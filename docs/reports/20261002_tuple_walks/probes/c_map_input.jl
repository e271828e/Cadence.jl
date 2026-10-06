# C: bindings.jl's map_input, a map over the datum's keys, at widths 31..64.
using Redstone, BenchmarkTools
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl"))
for n in (31, 32, 33, 64)
    b = TableBinding(; (Symbol(:c, i) => (face = "f$i",) for i in 1:n)...)
    datum = NamedTuple{ntuple(i -> Symbol(:c, i), n)}(ntuple(i -> 0.1i, n))
    map_input(datum, b)
    rt = only(Base.return_types(map_input, (typeof(datum), typeof(b))))
    println("n=$n map_input ", @ballocated(map_input($datum, $b)), " B ",
            round(@belapsed(map_input($datum, $b)) * 1e9, digits = 1), " ns, concrete return ", isconcretetype(rt))
end
