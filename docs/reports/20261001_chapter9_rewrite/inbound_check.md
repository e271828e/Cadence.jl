# Inbound citations into chapter 9, checked against the rewrite

Scope: the 274 rows of `inbound.tsv` that do not come from a `decisions.md`
**Spec.** field. Each row was judged by hand against `chapter_new.md`, with
`chapter_old.md` consulted for every row the new text does not support. A
script only grouped the rows by cited section and pulled spec context.
Per-row results are in `inbound_check.tsv`. Line numbers below are
`chapter_new.md` (N) and `chapter_old.md` (O).

## Counts

| status | rows |
|---|---|
| OK | 214 |
| RETARGET | 36 (31 caused by the rewrite, 5 already mis-targeted) |
| VAGUE | 14 |
| COMPANION | 4 |
| MISSING, stated in the old chapter (loss) | 0 |
| MISSING, not stated in the old chapter either (PREEXISTING) | 6 |

No row lost its fact. Every fact the rewrite moved is either in another
chapter-9 section or in the companion.

## RETARGET caused by the rewrite

### §9.1 → §9.2: the `Deployment` and the warnings policy (28 rows)

Old §9.1 held "The `Deployment` constructor" (O183–252) and "Where a build
warning lives" (O254–265). Both now sit in §9.2: The `Deployment` (N317–418)
and Warnings (N453–472).

| row | fact | evidence |
|---|---|---|
| spec 3196 | three sources for `Δt_base` | N330–347 |
| spec 3233 (code comment) | the warning channel around the build's steps | N460–464 |
| spec 3272 | `EmptyFaceSelection` lands on the `Build`'s list | N463–464 |
| spec 4798 | event parameters beside `h`, `N_base`, the algorithm | N322–326, N379–390 |
| spec 5046 | the deployment-time constraint pool | N357–366 |
| spec 5054 | a deployment binds `Δt_base = 2 ms` | N402–418 (the worked example was already in old §9.2) |
| spec 6343 | where the `Deployment` comes from, what it carries | N319–326 |
| spec 6372 | the constructor sits outside the `Build` | N320–321 |
| spec 7793 | grid, schedule and event parameters are the deployment's | N322–326, N392–400 |
| spec 8304 | deployment validation runs every check and throws once | N374–386. "Throws once" is implicit in "collected and reported", as it was in O237 (unit A2 flagged it) |
| spec 8424 | warnings live on artifacts; `warnings(x)` | N455–472. Cites §9.1, §9.2; drop §9.1 |
| spec 10821 | the `Deployment` carries `Schedule`, diagnostics, `warnings` | N324–326. Cites §9.1, §9.2; drop §9.1 |
| spec 10827 | `N_base` derived and validated ≥ 1 | N333–334 |
| spec 10828 | the `Δt_base` keyword, `:derive` | N333–347 |
| spec 10833 | one of three sources | N330 |
| spec 11379 | `DeploymentInvalid` | N374–386 |
| spec 11457 | `GridUtilization` | N445–451, N466–467. Cites §9.1, §9.2; drop §9.1 |
| spec 11868 | anchors join the deployment pool | N361 |
| spec 11898 | every discrete period is an integer multiple (harmonic grid) | N366, N381 |
| spec 12069 | scalar-free, compared as a value, materialized by `Simulation` | N319–328. Cites §9.1, §9.2; drop §9.1 |
| decisions 8294 (D-229 Position) | deployment validation | N374. Log text; keeps its day unless the user rules otherwise |
| decisions 8332 (D-229 Rejected) | deployment validation is collected | N374–377. Log text |
| sample_time_proposal 304 | `Δt_base`, `h`, `N_base` bind and validate | N322–334. Adopted proposal |
| sample_time_proposal 335 | collected `DeploymentInvalid`s | N374–377. Adopted proposal |
| sample_time_proposal 769 | deployment binding gains pool, derive-vs-declare, anchor resolution | N349–372. The triples half stays §9.1 (N109–133) |
| implementation 118 (`src/diagnostics.jl` Spec list) | warning channel, `DeploymentInvalid`'s grid payload, `GridUtilization` | N374–386, N445–467. The list names §9.1 only; it needs §9.2 |
| implementation 495 | the constructor has one throw per call | N374–386 |
| pending 90 | a build warning on the artifact | N455–464 |

