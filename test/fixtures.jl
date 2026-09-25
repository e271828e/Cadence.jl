# The suite's fixture set: the components, assemblies, devices and bindings the
# tests build models from. Coverage-driven — between them they exercise every
# shape the framework has to handle, and no more. None of it is framework
# material: no name here is known to `src/`.
#
# Everything lives at top level because a declaration written in a local scope
# binds a new local function rather than extending Cadence's generic (D-164,
# implementation.md's authoring caveat).

"""
Damped second-order plant. Carries state, publishes a **stage-1** port (`y`,
state-derived, no feedthrough — the port that lets a feedback loop close
legally) and a **stage-2** port (`power`, input-dependent), and defines `state_derivative`.
"""
struct Plant <: AbstractComponent
    ω::Float64
    ζ::Float64
    q₀::SVector{2,Float64}
end

Plant(; ω = 2.0, ζ = 0.1, q₀ = SVector(0.0, 0.0)) = Plant(ω, ζ, q₀)

init_x(c::Plant) = (q = c.q₀,)
input_types(::Plant) = (u = Float64,)
output_types(::Plant) = (y = Float64, power = Float64)

output_state(::Plant, (; x)) = (y = x.q[1],)
output_direct(::Plant, (; x, u)) = (power = u.u * x.q[2],)

function state_derivative(c::Plant, (; x, u))
    q, ω, ζ = x.q, c.ω, c.ζ
    (q = SVector(q[2], -ω^2 * q[1] - 2ζ * ω * q[2] + u.u),)
end

# --- §5.3's stage-1 return of exposed state ------------------------------------
# Components exposing a state or mode field by returning it from `output_state`,
# plus the refusal fixtures that declare one and return it from no stage (D-252).

"""
§8.2's worked engine at the suite's size: `ω` is a state field and `running` a
mode field, both declared and both returned from `output_state`; `M_shaft` is
the one stage-2 product. The boundary-detected `start` event flips `running` at
`t = 0.1`, after which `M_shaft = 1` — with `M_load = 0` and `J = 1`,
`ω(t) = max(t − 0.1, 0)` at every boundary.
"""
struct Motor <: AbstractComponent
    J::Float64
end

init_x(::Motor) = (ω = 0.0,)
init_m(::Motor) = (running = false,)
input_types(::Motor) = (M_load = Float64,)
output_types(::Motor) = (M_shaft = Float64, ω = Float64, running = Bool)

output_state(::Motor, (; x, m)) = (ω = x.ω, running = m.running)
output_direct(::Motor, (; x, m, u)) = (M_shaft = m.running ? one(x.ω) : zero(x.ω),)
state_derivative(c::Motor, (; x, y, u)) = (ω = (y.M_shaft - u.M_load) / c.J,)

motor_start_guard(::Motor, (; m, t)) = !m.running && t ≥ 0.1
motor_start_handler(::Motor, (; m)) = (m = (running = true,),)
state_events(::Motor) = (start = StateEvent(motor_start_guard, motor_start_handler),)

"""
`Plant` exposing its whole state vector as one stage-1 port: `q` is declared as
an `SVector` and returned from `output_state`, which is what lets
`vector_feedback_model` close the same loop through it.
"""
struct VectorPlant <: AbstractComponent
    ω::Float64
    ζ::Float64
    q₀::SVector{2,Float64}
end

VectorPlant(; ω = 2.0, ζ = 0.1, q₀ = SVector(0.0, 0.0)) = VectorPlant(ω, ζ, q₀)

init_x(c::VectorPlant) = (q = c.q₀,)
input_types(::VectorPlant) = (u = Float64,)
output_types(::VectorPlant) = (q = SVector{2,Float64}, power = Float64)

output_state(::VectorPlant, (; x)) = (q = x.q,)
output_direct(::VectorPlant, (; x, u)) = (power = u.u * x.q[2],)

function state_derivative(c::VectorPlant, (; x, u))
    q, ω, ζ = x.q, c.ω, c.ζ
    (q = SVector(q[2], -ω^2 * q[1] - 2ζ * ω * q[2] + u.u),)
end

"""Proportional state feedback on the plant's state-vector port: stage 2 only."""
struct StateFeedback <: AbstractComponent
    k::Float64
end

init_x(::StateFeedback) = (;)
input_types(::StateFeedback) = (q = SVector{2,Float64},)
output_types(::StateFeedback) = (u = Float64,)

output_direct(c::StateFeedback, (; u)) = (u = -c.k * u.q[1],)

"""`DiscreteCounter` without its `output_state`: `n` is declared and no stage returns it."""
struct UnreturnedCounter <: AbstractComponent end

init_s(::UnreturnedCounter) = (n = 0,)
output_types(::UnreturnedCounter) = (n = Int,)
state_update(::UnreturnedCounter, (; s)) = (n = s.n + 1,)

"""
A `Pinned` declaration of a walking state field, returned from stage 1:
exact at the nominal activation, and a refusal at every other one — stripping
the partials would be a stop-gradient the author never wrote (§5.3, D-166).
"""
struct PinnedState <: AbstractComponent end

init_x(::PinnedState) = (q = 0.0,)
output_types(::PinnedState) = (q = Pinned{Float64},)
output_state(::PinnedState, (; x)) = (q = x.q,)
state_derivative(::PinnedState, (; x)) = (q = 0.0,)

"""One port returned from both stages: two writers of one cell (§8.3)."""
struct Twice <: AbstractComponent end

init_x(::Twice) = (q = 0.0,)
output_types(::Twice) = (q = Float64,)
output_state(::Twice, (; x)) = (q = x.q,)
output_direct(::Twice, (; x)) = (q = x.q,)
state_derivative(::Twice, (; x)) = (q = 0.0,)

"""
A stage-2 product named after a mode field the store holds at *another* type,
beside a declared state field no stage returns. The classification is structural
and names only (§9.1, the nominal evaluation), so `flag` is a stage-2 product at every
activation, over a non-empty product list.
"""
struct ModeNamedProduct <: AbstractComponent end

init_x(::ModeNamedProduct) = (q = 0.0,)
init_m(::ModeNamedProduct) = (flag = 0,)
output_types(::ModeNamedProduct) = (flag = Float64, q = Float64)
output_direct(::ModeNamedProduct, (; x, m)) = (flag = m.flag * one(x.q),)
state_derivative(::ModeNamedProduct, (; x)) = (q = 0.0,)

"""
Proportional gain: **stateless**, stage 2 only. The three-level funnel of §5.2
in its smallest instance — a component that legitimately writes `output_direct` while
owning no state at all, so its bundle carries `u` and `t` and nothing else.
"""
struct Gain <: AbstractComponent
    k::Float64
end

init_x(::Gain) = (;)
input_types(::Gain) = (e = Float64,)
output_types(::Gain) = (out = Float64,)

output_direct(c::Gain, (; u)) = (out = c.k * u.e,)

"""
Two-input summing junction (§6.2): aggregation is an explicit, ordered entry in
the schedule, never an implicit fan-in.
"""
struct Sum <: AbstractComponent
    sa::Float64
    sb::Float64
end

Sum(; sa = 1.0, sb = -1.0) = Sum(sa, sb)

init_x(::Sum) = (;)
input_types(::Sum) = (a = Float64, b = Float64)
output_types(::Sum) = (e = Float64,)

output_direct(c::Sum, (; u)) = (e = c.sa * u.a + c.sb * u.b,)

# --- the discrete tier --------------------------------------------------------
# The tier's own store and update law (D-195) — `init_s`, `state_update` — with
# the shared output stages (D-220): these components declare the pinned world,
# and nothing about them walks with the activation (D-263).

"""
Discrete integrator: publishes its state from **stage 1** — the loop-breaking
port, exactly as on the continuous tier — and accumulates in `state_update`, which is
where `Δt` earns its place in the bundle.
"""
struct DiscreteIntegrator <: AbstractComponent
    k::Float64
