# Survey of spec chapter 10 before its readability rewrite — 2026-10-02

Scope: `docs/design/spec.md` lines 4689–5792, "## 10. Time and execution", at
commit `08f5dff`, 9,369 words. The convention is
`docs/design/tools/spec_style.md`; the method is `docs/spec_rewrite/recipe.md`
step 1; the model is `docs/reports/20261001_chapter9_rewrite/survey.md`.

Line numbers are `spec.md` lines unless marked `log` (`decisions.md`). Entry
claims rest on the entry's Position as read, with its log line given where the
point sits outside the Position's first sentence. Every entry cited below was
read in full; the code in `src/` was read where a name was in doubt.

Classification codes used in part A:

- **C** cited, and ruled by the cited entry's Position (at the spot or in the
  same paragraph, marked "adjacent").
- **U** ruled by an entry's Position that the section does not cite at that
  spot.
- **S** cited to a superseded entry.
- **R** ruled only in an entry's Rationale, Rejected list or annotation.
- **N** no entry found. Where the sentence reads as a description of an
  inherited status quo rather than a ruling, the row says so.
- **B** borderline; both readings are given.

"Marking" is how the spec marks the rule now: **Rule.**/**Why.** label (and
one **Consequence.** label, 5022, which the convention does not have), bold
sentence, bold lead-in (a bold phrase opening a paragraph, used as a heading),
bold word, or plain.

Section sizes (words): 10.1 126; 10.2 688; 10.3 72; 10.4 2,794; 10.5 2,648;
10.6 2,047; 10.7 989; the chapter heading 5.

## A. Per section

### Chapter intro (4689–4690, 5 words)

There is none. The `## 10.` heading is followed at once by `### 10.1`.
Chapter 9 has a context paragraph and a roadmap sentence (3393–3407). The
only roadmap for chapter 10 is the Part III roadmap at 4671–4676, which names
the six subjects in order (loop, seam, localization, tick lattice, event
iteration, pacing) but not §10.3, and which says nothing of the two terms the
whole chapter runs on, *frame* and *boundary* (defined only in §10.4,
4818–4829). Part G, question 1, asks whether the rewrite adds an intro.

### §10.1 Loop ownership (4691–4710, 126 words)

Purpose: states that the framework writes the simulation loop itself, and
drops `OrdinaryDiffEq`.

Subheadings: none. Labels: **Rule.** 4698, **Why.** 4702.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 1 | 4693–4696 | "The simulation loop consists of six activities: the §5.3 boundary sequence, tick dispatch, event handling, logging, input staging, and pacing" | plain | D-017 Position says only "Framework-owned simulation loop"; no entry enumerates the six | B: U by D-017 for ownership; N for the six-item list, a description of the loop inherited from the FlightCore comparison |
| 2 | 4698–4700 | "**Rule.** All six are **framework code, unconditionally**. … It does not assemble the loop out of callbacks registered with a third-party solver." | **Rule.** label, bold words | D-017 Position (cited 4706) | C (adjacent) |
| 3 | 4702–4706 | **Why.** only a framework-owned loop enforces the step-boundary contract by construction; `CallbackSet` choreography rejected | **Why.** label | D-017 Rejected log 611–621 | reason (adversarial half, see part G q3) |
| 4 | 4708–4709 | "`OrdinaryDiffEq` is therefore **dropped as a dependency**" | bold words | D-017 Position (cited) | C; the "therefore" demotes the rule to a consequence (`spec_style.md`, "Rule first, reason after") |

Descriptions that read like rules: row 1. The pacing gloss in 4695–4696
("waits inserted between completed frames, never altering the boundary
sequence") restates §10.7's invariant (D-021), uses *frame* before any
definition, and is the first use of *boundary sequence* in the chapter.

Display-block candidates: none.

### §10.2 The stepper seam (4711–4797, 688 words)

Purpose: the one operation the loop delegates, what a backend must provide,
the empty-state short-circuit, the first-cut backends and their keyword, and
the domain argument for fixed-step low-order methods.

Subheadings (`####`): "What the seam requires of a backend" (4718), "Models
with no continuous state" (4732), "The first-cut backends" (4750), "Why
fixed-step low-order suffices" (4770). Bold lead-ins: the three clauses
(4722, 4726, 4728) and the three domain points (4775, 4781, 4787).

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 5 | 4713–4716 | "Loop ownership stops at one operation … The framework delegates that operation across a narrow internal interface, the **stepper seam**" | bold term | D-017 Position ("stepper seam") | U (D-017 is cited only at 4730) |
| 6 | 4720 | "The seam contract has three clauses." | plain | D-017 Position | U; D-274 Position bullet 1 (log 11103–11104) adds a fourth obligation, a checkpoint hook, absent from the spec (part E, F1) |
| 7 | 4722–4725 | "**Advance by arbitrary `h`.**" lands on tick boundaries, resumes from a localized event time | bold lead-in | D-017 Position | U |
| 8 | 4726–4727 | "**Dense output on demand over the last completed step.** Only event localization needs it (§10.4), so the backend constructs it lazily." | bold lead-in | D-017 Position; "lazy" D-018 Position log 630 | U |
| 9 | 4728–4730 | "**One-step methods only.** … Multistep methods are excluded" | bold lead-in | D-017 Position (cited); reason D-017 Rejected log 624 | C |
| 10 | 4734–4735 | "A model with no continuous state at all is legal." | plain | D-156 Position log 5322–5325 ("Empty continuous block") | U |
| 11 | 4737–4741 | "**The seam is never entered empty.** … the integrate step degenerates to advancing `t` to the next boundary, and the stepper is not called. No backend ever faces `N = 0`" | bold sentence, no citation | D-156 Position log 5322–5325 | U |
| 12 | 4743–4748 | the dummy-`[0.0]` tax under a foreign loop is "gone at the root"; boundary machinery unchanged | plain, cites D-017 | D-017 Rejected log 618 (the tax); D-156 Position ("completing §10.1's removal of the dummy-`[0.0]` tax") | B: R by D-017 for the tax; U by D-156 for its removal |
| 13 | 4752–4755 | "The first cut ships **in-house fixed-step RK4 and Heun** over the flat state buffer … about a hundred lines … trivially zero-allocation … trivially `T`-generic" | bold phrase, no citation | D-017 Position ("in-house fixed-step RK4/Heun as the sole first-cut backends") | U for the backends; N for the properties (descriptions) |
| 14 | 4755–4757 | "Genericity is not even required of the stepper, because linearization and the tracer drive the *sweep*, never the integrator." | plain | none found | N |
| 15 | 4759 | "Of the two, **`RK4` is the default**." | bold phrase | D-227 Position (cited 4763) | C (adjacent) |
| 16 | 4759–4763 | `algorithm` selects the backend by type on the `Deployment`; materialization at `Simulation` construction binds the stepper against the state buffer, on the executor | plain, cites Appendix B, §9.2, D-227 | D-227 Position; "on the executor" D-256 Position bullet 2 (log 9639) | C; U for the executor clause |
| 17 | 4763–4764 | "The step `h` has no default and is **required** of the caller. A domain rate is not a framework default." | bold word, no citation | none found; Appendix B 11162 repeats it | N |
| 18 | 4766–4768 | an `OrdinaryDiffEq`-backed stepper "can exist later as a package extension … Per the guarded-additions rule it is not built until then" | plain | D-017 Position ("possible future extension adapter"); D-227 Rationale log 8258–8261 | U |
| 19 | 4775–4780 | "**The closed-loop tick cap.** … the integrator must land on every tick boundary regardless of method … the execution model forbids the stretch by construction" | bold lead-in | landing on ticks: D-019 Position ("Harmonic tick grid on step boundaries"); the argument: none | B: U by D-019 for the landing rule; N for the argument |
| 20 | 4781–4786 | "**A piecewise-smooth RHS starves high order.** … RK4 at 50 Hz already puts integration error orders of magnitude below the model uncertainty" | bold lead-in | none (D-018 Rejected log 648 makes a related point about guards) | N |
| 21 | 4787–4796 | "**Stiffness has a remedy ladder.** … First shrink `h` … Then subcycle the stepper against the tick grid. Only then reach for an implicit method through the adapter." | bold lead-in | none | N; reads as authoring guidance, not a ruling |

Rows 19–21 are the domain argument "recorded here because it is decisive for
the whole axis" (4772–4773). D-017's Rationale is "Recorded only through the
rejections below" (log 608), so the argument has no log home at all. It also
rests on Flight.jl facts stated as present tense: "50 Hz today" (4776), "the
current codebase" (4788), the 31 rad/s actuator poles, gear damper, friction
compensators (4789), "The crosswind-landing demo is the empirical proof"
(4790). Part G, question 2.

Descriptions that read like rules: row 13's "about a hundred lines" and
"trivially" claims; row 14.

Display-block candidates: none needed. The seam's operation is never named in
the spec; `src/stepper.jl` 7 calls it `integrate!(stepper, sim, h)` since
`4eb2d5a` (part E, F2).

### §10.3 Signal-table consistency is a boundary property (4798–4809, 72 words)

Purpose: says the table is integrator scratch during a step and meaningful
only at boundaries, and binds the periphery to that.

Subheadings: none. Label: **Rule.** 4806.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 22 | 4800–4802 | RK stages evaluate the interior sweep (§10.5) at internal stage states; the table is transiently "**integrator scratch**" | bold term | D-147 Position log 4928–4930 | U |
| 23 | 4802–4804 | "The boundary sweep in the §5.3 sequence restores consistency at each accepted boundary." | plain | D-147 Position log 4933–4937 | U |
| 24 | 4806–4808 | "**Rule.** External readers (GUI, logging, network output) observe the signal table only at step boundaries. Mid-step contents carry no meaning. This rule binds the periphery (§11)." | **Rule.** label, no citation | D-023 Rejected log 779 ("*Mid-step publication:* see §10.3"); D-147 lists §10.3 in its Spec field | R |

§10.6 5661–5663 states the stronger form: "[§10.3] extends naturally.
External readers observe the table only after the boundary sequence
completes", which also excludes mid-boundary (between-round) contents. That
is the rule's full statement, and it sits in a bullet about ticks (part B,
overlap 5).

Display-block candidates: none.

### §10.4 Localization mechanics (4810–5144, 2,794 words)

Purpose: which guards localize, the trigger, the localization loop (θ = 0
validation, interpolant, trial evaluations, root-finding, convergence), the
endpoint policy and grid integrity, what a `t*` boundary does, projection's
reach, the localization budget and the two deployment constants. Its opening
also defines *frame* and *boundary* for the whole chapter.

Subheadings (`####`, 10): "Which guards localize: the form is the policy"
(4841), "Boundary detection is exact for guards over `u` and `m` alone"
(4865), "Mixed predicates: the gate idiom" (4875), "The trigger" (4889), "The
localization loop" (4906), "Endpoint policy and grid integrity" (5017), "What a
`t*` boundary does, and does not, do" (5053), "Projection's reach is the
boundary, not the trial evaluation" (5078), "Budget exhaustion degrades; it
does not throw" (5092), "Both constants are deployment, not implementation"
(5123). Several are claims rather than topic labels (part C). "The
localization loop" runs 1,012 words under eleven bold lead-ins. Labels:
**Rule.** 4843, 4867, 4880, 4891, 5019, 5080, 5094; **Why.** 4856, 4869,
4884, 5025, 5084, 5141; **Why 8.** 5098; **Consequence.** 5022. One code
sketch (4911–4927), one chain blockquote (4834–4835).

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 25 | 4818–4826 | a **frame** is one grid step, the unit of scheduling, keyed to the drain, pacer deadlines and tick eligibility; a **boundary** is a published consistency point | bold terms | D-081 Position log 2327–2329 | U (D-081 is cited nowhere in the spec chapter) |
| 26 | 4827–4829 | "Every grid point is a boundary, but not every boundary is a grid point. The localized event time `t*` is a boundary, and so is boundary zero … Neither is a frame top." | plain | D-081 Position ("grid, `t*`, boundary zero") | U |
| 27 | 4831–4839 | the one-frame chain; "This chain lists the order of operations. It is not a walk along the time axis." | blockquote | D-182 Position (trigger on the arrival sweep, θ = 0 first) | mechanism |
| 28 | 4843–4844 | "**Rule.** The guard's return type declares its detection policy. No flag is involved." | **Rule.** label | D-179 Position (cited 4854) | C (adjacent) |
| 29 | 4846–4850 | `Bool` ⇒ **boundary-detected**, never root-found; nominal scalar ⇒ **localized** | bold terms | D-179 Position | C (adjacent) |
| 30 | 4852–4854 | the build reads the policy off the probe; "`StateEvent(guard, handler)` therefore carries no detection keyword" | plain, cites D-179 | D-179 Position ("`Event(guard, handler)` loses the `localize` keyword") | C |
| 31 | 4856–4858 | **Why.** only the sign form brackets a root; the illegal pairing cannot be written | **Why.** label | D-179 Rationale log 6299–6300 | reason |
| 32 | 4860–4863 | "**A localized guard becomes boundary-detected with a one-line rewrite, at no semantic cost.** Return the predicate `σ ≥ 0` instead of `σ`." | bold sentence, no citation | D-179 Position ("de-localization = casting the guard to its predicate … semantics-preserving by construction") | U |
| 33 | 4867 | "**Rule.** For a guard that reads only `u` and `m`, boundary detection is exact." | **Rule.** label, no citation | D-179 Rationale log 6301–6302 ("recorded doctrine") | R |
| 34 | 4869–4873 | **Why.** `u` changes only at the drain, `m` only through handlers; no interior instant | **Why.** label | D-179 Rationale | reason |
| 35 | 4877–4878 | "The piston engine's `starting → running` fires on `ω > ω_idle && fuel_available`." | plain | — | example; reader-cold (no introducing clause) |
| 36 | 4880–4882 | "**Rule.** When such a transition should localize, write it in the gate form `(gate) ? σ : -one(σ)`." | **Rule.** label, no citation | D-179 Rationale log 6302–6304 ("the blessed way to localize a mixed predicate") | R |
| 37 | 4884–4887 | **Why.** trial evaluations vary only θ; gates constant over the bracket | **Why.** label | D-179 Rationale ("gates frame-constant through probes") | reason |
| 38 | 4891–4894 | "**Rule.** A localized event triggers when its predicate was not-holding at tₙ's quiescence … and is holding at tₙ₊₁. The tₙ sample is the event's **prior**" | **Rule.** label, bold term, no citation | D-082 Position log 2354–2359 (per-event baseline = previous boundary's quiescent sample); D-181 Position (prior); trigger direction D-121 Rationale log 3567–3570 | U |
| 39 | 4896–4897 | directional edge; "A holding → not-holding transition neither fires nor localizes." | plain | D-082 Position | U |
| 40 | 4899 | "**The trigger check runs against the arrival sweep at tₙ₊₁.**" | bold sentence, no citation | D-182 Position log 6386–6388 | U |
| 41 | 4899–4904 | so it runs before the due-gated boundary sweep; forced by the trial-evaluation rule; "Every `t*` firing precedes tₙ₊₁'s whole boundary sequence." | plain | D-182 Position ("making the ZOH clause's ordering explicit") | U |
| 42 | 4908–4927 | the localization sketch | code | D-018, D-182 | mechanism |
| 43 | 4929–4934 | "**The θ = 0 validation.** On trigger, the first act is a trial evaluation at the left end. Write xₙ … run one interior sweep … σ₀" | bold lead-in | D-182 Position log 6388–6391 | U |
| 44 | 4936–4938 | σ₀ is the left bracket value value-based root-finders need, and it "tells the edge's cause apart" | plain | D-182 Position | U |
| 45 | 4940–4943 | "An **input epoch** is a maximal span of constant `u`, delimited by frame-top drains" | bold term | no Position; D-182 Rationale says "epoch-caused" | N (a definition) |
| 46 | 4945–4951 | "**Why the discriminator is conclusive.** `u` is the only thing that can differ …" | bold lead-in | D-182 Rationale log 6395–6396; D-181 Rationale (honest priors) | reason (R) |
| 47 | 4953–4957 | σ₀ not-holding ⇒ trajectory-caused: pay ẋₙ₊₁, build the interpolant, root-find; σ₀ holding ⇒ epoch-caused | bold words in bullets | D-182 Rationale log 6396–6399 | R |
| 48 | 4959–4968 | "**An epoch-caused edge is discarded, not degraded.** … consumes no `localization_budget`. It also warns nothing. … Boundary firing is therefore the correct semantics" | bold sentence; D-179 cited for the exactness clause only | D-182 Rationale log 6397–6401 | R |
| 49 | 4970–4977 | "**The interpolant is built lazily.**" cubic Hermite over (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁); ẋₙ₊₁ one sweep, paid only on a validated trigger; uniform accuracy O(h⁴) | bold sentence, no citation | D-018 Position log 630 ("lazy cubic Hermite dense output"); the payment rule D-182 Rationale log 6396–6397; order 4 D-018 Rejected log 652 | U for the interpolant; R for the details |
| 50 | 4979–4985 | "**Trial evaluations run the interior sweep.** … Discrete cells therefore hold their tick values through localization" | bold sentence, no citation | D-147 Position log 4928–4931; D-018 Position ("guard probes that run the sweep") | U |
| 51 | 4987–4990 | "**Root-finding is bracketed and derivative-free.** ITP or Brent … bisection is an acceptable fallback. … Newton and AD localization are rejected (D-018)." | bold sentence | D-018 Position; bisection: none | C; N for the fallback |
| 52 | 4992–4995 | "**Convergence is a relative bracket width.** … `localization_tol` is a `Deployment` constructor keyword defaulting to `1e-6`. … (D-133)" | bold sentence | D-133 Position log 3991–3993 (relative test, default); the keyword's home D-256 Position bullet 5 log 9645–9646 (D-133 still says "`Simulation` keywords", log 3990) | C for the test; U by D-256 for the keyword's home |
| 53 | 4995–4999 | why `1e-6`; "Under ITP the bill is a handful of trial evaluations, and around 20 in bisection's worst case." | plain | none (D-133 Rationale gives no reason for `1e-6`) | N |
| 54 | 5001–5005 | "**Post-event.**" boundary sequence at `t*`; interpolant invalidated; remainder step targets tₙ₊₁; guards re-checked on the remainder under the budget, with a chattering diagnostic | bold lead-in | D-018 Position log 632–635 | U |
| 55 | 5007–5010 | "**Multiple events localizing in one step fire at the earliest `t*`.** Ties fire at that boundary … one eligible event per component per round … Later crossings re-localize on the remainder." | bold sentence, cites §10.6 | earliest `t*`: none; one per component per round: D-154 Position log 5243–5245 | B: N for earliest-`t*`; U by D-154 for ties |
| 56 | 5012–5015 | "**Both policies share one blind spot.** An even number of crossings within one step …" | bold sentence | D-121 Rationale log 3569–3570 ("the even-crossings blind spot survives") | R |
| 57 | 5019–5020 | "**Rule.** The root-finder returns the holding endpoint of its final bracket." | **Rule.** label, no citation | D-082 Rationale log 2365–2366; Rejected log 2377–2378 | R |
| 58 | 5022–5023 | "**Consequence.** `t* = tₙ` is structurally impossible." | **Consequence.** label | D-082 Rationale log 2366; D-182 Rationale log 6401–6403 | R |
| 59 | 5025–5033 | **Why.** the left end was measured not-holding under the frame's own `u`; strictly later than tₙ; `nextfloat(tₙ)` | **Why.** label | D-182 Rationale log 6401–6403 | reason |
| 60 | 5035–5037 | the guard observably holds at `t*`; handlers fire where their predicate holds; the post-fire prior records an observation | plain | D-082 Rationale log 2367; Rejected log 2377–2378 | R |
| 61 | 5039–5043 | "**`t* = tₙ₊₁` exactly is legitimate.** … bitwise identical to the boundary-detected one" | bold sentence | D-082 Rationale log 2367–2368 | R |
| 62 | 5045–5051 | "**Grid times are indexed, never accumulated.** … `tₖ = t₀ + k·h` is computed from the frame index … `t*` is a float inside a frame, never an anchor" | bold sentence, cites §10.5 | D-082 Rationale log 2368–2369; Rejected log 2380–2381 | R |
| 63 | 5055–5060 | at `t*` the full §10.6 event phase runs, budget scoped to the boundary and fresh at tₙ₊₁; snapshot, counter increment, `stop_on`; a crash at `t*` ends the run from that snapshot | plain | D-081 Rationale log 2333–2336 (still "once-per-event scoped per boundary"); budget scoping D-181 Position | R; U by D-181 for the budget clause |
| 64 | 5062–5066 | "**Two things do not happen at `t*`.** Ticks are never due there. … Staged inputs are not drained either" | bold sentence | ticks: D-147 Position log 4949–4952; no drain: D-081 Rationale log 2336–2337, Rejected log 2343–2344 | B: U by D-147 for ticks; R by D-081 for the drain |
| 65 | 5068–5071 | "**The `t*` publication is not separately paced.**" | bold sentence | D-081 Rationale log 2337; Rejected log 2345–2346 | R |
| 66 | 5073–5076 | replay pointers and errors index by the frame-entry boundary index (§13.4) with `t`; snapshots carry the published-boundary ordinal (§12.3); the trace stays frame-indexed | plain | D-128 Position; D-230 Position; D-081 Rationale log 2338 | U (D-128, D-230); R (frame-indexed trace) |
| 67 | 5080–5082 | "**Rule.** Guard trial evaluations run against the raw interpolated state. Authority rests with the `t*` boundary. Projection runs there" | **Rule.** label | D-018 Position log 636–639 (cited 5086) | C (adjacent) |
| 68 | 5084–5086 | **Why.** RK stages are equally off-manifold; per-trial projection rejected (D-018) | **Why.** label | D-018 Rejected log 646–647 | reason, C |
| 69 | 5088–5090 | a projection that undoes the crossing: no firing, one extra boundary, harmless, deterministic, pace-independent (D-080) | plain, cites D-080 | D-018 Position ("costs one extra harmless boundary") | C (D-018 adjacent) |
| 70 | 5094–5096 | "**Rule.** `localization_budget` is an integer count of localizations permitted within one frame. It defaults to **8**." | **Rule.** label, bold number, no citation | D-133 Position log 3993–3994 (as `event_budget`); renamed only in D-181 Rationale log 6363–6364 | U (the name rests on a Rationale) |
| 71 | 5098–5101 | **Why 8.** three or four for a multi-event frame, tens for chattering | **Why 8.** label | D-133 Rationale log 4013–4016 | reason |
| 72 | 5103–5107 | "**When a frame spends its budget**, localization stops for the rest of that frame … A `ChatteringBudget` warning … names the chattering event and the localization count." | bold lead-in | D-018 Position log 632–635; the kind name and its payload: no entry (Appendix C 11855 only) | U; N for the name and payload |
| 73 | 5109–5112 | trajectory-only, pace-independence stands (D-080), replays identically; a `StepError` would misclassify (§14.8) | plain, cites D-080 | D-018 Position log 635–636 ("never a `StepError`") | U |
| 74 | 5114–5121 | "**The same doctrine governs §10.6.** … Localization sheds root-finding precision and preserves every firing … The firing budget sheds firings" | bold sentence, no citation | D-181 Rationale log 6361–6363; Rejected log 6378–6380 | R |
| 75 | 5125–5129 | `localization_tol` and `localization_budget` are `Deployment` constructor keywords beside `h`, `N_base`, the algorithm; validated as a positive tolerance and an integer budget ≥ 1, collected into `DeploymentInvalid` | plain, cites §9.2, Appendix B, C | D-256 Position bullet 5 (keywords); D-133 Position log 3994–3995 (validation) | U |
| 76 | 5129–5132 | `firing_budget` stands beside them: same validation, `DeploymentInvalid`, trace header, replay comparison | plain | D-181 Position ("validated/recorded/replay-compared with its siblings") | U |
| 77 | 5132–5133 | "Both are grid-independent, so neither enters the harmonic-grid check (§10.5)." | plain | D-133 Position log 3995–3996 | U |
| 78 | 5135–5139 | "**Because they determine the trajectory, both are recorded.** They ride the trace header's `Deployment` … replay compares up front" | bold sentence, cites §11.5, §12.7 | D-133 Position log 3996–3998 | U |
| 79 | 5141–5143 | **Why.** otherwise "replays identically" is empty | **Why.** label | D-133 Rationale log 4017–4019; Rejected log 4038–4040 | reason |

D-081 (`t*` is a boundary, not a frame) rules rows 25, 26 and the
whole "What a `t*` boundary does" block, yet its Spec field lists only §10.6
and §12.3 (log 2331), and the chapter cites it nowhere. D-182 (the θ = 0
validation) rules rows 40–48, and its Spec field lists §10.6 and §8.1 but not
§10.4 (log 6393).

Descriptions that read like rules: 4837–4839 (the chain is not a time axis);
4904 "Every `t*` firing precedes tₙ₊₁'s whole boundary sequence" (a
consequence of row 40); 4966–4968 (why boundary firing is correct); 5109–5112
(row 73's reason clauses).

Display-block candidates: `StateEvent(guard, handler)` and the one-line
de-localization rewrite (`σ` → `σ ≥ 0`, 4860–4861), shown as a before/after
pair; the gate form `(gate) ? σ : -one(σ)` with the piston-engine guard
written out (4878–4881); the convergence test `hi − lo < localization_tol`
already sits in the sketch.

Mechanisms and examples: the chain (4834–4835), the sketch (4911–4927), the
three-struts reference case (5099), the even-crossings blind spot.

### §10.5 Multi-rate tick scheduling (5145–5469, 2,648 words)

Purpose: the base grid and the `(D, Φ)` pair every rate compiles to, the gate,
the two sweep variants that deliver ZOH, due sets per kind of boundary, the
declaration surface (`Relative`, `Absolute`, anchors), a worked example, the
doctrine for mid-tree anchors, and how `Δt` reaches a component.

Subheadings (`####`, 13): 5155, 5184, 5215, 5253, 5262, 5281, 5293, 5327,
5353, 5380, 5411, 5440. Most are claims ("Discrete stages run only at their own
ticks", "Simultaneous ticks are already well-defined", "Coincidence and
stagger are modeling choices with observable consequences"). The intro
(5150–5153) promises three things "in that order": the lattice, the due test,
the declaration surface. Labels: **Rule.** 5157, 5186, 5217, 5295, 5329,
5355, 5417, 5442; **Why.** 5190, 5222. Bold lead-ins: 5165, 5170, 5177, 5289,
5340, 5347. Code: one `sample_times` block (5385–5393), one untyped-fence
chart (5399–5404), one table (5300–5303).

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 80 | 5157–5163 | "**Rule.** Every discrete component's period is an integer multiple of a base tick period `Δt_base`. … `N_base` steps per base tick … That is the **harmonic grid**. Ticks therefore land on step boundaries" | **Rule.** label, bold term | D-019 Position (cited); `N_base` per D-234 | C |
| 81 | 5165–5168 | "**Two indices.** … the frame top at `t = k·h` is a base tick exactly when `k` is a multiple of `N_base`. Its **tick index** is then `tick = k ÷ N_base`. A frame top that is no base tick has no tick index, and neither does a `t*` boundary." | bold lead-in | D-147 Position log 4949 ("counter-modulo image of the frame index") | B: U by D-147; N for the `k ÷ N_base` form. `t = k·h` omits `t₀` (part E, F9) |
| 82 | 5170–5175 | "**One pair per component.** … the build compiles it to two integers per discrete component" `D`, `Φ`, canonical residue `0 ≤ Φ < D` | bold lead-in | D-185 Rationale log 6493–6496; D-019 Position says "compiled to absolute divisors" (stale since D-186) | R |
| 83 | 5177–5182 | "**The gate.** A component is **due** at a boundary when `(tick − Φ) % D == 0` … That subtraction and remainder are the whole admission test." | bold lead-in, bold term | D-185 Rationale log 6496; D-185 Rejected log 6519–6525 (materialized due sets) | R |
| 84 | 5186–5188 | "**Rule.** A discrete component's `y_state`/`y_direct` run only at its own ticks. Its cells hold in between." | **Rule.** label | D-019 Position (cited 5191) | C (adjacent) |
| 85 | 5190–5191 | **Why.** re-running would un-sample (D-019) | **Why.** label | D-019 Rejected log 686–687 | reason, C |
| 86 | 5193–5195 | "**two statically distinct sweep variants, compiled from one entry list** … static rather than a runtime test (D-147)" | bold phrase | D-147 Position | C |
| 87 | 5197–5202 | the **interior sweep** walks continuous entries only; RK stages and trial evaluations run it; ZOH mid-step **by construction**; discrete entries absent at compile time | bold terms in bullet | D-147 Position | C (adjacent) |
| 88 | 5203–5207 | the **boundary sweep** walks the full list, gated; the §10.6 macro-sequence runs it; "not one fixed list either" | bold term in bullet | D-147 Position log 4933–4937 | C (adjacent) |
| 89 | 5209–5213 | "The split applies to **both sweep blocks**" (stage 1 and stage 2); interior bodies take no arguments, boundary bodies take the tick index (§9.7) | bold phrase | D-147 Position log 4937–4945 | C (adjacent) |
| 90 | 5217–5220 | "**Rule.** The due set is computed once for the boundary and reused by every re-sweep of its quiescence iteration" | **Rule.** label, no citation | D-147 Position log 4946–4948 | U |
| 91 | 5222–5223 | **Why.** a due component is at its tick instant for the whole boundary | **Why.** label | D-147 Position log 4947–4948 | reason, U |
| 92 | 5227–5229 | tick frame top: every discrete component whose gate admits the tick index | bold term in bullet | D-147 Position; D-185 Rationale (gate) | U |
| 93 | 5230–5232 | off-tick frame top (`N_base > 1`): due set **empty**; the tick counter has not advanced | bold word in bullet | none | N (follows from row 81, which is itself N in part) |
| 94 | 5233–5235 | `t*`: **empty**; a modulo test "would wrongly re-admit the previous tick's due set" | bold word in bullet | D-147 Position log 4949–4952 | U |
| 95 | 5236–5243 | boundary zero: **everything with `Φ = 0`**; "Nothing implements this rule. It falls out of the ordinary gate."; dueness governs `s_update` alone; output stages publish due or not (D-205) | bold phrase in bullet, cites D-205 | Φ = 0: D-185 Rationale log 6499–6501; output stages: D-205 Position. D-147 Position log 4952–4954 still says "everything at boundary zero" | B: R by D-185 for the `Φ = 0` set; C by D-205 for publication |
| 96 | 5245–5247 | an offset component's first tick is at `Φ·Δt_base`; its cells hold its boundary-zero publication; output stages run at `t₀` due or not | plain, cites D-205, §14.5 | D-205 Position | C |
| 97 | 5247–5251 | "The probe's synthesized values (§9.3) reach no published cell. The 'tick at `t₀⁻`' story they once told held only in the build's own world … In a phase-free model every `Φ` is 0" | plain | D-205 Position (no published cell holds probe values); the `t₀⁻` history is D-205 Rationale log 7257–7259 | C for the rule; the history sentence is log material (part G q7) |
| 98 | 5255–5260 | "All due components run their output stages in topological order within the sweep. All due `s_update` calls run after the sweep, in any order. … The FCS cascade's intra-tick ordering is therefore a sweep property" | plain | D-020 Position ("due `g` updates run after quiescence"); "any order": none | B: U by D-020; N for "any order" (a description of §5.3's block structure) |
| 99 | 5264–5268 | coincident ticks give fresh same-instant reads; a phase stagger makes them "pipelined and deterministically aged … with no delay blocks" | plain | none; D-185 adopts `sample_time_proposal.md` as the worked companion (log 6480) | N (modeling doctrine) |
| 100 | 5270–5273 | a stagger is a load-shaping tool under pacing; worst-case frame cost "a `max` rather than a sum" | plain | none | N |
| 101 | 5275–5279 | patterns worked in `sample_time_proposal.md`; the schedule and its chart (§9.2) are how a user audits them | plain | D-187 Position (chart), D-254 | pointer |
| 102 | 5283–5287 | "An assembly is virtual for execution. … There are no atomic assemblies, and no opt-in variant (D-019)." | plain | D-019 Position and Rejected log 673 | C |
| 103 | 5289–5291 | "**Why no coarsening is needed.**" the table makes interleaving invisible | bold lead-in | D-019 Rejected log 673–675 | reason |
| 104 | 5295–5298 | "**Rule.** A discrete component or sub-assembly is scheduled by a `sample_times` entry in its enclosing assembly (§8.7). The entry declares one (period, phase) pair … the wrapper type names the unit system." | **Rule.** label, no D-citation | D-185 Position (cited 5325) | U (the citation is 30 lines on) |
| 105 | 5300–5303 | the two-row table: `Relative(K, Φ = 0)`, `Absolute(q, τ = 0)`, unit systems, instants, constraints | table | D-185 Position log 6483–6486 | U |
| 106 | 5305–5307 | "`K = 1` therefore admits no stagger. Two same-rate siblings are staggered one level down instead." | plain | D-185 Rationale log 6505–6507 | R |
| 107 | 5309–5313 | `q` is `Period(1//50)` or `Hz(50)`, normalized at construction; every period and offset an exact `Rational{Int}`; a float throws the teaching error naming the exact spelling | plain | D-185 Position log 6484–6486; reason D-185 Rejected log 6514–6515 | U |
| 108 | 5315–5318 | "The wrappers are the whole vocabulary. A bare integer or bare quantity is a declaration error. An unlisted discrete child defaults to `Relative(1)`" | plain | D-185 Position log 6487–6488; D-185 Rejected log 6510–6513 | U |
| 109 | 5320–5325 | "**Validation belongs to the structure step** … collected with path attribution … The constructors themselves are plain data carriers (D-185)." | bold phrase | D-185 Position log 6488–6489; the key clause ("keys naming discrete or scope children") none | C; N for the key clause |
| 110 | 5329–5331 | "**Rule.** Multipliers compose multiplicatively and phases affinely down the tree. … `D = K·D_s` and `Φ = Φ_s + φ·D_s`." | **Rule.** label, no citation | multipliers: D-019 Position; phases: D-185 Rationale log 6493–6494 | B: U by D-019; R by D-185 |
| 111 | 5333–5338 | composition preserves the canonical residue; the induction is in the proposal; "All scoping therefore compiles away at build to **one `(D, Φ)` pair per discrete component**" | bold phrase | D-185 Rationale log 6494–6496 | R |
| 112 | 5340–5345 | "**Why relative is the default form.** … **a scope's base rate is its fastest relative member**, and that member gets `K = 1`." | bold lead-in, bold clause | default: D-019 Rejected log 683–685; the convention: none (D-186 Position log 6538 presupposes it) | B: R for the default; N for the convention |
| 113 | 5347–5351 | "**Two structural properties confine grid cost to the other form.** A relative phase … never refines the base grid. And it cannot place a tick *between* scope ticks." | bold sentence | D-185 Rationale log 6505–6506 | R |
| 114 | 5355–5358 | "**Rule.** An `Absolute` entry may appear in any scope's `sample_times` … an **anchor** … The child is severed from the enclosing scope's grid" | **Rule.** label, bold term, no citation | D-186 Position (cited only at 5414) | U |
| 115 | 5360–5368 | the three corollaries: `K ≥ 1` reads relative-to; fastest-member counts relative members only; phase relationships **deployment-emergent**, audited on the `Schedule` (§9.2) | bullets, bold word | D-186 Position log 6536–6540 | U |
| 116 | 5370–5372 | relative children of an anchored subtree compose against the anchor; a nested anchor severs again (the fold, §9.1) | plain | D-186 Rationale log 6554–6556 | R |
| 117 | 5374–5378 | "**Absolute periods and nonzero offsets jointly constrain the base grid.** They join the deployment-time constraint pool (§9.2). … attribution is the engine's job" | bold sentence | D-186 Rationale log 6559–6561 (pool); D-187 Position (diagnostics) | R |
| 118 | 5382–5409 | the worked example, declarations and chart; "that one hyperperiod is the complete truth rather than a sample (§9.2)" | code, chart | D-187 Position log 6591–6593 | mechanism; C via §9.2 |
| 119 | 5413–5415 | "Absolute-first declaration as the default form is rejected (D-019, D-186)." | plain | D-019 Rejected log 683; D-186 Rejected log 6573–6575 | C (both in Rejected lists, which is where a rejection lives) |
| 120 | 5417–5419 | "**Rule.** An absolute declaration inside a library type is legitimate when the rate is **a fact about the modeled system, not a preference about the simulation**." | **Rule.** label, bold clause | D-186 Rationale log 6544–6547 | R |
| 121 | 5421–5424 | GPS at 1 Hz, bus schedule, ADC offset; forcing them to the root breaks encapsulation | plain | D-186 Rationale log 6546–6548 | reason |
| 122 | 5426–5429 | deployment choices keep the exposed-multiplier idiom; "Absolute pinning *from outside* a subtree's contract stays rejected as action at a distance." | plain | D-186 Rationale log 6549; Rejected log 6578–6579 | R |
| 123 | 5431–5432 | "The framework cannot police the distinction. It is authoring doctrine, recorded here." | plain | D-186 Rationale log 6549–6551 | R |
| 124 | 5434–5438 | "**Anchoring leaves the never-cache-`Δt` argument below fully intact.**" | bold sentence | D-186 Rationale log 6551–6553 | R |
| 125 | 5442–5446 | "**Rule.** Each discrete component's effective period arrives read-only as the `Δt` field of every discrete-tier bundle (§5.2) … absent from continuous bundles" | **Rule.** label, no citation | D-019 Position log 661–662 (cited 5455); bundle law D-074 Rationale log 2112–2114 | U |
| 126 | 5448–5451 | "**It must be readable in the *stages*, not just in `s_update`.** The discretized laws … run in `y_direct` … (§5.3, D-015)" | bold sentence | D-019 Rejected log 689 ("discretized laws live in the feedthrough stage"); D-015 cited for computing once | R |
| 127 | 5453–5455 | the value arrives through the call; a `comp.Δt` virtual property "is impossible here … (D-019)" | plain, cites D-019 | D-019 Rejected log 669–672 | C |
| 128 | 5457–5460 | "**Author rule: never store `Δt`, or any `Δt`-derived coefficient, as a component parameter.**" | bold sentence | D-019 Position ("no stored `Δt`-derived parameters"), cited in the paragraph above | C (adjacent) |
| 129 | 5462–5464 | "**Relative declaration structurally enforces that rule for the period itself.**" | bold sentence | none (a consequence of D-019) | N |
| 130 | 5466–5468 | "**Phases change none of this.** The bundle's `Δt` is still `D·Δt_base`." | bold sentence | D-185 Rationale log 6503–6504 | R |

Descriptions that read like rules: 5253–5260 (row 98) restates §5.3's
block structure; 5262–5279 (rows 99–101) is modeling doctrine from the
proposal; 5248–5250 is history. The heading at 5440 ("`Δt` has a single
source of truth: the deployment's `Schedule`") states D-187's ruling (log
6589–6590), but the section under it never says `Schedule`; it rules the
bundle field.

Display-block candidates: the gate `(tick − Φ) % D == 0` (5178), the
composition `D = K·D_s`, `Φ = Φ_s + φ·D_s` (5331), the stagger idiom
`Relative(2, 0)`, `Relative(2, 1)` (5306–5307), the quantity spellings
`Period(1//50)`, `Hz(50)`, `Hz(1//2)` (5309–5313). The existing code block and
chart are already display.

Mechanisms and examples: the due-set list, the two sweep variants, the worked
example, the GPS/bus/ADC examples, the PID and LeadLag examples (5450–5451).

### §10.6 Event iteration at boundaries (5470–5683, 2,047 words)

Purpose: how far the boundary event phase runs and how often each event may
fire; the three registers; what a handler sees within a round; the firing
budget; why ticks stay outside the iteration; the final macro-sequence.

Subheadings: none, at 2,047 words. Bold lead-ins act as headings: 5523,
5536, 5544, 5559, 5566, 5580, 5593, 5604, 5617, 5636, 5651. Label: **Rule.**
5479. One code sketch (5511–5521), one blockquote (5675–5676). The rule
(5479) comes before its motivation, as it should, but "Why iterate"
(5544–5557), the reason for the whole section, arrives only after the
registers, the sketch, the prior update and boundary zero.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 131 | 5472–5477 | the phase iterates; a round re-runs the boundary sweep, evaluates all guards, fires the eligible events "at most one per component"; each firing is `handler → x_projection`; rounds continue to quiescence | plain | D-020 Position; D-154 Position log 5243–5245 | U |
| 132 | 5479–5485 | "**Rule.** An event fires in an iteration round if and only if three conditions hold. … below `firing_budget`. … `firing_budget` is a deployment keyword, an integer ≥ 1 defaulting to **4**." | **Rule.** label, bold number, no citation | D-181 Position log 6346–6351 (cited 5507) | U (the citation closes the next paragraph) |
| 133 | 5487–5497 | "Three registers per event decide the rule, all named normatively": **prior**, **last-observed sample** (initialized from the prior, overwritten each round, except an eligible-but-blocked event), **firing count** | bold terms | D-181 Position ("a last-observed sample initialized from the prior"); the three-register list D-181 Rationale log 6357; the blocked exception D-191 Position | B: U by D-181 and D-191; R for "three registers … named normatively" |
| 134 | 5499–5507 | eligibility inside a boundary is an edge against the last-observed sample; sticky predicates fire once; a genuinely re-enabled predicate fires again "against a fresh sweep (D-181)" | plain, cites D-181 | D-181 Position | C |
| 135 | 5509–5521 | the iteration sketch | code | D-191 Rationale log 6710–6711 (the restored sketch's corrected line) | mechanism |
| 136 | 5523–5527 | "**The prior is updated at each boundary's quiescence, from the final post-iteration samples.** The update is unconditional." | bold sentence, no citation | D-082 Position log 2357 ("updated at quiescence"); D-181 Rationale log 6355 ("priors are always honest") | U |
| 137 | 5529–5534 | the registers are detection bookkeeping, absent from state stores, not traced, reconstructed deterministically; a checkpoint carries the prior (§12.6, D-274); cost one `Bool` and one counter per event | plain, cites D-274 | D-082 Position log 2357–2359; D-274 Position bullet 1 log 11098–11099 | U by D-082; C by D-274; N for the cost line |
| 138 | 5536–5542 | "**Boundary zero sets every prior to not-holding.** … A re-run from a condition resets all three registers … A `restore!` keeps the checkpoint's priors and runs no boundary zero" | bold sentence, no D-citation | D-082 Rationale log 2363–2364; `restore!` D-274 Position bullet 3 log 11109–11112 | B: R by D-082 for boundary zero; U by D-274 for `restore!` |
| 139 | 5544–5552 | "**Why iterate.**" single-pass cascade latency `N·h`; §2.2's `f_step!` footgun; §3.1's externalized FSMs; hybrid automata, Modelica, Stateflow | bold lead-in | D-020 Rejected log 706–708 | reason |
| 140 | 5554–5557 | boundary-detection timing stays `h`-dependent, but that is a different quantity | plain | none | reason, N |
| 141 | 5559–5564 | "**Why a full re-sweep per round.**" a handler writes only state stores; "A round therefore re-runs the whole boundary sweep, gated entries included." | bold lead-in | D-020 Position ("rounds of full re-sweep") | U |
| 142 | 5566–5569 | "**Within a round, the signal table has a single writer, and it is the sweep.**" | bold sentence, no citation | D-154 Position log 5243–5244 | U |
| 143 | 5571–5578 | "This gives the epoch rule … **A handler executes against exactly the world its guard fired on.** … no bundle … ever straddles two epochs. Serialization is what delivers this." | bold sentence, no citation; "epoch rule" links `#g-input-epoch` | D-154 Position log 5249–5251 | U; the glossary link is wrong (part E, F4; part G q4) |
| 144 | 5580–5591 | "**A component's other eligible events are blocked, not lost.** Each is re-decided in the next round … Blocking is visible in the registers (D-191)." | bold sentence, cites D-191 | re-decision: D-154 Position log 5253–5254; the register exception: D-191 Position | B: U by D-154; C by D-191 |
| 145 | 5593–5602 | "**Across components, handler order within a round is semantically unobservable.** … Execution order is fixed all the same, as executor component order and then declaration order … The natural single-pass executor is therefore exactly correct … allocates nothing." | bold sentence, no citation | unobservable: D-154 Position log 5254–5255; fixed order: D-100 Rationale log 2879–2881; the executor: D-154 Rationale log 5263–5265 | B: U by D-154; R for the order and the executor |
| 146 | 5604–5609 | "**The trade, stated openly, is that a handler cannot opt into seeing a same-round foreign transition.** … the position of the synchronous languages" | bold sentence, no citation | D-100 Rejected log 2891–2893 (an entry whose mechanism D-154 superseded, unannotated) | R |
| 147 | 5610–5612 | serializing same-component firings costs one extra intra-boundary sweep per event | plain | D-154 Rationale log 5265–5266 | R |
| 148 | 5612–5615 | "D-154 records the rejected shapes. They are the per-event re-decode with a frozen round-start `u` (D-016, D-100, D-152), live-table reads …, a table copy per firing round (D-100), and handlers stripped of their own `y`." | plain | D-154 Rejected log 5268–5281 holds all four | adversarial; S for D-152 (superseded → D-154); D-016 and D-100 superseded in part, unannotated |
| 149 | 5617–5620 | "**Why a per-event budget.** … The deferral design and the per-round cap are both rejected (D-020, D-181)." | bold lead-in | D-181 Rejected log 6367–6370; D-020 Rejected log 709 | reason, C |
| 150 | 5622–5628 | termination budget-bounded: at most `firing_budget · E` firings; a livelock spends its budget and warns; "degradation, not an error, per the doctrine of §10.4" | plain | D-181 Rationale log 6358–6361 | R |
| 151 | 5630–5634 | "This trade is also stated openly. … the arbitrary-K objection lives on in `firing_budget`. … no manufactured prior, no re-arm flag, no `EventDeferred` warning …" | plain | D-020 Rejected log 709 (the arbitrary-K objection); D-181 Rationale log 6355–6357 (retirements) | R; the retirement list is adversarial (part G q3) |
| 152 | 5636–5643 | "**Budget exhaustion degrades; it does not throw.** … further edges there are lost … A lost edge emits a `FiringBudget` warning … at most once per event per boundary. … The warning carries the component path, the event name, the boundary time and the exhausted budget beside the boundary's firing count." | bold sentence, cites §13.2, Appendix C | D-181 Rationale log 6358–6360; "at most once" and the payload: none | R; N for the rate and the payload |
| 153 | 5645–5649 | "The default of **4** is chosen the way §10.4 chooses 8." | bold number | the default: D-181 Position; the reason: none (it is `src/deployment.jl` 305–308's docstring) | U for the default; N for the reason |
| 154 | 5651–5652 | "**Ticks stay outside the iteration, after quiescence.**" | bold sentence, no citation | D-020 Position log 698–699 | U |
| 155 | 5654–5663 | events → ticks: due output stages refresh every round against the boundary's fixed due set; `s_update` not yet run; tentative values are scratch; "External readers observe the table only after the boundary sequence completes" | italic lead, plain | D-147 Position log 4946–4948; D-020 Position | U |
| 156 | 5664–5670 | ticks → events "structurally impossible"; `s⁺` invisible until the owner's next tick; the one-sample `z⁻¹` delay; no combined fixed point | italic lead, plain | D-020 Rejected log 711–712 | R |
| 157 | 5672–5676 | the macro-sequence "in its final form"; boundary zero is the same with an empty integrate (§14.5) | plain, blockquote | D-020 Position; D-067 Position | U |
| 158 | 5678–5682 | the mixed case: an engine's `starting → running` under a 50 Hz FCS | plain | none | example (consequence of row 157) |

Descriptions that read like rules: 5529–5534's cost line; 5554–5557; 5599–5602
(the executor's properties, row 145); 5672–5676 is the sequence's statement
but repeats §5.3 940 (part B).

Display-block candidates: none beyond the existing sketch and blockquote. The
blockquote omits the frame-top drain and the publication that §11.1's frame
definition (5827) lists, which is right for a boundary but worth one clause.

Mechanisms and examples: the sketch, the supervisor-FSM cascade, the toggling
FSM pair, the engine/FCS mixed case.

### §10.7 Real-time pacing (5684–5790, 989 words)

Purpose: the pacing invariant, the wall-clock map, the deadline law and debt,
`p = ∞`, the sleep-then-spin wait and its `margin`, where the wait sits, and
the published diagnostics.

Subheadings: none. Bold lead-ins act as headings: 5686, 5697, 5707, 5718,
5722, 5766, 5772, 5786. One code block (5733–5739). Already free of
**Rule.**/**Why.** labels; most paragraphs open with a bold claim.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 159 | 5686–5691 | "**Pacing is outside the semantics.** … It never reorders, skips or alters the boundary sequence. A paced and an unpaced run with identical input traces produce bit-identical trajectories" | bold sentence, cites §2.2 | D-021 Position (cited first at 5701) | U |
| 160 | 5691–5695 | detection policy is inside the semantics; localization runs identically paced or unpaced, its cost absorbed as debt; degrading was rejected (D-080) | plain, cites §10.4, D-080 | D-080 Position and Rejected | C |
| 161 | 5697–5701 | "**The wall-clock map is piecewise affine, re-anchored at every knee.**" τ(t); a live pace change re-anchors forward (D-021) | bold sentence | D-021 Position | C |
| 162 | 5701–5703 | "Un-pause re-anchors for the same reason. Debt is cleared at re-anchor. … the counters record what was forgiven." | plain | D-021 Position ("debt cleared, counted") | C (adjacent) |
| 163 | 5703–5705 | "The frame that follows an anchor has no wait … The run's first anchor is taken when its loop starts" (D-269) | plain | D-269 Position bullet 4 | C |
| 164 | 5707–5711 | "**Deadline law: an absolute schedule with bounded debt** (D-021)." frames that overrun leave debt; later frames repay | bold phrase | D-021 Position | C |
| 165 | 5711–5716 | debt beyond "**five frames' worth of budget, `5·h/p`**" is forgiven by re-anchor plus a warning; the reason | bold phrase, no citation for the threshold | D-133 Position log 4000–4001; reason D-133 Rationale log 4022–4024 | U |
| 166 | 5718–5720 | "**`p = ∞` is pacer-off, not a limit value** (D-021)." no waits, no debt, no warnings | bold phrase | D-021 Position; D-021 Rejected log 734–735 | C |
| 167 | 5722–5731 | "**The wait mechanism is a hybrid sleep-then-spin with one knob.**" OS sleep is lower-bound only; measured overshoots (2026-07) | bold sentence, no citation | D-021 Position; measurements D-133 Rationale log 4026–4028, D-269 Rationale log 10750–10751 | U; measurements exempt as evidence |
| 168 | 5733–5739 | the wait loop; `GC.safepoint()` "a safepoint, never a yield" | code | D-269 annotation log 10775–10778; D-027 Position ("spin never yields") | R for the safepoint |
| 169 | 5741–5744 | `margin` "is a single constant … There is no second threshold." | plain | D-021 Position; D-021 Rejected log 737–738 | U |
| 170 | 5744–5747 | "**Its default is 2 ms**", with the reason | bold phrase, no citation | D-133 Position log 4001–4002; reason D-133 Rationale log 4026–4029 | U |
| 171 | 5750–5757 | `margin = 0` pure sleep; `2 ms` the hybrid; `∞` pure busy-wait, "FlightCore's behavior … the knob's endpoint, not a separate mechanism" | bold leads in bullets | D-021 Position log 722–723; D-021 Rejected log 736 | U |
| 172 | 5759–5761 | budget ≤ margin degenerates to pure spin; late wake-ups are overruns absorbed as debt | plain | none | N (consequence) |
| 173 | 5762–5764 | "Which primitive the coarse phase uses … is settled in §12.2. The coarse phase uses task-yielding `sleep`" | plain | D-027 Position | U; §12.2 is the home (part B) |
| 174 | 5766–5770 | "**The wait sits at the frame top, after the control plane is consulted.** … at most one frame budget `h/p` later (§12.1, D-269). The wait is an unmask point for the operator interrupt (§12.4)" | bold sentence | D-269 Position bullet 3; unmask point D-132 Rationale log 3936–3939 | C; R for the unmask point |
| 175 | 5772–5780 | "**Diagnostics.**" the framework-status record and its fields (D-269) | bold lead-in | D-269 Position bullet 6 | C |
| 176 | 5780–5782 | a deliberate re-anchor is counted and raises no warning; the forgiveness re-anchor reports `DebtReanchor` | plain | D-021 Position ("counted"); D-269 Position bullet 6 | C (adjacent) |
| 177 | 5782–5784 | "A live switch to `p = ∞` is a pace change like any other: it re-anchors, and the debt it clears is counted as forgiven (D-269)." | plain, cites D-269 | D-269 annotation log 10769–10772 | R |
| 178 | 5786–5789 | "**Forward pointers.** The wait interval is the natural staging slot for externally injected inputs, applied at the next boundary." | bold lead-in | none | N; "next boundary" should be the next frame top's drain (part E, F11) |

