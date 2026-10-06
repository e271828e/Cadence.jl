# C: does trim's `_seeded` infer its NamedTuple? The names arrive as a runtime value.
using Redstone, ForwardDiff
TD = ForwardDiff.Dual{Redstone.TrimTag,Float64,2}
println(Base.return_types(Redstone._seeded, (Tuple{Symbol,Symbol}, Vector{Float64}, Type{TD})))
