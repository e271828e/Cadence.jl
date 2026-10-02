# Chapter 7: rulings batch (step 6)

Merged from `units/{A,B,C,D}/rulings.md`, `units/*/verify.md` (leftovers),
`chapter_pass.md` (K2, K7), `chapter_rulings.md`, `inbound_check.md` and
`survey.md` parts D and E. Spec lines are `spec.md` at `8032ff2` (the working
tree still matches; `git diff 8032ff2 HEAD -- docs/design src test` is empty).
Log lines are `decisions.md` lines in the same tree. Every log line quoted
below was read at its line. `units/*/new.md` were not read; chapter lines
are `chapter_new.md` as assembled at 21:18.

Counts: blocking 2 open (B1, B2), 13 sources closed as ruled; landing 7;
track 2: 18 Positions owed, 7 annotations, 3 Spec-field items, 7 inbound
groups, 12 owner items. Serious candidates: none (see the end).

## 1. Blocking: needs a ruling before landing

### Already ruled, not re-raised

| item | source | status |
|---|---|---|
| F4's wording has no sentence left in §7.1 (keep the enumeration?) | `units/A/rulings.md` 13–19, 82–83 | ruled, R6 (M2 pointer). The carry to §5.2 and the glossary is track 2, T-D6 |
| `f_ode!` gloss in §7.4 | `units/D/rulings.md` 136–138 | ruled, E6 |
| §7.4's "every step addresses" | `units/D/rulings.md` 132–135; `units/D/verify.md` 9 | ruled, R14 |
| "roughly half the type inventory" dropped from §7.2 | `units/B/rulings.md` 105–107 | within R2's condition (kept in the companion); `units/B/verify.md` 37 agrees |
| "Their" antecedent, line wraps | `units/B/verify.md` 66–72 | fixed before the pass (chapter_new 150 reads "The walked types' parametrization"); wraps ruled, E18 |
| `#g-walked` links | `units/B/verify.md` 15 | ruled, R11 |
| Two senses of "snapshot" | `units/C/verify.md` 45; `chapter_pass.md` 243–251 | ruled, K2 (E9 and E17 only, no glossary note) |
| "the integrator buffer" | `chapter_pass.md` 270–276 | ruled, K5. Its "ask the owner whether the intermediates were meant" is not carried: the new text claims less, and nothing the framework does changes |
| D-231 "any leaf's `m`" | `chapter_pass.md` 287–290 | ruled, K7 (track 2 annotation, T-B4) |
| `extensions.md` 334 | `inbound_check.md` 53–67 | ruled, `chapter_rulings.md` 53–57 (L1) |
| `FrameTransform`, MTK/CSE, "need no migration" | `units/B/verify.md` 41; `units/D/verify.md` 44 | ruled, R12, R16, R13 |
| F11, F12, F14, F15 left as written | brief "Left as written"; `units/B/rulings.md` 13–15; `units/D/rulings.md` 18–22 | ruled (brief); owner side in T-E |
| D-044 drift, PRNG causes, activation gloss, "contract declarations" | `units/D/verify.md` 6; `units/C/verify.md` 7, 43–44 | fixed and re-checked (`verify.md` re-check sections) |

### Open

**B1. Reader-cold names the verifiers left optional.**
Sources: `units/A/verify.md` 29 ("attitude state", "trim solvers",
`reconstruct`/`flatten` not introduced); `units/B/verify.md` 42
(`frozen_discrete_walkthrough.md` named bare, chapter_new 162);
`units/D/verify.md` 42 ("pose" might take "(position and attitude)").
All were in the old text.
Proposal: no edit. The spec names that walkthrough bare at 2555 and 11232;
"pose" is §4.3's word (533–574, `pose = KinPose{T}`); chapter_new 30–31
defines the attitude state in its own sentence (`SVector{4,T}`); "trim" is
used throughout the spec (§14).
Recommendation: no edit, close.

