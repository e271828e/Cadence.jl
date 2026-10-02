# Chapter 10 rewrite: rulings batch — 2026-10-02

This batch gathers every open item of chapter 10's rewrite: the seven units'
`rulings.md`, the leftovers in their `verify.md` re-checks, the items
`chapter_fixes.md` skipped or decided without a ruling, every RETARGET, LOSS
and PREEXISTING row of `inbound_check.tsv`, and the survey's parts D and E.
An item that several sources raise appears once and names every source.
Rulings already made are not re-opened: R1 to R11 (`brief.md`) and P5, P7,
P29 to P34 (`chapter_rulings.md`). Items that a later fix resolved, or whose
claim did not hold at its line, are listed at the end under "Dropped".

Locations:

- `N` is a line of `chapter_new.md`, which matches the units' `new.md` files
  as they stand (11:48). A unit's own line is `N` minus its offset: A 0,
  B1 164, B2 380, C1 509, C2 639, D 845, E 1122.
- `spec` and `log` are `docs/design/spec.md` and `docs/design/decisions.md`
  at HEAD (`8fe31ec`, clean for both files). Spec lines below 9782 equal the
  base commit's; the glossary sits 3 lines lower than at `08f5dff`.
- `old` is a line of `chapter_old.md`.

Each item ends with a recommendation: **accept** (apply as proposed),
**leave** (no edit), or **discuss** (a choice the owner should make).

## Summary

| group | items |
|---|---|
| 1. BLOCKING | 12 (K1–K12) |
| 2. TRACK 2 | 14 (K13–K26) |
| 3. OUTSIDE | 6 (K27–K32) |
| 4. SERIOUS | 0 |
| **total** | **32** |

The Contents block needs no change: no section title changed (checked
against spec 57–64).

## Status: the orchestrator's rulings on the blocking items

- **K1 to K6: accepted.** Landing edits, applied at step 7. K4 holds because
  §10.3 now states the extension itself.
- **K7, K10, K11: accepted.** Ruled edits to the units before step 6b.
- **K8, K9: accepted.** No text change.
- **K12: accepted for P24 and P38, changed for P12.** A glossary anchor takes
  one link per section, even where its entry bolds several names: two links to
  one entry in one section send the reader to the same place twice. The
  second and later links to `#g-sweep` in §10.3 and §10.4 go, and so does
  §10.7's second link to `#g-pacing`. `spec_style.md`'s "First use per
  section" bullet gains one sentence saying so.
- **K13 to K32: track 2**, ruled after landing.

## 1. BLOCKING

### K1. Retarget §11.1's frame citation to §10.1

- **Sources:** inbound_check RETARGET row (tsv 52); survey part D, M1; unit A
  rulings "Inbound citations affected".
- **Evidence:** spec 5825–5827: "Its unit of account is the [frame](#g-frame)
  (one iteration of the loop: … publication), the grid step [§10.4][s10-4]
  names." R1 moved the definition to §10.1: N17 "A [frame](#g-frame) is one
  grid step `[tₙ, tₙ₊₁]`. It is the unit of scheduling." §10.4 keeps only a
  gloss (N174–175).
- **Proposal:** spec 5827, "the grid step [§10.4][s10-4] names" → "the grid
  step [§10.1][s10-1] names".
- **Recommendation:** accept. Edit before the splice (recipe step 7.1).

### K2. Retarget §12.3's list of published boundaries to §10.1

- **Sources:** inbound_check RETARGET row (tsv 67); survey part D, M1; unit A
  rulings.
- **Evidence:** spec 7597–7598: "The counter counts *published boundaries*,
  that is grid, `t*` and [boundary zero](#g-boundary-zero) ([§10.4][s10-4]),
  not frames." The three kinds now sit in §10.1 (N27–32). §10.4 still states
  `t*`'s counter increment (N425–426).
- **Proposal:** spec 7598, "([§10.4][s10-4])" → "([§10.1][s10-1],
  [§10.4][s10-4])". The pair keeps the counter-increment half in §10.4.
- **Recommendation:** accept. "([§10.1][s10-1])" alone also holds.

### K3. Retarget the glossary's *boundary* entry to §10.1

- **Sources:** inbound_check RETARGET row (tsv 121); survey part D, M1; unit A
  and unit B1 rulings.
- **Evidence:** spec 12211–12213: "Every grid point is a boundary, but `t*`
  and boundary zero are boundaries that are not frame tops ([§10.4][s10-4])."
  §10.1 holds the whole sentence (N27–32). §10.4 keeps the `t*` half only
  (N173–175).
- **Proposal:** spec 12213, "([§10.4][s10-4])" → "([§10.1][s10-1])".
- **Recommendation:** accept.

### K4. Simplify §11.2's publication citation

- **Sources:** inbound_check RETARGET row (tsv 55); survey part D, M2; unit A
  and unit D rulings.
- **Evidence:** spec 5944–5945: "Publication happens only after the boundary
  sequence completes ([§10.3][s10-3] as extended by [§10.6][s10-6])." M2
  moved the extension into §10.3: N161–163 "The rule extends naturally to
  the boundary sequence ([§10.6][s10-6]). External readers observe the table
  only after the boundary sequence completes." §10.6 keeps a pointer
  (N1095–1096). The old pair stays true.
- **Proposal:** spec 5945, "([§10.3][s10-3] as extended by [§10.6][s10-6])"
  → "([§10.3][s10-3])".
- **Recommendation:** accept. Optional, since the old text is not wrong.

### K5. Apply the R2 companion addition

- **Sources:** brief R2; unit A rulings ("Inbound citations affected", verifier
  fixes); unit A verify re-check.
- **Evidence:** `units/A/companion_addition.md` holds "## 5. Fixed-step RK4 on
  Flight.jl's aircraft model". Its line 14 runs to 104 columns (measured).
  `companions/flight_case_studies.md` 10–15 introduces sections 1 to 4 only.
  §10.2 points at the new section (N145–146). The companion is in
  `linkify.jl`'s roster (line 75), so `linkify.jl` adds the `s10-2` link
  definition.
- **Proposal:** (a) Rewrap the addition's last item:

  ```
  - The fastest continuous dynamics in Flight.jl's codebase sit inside RK4's
    stability region at `h = 0.02`. These are actuator poles near 31 rad/s,
    gear damper decay and friction compensators. The crosswind-landing demo,
    a Flight.jl demo of a landing in a crosswind, is the empirical proof.
    Shrinking `h` comes first on the ladder, since the RHS costs microseconds
    and 500 Hz real-time is unremarkable.
  ```

  (b) Append the section after section 4, before the link-definition block.
  (c) In the opening paragraph, after "Section 4 reads today's C172 trim
  against the stopped-sim services.", insert "Section 5 holds the Flight.jl
  evidence behind [§10.2][s10-2]'s choice of fixed-step RK4." and rewrap
  lines 10–15. That paragraph's next sentence says "The two case studies that
  stand without Flight.jl live in the spec", which stays true. (d) Run
  `linkify.jl`.
- **Recommendation:** accept.

### K6. Update the two Spec fields the rewrite changed

- **Sources:** survey part D, "Log entries whose Spec field would change";
  inbound_check "Spec fields, caused by the rewrite"; unit A and unit D
  rulings.
- **Evidence:** log 2335, D-081: "**Spec.** [§10.6][s10-6], [§12.3][s12-3]".
  R1 put D-081's content in §10.1, which cites it (N29–30), and §10.4 cites it
  three times (N420, N434, N439). log 11148, D-274's field has no §10.x. R6
  put its checkpoint hook in §10.2 (N72–75), and F8 cites it twice in §10.6
  (N946, N948). Old §10.6 already cited D-274, so its §10.6 gap predates the
  rewrite.
- **Proposal:**
  - log 2335 → "**Spec.** [§10.1][s10-1], [§10.4][s10-4], [§10.6][s10-6],
    [§12.3][s12-3]"
  - log 11148 → "**Spec.** [§10.2][s10-2], [§10.6][s10-6], [§11.5][s11-5],
    [§12.6][s12-6], [§12.7][s12-7], [§13.7][s13-7], [§14.8][s14-8],
    [§14.10][s14-10], [Appendix B][sB]"
- **Recommendation:** accept, at landing (recipe step 7.3). The §10.4 and
  §10.6 additions are track-2 repairs that touch the same lines, so they ride
  along. Other Spec fields wait for K26.

### K7. Cite D-288 where §10.5 says `t*` has no tick index

- **Sources:** found while checking unit C1's citations (C1 rulings, "D-185 at
  'neither does a boundary at a localized event time `t*`'. Rationale only");
  C1 verify DRIFT C1-016.
- **Evidence:** N533–535: "A frame top that is no base tick has no tick index,
  and neither does a boundary at a localized event time `t*` ([§10.4][s10-4],
  [D-185][d-185])." D-185 states it only in its Rationale (log 6502, "`t*`
  emptiness remaining arity selection (no sentinel index fails every gate)").
  D-288, written in chapter 9's track 2, states it in a Position bullet
  (log 11817–11819): "At a localized event time `t*` the empty due set is
  arity selection." Its Rationale repeats D-185's "no sentinel index".
- **Proposal:** N535, "([§10.4][s10-4], [D-185][d-185])" → "([§10.4][s10-4],
  [D-185][d-185], [D-288][d-288])". Drop this case from C1's Rationale-only
  list, and add §10.5 to D-288's Spec field (log 11823) in K26.
