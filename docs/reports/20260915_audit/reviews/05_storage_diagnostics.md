# Storage and diagnostics conformance review

**Revision audited:** `f941c504c90eadbad9950a182feafa96b300a642`  
**Date:** 2026-09-16  
**Disposition:** read-only source audit; this report and its `storage_*.jl` probe are the only authored artifacts.

## Scope and method

I read `docs/design/implementation.md` first, then audited the following permitted surface against the current revision:

- complete source files `src/leaves.jl`, `src/store.jl`, and `src/diagnostics.jl`;
- diagnostic definitions colocated with the runtime channel in `src/dataplane.jl:28-156`;
- the storage/diagnostic integration sites needed to validate behavior: declaration defaults and bundle sets (`src/declare.jl:275-334`), state/store checks and build probes (`src/build.jl:18-212,334-404,690-930,1307-1375`), structural and wiring construction (`src/assembly.jl:39-49,110-142,681-693`), stop-face validation (`src/sim.jl:212-242`), attachment face validation (`src/roster.jl:195-211`), and replay construction sites (`src/trace.jl:328-356,404-453`);
- complete `test/test_leaves.jl`, `test/test_store.jl`, `test/test_diagnostics.jl`, and `test/test_failures.jl`, plus relevant assertions/fixtures found in the permitted `test/**` tree;
- specification §§4.1–4.4 (`docs/design/spec.md:337-525`), §§7.1–7.5 (`:1316-1694`), §9.3 probe synthesis (`:3221-3310`), §9.5 (`:3403-3535`), §§13.1–13.4 (`:7194-7660`), and Appendix C (`:10659-11036`);
- relevant ratified decisions through D-241, especially D-051, D-057–D-059, D-092, D-094, D-113, D-142, D-151, D-157, D-164, D-166, D-168, D-203, D-210–D-215, D-228–D-229, D-235–D-239, and D-241.

No excluded report or pending-design file was read or used. Tests and comments were treated as evidence of exercised behavior, not proof of conformance.

## Executive result

The generated flatten/reconstruct and mixed-store machinery is internally coherent on its intended immutable vocabulary. The focused tests pass, and I found no numeric index, offset, field-order, or state-topology defect in those paths.

The material deviations are at the vocabulary and diagnostic boundaries:

1. a mutable subtype of `Real` bypasses the mutable-port rejection and exposes a live cell by reference;
2. five specified build diagnostics/behaviors are absent, producing raw Julia exceptions or silent acceptance;
3. Appendix C's closed set has eight source-level omissions, four of which correspond to currently absent runtime/deployment features;
4. the kind-inventory test is self-referential and therefore cannot detect a kind omitted from both code and tests;
5. twelve present kinds had payload discrepancies at this review revision; the final path-resolution delta resolves one, leaving eleven in SD-06.

## Confirmed findings

### SD-01 — High — Mutable `Real` values bypass the port immutability gate and alias the live cell

**Normative requirement.** Ports exchange immutable values (`docs/design/spec.md:339-370`). The leaf-walk rule says a mutable type anywhere in a port value is refused (`:436-441`); D-237 repeats that rule (`docs/design/decisions.md:8546-8556`).

**Implementation.** `_mutable_position` returns `nothing` for every subtype of `Real` before asking `ismutabletype(P)` (`src/leaves.jl:84-95`). `cell_layout` trusts that result to decide whether to raise `IllegalPortType(:mutable)` (`src/build.jl:352-371`). The generated scatter stores the value directly (`src/leaves.jl:128-147`; `src/store.jl:55-67`), and gather returns that same object (`src/leaves.jl:102-123`; `src/store.jl:42-53`).

**Reproducer and observed mechanism.** `docs/reports/20260915_audit/probes/storage_diagnostic_gaps.jl:69-95` first shows that mutable `BigInt <: Real` builds. It then declares a minimal `mutable struct MutableScalar <: Real`, publishes it, retrieves it with `port`, mutates the retrieved object, and observes the live cell change from `1.0` to `9.0`. The probe exits zero and prints `mutating a gathered mutable Real changed the live cell value`.

