# Chapter 10: whole-chapter pass

Read: `chapter_new.md` whole, against `chapter_old.md`, `brief.md`,
`docs/design/tools/spec_style.md`, the seven `units/*/rulings.md`, the
Positions and Rationales of every entry that carries two or more bolds,
and the spec targets the chapter points at.

Line numbers are `chapter_new.md` lines. Unit is the owner by section and
subheading. Class is EDITORIAL (an editor can apply it) or RULING (it
changes a claim, a citation or a bold, or needs a decision).

Open items from the units that the whole-chapter view settles:

- A, open question 1 (where D-081 is bold). Settled, no change. D-081's one
  Position ruling is bold once, at L27. The three D-081 bolds in §10.4
  (L415, L429, L434) state separate Rationale items, as B2's rulings list.
  B1's kept `t*` sentence (L171) carries no citation.
- B2, open question 1 (ticks at `t*`). Settled, no change. C1 bolds D-147's
  due-set sentence at L580, and that Position sentence includes "empty at
  `t*`". L426 stays plain.
- B2, open question 2 (`#g-chattering`). Settled. B1 kept the link at L362.
- B2, open question 3 (`Deployment` link). B1 did not link it. See P9.
- C2, open question 2 (frame link). C1 links frame at L526. See P14.

## 1. One name for one thing

