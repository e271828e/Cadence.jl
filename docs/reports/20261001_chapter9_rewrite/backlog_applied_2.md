# Backlog applied, batch 2 — R72–R85, R87–R93, R95–R96

Uncommitted. Battery green: `check_refs.jl`, `check_rows.jl`,
`check_glossary.jl --strict` pass, and `linkify.jl` re-runs as a no-op.

## New entries (`decisions.md`, after D-282)

| entry | title | rulings | source fields |
|---|---|---|---|
| D-283 | Bind `Δt_base` against anchor-relative rate triples | R72, R73 | D-186 Rationale (fold, tables, three sources, declare rule, pool, exact resolution) and Rejected (silent derivation); D-254 Rejected (schedule on the `Build`); D-185 Rejected (floats). `Δt_base = :derive` has no prior entry: §9.2 and Appendix B, said so in the Rationale. |
| D-284 | Attribute grid refinement to every driver, against the actual pool | R74 | D-187 Rationale (every `r_p > 1`) and Rejected (simple-fraction test, crowning one factor). |
| D-285 | Probe return checks, hand-down and placeholder sources, and totality's two homes | R77, R78 | Non-`NamedTuple` return: §9.3 alone (D-036 rules the return law). `DeadStage`: D-165 Position, D-194 bullet 5, fail-fast from Appendix C and §13.1. Hand-down: D-169 Rationale, D-252. Placeholder `1.0`: §9.3 alone, D-115 calls it settled. Dispositions: D-142 Rationale and Rejected. |
| D-286 | Hold a pinned leaf to the exact check as the schema-visible freeze | R79, R80 | D-238 Position and Rationale, D-263 bullet 1, Rationale and Rejected, D-166 Rationale (the old hint), D-079 Rationale and Rejected, D-266 Rationale and Rejected. Hint wording "remove its `Pinned`": §8.2 and §9.5 alone. |
| D-287 | Handler-return keys, struct-valued port embedding and the branchless payload | R81, R82 | D-090 Rationale and Rejected; D-053 Rejected. Cross-eltype constructor: §9.5 alone. |
| D-288 | The executor's structure: phase bodies, views, construction, the gate and publication | R83, R84, R85 | D-086 Rationale and Rejected; D-185 Rationale; D-147 Position and Rejected; D-116 Rationale and Rejected. Chunking and the ladder left out; the Rationale says they wait on the compile-time ruling in `pending.md`. |

C OQ3 is left out of D-287. D-238's "rebuilds the declaration from" the
leaves concerns normalizing a type parameter and names no constructor, so it
does not bear on the wording.

## D-282 (R75)

Position gains a bullet: "The `Build` is immutable apart from its lazily
filled activation dictionary, and may back any number of deployments and
`Simulation`s concurrently."

## Annotations (dated 2026-10-02)

- D-048, after Rationale: "amended by D-254. Deployment binding moved from
  `Simulation` construction to the `Deployment` constructor."
- D-119, after Rationale: same text.
- D-187, after Rationale: "amended by D-254. The bound schedule is the
  `Schedule`, and it lives on the `Deployment`, not on the `Simulation`."
- D-253 bullet 5, inside the bullet: "'under the existing lock' defers to
  D-135 and D-281. The mechanism is unspecified, and a lock is one that
  suffices."
- D-253 last bullet, inside the bullet: "superseded by D-259. The nominal
  evaluation fixes both the structure and the `Float64` typing, and no
  activation step runs at `Float64`."
- D-053, after its 2026-09-08 annotation: "amended by D-249. The payload
  carries no simulation time; the `StepError` carrier's frame holds the
  boundary time."
- D-235, after Rationale: "D-166 is superseded by D-263, under which D-166's
  embed-accept relation survives; the embed-accept named here is now
  D-263's."
- D-077 (R90): not added. D-077 already carries the 2026-09-24 annotation
  saying the allocator takes the scalar on both tiers, a discrete one
  receiving `Float64` (D-263). The survey missed it.

## Spec fields

- D-078: §4.4 → §4.4, §9.1.
- D-060: §13.5, §14.4 → §9.3, §13.5, §14.4.
- D-099: §14.10 → §9.4, §14.10.
- D-157: §8.4, §13.4 → §8.4, §9.5, §13.4.
- D-048: new field, §9.1.
- D-050: new field, §9.3.
- D-070: new field, §14.8 (the trim service's LM, backend, bounds, scratch
  stores and report live there; §9.6 only sketches the commit rule).
- D-261: adds §9.1 before §9.2.
- D-253: adds §9.7 after §9.4.
- D-033: drops §9.7.
- D-106: drops §9.7.
- D-163: drops §9.7 (no float-comparison rule there).
- D-152: drops §9.5 (no auto-publication there).
- D-168: drops §9.5 (no fan-out meet there).
- D-079: ratified, not superseded; its leaf walk is in §9.4 and its
  conformance split and exact embedding in §9.5. §7.1, §8.5, §14.10 → §7.1,
  §8.5, §9.4, §9.5, §14.10.
- D-066, D-256, D-166: untouched.

