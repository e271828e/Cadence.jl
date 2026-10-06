# The code a loop method carries per topology, on the `repeated` scenario:
#   julia --project=<export>/test mechanism.jl <label> [chunk_size = 16]
# Prints the executor's inline size and, for three loop methods, the LLVM line
# count, the `memcpy` count and the GC frame's slot count.
using Redstone, InteractiveUtils, Printf
include(joinpath(@__DIR__, "fixtures.jl"))
chunk_size = length(ARGS) > 1 ? parse(Int, ARGS[2]) : 16
sim = Simulation(build(model(:repeated)); h = 1//1000, chunk_size)
S = typeof(sim)
function shape(f, tt)
    ir = sprint(io -> code_llvm(io, f, tt; debuginfo = :none))
    frame = match(r"%gcframe\d* = alloca \[(\d+) x ptr\]", ir)
    (count(==('\n'), ir), length(collect(eachmatch(r"call void @llvm\.memcpy", ir))),
     frame === nothing ? 0 : parse(Int, frame[1]))
end
@printf("MECH label=%s chunk=%d sizeof_exec=%d typeof_sim_chars=%d", ARGS[1], chunk_size,
        sizeof(sim.exec), length(string(S)))
for (name, f, tt) in (("evaluate", Redstone.evaluate!, Tuple{S}),
                      ("rk4_step", Redstone.step!, Tuple{typeof(sim.exec.stepper),S,Float64}),
                      ("event_phase", Redstone.event_phase!, Tuple{S,Int}))
    lines, copies, roots = shape(f, tt)
    @printf(" %s_lines=%d %s_memcpy=%d %s_gcslots=%d", name, lines, name, copies, name, roots)
end
println()
