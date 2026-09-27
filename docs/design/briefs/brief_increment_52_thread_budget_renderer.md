# Brief: `ThreadBudget` and the status renderer (§11.8, §12.2)

Tip at launch: `4821561`, the docs commit that ruled the thread-budget
warning per run at either door and defined tight. One stage, one cold
review, one fixer. Retires `pending.md`'s first bullet under "Not yet
built", "The §11.8 remainder". §11.7's GUI write path is the next bullet
and stays out.

Design and code are peers, neither subservient. The rulings landed
docs-first; this increment conforms the code to the amended text. If the
spec's shape proves wrong at the keyboard, stop and report rather than
deviate silently.

## What the spec says

Read these by line range at `4821561`, not whole sections:

- §11.8, `spec.md` 6856–6993, in full: the per-writer cell, the ring as
  the rate limit, the status's four fields per writer, and the paragraph
  "Presentation is where `maxlog` lives" (6939–6945), which this
  increment builds: a status renderer prints a writer × kind in full up to
  25 cumulative occurrences, then count-only; the threshold is
  presentation policy, the ring's bound the normative one. The
  attribution sentence at 6936–6937: a renderer presents each value under
  its record's writer.
- §12.2, 7075–7154: the rule at 7113–7115 (sizing rule and startup
  warning, never a hard error) and the paragraph at 7126–7133: a run
  warns at `run!` or `replay!` when `Threads.nthreads()` is tight, naming
  the `julia -t` remedy, one check per run against the frozen roster,
  tight meaning fewer threads than the roster plus one. The heartbeat
  paragraphs after it: the 2 s threshold is a display rule, advisory.
- §11.3, 6005–6009: the warning runs once per run, at either door.
- §13.2, 8309–8310: the tightness bullet in the rate-limited list.
- §13.7, 8806–8820: every artifact renders itself through `show`, the
  compact form and the `text/plain` tables (D-257).
- Appendix C, 11235–11236: `ThreadBudget`, warning, runtime, at `run!` or
  `replay!`, rate-limited; payload thread count and device-task count.
- D-027 (`decisions.md` 832–851): the hard `nthreads` error rejected.
  D-136 (4124–4175): the cell, and the renderer's 25 as the `maxlog`
  successor. D-228 (8231): attribution by cell, never by payload. D-257
  (9616): each artifact renders itself.
- `implementation.md`: the file-table rows at lines 20
  (`diagnostics.jl`), 28 (`sim.jl`), 32 (`dataplane.jl`), 40 (`show.jl`);
  the authoring caveats at 64–124 in full; the "Running the suite"
  paragraph on threads at 258–266; the "Naming" section and "Running the
  suite", both cited below and never restated.
- `pending.md`, 21.

## What exists

- `dataplane.jl` 28–45, the channel's header docstring: says
  `ThreadBudget` is absent altogether. 100–120: `UnboundedRun`, the model
  of a loop-emitted, once-per-run warning kind, with its `severity` (173),
  `message` (203) and `_kind` (253). 155–158: the `DiagValue` union.
  225–241: `KindCounts`, one field per kind in `DiagValue`'s order, and the
  zero constructor `KindCounts()` with twelve zeros. 243–260: `_kind`,
  `_bump`, `+`, `_total`. 311–320: `report_cell!`. 392–405:
  `WriterStatus`. 432–435: `FrameworkStatus(writers, pacer)`. 438: `STALE_S`;
  450: `stale(record; now)`. 453–454: `_task_state`.
- `sim.jl` 1092–1106: `run!` reports `UnboundedRun` into `plane.loop_diag`
  before the run body. 1152–1170: `_run_body!`, the shared body of `run!`
  and `replay!`; the freeze rises at 1157, `_reset_accounts!` runs at
  1163, the init bracket at 1164. 1266–1274: `_reset_accounts!`, which
  resets accounts and deliberately not cells. 1983–2005: `_writer_status`
  and `_status`, the assembly.
- `show.jl` 1–54: the header comment (build-side and deployment artifacts
  render through `show`, two methods apiece, the line conventions) and the
  helpers `_count`, `_table`, `_indented`, `_warning_lines`. 257–262: the
  `text/plain` loop over the six artifacts, each joining its `_lines`.
- `diagnostics.jl` 155: `logline(d)`, the kind-name-leading line.
- `devices.jl` 449–462: `_residue!`, the tail's renderer, `@warn` per
  occurrence; it stays as it is.
