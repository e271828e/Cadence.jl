# Compile cost of the build and the executor — 2026-09-30

Where time-to-first-simulation goes, measured on this repository at
`82c23d5`, and an ordered roadmap for cutting it. The question that prompted
it: could a compile-cheap executor backend give a user who iterates on model
architecture a Python-like turnaround, trading runtime for compile time? The
answer is that the runtime trade is unnecessary. The cost sits almost
entirely outside the entry walk §9.7 optimizes, and every large term has a
remedy that keeps the zero-allocation stepping intact.

## Scope and method

Julia 1.13.0, Apple Silicon, one cold process per script unless stated.
The repository at `82c23d5` was exported with `git archive` into a scratch
directory with the workspace `Manifest.toml` copied beside it, because the
working tree was being edited during the measurements. Nothing in the
repository changed for this report; the source experiments (§3) patched
the scratch export only.

Two fixtures:

- **loops**: N copies of the README loop, a continuous `Plant` under a
  discrete `PI` at 50 Hz, wired under one root with one fanned root input.
  Each loop is 2 components and 5 entries; "64 loops" is 128 components and
  about 380 entries. The root is a `Group` unless the text says otherwise.
- **rigid bodies**: N copies of a quaternion-and-inertia `Body` with a
  StaticArrays `Damper`, for real arithmetic in the bodies.

Compile time is `Base.cumulative_compile_time_ns` around each step, and
wall time beside it. Every timer sits at top level. A timer inside a wrapper
function under-reports, because Julia infers and compiles the wrapper's
callees before the wrapper's body runs; the first version of the scaling
script fell into that, and its numbers are not used here. Attribution comes
from `--trace-compile=file --trace-compile-timing`, diffing the statement
sets of two runs that differ by one step (`probes/trace_diff.py`). A traced
root includes everything inlined into it and every callee compiled in the
same request, so a root's time is a unit's, not a method's.

Every number below comes from a script under `probes/`.

## 1. Where the time goes

A cold process pays about 5 s for the first model, whatever its size:

| README loop, first in process | seconds |
|---|---|
| `using Cadence`, precompiled | 0.34 |
| `build` | 2.32 |
| `Simulation` | 1.05 |
| `init!` | 0.90 |
| first `run!` | 0.69 |

That is generic machinery, and a package precompile workload would cover
most of it: a second model of the same types costs about 2 s at 4 loops,
and a fourth model of already-seen shape costs nothing.

Every new topology pays again, and the cost grows with the model. For a
fresh 64-loop model whose component types are already compiled, spelled
under a struct assembly with an abstract children field:

| step, 64 loops, types known | seconds |
|---|---|
| `build` | 0.75 |
| `Simulation` | 3.5 |
| `init!` | 2.1 |
| first `run!` | 6.5 |

The walks' own code generation is about 2 s of those 13. The rest is the
loop machinery recompiling around the executor. Traced at 64 loops with the
walks called once beforehand: the `Simulation` constructor's 4.3 s is the
`Executor` constructor (3.1 s) and the `PhaseBody` constructors (1.1 s);
`phase_bodies(sim)`, a field read, compiles in 3.5 s; `init!` costs 1.5 s
and `run!` 6.4 s in one traced root each.

## 2. Three mechanisms, each verified

The executor was rebuilt around the same buffers with one thing changed at a
time, and a fresh topology timed at top level with the walks pre-called.

### 2.1 The walks inline into every loop method

`PhaseBody`'s call methods are `@inline`, and so is everything below them,
so every call site in sim.jl expands the whole chunk tuple. Three seams on
fresh 64-loop topologies:

| seam at the phase-body call | `init!` | `run!` | warm runtime |
|---|---|---|---|
| current inline `PhaseBody` | 1.67 s | 6.79 s | baseline |
| `@noinline` wrapper, executor type still per topology | 1.34 s | 0.33 s | same |
| opaque-closure bodies, one executor type for every topology | 0.72 s | 0.00 s | same |

The 0.72 s left under opaque bodies is the first walk of the `Establish`
arity, which the pre-call had skipped; with it warmed, `init!` costs 0.09 s.
A body behind one opaque closure costs nothing measurable per call (160 to
181 ns against 164 to 222 ns direct, noise). A body behind an `Any` field
costs 250 to 460 ns more per call, so the seam must be a closure or a
`FunctionWrapper`, never a bare `Any` slot.

### 2.2 Accessor compile scales with the value's inline size

