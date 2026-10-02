# Unit B2 rulings

Log lines are `decisions.md` lines in the working tree on 2026-10-02.

## Corrections proposed

None in the spec text. Two stale log passages met while citing, both track 2:

- D-081 Rationale (log 2337–2342) still says "once-per-event scoped per
  boundary" (stale since D-181, survey part E) and "replay pointers =
  monotonic boundary counter + recorded `t`". D-128 Position (log 3796ff)
  respelled the pointer as the frame-entry boundary index, and D-230 split
  the snapshot's ordinal from the counter. The text follows D-128 and D-230.
- D-133 Position (log 3994–4001) still says "`Simulation` keywords beside
  `h`, `n`" and "`event_budget`" (survey part E). The text follows D-256 and
  D-181.

## Citations added or replaced

- **D-082**, at the holding-endpoint rule, "The guard also observably holds",
  "`t* = tₙ₊₁` exactly is legitimate" and "Grid times are indexed, never
  accumulated". Rationale, log 2369–2373: "localization returns the holding
  endpoint of the final bracket — `t* = tₙ` structurally impossible (left end
  strictly not-holding; published boundaries immutable), guard observably
  holds at `t*`, `t* = tₙ₊₁` degenerates to the grid boundary
  (Tier-1-coincident, one snapshot); grid times indexed, never accumulated
  (remainder step targets the grid point)". Rejected, log 2384: "Accumulated
  time `t ← t* + h′`".
- **D-182**, at the left-end argument ("That case never reaches the
  root-finder"). Rationale, log 6401–6407: "σ₀ holding ⇒ epoch-caused …
  localization discarded … 't*=tₙ structurally impossible' restated on the
  observed left end, unconditional under D-181's honest priors (drain = sole
  disagreement source)".
- **D-081**, at "At `t*` the full §10.6 event phase runs", "Staged inputs are
  not drained either" and "The `t*` publication is not separately paced".
  Rationale, log 2337–2341: "At `t*` the full §10.6 iteration runs … ticks
  never due at `t*`, staged inputs not drained, publication not separately
  paced". Rejected, log 2347–2350: "Drain at `t*`: input timing dependent on
  localization arithmetic — replay indeterminism"; "Per-`t*` pacing: wall
  placement below pacer resolution; the §10.7 invariant concerns
  trajectories".
- **D-181**, at "Firing-budget accounting is scoped to this boundary".
  Position, log 6351: "an event may fire up to `firing_budget` times per
  boundary". At the `localization_budget` rule, Rationale, log 6367:
  "`event_budget` renamed `localization_budget`". At "All three are
  recorded", Position, log 6353: "validated/recorded/replay-compared with its
  siblings".
- **D-147**, at "Ticks are never due there". Position, log 4953: "the
  counter-modulo image of the frame index at a frame top, empty at `t*`".
- **§13.4**, added at `StepError`'s first use in §10.4, a pointer to the
  section that defines it.
- **§14.8**, kept as "the no-throw doctrine of §14.8". Checked: §14.8 names
  its "no-throw doctrine" (spec 10405), and D-070's Rejected list rejects
  throwing on non-convergence as "an expected outcome, not broken machinery"
  (log 1994). The citation holds; "no-throw" is a declared addition.
- **D-128**, at the frame-entry boundary index. Position, log 3796–3798:
  "`StepError`'s replay pointer is respelled the frame-entry boundary index".
- **D-230**, at the published-boundary ordinal. Position, log 8378–8380: "A
  snapshot's boundary index is the trajectory's published-boundary ordinal".
- **D-018**, at "Guard trial evaluations run against the raw interpolated
  state". Position, log 636–638: "probes evaluate the raw interpolated state
  (off-manifold like RK stages), projection running at the `t*` boundary
  where §10.6's edge checks read it". At "Budget exhaustion degrades; it does
  not throw", Position, log 632–636: "bounded event budget whose exhaustion
  *degrades* … and never a `StepError`".
- **D-133**, at the `localization_budget` rule. Position, log 3997–3998:
  "`event_budget`, the per-frame localization allowance, default 8". At "All
  three are recorded", Position, log 4000–4001: "**recorded** in the trace
  header's deployment block".
