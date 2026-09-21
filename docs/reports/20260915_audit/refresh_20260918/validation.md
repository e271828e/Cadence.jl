# Latest refresh validation — 2026-09-18

## Frozen review boundary

Target: **`2938a025c05bc136dd9f76f64cb42f89f4986d4c`**, following the completed
`7b1c1e8` checkpoint. [Baseline](baseline.json) records SHA-256 hashes for all
54 permitted source/test/design inputs and the starting worktree status.
[Allowed delta](delta.patch) preserves the 17-file change since that checkpoint
(1,575 insertions/970 deletions). The primary reviewer and two bounded Sol/Terra
reviews reconciled its effect on the original findings; the new pipeline design
was not subjected to a new exhaustive audit.

Only `src/**`, `test/**`, `spec.md`, `decisions.md`, `implementation.md` and the
explicitly authorized `pending.md` were used as implementation/design inputs.
Pipeline briefs, the roadmap and previous audits were not followed. All audit
writes remain under `docs/reports/20260915_audit/`.

## Package gate

The [package run](pkg-test.log) uses Julia 1.13.0 and:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: pending completion at report preparation.

The earlier **2,828/2,828** result is tied to `7b1c1e8`, and the original
**2,514/2,514** to `6986ad4`. The intermediate mixed-worktree failure remains
recorded in [the previous validation](../refresh_20260917/validation.md).
No source or test changes were made to secure a passing result.

## Retained-behavior probes

All seven scripts completed with exit 0 on the frozen target. Their success
means they reproduced the intended observations, predominantly remaining bugs;
it does not mean these behaviors conform. [Runner](run_probes.jl),
[summary](runtime-probes-final.log).

| Probe | Current observation | Log |
|---|---|---|
| Handler returns | Unknown key silently ignored; scalar return has raw `MethodError` cause. | [handler](handler_probe-final.log) |
| Time bounds | Finite wide value becomes `Inf`; huge finite frame count produces `InexactError`. | [bounds](execution_time_bounds-final.log) |
| Replay and trace | Missing root keeps `b=20`; extra root writes live `a=99` before failure while latest stays 10; trace schema and entries alias. | [replay](periphery_replay_payload-final.log) |
| Timeout survivors | Old device task stages 77 and can stop the later trajectory. | [survivor](periphery_timedout_handle-final.log) |
| Services | Reads/problem relocation and linearization missing; late invalid index/callability failures; conversion interrupt becomes diagnostic. | [services](services_confirmed_gaps-final.log) |
| Stop priority | Model stop wins all three tested control/end collisions. | [priority](termination_priority-final.log) |
| Storage | `BigInt` admitted; mutable `Real` shares live/snapshot identity; pre-init root retains synthesized zero. | [storage](storage_residuals-final.log) |

The scripts reuse preserved report probes; the previously adapted handler
fixture supplies an explicit nonempty stage return. The old auto-publication
probe is intentionally incompatible with D-252 and was not rerun as a current
defect assertion. Retirement conclusions also rely on source and repository
tests cited in the build/design reviews. Real OS interrupt delivery, concurrency
stress, hardware behavior and timing benchmarks were not tested.

## Dispositions and integrity

[Dispositions](dispositions.json): seven original finding IDs retired, three
partially fixed, sixteen fully open. Documentation items 3 and 4 are retired;
items 1/2 require prose corrections and item 5 remains a design concern.
Appendix C contains 83 named rows: 77 `Diagnostic` subtypes plus `StepError`;
five named kinds are absent, including the new `EmptyFaceSelection` warning.
The new pipeline obligations are identified separately rather than folded into
an inflated count of independently audited findings.

Final hash, link, whitespace and worktree checks will be recorded in
[the integrity record](integrity.json).
