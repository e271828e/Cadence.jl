module Blocks

import ..Redstone: AbstractComponent, Pinned, StateEvent,
    x_init, s_init, m_init, u_types, y_types, y_direct, y_state, x_deriv, s_update,
    state_events, local_wires, input_wires, output_wires, sample_times, transparent_container
using StaticArrays: StaticArray, similar_type
import ForwardDiff

# The standard component library (§13.7, D-313). Written as a user's component
# file is: the import list above is its whole reach into the parent, so every
# block here is an ordinary component the framework knows nothing of.

# --- the junction (§6.2, D-311) -------------------------------------------------

"""
    Junction{In, Out, N}(f)

The N-to-1 block (§6.2): inputs `in1` to `inN` at `In`, one output `out` at
`Out`, and `out = f(in1, …, inN)`, the fold applied in positional order. A
stateless continuous leaf. The fold is instance data and `F` is inferred from
it. A custom fold, a weighted blend or a mass-properties composition, is written
at the site.

The fold is stateless and declares no events, so a discontinuity written into
it lands wherever it lands inside a step (§2.1). A clamp is fine, since its
kink is second-order downstream, and so is a branch on a `Bool` that flips at a
boundary, as a saturation code does. A branch on a continuous quantity is a
mode made silently, which the moded blocks exist to declare.
"""
struct Junction{In, Out, N, F} <: AbstractComponent
    f::F
end
(::Type{Junction{In, Out, N}})(f) where {In, Out, N} = Junction{In, Out, N, typeof(f)}(f)

"""
    SumJunction{V, N}()

The summing junction: the `Junction` at `+`, `N` inputs and the output at
`V` (§6.2).
"""
const SumJunction{V, N} = Junction{V, V, N, typeof(+)}

"""
    Or{N}()

The `Bool` gate at `|` over `N` inputs (§13.7): one consolidated `Bool` for a
consumer that wants one.
"""
const Or{N}  = Junction{Bool, Bool, N, typeof(|)}

"""
    And{N}()

The `Bool` gate at `&` over `N` inputs (§13.7).
"""
const And{N} = Junction{Bool, Bool, N, typeof(&)}

(::Type{SumJunction{V, N}})() where {V, N} = SumJunction{V, N}(+)
(::Type{Or{N}})() where {N} = Or{N}(|)
(::Type{And{N}})() where {N} = And{N}(&)

x_init(::Junction) = (;)
u_types(::Junction{In, Out, N}) where {In, Out, N} =
    NamedTuple{ntuple(i -> Symbol(:in, i), N)}(ntuple(_ -> In, N))
y_types(::Junction{In, Out}) where {In, Out} = (out = Out,)
y_direct(j::Junction, (; u)) = (out = j.f(u...),)

# --- the leaf blocks (§13.7, D-312) ---------------------------------------------

"""
    Constant(value)

The source block: no inputs, no state, and `out` publishes `value` from stage 1.
A stateless continuous leaf, so discrete consumers read it as well (§13.7).

`out` is pinned at `V`: a constant is never seeded, so it carries zero partials
under every `Dual` activation, and a tolerant consumer accepts it as a frozen
arrival. The value is instance data, not an overridable default; a source set
from outside is a root input (§11.3).
"""
struct Constant{V} <: AbstractComponent
    value::V
end
x_init(::Constant) = (;)
y_types(::Constant{V}) where {V} = (out = Pinned{V},)
y_state(c::Constant, _) = (out = c.value,)

"""
    UnitDelay(v0)

A discrete leaf, the tier's native `z⁻¹` (§10.6). `out` publishes the stored
value from stage 1, `v0` at the first publication, and each tick stores `in` for
the next one. Its store is isbits (D-231), which bounds `V`.

It breaks an algebraic loop (§5.5), and that is a modelling decision: placed
in a continuous loop it moves the signal onto the discrete tier and inserts a
`Δt_base`-scale zero-order hold.
"""
struct UnitDelay{V} <: AbstractComponent
    v0::V
end
s_init(delay::UnitDelay) = (v = delay.v0,)
u_types(::UnitDelay{V}) where {V} = (in = V,)
y_types(::UnitDelay{V}) where {V} = (out = V,)
y_state(::UnitDelay, (; s)) = (out = s.v,)
s_update(::UnitDelay, (; u)) = (v = u.in,)

