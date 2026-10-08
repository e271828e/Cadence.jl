# The limited integrator: the exact-zero defect, the variants weighed, and the two policies

*A companion record, not normative text. The ground truth is `spec.md`
[§2.1][s2-1] (events and edge semantics), [§10.4][s10-4] (detection policy, the gate form
and localization), [§10.6][s10-6] (priors and quiescence) and [§13.7][s13-7] (the library),
with decisions [D-179][d-179] and [D-313][d-313]. If this document and the spec ever
disagree, the spec wins. It was written on 2026-10-07, when the block's
second detection policy was briefed, to keep the reasoning that found a
defect in the first shipped form, ruled out every continuous remedy, and
settled on two policies.*

The block is the inventory's demonstrator for modes and events
(`library_inventory.md`, section 2): a limited integrator is not a clamp
but a mode read by the derivative, with events that move the mode. Building
it exposed a corner that the framework's edge semantics make unavoidable,
and the search for a fix produced a comparison of implementation variants
that is worth more than the fix. Sections 1 and 2 state the block and the
defect, section 3 proves that no continuous guard can repair it, section 4
weighs the remedies, section 5 analyses the kinks that decide the cheap
variant's accuracy, section 6 records the decision, and section 7 notes
what the episode says about the framework.

## 1. The block

One continuous state `q`, one mode `saturation` in `:free`, `:upper` or
`:lower`, and a derivative that reads the mode: `q̇ = in` while free and
`q̇ = 0` while saturated. Four state events move the mode. A sign-form
guard returns a scalar σ, the predicate holds when `σ ≥ 0`, and an event
fires on an edge, the transition from not-holding to holding, which the
framework detects against the guard's prior, its value at the last
quiescent boundary ([§2.1][s2-1], [§10.6][s10-6]).

```julia
hit_upper_guard(c, (; x))   = x.q - c.upper                        # ungated
hit_upper_handler(c, _)     = (x = (q = c.upper,), m = (saturation = :upper,))
leave_upper_guard(c, (; m, u)) = m.saturation === :upper ? -u.in : -one(u.in)   # the first form
leave_handler(c, _)         = (m = (saturation = :free,),)
```

The hit guards are deliberately ungated. Gated on `:free`, a hit guard
would read `-1` while saturated and `q - upper = 0` the instant a leave
handler frees the mode. That is an edge, so it would fire and saturate the
block again, with the leave guard then holding and unable to fire. The
leave guards are gated by the mode in [§10.4][s10-4]'s gate form, `(gate) ? σ :
-one(σ)`, which is sound because the mode is constant through a
localization.

## 2. The defect

Let the block be saturated at `upper` and let the input fall to exactly
`0.0`. The first leave guard computes `-u.in`, which is `-0.0`, and in IEEE
arithmetic `-0.0 ≥ 0` is true because `-0.0 == 0.0`. The predicate holds,
its prior was not-holding, and the leave event fires: the mode is `:free`
with `q` sitting exactly on the limit.

Now the hit guard reads `q - upper = 0`, which holds, and it has held since
the hit fired. When a later input pushes outward, `q` rises, σ turns
positive, and the predicate is still holding. There is no edge, the hit
event never fires again, and `q` passes the limit with nothing to stop it.
The reviewer's scenario stepped the input from `1` to `0` at `t = 1.05`
and back to `1` at `t = 2.05` into a block limited at `0.5`; by `t = 3` the
state read `1.45`, mode `:free`. The mirror case at the lower limit reads
`-1.45`. The corner also bites at boundary zero, which sets every prior to
not-holding ([§10.6][s10-6]): an `x0` on the limit with a zero input frees there and
overshoots later.

The root cause is that edge semantics cannot re-detect a predicate that
never stopped holding, and freeing the mode with `q` on the limit is
exactly the state in which the hit predicate holds without an edge.

## 3. Why no continuous guard can repair it

Two facts hold for any design that keeps a latched mode read by the
derivative, whatever continuous σ its guards compute.

- **The hit predicate cannot re-arm at the rest point.** To be safe, "hit
  upper" must hold whenever `q > upper`, for every input. Approach the rest
  point `(q, in) = (upper, 0)` along `q ↓ upper` with `in = 0`: σ is
  positive all the way, so by continuity `σ(upper, 0) ≥ 0`, which holds.
  Whenever the block is free at the rest point, the hit predicate is already
  holding and can produce no edge. This is true of any continuous σ, in
  whatever mixture of `q` and `in`.
- **So the block must never be free at the rest point**, which means
  "leave" must require `in < 0` strictly. No continuous σ satisfies
  `σ ≥ 0 ⟺ in < 0`: at `in = 0` it would have to be negative and the limit
  of positive values at once.

Together they say that with a latched mode, some guard must be
discontinuous at the crossing. The question is only where to put the
discontinuity, or whether to give up the latch.

## 4. The remedies weighed

**The strict gate, chosen.** The leave guards gate on strictly inward input
as well as on the mode:

```julia
leave_upper_guard(c, (; m, u)) = m.saturation === :upper && u.in < 0 ? -u.in : -one(u.in)
leave_lower_guard(c, (; m, u)) = m.saturation === :lower && u.in > 0 ?  u.in : -one(u.in)
```

An input of exactly zero at a limit now keeps the mode saturated, which
changes nothing observable in `q`, since the derivative is zero in both
modes at zero input. The gate `u.in < 0` reads a wired signal that varies
within a step, so [§10.4][s10-4]'s soundness argument, that gates stay fixed through
a localization, does not cover it. Across a bracket σ is `-1` on one side
and a small positive `-in` on the other, a jump rather than a crossing. The
bracketing root-finder reads only the sign, so it still converges on the
input's zero crossing; the reviewer measured the located instants within
4.6e-9 of the true zeros, under a bracket of 1e-8. The cost is speed: with
one end stuck at `-1`, the secant estimate ITP draws lands next to the other
end and its minmax projection falls back to bisection's count, 21 trials for
the default tolerance. On a `cos(t)` input into `[-0.5, 0.5]` over 20 s,
seven hits and six leaves cost 177 trial sweeps against 87 before the
gate, about 15 extra interior sweeps per leave.

**The `±1` gate, equivalent and not chosen.** Writing `one(u.in)` instead
of `-u.in` on the holding side defines the same predicate and converges at
the same bisection count, because both ends of the bracket are then fake
constants. It states more plainly that the gate alone decides the predicate.
It was not chosen because it teaches a pattern the design forbids: a `Bool`
predicate dressed as a sign form to force localization, which [D-179][d-179] says
cannot be written. The chosen form is [§10.4][s10-4]'s idiom with one more `Bool`
factor, and its continuous atom `-in` is still the quantity whose zero is
the event.

**A `floatmin` nudge, rejected.** Replacing an exact `-0.0` by
`-floatmin(u.in)` gives the same strict predicate, keeps the 87 trials and
the original leave instants, and every routed test stays green. It was
rejected because `floatmin` has no method for a `Dual`, so it works only
because events compile out at non-nominal activations, and because the
trick is cryptic.

**The computed clamp with a release event, rejected.** Give up the latch
and let the derivative decide saturation from the current state and input,
with events only to localize the kinks and clamp `q` exactly:

```julia
x_deriv(c, (; x, u)) = (q = (x.q >= c.upper && u.in > 0) || (x.q <= c.lower && u.in < 0) ?
                            zero(u.in) : u.in,)
