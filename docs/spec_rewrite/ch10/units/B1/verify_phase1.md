# B1 verify, phase 1 (blind read of new.md)

Intro
- V1 A guard's predicate can cross inside an integration step, strictly between two grid points.
- V2 Two treatments: notice at end of step at grid resolution, or find the crossing instant and publish it.
- V3 This section fixes which guards get which treatment and describes the second's machinery.
- V4 The localized event time t* is a boundary (published consistency point, §10.1).
- V5 t* is not the top of a frame (frame = one grid step, unit of scheduling).
- V6 A frame with one localizing event has boundaries tₙ, t*, tₙ₊₁.
- V7 Order chain: tₙ → integrate → arrival sweep at tₙ₊₁ → trigger → θ=0 trial → bracket → root-find → t* → remainder step → tₙ₊₁.
- V8 The chain is order of operations, not a walk along time; arrival sweep at tₙ₊₁ raises trigger; integration resumes from t*, before tₙ₊₁.

Detection policy
- V9 [bold] Guard's return type declares its detection policy (D-179); no flag.
- V10 Bool guard is boundary-detected: checked for edges at step boundaries only, never root-found.
- V11 Guard returning nominal scalar (continuous sign form) is localized; framework brackets crossing by root-finding over trial sweeps.
- V12 Build reads policy off the probe it already runs (§9.3, nominal activation).
- V13 StateEvent(guard, handler) therefore carries no detection keyword (D-179).
- V14 Localization brackets a root; only the sign form offers one.
- V15 Because form is policy, illegal pairing cannot be written; needs no diagnostic.
- V16 Localized → boundary-detected via one-line rewrite at no semantic cost (D-179): return σ ≥ 0 instead of σ.
- V17 That cast is the definition of the predicate (§2.1); predicate and edges unchanged; only observation resolution changes.
- V18 [bold] For a guard reading only u and m, boundary detection is exact (D-179).
- V19 Such a predicate is constant within each frame.
- V20 u changes only at frame-top drain (swap publishing staged device writes into root inputs, §11.4).
- V21 m changes only through handlers, at boundaries.
- V22 Predicate cannot cross mid-step; no interior instant to find; boundary is the crossing itself, not a resolution limit; localization has nothing to do.
- V23 Mixed predicate combines Bool factors with a continuous one.
- V24 Example: piston engine with modes off/starting/running, as declared for Engine component in §8.2.
- V25 starting → running fires on ω > ω_idle && fuel_available.
- V26 [bold] When such a transition should localize, write gate form (gate) ? σ : -one(σ) (D-179); Bool factors in condition, continuous in value.
- V27 Gate idiom is sound, not a way around the policy check.
- V28 Trial evaluations vary only θ, normalized time within step.
- V29 u and m fixed through a localization; gates constant over bracket; restricted to bracket σ is the continuous atom, can be bracketed.

Trial evaluations
- V30 A trial evaluation computes a guard's value at one instant inside the step; its state is a point on the interpolant (cubic Hermite continuous extension over last completed step), built by the loop below.
- V31 [bold] Trial evaluations run the interior sweep (D-147).
- V32 Guards read y; evaluating at interpolated state = writing x̂(θ) into state buffer and running interior sweep.
- V33 RHS already lives under this rule (§10.5), since a trial evaluation is a mid-step evaluation.
- V34 Discrete cells hold tick values through localization; guard reading sampled output sees what controller holds.
- V35 Definition: tick = instant at which a discrete component's stages and update run.
- V36 Each trial evaluation costs one interior sweep.

The trigger
- V37 [bold] Localized event triggers when predicate was not-holding at tₙ's quiescence and holding at tₙ₊₁ (D-082).
- V38 Quiescence = fixed point where a round of handlers fires nothing.
- V39 The tₙ sample is the event's prior, predicate sample stored at previous boundary (§10.6).
- V40 This is the directional edge of §2.1, not bare sign change; holding → not-holding neither fires nor localizes.
- V41 [bold] Trigger check runs against arrival sweep at tₙ₊₁ (D-182).
- V42 That sweep closes the integration step; check runs before due-gated boundary sweep refreshes any discrete cell.
- V43 Trial-evaluations-run-interior-sweep rule already forces this order, because trial evaluations must see values the frame actually held.
- V44 Stating it fixes sequencing up front; every t* firing precedes tₙ₊₁'s whole boundary sequence.

