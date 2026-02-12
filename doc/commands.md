# 9sh commands
`ls /usr/bin` and `ls //db` are both called `ls`, but they have different grammars and are executed differently. This requires 9sh to support not just command polymorphism but also _parse polymorphism,_ both governed by the PWD. This is nontrivially complex because polymorphic grammars can modify the parse points. You could imagine, for example:

``` sh
$ cat file | grep foo | bar > 10 | zstd > file.zst
#          |---------------------| <- parse 1: | is infix or
#          |----------|----------| <- parse 2: | is pipe
```

It might seem unreasonable for commands to overload `|`, but the flexibility improves interactive systems:

``` sh
$ @py x = 10
$ @py y = 20
$ @py x | y                     # probably not a shell pipe
@py: 30
$ @py x | wc -c                 # probably a shell pipe
@py: 3
$ @gemini Explain `ls | wc -l`  # not a shell pipe
@gemini: ...
$
```


## Parse structure
The 9sh parsing system is polymorphic along two independent axes:

1. Interactive vs offline-script parse cursors
2. `(amb)` to fork the parse continuation

`(amb)` is nuanced. We accommodate length-variant ambiguity tractably with offset-keyed shared-prefix parse forests (SPPF); for example:

``` sh
$ cat foo | grep foo | bar > 10 | bif
# AAAAAAA   BBBBBBBB   CCCCCCCC   DDD
# AAAAAAA   EEEEEEEEEEEEEEEEEEE   DDD
#
# 0         1         2         3
# 01234567890123456789012345678901234
```

The parse state after `cat foo | ` is `{10: [(cat foo)]}`. Since `grep` is ambiguous, we have two continuations that are parsed like this:

```
grep foo | bar > 10 → {32 [(grep foo (> bar 10))]}
grep foo            → {21 [(grep foo)]}
         | bar > 10 → {32 [(pipe (grep foo) (bar > 10))]}
```

The final result contains two alternatives:

```
{32 [(grep foo (> bar 10))
     (pipe (grep foo) (bar > 10))]}
```

We minimize intermediate breadth by fast-forwarding lagging branches, i.e. using a priority-queue wavefront scheduler ⇒ CPS transformation ⇒ Lua coroutines.


## Realtime entanglements
Parse states become time-variant in two ways:

1. Async VFS operations, which may retroactively add detail
2. Cursor movements and edits, which may reuse parse states

(2) is just a persistent scheduler and carefully-keyed memoization. (1) entangles two temporally distinct reference frames: _what could be true_ converging to _what we know to be true,_ distinct because interactive parsing (autocomplete, syntax highlighting, type hints) should not await all outstanding RPCs, whereas command execution, a side-effectful commitment, must.


**TODO:** cylinders, immutable class definitions, code portability, global-variable access detection via scope analysis, Merkle tree state, weakref pub/sub, convergence + hashing

Merkle-hashed convergent state → content-addressed timeline reconciliation, i.e. automatic if we memoize.

**Q:** why specifically do we need CAS? Prob for transfer-diff optimization within cylinder echoes; also, to force DAG in case that's useful.

Objects relate to time via metaclasses, e.g. immutable, convergent, divergent, echo-leased. Those metaclasses track state on each instance.

**TODO:** VFS remoting == echo.
