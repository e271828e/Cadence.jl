# Cadence conformance and design audit

Audit opened 2026-09-15; original reconciliation 2026-09-16;
**finding refresh 2026-09-17/18, finalized against `2938a0`.**

## Current assessment

**Seven original findings can be retired:** F-08, F-09, G-04, G-05, G-06,
G-08 and G-09. F-05 and G-07 are partially fixed; G-11 is reduced to two residual payload
contexts.
Eleven correctness/robustness findings remain open (including partial F-05),
and eight capability/diagnostic findings remain open (including partial G-07
and G-11).
The contract-arity ambiguity is settled by D-249 and its implementation is now
complete. D-252 and its implementation also retire the auto-publication
precedence question. Two stale-prose corrections and the timeout-survivor
design concern remain; allocation and heartbeat behavior already have settled rulings.

Validation at `2938a0` is recorded in the [latest validation](refresh_20260918/validation.md).
The earlier **2,828/2,828** package result belongs to `7b1c1e8`.

The most consequential runtime findings still reproduce: silently discarded
handler keys, malformed replay installation, timeout survivors affecting later
trajectories, trace aliasing, wrong termination priority, and extreme time-bound
conversion. Mutable numeric port isolation and the service-validation findings
also remain. Missing capabilities still include pacing/control, linearization,
service relocation and GUI integration.

### What changed since the original report

| Disposition | Original item(s) | Reason |
|---|---|---|
| Retire | F-08 | Nested component containers now raise `ContainerNested`. |
| Retire | F-09 | Enum ports and root probe values are supported, including mixed enum/walking activations. |
| Retire | G-04 | SCC membership, wires and traced cycle classification are implemented. |
| Retire | G-05/G-06 | `DeadStage`, `MissingProbeValue` and enum synthesis are implemented and tested. |
| Narrow, keep open | G-07 | Original stage/declaration/bundle failures are fixed under D-248; authored `probe_value` exceptions still escape raw, leaving a narrower framing-scope issue. |
| Retire | G-08/G-09 | `ProbeDual` and the D-246 `DeclarationShadowed` check are implemented. |
| Narrow, keep open | F-05 | Device-loop interrupt forwarding exists; boundary masking and the remaining operator protocol do not. |
| Narrow, keep open | G-11 | The committed payload sweep closes most omissions. Attachment binding-entry context and replay build/trace provenance remain missing. |
| Retire | Documentation item 3 | D-249 assigns contract arity to `TierSignatureMismatch`; the final payload sweep implements and tests it. |
| Retire | Documentation item 4 | D-252 removes auto-publication; source and tests now use explicit stage returns. |
| Keep open | Other findings | No sufficient implementation or design change closes them. |

**Do not conflate adjacent fixes:** explicit-detach refusal (D-244) does not
revoke a still-attached timeout survivor's authority (F-03); build/runtime
framing (D-248) does not validate handler return keys (F-01) or preserve an
interrupt swallowed inside condition conversion (F-12).

### Review boundary and evidence

This is a bounded finding refresh, not another exhaustive audit. It compares
original target `6986ad41b5f04c671fc6b321b4bab6df54520a40` with committed
`66c49f09b4cfc3ddb0b62523e979cd0537ba7c8c`, followed by a bounded review of
the committed diagnostic delta to `7b1c1e850515dad77942973e9ae87ebcc2ac7a6c`,
then the port-model and pipeline-design delta to final target
`2938a025c05bc136dd9f76f64cb42f89f4986d4c`. The user explicitly authorized
`docs/design/pending.md` for this follow-up, alongside the original source,
tests and three design documents. No older audit was consulted; references to
it inside `pending.md` were not followed. Removal from `pending.md` alone is
not closure evidence.

Diagnostic source/tests were edited concurrently during the first refresh pass.
Those edits were subsequently committed. The final source/test tree is clean;
the additional 24-file delta (475 insertions/230 deletions) was reviewed for its
effect on these findings, with new package and focused-probe runs. The old
2,514-assertion result belongs to `6986ad4`, not the new checkout. See
[refresh validation](refresh_20260917/validation.md) for revision hashes, the
superseded mixed-worktree test failure, and final validation.
That checkpoint observed HEAD `6b92356` with identical audited inputs. The later
17-file permitted delta (1,575 insertions/970 deletions) changes the port model
and ratifies D-250–D-258. Its [separate validation](refresh_20260918/validation.md)
preserves the new baseline and results. The referenced pipeline roadmap was
outside scope and was not consulted.

