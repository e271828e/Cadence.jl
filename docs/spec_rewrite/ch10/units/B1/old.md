### 10.4 Localization mechanics

A [guard](#g-guard)'s [predicate](#g-predicate) can cross inside an integration step, strictly between two
grid points. The framework can handle such a crossing in two ways. It can notice
the crossing at the end of the step, at grid resolution. Or it can find the
crossing instant and publish it. This section fixes which guards get which
treatment, and describes the machinery behind the second.


A frame in which one event localizes runs through these steps, with boundaries
in bold:

> **tₙ** → integrate → arrival sweep at tₙ₊₁ → trigger → θ = 0 trial evaluation → bracket
> → root-find → **t\*** → remainder step → **tₙ₊₁**

This chain lists the order of operations. It is not a walk along the time axis.
The arrival sweep at tₙ₊₁ raises the trigger, and integration then resumes from
`t*`, which lies before tₙ₊₁.

#### Which guards localize: the form is the policy

**Rule.** The guard's return type declares its detection policy. No flag is
involved.

- A guard returning `Bool` is **[boundary-detected](#g-boundary-detected)**. The framework checks it for
  edges at step boundaries only and never root-finds it.
- A guard returning the nominal scalar, the continuous sign form, is
  **[localized](#g-localized)**. The framework brackets the crossing instant by root-finding
  over trial sweeps.

The build reads the policy off the [probe](#g-probe) it already runs ([§9.3][s9-3], nominal
[activation](#g-activation)). `StateEvent(guard, handler)` therefore carries no detection keyword
([D-179][d-179]).

**Why.** Localization brackets a root, and only the sign form offers one.
Because the form is the policy, the illegal pairing cannot be written at all. It
needs no diagnostic.

**A localized guard becomes boundary-detected with a one-line rewrite, at no
semantic cost.** Return the predicate `σ ≥ 0` instead of `σ`. That cast is the
definition of the predicate ([§2.1][s2-1]). The predicate and its edges stay the same.
Only the resolution at which they are observed changes.

#### Boundary detection is exact for guards over `u` and `m` alone

**Rule.** For a guard that reads only `u` and `m`, boundary detection is exact.

**Why.** Such a predicate is constant within each frame. `u` changes only at the
frame-top drain ([§11.4][s11-4]), and `m` changes only through handlers, at boundaries.
The predicate cannot cross mid-step, so there is no interior instant for a
root-finder to find. Here the boundary is not a resolution limit. It is the
crossing itself, and localization would have nothing to do.

#### Mixed predicates: the gate idiom

The piston engine's `starting → running` fires on
`ω > ω_idle && fuel_available`.

**Rule.** When such a transition should localize, write it in the gate form
`(gate) ? σ : -one(σ)`. The `Bool` factors go in the branch condition and the
continuous factor in the value.

**Why.** The idiom is sound rather than a way around the policy check. Trial
evaluations vary only θ. `u` and `m` stay fixed through a localization, so the
gates are constant over the bracket. Restricted to the bracket, σ is the
continuous atom, and it can be bracketed as such.

#### The trigger

**Rule.** A localized event triggers when its predicate was not-[holding](#g-edge-semantics) at tₙ's
[quiescence](#g-quiescence) (the fixed point where a round of handlers fires nothing) and is
holding at tₙ₊₁. The tₙ sample is the event's **[prior](#g-prior)**, the predicate sample
stored at the previous boundary ([§10.6][s10-6]).

This is the directional edge of [§2.1][s2-1], not a bare sign change. A holding →
not-holding transition neither fires nor localizes.

**The trigger check runs against the arrival [sweep](#g-sweep) at tₙ₊₁.** That is the sweep
that closes the integration step. So the check runs before the due-gated
[boundary sweep](#g-sweep) refreshes any discrete [cell](#g-cell). The rule that trial evaluations run
the interior sweep (below) already forces this order, because trial evaluations
must see the values the frame actually held. Stating it here fixes the
sequencing up front. Every `t*` firing precedes tₙ₊₁'s whole boundary sequence.

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

**The θ = 0 validation.** On trigger, the first act is a trial evaluation at the
left end. Write xₙ into the state [buffer](#g-buffer), run one [interior sweep](#g-sweep), and evaluate
the guard to get σ₀. Nothing new is kept, since the stepper already retains xₙ
for the [interpolant](#g-interpolant) (the cubic Hermite continuous extension over the last
completed step). This trial evaluation needs no interpolant, because x̂(0) = xₙ
identically. So it runs before any interpolant cost is paid.

The evaluation serves two purposes. σ₀ is the left bracket value that
value-based root-finders need. σ₁ = σ(tₙ₊₁) is retained from the arrival
evaluation, but σ₀ had no source until now. And σ₀ tells the edge's cause apart.

That discrimination needs one term. An **[input epoch](#g-input-epoch)** is a maximal span of
constant `u`, delimited by frame-top drains ([§11.4][s11-4]). Within an epoch a guard can
change only through the trajectory. At a seam between epochs it can jump without
crossing anything.

**Why the discriminator is conclusive.** `u` is the only thing that can differ
between the prior's evaluation context and this trial evaluation. `m` changes
only via handlers at boundaries, and priors are sampled at quiescence, after the
handlers. Discrete cells hold their values under ZOH, and the interior sweep
excludes discrete entries ([§10.5][s10-5]). `t = tₙ` exactly, by the indexed-grid rule
below. Sweeps are deterministic. So under the honest [priors](#g-prior) of [§10.6][s10-6], the
frame-top drain is the only possible source of disagreement.

- σ₀ **not-holding** means a **trajectory-caused** edge, a genuine in-frame
  crossing. Pay the sweep for ẋₙ₊₁, build the interpolant and root-find on the
  bracket $(t_n, \sigma_0)$/$(t_{n+1}, \sigma_1)$.
- σ₀ **holding** means an **epoch-caused** edge. The drain flipped the guard at
  the frame top. σ holds at both ends, so there is no in-frame crossing to find.

**An epoch-caused edge is discarded, not degraded.** The localization is
abandoned and the event fires inside tₙ₊₁'s ordinary iteration. Mechanically,
not localizing is the action. The frame falls through, and the boundary
iteration detects and fires the event like any boundary-detected event. This
path costs one interior sweep. It never pays for ẋₙ₊₁ or an interpolant, and it
consumes no `localization_budget`. It also warns nothing. Input timing is a
frame fact, by the same doctrine that forbids draining at `t*` below, and
boundary detection is exact for a `u`-caused edge (above; [D-179][d-179]). Boundary
firing is therefore the correct semantics, not a degradation. This is the
left-end mirror of the `t* = tₙ₊₁` degeneracy below.

**The interpolant is built lazily.** It is the cubic Hermite continuous
extension $\hat{x}(\theta)$, $\theta = (t - t_n)/h \in [0, 1]$, built from
$(x_n, \dot{x}_n, x_{n+1}, \dot{x}_{n+1})$. $\dot{x}_n$ is the step's first
stage. $\dot{x}_{n+1}$ costs one sweep, paid only on a validated trigger. The θ
= 0 trial evaluation comes first, so an epoch-caused edge never pays for it.
Uniform accuracy is $O(h^4)$, one order below the discrete solution, which is
the standard pairing. The event time can never be more accurate than the
interpolant, so nothing more expensive is worth running trials against.

**Trial evaluations run the interior sweep.** Guards read `y`. Evaluating a
guard at an interpolated state therefore means writing $\hat{x}(\theta)$ into
the state buffer and running the interior sweep. The [RHS](#g-flow) already lives under
this rule ([§10.5][s10-5]), since a trial evaluation is a mid-step evaluation. Discrete
cells therefore hold their [tick](#g-tick) values through localization, and a guard reading
a sampled output sees what the controller is holding. Each trial evaluation
costs one interior sweep.

**Root-finding is bracketed and derivative-free.** ITP or Brent are the intended
methods, and bisection is an acceptable fallback. The observed
not-holding/holding bracket is an unconditional convergence certificate. Newton
and AD localization are rejected ([D-018][d-018]).

**Convergence is a relative bracket width.** Localization stops once the bracket
is narrower than `localization_tol · h`. `localization_tol` is a `Deployment`
constructor keyword defaulting to `1e-6`. The tolerance is relative because an
absolute tolerance in `t` is not scale-free ([D-133][d-133]). The default is `1e-6`
because the event time can never be more accurate than the interpolant, which is
`O(h⁴)` as stated above. At practical `h`, anything tighter buys nothing, while
every trial evaluation costs a full sweep. Under ITP the bill is a handful of
trial evaluations, and around 20 in bisection's worst case.

**Post-event.** The boundary sequence runs at `t*` (below). The interpolant is
then invalidated, because the handlers have made it wrong for `t > t*`.
Integration resumes from `t*` with the [remainder step](#g-remainder-step) targeting tₙ₊₁, and the
guards are re-checked on the remainder. The re-check runs under the per-frame
[localization budget](#g-chattering), with a chattering diagnostic.

**Multiple events localizing in one step fire at the earliest `t*`.** Ties fire
at that boundary inside the event iteration, one eligible event per component
per round in declaration order ([§10.6][s10-6]). Later crossings re-localize on the
remainder.

**Both policies share one blind spot.** An even number of crossings within one
step returns the predicate to not-holding at the boundary, so no edge is
observed. Neither policy can detect this. The mitigation is a smaller step size,
not more machinery.

