# Execution, scheduling, events, and localization audit

**Baseline:** `865521a0f7be6894b1688925bb349dcbadd06539`  
**Audit date:** 2026-09-15  
**Disposition:** four conformance findings: three high severity and one medium severity.

This was a fresh, read-only audit of the authorized design, source, and test inputs. I read `docs/design/implementation.md` first. I did not use `pending.md`, earlier reports, or files outside `src/**`, `test/**`, and `docs/design/{spec,decisions,implementation}.md` as audit evidence. The only additions are this report and the two isolated probes under `docs/reports/20260915_audit/probes/`.

## Inspected scope and subsection coverage

### Design

- `docs/design/implementation.md:1-58`, especially its source map for the store, executor, build/compiler, simulation loop, stepper, localization, and fixtures (`:23-29`, `:37-39`).
- Formalism and event policy: spec §2.1 (`docs/design/spec.md:201-245`).
- Evaluation order and feedthrough: §5.1-§5.3 (`:560-881`), including stage roles, projection placement, and the boundary sequence.
- Numeric genericity and allocation: §7.2 (`:1407-1470`) and §7.5 (`:1651-1714`).
- Runtime conformance and compiled execution: §9.5 (`:3403-3537`) and §9.7 (`:3574-3755`).
- Time and execution: all of §10 (`:3756-4833`): loop ownership, stepper seam, boundary consistency, localization, multirate scheduling, event iteration, and pacing.
- Boundary zero: §14.5 (`:8407-8504`).
- Related lifecycle/error text needed to assess boundary masking and time bounds: §12.4's operator-interrupt rule (`:6696-6735`), §12.6 (`:6816-6958`), §13.4 (`:7494-7659`), and the deployment/running API synopsis (`:10399-10452`, `:10573-10610`).
- Ratified decisions governing this area, including D-014, D-017-D-021, D-027, D-052-D-053, D-059, D-067, D-080-D-082, D-086, D-090-D-091, D-100-D-101, D-111, D-116, D-128, D-132-D-133, D-147, D-152-D-157, D-179, D-181-D-182, D-185-D-187, D-191, D-196, D-203, D-205, D-218, D-221, D-223, D-227, D-230, and D-235.

### Source

- Entire `src/executor.jl:1-510`: typed entries and bundles; generated stage/state writes; chunked walks; interior/boundary/establishment gates; event and projection entries; guard/fire/project walks; event registers; runtime latching; compiled body construction.
- Entire `src/stepper.jl:1-133`: RK4 and Heun stage sequencing, retained startpoint, and cubic-Hermite dense output.
- Entire `src/localization.jl:1-218`: indexed-grid target, arrival sweep, theta-zero validation, trigger/budget scan, ITP bracketing, holding-endpoint return, off-grid boundaries, publication, stop checks, and remainder integration.
- Execution-bearing parts of `src/sim.jl`: deployment/time bounds (`:20-49`, `:51-215`), boundary/event iteration and integration seam (`:360-555`), trajectory opening/boundary zero (`:557-658`), run and step entry points (`:867-923`, `:1144-1205`), frame loop/catch site (`:1045-1142`), and related publication/termination calls needed to establish order.
- Relevant compiler material in `src/build.jl:756-832` and `:1033-1186`, because it constructs the executor/event entries and supplies the build-time half of the always-on handler contract.

### Tests and fixtures

- Entire requested focused files: `test/test_executor.jl:1-55`, `test/test_continuous.jl:1-62`, `test/test_discrete.jl:1-384`, `test/test_stepper.jl:1-102`, `test/test_events.jl:1-286`, and `test/test_localization.jl:1-233`.
- Pertinent event, localization, integration, and interrupt fixtures in `test/fixtures.jl`, especially `Trigger` (`:189-202`), `Sawtooth` (`:229-241`), chattering/priority fixtures (`:268-319`), `Stamper`/`GatedStamper` (`:331-368`), `Bouncer`/`Relaxer` (`:377-416`), and `Interrupter` (`:560-571`).
- Pertinent runtime-conformance and interrupt tests in `test/test_failures.jl:1-114`, `:250-288`, and `:461-594`, plus time-bound/partial-advance tests in `test/test_lifecycle.jl:91-149` and `:214-240`.

Test comments were treated as claims to verify against code, not proof of behavior.

## Findings

### EXE-01 — High — Real-time pacing is absent from the runtime