- **Recommendation:** accept. It may also wait for track 2.

### K8. Confirm how unit A read R2's "one plain sentence each"

- **Sources:** unit A rulings, open question 2; unit A verify (R2).
- **Evidence:** brief R2: "Keep its three claims as one plain sentence each,
  unbolded." N127–143 states each claim in one plain topic sentence ("Closed-loop
  ticks cap the step.", "A piecewise-smooth RHS … starves high order.",
  "Stiffness has a remedy ladder."). The supporting sentences that are not
  Flight.jl evidence follow it: stale commands, the smoothness list and the
  ladder. Only the evidence R2 lists moved.
- **Proposal:** Rule that R2 meant one plain headline sentence per claim, with
  the non-evidence support kept. No text change.
- **Recommendation:** accept. Cutting the support would lose claims that
  have no other home.

### K9. Confirm four departures from the old bold

- **Sources:** unit A rulings, open questions 4 and 5; unit E rulings
  ("Rationale-only rulings", "Open questions"); unit E verify and re-check.
- **Evidence:**
  - (a) `h` required. old 76: "**required** of the caller", with no
    citation. N112–114 is plain. No entry rules it (survey part E, "Rulings
    with no entry at all", row 17). Appendix B repeats it (spec 11165, citing
    §10.2).
  - (b) The wait's place. old 1078: "**The wait sits at the frame top, after
    the control plane is consulted.**" N1228–1230 is plain and uncited.
    D-269 bullet 3 (log 10703–10705) rules only that the control plane is
    consulted at frame top alone. `src/sim.jl` 1575–1584 runs the pause
    block, the stop word, the yield and then the pacer's wait, which matches
    the sentence.
  - (c) D-080's bold, added. N1142–1143: "**Event localization runs
    identically paced or unpaced** ([§10.4][s10-4], [D-080][d-080])." D-080's
    Position (log 2312–2314) states it, and no other place bolds it.
  - (d) The checkpoint hook, plain. N72–75 cites D-274 without bold. D-274
    rules the hook in one sentence of its first bullet (log 11107–11108),
    and the seam's bold (N53) is D-017's.
- **Proposal:** Keep all four as they are. (a) and (b) get entries in K16
  and K17. Their bold returns only if those entries are ratified.
- **Recommendation:** accept.

### K10. Gloss `N` in "No backend ever faces `N = 0`"

- **Sources:** unit A rulings, open question 6; unit A verify ("`N = 0` is
  never defined").
- **Evidence:** N86: "No backend ever faces `N = 0`, and no backend contract
  has to say what it would do there." Nothing in the chapter says what `N` is.
  D-234's Position (log 8523–8524) names it: "the stepper seam's state count
  `N`". D-156 (log 5328): "never invoked with a zero-length buffer, no backend
  faces N = 0".
- **Proposal:** N86 → "No backend ever faces a state count of `N = 0`, and no
  backend contract has to say what it would do there." Cite nothing new: D-156
  sits on the paragraph (N83).
- **Recommendation:** accept.

### K11. Expand ITP and AD

- **Sources:** unit B1 rulings, "Reader-cold names"; unit B1 verify.
- **Evidence:** N348–349: "ITP or Brent are the intended methods, and
  bisection is an acceptable fallback." N350–351: "Newton and AD localization
  are rejected ([D-018][d-018])." Neither the spec nor the log expands either
  name (D-018 says only "ITP/Brent" and "Newton/AD").
- **Proposal:** N348 → "ITP (the interpolate-truncate-project method) or
  Brent's method are the intended methods". N351 → "Newton and AD (automatic
  differentiation) localization are rejected". The sketch comment (N288) and
  "Under ITP" (N360) stay as they are.
- **Recommendation:** accept. The expansions name standard methods and claim
  nothing about the design.

### K12. Confirm the editorial fixer's three no-edit decisions

- **Sources:** chapter_fixes "Skipped items and items with no edit" and unit A
  (P12); chapter_pass P12, P24, P38.
