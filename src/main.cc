#include <luajit-2.1/lua.hpp>
#include <readline/readline.h>
#include <readline/history.h>

// Include the embedded bytecode headers
#include "boot_bc.h"
#include "fennel_bc.h"
#include "bindings_bc.h"

#include "base.h"


extern "C" int luaopen_bindings_native_full(lua_State *L);


struct Args final
{
  Args(int argc, ch **argv)
  {
    for (int i = 1; i < argc; ++i)
      if (std::strcmp(argv[i], "-e") == 0 && i + 1 < argc)
      {
        eval_script_  = argv[++i];
        execute_flag_ = true;
      }
      else
      {
        std::cerr << "Unknown argument: " << argv[i] << std::endl;
        exit(1);
      }
  }

protected:
  St   eval_script_;
  bool execute_flag_ = false;
};


struct Lua final
{
  Lua()
  {
    L_ = luaL_newstate();
    if (!L_)
    {
      std::cerr << "Failed to create Lua state" << std::endl;
      exit(1);
    }
    luaL_openlibs(L_);
    init_core();
  }

  ~Lua() { if (L_) lua_close(L_); }

  void init_core()
  {
    load_embedded_module("fennel", src_fennel_bc, src_fennel_bc_len);
    init_fennel_package();

    init_bindings_native();
    load_embedded_module("bindings", src_bindings_bc, src_bindings_bc_len);  // loads bindings.fnl
    init_manual_package("bindings");

    load_embedded_module("boot", src_boot_bc, src_boot_bc_len);              // loads boot.fnl
    lua_setglobal(L_, "Boot");
  }

  void load_embedded_module(chc *name, u8c *bc, uN len)
  {
    if (luaL_loadbuffer(L_, (chc*) bc, len, name) != 0 || lua_pcall(L_, 0, 1, 0) != 0)
    {
      std::cerr << "Error loading " << name << ": " << lua_tostring(L_, -1) << std::endl;
      exit(1);
    }
  }

  // logic like: package.loaded.fennel = result_of_chunk
  void init_fennel_package()
  {
    // Stack: [fennel_module_table]
    lua_pushvalue     (L_, -1);
    lua_setglobal     (L_, "fennel");
    set_package_loaded("fennel");                                            // Stack: [fennel_module_table]
    lua_pop           (L_, 1);
  }

  void init_bindings_native()
  {
    lua_pushcfunction (L_, luaopen_bindings_native_full);
    lua_pushstring    (L_, "bindings.native");
    lua_call          (L_, 1, 1);
    set_package_loaded("bindings.native");
    lua_setglobal     (L_, "bindings.native");                               // technically we might not need this if it's in package.loaded
  }

  void init_manual_package(chc *name)
  {
    set_package_loaded(name);
    lua_pop(L_, 1);                                                          // pop module result
  }

  void set_package_loaded(chc *name)
  {
    // Stack expected: [module_value]
    lua_getglobal(L_, "package");
    lua_getfield (L_, -1, "loaded");                                         // stack: [mod, package, loaded]
    lua_pushvalue(L_, -3);                                                   // stack: [mod, package, loaded, mod]
    lua_setfield (L_, -2, name);
    lua_pop      (L_,  2);                                                   // stack: [mod]
  }

  void eval(Stc &script, bool panic = true)
  {
    lua_getglobal (L_, "fennel");
    lua_getfield  (L_, -1, "eval");
    lua_remove    (L_, -2);                                                  // remove fennel table
    lua_pushstring(L_, script.c_str());

    if (lua_pcall(L_, 1, 0, 0) != 0)
    {
      std::cerr << "Error executing script: " << lua_tostring(L_, -1) << std::endl;
      if (panic) exit(1);
      lua_pop(L_, 1);
    }
  }

protected:
  lua_State *L_;
};


struct REPL final
{
  REPL(Lua &l) : lua_(l) {}

  void run()
  {
    std::cout << "Welcome to 9sh (Skeletal)" << std::endl;
    for (ch *input; (input = readline("9sh> ")) != nullptr; free(input))
      if (*input)
      {
        if (*input != ' ') add_history(input);
        eval(input);
      }
  }

  void eval(Stc &input)
  {
    lua_.eval(input, false);
  }

protected:
  Lua &lua_;
};


int main(int argc, ch **argv)
{
  Args args(argc, argv);
  Lua  lua;

  if (args.execute_flag_) lua.eval(args.eval_script_);
  else
  {
    REPL repl(lua);
    repl.run();
  }

  return 0;
}
