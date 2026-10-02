# Rewriting a spec chapter for readability: the recipe

This is the living recipe for rewriting a chapter of `docs/design/spec.md`
for readability with no loss of content. It began as chapter 9's report,
`docs/reports/20261001_chapter9_rewrite/report.md`, which stays frozen as
that run's evidence. This copy changes: each chapter adds its lessons here,
next to the step they changed, before its directory is deleted.

The convention the rewrite writes to is `docs/design/tools/spec_style.md`,
"Marking rulings" and the rest. Briefs cite it and never restate it.

## 1. Setting up a chapter

- **Create `chNN/`** with the two-digit chapter number, and in it
  `chapter.sh`, for example:

  ```zsh
  NUM=10                  # the chapter number
  BASE=6ff502c            # the commit the rewrite starts from
  RANGE=4689,5792         # the chapter's lines in spec.md at BASE
  UNITS=(A B C)           # unit names in reading order, once cut
  EXTRA=()                # files the PDF appends, as text moved to a companion
  ```

- **The tools in `checks/` take the chapter directory.** Run them from
  `docs/spec_rewrite`:

  ```
  python3 checks/check_unit.py ch10 check A # a unit against its original
  python3 checks/boldcheck.py ch10 A        # a bold-only edit
  checks/assemble.sh ch10                   # chapter_new.md and chapter_old.md
  checks/build_pdf.sh ch10                  # chapter.pdf, untracked
  ```

  `check_unit.py ... show-old` and `show-new` print a unit's normalized
  texts. `checks/verify_prompt.md` is the step 4 prompt.
- **Mark the chapter in progress** in `README.md`.

## 2. The recipe

Each step names its agent, model, inputs and outputs. Opus does every step
that writes or judges text. The orchestrator is the main session: it reads
every report, checks key claims at the cited lines, routes fixes, and keeps
rulings away from agents.

**The orchestrator rules, from chapter 10 on.** The owner delegated every
decision of a chapter's rewrite to it on 2026-10-02. The four checkpoints
below are the orchestrator's, and it records each ruling with its reason in
the chapter's files, so the owner can audit any of them.

Serious findings are the exception. A finding is serious when it shows a
defect or inconsistency in the design itself, not in its prose: two sources
the spec treats as authoritative contradict each other and no Position
settles which is right; a fix would change what the framework does; or the
design looks wrong. The orchestrator never rules on these. The text stays as
written, the finding goes to `escalations.md` with its evidence and a
recommendation, and the owner gets the list when the chapter closes.

### Step 1: survey (one Opus agent, read-only)

The survey maps the chapter before anyone writes. Chapter 9's
`survey.md` is the model output. Ask for:

- per section, every rule with its line, its marking, and the decision entry
  whose Position rules it, classified as cited, uncited, superseded,
  Rationale-only or no entry;
- overlaps inside the chapter and with other chapters;
- a proposed structure: moves, merges, order within each section, with no
  renumbering unless it pays for its citations;
- every inbound citation of the chapter, to `inbound.tsv`, and analysis of
  the ones that rely on content a move would take;
- the log repairs the rewrite needs, and factual problems found in passing;
- a difficulty estimate per section, with warnings for the rewriter;
- per section, the Appendix C kinds cited to it, and whether the section
  names each where it states the kind's condition. Chapter 8 named five
  kinds in four late rounds (R14, P46, P48, K2) that one survey line would
  have ruled at checkpoint 1.
- every code block the package can run, run against it. Chapter 7's survey
  ran §7.3's PRNG example and found that it failed its own conformance
  check. No reading had caught it.

A survey whose report is long writes it in parts, one append per section:
one response over the output limit kills the agent and loses the report.

Then check its key claims yourself, at the cited lines, before ruling on
them. In chapter 9, six of six held, and in chapter 10, eleven of eleven.
In chapter 8 the claims held, but a correction did not: see checkpoint 1.

