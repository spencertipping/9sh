# 9sh
**Under construction**

9sh is a Plan 9-inspired shell built on four interconnected layers:

1. An extensible VFS that provides local, remote, and virtual locations
2. An extensible command grammar with a consistent semantic structure
3. An extensible process-interaction, multiplexing, and routing space
4. A distributed remote-execution mesh and [concurrency model](doc/cylinders.md)

They intersect extensively, including:

```
+ Shell state is fully VFS-encoded within the // moment
  + Routers/multiplexers
  + Running processes (within the @ moment)
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
+ Remote instances populate VFS entries
  + Remote peers are VFS lenses
```

**TODO:** redo the above list as a visual diagram

**Q:** how do VFS-UX and multiplexing relate to one another? We probably have UX levels, and/or a UX grammar similar to how commands re-delegate their sub-grammars to `$PWD`. Could be OOP overrides: override the top level or a sub-level maybe. I like the principle that we configure UX panes by pointing them at specific coordinates.

**NOTE:** we need a principled boundary between "UX as data" (commands) and "UX as presentation" (layout). Shouldn't be too hard to do.


**NOTE:** the way to think about type inference here is that we bootstrap into HM-world with a linear command. The VFS dir doesn't strictly need to look at the first _n_ characters to resolve the command, but (1) it generally should; and (2) the command resolves other types, so we'll want to know it early -- otherwise we have a chaotic experience.

**NOTE:** we can infer the type of semicolon; it's equivalent to `m a` monadic type inference. We need _some_ structure, but it's unclear how much. This relates to polymorphic pipes: it allows pipe type inference to travel through a pipeline.

**NOTE:** values are not necessarily known in a distributed system; they can be in a superposition of "sent but not confirmed". Algorithms should be able to reason about that state. Arguably that state is probabilistic in nature. If we do this, we're pushing distributed-state expectations downwards into the language kernel, the antithesis of sagas (or is it?).

**Speculative cylinder-ordering execution:** look forwards, expanding function calls and attempting to reorder execution, e.g. by collecting RPCs and batching them.
