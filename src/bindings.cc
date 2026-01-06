#include "base.h"
#include <sqlite3.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <vterm.h>
#include <luajit-2.1/lua.hpp>
#include <boost/asio.hpp>


struct C_IOContext
{
  boost::asio::io_context* ctx;
};


// Re-implement C wrappers for Asio to export pointers
extern "C"
{

void*
w_asio_context_new()
{
  return new boost::asio::io_context();
}

void
w_asio_context_run(void* ctx)
{
  static_cast<boost::asio::io_context*>(ctx)->run();
}

void
w_asio_context_delete(void* ctx)
{
  delete static_cast<boost::asio::io_context*>(ctx);
}

void*
w_asio_timer_new(void* ctx)
{
  return new boost::asio::steady_timer(*static_cast<boost::asio::io_context*>(ctx));
}

}


// Helper to push function pointer as lightuserdata
#define REG_PTR(name, func)        \
  lua_pushstring(L, name);         \
  lua_pushlightuserdata(L, (void*)func); \
  lua_settable(L, -3);

// This is the function called by main.cc
extern "C"
int luaopen_bindings_native_full(lua_State* L)
{
  lua_newtable(L);

  // SQLite3
  REG_PTR("sqlite3_open",           sqlite3_open);
  REG_PTR("sqlite3_close",          sqlite3_close);
  REG_PTR("sqlite3_exec",           sqlite3_exec);
  REG_PTR("sqlite3_libversion",     sqlite3_libversion);

  // Prepared Statements
  REG_PTR("sqlite3_prepare_v2",     sqlite3_prepare_v2);
  REG_PTR("sqlite3_step",           sqlite3_step);
  REG_PTR("sqlite3_finalize",       sqlite3_finalize);
  REG_PTR("sqlite3_reset",          sqlite3_reset);
  REG_PTR("sqlite3_column_text",    sqlite3_column_text);
  REG_PTR("sqlite3_column_int",     sqlite3_column_int);
  REG_PTR("sqlite3_column_count",   sqlite3_column_count);
  REG_PTR("sqlite3_bind_text",      sqlite3_bind_text);
  REG_PTR("sqlite3_bind_int",       sqlite3_bind_int);
  REG_PTR("sqlite3_bind_double",    sqlite3_bind_double);
  REG_PTR("sqlite3_bind_null",      sqlite3_bind_null);

  // Readline
  REG_PTR("readline",               readline);
  REG_PTR("add_history",            add_history);

  // vterm
  REG_PTR("vterm_new",              vterm_new);
  REG_PTR("vterm_free",             vterm_free);
  REG_PTR("vterm_set_size",         vterm_set_size);

  // Asio
  REG_PTR("asio_context_new",       w_asio_context_new);
  REG_PTR("asio_context_run",       w_asio_context_run);
  REG_PTR("asio_context_delete",    w_asio_context_delete);
  REG_PTR("asio_timer_new",         w_asio_timer_new);

  return 1;
}
