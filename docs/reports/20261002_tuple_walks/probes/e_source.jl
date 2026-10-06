# E: where run!'s per-frame bytes come from. Profile.Allocs over a run, then the parts directly.
using Redstone, StaticArrays, LinearAlgebra, ForwardDiff, Profile
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))

saw4() = Group(NamedTuple{(:a, :b, :c, :d)}(ntuple(_ -> Sawtooth(1.0), 4)))
sim = Simulation(saw4(); h = 1//1000)
init!(sim, fragment()); run!(sim; t_end = 0.05)
init!(sim, fragment())
Profile.Allocs.clear()
Profile.Allocs.@profile sample_rate = 1 run!(sim; t_end = 1.0)
res = Profile.Allocs.fetch()
frames = sim.exec.clock.frame
println("frames=$frames allocations=", length(res.allocs), " bytes=", sum(a.size for a in res.allocs))
# Attribute each allocation to the innermost Redstone source line in its stack.
agg = Dict{Tuple{String,String},Tuple{Int,Int}}()
for a in res.allocs
    site = "?"
    for fr in a.stacktrace
        f = string(fr.file)
        if occursin("redstone_walks", f) && occursin("/src/", f)
            site = "$(basename(f)):$(fr.line) $(fr.func)"
            break
        end
    end
    key = (site, string(a.type))
    c, b = get(agg, key, (0, 0))
    agg[key] = (c + 1, b + a.size)
end
for ((site, type), (c, b)) in sort(collect(agg); by = x -> -x[2][2])
    c < frames ÷ 2 && continue
    println(rpad(site, 60), rpad(type, 50), " count/frame=", round(c / frames, digits = 2),
            " bytes/frame=", round(b / frames, digits = 1))
end

# The parts directly.
roster = Redstone.RosterEntry[]
store = sim.exec.store
Redstone.capture_stores(store); Redstone._status(sim, roster, nothing); Redstone.publish!(sim, roster, nothing)
println("capture_stores ", @allocated(Redstone.capture_stores(store)), " B")
println("_status ", @allocated(Redstone._status(sim, roster, nothing)), " B")
println("publish! ", @allocated(Redstone.publish!(sim, roster, nothing)), " B")
println("store buffers: ", [(k, length(v.buffer)) for (k, v) in pairs(store.stores)])
