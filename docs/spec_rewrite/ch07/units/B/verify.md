# Unit B (§7.2): cold verification

## Counts

- 57 phase-1 assertions (`verify_phase1.md`). 47 inventory claims: 47 MATCH, 0 DRIFT, 0 LOST. 8 claims sit in `companion_addition.md`, and each span there says the same thing.
- ADDED with no meaning change: the roadmap sentence, the `@kwdef` gloss (R2), the Interpolations.jl clause (R2), "One example is" (R2) and "the leaf marker". The glosses on buffer, sweep, cell and activation also carry no meaning change. They match the glossary entries but are missing from the inventory's `added` list.
- `check_unit.py`: 0 failures.

## Hazards

- **Companion.** Written as Flight.jl's work and claims nothing beyond the old text. "The pass also parametrizes FlightPhysics' payload and value types" is the framing R2 orders. "Roughly half" is kept there as "roughly half of Flight.jl's type inventory" (C-020). Landing note: `migration_outline.md` has no `[s7-2]` reference definition, so add one.
- **M5.** Done. The tiers now come before the exemption paragraph and the per-leaf paragraph, so *pinned* is defined before its use at 47–50. "This scoping" (41) refers back two paragraphs, which is acceptable.
- **F11.** Not sharpened. Only the parenthetical was split into its own sentence.
- **F6 and F9.** Applied as ruled.
- **Two senses of *pinned*.** They stay distinct (the italic tier label against the `Pinned{P}` leaf). There are three `#g-walked` links (Walked, Pinned, pinned). The old text also had three (Walked, Exempt, pinned). The glossary entry bolds three names. `spec_style.md` (Terms) allows only the first link per section, so its rule conflicts with the brief, which orders "both link". This needs an orchestrator ruling. The fix under `spec_style.md` is to keep only the Walked link.

## Citations

All the old citations survive (§5.6, §8.2, §9.5, D-011). I checked each added or replaced citation against `decisions.md`:

- D-011 at the headline: Position carries it. The minor issue is its reach. The same sentence covers the buffer and pack/unpack, which D-011 does not name. Holds as part of "the continuous path".
- D-280 at consumer 4: Position carries it.
- D-072 at the exact answer: Position bullet 2 ("the discrete tier frozen-exact") carries it. `[d-072]` has no reference definition in `spec.md`, as noted.
- D-263 and D-295 at the walk sentence and "pins wholesale": D-263 bullet 1 and D-295 bullet 4 carry them.
- D-263 at `Pinned{P}`: carries it.
- D-032 at "nothing from inference": carries it only through "declarations define, probe evaluation checks". D-079 Rejected ("Probe-inferred participation") is the more direct source. Acceptable.
- D-266 at the black-box pattern: bullet 1 carries it.
- D-011 at the lookup rule and at the author rules: an application of the tiers, not a statement of either rule. The survey's U reading supports it.
- D-235: the Rejected text carries it. It is correctly listed as rationale-only.

## Bold

There is one bold: the headline clause, with D-011 cited in the same sentence. The old bolds on list labels, mechanism, the lookup sentence and the third rule are all gone, and so is the **Rule.** label. No ruling is stated twice in bold.

## Moves

M3, M4 and M5 are done. R2's `FrameTransform` example and pattern sentence stay in §7.2. "Roughly half" moved to the companion only. This goes past M3's listed span, but it is allowed by the brief's conditional and noted in `rulings.md`. I agree with the proposal in `rulings.md` to move "need no migration". It is Flight.jl's migration and reads cold in §7.2. There are no other moves.

## Reader-cold names

- `FrameTransform` (line 26), class (1). The spec defines it nowhere, and §8.6 only points back to §7.2. Fix: add "One example is `FrameTransform`, a FlightPhysics payload type". The companion supports that clause.
- `frozen_discrete_walkthrough.md`: a companion file named bare, as in the old text. Optional fix: add "the companion".
- Flight.jl: introduced in the spec at line 185, so it is fine.
- The other names are ordinary Julia or package API, which is fine: ForwardDiff, `Dual`, `SVector`, Interpolations' `BSpline`/`scale`/`extrapolate`/`Linear`/`Cubic`/`gradient`.

## Re-check (after R11–R13 and D-079)

Result: PASS on content. `check_unit.py ch07 check B` reports 0 failures.
Two nits remain, neither a drift.

- R11: done. The section keeps one `#g-walked` link, on Walked. The tier
  (*Pinned*) and the leaf ("deliberately pinned", `Pinned{P}`) stay distinct.
- R12: done. "a FlightPhysics payload type" claims no more than the companion
  and spec 3257 support.
- R13: done. §7.2 keeps "stay `Float64`" and "promotion handles mixing" word
  for word. The companion's "Flight.jl's parameters and definitions, the
  pinned tier of §7.2, stay `Float64` and need no migration" matches old 1633
  in Flight.jl's voice (C-031 MATCH).
- D-079: the citation is right. The entry is ratified, has no supersession
  annotation and has a reference definition in `spec.md`. Its Rejected bullet
  ("Probe-inferred participation: inverts declarations-define-probes-check")
  carries "nothing from inference" for participation. D-032 covers schemas.
  Correctly listed as rationale-only.
- Inventory: updated (C-029 R11, C-030/C-031 split, C-024 R12). The glosses
  are now in `added`.
- Nit 1, the antecedent of "Their" (new.md 26–27). Placed right after "a
  FlightPhysics payload type", "Their parametrization is mechanical" can be
  read as FlightPhysics' types instead of the walked tier. `extensions.md` 294
  and 334 read it as the walked tier. Fix: "The walked types' parametrization
  is mechanical."
- Nit 2, line wrap. new.md line 26 is 101 characters, and
  companion_addition.md lines 8–9 are 101 and 84. Fix: rewrap to 80.
