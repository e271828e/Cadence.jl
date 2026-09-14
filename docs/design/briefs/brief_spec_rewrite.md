# The spec rewrite — plain register, style only

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`. Drafted
2026-09-14 after the pilot of §10.4 and §10.6 (`spec_rewrite_pilot.md`, this
directory). Status: **draft, awaiting review**. Nothing here has started.

## 1. Goal and non-goals

**Goal.** Rewrite the prose of `docs/design/spec.md` into the register of
`~/.claude/CLAUDE.md`'s Language section, so that a human reader can follow
it. Every normative claim, citation, glossary link, code sketch and heading
number survives unchanged. The pilot is the exemplar of the target register.

**Non-goals.**

- No normative change. Where a sentence resists rewriting because its meaning
  is unclear, that is a finding to report, never something to guess at
  (`tools/spec_style.md`, "Content preservation").
- No renumbering, reordering or merging of sections. Heading *text* may
  change; heading *numbers* and their order may not.
- No rewrite of `decisions.md` (67k words in the same voice), the companions,
  or the code. They are touched only where §5 below says a quote must be
  re-pointed.
- No wrapping tool. Rewritten paragraphs are written wrapped at 80 rendered
  columns from the start, per the style guide.

## 2. The register

The four moves that account for most of the pilot's difference, applied
throughout:

1. **Aphoristic lead-ins become plain claims.** "Two words carry the section,
   and they are not synonyms" → "Two terms recur throughout, and they mean
   different things." A bold lead-in states its paragraph's content.
2. **Dash and colon chains become sentence sequences.** One burden per
   sentence. No em-dashes; at most one parenthetical, used for a gloss.
3. **Nominalizations and metaphors are unwound.** "It pays for itself twice
   over" → "The evaluation serves two purposes." "Orthodoxy concurs" →
   "Established practice agrees."
4. **Implicit subjects are made explicit.** Name who does what: "The frame
   falls through, and the boundary iteration detects and fires the event."

Everything `spec_style.md` already fixes stays in force: `Rule.` / `Why.`
markers, first-use gloss + glossary link per section, section template,
reference-style citations, constructive rationale in, adversarial rationale
out. Word count is allowed to stay flat or grow slightly; the pilot ran
+4%.

**Step 0, docs-commit-first.** Fold the Language rules into
`tools/spec_style.md` under "Sentences" before the first section is touched,
so every later edit by anyone is held to the same register. One small commit.

## 3. Unit of work and order

- **One `###` section per edit**, in place, on the file. The spec is ~190k
  tokens; it is never read whole.
- **One commit per `##` chapter**, single-sentence subject, e.g. "Rewrite
  §10 into the plain register". Chapters 5, 8, 10, 11 and 14 are large
  enough to split into two commits at a `###` boundary if the diff review
  wants it.
- **One session per Part**, to keep context carry from inflating cost.
- **Order**: Part I → II → III → IV → V, then the appendices. Appendix A–C
  are tables and index prose, light touch. Appendix D's glossary entries are
  prose and get the register, but every entry's bold term text is a matching
  key for `check_glossary.jl` and must stay verbatim.
- The pilot lands first, as chapter 10's first commit, once §6 below is
  settled.

## 4. Per-section checklist

Run in this order for every `###` section. Steps 1, 3, 4 and 5 are
mechanical and can go to a Sonnet subagent; steps 2 and 7 are the main
session's.

1. **Claim inventory, before.** Extract the section's normative sentences:
   every `**Rule.**` paragraph, every "must / never / iff / is rejected /
   is an error" sentence, every default value and keyword name. Save to the
   scratchpad as `claims_<section>.md`.
2. **Rewrite in place.** Wrapped at 80 rendered columns.
3. **Link-set diff.** The three sets (`[sN-M]` labels, `[d-nnn]` labels,
   `#g-…` anchors) of the section before and after must be identical. The
   pilot's one-liner does this; §7 proposes promoting it to a tool.
4. **Gloss check.** Every class-A term in `tools/gloss_table.md` whose first
   use in this section carries a gloss keeps that gloss text, or the table
   row is updated in the same commit.
5. **Orphan grep.** Grep the section's phrases listed in §5 across
   `decisions.md`, `extensions.md`, `companions/`, `src/`. Re-point or record
   per the table's action column.
6. **Battery**: `check_refs.jl`, `check_rows.jl`, `check_glossary.jl
   --strict`, `linkify.jl` as a no-op.
7. **Claim inventory, after.** Every claim from step 1 is found in the new
   text with the same force. A claim that changed force, or a sentence whose
   meaning was unclear, goes into the chapter's findings list.

Per Part, once its chapters are committed: one independent **Opus cold
reviewer** over the Part's diff, stance "meaning preserved?", probing with
the saved claim inventories. I adjudicate, a fixer lands one commit, the
user diff-reviews the Part, push. Same pipeline as an increment.

## 5. What can orphan, and what cannot

**Safe without action** (measured 2026-09-14):

- Cross-file section citations: 100 distinct spec headings cited from other
  design files, 1,958 `§` citations in `src/` and `test/`. All resolve by
  number through `linkify.jl`; heading text may change.
