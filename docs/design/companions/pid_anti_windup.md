# The PID block: anti-windup, the two axes and the variants weighed

*A companion record, not normative text. The ground truth is `spec.md`
[§13.7][s13-7] (the library), [§5.3][s5-3] and [§5.4][s5-4] (feedthrough and artificial loops), [§2.1][s2-1]
and [§10.4][s10-4] (events and localization) and [§7.3][s7-3] (modes), with decisions [D-179][d-179],
[D-231][d-231] and [D-313][d-313]. If this document and the spec ever disagree, the spec
wins. It was written on 2026-10-07, when the PID was promoted from an
example-first row of the inventory to a block of the library, to keep the
reasoning that chose its anti-windup design and to record the variants it
does not carry.*

The inventory listed a PID with anti-windup as *example first*, because the
design space, the controller's form, the anti-windup scheme and the
derivative filter, is wide, and a block fixes a form. Working the example
narrowed the space to two independent choices and one law, and the result
satisfies the three admission guidelines of `library_inventory.md`,
section 2, better than the didactic composition did: it is domain-agnostic
and generally useful, its implementation has corners that are easy to get
wrong, and building it met two framework mechanisms, stage-2 conservatism
and the declared boundary, in forms worth recording. Sections 1 and 2 state
the problem and the textbook schemes, section 3 what the framework adds to
them, section 4 the two axes and the law, section 5 a scenario per variant,
section 6 the variants not carried, section 7 the decision with the measured
numbers, and section 8 what the episode says about the framework. Section
9, added the same day, carries the law to the discrete tier as
`DiscretePID`. Section 10, added on 2026-10-08, widens both blocks over
static vectors, makes any parameter a port and adds the setpoint weights.

## 1. Windup

A PID's integral term accumulates the error. When the path downstream
saturates, the plant stops responding to further effort, the error
persists, and the integrator grows past anything the path can deliver.
When the error finally reverses, the integrator must unwind through that
excess before the output leaves the limit, so the loop overshoots and
recovers slowly. Every anti-windup scheme answers one question: what stops
the integrator while the path cannot act?

## 2. The textbook schemes

**Integrator limiting.** Bound the integral state itself. It is the
`LimitedIntegrator` holding the integral, with no knowledge of the path. The
bound is a tuning constant unrelated to the real saturation, so it bounds
the damage rather than preventing it, and too tight it leaves a steady-state
error. Its proper role is not anti-windup but an authority limit (section
6).

**Conditional integration, called clamping in Simulink.** Integrate only
while the output is unsaturated, or while the error would drive it back into
range. Intuitive and free of parameters, but the integrator's input switches
discontinuously when the output crosses a limit, which is a jump in `q̇` on
a continuous quantity reaching a level. Simulink handles it because its
Saturation block carries zero-crossing detection.

**Back-calculation, the tracking form.** Compute the unsaturated output,
saturate it, and feed the difference back into the integrator with a gain
`1/Tt`:

```
u_raw = Kp e + q + Kd d
u     = clamp(u_raw, u_min, u_max)
q̇     = Ki e + (u - u_raw) / Tt
```

Unsaturated, the correction is zero. Saturated, it drives `q` so that
`u_raw` settles at `u + Tt·e`, just past the limit, and the output comes off
the limit the moment the error reverses. Smooth everywhere, since `clamp`
is continuous and its kinks are second-order downstream, and one parameter
with a rule, `Tt = √(Ti Td)` or `Tt = Ti`. Simulink writes the gain as `Kb`.

**Tracking mode.** The same correction with an external value in place of
the block's own clamp, `q̇ = Ki e + (v - u_raw) / Tt`, where `v` is what the
path actually delivered. Simulink's `TR` port with gain `Kt`. It is how a
controller that is not in command, in manual mode or deselected in an
override scheme, follows the actuator so that the hand-back is bumpless.

