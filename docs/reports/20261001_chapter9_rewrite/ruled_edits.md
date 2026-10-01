# Ruled edits: R1, R3, R36 and the D-261 order

Applied 2026-10-01 to the units' `new.md`. Lines are those after the edits.
Each unit's edits are in `units/<U>/ruled_edits_<U>.py`. Checks after the
edits: `check9.py check` prints "checks failed: 0" for A1, A2, B, C, D and E.
`boldcheck.py` passes for C and S94. It fails for A1, A2 and B, whose words
changed, as expected.

Bold spans per unit, before → after: A1 11 → 10, A2 18 → 17, B 9 → 9,
S94 12 → 10, C 16 → 13, D 0 → 0, E 13 → 13. Total 79 → 72.

## R1: one bold per ruling

A bold span maps to the Position sentence or bullet its bold words state.
Semicolon-chained rulings in old-style Positions count as bullets. A bullet's
sentences count as one ruling, as the D-254 ruling has it. A span that is the
first bold statement of any ruling it maps to stays bold. Bold on a ruling
found only in a Rationale or a Rejected field stays (R5).

### Made plain

| entry | Position ruling | first bold, kept | made plain |
|---|---|---|---|
| D-253 (and D-259 b1) | b4, the nominal evaluation's and activation's inputs and outputs | A1:155 "The nominal evaluation is a function of the `Structure`" | A1:197 "Activation at a scalar `T` takes the `Structure`, the `Outputs` and the nominal activation" |
| D-253 | b4, "No product changes across activations" | A1:155 | S94:30 "No execution order and no name list changes across activations" |
| D-253 | b5, "`Build` is structure, dataflow, events and the activations, the nominal and the cache merged into one dictionary" | A2:20 "A `Build` is structure, outputs, events, the activations and `warnings`" | S94:107 "The nominal `Float64` entry is one key in the activation dictionary like any other" |
| D-254 | b1, "It carries the `Schedule`" | A2:92 "A `Deployment` is scalar-free" | A2:166 "The `Schedule` lives on the `Deployment`" |
| D-053 | "uniform across `f` (…), guards (form-aware …), output stages, handlers (partial-`m` subset predicate)" | C:137 "The check is uniform across all probed functions" | C:164 "`x` must be complete against the state field set"; C:177 "The guard check is form-aware" |
| D-053 | "failure = path + stage + field diff + `t`, reproducible by trace replay" | C:189 "The payload carries the component path, …" | C:202 "The always-on input trace makes every such failure reproducible by replay" |

Every demoted sentence keeps its citations.

### Kept: each bold states a different ruling

