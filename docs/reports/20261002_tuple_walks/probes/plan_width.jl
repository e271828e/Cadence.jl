# conditions.jl's two `Base.tail` recursions: does `apply!` allocate past 32 writes?
using Cadence, BenchmarkTools, StaticArrays, LinearAlgebra
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))
for n in (16, 32, 33, 40, 64)
    root = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
    sim = Simulation(root; h = 1//10)
    tree_of(v) = combine((at("s$i", fragment(x = (q = v + i,))) for i in 1:n)...)
    plan = compile_plan(tree_of(0.0), sim.deployment.build)
    tree = tree_of(0.25)
    apply!(sim.exec, plan, tree)
    println("n=$n xs=", length(plan.xs), " prefixes=", length(plan.prefixes), " apply! bytes=", @ballocated(apply!($(sim.exec), $plan, $tree)),
            " time=", round(@belapsed(apply!($(sim.exec), $plan, $tree)) * 1e9; digits = 1), " ns")
end
