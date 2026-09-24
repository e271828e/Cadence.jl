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

- **§12 beyond its built slices**: pause and the control plane's surface; the
  operator interrupt — §13.4's carve-out exists, the masking and the entry do
  not, so a stopped run can hold mid-boundary stores here; §13.4's
  interactive-session behaviour (log and surface the status rather than
  rethrow) has no discrimination in `run!`.
- **§11.7's GUI write path**, §10.7 pacing and its diagnostics, the §11.8
  remainder (`DebtReanchor`, `ThreadBudget`, the maxlog renderer).
- **§14**: `linearize` (§14.10) and its tap register (`TapResolution` reads
  the read register alone today), mounting (§14.9), the NLopt fallback and the
  nominal-activation loop it would run on; sub-port-field addressing; index
  addressing in the binding register; the `check` entry point (M-B23).
- **Smaller** (M-B26): no `report!(entry, d)` addressed by roster entry, only
  the internal `_report!(cell, d)`; the face table keeps the resolved endpoint
  and discards §9.1's routing chain that §13.7's face-route printer would print;
  `capture`, the trace header and the compiled `Reader` are three walks over the
  same stores against §14.1/§14.4's "one mechanism"; no `sizehint!`, and
  the log is a `Vector` of snapshot references, not inline records; the
  roster is a mutable `Vector` re-read every frame, frozen by
  `assert_stopped`'s policy rather than by type; the suite has no
  every-component `Dual` sweep, so D-166's CI policy is one fixture; the
  once-per-frame `ReplayDiscardedStaging` noise from a live device during
  replay is unpresented (§11.8).
- **§13.7's standard component library** (`SumJunction{W,N}`, the Bool gates,
  `Or{N}`, `UnitDelay{V}`, `Constant{V}`, the rig; §6.2's spellings) (M-B22).
- **Naming, the loose ends** (the `src/` passes and the `test/` sweep
  landed 2026-09-24; `docs/reports/20260924_naming_inventory_test/README.md`):
  the short fields the field rule reaches that the `src/` inventory's §5
  never named (`briefs/brief_naming_src_remainder.md`, "Noted, not in
  scope"); `trim.jl`'s local `off`; and a ruling on whether the rule
  against sharing an API name covers a prefixed twin (`_gather`,
  `_report!`, `_stage!`, `_drain!`, `_reads`). A loose fix and a ruling,
  not a sweep.

## Built in a shape the spec's is not

Transactional: the commit introducing a deviation adds its bullet, the one
retiring it deletes it, and the merge entry has the probe where the audit
found it. The first list retires bullet by bullet, each a local fix owing no
ruling; the second waits on the feature or the pass its bullet names.

### Retire alone

Currently empty.

### Retire with a feature or a pass

Currently empty.

## Awaiting a ruling

Where the code's shape is coherent and the spec may be what moves. Each is
the user's call; a ruling lands docs-commit-first, then the bullet above it
retires or the code conforms. Currently empty.

## Pending on the spec itself

Not a code deviation: what the design documents owe their reader.

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
  `Base.show`-style. On the operator side, `condition`, `fragment`, `at`,
  `capture` and `combine` (§14.2) are generic names that share a namespace
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
  stage-on-interaction, orphan display. The calling convention is deferred:
  context contents, port naming, child composition, to be co-designed
  against the GUI library under §11.7's four constraints.
- **Log and trace persistence.** The in-memory artifacts are settled and
  nothing on-disk is. The log is the retained boundary snapshots (§11.2); the
  input trace is always on and device-tagged, with its header of initial
  stores and root input values (§11.5, §14.5, §14.6); the log is recomputable
  from the trace, never the reverse. The on-disk questions wait for real users
  to ground them: the HDF5 export scope (the whole snapshot log, or selected
  subtrees); field-handle summarization over retained snapshots, the
  post-processing entry point, as `getproperty`-style navigation of a run's
  history; and the trace file format, which doubles as the reproducibility
  carrier and whose positions the replay pointers name (§13.4).
- **The trace header's deployment half.** `TraceHeader.deployment` carries
  the whole `Deployment`, and through it the `Build` with the component
  instances, into an artifact §11.5 calls primary data; the deployment's
  `==` excludes the build, so replay never compares it. Whether the header
  should hold the build-free half is a D-254 question, to be ruled when the
  persistence deferral above lifts.
- **The executor compile-cost re-measurement.** §9.7's compile-time anchors
  for a model of roughly 200–400 entries are extrapolated from synthetic
  bodies; re-measure them on a real model of that scale early, before the
  executor's shape hardens.
- **The trim post-commit target read-back.** Under elimination, a
  params-vs-world handle mismatch converges to a true equilibrium at an
  unintended operating point, and nothing complains (D-139). One evaluation
  of the sweep after the commit, comparing the achieved targets against the
  requested ones, catches the whole class. It belongs on `TrimReport`, beside
  the unbalanced equations and saturated decision variables it already names
  (`companions/trim_environment_walkthrough.md`).
- **A root-declared `stop_on` default.** §13.5 keeps one variant on record
  for reopening: a root-declared `stop_on` default, overridable per advance.
  Reopen it only if the per-advance keyword proves chronically forgotten.
