# Top-level timing of each step for a fresh 16- and 64-loop model, with marker
# functions compiled between steps so the trace-compile stream can be split.
Base.cumulative_compile_timing(true)
using Redstone, Printf
import Redstone: AbstractComponent, x_init, s_init, u_types, y_types,
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

# warm-up, top level
m2 = many(2); b2 = build(m2); s2 = Simulation(b2; h = 1//1000); init!(s2, fragment(inputs = (ref = 1.0,))); run!(s2; t_end = 0.01)

macro mark(name); f = Symbol("MARK_", name); esc(quote; $f() = nothing; $f(); end); end
for N in (16, 64)
    global model, b, sim
    @eval @mark $(Symbol("construct_", N))
    c0 = ct(); t = @elapsed model = many(N);                                @printf("N=%2d construct  %6.2f s (compile %6.2f)\n", N, t, ct() - c0)
    @eval @mark $(Symbol("build_", N))
    c0 = ct(); t = @elapsed b = build(model);                               @printf("N=%2d build      %6.2f s (compile %6.2f)\n", N, t, ct() - c0)
    @eval @mark $(Symbol("sim_", N))
    c0 = ct(); t = @elapsed sim = Simulation(b; h = 1//1000);               @printf("N=%2d Simulation %6.2f s (compile %6.2f)\n", N, t, ct() - c0)
    @eval @mark $(Symbol("walks_", N))
    c0 = ct(); t = @elapsed (for nm in (:sweep_1, :sweep_2, :rhs, :ticks); f = getfield(phase_bodies(sim), nm); f(); f(0); end);
                                                                            @printf("N=%2d walks      %6.2f s (compile %6.2f)\n", N, t, ct() - c0)
    @eval @mark $(Symbol("init_", N))
    c0 = ct(); t = @elapsed init!(sim, fragment(inputs = (ref = 1.0,)));    @printf("N=%2d init!      %6.2f s (compile %6.2f)\n", N, t, ct() - c0)
    @eval @mark $(Symbol("run_", N))
    c0 = ct(); t = @elapsed run!(sim; t_end = 0.01);                        @printf("N=%2d run!       %6.2f s (compile %6.2f)\n", N, t, ct() - c0)
    @eval @mark $(Symbol("end_", N))
end
