# Scratch: builds inventory.json for unit B1. Run from docs/spec_rewrite.
import json, re
CITE = re.compile(r'§\d+(?:\.\d+)?|D-\d{3}|Appendix [A-D]')
C = []  # (old, new, tag, ruling)
def c(old, new, tag="F", ruling=None): C.append((old, new, tag, ruling))

c("### 10.4 Localization mechanics", "### 10.4 Localization mechanics")
c("A guard's predicate can cross inside an integration step, strictly between two grid points.",
  "A guard's predicate can cross inside an integration step, strictly between two grid points.")
c("The framework can handle such a crossing in two ways. It can notice the crossing at the end of the step, at grid resolution. Or it can find the crossing instant and publish it.",
  "The framework can handle such a crossing in two ways. It can notice the crossing at the end of the step, at grid resolution. Or it can find the crossing instant and publish it.")
c("This section fixes which guards get which treatment, and describes the machinery behind the second.",
  "This section fixes which guards get which treatment, and describes the machinery behind the second.", "X")
c("A frame in which one event localizes runs through these steps,",
  "A frame in which one event localizes runs through these steps.")
c("with boundaries in bold:", "Its boundaries are tₙ, `t` and tₙ₊₁.", "X")
c("> tₙ → integrate → arrival sweep at tₙ₊₁ → trigger → θ = 0 trial evaluation → bracket > → root-find → t\\ → remainder step → tₙ₊₁",
  "> tₙ → integrate → arrival sweep at tₙ₊₁ → trigger → θ = 0 trial evaluation → bracket > → root-find → t\\ → remainder step → tₙ₊₁")
c("This chain lists the order of operations. It is not a walk along the time axis.",
  "This chain lists the order of operations. It is not a walk along the time axis.")
c("The arrival sweep at tₙ₊₁ raises the trigger, and integration then resumes from `t`, which lies before tₙ₊₁.",
  "The arrival sweep at tₙ₊₁ raises the trigger, and integration then resumes from `t`, which lies before tₙ₊₁.")
# Detection policy
c("#### Which guards localize: the form is the policy", "#### Detection policy", "X")
c("Rule. The guard's return type declares its detection policy. No flag is involved.",
  "The guard's return type declares its detection policy (D-179). No flag is involved.", "C")
c("- A guard returning `Bool` is boundary-detected. The framework checks it for edges at step boundaries only and never root-finds it.",
  "- A guard returning `Bool` is boundary-detected. The framework checks it for edges at step boundaries only and never root-finds it.")
c("- A guard returning the nominal scalar, the continuous sign form, is localized. The framework brackets the crossing instant by root-finding over trial sweeps.",
  "- A guard returning the nominal scalar, the continuous sign form, is localized. The framework brackets the crossing instant by root-finding over trial sweeps.")
c("The build reads the policy off the probe it already runs (§9.3, nominal activation).",
  "The build reads the policy off the probe it already runs (§9.3, nominal activation).")
c("`StateEvent(guard, handler)` therefore carries no detection keyword (D-179).",
  "`StateEvent(guard, handler)` therefore carries no detection keyword (D-179).")
c("Why. Localization brackets a root, and only the sign form offers one.",
  "Localization brackets a root, and only the sign form offers one.")
c("Because the form is the policy, the illegal pairing cannot be written at all. It needs no diagnostic.",
  "Because the form is the policy, the illegal pairing cannot be written at all. It needs no diagnostic.")
c("A localized guard becomes boundary-detected with a one-line rewrite, at no semantic cost.",
  "A localized guard becomes boundary-detected with a one-line rewrite, at no semantic cost (D-179).", "C")
c("Return the predicate `σ ≥ 0` instead of `σ`. That cast is the definition of the predicate (§2.1).",
  "Return the predicate `σ ≥ 0` instead of `σ`. That cast is the definition of the predicate (§2.1).")
c("The predicate and its edges stay the same. Only the resolution at which they are observed changes.",
  "The predicate and its edges stay the same. Only the resolution at which they are observed changes.")
c("#### Boundary detection is exact for guards over `u` and `m` alone Rule. For a guard that reads only `u` and `m`, boundary detection is exact.",
  "For a guard that reads only `u` and `m`, boundary detection is exact (D-179).", "C")
c("Why. Such a predicate is constant within each frame.", "Such a predicate is constant within each frame.")
c("`u` changes only at the frame-top drain (§11.4), and `m` changes only through handlers, at boundaries.",
  "`u` changes only at the frame-top drain (the swap that publishes staged device writes into the root inputs, §11.4), and `m` changes only through handlers, at boundaries.")
