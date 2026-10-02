# Brief: the readability rewrite of spec chapter 8

You rewrite one unit of chapter 8 of `docs/design/spec.md`, "The declaration
layer: components and assemblies", for readability, with no loss of content.
Nine agents work in parallel, one per unit. This file is the same for all of
them; your prompt names your unit.

Paths below are relative to `docs/spec_rewrite/ch08/` unless they start
with `docs/`. Run the checker from `docs/spec_rewrite/`. The base commit is
`084d6f0`; old spec lines below are lines of `spec.md` at that commit, which
the working tree still matches.

## Read first

1. `docs/design/tools/spec_style.md`, all of "Sentences", "Terms", "Section
   template", "Marking rulings", "Rationale" and "Content preservation". It
   is the convention you write to. This brief does not restate it.
2. Chapter 10 of `docs/design/spec.md`, from "## 10." to "## 11.", read by
   section. It is a finished chapter, written to the convention.
3. `survey.md`: part A for your unit's sections, part B's overlaps, part C's
   moves and order for your unit, part D's rows for your lines, part E's
   items for your lines ("Entries to cite at the rule", "Superseded and
   half-superseded citations", "Factual problems in chapter 8"), and part F.
   Part F's warnings apply to every unit. Read them all.
4. Your unit's `units/<U>/old.md`, the text you rewrite.

Read `spec.md` by section via its heading outline, never whole. Read a
decision entry in `docs/design/decisions.md` in full before you cite it or
claim what it rules. Grep the log; never read it whole.

## Rulings already made

These are settled. Apply the ones that touch your unit, and tag each such
claim in the inventory with `"tag": "R"` and `"ruling": "<id>"`.

- **R1. `Group`'s rate declaration stays as written** (survey q1, F6). The
  `Group` block (old 2794–2813) and the sentence "`(children =
  Relative(2),)` is the uniform spelling for a `Group`" are carried
  verbatim. `src/` has a `rates` field and a `sample_times(::Group)` method
  that the spec's sketch lacks, and no entry records them. That is the
  owner's to decide, and it is in `escalations.md`. Bold nothing about it,
  and fix nothing about it.
- **R2. The wire clauses stay in §8.2** (survey q2, option a). §8.2 keeps
  its statement of the two clauses (old 2280–2300). Cite D-263 and D-236 at
  the clauses, after checking that each Position carries what you cite it
  for. Add one pointer sentence to §6.1 for the kinds and the remedies.
  §6.1 1277 points here for the clauses, so §8.2 must keep stating them.
- **R3. §8.7's restatement of the rate forms becomes a pointer** (survey q3,
  M6). Keep the spelling, the sentence "Relative entries compose affinely
  down the tree, absolute entries anchor, and all are compiled to one
  `(D, Φ)` pair per discrete component" (spec 12188 and log 6981 rely on
  it), and one pointer to §10.5 for the wrappers, their validation and the
  default. Map each cut claim to its span in §10.5 in
  `docs/design/spec.md`. A cut claim §10.5 does not hold stays.
- **R4. Arguments against rejected designs** (survey q4, M8). Cut each to a
  one-clause pointer at its entry, and map each cut claim to the log span
  that carries it. Check the span says the same thing; a claim the log does
  not carry stays.
  - Unit A: 1997–1999, the re-export submodule (D-117 Rejected).
  - Unit B1: 2201–2203, the types with `probe_value` synthesis (D-073
    Rejected).
  - Unit B2: 2274, "Names-only contracts were rejected (D-033)" (D-033
    Rejected), keeping 2274–2278's constructive half, "Inputs are the
    component's *requirements*" and what it makes definable; 2313–2318's
    rejection clause (D-054 Rationale, D-078 Rejected), keeping "The
    permissive reading predicts nothing … That is what makes the marker
    carry information here".
  - Unit B4: 2662–2666, "What this rules out" (D-016, D-034, D-055, D-194
    Rejected; find which holds each item, and cite D-034 or D-239 rather
    than D-055 where R9 says so).
  - Unit E1: 2889–2890, the rejected path forms (D-040 Rejected); 2955–2959,
    the three rejected spellings (D-041 and D-170 Rejected).
  - Not cut: 2073–2075's last sentence (the glossary repeats it), and
    3373–3377, "the line not to cross", which forbids an authoring move.
- **R5. "One arity on both tiers" is trimmed** (survey q5, M5). Keep the
  class sentence ("Class fixes *which* declarations a type may define, and
  nothing about their shape"), the assembly clause, the clause "The tier is
  read from the store every leaf declares (§8.2)" (glossary 12525 relies on
  it), the name `DeclarationOnWrongTier` (Appendix C 11769 cites §8.5 for
  it), and a pointer to §8.2. Map the cut claims to their spans in §8.2,
  which unit B1 and unit B4 own: map to `units/B1/old.md` or
  `units/B4/old.md`.
- **R6. Orders and labels** (survey q6): every order and `####` label of
  survey part C, "Order within each section", for your sections. Check the
  final order for define-before-use yourself.
