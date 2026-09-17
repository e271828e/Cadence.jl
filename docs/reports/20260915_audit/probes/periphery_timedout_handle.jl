include(joinpath(@__DIR__, "..", "..", "..", "..", "test", "CadenceTests.jl"))

const CT = Main.CadenceTests
const C = CT.Cadence

mutable struct LateAction <: C.AbstractDevice
    release::Channel{Nothing}
    done::Channel{Nothing}
    action::Symbol
end

LateAction(action) = LateAction(Channel{Nothing}(1), Channel{Nothing}(1), action)

function C.loop(d::LateAction, h)
    take!(d.release)
    if d.action === :stage
        C.stage!(h, "a" => 77.0)
    else
        C.stop!(h)
    end
    put!(d.done, nothing)
    nothing
end

function timed_out(action)
    sim = CT.Simulation(CT.two_root_inputs(); h = 1 // 10, join_timeout = 0.02)
    dev = LateAction(action)
    C.attach!(sim, dev, CT.Enumerated("a"))
    CT.init!(sim, CT.fragment(inputs = (a = 0.0, b = 0.0)))
    CT.run!(sim; t_end = 0.1)
    return sim, dev
end

# A task abandoned by the first run stages after the second trajectory's init!.
# step! is specified as deviceless, but it drains the old task's retained handle.
stage_sim, stage_dev = timed_out(:stage)
CT.init!(stage_sim, CT.fragment(inputs = (a = 0.0, b = 0.0)))
put!(stage_dev.release, nothing)
take!(stage_dev.done)
advanced = CT.step!(stage_sim)
stage_a = CT.port(stage_sim, "", :a)
println("late stage: advanced=$advanced, a=$stage_a, " *
        "lifecycle=$(CT.lifecycle(stage_sim))")

# The same retained handle can issue the next trajectory's control stop. The
# following deviceless step terminates without advancing and attributes the stop to
# a device task belonging to the previous run.
stop_sim, stop_dev = timed_out(:stop)
CT.init!(stop_sim, CT.fragment(inputs = (a = 0.0, b = 0.0)))
put!(stop_dev.release, nothing)
take!(stop_dev.done)
advanced = CT.step!(stop_sim)
println("late stop: advanced=$advanced, lifecycle=$(CT.lifecycle(stop_sim)), " *
        "source=$(CT.termination(stop_sim).source)")
