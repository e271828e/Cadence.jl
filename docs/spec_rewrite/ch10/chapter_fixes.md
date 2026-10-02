# Chapter 10: editorial fixes from the chapter pass

One line per edit: item, unit, old wording, new wording. Rewraps of the
paragraphs an edit touched are not listed separately. Skipped items and
no-change decisions are at the end.

## Unit A

- P35, A: "This chapter owns time. It takes ... as given, and states how the loop runs them through time. [§10.1] covers ... two units, the frame and the boundary, [§10.2] the stepper seam, [§10.3] ..., and [§10.7] real-time pacing." → "This chapter states how the loop runs a model through time. It takes ... as given. [§10.1] covers loop ownership and the loop's two units; [§10.2] the stepper seam; [§10.3] ...; and [§10.7] real-time pacing."
- P3, A: "The macro-sequence of [§10.6] completes there, and a snapshot" → "The boundary sequence ([§5.3]) completes there, in the final form [§10.6] calls the macro-sequence, and a snapshot". L33's "([§5.3])" kept: dropping it would separate A-003's citation from its claim.
- P42, A: "**The localized event time `t*` is a boundary but not a frame top** ([D-081]). `t*` is an event's crossing instant inside a step, bracketed by root-finding ([§10.4])." → the two sentences swapped, bold untouched.
- P7 (ruled), A: "The reason is the step-boundary contract ([§10.6]), the central invariant of this design." → "The reason is the step-boundary contract (at every boundary the [§10.6] macro-sequence completes before a snapshot goes out). It is the central invariant of this design." A-008 tagged R/P7.
- P1, A: "root-finding over trial sweeps" → "root-finding over trial evaluations".
- P39, A: "decisive for the whole axis" → "decisive for the choice of integration method".
- P33 (ruled), A: "**External readers (GUI, logging, network output) observe the signal table only at step boundaries** ([D-023])." → "**External readers observe the signal table only at step boundaries** ([D-023]). These readers are the GUI, logging and network output." A-078 tagged R/P33.
- P47, A: "First shrink `h`. / Then subcycle the / stepper" rewrapped.
- P48, A: L104 (feedthrough tracer) and L126 (periodic avionics) rewrapped.
- P12, A: no change. Decision for both anchors: each name a glossary entry bolds (interior sweep, boundary sweep; pacing, debt) may take its own link once per section, as E did for `#g-pacing`. §10.3's two `#g-sweep` links stay, and §10.4's three stay too (arrival sweep is §10.4's first `#g-sweep` link; interior and boundary sweep are the entry's named variants).

Checker, A: `checks failed: 0`.

## Unit B1

- P8, B1: "The localized event time `t*` is a boundary" → "The [localized](#g-localized) event time `t*` is a boundary"; "is [localized](#g-localized). The framework brackets" → "is localized. The framework brackets".
- P1, B1: "root-finding over trial sweeps" → "root-finding over trial evaluations".
- P48, B1: the chain blockquote rewrapped, "→ bracket" moved to its second line.
- P10, B1: "The [arrival sweep] at tₙ₊₁ raises the trigger" → "The [arrival sweep] (the sweep that closes the integration step) at tₙ₊₁ raises the trigger".
- P40, B1: "the illegal pairing cannot be written at all" → "a localized `Bool` guard cannot be written at all".
- P44, B1: "instead of `σ`" → "instead of the sign-form value `σ`".
- P45, B1: "The piston engine's `starting → running` fires on" → "Its `starting → running` transition fires on".
- P11, B1: "hold their [tick] values through localization, ... is holding. A tick is an instant at which a discrete component's stages and update run." → "hold their [tick] values (set at the last instant their stages and update ran) through localization, ... is holding." The defining sentence is deleted.
- P2, B1: "The interpolant is built lazily ([D-018])." → "The interpolant is the seam's dense output ([§10.2]). It is built lazily ([D-018])."
- P9, B1: "`localization_tol` is a `Deployment` constructor keyword defaulting to `1e-6` ([D-256])." → "`localization_tol` is a constructor keyword of the [`Deployment`](#g-deployment) (the scalar-free artifact the grid parameters fix) and defaults to `1e-6` ([D-256])." The B2 half is under unit B2.
- P25, B1: "The default is `1e-6` because the event time can never be more accurate than the interpolant, which is `O(h⁴)` as stated above." → "The default is `1e-6` because of the interpolant's accuracy limit, `O(h⁴)` as stated above." "the interpolant's" in place of the pass's "that": the sentence before is about scale, so "that" had no antecedent.
- P13, B1: "with the [remainder step] targeting tₙ₊₁" → "with the [remainder step] (the integration from `t*` to the original grid target) targeting tₙ₊₁".
- P47, B1: "It also warns nothing. Input timing is / a frame fact" rewrapped.
- P48, B1: L219 (gone with P45) and L309 (zero-order hold) rewrapped.
- P30, P34, B1: no change; L250 and both D-179 bolds keep their bold under the rulings.

