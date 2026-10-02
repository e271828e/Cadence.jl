# Chapter 7 track 2: edits applied — 2026-10-02

Applies `rulings_batch.md` section 3 (T-A to T-E) as its section "Orchestrator's
status on track 2" rules it. `log` is `docs/design/decisions.md`, `spec` is
`docs/design/spec.md`, and `ext` is `docs/design/extensions.md`. Every line
number is the line **after** all edits and the `linkify.jl` run. The batch's
line numbers predate landing, so every edit was matched by its text. New
citations were written bare, and `linkify.jl` linked them afterwards.

## Step 1. New entries

D-304 (T-A1, T-A4, T-A11, with T-A9 and T-A10), D-305 (T-A2, T-A3, T-A17) and
D-306 (T-A13, T-A14, T-A16) sit after D-303 and before the link-definition
block, at log 12676 to 12763. Vocabulary is today's: `x_init`, `s_init`,
`m_init`, `x_projection`, stores, buffer, budget. The sources say `init_x`,
`project`, "tier" (for a budget) and `init_workspace`, and D-077 calls the
workspace "a store".

T-A8 to T-A10, as the Status orders, were first checked against the
Positions of D-263 and D-295.

- T-A8, participation authored per leaf: D-263's Position states it, log
  10307–10308: "every `Float64` position follows the activation scalar. A
  leaf wrapped as `Pinned{P}` is pinned at every activation". Presence or
  absence of the marker per leaf is participation per leaf. So no entry, and
  §7.2's sentence cites D-263 (step 2).
- T-A10, nothing from inference: neither Position states it. D-295's
  Position is about tier scope, obligations, root inputs and stores, and
  D-263's about the walk and the marker. So it joins D-304.
- T-A9, type stability under `Dual`: neither Position states it, so it joins
  D-304. The bullet restates D-235's one sentence only. §7.2's three author
  rules stay T-E1, the owner's.

### D-304 — The flat declaration, the unchanged buffer, the store-field limits and authored genericity (log 12676)

Spec: §7.1, §7.2, §7.3. Rejected: none beyond the source entries' lists.

- Bullet 1, flat (T-A1) ← D-094 annotation, log 2802–2806: "the declaration
  is also flat. A `NamedTuple` field would materialize without invariants, but
  the condition algebra and the readers address an `init_x` field as one leaf
  ([§14.3], [§14.4]), and structure is the component tree's to express; the
  check that enforces the vocabulary refuses nesting with the rest."
- Bullet 2, the CSE's legality condition (T-A4) ← D-288 Rationale, log
  12035–12036: "views rebuild per call, hoisting being compiler CSE, whose
  legality condition is the staleness rule"; D-086 Rationale, log 2581–2582:
  "views rebuild-per-call (hoisting = compiler CSE, whose legality condition
  is the staleness rule)". "The buffer is unchanged within a sweep" names the
  staleness rule in today's words: §7.1 (spec 1558–1559) calls it "this
  buffer-unchanged-within-a-sweep rule", and §9.7 (spec 4831–4832) "§7.1's
  buffer-unchanged-within-a-sweep rule".
- Bullet 3, the nesting edge (T-A11) ← D-231 Rationale, log 8630–8631: "The
  check stays one exact predicate per field and does not recurse, so a struct
  nesting a `Symbol` is rejected."
- Bullet 4, no arithmetic (T-A11) ← D-302 Rationale, log 12602–12603: "The
  rules that hold for the `s` and `m` stores alone, isbits fields, no
  arithmetic and copy by bits, say so where they are stated."
- Bullet 5, type stability (T-A9) ← D-235 Rejected, log 8791–8792: "Type
  stability under `Dual` is an authoring rule ([§7.2]), not a conformance
  predicate."
- Bullet 6, participation never inferred (T-A10) ← D-079 Rejected, log
  2386–2387: "*Probe-inferred participation:* inverts
  declarations-define-probes-check; one probe point cannot speak for
  branch-dependent participation."

### D-305 — The zero-allocation invariant's scope, its grounds and its budgets (log 12715)

Spec: §7.5. Rejected: none beyond the source entries' lists.

- Bullet 1, the scope (T-A2) ← D-135 Rationale, log 4260–4261: "[§7.5]'s
  zero-allocation invariant being scoped to the stepping loop (the services
  were always allocation-tolerant, [§14.8])".
- Bullet 2, dogma and the canary (T-A3) ← D-014 Rejected, log 567–568:
  "*Blanket dogma:* fights logging reality." and "*No policy:* loses the
  type-instability canary." D-116's canary rejection (a pinned nonzero
  baseline) is not restated: the Status names D-014 alone.
- Bullet 3, the budgets' membership (T-A17) ← D-116 Rationale, log
  3513–3515: "guards and `project` (unconditional per boundary/frame) join the
  exactly-zero tier, handlers (episodic, only on firing) join the tick tier's
  zero-by-idiom".

