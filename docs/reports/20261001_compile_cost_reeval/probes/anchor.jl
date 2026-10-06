# The 2026-09-30 report's own fixture and headline measurement, at this tip:
# a fresh 64-loop topology of the README loop, component types known, walks
# called once beforehand, timers at top level. The report gives, at 82c23d5,
# `build` 11.3 s, `init!` 1.67 s and `run!` 6.79 s.
#   julia --project=<export>/test anchor.jl
Base.cumulative_compile_timing(true)
using Redstone, Printf
import Redstone: AbstractComponent, x_init, s_init, u_types, y_types,
    y_state, y_direct, x_deriv, s_update,
    Group, Absolute, Hz, Simulation, init!, run!, fragment, build
struct Plant <: AbstractComponent; ω::Float64; ζ::Float64; end
x_init(::Plant) = (q = 0.0, v = 0.0)
u_types(::Plant) = (u = Float64,)
y_types(::Plant) = (y = Float64, power = Float64)
y_state(::Plant, (; x)) = (y = x.q,)
y_direct(::Plant, (; x, u)) = (power = u.u * x.v,)
x_deriv(p::Plant, (; x, u)) = (q = x.v, v = -p.ω^2 * x.q - 2p.ζ * p.ω * x.v + u.u)
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
warm = Simulation(many(2); h = 1//1000); init!(warm, fragment(u = (ref = 1.0,))); run!(warm; t_end = 0.01)

root = many(64)
t_build = @elapsed bld = build(root)
sim = Simulation(bld; h = 1//1000)
for nm in (:sweep_1, :sweep_2, :rhs, :ticks); b = getfield(sim.exec.bodies, nm); b(); b(0); end
t_init = @elapsed init!(sim, fragment(u = (ref = 1.0,)))
t_run = @elapsed run!(sim; t_end = 0.01)
@printf("ANCHOR build=%.2f init=%.2f run=%.2f  (report at 82c23d5: build 11.3, init 1.67, run 6.79)\n",
        t_build, t_init, t_run)