**The velocity form.** Integrate `u̇ = Kp ė + Ki e` and make the output
itself a `LimitedIntegrator` at the actuator's limits. Windup disappears
structurally and gain changes are bumpless, at the price of needing `ë` for
a D term. It is the common industrial discrete form, and [§13.7][s13-7] names
`UnitDelay` as the shape of its previous-saturation port, so it belongs to
the discrete tier.

## 3. What the framework adds

Three things the textbook does not say decided the design.

**A tracking input can close an artificial loop.** Written as one leaf with
inputs `r`, `y`, `v` and the output `u` from `y_direct`, the controller has
a stage-2 output, so every input is a feedthrough edge whether `y_direct`
reads it or not. [§5.4][s5-4]'s last paragraph records this stage-2 conservatism: an
input consumed only by `x_deriv` still creates the edge. Wire `v` from a
memoryless clamp of the leaf's own `u` and the build refuses an
`AlgebraicCycle` classified artificial, with the dead hop naming `v` as the
face `u` does not route. The remedy is [§5.4][s5-4]'s first rung, taken: the clamp of
a controller's own output is the controller's business, so the limits live
inside the block and the correction reads the block's own fresh `u`, which a
derivative stage may do. The tracking input then serves what it is for: a
value produced elsewhere, by a stateful actuator or an inner loop, whose
publication from state breaks the cycle. An assembly of library blocks never
meets the refusal, because its integrator splits the stages by
construction, which is [§5.4][s5-4]'s second remedy for free.

**A saturation code flips on a declared boundary.** Conditional integration
is a mode made silently when its switch reads a continuous quantity. But
when the saturating element is a moded block, its mode changes only when
its events fire, localized or at a step boundary. The code `LimitedIntegrator`
publishes, `-1`, `0` or `+1` for the limit in force, is such a signal: a
gate `saturation == sign(e) ? 0 : e` in front of the integrator switches on a
boundary and needs no events of its own. The signed code also carries which
limit, which the gate needs, and several codes consolidate through a small
fold or, reduced to `Bool`s, through the `Or` and `And` gates. Simulink has
no equivalent, since its clamping knows only the block's own limits.

**Tracking couples the loops, and `Tt` is squeezed from both sides.** With
`v` the inner measurement, the correction is nonzero during every inner
transient, saturated or not, and turns the outer integrator into a leaky
one partly slaved to the inner loop. Raising `Tt` weakens the coupling, but
during a saturation episode the excess the integrator accumulates is
`Tt·e`, and an episode shorter than `Tt` winds up almost freely. So `Tt`
must sit above the inner loop's time constant and below the typical episode,
a window that a cascade without a large timescale ratio does not have.
Gating the tracking term with the code removes the coupling and frees `Tt`
to be short.

## 4. The two axes and the law

Two independent choices remain, each adding one input port when taken.

- **An external saturation input**, the port `saturation::Int8`, the hold,
  which gates the error: `gate(e) = saturation == sign(e) ? 0 : e`. Absent,
  `gate(e) = e`.
- **The correction's reference**, the block's own clamped output `u` or
  the tracking port `v::Float64`.

The derivative is one line, `q̇ = Ki · gate(e) + (ref - u_raw) / Tt`, and
the four variants are its table:

| | reference: own `u` | reference: tracking `v` |
|---|---|---|
| no hold | `Ki e + (u - u_raw) / Tt` | `Ki e + (v - u_raw) / Tt` |
| hold | `Ki gate(e) + (u - u_raw) / Tt` | `Ki gate(e) + ((saturation == 0 ? u : v) - u_raw) / Tt` |

One rule joins the axes. When both ports exist, `v` is the reference only
while the code is nonzero, and the reference falls back to `u` while the
path is free. This is not a special case but what a tracking reference
means: a value to converge to while the path cannot follow, meaningless
while it can. Without the hold there is no way to know, so that variant
tracks always and carries section 3's coupling; with one, the coupling goes.
The naive composition, the gate on `e` plus ungated tracking, would keep
the coupling the hold was meant to remove, and an earlier form that stopped
integrating whenever the code was nonzero failed to resume when the error
reversed while the path still reported saturation, which the gate's sign
test handles.

