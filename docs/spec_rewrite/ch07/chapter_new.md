## 7. State and data representation

This chapter fixes where data lives, on both tiers and outside them. It fixes
the homes the declared state occupies and how each home holds its values.
Continuous state is an immutable value over a flat buffer the framework owns,
and the continuous path is generic over its scalar type. Discrete state and
modes live in stores, and scratch lives in a workspace. The allocation policy
closes the chapter. [§7.1][s7-1] covers continuous
state, [§7.2][s7-2] numeric genericity, [§7.3][s7-3] discrete state, modes and
the workspace, [§7.4][s7-4] the fused-evaluation lineage that led to the
interfaces of [§5.2][s5-2], and [§7.5][s7-5] the allocation policy.

### 7.1 Continuous state: structured immutable, flat backing

This section fixes how a [continuous component](#g-continuous-component) (the
hybrid primitive, with continuous state, flow and events) declares its state,
and how the framework lays that state out, reads it and writes it back. It
covers, in order, the closed leaf vocabulary, the three things the framework
does with a declaration, the buffer and its views, why the vocabulary is
closed, the shape of `Ẋ`, and what the design buys against FlightCore's
mutable-view pattern.

Each continuous component declares its state by value (`x_init`,
[§8.2][s8-2], [D-033][d-033]). The declaration is a NamedTuple
([D-247][d-247]). **Its leaves are drawn from a deliberately closed
vocabulary**, plain real scalars and `SArray`s (static vectors and matrices) of
a common eltype `T`, and nothing else ([D-094][d-094]). `Int`s, enums and
`Bool`s belong in modes. Domain wrapper types are not state leaves either. Two
such types are `RQuat`, a rotation quaternion type with a `normalization`
keyword, and `Ranged`, a clamped scalar. An attitude state is an
`SVector{4,T}`, cast where rotation semantics are wanted, as described below.
The structure step refuses a field outside the vocabulary as
`IllegalStateLeaf` ([§9.1][s9-1]). [§8.2][s8-2] shows the kind's messages.

**The declaration is flat** ([D-094][d-094]). Each field is one leaf, never a
`NamedTuple` of leaves. The condition algebra and the readers address a field
as one leaf ([§14.3][s14-3], [§14.4][s14-4]), and structure comes from the
component tree, not from the value.

The framework does three things with the declaration.

