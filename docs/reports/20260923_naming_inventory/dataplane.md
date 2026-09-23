# Naming inventory: src/dataplane.jl

Tip: f64b9f3. Sites flagged: 71. Renames: 35. Collisions: 4. Roster proposals: 1.

## Letters with more than one meaning in this file

- `a`: a writer account (`_reset!`, `_fold!`), a `KindCounts` operand (`+`), a cell address (`Writer` comprehension) → account sites renamed below
- `b`: a `KindCounts` operand (`+`), a diagnostic batch (`DiagCell`), a store bundle (`capture`) → batch and bundle sites renamed below
- `s`: a face symbol (`_normalize`), a snapshot (`port`) → both renamed below
- `t`: a task (`_task_state`); `t` is time in every struct field of the file → task site renamed below
- `v`: a probe value (`Writer` comprehension), a staged value (`_normalize`) → the `_normalize` site renamed below
- `w`: a writer status (`stale`), a compiled writer (`_normalize`, `_stage!`, `_drain!`) → all renamed below
- `f`: a field name (`_bump`, `+`, `_total`), a face (`Writer` comprehensions); all one-glance comprehension or lambda variables, kept
- `d`: a diagnostic value throughout; outside `diagnostics.jl` the rules forbid it → family methods raised as `roster?`, the two locals renamed

## `path(d::ChatteringBudget)` and `path(d::FiringBudget)` — lines 169–170

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 169 | `d` | param | a `ChatteringBudget` diagnostic | roster? | `d` as the diagnostic-kind family letter beyond `diagnostics.jl` (see Questions) |
| 170 | `d` | param | a `FiringBudget` diagnostic | roster? | as above |

## `message(d::MalformedDatum)` … `message(d::ReplayDiscardedStaging)` — lines 172–209

Ten one-expression methods of `diagnostics.jl`'s `message`, each with the sole parameter `d`.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 172, 174, 178, 181, 184, 188, 191, 198, 202, 205 | `d` | param (×10) | the diagnostic being rendered | roster? | `d`, matching `message`'s other methods in `diagnostics.jl` (see Questions) |

## `_bump(c::KindCounts, k::Symbol)` — line 245

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 245 | `c` | param | the counter record being bumped | rename | `counts` |
| 245 | `k` | param | the kind's field name | rename | `kind` |
| 246 | `f` | generator | a field name of `KindCounts` | keep:glance | — |

## `Base.:+(a::KindCounts, b::KindCounts)` — line 247

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 247 | `a`, `b` | param | the two addends | keep:glance | — (operator operands with no roles; see Questions) |
| 248 | `f` | generator | a field name of `KindCounts` | keep:glance | — |

## `_total(c::KindCounts)` — line 249

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 249 | `c` | param | the counter record summed | rename | `counts` |
| 249 | `f` | lambda param | a field name of `KindCounts` | keep:glance | — |

## `DiagCell(b::DiagBatch)` — line 292

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 292 | `b` | param | the initial diagnostic batch | rename | `batch` |

## `_report!(cell::DiagCell, d::DiagValue)` — line 297

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 297 | `d` | param | the diagnostic value being appended | rename | `occurrence` (`diagnostic` is a function, `diagnostics.jl:99`; the docstrings call each ring entry an occurrence) |
| 299 | `cur` | local | the batch loaded from the cell | rename | `current` |
| 303 | `success` | destructure | the CAS outcome, read on the next line | collision | `replaced = (@atomicreplace …).success` (`Base.success`, not called in the scope; the destructure must spell the field, so the rename needs the property form) |

## `_reset!(a::WriterAccount)` — line 340

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 340 | `a` | param | the writer's account | rename | `account` |

## `_fold!(a::WriterAccount, cell::DiagCell)` — line 351

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 351 | `a` | param | the writer's account | rename | `account` |
| 355 | `d` | for | a retained diagnostic value | rename | `occurrence` (as in `_report!`) |

## `stale(w::WriterStatus; now::Float64 = time())` — line 411

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 411 | `w` | param | one writer's record in the framework status | rename | `record` (the docstring's "one writer's record"; `status` is a `Snapshot` field meaning the whole `FrameworkStatus`) |

## `_task_state(t::Task)` — line 415

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 415 | `t` | param | the device's task | rename | `task` (`t` is time in this file) |

## `Writer(layout::Layout, faces::Vector{Symbol})` — line 456

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 457 | `addrs` | local | the per-position cell addresses | keep:roster | — |
| 457 | `f` | generator | a face name | keep:glance | — |
| 458 | `a` | comprehension | a cell address | keep:glance | — |
| 459 | `f`, `v` | generator destructure | a root input's name and probe value | keep:glance | — |
| 460 | `vals` | local | the placeholder values, converted to the declared types | rename | `placeholders` (the docstring's word; `values` is Base's) |
| 460 | `i` | generator | a position in the schema | keep:index | — |

## `_normalize(w::Writer, pairs, claimedby::Dict{Symbol,String}, cell::DiagCell; …)` — line 490

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 490 | `w` | param | the compiled writer | rename | `writer` |
| 490 | `pairs` | param | the author's face ⇒ value entries | collision | `entries` (`Base.pairs`; not called in the scope) |
| 493 | `vals` | local | the batch's values, blank placeholders overwritten per staged face | rename | `staged` (`values` is Base's) |
| 495 | `face` | for destructure | the author's face key, any type `Symbol` accepts | rename | `key` (frees `face` for the symbol on the next line) |
| 495 | `v` | for destructure | the author's value, read across the next six lines | rename | `value` |
| 496 | `s` | local | the face as a `Symbol` | rename | `face` |
| 497 | `i` | local | the face's position in the schema, not a loop index | rename | `face_position` (`position` is Base's) |

