# Naming inventory: src/trace.jl

Tip: f64b9f3. Sites flagged: 72. Renames: 39. Collisions: 0. Roster proposals: 1.

## Letters with more than one meaning in this file

- `h`: a hash seed (`Base.hash`), a trace header (`_detach`, `_check_header!`), while the spec's `h` is the step size → all renamed below
- `s`: the spec's discrete stores (`_capture_header`), a scope (`_walk_deployment!`'s comprehensions), a face name (`_check_schemas!`) → the scope and face sites renamed below
- `f`: a root-input face (comprehensions), the target's fingerprint (`_check_header!`), a face in a loop (`_replay_writer`) → the fingerprint and loop sites renamed below
- `b`: a recorded `TraceBatch` (`==`, `hash`, `_compile_records!`), the target schedule (`_walk_deployment!`) → both renamed below
- `a`: a recorded `TraceBatch` (`==`), the recorded schedule (`_walk_deployment!`) → both renamed below
- `k`: the touched-position count (`_record!`), the writer count (`_install_writers!`) → both renamed below

## `Base.:(==)(a::TraceBatch, b::TraceBatch) =` — line 70

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 70 | `a` | param | one record | rename | `record` |
| 70 | `b` | param | the record compared with it | rename | `other` |

## `Base.hash(b::TraceBatch, h::UInt) = …` — line 72

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 72 | `b` | param | the record hashed | rename | `record` |
| 72 | `h` | param | the hash seed; `h` is the step size | rename | `seed` |

## `function _record!(trc::Trace, widx::Int, batch::Batch)` — line 130

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 130 | `trc` | param | the run's trace; `trace` is a function | roster? | `trc` (see `roster.md`) |
| 130 | `widx` | param | the writer's index into the schema list | rename | `writer_index` |
| 132 | `k` | local | the touched-position count, the vector's length | rename | `touched` |
| 133 | `i` | for | the mask position | keep:index | — |
| 137 | `j` | local | the fill cursor into `entries` | keep:index | — |
| 138 | `i` | for | the mask position | keep:index | — |

## `function _writer_schemas(plane)` — line 148

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 150 | `e` | comprehension | a roster entry | keep:glance | — |

## `_detach(h::TraceHeader{T}) where {T} =` — line 160

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 160 | `h` | param | the recorded header; `h` is the step size | rename | `header` |
| 160 | `T` | where | the deployment's scalar | keep:typeparam | — |

## `function _install_writers!(plane, store, trc)` — line 184

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 184 | `trc` | param | the run's trace or `nothing` | roster? | `trc` |
| 185 | `k` | local | the writer count, the harness's slot being the last | rename | `writer_count` |
| 189 | `n` | local | the schema count before the append | rename | `schema_count` |
| 193 | `i` | for destructure | the roster position | keep:index | — |
| 193 | `e` | for destructure | the roster entry, read five times | rename | `entry` |

## `function _fingerprint(sim)` — line 212

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 212 | `sim` | param | the simulation | keep:roster | — |
| 213 | `ex` | local | the executor | rename | `exec` |
| 216 | `f` | comprehension destructure | a root input's face | keep:glance | — |
| 218 | `st` | comprehension | one component's discrete store reference, or `nothing` | keep:glance | — |
| 219 | `st` | comprehension | one component's mode store reference, or `nothing` | keep:glance | — |

## `function _capture_header(sim)` — line 225

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 225 | `sim` | param | the simulation | keep:roster | — |
| 226 | `ex` | local | the executor | rename | `exec` |
| 228 | `T` | local | the deployment's scalar, a local bound to the numeric type | keep:typeparam | — (see Questions) |
| 229 | `s` | local | the discrete store values, the spec's `s` | keep:spec | — |
| 229 | `st` | comprehension | one discrete store reference | keep:glance | — |
| 230 | `m` | local | the mode store values, the spec's `m` | keep:spec | — |
| 230 | `st` | comprehension | one mode store reference | keep:glance | — |
| 232 | `f` | comprehension destructure | a root input's face | keep:glance | — |

## `function _check_header!(diags::Vector{Diagnostic}, sim, h::TraceHeader)` — line 254

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 254 | `diags` | param | the collected mismatches | keep:roster | — |
| 254 | `sim` | param | the target simulation | keep:roster | — |
| 254 | `h` | param | the recorded header | rename | `header` |
| 255 | `f` | local | the target's fingerprint, read twenty times | rename | `target` |
| 256 | `l` | local | the recorded fingerprint, read twenty times | rename | `recorded` |
| 270 | `i` | for destructure | the component index | keep:index | — |
| 270 | `p` | for destructure | the component's path | rename | `path` (the rules' `path` exception) |