### §9.1 → §9.4: the retyping list (2 rows)

Old §9.1's activation step listed how cells are retyped (O170–178). New §9.1
says only that the step "retypes the cells and the walked state type at `T`
… as §9.4 details" (N197–199). The detail is §9.4's (N623–631).

| row | fact | evidence |
|---|---|---|
| spec 2303 | cell types single-sourced from the producer side per activation | N623–626 |
| spec 12095 (Appendix D, `Pinned`) | the per-leaf walk "applied at activation" | N623–629 |

Citing both §9.1 and §9.4 would also hold, since N197–199 still says the step
retypes cells.

### §9.1 → §9.5: the flat buffer (1 row)

| row | fact | evidence |
|---|---|---|
| decisions 6859 (D-195 Rationale) | continuous state lives in the flat buffer, discrete state in per-component stores | O178 "The flat `x` buffer and the table are laid out" is gone. N922–924 (§9.5, Handler returns) states the flat buffer against per-field stores; N631 (§9.4) says the state buffers are laid out. Log text, so no edit is expected |

## RETARGET already mis-targeted before the rewrite (5 rows)

The old chapter put these facts in the same place the new one does.

| row | cited | fact | now and then in |
|---|---|---|---|
| spec 10379 | §9.7 | pre-materialize an activation through `activations` | §9.4, N684–696 (O567–573) |
| decisions 10895 (D-272 Position) | §9.7 | same | §9.4. Log text |
| linearization_walkthrough 595 | §9.7 | `build(m; activations = …)` pays the compile ahead of time | §9.4 for the keyword. §9.7 states only the compile cost and the precompile rung (N1129–1135) |
| spec 11781 (glossary, buffer) | §9.2 | a service invocation instantiates its store set from the layouts | §9.4, N728–730 (O591–593). Unit A2 noted it |
| spec 11832 (glossary, execution order) | §9.1 | the hot loop runs a flat entry list with zero runtime graph logic | §9.7, N1000–1005 (O795–800) |

## COMPANION (4 rows)

Unit D moved the C172 trim comparison out of §9.6 into
`companions/flight_case_studies.md` section 4 (`units/D/companion_addition.md`).
§9.6 keeps only the activation-client sketch (N959–985).

| row | fact | evidence |
|---|---|---|
| decisions 4400 (D-139 Rationale) | `Kinematics.Initializer` survives aircraft-side, `atmosphere::Model` respelled as a field handle | companion bullet 2 (O767–773). Log text; it corrects an older wording |
| trim_environment_walkthrough 6 | §9.6 as ground truth for the trim respelling | companion section 4 |
| trim_environment_walkthrough 502 | per-residual scalings stay aircraft-side | companion bullet 2 (O768–769). Unit D also offers §14.7 |
| trim_environment_walkthrough 576 | the `Initializer` claim and its correction | companion bullet 2 |

## MISSING

### Stated in the old chapter (losses)

None.

### PREEXISTING (6 rows)

The old chapter did not state these either.

| row | cited | fact | note |
|---|---|---|---|
| spec 9866 (§14.7) | §9.6 | trim's default is nonlinear least squares in the trust-region/LM family | §9.6 only ever said "the `Dual` activation … for exact residual Jacobians" (O759–760, N968–971). §14.8 names the in-house LM default (unit D) |
| spec 11496 (Appendix C, `ArgumentInvalid`) | §9.2 | collection "over the materialization's keywords" | Neither chapter states materialization-keyword collection; only deployment validation is collected (unit A2) |
| decisions 5163 (D-152 Rationale) | §9.5 | auto-published cells belong to no stage | Neither chapter mentions auto-publication (unit C). Log text, and D-252 retired auto-publishing |
| decisions 9414 (D-253 Position) | §9.1 | "Stratum B is the nominal evaluation's structural half; the nominal activation is B's products plus C's typing" | Superseded by D-259. Both chapters say the nominal activation comes from the same probe chain, never a separate pass (O158–162, N187–191). Log text |
| sample_time_proposal 412 | §9.3 | an offset component's cells hold the probe's values until first tick | Superseded by D-205. Both chapters make probe values garbage once the build ends (O475–478, N549–552). Adopted proposal |
| sample_time_proposal 772 | §9.2 | the bound schedule as a printable artifact on the `Simulation` | Superseded by D-254. Old §9.2 already put the `Schedule` on the `Deployment` (O330–331). Adopted proposal |

