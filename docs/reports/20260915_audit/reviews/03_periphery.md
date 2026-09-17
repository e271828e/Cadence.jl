# Periphery audit: data plane, devices, trace/replay, and lifecycle

## Audit basis and limits

- **Audited source baseline:** `865521a0f7be6894b1688925bb349dcbadd06539`. The coordinator verified that all permitted files remain byte-identical. Unowned out-of-scope working-tree changes were observed without inspecting their contents; no changed-HEAD claim is made.
- **Normative inputs:** `docs/design/spec.md`, with related ratified positions in `docs/design/decisions.md`. `docs/design/implementation.md` was read first as the requested source map.
- **Source owned by this review:** `src/dataplane.jl`, `src/bindings.jl`, `src/roster.jl`, `src/devices.jl`, `src/trace.jl`, and the lifecycle/replay portions of `src/sim.jl`.
- **Tests reviewed:** `test_dataplane.jl`, `test_roster.jl`, `test_bindings.jl`, `test_devices.jl`, `test_log.jl`, `test_trace.jl`, `test_lifecycle.jl`, `test_failures.jl`, and the fixtures those files use.
- **Specification coverage:** §§11.1–11.8, 12.1–12.7, 13.5, and 13.6, with emphasis on the shutdown and concurrency contracts and malformed replay artifacts.
- `pending.md` and previous reports were neither read nor used. Boundary arithmetic and integration numerics belong to the execution review and are excluded here.
- Two focused probes were added under `docs/reports/20260915_audit/probes/`. I did not run the full suite independently. The coordinator reports the direct suite passed **2425/2425 on Julia 1.13.0**.

## Executive findings

| ID | Severity | Finding | Contract impact |
|---|---:|---|---|
| P-01 | High | A device task abandoned after `join_timeout` retains a usable `DeviceHandle` and can stage or stop a later trajectory. | Violates run-scoped task/resource authority and corrupts later runs. |
| P-02 | High | Replay validates the header's declared layout but not its state/root payload; malformed roots are accepted or fail after partial live writes. | Breaks loud up-front validation and the no-write-on-rejection requirement. |
| P-03 | Medium–High | `trace(sim)` and `_detach` shallow-copy nested mutable data. A returned trace can mutate the simulation's retained primary artifact; concurrent reads are also unsynchronized. | Breaks the documented detached-value behavior and creates a read/write race. |
| P-04 | High deviation | `InterruptException` is treated as a graceful control stop after abandoning the current frame, device wrappers can classify it as `DeviceCrash`. | Conflicts with the specified mask/unmask protocol and device exception contract. Synthetic interrupt tests do not verify masking. |
| P-05 | Medium | A `stop_on` face wins before control and `t_end` when multiple termination causes coincide. | Reverses the ratified source priority. |
| P-06 | Improvement / contract question | Lifecycle admission is a load/check followed later by a store. Concurrent service calls can both pass the gate before either claims `:running`. | The stopped-state roster freeze and single-advance lifecycle gate are not atomic. |
| P-07 | Medium gap | Only stop is present from the control/pacing family; startup thread-budget warning and pacer status/diagnostics are absent. | §§11.8, 12.1, and 12.2 are incomplete as a family. |
| P-08 | Low–Medium | Unknown output selectors omit the required did-you-mean candidate set. | Attach failures are typed and early, but not as informative as §11.2 requires. |

The direct suite result shows these cases are outside the present regression coverage. The synthetic interrupt tests verify the required defensive carve-out, but cannot establish asynchronous signal masking.

## Detailed findings

### P-01 — Timed-out device tasks retain authority over subsequent trajectories

**Severity: High. Confirmed by probe.**

The specification makes device tasks run-scoped and requires every run resource to be released before `run!` returns:

- `docs/design/spec.md:4886-4896` — one task per rostered device, all run-scoped, joined at every stop.
- `docs/design/spec.md:6456-6467` — every resource acquired for the run is released before return.
- `docs/design/spec.md:6586-6607` — after the tail the task set is empty; never a task or live resource survives; the next run spawns fresh tasks.

