# Same topology, one component type versus one type per instance.
Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
using Base.Experimental: @opaque
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
const KMAX = 48
for k in 1:KMAX                       # K distinct plant types, textually identical bodies
    P = Symbol(:PlantK, k)
    @eval begin
        struct $P <: AbstractComponent; ω::Float64; ζ::Float64; end
        x_init(::$P) = (q = 0.0, v = 0.0)
        u_types(::$P) = (u = Float64,)
        y_types(::$P) = (y = Float64, power = Float64)
        y_state(::$P, (; x)) = (y = x.q,)
        y_direct(::$P, (; x, u)) = (power = u.u * x.v,)
        x_derivative(p::$P, (; x, u)) = (q = x.v, v = -p.ω^2 * x.q - 2p.ζ * p.ω * x.v + u.u)
    end
end
plantk(k) = getfield(Main, Symbol(:PlantK, k))(2.0, 0.3)
manyk(N, k0) = Group(NamedTuple{ntuple(i -> Symbol(:m, i), N)}(ntuple(i -> loop(plantk(k0 + i)), N));
    inputs = ("ref" => ntuple(i -> "m$(i)/ref", N),))
const Thunk = Core.OpaqueClosure{Tuple{}, Nothing}
entry_thunk(entry, store, xbuf, ẋbuf)::Thunk = @opaque Tuple{} -> Nothing () -> (Cadence.run_entry!(entry, store, xbuf, ẋbuf); nothing)
walk_thunks(v::Vector{Thunk}) = (for f in v; f(); end; nothing)
# warm-ups: one-type path, and the distinct-type generic paths (types 47, 48)
for m in (many(2), manyk(2, 46))
    s = Simulation(m; h = 1//1000); init!(s, fragment(inputs = (ref = 1.0,))); run!(s; t_end = 0.01)
    e = s.exec; ent = Any[x for c in e.bodies.sweep_2.interior for x in c.entries]; v = Thunk[entry_thunk(x, e.store, e.xbuf, e.ẋbuf) for x in ent]; walk_thunks(v)
end
println("fresh models, timers at top level (warm: 4 plants of other types)")
for (label, model) in (("32 loops, one type", many(32)), ("16 loops, 16 distinct types", manyk(16, 0)), ("32 loops, 32 distinct types", manyk(32, 16)))
    global b, sim
    c0 = ct()
    t_b = @elapsed b = build(model)
    t_s = @elapsed sim = Simulation(b; h = 1//1000)
    t_w = @elapsed (for nm in (:sweep_1, :sweep_2, :rhs, :ticks); f = getfield(sim.exec.bodies, nm); f(); f(0); f(Cadence.ESTABLISH); end)
    t_i = @elapsed init!(sim, fragment(inputs = (ref = 1.0,)))
    t_r = @elapsed run!(sim; t_end = 0.01)
    c1 = ct()
    e = sim.exec
    ent = Any[x for c in e.bodies.sweep_2.interior for x in c.entries]      # outside the timer
    t_oc = @elapsed (v = Thunk[entry_thunk(x, e.store, e.xbuf, e.ẋbuf) for x in ent]; walk_thunks(v))
    @printf("  %-30s build %5.2f  Simulation %5.2f  walks %5.2f  init! %5.2f  run! %5.2f  | total %5.2f s  || opaque per-entry sweep_2, cold: %5.2f s\n",
            label, t_b, t_s, t_w, t_i, t_r, c1 - c0, t_oc)
end
