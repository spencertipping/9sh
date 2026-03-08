#include <boost/asio.hpp>
extern "C" {
#include "biscuit_auth.h"
}
#include <luajit-2.1/lua.hpp>
#include <readline/history.h>
#include <readline/readline.h>
#include <sqlite3.h>
#include <vterm.h>

#include "base.h"


extern "C" {
  // Asio
  void* w_asio_context_new();
  void  w_asio_context_run(void* ctx);
  void  w_asio_context_delete(void* ctx);
  void* w_asio_timer_new(void* ctx);

  // Filesystem
  int   w_is_slow_mount(const char* path);
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

  // Biscuit
  REG_PTR("biscuit_key_pair_new",            biscuit_key_pair_new);
  REG_PTR("biscuit_key_pair_public",         biscuit_key_pair_public);
  REG_PTR("biscuit_key_pair_free",           biscuit_key_pair_free);
  REG_PTR("biscuit_public_key_free",         biscuit_public_key_free);

  REG_PTR("biscuit_builder",                 biscuit_builder);
  REG_PTR("biscuit_builder_add_fact",        biscuit_builder_add_fact);
  REG_PTR("biscuit_builder_add_rule",        biscuit_builder_add_rule);
  REG_PTR("biscuit_builder_add_check",       biscuit_builder_add_check);
  REG_PTR("biscuit_builder_build",           biscuit_builder_build);
  REG_PTR("biscuit_builder_free",            biscuit_builder_free);

  REG_PTR("biscuit_free",                    biscuit_free);

  REG_PTR("biscuit_authorizer_builder",      biscuit_authorizer_builder);
  REG_PTR("biscuit_authorizer_builder_add_fact", biscuit_authorizer_builder_add_fact);
  REG_PTR("biscuit_authorizer_builder_add_rule", biscuit_authorizer_builder_add_rule);
  REG_PTR("biscuit_authorizer_builder_add_check", biscuit_authorizer_builder_add_check);
  REG_PTR("biscuit_authorizer_builder_add_policy", biscuit_authorizer_builder_add_policy);
  REG_PTR("biscuit_authorizer_builder_build", biscuit_authorizer_builder_build);
  REG_PTR("biscuit_authorizer_builder_free", biscuit_authorizer_builder_free);

  REG_PTR("biscuit_authorizer_authorize",    biscuit_authorizer_authorize);
  REG_PTR("biscuit_authorizer_free",         biscuit_authorizer_free);

  REG_PTR("biscuit_error_message",           biscuit_error_message);
  REG_PTR("vterm_set_size",         vterm_set_size);

  // Asio
  REG_PTR("asio_context_new",       w_asio_context_new);
  REG_PTR("asio_context_run",       w_asio_context_run);
  REG_PTR("asio_context_delete",    w_asio_context_delete);

  REG_PTR("asio_timer_new",         w_asio_timer_new);

  // Filesystem
  REG_PTR("is_slow_mount",          w_is_slow_mount);

  return 1;
}
