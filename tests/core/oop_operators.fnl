(import-macros {: deftrait : defclass : impl} :src.core.macros)
(local oop (require :src.core.oop))

(print "--- Starting OOP Operator Overload Tests ---")

;; Define a simple wrapper class for numbers
(defclass Num [:v] "A simple number wrapper")

(deftrait Arithmetic "Basic arithmetic"
  (operator+ [self b])
  (operator- [self b])
  (operator* [self b])
  (operator/ [self b])
  (operator% [self b])
  (operator^ [self b])
  (operator-idiv [self b])
  (operator-len [self])
  (operator-concat [self b])
  (operator-tostring [self])
  (operator-eq [self b])
  (operator-lt [self b])
  (operator-le [self b])
  (operator-band [self b])
  (operator-bor  [self b])
  (operator-bxor [self b])
  (operator-bnot [self])
  (operator-shl  [self b])
  (operator-shr  [self b]))

(local Num oop.registry.classes.Num)

(fn to-val [x] (if (= (type x) "table") x.v x))

(impl :Num :Arithmetic
  (operator+ [self other] (Num.new (+ self.v (to-val other))))
  (operator- [self other] (Num.new (- self.v (to-val other))))
  (operator* [self other] (Num.new (* self.v (to-val other))))
  (operator/ [self other] (Num.new (/ self.v (to-val other))))
  (operator% [self other] (Num.new (% self.v (to-val other))))
  (operator^ [self other] (Num.new (^ self.v (to-val other))))
  (operator-idiv [self other] (Num.new (// self.v (to-val other))))

  (operator-len [self] (Num.new self.v)) ;; Just return value as "length"
  (operator-concat [self other] (.. (tostring self.v) (tostring (to-val other))))
  (operator-tostring [self] (tostring self.v))

  (operator-eq [self other] (= self.v (to-val other)))
  (operator-lt [self other] (< self.v (to-val other)))
  (operator-le [self other] (<= self.v (to-val other)))

  ;; Bitwise
  (operator-band [self other] (Num.new (band self.v (to-val other))))
  (operator-bor  [self other] (Num.new (bor  self.v (to-val other))))
  (operator-bxor [self other] (Num.new (bxor self.v (to-val other))))
  (operator-bnot [self]       (Num.new (bnot self.v)))
  (operator-shl  [self other] (Num.new (lshift self.v (to-val other))))
  (operator-shr  [self other] (Num.new (rshift self.v (to-val other)))))

(local n1 (Num.new 10))
(local n2 (Num.new 3))

(print "Testing Arithmetic...")
(assert (= (. (+ n1 n2) :v) 13) "+ failed")
(assert (= (. (- n1 n2) :v) 7)  "- failed")
(assert (= (. (* n1 n2) :v) 30) "* failed")
;; Float division
(assert (< (math.abs (- (. (/ n1 n2) :v) 3.333333)) 0.0001) "/ failed")
(assert (= (. (% n1 n2) :v) 1)  "% failed")
(assert (= (. (^ n1 n2) :v) 1000) "^ failed")

(print "Testing Integer Division (Lua 5.3+ / LuaJIT 2.1)...")
;; Ensure environment supports // syntax and metamethod
(assert (= (. (// n1 n2) :v) 3) "// failed")

(print "Testing Comparison...")
(assert (= n1 (Num.new 10)) "== failed")
(assert (not= n1 n2) "!= failed")
(assert (< n2 n1) "< failed")
(assert (<= n2 n1) "<= failed")
(assert (<= n1 (Num.new 10)) "<= eq failed")

(print "Testing String/Len...")
(assert (= (tostring n1) "10") "tostring failed")
(assert (= (.. n1 n2) "103") ".. failed")
;; (assert (= (. (# n1) :v) 10) "# failed") ;; __len on tables requires Lua 5.2+ / LuaJIT compat

(print "Testing Bitwise...")
(local b1 (Num.new 10)) ;; 10 = 0b1010
(local b2 (Num.new 12)) ;; 12 = 0b1100

(assert (= (. (band b1 b2) :v) 8)  "& failed") ;; 8  = 0b1000
(assert (= (. (bor b1 b2) :v)  14) "| failed") ;; 14 = 0b1110
(assert (= (. (bxor b1 b2) :v) 6)  "~ failed") ;; 6  = 0b0110
(assert (= (. (lshift b1 1) :v) 20) "<< failed")
(assert (= (. (rshift b1 1) :v) 5) ">> failed")
;; Note: bnot behavior depends on integer width (usually 64-bit in LuaJIT)
;; checking identity: ~~x == x
(assert (= (. (bnot (bnot b1)) :v) 10) "~~x identity failed")

(print "All Operator Tests Passed!")