**Why the hold does not win over everything.** It is tempting to conclude
that with the saturation input in hand no correction is needed at all. That holds for a
controller without own limits, where the correction is identically zero,
and fails at two edges. The code reports the path downstream of `u`, so it
cannot see the controller's own clamp: with limits tighter than the path's,
`u_raw` runs past them while the code stays at zero, and only the internal
term catches it. And a hold can stop the integrator but cannot move it,
which is the same thing only when the integrator held the right value when
the hold began. A controller not in command, a limit that moves while the
hold is on, or a saturation input that rises late through actuator dynamics all leave an
excess that history set and the gate cannot undo; a tracking term undoes
it at rate `1/Tt`.

**The grouping.** The integrator holds the integral term in output units,
`q̇ = Ki e + …` with `u_raw = Kp (b r - y) + q + …`, rather than the error
integral with `Ki` outside. A change in `Ki` then alters only future
accumulation, which is what a gain-scheduled controller needs, and `1/Tt`
has the units of Simulink's `Kb`. The derivative acts on a weighted
measurement through a lag, `d = (w - yf) / τd` with `w = y - c r` and
`ẏf = (w - yf) / τd`. The setpoint weights `b` and `c`, Åström's
two-degree-of-freedom form, multiply `r` alone, with defaults `b = 1` and
`c = 0`, and the integral's error stays the unweighted `e = r - y`. The
default puts the derivative on the measurement because a setpoint step
through `Kd de/dt` is a spike of height `Kd Δr / τd`, an impulse at `τd = 0`
on the discrete tier, which drives `u` into saturation where the anti-windup
takes over. The gains set disturbance rejection and robustness, and `b` and
`c` shape the setpoint response apart from them; `c = 1` restores the
derivative on the error for a model that wants it, say with a smooth
generated reference.

## 5. A scenario per variant

- **Own limits, no hold.** A single loop commanding a black box: a PI on a
  valve, a throttle into an engine model that reports nothing back. The
  controller's limits are the actuator's travel and nothing downstream
  reports or has dynamics worth modelling.
- **Own limits with a hold.** A limit the path cannot see beside one it
  reports. An altitude hold commands vertical speed with a comfort limit
  while the pitch and elevator loops below report whether the servo is on
  its stops. The path follows the limited command without saturating, so
  only the internal term catches the comfort limit; only the hold catches
  the servo's.
- **Tracking, no hold.** A controller not in command. An engine control's
  speed loop and its temperature and pressure limiters each compute a fuel
  flow and a minimum selector picks one; the deselected integrators must
  follow the selected command so the switchover is bumpless. An autopilot
  in standby tracking the pilot's command is the same shape.
- **Tracking with a hold.** A cascade whose achievable value moves while
  the hold is on. The outer flight-path loop commands normal acceleration
  and the inner loop's limit varies with airspeed; holding freezes the
  outer integrator at the value it had when the hold began, while tracking
  the achieved acceleration keeps it on the moving limit, and the gate
  keeps that tracking from coupling to the inner loop's ordinary
  transients.

In one sentence: own limits are for the limit the path cannot see,
the hold for the limit the path reports, tracking for a value the integrator
must follow rather than a limit it must respect, and the gate is what lets
a tracking value be used without paying for it during free transients.

## 6. The variants not carried

- **Integrator authority limits**, the integral term bounded to a fraction
  of the command range so a failed sensor cannot drive it to full
  authority. The limiting scheme of section 2 in its proper role. It is
  the `LimitedIntegrator`'s four events applied to `q`, the one addition
  that would give the block a mode.
- **Feedforward accounted in the saturation.** A feedforward command added
  after the block is invisible to the own clamp; the hold variants see it
  through the path. A `uff` input inside the block, so the clamp sees the
  total, is the alternative wiring.
