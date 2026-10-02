# A: where inference gives up, for Base.tail, the two conditions.jl walks, and gather_reads.
using Cadence, BenchmarkTools, StaticArrays, LinearAlgebra, InteractiveUtils
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))

println("== Base.tail return type, heterogeneous tuple of n elements")
for n in parse.(Int, split(get(ENV, "WIDTHS", "31,32,33"), ","))
    TT = Tuple{(isodd(i) ? Float64 : Int for i in 1:n)...}
    rt = only(Base.return_types(Base.tail, (TT,)))
    println("n=$n tail -> ", rt === Tuple ? "Tuple (widened)" : "concrete $(length(rt.parameters))-tuple")
    rt2 = only(Base.return_types(Base.argtail, TT.parameters |> Tuple))
    println("      argtail(x...) direct (not splatted) -> ", isconcretetype(rt2))
end

function model(n)
    root = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
    Simulation(root; h = 1//10)
end

dyn(ci) = count(st -> st isa Expr && st.head === :call && !(st.args[1] isa GlobalRef && st.args[1].mod === Core && st.args[1].name in (:getfield, :tuple, :(===), :isa, :typeassert, :setfield!, :_apply_iterate)) && !(st.args[1] isa GlobalRef && st.args[1].mod === Base), ci.code)
function report(label, ci, rt)
    calls = [st for st in ci.code if st isa Expr && st.head === :call]
    invokes = count(st -> st isa Expr && st.head === :invoke, ci.code)
    apply = count(st -> st isa Expr && st.head === :call && occursin("_apply_iterate", string(st.args[1])), ci.code)
    generic = [string(st.args[1]) for st in calls if !(st.args[1] isa GlobalRef && st.args[1].mod in (Core, Core.Intrinsics, Base))]
    println(label, ": return ", rt, "; statements ", length(ci.code), ", :invoke ", invokes,
            ", _apply_iterate ", apply, ", generic :call ", isempty(generic) ? "none" : join(unique(generic), ","))
end

for n in parse.(Int, split(get(ENV, "WIDTHS", "31,32,33"), ","))
    sim = model(n)
    # writes only: one `at` per component, all under one Combined -> prefixes == xs == n
    tree = combine((at("s$i", fragment(x = (q = 0.25 + i,))) for i in 1:n)...)
    plan = compile_plan(tree, sim.deployment.build)
    exec = sim.exec
    for (lbl, f, args) in (("_writes!(xs)", Cadence._writes!, (plan.xs, exec, tree)),
                           ("_sweep_prefixes", Cadence._sweep_prefixes, (plan.prefixes, tree)),
                           ("apply!", apply!, (exec, plan, tree)))
        (ci, rt) = only(code_typed(f, typeof.(args); optimize = true))
        report("n=$n $lbl", ci, rt)
    end
    # The splat in tail, seen in the unoptimized first recursion step
    (ci, rt) = only(code_typed(Cadence._writes!, typeof.((plan.xs, exec, tree)); optimize = false))
    tails = [ci.ssavaluetypes[i] for (i, st) in enumerate(ci.code) if st isa Expr && st.head === :call && occursin("tail", string(st.args[1]))]
    println("    unoptimized _writes!: Base.tail(writes) inferred as ", tails)
    # gather_reads
    spec = reads(; (Symbol(:q, i) => get_state("s$i", :q) for i in 1:n)...)
    reader = Cadence._compile_reads(spec, sim.deployment.build, Float64)
    (ci, rt) = only(code_typed(gather_reads, typeof.((reader, exec)); optimize = true))
    report("n=$n gather_reads", ci, rt)
    m = which(map, Tuple{Function, typeof(reader.entries)})
    println("    map method selected: ", m.sig)
    println("    bytes ", (gather_reads(reader, exec); @ballocated gather_reads($reader, $exec)),
            "  apply! bytes ", (apply!(exec, plan, tree); @ballocated apply!($exec, $plan, $tree)))
end
