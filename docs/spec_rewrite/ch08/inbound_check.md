# Inbound check of chapter 8's rewrite — 2026-10-02

Every row of `inbound.tsv` (450 citations of §8 or §8.N from outside the
chapter) judged against `chapter_new.md`. Per-row verdicts and notes are in
`inbound_check.tsv` (the input columns plus `verdict` and `note`). Scratch
scripts are in `scratch_inbound/`.

## Counts

| verdict | rows |
|---|---|
| OK | 427 |
| RETARGET | 0 |
| COMPANION | 0 |
| MISSING | 0 |
| PREEXISTING | 23 |
| VAGUE | 0 |

No row lost its content. Every PREEXISTING row was already wrong against
`chapter_old.md`; each has a proposed fix below, for track 2 or for the
citing chapter's own rewrite.

## What was checked

- **M1 (root inputs) and M2 (custom structs)** stay inside §8.2. Rows 49, 55,
  71, 99, 101, 109, 111, 129, 130, 163, 343–344 and the
  `handle_walk_walkthrough.md` rows 440–443 all resolve in §8.2's new "Root
  inputs" and "Output contracts: `y_types`" blocks.
- **M3 (rate-key sugar to §8.7).** Appendix C `ChildNameCollision` (row 150)
  still resolves in §8.5: the collision bullet names "the `sample_times`
  sugar of §8.7" and keeps the own-field-name ambiguity (D-215). No row cites
  §8.5 for the sugar itself.
- **M4 (builder).** spec 7224 (row 79) and log 6528 (row 329) resolve in the
  `Group` block, which keeps "A declaration is an ordinary function body,
  and loops and comprehensions build the returned tuple" and the rejection
  with D-039.
- **M5 (§8.5 "One arity" trimmed).** §8.5 keeps "The tier is read from the
  store every leaf declares (§8.2)" (glossary 12525, rows 183–184) and the
  name `DeclarationOnWrongTier` (Appendix C 11769, row 142). The cut
  sentence "There is consequently no signature-shape violation to name"
  went to D-249's annotation (unit D inventory D-033); rows 319, 374, 375
  and 377 never had support in §8.5 and are PREEXISTING.
- **M6 (§8.7 rate forms trimmed).** §8.7 keeps "all are compiled to one
  `(D, Φ)` pair per discrete component" (glossary 12188, row 173; log 6981,
  row 336), the continuous-child error (row 149, row 309) and the deep-key
  rule. The cut "a bare integer or bare quantity is a declaration error" is
  in §10.5 (spec 5352); rows 162 and 450 touch it (see below).
- **M8 (adversarial passages).** No row relies on the cut passages. §8.3's
  "What this rules out" became one pointer sentence that still cites D-016,
  D-034, D-055 and D-194, so rows 194 and 217 keep their target.
- **Phrases quoted from outside (survey part F)**, all present word for
  word: "at build time where possible" and "at first execution otherwise"
  (§8.1; rows 54, 62); "Types come by declaration, values by execution, and
  conformance by comparison" (§8.1; row 174); the hint "if `F` participates
  in differentiation, remove its `Pinned`" (§8.2; row 417); "a face feeding
  nothing declares nothing" (§8.6). Also kept: "linearize the continuous
  dynamics with the discrete state held" (§8.2; rows 65, 110, 446), "the
  helper exists for the pass-through case, where an assembly hands a child's
  unfed requirements up one level" (§8.8; rows 266–267), "Containers are
  transparent grouping, not assemblies" (§8.5; row 354), "is the FFI door in
  use" (§8.2; row 292).

## Appendix C kinds (spec 11709–11993)

40 rows fall in that range, 38 of them citing a chapter-8 section for a kind. Every kind the old cited section
named is still named in the new one: `WalkingFaceAtFrozenEntry`,
`AbstractAtRoot`, `StoreNotNamedTuple`, `DeclarationShadowed`,
`ContainerNested`, `DeclarationOnWrongTier` (§8.2 and §8.5),
`UnknownFaceSelection`, `EmptyFaceSelection`, `TierUnreadable` (§8.2),
`StatelessWithoutOutputs` (§8.2), `IllegalPortType`, `DeclaredNotProduced`.
`RootInputTypeConflict` is newly named in §8.2 (R14).

