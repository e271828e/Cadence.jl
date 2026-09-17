# Build, declarations, assembly, and feedthrough audit

Baseline: `865521a0f7be6894b1688925bb349dcbadd06539`  
Audit date: 2026-09-15  
Corpus restriction: `src/**`, `test/**`, and `docs/design/{implementation,spec,decisions}.md` only. `implementation.md` was read first. No other design or report file informed this review.

## Inspected scope and specification coverage

The primary source review covered all of `src/declare.jl`, `src/assembly.jl`, and `src/build.jl`. Supporting reads covered the build-facing portions of `src/leaves.jl`, `src/store.jl`, `src/executor.jl`, `src/sim.jl`, and `src/diagnostics.jl`. The test review covered all of `test/test_declare.jl`, `test/test_assembly.jl`, and `test/test_build.jl`, the associated declarations in `test/fixtures.jl`, and the deployment/build assertions in `test/test_discrete.jl`.

| Specification area | Subsections checked | Evidence followed through |
| --- | --- | --- |
| Component and port model | §§3.1–3.3 | component/assembly distinction, boundary faces, declaration ownership |
| Evaluation and feedthrough | §§5.1–5.6 | bundle signatures, two output stages, auto-publication, feedthrough edges, static schedule, algebraic-loop diagnosis |
| Wiring | §§6.1–6.2 | one-level connections, producer/consumer type relation, root inputs, fan-out, library wiring implications |
| Declaration and hierarchy | §§8.1–8.8 | contract purity, tier forms, state/store declarations, assembly classification, containers, paths/faces, rate scopes, passthrough sugar |
| Build and execution preparation | §§9.1–9.7 | strata, Build artifact, probing and framing, activation caching, checked scatter, deployment schedule, executor ownership |

The decisions review included D-012, D-032–D-033, D-048–D-058, D-117, D-135, D-166–D-168, D-179, D-207–D-212, D-229, and D-235–D-239 where they constrain this area.

Severity in this report means: **high** changes accepted model semantics or substantially misdiagnoses a structural failure; **medium** rejects a model the design admits, accepts one it rejects, or omits a required conformance surface; **low** is a narrower diagnostic, lifecycle, or inspectability deviation.

## Confirmed gaps and deviations

### 1. Declared state and mode outputs are not auto-published

**Severity: high.** Spec §5.3 requires a declared output matching an `x`, `m`, or `s` field and not produced by either stage to be copied from its owning store at stage 1 (`spec.md:774-779`); §8.3 repeats that publication is contract-driven (`spec.md:2340-2346`).

`probe_stage1` returns only an explicit `output_state` result (`src/build.jl:146-162`). The completeness pass then treats every declared-but-absent output as an error (`src/build.jl:659-672`); it has no state/mode publication arm. Thus a lawful component with `init_x(c) == (x=...)`, `output_types(c,T) == (x=T,)`, and no explicit output method fails with `DeclaredNotProduced`.

The reproducer is `AuditAutoPublished` in `probes/build_confirmed_gaps.jl:24-28`, invoked at line 77. It reports `DeclaredNotProduced`. Existing unproduced-output coverage does not exercise the required state-name case (`test/test_build.jl:16-18`, `test/test_build.jl:39-44`).

The diagnostic is also underspecified: Appendix C requires the stage-product and state-field lists, while `DeclaredNotProduced` carries only `ports` and `products` (`src/diagnostics.jl:709-718`).

### 2. An explicitly empty output stage is accepted

**Severity: medium.** Spec §5.2 says an explicitly present stage that returns `NamedTuple()` is a fail-fast `DeadStage` error (`spec.md:674-682`); §9.3 and Appendix C repeat this requirement (`spec.md:3241-3244`, `spec.md:10851-10853`).

Both probe passes accept an empty named tuple: stage 1 checks only that the return is a named tuple and that returned fields conform (`src/build.jl:151-162`), and stage 2 does the same (`src/build.jl:639-657`). No `DeadStage` diagnostic exists in `src/diagnostics.jl`.

The isolated reproducer has an empty `output_state` plus a valid `output_direct` that produces the complete output (`probes/build_confirmed_gaps.jl:30-34`). `build` succeeds (invocation at line 78), proving this is not merely a different error caused by an unproduced declaration. There is no corresponding focused test.

### 3. Algebraic-loop reporting uses the Kahn stall residue instead of SCCs

