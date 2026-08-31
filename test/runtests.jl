include("CadenceTests.jl")
isempty(ARGS) ? CadenceTests.runall() : CadenceTests.runonly(ARGS...)
