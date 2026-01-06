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
  (next-float    [self] (math.random))
  (next-gaussian [self]
    ;; Box-Muller transform
    (let [u1 (math.random)
          u2 (math.random)]
      (* (math.sqrt (* -2 (math.log u1)))
         (math.cos (* 2 math.pi u2))))))

;; --- Arithmetic Logic ---

(fn add-dist [a b]
  (let [stats-mod (require :src.core.stats)
        Compound stats-mod.CompoundSum]
    (Compound.new a b)))


;; --- Distributions ---

;; 1. Constant
(defclass Constant [:val] "Deterministic distribution (delta function).")
(impl :Constant :Distribution
  (sample     [self]   self.val)
  (mean       [self]   self.val)
  (variance   [self]   0)
  (pdf        [self x] (if (= x self.val) math.huge 0))
  (operator+  [self b] (add-dist self b)))


;; 2. Uniform
(defclass Uniform [:min :max] "Uniform distribution [min, max].")
(impl :Uniform :Distribution
  (sample     [self]   (+ self.min (* (math.random) (- self.max self.min))))
  (mean       [self]   (/ (+ self.min self.max) 2))
  (variance   [self]   (/ (math.pow (- self.max self.min) 2) 12))
  (pdf        [self x] (if (and (>= x self.min) (<= x self.max))
                           (/ 1 (- self.max self.min))
                           0))
  (operator+  [self b] (add-dist self b)))


;; 3. Gaussian
(defclass Gaussian [:mu :sigma] "Normal distribution N(mu, sigma^2).")
(impl :Gaussian :Distribution
  (sample     [self]   (let [u1 (math.random)
                             u2 (math.random)
                             z  (* (math.sqrt (* -2 (math.log u1)))
                                   (math.cos (* 2 math.pi u2)))]
                         (+ self.mu (* self.sigma z))))
  (mean       [self]   self.mu)
  (variance   [self]   (* self.sigma self.sigma))
  (pdf        [self x] (let [den (* self.sigma (math.sqrt (* 2 math.pi)))
                             exp (* -0.5 (math.pow (/ (- x self.mu) self.sigma) 2))]
                         (* (/ 1 den) (math.exp exp))))
  (operator+  [self b] (add-dist self b)))


;; 4. Compound Sum (Result of A + B)
(defclass CompoundSum [:a :b] "Sum of two independent distributions.")
(impl :CompoundSum :Distribution
  (sample     [self]   (+ (self.a:sample) (self.b:sample)))
  (mean       [self]   (+ (self.a:mean) (self.b:mean)))
  (variance   [self]   (+ (self.a:variance) (self.b:variance)))
  (pdf        [self x] (error "Convolution PDF not implemented yet"))
  (operator+  [self b] (add-dist self b)))

(tset stats :Constant oop.registry.classes.Constant)
(tset stats :Uniform oop.registry.classes.Uniform)
(tset stats :Gaussian oop.registry.classes.Gaussian)
(tset stats :CompoundSum oop.registry.classes.CompoundSum)
(tset stats :PRNG oop.registry.classes.PRNG)

stats
