# Naming survey — slice E, data plane and periphery

Tip `2844584`. Files: `src/dataplane.jl`, `src/roster.jl`, `src/bindings.jl`,
`src/devices.jl`, `src/trace.jl`. Function definitions examined: 132 (61 in
`dataplane.jl`, 15 in `roster.jl`, 15 in `bindings.jl`, 26 in `devices.jl`, 15
in `trace.jl`), every long-form and short-form method, inner function and
closure in the five files. Date: 2026-09-22.

Glance threshold used throughout: a binding's last use within **5** source
lines of its definition (inclusive) counts as one glance; a comprehension,
`do`-block or anonymous-function argument whose own body is 1–2 lines counts
as one glance regardless of that gap. Both rules appear in the rows below as
plain "glance"; the span column carries the actual gap (or "param" for a
parameter, per the report's own convention) so the threshold can be moved.

Three genuine spec-bundle survivors surface in this slice, all in
`trace.jl`'s `_capture_header`: `T = eltype(ex.xbuf)` is §5.2's scalar type,
read off the state buffer's eltype for `TraceHeader{T}`; `s` and `m`, built
from `ex.sstores`/`ex.mstores`, are the discrete-state and mode bundle values
per component — `build.jl:1335–1336` names the two `Executor` fields
`sstores`/`mstores` as exactly "discrete state stores" and "mode stores" by
component index, so the header's own `s`/`m` (and these locals that fill
them) carry §5.2's `s`/`m` bundle, not a `store`-the-mechanism or
`Simulation` meaning. No other spec letter (`x`, `u`, `y`, `Δt`, `ws`, `σ`,
`θ`, `τ`, `D`, `Φ`, `N`, `h`, `ci`, `io`) appears as a plain single-letter
binding anywhere in the five files; every other `s` met here is a `Symbol`,
a selector, a scope prefix or a schedule row, never the discrete-state `s`.

## Conventions

**`dataplane.jl`**

- **A.** `message(d::Kind)` (lines 172–209, 10 methods: `MalformedDatum`,
  `OutOfClaimEntry`, `ClaimedFaceEntry`, `EntryTypeMismatch`,
  `ChatteringBudget`, `FiringBudget`, `UnboundedRun`, `DeviceCrash`,
  `DeviceJoinTimeout`, `ReplayDiscardedStaging`) and `path(d::Kind)` (lines
  169–170, 2 methods: `ChatteringBudget`, `FiringBudget`) — the same
  `diagnostics.jl` dispatch convention (slice A) extended by this file's own
  diagnostic kinds: every method takes `d`, the diagnostic value rendered or
  read. All 12 are one-statement bodies, glance.

**`bindings.jl`**

- **B.** `_resolve_read(layout::Layout, s::Kind, T::Type, device::String)`
  (lines 168 `StoreSelector`, 172–181 `GetOutput`, 183–189 `GetInput`,
  191–200 `GetFace`): every method takes `s`, the read selector resolved
  against the layout, and `T`, the binding's concrete type carried only for
  the diagnostic's `binding` label. `T`'s own last use sits 2–5 lines from
  its parameter line in every method — glance throughout. `s` is not
  uniform: glance in `StoreSelector` (one-liner) and `GetInput` (last use 5
  lines on), but its last use reaches 8 lines on in `GetOutput` and
  `GetFace` — tabulated individually below, renamed `selector`.
- **C.** `claims(b::Kind)` (`roster.jl:50`, the `AbstractBinding` fallback
  that throws; `bindings.jl:72`, `TableBinding`): every method takes `b`,
  the binding whose claim set is enumerated. Both one-liners, glance.

No convention was found worth stating for `roster.jl`, `devices.jl` or
`trace.jl`: recurring same-type parameter names there (`b::AbstractBinding`
across `reads`/`check_binding`/`_claim`; `w::Writer` across `_normalize`/
`_stage!`/`_drain!`; `h::DeviceHandle` across the handle primitives) are
distinct functions, not multiple methods of one generic dispatched over
sibling types, so each is tabulated on its own below.

