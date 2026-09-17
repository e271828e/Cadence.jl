# Test coverage and traceability review

**Subsystem baseline reconciled:** `f941c504c90eadbad9950a182feafa96b300a642`  
**Scope:** `src/**`, `test/**`, `docs/design/{implementation,spec,decisions}.md`, and this audit directory's first-wave reviews only. `implementation.md` was read first. `pending.md`, older reports, and unrelated workspace changes were not used.

## Method and status vocabulary

I read the test harness, fixtures, and every `test/*.jl` file. Test names and
comments were treated as pointers, then checked against the requirement and
the implementation path. A cited testset therefore means that a concrete
property was inspected; it is not a claim of complete conformance.

| Status | Meaning |
| --- | --- |
| **evidence inspected** | An implemented path has direct positive and/or rejection evidence. Remaining edge cases may still exist. |
| **gap/deviation** | A confirmed implementation defect, an absent required surface, or a test that enforces the divergent behavior. |
| **unresolved** | The specification is internally ambiguous, too abstract to make a binary product claim, or needs a design ruling. |
| **deferred** | Case-study, migration, GUI, persistence, or other material whose implementation is expressly deferred. It remains in the ledger. |

The saved direct and `Pkg.test()` results for the preceding baseline are both
**2425/2425** on Julia 1.13.0. They do not validate the reconciliation changes
above. The intermediate gate passed 2,478 assertions; the final gate passed
2,514/2,514 in 5m34.6s, recorded in [validation](../validation.md). No result is a conformance verdict.

## High-value test blind spots

### 1. Auto-publication is now covered; explicit empty stages remain untested and accepted

The reconciliation adds direct positive coverage for continuous state/mode,
discrete store, type mismatch, duplicate writer, non-nominal activation, loop
scheduling, executor entries, snapshots, and event-driven mode publication
(`test/test_build.jl:79-146`, `test/test_continuous.jl:60-118`,
`test/test_discrete.jl`, `test/test_events.jl:286-305`, and
`test/test_executor.jl:20-37`). `auto_published` now participates in activation
and compiled stage-1 work (`src/build.jl:259-289`, `666-691`, `1186-1207`).

The separate `DeadStage` rule remains absent: an explicitly present stage that
returns `NamedTuple()` has no diagnostic kind or focused test and is still
accepted by the probes. Add one negative test for each explicitly empty stage;
do not regress the newly covered lawful auto-publication cases.

### 2. Runtime conformance coverage misses handler top-level drift

`test/test_failures.jl:466-594` does exercise late output, derivative,
projection, successor, and nested-mode drift. It does not exercise a handler
whose later branch returns an unknown top-level key or a non-`NamedTuple`.
That is material: `_latch!` consumes only `:x` and `:m` (`src/executor.jl:325-330`),
so an unknown late key is silently dropped, while a late scalar reaches a raw
dispatch error. Add branch-divergent handler tests for extra key, undeclared
store, scalar return, valid reordered return, and partial mode update.

### 3. Cycle coverage cannot distinguish an SCC from its downstream Kahn residue

`test/test_build.jl:71-75` uses a graph in which every stalled vertex is
cyclic. `schedule_stage2` reports the entire remaining Kahn set
(`src/build.jl:221-253`), so it misreports an acyclic downstream tail and
collapses disjoint cycles. Add a graph `a ↔ b`, `b → c`, plus a separate cycle;
assert one diagnostic per SCC, no `c`, exact wire provenance, and the
real/artificial classification required by §5.6.

### 4. Signal interruption tests inject a model exception, not asynchronous SIGINT

`test/test_failures.jl:258-288` throws `InterruptException` from fixture model
code. That is valid coverage of §13.4's defensive catch-and-stop carve-out; it
does not establish the independent asynchronous signal-masking requirement.
`_advance!` has no `disable_sigint` bracket around a complete boundary. Add a
deterministic boundary-phase injection seam and test deferred delivery after
drain, integration, projection, event firing, tick, and publication, with a
completed final snapshot and coherent stopped-state stores.

### 5. No pacing/control family is tested because it is not implemented

