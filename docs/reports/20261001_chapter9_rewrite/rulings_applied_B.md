# Rulings applied to units B, C, D and E — 2026-10-01

The owner's accepted rulings from groups 2 and 5 of `rulings_batch.md`, applied
to `units/{B,C,D,E}/new.md`. Lines are the `new.md` lines after the edits.
Each changed claim in the unit's `inventory.json` carries the new span, tag
`R` and `"ruling"`. New wording is listed under `added`. The inventory edits
are scripted in `units/<U>/rulings_batch_<U>.py`. The pre-edit files are kept
as `units/<U>/new_preR.md` and `inventory_preR.json`. `checks/check9.py check`
prints `checks failed: 0` for B, C, D and E.

## Unit B (§9.3)

**R23**, B 9–10, claim B-003.
- Before: "**The nominal [activation](#g-activation) probes every user function
  once**, at the initial state, with real values ([D-050][d-050])."
- After: "**The nominal evaluation probes every user function once, at the
  initial state, with real values** ([D-050][d-050])." The `g-activation` link
  had no other use in §9.3 and is gone.
- Source: spec 3517–3536 (the nominal evaluation runs the stage probes); D-050
  Position, "All user functions … are probed once, at the initial state and
  nominal `T`."

**R25**, B 24–26, claim B-013.
- Before: "The stage-1 hand-down, `y_x` and `y_s` on the discrete tier, comes
  from …"
- After: "The stage-1 hand-down, `y_x` on the continuous tier and `y_s` on the
  discrete, comes from …"
