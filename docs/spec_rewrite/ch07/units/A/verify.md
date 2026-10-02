# Unit A verification

**Counts.** 65 inventory claims: 65 MATCH, 0 DRIFT, 0 LOST. Phase 1 found 69 assertions (V1–V69). 17 `added` entries. 1 factual problem comes from a ruling (R2), and 2 wording nits.

**Cut claims held elsewhere.**
- M1. §9.7 4759–4766 holds A-037 ("Hoisting belongs to the code generator"), A-038 ("Views are spelled rebuild-per-call") and A-039. §7.1 keeps the buffer-unchanged rule as a "because" clause, the phrase "buffer-unchanged-within-a-sweep" and "exactly the legality condition of the code generator's CSE". The §9.7 4764 inbound citation holds, and the text does not point back and forth with §9.7. The executor's gloss leaves with the cut. The glossary holds it.
- M2. §5.2 821–823 holds A-042 and A-043 ("produced" sits in the sentence before; dropping "ever" keeps the meaning). The kept clause survives word for word, with "table" changed to "signal table". F4's stale wording sits in §5.2 and in glossary 12532, as rulings.md reports.

**Judgments.** "excluded" for "closed" keeps the meaning (survey row 14 confirms "closed" meant excluded). "what the closed vocabulary buys" keeps the meaning of "paying rent". F16 matches §5.2's handler return law. F17 matches Appendix C 12001, §9.1 3728 and §8.2 2603–2617. "of a common eltype `T`" survives word for word. D-295 is not cited. "Nobody outside the framework" directly follows the authority sentence. "It" in "Where it materializes" refers to "An isbits view" in the sentence before.

**ADDED (claims more than a pointer).**
- Opening: "The allocation policy those choices make possible closes the chapter." "Make possible" adds a causal link. §7.5 says only that the zero-allocation idiom is the workspace plus immutable-value returns. Fix: "The allocation policy closes the chapter."
- Opening: "and how each home holds its values" goes beyond spec 1900. The chapter's content supports it. Acceptable.
- The other additions are glosses, each within its source. Continuous component, sweep, activation scalar, one home per datum and projection come from the glossary. `RQuat` and `Ranged` come from D-094. `f_ode!` comes from the Flight.jl deep dive. `ComponentArrays` comes from §7.1's own "mutable views".

**Nits.**
- A-006: "Its messages are listed in §8.2." "Its" could mean the structure step. §8.2 shows sample messages, not a full list. Fix: "§8.2 shows the kind's messages."

**Citations.** Every old citation survives with its claim. D-094 now sits at both rulings. I read all eleven added citations: D-033 Position, D-247 Position, D-094 Position and its Annotation, D-035 Position (twice), D-111 Position, D-010 Position, D-288 Position bullet 2, D-252 Position and D-072 Position bullet 1. Each field carries its claim. Two partial cases:
- D-010 does not word "authoritative". The survey (row 14 and the bold table) accepts it.
- The CSE legality condition is D-288 Rationale only. It is cited plain and listed in rulings.md.

**Bold.** There are three bolds, each a headline with its D-entry in the same sentence: the D-094 vocabulary, the D-094 flat declaration and the D-010 buffer authority. These match the survey's bold table. No mechanism or lead-in is bold, no ruling is bold twice, and D-190 is plain (R4).

**Moves.** R1, M1, M2 and R7 are done: the `Ẋ` paragraph now follows the cast, as in survey part C's order. There are no other moves.

**Reader-cold names.**
- (1) `get_x_ss`/`assign_x_ss!`/`get_u_ss` are called "FlightCore's". That is factually wrong. They are declared in FlightPhysics' `AircraftBase` (`aircraftbase.jl:281`) and implemented per aircraft in FlightApps (`c172s.jl:373`). The rewriter followed R2's wording, so the ruling is wrong. Fix: "Flight.jl's hand-written layer…". `f_ode!` and `ComponentArrays` are FlightCore's (`modeling.jl`). They are correct and glossed. `RQuat` and `Ranged` are introduced.
- (2) "attitude state" (an `SVector{4,T}`) and "trim solvers" have no introducing clause. Both were in the old text, and the spec uses "trim" widely. Low priority. `reconstruct`/`flatten` are not introduced, as in the old text.
- (3) FlightCore is named as the predecessor in the five-things paragraph, which is fine.

## Re-check (after R17, R18)

PASS. The R17 and R18 edits match those rulings word for word. Lines 41–99 are unchanged.

- Opening: "The allocation policy closes the chapter." The causal claim is gone. The roadmap sentence that follows is unchanged.
- A-006: "§8.2 shows the kind's messages." "The kind" can only refer to `IllegalStateLeaf`, the kind the sentence before names. The citation scope is §9.1 for the step and §8.2 for the messages, as before.
- A-065: "Flight.jl's hand-written per-aircraft state-space mapping layer". This now matches FlightPhysics plus FlightApps. D-072 bullet 1 still carries the claim. The lead-in "FlightCore's pattern" still refers to `ComponentArrays`, which is correct.
- Inventory: A-006 is tagged R18 and A-065 is tagged R17. The `added` list updates the opening.
- `check_unit.py ch07 check A` prints "checks failed: 0".
