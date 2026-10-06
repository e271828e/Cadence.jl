# One measurement, one process:
#   julia -O<level> --project=<export>/test measure.jl <scenario> <mode> <chunk_size>
#
# scenario  small | repeated | distinct
# mode      cold   the scenario's model is the first one of the process
#           types  a model of unrelated types ran first: generic machinery warm
#           iter   the scenario's previous topology ran first: types warm too
# chunk_size  an integer, or `none` for one chunk per body
#
# Every timer sits at top level. A timer inside a wrapper under-reports, because
# Julia compiles the wrapper's callees before its body runs.
#
# Contract with the patched exports: `sim.exec.bodies` has callable `sweep_1`,
# `sweep_2`, `rhs` and `ticks`, each taking `()` and `(tick::Int)`, and
# `sim.exec.xbuf` is the flat state vector. `Redstone.boundary!(sim, tick)` runs
# one base-tick boundary.
Base.cumulative_compile_timing(true)
t_using = @elapsed using Redstone
using Printf
include(joinpath(@__DIR__, "fixtures.jl"))
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
const BODIES = (:sweep_1, :sweep_2, :rhs, :ticks)
scenario, mode = Symbol(ARGS[1]), Symbol(ARGS[2])
chunk_size = ARGS[3] == "none" ? typemax(Int) ÷ 2 : parse(Int, ARGS[3])

if mode !== :cold
    warm_model = mode === :iter ? previous(scenario) : unrelated()
    warm_cond = mode === :iter ? condition(scenario) : unrelated_condition()
    warm_sim = Simulation(build(warm_model); h = 1//1000, chunk_size)
    for nm in BODIES; b = getfield(warm_sim.exec.bodies, nm); b(); b(0); end
    init!(warm_sim, warm_cond); run!(warm_sim; t_end = 0.1)
end

c0 = ct()
t_construct = @elapsed root = model(scenario)
cond = condition(scenario)
t_build = @elapsed bld = build(root)
t_sim = @elapsed sim = Simulation(bld; h = 1//1000, chunk_size)
t_walks = @elapsed for nm in BODIES; b = getfield(sim.exec.bodies, nm); b(); b(0); end
t_init = @elapsed init!(sim, cond)
t_run = @elapsed run!(sim; t_end = 0.1)
compile = ct() - c0

# warm runtime, allocation and trajectory, all outside the timed steps
warm = Inf
for _ in 1:3
    init!(sim, cond)
    global warm = min(warm, @elapsed run!(sim; t_end = 2.0))
end
init!(sim, cond); run!(sim; t_end = 1.0)
x = sim.exec.xbuf
xhash = hash(x)
alloc = 0                       # the interior bodies, the §7.5 measurement
alloc_at = 0                    # the boundary bodies
for nm in BODIES
    b = getfield(sim.exec.bodies, nm)
    b(); b(1)
    global alloc += @allocated b()
    global alloc_at += @allocated b(1)
end
Redstone.boundary!(sim, 1)       # projection, event phase and ticks, state already hashed
alloc_boundary = @allocated Redstone.boundary!(sim, 1)
@printf("RESULT scenario=%s mode=%s chunk=%s opt=%d using=%.3f construct=%.3f build=%.3f sim=%.3f walks=%.3f init=%.3f run=%.3f total=%.3f compile=%.3f warm_ms_per_s=%.3f alloc=%d alloc_at=%d alloc_boundary=%d n_x=%d xhash=%016x\n",
        scenario, mode, ARGS[3], Base.JLOptions().opt_level, t_using, t_construct, t_build, t_sim, t_walks,
        t_init, t_run, t_build + t_sim + t_walks + t_init + t_run, compile, warm * 500, alloc,
        alloc_at, alloc_boundary, length(x), xhash)