| entry | bold span → ruling |
|---|---|
| D-253 | A1:137 "The structure step returns `Structure`" → b1; A1:155 → b4; A2:20 → b5 |
| D-259 | A1:32 "The pipeline runs as the steps below" → b1 (the steps and the table); S94:9 "Only the activation step re-runs" → b2 |
| D-254 | A2:24 "Deploying and materializing are two steps" → lead sentence; A2:92 → b1; A2:219 "The grid diagnostics live on the `Deployment`" → b3 |
| D-186 | A2:73 timing tables anchor-relative; A2:103 three sources of `Δt_base`; A2:122 must declare `Δt_base` → three separate Rationale rulings (R5). The one-sentence Position names "the derive-vs-declare rule" but does not state it |
| D-261 | A1:163 "The feedthrough graph … is not carried" → b2's dated extension (2026-09-21, increment 48b: the `edges` column went); A2:58 "An artifact holds declared facts" → b2's rule |
| D-257 | A2:196 "Each artifact renders itself" → lead sentence; A2:212 chart prints whole → b2 |
| D-187 | A2:227 every `r_p > 1` listed → Rationale; A2:238 blame against the actual pool → Rejected (R5) |
| D-250 | A2:252 a completing step carries its warnings → b1; A2:266 `warnings(x)` → b4 |
| D-115 | B:35 `ws` → the `ws` ruling; B:82 `t` → the `t` ruling |
| D-051 | B:46 `probe_value` synthesis → ruling 1; B:77 strictly probe-scoped → ruling 2 |
| D-142 | B:96 total over type-valid inputs → sentence 1; B:133 parameter validation → sentence 4 |
| D-052 | S94:35 executable set → ruling 1; S94:57 first request → ruling 2; S94:110 caching never changes a result → ruling 3 |
| D-053 | C:73 exact match → "Exact match is scoped to the nominal activation"; C:82 walking leaf → "parametrized leaves … accept `{T, Float64}`"; C:137 → "uniform across …"; C:189 → "failure = …"; C:198 source branch absent → Rejected (R5) |
| D-263 | A1:93 → b2 (wire clauses decided by retyping); C:128 pinned-leaf freeze → b1 |
| D-147 | E:61 two arities → sentences 1 and 5; E:74 `t*`'s empty due set → sentence 6 |
| D-194 | B:42 `DeadStage` → b5; E:80 seams → b3 |
| D-086 | E:14 → the Position; E:47 phase bodies, E:99 views, E:107 type-opaque construction → three Rationale rulings (R5) |
| D-116 | E:154 the seam → ruling 1; E:182 identity → ruling 2; E:188 CI → ruling 3; E:202 publication → Rationale (R5) |

## R3: the clause that carries the bold

- A1:93. "**It is decided by retyping both declarations at a marker scalar**"
  became "**The walk-compatibility clause is decided by retyping both
  declarations at a marker scalar**". Inventory A1-054, tag R.
- A2:212. "**The chart guard is binary** ([D-257][d-257]). The chart prints
  whole, …" became "The chart guard is binary. **The chart prints whole, as a
  tick chart over `k = 0 … lcm(Dᵢ) − 1`, when `lcm(Dᵢ)` is at most 100 base
  ticks** ([D-257][d-257])." Inventory A2-121 and A2-122, tag R.
- B:91. "**Enforcement is the pre-write `UninitializedInputs` check** carried by
  every complete-world application, namely `init!`, trim setup and trim commit
  (…)" became "**Every complete-world application, namely `init!`, trim setup
  and trim commit, carries the pre-write `UninitializedInputs` check**
  ([§14.6][s14-6], [D-149][d-149])." The word "Enforcement" goes, as the
  proposed text has it. The preceding sentence still states the obligation the
  check enforces. Inventory B-055, tag R.

## R36: §9.2 drops the restated ownership argument

A2:41–45 dropped "That is true by construction once buffers are single-owner."
and "Each `Simulation` materializes its own buffers from the shared layouts, so
nothing writable is shared." The immutability sentence, the F6 sentence and
the §9.4 pointer stay. Inventory, with `where` = `units/S94/new.md`, tag R:

- A2-067 "true by construction once buffers are single-owner" → "Every buffer
  set has exactly one owner (D-282)." (S94:112)
- A2-068 "Each `Simulation` materializes its own from the shared layouts" →
  "The `Simulation` owns its nominal activation's buffers. They are
  materialized from the cached layouts at construction." (S94:114–115)
- A2-069 "so nothing writable is shared" → "An entry is immutable once
  constructed, and so it is freely shareable." (S94:104–105). "So buffers are
  never cached." (S94:121) states the other half.

## D-261's rule before its application

A2's paragraph "**An artifact holds declared facts**, and a consumer compiles
what it needs from them once, at one home ([D-261][d-261]). …" moved, unchanged,
from the head of "Rendering" to A2:58 in "The `Build`". It now follows the
paragraph that sets the diagnostic form against the compiled form, and precedes
the `Schedule` paragraph (A2:166) that applies it ("derived from the rows at
`compile`, never stored beside them"). "Rendering" now opens with "Each artifact
renders itself through `show`". No inventory span changed.
