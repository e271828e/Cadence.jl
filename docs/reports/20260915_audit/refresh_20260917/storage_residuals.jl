using Redstone
import Redstone: AbstractComponent, Group, build, output_types, output_state
capture(f) = try
    f()
    nothing
catch e
    e
end
# The port contract refuses mutable types anywhere. BigInt is a mutable Julia
# Real, but the walker returns before consulting ismutabletype for every Real.
struct MutableRealStage <: AbstractComponent end
output_types(::MutableRealStage, ::Type{T}) where {T <: Real} = (out = BigInt,)
output_state(::MutableRealStage, (; t)) = (out = BigInt(1),)

@assert ismutabletype(BigInt)
@assert Redstone.mutable_position(BigInt) === nothing
mutable_real_err = capture(() -> build(Group((; c = MutableRealStage()))))
@assert mutable_real_err === nothing
println("mutable Real port BigInt built successfully")

# The same bypass admits an ordinary mutable Real and exposes its identity from
# the cell: mutating a value returned by `port` mutates the live table entry.
mutable struct MutableScalar <: Real
    value::Float64
end
struct AliasingRealStage <: AbstractComponent end
output_types(::AliasingRealStage, ::Type{T}) where {T <: Real} = (out = MutableScalar,)
output_state(::AliasingRealStage, (; t)) = (out = MutableScalar(1.0),)

alias_sim = Redstone.Simulation(Group((; c = AliasingRealStage())); h = 1//10)
Redstone.init!(alias_sim)
old_snapshot = Redstone.latest(alias_sim)
borrowed = Redstone.port(old_snapshot, "c", :out)
borrowed.value = 9.0
@assert Redstone.port(alias_sim, "c", :out).value == 9.0
@assert Redstone.port(old_snapshot, "c", :out).value == 9.0
println("mutating a snapshot mutable Real changed both the snapshot and live cell value")

struct RefreshRootReal <: AbstractComponent end
Redstone.input_types(::RefreshRootReal, ::Type{T}) where {T <: Real} = (value = T,)
Redstone.output_types(::RefreshRootReal, ::Type{T}) where {T <: Real} = (out = T,)
Redstone.output_direct(::RefreshRootReal, (; u)) = (out = u.value,)
root_sim = Redstone.Simulation(Group((; c = RefreshRootReal()); inputs = ("root" => "c/value",)); h = 1//10)
@assert Redstone.lifecycle(root_sim) === :built
@assert Redstone.port(root_sim, "", :root) == 0.0
println("pre-init root input retains synthesized zero")
