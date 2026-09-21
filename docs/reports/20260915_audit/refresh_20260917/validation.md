# Refresh validation — 2026-09-17/18

## Revision boundaries

- Original audit: `6986ad41b5f04c671fc6b321b4bab6df54520a40`.
- Initial refresh: committed `66c49f09b4cfc3ddb0b62523e979cd0537ba7c8c`, with
  concurrent diagnostic edits. [Initial hashes/status](baseline.json) and
  [initial worktree patch](worktree.patch) preserve the starting observation.
- Final refresh: `7b1c1e850515dad77942973e9ae87ebcc2ac7a6c`, with clean source,
  tests and design inputs at launch. [Final hashes](final-baseline.json) and
  [the last allowed delta](final-delta.patch) delimit the follow-up inspection.

The report retires findings from actual code/tests and settled rulings. The
current `pending.md` is an authorized navigation aid, not a conformance oracle.
Original subsection coverage remains historical; this is a bounded refresh of
existing findings, not another exhaustive audit of every newly added mechanism.

## Package runs

The original **2,514/2,514** result belongs to `6986ad4` only.

The [first refresh run](pkg-test.log) failed: **2,176 passed, 3 failed,
2 errored**. Source and tests changed concurrently. The failures exercised the
old arity-kind and `EventHalfMissing.found` expectations, and diagnostic fixtures
omitting the newly required `declared` keyword. This is retained as evidence of
the mixed worktree, not attributed to either clean committed revision. No source
or test edits were made by this audit to fix it.

The [final package gate](pkg-test-final.log) at `7b1c1e8` passed:
**2,828/2,828 assertions, 8m48.6s**, process exit 0, Julia 1.13.0. Command:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

The reported time is the suite's elapsed time, excluding package preparation.
Final input hashes match the pre-run baseline; the source, tests and design
files did not change during this run.

## Focused current-behavior checks

Seven scripts run on the final checkout. A zero exit means the script completed
its intended observation; these scripts mostly **reproduce remaining defects**.

| Script | Observed behavior | Evidence |
|---|---|---|
| Handler key/scalar | Unknown top-level key ignored; scalar return has a raw `MethodError` cause. | [output](handler_probe-final.log) |
| Extreme time bounds | Finite wide value becomes `Inf`; huge finite frame count throws `InexactError`. | [output](execution_time_bounds-final.log) |
| Replay/trace | Missing root preserves old value; extra root partially writes; returned artifact aliases retained trace. | [output](periphery_replay_payload-final.log) |
| Timeout survivor | Previous-run task stages `77` or stops a later trajectory. | [output](periphery_timedout_handle-final.log) |
| Services | Missing relocation/linearization; late index/callability failure; swallowed conversion interrupt. | [output](services_confirmed_gaps-final.log) |
| Termination priority | Model source wins all three control/end-time collision cases. | [output](termination_priority-final.log) |
| Storage residuals | Mutable numeric snapshot/live alias; fabricated root input visible before initialization. | [output](storage-residuals-final.log) |

The [runner](run_final_probes.jl) executes the first six in separate Julia
processes; [its summary](runtime-probes-final.log) records all exit codes.
[Storage residuals](storage_residuals.jl) ran separately and exited zero.
The handler probe's nominal scalar-handler return was adapted to satisfy the
newly implemented `DeadStage` check; its runtime branch still exercises the
original defect. Original probes and logs were preserved, since rerunning
scripts which assert now-fixed bugs would not test current conformance.

The seven retirement conclusions additionally rely on reviewed committed source
and focused repository tests, documented in refresh reviews 08–10. The custom
`probe_value` framing residual is source/test evidence: an existing regression
asserts its raw `MethodError`. No real operating-system interrupt delivery,
concurrency stress test, hardware test or timing benchmark was performed.

## File preservation and limits

Only files under `docs/reports/20260915_audit/` were authored or changed by this
audit refresh. Source changes observed during the first pass belonged to
concurrent implementation work and were not modified or reverted. The final
integrity record compares all allowed input hashes to the final baseline and
records the final working-tree status. The full diagnostic inventory now has
82 named rows, with four kinds still absent; presence is not proof of correct
trigger, payload, collection policy or severity.

[Final integrity record](final-integrity.json) and [finding dispositions](dispositions.json)
retain the input checks and machine-readable status map.

HEAD advanced to `6b92356b7f34f5bfb7f1078f2249ee312759f884` during final checks,
but every allowed input and the complete input-file set still match the
`7b1c1e8` baseline. No additional source/test/design reconciliation or test rerun
is warranted for that metadata change; excluded files were not inspected.

## Later checkpoint

This record is historical to `7b1c1e8`. The later port-model/design delta at
`2938a0` is assessed in [2026-09-18 validation](../refresh_20260918/validation.md).
Its new diagnostic inventory has 83 rows and five absent kinds, adding
`EmptyFaceSelection`; the counts above describe the earlier checkpoint.
