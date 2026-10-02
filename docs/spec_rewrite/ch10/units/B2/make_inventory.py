# Scratch: writes inventory.json for unit B2.
import json, os
S = "docs/design/spec.md"
C = []
def c(old, new, tag="F", cites=(), newcites=None, where="new", ruling=None):
    d = {"id": f"B2-{len(C)+1:03d}", "old": old, "new": new, "where": where,
         "cites": list(cites), "tag": tag}
    if newcites is not None: d["newcites"] = list(newcites)
    if ruling: d["ruling"] = ruling
    C.append(d)

c("#### Endpoint policy and grid integrity", "#### Endpoint policy and grid integrity", "X")
c("Rule. The root-finder returns the holding endpoint of its final bracket.",
  "The root-finder returns the holding endpoint of its final bracket (D-082).", "C", newcites=["D-082"])
c("That is the smallest trial point where the predicate holds.", "That is the smallest trial point where the predicate holds.")
c("Consequence. `t = tₙ` is structurally impossible.", "It follows that `t = tₙ` is structurally impossible.")
c("It never needs clamping away.", "It never needs clamping away.")
c("Why. The argument rests on what was measured, not on what the prior reports.",
  "The argument rests on what was measured, not on what the prior reports.")
c("Root-finding starts only after the θ = 0 validation has measured σ₀ not-holding under the frame's own `u`.",
  "Root-finding starts only after the θ = 0 validation has measured σ₀ not-holding under the frame's own `u`.")
c("The bracket's left end is therefore not-holding by the same kind of evidence as its right end,",
  "The bracket's left end is therefore not-holding by the same kind of evidence as its right end.")
c("and the returned point is strictly later than the published, immutable tₙ.",
  "The returned point is thus strictly later than the published, immutable tₙ.")
c("In the worst rounding case it is `nextfloat(tₙ)`.", "In the worst rounding case it is `nextfloat(tₙ)`.")
c("This holds unconditionally. It needs no appeal to the prior", "This holds unconditionally, with no appeal to the prior.")
c("and leaves no residual epoch hole, because the case where the prior and the frame's `u` disagree is exactly the epoch-caused edge, and that case never reaches the root-finder.",
  "It also leaves no residual epoch hole, because the case where the prior and the frame's `u` disagree is exactly the epoch-caused edge, and that case never reaches the root-finder (D-182).",
  "C", newcites=["D-182"])
c("The guard also observably holds at `t`.", "The guard also observably holds at `t` (D-082).", "C", newcites=["D-082"])
c("Handlers therefore fire in states where their own predicate holds, and the post-fire prior records an actual observation rather than an assumption.",
  "Handlers therefore fire in states where their own predicate holds, and the post-fire prior records an actual observation rather than an assumption.")
c("`t = tₙ₊₁` exactly is legitimate.", "`t = tₙ₊₁` exactly is legitimate (D-082).", "C", newcites=["D-082"])
c("It is a crossing at the grid point, where σ(tₙ₊₁) = 0 both triggers detection and is the root.",
  "It is a crossing at the grid point, where σ(tₙ₊₁) = 0 both triggers detection and is the root.")
c("It degenerates to the grid boundary.", "It degenerates to the grid boundary.")
c("The localization result is discarded and the event fires inside tₙ₊₁'s ordinary iteration.",
  "The localization result is discarded and the event fires inside tₙ₊₁'s ordinary iteration.")
c("That outcome is bitwise identical to the boundary-detected one, with one boundary, one snapshot and no zero-length remainder.",
  "That outcome is bitwise identical to the boundary-detected one, with one boundary, one snapshot (the immutable per-boundary publication) and no zero-length remainder.")
c("Grid times are indexed, never accumulated.", "Grid times are indexed, never accumulated (D-082).", "C", newcites=["D-082"])
c("A near-degenerate `t` leaves a tiny remainder step.", "A near-degenerate `t` leaves a tiny remainder step.")
c("Numerically that is harmless, since increments scale with `h′`.", "Numerically that is harmless, since increments scale with `h′`.")
c("The real hazard is bookkeeping, and this rule removes it.", "The real hazard is bookkeeping, and this rule removes it.")
c("`tₖ = t₀ + k·h` is computed from the frame index, just as tick gating is already counter-modulo (§10.5).",
  "`tₖ = t₀ + k·h` is computed from the frame index, just as tick gating is already counter-modulo (§10.5).", cites=["§10.5"])
c("The remainder step targets the grid point, with `h′` derived at use.", "The remainder step targets the grid point, with `h′` (the remainder step's length) derived at use.")
c("`t` is a float inside a frame, never an anchor from which anything else is computed.",
  "`t` is a float inside a frame, never an anchor from which anything else is computed.")
c("#### What a `t` boundary does, and does not, do", "#### The `t` boundary", "X")
c("At `t` the full §10.6 event phase runs.", "At `t` the full §10.6 event phase runs (D-081).", "C",
  cites=["§10.6"], newcites=["§10.6", "D-081"])
