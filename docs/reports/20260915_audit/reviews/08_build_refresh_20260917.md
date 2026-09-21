# Build and storage finding refresh — 2026-09-17

Baseline report: `docs/reports/20260915_audit/report.md` at the requested comparison point `6986ad4`.
Committed review target: `66c49f09b4cfc3ddb0b62523e979cd0537ba7c8c`.
Items reviewed: F-08, F-09, F-13, G-04–G-09, and G-12.

## Scope and worktree qualification

This refresh used the current `spec.md`, `decisions.md`, `implementation.md`, and explicitly authorized `pending.md`, together with the relevant current source and focused tests. It did not use older audit reports. The old probes were not rerun.

The checkout was changing during review. `src/assembly.jl`, `src/build.jl`, `src/diagnostics.jl`, `test/test_assembly.jl`, `test/test_build.jl`, and `docs/design/implementation.md` had uncommitted edits by the end of inspection. Retirement conclusions involving those files are therefore anchored to `git show 66c49f0:<path>`; line references to them below are labeled **HEAD**. The dirty edits add diagnostic payload work and related tests, but are provisional and are not needed for any retirement conclusion in this report. Clean-file references use the current worktree line numbers.

No suite was run here. The main auditor owns the package gate. A new two-case current-revision probe was run only for the two findings whose mechanisms remain; its results are quoted under F-13 and G-12. The dirty `src/build.jl` diff did not touch either probed mechanism, and their other source files were clean.

## Disposition summary

| ID | Disposition at committed HEAD `66c49f0` | Basis |
| --- | --- | --- |
| F-08 | **Retired by implementation** | Nested component-bearing containers now produce `ContainerNested`; focused tuple and named-tuple tests exist. |
| F-09 | **Retired by implementation** | Enums are one pinned leaf throughout the leaf walk, reconstruction, activation typing, and root synthesis. |
| F-13 | **Still open — high** | Every subtype of `Real` bypasses the mutable-type check; shallow buffer capture still shares a mutable numeric leaf. |
| G-04 | **Retired by implementation** | Kahn's residue is decomposed into SCCs with exact intra-cluster wires; downstream tails and disjoint loops are tested. |
| G-05 | **Retired by implementation** | Both output-stage positions reject bare `(;)` as `DeadStage`, independently of port completeness. |
| G-06 | **Retired as originally stated** | Enum synthesis and collected `MissingProbeValue` for the framework fallback are implemented and tested. |
| G-07 | **Partially retired — medium residual** | Stage/declaration framing and bundle classification are implemented; an authored `probe_value` override is still invoked bare and its exception escapes raw. |
| G-08 | **Retired by implementation** | The canonical concrete `ProbeDual` exists and is exercised by eager activation checks. |
| G-09 | **Retired by a design change plus implementation** | D-246 replaced the earlier note-on-neighboring-kind approach with fail-fast `DeclarationShadowed`, now implemented before classification. |
| G-12 | **Still open — low** | Layout retains synthesized inputs and compilation scatters them into observable pre-`init!` cells. |

## Detailed verification

### F-08 — nested component containers: retired by implementation

The requirement remains unchanged: zero-component containers are inert except when an element is itself component-bearing, which must be rejected as `ContainerNested` (`spec.md:2484-2493`; Appendix C at `spec.md:10864-10868`). At committed HEAD, `_children` checks the nominally inert `n == 0` arm with recursive `_bears_component` and records the offending keys and types (`HEAD:src/assembly.jl:120-130`, `HEAD:src/assembly.jl:173-175`).

The focused tests cover both nested tuples and a deeper named-tuple case beside inert data, and assert the exact `ContainerNested` payload (`HEAD:test/test_assembly.jl:179-192`). This closes the silent-empty-build mechanism from F-08. The current dirty assembly/diagnostics work enriches neighboring payloads and is not required for this result.

### F-09 — enum-valued ports: retired by implementation

The current contract explicitly makes an enum one pinned leaf and refuses mutable types separately (`spec.md:437-444`). The leaf machinery now treats `Enum` atomically in leaf count, leaf type, leaf name, and value extraction (`src/leaves.jl:21-49`, `src/leaves.jl:69-72`, `src/leaves.jl:249`), while root-input synthesis chooses the first instance (`src/declare.jl:381-385`).

