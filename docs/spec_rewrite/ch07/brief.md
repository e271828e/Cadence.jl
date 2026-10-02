# Brief: the readability rewrite of spec chapter 7

You rewrite one unit of chapter 7 of `docs/design/spec.md`, "State and data
representation", for readability, with no loss of content. Four agents work
in parallel, one per unit. This file is the same for all of them; your
prompt names your unit.

Paths below are relative to `docs/spec_rewrite/ch07/` unless they start
with `docs/`. Run the checker from `docs/spec_rewrite/`. The base commit is
`8032ff2`; old spec lines below are lines of `spec.md` at that commit, which
the working tree still matches. Line 1 of `chapter_old.md` is spec line 1499.

## Read first

1. `docs/design/tools/spec_style.md`, all of "Sentences", "Terms", "Section
   template", "Marking rulings", "Rationale" and "Content preservation". It
   is the convention you write to. This brief does not restate it.
2. Chapter 9 of `docs/design/spec.md`, §9.4, §9.5 and §9.7 at least, read by
   section. It is a finished chapter, written to the convention, and it
   states much that chapter 7 touches.
3. `survey.md`: part A for your unit's sections, part B's overlaps, part C's
   moves, order and bold table for your unit, part D's rows for your lines
   and its list of phrases quoted from outside, part E's items for your
   lines, and part F. Part F's warnings apply to every unit. Read them all.
4. Your unit's `units/<U>/old.md`, the text you rewrite.

Read `spec.md` by section via its heading outline, never whole. Read a
decision entry in `docs/design/decisions.md` in full before you cite it or
claim what it rules. Grep the log; never read it whole.

## Rulings already made

These are the orchestrator's rulings at checkpoint 1, each on the survey's
part G question named. Apply the ones that touch your unit, and tag each
such claim in the inventory with `"tag": "R"` and `"ruling": "<id>"`.

- **R1. The chapter gains an opening** (q1, M0; unit A). After `## 7.`, a
  context paragraph saying what the chapter fixes, sourced only from the
  Part I roadmap (spec 133 at `8032ff2`), the Part II roadmap's first
  paragraph (spec 1900) and the chapter's own content, then one roadmap
  sentence naming §7.1 to §7.5 by subject. Every word is a declared
  addition. It may name the buffer, stores and the workspace without
  glossary links; the sections link them. Model: the openings of chapters
  8, 9 and 10.
