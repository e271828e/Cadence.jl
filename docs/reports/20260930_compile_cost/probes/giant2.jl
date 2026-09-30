Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
using Base.ScopedValues: with
import Cadence: StructureDraft, flatten!, Diagnostic, BUILD_WARNINGS
m2 = many(2); s2 = Simulation(m2; h = 1//1000); init!(s2, fragment(inputs = (ref = 1.0,))); run!(s2; t_end = 0.01)
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
macro first(label, ex)
    quote
        local c0 = ct(); local t = @elapsed $(esc(ex))
        @printf("  %-58s %6.2f s (compile %6.2f)\n", $label, t, ct() - c0)
    end
end
root = many(64)
println("on the 64-loop Group value (type string: $(length(string(typeof(root)))) chars):")
f1(x) = nothing
f2(x) = (x; nothing)
f3(x) = (c = () -> x; c(); nothing)
f4(x) = with(() -> (x; nothing), BUILD_WARNINGS => Diagnostic[])
f5(x) = (d = StructureDraft(x); with(() -> flatten!(d, x, Diagnostic[]), BUILD_WARNINGS => Diagnostic[]); nothing)
@first "f1(x) = nothing"                                  f1(root)
@first "f2(x) = (x; nothing)"                             f2(root)
@first "f3(x): create and call a closure capturing x"     f3(root)
@first "f4(x): closure capturing x, through with(f, pair)" f4(root)
@first "f5(x): StructureDraft + flatten! under with"      f5(root)
rootany::Any = root
f6(x) = nothing
@first "f6(rootany): same, argument boxed as Any"         f6(rootany)
sim = Simulation(root; h = 1//1000)
println("on the 64-loop Simulation value (type string: $(length(string(typeof(sim)))) chars):")
g1(x) = nothing
g2(x) = x.exec.bodies
g3(x) = x.bodies
g4(x) = x.rhs
g5(x) = (c = () -> x; c(); nothing)
@first "g1(sim) = nothing"                                g1(sim)
@first "g5(sim): create and call a closure capturing sim" g5(sim)
@first "g2(sim) = sim.exec.bodies"                        g2(sim)
@first "g3(exec) = exec.bodies"                           g3(sim.exec)
@first "g4(bodies) = bodies.rhs"                          g4(sim.exec.bodies)
