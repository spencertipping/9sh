(local fennel (require :fennel))

(print "\n=== Custom Iterator Experiment ===\n")

;; 1. Define an iterator factory
(fn range-iter [start end step]
  (var current (- start step))
  ;; The iterator function itself
  (fn []
    (set current (+ current step))
    (if (<= current end)
        (values current (* current current)) ;; Return (val, square)
        nil)))

(print "--- Consuming with (each) ---")
;; 'each' loop automatically calls the iterator until it returns nil
(each [val sq (range-iter 1 5 1)]
  (print "Value:" val "Square:" sq))

(print "\n--- Consuming manually ---")
;; Manually calling the iterator
(local iter (range-iter 10 12 1))

;; Step 1
(var (ok val sq) (iter)) ;; Oops, iter returns (val, sq), no 'ok' boolean here unlike parser!
;; Let's fix the var binding to match the return values
(var (val sq) (iter))
(print "Step 1 ->" val sq)

;; Step 2
(set (val sq) (iter))
(print "Step 2 ->" val sq)

;; Step 3
(set (val sq) (iter))
(print "Step 3 ->" val sq)

;; Step 4 (should be nil)
(set (val sq) (iter))
(print "Step 4 ->" val sq)
