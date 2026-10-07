# Brief: increment 65, the discrete tier

Three code stages, one cold review and a fixer if the review needs one.
The docs arc is landed in 1036476 and 5784f1a: `linear_blocks.md` section 9,
`pid_anti_windup.md` section 9, the inventory's rows under "Sources",
"Discrete tier" and "Controllers", and `pending.md`'s increment 65 bullet.
The tip at launch is the commit adding this brief; line numbers below are
5784f1a's. Find passages in `docs/design/implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **Nine blocks, all discrete leaves.** `s_init` is the store, `Δt` is in
  every bundle, the declarations pin wholesale (D-263), and none walks under
  `Dual`: under a `Dual` activation a discrete block holds its last value
  (§9.4). No `Pinned` marker anywhere on this tier, and no mode store. None
  earns a log entry: D-313 admits by judgement, and the PID and the linear
  blocks set the precedent.
- **`Δt` is the component's own period** from the tick table (§10.5), not
  `Δt_base`, so every constant below is per second and survives a
  `sample_times` change. The probe confirmed it: a `DiscreteIntegrator`
  under `Relative(2)` reads `0.1` at `t = 0.1`, the same as at `Relative(1)`.
- **The stage rule is the loop checker's evidence here too.** `y_state`
  reads `s` alone and breaks a loop; `y_direct` reads `u` and is
  feedthrough. A discrete member traces structurally (§5.6), so a cycle
  through a discrete stage-2 block is classified `:real` with no dead hop,
  where the continuous PID's clamp loop is `:artificial` with the hop named.
- **The initial value's name is `s0`** on this tier. `UnitDelay(v0)` stays
  as it is and is noted for the export audit.
- **The discrete linear tree.** One abstract `DiscreteLinearBlock{FT}`
  with two accessors: `held(c)`, the stored system whose shapes and `x0` do
  not depend on the period, and `realization(c, Δt)`, the discrete update
  matrices. The declarations and both output arms read `held(c)`; only
  `s_update` discretizes. `realization` is the existing one-argument
  function of the submodule gaining a two-argument method. The pure-`z`
  blocks return their field from both. The hold blocks store the continuous
  `StateSpace` and compute `A_d`, `B_d` per tick from one static
  exponential of the augmented matrix, assembled with `vcat` and `hcat`.
  The bracket spelling `[A B; 0 0]` goes through a static `hvcat` that
  allocated 1,088 B at 1×1 and 1,920 B at 2×2 per call in the probe, and
  showed up as 1,248 to 4,560 B per tick; the concatenations, `exp` and the
  static slices allocate nothing. Tustin is not built; the companion's
  section 9.2 says why, and the docstring carries the caveat.
- **The discrete PID** is the continuous law with `s = (q, yf)`, forward
  Euler on `q`, backward Euler on the filter (`τd + Δt` in the divisor, so
  `τd = 0` is the backward difference and every period is stable), and the
  correction's exact step `β = -expm1(-Δt / Tt)`, zero at `Tt = Inf` and
  one at `Tt = 0`, applied to the correction alone. The gate, the reference
  rule, the four `u_types` arms and `y_types` move to an abstract
  `PIDBlock{Hold, Track} <: AbstractComponent`; `PID` reparents to it and
  its seven fields repeat in `DiscretePID`.
- **The noise is counter-based.** `s = (k = UInt64(0),)`, no workspace. The
  `k`-th sample is `gaussian(seed, k)`: SplitMix64's output function on the
  state after `k + 1` advances, `seed + (k + 1) · 0x9e3779b97f4a7c15`
  through the `xorshift`-multiply finalizer, then Box–Muller over two
  consecutive words `2k` and `2k + 1`, with `u1 = 1 - (w >> 11) · 2⁻⁵³` so
  the logarithm never sees zero. `gaussian(0, 0)` is `0xe220a8397b1dcdaf`,
  the first output of a SplitMix64 seeded with zero, which pins the
  identity with the reference generator. One million draws at seed 42:
  mean `-2.2e-4`, variance `1.0010`, lag-one autocorrelation `1.2e-3`,
  kurtosis `2.998`, largest magnitude `5.0`. The stage draws, in `y_state`,
  because it is a pure function of `s`; `s_update` increments `k`.
- **Names.** Grepped across `src/` and `test/`: `DiscreteLimitedIntegrator`,
  `RateLimiter`, `DiscreteLinearBlock`, `DiscreteStateSpace`,
  `DiscreteTransferFunction`, `DiscretizedStateSpace`,
  `DiscretizedTransferFunction`, `PIDBlock`, `DiscretePID`,
  `GaussianWhiteNoise`, `held`, `saturation_code`, `splitmix` and `gaussian`
  are free (`held` is a local variable in three source files, never a
  function). `DiscreteIntegrator` was a test fixture; its rename to
  `DiscreteAccumulator` landed beside this brief, so the name is free too.
