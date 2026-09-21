# Design-refresh audit — 2026-09-17

**Scope.** This refresh reconciles the five entries under “Documentation conflicts and open design choices” in `report.md`, G-10/G-11, and the Appendix C kind count. It is anchored to committed `HEAD` `66c49f09b4cfc3ddb0b62523e979cd0537ba7c8c`, with `6986ad4` as the audit baseline. `src/assembly.jl`, `src/build.jl`, and `src/diagnostics.jl` have uncommitted edits during this review. Those edits, and the concurrently dirty tests and `implementation.md`, are not evidence of a committed retirement.

## Disposition of the five report entries

| Report entry | Current disposition | Evidence and required curation |
|---|---|---|
| Allocation scope | **Pre-existing stale-prose correction; implementation conformed at baseline.** | D-241, already ratified at the audit baseline, accepts one status-vector allocation per publication and says the zero-allocation sentence extended §7.5 beyond its scope ([`decisions.md:8704-8735`](../../../design/decisions.md#L8704)). §7.5 still calls logging amortized-zero and says the snapshot cost is zero ([`spec.md:1692-1702`](../../../design/spec.md#L1692)); §11.8 says the status is a per-publication vector. Retain this documentation correction, not an implementation defect or new ruling. |
| Heartbeat capture | **Low pre-existing stale-prose correction; implementation conformed at baseline.** | D-240, already ratified at the audit baseline, selects acquire-load at publication, not drain ([`decisions.md:8680-8702`](../../../design/decisions.md#L8680)). §11.8 says exactly that ([`spec.md:6252-6268`](../../../design/spec.md#L6252)), but §11.2 literally says that liveness timestamps are taken “at frame top” ([`spec.md:5039-5045`](../../../design/spec.md#L5039)). Retain it as a low documentation correction; no new ruling is needed. |
| Contract-arity taxonomy | **Design conflict retired by D-249; implementation was incomplete at the original anchor.** | §8.2 now directs contradictory contract arity to `TierSignatureMismatch` ([`spec.md:2308-2326`](../../../design/spec.md#L2308)), and D-249 gives that kind all three signature arms ([`decisions.md:9093-9136`](../../../design/decisions.md#L9093)). At original `66c49f0`, every disagreeing vote, including contract arity, still reached `DeclarationOnWrongTier`. The appendendum records the subsequent committed closure. |
| Auto-publication precedence | **Open design/code conformance choice.** | §§5.3 and 8.3 say a matching store field is auto-published when no stage produces it ([`spec.md:778-783`](../../../design/spec.md#L778), [`spec.md:2379-2392`](../../../design/spec.md#L2379)); §9.1 classifies before the stage-2 graph/probe ([`spec.md:3053-3068`](../../../design/spec.md#L3053)). Committed code chooses stage-1 precedence: it derives publication after stage 1 (`git show HEAD:src/build.jl:361-376`), then rejects an overlapping stage-2 product (`git show HEAD:src/build.jl:1068-1077`). No decision establishes that choice. Preserve the report’s request for an explicit rule or matching implementation. |
| Join-timeout survivor disposition | **Open high-severity design and implementation concern.** | D-198 only makes the cap a deployment keyword ([`decisions.md:6890-6927`](../../../design/decisions.md#L6890)). The shutdown text still promises an empty task set and released resources after the timeout ([`spec.md:6645-6651`](../../../design/spec.md#L6645)), while committed `_tail!` merely stops waiting and emits `DeviceJoinTimeout`; it cannot terminate an unfinished arbitrary task (`git show HEAD:src/devices.jl:479-491`). The calling-task exception is explicitly acknowledged ([`spec.md:6633-6643`](../../../design/spec.md#L6633)). A ruling must specify authority over survivors, resource ownership/cleanup, and next-run eligibility. |

## G-10: build and schedule inspection

**Still open.** `pending.md` continues to record D-187 grid diagnostics and the missing named renderings: Build/schedule view, anchor table including `A₀`, rate-scope rows, hyperperiod chart, and derivation line ([`pending.md:40-45`](../../../design/pending.md#L40)). `GridUtilization` is normative in Appendix C ([`spec.md:11047-11051`](../../../design/spec.md#L11047)) and has no committed definition or producer. This is a specified missing capability, not a request for an arbitrary universal `show` method. Ordinary printing of internal values therefore does not close G-10.

## G-11: committed payload map

The table separates a ruled payload from code which merely has an uncommitted patch in the present worktree.

| Payload subject | Committed HEAD disposition |
|---|---|
| `FaceNameCollision` origins | **Retired by D-249.** The normative payload is assembly path, colliding names, and site; no per-entry provenance ([`decisions.md:9101-9129`](../../../design/decisions.md#L9101)). `src/diagnostics.jl` supplies those fields. |
| `ConformanceFailure` duplicate time | **Retired by D-249.** Runtime time/index belong to the outer `StepError` carrier ([`decisions.md:9097-9122`](../../../design/decisions.md#L9097)); `StepError` carries `t` and boundary. Handler event identity remains a separate pending payload gap. |
| `ReadBindingUnresolved` candidates | **Partly retired by committed codefix.** Unknown output cells, root inputs, and root output faces now receive candidates from the resolver (`git show HEAD:src/bindings.jl:172-199`). Its payload still names the binding type where Appendix C requires the device type, as `pending.md` records ([`pending.md:32-38`](../../../design/pending.md#L32)). |
| `PathResolution.declared` | **Retired by committed codefix.** The committed payload includes `declared` (`git show HEAD:src/diagnostics.jl:366-377`). |
| `ContainerMixed` positions; `UnconnectedInput` declared type/obligation level; `ClassUnreadable`/`TierUnreadable` type and declarations-found; `ProducedByTwoStages` producer stage names; `TransparentContainerUnknown` container fields; `TwoProducers` terminals | **Open at committed HEAD.** The current sites omit these fields: e.g. `ContainerMixed` only passes types, `UnconnectedInput` only path/face, and `TwoProducers` only provenance strings (`git show HEAD:src/assembly.jl:130-135,798-803,948-953`). The dirty patches add several of them, but this review does not count them. |
| `TierSignatureMismatch` arity arms | **Open at committed HEAD.** This is the implementation consequence of D-249 above, not an unresolved taxonomy. |
| `StopFaceInvalid` site; `ConformanceFailure` handler event; `AttachUnknownFace` device type; `ServiceLifecycle.legal`; `EventHalfMissing.found` and `AbstractAtRoot.declared` type spelling | **Open.** These remain explicitly listed in `pending.md` ([`pending.md:21-39`](../../../design/pending.md#L21)); no committed closure was found in this bounded refresh. |

## Appendix C inventory correction

The current Appendix C contains **82 named rows**, not the 79 stated in `report.md`. At committed HEAD, 77 rows have a `Diagnostic` subtype and the separate `StepError` carrier implements the remaining carrier row. The only four normative names with no committed implementation are:

- `DebtReanchor`
- `GridUtilization`
- `ThreadBudget`
- `UnboundedRun`

The data-plane comment independently names the three runtime pacing omissions ([`src/dataplane.jl:30-42`](../../../../src/dataplane.jl#L30)); Appendix C names `GridUtilization` separately. Conversely, the report’s earlier absent kinds `DeadStage`, `MissingProbeValue`, `BundleFieldError`, and `UserCodeFraming` are committed codefix retirements: their definitions and producers are present in `src/diagnostics.jl` and `src/build.jl`. The report’s “eight kinds absent” line should be replaced with this four-kind inventory and should count `StepError` as a carrier rather than misclassifying it as missing.

## Initial curation summary

Retain allocation and heartbeat as pre-existing prose corrections; neither needs a new ruling. D-249 retires the arity ambiguity, which was a committed implementation gap at the original anchor. Keep auto-publication and join-timeout survival open. The following appendendum supersedes the original-anchor G-11 payload map.

## Appendendum — committed payload reconciliation at `7b1c1e8`

**Scope.** This bounded follow-up reviews the committed delta
`66c49f09b4cfc3ddb0b62523e979cd0537ba7c8c..7b1c1e850515dad77942973e9ae87ebcc2ac7a6c`.
Source is clean at the latter revision; unrelated audit-document worktree edits
are not evidence here. Commits `40f97f4`, `f386029`, `c44e6f3`, and `4a04f5e`
move the payload work from provisional changes to committed implementation and
tests.

### G-11 and D-249 disposition

**G-11 is now narrower but remains open.** `pending.md` removes the former
payload-shortfall bullet, and the following former residuals now have both a
committed producer and direct field assertions:

| Former residual | Committed closure |
|---|---|
| Structure payloads | `ClassUnreadable` now carries type, found declarations, and both family lists; `ContainerMixed` carries element keys and fully spelled types; `TransparentContainerUnknown` carries container-field candidates; `UnconnectedInput` carries declared type and last obligation level; `TwoProducers` carries both terminals. See [`src/assembly.jl:65-69`](../../../../src/assembly.jl#L65), [`src/assembly.jl:156-160`](../../../../src/assembly.jl#L156), [`src/assembly.jl:206-211`](../../../../src/assembly.jl#L206), [`src/assembly.jl:824-856`](../../../../src/assembly.jl#L824), and [`src/assembly.jl:990-1000`](../../../../src/assembly.jl#L990). Tests exercise names and indices, ancestor obligation level, candidates, and both terminals ([`test/test_assembly.jl:165-180`](../../../../test/test_assembly.jl#L165), [`test/test_assembly.jl:617-664`](../../../../test/test_assembly.jl#L617)). |
| Tier and stage payloads | `TierUnreadable` has type, family, and declarations; `ProducedByTwoStages` has the stage-1 producer; `EventHalfMissing.found` is a type spelling. D-249's arity arm is now emitted as `TierSignatureMismatch(reason = :arity, found, mandated)`, while the bound arm supplies explicit `mandated = Real`. See [`src/build.jl:229-237`](../../../../src/build.jl#L229), [`src/build.jl:742-753`](../../../../src/build.jl#L742), [`src/build.jl:794-800`](../../../../src/build.jl#L794), and [`src/build.jl:1089-1100`](../../../../src/build.jl#L1089). The arity matrix is asserted in [`test/test_build.jl:1214-1228`](../../../../test/test_build.jl#L1214). |
| Runtime and service payloads | Handler conformance failures now receive their event at both build and execution write sites; `StopFaceInvalid` carries `:constructor`, `:run!`, or `:replay!`; `ServiceLifecycle.legal` is populated per refusal. See [`src/build.jl:1107-1127`](../../../../src/build.jl#L1107), [`src/executor.jl:369-402`](../../../../src/executor.jl#L369), [`src/sim.jl:220-241`](../../../../src/sim.jl#L220), and [`src/diagnostics.jl:1093-1140`](../../../../src/diagnostics.jl#L1093). Constructor/run/replay sites and legality vectors are asserted in [`test/test_lifecycle.jl:154-171`](../../../../test/test_lifecycle.jl#L154) and [`test/test_diagnostics.jl:390-397`](../../../../test/test_diagnostics.jl#L390). |
| Admission and read payloads | Every `ReadBindingUnresolved` construction now carries device type as well as binding type; candidate lists remain supplied for name-shaped reads. `AttachUnknownFace` likewise closes the missing device-type column. See [`src/bindings.jl:164-200`](../../../../src/bindings.jl#L164) and [`test/test_bindings.jl:192-205`](../../../../test/test_bindings.jl#L192). The distinct attachment-entry residual is recorded below. |
| Type spelling | `AbstractAtRoot.declared` is deliberately rendered whole, preserving parameters, and `EventHalfMissing.found` is now a string. The kind-set fixtures and rendering test cover both ([`src/diagnostics.jl:345-360`](../../../../src/diagnostics.jl#L345), [`src/diagnostics.jl:435-448`](../../../../src/diagnostics.jl#L435), [`test/test_diagnostics.jl:266-280`](../../../../test/test_diagnostics.jl#L266), [`test/test_diagnostics.jl:638-641`](../../../../test/test_diagnostics.jl#L638)). |

### Remaining G-11 payloads

Two original G-11 contexts remain absent from the committed payload schema:

| Residual | Evidence and disposition |
|---|---|
| `AttachUnknownFace` binding entry | Appendix C requires the **binding entry** as well as device type, face and candidates ([`spec.md:10984-10986`](../../../design/spec.md#L10984)). The current type carries `device`, `binding`, `face`, and `candidates`, but no entry/provenance field ([`src/diagnostics.jl:1221-1230`](../../../../src/diagnostics.jl#L1221)); `_claim` reports only the enumerated face ([`src/roster.jl:204-211`](../../../../src/roster.jl#L204)). The new test checks the device/binding/face, not a binding-entry context ([`test/test_roster.jl:64-66`](../../../../test/test_roster.jl#L64)). **Open payload gap.** |
| `ReplayHeaderMismatch` build/trace provenance | Appendix C requires the build's and trace's provenance in addition to the discriminated mismatch ([`spec.md:11052-11059`](../../../design/spec.md#L11052)). The committed diagnostic has only `what`, `path`, `name`, `expected`, and `found` ([`src/diagnostics.jl:1737-1744`](../../../../src/diagnostics.jl#L1737)); header construction passes only those values ([`src/trace.jl:324-345`](../../../../src/trace.jl#L324)). The kind-set cases likewise contain no provenance ([`test/test_diagnostics.jl:523-531`](../../../../test/test_diagnostics.jl#L523)). **Open payload gap.** |

`StoreWithoutUpdate` is not a residual payload row. The prior shadowed-method
case is superseded by the earlier `DeclarationShadowed` gate (D-246), and a
missing update is derivable directly from the store declaration; its committed
payload remains the path and store ([`src/build.jl:202-207`](../../../../src/build.jl#L202),
[`src/diagnostics.jl:425-433`](../../../../src/diagnostics.jl#L425)).

The D-249 closure is complete in committed code: the specification's single
contract-signature kind, event-bearing handler failures, and its ruled
runtime-time/face-provenance columns agree with the implementation. The
remaining Appendix C feature omissions—`DebtReanchor`, `GridUtilization`,
`ThreadBudget`, and `UnboundedRun`—are separate from these two G-11 payload
residuals. G-10 remains open for the inspection capability.


## Appendendum — pipeline-redesign documentation delta at `2938a0`

**Scope.** This is a documentation-only reconciliation of
`7b1c1e8..2938a0`, anchored at
`2938a025c05bc136dd9f76f64cb42f89f4986d4c`. D-250 through D-258 are
ratified design decisions. Except for D-252's auto-publication removal,
`pending.md` explicitly records the redesign as unbuilt
([`pending.md:21-39`](../../../design/pending.md#L21)). This addendum therefore
does not treat newly specified artifacts or APIs as completed capabilities.

### Existing documentation items

| Existing item | Current curation |
|---|---|
| 1. Allocation prose | **Retain as a stale-prose correction.** D-252 changes the way state is exposed, not the per-boundary snapshot/status allocation question. D-241 remains the settled behavior; no new redesign ruling or implementation conclusion follows. |
| 2. Heartbeat prose | **Retain as a low stale-prose correction.** D-250 changes warning ownership, not the D-240 publication-time heartbeat rule. §11.2's “frame top” sentence remains inconsistent with §11.8. |
| 3. Contract arity | **Still retired.** D-249 is unaffected by the redesign. |
| 4. Auto-publication precedence | **Retire.** D-252 removes auto-publication: every declared port is returned by stage 1 or stage 2, and an unproduced one is `DeclaredNotProduced` ([`decisions.md:9264-9307`](../../../design/decisions.md#L9264)). The old precedence question and its stage-2 collision interpretation no longer describe the design. |
| 5. Join-timeout survivors | **Keep open.** D-255 moves run state and stop policy to `Run`/`StopPolicy`, while D-256 moves `join_timeout` to `Control`; neither decision gives authority over an unfinished arbitrary device task. The no-survivor promise and calling-task asymmetry remain in §12.4 ([`spec.md:6784-6802`](../../../design/spec.md#L6784)). |

### Existing capability findings

| Finding | Redesign impact |
|---|---|
| G-01 pacing/control | **Keep open, with a redesign-pending caveat.** D-255 now specifies `Run`, per-advance `StopPolicy`, and `UnboundedRun` ([`decisions.md:9405-9494`](../../../design/decisions.md#L9405)); D-256 relocates their owners ([`decisions.md:9497-9540`](../../../design/decisions.md#L9497)). Pause, pacing, `DebtReanchor`, `ThreadBudget`, and `UnboundedRun` remain unbuilt per `pending.md`. Remove legacy claims about constructor-owned `t_end`/`stop_on`; do not claim the new run/control design is implemented. |
| G-02 linearization | **Keep open.** The settled `linearize` service remains listed as unbuilt ([`pending.md:48-51`](../../../design/pending.md#L48)). D-253 says its structural consumers will read `Structure`/`Dataflow`, which is an implementation dependency, not a delivery. |
| G-03 mounting | **Keep open.** `at(prefix, problem)` remains an unbuilt §14 item. The new artifacts do not supply relocation. |
| G-10 inspection views | **Keep open, with a precise replacement target.** D-253/D-254 replace the old implied internal-data view with `Structure`, `Dataflow`, `Deployment`, and `Schedule` artifacts ([`decisions.md:9310-9369`](../../../design/decisions.md#L9310), [`decisions.md:9372-9402`](../../../design/decisions.md#L9372)). D-257 now requires their `show` renderings, anchor/`A₀` and rate-scope tables, and a binary 100-tick hyperperiod guard ([`decisions.md:9543-9573`](../../../design/decisions.md#L9543)). `GridUtilization` belongs on deployment warnings. Replace the report's vague “internal dictionaries and rows” evidence with this target, and retain the finding because the whole artifact/rendering theme is pending. |
| G-11 payloads | **Keep the two residuals, but remove the old producer-stage payload claim.** D-252 makes `ProducedByTwoStages` carry only path and port; the stages are intrinsic and no producer column is normative ([`spec.md:11182-11184`](../../../design/spec.md#L11182)). The earlier appendendum's historical `producers` closure is therefore superseded, not an open gap. `AttachUnknownFace` binding-entry and `ReplayHeaderMismatch` build/trace provenance remain the outstanding payload checks. |
| G-13 GUI semantics | **Keep open.** D-255 specifies the run-scoped `gui` behavior and says a GUI is an ordinary rostered device ([`spec.md:10887-10908`](../../../design/spec.md#L10887)); `pending.md` still lists the §11.7 GUI write path as unbuilt. The §16 calling convention remains deferred, so this does not finalize a GUI authoring API. |

### Deferred work and improvements

The standard component library and §16 migration deferrals remain unchanged. The
same-simulation-concurrency note remains a hardening proposal: D-250's
artifact criterion does not define concurrent lifecycle admission. The
trace-growth improvement should refer to D-255's intended append-only
`Run.trace` split into header, schemas, and batches, while remaining an
observability proposal rather than a claim that the new trace model ships.
The suggested semantic-boundary matrix and executable diagnostic inventory
remain useful; they should add artifact-warning ownership, per-advance policy,
and the new renderer guard once the redesign increments land.

### Missing-kind inventory

Appendix C now has **83 named rows**. At `2938a0`, direct type inventory finds
77 `Diagnostic` subtypes plus the separate `StepError` carrier. The normative
names without a committed type are now:

- `DebtReanchor`
- `EmptyFaceSelection`
- `GridUtilization`
- `ThreadBudget`
- `UnboundedRun`

`EmptyFaceSelection` is the new D-251 build warning
([`spec.md:11143-11147`](../../../design/spec.md#L11143)); the other four
were already outstanding. This is an inventory correction, not evidence that
the other D-250–D-258 artifact requirements are implemented.