## The table

### `src/dataplane.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 245 | `_bump` | `c` | the kind-count record incremented | param | glance | — | |
| 245 | `_bump` | `k` | the kind incremented | param | glance | — | |
| 246 | `_bump` | `f` (generator) | the `KindCounts` field name folded into the increment | 246–246 | glance | — | |
| 247 | `Base.:+` | `a` | the first kind-count record summed | param | glance | — | |
| 247 | `Base.:+` | `b` | the second kind-count record summed | param | glance | — | |
| 248 | `Base.:+` | `f` (generator) | the `KindCounts` field name summed | 248–248 | glance | — | |
| 249 | `_total` | `c` | the kind-count record summed | param | glance | — | |
| 249 | `_total` | `f` (anon-fn arg) | the `KindCounts` field name summed | 249–249 | glance | — | |
| 292 | `DiagCell` (constructor) | `b` | the batch the cell starts with | param | glance | — | |
| 297 | `_report!` | `d` | the diagnostic value appended to the writer's cell | param | glance | — | last use 5 lines on (302) |
| 340 | `_reset!` | `a` | the writer's diagnostic account being reset | param | glance | — | |
| 351 | `_fold!` | `a` | the writer's diagnostic account folded into | param | rename | `account` | |
| 411 | `stale` | `w` | the writer status queried for staleness | param | glance | — | |
| 415 | `_task_state` | `t` | the device's task, queried for its run state | param | glance | — | |
| 457 | `Writer` (constructor) | `f` (generator) | the root input's face name, looked up for its cell address | 457–457 | glance | — | |
| 458 | `Writer` (constructor) | `a` (generator) | the root input's cell address, queried for its port type | 458–458 | glance | — | |
| 459 | `Writer` (constructor) | `f` (generator) | the root input's face name | 459–459 | glance | — | tuple destructure with `v` |
| 459 | `Writer` (constructor) | `v` (generator) | the root input's declared probe value | 459–459 | glance | — | |
| 460 | `Writer` (constructor) | `i` (generator) | the position index into the compiled surface | 460–460 | glance | — | |
| 490 | `_normalize` | `w` | the compiled writer being staged into | param | rename | `writer` | |
| 495 | `_normalize` | `v` (loop var) | the staged value paired with the face | 495–512 | rename | `value` | |
| 496 | `_normalize` | `s` (local) | the staged face as a `Symbol`, looked up in the writer's schema | 496–512 | rename | `face_sym` | collision — see below |
| 497 | `_normalize` | `i` (local) | the face's position in the writer's compiled surface | 497–515 | rename | `index` | |
| 529–530 | `_merge` (`@generated`) | `i` (generator) | the batch position generated for the unrolled merge expression | 529–530 | glance | — | one comprehension across two lines |
| 531 | `_merge` (`@generated`) | `i` (generator) | the batch position generated for the unrolled merge expression | 531–531 | glance | — | distinct scope from line 530's `i` |
| 536 | `_stage!` | `w` | the writer whose staging cell is merged into | param | glance | — | |
| 551–552 | `_apply!` (`@generated`) | `i` (generator) | the batch position applied through the compiled scatter | 551–552 | glance | — | |
| 567 | `_drain!` | `w` | the writer whose cell is drained | param | glance | — | |
| 600 | `port` | `s` | the snapshot read from | param | glance | — | |
| 604 | `capture` | `b` | the store bundle copied for a boundary capture | param | glance | — | |
| 668 | `log!` | `L` | the snapshot log appended to | param | rename | `snapshot_log` | avoids shadowing `Base.log`, though this body never calls it |
| 689 | `_retain!` | `L` | the snapshot log thinned and appended to | param | rename | `snapshot_log` | |

