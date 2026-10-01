# execB: phase bodies and event walks behind opaque closures

All runs single, `-O2`, chunk 16, on a shared machine (load 4 to 5). Raw lines:
`execB_matrix.txt`, `execB_repeats.txt`, `execB_runtime.txt` beside this file.
"post-build" is `sim + walks + init + run`, the per-topology cost the seam can touch.

## 1. What execA still compiles per fresh topology (trace, before building)

`--trace-compile-timing`, markers between harness steps (driver `execB_probe/attr.jl`,
parser `attr.py` in the scratchpad). Roots in seconds.

| step | root | repeated iter | distinct iter |
|---|---|---|---|
| Simulation | `Base.grow_to!` / `push_widen` / `collect_to_with_first!` / `setindex_widen_up_to` / `push!`, the widening comprehensions in `chunked_body` | 0 | 0.33 |
| Simulation | `Simulation{T,E}` constructor, `Executor` constructor, `PhaseBody` constructors | 0.040 | 0.03 |
| walks | `getproperty(::Executor, :bodies)` and `getproperty(::Simulation)` | 0.012 | 0.009 |
| walks | `PhaseBody{...}()` and `(Int)`, the walks | 0.010 | 3.16 (sweep_1 0.24+0.28, sweep_2 0.11+0.36, rhs 0.33+0.34, ticks(Int) 1.51) |
| init! | `init!(::Simulation{...})`, one root: loop machinery + Establish walks of the sweeps + projection walk | 0.170 | 0.854 |
| init! | `_flat(::Fragment, ..., ::Group{...})`, specialized on the root assembly | 0.033 | 0.021 |
| run! | `kwcall(run!, ::Simulation{...})`, one root: the loop machinery | 0.300 | 0.299 |
| run! | `_record(::Simulation{...})` | 0.004 | 0.004 |

Seam-removable: the `Simulation`/`Executor` constructors, the accessors, the loop part
of `init!` and all of `run!`: about 0.5 s per topology, the same on both scenarios.
Not seam-removable: the walks (per chunk content), the widening comprehensions,
`_flat`. On `distinct`, the walks are 3.2 s of the 4.5 s.

## 2. Separating the effects, `distinct iter` and `repeated iter`

| variant | distinct post-build | repeated post-build |
|---|---|---|
| execA | 4.55, 4.42, 4.49 | 0.56 |
| execA + small means (`patches/execA_small.patch`: `Any[...]` comprehensions; a body with no gated entry walks its interior at every arity) | 3.39, 3.34 | 0.58 |
| B0: seam only, all three arities of all four bodies created eagerly | 5.61, 5.58, 5.85 | 0.07 |
| B1: seam, only the arities the loop runs, nested-closure variant | 3.65 (alloc_at 96) | 0.06 |
| B1 without nesting | 3.21 | 0.07 |
| execB final (B1 + `Any[...]` + `@nospecialize(level)` on `_flat`) | 2.81, 2.87, 2.82 | 0.027 |
| execB_fw (FunctionWrappers, lazy compile) | 3.04 | 0.024 |

Part of the small-means gain is the harness's own pre-call: `rhs(0)` (0.34 s) is
compiled only because `measure.jl` calls it; the loop never does.

## 3. Matrix, execA against execB

