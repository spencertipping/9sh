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
  int w_is_slow_mount(const char* path);
")

;; Biscuit
(ffi.cdef "
  typedef struct Biscuit Biscuit;
  typedef struct BiscuitBuilder BiscuitBuilder;
  typedef struct KeyPair KeyPair;
  typedef struct PublicKey PublicKey;
  typedef struct Authorizer Authorizer;
  typedef struct AuthorizerBuilder AuthorizerBuilder;

  enum SignatureAlgorithm { Ed25519 = 0, Secp256r1 = 1 };

  struct KeyPair *key_pair_new(const uint8_t *seed_ptr, uintptr_t seed_len, enum SignatureAlgorithm algorithm);
  struct KeyPair *key_pair_from_pem(const char *pem);
  struct PublicKey *key_pair_public(const struct KeyPair *kp);
  void key_pair_free(struct KeyPair *_kp);
  struct PublicKey *public_key_from_pem(const char *pem);
  void public_key_free(struct PublicKey *_kp);

  struct BiscuitBuilder *biscuit_builder(void);
  bool biscuit_builder_add_fact(struct BiscuitBuilder *builder, const char *fact);
  bool biscuit_builder_add_rule(struct BiscuitBuilder *builder, const char *rule);
  bool biscuit_builder_add_check(struct BiscuitBuilder *builder, const char *check);
  struct Biscuit *biscuit_builder_build(const struct BiscuitBuilder *builder, const struct KeyPair *key_pair, const uint8_t *seed_ptr, uintptr_t seed_len);
  void biscuit_builder_free(struct BiscuitBuilder *_builder);

  struct Biscuit *biscuit_from(const uint8_t *biscuit_ptr, uintptr_t biscuit_len, const struct PublicKey *root);
  void biscuit_free(struct Biscuit *_biscuit);

  struct AuthorizerBuilder *authorizer_builder(void);
  bool authorizer_builder_add_fact(struct AuthorizerBuilder *builder, const char *fact);
  bool authorizer_builder_add_rule(struct AuthorizerBuilder *builder, const char *rule);
  bool authorizer_builder_add_check(struct AuthorizerBuilder *builder, const char *check);
  bool authorizer_builder_add_policy(struct AuthorizerBuilder *builder, const char *policy);
  struct Authorizer *authorizer_builder_build(struct AuthorizerBuilder *builder, const struct Biscuit *token);
  void authorizer_builder_free(struct AuthorizerBuilder *_builder);

  bool authorizer_authorize(struct Authorizer *authorizer);
  void authorizer_free(struct Authorizer *_authorizer);

  const char *error_message(void);
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
        :timer_new (cast "void* (*)(void*)" "asio_timer_new")}
 :is_slow_mount (cast "int (*)(const char*)" "is_slow_mount")
 :biscuit {:key_pair_new (cast "struct KeyPair* (*)(const uint8_t*, uintptr_t, enum SignatureAlgorithm)" "biscuit_key_pair_new")
           :key_pair_from_pem (cast "struct KeyPair* (*)(const char*)" "biscuit_key_pair_from_pem")
           :key_pair_public (cast "struct PublicKey* (*)(const struct KeyPair*)" "biscuit_key_pair_public")
           :key_pair_free (cast "void (*)(struct KeyPair*)" "biscuit_key_pair_free")
           :public_key_from_pem (cast "struct PublicKey* (*)(const char*)" "biscuit_public_key_from_pem")
           :public_key_free (cast "void (*)(struct PublicKey*)" "biscuit_public_key_free")
           :builder (cast "struct BiscuitBuilder* (*)(void)" "biscuit_builder")
           :builder_add_fact (cast "bool (*)(struct BiscuitBuilder*, const char*)" "biscuit_builder_add_fact")
           :builder_add_rule (cast "bool (*)(struct BiscuitBuilder*, const char*)" "biscuit_builder_add_rule")
           :builder_add_check (cast "bool (*)(struct BiscuitBuilder*, const char*)" "biscuit_builder_add_check")
           :builder_build (cast "struct Biscuit* (*)(const struct BiscuitBuilder*, const struct KeyPair*, const uint8_t*, uintptr_t)" "biscuit_builder_build")
           :builder_free (cast "void (*)(struct BiscuitBuilder*)" "biscuit_builder_free")
           :from (cast "struct Biscuit* (*)(const uint8_t*, uintptr_t, const struct PublicKey*)" "biscuit_from")
           :free (cast "void (*)(struct Biscuit*)" "biscuit_free")
           :authorizer_builder (cast "struct AuthorizerBuilder* (*)(void)" "biscuit_authorizer_builder")
           :authorizer_builder_add_fact (cast "bool (*)(struct AuthorizerBuilder*, const char*)" "biscuit_authorizer_builder_add_fact")
           :authorizer_builder_add_rule (cast "bool (*)(struct AuthorizerBuilder*, const char*)" "biscuit_authorizer_builder_add_rule")
           :authorizer_builder_add_check (cast "bool (*)(struct AuthorizerBuilder*, const char*)" "biscuit_authorizer_builder_add_check")
           :authorizer_builder_add_policy (cast "bool (*)(struct AuthorizerBuilder*, const char*)" "biscuit_authorizer_builder_add_policy")
           :authorizer_builder_build (cast "struct Authorizer* (*)(struct AuthorizerBuilder*, const struct Biscuit*)" "biscuit_authorizer_builder_build")
           :authorizer_builder_free (cast "void (*)(struct AuthorizerBuilder*)" "biscuit_authorizer_builder_free")
           :authorizer_authorize (cast "bool (*)(struct Authorizer*)" "biscuit_authorizer_authorize")
           :authorizer_free (cast "void (*)(struct Authorizer*)" "biscuit_authorizer_free")
           :error_message (cast "const char* (*)(void)" "biscuit_error_message")}}
