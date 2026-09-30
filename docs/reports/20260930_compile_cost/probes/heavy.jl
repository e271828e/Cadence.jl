# A StaticArrays-heavy continuous component (rigid-body attitude with a 3x3
# inertia and a quaternion), to price the optimization level on real math.
using Cadence, StaticArrays, LinearAlgebra, BenchmarkTools, Printf
import Cadence: AbstractComponent, x_init, u_types, y_types, y_state, y_direct,
    x_derivative, x_projection, Group, Simulation, init!, run!, fragment, phase_bodies

struct Body <: AbstractComponent
    J::SMatrix{3,3,Float64,9}
    Jinv::SMatrix{3,3,Float64,9}
end
Body() = (J = SMatrix{3,3}(2.0, 0.1, 0.0, 0.1, 3.0, 0.0, 0.0, 0.0, 4.0); Body(J, inv(J)))
x_init(::Body) = (q = SVector(1.0, 0.0, 0.0, 0.0), ω = SVector(0.1, 0.2, 0.3))
u_types(::Body) = (M = SVector{3,Float64},)
y_types(::Body) = (R = SMatrix{3,3,Float64,9}, h = SVector{3,Float64}, KE = Float64)
function rotmat(q)
    w, x, y, z = q
    @SMatrix [1-2(y^2+z^2)  2(x*y-w*z)   2(x*z+w*y);
              2(x*y+w*z)   1-2(x^2+z^2) 2(y*z-w*x);
              2(x*z-w*y)   2(y*z+w*x)   1-2(x^2+y^2)]
end
y_state(b::Body, (; x)) = (R = rotmat(x.q), h = b.J * x.ω, KE = 0.5 * dot(x.ω, b.J * x.ω))
function x_derivative(b::Body, (; x, u, y))
    ω = x.ω
    Ω = @SMatrix [0 -ω[1] -ω[2] -ω[3]; ω[1] 0 ω[3] -ω[2]; ω[2] -ω[3] 0 ω[1]; ω[3] ω[2] -ω[1] 0]
    (q = 0.5 * Ω * x.q, ω = b.Jinv * (u.M - cross(ω, y.h)))
end
x_projection(::Body, x) = (q = x.q / norm(x.q), ω = x.ω)

struct Damper <: AbstractComponent; c::Float64; end
x_init(::Damper) = NamedTuple()
u_types(::Damper) = (R = SMatrix{3,3,Float64,9}, ω = SVector{3,Float64})
y_types(::Damper) = (M = SVector{3,Float64},)
y_direct(d::Damper, (; u)) = (M = -d.c * (u.R' * (u.R * u.ω)),)

N = 32
model = Group(NamedTuple{ntuple(i -> Symbol(:b, i), N)}(ntuple(_ -> Group((body = Body(), damper = Damper(0.05));
    wires = ("body/R" => "damper/R", "damper/M" => "body/M"),
    inputs = ("ω" => "damper/ω",)), N));
    inputs = ("ω" => ntuple(i -> "b$(i)/ω", N),))
t_c = @elapsed sim = Simulation(model; h = 1//1000)
t_i = @elapsed init!(sim, fragment(inputs = (ω = SVector(0.0, 0.0, 0.0),)))
t_r = @elapsed run!(sim; t_end = 0.01)
init!(sim, fragment(inputs = (ω = SVector(0.0, 0.0, 0.0),)))
t_w = @elapsed run!(sim; t_end = 10.0)
bodies = phase_bodies(sim)
@printf("opt=%d  %d bodies: first sim %.2f s (Sim %.2f, init %.2f, run %.2f)  warm %.1f ms per sim-second   rhs %.0f ns alloc %d   sweep_1 %.0f ns alloc %d\n",
        Base.JLOptions().opt_level, N, t_c + t_i + t_r, t_c, t_i, t_r, t_w * 100,
        (@belapsed $(bodies.rhs)()) * 1e9, @ballocated($(bodies.rhs)()),
        (@belapsed $(bodies.sweep_1)()) * 1e9, @ballocated($(bodies.sweep_1)()))