Display-block candidates: the map τ(t) is already a display formula inline;
the budget `h/p` and threshold `5·h/p` stay inline. The code block stays.

Mechanisms and examples: the measurements, the 20 ms budget illustration
(5753–5754), the degenerate `h = 0.01`, `p = 5` case (5759–5760).

### Tally

| section | rules | C | U | S | R | N | B |
|---|---|---|---|---|---|---|---|
| §10.1 | 3 | 2 | 0 | 0 | 0 | 0 | 1 |
| §10.2 | 17 | 3 | 8 | 0 | 0 | 4 | 2 |
| §10.3 | 3 | 0 | 2 | 0 | 1 | 0 | 0 |
| §10.4 | 44 | 7 | 20 | 0 | 13 | 2 | 2 |
| §10.5 | 45 | 13 | 10 | 0 | 13 | 4 | 5 |
| §10.6 | 22 | 1 | 11 | 0 | 6 | 0 | 4 |
| §10.7 | 20 | 9 | 7 | 0 | 2 | 2 | 0 |
| total | 154 | 35 | 58 | 0 | 35 | 12 | 14 |

The count leaves out the 24 rows that are reasons, mechanisms, examples,
pointers or code (3, 27, 31, 34, 35, 37, 42, 46, 59, 68, 71, 79, 85, 91, 101,
103, 118, 121, 135, 139, 140, 148, 149, 158), and classes each row by its
first code. The one superseded citation, D-152 at 5613, sits in row 148, a
list of rejected shapes rather than a rule.

