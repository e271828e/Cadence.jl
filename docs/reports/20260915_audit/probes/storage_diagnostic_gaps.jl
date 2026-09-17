using Cadence
import Cadence: AbstractComponent, Group, build, input_types, output_state, output_types

capture(f) = try
    f()
    nothing
catch e
    e
end

# D-051 requires the first enum instance as the framework probe value.
@enum ProbeChoice choice_a choice_b
struct EnumConsumer <: AbstractComponent end
input_types(::EnumConsumer, ::Type{T}) where {T <: Real} = (u = ProbeChoice,)
output_types(::EnumConsumer, ::Type{T}) where {T <: Real} = (out = T,)
output_state(::EnumConsumer, (; t)) = (out = t,)

enum_world = Group((; c = EnumConsumer()); inputs = ("choice" => "c/u",))
enum_err = capture(() -> build(enum_world))
@assert enum_err isa Cadence.DiagnosticError
enum_diag = only(Cadence.diagnostics(enum_err))
@assert enum_diag isa Cadence.IllegalPortType
@assert enum_diag.reason === :no_leaves
println("enum probe synthesis was rejected first as IllegalPortType(:no_leaves)")

# A concrete immutable root-input type with no zero-argument constructor must
# produce MissingProbeValue, naming its face and type.
struct NoDefault
    value::Int
end
struct NoDefaultConsumer <: AbstractComponent end
input_types(::NoDefaultConsumer, ::Type{T}) where {T <: Real} = (u = NoDefault,)
output_types(::NoDefaultConsumer, ::Type{T}) where {T <: Real} = (out = T,)
output_state(::NoDefaultConsumer, (; t)) = (out = t,)

default_world = Group((; c = NoDefaultConsumer()); inputs = ("item" => "c/u",))
default_err = capture(() -> build(default_world))
@assert default_err isa MethodError
println("missing probe value raised raw MethodError")

# A declared stage returning bare NamedTuple() is the specified DeadStage error.
struct EmptyStage <: AbstractComponent end
output_types(::EmptyStage, ::Type{T}) where {T <: Real} = NamedTuple()
output_state(::EmptyStage, (; t)) = NamedTuple()

empty_result = capture(() -> build(Group((; c = EmptyStage()))))
@assert empty_result === nothing
println("empty stage built successfully")

# Probe-time user exceptions must be framed as UserCodeFraming diagnostics.
struct ThrowingStage <: AbstractComponent end
output_types(::ThrowingStage, ::Type{T}) where {T <: Real} = (out = T,)
output_state(::ThrowingStage, (; t)) = throw(ArgumentError("probe boom"))

throw_err = capture(() -> build(Group((; c = ThrowingStage()))))
@assert throw_err isa ArgumentError
println("probe user exception escaped unframed")

# A user stage requesting a bundle field outside its legal family should be
# translated to BundleFieldError at the probe seam.
struct BadBundleStage <: AbstractComponent end
output_types(::BadBundleStage, ::Type{T}) where {T <: Real} = (out = T,)
output_state(::BadBundleStage, (; imaginary)) = (out = imaginary,)

bundle_err = capture(() -> build(Group((; c = BadBundleStage()))))
println("illegal bundle field exception type: ", typeof(bundle_err))
@assert !(bundle_err isa Cadence.DiagnosticError)

# The port contract refuses mutable types anywhere. BigInt is a mutable Julia
# Real, but the walker returns before consulting ismutabletype for every Real.
struct MutableRealStage <: AbstractComponent end
output_types(::MutableRealStage, ::Type{T}) where {T <: Real} = (out = BigInt,)
output_state(::MutableRealStage, (; t)) = (out = BigInt(1),)

@assert ismutabletype(BigInt)
@assert Cadence.mutable_position(BigInt) === nothing
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

alias_sim = Cadence.Simulation(Group((; c = AliasingRealStage())); h = 1//10)
Cadence.init!(alias_sim)
old_snapshot = Cadence.latest(alias_sim)
borrowed = Cadence.port(old_snapshot, "c", :out)
borrowed.value = 9.0
@assert Cadence.port(alias_sim, "c", :out).value == 9.0
@assert Cadence.port(old_snapshot, "c", :out).value == 9.0
println("mutating a snapshot mutable Real changed both the snapshot and live cell value")
