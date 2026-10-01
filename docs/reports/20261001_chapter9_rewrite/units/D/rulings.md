# Unit D (§9.6): rulings

## Corrections proposed

None found in §9.6's facts. The two part F items:

- F18 (Flight.jl names and "today's" in normative text, 4144–4175). Resolved
  by M13, within the ranges the brief gives. `get_x_ss`/`assign_x_ss!` (4166)
  stays in the spec. It lies outside M13's ranges, and §7.1 (spec 1584) names
  the same layer as deleted. Proposal, if the user wants §9.6 free of Flight.jl
  names: replace "the hand-written `get_x_ss`/`assign_x_ss!` layer" with "the
  hand-written per-aircraft state-space mapping layer", §7.1's wording.
- F19 (the activation gloss sat on the term's second use, 4151–4152). Applied,
  as a glossary-placement fix and not a change of claim. The link and the
  gloss now sit together on the first use, in the context paragraph.

## Citations added or replaced

- D-070, on "A failed trim leaves the simulation's stores untouched" (§9.6,
  second bullet). Position bullet 2: "Scratch store sets are instantiated per
  invocation from activation layouts … while authoritative stores have exactly
  one writer, the commit through boundary zero." Rejected: "*Iterating on the
  nominal activation's singleton buffers:* aliases the sim's authoritative
  stores — warn-but-assign reborn." The sentence states a consequence of that
  Position, so it carries the citation plain, not bold (see Open questions).
- D-139, on the `atmosphere::Model` respelling, in `companion_addition.md`.
  Rationale (log 4400): "§9.6's "`Kinematics.Initializer` … survives
  untouched, aircraft-side" is **corrected**: it survives aircraft-side with
  its `atmosphere::Model` argument respelled as a field handle (built at value
  level per §4.4, or held as a rig slot value)."
- Section pointers added, as the brief asks: §14.8 and §14.10 in §9.6; §9.6,
  §14, §14.7 and §14.8 in the companion section. §14.7 holds "The assignment
  is the pure `trim_condition(ac, params, d)` fragment-tree function". §14.8
  holds the service loop and "No commit means the sim is bit-for-bit
  untouched". §14.10 holds gather/scatter, the `get_x_ss` deletion and the
  zero-partial discrete tier.

No superseded entry was cited, and none is now.

## Rationale-only rulings

- D-139, Rationale, log 4400: the initializer's `atmosphere::Model` argument
  becomes a field handle (survey row 125). It now lives in
  `companion_addition.md`, not in the spec. If the spec should still state it,
  §14.7 or §14.9 is the place, and it would need an entry with a Position.

## Inbound citations affected

- D-139 Spec field (log 4371) lists §9.6. After M13 §9.6 holds nothing of
  D-139, so the field would drop §9.6 (survey part D; needs the ruling on
  whether Spec-field edits cover moved content).
- D-139 Rationale (log 4400) corrects §9.6's `Kinematics.Initializer` claim.
  It stays as history (`decisions_style.md` rule 1).
- `trim_environment_walkthrough.md` 502 ("§9.6 keeps per-residual scalings
  aircraft-side") now points at content in `flight_case_studies.md` section 4.
  Proposed retarget: that section, or §14.7 ("The FlightCore formulation's core
  is correct and survives verbatim as user math").
- `trim_environment_walkthrough.md` 6 (§9.6 as ground truth) and 576 (the
  `Initializer` correction): same retarget, or leave as history.
- Spec 9161 ("§9.6 previewed the services as activation clients"), D-259
  Position (log 9730, "§9.6's heading"), D-259 Spec field and
  `implementation.md` 756: unaffected. Heading and activation gloss stay.
- Spec 9866 (§14.7) cites §9.6 for "nonlinear least squares … in the
  trust-region/Levenberg–Marquardt family". §9.6 never stated least squares
  or the LM family, only the `Dual` default with exact Jacobians. This is
  older than the rewrite. Proposed: cite §14.8, which names the in-house dense
  LM default.

## Open questions

1. Zero bold. Survey part A counts two rules in §9.6. Row 125 (D-139, R)
   moved to the companion. Row 126 ("A failed trim leaves the simulation's
   stores untouched", D-070, U) states a consequence of D-070's Position, not
   the Position itself, so the convention keeps it plain. If the user reads
   it as the ruling, make it bold with D-070.
2. M13's ranges cut through two framework statements. Line 4154 opens with
   "only the assignment's *output* is framework vocabulary", which is not a
   comparison. It stays in §9.6. Lines 4171–4175 are the whole third bullet,
   but the brief also wants a bullet pointing at §14.8. Only the comparisons
   moved ("replaces today's per-aircraft NLopt plumbing", "an improvement over
   today's warn-but-assign `f_init!`"). The loop's parts and the failed-trim
   sentence stay in §9.6. The companion repeats the failed-trim sentence for
   context.
3. Bullet order changed from trim, linearization, service loop to trim,
   service loop, linearization, so the pointers run §14.7, §14.8, §14.10. No
   claim changes section.
4. M12 merged rather than deleted outright. The duplicate (4169–4170) added
   "through the `T`-generic assignment math", which the first statement
   (4149–4150) lacked. The merged sentence keeps it, so nothing is lost.
5. The brief asks for bullets that are "each an activation". The service-loop
   bullet names no activation, because the old text names none for it.
6. Glossary links `#g-face`, `#g-field-handle` and
   `#g-value-level-constructor` leave §9.6 with the content M13 moves. The
   companion uses no glossary links, so they are dropped.
7. The companion's opening roadmap names sections 1 to 3. Proposed addition
   after its "Section 3 reads …" sentence: "Section 4 reads today's C172 trim
   against the stopped-sim services." Its link definitions for `s9-6`, `s14`,
   `s14-1`, `s14-7`, `s14-8`, `s14-9`, `s4-4` and `d-139` come from
   `linkify.jl`.
