# Inbound citations into chapter 10, checked against the rewrite

Scope: all 328 rows of `inbound.tsv`. Each row was judged by hand against
`chapter_new.md`. `chapter_old.md` was checked for every row the new text
does not support. A script only grouped the rows by cited section. The 55
rows from a `decisions.md` **Spec.** field were judged briefly, for whether
the cited section still holds content of the entry. Per-row results are in
`inbound_check.tsv`. Line numbers below are `chapter_new.md` (N) and
`chapter_old.md` (O). Spec lines are at `08f5dff`.

## Counts

| status | rows |
|---|---|
| OK | 314 |
| RETARGET | 4 (all caused by the rewrite) |
| COMPANION | 0 |
| VAGUE | 0 |
| MISSING, stated in the old chapter (LOSS) | 1 (a ruled cut, R3; no fact leaves the design) |
| MISSING, not stated in the old chapter either (PREEXISTING) | 9 |

No row cites the Flight.jl evidence that R2 moved to the companion, so no row
is COMPANION. The six bare `§10` rows are chapter-level pointers that the
chapter still satisfies, so they count as OK rather than VAGUE.

## RETARGET caused by the rewrite

### §10.4 → §10.1: frame and boundary (R1, 3 rows)

Old §10.4 defined the frame and the boundary and listed the boundaries that
are not frame tops (O130–141). New §10.1 holds both definitions (N17–31).
New §10.4 keeps only "`t*` is a boundary, not the top of a frame", with
parenthetical glosses (N171–173).

| row | fact | evidence |
|---|---|---|
| spec 5827 (§11.1) | the frame, "the grid step §10.4 names" | N17–21 (O132–135). §10.4 keeps a gloss only |
| spec 7598 (§12.3) | published boundaries are grid, `t*` and boundary zero | N26–31 (O139–141). §10.4 still states `t*`'s counter increment (N420–421), so citing both would hold |
| spec 12210 (glossary, *boundary*) | every grid point is a boundary; `t*` and boundary zero are not frame tops | N26–31 (O139–141). §10.4 keeps the `t*` half (N171–173) |

### §10.6 → §10.3: when external readers observe the table (M2, 1 row)

"External readers observe the table only after the boundary sequence
completes" moved from §10.6 (O973–975) to §10.3 (N159–161). §10.6 keeps a
pointer (N1089–1091).

| row | fact | evidence |
|---|---|---|
| spec 5945 (§11.2) | publication only after the boundary sequence completes, "§10.3 as extended by §10.6" | N159–161. §10.3 now states the extension itself, so "as extended by §10.6" can go |

## RETARGET already mis-targeted before the rewrite

None as RETARGET. The mis-targets found are listed under PREEXISTING below,
with a few softer cases under "Other notes".

## COMPANION

None. R2's moved evidence (`units/A/companion_addition.md`) has no inbound
citation.

## MISSING

### Stated in the old chapter (LOSS)

One row. It is a ruled cut, and the fact is still in the log.

| row | cited | fact | old | new |
|---|---|---|---|---|
| decisions 5277 (D-154 Rejected) | §10.6 | "*Live-table reads under canonical order:* §10.6's standing rejection — executor order becomes semantics." | O924–927 listed "live-table reads under the canonical execution order" among the rejected shapes D-154 records | N1024–1026: "[D-154] and [D-100] record the rejected shapes." R3 cut the list. N1002–1011 keeps the principle: handler order within a round is unobservable, and no trajectory depends on execution order |

The pointer is now circular. D-154's Rejected entry defers to §10.6, and
§10.6 defers to D-154. The full argument survives in D-100's Rejected field
("trajectories then depend on the executor's schedule order", decisions
2888). Log text keeps its day, so no edit is required. If the user wants the
chain to close, §10.6's pointer could name D-100 first for this shape.

### PREEXISTING (9 rows)

The old chapter did not state these either.

