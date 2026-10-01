# new5.md verification (phase 2)

## Counts
- Claims: 114 (K1-K114). MATCH 113, DRIFT 1 (minor), LOST 0.
- Phase-1 assertions: 112 (V1-V112). ADDED with changed meaning: 0. Harmless ADDED: 8.
- Bold: 14 RULE claims (K6, K23, K27, K45, K56, K61, K62, K66, K77, K78, K84, K85, K86, K107), 14 bold spans. Each is bold and followed by its D-cite. No RULE claim is unbolded. Nothing else is bold. D-263 and D-012 appear unbolded on FACT claims K17/K18 and K38/K40, which is correct.
- Every § cite in the claims appears at its claim. No extra citations were added.

## DRIFT
- K36 (antecedent). Claim: "The rule that each activation probes exactly what it can execute has no special cases." New: "The rule has no special cases." The bold probe-set rule is two paragraphs up. The paragraph in between ends on probing the discrete stages at `Dual`, so "The rule" could be read as the `Dual`-specific restriction. Fix: "The probe-set rule has no special cases."

## Causal connectives checked, all backed by claims
"This is why" (K26), "because event localization..." (K32), "So only those are probed" (K34), "are lazy because" (K47), "To compensate" (K55), "no more and no fewer" (K27 parenthetical), "that break linearizability" (K50), "So the bare `Dual` cannot key" (K70), "so one canonical width suffices" (K75), "It lives there because" (K79), "so it is freely shareable" (K83), "So a different seeding width" (K105), "Because every buffer set has one owner" (K93), "So the worst benign race" (K114).

K28: the claim's appositive is non-restrictive in the span ("as linearization and gradient trim use"). So splitting it into "Linearization and gradient trim use a `Dual` activation. A `Dual` activation evaluates the model at a frozen instant." keeps the scope. MATCH.

## Harmless ADDED
- "The price is that a successful `build` does not certify..." names K49 as the price in K48. K49 is a CONSEQUENCE with no stated cause. The writer flagged this reading, and it is the natural one.
- K16 (buffer re-layout) goes in list item 3. K19-K21 go in item 4. The claims do not number these. The count of five still holds.
- "Linearization and gradient trim use a `Dual` activation." This comes from K28's appositive and overlaps K2.
- K111 drops "to exclude torn state". The previous sentence ("The mechanism that excludes it") carries that meaning.
- "The call above names `ProbeDual`." is a transition.
- "It redoes five things", "It is invoked as follows", "It is defined as follows" are lead-ins.
- The four #### subheadings follow K5's topics. `ProbeDual` sits under "Laziness and the CI check" and the torn-state paragraph under "The activation cache". This only affects layout.
- K104-K106 (seeding width) are moved ahead of K86-K103 in the order. Nothing depends on the order.
