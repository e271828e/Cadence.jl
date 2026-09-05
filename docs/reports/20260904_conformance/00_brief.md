# Conformance audit: brief

An exhaustive account of the gaps between `docs/design/spec.md` and the
package in `src/` and `test/`, rebuilt from scratch. Nine independent agents
each audit one slice of the spec against the code and write one report in
this directory. The coordinator then merges the reports against
`docs/design/pending.md`, which no agent reads, and a verification round
re-checks every reported deviation. Tip `70672d1`, Julia 1.12.7.

## The question

For every obligation the spec places on the code within your slice, answer:
is it built accurately, built with a deviation, or not built. An obligation
is a checkable claim: a name the package must export, a shape a value must
have, a law a function must obey, a diagnostic a condition must raise with a
stated payload and policy, an ordering, an allocation bound. Rationale,
prior art, rejected alternatives and worked examples are not obligations;
note that you skipped them and move on. Enumerate at the granularity of one
claim per row, not one section per row. A section with twelve claims gets
twelve rows.

## Slices

| agent | slice | spec lines |
| --- | --- | --- |
| A | Part I, §1–§7 | 127–1628 |
| B | §8 the declaration layer | 1648–2846 |
| C | §9 the build pipeline | 2847–3660 |
| D | §10 time and execution | 3680–4714 |
| E | §11 the data plane | 4715–6069 |
| F | §12 lifecycle and orchestration | 6070–6922 |
| G | §13 error discipline + Appendix C | 6941–7644 and 10130–10287 |
| H | §14 stopped-sim services | 7645–8851 |
| I | Appendix A + Appendix B | 9679–10129 |

Read your slice whole, by line range. Where a sentence in your slice defers
to another section ("as §N says"), read the cited passage for its meaning
but do not audit it; the agent owning that section does. Agent G audits
every Appendix C row: kind present or absent, payload column carried in full
or short, policy column (collected vs. fail-fast) honoured at every site
that raises the kind. Agent I audits the exported surface name by name:
every entry point Appendix B lists exists with the stated signature and
behaviour, and every taught contract in Appendix A has the code it points
at.

Not audited by anyone: §15, §16, Appendix D, the Contents block, and the
companions in `docs/design/companions/`.

## What you may read

- `docs/design/spec.md`, your slice and any passage it cites.
- `src/` and `test/`, all of it, as often as you need.
- The file table in `docs/design/implementation.md` ("What is real here"),
  as a map of where to look. Every row there is a claim to check, not
  evidence. Do not read the rest of that file.
- `docs/design/decisions.md` only for the specific `D-nnn` entries your
  slice cites. Grep for `### D-nnn` and read that entry. The log sometimes
  ratifies a shape the spec's prose does not spell out, or records a
  rejected alternative; a deviation the log ratifies is reported with its
  `D-nnn`, and a shape the log explicitly rejects is reported as such.

## What you must not read

`docs/design/pending.md`, the top-level `reports/` directory, everything in
`docs/design/briefs/`, the other reports in this directory, and the rest of
`docs/design/implementation.md`. The audit's value is independence from the
existing register. If you open one of these by accident, say so in your
report's header.

## Probing

You may run short probe scripts against the package from the scratchpad
directory named in your environment, with `julia --project=.` from the
repository root, in the foreground, with a timeout of 120 s. The package is
precompiled. Use a probe when reading leaves a claim ambiguous: an
allocation bound, a boundary arithmetic, an error's actual type. Never run
the test suite, never run `Pkg.test()`, and never run anything in the
background. Do not modify any file under `src/`, `test/` or `docs/design/`.

## Verdicts

Every row carries exactly one verdict:

- **accurate**: built in the spec's shape, covering the whole claim.
- **short**: built in the spec's shape, covering less than the claim. A
  diagnostic carrying fewer payload fields than its column, a check present
  at one of two sites, a law enforced on one tier.
- **stand-in**: built in a shape the spec's is not. The claim is satisfied
  or partly satisfied by a different mechanism.
- **absent**: not built. A construct, kind, check or entry point with no
  code behind it.
- **n/a**: not an obligation on the code. Rationale, history, rejected
  alternatives, examples. Give one row per skipped passage, not per
  sentence.

Add the marker **ratified D-nnn** to a short or stand-in row when the
decision log settles that shape. Add **rejected D-nnn** when the log names
the implemented shape as an alternative it rejected.

For every accurate, short or stand-in row, give the location as
`file.jl:line` (a range where the construct spans one) and the test that
asserts the claim as `test_x.jl:line` or the testset name, or write "no
test". A row with "no test" is still accurate if the code plainly does what
the spec says; the test column is a separate fact.

For every short, stand-in or absent row, state the gap in one or two
sentences: what the spec asks for, what the code does instead, and, when
you found it, why it matters (a wrong result, a missing refusal, a message
that misleads).

## Report format

One file per agent, `docs/reports/<letter>_<slug>.md`, for example
`docs/reports/a_foundations.md`. Structure:

1. **Header**: agent letter, slice, line range, tip hash, whether any
   probe was run, and any accidental read of a forbidden file.
2. **Summary**: a short prose account of the slice's standing. Where the
   gaps cluster, the deviations that matter most, anything that surprised
   you. A reader who stops here should know what the slice owes.
3. **Findings table**, one row per claim, in spec order, with the columns
   `§` (section and line), `claim` (a short phrase), `verdict`,
   `location`, `test`, `note`. Keep the note column short; a gap that
   needs more than two sentences goes in section 4 and the note says
   "see 4.n".
4. **Deviations in detail**: one numbered entry per short, stand-in or
   absent row that needed more room. Quote the spec sentence, cite the
   code, state what a probe showed if you ran one.
5. **Tally**: counts per verdict.
6. **Friction**: anything in the spec, the code or this brief that made
   the audit harder than it should have been. A claim you could not
   decide, a passage two readings fit, a test whose name promises more
   than it checks. Empty is acceptable.

Write in plain prose, short sentences, no em-dashes. Cite the spec by
section and line number. Cite code by `file:line`.

## Stance

Open mind. The implementation is a peer of the spec, grown one increment at
a time, and much of it is more precise than the prose. Read the code before
deciding what the spec asks for, then read the spec again. A claim you
cannot decide gets its own row with the verdict you lean to and a friction
entry. Do not soften a deviation because the code is careful elsewhere, and
do not report a deviation you have not traced to a line.
