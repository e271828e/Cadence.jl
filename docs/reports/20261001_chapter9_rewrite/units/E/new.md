### 9.7 The compiled executor

The [execution order](#g-execution-order) exists in two representations at two
lifecycle stages. On [`Outputs`](#g-outputs) (the nominal evaluation's product,
the port classes and the execution order) it is plain printable data
([§9.2][s9-2]), namely paths, stage names and order. That data is the authoring
and diagnostic form. The [executor](#g-executor) compiles from that order
([D-253][d-253]). This section covers the other form, the one the loop runs.

#### The execution form

At `Simulation` construction, and per [activation](#g-activation) (the
build's typed products at a given scalar type), that data is compiled into the
execution form. **The execution form is a concretely-typed tuple of entries**
over statically typed [cell](#g-cell) storage, traversed by a
compile-time-unrolled walk ([D-086][d-086]). This is a forced move, not a
preference. The zero-allocation invariant ([§7.5][s7-5]), the fold-away
conformance test ([§9.5][s9-5]) and the zero runtime graph logic
([§5.1][s5-1]) are reachable only under full specialization.

An entry carries what selects code in type parameters, namely
[component](#g-component) type and stage. It carries what is plain data in
fields, namely [tick](#g-tick) divisor and [phase](#g-phase), the `Δt` of the
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives), and layout offsets. Gating compiles to
`(tick − Φ) % D == 0` inside the specialized *[boundary](#g-boundary)* body,
and the interior bodies hold no discrete entries to test ([§10.5][s10-5]).

#### Cell storage

**Cells are stored per element type**, not per cell ([D-162][d-162]). The
[signal table](#g-signal-table) is one contiguous block per element type, the
construction pointed at signals rather than state ([§7.1][s7-1]). A cell
address is a build-time offset into it. The offset is carried in an entry
*field*, with the [port](#g-port) type as the address's own parameter.
Gathers reconstruct and scatters flatten through the same leaf walk, so the
closed vocabulary earns its keep twice. This is the entry rule above paying
off. Two instances of one component type then differ only in field values,
share an entry type, and compile to *one* body.
By contrast, a store enumerating every cell in its own type, addressed by
index in the type domain, compiles one body per instance. It also grows the
store type with the model. The choice was measured rather than argued
([D-162][d-162], `prototypes/cellstore_bench`).

#### Phase bodies, arities and seams

**[Phase bodies](#g-measurement-seam) are the outer decomposition**, and they
are semantically forced ([D-086][d-086]). The blocks are as follows.

- The [boundary sweep](#g-sweep)'s stage-1 block, both tiers' `y_state`
  entries alike, is order-free by definition, because the
  no-[feedthrough](#g-feedthrough) stage reads no `u`.
- The stage-2 block gates in the [due](#g-due) discrete stages, those whose
  components this boundary admits by their compiled `(D, Φ)` pair. It is the
  only topologically ordered one.
- The `x_deriv` block is `rhs`, the [RHS](#g-flow) body the stepper calls per
  stage evaluation. The `s_update` block is `ticks`. Both are order-free with
  disjoint writes.
- [Guards](#g-guard) and handlers are their own small callables inside the
  [§10.6][s10-6] iteration.

**Each sweep block compiles in two arities** off one entry list
([D-147][d-147]). The arities follow the interior/boundary split that
[§10.5][s10-5] fixes.

- The zero-arg `sweep_1()`/`sweep_2()` are the interior variants, over
  continuous entries only. That is what makes `@ballocated(sweep_2()) == 0` a
  well-defined measurement *of the interior path*, rather than of whichever
  tick phase the simulation happens to be sitting in.
- The `sweep_1(tick)`/`sweep_2(tick)` forms are the boundary variants. They
  gate their discrete entries by `(tick − Φ) % D` against the passed tick
  index, symmetric with `ticks(tick)`.

`rhs` takes no index. One gate serves all three tick-sensitive blocks,
because due-ness is per component, per boundary, never per stage. **At a
localized event time `t*` ([§10.4][s10-4]), the empty due set is arity
selection**, not an index trick ([D-147][d-147], [D-185][d-185]). The `t*`
iteration therefore runs the zero-arg arities, whose compiled bodies contain
no discrete entries ([§10.5][s10-5]).

**These bodies communicate only through the stores and the table**
([D-194][d-194]). No value crosses a [seam](#g-seam), whether between passes,
between the blocks of one pass, or between [chunks](#g-chunking). The seams
therefore cost nothing, and the executor's decomposition stays free. Fusing a
step's sweep with its `x_deriv` block, or an event round's sweep with its guards
and fired handlers ([§10.6][s10-6]), is an optimization it may take or decline.

Two options this structure opens for free are recorded, not committed.

- The first is deterministic parallel evaluation of the order-free blocks.
  They have disjoint writes and no floating-point reductions to reorder,
  because [§6.2][s6-2] made every sum an ordered junction entry.
- The second is finer recompilation granularity. Editing a discrete
  component invalidates the boundary body, not the RHS body. That is literal
  under the two-arity split, since discrete entries exist only in the
  boundary variants.

#### Views and construction

**[Views](#g-view) are spelled rebuild-per-call** ([D-086][d-086]). Every entry
constructs its bundle at its own position. There is no framework-maintained
hoisting and therefore no cache-invalidation obligation. Hoisting belongs to the
code generator. Common-subexpression elimination (CSE) merges repeated loads
exactly where no intervening store invalidates them. That is precisely
[§7.1][s7-1]'s buffer-unchanged-within-a-sweep rule. The sweep-varying bundle
fields (`u`, `y_x`/`y_s`) are per-call by topological necessity either way
([§7.1][s7-1]).

**Construction is type-opaque**, and only the executor
specializes ([D-086][d-086]). Entry tuples are built from untyped buffers
and splatted once. Generic tuple utilities (range indexing, long `ntuple`
closures, naive recursion) are inference traps at the entry list's length,
since a 400-entry heterogeneous tuple can send generic `getindex` inference
into combinatorial collapse. The compiled tuple's type therefore has exactly
one consumer, the unrolled walk.

#### Compile cost

[Chunking](#g-chunking) bounds the compile cost. Within a large block the tuple splits
into chunks behind non-inlined but statically-typed function barriers.
Inside a chunk everything the design relies on survives: static dispatch,
inlining, view SROA, check folding, zero allocation. At the seams only
cross-entry fusion is lost, which a table-mediated signal flow barely had.
Chunk size is the implementation's *only* representation freedom (fully
fused and chunk-of-one are its endpoints), and it converts the compile cost
from superlinear in the largest body to linear in entry count.

Measured anchors, taken 2026-07 over synthetic ~15-op bodies on Apple
Silicon, with the last two rows extrapolated to a full aircraft model of
roughly 200–400 entries with larger bodies. Those two rows
assume the chunked mode, the one whose cost is linear in entry count:

| case | activation | compile time |
|---|---|---|
| 400-entry sweep, fused | `Float64` | ~0.8 s |
| 400-entry sweep, chunked | `Float64` | ~0.34 s |
| 400-entry sweep, chunked | 8-partial `Dual` | ~9 s |
| Aircraft-scale model, extrapolated | nominal | seconds |
| Aircraft-scale model, extrapolated | `Dual` | tens of seconds, before mitigation |

The fused curve is visibly superlinear. An 8-partial `Dual` activation
multiplies instruction count ~20×, and its chunked curve is linear,
instruction-bound rather than structure-bound. Re-measurement on a real
model of that scale is pending (`pending.md`).

The mitigation ladder, in order. Activations are lazy ([§9.4][s9-4]), so a
session that never linearizes never compiles `Dual`. Non-nominal activations
may compile at reduced optimizer level, because their sweeps run inside
service loops where microseconds are irrelevant, a one-line per-module
policy. And activations bake into package images via ordinary precompile
workloads. An aircraft package exercising build-plus-one-sweep per
activation turns TTFX from a session tax into a CI artifact.

#### The measurement seam

**The phase bodies are the [§7.5][s7-5] measurement seam**
([D-116][d-116]). The accessor
below returns the compiled bodies of the nominal activation as named
callables bound over the simulation's own buffers.

```julia
phase_bodies(sim)
```

It returns four blocks.

- `rhs`, the `x_deriv` block.
- `sweep_1`, in both arities.
- `sweep_2`, in both arities.
- `ticks`, which takes the tick index its entries gate on.

Returned with them are the per-event guards and handlers and the
per-component `x_projection` callables, keyed by the model's own roster.

**The four-body roster is fixed and total** ([D-156][d-156]). The accessor
returns all of it always, whatever the model happens to declare. A model with
no discrete components, no events or no continuous state at all still gets
every body. The empty ones are legal, compile to no-ops, and their
`@ballocated` assertion passes vacuously. That is the point, because
consumers then iterate the roster uniformly, with no existence checks and no
per-model branching in the measurement code.

The seam is diagnostic only ([§13.5][s13-5]), and it makes one promise.
**These are the bodies the loop runs**, not re-derivations ([D-116][d-116]).
That is what makes the measurement honest, and why each callable carries the
real in-loop argument types by construction. A hand-built standalone test
cannot reproduce those types. [D-116][d-116] records why per-component tests
cannot discharge the invariant.

**CI is warm-then-assert over the roster** ([D-116][d-116]). One call
compiles, then CI asserts the following.

```julia
@ballocated(body()) == 0
```

It asserts at per-body granularity, each sweep arity in its own right
([D-147][d-147]), with the interior call bare and the boundary call at a due
index. So a documented [§7.5][s7-5] tolerance loosens exactly one assertion.

**Publication is not a phase body** ([D-116][d-116]). That is the
[§7.5][s7-5] carve-out made structural. What the accessor exposes is exactly
what the invariant claims is zero. Invoking bodies in isolation mutates the
simulation's buffers outside any [frame](#g-frame) sequence (a tick entry
advances discrete state with no clock advance). It leaves them valid but
off-trajectory. A session that wants to continue meaningfully re-runs
`init!`.
