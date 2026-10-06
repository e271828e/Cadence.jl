# D: the first trim! of a new shape, end to end, at n condition writes and one read.
using Redstone, BenchmarkTools, StaticArrays, LinearAlgebra, ForwardDiff
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))

function setup(n)
    root = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
    sim = Simulation(root; h = 1//10)
    baseline = combine((at("s$i", fragment(x = (q = 0.001i,))) for i in 2:n)...)
    cond = d -> at("s1", fragment(x = (q = d.q,)))
    problem = TrimProblem(guess = (q = 0.1,), lower = (q = -Inf,), upper = (q = Inf,),
                          condition = cond, reads = reads(q1 = get_state("s1", :q)),
                          residuals = (r, d) -> (hold = r.q1 - 0.3,), tolerances = (hold = 1e-9,))
    sim, baseline, problem
end
for n in parse.(Int, split(get(ENV, "WIDTHS", "8,64,128"), ","))
    sim, baseline, problem = setup(n)
    init!(sim, baseline); run!(sim; t_end = 0.2)       # the loop compiled, outside the figure
    t1 = @elapsed trim!(sim, problem; baseline = baseline)
    t2 = @elapsed trim!(sim, problem; baseline = baseline)
    println("n=$n first trim! ", round(t1, digits = 2), " s, second ", round(t2 * 1e3, digits = 1), " ms")
end
