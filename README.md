# 9sh
**Under active development; nothing works yet**

A distributed UNIX shell incorporating design elements from Plan 9, Tcl, Haskell, SQL, Self, Slack, and Emacs. A quick summary:

+ POSIX shell constructs generally work, warts and all -- bash constructs less so
+ Scripting is either shell-style or in Fennel (a Clojure-flavored Lisp for LuaJIT)
+ Background jobs in 9sh start with `@` and are much more powerful than they are in bash
+ Command parsing is POSIX-compatible, but overloads are resolved with Hindley-Milner and DoFs are statistically optimized
+ Directories form a VFS built from LuaJIT objects
+ `$PWD` functions as an implicitly-imported package, influencing available commands, scoped variables, grammars, types, optimization preferences, and other quasi-globals
+ 9sh implements distributed OOP with local SQLite state (accessible with VFS)

The result is a shell where background jobs are interactive, map/reduce can be inferred from commands like `cat //input/* | grep foo | sort | uniq > //output/*`, you can `cd` into remote hosts, and directories own local state activated when you `cd` into them.


## Parse → execution pipeline
``` sh
cat //input/* | grep foo | sort | uniq -c > //output/*
```

9sh processes the above line like this:

``` fennel
(let [command (PWD:command (line:match "^%S+"))  ; ask VFS PWD to resolve command
      parser  (command:parser PWD)               ; construct parser
      parsed  (parser:parse line)                ; typed ASTs
      linked  (grep #(not= $ nil)
                    (map #($:link) parsed))      ; unify types
      ;; TODO: choose "best" of the linked alternatives
      ;; (how is best defined? do we optimize across all?)
      opt     (linked:optimize)]                 ; optimize DoFs
  (opt:execute))                                 ; execute the plan
```

When running interactively, the parse and link phases happen on every modification to the input line. `(command:parser)` is an arbitrary combinatory parser that provides syntax highlighting and autocompletion hints as the user is typing. Note that it doesn't block on the VFS or RPC; remote resources may arrive later to provide refined type options. However, command execution _does_ block on RPC because the executed outcome must be consistent.


## Command grammar
9sh aims for POSIX compatibility in the general case:

``` sh
cat foo/bar | grep bif | sort | uniq -c > bif-counts
ext=c find -name "*.$ext" | wc -l
which foo 2>/dev/null || echo 'foo not installed'
if [ -n "$ext" ]; then
  echo "nonzero length for extension $ext"
fi
```

However, its grammar is not strict. 9sh uses an overloaded, object-oriented Tcl-style parser delegation strategy with type inference to resolve overloads, which promotes `|` into a _semantic_ composition operator, not necessarily a literal FIFO:

``` sh
cat db/table | grep x > 100 | sel foo bar | sort-by foo:desc | zstd > foo.csv.zst
```

Mechanically:

```
cat db/table     ::                        DB (db-type db) (Table table)
grep x > 100     :: Has t 'x            => DB d t -> DB d t
sel foo bar      ::                        DB d t -> DB d (foo t, bar t)
sort-by foo:desc :: Has t 'foo          => DB d t -> DB d t
zstd             :: Stream s            => s x -> s (Zstd x)
> foo.csv.zst    :: Stream s, CsvHint f => s (Zstd f) -> IO ()
```

**TODO:** fix types above; they're the right idea but are not literally correct. Also, let's get into how alternatives interact with the type system.

`db/table` is a VFS entry containing database connection metadata, including the table name. DB tables are often both streamable and listable, meaning that they act as files and directories simultaneously: `cat table` and `cd table` both work.

The `DB` type creates a SQL context that can be unified across those commands to fuse them into a single query. `DB d t -> Pipe CSV` is a well-defined implicit conversion, which `CsvHint f` suggests with high affinity. Since `Zstd` carries this information across the type boundary, it's unified leftwards to the DB export step.

