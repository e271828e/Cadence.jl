# Unit B (§9.3): cold verification

**Counts.** 79 inventory claims: 77 MATCH (B-043 to B-046 correctly held in D-051's Rejected field), 2 DRIFT (minor), 0 LOST. Phase 1: 77 assertions. ADDED: 5, none meaning-changing. `check9.py check B`: 0 failed.

## DRIFT

- **B-013** (antecedent). Old: "comes from the stage-1 probes' returns, which is every stage-1 port there is". The singular "is" makes the hand-down the subject, as §5.2 does (spec 738, 886). New: "Those returns are every stage-1 port there is", which is near-trivial. Fix: "That hand-down is every stage-1 port there is (§5.2)."
- **B-049** (antecedent). Old: "the default semantics rejected above". New: "the default semantics that entry rejects". In this section "entry" already means a type entry ("consuming entry", "abstract entries"), so "that entry" can read as the root-input entry. Fix: "the default semantics D-051 rejects".
- Minor, B-038 (citation scope). The elaboration "The root-input type is the consuming entry evaluated at `Float64`" was inside the §8.2 parenthesis. It is now a separate sentence after the citation. §8.2 holds it (spec 2322). Fix: put "([§8.2][s8-2])" after the second sentence too, or join the two sentences.

## Citations

- D-050, D-051 (both uses), D-115 (both uses), D-149, D-060, D-142 (totality, parameter validation): the Position carries each claim. D-149 names `UninitializedSlots` (renamed by D-206), as rulings.md says.
- D-194 carries "no ports and is dead" but not "fail-fast" (D-165 had it, now superseded). Appendix B's `DeadStage` row says fail-fast. This is listed correctly in rulings.md.
- D-142 Rationale (i) and (ii) carry the two dispositions, but (i) says §9.3 "only cross-references" §13.5's machinery.
- "That entry rejects": D-051 Rejected carries "reads as an unwired-input default".

## Bold

There are 11 bold sentences, and each is followed by a D-citation.

- **D-115 ×2** (`ws`, `t`): these are distinct. The Position rules two separate fields, and M9 places them apart.
- **D-051 ×2** (synthesis, probe scoping): these are distinct clauses of the Position.
- **D-142 ×4**:
  - Totality and "parameter validation belongs where user-controlled data enters" are two distinct Position rulings. Keep both bold.
  - The plausibility bullet is not a D-142 ruling. Its substance is D-060's Position (an exported `Bool` face, `stop_on`), and D-142 calls it a cross-reference. Make it plain, cited "([§13.5][s13-5], [D-060][d-060])".
  - The self-consistency bullet comes from the Rationale only and is a recommendation, which the brief bars from bold. Make it plain and keep the D-142 citation.
- The D-050 bold says "nominal activation". The F11 proposal ("nominal evaluation") is well supported.

## Moves

The paragraph split, M9 (`t` and `Δt` merged after synthesis and scoping) and M10 were done. The workspace passage was kept. No other moves were made.

## Reader-cold names

- **(1) Flight.jl machinery.** "Three habits of shipped code": the shipped code is Flight.jl's `landinggear.jl` (D-142 Rationale), named nowhere. Add "in Flight.jl's landing-gear model" or similar.
- **(2) Aerospace examples needing a clause:**
  - "a strut throwing on a touchdown overload";
  - "contact algebra cancels a velocity component";
  - `else error("unrecognized surface type")` (ground surface kind);
  - "a coefficient constructor asserting an ordering of its arguments", which is opaque without "friction coefficients, static ≥ dynamic".
  - `pilot.elevator_axis` is fine inside the quoted message.
- **(3)** None.
- **Other cold terms (not Flight).** "branch-shape rule" is defined at spec 2651 with no pointer, as in the old text. `RQuat` and `Ranged` are defined in ch. 8 (spec 1504, 2382), as in the old text.

## Other

- New line 4–5 roadmap and the "`t` is a clock value, sourced below with `Δt`" pointer are fine.
- F12 (`Simulation` vs `Deployment` binding `Δt_base`) is carried unchanged and proposed correctly.
- "It runs that early" (new line 41): "It" is ambiguous between `ws` and the allocator. Use "The allocator runs that early".