- **A general hold rule.** The `saturation` port is one hold rule with the sign
  built in. A `hold::Bool` port with the rule computed outside covers
  integral separation and mode logic.
- **The velocity form**, section 2. The positional law itself carries to
  the discrete tier as `DiscretePID` (section 9); the velocity form would
  be a different controller there, with the output a limited integrator,
  a D term on the second difference and new meanings for both axes.
- **Internal clamping**, Simulink's conditional integration against the
  block's own limits. A third moded block with the limited integrator's
  events applied to `u_raw`, including the strict gate against the
  exact-zero corner `limited_integrator_variants.md` records. The `saturation` port
  gives the external form of the same thing on a declared boundary.

## 7. The decision, and the numbers

The block is `PID{Hold, Track}` in `Redstone.Blocks`: two `Bool` type
parameters, one per axis, since whether a port exists is a declaration;
instance data `Kp`, `Ki`, `Kd`, `τd`, `Tt`, `u_min`, `u_max`, with `Ki = Kd
= 0`, `τd = 0.1`, `Tt = Inf` and infinite limits as defaults, so the plain
spelling is a P controller and every mechanism is opted into; inputs `r` and
`y`, plus `saturation` and `v` as the parameters add them; outputs `u`, clamped,
and `u_raw`; states `q` and `yf`; one `x_deriv` with two one-line helpers
for the gate and the reference. A simplified assembly of library blocks,
the first cell as a `Group`, stays in the tests as the inspector's example
beside the block; it is not a library row.

The shape was probed at commit 99438ec, at `h = 1//100`, on a reference
step to `5` at `t = 0.5`, with `Kp = 1, Ki = 0.5, Kd = 0.2, τd = 0.1` in
the single loops and `Kp = 0.5, Ki = 0.1` in the cascades. The single loop
is an integrator plant; the servo loop puts a first-order position servo
limited at `±1` between controller and plant and tracks its position; the
cascade sets the reference of a velocity servo whose controller is a
`LimitedIntegrator` at `±1.2` and integrates the velocity into the position
the controller reads. The peak is of the loop's output, the settling time is
the first instant after which the output stays within `0.05` of `5`.

| variant | loop | `Tt` | peak | settled |
|---|---|---|---|---|
| own limits `±1` | single | `Inf` | 8.18 | 18.7 s |
| own limits `±1` | single | 1 | 5.33 | 11.3 s |
| tracking the servo | servo | `Inf` | 8.71 | 29.4 s |
| tracking the servo | servo | 1 | 5.96 | 22.7 s |
| none | cascade | | 8.33 | 38.5 s |
| hold | cascade | | 6.10 | 32.5 s |
| tracking the velocity | cascade | 2 | 6.14 | 25.8 s |
| tracking the velocity | cascade | 0.5 | 7.27 | 55.2 s |
| hold and tracking | cascade | 2 | 5.20 | 26.9 s |
| hold and tracking | cascade | 0.5 | 5.09 | 22.0 s |

The last four rows are section 3's coupling argument measured. Shortening
`Tt` degrades ungated tracking, whose correction then slaves the outer
integrator to every inner transient, and improves gated tracking, which
pays nothing while the path is free. The hold alone beats ungated tracking
at its better `Tt`, and the two together beat both.

The tracking variant wired from a memoryless clamp of its own output is
refused at build, `AlgebraicCycle` with `classification === :artificial`
and the dead hop `("controller", :v, :u)`. All four variants build under
`(Float64, LinearizeDual)`. At a free operating point the two hold variants
linearize as the plain PID, `A = [0 0; 0 -1/τd]`, `B = [Ki -Ki; 0 1/τd]`,
`C = [1 Kd/τd]`, `D = [Kp (-Kp - Kd/τd)]`, since the correction is
identically zero inside the limits and the gate passes the error; the
ungated tracking variant adds the tracking pole, `A₁₁ = -1/Tt`, with
`∂q̇/∂v = 1/Tt`.

## 8. What the episode says about the framework

