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
- a difficulty estimate per section, with warnings for the rewriter.

A survey whose report is long writes it in parts, one append per section:
one response over the output limit kills the agent and loses the report.

Then check its key claims yourself, at the cited lines, before the owner sees
them. In chapter 9, six of six held.

**Checkpoint 1: the owner rules on the survey's decisions.** In chapter 9
they were: where the `Deployment` lives; which block is frozen pending
another ruling; how much log repair rides with the rewrite (answer: none, it
is a second track); how many sentences get bold (answer: one per ruling).

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

### Step 5: read the whole chapter (two Opus agents in parallel)

Run `checks/assemble.sh chNN` first.

- **The chapter pass** reads `chapter_new.md` whole for what no unit check
  sees: one name for one thing, one gloss per term, duplicated facts after
  the moves, pointers aimed at the wrong section, bold weight, the opening's
  roadmap, reader-cold names, and anything worse than the old text.
- **The inbound check** judges every row of `inbound.tsv` against the new
  chapter: OK, RETARGET, COMPANION, MISSING, VAGUE. A MISSING row the old
  chapter stated is a loss. Chapter 9 had none.

An editorial fixer (Opus) then applies the chapter pass's wording, placement,
link and wrap fixes through each unit's inventory, and lists the rest.

### Step 6: rulings (one Opus consolidator, then the owner)

The consolidator merges every `rulings.md`, the verifiers' leftovers, the
chapter pass's ruling items, the inbound check and the survey's log and
out-of-chapter parts into `rulings_batch.md`: deduplicated, sourced, each item
with a proposal and a recommendation, blocking items first.

**Checkpoints 2 and 3: the owner rules.** Bring the blocking items first, the
ones marked "discuss" with a recommendation each, and the rest as one
decision. In chapter 9, 103 items became two sittings.

Apply the rulings with agents partitioned by unit, so no two edit one file.
Every ruled edit carries its ruling id in the inventory. A bold-only edit
copies `new.md` to `new_pretrim.md` first, for `boldcheck.py`.

**Step 6b: the final verifier.** One cold Opus agent checks every edit made
since step 4, against its log and its source: editorial fixes, bold trims,
ruled edits, orchestrator touches. In chapter 9 it checked 164 edits and
found seven problems, one of them a change of meaning. Fix, then re-check.

### Step 7: land (the orchestrator)

**Checkpoint 4: the owner approves landing.** Run `checks/build_pdf.sh chNN`
and read the PDF first: tables and links are where an excerpt fails. Then,
in this order:

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
them.

### Step 8: the second track

After landing, rule and apply what the rewrite surfaced but did not need:
entries that state Rationale-only rulings in a Position, annotations of stale
Positions, Spec fields stale before the rewrite, and problems outside the
chapter. Then move the chapter's citations to the new entries. Track 2 is
where the log catches up with the spec; keeping it out of the rewrite kept
each rewriter's job to prose.

### Step 9: close the chapter

1. Add this chapter's lessons to this recipe, at the step each changed, and
   to section 5.
2. Record the chapter's landing commit in `README.md`.
3. Delete `chNN/` in a commit of its own, and record that commit's parent in
   `README.md` as the last one holding the files.

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

## 6. A chapter's files

- `chapter.sh`: section 1.
- `survey.md`, `inbound.tsv`: step 1.
- `brief.md`: step 2.
- `units/<U>/`: per unit, `old.md`, `new.md`, `inventory.json`, `rulings.md`,
  `verify_phase1.md`, `verify.md`, and any text that leaves the chapter,
  such as `companion_addition.md`.
- `chapter_pass.md`, `inbound_check.md`, `inbound_check.tsv`,
  `chapter_fixes.md`: step 5.
- `rulings_batch.md`: step 6, with each item's status.
- `trim_log.md`, `ruled_edits.md`, `rulings_applied_*.md`,
  `final_verify.md`: steps 6 and 6b.
- `backlog_applied_*.md`, `backlog_verify.md`: step 8.
- `chapter_old.md`, `chapter_new.md`: the chapter before and after, from
  `checks/assemble.sh`.