Focused tests assert the leaf operations and activation pinning (`test/test_leaves.jl:140-151`) and exercise a discrete enum producer/consumer, a synthesized enum root input, and an enum mode publication (`HEAD:test/test_build.jl:1123-1167`). The old zero-leaf `IllegalPortType` path is no longer present for enums.

### F-13 — mutable numeric ports: still open

The current design still promises immutable signals with no mutable aliasing (`spec.md:360-367`) and says a mutable type anywhere in a port value is refused (`spec.md:437-444`; D-237 at `decisions.md:8560-8570`). The implementation contradicts that rule for numeric types: `_mutable_position` returns `nothing` for every `P <: Real` before consulting `ismutabletype(P)` (`src/leaves.jl:95-100`). `cell_layout` relies on that answer for its `IllegalPortType(reason=:mutable)` arm (`HEAD:src/build.jl:558-563`). Existing tests reject ordinary mutable containers such as `Cache` and `Matrix`, but do not cover a mutable subtype of `Real` (`HEAD:test/test_build.jl:731-762`; `test/test_leaves.jl:163-169`).

Publication copies each leaf buffer only shallowly (`src/dataplane.jl:575-577`). The focused current-revision probe declared a mutable `RefreshMutableReal <: Real`, built a discrete source port of that type, initialized it, mutated the value returned from its snapshot, and observed:

```text
mutable Real accepted: live=9 snapshot=9
```

The same object therefore remains reachable from the published snapshot and the live cell, violating both snapshot immutability and live-cell isolation. This is the original F-13 mechanism, unchanged at committed HEAD. Fix the order in `_mutable_position` so the explicit exceptions are decided before the numeric leaf shortcut, and add a mutable-`Real` regression test that checks build refusal. If mutable `BigFloat` is intended as an exception, that requires a design ruling and an ownership/copying rule; the current spec and D-237 provide neither.

### G-04 — cycle SCC accuracy: retired by implementation

Section 5.6 still requires SCC decomposition rather than reporting Kahn's whole stalled remainder (`spec.md:987-1000`), with exact members and wires in Appendix C (`spec.md:10925-10929`). The committed implementation retains edge provenance, decomposes the residue with Tarjan's algorithm, emits one diagnostic per nontrivial SCC, and sends each cluster through the cycle classifier (`HEAD:src/build.jl:403-438`, `HEAD:src/build.jl:451-514`).

The focused test constructs two disjoint cycles plus a downstream tail, asserts two exact member/wire sets, and verifies the tail belongs to neither; it also covers a self-loop (`HEAD:test/test_build.jl:121-147`). Later tests cover real/artificial classification. The baseline `{a,b}` plus downstream `c` over-report is fixed.

### G-05 — empty output stages: retired by implementation

Bare `(;)` remains a fail-fast `DeadStage` requirement (`spec.md:684`, `spec.md:775`, `spec.md:3287-3290`; D-194 at `decisions.md:6724-6725`). The committed probe checks the return shape and then emptiness in both stage positions (`HEAD:src/build.jl:239-257`, `HEAD:src/build.jl:1052-1071`).

The tests isolate each position by producing the complete declared port set from the other stage, then assert singular `DiagnosticError{DeadStage}` with the correct stage name (`HEAD:test/test_build.jl:38-53`, `HEAD:test/test_build.jl:75-85`). This directly closes the baseline reproducer without relying on `DeclaredNotProduced`.

### G-06 — enum defaults and missing probe values: retired as originally stated

The synthesis chain required by §9.3 is `zero` for reals, `false` for `Bool`, first enum instance, then `T()`, with an unavailable framework fallback reported as `MissingProbeValue` carrying face and type (`spec.md:3297-3309`; Appendix C at `spec.md:10900-10901`). The enum arm now exists (`src/declare.jl:381-385`). `cell_layout` distinguishes the framework fallback from an authored override and collects `MissingProbeValue` when the former has no constructor (`HEAD:src/build.jl:582-607`).

Tests cover one and two unavailable faces, a working custom override, and the enum-root case (`HEAD:test/test_build.jl:765-783`, `HEAD:test/test_build.jl:1149-1158`). That retires G-06's two stated mechanisms. An exception thrown *inside* an authored override is deliberately allowed to escape by the current code/test (`HEAD:src/build.jl:595-603`, `HEAD:test/test_build.jl:785-788`); that is framing, not absence of a synthesized default, and is assessed under G-07.

