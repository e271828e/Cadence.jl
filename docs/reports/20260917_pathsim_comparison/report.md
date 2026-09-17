# Cadence.jl versus PathSim — 2026-09-17

A comparison of Cadence.jl (this repository at `9489e88`) against PathSim 0.25.1
(<https://github.com/pathsim/pathsim>, `af5c1779`, PyPI release of the same
version) on five axes: features, performance, usability, mathematical rigor
and code quality.

## Scope and method

PathSim was read from source: `simulation.py`, `blocks/_block.py`,
`connection.py`, `subsystem.py`, `utils/graph.py`, `utils/register.py`,
`utils/portreference.py`, the solver bases (`_solver.py`, `_rungekutta.py`),
the event modules, the discrete, ODE and dynamical-system blocks, and
`optim/operator.py`. Cadence was read from `spec.md` (§2–§7, §9.5, §9.7, §10,
§11.1, §12.7, §13, §14.7–§14.10, §16), `implementation.md`, `extensions.md`
and `src/`. Both frameworks ran the same model on the same machine, and three
PathSim behaviours were probed empirically. Every script is under `probes/`.

**Cadence is assessed as if every `pending.md` item were built.** Where a gap
is a design exclusion rather than a pending item, the text says so.

**What each is.** PathSim is a Python block-diagram simulator in the Simulink
mould: blocks with scalar float ports, connections, per-block ODE engines, a
global fixed-point loop, a large block library, about twenty integrators, a
web editor (PathView), FMU import, a JOSS paper, 84 releases, one main author.
Cadence is a Julia framework for hierarchical hybrid models with a build-time
derived static schedule, immutable typed signals, a harmonic multi-rate grid, a
formal event semantics, and a runtime periphery built for deterministic replay
and zero-allocation real-time operation. Cadence's `extensions.md` positions it
accurately: "Simulink's fixed-step, loop-free, harmonic-multirate causal
subset, plus guarantees Simulink does not offer". PathSim is closer to
Simulink's engine breadth.

## 1. Features

### PathSim has, Cadence excludes or lacks

| Feature | PathSim | Cadence |
|---|---|---|
| Integrators | ~20: Euler, SSPRK, RK4, embedded adaptive RK (RKF45, DOPRI5, RKDP87…), DIRK/ESDIRK, BDF, GEAR; adaptive step control; Hairer initial-step estimate | RK4, Heun, fixed step. The seam admits others later (§10.2); adaptive and stiff methods deliberately not in the first cut |
| Algebraic loops | Solved per step by Anderson-accelerated fixed point on loop-closing connections | Refused at build (§5.5). Design exclusion, not pending |
| DAEs, constraints, BVPs | `SemiExplicitDAE`, `Constraint`, `bvp` blocks | Excluded (§2.2); projection covers manifolds |
| Steady state | `steadystate()` (all derivatives forced to zero), `pss()` periodic steady state by shooting | `trim!` covers the DC case more generally (§4 below); no PSS |
| Checkpoints | `save_checkpoint`/`load_checkpoint` (JSON + NPZ), mid-run state restore | Trace + replay; `capture` for in-memory conditions; on-disk persistence open (§16) |
| Runtime structural mutation | Add/remove blocks and connections mid-run (lazy graph rebuild), `on()/off()`, `@mutable` parameter re-init | Mid-run mutation doctrine (§12.5) forbids structural change; parameters are fixed at build |
| Block library | ~35 modules: sources, filters, PID, LTI, continuous transport delay, lookup tables, logic, switches, relay, Kalman, noise, spectrum, scopes, FMU, RF | §13.7 library is a migration deliverable; today only test fixtures |
| Plotting and recording | `Scope`, `Spectrum`, `RealtimePlotter`, `sim.plot()` | Snapshot log plus readers; no plotting |
| GUI editor, notebooks | PathView web editor; 35 example notebooks; hosted docs | None |
| Continuous transport delay | `Delay` block with interpolated history | A library extension (`extensions.md` item 4) |
| Triggered discrete updates | `Schedule`, `ScheduleList`, `Condition` events; arbitrary float periods and offsets; time lists | Harmonic grid only; edge-triggered `state_update` is "real spec work" (`extensions.md` item 7) |

### Cadence has, PathSim lacks

