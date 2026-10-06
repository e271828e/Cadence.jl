# Compile cost re-evaluation, 2026-10-01

A critical second pass over the [2026-09-30 compile-cost report](../20260930_compile_cost/report.md).
That report proposed a roadmap. This one tests its first five items as source
patches, adds chunking itself to the list, measures each alone and combined
on three model scenarios, and explains the mechanism behind every number.

## Summary

**Where the time went.** At the pinned tip, the time from building a model to
its first simulated frame is 13 s for a 10-component model and 45 to 67 s for
a 64 to 128-component one. Rebuilding after a topology change in a warm
session still costs 3 s and 32 s. Three terms carry almost all of it:

1. **The declaration layer compiles again for every component type and every
   root type.** That is 12 to 40 s of `build` on the large models.
2. **Every call that hands a chunk to its walk copies the chunk.** Chunks are
   immutable and stored inline, so each call site emits a copy and a GC root
   per pointer. That is 17 s of `init!` and `run!` on the repeated-type model,
   and a fifth to a third of the loop's runtime.
3. **The walks themselves**, 1 to 9 s.

**What removes it.** One stack of patches with no new dependency and no
experimental API, 242 changed lines, passing the full gate (4278 of 4278):

| time to first simulation, `-O2` | pinned tip | recommended stack | at `-O0` |
|---|---|---|---|
| 10 components, 5 types: cold | 12.6 s | 8.6 s | 3.7 s |
| the same, after a topology change | 3.1 s | 0.85 s | 0.34 s |
| 128 components, 2 types: cold | 44.7 s | 9.4 s | 4.4 s |
| the same, after a topology change | 32.0 s | 0.96 s | 0.30 s |
| 64 components, 64 types: cold | 67.2 s | 13.5 s | 6.6 s |
| the same, after a topology change | 32.8 s | 3.6 s | 2.3 s |

Trajectories are bit-identical and every allocation check reads zero. The
warm loop runs as fast as before on the small model and faster on the large
ones: 7 times faster on the repeated-type model, where the pinned tip
allocates at every boundary.

**What the earlier report got wrong.** Its item 1 makes things much worse as
written. Its claim that pointer chunks leave the loop's cost in place is the
opposite of what happens. Most of the cost it charged to `Group` belongs to
the declaration layer. Its per-entry opaque closures do not match the unrolled
walk at runtime on a model of distinct types. §8 lists each.

**What the pinned tip gets wrong.** Three defects surfaced, independent of
compile cost: a tuple walk over more than 32 elements loses static dispatch
and allocates; a body is therefore capped at 512 entries; and `build`'s
runtime grows steeply with the width of a root. §9 lists them.

**The open trade.** The recommended stack leaves about 3.6 s per topology
change on a model of entirely distinct types, all of it walk compilation.
Closures remove it: one opaque closure per entry brings every scenario under
0.5 s. The price is a loop 60 to 70 percent slower on the distinct-type
model, a dependence on an internal calling convention, and a live simulation
that no longer sees a redefined method. §4.6 has the numbers. I recommend
against it for now.

## 1. Scope and method

**Tip and environment.** Julia 1.13.0, Apple Silicon with 4 performance
cores. The repository at `2556df4` was exported with `git archive` into a
scratch directory, with the workspace `Manifest.toml` beside it. Every
variant is a copy of that export with one or more patches from `patches/`
applied. Nothing in `src/` or `test/` of the repository changed.

**Anchor.** The earlier report's own fixture and headline measurement
reproduce at this tip: `build` 12.0 s, `init!` 1.69 s, `run!` 6.82 s, against
its 11.3, 1.67 and 6.79 at `82c23d5` (`probes/anchor.jl`). The verifier, on a
quieter machine, got 11.3, 1.6 and 6.3.

**Fixtures** (`probes/fixtures.jl`). Components with real arithmetic: a rigid
body with quaternion kinematics, Euler's equations and a projection; a
discrete rate controller at 50 Hz with StaticArrays matrix products; an
algebraic damper; and the README's scalar plant and PI loop. Three scenarios:

- **small**: 10 components of 5 types.
- **repeated**: 64 attitude loops, 128 components of 2 types, 320 entries.
- **distinct**: 32 attitude loops, 64 components of 64 types, 160 entries.

Every root and subassembly is a `Group`. The fixtures have no events, modes
or workspaces.

**Modes** (`probes/measure.jl`). Each run is one process.

- **cold**: the scenario's model is the first one in the process.
- **types**: a model of unrelated types ran first, so the generic machinery
  is compiled and the scenario's types are new.
- **iter**: the scenario's previous topology ran first, so its component
  types are compiled and only the topology is new. The previous topology is
  the model without one subassembly (small), with 63 loops (repeated), or the
  same 32 loops rotated by one (distinct). The rotation keeps every type
  known and shifts the content of every chunk.

**What a run records.** Wall seconds for constructing the root, `build`,
`Simulation`, the first call of the four phase bodies in both arities,
`init!`, and the first `run!`. Their sum is "first sim" below. Then, outside
the timers: the warm runtime in ms per simulated second; allocation of the
interior bodies, of the boundary bodies, and of one whole boundary; and a
hash of the final state. Every timer sits at top level, because a timer
inside a wrapper function under-reports.

**Runs.** 1 035 runs: every cell three times, the minimum reported. The
spread between the three is under 5 % in most cells and is in the raw files.
The matrix ran two or three processes at a time. Exact figures therefore
carry a few percent of noise; no conclusion below rests on less than a
factor of 1.2.