"""
    Freeze{V}()

The declared stop-gradient (§13.7): `out` is `in` with its partials dropped,
pinned at `V`, so a walking producer may feed a pinned entry through it. At
nominal it is the identity. Every Jacobian along the path then reads a zero
coupling, which is the modelling decision it states. `V` is a `Real` or a
`StaticArray` of them; any other `V` is refused at the spelling.
"""
struct Freeze{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent end
x_init(::Freeze) = (;)
u_types(::Freeze{V}) where {V} = (in = V,)
y_types(::Freeze{V}) where {V} = (out = Pinned{V},)
y_direct(::Freeze, (; u)) = (out = ForwardDiff.value.(u.in),)

# --- the continuous dynamics (§13.7, D-313) -------------------------------------

"""
    Integrator(; x0 = 0.0)

The integrator: one continuous state `q`, starting at `x0`, with `q̇ = in`, and
`out` publishing `q` from stage 1, so the block has no feedthrough (§5.3). `V`
is `Float64` or a static array of `Float64`, taken from `float(x0)`, so an
integer `x0` qualifies. A `Float64` state walks under a `Dual` activation
(§7.2), so the block linearizes as it integrates.
"""
struct Integrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    x0::V
end
Integrator(; x0 = 0.0) = Integrator(float(x0))
x_init(c::Integrator) = (q = c.x0,)
u_types(::Integrator{V}) where {V} = (in = V,)
y_types(::Integrator{V}) where {V} = (out = V,)
y_state(::Integrator, (; x)) = (out = x.q,)
x_deriv(::Integrator, (; u)) = (q = u.in,)

"""
    FirstOrderLag(; τ, x0 = 0.0)

The first-order lag: `q̇ = (in - q) / τ` from `q = x0`, and `out` publishing `q`
from stage 1. The time constant `τ` is positive, and it is instance data pinned
at `Float64`. The state walks under a `Dual` activation (§7.2), so the lag
linearizes to `A = -1/τ` and `B = 1/τ`; a hand-written lag whose scratch is
pinned at `Float64` fails there instead (D-313). `V` is `Float64` or a static
array of `Float64`, taken from `float(x0)`, so an integer `x0` qualifies.
"""
struct FirstOrderLag{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    x0::V
    τ::Float64
end
function FirstOrderLag(; τ, x0 = 0.0)
    x0 = float(x0)
    FirstOrderLag{typeof(x0)}(x0, τ)
end
x_init(c::FirstOrderLag) = (q = c.x0,)
u_types(::FirstOrderLag{V}) where {V} = (in = V,)
y_types(::FirstOrderLag{V}) where {V} = (out = V,)
y_state(::FirstOrderLag, (; x)) = (out = x.q,)
x_deriv(c::FirstOrderLag, (; x, u)) = (q = (u.in - x.q) / c.τ,)

# --- the step (§2.1, §10.4, D-313) ----------------------------------------------

"""
    Step(; t_step, before = 0.0, after = 1.0, localized = true)

The step source: `out` publishes `before` until `t_step` and `after` from then
on. A mode-only leaf with no inputs: the mode `fired` picks the value, and one
state event, `fire`, sets it once `t` reaches `t_step`. `before` and `after`
are promoted to one `V`, `Float64` or a static array of `Float64`, and taken by
`float`, so integer values qualify; `t_step` is any time. `out` is pinned at
`V` (D-312): the value depends on neither state nor a walking input, so it
carries zero partials under every activation, as a `Constant`'s does.

`localized` picks the detection policy (§2.1). Localized, the guard is the sign
form `t - t_step`: the step ends at the crossing and the jump lands there.
Boundary-detected, the guard is the `Bool` `t ≥ t_step`: the event fires at the
end of the step in which it was first observed, so the jump lands on the first
boundary at or after `t_step`, never inside a step. The policy is the type
parameter `L` rather than a field because the build reads it off the guard's
return type (D-179).

Boundary zero sets every prior to not-holding (§10.6), so a `t_step` at or
before `t₀` fires there and `out` publishes `after` from the start.
"""
struct Step{V <: Union{Real, StaticArray{<:Tuple, <:Real}}, L} <: AbstractComponent
    before::V
    after::V
    t_step::Float64
end
function Step(; t_step, before = 0.0, after = 1.0, localized = true)
    before, after = float.(promote(before, after))
    Step{typeof(before), localized}(before, after, t_step)
end
x_init(::Step) = (;)
m_init(::Step) = (fired = false,)
y_types(::Step{V}) where {V} = (out = Pinned{V},)
y_state(c::Step, (; m)) = (out = m.fired ? c.after : c.before,)
step_guard(c::Step{V, true}, (; t)) where {V} = t - c.t_step     # sign form: localized
step_guard(c::Step{V, false}, (; t)) where {V} = t >= c.t_step   # Bool form: boundary-detected
step_handler(::Step, _) = (m = (fired = true,),)
state_events(::Step) = (fire = StateEvent(step_guard, step_handler),)

# --- the moded blocks (§10.4, §10.6, D-313) -------------------------------------

"""
    LimitedIntegrator(; lower, upper, x0 = zero(lower), localized = true)

The integrator held between `lower` and `upper`: one continuous state `q`, with
`q̇ = in` while free and `q̇ = 0` while saturated, and `out` publishing `q` from
stage 1. It is not a clamp. The mode `saturation` is read by the derivative,
and four state events move it. It is a signed `Int8` code, the sign of the
limit in force: `-1` at `lower`, `0` free and `+1` at `upper`.
`hit_upper` and `hit_lower` fire when `q` reaches a limit; their handlers write
`q` to the limit exactly and saturate. `leave_upper` and `leave_lower` fire
when `in` turns strictly back into the range, and free it; an input of exactly
zero at a limit keeps the mode saturated. The hit events are localized.

A second output, also `saturation`, publishes the code from stage 1, so it has
no feedthrough. It serves an anti-windup consumer, such as a controller that
gates its integrator on the code, which flips only when an event fires and so
only on a declared boundary.

`localized` picks the detection policy of the leave events (§2.1). Localized,
the guards are gated in §10.4's sign form, and the departure ends the step at
the input's zero crossing. Boundary-detected, the guards are the `Bool`
predicates, and the departure fires at the end of the step in which `in` first
pointed back into the range, so `q` is held on the limit for the rest of that
step and carries an offset of at most `a h² / 2` from then on, `a` the input's
slope at its zero crossing. What the cheap form buys is that a departure costs
no root-finding and splits no step, where a localized one pays about 22 trial
sweeps and a boundary. The policy is the type parameter `L` rather than a
field because the build reads it off the guard's return type (D-179).
`limited_integrator_variants.md` gives the reasoning.

Over a static vector, the limits and the codes are componentwise, and
`saturation` publishes a static vector of `Int8`. The block declares `N` copies
of the scalar events, one per component, named `hit_upper_1` to `hit_upper_N`,
then `hit_lower_i`, `leave_upper_i` and `leave_lower_i`: each guard reads its
one component and each handler writes it.

`lower < upper`, componentwise over a vector. `x0`, `lower` and `upper` are
promoted to one `V`, which is `Float64` or a static array of `Float64`, and
taken by `float`, so integer values qualify. Boundary zero sets every prior to
not-holding (§10.6), so an `x0` outside the limits is clamped there, and the
initial mode agrees with the initial input.
"""
struct LimitedIntegrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}, L} <: AbstractComponent
    x0::V
    lower::V
    upper::V
