# 9sh OOP
The great majority of data in 9sh is represented as an object, which enables it to be visible within the [VFS](vfs.md) and inspected using `///meta` + other introspection. 9sh's default metaclass provides VFS integration for free; for example:

``` fennel
;; Suppose we have a simple class like this
(let [ty nine.types
      c1 (nine:c1)
      db (c1:defclass :postgres-db)]
  (db:def (ty:str) :host)
  (db:def (ty:int) :port)
  (db:def (ty:str) :dbname)
  (db:defn :str #(.. "postgres://" $.host ":" $.port "/" $.dbname)))
```

Now we can observe existing instances of this class in the VFS:

``` sh
$ cd //9/c1/postgres-db
$ ls
0  1  2
$ cat 0///meta/class 0///fields/host 0///fields/port
postgres-db
dev
5432
$ 0///fn/str
postgres://dev:5432/dev-db
```

Class instances can implement traits to participate more fully in the VFS, but the third-moment meta lookups always provide `///meta` and, for class instances, `///fields`.


## `data` and `class`
A cylinder's data is stored in records, each of whose schema is specified by an immutable `data`. Since `data` schemas are immutable, they can meaningfully be used as echoes from within other cylinders; this allows objects to be distributed.

A `class` is an object that maintains a mutable schema and creates `data` objects as needed when instantiated. You can think of `data` as a git tree and `class` as a branch. This means `class` instances remain flexible while `data` snapshots are stable enough for distributed usage. (Metaclasses like `class` may provide migration paths to upgrade objects after changing the class definition.)


## `trait` and RTTI
A `trait` is a collection of behavior an object can opt into, but 9sh traits are predicated on _runtime state,_ not just type information:

``` fennel
(let [c1  (nine:c1)
      obj (c1.vfs:at "/foo/bar")  ; a VFS entry
      dir (nine.vfs.dir:on obj)]  ; a VFS dir or nil
  (if dir (do
    (ls dir))))
```

In 9sh, you downcast into traits rather than subclasses. If the object is mutable, trait-downcasts are implemented in a metaclass-determined way, but a simple strategy is to return a snapshot of the object at the moment that it implemented the trait. That is, nobody, even members of the same cylinder, can revoke your successfully-downcast object.

This system is useful for distributed applications, but it isn't perfect: consider a nominally immutable object that wraps a UNIX path. Because the OS is the ultimate state owner and can modify the FS object out from under us, we need to escalate to a file descriptor to reliably invoke trait behavior:

``` fennel
(let [ty  nine.types
      c1  (nine:c1)
      cls (c1:class :unix-path)]
  (cls:def     (ty:str) :path)
  (cls:defctor (fn [this path] (tset this :path path)))

  (cls:impl nine.vfs.dir
    ;; Determine whether we implement the trait...
    #(let [fd (posix.open $.path)]
       (if (. (posix.fstat fd) :is-dir)
         {: fd}))  ; ...if we do, the FD is proof (and becomes self)

    :gc #(close $)

    ;; Within these method definitions, self is the FD we created
    ;; above.
    {:close #(posix.close   $.fd)
     :ls    #(posix.readdir $.fd)})
```

Now we have reliability, but at the cost of extra FDs that aren't explicitly freed unless we call `close` on them. We install a GC handler as a fallback.

It's worth noting that trait objects are cached and reused: in the example above, we'd open at most one FD per distinct UNIX path object.


## Trait echoes
Because trait objects are derived and not canonical, you don't echo them. Instead, you echo the underlying object and downcast it locally.