hit_upper_guard(c, (; x)) = x.q - c.upper     # localizes the arrival, clamps exactly
release_guard(c, (; u))   = -u.in             # localizes the input's zero crossing
```

Every guard is continuous and the corner disappears, because nothing is
latched: at the rest point the clamp is off, and the next outward push turns
it on at once. But the release guard is ungated, so it localizes every
downward zero crossing of the input wherever the state is, and its mirror
every upward one. A departure costs about 7 trial sweeps against the strict
gate's 22, so this form wins only when departures outnumber all other zero
crossings of the input three to one. The input of a limited integrator is
typically a tracking error, which crosses zero at every overshoot and then
continuously under any dither, while the latched block sits idle. Each
spurious firing also ends the step at the crossing ([§10.4][s10-4]), fragmenting the
grid with boundaries every component pays for. The block would also stop
being the modes-and-events demonstrator, and a saturation flag would become
a `y_direct` output with feedthrough from `in`.

**The computed clamp without a release event.** Keep only the arrival event.
Departures then cost nothing, and the kink in `q̇` at a departure lands
inside a step. Section 5 shows that this kink is mild, so the error is a
one-time offset of order `a h²`. This is the cheapest form, but it declares
no departure, loses the mode, and is dominated by the next one.

**The boundary-detected departure, chosen as the second policy.** [D-179][d-179]
says a localized guard becomes boundary-detected by returning the predicate
instead of the sign value. Here that rewrite does two things at once:

```julia
leave_upper_guard(c::LimitedIntegrator{V, false}, (; m, u)) where {V} =
    m.saturation === :upper && u.in < 0
