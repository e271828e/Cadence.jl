# E2 verify report

**Counts.** 86 claims: 85 MATCH, 1 DRIFT, 0 LOST. Phase 1 found 95 assertions (V1–V95). 16 ADDED items, 2 of them inexact. `check_unit.py` reports 0 failures.

**DRIFT**
- E2-046. Old: "`Δt` in the stage bundle … is the [§10.5] single source of truth". New: "… is the single source of truth ([§10.5])". The rewriter kept the sentence, as the brief requires. Moving the citation to the end makes §10.5 back the whole sentence. §10.5 (spec 5504) says the source is the deployment's `Schedule`, and the bundle field is where `Δt` arrives. Fix: adopt the proposal in rulings.md, "`Δt` arrives in the stage bundle from its single source of truth, the deployment's `Schedule` ([§10.5])."

**ADDED, inexact**
- V76, the quiescence gloss "(the point where a round of handlers fires nothing)". The glossary's round is sweep → guards → handlers. Fix: "(the point where an event round fires nothing)".
- V41, "`IMUSample` is the sampler's output struct". No source says it is a struct. The code only shows a keyword constructor and the port type. Fix: "the type of the sampler's `sample` output".
- The other glosses match their sources: RHS, bundle, boundary zero, boundary, due, condition, tick, sweep, projection, feedthrough and the ZOH expansion match the glossary. The `q_c_cc` gloss and the direct-formulation sentence match §3.4 395–405. "`Relative(1)`" matches E1's IMU block. The `z⁻¹` gloss matches §3.4 388 ("the `z⁻¹` delay").

**Code and math.** The code block differs from old.md only at F10 (`# §7.1's explicit cast`) and F9. F9 merged the two-line comment into "discrete tier: bound check only" on the first line and dropped "plain form", as F9's wording orders. The second line lost its comment and its padding, with no trailing whitespace left. The first-line comment column and the `y_types` comment alignment are unchanged. There are no other changes. Display math is byte-identical. The 19 inline math spans are identical and in the same order.

**Citations.** Every old citation survives with its claim. In the code, §7.1 went from link markup to plain text, which is F10. The six D-056 citations check out: bullet 1 (idiom), bullet 2 (condition, plus the two semicolon-chained items), bullet 3 (latch-back wire) and bullet 5 (taught contract) each carry their claim. D-067's Position ("→ due `g` updates") plus its bullet 1 ("the `t₀` sample's only chance") carries the boundary-zero latch. The §7.1 cite holds via spec 1504–1508 and 1580–1582 (`RQuat(x.q, normalization = false)`), and the §7.2 cite via spec 1620–1622.

**Bold.** Six D-056 bolds, one per Position item, each with its citation in the same sentence. One is borderline. "The equivalence survives discretization" passes the semicolon test, but it reads as a consequence of linearity, and the next sentence argues it. The owner should decide whether it keeps its bold.

§3.4 versus §8.6: §8.6 should keep the bullet-1 bold. Under "Bold where the section states what the entry decides", §8.6 is where the idiom is stated and spelled out. §3.4 states the problem and points here ("§8.6 spells that idiom … in full"), and survey row 682 assigns the homes the same way. §3.4's "**Algebra removes the reset.**" is also an old-style lead-in with no citation in its sentence. Its bold should go when §3.4 is rewritten. "First in reading order keeps the bold" governs two sentences in one place, not a cross-section double.

**Moves.** The five labels follow part C in order. "The leaves in code" spans the code and the assembly, `Δt` and initialization paragraphs (survey 775). The paragraph starting "In code, …" left the sculling bullet with no change in meaning. No other moves.

**Reader-cold names.** All are class (1), Flight.jl machinery:
- `RQuat` and `FrameTransform` are now introduced and sourced.
- `Attitude.dt`, `RVec` and `IMUSample` are glossed from the code alone. The first two stay within what the code shows. `IMUSample` is flagged above. The owner should choose between naming their library and moving them to a companion.
- "The direct formulation" is now introduced from §3.4, which defines it generically. F16 calls it Flight.jl's IMU.
- The "hour of flight" figure stays unsourced (survey row 216, "N").

Coning and sculling are defined only by their math, as in old.md.

**Other.** §8.6 links neither port nor component, because E1 does not link them either (already in rulings.md). The verb "project" (V70) comes before the projection link (V79).

## Re-check

All fixes are in `new.md`, `inventory.json` and `rulings.md`, and `check_unit.py` reports 0 failures. The code block, the display math and the 19 inline math spans are unchanged. There are still six bolds.

- **E2-046 (now R12): fixed.** The new text matches §10.5 (spec 5504): "`Δt` has a single source of truth, the deployment's `Schedule`", and it arrives as a field of every discrete-tier bundle. The citation still covers the whole sentence, and §10.5 now supports all of it. The purpose clause survives as E2-047. Its antecedent is weaker now. In "It is there for exactly this kind of discretized law", "there" could now mean the `Schedule`, the nearest noun, rather than the bundle. Fix: "It is in the bundle for exactly this kind of discretized law." brief.md and escalations.md do not record R12, so whoever holds the rulings record should add it.
- **Bundle gloss.** "(the NamedTuple of zero-copy views a component function receives)" matches the glossary's "the single `NamedTuple` of zero-copy views a component function receives beside the component itself". The gloss is carried over from old.md unchanged.
- **Quiescence gloss: fixed.** "an event round fires nothing" matches the glossary.
- **`IMUSample` gloss: fixed.** "the type of the sampler's `sample` output" rests on `y_types` and claims nothing more.
- **Projection: fixed.** The link now sits on the first "project" in "integrate, project, sweep", and the gloss sentence follows. That sentence now stands between "sweep" and "gated *into* that sweep". The antecedent still resolves, since only one sweep is named. No cause clause was dropped and no citation's reach shrank. "post-projection" in the contract section stays unlinked, which is correct.
- **Bolds.** The six D-056 bolds are kept. The §3.4 bold goes to the rulings batch, as recommended.
- **Nit.** The rewrap left one source line near 87 columns ("… latched. Sculling would") and one short line ("([§10.5][s10-5]). It is there for"). These are formatting only.
