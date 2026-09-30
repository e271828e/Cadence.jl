# Loop-machinery compile on a fresh topology under three seams: the original
# inline PhaseBody, a @noinline wrapper (same type per topology, no inlining),
# and opaque-closure bodies (one type for every topology).
Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
using Base.Experimental: @opaque
import Cadence: PhaseBody, Executor, DataPlane, Control, Run, SnapshotLog, Establish
ct() = Base.cumulative_compile_time_ns()[1] / 1e9

mutable struct NIBody{B}; b::B; end
@noinline (x::NIBody)() = x.b()
@noinline (x::NIBody)(tick) = x.b(tick)

const OC0 = Core.OpaqueClosure{Tuple{}, Nothing}
const OC1 = Core.OpaqueClosure{Tuple{Int}, Nothing}
struct OCBody; zero::OC0; at::OC1; est::OC0; end
(x::OCBody)() = x.zero()
(x::OCBody)(tick::Int) = x.at(tick)
(x::OCBody)(::Establish) = x.est()
ocbody(body) = OCBody((@opaque Tuple{} -> Nothing () -> (body(); nothing)),
                      (@opaque Tuple{Int} -> Nothing (t) -> (body(t); nothing)),
                      (@opaque Tuple{} -> Nothing () -> (body(Cadence.ESTABLISH); nothing)))

function rebuild(sim, wrap)
    e = sim.exec
    bodies = (sweep_1 = wrap(e.bodies.sweep_1), sweep_2 = wrap(e.bodies.sweep_2), rhs = wrap(e.bodies.rhs),
              ticks = wrap(e.bodies.ticks), events = e.bodies.events, projections = e.bodies.projections)
    e2 = Executor(e.act, e.store, e.xbuf, e.ẋbuf, e.sstores, e.mstores, e.clock, bodies, e.events, e.cursor,
                  e.chunk_size, e.stepper, e.xnext, e.ẋnext, e.has_localized)
    run = Run{Float64}(SnapshotLog(true, 1, typemax(Int)), nothing, nothing, nothing)
    Simulation{Float64,typeof(e2)}(sim.deployment, e2, DataPlane(e.act.layout), Control(5.0), run)
end
variants = (("original PhaseBody", identity), ("@noinline wrapper", s -> rebuild(s, NIBody)), ("opaque-closure bodies", s -> rebuild(s, ocbody)))
for (label, f) in variants          # warm each path on a small model
    global sim = f(Simulation(many(2); h = 1//1000)); init!(sim, fragment(inputs = (ref = 1.0,))); run!(sim; t_end = 0.01)
end
println("fresh topologies, walks called once beforehand; timers at top level:")
N = 63
for (label, f) in (variants..., ("opaque-closure bodies, again", variants[3][2]))
    global N += 1
    global sim = f(Simulation(many(N); h = 1//1000))
    for nm in (:sweep_1, :sweep_2, :rhs, :ticks); b = getfield(sim.exec.bodies, nm); b(); b(0); end
    c0 = ct()
    t_i = @elapsed init!(sim, fragment(inputs = (ref = 1.0,)))
    t_r = @elapsed run!(sim; t_end = 0.01)
    c1 = ct()
    init!(sim, fragment(inputs = (ref = 1.0,))); t_w = @elapsed run!(sim; t_end = 10.0)
    @printf("  %-32s N=%d  type string %5d chars  init! %5.2f  run! %5.2f  (compile %5.2f)   warm %5.1f ms per sim-second\n",
            label, N, length(string(typeof(sim))), t_i, t_r, c1 - c0, t_w * 100)
end
