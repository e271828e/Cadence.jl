# Backlog batch 2 — cold verification

Scope: the uncommitted `decisions.md` and `spec.md` changes recorded in
`backlog_applied_2.md` (R72–R85, R87–R93, R95–R96). Every cited source entry
was read in full; chapter 9, §5.2, §8.2 and Appendices B and C were read by
section. `check_refs.jl` and `check_rows.jl` pass.

Severity: **meaning** = misstates a source or changes what was decided;
**minor** = attribution, template or wording; **record** = the report file.

## 1. New entries and the D-282 bullet

### D-283 — PASS, one minor finding

Every Position bullet traces to D-186 Rationale (fold, tables, three sources,
declare rule, pool, exact resolution), D-185 (exactness) or §9.2/Appendix B
(`:derive`, explicitly attributed). Rejected items are quoted from D-186,
D-254 and D-185. Spec field correct.

- **minor.** Rationale, "All but the explicit request are recorded in
  D-186's Rationale": exactness is D-185's, as the paragraph itself says
  later. Also "one build backs many deployments … (as recorded in D-186)":
  D-186 says "many `Simulation`s". Fix: "All but the explicit request and
  exactness …"; and "many `Simulation`s (D-186), now deployments (D-254)".

### D-284 — PASS

Both bullets match D-187 Rationale and its two Rejected items, the same
strength and scope. Spec §9.2 holds both.

### D-285 — PASS, three minor findings

Each bullet is in §9.3 verbatim or near it. Sources are named correctly (D-194,
Appendix C/§13.1, D-169, D-115, D-142).

- **minor.** Rationale, "[D-194] … did not restate the error": D-194's
  bullet 5 names `DeadStage` ("`DeadStage`'s ground simplifies"). What it
  omits is that it is a fail-fast build error. Fix: "… did not restate that it
  is a fail-fast build error."
- **minor.** Rationale, "The third, defensive exhaustiveness, is D-142's
  Position": the disposition ("an `else error` is an admission that the
  function is partial") is in D-142's Rationale (iii). The Position covers it
  only through totality and "mislocated" validation. Fix: "… is covered by
  D-142's Position, its disposition in D-142's Rationale."
- **minor (Spec field).** `DeadStage` at the probe is also stated in §5.2
  ("The stage return law"), and its fail-fast row is in Appendix C. Fix: Spec
  §5.2, §9.3, Appendix C.

### D-286 — one finding that misattributes

The bullets match §9.5 and §8.2. D-238, D-263 bullet 1, D-166, D-079 and D-266
support them as the Rationale says.

- **meaning (misattribution).** Rejected item 1, *Superseded position — the
  hint "… declare it `T`" (D-166):* "it named the two-argument form, which fell
  with D-166's mandate. (As recorded in D-263.)" D-263 never mentions the hint.
  The reason is inferred, not recorded. Fix: drop "(As recorded in D-263.)" and
  say the hint's replacement has no prior entry (§8.2, §9.5). Or remove the
  item, since nothing recorded a rejection of the old hint.

### D-287 — PASS, two minor findings

Bullets match D-090 Rationale, D-053 Rejected and §9.5. Rejected items are quoted
from D-090 and D-053.

- **minor.** Bullet 1's "is a build error" comes from §9.5, not D-090. The
  Rationale credits §9.5 only for the key set's place first. Fix: "§9.5 states
  the key set's place first and that the refusal is a build error."
- **minor (Spec field).** §5.2 "The handler return law" states the per-key
  semantics and the did-you-mean. Fix: Spec §5.2, §9.5.

### D-288 — two findings that change meaning

- **meaning (overstated).** Headline: "The executor's structure follows from
  full specialization". D-086 says only that the entry-tuple form is forced by
  full specialization. It calls the phase bodies *semantically* forced. The gate
  (D-185) and publication (D-116) do not follow from specialization. Fix: "The
  executor's structure is fixed in six parts, and two options it opens stay
  uncommitted." Or name the parts.
- **meaning.** Bullet 4: "finer recompilation granularity, under which editing
  a discrete component invalidates the boundary body and not the RHS body".
  This makes the invalidation property depend on an uncommitted option. D-147's
  Rationale calls that property "an implicit commitment" that the two-body
  split makes true. §9.7 says it is "literal under the two-arity split". Fix:
  "… finer recompilation granularity. Editing a discrete component already
  invalidates the boundary body, not the RHS body, under the two-arity split
  (D-147)." Also, "deterministic" and the gloss come from §9.7, not D-086. Say
  so in the Rationale.