**Method rule.** Every mechanism is a change to the package source, in the
form it would land. The earlier report built its variants as wrappers inside
probe scripts, and two of its claims measured the wrapper instead of the
roadmap item.

**Who did what.** The harness, the fixtures, the small executor patches and
the final timings are the coordinator's. Four agents wrote the larger
patches, each on its own export, and each ran the suite. Their reports are in
`agent_reports/`. A fifth, cold agent then tried to refute the headline
claims from the patch files alone (§11).

## 2. Background

Five facts about Julia's compiler explain every result in this report.

**Specialization.** Julia compiles a method once for each concrete
combination of argument types, at the first call. `f(x) = x + 1` called with
an `Int` and a `Float64` yields two compiled versions. Each goes through type
inference, Julia's optimizer, LLVM code generation, LLVM optimization and
machine code emission. The LLVM stages dominate, and their cost grows with
the amount of code in the function.

**Types that carry structure.** Redstone stores a model's entries in tuples,
and a tuple's type lists its elements' types. So `typeof(sim)` spells out the
whole topology, and so does the type of a `Group` root. Any method that takes
such a value compiles again for every topology. That is harmless when the
method is small and expensive when it is not.

**Inlining.** The optimizer may replace a call with a copy of the callee's
body. `@inline` and `@noinline` force the choice. An inlined callee is
compiled again at every call site.

**Inline storage and the by-value hand-off.** An immutable struct is stored
inside its parent. A `mutable struct` lives on the heap and its parent holds
a pointer.

```julia
struct Inline;        a::Vector{Float64}; b::Vector{Float64}; end  # 16 bytes inside the parent
mutable struct Boxed; a::Vector{Float64}; b::Vector{Float64}; end  # the parent holds one pointer
```

When code passes an inline immutable to a non-inlined function, it copies the
struct to the stack and registers every pointer in it with the garbage
collector. The emitted code grows with the struct's size, and so does the
runtime. Passing a `Boxed` passes one pointer.

**The 32-element limit.** The usual way to walk a tuple of mixed types is a
recursion on `Base.tail`:

```julia
walk(::Tuple{}) = nothing
walk(t::Tuple) = (run(t[1]); walk(Base.tail(t)))
```

Julia infers this exactly up to 32 elements. Past that it gives up, the calls
become dynamic, and each one allocates. A `@generated` function that emits
one statement per element has no such limit.

## 3. The pinned tip

Seconds, chunk size 16, the minimum of three runs:

| scenario, mode | construct | `build` | `Simulation` | walks | `init!` | `run!` | first sim |
|---|---|---|---|---|---|---|---|
| small, cold | 0.31 | 6.90 | 2.42 | 0.66 | 1.22 | 1.14 | 12.6 |
| small, types | 0.27 | 2.90 | 0.89 | 0.49 | 0.60 | 0.80 | 5.9 |
| small, iter | 0.17 | 0.74 | 0.41 | 0.41 | 0.59 | 0.82 | 3.1 |
| repeated, cold | 0.45 | 16.68 | 3.13 | 5.25 | 6.34 | 12.85 | 44.7 |
| repeated, types | 0.42 | 12.64 | 1.97 | 5.13 | 5.86 | 12.38 | 38.4 |
| repeated, iter | 0.36 | 12.07 | 1.45 | 1.25 | 4.62 | 12.25 | 32.0 |
| distinct, cold | 0.72 | 40.63 | 6.41 | 8.89 | 3.25 | 7.32 | 67.2 |
| distinct, types | 0.70 | 40.48 | 5.29 | 9.26 | 2.86 | 7.58 | 66.2 |
| distinct, iter | 0.27 | 11.03 | 3.12 | 8.36 | 2.63 | 7.43 | 32.8 |

Three readings:

- About 7 s of a cold process is generic machinery, paid once whatever the
  model. The difference between the cold and types rows of the small model
  shows it.
- `build` costs about 0.4 s per new component type and about 11 s per new
  root, even when every type is known. Together they make the 40 s of the
  distinct model.
- `init!` and `run!` cost 17 s per new topology on the repeated model. They
  contain no model arithmetic. §4.2 explains what they compile.

## 4. The mechanisms

Each subsection gives the mechanism, where its cost arises in the code, what
the patch changes, and what was measured. "First sim" figures are cold and
iter, in seconds, at `-O2`.

### 4.1 Chunking

**The mechanism.** A phase body walks its entries with every call resolved at
compile time. Unrolled into one function, a body of N entries is one large
function, and LLVM's cost grows faster than N. Chunking splits the tuple into
groups of `chunk_size` entries, each behind a non-inlined call
(`src/executor.jl`, `Chunk`), so no function exceeds 16 entries.

**The requested baseline is not a valid executor.** With no chunking at the
pinned tip, every large body exceeds the 32-element limit:

| repeated scenario | first sim, cold | walks | warm run, ms per sim-second | allocation per boundary |
|---|---|---|---|---|
| pinned, no chunking | 174.8 | 104.7 | 1977 | 5.7 MB |
| pinned, chunk 4 | 33.0 | 1.8 | 88 | 595 KB |
| pinned, chunk 16 | 44.7 | 5.3 | 84 | 595 KB |

Even the chunked rows allocate, because the projection walk is not chunked
(§9). So the honest unchunked baseline needs the generated unroll first
(`patches/genwalk.patch`, 52 changed lines), which restores static dispatch
at any length:

| generated unroll | repeated: cold / iter | distinct: cold / iter | warm, repeated |
|---|---|---|---|
| no chunking | 71.7 / 65.0 | 67.1 / 32.7 | 17.8 |
| chunk 4 | 31.2 / 23.3 | 58.6 / 22.0 | 17.5 |
| chunk 16 | 39.7 / 30.4 | 61.6 / 26.5 | 17.5 |

On the small model chunking changes nothing: no body exceeds one chunk.

**What chunking buys, and why.** Three effects, in order of size:

1. **Identical chunks share one compiled function.** The repeated model's 64
   `y_state` entries make four chunks of one type, compiled once. Unchunked,
   the walks cost 23.2 s; at chunk 16 they cost 2.8 s. On the distinct model,
   where no two chunks match, the same comparison is 6.4 s against 3.7 s.
2. **Smaller functions compile faster than linearly.** The distinct model's
   6.4, 3.7 and 2.7 s at none, 16 and 4 show the superlinear term on its own.
   It is real but modest at these body sizes, about a factor of two.
3. **At the pinned tip, a smaller chunk is a smaller copy.** Chunk 4 beats
   chunk 16 by 7 to 12 s there, most of it in `init!` and `run!`. §4.2 removes
   that term, after which chunk 4 and 16 differ by about 1 s.

**What chunking costs.** A chunk's type is the tuple of its entries' types.
Inserting or reordering one component shifts every later chunk's content, so
each becomes a new type and compiles again. That is the 2.4 s of walks the
recommended stack still pays on `distinct iter`. Smaller chunks halve it
(1.3 s at chunk 4) and cost 3 to 9 % of runtime on the large models.

**Does the original reason hold?** Yes. §9.7's reason was the superlinear
growth of one function, and the distinct-model figures confirm it. But
sharing between identical chunks is the larger benefit, and the spec does not
mention it.

### 4.2 Item 1: a seam at the phase-body call

**Where the cost arises.** The chunk call is `@noinline`. The phase-body call
above it is `@inline`:

```julia
@noinline (chunk::Chunk)() = _walk(chunk.entries, chunk.store, chunk.xbuf, chunk.ẋbuf)
@inline (body::PhaseBody)() = _walkchunks(body.interior)
```

So at every call site `body()` becomes a sequence of chunk calls. Each chunk
is an inline immutable holding 16 entries, inside the `PhaseBody`, inside the
executor, inside the `Simulation`. Each call therefore emits a copy of the
chunk and a GC root per pointer. On the repeated model (`probes/mechanism.jl`):

| method, pinned tip | LLVM lines | `memcpy` calls | GC frame slots |
|---|---|---|---|
| `evaluate!(sim)`, 12 chunk calls | 6 330 | 192 | 742 |
| RK4 `step!`, four `evaluate!` | 18 587 | 768 | 2 964 |
| `event_phase!(sim, ::Int)` | 12 258 | 392 | 1 747 |

These methods inline upward into `init!` and `run!`, which is why those two
cost 17 s and contain no model arithmetic. The walks are not recompiled at
each site. What repeats is the hand-off.

**The roadmap's patch makes it worse.** Item 1 said to put `@noinline` on
`PhaseBody`'s two call methods. Each site then passes the whole `PhaseBody`
by value, which is larger than the chunks it copied before
(`patches/item1_literal.patch`):

| | repeated: cold / iter | `run!`, iter | `evaluate!` LLVM lines | warm |
|---|---|---|---|---|
| pinned, chunk 16 | 44.7 / 32.0 | 12.3 | 6 330 | 84 |
| item 1 as written | 83.3 / 70.6 | 46.2 | 15 325 | 97 |
| `mutable struct PhaseBody` and `@noinline` | 32.3 / 20.3 | 1.4 | 20 | 84 |

**What works** is the third row (`patches/item1_ptr.patch`): the seam must
hand over a pointer. The earlier report's 0.3 s figure came from a probe
wrapper declared `mutable struct`, so it measured this row, not the item.

**What it buys.** 12 s per topology on the repeated model, 9 s on the
distinct one, 1.3 s on the small one. It leaves the copies inside each body's
own function, compiled once per body, so the walks get slower to compile
(2.5 s against 1.3 s) and the runtime does not improve.

### 4.3 Item 4, first half: chunks behind pointers

**The patch** is one word, `mutable struct Chunk` (`patches/ptrchunk.patch`).
A phase body becomes a tuple of pointers. The inlined call site loads a
pointer and calls. No copy remains anywhere, so this subsumes item 1.

| | repeated: cold / iter | distinct: cold / iter | `evaluate!` LLVM lines |
|---|---|---|---|
| pinned, chunk 16 | 44.7 / 32.0 | 67.2 / 32.8 | 6 330 |
| pointer chunks, chunk 16 | 29.1 / 16.4 | 58.7 / 22.7 | 47 |

On the small model it saves 1.3 s per topology (3.1 → 1.8 s).

**The executor patch of the recommended stack** (`patches/execA_small.patch`,
99 changed lines) is this plus four things: the generated unroll; the event set's three walks
chunked behind pointers, with a mutable `EventSet`; a body with no gated
entry reusing its interior walk at a boundary; and untyped comprehensions
where the chunks are built. With it the per-topology executor cost on the
repeated model is 0.6 s, against 19.6 s at the pinned tip:

| executor side only, iter | `Simulation` | walks | `init!` | `run!` | warm |
|---|---|---|---|---|---|
| repeated, pinned | 1.45 | 1.25 | 4.62 | 12.25 | 90 |
| repeated, this patch | 0.04 | 0.02 | 0.20 | 0.31 | 12.7 |
| distinct, pinned | 3.12 | 8.36 | 2.63 | 7.43 | 10.2 |
| distinct, this patch | 0.03 | 2.54 | 0.68 | 0.29 | 8.1 |

The warm gain on the repeated model is mostly the allocation defect of §9
going away. The gain on the distinct model, 20 %, is the copies.

The earlier report's §2.2 says the opposite of this subsection: that pointer
chunks "leave `init!` and `run!` at 1.74 s and 5.59 s". Its probe wrapped
each chunk in a small mutable wrapper whose call method inlined, so every
site loaded the chunk by value again.

### 4.4 Item 2: `@nospecialize` through the declaration layer

**Where the cost arises.** `build` walks the component tree, reads each
component's declarations and checks them. That code takes a component as an
argument, so Julia compiles it once per component type: `_walk!`, the
closures it creates, the probes. It also takes the root, so it compiles once
per root type. None of it runs more than once per build.

**The patch** (`patches/nospec.patch`, 131 changed lines in `assembly.jl`,
`build.jl`, `declare.jl`). `@nospecialize` on about 35 signatures. Five
closures stop capturing the component instance, because a closure that
captures a typed local is itself parameterized by that type. `_children`
walks containers through `getfield` into a `Vector{Any}` instead of using
tuple operations.

| `build` seconds | small | repeated | distinct |
|---|---|---|---|
| cold: pinned → patched | 6.90 → 4.80 | 16.68 → 4.68 | 40.63 → 5.42 |
| types: pinned → patched | 2.90 → 0.07 | 12.64 → 0.12 | 40.48 → 0.86 |
| iter: pinned → patched | 0.74 → 0.00 | 12.07 → 0.08 | 11.03 → 0.02 |

By the agent's trace attribution, the compile per new component type falls
from 0.42 s to 0.013 s, and nearly all of what remains is the user's own
stage methods, which the probe must run. Per new 64-loop root it falls from
11.2 s to 0.05 s. The cold figure
settles near 4.8 s whatever the model, so a precompile workload would cover
all of it.

The patch passes the gate, 4278 of 4278, so every diagnostic still names its
site. The earlier report never ran its version against the suite.

**Limits.** A component with state events still compiles one closure per
type in `probe_events`. The fixtures have no events, so this was not
exercised. Warm `build` runtime is unchanged at these sizes and worse at
1024 children (§6).

### 4.5 Item 3: phase bodies behind closures

**The idea.** After §4.3 the loop methods are small, but they still compile
once per topology, because `Simulation{T,E}` carries the executor's type. An
opaque closure hides its captured data from its type: every
`Core.OpaqueClosure{Tuple{},Nothing}` is one type, whatever it closes over.
Put each phase body and each event-set walk behind one, and `typeof(sim)`
stops depending on the model. The loop then compiles once per scalar type.