**Impact.** A consumer, logger, or other reader can mutate a producer's published value under every other reader. This directly breaks the no-aliasing and concurrent-read arguments in §4.1; it is not only a nominal type-admission discrepancy.

**Test gap.** `test/test_leaves.jl:140-146` covers mutable arrays and an opaque immutable handle, but no mutable `Real`. `test/test_store.jl:182-230` validates identity sharing only for an immutable handle around frozen bulk data, which is the sanctioned case.

**Repair direction.** Apply `ismutabletype(P)` before the `P <: Real` leaf exit. If a particular mutable numeric family is intended as a value-like exception, that exception requires a design ruling because the present normative rule is unconditional.

### SD-02 — Medium — Probe-value synthesis violates the enum and missing-default contracts

**Normative requirement.** Root-input synthesis has framework methods for `Real`, `Bool`, and enums (first instance), then `T()`; failure must be `MissingProbeValue` with face and type (`docs/design/spec.md:3251-3266`; D-051 at `docs/design/decisions.md:1390-1399`). Enums are also listed as ordinary immutable port values (`docs/design/spec.md:339-343`).

**Implementation.** The methods implement `Real`, `Bool`, `StaticArray`, and unguarded `P()` only; no enum method or exception translation exists (`src/declare.jl:326-334`). Layout rejects a type with no walked leaves before synthesis (`src/build.jl:352-398`). Thus an enum root input is diagnosed as `IllegalPortType(reason = :no_leaves)`. A leaf-bearing immutable type without a zero-argument constructor reaches `probe_value(P)` and leaks a raw `MethodError` (`src/build.jl:385-398`). `MissingProbeValue` has no source definition.

**Reproducer.** `storage_diagnostic_gaps.jl:11-39` asserts both outcomes. The run printed:

```text
enum probe synthesis was rejected first as IllegalPortType(:no_leaves)
missing probe value raised raw MethodError
```

**Impact.** The documented enum fallback is unreachable, and the missing-default failure loses the required face/type diagnostic and collected build policy.

**Test gap.** No permitted test names `MissingProbeValue`; the Appendix inventory test only compares implemented subtypes (see SD-05).

### SD-03 — Medium — Probe-stage failure framing and dead-stage enforcement are absent

Three related fail-fast contracts are missing:

- A stage returning bare `(;)` must raise `DeadStage` (`docs/design/spec.md:3241-3244`; Appendix C `:10849-10853`). `probe_stage1` and `probe_stage2` accept every `NamedTuple`, including the empty one (`src/build.jl:146-162,737-755`). `storage_diagnostic_gaps.jl:41-48` builds such a stage successfully.
- Probe-time model exceptions must become `UserCodeFraming` with path, function, context, and cause (`docs/design/spec.md:3286-3298,7221-7230`; Appendix C `:10866-10871`; D-058 `docs/design/decisions.md:1569-1578`). Calls such as `output_state(...)` are made with no framing catch (`src/build.jl:146-160`); the probe's `ArgumentError` escapes unchanged (`storage_diagnostic_gaps.jl:50-57`). The same unframed pattern is visible at stage 2 and events (`src/build.jl:737-749,854-875`).
- An illegal requested bundle field must be `BundleFieldError` at probe and a `StepError` species later (`docs/design/spec.md:7283-7287,10860-10865`). The legal field sets exist (`src/declare.jl:279-323`), but a destructuring request for an absent field is left to Julia dispatch. The probe gets raw `FieldError` (`storage_diagnostic_gaps.jl:59-67`).

None of `DeadStage`, `UserCodeFraming`, or `BundleFieldError` is defined in `src/**`.

**Impact.** One invalid component is silently admitted; two other authoring failures lose the stable kind/payload and probe context that Appendix C makes the acceptance contract. The runtime bundle case necessarily becomes `StepError{FieldError}`, rather than the specified diagnostic species.

### SD-04 — Medium — Four additional Appendix C kinds are absent with their owning features