### `src/roster.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 61 | `reads` (`AbstractBinding` fallback) | `b` | the binding whose output enumeration is missing | param | glance | — | |
| 74 | `check_binding` | `b` | the binding checked for contract conformance | param | glance | — | |
| 75 | `check_binding` | `T` (local) | the binding's concrete type, checked against method definitions | 75–88 | rename | `binding_type` | |
| 101 | `check_device` | `T` (local) | the device's concrete type, checked against `loop`'s methods | 101–105 | glance | — | |
| 135 | `_handle` | `e` | the roster entry whose handle is read | param | glance | — | |
| 139 | `_who` | `e` | the roster entry whose handle name is read | param | glance | — | |
| 152 | `_drain_thunk` | `w` | the writer whose drain is compiled into the thunk | param | glance | — | |
| 206 | `DataPlane` (constructor) | `w` (local) | the plane's initial writer, over every root input | 206–207 | glance | — | |
| 206 | `DataPlane` (constructor) | `f` (generator) | the root input's face name | 206–206 | glance | — | |
| 221 | `_claim` | `b` | the binding whose claim is computed or read | param | rename | `binding` | |
| 222 | `_claim` | `f` (generator) | the candidate root input's face name, collected into the face set | 222–222 | glance | — | |
| 225 | `_claim` | `f` (loop var) | the claimed face name, from the binding's own enumeration | 225–226 | glance | — | distinct scope from line 222's `f` |
| 226 | `_claim` | `s` (local) | the claimed face name as a `Symbol`, validated and collected | 226–230 | glance | — | |
| 257 | `reclaim!` | `e` (loop var) | the roster entry walked for its claimed faces | 257–258 | glance | — | |
| 257 | `reclaim!` | `f` (loop var) | the claimed face name, added to the exclusivity index | 257–258 | glance | — | |
| 262 | `reclaim!` | `w` (local) | the harness writer recompiled over the unclaimed complement | 262–263 | glance | — | |
| 262 | `reclaim!` | `f` (generator) | the candidate root input's face name, collected into the new claim set | 262–262 | glance | — | distinct scope from line 257's `f` |
| 267 | `reclaim!` | `i` (generator) | the pending batch's touched position, paired with its face | 267–267 | glance | — | |

### `src/bindings.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 44 | `TableBinding` (constructor) | `k` (loop var) | the entry's channel name, used in every diagnostic for this entry | 44–65 | rename | `channel` | |
| 44 | `TableBinding` (constructor) | `e` (loop var) | the channel's entry `NamedTuple`, validated field by field | 44–63 | rename | `entry` | |
| 72 | `claims` (`TableBinding`) | `e` (generator) | each table entry, read for its face name | 72–72 | glance | — | `b` covered by convention C |
| 91 | `map_input` | `b` | the table binding queried for its channel table | param | glance | — | |
| 92 | `map_input` | `k` (do-arg) | the datum's field name, matched to a table channel | 92–96 | glance | — | |
| 96 | `map_input` | `e` (local) | the matched channel's entry, read for its face and conditioning | 96–97 | glance | — | |
| 126 | `_gather` | `r` | the compiled gather applied to a snapshot | param | glance | — | |
| 126 | `_gather` | `s` | the snapshot read from | param | glance | — | |
| 127 | `_gather` | `a` (anon-fn arg) | each compiled cell address, gathered from the snapshot | 127–127 | glance | — | |
| 138 | `_compile_gather` | `T` | the binding's concrete type, for the diagnostic's `binding` label | 138–146 | rename | `binding_type` | |
| 142 | `_compile_gather` | `s` (do-arg) | the attachment's declared read selector, validated and resolved | 142–147 | glance | — | |
| 151 | `_root_input_names` | `f` (generator) | the root input's face name | 151–151 | glance | — | |
| 157 | `_cells_at` | `p` | the assembly path whose child cell names are listed | param | glance | — | |
| 158 | `_cells_at` | `q` (generator) | the candidate cell's owning path, compared against `p` | 158–158 | glance | — | |
| 158 | `_cells_at` | `n` (generator) | the candidate cell's field name, collected as a face | 158–158 | glance | — | |
| 161 | `_root_output_faces` | `q` (generator) | the candidate cell's owning path, checked for the root | 161–161 | glance | — | distinct scope from `_cells_at`'s `q` |
| 161 | `_root_output_faces` | `n` (generator) | the candidate cell's field name, collected where not a root input | 161–161 | glance | — | distinct scope from `_cells_at`'s `n` |
| 168, 172, 183, 191 | `_resolve_read` (4 methods) | `T` | see convention B | param | glance | — | |
| 168 | `_resolve_read` (`StoreSelector`) | `s` | see convention B | param | glance | — | |
| 172 | `_resolve_read` (`GetOutput`) | `s` | see convention B | param | rename | `selector` | |
| 183 | `_resolve_read` (`GetInput`) | `s` | see convention B | param | glance | — | |
| 191 | `_resolve_read` (`GetFace`) | `s` | see convention B | param | rename | `selector` | |
| 222 | `_condition` | `v` | the raw authored value being conditioned | param | glance | — | |
| 222 | `_condition` | `e` | the channel's entry, read for its conditioning parameters | param | glance | — | |
| 226 | `_condition` | `x` (local) | the clamped raw value, sign-preserved for the final flip | 226–230 | glance | — | |
| 227 | `_condition` | `a` (local) | the magnitude being reshaped by deadzone and expo | 227–230 | glance | — | |

