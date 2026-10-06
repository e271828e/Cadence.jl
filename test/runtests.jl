include("RedstoneTests.jl")
isempty(ARGS) ? RedstoneTests.runall() : RedstoneTests.runonly(ARGS...)