end
function LimitedIntegrator(; lower, upper, x0 = zero(lower), localized = true)
    x0, lower, upper = float.(promote(x0, lower, upper))
    LimitedIntegrator{typeof(x0), localized}(x0, lower, upper)
end
x_init(c::LimitedIntegrator) = (q = c.x0,)
m_init(c::LimitedIntegrator) = (saturation = Int8.(zero(c.x0)),)    # -1 lower, 0 free, +1 upper
u_types(::LimitedIntegrator{V}) where {V} = (in = V,)
y_types(::LimitedIntegrator{V}) where {V <: Real} = (out = V, saturation = Int8)
y_types(::LimitedIntegrator{V}) where {V <: StaticArray} = (out = V, saturation = similar_type(V, Int8))
y_state(::LimitedIntegrator, (; x, m)) = (out = x.q, saturation = m.saturation)
x_deriv(::LimitedIntegrator, (; u, m)) = (q = ifelse.(m.saturation .== 0, u.in, zero(u.in)),)
# The hit guards are not gated by the free code on purpose. Gated, a hit guard
# would read `0` the instant a leave handler frees the mode, present a fresh
# edge and saturate the block again.
hit_upper_guard(c::LimitedIntegrator, (; x)) = x.q - c.upper
hit_lower_guard(c::LimitedIntegrator, (; x)) = c.lower - x.q
# The leave guards gate on strictly inward input. Gated on the mode alone, an
# input of exactly zero reads `-0.0`, which holds, and frees the mode with `q`
# on the limit. The gate `u.in < 0` reads a wired signal, so §10.4's argument
# that gates stay fixed through a localization does not cover it: σ jumps from
# `-1` to a small positive value at the input's zero crossing. The bracket still
# converges on that crossing, since only the sign drives it, but ITP falls back
# to bisection's count, about 15 extra interior sweeps per leave.
leave_upper_guard(::LimitedIntegrator{V, true}, (; m, u)) where {V} =
    m.saturation == 1 && u.in < 0 ? -u.in : -one(u.in)
