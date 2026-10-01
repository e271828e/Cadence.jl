# Chapter pass over the rewritten chapter 9 — 2026-10-01

One cold read of `chapter_new.md` from start to finish, with `chapter_old.md`,
`survey.md` and the units' `rulings.md` for comparison. Line numbers are
`chapter_new.md` lines unless marked "old". Owner tags are A1 (intro and
§9.1), A2 (§9.2), B (§9.3), v4 (§9.4), C (§9.5), D (§9.6) and E (§9.7). Claim
fidelity is out of scope. Factual items already in a unit's `rulings.md` are
named only where they affect how the chapter reads.

Priority marks: **[high]** a cold reader stumbles or is misled; [mid] a reader
notices; [low] polish.

## 1. Consistency across sections

1.1 [mid] A2. **"deployment" for the artifact.** In §9.1 and §9.3, lowercase
"deployment" is the step (table row 40, lines 127, 131, 555, 558). §9.2 also
uses it for the artifact: 210 "The deployment carries the `Schedule`", 212
"materializes a deployment", 286 "many deployments", 327 "Two deployments
compare as values". Line 244 mixes both styles in one phrase, "any number of
deployments and `Simulation`s". Line 349, "deployment must declare
`Δt_base`", can be read either way. Fix: use `` `Deployment` `` for the
artifact, including plurals (`` `Deployment`s ``, as with `` `Simulation`s ``).
Keep lowercase only for the step.

