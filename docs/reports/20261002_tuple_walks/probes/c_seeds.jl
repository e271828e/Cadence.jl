# The Dual seed splats in trim's `_seeded` and linearize's `_seed`, at widths 31..33, 64.
using Redstone, BenchmarkTools, ForwardDiff
for N in parse.(Int, split(get(ENV, "WIDTHS", "31,32,33,64"), ","))
    TD = ForwardDiff.Dual{Redstone.TrimTag,Float64,N}
    names = ntuple(i -> Symbol(:d, i), N)
    d = rand(N)
    Redstone._seeded(names, d, TD)
    LD = ForwardDiff.Dual{Redstone.LinearizeTag,Float64,N}
    Redstone._seed(LD, 0.5, 3)
    println("N=$N _seeded ", @ballocated(Redstone._seeded($names, $d, $TD)), " B ",
            round(@belapsed(Redstone._seeded($names, $d, $TD)) * 1e6, digits = 2), " µs | _seed ",
            @ballocated(Redstone._seed($LD, 0.5, 3)), " B ",
            round(@belapsed(Redstone._seed($LD, 0.5, 3)) * 1e9, digits = 1), " ns")
end
