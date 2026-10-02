# B4 verify report

**Counts.** 112 inventory claims: 108 MATCH, 4 DRIFT (one pattern), 0 LOST. Phase 1 found 130 assertions. ADDED: 6 listed items plus "That follows from the visibility rule above", which renders the old "therefore". Two added items are slightly off (below). `check_unit.py check B4` reports 0 failures.

## DRIFT
- **B4-104 to B4-107 (§8.4 items 2–5).** Old: "**Forgotten wire** (`fuel_available`, read only by a guard). The §6.1 … error". New: "A forgotten wire is `fuel_available`, read only by a guard. It fails as …". Items 3–5 follow the same pattern ("A type mismatch is a `Float64` fraction …"). The example now reads as the definition of the mistake. Fix: "A forgotten wire, such as `fuel_available` read only by a guard, fails as …", and the same for 3–5.

## ADDED, slightly off
- "(each guard the declared predicate of its event)". The glossary and this unit's own §8.4 gloss say "the declared function defining an event's predicate". Fix: use the §8.4 wording.
- The §8.3 lead-in says "the checks that hold every stage's returns to the declared set". `DeclaredNotProduced` checks the other direction. Fix: "the checks that hold stage returns and declarations to each other".

## Citations
- D-179: its Position carries the claim. §10.4 bolds it at spec 4878, so leaving it unbolded here is correct.
- D-033, D-112, D-249 (with its annotation for `Pinned`), D-263 last bullet (F23, `StatelessWithoutOutputs`), D-252, D-194: each carries its claim.
- R9: D-239's Position (`UndeclaredReturnField` alone) carries both the walkthrough-1 analogue (old 2647) and "Return typos cannot silently define new cells". D-034 and D-194 Rejected carry "Probe-observed expected types remain rejected" (old 2660). D-055 stays only in the R4 pointer (old 2662), where its Rejected list alone holds the opt-in variant.
- **Weak:** the bold "Schema authority is total over the table (D-034)". D-034's Position never says this. The phrase is D-055's ("schema authority total"), and D-032's Position states schema authority. D-034 supports it only by inference from "undeclared stage-return fields = build error", a clause the visibility bold already states. Fix: cite D-032 and D-034, or list the case under "Rationale-only rulings".
- R4: the cut items map correctly to D-016 Rejected, D-034 Rejected (two items) and D-055 Rejected. "Satellite-function representation" is nowhere in the log. The only "satellite" in it is at log 5672 and concerns `local_types`, so the clause rightly stays. D-016 carries a "superseded in part" annotation, but the Rejected list cited here still stands.
- §7.4 is dropped with the R4 cut, as recorded.

## Bold
There are 7 bolds, each followed by its D-entry, with one bold per ruling.
- Flag: "**The inspection path for an intermediate is declaration**" is followed at once by "That follows from the visibility rule above". The text itself calls the bolded sentence a consequence. Fix: drop the follow-on sentence, or unbold.
- §5.3 states D-252 under **Rule.**. When chapter 5 is rewritten it will double this bold; rulings.md already records this.

## Hazards
- Completeness: all three rules are present as plain topic sentences. The root rule is in `units/B2/old.md:129` and `B2/new.md:163`. B4's inventory has no claim mapping it, because its old.md never held it.
- §8.3's bullets became paragraphs. §8.4 keeps its numbering 1–5 and its order, so w1–w5 hold.
- The quoted message "no input `throtle`; did you mean `throttle`?" is verbatim.
- Moves and labels follow the brief, and nothing else moved. In Completeness, "An empty store … owes nothing" moved from right after the first rule's statement to the `m_init` paragraph. The meaning holds.

## Reader-cold names
- (3) FlightCore: fine.
- (1) FlightCore's `Model` output: needs "FlightCore's model output" or a clause.
- (2) `throttle`/`fuel_available`/`P_shaft`: `P_shaft` could take a short clause ("shaft power").
- Log vocabulary: "decoder" in "the 'decoder takes no inputs' property" means stage 1 (`y_state`), and nothing introduces it. "split state letters" (D-195) and "the didactic style" (rulings.md open question) are also unexplained. Each is carried from old.

## Other
rulings.md's correction 1 stands: "Every declaration takes the component alone" contradicts `ws_init` and the stages. D-263 says "contract declaration".

## Re-check (after the rewriter's fixes)

All fixes are in `new.md`, `inventory.json` and `rulings.md`. `check_unit.py check B4` reports 0 failures. 5 bold spans remain, each with its D-entry.

- **§8.4 items 2–5** now read "A forgotten wire, such as …, fails as …". The numbering 1–5 and the order hold, so w1–w5 still resolve. Item 5 keeps its cause clause ("since renaming the field produces the port") and its §13.1 and D-239 citations. Item 1 and its quoted message are unchanged.
- **Guard gloss:** one wording in §8.2 and §8.4, matching the glossary.
- **§8.3 lead-in:** fixed.
- **Schema authority:** unbolded, and cites D-032 and D-034. D-032's Position (log 980–981) carries schema authority, and §8.1 (unit A) bolds that ruling. D-239 stays on "Return typos …" and D-034 and D-194 stay on "Probe-observed …", so no citation scope shrank.
- **Inspection path:** unbolded, and D-194 stays at the sentence. "That follows from the visibility rule above" still sits right after it. The antecedent of "it" in "One line in `y_types` makes it public" is unchanged from the old text.
- **`Model` output:** it now reads "FlightCore's model output", so FlightCore appears twice in one sentence. That is clunky but correct. The checker lists `Model` as an old-only code span; that is the intended change.
- **`P_shaft`:** introduced as "a declared shaft power".
- **"decoder":** listed as open in rulings.md.
- **Residual, R13 at old 2574.** The sentence now reads "Every declaration of a structural fact takes the component alone, and `ws_init` takes the scalar on both tiers". B1 states the same fact as "Every declaration of a structural fact but the allocator takes the component alone". B1's "but" implies the allocator is a structural-fact declaration, so B4's version still contradicts itself unless the reader takes the `ws_init` clause as the exception. Fix: "Every declaration of a structural fact but the allocator takes the component alone, and `ws_init` takes the scalar on both tiers".

Nothing else nearby broke.
