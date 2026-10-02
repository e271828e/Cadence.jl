# B2 cold verification

**Counts.** 91 phase-1 assertions. 86 inventory claims: 84 MATCH, 2 DRIFT, 0 LOST. R5's three cut claims (B2-075, -078, -079) are held. §9.2's bullets hold the positive tolerance, the integer ≥ 1 for both budgets and the collected `DeploymentInvalid`. "All three are recorded … trace header … replay compares" holds the trace-header and replay parts for `firing_budget`. Appendix B (spec 11156) and D-256 hold `firing_budget` as a constructor keyword. F6 changed only "both/neither" to "all three/none", twice. "Both localization constants" only clarifies. The endpoint argument is exact: "holding endpoint", "strictly later than the published, immutable tₙ", `nextfloat(tₙ)`.

**DRIFT**
- B2-012. Old: "…is exactly the epoch-caused edge, and that case never reaches the root-finder." New: "…epoch-caused edge. That case never reaches the root-finder (D-182)." The second reason has dropped out of the "because". Fix: "…epoch-caused edge, and that case never reaches the root-finder ([D-182])."
- B2-071. Old: "which the §14.8 doctrine forbids". New: "which the no-throw doctrine of §14.8 forbids". The added name is undeclared. §14.8 is the trim service, and its "no-throw doctrine" (spec 10405) concerns `TrimReport`, not `StepError`. The old citation itself looks stale. §13's "exceptions-are-abnormal doctrine" (spec 7937) is the likely target. Fix: restore "the [§14.8] doctrine" and list the citation under Corrections proposed.

**ADDED (meaning-bearing)**
- The `stop_on` gloss "the read of the per-advance termination faces" puts "per-advance" on the faces. The glossary puts it on the keyword. Fix: "the read of the termination faces `stop_on` names".
- The other glosses (snapshot, pacer, projection, trace header, replay, `Deployment`) and the §10.5 and §9.2 pointers stay within their sources.

**Citations.** All old citations survive with their claims. §11.5 now sits on the trace-header gloss and §12.7 on replay's compare. That is narrower but correct. Every added cite checked against decisions.md: D-082 Rationale, D-182 Rationale, D-081 Rationale and Rejected, D-181 Position and Rationale, D-147 Position ("empty at `t*`"), D-128, D-230, D-018 (two Position clauses), D-133 ("per-frame localization allowance, default 8"; "**recorded**") and D-256 (bullet). Each named field carries its claim.

**Bold.** 10 bolds. Each is a headline clause with its citation. None is on a mechanism or a lead-in.
- D-082 fails the one-bold test. In its Rationale, "localization returns the holding endpoint —" chains t* = tₙ impossible, guard holds, and "t* = tₙ₊₁ degenerates" as elaborations of one segment. "Grid times indexed" is a second segment. So `t* = tₙ₊₁` exactly is legitimate should be plain, keeping its D-082 cite. The text already leaves "guard observably holds", from the same segment, plain.
- D-081 passes on substance only. Its Position rules one thing (`t*` is a boundary, bold in unit A). The Rationale's segment 2 comma-chains ticks, no drain and no pacing. A strict semicolon reading allows one bold there, and the text has two. The Rejected list rejects drain and pacing in separate bullets, so they are parallel rulings and not elaborations. Defensible. Note it in rulings.md.
- D-133/D-181 "All three are recorded" elaborates the parameter rulings under a strict reading. D-133 bolds **recorded** itself. Defensible.
- Across units, B1's "interpolant is then invalidated" and B2's "Budget exhaustion degrades" share D-018's "+"-chained segment 2. This is the same parallel-items question.

**Moves.** All done: the four labels in order, Consequence made plain, D-081 cited, the no-tick reason plus the §10.5 pointer, R5 and F6. The budget comparison is absent. No other moves.

**Glossary placement.** "replay" is used at line 55 ("replay determinism") and line 64 before its link and gloss at line 123. Move the link to line 55. The `Deployment` link is at B2's first use. B1 line 187 uses it earlier, unlinked (open question 3).

**Reader-cold names.** No class 1 and no class 3. Landing-gear struts (class 2) are self-introduced and claim nothing beyond the old text. Pre-existing gaps: `h′` (the remainder step's length) is never defined, and `StepError` has no pointer to §13.4.

## Re-check

I checked all seven edits against old.md, the log, new.md and inventory.json. All are clean.

1. B2-012 is rejoined inside the "because" and keeps D-182. Its scope matches old.md.
2. B2-071 is accepted. D-070's Rejected list (log 1994) says "an expected outcome, not broken machinery". §14.8 names the no-throw doctrine (spec 10405). "no-throw" is declared under `added` and in rulings.md.
3. The `t* = tₙ₊₁` sentence is now plain and keeps D-082.
4. D-081's two bolds are noted in rulings.md.
5. The `stop_on` gloss now matches the glossary.
6. The replay link and gloss sit at the first use ("the determinism of replay"). The meaning is unchanged, and the later "replay compares" is plain.
7. The old text supports the `h′` gloss. It says the remainder step targets the grid point "with `h′` derived at use". D-082's Rejected entry `t ← t* + h′` makes `h′` the step from `t*`. The glossary's remainder-step entry pairs the two. The new `StepError` (§13.4) citation is correct, since §13.4 defines the carrier. It is declared, and this is its first use in §10.4.

One cosmetic point remains. Lines 32–34 break oddly at "(the remainder / step's length) derived / at use"; re-wrap them.
