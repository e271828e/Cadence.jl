# Brief: step 1a, the vocabulary sweep

Step 1a of `roadmap_pipeline_redesign.md`, delivering item 31 of
`notes_pipeline_redesign.md`. Tip: `9c0346b`. Docs only; no source, no test
suite. One commit.

## What changes

The spec uses "schedule" for two different things. After this sweep each has
one word:

- **The dataflow.** The build-time evaluation order of the stage functions:
  Stratum B's product, the topological sort over the feedthrough graph, §5.3's
  "schedule positions", the executor's compiled entry list, the cursor's
  "schedule index", "schedule-free classification", the "structure, schedule,
  activation" stratum gloss, "Structure and schedule are `T`-independent", the
  `Build`'s "evaluation schedule", the build-time "scheduler", "checked
  scheduling", "unschedulable". Today's word is "schedule"; the new word is
  **"dataflow"**, one word, matching the coming `Dataflow` type.
- **The schedule.** The per-component tick timing, `(D, Φ, Δt)` with anchors
  and grid: today's "bound schedule" and "tick schedule", "the schedule the
  `Build` carries is anchor-relative", the "compiled schedule" that is `Δt`'s
  single source of truth (§10.5), the "gated schedule", a phase as "a
  schedule's offset". The new word is **"schedule"**, bare, matching the coming
  `Schedule` type. "bound schedule" drops "bound" everywhere.

The test for an occurrence: does it say *which stage functions run, in what
order* (dataflow), or *when a component ticks* (schedule)?

**Untouched, other senses.** These are not the framework's word and stay as
written: Julia's or the OS scheduler and §12.2's "loop scheduling"; gain
scheduling and scheduled gains (control engineering, ch. 15); a "scheduled
`GC.gc`"; a "bus schedule"; time events being "scheduled"; "detection versus
scheduling" for events; §10.5's heading "Multi-rate tick scheduling" (the
activity, schedule sense). Pacing's "absolute schedule", "schedule anchor" and
"re-anchors its schedule" (§10.7, Appendix C's `DebtReanchor`) are a third
sense, the wall-clock deadline sequence: leave them and list them in the
report. Appendix D.3's heading "Evaluation and scheduling" groups both senses:
leave it and flag it.

## Reading

- `docs/design/tools/spec_style.md`, whole. Especially: no em-dashes, one
  burden per sentence, content preservation, the battery.
- `notes_pipeline_redesign.md` item 31 and "The framing"; the roadmap's step
  1a.
- Every occurrence: `rg -n -i 'schedul' docs/design/spec.md` (about 150
  lines, 104 of them "schedule"). Read each in its paragraph before deciding.

## Edits, in order

1. **Glossary anchors, in this order.** First rename `#g-schedule` to
   `#g-dataflow` at every link and at the entry. Then rename
   `#g-bound-schedule` to `#g-schedule` at every link and at the entry. The
   order matters; doing it the other way merges the two. Link texts change
   with them: `[schedule](#g-dataflow)` becomes `[dataflow](#g-dataflow)`,
   `[bound schedule](#g-schedule)` becomes `[schedule](#g-schedule)`.
2. **Glossary entries (Appendix D).** The `g-dataflow` entry's headword is
   "dataflow", text as today's "schedule" entry. The `g-schedule` entry's
   headword is "schedule", text as today's "bound schedule" entry minus
   "bound". The "sweep" entry becomes "one execution of the dataflow against
   the current state". The `g-phase`, `g-build`, `g-executor`, `g-stratum`,
   `g-execution-cursor` entries take the new words per the test above.
3. **Headings, by hand** (`linkify.jl` never touches heading lines):
   §5.1 "The scheduling problem" becomes "The dataflow problem"; §5.3
   "Structural feedthrough: stage roles, schedule and step boundaries" takes
   "dataflow"; §5.3's "#### The schedule" becomes "#### The dataflow";
   §9.1's "#### Stratum B: schedule" becomes "#### Stratum B: dataflow".
   Do not edit the `## Contents` block or the definitions block at the end;
   `linkify.jl` regenerates both from the headings.
4. **Body prose.** Every remaining occurrence per the test. Repeated inline
   glosses change wholesale: "(one of the build's three phases: structure,
   schedule, activation)" becomes "structure, dataflow, activation"; "(the
   compiled execution form of the schedule)" becomes "of the dataflow". A verb
   or adjective in the dataflow sense is respelled plainly: "schedules cleanly"
   becomes "orders cleanly", "unschedulable" becomes "admits no evaluation
   order", "schedule-free" becomes "needs no dataflow" or similar. Never
   coin a verb form of "dataflow". Renaming only: if a sentence's meaning
   turns unclear under the new word, leave it and flag it. No sentence gains
   or loses a norm.
5. **`docs/design/tools/gloss_table.md`.** The rows for schedule (now
   dataflow, `g-dataflow`), bound schedule (now schedule, `g-schedule`),
   sweep, phase, `Build`, executor, stratum, execution cursor, and the
   section-index row for "bound schedule" near line 250. Leave the `n`
   counts alone.
6. **Not in scope.** `decisions.md` is history and keeps its wording;
   `implementation.md`, `pending.md`, `extensions.md`, `companions/` and the
   older briefs are untouched. `spec_rewrite_pilot.md` carries one
   `#g-schedule` link; leave it. Count "schedule" in each out-of-scope
   design file for the report.

## Battery, then commit

From the repository root, after the edits and before the commit:

    julia docs/design/tools/linkify.jl
    julia docs/design/tools/check_refs.jl
    julia docs/design/tools/check_rows.jl
    julia docs/design/tools/check_glossary.jl --strict
    julia docs/design/tools/linkify.jl        # must be a no-op

`linkify.jl` rewrites the definitions blocks of every rostered file that
cites §5.1 or §5.3, since their slugs change. Those files are part of the
commit. If `check_glossary.jl`'s `WHITELIST` names `g-schedule` or
`g-bound-schedule`, update the entry to the new anchor and report it.

Commit with `git add` **by path**, never `-A` or `.`: the uncommitted audit
refresh under `docs/reports` must stay out. Single-sentence subject, no body,
no attribution:

    Rename the evaluation order to dataflow and the bound schedule to schedule across the spec

A local post-commit hook rebuilds the PDFs when the spec changes; let it run.
Never stash, reset or check out the working tree. Do not run the Julia test
suite.

## Report

- Counts: occurrences renamed to "dataflow"; "bound schedule" renamed;
  occurrences kept as "schedule" in the tick sense; occurrences left in each
  other sense, by category.
- Every flagged line with its number: the pacing sense, D.3's heading,
  anything ambiguous or made unclear by the rename, with your reading.
- The battery's output, and the files `linkify.jl` regenerated.
- The out-of-scope counts per file.
- The commit hash.