- Source: spec 683–691 ("# continuous component … y_x = y_state(…)"; "#
  discrete component … y_s = y_state(…)"); spec 734, "`y_x` / `y_s` | stage-1
  ports exist, under the tier's own spelling".

**R60, "the probing scalar"**, B 35–36, claim B-023.
- Before: "… allocator** at the probing scalar, before the nominal evaluation's
  probes …"
- After: "… allocator** at the probing scalar (`Float64` at build), before the
  nominal evaluation's probes …"
- Source: spec 3530–3534 (workspace "allocated at the probing scalar"; "Stage-1
  probes run at `Float64`"); spec 3420, the steps table's nominal evaluation
  probes "at `Float64`"; D-115 Position (at the probing scalar before the
  Stratum B probes). At activation the allocator is re-invoked at `T` (spec
  3921–3922), which is why the gloss says "at build".

**R60, `RQuat` gloss**, B 56–57, claim B-032.
- Before: "`RQuat()` is the identity, and …"
- After: "For the rotation-quaternion type, `RQuat()` is the identity, and …"
- Source: spec 1504, "Domain wrapper types (`RQuat`, `Ranged`) … An attitude
  state is an `SVector{4,T}`, cast where rotation semantics are wanted"; spec
  1577–1578 and 3097, the cast `RQuat(x.q, normalization = false)`.

**R60, branch-shape pointer**, B 76, claim B-041 (newcites adds §8.3).
- Before: "… banned by the branch-shape rule."
- After: "… banned by the branch-shape rule ([§8.3][s8-3])."
- Source: spec 2651–2653, "**Branch-shape rule.** Stage returns must have the
  same `NamedTuple` shape on every branch", inside §8.3 (spec 2612–2668). This
  is the first of the two uses in §9.3. The second (B 106) stays bare.

**R24**, B 86–88, claim B-051.
- Before: "`Δt` in seconds does not exist until `Simulation` binds `Δt_base`,
  since deployment post-dates the build."
- After: "`Δt` in seconds does not exist until the `Deployment` constructor
  binds `Δt_base`, since deployment post-dates the build."
- Source: spec 3575–3579, the `Deployment` constructor "binds the grid
  parameters"; spec 3502, "binding `Δt_base`, which is deployment's"; D-254
  Position bullet 1, "`Deployment` is the build plus `h`, `N_base`, `Δt_base`
  …".

**R49**, B 117, claim B-066.
- Before: "Three habits of shipped code have sanctioned spellings:"
- After: "Three habits of shipped landing-gear code have sanctioned spellings:"
- Source: D-142 Rationale, "Three patterns in shipped `landinggear.jl`". No
  package is named.

**R52, strut**, B 120–121, claim B-068.
- Before: "A strut throwing on a touchdown overload is one such check."
- After: "A landing-gear strut model that throws on a touchdown overload is one
  such check."
- Source: D-142 Rationale (i), "`GroundCrash` thrown on `α_ts`/`ξ_dot`
  thresholds" in `landinggear.jl`.

**R52, surface kind and friction coefficients**, B 129–132, claim B-075.
- Before: "… `else error("unrecognized surface type")` over a closed enum, or a
  coefficient constructor asserting an ordering of its arguments when …"
- After: "… `else error("unrecognized surface type")` over a closed enum of
  ground-surface kinds, or a friction-coefficient constructor asserting an
  ordering of its arguments (static ≥ dynamic) when …"
- Source: D-142 Rationale (iii), "`error("Unrecognized surface type")` (`:191`)
  and the `@assert μ_s >= μ_d` / `@assert v_s < v_d` `FrictionCoefficients`
  constructor asserts".

**R52, contact algebra (B 123–125): no edit.** The batch drafts no wording for
it. With R49, the list's lead-in now says the code is landing-gear code, which
gives "their own contact algebra" its setting. D-142 Rationale (ii) calls it
"the author checking their own damper-rate cancellation algebra"; adding that
phrase would add a detail the old text lacks.

Line wrapping in the touched B paragraphs was reflowed to 80 columns. No
words changed in the reflow.

## Unit C (§9.5)

**R26**, C 64, claim C-033.
- Before: "The economics' one baked type test is resolved by dispatch rather than
  executed ([D-235][d-235])."
- After: "The check's one baked type test is resolved by dispatch rather than
  executed ([D-235][d-235])."
- Source: D-235 Rationale (log 8540–8541), "This is [D-053][d-053]'s one baked
  type test resolved by dispatch". The other reading R26 confirms, "the
  payload's diff" (C 70), needs no edit.

**R53**, C 45–46, claim C-024.
- Before: "The following two are the same return."
- After: "The following two are the same return, of a shaft's power `P` and
  torque `M_shaft`."
- Source: spec 2129–2136, the `Engine` example:
  `M_shaft = … torque_law(eng, u.throttle, x.ω)` and `P = M_shaft * x.ω`. The
  quoted message at C 77–78 stays verbatim (R9).

## Unit D (§9.6)

**R51**, D 11–14, claims D-006 and D-019.
- Before: "… seeded through the `T`-generic assignment math for exact residual
  Jacobians ([§14.7][s14-7])."
- After: "… seeded through the `T`-generic assignment (the user's function from
  decision variables to a condition) for exact residual Jacobians
  ([§14.7][s14-7])."
- Source: spec 9749, "`condition` is the condition-valued function over
  decisions"; spec 9800–9802, "The assignment is the pure
  `trim_condition(ac, params, d)` fragment-tree function". Departures from the
  proposed text: the `condition` link is not repeated, since D 9 already links
  it (R4), and the existing `[§14.7][s14-7]` covers the gloss, so it is not
  cited twice. The word "math" goes, as in the proposal.

**R47**, D 24–25, claim D-016.
- Before: "Gather and scatter over the canonical layout replace the hand-written
  `get_x_ss`/`assign_x_ss!` layer."
- After: "Gather and scatter over the canonical layout replace the hand-written
  per-aircraft state-space mapping layer."
- Source: spec 1583–1585, "The hand-written per-aircraft state-space mapping
  layer (`get_x_ss`/`assign_x_ss!`/`get_u_ss`/...) is deleted, replaced by the
  framework's canonical layout." The two names remain in §7.1 there.

## Unit E (§9.7)

**R56**, E 56–58, claim E-025.
- Before: "The `x_deriv` block (the [RHS](#g-flow) body the stepper calls per
  stage evaluation) and the `s_update` block are order-free with disjoint
  writes."
- After: "The `x_deriv` block is `rhs`, the [RHS](#g-flow) body the stepper
  calls per stage evaluation. The `s_update` block is `ticks`. Both are
  order-free with disjoint writes."
