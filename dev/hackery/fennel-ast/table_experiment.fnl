(local fennel (require :fennel))

(fn parse-one [str]
  (let [parser (fennel.parser str)]
    (match (parser)
      (true val) val
      _ nil)))

(print "\n=== Table vs Sequence Experiment ===")

(local seq-node (parse-one "[1 2]"))
(local curly-node (parse-one "{:a 1}"))

(print "Sequence [1 2]:" (fennel.view seq-node))
(print "  Is sequence?" (fennel.sequence? seq-node))
(print "  Is list?" (fennel.list? seq-node))
(print "  Is table?" (fennel.table? seq-node))
  (print "  Metatable:" (fennel.view (getmetatable seq-node)))

(print "Curly {:a 1}:" (fennel.view curly-node))
(print "  Is sequence?" (fennel.sequence? curly-node))
(print "  Is list?" (fennel.list? curly-node))
(print "  Is table?" (fennel.table? curly-node))
  (print "  Metatable:" (fennel.view (getmetatable curly-node)))

(print "\n=== Constructor Check ===")
(local constructed (fennel.sequence 1 2 3))
(print "Constructed sequence:" (fennel.view constructed) "Is sequence?" (fennel.sequence? constructed))

;; User's proposed line:
(local mixed (fennel.sequence {:foo 1 :bar 2}))
(print "User proposal (fennel.sequence {:foo 1}):" (fennel.view mixed))
(print "  Count of items:" (length mixed))
(print "  Item 1:" (fennel.view (. mixed 1)))
