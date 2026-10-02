## 10. Time and execution

This chapter states how the loop runs a model through time. It takes the
execution order ([§5.3][s5-3]) and the compiled executor ([§9.7][s9-7]) as
given. [§10.1][s10-1] covers loop ownership and the loop's two units;
[§10.2][s10-2] the stepper seam; [§10.3][s10-3] signal-table consistency;
[§10.4][s10-4] localization mechanics; [§10.5][s10-5] multi-rate tick
scheduling; [§10.6][s10-6] event iteration at boundaries; and [§10.7][s10-7]
real-time pacing.

### 10.1 Loop ownership: the framework owns the simulation loop

This section defines the simulation loop's two units, lists its six activities
and states who writes the loop. The two units recur throughout the chapter,
and they mean different things.

- A [frame](#g-frame) is one grid step `[tₙ, tₙ₊₁]`. It is the unit of
  scheduling. Three things are keyed to it, namely the input
  [drain](#g-drain) (the frame-top swap that publishes staged device writes
  into the root inputs, [§11.4][s11-4]), pacer deadlines ([§10.7][s10-7]) and
  [tick](#g-tick) eligibility ([§10.5][s10-5]).
- A [boundary](#g-boundary) is a published consistency point. The boundary
  sequence ([§5.3][s5-3]) completes there, in the final form [§10.6][s10-6]
  calls the macro-sequence, and a [snapshot](#g-snapshot) (the immutable
  per-boundary publication) goes out.

Every grid point is a boundary, but not every boundary is a grid point.
`t*` is an event's crossing instant inside a step, bracketed by root-finding
([§10.4][s10-4]). **The [localized](#g-localized) event time `t*` is a
boundary but not a frame top** ([D-081][d-081]).
[Boundary zero](#g-boundary-zero) (the initialization boundary at `t₀`,
[§14.5][s14-5]) is a boundary and not a frame top either.

The loop consists of six activities. They are the boundary sequence
([§5.3][s5-3]), tick dispatch, event handling, logging, input staging, and
[pacing](#g-pacing) (waits inserted between completed frames, never altering
the boundary sequence).

**All six are framework code, unconditionally** ([D-017][d-017]). The framework
writes the loop itself. It does not assemble the loop out of callbacks
registered with a third-party solver. The reason is the step-boundary contract
(at every boundary the [§10.6][s10-6] macro-sequence completes before a snapshot
goes out). It is the central invariant of this design. Only a loop the framework
owns can enforce that contract by construction rather than by convention.
[D-017][d-017] records the rejected foreign-loop alternative.

**`OrdinaryDiffEq` is dropped as a dependency** of the new core
([D-017][d-017]).

### 10.2 The stepper seam

Loop ownership stops at one operation. That operation advances the continuous
state from `t` by `h`. **The framework delegates that operation across a
narrow internal interface**, the [stepper seam](#g-seam) ([D-017][d-017]).
The seam exists so that the integration method can be replaced without the
loop changing.

#### What the seam requires of a backend

The seam contract has four clauses.

- The backend advances by arbitrary `h`. The loop needs this anyway. It lands
  on [tick](#g-tick) [boundaries](#g-boundary), and it resumes from a
  [localized](#g-localized) event time (the crossing instant bracketed by
  root-finding over trial evaluations).
- The backend provides dense output on demand over the last completed step.
  Only event localization needs it ([§10.4][s10-4]), so the backend
  constructs it lazily.
- The backend uses one-step methods only. Event handlers reset state
  discontinuously, and a one-step method restarts from a new state for free.
  Multistep methods are excluded ([D-017][d-017]).
- The seam carries what a backend needs across a frame top through a
  checkpoint hook, empty for a single-step method. A
  [checkpoint](#g-checkpoint) is the executor's state at a frame top
  ([§12.6][s12-6], [D-274][d-274]).

#### Models with no continuous state

A model with no continuous state at all is legal ([D-156][d-156]). Nothing in
[§8.2][s8-2] requires an `x` block of any component. Such a model still has
to be run.

**The seam is never entered empty** ([D-156][d-156]). The framework
short-circuits this case rather than pushing it down the seam. With an empty
`x`, the integrate step degenerates to advancing `t` to the next boundary,
and the stepper is not called. No backend ever faces a state count of
`N = 0`, and no backend contract has to say what it would do there.

The loop-ownership rule ([§10.1][s10-1]) pays off structurally here. Under a
foreign solver loop, an empty state pays a dummy-`[0.0]` tax
([D-017][d-017]). Here that tax is gone at the root. Both the
[buffer](#g-buffer) (the contiguous vector backing all continuous state) and
the step over it disappear. Everything else about such a model is ordinary.
The boundary machinery of [sweeps](#g-sweep), events and ticks runs
unchanged.

#### The first-cut backends

**The first cut ships in-house fixed-step RK4 and Heun** over the flat state
buffer ([D-017][d-017]). Together they are about a hundred lines. They are
trivially zero-allocation, so they can be audited against the CI invariant
([§7.5][s7-5]). They are also trivially `T`-generic. Genericity is not even
required of the stepper, because linearization and the
[feedthrough tracer](#g-feedthrough-tracer) (the instrument that classifies a
rejected cycle as real or artificial, [§5.6][s5-6]) drive the *sweep*, never the
integrator.

**`RK4` is the default** of the two ([D-227][d-227]). The `algorithm` keyword
selects the backend by type on the [`Deployment`](#g-deployment) (the
scalar-free artifact the grid parameters fix). Materialization at
`Simulation` construction binds the stepper against the state buffer, on the
executor ([Appendix B][sB], [§9.2][s9-2], [D-227][d-227]). The step `h` has
no default and is required of the caller. A domain rate is not a framework
default.

An `OrdinaryDiffEq`-backed stepper can exist later as a package extension, if
an offline study genuinely demands adaptive or stiff methods
([D-017][d-017]). It is a [guarded addition](#g-guarded-addition) (a
capability the design admits but does not build), so it is not built until
then.

#### The case for fixed-step low order

The domain argument is recorded here because it is decisive for the choice
of integration method. It makes three claims.

1. Closed-loop ticks cap the step. Every application beyond bare propagation
   runs periodic avionics (onboard flight systems), whose commands are
   zero-order-held signals. Integrating past a tick with stale commands is
   wrong, so the integrator must land on every tick boundary regardless of
   method. Adaptive and high-order methods pay off exactly when steps can
   stretch, and the execution model forbids the stretch by construction.
2. A piecewise-smooth [RHS](#g-flow) (the continuous derivative function)
   starves high order. Linearly interpolated lookup tables (C¹-kinked at
   every knot), clamps, friction blends and mode branches deny high-order
   error estimators and implicit-solver Newton iterations the smoothness they
   assume.
3. Stiffness has a remedy ladder. If a future model exceeds RK4's stability
   region at the deployed `h`, the ladder runs in order. First shrink `h`. Then
   subcycle the stepper against the tick grid. Only then reach for an implicit
   method through the `OrdinaryDiffEq` extension above. If that day comes,
   eltype genericity ([§7.2][s7-2]) supplies exact ForwardDiff Jacobians through
   the sweep for free.

The Flight.jl evidence behind these claims lives in section 5 of
`companions/flight_case_studies.md`.

### 10.3 Signal-table consistency is a boundary property

During a step, the RK stages evaluate the [interior sweep](#g-sweep) (the
sweep variant over continuous entries only, [§10.5][s10-5]) at internal stage
states ([D-147][d-147]). While they do, the [signal table](#g-signal-table)
is transiently integrator scratch. The boundary sweep in the
[§5.3][s5-3] sequence restores consistency at each accepted
[boundary](#g-boundary).

**External readers observe the signal table only at step boundaries**
([D-023][d-023]). These readers are the GUI, logging and network output.
Mid-step contents carry no meaning. This rule binds the
[periphery](#g-periphery) (everything outside the loop that exchanges data with
it, [§11][s11]). The rule extends naturally to the boundary sequence
([§10.6][s10-6]). External readers observe the table only after the boundary
sequence completes.

### 10.4 Localization mechanics

A [guard](#g-guard)'s [predicate](#g-predicate) can cross inside an integration step, strictly between two
grid points. The framework can handle such a crossing in two ways. It can notice
the crossing at the end of the step, at grid resolution. Or it can find the
crossing instant and publish it. This section fixes which guards get which
treatment, and describes the machinery behind the second.

The [localized](#g-localized) event time `t*` is a [boundary](#g-boundary) (a
published consistency point, [§10.1][s10-1]). It is not the top of a
[frame](#g-frame) (one grid step, the unit of scheduling).

A frame in which one event localizes runs through these steps. Its boundaries
are tₙ, `t*` and tₙ₊₁.

> tₙ → integrate → arrival sweep at tₙ₊₁ → trigger → θ = 0 trial evaluation
> → bracket → root-find → t\* → remainder step → tₙ₊₁

This chain lists the order of operations. It is not a walk along the time axis.
The [arrival sweep](#g-sweep) (the sweep that closes the integration step) at
tₙ₊₁ raises the trigger, and integration then resumes from `t*`, which lies
before tₙ₊₁.

#### Detection policy

**The guard's return type declares its detection policy** ([D-179][d-179]). No
flag is involved.

- A guard returning `Bool` is [boundary-detected](#g-boundary-detected). The framework checks it for
  edges at step boundaries only and never root-finds it.
- A guard returning the nominal scalar, the continuous sign form, is localized.
  The framework brackets the crossing instant by root-finding over trial
  evaluations.

The build reads the policy off the [probe](#g-probe) it already runs ([§9.3][s9-3], nominal
[activation](#g-activation)). `StateEvent(guard, handler)` therefore carries no detection keyword
([D-179][d-179]).

Localization brackets a root, and only the sign form offers one. Because the
form is the policy, a localized `Bool` guard cannot be written at all. It needs
no diagnostic.

A localized guard becomes boundary-detected with a one-line rewrite, at no
semantic cost ([D-179][d-179]). Return the predicate `σ ≥ 0` instead of the
sign-form value `σ`. That cast is the definition of the predicate
([§2.1][s2-1]). The predicate and its edges stay the same. Only the resolution
at which they are observed changes.

**For a guard that reads only `u` and `m`, boundary detection is exact**
([D-179][d-179]). Such a predicate is constant within each frame. `u` changes
only at the frame-top [drain](#g-drain) (the swap that publishes staged device writes into
the root inputs, [§11.4][s11-4]), and `m` changes only through handlers, at
boundaries. The predicate cannot cross mid-step, so there is no interior instant
for a root-finder to find. Here the boundary is not a resolution limit. It is
the crossing itself, and localization would have nothing to do.

A mixed predicate combines `Bool` factors with a continuous one. Take a piston
engine whose modes include `starting` and `running`. Its `starting → running`
transition fires on `ω > ω_idle && fuel_available`.

**When such a transition should localize, write it in the gate form
`(gate) ? σ : -one(σ)`** ([D-179][d-179]). The `Bool` factors go in the branch
condition and the continuous factor in the value.

The gate idiom is sound rather than a way around the policy check. Trial
evaluations (below) vary only θ, the normalized time within the step. `u` and
`m` stay fixed through a localization, so the gates are constant over the
bracket. Restricted to the bracket, σ is the continuous atom, and it can be
bracketed as such.

#### Trial evaluations

A trial evaluation computes a guard's value at one instant θ inside the step.
At θ = 0 its state is xₙ itself. Elsewhere its state is x̂(θ), a point on the
[interpolant](#g-interpolant) (the cubic Hermite continuous extension over the last completed
step), which the localization loop below defines and builds.

**Trial evaluations run the interior sweep** ([D-147][d-147]). Guards read `y`.
Evaluating a guard at an interpolated state therefore means writing
$\hat{x}(\theta)$ into the state [buffer](#g-buffer) and running the
interior sweep. The [RHS](#g-flow) already lives under this rule
([§10.5][s10-5]), since a trial evaluation is a mid-step evaluation. Discrete
[cells](#g-cell) therefore hold their [tick](#g-tick) values (set at the last
instant their stages and update ran) through localization, and a guard reading a
sampled output sees what the controller is holding. Each trial evaluation costs
one interior sweep.

#### The trigger

**A localized event triggers when its predicate was not-[holding](#g-edge-semantics) at tₙ's
[quiescence](#g-quiescence) and is holding at tₙ₊₁** ([D-082][d-082]). Quiescence is the fixed
point where a round of handlers fires nothing. The tₙ sample is the event's
[prior](#g-prior), the predicate sample stored at the previous boundary
([§10.6][s10-6]).

This is the directional edge of [§2.1][s2-1], not a bare sign change. A holding →
not-holding transition neither fires nor localizes.

**The trigger check runs against the arrival sweep at tₙ₊₁** ([D-182][d-182]).
That is the sweep that closes the integration step. So the check runs before the
due-gated boundary sweep refreshes any discrete cell. The rule that trial
evaluations run the interior sweep (above) already forces this order, because
trial evaluations must see the values the frame actually held. Stating it here
fixes the sequencing up front. Every `t*` firing precedes tₙ₊₁'s whole boundary
sequence.

#### The localization loop

The sketch below shows one localized event within one frame. Every step is
normed afterwards.

```julia
# θ = (t − tₙ)/h, and every σ(θ) is a trial evaluation: write the state, run
# the interior sweep, evaluate the guard.
σ₁ = σ(1)                              # already computed by the arrival sweep
(prior not-holding && σ₁ holding) || return    # no trigger, nothing to localize

σ₀ = σ(0)                              # the θ = 0 validation: x̂(0) = xₙ, no interpolant
σ₀ holding && return                   # epoch-caused edge: fall through to tₙ₊₁

build x̂ from (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁)      # one sweep for ẋₙ₊₁, paid only here
lo, hi = 0, 1                          # the not-holding / holding bracket, in θ
while hi - lo > localization_tol       # relative: bracket width (hi − lo)·h vs. tol·h
    θ = next bracketed guess in (lo, hi)       # ITP, Brent or bisection
    σ(θ) holding ? (hi = θ) : (lo = θ)
end
t* = tₙ + hi·h                         # the holding endpoint of the final bracket
```

**On trigger, the first act is a trial evaluation at the left end**, the θ = 0
validation ([D-182][d-182]). Write xₙ into the state buffer, run one interior
sweep, and evaluate the guard to get σ₀. Nothing new is kept, since the stepper
already retains xₙ for the interpolant. This trial evaluation needs no
interpolant, because x̂(0) = xₙ identically. So it runs before any interpolant
cost is paid.

The evaluation serves two purposes. σ₀ is the left bracket value that
value-based root-finders need. σ₁ = σ(tₙ₊₁) is retained from the arrival
evaluation, but σ₀ had no source until now. And σ₀ tells the edge's cause apart.

That discrimination needs one term. An [input epoch](#g-input-epoch) is a maximal span of
constant `u`, delimited by frame-top drains ([§11.4][s11-4]). Within an epoch a
guard can change only through the trajectory. At a seam between epochs it can
jump without crossing anything.

The discriminator is conclusive ([D-182][d-182]). `u` is the only thing that can
differ between the prior's evaluation context and this trial evaluation. `m`
changes only via handlers at boundaries, and priors are sampled at quiescence,
after the handlers. Discrete cells hold their values under zero-order hold
(ZOH), and the interior sweep excludes discrete entries ([§10.5][s10-5]).
`t = tₙ` exactly, by the indexed-grid rule below. Sweeps are deterministic. So
under the honest priors of [§10.6][s10-6], the frame-top drain is the only
possible source of disagreement.

- σ₀ not-holding means a trajectory-caused edge, a genuine in-frame crossing.
  Pay the sweep for ẋₙ₊₁, build the interpolant and root-find on the bracket
  $(t_n, \sigma_0)$/$(t_{n+1}, \sigma_1)$.
- σ₀ holding means an epoch-caused edge. The drain flipped the guard at the
  frame top. σ holds at both ends, so there is no in-frame crossing to find.

**An epoch-caused edge is discarded, not degraded** ([D-182][d-182]). The
localization is abandoned and the event fires inside tₙ₊₁'s ordinary iteration.
Mechanically, not localizing is the action. The frame falls through, and the
boundary iteration detects and fires the event like any boundary-detected event.
This path costs one interior sweep. It never pays for ẋₙ₊₁ or an interpolant,
and it consumes no `localization_budget` (see "The localization budget" below).
It also warns nothing. Input timing is a frame fact, by the same doctrine that
forbids draining at `t*` below, and boundary detection is exact for a `u`-caused
edge (above; [D-179][d-179]). Boundary firing is therefore the correct
semantics, not a degradation. This is the left-end mirror of the `t* = tₙ₊₁`
degeneracy below.

The interpolant is the seam's dense output ([§10.2][s10-2]). It is built lazily
([D-018][d-018]). It is the cubic Hermite continuous extension
$\hat{x}(\theta)$, $\theta = (t - t_n)/h \in [0, 1]$, built from
$(x_n, \dot{x}_n, x_{n+1}, \dot{x}_{n+1})$. $\dot{x}_n$ is the step's first
stage. $\dot{x}_{n+1}$ costs one sweep, paid only on a validated trigger
([D-182][d-182]). The θ = 0 trial evaluation comes first, so an epoch-caused
edge never pays for it. Uniform accuracy is $O(h^4)$, one order below the
discrete solution, which is the standard pairing. The event time can never be
more accurate than the interpolant, so nothing more expensive is worth running
trials against.

**Root-finding is bracketed and derivative-free** ([D-018][d-018]). ITP (the
interpolate-truncate-project method) or Brent's method are the intended
methods, and bisection is an acceptable fallback. The observed
not-holding/holding bracket is an unconditional convergence certificate. Newton
and AD (automatic differentiation) localization are rejected ([D-018][d-018]).

**Convergence is a relative bracket width** ([D-133][d-133]). Localization stops
once the bracket is narrower than `localization_tol · h`. `localization_tol` is
a constructor keyword of the [`Deployment`](#g-deployment) (the scalar-free
artifact the grid parameters fix) and defaults to `1e-6` ([D-256][d-256]). The
tolerance is relative because an absolute tolerance in `t` is not scale-free
([D-133][d-133]). The default is `1e-6` because of the interpolant's accuracy
limit, `O(h⁴)` as stated above. At practical `h`, anything tighter buys nothing,
while every trial evaluation costs a full sweep. Under ITP the bill is a handful
of trial evaluations, and around 20 in bisection's worst case.

After the event, the boundary sequence runs at `t*` (below). The interpolant is
then invalidated, because the handlers have made it wrong for `t > t*`
([D-018][d-018]). Integration resumes from `t*` with the
[remainder step](#g-remainder-step) (the integration from `t*` to the original
grid target) targeting tₙ₊₁, and the guards are re-checked on the remainder. The
re-check runs under the per-frame [localization budget](#g-chattering) (below),
with a chattering diagnostic.

Multiple events localizing in one step fire at the earliest `t*`. Ties fire at
that boundary inside the event iteration, one eligible event per component per
round in declaration order ([§10.6][s10-6], [D-154][d-154]). Later crossings
re-localize on the remainder.

Both policies share one blind spot. An even number of crossings within one step
returns the predicate to not-holding at the boundary, so no edge is observed.
Neither policy can detect this. The mitigation is a smaller step size, not more
machinery.

#### Endpoint policy and grid integrity

**The root-finder returns the holding endpoint of its final bracket**
([D-082][d-082]). That is the smallest trial point where the predicate holds.
It follows that `t* = tₙ` is structurally impossible. It never needs clamping
away.

The argument rests on what was measured, not on what the prior reports.
Root-finding starts only after the θ = 0 validation has measured σ₀ not-holding
under the frame's own `u`. The bracket's left end is therefore not-holding by
the same kind of evidence as its right end. The returned point is thus
strictly later than the published, immutable tₙ. In the worst rounding case it
is `nextfloat(tₙ)`. This holds unconditionally, with no appeal to the prior.
It also leaves no residual epoch hole, because the case where the prior and
the frame's `u` disagree is exactly the epoch-caused edge, and that case
never reaches the root-finder ([D-182][d-182]).

The guard also observably holds at `t*` ([D-082][d-082]). Handlers therefore
fire in states where their own predicate holds, and the post-fire prior
records an actual observation rather than an assumption.

`t* = tₙ₊₁` exactly is legitimate ([D-082][d-082]). It is a crossing at
the grid point, where σ(tₙ₊₁) = 0 both triggers detection and is the root. It
degenerates to the grid boundary. The localization result is discarded and
the event fires inside tₙ₊₁'s ordinary iteration. That outcome is bitwise
identical to the boundary-detected one, with one boundary, one
[snapshot](#g-snapshot) (the immutable per-boundary publication) and no
zero-length remainder.

**Grid times are indexed, never accumulated** ([D-082][d-082]). `tₖ = t₀ + k·h`
is computed from the frame index, just as tick gating is already counter-modulo
([§10.5][s10-5]). The remainder step targets the grid point, with `h′` (the
remainder step's length) derived at use. `t*` is a float inside a frame, never
an anchor from which anything else is computed. A near-degenerate `t*` leaves a
tiny remainder step. Numerically that is harmless, since increments scale with
`h′`. The real hazard is bookkeeping, and this rule removes it.

#### The `t*` boundary

**At `t*` the full [§10.6][s10-6] event phase runs** ([D-081][d-081]). The
sweep → guards → handlers cycle iterates to quiescence. Firing-budget
accounting is scoped to this boundary ([D-181][d-181]). The budget is fresh
again at tₙ₊₁, and again at a second `t*` on the remainder.

The settled state is then published. That means a snapshot, the
boundary-counter increment of [§12.3][s12-3] and the [`stop_on`](#g-stop_on)
check (the read of the termination faces `stop_on` names, [§13.5][s13-5]). A
crash localized at `t*` ends the run from that snapshot.

Two things do not happen at `t*`. Ticks are never due there
([D-147][d-147]). `t*` is off the [harmonic grid](#g-harmonic-grid) (every
discrete period an integer multiple of `Δt_base`) by construction, and
discrete cells ZOH-hold through the sweep. The due sets of [§10.5][s10-5] give
the full reason. **Staged inputs are not drained either** ([D-081][d-081]),
for two reasons. Input timing is a frame fact, and the determinism of
[replay](#g-replay) (the ordinary loop re-driven from the trace) must not
depend on localization arithmetic.

**The `t*` publication is not separately paced** ([D-081][d-081]). The
[pacer](#g-pacing) (which inserts waits between completed frames) paces frame
deadlines. A `t*` snapshot publishes when computed, mid-frame. Where that
lands in wall-clock time is below what pacing resolves. The invariant of
[§10.7][s10-7] is about trajectories, and those are identical either way.

Replay pointers and error messages index boundaries by the frame-entry
boundary index ([§13.4][s13-4], [D-128][d-128]) together with the recorded
`t`. Snapshots carry the trajectory's published-boundary ordinal
([§12.3][s12-3], [D-230][d-230]). The trace stays frame-indexed, since `t*`
boundaries consume no inputs.

[Projection](#g-projection) (the optional per-component hook
`x ← x_projection(x)`) reaches the boundary, not the trial evaluation. **Guard
trial evaluations run against the raw interpolated state** ([D-018][d-018]).
Authority rests with the `t*` boundary. Projection runs there, and the edge
checks of the [§10.6][s10-6] iteration read the projected state. RK-stage RHS
evaluations already run under the same rule, since they are equally
off-manifold. Sweeps must therefore tolerate near-manifold states, and they
already do. Per-trial projection is rejected ([D-018][d-018]).

If projection moves the state back across a guard, the event does not fire
and the run has published one extra boundary. That is harmless. Like any
other localization outcome, it is deterministic and pace-independent
([D-080][d-080]).

#### The localization budget

`localization_budget` is the integer count of localizations permitted within
one frame. **Its default is 8** ([D-133][d-133], [D-181][d-181]). It is the second
deployment keyword this section fixes.

A legitimate multi-event frame needs three or four localizations. Three
landing-gear struts touching down inside one step is the reference case.
Chattering needs tens. A budget of 8 therefore bounds the pathology without
ever binding on a healthy model.

**Budget exhaustion degrades; it does not throw** ([D-018][d-018]). When a
frame spends its budget, localization stops for the rest of that frame. The
remainder step completes, and any further crossings fire in the next
boundary's ordinary iteration, at boundary granularity for that frame. A
`ChatteringBudget` warning ([Appendix C][sC]) names the chattering event and
the localization count.

The degradation depends on the trajectory alone, never on wall clock. The
pace-independence guarantee ([D-080][d-080]) therefore stands, and the run
replays identically. A `StepError` ([§13.4][s13-4]) here would misclassify an
expected modeling outcome as broken machinery, which the no-throw doctrine of
[§14.8][s14-8] forbids.

#### Deployment constants

Both localization constants are deployment, not implementation.
`localization_tol` and `localization_budget` are constructor keywords of the
`Deployment`. They stand beside `h`, `N_base` and the algorithm ([§9.2][s9-2],
[Appendix B][sB], [D-256][d-256]). The constructor validates them with the third
such keyword, the `firing_budget` of [§10.6][s10-6], and failures are collected
into `DeploymentInvalid`, as [§9.2][s9-2] and [Appendix C][sC] set out. All
three are grid-independent, so none enters the harmonic-grid check
([§10.5][s10-5]).

All three are recorded ([D-133][d-133], [D-181][d-181]), because they determine
the trajectory. They ride the `Deployment` in the
[trace header](#g-trace-header) (the trace's fixed preamble, [§11.5][s11-5]).
They also join the set that replay compares up front, exactly as `h` and the
algorithm do ([§12.7][s12-7]).

Without this record, the replays-identically promise above is empty. A run
that does not record what its localizer was told to do cannot be re-driven
through the same localization outcomes.

### 10.5 Multi-rate tick scheduling

A model runs several clocks at once. The integrator advances on the continuous
step `h`. An inner control loop samples at one rate, an outer loop at another,
and a receiver at a third. Each of those must hold its outputs steady between
its own firings. For that to be well-defined, three things have to be fixed.
They are the time lattice every rate shares, the test that decides which
components run at a given [boundary](#g-boundary) (a published consistency
point), and the surface an author declares a rate on. This section fixes all
three, in that order.

#### The base grid and the gate

**Every discrete [component](#g-component)'s period is an integer multiple of a
base [tick](#g-tick) period `Δt_base`** ([D-019][d-019]). `Δt_base` is itself
an integer multiple of the continuous step, with `N_base` steps per base tick
($\Delta t_{\mathrm{base}} = N_{\mathrm{base}} \cdot h$, $N_{\mathrm{base}} \ge 1$).
That is the [harmonic grid](#g-harmonic-grid). Ticks therefore land on step
boundaries, which is the only place anything discrete ever happens.

[Frames](#g-frame) (iterations of the loop) are counted by the frame index
`k`. The frame top at `t = t₀ + k·h` is a base tick exactly when `k` is a
multiple of `N_base`. Its [tick index](#g-tick-index) is then
`tick = k ÷ N_base`. A frame top that is no base tick has no tick index, and
neither does a boundary at a localized event time `t*`
([§10.4][s10-4], [D-185][d-185], [D-288][d-288]).

However an author declares a rate, and however deeply the declaration is
nested, **the build compiles it to two integers per discrete component**
([D-185][d-185]). The divisor `D` is the component's period in base ticks. The
[phase](#g-phase) `Φ` is its offset in base ticks. The pair is kept in the
canonical residue `0 ≤ Φ < D`, so the component's ticks fall at base-tick
indices `Φ`, `Φ + D`, `Φ + 2D`, and so on.

**A component is [due](#g-due) at a boundary when `(tick − Φ) % D == 0`**,
where `tick` is the boundary's tick index ([D-185][d-185]). That subtraction
and remainder are the whole admission test. It costs one subtraction more than
a phase-free test would, over a lattice fixed at build time. The declaration
surface below says where a component's `(D, Φ)` comes from.

#### Zero-order hold and the two sweep variants

**A discrete component's `y_state`/`y_direct` run only at its own ticks**
([D-019][d-019]). Its [cells](#g-cell) (its entries in the
[signal table](#g-signal-table)) hold in between. This is zero-order hold
(ZOH), stated in [sweep](#g-sweep) terms. A sweep is one pass through the
[execution order](#g-execution-order). The reason for the hold is that
re-running a discrete component's stages at every boundary would un-sample a
sampled-data controller.

**Delivering that hold takes two statically distinct sweep variants, compiled
from one entry list** ([D-147][d-147]). Discreteness is a build-time fact, so
the split is static rather than a runtime test.

- The interior sweep walks continuous entries only ([D-147][d-147]). RK
  stage evaluations ([§10.3][s10-3]) and localization [guard](#g-guard) trial
  evaluations ([§10.4][s10-4]) run this variant. The ZOH therefore holds
  mid-step by construction. Discrete entries are not gated out at runtime.
  They are absent from the walk at compile time, so the hot path carries no
  gating test at all.
- **The boundary sweep walks the full list**, with discrete entries gated by
  `(tick − Φ) % D` against the boundary's tick index ([D-147][d-147]). It is
  the variant the [§10.6][s10-6] macro-sequence runs. It is not one fixed list
  either, because different boundaries run different subsets of the execution
  order.

**The split applies to both sweep blocks** ([D-147][d-147]). The discrete
[tier](#g-tier)'s `y_state` entries are absent from the interior stage-1 walk,
exactly as its `y_direct` entries are absent from the interior stage-2 walk.
The two sweep variants surface in the phase-body signatures: interior bodies
take no arguments, boundary bodies take the tick index ([§9.7][s9-7]).

#### Due sets

**The due set is computed once for the boundary and reused by every re-sweep
of its [quiescence](#g-quiescence) iteration** ([D-147][d-147]). Quiescence is
the fixed point where a round of handlers fires nothing ([§10.6][s10-6]). The
due set is a property of the boundary, not of the sweep call. That holds
because a due component is at its tick instant for the whole boundary, not for
one round of it.

Each kind of boundary has its own due set:

- At a tick frame top (every `N_base`-th frame top), the due set is every
  discrete component whose gate admits the tick index. These are the `(D, Φ)`
  pairs with `(tick − Φ) % D == 0`.
- At an off-tick frame top (a frame top with `N_base > 1` that is no base
  tick), the due set is empty. The tick counter has not advanced, so no
  component is at a tick instant.
- At a `t*` boundary, the due set is empty for the same reason. A modulo test
  against the unadvanced index would wrongly re-admit the previous tick's due
  set.
- At [boundary zero](#g-boundary-zero) (the initialization boundary, which
  runs the ordinary macro-sequence with an empty integrate), the due set is
  everything with `Φ = 0` ([D-185][d-185], [D-205][d-205]). At tick index 0 the gate reads
  `(0 − Φ) % D == 0`. Under the canonical residue `0 ≤ Φ < D` that holds if
  and only if `Φ = 0`. Nothing implements this rule. It falls out of the
  ordinary gate. Dueness at boundary zero governs the `s_update` calls alone.
  Output stages publish due or not ([D-205][d-205]), as [§14.5][s14-5]
  specifies.

An offset component's first tick is at `Φ·Δt_base`. Until then its cells hold
its boundary-zero publication. Its output stages still run at `t₀`, as above,
evaluated from the authored world ([D-205][d-205], [§14.5][s14-5]). The
[probe](#g-probe)'s synthesized values reach no published cell. The probe is the
build's single evaluation of a user function with real values ([§9.3][s9-3]). In
a phase-free model every `Φ` is 0, so at boundary zero everything is due and the
distinction is empty.

#### Simultaneous ticks

Several components can be due at one boundary, and settled machinery already
orders them. All due components run their output stages in topological order
within the sweep. All due `s_update` calls run after quiescence, in any order.
Each one reads the table and writes only its own `s` store. The intra-tick
ordering of a flight control system (FCS) cascade, where outer loops feed an
inner loop, is therefore a sweep property, not an update-order property.

#### Assemblies and rate scopes

**An [assembly](#g-assembly) is virtual for execution** ([D-019][d-019]). Its
children are scheduled individually, and the assembly itself never runs as a
unit. For declaration, a [rate scope](#g-rate-scope) is an assembly's
`sample_times` declaration against the enclosing scope. There are no atomic
assemblies, and no opt-in variant ([D-019][d-019]).

No coarsening is needed, because the signal table makes interleaving
semantically invisible. Consumers read cells whose freshness is guaranteed by
topological order rather than by contiguity.

#### The two declaration forms

A discrete component or sub-assembly is scheduled by a `sample_times` entry in
its enclosing assembly ([§8.7][s8-7]). **The entry declares one (period,
phase) pair in one of two unit systems**, and the wrapper type names the unit
system ([D-185][d-185]). The two forms thus declare one concept, a sample
time, in different units.

| entry | unit system | tick instants | constraints |
|---|---|---|---|
| `Relative(K, Φ = 0)` | scope ticks | every `K`-th tick of the enclosing scope, starting from its `Φ`-th | `K ≥ 1`, `0 ≤ Φ < K` |
| `Absolute(q, τ = 0)` | seconds | `t = τ + k·T`, with `T = period(q)` | `T > 0`, `0 ≤ τ < T` |

`K = 1` therefore admits no stagger ([D-185][d-185]). Two same-rate siblings
are staggered one level down instead. Declare the scope at twice their rate,
then give them `Relative(2, 0)` and `Relative(2, 1)`.

`q` is a quantity value, `Period(1//50)` or `Hz(50)`. The two are a spelling
choice, normalized to the rational period at construction. Every period and
offset is an exact `Rational{Int}`, because grid derivation is GCD arithmetic
and ill-defined over floats. A float argument throws the teaching error naming
the exact spelling (`Period(1//50)`, or `Hz(1//2)` for 0.5 Hz).

The wrappers are the whole vocabulary ([D-185][d-185]). A bare integer or bare
quantity is a declaration error. An unlisted discrete child defaults to
`Relative(1)`. The common case therefore costs nothing, and a multiplied or
anchored child (one declared `Absolute`, below) always appears explicitly.

Validation belongs to the structure step (the build's declaration-reading
step), which collects it with path attribution ([§9.1][s9-1], [§13.1][s13-1],
[D-185][d-185]). It covers `K ≥ 1`, `0 ≤ Φ < K`, `T > 0`, `0 ≤ τ < T`, and
keys naming discrete or scope children. The constructors themselves are plain
data carriers, with no checks of their own.

#### Relative composition

Multipliers compose multiplicatively and phases affinely down the tree
([D-019][d-019], [D-185][d-185]). Under a scope compiled to divisor and phase
`(D_s, Φ_s)` in base ticks, a child declared `Relative(K, φ)` compiles to
`D = K·D_s` and `Φ = Φ_s + φ·D_s`.

Composition preserves the canonical residue `0 ≤ Φ < D`.
`companions/sample_time_proposal.md` (the declaration design's worked companion)
carries the one-line induction. All scoping therefore compiles away at build to
one `(D, Φ)` pair per discrete component. The boundary sweep gates on that pair
with the `(tick − Φ) % D == 0` test above. The lattice stays static, and the
interior sweep still holds no discrete entries to gate.

Relative is the default form because, in a layered control architecture, the
*ratios* are intrinsic to the design and travel with the assembly type. The
inner loop runs at `Relative(1)` and the outer loops at `Relative(5)`,
whatever the deployment. One convention keeps `K ≥ 1` livable. A scope's base
rate is its fastest relative member, and that member gets `K = 1`.

Two structural properties keep a relative entry on the scope grid and confine
grid cost to the other form. **A relative phase never refines the base grid**,
because it selects among scope ticks that already exist ([D-185][d-185]). It
also cannot place a tick *between* scope ticks. Staggering off-grid means
declaring the offset in seconds, or declaring the scope base finer than its
fastest member so that unused slots exist.

#### Anchors

**An `Absolute` entry may appear in any scope's `sample_times`, not only the
root's** ([D-186][d-186]). The `(T, τ)` pair it establishes is an
[anchor](#g-anchor), and the child hangs from that anchor. The child is
severed from the enclosing scope's grid, and no relation to the scope's ticks
remains.

Three corollaries follow ([D-186][d-186]):

- `K ≥ 1` reads "a child cannot tick faster than the scope it is *relative*
  to". An anchored child may therefore tick faster than its scope.
- The fastest-member convention counts relative members only.
- Phase relationships between an anchored child and its relative siblings are
  deployment-emergent. Whether their ticks ever coincide depends on how the
  grid derivation works out. The deployment's [`Schedule`](#g-schedule) (the
  per-component `(D, Φ, Δt)` table the `Deployment` carries) exists to answer
  that question ([§9.2][s9-2]).

Relative children *of* an anchored subtree compose against the anchor exactly
as against the root grid ([D-186][d-186], [D-283][d-283]). A nested anchor simply severs again
(the fold, [§9.1][s9-1]).

**Absolute periods and nonzero offsets jointly constrain the base grid**
([D-186][d-186], [D-283][d-283]). They join the deployment-time constraint pool
([§9.2][s9-2]). This is the subtle part, and it has a real cost. An offset of
`T/2` can cost a 2× finer grid, and `T/1000` a 1000× one. The cost is
relational, incurred against everything else declared. That is why
attribution is the engine's job ([§9.2][s9-2]).

#### When an anchor belongs in a library type

Absolute-first declaration as the default form is rejected ([D-019][d-019],
[D-186][d-186]). What mid-tree anchors legitimize is narrower, and the
doctrinal line falls here. **An absolute declaration inside a library type is
legitimate when the rate is a fact about the modeled system, not a preference
about the simulation** ([D-186][d-186]).

A GPS receiver emitting at 1 Hz, a data bus's transmission schedule and an ADC
(analog-to-digital converter) pipeline's fixed conversion offset are as
intrinsic to the assembly as its wiring. Forcing them to the root breaks
encapsulation, since the root would have to know instrument internals to
re-declare them.

"Run the controller at 400 Hz in this study" remains a deployment choice, and
the existing idiom remains its answer. The assembly exposes its multiplier as
a constructor parameter. Absolute pinning *from outside* a subtree's
[contract](#g-contract) (its declared interface) stays rejected as action at a
distance.

The framework cannot police the distinction. It is authoring doctrine,
recorded here.

**Anchoring leaves the never-cache-`Δt` argument below fully intact**
([D-186][d-186]). The pinning happens in the enclosing assembly's
`sample_times`, the same site where the multiplier lives. The component type
itself therefore stays rate-agnostic. It still consumes the `Δt` of its
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives).

#### A worked example

This example follows one declaration to its compiled pairs and one hyperperiod
(the span after which the tick pattern repeats). Three discrete components sit
under two scopes, at a deployment that binds `Δt_base = 2 ms` ([§9.2][s9-2]).
The root scope holds `fcs`, an FCS scope, and `gnss`, a satellite-navigation
(GNSS) component.

```julia
# Root scope: (D_s, Φ_s) = (1, 0).
sample_times(::Vehicle) = (fcs  = Relative(1),        # → (D, Φ) = (1, 0)
                           gnss = Absolute(Hz(50)))   # → (10, 0), anchored at T = 20 ms

# fcs is the enclosing scope of its own children, at (D_s, Φ_s) = (1, 0).
sample_times(::FCS) = (inner = Relative(1),           # → (1, 0)
                       outer = Relative(5, 2))        # → (5, 2), D = 5·1, Φ = 0 + 2·1
```

Those pairs are what the boundary gate reads at run time. One hyperperiod is
`lcm(Dᵢ) = 10` base ticks. Because the gate is pure modulo arithmetic, that
one hyperperiod is the complete truth rather than a sample ([§9.2][s9-2]):

```
base tick k:  0  1  2  3  4  5  6  7  8  9 | 0  1  …
inner         •  •  •  •  •  •  •  •  •  • | •  •       (D, Φ) = (1, 0)
outer               •              •       |            (5, 2)
gnss          •                            | •          (10, 0)
```

`outer` is due where `(k − 2) % 5 == 0`, `gnss` where `k % 10 == 0`. Should
`outer` read a `gnss` cell, the ZOH makes that read two base ticks old at
`k = 2` and seven at `k = 7`.

#### Coincidence and stagger

Coincidence and stagger are modeling choices with observable consequences.
Coincident ticks give a consumer fresh same-instant reads via topological
order. That is the idealized synchronous-sampling picture. A phase stagger
makes the same reads pipelined and deterministically aged instead. That is the
structural expression of an acquisition pipeline's latency, obtained with no
delay blocks. The two-tick and seven-tick reads in the example above are the
deterministic aging of a stagger, in that model's numbers.

A stagger is also a load-shaping tool under real-time [pacing](#g-pacing) (waits
inserted between completed frames, never altering the boundary sequence).
Staggered stacks never share a frame, so worst-case frame cost is a `max` rather
than a sum ([§10.7][s10-7]).

Both patterns are worked in `companions/sample_time_proposal.md`, together with
how silently an offset edit rewires a coincidence structure. The `Schedule` and
its hyperperiod chart ([§9.2][s9-2]) are how a user audits which pattern a model
actually has.

#### `Δt` in the bundle

`Δt` has a single source of truth, the deployment's `Schedule`
([D-187][d-187], [D-254][d-254]). **Each discrete component's effective period
arrives read-only as the `Δt` field of every discrete-tier bundle**
([§5.2][s5-2], [D-019][d-019]). The field arrives in `y_state`, `y_direct` and
`s_update` alike. It is absent from continuous bundles, so touching it on the
wrong tier is a missing-field error rather than a rule.

The field must be readable in the *stages*, not just in `s_update`. The
discretized laws that actually consume `Δt` run in `y_direct`, which computes
each law once and publishes it ([§5.3][s5-3], [D-015][d-015]). A PID
controller's backward-difference coefficients and a lead-lag compensator's
Tustin transform are the examples. `s_update` is a copy.

The value must arrive through the call, and the bundle field is where it
arrives. A `comp.Δt` virtual property is impossible here, not merely
inconvenient ([D-019][d-019]).

An author must never store `Δt`, or any `Δt`-derived coefficient, as a
component parameter ([D-019][d-019]). Recomputing derived coefficients per
tick is a few arithmetic ops. A cached copy is a second thing for
gain-scheduling machinery to chase.

Relative declaration structurally enforces that author rule for the period
itself. Under scoped multipliers a component author *cannot* know their
absolute rate. It does not exist until composition.

Phases change none of this. **The bundle's `Δt` is still `D·Δt_base`**
([D-185][d-185]). An offset shifts firing instants and never the period, so
the discretized laws are unaffected by staggering.

### 10.6 Event iteration at boundaries: to quiescence, budgeted

[§5.3][s5-3] leaves two questions open. How far does the event phase run at a
[boundary](#g-boundary) (a published consistency point, where the
macro-sequence completes), and how often may each event fire while it does?
This section answers both.

**The phase iterates** ([D-020][d-020]). One round re-runs the
[boundary sweep](#g-sweep) (the pass over the full execution order, with due
discrete entries gated in), evaluates all [guards](#g-guard) (the declared
functions defining each event's predicate) against it, and fires the eligible
events. **A [component](#g-component) fires at most one event per round**
([D-154][d-154]). Each firing is `handler → x_projection`. Rounds continue to
[quiescence](#g-quiescence), the fixed point where a round of handlers fires
nothing.

**An event fires in an iteration round if and only if three conditions hold**
([D-181][d-181]):

- Its [predicate](#g-predicate) is observed holding in that round.
- The sample observed before it was not-holding.
- The event's firing count for this boundary is below `firing_budget`.

That is the whole definition of "newly fired". The predicate is the one
[§2.1][s2-1] defines, either the `Bool` form true or `σ ≥ 0`.
[`firing_budget`](#g-firing-budget) is a deployment keyword, an integer ≥ 1
defaulting to 4. It caps how many times each declared event may fire at one
boundary.

#### Why the phase iterates

Under a single pass, a cascade of N logically simultaneous transitions
(supervisor FSM → subordinate FSM → …, where an FSM is a finite-state machine)
takes N steps to complete, at latency N·h. Model semantics would then depend on
the integrator's step size, and `h` is an execution parameter. This is the same
class of footgun [§2.2][s2-2] cited when killing `f_step!`, an unconditional
per-step hook ([D-020][d-020]). Cascades are not a corner case either.
Externalized FSM components are blessed ([§3.1][s3-1]), which makes
cross-component cascades the expected idiom.

Established practice agrees. Hybrid automata take sequences of instantaneous
transitions at one time point. Modelica iterates events to quiescence.
Stateflow runs charts to completion within a [tick](#g-tick) (an instant at
which a discrete component's stages and update run).

Boundary-detection timing remains h-dependent, but that is a different
quantity. It is the resolution at which a physical crossing is noticed. The
cascade delay would have been structure the framework inserts between
transitions the model declares simultaneous.

#### The three registers

Three registers per event decide the rule, all named normatively.

- The [prior](#g-prior) is the previous boundary's quiescent sample. The
  boundary's first round tests against it.
- The *last-observed sample* is initialized from the prior when the boundary
  opens and overwritten by every round's evaluation. Every later round tests
  against it. There is one exception. An event that was eligible but blocked
  (below) keeps its sample, because blocking defers its edge rather than
  consuming it.
- The *firing count* for the boundary is incremented at each firing and reset
  when the boundary ends.

Eligibility inside a boundary is therefore an [edge](#g-edge-semantics) like
any other. It is a not-holding → holding transition, never a bare sign change.
What differs is the reference sample. The edge is read against the
last-observed sample, not against the prior the boundary entered with
([D-181][d-181]).

Two consequences follow. Sticky predicates need no special case. An event that
fires and keeps holding presents no further not-holding → holding edge, so it
fires once, at the boundary where it first held. And a predicate that is
genuinely falsified and re-enabled inside the boundary, because another
handler's cascade reverted its effect, fires again at this boundary against a
fresh sweep ([D-181][d-181]).

The sketch below shows one boundary's iteration.

```julia
# entering the boundary, per event:  last ← prior,  count ← 0
while the previous round fired something   # the first round always runs
    boundary sweep                         # the whole boundary sweep, due set fixed for the boundary
    per event:      eligible ← last not-holding && now holding && count < firing_budget
    per component:  firing ← its first eligible event, in declaration order
    per event:      last ← now, unless eligible and not firing   # a blocked edge stays unconsumed
    fire the firing events                 # handler → x_projection, count += 1
end                                        # the exit condition is quiescence
per event:  prior ← last                   # the settled boundary's honest sample
```

The prior is updated at each boundary's quiescence, from the final
post-iteration samples ([D-082][d-082]). The update is unconditional. Every
prior is therefore an honest observation of a settled boundary. That is what
makes the θ = 0 discriminator ([§10.4][s10-4]) conclusive.

All three registers are detection bookkeeping, not model memory. They are
correctly absent from every state store ([D-082][d-082]). A
[checkpoint](#g-checkpoint) (the executor's state at a frame top, as one value)
carries the prior, the one register that crosses a boundary ([§12.6][s12-6],
[D-274][d-274]). The [trace header](#g-trace-header) (the trace's fixed
preamble) is such a checkpoint. `restore!` copies a checkpoint's prior back
([D-274][d-274]). The other two registers are reset on entering each boundary,
as the sketch shows. Beyond the prior, the cost is one `Bool` and one small
counter per event.

[Boundary zero](#g-boundary-zero) is the initialization boundary. **Boundary
zero sets every prior to not-holding** ([D-082][d-082]). A predicate already
holding in the authored state therefore fires at `t₀`. That behavior
([§14.5][s14-5]) is derived rather than asserted. A re-run from a
[condition](#g-condition) (a path-addressed overlay that sets the build to a
state, [§14.1][s14-1]) resets all three registers from scratch, because `init!`
re-runs boundary zero ([§14.5][s14-5]). Predicates holding in the newly applied
state fire again at the new `t₀`. A `restore!` keeps the checkpoint's priors and
runs no boundary zero, so nothing holding re-fires ([§12.6][s12-6],
[D-274][d-274]).

#### What a handler sees within a round

Each round re-runs the whole boundary sweep, gated entries included
([D-020][d-020]). The reason is that a transition reaches the
[signal table](#g-signal-table) (the framework-owned cells holding every
produced signal) only through a sweep. A handler writes its component's state
stores and nothing else. So neither the transitioning component's own
[ports](#g-port) (each one declared name with its cell) nor the downstream
`y_direct` chains that read them have moved. The cost is negligible. Sweeps take
microseconds, and rounds beyond the first require an actual cascade.

Within a round, the signal table has a single writer, and it is the sweep
([D-154][d-154]). A handler writes nothing to the table. It returns
transitions, the framework latches them into the component's state stores, and
`x_projection` normalizes them. Nothing moves the table mid-round.

This gives the epoch rule, which is the core of this section. An epoch here is
the world one round's sweep produces. It is not the input epoch of
[§10.4][s10-4]. **A handler executes against exactly the world its guard fired
on** ([D-154][d-154]). Its own `y`, foreign `u` and its own `x`/`m` all come
from the firing round's sweep, so `y = h(x)` holds at every handler entry. No
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives) ever straddles two epochs.

Serialization is what delivers the epoch rule. A component's state stores are
written only by its own handlers, and it fires at most one event per round, so
no same-round writer precedes any handler's entry.

**A component's other eligible events are blocked, not lost**
([D-191][d-191]). Each is re-decided in the next round, against the
post-transition sweep ([D-154][d-154]). Declaration order is therefore a
priority with re-decision, not a simultaneity. An event whose premise the
earlier transition falsified simply does not fire. Under a within-round
sequence it would have fired on the stale premise.

Blocking is visible in the registers ([D-191][d-191]). An eligible-but-blocked
event is the one case whose last-observed sample is not overwritten, so the
edge it presented stands unconsumed. A guard that keeps holding therefore fires
in the next round on that same edge. One that the transition falsified records
not-holding as usual, and any later re-rise is a fresh edge. The prior stays
honest at no cost. The quiescent round fires nothing, hence blocks nothing, so
every sample takes its final update before the prior is written.

Across components, handler order within a round is semantically unobservable
([D-154][d-154]). The reason is stronger than serialization. There is no
delivering mechanism at all. Nothing writes the table mid-round, so there is
nothing for order to observe.

Execution order is fixed all the same. It follows the component order of the
[executor](#g-executor) (the compiled form of the stage execution order), then
declaration order within a component. That keeps the [execution cursor](#g-execution-cursor) (the
loop-state field recording where execution stands, [§13.4][s13-4]) and the
diagnostics stream deterministic. No trajectory depends on it. The natural
single-pass executor is therefore exactly correct. It builds each handler's
bundle at dispatch, from the live table. It needs none of the extra machinery
that [D-154][d-154] made unnecessary, and it allocates nothing.

The trade, stated openly, is that **a handler cannot opt into seeing a
same-round foreign transition** ([D-100][d-100]). Same-instant sequential
coupling across components is a cascade, one round per link, deterministic.
Coupling tighter than that belongs inside one component, where declaration
order gives exact sequencing across rounds. This is the position of the
synchronous languages. A micro-step sees the pre-state, and effects appear at
the next micro-step.

Serializing same-component firings costs one extra intra-boundary sweep per
event so serialized, which is microseconds on the rare boundary that fires at
all. [D-154][d-154] and [D-100][d-100] record the rejected shapes.

#### The firing budget

A per-event firing budget lets a re-enabled event fire at its true boundary,
against a fresh sweep. Priors stay honest as a consequence. Every prior is a
sample actually taken, never a value recorded to make a rule work out. The
deferral design and the rounds cap are both rejected ([D-020][d-020],
[D-181][d-181]). The deferral design fired a re-enabled event one step late,
through a manufactured not-holding prior ([D-181][d-181]). The rounds cap
bounded the number of rounds at a boundary ([D-020][d-020]).

Termination is then budget-bounded rather than structural. For `E` declared
events, a boundary admits at most `firing_budget · E` firings, hence a bounded
number of rounds, deterministically and independently of pace. A livelock, such
as two FSMs toggling each other, does not resolve silently. Each toggler spends
its budget and warns (below). The run proceeds, and its [replay](#g-replay) (the
ordinary loop re-driven from the trace) is identical. This is degradation, not
an error, per the doctrine of [§10.4][s10-4]. The warning names the actual
chatterer, while every other event's iteration continues untouched.

This trade is also stated openly. Because termination is budget-bounded rather
than structural, the objection that a rounds cap is an arbitrary knob
([D-020][d-020]) lives on in `firing_budget`. [D-181][d-181] records what that
buys.

**Budget exhaustion degrades; it does not throw** ([D-181][d-181]). When an
event has fired `firing_budget` times at a boundary, its further edges there
are lost for the rest of that boundary. The eligibility test skips it while
every other event iterates normally. A lost edge emits a `FiringBudget` warning
([§13.2][s13-2], [Appendix C][sC]), at most once per event per boundary. An
event that fires its budget out and then quiesces lost nothing and warns
nothing. The warning carries the component path, the event name, the boundary
time and the exhausted budget beside the boundary's firing count.

The default of 4 is chosen the way [§10.4][s10-4] chooses 8 for the
[localization budget](#g-chattering) (the count of localizations permitted
within one [frame](#g-frame), one grid step). A legitimate re-enable is one or two firings deep. A toggling
FSM pair chatters without bound. A budget of 4 separates the two without ever
binding on a healthy model. Like every other degradation here, it depends on the
trajectory alone, so the run replays identically.

The doctrine of [§10.4][s10-4] governs both budgets. Neither the boundary
iteration nor re-localization within the frame has a
structural bound, so each takes a budget. The boundary iteration takes
`firing_budget`, per event per boundary, and re-localization takes
`localization_budget`, per frame. Both degrade loudly rather than erroring,
under a warning that names the offending event. They differ only in what
exhaustion sheds. Localization sheds root-finding precision and preserves every
firing at boundary granularity. The firing budget sheds firings, which is
exactly what bounds the iteration.

#### Ticks after quiescence

**Ticks stay outside the iteration, after quiescence** ([D-020][d-020]). The
two possible couplings resolve asymmetrically.

- From events to ticks, machinery already in place handles the coupling. Due
  discrete components' output stages (`y_state`/`y_direct`) are gated into the
  boundary sweep against a due set fixed for the whole iteration
  ([§10.5][s10-5]). Every iteration round therefore refreshes them for free,
  against the same `s` and post-transition inputs. Their `s_update` has not
  run yet. At quiescence, their published outputs reflect the settled boundary
  instant, which is exactly what "sampling at t" should mean for a logically
  instantaneous cascade. Earlier rounds' tentative values are internal scratch,
  like RK stage evaluations. [§10.3][s10-3] states when external readers may
  observe the table.
- From ticks to events, a coupling is structurally impossible. A tick's output
  stages contribute nothing guards have not already seen, since they run inside
  the sweep, from current `s`. Its `s_update` writes `s⁺` after the sweep, and
  `s⁺` is first decoded at the owner's next tick. So `s⁺` is invisible to every
  reader within the boundary. This is the standard one-sample `z⁻¹` delay of
  sampled-data control, enforced here by construction. Nothing that happens
  after quiescence can flip a guard, so there is no combined event/tick fixed
  point to iterate.

The boundary macro-sequence, in its final form, is the following.

> integrate → project → [sweep → guards → handlers] iterated to quiescence
> (under the firing budget) → all due `s_update` calls → logging / I/O staging.

Boundary zero is the same sequence with an empty integrate ([§14.5][s14-5],
[D-067][d-067]).

The sequence decides the mixed case, where the handler of a
[continuous component](#g-continuous-component) (the hybrid primitive, with
continuous state, modes and events) and its discrete observers' ticks land on
one boundary. Take an engine's `starting → running` transition under a 50 Hz
flight control system (FCS). The engine is a continuous component, and the FCS
is a discrete component that observes it. The transition fires in the iteration
segment. The re-sweep re-runs the FCS's stages against `running`-mode ports, and
its `s_update` then runs from post-transition values.

### 10.7 Real-time pacing

A real-time run must keep to wall-clock time, and its trajectory must not
depend on how fast it runs. [Pacing](#g-pacing) (the waits that hold a run to
wall-clock time) does the first without breaking the second. This section covers
the invariant with the wall-clock map, the wait, the diagnostics, and where
staging and concurrency live.

#### The invariant and the wall-clock map

**Pacing is outside the semantics** ([D-021][d-021]). That is the section's
invariant. The pacer inserts waits between completed [frames](#g-frame)
(iterations of the loop). It never reorders, skips or alters the
[boundary](#g-boundary) sequence. A paced and an unpaced run with identical
input [traces](#g-trace) (the records of each frame's drained inputs) produce
bit-identical trajectories. So deterministic [replay](#g-replay)
([§2.2][s2-2]) extends over pace. Interactive runs differ only because their
*inputs* differ.

Detection policy is inside the semantics. **Event localization runs
identically paced or unpaced** ([§10.4][s10-4], [D-080][d-080]). Its
[sweep](#g-sweep) cost is absorbed as debt (wall time that later
frames repay) like any other expensive frame ([D-080][d-080]). Degrading to
boundary detection under pacing was rejected ([D-080][d-080]).

**The wall-clock map is piecewise affine, re-anchored at every knee**
([D-021][d-021]). A knee is a point where the map changes slope or offset. A
pace change, an un-pause and a forgiveness re-anchor each make one. The map is
$\tau(t) = \tau_{\mathrm{anchor}} + (t - t_{\mathrm{anchor}})/p$, with the
anchor pair as its reference point. Here $p$ is the pace and $\tau$ is
wall-clock time. The anchor pair $(t_{\mathrm{anchor}}, \tau_{\mathrm{anchor}})$
is the sim time and wall-clock time at the most recent anchor. A live pace
change re-establishes the anchor at the current `(t, τ)`, so the new slope
applies only forward ([D-021][d-021]). Un-pause re-anchors for the same reason.
Debt is cleared at re-anchor. A deliberate user action is a natural sync point.
The counters record what was forgiven. The frame that follows an anchor has no
wait, because its deadline is the anchor itself. The run's first anchor is taken
when its loop starts, so the first frame runs at once ([D-269][d-269]).

**The deadline law is an absolute schedule with bounded debt**
([D-021][d-021]). Frame deadlines come from the map. A frame that exceeds its
wall budget `h/p` leaves debt. Subsequent frames repay it by running short or
without waiting. The long-run rate is therefore exact, and ms-scale hiccups
from GC or the scheduler are invisible.

**Debt beyond a threshold of five frames' worth of budget, `5·h/p`, is
forgiven** by re-anchor plus a warning ([D-133][d-133]). As a result, long
stalls (a debugger, laptop sleep) do not trigger catch-up bursts. Five frames'
worth sits comfortably above the ms-scale hiccups that debt exists to absorb
silently, and far below the seconds-to-minutes stalls that forgiveness exists
for. Neither case lands near the threshold.

**`p = ∞` is pacer-off, not a limit value** ([D-021][d-021]). Unpaced mode is
the explicit *absence* of deadlines. There are no waits, no debt and no
warnings. By the invariant, it is the same execution with the waits deleted.

#### The wait

**The wait mechanism is a hybrid sleep-then-spin with one knob**
([D-021][d-021]). Non-realtime OSes guarantee only a lower bound on sleep. The
thread becomes runnable no earlier than requested. The wake-up is best-effort,
subject to timer granularity, scheduler load and macOS timer coalescing, with
no hard upper bound. Measured on the dev machine, idle, against 2 ms requests
(2026-07), Julia `sleep` overshoots by about 1.4 ms median, and
`Libc.systemsleep` by about 0.5 ms. Behind the `sleep` figure are libuv's
millisecond-granularity timers. Sub-ms requests are accepted and rounded up.
Spikes under load are unbounded. The pacer therefore sleeps toward
`deadline − margin` and spins the remainder:

```julia
remaining = deadline - margin - τ()
remaining > 0 && sleep(remaining)   # coarse phase: cheap, lower-bound-only (runs at most once)
while τ() < deadline                # spin phase: µs-precise, CPU cost bounded by margin
    GC.safepoint()                  # a safepoint, never a yield: GC and signals get through
end
```

`margin` is a single constant calibrated to cover the primitive's granularity
*plus* typical overshoot ([D-021][d-021]). There is no second threshold. The
resolution floor is absorbed into the calibration. A margin below the
primitive's granularity defeats the spin phase's purpose.

**The default `margin` is 2 ms** ([D-133][d-133]), the value the measurements
above imply. It covers libuv's millisecond timer granularity and `sleep`'s
median overshoot of about 1.4 ms. Anything larger merely spends more core in
the spin phase. The knob spans the whole design space ([D-021][d-021]):

- `margin = 0` is pure sleep, the cheapest in CPU. Frame spacing is bursty,
  but the absolute schedule still delivers the exact *average* rate through
  debt repayment. The spin phase buys regularity, never rate correctness.
- `margin = 2 ms` is the hybrid default. It sleeps about 90% of a 20 ms budget
  and lands within µs of the deadline at a few percent of one core.
- `margin = ∞` is pure busy-wait, FlightCore's behavior, with maximum frame
  regularity at one pinned core. The "best attempt at real time" mode is the
  knob's endpoint, not a separate mechanism.

When the frame budget is at or below the margin (for example `h = 0.01` at
`p = 5`, a 2 ms budget), the hybrid degenerates to pure spin per frame by
construction. Rare wake-ups past the deadline are overruns, absorbed as debt.

Which primitive the coarse phase uses, task-yielding `sleep` or
thread-blocking `Libc.systemsleep`, is settled in [§12.2][s12-2]. The coarse
phase uses task-yielding `sleep`, with `margin` absorbing its overshoot
([D-027][d-027]).

The wait sits at the frame top, after the
[control plane](#g-control-plane) (the atomic surface carrying pause, pace and
stop) is consulted. A control change issued during a wait is observed at the
next frame top, at most one frame budget `h/p` later ([§12.1][s12-1],
[D-269][d-269]). The wait is an unmask point ([§12.4][s12-4],
[D-132][d-132]) for the [operator interrupt](#g-operator-interrupt) (Ctrl-C in
an interactive session). The interrupt raises out of the coarse phase's
`sleep`.

#### Diagnostics

Overrun count, current and peak debt, forgiven-debt events and wait
statistics are published as [framework status](#g-framework-status) (the
frozen diagnostics value each snapshot carries beside the signal table) for
GUI and logs. The record carries `pace`, the pace the loop's frames run
under (`Inf` where no frame waits). It carries `debt` and `peak_debt`, in
seconds, and `overruns`, the frames that exceeded their budget. It carries
`reanchors`, every re-anchor after the run's first, and `forgiven`, the
seconds of debt those re-anchors cleared. It also carries `waits` and
`waited`, the frames that waited and their total wall time ([D-269][d-269]).

A deliberate re-anchor, from a pace change or an un-pause, is counted and
raises no warning. The forgiveness re-anchor is counted and reports
`DebtReanchor` ([Appendix C][sC]). A live switch to `p = ∞` is a pace change
like any other. It re-anchors, and the debt it clears is counted as forgiven
([D-269][d-269]).

#### Where staging and concurrency live

The wait interval is the natural staging slot for externally injected inputs,
which are drained at the next frame top. The staging rules belong to
[§11][s11] and [§12][s12], as does the concurrency model generally.
[§10.3][s10-3] constrains the concurrency model but does not decide it.

---


