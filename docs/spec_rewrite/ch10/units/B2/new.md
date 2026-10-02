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
