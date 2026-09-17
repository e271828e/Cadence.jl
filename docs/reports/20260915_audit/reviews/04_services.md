# Conditions, readers, trim, and stopped-simulation services audit

Audit baseline: `865521a0f7be6894b1688925bb349dcbadd06539`  
Service-source reconciliation: `src/conditions.jl`, `src/readers.jl`, `src/trim.jl`, and their three focused test files have no diff through `f941c504c90eadbad9950a182feafa96b300a642`.  
Corpus restriction: `src/**`, `test/**`, and `docs/design/{implementation,spec,decisions}.md` only. No other design or report file informed this review.

## Inspected scope and specification coverage

The primary review covered all of `src/conditions.jl`, `src/readers.jl`, and `src/trim.jl`; all of `test/test_conditions.jl`, `test/test_readers.jl`, and `test/test_trim.jl`; the associated component and condition declarations in `test/fixtures.jl`; and the `init!`, boundary-zero, lifecycle, and trim-commit glue in `src/sim.jl`. Supporting reads followed activation compilation and executor/store access only where the services call them.

| Area | Normative coverage | Result |
| --- | --- | --- |
| Condition values and capture | §14.1 | Sparse overlays, declared-default reset, store/root-input capture, lifecycle |
| Composition | §14.2 | inert trees, scoping, collision handling, provenance, misuse methods |
| Resolution | §14.3 | flattening, schema lookup, conversion, collection, compiled destinations |
| Apply/read registers | §14.4, §9.5 | dynamic and specialized writes, shape checks, activation identity, five selectors, compiled gather |
| Boundary zero | §14.5 | establishment, projection/events/ticks, commit behavior through `init!` |
| Root-input totality | §14.6 | pre-write coverage, `override`, probe-value exclusion |
| Trim problem | §14.7 | decision/bound/tolerance names and types, read compilation, residual canonicalization |
| Trim service | §14.8, §9.6 | scratch ownership, frozen-cell establishment, AD evaluation, backend seam, box behavior, verdict, commit/report |
| Relocation | §14.9 | `at(prefix, TrimProblem)` and scoped reads |
| Linearization | §14.10 | taps, seeding/freeze rules, pure-query and returned-data requirements |

Pertinent decisions checked include D-063–D-072, D-098, D-108, D-110, D-118, D-124–D-126, D-148–D-151, D-156, D-158–D-159, D-197, D-204–D-205, D-207, D-213, D-223–D-224, and D-235.

Severity means: **high** is a missing required service or relocation semantic; **medium** allows malformed service input to escape the structured/pre-write discipline or moves a failure to execution; **low** preserves correctness but omits required diagnostic help.

## Confirmed gaps and deviations

### 1. `TrimProblem` and read sets cannot be relocated with `at`

**Severity: high.** Section 14.9 requires `at(prefix, p::TrimProblem)` to pass through path-free fields, wrap `p.condition(d)`, and scope `p.reads` (`spec.md:9015-9028`). Resolution must then prefix path selectors and resolve input faces outward from the mount point (`spec.md:9030-9040`). D-071 records the same five-line lift (`decisions.md:1930-1944`).

The only `at` implementation accepts `ConditionNode`; every other value is routed to `ConditionNodeMisuse` (`src/conditions.jl:71-79`). Neither `src/readers.jl` nor `src/trim.jl` adds an overload for `Reads` or `TrimProblem`. Consequently a problem that works at its authored root cannot be mounted as a child, defeating the specified component-local reuse boundary.

The probe invokes both required halves (`probes/services_confirmed_gaps.jl:24-28`) and observes `DiagnosticError{ConditionNodeMisuse}` for each. No relocation test exists in the three focused service test files; `test/test_trim.jl:442-451` verifies only that an already root-authored commit is equivalent to `init!`.

### 2. The required continuous linearization service is absent