**Severity: high.** Spec §5.6 requires strongly connected component decomposition after a topological-sort stall, one diagnostic per nontrivial SCC, exact member/wire reporting, and trace-based real-versus-artificial classification where available (`spec.md:972-1016`, especially `spec.md:980-987`). D-012 fixes that design (`decisions.md:443-467`).

`schedule_stage2` reports every vertex left in Kahn's `remaining` set as one `AlgebraicCycle` (`src/build.jl:221-253`). A downstream acyclic tail remains in that set, so it is falsely named as a cycle member. `AlgebraicCycle` also carries only `members`, with neither cycle wires nor classification (`src/diagnostics.jl:690-697`). Multiple disjoint cycles would be collapsed into one diagnostic.

The probe graph contains the SCC `{a,b}` and innocent downstream `c` (`probes/build_confirmed_gaps.jl:36-48`); the result reports `members=["a","b","c"]` (invocation at line 79). The existing test uses a graph whose entire residual set is cyclic and therefore cannot expose the error (`test/test_build.jl:71-75`).

### 4. Probe-time user exceptions bypass the specified diagnostic framing

**Severity: high.** Spec §5.2 and §13.2 require a missing bundle field to become `BundleFieldError` and other user exceptions to become `UserCodeFraming` with component/stage context (`spec.md:638-652`, `spec.md:7316-7328`). §9.3 applies the same framing to probe execution (`spec.md:3286-3298`), and D-058 requires user exceptions to be wrapped (`decisions.md:1565-1580`).

User declarations and stage functions are invoked directly without a framing boundary in stage 1 (`src/build.jl:146-162`), stage 2 and update probing (`src/build.jl:639-711`), and event probing (`src/build.jl:753-775`). Neither required diagnostic kind exists in `src/diagnostics.jl`.

`AuditBundleMiss` reads absent `x` from its bundle (`probes/build_confirmed_gaps.jl:56-59`). `build` exposes a raw `FieldError` (invocation at line 81), losing the component path, callable, and build-stratum context.

### 5. Nested component containers are silently erased

**Severity: medium.** Spec §8.5 explicitly rejects containers of containers; a container field may contain components only, and nesting is not a second recursive child syntax (`spec.md:2445-2454`, especially `spec.md:2451-2452`).

`_children` counts only direct `AbstractComponent` elements. When that count is zero it treats the whole tuple/named tuple as inert data (`src/assembly.jl:120-127`). A tuple whose elements are themselves component containers therefore contributes no child and no diagnostic.

`AuditNestedContainer(((AuditDeadStage(),),))` (`probes/build_confirmed_gaps.jl:50-54`, invocation at line 80) builds successfully as an empty `Build`. Tests cover empty direct containers and mixtures of a direct component with data, but not a nested-container-only field (`test/test_assembly.jl:98-143`).

### 6. Enum-valued ports have zero leaves and are rejected

**Severity: medium.** The port contract expressly admits `Int`/`Bool`/enum leaves as pinned values (`spec.md:1993-1997`, `spec.md:2010-2017`, `spec.md:2135-2137`). This is separate from §7.1, which excludes enums only from continuous `x` and places them in modes (`spec.md:1320-1325`). D-237 does not close enums: it governs non-isbits immutable opaque handles, while enums are isbits primitive types (`decisions.md:8546-8556`).

`leaf_types` has explicit arms only for `Real` and `StaticArray`; its fallback recursively walks `fieldtypes(P)` (`src/leaves.jl:35-39`). An enum has no fields, producing an empty leaf list. `cell_layout` rejects every empty list as `IllegalPortType` (`src/build.jl:283-300`).

The discrete enum output at `probes/build_confirmed_gaps.jl:71-75` is rejected with `IllegalPortType` (invocation at line 83). No focused enum port/mode test exists.

### 7. Root probe-value synthesis lacks enum support and diagnostic conversion

**Severity: medium.** Spec §9.3 requires framework synthesis for `Real`, `Bool`, and enum types, then `T()` as a fallback, with an unsatisfied fallback reported as `MissingProbeValue(face,type)` (`spec.md:3250-3266`). D-051 makes the seam and failure mode explicit (`decisions.md:1390-1399`).

`probe_value` implements `Real`, `Bool`, `StaticArray`, and an unconditional `P()` fallback (`src/declare.jl:331-334`). There is no enum-first method and no catch that associates constructor failure with the root face. `MissingProbeValue` does not exist in `src/diagnostics.jl`.

