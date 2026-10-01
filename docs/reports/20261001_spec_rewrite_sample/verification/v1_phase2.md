# Phase 2: §9.4 no-loss check

**Counts (79 inventory items):** MATCH 71, DRIFT 8, LOST 0. Declared ADDED 6. Undeclared ADDED 4 groups. AMBIGUITY 4.

## DRIFT

- **c22, causal link dropped.** Old: "guards and handlers never run, **because** event localization is `Float64` sweeps by design (§10.4)". New: two freestanding sentences (N25, N26). The reason guards don't run at `Dual` is gone, and §10.4 now covers only the sweep fact.
- **c28, causal link added.** Old: appositive "a whole-model run at the tracer scalar, an activation like any other". New: "...and **so** an activation like any other". This is harmless but not in the old text.
- **c16/c17, citation scope.** Old: D-253 closed one sentence covering both the `T`-independence of `Structure`/`Outputs` and the "no order/name list changes" claim. New: D-253 attaches only to the "So no execution order..." sentence. D-253 ("No product changes across activations") backs the first half too.
- **c38, citation scope.** Old: "A pinned `Float64` (§7.2), whether hidden in a constructor or declared `Pinned` at a leaf..." The §7.2 citation and "pinned `Float64`" covered both cases. New: "A pinned `Float64` (§7.2) may hide in a constructor." The citation now covers only the constructor case. The leaf case no longer says it is a pinned `Float64`.
- **c41, antecedent and link.** Old: "pins **the invariant instead**". New: "enforces **genericity**". "Instead" (contrast with the uncertified `build`) is gone. The invariant also covered misplaced pins (spec §8.2 l.2470, "Both lurks are contained by policy"), so "genericity" is narrower. New also adds a **Rule.** marker here.
- **c47, strength.** Old: "with no synchronization on any path" (a fact: none happens). New: "no path needs synchronization" (none is required). That reading leaves room for an unneeded guard.
- **c59, agent assigned.** Old passive: "buffers, materialized from the cached layouts at construction". New: "**It** [the `Simulation`] materializes them". The old text named no agent.
- **c32, heading (X).** Old: "opt-in exhaustive mode". New: "all at once on request". The exhaustive mode materializes the listed set (`(Float64, ProbeDual)`), not "all" activations. Glossary l.12045 and D-275 call it "the exhaustive set" and the mode "opt-in".

## Undeclared ADDED

- **N48:** "The exhaustive mode does it:". The term "exhaustive mode" now has no introduction because the old heading that defined it is gone.
- **c09:** "`x_init`'s" became "`x_init`'s **leaves**". The old text, still live at spec l.3919, is truncated. The repair fits §8.2 ("The type derived from `x_init` is walked"), but the inventory doesn't flag it.
- **Structure:** three new h4 headings besides c32, the bold labels "What the cache saves." and "What it does not save.", and the list count "five things".
- **Markers:** new **Rule.** on c02, c33 and c41. New **Why.** on c24, c34 and c78. New **Example.** on c19. Old bold existed only on c18, c42, c53, c58 and c74, plus c74's "normatively".

## AMBIGUITIES

- **A1 (c19–c23):** Under **Example.**, the claims that discrete stages are gated off, guards never run, and only `y_state`/`y_direct`/`x_deriv` are probed at `Dual` can read as illustrative. In the old text they applied the bold rule directly.
- **A2 (c79):** The **Why.** marker covers "Torn state is excluded by contract", which restates the rule. It reads as explanation, not norm.
- **A3 (declared ADDED N1):** "The build types the model once, at `Float64`" conflicts with the exhaustive mode, where `build` also types at `ProbeDual`. It holds only for a default build (D-253: Stratum B returns the nominal activation; others are lazy).
- **A4 (declared ADDED "Nothing structural moves"):** `Outputs` is the nominal evaluation's product, not a structural one. "Structural" may read as covering `Structure` only. D-253's "No product changes" is the accurate scope.

Checked and fine: c29/c30 against D-012 ("global + sampled-local" tracers; "schedule-free per-member local trace"), and N3 against glossary l.12036.

Sources: spec.md §8.2 (l.2470–2486), glossary l.12036/12045; decisions.md D-012, D-253, D-275.