- **R7. Factual corrections**, each from survey part E, with its evidence
  there:
  - Unit A: F2, delete "The obvious candidate is the `where {T <: Real}`
    ceremony of a continuous `y_types` (§8.2)", and cite D-032 in place of
    D-166 for 1938–1941. F12, name the refusal at 2018–2021
    `ClassUnreadable` with a pointer to §8.5. F17, the opening names five
    subjects, the names included. F24, scope 2027's sentence to a shadowed
    stage, and add that an optional declaration shadowed in a local scope
    drops its feature silently (D-178, a Rationale-only statement; list it).
  - Unit B1: F3, delete "and a one-field store publishes its field as the
    port of that name (§5.3)" (D-252). F22, "Every declaration of a
    structural fact but the allocator takes the component alone" at 2216.
  - Unit B2: F20, after 2263 add one sentence citing D-266: `Pinned`
    records that a leaf carries no partials, not that an implementation
    cannot take them; an AD-opaque implementation that must participate
    keeps its entry tolerant and supplies a local derivative rule (§14.10),
    and a walking producer feeds a pinned entry through the `Freeze` block
    (§13.7). Take the words from D-266's Position and nothing beyond it.
  - Unit B3: F4, cite D-238 in place of D-033 at 2443. F5, drop "and no
    pinned fields on the continuous path" at 2531–2532.
  - Unit B4: F23, write `y_types(::C)` at 2619, and add that a stateless
    leaf without one is refused (§8.2; D-263's last bullet,
    `StatelessWithoutOutputs`).
  - Unit D: F13, delete "(the `LowPassFilter` precedent)" at 2847. F22, "Every
    declaration of a structural fact takes the component alone" at
    2870–2871, if R5's trim keeps the sentence.
  - Unit E1: F8, 2893–2894 becomes "That read side is the inspection side.
    It resolves a path with `resolve` under the instance walk (§13.3)."
    §13.3 names `resolve` as the walk primitive all clients share, and gives
    inspection the instance walk. F11, at 3016–3018 the latch-back wire is
    "(below)" and "would join `inner_connections`", and the sentence that
    counts the example's facts does not count it.
  - Unit E2: F9, the comments at 3105–3107 become "discrete tier: bound check
    only" and "discrete tier: cells pin (frozen-exact)". F10, the comment at
    3097 becomes `# §7.1's explicit cast`. These two are the only edits
    allowed inside a code block.
  - Unit F: F7, 3326 becomes "That is structure kept in two artifacts
    (D-039)", without the quotation marks and without "§8.1;". F21,
    replace "(the Δt-on-continuous error at declaration time, §10.5)" with a
    pointer to what §10.5 says, that a continuous bundle carries no `Δt`.
- **R8. The semantic axis is restored** (survey q8, F1). At 2052–2054 the
  spec says a declaration "names its *content*, never the *consequence*".
  Commit `c512ee6` inverted the sentence while moving it. Restore the
  reading it had before: a declaration names the *consequence* it has, not
  its *content*. Cite D-146, whose Rationale states it, and list the case
  under "Rationale-only rulings". The rest of the paragraph stands. This
  correction is also in `escalations.md` for the owner's audit.
- **R9. No citation of D-166 or D-167, and D-055's three citations** (survey
  q9). Cite D-263 at 2244 and at the three rulings whose only statement is
  in D-167 (the walk clause's tier scope at 2293, the obligation's scope at
  2308, seedability at 2332), keep their bold, and list each under
  "Rationale-only rulings" as owing a live Position. Drop D-167 from 2300
  and 2314. Cite D-034 and D-239 where 2647 and 2660 cite D-055, after
  checking that each Position carries the claim.
- **R10. The units** are the survey's nine, below.

Other factual problems, among them F14 to F16, F18 and F19, stay as written
or follow `spec_style.md`'s rule for reader-cold names. F14 to F16 read
"today's" and "the current" as Flight.jl's, with one introducing clause. If
you find a new factual problem, it stays as written and goes to
`rulings.md`.

## Rules for every unit

- **Keep every claim**, with its strength and scope: never, only, must,
  may, recommended, exactly, at most. Keep every causal link in its
  direction. Make no claim the old text does not make, except what a ruling
  above orders. A transition that asserts nothing is fine.
- **A gloss or an introducing clause claims nothing beyond the source it
  names.** Chapter 10's rewriters invented a demo's file and aircraft; the
  verifiers caught each one.
