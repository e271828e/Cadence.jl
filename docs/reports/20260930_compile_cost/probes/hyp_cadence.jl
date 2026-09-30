# The same hypothesis on the real executor: accessor compile time against the
# size of the value each accessor returns, and inference vs total.
Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
m2 = many(2); s2 = Simulation(m2; h = 1//1000)
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
sim = Simulation(many(64); h = 1//1000)
exec = sim.exec; bodies = exec.bodies
llvm_lines(f, T) = (io = IOBuffer(); code_llvm(io, f, (T,); debuginfo = :none); count(==('\n'), String(take!(io))))
@printf("sizeof: Executor %d bytes, bodies %d, sweep_2 %d, one chunk %d, one entry %d\n",
        sizeof(typeof(exec)), sizeof(typeof(bodies)), sizeof(typeof(bodies.sweep_2)),
        sizeof(typeof(bodies.sweep_2.interior[1])), sizeof(typeof(bodies.sweep_2.interior[1].entries[1])))
for (label, f, arg) in (("exec.bodies (returns the whole aggregate)", (e -> e.bodies), exec),
                        ("exec.bodies.sweep_2 (one body)", (e -> e.bodies.sweep_2), exec),
                        ("exec.bodies.sweep_2.interior[1] (one chunk)", (e -> e.bodies.sweep_2.interior[1]), exec),
                        ("exec.bodies.sweep_2.interior[1].entries[1] (one entry)", (e -> e.bodies.sweep_2.interior[1].entries[1]), exec),
                        ("...entries[1].path (a String out of the aggregate)", (e -> e.bodies.sweep_2.interior[1].entries[1].path), exec),
                        ("(exec.bodies; nothing): load, no return", (e -> (e.bodies; nothing)), exec),
                        ("exec.xbuf (a Vector field)", (e -> e.xbuf), exec))
    c0 = ct(); t = @elapsed f(arg)
    @printf("  %-56s %6.2f s (compile %6.2f)  LLVM lines %7d\n", label, t, ct() - c0, llvm_lines(f, typeof(arg)))
end