The implementation times out a join and reports it, but neither terminates the task nor revokes its capabilities:

- `src/devices.jl:160-170` — `DeviceHandle` directly retains the data plane, control plane, writer, gather, and publication counter.
- `src/devices.jl:214-328` — `running`, `stop!`, `stage!`, `report!`, and `wait` act through those references and have no run generation check.
- `src/devices.jl:451-471` — the tail uses one shared deadline and emits `DeviceJoinTimeout`; after expiry it leaves the actual task alive.
- `src/sim.jl:1011-1013` — cleanup empties `sim.plane.run_tasks`, removing the framework's reference without invalidating the surviving task.
- `src/sim.jl:566-580` — opening the next trajectory clears current staging, but a survivor may write after that point.

The existing timeout test at `test/test_devices.jl:266-288` lets its stubborn task wake after the timeout and does not reopen the simulation or exercise the retained handle. It therefore verifies bounded return and the warning, but not the run-scope invariant.

Reproduction: `julia --project=test docs/reports/20260915_audit/probes/periphery_timedout_handle.jl`

```text
Warning DeviceJoinTimeout...
late stage: advanced=1, a=77.0, lifecycle=initialized
Warning DeviceJoinTimeout...
late stop: advanced=0, lifecycle=stopped, source=Cadence.ControlRequestedStop("device 1 (LateAction)")
```

The first old task injects `a = 77.0` into a later, nominally device-free `step!`. The second terminates a later trajectory without advancing and attributes the stop to the device from the preceding run. The same handle can also race `last_seen` and diagnostic state with the fresh task created for that roster entry.

**Design options:** give every run a generation/epoch and capture it in each handle. Revoke the generation when the tail begins or completes, and make every handle operation reject or harmlessly drop work from a stale generation. If task termination is added, capability revocation is still valuable because asynchronous termination alone does not prove that no final operation escapes. Keep the task registry truthful until the task actually exits. Capability revocation alone cannot protect device resources from a new `init!` racing an old task: consider quarantining restart until survivors exit, or explicitly defining a different timeout disposition. These alternatives require a design choice.

### P-02 — Replay payload is not validated before writes

**Severity: High. Confirmed by probe.**

The trace header is the full resolved initial world (`docs/design/spec.md:5612-5658`). Replay must validate it loudly and up front, including store layout and root-input faces, before the first frame (`docs/design/spec.md:7112-7129`). A rejected artifact must not partly install itself.

`_check_header!` verifies the header's self-described layout fingerprint against the target, but it does not verify that the actual payload conforms to that description:

- `src/trace.jl:324-358` — compares layout/deployment/schema metadata; does not establish exact cardinality, uniqueness, and convertibility of `h.x`, `h.s`, `h.m`, and `h.root_inputs`, or reject a negative `trc.frames`.
- `src/sim.jl:792-805` — after the metadata check, replay writes `x`, `s`, `m`, and root inputs directly into live stores. Root lookup and conversion failures can occur after earlier entries were committed and before `_open_trajectory!` establishes a coherent new trajectory.

The current trace validation tests (`test/test_trace.jl:203-301`) cover altered layout metadata, schema disagreement, record positions, and frame ranges. They do not construct a payload inconsistent with a valid declared layout: missing/extra/duplicate roots, inconsistent store-vector lengths, wrong values, negative trace length, or the no-write postcondition after rejection.

Reproduction: `julia --project=test docs/reports/20260915_audit/probes/periphery_replay_payload.jl`

```text
missing root accepted: a=1.0, b=20.0, lifecycle=initialized
extra root error=KeyError; live a=99.0; latest a=10.0; lifecycle=initialized
```

In the first case, the artifact declares roots `a` and `b` in its layout but carries only `a`; replay silently retains the target simulation's old `b = 20.0`. The result depends on the target's prior trajectory rather than solely on the trace. In the second case, valid `a = 99.0` is written before unknown `zzz` throws a raw `KeyError`; `latest` still reports `a = 10.0`, so the live store and published state disagree while lifecycle remains `:initialized`.