**B2. Survey F1's two unruled notes on the `Noise` example.**
Sources: `units/C/rulings.md` 15–18; `survey.md` 824–830. (1) `Xoshiro` has a
fifth field `s4` the example leaves untouched. (2) D-231 Rationale (log
8588–8589) says the spec "stays silent on the generator's internals", while
the example names `s0` to `s3`.
Evidence checked: on this machine's Julia, `fieldnames(Xoshiro) == (:s0,
:s1, :s2, :s3, :s4)`, and two copies differing only in `s4` give identical
`rand(UInt64, 3)` and `randn(3)` draws. So `s0`–`s3` are the values that
determine the next draw, as the example's bold says. On (2), the survey
records both came in one commit (`d80f6dd`); D-231 rules nothing on the
internals, and the example illustrates.
Proposal: no chapter edit; no log edit.
Recommendation: close.

## 2. Landing edits (recipe step 7)

**L1. `extensions.md` 334, inbound citation (step 7.1).** Ruled,
`chapter_rulings.md` 53–57. Replace "[§7.2][s7-2]'s mechanical
parametrization of the walked payload list" with "[§7.2][s7-2]'s mechanical
parametrization of the walked class, whose FlightPhysics payload list
`companions/migration_outline.md` gives under 'The parametrization pass'".
The line wraps across 333–335; rewrap the paragraph. No other inbound row
needs a landing edit (`inbound_check.md` 11–19: 0 LOSS, 0 RETARGET).

**L2. The companion addition's destination (step 7.4).** Source
`units/B/companion_addition.md` (R2, R12, R13), with K1's "class" for
"tier" at both "the walked tier of §7.2" and "the pinned tier of §7.2"
(`chapter_rulings.md` 26–30) and E18's rewrap (`chapter_pass.md` 223).
Destination: `docs/design/companions/migration_outline.md`, a new paragraph
right after "**The parametrization pass.**" (lines 30–35, ending "into a plain
scalar."), before "**Comparison criteria.**" (37).
Sub-item, table row 16 ("The walked-leaf parametrization pass", names only
`Ranged`; `units/B/rulings.md` 97–101). Proposal: leave the row; the new
paragraph sits under the row's own section. Recommendation: leave.

**L3. Reference definitions `linkify.jl` must generate (step 7.6).**
- `spec.md`: `[d-010]`, `[d-014]`, `[d-072]`. None exists today; D-010,
  D-014 and D-072 are cited nowhere in the spec (`units/A/rulings.md` 34,
  `units/B/rulings.md` 34–36, `units/D/rulings.md` 79–80).
- `companions/migration_outline.md`: `[s7-2]` (the companion addition's three
  `[§7.2][s7-2]`). The file is in linkify's `ROSTER` (`linkify.jl` 73), so the
  run adds it. Its definitions block (from line 117) has no `s7-2` today.
- `extensions.md` 334 gains no citation.
Recommendation: run linkify, then grep the three definition blocks for the
four labels.

**L4. Spec fields the new citations change (step 7.3).** The rewrite adds
these entry-section pairs and drops none (`chapter_old.md` against
`chapter_new.md`, by section). Current fields read at the log:

| entry | current **Spec.** (log line of heading) | add |
|---|---|---|
| D-010 | none (477) | new field `[§7.1][s7-1]`, after Position |
| D-014 | none (547) | new field `[§7.5][s7-5]`, after Position |
| D-032 | §8.1, §8.3, §8.4 (983) | §7.2 |
| D-033 | §4.2, §8.1, §8.2 (1016) | §7.1 |
| D-034 | §5.4, §8.3 (1063) | §7.4 |
| D-035 | §5.2, §5.3, §7.4 (1093) | §7.1 |
| D-072 | §7.1, §14.10 (2095) | §7.2 |
| D-074 | §5.2, §11.4 (2167) | §7.3 |
| D-079 | §7.1, §8.2, §8.5, §9.4, §9.5, §14.10 (2330) | §7.2 |
| D-235 | §7.1, §9.5, Appendix C (8697) | §7.2 |
| D-252 | §5.2, §5.3, §7.5, … (9530) | §7.1 |
| D-266 | §6.1, §8.2, §13.7, §14.10 (10532) | §7.2 |
| D-280 | §8.2, §9.4, Appendix B (11668) | §7.2 |
| D-288 | §9.7, §10.5 (11967) | §7.1, §7.5 |
| D-295 | §6.1, §8.2, §14.10 (12303) | §7.2 |

No change: D-111, D-247 (§7.1 listed); D-263 (§7.2); D-302 (§7.3); D-116,
D-135, D-137 (§7.5). `inbound_check.md` 170–180 lists only D-035, D-235 and
D-288; this table is the full set. `decisions_style.md` 56 says "Omit the
field entirely if there are none", so D-010 and D-014 gain a field now that
§7.1 and §7.5 cite them. That closes survey part E's missing-field item
(`survey.md` 789–790) at landing.
Recommendation: apply all, keeping each field's existing order (recipe 7.3).

**L5. `check_rows.jl` coverage.** The spec newly cites D-010, D-014 and
D-072; no entry loses its last citation (no entry-section pair is dropped).
Coverage only grows, so the run passes and reports the three as new. No
`--rebaseline` is needed. `row_baseline.txt` ends at 294 and already omits
cited D-295 and D-302. Recommendation: do not rebaseline (the recipe
rebaselines only on a shrink).

**L6. `check_bold.jl`**: add 7 to `REWRITTEN` (line 21, now `[8, 9, 10]`).

**L7. Contents**: no `##`/`###` heading changed; only the `####` label
"Double-buffered mutable state (deferred)" became "Idioms". The one outside
mention is a dated report (`docs/reports/20260904_conformance/a_foundations.md`
269). No Contents edit.

