# B: what the two walks cost inside one trim!, at n condition writes and k reads.
using Cadence, BenchmarkTools, StaticArrays, LinearAlgebra, ForwardDiff
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))

function setup(n, k)
    root = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
    sim = Simulation(root; h = 1//10)
    baseline = combine((at("s$i", fragment(x = (q = 0.001i,))) for i in 2:n)...)
    cond = d -> at("s1", fragment(x = (q = d.q,)))
    rs = reads(; (Symbol(:q, i) => get_state("s$i", :q) for i in 1:k)...)
    problem = TrimProblem(guess = (q = 0.1,), lower = (q = -Inf,), upper = (q = Inf,),
                          condition = cond, reads = rs,
                          residuals = (r, d) -> (hold = r.q1 - 0.3,), tolerances = (hold = 1e-9,))
    sim, baseline, cond, problem
end

for (n, k) in ((31, 1), (32, 1), (33, 1), (64, 1), (128, 1), (31, 31), (32, 32), (33, 33), (64, 64))
    sim, baseline, cond, problem = setup(n, k)
    rep = trim!(sim, problem; baseline = baseline)          # compile
    rep = trim!(sim, problem; baseline = baseline)
    t_trim = minimum(@elapsed(trim!(sim, problem; baseline = baseline)) for _ in 1:5)
    # The seeded objects eval! uses, rebuilt as trim! builds them.
    build_ = sim.deployment.build
    TD = ForwardDiff.Dual{TrimTag,Float64,1}
    act = activation(build_, TD)
    sexec = Cadence._scratch(sim, TD, act)
    d = Cadence._seeded((:q,), [0.2], TD)
    plan = compile_plan(override(baseline, cond(d)), build_, TD)
    reader = Cadence._compile_reads(problem.reads, build_, TD)
    tree = override(baseline, cond(d))
    apply!(sexec, plan, tree); gather_reads(reader, sexec)
    a_b = @ballocated apply!($sexec, $plan, $tree)
    a_t = @belapsed apply!($sexec, $plan, $tree)
    g_b = @ballocated gather_reads($reader, $sexec)
    g_t = @belapsed gather_reads($reader, $sexec)
    res = problem.residuals
    r_t = @belapsed $res(gather_reads($reader, $sexec), $d)
    e_t = @belapsed evaluate!($sexec)
    println("n=$n k=$k plan(xs=$(length(plan.xs)), prefixes=$(length(plan.prefixes))) trim! ",
            round(t_trim * 1e3, digits = 2), " ms, evals ", rep.n_evaluations,
            ", converged ", rep.converged,
            " | seeded apply! ", a_b, " B ", round(a_t * 1e6, digits = 2), " µs",
            " | gather_reads ", g_b, " B ", round(g_t * 1e6, digits = 3), " µs",
            " | gather+residual ", round(r_t * 1e6, digits = 3), " µs",
            " | evaluate! ", round(e_t * 1e6, digits = 2), " µs")
end