| Feature | Cadence | PathSim |
|---|---|---|
| Typed, structured signals | Ports carry any immutable value: structs, `SVector`s, enums, `Bool`, `Symbol`, query objects (§4.1, §4.4) | Ports are `float64` scalars in a numpy register. Vectors are port ranges (`a[0:3]`), Bools are 0.0/1.0, no structs |
| Declared contracts, build checks | `input_types`/`output_types`, wire type-checking, unconnected-input and two-producer errors, did-you-mean, ~80 diagnostic kinds (Appendix C) | No port types. Unconnected inputs silently read 0.0; an out-of-range port index also reads 0.0 (`Register.__getitem__`) |
| Structural feedthrough, static schedule | Two output stages; algebraic cycles found by SCC and classified real/artificial by a set-tracer (§5.3–§5.6) | Per-block `__len__` flag; `DynamicalSystem` decides by a numerical Jacobian at t = 0 (§4 below) |
| Multi-rate | Rate scopes, `Relative`/`Absolute`, phases, exact rational periods, compiled `(D, Φ)` gates, ZOH by construction, hyperperiod audit (§10.5) | One `Schedule` event per discrete block with a float period, tolerance-based tick detection, no rate composition |
| Event semantics | Two policies by guard type; iterate to quiescence with a firing budget; epoch rule; ITP localization on dense output without re-integration (§10.4, §10.6) | One detection pass per step; cascades not resolved (§4 below); localization only in adaptive mode, by step rejection and re-integration |
| Deterministic replay | Always-on input trace, frame-indexed drain, RNG in state, pace-independence (§11.5, §12.7) | Checkpoints only; the `RNG` block uses global `np.random` |
| Concurrency model | Staged writes, snapshot reads, device roster, atomic handoffs; GUI and logging safe by construction (§11) | Single-threaded; the periphery mutates blocks directly |
| Numeric genericity | `ForwardDiff` duals through the whole continuous path; CI Dual sweep (§7.2) | Central differences (`num_jac`, r = 1e-3) |
| Trim | Residual system, box bounds, LM with exact AD Jacobians, per-residual tolerances, a report value (§14.7–§14.8) | `steadystate()` only: zero all derivatives |
| Zero-allocation, type-stable stepping | CI invariant via the `phase_bodies` seam (§7.5, §9.7) | Not applicable |
| Condition algebra | `fragment`/`at`/`combine`/`capture`/`override`, path-addressed initialization as values (§14.1–§14.6) | `initial_value` per block, `reset()` |
| Environment query signals | Field handles: atmosphere and terrain as immutable query objects on ports (§4.4) | No equivalent |
| Design record | 12k-line normative spec, 9k-line decision log, transactional deviation register | Docstrings and the JOSS paper |

### Both, differently

Hierarchy: PathSim nests `Subsystem` with an `Interface` block and treats the
subsystem as one node in the parent graph; Cadence flattens assemblies for
scheduling and keeps them for navigation. Linearization: PathSim assembles
per-block numerical Jacobians into a labelled `StateSpace` and can also swap
blocks for linear surrogates; Cadence (§14.10, pending) takes one seeded Dual
pass giving exact A, B, C, D. Real time: PathSim's `run_realtime` paces by a
speed factor with a generator loop; Cadence (§10.7, pending) uses debt-based
deadlines with a hybrid sleep/spin wait and forgiveness.

## 2. Performance

Same model in both: the closed-loop damped oscillator (a plant with two states,
a gain, a summing junction), N independent copies driven by one reference,
RK4, h = 1 ms, 10 s of simulated time. Apple Silicon, Julia 1.13.0, Python 3
with numpy 2.0.2. Scripts: `probes/bench_pathsim.py`,
`probes/bench_cadence.jl`.

| N | components | PathSim setup | PathSim per step | Cadence compile¹ | Cadence per step | step allocation | ratio |
|---|---|---|---|---|---|---|---|
| 1 | 3 (+1 const) | 0.2 ms | 58 µs | 6.8 s | 0.4 µs | 0 B | ~150× |
| 10 | 30 | 0.6 ms | 445 µs | 12.4 s | 1.3 µs | 0 B | ~340× |
| 100 | 300 | 6 ms | 4170 µs | 29.3 s | 13.1 µs | 0 B | ~320× |

