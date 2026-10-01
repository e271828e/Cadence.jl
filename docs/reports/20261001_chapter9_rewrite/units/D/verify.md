# Unit D (§9.6) — cold verification

**Counts.** 24 inventory claims. 24 MATCH, 0 DRIFT, 0 LOST. Phase 1 listed 27 assertions in new.md (V1–V27) and 13 in the companion (C1–C13). ADDED: 4 sentences, none of which changes meaning. `check9.py check D` prints `checks failed: 0`.

**Merges checked.**
- D-006 and D-019 (M12) merge into V7–V10. "Gradient-based" and "through the `T`-generic assignment math" survive, with §14.7 on the merged sentence.
- D-009's "either way" keeps its antecedent, the `Dual` default vs. the `Float64` fallback.
- D-013's "The respelling is the initializer's" spells out a link the old text left implicit. It is not a new claim.
- D-020/D-021 resolve the old parenthetical's ambiguity ("write-back including root inputs and the trace header taken after it") as "the loop takes the trace header after the write-back". Both old readings put the header after the write-back, so this is a MATCH.

**ADDED.** "Trim and linearization are stopped-sim services, and each is a client of an activation" restates the heading. The roadmap sentence is a transition. The companion's opening pointer (C1) and its roadmap are transitions too. They are missing from inventory `added`, which affects only the bookkeeping.

**Citations.**
- §14.7 survives on the merged default. §14, §7.1 and §8.2 stay with their claims.
- §4.4, §14.1 and §14.9 moved with their claims (D-013, D-014) to companion section 4 and sit on the same sentences.
- The old text had §14.7 twice. One instance went in the M12 merge and lost no claim.
- No claim lost a citation.
- The added pointers check out. §14.7 holds the pure `trim_condition` assignment and the `Dual`/`T`-generic default (spec 9800, 9858). §14.8 holds the backend, bounds packing, commit and "No commit means … untouched". §14.10 holds gather/scatter, the `get_x_ss` deletion and zero partials.
- One weak spot: "vectorization" is stated in §14.7 (9786), not §14.8. The pointer is acceptable.
- D-070 (V21) is carried, but only as a consequence. Position bullet 2 says the authoritative stores have one writer, the commit. Rejected names "warn-but-assign reborn". Keeping it plain is defensible (rulings Q1).
- D-139 (C8) is carried by the Rationale only (log 4400, "respelled as a field handle"). Its Position covers the value-level constructor, not the respelling. rulings.md lists this correctly.

**Bold.** None. The old lead words **Trim**/**Linearization** were labels, and dropping them is correct. Row 125 moved out of the spec. Row 126 stays plain as a consequence.

**Moves.**
- M12 is done as a merge, not a pure delete, and loses nothing.
- M13 is narrower than the brief's 4171–4175 range. Only the comparisons moved, and the loop's parts and the failed-trim sentence stayed. "only the assignment's output" (4154) stayed. This is defensible (rulings Q2), but the user should confirm it.
- No other moves.

**Companion vs. spec.**
- The companion restates and rules nothing new.
- After the move, the spec nowhere states the `Kinematics.Initializer`/`atmosphere::Model` respelling. It survives only in the D-139 Rationale and the companion.
- The spec loses domain math that survives aircraft-side, and `trim_environment_walkthrough.md` 502 cites §9.6 for it.
- rulings.md flags both. These are the user's call under M13.
- Dropped glossary links (`#g-face`, `#g-field-handle`, `#g-value-level-constructor`) moved with their content. The companion uses no glossary links.