Nineteen kinds were unnamed in their cited section before and still are,
though the section states the rule: `UnknownPort`, `UnconnectedInput`,
`WireTypeMismatch` (§8.4 w1, w2, w4; §8.2), `TwoProducers` (§8.8),
`IllegalStateLeaf`, `StoreWithoutUpdate`, `EventHalfMissing`,
`IllegalStoreField` (§8.2), `ClassUnreadable`, `ClassMixed`,
`ContainerMixed`, `ChildNameCollision`, `TransparentContainerUnknown`
(§8.5), `FaceNameIllegal`, `FaceNameCollision`, `FaceDirectionConflict`
(§8.6), `RatesViolation` (§8.7), `ProducedByTwoStages`,
`UndeclaredReturnField` (§8.3, §8.4 w5). These rows are OK. Two of them now
carry a pointer that lands on a section that does not name the kind:

- §8.1 names `ClassUnreadable` twice with a pointer to §8.5 (R7 F12), and
  §8.5 states the rule without the name. Proposed: name it in §8.5's "The
  rule is total" paragraph ("…is a build error naming both families,
  `ClassUnreadable`, …").
- §8.1 names `StoreWithoutUpdate` with a pointer to §8.2, and §8.2's
  "Completeness" states the rule without the name (old text alike).
  Proposed: name it there.

Three Appendix C rows cite a section that holds neither the kind nor the
rule (rows 153, 155, 162; below).

## Circular pointers

None new. One mutual citation, carried from the old text by R2:

- spec 1277 (§6.1, row 29) says "Two clauses type-check a wire (§8.2)", and
  §8.2's headline "Two clauses check a wire" cites §6.1 back. §8.2 still
  states both clauses in full, so neither pointer dead-ends. The duplicate
  is on record for chapter 6's rewrite (survey q2).

## Non-OK rows

All 23 are PREEXISTING. Row numbers are `inbound.tsv` data rows (header
excluded). Grouped by the fix they need.

### Cite §8.5, not §8.3, for "class is implementation detail behind the contract"

§8.3 never says it. §8.5 "Class by declaration shape" does: "Second, class
is implementation detail behind the contract (a component's declared
interface, §8.3)". Old text alike (old §8.5 "**Why.**" paragraph).

| row | place | citing words | fix |
|---|---|---|---|
| 78 | spec 7163 (§11.6) | "a component's class is implementation detail behind its contract (§8.3)" | cite §8.5 (survey D) |
| 207 | log 1201 (D-039 Rejected) | "kind is an implementation detail per §8.3" | track 2: cite §8.5 |
| 311 | log 6257 (D-177 Position) | "not the §8.3-hidden implementation class a component's tier is" | track 2: cite §8.5 |

### Appendix C cites a section that holds neither the kind nor the rule

| row | kind | evidence | fix |
|---|---|---|---|
| 153 | `TierUnreadable` (§8.2, §8.5) | §8.5 never held it; §8.2 names it in "The stores" and "Completeness" | drop §8.5 |
| 155 | `StatelessWithoutOutputs` (§8.2, §8.5) | §8.5 never held it; §8.2 "Completeness" names it, and new §8.3 now does too (R7 F23) | drop §8.5, or replace it with §8.3 |
| 162 | `ArgumentInvalid` (§8.7, …) | §8.7 held no argument check; the float-argument error is §10.5 (spec 5349–5350). Old §8.7 did say "The wrappers are the whole value vocabulary, so a bare integer or bare quantity is a declaration error"; M6 cut it to "§10.5 also holds the wrappers' definitions and their validation", and §10.5 (spec 5352) says "A bare integer or bare quantity is a declaration error" | cite §10.5 in place of §8.7 |

### Phrases chapter 8 never held

