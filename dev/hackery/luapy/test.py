import core

print("=== Initializing Core ===")
core.init()

# --- 1. Zero-Copy Thread Transfer ---
print("\n=== Testing Zero-Copy Thread Transfer ===")
buf = core.ZCBuffer(100)
buf.write("HELLO FROM PYTHON")

def on_worker_done(new_buf):
    print(f"[Python] Callback received buffer from worker!")
    print(f"[Python] Buffer content: '{new_buf.read()}'")

print("[Python] Dispatching buffer to background thread...")
core.process_in_background(buf, on_worker_done)

# Prove principled threading (Single Owner / Zero Copy transfer)
try:
    print("[Python] Attempting to read buffer after transfer...")
    buf.read()
except Exception as e:
    print(f"[Python] Expected access violation caught: {e}")

# --- 2. Lua Driving C++ API ---
print("\n=== Testing Lua -> C++ -> Python Event Flow ===")
print("[Python] Loading Lua script (logic.lua)...")
lua_mod = core.LuaModule("logic.lua")

def on_lua_done():
    print("[Python] Callback executed: Lua async timer completed!")

print("[Python] Telling Lua to start a C++ timer...")
lua_mod.call_timer(on_lua_done)

# --- 3. Run Event Loop ---
print("\n=== Starting Node.js-style Event Loop ===")
# This will block until the IO queue runs out of jobs natively in C++
core.run_loop()

print("\n=== Event Loop Empty. Shutting Down ===")
core.shutdown()