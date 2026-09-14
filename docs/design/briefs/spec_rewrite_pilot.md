### 10.4 Localization mechanics

A [guard](#g-guard)'s [predicate](#g-predicate) can cross inside an integration step, strictly between two grid points. The framework can handle such a crossing in two ways. It can notice the crossing at the end of the step, at grid resolution. Or it can find the crossing instant and publish it. This section fixes which guards get which treatment, and describes the machinery behind the second.

Two terms recur throughout, and they mean different things.

- A **[frame](#g-frame)** is one grid step `[tₙ, tₙ₊₁]`. It is the unit of scheduling. Three things are keyed to it: the input [drain](#g-drain) (the frame-top swap that publishes staged device writes into the root inputs, [§11.4][s11-4]), pacer deadlines ([§10.7][s10-7]) and [tick](#g-tick) eligibility ([§10.5][s10-5]).
- A **[boundary](#g-boundary)** is a published consistency point. The [§10.6][s10-6] macro-sequence completes there and a [snapshot](#g-snapshot) goes out.

Every grid point is a boundary, but not every boundary is a grid point. The localized event time `t*` is a boundary, and so is [boundary zero](#g-boundary-zero) (the initialization boundary at `t₀`, [§14.5][s14-5]). Neither is a frame top.

A frame in which one event localizes runs through these steps, with boundaries in bold:

> **tₙ** → integrate → arrival sweep at tₙ₊₁ → trigger → θ = 0 trial evaluation → bracket → root-find → **t\*** → remainder step → **tₙ₊₁**

This chain lists the order of operations. It is not a walk along the time axis. The arrival sweep at tₙ₊₁ raises the trigger, and integration then resumes from `t*`, which lies before tₙ₊₁.

#### Which guards localize: the form is the policy

**Rule.** The guard's return type declares its detection policy. No flag is involved.

- A guard returning `Bool` is **[boundary-detected](#g-boundary-detected)**. The framework checks it for edges at step boundaries only and never root-finds it.
- A guard returning the nominal scalar, the continuous sign form, is **[localized](#g-localized)**. The framework brackets the crossing instant by root-finding over trial sweeps.

The build reads the policy off the [probe](#g-probe) it already runs ([§9.3][s9-3], nominal [activation](#g-activation)). `StateEvent(guard, handler)` therefore carries no detection keyword ([D-179][d-179]).

**Why.** Localization brackets a root, and only the sign form offers one. Because the form is the policy, the illegal pairing cannot be written at all. It needs no diagnostic.

**A localized guard becomes boundary-detected with a one-line rewrite, at no semantic cost.** Return the predicate `σ ≥ 0` instead of `σ`. That cast is the definition of the predicate ([§2.1][s2-1]). The predicate and its edges stay the same. Only the resolution at which they are observed changes.

#### Boundary detection is exact for guards over `u` and `m` alone

**Rule.** For a guard that reads only `u` and `m`, boundary detection is exact.

**Why.** Such a predicate is constant within each frame. `u` changes only at the frame-top drain ([§11.4][s11-4]), and `m` changes only through handlers, at boundaries. The predicate cannot cross mid-step, so there is no interior instant for a root-finder to find. Here the boundary is not a resolution limit. It is the crossing itself, and localization would have nothing to do.

#### Mixed predicates: the gate idiom

Most transitions in FlightPhysics mix input predicates with state thresholds, so this case matters in practice. The piston engine's `starting → running` fires on `ω > ω_idle && fuel_available`.

**Rule.** When such a transition should localize, write it in the gate form `(gate) ? σ : -one(σ)`. The `Bool` factors go in the branch condition and the continuous factor in the value.

**Why.** The idiom is sound rather than a way around the policy check. Trial evaluations vary only θ. `u` and `m` stay fixed through a localization, so the gates are constant over the bracket. Restricted to the bracket, σ is the continuous atom, and it can be bracketed as such.

#### The trigger

**Rule.** A localized event triggers when its predicate was not-[holding](#g-edge-semantics) at tₙ's [quiescence](#g-quiescence) (the fixed point where a round of handlers fires nothing) and is holding at tₙ₊₁. The tₙ sample is the event's **[prior](#g-prior)**, the predicate sample stored at the previous boundary ([§10.6][s10-6]).

This is the directional edge of [§2.1][s2-1], not a bare sign change. A holding → not-holding transition neither fires nor localizes.

**The trigger check runs against the arrival [sweep](#g-sweep) at tₙ₊₁.** That is the sweep that closes the integration step. So the check runs before the due-gated [boundary sweep](#g-sweep) refreshes any discrete [cell](#g-cell). The ZOH clause below already forces this order, because trial evaluations must see the values the frame actually held. Stating it here fixes the sequencing up front. Every `t*` firing precedes tₙ₊₁'s whole boundary sequence.

#### The localization loop

The sketch below shows one localized event within one frame. Every step is normed afterwards.

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

**The θ = 0 validation.** On trigger, the first act is a trial evaluation at the left end. Write xₙ into the state [buffer](#g-buffer), run one [interior sweep](#g-sweep), and evaluate the guard to get σ₀. Nothing new is kept, since the stepper already retains xₙ for the [interpolant](#g-interpolant) (the cubic Hermite continuous extension over the last completed step). This trial evaluation needs no interpolant, because x̂(0) = xₙ identically. So it runs before any interpolant cost is paid.

The evaluation serves two purposes. σ₀ is the left bracket value that value-based root-finders need. σ₁ = σ(tₙ₊₁) is retained from the arrival evaluation, but σ₀ had no source until now. And σ₀ tells the edge's cause apart.

That discrimination needs one term. An **[input epoch](#g-input-epoch)** is a maximal span of constant `u`, delimited by frame-top drains ([§11.4][s11-4]). Within an epoch a guard can change only through the trajectory. At a seam between epochs it can jump without crossing anything.

**Why the discriminator is conclusive.** `u` is the only thing that can differ between the prior's evaluation context and this trial evaluation. `m` changes only via handlers at boundaries, and priors are sampled at quiescence, after the handlers. Discrete cells hold their values under ZOH, and the interior sweep excludes discrete entries ([§10.5][s10-5]). `t = tₙ` exactly, by the indexed-grid rule below. Sweeps are deterministic. So under the honest [priors](#g-prior) of [§10.6][s10-6], the frame-top drain is the only possible source of disagreement.

- σ₀ **not-holding** means a **trajectory-caused** edge, a genuine in-frame crossing. Pay the sweep for ẋₙ₊₁, build the interpolant and root-find on the bracket $(t_n, \sigma_0)$/$(t_{n+1}, \sigma_1)$.
- σ₀ **holding** means an **epoch-caused** edge. The drain flipped the guard at the frame top. σ holds at both ends, so there is no in-frame crossing to find.

**An epoch-caused edge is discarded, not degraded.** The localization is abandoned and the event fires inside tₙ₊₁'s ordinary iteration. Mechanically, not localizing is the action. The frame falls through, and the boundary iteration detects and fires the event like any boundary-detected event. This path costs one interior sweep. It never pays for ẋₙ₊₁ or an interpolant, and it consumes no `localization_budget`. It also warns nothing. Input timing is a frame fact, by the same doctrine that forbids draining at `t*` below, and boundary detection is exact for a `u`-caused edge (above; [D-179][d-179]). Boundary firing is therefore the correct semantics, not a degradation. This is the left-end mirror of the `t* = tₙ₊₁` degeneracy below.

**The interpolant is built lazily.** It is the cubic Hermite continuous extension $\hat{x}(\theta)$, $\theta = (t - t_n)/h \in [0, 1]$, built from $(x_n, \dot{x}_n, x_{n+1}, \dot{x}_{n+1})$. $\dot{x}_n$ is the step's first stage. $\dot{x}_{n+1}$ costs one sweep, paid only on a validated trigger. The θ = 0 trial evaluation comes first, so an epoch-caused edge never pays for it. Uniform accuracy is $O(h^4)$, one order below the discrete solution, which is the standard pairing. The event time can never be more accurate than the interpolant, so nothing more expensive is worth running trials against.

**Trial evaluations run the interior sweep.** Guards read `y`. Evaluating a guard at an interpolated state therefore means writing $\hat{x}(\theta)$ into the state buffer and running the interior sweep. The [RHS](#g-flow) already lives under this rule ([§10.5][s10-5]), since a trial evaluation is a mid-step evaluation. Discrete cells therefore hold their [tick](#g-tick) values through localization, and a guard reading a sampled output sees what the controller is holding. Each trial evaluation costs one interior sweep.

**Root-finding is bracketed and derivative-free.** ITP or Brent are the intended methods, and bisection is an acceptable fallback. The observed not-holding/holding bracket is an unconditional convergence certificate. Newton and AD localization are rejected ([D-018][d-018]).

**Convergence is a relative bracket width.** Localization stops once the bracket is narrower than `localization_tol · h`. `localization_tol` is a `Simulation` deployment keyword defaulting to `1e-6`. The tolerance is relative because an absolute tolerance in `t` is not scale-free ([D-133][d-133]). The default is `1e-6` because the event time can never be more accurate than the interpolant, which is `O(h⁴)` as stated above. At practical `h`, anything tighter buys nothing, while every trial evaluation costs a full sweep. Under ITP the bill is a handful of trial evaluations, and around 20 in bisection's worst case.

**Post-event.** The boundary sequence runs at `t*` (below). The interpolant is then invalidated, because the handlers have made it wrong for `t > t*`. Integration resumes from `t*` with the [remainder step](#g-remainder-step) targeting tₙ₊₁, and the guards are re-checked on the remainder. The re-check runs under the per-frame [localization budget](#g-chattering), with a chattering diagnostic.

**Multiple events localizing in one step fire at the earliest `t*`.** Ties fire at that boundary inside the event iteration, one eligible event per component per round in declaration order ([§10.6][s10-6]). Later crossings re-localize on the remainder.

**Both policies share one blind spot.** An even number of crossings within one step returns the predicate to not-holding at the boundary, so no edge is observed. Neither policy can detect this. The mitigation is a smaller step size, not more machinery.

#### Endpoint policy and grid integrity

**Rule.** The root-finder returns the holding endpoint of its final bracket. That is the smallest trial point where the predicate holds.

**Consequence.** `t* = tₙ` is structurally impossible. It never needs clamping away.

**Why.** The argument rests on what was measured, not on what the prior reports. Root-finding starts only after the θ = 0 validation has measured σ₀ not-holding under the frame's own `u`. The bracket's left end is therefore not-holding by the same kind of evidence as its right end, and the returned point is strictly later than the published, immutable tₙ. In the worst rounding case it is `nextfloat(tₙ)`. This holds unconditionally. It needs no appeal to the prior and leaves no residual epoch hole, because the case where the prior and the frame's `u` disagree is exactly the epoch-caused edge, and that case never reaches the root-finder.

The guard also observably holds at `t*`. Handlers therefore fire in states where their own predicate holds, and the post-fire prior records an actual observation rather than an assumption.

**`t* = tₙ₊₁` exactly is legitimate.** It is a crossing at the grid point, where σ(tₙ₊₁) = 0 both triggers detection and is the root. It degenerates to the grid boundary. The localization result is discarded and the event fires inside tₙ₊₁'s ordinary iteration. That outcome is bitwise identical to the boundary-detected one, with one boundary, one snapshot and no zero-length remainder.

**Grid times are indexed, never accumulated.** A near-degenerate `t*` leaves a tiny remainder step. Numerically that is harmless, since increments scale with `h′`. The real hazard is bookkeeping, and this rule removes it. `tₖ = t₀ + k·h` is computed from the frame index, just as tick gating is already counter-modulo ([§10.5][s10-5]). The remainder step targets the grid point, with `h′` derived at use. `t*` is a float inside a frame, never an anchor from which anything else is computed.

#### What a `t*` boundary does, and does not, do

At `t*` the full [§10.6][s10-6] event phase runs. The sweep → guards → handlers cycle iterates to quiescence, with firing-budget accounting scoped to this boundary. The budget is fresh again at tₙ₊₁, and again at a second `t*` on the remainder. The settled state is then published. That means a snapshot, the [§12.3][s12-3] boundary-counter increment and the [`stop_on`](#g-stop_on) check ([§13.5][s13-5]). A crash localized at `t*` ends the run from that snapshot.

**Two things do not happen at `t*`.** Ticks are never due there. `t*` is off the [harmonic grid](#g-harmonic-grid) (every discrete period an integer multiple of `Δt_base`) by construction, and discrete cells ZOH-hold through the sweep. Staged inputs are not drained either, for two reasons. Input timing is a frame fact, and replay determinism must not depend on localization arithmetic.

**The `t*` publication is not separately paced.** The pacer paces frame deadlines. A `t*` snapshot publishes when computed, mid-frame. Where that lands in wall-clock time is below what pacing resolves. The [§10.7][s10-7] invariant is about trajectories, and those are identical either way.

Replay pointers and error messages index boundaries by the frame-entry boundary index ([§13.4][s13-4]) together with the recorded `t`. Snapshots carry the trajectory's published-boundary ordinal ([§12.3][s12-3]). The trace stays frame-indexed, since `t*` boundaries consume no inputs.

#### Projection's reach is the boundary, not the trial evaluation

**Rule.** Guard trial evaluations run against the raw interpolated state. Authority rests with the `t*` boundary. [Projection](#g-projection) runs there, and the [§10.6][s10-6] iteration's edge checks read the projected state.

**Why.** RK-stage RHS evaluations already run under the same rule, since they are equally off-manifold. Sweeps must therefore tolerate near-manifold states, and they already do. Per-trial projection is rejected ([D-018][d-018]).

If projection moves the state back across a guard, the event does not fire and the run has published one extra boundary. That is harmless. Like any other localization outcome, it is deterministic and pace-independent ([D-080][d-080]).

#### Budget exhaustion degrades; it does not throw

**Rule.** `localization_budget` is an integer count of localizations permitted within one frame. It defaults to **8**. It is the second deployment keyword this section fixes.

**Why 8.** A legitimate multi-event frame needs three or four localizations. Three landing-gear struts touching down inside one step is the reference case. [Chattering](#g-chattering) needs tens. A budget of 8 bounds the pathology without ever binding on a healthy model.

**When a frame spends its budget**, localization stops for the rest of that frame. The remainder step completes, and any further crossings fire in the next boundary's ordinary iteration, at boundary granularity for that frame. A `ChatteringBudget` warning ([Appendix C][sC]) names the chattering event and the localization count.

The degradation depends on the trajectory alone, never on wall clock. The pace-independence guarantee ([D-080][d-080]) therefore stands, and the run replays identically. A `StepError` here would misclassify an expected modeling outcome as broken machinery, which the [§14.8][s14-8] doctrine forbids.

**The same doctrine governs [§10.6][s10-6].** Neither the boundary iteration nor cross-frame re-localization has a structural bound, so each takes a budget. The boundary iteration takes `firing_budget`, and re-localization takes `localization_budget`. Both degrade loudly rather than erroring, under a warning that names the offending event. They differ only in what exhaustion sheds. Localization sheds root-finding precision and preserves every firing at boundary granularity. The firing budget sheds firings, which is exactly what bounds the iteration.

#### Both constants are deployment, not implementation

`localization_tol` and `localization_budget` are `Simulation` keywords. They stand beside `h`, `N_base` and the algorithm ([§9.1][s9-1], [Appendix B][sB]). They are validated with their siblings, as a positive tolerance and an integer budget ≥ 1, and failures are collected into `DeploymentInvalid` ([Appendix C][sC]). The `firing_budget` ([§10.6][s10-6]) stands beside them in every one of these lists. It gets the same validation, the same `DeploymentInvalid`, the same trace header and the same replay comparison. Both are grid-independent, so neither enters the harmonic-grid check ([§10.5][s10-5]).

**Because they determine the trajectory, both are recorded.** They ride the [trace header](#g-trace-header)'s deployment block and join the set that [replay](#g-replay) compares up front, exactly as `h` and the algorithm do ([§11.5][s11-5], [§12.7][s12-7]).

**Why.** Without this, the replays-identically promise above is empty. A run that does not record what its localizer was told to do cannot be re-driven through the same localization outcomes.

### 10.6 Event iteration at boundaries: to quiescence, budgeted

[§5.3][s5-3] leaves two questions open. How far does the event phase run at a [boundary](#g-boundary), and how often may each event fire while it does? This section answers both. The phase iterates. One round re-runs the [boundary sweep](#g-sweep), evaluates all [guards](#g-guard) against it, and fires the eligible events, at most one per [component](#g-component). Each firing is `handler → state_projection`. Rounds continue to [quiescence](#g-quiescence), the fixed point where a round of handlers fires nothing.

**Rule.** An event fires in an iteration round if and only if three conditions hold. Its [predicate](#g-predicate) is observed holding in that round. The sample observed before it was not-holding. And the event's firing count for this boundary is below `firing_budget`. That is the whole definition of "newly fired". The predicate is the one [§2.1][s2-1] defines, either the `Bool` form true or `σ ≥ 0`. `firing_budget` is a `Simulation` deployment keyword, an integer ≥ 1 defaulting to **4**. It caps how many times each declared event may fire at one boundary.

Three registers per event decide the rule, all named normatively.

- The **[prior](#g-prior)** is the previous boundary's quiescent sample. The boundary's first round tests against it.
- The **last-observed sample** is initialized from the prior when the boundary opens and overwritten by every round's evaluation. Every later round tests against it. There is one exception. An event that was eligible but blocked (below) keeps its sample, because blocking defers its edge rather than consuming it.
- The **firing count** for the boundary is incremented at each firing and reset when the boundary ends.

Eligibility inside a boundary is therefore an [edge](#g-edge-semantics) like any other. It is a not-holding → holding transition, never a bare sign change. What differs is the reference sample. The edge is read against the last-observed sample, not against the prior the boundary entered with. Two consequences follow. Sticky predicates need no special case. An event that fires and keeps holding presents no further not-holding → holding edge, so it fires once, at the boundary where it first held. And a predicate that is genuinely falsified and re-enabled inside the boundary, because another handler's cascade reverted its effect, fires again at this boundary against a fresh sweep ([D-181][d-181]).

One boundary's iteration, sketched:

```julia
# entering the boundary, per event:  last ← prior,  count ← 0
while the previous round fired something   # the first round always runs
    boundary sweep                         # whole gated schedule, due set fixed for the boundary
    per event:      eligible ← last not-holding && now holding && count < firing_budget
    per component:  firing ← its first eligible event, in declaration order
    per event:      last ← now, unless eligible and not firing   # a blocked edge stays unconsumed
    fire the firing events                 # handler → state_projection, count += 1
end                                        # the exit condition is quiescence
per event:  prior ← last                   # the settled boundary's honest sample
```

**The prior is updated at each boundary's quiescence, from the final post-iteration samples.** The update is unconditional. Every prior is therefore an honest observation of a settled boundary. That is what makes the θ = 0 discriminator ([§10.4][s10-4]) conclusive. The [frame-top drain](#g-drain) is the only possible source of disagreement between the prior and the left-end trial evaluation.

All three registers are detection bookkeeping, not model memory. They are correctly absent from every state store. They are not captured, not traced, and reconstructed deterministically. Beyond the prior, the cost is one `Bool` and one small counter per event.

**[Boundary zero](#g-boundary-zero) sets every prior to not-holding.** A predicate already holding in the authored state therefore fires at `t₀`. That behavior ([§14.5][s14-5]) is derived rather than asserted. A warm restart resets all three registers from scratch, because `init!` re-runs boundary zero ([§14.5][s14-5]). Predicates holding in the newly applied state fire again at the new `t₀`.

**Why iterate.** Under a single pass, a cascade of N logically simultaneous transitions (supervisor FSM → subordinate FSM → …) takes N steps to complete, at latency N·h. Model semantics would then depend on the integrator's step size, and `h` is an execution parameter. This is the same class of footgun [§2.2][s2-2] cited when killing `f_step!`. Cascades are not a corner case either. Externalized FSM components are blessed ([§3.1][s3-1]), which makes cross-component cascades the expected idiom. Established practice agrees. Hybrid automata take sequences of instantaneous transitions at one time point, Modelica iterates events to quiescence, and Stateflow runs charts to completion within a [tick](#g-tick).

Boundary-detection timing remains h-dependent, but that is a different quantity. It is the resolution at which a physical crossing is noticed. The cascade delay would have been structure the framework inserts between transitions the model declares simultaneous.

**Why a full re-sweep per round.** A transition reaches the [signal table](#g-signal-table) only through a sweep. A handler writes its component's state stores and nothing else. So neither the transitioning component's own [ports](#g-port) nor the downstream stage-2 chains that read them have moved. A round therefore re-runs the whole gated [schedule](#g-schedule). The cost is noise. Sweeps take microseconds, and rounds beyond the first require an actual cascade.

**Within a round, the signal table has a single writer, and it is the sweep.** A handler writes nothing to the table. It returns transitions, the framework latches them into the component's state stores, and `state_projection` normalizes them. Auto-publication is a sweep act like any other stage-1 write ([§9.5][s9-5]). Nothing moves the table mid-round.

This gives the [epoch rule](#g-input-epoch), which is the core of this section. **A handler executes against exactly the world its guard fired on.** Its own `y`, foreign `u` and its own `x`/`m` all come from the firing round's sweep, so `y = h(x)` holds at every handler entry. No [bundle](#g-bundle) (the NamedTuple of zero-copy views a component function receives) ever straddles two epochs. Serialization is what delivers this. A component's state stores are written only by its own handlers, and it fires at most one event per round, so no same-round writer precedes any handler's entry.

**A component's other eligible events are blocked, not lost.** Each is re-decided in the next round, against the post-transition sweep. Declaration order is therefore a priority with re-decision, not a simultaneity. An event whose premise the earlier transition falsified simply does not fire. Under a within-round sequence it would have fired on the stale premise. Blocking is visible in the registers ([D-191][d-191]). An eligible-but-blocked event is the one case whose last-observed sample is not overwritten, so the edge it presented stands unconsumed. A guard that keeps holding therefore fires in the next round on that same edge. One that the transition falsified records not-holding as usual, and any later re-rise is a fresh edge. The prior stays honest at no cost. The quiescent round fires nothing, hence blocks nothing, so every sample takes its final update before the prior is written.

**Across components, handler order within a round is semantically unobservable.** The reason is stronger than serialization. There is no delivering mechanism at all. Nothing writes the table mid-round, so there is nothing for order to observe. Execution order is fixed all the same, as [executor](#g-executor) component order and then declaration order within a component. That keeps the [§13.4][s13-4] cursor and the diagnostics stream deterministic. No trajectory depends on it. The natural single-pass executor is therefore exactly correct. It builds each handler's bundle at dispatch, from the live table. It needs no pre-materialization, no staging pass, no carrier and no shadow table, and it allocates nothing.

**The trade, stated openly, is that a handler cannot opt into seeing a same-round foreign transition.** Same-instant sequential coupling across components is a cascade, one round per link, deterministic. Coupling tighter than that belongs inside one component, where declaration order gives exact sequencing across rounds. This is the position of the synchronous languages. A micro-step sees the pre-state, and effects appear at the next micro-step. Serializing same-component firings costs one extra intra-boundary sweep per event so serialized, which is microseconds on the rare boundary that fires at all. [D-154][d-154] records the rejected shapes. They are the per-event re-decode with a frozen round-start `u` ([D-016][d-016], [D-100][d-100], [D-152][d-152]), live-table reads under the canonical execution order, a table copy per firing round ([D-100][d-100]), and handlers stripped of their own `y`.

**Why a per-event budget.** A re-enabled event fires at its true boundary, against a fresh sweep. The deferral design and the per-round cap are both rejected ([D-020][d-020], [D-181][d-181]). Priors stay honest as a consequence. Every prior is a sample actually taken, never a value recorded to make a rule work out.

Termination is then budget-bounded rather than structural. For `E` declared events, a boundary admits at most `firing_budget · E` firings, hence a bounded number of rounds, deterministically and independently of pace. A livelock, such as two FSMs toggling each other, does not resolve silently. Each toggler spends its budget and warns (below), and the run proceeds and replays identically. This is degradation, not an error, per the doctrine of [§10.4][s10-4]. The warning names the actual chatterer, while every other event's iteration continues untouched.

This trade is also stated openly. Because termination is budget-bounded rather than structural, the arbitrary-K objection lives on in `firing_budget`. What that buys is the absence of deferral machinery. There is no manufactured prior, no re-arm flag, no `EventDeferred` warning, no one-step artifact, and no collapse of several intra-boundary re-arms into a single later firing.

**Budget exhaustion degrades; it does not throw.** When an event has fired `firing_budget` times at a boundary, its further edges there are lost for the rest of that boundary. The eligibility test skips it while every other event iterates normally. A lost edge emits a `FiringBudget` warning ([§13.2][s13-2], [Appendix C][sC]), at most once per event per boundary. An event that fires its budget out and then quiesces lost nothing and warns nothing. The warning carries the component path, the event name, the boundary time and the exhausted budget beside the boundary's firing count.

The default of **4** is chosen the way [§10.4][s10-4] chooses 8. A legitimate re-enable is one or two firings deep. A toggling FSM pair chatters without bound. A budget of 4 separates the two without ever binding on a healthy model. Like every other degradation here, it depends on the trajectory alone, so the run replays identically.

**Ticks stay outside the iteration, after quiescence.** The two possible couplings resolve asymmetrically.

- *Events → ticks: machinery already in place handles this.* Due discrete components' output stages (`output_state`/`output_direct`) are gated into the boundary sweep against a due set fixed for the whole iteration ([§10.5][s10-5]). Every iteration round therefore refreshes them for free, against the same `s` and post-transition inputs. Their `state_update` has not run yet. At quiescence, their published outputs reflect the settled boundary instant, which is exactly what "sampling at t" should mean for a logically instantaneous cascade. Earlier rounds' tentative values are internal scratch, like RK stage evaluations. [§10.3][s10-3] extends naturally. External readers observe the table only after the boundary sequence completes.
- *Ticks → events: structurally impossible.* A tick's output stages contribute nothing guards have not already seen, since they run inside the sweep, from current `s`. Its `state_update` writes `s⁺` after the sweep, and `s⁺` is first decoded at the owner's next tick. So `s⁺` is invisible to every reader within the boundary. This is the standard one-sample `z⁻¹` delay of sampled-data control, enforced here by construction. Nothing that happens after quiescence can flip a guard, so there is no combined event/tick fixed point to iterate.

The boundary macro-sequence, in its final form. Boundary zero, the initialization boundary, is the same sequence with an empty integrate ([§14.5][s14-5]).

> integrate → project → **[sweep → guards → handlers]** iterated to quiescence (under the [firing budget](#g-firing-budget)) → all due `state_update` calls → logging / I/O staging.

The sequence decides the mixed case, where a [continuous component](#g-continuous-component)'s handler and its discrete observers' ticks land on one boundary. Take an engine's `starting → running` transition under a 50 Hz FCS. The transition fires in the iteration segment. The re-sweep re-runs the FCS's stages against `running`-mode ports, and its `state_update` then runs from post-transition values.
