# Chapter 10 track 2: edits applied — 2026-10-02

Applies `rulings_batch.md` K13 to K32 as its Status section rules them. Line
numbers are those at the time of the edit; `log` is
`docs/design/decisions.md`, `spec` is `docs/design/spec.md`. Citations were
written bare and linked by `linkify.jl` afterwards.

## Step 1. New entries (K13 to K17)

All five proposals kept at least one traceable bullet, so the ids run
D-290 to D-294 in K order. Every entry is appended after D-289 and before the
link-definition block (log, old line 11977).

### D-290 (K13) — Localization's exact detection, left-end discriminator, endpoint and `t*` boundary

Dropped under the Status: K13's fifth bullet whole (earliest `t*`, later
crossings re-localizing, the bisection fallback, `ChatteringBudget`'s name and
payload). Also dropped, untraceable: "its `Bool` factors in the branch
condition" (D-179 says only "the gate idiom … is the blessed way to localize a
mixed predicate").

- Bullet 1 ← D-179 Rationale: "guards over `u`/`m` alone are piecewise
  frame-constant so boundary detection is *exact* for them, and the gate idiom
  `(gate) ? σ : -one(σ)` is the blessed way to localize a mixed predicate".
- Bullet 2 ← D-182 Rationale: "Only `u` can differ from the prior's context
  (`m`/cells/`t` boundary-stable, sweeps deterministic): σ₀ not-holding ⇒
  trajectory-caused, pay ẋₙ₊₁ + interpolant and root-find; σ₀ holding ⇒
  epoch-caused (the frame-top drain flipped the guard, no in-frame crossing
  exists) — localization discarded, the event fires in the boundary's ordinary
  iteration, one sweep spent, no budget, no warning … (drain = sole
  disagreement source)". The first clause is added beyond K13's draft; it
  carries spec N310's "The discriminator is conclusive".
- Bullet 3 ← D-082 Rationale: "localization returns the holding endpoint of the
  final bracket — `t* = tₙ` structurally impossible (…), guard observably holds
  at `t*`, `t* = tₙ₊₁` degenerates to the grid boundary (Tier-1-coincident, one
  snapshot); grid times indexed, never accumulated (remainder step targets the
  grid point)".
- Bullet 4 ← D-081 Rationale: "At `t*` the full §10.6 iteration runs with
  once-per-event scoped per boundary, snapshot published, §12.3 boundary
  counter incremented, `stop_on` checked (…); ticks never due at `t*`, staged
  inputs not drained, publication not separately paced; replay pointers = … ,
  trace stays frame-indexed." Once-per-event (replaced by D-181) and the replay
  pointers (respelled by D-128, D-230) are left out.

### D-291 (K14) — Rate compilation, the boundary gate, phases and the anchor doctrine

Dropped under the Status: the tick index `k ÷ N_base`, the off-tick empty due
set, the fastest-relative-member convention, and "in any order" for
`s_update`. Also dropped: "All due `s_update` calls run after quiescence",
which is D-020's Position already, not a Rationale-only ruling.

- Bullet 1 ← D-185 Rationale: "Composition: multipliers multiplicative, phases
  affine (`D = K·Dₛ`, `Φ = Φₛ + φ·Dₛ`), preserving the canonical residue
  `0 ≤ Φ < D` with no normalization pass, all scoping still compiling to one
  `(D, Φ)` pair per discrete component".
- Bullet 2 ← D-185 Rationale: "the boundary gate is `(idx − Φ) % D == 0`";
  "boundary zero refines from "everything due" to "everything with `Φ = 0`",
  implemented by nothing — the ordinary gate at index 0 under the residue
  invariant". The `s_update` clause ← D-205 Position: "every discrete
  component's output stages run in the ordinary sorted walk … while `g`
  updates remain gated by `Φ`".
- Bullet 3 ← D-185 Rationale: "`Δt` semantics explicitly unchanged
  (`D·Δt_base`; a phase shifts firing instants, never the period); relative
  phases never refine the base grid and cannot leave the scope grid, and
  `K = 1` admits no stagger — same-rate siblings stagger one level down, the
  scope declared at twice their rate".