Checker, B1: `checks failed: 0`.

## Unit B2

- P32 (ruled), B2: "**`localization_budget` is an integer count of localizations permitted within one frame** ([D-133], [D-181]). It defaults to 8." → "**`localization_budget`, the integer count of localizations permitted within one frame, defaults to 8** ([D-133], [D-181])." "integer" kept from the old text; the ruling's wording dropped it. B2-059 and B2-060 tagged R/P32.
- P9, B2: "constructor keywords of the [`Deployment`](#g-deployment) (the scalar-free artifact the grid parameters fix). They stand" → "constructor keywords of the `Deployment`. They stand". The gloss claim B2-083 now points at units/B1/new.md.
- P6, B2: "with the third event parameter, the `firing_budget` of [§10.6]" → "with the third such keyword, the `firing_budget` of [§10.6]".
- P31 (ruled), B2: "**All three are recorded** ([D-133], [D-181])" → plain, citations kept. B2-081's ruling now reads "R8; P31".
- P47, B2: "tiny remainder step. / Numerically" rewrapped.
- P48, B2: L450 (projection) and L481 (the §14.8 doctrine) rewrapped. L481's wording is untouched (P5 rejected).

Checker, B2: `checks failed: 0`.

## Unit C1

- P27, C1: "Its output stages run at `t₀` due or not, evaluated from the authored world ([D-205], [§14.5])." → "Its output stages still run at `t₀`, as above, evaluated from the authored world ([D-205], [§14.5])." The pass's fix dropped both citations; they stay, so the claim keeps its citation.
- P15, C1: "The intra-tick ordering of the FCS cascade (a flight control system's outer loops feeding its inner loop) is therefore" → "The intra-tick ordering of a flight control system (FCS) cascade, where outer loops feed an inner loop, is therefore".
- P29, C1: no change; L534 keeps its bold under the ruling.
- P48, C1: L522 is display math, left as is.

Checker, C1: `checks failed: 0`.

## Unit C2

- P29 (ruled), C2: "**Multipliers compose multiplicatively and phases affinely down the tree** ([D-019], [D-185])." → plain, both citations kept. C2-025 tagged R/P29.
- P28, C2: "`sample_time_proposal.md` (the declaration design's worked companion)" → "`companions/sample_time_proposal.md` (the declaration design's worked companion)".
- P20, C2: "and one hyperperiod." → "and one hyperperiod (the span after which the tick pattern repeats)."
- P15, C2: "`fcs`, a flight control system (FCS) scope" → "`fcs`, an FCS scope".
- P14, C2: "never share a [frame](#g-frame), so" → "never share a frame, so".
- P28, C2: "worked in `sample_time_proposal.md`" → "worked in `companions/sample_time_proposal.md`".
- P47, C2: the trailing blank line at the end of new.md deleted, which removes the double blank at the C2/D seam.

Checker, C2: `checks failed: 0`.

## Unit D

