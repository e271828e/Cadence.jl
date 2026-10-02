# Pending

What `src/` and `test/` still owe the design, and the questions the design
leaves open, split by whether the first release waits on them. The first
section also lists the release work the spec does not ask for. Every item
here is known and recorded; none is abandoned. `check_refs.jl` and
`check_rows.jl` read this file, so every `§N` and `D-nnn` below resolves or
the tools go red.

## Before the first release

The bullets stand in working order, the first one next. The GUI's design
runs in parallel with the library. The audit comes last, because it sweeps
the whole surface and the library and the GUI both add names.

- **§13.7's standard component library** (`SumJunction{W,N}`, the Bool gates,
  `Or{N}`, `UnitDelay{V}`, `Constant{V}`, `Freeze{V}`, the rig; §6.2's
  spellings).
- **The GUI panel authoring API.** The semantics are settled (§11.7), and
  so is the framework's half of the calling convention, the three values a
  panel reads (D-270). What is still to design is the GUI package's half:
  what the drawing context bundles beside them, how it scopes to a child,
  and the widgets, to be co-designed against the GUI library under §11.7's
  four constraints. `gui = true` (§12.6, Appendix B) attaches that package's
  device, so the flag waits on it.
- **The exported-name audit.** The export list is to be decided deliberately
  rather than by accident, and until the audit runs the module exports
  nothing (D-226). The audit is a full-surface sweep under the four-class
  naming convention (§8.1, D-144): every API name is exported, renamed or
  left unexported.
  - **The extension-only surface**, where *unexported* is preferred. It has
    three parts: the declaration and stage family of the import list (§8.1),
    the larger half, settled on every component file's first line; the
    binding interface `claims`/`reads` (§11.6) with the side traits
    `is_input`/`is_output`/`is_greedy`, `map_input`/`map_output` sitting
    outside the question as loop-idiom conventions the framework never
    calls; and the device contract `init!`/`loop`/`shutdown!`/`unblock!`/
    `needs_calling_task`, extended by `import` or qualified name,
    `Base.show`-style.
  - **The operator side.** `condition`, `fragment`, `at` and `combine`
    (§14.2) are generic names that share a namespace with user domain code,
    and whether the condition algebra ships behind a submodule is the
    packaging question.
  - **Four boundary cases** the convention does not settle are flagged for
    the sweep, none a defect of its list:
    - `input_faces`/`output_faces` (§13.3), build primitives named by nouns
      where class (4) asks for plain verbs, mitigated by being
      framework-facing; the pun on the `_types` declarations that D-144
      flagged went with their rename to `u_types`/`y_types` (D-267);
    - `loop` (§11.6), a mutating task body spelled as a bare noun among its
      verb-`!` siblings `init!`/`shutdown!`/`unblock!`; with `run!` taken
      and the "loop body" prose entrenched, it needs the whole-surface view;
    - the bare-noun accessors `trace(sim)`, `latest(sim)`,
      `binding(handle)`, `phase_bodies(sim)`, value selectors outside class
      (2)'s `get_` rule; `trace` is the sharpest, its kill-switch
      `trace = false` and post-run accessor `trace(sim)` being one name in
      two senses, the overload pattern D-122 and D-144 retire;
    - whether class (1) needs an explicit exemption for predicate traits
      (`is_greedy`, `needs_calling_task`).

### Outside the spec

Release work the spec does not ask for, in no order. Where an item changes
what the spec says, the spec edit is part of the item.

- **An example model**, large enough to measure on. It gives the
  compile-time and garbage measurements a model to run on, and the GUI one
  to drive.
- **A tutorial** that takes a newcomer from a component to a run and a plot.
- **The spec's readability rewrite.** Chapter 9 is done, and the other
  chapters follow its recipe, `docs/reports/20261001_chapter9_rewrite/report.md`.
  The convention is in `tools/spec_style.md`; its bold check still has to join
  the battery. Until a chapter's turn comes, it keeps the old markers.
- **Package registration.**
- **A precompile workload** for the generic machinery a cold process
  pays, about 9 s whatever the model (§9.7).

## After the first release

Each is additive, so it can land later without breaking user code.

- **Stop candidates.** §13.5 has two omissions with unequal loudness: a
  level that fails to re-export a stop face is refused at the next advance
  that names it, and an advance that names no face integrates a terminal
  state to `t_end` and nothing complains. A component flags its own `Bool`
  output faces as stop candidates, an annotation the framework diagnoses and
  never honours: a build warning (§9.2, D-250) where a flagged face is not
  re-exported to the root, naming the level that dropped it, and a `run!`
  advisory beside `UnboundedRun` (§11.8) where the root carries flagged
  faces and the policy names none. Who decides stays with the advance
  (D-060, D-255). It replaces the root-declared default D-060 kept on
  record, which does not compose: the default is the root type's, and a
  wrapped root has none. A ruling comes first, then the build.
- **Publication's garbage** (§7.5, §10.7, §11.2, D-269). A new snapshot and
  table copy per frame are by design: §11.2 leaves published snapshots to
  the GC, so a run never avoids it. A proper analysis on a model of real
  size comes first, then a ruling beside D-269, then the build. The analysis
  should assess:
  - **Sharing status records.** `_status` builds a fresh vector of writer
    records at every publication. An unchanged record could be shared with
    the previous snapshot. A device's heartbeat changes every frame, which
    makes this a design question.
  - **A scheduled young collection.** §7.5 names `GC.gc(false)` at frame
    boundaries, and nothing in `src/` builds it. The candidate: the pacer's
    wait collects when enough garbage has built up and the time to the next
    deadline exceeds the recent p99 pause with a margin. Unpaced runs and
    `step!` skip it, and `PacerStatus` reports the pauses.
  - **What limits a scheduled collection.** The trigger is process-wide, so
    a device that allocates can still start a collection mid-frame. The GUI
    will be the main such device, so the analysis runs with it attached.
    With the log on, thinned snapshots die in the old generation, where only
    a full collection reclaims them. The fixed cost grows with tasks, live
    heap and GC threads.
- **The NLopt fallback** (§14.8, H 4.5): `NLoptBackend(:LN_BOBYQA)` as a
  package extension, the squared and normalized objective at `stopval = 1`,
  and the nominal-activation loop it would run on.
- **Log and trace persistence.** The in-memory artifacts are settled (§11.2,
  §11.5) and nothing on-disk is. The on-disk questions wait for real users
  to ground them: the HDF5 export scope (the whole snapshot log, or selected
  subtrees); field-handle summarization over retained snapshots, the
  post-processing entry point, as `getproperty`-style navigation of a run's
  history; and the trace file format, which doubles as the reproducibility
  carrier and whose positions the replay pointers name (§13.4).
  - **The trace header's deployment half.** The checkpoint's `deployment`,
    which the trace header carries, holds the whole `Deployment`, and through
    it the `Build` with the component instances, into an artifact §11.5 calls
    primary data; the deployment's `==` excludes the build, so replay never
    compares it. Whether the header should hold the build-free half is a
    D-254 question, to be ruled when this deferral lifts.

## Deviations

What is built in a shape the spec's is not. Transactional: the commit
introducing a deviation adds its bullet, and the one retiring it deletes it.
Where the code's shape is coherent and the spec may be what moves, the call
is the user's; a ruling lands docs-commit-first, then the bullet retires or
the code conforms.

Currently empty.