## Other notes from the OK and VAGUE rows

- spec 10838 (Appendix B), OK: §9.2 states derivation at the coarsest
  admissible value, printed with its drivers. But Appendix B's "in a fully
  anchored model omitting both" contradicts §9.2's explicit `Δt_base =
  :derive` (N340–347). This was already so before the rewrite (unit A2, F22).
- spec 1979, OK: §9.1 is cited as the place of the structural walk. Neither
  chapter lists the D-246 shadowing check among the structure step's checks.
- spec 8242, VAGUE: "§9.1 already fixed when each check runs". Deployment
  checks now sit in §9.2, so "§9.1–§9.2" would be more accurate.
- implementation 511 (`src/deployment.jl` Spec list), VAGUE for §9.1: §9.1 now
  holds only the steps-table row for deployment. §9.2 is already listed.
- implementation 832, OK: it cites D-166 for the CI `Dual` sweep. §9.4 now
  cites draft D-280 there.

## Spec fields to revise

These are the `decisions.md` entries whose **Spec.** field names a §9.x
section. The check compared each field with the sections that cite the entry
in `chapter_new.md`, and with where the entry's content now sits.

### Caused by the rewrite

A named section lost all of the entry's content, or the content moved to a
section the field does not name.

| entry | Spec field (ch. 9) | change | reason |
|---|---|---|---|
| D-139 | §9.6 | drop §9.6 | the `Initializer` respelling moved to `flight_case_studies.md` section 4. §9.6 holds nothing of D-139 |
| D-227 | §9.1 | §9.1 → §9.2 | the `algorithm` keyword binds on the `Deployment` (N322–324, N384) |
| D-234 | §9.1 | §9.1 → §9.2 | `N_base` appears only in §9.2 now (N333–336, N380, N383) |
| D-113 | §9.1 | §9.1 → §9.2 | its chapter-9 piece is the `DeploymentInvalid` payload of parameter, value and violated constraint (N374–377) |
| D-133 | §9.1 | §9.1 → §9.2 | the event parameters as deployment parameters, validated beside the grid ones (N322–326, N385–390) |
| D-229 | §9.1 | add §9.2 | deployment validation is now cited and stated in §9.2 only (N374–377). Keep §9.1 only if the field should also cover the barrier sentence (N31–33), which cites D-259 |
| D-254 | §9.1, §9.2 | drop §9.1 | everything moved to §9.2. §9.1 keeps one uncited steps-table row (N40) |
| D-250 | §9.1, §9.2 | drop §9.1 | the warnings policy moved to §9.2 (N453–472) |
| D-187 | §9.1, §9.2 | drop §9.1 | old §9.1 only pointed at the suggestion message. The diagnostics are §9.2's (N420–451) |
| D-186 | §9.1, §9.2 | none | the fold stays in §9.1 (N118–133). Binding sits in §9.2. Listed because both sections are touched |

### Newly cited by the rewrite in a section the field does not name

| entry | Spec field (ch. 9) | add | where cited now |
|---|---|---|---|
| D-185 | §9.7 | §9.1 | N109, `sample_times` validation in the structure step |
| D-052 | §9.5 | §9.4 | N646, N668, N721, the executable-set, laziness and caching rulings. Old §9.4 held this content without citing D-052 |

### Already stale before the rewrite (not caused by it)

- D-261 lists §9.2 only, but both chapters cite it in §9.1 (N162, O136).
- D-253 lists §9.1–§9.4, but both chapters also cite it in §9.7 (N993, O793).
- D-033, D-106 and D-256 list §9.7, which holds nothing of theirs. D-163
  lists §9.7 for a float-comparison rule §9.7 does not state (unit E).
- D-152 lists §9.5 for auto-published cells, which neither chapter states.
- D-166 lists §9.4 and §9.5. It is superseded by D-263, and the new chapter
  no longer cites it. Its §9.4 citation went to draft D-280.

### Outside the brief: cited entries whose Spec field names no chapter-9 section

- D-078 (§9.1, N91), D-060 (§9.3, N585), D-099 (§9.4, N699) and D-157 (§9.5,
  N957) have Spec fields without a §9.x.
- D-048, D-050 and D-070 have no **Spec.** field.
- D-280, D-281 and D-282 (§9.4) are drafts with no entry in `decisions.md` yet.
