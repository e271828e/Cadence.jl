# Backlog applied, batch 1 — R65–R69, R97–R103

Uncommitted. Battery green: `check_refs.jl`, `check_rows.jl`,
`check_glossary.jl --strict` pass, and `linkify.jl` re-runs as a no-op.
Chapter 9 untouched.

## R65 — `spec.md`

- §14.10, `activations`: `([§9.7][s9-7])` → `([§9.4][s9-4])`.
- Glossary: the ruling's "buffer" row is the **scratch** entry (it names
  buffers; the buffer entry itself never cited §9.2). "discards with the call
  `([§9.2][s9-2], [§14.8][s14-8])`" → `([§9.4][s9-4], [§14.8][s14-8])`.
- Glossary, execution order: "zero runtime graph logic `([§5.1][s5-1],
  [§9.1][s9-1])`" → `([§5.1][s5-1], [§9.7][s9-7])`.
- §14.7: "trust-region/Levenberg–Marquardt family `([§9.6][s9-6])`" →
  `([§14.8][s14-8])`.
- Appendix C, `ArgumentInvalid`: "over the materialization's keywords
  `([§9.2][s9-2])`. The call" → "over the materialization's keywords. The
  call".

## R66 — `companions/linearization_walkthrough.md`

- `build(m; activations = (Float64, LinearizeDual))` `([§9.7][s9-7])` →
  `([§9.4][s9-4])`.

## R67 — `companions/trim_environment_walkthrough.md`

- Header: "mounting), `[§9.6][s9-6]`, and decision D-139" → "mounting),
  `flight_case_studies.md` section 4, and decision D-139".
- Mixed units: "and `[§9.6][s9-6]` keeps per-residual scalings" → "and
  `flight_case_studies.md` section 4 keeps per-residual scalings".
- D-139 record: "**`[§9.6][s9-6]`**'s claim that `Kinematics.Initializer`" →
  "**`flight_case_studies.md` section 4**'s claim that
  `Kinematics.Initializer`".

## R68 — `companions/sample_time_proposal.md`

- Section 5.3: "`Δt_base`, `h`, `N_base` already bind and validate
  `([§9.1][s9-1])`" → `([§9.2][s9-2])`.
- "collected `DeploymentInvalid`s in `[§9.1][s9-1]`'s style" →
  "`[§9.2][s9-2]`'s style".
- Amendments list, §9.1 bullet: "deployment binding gains the pool" →
  "deployment binding `([§9.2][s9-2])` gains the pool". The bullet keeps its
  §9.1 head for the triples half.
- Left as written: the section 5.2 rows (134, 266, 270 old), the §9.3 row
  (D-205) and the §9.2 bound-schedule row (D-254).

## R69 — `decisions.md`

- D-229 Position: "Deployment validation `([§9.1][s9-1])` runs" →
  `([§9.2][s9-2])`.
- D-229 Rejected: "*Deployment fail-fast under the service policy:*
  `[§9.1][s9-1]` and §10.4" → "`[§9.2][s9-2]` and §10.4".
- D-195 Rationale: "the flat buffer `([§9.1][s9-1])`" → `([§9.4][s9-4])`.
- D-272 Position: "activation through `activations` `([§9.7][s9-7])`" →
  `([§9.4][s9-4])`.
- Left: D-139, D-152, D-253, and the Spec fields.

## R97 — `spec.md` §8.7

- "They are deployment decisions fixed at `Simulation` construction (the three
  sources for `Δt_base`, [§9.2][s9-2])" → "They are deployment decisions fixed
  at deployment (the three sources for `Δt_base`, [§9.2][s9-2])".

## R98 — `spec.md` §10.4

- "`localization_tol` and `localization_budget` are `Simulation` keywords." →
  "… are `Deployment` constructor keywords." The next sentence ("They stand
  beside `h`, `N_base` and the algorithm") still reads.

## R99 — `spec.md` Appendix B

- "The third, in a fully anchored model omitting both, is derivation from the
  constraint pool" → "The third, requested with `Δt_base = :derive` in a fully
  anchored model, is derivation from the constraint pool".

## R100 — `spec.md` §13.1

- "The other two are the stage-1 probes in B and the probe chain in C." →
  "The other two are the stage-1 probes and the probe chain of the nominal
  evaluation ([§9.1][s9-1])." The §9.1 pointer is added.

## R101 — `extensions.md`

- "**Stratum A flattens whatever was declared into the same `Build`
  artifact** (§9.1–§9.2) — resolved wires, absolute divisors, schedule — so"
  → "**the structure step flattens whatever was declared into the same
  `Build` artifact** (§9.1–§9.2) — resolved wires and anchor-relative rate
  triples, whose final divisors and schedule wait for `Δt_base` at deployment
  — so".

## R102 — `tools/spec_style.md`, "The battery"

- "`linkify.jl` keeps a third roster, also `ROSTER`, naming the files it
  rewrites; a file checked but not linkified keeps plain citations, as
  `decisions.md` and `implementation.md` do." → "… naming the files it
  rewrites besides `spec.md`: `decisions.md`, `extensions.md` and the
  companions. A file checked but not linkified keeps plain citations, as
  `implementation.md` and `pending.md` do."

## R103 — `spec.md` §13.7

- After the `Outputs` sentence, added: "So does [`Events`](#g-events) (the
  nominal evaluation's event tables), which prints each component's event
  names with their policies."
- After "There are no accessor functions returning the tables alongside.",
  added: "`show(::Build)`'s parts include the events. Between the outputs
  table and the events table it prints a line of the
  [feedthrough](#g-feedthrough) edges (instantaneous input→output
  dependences). The edges are derived from the structure's connections and
  the producers' stage-2 names ([D-261][d-261])."
- "The structure step records the routing chain at every level" → "… records
  each face's routing chain at every level".

## Same staleness seen, not in the rulings

- `spec.md` §10.4: "`localization_tol` is a `Simulation` deployment keyword
  defaulting to `1e-6`" (the convergence paragraph).
- `spec.md` glossary, `Δt_base`: "It is bound at `Simulation` construction".
- `tools/check_refs.jl` roster comment: "their citations stay plain, as
  `decisions.md`'s do" (same error as R102).