The [original report](refresh_20260917/original_report.md), original
[coverage ledger](coverage.md), [validation](validation.md), and subsystem
reviews remain historical evidence. Detailed refresh reviews cover
[build/storage](reviews/08_build_refresh_20260917.md),
[services](reviews/09_services_refresh_20260917.md),
[design/payloads](reviews/10_design_refresh_20260917.md), and
[runtime/periphery](reviews/11_runtime_refresh_20260917.md).

Unless explicitly refreshed below, detailed source line numbers and reproduction
logs in the retained finding narratives are historical locations at `6986ad4`.
The refresh reviews supply current locations and confirmation. IDs are preserved
so follow-up discussions do not lose their reference.

## Correctness and robustness findings

### F-01 — High: runtime handler return keys are not fully checked

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement:** §5.2 handler return law and §9.5 require the runtime write to
validate the whole return, including its top-level store keys. A branch first
executed after the probe must not evade conformance.

**Evidence:** `src/executor.jl:355` (`_latch!`) only looks for `x` and `m`.
It ignores every other key. A handler valid at the build probe but returning
`(unknown=true,)` when its event fires completes successfully without updating
the intended mode. A late scalar return instead produces a raw `MethodError`
cause. Build-time handler validation is stronger than the runtime path.

**Impact and remedy:** a hybrid transition can silently disappear. Validate the
return's kind and complete top-level key set before any store write, preserving
partial `m` and optional legal stores. Add late-branch tests for unknown keys,
undeclared stores, and scalar returns. Nested-field conformance tests do not
cover this gap.

**Verification:** [probe](probes/execution_handler_key_drift.jl),
[2026-09-16 output](validation/execution_handler_key_drift-final.log),
[execution review EXE-03](reviews/02_execution.md).

### F-02 — High: malformed replay headers can silently preserve old inputs or partly overwrite the target

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement:** §§11.5/12.7 require a complete recorded initial world and loud,
up-front replay validation. A refused artifact must not partly install itself.

**Evidence:** `src/trace.jl:324` checks the header's layout metadata, but does not
prove its actual state/root payload agrees. `src/sim.jl:792–805` then writes the
payload into live stores. A header omitting root `b` is accepted and preserves
the target's old `b=20`. A header containing `a=>99` followed by unknown `zzz`
writes `a`, then throws `KeyError`: live `a=99`, published `a=10`, lifecycle still
`initialized`.

**Impact and remedy:** replay ceases to depend solely on the recording and can
leave a supposedly usable target inconsistent. Validate exact store shapes,
root membership/uniqueness and value compatibility against the target before
writing; normalize into temporary state, then commit. Include malformed length,
duplicate/missing/extra root, negative recording length and no-write-on-refusal
cases in the regression matrix. Only the two root cases above were dynamically
reproduced; the broader matrix is recommended follow-up coverage.

**Verification:** [probe](probes/periphery_replay_payload.jl),
[2026-09-16 output](validation/periphery_replay_payload-final.log),
[periphery review P-02](reviews/03_periphery.md).

### F-03 — High: timed-out device tasks retain authority over later trajectories

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement:** §§11.1/12.4 make device tasks run-scoped and describe fresh
resource acquisition on the next run, while also permitting bounded join
abandonment.

**Evidence:** `src/devices.jl:451–471` warns after the join deadline but does not
revoke the surviving task's handle. The handle still addresses the shared
control plane and writer. `src/sim.jl:1012` clears the registry even though the
task may still exist. A blocked device released after a new `init!` successfully
stages `a=77` into a later deviceless step. Another survivor calls `stop!` and
terminates the new trajectory before it advances.

**Refresh distinction:** D-244 guards `stage!`/`report!` after explicit `detach!`;
it does not revoke the still-attached handle when its task exceeds the join
deadline. Both timeout-survivor cases still reproduce.

**Impact and design choice:** this is a fault-containment failure after a device
has already violated its loop/unblock obligations; it is not the normal
cooperative-device path. Keep surviving tasks accounted for. Run-generation
checks can revoke stale handle authority, but cannot alone prevent an old task
and a fresh `init!` from sharing the device's external resources. Consider
quarantining restart until survivors exit, or explicitly defining another
timeout disposition. Resolve the specification's unconditional no-survivor
wording against its abandonment path. This audit does not choose that policy.

