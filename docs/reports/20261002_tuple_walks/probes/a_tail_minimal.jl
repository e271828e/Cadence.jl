# The tail splat in isolation: what survives optimization at 32 and 33 elements.
using InteractiveUtils
const ACC = Ref(0.0)
@noinline sink(x) = (ACC[] += x isa String ? length(x) : Float64(x); nothing)
walk(::Tuple{}) = nothing
@inline walk(t::Tuple) = (sink(first(t)); walk(Base.tail(t)))
measure(t) = @allocated walk(t)
timeit(t) = (t0 = time_ns(); for _ in 1:10_000; walk(t); end; (time_ns() - t0) / 10_000)
for n in (32, 33, 34, 64)
    t = ntuple(i -> isodd(i) ? Float64(i) : i, n)
    s = ntuple(i -> string(i), n)
    ci, rt = only(code_typed(Base.tail, (typeof(t),)))
    surv = [st for st in ci.code if st isa Expr && st.head === :call]
    println("n=$n tail: inferred ", isconcretetype(rt), ", remaining calls: ", isempty(surv) ? "none" : join(unique(string.(first.(getfield.(surv, :args)))), ","))
    ciw, _ = only(code_typed(walk, (typeof(t),)))
    println("      walk: _apply_iterate left ", count(st -> st isa Expr && occursin("_apply_iterate", string(st)), ciw.code))
    measure(t); measure(s); timeit(t)
    println("      walk alloc isbits ", measure(t), " B, strings ", measure(s), " B, ", round(timeit(t), digits = 1), " ns")
end
