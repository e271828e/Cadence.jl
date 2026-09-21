# Services refresh: F-10, F-11, F-12, G-02, G-03, and admission concurrency

**Revision evaluated:** `66c49f09b4cfc3ddb0b62523e979cd0537ba7c8c`  
**Comparison baseline:** `6986ad4`  
**Date:** 2026-09-17

## Scope and method

This is a bounded refresh of six entries in the current audit report. I read the current implementations in `src/readers.jl`, `src/conditions.jl`, `src/trim.jl`, `src/sim.jl`, and `src/devices.jl`; the changed service tests; the relevant current specification and decisions; and the now-authorized `docs/design/pending.md`. The five service source files and their targeted tests matched `HEAD` when inspected. Concurrent, pre-existing edits in other files were not used for these conclusions.

I reran the current-audit probe directly:

```text
relocate TrimProblem: DiagnosticError{Cadence.ConditionNodeMisuse} carried=Cadence.ConditionNodeMisuse
relocate Reads: DiagnosticError{Cadence.ConditionNodeMisuse} carried=Cadence.ConditionNodeMisuse
out-of-range compiled read: BoundsError carried=none
non-callable trim condition: MethodError carried=none
interrupt during condition conversion: DiagnosticError{Vector{Cadence.Diagnostic}} carried=Vector{Cadence.Diagnostic}
linearize defined: false
```

Command: `julia --project=test docs/reports/20260915_audit/probes/services_confirmed_gaps.jl`. It exited zero on the current checkout. I did not run the full suite; the root audit owns that gate.

## Status summary

| Item | Status at `66c49f0` | Conclusion |
|---|---|---|
| F-10, statically invalid selector indices | **Open** | The constructor rejects non-integers and resolution rejects indexing a scalar, but a schema-known out-of-range `SVector` index still compiles and later throws raw `BoundsError`. |
| F-11, non-callable trim fields | **Open** | Setup still does not validate applicability of `condition` or `residuals`; `condition = 42` still leaks `MethodError`. The spec still needs an explicit diagnostic arm for this malformed case. |
| F-12, interrupt swallowed by condition conversion | **Open** | `_convert` still catches every exception; `InterruptException` becomes collected `ConditionResolution(:unconvertible)`. |
| G-02, linearization | **Open** | No `linearize` entry point or tap-set implementation exists. |
| G-03, service relocation | **Open** | `at` still accepts only `ConditionNode`; `TrimProblem` and `Reads` both reach `ConditionNodeMisuse`. |
| Same-simulation service admission concurrency | **Open improvement** | Atomic lifecycle reads provide visibility and ordinary mid-run refusal, but admission remains check-then-act with no reservation, lock, or compare-and-swap. The spec does not state support for simultaneous lifecycle-mutating calls, so this remains hardening/design scope rather than a reproduced supported-use defect. |

No item in this refresh is retired. The current changes improve adjacent build diagnostics and interrupt framing, but they do not alter these service seams.

## F-10 — Open: statically invalid read indices still survive resolution

### Current requirement

The read-selector family includes an optional component index (`docs/design/spec.md:8396-8401`), and the linearization design says the index turns vector leaves into named scalars and the selector lists are validated at resolution (`:9167-9196`). `TapResolution` carries the optional index as part of its normative payload (`:11028-11033`).

### Current implementation

- `_index_arg` accepts every integer, including zero, negative, and oversized values, and rejects only non-integers (`src/readers.jl:82-85`).
- `_check_index` rejects an index only when the declared value type is a scalar `Real`; for every non-`Real` type it returns `true` without using the actual index or a statically known axis (`src/readers.jl:283-291`).
- The resolved entry retains the index (`src/readers.jl:300-342`), and execution applies it as an unchecked `v[i]` (`:163-176`).

The current probe compiles `get_state("", :q, 3)` against `SVector{2}` and `gather` throws raw `BoundsError`. This is the same mechanism as the original finding.

### Test evidence

Current tests cover a valid `SVector` index (`test/test_readers.jl:45-61`) and an index on a scalar (`:97-107`). They do not cover zero, negative, or out-of-range indices on a statically sized value. The changes since `6986ad4` adjust reader terminology and adjacent diagnostics but do not change `_check_index` or add range coverage.

### Assessment

