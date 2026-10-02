# Chapter 10 track 2: cold verification — 2026-10-02

Checks the uncommitted edits to `decisions.md`, `spec.md` and `extensions.md`
against `backlog_applied.md`, `rulings_batch.md` (Status, K13–K32) and
`tools/decisions_style.md`. `log` is `docs/design/decisions.md` and `spec` is
`docs/design/spec.md`, working tree; line numbers are the current file's.

Severity: **high** (a ruling broken or a false claim), **low** (defensible,
but short of the stated check), **note** (no fix needed).

## 1. New entries D-290 to D-294

Template: all five have `### D-nnn — Title`, Status `ratified`, Position
(headline sentence plus bullets, or two sentences for D-293), Spec,
Rationale, Rejected, in that order. Titles have no period and stay under ~15
words. The Index rows (log 317–321) match the headings. Headline counts match
the bullets (4, 5, 5, –, 4). No Divergence field is needed.

Every Position clause traced, source quoted:

### D-290 (log 12044–12077)

- B1 "guard over `u` and `m` alone is piecewise constant within a frame, so
  boundary detection is exact … gate idiom … endorsed way to localize a mixed
  predicate" ← D-179 Rationale (log 6363–6365): "guards over `u`/`m` alone are
  piecewise frame-constant so boundary detection is *exact* for them, and the
  gate idiom `(gate) ? σ : -one(σ)` is the blessed way to localize a mixed
  predicate". Carried.
- B2 "Only `u` can differ … frame-top drain is the sole source of
  disagreement … trajectory-caused … epoch-caused … discarded … one sweep …
  no localization budget spent and no warning" ← D-182 Rationale (log
  6457–6465): "Only `u` can differ from the prior's context …; σ₀ not-holding
  ⇒ trajectory-caused, pay ẋₙ₊₁ + interpolant and root-find; σ₀ holding ⇒
  epoch-caused (the frame-top drain flipped the guard …) — localization
  discarded, the event fires in the boundary's ordinary iteration, one sweep
  spent, no budget, no warning … (drain = sole disagreement source)". Carried;
  "localization budget" for "budget" is the only budget a discarded
  localization could spend.
- B3 holding endpoint, `t* = tₙ` impossible, holds at `t*`, `t* = tₙ₊₁`
  degenerates with one snapshot, indexed grid times, remainder targets the
  grid point ← D-082 Rationale (log 2397–2401): "localization returns the
  holding endpoint of the final bracket — `t* = tₙ` structurally impossible
  (left end strictly not-holding …), guard observably holds at `t*`, `t* =
  tₙ₊₁` degenerates to the grid boundary (Tier-1-coincident, one snapshot);
  grid times indexed, never accumulated (remainder step targets the grid
  point)". Carried.
- B4 full §10.6 iteration, snapshot, §12.3 counter, `stop_on`, no ticks, no
  drain, no separate pacing, frame-indexed trace ← D-081 Rationale (log
  2361–2366): "At `t*` the full §10.6 iteration runs …, snapshot published,
  §12.3 boundary counter incremented, `stop_on` checked …; ticks never due at
  `t*`, staged inputs not drained, publication not separately paced; …
  trace stays frame-indexed." Carried; once-per-event and replay pointers
  rightly left out.
- Status exclusions honored: no earliest `t*`, bisection or
  `ChatteringBudget`. K13's "`Bool` factors in the branch condition" dropped.

### D-291 (log 12079–12117)

- B1 one `(D, Φ)` pair, multiplicative/affine composition, residue with no
  normalization pass ← D-185 Rationale (log 6555–6558): "multipliers
  multiplicative, phases affine (`D = K·Dₛ`, `Φ = Φₛ + φ·Dₛ`), preserving the
  canonical residue `0 ≤ Φ < D` with no normalization pass, all scoping still
  compiling to one `(D, Φ)` pair per discrete component". Carried.
- B2 gate, boundary zero `Φ = 0` "implemented by nothing", `s_update` alone ←
  D-185 Rationale (log 6558–6563): "the boundary gate is `(idx − Φ) % D == 0`
  … boundary zero refines … to "everything with `Φ = 0`", implemented by
  nothing — the ordinary gate at index 0 under the residue invariant"; D-205
  Position (log 7307–7309): "every discrete component's output stages run …
  while `g` updates remain gated by `Φ`". Carried. `idx` → `tick` is current
  vocabulary; D-147's Position (log 4980) already says "the boundary's tick
  index", so no dropped clause re-enters.
