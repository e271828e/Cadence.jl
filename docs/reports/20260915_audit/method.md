# Audit method and baseline

## Scope

This is an independent review of `src/`, `test/`, and only these design documents:
`docs/design/spec.md`, `docs/design/decisions.md`, and
`docs/design/implementation.md`. No previous audit, pending register, other
repository documentation, migration code, or external source supplies findings.
References to excluded material inside the permitted documents are not followed.

The initial working tree was clean. Revision:
`865521a0f7be6894b1688925bb349dcbadd06539`.
`validation/baseline.json` records SHA-256 hashes of every permitted file.
All audit artifacts live in this directory; existing repository files are preserved.

## Evidence and interpretation

The specification is the requested conformance target. Decisions provide settled
rulings and supersession information. The implementation document is a map and a
set of claims to verify, not evidence that implementation conforms. A disagreement
between the permitted documents is identified explicitly rather than silently
resolved. Explicit exclusions, deferred extensions, migration deliverables, and
illustrative case studies are distinguished from current framework requirements.

Findings separate missing behavior, contradictory behavior, implementation defects,
documentation ambiguity, and optional improvements. A test gap alone is not a
demonstrated defect. Passing tests establish the assertions actually exercised;
they do not establish whole-specification conformance.

Severity reflects practical impact: high for corrupted/incorrect results, loss of
isolation, lifecycle failures, or substantial unavailable specified capabilities;
medium for bounded API/validation/diagnostic failures; low for localized clarity
or ergonomic shortcomings. Confidence and verification method are recorded
separately from severity.

## Review organization

Three Sol reviewers work concurrently on build, execution, and periphery. A second
wave reviews services and storage/diagnostic contracts with Sol, and independent
test/spec traceability with Terra. The primary reviewer checks candidates,
cross-layer interactions, grounding/open-axis sections, and final coverage,
deduplicates findings, and curates the final report. Subagent reports are retained
as working evidence; the curated report determines the final classifications.

Every numbered specification subsection is accounted for in the coverage ledger.
Coverage means a recorded disposition and review evidence, not formal proof of
every sentence. Unexecuted scenarios and unresolved suspicions stay visible.

## Verification

Run the documented direct suite and `Pkg.test()` trust gate. Targeted reproductions
are separate scripts under `probes/`; no tests or source are changed. Runtime logs
are stored under `validation/`. Final verification compares permitted-file hashes and working-tree changes
against the final reconciliation baseline, retaining the earlier baselines.

The first direct-suite attempt could not start because the Julia launcher needed
to create its configuration lock outside the filesystem sandbox. The user approved
the escalated retry. This environment issue is not a Cadence test failure.

## Resumption and reconciliation

Usage-window interruptions split the work. Independent auto-publication commits
changed 12 allowed inputs between `865521a` and `f941c50`; spec and decisions were
unchanged. The subsystem reviews and 2,478-assertion package gate cover `f941c50`.

Later path-resolution commits changed 14 allowed inputs between `f941c50` and
`6986ad41b5f04c671fc6b321b4bab6df54520a40`. The primary reviewer inspected the
complete permitted delta, including Appendix C edits and added tests, and reran
the package gate and all nine probes. This bounded reconciliation closes the
candidate-list and declared-type diagnostic omissions; it does not imply a new
full independent review of every unchanged file. Decisions remained unchanged.

The three hash manifests and two allowed-scope patches under `validation/`
preserve those revision boundaries. No new design ruling is inferred from a
concurrent code change; historical findings remain identifiable in the reviews.

## Finding refresh — 2026-09-17

The user explicitly authorized `pending.md` as an additional input to reassess
which findings were fixed. The refresh checks the original IDs against source,
tests and current rulings at committed `66c49f0`; it does not repeat the full
subsection audit. Three bounded Sol/Terra reviews and primary runtime review are
retained as reviews 08–11. Concurrent diagnostic edits are separated from
committed conclusions. Only this report directory is edited by the audit; the
pre-existing and concurrent implementation work is left to its owner. The
original report is archived with its relative links adjusted for the archive's
location. Original validation files and input manifests are preserved.

On resumption on 2026-09-18, the diagnostic work had landed at `7b1c1e8`.
The additional allowed delta (24 files, 475 insertions/230 deletions) was reviewed
for changes to the named findings. A clean source/test baseline was hashed and
the full gate plus focused probes rerun. The earlier mixed-worktree failure is
retained and identified; its tests/source were not a coherent committed target.

The final resumption found a further 17-file allowed delta at `2938a0`:
D-250–D-258 and removal of auto-publication. Separate build and design reviews
reconciled its effect on the existing findings. The primary reviewer froze
54 permitted inputs, inspected source/test changes and the new rulings, and
launched a new package gate and retained-behavior probes. Evidence lives under
`refresh_20260918/`; the `7b1c1e8` checkpoint remains historical. No pipeline
briefs, roadmap or prior audit reports were followed.
