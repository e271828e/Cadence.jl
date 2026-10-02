# B2 verify report

**Counts.** 88 inventory claims: 85 MATCH, 3 DRIFT (all minor), 0 LOST. 132 phase-1 assertions. 15 additions, none meaning-changing. Checker: 0 failed. Table identical to old once bold is stripped.

## DRIFT

- **B2-017.** Old: "`Int`/`Bool`/enum leaves and abstract reference-typed entries stand as they always were." New: "… admit what their declared bound admits." The prose no longer says these entries are unchanged; only the table's "as it always was" says it now. Fix: "… stand as they always were, admitting what their declared bound admits."
- **B2-045.** Old: "So **declarations record choices, and obligations are checked**." New drops "So", which loses the link to the preceding sentence. `spec_style.md`'s "Rule first" rule justifies this, and the next sentence keeps the tie. Fix: none needed, or open with "This is the doctrine:".
- **B2-043.** Old: "The obligation is still checked by the `Dual` probe". New: "It is checked". "still" (the obligation is unchanged under the permissive reading) is dropped. Fix: restore "still".

## Rulings checked

- **R2.** Both clauses stay. D-263's bullet 2 ("Both wire clauses of §6.1 stand") and D-236's Position ("Both clauses of §6.1 are this relation") carry them. The pointer sentence is true: §6.1 1282 names `WireTypeMismatch`, and 1302–1306 gives both remedies.
- **R9.** No D-166 or D-167 citation survives. The three bolds (tier scope, the obligation's scope, seedability) cite D-263 and are listed in `rulings.md`. D-263 states none of the three in any field, Rationale included. Only D-167's annotation (log 5874–5877) says they stand. So "Rationale-only" is a misnomer here, and the log owes a statement in D-263.
- **D-263 bullet 2, two bolds.** This is not one ruling bold twice. "Entries are face bounds, not cell types" is D-078's Position sentence, and "Two clauses check a wire" is D-236's Position sentence 2. Each bold has its own ruling sentence. D-263 adds support to both. Under the strict reading, where a bullet is one ruling, D-236 alone still justifies the second bold.
- **R4.** D-033 Rejected (log 1045–1046), D-078 Rejected (2285–2287) and D-054 Rationale (1555–1556) say what was cut. The halves that make the case stay ("Inputs are the component's requirements"; "predicts nothing … carry information here"). D-033 is dropped at 2313. Its text holds neither reading, so dropping it is right.
- **R7 F20.** The three sentences match D-266's Position sentence 1 and bullets 1 and 2. They claim nothing more. Placed after 2263.
- **M1.** Old 2597–2611 is fully mapped (B2-079 to B2-088). 2607–2611 is merged right after "Abstract-at-root is a build error", as the brief says. "Above" and "below" still point the right way.
- Distinctions with two halves all survive.

## Citations

Every added citation checks out against its entry: D-263 (Position; bullets 1 and 2), D-078, D-054, D-236 (bullet 3), D-208 (bullet 3), D-120 (Position), D-210 (bullet 1), D-168 (Rationale), D-266. §13.7 moved with the test-rig claim. "The unscoped variant is rejected" is now uncited, as R9 requires; no live entry holds it.

## Bold

12 bolds, each followed by its D-entry. Two are new on rulings: `IllegalPortType` (D-265 Position) and "Abstract-at-root is a build error" (D-236 bullet 3). Both are fine. No other unit bolds the same rulings. One double predates this unit: §6.1 1284 bolds "**for a continuous consumer only**", which is the same ruling as "Discrete consumers take the bound check only". `rulings.md` does not list it.

## Reader-cold names

- `RQuat` (in the verbatim table): category (1), but §4 and §7.1 already use it as a domain wrapper. Leave it.
- "a promoting aerodynamics leaf and … an AD-opaque table": category (2), mostly clear as written.
- `probe_value`: no pointer in this unit. B1 points to §9.3 earlier in the same section.

## Other

- The glossary links dropped by the section rule are correct. `component` ends up unlinked anywhere in §8.2, as `rulings.md` notes.
- The proposed `RootInputTypeConflict` correction is sound.

## Re-check

- **B2-017**: now reads "stand as they always were, admitting what their declared bound admits." This is a MATCH, and the inventory is updated to match.
- **B2-043**: "still" is restored. MATCH. The split keeps D-054 on the probe check and D-263 on the scope, so no citation scope shrank.
- **B2-045**: unchanged, as accepted.
- **R14 (B2-060)**: the sentence now reads "Two different concrete declarations remain an error, `RootInputTypeConflict` ([D-236])". D-236's Position bullet 3 (log 8680–8681) carries it: "Its concrete entries must agree at `Float64` (`RootInputTypeConflict`)". It is tagged R/R14 in the inventory and recorded in `rulings.md`. The sentence before it keeps its own D-236 citation, so both sentences cite D-236 in a row. This is harmless.
- **Nearby text**: nothing broke. No cause clause was dropped, no antecedent moved, and "That tool" and "It is still checked" still point at the right sentences. The checker reports 0 failures, with 88 claims and 15 additions. No D-166 or D-167 citation is in `new.md`.
- **`rulings.md`**: the three D-167-only rulings now sit under "Rulings no live entry states (R9)". That section correctly says D-263 holds them in no field. The §6.1 1284 double is recorded for the rulings batch. One small mislabel remains: "The unscoped variant is rejected" also has no live entry, but it is listed under "stated only in a Rationale or a Rejected list". It belongs in the R9 group. This affects bookkeeping only, not the text.