The finding remains **open**. There is partial validation infrastructure, but the reported defect was specifically the missing schema-known range check and late unstructured failure. For `StaticArray` and other statically sized/indexable declarations, resolution has enough information to refuse the selector as `TapResolution`. Policy for types whose axes cannot be read statically remains a design detail; it does not block the fixed-size case.

## F-11 — Open: plainly non-callable trim fields still bypass setup validation

### Current requirement and design nuance

`TrimProblem.condition` is specified as a condition-valued function, and `residuals` as a residual function (`docs/design/spec.md:8637-8651`; D-118 at `docs/design/decisions.md:3404-3424`). The service describes malformed problems as collected `TrimProblemInvalid` setup failures, but the current enumerated malformed-case paragraph lists shape/type/key/read errors without explicitly naming non-callability (`docs/design/spec.md:9026-9035`). The original report correctly identified both an implementation gap and this specification-list omission.

### Current implementation

- `TrimProblem` stores unconstrained field types (`src/trim.jl:49-60`), which is appropriate for an inert author value.
- Setup validates decision/bound shapes, tolerance shape and values, and the read set (`src/trim.jl:245-313`). It does not test whether `condition` is applicable to the actual guess shape or whether `residuals` is applicable to the resolved read/decision shapes.
- After the collected barrier, `trim!` invokes `problem.condition(guess)` and later `problem.residuals(...)` directly (`src/trim.jl:384-410`).
- `TrimProblemInvalid.reason` has no callability/applicability arm (`src/diagnostics.jl:1485-1536`).

The current probe's `condition = 42` still passes setup and raises raw `MethodError` at the direct call.

### Test evidence

The malformed-problem tests cover decision/bound keys and types, unresolved reads, residual return keys, read-set shape, inverted bounds, and invalid tolerances (`test/test_trim.jl:229-304`). They do not supply a non-callable or wrong-signature `condition`/`residuals` field. The test that a non-`TrimProblem` argument gets `ArgumentInvalid` (`:511-516`) is a different boundary.

### Assessment

The finding remains **open**. A complete resolution should validate applicability against the actual argument shapes available at setup, while preserving the distinction between “not callable with this contract” and an applicable user function that throws from its body. The spec's malformed-case enumeration and `TrimProblemInvalid` reason vocabulary should be extended together with the implementation.

## F-12 — Open: condition conversion still converts an interrupt into a data diagnostic

### Current requirement

An `InterruptException` is control flow, not model/data failure (`docs/design/spec.md:7684-7692`). For long-running trim, D-132 states that an interrupt unwinds the call over per-invocation scratch stores with no commit (`docs/design/decisions.md:3881-3890`). The newer build framing decision also explicitly passes `InterruptException` through unwrapped, but that decision governs build invocation frames, not condition conversion (D-248, `docs/design/decisions.md:9033-9052`).

### Current implementation

`_convert` catches without binding or discriminating the exception (`src/conditions.jl:402-407`). Its caller treats the `false` result as an ordinary collected `ConditionResolution(reason = :unconvertible)` (`src/conditions.jl:336-363`). A conversion method that throws `InterruptException` is therefore indistinguishable from an ordinary failed conversion.

The current probe confirms the result is `DiagnosticError{Vector{Diagnostic}}`, not raw `InterruptException`.

### Test evidence

The condition tests exercise an ordinary unconvertible string and assert collected `ConditionResolution` behavior (`test/test_conditions.jl:150-170`). Runtime/build interrupt tests cover other hosts, but no test covers interrupt propagation through `_convert`.

### Assessment

The finding remains **open**. The narrow repair is to rethrow `InterruptException` before converting other conversion failures to `(false, nothing)`. This keeps the existing collected-data behavior while preserving the control-flow exception.

## G-02 — Open: linearization remains absent

### Current requirement

§14.10 specifies the tap declaration, relocation, seeded scratch evaluation, and labeled result (`docs/design/spec.md:9167-9235` and following). Lifecycle preconditions explicitly include both defaulted and explicit-about `linearize` calls (`:8115-8123`), and D-197 constrains the `x` tap set to continuous state (`docs/design/decisions.md:6858-6869`).

### Current implementation and tests

There is no `linearize` binding in `Cadence`; the current probe prints `linearize defined: false`. The codebase has reusable pieces—the `Reads`/`Reader` machinery and trim scratch activations—but no tap-set type, seed/write pass, matrix assembly, labeled return, or service entry point. The permitted tests contain no linearization test file or entry-point exercise.