### `src/devices.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 184 | `running` | `h` | the device handle whose stop status is read | param | glance | — | |
| 195 | `stop!` | `h` | the device handle issuing the stop | param | glance | — | |
| 207 | `binding` | `h` | the device handle whose attachment binding is read | param | glance | — | |
| 215 | `latest` | `h` | the device handle whose latest snapshot is read | param | glance | — | |
| 228 | `stage!` | `h` | the device handle staging into its writer | param | glance | — | |
| 248 | `gather` | `h` | the device handle whose compiled gather is read | param | glance | — | |
| 248 | `gather` | `s` | the snapshot the compiled gather runs against | param | glance | — | |
| 272 | `report!` | `h` | the device handle reporting into its own diagnostic cell | param | glance | — | |
| 272 | `report!` | `d` | the malformed-datum diagnostic reported by the author's own loop | param | glance | — | |
| 288 | `wait_next_snapshot` | `h` | the device handle waiting on the next published boundary | param | rename | `handle` | file already spells this "handle" in `loop(dev, handle)` |
| 307 | `_shutdown!` | `e` | the roster entry whose device shutdown is guarded | param | glance | — | |
| 335 | `_wrap` | `e` | the roster entry whose device task the wrapper runs and reports for | param | rename | `entry` | |
| 375 | `_init_devices!` | `e` (loop var) | the roster entry being initialized | 377–387 | rename | `entry` | |
| 395 | `_spawn!` | `e` (loop var) | the roster entry whose wait register is refreshed before spawn | 396–397 | glance | — | |
| 399 | `_spawn!` | `e` (generator) | the roster entry whose wrapper task is spawned | 399–399 | glance | — | distinct scope from line 396's `e` |
| 433 | `_tail!` | `e` (loop var) | the roster entry whose `unblock!` hook runs | 433–438 | glance | — | |
| 442 | `_tail!` | `e` (loop var) | the roster entry being joined within the timeout window | 442–450 | rename | `entry` | distinct scope from line 433's `e` |
| 442 | `_tail!` | `t` (loop var) | the spawned task being joined | 442–446 | glance | — | |
| 448 | `_tail!` | `s` (local) | the latest snapshot, read for the abandonment's boundary and time | 448–451 | glance | — | |
| 472 | `_sweep_tail!` | `e` (loop var) | the roster entry whose account is folded into the residue | 472–474 | glance | — | |
| 486 | `_residue!` | `a` | the writer's diagnostic account, folded into a residue record if non-quiet | param | rename | `account` | |
| 488 | `_residue!` | `r` (local) | the residue record built for this writer, if non-quiet | 488–493 | glance | — | |
| 490 | `_residue!` | `d` (loop var) | each retained diagnostic value, warned individually | 490–491 | glance | — | |
| 493 | `_residue!` | `s` (local) | the total suppressed count, warned if nonzero | 493–494 | glance | — | |