leave_lower_guard(::LimitedIntegrator{V, true}, (; m, u)) where {V} =
    m.saturation == -1 && u.in > 0 ? u.in : -one(u.in)
# The `Bool` forms are the same predicates, boundary-detected and strict by
# construction.
leave_upper_guard(::LimitedIntegrator{V, false}, (; m, u)) where {V} =
    m.saturation == 1 && u.in < 0
leave_lower_guard(::LimitedIntegrator{V, false}, (; m, u)) where {V} =
    m.saturation == -1 && u.in > 0
hit_upper_handler(c::LimitedIntegrator, _) = (x = (q = c.upper,), m = (saturation = Int8(1),))
hit_lower_handler(c::LimitedIntegrator, _) = (x = (q = c.lower,), m = (saturation = Int8(-1),))
leave_handler(::LimitedIntegrator, _) = (m = (saturation = Int8(0),),)
state_events(::LimitedIntegrator{V}) where {V <: Real} =
    (hit_upper = StateEvent(hit_upper_guard, hit_upper_handler),
     hit_lower = StateEvent(hit_lower_guard, hit_lower_handler),
     leave_upper = StateEvent(leave_upper_guard, leave_handler),
     leave_lower = StateEvent(leave_lower_guard, leave_handler))
# The events are per component, not reductions over the vector, so the scalar
# reasoning holds component by component. A reduced hit guard holds for good
# once one component sits clamped on its limit, so a second arrival makes no
# edge, and gating it by the mode brings back the re-saturation above.
function state_events(::LimitedIntegrator{V, L}) where {V <: StaticArray, L}
    N = length(V)
    hit_upper = ntuple(N) do i
        StateEvent((c, (; x)) -> x.q[i] - c.upper[i],
                   (c, (; x, m)) -> (x = (q = Base.setindex(x.q, c.upper[i], i),),
                                     m = (saturation = Base.setindex(m.saturation, Int8(1), i),)))
    end
    hit_lower = ntuple(N) do i
        StateEvent((c, (; x)) -> c.lower[i] - x.q[i],
                   (c, (; x, m)) -> (x = (q = Base.setindex(x.q, c.lower[i], i),),
                                     m = (saturation = Base.setindex(m.saturation, Int8(-1), i),)))
    end
    leave_upper = ntuple(N) do i
        guard = L ? ((c, (; m, u)) -> m.saturation[i] == 1 && u.in[i] < 0 ? -u.in[i] : -one(u.in[i])) :
                    ((c, (; m, u)) -> m.saturation[i] == 1 && u.in[i] < 0)
        StateEvent(guard, (c, (; m)) -> (m = (saturation = Base.setindex(m.saturation, Int8(0), i),),))
    end
    leave_lower = ntuple(N) do i
        guard = L ? ((c, (; m, u)) -> m.saturation[i] == -1 && u.in[i] > 0 ? u.in[i] : -one(u.in[i])) :
                    ((c, (; m, u)) -> m.saturation[i] == -1 && u.in[i] > 0)
        StateEvent(guard, (c, (; m)) -> (m = (saturation = Base.setindex(m.saturation, Int8(0), i),),))
    end
    names = (ntuple(i -> Symbol(:hit_upper_, i), N)..., ntuple(i -> Symbol(:hit_lower_, i), N)...,
             ntuple(i -> Symbol(:leave_upper_, i), N)..., ntuple(i -> Symbol(:leave_lower_, i), N)...)
    NamedTuple{names}((hit_upper..., hit_lower..., leave_upper..., leave_lower...))
end

