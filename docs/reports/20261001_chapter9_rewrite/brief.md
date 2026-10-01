# Brief: the readability rewrite of spec chapter 9

You rewrite one unit of chapter 9 of `docs/design/spec.md`, "The build
pipeline", for readability, with no loss of content. Six agents work in
parallel, one per unit. This file is the same for all of them; your prompt
names your unit.

Paths below are relative to this report directory,
`docs/reports/20261001_chapter9_rewrite/`, unless they start with `docs/`.

## Read first

1. `docs/reports/20261001_spec_rewrite_sample/report.md`, in full. It is the
   trial on §9.4 that this rewrite scales up. Its "Conclusions" are the
   convention you write to.
2. `docs/reports/20261001_spec_rewrite_sample/versions/v4_flat.md`, the
   finished §9.4. It is what a section written to the convention looks like,
   and it is the chapter's §9.4 from now on.
3. `survey.md`: parts A, B, C, D and G for your unit's sections, and part F's
   items for them. It maps every rule to its entry, the overlaps, the moves,
   the inbound citations and the hazards.
4. `docs/design/tools/spec_style.md`, sections "Sentences", "Terms" and
   "Rationale". Its "Section template" markers (**Rule.**, **Why.**,
   **Example.**) are superseded by the convention below.
5. Your unit's `units/<U>/old.md`, the text you rewrite.

Read `spec.md` by section via its heading outline, never whole. Read a
decision entry in `docs/design/decisions.md` in full before you cite it or
claim what it rules.

## The convention

- No **Rule.**, **Why.** or **Example.** labels. A reason follows its rule
  with a plain connective.
- **Bold marks a ruling, once.** Each ruling gets one bold headline sentence
  where the section states it, and that sentence ends with the D-entry that
  rules it: `**Non-nominal activations run at first request, not at build**
  ([D-052][d-052]).` The sentences that spell out the ruling's mechanism stay
  plain. They carry a citation only when they rest on a different entry.
  Nothing else is ever bold: not lead-ins, terms, definitions, consequences,
  recommendations or labels. The survey counts 156 rule sentences in the
  chapter; expect bold on roughly one per distinct ruling, not one per
  sentence.
- Bold what the entry's Position states, not its consequence. Put the rule
  first and its reason after. A "so" or "by construction" before a rule turns
  it into a consequence.
- **Which entry to cite.** Cite the entry whose Position rules the sentence.
  If only a Rationale, a Rejected list or an annotation rules it, cite that
  entry anyway and list the case in `rulings.md`. Never cite a superseded
  entry; cite its successor, and list the case if the successor does not
  restate the ruling. Every citation you add goes in `rulings.md` with the
  words of the entry that carry it.
- `####` subheadings only where a long section needs entry points, and then
  as short topic labels. Never a question or a claim. A section without
  subheadings ends its context paragraph with one sentence naming its parts
  in order.
