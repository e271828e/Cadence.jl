### 9.4 Activations: executable sets, laziness, caching

By default, the build types the model only at the scalar type `Float64`.
Linearization and gradient trim need the same model typed at a scalar type
other than `Float64`, namely a `Dual`. An [activation](#g-activation) supplies
that typing. It is the build's typed products at a given scalar type. This
section covers four topics: what an activation re-runs, which functions an
activation [probes](#g-probe), when an activation runs, and what the `Build`
caches.

#### The activation step

**For a new scalar type, only the activation step re-runs**
([D-259][d-259]). An activation at scalar type `T` re-runs the activation step
with a different scalar. It redoes five things:

1. It re-types producer-fed [cells](#g-cell) by walking the producing
   [component](#g-component)'s output declaration at `T` ([§8.2][s8-2]). A
   continuous producer's output declaration follows the activation scalar at
   every [unpinned](#g-walked) leaf. A discrete producer's output declaration
   pins. It does not follow the activation scalar.
2. It re-types [root-input](#g-root-input) cells by walking the consuming
   `u_types` entry at `T`. [§8.2][s8-2] reads that entry
   permissively. An unpinned `u_types` entry follows the activation's scalar.
   A `Pinned` entry stays frozen across activations.
3. The leaf walk re-derives the state type from `x_init`. The table
   [buffers](#g-buffer) and the state buffers are laid out again.
4. It invokes the [workspace](#g-workspace) allocators again, and it invokes a
   [continuous component](#g-continuous-component)'s allocator at `T`
   ([D-263][d-263]). It invokes a discrete component's allocator at `Float64`,
   not at `T` ([D-263][d-263]). The activation does not introduce these
   allocators. They exist before it. Their first invocation happens before
   the nominal evaluation's probes ([§9.1][s9-1]/[§9.3][s9-3]). A continuous
   component's scratch carries the activation's scalar type ([§7.3][s7-3]).
5. The probe chain runs again.

**Across activations, the [execution order](#g-execution-order) never changes
and no name list changes** ([D-253][d-253]). [`Structure`](#g-structure) is
the product of the structure step. [`Outputs`](#g-outputs) is the product of
the nominal evaluation. Neither depends on the scalar type `T`, by
construction. This is why the execution order and the name lists do not
change across activations.

#### Probe sets

**Each activation probes exactly the set of functions that activation can
execute** ([D-052][d-052]).

Linearization and gradient trim use a `Dual` activation. A `Dual` activation
evaluates the model at a frozen instant. Its discrete stages are gated off and
hold `Float64` values. This is the frozen-constant semantics of [§8.2][s8-2].
Its [guards](#g-guard) and handlers never run, because event localization runs
as `Float64` [sweeps](#g-sweep) by design ([§10.4][s10-4]). Only the continuous
output stages (`y_state`/`y_direct`) and `x_deriv` ever see a `Dual`. So only
those are probed at `Dual`. Probing the discrete stages, `s_update`, or the
guards at `Dual` would check code against a number type that code cannot
receive.

The probe-set rule has no special cases. The tracer activation of [§5.6][s5-6] follows
it identically. The term "tracer activation" names the global set-tracer
([D-012][d-012]). It is a whole-model run at the tracer scalar. It is an
activation like any other. The other tracer variant is the cycle classifier
([§5.6][s5-6], [D-012][d-012]). The cycle classifier traces each member of a
cycle locally. It needs no execution order. It runs in the nominal
evaluation's failure path. It is not an activation at all.

#### Laziness and the CI check

**Non-nominal activations run at first request, not at build**
([D-052][d-052]). The dominant cost of a non-nominal activation is compiling
the continuous chain a second time, at `Dual`. Non-nominal activations are
lazy because that cost is pure waste for interactive fly-around use.

Laziness has a price, and the spec states it openly. The price is that a
successful `build` does not certify that the model is linearizable. A pinned
`Float64` ([§7.2][s7-2]) can appear in two places. It may hide in a constructor. Or a `Float64` may be declared
`Pinned` at a leaf that really participates. That is the misplaced pin of
[§8.2][s8-2]. Either kind lurks undetected until the first `Dual` activation.
At that activation the probe fails and names the offending constructor or
leaf.

Instead, the repository's test suite makes linearizability an
invariant, held by policy rather than by advice. **Every component gets a
`Dual` activation built in CI** ([D-280][d-280]). An opt-in exhaustive mode
builds the `Dual` activation for every component. It is invoked as follows:

```julia
build(world; activations = (Float64, ProbeDual))
```

This call runs the exhaustive set. The exhaustive mode catches both
genericity violations and misplaced pins at PR time. Its cost is one
activation per component. **The `activations` keyword of `build` is the whole
entry point for this check** ([D-275][d-275]). **No separate check function
exists** ([D-275][d-275]).

The same `activations` keyword is also recommended for the parallel-sweep
idiom ([§11.1][s11-1]). For a parallel sweep, pre-materialize the activations
the sweep will need. With them pre-materialized, the shared `Build` is a fully
immutable artifact, with no synchronization on any path.

The call above names `ProbeDual`. **[`ProbeDual`](#g-probedual) is the
framework's public canonical probe scalar** ([D-099][d-099]). It is defined
as follows:

```julia
const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}
```

`ProbeDual` exists because an activation is keyed by a concrete scalar type.
The bare `Dual` is a `UnionAll`. So the bare `Dual` cannot key an activation.
It cannot be walked to, and it cannot answer `zero(T)`. The width of
`ProbeDual` is arbitrary. CI pins genericity, not any particular Jacobian, so
one canonical `ProbeDual` width suffices, even though [§14.10][s14-10] chunks
at whatever widths it needs.

#### The activation cache

**The activation cache lives on the `Build`** ([D-135][d-135]). It lives
there because an activation is a pure function of the build and the concrete
scalar type. **The activation cache holds only immutable compiled artifacts**
([D-135][d-135]). It is one activation dictionary, keyed by concrete scalar
type. Each entry holds layouts, compiled plans and a validated flag. An entry
is immutable once constructed, so it is freely shareable. **The nominal
`Float64` entry is one key in the activation dictionary, like any other key**
([D-253][d-253]). **Whether an activation is cached never changes a result**
([D-052][d-052]).

The type `Dual{Tag,V,N}` carries the partial count. So a different seeding
width is a different scalar type. It gets a separate activation-cache entry
and a separate Julia compile.

**Every buffer set has exactly one owner** ([D-282][d-282]). The `Simulation`
owns its nominal activation's buffers. `Simulation` construction materializes
them from the cached layouts. The loop's zero-allocation stepping runs on
these buffers. Every service invocation owns the scratch set it instantiates
from the same cached layouts. [§14.8][s14-8] states this rule for `trim!`. It
is the general rule, not one local to trim. Because every buffer set has one
owner, buffers are never cached.

Julia itself caches compiled code, process-wide. The framework's activation
cache saves the expensive part. That part is probe re-runs, layout
construction, and Julia's compilation of the `Dual` chain. These savings
amortize in loops that reuse an activation. In the envelope-grid
gain-schedule case, hundreds of trim-then-linearize points pay the cached
costs once. The per-point allocation of a working store set does not
amortize. It is O(model size), and it is trivial against the solve it feeds.
The zero-allocation invariant ([§7.5][s7-5]) covers only the stepping loop.
The services were always allocation-tolerant. Nothing numerical is ever
cached.

**Lazy materialization of activations is torn-state-free**
([D-281][d-281]). Concurrent first requests for the same activation must
never expose partially populated cache state. Torn state is excluded by
contract, not by luck. The mechanism that excludes it is unspecified. A guard
around cache insertion suffices. Its cost is paid at service time and never
on the hot path. An activation is a pure function of build and scalar. So
the worst benign race on concurrent first requests is duplicated work.