## 3. Track 2 (after landing, recipe step 8)

### T-A. Positions owed for Rationale-only rulings (lesson 17: restate only)

Bold-cited first; these carry a chapter bold on a non-Position field.

1. D-094: the flat declaration. Annotation 2026-09-14, log 2780–2784. Bold
   in §7.1. Sources: `units/A/rulings.md` 47, 52; `survey.md` 725.
2. D-135: the invariant's scope (stepping loop; services allocation-tolerant).
   Rationale log 4228–4230. R5's sentence. `units/D/rulings.md` 96–97;
   survey part G q5.
3. D-014: "not dogma" and the canary. Rejected log 556–557. Also D-116
   Rejected log 3505–3507 for the canary. `units/D/rulings.md` 84–86;
   `survey.md` 752–753.
4. D-288 and D-086: the buffer unchanged within a sweep as CSE's legality
   condition. D-288 Rationale log 11994–11995; D-086 Rationale log 2559–2560.
   `units/A/rulings.md` 48; `survey.md` 732.
5. D-094 Rationale log 2771–2778: why the vocabulary is closed, the explicit
   cast, where invariants live. `units/A/rulings.md` 49.
6. D-190 Rationale log 6837–6840: derivative completeness is structural.
7. D-011 Rejected log 502–503: the four consumers.
8. D-263 Rationale log 10309–10312: participation authored per leaf.
9. D-235 Rejected log 8751: type stability under `Dual` "an authoring rule
   (§7.2)" (partial; see T-E1).
10. D-079 Rejected log 2364–2365: nothing from probe inference.
    `units/B/rulings.md` 73–74.
11. D-231 Rationale 8589–8596 and D-302 Rationale 12560–12562: the `Symbol`
    grounds, nesting rejected, no arithmetic on `s` and `m`.
12. D-077 Rationale 2271–2274, D-183 Rationale 6567–6568, D-220 Rationale
    8111–8113 with annotation 8133: workspace sizes and eltypes, `undef` as
    the marker, both tiers, `init` as *establish*.
13. D-183 Rejected 6574–6576: plans and factorizations valid from allocation.
14. D-077 Rejected 2288–2291: the workspace is never a condition target.
15. D-231 Rationale 8584–8588 and Rejected 8605–8606: rematerializing the
    generator allocates.
16. D-013 Rejected 545: double-buffering deferred.
17. D-116 Rationale 3491–3493: the budgets' membership (guards and
    projection exactly zero, handlers zero by idiom).
18. D-137 Rationale 4339–4341, 4379–4381: `sizehint!` to the bound; field
    handles as references. D-015 Rejected 573–574, 578–579: prior-art caches
    and the split's measured cost.

Source for 5–18 unless noted: `survey.md` 723–761; `units/C/rulings.md`
56–68; `units/D/rulings.md` 82–97. Recommendation: one Position per entry
for items 1–4 (bold or R5-carried). For 5–18, restate only where the spec
states a ruling; a constructive reason needs no Position (spec_style
"Rationale"). Then cite the new entries beside their sources in the chapter.

### T-B. Stale entry text needing an annotation

1. D-013 Position, log 537: "Immutable `z` in cells". `z` is `s` since
   D-195; stores are not cells since D-121/D-302. D-121 Rejected (log
   3658–3659) says historical D-013 is annotated, never rewritten. No
   annotation exists. `survey.md` 712–716.
2. D-035 Position, log 1101: "selective auto-publication of declared
   state/mode fields", retired by D-252, whose Position does not name this
   clause. No annotation. `survey.md` 707–711.
3. D-077 Rationale, log 2274–2276: "scoped debug poison". D-183 Rationale
   (log 6569–6570) "supersedes D-077's poison clause". D-077's one annotation
   (2278–2281) is about D-263 only. `survey.md` 717–721.
