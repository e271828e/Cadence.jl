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
the kinds later sweeps fill, and the spec's own migration deliverables last.
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
  `Or{N}`, `UnitDelay{V}`, `Constant{V}`, the rig; §6.2's spellings) — a
  migration-phase deliverable by the spec's word, deferred with the migration
  (`companions/migration_outline.md`, M-B22).

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

- **The trace header's deployment half.** `TraceHeader.deployment` carries
  the whole `Deployment`, and through it the `Build` with the component
  instances, into an artifact §11.5 calls primary data; the deployment's
  `==` excludes the build, so replay never compares it. Whether the header
  should hold the build-free half is a D-254 question, to be ruled when the
  on-disk persistence deferral below lifts.

### The exported-name audit

The exported-name surface is to be decided deliberately rather than by
accident. Until the audit runs, the module exports nothing, and a public name
is reached by qualified name or per-name `import` (D-226). `condition`,
`fragment`, `at`, `capture` and `combine` (§14.2) are generic names that share
a namespace with user domain code. The `Base.merge` piracy surface the
combinator once presented is retired with its rename (D-204), and the
mixed-argument methods stay error methods. For the readers, the `get_` prefix
of the selector family already settles the question (§14.4). Whether the
condition algebra ships behind a submodule is the packaging question.

The audit is a full-surface sweep (per user, 2026-08-01). Every API method
name is either specific enough to export, or gets renamed, or is left
unexported. For extension-only surface, *unexported* is the preferred
disposition. Extension-only surface has three parts.

- The declaration and stage family of the import list (§8.1) is the
  larger half of the question. It sits on every component file's first line
  and is settled there.
- The binding interface `claims`/`reads` (§11.6) and
  the side traits `is_input`/`is_output`/`is_greedy` are the second part.
  `map_input`/`map_output` sit outside the question, as loop-idiom conventions
  the framework never calls.
- The device contract
  `init!`/`loop`/`shutdown!`/`unblock!`/`needs_calling_task` is the third.
  Authors extend it by `import` or qualified name, `Base.show`-style, rather
  than call it every day.

The audit's criterion is the **four-class naming convention**
(D-144):

1. **Declarations**, which the author defines and the framework calls, are
   noun phrases or `init_*`/`_types`: `child_connections`,
   `input_connections`/`output_connections`, `state_events`, `input_types`,
   `init_workspace`, the stage and update-law names (D-220), and
   `claims(b)` from the binding interface (§11.6).
2. **Value selectors**, called against `reads` and snapshots,
   carry `get_` (§14.4).
3. **Lifecycle and mutating actions** are verbs, with `!` when they mutate.
4. **Build primitives** (§13.3) are plain verbs.

A name in the wrong class is a rename candidate on that ground alone.

The convention also has a **semantic axis**: right class, wrong noun.
`input_passthrough` (§8.8, D-171) and the binding methods
`claims`/`reads` (§11.6, D-146) are what settle it. A
bare-noun declaration names the *consequence* a declaration has rather than
its *content*. `exports` is that axis's retired exemplar (D-170). The
`*_connections` family names content deliberately, for authoring transparency.
That is a recorded choice, not class drift.

Four items are flagged for the sweep and deliberately not settled here.

- `input_faces`/`output_faces` are noun accessors that pun on the `_types`
  declarations, mitigated by being framework-facing.
- `loop`, in the device contract (§11.6), is a mutating task body
  spelled as a bare noun among its verb-`!` siblings
  `init!`/`shutdown!`/`unblock!`. With `run!` taken and the "loop body" prose
  entrenched, it needs the audit's whole-surface view.
- The bare-noun accessor family `trace(sim)`, `latest(sim)`,
  `binding(handle)`, `phase_bodies(sim)` holds value selectors outside
  class (2)'s `get_` rule. `trace` is the sharpest of them. The door's
  kill-switch `trace = false` and the post-run accessor `trace(sim)` are one
  name in two senses, which is the overload pattern D-122 and
  D-144 retire.
- Whether class (1) needs an explicit exemption for predicate traits
  (`is_greedy`, `needs_calling_task`).

All four are boundary cases the convention in D-144 does not settle,
and they are not defects of its list.

### The GUI panel authoring API

The semantics are settled (§11.7): derived liveness, first-class read-only
rendering, own-pending-else-snapshot peek, stage-on-interaction, orphan
display. What is deferred is the calling convention: context contents, port
naming, child composition. That convention is to be co-designed against the
GUI library under the four constraints (§11.7).

### Log and trace persistence

The in-memory artifacts are settled, and nothing on-disk is. Three facts stand
on the in-memory side.

- The log is the retained boundary snapshots (§11.2).
- The input trace is always on and device-tagged, and it carries its header
  of initial stores and root input values (§11.5, §14.5, §14.6).
- The primary/derived rule holds: the log is recomputable from the trace,
  never the reverse.

The on-disk questions are deferred until real users exist to ground the
choices.

- The HDF5 export scope: the whole snapshot log, or selected subtrees.
- Field-handle summarization over retained snapshots, the post-processing
  entry point: `getproperty`-style navigation of a run's history.
- The trace file format, which doubles as the reproducibility carrier. The
  replay pointers (§13.4) name positions in it.

### The executor compile-cost re-measurement

§9.7's compile-time anchors for a model of roughly 200–400 entries are
extrapolated from synthetic bodies. Re-measure them on a real model of that
scale early, before the executor's shape hardens.

### The trim post-commit target read-back

Under elimination, a params-vs-world handle mismatch converges to a true
equilibrium at an unintended operating point, and nothing complains (D-139).
After the commit, one evaluation of the sweep compares the achieved targets
against the requested ones and catches the whole class. It belongs on
`TrimReport`, beside the unbalanced equations and saturated decision
variables it already names (`companions/trim_environment_walkthrough.md`).

### A root-declared `stop_on` default

§13.5 keeps one variant on record for reopening: a root-declared `stop_on`
default, overridable per advance. Reopen it only if the per-advance keyword
proves chronically forgotten.
