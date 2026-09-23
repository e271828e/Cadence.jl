# Naming inventory: src/executor.jl

Tip: f64b9f3. Sites flagged: 151. Renames: 56. Collisions: 1. Roster proposals: 0.

## Letters with more than one meaning in this file

- `t`: the remaining tuple of a walk's recursion (`_proj_walk`, `_guard_walk`, `_fire_walk`, `_walk`, `_walk_at`, `_walkchunks`); `t` is time, and `:t` is the bundle's time field in `_bundle_expr` → all renamed below
- `e`: an entry in every entry method, and the name the generated bundle code reads (`e.x_off`, `e.sstore`, … in `_bundle_expr`) → renamed below, the quoted expressions with it
- `c`: the execution cursor (`_phase!`), a chunk (`Chunk`'s call methods) → both renamed below
- `b`: a phase body (`PhaseBody`'s call methods) → renamed below
- `g`: a gated entry (`run_at!`) → renamed below
- `n`: a bundle field name (`_bundle_expr`), the event count (`EventSet`) → both renamed below
- `idx`: the tick index or `ESTABLISH` (`run_at!`, the walks, the chunk and body calls), an event's global register index (`EventEntry`'s constructor, matching its field) → tick sites renamed to `tick`, as `run_at!(g::Gated, …, tick::Int)` already spells it

## `_phase!(c::ExecutionCursor, phase::Symbol, index::Int = 0)` — line 26

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 26 | `c` | param | the execution cursor | rename | `cursor` (the entries' field name for it) |

## `StageEntry{XT,BN}(fn, comp, inputs, y1, outs, x_off, clock, sstore, mstore, ws, Δt, path, ci, cursor)` — line 89

The parameters mirror the struct's fields; the rows concern the parameters only.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 89 | `XT`, `BN` | type param | the state type and the bundle name set | keep:typeparam | — |
| 89 | `fn` | param | the output stage's declaration function | rename | `decl` (roster: the declaration; the field stays `fn`) |
| 89 | `comp` | param | the component instance | keep:roster | — |
| 89 | `y1` | param | the own stage-1 port addresses | keep:spec | — (`y` derivative) |
| 89 | `outs` | param | the addresses this entry writes | rename | `outputs` |
| 89 | `x_off` | param | the continuous state offset | keep:spec | — (`x_offs` derivative) |
| 89 | `sstore`, `mstore` | param | the discrete state and mode stores | keep:spec | — (`s`, `m` derivatives) |
| 89 | `ws` | param | the workspace | keep:spec | — (§5.2's bundle name) |
| 89 | `Δt`, `ci` | param | the sample period, the component index | keep:spec, keep:index | — |

## `RHSEntry{XT,BN}(comp, inputs, y, x_off, clock, mstore, ws, path, ci, cursor)` — line 96

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 96 | `XT`, `BN` | type param | the state type and the bundle name set | keep:typeparam | — |
| 96 | `comp` | param | the component instance | keep:roster | — |
| 96 | `y`, `x_off`, `mstore`, `ws` | param | the own port addresses, the state offset, the mode store, the workspace | keep:spec | — |
| 96 | `ci` | param | the component index | keep:index | — |

## `UpdateEntry{BN}(comp, inputs, y, clock, sstore, ws, Δt, path, ci, cursor)` — line 101

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 101 | `BN` | type param | the bundle name set | keep:typeparam | — |
| 101 | `comp` | param | the component instance | keep:roster | — |
| 101 | `y`, `sstore`, `ws`, `Δt` | param | the own port addresses, the state store, the workspace, the sample period | keep:spec | — |
| 101 | `ci` | param | the component index | keep:index | — |

## `_bundle_expr(BN, XT)` — line 112

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 112 | `BN`, `XT` | param | the bundle name set and the state type, passed as values from the generated callers' type parameters | keep:typeparam | — (type-parameter values under their parameter names) |
| 113 | `n` | do-block param | one bundle field name, tested eleven times over twelve lines | rename | `field` |
| 114–122 | `e`, `store`, `xbuf` | quoted names | the generated callers' parameters, spelled inside the expressions | rename | `e` → `entry`, with `make_bundle`'s parameter; `store` and `xbuf` stay |

## `make_bundle(e::StageEntry{F,Comp,XT,BN}, store, xbuf)` and its three siblings — lines 129, 137, 144, 210

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 129, 137, 144, 210 | `e` | param (×4) | the entry whose bundle is built | rename | `entry` (the generated code reads it by name; `_bundle_expr` moves with it) |
| 129, 137, 144, 210 | `F`, `Comp`, `XT`, `BN`, `G`, `H`, `P` | type param | the entry's type parameters | keep:typeparam | — |
| 130, 137, 144, 211 | `xbuf` | param (×4) | the flat continuous state buffer | keep:spec | — (`x` derivative) |

## `run!(e::StageEntry, store, xbuf, ẋbuf)` — line 151

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 151 | `e` | param | the stage entry | rename | `entry` |
| 151 | `xbuf`, `ẋbuf` | param | the flat state and derivative buffers | keep:spec | — |
| 153 | `y` | local | the stage's returned ports | keep:spec | — |

## `run!(e::RHSEntry{Comp,XT}, store, xbuf, ẋbuf)` — line 157

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 157 | `e` | param | the RHS entry | rename | `entry` |
| 157 | `Comp`, `XT` | type param | the entry's type parameters | keep:typeparam | — |
| 157 | `xbuf`, `ẋbuf` | param | the flat buffers | keep:spec | — |
| 159 | `ẋ` | local | the returned derivative | keep:spec | — |

## `run!(e::UpdateEntry, store, xbuf, ẋbuf)` — line 168

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 168 | `e` | param | the update entry | rename | `entry` |
| 168 | `xbuf`, `ẋbuf` | param | the flat buffers | keep:spec | — |

## `EventEntry{XT,BN}(guard, handler, proj, comp, idx, inputs, y, x_off, clock, mstore, ws, path, event, ci, cursor)` — line 203

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 203 | `XT`, `BN` | type param | the state type and the bundle name set | keep:typeparam | — |
| 203 | `proj` | param | the component's `state_projection`, or `nothing` | rename | `projection` (the field stays `proj`) |
| 203 | `comp` | param | the component instance | keep:roster | — |
| 203 | `idx` | param | the event's global register index | rename | `event_index` (`idx` is the tick index elsewhere in the file; the field stays `idx`) |
| 203 | `y`, `x_off`, `mstore`, `ws` | param | the own port addresses, the state offset, the mode store, the workspace | keep:spec | — |
| 204 | `ci` | param | the component index | keep:index | — |

## `ProjectEntry{XT}(comp, x_off, clock, path, ci, cursor)` — line 231

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 231 | `XT` | type param | the state type | keep:typeparam | — |
| 231 | `comp` | param | the component instance | keep:roster | — |
| 231 | `x_off` | param | the continuous state offset | keep:spec | — |
| 231 | `ci` | param | the component index | keep:index | — |

## `run_project!(e::ProjectEntry{Comp,XT}, xbuf)` — line 234

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 234 | `e` | param | the projection entry | rename | `entry` |
| 234 | `Comp`, `XT` | type param | the entry's type parameters | keep:typeparam | — |
| 234 | `xbuf` | param | the flat state buffer | keep:spec | — |

## `EventSet(entries::Vector, projects::Vector, owner, names, localized, ncomps::Int)` — line 277

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 278 | `names` | param | each event's `(path, event name)` | collision | `event_names` (`Base.names`; not called in the scope; the field stays `names`) |
| 279 | `ncomps` | param | the component count | rename | `component_count` |
| 280 | `n` | local | the event count, read on four lines of a nine-line method | rename | `event_count` |

## `_projects!(es::EventSet, xbuf)` — line 294

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 294 | `es` | param | the event set | rename | `event_set` |
| 294 | `xbuf` | param | the flat state buffer | keep:spec | — |

## `_proj_walk(t::Tuple, xbuf)` — lines 295–296

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 296 | `t` | param | the projection entries still to run | rename | `projects` (the `EventSet` field it starts as; `t` is time) |
| 295, 296 | `xbuf` | param (×2) | the flat state buffer | keep:spec | — |

## `_guards!(es::EventSet, store, xbuf)` — line 301

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 301 | `es` | param | the event set | rename | `event_set` |

## `_guard_walk(t::Tuple, store, xbuf, now, σs)` — lines 302–303

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 303 | `t` | param | the event entries still to evaluate | rename | `entries` |
| 302, 303 | `σs` | param (×2) | the numeric-sample register | keep:spec | — (plural of `σ`) |
| 304 | `e` | local | the head entry, read over eight lines | rename | `entry` |
| 306 | `σ` | local | the guard's sample | keep:spec | — |

## `_fire!(es::EventSet, store, xbuf)` — line 315

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 315 | `es` | param | the event set | rename | `event_set` |

## `_fire_walk(t::Tuple, store, xbuf, fire)` — lines 316–317

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 317 | `t` | param | the event entries still to walk | rename | `entries` |
| 318 | `e` | local | the head entry | rename | `entry` |

## `_latch!(e::EventEntry{G,H,P,Comp,XT}, ret::NamedTuple, xbuf)` — line 327

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 327 | `e` | param | the fired entry | rename | `entry` |
| 327 | `ret` | param | the handler's returned stores | rename | `returned` |
| 327 | `G`, `H`, `P`, `Comp`, `XT` | type param | the entry's type parameters | keep:typeparam | — |

## `_store_successor!(ref::Base.RefValue{S}, s⁺, path, what)` — lines 338–339

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 338, 339 | `ref` | param (×2) | the discrete state store | rename | `sstore` (the entry field passed in) |
| 338, 339 | `s⁺` | param (×2) | the successor state | keep:spec | — |
| 338, 339 | `S` | type param (×2) | the store's state type | keep:typeparam | — |

## `_merge_modes!(ref::Base.RefValue{M}, m::NamedTuple{Ms}, path, what, event)` — lines 347, 367

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 347, 367 | `ref` | param (×2) | the mode store | rename | `mstore` (the entry field passed in) |
| 347, 367 | `m` | param (×2) | the handler's partial mode write | keep:spec | — |
| 349, 367 | `M`, `Ms` | type param | the mode store's type, the written names | keep:typeparam | — |
| 350 | `k` | for | a written mode's field name, read four times over twelve lines | rename | `mode_field` (`mode` is a function, `sim.jl:345`) |

## `_fire_project!(e::EventEntry{G,H,P,Comp,XT}, xbuf)` — line 372

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 372 | `e` | param | the fired entry | rename | `entry` |
| 372 | `G`, `H`, `P`, `Comp`, `XT` | type param | the entry's type parameters | keep:typeparam | — |

## `_event_bodies(e::EventEntry, store, xbuf)` — line 384

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 384 | `e` | param | the entry the bodies close over | rename | `entry` |

## `_project_body(e::ProjectEntry, xbuf)` — line 392

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 392 | `e` | param | the projection entry | rename | `entry` |

## `run_at!(e, store, xbuf, ẋbuf, idx)` and its two `Gated` methods — lines 426, 428, 439

"Every method names its parameters alike": the three methods spell the first parameter `e`, `g`, `g` and the last `idx`, `tick`, unnamed.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 426 | `e` | param | an ungated entry | rename | `entry` |
| 426 | `idx` | param | the tick index or `ESTABLISH`, unused here | rename | `tick` (the `Gated` method's name) |
| 428 | `g` | param | a gated discrete entry | rename | `entry` (one name across the three methods) |
| 439 | `g` | param | a gated discrete entry | rename | `entry` |

## `(c::Chunk)()` and `(c::Chunk)(idx)` — lines 451–452

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 451, 452 | `c` | param (×2) | the chunk called | rename | `chunk` |
| 452 | `idx` | param | the tick index or `ESTABLISH` | rename | `tick` |

## `_walk(t::Tuple, store, xbuf, ẋbuf)` — lines 454–455

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 455 | `t` | param | the entries still to run | rename | `entries` |

## `_walk_at(t::Tuple, store, xbuf, ẋbuf, idx)` — lines 460–461

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 461 | `t` | param | the entries still to run | rename | `entries` |
| 460, 461 | `idx` | param (×2) | the tick index or `ESTABLISH` | rename | `tick` |

## `(b::PhaseBody)()` and `(b::PhaseBody)(idx)` — lines 487–488

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 487, 488 | `b` | param (×2) | the phase body called | rename | `body` (the docstrings' `body()`) |
| 488 | `idx` | param | the tick index or `ESTABLISH` | rename | `tick` |

## `_walkchunks(t::Tuple)` and `_walkchunks(t::Tuple, idx)` — lines 490–497

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 491, 497 | `t` | param (×2) | the chunks still to call | rename | `chunks` |
| 496, 497 | `idx` | param (×2) | the tick index or `ESTABLISH` | rename | `tick` |

## `chunked_body(entries::Vector, gates::Vector, store, xbuf, ẋbuf; chunk_size::Int = 16)` — line 507

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 507 | `xbuf`, `ẋbuf` | param | the flat buffers | keep:spec | — |
| 509 | `es` | local function param | the entry list being chunked, beside the outer `entries` | rename | `walk_entries` (the interior or the boundary list, by role) |
| 511 | `lo` | generator | a chunk's first position | keep:glance | — |
| 512 | `e`, `gt` | comprehension destructure | an entry and its gate | keep:glance | — |
| 513–514 | `e`, `gt` | comprehension destructure | an entry and its gate | keep:glance | — |

## Collisions

- line 278, `names` in `EventSet(entries, projects, owner, names, localized, ncomps)`: `Base.names`; not called in the constructor.

## Roster proposals

None. `decl`, already on the roster, is the proposal for `StageEntry`'s `fn` parameter.

## Questions

- The entry structs' fields (`fn`, `outs`, `proj`, `idx`, `sstore`, `mstore`, `ws`, `y1`, `fname`) are out of this step's scope, but the outer constructors' parameters mirror them one for one. Renaming the parameters (`fn` → `decl`, `outs` → `outputs`, `proj` → `projection`, `idx` → `event_index`) while the fields keep the short names splits one concept across two spellings on adjacent lines. A field sweep would be the cleaner fix; until then the user may prefer to leave these four parameters as they are.
- `sstore`, `mstore`, `xbuf`, `ẋbuf`, `x_off`, `y1` and `σs` are kept as spec-symbol derivatives by analogy with `x_offs` and `nx`. The rule lists examples, not a pattern; a ruling on suffixes like `store`, `buf`, `_off` and a plural `s` would settle them package-wide.
- `ws` is §5.2's bundle name for the workspace, so it is kept as a spec symbol here. The same two letters abbreviate "warnings" in `deployment.md`'s `Deployment` constructor; "one name, one meaning per file" holds, but package-wide it has two meanings.
- `run!(e::StageEntry, …)`, `run!(e::RHSEntry, …)` and `run!(e::UpdateEntry, …)` are methods of the API's `run!(sim; …)` (`sim.jl`). The local rules cannot reconcile their parameter names; the internal methods might better be a separate function (`_run_entry!`), which is a function rename outside this step.
- `implementation.md`'s file-table row for this file names the gate `(idx − Φ) % D`, while the code and the `PhaseBody` docstring spell it `(tick - Φ) % D`. The proposal takes `tick` for every walk index; the table row should follow.
- `_bundle_expr` builds code that reads the generated callers' parameters by name (`e`, `store`, `xbuf`). Renaming `make_bundle`'s `e` to `entry` must rename the quoted `e.` references in the same commit, or every bundle breaks at generation.