**Verification:** [probe](probes/periphery_timedout_handle.jl),
[2026-09-16 output](validation/periphery_timedout_handle-final.log),
[periphery review P-01](reviews/03_periphery.md).

### F-04 — Medium: trace values share mutable containers with the recording

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement/evidence:** the primary trace supports inspection and edited-input
replay (§§11.5/12.7); source documentation explicitly promises a detached value.
`trace(sim)` (`src/sim.jl:1582–1587`) shares its header and shallow-copies batches.
`_detach` (`src/trace.jl:216–218`) also shares nested schema/layout containers.
Editing a returned schema or batch entry changes a subsequent `trace(sim)`.

**Impact and remedy:** an apparently separate artifact can corrupt the retained
primary record. Copy its mutable containers to the promised ownership boundary,
or explicitly expose an immutable representation. This reproduction edits
publicly reachable artifact fields; it is not an ordinary staged model write.
The accessor also has no stopped-state guard; a concurrent-read race is a
source-level concern, not a reproduced stress-test result.

**Verification:** same [replay probe/output](validation/periphery_replay_payload-final.log);
[periphery review P-03](reviews/03_periphery.md).

### F-05 — High: the specified operator-interrupt protocol is incomplete

**2026-09-18 status: partially fixed; still open.** See the refresh review for current evidence.

**Requirement:** §12.4 and D-132 require masking across the boundary sequence,
delivery at consistent unmask points, calling-task device forwarding, and a
second-interrupt shortcut through remaining joins.

**Evidence:** `src/sim.jl:1059–1099` has no `disable_sigint` boundary mask and can
catch an interrupt after partly modifying stores, retaining the old final
snapshot. The join tail still lacks second-interrupt collapse. **The original device-wrapper
claim is retired:** `src/devices.jl:377` now forwards a loop-body interrupt as
`:interrupt` without reporting `DeviceCrash`, with a dedicated device test. The remaining required machinery is absent
by source inspection; no real OS signal was injected during this audit.

**Important correction:** the synthetic `InterruptException` tests in
`test/test_failures.jl:258–288` correctly test §13.4's defensive catch. They are
not nonconformant and should remain. They simply do not test asynchronous
masking. Implement and test that independent protocol without changing the
specified defensive stop routing into a model-error rule.

**Evidence:** [execution EXE-02](reviews/02_execution.md), corrected
[periphery P-04](reviews/03_periphery.md).

### F-06 — Medium: coincident stop sources use the wrong priority

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement:** §13.5 and D-203 order control, end time, then model stop faces
when sources hold at the same boundary.

**Evidence:** `_advance!` (`src/sim.jl:1059–1087`) checks a holding face before
its initial control/end-time arbitration and returns immediately on a face after
publication. Three reproduced cases record `ModelRequestedStop`: pending
control plus a face at boundary zero; end time plus a face at boundary zero;
and end time plus a face at frame one.

**Remedy:** centralize boundary source arbitration and test coincident causes,
including localized boundaries. Individual-source lifecycle tests do not pin
the priority contract.

**Verification:** [probe](probes/termination_priority.jl),
[2026-09-16 output](validation/termination_priority-final.log).

### F-07 — Medium: extreme finite time bounds are not validated after conversion

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement:** finite `t_end` has finite-bound semantics; `Inf` explicitly
means open-ended execution (§§12.4/13.5 and Appendix B).

**Evidence:** `_t_bound`/constructor convert to `Float64` without checking the
converted result; `_frames_to` uses `ceil(Int, ...)` without range handling
(`src/sim.jl:156–209`, original locations). These are existing-code paths;
D-255 now requires per-advance validation and removes constructor stop policy,
but that redesign is not implemented. A finite `big"1e1000"` becomes `Inf`; `t_end=1e300`
produces raw `InexactError` before a run starts.

**Remedy:** define representability limits and reject out-of-range finite
values with a structured argument diagnostic at the per-advance binding site
required by D-255, rather than preserving the superseded constructor policy.
Check partial-advance duration conversion on the same basis. These are extreme
inputs, not a demonstrated error at ordinary simulation horizons.