Stage-2 conservatism ([§5.4][s5-4]) is a constraint on how a leaf is designed, not
only a diagnostic: a leaf with a stage-2 output cannot take as an input a
memoryless function of that output, however its derivative uses it, and the
design answer is to own the function. Where the function is the clamp of
the leaf's own output, owning it is also the better controller. Its mirror is
that an assembly of stateless folds and one integrator never meets the
constraint, and that the integrator in it is precisely the split [§5.4][s5-4]
describes.

The declared boundary is what makes an external saturation signal usable.
A gate on a continuous quantity is the silent mode the junction's docstring
warns against; a gate on a moded block's code switches where the framework
already stopped. The signed `Int8` code was chosen for the mode store's
isbits rule ([D-231][d-231]) so that a static vector of modes could exist; that it
reads as arithmetic in a consumer, `saturation == sign(e)`, is what made the
hold variant a one-liner.

## 9. The discrete tier

`DiscretePID{Hold, Track}` is the block of section 7 with `s = (q, yf)` in
place of `x`. Same seven fields, same ports, same two axes, same law. A
user moves a controller onto the discrete tier by changing a name, and the
anti-windup reasoning of sections 3 and 4 carries over unchanged. The
velocity form stays uncarried (section 6).

**The stage split is the textbook's.** The discrete PID of the control
texts computes the output from the integral term as it stands, then updates
the integral with the current error and the back-calculation term. That is
`y_direct` over `s` and `s_update` reading `y`, the block's own fresh `u`
and `u_raw` the update may read. Both outputs come from stage 2, so the
block is feedthrough as the continuous one is, and [§5.4][s5-4]'s refusal of a
tracking input wired from a memoryless clamp of the own `u` holds for the
same reason. The limits stay inside. One difference in the diagnostic: a
discrete member traces structurally ([§5.6][s5-6]), its pinned declarations
admitting no tracer scalar, so the cycle is classified `:real` with no dead
hop, where the continuous block's is `:artificial` with the hop named. The
probe confirmed both.

```julia
function y_direct(c::DiscretePID, (; s, u, Δt))
    d = (u.y - s.yf) / (c.τd + Δt)                          # backward Euler on the filter
    u_raw = c.Kp * (u.r - u.y) + s.q - c.Kd * d
    (u = clamp(u_raw, c.u_min, c.u_max), u_raw = u_raw)
end
function s_update(c::DiscretePID, (; s, u, y, Δt))
    β = -expm1(-Δt / c.Tt)                                  # 0 at Tt = Inf, 1 at Tt = 0
    (q  = s.q + Δt * c.Ki * gated_error(c, u.r - u.y, u) + β * (correction_reference(c, u, y) - y.u_raw),
     yf = s.yf + Δt * (u.y - s.yf) / (c.τd + Δt))
end
```

**The derivative filter is the trap.** Forward Euler on the continuous
filter, `yf⁺ = yf + Δt (y - yf)/τd`, is unstable for `Δt > 2τd`. With the
default `τd = 0.1` a 5 Hz tick sits on the margin, and nothing complains,
since the period is unknown at construction. Backward Euler on the filter
alone is stable for every period and every `τd ≥ 0`, and admits `τd = 0`,
where the D term is the plain backward difference `(y_k - y_{k-1})/Δt`,
the discrete tier's native derivative, which the continuous block cannot
express. The integral keeps forward Euler, since a pure accumulator has no
stability question, and the default `τd` stays at `0.1` so the two blocks
read alike.

**The correction's step is exact.** The back-calculation term relaxes `q`
at rate `1/Tt`, and its Euler step `Δt/Tt` is stable only for `Tt > Δt/2`
and free of ringing only for `Tt ≥ Δt`, a constraint on a tuning constant
against a period the block cannot see. The exact step of that relaxation
over one period with the inputs held is `β = 1 - e^{-Δt/Tt}`, spelled
`-expm1(-Δt/Tt)` so that `Tt = Inf` gives exactly zero and small `Δt/Tt`
reduces to the Euler step to rounding. Every `Tt` is then stable, and
`Tt = 0` is legal and means instant back-calculation, `u_raw` brought to
the reference by the next tick, which is Simulink's clamping scheme as a
limit of the tracking one. The factor applies to the correction alone. The
fully exact step would also scale the integral's drive by `Tt β`, which is
`Inf · 0` at the default and needs a branch for nothing the plain `Δt`
does not already give.

