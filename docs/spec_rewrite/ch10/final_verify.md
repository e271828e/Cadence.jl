# Chapter 10: final cold verification

Scope: every hunk of `git diff bddddc5 -- units/*/new.md` (hunks counted
with `-U0`), checked against its log line (chapter_fixes.md, ruled_edits.md),
the item or ruling behind it (chapter_pass.md, chapter_rulings.md,
rulings_batch.md "Status"), and units/<U>/old.md.

## Unit A

Hunks checked: 12. Log lines found for all 12.

| hunk | log | item | verdict |
|---|---|---|---|
| intro rewrite | P35 | P35 | OK. Wording is P35's own; "the frame and the boundary" drop is P35's. |
| boundary bullet | P3 | P3 | OK. "in the final form §10.6 calls the macro-sequence" is sourced by old §10.6 ("The boundary macro-sequence, in its final form", spec 5672). |
| `t*` swap | P42 | P42 | OK. Bold untouched. |
| step-boundary gloss | P7 (ruled) | chapter_rulings P7 | OK. Gloss is the ruling's wording; §10.6 pointer kept. |
| trial sweeps | P1 | P1 | OK (see B1 for the definition it now points to). |
| `N = 0` | ruled_edits K10 | K10 | OK. Exact proposal wording. |
| L104 wrap | P48 | P48 | OK, wrap only. |
| "whole axis" | P39 | P39 | OK. Old heading "Why fixed-step low-order suffices" makes the axis the integration method. |
| L126 wrap | P48 | P48 | OK, wrap only. |
| ladder wrap | P47 | P47 | OK, wrap only. |
| boundary sweep unlink | ruled_edits K12 | K12 Status | OK. |
| External readers bold | P33 (ruled) | chapter_rulings P33 | OK. Bold is the ruling's headline clause, D-023 in the sentence. |

Problems: none.

Note (no fix needed): P33's "These readers are the GUI, logging and network
output" reads as a closed list, as old's "(GUI, logging, network output)"
did. The ruling asked for the old list at its old strength, so it stands.

## Unit B1

Hunks checked: 15. Log lines found for all 15.

| hunk | log | item | verdict |
|---|---|---|---|
| `localized` link at L8 | P8 | P8 | OK. L8 is §10.4's first use. |
| chain blockquote wrap | P48 | P48 | OK, wrap only. |
| arrival sweep gloss | P10 | P10 | OK. Gloss is L100's own sentence. |
| `localized` unlink, trial evaluations | P8, P1 | P8, P1 | OK. Glossary *sweep*: localization guard "trial evaluations" run the interior sweep. |
| illegal pairing | P40 | P40 | OK. Old's reason ("only the sign form offers [a root]") makes the pairing a localized `Bool`. |
| sign-form `σ` | P44 | P44 | OK. |
| piston engine | P45 | P45 | OK. "Its" binds to the engine. |
| interior sweep unlink, tick gloss | K12, P11 | K12 Status, P11 | OK. Gloss is P11's wording; glossary *tick* supports it. |
| boundary sweep unlink | K12 | K12 Status | OK. |
| L309 wrap | P48 | P48 | OK, words identical. |
| warns-nothing wrap, dense output | P47, P2 | P47, P2 | OK. §10.2 names the product "dense output"; D-018 kept. |
| ITP | K11 | K11 | OK. Exact proposal. |
| AD | K11 | K11 | OK. Exact proposal. |
| `Deployment` link and gloss | P9 | P9 | OK. Gloss matches glossary *`Deployment`* ("the artifact the grid parameters fix", "scalar-free"); D-256 kept. |
| tolerance reason, remainder gloss | P25, P13 | P25, P13 | OK. The interpolant bound stays stated at L180-181; remainder gloss is the glossary's. |

Problems: none.

Note (no fix needed): P11's gloss "set at the last instant their stages and
update ran" hangs "their" on cells, which have no stages; the stages belong
to the discrete component. It is P11's exact wording and claims nothing
wrong.

## Unit B2

