# A REPL session with the framework and the suite's fixtures in `Main`, no
# import typed: from the repository root,
#
#     julia --project=test -L test/repl.jl
#
# The names come from `imports.jl`, the suite's own list; the fixtures are the
# components, assemblies, devices and bindings the tests build models from.
using Cadence, StaticArrays, LinearAlgebra, ForwardDiff
include(joinpath(@__DIR__, "imports.jl"))
include(joinpath(@__DIR__, "fixtures.jl"))