`grep x > 100 | ...` is valid POSIX syntax, but POSIX `grep` can't be unified to the `DB` type. As a result we choose the `DB` alternative of `grep`, whose grammar interprets `>` as part of a SQL expression rather than as a file redirection operator.

It may seem problematic that type unification and the grammar can interact. In practice it's not such an issue: although we parse every alternative for a command, we memoize the parse by starting position such that common suffixes will be cached. This means that as long as a command doesn't cannibalize `|` itself, it just creates a local alternative and doesn't fork the whole parse continuation. (Commands can also create bigger forks by consuming `|`; the only downside is performance.)


### VFS parse delegation
You can think of bash as using a monomorphic parsing strategy: the line is first split on words, then the command is resolved according to `$PATH` (or to a special form like `if`) and args are passed in as an array via `exec()`, or using the bulitin syntax. Forms like `<(grep foo bar)` are transformed into `/dev/fd/x` monomorphically as well.

**TODO**


## VFS
The VFS, an object-oriented superstructure over the UNIX filesystem, is modeled in terms of directory-resolution _moments:_

+ `foo/bar` resolves `bar` using the first resolution-moment of `foo`
+ `foo//bar` uses the second moment (common)
+ `foo///bar` uses the third moment (uncommon; this is usually for metadata)

Note that 9sh's VFS is not visible to UNIX processes. If you write `cat //vfs/file`, POSIX `cat` won't run; instead, a stream will be made from the virtual file contents. This approach is made consistent with stream types, covered below. Remote data is handled by either moving a process to the remote system (if possible), or by FIFO-streaming the data to the local one.


### Higher-moment roots
Only the first moment has a true root directory: `//` == `.//`, `///` == `.///`, and so on. The second moment of the UNIX root is written as `/.//`, but you will rarely if ever need to use it.

We do this to provide _root polymorphism for higher moments:_ functionally, `//` is both the root of the second-order VFS filesystem and it's contextually dependent on the directory you used to access it. That is, `cd foo` is allowed to add entries to the `//` tree. In order to make this consistent, we model that specific `//` tree as being local to the PWD used to access it. Same for `///`, which is more explicitly localized.

Conventionally, `/` is used for _concrete files,_ `//` for _synthetic shortcuts,_ and `///` to access configuration. 9sh supports arbitrarily high moments, but only the first three have behavior defined by the standard library.

`///` is used to inspect objects. `less ///help` will tell you about the capabilities of the current directory, for example. `///help` is defined for every VFS object, as are `///source`, `///methods`, and other meta-files. `///` also tells you about parser overloads, inheritance, and commands.


### VFS traits
VFS entries support operations like `ls`, `cat`, `stat`, etc by implementing OOP traits that specify certain methods; for example:

``` fennel
(deftrait VFS.RandomRead  ; enables efficient tail
  (size)
  (read len pos))

(deftrait VFS.StreamRead  ; enables cat
  (stream))

(deftrait VFS.LocalFile   ; enables use with POSIX commands
  (realpath))

(deftrait VFS.Directory
  (ls moment)             ; list entries at a moment
  (at moment child pwd)   ; resolve child at moment
```

Some traits are about behavior rather than file properties. This is how the VFS influences command resolution and namespacing:

``` fennel
(deftrait VFS.Namespace
  (def name val)
  (get name)
  (vars))

(deftrait VFS.Tenancy     ; specifies where something exists natively
  (host))

(deftrait VFS.Entry       ; a named point in the VFS
  (types))                ; a list of {:type :entry} objects
```

Note that these traits are unrelated to the types used to unify command alternatives -- the bridge is the `types` method of `VFS.Entry`, which provides a list of potential refined types for a given VFS node. A name might have multiple types because something like `foo/*` is a wildcard (expandable to a list of files), which we can see as a sequenced stream of filenames or as a sharded collection. Similarly, `cat foo.gz` might be a `(GZip Byte)` or just `Byte`. Absent performance optimization, we prefer the resolution with the greatest amount of type information.


