# Cadence.jl

The design and a walking skeleton of a simulation framework for hierarchical
continuous and discrete models. It is meant to replace `FlightCore` in
Flight.jl. The design document is the product here, and the prototype exists to
keep it honest. This repository was spun off from Flight.jl's `core-redesign-2`
branch on 2026-08-29, carrying that branch's history.

## Reading order

`docs/` has two halves: `docs/design/` is the design, `docs/implementation/`
covers the walking skeleton in `src/` and `test/`.

- `docs/design/spec.md` is normative. It defines the framework.
- `docs/design/decisions.md` is the decision log, 217 entries. Each one
  records a ruling and the alternatives it rejected.
- `docs/design/tools/spec_style.md` and `docs/design/tools/decisions_style.md`
  set the conventions for those two documents. Read the matching one before
  editing either.
- `docs/design/companions/` holds the worked explainers the spec cites.
- `docs/design/briefs/` holds the increment briefs.
- `docs/implementation/status.md` orients a coding session. Read it before
  touching `src/`. It points to `docs/implementation/map.md` and
  `docs/implementation/tests.md`, which you read on demand.
- `prototypes/cellstore_bench/` is the frozen cell-store bench behind D-162.
- `prototypes/sketch_decoder.jl` is a pre-design syntax sketch. It is not
  runnable and its section numbers are stale; its header says so.

## Status

`src/` is a flat include set, not yet a package module. Converting it into one
top-level `module Cadence` with flat includes and a UUID in `Project.toml` is
pending.

## Commands

Run the test suite from the repository root:

    julia --project=. test/runtests.jl

Check the design documents' cross references:

    julia docs/design/tools/check_refs.jl

The other design tools sit beside it in `docs/design/tools/`.
