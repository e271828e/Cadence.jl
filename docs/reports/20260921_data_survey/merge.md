# The data survey: merged register

Tip `aa9162a`, 2026-09-21. Five slices, five reports in this directory,
104 structs surveyed, 22 findings. The brief is
`docs/design/briefs/brief_data_survey.md`. Each row cites its slice's entry,
which carries the evidence; this file classifies and sequences. "Rostered"
means the spec or a decision names the field on that type, so the change is
a ruling before it is a fix.

## The findings

| id | field | smell | rostered | proposal |
| --- | --- | --- | --- | --- |
| A1 | `Walk.root_types` | courier | no | drop; `wire!` allocates the vector it hands `Structure` |
| B1 | `Schedule.D`, `.Φ`, `.Δt` | duplicate of the rows | D-254, §9.2 | rows are the home; `compile` takes the `Schedule` or a per-component helper |
| B2 | `ExecutionCursor.hit` | courier | §13.5, D-255 | `_localized_frame!` and `frame!` return the face |
| B3 | `Executor.xblocks` | duplicate of `_x_offsets`, misplaced | no | home on `Layout`, computed once in `cell_layout`; `_x_offsets`'s three callers read it |
| B4 | `Activation.stage1` | dead (tests only), duplicate | no | drop; frozen components get no carry |
| B5 | `Deployment.grid` | dead until its renderer | §9.2, D-254 | keep; `show(::Deployment)` is increment 48 |
| B6 | `Dataflow.edges` | dead (tests only) | D-253 | keep as the inspectable graph, or drop to four fields |
| B7 | `Layout.root_inputs`, the name half | duplicate of `Structure.root_inputs` | no | values only on the layout; seven name readers read the structure |
| B8 | `Chunk.clock` | dead | no | drop, with `chunked_body`'s argument |
| B9 | `GridEntry.anchor` | dead (tests only), duplicate of `provenance` | no | drop |
| B10 | `EventSet.store`, `.xbuf` | duplicate of the executor's | no | the three walks take them as arguments |
| C1 | `DataPlane.store` | courier, duplicate of `Executor.store` | no | `_install_writers!` and `reclaim!` take the store, as D-260 did for the trace |
| C2 | `DeviceHandle.id` | dead | no | drop |
| C3 | `RosterEntry.writer`, `.diag`, `.binding`, `.id` | duplicate of the handle's | §12.4 for `binding`, `id` | the entry reads them through `e.handle`, as `_who` does |
| C4 | `DeviceHandle.plane`, `.published` | misplaced, duplicate | no | hold `claimedby` alone; `published` then stands |
| C5 | `Snapshot.frame` | dead (tests only) | no, D-230 in passing | keep and roster, or drop |
| C6 | `Writer.types` | duplicate with an enforcer | no | leave, or read `_port_type(addrs[i])` |
| C7 | `TraceHeader.layout.root_faces` | duplicate of `root_inputs`' names | §12.7 | keep; the fingerprint's symmetry |
| D1 | `Run.log`, `.trace` on the placeholder | courier of the four recording flags | D-256, D-260 | one immutable flags value the `Simulation` owns |
| D2 | `StepError.t`, `.boundary`, `.frame.path` | duplicate of `NonfiniteState`'s payload | §13.4, Appendix C | accept; the diagnostic renders standalone |
| D3 | `TerminationRecord.policy.addrs` | misplaced: compiled addresses on an outcome value | §13.5, D-255, D-260 | `StopPolicy` keeps `(t_end, faces)`; the addresses travel as the loop's argument |
| E1 | `ConditionPlan.faces` beside `inputs`' face slot | duplicate | no | drop the slot from `inputs` |

## Grouping

**Plain fixes, not rostered.** A1, B3, B4, B7, B8, B9, B10, C1, C2, C4, C6,
E1. Twelve. Each is a local change whose readers the slice report lists;
none touches the spec beyond `implementation.md`'s rows. B3 and B7 change
signatures (`Writer`, `DataPlane`, `_claim`, `reclaim!`, `compile`'s
callers) and are the two with reach.

**Rulings.** B1, B2, B5, B6, C3, C5, C7, D1, D2, D3. Ten. The
recommendation for each is in the next section; the user rules.

**Touching the types increment 48 renders.** B1 (`Schedule`), B5
(`Deployment`), B6 (`Dataflow`), and the `aprov` question below, which 48
already schedules. B1 and B6 settle before 48 so the renderings print
settled shapes; B5 waits for 48, which is its reader.

## The rulings, with a recommendation each