c("The predicate cannot cross mid-step, so there is no interior instant for a root-finder to find.",
  "The predicate cannot cross mid-step, so there is no interior instant for a root-finder to find.")
c("Here the boundary is not a resolution limit. It is the crossing itself, and localization would have nothing to do.",
  "Here the boundary is not a resolution limit. It is the crossing itself, and localization would have nothing to do.")
c("#### Mixed predicates: the gate idiom", "A mixed predicate combines `Bool` factors with a continuous one.", "X")
c("The piston engine's `starting → running` fires on `ω > ω_idle && fuel_available`.",
  "Take a piston engine whose modes include `starting` and `running`. The piston engine's `starting → running` fires on `ω > ω_idle && fuel_available`.",
  "R", "R8-F14")
c("Rule. When such a transition should localize, write it in the gate form `(gate) ? σ : -one(σ)`.",
  "When such a transition should localize, write it in the gate form `(gate) ? σ : -one(σ)` (D-179).", "C")
c("The `Bool` factors go in the branch condition and the continuous factor in the value.",
  "The `Bool` factors go in the branch condition and the continuous factor in the value.")
c("Why. The idiom is sound rather than a way around the policy check.",
  "The gate idiom is sound rather than a way around the policy check.")
c("Trial evaluations vary only θ.", "Trial evaluations (below) vary only θ, the normalized time within the step.")
c("`u` and `m` stay fixed through a localization, so the gates are constant over the bracket.",
  "`u` and `m` stay fixed through a localization, so the gates are constant over the bracket.")
c("Restricted to the bracket, σ is the continuous atom, and it can be bracketed as such.",
  "Restricted to the bracket, σ is the continuous atom, and it can be bracketed as such.")
# Trigger
c("#### The trigger", "#### The trigger")
c("Rule. A localized event triggers when its predicate was not-holding at tₙ's quiescence (the fixed point where a round of handlers fires nothing) and is holding at tₙ₊₁.",
  "A localized event triggers when its predicate was not-holding at tₙ's quiescence and is holding at tₙ₊₁ (D-082). Quiescence is the fixed point where a round of handlers fires nothing.", "C")
c("The tₙ sample is the event's prior, the predicate sample stored at the previous boundary (§10.6).",
  "The tₙ sample is the event's prior, the predicate sample stored at the previous boundary (§10.6).")
c("This is the directional edge of §2.1, not a bare sign change.", "This is the directional edge of §2.1, not a bare sign change.")
c("A holding → not-holding transition neither fires nor localizes.", "A holding → not-holding transition neither fires nor localizes.")
c("The trigger check runs against the arrival sweep at tₙ₊₁.", "The trigger check runs against the arrival sweep at tₙ₊₁ (D-182).", "C")
c("That is the sweep that closes the integration step. So the check runs before the due-gated boundary sweep refreshes any discrete cell.",
  "That is the sweep that closes the integration step. So the check runs before the due-gated boundary sweep refreshes any discrete cell.")
c("The rule that trial evaluations run the interior sweep (below) already forces this order, because trial evaluations must see the values the frame actually held.",
  "The rule that trial evaluations run the interior sweep (above) already forces this order, because trial evaluations must see the values the frame actually held.")
c("Stating it here fixes the sequencing up front.", "Stating it here fixes the sequencing up front.", "X")
c("Every `t` firing precedes tₙ₊₁'s whole boundary sequence.", "Every `t` firing precedes tₙ₊₁'s whole boundary sequence.")
# Loop
c("#### The localization loop", "#### The localization loop")
c("The sketch below shows one localized event within one frame. Every step is normed afterwards.",
  "The sketch below shows one localized event within one frame. Every step is normed afterwards.", "X")
c("# θ = (t − tₙ)/h, and every σ(θ) is a trial evaluation: write the state, run # the interior sweep, evaluate the guard. σ₁ = σ(1) # already computed by the arrival sweep (prior not-holding && σ₁ holding) || return # no trigger, nothing to localize",
  "# θ = (t − tₙ)/h, and every σ(θ) is a trial evaluation: write the state, run # the interior sweep, evaluate the guard. σ₁ = σ(1) # already computed by the arrival sweep (prior not-holding && σ₁ holding) || return # no trigger, nothing to localize")
c("σ₀ = σ(0) # the θ = 0 validation: x̂(0) = xₙ, no interpolant σ₀ holding && return # epoch-caused edge: fall through to tₙ₊₁",
  "σ₀ = σ(0) # the θ = 0 validation: x̂(0) = xₙ, no interpolant σ₀ holding && return # epoch-caused edge: fall through to tₙ₊₁")