Immutable structs with pointer fields are stored inline in their parents,
so the executor is one 48 KB inline aggregate and every method that loads it
by value emits a copy with a GC root per pointer. On the 64-loop executor:

| accessor | compile | LLVM lines |
|---|---|---|
| `exec.bodies` | 1.72 s | 17 639 |
| `exec.bodies.sweep_2` | 0.56 s | 7 335 |
| one chunk | 0.02 s | 581 |
| one entry | 0.00 s | 38 |
| a `String` field out of the aggregate | 0.00 s | 7 |
| `(exec.bodies; nothing)`, a load without a return | 0.00 s | 5 |

A synthetic aggregate with no Cadence in it reproduces the curve: leaves
with pointer fields in chunks of 16, immutable leaves at 33 KB compile the
accessor in 1.7 s, mutable leaves at 8.7 KB in 0.2 s, and a type string of
37 or 11 000 characters makes no difference. Putting Cadence's chunks behind
pointers shrinks the executor to 624 B and fixes every accessor, but leaves
`init!` and `run!` at 1.74 s and 5.59 s: this mechanism is the accessors'
alone, not the loop's.

### 2.3 A root that carries its subtree in its type

`Group` carries its children's types in its own. Build of the same 64 loops:

| root spelling | type string | value size | `build` |
|---|---|---|---|
| struct with an abstract `NamedTuple` field | 4 chars | 8 B | 0.75 s |
| struct with a typed `NamedTuple` field | 11 849 chars | 8 192 B | 9.1 s |
| `Group` | 11 923 chars | 8 712 B | 11.3 s |

The walk's own work is about 1 s in every case. The cost is the declaration
layer specializing on the root's type: `build`'s steps called one by one at
top level cost 0.85 s, `build` itself 11 to 14 s in every whole-function
spelling tried, and the trace puts the difference in one root. Trivial
functions over the same type compile instantly, so it is not the type
system's handling of a big signature; it is the compile of the walk's body
for that type, and §3 shows what removes it.

## 3. The per-type term, and what removes it

The many-instances fixtures hid a term that a real model pays in full. Same
32-loop topology, one plant type against one plant type per instance, at
`-O2` and `-O0`:

| fresh model | `build` | `Simulation` | walks | `init!` | `run!` | total |
|---|---|---|---|---|---|---|
| 32 loops, one type | 11.3 | 2.2 | 3.1 | 2.0 | 2.8 | 21.3 s |
| 16 loops, 16 distinct types | 12.5 | 2.2 | 1.0 | 1.0 | 1.4 | 18.2 s |
| 32 loops, 32 distinct types | 27.2 | 3.7 | 2.4 | 1.9 | 2.9 | 38.1 s |
| the same three at `-O0` | 0.4 / 4.1 / 7.3 | 0.2 / 0.8 / 0.8 | 1.4 / 0.6 / 0.7 | 0.1 | 0.2 | 2.3 / 5.7 / 9.1 s |

Each distinct type costs about 0.5 s in `build` and 0.05 s in `Simulation`
at `-O2`, about 0.15 s in all at `-O0`. Walks, `init!` and `run!` do not
grow with type count, because the unrolled walk already inlines every entry
whether or not its type repeats. In this fixture each distinct plant also
makes a distinct loop assembly type, so "32 types" is 64.

The trace attributes the per-type cost to `_walk!` (6.8 s over 32 instances
for 16 new plants), then the `at_component` closures, `_fanout`,
`leaf_declarations` and `resolve_source`, all specializing on the component
type. Declaration-time code has no performance requirement, so it should
not. Tested on the scratch export, never in the repository:
`@nospecialize(comp)` on ten signatures (`_walk!`, `_children`, `children`,
`classify`, `_check_transparent`, `invoke_declaration`, `classify_tier`,
`check_store_form`, `check_stores`, `check_state_leaves`), then on eleven
more (`leaf_declarations`, `declarations_found`, `_is_container`,
`_walked_faces`, `resolve_source`, `resolve_dest`, `_fanout`,
`declarations`, `_workspace`, `foreign_declarations`, `declared_at`):

| `build` at `-O2` | unpatched | 10 signatures | 21 signatures |
|---|---|---|---|
| 32 loops, one type, `Group` root | 11.3 s | 4.2 s | 1.5 s |
| 16 loops, 16 distinct types | 12.5 s | 5.9 s | 3.6 s |
| 32 loops, 32 distinct types | 27.2 s | 15.8 s | 6.8 s |
| traced compile per new type | 0.78 s | 0.39 s | 0.27 s |

