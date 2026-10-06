# B, aside: where a warm trim! at 128 writes spends its time (the walks are not it).
using Redstone, StaticArrays, LinearAlgebra, ForwardDiff, Profile
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))
n = 128
root = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
sim = Simulation(root; h = 1//10)
baseline = combine((at("s$i", fragment(x = (q = 0.001i,))) for i in 2:n)...)
cond = d -> at("s1", fragment(x = (q = d.q,)))
problem = TrimProblem(guess = (q = 0.1,), lower = (q = -Inf,), upper = (q = Inf,), condition = cond,
                      reads = reads(q1 = get_state("s1", :q)),
                      residuals = (r, d) -> (hold = r.q1 - 0.3,), tolerances = (hold = 1e-9,))
trim!(sim, problem; baseline); trim!(sim, problem; baseline)
b = sim.deployment.build
for (label, f) in (("_scratch Float64", () -> Redstone._scratch(sim, Float64)),
                   ("resolve_condition", () -> Redstone.resolve_condition(override(baseline, cond((q = 0.1,))), b, Float64)),
                   ("compile_plan Dual", () -> compile_plan(override(baseline, cond(Redstone._seeded((:q,), [0.1], ForwardDiff.Dual{TrimTag,Float64,1}))), b, ForwardDiff.Dual{TrimTag,Float64,1})),
                   ("init! commit", () -> init!(sim, override(baseline, cond((q = 0.3,))))),
                   ("trim! whole", () -> trim!(sim, problem; baseline)))
    f()
    println(rpad(label, 22), round(minimum(@elapsed(f()) for _ in 1:3) * 1e3, digits = 2), " ms")
end
