# Chapter 7: the chapter pass

Read: `chapter_new.md` whole (as assembled), against `chapter_old.md`, the
brief's R1 to R18, `units/B/companion_addition.md`, and spec sections and
glossary entries as cited. Line numbers are `chapter_new.md` lines. Quoted
"current" text is joined across source line breaks.

Clean on these counts, so not listed below: one glossary link per anchor per
section (no anchor linked twice in a section; R11's single `#g-walked` link
holds); bold (twelve spans, matching survey part C's table, each a headline
clause with its D-citation in the sentence; no ruling bolded here is bold in
chapters 8 to 10 except D-231 sentence 1, which R4 records); every
section's parts sentence matches what follows; the opening's roadmap matches
§7.1 to §7.5; no em-dashes, semicolons or mid-sentence colons in prose; no
source line over 80 columns outside links and the R8 F1 code line;
pointers checked (§2.2, §8.2's messages, §9.1, §9.4, §11.2, §11.6, §14.1,
§14.8) all land.

## Editorial fixes

**E1. Unit A, opening, lines 3–4 and 7–8.**
Current: "This chapter fixes where data lives, on both tiers and outside them.
It fixes the homes the declared state occupies and how each home holds its
values." and "The allocation policy closes the chapter."
Replacement: "This chapter fixes where data lives and how each home holds its
values." Delete "The allocation policy closes the chapter."
Why: "outside them" has no referent a cold reader can find in the chapter,
and bare "tiers" is unlinked and unglossed in the opening (R1 exempts only
buffer, store and workspace). The second sentence already says the same
thing more plainly. "The allocation policy closes the chapter" repeats the
roadmap's "[§7.5] the allocation policy" two lines later. R18 ruled that
clause's wording, not its need, so the orchestrator may want to confirm the
deletion.

**E2. Unit A, §7.1 parts sentence, lines 20–21.**
Current: "what the design buys against FlightCore's mutable-view pattern."
Replacement: "what the design buys against FlightCore's mutable-views
pattern."
Why: one name for one thing. Line 117 calls it "the mutable-views pattern".

**E3. Unit A, §7.1, lines 45–46. Define `X`.**
Current: "It reconstructs the typed immutable state value for a
[component](#g-component) at each evaluation."
Replacement: "It reconstructs the typed immutable state value for a
[component](#g-component) at each evaluation. Its type, `X`, is derived from
`x_init`."
Why: `X` is used at lines 53, 94 and 97 (and `Ẋ` at 50, 93 and 111) but
nowhere in the spec is it introduced (`rg '`X`' spec.md` finds only uses).
§7.2 line 169 already says "the `x_init`-derived state type". Declared
addition. `Ẋ` then reads as its derivative without a further gloss.

**E4. Unit A, §7.1, lines 94–95. Activation-scalar gloss.**
Current: "at the [activation](#g-activation) scalar (the scalar type `T` an
activation is built at)."
Replacement: "at the [activation](#g-activation) scalar (the scalar type `T`
at which the build types the model)."
Why: the gloss defines the term with the term itself. §9.4's opening uses
"the build types the model only at `Float64`".

**E5. Unit A, §7.1, lines 86–87. Tense.**
Current: "It is the conversion that `f_ode!`, FlightCore's in-place
derivative function, performs on its raw views."
Replacement: "... FlightCore's in-place derivative function, performed on its
raw views."
Why: F9 replaced "today's" with "FlightCore's", but the present tense stayed.
Line 105 ("FlightCore's pattern was") and §7.4 line 396 ("did economically")
treat the predecessor in the past.

**E6. Unit D, §7.4, lines 395–396. Same function, same gloss.**
Current: "It is also what FlightCore's fused `f_ode!` (its in-place
derivative function) did economically, minus the checked ordering."
Replacement: "It is also what `f_ode!`, FlightCore's fused in-place derivative
function, did economically, minus the checked ordering."
Why: "its" reads as the fused sweep's, the subject of the sentence before.
The replacement matches §7.1's gloss word for word.

