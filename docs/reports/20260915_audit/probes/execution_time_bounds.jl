using Redstone
import Redstone: Group, Simulation, init!, lifecycle, run!

# Minimal stateless clock publisher, local to the probe.
struct RedstoneTestsRamp <: Redstone.AbstractComponent
    c0::Float64
end
Redstone.output_types(::RedstoneTestsRamp, ::Type{T}) where {T <: Real} = (out = T,)
Redstone.output_state(c::RedstoneTestsRamp, (; t)) = (out = c.c0 + t,)

world = Group((; c = RedstoneTestsRamp(0.0)))

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