**The law is shared, not the type.** The port sets, the gate and the
reference rule are identical in both blocks, eleven methods: the four
`signal_ports` arms, `u_types`, `y_types`, the two `gated_error` arms and
the three `correction_reference` arms. With `parameters`, which fetches the
nine parameters, they earn a supertype in the `LinearBlock` style,
`PIDBlock{V, Hold, Track, Fixed}`, which carries them (section 10). The
stores and the stages sit on each concrete type, and the field `fixed`
repeats in the discrete struct, since an abstract type carries none. The
continuous `PID` reparents in one line.

**Two smaller points.** The hold wires from either tier, a continuous
`LimitedIntegrator`'s code read at the tick or a `DiscreteLimitedIntegrator`
on the same tier, whose stage-1 `saturation` breaks the loop back into the
PID's stage-2 `u`. And `s_init` is `(q = zero(V), yf = zero(V))` with no
keywords, as the continuous block's `x_init` is; both share the start-up
kick from `yf` starting at zero rather than at the first measurement, a
not-carried item common to the pair.

## 10. Vectors, scheduled parameters and the weights

Added on 2026-10-08, superseding the type parameters, the fields and the
scalar sketch of sections 7 and 9. The spec names neither the PID's shape
nor its parameters, so the design lives here and in the inventory
([§13.7][s13-7], [D-313][d-313]).

**Widening, not forking.** The library's vector blocks are one struct each
over `V <: Union{Real, StaticArray{<:Tuple, <:Real}}`, with the law in
broadcast form: `Integrator`, `FirstOrderLag`, `LimitedIntegrator`, `Relay`,
`DiscreteLimitedIntegrator` and `RateLimiter`. Only two things fork on
scalar against vector, `state_events` and the saturation code's port type.
The PID has no events, and the port type becomes one helper shared with the
two limited integrators, `saturation_type(V)`, `Int8` over a `Real` and
`similar_type(V, Int8)` over a static array. Over a vector every law is
componentwise. The gate and the reference rule become broadcast `ifelse`s,
which select without short-circuiting, so the gate's `.!= 0` still works
per channel: a free channel at zero error never consults `sign` of a
zero-valued `Dual`. Every product with a parameter and every division by one
is dotted, since `SVector * SVector` is a shape error.

**Every parameter a `V`.** The blocks are `PID{V, Hold, Track, Fixed}` and
`DiscretePID{V, Hold, Track, Fixed}` over `PIDBlock{V, Hold, Track, Fixed}`,
`V` first as in `LimitedIntegrator{V, L}`. Each parameter of the roster
`PID_PARAMETERS = (:Kp, :Ki, :Kd, :τd, :Tt, :u_min, :u_max, :b, :c)` is a
`V`, and the stores start at `zero(V)`. The keywords given as values
broadcast to one shape by `GaussianWhiteNoise`'s idiom. The shape is the sum
of their `zero`s, each value is `Float64.(value .+ shape)`, and `V` is the
shape's type. `promote` cannot serve, since `promote(1.0, SVector(1.0,
2.0))` throws. A scalar pairs with a vector and integer keywords qualify, so
a vector PID with uniform gains spells at least one keyword as a vector,
`Kp = @SVector fill(2.0, 3)`, as the integrators take their shape from `s0`.

**A parameter becomes a port by `AsPort()`.** Any of the nine may be an
input port instead of a field, spelled `Kp = AsPort()` with the marker type
`AsPort`. It takes no part in the shape, and when every value-carrying
keyword is scheduled `V` is `Float64`. The struct stores the fixed
parameters alone, and one function fetches all nine:

```julia
struct PID{V, Hold, Track, Fixed} <: PIDBlock{V, Hold, Track, Fixed}
    fixed::Fixed      # the parameters that are not ports, each a `V`, in roster order