c("The sweep → guards → handlers cycle iterates to quiescence,", "The sweep → guards → handlers cycle iterates to quiescence.")
c("with firing-budget accounting scoped to this boundary.", "Firing-budget accounting is scoped to this boundary (D-181).", "C", newcites=["D-181"])
c("The budget is fresh again at tₙ₊₁, and again at a second `t` on the remainder.",
  "The budget is fresh again at tₙ₊₁, and again at a second `t` on the remainder.")
c("The settled state is then published.", "The settled state is then published.")
c("That means a snapshot, the §12.3 boundary-counter increment and the `stop_on` check (§13.5).",
  "That means a snapshot, the boundary-counter increment of §12.3 and the `stop_on` check (the read of the termination faces `stop_on` names, §13.5).",
  cites=["§12.3", "§13.5"])
c("A crash localized at `t` ends the run from that snapshot.", "A crash localized at `t` ends the run from that snapshot.")
c("Two things do not happen at `t`.", "Two things do not happen at `t`.")
c("Ticks are never due there.", "Ticks are never due there (D-147).", "C", newcites=["D-147"])
c("`t` is off the harmonic grid (every discrete period an integer multiple of `Δt_base`) by construction, and discrete cells ZOH-hold through the sweep.",
  "`t` is off the harmonic grid (every discrete period an integer multiple of `Δt_base`) by construction, and discrete cells ZOH-hold through the sweep.")
c("Staged inputs are not drained either, for two reasons.", "Staged inputs are not drained either (D-081), for two reasons.", "C", newcites=["D-081"])
c("Input timing is a frame fact, and replay determinism must not depend on localization arithmetic.",
  "Input timing is a frame fact, and the determinism of replay (the ordinary loop re-driven from the trace) must not depend on localization arithmetic.")
c("The `t` publication is not separately paced.", "The `t` publication is not separately paced (D-081).", "C", newcites=["D-081"])
c("The pacer paces frame deadlines.", "The pacer (which inserts waits between completed frames) paces frame deadlines.")
c("A `t` snapshot publishes when computed, mid-frame.", "A `t` snapshot publishes when computed, mid-frame.")
c("Where that lands in wall-clock time is below what pacing resolves.", "Where that lands in wall-clock time is below what pacing resolves.")
c("The §10.7 invariant is about trajectories, and those are identical either way.",
  "The invariant of §10.7 is about trajectories, and those are identical either way.", cites=["§10.7"])
c("Replay pointers and error messages index boundaries by the frame-entry boundary index (§13.4) together with the recorded `t`.",
  "Replay pointers and error messages index boundaries by the frame-entry boundary index (§13.4, D-128) together with the recorded `t`.",
  "C", cites=["§13.4"], newcites=["§13.4", "D-128"])
c("Snapshots carry the trajectory's published-boundary ordinal (§12.3).",
  "Snapshots carry the trajectory's published-boundary ordinal (§12.3, D-230).", "C", cites=["§12.3"], newcites=["§12.3", "D-230"])
c("The trace stays frame-indexed, since `t` boundaries consume no inputs.", "The trace stays frame-indexed, since `t` boundaries consume no inputs.")
c("#### Projection's reach is the boundary, not the trial evaluation",
  "Projection (the optional per-component hook `x ← x_projection(x)`) reaches the boundary, not the trial evaluation.")
c("Rule. Guard trial evaluations run against the raw interpolated state.",
  "Guard trial evaluations run against the raw interpolated state (D-018).", "C", newcites=["D-018"])
c("Authority rests with the `t` boundary.", "Authority rests with the `t` boundary.")
c("Projection runs there, and the §10.6 iteration's edge checks read the projected state.",
  "Projection runs there, and the edge checks of the §10.6 iteration read the projected state.",
  cites=["§10.6"])
c("Why. RK-stage RHS evaluations already run under the same rule, since they are equally off-manifold.",
  "RK-stage RHS evaluations already run under the same rule, since they are equally off-manifold.")
c("Sweeps must therefore tolerate near-manifold states, and they already do.", "Sweeps must therefore tolerate near-manifold states, and they already do.")
c("Per-trial projection is rejected (D-018).", "Per-trial projection is rejected (D-018).", cites=["D-018"])
c("If projection moves the state back across a guard, the event does not fire and the run has published one extra boundary.",
  "If projection moves the state back across a guard, the event does not fire and the run has published one extra boundary.")
c("That is harmless.", "That is harmless.")
c("Like any other localization outcome, it is deterministic and pace-independent (D-080).",
  "Like any other localization outcome, it is deterministic and pace-independent (D-080).", cites=["D-080"])
c("#### Budget exhaustion degrades; it does not throw", "Budget exhaustion degrades; it does not throw (D-018).", "C", newcites=["D-018"])
c("Rule. `localization_budget` is an integer count of localizations permitted within one frame.",
  "`localization_budget` is an integer count of localizations permitted within one frame (D-133, D-181).",
  "C", newcites=["D-133", "D-181"])
