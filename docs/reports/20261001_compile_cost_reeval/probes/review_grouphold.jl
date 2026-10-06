# A named assembly holding a `Group` in a field declared `::Group`. Base: `Group`
# is a UnionAll, the field is generically held, and a service path past it is
# refused (§13.3, D-130). Erased `Group`: the declared type is concrete.
using Redstone, StaticArrays, LinearAlgebra, ForwardDiff
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))
import Redstone: resolve_condition, PathResolution, DiagnosticError
nested() = Group((; loop = SampledLoop()); inputs = ("in" => "loop/ref",), outputs = ("loop/y" => "y",))
struct GroupHold <: AbstractComponent
    inner::Group
end
Redstone.inner_connections(::GroupHold) = ()
Redstone.u_connections(::GroupHold) = ("ref" => "inner/in",)
Redstone.y_connections(::GroupHold) = ("inner/y" => "y",)
println("isconcretetype(Group) = ", isconcretetype(Group))
b = build(GroupHold(nested()))
q = SVector(0.3, 0.1)
for c in (at("inner/loop", at("plant", fragment(x = (q = q,)))),
          at("inner/loop/plant", fragment(x = (q = q,))))
    try
        resolve_condition(c, b); println("ACCEPTED ", c)
    catch err
        d = err isa DiagnosticError ? (err.carried isa Vector ? first(err.carried) : err.carried) : err
        println("REFUSED reason=", getfield(d, :reason), " segment=", getfield(d, :segment),
                " declared=", getfield(d, :declared))
    end
end
