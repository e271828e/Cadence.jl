# Unit D verify report

**Counts.** 63 inventory claims: 62 MATCH, 1 minor DRIFT, 0 LOST. 83 phase-1 assertions. 7 ADDED: 3 are pointers or transitions, and 2 change meaning.

## DRIFT
- **D-044.** Old: "a documented tolerance, scoped per body by the seam's granularity so it never loosens the continuous assertions" ("it" is the tolerance). New: "The seam's granularity scopes the tolerance per body, so it never loosens…". Here "it" reads as the granularity. Fix: "so the tolerance never loosens the continuous assertions".

## ADDED that changes meaning
1. **§7.4 context sentence.** "Derivatives and outputs often share a computation, and every step below addresses that problem (§5.3)." §5.3 (spec 1024) carries the first clause only. It says overlap is "the *norm*", so "often" understates it. Nothing carries "every step addresses". D-006, step 1's entry, rejects N groups as "declaration/validation surface for a case that never materialized", which says nothing about shared computation. Step 3 (D-016, "double-passing") and step 4 (transport) are not about it either. The brief ordered this wording, but it overclaims, and the §5.3 citation's scope covers a claim §5.3 does not make. Fix: "Derivatives and outputs usually share a computation (§5.3). The four steps below trace how the design came to evaluate them in one fused sweep." Or just drop "every step below addresses that problem".
2. **R5 sentence 2, "that scope".** Its nearest antecedent is sentence 1's "the stepping loop". Publication happens per boundary inside the stepping loop, so the sentence implies that publication is outside the loop. The scope that spec 6420 means by "the §7.5 scope" is what the invariant claims is zero, namely the phase bodies (§9.7, spec 4917: "What the accessor exposes is exactly what the invariant claims is zero"). Fix: "…sits with logging on the framework side, outside what the invariant claims is zero (§11.2)". The rest of R5 holds. "scoped to the stepping loop" and "always allocation-tolerant" are D-135 Rationale's and spec 4406's own words. "stopped-sim" is §14's title, and §14.8 (spec 10777) says "stopped-sim allocation". "Publication is not a phase body" is spec 4916's and D-288's wording. "sits with logging" matches spec 6420's "already carved out logging".

## Citations
All 18 old citations survive with their claims. The §11.2 citation at the remedy moved to the end of its sentence, which is fine. Added citations, checked against the log:
- D-034 Position "declared = public": carries.
- D-015 at the cache-free formulation (Position, and Rejected "mutable caches… purity violation"): carries.
- D-015 at the split being expressible (Position, "not an impossibility claim"): carries.
- D-015 at the measurement (Rejected "2× components/wiring"): carries the halving only. The 4/13 counts come from the prototype, which is acceptable.
- D-014 at "not dogma" (Rejected "Blanket dogma"): carries.
- D-014 at the budget sentence (Position "CI-enforced on the hot path"): carries.
- D-116 at the seam and at the tolerance (Position): carries.
- D-137 Position "retained snapshot references": carries.
- D-135 Rationale and D-288 bullet 6: carry, except the "that scope" problem above.
- §5.3: carries only half its sentence (ADDED 1).

## Bold
One bold: "The budget is exactly zero, CI-enforced", with D-014 later in the same sentence. All old bold lead-ins are gone. No bold sits on mechanism, and no ruling is bolded twice.

## Moves
M8 (R5) and M9 are done. The levers bullet became a closing paragraph, which matches part C's order. No other moves.

## Hazards
- Step numbers 1 to 4 are kept. Step 2 keeps "one-line function body" and step 4 keeps "transport".
- "That decoder" follows "(now `y_state`)", so its antecedent is intact.
- F7, F9 and F10 are applied as ruled.
- "these are the honest levers" follows both tools.
- M9's paragraph matches old. The remedy is kept, and its citation is merged into "(§11.2, D-252)".
- The `f_ode!` gloss "(its in-place derivative function)" is supported. The log (2018) says "mutating `f_ode!`". The case study (22, 81) and §5.3 show that it computes derivatives fused with outputs.
- "the canary" and "a documented tolerance" are verbatim. The `[log](#g-log)` link is kept.

## Reader-cold names
- **(1) Flight.jl machinery:** `f_ode!`, now glossed. Nothing else.
- **(2) Aerospace examples:** "pose", "Newton–Euler solver", "kinematic descriptors", "rigid-body kinematics and dynamics core", "heightmap terrain or wind grids". All were in the old text. "pose" is the only one that might want a clause, such as "(position and attitude)".
- **(3) Predecessor:** FlightCore, fine.
- **Outside the three classes:** "MTK" (ModelingToolkit) and "CSE" are unexpanded acronyms. DWork, FMI and Bumper.jl are external prior art carried from the old text.

## Re-check (after R14–R16)

PASS.

- **D-044.** "so the tolerance never loosens the continuous assertions". The antecedent is now explicit.
- **R14.** Spec 1024 (§5.3) reads "Derivative/output overlap is the *norm* in physical and control models". The new sentence carries that and nothing more. The opening still ties the steps to §5.2.
- **R15.** "One snapshot allocation per boundary" is spec 6420 (§11.2) verbatim, cited by §11.2 at the end of the sentence. "Outside what the invariant claims is zero" is spec 4917 (§9.7), cited by §9.7 earlier in the sentence. "Sits with logging" matches 6420's "already carved out logging". No antecedent problem remains.
- **R16.** §9.7 (spec 4762) spells it "Common-subexpression elimination (CSE)". "ModelingToolkit" is the standard expansion of MTK.
- **Checker.** `check_unit.py ch07 check D` prints `checks failed: 0`. The one `#g-log` link it reports missing is the intended drop of the old duplicate.
