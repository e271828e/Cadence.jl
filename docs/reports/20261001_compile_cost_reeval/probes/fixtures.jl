# Fixtures of the re-evaluation: components with real arithmetic and the three
# scenarios. Every component family is defined by name, so the distinct-type
# scenario gets one textually identical copy per instance.
using Redstone, StaticArrays, LinearAlgebra
import Redstone: AbstractComponent, x_init, s_init, u_types, y_types,
    y_state, y_direct, x_deriv, s_update, x_projection,
    Group, Absolute, Hz, Simulation, init!, run!, fragment, build

const V3 = SVector{3,Float64}
const M3 = SMatrix{3,3,Float64,9}

function rotmat(q)
    w, x, y, z = q
    @SMatrix [1-2(y^2+z^2)  2(x*y-w*z)   2(x*z+w*y);
              2(x*y+w*z)   1-2(x^2+z^2) 2(y*z-w*x);
              2(x*z-w*y)   2(y*z+w*x)   1-2(x^2+y^2)]
end

# A rigid body's attitude: quaternion kinematics and Euler's equations.
function define_body(name::Symbol)
    @eval begin
        struct $name <: AbstractComponent
            J::M3
            Jinv::M3
        end
        $name() = (J = M3(2.0, 0.1, 0.0, 0.1, 3.0, 0.0, 0.0, 0.0, 4.0); $name(J, inv(J)))
        x_init(::$name) = (q = SVector(1.0, 0.0, 0.0, 0.0), ω = V3(0.1, 0.2, 0.3))
        u_types(::$name) = (M = V3,)
        y_types(::$name) = (R = M3, ω = V3, h = V3, KE = Float64, P = Float64)
        y_state(b::$name, (; x)) =
            (R = rotmat(x.q), ω = x.ω, h = b.J * x.ω, KE = 0.5 * dot(x.ω, b.J * x.ω))
        y_direct(::$name, (; x, u)) = (P = dot(u.M, x.ω),)
        function x_deriv(b::$name, (; x, u, y))
            ω = x.ω
            Ω = @SMatrix [0 -ω[1] -ω[2] -ω[3]; ω[1] 0 ω[3] -ω[2];
                          ω[2] -ω[3] 0 ω[1]; ω[3] ω[2] -ω[1] 0]
            (q = 0.5 * Ω * x.q, ω = b.Jinv * (u.M - cross(ω, y.h)))
        end
        x_projection(::$name, x) = (q = x.q / norm(x.q), ω = x.ω)
    end
end