**Requirement.** Section 10.7 requires pacing outside trajectory semantics, waits between completed frames, a piecewise-affine wall-clock map, absolute deadlines with debt repayment, five-frame debt forgiveness and warning, explicit `pace = Inf` disablement, a sleep-then-spin wait with `margin`, and published pacer statistics (`docs/design/spec.md:4744-4825`). The public API requires `run!(sim; gui=false, pace=1, margin=0.002, ...)` (`:10573-10584`, `:10598-10600`). D-021 ratifies the affine map and bounded debt (`docs/design/decisions.md:664-681`); D-027 chooses task-yielding `sleep` (`:802-817`); D-080 and D-081 keep event detection pace-independent and preserve `t*` as a boundary (`:2232-2266`).

**Implementation evidence.** `Simulation` has no pacer state (`src/sim.jl:20-49`), its constructor has no pace or margin deployment (`:131-175`), and `run!` accepts only `t_end` and `stop_on` (`:912-923`). The frame loop only conditionally calls `yield()` when a device is rostered (`:1057-1078`); it computes no deadline, performs no wait, carries no debt, re-anchors nowhere, and emits no pacing status.

**Mechanism / reproducer.** `run!(sim; pace=1)` fails at dispatch because the keyword is absent. A plain `run!` advances frames as fast as computation permits. Thus the documented default `pace=1` cannot pace at real time, and `pace=Inf` cannot select the specified unpaced mode.

**Test gap.** None of the focused execution tests exercises `pace`, `margin`, deadline recovery, re-anchoring, or paced/unpaced trajectory identity. The full suite passing therefore cannot cover §10.7.

### EXE-02 — High — The loop catches asynchronous SIGINT after abandoning a possibly half-written boundary instead of masking it

**Requirement.** The operator-interrupt rule requires `disable_sigint` across the complete boundary macro-sequence, with deferred delivery only at boundary-consistent unmask points. Ctrl-C must complete the current boundary, publish its final snapshot, and stop cleanly (`docs/design/spec.md:6696-6730`). D-132 states that boundary masking is normative and that the ordinary runtime catch should never receive the operator interrupt in normal operation (`docs/design/decisions.md:3837-3865`).

**Implementation evidence.** `_advance!` wraps the loop in an ordinary `try` (`src/sim.jl:1059-1089`) without `disable_sigint`. Its catch explicitly handles `InterruptException` by abandoning the unpublished frame and acknowledges that stores may be mid-boundary (`:1090-1097`). This is the exact inconsistent state the requirement says masking prevents.

**Mechanism / reproducer.** A real SIGINT may arrive after `drain!`, during integration, during projection, between event handlers, during ticks, or while publication is assembling state. `_advance!` immediately exits via the catch. The previous snapshot remains final, but the mutable execution stores can reflect an arbitrary prefix of the interrupted boundary. The simulation is then marked stopped and exposed to stopped-simulation services despite those dirty stores.

**Test gap.** `test/test_failures.jl:258-288` uses fixtures whose model code synchronously throws `InterruptException`; that verifies the defensive catch's source/lifecycle routing, not asynchronous signal deferral or completion of the in-progress boundary. The fixture is explicit at `test/fixtures.jl:560-571`. No test delivers SIGINT into different boundary phases and checks store/snapshot consistency.

### EXE-03 — High — A late handler can return an unknown top-level store key and the runtime silently discards it

**Requirement.** The probe comparison must remain in force at runtime so a branch first reached later fails at its first execution (`docs/design/spec.md:3403-3428`). The uniform rule explicitly includes handlers (`:3495-3506`), and handler return validation must check the returned `NamedTuple` key set first, rejecting unknown keys or stores the component does not declare (`:3508-3520`). D-053 and D-235 ratify always-on conformance at the generated write (`docs/design/decisions.md:1434-1458`, `:8435-8449`).

**Implementation evidence.** The build probe correctly validates the whole handler return: it requires a `NamedTuple`, enumerates every top-level key, and emits `HandlerReturnKey` for keys outside the component's `{x,m}` stores (`src/build.jl:787-827`). At runtime, `_fire_walk` passes the handler return to `_latch!` (`src/executor.jl:313-323`), but `_latch!` only looks for `:x` and `:m` and then returns (`:325-330`). It never compares the complete top-level key set. Its `ret::NamedTuple` method also means a late non-`NamedTuple` top-level return falls through to a raw `MethodError`, rather than the required located `ConformanceFailure`.