c("It defaults to 8.", "It defaults to 8.")
c("It is the second deployment keyword this section fixes.", "It is the second deployment keyword this section fixes.")
c("Why 8. A legitimate multi-event frame needs three or four localizations.", "A legitimate multi-event frame needs three or four localizations.")
c("Three landing-gear struts touching down inside one step is the reference case.", "Three landing-gear struts touching down inside one step is the reference case.")
c("Chattering needs tens.", "Chattering needs tens.")
c("A budget of 8 bounds the pathology without ever binding on a healthy model.",
  "A budget of 8 therefore bounds the pathology without ever binding on a healthy model.")
c("When a frame spends its budget, localization stops for the rest of that frame.",
  "When a frame spends its budget, localization stops for the rest of that frame.")
c("The remainder step completes, and any further crossings fire in the next boundary's ordinary iteration, at boundary granularity for that frame.",
  "The remainder step completes, and any further crossings fire in the next boundary's ordinary iteration, at boundary granularity for that frame.")
c("A `ChatteringBudget` warning (Appendix C) names the chattering event and the localization count.",
  "A `ChatteringBudget` warning (Appendix C) names the chattering event and the localization count.", cites=["Appendix C"])
c("The degradation depends on the trajectory alone, never on wall clock.", "The degradation depends on the trajectory alone, never on wall clock.")
c("The pace-independence guarantee (D-080) therefore stands, and the run replays identically.",
  "The pace-independence guarantee (D-080) therefore stands, and the run replays identically.", cites=["D-080"])
c("A `StepError` here would misclassify an expected modeling outcome as broken machinery, which the §14.8 doctrine forbids.",
  "A `StepError` (§13.4) here would misclassify an expected modeling outcome as broken machinery, which the no-throw doctrine of §14.8 forbids.",
  "C", cites=["§14.8"], newcites=["§13.4", "§14.8"])
c("#### Both constants are deployment, not implementation", "Both localization constants are deployment, not implementation.")
c("`localization_tol` and `localization_budget` are `Deployment` constructor keywords.",
  "`localization_tol` and `localization_budget` are constructor keywords of the `Deployment`")
c("They stand beside `h`, `N_base` and the algorithm (§9.2, Appendix B).",
  "They stand beside `h`, `N_base` and the algorithm (§9.2, Appendix B, D-256).", "C",
  cites=["§9.2", "Appendix B"], newcites=["§9.2", "Appendix B", "D-256"])
c("They are validated with their siblings, as a positive tolerance and an integer budget ≥ 1,",
  "- a nonpositive `localization_tol`; - a `localization_budget` or a `firing_budget` that is not an integer ≥ 1.",
  "M", where=S, ruling="R5")
c("and failures are collected into `DeploymentInvalid` (Appendix C).",
  "and failures are collected into `DeploymentInvalid`, as §9.2 and Appendix C set out.", "R",
  cites=["Appendix C"], newcites=["§9.2", "Appendix C"], ruling="R5")
c("The `firing_budget` (§10.6) stands beside them in every one of these lists.",
  "The constructor validates them with the third event parameter, the `firing_budget` of §10.6,", "R",
  cites=["§10.6"], ruling="R5")
c("It gets the same validation, the same `DeploymentInvalid`,",
  "- a `localization_budget` or a `firing_budget` that is not an integer ≥ 1.", "M", where=S, ruling="R5")
c("the same trace header and the same replay comparison.",
  "All three are recorded (D-133, D-181), because they determine the trajectory.", "R", newcites=[], ruling="R5")
c("Both are grid-independent, so neither enters the harmonic-grid check (§10.5).",
  "All three are grid-independent, so none enters the harmonic-grid check (§10.5).", "R", cites=["§10.5"], ruling="R8")
c("Because they determine the trajectory, both are recorded.",
  "All three are recorded (D-133, D-181), because they determine the trajectory.", "R",
  newcites=["D-133", "D-181"], ruling="R8")
c("They ride the trace header's `Deployment`",
  "They ride the `Deployment` in the trace header (the trace's fixed preamble, §11.5).", newcites=["§11.5"])
c("(the scalar-free artifact the grid parameters fix)",
  "`Deployment` (the scalar-free artifact the grid parameters fix).", "X")
c("and join the set that replay compares up front, exactly as `h` and the algorithm do (§11.5, §12.7).",
  "They also join the set that replay compares up front, exactly as `h` and the algorithm do (§12.7).",
  cites=["§11.5", "§12.7"], newcites=["§12.7"])
c("Why. Without this, the replays-identically promise above is empty.", "Without this record, the replays-identically promise above is empty.")
c("A run that does not record what its localizer was told to do cannot be re-driven through the same localization outcomes.",
  "A run that does not record what its localizer was told to do cannot be re-driven through the same localization outcomes.")

added = [
    "#### The localization budget",
    "#### Deployment constants",
    "The due sets of §10.5 give the full reason.",
    "no-throw",
    "(the remainder step's length)",
    "(§13.4)",
]
here = os.path.dirname(os.path.abspath(__file__))
json.dump({"claims": C, "added": added}, open(os.path.join(here, "inventory.json"), "w"),
          ensure_ascii=False, indent=1)
print(len(C), "claims")