**Checkpoint 1: the orchestrator rules on the survey's decisions.** In
chapter 9 the owner ruled them: where the `Deployment` lives; which block is
frozen pending another ruling; how much log repair rides with the rewrite
(answer: none, it is a second track); how many sentences get bold (answer:
one per ruling). The last two hold for every chapter. Record the rulings at
the top of `brief.md`.

Two lessons from chapter 8's checkpoint:

- **A correction restored from git history is checked against the entries
  ratified after the change.** Chapter 8's R8 restored a sentence a move had
  inverted, on the commit's evidence. Unit A's verifier found D-267, ratified
  two days after the move, agreeing with the inverted text. R8 was withdrawn
  and the conflict escalated.
- **A wording correction is ruled for every instance in the chapter.** The
  survey found F22's overstatement at two lines; a rewriter found a third,
  which cost a ruling (R13) after step 4. Grep the chapter for the phrase
  before writing the ruling.

### Step 2: the brief (written by the orchestrator)

Chapter 9's `brief.md` is the model, read with the corrections below. One
brief serves every unit; the prompt names the unit. It holds:

- what to read first: `spec_style.md`, a finished chapter as the example,
  and the survey's parts for the unit;
- every ruling of checkpoint 1;
- what may not change, and that factual problems stay as written and go to
  `rulings.md`;
- the outputs: `new.md`, `inventory.json`, `rulings.md` with fixed headings;
- the units: their line ranges, their moves, their hazards.

**Cut units by content, not by section.** A unit is a range of original lines
plus the blocks that move into it. In chapter 9, A2 was §9.2 plus §9.1's
`Deployment` and warnings blocks. Then every move is inside one unit, and its
inventory can follow each claim. A claim another unit keeps is mapped to that
unit's `old.md`, which its own inventory guarantees.

**The brief must also say**, because chapter 9's brief did not:

- Check every proposed subheading order for define-before-use. Chapter 9's
  came from the survey's labels and put "Rendering" before the `Schedule` it
  renders.
- One glossary link per term per section, at first use, not every link the
  old text had.
- With bold on the headline clause, the citation follows anywhere in the
  same sentence, not within some number of characters.
- Introduce reader-cold names, from the start.
- Every scratch file goes in the agent's own unit directory. Two agents
  sharing the scratchpad collided.

**From chapter 10, the brief should also:**

- Rule the clear factual corrections at checkpoint 1, with their evidence,
  instead of leaving them for step 6. Chapter 10's R8 settled eight of them
  before anyone wrote, and no unit needed a second pass for them.
- Say that a gloss or an introducing clause claims nothing beyond the source
  it names. Chapter 10's rewriters invented a demo's file and aircraft, and
  gave "periodic avionics" a modeling claim; the verifiers caught each one.
- Give the reading of the one-bold test for old entries: semicolons separate
  rulings, and "+" or a comma list joins clauses of one ruling. Tell each
  rewriter to grep its siblings' `new.md` for bolds on the same entry. Chapter
  10 had five rulings bold twice across units.

**From chapter 7, the brief should also:**

- Hold its own dictated wording to lesson 14. Two of chapter 7's rulings
  overclaimed: a context sentence said every step of §7.4 addressed one
  problem, and an introducing clause called `get_x_ss` FlightCore's when
  FlightPhysics and FlightApps own it. Check a Flight.jl name's owner in the
  Flight.jl source before ruling its clause.
- List the words the glossary reserves ("Bare 'tier' means only this").
  Chapter 7's rewriters used "tiers" for the genericity classes and for
  §7.5's budgets; only the chapter pass caught both.

### Step 3: rewrite the units in parallel (one Opus agent per unit)

Prompt: read `brief.md`, follow it, edit nothing outside `units/<U>/`, run
`python3 checks/check_unit.py chNN check <U>` until it prints
`checks failed: 0`.

The checker proves, per unit:

- the old spans cover every word of `old.md`;
- each new span exists where the inventory says, in this unit or another
  file;
