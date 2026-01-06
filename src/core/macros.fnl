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

(fn impl [cls trt meths]
  `(let [o# (require :src.core.oop)
         c# (if (= (type ,cls) "string") (o#.class ,cls) ,cls)
         t# (if (= (type ,trt) "string") (o#.trait ,trt) ,trt)]
     (o#.impl c# t# ,meths)))

{:deftrait deftrait
 :defclass defclass
 :impl     impl}
