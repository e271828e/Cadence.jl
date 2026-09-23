# Brief: naming, the `src/` remainder

Tip at drafting: `c07c201`. Ruled with the user on 2026-09-23. This
increment retires three of the four passes `pending.md`'s "Naming, the
later passes" bullet names: the struct fields, the abbreviated and homonym
function names, and the code generators' emitted names. The `test/` wave
stays in the bullet under its own brief.

The rules are `implementation.md`'s "Naming" section (lines 125–187 at the
tip, longer after the docs commit below); the rulings behind them are
`docs/reports/20260923_naming_inventory/README.md`, whose §5 is this
increment's inventory. Read the section first, then the README's §1–§3 and
§5, then this brief. Never restate the rules; cite them.

## Purpose

Apply the rules to the names the locals sweep could not reach. Every commit
is a pure rename: the same code, the same tests, the same assertion total,
new names. Nothing else changes.

## The docs commit, first

Landed by the coordinator before wave 1. The "Naming" section's lead line
becomes "Rules for locals, parameters, fields and package functions". Two
bullets join the list, after the "every method of a function" bullet:

- **fields follow the same rules**: a field names what it holds, in full or
  by the roster, one meaning per file; a field the spec names or the API
  reads keeps the spec's spelling; a constructor parameter mirrors its
  field;
- **a package function spells its words in full**, joined by underscores,
  the roster's abbreviations admitted (`_condition_violation`, never
  `_cviol`); a generic has one meaning across its methods; a private helper
  never shares an API function's name, and where the spec's verb is the
  right verb the helper appends its target (`gather_cell`, `gather_reads`,
  `capture_stores`, `run_entry!`).

In the "out of the rules' reach" bullet, "a parameter mirroring a struct
field keeps the field's spelling until the field changes" becomes "a
parameter mirroring a struct field keeps the field's spelling". The
generator clause's example list on line 178 changes in wave 3's store
commit, with the names.

## Wave 1: fields

Nine fields rename; the rest of §5's list keeps. `fn` and `dev` are on the
roster; `sstore`, `mstore`, `y1` and `ws` are spec symbols or derivatives
(`ws` is §7.3's own spelling, in every argument set of §5); the selectors'
`i` mirrors a public parameter (R2). `x_off`/`x_offs`, which the sweep's
brief deferred here, keep: the rules list `x_offs` among the derivatives.
`Gated.e` joins the list although §5 does not name it; the field rule
reaches it.

| struct | field | new | reads (`src/`, `test/`) |
| --- | --- | --- | --- |
| `Resolved` (`conditions.jl:327`) | `e` | `entry` | `conditions.jl` 295, 695, 709, 710 |
| `Resolved` | `L` | `leaf_type` | `conditions.jl` 697, 699, 710 |
| `Resolved` | `v` | `converted` | `conditions.jl` 297, 300, 303 |
| `CEntry` (`conditions.jl:156`) | `pos` | `position` | `conditions.jl` 180, 220, 697, 699, 710; the docstring at 324 |
| `StageEntry` (`executor.jl:44`) | `outs` | `outputs` | `executor.jl` 154; the constructor at 89–93 |
| `StageEntry` | `fname` | `fn_name` | `executor.jl` 152, 154; the constructor |
| `EventEntry` (`executor.jl:185`) | `proj` | `projection` | `executor.jl` 383; the constructor at 203–207 |
| `EventEntry` | `idx` | `event_index` | `executor.jl` 311, 315, 324; the constructor |
| `Gated` (`executor.jl:410`) | `e` | `entry` | `executor.jl` 441, 448; `test/utils.jl` 9 |
| `DeviceHandle` (`devices.jl:125`) | `ctl` | `control` | `devices.jl` 184, 195, 290, 344, 351, 398 |

Notes on the table:

- `Resolved.v` takes `converted`, not `value`: `CEntry.value` is the
  authored value and `Resolved.v` is that value through the converter, and
  `survivor.value` beside `survivor.entry.value` would read as one thing.
- `outs` on the executor's entry is not the roster's `outs`: the roster
  admits it for `Decls` rows only (`build.jl:101` keeps). `outputs` sits
  beside the sibling field `inputs`, which also maps ports to cell addresses.
- `build.jl` constructs every entry positionally (lines 1463–1544), so it
  does not change. `sim.jl:1504` constructs `DeviceHandle` positionally.
- `test/fixtures.jl:972`'s `l.ctl` is an assembly path, not the field.
- The rename touches the constructor's parameter with the field (the
  parameter mirrors its field), the field's comment where it spells the old
  name, and nothing else.

Three commits, one per file: `conditions.jl`, `executor.jl` (with
`test/utils.jl`), `devices.jl`. Message: `Rename <file>.jl's fields per the
naming inventory`.

## Wave 2: functions

