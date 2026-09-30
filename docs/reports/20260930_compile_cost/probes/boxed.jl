# Direct test of the fix the hypothesis implies: put each chunk behind a
# pointer (a mutable wrapper) so a phase body is a tuple of pointers, then
# rebuild an Executor and a Simulation around the same buffers and time the
# loop machinery on a fresh topology against the unmodified executor.
Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
import Cadence: PhaseBody, Executor, DataPlane, Control, Run, SnapshotLog, child_connections,
    input_connections, output_connections, transparent_container
ct() = Base.cumulative_compile_time_ns()[1] / 1e9

mutable struct MChunk{C}; c::C; end
(m::MChunk)() = m.c()
(m::MChunk)(tick) = m.c(tick)
boxed(body::PhaseBody) = PhaseBody(tuple((MChunk(c) for c in body.interior)...), tuple((MChunk(c) for c in body.boundary)...))
function boxed_sim(sim)
    e = sim.exec
    bodies = (sweep_1 = boxed(e.bodies.sweep_1), sweep_2 = boxed(e.bodies.sweep_2), rhs = boxed(e.bodies.rhs),
              ticks = boxed(e.bodies.ticks), events = e.bodies.events, projections = e.bodies.projections)
    e2 = Executor(e.act, e.store, e.xbuf, e.ẋbuf, e.sstores, e.mstores, e.clock, bodies, e.events, e.cursor,
                  e.chunk_size, e.stepper, e.xnext, e.ẋnext, e.has_localized)
    run = Run{Float64}(SnapshotLog(true, 1, typemax(Int)), nothing, nothing, nothing)
    Simulation{Float64,typeof(e2)}(sim.deployment, e2, DataPlane(e.act.layout), Control(5.0), run)
end

# every timer at top level: a wrapper function would compile init!/run! for the
# new Simulation type before its own timers start
for (label, N, f) in (("warm-up, original", 2, identity), ("warm-up, boxed", 3, boxed_sim),
                      ("original executor, fresh 64-loop", 64, identity), ("chunks behind pointers, fresh 65-loop", 65, boxed_sim))
    global sim = f(Simulation(many(N); h = 1//1000))
    for nm in (:sweep_1, :sweep_2, :rhs, :ticks); b = getfield(sim.exec.bodies, nm); b(); b(0); end
    c0 = ct()
    t_i = @elapsed init!(sim, fragment(inputs = (ref = 1.0,)))
    t_r = @elapsed run!(sim; t_end = 0.01)
    c1 = ct()
    init!(sim, fragment(inputs = (ref = 1.0,))); t_w = @elapsed run!(sim; t_end = 10.0)
    @printf("  %-40s sizeof(Executor) %6d B   init! %5.2f  run! %5.2f  (compile %5.2f)   warm %5.1f ms per sim-second\n",
            label, sizeof(typeof(sim.exec)), t_i, t_r, c1 - c0, t_w * 100)
end