**The patch** (`patches/execB.patch`, on top of §4.3's). `PhaseBody` and
`EventSet` become concrete types holding three closures each. `Executor`
drops its `B` and `EV` parameters. `typeof(sim)` is one 173-character type
for all three scenarios.

| first sim, iter, with the declaration-layer patch | small | repeated | distinct |
|---|---|---|---|
| stack A (§4.3 and §4.4) | 0.86 | 1.01 | 3.65 |
| stack B (this on top) | 0.38 | 0.45 | 3.14 |

**What it buys** is about 0.5 s per topology, the same on every model: the
constructors, the accessors and the loop's own code. On the distinct model
the remainder is the walks, which no seam at this level removes. Warm
runtime is within 0 to 6 % of stack A.

**What it costs.**

- A dependence on `Base.Experimental.@opaque`. D-086 rejected reliance on an
  experimental interface.
- **World age.** An opaque closure runs in the world it was created in. A
  user who redefines a component method and does not rebuild the simulation
  keeps the old method, silently. Stack A follows the redefinition.
- Two Julia 1.13 pitfalls the agent hit: an opaque closure that compiles to a
  constant return allocates 48 B per call, and a closure that calls a
  captured opaque closure allocates.
- A FunctionWrappers variant avoids the first two costs and runs 6 to 22 %
  slower (`patches/execB_fw_over_B.patch`).

The earlier report estimated this item at 8.5 s per topology. Nearly all of
that was the by-value copies, which §4.3 removes without closures. It also
said the store type `S` stays because the activation-identity checks key on
it. They key on the scalar `T`; `S` stays because the generated gather and
scatter need it statically.

### 4.6 Item 4, second half: one closure per entry

**The idea.** Take §4.5 to the limit: one opaque closure per entry, held in a
vector, walked by a plain loop. No chunks and no unrolled tuple. A closure's
body compiles once per captured type, so instances of one component type
share one compiled body, and a reordered model reuses every body.

**The patch** (`patches/entryclosures.patch`, 347 changed lines). The gate
`(tick - Φ) % D == 0` moves from a wrapper type into the walk's loop.
`chunk_size` is accepted and ignored.

| first sim, with the declaration-layer patch | small | repeated | distinct |
|---|---|---|---|
| stack A: cold / types / iter | 8.6 / 1.2 / 0.86 | 9.9 / 2.7 / 1.01 | 14.0 / 7.1 / 3.65 |
| stack C: cold / types / iter | 8.7 / 0.5 / 0.18 | 8.4 / 0.8 / 0.46 | 12.4 / 4.5 / 0.30 |

Almost all of stack C's `iter` time is constructing the root. 320 closures
share 5 compiled bodies on the repeated model.

**What it costs.**

- **Runtime.** One indirect call per entry, each through a world-age switch.

  | warm run, ms per sim-second | small | repeated | distinct |
  |---|---|---|---|
  | stack A | 1.1 | 12.2 | 7.8 |
  | stack C | 1.1 | 12.3 to 13.7 | 13.5 to 14.5 |

  On the distinct model, where every call has a different target, the loop
  is 70 % slower. On the repeated model it is at par.
- **A fragile representation.** On Julia 1.13.0, whether a call through a
  `Vector{Core.OpaqueClosure{Tuple{},Nothing}}` allocates depends on how the
  closure was built. The patch's closures allocate 48 B per call, and ten
  lines reproduce it. The earlier report's own probe does not allocate. The
  patch avoids the allocation by keeping the closures boxed and calling each
  through its internal `invoke` field with a `ccall`, which is the dependence
  on internal ABI that D-086 names. The verifier found that a plain call
  through an abstractly typed vector also reads 0 B, so the `ccall` may be
  avoidable. A `@cfunction` per entry type is a documented alternative that
  was not built.
- **World age**, as in §4.5.
- Under the gate both closure stacks fail two assertions of one
  timing-dependent test (§9).

The earlier report's §5 gives this representation "2.4 to 2.9 ns per entry,
0 allocation" and concludes it "lost nothing at runtime". The allocation
figure holds for its probe and not for every way of building the closure.
The runtime conclusion holds for repeated types and fails for distinct ones.

## 5. Combined stacks

First sim in seconds, the minimum of three runs. Stack A is §4.3 and §4.4.
Stack B adds §4.5. Stack C is §4.6 and §4.4. "Recommended" is stack A with
the child-list cache of §6, measured last on a quiet machine.

**`-O2`**

| scenario, mode | pinned, no chunking | pinned, chunk 16 | stack A | stack B | stack C | recommended | recommended, chunk 4 |
|---|---|---|---|---|---|---|---|
| small, cold | 12.8 | 12.6 | 8.6 | 9.2 | 8.7 | 8.6 | 8.6 |
| small, types | 6.0 | 5.9 | 1.2 | 0.7 | 0.5 | 1.2 | 1.2 |
| small, iter | 3.1 | 3.1 | 0.86 | 0.38 | 0.18 | 0.85 | 0.85 |
| repeated, cold | 174.8 | 44.7 | 9.9 | 10.1 | 8.4 | 9.4 | 8.5 |
| repeated, types | 172.8 | 38.4 | 2.7 | 2.2 | 0.8 | 2.6 | 1.7 |
| repeated, iter | 92.9 | 32.0 | 1.01 | 0.45 | 0.46 | 0.96 | 1.19 |
| distinct, cold | 101.6 | 67.2 | 14.0 | 14.4 | 12.4 | 13.5 | 12.3 |
| distinct, types | 97.2 | 66.2 | 7.1 | 6.5 | 4.5 | 6.6 | 5.5 |
| distinct, iter | 69.0 | 32.8 | 3.65 | 3.14 | 0.30 | 3.57 | 2.47 |

**`-O0`**

| scenario, mode | pinned, no chunking | pinned, chunk 16 | stack A | stack B | stack C | recommended | recommended, chunk 4 |
|---|---|---|---|---|---|---|---|
| small, cold | 5.0 | 5.0 | 3.7 | 3.8 | 3.6 | 3.7 | 3.7 |
| small, types | 1.9 | 1.9 | 0.51 | 0.35 | 0.22 | 0.50 | 0.52 |
| small, iter | 0.68 | 0.68 | 0.34 | 0.17 | 0.07 | 0.34 | 0.35 |
| repeated, cold | 105.6 | 10.1 | 4.6 | 4.9 | 3.6 | 4.4 | 3.5 |
| repeated, types | 105.3 | 7.5 | 1.6 | 1.3 | 0.27 | 1.5 | 0.59 |
| repeated, iter | 24.7 | 2.1 | 0.34 | 0.14 | 0.15 | 0.30 | 0.34 |
| distinct, cold | 56.5 | 26.9 | 7.2 | 6.8 | 5.2 | 6.6 | 5.6 |
| distinct, types | 51.0 | 22.6 | 3.7 | 3.6 | 1.9 | 3.5 | 2.6 |
| distinct, iter | 41.9 | 9.9 | 2.3 | 2.2 | 0.11 | 2.3 | 1.3 |

**Warm runtime**, ms per simulated second:

| | small | repeated | distinct |
|---|---|---|---|
| pinned, chunk 16, `-O2` | 1.2 | 84 | 9.7 |
| recommended, `-O2` | 1.1 | 12.0 | 7.7 |
| recommended, `-O0` | 2.7 | 34.1 | 17.8 |

Readings:

- The mechanisms act on separate steps and their savings add. Stack A's
  figures are, within noise, the pinned figures minus the two individual
  savings.
- On both large models the recommended stack at `-O2` beats the pinned tip
  at `-O0` in every mode, and its loop runs 2.5 to 9 times faster.
- `-O0` still helps on top of the stack: about half the remaining time, for
  a loop 2.3 to 2.8 times slower.
- Cold figures settle at 9 to 14 s on every stack. Most of what is left is
  generic machinery, the same for every model, about 4.8 s of it in `build`.
  A precompile workload, the earlier report's item 6, is the lever for it.
  It was not measured here.

## 6. `Group`

**The question changed.** The earlier report charged `Group` with 11 s per
64-loop root, because `Group{C,W,I,O,R}` carries its subtree in its type. The
declaration-layer patch removes that cost without touching `Group`: a new
64-loop root then costs `build` 0.05 s. So the question became what a typed
`Group` still costs.

**What remains.** A typed root is one inline value, 22.5 KB at 64 loops. Any
code that moves it by value compiles a copy of that layout.

| new root of known types, on the declaration-layer patch (the agent's single runs) | typed `Group` | erased `Group` |
|---|---|---|
| constructing a 64-loop root | 0.23 s | 0.013 s |
| a trivial function taking the root | 0.26 s | 0.002 s |
| `Simulation(root; …)` | 0.22 s | 0.02 s |
| constructing a 16-by-16 nested root | 0.75 s | 0.003 s |
| default `show` of the 64-loop root | 1.06 s | 0.31 s |

The earlier report's "trivial functions over the same type compile
instantly" does not hold: 0.26 s for one that returns the root. The cost
peaks at 64 children, because Julia stops storing the root inline at 128.

**Two variants** (the `group` agent, `agent_reports/group.md`):

- **`groupabs`**: an abstractly typed `children` field, the other four
  parameters kept. This is the earlier report's item 5 as stated.
- **`grouperased`**: `struct Group <: AbstractComponent` with no parameters
  (`patches/grouperased_over_nospec.patch`, 26 changed lines). The gate passes with
  no test edited.

| `build` seconds, harness | repeated, types | repeated, iter | distinct, types | distinct, iter |
|---|---|---|---|---|
| pinned | 12.64 | 12.07 | 40.48 | 11.03 |
| `groupabs` alone | 2.11 | 1.66 | 17.37 | 0.32 |
| `grouperased` alone | 0.67 | 0.14 | 16.81 | 0.04 |
| declaration-layer patch alone | 0.12 | 0.08 | 0.86 | 0.02 |
| both | 0.10 | 0.07 | 0.75 | 0.02 |

Readings:

- **Alone, the erased `Group` removes the per-root term and nothing else.**
  The 17 s left on the distinct model is the per-type term, which only the
  declaration-layer patch removes.
- **An abstract children field is not enough.** The root's type still changes
  with the length of its fanned input, so `build` still compiles per root.
  The earlier report's 0.75 s figure came from a hand-written struct with no
  type parameters, which is the erased variant.
- **On top of the declaration-layer patch the erased `Group` buys little
  compile time**: 0.2 s of construction per root, 0.2 s in
  `Simulation(root)`, up to 0.75 s for nested roots.
- **It buys readability.** A misspelled `Group` keyword prints 41 562
  characters today and 2 948 with the erased type.

**A separate finding: `build` runtime grows steeply with root width.** Warm
`build` of a flat root, no compilation involved:

| children | pinned | declaration-layer patch | plus child-list cache |
|---|---|---|---|
| 64 | 45 ms | 31 ms | |
| 256 | 205 ms | 298 ms | 114 ms |
| 1024 | 4.3 s | 10.4 s | 0.68 s |

Each fanned endpoint re-derives the root's whole child list. The
declaration-layer patch makes each derivation slower at large widths, because
it reads field names dynamically. A per-walk cache of child lists
(`patches/group_kidsmemo_over_grouperased.patch`, 12 changed lines, which
applies to the typed `Group` as well), like the existing cache of faces,
removes most of it. The recommended stack includes
it, and the declaration-layer patch should not land without it.

**The default display of a root is slow to compile.** `repr(root)` costs
about 1 s at 64 children and 4.6 s at 1024, on every variant. A REPL user
who leaves off the semicolon pays it at each new root. A compact `show`
method for `Group` would remove it. It was not built.

**What erasure gives up.** The service walk (§13.3, D-130) lets a path pass
through a child only when the parent's field declares a concrete type,
because a concrete type pins the subtree below it. A typed `Group{…}` field
does that: `test_readers.jl`'s `ReadableHold` declares
`inner::typeof(readable())` for exactly this reason. An erased `Group` is one
concrete type for every topology, so a field declared `::Group` passes the
check and pins nothing. The verifier's reproduction
(`probes/review_grouphold.jl`), which I re-ran:

| a path through a field declared `inner::Group` | result |
|---|---|
| pinned tip | refused, `past_generic` at `inner` |
| erased `Group` | accepted |
| erased `Group`, with every `Group` field treated as generically held (`patches/group_fields_generic_over_erased.patch`) | refused, but `test_readers.jl:319` then fails: it reads through a concretely typed `Group` field |

The gate does not cover the first case, so it passes on the erased variant.
Erasure removes a distinction the rule reads, and no local repair restores
both behaviours. The `group` agent's report says no rule is contradicted;
that is wrong.

**Recommendation.** Leave `Group` typed. With the declaration-layer patch in,
erasure buys 0.2 s of construction per root, up to 0.75 s for a nested root,
and shorter error messages. Against that it changes what D-130 admits. If
those gains come to matter, the choice is a ruling on D-130 for `Group`
fields, or a second, erased assembly type for roots that no named assembly
holds. Both erased patches stay in `patches/`.

## 7. Recommendation

**Land `patches/recommended.patch`**, 242 changed lines over four files. It
is four separable changes, in order of yield:

1. The declaration-layer patch (§4.4): `build` no longer compiles per
   component type or per root.
2. Pointer chunks and a pointer event set (§4.3): no by-value hand-off.
3. The generated unroll and chunked event-set walks (§4.1, §9): no
   32-element limit, no ceiling on body size.
4. The child-list cache (§6), which the first change needs at large widths.

It passes the gate, 4278 of 4278. The gate ran in 3 min 31 s, against the
7 minutes `implementation.md` quotes for the suite. Trajectories are
bit-identical to the pinned tip at `-O2`.

Two notes from the verifier's review, for whoever lands it:

- The child-list cache returns its stored vector. The face cache beside it
  copies on the way out. No caller mutates the list today.
- `EventSet.entries` and `.projects` now hold chunks, so `length` of either
  counts chunks. No code in `src/` reads them that way.

**Consider a smaller default chunk size.** With the copies gone, chunk 4
saves about 1 s on the large models wherever chunk functions must compile.
It costs 0.2 s on the repeated model's iteration, where chunk 16 reuses
every chunk, and 3 to 9 % of runtime. Chunk 8 was measured only in a
preliminary pass and sat between.

**Do not adopt the closure stacks now.** Stack B buys 0.5 s per topology and
stack C buys the last 3 s on distinct-type models. Both need an experimental
interface and change what a live simulation does under redefinition, and
stack C costs runtime. They stay available as patches if iteration on large
distinct-type models comes to matter more than the loop's speed.

**Not measured here, and next in line:** a precompile workload for the cold
floor, and components with events, modes or workspaces.

**What the spec would owe**, if the recommended stack lands:

- **§9.7's chunking paragraph**: the walk is a generated unroll; chunks are
  mutable; the event set's walks are chunked; sharing between identical
  chunks is a stated benefit; chunk size trades iteration cost against
  runtime.
- **§9.7's anchor table and mitigation ladder**: replaced by §3 and §5 here.
- **§9.7's "the seams cost nothing"**: true only when the seam hands over a
  pointer.
- **D-086** stands as written. Its rejection of type-erased call tables is
  what §4.5 and §4.6 would overturn, and this report recommends against that.
- **`pending.md`'s compile-time bullet** names the earlier roadmap, starting
  with the item that §4.2 shows to be harmful.

## 8. Corrections to the 2026-09-30 report

| its claim | what was measured here |
|---|---|
| §6 item 1: `@noinline` on `PhaseBody`'s call methods, "two lines", `run!` 6.8 → 0.3 s | As written, `run!` goes from 12.3 to 46.2 s on the repeated model. The 0.3 s came from a mutable probe wrapper. The seam needs a pointer (§4.2). |
| §2.1: `PhaseBody`'s call methods "are `@inline`, and so is everything below them" | The chunk call is `@noinline`. What each site repeats is the by-value hand-off of each chunk, not the walk. |
| §2.2: chunks behind pointers leave `init!` and `run!` at 1.74 s and 5.59 s; "this mechanism is the accessors' alone" | `mutable struct Chunk` alone removes the loop's cost (§4.3). The probe's wrapper inlined and re-loaded each chunk by value. |
| §2.2: "no runtime cost measured" for the seams | Correct for the seam. But the copies themselves cost runtime, 20 % on the distinct model. |
| §2.3 and §6 item 5: the `Group` root costs `build` 11 s; an abstract children field brings it to 0.75 s | The 11 s is the declaration layer specializing on the root, removed without touching `Group` (§4.4). An abstract children field alone leaves 1.7 s; full erasure reaches 0.14 s (§6). |
| §2.3: "trivial functions over the same type compile instantly" | 0.26 s for a function that returns a 64-loop root (§6). |
| §5: one opaque closure per entry, "2.4 to 2.9 ns, 0 allocation", "lost nothing at runtime" | Its probe does read 0 B. The patch's closures allocate 48 B per call through the same typed vector, so the property is fragile. On distinct types the working variant runs 70 % slower (§4.6). |
| §6 item 3: `init!` plus `run!` 8.5 s → 0.1 s per topology | True against the pinned tip. Against pointer chunks the closure seam is worth 0.5 s (§4.5). |
| §6 item 3: the store type `S` stays because the activation-identity checks key on it | They key on `T`. `S` stays for the generated gather and scatter. |
| §3: the per-type patch was "21 signatures", suite not run | 35 signatures, five closures and `_children` were needed. The gate passes (§4.4). |

Its measurements of the pinned behaviour reproduce (§1). The errors are in
what it attributed them to and in what its probes stood in for.

## 9. Defects found at the pinned tip

These are independent of compile cost. The recommended stack fixes the first
three.

1. **A walk over more than 32 elements allocates.** The projection, guard and
   fire walks (`_projects!`, `_guards!`, `_fire!`) are unchunked `Base.tail`
   recursions. A model with more than 32 projecting components, or more than
   32 events, loses static dispatch at every boundary. On the repeated
   scenario, 64 projections: 595 KB allocated per boundary and a loop 5 times
   slower. The §7.5 allocation tests do not see it, because no test model is
   that wide.
2. **A body is capped at 32 chunks.** The walk over a body's chunks is the
   same recursion. A body of more than 512 entries at the default chunk size,
   or more than 128 at chunk size 4, allocates. A `chunk_size` above 32
   allocates too.
3. **`build` runtime is steeply superlinear in root width** (§6): 4.3 s for
   1024 children.
4. **A timing-dependent test.** `test_trace.jl:934` and `:936` ("live staging
   into the harness is discarded on its own cell") race a staging task
   against a replay. Under both closure stacks the replay path is already
   compiled when the test runs and finishes first, so the two assertions
   fail under the full gate and pass alone. The recommended stack does not
   trigger it.

## 10. Caveats

- One machine, one Julia version. Timing cells ran two or three at a time.
- The fixtures have no events, modes, workspaces or localized events. The
  event-set patches are exercised by the suite, not by the timing matrix.
- "iter" is one kind of topology change per scenario. A change that leaves
  the entry order intact would pay less under chunking than the rotation
  used for the distinct scenario.
- The distinct scenario's 64 types have textually identical bodies. Real
  components differ, and their own inference and LLVM time is added per type
  under every stack.
- `measure.jl` calls each body in both arities before `init!`. Two of those
  calls, `ticks()` and `rhs(0)`, are walks the loop never runs. The verifier
  measured without them: 8 to 10 % lower on the cells without pointer chunks,
  the same on stack A.
- `repeated iter` is a best case for chunking: the 63-loop warm-up shares 7
  of the model's 8 chunk types. `distinct iter` is the adverse case.
- The trajectory hash covers the continuous state after one simulated second.
  It does not cover discrete state. At `-O0` it differs from `-O2` on every
  export, the pinned tip included, by round-off in one state in seven.
- No mode covers method redefinition under Revise or the readers.
- The closure stacks were not checked for package-image precompilation.

## 11. Verification

A cold agent received thirteen claims and the patch files, without the
reasoning behind them, and was asked to refute them. It rebuilt every export
from the pinned export and the patches, and each came out byte-identical to
the one measured. It wrote its own timer (`probes/mytime.jl`), which makes
no explicit body calls and compares whole state vectors.

**The harness.** Sound. Top-level wall time and the sum of
`--trace-compile-timing` entries agree within 0.3 % (3.565 against 3.555 s on
stack A, 29.907 against 29.890 s on the pinned tip, `distinct iter`). Its
caveats are in §10.

**The claims.** Eleven confirmed, two partly. Every number it measured
landed within 15 % of the claim.

| claim | verdict | the verifier's numbers |
|---|---|---|
| the anchor (§1) | confirmed | `build` 11.2 to 11.4, `init!` 1.6, `run!` 6.3 |
| the 32-element limit (§9) | confirmed | chunk 32 allocates 0 B, chunk 33 allocates 48 320 B; unchunked warm loop 27 times slower |
| item 1 as written is harmful (§4.2) | confirmed | `run!` 13.0 → 46.4 s; 6 330 → 15 325 lines |
| pointer chunks fix the loop (§4.3) | confirmed | 20.1 → 3.9 s; it rebuilt the earlier probe's wrapper and reproduced both its result and the fix |
| chunking (§4.1) | partly | same order, 8 to 10 % lower; it noted the chunk 4 gain persists under pointer chunks, which §4.1 attributes to smaller walk functions |
| the declaration layer (§4.4) | confirmed | 12.59 → 0.084 s and 42.19 → 0.79 s; gate 4278 of 4278 |
| stack A (§5) | confirmed | iter 0.97 / 1.04 / 3.68; cold 8.4 / 9.2 / 13.3 |
| stack B (§4.5) | confirmed | iter 0.39 / 0.43 / 3.11; one `typeof(sim)`; a live simulation ignores a redefined `x_deriv` |
| stack C (§4.6) | partly | iter 0.20 / 0.45 / 0.28; warm 13.7 to 14.2 against 7.9 to 8.7; the earlier probe's closures do not allocate |
| `Group` (§6) | confirmed | erased alone 0.12 s, abstract field alone 1.45 s |
| `build` runtime at 1024 children (§6) | confirmed | 4.25, 9.62 and 0.62 s |
| `-O0` (§5) | confirmed | iter 0.33 / 0.33 / 2.30; warm loop 2.8 times slower |
| the gate on the stack with the erased `Group` | confirmed | 4278 of 4278 |

**The review.** One finding changed this report: the erased `Group` alters
which service paths are refused (§6). It was in the recommended stack when
the verifier reviewed it and was taken out afterwards. The gate, the timings
of the `recommended` columns and the bit-identity check were then run again
on the stack without it. The two lesser findings are in §7.

**What it checked and found sound**, on a 120-component model with events,
modes and projections, past one chunk and past 32 elements
(`probes/review_events.jl`): state and mode hashes identical to the pinned
tip over 280 firings; `run!` allocation over 0.5 simulated seconds down from
940 MB to 4.4 MB; an error thrown by the 37th guard still attributed to its
component. That covers the event-set patches, which the timing fixtures do
not exercise.

## Files

- `probes/`: `fixtures.jl`, `measure.jl`, `mechanism.jl`, `anchor.jl`,
  `run_matrix.jl`, `tabulate.py`, the job lists, and the verifier's
  `mytime.jl`, `review_grouphold.jl` and `review_events.jl`.
- `patches/`: every patch, each a `diff -ru` against the `2556df4` export.
- `results/`: `raw_final.txt`, `raw_group.txt`, `raw_recommended.txt` and
  `raw_recommended_with_erased_group.txt` (one line per run),
  `mechanism.txt`, `gate_recommended.log`, and `verify/` with the verifier's
  raw output.
- `agent_reports/`: the four patch agents' long tables.
