# 9sh VFS
The 9sh VFS overloads repeated `/` characters to access higher-order directory resolution "moments". Conventionally:

+ The first moment of `foo`, via `foo/bar`, contains real UNIX files
+ The second moment of `foo`, via `foo//bar` (or `//bar` if PWD is `foo`), contains assembled virtuals
+ The third moment of `foo`, via `foo///bar` (of `///bar` if PWD is `foo`), contains self-meta
+ Higher moments exist but aren't typically used and aren't standardized

`/` always refers to the UNIX root and `~[user]` always refers to UNIX home directories (as in POSIX shell), however `~` is overloaded with suffixes, e.g. `~@`, to refer to the CWD of non-user processes and other VFS-anchored objects: if `@foo` is a background process, `cd ~@foo` navigates into the CWD of that process.

A quick rule of thumb:

+ The first moment reflects UNIX filesystem reality (or a transformation)
+ The second moment inherits from parent _directories_
+ The third moment inherits from parent _classes_

Although VFS entries can modify these behaviors to deviate from the standard convention, they usually don't.


## Quick overview
The VFS allows you to create a semantic superstructure over your filesystem. VFS nodes are more than files and directories: they also function as namespace scopes, i.e. you `import` them (or `cd` into them) to acquire access to resources. For example:

``` sh
$ cd //projects/foo  # VFS directory
$ @todo list         # chat with a VFS-scoped background process
@todo: 1. foo        # stdout tagged with sender
@todo: 2. bar
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
$ cut foo,bar //db/table | grep bar > 10 | zstd > rows.csv.zst
# |                                    |   ----        ---
# +- compiled to SQL ------------------+   |           |
#                                          |           |
#                zstd consumes csv text ---+-----------+
```

This case is particularly interesting because the `.csv.zst` file extension provides a CSV type hint that propagates across `| zstd >` to inform the export type from the database query.

You can `cd` into any of these locations: `cd //db; cut foo,bar table` works, and `cd //host/*` works as well, landing you in a multi-homed virtual directory targeting all hosts at once. The files visible to you are the union of the files on remotes, their sizes, modtimes, UIDs, and other attributes are reported as distributions rather than scalars, and any noninteractive command you run will execute on all hosts simultaneously, e.g. `uptime > uptime.log` will create `uptime.log` on every host. This execution behavior, as with most other implicit context, is determined by the VFS PWD.


## Navigation
``` sh
$ cd       # pwd = ~
$ ls       # entries of the first moment of $PWD
$ ls //    # entries of the second moment of $PWD
$ ls ///   # entries of the third moment of $PWD
$ cd //x   # cd into 'x' within the second moment of $PWD
$ cd .//y  # identical to cd //y -- we are now in ~//x//y
```

At this point we're in `~//x//y`, which is to say "`y` within the second moment of `x` within the second moment of the home directory". You don't typically have multiple second-moment navigations in succession, but you can. From there:

``` sh
$ cd ..         # pwd = ~//x
$ cd ///z       # pwd = ~//x///z
$ cd ..         # pwd = ~//x
$ cd ..         # pwd = ~
$ cd ///a       # pwd = ~///a
$ cd /bin       # pwd = /bin
$ cd //b/c///d  # pwd = /bin//b/c///d
$ cd /          # pwd = /
$ cd //foo      # pwd = /.//foo
```


## Virtuals and inheritance
9sh uses the second-moment `//` notation as a shorthand to access _virtual_ objects that have no logical filesystem location, e.g. remote hosts, databases, S3 locations, and so forth. Because virtuals don't canonically reside within the UNIX filesystem, they're accessible independently of location. However, VFS nodes act as _scope containers_ and therefore define `//` entries in a top-down way:

``` sh
$ cd ~/projects/foo
$ ls //hosts         # global hosts + hosts local to the foo project root
$ cd src/main        # subdirectories of projects/foo
$ ls //hosts         # hosts in this subdir inherited from parent(s)
```

In other words, the second moment conventionally inherits second-moment entries from parents, unioning (and sometimes shadowing) them together to form the most contextually-specific view. This allows `//` to act as a second logical root, just one whose contents are modified by where you're accessing it.


## Self-meta
The third moment is typically used to inspect objects: `///types/foo` might contain the definition of a custom type specific to this directory + descendants, however the `///` namespace is not itself inherited:

``` sh
$ ls //db      # list custom databases
prod  dev
$ ls ///types  # custom type defined here
foo
$
```

Note the difference between the second and third moments within a subdirectory:

``` sh
$ cd src       # move to a subdirectory
$ ls //db      # custom databases are inherited by default
prod  dev
$ ls ///types  # no custom types defined here
$
```


## Chained higher-order moments
While you can write `cd //db//x`, 9sh doesn't define what this would mean and this `cd` operation will usually fail. However, `cd //db///meta` _is_ well-defined, as all VFS entries define `///` attributes. `cd ///meta///meta///meta` is also well-defined.

`///` entries are inherited through the OOP system (via trait implementation) rather than from parent directories.


## VFS configuration
The VFS is configured in `~/.9shrc`. For example:

``` fennel
;; Entries defined into / are visible everywhere
(nine.root:def ://db/foo (nine.db.postgres {...}))
(nine.root:def ://db/bar (nine.db.mysql    {...}))

(nine.root:def ://host/x (nine.db.ssh-host {...}))

;; Let's define a project with project-local resources. Do this
;; if you want to centralize its configuration.
;;
;; We also specify the backing location for the directory. When
;; you run POSIX commands from this virtual directory, they'll
;; have CWD set to ~/git/projects/foo in the UNIX filesystem --
;; and `ls` on the virtual dir will be populated from there.
(let [p (nine.root:def ://proj/foo (nine.vfs.dir "~/git/projects/foo"))]
  (p:def ://host/foo (nine.db.ssh-host "ubuntu@foo.io"))
  (p:def ://db/prod  (nine.db.sqlite "prod.db"))
  (p:def ://db/dev   (nine.db.sqlite "dev.db"))

  ;; Insert a VFS entry into the first moment, as though it were
  ;; a real file. This will _not_ be inherited by subdirectories.
  ;; You can `cat www` to fetch homepage contents.
  ;;
  ;; www is simultaneously a file and a directory; its interpretation
  ;; will vary by usage. It's never "real" in the POSIX sense, even
  ;; though it appears inline. If you run POSIX ls, you won't see www
  ;; because it doesn't actually exist (but if you run 9sh ls, it
  ;; will be visible).
  (p:def :/www        (nine.net.http "https://foo.io")))
  (p:def :/www/status (nine.net.http "https://status.foo.io"))

;; Trust some directories by automatically evaluating their .9shrc.
;; These 9shrc files are evaluated each time you cd into the directory.
(nine.root:def ://proj/bar (nine.vfs.dir {:trust true}))
(nine.root:def ://proj/bif (nine.vfs.dir {:trust true}))
```