Appendix C is a normative closed set (`docs/design/spec.md:10659-10668`; D-092 at `docs/design/decisions.md:2549-2557`). In addition to the four build kinds in SD-02/03, these source types do not exist:

- `GridUtilization`, required for derived-grid deployment binding (`docs/design/spec.md:3215-3220,10953-10957`);
- `DebtReanchor` (`:11001-11002`);
- `ThreadBudget` (`:11011-11012`);
- `UnboundedRun` (`:11032-11036`).

The runtime channel's closed `DiagValue` union contains only its nine implemented warning types (`src/dataplane.jl:56-137`), so the three missing runtime kinds could not be reported even if a site attempted to construct them.

This finding records closed-set conformance. I did not reclassify each absent owning feature as a new storage bug; the inventory distinguishes those feature-coupled omissions from the directly reproduced build failures.

### SD-05 — Test-design gap — The diagnostic kind-set test cannot detect normative omissions

The test says it covers the Appendix C closed set, but constructs occurrences only for types already imported from the implementation (`test/test_diagnostics.jl:240-249`) and finally compares those occurrences with `subtypes(Diagnostic)` (`:522-525`). That proves every *implemented* subtype has a fixture. It cannot prove every Appendix C row has an implementation: deleting a type and its occurrence preserves equality.

The same issue affects warning severity: `warning_kinds` is an implementation-maintained list (`test/test_diagnostics.jl:509-516`), already omitting the absent Appendix C warning kinds.

**Observed false confidence.** `diagnostics` passes all 593 assertions while eight of 79 normative kinds are absent.

**Repair direction.** Maintain an explicit expected-name inventory derived independently from Appendix C (or generate it from a checked design artifact), compare it to `nameof.(subtypes(Diagnostic))`, and require one payload fixture per expected name.

### SD-06 — Low, with overlaps — Twelve historical payload discrepancies; eleven remain

Appendix C says tests match kind plus payload fields and that its rows are the acceptance contract (`docs/design/spec.md:10659-10668`). The following table records structured-payload discrepancies at `f941c50`. Some overlap substantive findings above. Runtime conformance time remains available on the outer `StepError`; that row concerns schema placement, not loss of the time from runtime evidence. `PathResolution` is now resolved as noted below.

| Kind | Appendix C requirement | Implemented payload/site | Missing structured data |
|---|---|---|---|
| `UnconnectedInput` | leaf path, input, declared entry type, obligation-chain last level (`spec.md:10736-10738`) | `path`, `face` only (`src/diagnostics.jl:267-270`); site supplies those two (`src/assembly.jl:687-691`) | entry type and chain level |
| `PathResolution` **resolved at `6986ad4`** | for generic read traversal, offending field's declared type (`spec.md:10750-10755`) | `entry`, spelling/reason/owner/segment/level/candidates/tail (`src/diagnostics.jl:361-370`) | declared type arm |
| `StoreWithoutUpdate` | store, missing update, shadowing note (`spec.md:10765-10769`) | `path`, `store` (`src/diagnostics.jl:394-397`; construction `src/build.jl:100-106`) | update identity is only derivable; shadowing provenance is absent |
| `ClassUnreadable` | path, component type, declarations found, both family lists, shadowing/did-you-mean context (`spec.md:10774-10778`) | `path`, one rendered family string, `holds_components` (`src/diagnostics.jl:419-423`; site `src/assembly.jl:39-49`) | type, declarations, separate family lists, shadowing provenance |
| `ContainerMixed` | offending element keys/indices and types (`spec.md:10780-10781`) | field plus unique noncomponent types (`src/diagnostics.jl:443-447`; site `src/assembly.jl:120-126`) | positions/keys; duplicates of a type collapse |
| `TierUnreadable` | path, type, declarations found, tier-family list (`spec.md:10820-10823`) | path and declarations (`src/diagnostics.jl:616-619`; site `src/build.jl:109-113`) | component type and family list |
| `AlgebraicCycle` | member terminals, wires, optional classification and dead-hop member (`spec.md:10834-10839`) | component-path residue only (`src/diagnostics.jl:690-697`) | terminals, wires, classification/hop |
| `ProducedByTwoStages` | port and both stage names (`spec.md:10840-10842`) | `path`, vector of ports (`src/diagnostics.jl:700-703`; construction `src/build.jl:750-754`) | both producer identities; current auto-publication collisions also cannot name stage vs framework |
| `ConformanceFailure` | field diff and simulation time (`spec.md:10854-10858`) | detailed diff, no time (`src/diagnostics.jl:740-751`) | simulation time; at runtime it exists only on the outer `StepError` |
| `StopFaceInvalid` | face/reason/list plus constructor vs `run!` binding site (`spec.md:10881-10884`) | face/reason/declared/candidates (`src/diagnostics.jl:878-883`; site `src/sim.jl:217-240`) | binding site |
| `AttachUnknownFace` | device type, binding entry, face, root list (`spec.md:10892-10894`) | binding type, face, candidates (`src/diagnostics.jl:969-973`; site `src/roster.jl:201-209`) | device type and concrete binding entry/provenance |
| `ReplayHeaderMismatch` | mismatch plus build and trace provenance (`spec.md:10958-10965`) | discriminator/path/name/expected/found (`src/diagnostics.jl:1480-1486`; sites `src/trace.jl:328-356,419-453`) | both provenance values |

