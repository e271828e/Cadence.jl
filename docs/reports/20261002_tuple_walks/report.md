# Tuple walks past 32 elements, 2026-10-02

Increment 58 replaced every `Base.tail` walk in `src/executor.jl` with a
generated unroll (§9.7, D-289). Its cold reviewer found three things outside
that scope. Two condition-plan walks and the reader gather allocate past 32
elements. And `run!` allocates about 800 B per step on every model. This
report traces the three, sweeps `src/` for the same cliff, prototypes a fix,
and measures it.

## Summary

**The assumption holds for the two named walks.** `_writes!`,
`_sweep_prefixes` and `gather_reads` are reached from `trim!` alone. `trim!`
refuses a running simulation. `linearize` reaches none of them.

**The same cliff sits on the running data plane.** A device's
`gather(handle, snapshot)` and the `map_input` helper use the same `map` over
a tuple. Both break at 32 labels or channels while `run!` runs.

**The larger cost of the condition walks is compile time.** The first call
of the specialized `apply!` takes 1.55 s at 64 writes, 14.2 s at 128 and
202 s at 256. A generated unroll takes 0.09 s, 0.22 s and 0.58 s. §14.4
states a cost of 10 to 50 ms per condition shape. The first `trim!` of a
128-write shape takes 16.9 s today and 2.6 s with the fix.

**The two cliffs have different causes.** Neither is inference giving up.
The `tail` walks keep their types and their static calls. The optimizer
leaves the splat inside `Base.tail` as a runtime call once the tuple has more
than 32 elements. The `map` walks dispatch to Base's fallback for tuples of
32 or more elements, which goes through a `Vector{Any}`.

**The prototype fixes all five sites.** It changes 4 files, adding 28 lines
and removing 21. Every probed call allocates 0 B at every width. The routed
test rows pass, 2483 of 2483.

**The `run!` allocation is publication.** It is 816 B per frame on a small
deviceless model. It grows linearly with the number of frames and is the
same on Julia 1.12. It is the snapshot, the copy of the signal table and the
status vector. §11.2, D-023 and D-241 accept it. §7.5's own text does not
name it.

## 1. Scope and method

**The tree.** Every figure was measured on an export of HEAD `6be1f17`, the
increment 58 tip. `src/conditions.jl`, `src/readers.jl`, `src/bindings.jl`
and `src/executor.jl` are unchanged between `6be1f17` and `08f5dff`, the tip
this report was written at. Two later commits renamed helpers elsewhere in
`src/`. They change no line count and none of the code discussed here. The
patch passes `git apply --check` at `08f5dff`.

**The copies.** `git archive 6be1f17` was unpacked twice, with the root
`Manifest.toml` copied in. `base` is the export as it is. `fix` carries
`patches/walks.patch`. The real tree was not touched.

**The machine.** Apple M4, 10 cores, 16 GB. Every figure is Julia 1.13.0
unless its sentence names Julia 1.12.7. The test runs used the gate's flags.

**How each figure was taken.** Runtime figures are BenchmarkTools'
`@ballocated` and `@belapsed`, the minimum time. Compile figures are
`@elapsed` of the first call in a process. Run figures are `@allocated` of
one `run!` after a warm-up run. The model in most probes is a `Group` of `n`
copies of the test fixture `Sawtooth`, with one continuous state `q` each.
Each probe and its raw output sit in `probes/` and `results/`.

**Widths.** At width `n` a probe builds a condition with `n` writes and `n`
`at` prefixes, or a read set with `n` labels. The standard widths are 31, 32,
33 and 64.

## 2. The mechanism

### 2.1 The `Base.tail` walks trip at 33

`_writes!` and `_sweep_prefixes` (`src/conditions.jl:777–787`) recurse on
`Base.tail`. Base defines `tail(x::Tuple) = argtail(x...)`
(`base/essentials.jl:539`), so every step is a splat.

Inference completes at every width. At 64 elements, `code_typed` of
`_writes!` infers `Nothing` and holds 64 static `:invoke`s. No generic call
is left. `Base.tail` returns a concrete type at 31, 32, 33 and 64.