**Severity: high.** Section 14.10 specifies the main continuous linearization surface: three tap lists, validated/relocatable selectors, per-invocation scratch, chunked `Dual` seeding, simultaneous `A/B/C/D` and operating-point vectors, pure-query behavior, and labeled output (`spec.md:9088-9189`). D-072 ratifies that surface (`decisions.md:1965-1987`). The later sampled-data step-map extension alone is explicitly “recorded, not built” (`spec.md:9199-9204`); that qualification does not defer the continuous service.

There is no `linearize`, taps value, linearization result, or subsystem/delete-vars implementation under `src/**`, and no linearization test under `test/**`. The shared lower-level pieces are present—condition plans, readers, activation-specific scratch executors—but the public service they are specified to support is missing. `isdefined(Cadence, :linearize)` is `false` in the probe (`probes/services_confirmed_gaps.jl:54`).

### 3. A statically invalid selector index resolves and fails later with `BoundsError`

**Severity: medium.** The optional component index is part of the selector and is intended to yield a named scalar from a vector leaf (`spec.md:8320-8322`, `spec.md:9093-9105`). Tap lists are validated at resolution (`spec.md:9107-9115`), and `TapResolution` carries the optional index (`spec.md:10936-10939`).

`_check_index` rejects only an index on a `Real` scalar. It does not check a statically sized array's known axes or whether another declared value supports indexing (`src/readers.jl:283-290`). The compiled read later executes `v[i]` directly (`src/readers.jl:163-176`). Thus an `SVector{2}` selector with index 3 compiles successfully and raises a raw `BoundsError` during `gather`, after resolution has declared the read valid.

The reproducer is `probes/services_confirmed_gaps.jl:31-37`. Existing tests cover a valid vector index and the scalar-index refusal (`test/test_readers.jl:28-31`, `test/test_readers.jl:93-103`), but not a statically out-of-range index.

### 4. Required callable fields of `TrimProblem` bypass setup validation

**Severity: medium.** `condition` and `residuals` are required functions with pinned call shapes (`spec.md:8567-8572`, `spec.md:8685-8692`). A malformed problem is a setup-time `DiagnosticError`, and `TrimProblemInvalid` carries the offending problem field and types/names (`spec.md:8947-8956`, `spec.md:10940-10942`).

The collecting setup pass checks decisions, bounds, tolerances, and reads, then throws its collected list (`src/trim.jl:389-394`). It never validates that `condition` is applicable to the decision NamedTuple or that `residuals` is applicable to `(gathered_reads, decisions)`. Both are invoked directly afterward (`src/trim.jl:403-409`). A non-callable field therefore produces a raw `MethodError`, outside `TrimProblemInvalid` and after the advertised collecting barrier.

The empty valid-shape problem with `condition = 42` at `probes/services_confirmed_gaps.jl:39-43` produces a raw `MethodError`. Existing malformed-problem tests exercise tuple types, keys, tolerances, read sets, and residual-return keys (`test/test_trim.jl:229-303`, `test/test_trim.jl:335-350`), but not callable-field conformance.

### 5. Condition conversion swallows `InterruptException`

**Severity: medium.** Section 14.8 says an interrupt during a long solve unwinds the ordinary Julia call, with scratch discarded and no commit (`spec.md:8873-8877`). This requires operator interruption to retain its control-flow meaning throughout setup and iteration.

`_convert` catches every exception and turns it into the boolean “unconvertible” result (`src/conditions.jl:384-389`). This includes `InterruptException`. Resolution consequently converts an operator interrupt from a user conversion method into a collected `ConditionResolution(reason=:unconvertible)` and continues checking other entries (`src/conditions.jl:323-349`).

The probe defines a `convert(Float64, value)` method that throws `InterruptException` and resolves it as a root-input value (`probes/services_confirmed_gaps.jl:45-52`). The result is `DiagnosticError{Vector{Diagnostic}}`, not an unwinding interrupt. The same mechanism applies during trim plan compilation because trim reuses `_resolve_entries`.

### 6. Unknown path diagnostics omit the required list in hand

**Severity: low.** Condition resolution requires did-you-mean information over children (`spec.md:8217-8224`), and `ConditionResolution` carries candidates whenever a list is available (`spec.md:10922-10928`). Linearization/read tap validation likewise promises did-you-mean lists (`spec.md:9107-9115`).