Against chapter 9 (C 59, U 58, S 1, R 22, N 3, B 13 of 156): about one rule
in four lives only in a Rationale, Rejected list or annotation (35), against
one in seven there, and fewer than one in four is cited where it stands. The R
rows cluster in five entries whose Rationale carries most of a block: D-082
(endpoint policy, grid integrity), D-182 (the θ = 0 validation), D-081 (the
`t*` boundary), D-185 and D-186 (composition, anchors, doctrine). Bold weight now: 141 bold spans, of which 29 are
**Rule.**/**Why.**/**Why 8.**/**Consequence.** labels; the other 112 carry
568 words. Many of those are bold terms (frame, boundary, prior, harmonic
grid) and lead-ins acting as headings, neither of which the convention allows.

## B. Overlaps

### Inside the chapter

1. **Frame and boundary.** Used from 4695 (§10.1, "completed frames", "the
   boundary sequence") and through §10.2, §10.3 and §10.5; defined only at
   §10.4 4818–4829. §10.5 5165–5168 defines the frame index again, and 5047
   restates `tₖ = t₀ + k·h`. One definition should open the chapter (part C,
   M1; part G q1).
2. **Trial evaluations run the interior sweep.** §10.4 4902–4903 (stated as
   "the rule … below"), §10.4 4979–4985 (the rule), §10.4 5084–5085 (RK stages
   equally off-manifold), §10.5 5197–5199 (the interior variant serves both).
   §10.5 owns the variant (D-147); §10.4 4979–4985 owns its consequence for
   guards. 4902–4903 is a forward reference that a reorder removes (part C).
3. **`localization_tol` as a keyword.** §10.4 4992–4995 and 5125–5129, plus
   §9.2 3753–3767 (the validation list and grid-independence, verbatim in
   substance) and Appendix B 11165–11166. §9.2 is the home for validation;
   §10.4's convergence paragraph is the home for the test and its default.
   5125–5133 restates both (part G q5).
4. **The two budgets compared.** §10.4 5114–5121 compares
   `localization_budget` with `firing_budget` before §10.6 defines the second;
   §10.6 5627 ("per the doctrine of §10.4") and 5645 ("chosen the way §10.4
   chooses 8") point back. Home: §10.6, after 5636–5649 (part C, M4).
5. **What external readers see.** §10.3 4806–4808 (only at step boundaries)
   and §10.6 5661–5663 (only after the boundary sequence completes). The second
   is the full rule. Home: §10.3 (part C, M2).
6. **No ticks at `t*`.** §10.4 5062–5064 and §10.5 5233–5235. §10.5 has the
   reason (the unadvanced index); §10.4 keeps one sentence and a pointer.
7. **The prior.** Introduced at §10.4 4893–4894 (trigger), defined again at
   §10.6 5489–5490 and 5523–5527. §10.6 is the home (the registers); §10.4
   glosses it and points forward, which is define-before-use done right.
8. **Degrade, don't throw.** §10.4 5092–5112 and §10.6 5622–5649 state the
   same doctrine for two budgets, each with its default's reasoning. Both
   stay; item 4 is the only duplicated text.
9. **The interpolant.** §10.2 4726–4727 (dense output, lazy), §10.4 4931–4933
   (gloss), 4970–4977 (rule). The gloss sits before the rule in the same
   section; a reorder puts the rule first.
10. **The θ = 0 discriminator's premise.** §10.4 4945–4951 ("under the honest
    priors of §10.6") and §10.6 5523–5527 ("That is what makes the θ = 0
    discriminator (§10.4) conclusive"). Two halves of one argument, each
    pointing at the other. Both stay, as cross-references.
11. **Stagger.** §10.5 5262–5279 (doctrine), 5305–5307 (`K = 1` admits none),
    5347–5351 (relative phases stay on the scope grid), 5406–5409 (the
    example's aging). The doctrine block precedes the forms it talks about.
12. **Boundary zero.** §10.5 5236–5251 (due set, publication), §10.6
    5536–5542 (priors), 5672–5673 (empty integrate). Distinct facts, each
    pointing to §14.5; no duplicated text.

### Other chapters

| content | chapter 10 | elsewhere | home |
|---|---|---|---|
| the boundary sequence and its iteration blockquote | §10.6 5672–5676 | §5.3 933–940, the same blockquote | §5.3 for the sequence, §10.6 for the iteration (D-154 lists both). §10.6's "final form" adds `s_update` and logging, which §5.3 omits |
| the epoch rule, "a handler executes against exactly the world its guard fired on" | §10.6 5571–5578 | §5.3 947–949 as **Rule.**, same wording, same wrong glossary link | §10.6 (D-154); §5.3 should point. Chapter 5's rewrite, not this one |
| one event per component per round, re-decision across rounds | §10.6 5580–5591 | §5.3 951–957 | §10.6 |
| output stages topological, `s_update` after the sweep | §10.5 5255–5260 | §5.3 892–895 | §5.3 |
| `sample_times` forms, wrappers the whole vocabulary, `Relative(1)` default, composition | §10.5 5293–5338 | §8.7 3181–3192, near-verbatim | §10.5 for the forms and their validation; §8.7 for the key rules (immediate children, containers, type not instance) |
| deployment validation of the event parameters, grid-independence | §10.4 5125–5133 | §9.2 3753–3767 | §9.2 |
| the worked example | §10.5 5380–5409 | §9.2 3777–3795 binds it ("The model worked in §10.5") | §10.5 for declarations and chart; §9.2 for the binding table, as chapter 9's survey ruled |
| one hyperperiod is the complete truth | §10.5 5395–5397 | §9.2 3818 | §9.2 (D-187, the chart's home) |
| interior and boundary arities | §10.5 5212–5213 | §9.7 4462–4470 | §9.7 |
| the frame as the unit of account | §10.4 4820–4823 | §11.1 5826–5830; glossary 12177 ("one iteration of the loop") | one definition in chapter 10 (part G q1); §11.1 and the glossary agree with it |
| the trace header records the event parameters; replay compares them | §10.4 5135–5139 | §11.5, §12.7 8517 | §11.5 and §12.7; §10.4 keeps the reason |
| the control plane consulted at frame top, `h/p` latency | §10.7 5766–5768 | §12.1 7428–7431 | §12.1 (D-269 lists both) |
| the coarse phase uses `sleep` | §10.7 5762–5764 | §12.2 7507–7508 as **Rule.** | §12.2; §12.2 7500–7502 says §10.7 "left the coarse phase's primitive open", which §10.7 5763–5764 no longer does (part E, F12) |
| replay pointer and ordinal | §10.4 5073–5076 | §13.4; §12.3 7598; §12.7 8386–8394 | §13.4 and §12.3 |
| boundary zero's due set and priors | §10.5 5236–5251; §10.6 5536–5542 | §14.5 9923ff | §14.5 for boundary zero; chapter 10 for dueness and priors |
| `FiringBudget`, `ChatteringBudget`, `DebtReanchor` payloads | §10.6 5639–5643; §10.4 5106–5107; §10.7 5782 | Appendix C 11855, 11858; §13.2 | Appendix C for the payloads; chapter 10 for when each is raised |
| zero allocation of the stepper | §10.2 4754–4755 | §7.5 1834ff | §7.5 |
| directional edges, the predicate | §10.4 4896; §10.6 5483 | §2.1 | §2.1 |

## C. Proposed structure

No section is renumbered and none is retitled. A renumbering inside the
chapter would cost far more than it buys: 328 citations point at chapter 10
(part D), §10.4 70 of them, §10.5 87, §10.6 76, §10.7 56. No file links a
`####` anchor of chapter 10 (checked with `rg` over `docs/`), so retitling
subheadings is free, and several claim-headings should become topic labels
(`spec_style.md`, "Subheadings only for entry points").

### Moves

| move | content | from | to | needs a ruling |
|---|---|---|---|---|
| M1 | the definitions of *frame* and *boundary* | §10.4 4818–4829 (109 words) | §10.1, as the loop's two units; §10.4 keeps one sentence that `t*` is a boundary but no frame top | yes, part G q1 |
| M2 | "§10.3 extends naturally. External readers observe the table only after the boundary sequence completes." | §10.6 5662–5663 (25 words) | §10.3, as the rule's full statement; §10.6 keeps "Earlier rounds' tentative values are internal scratch" and a pointer | no |
| M3 | the reason no tick is due at `t*` | §10.4 5062–5064 | stays; one sentence and a pointer to §10.5 5233–5235, which has the reason | no (a trim, not a move) |
| M4 | the comparison of the two budgets | §10.4 5114–5121 (74 words) | §10.6, after 5636–5649, where `firing_budget` is defined | no |
| M5 | the deployment-constants block's validation details | §10.4 5125–5132 | trimmed to the ownership sentence and a pointer to §9.2 3753–3767; 5132–5133 (grid-independence) and 5135–5143 (recording) stay | yes, part G q5 |
| M6 | the list of rejected shapes | §10.6 5612–5615 | deleted, one pointer to D-154 kept; D-154 Rejected (log 5268–5281) holds all four | yes, part G q3 |
| M7 | "Coincidence and stagger …" | §10.5 5262–5279 (136 words) | after the worked example, absorbing its last sentence (5406–5409, "the deterministic aging of a stagger") | no |
| M8 | "Where the doctrinal line falls on mid-tree anchors" | §10.5 5411–5438 | up, directly after the `Absolute` block (5353–5378), before the example | no |
| M9 | "Why iterate" and the `h`-dependence paragraph | §10.6 5544–5557 | up, directly after the rule (5479–5485) | no |
| M10 | "Trial evaluations run the interior sweep" | §10.4 4979–4985 | up, before "The trigger" (4889), so the trigger's "(below)" (4902) becomes a backward reference | no |
| M11 | the domain argument's Flight.jl evidence | §10.2 4775–4796 | per part G q2; nothing moves without that ruling | yes |

M1, M2, M4 and M7 cross unit boundaries (see "Rewrite units" below); each
moved block belongs to its destination unit, so every move stays inside one
unit.

### Order within each section

Define-before-use was checked for each order below against the terms each
block uses.

- **Chapter intro (new, part G q1).** One context paragraph: chapter 10 owns
  time, between and at boundaries, assuming the execution order (§5.3) and the
  executor (§9.7). One roadmap sentence naming §10.1–§10.7.
- **§10.1.** Context: the loop's activities (4693–4696). The two units (M1):
  a frame is one grid step and one iteration of the loop, the unit the drain,
  pacer deadlines and tick eligibility key to; a boundary is a published
  consistency point, every grid point being one, plus `t*` (a pointer to
  §10.4) and boundary zero (a pointer to §14.5). Rule: the framework writes
  the loop (D-017). Reason: the constructive half of 4702–4704. Consequence:
  `OrdinaryDiffEq` is dropped, stated as a rule, not after "therefore". `t*` is
  first used here; it takes a gloss ("the localized event time, §10.4").
- **§10.2.** Unchanged order: what the seam requires, the empty state, the
  backends and the keyword, the domain argument (or its pointer, part G q2).
  "What the seam requires of a backend" is already a topic label.
- **§10.3.** Context (RK stages run the interior sweep, glossed with a
  pointer to §10.5). Rule: readers observe the table only after the boundary
  sequence completes; mid-step and mid-boundary contents carry no meaning;
  the periphery is bound (M2).
- **§10.4.** Context (two treatments of a mid-step crossing), the `t*`
  sentence left by M1, the one-frame chain. Then `####` topic labels in this
  order: "Detection policy" (form is the policy, the one-line rewrite,
  exactness over `u` and `m`, the gate idiom: today three subheadings, which
  can stay three); "Trial evaluations" (M10, with "Projection's reach" kept in
  its place or joined here, the rewriter's choice); "The trigger"; "The
  localization loop" (the sketch, then the θ = 0 validation, the input epoch,
  the discriminator, the epoch-caused discard, the interpolant, root-finding,
  convergence, post-event, multiple events, the blind spot, each a paragraph,
  in that order, which is today's less M10); "Endpoint policy and grid
  integrity"; "The `t*` boundary"; "The localization budget"; "Deployment
  constants". The sketch uses θ, σ(θ) and "trial evaluation" and defines them
  in its first comment, so it may precede the prose it previews. The
  **Consequence.** label (5022) becomes a plain sentence after its rule.
- **§10.5.** Context (5147–5153), which promises lattice, test, surface "in
  that order", and the order keeps the promise. `####` labels: "The base grid
  and the gate" (5155–5182); "Zero-order hold and the two sweep variants"
  (5184–5213); "Due sets" (5215–5251); "Simultaneous ticks" (5253–5260);
  "Assemblies and rate scopes" (5281–5291); "The two declaration forms"
  (5293–5325); "Relative composition" (5327–5351); "Anchors" (5353–5378);
  "When an anchor belongs in a library type" (M8); "A worked example"
  (5380–5405); "Coincidence and stagger" (M7, with 5406–5409); "`Δt` in the
  bundle" (5440–5468). "Stagger" is used at 5305 and 5347–5351 before its
  block; both uses are self-explaining ("staggered one level down"), so the
  move costs nothing in define-before-use.
- **§10.6.** Context (5472–5477), the rule (5479–5485), then `####` labels:
  "Why the phase iterates" (M9); "The three registers" (5487–5542: registers,
  edge reading, sketch, prior update, bookkeeping, boundary zero and
  `restore!`); "What a handler sees within a round" (5559–5615: full re-sweep,
  single writer, the epoch rule, blocking, cross-component order, the trade);
  "The firing budget" (5617–5649, then M4); "Ticks after quiescence"
  (5651–5682: the two couplings, the macro-sequence, the mixed case). The
  sketch mentions a blocked edge before blocking is explained; the register
  bullet at 5493–5495 already says "(below)", which is enough.
- **§10.7.** Unchanged order. Three `####` labels would serve a returning
  reader: "The invariant and the wall-clock map" (5686–5720), "The wait"
  (5722–5770), "Diagnostics" (5772–5789). Optional at 989 words.

### Rewrite units

| unit | lines (original) | moves in | moves out | words |
|---|---|---|---|---|
| A | 4689–4809: heading, §10.1, §10.2, §10.3 | M1 (4818–4829), M2 (5662–5663) | — | 1,025, plus the new intro |
| B1 | 4810–5016: §10.4 to the end of "The localization loop" | — | M1 | 1,654 |
| B2 | 5017–5144: §10.4 from "Endpoint policy" | — | M4 | 957 |
| C1 | 5145–5292: §10.5, lattice to assemblies | — | M7 | 1,099 |
| C2 | 5293–5469: §10.5, declaration surface to `Δt` | M7 (5262–5279) | — | 1,549 |
| D | 5470–5683: §10.6 | M4 (5114–5121) | M2 | 2,096 |
| E | 5684–5790: §10.7 | — | — | 988 |

Total 9,368 words (the 9,369 less the closing `---`). D is just over the
2,000 target. It can split at 5558 into D1 (5470–5557, 820 words: the rule,
the registers, why iterate) and D2 (5559–5683 with M4, 1,276 words: within a
round, the budget, ticks), but the registers, blocking and the budget
cross-refer throughout, and M9 then crosses the split. Keeping D whole is
recommended. B1 and B2 split §10.4 where the loop ends and its consequences
begin; the only cross-reference between them is the endpoint argument's use of
the θ = 0 validation (5025–5033), a backward pointer.

### Code blocks

The chapter is less code-heavy than its length suggests: five fenced blocks
(4911–4927, 5385–5393, 5399–5404, 5511–5521, 5733–5739), two blockquoted
chains (4834–4835, 5675–5676), one table (5300–5303), and inline math.

- **Carry every block verbatim**, each as one claim. `checks/norm.py` folds a
  ```` ```julia ```` block into one code span, so a one-character edit makes
  the whole block differ in the code-span count. The chart at 5399–5404 is an
  untyped fence: `norm.py` leaves it as prose, so each of its numbers and
  bullets must be covered by the claim's span. Comment edits inside a block
  are ruled edits only.
- **Inline math stays as written**: `$…$` passes `norm.py` as text, and the
  verifier compares it literally.
- **New display blocks** are the candidates in part A (the gate, the gate
  idiom, the one-line de-localization, the composition formulas, the quantity
  spellings). Each is an addition the inventory declares; inline `code` turned
  into a display block shows in the code-span count and is expected.

## D. Inbound citations

The full list is `inbound.tsv` (beside this file), in chapter 9's format:
328 rows, one per "§10" or "§10.N" occurrence outside chapter 10 (4689–5792)
and outside the Contents block; for `decisions.md` rows the `entry` and
`field` columns are filled. Links to chapter 10's anchors occur only in the
link-definition blocks that `linkify.jl` regenerates, which are excluded. A
range counts its two ends only: `implementation.md` 237 ("§10.4–§10.6") and
494 ("§10.2–§10.7") also cover the sections between, which no row records.
The script is `scratch_survey/inbound.py`.

By file: `spec.md` 146, `decisions.md` 108 (Spec 55, Rejected 22, Rationale
17, Position 13, Annotation 1), `implementation.md` 18,
`sample_time_proposal.md` 17, `frame_walkthrough.md` 14, `extensions.md` 12,
`localization_validation_walkthrough.md` 5, `event_visibility_walkthrough.md`
4, `frozen_discrete_walkthrough.md` 2, `flight_case_studies.md` 1, `pending.md`
1. By target: §10 6, §10.1 6, §10.2 16, §10.3 11, §10.4 70, §10.5 87, §10.6
76, §10.7 56.

### Citations relying on moved content

M1, frame and boundary (§10.4 → §10.1):

| file:line | fact relied on | after |
|---|---|---|
| spec 5827 (§11.1) | the frame is "the grid step §10.4 names" | §10.1 |
| spec 7598 (§12.3) | published boundaries are grid, `t*` and boundary zero (§10.4) | §10.1 |
| spec 12210 (glossary, boundary) | `t*` and boundary zero are boundaries that are not frame tops (§10.4) | §10.1 |
| log 2331 (D-081 Spec) | lists §10.6 and §12.3 only, though D-081's content is §10.4's | add §10.1 (landing) and §10.4 (track 2) |

Unaffected though nearby: spec 9127 (§13.5) cites §10.4 for `t*` itself,
which stays; spec 8393 (§12.7) and log 3802 (D-128) rely on 5073–5076, the
counter versus frame-ordinal separation, which stays in §10.4.

M2, the full reader rule (§10.6 → §10.3):

| file:line | fact relied on | after |
|---|---|---|
| spec 5945 (§11.2) | "Publication happens only after the boundary sequence completes (§10.3 as extended by §10.6)" | §10.3 alone; the old pair stays true, so the edit is optional |

M4, the budget comparison (§10.4 → §10.6): no inbound row relies on
5114–5121. spec 8787–8789 (§13.2) cite §10.4 and §10.6 for the two
exhaustions, which stay where they are.

M5, the deployment-constants trim: spec 3765 (§9.2) cites §10.4 and §10.6
for grid-independence, so 5132–5133 must stay in §10.4 (part C keeps it).
spec 7767 (§12.4) relies on "the disposition §10.4 gives its own two
constants", deployment rather than implementation; that claim lives in the
heading at 5123 and in 5125. If the heading becomes a topic label, the claim
must survive as a sentence.

M6 to M10 move nothing an inbound row names.

M11 (only if part G q2 moves the domain argument out): no inbound row relies
on 4770–4796. spec 10269 (§14.8) and log 1985 (D-070) cite "the §10.2 stepper
precedent", which is 4752–4757 and 4766–4768, a tiny in-house core against a
heavy dependency; that stays.

### Citations that already rely on content chapter 10 does not hold

The inbound check will flag these as VAGUE or MISSING whatever the rewrite
does; they belong to track 2 or to the other chapter's rewrite.

| file:line | claim | what chapter 10 says |
|---|---|---|
| spec 4063 (§9.4) | "event localization runs as `Float64` sweeps by design (§10.4)" | §10.4 says nothing of the scalar type |
| log 2125 (D-074 Rejected), log 2500 (D-086 Rejected) | "the §10.1 `task_local_storage` lesson" | §10.1 has no such lesson; it is D-017's Rejected dossier (log 611–621) |
| log 5324 (D-156 Position) | "completing §10.1's removal of the dummy-`[0.0]` tax" | the tax is §10.2 4743–4748 |
| log 3426 (D-116 Rejected), log 11854 (D-288 Rejected) | "§10.3's publication-after-every-boundary property" | §10.3 rules what readers may observe, not that every boundary publishes; that is §11.2 and D-081 |
| log 2333 (D-081 Rationale) | at `t*` the §10.6 iteration runs "with once-per-event scoped per boundary" | §10.6 has `firing_budget` (D-181) |
| log 3991, 3996, 4018 (D-133) | `Simulation` keywords beside `h`, `n`; `event_budget` | `Deployment` keywords (D-256), `N_base` (D-234), `localization_budget` (D-181) |
| implementation.md 499–505 | `checkpoint_stepper`/`restore_stepper!`, the hook pair, under "Spec: §10.2" | §10.2 has no checkpoint hook (part E, F1) |
| `frame_walkthrough.md` 79–81, 218 | the seam is crossed by `step!(sim, h′)` to `step!(::RK4, sim, h)` | `src/` calls both `integrate!` since `4eb2d5a` (part E, F2) |

### Log entries whose Spec field would change

- Under M1: D-081 gains §10.1 (and §10.4, which it already lacks).
- Under M2: D-023 and D-147 already list §10.3; nothing changes.
- Under M4: D-181 already lists §10.4 and §10.6; nothing changes.
- Under M11, if the argument leaves the spec: no entry carries it, so no Spec
  field changes; the companion would be its only home.

The recipe updates the Spec fields a move changes at landing (step 7, item
3). D-081's field is stale before any move, so its repair is track 2 either
way; under M1 the two edits coincide.

## E. Log repairs and factual problems

Log repairs go to the second track, after landing (recipe step 8). The
rewrite only adds citations; it states no repair. Factual problems stay as
written and go to the units' `rulings.md`, unless part G pre-rules them.

### Entries to cite at the rule

From part A's U rows: D-017 (rows 5–8, 13, 18), D-156 (10, 11), D-227 and
D-256 (16, 52, 75), D-019 (19, 125), D-147 (22, 23, 50, 64, 81, 90–94, 155),
D-081 (25, 26; cited nowhere in the chapter today), D-179 (32), D-082 (38, 39,
136, 137), D-182 (40, 41, 43, 44), D-018 (49, 54, 72, 73), D-128 and D-230
(66), D-133 (70, 77, 78, 165, 170), D-181 (63, 76, 132, 133), D-154 (55, 131,
142–145), D-185 (104, 105, 107, 108), D-186 (114, 115), D-020 (131, 141, 154,
157), D-067 (157), D-274 (138), D-191 (133), D-021 (159, 167, 169, 171),
D-027 (173).

### Superseded and half-superseded citations

- 5613 cites D-152 (superseded → D-154) in the list of rejected shapes. The
  same sentence cites D-016 and D-100, whose mechanisms D-154 superseded
  (log 5261–5263) and whose status still reads "ratified". The list is
  history, so the citations are correct as history; M6 removes them with the
  list.
- No other superseded citation in the chapter.

### Rulings that need an entry stating them in a Position

1. Exact boundary detection over `u` and `m`, and the gate idiom (rows 33, 36):
   D-179 Rationale log 6301–6304.
2. The θ = 0 discriminator and the discard of epoch-caused edges (rows 47,
   48): D-182 Rationale log 6395–6403.
3. The endpoint policy: the holding endpoint, `t* = tₙ` impossible, the guard
   observably holding, `t* = tₙ₊₁` legitimate, grid times indexed (rows
   57–62): D-082 Rationale log 2365–2369. D-082's Spec field lists only §14.5
   (log 2361).
4. What a `t*` boundary does: the full iteration, no drain, no separate
   pacing, the frame-indexed trace (rows 63–66): D-081 Rationale log
   2333–2338.
5. The even-crossings blind spot (row 56): D-121 Rationale log 3569–3570.
6. The two budgets' exhaustion semantics compared (row 74); the three
   registers "named normatively", the termination bound, `FiringBudget` (rows
   133, 150, 152); the name `localization_budget` (row 70): D-181 Rationale
   log 6355–6364 and Rejected log 6378–6380.
7. Rate compilation and dueness: one `(D, Φ)` pair, the gate, `Φ = 0` at
   boundary zero, affine phases, the residue, `K = 1` admitting no stagger,
   relative phases never refining the grid, phases leaving `Δt` unchanged
   (rows 82, 83, 95, 106, 110, 111, 113, 130): D-185 Rationale log 6493–6507.
8. Anchors: composition below an anchor, the constraint pool, the doctrinal
   line, outside pinning rejected, never-cache-`Δt` intact (rows 116, 117,
   120, 122–124): D-186 Rationale log 6544–6561.
9. `Δt` readable in the stages (row 126): D-019 Rejected log 689.
10. Readers observe the table only at boundaries (row 24): D-023 Rejected
    log 779, which says only "see §10.3".
11. Fixed handler order across components, the no-opt-in trade, the
    single-pass executor (rows 145–147): D-100 Rationale and Rejected log
    2879–2893, D-154 Rationale log 5263–5266.
12. Ticks cannot cause events (row 156): D-020 Rejected log 711–712.
13. Boundary zero sets every prior to not-holding (row 138): D-082 Rationale
    log 2363–2364.
14. The spin's `GC.safepoint()` and a live switch to `p = ∞` (rows 168,
    177): D-269 annotation log 10769–10778.
15. The wait as an unmask point (row 174): D-132 Rationale log 3936–3939.

### Rulings with no entry at all

`h` required with no default (row 17); the first cut's properties and
"genericity is not even required" (13, 14); the domain argument (19–21); the
`1e-6` reasoning and the trial-evaluation bill (53); bisection as fallback
(51); earliest `t*` first (55); `ChatteringBudget`'s name and payload (72);
the tick index `k ÷ N_base` and the empty off-tick due set (81, 93);
`s_update` in any order (98); the stagger doctrine (99, 100); the
fastest-relative-member convention (112); the `sample_times` key clause
(109); `FiringBudget` at most once per event per boundary, and its payload
(152); the reason for the default 4 (153, which lives in `src/deployment.jl`
305–308); the staging-slot pointer (178). Some are descriptions (13, 98,
178); the rest are rulings the log never recorded.

### Stale entry text and Spec fields

- D-016 Position (log 571–575): per-event re-decode and selective
  auto-publication, superseded by D-154 (log 5261) and D-252 (log 9384);
  status "ratified", no annotation.
- D-019 Position (log 660–661): "compiled to absolute divisors", stale since
  D-186's anchor-relative triples; Rejected log 688 "Phase offsets: no
  demonstrated use", reversed by D-185. No annotation.
- D-020 Position (log 696–698): "per-event re-decode", "each event firing at
  most once per boundary", superseded by D-154 and D-181. No annotation.
- D-067 Position (log 1855): boundary zero's sweep "every tick due", stale
  since D-185 and D-205.
- D-081 Rationale (log 2333): "once-per-event scoped per boundary", stale
  since D-181. Spec field (log 2331) lacks §10.4, where the content lives.
- D-082 Spec (log 2361): §14.5 only.
- D-100 Position (log 2868–2873): the round-start materialization, whose
  mechanism D-154 superseded (log 5262). No annotation.
- D-133 Position (log 3990–3994): "`Simulation` keywords beside `h`, `n`",
  "`event_budget`"; stale by D-254/D-256, D-234 and D-181. No annotation.
- D-147 Position (log 4952–4954): "everything at boundary zero", amended by
  D-185 Rationale and D-205; phase-body names `sweep_hx`, `sweep_hxu` are the
  old vocabulary.
- D-153 Position (log 5209–5215): the `fired` and `re-arm` flags and
  `EventDeferred`, all retired by D-181 (log 6355–6357); status "ratified".
- D-154 Position (log 5247): "once-per-event-per-boundary … unchanged", stale
  since D-181.
- D-156 Position (log 5324): "completing §10.1's removal of the dummy-`[0.0]`
  tax"; the text is §10.2 4743–4748.
- D-182 Spec (log 6393): lacks §10.4.
- D-185 Rationale (log 6501–6502): an offset component "holding its
  probe-populated cells", amended by D-205 (which says so, log 7246–7247); no
  annotation on D-185.
- D-187 Spec (log 6596): lacks §10.5, whose heading at 5440 states its
  "single source of truth for `Δt`".
- D-268 Position bullet 1 (log 10563–10564): the loop consults the pause flag
  "at frame top and inside its wait and pause blocks"; D-269 bullet 3 (log
  10699–10701) says frame top alone, the pause block the one wait woken at
  once. §10.7 5766–5768 and §12.1 7428–7431 follow D-269. D-268 wants an
  annotation.
- D-274 Spec (log 11144): lacks §10.2 (the checkpoint hook, F1) and §10.6
  (5533 cites D-274).
- D-074 Rejected log 2125 and D-086 Rejected log 2500 cite "the §10.1
  `task_local_storage` lesson", which is D-017's dossier, not §10.1.
- D-116 Rejected log 3426 and D-288 Rejected log 11854 cite "§10.3's
  publication-after-every-boundary property", which §10.3 does not state.

### Factual problems in chapter 10

- **F1.** 4720 "The seam contract has three clauses." D-274 Position bullet 1
  (log 11103–11104) gives the seam a checkpoint hook, "empty for a
  single-step method". `src/stepper.jl` 33–44 implements it
  (`checkpoint_stepper`, `restore_stepper!`), and `implementation.md` 499–505
  lists it under "Spec: §10.2". The spec never states it (`rg 'checkpoint
  hook'` finds nothing). Part G q6.
- **F2.** The seam's operation is unnamed in the spec ("advance the
  continuous state from `t` by `h`", 4713), which is fine. `src/stepper.jl` 7
  and `src/sim.jl` 601–603 call it `integrate!` since `4eb2d5a`;
  `frame_walkthrough.md` 79, 81 and 218 still say `step!(sim, h′)` and
  `step!(::RK4, sim, h)`. The stale names are the companion's, not the spec's.
- **F3.** 4776 "periodic avionics (50 Hz today)", 4788 "the fastest
  continuous dynamics in the current codebase", 4790 "The crosswind-landing
  demo is the empirical proof". These are Flight.jl facts in the present
  tense; Cadence.jl's own `src/` and `test/` hold no aircraft model, and the
  crosswind landing appears only in `trim_environment_walkthrough.md`. Part G
  q2.
- **F4.** 5571 "[epoch rule](#g-input-epoch)". The epoch in "no bundle …
  straddles two epochs" (5574–5575) is one round's sweep, the world a guard
  fired on (D-154; `event_visibility_walkthrough.md` 162–166). An input epoch
  is a span of constant `u` between drains (4940–4941; glossary 12271), and
  `u` never changes inside a boundary. The link points readers at the wrong
  concept. §5.3 947 has the same link (outside the chapter). Part G q4.
- **F5.** 5114–5115 "Neither the boundary iteration nor cross-frame
  re-localization has a structural bound". Re-localization runs on the
  remainder, inside the same frame (5003–5005, 5009–5010), and the budget is
  per frame. "Cross-frame" looks wrong; "within-frame" or plain
  "re-localization" is meant.
- **F6.** 5132 "Both are grid-independent" and 5135 "both are recorded"
  follow a sentence that adds `firing_budget` to the two localization
  constants; "both" excludes the third parameter by inference. §9.2
  3763–3765 says all three are grid-independent, and D-181 says all three are
  recorded.
- **F7.** 5165–5166 "The frame top at `t = k·h`": 5047 and D-082 say
  `tₖ = t₀ + k·h`; `t₀` is an init-service argument (D-067 log 1864).
- **F8.** 5529–5531 the registers "are not traced, and they are
  reconstructed deterministically". Under D-274 the trace header is a
  checkpoint and carries the guard priors (log 11094–11099), and `restore!`
  copies them rather than reconstructing them; 5532–5533 says the checkpoint
  carries the prior, so the paragraph contradicts itself. "Reconstructed" is
  D-082's warm-restart wording (log 2359).
- **F9.** 5547–5548 "the same class of footgun §2.2 cited when killing
  `f_step!`". §2.2 (285–291) excludes `f_step!` on decomposition grounds and
  says nothing about step-size-dependent semantics; the argument lives in
  D-020 Rejected log 706–708.
- **F10.** 5248–5250 "The 'tick at `t₀⁻`' story they once told held only in
  the build's own world": history of a superseded position (D-205 Rationale
  log 7257–7259) in normative text. Part G q7.
- **F11.** 5786–5787 "The wait interval is the natural staging slot for
  externally injected inputs, applied at the next boundary." Staged inputs
  are drained at the next frame top, never at a `t*` boundary (5064–5066,
  D-081 Rejected log 2343).
- **F12.** §12.2 7500–7502 says §10.7 "left the coarse phase's primitive
  open", while §10.7 5762–5764 names it. One of the two is stale; §12.2 is the
  home (D-027), so §10.7's sentence is the duplicate and §12.2's framing the
  inaccuracy.
- **F13.** 4756 "the tracer": a reader-cold name in §10.2. It is §5.6's
  feedthrough tracer (spec 1048, 1149). It needs a gloss and a pointer.
- **F14.** 4877 "The piston engine's `starting → running`", 5679–5680 "an
  engine's `starting → running` transition under a 50 Hz FCS", 5258 "The FCS
  cascade": aerospace examples without an introducing clause
  (`spec_style.md`, "Introduce every reader-cold name"). FCS is glossed
  nowhere in the chapter.
- **F15.** 4695–4696 and 5270–5271 gloss pacing twice, in §10.1 and §10.5;
  that is allowed (one gloss per section) but §10.1's is the chapter's first
  use of *frame*, which nothing has defined (part G q1).

Outside chapter 10, met while checking citations:

- **F16.** spec 4063 (§9.4): "event localization runs as `Float64` sweeps by
  design (§10.4)"; §10.4 says nothing about the scalar type.
- **F17.** spec 947 (§5.3): the same wrong `#g-input-epoch` link as F4, under
  a **Rule.** label that restates §10.6's epoch rule.
- **F18.** `frame_walkthrough.md` 79, 81, 218: `step!` for the seam operation
  (F2).

## F. Difficulty per section

| section | difficulty | reason |
|---|---|---|
| intro (new) | low | about 60 added words, once part G q1 is ruled |
| §10.1 | low | 126 words; absorbs M1; strip the **Rule.**/**Why.** labels; keep D-017's adversarial half out |
| §10.2 | medium | short and already labelled, but the domain argument (rows 19–21) has no entry and rests on Flight.jl facts (F3, F13); the checkpoint hook (F1) waits on a ruling |
| §10.3 | low | 72 words plus M2; its one rule is R (D-023 Rejected only) |
| §10.4 B1 | high | 1,654 words, a 1,012-word block under eleven bold lead-ins; 20 U and 13 R rows; the order fix (M10) touches define-before-use; three entries (D-179, D-182, D-082) carry most rulings in Rationales |
| §10.4 B2 | medium | endpoint argument (R throughout, D-082/D-182); the `t*` boundary (R, D-081); M4 out; M5 waits on q5; F5, F6 sit here |
| §10.5 C1 | medium | the gate and due sets are crisp, but rows 81–83 and 93 are R or N; boundary zero's row cites D-205 while D-147 still says "everything" |
| §10.5 C2 | medium | 13 R rows from D-185/D-186 Rationales; the table, code block and chart carried verbatim; M7 and M8 reorder blocks |
| §10.6 D | high | 2,096 words with no subheadings; the densest argument in the chapter (registers, blocking, budget); the epoch link (F4), F8 and F9; adversarial passages (q3) |
| §10.7 E | low | already in near-target style, cited and bold-first; F11, F12 are one-sentence issues |

