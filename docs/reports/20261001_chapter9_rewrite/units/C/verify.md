# Unit C (§9.5): cold verification

**Counts.** 121 claims: 119 MATCH, 2 DRIFT (minor), 0 LOST. 108 phase-1 assertions. 2 of the additions assert mildly, with no meaning change. `check9.py` gives 0 failures.

**Terms of art.** All are verbatim and match their entries. "exact type match" and "nominal-style exact check" match D-053 and D-238. "identity alone" matches D-237's Position. "embeds" and "zero-partial" match D-053. "lifted … must be the declaration itself" matches D-238's Position. "accepts exactly two types" matches D-053 `{T, Float64}`. "embed-accept" survives in the label, as in old's lead-in.

**DRIFT**
- C-010. In old, "When the write's method is generated" covered both the key-set check and "each returned field is held to its cell's type". After the split, the second sentence lost it. Fix: "At the same point, each returned field …".
- C-088/089. Old gave one joint reason ("since A and B", as in D-111). New gives two: "It is complete because A. It is also complete because B." Fix: "because A, and because B."

**ADDED.** "How the stage's code is typed decides what the check costs it" and "Each function is checked against its own predicate" summarize the lists that follow.

**Unlisted move.** The C-044 gloss on activation moved from old line 54 up to "The generated write". The meaning holds, but the brief lists no such move.

**Citations.** Every old citation survives. D-235 moved from C-008 and D-238 from C-056 to their headlines.
1. C-057, the pinned-leaf headline, cites D-238. D-238's Position does not state the rule. It implies the rule only together with D-263 bullet 1 (`Pinned{P}` is pinned at every activation, and the walk "yields `P` at `Pinned{P}`"). No `T` position means nothing lifts, so the check is identity. As an implication the citation is honest. But it bolds a consequence, against the brief, and it is D-238's second bold. rulings.md correctly lists it as Rationale-only. Fix: unbold it and cite "([D-238][d-238], [D-263][d-263])" until survey E9 settles it.
2. C-112. D-053's Position reads "path + stage + field diff + `t`", and the next sentence denies the `t` (D-249). Fix: cite D-249 alone, or note the conflict in rulings.
3. C-095/097. D-053 carries only the `m` half. The `x`-complete half rests on D-090's Rationale, which is listed but not cited. Fix: add D-090.
4. C-004. D-235 rules that the write holds *the return to* the cell type. The bold sentence says the executor *holds the type*. Consider bolding C-007/C-008 instead.
5. All other added citations carry their claims.

**Bold.** 17 spans, each followed by a D-citation, and none on a definition or lead-in. D-053 has 7. Three of those ("uniform", the guard form, the handler `m`) are clauses of one Position sentence, so this is near a ruling bolded three times (rulings Open Q1).

**Reader-cold names.** No Flight.jl machinery. `Expected` is never defined in the spec, as in old. Category 2: the `P = M*ω` / `M_shaft` example needs a clause such as "a shaft's power and torque".
