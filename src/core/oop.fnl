;; 9sh OOP System
;; Provides traits, classes, and introspection via metatables.

(local oop {})
(local unpack (or table.unpack _G.unpack))


;; --- Registry & Introspection ---

(local registry {:classes {} :traits {}})
(tset oop :registry registry)

(fn oop.is? [obj t]
  (if (and (= (type obj) "table") obj.__class)
      (or (= obj.__class t)
          (and t.trait (obj.__class:implements? t)))
      false))

(fn oop.class [n] (. registry.classes n))
(fn oop.trait [n] (. registry.traits n))


;; Documentation helpers
(local Documentation {})
(set Documentation.trait true)
(set Documentation.methods {:doc {:args [:e] :doc "Get documentation for an element."}})
(tset registry.traits "Documentation" Documentation)

(fn oop.doc [o e]
  (if (and (= (type o) "table") o.doc) (o:doc e) nil))


;; --- Trait Definition ---

(fn oop.deftrait [name methods & doc]
  (let [t {:trait   true
           :name    name
           :methods methods
           :classes {}
           :doc     (or (unpack doc) "")}]

    (tset registry.traits name t)

    ;; Generate invocation helpers
    (each [m _ (pairs methods)]
      (tset oop m (fn [self ...]
                    (if (and self self.__class (self.__class:implements? t))
                        ((. self m) self ...)
                        (error (string.format "Object missing trait %s for method %s" name m))))))

    (fn t.doc [self e] (if (= e nil) self.doc (. self.methods e :doc)))
    t))


;; --- Class Definition ---

(local Class {})
(tset  Class :__index Class)

;; Operator overloads
(fn Class.overload+         [s f] (tset s.prototype :__add      f))
(fn Class.overload-         [s f] (tset s.prototype :__sub      f))
(fn Class.overload*         [s f] (tset s.prototype :__mul      f))
(fn Class.overload/         [s f] (tset s.prototype :__div      f))
(fn Class.overload%         [s f] (tset s.prototype :__mod      f))
(fn Class.overload^         [s f] (tset s.prototype :__pow      f))
(fn Class.overload-call     [s f] (tset s.prototype :__call     f))
(fn Class.overload-index    [s f] (tset s.prototype :__index    f))
(fn Class.overload-concat   [s f] (tset s.prototype :__concat   f))
(fn Class.overload-len      [s f] (tset s.prototype :__len      f))
(fn Class.overload-eq       [s f] (tset s.prototype :__eq       f))
(fn Class.overload-lt       [s f] (tset s.prototype :__lt       f))
(fn Class.overload-le       [s f] (tset s.prototype :__le       f))
(fn Class.overload-tostring [s f] (tset s.prototype :__tostring f))

(fn Class.overload-band     [s f] (tset s.prototype :__band     f))
(fn Class.overload-bor      [s f] (tset s.prototype :__bor      f))
(fn Class.overload-bxor     [s f] (tset s.prototype :__bxor     f))
(fn Class.overload-bnot     [s f] (tset s.prototype :__bnot     f))
(fn Class.overload-shl      [s f] (tset s.prototype :__shl      f))
(fn Class.overload-shr      [s f] (tset s.prototype :__shr      f))
(fn Class.overload-idiv     [s f] (tset s.prototype :__idiv     f))


(fn oop.defclass [name fields & doc]
  (let [cls {:name      name
             :fields    fields
             :methods   {}
             :traits    {}
             :prototype {}
             :doc       (or (unpack doc) "")}]

    (tset cls.prototype :__index cls.prototype)
    (tset cls.prototype :__class cls)

    (setmetatable cls Class)
    (tset cls :__index cls)

    (set cls.new (fn [...]
                   (let [inst (setmetatable {} cls.prototype)
                         ctor (. cls.prototype :init)]
                     (each [_ f (ipairs fields)] (tset inst f nil))
                     (if ctor (ctor inst ...)
                         (each [i v (ipairs [...])]
                           (let [f (. fields i)] (if f (tset inst f v)))))
                     inst)))

    (fn cls.implements? [self t] (. self.traits t.name))
    (fn cls.doc [self e] (if (= e nil) self.doc (. self.methods e :doc)))

    (tset registry.classes name cls)
    cls))


(fn oop.impl [cls trait methods]
  (if (not trait.trait) (error "Second argument must be a trait"))

  (each [m _ (pairs trait.methods)]
    (if (= (. methods m) nil)
        (error (string.format "Missing impl for %s of %s in %s" m trait.name cls.name))))

  (each [m f (pairs methods)]
    (tset cls.prototype m f)
    (let [op-map {"operator+"         :__add
                  "operator-"         :__sub
                  "operator*"         :__mul
                  "operator/"         :__div
                  "operator%"         :__mod
                  "operator^"         :__pow
                  "operator-call"     :__call
                  "operator-index"    :__index
                  "operator-concat"   :__concat
                  "operator-len"      :__len
                  "operator-eq"       :__eq
                  "operator-lt"       :__lt
                  "operator-le"       :__le
                  "operator-tostring" :__tostring
                  "operator-band"     :__band
                  "operator-bor"      :__bor
                  "operator-bxor"     :__bxor
                  "operator-bnot"     :__bnot
                  "operator-shl"      :__shl
                  "operator-shr"      :__shr
                  "operator-idiv"     :__idiv}
          mm     (. op-map m)]
      (if mm (tset cls.prototype mm f))))

  (tset cls.traits    trait.name true)
  (tset trait.classes cls.name   cls))


oop