Warnings for the rewriter:

- **Terms of art stay verbatim**: holding, not-holding, prior, last-observed
  sample, firing count, eligible, blocked, quiescence, trial evaluation,
  arrival sweep, interior sweep, boundary sweep, due, epoch-caused,
  trajectory-caused, frame top, tick index, canonical residue, anchor,
  severed. "Blocked, not lost", "discarded, not degraded" and "degrades; it
  does not throw" are each a distinction the log fought for (D-191, D-182,
  D-018); a paraphrase that drops one half changes the rule.
- **The log's vocabulary is old.** D-018, D-147 and D-182 say "probe" for
  what the spec calls a trial evaluation, "Tier-1/Tier-2" for
  boundary-detected/localized (D-122), "baseline" for prior, `h_x`, `h_xu`,
  `g`, `z`, `project`, `Event`, `n`, `event_budget`, `Simulation` keywords.
  Never import them when citing an entry.
- **Directionality is exact.** "not-holding → holding" is not a sign change
  (4896–4897, 5499–5500). "The holding endpoint" (5019) is not "the root".
  "Strictly later than tₙ" and "`nextfloat(tₙ)`" (5029–5030) are the argument.
- **Two different epochs.** Until part G q4 is ruled, keep 5571's link as
  written and flag it; do not merge §10.4's input epoch with §10.6's.