- **Every number below was probed at 5784f1a's tree** with the shapes
  above, sampling by `step!` at `h = 1//100` unless said. Confirm each in a
  probe before writing an assertion, and report the probe's numbers.

## Out of scope

- `Delay{V, K}`, a Tustin method, a gain or limits on `DiscreteIntegrator`,
  per-component rates on `RateLimiter`, setpoint weighting or any other
  variant of `pid_anti_windup.md` section 6, a `Ts` field or check on the
  pure-`z` blocks, a stdlib-generator noise source.
- A `show` method, an export, any spec or log edit, and any companion edit
  beyond the inventory statuses named in the bookkeeping.

## Reading, in order

- `docs/design/pending.md`, the increment 65 bullet, lines 20 to 34.
- `docs/design/companions/library_inventory.md` sections 2 to 4;
  `docs/design/companions/linear_blocks.md` section 9 whole, then sections
  3, 4 and 6 for the continuous pattern it mirrors;
  `docs/design/companions/pid_anti_windup.md` section 9 whole, then section
  4 for the law.
- `docs/design/spec.md` §5.2, lines 678 to 825, the discrete signatures and
  the bundle law; §5.3, lines 826 to 1037, the two rules under "Stage
  roles"; §5.4, lines 1038 to 1107; §5.5, lines 1108 to 1127; §5.6, lines
  1128 to 1215, the paragraph on structural tracing of discrete members;
  §7.3, lines 1695 to 1843; §7.5, lines 1894 to 1976; §8.7, lines 3447 to
  3492; §9.3, lines 4217 to 4359, the probe's placeholder `Δt`; §10.5,
  lines 5550 to 5885; §13.7, lines 9735 to 9963. Never read the spec
  whole.
- `docs/design/decisions.md` D-231, D-263, D-312 with its annotation, and
  D-313.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/blocks.jl`, `### test/fixtures.jl`
  and `### test/imports.jl`; "Authoring caveats", its first three bullets;
  "Naming"; "Running the suite". Never restate either in a commit or a
  comment.
- `src/blocks.jl` whole, 684 lines. `UnitDelay` (lines 89 to 106) is the
  discrete leaf to copy, the linear blocks section (lines 169 to 330) the
  tree stage 2 mirrors, `LimitedIntegrator` (lines 375 to 517) the interface
  stage 1's limited block copies and `PID` (lines 553 to 632) the block
  stage 3 reparents. The section comments at lines 14, 69, 124, 169, 331,
  373, 553 and 633 give the file's order.
- `test/test_blocks.jl` whole, 998 lines: the models at top level (lines 1
  to 237), the delay testset (line 274) for driving a discrete block by
  `step!` and reading `port`, the linear testsets (lines 357 to 500) stage 2
  mirrors, the PID testsets (lines 730 to 913) stage 3 mirrors, the keyword
  testset (line 915), the loops' allocation testset (line 939), the
  shadowing testset (line 963). `test/fixtures.jl` lines 178 to 204, the
  fixtures `DiscreteAccumulator` and `TickCounter`. `test/utils.jl` lines 1
  to 30, `single` and `fed`.

## Stage 1: `DiscreteIntegrator`, `DiscreteLimitedIntegrator`, `RateLimiter`

### The shape

A new section `# --- the discrete tier (§7.3, §10.5, D-313) ---` after the
leaf blocks and before the continuous dynamics, holding the three blocks in
that order. Each over `V <: Union{Real, StaticArray{<:Tuple, <:Real}}` as
`Integrator` is, each with a keyword constructor promoting integers to
`Float64`.

```julia
struct DiscreteIntegrator{V} <: AbstractComponent
    s0::V
end
DiscreteIntegrator(; s0 = 0.0) = DiscreteIntegrator(float(s0))
s_init(c::DiscreteIntegrator) = (q = c.s0,)
u_types(::DiscreteIntegrator{V}) where {V} = (in = V,)
y_types(::DiscreteIntegrator{V}) where {V} = (out = V,)
y_state(::DiscreteIntegrator, (; s)) = (out = s.q,)
s_update(::DiscreteIntegrator, (; s, u, Δt)) = (q = s.q + Δt * u.in,)
```

`DiscreteLimitedIntegrator` adds `lower` and `upper`, `s0 = zero(lower)`,
the three promoted together; `y_types` adds `saturation = Int8` for a
`Real` and `similar_type(V, Int8)` for a static vector, as
`LimitedIntegrator` does; `y_state` publishes `out = s.q` and the code off
the state through a helper `saturation_code(q, lower, upper)`, `1` where
`q >= upper`, `-1` where `q <= lower`, `0` otherwise, broadcast over a
vector; `s_update` is `(q = clamp.(s.q + Δt * u.in, c.lower, c.upper),)`.
The docstring says in one sentence that the continuous block's mode and
four events are this one `clamp`, and in another that at a limit with the
input already pointing inward the code reads saturated until the next tick
moves the state off.