What remains per type after the second round is the probe closures under
`at_component` (64 instances, 1.4 s per 16 types), `resolve_terminal` and
`_declares`. The 32-distinct model's total went from 38 s to 17 s. The
patch is `probes/nospecialize_patch.sh`; the suite was not run on the
patched export.

The `Group` row holds at 32 loops only. Under the patch a `Group` root still
grows with its size, and a root with an abstract children field does not.
Measured 2026-10-01 at the same tip, one fresh root per process, two runs
agreeing within 0.2 s (`probes/rootentry.jl`, variants by
`probes/rootentry_patch.sh`):

| `build` at `-O2`, 21 signatures and | `Group`, 32 loops | `Group`, 64 loops | abstract field, 64 loops |
|---|---|---|---|
| nothing more | 1.54 s | 3.63 s | 0.76 s |
| the root reaching `_walk!` by dynamic dispatch | 1.53 s | 3.60 s | 0.75 s |
| `@nospecializeinfer` on `flatten!` and `_walk!`, `flatten!`'s root unspecialized | 1.29 s | 3.02 s | 0.77 s |
| the same on `build` | 0.86 s | 2.06 s | not run |

How the root reaches the walk makes no difference. Traced at 64 loops
(`probes/roottrace.jl`, `probes/trace_root.py`), the 3.6 s splits in two.
About 1.6 s is `build` and `flatten!` compiled for the root's type, their
closures included; the annotations in the table remove it. The other 1.8 s
is dynamic dispatch on the root's concrete type into code that still
specializes:

| compile for the 64-loop root | seconds |
|---|---|
| `resolve_terminal` | 0.72 |
| `Base.count` over the children, from `_children` | 0.68 |
| the `StructureDraft` constructor, once `build` stops specializing | 0.27 |
| `_declares`, twice | 0.16 |

The `count` compile is Base code reached through an untyped field read, so
no annotation in Cadence removes it.

## 4. The `Dual` activation

§9.7's anchor of about 9 s for an 8-partial `Dual` executor did not
reproduce. Activation plus executor compile plus the first call of the three
interior bodies, fresh topologies, `Dual` machinery warm:

| fresh topology | `Float64` | `ProbeDual`, 1 partial | `Dual`, 8 partials |
|---|---|---|---|
| 64 loops | 6.6 s | 2.8 s | 2.8 s |
| 32 rigid bodies | 2.3 s | 2.4 s | 2.5 s |

The probe step costs nothing once the `Dual` machinery is warm and about
1 s the first time in a process. The `Dual` executor is cheaper than the
nominal one on the loop fixture because it excludes the discrete tier and
the events, so it carries no gated boundary chunks. The partial count made
no difference at these body sizes.

## 5. Alternatives measured

**Optimization level.** `-O0` cuts compile 3 to 5× across every step and
keeps the zero-allocation invariant. On 32 rigid bodies, first simulation
24.6 s at `-O2`, 14.2 s at `-O1`, 4.8 s at `-O0`; the hot bodies run 2.7×
slower at `-O0` (`rhs` 391 ns against 1046 ns) and the whole loop 1.35×
slower, with `@ballocated` at zero throughout. On the trivial loop fixture
the runtime difference is within noise. `--compile=min` makes compile
vanish and runs about 6000× slower; it is not a knob.

**Per-entry representations**, 64 loops, interior bodies:

| walk | ns per entry | allocation | compile on a fresh topology of known types |
|---|---|---|---|
| unrolled tuple, current | 2.3 to 3.3 | 0 | about 0.2 s per body arity |
| one `@opaque` closure per entry, `Vector{OpaqueClosure{Tuple{},Nothing}}` | 2.4 to 2.9 | 0 | 0.000 s |
| `Vector{Any}` with dynamic dispatch | 11 to 18 (28 gated) | 16 B per entry | about 0 |

The opaque-closure walk compiles one body per entry type, so its zero
compile holds for repeated types only; on the 32-distinct model its cold
`sweep_2` costs 1.2 s at `-O2`, about 40 ms per new type per body arity,
which is what the unrolled walk pays too. Its advantage on a fully distinct
model reduces to the topology-independent executor type of §2.1.

**Interpreting or de-inferring** (`--compile=min`, `@compiler_options
infer=false`) and dynamic dispatch over `Vector{Any}` are the "slow backend"
D-086 rejected, and the measurements agree: they lose 5× to 6000× at
runtime for no compile advantage over the opaque-closure walk.

## 6. Roadmap

In order of yield per line changed. Savings are at 64 loops or 32 distinct
types, `-O2`, from the tables above.