Condition `_component` classifies unknown versus assembly paths but supplies no candidate paths (`src/conditions.jl:397-405`). Reader `_read_component` does the same (`src/readers.jl:253-264`). Tests assert the reason/path and do not require candidates (`test/test_conditions.jl:137-163`, `test/test_readers.jl:77-103`). The rejection is correct, but it lacks the diagnostic information the specification calls for.

## Design improvements and explicit limits

1. Introduce a scoped-read value that records a prefix without resolving it, paralleling `Scoped` conditions. Define `at(prefix, Reads)` over it and implement `at(prefix, TrimProblem)` exactly as §14.9 specifies. This also gives future tap sets the same relocation primitive.
2. Validate callable seams before allocating/evaluating scratch. `applicable(problem.condition, guess)` can diagnose a plainly non-callable condition. The residual seam can be checked as soon as gathered reads exist, with exceptions framed by field and invocation context rather than leaking a bare dispatch error.
3. Resolve indices against known static axes. For types whose axes are not schema-known, either reject indexed selectors at resolution or compile a checked read that raises `TapResolution`; do not move the first structured failure to raw `getindex` execution.
4. Narrow conversion catching to expected conversion failures and immediately rethrow `InterruptException`. The same carve-out should be used at every stopped-service wrapper that catches user code.
5. Normalize condition shapes across activation scalars and compare the nominal setup shape with the seeded shape. The specialized plan detects drift among seeded iterations (`src/conditions.jl:728-784`), but separate nominal and seeded compilations are not compared (`src/trim.jl:401-426`). This is a defensive improvement around the authoring rule that a condition function's shape is decision-independent; no wrong result was demonstrated from the current split.
6. Treat custom backend output as a checked seam. `trim!` currently trusts `out.d/status/nevals/niters` and accesses them directly (`src/trim.jl:472-480`). The specification pins the backend contract but defines no dedicated backend-violation diagnostic. Validating length, scalar types, finiteness where required, and returned-point box membership would turn third-party backend mistakes into local failures. This is a hardening proposal, not a confirmed violation by the built-in backend.
7. Validate `LevenbergMarquardt(maxiter, λ₀)` parameters or document their admitted domain. The spec fixes defaults and algorithm, but does not state rejection rules for negative iteration counts, nonpositive damping, or nonfinite damping; the current constructor accepts all `Real` values (`src/trim.jl:158-170`).
8. Use a lifecycle acquisition primitive if stopped-service calls and run entry must be race-free under concurrent callers. The current services perform atomic reads of lifecycle, but do not reserve the stopped state for the duration of capture/trim setup. This audit did not construct a deterministic race reproducer, so it is recorded as a concurrency design risk rather than a confirmed defect.

## Ruled-out suspicions and verified behavior