The localization loop
- V45 Sketch shows one localized event within one frame; every step normed afterwards.
- V46 Sketch: θ = (t − tₙ)/h; every σ(θ) is a trial evaluation (write state, run interior sweep, evaluate guard).
- V47 σ₁ = σ(1) already computed by arrival sweep; no trigger → return.
- V48 σ₀ = σ(0): θ=0 validation, x̂(0) = xₙ, no interpolant; σ₀ holding → return, epoch-caused, fall through to tₙ₊₁.
- V49 Build x̂ from (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁); one sweep for ẋₙ₊₁, paid only here.
- V50 Bracket lo,hi = 0,1 not-holding/holding in θ; loop while hi−lo > localization_tol (relative: width·h vs tol·h); ITP, Brent or bisection; t* = tₙ + hi·h, holding endpoint.
- V51 [bold] On trigger, first act is trial evaluation at left end, θ=0 validation (D-182).
- V52 Write xₙ, run one interior sweep, evaluate guard → σ₀.
- V53 Nothing new kept; stepper already retains xₙ for interpolant.
- V54 Needs no interpolant since x̂(0)=xₙ identically; runs before interpolant cost.
- V55 Serves two purposes: σ₀ is the left bracket value value-based root-finders need; σ₁ retained from arrival evaluation, σ₀ had no source; σ₀ tells edge's cause apart.
- V56 Definition: input epoch = maximal span of constant u, delimited by frame-top drains (§11.4).
- V57 Within epoch guard changes only through trajectory; at seam it can jump without crossing.
- V58 Discriminator is conclusive (D-182).
- V59 u is the only thing that can differ between prior's context and this trial evaluation.
- V60 m changes only via handlers at boundaries; priors sampled at quiescence, after handlers.
- V61 Discrete cells hold under ZOH; interior sweep excludes discrete entries (§10.5).
- V62 t = tₙ exactly by indexed-grid rule below; sweeps deterministic.
- V63 Under honest priors of §10.6, frame-top drain is only possible source of disagreement.
- V64 σ₀ not-holding → trajectory-caused edge, genuine in-frame crossing; pay ẋₙ₊₁ sweep, build interpolant, root-find on bracket (tₙ,σ₀)/(tₙ₊₁,σ₁).
- V65 σ₀ holding → epoch-caused edge; drain flipped guard at frame top; σ holds at both ends; no in-frame crossing.
- V66 [bold] Epoch-caused edge discarded, not degraded (D-182).
- V67 Localization abandoned; event fires inside tₙ₊₁'s ordinary iteration; not localizing is the action; frame falls through; boundary iteration detects and fires as boundary-detected.
- V68 Path costs one interior sweep; never pays ẋₙ₊₁ or interpolant; consumes no localization_budget; warns nothing.
- V69 Input timing is a frame fact, by same doctrine forbidding draining at t* (below); boundary detection exact for u-caused edge (above; D-179).
- V70 Boundary firing therefore correct semantics, not degradation; left-end mirror of t* = tₙ₊₁ degeneracy below.
- V71 Interpolant built lazily (D-018).
- V72 Cubic Hermite x̂(θ), θ ∈ [0,1], from (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁); ẋₙ is step's first stage.
- V73 ẋₙ₊₁ costs one sweep, paid only on validated trigger (D-182); θ=0 first so epoch-caused never pays.
- V74 Uniform accuracy O(h⁴), one order below discrete solution, standard pairing.
- V75 Event time can never be more accurate than interpolant; nothing more expensive worth running trials against.
- V76 [bold] Root-finding bracketed and derivative-free (D-018).
- V77 ITP or Brent intended; bisection acceptable fallback.
- V78 Observed not-holding/holding bracket is unconditional convergence certificate.
- V79 Newton and AD localization rejected (D-018).
- V80 [bold] Convergence is a relative bracket width (D-133); stops once bracket < localization_tol · h.
- V81 localization_tol is a Deployment constructor keyword defaulting to 1e-6 (D-256).
- V82 Relative because absolute tolerance in t is not scale-free (D-133).
- V83 Default 1e-6 because event time ≤ interpolant accuracy O(h⁴); at practical h tighter buys nothing; every trial costs a full sweep.
- V84 Under ITP a handful of trials; ~20 in bisection worst case.
- V85 After event, boundary sequence runs at t* (below).
- V86 [bold] Interpolant then invalidated, because handlers made it wrong for t > t* (D-018).
- V87 Integration resumes from t* with remainder step targeting tₙ₊₁; guards re-checked on remainder.
- V88 Re-check runs under per-frame localization budget (below), with chattering diagnostic.
- V89 Multiple events localizing in one step fire at earliest t*.
- V90 Ties fire at that boundary inside event iteration, one eligible event per component per round in declaration order (§10.6, D-154).
- V91 Later crossings re-localize on the remainder.
- V92 Both policies share one blind spot: even number of crossings in one step returns predicate to not-holding at boundary, no edge observed; neither can detect.
- V93 Mitigation is smaller step size, not more machinery.