4. D-231 Position, log 8563–8564: "a discrete leaf's `s`, and any leaf's
   `m`". K7: glossary (spec 12432, "the continuous-only mode store"), §8.2
   2686 (bold, D-112, D-249: `m_init` continuous-only), `src/build.jl` 188
   (`m_init` votes CONTINUOUS) and D-249 Position (log 9363–9365,
   `DeclarationOnWrongTier` keeps `init_m`) agree. Annotation: `m` is
   continuous-only; "any leaf's `m`" means every leaf that declares one.
   Also D-231's `init_s`/`init_m` and "Stratum A" are old names.
5. D-121 Rationale, log 3644: "author-facing, poison-covered scratch".
   History since D-183. `survey.md` 801–802.
6. D-116 Rationale, log 3491–3493: "[§7.5]'s tiers" and "the §7.5
   carve-out". §7.5 now says "budgets" (E13) and never "carve-out"; also
   `project` (old name). Annotate or leave as history (`inbound_check.md`
   90–97).
7. D-203 Rejected, log 7349: "the clock is seeded `zero(T)` ([§7.2])". §7.2
   never said it (T-D1).

### T-C. Spec fields

1. D-010, D-014 (no field): closed at landing by L4 if L4 is accepted.
   Otherwise here.
2. D-295 Position cites §7.1 (log 12324), Spec (12326) lacks it; D-194
   Position cites §7.3 (log 6973), Spec lacks it (`survey.md` 794–796).
   Proposal: leave both. The pointer names a premise; §7.1 does not state
   D-295's ruling and must not cite it (lesson 16), and §7.3's `ws` channel is
   D-013/D-077's ruling. L4 adds D-295's real home, §7.2.
3. D-066 Spec lists §7.5 for "allocation fine per §7.5" (`survey.md` 799–800):
   now true after R5. Close.

### T-D. Pre-existing wrong inbound rows

1. MISSING, four (`inbound_check.md` 78–83), each verified at its line:
   - spec 4765–4766 (§9.7, rewritten chapter): drop "([§7.1][s7-1])".
   - spec 12067 (Appendix C, `IllegalPortType`): §7.1 → §4.3 (547–549).
   - spec 12549 (glossary *scratch*): drop §7.5; §10.3 and §10.4 carry it.
   - log 7349 (D-203 Rejected): drop "(§7.2)"; no spec sentence on the seed
     was found. As annotation (T-B7), since the log is not rewritten.
2. VAGUE, carve-out (7 rows: spec 4917, 7061; log 3194, 3491, 3493, 6297,
   12008): referent now clear. Recommendation: leave log rows; reword spec
   4917 and 7061 "carve-out" to "scope" only with chapter 9 and 11 owners'
   agreement. `inbound_check.md` 90–97.
3. VAGUE, "model sweep" (spec 7819; log 4298): pick "stepping loop".
   `inbound_check.md` 99–102.
4. VAGUE, rules §7.1 implies (spec 2599, 2195; log 12324, 5860, 5812, 5836,
   5575): cite §7.2 beside §7.1 at spec 2195; the rest hold.
   `inbound_check.md` 104–114.
5. VAGUE, phrases: fix `extensions.md` 283's quote to "no
   `::SomeType{Float64}` return-type annotations"; spec 11539, 2258 hold;
   `sizehint!` rows and chapter 3's spec 304, 331 go to chapter 3's rewrite.
   `inbound_check.md` 116–131.
