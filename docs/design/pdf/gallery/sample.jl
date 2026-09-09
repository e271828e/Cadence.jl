# a continuous leaf: one bundle port, hot field loose
output_types(::Kinematics, ::Type{T}) where {T <: Real} =
    (pose = KinPose{T}, q_eb = RQuat{T})

function state_derivative(comp::Aircraft, args)
    y_x = output_state(comp, args)      # x, m, u, t
    ẋ = y_x.v * 2.5 + args.t
    isnan(ẋ) && return nothing
    @assert ẋ > 0 "bad $ẋ"
    return (; ẋ, w = 0.0)
end

struct KinPose{T <: Real}
    q::RQuat{T}
    alt::T
end
const N_BASE = 8
sim = Simulation(model; dt = 1//100, stop_on = :quiescence)
