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

- **The pipeline redesign, D-250 through D-258**, delivered by increments
  43–48 per `docs/design/briefs/roadmap_pipeline_redesign.md`. Seven themes.
  The port model: auto-publishing goes, ports are stage 1 or stage 2, and an
  exposed state field is returned from `output_state` (D-252), delivered by
  increment 43. The build-side types: `Structure`, `Dataflow` and `Events` as
  named step products, one activation dictionary on the `Build`, and the
  structural consumers reading them instead of the nominal activation (D-253),
  delivered by increment 44. §8.8's selectors: the `select` predicate,
  `:multiple_selectors` and `EmptyFaceSelection` (D-251), delivered by
  increment 45. The warning homes: the artifact criterion, `warnings` on the
  `Build` and the scoped channel the build binds, delivered by increment 44;
  `Deployment`'s own list is delivered by increment 46, and `EmptyGreedyClaim`
  into the roster entry's cell by increment 47 (D-250). `Deployment` and
  `Schedule` as artifacts, with D-187's grid diagnostics on the deployment
  (leave-one-out factors, prime attribution, nearest non-refining offsets, the
  derivation line and `GridUtilization`), delivered by increment 46 (D-254).
  The run: `Run{T}`, the
  trace split into header plus `schemas` and `batches`, `StopPolicy` per
  advance, `UnboundedRun` and the `Simulation`'s five fields are delivered by
  increment 47 (D-255, D-256).
  The renderings: `show` for `Structure`, `Dataflow`, `Schedule`, `Build` and
  `Deployment`, with the binary hyperperiod-chart guard at 100 base ticks
  (D-257). Nothing else of it is built today (M-B26).
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
  and discards §9.1's routing chain that §13.7's provenance would print;
  `capture`, the trace header and the compiled `Reader` are three walks over
  the same stores against §14.1/§14.4's "one mechanism"; no `sizehint!`, and
  the log is a `Vector` of snapshot references, not inline records; the
  roster is a mutable `Vector` re-read every frame, frozen by
  `assert_stopped`'s policy rather than by type; the suite has no
  every-component `Dual` sweep, so D-166's CI policy is one fixture; the
  once-per-frame `ReplayDiscardedStaging` noise from a live device during
  replay is unpresented (§11.8).
- **§13.7's standard component library** (`SumJunction{W,N}`, the Bool gates,
  `Or{N}`, `UnitDelay{V}`, `Constant{V}`, the rig; §6.2's spellings) — a
  migration-phase deliverable by the spec's word, deferred with §16 (M-B22).

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
  on-disk persistence deferral (§16) lifts.