### G-07 — probe/bundle framing: partially retired

The original stage mechanisms are fixed. Committed HEAD routes declaration calls through `invoke_declaration` and bundle-taking probe calls through `invoke_probed`; the latter recognizes a `FieldError` against the supplied bundle as `BundleFieldError` and wraps other model exceptions as `UserCodeFraming`, while preserving framework carriers and interrupts (`HEAD:src/build.jl:16-63`). Focused tests cover all probed function families, declarations, correct bundle-field classification, a `FieldError` against the author's own type, and pass-through exceptions (`HEAD:test/test_build.jl:984-1055`). D-248 additionally specifies the runtime bundle-field species (`decisions.md:9033-9054`), implemented at the existing runtime catch site.

One framing seam remains. Section 13.2 says the framed set is “every user-authored method the build invokes” (`spec.md:7374-7387`), and §9.3 makes `probe_value` explicitly overridable (`spec.md:3297-3304`). Yet `cell_layout` calls `probe_value(P)` directly and rethrows an authored override's exception (`HEAD:src/build.jl:595-603`); the focused test requires the raw `MethodError` (`HEAD:test/test_build.jl:785-788`). The narrower D-248 bullet enumerates declarations and probed component functions, so the documents leave some room over whether the synthesis hook was intentionally excluded, but §13.2's universal sentence does not. On the current normative text, G-07 is only partially retired: bundle/stage/declaration framing is complete, while the custom synthesis seam still lacks path/face/function framing. Clarify the scope or route authored `probe_value` through a framing accessor.

### G-08 — canonical `ProbeDual`: retired by implementation

The spec names the public concrete alias and its purpose (`spec.md:3408-3416`), and the decision fixes the exact type (`decisions.md:2779-2780`). Committed HEAD defines `ProbeTag` and `const ProbeDual = ForwardDiff.Dual{ProbeTag,Float64,1}` (`HEAD:src/build.jl:671-681`). Focused tests assert concreteness, subtype and width, cache materialization, and eager activation failure payloads using `ProbeDual` (`HEAD:test/test_build.jl:1479-1495`). The symbol is directly available as `Cadence.ProbeDual` and is included in the suite's explicit public import inventory (`test/imports.jl:24`).

### G-09 — foreign declaration bindings: retired by design change and implementation

The baseline row expected shadowing context on `StoreWithoutUpdate` or `ClassUnreadable`. Current D-246 supersedes that placement: every component is checked before classification, and a foreign family binding throws fail-fast `DeclarationShadowed` alone (`decisions.md:8911-8944`; current spec `spec.md:1811-1828`). This is a design change in diagnostic kind and timing, while preserving and broadening the original error-locality goal to optional declarations.

The declaration layer inventories the full family and detects bindings distinct from Cadence's functions (`src/declare.jl:230-250`). The committed tree walk performs the check before `classify` (`HEAD:src/assembly.jl:830-846`). Tests cover the whole inventory, one required update declaration, optional events, assembly rates, and a passthrough parent, while declaration tests verify family order and sound-module negatives (`HEAD:test/test_assembly.jl:95-129`; `test/test_declare.jl:51-71`). G-09 is therefore retired under the ratified replacement design, rather than by adding the baseline report's proposed note fields.

### G-12 — probe values in runtime root cells: still open

Section 9.3 still says probe values are garbage after build and never serve as initial root-input values (`spec.md:3320-3330`). At committed HEAD, `Layout.root_inputs` stores each synthesized value (`HEAD:src/build.jl:543-546`, `HEAD:src/build.jl:599-607`), and executor compilation explicitly scatters those values into root cells (`HEAD:src/build.jl:1441-1455`). The public live-table accessor has no lifecycle gate (`src/sim.jl:1632-1633`).

The focused current-revision probe constructed a simulation with a `Float64` root input and read it before initialization:

```text
pre-init root input: lifecycle=built value=0.0
```

This remains a representation/lifecycle contract deviation. It does not establish a wrong initialized trajectory: complete-world application checks root-input totality and overwrites the cell before boundary zero, and `latest(sim)` remains `nothing` before `init!`. Retain the low severity. A structural fix would keep only root-input names, types, and addresses in the activation/runtime layout and leave runtime root cells uninitialized until a complete-world application, or the design must explicitly sanction pre-init fabricated values.