- each claim's citations sit in the same paragraph, bullet or table;
- every word of `new.md` traces to a claim or a declared addition;
- every bold span has a D-citation in its sentence.

It cannot see meaning. That is step 4's job.

### Step 4: verify each unit blind (one Opus agent per unit)

Prompt: `checks/verify_prompt.md` with the chapter directory and the unit's
name, plus notes on its known hazards. Phase 1 lists the new text's
assertions before reading anything else. Phase 2 classifies every old claim
as MATCH, DRIFT or LOST and lists ADDED.

Route each fix list back to the **same rewriter**, then the fixes back to the
**same verifier** for a re-check. Never skip the re-check. In chapter 9,
fixes broke something new three times: a cause clause fell off in a pointer,
a citation's scope shrank, an "its" changed antecedent.

What chapter 9's verifiers caught that the checker could not:

- a dropped "because" and a dropped scope clause after a sentence split;
- a citation left covering half its sentence;
- one ruling bold twice, a consequence in bold, a ruling bold where its home
  is another chapter;
- a factual correction applied silently, which the brief forbids: one
  rewriter replaced "under the lock" with §9.4's "mechanism unspecified";
- citations added for entries whose Position does not carry the claim.

Chapter 10's verifiers also caught an antecedent that moved when a ruled
sentence was inserted between "two epochs" and "this", and a citation pointer
that named one entry for a list whose items two entries reject.

From chapter 8:

- **Start each unit's verifier when its rewriter reports**, not when all
  have. With nine units the rewriters finished over twenty minutes, and the
  first fix rounds ran while the last units were still being written.
- **An inserted gloss or introducing clause is an antecedent hazard.** Four
  of chapter 8's fixes moved an antecedent this way, and only the re-checks
  caught them: an "its" that now read as the newly introduced `Systems`, a
  "there" that read as the `Schedule`, an "it" that read as the wrapper
  types, a "that adjudication" that pointed at the wrong section.
- **Inventories map into sibling units**, so after any edit, run every
  unit's checker, not only the edited one's. Moving a link in B1 broke a span
  B4 mapped into B1's text, and only the final verifier ran B4 again.

### Step 5: read the whole chapter (two Opus agents in parallel)

Run `checks/assemble.sh chNN` first.

- **The chapter pass** reads `chapter_new.md` whole for what no unit check
  sees: one name for one thing, one gloss per term, duplicated facts after
  the moves, pointers aimed at the wrong section, bold weight, the opening's
  roadmap, reader-cold names, and anything worse than the old text.
- **The inbound check** judges every row of `inbound.tsv` against the new
  chapter: OK, RETARGET, COMPANION, MISSING, VAGUE. A MISSING row the old
  chapter stated is a loss. Chapter 9 had none. Chapter 10's one LOSS was a
  circular pointer: a cut list pointed at D-154, whose Rejected item pointed
  back at the section. Before cutting a list to a pointer, check that the
  entry does not point back.

An editorial fixer (Opus) then applies the chapter pass's wording, placement,
link and wrap fixes through each unit's inventory, and lists the rest.

### Step 6: rulings (one Opus consolidator, then the owner)

The consolidator merges every `rulings.md`, the verifiers' leftovers, the
chapter pass's ruling items, the inbound check and the survey's log and
out-of-chapter parts into `rulings_batch.md`: deduplicated, sourced, each item
with a proposal and a recommendation, blocking items first.

**Checkpoints 2 and 3: the orchestrator rules.** Take the blocking items
first. Check each proposal's evidence at its source before accepting it, and
record every ruling and its reason as the item's status in
`rulings_batch.md`. Serious items go to `escalations.md` unruled. In
chapter 9, the owner ruled 103 items in two sittings.

Apply the rulings with agents partitioned by unit, so no two edit one file.
Every ruled edit carries its ruling id in the inventory. A bold-only edit
copies `new.md` to `new_pretrim.md` first, for `boldcheck.py`.