Hunks checked: 6. Log lines found for all 6 (two are the P47/P48 wraps; the
orchestrator's rewrap is wrap-only, words unchanged).

| hunk | log | item | verdict |
|---|---|---|---|
| "tiny remainder step" wrap | P47 | P47 | OK, wrap only. |
| projection paragraph wrap | P48 (L450) | P48 | OK, words and bold identical. |
| `localization_budget` bold | P32 (ruled) | chapter_rulings P32 | OK. Bold moved to the default, as old bolded **8**; "integer" kept from old (78), which only keeps a claim the ruling's wording dropped. Citations unchanged. |
| §14.8 doctrine wrap | P48 (L481) | P48; P5 rejected | OK, words identical. |
| `Deployment` unlink, "third such keyword" | P9, P6 | P9, P6 | OK. Link and gloss now at B1 L192, §10.4's first use; glossary *firing budget* calls it a deployment keyword. |
| "All three are recorded" plain | P31 (ruled) | chapter_rulings P31 | OK. Citations kept. |

Problems: none.

## Unit C1

Hunks checked: 4. Log lines found for all 4.

| hunk | log | item | verdict |
|---|---|---|---|
| D-288 added | ruled_edits K7 | K7 | OK. D-288's gate bullet: "At a localized event time `t*` the empty due set is arity selection"; its Rationale repeats "no sentinel index". `[d-288]` is defined at spec 13200. |
| output stages at `t₀` | P27 | P27 | OK. "still run at `t₀`, as above" keeps "due or not" by pointer to the bullet just above (D-205); both citations kept, as the log says. |
| probe wrap | P27 (rewrap) | P27 | OK, words identical. |
| FCS cascade | P15 | P15 | OK. Same claim; "FCS" spelled out at its first §10.5 use. |

Problems: none.

## Unit C2

Hunks checked: 6. Log lines found for all 6.

| hunk | log | item | verdict |
|---|---|---|---|
| composition bold dropped | P29 (ruled) | chapter_rulings P29 | OK. D-019 and D-185 kept. |
| companion path | P28 | P28 | OK. `docs/design/companions/sample_time_proposal.md` exists. |
| hyperperiod gloss | P20 | P20 | OK. Spec §9.2 (3816): "The chart's pattern repeats with period `lcm(Dᵢ)`". |
| "an FCS scope" | P15 | P15 | OK. C1 spells FCS out earlier in §10.5. |
| frame unlink | P14 | P14 | OK. C1 links frame first in §10.5. |
| companion path | P28 | P28 | OK. |
| trailing blank line | P47 | P47 | OK. |

Problems: none.

## Unit D

Hunks checked: 15. Log lines found for all 15.

| hunk | log | item | verdict |
|---|---|---|---|
| `firing_budget` link | P17 | P17 | OK. |
| FSM spelled out | P19 | P19 | OK. Avoids nested parentheses, as logged. |
| "Two consequences" wrap | P47 | P47 | OK, wrap only. |
| prior bold dropped, drain sentence cut | P30 (ruled), P22 | chapter_rulings P30, P22 | OK. D-082 kept. The cut claim survives at B1 L152-153; "drain" has no other use in §10.6, so its link goes with no orphan. |
| `restore!` wrap | P47 | P47 | OK, wrap only. |
| condition gloss | P18 | P18 | OK. Matches glossary *condition* ("set this build to this state", "path-addressed sparse overlay"); §14.1 is the glossary's citation. |
| `y_direct` chains | P41 | P41 | OK. §10.5 ties stage 2 to `y_direct`. |
| epoch definition moved | P43 | P43 | OK. Bold and D-154 untouched. |
| serialization wrap | P48 | P48 | OK, wrap only. |
| firing budget paragraph | P17, P46, P4 | P17, P46, P4 | OK. "Priors stay honest" now follows the budget; old (159) made it follow the budget and the two rejections together, and only the deferral rejection bears on priors, so the causal claim holds. "rounds cap" is D-020's "bounded-rounds cap". |
| replay gloss | P21 | P21 | OK. Glossary *replay*: "the ordinary loop with one substitution: the drain reads the trace". |
| arbitrary-K | P4 | P4 | OK. D-020 Rejected: "Bounded-rounds cap: arbitrary K knob". |
| localization budget gloss | P21 | P21 | OK in claim; see problem 1. |
| frame link and gloss | P21 | P21 | See problem 1. |
| FCS | P16 | P16 | OK. |

Problems:

1. Minor (define before use). The log says "re-localization within the
   [frame](#g-frame) (one grid step)" (new L228) is §10.6's first use of
   "frame". It is not. The new localization-budget gloss two lines up uses
   it: "(the count of localizations permitted within one frame)" (L221-222),
   and the checkpoint gloss uses "frame top" at L99. The link and gloss land
   after the reader has met the word twice. Fix: put the link and gloss on
   L222 ("within one [frame](#g-frame) (one grid step)") and leave L228
   plain; L99's compound "frame top" can stay as the checkpoint gloss's
   wording.

Note (no fix asked): `firing_budget` appears at L22, in the rule's third
condition, four lines before its link at L26. P17 chose L26 deliberately,
where the definition follows in the same sentence.

## Unit E

Hunks checked: 4. Log lines found for all 4.

| hunk | log | item | verdict |
|---|---|---|---|
| opening | P36 | P36 | See problem 2. The second claim and the parts sentence are fine. |
| debt unlink | ruled_edits K12 | K12 Status | OK. The gloss stays. |
| knee definition | P37 | P37 | OK. D-021's Position re-anchors at pace change, un-pause and excess debt; a pace change alters the slope `1/p`, a re-anchor the offset. Declared as an addition. |
| un-pause wrap | P48 | P48 | OK, wrap only. |

Problems:

2. Minor (new sentence states more than its source). New: "An
   interactive run must keep to wall-clock time, and its trajectory must not
   depend on how fast it runs." Old has no such opening, and nothing in
   §10.7 or D-021 says an interactive run must be paced. D-021 makes
   `p = ∞` an explicit pacer-off that any run may use, and old 100 calls it
   "a pace change like any other". The second clause is the invariant
   (D-021, "bit-identical paced/unpaced trajectories") and holds. P36 wrote
   the wording and said both claims are the section's own; the first is not
   stated anywhere as a requirement. Fix: "A real-time run must keep to
   wall-clock time, and its trajectory must not depend on how fast it
   runs."

## Bold across chapter_new.md

`chapter_new.md` equals the seven units' new.md concatenated (blank lines
aside). 60 bold spans outside fenced code; every one has a D-citation in its
sentence.

- The rulings' bold changes landed as ruled: P29 (C2 composition plain; C1's
  D-185 bold kept), P30 (D's prior plain; B1's D-082 trigger bold kept), P31
  (B2 "recorded" plain), P32 (B2 bold moved to the default), P33 (A, bold
  trimmed to the headline clause). P42 moved a bold sentence without
  touching it.
