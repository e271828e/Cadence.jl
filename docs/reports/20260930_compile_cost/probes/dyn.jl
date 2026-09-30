# A dynamic-dispatch walk over the same entries the compiled bodies hold:
# runtime and allocation against the compiled walk, and its compile cost on a
# fresh topology.
Base.cumulative_compile_timing(true)
using Cadence, BenchmarkTools, Printf
import Cadence: AbstractComponent, x_init, s_init, u_types, y_types,
    y_state, y_direct, x_derivative, s_update,
    Group, Absolute, Hz, Simulation, init!, run!, fragment, build

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

# the entries, flattened out of the compiled chunks into an untyped vector
entries_of(chunks::Tuple) = Any[e for c in chunks for e in c.entries]

# the dynamic walks: one loop compiled once for Vector{Any}, dispatching per entry
function dyn_walk(entries::Vector{Any}, store, xbuf, ẋbuf)
    for e in entries
        Cadence.run_entry!(e, store, xbuf, ẋbuf)
    end
    nothing
end
function dyn_walk_at(entries::Vector{Any}, store, xbuf, ẋbuf, tick::Int)
    for e in entries
        Cadence.run_at!(e, store, xbuf, ẋbuf, tick)
    end
    nothing
end

function compare(N)
    sim = Simulation(many(N); h = 1//1000)
    init!(sim, fragment(inputs = (ref = 1.0,)))
    exec = sim.exec
    store, xbuf, ẋbuf = exec.store, exec.xbuf, exec.ẋbuf
    for name in (:sweep_1, :sweep_2, :rhs)
        body = getfield(exec.bodies, name)
        ent = entries_of(body.interior)
        t_c = @belapsed $body()
        t_d = @belapsed dyn_walk($ent, $store, $xbuf, $ẋbuf)
        a_d = @ballocated dyn_walk($ent, $store, $xbuf, $ẋbuf)
        @printf("N=%3d %-8s %3d entries  compiled %7.1f ns (%4.1f ns/entry)   dynamic %7.1f ns (%4.1f ns/entry)  alloc %d\n",
                N, name, length(ent), t_c * 1e9, t_c * 1e9 / max(length(ent), 1), t_d * 1e9, t_d * 1e9 / max(length(ent), 1), a_d)
    end
    body = exec.bodies.sweep_2
    ent = entries_of(body.boundary)
    t_c = @belapsed $body(20)
    t_d = @belapsed dyn_walk_at($ent, $store, $xbuf, $ẋbuf, 20)
    a_d = @ballocated dyn_walk_at($ent, $store, $xbuf, $ẋbuf, 20)
    @printf("N=%3d %-8s %3d entries  compiled %7.1f ns (%4.1f ns/entry)   dynamic %7.1f ns (%4.1f ns/entry)  alloc %d   [boundary, gated]\n",
            N, "sweep_2", length(ent), t_c * 1e9, t_c * 1e9 / length(ent), t_d * 1e9, t_d * 1e9 / length(ent), a_d)
    sim
end

compare(4)
compare(64)

# compile cost of the dynamic walk on a fresh topology: 65 loops, never seen.
# The Simulation constructor still builds the compiled tuples (unavoidable in
# this prototype), so time the walk's first call only.
sim = Simulation(many(65); h = 1//1000)
exec = sim.exec
ent = entries_of(exec.bodies.sweep_2.interior)
c0 = Base.cumulative_compile_time_ns()[1]
t = @elapsed dyn_walk(ent, exec.store, exec.xbuf, exec.ẋbuf)
c1 = Base.cumulative_compile_time_ns()[1]
@printf("fresh topology (65 loops): first dynamic sweep_2 call %.4f s, compile %.4f s\n", t, (c1 - c0) / 1e9)
c0 = Base.cumulative_compile_time_ns()[1]
t = @elapsed exec.bodies.sweep_2()
c1 = Base.cumulative_compile_time_ns()[1]
@printf("fresh topology (65 loops): first compiled sweep_2 call %.4f s, compile %.4f s\n", t, (c1 - c0) / 1e9)