**Step 6b: the final verifier.** One cold Opus agent checks every edit made
since step 4, against its log and its source: editorial fixes, bold trims,
ruled edits, orchestrator touches. In chapter 9 it checked 164 edits and
found seven problems, one of them a change of meaning. Fix, then re-check.
Give it the commit that holds the chapter as verified per unit, so it can
diff the two versions hunk by hunk; in chapter 8 it checked 75 hunks and
found two unlogged rewraps, two duplicated glossary links, a citation left
off a split sentence and a broken sibling span. In chapter 7 its one finding
was the orchestrator's own: a scripted replace joined two source lines. Log
every orchestrator touch, and rewrap after any scripted edit.

### Step 7: land (the orchestrator)

**Checkpoint 4: the orchestrator approves landing.** Run
`checks/build_pdf.sh chNN` and read the PDF first: tables and links are where
an excerpt fails. Then, in this order:

1. Edit inbound citations outside the chapter first, while their line numbers
   still match the inbound check's.
2. Splice the assembled chapter over its line range, and fix the Contents
   entry for any retitled section.
3. Add the new log entries before the link-definition block, and update the
   Spec fields the moves changed, in place, keeping each field's own order.
4. Apply the companion additions and any other file edits the rulings name.
5. Add the chapter to `REWRITTEN` in `docs/design/tools/check_bold.jl`.
6. Run `linkify.jl`, then the battery `spec_style.md` lists, and
   `linkify.jl` again as a no-op.
7. Rebuild `design.pdf`, and commit in reviewable pieces.

Other sessions may edit the spec while a chapter is in flight. Recount the
range against `BASE` before splicing, and carry their hunks, never revert
them. Tell any session working on the spec when the chapter is in flight and
when it lands; chapter 10 coordinated with one that way.

- `RANGE` ends on the blank line after the chapter's closing `---`. The
  splice keeps that blank line.
- When a cut removes the only spec citation of a superseded entry,
  `check_rows.jl` reports that coverage shrank. Rebaseline it with
  `--rebaseline`, since the style forbids citing a superseded entry.
- The PDF read can go to a Sonnet agent. Check by script that every fenced
  block is byte-identical to the original first; then a long line or a page
  split in a code block is layout, not damage.
- The Read tool renders PDF pages only with `pdftoppm` (poppler), which this
  machine lacks. Without it the PDF read runs on extracted text, which finds
  raw markup, broken tables and lost numbering but not spacing or page
  layout. Chapter 8's read ran that way.

### Step 8: the second track

After landing, the orchestrator rules and applies what the rewrite surfaced
but did not need, serious findings excepted:
entries that state Rationale-only rulings in a Position, annotations of stale
Positions, Spec fields stale before the rewrite, and problems outside the
chapter. A new entry restates only what an existing entry already records.
A spec sentence with no entry behind it stays uncited and goes to the owner,
since ratifying it would be a design decision. Then cite the new entries
beside their source entries in the chapter. Track 2 is
where the log catches up with the spec; keeping it out of the rewrite kept
each rewriter's job to prose.

### Step 9: close the chapter

1. Add this chapter's lessons to this recipe, at the step each changed, and
   to section 5.
2. Record the chapter's landing commit in `README.md`.
3. Delete `chNN/` in a commit of its own, and record that commit's parent in
   `README.md` as the last one holding the files. Move `escalations.md` out
   first, into `docs/design/pending.md` as one bullet per finding the owner
   has not ruled. A shape `src/` has and the spec lacks goes under
   "Deviations"; a design question goes beside the item it belongs to, as
   chapter 8's semantic axis joined the exported-name audit.
4. Report to the owner: the commits, and `escalations.md` with a
   recommendation per finding.

## 3. Cost and time

Chapter 9, 8,544 words:

| step | agent runs | subagent tokens |
|---|---|---|
| survey | 1 | 0.26M |
| rewrites | 6, plus fix rounds | 0.97M |
| unit verification | 6, plus re-checks | 0.54M |
| chapter pass, inbound check, editorial fixer | 3 | 0.52M |
| consolidation | 1 | 0.22M |
| trim, rulings, bold de-duplication | 4 | 0.50M |
| final verification and fixes | 2 | 0.28M |
| total | about 35 | about 3.3M |

The rewrites ran in about 8 to 13 minutes each in parallel. The whole chapter
took one long session, most of it spent at the four checkpoints. Expect
roughly 0.4M subagent tokens per 1,000 words of chapter.

Chapter 10, 9,369 words, ruled by the orchestrator:

| step | agent runs | subagent tokens |
|---|---|---|
| survey | 1 | 0.32M |
| rewrites | 7, plus fix rounds | 1.2M |
| unit verification | 7, plus re-checks | 0.8M |
| chapter pass, inbound check, editorial fixer | 3 | 0.56M |
| consolidation and ruled edits | 2 | 0.38M |
| final verification and PDF check | 2 | 0.22M |
| track 2 and its verification | 2 | 0.35M |
| total | about 30 | about 3.8M |

With no owner checkpoints, the whole chapter, track 2 included, ran in one
session of about three hours.

Chapter 8, 12,392 words, ruled by the orchestrator:

| step | agent runs | subagent tokens |
|---|---|---|
| survey | 1 | 0.49M |
| rewrites | 9, plus fix rounds | 1.74M |
| unit verification | 9, plus re-checks | 1.07M |
| chapter pass, inbound check, editorial fixer | 3 | 0.72M |
| consolidation and ruled edits | 2 | 0.36M |
| final verification and PDF check | 2 | 0.19M |
| track 2 and its verification | 2 | 0.38M |
| total | 28, plus fix rounds | about 4.9M |

The chapter, track 2 included, ran in one session of about two and a half
hours. The cost per 1,000 words held at about 0.4M.

Chapter 7, 3,252 words, ruled by the orchestrator:

| step | agent runs | subagent tokens |
|---|---|---|
| survey | 1 | 0.43M |
| rewrites | 4, plus fix rounds | 0.64M |
| unit verification | 4, plus re-checks | 0.38M |
| chapter pass, inbound check, editorial fixer | 3 | 0.49M |
| consolidation | 1 | 0.16M |
| final verification and PDF check | 2 | 0.16M |
| track 2 and its verification | 2 | 0.29M |
| total | 17, plus fix rounds | about 2.6M |

The chapter, track 2 included, ran in one session of about an hour and a
half. A small chapter costs more per word, about 0.8M per 1,000 words: the
survey, the chapter-wide passes and track 2 cost nearly as much as for a
chapter three times its size.

## 4. What to expect from a chapter

From chapter 9:

- **About half the rule sentences become bold.** The survey counted 156 rule
  sentences; one bold per ruling left 71.
- **About one rule in seven lives only in a Rationale.** There, 22 of 156.
  Each becomes a track-2 entry.
- **Half the rules cite nothing at their spot.** There, 58 of 156 were ruled
  by an entry the section did not cite. The rewrite adds the citations.
- **Factual problems are found, not made.** There, 19 inside the chapter,
  all pre-existing, among them three places where the spec still named the
  `Simulation` for what D-254 moved to the `Deployment`.
- **Moves cost citations.** One section's worth of moved content retargeted
  31 inbound citations. The inbound check finds every one.
- **Bold weight is measured in words.** The span count stayed level, 81
  before and 71 after, while bold words doubled from 403 to 877, until the
  headline-clause trim and the de-duplication brought them to 595.

From chapter 8, which held 213 rules:

- **One rule in five lived only in a Rationale**, 43 of 213, and seven had
  no entry at all. Track 2 wrote five entries for them, D-295 to D-299.
