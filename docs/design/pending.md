# Pending against the spec

What `src/` and `test/` still owe the design: the constructs not yet built,
the ones built in a shape the spec's is not, and the ones awaiting a ruling.
Every item here is known and recorded; none is abandoned. `check_refs.jl` and
`check_rows.jl` read this file, so every `§N` and `D-nnn` below resolves or
the tools go red.

The 2026-09-04 conformance audit (`docs/reports/20260904_conformance/`, tip
`70672d1`) is folded in. Its merge, `01_merge.md`, is cited as `M-A1`, `M-B3`
and so on; the entry carries the argument, the probe and the line numbers at
that tip. The reports are frozen evidence; this file is the register.

## Not yet built

The bullets stand in working order, the first one next: correctness before
diagnostics, diagnostics before ergonomics, rulings early because they change
the kinds later sweeps fill, and the standard component library last.
Where the reason is not given here, the cited decision carries it:

- **Mounting** (§14.9, I 4.12): `at(prefix, ::TrimProblem)` and
  `at(prefix, ::Taps)`, and the read side's resolution from a mount point;
  `readers.jl`'s `_read_component` walks every selector path from the root.
- **The NLopt fallback** (§14.8, H 4.5): `NLoptBackend(:LN_BOBYQA)` as a
  package extension, the squared and normalized objective at `stopval = 1`,
  and the nominal-activation loop it would run on.
- **Sub-port-field addressing** (§4.2, A 4.3): no selector drills into a
  nested field of a bundle port; a ruling on the spelling comes first.
- **Index addressing in the binding register** (§14.4, M-B23): a binding
  read refuses the component index on every table member
  (`ReadBindingUnresolved`, `:indexed`), where §14.4's table admits it for
  inspection readers.
- **The `check` entry point** (M-B23): §9.7 names it once, in a
  parenthetical; whether it is a rule is a ruling to raise.
- **§13.7's standard component library** (`SumJunction{W,N}`, the Bool gates,
  `Or{N}`, `UnitDelay{V}`, `Constant{V}`, `Freeze{V}`, the rig; §6.2's
  spellings) (M-B22).

## Built in a shape the spec's is not

Transactional: the commit introducing a deviation adds its bullet, the one
retiring it deletes it, and the merge entry has the probe where the audit
found it. The first list retires bullet by bullet, each a local fix owing no
ruling; the second waits on the feature or the pass its bullet names.

### Retire alone

- **The log boxes each snapshot again** (§7.5, §11.2, M-B26): `publish!`
  boxes the snapshot once for `latest`, and `log!`, called with the concrete
  value, boxes it twice more, for `last` and for the middle. That is 288 B a
  frame on `feedback_model`, where §7.5 makes logging amortized-zero.
  Ruled 2026-09-30:
  - `log!` takes the box `latest` already holds, reloaded from the atomic
    field and passed `@nospecialize`;
  - `logged(sim)` returns a vector typed by the run's concrete snapshot
    type, since reading a `Vector{Snapshot}` costs a dynamic dispatch per
    element (24 ns against 1 ns);
  - the storage stays a vector of references. Inline records would
    preallocate 136 B a slot at every `init!` and would save nothing the
    reuse does not. §7.5's sentence on inline records softens to match,
    docs-commit-first.

  The check: a full run allocates the same bytes a frame with the log on as
  with it off.

### Retire with a feature or a pass

Currently empty.

## Awaiting a ruling

Where the code's shape is coherent and the spec may be what moves. Each is
the user's call; a ruling lands docs-commit-first, then the bullet above it
retires or the code conforms.

Currently empty.

## Pending on the spec itself

Not a code deviation: what the design documents owe their reader.

- **§11.6's wrapper sketch** writes `report!(handle, DeviceCrash(e))`,
  where the code files a crash by roster entry and the handle admits
  `MalformedDatum` alone. Ruled 2026-09-30: the sketch reads
  `report!(entry, DeviceCrash(e))`.
- **Publication's garbage and when it is collected** (§7.5, §10.7, §11.2,
  D-269). With the log and the trace off, a frame of `feedback_model` still
  allocates 816 B, all of it publication's: `_status` 656 B, the store copy
  112 B, and the snapshot object `latest` holds. §11.2 makes the GC the
  reclamation of published snapshots, so a new snapshot and table copy per
  frame are by design, and a run never avoids the GC. Two levers remain:
  - **The status records.** `_status` builds a fresh vector of writer
    records at every publication, two of them with no device attached.
    Published values never change, so an unchanged record could be shared
    with the previous snapshot. A device's heartbeat changes every frame,
    which makes this a design question.
  - **A scheduled collection.** §7.5 names `GC.gc(false)` at frame
    boundaries as a lever, and nothing in `src/` builds it. Measured on
    2026-09-30 at `h = 1 ms`, 10 threads: a young collection after up to
    about 1 MB of garbage pauses about 200 µs (p99 under 240 µs), against
    3.4 ms after 8 MB, the size the automatic collector waited for. The
    proposal: the pacer's wait collects when the bytes allocated since the
    last collection pass a budget of about 1 MB and the time to the next
    deadline exceeds the recent p99 pause with a margin, and skips
    otherwise. Unpaced runs and `step!` skip it. `PacerStatus` reports the
    pauses. Open: the knob's name and default, and whether it is on by
    default. Caveats: the trigger is process-wide, so a device that
    allocates can still start a collection mid-frame; with the log on,
    thinned snapshots die in the old generation and only a full collection
    reclaims them, unmeasured; the fixed cost grows with tasks, live heap
    and GC threads, so re-measure on a model of real size.

  A ruling and a decision entry beside D-269 come first, then the build.
