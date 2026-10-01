# A2 verify report

**Counts.** 155 claims: 150 MATCH, 4 DRIFT, 1 LOST. 9 added, all transitions, glosses or pointers. 104 phase-1 assertions. The check script passes.

## DRIFT and LOST

- **A2-070, LOST.** Old: "The one mutable thing on the artifact is the lazily populated activation dictionary." It maps to v4's "Lazy materialization is torn-state-free", which does not say this. Nothing in v4 says the dictionary is the Build's only mutable part. Fix: adopt correction 4, or end the pointer with "…torn-state-free insertion into the activation dictionary, the one mutable thing on the artifact."
- **A2-056, DRIFT (strength).** Old: "under the lock". v4: "The mechanism is unspecified." The rewriter knew (F6). The user must confirm.
- **A2-069, DRIFT (scope).** Old: "nothing writable is shared". v4: "Every buffer set has exactly one owner." This is narrower, but acceptable under M4 if A2-070 is restored.
- **A2-115, DRIFT (quantifier).** Old: "records each face's routing chain at every level". §13.7: "records the routing chain at every level". D-257's amendment says "each face's". Fix: say "each face's" in §13.7.
- **A2-084, DRIFT (antecedent).** "validates device bindings against it". After M5, "it" reads as the Build, which is D-049's intent (F8). Fix: "against the `Build`".

All other mapped spans say the same thing. That covers M4's dictionary and `Float64` entry in v4, M6's hops, `→` and fan-out in §13.7 (spec 8996–8999), and M7's declarations in §10.5 (spec 5058–5063, where `Vehicle` is the root).

## Warnings vs. grid diagnostics (note 2)

"The derivation path is the one place refinement happens silently. It always prints the derived value with its drivers" is the derivation path's info line. Grid diagnostics names that line (l.215), and D-254 bullet 3 lists "the derivation line" among the grid diagnostics. Under Warnings it reads as if it were a warning, so these two sentences sit under the wrong label. Appendix B 10838 cites §9.2 for "printed with its drivers". Fix: move l.249–255 to the end of Grid diagnostics. Keep l.256–257 ("`GridUtilization` is a deployment warning…") under Warnings as its own paragraph. That also brings back the D-250 citation the paragraph lost.

## Citations

Every added citation checks out against the field rulings.md names: D-049 Position; D-254 Position and bullets 1 and 4; D-207 bullet 2; D-261 bullet 2; D-257 bullet 2; D-229 last bullet; D-186 Rationale ×3; D-187 Rationale and Rejected; D-135 Rationale. The dropped citations are self-citations, the two §9.4 citations merged into one, and D-250 on `GridUtilization`. Under the convention, all are acceptable.

## Bold (19)

- **Ruling bolded three times.** l.111, "carries everything the grid parameters fix", restates D-254 bullet 1. That bullet is also the ruling behind l.184, "`Schedule` lives on the `Deployment`", and bullet 3 behind l.213, "grid diagnostics live on the `Deployment`". Fix: bold only "A `Deployment` is scalar-free".
- **Consequence.** l.40 is the immutability sentence. D-135 calls it one of "two consequences". It carries only a Rationale citation and was already bold in the old text. Keep the bold only if an entry rules it in a Position (survey E).
- The other bolds are distinct rulings with a citation after each. This includes the pairs that cite the same entry: D-186 ×3, D-187 ×2, D-250 ×2 and D-257 ×2.

## Inbound spot-checks (15)

These facts are findable in the new §9.2:

- 3196, the three sources
- 3272, `EmptyFaceSelection` on the list
- 4798, the event parameters
- 5046, the pool
- 6343, the deployment's contents
- 6372, outside the `Build`
- 7793, the deployment's parameters
- 8424, `warnings(x)`
- 9322, routes per level on the face table
- 11457, `GridUtilization`
- D-135 Rationale's quoted "true by construction once buffers are single-owner", verbatim at l.41

These are partial or missing:

- 5548, the immutability sentence. "One immutable `Build`" is findable at l.40, but "each `Simulation` owns its own buffers" now lives only in §9.4. Add a §9.4 citation there.
- 8304, "throws once", is in neither the old text nor the new one (correction 8).
- 11781, the service store set, was never in §9.2.
- 10838 is found under the wrong label (see above).

## Moves

M2–M7 are done, the labels follow the survey's order, and no other moves were made. The reorders inside subsections follow the labels.

## Reader-cold names

- **Category 2.** `fcs` and `gnss`. M7 removed the prose that declared `fcs` at the root, so the table's "under `fcs`" now has nothing to introduce it. Fix: "under two scopes, the root and `fcs` (the flight-control scope)". `gnss` needs a clause such as "a 50 Hz GNSS receiver".
- **Category 1.** None.

## Other

- The constructor's inputs are stated twice (l.25 and l.113, survey overlap 7).
- D-261 is cited in bold at l.85 and again in plain text at l.190, which rests on bullet 4. That is acceptable.