end

init_s(::DiscreteIntegrator) = (acc = 0.0,)
input_types(::DiscreteIntegrator) = (e = Float64,)
output_types(::DiscreteIntegrator) = (u = Float64,)

output_state(::DiscreteIntegrator, (; s)) = (u = s.acc,)
state_update(c::DiscreteIntegrator, (; s, u, Δt)) = (acc = s.acc + c.k * Δt * u.e,)

"""
Tick counter: `Int` state, `Int` and `Bool` ports. The second and third store
buffers of the bundle, which a continuous model never needs (D-162).
"""
struct TickCounter <: AbstractComponent end

init_s(::TickCounter) = (n = 0,)
output_types(::TickCounter) = (n = Int, even = Bool)

output_state(::TickCounter, (; s)) = (n = s.n, even = iseven(s.n))
state_update(::TickCounter, (; s)) = (n = s.n + 1,)

"""
Stateful discrete leaf whose update law decides its tier beside its store:
`state_update` present. The classifier's positive case, and the discrete half of
the bundle law.
"""
struct DiscreteCounter <: AbstractComponent end

init_s(::DiscreteCounter) = (n = 0,)
output_types(::DiscreteCounter) = (n = Int,)

output_state(::DiscreteCounter, (; s)) = (n = s.n,)
state_update(::DiscreteCounter, (; s)) = (n = s.n + 1,)

"""
Stateless discrete leaf: its empty store alone declares the tier.
"""
struct DiscreteMap <: AbstractComponent end

init_s(::DiscreteMap) = (;)
input_types(::DiscreteMap) = (a = Int,)
output_types(::DiscreteMap) = (b = Int,)

output_direct(::DiscreteMap, (; u)) = (b = 2u.a,)

"""
Two-channel exponential smoother, written in §7.3's blessed idiom: the in-place
math runs on the workspace, and what reaches the store is an isbits snapshot.
Nothing carries between calls — the scratch is garbage until written.
"""
struct Smoother <: AbstractComponent
    α::Float64
end

init_s(::Smoother) = (v = SVector(0.0, 0.0),)
input_types(::Smoother) = (a = Float64, b = Float64)
output_types(::Smoother) = (v = SVector{2,Float64},)
init_workspace(::Smoother, ::Type) = (tmp = Vector{Float64}(undef, 2),)

output_state(::Smoother, (; s)) = (v = s.v,)

function state_update(c::Smoother, (; s, u, ws))
    ws.tmp[1] = u.a
    ws.tmp[2] = u.b
    for i in 1:2
        ws.tmp[i] = c.α * ws.tmp[i] + (1 - c.α) * s.v[i]
    end
    (v = SVector{2,Float64}(ws.tmp[1], ws.tmp[2]),)
end

# --- the other two declarations the bundle law owes -------------------------

"""
A continuous workspace user, allocating at the activation scalar so the scratch
follows `Dual` when the activation does.
"""
struct WorkGain <: AbstractComponent
    k::Float64
end

init_x(::WorkGain) = (;)
input_types(::WorkGain) = (in = Float64,)
output_types(::WorkGain) = (out = Float64,)
init_workspace(::WorkGain, ::Type{T}) where {T <: Real} = (tmp = Vector{T}(undef, 1),)

function output_direct(c::WorkGain, (; u, ws))
    ws.tmp[1] = c.k * u.in
    (out = ws.tmp[1],)
end

"""
A mode-carrying source: modes are continuous-only, read here and written by
nothing — a component may legitimately declare modes no event of its own
transitions (§8.2). The branch returning a literal is the constant-branch
idiom (D-166).
"""
struct ModedSource <: AbstractComponent end

init_m(::ModedSource) = (phase = :idle,)
init_x(::ModedSource) = (;)
output_types(::ModedSource) = (out = Float64,)

output_state(::ModedSource, (; m)) = (out = m.phase === :idle ? 0.0 : 1.0,)

"""
Modes and a derivative, and no store: `init_m` is no state store, so nothing
declares a tier — §8.2's `TierUnreadable`.
"""
struct ModesNoContract <: AbstractComponent end

init_m(::ModesNoContract) = (phase = :idle,)
state_derivative(::ModesNoContract, (; m)) = (;)

# --- the event coverage set (§2.1, §10.6) -------------------------------------
# Guards and handlers are ordinary named functions referenced by `state_events` —
# nothing global-generic about them, which is why they carry component-prefixed
# names here rather than adding methods to a framework surface.

"""
Threshold trigger: mode-only state, a `Bool` guard on its input against a
level, and a *sticky* predicate — the input stays above the level after the
transition, so edge semantics must make it fire exactly once. `count` records
firings, which is what the tests read.
"""
struct Trigger <: AbstractComponent
    level::Float64
end

init_m(::Trigger) = (state = :armed, count = 0)
init_x(::Trigger) = (;)
input_types(::Trigger) = (sig = Float64,)
output_types(::Trigger) = (on = Bool,)

output_state(::Trigger, (; m)) = (on = m.state === :fired,)

trigger_guard(c::Trigger, (; u)) = u.sig ≥ c.level
trigger_handler(::Trigger, (; m)) = (m = (state = :fired, count = m.count + 1),)
state_events(::Trigger) = (fire = StateEvent(trigger_guard, trigger_handler),)

"""
Cascade follower: goes `:idle → :on` on the rising edge of its `Bool` input. A
chain of these under a `Trigger` is §10.6's logically-simultaneous cascade —
settled within one boundary, one iteration round per link, independent of `h`.
"""
struct Follower <: AbstractComponent end

init_m(::Follower) = (state = :idle,)
init_x(::Follower) = (;)
input_types(::Follower) = (go = Bool,)
output_types(::Follower) = (on = Bool,)

output_state(::Follower, (; m)) = (on = m.state === :on,)

follower_guard(::Follower, (; u)) = u.go
follower_handler(::Follower, (; m)) = (m = (state = :on,),)
state_events(::Follower) = (engage = StateEvent(follower_guard, follower_handler),)

"""
Sawtooth: `q̇ = rate`, and a **sign-form** guard `q − 1` whose handler carries
the overshoot across the reset, `q ← q − 1`. The sign form declares the event
localized (§10.4, D-179) — and the carrying handler makes the *trajectory*
invariant to where the firing lands, `q(t) = rate·t − #wraps` either way, so
the boundary-detected recursion stays its exact reference. What localization
changes here is only the timing resolution `Bouncer` makes observable.
"""
struct Sawtooth <: AbstractComponent
    rate::Float64
end

init_x(::Sawtooth) = (q = 0.0,)
output_types(::Sawtooth) = (q = Float64,)

output_state(::Sawtooth, (; x)) = (q = x.q,)
state_derivative(c::Sawtooth, (; x)) = (q = c.rate,)

sawtooth_guard(::Sawtooth, (; x)) = x.q - 1.0
sawtooth_handler(::Sawtooth, (; x)) = (x = (q = x.q - 1.0,),)
state_events(::Sawtooth) = (wrap = StateEvent(sawtooth_guard, sawtooth_handler),)

"""
Unit-circle rotor: `ċ = -ω s, ṡ = ω c` under a renormalizing `state_projection` — the
state manifold in miniature. Boundary zero already projects (§14.5), so a
deliberately off-manifold `init_x` lands on the circle before the first step.
"""
struct Rotor <: AbstractComponent
    ω::Float64
    r₀::SVector{2,Float64}
end

Rotor(; ω = 1.0, r₀ = SVector(1.0, 0.0)) = Rotor(ω, r₀)

init_x(c::Rotor) = (r = c.r₀,)
output_types(::Rotor) = (c = Float64,)

