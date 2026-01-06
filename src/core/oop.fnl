;; 9sh OOP System
;; Provides traits, classes, and introspection via metatables.

(local oop {})
;; Fix for Fennel strictness regarding unpack
(local unpack (or table.unpack _G.unpack))

;; --- Registry & Introspection ---

;; Registry of all defined classes and traits for type checking
(local registry {:classes {} :traits {}})
(tset oop :registry registry)

(fn oop.is? [obj type-def]
  "Check if `obj` is an instance of `type-def` (class or trait)."
  (if (and (= (type obj) "table") obj.__class)
      (or (= obj.__class type-def)
          (and type-def.trait (obj.__class:implements? type-def)))
      false))

(fn oop.class [name] (. registry.classes name))
(fn oop.trait [name] (. registry.traits name))

;; Documentation trait defining the interface for introspecting docs.
;; Intentionally defined manually to bootstrap the system.
(local Documentation {})
(set Documentation.trait true)
(set Documentation.methods {:doc {:args [:element] :doc "Get documentation for an element."}})
(tset registry.traits "Documentation" Documentation)

(fn oop.doc [obj element]
  "Get documentation for an object or one of its elements."
  (if (and (= (type obj) "table") obj.doc)
      (obj:doc element)
      nil))

;; --- Trait Definition ---

(fn oop.deftrait [name methods & doc]
  "Define a new trait with method signatures and documentation.
   methods: {:method-name {:args [:arg1] :doc \"description\"}}"
  (let [trait {:trait true
               :name name
               :methods methods
               :classes {} ;; Bidirectional: List of classes implementing this trait
               :doc (or (unpack doc) "")}]

    ;; Register
    (tset registry.traits name trait)

    ;; Generate invocation helpers for each method
    (each [m-name m-spec (pairs methods)]
      (tset oop m-name (fn [self ...]
                         (if (and self self.__class (self.__class:implements? trait))
                             ((. self m-name) self ...)
                             (error (string.format "Object does not implement trait %s for method %s" name m-name))))))

    ;; Documentation Implementation for Trait
    (fn trait.doc [self element]
       (if (= element nil) self.doc
           (. self.methods element :doc)))

    trait))


;; --- Class Definition ---

(local Class {})
(tset Class :__index Class)

(fn Class.overload+         [self f] (tset self :__add      f))
(fn Class.overload-         [self f] (tset self :__sub      f))
(fn Class.overload*         [self f] (tset self :__mul      f))
(fn Class.overload/         [self f] (tset self :__div      f))
(fn Class.overload%         [self f] (tset self :__mod      f))
(fn Class.overload^         [self f] (tset self :__pow      f))
(fn Class.overload-concat   [self f] (tset self :__concat   f))
(fn Class.overload-len      [self f] (tset self :__len      f))
(fn Class.overload-eq       [self f] (tset self :__eq       f))
(fn Class.overload-lt       [self f] (tset self :__lt       f))
(fn Class.overload-le       [self f] (tset self :__le       f))
(fn Class.overload-tostring [self f] (tset self :__tostring f))

;; Bitwise & Integer Ops (Lua 5.3+ / LuaJIT 2.1+)
(fn Class.overload-band    [self f] (tset self :__band     f))
(fn Class.overload-bor     [self f] (tset self :__bor      f))
(fn Class.overload-bxor    [self f] (tset self :__bxor     f))
(fn Class.overload-bnot    [self f] (tset self :__bnot     f))
(fn Class.overload-shl     [self f] (tset self :__shl      f))
(fn Class.overload-shr     [self f] (tset self :__shr      f))
(fn Class.overload-idiv    [self f] (tset self :__idiv     f))

(fn oop.defclass [name fields & doc]
  "Define a new class."
  (let [cls {:name name
             :fields fields
             :methods {}
             :traits {}
             :doc (or (unpack doc) "")}]

    ;; Class Metaclass (for overload+)
    (setmetatable cls Class)

    ;; Setup class as its own metatable (for __index and operators)
    (tset cls :__index cls)

    ;; Constructor
    (set cls.new (fn [...]
                   (let [instance (setmetatable {} cls) ;; Use cls as metatable directly
                         ctor (. cls :init)]
                     ;; Initialize fields
                     (each [_ f (ipairs fields)] (tset instance f nil))
                     (set instance.__class cls)
                     (if ctor
                         (ctor instance ...)
                         ;; Default Init: Map args to fields
                         (each [i val (ipairs [...])]
                               (let [f (. fields i)]
                                 (if f (tset instance f val)))))
                     instance)))

    ;; Trait check
    (fn cls.implements? [self trait]
      (. self.traits trait.name))

    ;; Documentation Implementation (Bootstrapped)
    ;; Using dot syntax with explicit self
    (fn cls.doc [self element]
      (if (= element nil) self.doc
          (. self.methods element :doc)))

    (tset registry.classes name cls)
    cls))


(fn oop.impl [cls trait methods]
  "Implement a trait for a class."
  (if (not trait.trait) (error "Second argument must be a trait"))

  ;; verify all methods are present
  (each [m-name _ (pairs trait.methods)]
    (if (= (. methods m-name) nil)
        (error (string.format "Missing implementation for method %s of trait %s in class %s" m-name trait.name cls.name))))

  ;; Copy methods to class
  (each [m-name impl-fn (pairs methods)]
    (tset cls m-name impl-fn)

    ;; Check for operator overloading aliases
    (let [op-map {"operator+"         :__add
                  "operator-"         :__sub
                  "operator*"         :__mul
                  "operator/"         :__div
                  "operator%"         :__mod
                  "operator^"         :__pow
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
          metamethod (. op-map m-name)]
      (if metamethod
          (tset cls metamethod impl-fn))))

  (tset cls.traits    trait.name true)
  (tset trait.classes cls.name   cls))


oop
