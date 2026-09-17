# Cadence conformance and design audit

Audit opened 2026-09-15; reconciled with the checkout on 2026-09-16.

## Executive assessment

The implementation has substantial, tested support for hybrid execution,
multirate scheduling, localization, staged input, replay, conditions and trimming.
The test suite nevertheless leaves important failures unexercised. The most
consequential reproduced defects are a silently discarded event-handler return,
non-atomic admission of malformed replay data, and a timed-out device retaining
authority over a subsequent trajectory. Missing specified capabilities include
real-time pacing/control, linearization, and service relocation.

The final package gate passes **2,514/2,514 assertions**. Nine focused probes
reproduce gaps outside those assertions. The findings below include thirteen
correctness/robustness defects, thirteen capability/diagnostic gaps, five
documentation conflicts or design choices, and separate improvement proposals.
These categories overlap where one missing mechanism causes several symptoms.

This report is the **curated conclusion**. The subsystem reviews retain detailed
working evidence and original finding identifiers; their initial severities and
interpretations do not override the dispositions here. Tests that successfully
reproduce a defect are evidence of that defect, not passing conformance tests.

### Revision boundary

- Initial baseline: `865521a0f7be6894b1688925bb349dcbadd06539`.
- Comprehensive subsystem reviews were reconciled to
  `f941c504c90eadbad9950a182feafa96b300a642`. Independent auto-publication work
  changed 12 permitted files (562 insertions/32 deletions), with spec/decisions
  unchanged. Its original absence and missing `DeclaredNotProduced.state_fields`
  payload are **closed findings**.
- Final target: `6986ad41b5f04c671fc6b321b4bab6df54520a40`. A further independent
  path-resolution change affected 14 permitted files (382 insertions/80 deletions).
  The primary reviewer read the complete source, test and permitted design delta,
  and reran the package gate and all nine probes. This is a bounded delta review,
  not a second complete subsystem audit. Decisions remained unchanged; Appendix C
  and the implementation map changed with the new path-resolution behavior.
- **Unknown-path candidate omissions in conditions/readers and the missing
  `PathResolution.declared` payload are also closed on the final target.**
  Other findings below remain supported by current source/probe evidence.
- Historical line numbers in subsystem reviews refer to their stated revision.
  The curated findings use current locations. See [validation](validation.md)
  for revision-specific hashes, logs and limitations.

Only `src/`, `test/`, `spec.md`, `decisions.md`, and `implementation.md` informed
the audit. No previous audit or pending register was consulted. The audit changed
only files in this report directory. See [method](method.md),
[coverage ledger](coverage.md), and [final revision delta](validation/final-revision-delta.patch).

## Confirmed correctness and robustness defects

### F-01 — High: runtime handler return keys are not fully checked

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
[current output](validation/execution_handler_key_drift-final.log),
[execution review EXE-03](reviews/02_execution.md).

### F-02 — High: malformed replay headers can silently preserve old inputs or partly overwrite the target

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
[current output](validation/periphery_replay_payload-final.log),
[periphery review P-02](reviews/03_periphery.md).

### F-03 — High: timed-out device tasks retain authority over later trajectories

**Requirement:** §§11.1/12.4 make device tasks run-scoped and describe fresh
resource acquisition on the next run, while also permitting bounded join
abandonment.

**Evidence:** `src/devices.jl:451–471` warns after the join deadline but does not
revoke the surviving task's handle. The handle still addresses the shared
control plane and writer. `src/sim.jl:1012` clears the registry even though the
task may still exist. A blocked device released after a new `init!` successfully
stages `a=77` into a later deviceless step. Another survivor calls `stop!` and
terminates the new trajectory before it advances.

**Impact and design choice:** this is a fault-containment failure after a device
has already violated its loop/unblock obligations; it is not the normal
cooperative-device path. Keep surviving tasks accounted for. Run-generation
checks can revoke stale handle authority, but cannot alone prevent an old task
and a fresh `init!` from sharing the device's external resources. Consider
quarantining restart until survivors exit, or explicitly defining another
timeout disposition. Resolve the specification's unconditional no-survivor
wording against its abandonment path. This audit does not choose that policy.

**Verification:** [probe](probes/periphery_timedout_handle.jl),
[current output](validation/periphery_timedout_handle-final.log),
[periphery review P-01](reviews/03_periphery.md).

### F-04 — Medium: trace values share mutable containers with the recording

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

**Requirement:** §12.4 and D-132 require masking across the boundary sequence,
delivery at consistent unmask points, calling-task device forwarding, and a
second-interrupt shortcut through remaining joins.