# A discrete rate controller with an integrator and a body-frame damping term.
function define_ctl(name::Symbol)
    @eval begin
        struct $name <: AbstractComponent
            K_p::M3
            k_i::Float64
            k_d::Float64
        end
        $name() = $name(M3(4.0, 0.2, 0.0, 0.2, 5.0, 0.0, 0.0, 0.0, 6.0), 0.5, 0.1)
        s_init(::$name) = (integral = V3(0.0, 0.0, 0.0),)
        u_types(::$name) = (rate_ref = V3, ω = V3, R = M3)
        y_types(::$name) = (M = V3,)
        y_direct(c::$name, (; s, u)) =
            (M = c.K_p * (u.rate_ref - u.ω) + s.integral - c.k_d * (u.R' * (u.R * u.ω)),)
        s_update(c::$name, (; s, u, Δt)) =
            (integral = s.integral + c.k_i * Δt * (u.rate_ref - u.ω),)
    end
end

# A continuous algebraic damper.
function define_damper(name::Symbol)
    @eval begin
        struct $name <: AbstractComponent; c::Float64; end
        $name() = $name(0.4)
        x_init(::$name) = (;)
        u_types(::$name) = (R = M3, ω = V3)
        y_types(::$name) = (M = V3,)
        y_direct(d::$name, (; u)) = (M = -d.c * (u.R' * (u.R * u.ω)),)
    end
end

# The README's scalar loop.
function define_plant(name::Symbol)
    @eval begin
        struct $name <: AbstractComponent; ω::Float64; ζ::Float64; end
        $name() = $name(2.0, 0.3)
        x_init(::$name) = (q = 0.0, v = 0.0)
        u_types(::$name) = (u = Float64,)
        y_types(::$name) = (y = Float64, power = Float64)
        y_state(::$name, (; x)) = (y = x.q,)
        y_direct(::$name, (; x, u)) = (power = u.u * x.v,)
        x_deriv(p::$name, (; x, u)) = (q = x.v, v = -p.ω^2 * x.q - 2p.ζ * p.ω * x.v + u.u)
    end
end
function define_pi(name::Symbol)
    @eval begin
        struct $name <: AbstractComponent; k_p::Float64; k_i::Float64; end
        $name() = $name(3.0, 2.0)
        s_init(::$name) = (integral = 0.0,)
        u_types(::$name) = (ref = Float64, y = Float64)
        y_types(::$name) = (u = Float64,)
        y_direct(c::$name, (; s, u)) = (u = c.k_p * (u.ref - u.y) + s.integral,)
        s_update(c::$name, (; s, u, Δt)) = (integral = s.integral + c.k_i * Δt * (u.ref - u.y),)
    end
end

const N_DISTINCT = 32
define_body(:Body); define_ctl(:AttCtl); define_damper(:Damper); define_plant(:Plant); define_pi(:PI)
define_body(:WBody); define_ctl(:WCtl); define_damper(:WDamper); define_plant(:WPlant); define_pi(:WPI)
for k in 1:N_DISTINCT
    define_body(Symbol(:Body, k)); define_ctl(Symbol(:AttCtl, k))
end
make(name::Symbol) = getfield(Main, name)()

# The three subassemblies.
attloop(body, ctl) = Group((body = body, ctl = ctl);
    wires = ("ctl/M" => "body/M", "body/ω" => "ctl/ω", "body/R" => "ctl/R"),
    inputs = "rate_ref" => "ctl/rate_ref", outputs = "body/KE" => "KE",
    rates = (ctl = Absolute(Hz(50)),))
damped(body, damper) = Group((body = body, damper = damper);
    wires = ("damper/M" => "body/M", "body/ω" => "damper/ω", "body/R" => "damper/R"),
    outputs = "body/KE" => "KE")
scalarloop(plant, ctl) = Group((plant = plant, ctl = ctl);
    wires = ("ctl/u" => "plant/u", "plant/y" => "ctl/y"),
    inputs = "ref" => "ctl/ref", outputs = "plant/y" => "y",
    rates = (ctl = Absolute(Hz(50)),))

# A root over named attitude loops, one fanned rate reference.
function attroot(names, loops)
    Group(NamedTuple{Tuple(names)}(Tuple(loops));
          inputs = ("rate_ref" => Tuple("$(n)/rate_ref" for n in names),))
end
function smallroot(names)
    parts = (a1 = () -> attloop(Body(), AttCtl()), a2 = () -> attloop(Body(), AttCtl()),
             d1 = () -> damped(Body(), Damper()), d2 = () -> damped(Body(), Damper()),
             l1 = () -> scalarloop(Plant(), PI()))
    Group(NamedTuple{names}(Tuple(parts[n]() for n in names));
          inputs = ("rate_ref" => Tuple("$(n)/rate_ref" for n in names if startswith(String(n), "a")),
                    "ref" => "l1/ref"))
end
distinct_loop(k) = attloop(make(Symbol(:Body, k)), make(Symbol(:AttCtl, k)))

"""
The measured model of a scenario.

- `:small`: 10 components of 5 types.
- `:repeated`: 64 attitude loops, 128 components of 2 types.
- `:distinct`: 32 attitude loops, 64 components of 64 types.
"""
function model(scenario::Symbol)
    scenario === :small && return smallroot((:a1, :a2, :d1, :d2, :l1))
    scenario === :repeated &&
        return attroot([Symbol(:m, i) for i in 1:64], [attloop(Body(), AttCtl()) for _ in 1:64])
    scenario === :distinct &&
        return attroot([Symbol(:m, i) for i in 1:N_DISTINCT], [distinct_loop(i) for i in 1:N_DISTINCT])
    error("unknown scenario $scenario")
end

"""
The model an iteration session held before the measured one: the same
component and subassembly types under another topology.

- `:small`: the model without `d2`.
- `:repeated`: 63 loops.
- `:distinct`: the same 32 loops rotated by one, so every type is known and
  every chunk's content shifts.
"""
function previous(scenario::Symbol)
    scenario === :small && return smallroot((:a1, :a2, :d1, :l1))
    scenario === :repeated &&
        return attroot([Symbol(:m, i) for i in 1:63], [attloop(Body(), AttCtl()) for _ in 1:63])
    if scenario === :distinct
        order = [2:N_DISTINCT; 1]
        return attroot([Symbol(:m, i) for i in order], [distinct_loop(i) for i in order])
    end
    error("unknown scenario $scenario")
end

# A model of other types that exercises the same generic paths.
unrelated() = Group((a = attloop(WBody(), WCtl()), d = damped(WBody(), WDamper()),
                     l = scalarloop(WPlant(), WPI()));
                    inputs = ("rate_ref" => "a/rate_ref", "ref" => "l/ref"))

condition(scenario::Symbol) = scenario === :small ?
    fragment(u = (rate_ref = V3(0.0, 0.0, 0.1), ref = 1.0)) :
    fragment(u = (rate_ref = V3(0.0, 0.0, 0.1),))
unrelated_condition() = fragment(u = (rate_ref = V3(0.0, 0.0, 0.1), ref = 1.0))
