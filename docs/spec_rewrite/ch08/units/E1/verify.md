# E1 verify report

**Counts.** There are 76 inventory claims, with 75 MATCH, 1 DRIFT (minor) and 0 LOST. The four R4 cuts are held in decisions.md: E1-007 in D-040 Rejected ("proxies remain sugar"), and E1-049, E1-050 and E1-051 in D-041 Rejected. Each says the same thing. The unit has 104 phase-1 assertions and 12 ADDED items, none of which changes meaning. `check_unit.py` reports 0 failures. The IMU code block is byte-identical to the old one (diff is empty). "a face feeding nothing declares nothing" is word for word.

**DRIFT**
- E1-011 (antecedent). Old: "One fact from that adjudication is relied on downstream." New: "One fact behind the rejection of instance navigation is relied on downstream." In the old text, "that adjudication" grammatically points at §13.3's `resolve`. The new text ties the fact to D-040's rejection, and D-040 Rejected (log 1216–1217) is where the fact actually lives. The change is correct. Fix: record it in rulings.md as an antecedent clarification.

**Rulings R4 and R7**
- R4: done. D-170's Rejected list (status quo, `wires`/`imports`/`exports`, two names) holds none of the three spellings. D-041 Rejected holds all three, so the rewriter's correction 1 is right. Leaving D-170 on that sentence cites it for nothing it rules.
- F8: the two sentences match the brief verbatim. §13.3's table gives inspection "the instance walk".
- F11: the text says "would join", and the count now reads "Two facts the example carries".

**Citations.** I checked every added or replaced citation against its entry. D-040, D-085, D-211, D-207 and D-046 are supported by their Positions. D-170 is supported at all four sites: the child-port clause, the split by direction, "declared by the method" and uniqueness across both boundary declarations. D-210 bullet 2 carries "at least one", D-129's Position carries the directional rule, D-208 bullet 1 carries the class rule, and D-041's Position carries "face types/tiers derived from endpoints… derivation is forced". The three Rationale-only listings are accurate:
- the `===` fact is in D-040 Rejected;
- "not read from write" is in D-129 Rejected;
- the below-root aliasing is in D-210 Rejected.

The old citations all survive. One weakness: D-041 moved off "The derivation is forced, not merely convenient", which now relies on adjacency across an intervening §8.2 citation. This is acceptable.

**Bold.** There are nine bold spans. All are ruling headlines, each with its D-entry. D-170 has three bolds, one for each of three Position clauses separated by semicolons. D-210 has two, one per bullet. No bold falls on mechanism or a lead-in. D-208 is left unbold, and B2/new.md:164 does bold D-208's Position ("Any component may be the root of a build…"), so it is not a double.

**Order and moves.** The order follows survey part C: paths; the three declarations; the direction invariant together with types and tiers; face names and the two-notation rule; root inputs; root uniqueness; the IMU label. I found no other moves. Define-before-use:
- Line 22 uses "the three wiring declarations" before lines 32–47 name them. The old text did the same, and a §6.1 pointer is present. Optional fix: "(named below)".
- "two-producers error" (line 59) has no pointer. Rulings correction 2, adding §6.1, is sound.
- "root inputs" is first used in the context paragraph (line 7), but its glossary link sits at line 95. Fix: move the link to line 7.

**Context glosses.** The assembly gloss ("pure composition… no dynamics of its own") stays within the glossary entry. The face gloss copies the glossary entry verbatim. The other glosses (tier, class, snapshot, periphery, cell, blessed, worked) match the glossary. The container-children gloss says "tuple field", but the glossary says `Tuple`/`NamedTuple`. Fix: "a `Tuple` or `NamedTuple` field".

**Reader-cold names**
- (2) In the prose at lines 152–153, `q_eb`, `r_eb_e`, `ω_eb_b`, `a_ib_b` and `α_ib_b` appear with only the label "kinematic-truth inputs". This is carried from the old text. Optional fix: one clause, such as "attitude, position, rates and accelerations".
- HDF5 is not introduced. Rulings already notes this.
- "the latch-back wire (below)" points to "The boundary-sampling contract" in E2, which never uses the phrase "latch-back". Fix: name that label.
- I found no Flight.jl machinery and no FlightCore mentions.

**Other.** The roadmap's "A worked assembly, the strapdown IMU, closes the section" leaves out the boundary-sampling contract that E2 bolds (D-056). It is still true if the IMU spans to the end of §8.6.

## Re-check

All the fixes I reported are applied, and they broke nothing nearby. `check_unit.py` still reports 0 failures. The IMU code block is still byte-identical to the old one, and the nine bold spans are unchanged.

- **E1-011.** The text is kept, and rulings.md correction 3 records it as a clarified referent, with D-040 Rejected as the evidence. Resolved.
- **D-170 dropped.** The three-spellings sentence now cites D-041 alone, and D-041 Rejected holds all three spellings. Inventory E1-048 lists `cites` [D-041, D-170] and `newcites` [D-041], and rulings records the drop. The sentence's scope did not shrink, since D-170 ruled none of the three. D-170 now appears in new.md three times, at the bold child-face clause, the split by direction and "declared by the method", plus once unbold at face-name uniqueness. That is still four sites, all supported.
- **§6.1 at the two-producers error.** E1-044 and rulings record it. The cited passage, §6.1 at spec 1329–1336, states the exactly-one-connection rule and names the two-producers build error. The citation fits.
- **Root-input link and gloss.** The link now sits at the first use, line 7, and line 98 is unlinked (one link in the file). The gloss "(the root component's own input faces)" is the glossary's "the root component's own input face". It claims nothing more. The gloss slightly anticipates line 100's "*are* the write surface", but contradicts nothing. "fall out with no vocabulary of their own" still reads correctly.
- **Container-children gloss.** It now reads "the elements of a `Tuple` or `NamedTuple` field holding only components", which matches the glossary and D-085's Position. The added code spans `Tuple` and `NamedTuple` are ordinary Julia names.
- **Latch-back pointer.** It now reads "(below, under "The boundary-sampling contract")", which names E2's last label, where the latch wiring is described. "would join" is kept, and the count sentence is still "Two facts". Nit: line 169 is not rewrapped and runs past the line width.
- **Roadmap.** It now reads "It then spells out a worked assembly, the strapdown IMU, and its leaves. It closes with the boundary-sampling contract." That matches E2's label order. The antecedents ("its" for the IMU, "It" for the section) are clear. It is listed under `added` and claims nothing beyond the section.

**Still open, accepted by the coordinator:** the reader-cold names `q_eb` and the rest, and HDF5.