What survives is the splat. The inliner rewrites `Core._apply_iterate` into a
direct call only when the tuple has at most `max_tuple_splat = 32` elements
(`Compiler/src/ssair/inlining.jl:1031`). Past that the splat stays a runtime
builtin call. That call boxes each element and allocates the tail tuple on
the heap. One such call survives at each level of the recursion whose tuple
is longer than 32.

| width | `_apply_iterate` left in `_writes!` | in `apply!` | `apply!` bytes | `apply!` time |
|---|---|---|---|---|
| 16 | 0 | 0 | 0 | 76 ns |
| 31 | 0 | 0 | 0 | |
| 32 | 0 | 0 | 0 | 150 ns |
| 33 | 1 | 2 | 2176 | 1.39 µs |
| 34 | 2 | 4 | 4384 | |
| 40 | 8 | 16 | 19200 | 11.9 µs |
| 64 | 32 | 64 | 102336 | 65.8 µs |

The count is exactly n − 32 per walk. That is why 32 is clean and 33 is not.
`apply!` runs both walks, which doubles the count.

A six-line walk outside Cadence shows the same thing
(`probes/a_tail_minimal.jl`). On a tuple of `Float64` and `Int` it allocates
0 B at 32, 832 B at 33, 1648 B at 34 and 38624 B at 64. Its time goes from
37 ns at 32 to 954 ns at 33 and 31 µs at 64. Julia 1.12.7 gives the same
bytes.

The recursion is `@inline`, so each level inlines all the rest. The optimized
`apply!` holds 1413 statements at 32 and 6117 at 64. §6.3 shows what that
growth costs in compile time.

### 2.2 The `map` walks trip at 32

`gather_reads` (`src/readers.jl:367`) is
`NamedTuple{L}(map(e -> _read(e, exec), reader.entries))`. Base has a
separate `map` method for long tuples, `map(f, t::Any32)`
(`base/tuple.jl:359–376`). `Any32` matches every tuple of 32 or more
elements. `which` selects `map(f, ::Tuple)` at 31 and the `Any32` method at
32, 33 and 64.

That method fills a `Vector{Any}`. It calls `f` with a runtime index, so
each `_read` is a dynamic dispatch. It then splats the vector back into a
tuple, and the element types are lost. At 32, `gather_reads` returns
`NamedTuple{(:q1, …, :q32)}` with no field types. Every use of the result is
then dynamic too. In `trim!` that use is the author's residual function.

| width | bytes at `Float64` | bytes at the trim's `Dual` activation | time at `Dual` |
|---|---|---|---|
| 31 | 0 | 0 | 0.013 µs |
| 32 | 1888 | 3456 | 1.18 µs |
| 33 | 1920 | 3520 | 1.23 µs |
| 64 | 3712 | 6848 | 2.32 µs |

### 2.3 Why 32 for one and 33 for the other

Both limits are 32, but they bound different things. Dispatch chooses the
`Any32` method when a tuple has 32 elements or more. The splat cap stops the
rewrite only when a tuple has more than 32. A `tail` recursion over 32
elements never splats a tuple longer than 32, so it stays clean.

### 2.4 What sets each width in a user's model

- **`plan.xs`** holds one write per authored `x` field in the whole tree. In
  `trim!` the tree is `override(baseline, condition(d))`. The baseline's
  fields count, not only the decisions.
- **`plan.stores`** holds one write per component whose `s` or `m` is
  overlaid.
- **`plan.inputs`** holds one write per `u` entry.
- **`plan.prefixes`** holds one compare per `at(...)` node, nested ones
  included.
- **`gather_reads`** walks one entry per label in the problem's `reads(...)`.

A baseline written as one `at` per component crosses the limit at 33
components. I read these drivers off `compile_plan` and `_flat`. The probes
confirm the first and the fourth.

## 3. Reach

### 3.1 The call chains

I searched for direct calls and for each function passed as an argument.

- `trim!` (`trim.jl:442`) builds the closure `eval!` (`trim.jl:508`).
  `eval!` calls `apply!(seeded_exec, seeded_plan, tree)` (`trim.jl:510`).
  That `apply!` runs `_sweep_prefixes` once and `_writes!` three times
  (`conditions.jl:764–767`).
