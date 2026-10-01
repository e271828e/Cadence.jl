# A fresh 64-loop `Group` build for `--trace-compile=file --trace-compile-timing`;
# `trace_root.py` lists the roots from the first one naming the 64-loop type.
include(joinpath(@__DIR__, "cum_defs.jl"))
root = many(64)
b = build(root)