## `pending.md` reconciliation and limits

`pending.md` now has no “built in a shape the spec's is not” or “awaiting a ruling” entries (`pending.md:74-93`). That is consistent with retirement of F-08, F-09, G-04–G-06, G-08, and the D-246 replacement for G-09. It is not consistent with the current evidence for F-13 and G-12, and it does not record the `probe_value` framing ambiguity under G-07. Those three should remain visible in the refreshed top-level report unless the implementation changes or a docs-first ruling changes their contracts.

The current dirty payload work overlaps `pending.md:21-39` but is outside these named findings. It must remain provisional until committed and tested. This report makes no package-gate claim and no conclusion from the moving dirty worktree beyond noting that its inspected diffs did not alter F-13 or G-12.

## Addendum — D-252 and pipeline-design reconciliation at `2938a0` (2026-09-18)

This addendum freezes its claims to commit `2938a025c05bc136dd9f76f64cb42f89f4986d4c` and reviews only the delta from `7b1c1e8` that can affect F-08, F-09, F-13, G-04–G-09, G-12, or the report's auto-publication precedence item. No focused or full tests were run for this addendum; the parent audit owns those gates. Source and test references below are line numbers in the frozen commit, irrespective of later worktree movement.

### Disposition changes

| ID / item | Status at `2938a0` | Effect of `7b1c1e8..2938a0` |
| --- | --- | --- |
| F-08 | **Retired by implementation** | Unchanged. Nested component-bearing containers are still detected recursively (`src/assembly.jl:115-153`, `src/assembly.jl:200-202`) and covered in both tuple and named-tuple forms (`test/test_assembly.jl:183-195`). |
| F-09 | **Retired by implementation** | Unchanged. Enum leaf support remains (`src/leaves.jl:21-49`; `src/declare.jl:381-385`; `test/test_leaves.jl:140-151`). D-252 changes the enum-mode fixture from framework publication to an explicit stage-1 return, which the current test verifies (`test/test_build.jl:1147-1153`; `test/fixtures.jl:1200-1210`). |
| F-13 | **Still open — high** | Unchanged. Every subtype of `Real` still bypasses the mutability check (`src/leaves.jl:95-100`), while snapshots still shallow-copy leaf buffers (`src/dataplane.jl:575-577`). D-252 changes who writes a port, not the mutable-object aliasing mechanism. |
| G-04 | **Retired by implementation** | Unchanged. The stage-1 exemption now has only its intended meaning (`src/build.jl:351-393`), while stalled residues still undergo SCC decomposition (`src/build.jl:397-415`). Current tests cover the stage-1 loop break (`test/test_build.jl:333-343`) as well as the exact disjoint-cycle/tail cases already cited above. |
| G-05 | **Retired by implementation** | Unchanged. Both explicit output stages still reject an empty return (`src/build.jl:256-275`, `src/build.jl:992-1017`; `test/test_build.jl:38-53`, `test/test_build.jl:75-85`). Auto-publication no longer has to be excluded when isolating `DeadStage`; the tests already make the other stage produce every declared port. |
| G-06 | **Retired as originally stated** | Unchanged. Enum synthesis and the `MissingProbeValue` fallback remain in the same build path (`src/declare.jl:381-385`; `src/build.jl:537-563`), with the custom-override seam still separated under G-07 (`test/test_build.jl:751-774`). |
| G-07 | **Partially retired — medium residual** | Unchanged. The current spec makes `probe_value` overridable (`docs/design/spec.md:3407-3417`) while saying every user-authored method the build invokes is framed (`docs/design/spec.md:7563-7569`). D-252 removes one internal classifier branch but does not frame an authored override: the direct call and rethrow remain (`src/build.jl:550-558`), and the current test still expects the raw `MethodError` (`test/test_build.jl:771-774`). |
| G-08 | **Retired by implementation** | Unchanged. The canonical `ProbeDual` definition and focused activation tests remain (`src/build.jl:626-635`; `test/test_build.jl:1490-1506`). |
| G-09 | **Retired by D-246 plus implementation** | Unchanged. The foreign-declaration inventory and pre-classification failure remain (`src/declare.jl:230-250`; `src/assembly.jl:873-884`) with focused family coverage (`test/test_assembly.jl:97-130`; `test/test_declare.jl:51-71`). |
| G-12 | **Still open — low** | Unchanged. The current spec says probe values are discarded and never become initial root-input values (`docs/design/spec.md:3429-3439`). `Layout` still retains synthesized values (`src/build.jl:498-506`, `src/build.jl:537-568`), compilation still scatters them into live cells (`src/build.jl:1390-1397`), and the public live-table getter still has no lifecycle gate (`src/sim.jl:1642-1643`). D-252 does not affect root inputs. |
| Report item 4, auto-publication/stage-2 precedence | **Retired by D-252 design change and implementation** | The old three-producer question no longer exists. A declared output is produced only by `output_state` or `output_direct`; absence is `DeclaredNotProduced`, and overlap is `ProducedByTwoStages`. |

