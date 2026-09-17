using Cadence
const C = Cadence

struct AuditStopAt <: C.AbstractComponent
    at::Float64
end
C.output_types(::AuditStopAt, ::Type{T}) where {T <: Real} = (stop = Bool,)
C.output_state(c::AuditStopAt, (; t)) = (stop = t >= c.at,)

function check_priority()
    for (label, at, ending, control) in
        (("boundary zero: control + face", 0.0, Inf, true),
         ("boundary zero: end time + face", 0.0, 0.0, false),
         ("frame one: end time + face", 0.1, 0.1, false))
        sim = C.Simulation(AuditStopAt(at); h = 1//10, t_end = ending,
                           stop_on = ("stop",))
        C.init!(sim)
        control && C.stop!(sim)
        frames = C.step!(sim)
        source = C.termination(sim).source
        println(label, ": frames=", frames, "; source=", source)
        @assert source isa C.ModelRequestedStop
    end
end
check_priority()