- **minor.** Bullet 3's "built from untyped buffers" is §9.7's, not D-086's,
  and is unattributed.

Other bullets PASS: phase bodies (D-086, renamed to current stage names), views
(D-086 Rationale and Rejected), the gate and `t*` (D-185 Rationale, D-147),
and publication (D-116). The Rejected items are quoted faithfully.

### D-282 new bullet — PASS

D-135 Rationale ("immutable artifact that may back any number of
`Simulation`s, concurrently"), lazy activation dictionary (D-135 Position,
D-281), deployments (§9.2, D-254). Matches §9.2 verbatim.

### Template and field rules, all six entries

Heading shape, Status, field order, sorted Spec fields and titles all PASS. No
history in any Position.

- **minor (template).** Four Rejected items read "*None recorded for …*"
  (D-283, D-285, D-287, D-288). No rule in `decisions_style.md` covers this,
  and no other entry uses it. Fix: add the convention to the style guide, or
  drop the items.

## 2. Annotations (2026-10-02)

| entry | verdict |
|---|---|
| D-048 | PASS. D-254 Position and Rejected ("Binding inside the `Simulation` constructor"). Placed after Rationale; no text rewritten. |
| D-119 | PASS. Same. |
| D-187 | PASS. D-254 bullet 2 and its superseded-position item. |
| D-053 | PASS. D-249 bullet 2. "No simulation time" leaves out "of its own", but D-249 also says a build-time occurrence has none. |
| D-253 bullet 5 | PASS. D-281 Rationale ("The lock under which D-253 merges … is one mechanism that suffices") and D-135. Indented in-bullet annotations have precedent (log 2004, 11213). |
| D-253 last bullet | PASS. D-259 Rationale ("fixes both the structure and the `Float64` typing"; "a C run at `Float64` would be the separate pass"). |
| D-235 | **meaning.** "the embed-accept named here is now D-263's": D-263 neither states nor owns the relation. D-166's 2026-09-24 annotation records that the relation *survives* D-263, and D-238's Position states it. Fix: "… under which D-166's embed-accept relation survives. D-238 states it, decided on the type." |

Rule 1: the diff removes no line from any annotated entry except Spec-field lines.

## 3. Spec-field changes

All PASS. Each added section holds the entry's mechanism, and each dropped
section holds none of it:

- D-078 +§9.1, the bound clause.
- D-060 +§9.3, the plausibility face and abnormal exceptions.
- D-099 +§9.4, `ProbeDual`.
- D-157 +§9.5, the nonfinite-state sibling at the catch site.
- D-048 §9.1. D-050 §9.3.
- D-070 §14.8. §9.6 also cites D-070 for the untouched-stores rule, which is
  borderline but acceptable as a sketch.
- D-261 +§9.1, the feedthrough graph not carried.
- D-253 +§9.7, the executor compiles from `Outputs`.
- D-079 +§9.4, the leaf walk, and +§9.5, the conformance split and exact
  embedding.
- D-033, D-106 and D-163 −§9.7: no inventory, no roster freeze, no float
  comparison there.
- D-152 and D-168 −§9.5: no auto-publication and no fan-out meet there.

The Spec-field gaps on new entries are listed under D-285 and D-287 above.

## 4. Chapter-9 citations

All 19 retargets to D-283–D-288, the D-135 → D-282 retarget and the added
D-187 PASS. Each new entry's Position carries the cited sentence. No sentence
lost a citation it still needs: D-186, D-187, D-142, D-238, D-263, D-090,
D-053, D-086, D-185, D-116 and D-135 each remain cited elsewhere for what they
still hold, and `check_rows.jl` passes coverage. Every bold clause touched is
a ruling headline with its D-citation in the same sentence.

- **record.** `backlog_applied_2.md` says §9.2's "The `Build` is immutable …
  (D-135)" was not changed. The diff retargets it to D-282, which is correct.
  Fix the record.
- **minor (cosmetic).** In the §9.3 plausibility bullet, the line "A
  landing-gear strut model … The face and" runs past the wrap width. Reflow it.

## Not verified

The diff also carries changes from batch 1 (`backlog_applied_1.md`): citation
retargets in D-195, D-229 and D-272, and spec edits in §8.7, §10.4,
Appendix B's `Δt_base` row, §13.1, the rendering list and the glossary. They
fall outside this brief.