- **R2. Flight.jl names** (q2, as the survey's table). Reason: spec_style's
  reader-cold rule; the survey checked every inbound row the table touches.
  - Unit A: keep `RQuat` and `Ranged` with one introducing clause at first
    use (a rotation quaternion type with a `normalization` keyword; a
    clamped scalar). Keep FlightCore's `f_ode!` with a short gloss
    (FlightCore's in-place derivative function). Keep the five things
    bought as the contrast with FlightCore, `ComponentArrays` glossed from
    the section's own words (mutable views into the flat vector), and
    `get_x_ss`/`assign_x_ss!`/`get_u_ss` introduced as FlightCore's
    per-aircraft state-space mapping functions.
  - Unit B: M3 and M4. Move the walked-type inventory from "(about 25
    structs)" through "so existing behavior is untouched", the `Quaternion`
    sentence and the invariance sentence included, and the clause "which the
    codebase already mostly does" and the sentence on `attitude.jl`, to
    `units/B/companion_addition.md`: a paragraph to join
    `docs/design/companions/migration_outline.md`'s "The parametrization
    pass", written as Flight.jl's (FlightPhysics' payload types), citing
    §7.2. §7.2 keeps the Walked tier's definition, `FrameTransform` as its
    one example (spec 3258 relies on it), and the pattern sentence
    "Constructors infer `T`, so call sites don't change, and `@kwdef`
    defaults pin the no-argument case to `Float64`" (`extensions.md` 294
    relies on it), with `@kwdef` glossed as Julia's keyword-constructor
    macro. Keep "roughly half the type inventory" only if the companion
    paragraph holds it too; map each moved claim to its span there.
    Interpolations.jl takes an introducing clause (the interpolation package
    Flight.jl's lookup tables use).
  - Unit D: FlightCore's `f_ode!` in §7.4 stays.
- **R3. §7.4 stays whole** (q3, option a), rewritten for prose. The four
  steps keep their numbers: spec 10578, D-125 and D-169 cite steps 2 and 4
  by number.
- **R4. Bold across chapters** (q4).
  - D-190 is bold at §9.5. §7.1 cites it plain, with no bold.
  - D-231's first Position sentence holds two rulings joined by "and": the
    field rule, whose home is §7.3, and the check's run, which §9.1 bolds.
    Unit C bolds the field rule ("Every field of an `s` or `m` store value
    is isbits or a `Symbol`") and cites D-231. Unit C also bolds D-231's
    second sentence (the frozen-reference latitude stays with signals) and
    third (a PRNG object is workspace, the draw-determining values are
    state), each once. This reading is recorded here so the cross-chapter
    bold check does not flag it.
- **R5. §7.5 states the invariant's scope** (q5, option a; M8, F8; unit D).
  After the three reasons, add two plain sentences, unbolded, as declared
  additions: (1) the zero-allocation invariant covers the stepping loop,
  and the stopped-sim services are allocation-tolerant, citing D-135 and
  pointing to §14.8; (2) publication is on the framework side of the scope
  with logging, not a phase body, citing D-288 and pointing to §11.2. Each
  sentence claims only what spec 4406 (§9.4), spec 4916 (§9.7) and D-135's
  and D-288's text already say; read them first, and quote their words
  where you can. Reason: seventeen outside citations already read the scope
  in §7.5, and the facts are recorded. D-014's bold stays on the budget
  sentence.
- **R6. Duplicates trimmed to pointers** (q6, option a).
  - Unit A, M1: the codegen-freedom paragraph becomes one sentence that
    states, in §7.1's own words, that the buffer is unchanged within a
    sweep and that this rule is the legality condition of the code
    generator's CSE, with a pointer to §9.7 for rebuild-per-call and
    hoisting. Keep the phrase "buffer-unchanged-within-a-sweep": §9.7 cites
    §7.1 for it by name. Never reduce it to a pointer to §9.7, which points
    back (lesson 16). Map each cut claim to its span in §9.7.
  - Unit A, M2: "one home per datum" becomes a pointer to §5.2, keeping
    the clause that no state cells sit in the table beyond the declared
    ports a component returns from `y_state`, "which are interface, not
    transport". Keep one `[one home per datum](#g-one-home-per-datum)` link.
    Map each cut claim to §5.2.
  - Unit C, M6: "Available on both tiers" merges into the scalar rule for
    `ws_init`. Its `Dual` and BLAS sentences stay. "That multiplicity" must
    still follow the continuous calls it points at.
- **R7. Orders and labels** (q7, option a), as survey part C's "Order within
  each section": §7.1's `Ẋ` paragraph after the vocabulary's reason; §7.2's
  tier list before the walk paragraph (M5); §7.3's labels "Stores: discrete
  state and modes", "Workspace" and a new "Idioms", with the
  double-buffering heading folded into one sentence at the end of the stores
  block citing D-013 (M7); §7.5's event-firing bullet becomes a paragraph
  after the tier list (M9). No subheadings in §7.1, §7.2, §7.4 or §7.5; each
  ends its context paragraph with one sentence naming its parts. Check the
  final order for define-before-use yourself.
- **R8. Factual corrections** (q8), each with its evidence in survey part E:
  - Unit A: F4, "the `s` and `m` stores hold `s` and `m`" (D-302). F9, both
    "today's" at old 1565 and 1572 become "FlightCore's". F16, "A handler's
    `x` key and the projection carry a new `X`" (§5.2's handler return
    law). F17, name `IllegalStateLeaf` where the closed vocabulary is
    stated, with pointers to §8.2 for its messages and §9.1 for the step
    (Appendix C cites §7.1 for it).
  - Unit B: F6, "Every declaration but the allocator (§7.3) is written at
    nominal `Float64`" (D-263 Position bullet 4). F9, "the compositions in
    use" becomes "the compositions in Flight.jl's tables"; the other two
    instances leave with R2's moves.
  - Unit C: F1, the `Noise` block's first line becomes
    `s_init(::Noise)         = (rng = UInt64.((0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667)),)`,
    the rest of the block unchanged; this is the only edit allowed inside a
    code block (the survey ran both versions against the package; the
    original fails `ConformanceFailure`). F2, "The `init` in `ws_init`
    means *establish*" (D-267, D-220's annotation). F3, "this declaration"
    for "this store" (D-302). F5, "values whose fields are isbits or
    `Symbol`s" for "isbits values" at old 1657.
  - Unit D: F7, "a split-form spelling of a rigid-body kinematics and
    dynamics core", citing D-015, with no file name. F9, "today's
    `y_state`" becomes "(now `y_state`)", inside the parenthesis so "That
    decoder" keeps its antecedent. F10, "Once contract visibility (§8.3,
    D-034) made a port's publicity a declaration" for "Once §8.3 made
    publication a deliberate interface act".
- **R9. The units** are the survey's four (q9, option a), below.
- **R10. Constructive passages stay** (q10, option b): the round-trip
  sentence's "no constructor bypass, no `reinterpret`" list, §7.4's prior
  art and the rematerializing sentence. None argues a design down.

Left as written, flagged and listed in `rulings.md` if you touch them: F11
("any Float64-pinning"; do not sharpen it), F12 (projection
"unconditional"), F13 (`ValueSnapshot`), F14 (`GC.gc(false)`, already in
`pending.md`), F15 (OrdinaryDiffEq, HDF5). If you find a new factual
problem, it stays as written and goes to `rulings.md`.

## Rules for every unit

- **Keep every claim**, with its strength and scope: never, only, must,
  may, recommended, exactly, at most, deliberately. Keep every causal link
  in its direction. Make no claim the old text does not make, except what a
  ruling above orders. A transition that asserts nothing is fine.
- **A gloss or an introducing clause claims nothing beyond the source it
  names.** Chapter 10's rewriters invented a demo's file and aircraft; the
  verifiers caught each one.
- **Moves** are limited to the rulings above and the survey's part C moves
  for your unit. A claim you would like to move or delete otherwise stays,
  and the proposal goes in `rulings.md`.
- **Bold**: follow `spec_style.md`, "Marking rulings", and survey part C's
  bold table, which lists twelve bolds for the chapter. Bold the headline
  clause only. Its D-citation may sit anywhere later in the same sentence.
  Every old **Rule.**, **Why.** and **Example.** label goes, and every bold
  lead-in becomes a `####` topic label, a plain topic sentence or a bold
  headline clause with its citation. A rule with no entry stating it
  (§7.2's three author rules and its lookup rule, for example) is stated
  plain: `check_bold.jl` refuses a bold with no D-citation. The one-bold
  test for old entries: semicolons separate rulings, and "+" or a comma
  list joins clauses of one ruling. Before you finish, grep the other
  units' `new.md` files and chapters 8 to 10 of `spec.md` for bolds citing
  the same entries as yours (`survey.md` part B's last table and
  `scratch_survey/bold_rewritten.txt` list the latter), and list any ruling
  bold in two places in `rulings.md`.
- **Subheadings**: `####` topic labels, never a question or a claim. Check
  your final order for define-before-use: no term or name is used before the
  text that defines it, unless a pointer says where.
- **Glossary links**: one per term per section, at its first use, with the
  gloss `spec_style.md` asks for. Not every link the old text had. A term
  whose first use moved needs its link at the new first use. Keep at least
  one `[log](#g-log)` link in §7.5: no other body line links it.
- **Reader-cold names**: introduce each one, from the start
  (`spec_style.md`, "Introduce every reader-cold name"; R2).
- **Citations** stay reference-style: `[§9.2][s9-2]`, `[D-263][d-263]`,
  `[Appendix C][sC]`. Never cite a superseded entry. Every citation you add
  or replace goes in `rulings.md` with the entry's words that carry it.
  Survey part E, "Entries to cite at the rule", lists the entries that rule
  your rows uncited; add a citation where the entry's text carries the
  claim, after reading it. Where only a Rationale or Rejected list carries a
  ruling, cite the entry and list the case under "Rationale-only rulings".
  Never cite D-295 in §7.1 for "no pinned state leaf": D-295 points back to
  §7.1 for it (lesson 16).
- **The log's vocabulary is old**: never import `z`, "cells" for stores,
  `init_x`, `init_s`, `init_workspace`, `project`, `h_x`, `f`/`h`,
  "Stratum A" or poison into the spec when citing an entry.
- **The chapter cites by adjacency.** Many rules have their citation a
  sentence or a paragraph away. A split or move that separates a rule from
  its citation repeats the citation.
- **Code**: carry both fenced blocks verbatim, except R8's F1 line. New
  display blocks are allowed where `spec_style.md` asks for display code,
  declared as additions.
- **Terms of art and quoted phrases stay verbatim** (survey part F's list,
  and part D's list of phrases quoted from outside: "buffer-unchanged-
  within-a-sweep", "the explicit cast", "domain wrapper type", "of a common
  eltype `T`", "the CI invariant", "the discrete exemption", "stay
  `Float64`", "promotion handles mixing", "the canary", "a documented
  tolerance", "interned, immutable and never freed", "governed by contract
  rather than by checks").
- **Scratch files** go in your own `units/<U>/`, nowhere else. Edit no file
  outside `units/<U>/`.
- Run nothing in the background. Use `/bin/ls` or `fd`, never a bare `ls`.
  Never stash, reset, check out or commit.

## What you produce

In `units/<U>/`:

- `new.md`: the rewritten text. Unit A's starts with the "## 7." heading and
  R1's opening. Each unit's starts with its first heading and ends where
  its old text ends, moves aside. Unit D keeps the chapter's closing `---`
  as its last line.
- Unit B also writes `companion_addition.md` (R2).
- `inventory.json`, in this shape:

  ```json
  {"claims": [{"id": "C-001", "old": "...", "new": "...", "where": "new",
               "cites": ["§5.2"], "newcites": ["§5.2", "D-013"], "tag": "F"}],
   "added": ["a new sentence with no old source, normalized"]}
  ```

  One entry per atomic claim of `old.md`, in order. `old` is the claim's
  verbatim span in the normalized old text, and `new` its verbatim span in
  the normalized text at `where`. Print both normalized texts with

  ```
  python3 checks/check_unit.py ch07 show-old <U>
  python3 checks/check_unit.py ch07 show-new <U>
  ```

  and copy spans from that output. `where` is `"new"` for your own text. For
  content held elsewhere it is the path that holds it:
  `docs/design/spec.md` or `docs/design/decisions.md` for text outside the
  chapter, `units/B/companion_addition.md` for unit B's moves, and
  `units/<V>/old.md` for content another unit owns. `cites` lists the
  citations inside the old span, and `newcites` those your new text
  attaches, if they differ. `tag` is `F` for a fact carried over, `X` for
  framing, `M` for moved or held elsewhere, `C` for a citation added or
  replaced, and `R` for a ruled edit, with its `"ruling"`. `added` lists,
  verbatim and normalized, every new sentence or clause with no old source.
- `rulings.md`, with these sections: **Corrections proposed** (quote, line,
  evidence, proposed text); **Citations added or replaced** (entry, the words
  that rule it); **Rationale-only rulings** (entry, field, log line);
  **Bold on the same entry elsewhere**; **Inbound citations affected**;
  **Open questions**.

Run `python3 checks/check_unit.py ch07 check <U>` until it prints
`checks failed: 0`. A cold verifier then reads your text blind and matches
it against your inventory. Drift that passes the script still fails there.

## The units

Line numbers are old spec lines at `8032ff2`. Survey part F rates each
unit's difficulty and names its hazards.

**A: the chapter heading, the new opening and §7.1** (1499–1589, 819 words
plus the opening).
- Order of part C for §7.1, no subheadings; the context paragraph ends in
  one sentence naming the parts.
- R1, R2, R4 (D-190 plain), R6 (M1, M2), R7, R8 (F4, F9, F16, F17).
- D-010 rules the section and is cited nowhere; bold its ruling once, as
  part C's bold table says, and D-094's two rulings (the closed vocabulary,
  the flat declaration). Splitting old 1503–1512 needs D-094 at both.
- "Nobody outside the framework" follows the authority sentence; "It" after
  "'Ephemeral' is literal" must keep its antecedent.

**B: §7.2** (1590–1652, 484 words).
- Order of part C: the generic path and its four consumers; the three tiers
  (M5), with the discrete exemption as the Exempt tier's consequence; the
  per-leaf spelling; lookups; the three author rules, stated plain.
- R2 (M3, M4, `companion_addition.md`), R7, R8 (F6, F9).
- Two senses of *pinned*: the Pinned tier, and a `Pinned{P}` contract leaf;
  both link `#g-walked`. Keep them distinct.

**C: §7.3** (1653–1794, 1,125 words).
- Labels of R7. Five **Rule.** and two **Why.** labels to fold. Seven bolds
  (part C's table: D-013, D-231 three times, D-183, D-077, D-263 bullet 4).
- R4, R6 (M6), R7 (M7), R8 (F1, F2, F3, F5).
- `KF`'s allocator is cited from §8.1 ("`ws_init(c::KF, ::Type{T})` reads
  `c.n`"); carry it verbatim.

**D: §7.4 and §7.5** (1795–1884, 824 words).
- §7.4 per R3, with one context sentence first naming the problem every
  step addresses (the shared computation between derivatives and outputs,
  §5.3). §7.5 in part C's order: context and the three reasons, R5's scope,
  the tiers as a list, M9's paragraph, the levers.
- R3, R5, R7 (M9), R8 (F7, F9, F10). F12 to F15 stay as written.
- "these are the honest levers" needs both tools before it.