**Required correction:** validate the complete concrete payload before touching the target: exact `x/s/m` shapes, exact root-face set with each face once, value convertibility, schema internals, record positions, and nonnegative trace length. Prefer building a temporary resolved state and committing it only after all validation succeeds. Surface the documented typed replay diagnostic rather than `KeyError` or conversion exceptions.

### P-03 — Returned traces alias the retained primary artifact

**Severity: Medium–High. Confirmed by probe.**

Trace is the primary record and is retrieved after a run (`docs/design/spec.md:5651-5666`). The implementation's own `_detach` contract says it copies every mutable field, yet nested storage remains shared:

- `src/trace.jl:37-48` — `TraceHeader` contains mutable vectors for stores, roots, schemas, and layout.
- `src/trace.jl:58-62` — each `TraceBatch` contains a mutable `entries` vector.
- `src/trace.jl:216-218` — `_detach` copies the outer schema vector shallowly and reuses `layout`.
- `src/sim.jl:1582-1587` — `trace(sim)` reuses the header and shallow-copies only the outer batches vector; every `TraceBatch` and its entries remain shared.
- `src/trace.jl:184-196` — recording appends batches while the run advances, but `trace(sim)` has no stopped-state gate or synchronization.

The replay payload probe also mutates the returned value:

```text
trace aliases register: schema="harness" => [:a, :b, :injected], entries=Pair{Int64, Any}[2 => 77.0]
```

A later `trace(sim)` observes both edits. This reproduction mutates exposed artifact fields rather than using a high-level mutator, so it should not be interpreted as ordinary simulation input. It is still a concrete violation of the source's detached-value promise, and it can silently corrupt a trace before persistence or replay. No reviewed test mutates a returned trace or requests it while recording.

**Required correction:** deep-detach every mutable header and batch container, or expose a genuinely immutable artifact. Restrict `trace(sim)` to a stopped/non-recording state, or synchronize a complete immutable snapshot handoff. Copying only the outer vectors is insufficient.

### P-04 — Interrupt handling contradicts the shutdown contract

**Severity: High design deviation for missing masking and operator-interrupt protocol.**

The control plane says an operator interrupt is caught only at loop unmask points and becomes the first-writer stop issuer (`docs/design/spec.md:6280-6298`). The shutdown section requires the current boundary to finish and includes a second-interrupt escape that collapses remaining joins (`docs/design/spec.md:6456-6467`, `6732` onward). The device contract also states that an `InterruptException` from a calling-task device is never reported as `DeviceCrash`.

Current behavior differs in three related ways:

- `src/sim.jl:1089-1099` catches any `InterruptException` thrown through the boundary body, abandons the unpublished frame, and converts it to `ControlRequestedStop(:interrupt)`.
- `src/devices.jl:362-376` catches device-loop exceptions and can report `InterruptException` as `DeviceCrash`; it has no calling-task forwarding rule.
- `src/devices.jl:451-471` implements the timed shared join deadline, but no second-interrupt collapse path.

`test/test_failures.jl:258-278` explicitly expects a component that throws `InterruptException` during stepping to stop gracefully and discard the interrupted frame. That correctly verifies the defensive catch required by §13.4; it does not establish the independent asynchronous masking requirement. The specification does not require this caught exception to become a model error. `test/test_failures.jl:280-288` covers first-writer issuer preservation, not mask placement or the second interrupt.

**Required correction:** decide the contract in one place before implementation. If the specification stands, mask interrupts across each boundary, unmask only at the named polling/wait sites, retain §13.4's defensive stop routing for an `InterruptException` reaching the catch, preserve the calling-task device exception rule, and implement the second-interrupt tail collapse. Keep the current defensive-catch tests and add separate tests of asynchronous deferral.

### P-05 — Model stop faces bypass termination-source priority

**Severity: Medium. Source-level counterexample.**

The ratified termination source order is control, then end time, then model stop face (`docs/design/spec.md:7741-7762`; `docs/design/decisions.md:7023-7053`, D-203). `_advance!` applies a different order:

- `src/sim.jl:1059-1070` checks `_stop_hit` before the loop and checks control then `t_end` only after that early return.
- `src/sim.jl:1078-1087` publishes a completed frame and immediately returns `ModelRequestedStop` when a stop face holds, before the next iteration can arbitrate control and `t_end` at that same boundary.

Thus a stop face that is already true at boundary zero wins even if control is pending or the end-time budget is zero. A face that becomes true on the exact final boundary also wins over `EndTimeReached`. `test/test_lifecycle.jl:91-212` verifies individual source cases, including a boundary-zero stop, but never makes sources coincide, so it cannot detect priority inversion.

**Required correction:** perform one source arbitration at every termination boundary in D-203 order. Add simultaneous control/end-time/face tests at boundary zero and after publication.

### P-06 — Lifecycle admission and roster freeze are check-then-act races

**Category: design robustness concern; source-level race window, not dynamically reproduced.** Concurrent lifecycle-mutating calls on the same simulation are not clearly promised by the permitted specification, which also states one-owner execution. Treat this as a contract clarification/hardening proposal, not a confirmed supported-use conformance defect.

The lifecycle freeze is implemented as an atomic status word, but admission is not an atomic transition:

- `src/sim.jl:322-329` loads lifecycle and checks allowed states.
- `src/sim.jl:912-921` (`run!`) and `1176-1195` (`step!`) perform validation and policy mutation after that check; `_run_body` stores `:running` only later at `963`.
- `src/sim.jl:642-657` (`init!`) and `756-827` (`replay!`) similarly do work between checking and claiming their active state.
- Roster operations begin with the same stopped-state check before mutating the roster (`src/sim.jl:1275` onward).

Two tasks can therefore observe `:initialized`, both pass `_assert_advanceable`, and enter shared policy/execution mutation before either stores `:running`. Likewise, `attach!`/`detach!` can pass their configuration gate just before `run!` freezes the roster. This defeats the intended single owner of live execution state and can expose the harness-recompilation seam in `src/roster.jl:232-248` to live staging.

`test/test_lifecycle.jl:65-89` waits until lifecycle is observably `:running` before issuing its rejected calls; the test deliberately removes the admission race. Roster freeze tests use the same established-running pattern. No test starts two lifecycle-changing services behind a barrier.

**Potential improvement:** reserve the transition with compare-and-swap (or one service mutex) before any policy, roster, store, or trace mutation. On pre-run validation failure, restore the former state through a defined rollback path. Include barrier tests for run/run, run/step, run/init, replay/run, and run/attach admission.

### P-07 — Control/pacing and related diagnostics are incomplete

**Severity: Medium missing family.**

Only stop and its issuer are implemented from §12.1. Pause/unpause, pace changes, margin changes, and condition-based paused waiting described at `docs/design/spec.md:6280-6307` are absent. The explicit per-frame yield with devices is present, and heartbeat/task-state publication is present, but the pacer's sleep/spin machinery is unavailable in this source area.

The missing pacer also leaves required observability absent:

- `docs/design/spec.md:6347-6366` requires `run!` to warn when the thread budget is tight and name the `julia -t` remedy.
- `docs/design/spec.md:6368-6384` requires pacer diagnostics alongside device heartbeat/task state.
- `src/dataplane.jl:129-152` and `196-217` define a closed diagnostic union/counter with nine kinds; `DebtReanchor`, `ThreadBudget`, and `UnboundedRun` are not representable.
- `src/dataplane.jl:350-370` and `src/sim.jl:1520-1529` expose only per-writer status, with no pacer fields.

The **thread-budget warning should be delivered with the pacer/control family**, because its sizing calculation and remedy depend on the final scheduling topology. Its absence remains a conformance gap even before paced execution is available. `UnboundedRun` belongs to the same deployment/run-entry completion work. These are missing behaviors, not evidence of a defect in the implemented unpaced arithmetic.