end
parameters(c::PIDBlock, u) = NamedTuple{PID_PARAMETERS}(merge(c.fixed, u))
```

`merge` resolves at compile time, and the selection lays the nine out in
roster order however the merged keys are staggered. With `Ki` and `u_min`
scheduled the merge reads `(:Kp, :Kd, :τd, :Tt, :u_max, :b, :c, :r, :y,
:Ki, :u_min)`, the bundle's order last; the selection reads the same nine
whichever way the bundle lists them. Port and parameter names never
collide, so merging the whole input bundle is safe. The ports are section
4's four arms, now `signal_ports`, merged by `u_types` with one `V` port
per scheduled name.

**Nothing dispatches on the scheduled set.** Each set is one `Fixed` type,
and a scheduled gain and a fixed gain enter the same expression, so the 512
sets share every method. `Hold` and `Track` keep type parameters of their
own because they change the law. They pick the gate and the reference, and
their four arms read as section 4's table.

**A scheduled port is an ordinary input.** `u` is a stage-2 output, so every
input is a feedthrough edge (section 3, [§5.4][s5-4]). A schedule computed
memorylessly from the block's own output closes an `AlgebraicCycle` as a
clamped `v` does. It is classified real when the parameter enters the
direct law, as every one but `Ki` and `Tt` does; a scheduled `Ki` or `Tt`
closes an artificial cycle on the continuous tier, as `v` does, and a real
one on the discrete tier, where a member traces structurally (section 9,
[§5.6][s5-6]). One read from a state is fine. Under a `Dual` activation a
scheduled gain carries partials, so a linearization sees the coupling
through the schedule. A model that wants the gain frozen at its
nominal value routes the port through `Freeze` ([§14.10][s14-10]).

**The setpoint weights.** `b` weights the reference in the proportional term
and `c` in the derivative term, with defaults `1` and `0`, which leave the
law of sections 7 and 9 unchanged; section 4 gives the reason. `yf` keeps its name and sign
and filters the weighted measurement `w = y - c r`, so at `c = 0` every
number of section 7 holds. The integral's error stays `e = r - y`. Over a
vector each channel weights its own reference. Continuous:

```
w     = y - c r
u_raw = Kp (b r - y) + q - Kd (w - yf) / τd
q̇     = Ki · gate(e) + (ref - u_raw) / Tt
ẏf    = (w - yf) / τd
```

Discrete, with `Δt` the component's own period ([§10.5][s10-5]):

```
deriv = (w - yf) / (τd + Δt)
u_raw = Kp (b r - y) + q - Kd deriv
q⁺    = q + Δt Ki · gate(e) + β (ref - u_raw),    β = 1 - exp(-Δt / Tt)
yf⁺   = yf + Δt deriv
```

On both tiers `u = clamp(u_raw, u_min, u_max)`.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-179]: ../decisions.md#d-179--derive-detection-policy-from-the-guards-return-type
[d-231]: ../decisions.md#d-231--require-isbits-store-values-checked-at-build
[d-313]: ../decisions.md#d-313--admit-a-library-block-by-judgement-against-three-guidelines
[s10-4]: ../spec.md#104-localization-mechanics
[s10-5]: ../spec.md#105-multi-rate-tick-scheduling
[s13-7]: ../spec.md#137-tooling-consequences-face-routes-and-the-component-library
[s14-10]: ../spec.md#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s2-1]: ../spec.md#21-events-two-detection-policies
[s5-3]: ../spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
[s5-4]: ../spec.md#54-artificial-loops-and-the-escape-hatch
[s5-6]: ../spec.md#56-diagnostics-feedthrough-tracing
[s7-3]: ../spec.md#73-discrete-state-modes-and-workspace
