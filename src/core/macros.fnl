;; Macros for 9sh OOP System
;; Dense, aligned, tabular style.

(local fp (require :core.fp))


(fn deftrait [name doc ...]
  (let [mthd   {}
        name-s (tostring name)]
    (each [_ m (ipairs [...])]
      (let [mn (tostring (. m 1))
            ma (fp.map tostring (. m 2))
            md (. m 3)]
        (tset mthd mn {:args ma :doc md})))
    `(let [o# (require :core.oop)]
       (o#.deftrait ,name-s ,mthd ,doc))))


(fn defclass [name flds doc]
  (let [name-s (tostring name)]
    `(let [o# (require :core.oop)]
       (o#.defclass ,name-s ,flds ,doc))))


(fn impl [cls trt ...]
  (let [impls {}]
    (each [_ m (ipairs [...])]
      (let [n (tostring (. m 1))
            a (. m 2)
            b [(unpack m 3)]]
        (tset impls n `(fn ,a ,(unpack b)))))

    ;; Stringify the bare symbols for lookup
    `(let [o# (require :core.oop)
           c-name# ,(tostring cls)
           t-name# ,(tostring trt)
           c# (o#.class c-name#)
           t# (o#.trait t-name#)]
       (o#.impl c# t# ,impls))))


{:deftrait deftrait
 :defclass defclass
 :impl     impl}
