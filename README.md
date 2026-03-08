# 9sh
**Under construction**






**TODO:**

Each prompt is a UX for the shell cylinder, which multiplexes onto the VFS.

Some cylinders act as controllers for others. Controlled cylinders need a `controlled-by = (id, timestamp)` attribute (and to maintain it canonically) to avoid controller collisions. We should probably think about controller handoff and delegation. This doesn't strictly interact with permissions, but it might.

Within a prompt time-step, **VFS nodes are echoes of cylinders.** This forces all prompt interactions to treat them read-only until you hit `<enter>`, which is the first point at which a delay is UX-permissible. So, `cd foo//bar` will block until an echo has been created for `foo//bar`. The local VFS is therefore an echo of the underlying mount structure: the VFS is a graph of _cylinder accessors → echo generators._

Types and stochastic models are not directly related to cylinders. They're alternative projections from the same command objects, but we don't need an underlying cylinder to exist to create types -- unlike echoes, which are derived. The same `command` object can produce both. (Also note: `command` in the UX sense and `command` in the backend-process sense are entirely distinct concepts. Should probably give them different names.)




## Core concepts
If you're new to 9sh, you'll probably want to read these in order. The VFS underpins or influences almost everything else.

**TODO:** rewrite/GC the list below

+ Foundation
  + [Cylinders and echoes](doc/cylinders.md)
  + [VFS mechanics](doc/vfs.md)
+ Commands
  + [Commands](doc/commands.md)
  + [Types and unification](doc/types.md)
  + [Simulation](doc/simulation.md)
  + [Stochastic optimization](doc/optimization.md)

**Core idea:** data promises, `echo hi > foo` should track `foo`'s existence for future steps, helping the parser

**Core idea:** type _recommender_, not type _verifier_


## Unincorporated notes
+ [Collection](doc/notes.md)

+ https://librechat.k3s.priv/c/5bc16f79-90d7-4388-a75c-a72c87f9f887
+ https://librechat.k3s.priv/c/a2fb2b38-ef4a-4396-a795-0c231818a65f
+ https://librechat.k3s.priv/c/5f88c05b-4918-42c9-aa79-401c7e34c0f9
+ https://librechat.k3s.priv/c/8f0e37d5-f046-40da-9981-b0f68bf00e67
+ https://librechat.k3s.priv/c/b75fded5-edab-44c4-9281-c45670b58b97
+ [Cylinders as objects, ad-hoc raft](https://librechat.k3s.priv/c/0d41f7f2-79a7-4fd2-98df-60b03fc5b064)


## Examples
**TODO**


## Contributors
+ [Spencer Tipping](https://github.com/spencertipping)
+ [tvScientific](https://tvscientific.com)


## License (GPLv3)
Copyright (C) 2026 Spencer Tipping.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