- Source: Appendix B, spec 11076–11079, "the four blocks (`rhs`, `sweep_1`,
  `sweep_2`, `ticks`) … `ticks` taking the tick index"; glossary 12101–12105;
  D-116 Position; D-196 Position (`sweep_hx` → `sweep_1`, `sweep_hxu` →
  `sweep_2`). `rhs` = the `x_deriv` block is stated at old spec 4301 (E 167).
  `ticks` = the `s_update` block holds by elimination: §9.7 lists the stage-1,
  stage-2, `x_deriv` and `s_update` blocks plus guards and handlers as their
  own callables, and the roster's other three bodies are the two sweeps and
  `rhs`. No sentence in the spec or log states `ticks` = `s_update` outright.
  The proposal's two parentheticals became short sentences, to keep one
  parenthetical per sentence.

**R55**, E 75–77, claim E-035 (newcites adds §10.4).
- Before: "**`t*`'s empty due set is arity selection**, not an index trick
  ([D-147][d-147], [D-185][d-185])."
- After: "**At a localized event time `t*` ([§10.4][s10-4]), the empty due set
  is arity selection, not an index trick** ([D-147][d-147], [D-185][d-185])."
- Source: spec 4500–4501 (§10.4), "The localized event time `t*` is a
  boundary". Bold as proposed.

**R57 (CSE only) and R58**, E 103–107, claim E-070.
- Before: "CSE merges repeated loads exactly where no intervening store
  invalidates them, which is precisely the staleness rule, and the
  sweep-varying bundle fields (`u`, `y_x`/`y_s`) are per-call by topological
  necessity either way ([§7.1][s7-1])."
- After: "Common-subexpression elimination (CSE) merges repeated loads exactly
  where no intervening store invalidates them. That is precisely
  [§7.1][s7-1]'s buffer-unchanged-within-a-sweep rule. The sweep-varying
  bundle fields (`u`, `y_x`/`y_s`) are per-call by topological necessity
  either way ([§7.1][s7-1])."
- Source: spec 1543–1546 (§7.1), "hoisting a repeated read is the code
  generator's CSE. The legality condition of that CSE is exactly the
  buffer-unchanged-within-a-sweep rule". CSE's expansion is the standard
  compiler term. The sentence was split so it carries one parenthetical per
  sentence. SROA and TTFX sit in the frozen block and are deferred (R29).

**R28**, E 183, claim E-089.
- Before: "The seam makes one promise, and it is diagnostic only
  ([§13.5][s13-5])."
- After: "The seam is diagnostic only ([§13.5][s13-5]), and it makes one
  promise."
- Source: Appendix B, spec 11083–11084, "It is an inspection-only surface, and
  its one promise is identity with what the loop runs."

**R48**, E after 199 (sentences removed), claims E-099 and E-100.
- Before: "This is the successor of the migration suite's `@ballocated
  f_ode!`/`f_step!`/`f_periodic!` idiom. It is also the seam the FlightCore
  comparison in `migration_outline.md` measures through."
- After: both sentences removed from §9.7.
- E-100 maps to `docs/design/companions/migration_outline.md` 37–40, which
  already says it: "Zero-alloc stepping is measured through the `phase_bodies`
  seam ([§9.7][s9-7]), apples-to-apples with today's `@ballocated f_ode!`
  suites."
- E-099 is not fully stated there: the outline names only `f_ode!`, and not
  the successor relation. It maps to `units/E/migration_addition.md`, to be
  appended to the end of the outline's "Comparison criteria" paragraph (after
  line 40): "The per-body CI assertion over the `phase_bodies` roster
  ([§9.7][s9-7]) is the successor of the migration suite's `@ballocated
  f_ode!`/`f_step!`/`f_periodic!` idiom."
- Source: old spec 4324–4330 ("CI is warm-then-assert over the roster … at
  per-body granularity … This is the successor of …"); D-116 Position ("CI is
  warm-then-assert at per-body granularity").

## Not applied in these units, by the owner's resolution

- R27: both citations stay. The D-053 annotation is a log item.
- R29 and R57's SROA and TTFX: deferred to the compile-time ruling. The frozen
  block is untouched.
- R43 and R46: no edit.