- B3 `K = 1`, stagger one level down, relative phases, `Δt = D·Δt_base` ←
  D-185 Rationale (log 6565–6569). Carried.
- B4 library-type doctrine, cannot police, never-cache-`Δt`, outside pinning
  ← D-186 Rationale (log 6610–6617) "an absolute declaration inside a library
  type is legitimate when the rate is **a fact about the modeled system, not a
  preference about the simulation** … deployment preferences keep the
  exposed-multiplier idiom, and the framework cannot police the distinction
  … never-cache-`Δt` fully intact"; D-186 Rejected (log 6644): "*Absolute
  pinning from outside a subtree's contract:* standing rejection, upheld."
  Carried.
- B5 "`Δt` cannot arrive through an `h` argument alone, because the
  discretized laws live in the feedthrough stage" ← D-019 Rejected: "*`Δt`
  via `h`-argument only:* discretized laws live in the feedthrough stage."
  Carried.
- Status exclusions honored: no `k ÷ N_base`, no off-tick due set, no
  fastest-member convention, no "in any order".

### D-292 (log 12119–12153)

- B1 registers; boundary zero not-holding; authored holding guard fires at
  `t₀` ← D-181 Rationale (log 6418–6419) "registers = prior + last-observed +
  firing count"; D-082 Rationale (log 2395–2396) "Boundary-zero baseline =
  nothing-holds (authored guard-true conditions fire at `t₀` …)". Carried;
  "all normative" rightly dropped.
- B2 exhaustion loses further edges, `FiringBudget` naming the chatterer,
  degrades never errors, bound `firing_budget · E` ← D-181 Rationale (log
  6420–6423): "exhaustion loses that event's further edges for the boundary
  under a `FiringBudget` warning naming the chatterer — degrades, never
  errors; termination budget-bounded (≤ budget·events) instead of
  structural". Carried. The warning's name is D-181's; its rate and payload
  are rightly absent.
- B3 no opt-in, cascade one round per link, tighter coupling inside one
  component ← D-100 Rejected (log 2932–2934). Carried.
- B4 fixed order, cursor/diagnostic determinism only; single-pass executor
  correct, no shadow table, no allocation ← D-100 Rationale (log 2916–2918)
  "cross-component handler order is … fixed (executor component order,
  declaration order within a component) only for §13.4 cursor/diagnostic
  determinism"; D-154 Rationale (log 5318–5320) "The natural single-pass
  executor is correct: … "no shadow table, no allocation" becomes trivially
  true". Carried.
- B5 event/tick iteration unnecessary, `s⁺` invisible until next tick decode
  ← D-020 Rejected (log 728–729): "*Event/tick fixed-point iteration:*
  structurally unnecessary — `z⁺` is invisible until the next tick decode."
  Carried; `s⁺` is the spec's current name (spec 380, 5788).

### D-293 (log 12155–12171)

- "No snapshot is published mid-step. External readers, who acquire-load the
  published snapshot, therefore observe the signal table only at boundaries."
  ← D-023 Rejected (log 799) "*Mid-step publication:* see §10.3."; D-023
  Position (log 782–784) "readers acquire-load; … allocate per boundary".
  Carried: the glossary's *snapshot* is the "boundary-consistent signal
  table" (spec 12833–12834), so "observe the signal table" adds nothing.
  "External" is a gloss of D-023's "readers". The required `h` is rightly
  absent, and §10.2 and Appendix B with it.

### D-294 (log 12173–12195)

- B1 wait is an unmask point beside frame top and pause block; signal raises
  out of `sleep` ← D-132 Rationale (log 3979–3980) "takes the deferred raise
  at the unmask points — frame top, wait and pause blocks"; D-269 Rationale
  (log 10806–10807) "The operator interrupt loses nothing, since a signal
  raises out of `sleep` itself." Carried.
- B2 no separate threshold, absorbed into `margin` ← D-021 Rejected (log
  754–755). Carried; "granularity plus typical overshoot" rightly dropped.
- B3 `GC.safepoint()` per spin iteration, not a yield ← D-269 annotation
  2026-09-27 (log 10845–10846). Carried.
- B4 live switch to `pace = Inf` re-anchors, forgives, counted ← D-269
  annotation (log 10839–10841). Carried.