output_state(::Rotor, (; x)) = (c = x.r[1],)
state_derivative(c::Rotor, (; x)) = (r = SVector(-c.ω * x.r[2], c.ω * x.r[1]),)
state_projection(::Rotor, x) = (r = x.r / sqrt(x.r[1]^2 + x.r[2]^2),)

"""
Two events toggling one mode: each transition re-arms the other, so the pair
chatters without bound and each spends `firing_budget` at the first boundary —
the §10.6 degradation path, warned and bounded while the rest of the model
iterates untouched. `flips` counts every firing.
"""
struct Chatterer <: AbstractComponent end

init_m(::Chatterer) = (v = false, flips = 0)
init_x(::Chatterer) = (;)
output_types(::Chatterer) = (v = Bool,)

output_state(::Chatterer, (; m)) = (v = m.v,)

chatter_up(::Chatterer, (; m)) = !m.v
chatter_down(::Chatterer, (; m)) = m.v
chatter_flip(::Chatterer, (; m)) = (m = (v = !m.v, flips = m.flips + 1),)
state_events(::Chatterer) = (up = StateEvent(chatter_up, chatter_flip),
                       down = StateEvent(chatter_down, chatter_flip))

"""
Two events on one predicate: both edges rise in the same round, the first fires
by declaration order, and the second is eligible but blocked — its sample is
*not* overwritten (D-191), so the standing edge fires it in the next round.
"""
struct TwoShot <: AbstractComponent end

init_m(::TwoShot) = (a = false, b = false)
init_x(::TwoShot) = (;)
input_types(::TwoShot) = (sig = Float64,)
output_types(::TwoShot) = (a = Bool,)

output_state(::TwoShot, (; m)) = (a = m.a,)

twoshot_guard(::TwoShot, (; u)) = u.sig ≥ 1.0
twoshot_a(::TwoShot, (; m)) = (m = (; a = true),)
twoshot_b(::TwoShot, (; m)) = (m = (; b = true),)
state_events(::TwoShot) = (first = StateEvent(twoshot_guard, twoshot_a),
                     second = StateEvent(twoshot_guard, twoshot_b))

"""
The blocked-then-falsified variant: the second event's premise includes the
first's *not* having fired, so the round-1 block defers it into a round where
the premise is gone — it re-decides against the post-transition sweep and never
fires, where a within-round sequence would have fired it on the stale premise.
"""
struct Preempted <: AbstractComponent end

init_m(::Preempted) = (a = false, b = false)
init_x(::Preempted) = (;)
input_types(::Preempted) = (sig = Float64,)
output_types(::Preempted) = (a = Bool,)

output_state(::Preempted, (; m)) = (a = m.a,)

preempted_guard_a(::Preempted, (; u)) = u.sig ≥ 1.0
preempted_guard_b(::Preempted, (; u, m)) = u.sig ≥ 1.0 && !m.a
preempted_a(::Preempted, (; m)) = (m = (; a = true),)
preempted_b(::Preempted, (; m)) = (m = (; b = true),)
state_events(::Preempted) = (first = StateEvent(preempted_guard_a, preempted_a),
                       second = StateEvent(preempted_guard_b, preempted_b))

# --- the localization coverage set (§10.4) --------------------------------------

"""
Crossing stamper: a **sign-form** guard on its input against a level, and a
handler that records the boundary time it fired at — the direct observable for
`t*`. A localized firing stamps within `localization_tol` of the true crossing
(exactly, when the trajectory feeding it is polynomial of degree ≤ 3, where the
Hermite interpolant is exact); an epoch-caused or degenerate edge stamps its
frame top exactly.
"""
struct Stamper <: AbstractComponent
    level::Float64
end

init_m(::Stamper) = (t_fired = -1.0, count = 0)
init_x(::Stamper) = (;)
input_types(::Stamper) = (sig = Float64,)
output_types(::Stamper) = (armed = Bool,)

output_state(::Stamper, (; m)) = (armed = m.count == 0,)

stamper_guard(c::Stamper, (; u)) = u.sig - c.level
stamper_handler(::Stamper, (; m, t)) = (m = (t_fired = t, count = m.count + 1),)
state_events(::Stamper) = (cross = StateEvent(stamper_guard, stamper_handler),)

"""
The gate idiom (§10.4): a mixed predicate in its blessed spelling,
`(gate) ? σ : -one(σ)` — the `Bool` factor rides the branch, the continuous
factor rides the value, and the guard's return type stays the nominal scalar,
so the event is localized. Trial evaluations vary only θ, with `u` fixed
through a localization, so the gate is constant over the bracket and σ
restricted to it is the continuous atom.
"""
struct GatedStamper <: AbstractComponent
    level::Float64
end

init_m(::GatedStamper) = (t_fired = -1.0, count = 0)
init_x(::GatedStamper) = (;)
input_types(::GatedStamper) = (sig = Float64, gate = Bool)
output_types(::GatedStamper) = (armed = Bool,)

output_state(::GatedStamper, (; m)) = (armed = m.count == 0,)

function gated_stamper_guard(c::GatedStamper, (; u))
    σ = u.sig - c.level
    u.gate ? σ : -one(σ)
end
gated_stamper_handler(::GatedStamper, (; m, t)) = (m = (t_fired = t, count = m.count + 1),)
state_events(::GatedStamper) = (cross = StateEvent(gated_stamper_guard, gated_stamper_handler),)

"""
Resetting ramp: `q̇ = rate` against a sign guard at `level`, and a handler that
*discards* the overshoot, `q ← 0` — unlike `Sawtooth`'s carrying handler, so
the trajectory itself depends on where the firing lands. Localized resets give
the exact period `level/rate`; boundary-resolution resets accumulate the
overshoot as phase error, which is the observable §10.4 buys.
"""
struct Bouncer <: AbstractComponent
    rate::Float64
    level::Float64
end

init_x(::Bouncer) = (q = 0.0,)
init_m(::Bouncer) = (count = 0,)
output_types(::Bouncer) = (q = Float64,)

output_state(::Bouncer, (; x)) = (q = x.q,)
state_derivative(c::Bouncer, (; x)) = (q = c.rate,)

bouncer_guard(c::Bouncer, (; x)) = x.q - c.level
bouncer_handler(::Bouncer, (; x, m)) = (x = (q = 0.0,), m = (count = m.count + 1,))
state_events(::Bouncer) = (reset = StateEvent(bouncer_guard, bouncer_handler),)

"""
Relaxation chatterer: `q̇ = rate` against a sign guard at `level`, re-armed by
its own handler to `level − drop` — each remainder step re-crosses within the
same frame, so localizations pile up until `localization_budget` is spent and
the frame degrades to boundary granularity under a `ChatteringBudget` warning
(§10.4), while the run proceeds deterministically.
"""
struct Relaxer <: AbstractComponent
    rate::Float64
    level::Float64
    drop::Float64
end

init_x(::Relaxer) = (q = 0.0,)
init_m(::Relaxer) = (count = 0,)
output_types(::Relaxer) = (q = Float64,)

output_state(::Relaxer, (; x)) = (q = x.q,)
state_derivative(c::Relaxer, (; x)) = (q = c.rate,)

relaxer_guard(c::Relaxer, (; x)) = x.q - c.level
relaxer_handler(c::Relaxer, (; x, m)) =
    (x = (q = c.level - c.drop,), m = (count = m.count + 1,))
state_events(::Relaxer) = (pop = StateEvent(relaxer_guard, relaxer_handler),)

# --- the termination coverage set (§13.5, §13.6) -------------------------------

"""
Overload monitor: §13.5's touchdown archetype — a **sign-form** guard on its
input against a level, a handler that latches `m.tripped`, and the sticky
`Bool` output face a `stop_on` policy names. The sign form declares the event
localized, so a run stopped on `tripped` ends at the crossing's `t*` boundary
with the crossing state as the terminal snapshot.
"""
struct Overload <: AbstractComponent
    level::Float64
