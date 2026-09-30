# Hypothesis: compiling a method that loads a huge inline immutable aggregate
# by value is what costs seconds. Synthetic aggregates, no Cadence: leaves with
# pointer fields, immutable (stored inline) or mutable (stored by reference),
# with homogeneous types (small type string) or one type per leaf (large type
# string). Measured: first-call compile of `h.x` on a mutable holder, and the
# accessor's LLVM IR size.
Base.cumulative_compile_timing(true)
using Printf
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
struct Imm{V}; a::String; b::Base.RefValue{Int}; c::Int; d::Symbol; end
mutable struct Mut{V}; a::String; b::Base.RefValue{Int}; c::Int; d::Symbol; end
struct Chunk{E}; entries::E; s::Vector{Float64}; end        # like the executor's Chunk
mutable struct Holder{T}; x::T; end                          # like Simulation holding the executor
leaf(L, i, hetero) = hetero ? L{i}("p$i", Ref(i), i, :x) : L{0}("p$i", Ref(i), i, :x)
function aggregate(L, N, hetero)   # N leaves in chunks of 16, chunks in a tuple
    chunks = [Chunk(tuple((leaf(L, 16(c - 1) + j, hetero) for j in 1:16)...), zeros(2)) for c in 1:N ÷ 16]
    tuple(chunks...)
end
llvm_lines(f, T) = (io = IOBuffer(); code_llvm(io, f, (T,); debuginfo = :none); count(==('\n'), String(take!(io))))
println("leaf     types    N    sizeof(T) bytes   type-string chars   compile of h.x     LLVM lines")
for (L, ln) in ((Imm, "immut"), (Mut, "mutab")), hetero in (false, true), N in (64, 256, 1024)
    agg = aggregate(L, N, hetero); h = Holder(agg)
    f = @eval (h -> h.x)                                    # a fresh accessor each time
    c0 = ct(); t = @elapsed f(h)
    @printf("%-6s %-9s %5d  %10d  %14d      %6.2f s (%6.2f)   %8d\n", ln, hetero ? "hetero" : "homog", N,
            sizeof(typeof(agg)), length(string(typeof(agg))), t, ct() - c0, llvm_lines(f, typeof(h)))
end
