;; Functional Programming Utilities

(local fp {})


(macro returning [b & body]
  (let [n (tostring (. b 1))]
    `(let [,(unpack b)]
       (var ,(sym n) ,(sym n))
       ,(unpack body)
       ,(sym n))))


(fn fp.map     [f xs] (returning [ys []] (each [_ x (ipairs xs)] (table.insert ys (f x)))))
(fn fp.grep    [p xs] (returning [ys []] (each [_ x (ipairs xs)] (if (p x) (table.insert ys x)))))

(fn fp.flatmap [f xs] (returning [ys []] (each [_ x (ipairs xs)] (each [_ y (ipairs (f x))] (table.insert ys y)))))

(fn fp.reduce  [f a xs] (returning [r a] (each [_ x (ipairs xs)] (set r (f r x)))))
(fn fp.foldl   [f a xs] (fp.reduce f a xs))
(fn fp.foldr   [f a xs] (returning [r a] (for [i (length xs) 1 -1] (set r (f (. xs i) r)))))

(fn fp.any [p xs] (returning [r false] (each [_ x (ipairs xs)] (if (p x)      (do (set r true)  (lua "break"))))))
(fn fp.all [p xs] (returning [r true]  (each [_ x (ipairs xs)] (if (not (p x)) (do (set r false) (lua "break"))))))


(fn fp.keys       [t]  (returning [ys []] (each [k _ (pairs t)]  (table.insert ys k))))
(fn fp.vals       [t]  (returning [ys []] (each [_ v (pairs t)]  (table.insert ys v))))
(fn fp.kv-pairs   [t]  (returning [ys []] (each [k v (pairs t)]  (table.insert ys [k v]))))
(fn fp.from-pairs [xs] (returning [t  {}] (each [_ p (ipairs xs)] (tset t (. p 1) (. p 2)))))


fp
