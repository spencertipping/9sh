# 9sh
**TODO:** iterate on the structure here; the core ideas are not yet focused



POSIX defines physics for the local machine and `sh` is the user interface. 9sh is C++ to POSIX's C:

1. 9sh preserves POSIX semantics in-place in almost all cases
2. 9sh physics govern a distributed fabric, not just the local machine
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

`>` changes meaning within `grep` in the last example; this is an example of type-informed parse polymorphism.




**TODO:** figure out whether these form the right basis for README-adjacent documents

+ [doc/commands.md](doc/commands.md) for command-execution machinery
+ [doc/cylinders.md](doc/cylinders.md) for the distributed-computing abstractions
+ [doc/vfs.md](doc/vfs.md) for `/` overloading
