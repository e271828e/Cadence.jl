# Cadence.jl

The design and a walking skeleton of a simulation framework for hierarchical
continuous and discrete models. It is meant to replace `FlightCore` in
Flight.jl. The design document is the product here, and the prototype exists to
keep it honest. This repository was spun off from Flight.jl's `core-redesign-2`
branch on 2026-08-29, carrying that branch's history.

## Reading order

- `docs/framework_spec.md` is normative. It defines the framework.
- `docs/framework_decisions.md` is the decision log, 217 entries. Each one
  records a ruling and the alternatives it rejected.
- `docs/tools/spec_style.md` and `docs/tools/decisions_style.md` set the
  conventions for those two documents. Read the matching one before editing
  either.
- `docs/kernel_guide.md` orients a coding session. Read it before touching
  `src/`. It points to `docs/kernel_map.md` and `docs/kernel_notes.md`, which
  you read on demand.
- `docs/briefs/` holds the increment briefs.
- `prototypes/cellstore_bench/` is the frozen cell-store bench behind D-162.

## Status

`src/` is a flat include set, not yet a package module. Converting it into one
top-level `module Cadence` with flat includes and a UUID in `Project.toml` is
pending.

## Commands

Run the test suite from the repository root:

    julia --project=. test/runtests.jl

Check the design documents' cross references:

    julia docs/tools/check_refs.jl

The other design tools sit beside it in `docs/tools/`.