## `_merge(pending::Batch{V,M}, incoming::Batch{V,M}) where {V,M}` — line 526

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 526 | `V`, `M` | type param | the batch's values and mask tuple types | keep:typeparam | — |
| 527 | `vals` | local | the generated per-position value expressions | rename | `value_exprs` |
| 527 | `i` | comprehension | a position | keep:index | — |
| 529 | `mask` | local | the generated per-position mask expressions, not a mask | rename | `mask_exprs` (`mask` is a `Bool` vector in `_normalize`) |
| 529 | `i` | comprehension | a position | keep:index | — |

## `_stage!(w::Writer{B}, batch::B) where {B}` — line 534

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 534 | `w` | param | the compiled writer | rename | `writer` |
| 534 | `B` | type param | the writer's batch type | keep:typeparam | — |
| 539 | `success` | destructure | the CAS outcome, read on the next line | collision | `replaced = (@atomicreplace …).success` (`Base.success`, not called in the scope; the destructure must spell the field, so the rename needs the property form) |

## `_apply!(store, addrs::Tuple, batch::Batch)` — line 548

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 548 | `addrs` | param | the writer's cell addresses | keep:roster | — |
| 549 | `stmts` | local | the generated scatter statements | rename | `statements` |
| 550 | `i` | comprehension | a position | keep:index | — |

## `_drain!(store, w::Writer, trc, widx::Int)` — line 565

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 565 | `w` | param | the compiled writer | rename | `writer` |
| 565 | `trc` | param | the run's trace, or `nothing` | rename | `run_trace` (`trace` is a function, `sim.jl:1790`; `_record!` in `trace.jl:130` names it `trc` too, so both move together) |
| 565 | `widx` | param | the writer's index into the trace's schemas | rename | `writer_index` (likewise `trace.jl:130`) |
| 566 | `ref` | local | the swapped-out pending reference | rename | `pending` (the cell field it was taken from) |

## `port(s::Snapshot, path::String, name::Symbol)` — line 598

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 598 | `s` | param | the snapshot read | rename | `snapshot` (`port`'s other method, `sim.jl:1806`, names its first parameter `sim`; see Questions) |
| 598 | `path` | param | the component path | keep (the `path` exception) | — |

## `capture(b::StoreBundle)` — line 602

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 602 | `b` | param | the store bundle copied | rename | `bundle` (`capture`'s other method, `conditions.jl:819`, takes `sim`; see Questions) |
| 602 | `cs` | lambda param | one cell store | keep:glance | — |

## `SnapshotLog(enabled::Bool, every::Int, max::Int)` — line 655

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 655 | `every` | param | the keep-every-kth stride | rename | `log_every` (the door's keyword it carries) |
| 655 | `max` | param | the retention bound | collision | `log_max` (`Base.max`; not called in the scope) |

## `log!(L::SnapshotLog, snap::Snapshot)` — line 666

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 666 | `L` | param | the snapshot log | rename | `snapshot_log` (`log` is Base's) |
| 666 | `snap` | param | the snapshot entering the log | rename | `snapshot` |
| 668 | `nb` | local | the snapshot's boundary ordinal, read four lines on | rename | `boundary` |

## `_retain!(L::SnapshotLog, snap::Snapshot, nb::Int)` — line 687

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 687 | `L` | param | the snapshot log | rename | `snapshot_log` |
| 687 | `snap` | param | the snapshot being retained | rename | `snapshot` |
| 687 | `nb` | param | the snapshot's boundary ordinal | rename | `boundary` |

## Collisions

- line 303, `success` in `_report!`: `Base.success` (Base's command-status function); not called in `_report!`.
- line 490, `pairs` in `_normalize`: `Base.pairs`; not called in `_normalize`.
- line 539, `success` in `_stage!`: `Base.success`; not called in `_stage!`.
- line 655, `max` in `SnapshotLog(enabled, every, max)`: `Base.max`; not called in the constructor.

## Roster proposals

- `d` for a diagnostic kind as the sole parameter of `message`/`path` methods extending `diagnostics.jl`'s families: 12 sites here (lines 169–170, ten `message` methods at 172–205). Abbreviates "diagnostic". The alternative is `diagnostic`, which collides with the function at `diagnostics.jl:99`, though `diagnostics.jl:744` and `:1587` already use it as a `message` parameter.

## Questions

- The rules say `d` is a diagnostic "in `diagnostics.jl` and nothing elsewhere", yet the methods here extend that file's `message`/`path` families, and "every method of a function names its parameters alike" wants `d`. The two rules conflict for any file that adds diagnostic kinds; the `roster?` above asks to extend `keep:family` to them.
- `diagnostics.jl` itself names `message`'s parameter `diagnostic` at lines 744 and 1587, against `d` elsewhere and against the `diagnostic` function; group C's report should catch it, and the ruling above decides which way.
- `port(s::Snapshot, …)` and `port(sim::Simulation, …)` are methods of one function over unrelated types. "Every method names its parameters alike" cannot hold literally; the proposal names each by what it holds (`snapshot`, `sim`). The same applies to `capture(b::StoreBundle)` beside the API's `capture(sim)` (`conditions.jl:819`); there the internal method might better be a separate function (`_copy_stores`), since the two share only the word.
- `Base.:+(a, b)`: operator operands have no roles to name; kept as `a`/`b`. Say if the rule should reach operator methods.
- `success` is fixed by `@atomicreplace`'s named-tuple field; does the Base-collision rule reach a destructure whose name the callee dictates? If not, both sites become `keep:glance`.
- `claimedby` (line 490) is two words run together, not an abbreviation; left unflagged. `claimed_by` would match the file's snake-case locals if the user wants it.
