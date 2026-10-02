# Unit D (§10.6) — cold verification

**Counts.** 173 inventory claims: 171 MATCH (this includes R3, R4, R8 F5/F8/F9/F14 and moves M2/M4/M9 as ruled), 2 DRIFT, 0 LOST. Phase 1 found 118 assertions. ADDED: 15 entries, all glosses, labels, ruled sentences or pointers. None changes meaning. The checker reports 0 failures.

## DRIFT

- **D-088 (antecedent).** Old: "…ever straddles two epochs. Serialization is what delivers this." New: R4's two sentences now come between them, and a paragraph break follows, so "this" can read as "not the input epoch". Fix: "Serialization is what delivers the epoch rule."
- **D-120 (citation scope, through the pointer D-117).** Old: "a table copy per firing round (D-100)". The item sits only in D-100 Rejected (log 2893), and the span there says the same thing, so the item is held. But the kept pointer says "D-154 records the rejected shapes", and D-154 Rejected does not list it. Fix: "D-154 and D-100 record the rejected shapes". Better, add the item to D-154 Rejected in track 2 and keep the pointer, which also settles the D-100 question below. The survey's row 148 ("D-154 Rejected holds all four") is wrong.

## R3, R4, R8, moves

- R3 list 1: D-118, D-119 and D-121 are in D-154 Rejected (5279–5285). D-119's log span says only "§10.6's standing rejection", which is now circular. The full reason is in D-100 Rejected 2889–2892. rulings.md already lists this.
- R3 list 2: D-136 and D-137 are in D-181 Rationale (6359–6362). D-138 is in D-181 Rejected (6373). "D-181 records what that buys" is accurate.
- R4: the new text says only what D-154 says ("the firing round's sweep"), and it keeps §10.4's input epoch separate. It is redundant: "no bundle mixes values from two rounds' sweeps" repeats the sentence before it. Optional cut.
- F8: each of the three replacement sentences matches D-274. Bullet 4 says the header is a checkpoint, bullet 3 says restore! copies it back, and the sketch shows the reset. It claims nothing more. "Not model memory" and "absent from every state store" are kept.
- F5 and F9 are correct. §2.2 line 285 supports the f_step! gloss, and D-020 Rejected (706–708) supports the citation. F14 claims nothing beyond the old sentences.
- M2 holds: units/A/old.md:136 and new.md:160. M4 and M9 were done. One unbriefed move: "Boundary zero is the initialization boundary" moved to the term's first use (line 107). This is allowed by the first-use gloss rule.
- Two-sided phrases are intact. Every sentence that names a budget keeps its scope ("per event per boundary", "per frame"). §10.4 (spec 5094–5096) confirms that 8 is per frame.
- The blockquote changed only in its bold and the moved firing-budget link. The code block is verbatim.

## Citations

Every old citation survives, except the four inside R3's cut list (D-016, D-152 and one D-100) and the self-citation §10.6, which became §10.4. I checked every added citation against its entry. Each named field carries its claim: D-020 Position and Rejected, D-067, D-082 Position and Rationale, D-154 Position, D-181 Position and Rationale, D-191 Position, D-274 bullets 1, 3 and 4. D-082's Position still says "not captured, reconstructed on warm restart", which contradicts D-274. rulings.md flags it.

**The D-100 bold.** The Rejected item ("an opt-in for same-round foreign visibility") still stands. D-154 superseded D-100's Position mechanism, but nothing in the log records this and the status reads "ratified". Under "never cite a superseded entry", the citation is acceptable only while D-100 counts as half-superseded. The bold itself is right, as a ruling stated only in Rejected. Preferred fix: move the item into D-154 Rejected (track 2), then cite D-154. This is the same fix as D-120.

## Bold

There are 10 bolds. Each is a headline clause with its D-entry in the same sentence, and no ruling is bolded twice. Removing the bold from "single writer" and "unobservable" is correct, because D-154's Position sentences each already have one bold. No bold falls on a mechanism, a lead-in or a definition.

## Glosses and reader-cold names

- The #g-execution-cursor gloss ("the loop-state field recording where execution stands, §13.4") matches §13.4 line 8916 and the glossary.
- "trace header" (line 102) appears for the first time here and has no link or gloss. #g-trace-header exists. Fix: link it.
- (1) Flight.jl machinery: `f_step!` is now glossed and fine.
- Cold log names, outside the three classes: "pre-materialization, staging pass, carrier, shadow table" (D-100 and D-154 machinery), "the deferral design" and "the per-round cap". These are rulings.md open questions 3 and 4. I agree with both.
- (2) Aerospace examples: the engine and the FCS are now introduced. Fine.
- (3) No case.
- Hybrid automata, Modelica, Stateflow and the synchronous languages are outside references and fine.

## Re-check

I re-checked the seven fixes against old.md, the log, the current new.md and inventory.json. The checker still reports 0 failures.

1. "Serialization is what delivers the epoch rule": clean.
2. The repeated R4 clause is gone. "Straddles two epochs" stays, followed by the definition of the epoch and the line that it is not §10.4's input epoch. Clean.
3. "D-154 and D-100 record the rejected shapes": clean. D-123 is mapped to D-100 Rejected (log 2893).
4. The D-100 bold stays, flagged for track 2. Accepted.
5. All four cut names are carried in D-154 Rationale (log 5264–5269), in the same sense:
   - D-100's "pre-materialization mechanism" is superseded.
   - "f.10's staging pass, carrier … are mooted".
   - "no shadow table … becomes trivially true".
   
   "None of the extra machinery that D-154 made unnecessary" is accurate. Clean.
6. Two problems remain in the two glosses.
   - "A manufactured not-holding prior" names the deferral design's mechanism, not the design. D-181 Rejected also says the design "fires one step late" and "collapses multiple re-arms".
   - "A bounded-rounds cap" only renames "the per-round cap" and does not say what it caps. D-020 Rejected caps the number of rounds, and D-181 Rationale calls it "D-020's rejected rounds-cap".
   - The appositive commas also make the sentence read as a four-item list.
   - Fix: "The deferral design (a re-enabled event fired one step late, through a manufactured not-holding prior) and the per-round cap (a cap on the number of rounds) are both rejected (D-020, D-181)."
7. "Trace header" now links #g-trace-header, glossed "the trace's fixed preamble". This matches the glossary. Clean.