### `src/trace.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 70 | `Base.:(==)` | `a` | the first trace batch compared for equality | param | glance | — | |
| 70 | `Base.:(==)` | `b` | the second trace batch compared for equality | param | glance | — | |
| 72 | `Base.hash` | `b` | the trace batch hashed | param | glance | — | |
| 72 | `Base.hash` | `h` | the running hash seed | param | glance | — | |
| 130 | `_record!` | `k` (local) | the count of touched positions in this batch | 132–136 | glance | — | |
| 133 | `_record!` | `i` (loop var) | the mask position counted, if touched | 133–134 | glance | — | first counting pass |
| 137 | `_record!` | `j` (local) | the entry's fill position, advanced as touched positions are found | 137–139 | glance | — | |
| 138 | `_record!` | `i` (loop var) | the mask position filled into the entries vector, if touched | 138–139 | glance | — | second, filling pass — distinct scope from line 133's `i` |
| 149 | `_writer_schemas` | `e` (generator) | each rostered device entry, read for its writer's schema | 149–149 | glance | — | |
| 160 | `_detach` | `h` | the trace header detached into a fresh, caller-independent copy | param | glance | — | |
| 185 | `_install_writers!` | `k` (local) | the roster's writer count plus the harness, the new schema-list width | 185–200 | rename | `writer_count` | |
| 189 | `_install_writers!` | `n` (local) | the trace's existing schema-list length, before this roster's writers are appended | 189–191 | glance | — | |
| 193 | `_install_writers!` | `i` (loop var) | the roster entry's position, indexing into `live_writers` | 193–197 | glance | — | |
| 193 | `_install_writers!` | `e` (loop var) | the roster entry being recompiled with its new writer index | 193–198 | glance | — | |
| 216 | `_fingerprint` | `f` (generator) | the root input's face name | 216–216 | glance | — | |
| 228 | `_capture_header` | `T` (local) | the deployment's scalar type, read off the state buffer's eltype | 228–233 | survivor(T) | — | §5.2's scalar type (D-260) |
| 229 | `_capture_header` | `s` (local) | each component's discrete-state bundle value, off its cell store | 229–233 | survivor(s) | — | `build.jl:1335`'s `sstores`, "discrete state stores by component index" |
| 230 | `_capture_header` | `m` (local) | each component's mode bundle value, off its cell store | 230–233 | survivor(m) | — | `build.jl:1336`'s `mstores`, "mode stores by component index" |
| 231 | `_capture_header` | `f` (generator) | the root input's face name | 231–231 | glance | — | tuple destructure with `_` |
| 254 | `_check_header!` | `h` | the recorded trace header, checked against the target build | param | rename | `header` | |
| 255 | `_check_header!` | `f` (local) | the target build's structural fingerprint, compared against the header's | 255–276 | rename | `fingerprint` | no true collision with `_fingerprint` (leading underscore differs) |
| 256 | `_check_header!` | `l` (local) | the header's own recorded structural fingerprint | 256–276 | rename | `recorded` | |
| 270 | `_check_header!` | `i` (loop var) | the component's position, indexing the per-path type comparison | 270–276 | rename | `index` | |
| 270 | `_check_header!` | `p` (loop var) | the component's path, for the mismatch's `path` field | 270–275 | glance | — | |
| 299 | `_walk_deployment!` | `a` (local) | the recorded deployment's schedule | 299–316 | rename | `recorded_schedule` | |
| 299 | `_walk_deployment!` | `b` (local) | the target deployment's schedule | 299–316 | rename | `target_schedule` | |
| 302, 307 | `_walk_deployment!` | `r` (generator, ×4) | each schedule row, recorded or target side, read for its path | 302–302, 307–307 | glance | — | four one-line comprehensions comparing `a.rows`/`b.rows` path lists |
| 309, 315–316 | `_walk_deployment!` | `s` (generator, ×4) | each scope entry, recorded or target side, read for its path and key | 309–309, 315–316 | glance | — | four one-line comprehensions comparing `a.scopes`/`b.scopes`; not the discrete state |
| 329 | `_check_schemas!` | `s` (generator) | the recorded face name, checked against the model's root inputs | 329–329 | glance | — | not the discrete state |
| 349 | `_replay_writer` | `f` (generator) | the recorded face name, checked for an address in the target layout | 349–349 | glance | — | |
| 351 | `_replay_writer` | `f` (loop var) | the recorded face absent from the target layout, reported by name | 351–352 | glance | — | distinct scope from line 349's `f` |
| 373 | `_compile_records!` | `b` (loop var) | the recorded batch being resolved into a replay record | 373–422 | rename | `trace_batch` | collision — see below |
| 397 | `_compile_records!` | `w` (local) | the compiled writer for the recorded batch's schema, resolved once per writer index | 397–422 | rename | `writer` | reassigned at line 401, same binding |
| 403 | `_compile_records!` | `v` (loop var) | the recorded entry's raw value, converted to the target's declared type | 403–415 | rename | `value` | |
| 427 | `_compile_records!` | `r` (anon-fn arg) | each replay record, sorted by frame then by the recording's writer index | 427–427 | glance | — | |