**Verification:** [probe](probes/execution_time_bounds.jl),
[2026-09-16 output](validation/execution_time_bounds-final.log).

### F-08 — Nested component containers — retired

**2026-09-18 status: retired by implementation.**

`ContainerNested` now rejects a component-bearing container nested inside another container. The walker distinguishes this shape from ordinary inert parameter data, and the assembly tests cover the refusal. See [build refresh](reviews/08_build_refresh_20260917.md) for source and test locations.

The original reproduction and rationale remain in the [historical report](refresh_20260917/original_report.md).

### F-09 — Enum-valued ports — retired

**2026-09-18 status: retired by implementation.**

The leaf walk treats enums as atomic pinned leaves; synthesis supplies the first instance. Flatten/reconstruction and non-nominal embedding now preserve enum leaves, including a compound value containing both an enum and a walking scalar. Dedicated build/leaf tests cover these cases. See [build refresh](reviews/08_build_refresh_20260917.md).

The original reproduction and rationale remain in the [historical report](refresh_20260917/original_report.md).

### F-10 — Medium: statically invalid read indices survive resolution

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement/evidence:** §§14.4/14.10 make the optional vector-component index
part of the resolved selector. `_check_index` (`src/readers.jl:287–294`) rejects
an index on a scalar but does not reject index 3 on a declared `SVector{2}`.
Compilation succeeds; `gather` then throws raw `BoundsError`.

**Remedy:** check schema-known axes during resolution and emit the located
`TapResolution`. Define the policy for other indexable declared types explicitly.
Test zero/negative/too-large indices as well as the existing valid-vector and
scalar-index cases. The demonstrated consequence is late unstructured failure,
not a corrupted result or a write to the live simulation.

**Verification:** [service probe](probes/services_confirmed_gaps.jl),
[2026-09-16 output](validation/services_confirmed_gaps-final.log),
[service review finding 3](reviews/04_services.md).

### F-11 — Medium: plainly non-callable trim fields bypass problem validation

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement/evidence:** §14.7 specifies callable `condition` and `residuals`
fields; §14.8 assigns malformed problems to setup diagnostics. The collecting
setup pass (`src/trim.jl:389–409`) does not check those call seams. A correctly
shaped problem with `condition=42` leaks raw `MethodError`.

**Remedy:** diagnose inapplicability against the actual decision/read tuple
shapes with field context, while preserving the distinction between invalid
callability and a legitimate user function throwing from its body. This is a
bounded validation/error-locality gap; no failed-solve live-state mutation was
demonstrated. The specification's explicit malformed-case list omits callable
misuse, so extend/clarify that list when completing the check.

**Verification:** [2026-09-16 service output](validation/services_confirmed_gaps-final.log),
[service review finding 4](reviews/04_services.md).

### F-12 — Medium: condition conversion converts an interrupt into a data error

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement/evidence:** §14.8 requires an interrupt during solve/setup to
unwind without commit. `_convert` (`src/conditions.jl:388–393`) catches every
exception. A supplied conversion that throws `InterruptException` becomes a
collected `ConditionResolution` failure and resolution continues.

**Remedy:** preserve interrupt control flow through conversion/validation
wrappers and catch only the failures intended to mean unconvertible data.
The probe uses a synchronous conversion-thrown exception; it establishes the
catch behavior, not timing characteristics of operating-system SIGINT delivery.

**Verification:** [2026-09-16 service output](validation/services_confirmed_gaps-final.log),
[service review finding 5](reviews/04_services.md).

### F-13 — High: mutable numeric ports defeat snapshot and live-cell isolation

**2026-09-18 status: open.** See the refresh review for current evidence.

**Requirement:** §§4.1/4.3 and D-237 require immutable port values and reject
mutable types reached by the leaf walk.

**Evidence:** `_mutable_position` (`src/leaves.jl:86–95`) accepts every subtype
of `Real` before testing mutability. A `BigInt` port consequently builds. A
custom mutable `Real` also builds; mutating the value returned by
`port(latest(sim), "c", :out)` changes both that retained snapshot and the live
cell read by `port(sim, "c", :out)` from 1 to 9. Publication copies the containing
buffer, leaving the mutable leaf shared.

