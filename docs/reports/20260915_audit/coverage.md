# Independent specification, source, and test coverage ledger

**Subsystem baseline:** `f941c504c90eadbad9950a182feafa96b300a642`
**Final delta reconciled by primary reviewer:** `6986ad41b5f04c671fc6b321b4bab6df54520a40`  
**Audit scope:** only `src/**`, `test/**`, `docs/design/spec.md`,
`docs/design/decisions.md`, `docs/design/implementation.md`, and the current
audit's seven detailed reviews. All added/changed test and source lines in the
final path-resolution delta were inspected; historical line references remain
anchored to their review's stated revision.

This is a traceability ledger, not a conformance certificate. **Evidence
inspected** means a source path and test evidence were reviewed. **Gap/deviation**
means the requirement lacks a surface, has a confirmed contrary behavior, or
is enforced by a test that accepts the contrary behavior. **Unresolved** means
the specification needs a ruling before a binary verdict. **Deferred** is used
for explicitly deferred implementation work, which remains recorded here.

## Numbered specification ledger

| Spec area | Status | Source and test trace | Audit disposition |
| --- | --- | --- | --- |
| §1 Purpose and method | evidence inspected | `Cadence.jl`; full harness | Framing/quality goals, not a separately executable requirement. |
| §2 Formalism | evidence inspected | `declare.jl`, `executor.jl`; events tests | Core formalism is represented in the implemented tier model. |
| §2.1 Events | evidence inspected | `executor.jl`, `localization.jl`; events/localization tests | Both detection policies have direct tests. |
| §2.2 Exclusions | evidence inspected | Design-only exclusions | Deliberate nonfeatures are documented; no absent product behavior is inferred. |
| §3 Component taxonomy | evidence inspected | `declare.jl`, `assembly.jl`; declare/assembly tests | Tier and assembly classification covered. |
| §3.1 Continuous component | evidence inspected | `build.jl`, `executor.jl`; continuous tests | Core primitive behavior inspected. |
| §3.2 Periodic discrete component | evidence inspected | `executor.jl`; discrete tests | Tick/update behavior inspected. |
| §3.3 Assembly | evidence inspected | `assembly.jl`; assembly tests | Hierarchy covered, subject to nested-container gap below. |
| §4 Ports and signals | gap/deviation | leaves/store/assembly; related tests | General port machinery covered; enum port vocabulary diverges. |
| §4.1 Immutable value semantics | gap/deviation | `leaves.jl`, `store.jl`; leaves/store tests | Value round-trip evidence inspected; mutable Real bypass breaks snapshot/live-cell isolation (F-13). |
| §4.2 Consumers see ports | evidence inspected | `assembly.jl`, `build.jl`; assembly/build tests | Face/port resolution and stage visibility inspected. |
| §4.3 Table mechanics and granularity | gap/deviation | `store.jl`, `executor.jl`; store/failures tests | Gather/scatter/write checks covered; mutable numeric values bypass the required immutability gate (F-13). |
| §4.4 Function-valued signals | evidence inspected | `leaves.jl`; handle tests | D-237 opaque-handle acceptance and identity semantics are implemented and tested; no additional consumer form is required by the closed corpus. |
| §5 Evaluation and feedthrough | gap/deviation | build/executor; build/failures tests | See granular §5 rows. |
| §5.1 Scheduling problem | evidence inspected | `build.jl`; build tests | Ordinary acyclic ordering covered. |
| §5.2 Two-stage outputs | gap/deviation | `build.jl`; build/failures tests | Auto-publication is now covered; empty stage and user-code framing remain divergent. |
| §5.3 Structural feedthrough | evidence inspected | `build.jl`, `executor.jl`; build/continuous/discrete/events/executor tests | Stage roles, auto-publication, loop scheduling, runtime cells, snapshots, and event publication have current focused evidence. |
| §5.4 Artificial loops | gap/deviation | `build.jl`; build tests | Required tracing/classification surface is absent alongside SCC reporting. |
| §5.5 Algebraic loop policy | gap/deviation | `build.jl:221-253`; build tests | Kahn residue substitutes for SCCs. |
| §5.6 Feedthrough diagnostics | gap/deviation | `diagnostics.jl`; build tests | Cycle wires/classification and per-SCC reporting absent. |
| §6 Composition | evidence inspected | `assembly.jl`; assembly tests | Connection registers and face resolution broadly covered. |
| §6.1 Connections and hierarchy | gap/deviation | `assembly.jl`; assembly/leaves tests | Normal type/path/fanout tests are strong; nested container acceptance gap remains. |
| §6.2 Explicit aggregation | evidence inspected | `assembly.jl`; assembly/build fixtures | Explicit summing paths inspected. |
| §7 State/data representation | gap/deviation | leaves/store/build; leaves/store tests | Enum leaf behavior remains divergent. |
| §7.1 Continuous state | evidence inspected | `leaves.jl`; leaves/failures tests | Shape, names, immutability/refusal paths inspected. |
| §7.2 Numeric genericity | evidence inspected | `leaves.jl`, `build.jl`; leaves/store/build tests | Retyping and mixed pinned values inspected. |
| §7.3 Discrete state/modes/workspace | evidence inspected | `store.jl`, `executor.jl`; store/discrete/failures tests | Cells, updates, workspace covered. |
| §7.4 Fused-evaluation lineage | evidence inspected | Historical/design rationale | Not an independent runtime obligation. |
| §7.5 Allocation policy | evidence inspected | generated bodies; store/conditions/readers/trim tests | Scoped zero-allocation evidence only, not an end-to-end proof. |
| §8 Declaration layer | gap/deviation | declare/assembly/build; associated tests | See granular §8 rows. |
| §8.1 Plain Julia declaration position | gap/deviation | `declare.jl`, `build.jl`; declare/build tests | Basic declarations covered; foreign same-name binding diagnosis absent. |
| §8.2 Declaration inventory | gap/deviation | `declare.jl`; declare/build tests | Most inventory covered; enum/probe and some error rules incomplete. |
| §8.3 Contract visibility | evidence inspected | `build.jl`; build/continuous/discrete/events tests | Current auto-publication tests cover the contract-driven store-field case. |
| §8.4 Failure walkthroughs | evidence inspected | diagnostics/build; build/diagnostics tests | Representative errors inspected, not every prescribed payload. |
| §8.5 Assembly declaration | gap/deviation | `assembly.jl`; assembly tests | Direct containers covered; nested-container-only field is silently inert. |
| §8.6 Paths/wiring/faces | evidence inspected | `assembly.jl`; assembly tests | Positive and negative endpoint cases covered. |
| §8.7 Rate scopes | evidence inspected | declare/assembly/build; discrete tests | Relative/absolute/scope arithmetic inspected. |
| §8.8 Computed connections | evidence inspected | `assembly.jl`; assembly tests | Passthrough/generic holding inspected. |
| §9 Build pipeline | gap/deviation | build/executor/sim; build/executor tests | See granular §9 rows. |
| §9.1 Three strata | evidence inspected | `build.jl`; build tests | Structural/schedule/activation paths inspected. |
| §9.2 Build artifact | gap/deviation | `build.jl`; build/discrete tests | Internal values tested; required rendering/provenance/hyperperiod view absent. |
| §9.3 Probing/input synthesis | gap/deviation | declare/build; build tests | Missing enum support and diagnostic conversion; probe values leak into runtime cells. |
| §9.4 Activations/caching | gap/deviation | `build.jl`; build/failures tests | Cache/type behavior covered; public canonical `ProbeDual` absent. |
| §9.5 Always-on conformance | gap/deviation | executor/store; failures tests | Many late paths tested; handler top-level drift escapes. |
| §9.6 Stopped-sim services | evidence inspected | conditions/readers/trim; service tests | Implemented services have direct evidence. |
| §9.7 Compiled executor | evidence inspected | build/executor; executor/discrete tests | Entry/chunk/gate/body coverage inspected. |
| §10 Time and execution | gap/deviation | sim/executor/stepper/localization; execution tests | See granular §10 rows. |
| §10.1 Loop ownership | evidence inspected | `sim.jl`; lifecycle tests | Framework-owned run/step paths covered. |
| §10.2 Stepper seam | evidence inspected | `stepper.jl`; stepper/continuous tests | RK4, Heun, dense behavior inspected. |
| §10.3 Boundary consistency | evidence inspected | sim/executor; events/failures tests | Boundary sequencing has direct evidence. |
| §10.4 Localization | evidence inspected | `localization.jl`; localization tests | Endpoints/budgets/remainders covered. |
| §10.5 Multi-rate scheduling | evidence inspected | executor/build; discrete tests | Gates/anchors/ticks covered. |
| §10.6 Event iteration | evidence inspected | sim/executor; events tests | Quiescence/order/budget coverage inspected. |
| §10.7 Real-time pacing | gap/deviation | no pacing state/API; no tests | Required feature absent. |
| §11 Data plane | gap/deviation | periphery source/tests | See granular §11 rows. |
| §11.1 Task topology | gap/deviation | devices/roster; devices tests | Normal bracket covered; stale timed-out authority found. |
| §11.2 Snapshot publication | gap/deviation | dataplane/bindings; dataplane/log/bindings tests | Main publication/read paths covered; mutable Real snapshot alias (F-13) and binding candidates remain gaps. |
| §11.3 Claims/frozen roster | unresolved | roster/sim; roster tests | Claim behavior covered. Same-simulation concurrent admission is a hardening/design question, not a confirmed defect. |
| §11.4 Staging/drain | evidence inspected | dataplane/sim; dataplane tests | Normal coalescing, representation, and drain ordering are covered; replay validation belongs to §12.7. |
| §11.5 Input trace | gap/deviation | trace/sim; trace tests | Well-formed replay strong; payload validation/ownership defects found. |
| §11.6 Devices | gap/deviation | devices/roster; devices tests | Contract/bracket covered; interrupt/timed-out handle issues remain. |
| §11.7 GUI write path | gap/deviation | no GUI API/tests | The specified GUI semantics are absent. §16 defers only the authoring calling convention, not this capability. |
| §11.8 Diagnostics/liveness | gap/deviation | dataplane; diagnostics tests | Writer diagnostics tested; pacer/run-entry family absent. |
| §12 Lifecycle/orchestration | gap/deviation | sim/devices/trace; lifecycle/trace tests | See granular §12 rows. |
| §12.1 Control plane | gap/deviation | `sim.jl`; lifecycle tests | Stop exists; pause/unpause/pace/margin absent. |
| §12.2 Scheduling/thread budget | gap/deviation | sim/devices; devices/diagnostics tests | Yield/liveness covered; pacer/thread-budget behavior absent. |
| §12.3 Next-snapshot wait | evidence inspected | devices/dataplane; devices tests | Predicate/counter wait path inspected. |
| §12.4 Shutdown protocol | gap/deviation | devices/sim; lifecycle/devices tests | Ordinary tail covered; stale authority/interrupt deviations remain. |
| §12.5 Mid-run mutation doctrine | evidence inspected | sim/dataplane; lifecycle/trace tests | Staging-only normal path inspected; absent control operations tracked under §12.1. |
| §12.6 Run lifecycle/partial advance | unresolved | sim; lifecycle/trace tests | Nominal transitions strong; same-simulation concurrent admission needs a supported-use ruling before a failure claim. |
| §12.7 Replay | gap/deviation | trace/sim; trace tests | Normal replay robustly tested; malformed entry pass can mutate/fail late. |
| §13 Error discipline | gap/deviation | diagnostics and cross-cutting paths; diagnostics/failures tests | See granular §13 rows. |
| §13.1 Reporting policy | evidence inspected | diagnostics/build/conditions; diagnostics/build/service tests | Collection/fail-fast examples inspected. |
| §13.2 Structured diagnostics | gap/deviation | diagnostics; diagnostics tests | Carrier/rendering covered; Appendix-C family/payload inventory incomplete. |
| §13.3 Build primitives | evidence inspected | assembly/readers; assembly/readers tests | Resolve/accessor paths inspected. |
| §13.4 Runtime failures | gap/deviation | sim/executor; failures tests | Cursor/StepError and the defensive synchronous `InterruptException` carve-out are covered; asynchronous SIGINT masking remains absent. |
| §13.5 Termination state | gap/deviation | devices/sim; lifecycle tests and `probes/termination_priority.jl` | Individual sources are covered, but collision priority is not. The focused probe confirms face/model stop incorrectly outranks control and end-time. |
| §13.6 Abnormal shutdown | gap/deviation | devices/sim; failures/lifecycle tests | Ordinary failure tail covered; interrupt handling deviates. |
| §13.7 Tooling/component library | gap/deviation | no complete shipped surface | Required library/test-rig/tooling artifacts not present as specified. |
| §14 Stopped-sim services | evidence inspected | conditions/readers/trim; service tests | See granular §14 rows. |
| §14.1 Conditions | gap/deviation | conditions; conditions/readers/trim tests | Overlay/capture/lifecycle coverage inspected; conversion swallows `InterruptException` rather than preserving control flow. |
| §14.2 Fragment composition | evidence inspected | conditions; conditions tests | Lazy composition/provenance cases covered. |
| §14.3 Resolution | gap/deviation | conditions; conditions tests | Collection/validation/conversion paths covered; unknown-path candidates are now supplied and tested; conversion still swallows interrupts. |
| §14.4 Application registers | gap/deviation | conditions/readers; conditions/readers tests | Dynamic/specialized read/write and drift coverage inspected; static out-of-range selector indices resolve and fail later as raw `BoundsError`. |
| §14.5 Boundary zero | evidence inspected | sim/executor; conditions/trim/failures tests | Initialization/event/replay pointer cases inspected. |
| §14.6 Root-input totality | evidence inspected | conditions/sim; conditions/trim tests | Pre-write totality/rejection covered. |
| §14.7 Trim problem | gap/deviation | trim; trim tests | Shape/bounds/residual validation covered; callable `condition`/`residuals` fields bypass setup validation. |
| §14.8 Trim service | evidence inspected | trim; trim tests | Solve/scratch/commit/report coverage inspected; it inherits condition conversion's interrupt-propagation defect. |
| §14.9 Mounting | gap/deviation | no `at(prefix, Reads/TrimProblem)` API or tests | Relocation of read sets and trim problems is required and currently rejects as `ConditionNodeMisuse`. |
| §14.10 Linearization | gap/deviation | no API in source/tests | No implementation or test surface. |
| §15 Case studies | deferred | fixture analogues only | See granular §15 rows. |
| §15.1 Vehicle migration | deferred | `Vehicle` fixture | Fixture is not the specified migration artifact. |
| §15.2 PistonEngine/FCS torture test | deferred | no named shipped artifact | No full case-study conformance claim. |
| §15.3 Staging-shape torture test | deferred | staging fixtures | Partial analogues only. |
| §15.4 Interactive C172X demo | deferred | no GUI/demo artifact | Deferred with GUI integration. |
| §15.5 Strapdown IMU | deferred | no named shipped artifact | No full case-study artifact. |
| §16 Open axes | deferred | no migration/persistence API | Explicitly open/deferred text. |