## Collisions

- `dataplane.jl:496`, `_normalize` — `s` (the staged face as a `Symbol`)
  would propose `face`, colliding with the for-loop's own destructured
  `face` (line 495, the pre-`Symbol` string/`Symbol` from `pairs`).
  Alternative: `face_sym`.
- `trace.jl:373`, `_compile_records!` — `b` (the recorded batch) would
  propose `batch`, colliding with the local `batch` built at line 421 (the
  positional `Batch` rebuilt from `w`'s converted values) inside the same
  loop iteration. Alternative: `trace_batch`.

## Neighbours

- `trc` (`dataplane.jl:567,572`; `roster.jl:152,255`; `trace.jl:130,184,369`)
  — the run's trace, `nothing` under the kill switch.
- `cs` (`dataplane.jl:604`) — each per-eltype cell store, copied for the
  boundary capture.
- `nb` (`dataplane.jl:670,689`) — the trajectory's published-boundary
  ordinal, read off the snapshot.
- `dz` (`bindings.jl:60,223,228`) — the declared deadzone parameter.
- `ex` (`bindings.jl:63,224,229`) — the declared expo parameter (unrelated
  to `trace.jl`'s `ex`, below).
- `nt` (`bindings.jl:138–148`) — the attachment's declared `reads`
  `NamedTuple`.
- `ctl` (`devices.jl`, throughout) — the control struct, `Control`.
- `lc` (`devices.jl:97`) — the control's lifecycle symbol.
- `op` (`devices.jl:91,96`) — the service call name, for the lifecycle
  diagnostic.
- `ok` (`devices.jl:378`) — whether this device's `init!` succeeded.
- `dev` (`devices.jl`, throughout) — the attached device instance.
- `ex` (`trace.jl:213,214,226,227`) — the simulation's executor, off
  `sim.exec` (unrelated to `bindings.jl`'s `ex`, above).
- `st` (`trace.jl:218,219,229,230`) — each component's cell store, read for
  its type or dereferenced value.
- `rec` (`trace.jl:294–317`) — the recorded deployment.
- `tgt` (`trace.jl:294–317`) — the target deployment.
- `ra`, `rb` (`trace.jl:303–304`) — the recorded and target schedule rows.
- `sa`, `sb` (`trace.jl:310–311`) — the recorded and target scope entries.
- `pos` (`trace.jl:389,403–418`) — the batch entry's schema position.

## Questions

None. Every single-letter binding in this slice resolved cleanly against
§5.2's bundle table or against its own role. The one case that looked
ambiguous on the letter alone — `trace.jl`'s `s`/`m` in `_capture_header`,
built from `ex.sstores`/`ex.mstores` — resolved from `build.jl:1335–1336`'s
own field comments ("discrete state stores", "mode stores", both "by
component index"): they carry §5.2's `s`/`m` bundle, not the `store` or
`Simulation` meaning the same letter takes elsewhere in this slice.

## Coverage

All 132 function definitions across the five files were examined; none were
skipped.