- **The firing budget is per event per boundary; the localization budget is
  per frame.** 5095, 5484–5485. Keep both scopes in every sentence that names
  either.
- **Counts and defaults are rulings.** 8, 4, `1e-6`, 2 ms, `5·h/p`, `≥ 1`,
  "at most once per event per boundary", "one per component per round". Each
  carries its own entry (part A); none is a style choice.
- **Glossary links reset per section.** M1 moves the first uses of frame,
  boundary, drain, tick and boundary zero into §10.1; §10.4 then needs its own
  first-use links for whatever it still uses.
- **Bold lead-ins are headings.** 25 or so in §10.4–§10.7. Each becomes a
  `####` label, a plain topic sentence or a bold headline clause with its
  D-citation; the bold check flags any bold span without one. Count before and
  after.
- **The chapter already cites by adjacency.** Many C rows have their
  citation one paragraph away (marked "adjacent"). A split or move that
  separates a rule from that paragraph needs the citation repeated.
- **Code and math**: part C, "Code blocks".
- **History sentences** (5248–5250, 5612–5615, 5630–5634) wait on part G q3
  and q7; carry them unchanged until ruled.

## G. Decisions for the owner at checkpoint 1

Settled for every chapter and not asked again: log repair rides track 2, and
bold marks one headline clause per ruling (recipe step 1, checkpoint 1).