- **Two in five cited nothing at their spot**, 83 of 213.
- **Moves inside a section cost no citations.** Every move stayed within
  its section, and the 450 inbound rows needed no retarget; 23 were already
  wrong before the rewrite.
- **The chapter grew about a tenth**, from 12,392 words to about 13,750,
  with 67 bold spans of 632 words.

From chapter 7, which held 79 rules:

- **One rule in four lived only outside a Position**, 20 of 79, and two had
  no entry. Track 2 wrote three entries, D-304 to D-306.
- **Two entries ruled whole sections and were cited nowhere**: D-010 for
  §7.1 and D-014 for §7.5. Neither had a Spec field.
- **Seventeen outside citations read a scope §7.5 never stated.** Two
  sentences added from recorded sources turned ten of those rows from
  wrong to right.
- **The chapter grew about a sixth**, from 3,252 words to about 3,840, and
  bold fell from 42 spans and 8 labels to 12 spans of 119 words.

## 5. Lessons, in one list

1. Survey first, and rule on its decisions before writing. Moves settled
   later cost rework.
2. Rewrite incrementally from the source, never from a paraphrase (the §9.4
   trial, `docs/reports/20261001_spec_rewrite_sample/`).
3. Cut units by content; map claims another unit keeps to its `old.md`.
4. One brief, checked for define-before-use and against `spec_style.md`.
5. Scratch files in the agent's own unit directory.
6. Every fix goes back to the verifier that found the problem.
7. Factual problems stay as written until ruled; verifiers flag silent fixes.
8. Bold: headline clause, one per Position sentence or bullet, weight in
   words.
9. Two tracks: prose now, log repairs after landing.
10. The orchestrator checks agents' key claims at the cited lines. Chapter
    9's final verifier once called two unruled items accepted, and its
    rulings batch proposed a gloss ("a GNSS receiver") that no source
    supports.
11. Land outside edits by line first, then splice.
12. The PDF is a check too: tables and links are where the excerpt fails.
13. Rule clear factual corrections before writing (chapter 10).
14. A gloss claims nothing beyond its named source; verifiers check each one.
15. Check bold across sibling units, not only within one.
16. A pointer to an entry must not lead to an entry that points back.
17. New log entries restate recorded rulings only; unrecorded ones go to the
    owner.
18. Check a correction from history against later entries before ruling it
    (chapter 8).
19. Rule a wording correction for every instance; grep before the brief.
20. Survey the Appendix C kinds each section must name.
21. Verify each unit as soon as it is written.
22. Every inserted clause is an antecedent hazard; re-check after each fix.
23. After any unit edit, run every unit's checker.
24. Run the chapter's code blocks against the package in the survey
    (chapter 7).
25. The brief's own wording is held to lesson 14, and a Flight.jl name's
    owner is checked in the Flight.jl source.
26. List the glossary's reserved words in the brief.
27. Log every orchestrator touch, and rewrap after a scripted edit.

## 6. A chapter's files

- `chapter.sh`: section 1.
- `survey.md`, `inbound.tsv`: step 1.
- `brief.md`: step 2.
- `units/<U>/`: per unit, `old.md`, `new.md`, `inventory.json`, `rulings.md`,
  `verify_phase1.md`, `verify.md`, and any text that leaves the chapter,
  such as `companion_addition.md`.
- `chapter_pass.md`, `inbound_check.md`, `inbound_check.tsv`,
  `chapter_rulings.md`, `chapter_fixes.md`: step 5.
- `rulings_batch.md`: step 6, with each item's status.
- `escalations.md`: serious findings from any step, for the owner.
- `trim_log.md`, `ruled_edits.md`, `rulings_applied_*.md`,
  `final_verify.md`: steps 6 and 6b.
- `pdf_check.md`: step 7.
- `backlog_applied_*.md`, `backlog_verify.md`: step 8.
- `chapter_old.md`, `chapter_new.md`: the chapter before and after, from
  `checks/assemble.sh`.
