# ch08 B1 verify report

**Counts.** 68 inventory claims: 65 MATCH, 1 DRIFT, 0 LOST, 2 ruled (B1-033 F3 deletion, B1-044/045 R4 cut). ADDED: 3 listed, 2 unlisted, none meaning-changing.

**DRIFT**
- B1-044. Old: "Declaring types here too, `u_types`-style, with `probe_value` (§9.3) synthesizing the initial values, was rejected". New: "Typed stores with synthesized initial values were rejected". Stores are typed under the kept design too (their type is derived), so "typed stores" can read as rejecting what §8.2 adopts. Fix: "Stores declared by type, with synthesized initial values, were rejected (D-073)." The R4 map holds: D-073 Rejected (log 2112) carries "`init_*` as types + `probe_value` synthesis". The cut drops the §9.3 pointer, which the log does not carry. That is acceptable under R4.

**Minor**
- B1-052. Old "which are recomputed … and so need only types" is ambiguous between cells and contracts. New picks contracts. The sense is unchanged.
- B1-035. Old "consequently" becomes "Because the type is derived from the value". This fixes the antecedent, and D-033 ("type derived — nothing to drift") and the `Engine` comment carry it. It is not listed in `added`.
- The display block is not declared in `added`. The survey's part C says new display blocks are declared additions. Its content is exactly the old text's forms and D-263 bullet 5. Survey part F expected two display blocks; the bare-leaf candidate went unused, which is allowed.

**ADDED (all fine)**
- "The store names each leaf because". It folds the **Why.** label into a causal link, and D-247 Rationale (log 9175ff) supports it.
- "`ws_init` allocates … which is described below". This is a pointer.

**Hazard checks**
- Criterion list. The walk gloss is verbatim old and matches glossary `g-leaf-walk`. The `Pinned` gloss ("leaf wrapper `Pinned{P}`, which yields `P` at every activation") matches the glossary leaf walk and D-263 bullets 1 and 3. No glossary entry for `Pinned` exists. The activation and workspace glosses are verbatim. The tier gloss matches `g-tier`. Both halves of "The criterion, not uniformity, is the rule. A `T` in a signature…" survive.
- F22. The bold wording matches the brief exactly. F3 is deleted, and nothing replaces it.
- The `init_*` spelling is carried from the old text (old line 104), not imported by the rewriter. It is still log vocabulary in a chapter that otherwise says `x_init`/`s_init`/`m_init`. This is the owner's call, and rulings.md raises it.
- Store gloss. "The model's memory" comes from the old text, and "declared by initial value" comes from D-033. Glossary `g-store` covers only `m` and a discrete leaf's `s`, not `x`. The old text's link had the same scope mismatch.

**Citations**
- D-033 Position: "`init_*` by value (type derived — nothing to drift)". It carries the claim.
- D-247 Position: "one named field per leaf, and no other form is admitted". It carries the claim.
- D-263 bullet 5 carries the exactly-one-store rule.
- D-077 and D-263 at the workspace. D-077's Position gives the discrete allocator no `T`. "Both tiers" is carried only by its annotation and by D-263 bullet 4, so citing both is right.
- D-079 at the seeding clause. Its Rationale says "per-invocation seeding, never typing". The "never through initialization" half rests on the same Rationale's "declared `Float64` initial values embedding as zero-partial constants". rulings.md should quote that clause too.
- Every other old citation survives with its claim. The only exceptions are §5.3, removed by the F3 ruling, and §9.3, removed by R4.

**Bold.** There are four bolds, each a distinct ruling with its D-entry in the same sentence. None is on mechanism or a lead-in. Grepping the other units finds no double bolds. The two D-263 bolds are distinct rulings: Position sentence 1 with bullet 4, and bullet 5.

**Moves.** The criterion paragraph opens §8.2 after the `Engine` block, and the "The stores" label is applied. The condition gloss and link moved to the first use. There are no other moves.

**Reader-cold names.** There are no Flight.jl names. `TierUnreadable` has no Appendix C pointer, which matches the old text. `Gain` and `Sampler` are illustrative names from the old text. `Engine`, `torque_law` and `StateEvent` sit in the verbatim code block.

## Re-check

All findings are resolved. The checker prints `checks failed: 0`, with 4 bold spans and no glossary-link differences.

- B1-044 now reads "Stores declared by type, with synthesized initial values, were rejected ([D-073][d-073])". The ambiguity is gone. "By type" reuses the criterion list's by-type convention, so the term is defined above. The synthesis clause, the D-073 citation and its scope are intact. "This is the boundary of legitimate derivation" still points back to the same two sentences. The inventory and rulings.md R4 entry carry the same wording. The §9.3 pointer stays dropped under R4, as before.
- `added` now declares "Because the type is derived from the value" and the display block. The workspace paragraph after it still reads "that convention" as by-value, so no antecedent moved.
- rulings.md now quotes D-079 Rationale log 2309–2310, "declared `Float64` initial values embedding as zero-partial constants", for "never through initialization". I checked that line in the log. In context the clause is about `init_m`/`init_z` pinning, but it does state that initial values embed with zero partials, and that supports the claim. The new text is unchanged at that bullet.
- `init_*` stays as written by ruling, and rulings.md records the ruling.
- Nothing nearby broke. I re-read new.md lines 47–137. The criterion list, the bold sentences, the citations and the cause clauses ("since it has nothing to integrate or advance", "because it is not memory", "so contracts need only types") are all as verified before.