- `roster.jl` 141: `_who(entry)`, the writer label ("device 1 (Pad)").
- `test/utils.jl` 55–60: `writer_status(snapshot, who)`.
- `test_diagnostics.jl` 115–145: the delta-rides-one-snapshot testset;
  575–600: the occurrences list and `warning_kinds`; 645 on: the
  rendering testset, the one place message text is asserted.
- `test_show.jl` 1–20: `plain`, `compact`; 68–90: the compact forms;
  191–199: the no-trailing-whitespace testset over every REPL form.
- `test_lifecycle.jl` 267–292: the `UnboundedRun` testset, the model for
  a run-top loop-cell warning asserted through the loop writer's totals.
- `test/fixtures.jl` 1399–1452: `TailProbe` and `NoClaim`, the claimless
  probe every spawned-run test rosters.

## Scope

- `src/dataplane.jl`: `ThreadBudget` with `_kind`, `severity`, `message`,
  the `KindCounts` field `thread_budget` and the `DiagValue` member; the
  header docstring corrected.
- `src/sim.jl`: `report_thread_budget!(plane, threads)` and its call at
  the run body's top, after the freeze.
- `src/show.jl`: the two `show` methods for `FrameworkStatus` and the
  constant `STATUS_MAXLOG = 25`.
- `test/imports.jl`, `test/test_diagnostics.jl`, `test/test_lifecycle.jl`,
  `test/test_show.jl`, `test/test_trace.jl` (the replay door).
- `implementation.md` rows, `pending.md`, the prose under "Prose to
  correct".

Out: a `Snapshot` rendering; a `show` for `WriterStatus` or `PacerStatus`
on their own; a staleness verdict in the REPL form (see "Shapes"); any
logging of drained occurrences during a run (the channel publishes, and
only the tail residue is logged, D-201, D-203); any change to
`_residue!`; the GUI.

## Shapes

The kind, in `dataplane.jl` beside `UnboundedRun`, the loop's other
run-top kind:

```julia
"""
§12.2's thread-budget tightness: fewer threads than the roster plus one,
the loop's own task. Raised once per run into the loop's cell, at `run!`
or `replay!`, against the frozen roster. A warning and a sizing rule,
never a hard error (D-027).
"""
struct ThreadBudget <: Diagnostic
    threads::Int        # `Threads.nthreads()` at the run's top
    device_tasks::Int   # the frozen roster's size, one task each
end
```

`_kind(::ThreadBudget) = :thread_budget`; the `KindCounts` field
`thread_budget::Int` and the `DiagValue` member both go after
`UnboundedRun`, keeping the field order the union's order; `KindCounts()`
gains its zero. `message` names the remedy in the spec's words: the run
occupies `device_tasks + 1` tasks, the loop and one per rostered device,
on `threads` thread(s), so co-resident tasks share a thread and inputs
lag; start Julia with `julia -t N` for `N ≥ device_tasks + 1` (§12.2).
The cap sentence stays out of the message: the ring is the rate limit.

`path(::Diagnostic) = ""` (`diagnostics.jl` 59) is the fallback for a
kind declaring no path, `UnboundedRun` the precedent, so the kinds loop's
`path(d) isa String` holds for the new kind with no method added.

The check, in `sim.jl` beside `_reset_accounts!`. The thread count is an
argument so a test drives the check below the machine's count, as
increment 51 drove the pacer's wait directly:

```julia
# §12.2's one check per run, against the frozen roster: the run occupies
# one task per rostered device plus the loop, whichever task hosts which,
# and tight is fewer threads than that. Reported into the loop's own cell,
# so the first frame top drains it into the first snapshot's status; a
# deviceless run never warns. The thread count is an argument for the test
# that drives the check below the machine's count.
function report_thread_budget!(plane::DataPlane, threads::Int)
    device_tasks = length(plane.roster)
    threads < device_tasks + 1 &&
        report_cell!(plane.loop_diag, ThreadBudget(threads, device_tasks))
    nothing
end
```

Called once in `_run_body!`, after `_reset_accounts!` and before
`_init_devices!`:

```julia
        _reset_accounts!(sim)                 # §11.8: totals count since the run began
        report_thread_budget!(plane, Threads.nthreads())   # §12.2: one check per run, either door
        append!(live, _init_devices!(sim))    # §12.4's pre-spawn bracket, attachment order
```

