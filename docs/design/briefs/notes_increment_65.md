# Notes: increment 65, the unattended run of 2026-10-08

The coordinator's rulings while the user was away, each with its reason, and
the open points left for the user. Nothing here is pushed.

## The arc

| commit | what |
| --- | --- |
| 73024cf | stage 1: `DiscreteIntegrator`, `DiscreteLimitedIntegrator`, `RateLimiter` |
| c34fae2 | stage 2: `DiscreteLinearBlock` over the four discrete linear blocks |
| 4d061fe | stage 3: `PIDBlock`, `DiscretePID`, `GaussianWhiteNoise`; `pending.md` bullet retired |
| e1e5fb4 | the review fixes (rulings 17 to 24) |
| 825ec9a | the two companion corrections (ruling 25) |
| 6751c25 | two docstring nits from the delta verification (ruling 26) |

Routed subsets green at every stage; the cold reviewer's gate green at
4d061fe (5258), the fixer's at e1e5fb4 (5265, Dual sweep 98 covered, 61
skipped, 75 refused); `blocks build` green at 6751c25 (1325); docs battery
green after every docs edit. The reviewer verified the delta 4d061fe..825ec9a:
every finding closed, both surviving mutants red, the constructor's new
admissions probed, naming clean.

**What is left for you:** the diff review of the arc (a730017..6751c25) and
the push. The open points are at the end.

## Rulings made

### Stage 1 (73024cf)

1. **The test loops reuse `feedback_loop(plant)`** instead of the brief's
   inline `Group`. It builds the same model with the block named `p` rather
   than `i`. Reason: the helper already existed, and a second copy of the
   same loop is the kind of duplicate the reviewer would flag.
2. **`fed_by` gained a `sample_times = (;)` keyword.** Reason: the brief's
   `Relative(2)` read needs a rate scope on the fed model, and stage 2 needs
   the same keyword twice more.
3. **The step models are two top-level helpers**, `discrete_limited_model()`
   and `limiter_model(before, after)`, built over `fed_by` with the `Step` in
   slot `k`, not `s`. Reason: same model, one less inline `Group`.
4. **`RateLimiter`'s keyword constructor names the parameter**,
   `RateLimiter{typeof(s0)}(rising, falling, s0)`, as `FirstOrderLag` does.
   Reason: the brief's positional form does not convert integer rates to
   `Float64`, since the default constructor of a parametric struct takes
   exact field types.
5. **`fed_by(Constant(v), c)` duplicated `linear_model(block, v)`.**
   Resolved after the run with the user: `linear_model` is retired and its
   five call sites read `fed_by(Constant(v), block)`, which builds the same
   model. The gate stayed at 5265.

### Stage 2 (c34fae2)