| scenario mode | variant | build | sim | walks | init | run | post-build | warm ms/s |
|---|---|---|---|---|---|---|---|---|
| small cold | execA | 7.24 | 2.22 | 0.52 | 0.97 | 0.64 | 4.34 | 1.07 |
| small cold | execB | 7.32 | 2.44 | 0.02 | 0.84 | 0.64 | 3.94 | 1.18 |
| repeated cold | execA | 16.46 | 1.66 | 1.73 | 1.25 | 0.65 | 5.29 | 13.07 |
| repeated cold | execB | 16.64 | 3.49 | 0.03 | 0.87 | 0.67 | 5.06 | 12.33 |
| distinct cold | execA | 42.58 | 4.22 | 3.70 | 1.62 | 0.64 | 10.18 | 8.24 |
| distinct cold | execB | 41.32 | 6.92 | 0.02 | 0.79 | 0.61 | 8.35 | 8.39 |
| small iter | execA | 0.74 | 0.02 | 0.21 | 0.27 | 0.30 | 0.80 | 1.10 |
| small iter | execB | 0.73 | 0.21 | 0.00 | 0.00 | 0.00 | 0.21 | 1.14 |
| repeated iter | execA | 11.30 | 0.04 | 0.02 | 0.20 | 0.30 | 0.56 | 12.75 |
| repeated iter | execB | 11.63 | 0.03 | 0.00 | 0.00 | 0.00 | 0.03 | 12.57 |
| distinct iter | execA | 10.33 | 0.36 | 3.03 | 0.86 | 0.30 | 4.55 | 8.49 |
| distinct iter | execB | 10.57 | 2.81 | 0.00 | 0.00 | 0.00 | 2.81 | 8.28 |
| distinct iter -O0 | execA | 0.48 | 0.15 | 2.08 | 0.37 | 0.11 | 2.71 | 18.81 |
| distinct iter -O0 | execB | 0.45 | 2.12 | 0.00 | 0.00 | 0.00 | 2.13 | 18.05 |

All `alloc`, `alloc_at`, `alloc_boundary` are 0. `xhash` matches the reference at
`-O2` on every row. At `-O0` both exports give `a47967d1ad0f6779`, identical to each
other and different from the `-O2` reference: the optimization level, not the patch.

## 4. Runtime, min of 10 × `run!(t_end = 2)`, one process each (`execB_probe/runtime.jl`)

| scenario | execA ms/s | execB ms/s | execB_fw ms/s | `rhs()` ns A / B / fw |
|---|---|---|---|---|
| small | 1.082 | 1.150 (+6 %) | 1.316 (+22 %) | 60 / 63 / 67 |
| repeated | 11.99 | 12.01 (0 %) | 12.76 (+6 %) | 1014 / 1004 / 1006 |
| distinct | 7.65 | 7.92 (+3.5 %) | 8.12 (+6 %) | 638 / 663 / 705 |

## 5. LLVM lines, `repeated` model (`debuginfo = :none`)

| method | execA | execB |
|---|---|---|
| `evaluate!(sim)` | 47 | 26 |
| `step!(::RK4, sim, h)` | 770 | 722 |
| `boundary!(sim, ::Int)` | 63 | 22 |
| `event_phase!(sim, ::Int)` | 557 | 523 |

`evaluate!` in execB is three loads of `specptr` and three indirect calls, no boxing.
The sizes were already small under execA; the seam's gain is that these methods compile
once per `Simulation{T,...}` type, and that type no longer varies with topology.

## 6. Type identity

`typeof(sim)` for `model(s)` and `previous(s)` is identical for all three scenarios, and
the three scenarios share one type:
`Simulation{Float64, Executor{Float64, StoreBundle{@NamedTuple{var"Core.Float64"::CellStore{Float64}}}, Clock{Float64}, RK4{Float64}}}`
(173 characters, against thousands under execA).

## 7. World age (`execB_probe/world.jl`, `small` model, `x_deriv(::Plant)` redefined after a run)

| export | same sim follows the redefinition | rebuilt sim follows it |
|---|---|---|
| execA | yes | yes |
| execB (`@opaque`) | no: old code, silently | yes |
| execB_fw (FunctionWrappers) | yes | yes |

## 8. Gate failure, mechanism

`trace_discarded_harness` races the inline `HarnessPoker` against a 400-frame replay.
Instrumented in a scratch copy: the poker's loop starts 9.2 to 9.7 ms after `replay!`
begins, in both exports; the replay ends at 10.4 to 10.5 ms (execA, 2 to 3 pokes land),
10.75 ms (execB, `trace` alone, 3 pokes) and 9.28 ms (execB after `devices`, 0 pokes).
The margin is under 1.5 ms in every case. With one `Simulation` type for every model,
`devices` leaves the replay path warm, and the run finishes before the poker's first
stage. The test passes alone, with `trace` alone and four times in a row in one process.
