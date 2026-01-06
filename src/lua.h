#pragma once
#include <luajit-2.1/lua.hpp>
#include "base.h"

struct Lua final
{
  Lua();
  ~Lua();

  void eval(Stc &script, bool panic = true);

private:
  void init_core();
  void load_embedded_module(chc *name, u8c *bc, uN len);
  void init_fennel_package();
  void init_bindings_native();
  void init_manual_package(chc *name);
  void set_package_loaded(chc *name);

  lua_State *L_;
};
