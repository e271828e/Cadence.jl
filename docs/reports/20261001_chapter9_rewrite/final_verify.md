# Final cold verification of the post-unit edits — 2026-10-01

Scope: every edit logged in `chapter_fixes.md`, `trim_log.md`,
`ruled_edits.md`, `rulings_applied_A.md`, `rulings_applied_B.md`,
`units/S94/changes.md`, plus the orchestrator's GNSS edit. Each was checked
against `chapter_new.md`, `chapter_old.md`, `docs/design/spec.md` (by section)
and `docs/design/decisions.md`. Line numbers are `chapter_new.md` lines.
`chapter_new.md` equals a fresh concatenation of `units/*/new.md`. The frozen
§9.7 block (1134–1167) equals spec 4247–4280 with `**` removed.

## Checks

`python3 checks/check9.py check <U>`:

| unit | checks failed | bold spans |
|---|---|---|
| A1 | 0 | 10 |
| A2 | 0 | 17 |
| B | 0 | 9 |
| C | 0 | 13 |
| D | 0 | 0 |
| E | 0 | 13 |

With S94's 10, the chapter has 72 bold spans. Every one has a D-citation in its
own sentence.

## Counts

| log | edits checked | findings |
|---|---|---|
| chapter_fixes.md | 29 | 0 |
| trim_log.md | 79 | 0 (2 later undone, see F4, F5) |
| ruled_edits.md | 12 | 1 (F3) |
| rulings_applied_A.md | 20 | 3 (F1, F6, F7) |
| rulings_applied_B.md | 19 | 3 (F2, F4, F5) |
| units/S94/changes.md | 4 | 0 |
| orchestrator GNSS edit | 1 | 0 |
| **total** | **164** | **7**, plus G1 (two accepted rulings never applied) |

Only F2 changes a claim (scope). The other findings are about duplication, bold
or links.

## Findings

**F1. R16 duplicates the F6 sentence** (252–257). "The `Build` is immutable
apart from its lazily filled activation dictionary" is followed by "The one
mutable thing on the artifact is the lazily populated activation dictionary,
whose insertion is torn-state-free". The next sentence then names
"torn-state-free insertion" again. That is the same fact twice and the
torn-state-free point twice, in three sentences. No claim is wrong.
Fix: replace the F6 sentence with "Its insertion is torn-state-free." The
rulings_applied_A note proposes the same thing.

**F2. R60's `RQuat` gloss narrows the scope of the `@kwdef` clause** (546–548).
In the old text, "`RQuat()` is the identity, and the `@kwdef` convention
supplies it broadly" was an aside to the general `T()` fallback. The new
opener "For the rotation-quaternion type," now governs both conjuncts, so the
general `@kwdef` claim reads as a claim about `RQuat` alone. *This changes
meaning (scope).*
Fix: "For the rotation-quaternion type, `RQuat()` is the identity. The `@kwdef`
convention supplies such a default broadly."

