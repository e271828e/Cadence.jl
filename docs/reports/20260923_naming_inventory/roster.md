# Naming inventory: src/roster.jl

Tip: f64b9f3. Sites flagged: 29. Renames: 17. Collisions: 0. Roster proposals: 3.

## Letters with more than one meaning in this file

- `w`: the harness writer in `DataPlane` and `reclaim!`, any writer in `_drain_thunk` → renamed below
- `f`: a root-input face name (comprehensions, `reclaim!`), a claimed face as the binding returned it before conversion (`_claim`'s loop) → the loop sites renamed below
- `s`: the converted face `Symbol` in `_claim`; `s` is the spec's discrete state → renamed below
- `T`: the binding's type (`check_binding`), the device's type (`check_device`), never the numeric type → renamed below
- `device`/`dev`: `device` is the device's name (a `String`, `_claim`), `dev` the device instance (`check_device`) → kept apart, `dev` raised as a roster proposal

## `claims(b::AbstractBinding) = …` — line 50

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 50 | `b` | param | the binding whose `claims` was never written | roster? | `b` as the binding family's letter (see `bindings.md`) |

## `reads(b::AbstractBinding) = …` — line 61

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 61 | `b` | param | the binding whose `reads` was never written | roster? | `b` |

## `function check_binding(b::AbstractBinding)` — line 74

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 74 | `b` | param | the binding checked; `binding` is a function (`devices.jl:207`) | roster? | `b` |
| 75 | `T` | local | the binding's type, not the numeric type | rename | `binding_type` |
| 76 | `isin` | destructure | the declared input side | rename | `input_side` |
| 76 | `isout` | destructure | the declared output side | rename | `output_side` |
| 77 | `drifted` | local | whether `claims` has a method of its own; paired with `rdrifted`, so named by role | rename | `claims_drifted` |
| 78 | `rdrifted` | local | whether `reads` has a method of its own | rename | `reads_drifted` |

## `function check_device(dev::AbstractDevice)` — line 100

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 100 | `dev` | param | the device instance; `device` names the device's `String` name in this file (`_claim`) | roster? | `dev` (see Roster proposals) |
| 101 | `T` | local | the device's type | rename | `device_type` |

## `_handle(e::RosterEntry) = …` — line 135

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 135 | `e` | param | the roster entry | rename | `entry` |

## `_who(e::RosterEntry) = …` — line 139

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 139 | `e` | param | the roster entry | rename | `entry` |

## `_drain_thunk(store, w::Writer, trc, widx::Int) = …` — line 152

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 152 | `w` | param | the writer the thunk drains | rename | `writer` |
| 152 | `trc` | param | the run's trace or `nothing`; `trace` is a function | roster? | `trc` (see Roster proposals) |
| 152 | `widx` | param | the writer's index into the trace's schema list | rename | `writer_index` |

## `function DataPlane(layout::Layout)` — line 205

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 206 | `w` | local | the harness writer over every root input | rename | `harness` |
| 206 | `f` | comprehension destructure | a root input's face | keep:glance | — |

## `function _claim(plane::DataPlane, layout::Layout, b::AbstractBinding, device::String)` — line 221

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 221 | `b` | param | the binding whose claim is read | roster? | `b` |
| 222 | `f` | comprehension destructure | a root input's face | keep:glance | — |
| 223 | `f` | comprehension | an unclaimed face candidate | keep:glance | — |
| 225 | `f` | for | one name the binding's `claims` returned, a string or a symbol | rename | `claimed` |
| 226 | `s` | local | that name as a face `Symbol`, read four times; `s` is the discrete state | rename | `face` |

## `function reclaim!(plane::DataPlane, layout::Layout, store, trc)` — line 255

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 255 | `trc` | param | the run's trace or `nothing` | roster? | `trc` |
| 257 | `e` | for | a roster entry, read twice | rename | `entry` |
| 257 | `f` | for | a face that entry's writer claims | rename | `face` |
| 262 | `w` | local | the recompiled harness writer, beside `old` | rename | `harness` |
| 262 | `f` | comprehension destructure | a root input's face | keep:glance | — |
| 267 | `i` | comprehension | the pending batch's slot index | keep:index | — |
| 268 | `renorm` | local | the renormalized entries, or `nothing` | rename | `renormalized` |

## Collisions

None. Three proposals avoid a function: `b` stays a letter because `binding` is a function (`devices.jl:207`), `trc` because `trace` is one (`sim.jl:1790`), and `drifted`'s pair takes role names rather than `claims`/`reads`, which are functions called in the same scope.

## Roster proposals

- `b`: 5 sites here (`claims`, `reads`, `check_binding`, `_claim` and, from `bindings.md`, the same letter in `claims`/`map_input` there). The binding family's parameter letter; the noun `binding` is a function.
- `dev`: 1 site here (`check_device`), 37 word occurrences across `bindings.jl`, `devices.jl`, `roster.jl`, `sim.jl`, `trace.jl`. It abbreviates "device" where the full word already names the device's `String` name (`_claim`'s `device::String`, the payloads' `device =` field).
- `trc`: 2 sites here (`_drain_thunk`, `reclaim!`), 54 word occurrences across `dataplane.jl`, `diagnostics.jl`, `roster.jl`, `sim.jl`, `trace.jl`. It abbreviates "trace", which is the function `trace(sim)`.

## Questions

- `b` for a binding: the brief reserves `keep:family` for `diagnostics.jl`'s `d`. The binding methods (`claims`, `reads`, `is_input`, `check_binding`, `map_input`) are a second family of that shape, so this report raises `b` as `roster?` rather than applying it.
- `old` (line 260, the harness writer before recompilation) is not flagged, but it pairs with `w` → `harness`; `old_harness` would name both by role. Not listed as a row.