`RateLimiter` holds `rising::Float64`, `falling::Float64` and `s0::V`, with
`RateLimiter(; rising, falling = rising, s0 = 0.0)`; `s_init` is
`(v = c.s0,)`; `y_direct(c, (; s, u, Δt))` publishes `out = s.v +
clamp.(u.in - s.v, -c.falling * Δt, c.rising * Δt)` and `s_update(c, (; y))
= (v = y.out,)`, the one block whose update reads `y` rather than
recomputing. The docstring names both rates, says the block is feedthrough
and why the lagged form is a different block, and says that `s0` is the
previous output at the first tick, so the output at `t₀` is already one
slew step from it.

Probed values:

- `fed_by(src, c) = Group((; k = src, c = c); local_wires = ("k/out" =>
  "c/in",))`, a model helper for the stage. `fed_by(Constant(1.0),
  DiscreteIntegrator())`: `out == 0.0` at `t₀`; `out ≈ 0.1` at `t = 0.1`
  (the probe's `0.09999999999999999`, ten additions of `0.01`; assert
  `atol = 1e-12`); the same with `sample_times = (c = Relative(2),)` reads
  `0.1`; `fed_by(Constant(SVector(1.0, -2.0)), DiscreteIntegrator(s0 =
  SVector(0.0, 1.0)))` reads `≈ SVector(0.1, 0.8)` at `t = 0.1`;
  `has_stage(y_direct, ·)` false and `has_stage(y_state, ·)` true;
  `typeof(DiscreteIntegrator(s0 = 1)) === DiscreteIntegrator{Float64}`.
- The discrete unit-feedback loop `Group((; r = Constant(1.0), e =
  Junction{Float64, Float64, 2}(-), i = DiscreteIntegrator()); local_wires =
  ("r/out" => "e/in1", "i/out" => "e/in2", "e/out" => "i/in"))` builds, and
  reads `out = 0.6339676587267709` at `t = 1`, which is `1 - 0.99¹⁰⁰`
  exactly (assert `≈` at `rtol = 1e-12` against that expression, not
  against `1 - e⁻¹`).