**Evidence:** `src/sim.jl:1059–1099` has no `disable_sigint` boundary mask and can
catch an interrupt after partly modifying stores, retaining the old final
snapshot. `src/devices.jl:362–376` lacks the calling-task interrupt distinction;
the join tail lacks second-interrupt collapse. The required machinery is absent
by source inspection; no real OS signal was injected during this audit.

**Important correction:** the synthetic `InterruptException` tests in
`test/test_failures.jl:258–288` correctly test §13.4's defensive catch. They are
not nonconformant and should remain. They simply do not test asynchronous
masking. Implement and test that independent protocol without changing the
specified defensive stop routing into a model-error rule.

**Evidence:** [execution EXE-02](reviews/02_execution.md), corrected
[periphery P-04](reviews/03_periphery.md).

### F-06 — Medium: coincident stop sources use the wrong priority

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
[current output](validation/termination_priority-final.log).

### F-07 — Medium: extreme finite time bounds are not validated after conversion

**Requirement:** finite `t_end` has finite-bound semantics; `Inf` explicitly
means open-ended execution (§§12.4/13.5 and Appendix B).

**Evidence:** `_t_bound`/constructor convert to `Float64` without checking the
converted result; `_frames_to` uses `ceil(Int, ...)` without range handling
(`src/sim.jl:156–209`). A finite `big"1e1000"` becomes `Inf`; `t_end=1e300`
produces raw `InexactError` before a run starts.

**Remedy:** define representability limits and reject out-of-range finite
values with the appropriate structured argument/deployment diagnostic.
Check partial-advance duration conversion on the same basis. These are extreme
inputs, not a demonstrated error at ordinary simulation horizons.

**Verification:** [probe](probes/execution_time_bounds.jl),
[current output](validation/execution_time_bounds-final.log).

### F-08 — Medium: nested component containers can silently disappear

**Requirement:** §8.5 rejects containers of containers in the first cut.
`_children` (`src/assembly.jl:120–127`) instead treats a tuple with no direct
component elements as inert, even when those elements are component containers.
The probe's nested component builds as an empty assembly.

**Remedy:** distinguish nested component-bearing containers from ordinary
parameter data and reject the former with element locations. Existing tests
cover direct mixed containers and empty containers, not this silent omission.

**Verification:** [build probe](probes/build_confirmed_gaps.jl),
[current output](validation/build_confirmed_gaps-final.log),
[build review finding 5](reviews/01_build.md).

### F-09 — Medium: enum-valued ports are rejected despite being admitted by the contract

**Requirement:** §8.2 admits enum port leaves as pinned values; §7.1's narrower
continuous-state vocabulary does not prohibit enum ports.

**Evidence:** `src/leaves.jl:35–39` recursively walks an enum's zero fields,
yielding no leaves; `cell_layout` rejects it as `IllegalPortType`. The isolated
discrete enum output reproduces that rejection. D-237's non-isbits handle rule
does not supply the missing enum leaf case.

**Remedy:** separate continuous-state restrictions from the port/store leaf
vocabulary and supply a consistent atomic enum representation through count,
flatten, reconstruction, comparison and probe synthesis. Test both producer and
root-input forms, including generic activation behavior.

**Verification:** [build probe/output](validation/build_confirmed_gaps-final.log);
[build review finding 6](reviews/01_build.md).

### F-10 — Medium: statically invalid read indices survive resolution

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
[current output](validation/services_confirmed_gaps-final.log),
[service review finding 3](reviews/04_services.md).

### F-11 — Medium: plainly non-callable trim fields bypass problem validation

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

**Verification:** [current service output](validation/services_confirmed_gaps-final.log),
[service review finding 4](reviews/04_services.md).

### F-12 — Medium: condition conversion converts an interrupt into a data error

**Requirement/evidence:** §14.8 requires an interrupt during solve/setup to
unwind without commit. `_convert` (`src/conditions.jl:388–393`) catches every
exception. A supplied conversion that throws `InterruptException` becomes a
collected `ConditionResolution` failure and resolution continues.

**Remedy:** preserve interrupt control flow through conversion/validation
wrappers and catch only the failures intended to mean unconvertible data.
The probe uses a synchronous conversion-thrown exception; it establishes the
catch behavior, not timing characteristics of operating-system SIGINT delivery.

**Verification:** [current service output](validation/services_confirmed_gaps-final.log),
[service review finding 5](reviews/04_services.md).

### F-13 — High: mutable numeric ports defeat snapshot and live-cell isolation

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
[final output](validation/storage_diagnostic_gaps-final.log),
[storage review SD-01](reviews/05_storage_diagnostics.md).