No test calls `run!(; pace, margin)` or exercises pause/unpause, debt,
re-anchoring, sleeping/spinning, or pacer status. `run!` accepts only `t_end`
and `stop_on` (`src/sim.jl:912-923`) and `Simulation` contains no pacer state.
This is a §10.7/§12.1–12.2 gap, not a coverage percentage shortfall. When the
surface exists, test it behind an injected monotonic clock/wait seam and
compare bit-identical trajectory results with `pace=Inf`.

### 6. Trace/replay tests are strong for well-formed artifacts but do not protect malformed payload atomicity

`test/test_trace.jl:193-372` covers header/schema/position refusal and
`test/test_trace.jl:393-847` covers replay, bounds, mode transitions, and live
staging discard. First-wave periphery evidence found that payload/root
validation can be incomplete and can mutate before a raw failure. Add malformed
records for a missing root, duplicate/out-of-schema face, incompatible datum,
and alias/mutation after `trace(sim)`; assert every refusal occurs before any
target-store, trace-register, log, or lifecycle mutation.

### 7. Lifecycle concurrency is a hardening question, not a confirmed deviation

`test/test_lifecycle.jl:65-89` waits until `:running` is observable before
checking refusal. That tests the settled state, but not same-simulation
concurrent service entry. The source has a check-to-transition interval
(`src/sim.jl:322-329`, `912-921`, `1176-1195`, `1275-1296`), but the
specification does not clearly establish concurrent caller support as a
required contract. Treat barrier tests for run/run, run/step, run/init,
replay/run, and run/attach as a hardening/design decision, not proof of a
current conformance failure.

### 8. Numeric-bound tests omit representability boundaries

The lifecycle tests cover ordinary finite, off-grid, negative, and infinite
times, but not a finite wide real converting to `Inf`, an integer frame count
outside `Int`, or the identical problem through `step!(; t_plus=...)`.
`_t_bound` converts accepted nonnegative `Real`s to `Float64` and `_frames_to`
uses `ceil(Int, ...)` (`src/sim.jl:181-209`). Add boundary tests that require a
framework diagnostic and preserved lifecycle rather than silent unboundedness
or raw `InexactError`.

### 9. Termination tests do not exercise simultaneous source arbitration

`test/test_lifecycle.jl` checks each stop source independently, but not their
documented priority at the same boundary. The current focused probe confirms
that a model face wins in all three collision cases: control plus face at
boundary zero, end time plus face at boundary zero, and end time plus face at
frame one (`validation/termination-priority.log:1-3`). The result conflicts
with the specified arbitration order. Add deterministic same-boundary tests for
all source pairs, including control/end/face triple collisions, and assert both
the typed source and the final frame count.

### 10. Appendix-C coverage is selective and sometimes freezes underspecified diagnostics

`test/test_diagnostics.jl:248-530` validates useful rendering and payload
examples. It is not a table-driven inventory of Appendix C, and focused tests
accept reduced payloads: for example `ContainerMixed` checks types but not the
offending entries (`test/test_assembly.jl:123-141`), and the cycle test cannot
require cycle wires/classification. Add a generated Appendix-C matrix of kind,
severity, required payload fields, collection/fail-fast timing, and rendering
for every implemented diagnostic. Mark absent kinds as expected failures until
their implementation is accepted.

### 11. Services have broad nominal coverage but six concrete blind spots

Conditions have substantial compositional, resolution, shape-drift, totality,
and allocation coverage (`test/test_conditions.jl:35-518`); readers cover all
five selectors and lifecycle/activation rejection (`test/test_readers.jl:40-204`);
trim covers convergence, refusal, scratch isolation, commits, and lifecycle
(`test/test_trim.jl:91-531`). Their gaps are specific:

- No test can relocate `Reads` or `TrimProblem` with `at`; both APIs are absent
  and reject with `ConditionNodeMisuse`.
- Readers test a valid vector index and scalar-index refusal, but not an
  out-of-range `SVector` index that resolves then throws raw `BoundsError`.
- Malformed trim tests omit non-callable `condition`/`residuals` fields, which
  escape the setup barrier as raw `MethodError`.
- Conversion tests omit `InterruptException`; `_convert` collects it as an
  ordinary conversion failure rather than rethrowing it.
- Final delta reconciliation: unknown-path tests now assert `PathResolution`
  candidates, provenance and declared generic field types; the earlier gap is closed.
