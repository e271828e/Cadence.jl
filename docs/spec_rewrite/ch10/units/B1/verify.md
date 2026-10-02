# B1 verify

**Counts.** 93 phase-1 assertions. 107 inventory claims: 106 MATCH, 1 borderline (B1-027, F14), 0 DRIFT, 0 LOST. Checker: 0 failed. Code sketch and inline math match the old text exactly. All old citations survive with their claims.

## Borderline and meaning-changing ADDED

1. **B1-027 (F14).** Old: "The piston engine's `starting → running` fires on …". New adds "Take a piston engine with the modes `off`, `starting` and `running`, as declared for the `Engine` component in §8.2." The modes match §8.2 (spec 2121), and §8.2's `ignition_guard` is this predicate. But §8.2 never calls `Engine` a piston engine, so the clause equates the two on inference alone. Fix: "Take §8.2's `Engine`, whose modes are `off`, `starting` and `running`; its `ignition` event takes it from `starting` to `running` on …"
2. **ADDED, new 73–75.** "A trial evaluation computes a guard's value at one instant inside the step. Its state is a point on the interpolant …, which the localization loop below builds." This conflicts with the θ = 0 trial (new 131–133), which runs at the step's left end, needs no interpolant and runs before the interpolant is built. Fix: "Its state is x̂(θ), a point on the interpolant (…), or xₙ itself at θ = 0."
3. **Define-before-use (from M10).** `$\hat{x}(\theta)$` at new 79 now comes before its definition (sketch 119, paragraph 171). In the old order it came after. Fix 2 also fixes this.

## Citations

I checked every added citation against the field rulings.md names, and each one carries its claim: D-179 Position and Rationale; D-147 Position; D-082 Position; D-182 Position for the trigger check and the first act, Rationale for the discriminator, the discard and the ẋₙ₊₁ payment; D-018 Position for chained rulings 1 and 2; D-133 Position; D-256 bullet 1 and the constructor bullet; D-154 Position. None is superseded. rulings.md lists the ẋₙ₊₁-payment D-182 citation as Position-free without saying it is Rationale. It is not bold, so this is harmless.

## Bold

There are 11 bold spans. Each is a headline clause followed by its D-entry, and none falls on mechanism, definition or a lead-in.
- **D-147, duplicate across units.** B1's "Trial evaluations run the interior sweep" and C1's "The interior sweep walks continuous entries only" come from the same D-147 Position sentence. Under the reading-order tie-break, B1 keeps the bold and C1 yields. Otherwise B1 yields. Either way, one of them must change.
- **D-018, inconsistent across units.** B1 treats "+" inside a chained ruling as one ruling. So it unbolds "The interpolant is built lazily", which shares chained ruling 1 with root-finding. But B1's "The interpolant is then invalidated" and B2's "Budget exhaustion degrades" both bold chained ruling 2. Pick one reading. Either "+" splits rulings, and the lazy interpolant gets its bold back, or it does not, and one chained-ruling-2 bold goes.
- The one-line rewrite is a clause of D-179's single Position sentence, so leaving it plain is correct. No entry states "Earliest `t*` first" (grep finds none), so leaving it plain is correct.
- **D-082, possible duplicate.** B1's bolded trigger and D's bolded "The prior is updated at each boundary's quiescence" both come from D-082's chained ruling 2. The owner should check this.
- The blind spot lost its bold, and D-121 is not cited. The survey's row 56 classes it as a Rationale-only ruling. D-121's Rationale only records the vocabulary, so plain is defensible. rulings.md should still list the case.

## Brief checks

- **Moves.** R1 and M10 are done, the "(above)" reference is correct, and there are no other moves. Merging three subheadings into "Detection policy" is within the survey's latitude.
- **Directionality.** "Not-holding → holding", "the holding endpoint" and the input epoch are all intact.
- **`prior` link.** It is linked at its first use (new 91). Only the second link was dropped, which is correct.
- **Glosses.** The `t*` glosses for boundary and frame match §10.1, and the gloss for tick matches the glossary.
- **`(below)`.** The new "(below)" on trial evaluations (new 66) points to the right place.

## Reader-cold names

There is no Flight.jl machinery (kind 1) and no FlightCore (kind 3). The piston engine (kind 2) now has an introducing clause, with the caveat in item 1. These carry over from the old text: ZOH is used at new 147 without expansion until §10.5, ITP and AD are not expanded, and `localization_budget` appears at new 165 before its own section, with no pointer there.