**q1. Where frame and boundary are defined, and whether the chapter gains an
intro.** Today they are defined only in §10.4 (4818–4829) and used from
§10.1 on (F15). Options: (a) move them to §10.1 as the loop's two units (M1),
retargeting three spec citations (5827, 7598, 12210), and add a short chapter
intro with a roadmap sentence; (b) put the definitions in a new chapter intro
instead, so citations retarget to "§10"; (c) leave them in §10.4 and add a
forward pointer in §10.1, plus the roadmap intro. Recommendation: (a). §10.1
is about the loop, a frame is one iteration of it, and a section citation is
more precise than a chapter citation.

**q2. §10.2's domain argument (4770–4796).** It has no entry (D-017's
Rationale is "Recorded only through the rejections below", log 608), and its
evidence is Flight.jl's: 50 Hz avionics "today", the "current codebase",
31 rad/s actuator poles, the crosswind-landing demo (F3). Options: (a) keep it
in the spec as constructive rationale, unbolded, rewording "today" and
"current codebase" as Flight.jl's with one introducing clause, and record the
argument in a track-2 entry; (b) keep the three points as one-sentence claims
and move the Flight.jl evidence to `companions/flight_case_studies.md` with a
pointer; (c) leave it as written for the rewrite, everything to rulings.
Recommendation: (b). The three claims are the spec's reasons for fixed-step
RK4; the measurements of one aircraft model are case-study evidence, which
`spec_style.md` "Rationale" places in that companion. The stiffness ladder
(4791–4794) reads as guidance and stays unbolded either way.