`DeclaredNotProduced` is not in this table: the current revision now carries both `products` and `state_fields` (`src/diagnostics.jl:710-721`), matching the amended auto-publication contract.

## Appendix C complete kind inventory

The inventory below parses the 79 normative rows in `docs/design/spec.md:10730-11036` and checks current `src/**` definitions. “Present; schema gap” points to SD-06. Presence alone does not assert correct trigger/policy.

| # | Appendix C kind | Current definition | Result |
|---:|---|---|---|
| 1 | `UnknownPort` | `src/diagnostics.jl:250` | present |
| 2 | `UnconnectedInput` | `src/diagnostics.jl:267` | present; schema gap |
| 3 | `TwoProducers` | `src/diagnostics.jl:277` | present |
| 4 | `WireTypeMismatch` | `src/diagnostics.jl:289` | present |
| 5 | `WalkingFaceAtFrozenEntry` | `src/diagnostics.jl:305` | present |
| 6 | `PathResolution` | `src/diagnostics.jl:361` (review baseline) | present; historical schema gap resolved at `6986ad4` |
| 7 | `AbstractAtRoot` | `src/diagnostics.jl:324` | present |
| 8 | `RootInputTypeConflict` | `src/diagnostics.jl:348` | present |
| 9 | `IllegalStateLeaf` | `src/diagnostics.jl:651` | present |
| 10 | `StoreWithoutUpdate` | `src/diagnostics.jl:394` | present; schema gap |
| 11 | `EventHalfMissing` | `src/diagnostics.jl:404` | present |
| 12 | `ClassUnreadable` | `src/diagnostics.jl:419` | present; schema gap |
| 13 | `ClassMixed` | `src/diagnostics.jl:432` | present |
| 14 | `ContainerMixed` | `src/diagnostics.jl:443` | present; schema gap |
| 15 | `DeclarationOnWrongTier` | `src/diagnostics.jl:454` | present |
| 16 | `TierSignatureMismatch` | `src/diagnostics.jl:473` | present |
| 17 | `FaceNameIllegal` | `src/diagnostics.jl:488` | present |
| 18 | `FaceNameCollision` | `src/diagnostics.jl:501` | present |
| 19 | `FaceDirectionConflict` | `src/diagnostics.jl:516` | present |
| 20 | `UnknownFaceSelection` | `src/diagnostics.jl:530` | present |
| 21 | `RatesViolation` | `src/diagnostics.jl:547` | present |
| 22 | `MissingProbeValue` | — | **absent; SD-02** |
| 23 | `ChildNameCollision` | `src/diagnostics.jl:578` | present |
| 24 | `TransparentContainerUnknown` | `src/diagnostics.jl:603` | present |
| 25 | `TierUnreadable` | `src/diagnostics.jl:616` | present; schema gap |
| 26 | `IllegalPortType` | `src/diagnostics.jl:628` | present |
| 27 | `IllegalStoreField` | `src/diagnostics.jl:674` | present |
| 28 | `AlgebraicCycle` | `src/diagnostics.jl:691` | present; schema gap |
| 29 | `ProducedByTwoStages` | `src/diagnostics.jl:700` | present; schema gap |
| 30 | `DeclaredNotProduced` | `src/diagnostics.jl:710` | present; current state-field payload included |
| 31 | `UndeclaredReturnField` | `src/diagnostics.jl:724` | present |
| 32 | `DeadStage` | — | **absent; SD-03** |
| 33 | `ConformanceFailure` | `src/diagnostics.jl:740` | present; schema gap |
| 34 | `GuardForm` | `src/diagnostics.jl:811` | present |
| 35 | `BundleFieldError` | — | **absent; SD-03** |
| 36 | `HandlerReturnKey` | `src/diagnostics.jl:823` | present |
| 37 | `UserCodeFraming` | — | **absent; SD-03** |
| 38 | `MissingInit` | `src/diagnostics.jl:840` | present |
| 39 | `ServiceLifecycle` | `src/diagnostics.jl:849` | present |
| 40 | `StopFaceInvalid` | `src/diagnostics.jl:878` | present; schema gap |
| 41 | `DeploymentInvalid` | `src/diagnostics.jl:895` | present |
| 42 | `AttachUnknownFace` | `src/diagnostics.jl:969` | present; schema gap |
| 43 | `AlreadyAttached` | `src/diagnostics.jl:979` | present |
| 44 | `CallerTaskConflict` | `src/diagnostics.jl:989` | present |
| 45 | `ClaimConflict` | `src/diagnostics.jl:998` | present |
| 46 | `EmptyGreedyClaim` | `src/diagnostics.jl:1008` | present |
| 47 | `BindingContractMismatch` | `src/diagnostics.jl:1018` | present |
| 48 | `DeviceContractMismatch` | `src/diagnostics.jl:1056` | present |
| 49 | `ReadBindingUnresolved` | `src/diagnostics.jl:1068` | present |
| 50 | `ConditionResolution` | `src/diagnostics.jl:1102` | present |
| 51 | `DuplicateConditionLeaf` | `src/diagnostics.jl:1171` | present |
| 52 | `ConditionNodeMisuse` | `src/diagnostics.jl:1184` | present |
| 53 | `UninitializedInputs` | `src/diagnostics.jl:1201` | present |
| 54 | `TapResolution` | `src/diagnostics.jl:1212` | present |
| 55 | `TrimProblemInvalid` | `src/diagnostics.jl:1268` | present |
| 56 | `TrimCommitEvents` | `src/diagnostics.jl:1322` | present |
| 57 | `TrimCommitResiduals` | `src/diagnostics.jl:1333` | present |
| 58 | `ConditionShapeDrift` | `src/diagnostics.jl:1344` | present |
| 59 | `GridUtilization` | — | **absent; SD-04** |
| 60 | `ReplayHeaderMismatch` | `src/diagnostics.jl:1480` | present; schema gap |
| 61 | `ReplaySchemaMismatch` | `src/diagnostics.jl:1521` | present |
| 62 | `ReplayUnknownFace` | `src/diagnostics.jl:1535` | present |
| 63 | `ArgumentInvalid` | `src/diagnostics.jl:1367` | present |
| 64 | `ReadSetMisuse` | `src/diagnostics.jl:1445` | present |
| 65 | `NotAttached` | `src/diagnostics.jl:1462` | present |
| 66 | `StepError` | `src/diagnostics.jl:156` | present carrier (intentionally not a `Diagnostic` subtype) |
| 67 | `NonfiniteState` | `src/diagnostics.jl:219` | present |
| 68 | `ChatteringBudget` | `src/dataplane.jl:84` | present |
| 69 | `FiringBudget` | `src/dataplane.jl:93` | present |
| 70 | `DebtReanchor` | — | **absent; SD-04** |
| 71 | `ClaimedFaceEntry` | `src/dataplane.jl:69` | present |
| 72 | `OutOfClaimEntry` | `src/dataplane.jl:61` | present |
| 73 | `ThreadBudget` | — | **absent; SD-04** |
| 74 | `DeviceJoinTimeout` | `src/dataplane.jl:113` | present |
| 75 | `DeviceCrash` | `src/dataplane.jl:102` | present |
| 76 | `ReplayDiscardedStaging` | `src/dataplane.jl:129` | present |
| 77 | `MalformedDatum` | `src/dataplane.jl:56` | present |
| 78 | `EntryTypeMismatch` | `src/dataplane.jl:77` | present |
| 79 | `UnboundedRun` | — | **absent; SD-04** |

