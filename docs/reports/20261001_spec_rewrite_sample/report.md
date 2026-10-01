# A readability rewrite of spec §9.4 — 2026-10-01

## Question

Could `spec.md` and `decisions.md` be rewritten to read more easily, with no
loss of content? The trial took one dense, conceptually hard section, §9.4
"Activations: executable sets, laziness, caching", and rewrote it five times.
§9.4 had no context paragraph and packed three rules into three long
paragraphs. The spec text is that of commit `d9b2711`.

The outcome is Version 4, a writing convention for the spec, and a method for
rewriting without loss. Nothing here is applied to `docs/design/` yet. The
heading sizes are the exception (`9399e63`).

## The versions

| version | what it tried | words | bold spans |
|---|---|---|---|
| [0](versions/v0_spec.md) | the spec as it stood | 873 | 8 |
| [1](versions/v1_labels.md) | context paragraph, four `####` headings, bullets, display code, **Rule.**/**Why.**/**Example.** labels | 1049 | 20 |
| [2](versions/v2_bold.md) | labels dropped; bold reserved for rule sentences | 1032 | 9 |
| [3](versions/v3_cited.md) | each bold rule ends with the D-entry that rules it; rulings applied | 1077 | 12 |
| [4](versions/v4_flat.md) | headings dropped; a roadmap sentence closes the context paragraph | 1046 | 12 |
| [5](versions/v5_from_claims.md) | written from scratch by an agent that saw only a claim list | 1235 | 14 |

The user preferred Version 4. Versions 3 to 5 cite three entries the log does
not yet have, drafted in [draft_entries.md](versions/draft_entries.md).

## What each round found

**Version 1.** The first gain was structural: the context paragraph, bullets
and display code. A blind verifier found no lost claim but eight drifts. A
"because" was dropped, so §10.4 no longer gave the reason guards never run. A
citation ended up covering half its sentence. "With no synchronization on any
path" had weakened to "no path needs synchronization". It also found four new
ambiguities, such as a **Why.** label over a normative sentence. All were
fixed and re-checked.

**Version 2.** The labels broke the flow. A **Why.** paragraph is one or two
sentences right after its rule, and a connective does the label's job. Bold
on the rule sentence itself finds the rule as well as **Rule.** does, but only
if bold means nothing else. Version 1 used bold for lead-ins, a consequence, a
definition and paragraph labels.

**The bold audit.** A cold agent checked each bold sentence against the log.
Seven of nine were rules, but only one cited the entry that rules it. One was
a definition (the D-259 ruling sat behind it). One rule was plain: D-135's
cache scope read as a consequence after a "so". One bold sentence was an
effect, "never cached", whose cause is single ownership. The criterion was
decidable for about 80% of the section. The rest was hard because of the log:
some rulings sit in a Rationale or in a superseded entry, and amended entries
stack rulings.

**Version 3.** The user agreed to all 17 proposals that came out of the audit:

- Wording. The truncated "`x_init`'s" became §9.1's "the state type derived
  from `x_init`". "Pins the invariant" became linearizability, after §8.2's
  "both lurks are contained by policy". D-259 replaced the definitional bold
  sentence. D-135's cache rule became a bold rule. "Caching is an
  implementation detail" became "whether an activation is cached never
  changes a result" (D-052). The ownership rule is bold, "never cached" its
  consequence.
- A correction. Workspace allocators get `T` on the continuous tier and
  `Float64` on the discrete (D-263). Version 0 said `T` for both.
- Citations. D-052, D-099, D-135 and D-259 are now cited. D-166, superseded,
  gave way to a new D-280.
- The log. Rulings found only in a Rationale got entries that state them in a
  Position: D-280 for the CI policy, D-281 for torn-state freedom, D-282 for
  buffer ownership.
- Structure. The context paragraph, the headings and the display code stand.
  §9.1's "Activation, parametric in `T`" overlaps §9.4 and should be merged at
  the real rewrite.

The verifier then caught four slips of the rewriter's own. "Caching changes
only what a request costs" was stronger than D-052. "The cache *can* live on
the `Build`" was weaker than D-135. D-253's two rulings were left plain. A
since-clause sat in D-280's Position.

**Version 4.** Each `####` heading posed a question that the bold rule below
it answered at once. The headings went. With them gone, the sentence naming
the section's parts came back to orient the reader. The PDF showed a second
problem: `###` headings rendered at body size, like a bold sentence. Commit
`9399e63` gives the top three heading levels their own sizes.

