# Rewriting a spec chapter for readability: the recipe — 2026-10-01

## What this is

Chapter 9 of `spec.md`, "The build pipeline", was rewritten for readability
with no loss of content and landed in `9a7d84f`. It was the first full chapter,
after a single-section trial on §9.4
(`docs/reports/20261001_spec_rewrite_sample/`). This report turns the run into
a recipe for the remaining chapters. Follow it as written, and the lessons of
this run need not be learned again. Each lesson sits next to the step it
changed, and section 6 lists them all.

The outcome, by the numbers:

- The chapter went from 8,544 words to about 9,200. Content moved out (the
  Flight.jl comparisons) and in (corrections the log required, such as the
  shadowing check and `show(::Events)`).
- 156 rule sentences became 71 bold rulings, each ending with the decision
  entry that rules it.
- Six units, 608 claims, each verified blind against its original.
- 389 inbound citations checked. None lost its fact; 31 were retargeted.
- Three new log entries (D-280 to D-282), eleven Spec fields updated.
- About 35 agent runs and 3.3M subagent tokens, over four owner checkpoints.

## 1. Before the first chapter of a batch

Do these once, not per chapter.

- **The convention lives in `tools/spec_style.md`.** Section 3 below is its
  final form. Until it is written there, put it in the brief verbatim.
- **Copy `checks/` into the new chapter's report directory.** The tools are
  generic: `check9.py` checks any unit, `boldcheck.py` any bold-only edit,
  `assemble.sh` and `build_pdf.sh` need only the unit list and the line range
  edited.
- **`design.pdf` must render tables and links.** Both were fixed during this
  run: `tablewidths.lua` floors each column at its longest word (`bc7258b`),
  and `build_pdf.sh` defines every D-entry the excerpt cites that `spec.md`
  does not cite yet.

## 2. The recipe

Each step names its agent, model, inputs and outputs. Opus does every step
that writes or judges text. The orchestrator is the main session: it reads
every report, checks key claims at the cited lines, routes fixes, and keeps
rulings away from agents.

### Step 1: survey (one Opus agent, read-only)

The survey maps the chapter before anyone writes. Its prompt is in the
session record; `survey.md` here is the model output. Ask for:

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

Then check its key claims yourself, at the cited lines, before the owner sees
them. Here six of six held.

**Checkpoint 1: the owner rules on the survey's decisions.** Here they were:
where the `Deployment` lives; which block is frozen pending another ruling;
how much log repair rides with the rewrite (answer: none, it is a second
track); how many sentences get bold (answer: one per ruling).

### Step 2: the brief (written by the orchestrator)

`brief.md` is the model. One brief serves every unit; the prompt names the
unit. It holds:

- what to read first: the convention, the finished §9.4, the survey's parts
  for the unit, `spec_style.md`;
- the convention, with every ruling of checkpoint 1;
- what may not change, and that factual problems stay as written and go to
  `rulings.md`;
- the outputs: `new.md`, `inventory.json`, `rulings.md` with fixed headings;
- the units: their line ranges, their moves, their hazards.

**Cut units by content, not by section.** A unit is a range of original lines
plus the blocks that move into it. Here A2 was §9.2 plus §9.1's `Deployment`
and warnings blocks. Then every move is inside one unit, and its inventory can
follow each claim. A claim another unit keeps is mapped to that unit's
`old.md`, which its own inventory guarantees.

**What this brief got wrong, and the next one must say instead:**

- The subheading order came from the survey's labels and put "Rendering"
  before the `Schedule` it renders. Check every proposed order for
  define-before-use.
- It said to keep every glossary link the old text had. `spec_style.md` links
  a term once per section, at first use; say that.
- It allowed the citation within 40 characters of the bold. With bold on the
  headline clause, the citation follows anywhere in the same sentence.
- It did not ask for reader-cold names (section 3). Ask from the start.
- It let agents use the shared scratchpad. Two collided. Every scratch file
  goes in the agent's own unit directory.

### Step 3: rewrite the units in parallel (one Opus agent per unit)

Prompt: read `brief.md`, follow it, edit nothing outside `units/<U>/`, run
`python3 checks/check9.py check <U>` until it prints `checks failed: 0`.

The checker proves, per unit:

- the old spans cover every word of `old.md`;
- each new span exists where the inventory says, in this unit or another
  file;
- each claim's citations sit in the same paragraph, bullet or table;
- every word of `new.md` traces to a claim or a declared addition;
- every bold span has a D-citation in its sentence.