- `eval!` calls `gather_reads(seeded_reader, seeded_exec)` (`trim.jl:512`).
- `trim!` calls `gather_reads(reader, nominal_exec)` once (`trim.jl:470`).
- `_verdict!` calls `gather_reads(reader, sim.exec)` once, on convergence
  (`trim.jl:644`).
- `solve` calls `eval!` once per evaluation. `trim!` calls it once more for
  the verdict (`trim.jl:544`).

Nothing else calls the specialized `apply!`, `compile_plan`, `Reader` or
`gather_reads`. `sim.jl:812` and `linearize.jl:147, 167` call the dynamic
two-argument `apply!`. `linearize` reads its taps with its own `_read` loop
over a `Vector{Any}`.

### 3.2 The verdict

All three walks serve a stopped simulation only. `trim!` refuses a `:running`
simulation (`trim.jl:445`). `linearize` calls none of them.

§14.4 says the specialized `apply!` serves "trim's per-evaluation write and
linearization's seeding". The code uses the specialized `apply!` in `trim!`
alone. This report does not rule on which is meant.

### 3.3 The cost per trim

The probe's problem has one decision. It converged in 4 evaluations, so
`eval!` ran 5 times.

| writes | seeded `apply!` per call | bytes | warm `trim!` |
|---|---|---|---|
| 31 | 0.04 µs | 0 | 5.0 ms |
| 33 | 1.32 µs | 2176 | 6.0 ms |
| 64 | 68.5 µs | 102336 | 19.1 ms |
| 128 | 312 µs | 508352 | 84.8 ms |

At 64 writes, five calls cost about 0.34 ms of a 19.1 ms `trim!`, about 2 %.
At 128 writes they cost about 1.6 ms of 84.8 ms. These two products are
computed from the per-call figures, not measured as a whole. At 64 reads,
`gather_reads` costs 2.32 µs per seeded call. Seven calls cost about 16 µs
per trim, also computed.

§14.4 expects 10³ to 10⁴ evaluations per solve. At 64 writes that would put
69 ms to 0.69 s into the walks. This is extrapolated from the per-call
figure, not measured.

The walks do not explain why a warm `trim!` grows with the model. At 128
writes on the fixed copy, `resolve_condition` takes 26.6 ms, `compile_plan`
at the `Dual` activation 28.2 ms, and the `init!` commit 27.1 ms. Together
they are 82 of 86.5 ms. One scratch executor takes 3.0 ms. The base copy
gives 26.4, 25.8, 29.0 and 3.0 ms of 92.8 ms. I did not trace why resolution
grows this way.

The first `trim!` of a new shape pays the compile cost of §6.3.

## 4. The siblings

The sweep covered `Base.tail`, `map`, `foreach`, `ntuple`, `any`, `all`,
`sum`, `reduce`, `mapreduce`, `findfirst`, splats into varargs, `Tuple(...)`,
recursion over a NamedTuple's fields, `Iterators.flatten(map(...))`, and what
every `@generated` body emits. Most hits walk a `Vector`. The table lists the
ones that walk a tuple.