`DiagnosticError` (`src/diagnostics.jl:70`) and `InternalInvariant` (`:238`) correctly sit outside the Appendix C diagnostic-kind rows as carrier/internal exception types. Their absence from the 79-row table is intentional.

## Storage and leaf-walk deep-audit conclusions

### Confirmed conforming behavior

- The flat walk and generated reconstruction use the same recursive ordering for `Real`, static arrays, isbits structs, named tuples, and opaque handles (`src/leaves.jl:23-49,102-147`). Tests exercise nonzero offsets, matrices, named tuples, mixed types, and opaque identity (`test/test_leaves.jl:99-228`).
- Mixed cells maintain one cursor per distinct leaf type and use the same first-appearance ordering in layout and generated gather/scatter (`src/leaves.jl:150-189`; `src/store.jl:42-67`). `test/test_leaves.jl:193-227` verifies exact offsets in both buffers, and `test/test_store.jl:52-76` exercises the integrated form.
- The activation walk and exact type-level embed relation preserve pinned leaves and reject field-name, tag, and mutability drift (`src/leaves.jl:207-287`; `test/test_leaves.jl:231-301`).
- State topology is enforced before layout: each `init_x` field is flat `Float64` or an `SArray` of it, while `init_s`/`init_m` require isbits or `Symbol` (`src/build.jl:57-79`). Generated wholesale state writes compare key sets by name and enforce field types (`src/leaves.jl:303-341`).
- `scatter_group!` compares field sets as sets and fetches returned fields by name, so order is semantically irrelevant (`src/store.jl:81-107`). Late-branch conformance and state/update cases are covered in `test/test_failures.jl:465-600`.
- Opaque immutable handles remain one cell value and share only the deliberately frozen bulk reference (`src/leaves.jl:11-15,234-238`; `test/test_store.jl:179-230`). This is distinct from SD-01's mutable outer object.
- `DiagnosticError` correctly distinguishes a single fail-fast kind from `Vector{Diagnostic}` collection, and `StepError` carries either a diagnostic species or raw exception (`src/diagnostics.jl:61-107,148-208`). The focused failure tests cover cursor frames, boundary zero, localized trials, nonfinite state, and late conformance (`test/test_failures.jl:116-600`).

