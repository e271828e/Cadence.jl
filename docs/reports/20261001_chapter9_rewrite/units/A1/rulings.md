# A1 rulings: chapter 9 opening and §9.1 up to the `Deployment`

Line numbers are `spec.md` lines (old.md line + 3390) unless marked `log`.

## Corrections proposed

1. **The steps table's probed set (survey F1).** Spec 3420, "the stage
   functions, guards and handlers, at `Float64`". §9.3 3815–3817 and D-050
   give the full set: the stages, `x_deriv`, `s_update`, guards, handlers and
   `x_projection`. Proposed cell: "every user function once, at `Float64`
   ([§9.3][s9-3])", or the full list.
2. **"Both products" (survey F2).** Spec 3545, "Both products are
   structural", follows a sentence naming three artifacts. The rewrite keeps
   it right after the list whose last bullet produces `Events`, as before.
   Proposed: "`Outputs` and `Events` are structural."
3. **"The nominal `Float64` activation runs at build" (survey F3).** Spec
   3570, under the activation heading, reads as if the activation step runs
   at `Float64`. Spec 3548–3552 and D-259 Rationale (log 9746–9750) say the
   nominal activation is the nominal evaluation's product, and a `Float64`
   run of the activation step "would be a second pass". Proposed: "The
   nominal evaluation produces the `Float64` activation at build. Every other
   activation re-runs *only this step* ([§9.4][s9-4])."
4. **"Absolute rate divisors" in the chapter opening.** Spec 3393–3395 lists
   "absolute rate divisors" among the build's products. Spec 3502–3504 says
   final divisors for anchored entries cannot exist until `Δt_base` binds,
   which is deployment's. The build produces `(anchor, m, c)` triples. The
   flat state layout is likewise an activation's product. Proposed: "the
   anchor-relative rate triples" for "absolute rate divisors". Same staleness
   as survey F25 in `extensions.md`.
5. **The shadowing check is missing from the structure step.** Spec 1979
   says "a **shadowing check** in the structural walk (§9.1), run on every
   component before its class is read (D-246)". D-246 Position (log 8990, "The
   shadowing check is one pass of Stratum A's structural walk") rules it.
   §9.1 does not mention it. Proposed: a sixth walk item or a sentence after
   the walk list, "Before a component's class is read, the walk runs the
   shadowing check ([§8.1][s8-1], [D-246][d-246])."

## Citations added or replaced

| claim | entry | words that rule it |
|---|---|---|
| A1-016, pipeline steps and barriers | D-259 Position, log 9718, 9725 | "The three steps are the structure step (the root instance in, `Structure` out), the nominal evaluation (…) and activation at a scalar (…). [§9.1][s9-1] opens with a table … with the deployment and the materialization on it as the steps after the build." "Each step is a barrier, as each stratum was" |
| A1-026, structure step is pure declaration reading | D-048 Position, log 1385 | "A, structure: pure declaration reading — tree/kinds/contracts, bottom-up faces, global wiring + obligations, rate compilation." |
| A1-027, no user stage code | D-259 Position, log 9725 | "No user stage code runs before the structure step completes." |
| A1-042, store form checked first | D-247 Position, log 9053 | "Stratum A checks the form on every primitive before the tier classifier and the vocabulary checks read the value" |
| A1-047, isbits field by field | D-231 Position, log 8376 | "Every field of a store value … is isbits or a `Symbol`, and Stratum A checks every `init_s`/`init_m` field, reporting `IllegalStoreField`." |
| A1-048, root inputs fall out | D-208 Position, log 7339 | "the model's root inputs are the root's input faces uniformly" |
| A1-050, bound check | D-078 Position, log 2217 | "wiring check `producer_face <: entry` at nominal faces — one uniform rule, exact equality the concrete degenerate" |
| A1-052, abstract-at-root | D-236 Position, log 8569, 8578 | "Both clauses of [§6.1][s6-1] are this relation, decided in Stratum A …" "A root input whose entries are all abstract is `AbstractAtRoot`." |
| A1-054, walk clause by retyping | D-263 Position bullet 2, log 10074; D-236 Position, log 8572 | "Both wire clauses of [§6.1][s6-1] stand, decided at the marker scalar by retyping the declarations instead of calling them." "A concrete entry is checked leaf by leaf." |
| A1-064, `sample_times` validation | D-185 Position, log 6458 | "validation Stratum A's with path attribution" |
| A1-069, the fold | D-186 Rationale, log 6523–6526 | "Stratum A compiles to **`(anchor, m, c)` triples** — seed `(A₀, 1, 0)` …, `Relative(K, φ)` step `(a, K·mₛ, cₛ + φ·mₛ)`, `Absolute` severs and re-seeds `(Aₖ, 1, 0)`" (see the next section) |
| A1-094, feedthrough graph not carried | D-261 Position, amendment of 2026-09-21, log 9876–9879 | "the old `edges` column was derivable from the structure's connections and the producers' stage-2 names, so both went, and the `Build` renders the feedthrough from those where it shows the table." The citation moved from the "derived" sentence to the bold "not carried" sentence, in the same paragraph. |
| A1-109, fixes structure and typing at once | D-253 Position bullet 4 as amended, log 9401–9407; D-259 Position bullet 4 | "Stratum B is its own function, consuming the structure and returning the dataflow, the events and the nominal `Float64` activation, assembled from its own probe chain." "(Amended by D-259: … a C run at `Float64` would be a second pass.)" The citation moved from the next sentence onto the bold one, in the same paragraph. |
| A1-098, workspace pointer | §9.3, not an entry | The bullet's reason moved to §9.3 (M8); the old D-077 citation goes with it. |