**Impact and remedy:** a model using a prohibited but admitted type can let a
reader change published history and producer state. Check mutability before the
numeric-leaf shortcut and test nested numeric leaves as well. The source comment
explicitly accommodates mutable `BigFloat`; any desired value-like numeric
exception needs an explicit ownership/copying contract rather than admitting
all mutable `Real` types. Sanctioned immutable handles around frozen data remain
a separate case.

**Verification:** [probe](probes/storage_diagnostic_gaps.jl),
[2026-09-16 output](validation/storage_diagnostic_gaps-final.log),
[storage review SD-01](reviews/05_storage_diagnostics.md).

## Missing specified capabilities and diagnostic behavior

Open rows remain gaps against settled design. Retired rows preserve the original
IDs and identify the delivered replacement. Deferred deliverables remain separate.

| ID | Priority | Gap and evidence | Completion/test direction |
|---|---|---|---|
| G-01 | High | **Real-time pacing and control family absent.** §§10.7/12.1/12.2 require pace/margin, pause, deadlines, re-anchoring, debt handling and related status. The current loop only yields with devices; pacing and the `DebtReanchor`, `ThreadBudget`, `UnboundedRun` kinds are absent. D-255’s `Run` and per-advance `StopPolicy` are also pending; constructor-owned stop defaults are no longer the target design. | Implement the settled family with a controllable monotonic-clock/wait seam; verify paced/unpaced trajectory identity and deadline/debt behavior. See EXE-01/P-07. |
| G-02 | High | **Linearization is absent.** §14.10 specifies taps, seeded evaluation, labeled matrices and pure scratch execution. No `linearize` entry point exists. | Build on service scratch stores and compiled reads/writes; validate frozen/unseedable taps and no-live-mutation before numerical matrix tests. |
| G-03 | Medium | **Service relocation is absent.** §14.9 requires `at(prefix, problem)` and relocated read sets. Both currently reach `ConditionNodeMisuse`. | Add the problem/read relocation algebra and nested relocation tests; do not confuse condition-node relocation, which exists, with this missing surface. |
| G-04 | Retired | SCC extraction excludes downstream acyclic tails, retains wires and classifies clusters using the traced graph (D-245). | See the build refresh and new cycle-classification tests. |
| G-05 | Retired | Both output-stage probes now reject explicit empty stages as `DeadStage`. | Stage-specific and event-related tests exercise the new checks. |
| G-06 | Retired | Enum-first synthesis and collected `MissingProbeValue` exist. An override’s own `MethodError` is distinguished from missing framework synthesis. | See root-probe tests and the build refresh. |
| G-07 | Medium; partial | **The original framing mechanisms are fixed, with a narrower residual.** D-248 frames declarations/component probes and classifies bundle misses, including at runtime. An authored `probe_value` override still runs bare and its own `MethodError` escapes raw (`2938a0:src/build.jl:550–558`), as the test requires. | §13.2 says every authored method invoked by build is framed. Clarify whether synthesis hooks are excluded or frame them with face/function context. Do not reopen the fixed bundle/stage cases; F-01 is a separate return-validation gap. |
| G-08 | Retired | The canonical concrete `ProbeDual` and `ProbeTag` are supplied and exercised by the documented activation-build form. | A public type is now present; the broader every-component CI sweep is a separate coverage policy. |
| G-09 | Retired | D-246 introduces fail-fast `DeclarationShadowed` before classification, with foreign-binding tests. | Retired under the settled diagnostic design, rather than the old proposal to extend missing-class/store errors. |
| G-10 | Medium | **Specified artifact renderings and provenance are incomplete.** D-253/D-254 introduce `Structure`, `Dataflow`, `Deployment` and `Schedule`; D-257 requires typed `show` renderings for these and `Build`, including anchor/`A₀`, component/rate-scope and execution-order tables. These artifacts/renderings are pending. | Implement the named renderings and face routing provenance. Test the complete hyperperiod chart at ≤100 base ticks and length plus omission notice above it. Grid explanations and `GridUtilization` belong to deployment under D-254. |
| G-11 | Low; partial | **Two payload contexts remain missing.** `AttachUnknownFace` now has device and binding types but no required binding-entry context. `ReplayHeaderMismatch` still lacks the build/trace provenance required by Appendix C. | Retire the former container, class/tier, legality-list, stop-site and handler-event omissions: the payload sweep fills them. D-252 deliberately removes the producer column from `ProducedByTwoStages`; the two stage identities are implicit, so that removal is not a regression. D-249 removes the face-origin/inner-time requirements and its arity rule is implemented. See the final design-review addendum for exact payload and test references. |
| G-12 | Low | **Root probe values survive into built runtime cells.** §9.3 says these are probe-scoped; layout retains them and compiler scatters them before `init!`. | Clarify pre-init observation or remove runtime seeding from fabricated roots. Current totality/lifecycle gates overwrite them before normal advancement; no initialized-trajectory defect is claimed. |
| G-13 | Medium | **GUI integration semantics are unavailable.** §§11.7/12.6 specify liveness, peek and run attachment behavior; no corresponding implementation is present. | Preserve these semantic requirements while settling the authoring calling convention explicitly deferred to §16. A finalized API cannot be inferred from that section. |