**E7. Units B and C, buffer gloss, lines 127–128 and 198–199.**
Current §7.2: "(the framework-owned flat vector backing continuous state)".
Current §7.3: "(the contiguous vector backing all continuous state)".
Replacement, both: "(the framework-owned contiguous vector backing all
continuous state)".
Why: one gloss per term across the chapter. The replacement follows the
glossary's *buffer* entry ("the framework-owned contiguous `Vector{T}`
backing all continuous state").

**E8. Unit C, §7.3, line 222.**
Current: "Isbits is an immutable value that holds no references,
transitively."
Replacement: "An isbits value is immutable and holds no references,
transitively."
Why: "isbits" is an adjective, and the sentence defines a kind of value.

**E9. Units C and D, one name for the workspace idiom; two parentheticals.**
The glossary's *blessed* entry calls it "the workspace-plus-snapshot idiom".
The chapter calls it "the blessed idiom for zero-allocation ticks" (316),
"the Kalman idiom" (328) and "the workspace ... and snapshot pattern" (§7.5,
441–442). The §7.3 sentence also carries two parentheticals, against
spec_style's limit of one.
- Line 316–318. Current: "The [blessed](#g-blessed) (explicitly sanctioned)
  idiom for zero-allocation ticks with immutable `s` does the in-place math
  (`mul!`, `cholesky!`, BLAS) on the workspace ([D-013][d-013])."
  Replacement: "The [blessed](#g-blessed) (explicitly sanctioned)
  workspace-plus-snapshot idiom for zero-allocation ticks with immutable `s`
  does the in-place math on the workspace, with `mul!`, `cholesky!` or BLAS
  ([D-013][d-013])."
- Line 328. Current: "in the same shape as the Kalman idiom above."
  Replacement: "in the same shape as the workspace-plus-snapshot idiom above."
