# Compile cost per model type within one session versus a fresh process. Each
# argument is an N to build in sequence, e.g.
#   julia --project=test docs/reports/20260917_pathsim_comparison/probes/compile_cost.jl 1 30
t_load = @elapsed include(joinpath(@__DIR__, "..", "..", "..", "..", "test", "repl.jl"))
using Printf
const ω, ζ, k, r = 2.0, 0.1, 4.0, 0.7
function make(N)
    kids = NamedTuple{Tuple(Symbol.(vcat(["plant$i" for i in 1:N], ["ctl$i" for i in 1:N], ["sum$i" for i in 1:N])))}(
        Tuple(vcat([Plant(; ω, ζ) for _ in 1:N], [Gain(k) for _ in 1:N], [Sum() for _ in 1:N])))
    wires = Tuple(vcat([["ctl$i/out" => "plant$i/u", "sum$i/e" => "ctl$i/e", "plant$i/y" => "sum$i/b"] for i in 1:N]...))
    Group(kids; wires, inputs = ("ref" => Tuple("sum$i/a" for i in 1:N),), outputs = "plant1/y" => "y")
end
function once(N)
    tb = @elapsed sim = Simulation(make(N); h = 1//1000)
    ti = @elapsed init!(sim, fragment(inputs = (ref = r,)))
    tr = @elapsed run!(sim; t_end = 0.01)
    @printf("  N=%3d: build+compile %5.2f s, init %5.2f s, first run! %5.2f s  = %5.2f s\n", N, tb, ti, tr, tb + ti + tr)
end
@printf("load (using Cadence + fixtures): %.2f s\n", t_load)
for N in parse.(Int, ARGS); once(N); end