### D-306 — The workspace outside conditions, plans valid from allocation, and double-buffering deferred (log 12739)

Spec: §7.3. Rejected: none beyond the source entries' lists. The working title
in the Status ("the workspace contract's unstated rulings") would be stale once
the entry exists, so the title names the three rulings.

- Bullet 1 (T-A14) ← D-077 Rejected, log 2311–2313: "a workspace is not
  memory that conditions overlay, and no [§8.2] by-value argument (condition
  overlay base, probe-value barrier) covers a store conditions exclude and the
  poison overwrites."
- Bullet 2 (T-A13) ← D-183 Rejected, log 6606–6607: "plans and
  factorizations are valid from allocation".
- Bullet 3 (T-A16) ← D-013 Rejected, log 554: "*Double-buffering:* deferred;
  publication races."

T-A5, 6, 7, 12, 15 and 18: no entry, per the Status.

## Step 2. Chapter 7 citations

No bold span changed. `check_bold.jl` counts 12 spans and 119 bold words in
chapter 7, and the chapter's `**` count is 24 before and after.

- D-304: spec 1530 (bold, beside D-094), 1561 (beside D-288), 1666 (beside
  D-032 and D-079), 1680 (beside D-011 and D-235), 1707 ("no arithmetic is
  ever done on them", uncited before, so D-304 alone), 1717 ("A struct nesting
  a `Symbol` does not qualify", uncited before, so D-304 alone).
- D-263 (T-A8): spec 1664–1665, "Participation is therefore authored per
  leaf, by the absence or presence of the marker", uncited before.
- D-305: spec 1891 (beside D-014), 1902 (beside D-135), 1915 (bold, beside
  D-014 and D-116), 1919 ("Their allocation is zero by the
  workspace-plus-snapshot idiom … and immutable-value returns", cited to §7.3
  alone before, so D-305 alone at the sentence's end).
- D-306: spec 1731 (beside D-013), 1742 (beside §14.1; D-306 covers the
  condition-target clause only, and "not snapshotted, not replayed" stays
  T-E11), 1749 ("A plan or factorization configured at allocation is valid
  from then on", uncited before).

Uncited sentences gain the new entry alone, as chapter 8 did at spec 2354 and
2593. Rewraps, to stay within 80 rendered columns: spec 1530–1533, 1664–1667,
1749–1751, 1891–1899, 1901–1906, 1919–1922.

## Step 3. Annotations (T-B1 to T-B7)

Each is a new paragraph before the entry's `**Rejected.**` line, after its
Rationale and any earlier annotation. Old text: none.

- T-B1, D-013, log 548: "Annotation (2026-10-02): `z` is `s` since D-195, and
  the discrete state lives in stores, which are not cells (D-121, D-302).
  Immutable discrete state, the workspace and the snapshot idiom stand."
- T-B2, D-035, log 1119: "Annotation (2026-10-02): amended by D-252, which
  removes auto-publication. A component exposes a state or mode field by
  returning it from `y_state`. The views, the bundle, the produced-only table
  and the no-feedthrough stage stand."
- T-B3, D-077, log 2298, after the 2026-09-24 annotation: "Annotation
  (2026-10-02): the scoped debug poison is retired by D-183, and so is the
  poison the Rejected list's second and fourth items name. The framework never
  inspects or mutates a workspace, and `undef` allocation is the sole visible
  marker of meaningless contents. Sizes from the instance, eltypes from the
  activation, both tiers and the no-information-between-calls contract stand."
- T-B6, D-116, log 3520: "Annotation (2026-10-02): §7.5 calls its tiers
  budgets. The "carve-out" is the invariant's scope, which §7.5 states: the
  invariant covers the stepping loop, and publication is not a phase body
  (D-305). `project` is `x_projection` (D-220, D-267)."
- T-B5, D-121, log 3681, after the earlier 2026-10-02 annotation: "Annotation
  (2026-10-02): the workspace is no longer poison-covered. D-183 retires
  workspace poisoning, and §7.3 states the workspace's rules as contract
  only."
- T-B7, D-203, log 7366: "Annotation (2026-10-02): §7.2 never stated the
  clock's seed, and no spec sentence states it today, so the fourth
  rejection's citation has no referent. The rejection's other grounds stand."
  A grep of the spec for `seeded`, `zero(T)` and "clock" with "seed" found no
  sentence on the clock's seed.
- T-B4, D-231, log 8633: "Annotation (2026-10-02): `m` is continuous-only,
  since a discrete component has no mode store (§3.2, §8.2). "Any leaf's `m`"
  reads "the `m` of every leaf that declares one". `init_s` and `init_m` are
  `s_init` and `m_init` (D-267), and Stratum A is the structure step (D-259)."
  §3.2 (spec 345) bolds "`m` is continuous-only"; §8.2 (spec 2754–2755) lists
  `m_init` as continuous-only.

## Step 4. Spec Fields (T-C)

Closed, per the Status. No existing entry's Spec field changed: every section
the new citations add was already in its entry's field (D-263 has §7.2).

## Step 5. Outside chapter 7 (T-D)

- T-D1, spec 4833 (§9.7). Old: "fields (`u`, `y_x`/`y_s`) are per-call by
  topological necessity either way" / "([§7.1][s7-1])." New: "fields (`u`,
  `y_x`/`y_s`) are per-call by topological necessity either way."
- T-D1, spec 12134 (Appendix C, `IllegalPortType`). Old: `([§7.1][s7-1],
  [§8.2][s8-2])`. New: `([§4.3][s4-3], [§8.2][s8-2])`. §4.3 states the
  refusal (spec 546–548).
- T-D1, spec 12616 (glossary, *scratch*). Old: `([§7.5][s7-5],
  [§10.3][s10-3], [§10.4][s10-4])`. New: `([§10.3][s10-3], [§10.4][s10-4])`.
- T-D1, log 7366 (D-203): the T-B7 annotation above.
- T-D4, spec 2263 (§8.2). Old: "[§7.1][s7-1] forces every state leaf to follow
  the". New: "[§7.1][s7-1] and [§7.2][s7-2] force every state leaf to follow
  the". **Applied, because the sentence relies on the walk rule.** "Follow
  the scalar of the activation" is §7.2's rule: "a `Float64` leaf follows the
  activation scalar, in a contract and in the `x_init`-derived state type
  alike" (spec 1661–1662). §7.1 supplies only the closed vocabulary, which
  leaves no state leaf that could be pinned.
- T-D5, ext 283–285. Old: `it is [§7.2][s7-2]'s "no `::SomeType{Float64}`
  annotations"` / `rule transposed from method signatures to field
  declarations.` New: `it is [§7.2][s7-2]'s "no `::SomeType{Float64}``,
  `return-type annotations" rule transposed from method signatures to field`,
  `declarations.` The quote now matches §7.2's rule 3 (spec 1684).
- T-D6, spec 821–824 (§5.2). Old: "The buffer holds `x`, the stores hold `s`
  and `m`,". New: "The buffer holds `x`, the `s` and `m` stores hold" / "`s`
  and `m`, …", with the paragraph's last three lines rewrapped. §5.2 keeps
  its markers.
- T-D6, spec 12599–12601 (glossary, *one home per datum*). Old: "— the buffer
  holds `x`, the stores hold `s` and `m`,". New: "— the buffer holds `x`, the
  `s` and `m` stores hold" / "`s` and `m`, and the table holds produced
  signals. …", rewrapped.

Left per the Status: T-D2 and T-D3 (spec 7886's "model sweep" carried to
chapter 11 below), T-D7 (`src/` and `test/`, the owner's).

## Step 6. `docs/spec_rewrite/README.md`, "Carried to later chapters"

- Line 45, lead-in. Old: "Doubles and pointers chapter 8 found". New:
  "Doubles and pointers chapters 7 and 8 found", so the new bullets fit the
  lead-in.
- Line 50, new Chapter 3 bullet: §3.1 (spec 304) "an isbits struct of real
  scalars" and §3.2 (spec 331) "any isbits value", against §7.1's flat
  NamedTuple of real scalars and `SArray`s and §7.3's isbits-or-`Symbol`
  fields (D-231).
- Line 59, new Chapter 11 bullet: §11.8 (spec 7886–7887) "the model sweep",
  against §7.5's "the stepping loop" (D-305).
- No Chapter 5 note: T-D6 settles §5.2's sentence, and nothing else in §5.2
  carries the old phrase.

Found and not applied, since no ruling covers them: Appendix A, spec 11432,
repeats "the stores hold `s` and `m`"; §14.4, spec 10322, says "A discrete
`s` field is any isbits value (§3.2)", against D-231's isbits-or-`Symbol`.

T-E: the owner's list, reported when the chapter closes. Nothing ratified.

## Step 7. Battery

The edit script asserted all 31 matches, each found exactly once, before it
wrote anything. `linkify.jl` ran, then:

- `check_refs.jl`: OK — every citation and every anchor resolves.
- `check_rows.jl`: OK — every decision citation names an existing entry.
  Newly cited by the spec includes D-304 to D-306.
- `check_glossary.jl --strict`: OK.
- `check_bold.jl`: OK. Chapter 7: 12 bold spans, 119 bold words.

The second `linkify.jl` run changed nothing; the diff's hash was identical
before and after it, and `git diff --stat` was unchanged.

## Orchestrator touches after the agent's run

- **T-D6 extended to Appendix A** (lesson 19). The *One home per datum* bullet
  read "the stores hold `s` and `m`"; it now reads "the `s` and `m` stores
  hold `s` and `m`" (D-302 Position).
- **§14.4's "any isbits value"** for a discrete `s` field is carried to
  chapter 14's rewrite in `README.md`, beside chapter 3's carry of the same
  wording.
