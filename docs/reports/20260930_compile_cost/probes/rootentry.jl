# One fresh root per process, `build` timed at top level with the component
# types already compiled. ROOT=group|bank and N=<loops> select the root:
# `Group` carries its subtree in its type, `Bank` holds it in an abstract field.
Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
import Redstone: child_connections, input_connections, output_connections, transparent_container
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
struct Bank <: AbstractComponent; m::NamedTuple; end
child_connections(::Bank) = ()
transparent_container(::Bank) = :m
input_connections(b::Bank) = ("ref" => ntuple(i -> "m$(i)/ref", length(b.m)),)
output_connections(::Bank) = ()
loops(N) = NamedTuple{ntuple(i -> Symbol(:m, i), N)}(ntuple(i -> loop(Plant(2.0, 0.3)), N))
build(Bank(loops(2)))                                   # warm the Bank path
kind, N = ENV["ROOT"], parse(Int, ENV["N"])
root = kind == "group" ? many(N) : Bank(loops(N))
c0 = ct(); t = @elapsed b = build(root)
@printf("%-6s N=%2d  build %6.2f s  (compile %6.2f)\n", kind, N, t, ct() - c0)