- P17, D: "`firing_budget` is a deployment keyword" → "[`firing_budget`](#g-firing-budget) is a deployment keyword"; "A per-event [firing budget](#g-firing-budget) (the rule bounding how often each event fires at one boundary) lets" → "A per-event firing budget lets".
- P19, D: "(supervisor FSM → subordinate FSM → …) takes" → "(supervisor FSM → subordinate FSM → …, where an FSM is a finite-state machine) takes". The pass's "(supervisor finite-state machine (FSM) → …)" nests parentheses, which spec_style forbids.
- P47, D: "Two consequences follow. Sticky predicates need no / special case." rewrapped.
- P30 (ruled), D: "**The prior is updated at each boundary's quiescence**, from" → plain, D-082 kept. D-044 tagged R/P30.
- P22, D: "That is what makes the θ = 0 discriminator ([§10.4]) conclusive. The frame-top [drain](#g-drain) (the swap that publishes ...) is the only possible source of disagreement between the prior and the left-end trial evaluation." → "That is what makes the θ = 0 discriminator ([§10.4]) conclusive." D-048 now points at units/B1/new.md ("the frame-top drain is the only possible source of disagreement").
- P47, D: "`restore!` copies a / checkpoint's prior back" rewrapped.
- P18, D: "A re-run from a condition resets" → "A re-run from a [condition](#g-condition) (a path-addressed overlay that sets the build to a state, [§14.1]) resets".
- P41, D: "the downstream stage-2 chains that read them" → "the downstream `y_direct` chains that read them".
- P43, D: "An epoch here is the world one round's sweep produces. It is not the input epoch of [§10.4]." moved from after "No bundle ... ever straddles two epochs." to after "This gives the epoch rule, which is the core of this section.", before the bold.
- P48, D: L979, L980, L983 rewrapped with P43's paragraph and the next.
- P46 and P4, D: "A per-event firing budget lets ... fresh sweep. The deferral design and the per-round cap are both rejected ([D-020], [D-181]). The deferral design fired ... ([D-181]). The per-round cap bounded the number of rounds at a boundary ([D-020]). Priors stay honest as a consequence. Every prior is ... work out." → "A per-event firing budget lets ... fresh sweep. Priors stay honest as a consequence. Every prior is ... work out. The deferral design and the rounds cap are both rejected ([D-020], [D-181]). The deferral design fired ... ([D-181]). The rounds cap bounded the number of rounds at a boundary ([D-020])."
- P47, D: "Priors stay honest as a consequence. / Every prior" rewrapped (with P46).
- P21, D: "warns (below), and the run proceeds and replays identically." → "warns (below). The run proceeds, and its [replay](#g-replay) (the ordinary loop re-driven from the trace) is identical."
- P4, D: "the arbitrary-K objection ([D-020]) lives on in `firing_budget`" → "the objection that a rounds cap is an arbitrary knob ([D-020]) lives on in `firing_budget`".
- P21, D: "chooses the per-frame localization budget's 8." → "chooses 8 for the [localization budget](#g-chattering) (the count of localizations permitted within one frame)." The gloss keeps the per-frame scope. P48's L1063 rewrapped with it.
- P21, D: "re-localization within the frame has" → "re-localization within the [frame](#g-frame) (one grid step) has". With P22's sentence gone, this is §10.6's first use of "frame".
- P16, D: "under a 50 Hz FCS. The engine is a continuous component, and the FCS (the flight control system) is" → "under a 50 Hz flight control system (FCS). The engine is a continuous component, and the FCS is".

Checker, D: `checks failed: 0`.

## Unit E

- P36, E: "This section covers [pacing](#g-pacing) (the waits that hold a run to wall-clock time). Its parts are the invariant with ..." → "An interactive run must keep to wall-clock time, and its trajectory must not depend on how fast it runs. [Pacing](#g-pacing) (the waits that hold a run to wall-clock time) does the first without breaking the second. This section covers the invariant with ...". "Its parts are" became "This section covers" because "Its" would now refer to pacing.
- P37, E: added after "**The wall-clock map is piecewise affine, re-anchored at every knee** ([D-021])." the sentences "A knee is a point where the map changes slope or offset. A pace change, an un-pause and a forgiveness re-anchor each make one." Declared as an addition.
- P48, E: L1148 ("Un-pause re-anchors for the same reason") rewrapped.

Checker, E: `checks failed: 0`.

## Skipped items and items with no edit

- P5: rejected by chapter_rulings.md. "The no-throw doctrine of [§14.8]" stays.
- P24: skipped. It conflicts with P9, and dropping "is a `Deployment` constructor keyword" from L349–350 would break B2's next reference: "It is the second deployment keyword this section fixes" (L464) counts `localization_tol` as the first, and only L350 says so before that point. P9 was applied instead, so §10.4's `Deployment` link and gloss now sit at L350.
- P38: skipped. No source names Esterel or Lustre (spec 5608, D-100 at decisions.md 2897 and companions/event_visibility_walkthrough.md 210 say only "the synchronous languages"). Adding them would claim something the source does not.
- P12: applied as a decision with no text change (see unit A).
- P23: folded into P2. P26: needs no change (the pass says so).
- P29 (C1 side), P30 (B1 side), P34: the rulings keep these bolds as they are.
