# entryclosures track: one opaque closure per entry

Patch: `$STUDY/patches/entryclosures.patch` (src/build.jl, src/executor.jl,
src/localization.jl, src/sim.jl, src/store.jl, test/imports.jl, test/utils.jl).
Probe scripts: `$STUDY/ec_probes/` (types.jl, llvm.jl, share.jl, spec2.jl,
world.jl, bench.jl). Raw RESULT lines: `entryclosures_base.txt`,
`entryclosures_ec.txt`, `entryclosures_O0.txt`. Gate log:
`entryclosures_gate.log`. All single runs on a shared machine.

## Harness, -O2, chunk size 16 (seconds; warm in ms per simulated second)

| scenario mode | export | build | sim | walks | init | run | total | warm | alloc_boundary |
|---|---|---|---|---|---|---|---|---|---|
| small cold | base | 7.087 | 2.494 | 0.719 | 1.239 | 1.144 | 12.684 | 1.174 | 0 |
| small cold | ec | 7.222 | 1.992 | 0.024 | 0.841 | 0.658 | 10.737 | 1.156 | 0 |
| small iter | base | 0.779 | 0.425 | 0.414 | 0.609 | 0.830 | 3.056 | 1.177 | 0 |
| small iter | ec | 0.756 | 0.001 | 0.000 | 0.020 | 0.000 | 0.776 | 1.225 | 0 |
| repeated cold | base | 16.343 | 3.158 | 5.433 | 6.741 | 12.997 | 44.672 | 89.085 | 595072 |
| repeated cold | ec | 16.594 | 1.734 | 0.025 | 0.834 | 0.640 | 19.828 | 13.581 | 0 |
| repeated iter | base | 11.674 | 1.441 | 1.208 | 4.531 | 12.229 | 31.082 | 84.459 | 595072 |
| repeated iter | ec | 11.776 | 0.004 | 0.000 | 0.034 | 0.001 | 11.815 | 12.557 | 0 |
| distinct cold | base | 41.682 | 6.583 | 8.686 | 3.384 | 7.878 | 68.213 | 10.655 | 0 |
| distinct cold | ec | 42.314 | 4.975 | 0.026 | 0.820 | 0.644 | 48.779 | 16.678 | 0 |
| distinct iter | base | 10.800 | 3.005 | 8.147 | 2.582 | 7.272 | 31.806 | 10.428 | 0 |
| distinct iter | ec | 11.023 | 0.003 | 0.000 | 0.020 | 0.002 | 11.048 | 14.833 | 0 |

`alloc` and `alloc_at` are 0 everywhere. xhash equals the reference in every
row (small `29ecd83a8ddc20c2`, repeated `2ec2c14b24189565`, distinct
`361f7aeacfda9226`).

## distinct iter at -O0

| export | build | sim | walks | init | run | total | warm | xhash |
|---|---|---|---|---|---|---|---|---|
| base | 0.497 | 0.293 | 7.259 | 0.988 | 0.231 | 9.269 | 20.299 | a47967d1ad0f6779 |
| ec | 0.492 | 0.012 | 0.000 | 0.010 | 0.003 | 0.518 | 26.829 | a47967d1ad0f6779 |

The -O0 hash differs from the -O2 reference on both exports alike.

## LLVM lines, repeated model (`code_llvm`, debuginfo none)

| method | base | ec |
|---|---|---|
| `evaluate!(sim)` | 6330 | 20 |
| `step!(::RK4, sim, ::Float64)` | 18587 | 716 |
| `boundary!(sim, ::Int)` | 4047 | 20 |
| `sweep_2()` | 565 | 90 |
| `sweep_2(::Int)` | 1995 | 139 |

## Code sharing: N loops of one never-compiled type pair, generic machinery warm

| N | export | `Simulation` compile | first walks compile | closures | compiled closure bodies |
|---|---|---|---|---|---|
| 1 | ec | 0.137 | 0.004 | 5 | 5 |
| 8 | ec | 0.158 | 0.004 | 40 | 5 |
| 64 | ec | 0.150 | 0.005 | 320 | 5 |
| 1 | base | 0.554 | 0.145 | | |
| 8 | base | 1.177 | 1.373 | | |
| 64 | base | 2.004 | 5.286 | | |

"Compiled closure bodies" is the number of distinct `specptr`s and of
distinct capture-tuple types over the closures (`spec2.jl`).

## Body runtime (`@belapsed`, warm, ns per call; interior entries in brackets)

| body | distinct base | distinct ec | repeated base | repeated ec |
|---|---|---|---|---|
| `sweep_1()` | 517 (32) | 825 | 772 (64) | 864 |
| `sweep_2()` | 112 (32) | 412 | 905 (64) | 210 |
| `rhs()` | 552 (32) | 1146 | 836 (64) | 901 |

## Opaque-closure call cost on Julia 1.13.0 (`$STUDY/ec_probes/oc_probe*.jl`)

| call form | bytes per call | ns per call (trivial body) |
|---|---|---|
| `Vector{OpaqueClosure{Tuple{},Nothing}}`, `f()` | 48 | 15 to 20 |
| same with an argument or a non-singleton return | 48 to 80 | 16 |
| `Vector{Any}`, `f()` by dynamic dispatch | 0 | 184 |
| abstract eltype, `ccall(f.invoke, …)` (the patch's `_invoke`) | 0 | 8.3 |
| `@cfunction` per entry type over a boxed entry | 0 | 7.1 |
| direct inlined call | 0 | 0.65 |