- **Evidence:**
  - P12. chapter_fixes 18: "each name a glossary entry bolds (interior sweep,
    boundary sweep; pacing, debt) may take its own link once per section".
    §10.3 keeps two `#g-sweep` links (N150, N153), and §10.4 three (N184,
    N245, N265). `spec_style.md` 36–37: "A term takes one glossary link per
    section". The glossary's *sweep* entry bolds **interior sweep** and
    **boundary sweep**.
  - P24. §10.4 says three times that the localization constants are
    `Deployment` keywords (N354–356, N468–469, N491–494). The fixer skipped
    the cut because N469's "the second deployment keyword this section fixes"
    counts N354's statement as the first.
  - P38. N1024–1025: "This is the position of the synchronous languages."
    The pass asked for examples. D-100's Rejected item (log 2897) and the
    old text name no language, so the fixer added none.
- **Proposal:** Accept all three. For P12, add one sentence to
  `spec_style.md`'s "First use per section" bullet, after "tables included":
  "The variant names a glossary entry bolds (interior sweep and boundary sweep
  under *sweep*) count as separate terms."
- **Recommendation:** accept.

## 2. TRACK 2

These items wait until the chapter has landed (recipe step 8). K13 to K17
draft new entries that state in a Position what the chapter cites from a
Rationale, a Rejected list or an annotation, or from no entry at all. The
ids D-290 to D-294 assume nothing else claims them first. Each draft takes
the log's usual fields; its Rationale says where each clause was recorded
before, in the "(as recorded in D-nnn)" form chapter 9's entries used. Once
an entry is ratified, the chapter's citations listed with it move to it, or
gain it beside the old entry.

### K13. New entry for §10.4's localization rulings

- **Sources:** unit B1 and B2 rulings, "Rationale-only rulings"; unit B1
  "Bold allocation"; survey part E, "Rulings that need an entry stating them
  in a Position" 1–4 and "Rulings with no entry at all" (earliest `t*`,
  bisection, `ChatteringBudget`).