¹ `Simulation` + `init!` + first `run!`, package load excluded (0.6 s).
N = 1 was measured on a fresh process; N = 10 and N = 100 afterwards in the
same process, so those rows exclude the ~5 s of framework-generic compilation
the first model in a session pays. Both frameworks reach |x − exact| ≈ 2e-12.

**Execution.** Cadence costs about 50 ns per component per step; PathSim about
14 µs. PathSim's per-step work is interpreted Python: for every RK stage,
every block does `Register.to_array()` copies, a lambda call and
`update_from_array`, and every connection does a numpy fancy-indexed transfer;
each dynamic block also owns its own solver object with dict-indexed Butcher
rows. Cadence compiles one unrolled, specialized body per activation over
contiguous per-eltype cell blocks, so the per-component cost is a few loads and
stores. PathSim's own docs recommend monolithic `ODE` blocks for performance;
that recovers part of the gap by giving up block-diagram granularity, which
Cadence never has to trade away.

**Compilation.** PathSim imports in 0.57 s and builds a 300-block model in
6 ms with no JIT. Cadence pays 7–30 s per model *type*, of which about 5 s
is framework-generic and paid once per session, then 1.4 ms to rebuild the
same type warm. Compile cost is not monotone in model size: N = 30 costs 38 s
in the same session where N = 100 costs 29 s, with the excess in `init!` and
the first `run!` rather than the build. Unexplained; see §16's re-measurement
item. Break-even against PathSim is about two minutes of simulated time at
N = 1 and about 7 s at N = 100. The spec's mitigation ladder (§9.7) applies:
lazy activations, chunking, precompile workloads baked into package images.
Nothing in these runs used a package image.

**Where each wins.** Short edit-run cycles on small models favour PathSim's
turnaround. Long runs, real-time operation, parameter sweeps, Monte Carlo, and
trim or localization loops that evaluate the model thousands of times favour
Cadence by two orders of magnitude. The 10 s run at N = 100 took 42 s in
PathSim, so PathSim cannot run that model in real time at 1 kHz; Cadence used
1.3% of the wall budget.

**A PathSim quirk the benchmark tripped over.** `run(10.0)` at dt = 1e-3 ends
at t = 10.001, because simulation time is accumulated by repeated addition and
the loop overshoots by a step when rounding lands short. The benchmark compares
against the analytic solution at the reached time for that reason.

## 3. Usability

### Assembling models