| site | walks | width driver | past 32? | path | 31 / 32 / 33 / 64 |
|---|---|---|---|---|---|
| `conditions.jl:777–787` `_writes!`, `_sweep_prefixes` (`tail`) | plan writes, prefixes | §2.4 | yes | trim | §2.1 |
| `readers.jl:368` `gather_reads` (`map`) | reader entries | labels in `reads` | yes | trim | §2.2 |
| `bindings.jl:132` `gather_snapshot` (`map`) | `ReadGather.entries` | labels in a binding's `reads` | yes, telemetry | running data plane, device task | 0 / 1888 / 1920 / 3712 B; 5.4 ns / 1.18 / 1.16 / 2.23 µs; result not concrete from 32 |
| `bindings.jl:94` `map_input` (`map`) | `keys(datum)` | channels in one datum | yes, large panels | running data plane, staging | 0 / 10592 / 10896 / 38528 B; 11.6 ns / 4.97 / 5.23 / 17.3 µs |
| `conditions.jl:632` `StoreWrite` overlay (`map`) | `w.authored` | fields authored into one `s` or `m` store | uncommon | trim, inside `apply!` | 0 / 11136 / 11968 / 39616 B; 7.8 ns / 3.26 / 3.56 / 8.29 µs |
| `trim.jl:595` `_seeded` (`Dual(v, partials...)` splat) | partials | trim decisions | unrealistic | trim | 16768 / 17824 / 93056 / 343744 B; 1.04 / 1.09 / 54.0 / 191 µs |
| `linearize.jl:384` `_seed` (same splat) | partials | `width` keyword, default 8 | only if set | linearize | 0 / 272 / 1984 / 3792 B; 29.9 / 48.6 / 1554 / 2759 ns |
| `leaves.jl:286–292` `_leaf_values` (`Iterators.flatten(map)`) | fields, `SArray` elements | value shape, an `SMatrix{6,6}` has 36 | yes | per build (`build.jl:115, 335, 1323`, `tracer.jl:142, 167`) | not measured |
| `dataplane.jl:671` `capture_stores` (`map`), `checkpoint.jl:92` (`foreach`) | `StoreBundle.stores` | distinct leaf eltypes | no, a handful | every publication, checkpoint | not measured |
| `dataplane.jl:286–289` `KindCounts` splat and `sum` | 13 fields | fixed | no | diagnostics | not measured |
| `tracer.jl:85–88` `hypot` (`map`, `reduce`) | operands | call arity | no | build | not measured |
| `stepper.jl:60, 96` `ntuple` | literal 5 and 3 | fixed | no | construction | not measured |
| `executor.jl:252, 548`; `build.jl:264, 288, 338, 1048–1425`; `declare.jl:301`; `assembly.jl:82, 207, 238, 499`; `dataplane.jl:529`; `bindings.jl:148` | splats, `map`, `any`, `all` | children, ports, faces | yes | per build or per attach | not measured |
| every `@generated` body | | | | | emits unrolled code, no `map` and no `tail` |

The generated bodies checked are `walk_steps`, `gather_cell`,
`scatter_cell!`, `gather_group`, `scatter_group!`, `_merge`, `_apply!`,
`reconstruct`, `flatten!`, `flatten_state!`, `make_bundle`, `_merge_modes!`
and the executor's walks. `_merge_modes!` emits Base's `merge` on
NamedTuples. That `merge` is generated in Base, but I did not measure it past
32 mode fields.

The `_seeded` figures at 31 and below come from a separate cause, §5.2. The
splat adds the cliff at 33.

## 5. Width-independent findings

These came up in the sweep. None is a 32-element cliff.

### 5.1 A device's gather allocates at every width

`DeviceHandle.gatherer` is a `Union{Nothing,ReadGather}` field
(`devices.jl:63`). `gather(handle, snapshot)` therefore dispatches
dynamically and boxes its result. It allocates 400 B at 31 reads on both
copies, 416 B at 32 and 33, and 688 B at 64 on the fixed copy. It runs on the
device task while the loop runs.

### 5.2 Trim's decisions are not inferred

`_seeded` builds `NamedTuple{decision_names}` from a runtime tuple of names.
Its inferred return type is `NamedTuple{_A, Tuple{Dual, Dual}} where _A`.
`problem.condition(decisions)` and the `apply!` call in `eval!` therefore
dispatch dynamically. `_seeded` allocates 224 B at one decision and 1536 B at
eight.

### 5.3 Staging rebuilds every batch dynamically

`_normalize` (`dataplane.jl:561, 586`) copies the blank batch into a
`Vector{Any}` and splats vectors back into tuples. It is dynamic by
construction at every width. It runs at staging, on the writer's task.

## 6. The prototype

### 6.1 What it changes

The patch changes 4 files, adding 28 lines and removing 21.

- `_writes!` and `_sweep_prefixes` become `@generated` bodies built by
  `_unrolled`.
- `executor.jl` gains one helper beside `_unrolled`, `_unrolled_tuple`.
  `_unrolled` ends in `nothing`, so it cannot build the tuple a `map`
  returns.