end

init_m(::Overload) = (tripped = false,)
init_x(::Overload) = (;)
input_types(::Overload) = (sig = Float64,)
output_types(::Overload) = (tripped = Bool,)

output_state(::Overload, (; m)) = (tripped = m.tripped,)

overload_guard(c::Overload, (; u)) = u.sig - c.level
overload_handler(::Overload, (; m)) = (m = (tripped = true,),)
state_events(::Overload) = (trip = StateEvent(overload_guard, overload_handler),)

"""
    overloaded()

A sawtooth crossing the overload's level mid-frame, so the stop localizes to the
crossing's `t*` boundary (§13.5).
"""
overloaded() = Group((; src = Sawtooth(1.0), mon = Overload(0.315));
                     wires = ("src/q" => "mon/sig",),
                     outputs = ("mon/tripped" => "tripped",))

"""
`Overload` with its `output_state` removed: `tripped` is a mode field declared
public that no stage returns (§5.3, D-252), so the component runs no stage at
all.
"""
struct UnreturnedMode <: AbstractComponent
    level::Float64
end

init_m(::UnreturnedMode) = (tripped = false,)
init_x(::UnreturnedMode) = (;)
input_types(::UnreturnedMode) = (sig = Float64,)
output_types(::UnreturnedMode) = (tripped = Bool,)

"""
Exploder: the §13.6 specimen — `q̇ = 1` until its `arm` input goes true, then
its RHS throws `Exploded`. The throw escapes mid-integration, so the failing
frame has published nothing: what the abnormal tail leaves as final is the
last completed boundary's snapshot, which is the §13.6 discard-and-promote
made observable.
"""
struct Exploder <: AbstractComponent end

"Exploder's own exception type, so the tests assert the retained cause's identity."
struct Exploded <: Exception end

init_x(::Exploder) = (q = 0.0,)
input_types(::Exploder) = (arm = Bool,)
output_types(::Exploder) = (q = Float64,)

output_state(::Exploder, (; x)) = (q = x.q,)
state_derivative(::Exploder, (; x, u)) = u.arm ? throw(Exploded()) : (q = one(x.q),)

# --- the runtime-failure coverage set (§13.4) ----------------------------------
# One component per user-code surface the execution cursor names, each failing
# only when armed so the build probe — which runs every stage, guard, handler,
# update and projection once — passes.

"Tripwire's exception, so the tests assert the retained cause's identity."
struct Tripped <: Exception end

"The exception the mine family throws, likewise."
struct Detonated <: Exception end

"""
Tripwire: `q̇ = 1` until `t` reaches `t_trip` with `arm` true, when the RHS
throws `Tripped`. With `t_trip` at a half-step time the throw lands at RK4's
second stage evaluation, which is what makes the cursor's stage ordinal
observable.
"""
struct Tripwire <: AbstractComponent
    t_trip::Float64
end

init_x(::Tripwire) = (q = 0.0,)
input_types(::Tripwire) = (arm = Bool,)
output_types(::Tripwire) = (q = Float64,)

output_state(::Tripwire, (; x)) = (q = x.q,)
state_derivative(c::Tripwire, (; x, u, t)) = (u.arm && t ≥ c.t_trip) ? throw(Tripped()) : (q = one(x.q),)

"""
Mine: a `Bool` input and a predicate-form event whose handler throws
`Detonated` — the failure inside an event round, at boundary resolution.
"""
struct Mine <: AbstractComponent end

init_m(::Mine) = (blown = false,)
init_x(::Mine) = (;)
input_types(::Mine) = (sig = Bool,)
output_types(::Mine) = (blown = Bool,)

output_state(::Mine, (; m)) = (blown = m.blown,)

mine_guard(::Mine, (; u)) = u.sig
mine_handler(::Mine, (; u, m)) = u.sig ? throw(Detonated()) : (m = (blown = true,),)
state_events(::Mine) = (blow = StateEvent(mine_guard, mine_handler),)

"""
Landmine: a `Bouncer` whose sign-form guard throws `Detonated` when `t` is off
the grid. Arrival, validation and the boundary rounds all sit on the grid before
any `t*` has occurred, so the only evaluation that reaches the throw is a
localization trial.
"""
struct Landmine <: AbstractComponent
    rate::Float64
    level::Float64
    h::Float64          # the deployment's step, so the guard can tell the grid
end

init_x(::Landmine) = (q = 0.0,)
init_m(::Landmine) = (count = 0,)
output_types(::Landmine) = (q = Float64,)

output_state(::Landmine, (; x)) = (q = x.q,)
state_derivative(c::Landmine, (; x)) = (q = c.rate,)

function landmine_guard(c::Landmine, (; x, t))
    abs(t - round(t / c.h) * c.h) > 1e-9 && throw(Detonated())
    x.q - c.level
end
landmine_handler(::Landmine, (; x, m)) = (x = (q = 0.0,), m = (count = m.count + 1,))
state_events(::Landmine) = (blow = StateEvent(landmine_guard, landmine_handler),)

"""
Sapper: the discrete-tier mine — `state_update` throws `Detonated` when its input is set,
so the failure lands in the tick updates, the boundary sequence's last block.
"""
struct Sapper <: AbstractComponent end

init_s(::Sapper) = (n = 0,)
input_types(::Sapper) = (sig = Bool,)
output_types(::Sapper) = (n = Int,)

output_state(::Sapper, (; s)) = (n = s.n,)
state_update(::Sapper, (; s, u)) = u.sig ? throw(Detonated()) : (n = s.n + 1,)

"""
Primer: `q̇ = 1` with a `state_projection` that throws `Detonated` once `q` reaches
`level` — the failure at the boundary's projection, between the integrate's
state write and its decode.
"""
struct Primer <: AbstractComponent
    level::Float64
end

init_x(::Primer) = (q = 0.0,)
output_types(::Primer) = (q = Float64,)

output_state(::Primer, (; x)) = (q = x.q,)
state_derivative(::Primer, (; x)) = (q = one(x.q),)
state_projection(c::Primer, x) = x.q ≥ c.level ? throw(Detonated()) : (q = x.q,)

"""
Interrupter: `q̇ = 1` whose RHS raises an `InterruptException` when armed — the
operator's stop reaching §13.4's catch site, which is the only way to exercise
the carve-out with §12.4's masking absent.
"""
struct Interrupter <: AbstractComponent end

init_x(::Interrupter) = (q = 0.0,)
input_types(::Interrupter) = (arm = Bool,)
output_types(::Interrupter) = (q = Float64,)

output_state(::Interrupter, (; x)) = (q = x.q,)
state_derivative(::Interrupter, (; x, u)) = u.arm ? throw(InterruptException()) : (q = one(x.q),)

"""
Diverger: `q̇ = 1` until armed, then `q̇ = NaN` — the model that blows up. Its
`state_projection` refuses a nonfinite `q`, so a sweep running later than the integrate
would be beaten by the projection; the declared default `q = 0` passes it, which
is what the build probe needs.
"""
struct Diverger <: AbstractComponent end

init_x(::Diverger) = (q = 0.0,)
input_types(::Diverger) = (arm = Bool,)
output_types(::Diverger) = (q = Float64,)

output_state(::Diverger, (; x)) = (q = x.q,)
state_derivative(::Diverger, (; u)) = (q = u.arm ? NaN : 1.0,)
state_projection(::Diverger, x) = isfinite(x.q) ? x : throw(DomainError(x.q, "diverged"))

"""
Consumer: the innocent component downstream of a `Diverger`. Its stage-2 port
computes `sqrt` of its input, the lookup a diverged upstream would surface a
`DomainError` from — the error-locality inversion §13.4's sweep placement
exists to prevent. Its own state never diverges, so the sweep has one owner to
name.
"""
struct Consumer <: AbstractComponent end