- There is no linearization/tap API under `src/**` or `test/**`.

These are product gaps or missing negative tests, not a claim that the nominal
condition, reader, and trim paths lack coverage.

## Test-file inventory

| File(s) | Property coverage inspected | Principal limits found |
| --- | --- | --- |
| `CadenceTests.jl`, `runtests.jl`, `repl.jl`, `imports.jl`, `Project.toml`, `utils.jl` | Harness, named-file dispatch, explicit imports, test environment, shared assertions | Harness does not encode a normative inventory or prevent missing test files/APIs. |
| `fixtures.jl` | Shared component, event, device, binding, trace, and trim worlds | Rich fixture reuse can mask untested declaration shapes; it contains no enum-port or nested-container-only world. |
| `test_declare.jl`, `test_assembly.jl`, `test_build.jl` | Declarations, hierarchy, wiring, faces, rate scopes, build, activation, feedthrough | Auto-publication now has focused positive/negative coverage; dead stage, SCC precision, enum ports/probes, public `ProbeDual`, and build rendering remain absent or divergent. |
| `test_leaves.jl`, `test_store.jl` | Leaf walk, retyping, wire relation, mixed stores, gather/scatter, workspace | Enum leaf vocabulary is not exercised; source rejects it as an empty port layout. |
| `test_continuous.jl`, `test_discrete.jl`, `test_executor.jl`, `test_stepper.jl` | Integrators, schedules, gating, chunking, ticks, compilation allocation | No pace/margin/debt or public schedule/Build inspection coverage. |
| `test_events.jl`, `test_localization.jl`, `test_failures.jl` | Guards, localization, projection, quiescence, runtime cursor and conformance | Late handler top-level drift and real asynchronous interruption absent. |
| `test_dataplane.jl`, `test_log.jl`, `test_roster.jl`, `test_bindings.jl`, `test_devices.jl`, `test_diagnostics.jl` | Staging, publication/log, claims, bindings, lifecycle brackets, writer diagnostics | GUI semantics, pause/pacing, stale timed-out handles, and some did-you-mean branches are absent; concurrent admission is an unresolved hardening question. |
| `test_lifecycle.jl`, `test_trace.jl` | Lifecycle, stop/end bounds, replay, trace, mode transitions | Representability bounds, atomic replay prevalidation, and trace ownership are absent; service-entry races are unresolved hardening. |
| `test_conditions.jl`, `test_readers.jl`, `test_trim.jl` | Stopped-sim conditions, selectors/readers, and trim | No relocation or linearization surface/tests; static index bounds, callable trim fields, and conversion interrupts lack coverage. Unknown-path candidate coverage was added in the final delta. |

## Test strategy recommendations

1. Create a requirement-to-test ledger generated from stable IDs, rather than
   relying only on prose in test names. Each row should name the normative
   clause, positive case, negative case, test file/line, and an explicit
   `deferred`/`not implemented` disposition.
2. Add adversarial branch fixtures deliberately different from the probe branch.
   This is the recurring weakness in runtime conformance tests.
3. Build deterministic seams for clock, wait, signal delivery, and lifecycle
   admission. They turn timing/concurrency contracts into repeatable tests.
4. Keep §15 case studies and §16 migration axes out of the core pass/fail count;
   test any shipped example as an integration artifact with a separate label.

## Limits

This review does not claim that every test assertion was individually mapped to
one sentence of the specification. It does establish that every test file was
read, each implemented source area has a named test-owner inventory, and each
numbered specification area is dispositioned in `coverage.md`.

## Primary-review reconciliation to `6986ad4`

The final path-resolution delta adds positive and negative tests for concrete
versus generic holdings, traversal stopping at primitives, nested condition
composition, and capture/reapply across generic seams. Reader and trim failures
now use located `PathResolution` occurrences with candidate names. These tests
and the complete source/design delta were read; no additional defect was
established by that bounded review.

Storage review SD-01 adds a confirmed blind spot: mutable `Real` values are
admitted and shared between snapshot and live storage. The final storage probe
asserts both mutations. SD-05 identifies a separate test-design issue: comparing
fixtures only with implemented diagnostic subtypes cannot detect the eight
missing kinds among Appendix C's 79 rows. See the curated report for severities
and overlap with existing findings.