- `gather_reads` and `gather_snapshot` share a new generated `_read_all`.
- The `StoreWrite` overlay uses a generated `_overlay`.
- `map_input` becomes a generated unroll over a new `_map_channel`.

`src/Cadence.jl` includes `executor.jl` before `readers.jl`, `bindings.jl`
and `conditions.jl`. Every generator therefore calls only functions defined
before it.

### 6.2 Runtime

| call | width | base | fix |
|---|---|---|---|
| `apply!`, `Float64` | 33 | 2176 B, 1.39 µs | 0 B, 155 ns |
| `apply!`, `Float64` | 64 | 102336 B, 65.8 µs | 0 B, 277 ns |
| seeded `apply!` in trim | 64 | 102336 B, 68.5 µs | 0 B, 0.07 µs |
| seeded `apply!` in trim | 128 | 508352 B, 312 µs | 0 B, 0.14 µs |
| `gather_reads`, `Dual` | 64 | 6848 B, 2.32 µs | 0 B, 0.031 µs |
| `gather_snapshot` | 64 | 3712 B, 2.23 µs | 0 B, 20.6 ns |
| `StoreWrite` overlay | 64 | 39616 B, 8.29 µs | 0 B, 11.4 ns |
| `map_input` | 64 | 38528 B, 17.3 µs | 0 B, 21.5 ns |

Every probed call allocates 0 B on the fixed copy at 31, 32, 33 and 64. The
result types are concrete at every width. A warm `trim!` keeps its time,
since resolution dominates it (§3.3).

### 6.3 Compile time

The table times the first call of the specialized `apply!` and of
`gather_reads` in one process, widths in order. The command is
`WIDTHS=4,8,16,32,64,128 julia --startup-file=no -O2 --project=test probes/d_compile.jl <copy>`.
The first width in a process carries one-time compilation of shared code, so
width 4 reads higher than width 8.

| writes or reads | 4 | 8 | 16 | 32 | 64 | 128 |
|---|---|---|---|---|---|---|
| `apply!`, base | 0.030 s | 0.015 s | 0.031 s | 0.072 s | 1.545 s | 14.1 s |
| `apply!`, fix | 0.062 s | 0.013 s | 0.022 s | 0.041 s | 0.091 s | 0.214 s |
| `gather_reads`, base | 0.004 s | 0.006 s | 0.011 s | 0.006 s | 0.007 s | 0.009 s |
| `gather_reads`, fix | 0.020 s | 0.005 s | 0.006 s | 0.016 s | 0.023 s | 0.059 s |

Wider runs, each a fresh process starting at width 8:

| writes or reads | 64 | 128 | 256 | 512 | 1024 |
|---|---|---|---|---|---|
| `apply!`, base | 1.555 s | 14.2 s | 202 s | | |
| `apply!`, fix | 0.090 s | 0.216 s | 0.579 s | 1.561 s | 4.797 s |
| `gather_reads`, base | 0.008 s | 0.009 s | 0.016 s | | |
| `gather_reads`, fix | 0.023 s | 0.060 s | 0.150 s | 0.312 s | 0.685 s |

The base `gather_reads` compiles fast because its `Any32` path is dynamic.
It pays at run time instead.

The first `trim!` of a new shape, after the loop has compiled:

| writes | base, first | fix, first | base, second | fix, second |
|---|---|---|---|---|
| 8 | 2.34 s | 2.38 s | 1.3 ms | 1.3 ms |
| 64 | 2.76 s | 1.30 s | 19.1 ms | 25.3 ms |
| 128 | 16.9 s | 2.58 s | 98.2 ms | 94.7 ms |

### 6.4 Chunking

The fixed walks do not need chunking at realistic widths. One generated body
of 256 writes compiles in 0.58 s. Its cost grows somewhat faster than the
width, 0.09 s at 64 and 4.8 s at 1024. Chunking would also buy little here.
Each `Authored{P,L}` element carries its own tree position in its type, so
every element type is unique and no two chunks could share a compiled body.
§9.7's chunking gains most of its effect from that sharing. This last point
is reasoned from the types, not measured.