init_x(::Consumer) = (p = 0.0,)
input_types(::Consumer) = (in = Float64,)
output_types(::Consumer) = (r = Float64,)

output_direct(::Consumer, (; u)) = (r = sqrt(u.in),)
state_derivative(::Consumer, (; x)) = (p = zero(x.p),)

"""
LateDiverger: a `Bouncer` that diverges only *after* its own reset. The
sign-form guard localizes the crossing, the handler latches `blown`, and the
remainder segment from `t*` to the frame top integrates `q̇ = NaN` — the
nonfinite state a sweep placed at the frame loop rather than at the seam would
miss.
"""
struct LateDiverger <: AbstractComponent
    rate::Float64
    level::Float64
end

init_x(::LateDiverger) = (q = 0.0,)
init_m(::LateDiverger) = (blown = false,)
output_types(::LateDiverger) = (q = Float64,)

output_state(::LateDiverger, (; x)) = (q = x.q,)
state_derivative(c::LateDiverger, (; m)) = (q = m.blown ? NaN : c.rate,)

late_diverger_guard(c::LateDiverger, (; x)) = x.q - c.level
late_diverger_handler(::LateDiverger, (; m)) = (m = (blown = true,),)
state_events(::LateDiverger) = (blow = StateEvent(late_diverger_guard, late_diverger_handler),)

# --- the algebraic-cycle coverage set (§5.5, §5.6) ----------------------------
# What the feedthrough tracer has to tell apart: a hop stage 2 does not route, a
# declaration no tracer scalar can enter, and a member whose evaluation throws.

"""
Consumes `b` in `state_derivative` only: stage 2 routes `a` and not `b`, so a
loop closed through `b` is §5.4's last paragraph, artificial at port level.
"""
struct DerivativeFed <: AbstractComponent end

init_x(::DerivativeFed) = (q = 0.0,)
input_types(::DerivativeFed) = (a = Float64, b = Float64)
output_types(::DerivativeFed) = (y = Float64,)
output_direct(::DerivativeFed, (; u)) = (y = 2u.a,)
state_derivative(::DerivativeFed, (; u)) = (q = u.b,)

"""`Gain` with both ends pinned `Float64`: no tracer scalar can enter, so its hops trace structurally."""
struct PinnedGain <: AbstractComponent end

init_x(::PinnedGain) = (;)
input_types(::PinnedGain) = (e = Pinned{Float64},)
output_types(::PinnedGain) = (out = Pinned{Float64},)
output_direct(::PinnedGain, (; u)) = (out = 2u.e,)

"""`Gain` asserting its return `Float64`: fine at the nominal probe, a throw at any other scalar."""
struct TypedGain <: AbstractComponent end

init_x(::TypedGain) = (;)
input_types(::TypedGain) = (e = Float64,)
output_types(::TypedGain) = (out = Float64,)
output_direct(::TypedGain, (; u)) = (out = (2u.e)::Float64,)

"""
A branch on an input, whose subject the arithmetic routes as well: the global
tracer refuses the branch and the sampled one reports the paths it took. `f` is
routed on both arms and `v` on the arm the branch takes, `g` on neither, so a
loop through `v` or through `f` is real and one through `g` artificial, all
found by sampling.
"""
struct Piecewise <: AbstractComponent end

init_x(::Piecewise) = (q = 0.0,)
input_types(::Piecewise) = (v = Float64, f = Float64, g = Float64)
output_types(::Piecewise) = (F = Float64,)
output_direct(::Piecewise, (; u)) = (F = u.v > 0 ? u.f + u.v : -u.f,)
state_derivative(::Piecewise, (; u)) = (q = u.g,)

# --- the reference models -----------------------------------------------------

"""
    feedback_model(; k, feedback_port = "y")

Closed loop as a `Group`: `sum` differences the `"ref"` input face against the
plant's feedback port, `ctl` scales the error, the plant integrates it. `"y"` is
its one output face.

The default `feedback_port = "y"` closes the loop through the plant's *stage-1*
port, which carries no input dependence — so the loop is legal and the schedule
is `sum → ctl → plant`. Passing `"power"` closes it through a stage-2 port
instead, which is a genuine algebraic loop and must be rejected at build time
(§5.5).
"""
function feedback_model(; k = 4.0, ω = 2.0, ζ = 0.1, q₀ = SVector(0.0, 0.0),
                        feedback_port::String = "y")
    Group((plant = Plant(; ω, ζ, q₀), ctl = Gain(k), sum = Sum());
          wires = ("ctl/out" => "plant/u",
                   "sum/e" => "ctl/e",
                   "plant/$feedback_port" => "sum/b"),
          # `sum.a` is claimed by no wire: the obligation is handed up to this
          # face, and at the root a face is a root input — its cell seeded by
          # `probe_value` for the build's own probes, and its initial value
          # authored by the init service's condition (§6.1, §11.3, §14.6).
          inputs = "ref" => "sum/a",
          outputs = "plant/y" => "y")
end

"""
    vector_feedback_model(; k)

The same closed loop through a **stage-1 port**, an `SVector` one: `VectorPlant`
returns its whole state vector from `output_state`, `StateFeedback` reads it and
feeds the plant back. A stage-1 port carries no input dependence, so the loop
adds no edge and is legal (§5.3, §5.5).

With `ref = 0` this is `feedback_model(; k)`'s loop with `Sum` and `Gain` fused,
so the two trajectories agree step for step.
"""
vector_feedback_model(; k = 4.0, ω = 2.0, ζ = 0.1, q₀ = SVector(0.0, 0.0)) =
    Group((plant = VectorPlant(; ω, ζ, q₀), fb = StateFeedback(k));
          wires = ("plant/q" => "fb/q", "fb/u" => "plant/u"),
          outputs = ("plant/q" => "q",))

"""
    sampled_loop(; kI, ω, ζ)

The sampled-data closed loop: a continuous plant under a discrete integrator's
zero-order-held command. `sum` differences the `"ref"` face against the plant's
stage-1 port, the discrete `ctl` accumulates that error at its own tick and holds
`u` between ticks, and the plant integrates it.

Its two output faces are the mixed-tier pair: `"y"` sourced from the continuous
plant, `"cmd"` from the discrete controller (§8.6 — an assembly is tier-neutral,
and a face's type and tier are its internal endpoint's).

The hold is not implemented anywhere: `ctl`'s entries are absent from the
interior sweep, so its cell simply cannot change between boundaries (§10.5).
"""
function sampled_loop(; kI = 3.0, ω = 2.0, ζ = 0.1)
    Group((plant = Plant(; ω, ζ), ctl = DiscreteIntegrator(kI), sum = Sum());
          wires = ("ctl/u" => "plant/u",
                   "sum/e" => "ctl/e",
                   "plant/y" => "sum/b"),
          inputs = "ref" => "sum/a",
          outputs = ("plant/y" => "y", "ctl/u" => "cmd"))
end

# --- the named two-level assembly ---------------------------------------------
# Class by declaration shape (§8.5): `child_connections` and nothing else, on a
# plain struct whose component-typed fields are its children.

"""
The sampled loop as a *named* assembly, holding its three children in concretely
declared fields. An ancestor reaches none of them: every signal leaving this
level does so through a face declared here (§6.1, D-207), which is why the
plant's `power` port is re-exported below beside `y` and `cmd`.

`ctl_rate` is §10.5's exposed-multiplier idiom: a deployment preference surfaces
as a constructor parameter, the declaration stays the assembly's own
`sample_times`, and the component type stays rate-agnostic — `ctl` reads its
period from its bundle's `Δt` and nowhere else.
"""
struct SampledLoop <: AbstractComponent
    plant::Plant
    ctl::DiscreteIntegrator
    sum::Sum
    ctl_rate::Relative           # inert parameter data, read by `sample_times`
