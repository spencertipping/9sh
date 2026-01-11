# 9sh objects and traits
``` fennel
(local foo
  ;; FIXME: we don't want a macro here; this should allow control flow
  ;; inside the class body.
  (nine.class.persistent
    (field name :str)
    (field xs   :table)))
```

**TODO:** document local DB persistence, the 9shrc queue, and staging

**Situation:** we want to live-configure stuff without tons of reloading; but nobody wants to version-control a SQLite database. The default metaclass's persistence system tracks configured-vs-live changes and can append blocks for the user to append to a `9shrc` file.
