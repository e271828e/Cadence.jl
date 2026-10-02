# C: does trim's `_seeded` infer its NamedTuple? The names arrive as a runtime value.
using Cadence, ForwardDiff
TD = ForwardDiff.Dual{Cadence.TrimTag,Float64,2}
println(Base.return_types(Cadence._seeded, (Tuple{Symbol,Symbol}, Vector{Float64}, Type{TD})))
