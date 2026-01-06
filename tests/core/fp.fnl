(local fp (require :src.core.fp))
(print "--- Testing FP ---")

;; Map
(let [xs [1 2 3]
      ys (fp.map (fn [x] (* x 2)) xs)]
  (print "map:" (table.concat ys " ")))

;; Grep
(let [xs [1 2 3 4]
      ys (fp.grep (fn [x] (= (% x 2) 0)) xs)]
  (print "grep:" (table.concat ys " ")))

;; Flatmap
(let [xs [1 2]
      ys (fp.flatmap (fn [x] [x x]) xs)]
  (print "flatmap:" (table.concat ys " ")))

;; Foldl/Reduce
(let [xs [1 2 3]
      r  (fp.foldl (fn [a x] (- a x)) 0 xs)]
  (print "foldl (-):" r)) ;; -6

;; Foldr
(let [xs [1 2 3]
      r  (fp.foldr (fn [x a] (- x a)) 0 xs)]
  (print "foldr (-):" r)) ;; 2

;; Any/All
(let [xs [1 2 3]]
  (print "any (>1):" (fp.any (fn [x] (> x 1)) xs))
  (print "all (>1):" (fp.all (fn [x] (> x 1)) xs))
  (print "all (>0):" (fp.all (fn [x] (> x 0)) xs)))

(print "FP Verification Complete.")
