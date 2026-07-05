# 9sh
**TODO:** rewrite everything; this is directional but needs focus

**NOTE:** mounted cylinders for `/`-scoped state, e.g. `/home/foo` is in `c0`, but `/home/foo/bar` might store its `///` state in `/home/foo/bar/.9sh.db`

**FIXME:** nothing in SQLite by default; `///` prototype state should be layered into UNIX FS so it can be version-controlled easily.

**NOTE:** `///` corresponds _exactly_ to a Lua table, with `///meta/get entry` and `///meta/ls`. It's worth defining `///` in detail as it's the entire substrate of types, VFS, everything.

**Q:** how does `///` exist for UNIX files? That's a cylinder-owned sidecar. We may want to standardize that format so we aren't doing e.g. `\002foo/...`, which has many other problems as well. So, we have 9sh-flavored directories and UNIX ones.


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
