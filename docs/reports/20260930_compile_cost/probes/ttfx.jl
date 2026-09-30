# Time-to-first-simulation breakdown, one cold process. Prints wall time and the
# compile share of each step, for three models: the README loop, a 4x copy of
# it with no new component types, and a variant with a new component type.
Base.cumulative_compile_timing(true)
t_load = @elapsed using Cadence
import Cadence: AbstractComponent, x_init, s_init, u_types, y_types,
    y_state, y_direct, x_derivative, s_update,
    Group, Absolute, Hz, Simulation, init!, run!, fragment, port, state, build

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

# the "architecture iteration": a new plant type with a third state
struct Plant3 <: AbstractComponent; ω::Float64; ζ::Float64; τ::Float64; end
x_init(::Plant3) = (q = 0.0, v = 0.0, a = 0.0)
u_types(::Plant3) = (u = Float64,)
y_types(::Plant3) = (y = Float64, power = Float64)
y_state(::Plant3, (; x)) = (y = x.q,)
y_direct(::Plant3, (; x, u)) = (power = u.u * x.v,)
x_derivative(p::Plant3, (; x, u)) =
    (q = x.v, v = x.a, a = (-p.ω^2 * x.q - 2p.ζ * p.ω * x.v + u.u - x.a) / p.τ)

loop(P) = Group((plant = P, ctl = PI(3.0, 2.0));
    wires = ("ctl/u" => "plant/u", "plant/y" => "ctl/y"),
    inputs = "ref" => "ctl/ref", outputs = "plant/y" => "y",
    rates = (ctl = Absolute(Hz(50)),))

four(P) = Group(NamedTuple{(:m1, :m2, :m3, :m4)}(ntuple(_ -> loop(P), 4));
    inputs = ("ref" => ("m1/ref", "m2/ref", "m3/ref", "m4/ref"),))

macro step(label, ex)
    quote
        local c0 = Base.cumulative_compile_time_ns()
        local t = @elapsed local r = $(esc(ex))
        local c1 = Base.cumulative_compile_time_ns()
        local comp = (c1[1] - c0[1]) / 1e9
        local recomp = (c1[2] - c0[2]) / 1e9
        Printf.@printf("  %-28s %7.3f s   compile %6.3f s  (recompile %5.3f)\n", $label, t, comp, recomp)
        r
    end
end
using Printf

function drive(name, model, inputs)
    println(name); println(stderr, "=== ", name)
    b   = @step "build"            build(model)
    sim = @step "Simulation"       Simulation(b; h = 1//1000)
    @step "init!"                  init!(sim, fragment(; inputs))
    @step "run! 1 s (first)"       run!(sim; t_end = 1.0)
    @step "init! + run! 1 s (warm)" (init!(sim, fragment(; inputs)); run!(sim; t_end = 1.0))
    sim
end

Printf.@printf("using Cadence                   %7.3f s\n", t_load)
drive("M1: README loop (Plant, PI)", loop(Plant(2.0, 0.3)), (ref = 1.0,))
drive("M2: 4x README loop, same types", four(Plant(2.0, 0.3)), (ref = 1.0,))
drive("M3: loop with new type Plant3", loop(Plant3(2.0, 0.3, 0.05)), (ref = 1.0,))
drive("M4: M1 again (all warm)", loop(Plant(2.5, 0.3)), (ref = 1.0,))
