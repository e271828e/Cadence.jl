### 9.4 Activations: executable sets, laziness, caching

By default, the build types the model only at `Float64`. Linearization and
gradient trim need the same model at another scalar type, a `Dual`. An
[activation](#g-activation) (the build's typed products at a given scalar
type) supplies that typing. This section states what an activation re-runs,
which functions it probes, when it runs, and what the `Build` caches.

**Only the activation step re-runs for a new scalar** ([D-259][d-259]). An
activation at `T` re-runs it with a different scalar and redoes five things:

- Producer-fed [cells](#g-cell) are re-typed by *walking* the producing
  [component](#g-component)'s output declaration at `T` ([§8.2][s8-2]). A
  continuous producer's declaration follows the scalar at every unpinned leaf.
  A discrete producer's declaration is read once and pins.
- [Root-input](#g-root-input) cells are re-typed by *walking* the consuming
  `u_types` entry at `T`. [§8.2][s8-2] reads that entry permissively. An
  unpinned entry follows the activation, and a `Pinned` entry stays frozen.
- The state type derived from `x_init` is re-derived by the leaf walk
  ([§8.2][s8-2]). The table and the flat `x` [buffer](#g-buffer) are laid out
  again.
- [Workspace](#g-workspace) allocators are invoked again, a continuous
  component's at `T` and a discrete component's at `Float64`
  ([D-263][d-263]). The activation does not introduce them. Their first
  invocation precedes the nominal evaluation's [probes](#g-probe)
  ([§9.3][s9-3]). A
  [continuous component](#g-continuous-component)'s scratch carries the
  activation's scalar ([§7.3][s7-3]).
- The probe chain runs again.

No [execution order](#g-execution-order) and no name list changes across
activations ([D-253][d-253]). [`Structure`](#g-structure) is the structure
step's product, and [`Outputs`](#g-outputs) is the nominal evaluation's.
Neither depends on `T`, by construction.

**Each activation probes exactly the set of functions it can execute**
([D-052][d-052]). A `Dual` activation, as linearization and gradient trim use,
evaluates the model at a frozen instant.

- Discrete stages are gated off and hold `Float64` values. This is the
  frozen-constant semantics of [§8.2][s8-2].
- [Guards](#g-guard) and handlers never run, because event localization runs
  as `Float64` [sweeps](#g-sweep) by design ([§10.4][s10-4]).
- Only the continuous output stages (`y_state`/`y_direct`) and `x_deriv` ever
  see a `Dual`. So only they are probed at it.

Probing the discrete stages, `s_update` or the guards at `Dual` would check
code against a number type it cannot receive.

The rule has no special cases. The [§5.6][s5-6] tracer activation follows it
identically. "Tracer activation" names the *global* set-tracer
([D-012][d-012]). It is a whole-model run at the tracer scalar, an activation
like any other. The cycle classifier ([§5.6][s5-6]) is the other tracer
variant ([D-012][d-012]). It traces each member of a cycle locally and needs
no execution order. It runs in the nominal evaluation's failure path and is
not an activation at all.

**Non-nominal activations run at first request**, not at build
([D-052][d-052]). Their dominant cost is compiling the continuous chain a
second time, at `Dual`, and for interactive use, such as flying the model by
hand, that cost is pure waste.

Laziness has a price, and the spec states it openly. A successful `build` does
not certify that the model is linearizable. A [pinned](#g-walked) `Float64`
([§7.2][s7-2]) can appear in two places. It may hide in a constructor. Or it
may be declared `Pinned` at a leaf that really participates, which is the
misplaced pin of [§8.2][s8-2]. Either one lurks until the first `Dual`
activation. The probe then fails and names the offending constructor or leaf.

Instead, the repository's test suite makes linearizability an invariant, held
by policy rather than advice. **Every component gets a `Dual` activation built
in CI** ([D-280][d-280]). An opt-in exhaustive mode does it:

```julia
build(world; activations = (Float64, ProbeDual))
```

This call runs the exhaustive set. It catches both genericity violations and
misplaced pins at PR time, at the cost of one activation per component. **The
keyword is the whole entry point**, and no separate check function exists
([D-275][d-275]).

The same keyword is also recommended for the parallel-sweep idiom
([§11.1][s11-1]). Pre-materialize the activations the sweep will need. The
shared `Build` is then a fully immutable artifact, with no synchronization on
any path.

**[`ProbeDual`](#g-probedual) is the framework's public canonical probe
scalar** ([D-099][d-099]).

```julia
const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}
```

It exists because an activation is keyed by a *concrete* scalar type. The bare
`Dual` is a `UnionAll`. It cannot key an activation, be walked
to, or answer `zero(T)`. The width of `ProbeDual` is arbitrary. CI pins
genericity, not any particular Jacobian. So one canonical width suffices, even
though [§14.10][s14-10] chunks at whatever widths it needs.

**The activation cache lives on the `Build` and holds only immutable compiled
artifacts** ([D-135][d-135]). It lives there because an activation is a pure
function of the build and the concrete scalar type. The cache is one
activation dictionary, keyed by concrete scalar type. Each entry holds
layouts, compiled plans and a validated flag. An entry is immutable once
constructed, and so it is freely shareable. The nominal `Float64` entry is one
key in the activation dictionary like any other ([D-253][d-253]). **Whether an
activation is cached never changes a result** ([D-052][d-052]).

**Every buffer set has exactly one owner** ([D-282][d-282]).

- The `Simulation` owns its nominal activation's buffers. They are
  materialized from the cached layouts at construction. The loop's
  zero-allocation stepping runs on them.
- Every service invocation owns the scratch set it instantiates from those
  same layouts. [§14.8][s14-8] states this for `trim!`. It is the general rule,
  not one local to trim.

So buffers are never cached.

Julia itself caches compiled code, process-wide. The framework cache saves the
expensive part, namely probe re-runs, layout construction, and Julia's
compilation of the `Dual` chain. These savings amortize in loops that reuse an
activation. One such loop computes a gain schedule over a grid of flight
conditions, where hundreds of trim-then-linearize points pay those costs once.

The per-point allocation of a working store set does not amortize. It is
O(model size), and trivial against the solve it feeds. The zero-allocation
invariant ([§7.5][s7-5]) covers only the stepping loop, and the services were
always allocation-tolerant. Nothing numerical is ever cached.

`Dual{Tag,V,N}` carries the partial count. A different seeding width is
therefore a different scalar type. It gets a separate entry and a separate
Julia compile.

**Lazy materialization is torn-state-free** ([D-281][d-281]). Concurrent first
requests for the same activation must never expose partially populated cache
state. Torn state is excluded by contract, not by luck. The mechanism is
unspecified. A guard around insertion suffices, paid at service time and never
on the hot path. An activation is a pure function of build and scalar, so the
worst benign race is duplicated work.
