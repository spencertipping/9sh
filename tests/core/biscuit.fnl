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

;; Add facts
(local add_ok (biscuit.builder_add_fact builder "user(\"alice\")"))
(if (not add_ok)
  (error (.. "Fact error: " (ffi.string (biscuit.error_message)))))
(assert add_ok "Fact should be added")

;; Build token
(local token (biscuit.builder_build builder kp seed 32))
(assert (not (= nil token)) "Token should be built")

;; Verify token with authorizer
(local auth_builder (biscuit.authorizer_builder))
(assert (not (= nil auth_builder)) "Authorizer builder should be created")
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
(biscuit.free token)
(biscuit.public_key_free pub)
(biscuit.key_pair_free kp)

(print "biscuit: ok")
