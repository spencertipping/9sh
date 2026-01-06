#include <luajit-2.1/lua.hpp>
#include <readline/readline.h>
#include <readline/history.h>

// Include the embedded bytecode headers
#include "boot_bc.h"
#include "fennel_bc.h"
#include "bindings_bc.h"

#include "base.h"

extern "C" int luaopen_bindings_native_full(lua_State* L);

class Args
{
public:
  St   eval_script;
  bool execute_flag = false;

  Args(int argc, char** argv)
  {
    for (int i = 1; i < argc; ++i)
      if (std::strcmp(argv[i], "-e") == 0 && i + 1 < argc)
      {
        eval_script  = argv[++i];
        execute_flag = true;
      }
  }
};

class Lua
{
public:
  lua_State* L;

  Lua()
  {
    L = luaL_newstate();
    if (!L)
    {
      std::cerr << "Failed to create Lua state" << std::endl;
      exit(1);
    }
    luaL_openlibs(L);
    init_core();
  }

  ~Lua()
  {
    if (L) lua_close(L);
  }

  void init_core()
  {
    load_embedded_module("fennel", src_fennel_bc, src_fennel_bc_len);
    init_fennel_package();
    init_bindings_native();
    load_embedded_module("bindings", src_bindings_bc, src_bindings_bc_len); // loads bindings.fnl
    init_manual_package("bindings");
    load_embedded_module("boot", src_boot_bc, src_boot_bc_len);             // loads boot.fnl
    lua_setglobal(L, "Boot");
  }

  void load_embedded_module(const char* name, const unsigned char* bc, unsigned int len)
  {
    if (luaL_loadbuffer(L, (const char*)bc, len, name) != 0 || lua_pcall(L, 0, 1, 0) != 0)
    {
      std::cerr << "Error loading " << name << ": " << lua_tostring(L, -1) << std::endl;
      exit(1);
    }
  }

  // logic like: package.loaded.fennel = result_of_chunk
  void init_fennel_package()
  {
    // Stack: [fennel_module_table]
    lua_pushvalue(L, -1);
    lua_setglobal(L, "fennel");
    set_package_loaded("fennel"); // Stack: [fennel_module_table]
    lua_pop(L, 1);
  }

  void init_bindings_native()
  {
    lua_pushcfunction(L, luaopen_bindings_native_full);
    lua_pushstring   (L, "bindings.native");
    lua_call         (L, 1, 1);
    set_package_loaded("bindings.native");
    lua_setglobal    (L, "bindings.native"); // technically we might not need this if it's in package.loaded, but consistent with prev code
  }

  void init_manual_package(const char* name)
  {
    set_package_loaded(name);
    lua_pop(L, 1); // pop module result
  }

  void set_package_loaded(const char* name)
  {
    // Stack expected: [module_value]
    lua_getglobal(L, "package");
    lua_getfield (L, -1, "loaded");      // stack: [mod, package, loaded]
    lua_pushvalue(L, -3);                // stack: [mod, package, loaded, mod]
    lua_setfield (L, -2, name);
    lua_pop      (L, 2);                 // stack: [mod]
  }

  void eval(const St& script)
  {
    lua_getglobal(L, "fennel");
    lua_getfield (L, -1, "eval");
    lua_remove   (L, -2);                // remove fennel table
    lua_pushstring(L, script.c_str());

    if (lua_pcall(L, 1, 0, 0) != 0)
    {
      std::cerr << "Error executing script: " << lua_tostring(L, -1) << std::endl;
      exit(1);
    }
  }
};

class REPL
{
  Lua& lua;
public:
  REPL(Lua& l) : lua(l) {}

  void run()
  {
    std::cout << "Welcome to 9sh (Skeletal)" << std::endl;
    char* input;
    while ((input = readline("9sh> ")) != nullptr)
    {
      if (*input)
      {
        add_history(input);
        if (luaL_dostring(lua.L, input) != 0)
          std::cerr << "Error: " << lua_tostring(lua.L, -1) << std::endl;
      }
      free(input);
    }
  }
};

int main(int argc, char** argv)
{
  Args args(argc, argv);
  Lua  lua;

  if (args.execute_flag)
    lua.eval(args.eval_script);
  else
  {
    REPL repl(lua);
    repl.run();
  }

  return 0;
}
