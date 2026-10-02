# Unit B1 rulings: §10.4 to the end of "The localization loop"

Old lines are `units/B1/old.md` lines; log lines are `docs/design/decisions.md`
at the working tree.

## Ruled edits applied

- **R1.** The old frame and boundary definitions (spec 4818–4829) are unit A's.
  §10.4 now opens with its context, then the added `t*` sentence ("The
  localized event time `t*` is a boundary (a published consistency point,
  §10.1). It is not the top of a frame (one grid step, the unit of
  scheduling)."), then the chain. The sentence and its two glosses are in
  `added`. First-use links added for boundary, frame and drain; tick keeps its
  link at its new first use. Boundary zero is not used in B1, so it takes no
  link.
- **M10.** "Trial evaluations run the interior sweep" moved up under its own
  `####` label before "The trigger". The trigger's "(below)" became "(above)"
  (claim B1-040). The block gains a definition of "trial
  evaluation" (from the sketch's first comment): at θ = 0 its state is xₙ
  itself, elsewhere x̂(θ), a point on the interpolant, which the loop below
  defines (verifier fix 2; the θ = 0 paragraph and the sketch's
  `x̂(0) = xₙ, no interpolant` comment carry it) and the interpolant's gloss
  and link, which moved here from the θ = 0 paragraph because this is now the
  first use.
- **R8, F14.** The piston engine gets one introducing clause that claims
  nothing beyond the old text: "Take a piston engine whose modes include
  `starting` and `running`." No link to §8.2, whose `Engine` is never called a
  piston engine (verifier fix 1).
- Old **Rule.**, **Why.** labels and the bold lead-ins ("The θ = 0
  validation.", "Why the discriminator is conclusive.", "Post-event.") are
  gone. The lead-ins became a trailing appositive, a plain topic sentence and
  "After the event,". Bold terms (boundary-detected, localized, prior, input
  epoch, trajectory-caused, epoch-caused, holding, not-holding) are unbolded.
  The chain's bold boundaries became the sentence "Its boundaries are tₙ, `t*`
  and tₙ₊₁."

## Corrections proposed

None found beyond the survey's list.

## Citations added or replaced

All are additions; nothing was replaced.

- D-179 (bold, "The guard's return type declares its detection policy"):
  Position log 6296, "Detection policy is declared by the guard's return type".
- D-179 (the one-line rewrite): Position, "de-localization = casting the guard
  to its predicate (`σ ≥ 0`, the §2.1 definition, semantics-preserving by
  construction)".
- D-179 (bold, exact boundary detection over `u` and `m`): Rationale log 6305,
  "recorded doctrine: guards over `u`/`m` alone are piecewise frame-constant so
  boundary detection is *exact* for them". Rationale-only, below.
- D-179 (bold, the gate form): Rationale log 6306–6307, "the gate idiom
  `(gate) ? σ : -one(σ)` is the blessed way to localize a mixed predicate".
  Rationale-only, below.
- D-147 (bold, "Trial evaluations run the interior sweep"): Position log 4933,
  "The interior sweep walks continuous entries only and is what RK stage
  evaluations and localization guard probes run".
- D-082 (bold, the trigger): Position log 2359–2361, "events fire on
  not-holding → holding edges against a per-event baseline held in loop state
  (previous boundary's quiescent sample, updated at quiescence ...)".
- D-182 (bold, the trigger check on the arrival sweep): Position log 6390–6391,
  "trigger checks run against the arrival sweep (before the due-gated boundary
  sweep ...)".
- D-182 (bold, the first act on trigger): Position log 6392–6394, "on trigger
  the first act writes xₙ (already stepper-retained for the interpolant) and
  sweeps once under post-drain `u`".
- D-182 ("The discriminator is conclusive"): Rationale log 6399–6400, "Only
  `u` can differ from the prior's context (`m`/cells/`t` boundary-stable,
  sweeps deterministic)". A reason, not a ruling.
- D-182 (bold, "An epoch-caused edge is discarded, not degraded"): Rationale
  log 6401–6405, "σ₀ holding ⇒ epoch-caused ... localization discarded, the
  event fires in the boundary's ordinary iteration, one sweep spent, no
  budget, no warning". Rationale-only, below.
- D-182 (ẋₙ₊₁ "paid only on a validated trigger"): Rationale log 6400–6401,
  "σ₀ not-holding ⇒ trajectory-caused, pay ẋₙ₊₁ + interpolant and root-find".
- D-018 ("The interpolant is built lazily", bold "Root-finding is bracketed
  and derivative-free"): Position log 630–631, "lazy cubic Hermite dense
  output + bracketed derivative-free root-finding (ITP/Brent)".
- D-018 ("The interpolant is then invalidated", plain): Position log 632,
  "post-event interpolant invalidation + remainder step + bounded event
  budget".
- D-133 (bold, "Convergence is a relative bracket width"): Position log
  3995–3997, "`localization_tol`, a *relative* bracket-width convergence test
  ... (localization converges when the bracket is narrower than
  `localization_tol · h`), default `1e-6`". D-133 still says "`Simulation`
  keywords", so its log vocabulary was not imported.
- D-256 (`localization_tol` is a `Deployment` constructor keyword): Position
  bullets "To the deployment: ... the three event parameters" and log 9649,
  "Constructor keywords follow their fields. The `Deployment` constructor takes
  the grid and event parameters and the algorithm."
- D-154 (ties, one eligible event per component per round in declaration
  order): Position log 5248–5249, "a component fires at most one event per
  round, declaration order picking among its simultaneously-eligible events".
- §10.1 (the `t*` sentence, R1) is a section pointer.

## Rationale-only rulings

- D-179, Rationale, log 6305: boundary detection is exact for guards over `u`
  and `m` alone. Bold, cited; the log owes a Position stating it.
- D-179, Rationale, log 6306–6307: the gate idiom. Bold, cited; the log owes a
  Position.
- D-182, Rationale, log 6399–6405: the θ = 0 discriminator and the discard of
  epoch-caused edges. The discard is bold, cited; the log owes a Position.

## Inbound citations affected

- None from the M10 reorder: it moves text within §10.4, and no file links a
  chapter 10 `####` anchor (survey part C).
- The M1 rows of survey part D (spec 5827, 7598, 12210; log 2331) follow
  from unit A's move. §10.4 still says `t*` is a boundary and no frame top, so
  glossary 12210 stays true for `t*`; its boundary-zero half now lives in
  §10.1 only.

## Bold allocation (coordinator rulings)

- D-018's Position chains four rulings with semicolons. Ruling 1 (lazy
  dense output with bracketed root-finding on trial evaluations that run the
  sweep) takes one bold in B1, on "Root-finding is bracketed and
  derivative-free"; "The interpolant is built lazily" stays plain and cited.
  Ruling 2 (post-event invalidation, remainder step, the budget whose
  exhaustion degrades) has its headline in unit B2 ("Budget exhaustion
  degrades"), so "The interpolant is then invalidated" is plain and cited.
- The one-line de-localization rewrite is a clause of D-179's single Position
  sentence, so it is plain and cited.
- D-147: B1 keeps the bold on "Trial evaluations run the interior sweep";
  unit C1 yields.
- "Multiple events localizing in one step fire at the earliest `t*`" has no
  entry (survey N), so it carries no bold.
- The ẋₙ₊₁ payment rule ("paid only on a validated trigger") rests only on
  D-182's Rationale (log 6400–6401). It is cited, not bold.
- The even-crossings blind spot is plain and uncited: D-121's Rationale only
  records its wording ("survives as 'no edge observed'"), not a ruling.

## Reader-cold names

- ZOH is expanded at its first use in §10.4 ("zero-order hold (ZOH)"), in a
  sentence that already points to §10.5.
- `localization_budget` gets a pointer to "The localization budget" below at
  its first use.
- ITP and AD stay unexpanded. Neither the old text nor the log (D-018 says
  only "ITP/Brent" and "Newton/AD") nor the spec says what they stand for.
  Track 2 or the owner should supply the expansions (ITP: the
  interpolate-truncate-project bracketing method; AD: automatic
  differentiation).

## Open questions

None.