- **D-256**, at the keywords standing beside `h`, `N_base` and the algorithm.
  Position, log 9649–9650: "The `Deployment` constructor takes the grid and
  event parameters and the algorithm".

No citation was removed or replaced. No superseded entry is cited.

## Rationale-only rulings

- D-082, Rationale, log 2369–2373, and Rejected, log 2384: the holding
  endpoint (bold), grid times indexed (bold), `t* = tₙ₊₁` legitimate and the
  guard observably holding (plain, cited). `t* = tₙ₊₁` shares one Rationale
  segment with the holding endpoint, so it takes no bold of its own.
- D-182, Rationale, log 6401–6407: the left-end argument (plain, a reason).
- D-081, Rationale, log 2337–2341, and Rejected, log 2347–2350: the full event
  phase at `t*` (bold), no drain at `t*` (bold), no separate pacing (bold).
  D-081's Position states only that `t*` is a boundary, not a frame. Its
  Rejected field rejects the drain at `t*` and per-`t*` pacing in separate
  bullets, which makes them separate rulings, each with its own bold.
- D-181, Rationale, log 6367: the name `localization_budget` (bold, with
  D-133 for the rule itself).

## Inbound citations affected

- spec 7767 (§12.4) relies on "the disposition §10.4 gives its own two
  constants", deployment not implementation. The old heading carried it; it
  survives as "Both localization constants are deployment, not
  implementation." under "Deployment constants".
- spec 3765 (§9.2) cites §10.4 for grid-independence. Kept, now "all three"
  (F6).
- log 8365 (D-229 Rejected): "§9.2 and §10.4 both spell deployment validation
  collected". R5's pointer sentence keeps "failures are collected into
  `DeploymentInvalid`", so it stays true.
- spec 8393 (§12.7) and log 3802 (D-128): the counter versus frame-ordinal
  separation. Kept.
- spec 5838 (§11.1) and 12347 (glossary): no drain at `t*`. Kept.
- spec 7751, 12269 and log 4050: grid times indexed, `tₖ = t₀ + k·h`. Kept.
- spec 12229, 8787, 11855: the localization budget and `ChatteringBudget`.
  Kept.
- spec 8517–8518 (§12.7) and 11165–11166 (Appendix B): the two keywords at
  §10.4. Kept.
- The subheadings "What a `t*` boundary does, and does not, do",
  "Projection's reach …", "Budget exhaustion degrades …" and "Both constants
  are deployment …" are gone. No file links a `####` anchor of chapter 10
  (survey part C).

## Open questions

1. **Ticks at `t*` are cited, not bold.** "Ticks are never due there" cites
   D-147 without bold, on the view that §10.5's due-set list (unit C1) is
   where D-147's "empty at `t*`" ruling is stated and bold. If C1 leaves it
   unbolded, the bold belongs here.
2. **The `#g-chattering` link on "Chattering" is dropped.** Unit B1's old text
   links the same anchor earlier in §10.4 (on "localization budget", in the
   post-event paragraph). If B1 drops that link, restore it here.
3. **The `Deployment` link.** `Deployment` first appears in §10.4 in B1's
   convergence paragraph, unlinked in the old text. This unit moves its link
   to its own first use, under "Deployment constants". If B1 links it, this
   one goes.
4. **Glosses added** at first links in §10.4: snapshot, pacer, projection,
   `stop_on`, trace header, replay. Each comes from the glossary entry. The
   projection gloss adds the code span `x ← x_projection(x)`.
5. **"Projection's reach" stays in unit B2**, under "The `t*` boundary", the
   "kept in its place" option of survey part C. Its claim heading became the
   paragraph's topic sentence.
6. **R5's pointer sentence names the `firing_budget`**, so that "all three"
   (F6) has its third member in the text. The kept sentence "the
   constructor validates them with the third event parameter" is the
   pointer, and the validation details map to §9.2.
7. **`h′` gloss.** "`h′` (the remainder step's length)" is a declared
   addition. The old text implies it ("a tiny remainder step … increments
   scale with `h′`"; "the remainder step targets the grid point, with `h′`
   derived at use"), and the glossary's remainder-step entry pairs the two.