"""
    Relay(; lower, upper, off = zero(lower), on = one.(lower))

The relay with hysteresis: `out` publishes `off` or `on` by the mode `state`,
from stage 1. The mode is an `Int8` code, `0` off and `1` on. Two state events
move it. `switch_on` fires when `in` rises to `upper` while off, and
`switch_off` when `in` falls to `lower` while on. Both guards are sign forms
gated by the mode in §10.4's form, so both are localized.

`out` reads no input, so the block has no feedthrough (§5.3), and a relay
closing a feedback loop makes no algebraic loop. It is the library's reference
mode-switching leaf. `lower < upper`. The four values are promoted to one `V`,
which is `Float64` or a static array of `Float64`, and taken by `float`, so
integer values qualify. `out` is pinned at `V` (D-312): it depends on the mode
and the instance alone, so it carries zero partials under every activation.

Over a static vector, the thresholds, the values and the codes are
componentwise. The block declares `N` copies of the two events, one per
component, named `switch_on_1` to `switch_on_N`, then `switch_off_i`: each
guard reads its one component and each handler writes it.

The relay starts off. Boundary zero sets every prior to not-holding (§10.6), so
an input already at or above `upper` at `t₀` turns it on there, and an input
between the thresholds leaves it off, which is the hysteresis itself.
"""
struct Relay{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    lower::V      # switch off when `in` falls to it
    upper::V      # switch on when `in` rises to it
    off::V        # `out` while off
    on::V         # `out` while on
end
Relay(; lower, upper, off = zero(lower), on = one.(lower)) =
    Relay(float.(promote(lower, upper, off, on))...)
x_init(::Relay) = (;)
m_init(c::Relay) = (state = Int8.(zero(c.lower)),)    # 0 off, 1 on
u_types(::Relay{V}) where {V} = (in = V,)
y_types(::Relay{V}) where {V} = (out = Pinned{V},)
y_state(c::Relay, (; m)) = (out = ifelse.(m.state .== 1, c.on, c.off),)
switch_on_guard(c::Relay, (; m, u)) = m.state == 0 ? u.in - c.upper : -one(u.in)
switch_off_guard(c::Relay, (; m, u)) = m.state == 1 ? c.lower - u.in : -one(u.in)
switch_on_handler(::Relay, _) = (m = (state = Int8(1),),)
switch_off_handler(::Relay, _) = (m = (state = Int8(0),),)
state_events(::Relay{V}) where {V <: Real} =
    (switch_on = StateEvent(switch_on_guard, switch_on_handler),
     switch_off = StateEvent(switch_off_guard, switch_off_handler))
function state_events(::Relay{V}) where {V <: StaticArray}
    N = length(V)
    switch_on = ntuple(N) do i
        StateEvent((c, (; m, u)) -> m.state[i] == 0 ? u.in[i] - c.upper[i] : -one(u.in[i]),
                   (c, (; m)) -> (m = (state = Base.setindex(m.state, Int8(1), i),),))
    end
    switch_off = ntuple(N) do i
        StateEvent((c, (; m, u)) -> m.state[i] == 1 ? c.lower[i] - u.in[i] : -one(u.in[i]),
                   (c, (; m)) -> (m = (state = Base.setindex(m.state, Int8(0), i),),))
    end
    names = (ntuple(i -> Symbol(:switch_on_, i), N)..., ntuple(i -> Symbol(:switch_off_, i), N)...)
    NamedTuple{names}((switch_on..., switch_off...))
end

# --- the anonymous assembly (§8.5, D-211) -------------------------------------

"""
`Group`: the library's on-the-fly assembly, whose *values* are the ad-hoc
topologies. It needs no new rule — the container-children rule makes the
`children` field's elements children of the `Group` itself, and the four
declarations are ordinary functions of the instance, free to read its fields.

The one declaration it adds is `transparent_container` (D-211): `children` is
name-transparent, so its elements go by **bare key** everywhere a child name
appears — `"ctl/out" => "plant/u"` for a wire, `(ctl = Relative(2),)` for a rate,
`at("ctl", …)` for a condition prefix, `"plant/y"` for a read path. A `Group`'s
declarations are then textually identical to a named assembly's; the rate
declaration's field-name sugar, keying on the field rather than on a path
segment, keeps working as `(children = Relative(2),)` for the uniform case.

The type parameters carry the children's concrete types, so the executor's
specialization is unchanged; what is given up against a named type is dispatch,
which exploratory composition does not want.
"""
struct Group{C <: NamedTuple, W, I, O, R <: NamedTuple} <: AbstractComponent
    children::C       # component-typed elements → children by the container rule
    local_wires::W    # inert parameter data
    input_wires::I
    output_wires::O
    sample_times::R   # the ad-hoc rate scope, keyed by bare element name (§8.7)
end

"""
    Group(children; local_wires = (), input_wires = (), output_wires = (),
          sample_times = (;))

The convenience form. Each keyword takes the name of the declaration it feeds.
A bare `Pair` passed for `local_wires`, `input_wires` or `output_wires` is the
one-entry tuple — the declarations are ordered collections of pairs, and a
single wire should not have to be written `("a/x" => "b/y",)`.
"""
Group(children; local_wires = (), input_wires = (), output_wires = (),
      sample_times = (;)) =
    Group(children, _entries(local_wires), _entries(input_wires),
          _entries(output_wires), sample_times)

_entries(wires::Pair) = (wires,)
_entries(wires) = wires

local_wires(g::Group) = g.local_wires
input_wires(g::Group) = g.input_wires
output_wires(g::Group) = g.output_wires
sample_times(g::Group) = g.sample_times
transparent_container(::Group) = :children

end # module Blocks