- The wait's place at frame top is rightly absent.

**Group 1 result: 5 entries, 19 Position units (18 bullets plus D-293's
Position) traced, 0
findings.**

## 2. Annotations (K16, K18–K24)

15 annotations on 14 entries: D-016, D-019, D-020, D-023, D-067, D-081,
D-082, D-100, D-133, D-147, D-153, D-154 (two), D-185, D-268.

Placement and form. Every hunk in `git diff` for these is a pure insertion
(`-N,0`): no annotated entry's own text changed. Each sits after the
Rationale, before `**Rejected.**`, as a paragraph opening "Annotation
(2026-10-02):". Each text matches its K item word for word, citations
linkified. D-023's annotation is K16's, applied as K16 proposes.

Truth, against the amending entry's Position:

- D-016 ← D-154 Position "The per-event re-decode is removed"; D-252
  Position "Supersedes D-016's publication rule". True.
- D-019 ← D-185 Position "gains phases"; D-283 Position "compiles every rate
  into an anchor-relative triple … Final divisors for anchored entries wait
  for `Δt_base`, which deployment binds". True.
- D-020 ← D-154 Position (re-decode removed, "the quiescence iteration
  unchanged"); D-181 Position (once-per-boundary replaced). True.
- D-023 ← D-293 Position. True.
- D-081 ← D-181 Position; D-128 Position "respelled the **frame-entry boundary
  index**"; D-230 Position "A snapshot's boundary index is the trajectory's
  published-boundary ordinal". True.
- D-082 ← D-274 Position: a checkpoint holds "the guard priors"; the trace
  header is a checkpoint; `restore!` "copies the state back … no prior
  reset". True. "No state store and no condition" restates D-082's own
  surviving "not in `z`, not captured".
- D-185 ← D-205 Position "No published cell holds the probe's synthesized
  values … whose gate composition and residue invariant stand". True.
- D-268 ← D-269 Position "consults the control plane at frame top alone …
  the pause block stays the one wait woken at once". True.
- D-154 (1) ← D-181 Position. True. D-154 (2) is not an amendment: §10.6
  ends its order paragraph with "D-154 and D-100 record the rejected shapes"
  (spec 5719) and lists none, and D-100's first Rejected item is "Live-table
  reads under the canonical order" (log 2926). True.

Findings (all low; each is K-ruled text, true of the log, but one clause
rests on a Rationale rather than the named entry's Position):

- **A1, low.** log 1898–1900 (D-067) and log 5009–5011 (D-147): "amended by
  D-185 and D-205. At boundary zero the due set is the `Φ = 0` components".
  D-185's Position says nothing about boundary zero; the `Φ = 0` due set is
  in its Rationale (log 6561–6563). D-205's Position only attests it ("the
  boundary-zero consequence recorded in D-185"). D-291's Position now states
  it. Fix: "amended by D-185 and D-205 (stated in D-291's Position)", or
  leave as ruled.
- **A2, low.** log 5278–5281 (D-153): "the registers are the prior, the
  last-observed sample and the firing count". D-181's Position names only the
  last-observed sample "initialized from the prior"; the three-register list
  and the retirement of `re-arm` and `EventDeferred` are its Rationale (log
  6417–6419). The Position's "deferral compensation … replaced" carries the
  retirement in substance; the list now sits in D-292's Position. Fix: add
  "as D-292 states", or leave as ruled.
- **A3, low.** log 4076–4079 (D-133): "`event_budget` is
  `localization_budget`". The rename is in D-181's Rationale (log 6425),
  not its Position. Fix: none needed beyond noting it; D-181 is still the
  right entry to name.
- **A4, note.** log 2921–2923 (D-100): "The round-start materialization …
  gone" is explicit only in D-154's Rationale (log 5316–5318); its Position
  carries it in substance ("foreign `u` … all the firing round's sweep",
  "nothing writes mid-round"). No fix.

**Group 2 result: 15 annotations checked, placement and dates all correct,
no entry text rewritten, 0 high, 3 low, 1 note.**

## 3. K25 repoints, K26 Spec fields, new entries' Spec fields

K25 (4 repoints; D-156 at log 5379 left, per the Status):

- log 2153 (D-074) and log 2537 (D-086): "the D-017 `task_local_storage`
  lesson", "the D-017 lesson". D-017's first Rejected item (log 620–630)
  holds it: "demonstrated churn — the `task_local_storage` regression …
  after a DiffEqCallbacks release moved `PeriodicCallback` onto
  `task_local_storage`". Holds.
- log 3467 (D-116) and log 11924 (D-288): "§10.1's
  publication-after-every-boundary property". §10.1 (spec 4710–4713): "A
  boundary is a published consistency point. … a snapshot … goes out." Holds.

K26 (9 fields changed; D-288's §10.5 was already at HEAD, log 11889). Each
new section cites the entry for its mechanism:

- D-015 §10.5: spec 5512–5514, `y_direct` "computes each law once and
  publishes it (§5.3, D-015)". Holds.
- D-027 §10.7: spec 5912–5915, the coarse phase uses task-yielding `sleep`.
  Holds.
- D-082 §10.4: spec 4943, 5073–5099 (holding endpoint, indexed grid times);
  §10.6: spec 5627, 5632, 5642 (prior update, not in a store, boundary zero).
  Holds.
- D-132 §10.7: spec 5922, the wait as an unmask point. Holds.
- D-154 §10.4: spec 5060–5062, ties fire one per component per round. Holds.
- D-182 §10.4: spec 4951, 4983, 4998, 5013, 5030, 5085 (trigger check,
  θ = 0 evaluation, discriminator). Holds.
- D-187 §10.5: spec 5505–5506, `Δt`'s single source of truth, the
  `Schedule`. Holds.
- D-256 §10.4: spec 5045, 5183, the event parameters as `Deployment`
  keywords. Holds.
- D-283 §10.5: spec 5410, 5414, anchors severing and the constraint pool.
  Holds.

Each insertion sits in the field's numeric place as K26 orders it. D-182's
field ends "§10.6, §8.1", unsorted before this edit and kept as K26 rules
(note only).

New entries: D-290 §10.4 (14 citations, spec 4902–5128); D-291 §10.5 (9,
spec 5228–5532); D-292 §10.6 (4, spec 5642–5745); D-293 §10.3 (spec 4846);
D-294 §10.7 (spec 5890, 5922, 5942) and §12.4, whose operator-interrupt
subsection names the unmask points ("It takes the deferred raise at the
unmask points: the frame top, …", spec ~8113). All hold.

**Group 3 result: 4 repoints, 9 Spec fields, 5 new Spec fields (6
sections) checked, 0 findings.**

## 4. Chapter 10 citations (spec 4699–5952)

31 hunks in chapter 10, each adding `, [D-29x][d-29x]` inside an existing
parenthetical, except spec 5707, which adds a new parenthetical at the end
of a sentence. No bold span, word or line break changed in any hunk. Every
changed line stays within 80 rendered columns (links collapsed).

Sentence carried by the new entry:

- D-293 at 4846 "External readers observe the signal table only at step
  boundaries". Carried.
- D-290 (14): 4902 exact detection (B1); 4914 gate form (B1); 4998
  "discriminator is conclusive" (B2, "Only `u` can differ"); 5013 epoch edge
  discarded (B2); 5021 "boundary detection is exact for a `u`-caused edge"
  (B1); 5030 ẋₙ₊₁ "paid only on a validated trigger" (B2); 5073 holding
  endpoint (B3); 5085 epoch case "never reaches the root-finder" (B2); 5087
  holds at `t*` (B3); 5091 `t* = tₙ₊₁` legitimate (B3); 5099 indexed grid
  times (B3); 5109 full event phase at `t*`, 5123 no drain, 5128 not paced
  (B4). All carried.
- D-291 (9): 5228 two integers per component (B1); 5234 the gate (B2); 5293
  boundary zero `Φ = 0` (B2); 5342 `K = 1` (B3); 5366 composition (B1); 5385
  phase never refines the grid (B3); 5426 library-type line (B4); 5444
  never-cache-`Δt` intact (B4); 5532 `Δt` still `D·Δt_base` (B3). All
  carried.
- D-292 (4): 5642 boundary-zero prior (B1); 5707 "allocates nothing" (B4, "no
  shadow table and no allocation"); 5710 no opt-in (B3); 5745 exhaustion
  degrades (B2). All carried.
- D-294 (3): 5922 the wait is an unmask point (B1); 5942 live switch to
  `p = ∞` (B4). Carried. 5890: see C1.

- **C1, low.** spec 5889–5890: "`margin` is a single constant calibrated to
  cover the primitive's granularity *plus* typical overshoot ([D-021][d-021],
  [D-294][d-294])." D-294 is attached to the one clause the log says it
  dropped as untraceable ("calibrated to cover the primitive's granularity
  plus typical overshoot", backlog_applied.md, D-294). D-294's B2 carries the
  next two sentences, "There is no second threshold. The resolution floor is
  absorbed into the calibration." D-021 there is pre-existing and carries
  "single" (its Position: "`margin` the single knob"). Fix: move
  `, [D-294][d-294]` off 5890 and cite D-294 after "absorbed into the
  calibration" on 5891.
- **C2, note.** Sentences D-292 B4 and B5 carry but no new citation reaches,
  because no source entry is cited there: "Execution order is fixed …"
  (spec 5700–5704) and the ticks-cannot-flip-guards passage. The Status rule
  ("citations of a source entry gain the new entry beside it") is applied
  consistently; the log lists them. No fix.

**Group 4 result: 31 citations checked, 1 low, 1 note.**

## 5. Edits outside chapter 10

- K27, spec 7660–7665: "[§10.7] fixed the shape of the pacer's wait, hybrid
  sleep-then-spin, and leaves the choice of the coarse phase's primitive to
  this section." Matches K27 word for word; the rest of the paragraph is
  only rewrapped (every other word identical to HEAD). OK.
- K28, spec 4062–4063: "[Guards] and handlers never run, because event
  localization runs as `Float64` [sweeps] by design ([§9.5][s9-5],
  [D-052][d-052])." The "because" clause is kept and only "([§10.4][s10-4])"
  changed, as the Status rules. OK.
- K29, spec 947: "**Rule.** Hence the epoch rule ([§10.6][s10-6])." Matches;
  the **Rule.** label stays. OK.
- **E1, note.** spec 947 now renders at 88 columns (80 at HEAD). Chapter 5
  has not been rewritten, so its line-length rule is not yet binding there.
  Fix: rewrap the paragraph at chapter 5's rewrite, or now.
- K32, spec 12279: "([§7.5][s7-5], [§10.3][s10-3], [§10.4][s10-4])". Matches.
  OK.
- K31, extensions.md 47: "[§10.5][s10-5]" → "[D-019][d-019]"; D-019's Rejected
  item (log 686–688) carries the artificial-loop reason. extensions.md 323:
  "[§10.4][s10-4]'s" → "[D-018][d-018]'s"; D-018's Rejected item (log 657)
  reads "*Newton/AD localization:* guards C⁰ not C¹". Both match K31; lines
  70 and 175 untouched. Link definitions for d-018 and d-019 added by
  linkify. OK.

**Group 5 result: 6 edits checked, 0 findings, 1 note.**

## 6. Battery

- `check_refs.jl`: OK, 4699 citations, every citation and anchor resolves
  (one pre-existing self-vs-spec advisory, event_visibility_walkthrough.md:20).
- `check_rows.jl`: OK; "newly cited by the spec (fine): [290, 291, 292, 293,
  294]".
- `check_glossary.jl --strict`: OK, 170 entries (3 pre-existing advisories).
- `check_bold.jl`: OK; chapter 10 at 60 bold spans, 569 bold words, as the
  log reports.
- `linkify.jl` not re-run: it writes files, and this verifier edits none but
  this one.

## Summary

No high findings. Low: A1 (D-067 and D-147 annotations name D-185, whose
`Φ = 0` boundary-zero rule is Rationale-only; D-291 now states it), A2
(D-153's register list rests on D-181's Rationale; D-292 states it), A3
(D-133's `localization_budget` rename is D-181's Rationale), C1 (D-294 cited
on the "granularity plus overshoot" clause it dropped; move it one sentence
on). Notes: A4, C2, E1.

## Fixes applied by the orchestrator

- C1: D-294 moved from the `margin` calibration sentence to "The resolution
  floor is absorbed into the calibration", its second bullet.
- A1: the D-067 and D-147 annotations also name D-291, whose Position states
  the boundary-zero due set.
- A2: the D-153 annotation also names D-292, whose Position states the three
  registers.
- E1: spec 947 rewrapped to 80 columns.
- A3 and A4 left: the named entries do record the points, in a Rationale.

Battery green after the fixes; `linkify.jl` re-runs as a no-op.
