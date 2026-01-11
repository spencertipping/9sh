(local fennel (require :fennel))

(fn returns-multi []
  (values true "the-ast"))

(fn returns-table []
  [true "the-ast"])

(print "\n=== Destructuring Experiment ===")

;; Case 1: Multi-return function with () destructuring
(let [(ok ast) (returns-multi)]
  (print "() destructuring on multi-return:")
  (print "  ok:" ok "type:" (type ok))
  (print "  ast:" ast))

;; Case 2: Multi-return function with [] destructuring
(let [[ok ast] (returns-multi)]
  (print "[] destructuring on multi-return:")
  (print "  ok:" ok "type:" (type ok))
  (print "  ast:" ast))

;; Case 3: Table return with [] destructuring
(let [[ok ast] (returns-table)]
  (print "[] destructuring on table-return:")
  (print "  ok:" ok "type:" (type ok))
  (print "  ast:" ast))
