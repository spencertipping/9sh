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
$ cat 0
postgres://dev:5432/dev-db
$ cat 0///class
postgres-db
$ cat 0///host
dev
$ cat 0///port
5432
```