The custom no-default root-input type in `probes/build_confirmed_gaps.jl:61-69` exposes a raw `MethodError` (invocation at line 82). Enum root input synthesis is additionally blocked by finding 6 before this seam can run.

### 8. The public canonical `ProbeDual` scalar is absent

**Severity: medium.** Spec §9.4 requires public `const ProbeDual = ForwardDiff.Dual{ProbeTag,Float64,1}` so CI and users can request the canonical exhaustive activation (`spec.md:3360-3374`). No `ProbeDual` or `ProbeTag` definition exists under `src/**`.

The activation machinery itself accepts concrete scalar types and caches them correctly (`src/build.jl:564-570`), but tests substitute their own `D8` type (`test/test_build.jl:646-733`). Consequently the suite verifies activation behavior without verifying the required public interface.

### 9. Same-name foreign declaration bindings are not detected

**Severity: medium.** Spec §8.1 requires the build to inspect the component's parent module when a required declaration appears absent and distinguish a same-name foreign binding: `StoreWithoutUpdate` gains that note, and otherwise the failure is `ClassUnreadable` (`spec.md:1791-1800`). D-117 records the diagnostic intent (`decisions.md:3372-3383`).

Class and tier detection query only Cadence's declaration generics (`src/assembly.jl:39-49`, `src/build.jl:86-113`). They never examine `parentmodule(typeof(c))` for a foreign binding. The associated diagnostic payloads have no shadowing provenance (`src/diagnostics.jl:393-429`). A Julia 1.12+ missing import can therefore present as an unrelated class/store failure rather than the required actionable diagnosis.

### 10. Contract arity mismatches use the wrong diagnostic kind

**Severity: low.** The detailed §8.5 rule classifies a continuous contract missing the `T` form, a discrete contract carrying it, or a too-narrow `T` bound as `TierSignatureMismatch`, with found and mandated forms (`spec.md:2571-2585`). Appendix C likewise assigns stateful `input_types`/`output_types` form mismatches to that kind (`spec.md:10788-10797`). However, the neighboring `DeclarationOnWrongTier` inventory entry includes an `output_types` arity (`spec.md:10782-10787`). The normative diagnostic taxonomy is therefore internally inconsistent at that boundary.

`classify_tier` emits `DeclarationOnWrongTier(reason=:tier_form)` for arity votes (`src/build.jl:117-129`). `TierSignatureMismatch` explicitly handles only the narrow-bound arm (`src/diagnostics.jl:472-479`). Tests encode the current split and require `DeclarationOnWrongTier` for the stateful `WrongArity` case (`test/test_build.jl:502-511`). This follows one inventory sentence but violates §8.5 and the more detailed `TierSignatureMismatch` entry, and omits the mandated found/form payload. A spec clarification is needed before changing the stateless `BothArities` behavior.

### 11. Build and bound-schedule inspectability is incomplete

**Severity: medium.** Spec §9.2 requires a stable printable Build artifact with raw wire/face tables, root inputs, anchor and component tables including declaration provenance, and a printable bound schedule/hyperperiod chart (`spec.md:3125-3173`). It further specifies diagnostic derivation details and `GridUtilization` (`spec.md:3193-3220`).

The raw `Build` retains useful internal vectors and dictionaries (`src/build.jl:355-380`), but defines no `show`/printer and no A0-inclusive anchor/component presentation. `bind_schedule` returns discrete rows containing only `(path,D,Φ,Δt)` (`src/build.jl:940-951`); it omits rate-scope rows, anchor identity, and declaration provenance. No `GridUtilization` kind or hyperperiod renderer exists under `src/**`.

Tests verify numeric schedule cells and infer the worked hyperperiod by executing the model (`test/test_discrete.jl:160-196`); they do not exercise the required artifact renderings. The arithmetic and runtime gate are covered and appear correct; this finding is about the required inspection and explanation surface.

### 12. Probe values are copied into the runtime root-input table

**Severity: low.** Spec §9.3 says probe values are strictly probe-scoped garbage after build and “never double as initial root-input values” (`spec.md:3274-3284`). `Layout` retains `(face, probe_value)` pairs (`src/build.jl:268-270`, `src/build.jl:307-319`), and executor compilation scatters them into the runtime store (`src/build.jl:1081-1084`).

