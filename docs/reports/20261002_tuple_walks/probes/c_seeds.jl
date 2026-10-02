# The Dual seed splats in trim's `_seeded` and linearize's `_seed`, at widths 31..33, 64.
using Cadence, BenchmarkTools, ForwardDiff
for N in parse.(Int, split(get(ENV, "WIDTHS", "31,32,33,64"), ","))
    TD = ForwardDiff.Dual{Cadence.TrimTag,Float64,N}
    names = ntuple(i -> Symbol(:d, i), N)
    d = rand(N)
    Cadence._seeded(names, d, TD)
    LD = ForwardDiff.Dual{Cadence.LinearizeTag,Float64,N}
    Cadence._seed(LD, 0.5, 3)
    println("N=$N _seeded ", @ballocated(Cadence._seeded($names, $d, $TD)), " B ",
            round(@belapsed(Cadence._seeded($names, $d, $TD)) * 1e6, digits = 2), " µs | _seed ",
            @ballocated(Cadence._seed($LD, 0.5, 3)), " B ",
            round(@belapsed(Cadence._seed($LD, 0.5, 3)) * 1e9, digits = 1), " ns")
end
