# 9sh
**Under active development; nothing works yet**

A UNIX shell built on a semantic VFS. 9sh extends POSIX shell scripting by adding VFS-driven command and grammar overloads, distributed execution and file remoting, and interaction multiplexing. For example:

``` sh
$ cd //projects/foo  # VFS directory
$ @todo list         # chat with a VFS-scoped background process
@todo: 1. foo        # stdout tagged with sender
@todo: 2. bar
```

Because `@`-tagged processes have custom grammar continuations, you can use them to interact in non-shell languages:

```sh
$ export f=foo.csv
$ @py import pandas as pd   # start a python process
$ @py df = pd.read_csv($f)  # splice envvar
$ @py df                    # view dataframe interactively
```

In addition to resolving all commands and providing the shell grammar, the VFS also translates non-filesystem objects into the filesystem metaphor; for instance:

```sh
$ cat //host/*/logs | grep foo | sort | uniq -c > log-rollup
# ---                 ----
# |                   |
# +-------------------+- moved to data for performance since sort
#                        reorders the input data
```

A Haskell-style type system applies these operations only when valid. If you run a command with an end-to-end serial dependency, the jobs won't be parallelized, matching POSIX semantics (except that `grep` may still be moved to save bandwidth):

``` sh
$ cat //host/*/logs | grep foo > log-rollup
# ---                 ----
# |                   |
# +-------------------+- moved to data but serially, since order
#                        is specified by *
```

The same logic, plus command overloading, allows sections of the pipeline to move away from POSIX altogether; `cut` is similar to SQL `select` and `grep` is similar to `where`, yielding:

```sh

$ cut foo,bar //db/table | grep bif > 10 | zstd > rows.csv.zst
# |                                    |   ----        --- ---
# +- compiled to SQL ------------------+   |
#                                          |
#                  zstd consumes csv text -+
```

This case is particularly interesting because the `.csv.zst` file extension provides a CSV type hint that propagates across `| zstd >` to inform the export type from the database query.

You can `cd` into any of these locations: `cd //db; cut foo,bar table` works, and `cd //host/*` works as well, landing you in a multi-homed virtual directory targeting all hosts at once. The files visible to you are the union of the files on remotes, their sizes, modtimes, UIDs, and other attributes are reported as distributions rather than scalars, and any noninteractive command you run will execute on all hosts simultaneously, e.g. `uptime > uptime.log` will create `uptime.log` on every host. This tenancy behavior is determined by the VFS.

**TODO:**

1. Figure out whether oop.fnl can support HM, or whether that's higher-level
2. Formalize stream-trait model


## Contributors
+ [Spencer Tipping](https://github.com/spencertipping)
+ [tvScientific](https://tvscientific.com)


## License (GPLv3)
Copyright (C) 2026 Spencer Tipping.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