- **Moves** are limited to the rulings above and the survey's part C moves
  for your unit. A claim you would like to move or delete otherwise stays,
  and the proposal goes in `rulings.md`.
- **Bold**: follow `spec_style.md`, "Marking rulings". Bold the headline
  clause only. Its D-citation may sit anywhere later in the same sentence.
  Every old **Rule.**, **Why.** and **Example.** label goes, and every bold
  lead-in becomes a `####` topic label, a plain topic sentence or a bold
  headline clause with its citation. The one-bold test for old entries:
  semicolons separate rulings, and "+" or a comma list joins clauses of one
  ruling. Before you finish, grep the other units' `new.md` files for bolds
  citing the same entries as yours, and list any ruling bold in two places
  in `rulings.md`. Chapter 10 had five such doubles.
- **Subheadings**: `####` topic labels, never a question or a claim. Check
  your final order for define-before-use: no term or name is used before the
  text that defines it, unless a pointer says where.
- **Glossary links**: one per term per section, at its first use, with the
  gloss `spec_style.md` asks for. Not every link the old text had. A term
  whose first use moved needs its link at the new first use. §8.2 spans
  units B1 to B4 and §8.6 spans E1 and E2: in a unit that does not open its
  section, link a term only if no earlier unit of the section uses it (grep
  their `old.md`). §8.3, §8.4 and §8.7 open in the middle of a unit and
  take their own first links.
- **Reader-cold names**: introduce each one, from the start
  (`spec_style.md`, "Introduce every reader-cold name").
- **Citations** stay reference-style: `[§9.2][s9-2]`, `[D-263][d-263]`,
  `[Appendix C][sC]`. Never cite a superseded entry. Every citation you add
  or replace goes in `rulings.md` with the entry's words that carry it.
  Where only a Rationale or Rejected list carries a ruling, cite the entry
  and list the case under "Rationale-only rulings".
- **The chapter cites by adjacency.** Many rules have their citation a
  sentence or a paragraph away. A split or move that separates a rule from
  its citation repeats the citation.
- **Code and math**: carry every fenced block, the table and all inline and
  display math verbatim (survey part C, "Code blocks"). A comment edit
  inside a block is R7's F9 and F10 only. New display blocks are allowed
  where `spec_style.md` asks for display code, declared as additions.
- **Terms of art and quoted phrases stay verbatim** (survey part F's
  lists). Never import the log's old vocabulary (`init_x`, `input_types`,
  `output_types`, `connections`, `exports`, "root slot" and the rest of part
  F's list).
- **Scratch files** go in your own `units/<U>/`, nowhere else. Edit no file
  outside `units/<U>/`.
- Run nothing in the background. Use `/bin/ls` or `fd`, never a bare `ls`.
  Never stash, reset, check out or commit.

## What you produce

In `units/<U>/`:

- `new.md`: the rewritten text. Unit A's starts with the "## 8." heading,
  its context paragraph and a new roadmap sentence naming §8.1 to §8.8 by
  subject. Each unit's starts with its first heading, or with the paragraph
  its old text starts with, and ends where its old text ends, moves aside.
  Unit F keeps the chapter's closing `---` as its last line, after the
  moved-in paragraph has gone to its place in §8.7.
- `inventory.json`, in this shape:

  ```json
  {"claims": [{"id": "B2-001", "old": "...", "new": "...", "where": "new",
               "cites": ["§6.1"], "newcites": ["§6.1", "D-263"], "tag": "F"}],
   "added": ["a new sentence with no old source, normalized"]}
  ```

  One entry per atomic claim of `old.md`, in order. `old` is the claim's
  verbatim span in the normalized old text, and `new` its verbatim span in
  the normalized text at `where`. Print both normalized texts with

  ```
  python3 checks/check_unit.py ch08 show-old <U>
  python3 checks/check_unit.py ch08 show-new <U>
  ```

  and copy spans from that output. `where` is `"new"` for your own text. For
  content held elsewhere it is the path that holds it:
  `docs/design/spec.md` or `docs/design/decisions.md` for text outside the
  chapter, and `units/<V>/old.md` for content another unit owns. `cites`
  lists the citations inside the old span, and `newcites` those your new
  text attaches, if they differ. `tag` is `F` for a fact carried over, `X`
  for framing, `M` for moved or held elsewhere, `C` for a citation added or
  replaced, and `R` for a ruled edit, with its `"ruling"`. `added` lists,
  verbatim and normalized, every new sentence or clause with no old source.
- `rulings.md`, with these sections: **Corrections proposed** (quote, line,
  evidence, proposed text); **Citations added or replaced** (entry, the words
  that rule it); **Rationale-only rulings** (entry, field, log line);
  **Bold on the same entry elsewhere**; **Inbound citations affected**;
  **Open questions**.

