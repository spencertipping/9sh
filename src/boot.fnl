(local b   (require :bindings))
(local ffi (require :ffi))


(fn hello []
  (print "Hello from embedded Fennel!")
  (print (.. "SQLite Version: " (tostring (b.sqlite3.version))))

  (let [dp (ffi.new "sqlite3*[1]")
        rc (b.sqlite3.open ":memory:" dp)]

    (if (= rc b.sqlite3.OK)
      (do
        (print "Opened in-memory database.")

        (let [db (. dp 0)
              sp (ffi.new "sqlite3_stmt*[1]")]

          ;; Create table
          (b.sqlite3.exec db "CREATE TABLE test (id INTEGER, name TEXT);" nil nil nil)

          ;; Insert data using prepared statement
          (b.sqlite3.prepare_v2 db "INSERT INTO test VALUES (?, ?);" -1 sp nil)

          (let [s (. sp 0)]
            (b.sqlite3.bind_int  s 1 42)
            (b.sqlite3.bind_text s 2 "Fennel via Prepared Stmt" -1 nil)
            (b.sqlite3.step      s)
            (b.sqlite3.finalize  s))

          ;; Query data
          (b.sqlite3.prepare_v2 db "SELECT id, name FROM test;" -1 sp nil)

          (let [s (. sp 0)]
            (while (= (b.sqlite3.step s) b.sqlite3.ROW)
              (print (.. "Row: " (tostring (b.sqlite3.column_int s 0))
                         " - "   (tostring (ffi.string (b.sqlite3.column_text s 1))))))
            (b.sqlite3.finalize s))

          (b.sqlite3.close db)))

      (print "Failed to open database!")))

  (let [c (b.asio.context_new)
        t (b.asio.timer_new c)]
    (print "Boost.Asio timer created.")
    (b.asio.context_delete c)))


{:hello hello}
