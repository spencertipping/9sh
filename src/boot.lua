local bindings = require("bindings")
local ffi = require("ffi")
local function hello()
  print("Hello from embedded Fennel!")
  print(("SQLite Version: " .. tostring(bindings.sqlite3.version())))
  do
    local db_ptr = ffi.new("sqlite3*[1]")
    local rc = bindings.sqlite3.open(":memory:", db_ptr)
    if (rc == bindings.sqlite3.OK) then
      print("Opened in-memory database.")
      local db = db_ptr[0]
      local stmt_ptr = ffi.new("sqlite3_stmt*[1]")
      bindings.sqlite3.exec(db, "CREATE TABLE test (id INTEGER, name TEXT);", nil, nil, nil)
      bindings.sqlite3.prepare_v2(db, "INSERT INTO test VALUES (?, ?);", -1, stmt_ptr, nil)
      do
        local stmt = stmt_ptr[0]
        bindings.sqlite3.bind_int(stmt, 1, 42)
        bindings.sqlite3.bind_text(stmt, 2, "Fennel via Prepared Stmt", -1, nil)
        bindings.sqlite3.step(stmt)
        bindings.sqlite3.finalize(stmt)
      end
      bindings.sqlite3.prepare_v2(db, "SELECT id, name FROM test;", -1, stmt_ptr, nil)
      do
        local stmt = stmt_ptr[0]
        while (bindings.sqlite3.step(stmt) == bindings.sqlite3.ROW) do
          print(("Row: " .. tostring(bindings.sqlite3.column_int(stmt, 0)) .. " - " .. tostring(ffi.string(bindings.sqlite3.column_text(stmt, 1)))))
        end
        bindings.sqlite3.finalize(stmt)
      end
      bindings.sqlite3.close(db)
    else
      print("Failed to open database!")
    end
  end
  local ctx = bindings.asio.context_new()
  local timer = bindings.asio.timer_new(ctx)
  print("Boost.Asio timer created.")
  return bindings.asio.context_delete(ctx)
end
return {hello = hello}