**Mechanism / reproducer.** `docs/reports/20260915_audit/probes/execution_handler_key_drift.jl` defines a handler whose build-time branch returns valid `m`, while the branch first reached at `t=0.1` returns `(unknown=true,)`. The event fires, `_latch!` sees neither `x` nor `m`, silently ignores the complete return, and the simulation finishes with `m.fired == false`. A second component changes from a valid build-time `NamedTuple()` to scalar `5`; the failed dispatch is wrapped with a raw `MethodError` cause instead of the specified conformance diagnostic.

**Observed probe result (Julia 1.13.0):**

```text
unknown runtime handler key was silently ignored
non-NamedTuple runtime handler return became raw MethodError cause
```

The probe exited successfully with its assertion that the mode remained unchanged. This is high severity because an authored hybrid transition is silently lost while the run reports success.

**Test gap.** `test/test_events.jl:72-104` checks malformed handler returns only on the build-time branch. Runtime tests cover late port key drift, derivative/projection type drift, and nested mode type/shape drift (`test/test_failures.jl:461-594`), but no test covers a late unknown top-level handler key or a late non-`NamedTuple` top-level handler return.

### EXE-04 — Medium — Time-bound conversion can turn a finite run into an unbounded run or raise a raw integer-conversion error

**Requirement.** A finite `t_end` ends at the first grid boundary reaching or exceeding it (`docs/design/spec.md:6547-6554`), while `Inf` is the explicit open-ended default (`:10399-10417`, `:10434-10439`). Constructor and per-run override are the two validated binding sites.

**Implementation evidence.** `_t_bound_diag` accepts every nonnegative `Real`; `_t_bound` and the constructor then convert it to `Float64` without checking the converted result (`src/sim.jl:156-169`, `:181-192`). `_frames_to` maps any infinity to `typemax(Int)`, but otherwise executes `ceil(Int, ...)` without range handling (`:194-209`). `run!` invokes that conversion before the run body (`:912-921`).

**Mechanisms / reproducers.** `docs/reports/20260915_audit/probes/execution_time_bounds.jl` demonstrates both branches:

1. `Simulation(...; t_end=big"1e1000")` accepts a finite `BigFloat` and stores `Inf`, silently changing a finite bound into unbounded execution.
2. `run!(sim; t_end=1e300)` retains a finite `Float64`, then `_frames_to` raises raw `InexactError` while converting the enormous frame count to `Int`. Because this occurs before `_run_body!`, lifecycle remains `:initialized`, but callers receive neither the normal end-time behavior nor a framework diagnostic.

**Observed probe result (Julia 1.13.0):**

```text
finite BigFloat t_end converted to Inf
large finite Float64 t_end raised raw InexactError
```

**Test gap.** `test/test_lifecycle.jl:91-149` covers ordinary finite/off-grid/offset bounds, `Inf`, and negative rejection. It does not cover finite-to-infinite conversion, a bound whose frame count exceeds `Int`, or the same overflow through `step!(; t_plus=...)` (`src/sim.jl:1186-1191`).

## Optional improvements and additional test coverage

These are not additional confirmed implementation defects.

- Add direct runtime conformance tests for every handler top-level return class: extra key, a key naming an undeclared `x` or `m` store, non-`NamedTuple`, valid reordered keys, complete `x`, and partial `m`. These should force a branch different from the probe branch.
- Add numeric-bound tests around the representability boundary: the largest finite `t_end` whose frame count fits `Int`, the next value, a finite wider `Real` that converts to `Inf`, NaN, positive `Inf`, and `step!(; t_plus=...)` overflow. Specify whether out-of-range finite bounds are rejected with `DeploymentInvalid` or saturated intentionally; the current silent semantic change should not remain.
- Add a deterministic interrupt injection seam around each macro-sequence phase, so tests can assert that delivery is deferred through publication and only then converted to a stop. A synchronous model-thrown `InterruptException` cannot establish the asynchronous guarantee.
- Once pacing exists, use an injected monotonic clock/wait seam to test absolute deadlines, debt repayment, five-frame forgiveness, re-anchor on pace change/unpause, `margin` endpoints, and bit identity against an unpaced run without relying on wall-clock timing in CI.

## Ruled-out suspicions

