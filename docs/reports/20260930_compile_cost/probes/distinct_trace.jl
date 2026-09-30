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

steps = parse(Int, ARGS[1])
for m in (many(2), manyk(2, 46)); s = Simulation(m; h = 1//1000); init!(s, fragment(inputs = (ref = 1.0,))); run!(s; t_end = 0.01) end
b1 = build(manyk(16, 0))
steps ≥ 1 && (b2 = build(manyk(16, 16)))
