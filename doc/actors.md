# 9sh Actors, Mesh, and Materialization

**TODO:** un AI-ify this

In bash, you background a job with `&` and it becomes a fragile, anonymous PID like `%2`. In a modern cloud environment, you collaborate with others using a fragmented stack of Slack, SSH, and Google Docs.

9sh collapses all of these paradigms into a single concept: **The Actor**.

At its core, an Actor (`@`) is just a Cylinder that implements the `VFS.Transcript` trait—a totally ordered, append-only log of events. Because a REPL, a background job, a chat channel, and a human user are all fundamentally just event logs, 9sh unifies them under standard UNIX filesystem mechanics.

---

## 1. Actors and the Transcript
Background jobs in 9sh are named with `@`, and they are **directory-scoped, session-typed interactive actors.**

When you interact with an Actor, you are appending to its Transcript. The shell automatically routes your input through the Actor's `///parser` to determine its intent.

```sh
$ bg @py python3 -q
$ @py x = 10                    # Parsed as Python, appended to transcript
$ @py y = 20
$ @py x | y                     # Parsed as Python bitwise-OR
@py: 30
```

Because Actors are just VFS nodes, you can pipe data into them:
```sh
$ tail error.log | @gemini Explain this stack trace
```

### Implicit Contexts and the Literate Shell
For continuous interaction, typing `@py` over and over is tedious. In 9sh, if you type the name of an Actor or Directory and hit Enter, the shell **implicitly pushes it onto your `$PWD` stack**.

To pop the context and return to your previous shell, you simply press `ESC`.

```sh
$ @py
[@py] $ def foo():
[@py] $     return "hello"
[@py] $ <ESC>
$
```

---

## 2. The Spacetime Mesh & Multiplayer
9sh does not have a "multiplayer mode" or a chat client. It has the **Spacetime Mesh** (`///mesh`), a peer-to-peer WebRTC fabric (via `libdatachannel`) that connects `c0` daemons.

Joining a collaborative workspace is just VFS traversal. If Alice exposes an Anchor to the mesh, Bob can `cd` into it:

```sh
bob@~9 $ cd mesh://alice.id/scratch/foo
```

Because Bob is now in Alice's Anchor, their lexical stacks (`//`) are entangled. **Users are just Actors.** If Alice types `ls //`, she will see `@bob` in her environment.

Because `@bob` is an Actor with a Transcript, Alice can talk to him using standard shell routing:
```sh
alice@~9 $ @bob what do you think of the new spec?
```

Or, she can send him a file by embedding it in his transcript:
```sh
alice@~9 $ @bob here are the logs: < error.log
```

---

## 3. Broadcast Channels (`#`)
A multicast channel is just a shared Directory in the `//` scope where the `///parser` is set to `Text` instead of `POSIX`. By convention, these are prefixed with `#`.

When you enter a channel, you drop into a **Literate Shell**. English is the default parser. Everything you type is broadcast to the channel's Transcript. To execute a POSIX command from within a Literate Shell, you use the `$` escape hatch:

```sh
$ #dev[#dev] $ Does anyone know why the build is failing?
bob[#dev]   $ I think the tests are timing out.
[#dev] $ Let me check the latest output.
[#dev] $ $ tail -n 5 //jobs/build/error.log
[... output of tail is printed to the chat for everyone to see ...]
[#dev] $ <ESC>
$
```

---

## 4. Collaboration without CRDTs
9sh explicitly rejects CRDTs (Conflict-Free Replicated Data Types) for file editing. They are complex, leak memory, and violate the UNIX philosophy of simple primitives.

Instead, 9sh achieves real-time collaboration using standard **Pub/Sub** and **POSIX File Locking**.

Every Anchor exposes an event stream at `///events`. When Bob joins a workspace, his terminal implicitly subscribes to this stream. If Alice wants to edit a shared file, she takes out a lock:

```sh
alice[#dev] $ lock spec.md
```
This sets a metadata flag on the Cylinder and fires an event to the Pub/Sub channel (`[System] @alice locked spec.md`). If Bob tries to open the file, his editor will correctly open it in read-only mode. When Alice saves and exits, the lock is released.

By piping `///events` into the `#dev` chat transcript, human conversation and system state share a single, totally ordered timeline.

---

## 5. Bridging Realities: Materialization and Trait Coercion (`:`)
A core problem with Virtual Filesystems is that standard POSIX text editors (`vim`, `code`) cannot `lseek()` over a network socket, and legacy media tools (`ffmpeg`) often demand physical file paths.

Instead of relying on fragile kernel extensions like FUSE or `ptrace`, the 9sh compiler uses **AST Rewriting and Materialization**.

When you run `vim //shared/spec.md`, the 9sh Linker detects a type mismatch: `vim` requires `VFS.LocalFile`, but `//shared/spec.md` is a remote stream. The compiler automatically materializes a temporary file in `/tmp/9sh/`, sets up an `inotify` watcher, and rewrites the AST to pass the `/tmp` path to `vim`. When you save, 9sh streams the diff back to the Cylinder.

### The Trait Coercion Operator (`:`)
Sometimes, the compiler's type inference needs a manual override. You can force the AST Linker to materialize a VFS node in a specific POSIX format using the **Trait Coercion Operator (`:`)**.

*   `:f` **(Local File):** Forces materialization to a physical `/tmp` file.
*   `:p` **(Named Pipe):** Forces materialization to a FIFO (`mkfifo`).
*   `:ro` **(Read-Only):** Strips the `VFS.Write` trait, preventing the OS from opening the file with `O_RDWR`.
*   `:consume` **(Linear Type):** Wraps the stream in an Auto-ACK garbage collection loop for destructive liability transfer.

**Example:**
Suppose you download a closed-source binary called `data-cruncher` that strictly requires a physical file path, but you want to feed it a live database query:

```sh
$ sel foo bar from //db/prod | data-cruncher /dev/stdin:f
```

1. `sel` outputs a stream of text.
2. The pipe `|` connects `stdout` to `stdin`.
3. You explicitly cast `/dev/stdin` to `:f`.
4. The 9sh compiler intercepts the stream, buffers it into a temporary physical file, and passes that physical file path to `data-cruncher`.

With a single character, you seamlessly bridge the gap between streaming POSIX pipes and legacy file-bound binaries, maintaining strict type safety under the hood.