end

SampledLoop(; kI = 3.0, ω = 2.0, ζ = 0.1, ctl_rate = Relative(1)) =
    SampledLoop(Plant(; ω, ζ), DiscreteIntegrator(kI), Sum(), ctl_rate)

child_connections(::SampledLoop) =
    ("ctl/u" => "plant/u", "sum/e" => "ctl/e", "plant/y" => "sum/b")
input_connections(::SampledLoop) = ("ref" => "sum/a",)
output_connections(::SampledLoop) =
    ("plant/y" => "y", "ctl/u" => "cmd", "plant/power" => "power")
sample_times(l::SampledLoop) = (ctl = l.ctl_rate,)

"""
    Vehicle(; k, kI, ω, ζ)

Two levels: the vehicle scales its own `"ref"` face and hands the product to the
loop's input face, and re-exports three of the loop's signals — each through the
loop's own face, one level at a time, the plant's `power` having acquired a face
on the loop's boundary to be re-exported through (§6.1, D-207).

Its faces are the mixed-tier set: `"y"` derives from the continuous plant, `"cmd"`
from the discrete controller, and neither is declared anywhere — a face's type and
tier are its ultimate internal endpoint's (§8.6).
"""
struct Vehicle <: AbstractComponent
    loop::SampledLoop
    trim::Gain
end

Vehicle(; k = 1.0, kI = 3.0, ω = 2.0, ζ = 0.1) = Vehicle(SampledLoop(; kI, ω, ζ), Gain(k))

child_connections(::Vehicle) = ("trim/out" => "loop/ref",)
input_connections(::Vehicle) = ("ref" => "trim/e",)
output_connections(::Vehicle) =
    ("loop/y" => "y", "loop/cmd" => "cmd", "loop/power" => "power")

"""A primitive that also holds a component, a field the flatten pass never descends into (§8.5)."""
struct OpaqueLeaf <: AbstractComponent
    hidden::Gain
end

init_x(::OpaqueLeaf) = (z = 0.0,)
state_derivative(::OpaqueLeaf, (; x)) = (z = -x.z,)

"""One `OpaqueLeaf` in a concretely declared field, so a path reaches the primitive with a segment to spare (§13.3)."""
struct OpaqueHold <: AbstractComponent
    c::OpaqueLeaf
end

child_connections(::OpaqueHold) = ()

# --- the fragment-function idiom (§14.2) ----------------------------------------
# Methods of the framework's `condition` generic, one per component, shipped
# beside it. What the idiom buys is locality — the caller says "start the plant
# at this displacement", and only `Plant` knows displacement and rate pack into
# `q` — composed by *pull* from the structure's owner, never by a schema routing
# sub-specs down the tree (D-064).

"""The plant's own vocabulary: displacement and rate, which it packs into `q`."""
condition(::Plant; y = 0.0, v = 0.0) = fragment(x = (q = SVector(y, v),))

"""The integrator's: the held command, which it accumulates in `acc`."""
condition(::DiscreteIntegrator; cmd = 0.0) = fragment(s = (acc = cmd,))

"""
Composition by pull (§14.2): the owner of the structure names its children and
scopes their fragments with `at`, and `combine` collects the siblings. It
authors no root input — `ref` is this assembly's *input face*, which is a root
input only when `SampledLoop` is itself the root, so the level that knows is
the one that owns the boundary.
"""
condition(l::SampledLoop; y = 0.0, v = 0.0, cmd = 0.0) =
    combine(at("plant", condition(l.plant; y, v)), at("ctl", condition(l.ctl; cmd)))

"""
The second level, and the one that owns the root boundary: it pulls the loop's
fragment under `at("loop", …)` — deep paths are compiled derivatives of this
nesting, never written by hand — and authors the root input its own contract
declares.
"""
condition(vehicle::Vehicle; ref = 0.0, kw...) =
    combine(at("loop", condition(vehicle.loop; kw...)), fragment(inputs = (ref = ref,)))

# --- the multi-rate coverage set (§10.5) ----------------------------------------

"""
Zero-order hold: a stateless discrete pass-through. Its one cell takes a fresh
sample at its own ticks and holds in between, so the tick pattern and the
deterministic aging of a stagger are directly observable through cell reads.
"""
struct ZOH <: AbstractComponent end

init_s(::ZOH) = (;)
input_types(::ZOH) = (in = Float64,)
output_types(::ZOH) = (out = Float64,)
output_direct(::ZOH, (; u)) = (out = u.in,)

"""Affine clock publisher: continuous, stateless, stage 1 — `out = c₀ + t`."""
struct Ramp <: AbstractComponent
    c₀::Float64
end

init_x(::Ramp) = (;)
output_types(::Ramp) = (out = Float64,)
output_state(c::Ramp, (; t)) = (out = c.c₀ + t,)

"""
The rate scope of the spec's worked example (§9.2, §10.5): `inner` at the scope
base, `outer` staggered at `Relative(5, 2)`. `outer` samples a signal handed in
through the `g` face, so what it reads between that producer's ticks is the ZOH
aging the example computes.
"""
struct FCS <: AbstractComponent
    inner::ZOH
    outer::ZOH
end

child_connections(::FCS) = ()
input_connections(::FCS) = ("in" => "inner/in", "g" => "outer/in")
output_connections(::FCS) = ("inner/out" => "y_inner", "outer/out" => "y_outer")
sample_times(::FCS) = (inner = Relative(1), outer = Relative(5, 2))

"""
    MultiRate()

The §9.2 worked example: three discrete components under two scopes, `fcs` on
the root grid and `gnss` anchored at `Hz(50)`. Deployed at `Δt_base = 2 ms` the
compiled pairs are inner `(1, 0)`, outer `(5, 2)`, gnss `(10, 0)`, and one
hyperperiod is `lcm(Dᵢ) = 10` base ticks. The ramp source makes every sample
carry its own acquisition time, so the chart's dots — and the stagger's aging —
are readable off the cells.
"""
struct MultiRate <: AbstractComponent
    src::Ramp
    fcs::FCS
    gnss::ZOH
end

MultiRate(; c₀ = 1.0) = MultiRate(Ramp(c₀), FCS(ZOH(), ZOH()), ZOH())

child_connections(::MultiRate) =
    ("src/out" => "fcs/in", "src/out" => "gnss/in", "gnss/out" => "fcs/g")
output_connections(::MultiRate) =
    ("fcs/y_inner" => "inner", "fcs/y_outer" => "outer", "gnss/out" => "gnss")
sample_times(::MultiRate) = (fcs = Relative(1), gnss = Absolute(Hz(50)))

# --- the field-handle coverage set (§4.4, D-237) --------------------------------
# The handle pattern: an immutable struct combining isbits parameters with a
# reference to bulk data, frozen at build time. Not isbits, so the leaf walk
# stops there and the table stores the handle whole, references included.

"""One stable face over several concrete field types (§4.4, §8.2)."""
abstract type AbstractTerrain end

"""
A terrain handle: a `2×2` heightmap behind an immutable struct, beside the
isbits parameter that scales it. The one opaque leaf of D-237.
"""
struct HeightField <: AbstractTerrain
    z::Matrix{Float64}
    h0::Float64
end

"""
The field-emitting component (§4.4). It owns its resource loading, so the
heightmap is built once, at construction, and frozen on the instance; the swept
output stage rebuilds only the immutable struct around that existing reference,
which is what makes the rebuild allocation-free.
"""
struct Terrain <: AbstractComponent
    z::Matrix{Float64}
    h0::Float64
end

Terrain(; h0 = 1.0) = Terrain(fill(h0, 2, 2), h0)