**q3. Adversarial rationale.** `spec_style.md` sends "why alternative X loses"
to the log. Candidates: §10.1 4704–4706 (the `CallbackSet` rejection; D-017
Rejected holds it), §10.6 5612–5615 (the four rejected shapes; D-154 Rejected
holds all four, M6), §10.6 5630–5634 (the retired deferral machinery; D-181
Rationale holds it). Options: (a) delete each to a one-clause pointer at its
entry, after checking the entry carries it (all three do); (b) keep all three;
(c) delete only 5612–5615, which is a pure list. Recommendation: (a) for
5612–5615 and 4704–4706; keep 5630–5634's first two sentences ("the
arbitrary-K objection lives on in `firing_budget`"), which state a cost of
the adopted design rather than litigate a rejected one, and cut its list.

**q4. The "epoch rule" (5571, F4).** The link sends readers to the input
epoch, a different concept. Options: (a) drop the glossary link and say what
the epoch is in place ("no bundle mixes two sweeps' values"), keeping the
name "epoch rule"; (b) rename it ("the one-world rule") and add a glossary
entry; (c) leave as written, to rulings. Recommendation: (a), ruled now so the
rewriter of unit D does not have to flag and wait; §5.3 947 gets the same fix
in chapter 5's turn or in track 2.