This is externally observable through a port accessor between `Simulation` construction and `init!`. It does **not** currently establish a wrong initialized trajectory: complete-world application requires all root inputs and overwrites them before boundary zero, while run/capture lifecycle gates prevent normal advancement from the built state. The defect is therefore a representation/lifecycle contract deviation, not evidence that initialized simulations consume defaults.

### 13. Several structural diagnostics omit specified provenance

**Severity: low.** These omissions do not change rejection, but reduce the actionable payload required by Appendix C:

- `ContainerMixed` must name offending keys/indices and types, while it carries only unique types (`src/assembly.jl:123-126`, `src/diagnostics.jl:442-451`; requirement `spec.md:10780-10781`).
- `FaceNameCollision` must carry both entries' provenance, while it carries the names/site without both declaration origins (`src/assembly.jl:819-828`, `src/diagnostics.jl:500-513`; requirement `spec.md:10798-10801`).
- `AlgebraicCycle` must include exact wires and tracing classification, as covered in finding 3 (`spec.md:10836-10839`).

Focused tests assert the reduced payloads, for example only `field` and `types` for `ContainerMixed` (`test/test_assembly.jl:123-141`).

## Design improvements

1. Route every probe-time user call through one wrapper that knows `(path, callable, stratum)`. Convert a `FieldError` against the supplied bundle into `BundleFieldError`; wrap every other non-framework exception as `UserCodeFraming`. Reuse it for stages, update laws, projection, events, declarations that are evaluated, and workspace allocation.
2. Build an explicit per-component production plan: explicit stage-1 keys, auto-published store keys, and explicit stage-2 keys. Validate `DeadStage`, collisions, and completeness on that plan before probing downstream consumers. This makes auto-publication part of scheduling rather than a special case after execution.
3. Preserve the stage-2 dependency graph with edge provenance, then run Tarjan or Kosaraju on a Kahn stall. Emit one diagnostic per nontrivial SCC and derive an actual cycle path/wire set from each SCC.
4. Classify container fields recursively enough to distinguish inert data, a direct component container, mixed content, and forbidden nested component containers. Preserve offending element paths in the diagnostic.
5. Give primitive isbits atoms such as enums an explicit leaf rule. Keep §7.1's continuous-state vocabulary check separate from the more general port leaf walk.
6. Store only root-input names/types/addresses in `Activation`. Allocate runtime root cells uninitialized, then let the complete-world application establish them. This enforces probe scoping structurally.
7. Expose immutable inspection records for Build and deployment binding, and make `show` render those records. Include A0, rate-scope provenance, component affine triples, bound rows, and the hyperperiod chart without requiring access to internal fields.
8. Add table-driven tests from Appendix C for diagnostic kind and required payload fields. Current tests often prove rejection while fixing a smaller payload or a neighboring kind.

## Ruled-out suspicions and limits

- **Normal acyclic feedthrough scheduling:** stage-2 consumers add edges only for stage-2 producer ports; stage-1 products correctly break instantaneous dependencies (`src/build.jl:221-231`). The executor evaluates stage 1 before the ordered stage-2 sweep. No ordinary scheduling-order defect was found outside the cycle-reporting issue.
- **Wire typing and root-input fan-out:** nominal and marker-scalar checks, abstract bounds, and the root-input whole-type meet are implemented and have substantial focused coverage. No acceptance/rejection error was confirmed in these paths.
- **Activation cache races:** the lookup/build/`get!` sequence may duplicate a first computation, but the lock ensures all callers receive the canonical stored activation (`src/build.jl:564-570`). The concurrent identity test covers this (`test/test_build.jl:736-747`).
- **Per-Simulation buffer ownership:** compilation allocates fresh state, store, and cell buffers for each simulation. Tests comparing deployments and simulations support the intended separation. No shared mutable executor buffer was found.
- **Always-on output checks:** probe checks are not the sole defense; generated scatter paths enforce return keys/types during execution. The order-insensitive named-tuple handling and state-write checks appear consistent with D-235/D-238.
- **Rate arithmetic and gating:** exact rational deployment validation, affine scope composition, and `(idx-Φ) % D` gating have broad tests. Finding 11 is limited to inspectability and specified rendering.
- **Contract dependence on component values:** §8.1/D-033 require contract names and shapes to depend on type, not instance fields, but D-033 explicitly treats this as an author rule the build cannot generally check. This review did not classify the absence of an impossible general check as an implementation bug.
- **Deep immutability:** `Build` and `Activation` are immutable structs containing mutable collections, and the activation cache is intentionally mutable. No internal post-construction mutation of nominal structure was found. Stronger encapsulation would make the promise easier to enforce, but the audit found no concrete corruption path through the supported API.
- **Probe-root runtime impact:** as stated in finding 12, the retained values are visible before initialization but current totality and lifecycle rules prevent them from becoming initialized simulation inputs through the supported run path.