- Lines 440–443. Current: "Their allocation is zero by idiom. The idiom is
  the [workspace](#g-workspace) (component-declared mutable scratch arriving
  as the `ws` bundle field) and snapshot pattern, plus immutable-value
  returns." Replacement: "Their allocation is zero by the
  [workspace](#g-workspace)-plus-snapshot idiom ([§7.3][s7-3]) and
  immutable-value returns. A workspace is component-declared mutable scratch
  arriving as the `ws` bundle field."
  Why, besides the name: the gloss split the compound "workspace and snapshot
  pattern" in two. Survey B.6 asked §7.5 to keep one clause and a pointer to
  §7.3. The pointer never landed.

**E10. Unit C, §7.3, reason after rule (lines 277–294). Placement.**
The `ws_init` rule (277–283) is followed by the merged "Available on both
tiers" material (283–288, "Nothing in the workspace contract ... run
marathons."), and only then by the rule's reason (290–294, "State and cells
re-scalar through the walk ... the allocator's own argument").
Fix: split the paragraph after "take the component alone on every tier."
(283), move the reason paragraph (290–294) there, and follow it with
"Nothing in the workspace contract is tier-specific ... They don't run
marathons." as its own paragraph. No word changes.
Why: spec_style "Rule first, reason after". R6 merged M6 into the scalar
rule. This keeps the merge and puts the reason next to the rule it explains.

**E11. Unit C, §7.3, "declared by allocation" stated twice (269 and 304–305).**
- Line 269. Current: "**A workspace is declared by allocation**
  ([D-077][d-077])." Replacement: "**A workspace is declared by
  allocation**, never by initial value ([D-077][d-077])."
- Lines 302–305. Current: "It puts that fact in the declaration. That is the
  by-allocation convention this declaration actually lives in. Declaration is
  by allocation, never by initial value ([D-077][d-077])." Replacement: "It
  puts that fact in the by-allocation declaration itself."
Why: the bold at 269 and the sentence at 304–305 state one ruling. "That is
the by-allocation convention ..." has no clear antecedent after the split. No
claim is lost. "never by initial value" joins the bold sentence outside the
bold span.

**E12. Unit D, §7.4, line 385.**
Current: "Every causal framework meets the shared-computation problem and
resolves it per its architecture."
Replacement: "Every causal framework meets this overlap and resolves it per
its architecture."
Why: "the shared-computation problem" is never named before. The context
sentence (360) states the overlap between derivatives and outputs, and §5.3
calls the fix "Shared expensive computations".

**E13. Unit D, §7.5, lines 419 and 430. "tier" means something else.**
Current: "the policy's three tiers" (419) and "The policy has three tiers."
(430).
Replacement: "the policy's three budgets" and "The policy sets three
budgets."
Why: the glossary's *tier* entry says "Bare 'tier' means only this", the
continuous or discrete side. The old §7.5 never used the word. The rewrite
added it. "Budget" is the bullets' own word ("The budget is exactly zero").

**E14. Unit D, §7.5, lines 425 and 436–437. Phase body and the measurement
seam.**
- Line 425. Current: "Publication is not a phase body ([D-288][d-288],
  [§9.7][s9-7])". Replacement: "Publication is not a [phase
  body](#g-measurement-seam) (one of the compiled bodies the loop runs)
  ([D-288][d-288], [§9.7][s9-7])".
- Lines 436–437. Current: "at the phase-body [seam](#g-seam) that
  `phase_bodies` exposes". Replacement: "at the measurement [seam](#g-seam)
  that `phase_bodies` exposes".
Why: "phase body" is first used at 425, twelve lines before the seam is
named. §9.7 (spec 4871, "The phase bodies are the [§7.5] measurement seam")
and the glossary's *measurement seam / phase bodies* entry name it the
measurement seam. §7.5 should use that name. The gloss follows that entry
("identity with what the loop runs").

**E15. Unit D, §7.5, lines 471–472. Reader-cold package.**
Current: "Arena allocation (Bumper.jl-style) serves scoped temporaries."
Replacement: "Arena allocation, in the style of the Julia package Bumper.jl,
serves scoped temporaries."
Why: R2 gave Interpolations.jl an introducing clause. Bumper.jl gets the same
treatment. The clause claims only what "-style" already implies.

**E16. Glosses missing at a section's first linked use.** §7.1 to §7.3
gloss these terms. §7.1, §7.4 and §7.5 link them bare. Reuse the chapter's
existing glosses so each term keeps one gloss:
- §7.1 line 88, "[boundaries](#g-boundary)": add "(published consistency
  points)".
- §7.4 line 377, "[buffer](#g-buffer)": add E7's gloss. "[cells](#g-cell)":
  add "(typed entries of the signal table)".
- §7.5 line 427, "[boundary](#g-boundary)": add "(a published consistency
  point)". Line 439, "[ticks](#g-tick)": add "(the instants a discrete
  component runs)". Line 464, "[Replay](#g-replay)": add "(the ordinary loop
  re-driven from the trace)".
Why: spec_style, "Every section must be locally re-readable by a reader
arriving cold." The old text lacked these too, so this is an improvement, not
a repair. Drop any of them if the fixer finds a line growing past one
parenthetical.