"""
§4.4's value-level constructor: the map (component, input values) → handle,
plain, pure and public, so condition math can build the same handle outside any
sweep. `Terrain` takes no inputs, so the component is the whole domain.
"""
height_field(c::Terrain) = HeightField(c.z, c.h0)

init_s(::Terrain) = (;)
output_types(::Terrain) = (terrain = HeightField,)
output_direct(c::Terrain, args) = (terrain = height_field(c),)

"""The consumer: it evaluates the handle inside its own stage, at its own arguments."""
struct Query <: AbstractComponent end

init_x(::Query) = (;)
input_types(::Query) = (terrain = HeightField,)
output_types(::Query) = (h = Float64,)
output_direct(::Query, (; u)) = (h = u.terrain.h0 + size(u.terrain.z, 1),)

"""The same consumer behind an abstract entry: structural substitutability (§8.2)."""
struct AbstractTerrainQuery <: AbstractComponent end

init_x(::AbstractTerrainQuery) = (;)
input_types(::AbstractTerrainQuery) = (terrain = AbstractTerrain,)
output_types(::AbstractTerrainQuery) = (h = Float64,)
output_direct(::AbstractTerrainQuery, (; u)) = (h = u.terrain.h0 + size(u.terrain.z, 1),)

"""A mutable cache where a handle belongs — the refusal D-237 owes (§4.4)."""
mutable struct Cache
    n::Float64
end

struct MutableSource <: AbstractComponent end

init_s(::MutableSource) = (;)
output_types(::MutableSource) = (c = Cache,)
output_direct(::MutableSource, args) = (c = Cache(0.0),)

"""A mutable array declared as an entry, to surface as a root input."""
struct MatrixEntry <: AbstractComponent end

init_x(::MatrixEntry) = (;)
input_types(::MatrixEntry) = (m = Matrix{Float64},)
output_types(::MatrixEntry) = (n = Float64,)
output_direct(::MatrixEntry, (; u)) = (n = float(length(u.m)),)

"""The reference handle model: one field emitter wired into one consumer."""
handle_model() = Group((; src = Terrain(), q = Query());
                       wires = ("src/terrain" => "q/terrain",))

"""
A handle carrying `T` among its isbits parameters (D-237): its cell is a
different type per activation, and the emitter must build it at `T`.
"""
struct OffsetField{T}
    h0::T
    z::Matrix{Float64}
end

"""Builds the handle from the clock, so at `T` (D-237's lawful emitter)."""
struct OffsetAtT <: AbstractComponent
    z::Matrix{Float64}
end
OffsetAtT() = OffsetAtT(zeros(2, 2))

init_x(::OffsetAtT) = (;)
output_types(::OffsetAtT) = (terrain = OffsetField{Float64},)
output_direct(c::OffsetAtT, (; t)) = (terrain = OffsetField(t + 1.0, c.z),)

"""Builds the handle from a literal: a `Float64` handle at every activation."""
struct OffsetAtLiteral <: AbstractComponent
    z::Matrix{Float64}
end
OffsetAtLiteral() = OffsetAtLiteral(zeros(2, 2))

init_x(::OffsetAtLiteral) = (;)
output_types(::OffsetAtLiteral) = (terrain = OffsetField{Float64},)
output_direct(c::OffsetAtLiteral, (; t)) = (terrain = OffsetField(1.0, c.z),)

"""The same handle from build-time data, declared frozen (D-264's admitted producer)."""
struct PinnedOffsetSource <: AbstractComponent
    z::Matrix{Float64}
end
PinnedOffsetSource() = PinnedOffsetSource(zeros(2, 2))

init_x(::PinnedOffsetSource) = (;)
output_types(::PinnedOffsetSource) = (terrain = Pinned{OffsetField{Float64}},)
output_direct(c::PinnedOffsetSource, (; t)) = (terrain = OffsetField(1.0, c.z),)

"""The same handle from a discrete producer, which pins wholesale with no marker."""
struct DiscreteOffsetSource <: AbstractComponent
    z::Matrix{Float64}
end
DiscreteOffsetSource() = DiscreteOffsetSource(zeros(2, 2))

init_s(::DiscreteOffsetSource) = (;)
output_types(::DiscreteOffsetSource) = (terrain = OffsetField{Float64},)
output_direct(c::DiscreteOffsetSource, (; t)) = (terrain = OffsetField(1.0, c.z),)

struct OffsetQuery <: AbstractComponent end

init_x(::OffsetQuery) = (;)
input_types(::OffsetQuery) = (terrain = OffsetField{Float64},)
output_types(::OffsetQuery) = (h = Float64,)
output_direct(::OffsetQuery, (; u)) = (h = 2 * u.terrain.h0,)

offset_model(src) = Group((; src = src, q = OffsetQuery());
                          wires = ("src/terrain" => "q/terrain",))

"""Pins the handle entry, so a walking handle producer fails the walk clause."""
struct PinnedOffsetQuery <: AbstractComponent end

init_x(::PinnedOffsetQuery) = (;)
input_types(::PinnedOffsetQuery) = (terrain = Pinned{OffsetField{Float64}},)
output_types(::PinnedOffsetQuery) = (h = Float64,)
output_direct(::PinnedOffsetQuery, (; u)) = (h = 2 * u.terrain.h0,)

# --- the label port coverage set (§4.1, §4.3, §8.2, §9.3) -----------------------
# An enum is a port value (§4.1) and a pinned leaf (§8.2): one leaf of its own
# eltype, stored whole, never following the activation scalar. Its probe value
# is the first instance (§9.3, D-051). A `Symbol` is an opaque leaf (D-243):
# stored whole too, and with no synthesis, so it is refused at a root input.

@enum Gear up = 1 down = 2

"""A discrete producer of an enum port: the cell's eltype is `Gear` itself."""
struct GearSelector <: AbstractComponent end

init_s(::GearSelector) = (n = 0,)
output_types(::GearSelector) = (gear = Gear,)

output_state(::GearSelector, (; s)) = (gear = iseven(s.n) ? up : down,)
state_update(::GearSelector, (; s)) = (n = s.n + 1,)

"""
A struct port with an enum leaf beside a walking one, returned from literals:
the constant-branch idiom at a mixed-leaf port, which embeds leaf by leaf at
a non-nominal activation (D-166).
"""
struct GearState{T}
    h::T
    gear::Gear
end

struct GearStateSource <: AbstractComponent end

init_x(::GearStateSource) = (;)
output_types(::GearStateSource) = (gs = GearState{Float64},)
output_direct(::GearStateSource, (; t)) = (gs = GearState(1.0, down),)

"""
A consumer declaring an enum entry beside a `T` one: the enum pins, the real
walks. `code` republishes the enum as its `Int`, which is what a test reads to
tell which instance arrived.
"""
struct GearReader <: AbstractComponent end

init_x(::GearReader) = (;)
input_types(::GearReader) = (gear = Gear, x = Float64)
output_types(::GearReader) = (drag = Float64, code = Int)

output_direct(::GearReader, (; u)) = (drag = u.gear === down ? 2 * u.x : u.x,
                                      code = Int(u.gear))

"""
An enum mode declared public and returned from stage 1: §7.5's remedy for the
missing event stream is declaring the mode field public, which the return
delivers.
"""
struct GearMode <: AbstractComponent end

init_m(::GearMode) = (gear = up,)
init_x(::GearMode) = (;)
output_types(::GearMode) = (gear = Gear, y = Float64)

output_state(::GearMode, (; m)) = (gear = m.gear, y = m.gear === up ? 0.0 : 1.0)

"""A discrete producer of a `Symbol` port, the idiomatic label of §7.3."""
struct PhaseSelector <: AbstractComponent end

init_s(::PhaseSelector) = (n = 0,)
output_types(::PhaseSelector) = (phase = Symbol,)