## Verification

`docs/reports/20260915_audit/probes/build_confirmed_gaps.jl` was run with:

```text
julia --project=test docs/reports/20260915_audit/probes/build_confirmed_gaps.jl
```

Observed results:

```text
auto-publication: DeclaredNotProduced
dead stage: build succeeds
cycle with downstream tail: AlgebraicCycle members=["a", "b", "c"]
nested container: build succeeds as an empty Build
bundle field framing: raw FieldError
missing probe value: raw MethodError
enum port: IllegalPortType
```

The main audit's direct suite completed **2425/2425** assertions on Julia 1.13.0. That green suite is compatible with these findings because the focused gaps above are absent from the suite or the current tests encode the reduced behavior described in each finding.

## Current-revision reconciliation (`f941c504c90eadbad9950a182feafa96b300a642`)

The findings above are the historical audit of the requested baseline, `865521a0f7be6894b1688925bb349dcbadd06539`. This reconciliation is limited to the subsequent diff in `src/build.jl`, `src/diagnostics.jl`, `src/executor.jl`, and the assigned build/declaration/assembly tests and fixtures. It does not reinterpret unchanged findings as newly reprobed results.

### Resolved in the inspected diff

- **Finding 1's simple auto-publication absence is resolved.** The current build computes each component's eligible state/mode publications before stage-2 scheduling (`src/build.jl:214-284`, `src/build.jl:668-688`), carries that set in the activation, probes with the published products already present (`src/build.jl:714-755`), and compiles store-to-cell `PublishEntry` operations (`src/executor.jl:88-120`). Current focused tests cover continuous state and mode fields, discrete state, feedthrough-loop breaking, runtime updates, nonnominal activation behavior, and collisions (`test/test_build.jl:79-155` and the corresponding tier tests in the inspected diff).
- **The `DeclaredNotProduced` state-field payload sub-gap in finding 13 is resolved.** The build now supplies the tier's state-field list when declared outputs remain unproduced (`src/build.jl:232-233`, `src/build.jl:758-771`), and tests distinguish an absent product from a same-name field of the wrong type (`test/test_build.jl:117-123`).

### Still present within the bounded diff

The inspected changes do not alter the mechanisms behind findings 2–12, except for the auto-publication portion of finding 1, or the remaining `ContainerMixed`, `FaceNameCollision`, and `AlgebraicCycle` payload parts of finding 13. In particular, the stage-2 residue algorithm is unchanged apart from treating published ports as stage-1-position products, so the downstream-tail cycle over-report in finding 3 remains; declaration, assembly/container, enum-leaf, probe-framing, shadow-binding, tier-taxonomy, inspection, and root-input materialization paths received no corrective change relevant to their findings.

### Unresolved specification tension: stage 2 versus auto-publication precedence

The current implementation deliberately reserves a matching state field for framework publication whenever stage 1 did not return the port (`src/build.jl:259-274`). If `output_direct` then returns the same name, probing reports `ProducedByTwoStages` because publication occupies the stage-1 position (`src/build.jl:737-755`); `Twice` fixes that behavior in a focused test (`test/test_build.jl:125-132`). This is coherent with §9.1's requirement to classify ports before stage-2 probing (`spec.md:3018-3020`).

However, §5.3 describes auto-publication for a matching port “that no stage produces” (`spec.md:774`), and §8.3 repeats the no-stage condition (`spec.md:2341`). Read literally, those clauses could instead let an explicit stage-2 producer suppress auto-publication. The documents therefore leave precedence ambiguous between pre-stage-2 reservation and an explicit stage-2 result. This review does not classify the current choice as a confirmed implementation defect; the specification should state which producer wins and at what point publication membership becomes fixed.

The main auditor is running the current-revision package gate. No current full-suite result is claimed here.