- Code a reader would type or copy goes in a ```julia display block: a call,
  a definition, a signature, a keyword assignment. Bare identifiers and type
  names stay inline.
- Open each section with context: what problem it solves, before any rule.
- Sentences: short, active voice, one point each. No em dashes. At most one
  parenthetical per sentence. No colon as a mid-sentence connector. Plain
  vocabulary.
- Keep section numbers. Keep titles, except where your unit says otherwise.
- Citations stay reference-style: `[§8.2][s8-2]`, `[D-052][d-052]`,
  `[Appendix B][sB]`. Glossary links stay inline, `[term](#g-anchor)`, on the
  first use in each section. Keep every glossary link the old text had in
  that section.
- Mathematics, tables of formulas and terms of art carry over unchanged (part
  G of the survey lists them).

## What you may not change

You change how the text reads, never what it says.

- Keep every claim, with its strength and scope: never, only, must, may,
  recommended, exactly. Keep every causal link in its direction.
- Make no claim the old text does not make. A transition that asserts
  nothing is fine.
- Factual problems, including the survey's part F items for your unit, stay
  as the old text states them. Propose each correction in `rulings.md` with
  its evidence. The user rules on them later.
- Moves are limited to the ones your unit lists. A claim you would like to
  move or delete otherwise stays, and the proposal goes in `rulings.md`.
- Edit no file outside `units/<U>/`.

## What you produce

In `units/<U>/`:

- `new.md`: the rewritten text.
- `inventory.json`: the claim inventory, in this shape:

  ```json
  {"claims": [{"id": "A1-001", "old": "...", "new": "...", "where": "new",
               "cites": ["§8.2"], "newcites": ["§8.2", "D-048"], "tag": "F"}],
   "added": ["a new sentence with no old source, normalized"]}
  ```

  One entry per atomic claim of `old.md`, in order. `old` is the claim's
  verbatim span in the normalized old text, and `new` its verbatim span in the
  normalized text at `where`. Run `python3 checks/check9.py show-old <U>`
  and `show-new <U>` to see both normalized texts, and copy spans from that
  output. `where` is `"new"` for your own text. For content held elsewhere it
  is the file path that holds it, and `new` is the span there. Use
  `docs/design/spec.md` or `docs/design/decisions.md` for text outside the
  chapter, `units/<V>/old.md` for content another unit owns, and
  `docs/reports/20261001_spec_rewrite_sample/versions/v4_flat.md` for §9.4.
  `cites` lists the citations inside the old span. `newcites` lists those
  your new text attaches, if they differ. `tag` is one of the following:

  - `F`: a fact carried over;
  - `X`: framing;
  - `M`: moved or held elsewhere;
  - `C`: a citation added or replaced under the convention.

  `added` lists, verbatim and normalized, every new sentence or clause with no
  old source: context openings, roadmaps, transitions, pointers.
- `rulings.md`, with these sections:
  - **Corrections proposed:** quote, line, evidence, proposed text.
  - **Citations added or replaced:** entry, and the words that rule it.
  - **Rationale-only rulings:** entry, field, log line.
  - **Inbound citations affected:** for moved content.
  - **Open questions.**

Run `python3 checks/check9.py check <U>` until it prints `checks failed: 0`.
It checks the following:

- the old spans cover every word of `old.md`;
- each new span exists where you say;
- each claim's citations sit in the same paragraph, bullet or table as its
  new span;
- every word of `new.md` traces to a claim or a declared addition;
- every bold span is followed by a D-citation.

A cold verifier then reads your text blind and matches it against your
inventory. Drift that passes the script still fails there. The trial's
verifiers caught a dropped "because", a citation that ended up covering half
its sentence, and "no path needs synchronization" for "with no
synchronization on any path".

## The units

**A1: the chapter opening and §9.1 up to the `Deployment`** (spec 3391–3572).
- M11: cut the intro's summary of §13.1 to one sentence and a pointer.
- Give the intro a roadmap sentence naming §9.1 to §9.7. §9.2 is now "The
  `Build` and `Deployment` artifacts".
- M1: the retyping list of "Activation, parametric in `T`" (3559–3568) is
  held by §9.4. Map it to `v4_flat.md`, and keep 3556–3558 and one pointer
  sentence. Keep "observed is compared against declared" in §9.1.
- M8: workspace allocation before the probes (3530–3533) is held by §9.3. Map
  it to `units/B/old.md` and keep a pointer.
- The steps table keeps its deployment and materialization rows, with a
  pointer to §9.2.
- Mind survey F1–F3.

**A2: §9.2, retitled "The `Build` and `Deployment` artifacts"** (spec
3657–3810, plus 3573–3655, which arrive from §9.1).
- M2 and M3: §9.1's "The `Deployment` constructor" and "Where a build warning
  lives" join §9.2. The warnings block merges with 3797–3810.
- Use `####` topic labels in the survey's order: "The `Build`", "Rendering",
  "The `Deployment`", "Grid diagnostics", "Warnings".
- M4: the lock clause and the immutability argument (3661–3663, 3680–3684)
  become one pointer to §9.4. Keep the immutability sentence at 3679–3680,
  which inbound citations rely on.
- M5: move the standalone-`build` justification beside its subject.
- M6: route printing is held by §13.7. Map it to `docs/design/spec.md` and
  keep one sentence with a pointer.
- M7: the example's declarations in prose are held by §10.5's code block. Map
  them to `docs/design/spec.md`. The binding table stays.
- Every fact that survey part D says an inbound citation relies on must stay
  findable in §9.2. List each one in `rulings.md`.
- Mind F4–F10.

**B: §9.3** (spec 3812–3907).
- Split the 500-word paragraph at each topic.
- M9: merge the `t` and `Δt` probe-value paragraphs, after root-input
  synthesis.
- M10: delete the list of D-051's rejected alternatives (3862–3863). Map each
  item to D-051's Rejected field in `docs/design/decisions.md`.
- Keep the workspace-allocation passage. A1 maps to it.
- Mind F11–F12.

**C: §9.5** (spec 4001–4140).
- The densest type reasoning in the chapter. Its terms of art ("exact",
  "identity", "embed", "lift", "accepts exactly two types") come from D-235,
  D-237 and D-238 and stay verbatim.
- Split the 600-word paragraph.
- Use topic labels only if the section stays above about 1,200 words.

**D: §9.6** (spec 4141–4175).
- M12: delete the duplicated trim default (4169–4170). Map it to its first
  statement.
- M13: move the Flight.jl comparisons (4144–4146, 4154–4163, 4171–4175) to
  `docs/design/companions/flight_case_studies.md`. Write the text to append
  there in `units/D/companion_addition.md`, as one new `##` section in that
  file's style, and map the moved claims to it. Companions cite their own
  sections as "section N.N" and the spec with §.
- What remains is one context paragraph and three short bullets, each an
  activation and a pointer to §14.7, §14.8 and §14.10.
- Mind F18–F19.

**E: §9.7** (spec 4177–4337).
- **Frozen:** the anchors table and the mitigation ladder, spec 4247–4280.
  They await a separate compile-time ruling. Copy that block verbatim, and
  rewrite the rest of the section around it.
- Order: representation and why it is forced, then cell storage, then phase
  bodies, arities and seams, then views and type-opaque construction, then
  compile cost (the frozen block), then the measurement seam last.
- Mind F16–F17.
