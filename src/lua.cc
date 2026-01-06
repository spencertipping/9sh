#include <iostream>

#include "lua.h"

// Include the embedded bytecode headers
#include "boot_bc.h"
#include "fennel_bc.h"
#include "bindings_bc.h"

extern "C" int luaopen_bindings_native_full(lua_State *L);

Lua::Lua()
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

Lua::~Lua() { if (L_) lua_close(L_); }

void Lua::init_core()
{
  load_embedded_module("fennel", src_fennel_bc, src_fennel_bc_len);
  init_fennel_package();

  init_bindings_native();
  load_embedded_module("bindings", src_bindings_bc, src_bindings_bc_len);  // loads bindings.fnl
  init_manual_package("bindings");

  load_embedded_module("boot", src_boot_bc, src_boot_bc_len);              // loads boot.fnl
  lua_setglobal(L_, "Boot");
}

void Lua::load_embedded_module(chc *name, u8c *bc, uN len)
{
  if (luaL_loadbuffer(L_, (chc*) bc, len, name) != 0 || lua_pcall(L_, 0, 1, 0) != 0)
  {
    std::cerr << "Error loading " << name << ": " << lua_tostring(L_, -1) << std::endl;
    exit(1);
  }
}

// logic like: package.loaded.fennel = result_of_chunk
void Lua::init_fennel_package()
{
  // Stack: [fennel_module_table]
  lua_pushvalue     (L_, -1);
  lua_setglobal     (L_, "fennel");
  set_package_loaded("fennel");                                            // Stack: [fennel_module_table]
  lua_pop           (L_, 1);
}

void Lua::init_bindings_native()
{
  lua_pushcfunction (L_, luaopen_bindings_native_full);
  lua_pushstring    (L_, "bindings.native");
  lua_call          (L_, 1, 1);
  set_package_loaded("bindings.native");
  lua_setglobal     (L_, "bindings.native");                               // technically we might not need this if it's in package.loaded
}

void Lua::init_manual_package(chc *name)
{
  set_package_loaded(name);
  lua_pop(L_, 1);                                                          // pop module result
}

void Lua::set_package_loaded(chc *name)
{
  // Stack expected: [module_value]
  lua_getglobal(L_, "package");
  lua_getfield (L_, -1, "loaded");                                         // stack: [mod, package, loaded]
  lua_pushvalue(L_, -3);                                                   // stack: [mod, package, loaded, mod]
  lua_setfield (L_, -2, name);
  lua_pop      (L_,  2);                                                   // stack: [mod]
}

void Lua::eval(Stc &script, bool panic)
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