## `function _walk_deployment!(diags::Vector{Diagnostic}, rec::Deployment, tgt::Deployment)` — line 294

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 294 | `diags` | param | the collected mismatches | keep:roster | — |
| 294 | `rec` | param | the recorded deployment | rename | `recorded` |
| 294 | `tgt` | param | the target deployment | rename | `target` |
| 299 | `a` | destructure | the recorded schedule, read to line 316 | rename | `recorded_schedule` |
| 299 | `b` | destructure | the target schedule, read to line 316 | rename | `target_schedule` |
| 302 | `r` | comprehension | a recorded or target row (two comprehensions) | keep:glance | — |
| 303 | `ra` | for destructure | the recorded row | rename | `recorded_row` |
| 303 | `rb` | for destructure | the target row | rename | `target_row` |
| 303 | `col` | for | the compared column; abbreviation off the roster | rename | `column` |
| 307 | `r` | comprehension | a row (two comprehensions) | keep:glance | — |
| 309 | `s` | comprehension | a rate-scope row (two comprehensions); `s` is the discrete state in this file | rename | `scope` |
| 310 | `sa` | for destructure | the recorded scope row | rename | `recorded_scope` |
| 310 | `sb` | for destructure | the target scope row | rename | `target_scope` |
| 310 | `col` | for | the compared column | rename | `column` |
| 315 | `s` | comprehension | a rate-scope row (two comprehensions) | rename | `scope` |

## `function _check_schemas!(diags::Vector{Diagnostic}, faces::Vector{Symbol}, schemas::…)` — line 326

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 326 | `diags` | param | the collected mismatches | keep:roster | — |
| 329 | `s` | comprehension | one schema face name; `s` is the discrete state in this file | rename | `face` |

## `_apply_thunk(store, addrs::Tuple, batch::Batch) = …` — line 341

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 341 | `addrs` | param | the writer's compiled addresses | keep:roster | — |

## `function _replay_writer(layout::Layout, diags::Vector{Diagnostic}, tag::String, …)` — line 347

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 347 | `diags` | param | the collected mismatches | keep:roster | — |
| 349 | `f` | comprehension | one schema face | keep:glance | — |
| 351 | `f` | for | an absent face, pushed into a payload | rename | `face` |

## `function _compile_records!(diags::Vector{Diagnostic}, sim, trc::Trace, faces::Vector{Symbol})` — line 369

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 369 | `diags` | param | the collected mismatches | keep:roster | — |
| 369 | `sim` | param | the target simulation | keep:roster | — |
| 369 | `trc` | param | the recording being replayed | roster? | `trc` |
| 372 | `recs` | local | the normalized replay records; abbreviation off the roster | rename | `replay_records` |
| 373 | `b` | for | one recorded `TraceBatch`, read through line 422 | rename | `record` |
| 389 | `pos` | for destructure | a recorded face position; `position` is a Base function | rename | `face_position` |
| 397 | `w` | local | the writer compiled for that tag, or `nothing` | rename | `writer` |
| 401 | `w` | local | the batch's compiled writer, read six times | rename | `writer` |
| 402 | `vals` | destructure | the batch's values, seeded from the writer's blank; `values` is a Base function | rename | `batch_values` |
| 402 | `ok` | destructure | whether every entry of the batch resolved | rename | `resolved` |
| 403 | `pos` | for destructure | a recorded face position | rename | `face_position` |
| 403 | `v` | for destructure | the recorded value at it | rename | `value` |
| 427 | `r` | lambda param | one replay record, the sort key's source | keep:glance | — |

## Collisions

None. Four proposals avoid a function: `trc` stays an abbreviation because `trace` is a function (`sim.jl:1790`); `pos` takes `face_position` because `position` is a Base function; `vals` takes `batch_values` because `values` is one, called in the package; `recs` takes `replay_records` so that `record` is free for the recorded batch.

## Roster proposals

- `trc`: 3 sites here (`_record!`, `_install_writers!`, `_compile_records!`), raised in `roster.md` with its package-wide count (54 word occurrences, five files). It abbreviates "trace", which is the function `trace(sim)`.

## Questions

- `_capture_header` binds `T = eltype(ex.xbuf)` as a local and splices it into `TraceHeader{T}`. It holds the numeric type, which is what the rules reserve `T` for, but it is not a type parameter. Kept here; is a type-valued local under the `T` rule, or a rename to `scalar`?
- `sim.exec` is the roster's `exec`, and the file binds it as `ex`. The renames assume the roster spelling wins, as in `readers.md`.
- `_compile_records!` names the recorded batch `record` and the list of `ReplayRecord`s `replay_records`; the `ReplayRecord` field `record` already holds the `TraceBatch`, so `record` for a `TraceBatch` matches the file's own vocabulary.
