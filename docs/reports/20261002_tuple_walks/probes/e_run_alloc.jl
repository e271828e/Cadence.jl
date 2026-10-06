# E: is run!'s allocation per frame or per call? Same model, run lengths 10x and 100x apart.
using Redstone, StaticArrays, LinearAlgebra, ForwardDiff
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))

function probe(label, sim, cond; kw...)
    init!(sim, cond; kw...); run!(sim; t_end = 0.05)                 # compile
    for frames in (100, 1_000, 10_000, 100_000)
        init!(sim, cond; kw...)
        te = frames * Float64(sim.deployment.h)
        a = @allocated run!(sim; t_end = te)
        n = sim.exec.clock.frame
        println(label, " frames=", n, " boundaries=", sim.exec.clock.boundary,
                " alloc=", a, " B  per frame=", round(a / n, digits = 1), " B")
    end
end

saw4() = Group(NamedTuple{(:a, :b, :c, :d)}(ntuple(_ -> Sawtooth(1.0), 4)))
probe("saw4 deviceless", Simulation(saw4(); h = 1//1000), fragment())
probe("saw4 log=false", Simulation(saw4(); h = 1//1000), fragment(); log = false)
probe("saw4 log=false trace=false", Simulation(saw4(); h = 1//1000), fragment(); log = false, trace = false)
sim = Simulation(saw4(); h = 1//1000)
attach!(sim, TailProbe(), NoClaim())
probe("saw4 + TailProbe", sim, fragment())
