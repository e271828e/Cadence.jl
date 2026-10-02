# ch08 unit A — cold verification

**Counts.** 118 inventory claims: 118 MATCH, which includes 11 ruled edits applied as ordered (R4, R6, R7 F2/F12/F17/F24, R8). 0 DRIFT, 0 LOST. 15 ADDED, none of which changes meaning beyond a ruling. Checker: `checks failed: 0`. Phase 1 lists 100 assertions.

**Roadmap (V4–V11).** I checked all eight descriptions against spec 1910–3390. Each one fits its section. One is incomplete: "§8.6 covers paths, wiring and faces" repeats the title, but more than half of §8.6 (3020–3178) is the worked strapdown IMU and the boundary-sampling contract. Fix: append "and works them through the strapdown IMU, ending with the boundary-sampling contract".

**R8.** "A declaration names the *consequence* it has, not its *content* ([D-146])" is the brief's wording exactly. It claims nothing more. D-146's Rationale (log 4941–4945) carries it, and rulings.md lists it as Rationale-only. The bold is allowed under "Cite the entry that rules". One tension goes to the owner and is missing from escalations.md E2. Class 1 two paragraphs above says declarations are "noun phrases naming what they return". That comes from D-267's Position (log 10531–10532, after `c512ee6`). D-146's axis contrasts "the role the declaration plays" with "the material it returns". The restored sentence now reads against class 1. The pre-`c512ee6` text was scoped to "A bare-noun declaration".

**R7.** F2 is deleted, and D-032's Position ("never essential") carries "never required". F12 is "The refusal is `ClassUnreadable` (§8.5)". §8.5 2853–2857 describes this error, and Appendix C 11759 names it. F17 has five questions in subsection order. F24 is scoped to "only a stage". Its added sentence maps `events`/`workspace` to `state_events`/`ws_init` and says no more than log 6336–6340 ("still builds silently with fewer features").

**R4.** D-117's Rejected list (log 3502–3504) carries the cut reason: the submodule has "identical silent-shadowing semantics". The rewriter's note is right. The log's "only extension idiom" is broader than the old "*unqualified*", and read literally it contradicts the qualified alternative that D-117's own Position records. The narrower fact survives in A-032 ("only through an explicit per-name `import`, or through a qualified … definition"). Nothing is lost.

**Quoted phrases.** "at build time where possible", "at first execution otherwise", "Types come by declaration, values by execution, and conformance by comparison" and "inert component" are all verbatim (new 43, 68, 186).

**`GUI.draw!`.** The clause matches §11.7 7285–7286 ("per-component extensions in FlightCore's style") and claims nothing beyond it.

**Citations.** Only D-166 was dropped, as R7/F2 orders. Every added or replaced citation is carried by the field rulings.md names: D-032 ×4, D-033 ×2 (Rationale 1024–1028), D-117 ×3, D-164 ×2, D-246, D-178, D-146 and §11.7. One soft point: survey row 4 notes that D-032's Position carries the mechanism of A-021 ("Every inconsistency fails loudly …") but not its "non-negotiable condition" wording. That is acceptable.

**Bold.** There are 11 bolds, each on a headline clause followed by its entry. D-032 has three bolds, D-164 two, D-246 two: one per semicolon ruling or Position sentence. No other unit's new.md bolds these rulings. Dropping the bold on "Every inconsistency fails loudly" is right. It elaborates the "+" clause of D-032's schema-authority ruling (build probe + always-on conformance). spec_style says such clauses share one bold, and bold never marks a consequence. Its "first in reading order" rule covers two sentences stating the *same* ruling, which this is not. The reorder now puts the elaboration a subsection before its headline. That is harmless.

**Moves.** The order and labels follow R6. There are no other moves.

**Reader-cold names.**
- Category 1: none.
- Category 3: "FlightCore's style" is fine.
- Minor, carried over from the old text:
  - `Engine` (`u_types(::Engine)`, `x_deriv(eng::Engine, …)`) appears before §8.2's `Engine` block, with no pointer.
  - `pending.md` is named twice without an introduction.
- After the reorder, "Contracts are functions of the type" uses `x_init`, `s_init`, `m_init`, `ws_init` and `state_events` before the import list or §8.2. These are Cadence's own names, and the roadmap points to §8.2, so this is acceptable.
- Glosses checked against the glossary: tier, contract, port, binding, snapshot, `StoreWithoutUpdate` (Appendix C 11750) and `ClassUnreadable` (§8.5). All are faithful.

## Re-check (after R8 was withdrawn)

The checker reports `checks failed: 0`. There are now 10 bolds.

- **Semantic axis.** New 226–227 reads "A declaration names its *content*, never the *consequence* the declaration has." This is the old sentence word for word (A-089, tag F). It is unbolded and has no citation of its own. The paragraph keeps exactly its old citations: §8.8, D-171, §11.6, D-146 and D-170 (A-090). The old bold lead-in "The convention also has a semantic axis." is now plain, which is right. rulings.md drops D-146 from both the citation list and the Rationale-only list. It carries F1 under "Left as written pending escalation E2", and escalations.md E2 now names D-267. MATCH.
- **§8.6 roadmap.** "covers paths, wiring and faces, works them through the strapdown IMU, and ends with the boundary-sampling contract" fits spec 2880–3178. §8.6 closes with "Sampling at `t_k` is a taught contract" (3152–3178). It claims nothing beyond the section. The split leaves "On the assembly side" heading only the §8.5 sentence. Nothing is lost, because the previous sentence already assigns §8.5–§8.8 to the assembly side.
- **`Engine` pointer.** "(`Engine` is the example component of §8.2)" sits at the first use (new 79), before `x_deriv(eng::Engine, …)` at 126. §8.2 opens with `struct Engine` (spec 2115), so the pointer is true. A-105's claim and its cause are intact. rulings.md lists the added §8.2 pointer.
- **Nearby.** No cause clause was dropped. No citation scope shrank. No antecedent moved: "That check" (new 187) still follows the refusal it names. One nit: new 79 and 14 are unwrapped lines over 80 columns.