**F3. D-261 b2 is bold twice** (167 and 270). By the R1 test in
`ruled_edits.md`, all sentences of one bullet count as one ruling. A1:167 ("The
feedthrough graph … is not carried") rests on the 2026-09-22 extension inside
D-261's second bullet. A2:270 ("An artifact holds declared facts") rests on the
same bullet. Calling the extension a separate ruling departs from the log's
own test.
Fix: make one of them plain. The first-bold rule gives "An artifact holds
declared facts" (270). Otherwise, record the extension as a separate ruling
in R1's table.

**F4. R23 brings back bold that the trim removed** (499–500). The bold
again covers "at the initial state, with real values", the part the trim
moved out. D-050's Position does not say "with real values". The bold follows
R23's proposed text to the letter, but that text conflicts with the trim
ruling.
Fix: "**The nominal evaluation probes every user function once**, at the
initial state, with real values ([D-050][d-050])."

**F5. R55's bold runs past the headline** (1090–1092). The bold includes "not
an index trick", which trim item E4 left outside. R55 says its bold "follows
the ruled trim", but it does not.
Fix: "**At a localized event time `t*` ([§10.4][s10-4]), the empty due set is
arity selection**, not an index trick ([D-147][d-147], [D-185][d-185])."

**F6. R13 goes beyond the drafted ruling** (3–8). R13's proposal changed only
"absolute rate divisors". The batch left the layout open ("Decide whether it
changes too"), and the applier changed it to "the nominal activation's flat
state layout". The new wording is accurate: D-259 b1 makes the nominal
activation a build product, and D-135 says entries hold layouts. But "the
typed signal table" in the same list is also per activation and stays
unqualified, so the list now implies a difference that does not exist. The
reflow also leaves an orphan line, "and the".
Fix: have the owner confirm the qualifier, and either drop it or apply it to
both ("the nominal activation's typed signal table and flat state layout").
Reflow lines 6–8.

**F7. R60 "tier classifier" comes before the `g-tier` link in §9.1** (83 vs
112). Under R4, a term is linked at its first use in a section. The R60 edit
makes line 83 the first "tier" in §9.1.
Fix: move the `[tier](#g-tier)` link from line 112 to "tier classifier" on
line 83.

**G1. R33 and R35 were accepted but never applied.** No log records them.
- R33: line 652 should read "re-derived by the leaf walk ([§8.2][s8-2])".
- R35: 740, 743 and 745 are still separate one-sentence paragraphs. R1 has
  already made 740 plain.

Fix: apply both to `units/S94/new.md` and log them in `changes.md`.

## chapter_fixes.md

All PASS. Notes on the edits that came closest to changing a claim:

- 1.1, 1.2 ("It is typed."; "the content of the `Schedule`"), 1.4, 5.8: wording
  only. The antecedents still hold.
- 1.7/5.4/6.3: the gloss returns to "non-nominal activation", where old §9.5 had
  it (old 664–665).
- 1.10: "verifies empirically that the check folds away" is old's "verifies the
  fold empirically".
- 1.13: the parenthetical names the same check the chapter opening calls the
  unconnected-input obligation check.
- 1.14 and 1.15: links only. R4 later lifted the keep-every-link rule.
- 4.2: the lead sentence asserts nothing new.
- 5.1/6.1 (R37), 5.2/4.4 (R38), 5.10 (R39): the owner confirmed these moves.
  After them, "Two checks ride the same pass" and "Root inputs fall out here
  too" still resolve.
- 5.3: "walking and pinned" names the two kinds that old bolded (old 667, 680).
  "An opaque leaf has a rule of its own" is a transition.
- 5.5, 5.7/6.4, 5.11, 5.12, 5.13, 6.8: wording or order only. "Only a sketch,
  kept here" restates old's "sketched here".
- 5.9: the three habit bullets keep each claim and its D-142 citation.
- 6.5/2.5: the causal order "binds no clock … so `t` is a fabricated value"
  matches old. The placeholder is still "therefore" from `Δt`'s absence.

## trim_log.md

All 79 items PASS. Each "after" span is either in the current text or was
later changed by a logged ruling (R1, R3, R23, R55, R60, R15). Each kept span
is a headline clause, and its D-citation is in the same sentence. The
"kept longer" cases are justified. Note: `new_pretrim.md` already contains the
trimmed bold, so the trim cannot be diffed from files. It was checked
against the log's before and after spans.

## ruled_edits.md

- R1, A1:202, S94:663, S94:740 (D-253 b4 and b5; D-259 b1): PASS. The first
  bolds are at 157 and 231.
- R1, A2:380 (D-254 b1, first bold at 304): PASS.
- R1, C:942, C:955 and C:980: PASS. C:942 maps to D-053's handler clause and
  D-090's Rationale sentence, and both are already bold at 915 and 936. C:955
  maps to D-053's guards clause (915). C:980 maps to D-053's "failure = …
  replay" clause (967).
- The "Kept" table is correct for D-259 (33 for b1; 157 kept as the first bold
  of D-253 b4), D-254, D-186 (three semicolon-separated Rationale parts),
  D-187, D-250, D-115, D-051, D-142, D-052, D-053, D-263, D-147, D-194, D-086
  and D-116. **D-261 fails: see F3.**
- R3, A1:97: PASS. R3, A2:431: PASS, as R3 proposed. R3, B:585: PASS, as
  proposed. Dropping "Enforcement" leaves the preceding obligation sentence
  as the link.
- R36 (252–257): PASS. Two sentences were dropped and the §9.4 pointer was
  kept. The S94 mappings (745–754, 737–738) hold.
- D-261 reorder (270): PASS. The text is unchanged. The rule now comes before
  its application at 385.

## rulings_applied_A.md

| ruling | where | result |
|---|---|---|
| R13 | 6–7 | "anchor-relative rate triples": PASS (D-186 Rationale, D-253 b1). Layout qualifier: **F6** |
| R10 | 40 | PASS (D-050 Position; §9.3) |
| R14 | 69–70 | PASS (D-246 Position, "run on every component before its class is read") |
| R60 classifier | 83 | PASS (D-247 Position uses "the tier classifier"). Link: **F7** |
| R15 | 97–100 | PASS (D-236 bullet 1) |
| R44 | 137–139 | PASS. A2 298–300 holds the reason |
| R60 probing scalar | 177 | PASS (D-259 Rationale; build probes at `Float64`) |
| R11 | 190 | PASS (D-259 b2) |
| R12 | 209–210 | PASS (D-259 b1 and b2; Rationale "a second pass") |
| R17 | 228 | PASS (D-253 Rationale, "bindings validate against it") |
| R18 | 232–233 | PASS (D-259 b1) |
| R45 | 236 | PASS. The inputs stay at 306–307 |
| R16 | 252–254 | The text matches D-135 (Position on the cache; Rationale "immutable artifact … concurrently"). Duplication: **F1** |
| R19 | 320 | PASS |
| R20 | 374 | PASS (D-229 last bullet; plain, as the paragraph's bold already cites D-229) |
| R21 | 380–384 | PASS, no change (D-254 b2, D-261 "component rows and rate-scope rows") |
| R50 + GNSS edit | 391–393 | PASS. Spec 5054–5062: both entries sit on `Vehicle`, the root scope. `fcs` is a scope. `gnss` is one of the "three discrete components". "Flight-control" reads the name `FCS`, as the accepted proposal did. "Deploy it" still resolves to the model |
| R22 | 420, 423–425 | PASS (D-257 b1, the 2026-09-21 and 2026-09-22 amendments) |
| R59 | 429–430 | PASS (spec 4193, in §9.7) |
| R54 (S94) | 692–693, 759–760 | PASS (old spec 3948–3949 and 3986–3988; "One such loop" keeps the "such as" relation) |

## rulings_applied_B.md

| ruling | where | result |
|---|---|---|
| R23 | 499–500 | The wording is PASS (D-050). The bold is **F4** |
| R25 | 514–515 | PASS (spec 683–691, 734) |
| R60 probing scalar | 525–527 | PASS |
| R60 `RQuat` | 546–548 | **F2** |
| R60 branch-shape | 566 | PASS (spec 2651, inside §8.3 at 2612) |
| R24 | 577–579 | PASS (D-254 b1; A2 306–308) |
| R49 | 607 | PASS (D-142 Rationale, "shipped `landinggear.jl`"; no package named) |
| R52 strut | 610–611 | PASS (D-142 Rationale (i)) |
| R52 surface, friction | 619–623 | PASS (D-142 Rationale (iii)). "(static ≥ dynamic)" gives one of the two asserted orderings as an example |
| R52 contact algebra | 613–614 | PASS, no edit |
| R26 | 841 | PASS (D-235 Rationale) |
| R53 | 822–823 | PASS (spec 2129–2136, `Engine`: `M_shaft` torque, `P = M_shaft * x.ω`) |
| R51 | 996–999 | PASS (spec 9749, 9800–9802) |
| R47 | 1009–1011 | PASS (spec 1583–1585, §7.1) |
| R56 | 1071–1073 | PASS. `rhs` = `x_deriv` block is stated at 1182. `ticks` = `s_update` block holds by elimination from §9.7's own block list and D-116's roster. Spec 4335 ("a tick entry advances discrete state with no clock advance") also supports it. No source states it outright, as the log says |
| R55 | 1090–1092 | `t*` gloss: PASS (spec 4500, §10.4). The bold is **F5** |
| R57/R58 | 1118–1122 | PASS (spec 1542–1545). The §7.1 citation scope is kept: each sentence of the old one now carries it |
| R28 | 1198 | PASS (Appendix B, spec 11083–11084, "inspection-only surface") |
| R48 | after 1214 | PASS. E-100 maps to `migration_outline.md` 37–40 and E-099 to `migration_addition.md`, which has not yet been appended to the outline. The paragraph that remains reads cleanly |

## units/S94/changes.md

R30 (648), R31 (652–653), R32 (657–658) and R4 (645 plain, 696 linked) all
PASS. R33 and R35 are missing: see **G1**.

## Fixes applied

Applied 2026-10-01 to the unit files. `chapter_new.md` was then rebuilt with
`checks/assemble.sh`. Line numbers below are the rebuilt `chapter_new.md`.
`python3 checks/check9.py check <U>` prints `checks failed: 0` for A1, A2, B,
C, D and E. A1 has 10 bold spans, A2 16, B 9 and E 13. With S94's 10, the
chapter now has 71. Scripts: `units/<U>/fixes_final_<U>.py` and, for A1's
reflows, `units/A1/reflow.py`.

- **F1** (A2, 251–254). Before: "… concurrently ([D-135]). The one mutable
  thing on the artifact is the lazily populated activation dictionary, whose
  insertion is torn-state-free. [§9.4] states the ownership rule, the keying
  and the torn-state-free insertion." → After: "… concurrently ([D-135]). Its
  insertion is torn-state-free. [§9.4] states the ownership rule, the keying
  and the torn-state-free insertion." Inventory: A2-070's old span now maps
  to R16's "immutable apart from its lazily filled activation dictionary".
  A2-056's new span is "Its insertion is torn-state-free."
- **F2** (B, 543–545). Before: "For the rotation-quaternion type, `RQuat()`
  is the identity, and the `@kwdef` convention supplies it broadly." → After:
  "For the rotation-quaternion type, `RQuat()` is the identity. The `@kwdef`
  convention supplies such a default broadly." Inventory: B-032.
- **F3** (A2, 267). Before: "**An [artifact] holds declared facts**, and a
  consumer compiles … ([D-261])." → After: plain, with its D-261 citation
  kept. The bold at A1, 166 ("The feedthrough graph … is not carried") stays
  as D-261 b2's first bold in reading order.
- **F4** (B, 496–497). Before: "**The nominal evaluation probes every user
  function once, at the initial state, with real values** ([D-050])." →
  After: "**The nominal evaluation probes every user function once**, at the
  initial state, with real values ([D-050])."
- **F5** (E, 1087–1089). Before: "**At a localized event time `t*` ([§10.4]),
  the empty due set is arity selection, not an index trick** ([D-147],
  [D-185])." → After: "**At a localized event time `t*` ([§10.4]), the empty
  due set is arity selection**, not an index trick ([D-147], [D-185])."
- **F6** (A1, 3–17). Before: "the resolved wires, the typed [signal table],
  …". → After: "the resolved wires, the nominal activation's typed [signal
  table], …". The source supports it. v4 §9.4 has activation at `T` re-type
  every cell and lay out "the table and state buffers" again, so the typed
  table is per activation like the layout. The paragraph is reflowed, and the
  orphan "and the" line is gone. Inventory: A1-003.
- **F7** (A1, 82 and 111). Before: "the tier classifier" (82) and "a leaf
  mixing [tier](#g-tier) families" (111). → After: "the [tier](#g-tier)
  classifier" and "a leaf mixing tier families". The paragraph at 81–87 is
  reflowed. Note: the steps table at line 41 ("the continuous tier's
  functions at `T`") uses "tier" earlier in §9.1. Under R4 read strictly, the
  link belongs there. It was placed at 82, as instructed.

## Re-check of the fixes

All seven spots were re-read against `chapter_old.md`. `check9.py check`
prints 0 failures for every unit, and `chapter_new.md` matches the unit files.

- F2, F3, F4, F5 and F7 (the link is now at line 40, the first "tier" in
  §9.1): PASS.
- F6: PASS. The list now says "the nominal activation's" twice, which is
  repetitive but accurate.
- **F1 is newly broken (252).** In "Its insertion is torn-state-free", the
  nearest subject is the `Build`, so "Its" reads as the `Build`'s insertion,
  not the dictionary's. Fix: "Insertion into that dictionary is
  torn-state-free."