- **Evidence:** D-179 Rationale, log 6305–6308 ("guards over `u`/`m` alone are
  piecewise frame-constant so boundary detection is *exact* for them, and the
  gate idiom … is the blessed way to localize a mixed predicate"). D-182
  Rationale, log 6399–6407 (the discriminator and the discard). D-082
  Rationale, log 2369–2373, and Rejected, log 2384–2385 (the endpoint, indexed
  grid times). D-081 Rationale, log 2337–2342, and Rejected, log 2347–2350
  (what a `t*` boundary does). No entry: N371–374 (earliest `t*`), N349
  (bisection fallback), N480–481 (`ChatteringBudget`'s name and payload). The
  chapter bolds five of these on a Rationale or Rejected field: N213, N225,
  N325, N383 and N410, plus D-081's three at N420, N434, N439.
- **Proposal:** a new entry.

  ```
  ### D-290 — Localization's exact detection, left-end discriminator, endpoint and `t*` boundary

  **Status.** ratified

  **Position.** The localization rulings §10.4 states are fixed here.

  - A guard that reads only `u` and `m` is constant within each frame, so
    boundary detection is exact for it. A mixed predicate that should
    localize is written in the gate form `(gate) ? σ : -one(σ)`, its `Bool`
    factors in the branch condition.
  - On trigger, the θ = 0 trial evaluation decides the edge's cause. σ₀
    not-holding is a trajectory-caused edge, which pays for ẋₙ₊₁ and the
    interpolant and root-finds. σ₀ holding is an epoch-caused edge: the
    localization is discarded and the event fires in the boundary's ordinary
    iteration, at one sweep's cost, with no localization budget spent and no
    warning.
  - The root-finder returns the holding endpoint of its final bracket, so
    `t* = tₙ` is structurally impossible and the guard observably holds at
    `t*`. `t* = tₙ₊₁` degenerates to the grid boundary, with one snapshot.
    Grid times are indexed, never accumulated.
  - At `t*` the full event phase of §10.6 runs, a snapshot publishes, the
    boundary counter increments and `stop_on` is checked. No tick is due,
    staged inputs are not drained, and the publication is not separately
    paced. The trace stays frame-indexed.
  - Events localizing in one step fire at the earliest `t*`, and later
    crossings re-localize on the remainder. Bisection is an acceptable
    fallback root-finder. An exhausted localization budget raises a
    `ChatteringBudget` warning naming the event and the localization count.

  **Spec.** [§10.4][s10-4]

  **Rationale.** The first four bullets were recorded outside a Position:
  exact detection and the gate idiom in [D-179][d-179]'s Rationale, the
  discriminator in [D-182][d-182]'s, the endpoint and indexed grid times in
  [D-082][d-082]'s, the `t*` boundary in [D-081][d-081]'s Rationale and
  Rejected list. The last bullet's clauses had no entry.

  **Rejected.** None beyond the source entries' lists.
  ```

  Then cite D-290 at N213, N225, N310, N325, N341–342, N383, N396, N398,
  N402, N410, N420, N434, N439, N349 and N371, beside or instead of the
  entries cited there.
- **Recommendation:** accept. The owner may prefer to drop the last bullet:
  earliest `t*` and bisection read as mechanism.

### K14. New entry for §10.5's rate rulings

- **Sources:** unit C1 and C2 rulings, "Rationale-only rulings" and C2 open
  question 1; unit C2 verify (fastest-member convention); survey part E,
  "Rulings that need an entry" 7–9 and "Rulings with no entry at all" (the
  tick index, the off-tick due set, `s_update` in any order, the
  fastest-relative-member convention).
- **Evidence:** D-185 Rationale, log 6497–6511 (one `(D, Φ)` pair, affine
  composition, the residue, the gate, `Φ = 0` at boundary zero, `Δt` unchanged,
  relative phases, `K = 1`). D-186 Rationale, log 6548–6557 (the library-type
  line, never-cache-`Δt`), and Rejected, log 6582–6583 (pinning from outside).
  D-019 Rejected, log 689 (`Δt` in the feedthrough stage). No entry: N531–533
  (`tick = k ÷ N_base`), N596–598 (off-tick due set empty), N623 (`s_update`
  in any order), N691–692 (fastest relative member; D-186's Position at log
  6542 only presupposes it). The chapter bolds N538, N544, N695, N735, N754
  and N842 on these fields.
- **Proposal:** a new entry.

  ```
  ### D-291 — Rate compilation, dueness and the anchor doctrine

  **Status.** ratified

  **Position.** The rate rulings §10.5 states are fixed here.

  - Every declaration compiles to one `(D, Φ)` pair per discrete component,
    kept in the canonical residue `0 ≤ Φ < D`. Multipliers compose
    multiplicatively and phases affinely: under a scope at `(Dₛ, Φₛ)`,
    `Relative(K, φ)` gives `D = K·Dₛ` and `Φ = Φₛ + φ·Dₛ`.
  - Frame top `k` is a base tick exactly when `N_base` divides `k`, and its
    tick index is `k ÷ N_base`. A component is due when
    `(tick − Φ) % D == 0`. An off-tick frame top has no tick index and an
    empty due set. At boundary zero the gate admits exactly the `Φ = 0`
    components, which governs the `s_update` calls alone.
  - `K = 1` admits no stagger: same-rate siblings stagger one level down,
    under a scope declared at twice their rate. A relative phase never
    refines the base grid and cannot leave the scope grid. A phase shifts
    firing instants, never the period, so the bundle's `Δt` stays
    `D·Δt_base`.
  - A scope's base rate is its fastest relative member, which takes `K = 1`.
  - An absolute declaration inside a library type is legitimate when the
    rate is a fact about the modeled system, not a preference about the
    simulation. Deployment preferences keep the exposed-multiplier idiom, and
    the framework cannot police the distinction. Absolute pinning from
    outside a subtree's contract stays rejected. Anchoring leaves the
    never-cache-`Δt` rule intact.
  - `Δt` is readable in the stages, not only in `s_update`. All due
    `s_update` calls run after quiescence, in any order.

  **Spec.** [§10.5][s10-5]

  **Rationale.** Recorded before outside a Position: composition, the gate,
  boundary zero, `K = 1`, relative phases and `Δt` in [D-185][d-185]'s
  Rationale (boundary zero as amended by [D-205][d-205]); the library-type
  line, never-cache-`Δt` and outside pinning in [D-186][d-186]'s Rationale
  and Rejected list; `Δt` in the stages in [D-019][d-019]'s Rejected list.
  The tick index, the off-tick due set, the fastest-member convention and the
  `s_update` order had no entry.

  **Rejected.** None beyond the source entries' lists.
  ```

  Then cite D-291 at N533–535, N538, N544, N596, N604, N653, N676, N691,
  N695, N735, N747, N754, N823 and N842, beside or instead of the entries
  cited there. N676 and N691 may then take bold again (P29 ruled N676 plain
  because N538 already bolds the same D-185 item).
- **Recommendation:** accept. `s_update` in any order (survey row 98) reads
  as a description; the owner may drop that clause.

### K15. New entry for §10.6's event-iteration rulings

- **Sources:** unit D rulings, "Rationale-only rulings" and open question;
  unit D verify ("The D-100 bold"); survey part E, "Rulings that need an
  entry" 6, 11–13 and "Rulings with no entry at all" (`FiringBudget`).
- **Evidence:** D-082 Rationale, log 2367 ("Boundary-zero baseline =
  nothing-holds"), bold at N952–953. D-181 Rationale, log 6359–6366 (the
  three registers, the termination bound, exhaustion degrading), bold at
  N1056. D-100 Rejected, log 2895–2897 (the opt-in), bold at N1020–1021, and
  Rationale, log 2881–2886 (fixed cross-component order), N1011–1015. D-154
  Rationale, log 5267–5270 (the single-pass executor), N1015–1018. D-020
  Rejected, log 711–712 (ticks cannot cause events), N1097–1104. No entry:
  N1059–1063 (`FiringBudget` at most once per event per boundary, and its
  payload).
- **Proposal:** a new entry.

  ```
  ### D-292 — Event iteration's registers, boundary zero, visibility trade and budget exhaustion

  **Status.** ratified

  **Position.** The event-iteration rulings §10.6 states are fixed here.

  - Three registers per event decide eligibility, all normative: the prior,
    the last-observed sample and the firing count. Boundary zero sets every
    prior to not-holding, so a predicate already holding in the authored
    state fires at `t₀`.
  - Exhausting `firing_budget` degrades and never throws: the event's further
    edges at that boundary are lost. A lost edge raises a `FiringBudget`
    warning at most once per event per boundary, carrying the component
    path, the event name, the boundary time, the exhausted budget and the
    boundary's firing count. A boundary admits at most `firing_budget · E`
    firings for `E` declared events.
  - A handler cannot opt into seeing a same-round foreign transition.
    Tighter coupling belongs inside one component.
  - Handler execution order is fixed, executor component order and then
    declaration order within a component, for cursor and diagnostic
    determinism only. The single-pass executor builds each handler's bundle
    at dispatch from the live table.
  - Ticks cannot cause events: a tick's `s⁺` is first decoded at the owner's
    next tick, so nothing after quiescence can flip a guard.

  **Spec.** [§10.6][s10-6]

  **Rationale.** Recorded before outside a Position: the boundary-zero prior
  in [D-082][d-082]'s Rationale; the registers, the termination bound and
  exhaustion in [D-181][d-181]'s; the opt-in in [D-100][d-100]'s Rejected
  list and the fixed order in its Rationale; the single-pass executor in
  [D-154][d-154]'s Rationale; ticks and events in [D-020][d-020]'s Rejected
  list. The `FiringBudget` rate and payload had no entry.

  **Rejected.** None beyond the source entries' lists.
  ```

  Then cite D-292 at N898, N952–953, N1011, N1015, N1020–1021, N1042,
  N1056, N1059 and N1097, beside or instead of the entries cited there.
  N1020–1021's bold then rests on a Position, and its D-100 citation can go
  (see K19).
- **Recommendation:** accept.

### K16. New entry for §10.2's required step and §10.3's reader rule

- **Sources:** unit A rulings, "Rationale-only rulings" and open question 4;
  unit A verify ("the entry points back at §10.3, so no Position exists");
  survey part E, "Rulings that need an entry" 10 and "Rulings with no entry
  at all" (row 17).
- **Evidence:** log 779, D-023's Rejected list: "*Mid-step publication:* see
  [§10.3][s10-3]." §10.3 cites D-023 for the rule (N157–158), so each points
  at the other: a circular pointer. D-023's Rationale is "Recorded only
  through the rejections below" (log 772). N112–114 states that `h` has no
  default, with no entry (K9 (a)).
- **Proposal:** a new entry, and an annotation on D-023.

  ```
  ### D-293 — External readers see boundaries only, and the step has no default

  **Status.** ratified

  **Position.** External readers (the GUI, logging, network output) observe
  the signal table only at step boundaries, and only after the boundary
  sequence completes; mid-step contents carry no meaning. The step `h` has
  no default and is required of the caller: a domain rate is not a
  framework default.

  **Spec.** [§10.2][s10-2], [§10.3][s10-3], [Appendix B][sB]

  **Rationale.** The reader rule was recorded only as [D-023][d-023]'s
  rejection of mid-step publication, which pointed back at §10.3. The
  required step had no entry; Appendix B's keyword table repeats it.

  **Rejected.**
  - *Mid-step publication:* as recorded in [D-023][d-023].
  ```

  D-023, after its Rationale (log 772): "Annotation (<date>): the reader rule
  its third rejection points at is stated in [D-293][d-293]'s Position."
  Then cite D-293 at N157–158 and N112–114. N113's "required" may take bold
  again.
- **Recommendation:** accept.

### K17. New entry for §10.7's wait rulings

- **Sources:** unit E rulings, "Rationale-only rulings"; unit E verify;
  survey part E, "Rulings that need an entry" 14–15.
- **Evidence:** N1228–1230, the wait's place, no entry (K9 (b)). D-132
  Rationale, log 3942–3943: "takes the deferred raise at the unmask points —
  frame top, wait and pause blocks", cited at N1232–1233. D-021 Rejected, log
  737–738: "*Separate primitive-resolution threshold:* absorbed into `margin`
  calibration", which carries N1201's "There is no second threshold". D-269
  Annotation, log 10773–10782: a live switch to `pace = Inf` (cited at N1253)
  and the spin's `GC.safepoint()` (in the code block, N1196, which cannot
  cite).
- **Proposal:** a new entry.

  ```
  ### D-294 — The pacer's wait: its place, its unmask point and its one knob

  **Status.** ratified

  **Position.** The pacer's wait sits at the frame top, after the control
  plane is consulted, and it is an unmask point for the operator interrupt,
  which raises out of the coarse phase's `sleep`. `margin` is the wait's one
  knob, calibrated to cover the primitive's granularity plus typical
  overshoot; there is no second threshold. The spin phase takes a
  `GC.safepoint()` per iteration, a safepoint and never a yield. A live
  switch to `pace = Inf` is a pace change like any other: it re-anchors, and
  the debt it clears is counted as forgiven.

  **Spec.** [§10.7][s10-7], [§12.4][s12-4]

  **Rationale.** The wait's place had no entry. The unmask point was
  recorded in [D-132][d-132]'s Rationale, the single threshold in
  [D-021][d-021]'s Rejected list, and the safepoint and the switch to
  `pace = Inf` in [D-269][d-269]'s annotation of 2026-09-27.

  **Rejected.** None beyond the source entries' lists.
  ```

  Then cite D-294 at N1201, N1228–1230, N1232–1233 and N1253. N1228 may take
  bold again.
- **Recommendation:** accept.

### K18. Annotate four entries that D-181 amended: D-020, D-081, D-153, D-154

- **Sources:** survey part E, "Stale entry text and Spec fields"; unit B2
  rulings, "Corrections proposed"; unit D rulings.
- **Evidence:** D-181's Position (log 6350–6351): "Once-per-event-per-boundary
  and its deferral compensation are replaced by budgeted re-firing", and its
  Rationale (log 6359–6361) retires the "manufactured-prior exception, re-arm
  flag and `EventDeferred`". Still standing:
  - D-020 Position, log 696–697: "per-event re-decode) — each event firing at
    most once per boundary". (The re-decode is D-154's; see K19.)
  - D-081 Rationale, log 2337–2338: "the full §10.6 iteration runs with
    once-per-event scoped per boundary", and log 2341–2342: "replay pointers =
    monotonic boundary counter + recorded `t`", respelled by D-128 (log
    3796–3798, "the frame-entry boundary index") and split by D-230 (the
    published-boundary ordinal).
  - D-153 Position, log 5213–5219: the `fired` and `re-arm` flags and
    `EventDeferred`. Status "ratified". The spec has no `EventDeferred`
    outside the cut text (old 5633).
  - D-154 Position, log 5251: "once-per-event-per-boundary and the
    quiescence iteration unchanged".
  The spec follows D-181 (N862–873), and `src/deployment.jl` 283 has
  `firing_budget = 4`.
