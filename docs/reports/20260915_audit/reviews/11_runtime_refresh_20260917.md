# Runtime and periphery refresh — 2026-09-17

## Boundary and evidence

Committed comparison target: `66c49f09b4cfc3ddb0b62523e979cd0537ba7c8c`,
after original audit target `6986ad4`. `pending.md` is explicitly authorized for
this follow-up. Source, current design and tests determine the verdict; absence
from that register does not retire a finding. The checkout has concurrent
uncommitted diagnostic changes. Runtime files cited below were unchanged by
those edits when inspected. Focused probes ran in that working checkout, so
logs establish the exercised behavior, not a frozen-commit package gate.

## Dispositions

| Finding | Status | Current evidence |
|---|---|---|
| F-01 | Open | `src/executor.jl:355` still only inspects `x`/`m`. The refreshed handler probe confirms the silently ignored unknown key and the scalar return's raw `MethodError` cause. Its nominal scalar-handler branch was made nonempty to satisfy the newly implemented build-time `DeadStage` check; the original runtime defect remains. |
| F-02 | Open | `src/trace.jl:324` still checks header metadata without proving actual payload membership. `src/sim.jl:792` installs it into live stores. Missing root retains `b=20`; extra root raises `KeyError` after live `a=99` while published `a=10`. |
| F-03 | Open; distinguish D-244 | `src/devices.jl:471` still abandons a task without revoking run authority; `src/sim.jl:1012` clears the task registry. Probe still stages `a=77` and stops a later trajectory. D-244 only marks a handle detached at explicit `detach!`, guarding `stage!`/`report!` (`src/devices.jl:177,266,310`, `src/sim.jl:1366`). The probe's device remains attached, so no guard changes its outcome. `stop!(handle)` still addresses shared control directly. |
| F-04 | Open | `trace(sim)` at `src/sim.jl:1618` shares the header and shallow-copies batches; `_detach` at `src/trace.jl:216` shares nested containers. Probe still mutates subsequent returned trace schema and entries. |
| F-05 | Partial fix; keep open | `src/devices.jl:377` now forwards a loop-body `InterruptException` as `:interrupt` without a crash report. Added `test/test_devices.jl:329` checks this path. Retire the old assertion that this wrapper lacks discrimination. Boundary masking/operator entry and second-interrupt join collapse remain absent (`src/sim.jl:1059`, `src/devices.jl:471`); `pending.md` confirms masking/entry are still outstanding. No actual OS signal was injected. |
| F-06 | Open | `_advance!` (`src/sim.jl:1059`) still lets model faces precede higher-priority control/end-time sources. All three original collision probes still return `ModelRequestedStop`; current §13.5 retains the priority rule. |
| F-07 | Open | Constructor and `_t_bound`/`_frames_to` (`src/sim.jl:166,189,204`) retain unchecked Float64/range conversion. Both original extreme-time examples reproduce. |
| G-01 | Open | No real-time pacer/control family was added; pending §10.7/§12 and the absent warning kinds agree with the source. |
| G-13 | Open | GUI integration remains unavailable; the authoring calling convention remains a separate migration decision. |

## Validation

[Runtime runner summary](../refresh_20260917/runtime-probes.log): all five
scripts exit zero, reproducing the relevant defects. Detailed logs are
[handler](../refresh_20260917/handler_probe.log),
[time bounds](../refresh_20260917/execution_time_bounds.log),
[replay/trace](../refresh_20260917/periphery_replay_payload.log),
[timeout survivors](../refresh_20260917/periphery_timedout_handle.log), and
[termination priority](../refresh_20260917/termination_priority.log).

A detached handle refusal does not prove timeout-survivor containment. A
synthetic loop-body interrupt test does not prove masking under asynchronous
operator delivery. These are the two most important non-equivalences when
retiring the old periphery statements.

## Final delta reconciliation — 2026-09-18, `7b1c1e8`

The runtime part of the committed delta after `66c49f0` carries handler event
identity through `EventEntry`, state/mode writes and conformance diagnostics;
fills legal lifecycle lists and stop-binding sites; and supplies device names
to attachment/read diagnostics. It does not change the handler's top-level key
check, replay admission, trace detachment, timeout revocation, boundary masking,
termination arbitration or finite-bound conversion. None of F-01–F-07 closes;
F-05 retains its already-recorded partial forwarding fix.

Fresh [final runtime probes](../refresh_20260917/runtime-probes-final.log)
include the service probe in addition to the five original scripts. The final
validation document records the package result. Source/test hashes are frozen
in `refresh_20260917/final-baseline.json`; the diagnostic-payload change is
reviewed separately in the design review's latest addendum.

## Port-model/design delta — `2938a0`

The subsequent delta removes executor `PublishEntry` and changes build/tracer
classification to explicit stage returns. The handler latching mechanism is
unchanged. Simulation, devices, trace, readers, conditions and leaves have no
source changes relative to `7b1c1e8`; the retained runtime mechanisms remain.
All seven retained-behavior scripts completed again at the new frozen baseline:
[runner results](../refresh_20260918/runtime-probes-final.log).

D-255 specifies a new `Run`, trace split and per-advance `StopPolicy`; D-256
moves fields to their owners. These are pending design changes, not evidence
that replay/trace aliasing, stop priority, timeout-survivor authority or numeric
bound handling are fixed. Current constructor-policy examples are observations
of the existing implementation, not recommendations to retain that API.
D-250 warning ownership likewise does not implement pacing or operator control.