### Ruled-out suspicions

- **Generated scatter accepting a wrong return shape:** the public group write checks both the name set and every field type before emitting stores (`src/store.jl:81-107`). The unconstrained scalar `scatter!` is an internal primitive called only after that generated check; no permitted call site exposed it as an author seam.
- **NamedTuple field order corrupting storage:** reconstruction handles the NamedTuple constructor separately (`src/leaves.jl:120-123,167-169`), while group scatter indexes the returned value by symbol (`src/store.jl:93-101`). Existing permutation tests and source agree.
- **Mixed-type cursor drift:** layout counts each leaf type using the same `leaf_types` order from which the generated builders derive their per-type bases (`src/build.jl:368-377`; `src/leaves.jl:158-188`). Focused exact-offset tests passed.
- **Opaque handle traversal into referenced bulk data:** `_opaque` stops both type and value walks at the outer immutable non-isbits value (`src/leaves.jl:15,25,37-39,70-75,234-238`). Tests verify reference identity (`test/test_leaves.jl:121-145,182-189`; `test/test_store.jl:182-230`).
- **Current auto-publication payload regression:** current `DeclaredNotProduced` includes `state_fields` (`src/diagnostics.jl:710-721`) and construction supplies it (`src/build.jl:763-771`). I did not carry forward the stale suspicion from the earlier revision.
- **D-241 status-vector allocation and snapshot allocation:** both are expressly allowed by current design. They were not classified as storage bugs, and no whole-frame zero-allocation claim is made here.

