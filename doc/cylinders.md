# 9sh cylinders
9sh is a distributed system, which means that time is only partially ordered. A _cylinder,_ named for the database symbol in technical diagrams, is any area in which readers and writers agree about a total ordering -- i.e. reads and writes are fully serialized. All canonical state is owned by a cylinder.

Direct cylinder access is strictly serialized, which is often a problem for performance. To work around this, you can create an _echo,_ which is a read-only cache of a cylinder's state within the recent past. Echoes typically have TTLs and they may implement refresh mechanics. Critically, echoes are always read-only; if you want to write, you must do so by talking to the cylinder that owns the object you're writing to. On the system-level, 9sh provides no fire-and-forget mechanics.

Intuitively, you can think of a cylinder as being a heap, a garbage-collected domain, and/or a database.


## Local topology
9sh is organized around a user-specific daemon that serves as a traffic hub and a central repository for data coming in from all shell sessions. For example, command history is stored here. This daemon has the root cylinder, `c0`, which manages the `.9sh.db` user SQLite database.

Each shell session creates its own local cylinder, `c1`, to contain its VFS objects. This is important: because the underlying filesystem (which lazily populates the VFS) can block, it's critical that `c0` not issue any filesystem calls; otherwise _all_ active shell sessions could experience a denial of service. The only exception is to load `.9sh.db`.

`.9shrc` initializes `c1` within each shell session. `c0` doesn't hold session data; it holds permanent, cross-session state and proxies to communicate between sessions.


## Perspective
Cylinders communicate with one another using proxy objects.

```
 PID 4722 c1         PID 8150 c0
+-----------+       +-----------+
| obj1      |       |  obj1     |
| obj2      |       |  obj2     |
| ...       |       |  ...      |
|           |       |           |
| c0-proxy<-+-------+->c1-proxy |
+-----------+   ^   +-----------+
                |
                +-- UNIX domain socket
                    or data channel
```

Proxy objects may contain echoes of their remote cylinders, or they may use the data channel directly. Beyond data-channel integrity, the proxy objects are responsible for authentication and authorization.