```

A `Bool` predicate is strict by construction, so the exact-zero corner is
handled without any gate trick. There is no root-finding, so a departure
costs one guard evaluation per step and no grid split. The mode is kept, so
the derivative, the hit events and `modes(sim, …)` are unchanged. The
departure then fires at the end of the step in which `in < 0` was first
observed, up to one step late, and section 5 bounds what that costs.

## 5. The two kinks

The arrival and the departure are different kinds of kink, and the
difference decides which event may be cheap.

**At an arrival** the derivative jumps from `in > 0` to `0`: a discontinuity
in `q̇` itself. Stepping over it costs an error of order `h` and leaves `q`
past the limit, so the arrival stays localized in every variant, and its
handler writes `q` to the limit exactly.

**At a departure** the input passes *through* zero, so `q̇` goes from `0` to
`0⁻` continuously and only `q̈` jumps. `q` stays once differentiable through
the departure, and a one-step method misses far less. A discontinuous input
would make the departure a first-order kink too, but in this framework such
an input carries its own event, `Step` localized or boundary-aligned, and a
`Relay` likewise, so the boundary is already there.

Take a step `[tₙ, tₙ + h]` with the block saturated at `upper` and the input
crossing zero at `tₙ + θh` with slope `-a`, so `in(t) = -a (t - t_c)`. The
exact state at the end of the step is

```
q(tₙ + h) = upper - a (1 - θ)² h² / 2
```

The boundary-detected policy holds the mode to the end of the step, keeps
`q̇ = 0` throughout and lands exactly on `upper`. Its error is
`a (1 - θ)² h² / 2`, at most `a h² / 2`. The computed clamp without a
release event switches the derivative inside the step, and RK4 sees the
negative input in some of its stages; for `θ < 1/2` its error works out to
`a h² θ (1 - 3θ) / 6`, the same order with a smaller constant. Both are
one-time errors paid once per departure, and two things matter about them.
They persist, since an integrator has no restoring dynamics, so the offset
stays in `q` until feedback elsewhere removes it. And they are small: with
an input slope of 1 per second, the bound is 5e-5 at `h = 0.01` and 5e-3 at
`h = 0.1`, where the localized policy lands within the root-finder's
tolerance, about 1e-8 in time.

| variant | cost per departure | error per departure | corner-safe | mode kept |
|---|---|---|---|---|
| localized, strict gate | about 22 trial sweeps and a grid split | root-finder tolerance | yes | yes |
| boundary-detected `Bool` guard | one `Bool` per step | at most `a h² / 2`, once | yes | yes |
| computed clamp, release localized | about 7 trial sweeps per zero crossing of the input, anywhere | root-finder tolerance | yes | no |
| computed clamp, no release event | nothing | about `a h² θ (1 - 3θ) / 6`, once | yes | no |

## 6. The decision

The block ships both detection policies for its departures, selected by a
type parameter in `Step`'s shape, `LimitedIntegrator{V, L}` with the
keyword `localized = true`. Arrivals are localized in both, since that kink
is first-order and the exact clamp depends on it. The localized departure
is the accurate form and the default; the boundary-detected departure is
the cheap form, exact at every zero input, and off by at most `a h² / 2`
per departure. The two forms differ in one method per leave guard, and the
policy must be a type parameter because the build reads it off the guard's
probed return type ([D-179][d-179]). The computed forms were not built: the first is
dominated on cost in every realistic use, and the second on everything but
a constant factor by the boundary-detected policy.

On 2026-10-07 the modes were recoded from `Symbol` labels to the signed `Int8`
codes `-1`, `0` and `+1`, so that the vector form could share them under
[D-231][d-231]'s rule, and the sketches and the prose above keep the
labels.

## 7. What the episode says about the framework

The convention that a predicate holds at `σ ≥ 0`, with edges detected
against a prior, is what makes boundary-detected and localized events share
one declaration ([§2.1][s2-1]), and it is what made the rest point a trap: at
`(upper, 0)` both "`q` has reached the limit" and "`in` has stopped pushing"
hold, and neither can produce an edge from there. Any block that latches a
mode on one continuous quantity reaching zero and releases it on another
reaching zero meets the same corner, and the strict gate on the releasing
quantity is the general remedy.

Whether the convention itself should move to `σ > 0` was weighed on
2026-10-07 and declined. A strict convention would dissolve both halves of
section 3: the hit guard would read `0` at the rest point and not hold, so
it would re-arm by itself, and `-in` at zero would not hold either. But it
would break the events the design is built around, the ones in which a
quantity reaches a level: the touchdown archetype and the stop requests of
[§13.5][s13-5], a `Step` at `t_step = t₀`, a relay fed exactly its threshold, and
every state initialized exactly on a level, which fires at boundary zero
today and never would. It would also make the sign form `q - upper` and the
`Bool` form `q >= upper` disagree at the limit, where [D-179][d-179]'s cast
`σ ≥ 0` is what makes them one predicate. Strictness is a property of the
predicate, not of the framework: a reach predicate holds at equality and a
release predicate does not, and one global convention cannot serve both.
`≥` serves the common kind, and the strict gate is the local statement for
the other, with the `Bool` form as its boundary-detected twin. [§10.4][s10-4] names
the idiom beside the gate form, and [D-290][d-290] carries the annotation.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-179]: ../decisions.md#d-179--derive-detection-policy-from-the-guards-return-type
[d-231]: ../decisions.md#d-231--require-isbits-store-values-checked-at-build
[d-290]: ../decisions.md#d-290--localizations-exact-detection-left-end-discriminator-endpoint-and-t-boundary
[d-313]: ../decisions.md#d-313--admit-a-library-block-by-judgement-against-three-guidelines
[s10-4]: ../spec.md#104-localization-mechanics
[s10-6]: ../spec.md#106-event-iteration-at-boundaries-to-quiescence-budgeted
[s13-5]: ../spec.md#135-termination-is-a-state-not-an-exception
[s13-7]: ../spec.md#137-tooling-consequences-face-routes-and-the-component-library
[s2-1]: ../spec.md#21-events-two-detection-policies