## Appendix ledger

| Appendix | Status | Trace | Disposition |
| --- | --- | --- | --- |
| A. Taught contracts | evidence inspected | Public declarations/operations across `declare.jl`, `sim.jl`, `conditions.jl`, `readers.jl`, `trim.jl`; imports and focused tests | A useful author index; coverage follows its normative chapter entries and inherits their gaps. |
| B. API synopsis | gap/deviation | `src/Cadence.jl`, declarations, tests/imports | Many listed APIs are exercised. Missing `ProbeDual`, pacing/control, mounting, and linearization mean the synopsis is not fully callable. |
| C. Diagnostic kind set | gap/deviation | `diagnostics.jl`; `test_diagnostics.jl`, build/assembly/failure tests | Many kinds and renderings tested, but required kinds (`DeadStage`, user framing, missing probe value, grid utilization) and several mandatory payloads are absent/reduced. |
| D. Glossary, D.1–D.10 | evidence inspected | Naming/type/use was checked through the mapped source and tests | Vocabulary is explanatory; no independent executable obligation beyond its cross-referenced requirements. |

## Source-file inventory

| Source file | Implemented responsibility inspected | Primary test ownership |
| --- | --- | --- |
| `Cadence.jl` | Module imports/includes/exports | Harness/import files, all tests |
| `declare.jl` | Declarations, probes, rates, events | declare, build, discrete, events |
| `leaves.jl` | Leaf walk, retype, acceptance | leaves, store, assembly |
| `diagnostics.jl` | Diagnostics/carriers/cursor | diagnostics, failures, build, assembly |
| `assembly.jl` | Class, hierarchy, paths, faces, wiring | assembly, build |
| `store.jl` | Cell stores, scatter/gather, clock | store, leaves, failures |
| `build.jl` | Build strata, layout, probe, activation, compiler | build, assembly, executor, failures |
| `executor.jl` | Entries, generated walks, gates, events | executor, discrete, events, failures |
| `stepper.jl` | RK4/Heun/dense output | stepper, continuous, localization |
| `localization.jl` | Frame/localization loop | localization, events, failures |
| `sim.jl` | Deployment, loop, lifecycle, replay, publication | lifecycle, trace, failures, dataplane |
| `dataplane.jl` | Staging, snapshots, log, writer diagnostics | dataplane, log, diagnostics |
| `trace.jl` | Trace capture/header/feed validation | trace, lifecycle |
| `roster.jl` | Device/binding admission and data plane | roster, devices, bindings |
| `bindings.jl` | Table binding and compiled reads | bindings, readers |
| `devices.jl` | Device task/bracket/termination | devices, lifecycle, failures |
| `conditions.jl` | Fragments, resolution, plans/capture | conditions, readers, trim |
| `readers.jl` | Selectors/read compilation/gather | readers, bindings, trim |
| `trim.jl` | Problem validation, solver, commit/report | trim |