- The 110 `####` headings: unnumbered and linked from nowhere. Free to
  retitle.
- Glossary anchors: no file outside the spec links to a `#g-` anchor.
- `prototypes/`: section numbers only, hand-verified in their headers.
- The PDF build: pandoc over the two files, no text dependency.

**Tracked per section:**

- Decision-citation coverage (`tools/row_baseline.txt`): the link-set diff
  guards it.
- First-use glosses (`tools/gloss_table.md`): step 4. Its per-anchor link
  counts are advisory; recount once at the end.
- Verbatim quotes of spec prose elsewhere, found by exact match. This table
  is the floor: paraphrases are invisible to the sweep, which is why step 5
  greps phrases rather than trusting the list.

| where | line | quote | action |
|---|---|---|---|
| decisions.md | 3516 | "one authoring contract, no taxonomy" | §11.6 title; keep if the title stays |
| decisions.md | 3799 | "the one initialized datum without declared defaults" | re-point on §14 |
| decisions.md | 4091 | "rate-limited wherever its source can repeat" | re-point on §11 |
| decisions.md | 4737 | "structure kept in two artifacts" | re-point on §9 |
| decisions.md | 5592 | "if `F` participates in differentiation, declare it `T`" | re-point on §7.2 |
| decisions.md | 7466 | "gated off holding `Float64` values" | re-point on §9 |
| decisions.md | — | sentence "A name in the wrong register is a rename candidate on that ground alone." | re-point on §8 |
| companions/inbound_periphery_walkthrough.md | 106 | "claimed by `T16000M` — task dead" | re-point on §11.3 |
| companions/sample_time_proposal.md | 409 | "at boundary zero everything is due" | re-point on §10.5 |
| companions/sample_time_proposal.md | 732 | "grid is N× finer than the fastest declared work" | re-point on §10.5 |
| companions/sample_time_proposal.md | — | sentence "Absolute pinning *from outside* a subtree's contract stays rejected as action at a distance." | re-point on §10.5 |
| briefs/brief_increment_25_api_names.md | 175 | "declaration by allocation, never by initial value" | frozen artifact; leave |
| briefs/brief_increment_32b_exact_relation.md | 16 | "Contract signature shape follows the class" | frozen; leave |
| briefs/brief_increment_23.md | 223, 277 | two phrases | frozen; leave |
| tools/coinage_inventory.md | 18 | "stage function / two-stage outputs" | glossary term text; must stay verbatim |
| src/assembly.jl | 15 | docstring fragment | cosmetic; re-point on §8.5 or leave |
| src/diagnostics.jl | 320, 660 | two docstring fragments | cosmetic; re-point on §13 or leave |
| src/trim.jl | 152 | "the tolerances *are* the stopping criterion" | cosmetic; re-point on §14.8 or leave |
| src/sim.jl | 3 | "advance the continuous state from `t` by `h`" | cosmetic; leave |
| src/build.jl | 954 | "fresh run from the `init_*` defaults, with these overrides" | cosmetic; re-point on §14 or leave |

"Re-point" means: update the quote to the new wording in the same commit as
the section, or, in the log, leave the historical quote and add nothing.
The user decides which per the log's "log lags spec" doctrine; the default
proposed here is **update companions, leave the log and the briefs**.

## 6. Open questions from the pilot

Three places where the pilot changed more than style. Settle before the
pilot lands:

1. §10.6 called the epoch rule "the whole of this section's content". The
   pilot says "the core of this section". Keep the softer claim, or revert?
2. §10.6 "Blocking is register-visible" became "Blocking is visible in the
   registers". Confirm "register" means the three per-event registers.
3. §10.4 "The ZOH clause below already forces that ordering" names no
   clause. The pilot kept it. Proposed: name the paragraph, "Trial
   evaluations run the interior sweep".

Also noted, not changed: `[localization budget](#g-chattering)` links the
budget to the chattering entry. Intentional?

## 7. Tooling proposed

- `tools/check_linkset.jl` (or a shell one-liner in `spec_style.md`): given
  a line range and a saved baseline, diff the three link sets. Joins the
  battery for the duration of the rewrite. Small; Sonnet can write it.
- The claim-inventory files stay in the scratchpad per session and are
  quoted in the chapter's report; they are not committed.

## 8. Cost

Measured on the pilot: ~95k tokens for 4.6k source words, ~20 tokens per
word, including orientation reading and the link-set check.

| Part | words | rewrite |
|---|---|---|
| I Foundations | 13k | 0.26M |
| II Authoring and build | 17k | 0.34M |
| III Execution | 28k | 0.57M |
| IV Failure and services | 17k | 0.34M |
| V Grounding | 7k | 0.14M |
| Appendices | 16k | ~0.15M, light touch |
| total | 99k | ~1.8M |

Verification (inventories, cold review per Part, fixes) adds a third to a
half: **2.5–3M tokens all in**, spread over six sessions.

## 9. Report format, per Part

- Chapters committed, with hashes.
- Findings list: sentences whose meaning was unclear, claims whose force
  changed, quotes re-pointed and quotes left.
- Battery output, verbatim.
- Cold reviewer's verdict and the fixer commit, if any.
