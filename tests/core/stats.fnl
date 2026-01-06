(import-macros {: deftrait : defclass : impl} :src.core.macros)
(local oop   (require :src.core.oop))
(local stats (require :src.core.stats))

(print "--- OOP Macros ---")
(defclass Person [:name :age] "Person class")
(local p (oop.registry.classes.Person.new "Alice" 30))
(print "Created person:" p.name p.age)

(print "--- Stats ---")
(local g1 (stats.Gaussian.new 0 1))
(local g2 (stats.Gaussian.new 10 2))

(print "G1: mu=" (g1:mean) " var=" (g1:variance))
(local g3 (+ g1 g2))
(print "G3 (G1+G2): mu=" (g3:mean) " var=" (g3:variance))
(assert (= (g3:mean) (+ (g1:mean) (g2:mean))))

(print "--- Introspection ---")
(print "Doc for Distribution.mean:" (oop.doc oop.registry.traits.Distribution :mean))

(print "--- Bidirectionality ---")
(local T oop.registry.traits.Distribution)
(local C oop.registry.classes.Gaussian)

(print "Trait knows Gaussian?" (. (. T.classes "Gaussian") :name))
(assert (= (. T.classes "Gaussian") C))
(assert C.traits.Distribution)

(print "Verification Complete.")
