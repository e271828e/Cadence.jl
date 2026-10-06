include(joinpath(@__DIR__, "heavy_defs.jl"))
import Redstone: Deployment, activation, ProbeDual, ProbeTag, build
const Dual8 = ForwardDiff.Dual{ProbeTag, Float64, 8}
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
bank(N) = Group(NamedTuple{ntuple(i -> Symbol(:b, i), N)}(ntuple(_ -> Group((body = Body(), damper = Damper(0.05));
    wires = ("body/R" => "damper/R", "damper/M" => "body/M"), inputs = ("ω" => "damper/ω",)), N));
    inputs = ("ω" => ntuple(i -> "b$(i)/ω", N),))
function measure(N, T, label)
    b = build(bank(N)); dep = Deployment(b; h = 1//1000)
    c0 = ct(); t_act = @elapsed act = activation(b, T)
    t_cmp = @elapsed exec = Redstone.compile(b, act, dep.schedule; algorithm = dep.algorithm)
    t_body = @elapsed (exec.bodies.sweep_1(); exec.bodies.sweep_2(); exec.bodies.rhs())
    @printf("%-26s N=%2d bodies  activation %5.2f  compile %5.2f  first bodies %5.2f  | total %5.2f s (compile %5.2f)\n",
            label, N, t_act, t_cmp, t_body, t_act + t_cmp + t_body, ct() - c0)
end
measure(2, Float64, "Float64, first in process")
measure(2, ProbeDual, "ProbeDual, first in process")
measure(2, Dual8, "Dual8, first in process")
for N in (8, 32)
    measure(N, Float64, "Float64")
    measure(N, ProbeDual, "ProbeDual (1 partial)")
    measure(N, Dual8, "Dual (8 partials)")
end