Build details and reproductions: [01_build](reviews/01_build.md).
Execution/periphery details: [02_execution](reviews/02_execution.md),
[03_periphery](reviews/03_periphery.md).
Service details: [04_services](reviews/04_services.md).
Diagnostic inventory: [05_storage_diagnostics](reviews/05_storage_diagnostics.md).
Appendix C now has **83 named rows**, with 77 implemented diagnostic subtypes
and the separate `StepError` carrier. The original 79-row/eight-absent count is
historical. Four originally missing kinds are now implemented: `DeadStage`, `MissingProbeValue`,
`BundleFieldError` and `UserCodeFraming`. `GridUtilization`, `DebtReanchor`,
`ThreadBudget` and `UnboundedRun` remain absent, joined by D-251’s new
`EmptyFaceSelection`: five kinds are missing. The four added rows since the
original audit are `ContainerNested`, `DeclarationShadowed`,
`StoreNotNamedTuple` and `EmptyFaceSelection`. The [design refresh](reviews/10_design_refresh_20260917.md)
records the current count and absence list. The implementation-subtype fixture check still cannot
prove completeness against an independent normative list.

## Documentation conflicts and open design choices

1. **Allocation prose correction remains (medium; behavior settled).** §7.5 claims inline/amortized-zero
   snapshot retention, whereas §11.2 and D-023 require per-boundary allocation
   and retained references; D-241 explicitly accepts the status vector's small
   allocation. The implementation follows the latter decisions. Warmed tiny-model
   probes allocate on publication with logging both on and off. Correct the
   prose; do not call this a zero-allocation phase-body regression.
2. **Heartbeat prose correction remains (low; behavior settled).** §11.2 still says frame top, while
   §11.8/D-240 require publication-time capture. Source follows D-240. Correct
   the stale §11.2 summary; no new capture-location ruling is needed.
3. **Contract arity taxonomy — retired by ruling and implementation.**
   D-249 assigns contract arity violations to `TierSignatureMismatch` and
   reserves `DeclarationOnWrongTier` for the other specified violations.
   The final diagnostic sweep implements the arity arm, including found and
   mandated signatures, and updates the tier/diagnostic tests. The first
   refresh's code-gap qualification at `66c49f0` is now retired too.
4. **Auto-publication precedence — retired by ruling and implementation.**
   D-252 removes automatic publication altogether. Every port must be returned
   by stage 1 or stage 2; exposed state is returned explicitly from
   `output_state`. Source, executor entries and fixtures now follow that rule,
   so the old precedence conflict no longer applies. `ProducedByTwoStages`
   intentionally carries no producer column because the two stages are fixed.
5. **Join-timeout disposition (high design concern).** The promise that no task
   or resource survives return cannot hold unconditionally alongside arbitrary
   device-code abandonment. F-03 demonstrates the dangerous consequence. Define
   survivor authority, restart eligibility and cleanup responsibility together.

See the [design refresh](reviews/10_design_refresh_20260917.md) for current
references and the [original document review](reviews/07_grounding_and_document_consistency.md)
for historical evidence. Allocation and heartbeat are prose corrections, not unresolved implementation
choices. Timeout-survivor authority still needs explicit resolution; an empty
ruling heading in `pending.md` does not close the demonstrated concern.

## New settled design awaiting implementation