- **B1, the `Schedule` vectors.** Drop them. The rows are §9.2's typed
  schedule and the vectors are the rows re-indexed by component, built in
  the same loop. `compile` takes the `Schedule` and a small helper yields the
  per-component `(D, Φ, Δt)` from the rows by path, the continuous tier's
  constant otherwise. `==`, `hash` and the header walk lose their vector
  clauses. D-254 amended.
- **B2, the cursor's `hit`.** Return it. The face travels
  `_localized_frame!` → `frame!` → `_advance!` as a `Union{Nothing,Symbol}`
  return, no allocation, and the cursor drops to its four dispatch fields.
  §13.5's "scratch beside the cursor" sentence and D-255's bullet amended.
- **B5, `Deployment.grid`.** Keep. Its reader is 48's `show(::Deployment)`.
- **B6, `Dataflow.edges`.** Keep. D-253 kept the name `Dataflow` for the
  graph, and a renderer may print it. Cheap to hold, and the ruling can be
  revisited when `show(::Dataflow)` lands and prints the order alone.
- **C3, the roster entry's four mirrors.** Move all four behind the handle.
  §12.4's "binding, claims, stable device id" survive a stop on the entry
  through its handle, so its wording stands. `RosterEntry` moves below
  `DeviceHandle` in the include order so `handle` is typed and the frame-top
  `_fold!(e.acct, e.handle.diag)` costs nothing.
- **C5, `Snapshot.frame`.** Keep and roster it in §11.2. It is the one
  field that tells a `t*` snapshot from the frame top beside `boundary`,
  which is why the tests lean on it.
- **C7, the fingerprint's `root_faces`.** Keep. `_fingerprint` is one
  function with two sides on purpose, and the duplicate has an enforcer.
- **D1, the recording flags.** A sixth `Simulation` field, an immutable
  value of the four keywords, read by `_open_run!` and the two header-capture
  sites. The placeholder run stays for the accessors. D-256's "five fields"
  becomes six; the alternative, on `Control` beside `join_timeout`, puts a
  recorders' parameter on the control plane by convenience alone.
- **D2, `StepError` beside `NonfiniteState`.** Accept. A diagnostic must
  render standalone through `logline`, and the carrier prints its own line.
  No change.
- **D3, the record's compiled addresses.** Shrink `StopPolicy` to the
  declared pair. `_bind_policy` returns the addresses beside it and they
  travel as one more loop argument through `_advance!`, `frame!` and
  `_localized_frame!` to `_stop_hit`. The least consequential of the ten;
  fine to defer.

## Questions the slices raised, not counted

- `Structure.aprov` is a rendering parsed back by regex (A). Increment 48's
  first stage already makes it a structured `(scope, key)` record.
- `Structure.root_types` is filled by `_check_wires` after the immutable
  `Structure` exists (A). A construction-order question: `build` could
  compose the `Structure` after the barrier.
- `Deployment.Δt_base` has comparison readers only, and is not recomputable
  from `N_base · h` in floats (B). Stays by §9.1's cross-validation.
- The six entry types each hold `clock` and `cursor` while `Chunk` already
  passes buffers down the walk (B). Whether the reference or the argument
  is §9.7's shape.
- `DataPlane.run_tasks` is per-`run!` state on the plane (C). D-193 says the
  loop owns the tasks; the loop could carry them into the status assembly.
- `Control.stopped` beside `lifecycle`, a deliberate gap during the tail (C).
- `TraceHeader.deployment` carries the whole `Build`, instances included,
  into primary data; `==` never compares it (C). A D-254 question.
- `TerminationRecord.t` equals `latest(sim).t` at assembly (D). §13.5 wants
  the record self-contained; keep.
- `Run.trace === nothing` is both the kill switch and the placeholder's
  state (D). D1's fix removes the double duty.
- `Walk.root` beside `flatten!`'s argument (A); `SnapshotLog.live` as a
  cached count with a stated cost (C); `Writer.blank`'s unread mask half
  (C); `StageEntry.fname` and `Executor.has_localized` as caches (B);
  `TrimReport.converged`/`.tolerances` and `Resolved.v` as compute-once
  values (E). Caches with an enforcer; not smells.

## Sequencing

1. A docs commit for the rulings the user takes: D-261 with the amendments
   to D-254, D-255, D-256, §9.2, §11.2, §13.5 and the glossary.
2. One increment for the twelve plain fixes plus the ruled changes, cut by
   slice so each stage's routed subset is small: authoring and build (A1,
   B1, B3, B4, B7, B8, B9, B10, B2), the periphery (C1, C2, C3, C4, C6, E1),
   the run and the record (D1, D3). Full suite where `sim.jl` is touched.
3. Increment 48.