- **Proposal:** one annotation per entry, after its Rationale.
  - D-020: "Annotation (<date>): amended by [D-154][d-154] and
    [D-181][d-181]. The per-event re-decode is removed, and once-per-boundary
    firing gives way to the per-event `firing_budget`. The iteration to
    quiescence and the ticks after it stand."
  - D-081: "Annotation (<date>): amended by [D-181][d-181], [D-128][d-128] and
    [D-230][d-230]. At `t*` the event phase runs under `firing_budget`. Replay
    pointers are the frame-entry boundary index, and a snapshot carries the
    published-boundary ordinal."
  - D-153: "Annotation (<date>): amended by [D-181][d-181]. The `fired` and
    `re-arm` flags and `EventDeferred` are retired; the registers are the
    prior, the last-observed sample and the firing count. That they are named
    and normative stands."
  - D-154: "Annotation (<date>): amended by [D-181][d-181]. Once-per-event-per-boundary
    is replaced by `firing_budget`. One event per component per round and the
    epoch rule stand."
- **Recommendation:** accept. D-153 keeps "ratified": its principle of named,
  normative registers survives.

### K19. Annotate D-016 and D-100, and close D-154's circular pointer

- **Sources:** inbound_check LOSS row (tsv 213); survey part E, "Superseded
  and half-superseded citations" and "Stale entry text"; unit D rulings,
  "Inbound citations affected" and open question; unit D verify (D-120, the
  D-100 bold).