| row | place | citing words | what chapter 8 holds | fix |
|---|---|---|---|---|
| 75 | spec 7134 (§11.6) | "That is the reflection class (§8.1), where the shadowing check is an `isdefined`/`!==` pair" | §8.1 "The namespace" has the two-line `isdefined`/`!==` test; no "reflection class" | name what §8.1 holds ("the shadowing check of §8.1") |
| 315 | log 6273 (D-177 Rationale) | same "reflection class" | same | track 2 |
| 206 | log 1198 (D-039 Rejected) | "§8.1's disease at assembly scale" | §8.1 accepts redundancy under fail-loud; the drift argument is D-039's own | track 2: drop the §8.1 pointer |
| 274 | log 4877 (D-145 Rationale) | "§8.1's and D-039's 'structure kept in two artifacts'" | §8.1 holds no such phrase; §8.8 now says it citing D-039 alone (R7 F7) | track 2: drop "§8.1's" |
| 323 | log 6378 (D-179 Rejected) | "§8.1's no-macros/no-introspection foundations" | §8.1 forbids macros; "introspection" appears nowhere in chapter 8 | track 2: "no-macros" only |
| 325 | log 6469 (D-182 Rejected) | "the introspection §8.1 forbids" | same | track 2 |
| 420 | `extensions.md` 286 | cell types are declarations "*evaluated at the activation scalar* (§7.2, §8.2)" | §8.2 retypes plain declarations by the leaf walk (D-263); "evaluated at" is D-166's vocabulary | "retyped at the activation scalar by the leaf walk" |
| 186 | spec 12614 (glossary, *nominal*) | "the one where the conformance check demands exact type match (§8.2, §9.4, §9.5)" | §8.2 never states it; §9.5 holds the exact check (D-286 for pinned leaves) | drop §8.2 |

Side note on row 420: new §8.6 still says a face's cells "are evaluated at
the [activation] scalar on the continuous tier and pinned on the discrete"
(chapter_new.md 1194–1196), carried from the old text. Same vocabulary
question, inside the chapter; for the owner, not an inbound fix.

### §8.5 never named signature violations (D-263 retired them)

Old §8.5 said "There is consequently no signature-shape violation to name".
M5 cut that sentence to D-249's annotation (log 9312–9314; unit D inventory
D-033). New §8.5 says every declaration of a structural fact takes the
component alone and names only `DeclarationOnWrongTier`.

| row | place | citing words | fix |
|---|---|---|---|
| 319 | log 6323 (D-178 Rationale) | "`f`-vs-`g` plus the §8.5 signature arities, `TierSignatureMismatch`" | track 2: history; annotate or drop the §8.5 pointer |
| 374 | log 9273 (D-249 Position) | "`TierSignatureMismatch` owns all three signature violations §8.5 names" | none needed beyond D-249's existing annotation |
| 375 | log 9286 (D-249 Spec) | Spec field lists §8.5 | track 2: §8.2 holds the arity rule now |
| 377 | log 9290 (D-249 Rationale) | "§8.5 said two things about a contract arity on a stateful leaf" | none: true as history |

### Spec fields naming a chapter-8 section that holds nothing of the entry

Survey part E lists these; the rewrite neither caused nor fixed them.

| row | entry | section | where the content is |
|---|---|---|---|
| 202 | D-039 | §8.1 | §8.5, §8.8 |
| 203 | D-039 | §8.3 | §8.5 (class behind the contract, citing §8.3) |
| 270 | D-145 | §8.1 | §8.8 |
| 322 | D-179 | §8.1 | §8.2 "Events: `state_events`", which now cites D-179 |
| 324 | D-182 | §8.1 | chapter 10 |

## OK rows worth a note

- Rows 137 and 165 (`ClassUnreadable`, §8.5) and row 134
  (`StoreWithoutUpdate`, §8.2): rule held, name absent, see the Appendix C
  section above.
- Row 450 (`sample_time_proposal.md` 9) lists §8.7 among the sections
  D-185's adoption amended and quotes "a bare integer or bare quantity is a
  declaration error". True as history; that clause now lives in §10.5 only.
- `src/assembly.jl` 113–116 (not an inbound row, survey D) cites §8.7 for
  the bare field name applying one entry to every element; M3 makes that
  true now.