Two commits, each one family, because a function rename crosses files and
the suite must stay green at every commit.

**Commit A, the diagnostic helpers.** Definitions and every call:

| old | new | file |
| --- | --- | --- |
| `_cviol` | `_condition_violation` | `conditions.jl` (410; 7 calls) |
| `_tviol` | `_trim_violation` | `trim.jl` (239; 10 calls) |
| `_rviol` | `_reader_violation` | `readers.jl` (276; 8 calls) |
| `_tapviol` | `_tap_violation` | `diagnostics.jl` (1657; 7 calls) |
| `_cf_what`, `_cf_expect`, `_cf_section` | `_conformance_what`, `_conformance_expect`, `_conformance_section` | `diagnostics.jl` (1010–1021; 10 calls) |
| `_dep_constraint`, `_dep_section` | `_deployment_constraint`, `_deployment_section` | `diagnostics.jl` (1273, 1281; 2 calls) |
| `_dep_diff!` | `_deployment_diff!` | `trace.jl` (291; 5 calls) |
| `_sup` | `_superscript` | `diagnostics.jl` (1296; 1 call) |

`_dep_` is the deployment in both files: the parameter constraints in
`diagnostics.jl`, the header diff in `trace.jl`. No test calls any of these
(`test/imports.jl` lists none). Message: `Spell the diagnostic helpers'
names in full`.