- **Evidence:**
  - D-016 Position, log 571–575: "per-event re-decode" and "selective
    auto-publication". D-154's Rationale (log 5265) supersedes the
    re-decode, and D-252's Position supersedes "[D-016]'s publication rule".
    Status "ratified", no annotation.
  - D-100 Position, log 2872–2877: the round-start materialization. D-154
    (log 5265–5267) supersedes "[D-100]'s pre-materialization mechanism
    ([D-100]'s round-start-`u` *semantics* survives, now by construction)".
    Status "ratified", no annotation. The chapter cites D-100 at N1021 (bold)
    and N1030.
  - log 5281, D-154 Rejected: "*Live-table reads under canonical order:*
    [§10.6][s10-6]'s standing rejection — executor order becomes semantics."
    R3 cut §10.6's list; N1029–1030 now says "[D-154][d-154] and
    [D-100][d-100] record the rejected shapes". The two point at each other.
    The argument itself is D-100's Rejected item (log 2889–2892).
- **Proposal:**
  - D-016, after its Rationale: "Annotation (<date>): superseded in part.
    [D-154][d-154] removes the per-event re-decode and [D-252][d-252] the
    selective auto-publication. `h_x` as the uniform state decoder and
    `project` as the sole raw-state function stand."
  - D-100, after its Rationale: "Annotation (<date>): mechanism superseded by
    [D-154][d-154]. The round-start materialization and the per-event
    re-decode are gone; the round-start-`u` semantics holds by construction,
    and the Rejected list stands."
  - D-154, after its Rationale: "Annotation (<date>): §10.6 no longer lists
    the rejected shapes. The live-table-reads argument is [D-100][d-100]'s
    first Rejected item."
  - Keep the chapter's D-100 citations. With K15, N1021's bold moves to D-292.
- **Recommendation:** accept. The unit D verifier preferred moving D-100's two
  Rejected items into D-154; the annotations reach the same end without
  editing a ratified Rejected list.

### K20. Annotate the boundary-zero and phase-body text of D-067, D-147 and D-185

- **Sources:** survey part E, "Stale entry text"; unit C1 rulings
  ("Citations added", D-185 and D-205); found while checking D-147's names.
- **Evidence:**
  - D-067 Position, log 1859: "sweep (every tick due; …)".
  - D-147 Position, log 4956: "and everything at boundary zero". Its phase
    bodies are `sweep_hx`/`sweep_hxu` (log 4944–4948), renamed `sweep_1` and
    `sweep_2` by D-196 (log 6931–6932), the names §9.7 uses (spec 4626–4627).
  - D-185 Rationale, log 6503–6506: "everything with `Φ = 0` … an offset
    component holding its probe-populated cells until its first tick".
  - D-185's Rationale (log 6503–6504) refines "everything due" to
    "everything with `Φ = 0`", and D-205's Position (log 7245–7251) "amends
    the boundary-zero consequence recorded in [D-185]": every output stage
    publishes, `g` updates stay `Φ`-gated. §10.5 follows both (N602–613).
- **Proposal:**
  - D-067: "Annotation (<date>): amended by [D-185][d-185] and [D-205][d-205].
    At boundary zero the due set is the `Φ = 0` components, which governs the
    `s_update` calls alone; every discrete output stage publishes, due or
    not."
  - D-147: "Annotation (<date>): amended by [D-185][d-185] and [D-205][d-205]
    for boundary zero, as on [D-067][d-067], and renamed by [D-196][d-196]:
    `sweep_hx` and `sweep_hxu` are `sweep_1` and `sweep_2`."
  - D-185: "Annotation (<date>): amended by [D-205][d-205]. Every discrete
    output stage publishes at boundary zero, so no offset component holds
    probe-populated cells. The gate composition and the residue invariant
    stand."
- **Recommendation:** accept.

### K21. Annotate D-019's divisors and its rejected phase offsets

- **Sources:** survey part E, "Stale entry text"; unit C2 rulings, open
  question 3.
- **Evidence:** D-019 Position, log 660–661: "integer multipliers $K \ge 1$
  composing down the tree, compiled to absolute divisors". D-019 Rejected,
  log 688: "*Phase offsets:* no demonstrated use." D-185 adopts phases (log
  6483), and D-186/D-283 compile rates to anchor-relative triples whose
  anchored divisors wait for `Δt_base` (log 11578–11585). §10.5 cites D-019
  beside D-185 at N676–677.
- **Proposal:** D-019, after its Rationale: "Annotation (<date>): amended by
  [D-185][d-185], [D-186][d-186] and [D-283][d-283]. Phases are adopted,
  reversing the phase-offset rejection below, and rates compile to
  anchor-relative triples whose divisors deployment binds."
- **Recommendation:** accept.

### K22. Annotate D-082's "not captured, reconstructed on warm restart"

- **Sources:** unit D rulings, "Inbound citations affected"; unit D verify
  ("contradicts D-274"); survey F8.
- **Evidence:** D-082 Position, log 2362–2363: "detection bookkeeping, not
  model memory: not in `z`, not captured, reconstructed on warm restart".
  D-274 Position, log 11101–11102: a checkpoint holds "the guard priors, the
  one event register that crosses a boundary", and `restore!` "copies the
  state back" with "no prior reset" (log 11114–11116). `src/checkpoint.jl`
  45, 81 and 94 capture and restore `prior`. §10.6 follows D-274 (N942–961):
  a re-run from a condition resets the registers through boundary zero, and
  a restore keeps them. "Not captured" still holds for a condition; it fails
  for a checkpoint.
- **Proposal:** D-082, after its Rationale: "Annotation (<date>): refined by
  [D-274][d-274]. The prior is in no state store and no condition, and a
  re-run from a condition rebuilds it at boundary zero. Every checkpoint,
  the trace header included, carries it, and `restore!` copies it back."
- **Recommendation:** accept. Not SERIOUS: D-274's Position is later and
  explicit, and the spec and the code follow it.

### K23. Annotate D-133's keyword vocabulary

- **Sources:** survey part E, "Stale entry text"; unit B2 rulings,
  "Corrections proposed"; unit B1 rulings (D-133).
- **Evidence:** D-133 Position, log 3993–3994: "deployment parameters —
  `Simulation` keywords beside `h`, `n` and the algorithm", and log 3997:
  "`event_budget`, the per-frame localization allowance". D-256 made them
  `Deployment` constructor keywords (log 9649–9650), D-234 renamed `n` to
  `N_base` (log 8521–8524), and D-181 renamed `event_budget` (log 6367–6368).
  §10.4 follows (N491–496).
- **Proposal:** D-133, after its Rationale: "Annotation (<date>): amended by
  [D-256][d-256], [D-234][d-234] and [D-181][d-181]. The two parameters are
  `Deployment` constructor keywords beside `h`, `N_base` and the algorithm,
  `event_budget` is `localization_budget`, and `firing_budget` joins them as
  a third recorded parameter."
- **Recommendation:** accept.

### K24. Annotate D-268's pause-flag consultation

- **Sources:** brief, unit E; unit E rulings, open question; survey part E,
  "Stale entry text".
- **Evidence:** D-268 Position, log 10567–10568: "the loop consults the flag
  at frame top and inside its wait and pause blocks". D-269 Position, log
  10703–10705: "The loop consults the control plane at frame top alone. … the
  pause block stays the one wait woken at once ([D-268][d-268])". The glossary
  puts the pause flag on the control plane (N1229–1230), and `src/sim.jl`
  1547–1549 and `src/control.jl` 180 read it at frame top alone. §10.7
  follows D-269 (N1228–1231).
- **Proposal:** D-268, after its Rationale: "Annotation (<date>): amended by
  [D-269][d-269]. The loop reads the control plane, the pause flag included,
  at frame top alone; the pause block is the one wait woken at once."
- **Recommendation:** accept. Not SERIOUS: D-269's Position cites D-268 in the
  bullet that settles the point, and the spec and the code follow it.

### K25. Repoint five section citations in the log

- **Sources:** inbound_check PREEXISTING rows (tsv 163, 171); survey part D,
  "Citations that already rely on content chapter 10 does not hold"; survey
  part E, "Stale entry text"; unit A rulings, "Inbound citations affected".
- **Evidence:**
  - log 2129 (D-074 Rejected): "the [§10.1][s10-1] `task_local_storage`
    lesson". log 2504 (D-086 Rejected): "a relied-on seam on internal ABI —
    the [§10.1][s10-1] lesson". Neither §10.1, old or new, states the lesson.
    D-017's Rejected item does (log 611–621, "the `task_local_storage`
    regression").
  - log 3430 (D-116 Rejected) and log 11858 (D-288 Rejected): "breaks
    [§10.3][s10-3]'s publication-after-every-boundary property". §10.3 rules
    what readers may observe. After R1, §10.1 states that every boundary
    publishes: N22–25, "A boundary is a published consistency point. … a
    snapshot … goes out."
  - log 5328 (D-156 Position): "completing [§10.1][s10-1]'s removal of the
    dummy-`[0.0]` tax". The tax is stated in §10.2 (N89–91), which credits
    "the loop-ownership rule ([§10.1][s10-1])" for its removal.
- **Proposal:**
  - log 2129: "the [§10.1][s10-1] `task_local_storage` lesson" → "the
    [D-017][d-017] `task_local_storage` lesson".
  - log 2504: "the [§10.1][s10-1] lesson" → "the [D-017][d-017] lesson".
  - log 3430 and 11858: "[§10.3][s10-3]'s publication-after-every-boundary
    property" → "[§10.1][s10-1]'s publication-after-every-boundary property".
  - log 5328: leave.
- **Recommendation:** accept the first four; leave D-156, since §10.1's rule
  is what removes the tax and §10.2 says so.

### K26. Spec fields stale before the rewrite or missing a newly cited section

- **Sources:** inbound_check "Spec fields" (all three lists); survey part D
  and part E; unit A, B2, C2 and D rulings.
- **Evidence:** the chapter cites each entry below in a section its field
  lacks (checked by script against `chapter_new.md`): D-015 §10.5 (field log
  554), D-027 §10.7 (862), D-082 §10.4 and §10.6 (2365), D-132 §10.7
  (3936–3937), D-154 §10.4 (5261), D-182 §10.4 (6397), D-187 §10.5 (6600),
  D-256 §10.4 (9657), D-283 §10.5 (11603), and D-288 §10.5 (11823) if K7 is
  accepted. Fields that list a §10.x the chapter no longer cites: D-016 and
  D-152 (§10.6, via R3's cut), D-018 (§10.6), D-133 (§10.5), D-147 (§10.6),
  D-156 (§10.1).
- **Proposal:** add, in each field's numeric place:
  - D-015: "[§5.3][s5-3], [§7.4][s7-4], [§10.5][s10-5]"
  - D-027: "[§10.7][s10-7], [§12.2][s12-2]"
  - D-082: "[§10.4][s10-4], [§10.6][s10-6], [§14.5][s14-5]"
  - D-132: insert "[§10.7][s10-7]" before "[§11.6][s11-6]"
  - D-154: "[§5.3][s5-3], [§10.4][s10-4], [§10.6][s10-6]"
  - D-182: "[§10.4][s10-4], [§10.6][s10-6], [§8.1][s8-1]" (the field's own
    order puts §8.1 last)
  - D-187: "[§9.2][s9-2], [§10.5][s10-5], Appendices B/C"
  - D-256: insert "[§10.4][s10-4]" after "[§9.7][s9-7]"
  - D-283: "[§9.1][s9-1], [§9.2][s9-2], [§10.5][s10-5], [Appendix B][sB]"
  - D-288 (with K7): "[§9.7][s9-7], [§10.5][s10-5]"
  Remove nothing. Each listed section still holds the entry's mechanism
  (§10.6 applies D-018's degrade-not-error doctrine at N1048 and N1072;
  §10.5 is the grid check D-133 keeps the constants out of; §10.6's
  macro-sequence runs D-147's boundary sweep; §10.1 holds the loop-ownership
  premise D-156 completes; D-016 and D-152 are history).
- **Recommendation:** accept.

## 3. OUTSIDE

Problems in other chapters and companions, met while checking chapter 10's
citations. None blocks landing.

### K27. §12.2 says §10.7 left the coarse phase's primitive open (F12)

- **Sources:** survey F12; brief, unit E; unit E rulings; inbound_check
  "Other notes" (spec 7500).
- **Evidence:** spec 7500–7501 (§12.2): "[§10.7][s10-7] fixed the shape of
  the pacer's wait, hybrid sleep-then-spin, but left the coarse phase's
  primitive open." §10.7 names it and points here, old and new: N1223–1226,
  "Which primitive the coarse phase uses … is settled in [§12.2][s12-2]. The
  coarse phase uses task-yielding `sleep` … ([D-027][d-027])." D-027's Spec
  field is §12.2 (log 862).
- **Proposal:** spec 7500–7501 → "[§10.7][s10-7] fixed the shape of the
  pacer's wait, hybrid sleep-then-spin, and leaves the choice of the coarse
  phase's primitive to this section."
- **Recommendation:** accept, now or at chapter 12's rewrite.

### K28. §9.4 cites §10.4 for `Float64` localization sweeps (F16)

- **Sources:** survey F16 and part D; inbound_check PREEXISTING (tsv 40).
- **Evidence:** spec 4061–4062 (§9.4): "[Guards](#g-guard) and handlers never
  run, because event localization runs as `Float64` [sweeps](#g-sweep) by
  design ([§10.4][s10-4])." §10.4 never names the scalar type; it says a
  localized guard returns "the nominal scalar" (N195). The fact holds
  elsewhere: §9.5 (spec 4343–4344) says "Guards run only at the nominal
  activation ([D-052][d-052])", the nominal world is the `Float64` activation
  (spec 1315), and D-052's Position (log 1472–1474) says guards and handlers
  "never see `Dual`".
- **Proposal:** spec 4061–4062 → "- [Guards](#g-guard) and handlers never run.
  They run only at the nominal activation, the `Float64` one ([§9.5][s9-5],
  [D-052][d-052])."
- **Recommendation:** accept. Chapter 9 has landed, so this is a one-line edit
  to a finished chapter.

### K29. §5.3 links "epoch rule" to the input epoch (F17)

- **Sources:** survey F17 and part G q4; brief R4.
- **Evidence:** spec 947 (§5.3): "**Rule.** Hence the [epoch
  rule](#g-input-epoch)." R4 dropped the same link in §10.6 because the epoch
  there is one round's sweep, not the input epoch (N979–981: "An epoch here is
  the world one round's sweep produces. It is not the input epoch of
  [§10.4][s10-4].").
- **Proposal:** spec 947, "Hence the [epoch rule](#g-input-epoch)." → "Hence
  the epoch rule ([§10.6][s10-6])." The **Rule.** label waits for chapter 5's
  rewrite.
- **Recommendation:** accept.

### K30. `frame_walkthrough.md` names the seam's operation `step!` (F2, F18)

- **Sources:** survey F2, F18 and part D.
- **Evidence:** `companions/frame_walkthrough.md` 71 quotes
  "`step!(sim, T(sim.h))`", 79 "`step!(sim, h′)` in `sim.jl`", 81
  "`step!(::RK4, sim, h)` in `stepper.jl`", 218 "`step!(sim, h′)` runs a full
  RK4 step". The code says `integrate!`: `src/localization.jl` 41
  "`integrate!(sim, T(sim.deployment.h))`", `src/sim.jl` 601, `src/stepper.jl`
  62 "`function integrate!(stepper::RK4, sim, h)`". The companion's header
  pins it to `f40585e` and says "the code moves more often than the spec".
- **Proposal:** at those four lines, `step!(sim, h′)` → `integrate!(sim, h′)`,
  `step!(::RK4, sim, h)` → `integrate!(::RK4, sim, h)`, and line 71's quote →
  `(integrate!(sim, T(sim.deployment.h)); nothing)`, with the header's commit
  moved to the commit that checks it.
- **Recommendation:** discuss. Renaming four spots under an old commit pin
  mixes two trees; a full refresh of the walkthrough is the clean fix.

### K31. Four stale §10 citations in `extensions.md`

- **Sources:** inbound_check PREEXISTING (tsv 258, 260, 266, 267); unit C1
  rulings, "Inbound citations affected".
- **Evidence:**
  - 47–49: "[§10.5][s10-5] records why atomic subsystems are an
    artificial-loop factory we refuse to reproduce." §10.5 says only that no
    coarsening is needed (N630–638). The reason is D-019's Rejected item (log
    673–675).
  - 70–72: item 2, "**Sample-time phase offsets.** Recorded in [§10.5][s10-5]
    as 'no phase offsets in the first cut (no demonstrated use)'." D-185 adopted
    phases, and `companions/sample_time_proposal.md` 6–7 says it "supersedes
    section 2 of the extensions charter".
  - 175–178: "[§10.5][s10-5] explicitly identifies `Subsampled`'s
    parent-relative multipliers as a call-tree artifact, then re-chooses
    relative declaration because *ratios* are intrinsic … while absolute rates
    are deployment decisions". No version of §10.5 names `Subsampled`. D-019's
    call-tree remark concerns whole-tree atomicity (log 675), and D-186 made
    absolute rates legal inside library types.
  - 323–324: "consistent with [§10.4][s10-4]'s rejection of Newton/AD
    localization on C⁰ grounds". §10.4 states the rejection without the
    reason (N350–351). The C⁰ reason is D-018's Rejected item (log 648).
- **Proposal:**
  - 47: "[§10.5][s10-5] records" → "[D-019][d-019] records".
  - 70–72: "**Sample-time phase offsets.** Adopted ([D-185][d-185]) and
    specified in [§10.5][s10-5]; worked out in
    [`sample_time_proposal.md`](companions/sample_time_proposal.md)."
  - 175–178: "parent-relative rates ([§10.5][s10-5] chooses relative
    declaration because *ratios* are intrinsic to a control architecture)".
  - 323: "[§10.4][s10-4]'s rejection" → "[D-018][d-018]'s rejection".
- **Recommendation:** accept 47 and 323; discuss 70 and 175, which edit the
  charter's own account of its history.

### K32. Soft citations that hold but could be sharper

- **Sources:** inbound_check "Other notes from the OK rows" and PREEXISTING
  (tsv 314).
- **Evidence:**
  - spec 12118–12119 (glossary, *scratch*): "the integrator's buffers and the
    mid-step table ([§7.5][s7-5], [§10.4][s10-4])". §10.3 is where the chapter
    calls the table integrator scratch (N152–153).
  - spec 3763–3765 (§9.2): the event parameters "are grid-independent …
    ([§10.4][s10-4], [§10.6][s10-6])". Only §10.4 states it (N496–498); §10.6
    defines `firing_budget`.
  - `companions/sample_time_proposal.md` 61–63 quotes pre-D-186 §10.5,
    "absolute rates are deployment decisions made once at the root", and 779
    asks for the coincidence documentation next to the simultaneous-tick rule,
    which M7 moved after the worked example (N619 against N794).
- **Proposal:** spec 12119, "([§7.5][s7-5], [§10.4][s10-4])" →
  "([§7.5][s7-5], [§10.3][s10-3], [§10.4][s10-4])". Leave the rest: §9.2's
  pair is accurate in sum, and the proposal is an adopted record whose quotes
  keep their day.
- **Recommendation:** accept the glossary edit; leave the others.

## 4. SERIOUS

No item qualifies. Every conflict found has a later Position that settles
it, and the spec and the code follow that Position. The candidates examined:

- D-082's "not captured, reconstructed on warm restart" against D-274's
  checkpoint priors: D-274's Position is explicit, and `src/checkpoint.jl`
  captures and restores `prior`. K22.
- D-268 against D-269 on where the loop reads the pause flag: D-269's bullet
  cites D-268 and settles it, and `src/sim.jl` 1547–1549 reads the control
  plane at frame top alone. K24.
- D-020, D-081, D-153 and D-154 against D-181 on once-per-boundary firing:
  D-181's Position says "replaced", and `src/deployment.jl` 283 has
  `firing_budget = 4`. K18.
- D-067 and D-147 against D-185 and D-205 on boundary zero's due set: D-185's
  Rationale refines it, and D-205's Position says it amends it. K20.
- D-288's "due-ness is per component, per boundary, never per stage" against
  D-205's boundary zero, where output stages publish due or not and only
  `s_update` is gated: due-ness itself stays per component; D-205 makes the
  output stages ignore it at one boundary. §10.5 states both (N607–609).
- §9.4's `Float64` reason (F16): the fact is true and ruled by D-052; only the
  citation is wrong. K28.

## Dropped

Items a source raised that no longer hold or were already settled.

- `implementation.md` 497–506, the hook pair under "Spec: §10.2–§10.7" (survey
  part D): R6 put the hook in §10.2 (N72–75), so the citation now holds.
- Glossary *edge semantics*, spec 12249–12252 (inbound PREEXISTING, tsv 127):
  §2.1 states the negated-guard sentence (spec 265–266) and §10.6 states "never
  a bare sign change" (N911). The entry's two citations cover its two
  sentences.
- Unit A verify re-check, the periodic-avionics clause and the demo name: fixed
  (N128 "(onboard flight systems)"; companion lines 13–14).
- Line-length leftovers in the B1, B2, C1, C2 and E re-checks and chapter_pass
  P47–P48: no prose line of `chapter_new.md` exceeds 80 rendered columns
  (measured, links collapsed); N526 is display math. The companion's line 14
  is in K5.
- Unit D verify re-check item 6, the glosses of the deferral design and the
  per-round cap: P4 and P46 rewrote them (N1037–1040).
- Unit E verify re-check, E-077's mapping: the inventory maps E-077 to the
  label, and `added` no longer lists it.
- Unit C2 verify re-check, "fixed" in the bus-schedule gloss: N739 reads "a
  data bus's transmission schedule".
- Unit C1 open question, D-147's four bolds in §10.5: chapter_pass section 5
  found D-147's five bolds on five Position sentences, and C1's verifier
  advised against sharing one.
- Unit A open question 1, unit B2 open questions 1 to 3, unit C2 open
  question 2: settled in chapter_pass's opening list and applied (P9, P14).
- Survey F15, *frame* used before any definition: R1 resolved it (N17).
- Survey part D, the Spec fields under M2 and M4: D-023 and D-147 already list
  §10.3, D-181 lists §10.4 and §10.6.
- Survey part E, row 148 ("D-154 Rejected holds all four"): unit D mapped the
  fourth shape to D-100 (N1030); K19 handles what remains.
- Unit E verify DRIFT E-010 and unit B2 verify DRIFTs B2-012 and B2-071:
  fixed or ruled (N1145; N394–396; P5).
- Log 8365 (D-229 Rejected), spec 7767 (§12.4), spec 8393 and log 3802
  (D-128): each still holds against the new text (unit B2 rulings; N491,
  N445–447).
