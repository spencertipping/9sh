#include <pybind11/pybind11.h>
#include <pybind11/functional.h>
#include <pybind11/eval.h>
#include <boost/asio.hpp>

#ifdef __cplusplus
extern "C" {
#endif
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#ifdef __cplusplus
}
#endif

#include <iostream>
#include <memory>
#include <thread>
#include <unordered_map>
#include <string>
#include <cstring>
#include <algorithm>
#include <atomic>
#include <optional>

namespace py = pybind11;
namespace asio = boost::asio;

// === Globals ===
asio::io_context io_ctx;
asio::io_context worker_ctx;
std::optional<asio::executor_work_guard<asio::io_context::executor_type>> worker_guard;
std::thread worker_thread;

lua_State* L = nullptr;

// Tracking active tasks to ensure the io_context loop doesn't exit prematurely
std::atomic<int> active_tasks{0};
std::optional<asio::executor_work_guard<asio::io_context::executor_type>> main_guard;

void inc_task() {
    if (active_tasks++ == 0) main_guard.emplace(asio::make_work_guard(io_ctx));
}
void dec_task() {
    if (--active_tasks == 0) main_guard.reset();
}

std::unordered_map<int, py::function> py_callbacks;
int next_py_cb_id = 1;

// === C++ <-> Lua Bridge ===
extern "C" {
    // Called by Lua: cpp_call_py(cb_id)
    static int l_cpp_call_py(lua_State* L) {
        int cb_id = luaL_checkinteger(L, 1);

        py::gil_scoped_acquire acquire; // Must acquire GIL to invoke Python
        if (py_callbacks.count(cb_id)) {
            auto cb = py_callbacks[cb_id];
            cb();
            py_callbacks.erase(cb_id);
            dec_task();
        }
        return 0;
    }

    // Called by Lua: cpp_async_sleep(ms, callback_fn)
    static int l_cpp_async_sleep(lua_State* L) {
        int ms = luaL_checkinteger(L, 1);
        luaL_checktype(L, 2, LUA_TFUNCTION);

        lua_pushvalue(L, 2);
        int lua_cb_ref = luaL_ref(L, LUA_REGISTRYINDEX); // Retain Lua function

        auto timer = std::make_shared<asio::steady_timer>(io_ctx, std::chrono::milliseconds(ms));

        // FIX: Added 'L' to the lambda capture list here!
        timer->async_wait([timer, lua_cb_ref, L](const boost::system::error_code& ec) {
            if (!ec) {
                lua_rawgeti(L, LUA_REGISTRYINDEX, lua_cb_ref);
                if (lua_pcall(L, 0, 0, 0) != 0) {
                    std::cerr << "Lua error: " << lua_tostring(L, -1) << std::endl;
                }
                luaL_unref(L, LUA_REGISTRYINDEX, lua_cb_ref); // Free reference
            }
        });
        return 0;
    }
}

// === Initialization & Loop Mechanics ===
void init_env() {
    if (!L) {
        L = luaL_newstate();
        luaL_openlibs(L);
        lua_register(L, "cpp_call_py", l_cpp_call_py);
        lua_register(L, "cpp_async_sleep", l_cpp_async_sleep);

        worker_guard.emplace(asio::make_work_guard(worker_ctx));
        worker_thread = std::thread([]() { worker_ctx.run(); });
    }
}

void shutdown_env() {
    if (worker_guard) {
        worker_guard.reset();
        worker_ctx.stop();
        if (worker_thread.joinable()) worker_thread.join();
    }
    if (L) {
        lua_close(L);
        L = nullptr;
    }
}

// Node.js style run loop
void run_loop() {
    py::gil_scoped_release release; // Let python threads run during event loop
    io_ctx.run();
    io_ctx.restart();
}

// === Python Lua Interface ===
class LuaModule {
public:
    LuaModule(const std::string& script) {
        if (luaL_dofile(L, script.c_str()) != 0) {
            throw std::runtime_error("Failed to load Lua script: " + std::string(lua_tostring(L, -1)));
        }
        lua_setglobal(L, "current_module");
    }

    void call_timer(py::function cb) {
        int cb_id = next_py_cb_id++;
        py_callbacks[cb_id] = cb;
        inc_task(); // Prevent loop from dying early

        lua_getglobal(L, "current_module");
        lua_getfield(L, -1, "do_timer");
        lua_pushinteger(L, cb_id);

        if (lua_pcall(L, 1, 0, 0) != 0) {
            std::cerr << "Lua error: " << lua_tostring(L, -1) << std::endl;
        }
        lua_pop(L, 1);
    }
};

// === Zero-Copy Ownership Buffer ===
class ZCBuffer {
    std::unique_ptr<uint8_t[]> ptr;
    size_t sz;
public:
    ZCBuffer(size_t size) : sz(size), ptr(new uint8_t[size]()) {}
    ~ZCBuffer() = default;

    void write(const std::string& data) {
        if (!ptr) throw std::runtime_error("Access violation: Buffer ownership has been transferred!");
        size_t copy_sz = std::min(sz, data.size());
        std::memcpy(ptr.get(), data.data(), copy_sz);
    }

    std::string read() {
        if (!ptr) throw std::runtime_error("Access violation: Buffer ownership has been transferred!");
        return std::string((char*)ptr.get(), sz);
    }

    std::unique_ptr<uint8_t[]> release() { return std::move(ptr); }
    void acquire(std::unique_ptr<uint8_t[]> p) { ptr = std::move(p); }
    size_t size() const { return sz; }
};

// Transfers ownership (zero-copy) to worker context and back
void process_in_background(ZCBuffer* buf, py::function on_done) {
    if (!buf) throw std::runtime_error("Null buffer");
    auto raw_ptr = buf->release(); // Takes ownership away from Python representation
    if (!raw_ptr) throw std::runtime_error("Buffer already transferred");

    size_t sz = buf->size();
    int cb_id = next_py_cb_id++;
    py_callbacks[cb_id] = on_done;
    inc_task();

    // Send payload to worker thread
    asio::post(worker_ctx, [p = std::move(raw_ptr), sz, cb_id]() mutable {
        std::string prefix = "PROCESSED: ";
        size_t copy_sz = std::min(sz, prefix.size());
        if (copy_sz > 0) std::memcpy(p.get(), prefix.data(), copy_sz);
        std::this_thread::sleep_for(std::chrono::milliseconds(300)); // simulate hard work

        // Send payload back to main thread event loop
        asio::post(io_ctx, [p = std::move(p), sz, cb_id]() mutable {
            auto new_buf = new ZCBuffer(sz);
            new_buf->acquire(std::move(p)); // Give data back to proxy

            py::gil_scoped_acquire acquire; // Acquire GIL before editing py_callbacks
            if (py_callbacks.count(cb_id)) {
                auto cb = py_callbacks[cb_id];
                auto py_buf = py::cast(new_buf, py::return_value_policy::take_ownership);
                cb(py_buf);
                py_callbacks.erase(cb_id);
            } else {
                delete new_buf;
            }
            dec_task();
        });
    });
}

// === PyBind11 Module Registration ===
PYBIND11_MODULE(core, m) {
    m.def("init", &init_env);
    m.def("shutdown", &shutdown_env);
    m.def("run_loop", &run_loop);
    m.def("process_in_background", &process_in_background);

    py::class_<LuaModule>(m, "LuaModule")
        .def(py::init<const std::string&>())
        .def("call_timer", &LuaModule::call_timer);

    py::class_<ZCBuffer>(m, "ZCBuffer")
        .def(py::init<size_t>())
        .def("write", &ZCBuffer::write)
        .def("read", &ZCBuffer::read);
}
