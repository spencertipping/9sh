(local {:biscuit biscuit} (require :bindings))
(local ffi (require :ffi))

;; 32-byte seed for Ed25519
(local seed "01234567890123456789012345678901")

;; Verify key pair generation (0 = Ed25519)
(local kp (biscuit.key_pair_new seed 32 0))
(assert (not (= nil kp)) "Key pair should be created")

;; Verify public key extraction
(local pub (biscuit.key_pair_public kp))
(assert (not (= nil pub)) "Public key should be extracted")

;; Create a builder
(local builder (biscuit.builder))
(assert (not (= nil builder)) "Builder should be created")

;; Add facts, rules, and checks to builder
(local add_ok (biscuit.builder_add_fact builder "user(\"alice\")"))
(if (not add_ok) (error (.. "Fact error: " (ffi.string (biscuit.error_message)))))
(assert add_ok "Fact should be added")

(local rule_ok (biscuit.builder_add_rule builder "right(\"read\") <- user(\"alice\")"))
(if (not rule_ok) (error (.. "Rule error: " (ffi.string (biscuit.error_message)))))
(assert rule_ok "Rule should be added")

(local check_ok (biscuit.builder_add_check builder "check if user(\"alice\")"))
(if (not check_ok) (error (.. "Check error: " (ffi.string (biscuit.error_message)))))
(assert check_ok "Check should be added")

;; Build token
(local token (biscuit.builder_build builder kp seed 32))
(assert (not (= nil token)) "Token should be built")

;; Verify token with authorizer
(local auth_builder (biscuit.authorizer_builder))
(assert (not (= nil auth_builder)) "Authorizer builder should be created")

(local auth_fact_ok (biscuit.authorizer_builder_add_fact auth_builder "resource(\"file1\")"))
(assert auth_fact_ok "Authorizer fact should be added")

(local auth_rule_ok (biscuit.authorizer_builder_add_rule auth_builder "can_read($file) <- resource($file), right(\"read\")"))
(assert auth_rule_ok "Authorizer rule should be added")

(local auth_check_ok (biscuit.authorizer_builder_add_check auth_builder "check if right(\"read\")"))
(assert auth_check_ok "Authorizer check should be added")

(local pol_ok (biscuit.authorizer_builder_add_policy auth_builder "allow if user(\"alice\")"))
(if (not pol_ok)
  (error (.. "Policy error: " (ffi.string (biscuit.error_message)))))
(assert pol_ok "Policy should be added")

(local authorizer (biscuit.authorizer_builder_build auth_builder token))
(assert (not (= nil authorizer)) "Authorizer should be built")

(local authorized (biscuit.authorizer_authorize authorizer))
(if (not authorized)
  (error (.. "Authorization failed: " (ffi.string (biscuit.error_message)))))
(assert authorized "Authorization should succeed")

;; Clean up
(biscuit.authorizer_free authorizer)
(biscuit.authorizer_builder_free auth_builder)
(biscuit.free token)
(biscuit.builder_free builder)
(biscuit.public_key_free pub)
(biscuit.key_pair_free kp)

(print "biscuit: ok")