## Missing specified capabilities and diagnostic behavior

The following are gaps against settled design, not all runtime corruption bugs.
Explicitly deferred deliverables are listed separately below.

| ID | Priority | Gap and evidence | Completion/test direction |
|---|---|---|---|
| G-01 | High | **Real-time pacing and control family absent.** §§10.7/12.1/12.2 require pace/margin, pause, deadlines, re-anchoring, debt handling and related status. `run!` accepts only `t_end`/`stop_on`; the loop only yields with devices. `DebtReanchor`, `ThreadBudget`, `UnboundedRun` and pacer fields are absent. | Implement the settled family with a controllable monotonic-clock/wait seam; verify paced/unpaced trajectory identity and deadline/debt behavior. See EXE-01/P-07. |
| G-02 | High | **Linearization is absent.** §14.10 specifies taps, seeded evaluation, labeled matrices and pure scratch execution. No `linearize` entry point exists. | Build on service scratch stores and compiled reads/writes; validate frozen/unseedable taps and no-live-mutation before numerical matrix tests. |
| G-03 | Medium | **Service relocation is absent.** §14.9 requires `at(prefix, problem)` and relocated read sets. Both currently reach `ConditionNodeMisuse`. | Add the problem/read relocation algebra and nested relocation tests; do not confuse condition-node relocation, which exists, with this missing surface. |
| G-04 | Medium | **Cycle diagnostics use Kahn's stalled remainder.** §5.6/D-012 require SCCs, exact members/wires and classification support. `src/build.jl:298` reports one remainder; `{a,b}` cycle plus downstream `c` is reported as `[a,b,c]`. | Retain edge provenance, extract SCCs and test acyclic tails plus multiple disjoint cycles. Scheduling rejection exists; precise diagnosis does not. |
| G-05 | Medium | **Explicitly empty stages are accepted.** §§5.2/9.3 require `DeadStage`. Empty `output_state` plus a complete valid `output_direct` builds successfully; the diagnostic kind is absent. | Test both output families independently from completeness errors. |
| G-06 | Medium | **Probe synthesis lacks its specified diagnostic and enum default.** §9.3/D-051 require enum first-instance synthesis and `MissingProbeValue` for unavailable construction. `src/declare.jl:331–334` falls through to `P()` and leaks `MethodError`. | Resolve all synthesis failures with root-face/type context before dependent evaluation; test multiple failures and enum roots. |
| G-07 | Medium | **Probe/bundle error framing is missing.** §§5.2/13.2 require `BundleFieldError` and `UserCodeFraming`. The raw bundle miss reproduces `FieldError`; neither kind is defined. | Add a context-aware user-evaluation boundary and preserve original causes. Keep fail-fast evaluation distinct from collected declarative checks. |
| G-08 | Medium | **Public canonical `ProbeDual` is absent.** §9.4 explicitly names it. Custom `D8` tests exercise genericity without verifying the promised API. | Add the canonical concrete type and exercise the documented exhaustive-build call. |
| G-09 | Medium | **Foreign same-name declaration bindings are not diagnosed.** §8.1 requires shadowing context when required declarations appear absent; classification only inspects Cadence generics. | Test a component module with a foreign declaration binding; enrich the actual missing-class/store diagnostic. |
| G-10 | Medium | **Named build/schedule inspection views are incomplete.** §§9.2/13.7 require face provenance, anchor/component tables, rate-scope rows, bound provenance, hyperperiod chart and grid-driver explanations/`GridUtilization`. Internal dictionaries and `(path,D,Φ,Δt)` rows are insufficient. | Preserve provenance through binding and test the named views. Ordinary Julia printing of internal data is already available; the finding is not a demand for an arbitrary new universal `show` method. |
| G-11 | Low | **Some diagnostic payloads omit required context.** Examples: `ContainerMixed` lacks offending positions; face collision lacks both origins; read-binding `GetOutput`/`GetFace` failures lack candidate names. Storage review SD-06 lists eleven remaining payload discrepancies, including replay provenance and attachment context; these overlap other rows here. | Use the Appendix C inventory and payload assertions, rather than merely checking that an exception was thrown. The auto-publication `state_fields` and path-resolution declared-type omissions are fixed. Runtime conformance time is available on outer `StepError`; its placement is a schema discrepancy, not missing runtime context. |
| G-12 | Low | **Root probe values survive into built runtime cells.** §9.3 says these are probe-scoped; layout retains them and compiler scatters them before `init!`. | Clarify pre-init observation or remove runtime seeding from fabricated roots. Current totality/lifecycle gates overwrite them before normal advancement; no initialized-trajectory defect is claimed. |
| G-13 | Medium | **GUI integration semantics are unavailable.** §§11.7/12.6 specify liveness, peek and run attachment behavior; no corresponding implementation is present. | Preserve these semantic requirements while settling the authoring calling convention explicitly deferred to §16. A finalized API cannot be inferred from that section. |