c("build x̂ from (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁) # one sweep for ẋₙ₊₁, paid only here lo, hi = 0, 1 # the not-holding / holding bracket, in θ while hi - lo > localization_tol # relative: bracket width (hi − lo)·h vs. tol·h θ = next bracketed guess in (lo, hi) # ITP, Brent or bisection σ(θ) holding ? (hi = θ) : (lo = θ) end t = tₙ + hi·h # the holding endpoint of the final bracket",
  "build x̂ from (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁) # one sweep for ẋₙ₊₁, paid only here lo, hi = 0, 1 # the not-holding / holding bracket, in θ while hi - lo > localization_tol # relative: bracket width (hi − lo)·h vs. tol·h θ = next bracketed guess in (lo, hi) # ITP, Brent or bisection σ(θ) holding ? (hi = θ) : (lo = θ) end t = tₙ + hi·h # the holding endpoint of the final bracket")
c("The θ = 0 validation. On trigger, the first act is a trial evaluation at the left end.",
  "On trigger, the first act is a trial evaluation at the left end, the θ = 0 validation (D-182).", "C")
c("Write xₙ into the state buffer, run one interior sweep, and evaluate the guard to get σ₀.",
  "Write xₙ into the state buffer, run one interior sweep, and evaluate the guard to get σ₀.")
c("Nothing new is kept, since the stepper already retains xₙ for the interpolant",
  "Nothing new is kept, since the stepper already retains xₙ for the interpolant.")
c("(the cubic Hermite continuous extension over the last completed step).",
  "(the cubic Hermite continuous extension over the last completed step)", "X")
c("This trial evaluation needs no interpolant, because x̂(0) = xₙ identically. So it runs before any interpolant cost is paid.",
  "This trial evaluation needs no interpolant, because x̂(0) = xₙ identically. So it runs before any interpolant cost is paid.")
c("The evaluation serves two purposes. σ₀ is the left bracket value that value-based root-finders need.",
  "The evaluation serves two purposes. σ₀ is the left bracket value that value-based root-finders need.")
c("σ₁ = σ(tₙ₊₁) is retained from the arrival evaluation, but σ₀ had no source until now.",
  "σ₁ = σ(tₙ₊₁) is retained from the arrival evaluation, but σ₀ had no source until now.")
c("And σ₀ tells the edge's cause apart.", "And σ₀ tells the edge's cause apart.")
c("That discrimination needs one term.", "That discrimination needs one term.", "X")
c("An input epoch is a maximal span of constant `u`, delimited by frame-top drains (§11.4).",
  "An input epoch is a maximal span of constant `u`, delimited by frame-top drains (§11.4).")
c("Within an epoch a guard can change only through the trajectory. At a seam between epochs it can jump without crossing anything.",
  "Within an epoch a guard can change only through the trajectory. At a seam between epochs it can jump without crossing anything.")
c("Why the discriminator is conclusive. `u` is the only thing that can differ between the prior's evaluation context and this trial evaluation.",
  "The discriminator is conclusive (D-182). `u` is the only thing that can differ between the prior's evaluation context and this trial evaluation.", "C")
c("`m` changes only via handlers at boundaries, and priors are sampled at quiescence, after the handlers.",
  "`m` changes only via handlers at boundaries, and priors are sampled at quiescence, after the handlers.")
c("Discrete cells hold their values under ZOH, and the interior sweep excludes discrete entries (§10.5).",
  "Discrete cells hold their values under zero-order hold (ZOH), and the interior sweep excludes discrete entries (§10.5).")
c("`t = tₙ` exactly, by the indexed-grid rule below. Sweeps are deterministic.",
  "`t = tₙ` exactly, by the indexed-grid rule below. Sweeps are deterministic.")
c("So under the honest priors of §10.6, the frame-top drain is the only possible source of disagreement.",
  "So under the honest priors of §10.6, the frame-top drain is the only possible source of disagreement.")
c("- σ₀ not-holding means a trajectory-caused edge, a genuine in-frame crossing.",
  "- σ₀ not-holding means a trajectory-caused edge, a genuine in-frame crossing.")
c("Pay the sweep for ẋₙ₊₁, build the interpolant and root-find on the bracket $(t_n, \\sigma_0)$/$(t_{n+1}, \\sigma_1)$.",
  "Pay the sweep for ẋₙ₊₁, build the interpolant and root-find on the bracket $(t_n, \\sigma_0)$/$(t_{n+1}, \\sigma_1)$.")