**Commit B, the homonyms.** The spec owns the verb `gather` (§5's "Scatter
and gather"); each level appends what it gathers.

| old | new | definition | calls |
| --- | --- | --- | --- |
| `gather(bundle, addr)` | `gather_cell` | `store.jl:42` | `store.jl` 74 (emitted); `readers.jl` 181; `dataplane.jl` 600; `trace.jl` 234; `sim.jl` 383, 1827; `trim.jl` 527; `conditions.jl` 861; `bindings.jl` 129; `test/test_trace.jl` 397 |
| `scatter!(bundle, addr, v)` | `scatter_cell!` | `store.jl:55` | `store.jl` 101 and `dataplane.jl` 550 (both emitted); `build.jl` 1449; `conditions.jl` 536, 626; `trim.jl` 526; `test/utils.jl` 34 |
| `gather(reader, exec)` | `gather_reads` | `readers.jl` 204, 207 | `trim.jl` 417, 454, 586; `test/test_readers.jl` 47, 71–74, 133, 175; `test/test_trim.jl` 492, 494, 498 |
| `gather(handle, snapshot)` | `gather_reads` | `devices.jl:248` | `test/test_bindings.jl` 20, 232, 240, 251; `test/test_devices.jl` 382 |
| `capture(::StoreBundle)` | `capture_stores` | `dataplane.jl:604` | `sim.jl` 1714; `test/test_diagnostics.jl` 107, 111 |
| `run!(entry, store, xbuf, ẋbuf)` | `run_entry!` | `executor.jl` 151, 157, 168 | `executor.jl` 434, 441, 448, 464 |

The reader-level and device-level gathers are one meaning, a compiled read
set evaluated against a store holder, so both become `gather_reads` and
each names its parameter by what it holds (R3). `gather_group` and
`scatter_group!` already carry their target and keep. `capture(sim)` and
`run!(sim)` are the API and keep.

Also in this commit: the docstrings and comments that quote a renamed call
(`readers.jl` 185; `sim.jl` 1455; `bindings.jl` 119, 216; `devices.jl` 237,
242) and the two message texts in `diagnostics.jl` (1464, 1476) that spell
`` `gather` `` as a function name; `test/imports.jl`, which lists `gather`,
`scatter!`, `capture` and `run!` (`gather` becomes `gather_cell,
gather_reads`, `scatter!` becomes `scatter_cell!`; `capture` and `run!`
stay and `capture_stores` joins); the
`implementation.md` readers row (line 27), which quotes `gather` as
`apply!`'s twin; `docs/design/companions/frame_walkthrough.md:101`, which
names `run!(::RHSEntry)`. The word *gather* as prose (the compiled gather,
the output gather) is not a function name and stays everywhere. Message:
`Give the private homonyms of gather, capture and run! their targets`.

After both commits, `rg -w` every old name across `src/`, `test/` and
`docs/design/` and read every hit.

## Wave 3: generators

The emitted names change with their builders and readers in one commit, or
nothing compiles.

**Commit C, `store.jl` with `leaves.jl`.** The generated bodies of
`gather_cell`/`scatter_cell!` (`store.jl` 44–62) bind `buf<k>` and `offs`;
`leaves.jl`'s `_mreconstruct_expr` and `_mflatten_expr` (179, 197) emit
reads of them. `reconstruct`, `flatten!` and `flatten_state!` (`leaves.jl`
215, 317, 336, 366) take `buf`, `off`, `v`, and `_reconstruct_expr`/
`_flatten_expr` (117, 142) emit reads of them.

| old | new | where |
| --- | --- | --- |
| `buf` | `buffer` | the three generated functions' parameters and the emitted reads |
| `off` | `offset` | same |
| `offs` | `offsets` | `store.jl`'s bound local and the mixed builders' emitted reads |
| `buf<k>` | `buffer<k>` | `Symbol(:buf, k)` in both files |
| `v` (a value) | `value` | `flatten!`, `flatten_state!` and the `:v` symbol handed to the builder |
| `v` (an expression denoting a value) | `value_expr` | `_flatten_expr`'s and `_mflatten_expr`'s parameter |
| `stmts` | `statements` | the builders' own locals, in both files |
| `CellStore.buf` | `buffer` | `store.jl:16`; read at `store.jl` 44, 57 and `dataplane.jl` 604 |
| `CellAddr.offs` | `offsets` | `store.jl:12`; read at `store.jl` 49, 62 |

The two fields ride with this commit rather than wave 1 because their
readers are the generated bodies. Docstrings restate: `reconstruct(P, buf,
off)` (210–213), `flatten!(buf, off, v)` (313–315), `flatten_state!(buf,
off, v, …)` (327 and the paragraph under it), the builder comments at
114–115, 140–141, 163–169. `implementation.md` line 178's example list
becomes `` (`buffer`, `offset`, `offsets`, `statements`, `_bundle_expr`'s
`entry`) ``. Message: `Rename the store and leaf generators' emitted
names with their builders`.

**Commit D, `executor.jl`.** `_bundle_expr` (112–123) quotes `e.`; the
four `make_bundle` methods (129, 137, 144, 210) name their entry `e`. Both
become `entry`. `store` and `xbuf` in the same expressions keep. Message:
`Name the bundle generator's entry in full`.

**Commit E, `dataplane.jl`.** `stmts` at 550 becomes `statements`.
Message: `Rename dataplane.jl's generator local`.

## What a commit changes

- the names in its table, at every use in their scope, including the
  docstring or comment that spells the old name;
- a line the rename pushes past the file's width, rewrapped as the
  neighbouring lines are; nothing else reflowed;
- nothing else: no reordering, no helper extraction, no comment rewording
  beyond the name, no formatting drift. `git diff --stat` per commit shows
  the files the wave names for it and no other.

A rename is done by reading the scope, never by a file-wide substitution: a
field read `x.pos` and a keyword `pos = …` at another struct's call site
are different things; `\b` does not close after `!`, so grep `run!\(` and
`scatter!\(` with the parenthesis. After each commit, grep the old
spellings as whole words across `src/`, `test/` and `docs/design/` and
read every remaining hit. The prose word (a gather, the scatter) stays.

## Verification

Per commit, the routed subset for the files touched under the sandbox
flags, read off `implementation.md`'s "Running the suite", which is the one
home of test policy; this brief does not restate it. A commit touching a
file in the table's last row runs the gate for its commit: commits A
(`diagnostics.jl`), B (`store.jl`, `sim.jl`) and C (`store.jl`,
`leaves.jl`). Never run the suite in the background; never stash, reset or
check out the working tree. The assertion total ("To check a refactor for
test loss") is read before wave 1 and after each commit, and must not move.

After editing `implementation.md` or a companion, run `check_refs.jl`,
`check_rows.jl` and `linkify.jl` from `docs/design/tools/`.

## Waves and agents

Three agents, sequential, Sonnet, one per wave; each prompt carries this
brief's path, the tip it starts from and the previous wave's handoff. Then
one Opus cold reviewer over the whole increment: for each commit, every row
applied and nothing else changed; the old spellings gone; the "Naming"
section's new bullets held by the new names; the gate green; the assertion
total unchanged. Findings go to the user; a fixer lands one `Fix the src
naming remainder's review findings` commit.

## Handoff

Each agent's final message: per commit, the hash, the rows it deviated from
with the reason (a name already taken in the scope, a site the table
missed), the docstrings and comments it restated, and the suite result.
Nothing else; the diff is the report.

## Bookkeeping

After the review, the coordinator rewrites `pending.md`'s "Naming, the
later passes" bullet to the `test/` wave alone. The README and the reports
stay frozen.

## Noted, not in scope

Short fields the field rule would reach that §5 does not name, for the
user to pull in or leave: `readers.jl`'s `sels` and the read entries' `off`;
`conditions.jl:599`'s `off`; `roster.jl`'s `acct`, `harness_acct`,
`loop_acct`; `DeviceHandle.diag` and `Control.cond`; `tracer.jl`'s `val`,
`deps`; `dataplane.jl`'s `vals`, `max`; `diagnostics.jl`'s `msg`, `mod`,
`end_`; `executor.jl`'s `trig`; `TrimReport`'s `nevals`, `niters` if the
spec does not spell them.
