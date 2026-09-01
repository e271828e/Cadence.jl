---
name: conformance-audit
description: Audit spec.md against src/ with parallel independent readers, then diff the findings against implementation.md's register
argument-hint: "Whole spec, or which parts?"
disable-model-invocation: true
---

You coordinate. Subagents read and report. You verify and merge.

## What this is for

`docs/design/implementation.md` carries a self-reported account of what is
absent and what deviates. Self-reported is the weakness: it records the
deviations somebody wrote down. The rule "nothing deviates silently" is
unenforceable by tooling, as that file itself admits, and `src/` and `test/`
sit outside every roster.

This audit is the instrument that finds the ones nobody wrote down. Its payoff
is not the per-part reports; it is the **diff between the reports and the
register the readers were never allowed to see**. Design the run around that
and the rest follows.

Spec and code are peers. A divergence may be a defect in either. Agents record;
you adjudicate.

## 1. Slice the spec — recompute it every time

Never reuse a previous run's slicing. The spec grows and its balance shifts.

    grep -n '^# Part\|^# Appendices\|^## \|^### ' docs/design/spec.md
    wc -l src/*.jl test/*.jl

Balance each slice on **both** axes: spec lines to read, and source lines to
cross-check. They diverge badly. Then apply what the first run (2026-09-01,
tip `2c02afb`) learned:

- **The spec's own part divisions are not balanced slices.** Part III was 2.2×
  Part I on the spec side and roughly 4700 source lines against Part I's 300.
  Split at a section seam, not a part boundary.
- **Appendix C gets its own agent.** It is the normative diagnostic kind set
  with a payload column, it is where a large share of recorded absences live,
  and every other slice trips over diagnostics. Without an owner you get the
  same kinds reported five times in five idioms and nobody enumerating them.
  Tell every other agent to defer the kind set to that agent and audit only
  the mechanism behind it.
- **Appendix A/B is a mechanical signature sweep.** Names, arities, keyword
  spellings, defaults, exports. Put it on **Sonnet**; everything else on
  **Opus**, where payload and design judgment is load-bearing.
- **A formalism-heavy slice needs different instructions.** Part I's §2–§3 are
  embodied across the build rather than implemented at a site. Tell that agent
  to judge whether the code's shape *satisfies* the obligation and cite the two
  or three places carrying it, and to reserve `pending` for obligations naming
  a concrete construct nothing provides. Otherwise it manufactures gaps.
- Part V is grounding. §15 is an expressiveness question, not a gap audit; §16
  is parked. Leave both out unless asked.

Seven agents fit the current spec. Expect ~165k–245k tokens and 10–16 minutes
each.

## 2. Write one brief, with a section per agent

Put it in `docs/design/briefs/`. Shared preamble first, then one assignment
each. Launch every agent in a single message so they run concurrently, each
carrying only "read the brief, then your own section", plus the hard rules
restated inline so they cannot be missed.

### The isolation rule — the whole point

**No agent may open `docs/design/implementation.md`.** Not the absence list,
not the stand-ins, not the file table. Withholding the whole file is cleaner
than "skip two sections" and removes the temptation to peek. The file table in
particular is half the answer to "where does it live", and an agent handed it
confirms the table instead of auditing the code. Tell them to back out if a
grep lands them in it. `src/` and `test/` comments cite it by name; that is
fine.

Pay the cost back with a **neutral orientation block you write yourself**: the
`src/` file list with line counts and a four-word gloss each, the `test/` list,
the note that `rg '§' test/` is a section-to-test index, that tests are
evidence and `src/` is authority, and that `test/` deliberately does not mirror
`src/` so the asymmetry is not a finding. Twenty lines, no verdicts embedded.

### The decisions-log rule

`docs/design/decisions.md` refines and supersedes the spec's letter constantly,
and `src/` cites `D-nnn` at the sites where it does. Without this rule you get
a pile of "deviations" that are ratified design.

> Before writing any `deviation` finding, grep the log for the `D-nnn` the code
> cites at that site and for the section number. State in the finding whether a
> decision covers it and which one. Grep it; never read it front to back.

### Operational rules

Read-only outside `reports/`. One file per agent, path named in the
assignment. Do not run the test suite — five minutes, and it says nothing the
source does not. No nested subagents. Stay in slice; out-of-slice observations
go in a list, unadjudicated.

### Julia traps to restate

So agents do not report non-findings: local-scope declarations never reach the
framework (why fixtures sit at top level); extending a declaration without
importing it is silent on 1.12; `_typename` versus `string(typeof(...))`; the
`t0` / `t₀` split. Paraphrase them — the caveats section names absences, and
copying it verbatim leaks answers.

## 3. The report template — fix it verbatim in the brief

Independently authored reports do not merge. Three parts.

**Summary.** Half a page of prose: the slice's standing, the shape of what is
missing, the two or three findings to raise first, and plainly if a section
defeated the agent.

**The table.** One row per spec obligation, at the granularity of the spec's
own numbered subsection — not per paragraph, or a dense section yields four
hundred unread rows. Tens per section, not hundreds.

| col | content |
| --- | --- |
| `anchor` | `§N.M` plus the `spec.md` line range |
| `obligation` | one sentence. What the spec requires |
| `verdict` | `accurate` / `partial` / `deviation` / `pending` |
| `where` | `file.jl:line`, or for `pending` the searches that came back empty |
| `notes` | for `deviation`/`partial`: what the code does instead, and whether a `D-nnn` ratifies it |
| `test` | `test_x.jl` and the testset name, or `none` |
| `conf` | `high` / `medium` / `low` |

Pin the verdicts: `accurate` — does what the spec says, found and read.
`partial` — shape exists, does less; say what is missing. `deviation` — does
something else, or carries a payload, signature or arity short of the spec's.
`pending` — nothing implements it.

**Two lists.** *Observed outside my slice*, one line each, unadjudicated. *Spec
problems* — ambiguity, internal contradiction, or places the code's shape reads
better than the spec's. The design is not privileged over the implementation,
and these are worth as much as the gap findings.

## 4. Guard the dominant failure mode

An agent that cannot find something concludes it is absent. The error is
asymmetric: a false `pending` manufactures a gap and costs you adjudication.
Put all four in the brief.

- Every `pending` row lists the **actual grep patterns** that came back empty.
- Search by concept, not the spec's spelling: type name, field name, diagnostic
  kind, section number in comments, the `D-nnn`.
- `low` confidence is respectable and cheaper than a wrong `pending`.
- The converse counts too: never mark `accurate` off a matching name. Read the
  body.

## 5. Verify as the reports land

Do not wait for all of them. As each arrives, check its headline claims
yourself with a grep or two — you are reporting them to the user, and one
wrong headline costs the whole audit its credibility. Cheap and high-value:
a claimed-absent symbol, a signature, a `keys(...) === keys(...)`, an
`export` sweep, a rounding call. Note in the merge which findings you verified.

Watch for **convergence**: the same defect found independently by two agents
from different directions is the strongest signal the run produces. Say so.

## 6. Merge — this is the deliverable

Write `reports/00_findings_vs_register.md`. Now read
`implementation.md` and diff every non-`accurate` finding against its absence
list and stand-in table. Sections, in this order:

- **A. Contradicts something the register explicitly asserts.** The rule
  violations. Highest severity, because the register claims otherwise.
- **B. Undocumented deviations** — in neither the absence list nor the
  stand-ins. What the exercise exists to find.
- **C. Undocumented absences** — whole obligations with no implementation and
  no entry.
- **D. Documented but understated** — the entry exists and is weaker than the
  truth.
- **E. Where the register holds.** Say this plainly; it is a real result.
- **F. Verification queue** — what you did not check, ranked.
- **G. Spec-side findings** — spec-pass material, not code work.

To extract the rows without drowning in the tables:

    for f in reports/*.md; do echo "### $f"; awk -F'|' '/^\|/ {
      for(i=1;i<=NF;i++) gsub(/^ +| +$/,"",$i)
      for(i=1;i<=NF;i++) if($i ~ /^`?(deviation|partial|pending)`?$/)
        printf "%-32s %-10s %s\n", substr($2,1,32), $i, substr($3,1,110)
    }' "$f"; done

Then commit the brief and the reports together, and say which findings are
verified and which are still claims.