**E17. Links at the first use, and links missing.** Each of these is
low-stakes.
- §7.1: "component tree" (37) precedes the [component](#g-component) link
  (46). Move the link to 37.
- §7.3: "the component instance" (236) precedes the link at 250. Move it to
  236.
- §7.3, line 216: "the table's [cells](#g-cell)". Bare "table" is
  unintroduced in §7.3. Write "the [signal table](#g-signal-table)'s
  [cells](#g-cell)".
- §7.1: `#g-view`'s glossary entry cites §7.1, but §7.1 never links it.
  Line 47, "every function receiving state views": link "[views](#g-view)
  (zero-copy reconstructions handed to a function)".
- §7.5, line 426: "its one snapshot allocation" → "its one
  [snapshot](#g-snapshot) (the immutable per-boundary publication)
  allocation". This also separates §7.5's sense from §7.3's local one (ruling
  item K2).

**E18. Wrap.** Every source line is within 80 columns. Several paragraphs
break raggedly where links were moved or inserted. Rewrap, with no word
changes: the opening (3–11; line 8 holds 50 columns); §7.1 bullet 3 (50–55;
54 holds 48); §7.2 164–176 (174 and 175 hold 49 and 43); §7.3 210–214 (212
holds only "[D-302][d-302])."); §7.3 309–312 (311 holds 50); §7.5 423–428
(426 holds 50); §7.5 432–438 (433 holds 51); §7.5 451–460 (452 holds 52).
The companion paragraph also breaks short after "Flight.jl's". Rewrap it too.

## Ruling items

**K1. "Tier" for the genericity classes (unit B and the companion).**
Evidence: the glossary's *tier* entry says "Bare 'tier' means only this
[the continuous or discrete side] ... The genericity classes are *walked /
pinned / exempt*". The *walked / pinned / exempt* entry calls them "the
eltype-genericity classes". §7.2 says "the three tiers that scope this
genericity" (141), "has three tiers" (145), and then, 23 lines later, "On the
continuous tier" (168) in the glossary's sense. The companion paragraph says
"the walked tier of §7.2" and "the pinned tier of §7.2". The old text had one
instance (old 1621–1623). The rewrite added the parts sentence's and the
companion's. D-011's Position says "three-tier scoping". That is log
vocabulary, and it stays.
Recommendation: "classes" at 141 and 145 and in the companion, as the
glossary already rules. Then link [tier](#g-tier) at 168, its first use in
the glossary's sense in §7.2, with a gloss "(the continuous or discrete
side)". Together with E13, this leaves "tier" in chapter 7 with one meaning.

**K2. Two senses of "snapshot" (units C and D).** Evidence: §7.3 uses
"snapshot" for the isbits container a tick returns into `s` (318, 343–356,
`ValueSnapshot`). The glossary's *snapshot* is the per-boundary publication,
the sense §7.5's logging bullet uses (446–458). The old text had both too,
but §7.5 put them in adjacent bullets. Recommendation: no spec rewording
beyond E9 (which names the idiom and points to §7.3) and E17's §7.5 link.
Optionally, add to the glossary's *snapshot* entry: "§7.3's
workspace-plus-snapshot idiom uses the word for the isbits value a tick
returns."

**K3. §7.5 now says both "one snapshot allocation per boundary" and "The
per-boundary allocation cost is zero either way" (unit D, 426 and 458).**
Evidence: R5's sentence (423–428) follows §11.2 (spec 6419–6420: "The cost
is one snapshot allocation per boundary, on the framework side"). Line 458,
carried from the old text, reads flatly as the opposite. Its context is the
reference fields of a field-handle snapshot. Recommendation: line 458
becomes "The reference fields add no per-boundary allocation either way."
This narrows the wording to what the paragraph argues, so it needs a ruling.

**K4. "Bulk data and labels do not [change between ticks]" (unit C,
235–236).** Evidence: six lines earlier, a `Symbol` is "admitted as the
idiomatic label" in a store (227). D-231's Rationale says only "bulk data
does not change between ticks". §8.2's message (spec 2619) says "text and
bulk data belong on the component instance". The text is pre-existing.
Recommendation: "Bulk data and text do not", which matches §8.2 and removes
the clash.

**K5. "the integrator buffer" (unit C, 218–219).** Evidence: the glossary's
*buffer* entry separates "the buffer" from "framework-owned integrator
buffers" (the integration intermediates). The *scratch* entry lists the
integrator's buffers as scratch. "The `s` and `m` stores never touch the
integrator buffer" can be read either way. The text is pre-existing.
Recommendation: "never touch the buffer", the chapter's one name for the
state vector. Ask the owner whether the intermediates were also meant.

**K6. The fifth "thing bought" is no longer against FlightCore's pattern
(unit A, 105–122).** Evidence: R17 made the bullet "Flight.jl's hand-written
per-aircraft state-space mapping layer". The list's lead still says "Against
that pattern [FlightCore's flat `Vector` read through `ComponentArrays`
views], this design buys five things." Recommendation: the lead becomes
"Against that pattern and the Flight.jl code around it, this design buys five
things." Alternatively, leave it, since the layer is the pattern's per-aircraft
companion. Low priority.

**K7 (outside the chapter, for track 2).** The glossary's *the letters* entry
(spec 12432) calls `m` "the continuous-only mode store", and §5.2's bundle
table agrees. D-231's Position says "any leaf's `m`". Chapter 7 states
neither, so nothing changes here. The log's wording is the stale one.
