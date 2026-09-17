# Same model as bench_pathsim.py: N copies of the plant/gain/sum loop from the
# suite's `feedback_model` fixture, RK4, h = 1 ms, 10 s. Run from the repo root:
#   julia --project=test docs/reports/20260917_pathsim_comparison/probes/bench_cadence.jl
include(joinpath(@__DIR__, "..", "..", "..", "..", "test", "repl.jl"))
using Printf

const ω, ζ, k, r = 2.0, 0.1, 4.0, 0.7

function make(N)
    kids = NamedTuple{Tuple(Symbol.(vcat(["plant$i" for i in 1:N], ["ctl$i" for i in 1:N], ["sum$i" for i in 1:N])))}(
        Tuple(vcat([Plant(; ω, ζ) for _ in 1:N], [Gain(k) for _ in 1:N], [Sum() for _ in 1:N])))
    wires = Tuple(vcat([["ctl$i/out" => "plant$i/u", "sum$i/e" => "ctl$i/e", "plant$i/y" => "sum$i/b"] for i in 1:N]...))
    inputs = ("ref" => Tuple("sum$i/a" for i in 1:N),)   # one face fanned out (§8.6)
    Group(kids; wires, inputs, outputs = "plant1/y" => "y")
end

function exact(t)
    A = SMatrix{2,2}(0.0, -ω^2, 1.0, -2ζ * ω)
    B = SVector(0.0, 1.0)
    Acl = A - B * k * SVector(1.0, 0.0)'
    c = Acl \ (B * k * r)
    exp(Acl * t) * c - c
end

function bench(N; t_end = 10.0)
    GC.gc()
    tb = @elapsed sim = Simulation(make(N); h = 1//1000)          # build + compile
    ti = @elapsed init!(sim, fragment(inputs = (ref = r,)))
    tr1 = @elapsed run!(sim; t_end = 0.01)                          # first run!: remaining compile
    sim2 = Simulation(make(N); h = 1//1000)
    init!(sim2, fragment(inputs = (ref = r,)))
    tr = @elapsed run!(sim2; t_end)
    steps = round(Int, t_end / 1e-3)
    err = maximum(abs.(state(sim2, "plant1").q - exact(t_end)))
    alloc = @allocated step!(sim2, 1e-3)
    @printf("N=%4d comps=%4d  build+compile=%7.2f s  init=%6.3f s  first-run=%6.3f s  run=%7.3f s  per-step=%7.1f us  per-comp-step=%5.2f us  step-alloc=%d B  |x-exact|=%.1e\n",
            N, 3N, tb, ti, tr1, tr, 1e6 * tr / steps, 1e6 * tr / steps / 3N, alloc, err)
end

for N in [1, 10, 100]
    bench(N)
end