It cannot see meaning. That is step 4's job.

### Step 4: verify each unit blind (one Opus agent per unit)

Prompt: `checks/verify_prompt.md` with the unit's name, plus notes on its
known hazards. Phase 1 lists the new text's assertions before reading
anything else. Phase 2 classifies every old claim as MATCH, DRIFT or LOST and
lists ADDED.

Route each fix list back to the **same rewriter**, then the fixes back to the
**same verifier** for a re-check. Never skip the re-check. Here fixes broke
something new three times: a cause clause fell off in a pointer, a citation's
scope shrank, an "its" changed antecedent.

What the verifiers caught that the checker could not:

- a dropped "because" and a dropped scope clause after a sentence split;
- a citation left covering half its sentence;
- one ruling bold twice, a consequence in bold, a ruling bold where its home
  is another chapter;
- a factual correction applied silently, which the brief forbids: one
  rewriter replaced "under the lock" with §9.4's "mechanism unspecified";
- citations added for entries whose Position does not carry the claim.

### Step 5: read the whole chapter (two Opus agents in parallel)

- **The chapter pass** reads `chapter_new.md` whole for what no unit check
  sees: one name for one thing, one gloss per term, duplicated facts after
  the moves, pointers aimed at the wrong section, bold weight, the opening's
  roadmap, reader-cold names, and anything worse than the old text.
- **The inbound check** judges every row of `inbound.tsv` against the new
  chapter: OK, RETARGET, COMPANION, MISSING, VAGUE. A MISSING row the old
  chapter stated is a loss. Here there were none.

An editorial fixer (Opus) then applies the chapter pass's wording, placement,
link and wrap fixes through each unit's inventory, and lists the rest.

### Step 6: rulings (one Opus consolidator, then the owner)

The consolidator merges every `rulings.md`, the verifiers' leftovers, the
chapter pass's ruling items, the inbound check and the survey's log and
out-of-chapter parts into `rulings_batch.md`: deduplicated, sourced, each item
with a proposal and a recommendation, blocking items first.

**Checkpoints 2 and 3: the owner rules.** Bring the blocking items first, the
ones marked "discuss" with a recommendation each, and the rest as one
decision. Here 103 items became two sittings.

Apply the rulings with agents partitioned by unit, so no two edit one file.
Every ruled edit carries its ruling id in the inventory.

**Step 6b: the final verifier.** One cold Opus agent checks every edit made
since step 4, against its log and its source: editorial fixes, bold trims,
ruled edits, orchestrator touches. Here it checked 164 edits and found seven
problems, one of them a change of meaning. Fix, then re-check.

### Step 7: land (the orchestrator)

**Checkpoint 4: the owner approves landing.** Then, in this order:

1. Edit inbound citations outside the chapter first, while their line numbers
   still match the inbound check's.
2. Splice the assembled chapter over its line range, and fix the Contents
   entry for any retitled section.
3. Add the new log entries before the link-definition block, and update the
   Spec fields the moves changed, in place, keeping each field's own order.
4. Apply the companion additions and any other file edits the rulings name.
5. Run `linkify.jl`, then the battery: `check_refs.jl`, `check_rows.jl`,
   `check_glossary.jl --strict`, and `linkify.jl` again as a no-op.
6. Rebuild `design.pdf`, and commit in reviewable pieces.

### Step 8: the second track

After landing, rule and apply what the rewrite surfaced but did not need:
entries that state Rationale-only rulings in a Position, annotations of stale
Positions, Spec fields stale before the rewrite, and problems outside the
chapter. Then move the chapter's citations to the new entries. Track 2 is
where the log catches up with the spec; keeping it out of the rewrite kept
each rewriter's job to prose.

## 3. The convention

This supersedes the trial report's list.

- **No labels.** No **Rule.**, **Why.** or **Example.** A reason follows its
  rule with a plain connective.
- **Bold marks a ruling, once, on its headline clause.** The headline clause
  is the shortest clause that states what is decided, subject and verb
  included. Its D-citation follows in the same sentence. Bold marks nothing
  else: not lead-ins, terms, definitions, consequences, recommendations or
  labels.
- **One bold per ruling, by a mechanical test.** A Position's rulings are its
  sentences and its bullets. In old entries that chain parallel rulings with
  semicolons, each chained ruling counts as a bullet. Clauses that elaborate
  one ruling share one bold. Where two sentences state one ruling, the first
  in reading order keeps the bold.