**P1.** L64 (A, §10.2 "What the seam requires") and L194 (B1, "Detection
policy"). The chapter calls the guard evaluations a localization runs
"trial sweeps" here and "trial evaluations" everywhere else (defined L234).
Fix: "root-finding over trial evaluations" at both lines. EDITORIAL.

**P2.** L65–67 (A, §10.2) and L236, L333 (B1, "Trial evaluations", "The
localization loop"). §10.2 names the seam's product "dense output" and says
the backend builds it lazily. §10.4 names it "the interpolant" and says
again that it is built lazily. Nothing links the two names. Fix at L333:
"The interpolant is the seam's dense output ([§10.2][s10-2]). It is built
lazily ([D-018][d-018])." EDITORIAL.

**P3.** L23 and L33–34 (A, §10.1). One section names the same sequence
twice, with two pointers: "The macro-sequence of [§10.6] completes there"
and "the boundary sequence ([§5.3])". The chapter then uses both names five
times each. Fix at L22–23: "The boundary sequence ([§5.3][s5-3]) completes
there, in the final form [§10.6][s10-6] calls the macro-sequence, and a
snapshot ... goes out." L33 can then drop its "([§5.3][s5-3])". EDITORIAL.

**P4.** L1032–1035 and L1050 (D, "The firing budget"). "The per-round cap"
names D-020's rejected "bounded-rounds cap", a cap on the number of rounds.
The text has to explain that it "bounded the number of rounds". L1050's
"the arbitrary-K objection" reuses `K`, which §10.5 defines as the
`Relative` multiplier, and never says what K is. Fix: "the rounds cap" at
L1032 and L1035. At L1050: "the objection that a rounds cap is an arbitrary
knob ([D-020][d-020]) lives on in `firing_budget`." EDITORIAL.

**P5.** L481 (B2, "The localization budget") against L1045 and L1068 (D,
"The firing budget"). The chapter places one doctrine in two homes. L481
says "the no-throw doctrine of [§14.8]". L1045 and L1068 say "the doctrine
of [§10.4]". §14.8 is the trim service. It applies the doctrine and itself
cites "the exceptions-are-broken-machinery line ([§13][s13])" (spec 10507).
D-181's Rationale calls it "the §10.4 doctrine". Old text had the §14.8
pointer, so this predates the rewrite. Fix at L481: "which the
exceptions-are-broken-machinery line of [§13][s13] forbids". Leave L1045
and L1068 pointing at §10.4. RULING (citation).

**P6.** L491 (B2, "Deployment constants"). "the third event parameter"
names `firing_budget`. The chapter elsewhere calls these "deployment
keywords" (L464, L869) and "localization constants" (L486). Fix: "with the
third such keyword, the `firing_budget` of [§10.6]". EDITORIAL.

**P7.** L41 (A, §10.1). "The step-boundary contract ([§10.6][s10-6])" is the
name's only use in the chapter. §10.6 never uses the name, so the pointer
leads to a section that does not mention it. The glossary's contract entry
(spec 11966) also places it at §10.6. Fix: gloss it in place, for example
"the step-boundary contract (every boundary runs the full macro-sequence
before it publishes, [§10.6][s10-6])". The gloss states what the contract
is, so the owner should approve the wording. RULING.

## 2. One gloss and one link per term per section

**P8.** L171 against L193 (B1, §10.4 context, "Detection policy"). §10.4
first uses "localized" at L171, unlinked. The link sits at L193. Fix: link
"localized" at L171 and unlink L193. EDITORIAL.

**P9.** L350 against L488 (B1 "The localization loop", B2 "Deployment
constants"). `Deployment` first appears in §10.4 at L350, unlinked. B2 put
the link and gloss at L488 on the assumption B1 would not link it, and B1
did not. Fix: move `[`Deployment`](#g-deployment)` and its gloss to L350,
and leave L488 plain. EDITORIAL.

**P10.** L182 against L260 (B1, §10.4 context, "The trigger"). "Arrival
sweep" is linked at L182 with no gloss. L260 defines it ("That is the sweep
that closes the integration step"). Fix: gloss at L182, "the
[arrival sweep](#g-sweep) (the sweep that closes the integration step) at
tₙ₊₁". L260 can stay as the trigger's reason. EDITORIAL.

**P11.** L243–246 (B1, "Trial evaluations"). "Tick" is linked at L243 and
defined two sentences later at L245. Fix: delete the L245 sentence and
gloss at the link: "Discrete [cells](#g-cell) therefore hold their
[tick](#g-tick) values (set at the last instant their stages and update
ran) through localization". EDITORIAL.

**P12.** L149 and L152 (A, §10.3), and L182, L241, L261 (B1, §10.4).
"Interior sweep", "boundary sweep" and "arrival sweep" each link
`#g-sweep`. §10.3 carries two links to one anchor, §10.4 three. The old
text did the same. E kept its two `#g-pacing` links on the same reasoning
(two names in one entry). Fix: keep the first `#g-sweep` link per section
and unlink the rest, or rule that variant names may each link. Decide once
for both anchors. EDITORIAL.

**P13.** L360 (B1, "The localization loop"). "Remainder step" is linked at
its first prose use with no gloss. Fix: "(the integration from `t*` to the
original grid target)", from the glossary entry. EDITORIAL.

**P14.** L803 (C2, "Coincidence and stagger"). Second `#g-frame` link in
§10.5. C1 links "Frames" at L526. Fix: unlink L803. EDITORIAL.

**P15.** L621 (C1, "Simultaneous ticks") and L763 (C2, "A worked
example"). §10.5 glosses FCS twice. L621 never spells out the letters, and
L763 spells them out again. Fix at L621: "The intra-tick ordering of a
flight control system (FCS) cascade, where outer loops feed an inner loop,
is therefore ...". At L763: "`fcs`, an FCS scope". EDITORIAL.

**P16.** L1112–1114 (D, "Ticks after quiescence"). "Under a 50 Hz FCS"
comes before "the FCS (the flight control system)". Fix: "under a 50 Hz
flight control system (FCS)", then "and the FCS is a discrete component
that observes it". EDITORIAL.

**P17.** L865–870 against L1030 (D, §10.6 rule, "The firing budget"). The
rule defines `firing_budget` at L868–870. The glossary link and gloss wait
until L1030. D placed the link at the first use of the prose term, but the
code-form use at L868 is where the reader meets the concept. Fix: link the
L868 code-form use, "[`firing_budget`](#g-firing-budget) is a deployment
keyword ...". The definition follows in the same sentence, so drop the
L1030 link and gloss. EDITORIAL.

**P18.** L954 (D, "The three registers"). "A re-run from a condition" uses
a glossary term (`#g-condition`) unlinked and unglossed. Fix: "a re-run
from a [condition](#g-condition) (a path-addressed overlay that sets the
build to a state, [§14.1][s14-1])". EDITORIAL.

**P19.** L874, L879, L1043, L1063 (D). "FSM" is never spelled out. Fix at
L875: "(supervisor finite-state machine (FSM) → subordinate FSM → …)", or
spell it out in the sentence before the parenthesis. EDITORIAL.

**P20.** L761 (C2, "A worked example"). "Hyperperiod" is used before L777
defines it as `lcm(Dᵢ)`. Fix: "and one hyperperiod (the span after which
the tick pattern repeats)". EDITORIAL.

**P21.** §10.6 (D) uses other linked terms unlinked: "replay" (L1044),
"localization budget" (L1063, `#g-chattering`), "frame" (L936, L1071).
Minor. Fix: link each once at that first use. EDITORIAL.

## 3. Duplicated facts

**P22.** L306–313 (B1, "The localization loop") and L936–939 (D, "The
three registers"). Both state that the frame-top drain is the only possible
source of disagreement between the prior and the θ = 0 evaluation. The old
text did too. Fix: §10.6 ends at "That is what makes the θ = 0
discriminator ([§10.4][s10-4]) conclusive." Drop L936–939's last sentence.
The claim survives at L312. The drain link in §10.6 then goes with it.
EDITORIAL.

**P23.** L65–67 (A) and L333 (B1). Lazy construction stated twice under
two names. Covered by P2.

**P24.** L350, L464 (B1, B2) and L486–488 (B2). §10.4 says three times that
the localization constants are `Deployment` constructor keywords. R5 keeps
the keyword list at L486–490. Fix at L349–350: "`localization_tol` defaults
to `1e-6` ([D-256][d-256])". Drop "is a `Deployment` constructor keyword"
and keep D-256, which L490 also cites. EDITORIAL.

**P25.** L339–341 and L352–353 (B1, "The localization loop"). "The event
time can never be more accurate than the interpolant" appears twice, six
lines apart (also in the old text). Fix at L352: "The default is `1e-6`
because of that accuracy limit, `O(h⁴)` as stated above." EDITORIAL.

**P26.** L534 (C1) and L680–681 (C2). "Compiles to two integers per
discrete component" and "compiles away at build to one `(D, Φ)` pair per
discrete component". The old text had both. The second is the composition
rule's conclusion, so it can stay. Its bold status is P29. No wording fix
needed.

**P27.** L604 and L608–609 (C1, "Due sets"). "Output stages publish due or
not ([D-205])" and, in the next paragraph, "Its output stages run at `t₀`
due or not ... ([D-205], [§14.5])". The old text had both. Fix at L608:
"Its output stages still run at `t₀` (above), evaluated from the authored
world". EDITORIAL.

## 4. Pointers

Checked and correct: every "(above)" and "(below)" in §10.4 to §10.6; "see
"The localization budget" below" (L326, the label exists at L460); "The
due sets of [§10.5]" (L428, label "Due sets"); "the never-cache-`Δt`
argument below" (L751, under "`Δt` in the bundle"); "[§10.3] states when
external readers may observe the table" (L1090, the sentence is at L159);
section 5 of `companions/flight_case_studies.md` (L144, unit A's addition
is "## 5."); `#### ` labels named in the brief all exist under those
names.

Wrong or weak:

- P5 (the §14.8 doctrine pointer, L481). RULING.
- P7 (the step-boundary contract pointer, L41). RULING.

**P28.** L679 and L806 (C2, "Relative composition", "Coincidence and
stagger"). Both name a bare `sample_time_proposal.md`. The file lives at
`docs/design/companions/sample_time_proposal.md`, and L145 (A) names its
companion as `companions/flight_case_studies.md`. Fix: write
`companions/sample_time_proposal.md` at both lines. EDITORIAL.

## 5. Bold

Totals (fenced code excluded): old 141 spans, 598 words, of which 28 spans
are **Rule.**/**Why.**/**Example.**/**Consequence.** labels. New 63 spans,
601 words, no labels. Spans fell by more than half, but bold words net of
labels rose about 5%. The new bolds are whole headline sentences where the
old bolded fragments. The heaviest are L732 (25 words), L580 (18), L222 and
L250 (17 each). L534 and L540 are new bolds of sentences the old left
plain, and L1135 is a bold E added (E's open item).

Pairs checked against the entry's Position (and Rationale where the bold
rests on one): D-017 (4 bolds, 4 chained rulings), D-018 (3, ruled by the
coordinator), D-021 (5 of 5), D-147 (5 of 5 sentences, one in §9.7 already
plain here), D-081 (1 Position, 3 Rationale items), D-154 (2 of 2), D-182
(2 Position, 1 Rationale), D-186 (1 Position, 3 Rationale items), D-020
(2 of 2). These are clean. The findings:

**P29.** L534 (C1, "The base grid and the gate") and L673 (C2, "Relative
composition"). Both bolds rest on D-185's first Rationale item
(log 6497–6500): "Composition: multipliers multiplicative, phases affine
..., all scoping still compiling to one `(D, Φ)` pair per discrete
component". C1 cites the last clause, C2 the first, and neither unit sees
the other. L673 also cites D-019, whose third Position ruling ("rate scopes
for declaration (integer multipliers K ≥ 1 composing down the tree ...)")
is already bold at L627. Fix: L673 goes plain and keeps both citations.
L534 keeps the bold as first in reading order. If the owner prefers the
bold where the composition rule is stated, swap them. Either way it is one
bold, not two. RULING.

**P30.** L250 (B1, "The trigger") and L933 (D, "The three registers").
Both bold D-082's second chained Position ruling: "events fire on
not-holding → holding edges against a per-event baseline held in loop state
(previous boundary's quiescent sample, updated at quiescence ...)". B1's
rulings cite that span for L250, and D's rulings cite "updated at
quiescence" from the same parenthesis for L933. Fix: L933 goes plain and
keeps D-082, since L250 comes first in reading order. RULING.

**P31.** L462 and L496 (B2, "The localization budget", "Deployment
constants"). D-133's second Position sentence chains two rulings with a
semicolon. The second, "`event_budget`, the per-frame localization
allowance, default 8 — validated ... and **recorded** in the trace header",
carries both L462's subject and L496's "recorded". L496 also cites D-181.
D-181's Position is one sentence, already bold at L860, and holds
"validated/recorded/replay-compared" in a parenthesis. Under the mechanical
test, L496 bolds a ruling twice. Against that, the recording rule is the
one R5 keeps with its reason, and the dash clause covers both constants.
Decide whether the recording clause counts as its own ruling. If not, L496
goes plain. RULING.

**P32.** L462 (B2). The bold marks a definition ("an integer count of
localizations permitted within one frame"). What D-133 decides, the
default of 8, sits plain in the next sentence. Fix: "**`localization_budget`,
the count of localizations permitted within one frame, defaults to 8**
([D-133][d-133], [D-181][d-181])." RULING.

**P33.** L156 (A, §10.3). The bold carries the parenthesis "(GUI, logging,
network output)", which is not part of the headline clause. Fix:
"**External readers observe the signal table only at step boundaries**
([D-023][d-023]). These readers are the GUI, logging and network output."
RULING.

**P34.** L210 and L222 (B1, "Detection policy"). Both bolds rest on one
chained item of D-179's Rationale: "recorded doctrine: guards over `u`/`m`
alone are piecewise frame-constant so boundary detection is *exact* for
them, and the gate idiom ... is the blessed way to localize a mixed
predicate". B1 lists both as Rationale-only but does not ask whether the
"and" joins two rulings or two clauses of one. Each states an independent
decision, so two bolds look right. Confirm, or L222 goes plain. RULING.

## 6. The opening

**P35.** L3–9 (A, chapter intro). "This chapter owns time." is an aphorism,
not a findable claim. The intro states no problem before the roadmap. The
roadmap sentence also nests an apposition inside a comma list ("the loop's
two units, the frame and the boundary, [§10.2] the stepper seam"), so the
reader cannot tell where §10.1's item ends. Fix: "This chapter states how
the loop runs a model through time. It takes the execution order ([§5.3])
and the compiled executor ([§9.7]) as given." Then, as its own sentence,
use semicolons: "[§10.1] covers loop ownership and the loop's two units;
[§10.2] the stepper seam; [§10.3] signal-table consistency; ...; and
[§10.7] real-time pacing." EDITORIAL.

**P36.** L1120–1122 (E, §10.7 context). The new opening lists the parts
but states no problem. The section has subheadings, so the parts sentence
is optional. The problem goes unsaid. Fix: "An interactive run must keep
to wall-clock time, and its trajectory must not depend on how fast it
runs. [Pacing](#g-pacing) (the waits that hold a run to wall-clock time)
does the first without breaking the second." Both claims are the
section's own (L1126–1133). EDITORIAL.

The other openings work. §10.1 (L13–15) names its parts in order. §10.2
(L51–55), §10.4 (L165–169), §10.5 (L508–515) and §10.6 (L846–849) each
state the problem first. §10.3 opens on its mechanism, which is its
context, and it is short enough to need no parts sentence.

## 7. Reader-cold names

- P7: "step-boundary contract" (L41). RULING.
- P4: "arbitrary-K objection" (L1050). EDITORIAL.
- P19: "FSM" (L874 on). EDITORIAL.

**P37.** L1141 (E, "The invariant and the wall-clock map"). "Re-anchored
at every knee" never says what a knee is. Fix: add after the bold sentence
"A knee is a point where the map changes slope or offset. A pace change,
an un-pause and a forgiveness re-anchor each make one." The three causes
are in the section (L1147–1148, L1160–1161). EDITORIAL.

**P38.** L1020–1021 (D, "What a handler sees within a round"). "This is
the position of the synchronous languages" names a family the reader may
not know. Fix: "the synchronous languages (Esterel and Lustre, for
example)". Check the examples against the source the sentence came from
before adding them. EDITORIAL.

**P39.** L122–123 (A, "The case for fixed-step low order"). "Decisive for
the whole axis" does not say which axis. Fix: "decisive for the choice of
integration method". EDITORIAL.

**P40.** L200–201 (B1, "Detection policy"). "The illegal pairing" does not
name the pairing. Fix: "a localized `Bool` guard cannot be written at
all." EDITORIAL.

**P41.** L968 (D). "The downstream stage-2 chains" assumes the reader knows
the stage numbering. §10.5 (L573–574) ties stage 1 to `y_state` and stage 2
to `y_direct`, but only inside one sentence, three sections earlier. Fix:
"the downstream `y_direct` chains that read them". EDITORIAL.

## 8. Define before use

- P10 (arrival sweep, L182), P11 (tick, L243), P16 (FCS, L1113), P20
  (hyperperiod, L761). EDITORIAL.

**P42.** L27–29 (A, §10.1). The bold sentence uses `t*` before the next
sentence defines it. The old order ("`t*` is a boundary, and so is boundary
zero. Neither is a frame top.") read more smoothly. Fix: swap the two
sentences without touching the bold. "`t*` is an event's crossing instant
inside a step, bracketed by root-finding ([§10.4]). **The localized event
time `t*` is a boundary but not a frame top** ([D-081])." EDITORIAL.

**P43.** L976–981 (D, "What a handler sees within a round"). "The epoch
rule" (L976) and "two epochs" (L980) come before "An epoch here is the
world one round's sweep produces" (L980–981). R4 asked for that sentence.
Its place is the problem. Fix: move "An epoch here is the world one
round's sweep produces. It is not the input epoch of [§10.4]." to follow
L976's first sentence, before the bold. EDITORIAL.

**P44.** L205 (B1, "Detection policy"). "Return the predicate `σ ≥ 0`
instead of `σ`" uses σ before anything defines it (L229, and the sketch at
L273). The old text did the same. Fix: "instead of the sign-form value
`σ`". EDITORIAL.

The seams themselves hold. B2 uses only terms B1 defines (θ = 0 validation,
epoch-caused edge, prior). C2 uses C1's `(D, Φ)`, gate and residue. D uses
§10.4's discriminator by pointer. "Stagger" before its block (L650) is the
brief's accepted case.

## 9. Reads worse than the old text

**P45.** L218–220 (B1, "Detection policy"). F14's new clause names the
piston engine, and the old sentence then names it again: "Take a piston
engine whose modes include `starting` and `running`. The piston engine's
`starting → running` fires on ...". Fix: "Its `starting → running`
transition fires on `ω > ω_idle && fuel_available`." EDITORIAL.

**P46.** L1030–1038 (D, "The firing budget"). Two sentences about the
rejected designs now sit between the per-event budget and "Priors stay
honest as a consequence". The consequence now reads as following from the
per-round cap. Fix: order the paragraph as budget, then "Priors stay
honest as a consequence. Every prior is a sample actually taken ...", then
the two rejected designs with their descriptions. EDITORIAL.

**P47.** Ragged wraps left by sentence splits: L137–138 ("Then subcycle
the" / "stepper"), L327–328, L408–409, L912–913, L945–947, L1036–1037.
There is also a double blank line at L842–843, the C2/D seam. Fix: rewrap
each paragraph and delete one blank line. EDITORIAL.

P42 (§10.1's `t*` order), P43 (the epoch order) and P35 (the roadmap) also
belong here.

## 10. Lines over 80 rendered columns

Measured with link markup collapsed and code ticks and emphasis removed.
Fenced code and table rows are skipped.

| line | cols | unit |
|---|---|---|
| 104 | 82 | A |
| 126 | 95 | A |
| 178 | 85 | B1 (the chain blockquote, as long in the old text) |
| 219 | 96 | B1 (gone if P45 applies) |
| 309 | 98 | B1 |
| 450 | 88 | B2 |
| 481 | 83 | B2 |
| 979 | 95 | D |
| 980 | 94 | D |
| 983 | 85 | D |
| 1063 | 90 | D |
| 1148 | 89 | E |

L522 is display math, short when rendered. **P48.** Fix: rewrap each prose
line. L178 may stay if the chain should read as one line. EDITORIAL.

## Counts

- EDITORIAL: 38. P1–P4, P6, P8–P22, P24, P25, P27, P28, P35–P48. P23
  folds into P2, and P26 needs no change.
- RULING: 8. P5, P7, P29–P34. P29 and P30 are clear repeat bolds across
  units. P31 and P34 need a reading of the mechanical test. P32 and P33
  move bold onto the headline clause. P5 changes a citation, and P7 adds a
  gloss that says what the cited contract is. The bold-weight rise
  (section 5) is a note, not an item.
