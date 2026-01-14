# 9sh
**Under active development; nothing works yet**

A UNIX shell built on a semantic VFS. 9sh extends POSIX shell scripting by adding VFS-driven command and grammar overloads, distributed execution and file remoting, and interaction multiplexing.

9sh borrows ideas from Plan 9, Haskell, SQL, and Smalltalk, and is written as a statically-linked binary in C++ with embedded LuaJIT and is scripted in Fennel, a Clojure-flavored Lisp for Lua. 9sh is probably less awful than you might reasonably assume given the introduction so far.


## Core concepts
If you're new to 9sh, you'll probably want to read these in order. The VFS underpins or influences almost everything else, and is written using objects and traits.

+ Foundation
  + [VFS](doc/vfs.md)
  + [Objects and traits](doc/objects.md)
+ Commands
  + [Commands](doc/commands.md)
  + [Types and unification](doc/types.md)
  + [Simulation](doc/simulation.md)
  + [Stochastic optimization](doc/optimization.md)


## Examples
**TODO**


## Contributors
+ [Spencer Tipping](https://github.com/spencertipping)
+ [tvScientific](https://tvscientific.com)


## License (GPLv3)
Copyright (C) 2026 Spencer Tipping.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
