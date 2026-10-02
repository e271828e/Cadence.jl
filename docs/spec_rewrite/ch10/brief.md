# Brief: the readability rewrite of spec chapter 10

You rewrite one unit of chapter 10 of `docs/design/spec.md`, "Time and
execution", for readability, with no loss of content. Seven agents work in
parallel, one per unit. This file is the same for all of them; your prompt
names your unit.

Paths below are relative to `docs/spec_rewrite/ch10/` unless they start
with `docs/`. Run the checker from `docs/spec_rewrite/`.

## Read first

1. `docs/design/tools/spec_style.md`, all of "Sentences", "Terms", "Section
   template", "Marking rulings", "Rationale" and "Content preservation". It
   is the convention you write to. This brief does not restate it.
2. Chapter 9 of `docs/design/spec.md`, from "## 9." to "## 10.", read by
   section. It is a finished chapter, written to the convention.
3. `survey.md`: part A for your unit's sections, part B's overlaps, part C's
   moves and order for your unit, part E's items for your lines ("Entries to
   cite at the rule", "Superseded and half-superseded citations", the factual
   problems), and part F's warnings. Part F's warnings apply to every unit.
4. Your unit's `units/<U>/old.md`, the text you rewrite.

Read `spec.md` by section via its heading outline, never whole. Read a
decision entry in `docs/design/decisions.md` in full before you cite it or
claim what it rules. Grep the log; never read it whole.

## Rulings already made

These are settled. Apply the ones that touch your unit, and tag each such
claim in the inventory with `"tag": "R"` and `"ruling": "<id>"`.

- **R1. Frame and boundary move to §10.1** (survey M1). The definitions at
  old spec 4818–4829 become §10.1's two units of the loop. §10.4 keeps one
  sentence saying the localized event time `t*` is a boundary but no frame
  top, with a pointer to §10.1. The chapter gains a short intro under
  "## 10.": one context paragraph and one roadmap sentence naming §10.1 to
  §10.7.
- **R2. §10.2's case for fixed-step RK4** (survey M11, F3). Keep its three
  claims as one plain sentence each, unbolded: ticks forbid stretching steps,
  a piecewise-smooth right-hand side starves high order, and stiffness has a
  remedy ladder. The ladder stays as guidance, unbolded. Move the Flight.jl
  evidence (50 Hz avionics "today", "the current codebase", the 31 rad/s
  actuator poles, `h = 0.02`, the crosswind-landing demo, the RK4 error
  claim about a coefficient-table aircraft model) to
  `docs/design/companions/flight_case_studies.md`. Write the text to append
  there in `units/A/companion_addition.md`, as one new `##` section in that
  file's style, and map the moved claims to it. Companions cite their own
  sections as "section N.N" and the spec with §. §10.2 keeps one pointer
  sentence to that companion.
- **R3. Arguments against rejected designs** (survey q3, M6). Each deleted
  claim is mapped to the log span that carries it, and the text keeps a
  one-clause pointer to the entry.
  - §10.1, old spec 4704–4706: the `CallbackSet` rejection goes to D-017.
    The constructive half of the "Why" stays.
  - §10.6, old spec 5612–5615: the list of rejected shapes goes to D-154's
    Rejected field. The cost sentence before it stays.
  - §10.6, old spec 5630–5634: keep the first two sentences ("This trade is
    also stated openly ... lives on in `firing_budget`."). Cut "What that
    buys ..." and its list, mapped to D-181's Rationale.
- **R4. The "epoch rule" link** (survey F4). Drop the glossary link on
  "epoch rule" in §10.6. Keep the name. Say in place what that epoch is:
  the world one round's sweep produces, so no bundle mixes values from two
  rounds' sweeps. It is not the input epoch of §10.4.
- **R5. The deployment-constants block** (survey M5). Keep the sentence
  that the constants are deployment, not implementation, with the keyword
  list. Replace the validation details and the `firing_budget` list (old
  spec 5125–5132, up to "replay comparison.") with one pointer sentence to
  §9.2 and Appendix C. Map the cut claims to §9.2 in `docs/design/spec.md`
  (3753–3767 at the base commit). Keep the grid-independence sentence,
  which spec 3765 cites, and the recording rule with its reason. §9.2 does
  not say that `firing_budget` rides the trace header and the replay
  comparison. Map those two parts to the kept recording rule, which F6 below
  extends to all three parameters, and check that it says so. Anything else
  §9.2 does not hold stays in the unit.
- **R6. The seam's checkpoint hook** (survey F1). §10.2's contract gains a
  fourth clause, citing D-274, and "three clauses" becomes "four". The
  clause: the seam carries what a backend needs across a frame top through
  a checkpoint hook, empty for a single-step method. Take the wording from
  D-274's first bullet and nothing beyond it.
- **R7. The history sentence in §10.5** (survey F10). Delete "The 'tick at
  `t₀⁻`' story they once told held only in the build's own world" (old spec
  5248–5250), mapped to D-205's Rationale. Keep the rule before it and the
  phase-free remark after it.