Build details and reproductions: [01_build](reviews/01_build.md).
Execution/periphery details: [02_execution](reviews/02_execution.md),
[03_periphery](reviews/03_periphery.md).
Service details: [04_services](reviews/04_services.md).
Diagnostic inventory: [05_storage_diagnostics](reviews/05_storage_diagnostics.md).
It accounts for **79 Appendix C rows; eight kinds are absent** (all named in
G-01/G-05/G-06/G-07/G-10). These are overlapping evidence, not eight additional
findings. The existing kind-set test compares fixtures only with implemented
subtypes, so it cannot detect normative omissions. That is a test-design gap,
not an additional high-severity product defect.

## Documentation conflicts and open design choices

1. **Allocation scope conflicts (medium).** §7.5 claims inline/amortized-zero
   snapshot retention, whereas §11.2 and D-023 require per-boundary allocation
   and retained references; D-241 explicitly accepts the status vector's small
   allocation. The implementation follows the latter decisions. Warmed tiny-model
   probes allocate on publication with logging both on and off. Correct the
   prose; do not call this a zero-allocation phase-body regression.
2. **Heartbeat capture location (low).** §11.2 still says frame top, while
   §11.8/D-240 require publication-time capture. Source follows D-240.
3. **Contract arity error taxonomy (needs clarification).** §8.2 describes
   contradictory contract arities as `DeclarationOnWrongTier`; §8.5 names
   `TierSignatureMismatch` for overlapping cases. Source/tests use the first
   kind for arity disagreement and the second for narrow bounds. Rejection works.
   Align the texts/payload contracts before labelling one preserved error kind
   conclusively wrong.
4. **Auto-publication precedence (needs clarification).** §5.3/§8.3 say automatic
   publication applies when *no stage* produces the matching store name. §9.1
   classifies automatic names before probing stage 2. The new implementation
   reserves matching names after stage 1 and rejects a stage-2 return of such a
   name as `ProducedByTwoStages`. Make that precedence explicit, or change the
   classification contract deliberately. The audit does not infer a ruling.
5. **Join-timeout disposition (high design concern).** The promise that no task
   or resource survives return cannot hold unconditionally alongside arbitrary
   device-code abandonment. F-03 demonstrates the dangerous consequence. Define
   survivor authority, restart eligibility and cleanup responsibility together.

See the [primary document review](reviews/07_grounding_and_document_consistency.md)
and the subsystem reconciliation notes for evidence and tradeoffs.

## Potential improvements, separate from conformance defects

- **Define same-simulation service concurrency.** Admission currently checks
  lifecycle before later mutations/transition to `running`. A second caller can
  theoretically pass the same check. The specification does not clearly promise
  concurrent lifecycle mutators on one simulation, so this is a contract and
  hardening proposal, not a reproduced supported-use defect. A service mutex or
  atomic reservation is worth considering if such calls should be supported.
- **Make long-run trace growth observable.** Log retention is bounded, but the
  primary trace intentionally grows with drained batches. Expose batch count and
  estimated memory/growth; evaluate lossless streaming with the explicitly
  deferred persistence design. Do not silently thin primary data.
- **Test semantic boundaries as small matrices.** Prioritize build-vs-runtime
  returns, malformed replay refusal atomicity, timeout-vs-restart, coincident
  termination sources, selector resolution-vs-gather, and nominal-vs-Dual
  activations. These interactions produced more actionable defects than another
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

## Suggested order of work

1. Close silent-result and isolation defects: F-01, F-02, F-03 and F-13; protect
   trace ownership alongside replay admission.
2. Pin termination/interrupt semantics with targeted tests, then implement the
   missing operator protocol and correct priority arbitration.
3. Complete service safety/validation and the admitted type vocabulary.
4. Fill settled capability gaps: pacing/control, service relocation and
   linearization, in an order chosen by actual users.
5. Align diagnostic/inspection contracts and conflicting documentation; retain
   the coverage ledger as a checklist for focused regression additions.

This is a broad source-and-requirement audit with explicit coverage dispositions,
not proof that all possible numerical models, schedules, devices or interleavings
are correct. See [validation](validation.md) for executed checks and limits and
[coverage](coverage.md) for every specification subsection and source/test file.
