;; 9sh Statistics Library
;; Depends on src/core/oop.fnl
(import-macros {: deftrait : defclass : impl} :src.core.macros)

(local oop   (require :src.core.oop))
(local stats {})

;; --- Traits ---

(deftrait Distribution "Trait for statistical distributions."
  (sample   []   "Draw random sample.")
  (mean     []   "E[X].")
  (variance []   "Var[X].")
  (pdf      [x]  "PDF(x)."))

(deftrait Sampler "Trait for random number generators."
  (next-float    [] "Float in [0, 1).")
  (next-gaussian [] "Standard normal sample."))


;; --- PRNG ---

(defclass PRNG [:seed] "Wrapper for math.random")

(impl PRNG Sampler
  (next-float    [s] (math.random))
  (next-gaussian [s]
    (let [u1 (math.random)
          u2 (math.random)]
      (* (math.sqrt (* -2 (math.log u1)))
         (math.cos  (* 2 math.pi u2))))))


;; --- Logic ---

(fn add-dist [a b] ((. stats.CompoundSum :new) a b))


;; --- Distributions ---
;; 1. Constant
(defclass Constant [:v] "Delta function.")
(impl Constant Distribution
  (sample    [s]   s.v)
  (mean      [s]   s.v)
  (variance  [s]   0)
  (pdf       [s x] (if (= x s.v) math.huge 0))
  (operator+ [s b] (add-dist s b)))


;; 2. Uniform
(defclass Uniform [:min :max] "Uniform [min, max].")
(impl Uniform Distribution
  (sample    [s]   (+ s.min (* (math.random) (- s.max s.min))))
  (mean      [s]   (/ (+ s.min s.max) 2))
  (variance  [s]   (/ (math.pow (- s.max s.min) 2) 12))
  (pdf       [s x] (if (and (>= x s.min) (<= x s.max))
                       (/ 1 (- s.max s.min)) 0))
  (operator+ [s b] (add-dist s b)))


;; 3. Gaussian
(defclass Gaussian [:mu :sigma] "Normal N(mu, sigma^2).")
(impl Gaussian Distribution
  (sample    [s]   (let [u1 (math.random)
                         u2 (math.random)
                         z  (* (math.sqrt (* -2 (math.log u1)))
                               (math.cos  (* 2 math.pi u2)))]
                     (+ s.mu (* s.sigma z))))
  (mean      [s]   s.mu)
  (variance  [s]   (* s.sigma s.sigma))
  (pdf       [s x] (let [d (* s.sigma (math.sqrt (* 2 math.pi)))
                         e (* -0.5 (math.pow (/ (- x s.mu) s.sigma) 2))]
                     (* (/ 1 d) (math.exp e))))
  (operator+ [s b] (add-dist s b)))


;; 4. Compound Sum (Result of A + B)
(defclass CompoundSum [:a :b] "Sum of independent dists.")
(impl CompoundSum Distribution
  (sample    [s]   (+ (s.a:sample) (s.b:sample)))
  (mean      [s]   (+ (s.a:mean)   (s.b:mean)))
  (variance  [s]   (+ (s.a:variance) (s.b:variance)))
  (pdf       [s x] (error "Convolution PDF TODO"))
  (operator+ [s b] (add-dist s b)))


(tset stats :Constant    oop.registry.classes.Constant)
(tset stats :Uniform     oop.registry.classes.Uniform)
(tset stats :Gaussian    oop.registry.classes.Gaussian)
(tset stats :CompoundSum oop.registry.classes.CompoundSum)
(tset stats :PRNG        oop.registry.classes.PRNG)

stats