## Chapter 9 citations (`spec.md`)

- §9.1, fold table lead: `([D-186][d-186])` → `([D-186][d-186],
  [D-283][d-283])`. Kept D-186: the `Absolute` row's severing is its
  Position.
- §9.2, "`Structure`'s timing tables are anchor-relative": D-186 → D-283.
- §9.2, "`Δt_base` has exactly one of three sources": D-186 → D-283.
- §9.2, "If any unanchored component exists, deployment must declare
  `Δt_base`": D-186 → D-283.
- §9.2, "Every `r_p > 1` is listed": D-187 → D-284.
- §9.2, "Blame is computed against the actual pool": D-187 → D-284.
- §9.2, "The grid diagnostics live on the `Deployment` and print from the
  pool, exactly": `([D-254][d-254])` → `([D-187][d-187], [D-254][d-254])`.
  Not in the brief. The two replacements above left D-187 uncited in the spec
  and `check_rows.jl` failed coverage. D-187's Position rules that the grid
  gets exact diagnostics, so it belongs on this sentence.
- §9.3, `DeadStage` fail-fast: `([D-194][d-194])` → `([D-194][d-194],
  [D-285][d-285])`.
- §9.3, plausibility check: `([§13.5][s13-5], [D-060][d-060])` → `([§13.5][s13-5],
  [D-060][d-060], [D-285][d-285])`.
- §9.3, "Its home is the test suite": D-142 → D-285.
- §9.5, pinned leaf exact check: `([D-238][d-238], [D-263][d-263])` →
  `([D-286][d-286])`.
- §9.5, "The pinned leaf is the schema-visible freeze": D-263 → D-286.
- §9.5, "The returned NamedTuple's key set is checked first": D-090 → D-287.
- §9.5, "`x` must be complete …, while `m` may be partial": `([D-053][d-053],
  [D-090][d-090])` → `([D-053][d-053], [D-287][d-287])`.
- §9.5, "The source branch is deliberately absent from the payload": D-053 →
  D-287.
- §9.7, "Phase bodies are the outer decomposition … semantically forced":
  D-086 → D-288.
- §9.7, `t*` arity selection: `([D-147][d-147], [D-185][d-185])` →
  `([D-147][d-147], [D-288][d-288])`.
- §9.7, "Views are spelled rebuild-per-call": D-086 → D-288.
- §9.7, "Construction is type-opaque": D-086 → D-288.
- §9.7, "Publication is not a phase body": D-116 → D-288.

- §9.2, "The `Build` is immutable apart from its lazily filled activation
  dictionary …": D-135 → D-282. Retargeted by the orchestrator after this
  batch's run.

## Fixes

- `spec.md` §10.4 convergence paragraph: "`localization_tol` is a
  `Simulation` deployment keyword" → "… is a `Deployment` constructor
  keyword".
- `spec.md` glossary, `Δt_base`: "It is bound at `Simulation` construction"
  → "It is bound at the `Deployment` constructor".
- `tools/check_refs.jl` roster comment: "out of linkify.jl's roster: their
  citations stay plain, as decisions.md's do." → "out of linkify.jl's
  roster, which rewrites decisions.md, extensions.md and the companions
  besides spec.md: their citations stay plain."

## Fixes after verification

From `backlog_verify.md`, each checked against its source entry.

1. D-235 annotation: "… under which D-166's embed-accept relation survives;
   the embed-accept named here is now D-263's." → "… under which D-166's
   embed-accept relation survives. D-238 states it, decided on the type."
   D-238's Position states the relation; D-166's 2026-09-24 annotation says
   it survives D-263.
2. D-286 Rejected: dropped the item "*Superseded position — the hint 'if `F`
   participates in differentiation, declare it `T`' (D-166):* it named the
   two-argument form, which fell with D-166's mandate. (As recorded in
   D-263.)" D-263 never mentions the hint, and D-166 records the hint but no
   rejection of it.
3. D-288 headline: "The executor's structure follows from full
   specialization, and two options it opens stay uncommitted." → "The
   executor's structure is fixed in five parts, and two options it opens
   stay uncommitted."
4. D-288 bullet 4: "… and finer recompilation granularity, under which
   editing a discrete component invalidates the boundary body and not the RHS
   body." → "… and finer recompilation granularity. Editing a discrete
   component already invalidates the boundary body, not the RHS body, under
   the two-arity split." Rationale gains: "That a discrete edit invalidates
   the boundary body and not the RHS body is an implicit commitment the
   two-body split makes true (as recorded in D-147)."
5. Spec fields: D-285 §9.3 → §5.2, §9.3, Appendix C (§5.2 states `DeadStage`
   at the probe; Appendix C its fail-fast row). D-287 §9.5 → §5.2, §9.5
   (§5.2's handler return law states the per-key checks and the
   did-you-mean).
6. This file: the §9.2 immutability citation is recorded as retargeted from
   D-135 to D-282 (chapter citations, above).

Battery after the fixes: `check_refs.jl`, `check_rows.jl` and
`check_glossary.jl --strict` pass, and `linkify.jl` re-runs as a no-op.