No named build/storage finding changes status in this bounded reconciliation. The material change is retirement of report item 4 under a new port model, rather than a ruling about precedence within the old model.

### Why auto-publication item 4 is now retired

D-252 expressly removes auto-publishing and supersedes the prior publication decisions: a declared port must be returned by stage 1 or stage 2, with no framework-written third class (`docs/design/decisions.md:9264-9276`). The current spec repeats that rule in §5.3 (`docs/design/spec.md:774-778`) and §8.3 (`docs/design/spec.md:2376-2383`). This resolves the earlier documentation tension structurally: there is no longer an automatic producer whose reservation could collide with stage 2.

The implementation matches that design:

- Stratum C derives the stage-1 set solely from `output_state`, schedules stage 2 from that set, then probes `output_direct` (`src/build.jl:838-855`).
- A port returned by both stages fails immediately as `ProducedByTwoStages` (`src/build.jl:1012-1017`); a declared port returned by neither is collected as `DeclaredNotProduced` (`src/build.jl:884-935`). The diagnostics carry exactly those two-stage semantics (`src/diagnostics.jl:856-879`).
- The compiled executor has only stage, RHS, and update entry classes, with no `PublishEntry` (`src/executor.jl:31-58`).
- Focused tests establish explicit state/mode exposure, stage-1 loop breaking, unreturned-store-field refusal, two-stage collision, and the walking-type check (`test/test_build.jl:313-375`). Representative fixtures now return exposed state and mode directly (`test/fixtures.jl:40-56`, `test/fixtures.jl:63-81`, `test/fixtures.jl:1200-1210`).

Accordingly, the top-level report's item 4 should be marked resolved by D-252 and its implementation. Its old question — whether a stage-2 return or automatic publication wins — should not be restated as a current ambiguity.

### Historical probe compatibility

`probes/build_confirmed_gaps.jl:25-28,77` is intentionally incompatible with the current contract. `AuditAutoPublished` declares state field `x` as an output but returns it from no stage. Under the baseline design that case probed missing auto-publication; at `2938a0` it must produce `DeclaredNotProduced`. Its label, comment, and any historical validation output remain baseline evidence only and must not be rerun or interpreted as a current defect probe without rewriting the component to implement `output_state` and changing the asserted question.

No other retained build probe contains an auto-publication component. Despite its filename, `probes/publication_allocation.jl` measures boundary snapshot publication and already supplies an explicit `output_state` (`probes/publication_allocation.jl:4-7`); D-252 does not invalidate that mechanism or turn its prior allocation output into evidence about port classification.

The earlier F-13 probe remains conceptually valid because its component explicitly returns its mutable numeric value from a stage. The G-12 observation also concerns synthesized root-input cells, not output publication. Neither was rerun here, in accordance with the bounded no-test instruction.

### D-250–D-258 boundary

This addendum does not infer implementation of the broader pipeline redesign from the ratified decisions. `pending.md` records D-252 as delivered by increment 43 and says that nothing else in the D-250–D-258 redesign is built yet (`docs/design/pending.md:21-39`). The current implementation map likewise names D-252 on `src/build.jl` but still describes the existing `Flat`, `Activation`, and executor architecture (`docs/design/implementation.md:21-28`). D-253 through D-258 therefore do not retire, reopen, or otherwise alter any of the bounded finding dispositions above; reviewing their future artifacts and migration is outside this reconciliation.
