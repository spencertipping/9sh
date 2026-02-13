# 9sh cylinders
9sh is a distributed system, which means that unified time is only partially ordered. A _cylinder,_ named for the database symbol in technical diagrams, is any area in which readers and writers agree about a total ordering -- i.e. reads and writes are fully serialized. All canonical state is owned by a cylinder.

Direct cylinder access is strictly serialized, which is often a problem for performance. To work around this, you can create an _echo,_ which is a read-only cache of a cylinder's state within the recent past. Echoes typically have TTLs and they may implement refresh mechanics. Critically, echoes are always read-only; if you want to write, you must do so by talking to the cylinder that owns the object you're writing to. On the system-level, 9sh provides no fire-and-forget mechanics: if you didn't get an ack, then a write has not been safely committed.

If an echo and cylinder-writer are colocated, the echo will typically update itself when the cylinder confirms a write. For example, `cylinder.x = 100` will cause `echo.x == 100` once the write is confirmed. This isn't guaranteed behavior -- it depends on the echo implementation -- but it's common.

Intuitively, you can think of a cylinder as generalizing a heap, a garbage-collected domain, and/or a database.


## Atomic operations
Cylinders support versioned CAS and other related distributed atomics.

**TODO:** details


## Content-addressable storage
**TODO**


## Local topology
9sh is organized around a user-specific daemon that serves as a traffic hub and a central repository for data coming in from all shell sessions. For example, command history is stored here. This daemon has the root cylinder, `c0`, which manages the `.9sh.db` user SQLite database.

Each shell session creates its own local cylinder, `c1`, to contain its VFS objects. This is important: because the underlying filesystem (which lazily populates the VFS) can block, it's critical that `c0` not issue any filesystem calls; otherwise _all_ active shell sessions could experience a denial of service. The only exception is to load and modify `.9sh.db`.

`.9shrc` initializes `c1` within each shell session. `c0` doesn't hold session data; it holds permanent, cross-session state and proxies to communicate between sessions.


## Perspective
Cylinders communicate with one another using proxy objects. `c0` acts as a hub/directory, and `c1`s can establish direct connections with one another if they choose to.

```
 PID 4722 c1         PID 8150 c0
+-----------+       +-----------+
| obj1      |       |  obj1     |
| obj2      |       |  obj2     |
| ...       |       |  ...      |
|           |       |           |
| c0-proxy<-+-------+->c1-proxy |
+-----------+   +---+->c1-proxy |
                |   |           |
                |   |  sqlite   |
 PID 5498 c1    |   +-----------+
+-----------+   |
| obj1      |   |
| obj2      |   | <-- local data channel
| ...       |   |     e.g. UNIX socket/SHM IPC
|           |   |
| c0-proxy<-+---+
+-----------+
```

Proxy objects may construct echoes of their remote cylinders, or they may use the data channel directly. Beyond data-channel integrity, the proxy objects are responsible for authentication and authorization.
