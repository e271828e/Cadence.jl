### 9.4 Activations: executable sets, laziness, caching

An **[activation](#g-activation) at `T`** re-runs the activation step with a different scalar:

- producer-fed [cells](#g-cell) are re-typed by *walking* the producing [component](#g-component)'s
  output declaration at `T` ([§8.2][s8-2]). A continuous producer's declaration
  follows the scalar at every unpinned leaf, and a discrete producer's
  declaration pins;
- [root-input](#g-root-input) cells are re-typed by *walking* the consuming `u_types`
  entry at `T`, which [§8.2][s8-2] reads permissively. An unpinned entry follows
  the activation, and a `Pinned` entry stays frozen;
- the state type is re-derived by the walk over `x_init`'s, with table and
  state [buffers](#g-buffer) re-laid-out;
- [workspace](#g-workspace) allocators are re-invoked at `T`, not introduced. The first
  invocation precedes the nominal evaluation's [probes](#g-probe) ([§9.1][s9-1]/[§9.3][s9-3]), and a
  [continuous component](#g-continuous-component)'s scratch carries the activation's scalar ([§7.3][s7-3]);
- the probe chain is re-run.

[`Structure`](#g-structure), the structure step's product, and
[`Outputs`](#g-outputs), the nominal evaluation's, are `T`-independent by construction,
so no [execution order](#g-execution-order) and no name list changes across
activations
([D-253][d-253]).

**Each activation probes exactly the function set it can execute.** A `Dual`
activation (linearization, gradient trim) evaluates the model at a frozen
instant. Discrete stages are gated off holding `Float64` values (the [§8.2][s8-2]
frozen-constant semantics), and [guards](#g-guard) and handlers never run, because
event localization is `Float64` [sweeps](#g-sweep) by design ([§10.4][s10-4]). Only the
continuous output stages (`y_state`/`y_direct`) and
`x_deriv` ever see a `Dual`, so only they are probed. Probing the
discrete stages, `s_update`, or guards at `Dual` would check code against
a number type it cannot receive. It is one rule with no special cases, and the
[§5.6][s5-6] tracer activation follows it identically. "Tracer activation" names the
*global* set-tracer ([D-012][d-012]), a whole-model run at the tracer scalar, an activation
like any other. The cycle classifier ([§5.6][s5-6]) is the other variant ([D-012][d-012]). It is
the order-free per-member local trace, which runs in the nominal evaluation's
failure path and is not an activation at all.

**Lazy, with an opt-in exhaustive mode.** Non-nominal activations run at first
request, not at build. The dominant cost is compiling the continuous chain a
second time at `Dual`, pure waste for interactive fly-around use. The price is
stated openly. `build` succeeding does **not** certify the model
linearizable. A [pinned](#g-walked) `Float64` ([§7.2][s7-2]), whether hidden in a constructor
or declared `Pinned` at a leaf that really participates (the misplaced pin,
[§8.2][s8-2]), lurks until the first `Dual` activation
detonates it at the probe, naming the offending constructor or leaf. The
repository's test suite pins the invariant instead, as policy rather than
advice ([D-166][d-166]). **Every component gets a `Dual` activation built in CI.**
`build(world; activations = (Float64, ProbeDual))` runs the exhaustive set,
catching both genericity violations and misplaced pins at PR time, at the
cost of an activation per component. The keyword is the whole entry point,
and no separate check function exists ([D-275][d-275]). The same
keyword is also recommended for the parallel-sweep idiom ([§11.1][s11-1]).
Pre-materialize the activations the sweep will need, and the shared `Build`
is a fully immutable artifact, with no synchronization on any path.
[`ProbeDual`](#g-probedual) is the framework's public canonical probe scalar,
`const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}`. It exists because
an activation is keyed by a *concrete* scalar type, and the bare `Dual`
`UnionAll` cannot key one, be [walked](#g-walked) to, or answer `zero(T)`. Its width is
arbitrary. What CI pins is genericity, not any particular Jacobian, so one
canonical width suffices even though [§14.10][s14-10] chunks at whatever widths it
needs.

**Caching is implementation detail, not semantics.** An activation is a pure
function of the build and the concrete scalar type, so the activation
dictionary is the `Build`'s, and the nominal `Float64` entry is one key in it
like any other ([D-253][d-253]). Each entry holds layouts, compiled plans and a
validated flag keyed by that type, immutable once constructed and hence freely
shareable. **Buffers
are never cached**, because every buffer set has exactly one owner. The
`Simulation` owns its nominal activation's buffers, materialized from the
cached layouts at construction, which is what the loop's zero-allocation
stepping runs on. Every service invocation owns the scratch set it
instantiates from those same layouts. [§14.8][s14-8] states this for `trim!`, and
it is the general rule, not a trim-local one. Compiled code is cached by
Julia itself, process-wide. What the framework cache saves is the expensive
part, namely probe re-runs, layout construction, and Julia's compilation of
the `Dual` chain. That is what actually amortizes in activation-reusing
loops, such as the envelope-grid gain-schedule case, where hundreds of
trim-then-linearize points pay those costs once. What does not amortize is
the per-point allocation of a working store set, which is O(model size) and
trivial against the solve it feeds. The zero-allocation invariant ([§7.5][s7-5])
is scoped to the stepping loop, and the services were always
allocation-tolerant. Nothing numerical is ever cached. Note that
`Dual{Tag,V,N}` carries the partial count, so a different seeding width is a
different scalar type, hence a separate entry and a separate Julia compile.
**Lazy materialization is torn-state-free**, normatively. Concurrent first
requests for the same activation must never expose partially populated cache
state. The mechanism is unspecified, and a guard around insertion suffices,
paid at service time and never on the hot path. Since an activation is a
pure function of build and scalar, the worst benign race is duplicated work.
Torn state is excluded by contract, not by luck.