output_state(::PhaseSelector, (; s)) = (phase = iseven(s.n) ? :idle : :armed,)
state_update(::PhaseSelector, (; s)) = (n = s.n + 1,)

"""A consumer of a `Symbol` entry; alone under a root, that entry is a root input."""
struct PhaseReader <: AbstractComponent end

init_x(::PhaseReader) = (;)
input_types(::PhaseReader) = (phase = Symbol,)
output_types(::PhaseReader) = (armed = Bool,)

output_direct(::PhaseReader, (; u)) = (armed = u.phase === :armed,)

"""
A `Symbol` mode declared public and returned from stage 1: §7.5's remedy on the
idiomatic label.
"""
struct PhaseMode <: AbstractComponent end

init_m(::PhaseMode) = (phase = :idle,)
init_x(::PhaseMode) = (;)
output_types(::PhaseMode) = (phase = Symbol, y = Float64)

output_state(::PhaseMode, (; m)) = (phase = m.phase, y = m.phase === :idle ? 0.0 : 1.0)

# --- the periphery's coverage set: devices and bindings (§11.3, §11.6) ----------

"""
    Pad(name)

A stub device: no hardware — the identity carrier for the roster. Mutable
deliberately, because identity is the instance (`===`, §11.3): an immutable
stub with equal fields would be egal to its twin, and two same-named `Pad`s
are meant to be two devices. Its loop body returns at once — §12.4(6)'s
voluntary exit, honest for a stub with nothing to wait on — so a rostered
`Pad` in a run is an identity holding a claim, its task already departed and
its staging cell writable from any task through the handle.
"""
mutable struct Pad <: AbstractDevice
    name::String
end
loop(::Pad, handle) = nothing

"""
    Panel(name)

A stub device declaring the calling-task affinity (§11.6): at most one holder
per roster, the calling task being a single-slot resource (§11.1, §11.3).
Its loop body is `Pad`'s immediate voluntary return, run inline on the
calling task by the wrapper.
"""
mutable struct Panel <: AbstractDevice
    name::String
end
needs_calling_task(::Panel) = true
loop(::Panel, handle) = nothing

"""
    Enumerated(faces...)

The returned claim source (§11.3): an input-side binding whose `claims` names
exactly the faces it was built with — the enumeration is the interface, and
the empty enumeration is the honest may-write-nothing degenerate, not a back
door (§11.6).
"""
struct Enumerated <: AbstractBinding
    faces::Vector{String}
end
Enumerated(faces::AbstractString...) = Enumerated(collect(String, faces))
is_input(::Enumerated) = true
claims(b::Enumerated) = b.faces

"""
    Greedy()

The computed claim source (§11.3): `is_greedy` declared, no `claims` of its
own — the framework computes the unclaimed complement at the attach point,
the shipped GUI binding's shape (§11.6, §11.7).
"""
struct Greedy <: AbstractBinding end
is_input(::Greedy) = true
is_greedy(::Greedy) = true

"""
    Readout(; label = selector, ...)

The output side's coverage binding (§11.2, §11.6): `reads` names exactly the
labeled selectors it was built with — the enumeration is the interface — and
its `map_output` is the identity, the wire datum being the gather's
NamedTuple itself. A snapshot-consuming telemetry peer differs only in what
its own `map_output` does with the same NamedTuple.
"""
struct Readout{R<:NamedTuple} <: AbstractBinding
    r::R
end
Readout(; kw...) = Readout(NamedTuple(kw))
is_output(::Readout) = true
reads(b::Readout) = b.r
map_output(nt, ::Readout) = nt

# --- the trim coverage set (§14.7) ----------------------------------------------
# One nonlinear continuous component with a torque input, which is the smallest
# thing a trim problem can be posed on: a decision reaching it through a root
# input or through its own authored state, a residual read off `ẋ`, and a
# solution that is analytic in both directions (`u = g/l·sin θ` one way,
# `θ = asin(u·l/g)` the other, the box picking the branch).

"""Damped pendulum under a torque input: θ̈ = −(g/l)·sin θ − c·θ̇ + u."""
struct Pendulum <: AbstractComponent
    g_l::Float64
    c::Float64
end

Pendulum(; g_l = 9.81, c = 0.5) = Pendulum(g_l, c)

init_x(::Pendulum) = (θ = 0.0, ω = 0.0)
input_types(::Pendulum) = (u = Float64,)
output_types(::Pendulum) = (θ = Float64, ω = Float64)

output_state(::Pendulum, (; x)) = (θ = x.θ, ω = x.ω)
state_derivative(c::Pendulum, (; x, u)) = (θ = x.ω, ω = -c.g_l * sin(x.θ) - c.c * x.ω + u.u)

"""The pendulum's own vocabulary, in the fragment-function idiom (§14.2)."""
condition(::Pendulum; θ = 0.0, ω = 0.0) = fragment(x = (θ = θ, ω = ω))

"""A component that ships no fragment function: the owner's pull fails on it by name."""
struct Voiceless <: AbstractComponent end
init_x(::Voiceless) = (; a = 0.0)
state_derivative(::Voiceless, (; x)) = (; a = 0.0)

# --- the forgotten-import fixtures (§8.1, D-246) --------------------------------

"""
The forgotten-import fixtures (§8.1, D-246), one module per case because the
check reads the module: every bare definition below lands on a function of its
own module, which is the mistake `DeclarationShadowed` names. Qualified
`Cadence.f(…)` definitions are the ones that reach the framework.
"""
module ForgottenImport

"Every declaration bare: the whole inventory shadowed."
module Inventory
using Cadence
struct Leaf <: Cadence.AbstractComponent end
init_x(::Leaf) = (q = 0.0,)
output_types(::Leaf) = (y = Float64,)
output_state(::Leaf, (; x)) = (y = x.q,)
state_derivative(::Leaf, (; x)) = (q = -x.q,)
end

"A sound leaf whose update alone is bare: would have read as `StoreWithoutUpdate`."
module Update
using Cadence
struct Leaf <: Cadence.AbstractComponent end
Cadence.init_x(::Leaf) = (q = 0.0,)
Cadence.output_types(::Leaf) = (y = Float64,)
Cadence.output_state(::Leaf, (; x)) = (y = x.q,)
state_derivative(::Leaf, (; x)) = (q = -x.q,)
end

"A sound leaf whose events alone are bare: builds today with no events."
module Events
using Cadence
struct Leaf <: Cadence.AbstractComponent end
Cadence.init_x(::Leaf) = (q = 1.0,)
Cadence.output_types(::Leaf) = (y = Float64,)
Cadence.output_state(::Leaf, (; x)) = (y = x.q,)
Cadence.state_derivative(::Leaf, (; x)) = (q = -x.q,)
state_events(::Leaf) = (;)
end

"A sound assembly whose rate declaration alone is bare: builds today on the parent's grid."
module Rates
using Cadence
struct Leaf <: Cadence.AbstractComponent end
Cadence.init_x(::Leaf) = (q = 1.0,)
Cadence.output_types(::Leaf) = (y = Float64,)
Cadence.output_state(::Leaf, (; x)) = (y = x.q,)
Cadence.state_derivative(::Leaf, (; x)) = (q = -x.q,)
struct Assembly <: Cadence.AbstractComponent
    kid::Leaf
end
Cadence.child_connections(::Assembly) = ()
sample_times(::Assembly) = (kid = Cadence.Relative(2),)
end

end

"""
A sound assembly whose boundary is computed over a shadowed child (§8.8):
`input_passthrough` classifies the child it names, so the parent's own
declarations must not be read before the child is walked (D-246).
"""
struct PassthroughOverForgotten <: AbstractComponent
    kid::ForgottenImport.Inventory.Leaf
end
child_connections(::PassthroughOverForgotten) = ()
input_connections(a::PassthroughOverForgotten) = input_passthrough(a, "kid")
