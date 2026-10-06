# C: the hot and service siblings at widths 31, 32, 33, 64.
using Redstone, BenchmarkTools, StaticArrays, LinearAlgebra
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))

# A discrete component whose `s` has n fields, for StoreWrite's overlay map.
function define_wide(n)
    name = Symbol(:WideS, n)
    fields = Tuple(Symbol(:f, i) for i in 1:n)
    @eval begin
        struct $name <: AbstractComponent end
        Redstone.s_init(::$name) = NamedTuple{$fields}(ntuple(_ -> 0.0, $n))
        Redstone.y_types(::$name) = (o = Float64,)
        Redstone.y_state(::$name, (; s)) = (o = s.f1,)
        Redstone.s_update(::$name, (; s)) = s
    end
    getfield(Main, name)
end

function gather_case(n)
    root = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
    sim = Simulation(root; h = 1//10)
    handle = attach!(sim, Pad("t"), Readout(; (Symbol(:q, i) => get_output("s$i", "q") for i in 1:n)...))
    init!(sim, fragment())
    snapshot = latest(sim)
    g = handle.gatherer
    gather(handle, snapshot); gather_snapshot(g, snapshot)
    rt = only(Base.return_types(gather_snapshot, (typeof(g), typeof(snapshot))))
    println("n=$n gather(handle, snapshot) ", @ballocated(gather($handle, $snapshot)), " B ",
            round(@belapsed(gather($handle, $snapshot)) * 1e9, digits = 1), " ns | gather_snapshot ",
            @ballocated(gather_snapshot($g, $snapshot)), " B ",
            round(@belapsed(gather_snapshot($g, $snapshot)) * 1e9, digits = 1), " ns, concrete return ",
            isconcretetype(rt))
end

function storewrite_case(W, n)
    sim = Simulation(Group((; w = W())); h = 1//10)
    tree = at("w", fragment(s = NamedTuple{Tuple(Symbol(:f, i) for i in 1:n)}(ntuple(i -> 0.5i, n))))
    plan = compile_plan(tree, sim.deployment.build)
    apply!(sim.exec, plan, tree)
    println("n=$n StoreWrite overlay: stores=", length(plan.stores), " xs=", length(plan.xs),
            " apply! ", @ballocated(apply!($(sim.exec), $plan, $tree)), " B ",
            round(@belapsed(apply!($(sim.exec), $plan, $tree)) * 1e9, digits = 1), " ns")
end

for n in parse.(Int, split(get(ENV, "WIDTHS", "31,32,33,64"), ","))
    gather_case(n)
end
for n in parse.(Int, split(get(ENV, "WIDTHS", "31,32,33,64"), ","))
    W = define_wide(n)
    Base.invokelatest(storewrite_case, W, n)
end