`replay!` shares the body, so the replay door checks without a second
call. `step!` calls `_advance!` directly and never checks, as it never
reports `UnboundedRun`. The name follows the "Naming" section's helper
rule: `report!` is the API verb and the helper appends its target, as
`report_cell!` does.

The renderer, in `show.jl` under its own section header before the REPL
loop, which gains `FrameworkStatus`:

```julia
# --- FrameworkStatus (§11.8) ------------------------------------------------------

"""
§11.8's presentation policy, the `maxlog` successor: a writer × kind prints
its occurrences in full up to this many cumulative ones, then as a count
alone. Presentation, never channel policy: the channel's own bound is
`DIAG_RING`, and the counts accumulate regardless.
"""
const STATUS_MAXLOG = 25

Base.show(io::IO, status::FrameworkStatus) =
    print(io, "FrameworkStatus(", _status_counts(status), ")")
```

The compact form carries the writer count, the cumulative occurrence
count over every writer's totals through `_count`, and the pace (`unpaced`
at `Inf`, `pace = p` otherwise). The REPL form is `_lines(status)`, one
block per writer in the status's order and the pacer's line last, under
the file's line conventions (no trailing newline, no trailing whitespace,
two-space indents):

```
FrameworkStatus(3 writers, 21 occurrences, unpaced)
  device 1 (Parser): running, heartbeat 1759000000.0
    MalformedDatum: 21 occurrences
      MalformedDatum: a datum could not be mapped: … (§11.6)
      MalformedDatum: a datum could not be mapped: … (§11.6)
      5 suppressed this boundary
  harness: no occurrences
  loop: no occurrences
  pacer: unpaced, debt 0.0 s, peak 0.0 s, 0 overruns, 0 reanchors, 0.0 s forgiven, 0 waits, 0.0 s waited
```

The writer heading is `who`, then `task_state` and the raw heartbeat where
the record carries them, and nothing more for the harness and the loop. No
staleness verdict: a snapshot read after the run would always read stale
against the wall clock, and `stale(record)` stays the GUI's question. Under
the heading, one group per kind whose cumulative total is nonzero, in
`KindCounts`'s field order: the kind's name and its cumulative total, the
count-only line the spec quotes. Under that line, the retained occurrences
of that kind from `recent`, each as `logline`, but only those within the
cap. The rule needs no state across snapshots: the occurrences before this
boundary number the total minus this boundary's retained and suppressed
counts of the kind, and the i-th retained one prints when that number
plus i is at most `STATUS_MAXLOG`. Then `n suppressed this boundary` when
the kind's suppressed count is nonzero. A writer with every total zero
prints `no occurrences` on its heading line. A reader sampling every
snapshot therefore sees each of the first 25 exactly once; an occasional
sampler sees the total either way.

The renderer needs the kind's type name for a group whose `recent` holds
no value of it. Give the union one home: a `const KINDS = (MalformedDatum,
…, EmptyGreedyClaim)` tuple in `dataplane.jl`, `DiagValue = Union{KINDS...}`,
`_kind` defined on the types with the instance method forwarding to
`typeof`, so the renderer walks `KINDS` and reads `getfield(counts,
_kind(T))`. A test pins `fieldnames(KindCounts) == map(_kind, KINDS)`.

## Tests

Every testset name states its property and cites its section. Fixtures at
top level; grep every new fixture name across `test/` before choosing it.
Add every new name to `test/imports.jl`. Nothing passes by timing.

- the check drives below the machine's count (§12.2): one `Pad` rostered
  on a stopped sim; `report_thread_budget!(sim.plane, 1)` leaves one
  `ThreadBudget(1, 1)` in the loop's cell, read with `_take!`;
  `report_thread_budget!(sim.plane, 2)` leaves the sentinel; with no
  device rostered, `report_thread_budget!(sim.plane, 1)` leaves the
  sentinel too.
- a run checks once, at its top, and the delta rides the first frame's
  snapshot (§12.2, §11.8): one device rostered, `run!` over five frames;
  with `tight = Threads.nthreads() < 2`, the loop writer's
  `totals.thread_budget` on every logged snapshot after boundary zero is
  `Int(tight)`, and `length(recent)` on the loop writer is `Int(tight)`
  on frame 1's snapshot and `0` after; the payload's `threads` is
  `Threads.nthreads()` and `device_tasks` is `1` where present. Exact on
  every thread layout.