## Test/harness inventory

All files under `test/**` were read. The ownership grouping is recorded in
`reviews/06_test_coverage.md`; the complete file list is: `CadenceTests.jl`,
`Project.toml`, `fixtures.jl`, `imports.jl`, `repl.jl`, `runtests.jl`,
`utils.jl`, and `test_{assembly,bindings,build,conditions,continuous,dataplane,
declare,devices,diagnostics,discrete,events,executor,failures,leaves,lifecycle,
localization,log,readers,roster,stepper,store,trace,trim}.jl`.

## Cross-review confirmed gaps carried into test disposition

The following are implementation findings from current first-wave evidence,
not speculation inferred from missing test names: empty stage, SCC reporting,
user-code framing, nested containers, enum ports/probe values, and public
`ProbeDual` (review 01); pacing, asynchronous SIGINT masking, late handler
return drift, and time-bound conversion (review 02); stale timed-out handles,
replay entry/payload validation and trace ownership, control/pacer diagnostics,
termination arbitration, and binding candidates (review 03); and service
relocation, selector-index validation, callable trim fields, conversion
interrupt propagation (review 04); mutable numeric port aliasing and the
independent Appendix C inventory (review 05). Auto-publication and unknown-path
candidate findings are resolved at their respective reconciliation revisions. Concurrent
service admission remains an unresolved hardening/design question, not a
confirmed first-wave defect. Corresponding absent or insufficient tests are
detailed in `reviews/06_test_coverage.md`.

## Remaining uncertainty

All seven detailed reviews are incorporated. Absent mounting/linearization
APIs, asynchronous signal delivery and arbitrary numerical/device interleavings
remain subject to the limits in validation.md.
No status in this ledger is an unqualified full-conformance result.
