#### Endpoint policy and grid integrity

**Rule.** The root-finder returns the holding endpoint of its final bracket.
That is the smallest trial point where the predicate holds.

**Consequence.** `t* = tₙ` is structurally impossible. It never needs clamping
away.

**Why.** The argument rests on what was measured, not on what the prior reports.
Root-finding starts only after the θ = 0 validation has measured σ₀ not-holding
under the frame's own `u`. The bracket's left end is therefore not-holding by
the same kind of evidence as its right end, and the returned point is strictly
later than the published, immutable tₙ. In the worst rounding case it is
`nextfloat(tₙ)`. This holds unconditionally. It needs no appeal to the prior and
leaves no residual epoch hole, because the case where the prior and the frame's
`u` disagree is exactly the epoch-caused edge, and that case never reaches the
root-finder.

The guard also observably holds at `t*`. Handlers therefore fire in states where
their own predicate holds, and the post-fire prior records an actual observation
rather than an assumption.

**`t* = tₙ₊₁` exactly is legitimate.** It is a crossing at the grid point, where
σ(tₙ₊₁) = 0 both triggers detection and is the root. It degenerates to the grid
boundary. The localization result is discarded and the event fires inside tₙ₊₁'s
ordinary iteration. That outcome is bitwise identical to the boundary-detected
one, with one boundary, one snapshot and no zero-length remainder.

**Grid times are indexed, never accumulated.** A near-degenerate `t*` leaves a
tiny remainder step. Numerically that is harmless, since increments scale with
`h′`. The real hazard is bookkeeping, and this rule removes it. `tₖ = t₀ + k·h`
is computed from the frame index, just as tick gating is already counter-modulo
([§10.5][s10-5]). The remainder step targets the grid point, with `h′` derived at use.
`t*` is a float inside a frame, never an anchor from which anything else is
computed.

#### What a `t*` boundary does, and does not, do

At `t*` the full [§10.6][s10-6] event phase runs. The sweep → guards → handlers cycle
iterates to quiescence, with firing-budget accounting scoped to this boundary.
The budget is fresh again at tₙ₊₁, and again at a second `t*` on the remainder.
The settled state is then published. That means a snapshot, the [§12.3][s12-3]
boundary-counter increment and the [`stop_on`](#g-stop_on) check ([§13.5][s13-5]). A crash localized at
`t*` ends the run from that snapshot.

**Two things do not happen at `t*`.** Ticks are never due there. `t*` is off the
[harmonic grid](#g-harmonic-grid) (every discrete period an integer multiple of `Δt_base`) by
construction, and discrete cells ZOH-hold through the sweep. Staged inputs are
not drained either, for two reasons. Input timing is a frame fact, and replay
determinism must not depend on localization arithmetic.

**The `t*` publication is not separately paced.** The pacer paces frame
deadlines. A `t*` snapshot publishes when computed, mid-frame. Where that lands
in wall-clock time is below what pacing resolves. The [§10.7][s10-7] invariant is about
trajectories, and those are identical either way.

Replay pointers and error messages index boundaries by the frame-entry boundary
index ([§13.4][s13-4]) together with the recorded `t`. Snapshots carry the trajectory's
published-boundary ordinal ([§12.3][s12-3]). The trace stays frame-indexed, since `t*`
boundaries consume no inputs.

#### Projection's reach is the boundary, not the trial evaluation

**Rule.** Guard trial evaluations run against the raw interpolated state.
Authority rests with the `t*` boundary. [Projection](#g-projection) runs there, and the [§10.6][s10-6]
iteration's edge checks read the projected state.

**Why.** RK-stage RHS evaluations already run under the same rule, since they
are equally off-manifold. Sweeps must therefore tolerate near-manifold states,
and they already do. Per-trial projection is rejected ([D-018][d-018]).

If projection moves the state back across a guard, the event does not fire and
the run has published one extra boundary. That is harmless. Like any other
localization outcome, it is deterministic and pace-independent ([D-080][d-080]).

#### Budget exhaustion degrades; it does not throw

**Rule.** `localization_budget` is an integer count of localizations permitted
within one frame. It defaults to **8**. It is the second deployment keyword this
section fixes.

**Why 8.** A legitimate multi-event frame needs three or four localizations.
Three landing-gear struts touching down inside one step is the reference case.
[Chattering](#g-chattering) needs tens. A budget of 8 bounds the pathology without ever binding
on a healthy model.

**When a frame spends its budget**, localization stops for the rest of that
frame. The remainder step completes, and any further crossings fire in the next
boundary's ordinary iteration, at boundary granularity for that frame. A
`ChatteringBudget` warning ([Appendix C][sC]) names the chattering event and the
localization count.

The degradation depends on the trajectory alone, never on wall clock. The
pace-independence guarantee ([D-080][d-080]) therefore stands, and the run replays
identically. A `StepError` here would misclassify an expected modeling outcome
as broken machinery, which the [§14.8][s14-8] doctrine forbids.


#### Both constants are deployment, not implementation

`localization_tol` and `localization_budget` are `Deployment` constructor
keywords. They stand beside `h`, `N_base` and the algorithm ([§9.2][s9-2],
[Appendix B][sB]). They are
validated with their siblings, as a positive tolerance and an integer budget ≥
1, and failures are collected into `DeploymentInvalid` ([Appendix C][sC]). The
`firing_budget` ([§10.6][s10-6]) stands beside them in every one of these lists. It gets
the same validation, the same `DeploymentInvalid`, the same trace header and the
same replay comparison. Both are grid-independent, so neither enters the
harmonic-grid check ([§10.5][s10-5]).

**Because they determine the trajectory, both are recorded.** They ride the
[trace header](#g-trace-header)'s [`Deployment`](#g-deployment) (the scalar-free
artifact the grid parameters fix) and join the set that [replay](#g-replay)
compares up front, exactly as `h` and the algorithm do ([§11.5][s11-5],
[§12.7][s12-7]).

**Why.** Without this, the replays-identically promise above is empty. A run
that does not record what its localizer was told to do cannot be re-driven
through the same localization outcomes.