- Bullet 4 ← D-186 Rationale: "an absolute declaration inside a library type is
  legitimate when the rate is **a fact about the modeled system, not a
  preference about the simulation** …, deployment preferences keep the
  exposed-multiplier idiom, and the framework cannot police the distinction —
  authoring doctrine …; never-cache-`Δt` fully intact (the pinning sits in the
  enclosing assembly's `sample_times` …)"; D-186 Rejected: "*Absolute pinning
  from outside a subtree's contract:* standing rejection, upheld."
- Bullet 5 ← D-019 Rejected: "*`Δt` via `h`-argument only:* discretized laws
  live in the feedthrough stage." K14's draft "`Δt` is readable in the stages,
  not only in `s_update`" was reworded to the source's own claim.

### D-292 (K15) — Event iteration's registers, boundary-zero prior, visibility trade and budget exhaustion

Dropped under the Status: `FiringBudget` at most once per event per boundary,
and its payload. Also dropped, untraceable: "all normative" (D-181 lists the
registers; "named and normative" is D-153's Position about the retired set),
and "builds each handler's bundle at dispatch from the live table" (not in
D-154's words). The firing-budget warning's naming of the chatterer stays: it
is in D-181's Rationale.

- Bullet 1 ← D-181 Rationale: "registers = prior + last-observed + firing
  count"; D-082 Rationale: "Boundary-zero baseline = nothing-holds (authored
  guard-true conditions fire at `t₀`, §14.5 derived)".
- Bullet 2 ← D-181 Rationale: "exhaustion loses that event's further edges for
  the boundary under a `FiringBudget` warning naming the chatterer — degrades,
  never errors; termination budget-bounded (≤ budget·events) instead of
  structural".
- Bullet 3 ← D-100 Rejected: "*An opt-in for same-round foreign visibility:*
  same-instant cross-component coupling is a cascade — one round per link — and
  tighter coupling belongs inside one component, the synchronous-languages
  position."
- Bullet 4 ← D-100 Rationale: "cross-component handler order is thereby
  semantically unobservable and is fixed (executor component order,
  declaration order within a component) only for §13.4 cursor/diagnostic
  determinism"; D-154 Rationale: "The natural single-pass executor is correct:
  … "no shadow table, no allocation" becomes trivially true".
- Bullet 5 ← D-020 Rejected: "*Event/tick fixed-point iteration:* structurally
  unnecessary — `z⁺` is invisible until the next tick decode." (`z⁺` is `s⁺`
  today.)

### D-293 (K16) — External readers observe the signal table only at boundaries

Dropped under the Status: the required `h` with no default, and with it
§10.2 and Appendix B from the Spec field. Also dropped, untraceable: "only
after the boundary sequence completes", "mid-step contents carry no meaning"
and the parenthetical list of readers, none of which D-023 records.

- Position ← D-023 Rejected: "*Mid-step publication:* see §10.3."; D-023
  Position: "readers acquire-load; … allocate per boundary".

### D-294 (K17) — The pacer's wait: unmask point, single knob, spin safepoint and the switch to `pace = Inf`

Dropped under the Status: the wait's place at frame top, after the control
plane is consulted. Also dropped, untraceable: "calibrated to cover the
primitive's granularity plus typical overshoot" (D-021 says only "absorbed into
`margin` calibration").

- Bullet 1 ← D-132 Rationale: "takes the deferred raise at the unmask points —
  frame top, wait and pause blocks"; D-269 Rationale: "The operator interrupt
  loses nothing, since a signal raises out of `sleep` itself." The second
  source is added beyond K17's draft.
- Bullet 2 ← D-021 Rejected: "*Separate primitive-resolution threshold:*
  absorbed into `margin` calibration."
- Bullet 3 ← D-269 Annotation (2026-09-27): "The spin phase also takes a
  `GC.safepoint()` per iteration: a safepoint is not a yield, so D-027's spin
  stays non-yielding".
- Bullet 4 ← D-269 Annotation (2026-09-27): "A live switch to `pace = Inf` is
  a pace change like any other: it re-anchors and forgives the debt, counted".

## Step 2. Annotations, repoints and Spec fields

Each annotation is a new paragraph inserted before the entry's `**Rejected.**` line, after its Rationale and any earlier annotation. Old text: none (insertion). Line = the `**Rejected.**` line before insertion, in the file as it stood after step 1.

- K19, log 581, D-016. New:

  > Annotation (2026-10-02): superseded in part. D-154 removes the per-event
  > re-decode and D-252 the selective auto-publication. `h_x` as the uniform
  > state decoder and `project` as the sole raw-state function stand.

- K21, log 668, D-019. New:

  > Annotation (2026-10-02): amended by D-185, D-186 and D-283. Phases are
  > adopted, reversing the phase-offset rejection below, and rates compile to
  > anchor-relative triples whose divisors deployment binds.

- K18, log 705, D-020. New:

  > Annotation (2026-10-02): amended by D-154 and D-181. The per-event
  > re-decode is removed, and once-per-boundary firing gives way to the per-event
  > `firing_budget`. The iteration to quiescence and the ticks after it stand.

- K16, log 774, D-023. New:

  > Annotation (2026-10-02): the reader rule its third rejection points at is
  > stated in D-293's Position.

- K20, log 1878, D-067. New:

  > Annotation (2026-10-02): amended by D-185 and D-205. At boundary zero the
  > due set is the `Φ = 0` components, which governs the `s_update` calls alone;
  > every discrete output stage publishes, due or not.

- K18, log 2344, D-081. New:

  > Annotation (2026-10-02): amended by D-181, D-128 and D-230. At `t*` the
  > event phase runs under `firing_budget`. Replay pointers are the frame-entry
  > boundary index, and a snapshot carries the published-boundary ordinal.

- K22, log 2375, D-082. New:

  > Annotation (2026-10-02): refined by D-274. The prior is in no state store
  > and no condition, and a re-run from a condition rebuilds it at boundary zero.
  > Every checkpoint, the trace header included, carries it, and `restore!`
  > copies it back.

- K19, log 2888, D-100. New:

  > Annotation (2026-10-02): mechanism superseded by D-154. The round-start
  > materialization and the per-event re-decode are gone; the round-start-`u`
  > semantics holds by construction, and the Rejected list stands.

- K23, log 4039, D-133. New:

  > Annotation (2026-10-02): amended by D-256, D-234 and D-181. The two
  > parameters are `Deployment` constructor keywords beside `h`, `N_base` and the
  > algorithm, `event_budget` is `localization_budget`, and `firing_budget` joins
  > them as a third recorded parameter.

- K20, log 4967, D-147. New:

  > Annotation (2026-10-02): amended by D-185 and D-205 for boundary zero, as
  > on D-067, and renamed by D-196: `sweep_hx` and `sweep_hxu` are `sweep_1` and
  > `sweep_2`.

- K18, log 5232, D-153. New:

  > Annotation (2026-10-02): amended by D-181. The `fired` and `re-arm` flags
  > and `EventDeferred` are retired; the registers are the prior, the
  > last-observed sample and the firing count. That they are named and normative
  > stands.

- K18, K19, log 5272, D-154. New:

  > Annotation (2026-10-02): amended by D-181. Once-per-event-per-boundary is
  > replaced by `firing_budget`. One event per component per round and the epoch
  > rule stand.
  >
  > Annotation (2026-10-02): §10.6 no longer lists the rejected shapes. The
  > live-table-reads argument is D-100's first Rejected item.

- K20, log 6513, D-185. New:

  > Annotation (2026-10-02): amended by D-205. Every discrete output stage
  > publishes at boundary zero, so no offset component holds probe-populated
  > cells. The gate composition and the residue invariant stand.

- K24, log 10661, D-268. New:

  > Annotation (2026-10-02): amended by D-269. The loop reads the control
  > plane, the pause flag included, at frame top alone; the pause block is the one
  > wait woken at once.


K25 repoints (D-156 at log 5328 left, per the Status):

- K25, log 2148. Old: `internal binding — the [§10.1][s10-1] `task_local_storage` lesson.` New: `internal binding — the D-017 `task_local_storage` lesson.`
- K25, log 2532. Old: `a relied-on seam on internal ABI — the [§10.1][s10-1] lesson.` New: `a relied-on seam on internal ABI — the D-017 lesson.`
- K25, log 3462. Old: `benefit and breaks [§10.3][s10-3]'s publication-after-every-boundary property.` New: `benefit and breaks §10.1's publication-after-every-boundary property.`
- K25, log 11919. Old: `benefit and breaks [§10.3][s10-3]'s publication-after-every-boundary property. (As` New: `benefit and breaks §10.1's publication-after-every-boundary property. (As`

K26 Spec fields (D-288 already listed §10.5 from landing, so it is unchanged):

- K26, log 554, D-015. Old: `**Spec.** [§5.3][s5-3], [§7.4][s7-4]` New: `**Spec.** [§5.3][s5-3], [§7.4][s7-4], [§10.5][s10-5]`
- K26, log 877, D-027. Old: `**Spec.** [§12.2][s12-2]` New: `**Spec.** [§10.7][s10-7], [§12.2][s12-2]`
- K26, log 2388, D-082. Old: `**Spec.** [§14.5][s14-5]` New: `**Spec.** [§10.4][s10-4], [§10.6][s10-6], [§14.5][s14-5]`
- K26, log 3968, D-132. Old: `**Spec.** [§11.6][s11-6], [§12.4][s12-4](1), [§12.4][s12-4](3), [§12.4][s12-4](5), [§13.4][s13-4], [§13.5][s13-5], [§14][s14], [§14.8][s14-8],` New: `**Spec.** [§10.7][s10-7], [§11.6][s11-6], [§12.4][s12-4](1), [§12.4][s12-4](3), [§12.4][s12-4](5), [§13.4][s13-4], [§13.5][s13-5], [§14][s14], [§14.8][s14-8],`
- K26, log 5307, D-154. Old: `**Spec.** [§5.3][s5-3], [§10.6][s10-6]` New: `**Spec.** [§5.3][s5-3], [§10.4][s10-4], [§10.6][s10-6]`
- K26, log 6450, D-182. Old: `**Spec.** [§10.6][s10-6], [§8.1][s8-1]` New: `**Spec.** [§10.4][s10-4], [§10.6][s10-6], [§8.1][s8-1]`
- K26, log 6657, D-187. Old: `**Spec.** [§9.2][s9-2], Appendices B/C` New: `**Spec.** [§9.2][s9-2], [§10.5][s10-5], Appendices B/C`
- K26, log 9714, D-256. Old: `**Spec.** [§9.7][s9-7], [§11.2][s11-2], [§11.8][s11-8], [§12.1][s12-1], [§12.4][s12-4], [Appendix B][sB], [Appendix C][sC]` New: `**Spec.** [§9.7][s9-7], [§10.4][s10-4], [§11.2][s11-2], [§11.8][s11-8], [§12.1][s12-1], [§12.4][s12-4], [Appendix B][sB], [Appendix C][sC]`
- K26, log 11664, D-283. Old: `**Spec.** [§9.1][s9-1], [§9.2][s9-2], [Appendix B][sB]` New: `**Spec.** [§9.1][s9-1], [§9.2][s9-2], [§10.5][s10-5], [Appendix B][sB]`

Spec fields of the new entries: D-290 §10.4, D-291 §10.5, D-292 §10.6, D-293 §10.3, D-294 §10.7 and §12.4, written with the entries in step 1. K16's §10.2 and Appendix B left with the required-`h` clause.

## Step 3. Chapter 10 citations

The new entry joins the source entry's citation; nothing is replaced and no bold span changed. Spec lines are those before any step-4 edit.

- D-290, spec 4902 (N214). Old: `([D-179][d-179]). Such a predicate is constant within each frame. `u` changes` New: `([D-179][d-179], D-290). Such a predicate is constant within each frame. `u` changes`
- D-290, spec 4914 (N226). Old: ``(gate) ? σ : -one(σ)`** ([D-179][d-179]). The `Bool` factors go in the branch` New: ``(gate) ? σ : -one(σ)`** ([D-179][d-179], D-290). The `Bool` factors go in the branch`
- D-290, spec 4998 (N310). Old: `The discriminator is conclusive ([D-182][d-182]). `u` is the only thing that can` New: `The discriminator is conclusive ([D-182][d-182], D-290). `u` is the only thing that can`
- D-290, spec 5013 (N325). Old: `**An epoch-caused edge is discarded, not degraded** ([D-182][d-182]). The` New: `**An epoch-caused edge is discarded, not degraded** ([D-182][d-182], D-290). The`
- D-290, spec 5021 (N333). Old: `edge (above; [D-179][d-179]). Boundary firing is therefore the correct` New: `edge (above; [D-179][d-179], D-290). Boundary firing is therefore the correct`
- D-290, spec 5030 (N342). Old: `([D-182][d-182]). The θ = 0 trial evaluation comes first, so an epoch-caused` New: `([D-182][d-182], D-290). The θ = 0 trial evaluation comes first, so an epoch-caused`
- D-290, spec 5073 (N385). Old: `([D-082][d-082]). That is the smallest trial point where the predicate holds.` New: `([D-082][d-082], D-290). That is the smallest trial point where the predicate holds.`
- D-290, spec 5085 (N397). Old: `never reaches the root-finder ([D-182][d-182]).` New: `never reaches the root-finder ([D-182][d-182], D-290).`
- D-290, spec 5087 (N399). Old: `The guard also observably holds at `t*` ([D-082][d-082]). Handlers therefore` New: `The guard also observably holds at `t*` ([D-082][d-082], D-290). Handlers therefore`
- D-290, spec 5091 (N403). Old: ``t* = tₙ₊₁` exactly is legitimate ([D-082][d-082]). It is a crossing at` New: ``t* = tₙ₊₁` exactly is legitimate ([D-082][d-082], D-290). It is a crossing at`
- D-290, spec 5099 (N411). Old: `**Grid times are indexed, never accumulated** ([D-082][d-082]). `tₖ = t₀ + k·h`` New: `**Grid times are indexed, never accumulated** ([D-082][d-082], D-290). `tₖ = t₀ + k·h``
- D-290, spec 5109 (N421). Old: `**At `t*` the full [§10.6][s10-6] event phase runs** ([D-081][d-081]). The` New: `**At `t*` the full [§10.6][s10-6] event phase runs** ([D-081][d-081], D-290). The`
- D-290, spec 5123 (N435). Old: `the full reason. **Staged inputs are not drained either** ([D-081][d-081]),` New: `the full reason. **Staged inputs are not drained either** ([D-081][d-081], D-290),`
- D-290, spec 5128 (N440). Old: `**The `t*` publication is not separately paced** ([D-081][d-081]). The` New: `**The `t*` publication is not separately paced** ([D-081][d-081], D-290). The`
- D-291, spec 5228 (N540). Old: `([D-185][d-185]). The divisor `D` is the component's period in base ticks. The` New: `([D-185][d-185], D-291). The divisor `D` is the component's period in base ticks. The`
- D-291, spec 5234 (N546). Old: `where `tick` is the boundary's tick index ([D-185][d-185]). That subtraction` New: `where `tick` is the boundary's tick index ([D-185][d-185], D-291). That subtraction`
- D-291, spec 5293 (N605). Old: `everything with `Φ = 0` ([D-185][d-185], [D-205][d-205]). At tick index 0 the gate reads` New: `everything with `Φ = 0` ([D-185][d-185], [D-205][d-205], D-291). At tick index 0 the gate reads`
- D-291, spec 5342 (N654). Old: ``K = 1` therefore admits no stagger ([D-185][d-185]). Two same-rate siblings` New: ``K = 1` therefore admits no stagger ([D-185][d-185], D-291). Two same-rate siblings`
- D-291, spec 5366 (N678). Old: `([D-019][d-019], [D-185][d-185]). Under a scope compiled to divisor and phase` New: `([D-019][d-019], [D-185][d-185], D-291). Under a scope compiled to divisor and phase`
- D-291, spec 5385 (N697). Old: `because it selects among scope ticks that already exist ([D-185][d-185]). It` New: `because it selects among scope ticks that already exist ([D-185][d-185], D-291). It`
- D-291, spec 5426 (N738). Old: `about the simulation** ([D-186][d-186]).` New: `about the simulation** ([D-186][d-186], D-291).`
- D-291, spec 5444 (N756). Old: `([D-186][d-186]). The pinning happens in the enclosing assembly's` New: `([D-186][d-186], D-291). The pinning happens in the enclosing assembly's`
- D-291, spec 5532 (N844). Old: `([D-185][d-185]). An offset shifts firing instants and never the period, so` New: `([D-185][d-185], D-291). An offset shifts firing instants and never the period, so`
- D-292, spec 5642 (N954). Old: `zero sets every prior to not-holding** ([D-082][d-082]). A predicate already` New: `zero sets every prior to not-holding** ([D-082][d-082], D-292). A predicate already`
- D-292, spec 5707 (N1019). Old: `that [D-154][d-154] made unnecessary, and it allocates nothing.` New: `that [D-154][d-154] made unnecessary, and it allocates nothing (D-292).`
- D-292, spec 5710 (N1022). Old: `same-round foreign transition** ([D-100][d-100]). Same-instant sequential` New: `same-round foreign transition** ([D-100][d-100], D-292). Same-instant sequential`
- D-292, spec 5745 (N1057). Old: `**Budget exhaustion degrades; it does not throw** ([D-181][d-181]). When an` New: `**Budget exhaustion degrades; it does not throw** ([D-181][d-181], D-292). When an`
- D-293, spec 4846 (N158). Old: `([D-023][d-023]). These readers are the GUI, logging and network output.` New: `([D-023][d-023], D-293). These readers are the GUI, logging and network output.`
- D-294, spec 5890 (N1202). Old: `*plus* typical overshoot ([D-021][d-021]). There is no second threshold. The` New: `*plus* typical overshoot ([D-021][d-021], D-294). There is no second threshold. The`
- D-294, spec 5922 (N1234). Old: `[D-132][d-132]) for the [operator interrupt](#g-operator-interrupt) (Ctrl-C in` New: `[D-132][d-132], D-294) for the [operator interrupt](#g-operator-interrupt) (Ctrl-C in`
- D-294, spec 5942 (N1254). Old: `([D-269][d-269]).` New: `([D-269][d-269], D-294).`

Sentences a new entry covers that cite no source entry, so gain nothing
under the Status ("citations of a source entry gain the new entry beside
it"): N426–429 (`t*` publication, counter, `stop_on`; D-290); N748–753
(outside pinning, policing; D-291); N824 (`Δt` in the stages; D-291, the next
sentence cites D-015); N899 (the registers; D-292); N1012–1017 (execution
order fixed; D-292); N1043–1048 (termination bound; D-292); N1098–1105
(ticks cannot flip guards; D-292); N1196–1197 (the spin's `GC.safepoint()`,
inside code; D-294). The N1019 citation of D-292 sits at the end of the
sentence whose subject cites D-154, since D-154 there is a noun, not a
parenthetical.

Not cited, since the Status dropped the clause: N349 (bisection), N372
(earliest `t*`), N481 (`ChatteringBudget`), N533 (tick index), N597 (off-tick
due set), N624 (`s_update` in any order), N692 (fastest relative member),
N1060–1064 (`FiringBudget` rate and payload), N112–114 (required `h`),
N1229–1233 (the wait's place).

## Step 4. Outside chapter 10

- K27, spec 7660–7665 (§12.2). Old: "but left the coarse phase's primitive open." New: "and leaves the choice of the coarse phase's primitive to this section." The paragraph's last five lines are rewrapped; no other word changed.
- K28 (as changed by the Status), spec 4063 (§9.4). Old: `as `Float64` [sweeps](#g-sweep) by design ([§10.4][s10-4]).` New: `as `Float64` [sweeps](#g-sweep) by design ([§9.5][s9-5], [D-052][d-052]).`
- K29, spec 947 (§5.3). Old: `**Rule.** Hence the [epoch rule](#g-input-epoch).` New: `**Rule.** Hence the epoch rule ([§10.6][s10-6]).` The **Rule.** label stays for chapter 5's rewrite.
- K32, spec 12279 (glossary, *scratch*). Old: `buffers and the mid-step table ([§7.5][s7-5], [§10.4][s10-4]); and the store` New: `buffers and the mid-step table ([§7.5][s7-5], [§10.3][s10-3], [§10.4][s10-4]); and the store`
- K31, extensions.md 47. Old: `([§3.3][s3-3]) — exactly Simulink's virtual subsystem, and deliberately *only* that. [§10.5][s10-5]` New: `([§3.3][s3-3]) — exactly Simulink's virtual subsystem, and deliberately *only* that. D-019`
- K31, extensions.md 323. Old: `with [§10.4][s10-4]'s rejection of Newton/AD localization on C⁰ grounds.` New: `with D-018's rejection of Newton/AD localization on C⁰ grounds.`

Left per the Status: K30 (walkthrough), K31 lines 70 and 175, K32's §9.2 pair and the proposal quotes, K25's D-156.

## Step 5. Battery

`linkify.jl` ran, then: `check_refs.jl` OK; `check_rows.jl` OK, 294 entries,
coverage grew by D-290 to D-294 and shrank nowhere; `check_glossary.jl
--strict` OK; `check_bold.jl` OK, chapter 10 at 60 bold spans and 569 bold
words, unchanged. `linkify.jl` re-run changed nothing in `spec.md`,
`decisions.md` or `extensions.md`.

## Beyond the step list

- K16's annotation on D-023 is applied (step 2), though the step list named
  only K18 to K24: it belongs to the accepted K16 and closes the circular
  pointer D-293 exists to close.