## Validation

- Focused suite command: `julia --project=test test/runtests.jl leaves store diagnostics failures`
  - `leaves`: 97/97
  - `store`: 57/57
  - `diagnostics`: 593/593
  - `failures`: 182/182
  - selected total: **929/929 passed**
- Probe: `julia --project=test docs/reports/20260915_audit/probes/storage_diagnostic_gaps.jl`
  - exit 0 on Julia 1.13.0;
  - reproduced enum rejection, raw missing-default `MethodError`, accepted dead stage, unframed `ArgumentError`, raw bundle `FieldError`, accepted mutable `BigInt`, and live-cell alias mutation through a custom mutable `Real`.
- Root full gate, run separately on the same frozen source revision: `Pkg.test()` **2478/2478 passed** in 5m37.9s; log `docs/reports/20260915_audit/validation/pkg-test-current.log`.

## Limitations

- This review did not modify source or tests and did not execute external tooling or consult excluded design/audit material.
- Appendix C placement/policy was checked deeply for the storage/build behaviors above and structurally across all 79 types. It was not a second full behavioral audit of every periphery/service feature that owns a present kind.
- The focused suite passing does not weaken SD-01–SD-06: each is either directly reproduced or follows from an exact normative inventory/payload comparison the present tests do not perform.

## Optional improvements

These are lower-priority maintainability improvements, separate from conformance findings:

1. Replace comments that call the runtime stream's implemented subset “the nine kinds” with wording that cannot be mistaken for Appendix C completeness (`src/diagnostics.jl:16-17`, `src/dataplane.jl:134-137`).
2. Add a property-style round-trip test over a small generated family of nested immutable structs/static arrays and mixed leaf orders. The current hand-picked shapes are good, but a generator would cheaply guard the two recursive expression builders against future asymmetric edits.
3. Add an explicit test asserting every diagnostic payload field required by the independent Appendix inventory, not only that `message(d)` returns a nonempty string (`test/test_diagnostics.jl:515-525`).

## Primary-review final reconciliation and curation

Final target: `6986ad41b5f04c671fc6b321b4bab6df54520a40`. The primary reviewer
read the intervening allowed delta and reran the probe. `PathResolution` now
carries the declared field type for generic traversal and supplies located
candidate lists to conditions/readers. Its SD-06 row is closed; the table had
twelve historical entries (the first draft's count of eleven was incorrect),
of which eleven remain. The eight missing kinds and 79-row inventory are
unchanged. Inventory presence alone remains no verdict on trigger or policy.

SD-01 is strengthened by the final probe: mutation through a retained snapshot's
port changes both the snapshot and the live cell. The source explicitly treats
mutable `BigFloat` as a numeric leaf, but the allowed design documents contain
no exception admitting all mutable `Real` values. Final output is in
[storage_diagnostic_gaps-final.log](../validation/storage_diagnostic_gaps-final.log).
The earlier `storage-diagnostic-gaps.log` was overwritten by a blocked launcher
retry; it is retained as environment-failure evidence, not a successful run.
The focused-suite figures above are the subsystem reviewer's recorded results;
the primary review's full-suite logs and final probe are the durable validation.

Curation separates severity from test count: SD-02/03 are bounded medium
validation/vocabulary gaps; SD-05 is a test-design weakness, not a separate
high-severity product bug. SD-06's low-priority schema details overlap the
cycle/framing/shadowing findings, which keep their curated priorities. The final
report deduplicates those overlaps rather than adding them as independent bugs.