`docs/design/pending.md:55-58` independently records `linearize`, its tap register, and the nominal-activation loop as not built. That register supports the source finding but is not its basis.

### Assessment

G-02 remains **open** in full. Current reader and scratch machinery reduce implementation cost but do not constitute a partial user-visible capability.

## G-03 — Open: `TrimProblem` and read/tap relocation remain absent

### Current requirement

§14.9 gives the concrete `at(prefix, p::TrimProblem)` lift, including post-composed condition and relocated reads (`docs/design/spec.md:9081-9119`; D-071 at `docs/design/decisions.md:1940-1958`; D-188 at `:6542-6550`). §14.10 requires whole tap-set relocation (`docs/design/spec.md:9186-9196`).

### Current implementation

`at` has exactly one accepting method, for `ConditionNode`, and routes every other value to `ConditionNodeMisuse` (`src/conditions.jl:85-93`). `Reads` is a separate wrapper around a selector NamedTuple (`src/readers.jl:105-134`) and has no scoped/relocated representation. `TrimProblem` likewise has no `at` method (`src/trim.jl:49-60`).

The current probe confirms both `at("mount", empty_problem)` and `at("mount", reads(...))` raise `DiagnosticError{ConditionNodeMisuse}`.

### Test evidence

The reader test explicitly states “No mounting exists” and tests paths authored from the root (`test/test_readers.jl:117-125`). Condition-node scoping itself is well tested, but that is the already-built inner algebra, not whole-problem/read relocation. `docs/design/pending.md:55-58` records mounting as unbuilt.

### Assessment

G-03 remains **open**. The condition half alone cannot make a problem relocatable because its read selectors would still resolve from the old root. Completing it requires a scoped read/tap representation plus the field-by-field `TrimProblem` lift.

## Same-simulation service concurrency — open improvement, scope still unspecified

### What is implemented

Lifecycle is an atomic field and readers see it with atomic loads (`src/sim.jl:254-265`). Once one call has stored `:running`, later `init!`, `run!`, `step!`, `trim!`, `capture`, attach, and detach calls take their ordinary refusals. Current tests deliberately start a run, wait until the lifecycle is visibly `:running`, and then test those refusals (`test/test_lifecycle.jl:65-89`; `test/test_trim.jl:518-530`). That behavior is sound for sequential admission followed by concurrent observation.

### Remaining race window

Admission is still check-then-act:

- `step!` atomically reads `:initialized` in `_assert_advanceable`, validates arguments, and only later stores `:running` (`src/sim.jl:318-329,1208-1228`).
- `run!` reaches the same gate before `_run_body!` stores `:running` (`src/sim.jl:949-968`).
- `init!`, `replay!`, `trim!`, and `capture` read lifecycle, then perform work without owning a reservation (`src/sim.jl:642-657,756-762`; `src/trim.jl:384-404`; `src/conditions.jl:830-837`).
- attach/detach similarly check lifecycle and then mutate the roster (`src/devices.jl:125-142`; `src/sim.jl:1310-1343,1360-1369`).

Two simultaneous calls can therefore both pass the old state before either establishes exclusive ownership. Atomic visibility alone does not make the compound admission transition atomic. No current test synchronizes two calls before that transition; existing concurrent tests wait for `:running`, expressly avoiding the admission race.

### Contract classification

The spec says every service requires a non-running simulation because the loop owns stores during a run (`docs/design/spec.md:8105-8111`), but it does not state that two lifecycle-mutating services on the same simulation are supported concurrently or define a loser/error policy. The design explicitly promises concurrent activation materialization for multiple `Simulation`s, a different scope.

The audit item therefore remains an **open improvement**, not a confirmed supported-use defect. If same-simulation concurrent entry should be supported safely, admission needs one owner transition covering check plus reservation (for example, a service mutex or an atomic state/reservation protocol) and tests that synchronize contenders before admission. If it is outside the supported contract, the spec should say calls that mutate lifecycle/configuration must be externally serialized.

## Final classification

All five report findings remain actionable and open at `66c49f0`. The concurrency item also remains open as a design/hardening improvement. The most localized fixes are F-10's fixed-size range validation and F-12's interrupt pass-through. F-11 needs a paired spec/diagnostic decision about applicability failures. G-02 and G-03 remain feature work already acknowledged in the current pending register.
