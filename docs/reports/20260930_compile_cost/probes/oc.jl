# Opaque closures as the seam: (1) one per phase body, the barrier a generic
# loop would call through; (2) one per entry, a runtime-walked vector that
# replaces the unrolled tuple. Runtime, allocation and fresh-topology compile.
Base.cumulative_compile_timing(true)
using Cadence, BenchmarkTools, Printf
using Base.Experimental: @opaque
import Cadence: AbstractComponent, x_init, s_init, u_types, y_types,
    y_state, y_direct, x_derivative, s_update,
    Group, Absolute, Hz, Simulation, init!, run!, fragment, build, phase_bodies

struct Plant <: AbstractComponent; ω::Float64; ζ::Float64; end
x_init(::Plant) = (q = 0.0, v = 0.0)
u_types(::Plant) = (u = Float64,)
y_types(::Plant) = (y = Float64, power = Float64)
y_state(::Plant, (; x)) = (y = x.q,)
y_direct(::Plant, (; x, u)) = (power = u.u * x.v,)
x_derivative(p::Plant, (; x, u)) = (q = x.v, v = -p.ω^2 * x.q - 2p.ζ * p.ω * x.v + u.u)
struct PI <: AbstractComponent; k_p::Float64; k_i::Float64; end
s_init(::PI) = (integral = 0.0,)
u_types(::PI) = (ref = Float64, y = Float64)
y_types(::PI) = (u = Float64,)
y_direct(c::PI, (; s, u)) = (u = c.k_p * (u.ref - u.y) + s.integral,)
s_update(c::PI, (; s, u, Δt)) = (integral = s.integral + c.k_i * Δt * (u.ref - u.y),)
loop(P) = Group((plant = P, ctl = PI(3.0, 2.0));
    wires = ("ctl/u" => "plant/u", "plant/y" => "ctl/y"),
    inputs = "ref" => "ctl/ref", outputs = "plant/y" => "y",
    rates = (ctl = Absolute(Hz(50)),))
many(N) = Group(NamedTuple{ntuple(i -> Symbol(:m, i), N)}(ntuple(i -> loop(Plant(2.0, 0.3)), N));
    inputs = ("ref" => ntuple(i -> "m$(i)/ref", N),))
ct() = Base.cumulative_compile_time_ns()[1] / 1e9

const Thunk = Core.OpaqueClosure{Tuple{}, Nothing}
entries_of(chunks::Tuple) = Any[e for c in chunks for e in c.entries]
# one opaque closure per entry, closed over the entry and the buffers
entry_thunk(entry, store, xbuf, ẋbuf)::Thunk =
    @opaque Tuple{} -> Nothing () -> (Cadence.run_entry!(entry, store, xbuf, ẋbuf); nothing)
gated_thunk(entry, store, xbuf, ẋbuf, tick)::Thunk =
    @opaque Tuple{} -> Nothing () -> (Cadence.run_at!(entry, store, xbuf, ẋbuf, tick); nothing)
thunks(entries, store, xbuf, ẋbuf) = Thunk[entry_thunk(e, store, xbuf, ẋbuf) for e in entries]
function walk_thunks(v::Vector{Thunk})
    for f in v; f(); end
    nothing
end

function measure(N, label)
    sim = Simulation(many(N); h = 1//1000); init!(sim, fragment(inputs = (ref = 1.0,)))
    exec = sim.exec; store, xbuf, ẋbuf = exec.store, exec.xbuf, exec.ẋbuf
    bodies = phase_bodies(sim)
    println(label)
    for name in (:sweep_1, :sweep_2, :rhs)
        body = getfield(bodies, name)
        ent = entries_of(body.interior)
        c0 = ct(); barrier = (@opaque Tuple{} -> Nothing () -> (body(); nothing))::Thunk; barrier(); cb = ct() - c0
        c0 = ct(); v = thunks(ent, store, xbuf, ẋbuf); walk_thunks(v); cv = ct() - c0
        @printf("  %-8s %3d entries  direct %6.1f ns | body behind one opaque closure %6.1f ns (compile %.3f s) | per-entry opaque closures %6.1f ns = %4.1f ns/entry, alloc %d (compile %.3f s)\n",
                name, length(ent), (@belapsed $body()) * 1e9, (@belapsed $barrier()) * 1e9, cb,
                (@belapsed walk_thunks($v)) * 1e9, (@belapsed walk_thunks($v)) * 1e9 / length(ent),
                @ballocated(walk_thunks($v)), cv)
    end
end
measure(4, "4 loops (cold: closure bodies compile here)")
measure(64, "64 loops (closure bodies warm from the 4-loop model: this is the fresh-topology cost)")
