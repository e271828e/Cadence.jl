using Cadence

import Cadence: AbstractComponent, DiagnosticError, build, child_connections,
    diagnostics, init_x, input_types, output_direct, output_state, output_types,
    state_derivative

function show_failure(label, f)
    try
        value = f()
        println(label, ": success => ", value)
    catch err
        ds = err isa DiagnosticError ? (err.carried isa Vector ? err.carried : [err.carried]) : ()
        kinds = typeof.(ds)
        println(label, ": ", typeof(err), " diagnostics=", kinds)
        if err isa DiagnosticError
            for diagnostic in ds
                hasproperty(diagnostic, :members) &&
                    println("  members=", getproperty(diagnostic, :members))
            end
        end
    end
end

# A state field declared as a public output is required to auto-publish.
struct AuditAutoPublished <: AbstractComponent end
init_x(::AuditAutoPublished) = (x = 1.0,)
output_types(::AuditAutoPublished, ::Type{T}) where {T <: Real} = (x = T,)
state_derivative(::AuditAutoPublished, (; x)) = (x = zero(x.x),)

# An explicitly present output stage that returns no ports is DeadStage.
struct AuditDeadStage <: AbstractComponent end
output_types(::AuditDeadStage, ::Type{T}) where {T <: Real} = (y = T,)
output_state(::AuditDeadStage, (; t)) = (;)
output_direct(::AuditDeadStage, (; t)) = (y = zero(t),)

# The SCC is {a,b}; c is an innocent downstream consumer in Kahn's stall residue.
struct AuditNode <: AbstractComponent end
input_types(::AuditNode, ::Type{T}) where {T <: Real} = (u = T,)
output_types(::AuditNode, ::Type{T}) where {T <: Real} = (y = T,)
output_direct(::AuditNode, (; u)) = (y = u.u,)

struct AuditCycleTail <: AbstractComponent
    a::AuditNode
    b::AuditNode
    c::AuditNode
end
child_connections(::AuditCycleTail) =
    ("a/y" => "b/u", "b/y" => "a/u", "a/y" => "c/u")

# Containers of containers are rejected by §8.5, rather than treated as inert.
struct AuditNestedContainer <: AbstractComponent
    nested::Tuple
end
child_connections(::AuditNestedContainer) = ()

# A missing bundle field is required to become BundleFieldError.
struct AuditBundleMiss <: AbstractComponent end
output_types(::AuditBundleMiss, ::Type{T}) where {T <: Real} = (y = T,)
output_state(::AuditBundleMiss, (; x)) = (y = x.x,)

# The fallback P() fails, which is required to become MissingProbeValue.
struct AuditNoDefault
    x::Float64
    AuditNoDefault(x::Float64, ::Val{:ok}) = new(x)
end
struct AuditMissingProbe <: AbstractComponent end
input_types(::AuditMissingProbe, ::Type{T}) where {T <: Real} = (u = AuditNoDefault,)
output_types(::AuditMissingProbe, ::Type{T}) where {T <: Real} = (y = T,)
output_direct(::AuditMissingProbe, (; u)) = (y = u.u.x,)

# Enums are expressly admitted as pinned port leaves by §8.2.
@enum AuditMode audit_off audit_on
struct AuditEnumPort <: AbstractComponent end
output_types(::AuditEnumPort) = (mode = AuditMode,)
output_direct(::AuditEnumPort, (; t)) = (mode = audit_off,)

show_failure("auto-publication", () -> build(AuditAutoPublished()))
show_failure("dead stage", () -> build(AuditDeadStage()))
show_failure("cycle with downstream tail", () -> build(AuditCycleTail(AuditNode(), AuditNode(), AuditNode())))
show_failure("nested container", () -> build(AuditNestedContainer(((AuditDeadStage(),),))))
show_failure("bundle field framing", () -> build(AuditBundleMiss()))
show_failure("missing probe value", () -> build(AuditMissingProbe()))
show_failure("enum port", () -> build(AuditEnumPort()))