- `Group((; s = Step(t_step = 0.1, before = 1.0, after = -1.0), c =
  DiscreteLimitedIntegrator(lower = -0.03, upper = 0.05)); …)`, stepped one
  tick at a time: `out` reads `0.01, 0.02, 0.03, 0.04` with code `0`, then
  `0.05` with code `1` at ticks 5 to 10 (the step flips at `t = 0.1`, tick
  10, and the code still reads `1` there), then `0.04, 0.03, …` with code
  `0` from tick 11, reaching `≈ 0` at tick 15 (the probe's `-3.5e-18`) and
  `-0.01` at tick 16. Assert the exact `0.05` and the codes; the ramps `≈`
  at `atol = 1e-12`. `fed_by(Constant(SVector(1.0, -1.0)),
  DiscreteLimitedIntegrator(lower = SVector(-0.02, -0.02), upper =
  SVector(0.03, 0.03)))` at `t = 0.1`: `out == SVector(0.03, -0.02)`,
  `saturation === SVector{2, Int8}(1, -1)`; `y_types` of the vector block
  is `(out = SVector{2, Float64}, saturation = SVector{2, Int8})`;
  `has_stage(y_direct, ·)` false; the keyword forms
  `DiscreteLimitedIntegrator(lower = -1, upper = 1) isa
  DiscreteLimitedIntegrator{Float64}` and the `SVector(-1, -1)` pair `isa
  DiscreteLimitedIntegrator{SVector{2, Float64}}`.
- `Group((; s = Step(t_step = 0.1, before = 0.0, after = 1.0), c =
  RateLimiter(rising = 2.0, falling = 5.0)); …)`: `out == 0.02` at
  `t = 0.1`, `0.04` at `0.11`, `≈ 0.54` at `0.36`, `1.0` at `0.61`; the
  mirror with `before = 1.0, after = 0.0, s0 = 1.0` reads `0.95` at `0.1`,
  `≈ 0.45` at `0.2`, `0.0` at `0.3`; `fed_by(Constant(10.0),
  RateLimiter(rising = 2.0))` reads `0.02` at `t₀` and `0.04` after one
  tick, the start-up slew; `has_stage(y_direct, ·)` true and `y_state`
  false; the memoryless loop `Group((; r = Constant(1.0), e =
  Junction{Float64, Float64, 2}(-), c = RateLimiter(rising = 1.0));
  local_wires = ("r/out" => "e/in1", "c/out" => "e/in2", "e/out" =>
  "c/in"))` is refused, `DiagnosticError`, one `AlgebraicCycle`,
  `classification === :real`; the vector form over `SVector{2, Float64}`
  fed `SVector(1.0, -1.0)` reads `≈ SVector(0.22, -0.55)` at `t = 0.1`;
  `RateLimiter(rising = 1) isa RateLimiter{Float64}` and `RateLimiter(rising
  = 3).falling == 3.0`.
- Every model above builds under `(Float64, LinearizeDual)`, and the four
  phase bodies, `boundary!` and `offtick_boundary!` allocate nothing for
  the integrator's fed model, the loop, the limited step model and the
  limiter's step model.

### Tests

New testsets in `test/test_blocks.jl` after the delay's, models at top
level:

- "the discrete integrator accumulates `Δt in` per tick from `s0`, at its
  own period, and breaks a loop from stage 1 (§7.3, §10.5, §5.5, D-313)".
- "the discrete limited integrator clamps in one line and publishes its
  code off the state (§7.3, §13.7, D-313)".
- "the rate limiter follows its input within two slews per tick and is
  feedthrough (§7.3, §5.3, D-313)": the two step runs, the start-up slew,
  the refusal, the vector read.
- "the discrete tier's phase bodies allocate nothing (§7.5)" over
  `phase_bodies` with `boundary!` and `offtick_boundary!`, the idiom of
  line 939; stages 2 and 3 extend it.
- The keyword testset gains the four spellings above; the shadowing tuple
  gains `DiscreteIntegrator()`,
  `DiscreteLimitedIntegrator(lower = -1.0, upper = 1.0)`, its vector form
  and `RateLimiter(rising = 1.0)`.

### Routing

`src/blocks.jl` is the `blocks` row: run `blocks build` under the flags of
"Running the suite", in the foreground, 600 s per invocation.

### Bookkeeping, in the same commit

- `test/imports.jl` line 77: `DiscreteIntegrator`,
  `DiscreteLimitedIntegrator` and `RateLimiter` join the `import
  Redstone.Blocks:` line.
- `docs/design/implementation.md` `### src/blocks.jl`: a new bullet after
  the leaf blocks', "`DiscreteIntegrator`, `DiscreteLimitedIntegrator` with
  the helper `saturation_code`, and `RateLimiter` (D-313)". Constructs, not
  behaviour.
- `docs/design/companions/library_inventory.md`: the three rows' status
  becomes *shipped*. Linkified spelling; run the battery, `linkify` a
  no-op on rerun.

## Stage 2: the discrete linear tree

### The shape

A new section `# --- the discrete linear blocks (§13.7, §5.3, D-313) ---`
after the linear blocks and before the step. First the supertype with a
docstring saying what `FT` is, what the two accessors return and that only
the update discretizes, then the shared declarations and arms over
`held`/`realization`, then the four blocks in the order `DiscreteStateSpace`,
`DiscreteTransferFunction`, `DiscretizedStateSpace`,
`DiscretizedTransferFunction`.

```julia
abstract type DiscreteLinearBlock{FT} <: AbstractComponent end
s_init(c::DiscreteLinearBlock)  = (q = held(c).x0,)
u_types(c::DiscreteLinearBlock) = (in = port_type(size(held(c).B, 2)),)
y_types(c::DiscreteLinearBlock) = (out = port_type(size(held(c).C, 1)),)
function s_update(c::DiscreteLinearBlock, (; s, u, Δt))
    (; A, B) = realization(c, Δt)
    (q = A * s.q + B * as_vector(u.in),)
end
y_state(c::DiscreteLinearBlock{false}, (; s)) = (out = as_port(held(c).C * s.q),)
function y_direct(c::DiscreteLinearBlock{true}, (; s, u))
    (; C, D) = held(c)
    (out = as_port(C * s.q + D * as_vector(u.in)),)
end
```

- `DiscreteStateSpace{NX, NU, NY, FT, LA, LB, LC, LD}` has `StateSpace`'s
  five fields with their length parameters, its positional constructor
  setting `FT = !iszero(D)`, and a keyword constructor
  `DiscreteStateSpace(; A, B, C, D = zero, x0 = zero)` with `StateSpace`'s
  checks and messages, factored into one helper the two constructors share
  if that reads well. `held(c) = c`, `realization(c, _) = c`. The docstring
  says the period is the scope's and the block cannot check it.
- `DiscreteTransferFunction{N, FT, M, K, LA}` has `TransferFunction`'s
  three fields, the held block a `DiscreteStateSpace{N, 1, 1, FT, LA, N, N,
  1}`, built by `realize(num, den)` unchanged. Coefficients highest power
  of `z` first; the docstring says so and names the `z⁻¹` convention it is
  not. Refusals as `TransferFunction`'s, with the origin-pole test replaced
  by the `z = 1` test: with `u0 ≠ 0`, refuse when `|Σ den| ≤ 1e-12 · Σ |den|`
  after dividing by `den[1]`. Then `x0 = (I - A) \ (B u0)`, zero for
  `u0 = 0`. `held` and `realization` return the field.
- `DiscretizedStateSpace{NX, NU, NY, FT, LA, LB, LC, LD}` holds one field
  `continuous::StateSpace{…}` with the same parameters;
  `DiscretizedStateSpace(sys::StateSpace)` wraps and
  `DiscretizedStateSpace(; kwargs...)` forwards to `StateSpace(; kwargs...)`.
  `held(c) = c.continuous`; `realization(c, Δt)` concatenates `A`, `B` and
  two zero blocks with `vcat`/`hcat`, takes `exp(M * Δt)` and slices with
  `SOneTo` and `SUnitRange`, returning `(; A = A_d, B = B_d, C, D)`.
  `SOneTo` and `SUnitRange` join the StaticArrays import by name. The
  docstring states the hold, that the class and `x0` are the continuous
  ones, and the period caveat.
- `DiscretizedTransferFunction{N, FT, M, K, LA}` holds `num`, `den` and a
  `DiscretizedStateSpace{N, 1, 1, FT, LA, N, N, 1}`;
  `DiscretizedTransferFunction(; num, den, u0 = 0.0)` builds a
  `TransferFunction` with the same keywords and wraps its realization, so
  the refusals and the `u0` solve are the continuous block's; `held` is the
  continuous `StateSpace` inside and `realization` forwards. The docstring
  carries the Tustin caveat of the companion's section 9.2 in two
  sentences: the hold keeps the class and the step response at the
  samples, and a design wanting Tustin's frequency response discretizes
  externally into `DiscreteTransferFunction`.

Probed values:

- `DiscreteStateSpace(A = [0.5;;], B = [1.0;;], C = [1.0;;])` fed
  `Constant(1.0)`, five ticks: `out == 1.9375`, `2(1 - 0.5⁵)` exactly; type
  `DiscreteStateSpace{1, 1, 1, false, 1, 1, 1, 1}`; the loop of stage 1
  with the block in the integrator's place builds at `D = 0` and is refused
  at `D = 1`, `AlgebraicCycle` `:real`; the two-state block `A = [0.5 0.1; 0
  0.8], B = I, C = I` has `u_types == (in = SVector{2, Float64},)` and the
  same `out`, and fed `SVector(1.0, 1.0)` reads `≈ SVector(1.98, 2.44)`
  after three ticks.
- `DiscreteTransferFunction(num = (0.5,), den = (1, -0.5))` realizes to
  `A = 0.5, B = 1, C = 0.5, D = 0`, type `{1, false, 1, 2, 1}`; fed
  `Constant(1.0)`, five ticks: `out == 0.96875`; with `u0 = 2.0` its `x0`
  is `SVector(4.0)` and fed `Constant(2.0)` it reads `out == 2.0` at `t₀`
  and at `t = 1`; `num = (1, -0.9), den = (1, -0.5)` is `{1, true, 2, 2,
  1}`; `@test_throws ArgumentError` for `u0 = 1.0` over each of `den = (1,
  -1)`, `(1, -0.7, -0.3)` (sum `5.6e-17`) and `(1, -1.5, 0.5)`; `den = (1,
  -1)` with `u0 = 0` builds under `fed`; `has_stage(y_direct, strict)` and
  `has_stage(y_state, proper)` both false.
- `DiscretizedStateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;])` fed
  `Constant(1.0)`: `out ≈ 1 - e⁻¹` at `t = 1` (probe difference `2e-15`;
  assert `atol = 1e-12`), and the same under `sample_times = (c =
  Relative(2),)` (difference `2.3e-15`); with `x0 = 2.0`, `out ≈ 1 + e⁻¹`;
  `realization(c, 0.01)` gives `A_d ≈ e^{-0.01}` and `B_d ≈ 1 - e^{-0.01}`;
  the two-state block of `two_state_block()`'s matrices, wrapped, fed
  `SVector(1.0, -1.0)` and sampled at `t = 0.3`, matches the continuous
  `StateSpace` to `3e-10` (`[-0.33839127292948, -0.22559418195299]` against
  RK4's `[-0.33839127259466, -0.22559418172977]`; assert `atol = 1e-8`).
- `DiscretizedTransferFunction(num = (1,), den = (0.5, 1))` beside
  `FirstOrderLag(τ = 0.5)` from one `Constant(1.0)`, `t = 1`: the hold
  reads `0.8646647167633915`, which is `1 - e⁻²` to `4e-15` (assert `atol =
  1e-12`), and the RK4 lag `0.8646647163964265`, agreeing to `4e-10`
  (assert `atol = 1e-8`); under `sample_times = (d = Relative(5),)` the hold
  still reads `1 - e⁻²` to `1e-15`; with `u0 = 3.0` fed `Constant(3.0)`,
  `out == 3.0` at `t₀` and `≈ 3.0` at `t = 1` (probe `3.0000000000000115`);
  the second-order `(4,), (1, 1.2, 4)` beside the continuous
  `TransferFunction` at `t = 1`: `1.0186307301606967` against
  `1.0186307301131525`, assert `atol = 1e-9`; types `{1, false, 1, 2, 1}`
  for the lag and `{1, true, 2, 2, 1}` for `(1, 2), (1, 5)`; the lag in the
  stage 1 memoryless loop builds and the lead-lag is refused `:real`;
  `has_stage(y_direct, lag)` and `has_stage(y_state, lead-lag)` both false;
  `den = (1, 0), u0 = 1.0` throws `ArgumentError`.
- Every model builds under `(Float64, LinearizeDual)`; the fed scalar and
  two-state hold models, the lag pair and the second-order pair allocate
  nothing in the four phase bodies and the two boundaries. The bracket
  spelling is the mutant: `ticks` allocates 1,248 B for the scalar hold,
  2,144 B for the two-state, 1,376 B for the lag pair and 4,560 B for the
  second-order pair.

### Tests

- "the pair in `z` mirrors the continuous pair over `DiscreteLinearBlock`,
  with `D` picking the stage (§13.7, §5.3, D-313)".
- "the discrete transfer function realizes in `z`, starts at `G(1) u0` and
  refuses a pole at `z = 1` with `u0` by tolerance (§13.7, D-313)".
- "the zero-order hold reproduces the exact solution at every period and
  keeps the class (§10.5, §13.7, D-313)": the scalar and `Relative(2)`
  reads, `x0`, the two-state match, the lag pair and `Relative(5)`, `u0`,
  the second-order pair, the loop pair, the `has_stage` pair, the refusal.
- The keyword testset gains one integer spelling per block; the shadowing
  tuple gains one instance per block, the hold blocks in both classes; the
  stage 1 allocation testset gains the models named above.

### Routing

`blocks build`, as in stage 1.

### Bookkeeping, in the same commit

- `test/imports.jl`: the four names join the line.
- `docs/design/implementation.md` `### src/blocks.jl`: a new bullet after
  the linear blocks', "`DiscreteLinearBlock{FT}` with the accessors `held`
  and `realization(c, Δt)`, over `DiscreteStateSpace`,
  `DiscreteTransferFunction`, `DiscretizedStateSpace` and
  `DiscretizedTransferFunction` (D-313)".
- `docs/design/companions/library_inventory.md`: the two rows' status
  becomes *shipped*.

## Stage 3: `DiscretePID` and `GaussianWhiteNoise`

### The shape

In the controller section, `abstract type PIDBlock{Hold, Track} <:
AbstractComponent end` goes first with a two-sentence docstring, the four
`u_types` arms, `y_types`, `gated_error` and `correction_reference` move
onto it, `PID{Hold, Track} <: PIDBlock{Hold, Track}` keeps its struct,
constructor, `x_init`, `y_direct` and `x_deriv` unchanged, and
`DiscretePID{Hold, Track} <: PIDBlock{Hold, Track}` follows `PID` with the
same seven fields, the same keyword constructor and defaults, and

```julia
s_init(::DiscretePID) = (q = 0.0, yf = 0.0)
function y_direct(c::DiscretePID, (; s, u, Δt))
    d = (u.y - s.yf) / (c.τd + Δt)
    u_raw = c.Kp * (u.r - u.y) + s.q - c.Kd * d
    (u = clamp(u_raw, c.u_min, c.u_max), u_raw = u_raw)
end
function s_update(c::DiscretePID, (; s, u, y, Δt))
    β = -expm1(-Δt / c.Tt)
    (q  = s.q + Δt * c.Ki * gated_error(c, u.r - u.y, u) + β * (correction_reference(c, u, y) - y.u_raw),
     yf = s.yf + Δt * (u.y - s.yf) / (c.τd + Δt))
end
```

The docstring is `PID`'s table and prose adapted: the two store fields, the
backward Euler filter with `τd = 0` legal, `β` with `Tt = 0` legal and what
it means, and the structural `:real` classification of the clamp loop. The
`PID` docstring gains no text; a site comment at `PIDBlock` says the nine
shared methods live there.

`GaussianWhiteNoise{V <: Union{Float64, SVector{<:Any, Float64}}}` gets a
section `# --- the noise source (§7.3, §2.2, D-231, D-313) ---` after the
discrete tier section of stage 1. Fields `seed::UInt64`, `μ::V`, `σ::V`,
`density::Bool`; the constructor `GaussianWhiteNoise(; seed, μ = 0.0, σ =
nothing, psd = nothing)` requires `seed`, takes exactly one of `σ` and
`psd` (an `ArgumentError` otherwise, one sentence), stores `sqrt.(psd)` in
`σ` with `density = true` when `psd` is given, and promotes `μ` and the
scale together. `s_init` is `(k = UInt64(0),)`; `y_types` is `(out = V,)`;
`y_state(c, (; s, Δt))` publishes `μ .+ scale .* gaussian(c.seed, s.k, V)`
with `scale = c.density ? c.σ ./ sqrt(Δt) : c.σ`; `s_update` increments
`k`. Helpers of the submodule: `splitmix(seed, k)` as in "What is
settled", `gaussian(seed, k)` by Box–Muller over words `2k` and `2k + 1`
with `cospi`, and `gaussian(seed, k, ::Type{SVector{N, Float64}})` over
sub-counters `k·N + i - 1` through `ntuple` with `Val(N)`. The docstring
names the process, says the sample is a pure function of the seed and the
tick count so the stage draws and replay reproduces the stream, that two
blocks differ by seed, and states the density frame in one sentence: `psd`
is the two-sided intensity `Q` with `σ² = Q/Δt`, and a one-sided density is
halved before being passed.

Probed values:

- The law by direct call, `s = (q = 0.3, yf = 0.1)`, `y = (u = 1.0, u_raw =
  2.0)`, `Δt = 0.01`, the six input rows of the continuous law testset at
  `pid_controller`'s gains: `u_raw = 2.0727272727272723` and `u = 1.0` in
  every row; `yf⁺ = 0.13636363636363635` in every row; `q⁺` is
  `0.30254983374916805` for the plain, the `-1` code, the `0` code and the
  hold-with-tracking at code `0`, `0.29004983374916804` for the gated `+1`
  code, `0.2995647838739185` for ungated tracking and `0.2870647838739185`
  for hold-with-tracking at code `1`. Assert `atol = 1e-12`. `β` is
  `0.009950166250831947` at `Tt = 1`, exactly `0.0` at `Tt = Inf` and
  exactly `1.0` at `Tt = 0`. With `τd = 0`, `Kp = 1`, `Kd = 0.2`, `s = (q =
  0.0, yf = 0.4)`, `u = (r = 0.0, y = 0.5)`: `u_raw == -2.5`, the backward
  difference `10` times `Kd`.
- Loops through `loop_samples` at `h = 1//100`, peak of the plant output and
  the first sample after which it stays within `0.05` of `5`, the continuous
  figures beside: the single loop with `DiscretePID` at `pid_controller`'s
  gains, `Tt = 1`: peak `5.329`, settled `11.3 s` (continuous `5.327`,
  `11.3 s`); at `Tt = Inf`: `8.194`, `18.7 s`; at `Tt = 0`: `5.229`,
  `11.4 s`; at `τd = 0`: `5.331`, `11.2 s`; the servo loop tracking:
  `5.935`, `23.6 s`; the cascade with hold and tracking at `Kp = 0.5, Ki =
  0.1, Tt = 2`: `5.202`, `27.0 s` (continuous `5.202`, `26.9 s`). Assert
  peaks at `atol = 0.005` and settling times exactly, as the continuous
  testsets do.
- The all-discrete loop, `pid_single_loop`'s shape with
  `DiscreteIntegrator()` as the plant, builds and reads
  `5.329`, `11.3 s`. The hold from a `DiscreteLimitedIntegrator(lower =
  -1.0, upper = 1.0)` between the controller and a discrete integrator
  plant, its `saturation` wired to the controller, builds.
- `pid_clamp_loop`'s shape with `DiscretePID(Kp = 1.0, Ki = 0.5, Kd = 0.2,
  Tt = 1.0, tracking = true)` is refused: `DiagnosticError`, one
  `AlgebraicCycle`, `classification === :real`, `dead` empty.
- `u_types` of `DiscretePID(Kp = 1.0, hold = true, tracking = true)` is
  `(r, y, saturation = Int8, v)`, `y_types` is `(u, u_raw)`; `DiscretePID(Kp
  = 1) isa DiscretePID{false, false}` with every field a `Float64`; `PID` is
  a `PIDBlock` and the continuous PID testsets are untouched and green.
- Builds under `(Float64, LinearizeDual)`: the single loop and the cascade.
  Zero allocation in the bodies and boundaries for both.
- `single(GaussianWhiteNoise(seed = 42, σ = 1.0))`: `out` at `t₀` equals
  `gaussian(42, 0)`, `0.882248906222269`; after `k` ticks `out ==
  gaussian(42, k)` for every `k` to 1000, and `s.k == 1000`; the thousand
  samples have mean `0.0015` and standard deviation `1.0017` (assert `|mean|
  < 0.1` and `std` within `0.9` to `1.1`); a second simulation at seed 42
  reads the same value after ten ticks and seed 43 a different one;
  `single(GaussianWhiteNoise(seed = 7, μ = SVector(1.0, -1.0), σ =
  SVector(1.0, 2.0)))` reads `SVector(1.9884743323187353,
  -4.728511613462453)` at `t₀` with `y_types == (out = SVector{2,
  Float64},)`; `psd = 4.0` over 20,000 ticks has standard deviation
  `19.79` against `20` and under `Relative(2)` `14.05` against `14.14`
  (assert within 3 %); `GaussianWhiteNoise(seed = 1)` and the form with
  both `σ` and `psd` throw `ArgumentError`; `splitmix(0, 0) ==
  0xe220a8397b1dcdaf`; one million `gaussian(42, k)` have mean within
  `0.005` of zero, variance within `0.01` of one and kurtosis within `0.05`
  of three. Both noise models allocate nothing in the bodies and
  boundaries; `Group((; n = GaussianWhiteNoise(seed = 1, σ = 1.0), i =
  Integrator()); …)` builds under `(Float64, LinearizeDual)`.

### Tests

- "the discrete PID's law is the continuous one over `s`, with the backward
  filter and the exact correction step (§13.7, D-313)".
- "the discrete PID's loops match the continuous block's, and `Tt = 0` and
  `τd = 0` are legal (§13.7, D-313)".
- "a tracking input wired from a clamp of the discrete PID's own output is a
  real cycle, traced structurally (§5.4, §5.6)".
- "the Gaussian white noise is a pure function of its seed and tick, with
  the moments it claims (§7.3, §2.2, D-231, D-313)".
- "the noise's density form scales by the period (§7.3, §10.5)".
- The keyword testset gains `DiscretePID(Kp = 1)` and the two
  `ArgumentError`s; the shadowing tuple gains the four `DiscretePID`
  spellings and the two noise instances; the stage 1 allocation testset
  gains the single loop, the cascade and the two noise models.

### Routing

`blocks build`, as in stage 1.

### Bookkeeping, in the same commit

- `test/imports.jl`: `DiscretePID` and `GaussianWhiteNoise` join the line.
- `docs/design/implementation.md` `### src/blocks.jl`: the PID bullet
  becomes "`PIDBlock{Hold, Track}`, carrying the ports, `gated_error` and
  `correction_reference`, over `PID` and `DiscretePID` (D-313)", and a new
  bullet "`GaussianWhiteNoise`, with the helpers `splitmix` and `gaussian`
  (D-231, D-313)".
- `docs/design/companions/library_inventory.md`: the `DiscretePID` and
  `GaussianWhiteNoise` rows' status becomes *shipped*.
- `docs/design/pending.md`: the increment 65 sub-bullet is removed. If the
  increment 66 sub-bullet is already gone, the parent bullet goes too;
  otherwise the parent reads "one remaining tranche". `check_refs.jl` and
  `check_rows.jl` read this file; run the battery.

## The cold review

One fresh Opus reviewer over the three code commits: open-mind stance,
probe scripts under `/tmp`, "empty is acceptable". Dimensions:

- **Each block against its sketch here and the companions**: the stage of
  each by `has_stage` on an instance (`DiscreteIntegrator`, its limited
  form, the strict linear blocks and the noise declare `y_state` alone;
  `RateLimiter`, `DiscretePID` and the proper linear blocks `y_direct`
  alone); every declaration and arm of the linear tree on the supertype
  and none on a concrete block; the nine shared PID methods on `PIDBlock`
  and none duplicated; `vcat`/`hcat` in the hold; the `expm1` spelling;
  the `τd + Δt` divisor in both the output and the update; the mixer's
  constants.
- **The submodule's imports.** `src/blocks.jl` reaches the parent through
  its import list alone; `SOneTo` and `SUnitRange` are the StaticArrays
  names stage 2 adds, by name, and nothing else is new.
- **Mutants on a scratch copy**, each named test going red: the bracket
  spelling in the hold (the allocation testset); `held(c).C` replaced by
  `realization(c, Δt).C` in `y_state` is a legal variant and not a mutant;
  `Δt/Tt` for `β` with `Tt = 0` (the `Tt = 0` loop, `Inf`); `τd` alone in
  the filter's divisor (the `τd = 0` direct call, division by zero);
  forward Euler on the filter (the `yf⁺` values); the gate dropped (the
  gated `q⁺`); the fallback to `u` dropped at code `0` (the hold-with-
  tracking rows); `clamp` dropped from the limited integrator (the exact
  `0.05`); the code read off the input's sign instead of the state (tick
  10's code `1`); `falling` used for the rising bound (the `0.02` ramp);
  `s_update` recomputing `out` with a sign error instead of reading `y`
  (the `0.04` second tick); `(k + 1)` replaced by `k` in `splitmix` (the
  `0xe220a8397b1dcdaf` identity); `u1` without the `1 -` (a `log(0)`
  somewhere in a million draws is not guaranteed, so this one is checked by
  reading the code); the `z = 1` tolerance replaced by an exact test (the
  `(1, -0.7, -0.3)` refusal); `(I - A)` replaced by `A` in the `z` solve
  (the `u0 = 2` read); the `psd` scale without the `sqrt(Δt)` (the
  `Relative(2)` standard deviation). A surviving mutant is a missing test.
- **The numbers.** Re-probe every asserted value against this brief and the
  companions' section 9s.
- **`Dual`.** Every new model builds under `(Float64, LinearizeDual)`; the
  tier pins, so the check is that nothing on this tier is marked `Pinned`
  (`DeclarationOnWrongTier` would say so at build).
- **The register, the inventory and the companions.** `implementation.md`'s
  rows name constructs; behaviour is in docstrings; the docstrings and the
  two section 9s agree, the period caveat, the Tustin caveat, the `Tt = 0`
  meaning and the density frame above all.
- "Naming" over every touched file, the docs battery, and the gate once on
  the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new name across `test/`
before defining it. Models and helpers live at top level. Report: the
commit hash, the files touched, the routed subset's result with the
assertion count, the probe's numbers for every asserted value, and every
deviation from this brief with its reason.
