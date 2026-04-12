# 9sh VFS
**TODO:** un-AI-ify this document

The 9sh Virtual Filesystem is the universal address space for the shell. It replaces IP addresses, connection strings, and container APIs with a unified, capability-secure hierarchy.

In 9sh, the VFS does not merely expose data; it encodes **distributed state, lexical closures, and liability mechanics**. By mapping distributed systems concepts onto standard POSIX primitives, 9sh allows you to orchestrate containers, Raft consensus groups, and remote compute clusters using nothing but standard UNIX text streams.


## Moments
The 9sh VFS overloads repeated `/` characters to access higher-order directory resolution "moments". These moments dictate how you traverse the stacked union of environments (lexical frames) that make up your current context.

*   **The First Moment (`/`): Spatial Reality.** Contains concrete data (UNIX files, database rows, pipe buffers).
*   **The Second Moment (`//`): Lexical Scope.** Contains the active environment stack. It hosts remote mounts, virtual cylinders, and shadowed variables.
*   **The Third Moment (`///`): Meta & Prototypes.** Contains the shell's reflection plane. It hosts type traits, capability policies, orchestrator scripts, and the unflattened environment stack.


### Traversal and the Spatial Ceiling
Because moments are literal dimensions, traversal is strictly bounded to prevent sandbox escapes:
*   `cd ..` (Spatial Parent): Moves up the physical directory tree. If you are inside a containerized Anchor, `cd ..` from `/` is a no-op. You hit the spatial ceiling.
*   `cd //..` (Lexical Parent): Pops the top environment frame off your lexical stack, returning your context to the parent Anchor.
*   `cd ///..` (Prototype Parent): Steps up the OOP inheritance tree to inspect fallback parsers and commands.


## Reference frames and `~`
In 9sh, directory navigation (`cd`) moves the **Observer** (the user), while AST evaluation moves the **Actor** (the command).

If you `cd` into an Anchor backed by a Docker container, your interactive shell remains on the host, but the compilation context for your next command is set to the container. To bridge these realities seamlessly, 9sh reserves a specific set of tilde (`~`) coordinates:

*   **`/` (The Observer's Root):** The physical root of the machine running your interactive shell.
*   **`~@/` (The Actor's Root):** The physical root of the execution environment (e.g., the container's `/` or the remote host's `/`).
*   **`~0/` (The Current Anchor):** The root of your current logical project.
*   **`~1/` (The Parent Anchor):** The root of the project one level down the lexical stack.
*   **`~9/` (The Ambient Root):** The absolute bottom of your stack. It holds your global distributed identity, `@jobs`, and aliases.

**Example: Cross-Reality Operations**
Because these coordinates are resolved at compile-time, you can perform complex cross-boundary operations in a single line.
```sh
# You are inside a containerized microservice Anchor.
$ cd //src/monorepo/backend/auth_service

# Copy the container's internal Nginx log to the host's parent monorepo
$ cp ~@/var/log/nginx/access.log ~1/shared_logs/
```


## Cylinders, echoes, and liability
In 9sh, data is not just a stream of bytes; it is a flow of **liability**.

*   **Cylinders (Owners):** A Cylinder is any VFS node that accepts liability for data (e.g., a local disk, a Postgres database, a Raft cluster). Cylinders are the *only* entities permitted to execute non-idempotent side effects.
*   **Echoes (Projections):** An Echo is a read-only, non-authoritative cache of a Cylinder. You can pipe out of an Echo, but you cannot pipe into it.
*   **Pipes (Conduits):** A pipe (`|`) is a Liability Transfer Proposal. Because networks partition, pipes are volatile. The 9sh compiler mandates that all commands within a pipe must be mathematically `Pure` or `Idempotent`.


### Linear Types and the Auto-ACK Fabric
To transfer data destructively between Cylinders, you append `:consume` to the source path. This wraps the data in a Linear Type (`#`), enforcing the **Law of Conservation of Liability**. The data cannot be duplicated or dropped; it must be absorbed by a robust Sink.

```sh
$ tail -f //raft-a/topic:consume | awk '{print $2}' > //raft-b/topic
```

Because POSIX pipes are lossy, 9sh does not attempt to inject magic watermarks into the byte stream. Instead, the compiler synthesizes a **Garbage Collection (ACK) loop** in the background.

1. `//raft-a` emits data but does not delete it.
2. `awk` transforms the data.
3. `//raft-b` absorbs the data and emits the safely committed Row IDs to its `///receipts` endpoint.
4. 9sh automatically routes those IDs back to `//raft-a///ack`, which deletes the original records.

This provides exactly-once, Kafka-level streaming semantics using standard UNIX text-processing tools.


## Entanglement and `&`
9sh models distributed execution via **Entanglement Mechanics**. Your interactive terminal (`~9`) is a highly unreliable reference frame (laptops go to sleep, Wi-Fi drops).

The `&` operator, traditionally used to background a process, is overloaded in 9sh to mean **Decoherence**. It instructs the compiler to dissociate the execution from your `~9` reference frame entirely.

**Subjective Execution (Synchronous):**
```sh
$ tail -f //db/prod:consume > //db/warehouse
```
The data plane and the Auto-ACK control plane are routed through your laptop. If you close your laptop, the pipe breaks safely. No data is lost, but the transfer halts.

**Objective Execution (Decohered):**
```sh
$ tail -f //db/prod:consume > //db/warehouse &
[1] @migration_job_7f
```
The compiler observes that the Source and Sink are both robust Cylinders. Because of the `&`, it packages the pipeline and submits it to the Spacetime Mesh (`///mesh`). The transfer runs directly between the databases.

You can close your laptop, throw it in the ocean, and buy a new one. Upon restoring your `~9` Ambient Root, you can re-entangle the observation plane using standard job control:
```sh
$ fg @migration_job_7f
```
The switching fabric will dynamically rewire the remote job's `stdout` and `stderr` back to your new terminal.


## 5. Security and sandboxing
9sh abandons User-ID (UID) based security for within-session execution, replacing it with **Lexical VFS Projections**.

When a command is executed, it does not see the entire hard drive. It only sees the specific Moments (`//`) explicitly projected into its sandbox by the AST Linker.


### Anchor Orchestrators
Security is bolted on via the `///cmd` prototype chain. If an Anchor is configured to use a container, the default orchestrator wraps all executions in that namespace.

```fennel
;; //project/foo///cmd/default/exec
(fn [ast plan]
  (os.execute (string.format "podman run -v %s:%s --rm my_image %s"
                             (vfs.pwd) (vfs.pwd) ast.raw)))
```


### Command Exemptions
Commands can be exempted from the container by delegating to the `super` prototype. If `git` is exempted, typing `git commit` inside the containerized Anchor will fall through the prototype chain and execute on the host OS, utilizing the host's `ssh-agent` and filesystem, while `npm install` remains safely isolated in the container.