## Stream typing
9sh types have several properties:

+ 9sh will never reject a POSIX shell command, regardless of type
  + Specifically, 9sh types are not used for verification
+ 9sh types are erased at exec-time; their only purpose is to choose alternatives and propagate configuration
+ VFS entries can provide type information
+ Types can and often should be ambiguous; if they are, 9sh will use statistical optimization to disambiguate
  + Every degree of freedom is a degree of optimization

**TODO:** refine this taxonomy; the idea is right but the proposed implementation is not

`Pipe` is a simple FIFO stream on the local system, but 9sh comes with types that describe data locality, sharding, partitioning, and other traits useful for map/reduce operations. This is what enables `cat foo/*` to carry information about file partitioning. If `foo` is a VFS union of remote files, we'll want to move `grep` to the data rather than streaming it all across the network -- therefore, `foo/* :: RemoteFiles ...`. `RemoteFiles` satisfies `Stream`, but it also satisfies `Sharded` and `Remote` which provide enough information to move `grep` to the data.

`Sharded` is the mechanism by which `cat input/* | ... > output/*` can maintain partition boundaries and parallelize the work. This behavior is activated by `> output/*`; although POSIX `sh` does support `> *` as syntax (meaning, create a file called `*` and direct stdout to it), 9sh hijacks that case to mean "write to partitions" and modifies the stream type to a sharded consumer rather than a serialized stream. This propagation happens automatically when the types are unified.

``` sh
cat foo | grep bar | sort | uniq -c > bif
#                    ----
#                    |
#                    +- sort erases ordering, replacing the output's
#                       ordering constraint with a free variable, which
#                       allows cat and grep to be parallelized

cat //input/* | grep foo | sort > //output/*
#   ---------                     ----------
#   |                             |
#   +-----------------------------+- wildcards are unified, preserving
#                                    file-level partitions
```


## RPC
9sh is a distributed shell. Objects can be addressed remotely using a flatbuffer RPC tunneled over any full-duplex channel, e.g. SSH stdio, a UNIX socket, or a secure P2P network connection provided by `libdatachannel`. This mechanism enables remote VFS operations, which makes it possible to `cd` into a remote host and list its files as though they were local.

9sh connects local instances by default using the `~/.9sh.sock` domain socket. State is centralized per user to avoid race conditions and conflicts.

**TODO:** a lot more about this


## Async processes and interaction
In bash, you background a job with `&`. It then acquires a name like `%2` that refers to its PID.

9sh does something that, in my opinion, is far more intuitive and useful: background jobs are given names starting with `@`, and those names are (1) directory-scoped, and (2) are interaction commands:

``` sh
$ @reverse= rev       # run rev in background, call it @reverse
$ @reverse asdf       # send text to stdin
@reverse: fdsa        # reverse sent us text back
$ @reverse <file      # send a whole file on stdin
@reverse: ...         # we get the reversed lines back
$ @reverse >file      # start sending its output to a file
$ echo hi | @reverse  # pipe something to reverse's stdin
$ @reverse            # foreground the process
Ctrl+Z                # pause it
$ bg @reverse         # background it
$ kill -INT @reverse  # kill the job
@reverse exited 0
```

You can see that background jobs have flexible endpoints: you can change them as they're running. 9sh manages this for you by holding onto FIFOs or PTYs and splicing data to and from the endpoints.

As in bash, background jobs are stopped if they attempt to change the terminal mode. These jobs must be explicitly foregrounded to interact with them.


### On-demand processes
Background jobs aren't always UNIX processes. You can define a `@`-name as a Fennel object that operates over stored state in some way rather than persistently occupying a process entry.


## Contributors
+ [Spencer Tipping](https://github.com/spencertipping)
+ [tvScientific](https://tvscientific.com)


## License
Copyright (C) 2026 Spencer Tipping.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
