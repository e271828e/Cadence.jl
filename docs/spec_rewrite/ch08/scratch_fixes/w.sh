#!/bin/zsh
f=$1; shift
for s in "$@"; do python3 /Users/miguel/.julia/dev/Cadence.jl/docs/spec_rewrite/ch08/scratch_fixes/wrap.py wrap /Users/miguel/.julia/dev/Cadence.jl/docs/spec_rewrite/ch08/units/$f/new.md "$s"; done
