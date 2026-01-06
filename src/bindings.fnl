(local ffi (require :ffi))
(local native (require :bindings.native))

;; Helper to cast pointer to function type
(fn cast [type name]
  (ffi.cast type (. native name)))

;; SQLite3
(ffi.cdef "
  typedef struct sqlite3 sqlite3;
  typedef struct sqlite3_stmt sqlite3_stmt;
  typedef int (*sqlite3_callback)(void*,int,char**,char**);

  // Return codes
  static const int SQLITE_OK = 0;
  static const int SQLITE_ROW = 100;
  static const int SQLITE_DONE = 101;
")

;; Readline
(ffi.cdef "
  char *readline(const char *prompt);
  void add_history(const char *line);
")

;; libvterm (partial)
(ffi.cdef "
  typedef struct VTerm VTerm;
  VTerm *vterm_new(int rows, int cols);
  void vterm_free(VTerm *vt);
  void vterm_set_size(VTerm *vt, int rows, int cols);
")

;; Boost.Asio
(ffi.cdef "
  void* w_asio_context_new();
  void w_asio_context_run(void* ctx);
  void w_asio_context_delete(void* ctx);
  void* w_asio_timer_new(void* ctx);
")


{:sqlite3 {:open (cast "int (*)(const char *filename, sqlite3 **ppDb)" "sqlite3_open")
           :close (cast "int (*)(sqlite3*)" "sqlite3_close")
           :exec (cast "int (*)(sqlite3*, const char *sql, int (*callback)(void*,int,char**,char**), void *, char **errmsg)" "sqlite3_exec")
           :version (cast "const char *(*)(void)" "sqlite3_libversion")
           ;; Prepared statements
           :prepare_v2 (cast "int (*)(sqlite3*, const char*, int, sqlite3_stmt**, const char**)" "sqlite3_prepare_v2")
           :step (cast "int (*)(sqlite3_stmt*)" "sqlite3_step")
           :finalize (cast "int (*)(sqlite3_stmt*)" "sqlite3_finalize")
           :reset (cast "int (*)(sqlite3_stmt*)" "sqlite3_reset")
           :column_text (cast "const unsigned char *(*)(sqlite3_stmt*, int)" "sqlite3_column_text")
           :column_int (cast "int (*)(sqlite3_stmt*, int)" "sqlite3_column_int")
           :column_count (cast "int (*)(sqlite3_stmt*)" "sqlite3_column_count")
           :bind_text (cast "int (*)(sqlite3_stmt*, int, const char*, int, void(*)(void*))" "sqlite3_bind_text")
           :bind_int (cast "int (*)(sqlite3_stmt*, int, int)" "sqlite3_bind_int")
           :bind_double (cast "int (*)(sqlite3_stmt*, int, double)" "sqlite3_bind_double")
           :bind_null (cast "int (*)(sqlite3_stmt*, int)" "sqlite3_bind_null")
           :OK 0
           :ROW 100
           :DONE 101}
 :readline {:readline (cast "char *(*)(const char*)" "readline")
            :add_history (cast "void (*)(const char*)" "add_history")}
 :vterm {:new (cast "VTerm* (*)(int, int)" "vterm_new")
         :free (cast "void (*)(VTerm*)" "vterm_free")
         :set_size (cast "void (*)(VTerm*, int, int)" "vterm_set_size")}
 :asio {:context_new (cast "void* (*)(void)" "asio_context_new")
        :context_run (cast "void (*)(void*)" "asio_context_run")
        :context_delete (cast "void (*)(void*)" "asio_context_delete")
        :timer_new (cast "void* (*)(void*)" "asio_timer_new")}}
