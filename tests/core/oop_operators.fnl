(import-macros {: deftrait : defclass : impl} :core.macros)
(local oop (require :core.oop))
(local bit (require :bit))

(print "--- OOP Operator Tests ---")


;; Setup

(defclass Num [:v] "Number wrapper")

(deftrait Arithmetic "Basic arithmetic"
  (operator+        [s b])
  (operator-        [s b])
  (operator*        [s b])
  (operator/        [s b])
  (operator%        [s b])
  (operator^        [s b])
  (operator-len     [s])
  (operator-concat  [s b])
  (operator-tostring [s])
  (operator-eq      [s b])
  (operator-lt      [s b])
  (operator-le      [s b])
  (operator-band    [s b])
  (operator-bor     [s b])
  (operator-bxor    [s b])
  (operator-bnot    [s])
  (operator-shl     [s b])
  (operator-shr     [s b]))

(local Num oop.registry.classes.Num)
(fn val [x] (if (= (type x) "table") x.v x))

(impl Num Arithmetic
  (operator+ [s o] (Num.new (+ s.v (val o))))
  (operator- [s o] (Num.new (- s.v (val o))))
  (operator* [s o] (Num.new (* s.v (val o))))
  (operator/ [s o] (Num.new (/ s.v (val o))))
  (operator% [s o] (Num.new (% s.v (val o))))
  (operator^ [s o] (Num.new (^ s.v (val o))))

  (operator-len      [s]   (Num.new s.v))
  (operator-concat   [s o] (.. (tostring s.v) (tostring (val o))))
  (operator-tostring [s]   (tostring s.v))

  (operator-eq [s o] (= s.v (val o)))
  (operator-lt [s o] (< s.v (val o)))
  (operator-le [s o] (<= s.v (val o)))

  ;; Bitwise (using bit lib for 5.2/JIT compat)
  (operator-band [s o] (Num.new (bit.band   s.v (val o))))
  (operator-bor  [s o] (Num.new (bit.bor    s.v (val o))))
  (operator-bxor [s o] (Num.new (bit.bxor   s.v (val o))))
  (operator-bnot [s]   (Num.new (bit.bnot   s.v)))
  (operator-shl  [s o] (Num.new (bit.lshift s.v (val o))))
  (operator-shr  [s o] (Num.new (bit.rshift s.v (val o)))))


;; Verification

(local n1  (Num.new 10))
(local n2  (Num.new 3))

(print "Testing Arithmetic...")
(assert (= (. (+ n1 n2) :v) 13)   "+ fail")
(assert (= (. (- n1 n2) :v) 7)    "- fail")
(assert (= (. (* n1 n2) :v) 30)   "* fail")
(assert (= (. (% n1 n2) :v) 1)    "% fail")
(assert (= (. (^ n1 n2) :v) 1000) "^ fail")

(assert (< (math.abs (- (. (/ n1 n2) :v) 3.333333)) 0.0001) "/ fail")

(print "Testing Comparison...")
(assert (= n1 (Num.new 10))       "== fail")
(assert (not= n1 n2)              "!= fail")
(assert (< n2 n1)                 "< fail")
(assert (<= n2 n1)                "<= fail")
(assert (<= n1 (Num.new 10))      "<= eq fail")

(print "Testing String/Len...")
(assert (= (tostring n1) "10")    "str fail")
(assert (= (.. n1 n2) "103")      ".. fail")
(let [len-res (# n1)]
  (assert (= (. len-res :v) 10)   "# fail"))

(print "All Supported Operator Tests Passed!")
