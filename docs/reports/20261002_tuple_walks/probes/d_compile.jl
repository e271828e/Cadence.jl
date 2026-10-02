# D: first-call (compile) time of the specialized apply! and of gather_reads at 64 and 128.
using Cadence, BenchmarkTools, StaticArrays, LinearAlgebra
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))

function case(n)
    root = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
    sim = Simulation(root; h = 1//10)
    tree = combine((at("s$i", fragment(x = (q = 0.25 + i,))) for i in 1:n)...)
    plan = compile_plan(tree, sim.deployment.build)
    spec = reads(; (Symbol(:q, i) => get_state("s$i", :q) for i in 1:n)...)
    reader = Cadence._compile_reads(spec, sim.deployment.build, Float64)
    exec = sim.exec
    ta = @elapsed apply!(exec, plan, tree)
    tg = @elapsed gather_reads(reader, exec)
    println("n=$n first apply! ", round(ta, digits = 3), " s, first gather_reads ", round(tg, digits = 3), " s")
end
for n in parse.(Int, split(get(ENV, "WIDTHS", "8,64,128,256"), ","))
    case(n)
end
