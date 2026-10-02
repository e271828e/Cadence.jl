# Chapter 7: the inbound check

Every row of `inbound.tsv` (269) judged against `chapter_new.md`, with
`units/B/companion_addition.md` as the companion's new paragraph. The verdict
per row is in `inbound_check.tsv` (the input columns plus `verdict` and
`note`). The verdict script is `scratch_inbound/verdicts.py`; the phrase check
is `scratch_inbound/phrases.py`.

## Counts

| verdict | rows |
|---|---|
| OK | 177 |
| VAGUE | 23 |
| MISSING | 4 |
| COMPANION | 1 |
| RETARGET | 0 |
| LOSS | 0 |
| HISTORY | 64 |

HISTORY is the 56 `briefs/` rows and the 8 `tools/gloss_table.md` rows.

Of the 205 live rows, 37 relied on content the old chapter did not hold
(survey part D's list, confirmed). Ten of them are now OK, because R5 and R15
put the invariant's scope into §7.5. The other 27 are the 23 VAGUE rows and
the 4 MISSING rows. Each one already failed the old chapter in the same way.
No row lost content to the rewrite.

## LOSS

None. Every row that relies on cut or moved content still holds:

- M1, the codegen-freedom paragraph. Spec 4764 (§9.7) quotes
  "buffer-unchanged-within-a-sweep", which survives word for word. §7.1 states
  the rule in its own words ("the buffer is unchanged within a sweep") and
  points to §9.7 only for the CSE and the rebuilt views, so the two sections
  do not point at each other.
- M2, one home per datum. Glossary 12534 cites §5.2 and §7.1 together. §5.2
  (spec 820–822) holds "The buffer holds `x`, the stores hold `s` and `m`" and
  "No store mirrors another". §7.1 keeps "no state cells ... interface, not
  transport". Spec 452 still finds the framework-owned buffer in §7.1 and "the
  buffer that holds `x`" in §7.3.
- M3 and M4, the walked-type list. Spec 3258 holds, because §7.2 keeps
  `FrameTransform` as the Walked tier's one example. `extensions.md` 294
  holds, because §7.2 keeps the `@kwdef` pattern sentence. `extensions.md`
  334 is the one COMPANION row (below).
- §7.4's step numbers. Spec 10578 and D-125 3784 cite step 2, and D-169 6002
  cites step 4. All four steps keep their numbers. Step 2 keeps "one-line
  function body", and step 4 keeps the identity decode as transport.

## COMPANION

**`extensions.md` 334** (§3.5). "whether [§7.2][s7-2]'s mechanical
parametrization of the walked payload list simply extends to parameter
carriers". The payload list moved to `migration_outline.md`, "The
parametrization pass". §7.2 keeps the Walked tier, "The walked types'
parametrization is mechanical" and one example. Proposed edit to
`extensions.md`:

> whether [§7.2][s7-2]'s mechanical parametrization of the walked tier, whose
> FlightPhysics payload list `companions/migration_outline.md` gives under
> "The parametrization pass", simply extends to parameter carriers, or
> participation is opted into per component.

A shorter alternative keeps the sentence and changes only "of the walked
payload list" to "of the walked tier". The list is then one hop away, through
the companion's citation of §7.2.

## RETARGET

None.

## MISSING

All four rows were MISSING before the rewrite. None is a loss. Each one goes
to track 2 with the edit shown.

| file:line | relies on | old chapter | proposed edit |
|---|---|---|---|
| spec 4766 (§9.7) | "per-call by topological necessity either way (§7.1)" | never held. Old §7.1 said only that the executor is spelled rebuild-per-call (M1 trimmed that to "views rebuilt per call", §9.7) | drop "([§7.1][s7-1])". §9.7's own "Views are spelled rebuild-per-call" carries the sentence |
| spec 12067 (Appendix C, `IllegalPortType`) | §7.1 for a port type the walk cannot lay out | never held | replace §7.1 with §4.3, which states the condition (547–549) |
| spec 12549 (glossary, *scratch*) | §7.5 for "the integrator's buffers and the mid-step table" | never held | drop §7.5. §10.3 and §10.4 carry it |
| log 7349 (D-203 Rejected) | "the clock is seeded `zero(T)` (§7.2)" | never held | drop "(§7.2)", or cite the section that states the run's time scalar. No spec sentence on the seed was found |

## VAGUE

Every VAGUE row is pre-existing. The old chapter matched it no better, and it
holds in substance. They group as follows for track 2.

**The §7.5 "carve-out" (7 rows).** These are spec 4917 and 7061, D-107
Position 3194, D-116 Rationale 3491 and 3493, D-176 Rationale 6297, and D-288
Rationale 12008. Each was MISSING before the rewrite. They now hold in
substance, because §7.5 says publication is not a phase body (D-288) and that
its per-boundary snapshot allocation sits with logging on the framework side,
outside what the invariant claims is zero. The word "carve-out" is not
§7.5's. Track 2 can leave them, since the referent is now clear, or reword
"the §7.5 carve-out" to "the §7.5 scope".

**"Model sweep" against "stepping loop" (2 rows).** Spec 7819 and D-136
Rationale 4298 scope the invariant to "the model sweep". §7.5 now says "the
stepping loop", as spec 4406 does. Track 2: pick one term. "Stepping loop"
matches §9.4 and §7.5.

**Rules that §7.1 implies and never states (7 rows).**
- "§7.1 admits no pinned state leaf": spec 2599, D-295 Position 12324 and
  D-166 Rejected 5860. "of a common eltype `T`" survives word for word.
  §7.1 must not cite D-295 for it.
- "§7.1 forces every state leaf to follow the activation scalar": spec 2195
  and D-166 Rationale 5812. §7.2 states it ("in the `x_init`-derived state
  type alike"). Proposed: cite §7.2 beside §7.1 at spec 2195.
- "§7.1's walk being total": D-166 Annotation 5836. §7.1 closes the
  vocabulary, and the walk is §7.2's and §8.2's.
- "§7.1's leaf walk": D-162 Position 5575. §7.1 gives the flat layout, and
  the leaf walk's glossary home is §8.2.

**Phrases from elsewhere (3 rows).**
- Spec 11539: "the layout image of `X`" is Appendix B's phrase.
- Spec 2258: "not memory" is D-077 Rejected's phrase.
- `extensions.md` 283 quotes "no `::SomeType{Float64}` annotations". The rule
  reads "no `::SomeType{Float64}` return-type annotations", in the old text
  and in the new. Proposed: fix the quote.

**`sizehint!` (2 rows).** Spec 6514 and D-137 Rationale 4379 speak of the
`sizehint!` "for the expected duration". §7.5 says "to the retention bound",
which is the reconciled form those rows describe. No edit is needed.

**Chapter 3's summaries (2 rows).** Spec 304 says continuous state is "an
isbits struct of real scalars", where §7.1 has a flat NamedTuple of real
scalars and `SArray`s. Spec 331 says discrete state is "any isbits value",
where §7.3 has fields that are isbits or a `Symbol` (D-231). These belong to
chapter 3's rewrite.

## Rows fixed by the rewrite

Ten rows that the old chapter did not support are OK now, because R5 and R15
added §7.5's scope sentences:

- spec 4406, 6420, 6493, 10220 and 10778;
- D-066 Position 1892;
- D-135 Rationale 4228;
- D-137 Rationale 4369;
- D-241 Rejected 9001 (two rows).

Pending 93 ("Publication's garbage") also finds publication's snapshot
allocation in §7.5 now.

## Quoted phrases

Each phrase on survey part D's list is in `chapter_new.md` exactly as often
as it was in `chapter_old.md`:

- Present word for word: "buffer-unchanged-within-a-sweep", "of a common
  eltype `T`", "stay `Float64`", "promotion handles mixing", "the canary", "a
  documented tolerance", "interned, immutable and never freed" and "governed
  by contract rather than by checks".
- Never present word for word, in the old text or the new:
  - "the explicit cast": both texts read "explicit, invariant-free cast".
  - "domain wrapper type": both texts read "Domain wrapper types",
    capitalized.
  - "the CI invariant": both texts read "CI invariant".
  - "the discrete exemption": both texts read "the *discrete* side's
    exemption".

  The rows that cite them paraphrase and do not quote, except `extensions.md`
  283 (above).
- `FrameTransform` and "`@kwdef` defaults pin the no-argument case" are kept
  (R2).
- `IllegalStateLeaf` is new at §7.1 (F17). It supports spec 12001.

## Spec fields to update at landing

These are not inbound failures. They are noted because the rewrite now cites
these entries at new sections:

- D-035 gains §7.1.
- D-235 gains §7.2.
- D-288 gains §7.1 and §7.5.
- D-135 and D-116 already list §7.5.

Survey part D, "Log entries whose Spec field would change", has the full list.

## Outside `inbound.tsv`

Comments in `src/` and `test/` are not rows. The ones about the carve-out and
the scope (`src/dataplane.jl` 670, `src/sim.jl` 2227,
`test/test_localization.jl` 232, `test/test_stepper.jl` 89) now hold in
substance, as the carve-out group above does.

Three are already wrong and go to track 2:
- `src/build.jl` 1397 cites §7.3 for "no store mirrors another". §5.2 holds
  it.
- `src/build.jl` 1349 cites §7.5 for the `ẋ` buffer as integrator scratch. It
  is the same gap as glossary 12549.
- `src/diagnostics.jl` 1043 and `src/executor.jl` 383 cite §7.3 for "a
  discrete successor is the store's own type exactly". §9.5 states it. This
  was already in survey part D.
