(local bindings (require :bindings))
(local ffi (require :ffi))

(fn hello []
  (print "Hello from embedded Fennel!")
  (print (.. "SQLite Version: " (tostring (bindings.sqlite3.version))))

  (let [db-ptr (ffi.new "sqlite3*[1]")
        rc (bindings.sqlite3.open ":memory:" db-ptr)]
    (if (= rc bindings.sqlite3.OK)
        (do
          (print "Opened in-memory database.")
          (let [db (. db-ptr 0)
                stmt-ptr (ffi.new "sqlite3_stmt*[1]")]
            ;; Create table
            (bindings.sqlite3.exec db "CREATE TABLE test (id INTEGER, name TEXT);" nil nil nil)

            ;; Insert data using prepared statement
            (bindings.sqlite3.prepare_v2 db "INSERT INTO test VALUES (?, ?);" -1 stmt-ptr nil)
            (let [stmt (. stmt-ptr 0)]
               (bindings.sqlite3.bind_int stmt 1 42)
               (bindings.sqlite3.bind_text stmt 2 "Fennel via Prepared Stmt" -1 nil)
               (bindings.sqlite3.step stmt)
               (bindings.sqlite3.finalize stmt))

            ;; Query data
            (bindings.sqlite3.prepare_v2 db "SELECT id, name FROM test;" -1 stmt-ptr nil)
            (let [stmt (. stmt-ptr 0)]
              (while (= (bindings.sqlite3.step stmt) bindings.sqlite3.ROW)
                (print (.. "Row: " (tostring (bindings.sqlite3.column_int stmt 0))
                           " - " (tostring (ffi.string (bindings.sqlite3.column_text stmt 1))))))
              (bindings.sqlite3.finalize stmt))

            (bindings.sqlite3.close db)))
        (print "Failed to open database!")))

  (let [ctx (bindings.asio.context_new)
        timer (bindings.asio.timer_new ctx)]
    (print "Boost.Asio timer created.")
    (bindings.asio.context_delete ctx)))

{:hello hello}
