# Unit E2: rulings and findings

Rulings applied: R6 (the five labels of survey part C, in its order) and R7
(F9, F10). The F9 comment on `u_types(::IMUSampler)` sat on two lines; it is
now one comment, "discrete tier: bound check only", on the first line.

## Corrections proposed

- Ruled in as R12 and applied (E2-046, tag R). The text now reads "`Δt`
  arrives in the stage bundle (…) from its single source of truth, the
  deployment's `Schedule` ([§10.5][s10-5])". The original proposal follows.
- Old 3123–3125: "`Δt` in the stage bundle … is the [§10.5][s10-5] single
  source of truth". §10.5 (spec 5505–5508) says `Δt` "has a single source of
  truth, the deployment's `Schedule`", and the bundle field is where it
  arrives. Kept as written ("is the single source of truth ([§10.5][s10-5])").
  Proposed: "`Δt` arrives in the stage bundle from its single source of truth,
  the deployment's `Schedule` ([§10.5][s10-5])."

## Citations added or replaced

- D-056 at "Every interval-relative integral becomes a *cumulative* one"
  (bold). Position bullet 1: "The idiom is integrate-and-difference:
  cumulative integrals in `x`, previous-sample latch in the sampler's `z`."
- D-056 at the exactness condition (bold). Position bullet 2: "It is exact
  whenever interval-dependence is a left action by the interval-start value of
  a cumulatively-integrable quantity".
- D-056 at "the cumulative attitude must be integrated with the *inertial*
  rate" (bold). Position bullet 2: "(inertial-rate anchoring required; …)".
- D-056 at "the equivalence survives discretization" (bold). Position bullet
  2: "RK-exact by linearity of the kinematics". Bullet 2's parenthesis chains
  two items with a semicolon, so by the one-bold test the condition and the
  two items take one bold each.
- D-056 at "That knowledge must be part of the framework's taught contract"
  (bold). Position bullet 5: "Boundary-sampling semantics are promoted to
  taught contract."
- D-056 at "When the coupling is genuinely two-way, the latch becomes a wire
  back" (bold). Position bullet 3: "A latch-back wire — a feedthrough-stage ZOH
  latch — carries interval-relative flow terms."
- D-067 at "There the sampler's due `s_update` … latches `s ← integrals(t₀)`"
  (no bold; §14.5 states the ruling). Position: "Boundary zero is the §10.6
  macro-sequence run with an empty integrate: … → due `g` updates → …";
  bullet 1: "the update at `t₀` is the `t₀` sample's only chance". The
  annotation (due set at boundary zero is the `Φ = 0` components) holds for the
  sampler, whose entry is `Relative(1)`.
- §7.1 in the new paragraph introducing the code's names. Spec 1504–1505:
  "Domain wrapper types (`RQuat`, `Ranged`) are not state leaves. An attitude
  state is an `SVector{4,T}`, cast where rotation semantics are wanted".
- §7.2 in the same paragraph. Spec 1620–1622: "**Walked**, the payload and
  value types constructed during evaluation … `FrameTransform`".

## Rationale-only rulings

None.

## Bold on the same entry elsewhere

- §3.4, spec 414: "**Algebra removes the reset.** Every interval-relative
  integral becomes a cumulative one, and a discrete sampler differences
  consecutive samples against its latch." This is D-056 bullet 1, bold here
  too. §3.4 is not yet rewritten and uses a bold lead-in; it points to §8.6
  for the idiom, so §8.6 should keep the bold.
- Coordinator ruling: §8.6 keeps D-056's first-bullet bold, and §3.4's
  lead-in is that chapter's business. All six D-056 bolds stay, "the
  equivalence survives discretization" included. Listed for the rulings
  batch.
- No other unit's `new.md` bolds a claim citing D-056 or D-067.

## Inbound citations affected

None retarget. The rows relying on this unit stay true: spec 406 and 416
("the differencing idiom", "its exactness condition"), 10138 and log 1883
(D-067, "the boundary-sampling line"), 11091 ("The IMU's boundary-sampling
note"), 11117 (Appendix A, the worked example), 13142 (glossary *worked*),
log 2111 (D-073). The labels "The exactness condition" and "The
boundary-sampling contract" keep the names they use.

## Open questions

- Reader-cold names (F16). "The direct formulation" now takes one
  introducing sentence from §3.4 at its first use. The code's `RVec`,
  `Attitude.dt` and `IMUSample` have no source in the spec. Their glosses
  rest on the code alone (`Attitude.dt` builds the `q` derivative, `RVec(Δq)`
  fills the sample's `ϑ_c_cc`, `IMUSample` is the type of the `sample`
  output). The
  owner may prefer to name their library or move them to a companion.
- Glossary links dropped because unit E1 uses the term first in §8.6:
  `#g-assembly`, `#g-tier`, `#g-worked` (E1 links them) and `#g-port`,
  `#g-component` (E1 uses them, and its current `new.md` links neither). If E1
  does not link port and component, §8.6 has no link for either.
- `#g-boundary` is linked here although E1 uses "boundary" in the assembly
  sense (`u_connections`/`y_connections`), which is not the glossary's
  time-boundary sense.
- The `K = 1` gloss reads E1's IMU block (`sample_times(::IMU) = (sampler =
  Relative(1), …)`). If E1 changes that block, the gloss follows it.
