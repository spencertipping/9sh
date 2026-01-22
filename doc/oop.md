# 9sh OOP
The great majority of data in 9sh is represented as an object, which enables it to be visible within the [VFS](vfs.md) and inspected using `///meta` + other introspection. 9sh's default metaclass provides VFS integration for free; for example:

``` fennel
;; Define a trivial class to represent something
(let [ty nine.types
      ts nine.traits
      c1 (nine:c1)
      db (c1:defclass :postgres-db)]
  (db:def (ty:str) :host)
  (db:def (ty:int) :port)
  (db:def (ty:str) :dbname)
  (db:def :str #(.. "postgres://" $.host ":" $.port "/" $.dbname)))
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
```

Class instances can implement traits to participate more fully in the VFS, but the third-moment meta lookups always provide `///meta` and, for class instances, `///fields`.
