# Unit B (§7.2): rulings, citations and open items

## Corrections proposed

None new. Applied as ruled: F6 (R8), "Every declaration but the allocator
([§7.3][s7-3]) is written at nominal `Float64`" (old 1610–1611; D-263 Position
bullet 4); F9 (R8), "the compositions in use" → "the compositions in
Flight.jl's tables" (old 1640). The other two F9 instances (1628, 1647) and
`attitude.jl` (1651) left with R2's moves.

Touched and left as written, per the brief:

- F11, "fails loudly … on any Float64-pinning" (old 1602–1603). The sentence
  was split to move the `MethodError`/`InexactError` parenthetical out; "on any
  Float64-pinning" is unchanged and not sharpened.

Applied after step 4:

- R13: "and need no migration" (old 1633) moved to `companion_addition.md`
  ("Flight.jl's parameters and definitions, the pinned tier of §7.2, stay
  `Float64` and need no migration"). §7.2 keeps "stay `Float64`" and
  "promotion handles mixing" word for word.
- R12: "One example is `FrameTransform`, a FlightPhysics payload type."
- R11: only the Walked label links `#g-walked`; the Pinned label and the
  `Pinned{P}` "pinned" lost their links.

## Citations added or replaced

- D-011 at the bold headline (row 24). Position: "Eltype genericity on the
  continuous path, three-tier scoping."
- D-280 at consumer 4. Position: "The repository's test suite builds a `Dual`
  activation of every component … Linearizability is an invariant held by this
  policy."
- D-072 at "not a limitation but the exact answer" (row 26). Position bullet 2:
  "unseeded states stay constant, the discrete tier frozen-exact." `[d-072]` has
  no reference definition in `spec.md` yet; linkify adds it.
- D-263 and D-295 at the continuous-tier walk sentence and at "pins wholesale".
  D-263 bullet 1: "On the continuous tier `input_types` and `output_types` are
  walked … A leaf wrapped as `Pinned{P}` is pinned … On the discrete tier the
  declarations pin wholesale". D-295 bullet 4: "The type derived from `x_init`
  walks, and `m_init` and `s_init` pin wholesale." D-295 is not cited for "no
  pinned state leaf".
- D-263 alone at the `Pinned{P}` sentence (bullet 1, as above).
- D-032 at "Nothing anywhere comes from inference through user code". Position:
  "schema authority — declarations define, probe evaluation checks".
- D-079 beside D-032 at the same sentence. Rejected (log 2364–2365):
  "*Probe-inferred participation:* inverts declarations-define-probes-check;
  one probe point cannot speak for branch-dependent participation." D-079 is
  ratified, not superseded. Listed under Rationale-only below.
- D-011 at the lookup rule: the rule applies D-011's tiers; no entry states it.
- D-266 at "the pattern for wrapping non-Julia black boxes". Position bullet 1:
  "A component that must participate in differentiation keeps its entry
  tolerant and supplies its own local derivative inside the stage … rebuilding
  the output by the chain rule".
- D-011 and D-235 at "Three rules are author-facing". D-011 for the genericity
  they protect; D-235 Rejected for "an authoring rule" (below). No entry states
  the three rules; they stay plain.

Not added: D-238 at the embedding-guarantee pointer (row 32). Its Position
decides embed-accept on the type, not the safety claim; the pointer to §9.5
carries it. D-070 at `Cubic` (optional in part E): its bullet is the C172
audit's preference, narrower than the general guidance.

## Rationale-only rulings

- D-011, Rejected, log 502–503: the four consumers (FD noise, the hand-written
  state-space layer, no tracer).
- D-263, Rationale, log 10309–10312: "the pin is on the page, per leaf", for
  "Participation is therefore authored per leaf".
- D-235, Rejected, log 8751: "Type stability under `Dual` is an authoring rule
  (§7.2), not a conformance predicate", for the three author rules.

- D-079, Rejected, log 2364–2365: probe-inferred participation, for
  "Nothing anywhere comes from inference through user code".

## Bold on the same entry elsewhere

One bold: "The entire continuous evaluation path is generic over `T <: Real`"
(D-011). No other bold cites D-011 in chapters 8–10 or in units A, C and D's
`new.md`. The lookup sentence and the third author rule lost their bold: no
entry states them.

## Inbound citations affected

- spec 3258 (§8.6): "`FrameTransform` is one of the payload types §7.2 lists as
  walked". Holds: the Walked tier keeps `FrameTransform` as its example.
- `extensions.md` 294: the `@kwdef` pattern sentence. Holds, verbatim.
- `extensions.md` 334: "§7.2's mechanical parametrization of the walked payload
  list". The list moved to `migration_outline.md`; §7.2 keeps "Their
  parametrization is mechanical". Retarget at landing to the outline, or reword
  to "§7.2's walked tier".
- `extensions.md` 220, 278 ("stay `Float64`", "promotion handles mixing"),
  283 (the return-annotation rule), spec 2540 ("the CI invariant"): hold.
- spec 2467, "the discrete exemption (§7.2)": the old text never used that
  exact phrase ("the *discrete* side's exemption"); kept as written, holds in
  substance.
- `migration_outline.md`: `companion_addition.md` joins "The parametrization
  pass" (line 30). The table row "The walked-leaf parametrization pass" (line
  16) names `Ranged` only; its disposition may want "and FlightPhysics'
  walked payload types" at landing. The outline has no `[s7-2]` reference
  definition; linkify or the lander adds one.

## Open questions

- "roughly half the type inventory": moved to the companion only, as
  Flight.jl's inventory. R2 allowed keeping it in §7.2 too; dropping it there
  removes a reader-cold claim and leaves "Scoping … has three tiers".
- Settled by R11: the Walked label alone links `#g-walked`.