- **Stop candidates.** §13.5 has two omissions with unequal loudness: a
  level that fails to re-export a stop face is refused at the next advance
  that names it, and an advance that names no face integrates a terminal
  state to `t_end` and nothing complains. A component flags its own `Bool`
  output faces as stop candidates, an annotation the framework diagnoses and
  never honours: a build warning (§9.1, D-250) where a flagged face is not
  re-exported to the root, naming the level that dropped it, and a `run!`
  advisory beside `UnboundedRun` (§11.8) where the root carries flagged
  faces and the policy names none. Who decides stays with the advance
  (D-060, D-255). It replaces the root-declared default D-060 kept on
  record, which does not compose: the default is the root type's, and a
  wrapped root has none.
- **The executor compile-cost re-measurement.** §9.7's compile-time anchors
  for a model of roughly 200–400 entries are extrapolated from synthetic
  bodies; re-measure them on a real model of that scale early, before the
  executor's shape hardens.
- **The trace header's deployment half.** The checkpoint's `deployment`,
  which the trace header carries, holds the whole `Deployment`, and through
  it the `Build` with the component instances, into an artifact §11.5 calls
  primary data; the deployment's
  `==` excludes the build, so replay never compares it. Whether the header
  should hold the build-free half is a D-254 question, to be ruled when the
  persistence deferral above lifts.
- **The exported-name audit.** The export list is to be decided deliberately
  rather than by accident; until the audit runs the module exports nothing,
  and a public name is reached by qualified name or per-name `import`
  (D-226). The audit is a full-surface sweep under the four-class naming
  convention (§8.1, D-144): every API name is exported, renamed or left
  unexported, and *unexported* is preferred for extension-only surface. That
  surface has three parts: the declaration and stage family of the import
  list (§8.1), the larger half, settled on every component file's first line;
  the binding interface `claims`/`reads` (§11.6) with the side traits
  `is_input`/`is_output`/`is_greedy`, `map_input`/`map_output` sitting
  outside the question as loop-idiom conventions the framework never calls;
  and the device contract `init!`/`loop`/`shutdown!`/`unblock!`/
  `needs_calling_task`, extended by `import` or qualified name,
  `Base.show`-style. On the operator side, `condition`, `fragment`, `at`
  and `combine` (§14.2) are generic names that share a namespace
  with user domain code; the `Base.merge` piracy surface is retired with the
  combinator's rename (D-204), the mixed-argument methods staying error
  methods; the `get_` prefix settles the readers (§14.4); and whether the
  condition algebra ships behind a submodule is the packaging question. Four
  boundary cases the convention does not settle are flagged for the sweep,
  none a defect of its list:
  - `input_faces`/`output_faces`, noun accessors that pun on the `_types`
    declarations, mitigated by being framework-facing;
  - `loop` (§11.6), a mutating task body spelled as a bare noun among its
    verb-`!` siblings `init!`/`shutdown!`/`unblock!`; with `run!` taken and
    the "loop body" prose entrenched, it needs the whole-surface view;
  - the bare-noun accessors `trace(sim)`, `latest(sim)`, `binding(handle)`,
    `phase_bodies(sim)`, value selectors outside class (2)'s `get_` rule;
    `trace` is the sharpest, its kill-switch `trace = false` and post-run
    accessor `trace(sim)` being one name in two senses, the overload pattern
    D-122 and D-144 retire;
  - whether class (1) needs an explicit exemption for predicate traits
    (`is_greedy`, `needs_calling_task`).
- **The GUI panel authoring API.** The semantics are settled (§11.7): derived
  liveness, first-class read-only rendering, own-pending-else-snapshot peek,
  stage-on-interaction, orphan display. The framework's half of the calling
  convention is fixed too (D-270): the port view, the handle and a snapshot
  are the three values a panel reads. What stays deferred is the GUI
  package's half: what the drawing context bundles beside them, how it
  scopes to a child, and the widgets, to be co-designed against the GUI
  library under §11.7's four constraints. `gui = true` (§12.6, Appendix B)
  attaches that package's device, so the flag waits on it.
- **Log and trace persistence.** The in-memory artifacts are settled and
  nothing on-disk is. The log is the retained boundary snapshots (§11.2); the
  input trace is always on and device-tagged, with its header, the
  checkpoint `init!` takes after boundary zero (§11.5, §12.6); the log is
  recomputable from the trace, never the reverse. The on-disk questions wait for real users
  to ground them: the HDF5 export scope (the whole snapshot log, or selected
  subtrees); field-handle summarization over retained snapshots, the
  post-processing entry point, as `getproperty`-style navigation of a run's
  history; and the trace file format, which doubles as the reproducibility
  carrier and whose positions the replay pointers name (§13.4).