D-250–D-258 add obligations beyond the original audit’s finding inventory.
Only D-252’s explicit port model is delivered at this revision. The remaining
pipeline redesign is recorded as pending and the inspected code still uses the
older build/simulation representation:

- D-250: artifact-owned warnings, scoped collection, `warnings` accessors and
  roster-entry ownership for `EmptyGreedyClaim`.
- D-251: exclusive `except`/`only`/`select` selectors, `:multiple_selectors`
  validation and `EmptyFaceSelection`. Required-faces declarations are optional
  future sugar, not an owed capability.
- D-253/D-254: `Structure`, `Dataflow`, `Events`, `Deployment` and `Schedule`
  artifacts, structural consumers and deployment-owned grid diagnostics.
- D-255/D-256: `Run`, fresh run-owned objects, split trace data, per-advance
  `StopPolicy` and the six-owner `Simulation` organization.
- D-257: the explicit artifact renderings described in G-10. D-258 also changes
  terminology: schedule means tick timing; execution order means stage order.

These are acknowledged implementation gaps, not additional independently
exhaustive findings. They inform G-01/G-10/G-11 and the recommended remedies.
In particular, the future trace/run organization does not retire F-02/F-04,
and moving `join_timeout` into `Control` does not revoke a survivor’s authority
(F-03). Existing-code reproductions remain relevant; constructor stop-policy
examples describe the current implementation, not the new target API. See the
[design addendum](reviews/10_design_refresh_20260917.md) for the precise rulings.

## Potential improvements, separate from conformance defects

- **Define same-simulation service concurrency.** Admission currently checks
  lifecycle before later mutations/transition to `running`. A second caller can
  theoretically pass the same check. The specification does not clearly promise
  concurrent lifecycle mutators on one simulation, so this is a contract and
  hardening proposal, not a reproduced supported-use defect. A service mutex or
  atomic reservation is worth considering if such calls should be supported.
- **Make long-run trace growth observable.** Log retention is bounded, but the
  primary trace intentionally grows with drained batches. D-255’s planned
  `Run.trace` separates header, schemas and batches; that representation is not
  implemented yet. Expose batch count and
  estimated memory/growth; evaluate lossless streaming with the explicitly
  deferred persistence design. Do not silently thin primary data.
- **Test semantic boundaries as small matrices.** Prioritize build-vs-runtime
  returns, malformed replay refusal atomicity, timeout-vs-restart, coincident
  termination sources, selector resolution-vs-gather, and nominal-vs-Dual
  activations. As D-250–D-257 land, include artifact-warning ownership, per-advance
  policy, and the chart guard. These interactions produced more actionable defects than another
  repetition of ordinary successful runs.
- **Keep diagnostic inventory executable.** Map each Appendix C kind and
  required payload to tests. Hundreds of rendering assertions do not establish
  complete occurrence, collection-policy or provenance coverage.

## Deliberately unimplemented or out of scope

- DAEs, SDE integrators and unconditional step hooks are explicit exclusions.
- Sampled-data differentiation, tick-triggered continuous handlers, checkpoints
  and other explicitly recorded extensions are not counted as missing current
  mechanisms.
- The standard component library is explicitly a migration-phase deliverable;
  fixtures are not evidence that those blocks are shipped.
- The GUI authoring calling convention is deferred to migration (§16). The
  unavailable specified GUI semantics are recorded separately as G-13.
- On-disk log/trace persistence and external FlightPhysics/FlightApps migrations
  are deferred/outside the permitted corpus. No claims about those repositories
  or previous audit conclusions are made.

## Suggested order of remaining work

1. Close silent-result and isolation defects: F-01, F-02, F-03 and F-13; protect
   trace ownership alongside replay admission.
2. Pin termination/interrupt semantics with targeted tests, then implement the
   missing operator protocol and correct priority arbitration.
3. Complete service validation and mutable numeric port isolation; enum support
   and nested-container rejection are already delivered.
4. Fill settled capability gaps: pacing/control, service relocation and
   linearization, in an order chosen by actual users.
5. Align diagnostic/inspection contracts and conflicting documentation; retain
   the coverage ledger as a checklist for focused regression additions.

The original audit was broad; this refresh rechecks its findings. Neither is a
proof for all numerical models, schedules, devices or interleavings. The original
coverage ledger remains dated evidence; the refresh reviews and validation record
establish the narrower current conclusions above.
