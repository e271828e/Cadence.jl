# A1 cold verification

**Counts.** 123 claims: 121 MATCH, 2 DRIFT (both in M1, held by v4), 0 LOST. ADDED: 2 (roadmap, §9.4 pointer), neither claims more than a pointer. 14 bold spans in 1,474 words; 3 flagged. `check9.py check A1`: 0 failures.

## DRIFT

- **A1-117** (M1). Old: "a discrete producer's is read once and pinned (§8.2)". v4: "A discrete producer's declaration pins." The pin holds in v4 and in §8.2 (spec 2372, "pins wholesale"). "Read once" means the declaration is not re-evaluated per activation, and nothing in chapter 9 now says so. Fix: v4 bullet 1 reads "A discrete producer's declaration is read once and pins."
- **A1-121** (M1, minor). Old: "The flat `x` buffer and the table are laid out." v4: "The table and state buffers are laid out again." "flat" and "`x`" are gone, and "state buffers" (plural) could take in store buffers. Fix: v4 "The table and the flat `x` buffer are laid out again", or confirm the wider reading.

## M1, the other items

- A1-115, A1-116 and A1-118 are MATCH in v4. One small point on A1-118: v4's state-type bullet carries no §8.2. The citation sits only on v4's first bullet.
- A1-119 ("the `s_init`- and `m_init`-derived store types pin") goes to §8.2. That is acceptable. Spec 2479–2481 says, in the activation-scalar context, "`m_init` and `s_init` pin wholesale, mirroring the discrete-producer rule". The meaning matches. The clause in §9.4 is optional.
- "observed is compared against declared" stays in §9.1.
- M8 holds. The workspace bullet stays with a §9.3 pointer. units/B/old.md lines 28–30 carry the reason and D-077.

## M11

§13.1 states the clause at spec 8305–8306: "The only partial results ever carried past a failure are violation lists and a claim table with the failed wires absent." It is wider than the old intro, which said only "violation lists from pure checks". §13.1 is the newer text, so the mapping holds. The barrier clause now sits in §9.1's bold sentence with D-259 and §13.1.

## Citations

I checked all 13 added or replaced citations against decisions.md. Every one sits in the field and on the words that rulings.md names.
- D-048 is still ratified, but its "deployment binding at `Simulation` construction only" is stale. rulings.md already notes this.
- D-186 is cited from its Rationale only.
- One older point, not drift: "comparing per leaf" (A1-054) is unconditional, while D-236 checks an abstract entry on the whole declaration.

All of old.md's citations survive. D-077 moved with M8. D-261 moved within its paragraph.

## Bold

- **V45, "The compilation is a fold down the tree" (D-186).** This is mechanism, and it rests on D-186's Rationale only. D-186's Position rules anchors and severing. Unbold it and keep the citation.
- **V32, "Root inputs fall out here too…" (D-208).** This is a consequence ("fall out"). §8.2 already bolds D-208's ruling at spec 2597. Unbold it.
- **V70, "The nominal evaluation fixes the structure and the `Float64` typing at once" (D-253, D-259).** V58 already bolds this ruling (D-253 bullet 4: the nominal evaluation returns the nominal activation). V70 is a summary built from D-259's Rationale wording. Unbold it.
- V34 (D-078) and V38 (D-263) state the wire clauses whose home is §8.2. §8.2 bolds them only as terms today. When §8.2 is rewritten, their bold belongs there and §9.1's should become plain.
- The other 10 bolds are rulings, each headline appears once, and each is followed by its D-entry.

## Reader-cold names

There are none in classes 1–3. `build(world)`, `Simulation{T}`, `Δt_base` and `period(q)` appear without an introduction, the same as in the old text. §9.2 and §10.5 define them.

## Other

- A1-097, "computes its products in this order": the first bullet is workspace allocation, which is not a product. Better: "does its work in this order".
- A1-065, "They are wrapper-typed values…": the antecedent is "constraints". Better: "They require wrapper-typed values, …".
- The emphasis in "Error-*reporting*" was dropped.
- A1-024 ("both in §9.2") is true only once M2 lands. rulings.md says so.
