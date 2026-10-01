# Verifier's own timer, independent of measure.jl.
#   julia --project=<export>/test mytime.jl <label> <scenario> <mode> <chunk> [trajdir]
# mode: cold | types | iter. First sim = construct + build + Simulation + init! + run!(0.1),
# no explicit body calls. Every step is its own top-level statement.
Base.cumulative_compile_timing(true)
using Cadence
include("/Users/miguel/.julia/dev/Cadence.jl/docs/reports/20261001_compile_cost_reeval/probes/fixtures.jl")
const LABEL = ARGS[1]
const SCEN = Symbol(ARGS[2]); const MODE = Symbol(ARGS[3])
const CH = ARGS[4] == "none" ? typemax(Int) ÷ 2 : parse(Int, ARGS[4])
cc() = Base.cumulative_compile_time_ns()[1]
if MODE === :iter
    wsim = Simulation(build(previous(SCEN)); h = 1//1000, chunk_size = CH)
    init!(wsim, condition(SCEN)); run!(wsim; t_end = 0.1)
elseif MODE === :types
    wsim = Simulation(build(unrelated()); h = 1//1000, chunk_size = CH)
    init!(wsim, unrelated_condition()); run!(wsim; t_end = 0.1)
end
c0 = cc(); t0 = time_ns()
root = model(SCEN)
t1 = time_ns()
bld = build(root)
t2 = time_ns()
sim = Simulation(bld; h = 1//1000, chunk_size = CH)
t3 = time_ns()
init!(sim, condition(SCEN))
t4 = time_ns()
run!(sim; t_end = 0.1)
t5 = time_ns(); c1 = cc()
warm = Inf
for _ in 1:3
    init!(sim, condition(SCEN))
    local a = time_ns(); run!(sim; t_end = 2.0); global warm = min(warm, (time_ns() - a) / 1e6 / 2)
end
init!(sim, condition(SCEN)); run!(sim; t_end = 0.2)
init!(sim, condition(SCEN))
runalloc = @allocated run!(sim; t_end = 1.0)
x = copy(sim.exec.xbuf)
if length(ARGS) ≥ 5
    open(joinpath(ARGS[5], "$(LABEL)_$(SCEN)_$(ARGS[4]).txt"), "w") do io
        foreach(v -> println(io, repr(v)), x)
    end
end
s(a, b) = round((b - a) / 1e9; digits = 3)
println("MY label=$LABEL scen=$SCEN mode=$MODE chunk=$(ARGS[4]) O=$(Base.JLOptions().opt_level) ",
        "construct=$(s(t0,t1)) build=$(s(t1,t2)) sim=$(s(t2,t3)) init=$(s(t3,t4)) run=$(s(t4,t5)) ",
        "first=$(s(t0,t5)) compile=$(round((c1-c0)/1e9; digits=3)) warm_ms_per_s=$(round(warm; digits=2)) ",
        "runalloc_1s=$runalloc nx=$(length(x)) xhash=$(string(hash(x), base=16))")
