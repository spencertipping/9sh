;; Verification Script for OOP and Stats

(import-macros {: deftrait : defclass : impl} :src.core.macros)
(local oop (require :src.core.oop))
(local stats (require :src.core.stats))

(print "--- Testing OOP Macros ---")
(defclass Person [:name :age] "A person class")
(local p (oop.registry.classes.Person.new "Alice" 30))
(print "Created person:" p.name p.age)

(print "--- Testing Stats ---")
(local g1 (stats.Gaussian.new 0 1))
(local g2 (stats.Gaussian.new 10 2))

(print "G1: mu=" (g1:mean) " var=" (g1:variance))

(print "--- Testing Introspection ---")
(print "Doc for Distribution.mean:" (oop.doc oop.registry.traits.Distribution :mean))

(print "--- Testing Bidirectionality ---")
(local dist-trait oop.registry.traits.Distribution)
(local gaussian-cls oop.registry.classes.Gaussian)

(print "Trait knows Gaussian?" (. (. dist-trait.classes "Gaussian") :name))
(assert (= (. dist-trait.classes "Gaussian") gaussian-cls))
(assert gaussian-cls.traits.Distribution)

(print "Verification Complete.")