**Version 5.** An agent extracted 114 tagged claims from Version 4 in its own
words, and a second agent wrote the section from those claims alone. A third
matched the result against the claims: 113 exact, one antecedent drift, none
lost. The text was longer and choppier, restated rules, and split two bold
rules in two. The extraction step had also slipped in four plausible glosses,
such as "to compensate" for "instead". No verifier caught them, since each
checked against the claims, not against Version 4.

## Conclusions

The convention, agreed for a full rewrite of the spec:

- No **Rule.**, **Why.** or **Example.** labels. A reason follows its rule
  with a plain connective.
- Bold marks a decision rule and nothing else. It never marks lead-ins,
  definitions, consequences or recommendations.
- Each bold sentence ends with the D-entry whose Position rules it. Bold what
  that Position states, not its consequence.
- A ruling found only in a Rationale, or only in a superseded entry, gets a
  new entry that states it in a Position.
- A "so" or "by construction" can quietly turn a rule into a consequence.
  Put the rule first and its reason after.
- Use `####` subheadings only where a long section needs entry points, and
  then as topic labels. Never use a question or a claim as a heading.
- A section without subheadings ends its context paragraph with one sentence
  naming its parts in order.
- Code a reader would type or copy goes in a display block: a call, a
  definition, a signature. Bare identifiers and type names stay inline. The
  user rated this the largest gain in readability.

Rewrite incrementally from the source, never from a paraphrase. The
from-scratch Version 5 lost to Version 4, and its claim list could not be
checked against the source the way verbatim spans can.

A rewrite under this convention is also an audit of the spec against the log.
On §9.4 alone it found five uncited entries, one superseded citation, one
factual error and three rulings with no Position. Budget for that work.

The log gains less. `decisions_style.md` rule 1 forbids retrofitting old
entries, rule 2 keeps each entry's vocabulary of its day, and rule 8 forbids
expanding the terse early ones.

## The method

Rewording, as opposed to reformatting, cannot be proven by a word diff. The
method, endorsed on 2026-09-28 and used for every version here:

1. Inventory the old text as atomic claims. Each claim records its verbatim
   old span, its new span, its citations and a tag: fact, framing or ruled
   change. [checks/check.py](checks/check.py) proves that the old spans cover
   every content word, that each new span exists, and that each claim's
   citations sit in the same paragraph or bullet. It diffs the multisets of
   code spans, citations and glossary links, and with `--bold` it flags a bold
   span without a D-citation.
2. A cold Opus agent lists the new text's claims blind, then matches them
   against the inventory as MATCH, DRIFT, LOST or ADDED, plus new ambiguities.
   Fixes go back to the rewriter, and the verifier re-checks.
3. Settle each finding against the spec and the log, never against another
   agent's paraphrase. Corrections, clarifications and dropped history go to
   the user as a list. They are never folded in.

A citation closing an aside covers the aside. In bullets, a lead line ending
"(D-nnn):" over lowercase sub-bullets carries it. Short edits, such as Version
4's deletion of headings, may skip the cold check.

## Delegating it

Subagents can do most of the work:

- the rewrite and its inventory, by one Opus agent;
- the blind cross-check, always by a different, cold Opus agent;
- the bold audit and the search for uncited entries;
- the fix-and-recheck loop while the checks stay mechanical or the verifier
  supplies them.

Two parts stay with the main session and the user. Findings must be judged
against the source. Rulings are design decisions, so agents surface them and
never apply them.

Do not add a separate extraction step whose output the next agent trusts.
That is how Version 5's glosses got through.

One section took three to five agent runs of 55k to 70k tokens each. The spec
has about a hundred `###` sections. A full rewrite is therefore several hundred
agent runs, best run as a workflow over one Part at a time, with each batch's
rulings pooled for the user.

## Before adopting it

- Write the convention into `tools/spec_style.md`, and move the bold check into
  the battery.
- Decide whether the spec's existing claim-style `####` headings become labels
  or go.
- Land Version 4 in the spec and D-280 to D-282 in the log, then run the
  battery.
- D-052's Spec field lists §9.5 and should list §9.4.
- Merge §9.1's "Activation, parametric in `T`" with §9.4's list of what an
  activation re-runs.
- `spec.md` lacks a blank line between §9.4's last line and `### 9.5`.