1. **`@noinline` on `PhaseBody`'s two call methods** (executor.jl). Removes
   the inlining of the walks into the loop: `run!` 6.8 s → 0.3 s per
   topology, no runtime cost measured. Two lines. §9.7 already states that
   the seams cost nothing; D-194 keeps fusion optional.
2. **`@nospecialize(comp)` through the declaration layer** (assembly.jl,
   build.jl, declare.jl; then the `at_component` probe closures and
   `resolve_terminal`). Per distinct type 0.55 s → about 0.2 s, and a
   32-loop `Group` root 11 s → 1.5 s. No runtime relevance. The suite decides
   whether every diagnostic still names its site.
3. **Phase bodies behind opaque closures, or `FunctionWrapper`s**, so
   `Simulation{T}` carries no executor type and the loop compiles once per
   scalar. With 1, `init!` plus `run!` 8.5 s → 0.1 s per topology, and the
   accessor costs of §2.2 go with them. The cost is a dependence on
   `Base.Experimental.@opaque`, marked experimental, or on the
   FunctionWrappers package. `Executor`'s parameters need reconsidering;
   the store type `S`, which the activation-identity checks key on, stays.
4. **Chunks or entries behind pointers.** A `mutable struct` chunk shrinks
   the executor from 48 KB to 624 B and fixes every accessor on its own.
   One opaque closure per entry goes further: it removes walk codegen for
   repeated types and could replace the unrolled tuple outright, since it
   lost nothing at runtime. This is where §9.7's representation paragraph
   and D-086's rejected list move.
5. **`Group` with an abstract children field.** Partly covered by 2. After
   the 21 signatures a 64-loop `Group` root still builds in 3.6 s against
   0.76 s for an abstract one (§3). The same annotations on `build` and
   `flatten!` bring it to 2.1 s. The rest is `resolve_terminal`, `_declares`
   and Base's `count` over the children, which only this item or a
   `_children` free of generic tuple operations removes. Without 2, this
   item alone takes a 64-loop `Group` build from 11.3 s to the 0.75 s of
   §2.3.
6. **A `PrecompileTools` workload in the package**, building and stepping
   one representative model. Estimated saving about 3 s of the 5 s first
   model, the generic part; the per-topology and per-type terms stay.
7. **Document `-O0` and `-O1` as the iteration session's knob.** No change
   to the package.

Not recommended: a second, slower executor backend. Nothing measured needs
it, and D-086's reasons against dynamic dispatch and interpretation hold.

For a real aircraft with fifty distinct types and a few hundred entries,
today's cost is roughly 28 s of per-type work plus the per-topology terms at
`-O2`. After 1 to 3 the per-topology terms are the walks alone, about 2 s,
and after 2 the per-type work is under 10 s; at `-O0` it is under 8 s with
nothing changed. Under Revise only the edited types pay the per-type term
again.

## 7. What the spec owes

- **§9.7's anchor table** (0.34 s for a 400-entry chunked sweep, 9 s at
  `Dual`, "tens of seconds before mitigation" for an aircraft) is replaced
  by §1 and §4. The walks cost about 2 s at 380 entries; the machinery
  around them costs 10 s; `Dual` costs about what `Float64` does.
- **§9.7's mitigation ladder.** Lazy activation saves 2 to 3 s, not tens.
  A reduced optimizer level for non-nominal activations buys nothing
  measurable. Precompile workloads remain right, for the generic part.
- **D-086's rejected "type-erased call tables".** The stated reasons were
  the specialization count and the loss of cross-entry inlining. Measured,
  one opaque closure per entry matches the unrolled walk at runtime with
  zero allocation, and cross-entry fusion was never relied on. The
  rejection should be narrowed to dynamic dispatch and to per-instance
  specialization, both of which stay rejected.
- **D-162** stands: per-eltype cell stores are what let instances share
  bodies, and every result here rests on that sharing.
- **§7.5** is untouched: the zero-allocation invariant held under every seam
  and at `-O0`.

## 8. Caveats

The component bodies are three operations each; a real `x_derivative` adds
its own inference and LLVM time per type, which no framework change removes
and a lower optimization level or a component package's precompile workload
reduces. The rigid-body fixture is the only one with real arithmetic. All
numbers are from one machine and one Julia version. The `@nospecialize`
patch ran the probes only, not the suite. The mechanism behind §2.3 is
identified as the walk's body compiling per root type and removed by the
patch, but the reason a static call to `flatten!` costs ten times what a
dynamic one does was not isolated further.