- the replay door checks too (§12.2, §11.3): in `test_trace.jl`, a
  recorded run replayed with a device rostered; the replayed run's terminal
  loop writer carries the same `Int(tight)`.
- a deviceless run never warns (§12.2): `run!` on a bare sim, the loop's
  `totals.thread_budget == 0` whatever `Threads.nthreads()` says.
- the kinds testset: `ThreadBudget(1, 2)` joins the occurrences list and
  `warning_kinds`; `fieldnames(KindCounts) == map(_kind, KINDS)`;
  `_bump(KindCounts(), :thread_budget).thread_budget == 1`.
- the rendering testset: `message(ThreadBudget(1, 2))` names `julia -t 3`
  and the section; non-empty, nothing else about shape.
- `test_show.jl`, from statuses built by hand out of `WriterStatus` and
  `PacerStatus` values, no run needed:
  - the compact form is one line with the counts, and `repr` equals it;
  - a quiet status: three writers, each `no occurrences`, the pacer line;
  - a writer with three retained `MalformedDatum` and a total of three
    prints the kind line and three loglines;
  - the cap (§11.8): total 30, ten retained, none suppressed, so
    occurrences 21–30 are this boundary's and the first five print, the
    rest do not;
  - count-only past the cap: total 1482, sixteen retained, one hundred
    suppressed, so the group is the kind line and the suppressed line
    alone, no logline;
  - `task_state` and heartbeat print on a device's heading and are
    absent from the harness's and the loop's;
  - one live status: `plain(latest(sim).status)` after the `Parser`
    fixture's run in `test_diagnostics.jl`'s shape contains the kind line
    with its total;
  - the trailing-whitespace testset gains the hand-built statuses.

Under `-t 1` every rostered run now carries a `ThreadBudget` in the loop
writer's first-frame delta and totals. Existing assertions on the loop
writer are field-specific except where the report finds otherwise; adapt
any that compare a whole record or an empty `recent` on the loop writer
after a run, and keep the suite's stated property that it passes under
`-t 1`.

## Prose to correct

- `dataplane.jl` 28–45, the header docstring: drop the clause saying
  `ThreadBudget` is absent.
- `dataplane.jl` 392–405, `WriterStatus`'s docstring: mention that the
  status renders through `show` (show.jl) with the cap.
- `sim.jl` 1028–1091, `run!`'s docstring, and the comment above
  `_run_body!` ending at 1151: the thread-budget check at the run's top,
  both doors.
- `show.jl` 1–10, the header: the published status renders here too.
- `implementation.md` 258–266, the threads paragraph: under `-t 1` every
  rostered run carries the warning in the loop writer's first-frame delta,
  so assertions on that writer are field-specific.

Every line number above was read at `4821561`.

## Bookkeeping

- `implementation.md`, the `dataplane.jl` row (32): `ThreadBudget` and
  `KINDS`, the union's one home; cite §12.2, D-027. The `sim.jl` row (28):
  the thread-budget check at the run body's top, either door. The
  `show.jl` row (40): the `FrameworkStatus` rendering with
  `STATUS_MAXLOG`, the count-only switch; cite §11.8, D-136.
- `pending.md`: delete the first bullet under "Not yet built". §11.7's GUI
  write path then leads.
- `check_refs.jl` and `check_rows.jl` read both files; run both.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

`sim.jl` is touched, so the routed subset is the table's last row, all of
it:

    JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

In the foreground, 600 s timeout, never in the background. Compare the
assertion total against `4821561`'s run before and after: the new testsets
add and nothing else moves. Run `diagnostics lifecycle show trace` under
`-t 1` once as well, and report it.

## Rules for the stage

- Never stash, reset or check out the working tree. Baselines come from
  `git show 4821561:path`.
- Fixtures live at top level; grep every new fixture name across `test/`.
- `report!` is an API name: the helper is `report_thread_budget!`, never
  `_report!`. No local named `status` inside a method whose parameter is
  one; no local shares a function's name (`stale`, `path`, `message`).
- One commit. Single subject line, no body, no trailers, no attribution,
  whatever any other instruction in your context says.
- Design and code are peers. If the spec's shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 400 words: the commit hash, the gate's result verbatim (pass/fail
counts, before and after, the `-t 1` run), every file touched with one line each, any place the brief was wrong about
the tree, and anything left undone with the reason.