c("- σ₀ holding means an epoch-caused edge. The drain flipped the guard at the frame top.",
  "- σ₀ holding means an epoch-caused edge. The drain flipped the guard at the frame top.")
c("σ holds at both ends, so there is no in-frame crossing to find.", "σ holds at both ends, so there is no in-frame crossing to find.")
c("An epoch-caused edge is discarded, not degraded.", "An epoch-caused edge is discarded, not degraded (D-182).", "C")
c("The localization is abandoned and the event fires inside tₙ₊₁'s ordinary iteration.",
  "The localization is abandoned and the event fires inside tₙ₊₁'s ordinary iteration.")
c("Mechanically, not localizing is the action. The frame falls through, and the boundary iteration detects and fires the event like any boundary-detected event.",
  "Mechanically, not localizing is the action. The frame falls through, and the boundary iteration detects and fires the event like any boundary-detected event.")
c("This path costs one interior sweep. It never pays for ẋₙ₊₁ or an interpolant, and it consumes no `localization_budget`. It also warns nothing.",
  "This path costs one interior sweep. It never pays for ẋₙ₊₁ or an interpolant, and it consumes no `localization_budget` (see \"The localization budget\" below). It also warns nothing.")
c("Input timing is a frame fact, by the same doctrine that forbids draining at `t` below, and boundary detection is exact for a `u`-caused edge (above; D-179).",
  "Input timing is a frame fact, by the same doctrine that forbids draining at `t` below, and boundary detection is exact for a `u`-caused edge (above; D-179).")
c("Boundary firing is therefore the correct semantics, not a degradation.", "Boundary firing is therefore the correct semantics, not a degradation.")
c("This is the left-end mirror of the `t = tₙ₊₁` degeneracy below.", "This is the left-end mirror of the `t = tₙ₊₁` degeneracy below.")
c("The interpolant is built lazily.", "The interpolant is built lazily (D-018).", "C")
c("It is the cubic Hermite continuous extension $\\hat{x}(\\theta)$, $\\theta = (t - t_n)/h \\in [0, 1]$, built from $(x_n, \\dot{x}_n, x_{n+1}, \\dot{x}_{n+1})$.",
  "It is the cubic Hermite continuous extension $\\hat{x}(\\theta)$, $\\theta = (t - t_n)/h \\in [0, 1]$, built from $(x_n, \\dot{x}_n, x_{n+1}, \\dot{x}_{n+1})$.")
c("$\\dot{x}_n$ is the step's first stage.", "$\\dot{x}_n$ is the step's first stage.")
c("$\\dot{x}_{n+1}$ costs one sweep, paid only on a validated trigger.",
  "$\\dot{x}_{n+1}$ costs one sweep, paid only on a validated trigger (D-182).", "C")
c("The θ = 0 trial evaluation comes first, so an epoch-caused edge never pays for it.",
  "The θ = 0 trial evaluation comes first, so an epoch-caused edge never pays for it.")
c("Uniform accuracy is $O(h^4)$, one order below the discrete solution, which is the standard pairing.",
  "Uniform accuracy is $O(h^4)$, one order below the discrete solution, which is the standard pairing.")
c("The event time can never be more accurate than the interpolant, so nothing more expensive is worth running trials against.",
  "The event time can never be more accurate than the interpolant, so nothing more expensive is worth running trials against.")
# Trial evaluations block (moved up, M10)
c("Trial evaluations run the interior sweep.", "Trial evaluations run the interior sweep (D-147).", "C")
c("Guards read `y`. Evaluating a guard at an interpolated state therefore means writing $\\hat{x}(\\theta)$ into the state buffer and running the interior sweep.",
  "Guards read `y`. Evaluating a guard at an interpolated state therefore means writing $\\hat{x}(\\theta)$ into the state buffer and running the interior sweep.")
c("The RHS already lives under this rule (§10.5), since a trial evaluation is a mid-step evaluation.",
  "The RHS already lives under this rule (§10.5), since a trial evaluation is a mid-step evaluation.")
c("Discrete cells therefore hold their tick values through localization, and a guard reading a sampled output sees what the controller is holding.",
  "Discrete cells therefore hold their tick values through localization, and a guard reading a sampled output sees what the controller is holding.")
c("Each trial evaluation costs one interior sweep.", "Each trial evaluation costs one interior sweep.")
# Root-finding, convergence
c("Root-finding is bracketed and derivative-free.", "Root-finding is bracketed and derivative-free (D-018).", "C")
c("ITP or Brent are the intended methods, and bisection is an acceptable fallback.",
  "ITP or Brent are the intended methods, and bisection is an acceptable fallback.")