- **R8. Factual corrections**, each from the survey's part E:
  - F5, unit B2 (moves with M4 to unit D): "cross-frame re-localization"
    becomes "re-localization within the frame".
  - F6, unit B2: "both are grid-independent" and "both are recorded" become
    "all three". §9.2 3763–3765 and D-181 cover all three parameters.
  - F7, unit C1: "`t = k·h`" becomes "`t = t₀ + k·h`".
  - F8, unit D: "They are not traced, and they are reconstructed
    deterministically" is wrong under D-274. The trace header is a
    checkpoint, which carries the prior, and `restore!` copies it back. The
    other two registers are reset on entering each boundary, as the sketch
    shows. Replace the sentence with those facts, citing D-274. Keep "not
    model memory" and "absent from every state store".
  - F9, unit D: keep the `f_step!` footgun sentence and add a D-020
    citation. D-020's Rejected list states the same class.
  - F11, unit E: "applied at the next boundary" becomes "drained at the
    next frame top".
  - F13, unit A: "the tracer" gets a gloss and a pointer: §5.6's
    feedthrough tracer.
  - F14, units B1, C1 and D: the piston engine, `starting → running` and
    the FCS cascade each get one introducing clause. FCS is the flight
    control system. Claim nothing the example's source does not.
- **R9. The units** are the survey's seven, with §10.6 whole in unit D.
- **R10. Due updates run after quiescence** (ruled after step 3, from unit
  C1's rulings). "All due `s_update` calls run after the sweep" becomes
  "after quiescence". D-020's Position says due updates "run after
  quiescence, outside the iteration", and the glossary's *due* entry agrees.
- **R11. Bold across units** (ruled after step 4). In old entries,
  semicolons separate rulings and "+" joins clauses of one ruling. D-018's
  ruling 2 keeps its bold on "Budget exhaustion degrades" in unit B2, its
  headline outcome; B1's "The interpolant is then invalidated" is mechanism
  and goes plain. D-147's interior-sweep sentence keeps its bold in B1, first
  in reading order, and C1 yields. A ruling §9.1 already bolds stays plain in
  §10.5.

Other factual problems, including F12 and F16 to F18, stay as written. If
you find a new one, it stays as written too and goes to `rulings.md`.

## Rules for every unit

- **Keep every claim**, with its strength and scope: never, only, must,
  may, recommended, exactly, at most. Keep every causal link in its
  direction. Make no claim the old text does not make, except what a ruling
  above orders. A transition that asserts nothing is fine.
- **Moves** are limited to the rulings above and the survey's part C moves
  for your unit. A claim you would like to move or delete otherwise stays,
  and the proposal goes in `rulings.md`.
- **Bold**: follow `spec_style.md`, "Marking rulings". Bold the headline
  clause only. Its D-citation may sit anywhere later in the same sentence.
  Every old **Rule.**, **Why.**, **Example.** and **Consequence.** label
  goes, and every bold lead-in becomes a `####` topic label, a plain topic
  sentence or a bold headline clause with its citation.
- **Subheadings**: `####` topic labels, never a question or a claim. Check
  your final order for define-before-use: no term or name is used before the
  text that defines it, unless a pointer says where.
- **Glossary links**: one per term per section, at its first use, with the
  gloss `spec_style.md` asks for. Not every link the old text had. A term
  whose first use moved needs its link at the new first use.
- **Reader-cold names**: introduce each one, from the start
  (`spec_style.md`, "Introduce every reader-cold name").
- **Citations** stay reference-style: `[§9.2][s9-2]`, `[D-274][d-274]`,
  `[Appendix C][sC]`. Never cite a superseded entry. Every citation you add
  or replace goes in `rulings.md` with the entry's words that carry it.
  Where only a Rationale or Rejected list carries a ruling, cite the entry
  and list the case under "Rationale-only rulings".
- **The chapter cites by adjacency.** Many rules have their citation a
  sentence or a paragraph away. A split or move that separates a rule from
  its citation repeats the citation.
- **Code and math**: carry every fenced block, the chart, the table and all
  inline math verbatim (survey part C, "Code blocks"). A comment edit inside
  a block is a ruled edit only. New display blocks are allowed where
  `spec_style.md` asks for display code, declared as additions.
- **Terms of art stay verbatim** (survey part F's list). Never import the
  log's old vocabulary ("probe", "Tier-1", "baseline", `event_budget`).
- **Scratch files** go in your own `units/<U>/`, nowhere else. Edit no file
  outside `units/<U>/`.

## What you produce

In `units/<U>/`:

- `new.md`: the rewritten text. Unit A's starts with the "## 10." heading
  and the intro. Each unit's starts with its first heading and ends where
  its old text ends. Unit E keeps the closing `---`.
- `inventory.json`, in this shape:

  ```json
  {"claims": [{"id": "B1-001", "old": "...", "new": "...", "where": "new",
               "cites": ["§10.5"], "newcites": ["§10.5", "D-081"], "tag": "F"}],
   "added": ["a new sentence with no old source, normalized"]}
  ```

  One entry per atomic claim of `old.md`, in order. `old` is the claim's
  verbatim span in the normalized old text, and `new` its verbatim span in
  the normalized text at `where`. Print both normalized texts with

  ```
  python3 checks/check_unit.py ch10 show-old <U>
  python3 checks/check_unit.py ch10 show-new <U>
  ```

  and copy spans from that output. `where` is `"new"` for your own text. For
  content held elsewhere it is the path that holds it: `docs/design/spec.md`
  or `docs/design/decisions.md` for text outside the chapter,
  `units/<V>/old.md` for content another unit owns, and
  `units/A/companion_addition.md` for R2's moved evidence. `cites` lists the
  citations inside the old span, and `newcites` those your new text
  attaches, if they differ. `tag` is `F` for a fact carried over, `X` for
  framing, `M` for moved or held elsewhere, `C` for a citation added or
  replaced, and `R` for a ruled edit, with its `"ruling"`. `added` lists,
  verbatim and normalized, every new sentence or clause with no old source.
- `rulings.md`, with these sections: **Corrections proposed** (quote, line,
  evidence, proposed text); **Citations added or replaced** (entry, the words
  that rule it); **Rationale-only rulings** (entry, field, log line);
  **Inbound citations affected**; **Open questions**.

Run `python3 checks/check_unit.py ch10 check <U>` until it prints
`checks failed: 0`. A cold verifier then reads your text blind and matches
it against your inventory. Drift that passes the script still fails there.

## The units

Line numbers are old spec lines at the base commit `08f5dff`. Each
`old.md` holds the unit's range plus the blocks that move into it.

**A: the chapter heading, §10.1, §10.2 and §10.3** (4689–4809, plus 4818–4829
from §10.4 and two sentences from §10.6, 5662–5663).
- R1: write the chapter intro. Then §10.1: the loop's activities, the two
  units (frame, boundary), the rule that the framework writes the loop
  (D-017), its constructive reason, and `OrdinaryDiffEq` dropped as a rule,
  not after "therefore". `t*` is first used here; gloss it with a pointer to
  §10.4. Boundary zero keeps its pointer to §14.5.
- R2, R3 (4704–4706), R6, F13.
- §10.3 (survey M2): its rule gains "External readers observe the table only
  after the boundary sequence completes", from §10.6, with "§10.3 extends
  naturally" as the framing it was. Unit D keeps "Earlier rounds' tentative
  values are internal scratch" and a pointer to §10.3.
- §10.3's one rule is ruled only in D-023's Rejected field.

**B1: §10.4 to the end of "The localization loop"** (4810–4817 and
4830–5016).
- R1: §10.4 opens with its context, then the `t*` sentence, then the
  one-frame chain. It needs its own first-use links for frame, boundary,
  drain, tick and boundary zero, wherever it still uses them.
- The survey's part C order: "Detection policy", "Trial evaluations" (M10,
  moved up before "The trigger", so the trigger's "(below)" becomes a
  backward reference), "The trigger", "The localization loop". The sketch
  defines θ, σ(θ) and "trial evaluation" in its first comment, so it may
  precede the prose it previews.
- The densest unit: about a thousand words under eleven bold lead-ins.
  D-179, D-182 and D-082 carry most rulings, many only in Rationales.
- "Holding" endpoints and "not-holding → holding" are not sign changes.
  Keep §10.4's input epoch distinct from §10.6's epoch.
- F14 (the piston engine).

**B2: §10.4 from "Endpoint policy and grid integrity"** (5017–5113 and
5122–5144; the budget comparison, 5114–5121, moves to unit D).
- Labels in order: "Endpoint policy and grid integrity", "The `t*`
  boundary", "The localization budget", "Deployment constants".
- The **Consequence.** label becomes a plain sentence after its rule.
- D-081 rules the `t*` boundary and is cited nowhere in the chapter.
- The no-tick-at-`t*` reason (5062–5064) stays one sentence with a pointer
  to §10.5, which has the full reason (survey M3).
- R5, F6. "Strictly later than tₙ" and `nextfloat(tₙ)` are the argument;
  keep them exact.

**C1: §10.5 from its opening to "Assemblies"** (5145–5261 and 5280–5292;
"Coincidence and stagger", 5262–5279, moves to unit C2).
- The context promises lattice, test and surface "in that order". Keep the
  promise.
- Labels in order: "The base grid and the gate", "Zero-order hold and the
  two sweep variants", "Due sets", "Simultaneous ticks", "Assemblies and
  rate scopes".
- R7, F7, F14 (the FCS cascade).
- Boundary zero's row cites D-205 while D-147 still says "everything". Cite
  D-205 and list the case.

**C2: §10.5 from "Declaring a sample time"** (5293–5469, plus 5262–5279).
- Labels in order: "The two declaration forms", "Relative composition",
  "Anchors", "When an anchor belongs in a library type" (survey M8, moved up
  after the `Absolute` block), "A worked example", "Coincidence and stagger"
  (M7, after the example, absorbing its last sentence, "the deterministic
  aging of a stagger"), "`Δt` in the bundle".
- The table, the code block and the chart carry over verbatim. The chart is
  an untyped fence, so each of its numbers and bullets must be covered by a
  claim's span.
- D-185 and D-186 carry thirteen rulings only in Rationales.
- "Stagger" is used before its block in two self-explaining places. Leave
  them.

**D: §10.6** (5470–5683, plus 5114–5121 from §10.4).
- Context and the rule first, then labels in order: "Why the phase iterates"
  (survey M9, 5544–5557, moved up after the rule), "The three registers",
  "What a handler sees within a round", "The firing budget" (ending with
  the budget comparison from §10.4, M4, after `firing_budget` is defined),
  "Ticks after quiescence".
- R3 (5612–5615, 5630–5634), R4, F5, F8, F9, F14 (the engine and the FCS).
- The sentences at 5662–5663 ("§10.3 extends naturally. External readers
  observe ...") are held by unit A. Map them to `units/A/old.md` and keep a
  pointer.
- "Blocked, not lost", "discarded, not degraded" and "degrades; it does not
  throw" are each two-sided. Keep both halves. The firing budget is per
  event per boundary; the localization budget is per frame. Keep both
  scopes in every sentence that names either.

**E: §10.7** (5684–5792).
- Already close to the target style. Three labels may serve a returning
  reader: "The invariant and the wall-clock map", "The wait",
  "Diagnostics". Use them if they help.
- F11. F12 stays as written: §10.7 names the coarse phase's primitive, and
  §12.2's contrary framing is fixed outside this rewrite.
- D-268 and D-269 disagree on where the loop checks the pause flag. Keep
  §10.7's statement as written and list it in `rulings.md`.
