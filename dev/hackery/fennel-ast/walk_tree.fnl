(local fennel (require :fennel))
(local utils (require :fennel.utils))

(print "\n=== Walk-Tree Experiment ===\n")

(local ast (fennel.parser "(+ 1 (print \"nested\") 2)"))
(var (ok root) (ast))

(print "Root AST:" (fennel.view root))

(print "\n--- Walking ---")
(utils.walk-tree root (fn [idx node parent]
  (print "Visit: idx=" idx " node=" (fennel.view node)
         " parent=" (if parent (fennel.view parent) "nil"))

  ;; Return true to descend, nil/false to skip children
  (if (and (fennel.list? node)
           (= (tostring (. node 1)) "print"))
      (do
        (print "  Skipping children of print!")
        nil)
      (= (type node) "table"))))

(print "\nNote: inner 'nested' string should NOT be visited if skip worked.")
