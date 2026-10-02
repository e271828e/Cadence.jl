# Unit D verify (§8.5)

**Counts.** 89 inventory claims: 87 MATCH, 1 DRIFT, 1 weak mapping, 0 LOST. Phase 1 found 98 assertions. ADDED: 4 listed, all transitions, pointers or framing. None changes meaning. `check_unit.py` passes, with 0 failures and 11 bold spans.

**DRIFT**
- D-033. Old: "There is consequently no signature-shape violation to name." It maps to B4's "No arity carries a tier. Every declaration takes the component alone…", which states the premise but not the conclusion. The conclusion is in D-263's bullet "`TierSignatureMismatch` retires with all three arms". Fix: remap the claim to `docs/design/decisions.md` D-263, or keep one clause.

**Weak mapping**
- D-032. Old: "the walk … is applied by the build, never requested by a `T` in the declaration." B1's mapped span ("A by-type declaration walks by the same rule…") holds the walk. The "never a `T`" half sits two sentences later in B1: "A `T` in a signature means the framework could not have supplied it." Fix: widen the span. The content is held.

**Hazards checked**
- R1. The `Group` block is byte-identical to the old one (diff). Nothing about its rate declaration is bold or fixed. The last sentence's "wiring and rate declarations" is carried as written, and rulings.md flags it.
- R5. D-030 and D-035 match B4. D-032 is held in B1, as above. D-033 is the DRIFT above. The allocator-exception sentence is needed. Under F22, B1's bold reads "Every declaration of a structural fact *but the allocator*", so without the exception §8.5's sentence would overstate. It also carries the §7.3 and D-263 citations.
- Order. The section runs opening, class, arity, containers, then `Group` with the builder folded in beside D-184's reach. Nothing is used before its definition. The opening's container pointer now says "as 'Container children' below states". "Builder" carries "rejected below". The did-you-mean, contract, face and class links moved to their new first uses.
- M3. The bullet states the same ambiguity, a transparent element's bare key equal to its own field's name. "The sugar" is named and points to §8.7, and unit F's text matches it. One small change: "The one ambiguity this leaves" became "leaves one ambiguity". Optional fix: "leaves only one ambiguity".
- spec 7158. Both reasons survive as "First" and "Second".
- F13 is deleted. F22 reads "Every declaration of a structural fact takes the component alone". Both are correct.

**Citations.** Every old citation survives with its claim. The added ones carry their claims in the fields rulings.md names: D-039 Position (plain struct; marker), D-039 Rejected (builder), D-085 Position (twice), D-085 Rationale (three bullets), D-211 Position sentences 1 and 2, D-212 Position sentences 1 and 2, D-215 bullet 1, D-184 Position, and §13.7 at 9514–9517. One soft spot: D-211 at "must name a container field … two … is a declaration error". D-211 carries only "at most one of its container fields". The name check is `TransparentContainerUnknown`, which D-215 lists. Optional fix: add D-215.

**Bold.** There are 11 spans and all pass the one-bold test. D-039 has four: Position clauses 1, 2 and 3, plus the builder bullet from its Rejected list. D-085 has two, one per semicolon-separated ruling. D-211 has two and D-212 has two, one per Position sentence. D-184 has one. None marks a mechanism, a consequence or a lead-in. Two rulings are new bolds: the builder rejection and "An empty field reserves nothing". The builder rejection is flagged as Rationale-only. No other unit's `new.md` bolds D-039, D-085, D-184, D-211, D-212 or D-215. E1 and F cite them without bold.

**Reader-cold names**
- (2) `Cessna172X{K, A}` becomes "Flight.jl's Cessna 172 model". That is accurate, since C172X is Flight.jl's fly-by-wire C172 variant. Optionally say "fly-by-wire". It claims nothing beyond its source.
- (2) "In an aircraft library, for example" frames the engine example and claims nothing new. But `AbstractAircraft` appears one sentence earlier, before the clause. Fix: move the clause to "the domain hierarchies" sentence.
- No class (1) names. `Plant` and `PID` are inside the verbatim block. The two-producer check is carried as in the old text.

**Other**
- D-020. "Its message reads '…'" is firmer than the old parenthetical quote. `src/diagnostics.jl` 529 confirms the text, so this is fine.
- D-089. "What that declaration buys is that…" became "With that declaration, …". The causal link is a little softer. Acceptable.

## Re-check

All five fixes are in, and nothing nearby broke. `check_unit.py` still reports 0 failures and 11 bold spans.

- **D-033: MATCH.** The claim now maps to `docs/design/decisions.md` line 10197, "`TierSignatureMismatch` retires with all three arms." That line is a bullet in D-263's Position, which runs from 10171 to before Spec at 10201. `rulings.md` records the remap.
- **D-032: MATCH.** B1's span now runs through "A `T` in a signature means the framework could not have supplied it". That covers both halves of the claim, the walk applied by the build and no `T` requested.
- **M3: MATCH.** The bullet reads "leaves only one ambiguity", which restores the old "the one". "Joins this collision error" still refers to the bullet's own bold clause, and D-215 stays at that sentence.
- **D-066: fixed.** It now cites D-211 and D-215. D-211 carries "at most one", and D-215 bullet 1 lists `TransparentContainerUnknown` for the name check. Both are in `rulings.md`. The citation scope did not shrink.
- **D-011: MATCH.** The new text reads "First, the domain hierarchies have to carry both classes. In an aircraft library, for example, these are `AbstractAircraft` and the engine families." The clause now comes before the first use of `AbstractAircraft`. "These" points back to "the domain hierarchies". The engine-field sentence follows inside the same example. Nothing beyond the source is claimed, and the "First"/"Second" reasons spec 7158 needs are intact. The clause left ADDED for D-011's span, which is consistent.
- **One cosmetic nit.** Source line 28 runs to 87 characters and renders at about 85, over the 80-column target. The fix is to rewrap lines 27–28. The other line over 80 is line 157, in the verbatim `Group` block, and stays as it is.
