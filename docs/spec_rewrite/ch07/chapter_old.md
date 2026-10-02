## 7. State and data representation

### 7.1 Continuous state: structured immutable, flat backing

Each [continuous component](#g-continuous-component) declares its state by value (`x_init`, [§8.2][s8-2]). The
declaration is a NamedTuple whose leaves are drawn from a **deliberately closed
vocabulary, plain real scalars and `SArray`s (static vectors and matrices) of a
common eltype `T`**, and nothing else. `Int`s, enums and `Bool`s belong in
modes. Domain wrapper types (`RQuat`, `Ranged`) are not state leaves. An
attitude state is an `SVector{4,T}`, cast where rotation semantics are wanted,
as described below. The declaration is flat. Each field is one leaf, never a
`NamedTuple` of leaves. The condition algebra and the readers address a field
as one leaf ([§14.3][s14-3], [§14.4][s14-4]), and structure comes from the component tree, not
from the value ([D-094][d-094]). The framework does three things with the declaration.

- It computes a **flat layout** at build time, with compile-time offsets over
  one contiguous `Vector{T}` [buffer](#g-buffer) it owns.
- It **reconstructs** the typed immutable state value for a [component](#g-component) at each
  evaluation and passes it to every function receiving state views, under the
  argument rule of [§5.2][s5-2]. The reconstruction is field loads at known offsets,
  register-level, at zero cost.
- It receives immutable results back. Derivative functions return an `Ẋ`-typed
  value, which is scatter-stored into the flat `ẋ` buffer. Event handlers and
  [projection](#g-projection) return a new `X`, which is written back, with projection at the two
  positions in the [execution order](#g-execution-order) of [§5.3][s5-3].

**What `Ẋ` is.** With the leaf vocabulary closed, the answer takes one line. `Ẋ`
has exactly `X`'s shape at the [activation](#g-activation) scalar. A scalar leaf's derivative is
a `T`, and an `SArray` leaf's is the same `SArray` at `T`. This is the
vocabulary rule paying rent. An invariant-carrying leaf like a unit quaternion
has a derivative off its own type, and `Ẋ` would need a separate derivation.
Here the attitude leaf is an `SVector{4,T}` and so is its rate. The conformance
predicate is structural. *Each field of `x_deriv`'s return scatters
into its field's block at `T`* ([§9.5][s9-5] states the check). That makes derivative
completeness a property of the layout rather than of author discipline. There is
deliberately **no `derivative_type` hook** ([D-190][d-190]).

**The buffer is authoritative, and typed values are ephemeral reconstructions.**
Nobody outside the framework ever holds a mutable reference to state.
"Ephemeral" is literal. An isbits view materializes in the caller's frame for
exactly the duration of the call, and has no existence between calls. Where it
materializes, in registers or on the spilled stack, is the compiler's business.
Re-materializing is the same loads, and it is value-identical because the value
is immutable and the buffer is unchanged within a [sweep](#g-sweep).

Whether repeated reads within a sweep re-materialize or reuse the loads is
codegen freedom, in the literal sense that the freedom is the code generator's.
The [executor](#g-executor) (the compiled form of the stage execution order) is spelled
rebuild-per-call, and hoisting a repeated read is the code generator's CSE. The
legality condition of that CSE is exactly the buffer-unchanged-within-a-sweep
rule ([§9.7][s9-7]).

The complementary rule is **[one home per datum](#g-one-home-per-datum)** ([§5.2][s5-2]). The buffer holds `x`,
the stores hold `s` and `m`, and the table holds produced signals. No store ever
mirrors another. In particular there are no state [cells](#g-cell) in the table beyond
the declared [ports](#g-port) a component returns from `y_state` ([§5.3][s5-3]),
which are interface, not transport.

**The vocabulary is closed because views must materialize without running
anyone's invariants.** Scalars and `SArray`s have invariant-free constructors.
`SVector`'s stores its tuple, `NamedTuple` construction runs no user code, and
nothing normalizes or clamps. Building a view through ordinary public
construction is therefore bit-faithful automatically. `reconstruct(flatten(x))
== x` holds identically, with no constructor bypass, no `reinterpret`, and no
reliance on a custom struct's memory layout mirroring the buffer's.
Invariant-carrying leaves are closed ([D-094][d-094]). Domain semantics are instead an
**explicit, invariant-free cast at the point of use**, the conversion today's
`f_ode!` code performs on its raw views. Invariants live where the design
already put them, in `x_projection` at [boundaries](#g-boundary) and in writers. Handlers
build their returned values through ordinary constructors, and the condition
apply converts authored values through ordinary `convert` methods ([§14.3][s14-3]).
Constructors run on the write paths, never on views.

Against today's flat-`Vector` + `ComponentArrays`-views pattern, this buys five
things.

- There are no aliased mutable views, where who writes what is a matter of
  convention.
- Derivative completeness is **structural**. The returned `Ẋ` has every field by
  construction, so a forgotten `ẋ` entry is impossible rather than silently
  stale.
- State fields arrive as the declared scalars and `SArray`s, immutable. The
  domain wrapper, where wanted, is one explicit invariant-free cast (`RQuat(x.q,
  normalization = false)`). That is the conversion the mutable-views pattern
  performed implicitly, now visible and chosen.
- The flat vector still exists. Integrator compatibility (OrdinaryDiffEq or
  custom), trim solvers, HDF5 logging and linearization all get their arrays.
- The hand-written per-aircraft state-space mapping layer
  (`get_x_ss`/`assign_x_ss!`/`get_u_ss`/...) is deleted, replaced by the
  framework's canonical layout.

### 7.2 Numeric genericity (eltype)

The state [buffer](#g-buffer), the pack/unpack machinery, and the entire **continuous
evaluation path** are generic over `T <: Real`. This one design property serves
four consumers.

1. Exact Jacobians for **linearization**, with ForwardDiff duals through the
   whole model, replacing finite differences.
2. Derivatives for **trim** solvers.
3. The **[feedthrough tracer](#g-feedthrough-tracer)** (the set-propagation instrument classifying a
   rejected cycle, [§5.6][s5-6]).
4. A trivially checkable **CI invariant**. One evaluation [sweep](#g-sweep) with `T = Dual`
   fails loudly (`MethodError`/`InexactError` at the offending line) on any
   Float64-pinning.

For consumer 1, the *discrete* side's exemption is not a limitation but the
exact answer. A frozen discrete [cell](#g-cell) is a constant with zero partials, which is
what "linearize the continuous dynamics with the discrete state held" means.
`frozen_discrete_walkthrough.md` works the chain through in detail.

The declaration layer keeps this scoping legible without putting it in the
author's way. Every declaration is written at nominal `Float64`, and one walk
retypes it per [activation](#g-activation) ([§8.2][s8-2]). On the continuous tier a `Float64`
leaf follows the activation scalar, in a contract and in the `x_init`-derived
state type alike, and a contract leaf wrapped as `Pinned{P}` is deliberately
[pinned](#g-walked). Participation is therefore authored per leaf, by the absence or
presence of the marker. The discrete side stays plain and pins wholesale.
Nothing anywhere comes from inference through user code. Safety of the
substitution rests on the embedding guarantee stated in [§9.5][s9-5].

Scoping, meaning what actually needs genericity, covers roughly half the type
inventory and has three tiers ([D-011][d-011]).

- **[Walked](#g-walked)**, the payload and value types constructed during evaluation (about
  25 structs). These are the quaternion/attitude family, `Wrench`,
  `FrameTransform`, `MassProperties`, `KinData`, `AirData`, geodesy value types,
  `TerrainData` and continuous output structs. `Quaternion` becomes
  `Quaternion{N,T} <: AbstractVector{T}`. By invariance, `Float64` instances
  still match every existing `AbstractVector{Float64}` method, so existing
  behavior is untouched. The parametrization is mechanical. Constructors infer
  `T`, so call sites don't change, and `@kwdef` defaults pin the no-argument
  case to `Float64`.
- **Pinned**, the parameters and definitions. They stay `Float64`, since
  promotion handles mixing, and need no migration.
- **[Exempt](#g-walked)**, the discrete side (compensators, avionics). Linearization and trim
  differentiate continuous dynamics only.

For lookups, **table data is a pinned parameter and the query coordinate is
walked traffic.** Interpolations.jl evaluates generically over the coordinate.
`itp(x::Dual)` works through the `BSpline`/`scale`/`extrapolate` compositions in
use. Two caveats apply. `Linear()` interpolants have kinked derivatives at
knots. That is no regression against finite differences, but upgrade to `Cubic`
where Jacobian quality near a lookup matters. A manual chain rule via
`Interpolations.gradient` is the escape hatch for anything exotic, and the
pattern for wrapping non-Julia black boxes.

**Rule.** Three rules are author-facing. First, no `::Float64` argument
annotations in math. Use `<:Real` or nothing, which the codebase already mostly
does. Second, no `Float64`-pinned intermediates. Write `zero(SVector{3,T})`.
Third, **no `::SomeType{Float64}` return-type annotations** on the continuous
path, because they force converts and hence `InexactError`. The `*` method in
`attitude.jl` is the live example pattern.

### 7.3 Discrete state, modes, and workspace

Two homes sit outside the continuous [buffer](#g-buffer), and the rules they obey are
opposites. Discrete state and modes are state in the full sense. They are isbits
values that the framework owns and that a checkpoint copies wholesale. A
[workspace](#g-workspace) is mutable scratch, deliberately not state at all, governed by
contract rather than by checks.

#### Stores: discrete state and modes

**Rule.** Discrete state, a discrete leaf's `s`, and the modes `m` live in
**typed stores**, apart from the buffer that holds `x` ([§7.1][s7-1]). The framework
overwrites an `s` or `m` store when an update or a handler returns a new value.

An `s` or `m` store keeps the same immutable-value discipline as the table's
[cells](#g-cell), in a separate home. The vocabulary of [§4.1][s4-1] never counts a store
as a cell. The `s` and `m` stores never touch the integrator buffer, and no
arithmetic is ever done on them.

**Rule.** Every field of an `s` or `m` store value is **isbits or a `Symbol`**. Isbits is an
immutable value that holds no references, transitively. Enums, integers,
`Bool`s, `SArray`s and nested isbits structs all qualify. A `Symbol` is admitted
as the idiomatic label. It is interned, immutable and never freed, so it copies
as a pointer to permanent data and serializes as its name. The table admits it
on the same grounds, as an opaque leaf ([§4.3][s4-3]). A `String`, an array,
or a struct holding either does not qualify, and neither does a struct nesting a
`Symbol`. The structure step checks every `s_init` and `m_init` field and reports a
violation as `IllegalStoreField` ([§9.1][s9-1], [Appendix C][sC], [D-231][d-231]).

**Why.** State is what changes between [ticks](#g-tick). Bulk data and labels do not, and
their home is the component instance. The frozen-reference latitude signals
enjoy ([§4.1][s4-1]) exists for field handles ([§4.4][s4-4]), and no store needs it. Isbits is
what makes the rest of this section literal. Copying an `s` or `m` store copies
bits, so checkpoint and [replay](#g-replay) of the entire discrete side is "copy the
store values", and a stored value has one fixed layout per component.

#### Workspace

A workspace serves heavy algorithms, such as an n≈20 Kalman filter.

**Rule.** A workspace is [component](#g-component)-declared mutable scratch, instantiated by the
framework. It arrives as the `ws` field of the [bundle](#g-bundle) (the NamedTuple of
zero-copy views a component function receives) in every bundle-receiving
function of the declaring component ([§5.2][s5-2]). `x_projection` is positional and
receives none.

**Rule.** A workspace is **excluded from state semantics**. It is not
snapshotted, not replayed and never a condition target ([§14.1][s14-1]). It must carry no
information between calls.

The framework **never inspects or mutates a workspace**. The workspace is an
opaque, opt-in escape hatch from value semantics, used at the author's own risk,
and its rules are contract, not checks. At call entry, contents are unspecified
beyond the structure the allocator itself established. A plan or factorization
configured at allocation is valid from then on. Scratch is garbage until written
this call, and nothing a previous call left behind may be relied upon. No
poisoning of scratch is attempted ([D-183][d-183]).

**Declared by allocation.** The well-known method *is* the allocator.

```julia
ws_init(c::KF, ::Type{T}) where {T} =
    (P = Matrix{T}(undef, c.n, c.n), x̂ = Vector{T}(undef, c.n))
```

**Rule.** `ws_init(::C, ::Type{T})` takes the activation scalar on both
[tiers](#g-tier), and it is the one declaration that does. A discrete allocator
receives `Float64` at every activation, because the discrete tier never runs at
another scalar ([§9.4][s9-4]). `x_init`, `s_init`, `m_init` and the contracts take
the component alone on every tier.

**Why.** State and cells re-scalar through the walk ([§7.2][s7-2]), so those
declarations never need `T`. Scratch is allocated, not retyped. A factorization,
a plan or a buffer sized by the scalar has no rebuild the framework could
perform, so the eltypes can come from nowhere but the allocator's own argument
([D-077][d-077], [D-263][d-263]).

The allocator is called once per [activation](#g-activation) (the build's typed products at a
given scalar type) and once per scratch-store set ([§14.8][s14-8]). Sizes come from the
instance, and eltypes from the activation. Nothing downstream derives from a
workspace's type, and mistyped scratch detonates loudly at the `Dual` [probe](#g-probe).

The `undef` spelling is the recommended idiom and the sole visible marker that
contents are meaningless. It puts that fact in the declaration, which is the
by-allocation convention this store actually lives in. Declaration is by
allocation, never by initial value ([D-077][d-077]). The `init_` prefix means
*establish*, as the device contract's `init!` does ([§11.6][s11-6]), and carries no claim
that the allocated contents are a value ([D-220][d-220]).

**Available on both tiers.** Nothing in the workspace contract is tier-specific,
and a continuous workspace simply joins the `T`-generic surface. Under a `Dual`
activation the allocator is called at `Dual`, and the in-place math runs through
Julia's generic fallbacks. No BLAS is involved. Activations probe and linearize,
they don't run marathons.

The continuous side runs many calls per [boundary](#g-boundary), for RK stages, localization
trial evaluations and event re-[sweeps](#g-sweep). That multiplicity makes the
no-information-between-calls contract *more* essential there, not less.

**The [blessed](#g-blessed) idiom for zero-allocation [ticks](#g-tick) with immutable `s`.** Do the
in-place math (`mul!`, `cholesky!`, BLAS) on the workspace. At the end, snapshot
into an isbits container and return it, as in `s = KFState(SVector{20}(ws.x̂),
SMatrix{20,20}(ws.P))`.

**The blessed idiom for a PRNG in a discrete leaf.** A generator object such as
`Xoshiro` is mutable, so it is scratch and lives in the workspace, allocated
once. The values that determine its next draw are immutable, so they are state
and live in `s`, which is what makes replay deterministic ([§2.2][s2-2]). The tick loads
them into the generator at entry and snapshots them back at exit, in the same
shape as the Kalman idiom above.

```julia
s_init(::Noise)         = (rng = (0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667),)
ws_init(::Noise, ::Type) = (rng = Xoshiro(0, 0, 0, 0),)

function s_update(c::Noise, b)
    r = b.ws.rng
    r.s0, r.s1, r.s2, r.s3 = b.s.rng        # load the words at entry
    z = randn(r)
    (rng = (r.s0, r.s1, r.s2, r.s3),)       # snapshot them back
end
```

Rematerializing the generator from its values each tick reads naturally and
allocates. A sampler with an out-of-line tail lets the object escape ([D-231][d-231]).

Construction and storage of large `SArray`s are cheap and compile fine. The
StaticArrays "codegen catastrophe" lives in its *operations*, the unrolled
matmuls, which are never called on snapshots.

The discipline is that snapshot values are for storage, logging and element
access only, never arithmetic. It is optionally enforceable by an op-forbidding
`ValueSnapshot{N,T}` wrapper, an `NTuple` with only `getindex` and iteration,
structurally what `SArray` is minus the methods. The practical ceiling is a few
KB comfortable and tens of KB defensible. Beyond that, value semantics stop
making sense.

#### Double-buffered mutable state (deferred)

Double-buffered mutable state is a possible future extension only, deferred
([D-013][d-013]).

### 7.4 The fused-evaluation lineage (prior art and how we got here)

The [§5.2][s5-2] interfaces are the end point of a four-step simplification arc. The arc
is recorded here because each step replaced a mechanism with something smaller.

1. **N output groups → exactly two** ([D-006][d-006]), at the price of an occasional
   [component](#g-component) split ([§5.4][s5-4]).
2. **Derivative binding → own-output access** ([D-015][d-015]). Passing the fresh [signal
   table](#g-signal-table) to `x_deriv`/`s_update` subsumes the
   declaration feature, and the "binding" becomes a one-line function body.
3. **Separate state arguments → the state decoder** ([D-016][d-016], [D-035][d-035]). Step 4 later
   reversed the second half of this step.
4. **Decoder-exclusive state access → stores-and-views arguments.** Step 3's
   second half was reversed ([D-035][d-035]). Once [§8.3][s8-3] made publication a deliberate
   interface act, the identity decode stood revealed as *transport*. It copied
   the [buffer](#g-buffer) into [cells](#g-cell) so that a buffer view could be replaced by a cell view.
   The fixed point is the argument rule ([§5.2][s5-2]), zero-copy views of the stores a
   function genuinely reads. What survives of step 3 is the uniform shapes, the
   fused economics, and the stage-1 decoder itself (today's `y_state`).
   That decoder is no longer the sole state gate. It is the no-[feedthrough](#g-feedthrough)
   stage.

For orientation, here is the prior art. Every causal framework meets the
shared-computation problem and resolves it per its architecture. **Simulink
diagrams** make integrators explicit blocks. Derivatives are ordinary wires into
`1/s`, and the computer/integrator split is their native idiom. **S-functions
and FMUs** use sanctioned *mutable caches*, DWork vectors and FMI's
lazy-evaluation caching, between their `mdlDerivatives`/`mdlOutputs`-style
callback pairs. **Modelica/MTK** write `der(x) = expr` natively with symbolic
CSE. The fused [sweep](#g-sweep) plus signal-consuming `x_deriv`/`s_update` is
the cache-free formulation that fits this design's purity rules. It is also what
FlightCore's fused `f_ode!` did economically, minus the checked ordering.

The **computer/integrator split** remains fully expressible without any
framework support. A stateless component computes derivatives as outputs, wired
into a trivial state-holding component. It is the idiom of choice when the
factoring earns reuse, for example one Newton–Euler solver shared across vehicle
variants, or swappable kinematic descriptors against a common integrator shape.
Against a split-form spelling of the same model (four components, thirteen
connections), the merged form has half the components and wiring. Everything
derivable from pose alone migrates to stage 1, shortening the stage-2 chain.

### 7.5 Allocation policy: a scoped invariant

The allocation policy is not dogma. Three reasons support it, and only one is
about speed. First, GC-pause jitter control for real-time. Second, throughput
for [unattended runs](#g-unattended-run) (runs with empty staging and no snapshot readers). Third,
**the canary**. An unexpected allocation is Julia's most reliable symptom of
type instability. A zero baseline therefore makes `@allocated == 0` a
CI-testable invariant, one that catches inference regressions at the offending
commit.

- **Continuous hot path.** This is per-stage evaluation, plus everything else
  that runs unconditionally per frame or [boundary](#g-boundary). Those unconditional items are
  [guards](#g-guard), evaluated every boundary whether they fire or not, and
  `x_projection` at both of its [§5.3][s5-3] positions in the [execution order](#g-execution-order). The
  budget is exactly zero, CI-enforced at the [§9.7][s9-7] phase-body [seam](#g-seam)
  (`phase_bodies`).
- **Periodic [ticks](#g-tick) and event handlers.** These execute episodically, a tick when
  due and a handler only on firing. Allocation here is zero by idiom. The idiom
  is the [workspace](#g-workspace) (component-declared mutable scratch arriving as the `ws`
  bundle field) and snapshot pattern, plus immutable-value returns. The rare
  exception has a documented tolerance, scoped per body by the seam's
  granularity so it never loosens the continuous assertions.
- **Logging** is amortized-zero. The [log](#g-log) retains the published
  snapshot objects themselves, by reference, one slot per retained boundary
  and no copy ([§11.2][s11-2]). `sizehint!` to the retention bound makes
  regrowth a non-event. The allocation claim is about the snapshot's
  *fields*, not about everything reachable from them. A model carrying [§4.4][s4-4] [field handles](#g-field-handle)
  (immutable query objects consumers evaluate at their own arguments, such as
  heightmap terrain or wind grids) has a snapshot type with reference fields.
  Those fields ride as references to build-time-frozen data, with no copy and no
  per-boundary garbage, which is what the allocation claim asserts. What the
  claim does not assert is that the snapshot is `isbits`. The per-boundary
  allocation cost is zero either way, and the summarize-or-skip rule ([§4.4][s4-4])
  governs what such a field contributes on export.
- **Event firings are not recorded.** The [log](#g-log) holds boundary snapshots and the
  [trace](#g-trace) holds staged inputs ([§11.2][s11-2], [§11.5][s11-5]). Neither carries a per-event record.
  Which events fired at which boundary is recovered by [replay](#g-replay) plus the published
  modes. The honest remedy ([§11.2][s11-2]) is to declare the mode field public and
  return it from `y_state` ([D-252][d-252]); a mode field so exposed is in
  every snapshot. An event-firing stream is a
  [guarded addition](#g-guarded-addition) (a capability the design admits but does not build).
- **Tools where garbage is unavoidable.** Arena allocation (Bumper.jl-style)
  serves scoped temporaries. A scheduled `GC.gc(false)` at frame boundaries
  moves collection out of the critical path. Julia has no per-object freeing, so
  these are the honest levers.

---