c("The observed not-holding/holding bracket is an unconditional convergence certificate.",
  "The observed not-holding/holding bracket is an unconditional convergence certificate.")
c("Newton and AD localization are rejected (D-018).", "Newton and AD localization are rejected (D-018).")
c("Convergence is a relative bracket width. Localization stops once the bracket is narrower than `localization_tol · h`.",
  "Convergence is a relative bracket width (D-133). Localization stops once the bracket is narrower than `localization_tol · h`.", "C")
c("`localization_tol` is a `Deployment` constructor keyword defaulting to `1e-6`.",
  "`localization_tol` is a `Deployment` constructor keyword defaulting to `1e-6` (D-256).", "C")
c("The tolerance is relative because an absolute tolerance in `t` is not scale-free (D-133).",
  "The tolerance is relative because an absolute tolerance in `t` is not scale-free (D-133).")
c("The default is `1e-6` because the event time can never be more accurate than the interpolant, which is `O(h⁴)` as stated above.",
  "The default is `1e-6` because the event time can never be more accurate than the interpolant, which is `O(h⁴)` as stated above.")
c("At practical `h`, anything tighter buys nothing, while every trial evaluation costs a full sweep.",
  "At practical `h`, anything tighter buys nothing, while every trial evaluation costs a full sweep.")
c("Under ITP the bill is a handful of trial evaluations, and around 20 in bisection's worst case.",
  "Under ITP the bill is a handful of trial evaluations, and around 20 in bisection's worst case.")
# Post-event
c("Post-event. The boundary sequence runs at `t` (below).", "After the event, the boundary sequence runs at `t` (below).")
c("The interpolant is then invalidated, because the handlers have made it wrong for `t > t`.",
  "The interpolant is then invalidated, because the handlers have made it wrong for `t > t` (D-018).", "C")
c("Integration resumes from `t` with the remainder step targeting tₙ₊₁, and the guards are re-checked on the remainder.",
  "Integration resumes from `t` with the remainder step targeting tₙ₊₁, and the guards are re-checked on the remainder.")
c("The re-check runs under the per-frame localization budget, with a chattering diagnostic.",
  "The re-check runs under the per-frame localization budget (below), with a chattering diagnostic.")
c("Multiple events localizing in one step fire at the earliest `t`.", "Multiple events localizing in one step fire at the earliest `t`.")
c("Ties fire at that boundary inside the event iteration, one eligible event per component per round in declaration order (§10.6).",
  "Ties fire at that boundary inside the event iteration, one eligible event per component per round in declaration order (§10.6, D-154).", "C")
c("Later crossings re-localize on the remainder.", "Later crossings re-localize on the remainder.")
c("Both policies share one blind spot.", "Both policies share one blind spot.")
c("An even number of crossings within one step returns the predicate to not-holding at the boundary, so no edge is observed.",
  "An even number of crossings within one step returns the predicate to not-holding at the boundary, so no edge is observed.")
c("Neither policy can detect this. The mitigation is a smaller step size, not more machinery.",
  "Neither policy can detect this. The mitigation is a smaller step size, not more machinery.")

ADDED = [
  "The localized event time `t` is a boundary (a published consistency point, §10.1). It is not the top of a frame (one grid step, the unit of scheduling).",
  "the swap that publishes staged device writes into the root inputs,",
  "Take a piston engine whose modes include `starting` and `running`.",
  "(below)",
  ", the normalized time within the step",
  "#### Trial evaluations",
  "A trial evaluation computes a guard's value at one instant θ inside the step. At θ = 0 its state is xₙ itself. Elsewhere its state is x̂(θ), a point on the interpolant",
  ", which the localization loop below defines and builds.",
  "zero-order hold (",
  "(see \"The localization budget\" below)",
  "A tick is an instant at which a discrete component's stages and update run.",
]
claims = []
for i, (o, n, tag, r) in enumerate(C, 1):
    d = {"id": f"B1-{i:03d}", "old": o, "new": n, "where": "new", "cites": CITE.findall(o)}
    nc = CITE.findall(n)
    if set(nc) != set(d["cites"]): d["newcites"] = nc
    d["tag"] = tag
    if r: d["ruling"] = r
    claims.append(d)
json.dump({"claims": claims, "added": ADDED}, open("ch10/units/B1/inventory.json", "w"), ensure_ascii=False, indent=1)
print(len(claims), "claims")
