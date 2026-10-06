# The Dual activation: probes and layout (`activation`), executor compile, and
# the first call of each interior body, per model size, at 1 and 8 partials.
Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
using ForwardDiff
import Redstone: Deployment, activation, ProbeDual, ProbeTag
const Dual8 = ForwardDiff.Dual{ProbeTag, Float64, 8}
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
function measure(N, T, label)
    b = build(many(N)); dep = Deployment(b; h = 1//1000)
    c0 = ct(); t_act = @elapsed act = activation(b, T)
    t_cmp = @elapsed exec = Redstone.compile(b, act, dep.schedule; algorithm = dep.algorithm)
    t_body = @elapsed (exec.bodies.sweep_1(); exec.bodies.sweep_2(); exec.bodies.rhs())
    n = length(b.structure.components)
    @printf("%-28s N=%2d loops (%3d components)  activation %5.2f  compile %5.2f  first bodies %5.2f  | total %5.2f s (compile %5.2f)\n",
            label, N, n, t_act, t_cmp, t_body, t_act + t_cmp + t_body, ct() - c0)
end
measure(2, ProbeDual, "ProbeDual, first in process")
measure(2, Dual8, "Dual8, first in process")
for N in (4, 16, 64)
    measure(N, ProbeDual, "ProbeDual (1 partial)")
    measure(N, Dual8, "Dual (8 partials)")
end
# for reference, the same three steps at Float64 on a fresh 65-loop model
b = build(many(65)); dep = Deployment(b; h = 1//1000)
c0 = ct(); t = @elapsed (act = activation(b, Float64); exec = Redstone.compile(b, act, dep.schedule; algorithm = dep.algorithm); exec.bodies.sweep_1(); exec.bodies.sweep_2(); exec.bodies.rhs())
@printf("%-28s N=65 loops: activation+compile+first bodies %5.2f s (compile %5.2f)\n", "Float64, for reference", t, ct() - c0)
