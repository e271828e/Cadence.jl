# Unit F verification (§8.7, §8.8)

**Counts.** 105 inventory claims: 104 MATCH, 1 DRIFT, 0 LOST. 11 ADDED, none meaning-changing. Checker: 0 failures. Phase 1 found 112 assertions and 7 bolds. The unit ends with the chapter's closing `---`.

## DRIFT

- **F-009 (antecedent).** Old: "An unlisted discrete child defaults to `Relative(1)`, so only multiplied, phased or anchored children need appear." New: "The declaration is optional, and so is any given key (D-042). Under that default, only multiplied, phased or anchored children need appear." The default is now only named in a pointer ("the default for an unlisted discrete child"), and "that default" follows the optionality sentence. The reason why only those children appear is gone. Fix: "Since an unlisted discrete child defaults to `Relative(1)` ([§10.5][s10-5]), only multiplied, phased or anchored children need appear."

## Ruled edits

- R1: the `Group` sentence is verbatim and unbolded. MATCH.
- R3: the `(D, Φ)` compile sentence is verbatim. Both cut claims sit at spec §10.5, "The two declaration forms": "The wrappers are the whole vocabulary (D-185). A bare integer or bare quantity is a declaration error. An unlisted discrete child defaults to `Relative(1)`." Old "value vocabulary" vs §10.5 "vocabulary" is no loss. §10.5 also holds the validation, so the pointer is accurate.
- R7 F7: "That is structure kept in two artifacts (D-039)", with no quotes and no §8.1. MATCH.
- R7 F21: "A continuous bundle carries no `Δt` (§10.5)" matches §10.5, "`Δt` in the bundle" ("It is absent from continuous bundles").

## ADDED

The roadmaps and glosses are pointers or match the glossary. The `World`, `Systems`/`act` and "two of the faces" clauses say only what the code blocks show. "Flight.jl's C172X demo" matches `flight_case_studies.md` ("the full C172X demo", FlightApps). F-068's new clause, "split by direction into `u_connections` and `y_connections`", is not in `added`, but it is accurate (D-170).

## Citations

All old citations survive. §8.1 was dropped by R7. Every added or replaced citation checks out against its named field: D-185, D-042 (both Position and Rejected), D-085 Rationale, D-254 Position, D-039 Rejected, D-046, D-145 (Position, Rationale and Rejected), D-171 Rationale, D-209 Rationale, D-207 (Position and Rejected), and D-251 bullets 1–3. Two are weak:
- D-043 at "Computed entries mix freely" and at "evaluated at build against the concrete instance". The Position says only "Computed exports as ordinary code", so mixing and build-time evaluation are implied, not stated.
- D-039 is carried only by its Rejected list. It is missing from "Rationale-only rulings".

## Bold

There are 7 bolds. Each is a ruling with its D-entry. D-145 is bold twice and D-251 twice, but each pair comes from distinct parts of the entry, so that is acceptable. "Removing the duplication needs no vocabulary" was plain in the old text. It is now bold, and D-145's Position supports it.

D-251's selector ruling is bold here and at §13.7 ("The passthrough helpers take a predicate"). Both bolds come from the same colon-joined Position sentence, so they are one ruling. The bold belongs in §8.8. That is where the helpers and selectors are specified, and D-251's Spec field names §8.8 and Appendix C, not §13.7. §13.7's sentence should go plain, keeping its §8.8 pointer.

## Reader-cold names

- (1) FlightCore's `Subsampled` is introduced as "an instance wrapper in the style of". That is fine, since it names the predecessor (3).
- Define-before-use: `Systems` is first used in the `output_passthrough` block (line 167) but introduced only at line 203. Fix: move the introducing clause before the first block, or add "(below)".
- (2) `EAS_ref`, `mode_req`, `ldg` and `aero` have no introducing clause. `EAS_ref` would take "(the equivalent-airspeed reference)". This is unchanged from the old text.

## Other

- "bundle" is a glossary term used for the first time in §8.7, and it is unlinked.
- §8.7 says the sugar twice: "is sugar for a uniform declaration across all elements. It applies one declaration to every element." Merge them into one sentence.

## Re-check

The checker reports 0 failures. Every finding is fixed except the §13.7 bold, which is outside the chapter and has gone to the rulings batch. One fix moved an antecedent.

- **F-009:** MATCH. The new text reads "Since an unlisted discrete child defaults to `Relative(1)` (§10.5), only multiplied, phased or anchored children need appear." The §10.5 pointer now names only the definitions and the validation, so nothing is said twice.
- **D-043:** the cite is dropped at "ordinary functions evaluated at build…" and at "Computed entries mix freely". The old text cited neither, so no scope shrank. D-043 still covers auto-bubbling and generic holding. `rulings.md` lists both claims as uncited and notes that an entry may be owed.
- **D-039:** now listed under Rationale-only, Rejected list, log 1197–1198.
- **Sugar:** merged into "The bare field name is sugar that applies one uniform declaration across all elements." This covers both F-013 and F-104. MATCH.
- **`bundle`:** the gloss reads "(the `NamedTuple` of views a component function receives)". It is a subset of glossary 12216 ("the single `NamedTuple` of zero-copy views…"), so it claims nothing extra. It is missing from the inventory's `added` list because it sits inside F-015's span. That is bookkeeping only.
- **`Systems`:** "`Systems` is an assembly whose children include `aero` and `ldg`" and "`Systems` also holds an actuator child `act`…" claim only what the code blocks show.
- **`EAS_ref`:** "the equivalent-airspeed reference" has no named source in the docs, which use EAS but never spell it out. The expansion is standard and claims nothing about the design, so it is acceptable as a one-clause introduction.
- **F-068:** the clause is now declared in `added`.
- **New antecedent drift, F-062.** The `Systems` sentence now sits between "`output_passthrough` is its sibling…" and the code block. So "Its consumer is one-level routing (§6.1, D-209)" now reads as `Systems`'s consumer. Fix: "`output_passthrough`'s consumer is one-level routing ([§6.1][s6-1], [D-209][d-209])."
- Nothing else nearby broke. "That is impossible with a bundled face" still follows "The remaining faces stay exported…", and the unit still ends with `---`.