- **RK4/Heun stage times and arithmetic:** RK4 evaluates at `t`, two stages at `t+h/2`, and one at `t+h`, then applies the classical weights; Heun uses the start and predicted endpoint (`src/stepper.jl:49-67`, `:85-99`). Analytic convergence tests distinguish fourth and second order (`test/test_stepper.jl:20-42`). I found no coefficient or stage-time regression.
- **Dense interpolation and retained endpoint data:** both backends retain `(x0,k1)` and the cubic Hermite interpolant uses start state/derivative and arrival state/derivative with the segment length (`src/stepper.jl:69-82`, `:101-133`). Heun localization is exercised separately (`test/test_stepper.jl:44-81`).
- **Nonfinite integration-result detection:** every nonempty or empty integration segment passes immediately through `_check_finite!` before projection or any boundary sweep; attribution maps the flat leaf back to its component and frame-entry boundary (`src/sim.jl:517-555`). This matches the specified state-result check. The scratch derivative need not be separately scanned because contamination is checked in the integrated state.
- **Projection placement:** projection runs after each integrated state write and before decode at tick, off-tick, and boundary-zero boundaries (`src/sim.jl:378-430`); event firing projects again before the next sweep (`src/executor.jl:313-323`). Focused tests cover initial and ongoing manifold projection (`test/test_events.jl:245-256`) and late projection return-type drift (`test/test_failures.jl:537-547`).
- **Event priority, blocked edges, and quiescence:** the event loop fixes the boundary due-set, allows at most one event per component per round in declaration order, preserves an eligible-but-blocked edge, re-sweeps after firing, applies ticks only after quiescence, and commits settled priors (`src/sim.jl:433-503`). Tests cover cascade, re-decision, reset, post-transition update, and firing-budget degradation (`test/test_events.jl:112-243`).
- **Multirate gating and boundary zero:** compiled gates use `(tick-Φ) % D`, while establishment widens output stages and keeps update index zero (`src/executor.jl:388-510`, `src/sim.jl:404-430`). Tests cover exact ZOH recursion, compile-time holding, nonnominal freezing, schedule folding/anchors, hyperperiods, boundary zero, and zero-allocation phase bodies (`test/test_discrete.jl:11-384`).
- **Localization endpoints, remainders, and budgets:** the localization loop validates theta zero under the frame's input epoch, locates only false-to-holding arrival brackets, chooses the earliest holding endpoint, folds a frame-top root into the ordinary boundary, publishes off-grid `t*` boundaries with no ticks, and repeats over the remainder (`src/localization.jl:28-158`). The tolerance is correctly scaled to `localization_tol*h` in absolute time even on a shorter remainder (`:174-218`). Tests cover exact/nonlinear crossings, epoch edges, frame-top degeneracy, ties and multiple roots, budget degradation, gating, no ticks at `t*`, and nonnominal compilation (`test/test_localization.jl:7-212`). I found no off-by-one in the localization budget: exactly `budget` localized boundaries are allowed, and the next trigger degrades.
- **Degenerate no-state execution:** the framework advances only the clock when the state buffer is empty and still performs the finite-state pass and normal boundary sequence (`src/sim.jl:511-521`).
- **Executor roster and chunking:** the executor exposes the required stage-1, stage-2, RHS, tick, event, and projection callables; the chunk recursion keeps gate specialization and order (`src/executor.jl:42-171`, `:438-510`, `src/build.jl:1092-1186`). `test/test_executor.jl:10-55` checks roster completeness, wide-model chunk behavior, and event/projection callable presence.

## Validation and limitations

- The direct suite passed **2425/2425** assertions on Julia 1.13.0, as recorded by the main audit run. This confirms the current suite is green; it does not negate the absent features or uncovered adversarial branches above.
- Both execution probes ran independently with `julia --project=test` and exited zero after asserting the reproduced behavior.
- I did not send a real operating-system SIGINT during arbitrary boundary phases. Such timing is nondeterministic without an injection seam; the complete absence of `disable_sigint` around `_advance!` and the catch's own mid-boundary-abandonment behavior establish EXE-02 directly.
- I did not benchmark wall-clock pacing because the public keywords and implementation machinery are absent.
- Whole-frame allocation claims are intentionally not raised here. The design contains separately reported tension between the scoped phase-body invariant and per-boundary snapshot retention; this audit only verified the executor/stepper/localization phase paths under their stated scope.
