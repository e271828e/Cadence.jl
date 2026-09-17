using Cadence
import Cadence: Group, Simulation, init!, lifecycle, run!

# Minimal stateless clock publisher, local to the probe.
struct CadenceTestsRamp <: Cadence.AbstractComponent
    c0::Float64
end
Cadence.output_types(::CadenceTestsRamp, ::Type{T}) where {T <: Real} = (out = T,)
Cadence.output_state(c::CadenceTestsRamp, (; t)) = (out = c.c0 + t,)

world = Group((; c = CadenceTestsRamp(0.0)))

converted = Simulation(world; h = 1 // 10, t_end = big"1e1000")
@assert isinf(converted.t_end)
println("finite BigFloat t_end converted to Inf")

sim = Simulation(world; h = 1 // 10)
init!(sim)
err = try
    run!(sim; t_end = 1e300)
    nothing
catch e
    e
end
@assert err isa InexactError
@assert lifecycle(sim) === :initialized
println("large finite Float64 t_end raised raw ", typeof(err))