Run `python3 checks/check_unit.py ch08 check <U>` until it prints
`checks failed: 0`. A cold verifier then reads your text blind and matches
it against your inventory. Drift that passes the script still fails there.

## The units

Line numbers are old spec lines at `084d6f0`. Each `old.md` holds the
unit's range plus the blocks that move into it, appended at its end. Survey
part F rates each unit's difficulty and names its hazards.

**A: the chapter heading and intro, §8.1** (1901–2109, 1,670 words).
- The intro gains a roadmap sentence. §8.1's order: "Plain Julia, not a
  macro DSL"; "Declarations are the schema authority"; "Contracts are
  functions of the type"; "The namespace"; "Names".
- R4 (1997–1999), R7 (F2, F12, F17, F24), R8.
- "at build time where possible" and "at first execution otherwise"
  (1931–1932) are quoted by spec 3892 and 4167; "Types come by declaration,
  values by execution, and conformance by comparison" (2075) by glossary
  12193. Keep them word for word.

**B1: §8.2's opening and the stores** (2110–2231, 1,015 words).
- The criterion paragraph (2216–2230) moves to open the section after the
  `Engine` block, as part C says, with glosses for the walk and `Pinned`.
  Then "The stores".
- Three **Why.** labels to fold. R4 (2201–2203), R7 (F3, F22).

**B2: §8.2's `u_types`, the wire clauses and root inputs** (2232–2359, plus
2597–2611 from the completeness block, M1).
- Labels: "Input contracts: `u_types`" and "Root inputs". M1's 2597–2606
  forms the root-input block with 2320–2358, and 2607–2611 merges into
  2325–2327.
- The densest argument in the chapter. R2, R4 (2274, 2313–2318), R7 (F20),
  R9.

**B3: §8.2's `y_types`** (2360–2500, plus 2527–2540, "Custom structs as
port types", M2).
- Label "Output contracts: `y_types`". M2 goes after the handle rule
  (2402–2429) and before constructibility at `T` (2431), which it leads
  into.
- D-280 and D-286 rule much here and are cited nowhere. The hint "if `F`
  participates in differentiation, remove its `Pinned`" (2465–2466) is
  quoted by D-286; keep it word for word. R7 (F4, F5).

**B4: §8.2's events, stage membership and completeness; §8.3; §8.4**
(2501–2526, 2541–2596 and 2612–2693).
- Labels: "Events: `state_events`", "Stage membership", "Completeness".
  "Four rules" becomes "Three rules", since M1 took the root rule to B2.
- §8.4's numbering is cited from outside as w1 to w5; keep it.
- R4 (2662–2666), R7 (F23), R9 (2647, 2660).

**D: §8.5** (2694–2768 and 2774–2879, 1,331 words; 2769–2773's rate-key
sugar moves to unit F, M3).
- Order: the opening rule and declarations; "Class by declaration shape";
  "One arity on both tiers" (R5); "Container children"; "`Group`: the
  on-the-fly assembly", with "The builder is rejected" (M4) folded in beside
  2826–2830, where D-184 fixes the rejection's reach.
- The ambiguity sentence ("The one ambiguity this leaves …") joins the
  bare-key collision bullet (2757–2767). Its "this" referred to the sugar
  that moved to §8.7; say what it is, with a pointer to §8.7.
- R1 (the `Group` block verbatim), R5, R7 (F13, F22). spec 7158 relies on
  §8.5's two reasons for refusing a class supertype (2840–2843); keep both.

**E1: §8.6's rules and the IMU assembly** (2880–3019, 1,178 words).
- Order of part C: paths; the three declarations; the direction invariant;
  face names and the two-notation rule; root inputs; uniqueness at the root;
  then "A worked assembly: the strapdown IMU" (new label).
- R4 (2889–2890, 2955–2959), R7 (F8, F11). "a face feeding nothing declares
  nothing" (2909) is quoted by D-210; keep it.

**E2: §8.6's IMU leaves to the sampling contract** (3020–3178, 1,278 words).
- Labels of part C: "The leaves: integrate-and-difference", "The
  exactness condition", "The leaves in code", "Freshness at the sample",
  "The boundary-sampling contract".
- Math carried literally. R7 (F9, F10).

**F: §8.7 and §8.8** (3179–3390, plus 2769–2773, M3; about 1,650 words).
- §8.7: R3, and M3's sugar sentences merged with 3191–3192. The "uniform
  spelling for a `Group`" sentence is R1's: carry it verbatim.
- §8.8: three labels, "The passthrough helpers", "One authored feed list",
  "Generic holding".
- R7 (F7, F21). Four code blocks verbatim. Two **Rule.** and two **Why.**
  labels to fold.
