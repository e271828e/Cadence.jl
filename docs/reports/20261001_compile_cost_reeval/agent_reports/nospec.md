# nospec track: the declaration layer stops specializing on component and root types

Patch: `$STUDY/patches/nospec.patch` (467 lines, `src/assembly.jl`, `src/build.jl`,
`src/declare.jl`). Julia 1.13.0, single runs, machine shared with other agents
(load average 5 to 6). Traces use `--startup-file=no`; the harness runs used the
command as given.

## 1. Harness, chunk size 16, `-O2`

`build=` in seconds. Every `xhash` equals the base export's and the reference
values. The harness gained a `construct=` column partway through the batch (the
first three base rows lack it); `build=` is timed the same way in both versions.

| scenario | mode | base build | nospec build | base sim / walks / init / run | nospec sim / walks / init / run |
|---|---|---|---|---|---|
| small | cold | 7.156 | 4.902 | 2.52 / 0.69 / 1.32 / 1.25 | 2.44 / 0.65 / 1.22 / 1.14 |
| small | types | 3.005 | 0.077 | 0.94 / 0.52 / 0.61 / 0.82 | 0.87 / 0.50 / 0.63 / 0.82 |
| small | iter | 0.746 | 0.003 | 0.42 / 0.41 / 0.59 / 0.81 | 0.42 / 0.42 / 0.60 / 0.83 |
| repeated | cold | 16.610 | 4.821 | 3.23 / 5.26 / 6.36 / 12.43 | 3.22 / 5.48 / 6.50 / 12.82 |
| repeated | types | 12.384 | 0.106 | 1.99 / 5.06 / 5.70 / 12.04 | 2.02 / 5.23 / 5.59 / 12.79 |
| repeated | iter | 11.797 | 0.077 | 1.53 / 1.22 / 4.57 / 12.41 | 1.59 / 1.34 / 4.73 / 12.62 |
| distinct | cold | 42.233 | 5.242 | 6.46 / 8.78 / 3.25 / 7.82 | 6.35 / 8.48 / 3.25 / 7.76 |
| distinct | types | 38.640 | 0.724 | 5.37 / 8.92 / 2.68 / 7.31 | 5.12 / 8.84 / 2.83 / 7.50 |
| distinct | iter | 11.119 | 0.017 | 3.04 / 8.43 / 2.62 / 7.38 | 3.08 / 8.21 / 2.67 / 7.38 |

Warm runtime (`warm_ms_per_s`) and the three allocation counts are unchanged:
`alloc_boundary=595072` on `repeated` in both, as the brief expects.

`distinct types` at `-O0`, two runs each:

| | build | sim | walks | init | run | xhash |
|---|---|---|---|---|---|---|
| base | 11.631 / 12.205 | 1.06 / 1.16 | 7.79 / 8.13 | 1.05 / 1.13 | 0.24 / 0.25 | a47967d1ad0f6779 |
| nospec | 0.273 / 0.271 | 0.96 / 0.96 | 7.66 / 8.06 | 3.91 / 1.21 | 0.53 / 0.27 | a47967d1ad0f6779 |

The first nospec `init` and `run` were load noise; the rerun matches base.

## 2. Per new component type and per new root

From `nospec_work/trace.jl`: one warm `build`, then the measured `build` between
two markers, compile seconds from `Base.cumulative_compile_time_ns`.
`distinct iter` is a new root over known types. `distinct types` adds 64
component types and 32 loop `Group` types.

| | base | nospec |
|---|---|---|
| new root, 32 loops of 64 known types (`distinct iter`) | 10.45 s | 0.010 s |
| new root, 64-loop `Group` (`repeated iter`) | 11.16 s | 0.053 s |
| 64 new component types + their root (`distinct types`) | 37.05 s | 0.825 s |
| per new component type, (types − iter) / 64 | 0.416 s | 0.0127 s |
| of which the user's own stage methods | — | 0.0117 s |

Base attribution, `distinct types`: `_walk!` 17.65 s (96 instances), `build` 10.20 s
(1 instance), `at_component` closures 4.95 s (288), `invoke_probed` 1.34 s (160),
`bundle_names` 0.65 s, `_workspace` 0.38 s, `declarations` 0.37 s,
`declared_at` 0.34 s. Base `distinct iter` and `repeated iter`: one `build`
instance each (10.29 s, 10.58 s), plus `Base.count` over the root's children
(0.14 s, 0.37 s).

Round 1 (the 21 signatures, the root entry, `resolve_terminal`, `_one_level`,
`_declares`, `StructureDraft`, and two closures switched to index capture),
`distinct types`, 7.28 s traced:

| unit | s | instances |
|---|---|---|
| `at_component` closures of `_probe_direct!` | 1.761 | 64 |
| `at_component` closures of `probe_stage2` | 1.751 | 96 |
| `at_component` closures of `probe_stage1` | 0.767 | 64 |
| `bundle_names` | 0.658 | 64 |
| `invoke_probed` (`y_direct`, `y_state`, `x_deriv`, `s_update`) | 1.269 | 160 |
| `Base.count` over a container | 0.378 | 34 |
| `_contract` | 0.230 | 64 |
| `Pair(::String, ::Group{…})` | 0.230 | 98 |

Round 2 (probe closures read the instance instead of capturing it;
`invoke_probed`, `bundle_names`, `event_bundle_names`, `has_stage`, `_contract`,
`_declares_workspace` unspecialized; `_children` walks containers as `Vector{Any}`;
`Pair{String,Any}` built directly), `distinct types`, 0.804 s traced:

| unit | s | instances |
|---|---|---|
| `y_direct` (user methods, compiled by the probe) | 0.224 | 64 |
| `x_deriv` | 0.155 | 32 |
| `y_state` | 0.149 | 32 |
| `x_projection` | 0.126 | 32 |
| `s_update` | 0.094 | 32 |
| `_entry`, `_fanout`, `_check_face_names`, `indexed_iterate`, `_array_for` (root) | 0.056 | 6 |

## 3. Input for the Group track: the 64-loop `Group` root after the patch

`repeated iter` (new root, known types): `build` 0.075 s wall, 0.053 s compile,
0.043 s traced:

| function | s | signature key |
|---|---|---|
| `_entry` | 0.015 | `Pair{String, NTuple{64,String}}` |
| `_check_face_names` | 0.011 | `Tuple{Pair{String, NTuple{64,String}}}` |
| `_fanout` | 0.009 | `NTuple{64,String}` |
| `Base.indexed_iterate` ×2 | 0.005 | `Pair{String, NTuple{64,String}}` |
| `Base._array_for` | 0.003 | `Tuple{Pair{String, NTuple{64,String}}}` |

None of these is keyed on the `Group`'s children. All five come from the root's
fanned input `"rate_ref" => Tuple(64 paths)`. `@nospecialize` on the three Redstone
functions was tried and reverted: the same 43 ms moved into `Base.repr`,
`Base.reduce` and a `Generator` constructor over the same tuple.

What the `Group` type still costs outside `build`, measured on this patch
(`nospec_work/static2.jl`): compiling any function that takes the 64-loop root
concretely costs about 0.2 s, even one that only returns `(r, 1)` (0.261 s);
a wrapper calling `build(r)` costs 0.234 s, and one calling
`build(Base.inferencebarrier(r))` costs 0.192 s. The harness's `construct=`
column, the model's construction, is 0.42 s for `repeated`.

## 4. Warm `build` runtime

Second and later builds of the same model in one process, 20 builds,
`nospec_work/warm.jl`, two processes each:

| scenario | base min / median ms | nospec min / median ms | base alloc | nospec alloc |
|---|---|---|---|---|
| small | 1.88–1.90 / 1.93 | 1.99–2.01 / 2.00–2.03 | 1.39 MB | 1.27 MB |
| repeated | 36.1–36.4 / 36.9–37.4 | 29.4–30.6 / 31.5–33.0 | 135.1 MB | 24.8 MB |
| distinct | 14.6–15.5 / 18.3–18.4 | 14.1–14.8 / 14.9–15.7 | 17.0 MB | 10.6 MB |

`small` is about 5% slower: dynamic dispatch in place of static calls.
`repeated` is about 17% faster. Base `_children` on the 64-loop root allocates
1.87 MB per call (0.12 MB patched). `_one_level` calls it once for every root-level
wire endpoint, so base `flatten!` allocates 130.7 MB on that root, 20.5 MB patched
(`nospec_work/alloc.jl`).

## 5. What remains, and why

- **The user's stage methods, about 12 ms per type at `-O2`.** The probe runs
  `y_state`, `y_direct`, `x_deriv`, `s_update` and `x_projection` on probe
  bundles, so they compile once per type. Only the author's own code or a
  lower optimization level reduces this.
- **About 43 ms per root**, keyed on the fanned root-input tuple (§3). To
  remove it, the boundary declarations would have to be read into vectors
  before any generic code touches them.
- **Cold, about 4.5 s, the same for every scenario**: `build` for an
  `AbstractComponent` root (2.4 s, one instance), `_outputs` (0.9 s), and Base
  helpers. All of it is type-independent now, so a precompile workload of one
  model would cover the whole of `build` for any later model.
- **Not changed, because not exercised by the fixtures**: `probe_events`' inner
  `map` closure captures `declared_events`. A component with state events
  still compiles that closure per type. `_bundle_values`, `_check_ports` and
  `_embed_ports` specialize on port and bundle value types. Those types are
  shared across components and did not show in the traces.
- **Out of scope**: `compile`'s `at_component(() -> invoke_declaration(state_events, comp))`
  (build.jl, `Simulation` time), and the service-walk callers in
  `conditions.jl` and `tracer.jl`.