- **Bold where the section states what the entry decides.** A ruling about
  when a check runs is bold where the run is described, even if the check's
  rule lives in another chapter. Each ruling ends up bold in one place.
- **Cite the entry that rules.** Prefer the Position. If only a Rationale,
  Rejected list or annotation rules it, cite that entry, keep the bold, and
  list the case for track 2. Never cite a superseded entry.
- **A "so" or "by construction" before a rule demotes it.** Put the rule
  first and its reason after.
- **Subheadings only for entry points, as topic labels**, in an order where
  nothing is used before it is defined. A section without them ends its
  context paragraph with one sentence naming its parts in order.
- **Display code** for what a reader would type or copy: a call, a definition,
  a signature. Identifiers stay inline. Quoted diagnostic messages stay
  verbatim.
- **One glossary link per term per section,** at first use, tables included.
- **Reader-cold names get introduced.** Classify each unintroduced name:
  Flight.jl machinery used as if known (move it to a companion, or say what it
  is), an aerospace example (one introducing clause, claiming nothing the
  source does not), or FlightCore named as the predecessor (fine).
- **Sentences** as `spec_style.md` has them: short, active, one point each, no
  em dashes, one parenthetical at most, no mid-sentence colon.

Bold weight is measured in words, not spans. Here the span count stayed level
(81 before, 71 after) while bold words doubled, 403 to 877, until the
headline-clause trim and the de-duplication brought them to 595.

## 4. Cost and time

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

## 5. What to expect from the next chapter

- **About half the rule sentences become bold.** The survey counted 156 rule
  sentences; one bold per ruling left 71.
- **About one rule in seven lives only in a Rationale.** Here 22 of 156. Each
  becomes a track-2 entry.
- **Half the rules cite nothing at their spot.** Here 58 of 156 were ruled by
  an entry the section did not cite. The rewrite adds the citations.
- **Factual problems are found, not made.** Here 19 inside the chapter, all
  pre-existing, among them three places where the spec still named the
  `Simulation` for what D-254 moved to the `Deployment`.
- **Moves cost citations.** One section's worth of moved content retargeted
  31 inbound citations. The inbound check finds every one.

## 6. Lessons, in one list

1. Survey first, and rule on its decisions before writing. Moves settled
   later cost rework.
2. Rewrite incrementally from the source, never from a paraphrase (trial).
3. Cut units by content; map claims another unit keeps to its `old.md`.
4. One brief, checked for define-before-use and against `spec_style.md`.
5. Scratch files in the agent's own unit directory.
6. Every fix goes back to the verifier that found the problem.
7. Factual problems stay as written until ruled; verifiers flag silent fixes.
8. Bold: headline clause, one per Position sentence or bullet, weight in
   words.
9. Two tracks: prose now, log repairs after landing.
10. The orchestrator checks agents' key claims at the cited lines. The final
    verifier once called two unruled items accepted, and the rulings batch
    proposed a gloss ("a GNSS receiver") that no source supports.
11. Land outside edits by line first, then splice.
12. The PDF is a check too: tables and links are where the excerpt fails.

## 7. Files

- `survey.md`, `inbound.tsv`: step 1.
- `brief.md`: step 2.
- `units/<U>/`: per unit, `old.md`, `new.md`, `inventory.json`, `rulings.md`,
  `verify_phase1.md`, `verify.md`. `units/D/companion_addition.md` and
  `units/E/migration_addition.md` hold text that left the chapter.
  `units/S94/` holds §9.4 with its changes from the trial.
- `chapter_pass.md`, `inbound_check.md`, `inbound_check.tsv`,
  `chapter_fixes.md`: step 5.
- `rulings_batch.md`: step 6, with each item's status.
- `trim_log.md`, `ruled_edits.md`, `rulings_applied_A.md`,
  `rulings_applied_B.md`, `final_verify.md`: steps 6 and 6b.
- `backlog_applied_1.md`, `backlog_applied_2.md`: step 8.
- `chapter_old.md`, `chapter_new.md`: the chapter before and after, as
  assembled and landed in `9a7d84f`. The units record that state too. Step 8
  later moved 20 of the chapter's citations to D-282–D-288 in `spec.md` only.
- `backlog_verify.md`: the cold check of step 8's log entries and citations.
- `checks/`: the tools and the verifier prompt.