**q5. The deployment-constants block (5123–5143) against §9.2 (3753–3767).**
§9.2 holds the validation list and grid-independence for all three event
parameters. Options: (a) keep §10.4's ownership sentence (deployment, not
implementation), grid-independence (spec 3765 cites it), the recording rule
and its reason, and replace the validation details and the `firing_budget`
list (5128–5132) with a pointer to §9.2 (M5); (b) keep the block whole.
Recommendation: (a). It removes the "both"/three mismatch (F6) without
deciding it, since the trimmed sentences are the ones that carry it.

**q6. The seam's checkpoint hook (F1).** D-274 ruled it and `src/` has it;
§10.2 says "three clauses". Options: (a) add a fourth bullet now as a ruled
edit, citing D-274, and change "three" to "four"; (b) leave the text, file it
for track 2. Recommendation: (a). The rewriter re-touches that sentence
anyway, and the inbound check would otherwise find `implementation.md` 505
relying on content §10.2 lacks.

**q7. History in normative text.** 5248–5250 ("The 'tick at `t₀⁻`' story they
once told …") records a superseded position (D-205 Rationale holds it).
Options: (a) delete, keeping 5247–5248's rule and 5250–5251's phase-free
remark; (b) keep. Recommendation: (a).

**q8. The units.** Seven units as in part C: A 1,025 (plus the new intro),
B1 1,654, B2 957, C1 1,099, C2 1,549, D 2,096, E 988. The open choice is D
whole or split at 5558 (D1 820, D2 1,276). Recommendation: D whole, because
its blocks cross-refer and M9 would cross the split.
