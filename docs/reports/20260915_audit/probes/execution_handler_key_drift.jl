using Cadence
import Cadence: AbstractComponent, Group, Simulation, StateEvent,
    init!, init_m, output_state, output_types, run!, state_events

struct LateHandlerKey <: AbstractComponent end

init_m(::LateHandlerKey) = (fired = false,)
output_types(::LateHandlerKey, ::Type{T}) where {T <: Real} = (fired = Bool,)
output_state(::LateHandlerKey, (; m)) = (fired = m.fired,)

late_key_guard(::LateHandlerKey, (; t)) = t >= 0.1
late_key_handler(::LateHandlerKey, (; t)) =
    iszero(t) ? (m = (fired = true,),) : (unknown = true,)
state_events(::LateHandlerKey) =
    (fire = StateEvent(late_key_guard, late_key_handler),)

sim = Simulation(Group((; c = LateHandlerKey())); h = 1 // 10)
init!(sim)
run!(sim; t_end = 0.1)

@assert Cadence.modes(sim, "c") == (fired = false,)
println("unknown runtime handler key was silently ignored")

struct LateHandlerScalar <: AbstractComponent end

output_types(::LateHandlerScalar, ::Type{T}) where {T <: Real} = (seen = Bool,)
output_state(::LateHandlerScalar, (; t)) = (seen = t >= 0.1,)

late_scalar_guard(::LateHandlerScalar, (; t)) = t >= 0.1
late_scalar_handler(::LateHandlerScalar, (; t)) = iszero(t) ? NamedTuple() : 5
state_events(::LateHandlerScalar) =
    (fire = StateEvent(late_scalar_guard, late_scalar_handler),)

scalar_sim = Simulation(Group((; c = LateHandlerScalar())); h = 1 // 10)
init!(scalar_sim)
scalar_err = try
    run!(scalar_sim; t_end = 0.1)
    nothing
catch e
    e
end
@assert scalar_err isa Cadence.StepError
@assert scalar_err.cause isa MethodError
println("non-NamedTuple runtime handler return became raw MethodError cause")