| row | cited | fact | note |
|---|---|---|---|
| spec 4063 (§9.4) | §10.4 | event localization runs as `Float64` sweeps by design | Neither chapter says `Float64`. §10.4 has the nominal scalar (N192) and "Newton and AD localization are rejected" (N345–346, O301–302) |
| spec 12249 (glossary) | §10.6 | the opposite crossing direction is a second event with the negated guard | Neither chapter says it. §10.6 says only that eligibility is never a bare sign change (N906–907) |
| decisions 2125 (D-074 Rejected) | §10.1 | "the §10.1 `task_local_storage` lesson" | The lesson is D-017's Rejected field (decisions 610–620). Neither §10.1 states it. New §10.1 points at D-017 for the rejected foreign-loop alternative (N43–44) |
| decisions 2500 (D-086 Rejected) | §10.1 | "a relied-on seam on internal ABI — the §10.1 lesson" | Same as the D-074 row |
| extensions 47 | §10.5 | §10.5 records why atomic subsystems are an artificial-loop factory | Both chapters say only "no atomic assemblies" and "no coarsening is needed" (N630–635, O598–604). The artificial-loop reason is D-019's Rejected field |
| extensions 70 | §10.5 | §10.5 records "no phase offsets in the first cut" | Stale since D-185. Both chapters have phases (N533–544) |
| extensions 175 | §10.5 | §10.5 calls `Subsampled`'s parent-relative multipliers a call-tree artifact | Neither chapter mentions `Subsampled`. The ratios-are-intrinsic half holds (N685–689). D-019's Rejected field holds the call-tree remark |
| extensions 323 | §10.4 | §10.4 rejects Newton/AD localization "on C⁰ grounds" | Both chapters state the rejection (N345–346) without the reason. The C⁰ reason is D-018's Rejected field (decisions 648) |
| sample_time_proposal 63 | §10.5 | quotes "absolute rates are deployment decisions made once at the root" | A pre-D-186 quote. Neither chapter holds it. The current doctrine is "When an anchor belongs in a library type" (N728–749). Adopted proposal |

## Other notes from the OK rows

- spec 12116 (glossary, *scratch*), OK: cites §10.4 for the mid-step table
  as scratch. §10.3 is the section that calls the table integrator scratch
  (N149–152), before and after the rewrite. §10.4 shows only the mid-step
  trial evaluations.
- spec 3765 (§9.2), OK: cites §10.4 and §10.6 for grid-independence. Only
  §10.4 states it (N493–494). §10.6 defines `firing_budget`.
- decisions 3991 (D-133 Position), OK for §10.4's root-finder. The
  validation details it also names (positive tolerance, integer budget ≥ 1)
  now sit only in §9.2, by R5 (N489–493).
- decisions 8365 (D-229 Rejected), OK: §10.4 still says failures are
  collected into `DeploymentInvalid`, now as a pointer to §9.2 (N491–493).
- decisions 7257 (D-205 Rationale), OK: it describes the "tick at `t₀⁻`"
  defense §10.5 once made. R7 cut the last echo of that defense and mapped it
  to this same Rationale.
- spec 7500 (§12.2), OK: "§10.7 … left the coarse phase's primitive open".
  Both chapters say the primitive "is settled in §12.2" (N1215–1218). This is
  F12, kept as written.
- sample_time_proposal 779, OK: it wants the coincidence documentation next
  to the simultaneous-tick rule. M7 moved "Coincidence and stagger" after the
  worked example (N791), so the two are no longer adjacent (N615 vs N791).
- Quoted phrases "the due set is a pure function of the frame index"
  (extensions 133, sample_time_proposal 253) are paraphrases in both
  chapters. The substance holds (N526–544).

## Spec fields

Brief, per the scope. Fields compared with the sections that cite each entry
in `chapter_new.md`.

### Caused by the rewrite

- D-016 lists §10.6. Old §10.6 cited it only inside the rejected-shapes list
  R3 cut (O924–925). New §10.6 still has guards and handlers reading the
  fresh boundary sweep, D-154's refinement of D-016, but no longer cites
  D-016.
- D-152 (superseded) lists §10.6 for the same cut list. Historical.
- D-081 lists §10.6 and §12.3. The rewrite now cites it in §10.1 (N27) and
  §10.4 (N415–434), its real home. Neither is in the field.
- D-182 lists §10.6. The rewrite cites it only in §10.4 (N259–390).
- D-082 and D-274 have no §10.x in their fields. D-082 is now cited in
  §10.4 and §10.6, D-274 in §10.2 and §10.6.
- D-154 is newly cited in §10.4 (N367). Its field lists §10.6 only.

### Already stale before the rewrite

- D-156 lists §10.1, which holds only the loop-ownership premise D-156
  cites. Its rule is in §10.2.
- D-018 lists §10.6. Both chapters cite it only in §10.4. §10.6 applies its
  degrade-not-error doctrine to the firing budget.
- D-133 lists §10.5, which holds only the harmonic grid that D-133 keeps the
  constants out of.
- D-153 lists §10.6. D-181 replaced its re-arm flag. §10.6 keeps the named,
  normative per-event registers.

### Cited in chapter 10 with no §10.x in the field

D-015 (§10.5), D-027 (§10.7), D-132 (§10.7), D-187 (§10.5), D-256 (§10.4)
and D-283 (§10.5). These are newly cited by the rewrite, except D-015.
