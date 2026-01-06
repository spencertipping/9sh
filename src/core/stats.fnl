;; 9sh Statistics Library
;; Depends on src/core/oop.fnl
(import-macros {: deftrait : defclass : impl} :src.core.macros)

(local oop (require :src.core.oop))
(local stats {})

;; --- Traits ---

(deftrait Distribution "Trait for statistical distributions."
  (sample   []   "Draw a random sample from the distribution.")
  (mean     []   "Expected value E[X].")
  (variance []   "Variance Var[X].")
  (pdf      [x]  "Probability Density Function at x."))

(deftrait Sampler "Trait for random number generators."
  (next-float    [] "Return a float in [0, 1).")
  (next-gaussian [] "Return a standard normal sample (mean 0, std 1)."))

;; --- PRNG Implementation ---

(defclass PRNG [:param-seed] "Pseudo-Random Number Generator wrapper around Lua's math.random")

(impl :PRNG :Sampler
  {:next-float (fn [self] (math.random))
   :next-gaussian (fn [self]
                    ;; Box-Muller transform
                    (let [u1 (math.random)
                          u2 (math.random)]
                      (* (math.sqrt (* -2 (math.log u1)))
                         (math.cos (* 2 math.pi u2)))))})

;; --- Arithmetic Logic ---

(fn add-dist [a b]
  (let [stats-mod (require :src.core.stats)
        Compound stats-mod.CompoundSum]
    (Compound.new a b)))


;; --- Distributions ---

;; 1. Constant
(defclass Constant [:val] "Deterministic distribution (delta function).")
(impl :Constant :Distribution
  {:sample (fn [self] self.val)
   :mean   (fn [self] self.val)
   :variance (fn [self] 0)
   :pdf    (fn [self x] (if (= x self.val) math.huge 0))})
(oop.registry.classes.Constant:overload+ add-dist)

;; 2. Uniform
(defclass Uniform [:min :max] "Uniform distribution [min, max].")
(impl :Uniform :Distribution
  {:sample (fn [self] (+ self.min (* (math.random) (- self.max self.min))))
   :mean   (fn [self] (/ (+ self.min self.max) 2))
   :variance (fn [self] (/ (math.pow (- self.max self.min) 2) 12))
   :pdf    (fn [self x] (if (and (>= x self.min) (<= x self.max))
                            (/ 1 (- self.max self.min))
                            0))})
(oop.registry.classes.Uniform:overload+ add-dist)

;; 3. Gaussian
(defclass Gaussian [:mu :sigma] "Normal distribution N(mu, sigma^2).")
(impl :Gaussian :Distribution
  {:sample (fn [self]
             (let [u1 (math.random)
                   u2 (math.random)
                   std-normal (* (math.sqrt (* -2 (math.log u1)))
                                 (math.cos (* 2 math.pi u2)))]
               (+ self.mu (* self.sigma std-normal))))
   :mean   (fn [self] self.mu)
   :variance (fn [self] (* self.sigma self.sigma))
   :pdf    (fn [self x]
             (let [denom (* self.sigma (math.sqrt (* 2 math.pi)))
                   exponent (* -0.5 (math.pow (/ (- x self.mu) self.sigma) 2))]
               (* (/ 1 denom) (math.exp exponent))))})
(oop.registry.classes.Gaussian:overload+ add-dist)

;; 4. Compound Sum (Result of A + B)
(defclass CompoundSum [:a :b] "Sum of two independent distributions.")
(impl :CompoundSum :Distribution
  {:sample (fn [self] (+ (self.a:sample) (self.b:sample)))
   :mean   (fn [self] (+ (self.a:mean) (self.b:mean)))
   :variance (fn [self] (+ (self.a:variance) (self.b:variance)))
   :pdf    (fn [self x] (error "Convolution PDF not implemented yet"))})
(oop.registry.classes.CompoundSum:overload+ add-dist)

(tset stats :Constant oop.registry.classes.Constant)
(tset stats :Uniform oop.registry.classes.Uniform)
(tset stats :Gaussian oop.registry.classes.Gaussian)
(tset stats :CompoundSum oop.registry.classes.CompoundSum)
(tset stats :PRNG oop.registry.classes.PRNG)

stats