1.2 [mid] A2. **"schedule" and `Schedule`.** Lines 323 ("builds the
schedule"), 371 ("are the schedule, the `Schedule` the constructor builds"),
393 ("It is the typed schedule") and 399 ("The schedule is the single source
of truth") use lowercase for the artifact that 210 and 392 code-format. Fix:
use `` `Schedule` `` throughout. At 371, write "The per-component triples are
the `Schedule`'s content" or similar.

1.3 [low] A2. **The `Build`'s parts in lowercase.** At 224, "A `Build` is
structure, outputs, events, the activations and `warnings`" names in
lowercase three artifacts that the rest of the chapter code-formats. Fix: if
these are the artifact types, write `` `Structure`, `Outputs`, `Events` ``.
If they are field names, code-format them as fields. Check D-253 for which
reading it means.

1.4 [mid] A2. **One warning, two names.** `GridUtilization` is "the one
advisory" at 447 ("The advisory reports …", 448) and "a deployment warning"
at 466. The two subsections never say these are the same thing. Fix at 466:
"The `GridUtilization` advisory is a deployment warning, so …".

1.5 [mid] B. **Who probes.** At 482, "The nominal activation probes every user
function". §9.1 (153, 172) gives probing to the nominal evaluation, and the
activation is its product. This is survey F11, already in B's rulings item 1.
It is listed here because it is the only place in the chapter where the
two names swap.

1.6 [mid] A1, A2, E. **Two glosses for each of two artifacts.**
- `Structure`: at 135–136 (A1) it is "the artifact holding everything the
  instance alone fixes". At 255–256 (A2) it is "the structure step's product,
  the components, wires, faces and tiers".
- `Outputs`: at 158 (A1) it is "the artifact holding the port classification
  and the order over it". At 257 (A2) and 990–991 (E) it is "the nominal
  evaluation's product, the port classes and the execution order".

Both pairs were already in the old text. Fix: choose one wording per artifact
and use it at every gloss. For example, "(the structure step's product,
holding everything the instance alone fixes)" and "(the nominal evaluation's
product, holding the port classes and the execution order)".

1.7 [mid] A1, C, D, E. **The activation gloss.** "(the build's typed products
at a given scalar type)" appears in §9.4 (616), §9.5 (767), §9.6 (962) and
§9.7 (999). It never appears in §9.1, where the term first carries weight
(38, 155, 189, 195). Fix: gloss it once in §9.1, at 155 ("the nominal
`Float64` activation (the build's typed products at a given scalar type)").
In §9.5, drop the standalone gloss sentence at 767 and rely on the link (see
5.4). The §9.6 and §9.7 glosses can stay, because readers often enter those
sections directly.

1.8 [low] A2. **`Deployment` defined twice in one section.** At 209 the gloss
is "(the scalar-free artifact the grid parameters fix)". At 319–320 the bold
ruling is "A `Deployment` is scalar-free" and the next sentence is "It
carries everything the grid parameters fix". Fix: shorten the gloss at 209 to
"(the artifact the grid parameters fix)". The ruling then adds something new
when the reader reaches it.

1.9 [mid] E. **`ticks` and the `s_update` block.** The phase-body list names
"the `s_update` block" (1041). The arity bullets and the seam list call a
body `ticks` (1056, 1153), and 1058 speaks of "all three tick-sensitive
blocks". The reader cannot tell that `ticks` is that block, if it is.
Appendix B 11076–11079 lists the four bodies as `rhs`, `sweep_1`, `sweep_2`,
`ticks`. Fix: name the body where the block is listed, at 1041: "the
`s_update` block (`ticks`)". Also name `rhs` there: "the `x_deriv` block
(`rhs`, the RHS body …)". Then "`rhs` takes no index" at 1058 has a referent.
Confirm the mapping first.

1.10 [mid] A1, C, E. **"Fold" means two things.** In §9.1 the word is the
`sample_times` compilation (118, "a fold down the tree"). In §9.5 it means a
check that compiles away: 818 "verifies the fold empirically", 919 "folds
when inferred". §9.7 uses it the second way too (1005, "fold-away"; 1105,
"check folding"). Fix (C) at 818: "The canary ([§7.5][s7-5]) verifies
empirically that the check folds away, rather than by assertion."

1.11 [low] v4, E. **"Chunk" means two things.** At 709, "§14.10 chunks at
whatever widths it needs" refers to ForwardDiff seeding widths. In §9.7
(1066, 1102) [chunking](#g-chunking) is the executor's tuple split. Fix (v4):
"even though [§14.10][s14-10] seeds at whatever widths it needs".

1.12 [low] E, frozen. **"Anchor" means two things.** At 1111, "Measured
anchors" uses the word for measurement reference points, inside a chapter
where *anchor* is a glossary term for timing anchors (§9.1, §9.2). The block
is frozen. Fix: record it for the compile-cost ruling ("reference
measurements").

1.13 [low] A1. **One check, two names.** It is "the unconnected-input
obligation check" at 23 and "the whole-tree obligation check" at 73. The
old text did the same. Fix: use one name, or write "the whole-tree
(unconnected-input) obligation check" at 73.

1.14 Glossary links missing at first use in a section:
- [mid] A2, 207: `` `Build` `` is never linked in §9.2, the section that now
  bears its name. Link it at 207.
- [low] v4, 618: `` `Build` `` is never linked in §9.4.
- [low] B, 518: "root inputs" is never linked in §9.3, though it is the
  section's main subject. Link it at 518 or at the roadmap mention at 479.
- [low] B, 511–513: §9.3 explains `ws` and `ws_init` without the glossary
  term. Fix: "`ws`, the [workspace](#g-workspace), comes from …". This
  touches the bold sentence at 512, so the link may sit in the sentence
  before it.
- [low] C, 766: "execution order" first appears in the executor gloss, but
  the link waits until 903. Link it at 766.
- [low] E, 993: "The executor compiles from that order" is unlinked. The
  link waits until 1092. Move the link to 993.
- [low] E, 1084: the bundle gloss ("the NamedTuple of zero-copy views …")
  sits on the second use. The link is at 1010. Move the gloss to 1010.
- [low] A1, intro 13–16: the roadmap's `Build`, `Deployment` and
  "activations" are unlinked. This is optional for a roadmap.

1.15 [low] All, inherited. Glossary links repeated within one section. The
old text had all of them, and the brief kept them:
- §9.1: `g-face` (21, 63), `g-structure` (37, 135), `g-outputs` (38, 154),
  `g-events` (38, 154), `g-activation` (38, 155, 189), `g-root-input` (86,
  143), `g-tier` (106, 140), `g-feedthrough` (161, 174).
- §9.3: `g-tier` (497, 558).
- §9.4: `g-walked` (674, 706).
- §9.7: `g-measurement-seam` (1032, 1140).

Fix: keep only the first link in each, if the user lifts the keep-every-link
rule.

## 2. Duplication and pointers

2.1 [high] A2. **M4 was only half applied.** Lines 244–250 keep the
immutability argument: "true by construction once buffers are single-owner.
Each `Simulation` materializes its own buffers … nothing writable is shared."
They also keep the lock clause, "under the lock that makes insertion
torn-state-free", and add the pointer to §9.4. The brief asked for one
pointer. §9.4 says the same things at 723–733 (single ownership,
materialization from layouts) and 749–754 (torn-state freedom). Worse, a
cold reader meets "under the lock" in §9.2 and "The mechanism is
unspecified" in §9.4 (752), 500 lines apart (survey F6). Fix: keep the bold
sentence at 244 and the pointer only. For example: "**The `Build` is
immutable and may back any number of deployments and `Simulation`s,
concurrently** ([D-135][d-135]). [§9.4][s9-4] states why: buffer ownership,
the activation dictionary's keying and its torn-state-free insertion."

2.2 [mid] A1. **"Final divisors wait for `Δt_base`" is said three times.**
The places are §9.1 127 and 131–133 ("Final divisors for anchored entries
genuinely cannot exist until `Δt_base` binds"), §9.2 281–287 (with its
reason, that one `Build` backs many deployments), and §9.2 417–418 (the
example). This is survey overlap 3. No move covered it, and the survey judged
§9.2 281–287 the best. Fix: in §9.1, keep 131's first sentence and replace
132–133 with a pointer: "[§9.2][s9-2] states why final divisors wait for that
binding."

2.3 [low] A2. **The constructor's inputs are stated twice in §9.2.** Line 229
("The `Deployment` constructor takes a `Build` and the grid parameters") and
321–322 ("The constructor consumes the `Build` and the grid parameters") say
the same. A2's rulings item 5 notes this. Fix: at 229, write "The `Deployment`
constructor (below) is the first step, and the three `Simulation` forms are
these:". This also fixes 5.8.

2.4 [mid] v4. **A stale pointer after M8.** At 636, "Their first invocation
precedes the nominal evaluation's probes ([§9.1][s9-1]/[§9.3][s9-3])". After
M8, §9.1 holds only a pointer to §9.3. Fix: cite "([§9.3][s9-3])" alone. That
also removes the slash-joined citation, which nothing else in the spec uses.

2.5 [mid] B. **"Probe-scoped" three times in eight lines** (554–561). See 6.5.

2.6 [low] A1. **The nominal evaluation's products restated within one
subsection.** At 187–189, "The nominal activation is its product beside
`Outputs` and `Events`" repeats the bold sentence at 153–155. Fix: make the
paragraph one reason sentence. "Because the nominal activation is assembled
from the same probe chain as `Outputs` and `Events`, never in a separate pass,
the step fixes the structure and the `Float64` typing at once ([D-253][d-253],
[D-259][d-259]). That is why …"

2.7 [low] B, inherited. §9.3 lists the probed set twice, at 484–485 and
571–572. The §9.1 table (38) gives a third, shorter list (survey F1, in A1's
rulings). Nothing to move. Noted for completeness.

Pointers checked and correct after the moves: 44–46 (§9.2 for `Build`,
`Deployment`, `Simulation`), 171 (workspace, §9.3), 199 (§9.4), 207 and 226
(§9.1), 249 (§9.4), 304 (§13.7), 351 and 326 ("below"), 491 (§9.5), 512 ("`t`
… sourced below"), 992 (§9.2), 1129 (§9.4). No pointer in the chapter still
sends a reader to §9.1 for the `Deployment` or the warnings.

## 3. Bold

3.1 Counts:

| section | bold spans | words | spans per 1,000 words | share of words in bold | blocks with bold |
|---|---|---|---|---|---|
| intro | 0 | 123 | 0 | 0% | 0 of 2 |
| §9.1 | 11 | 1,340 | 8.2 | 11.6% | 10 of 32 |
| §9.2 | 18 | 2,024 | 8.9 | 9.0% | 18 of 41 |
| §9.3 | 9 | 1,064 | 8.5 | 9.2% | 9 of 23 |
| §9.4 | 12 | 1,024 | 11.7 | 11.3% | 12 of 25 |
| §9.5 | 16 | 1,589 | 10.1 | 12.9% | 15 of 27 |
| §9.6 | 0 | 224 | 0 | 0% | 0 of 2 |
| §9.7 | 13 | 1,520 | 8.6 | 7.8% | 13 of 28 |
| chapter | 79 | 8,957 | 8.8 | 9.8% | |

The old chapter had 81 bold spans holding 403 words (4.7%). The new one has 79
spans holding 877 words (9.8%). The count of bold spans barely moved. Each one
is now a full sentence, so the bold weight on the page doubled. In §9.5,
§9.4 and §9.2, more than half of the paragraph and bullet blocks carry bold.
Every `####` subsection of §9.2 and §9.5, and all but one of §9.7's, opens on
a bold sentence, so bold has started to work as a second heading level.
[high] This is the chapter-level finding the per-section checks could not
see.

3.2 No ruling is bold in two sections. The entries bolded most often are
D-053 eight times in §9.5 (827, 834, 888, 915, 928, 940, 949, 953), D-254
four times in §9.2 (228, 319, 392, 422), D-186 three times in §9.2 (272,
330, 349), D-086 four times and D-116 four times in §9.7, D-253 six times
across §9.1, §9.2 and §9.4, and D-052 three times in §9.4. Each bold states a
different part of its entry, so none is a duplicate under the convention.
The weight comes from the count.

3.3 [mid] Bold spans longer than their ruling. Trimming the bold to the
headline clause would roughly halve the bold weight without unbolding any
ruling.
- A1, 135–136: a gloss sits inside the bold. Fix: "**The structure step
  returns `Structure`, and that is its whole product** ([D-253][d-253]).
  `Structure` is the artifact holding everything the instance alone fixes. It
  carries the following:".
- A1, 153–155: the bold carries three linked artifact names. Fix:
  "**The nominal evaluation is a function of the `Structure` that returns three
  artifacts** ([D-253][d-253], [D-259][d-259]). They are
  [`Outputs`](#g-outputs), [`Events`](#g-events) and the nominal `Float64`
  [activation](#g-activation)."
- C, 827–828: move the aside "the only one that ever runs in real time" out of
  the bold, into a following sentence.
- C, 940–942: end the bold at "the field-level diff". Put "(missing /
  unexpected / per-field expected-vs-observed)" in a plain sentence after the
  citation.

3.4 [mid] Bold on something other than the ruling, or a bold sentence that
cannot stand alone:
- A1, 95: the bold starts "It is decided by …". Skimmed alone, it has no
  subject. Fix: "**The walk-compatibility clause is decided by retyping both
  declarations …**", with the sentence before it rephrased to "The second type
  clause applies to continuous consumers only."
- A2, 313: "**The chart guard is binary**" is a label. The rule is the next
  sentence, "The chart prints whole … when `lcm(Dᵢ)` is at most 100 base
  ticks". Fix: bold that sentence instead, and put the citation after it.
- B, 564: "**Enforcement is the pre-write `UninitializedInputs` check …**"
  makes the mechanism the subject. Fix: "**Every complete-world application,
  namely `init!`, trim setup and trim commit, carries the pre-write
  `UninitializedInputs` check** ([§14.6][s14-6], [D-149][d-149])."
- C, 949: "**The source branch is deliberately absent from the payload**" is
  bold. Survey row 121 found no entry that states it. If the D-053 citation
  does not hold up, make it plain. This is a candidate for the user, not a
  fidelity ruling.

3.5 [mid] v4. **Stacked bold one-liners.** Lines 718, 721 and 723 are three
consecutive one-sentence paragraphs, each entirely bold. They read as a run
of headlines. Fix: join 718 and 721 to the cache paragraph at 711–716, with
the bold kept as sentences inside it. Let 723 open the ownership list as it
does now.

3.6 [low] E. **The measurement seam's bold.** The seam subsection has five
bold sentences in about 55 lines (1139, 1158, 1167, 1173, 1187). Four of them
cite D-116. E's rulings question 4 asks the same thing. The candidates for
plain text, if the user wants fewer, are 1173 (a CI procedure) and 1187
(ruled only in D-116's Rationale, survey row 150).

## 4. The opening

4.1 The intro roadmap (12–16) matches the seven sections, their titles and
their order. §9.2's new title is spelled the same in the roadmap and the
heading.

4.2 [mid] A1. **§9.1 opens mid-argument.** Its first sentence, "Three ordering
constraints are forced by settled decisions", presupposes that the reader
knows what is being ordered. Fix: add one lead sentence before it, for
example "The build runs as a fixed sequence of steps, each checking what it
can with what it has in hand." Or open with the table's job: "This section
states the build's steps, what each consumes and produces, and what each
checks." Either is a declared addition with no claim.

4.3 §9.2 (207–214): the context comes first, and the parts sentence matches
the five labels in order. The Rendering placement is a separate problem
(5.1).

4.4 [low] B. §9.3's parts sentence (478–480) matches the text, except that
the `ws`/`t` paragraph (511–516) sits outside "probe argument sourcing". The
placement fix in 5.2 resolves this.

4.5 §9.4, §9.6 and §9.7 open with context before their first rule. §9.5
(758–761) also does, though in two terse sentences. A parts sentence is
optional there, since the section has labels.

## 5. Flow

5.1 [high] A2. **Rendering comes before what it renders.** "Rendering"
(289–315) precedes "The `Deployment`" (317–418). The reader meets
`show(::Schedule)` "prints the rows and the hyperperiod chart", "the
chart's pattern repeats with period `lcm(Dᵢ)`" and "the gate is pure modulo
arithmetic" about 80 lines before the `Schedule`'s rows are described
(392–400). The old order (old 330–365) described the `Schedule` before `show`.
The D-261 rule at 291–295 ("a compiled form stored beside its declared one is
a second home") also sits 100 lines from its only application in the section,
at 396–398 ("derived from the rows at `compile`, never stored beside them").
A2's rulings question 2 raises the same point. The brief's label order caused
it. Fix: put Rendering after The `Deployment` and before Grid diagnostics. A
smaller fix moves only the chart paragraph (311–315) to follow 400, and the
D-261 paragraph (291–295) to sit just before the `Schedule` paragraph.

5.2 [mid] B. **Argument sourcing is split by the checks.** The order runs
sourcing list (494–504), then "Two checks ride the same pass" (506–509), then
"The bundle law's two remaining fields … `ws` and `t`" (511–516), which is
more sourcing, then synthesis. Fix: move 511–516 up to follow 502–504, so
both checks come after all sourcing. The roadmap's "probe argument sourcing
and its two checks" then matches.

5.3 [mid] C. **"Two leaf kinds", then three treatments.** Line 833–834 says
"the two leaf kinds the declaration ([§8.2][s8-2]) distinguishes are checked
differently". The text then gives walking (834), opaque (842), "Nothing else
is accepted" (847) and only then pinned (853), the second of the two kinds.
Fix: name the two kinds and flag the third. "… the two leaf kinds the
declaration ([§8.2][s8-2]) distinguishes, walking and pinned, are checked
differently, and an opaque leaf ([§4.3][s4-3]) has a rule of its own."

5.4 [mid] C. **A gloss sentence breaks an argument.** At 767, "An activation
is the build's typed products at a given scalar type." sits between "the
complete expected return type at this activation" and "The expected type is
the type of the cells …", which continues the same thought. C's rulings item
10 says the cold verifier flagged it. Fix: drop the sentence, since
"activation" is linked at 767. Or put the gloss back on "non-nominal
activation" at 833, where old §9.5 had it.

5.5 Jargon and names used before they are introduced:
- [mid] C, 796: `` `Expected` `` appears as an identifier. Until then the text
  says only "the expected return type" and "the expected type". Fix: "The
  expected type's order is an internal fact."
- [mid] C, 816: "the economics ([D-053][d-053])" names nothing the reader has
  seen. Fix: "which is how D-053's cost claim holds", or "the check's
  economics".
- [mid] E, 1059: `` `t*` `` is never introduced in the chapter. §10.4 (spec
  4500) defines it as the localized event time. Fix: "**At a localized event
  time `t*` ([§10.4][s10-4]), the empty due set is arity selection, not an
  index trick**".
- [mid] E, 1058: "`rhs` takes no index. One gate serves all three
  tick-sensitive blocks". Neither `rhs` nor the three blocks has been named
  by that point. See 1.9.
- [low] E, 1088: "CSE" is not expanded. Fix: "Common-subexpression
  elimination (CSE) merges …". In the frozen block, "SROA" (1105) and "TTFX"
  (1135) are also unexpanded. Record them for the compile-cost ruling.
- [low] A2, 312: "the gate is pure modulo arithmetic" comes before §9.7
  introduces gating (1010). Fix: "the gate (`(tick − Φ) % D == 0`,
  [§9.7][s9-7]) is pure modulo arithmetic".
- [low] A1, 78: "before the classifier … read[s] the value". This is the
  class reading of walk step 2. The chapter has another classifier, the cycle
  classifier, at 663. Fix: "before the class reading (step 2) and the
  vocabulary checks read the value", if that is the meaning.
- [mid] D, 970 and 974: "the `T`-generic assignment math" and "the
  assignment's *output*". M13 moved out the old sentence that introduced the
  assignment (old 764–767). §14.7 defines it (spec 9801, "the pure
  `trim_condition(ac, params, d)` fragment-tree function"). Fix: "… seeded
  through the `T`-generic assignment (the user's function from decision
  variables to a [condition](#g-condition), [§14.7][s14-7]) …".
- [low] A1 171 and B 513: "the probing scalar" is never named. If it is
  `Float64` at the nominal evaluation, say "the probing scalar (`Float64` at
  build)". Otherwise leave it.

5.6 Unintroduced names, by class:
- Class 1, Flight.jl machinery used as if known:
  - [mid] D, 982: "the hand-written `get_x_ss`/`assign_x_ss!` layer". §7.1
    (spec 1583) calls it "the hand-written per-aircraft state-space mapping
    layer". Fix: "replace FlightCore's hand-written per-aircraft state-space
    mapping layer (`get_x_ss`/`assign_x_ss!`)". This turns it into class 3.
  - [mid] E, 1183–1185: "the migration suite's `@ballocated
    f_ode!`/`f_step!`/`f_periodic!` idiom". The migration suite is not
    introduced, and the function names are FlightCore's. Fix: "This is the
    successor of FlightCore's `@ballocated f_ode!`/`f_step!`/`f_periodic!`
    idiom, as used in the migration suite." E's rulings question 3 is
    related.
- Class 2, aerospace examples that need one introducing clause:
  - [low] A2, 402–406: `fcs` and `gnss`. Fix: "a flight-control scope `fcs`
    and a GNSS receiver `gnss`" (check against §10.5's code block).
  - [low] B, 591: "A strut throwing on a touchdown overload". Fix: "A
    landing-gear strut model that throws on a touchdown overload".
  - [low] v4, 670: "interactive fly-around use". Fix: "interactive use, such
    as flying the model by hand,".
  - [low] v4, 737: "the envelope-grid gain-schedule case". Fix: "computing a
    gain schedule over a grid of flight conditions, where hundreds of …".
  - Frozen (E 1112, 1121–1122, 1133): "aircraft model", "aircraft package".
    These are clear enough.
- Class 3, FlightCore named as predecessor: E 1185 ("the FlightCore
  comparison in `migration_outline.md`"). Fine.
- Not Flight.jl: `RQuat` (B 527) is a spec domain type (spec 573, 1504).
  Optionally gloss it as "the rotation-quaternion type".

5.7 [mid] A2. **The example's opener stutters** (402–406): "… and that
section's code block gives their `sample_times`. `sample_times` declares
`fcs = Relative(1)` and `gnss = Absolute(Hz(50))` at the root." It says the
code block gives the declarations, then lists half of them. `inner` and
`outer` first appear in the table header. Fix: "The model worked in
[§10.5][s10-5] has three discrete components under two scopes, declared in
that section's code block. At the root, `fcs = Relative(1)` scopes `inner`
and `outer`, and `gnss = Absolute(Hz(50))` stands alone. Deploy it at
`Δt_base = 2 ms`."

5.8 [mid] A2. **"Two sugar forms", then "three `Simulation` forms"**
(228–230). A reader counts and finds a mismatch, because the first form is
the materialization step itself. Fix: "The `Simulation` constructor has three
forms, the materialization step and the two sugar forms:".

5.9 [low] B. **The three habits are not parallel** (587–602). The bullets
open "A *plausibility* check … is", "Take a *self-consistency* assert …"
and "The third is the *defensive exhaustiveness* branch". After the list,
"Such a branch" (604) can read as covering all three. Fix: open each bullet
the same way ("A *plausibility* check …", "A *self-consistency* assert …", "A
*defensive exhaustiveness* branch …"). At 604, write "A
defensive-exhaustiveness branch is not banned validation but mislocated
validation."

5.10 [low] A1, inherited. The root-inputs paragraph (86–87) sits between the
explanations of the store form and of the type clauses. Both explain items
of the resolution list. Fix: move 86–87 after 99.

5.11 [low] C. The per-function list (891–905) orders x_deriv, guards,
s_update, handlers, x_projection. The subsections that follow take handlers
(907) before guards (926). Fix: swap the two subsections, or reorder the
bullets to match.

5.12 [low] D, 963: "This section is sketched here because it grounds the
build's steps" reads oddly. Fix: "This section is only a sketch, kept here
because it grounds the build's steps."

5.13 [low] E, 1066: "between chunks" comes before chunking is introduced
(1102, under Compile cost). Fix: link [chunks](#g-chunking) at 1066.

## 6. Places that read worse than the old text

6.1 [high] A2. Rendering before the `Schedule` (5.1). In old §9.2 the
`Schedule` paragraph came before `show` and the chart.

6.2 [high] All. The bold weight doubled (3.1). Old bold was often a label.
New bold is always a ruling, but now runs to full sentences and opens most
blocks in §9.4 and §9.5.

6.3 [mid] C, 767. The standalone activation gloss (5.4). Old §9.5 read
straight through at that point.

6.4 [mid] A2, 402–406. The example's opener (5.7). Old 367–372 gave all four
declarations in one sentence.

6.5 [mid] B, 554–561. **The merged clock paragraph** (M9) repeats itself.
"`t` is probe-scoped `0.0`", then "So, like `Δt` below, `t` is a fabricated,
probe-scoped value", then the `Δt` sentence, then "It is a fabricated,
probe-scoped value like any synthesized input". "Below" points at the next
sentence, and two sentences in a row open with "So". Fix: "**`t` is
probe-scoped `0.0`** ([D-115][d-115]). Deployment binds no clock, and `t₀`
post-dates even deployment ([§14.5][s14-5]). `Δt` in seconds does not exist
until `Simulation` binds `Δt_base`, since deployment post-dates the build, so
discrete-tier probes supply a placeholder period (`1.0`) in the bundle. Both
are fabricated, probe-scoped values like any synthesized input. The probe
checks types, not physics." Verify this against B's inventory before
applying, since it joins two claims' wording.

6.6 [mid] D, 970–974. "Assignment" lost the introduction it had (5.5).

6.7 [low] A2, 430–432. "… one culprit crowned** ([D-187][d-187]). That is
because joint responsibility is the honest answer." Old 393–394 joined the
reason with "because". The new "That is because" sentence is stiff. Fix:
"Joint responsibility is the honest answer." This keeps the reason as a
following sentence, as the convention allows. Check with the verifier that
the causal link survives.

6.8 [low] All, assembly. Fixer splices left lines over 80 columns: 111, 314,
406, 527, 767, 773, 777, 854, 862, 871, 903, 916, 1023, 1058, 1102. There is
also a broken wrap at 767–770 ("writes,\nas the probe fixed them"). Fix:
reflow at assembly. The frozen block's 1102 was rewrapped when its bold was
removed. Check that the block is otherwise verbatim.

## Overall

The new chapter reads clearly better than the old one. The labels are gone.
The 500- and 600-word paragraphs are split, and lists and display blocks
carry the mechanisms. Every section opens with context. All `Deployment` and
warning material sits in §9.2, and §9.6 is now a true sketch. The remaining
problems are few and local. Three are worth fixing before landing: §9.2's
Rendering order, the half-applied M4 with its "under the lock" contradiction
of §9.4, and the doubled bold weight. The rest is wording.
