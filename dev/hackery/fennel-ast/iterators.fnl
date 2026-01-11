(local fennel (require :fennel))

(fn my-iterator []
  (values true "value-1" "value-2"))

(print "\n=== Iterator Consumption Experiment ===")

;; 1. (var (a b) ...)
(print "\n--- 1. (var (a b) ...) ---")
(var (ok v1 v2) (my-iterator))
(print "ok:" ok "v1:" v1 "v2:" v2)
(set (ok v1 v2) (values false "changed" "changed"))
(print "mutated -> ok:" ok "v1:" v1 "v2:" v2)

;; 2. (let [(a b) ...] ...)
(print "\n--- 2. (let [(a b) ...] ...) ---")
(let [(ok v1 v2) (my-iterator)]
  (print "ok:" ok "v1:" v1 "v2:" v2))

;; 3. (match ...)
;; Note: match usually operates on the first value unless wrapped?
(print "\n--- 3. (match ...) ---")
(match (my-iterator)
  (true v1 v2) (print "Match unpacked multiple values directly: " v1 v2)
  _ (print "Match failed to unpack directly"))

(match [(my-iterator)]
  [true v1 v2] (print "Match unpacked via table wrap: " v1 v2)
  _ (print "Match failed via table wrap"))

;; 4. (each ...)
(print "\n--- 4. (each ...) ---")
;; Custom iterator for loop
(fn count-to-3 []
  (var i 0)
  (fn []
    (set i (+ i 1))
    (if (<= i 3)
        (values i (* i i))
        nil)))

(each [num sq (count-to-3)]
  (print "num:" num "sq:" sq))
