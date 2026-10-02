# B3 verify report

**Counts.** 88 inventory claims: 88 MATCH (three ruled changes among them: B3-001 R6, B3-048 R7 F4, B3-084 R7 F5), 0 DRIFT, 0 LOST. ADDED: 5 (the inventory's 5), none meaning-changing. Phase 1: 101 assertions.

**Hazards checked.**
- R7 F4 (B3-048). D-238 Position lifts `Float64` positions "exactly where `P` has `T`", which is the walking-leaf keying. D-033 says nothing on embedding. Correct.
- R7 F5 (B3-084). §7.2 (spec 1587–1648) forbids `Float64` intermediates and `::SomeType{Float64}` returns, not concrete fields. D-265 Position allows `b::Float64` beside `a::T`. The drop is correct, and the rest of the M2 sentence holds.
- M2. All six claims (B3-082 to B3-088) are present, in order, after the handle walkthrough pointer and before constructibility. The heading dissolves as part C asks. "The companion obligation is constructibility at `T`" still reads as the next step after "constructors inferring the scalar" and the `InexactError`.
- Wording swaps. "pin (D-079)" for "pin as they always did" applies part F and keeps the rule. "Like `u_types`" keeps the three shared properties, and it avoids the glossary's *species*. "fails" for "detonates" (twice) keeps the meaning. The loud failure is still carried by the `InexactError` and "with its own name in the message".
- The hint and the four messages are byte-identical to old.md. The `DeckField` block is verbatim.

**Citations.** Every old citation survives with its claim. 21 added plus 1 replaced; I read each entry.
- Position fields carry their claims: D-263 b1/b3 (B3-014, 025, 026, 028, 085), D-079 Position (016, 023, 040), D-286 b2/b3 (021, 058), D-280 (064), D-194 b4 (051), D-094 (075), D-231 (076), D-238 (048).
- The six Rationale-only citations are listed correctly: D-265 (037, verbatim), D-079 (044, 052, 073), D-263 (055, 067).
- Partial: B3-068, "The stores are walked by the same rule, with no marker (D-263)". Bullet 1 carries the `x_init` walk. "with no marker" has no live entry (D-166 Rejected, superseded). Fix: none needed, but list it beside "`Pinned` has no place in a store" in the open questions.
- B3-085's "recursively for nested parameters" is implied by bullet 3, not stated. It is acceptable.

**Bold.** Three spans, each followed by its D-entry, each a single headline.
- The §9.4/§9.5 claim holds. D-280 is bold at spec 4091 (§9.4). D-238 is bold at 4258 (§9.5). D-286's first Position sentence is bold at 4291 (§9.5). Bullet 2 is plain at 4263–4270. B3 leaves D-280 and D-238 plain and bolds D-286 bullet 2 only.
- No other unit's new.md bolds D-263 bullet 3, D-079 or D-286.
- Borderline: "The first bug lurks, but is never silent" is phrased as a consequence. Its ruling is D-286 b2, and "lurks" comes from D-280 Rationale. Survey row 102 accepts it, so keep it.

**Reader-cold names.**
- (1) `RQuat` and `Ranged` are Flight.jl wrapper types. Spec 1504 names them without explaining them. Both are carried from old.
- (2) `GearContact` (landing-gear contact) and the "static terrain"/"moving deck" pair with `heave`/`pitch` are used with no introducing clause. The walkthrough pointer and the code comments partly cover the deck.
- `Engine` comes from B1's sketch. `MyStruct` is a placeholder.

**Other.**
- new.md line 89 runs past the wrap width (cosmetic).
- "The companion `handle_walk_walkthrough.md`" (l.76) and "The companion obligation" (l.92) use *companion* in two senses three paragraphs apart. The file does sit in `docs/design/companions/`. Optional fix: "The walkthrough `handle_walk_walkthrough.md`".
- Glossary: every term the old text linked is used earlier in B1/B2. No links needed.

## Re-check

I re-read new.md, inventory.json and rulings.md after the fixes.

- **"with no marker" (B3-068).** The text is unchanged, and the open question is listed. Done.
- **`RQuat`/`Ranged` gloss (l.28–29).** Spec §7.1 (1504) carries it: "Domain wrapper types (`RQuat`, `Ranged`) are not state leaves". The new §7.1 citation is listed in rulings.md. **Broken antecedent:** the gloss now sits between "Its cell carries the activation scalar" and "Value parameters … never take it". The nearest antecedent of "it" is now "domain wrapper types". Fix: write "they never take the scalar", or move the gloss to the end of the bullet.
- **Ship deck (l.71–72).** It matches `handle_walk_walkthrough.md` l.52: "a ship deck whose heave and pitch are continuous state of a sea-motion component". It claims no more than that line. B3-035 and the added list are updated, and l.79's "a moving deck" stays consistent.
- **`GearContact` gloss (l.83).** No source defines it. Nothing in the spec, decisions or `src/` names it beyond the old example, so the clause rests on the name and the coordinator's direction. The risk is low, but it is the one gloss with no named source. "That scoping" (l.83) is now two sentences from §7.2's "scoping". It is still unambiguous.
- **"The walkthrough `handle_walk_walkthrough.md`" (l.78).** Fine. *Companion* now has one sense.
- **Custom-struct rewrap.** The words are identical apart from the gloss. No cause clause dropped, no citation scope shrank, and D-263 and §7.2 stay at their claims.
- **Cosmetic.** l.72 is a short line ("state. A field that must never follow the scalar") left by the edit. It needs a rewrap.

Re-check verdict: one antecedent to fix (l.30). Everything else holds.