PathSim is quick and forgiving. Blocks are objects, `Connection(src, t1, t2,
…)` fans out, ports are integers or labels, subsystems wrap a block list.
Nothing needs declaring; algebraic loops and unconnected inputs just run. The
cost is that the same forgiveness hides mistakes: a wrong port index reads
zero, vector signals become index bookkeeping (`Connection(a[0:3], b[1:4])`),
sample times are per-block floats with no composition, and the error messages
that do exist are thin (`"Connection conflict detected"` names nothing). The
hybrid part of a model lives outside its blocks, as closures that reach into
engines (`Ix.engine.set(abs(x))` in PathSim's own bouncing-ball test).

Cadence asks more up front and returns it as diagnostics. Wiring is string
paths checked at build, with collected errors sorted by path and did-you-mean
lists. The one triggered deliberately for this report reads well:

```
AlgebraicCycle: algebraic loop among `plant`, `sum`, `ctl`: plant/power → sum/b,
sum/e → ctl/e, ctl/out → plant/u — real: a loop survives the trace (traced
globally); break it with a state, a unit delay or a stage-1 (`output_state`) port (§5.5)
```

**Fan-out through the boundary, worked.** The benchmark needs one `ref` face
feeding N summing junctions. In PathSim that is `Connection(ref, sm1[0],
sm2[0], …)`. The first Cadence attempt spelled it as repeated pairs:

```julia
inputs = ("ref" => "sum1/a",
          "ref" => "sum2/a")
```

and the build refused it:

```
FaceNameCollision: the root component: face name(s) ref appear twice — face
names are unique across `input_connections` and `output_connections` together (§8.6)
```

The refusal is principled. At the root a face is an address: one root input
places exactly one cell the periphery writes by that name (§11.3), one trace
column, one device claim. Two entries named `ref` are two declarations of that
address, and the build cannot tell "the same input, routed twice" from "two
inputs with a typo'd name". §8.6 spells fan-out as one face routed to a tuple
of endpoints:

```julia
inputs = ("ref" => ("sum1/a", "sum2/a"),)
```

which builds, seeds from one `fragment(inputs = (ref = 0.7,))`, and drives both
loops identically (`probes/fanout.jl`). So this is a spelling, not a capability
gap. It did expose a message-quality nit: the diagnostic said what was wrong
without pointing at the spelling wanted. The `:assembly` arm of
`FaceNameCollision` now carries that hint (`diagnostics.jl`, this report's
commit).

Two frictions remain real. There is no library, so every model brings its own
`Sum` and `Gain`. And initialization through `init!(sim, fragment(inputs = …))`
is composable but more ceremony than `Integrator(5)`. The compile latency
shapes the workflow: iterate on a model type in one session, not across
processes.

### Authoring components

PathSim: subclass `Block`, set `initial_value`, override `update`/`step`/
`solve`, set `__len__` to declare feedthrough, optionally hand-write
`to_statespace`. Each of those is a convention the framework cannot check;
forgetting `__len__` on a feedthrough block silently produces a one-evaluation
delay. Cadence: a plain struct plus a few methods on framework generics, no
macros, stages named by dependence class, bundles destructured by name. The
framework probes every function at build and checks returns against the
declaration. The discipline is real: immutable state in a closed leaf
vocabulary, `T`-generic math with no `Float64` pinning, the stage split, the
per-name `import` list, and the local-scope trap `implementation.md`
documents. The learning curve is steeper and the footguns are fewer.

## 4. Mathematical rigor

This is where the two diverge most. The claims that mattered were checked by
running them.

**Feedthrough and scheduling.** Cadence's schedule is sound by construction:
`output_state` cannot see `u`, so a stage-1 port cannot feed through, and any
`output_direct` conservatively depends on every input. PathSim's
`DynamicalSystem.__len__` evaluates ∂y/∂u numerically at the initial point.
`probes/feedthrough.py` builds `ẋ = 1, y = x·u` in the loop `u = 1 + y` (exact
`y = x/(1 − x)`). With `x₀ = 0` PathSim classified the block as
non-feedthrough, skipped its loop solver, and returned `y = 0.99369` at
`t = 0.5` where the exact value is 1.0, with no warning. With `x₀ = 0.1` it
detected the loop and was exact. Subsystems are also coarsened to a single
node whenever any interior path feeds through, so a partially-feedthrough
subsystem manufactures loops in its parent that then cost iterations.

**Events.** Cadence formalizes edge semantics, priors, the epoch rule and
budgets, and proves small things in prose: boundary detection is exact for
guards over `u` and `m`, `t* = tₙ` is structurally impossible, the
even-crossing blind spot is stated. Rounds iterate to quiescence, so a handler
that enables another guard fires it at the same boundary
(`test_events.jl`, "a cascade settles within one boundary"). PathSim computes
the detected list once per step. `probes/cascade.py` sets event A to fire at
t = 1 and flip a flag that jumps B's guard from −1 to +1. B never fired, in
fixed-step RK4 or adaptive DOPRI5, because the next step's `buffer` already
records the positive value and no sign change is ever seen. In fixed-step mode
PathSim also resolves an event *after* the full step against end-of-step
state; only the recorded timestamp is interpolated. Adaptive mode localizes by
rejecting and re-integrating the step with a secant ratio until
`|g| ≤ tolerance`, a tolerance on the guard value rather than on time. Cadence
localizes on the stepper's dense output with a bracketing method and never
re-integrates.

**Time.** PathSim accumulates `time += dt`; `run(10.0)` at dt = 1e-3 ended at
10.001, and `Schedule` widens its tolerance by `1e-10·|t|` to absorb drift.
Cadence indexes the grid (`tₖ = t₀ + k·h`), keeps periods as `Rational{Int}`,
and derives the base grid by GCD.

**Implicit solvers.** PathSim's implicit methods solve each block's stage
equation with a block-local Jacobian inside a global fixed-point iteration
over blocks: a nonlinear block-Gauss-Seidel accelerated by Anderson. Stiff
coupling *across* blocks gets no global Newton, and non-convergence is a
`RuntimeError`. Cadence has no implicit method; §10.2 argues the domain does
not need one and records the remedy ladder. That is a scoping choice rather
than a rigor gap, but a real capability gap.

**Jacobians.** Cadence's are exact through Dual activations, and the
pinned/walked leaf schema makes a frozen coupling schema-visible (§9.5).
PathSim's are central differences with a fixed relative step, O(h²) accurate,
unless the author supplies analytic ones.

**Determinism and state.** Cadence: immutable values, one home per datum, RNG
in `s`, bit-exact replay. PathSim: mutable numpy arrays held by reference
(`engine.set(x)` stores the caller's array), the `RNG` block on global
`np.random`, no input trace.

## 5. Code quality

**PathSim** (25.5k source lines, 27k test lines in 122 files, codecov CI).
Consistent layout, numpy-style docstrings on nearly everything, iterative
graph algorithms with SCC decomposition, `__slots__` and cached index arrays
on the hot path, a two-tier test philosophy (unit tests plus eval tests
against reference solutions), a deprecation mechanism, versioned checkpoints.
Weaknesses found while reading: `Simulation` is a 2263-line class;
`Subsystem` re-implements `_loops`, `step` and `solve` from it;
`error_controller` is duplicated between the explicit and DIRK bases, down to
a doubled comment; five docstrings describe "automatic differentiation via the
Value class", which does not exist in the tree; 23 `@deprecated` shims;
`Register.__getitem__` returns 0.0 for a missing key instead of raising;
dynamic attributes appear via `hasattr(self, '_Solver')`; a mutable default
argument (`coeffs=[1.0]`); `@mutable` re-runs `__init__` by introspection;
almost no type hints. The numerical feedthrough heuristic and the accumulated
clock are design-level weaknesses in otherwise clean code.

**Cadence** (12.4k source lines, 11k test lines, 1803 tests). Its
distinguishing property is traceability. Every file header and most testset
names cite the spec section they answer to; the decision log records rejected
alternatives; `pending.md` is a transactional deviation register;
`check_refs.jl`, `check_rows.jl` and `linkify.jl` keep the documents
consistent. Invariants other frameworks state as goals are tests here: zero
allocation per phase body, type stability, a Dual sweep,
tolerance-not-equality correctness. The executor's representation was chosen
by measurement (`prototypes/cellstore_bench`). Weaknesses: v0.1 exporting
nothing, no CI workflow in the repository, no docs site, no library, heavy
specialization that costs seconds of compile per model type, large files
(`build.jl` 1.5k lines, `sim.jl` and `diagnostics.jl` 1.6k), comment density
that assumes the reader has the spec open, Julia ≥ 1.12 only, and the payload
gaps `pending.md` itemizes for several diagnostic kinds. It is a single-author
project.

## Bottom line

PathSim is the broader tool today: more solvers, loop solving, DAEs, a
library, a GUI, plotting, checkpoints, and a millisecond edit-run loop. It buys
that breadth with heuristic feedthrough detection, a one-pass event model,
accumulated time, untyped scalar ports, and a ~14 µs per-block-step floor that
rules out real-time operation on anything but small models.

Cadence is narrower by design and far more rigorous inside its boundary:
structural scheduling, formal event semantics, typed signals, exact Jacobians,
deterministic replay, and a 50 ns per-component-step floor. Its costs are
compile latency, the authoring discipline, and the parts still unbuilt.

Two things PathSim does that Cadence could adopt through existing seams
without touching the execution model: an adaptive stepper as a package
extension (`extensions.md` item 1), and a checkpoint that serializes the trace
header plus stores to disk (the §16 persistence question). Two things Cadence
does that PathSim could not adopt without redesign: structural feedthrough and
quiescence iteration, both of which its `Register`/`__len__`/single-pass
architecture precludes.

## Reproduction

- `probes/bench_pathsim.py`, `probes/bench_cadence.jl`: the table in §2.
  PathSim ran in a venv with `pip install pathsim` (0.25.1). The Julia script
  loads `test/repl.jl` and runs with `julia --project=test`.
- `probes/cascade.py`: the missed cascade.
- `probes/feedthrough.py`: the numerical feedthrough misclassification.
- `probes/fanout.jl`: both fan-out spellings.
- `probes/compile_cost.jl`: compile cost of a second model type in the same
  session versus a fresh process, behind the non-monotonicity remark in §2.