6. F4 carry: spec 822 (§5.2, chapter 5's rewrite) and glossary 12531
   (*one home per datum*), "the stores hold `s` and `m`" → "the `s` and `m`
   stores hold `s` and `m`" (D-302 Position, log 12545–12548).
   `units/A/rulings.md` 13–19.
7. `src/` and `test/` comments (`inbound_check.md` 189–196; checked at each
   line): `src/build.jl` 1397 §7.3 → §5.2; `src/build.jl` 1349 §7.5 → §10.3
   (as glossary 12549); `src/diagnostics.jl` 1043 (an error message),
   `src/executor.jl` 383, `src/build.jl` 1619, `test/test_store.jl` 176,
   `test/test_failures.jl` 722: §7.3 → §9.5 (4565, "`s_update` checks
   against its leaf's `s` shape"). No test matches the message's "(§7.3)".

### T-E. Owner items: spec sentences with no entry behind them

Each stays uncited; ratifying it is a design decision (recipe step 8).

1. **§7.2's three author rules** (old 1645–1651). No `::Float64` argument
   annotations; no `Float64`-pinned intermediates; no `::SomeType{Float64}`
   return annotations on the continuous path. Reads as a ruling (July text,
   once under **Rule.**). Partial record: D-235 Rejected 8751 calls type
   stability under `Dual` "an authoring rule (§7.2)". The Flight.jl
   status-quo remarks attached to them left with M4.
2. **§7.2's lookup rule** (old 1636–1643): table data pinned, query
   coordinate walked; `Linear()` kinks, upgrade to `Cubic`, `gradient` as
   escape hatch. The rule reads as a ruling; the caveats as guidance. D-070's
   bullet is the C172 audit's narrower preference (`units/B/rulings.md`
   60–62). "Compositions in Flight.jl's tables" is a status-quo description.
3. **`ValueSnapshot{N,T}`** (F13, old 1784–1787): "optionally enforceable".
   Neither: a design option offered, with nothing in `src/`, the log or the
   spec behind it. Owner: ratify, move to `pending.md`, or drop.
4. **The snapshot discipline and ceiling** (old 1782–1789): storage, logging
   and element access only; a few KB to tens of KB. Reads as a ruling
   (guidance). The `SArray` codegen claim beside it (1778–1780) describes
   StaticArrays, not a ruling.
5. **§7.5's three reasons** (old 1839–1845): jitter, throughput, the canary.
   Reads as a ruling's constructive rationale. Only the canary is recorded
   (D-014 Rejected 557). `pending.md` 93–104 grounds jitter in the
   hardware-in-the-loop requirement. Owner: enrich D-014's Rationale or leave.
6. **Event firings are not recorded; an event-firing stream is a guarded
   addition** (old 1871–1877). Reads as a ruling. D-243 Rationale (log
   9086–9087) and Rejected (9097) presuppose "the absent event stream" and
   "§7.5's remedy" but rule neither. No `pending.md` item.
7. **The garbage levers** (old 1878–1881): Bumper.jl-style arenas and a
   scheduled `GC.gc(false)`. Reads as guidance offered as available; nothing
   in `src/` builds either.
8. **`GC.gc(false)`** (F14): already in `pending.md` 109–113 under
   "Publication's garbage". No new item.
9. **OrdinaryDiffEq, HDF5** (F15, old 1584–1585). FlightCore-era status quo.
   §10.2 drops OrdinaryDiffEq as a dependency (spec 4992) and keeps an
   extension possible (5061), so "compatibility" holds; HDF5 export is open
   (`pending.md` 127–131). Owner: reword when HDF5 is ruled.
10. **"`Int`s, enums and `Bool`s belong in modes"** (§7.1; §8.2 2611–2612 repeats
    it as a message). Reads as a ruling. `survey.md` 765–766.
11. **"Not snapshotted, not replayed"** for the workspace (§7.3, survey row
    50). Reads as a ruling, implied by D-183's "no information carried
    between calls" but not stated. `units/C/rulings.md` 106–107.
12. **Status-quo descriptions moved to the companion** (walked-type
    inventory, "roughly half", "need no migration", "already mostly does",
    `attitude.jl`): descriptions of Flight.jl, not rulings. No owner action;
    listed so they are not mistaken for owner items (`survey.md` 777–785).

F11 (no sharpening) and F12 (projection "unconditional", which D-116
Rationale 3491–3492 states per boundary/frame) need no action.

## Serious candidates (recipe step 2)

None. Checked:
- K7, D-231 "any leaf's `m`" against the spec's continuous-only `m`. A later
  Position (D-249, log 9363–9365) and the spec's bold (§8.2 2686, D-112,
  D-249) agree; D-231's phrase can be read consistently. Tie-break rule:
  annotate (T-B4).
- F15: "compatibility" is not a dependency; §10.2 5061 keeps the extension.
- F12: D-116 Rationale agrees the budget is per body.
- K3 (old "per-boundary allocation cost is zero" against §11.2 6419–6420):
  ruled; the old sentence's context was the reference fields.
- F1's notes (B2): tested; the example's claim holds.

## Orchestrator's status on the blocking items

- **B1 closed, no edit.** The names were in the old text, the spec uses the
  walkthrough's name and "pose" bare elsewhere (2555, 11232; §4.3), and none
  is Flight.jl machinery.
- **B2 closed, no edit.** The consolidator ran the example: `s0` to `s3`
  determine the next draw, and `s4` does not change it. D-231's Rationale
  sentence rules nothing, and the example stays an illustration.
