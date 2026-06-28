# 9sh
POSIX defines operational physics and a user interface for local computation. `9sh` operates from `sh`'s vantage point to provide unprivileged, subjective distributed orchestration. Specifically:

1. 9sh preserves POSIX semantics in-place in almost all cases
2. 9sh physics govern a subjective distributed fabric _through and beyond_ the local machine
3. The 9sh interface provides comprehensive overloading and consistency

This architecture allows 9sh to use POSIX-adjacent syntax to represent a wide variety of different local and distributed operations; for example:

``` sh
$ cat file | grep foo | zstd > matches  # normal command

$ cat //host/*/data | grep foo \
    | zstd > //host/*/matches  # distributed parallel

$ cat //host/*//db/foo | grep bar > 10 \
    | cut -f foo,bar \
    | sort -k bar:asc \
    | zstd > rows.csv.zst  # distributed database
```

Note that `>` changes meaning within `grep` in the last example; this is an example of type-informed parse polymorphism, a core feature of 9sh's grammar and optimizer.


**TODO:** formalize _liability → legibility_ -- i.e. relativistic circuits of coupled causality between cylinders

**TODO:** clarify that cylinders form the basis of legibility; everything is legible _to a cylinder_ and ACKs convey that legibility

**NOTE:** actors convey but conserve legibility; they neither create nor destroy it.


**TODO:** define the layout of `///` in detail


**TODO:** figure out whether these form the right basis for README-adjacent documents

+ [doc/commands.md](doc/commands.md) for command-execution machinery
+ [doc/cylinders.md](doc/cylinders.md) for the distributed-computing abstractions
+ [doc/vfs.md](doc/vfs.md) for `/` overloading