- No ruling is bold twice as a result of the diff. Same-entry repeats that
  remain (D-017 ×4, D-147 ×5, D-185, D-082, D-081) are the ones chapter_pass
  section 5 checked against separate Position or Rationale rulings.

Problems:

3. Low (ruled, but against spec_style). P32's bold "**`localization_budget`,
   the integer count of localizations permitted within one frame, defaults
   to 8**" carries a definition inside the bold. spec_style "Marking
   rulings": "Bold marks nothing else: not ... terms, definitions", and the
   headline clause is the shortest clause that states what is decided.
   chapter_rulings P32 ordered this wording, so the edit is authorized.
   Fix: "`localization_budget` is the integer count of localizations
   permitted within one frame. **It defaults to 8** ([D-133][d-133],
   [D-181][d-181])."

## Checker

`python3 checks/check_unit.py ch10 check <U>` from docs/spec_rewrite, last
line for each unit:

| unit | bold spans | result |
|---|---|---|
| A | 8 | checks failed: 0 |
| B1 | 10 | checks failed: 0 |
| B2 | 8 | checks failed: 0 |
| C1 | 9 | checks failed: 0 |
| C2 | 8 | checks failed: 0 |
| D | 9 | checks failed: 0 |
| E | 8 | checks failed: 0 |

## Totals

62 hunks checked (A 12, B1 15, B2 6, C1 4, C2 6, D 15, E 4). Every hunk
has a log line and an item or ruling behind it. No claim's strength, scope,
quantifier, causal direction or citation changed outside what a ruling
ordered. Three minor problems: D's frame link placed after two uses
(problem 1), E's opening "must" with no source (problem 2), and P32's bold
holding a definition (problem 3).

## Fixes applied by the orchestrator

- E, opening: "An interactive run must keep to wall-clock time" became "A
  real-time run must keep to wall-clock time".
- D: the frame link and gloss moved to the first use, "within one
  [frame](#g-frame), one grid step", in the localization-budget gloss; the
  later "within the frame" is plain.
- B2: "`localization_budget` is the integer count of localizations permitted
  within one frame. **Its default is 8** (D-133, D-181)." The bold now marks
  the ruling, not the definition.

All seven units print `checks failed: 0`.