- **Resolution before write:** `resolve_condition` performs the full collecting pass before building a plan (`src/conditions.jl:261-289`), and `init!` resolves and asserts root-input totality before resetting defaults or applying writes (`src/sim.jl:642-652`). Focused tests verify that failed resolution/totality leaves state, inputs, lifecycle, and snapshot identity unchanged (`test/test_conditions.jl:228-250`).
- **Declared-default overlay semantics:** both dynamic and specialized plans merge partial `s`/`m` overlays onto declared defaults, not current stores (`src/conditions.jl:281-288`, `src/conditions.jl:595-620`). Fresh-run and store-merge tests cover the distinction (`test/test_conditions.jl:259-287`, `test/test_conditions.jl:421-431`).
- **Specialized shape atomicity:** tree-type dispatch and the prefix sweep both reject drift before `_writes!` begins (`src/conditions.jl:728-759`). Tests verify type and prefix drift and unchanged executor state (`test/test_conditions.jl:433-457`).
- **Root-input totality:** `assert_total` compares plan coverage with root faces in declaration order and throws before evaluation (`src/conditions.jl:481-501`). Trim applies it to the nominal scratch plan before the establishment round (`src/trim.jl:401-409`). Tests cover both init and trim setup shortfalls.
- **Probe-value exclusion from service evaluation:** trim builds a nominal scratch world from the authored composite, runs the establishment round, and copies frozen discrete cells to the seeded executor (`src/trim.jl:401-426`, `src/trim.jl:503-520`). Tests vary authored discrete state and observe the corresponding trim solution (`test/test_trim.jl:367-404`).
- **Scratch freshness and no-commit failure:** `_scratch` compiles a fresh executor/buffer set per invocation (`src/trim.jl:496-501`). The authoritative simulation is touched only by `_verdict!` after the service-owned convergence test (`src/trim.jl:547-558`). Nonconvergence tests compare the entire world and lifecycle before/after (`test/test_trim.jl:152-180`).
- **Named pairing and bounds in the built-in backend:** setup compares key sets, packs by name in canonical orders, rejects inverted boxes, projects the initial guess, and projects every LM trial (`src/trim.jl:239-297`, `src/trim.jl:179-220`, `src/trim.jl:462-479`). Tests cover permuted bounds, inverted/degenerate boxes, an initially out-of-box guess, and saturation reporting (`test/test_trim.jl:132-150`, `test/test_trim.jl:276-333`). No built-in-backend box escape was found.
- **Service-owned convergence:** after any backend return, the service evaluates residuals at `out.d` and applies its own per-residual tolerance test before committing (`src/trim.jl:474-480`, `src/trim.jl:547-556`). Backend status is only copied to the report. This matches D-150.
- **Commit semantics:** a converged trim commits through `init!(sim, override(baseline, condition(solution)); t0=...)`, then reports boundary-zero events and re-gathers committed residuals (`src/trim.jl:558-579`). Tests cover event and projection movement, warnings, and equivalence to a direct `init!` (`test/test_trim.jl:406-470`).
- **Capture:** capture is limited to `initialized`/`stopped`, reads all declared stores and root inputs, and returns time beside the condition (`src/conditions.jl:786-851`). Round-trip tests cover cold boundary and post-run warm restart (`test/test_readers.jl:151-203`).
- **Activation pairing and allocation:** compiled plans/readers carry their activation in the type and mismatch through `InternalInvariant`; focused tests verify no writes on mismatch and zero allocation for conforming specialized apply/gather (`test/test_readers.jl:66-75`, `test/test_readers.jl:123-149`, `test/test_trim.jl:473-498`).
- **Recorded extensions:** closed-loop sampled-data trim and sampled-data linearization are explicitly recorded, not built. Their absence is not reported as a defect. Finding 2 concerns the required continuous linearization service.

## Verification

The focused probe was run successfully with:

```text
julia --project=test docs/reports/20260915_audit/probes/services_confirmed_gaps.jl
```

Results are retained in `docs/reports/20260915_audit/validation/services-confirmed-gaps.log`:

```text
relocate TrimProblem: ConditionNodeMisuse
relocate Reads: ConditionNodeMisuse
out-of-range compiled read: raw BoundsError
non-callable trim condition: raw MethodError
interrupt during condition conversion: collected DiagnosticError
linearize defined: false
```

The audit's earlier direct suite completed 2425/2425 assertions on Julia 1.13.0 at the original baseline. The current-revision package gate completed 2478/2478 assertions on Julia 1.13.0; see `validation/pkg-test-current.log` in the audit root. It was not duplicated by this reviewer.

## Primary-review final reconciliation to `6986ad4`

The complete source/test/design delta after `f941c50` was inspected. Finding 6
is **resolved**: condition and read paths now use `resolve_authored`, returning
`PathResolution` with sibling candidates, provenance and a declared-type arm
for generic traversal. Tests cover concrete/generic holdings, primitive stop
points, and capture/reapply through nested `at` nodes. Appendix C was updated
consistently with those occurrence sites. Earlier line numbers remain historical.

Findings 1–5 remain: neither service relocation nor linearization was added;
index validation, trim callability and conversion interrupt handling are
unchanged. The final service probe reproduces these cases; see
[final output](../validation/services_confirmed_gaps-final.log).
