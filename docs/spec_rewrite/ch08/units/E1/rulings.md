# Unit E1: rulings and findings

## Corrections proposed

1. **The D-170 citation on the rejected spellings.** Old 2955–2956: "Three
   alternative spellings are rejected ([D-041][d-041], [D-170][d-170])".
   D-170's Rejected list (log 6006–6015) names the status quo, the
   consequence-named family `wires`/`imports`/`exports`, and two names. It
   names none of the three spellings. D-041 Rejected (log 1234–1240) holds
   all three. Proposed text: "Three alternative spellings are rejected
   ([D-041][d-041])." Left as written.
2. **No pointer at the two-producers error in the direction paragraph.**
   Old 2948–2949: "Two entries producing the same output face remain the
   ordinary two-producers error." Survey part C calls it "pointed (§6.1)",
   but the old text points nowhere, and §6.1 1327–1336 states the error.
   Proposed text: "... remain the ordinary two-producers error
   ([§6.1][s6-1])." Not added.

## Citations added or replaced

- **D-040** at "Paths are slash-separated strings" (bold). Position:
  "Slash-string paths, relative to the declaring assembly, one canonical form
  shared by declarations, diagnostics, devices and logs."
- **D-085** at the container index and key segments. Position: "`"field/1"`/
  `"field/key"` path segments" (log 2478).
- **D-211** at "its elements go by bare key". Position: "that field's
  elements are then contributed as children under their bare keys" (log
  7531).
- **D-207** at the short case of the path form. Position: "every endpoint in
  the three wiring declarations addresses an immediate child (container
  elements included) and one of its faces"; bullet 3, "Deep structural paths
  survive on the read side" (log 7402).
- **D-170**, four rulings of its Position, each with its own sentence, the
  names per D-279 and D-170's annotation:
  - "Every pair runs strictly from a child face to a child face" (bold):
    "`child_connections` (strictly child-port → child-port …)".
  - "The assembly's boundary is declared by two further methods, one per
    direction" (bold): "`exports` splits by direction into
    `input_connections` … and `output_connections`".
  - "Direction is therefore declared by the method, not inferred" (bold):
    "direction is *declared by the method*, D-041's endpoint derivation
    becoming a cross-check with a sharper error and the mixed-entry class
    inexpressible".
  - Uniqueness across both boundary declarations (unbold): "face-name
    uniqueness spans both boundary declarations".
- **D-210** at "Every entry routes to at least one internal endpoint"
  (bold). Position bullet 2: "An `input_connections` entry routes to at least
  one internal endpoint: the empty tuple is a declaration error" (log 7495).
  The old citation on the next sentence stays.
- **D-046** at "Face names are arbitrary strings with two build-checked
  invariants" (bold). Position: "Face names = arbitrary strings; build
  invariants only no-`/` + per-assembly uniqueness".
- **D-129** at "It separates structure from derived contract, not read from
  write" (bold). Position: "The two-notation rule is restated as directional
  — slash is structure, face names are contract; the write side speaks
  contract exclusively …, the read side speaks structure in inspection reads
  and contract wherever meaning must outlive the build".
- **D-041** moved one sentence earlier, to the bold "Face types and tiers are
  derived from the internal endpoints". Position: "direction and face
  types/tiers derived from endpoints (assemblies are tier-neutral —
  derivation is forced)". The direction half is superseded by D-170
  (Rationale, log 5999, "Supersedes D-041's single-method shape"); the
  types/tiers half stands. The count of D-041 citations is unchanged.
- **D-208** at "Which declaration supplies them follows the root's class"
  (unbold, see below). Position bullet 1: "For an assembly they are its
  `input_connections` keys …; for a primitive, its `input_types` keys
  directly" (log 7441).

## Rationale-only rulings

- The `===` fact, "Symmetric immutable siblings are `===`-identical, so a
  path is unrecoverable from an instance": D-040, Rejected, log 1216–1217.
  It is a fact the §8.8 helpers rely on, unbolded, and sits after the D-040
  pointer.
- "not read from write" in the two-notation rule: D-129's Position states
  the rule as directional; the explicit "never read vs. write" is in its
  Rejected list, log 3875. The bold rests on the Position.
- "Below the root nothing collides, because a primitive's input faces alias
  their producers' cells": D-210, Rejected, log 7516. The Position states
  only "Non-root primitives are untouched" (log 7493). Unbolded.

## Bold on the same entry elsewhere

- **D-208.** Unit B2 bolds D-208's Position sentence ("Any component may be
  the root of a build, and the model's root inputs are the root's own input
  faces"). E1 cites D-208 for bullet 1 and leaves it unbold, since B2 states
  the same root-input types plainly after its bold. Not a double.
- **D-085, D-211.** Unit D bolds both; E1 cites them unbold. Not a double.
- **D-210.** E1 bolds both bullets (at least one endpoint; uniqueness at the
  root). B2 cites D-210 unbold. Not a double as of this writing.
- **D-170, D-046, D-207.** Units A and F cite them unbold. Not a double.

## Inbound citations affected

None loses its target. Checked and kept: D-210 Rationale quotes "A face
feeding nothing declares nothing" (kept word for word); spec 9000 and 9985
(no `/` in a face name; a face name may contain a dot) rely on the first
invariant; spec 12245 and 6323 rely on the write side speaking face names
and on its list (devices, mappings, the trace, the GUI write path); spec 1234
on "the three wiring declarations"; spec 416 and glossary 13142 on the worked
IMU; §8.8 3248–3249 on the `===` fact; spec 4686 and glossary 12274 on root
inputs as the root's input faces.

## Open questions

- `[d-085]` and `[d-129]` have no link definition in `spec.md`. Linkify
  must add them at landing.
- D-085's Spec field (log 2482) lacks §8.6, which now cites it. Track 2.
- R4 at 2889–2890: the list of rejected path forms was already a one-clause
  pointer at D-040 and stays. The cut sentence, "A path-tracking proxy
  remains addable sugar", maps to D-040 Rejected "proxies remain sugar" (log
  1217).
- "the latch-back wire (below)" points into unit E2, now under "The
  boundary-sampling contract". If E2 moves it, the pointer may need its
  label.
- "HDF5 log tree" names a storage format the chapter does not introduce.
  Left as written.