GUI attachment, GUI liveness, `peek`, and `run!(...; gui=true)` are also absent from §§11.7/12.6. Primary curation: these are unavailable specified capabilities. §16 defers the GUI authoring calling convention; that does not defer all §§11.7/12.6 semantics. Keep the capability gap separate from the unresolved API shape.

### P-08 — Did-you-mean candidates are incomplete for read binding failures

**Severity: Low–Medium.**

Attach-time resolution and typed rejection are otherwise correctly implemented. However:

- `src/bindings.jl:161-187` supplies `candidates` for an unknown `GetInput` but omits them for unknown `GetOutput` and `GetFace`.
- `test/test_bindings.jl:190-200` asserts candidates only for the root-input case and therefore codifies the incomplete coverage.

This falls short of §11.2's attach-style did-you-mean rule for every offending name. Populate candidates from the relevant component/output namespace for `GetOutput`, and from root output faces for `GetFace`; test the payload, not only the reason symbol.

## Subsection coverage

| Section | Observed implementation | Audit conclusion |
|---|---|---|
| §11.1 Task topology | Calling-task trait, per-device spawning, wrapper, join tail | Broad mechanism present; P-01 breaks run scoping after a timeout. |
| §11.2 Snapshots, log, reads | Atomic latest snapshot, bounded/redecimated log, compiled gather | Core path and endpoint preservation look correct; P-08 is the diagnostic gap. |
| §11.3 Claims and roster | Stable ids, claim admission, stopped-state attach/detach, harness recompilation | Claim mechanics present; atomic lifecycle admission remains unsafe under concurrent service entry (P-06). |
| §11.4 Staging and drain | Per-writer coalescing cell, normalization, atomic swap drain, deterministic writer order | Main protocol present. Concurrent roster/harness replacement is unsafe if P-06 admits overlap. |
| §11.5 Trace | Header, schemas, positional sparse records, frame count, kill switch | Main recording form present; malformed payload validation and artifact detachment fail (P-02/P-03). |
| §11.6 Device contract | Direction/trait checks, init-loop-shutdown bracket, mapping and gather | Most fail-fast checks present; interrupt classification deviates (P-04). |
| §11.7 GUI | No shipped GUI/device integration in reviewed source | Specified capability unavailable; authoring convention deferred to §16. |
| §11.8 Diagnostics | Bounded per-writer rings, suppression counters, heartbeat/task state | Implemented subset is coherent; pacer/run-entry kinds and status are absent (P-07). |
| §12.1 Control | Atomic first-writer stop word | Stop works; pause, pace, margin, and paused waiting absent (P-07). |
| §12.2 Scheduling | Explicit yield with a roster; liveness timestamps/task states | Pacer and startup thread warning absent (P-07). |
| §12.3 Next snapshot wait | Counter plus condition, predicate loop, newest-snapshot gather | Ordering and coalescing contract present. |
| §12.4 Shutdown | Init bracket, stop/unblock, shared join deadline, shutdown residue, error tail | Most tail structure present; stale handle authority and interrupt protocol fail (P-01/P-04). |
| §12.5 Scenario doctrine | No ordinary mid-run semantic mutation beyond staging/control | No separate defect found in the owned surface; missing control operations tracked in P-07. |
| §12.6 Lifecycle | Five states, warm re-init, step/run/replay transitions, terminal errored state | Nominal paths are tested; transition admission is not atomic (P-06). GUI capability unavailable; authoring API remains deferred. |
| §12.7 Replay | Ordinary boundary loop, trace-fed drains, discarded live staging, partial replay | Core replay path works for well-formed artifacts; entry validation is unsafe (P-02). |
| §13.5 Termination | Typed record, run overrides, localized/final boundary capture | Values and individual triggers present; coincident source priority is wrong (P-05). |
| §13.6 Loop failure | Ordinary tail, promoted last snapshot, `LoopError`, terminal `:errored` | Non-interrupt failure behavior is strong; `InterruptException` is carved out contrary to the text (P-04). |

## Design suggestions, separate from defects

