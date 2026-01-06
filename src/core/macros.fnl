;; Macros for 9sh OOP System
;; Dense, aligned, tabular style.

(local fp (require :src.core.fp))

(fn deftrait [name doc ...]
  (let [meths    {}
        name-s   (tostring name)]
    (each [_ m (ipairs [...])]
      (let [mn (tostring (. m 1))
            ma (fp.map tostring (. m 2))
            md (. m 3)]
        (tset meths mn {:args ma :doc md})))
    `(let [o# (require :src.core.oop)]
       (o#.deftrait ,name-s ,meths ,doc))))

(fn defclass [name flds doc]
  (let [name-s (tostring name)]
    `(let [o# (require :src.core.oop)]
       (o#.defclass ,name-s ,flds ,doc))))

(fn impl [cls trt ...]
  (let [method-impls {}]
    (each [_ m (ipairs [...])]
      (let [name (tostring (. m 1))
            args (. m 2)
            ;; The body is the rest of the list after args
            ;; slice is 3 to end
            body [(unpack m 3)]]
        (tset method-impls name `(fn ,args ,(unpack body)))))

    `(let [o# (require :src.core.oop)
           c# (if (= (type ,cls) "string") (o#.class ,cls) ,cls)
           t# (if (= (type ,trt) "string") (o#.trait ,trt) ,trt)]
       (o#.impl c# t# ,method-impls))))

{:deftrait deftrait
 :defclass defclass
 :impl     impl}
