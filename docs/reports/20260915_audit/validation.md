# Validation and reproducibility

## Runtime and revisions

- Julia **1.13.0**, 10 default-pool threads, 2 thread pools as reported by Julia.
- Initial review revision: `865521a0f7be6894b1688925bb349dcbadd06539`.
- Subsystem reconciliation: `f941c504c90eadbad9950a182feafa96b300a642`.
- Final delta reconciliation: `6986ad41b5f04c671fc6b321b4bab6df54520a40`.
- Hash manifests: [initial](validation/baseline.json),
  [intermediate](validation/current-baseline.json), and
  [final](validation/final-baseline.json), covering every source, test and
  permitted design file. The [first delta](validation/revision-delta.patch)
  records independent auto-publication changes; the
  [final delta](validation/final-revision-delta.patch) records subsequent path
  resolution changes. The primary reviewer read the full final permitted delta.

## Existing suites

| Run | Result | Evidence |
|---|---|---|
| Initial direct suite: `julia --project=test test/runtests.jl` | 2,425 / 2,425, 5m08.3s | [direct-suite.log](validation/direct-suite.log) |
| Initial isolated gate: `julia --project=. -e 'using Pkg; Pkg.test()'` | 2,425 / 2,425, 5m08.7s | [pkg-test.log](validation/pkg-test.log) |
| Intermediate isolated gate at `f941c50` | **2,478 / 2,478, 5m37.9s**, process exit 0 | [pkg-test-current.log](validation/pkg-test-current.log) |
| Final isolated gate at `6986ad4`, same `Pkg.test()` command | **2,514 / 2,514, 5m34.6s**, process exit 0 | [pkg-test-final.log](validation/pkg-test-final.log) |

Times are the suite's own reported elapsed time, excluding package preparation.
The first direct-suite launch was blocked before running by Julia launcher's
configuration lock permissions; the approved retry completed. This was an
environment startup failure, not a product test failure.

The final gate covers 89 more assertions than the initial baseline and 36 more
than the intermediate revision. A second direct run was unnecessary after the
final isolated package gate passed.

## Targeted probes

Run from the repository root:

```sh
julia --project=test docs/reports/20260915_audit/validation/run_probes.jl
```

The runner starts a fresh process per probe and retains output, preventing local
fixture/generic definitions from interfering across probes. All nine scripts
completed with exit 0 on `6986ad4`; see
[runner summary](validation/probe-results-final.log). **A successful probe can
mean that it reproduced a bug, not that the product passed that requirement.**

| Probe | Material outcome on current revision | Output |
|---|---|---|
| `build_confirmed_gaps.jl` | Simple auto-publication now succeeds; empty stage and nested container still accepted; imprecise cycle membership, enum rejection and raw probe errors persist. | [log](validation/build_confirmed_gaps-final.log) |
| `execution_handler_key_drift.jl` | Unknown top-level handler key silently ignored; scalar return becomes a raw `MethodError` cause. | [log](validation/execution_handler_key_drift-final.log) |
| `execution_time_bounds.jl` | Finite wide bound converts to `Inf`; finite huge frame count raises `InexactError`. | [log](validation/execution_time_bounds-final.log) |
| `periphery_replay_payload.jl` | Missing root retains target value; extra root fails after partial write; returned trace aliases recording. | [log](validation/periphery_replay_payload-final.log) |
| `periphery_timedout_handle.jl` | Prior-run task stages into or stops the next trajectory. | [log](validation/periphery_timedout_handle-final.log) |
| `services_confirmed_gaps.jl` | Missing relocation/linearization, unchecked vector index, invalid callable and swallowed conversion interrupt. | [log](validation/services_confirmed_gaps-final.log) |
| `publication_allocation.jl` | Warmed minimum publication allocation is 576 bytes with logging off, 736 with logging on; corresponding whole-frame figures 592/752. Trace off; tiny stateless fixture only. | [log](validation/publication_allocation-final.log) |
| `termination_priority.jl` | Model source wins all three tested collisions with higher-priority control/end-time sources. | [log](validation/termination_priority-final.log) |
| `storage_diagnostic_gaps.jl` | Enum/probe/framing/dead-stage failures; mutable `BigInt` admitted; mutation through a retained snapshot changes both snapshot and live cell. | [log](validation/storage_diagnostic_gaps-final.log) |

Some probes print caught failures rather than asserting every diagnosis; their
material output was inspected by the primary reviewer. The timeout probe releases
its blocked tasks before exiting. No source/test fixtures were modified.

## Evidence boundaries

- Real OS SIGINT delivery was not injected. Missing masking/forwarding/escalation
  is established by source inspection, independently of valid synthetic
  defensive-catch tests.
- Same-simulation lifecycle admission races were not dynamically reproduced and
  are classified as design hardening/contract questions.
- The numerical review and suite cover analytic RK4/Heun examples, localization
  and event cases; they do not prove arbitrary model correctness or every
  possible crossing/interleaving.
- The allocation figures characterize one warmed fixture and runtime. They
  resolve a documentation conflict; they are not an end-to-end performance
  certification or a claim that allocating snapshots violate D-023.
- No real aircraft migration, GUI integration, external device hardware,
  wall-clock pacer benchmark, long-duration memory trial, or on-disk trace
  interoperability check was performed. Those artifacts were absent, deferred,
  or outside the allowed corpus.
- The coverage ledger contains all **81 numbered subsections**, top-level
  sections and appendices, and every source/test file. A disposition means
  reviewed evidence/limits, not formal conformance proof.

## Integrity

Final verification passed: all 52 permitted input files match
`final-baseline.json`, no audit inputs were added or removed, and HEAD remains
`6986ad4`. Markdown links resolve, and the ledger accounts for all 81 numbered
subsections, 19 source files and 30 test/harness files. Only `docs/reports/20260915_audit/` is an audit-created change.
The resulting verification record is retained in
[final-integrity.json](validation/final-integrity.json).