No superseded entry is cited.

## Rationale-only rulings

| claim | entry | field | log line |
|---|---|---|---|
| A1-069, the `sample_times` fold into `(anchor, m, c)` triples | D-186 | Rationale | 6523–6526 |
| A1-109, "fixes the structure and the `Float64` typing at once" (the wording; the ruling that one probe chain yields all three products is D-253's amended Position) | D-259 | Rationale | 9749 |
| A1-055, the kind name `WalkingFaceAtFrozenEntry` (left uncited) | D-167 (superseded), D-264 | Rationale | 5752, 10248 |

D-048's Position also says "deployment binding at `Simulation` construction
only", which D-254 contradicts with no annotation (survey part E). A1 cites
D-048 only for "pure declaration reading".

## Inbound citations affected

M1, the retyping list (spec 3559–3568), now held by §9.4 (`v4_flat.md`):

- spec 2303 (§8.2): "Cell types are single-sourced from the producer side per
  activation ([§9.1][s9-1])". §9.1 still says the step retypes the cells at
  `T`, so the citation stays true. The detail is §9.4's; retarget to §9.4 or
  cite both.
- spec 12095 (Appendix D, `Pinned`): "applied at activation, [§9.1][s9-1]".
  Same; retarget to §9.4.

Two pieces of the old list are not in `v4_flat.md`:

- "a discrete producer's is read once and pinned". v4 says only "A discrete
  producer's declaration pins". "Read once" has no home in chapter 9 now.
  Mapped to v4 as the nearest span. Either add "is read once and" to §9.4's
  bullet or confirm the drop.
- "the `s_init`- and `m_init`-derived store types pin". v4 has no store line.
  Mapped to §8.2 (spec 2480, "`m_init` and `s_init` pin wholesale"). §9.1
  keeps "`s_init` pins wholesale" in the structure step. Consider a §9.4
  bullet clause.

M8, workspace allocation (spec 3530–3533), now held by §9.3 (`units/B/old.md`):
no inbound citation names it. §9.1 keeps the bullet with a §9.3 pointer.

M11, the §13.1 summary (spec 3398–3401): the barrier clause maps to §9.1's
barrier sentence. "The only partial results carried past failures are
violation lists from pure checks" maps to §13.1 (spec 8305–8306), which adds
"and a claim table with the failed wires absent". No inbound citation names
the intro.

The steps-table paragraph now says both constructors are in §9.2 (dropping
"below"). That is true only once M2 lands.

## Open questions

1. **"It computes them in this order" (spec 3528).** "It" follows the
   `Events` sentence, but the list is the nominal evaluation's work. The
   rewrite says "The nominal evaluation computes its products in this order".
   Confirm the antecedent.
2. **Bold count.** 11 bold rulings after the verifier round, which unbolded
   the fold (D-186), root inputs (D-208) and "fixes the structure and the
   `Float64` typing at once". Six bold rulings rest on entries §9.1 did not
   cite (D-048, D-078, D-185, D-231, D-247 and D-259 at the barrier). The store-form and isbits rulings are bold here though their
   home is §8.2/§7.3, because the entries rule *where* they are checked,
   which is this section's claim.
3. **The `####` "Activation, parametric in `T`" heading** is kept. It is a
   topic label with a qualifier. The survey's part C suggests "Activation".
4. **Bold removed** from "bottom-up", "global", "derived by probing", the
   bound-check and walk-clause lead-ins, "`(anchor, m, c)` triples",
   "retyped", and the fold table's "severs and re-seeds" cell. The table is
   otherwise unchanged.
5. **The `#g-walked` link.** Old §9.1 had two `#g-walked` links,
   both in the M1 list. One survives in the pointer sentence.