6. **`StateSpace`'s checks moved into a shared helper `static_system(A, B, C,
   D, x0)`**, which both `StateSpace(; …)` and `DiscreteStateSpace(; …)`
   forward to. Reason: the brief allowed the factoring "if that reads well",
   and the messages are unchanged. The register bullet does not name the
   helper; see the open points.
7. **`DiscreteTransferFunction` repeats `TransferFunction`'s three common
   refusals** (order zero, improper, leading zero) instead of sharing them.
   Reason: the brief permitted a shared helper only for the state-space
   checks. A helper over both transfer functions is a possible later
   cleanup, not applied.
8. **The generated outer constructors stand in for the positional ones** on
   `DiscretizedStateSpace(sys)`, `DiscretizedTransferFunction(num, den,
   hold)` and `DiscreteTransferFunction`. Reason: they infer every parameter
   and nothing in the brief needs an explicit form.
9. **The two-state block in the tests spells `B = [1 0; 0 1]`** where the
   brief wrote `B = I`. Reason: the keyword constructor takes an
   `AbstractMatrix`.
10. **The bracket mutant's byte counts differ from the brief's** (1,376 B
    against 1,248 B for the scalar hold, 4,720 B against 4,560 B for the
    second-order pair) and were not chased. Reason: no assertion depends on
    the count, only on zero against nonzero, and the mutant's exact spelling
    of the zero blocks explains the gap.

### Stage 3 (4d061fe)

11. **`GaussianWhiteNoise`'s store reads 1001 after 1000 ticks**, not the
    brief's 1000, and the test asserts 1001 with a comment. Reason: the `t₀`
    boundary runs the first tick, so after `init!` the store already holds
    the next sample's index. The brief's count was off by one; the law
    (`out` at tick `k` is `gaussian(seed, k)`) is unchanged.
12. **`μ` defaults to zero of the scale** (fixer, pending the review). As
    built, `GaussianWhiteNoise(seed = 1, σ = SVector(1.0, 2.0))` throws since
    `0.0` does not promote with a vector. Reason: a zero-mean vector noise is
    the common case and must not need `μ`; the docstring's signature changes
    to `μ = nothing` resolved as `zero(scale)`.
13. **`PIDBlock` carries ten shared methods, not nine** (four `u_types`, one
    `y_types`, two `gated_error`, three `correction_reference`).
    `pid_anti_windup.md` section 9 says nine twice. The site comment lists
    them by kind without a count. The companion gets a one-word docs fix
    after the review, landed by the coordinator.
14. **The servo loop's figures are asserted with `pid_controller`'s ±1
    limits** in place, as the brief's numbers imply (without them the peak is
    5.962 and settling 22.8 s). Reason: the brief's probe was run with them.
15. **Two PID test helpers gained optional arguments** with unchanged
    defaults, `pid_single_loop(controller; plant = Integrator())` and
    `pid_clamp_loop(controller = PID(...))`, so the discrete loops reuse the
    continuous models. The continuous testsets are untouched.
16. **`moments` is a test helper** because `Statistics` is not a test
    dependency and the brief adds none.

### The cold review and the fix commit

The reviewer's verdict: sound. Every block's shape, stage, constants and
placement match the brief and the companions' section 9s; gate green at
4d061fe (5258 assertions, Dual sweep 98 covered, 61 skipped, 75 refused);
docs battery green. Sixteen of the brief's seventeen mutants went red, one
survived, and one extra mutant the reviewer added survived. Rulings:

17. **Missing test, the `z` solve.** `x0 = (I - A) \ (B u0)` was tested only
    at `den = (1, -0.5)`, where `I - A == A`, so `A` in place of `I - A`
    survived. Fixed with a second pole, `den = (1, -0.8)`, `num = (0.2,)`,
    `u0 = 2`: `x0 == 10`, `out == 2` at `t₀`.
18. **Missing test, the vector noise.** The sub-counter `k N + i - 1` was
    asserted only at `t₀`, where `k = 0` hides the multiplier, so
    `k + i - 1` survived. Fixed with a read after a few ticks against
    `gaussian(seed, k, SVector{2, Float64})`.
19. **The noise constructor admits what its docstring claims.** Beyond the
    vector-`σ` default (ruling 12), a vector `μ` with a scalar `σ` and
    `Float32` inputs were refused. The body now broadcasts `μ` and the scale
    to one shape and converts with `Float64.(…)`; `μ` defaults to the
    scale's zero. Reason: the docstring says the pair is promoted to one
    `V`, `Float64` or an `SVector` of `Float64`; making it true is three
    lines, and the refusals' error messages were `promote`'s own.
20. **The `GaussianWhiteNoise` docstring says the store holds the next
    sample's index**, so `k` reads `N + 1` after `N` steps. Reason: a reader
    of `state(sim, …).k` would otherwise predict `N`.
21. **`d` → `deriv` in `DiscretePID`'s `y_direct`.** Reason: "Naming"
    reserves `d` for diagnostics and the trim decision vector, and the
    roster's word for a derivative is `deriv`. The companion's sketch in
    `pid_anti_windup.md` section 9 keeps `d`; it is a sketch, not a rule.
22. **The servo comment names its limits.** The continuous figures in the
    discrete loops' comment (5.931 at 23.6 on the servo) are the continuous
    block at the same gains and ±1 limits, which no continuous testset runs.
    The limits stay (the brief's figure needs them) and the comment says so.
23. **The register names `static_system`** in the `StateSpace` bullet, and
    the row's Spec line gains D-231. Reason: the stage 1 bullet names
    `saturation_code`, and every other D-number cited in the row's bullets
    is on the line.
24. **`thousand` and `million`** in the noise testset are renamed for the
    moments they hold.
25. **Two companion corrections, landed by the coordinator as a docs
    commit**: `pid_anti_windup.md` section 9's "nine" shared methods are ten
    (`methods()` on the tree: four `u_types`, one `y_types`, two
    `gated_error`, three `correction_reference`; the pre-increment `PID` had
    the same ten), and `linear_blocks.md` section 9's "`(1, -0.7, -0.3)` sums
    to about `-5.6e-17`" has the wrong sign (the probe gives `+5.55e-17`).
    Both lines were written in the docs arc, not the increment.

26. **Two docstring nits from the delta verification**, landed by the
    coordinator: the `k` clause said "after `N` steps from `t₀`", exact only
    at the base rate with no offset; it now counts the block's own ticks. The
    signature line said `μ = zero(σ)`, which reads as failing under `psd`; it
    now shows `μ = nothing` as the code has it, the prose saying what that
    resolves to.

## Open points for the user

- **`held` is now a package function while locals named `held` remain** in
  `src/dataplane.jl`, `src/devices.jl` and `test/test_blocks.jl`'s cascade
  testset. Resolved after the run with the user: no rename. "Naming" now
  scopes the rule to the functions a module sees, so a function of
  `Redstone.Blocks` binds no name in `Redstone`, which never imports it.
- The brief says "nine shared methods" at two places (lines 430 and 555);
  briefs stay untouched until the first release, so it is left as is.
- Low reviewer nits not acted on: `u1`, `u2` as the uniforms in a file where
  `u` is the input bundle (methods under five lines, allowed).
