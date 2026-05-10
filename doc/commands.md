# 9sh commands
Bash treats commands as instructions. 9sh treats them as constraints. 9sh's core thesis is that you don't want to control reality in detail, you want to confine reality to specific domains of outcomes. Therefore, `ls | wc -l > output` dictates that `output` will contain the number of non-hidden files, but neither `ls` nor `wc -l` necessarily needs to be run to do it.

Structurally, a 9sh command is a behavioral signature that 9sh refers to as a _shadow_; it then derives a _structure_ which casts that shadow and minimizes a VFS-defined cost function. You can direct-drive the structure using overrides like the `$` prefix, which drops you directly into a POSIX environment; but 9sh commands will generally achieve the same effect at least as efficiently.







**TODO:** un-AI-ify this


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


## 1. Parsing: SPPF and The Shadow
Because `$PWD` dictates the grammar via its `///parser` prototype, 9sh supports extreme syntactic polymorphism. A Lisp-flavored Anchor might parse `(| (ls) (wc 'l))` while a standard Anchor parses `ls | wc -l`.

To accommodate length-variant ambiguity without blocking the interactive prompt, 9sh parses input into a **Shared-Prefix Parse Forest (SPPF)**.

```sh
$ cat //db/logs | grep ERROR
```

The parser's job is not to figure out *how* to execute this. Its only job is to translate the SPPF into the **Shadow**—an AST where physical execution details are left as free variables (`?`):

```text
Pipe(
  exec(where = //db, what = cat(logs)),
  exec(where = ?,    what = grep(ERROR))
)
```

Because `//db/logs` is physically anchored, its `where` is implicitly concrete. But `grep` is a pure function, so the parser leaves its `where` up for grabs.


## 2. Unification: Casting the Structure
The 9sh core engine knows absolutely nothing about SQL, Map/Reduce, or Docker. It is simply a **Type Unifier**. It takes the Shadow and attempts to fill in the `?` holes by querying the VFS Traits (`///traits`) of the commands involved.

For the `grep` example above, the Unifier queries `grep` and sees it implements `Trait.Pure`. This means its location is unconstrained. The Unifier generates two valid **Structures** (concrete types):

*   **Structure A (Standard POSIX):** `?where = ~9`. The pipe bridges `//db` to your laptop (`~9`). A massive network transfer happens *before* `grep`.
*   **Structure B (SQL Pushdown):** `?where = //db`. The pipe bridges `//db` to `~9` *after* `grep`. The network transfer is tiny.

### Implicit Combinators and Map/Reduce
If a type fails to unify directly, 9sh searches the environment for an Implicit Combinator to bridge the gap.

If you type `$ g++ *.c` across 50 files, the Unifier sees a mismatch: `g++` expects a single file, but it was handed a `List`. It searches `///traits` and finds `Trait.ScatterGather`. It proposes a new Structure:

```text
parallel(
  how_many = 5,
  where = [node1, node2, node3, node4, node5],
  what = g++(*.c)
)
```
By simply unifying types, 9sh discovers distributed build farms and Map/Reduce topologies for free.

### Explicit Typing (Manual Override)
If you want to bypass the Unifier, you simply provide a more concrete Shadow using the Trait Coercion Operator (`:`).

```sh
$ grep:~9 ERROR
```
By explicitly pinning the type to `~9` (Local), the Shadow *is* the Structure. There is zero ambiguity, and 9sh executes it exactly like standard `bash`. User intent is just type annotation.


## 3. Optimization as Disambiguation (The QMC Solver)
When the Unifier generates multiple valid Structures that cast the exact same Shadow, how does 9sh choose?

**Optimization is simply the algorithm we use to disambiguate underspecified pipeline types.**

9sh resolves ambiguity using a **Quasi-Monte Carlo (QMC) Stochastic Solver**.
Every VFS node and command maintains a lightweight, 2KB statistical sketch of its historical execution in the `///profile` moment (e.g., "grep usually filters 90% of data," "this disk has a 1% failure rate").

The QMC Solver takes the valid Structures and runs a rapid Monte Carlo simulation over these samplers to minimize the user's **Cost Function**.

*   If your Cost Function is `Time`, the Solver picks the Structure that parallelizes compute across the Spacetime Mesh.
*   If your Cost Function is `AWS_Egress_Fees`, the Solver picks the Structure that pushes all filtering to the remote Cylinder.

If the QMC Solver times out (e.g., after 50ms), or if the math is too complex, 9sh safely degrades to the first valid Structure it found (usually local POSIX execution). It never hangs; it just degrades gracefully.


## 4. Execution and Online Iteration (MPC)
Once a Structure is chosen, the 9sh microkernel mechanically translates it into physical axioms: spawning namespaces, opening WebRTC datachannels, and wiring file descriptors.

But distributed systems are volatile. What happens if a node's CPU spikes 10 minutes into a heavy analytics job?

Because 9sh treats pipelines as constrained optimization problems, it executes them using **Model Predictive Control (MPC)**. The `c0` daemon continuously monitors the throughput of the switching fabric. If reality deviates from the QMC Solver's expected model by a defined threshold, 9sh initiates a **Replumb**:

1.  The MPC loop sends a `SIGSTOP` to the bottlenecked pipe.
2.  Because of the VFS Auto-ACK liability fabric, no data is lost; it simply buffers at the Source Cylinder.
3.  The Unifier and QMC Solver run again, discovering that a different node in the mesh is now idle.
4.  9sh spins up the actor on the new node, rewires the WebRTC datachannels, and resumes the flow of bytes.

The user never sees a blip. The data never drops. You achieve Kubernetes-level pod-eviction and Kafka-level consumer rebalancing using nothing but POSIX pipes and pure type theory.
