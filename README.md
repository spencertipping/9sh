# 9sh
**Under construction**

POSIX sh manages three state spaces:

+ Local files
+ Local processes
+ Session-scoped variables


9sh is a Plan 9-inspired, mostly POSIX-compliant UNIX shell built on four interconnected layers:

1. An extensible VFS that provides local, remote, and virtual locations
2. An extensible command grammar with Hindley-Milner type inference
3. An extensible process-interaction, multiplexing, and routing space
4. A distributed remote-execution mesh and [concurrency model](doc/cylinders.md)

This architecture allows 9sh to use POSIX-adjacent syntax to represent a wide variety of different local and distributed operations; for example:

``` sh
$ cat file | grep foo | zstd > matches  # normal command

$ cat //host/*/data \
    | grep foo \
    | zstd > //host/*/matches  # distributed parallel

$ cat //host/*//db/foo | grep bar > 10 \
    | cut -f foo,bar \
    | sort -k bar:asc \
    | zstd > rows.csv.zst  # distributed database
```

9sh also provides custom grammars for data processing, and you can easily define your own in Lua, Fennel, or 9sh script.

See [doc/commands.md](doc/commands.md) for more specifics about command-execution machinery, but you might want to read the VFS overview below first.


## VFS
The VFS unifies the UNIX data plane, the 9sh data plane, and the 9sh control plane as three distinct moments of directory access:

+ `foo/bar`: `bar` within the first moment of `foo` (the data plane)
+ `foo//bar`: `bar` within the second moment of `foo` (the 9sh user-data plane)
+ `foo///bar`: `bar` within the third moment of `foo` (the 9sh control plane)

Moments 2 and 3 are rootless and relative to `$PWD`, and there are several shorthands:

+ `//foo` → `.//foo`, and `///foo` → `.///foo` -- the `.` is implied, since `//` and `///` are not roots
+ `@foo` → `///proc/foo`
+ `~foo` → `///home/foo`
+ `foo://bar/bif` → `///scheme/foo/bar/bif`

The second moment is inherited from parent directories: `foo/bar//bif` will be a superset of `foo//bif`. `///` inherits from its parent-directory prototype.

VFS directories resolve commands: `foo` → `///cmd/foo`, if `///cmd/foo` exists. `///cmd` is the union of `$PATH`-specified directories, plus any user-defined commands that may exist within this path.

VFS directories also resolve shell grammar components, e.g. `///parse/foo`, which allows user-extensible grammar overrides.

See [doc/vfs.md](doc/vfs.md) for more specifics.



```
+ Shell state is fully VFS-encoded within the /// moment
  + Routers/multiplexers
  + Running processes (within the @ moment)
  + Routing topology
  + Distributed peers
  + Cylinders and echoes
  + Available commands
  + Command grammars
+ $PWD within the VFS drives the UX
  + Command resolution
  + Grammar elements
  + Visual presentation
  + Plurality + statistical optimization, like command grammars?
  + This is implemented using the // and /// moments
+ Type resolution through the VFS
  + Static VFS entries → static lookups
  + Some VFS entries = control interfaces/sockets
  + VFS entries can be runtime Lua objects, if colocated or proxied
```

**TODO:** redo the above list as a visual diagram

**Q:** how do VFS-UX and multiplexing relate to one another? We probably have UX levels, and/or a UX grammar similar to how commands re-delegate their sub-grammars to `$PWD`. Could be OOP overrides: override the top level or a sub-level maybe. I like the principle that we configure UX panes by pointing them at specific coordinates.

**NOTE:** we need a principled boundary between "UX as data" (commands) and "UX as presentation" (layout). Shouldn't be too hard to do.


**NOTE:** the way to think about type inference here is that we bootstrap into HM-world with a linear command. The VFS dir doesn't strictly need to look at the first _n_ characters to resolve the command, but (1) it generally should; and (2) the command resolves other types, so we'll want to know it early -- otherwise we have a chaotic experience.

**NOTE:** we can infer the type of semicolon; it's equivalent to `m a` monadic type inference. We need _some_ structure, but it's unclear how much. This relates to polymorphic pipes: it allows pipe type inference to travel through a pipeline.

**NOTE:** values are not necessarily known in a distributed system; they can be in a superposition of "sent but not confirmed". Algorithms should be able to reason about that state. Arguably that state is probabilistic in nature. If we do this, we're pushing distributed-state expectations downwards into the language kernel, the antithesis of sagas (or is it?).

**Speculative cylinder-ordering execution:** look forwards, expanding function calls and attempting to reorder execution, e.g. by collecting RPCs and batching them.