1. **Make run authority explicit.** A small immutable run token shared by lifecycle, device handles, control, and publication waiters would make P-01 and stale-wait behavior easier to reason about than inferring authority from a mutable `running` bit.
2. **Use validate/build/commit for replay.** Parsing a trace into a temporary resolved world gives one clean boundary: before commit, the simulation is unchanged; after commit, every header invariant holds. This is simpler to test than compensating rollback.
3. **Make artifacts immutable at their public boundary.** Internal vectors may remain efficient during recording, but `trace(sim)` should freeze or deeply copy once. That also gives storage/export code a stable ownership rule.
4. **Centralize termination arbitration.** Have one function accept the simultaneous observations at a boundary and apply D-203 priority. It avoids early returns distributing priority across the loop.
5. **Centralize service admission.** One guarded transition primitive for init/run/step/replay/roster changes would prevent each API from recreating a subtly different check-then-act window.
6. **Validate semantic type names consistently.** `check_binding` and read diagnostics use `string(T)` (`src/roster.jl:74-88`, `src/bindings.jl:138-159`). Reusing the project's semantic type-name renderer would avoid module-qualified or environment-dependent labels. This is presentation debt, not a demonstrated behavioral failure.

## Ruled-out issues and positive checks

- **Log retention/redecimation:** the bounded log preserves required endpoints, including the `max=1` case; reviewed log tests exercise repeated reconfiguration. I found no periphery defect there.
- **Schema growth after roster changes:** old schema indices remain append-only and records resolve through their own schema; trace tests exercise continued recording/replay across changes.
- **Publication ordering:** the loop release-publishes `latest` before incrementing/notifying the boundary counter (`src/sim.jl:1488-1503`), while device wait uses a predicate loop (`src/devices.jl:315-328`). I found no lost-wakeup mechanism in the reviewed ordering.
- **Shared shutdown deadline:** `src/devices.jl:451-471` computes one deadline for the full join pass, so timeouts do not multiply by device count. P-01 concerns authority after abandonment, not deadline accounting.
- **Ordinary loop failures:** `test/test_lifecycle.jl:252-286` shows a non-interrupt `StepError` takes the full tail, promotes the last published snapshot, records residue, and leaves the simulation terminally `:errored`. That path matches §13.6.
- **Moved-loop exception propagation:** the run-body unwraps a failed loop task before completing failure handling; I found no additional swallowed-exception path in the reviewed topology.
- **Replay live staging:** the replay drain discards live staged batches with `ReplayDiscardedStaging`, and tests cover this warning. P-02 is specifically header entry validation before any write.
- **Boundary-zero replay pointer:** `to_boundary = 0` is a valid zero-budget replay after boundary-zero establishment; it was used intentionally by the probe and is not itself an error.

## Validation record and remaining limits

Focused probes are retained as review artifacts:

- `docs/reports/20260915_audit/probes/periphery_timedout_handle.jl` — confirmed stale handle `stage!` and `stop!` against the next trajectory.
- `docs/reports/20260915_audit/probes/periphery_replay_payload.jl` — confirmed missing-root acceptance, partial write before raw `KeyError`, and trace aliasing.

Both were run with `julia --project=test`; their material output is reproduced verbatim in P-01 through P-03. They are small executable reproducers rather than additions to the product test suite.

I did not stress the unsynchronized lifecycle admission race because a deterministic hook would require instrumenting production code or relying on probabilistic scheduling. The source has an unambiguous check-to-store window, and existing tests explicitly wait until after it. I also did not exercise real OS Ctrl-C delivery; P-04 is established by the missing mask/unmask machinery. The unit test using a thrown `InterruptException` is valid defensive-catch coverage, not evidence of asynchronous masking.

No external sources were used. No files outside the permitted source/design/test scope were inspected for conclusions, and no product code was changed.

## Primary-review curation note

The primary reviewer corrected the interrupt-test interpretation and unsupported
HEAD claim above, and downgraded P-06 from a conformance defect to an unverified
same-simulation concurrency hardening proposal. P-05 still requires the primary
reviewer's targeted priority check. The curated top-level report controls final
severity and classification.