- It computes a flat layout at build time. The layout has compile-time offsets
  into one contiguous `Vector{T}` that the framework owns, the
  [buffer](#g-buffer).
- It reconstructs the typed immutable state value for a
  [component](#g-component) at each evaluation. It passes that value to every
  function receiving state views, under the argument rule of [§5.2][s5-2]
  ([D-035][d-035]). The reconstruction is field loads at known offsets,
  register-level, at zero cost.
- It receives immutable results back. Derivative functions return an
  `Ẋ`-typed value, which is scatter-stored into the flat `ẋ` buffer. A
  handler's `x` key and the [projection](#g-projection) (the optional hook
  `x_projection`) carry a new `X`, which is written back. Projection's
  write-back happens at the two positions in the
  [execution order](#g-execution-order) of [§5.3][s5-3] ([D-111][d-111]).

**The buffer is authoritative, and typed values are ephemeral
reconstructions** ([D-010][d-010]). Nobody outside the framework ever holds a
mutable reference to state. "Ephemeral" is literal. An isbits view
materializes in the caller's frame for exactly the duration of the call, and
has no existence between calls. Where it materializes, in registers or on the
spilled stack, is the compiler's business. Re-materializing is the same loads,
and it is value-identical because the value is immutable and the buffer is
unchanged within a [sweep](#g-sweep) (one pass through the execution order). This
buffer-unchanged-within-a-sweep rule is exactly the legality condition of the
code generator's CSE, the common-subexpression elimination that hoists
repeated reads of views rebuilt per call ([§9.7][s9-7], [D-288][d-288]).

The complementary rule is [one home per datum](#g-one-home-per-datum) (each
datum has exactly one home), stated in [§5.2][s5-2] ([D-035][d-035]). In
particular there are no state [cells](#g-cell) in the
[signal table](#g-signal-table) beyond the declared [ports](#g-port) a
component returns from `y_state` ([§5.3][s5-3], [D-252][d-252]), which are
interface, not transport.

The vocabulary is closed because views must materialize without running
anyone's invariants. Scalars and `SArray`s have invariant-free constructors.
`SVector`'s stores its tuple, `NamedTuple` construction runs no user code, and
nothing normalizes or clamps. Building a view through ordinary public
construction is therefore bit-faithful automatically. `reconstruct(flatten(x))
== x` holds identically, with no constructor bypass, no `reinterpret`, and no
reliance on a custom struct's memory layout mirroring the buffer's.
Invariant-carrying leaves are excluded from the vocabulary ([D-094][d-094]).

Domain semantics are instead an explicit, invariant-free cast at the point of
use. It is the conversion that `f_ode!`, FlightCore's in-place derivative
function, performs on its raw views. Invariants live where the design already
put them, in `x_projection` at [boundaries](#g-boundary) and in writers.
Handlers build their returned values through ordinary constructors, and the
condition apply converts authored values through ordinary `convert` methods
([§14.3][s14-3]). Constructors run on the write paths, never on views.

With the leaf vocabulary closed, the shape of `Ẋ` takes one line to state.
`Ẋ` has exactly `X`'s shape at the [activation](#g-activation) scalar (the
scalar type `T` an activation is built at). A scalar leaf's derivative is a
`T`, and an `SArray` leaf's is the same `SArray` at `T`. This is what the
closed vocabulary buys. An invariant-carrying leaf like a unit quaternion has a
derivative off its own type, and `Ẋ` would need a separate derivation. Here
the attitude leaf is an `SVector{4,T}`, and so is its rate. The conformance
predicate is structural. *Each field of `x_deriv`'s return scatters into its
field's block at `T`* ([§9.5][s9-5] states the check). That makes derivative
completeness a property of the layout rather than of author discipline. There
is deliberately no `derivative_type` hook ([D-190][d-190]).

FlightCore's pattern was a flat `Vector` read through `ComponentArrays` views,
which are mutable views into the flat vector. Against that pattern, this
design buys five things.

- There are no aliased mutable views, where who writes what is a matter of
  convention.
- Derivative completeness is structural. The returned `Ẋ` has every field by
  construction, so a forgotten `ẋ` entry is impossible rather than silently
  stale.
- State fields arrive as the declared scalars and `SArray`s, immutable. The
  domain wrapper, where wanted, is one explicit invariant-free cast
  (`RQuat(x.q, normalization = false)`). That is the conversion the
  mutable-views pattern performed implicitly, now visible and chosen.
- The flat vector still exists. Integrator compatibility (OrdinaryDiffEq or
  custom), trim solvers, HDF5 logging and linearization all get their arrays.
- Flight.jl's hand-written per-aircraft state-space mapping layer
  (`get_x_ss`/`assign_x_ss!`/`get_u_ss`/...) is deleted, replaced by the
  framework's canonical layout ([D-072][d-072]).

### 7.2 Numeric genericity (eltype)

**The entire continuous evaluation path is generic over `T <: Real`**, and so
are the state [buffer](#g-buffer) (the framework-owned flat vector backing
continuous state) and the pack/unpack machinery ([D-011][d-011]). This one
design property serves four consumers.

1. Exact Jacobians for linearization, with ForwardDiff duals through the
   whole model, replacing finite differences.
2. Derivatives for trim solvers.
3. The [feedthrough tracer](#g-feedthrough-tracer) (the set-propagation
   instrument classifying a rejected cycle, [§5.6][s5-6]).
4. A trivially checkable CI invariant ([D-280][d-280]). One evaluation
   [sweep](#g-sweep) (one pass through the execution order) with `T = Dual`
   fails loudly on any Float64-pinning. It fails with a `MethodError` or an
   `InexactError` at the offending line.

The rest of the section states the three tiers that scope this genericity, how
the declaration layer spells them per leaf, how lookup tables fit them, and
three rules for authors.

Scoping, meaning what actually needs genericity, has three tiers
([D-011][d-011]).

- *[Walked](#g-walked)*, the payload and value types constructed during
  evaluation. One example is `FrameTransform`, a FlightPhysics payload type.
  The walked types' parametrization is mechanical. Constructors infer `T`, so
  call sites don't change, and `@kwdef` defaults pin the no-argument case to
  `Float64`. `@kwdef` is Julia's keyword-constructor macro.
- *Pinned*, the parameters and definitions. They stay `Float64`, since
  promotion handles mixing.
- *Exempt*, the discrete side (compensators, avionics). Linearization and trim
  differentiate continuous dynamics only.

For consumer 1, the *discrete* side's exemption is not a limitation but the
exact answer ([D-072][d-072]). A frozen discrete [cell](#g-cell) (a typed
entry of the signal table) is a constant with zero partials. That is what
"linearize the continuous dynamics with the discrete state held" means.
`frozen_discrete_walkthrough.md` works the chain through in detail.

The declaration layer keeps this scoping legible without putting it in the
author's way. Every declaration but the allocator ([§7.3][s7-3]) is written at
nominal `Float64`. One walk retypes it per [activation](#g-activation) (the
build's typed products at a given scalar type), as [§8.2][s8-2] states. On the
continuous tier a `Float64` leaf follows the activation scalar, in a contract
and in the `x_init`-derived state type alike ([D-263][d-263], [D-295][d-295]).
A contract leaf wrapped in the leaf marker `Pinned{P}` is deliberately
pinned ([D-263][d-263]). Participation is therefore authored per
leaf, by the absence or presence of the marker. The discrete side stays plain
and pins wholesale ([D-263][d-263], [D-295][d-295]). Nothing anywhere comes
from inference through user code ([D-032][d-032],
[D-079][d-079]). Safety of the substitution
rests on the embedding guarantee stated in [§9.5][s9-5].

For lookups, table data is a pinned parameter and the query coordinate is
walked traffic ([D-011][d-011]). Interpolations.jl, the interpolation package
Flight.jl's lookup tables use, evaluates generically over the coordinate. A
call `itp(x::Dual)` works through the `BSpline`/`scale`/`extrapolate`
compositions in Flight.jl's tables. Two caveats apply. `Linear()` interpolants
have kinked derivatives at knots. That is no regression against finite
differences, but upgrade to `Cubic` where Jacobian quality near a lookup
matters. A manual chain rule via `Interpolations.gradient` is the escape hatch
for anything exotic, and the pattern for wrapping non-Julia black boxes
([D-266][d-266]).

Three rules are author-facing ([D-011][d-011], [D-235][d-235]).

1. No `::Float64` argument annotations in math. Use `<:Real` or nothing.
2. No `Float64`-pinned intermediates. Write `zero(SVector{3,T})`.
3. No `::SomeType{Float64}` return-type annotations on the continuous path,
   because they force converts and hence `InexactError`.

### 7.3 Discrete state, modes, and workspace

Two homes sit outside the continuous [buffer](#g-buffer) (the contiguous
vector backing all continuous state), and the rules they obey are opposites.
Discrete state and modes are state in the full sense. They are values whose
fields are isbits or `Symbol`s. The framework owns them, and a checkpoint
copies them wholesale. A [workspace](#g-workspace) is mutable scratch,
deliberately not state at all, governed by contract rather than by checks.
The section states the rules of the `s` and `m` [stores](#g-store) (the
framework-owned homes of those letters) first, then the workspace's rules,
then the idioms that join the two homes.

#### Stores: discrete state and modes

**Discrete state, a discrete leaf's `s`, and the modes `m` live in typed
stores**, apart from the buffer that holds `x` ([§7.1][s7-1], [D-013][d-013],
[D-302][d-302]).
The framework overwrites an `s` or `m` store when an update or a handler
returns a new value.

An `s` or `m` store keeps the same immutable-value discipline as the table's
[cells](#g-cell), in a separate home. The vocabulary of [§4.1][s4-1] never
counts a store as a cell ([D-302][d-302]). The `s` and `m` stores never touch
the integrator buffer, and no arithmetic is ever done on them.

**Every field of an `s` or `m` store value is isbits or a `Symbol`**
([D-231][d-231]). Isbits is an immutable value that holds no references,
transitively. Enums, integers, `Bool`s, `SArray`s and nested isbits structs
all qualify. A `String`, an array, or a struct holding either does not
qualify.

A `Symbol` is admitted as the idiomatic label. It is interned, immutable and
never freed, so it copies as a pointer to permanent data and serializes as its
name. The table admits it on the same grounds, as an opaque leaf
([§4.3][s4-3]). A struct nesting a `Symbol` does not qualify. The structure
step checks every `s_init` and `m_init` field and reports a violation as
`IllegalStoreField` ([§9.1][s9-1], [Appendix C][sC], [D-231][d-231]).

The rule rests on what state is. State is what changes between
[ticks](#g-tick) (the instants a discrete component runs). Bulk data and
labels do not, and their home is the component instance. **The
frozen-reference latitude stays with signals** ([§4.1][s4-1],
[D-231][d-231]). It exists for field handles ([§4.4][s4-4]), and no store
needs it. Isbits is what makes the rest of this section literal. Copying an
`s` or `m` store copies bits. So checkpoint and [replay](#g-replay) (the
ordinary loop re-driven from the trace) of the entire discrete side is "copy
the store values", and a stored value has one fixed layout per component.

Double-buffered mutable state is a possible future extension only, deferred
([D-013][d-013]).

#### Workspace

A workspace serves heavy algorithms, such as an n≈20 Kalman filter. A
workspace is [component](#g-component)-declared mutable scratch, instantiated
by the framework ([D-013][d-013]). It arrives as the `ws` field of the
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives) in every bundle-receiving function of the declaring component
([§5.2][s5-2]). `x_projection` is positional and receives none
([D-074][d-074]).

A workspace is excluded from state semantics. It is not snapshotted, not
replayed and never a condition target ([§14.1][s14-1]). It must carry no
information between calls ([D-183][d-183]).

**The framework never inspects or mutates a workspace** ([D-183][d-183]). The
workspace is an opaque, opt-in escape hatch from value semantics, used at the
author's own risk. Its rules are contract, not checks. At call entry, contents
are unspecified beyond the structure the allocator itself established. A plan
or factorization configured at allocation is valid from then on. Scratch is
garbage until written this call, and nothing a previous call left behind may
be relied upon. No poisoning of scratch is attempted.

**A workspace is declared by allocation** ([D-077][d-077]). The well-known
method *is* the allocator.

```julia
ws_init(c::KF, ::Type{T}) where {T} =
    (P = Matrix{T}(undef, c.n, c.n), x̂ = Vector{T}(undef, c.n))
```

**`ws_init(::C, ::Type{T})` takes the [activation](#g-activation) scalar on
both [tiers](#g-tier)**, and it is the one declaration that does
([D-263][d-263]). An activation is the build's typed products at a given
scalar type, and a tier is the continuous or the discrete side. A discrete
allocator receives `Float64` at every activation, because the discrete tier
never runs at another scalar ([§9.4][s9-4]). `x_init`, `s_init`, `m_init` and
the contract declarations take the component alone on every tier. Nothing in
the workspace contract is tier-specific, and a continuous workspace simply
joins the `T`-generic surface. Under a `Dual` activation the allocator is
called at `Dual`, and the in-place math runs through Julia's generic
fallbacks. No BLAS is involved. Activations probe and linearize. They don't
run marathons.

State and cells re-scalar through the walk ([§7.2][s7-2]), so those
declarations never need `T`. Scratch is allocated, not retyped. A
factorization, a plan or a buffer sized by the scalar has no rebuild the
framework could perform. So the eltypes can come from nowhere but the
allocator's own argument ([D-077][d-077], [D-263][d-263]).

The allocator is called once per activation and once per scratch-store set
([§14.8][s14-8], [D-077][d-077]). Sizes come from the instance, and eltypes
from the activation. Nothing downstream derives from a workspace's type, and
mistyped scratch detonates loudly at the `Dual` [probe](#g-probe) (the
build's single evaluation of a user function).

The `undef` spelling is the recommended idiom and the sole visible marker that
contents are meaningless. It puts that fact in the declaration. That is the
by-allocation convention this declaration actually lives in. Declaration is by
allocation, never by initial value ([D-077][d-077]). The `init` in `ws_init`
means *establish*, as the device contract's `init!` does ([§11.6][s11-6]). It
carries no claim that the allocated contents are a value ([D-220][d-220]).

The continuous side runs many calls per [boundary](#g-boundary) (a published
consistency point), for RK stages, localization trial evaluations and event
re-[sweeps](#g-sweep). That multiplicity makes the
no-information-between-calls contract *more* essential there, not less.

#### Idioms

The [blessed](#g-blessed) (explicitly sanctioned) idiom for zero-allocation
ticks with immutable `s` does the in-place math (`mul!`, `cholesky!`, BLAS) on
the workspace ([D-013][d-013]). At the end, it snapshots into an isbits
container and returns it, as in `s = KFState(SVector{20}(ws.x̂),
SMatrix{20,20}(ws.P))`.

In the blessed idiom for a PRNG in a discrete leaf, **a generator object such
as `Xoshiro` lives in the workspace, and the values that determine its next
draw are state in `s`** ([D-231][d-231]). The generator is mutable, so it is
scratch and lives in the workspace, allocated once. The values are immutable,
so they are state and live in `s`. Keeping them in `s` is what makes replay
deterministic ([§2.2][s2-2]). The tick loads them into the generator at
entry and snapshots them back at exit, in the same shape as the Kalman idiom
above.

```julia
s_init(::Noise)         = (rng = UInt64.((0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667)),)
ws_init(::Noise, ::Type) = (rng = Xoshiro(0, 0, 0, 0),)

function s_update(c::Noise, b)
    r = b.ws.rng
    r.s0, r.s1, r.s2, r.s3 = b.s.rng        # load the words at entry
    z = randn(r)
    (rng = (r.s0, r.s1, r.s2, r.s3),)       # snapshot them back
end
```

Rematerializing the generator from its values each tick reads naturally and
allocates. A sampler with an out-of-line tail lets the object escape
([D-231][d-231]).

Construction and storage of large `SArray`s are cheap and compile fine. The
StaticArrays "codegen catastrophe" lives in its *operations*, the unrolled
matmuls, which are never called on snapshots.

The discipline is that snapshot values are for storage, logging and element
access only, never arithmetic. It is optionally enforceable by an
op-forbidding `ValueSnapshot{N,T}` wrapper. That wrapper is an `NTuple` with
only `getindex` and iteration, structurally what `SArray` is minus the
methods. The practical ceiling is a few KB comfortable and tens of KB
defensible. Beyond that, value semantics stop making sense.

### 7.4 The fused-evaluation lineage (prior art and how we got here)

Overlap between derivatives and outputs is the norm in physical and control
models ([§5.3][s5-3]). The [§5.2][s5-2] interfaces are the end point of a
four-step simplification arc. The arc is recorded here because each step
replaced a mechanism with something smaller. The section gives the four steps,
then the prior art, then an idiom the design admits without framework support.

1. N output groups gave way to exactly two ([D-006][d-006]), at the price of an
   occasional [component](#g-component) split ([§5.4][s5-4]).
2. Derivative binding gave way to own-output access ([D-015][d-015]). Passing
   the fresh [signal table](#g-signal-table) to `x_deriv`/`s_update` subsumes
   the declaration feature, and the "binding" becomes a one-line function body.
3. Separate state arguments gave way to the state decoder ([D-016][d-016],
   [D-035][d-035]). Step 4 later reversed the second half of this step.
4. Decoder-exclusive state access gave way to stores-and-views arguments.
   Step 3's second half was reversed ([D-035][d-035]). Once contract
   visibility ([§8.3][s8-3], [D-034][d-034]) made a port's publicity a
   declaration, the identity decode stood revealed as *transport*. It copied
   the [buffer](#g-buffer) into [cells](#g-cell) so that a buffer view could be
   replaced by a cell view. The fixed point is the argument rule
   ([§5.2][s5-2]). A function receives zero-copy views of the stores it
   genuinely reads. What survives of step 3 is the uniform shapes, the fused
   economics, and the stage-1 decoder itself (now `y_state`). That decoder is
   no longer the sole state gate. It is the no-[feedthrough](#g-feedthrough)
   stage.

Every causal framework meets the shared-computation problem and resolves it
per its architecture. The prior art is given here for orientation. Simulink
diagrams make integrators explicit blocks. Derivatives are ordinary wires into
`1/s`, and the computer/integrator split is their native idiom. S-functions and
FMUs use sanctioned *mutable caches* between their
`mdlDerivatives`/`mdlOutputs`-style callback pairs. The caches are DWork
vectors and FMI's lazy-evaluation caching. Modelica/MTK (ModelingToolkit)
write `der(x) = expr` natively, with symbolic common-subexpression
elimination. The fused [sweep](#g-sweep) plus signal-consuming
`x_deriv`/`s_update` is the cache-free formulation that fits this design's
purity rules ([D-015][d-015]). It is also what FlightCore's fused `f_ode!`
(its in-place derivative function) did economically, minus the checked
ordering.

The computer/integrator split remains fully expressible without any framework
support ([D-015][d-015]). A stateless component computes derivatives as
outputs and is wired into a trivial state-holding component. It is the idiom
of choice when the factoring earns reuse. Two examples are one Newton–Euler
solver shared across vehicle variants, and swappable kinematic descriptors
against a common integrator shape. Against a split-form spelling of a
rigid-body kinematics and dynamics core (four components, thirteen
connections), the merged form has half the components and wiring
([D-015][d-015]). Everything derivable from pose alone migrates to stage 1,
shortening the stage-2 chain.

### 7.5 Allocation policy: a scoped invariant

The allocation policy is not dogma ([D-014][d-014]). Three reasons support it,
and only one is about speed. The first is GC-pause jitter control for
real-time. The second is throughput for [unattended runs](#g-unattended-run)
(runs with empty staging and no snapshot readers). The third is the canary. An
unexpected allocation is Julia's most reliable symptom of type instability. A
zero baseline therefore makes `@allocated == 0` a CI-testable invariant. That
invariant catches inference regressions at the offending commit. The section
states the invariant's scope, the policy's three tiers, what the
[log](#g-log) does not record, and the tools for garbage that cannot be
avoided.

The zero-allocation invariant is scoped to the stepping loop, and the
stopped-sim services were always allocation-tolerant ([D-135][d-135],
[§14.8][s14-8]). Publication is not a phase body ([D-288][d-288],
[§9.7][s9-7]), and its one snapshot allocation per
[boundary](#g-boundary) sits with logging on the framework side, outside what the
invariant claims is zero ([§11.2][s11-2]).

The policy has three tiers.

- The continuous hot path is per-stage evaluation, plus everything else that
  runs unconditionally per frame or boundary. Those
  unconditional items are [guards](#g-guard), evaluated every boundary whether
  they fire or not, and `x_projection` at both of its [§5.3][s5-3] positions in
  the [execution order](#g-execution-order). **The budget is exactly zero,
  CI-enforced** at the phase-body [seam](#g-seam) that `phase_bodies` exposes
  ([§9.7][s9-7], [D-014][d-014], [D-116][d-116]).
- Periodic [ticks](#g-tick) and event handlers execute episodically. A tick
  runs when due, and a handler only on firing. Their allocation is zero by
  idiom. The idiom is the [workspace](#g-workspace) (component-declared mutable
  scratch arriving as the `ws` bundle field) and snapshot pattern, plus
  immutable-value returns. The rare exception has a documented tolerance
  ([D-116][d-116]). The seam's granularity scopes the tolerance per body, so the
  tolerance never loosens the continuous assertions.
- Logging is amortized-zero. The log retains the published snapshot
  objects themselves, by reference ([§11.2][s11-2], [D-137][d-137]). It keeps
  one slot per retained boundary and makes no copy. `sizehint!` to the
  retention bound makes regrowth a non-event.

  The allocation claim is about the snapshot's *fields*, not about everything
  reachable from them. A model carrying [§4.4][s4-4]
  [field handles](#g-field-handle) (immutable query objects consumers evaluate
  at their own arguments, such as heightmap terrain or wind grids) has a
  snapshot type with reference fields. Those fields ride as references to
  build-time-frozen data, with no copy and no per-boundary garbage. That is
  what the allocation claim asserts. The claim does not assert that the
  snapshot is `isbits`. The per-boundary allocation cost is zero either way.
  The summarize-or-skip rule ([§4.4][s4-4]) governs what such a field
  contributes on export.

Event firings are not recorded. The log holds boundary snapshots and the
[trace](#g-trace) holds staged inputs ([§11.2][s11-2], [§11.5][s11-5]).
Neither carries a per-event record. [Replay](#g-replay) plus the published
modes recovers which events fired at which boundary. The honest remedy is to
declare the mode field public and return it from `y_state` ([§11.2][s11-2],
[D-252][d-252]). A mode field so exposed is in every snapshot. An event-firing
stream is a [guarded addition](#g-guarded-addition) (a capability the design
admits but does not build).

Two tools serve where garbage is unavoidable. Arena allocation
(Bumper.jl-style) serves scoped temporaries. A scheduled `GC.gc(false)` at
frame boundaries moves collection out of the critical path. Julia has no
per-object freeing, so these are the honest levers.

---

