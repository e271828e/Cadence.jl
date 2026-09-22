# The naming survey — merge

Six slice reports at tip `2844584` (`brief_naming_survey.md`), read on
2026-09-22. Totals: 868 rows; 219 renames, 564 glance, 85 survivors; the
conventions cover about 170 further parameters not tabulated as rows
(`severity`/`path`/`message` over the kinds, `show`'s `io`, the tracer's
operator families, `ci`). The slices are consistent with the brief's rule
and with each other on the classes. They differ on a handful of words, and
several proposals dodge collisions that are not collisions. This file fixes
those points; a rename the sweep applies is the slice's row **as amended
here**. Where this file is silent, the row stands.

## Tree-wide words

One word per role across `src/`, overriding the slice proposals named:

| role | word | overrides |
| --- | --- | --- |
| the component instance (`c`) | `comp` (§5.2's own word) | `component` (D), `instance` (C, F) |
| one component's `Decls` (`d`) | `decl`; the vector stays `decls` | — |
| the `Build` (`b`) | `build` | `artifact` (B: `activation`, `warnings`; C: `Simulation` sugar) |
| the `Deployment` (`d`) | `deployment` | `artifact` (C: `Simulation`) |
| the warnings list (`ws`) | `warnings` | `raised` (C: the `Deployment` constructor) |
| a caught or carried exception (`e`) | `err` | `exc` (B) |
| the compiled executor entry (`e`) | `entry` | — |
| the tuple remainder of an unrolled walk (`t::Tuple`) | `rest` | — |
| the snapshot log (`L`) | `log`, the field's and the keyword's word | `snapshot_log` (E) |
| a count (`n`) | `<thing>_count`: `event_count`, `component_count` | `nevents`, `ncomps` (B, C) |
| a diagnostic value (`d`) in `severity`/`path`/`message` and the helpers a `message` body calls | `diagnostic` | — |
| the device's binding in `attach!` (`b`) | `device_binding` | `new_binding` (C) |

Shadowing a module-level function with a local is a collision only when
the body calls that function. Checked on 2026-09-22: `activation(b::Build)`,
`warnings(b::Build)`, `Simulation(d::Deployment, …)`, `Simulation(b::Build,
…)` and the `Deployment` constructor call none of `build`, `deployment`,
`warnings`; `readers.jl` already spells `build::Build` in two of the five
`_resolve_selector` methods. `attach!` does call `binding(_handle(e))` and
builds a `binding = …` keyword, so its `b` is the one true case.
`_at_path`'s `path` and the `diagnostic` convention shadow accessors their
bodies never call; both stand.

## Questions answered

- `T` as an anchor's period (`deployment.jl:81`) survives: the spec writes
  the anchor pair `(T, τ)`. `K`, `q`, `τ` from Appendix B's declaration
  table survive; the survivor test is "the spec's letter for the spec's
  quantity", at whatever level the spec writes it. `t₀`, `h′`, `y_x`, `y_s`
  survive as decorated spec symbols. `h` as a `Base.hash` seed stays by
  Julia's convention. `s`/`m` in `trace.jl`'s `_capture_header` survive as
  the §5.2 bundles.
- `stepper.jl`'s local `t₀` is the step's start, not the run's origin;
  rename `t_start` in both `step!` methods.
- The Hermite weights `b₀, b₁, d₀, d₁` stay: glance.
- `_check_wires`'s inner `at(fn, S)`: `S` → `scalar`.
- `_tarjan`'s outer `v` (`build.jl:475`) → `node`, for consistency with
  `strong!`'s renamed `v`; the function is touched anyway.
- `executor.jl`'s `entry` beside `build.jl`'s `ComponentEntry` `entry`: no
  collision within a file; both stand.
- `RK4`/`Heun`'s `n::Int` → `nx`, the tree's word for the flat state length
  (`compile`'s own local at `build.jl:1395`).

## The fold

`assembly.jl:72`'s `_at` goes; its six callers (`assembly.jl:300, 321,
378, 391, 400, 1163`) call `_at_path`. `diagnostics.jl:69`'s parameter
becomes `path`, the type annotation `AbstractString` kept.

## Out of scope, recorded

Terse multi-letter names the slices met (`df`, `bn`, `pol`, `fr`, `st`,
`es`, `cur`, `trc`, `ex`, `sm`, `segs`): another sweep if the user wants
one. One of them is a real ambiguity: `ws` is §5.2's workspace bundle in the
user-code frame and the warnings list in the build and the deployment.
The warnings-list `ws` is renamed by the table above wherever it is a
parameter or outlives a glance; the workspace `ws` survives.