### 6.5 Tests

The routed rows for the touched files ran on the fixed copy under the gate's
flags.

- `readers conditions trim linearize dataplane roster bindings devices trace
  lifecycle log` pass 1825 of 1825 (`results/tests_fix_part1.txt`).
- `executor stepper continuous discrete events localization failures` pass
  658 of 658 (`results/tests_fix_part2.txt`).

## 7. The `run!` allocation

### 7.1 It is per frame

One model, four `Sawtooth`s with no device, runs 100 to 100 000 frames. Each
frame publishes one boundary.

| frames | default | `log = false` | `log = false, trace = false` | one `TailProbe` rostered |
|---|---|---|---|---|
| 100 | 821.9 B | 821.9 B | 821.9 B | 1103.8 B |
| 1 000 | 816.6 B | 816.6 B | 816.6 B | 1089.6 B |
| 10 000 | 816.1 B | 816.1 B | 816.1 B | 1088.3 B |
| 100 000 | 825.8 B | 816.0 B | 816.0 B | 1097.9 B |

The figures are per frame. They stay flat from 1 000 to 100 000 frames, so
the cost is per frame and not per call. The default column's extra at 100 000
frames is the log's retention vector growing. The trace switch changes
nothing. Julia 1.12.7 gives the same figures to the byte, apart from the
device column, which differs by a few bytes per frame.

### 7.2 It is `publish!`

`publish!` alone allocates 816 B. `Profile.Allocs` over a run of 1000 frames
attributes 768 B per frame, at one allocation each.

| line | object | bytes per frame |
|---|---|---|
| `sim.jl:2282`, `_status` | `Memory{WriterStatus}` | 512 |
| `sim.jl:2282`, `_status` | `Vector{WriterStatus}` | 32 |
| `sim.jl:2247`, `publish!`'s release store | the `Snapshot` box | 144 |
| `dataplane.jl:671`, `capture_stores` | `Memory{Float64}` | 48 |
| `dataplane.jl:671`, `capture_stores` | `Vector{Float64}` | 32 |

The profiler did not place the remaining 48 B. `FrameworkStatus`
(`sim.jl:2290`) is a likely home, but I did not verify it. Measured directly,
`capture_stores` allocates 112 B and `_status` 656 B. Nothing else in the
frame allocated even half an allocation per frame.

The cost grows with the table and the roster.

| cells | devices | per frame |
|---|---|---|
| 4 | 0 | 816.3 B |
| 64 | 0 | 1296.3 B |
| 256 | 0 | 2832.3 B |
| 4 | 1 | 1088.9 B |
| 4 | 2 | 1361.2 B |
| 4 | 4 | 1906.0 B |

That fits 784 B, plus 8 B per `Float64` cell, plus about 272 B per rostered
device. The fit is mine. On a small model the status vector is two thirds of
the total.

### 7.3 What the spec says

§11.2 (spec.md:6003) accepts "one snapshot allocation per boundary, on the
framework side of the §7.5 scope". §11.8 (spec.md:7402) says the cells "sit
on the framework side of that scope with publication and logging". D-023 is
ratified and says "allocate per boundary". D-241 is ratified and accepts the
status vector, "one small allocation per publication".

§7.5 itself names logging and not publication. Its first bullet sets the
zero budget for "everything else that runs unconditionally per frame or
boundary". Read literally, that covers publication. The bullet enforces the
budget only at the phase-body seam, and `publish!` is outside it.

## 8. Not checked

- The full gate. Only the routed rows ran.
- The fixed copy on Julia 1.12. Only `a_tail_minimal.jl` and
  `e_run_alloc.jl` ran there.
- Whether §9.7's sentence that past 32 elements a walk's "calls dispatch
  dynamically" describes the executor's old walks. The condition walks keep
  static calls (§2.1).
- Fixes for `_seeded`, `_seed` and the device gather's abstract field.
- Why resolution in `trim!` grows faster than the condition's width.
- `_merge_modes!` with more than 32 mode fields.
- `capture_stores` with more than 32 leaf eltypes.
- The replay path.
- The 48 B per frame that the profiler did not attribute.
