# Brief: increment 64, the linear blocks `StateSpace` and `TransferFunction`

Two code stages, one cold review and a fixer if the review needs one. The
docs arc is landed in db2312f: the companion
`docs/design/companions/linear_blocks.md`, the inventory's two rows under
"Continuous dynamics" and its section 4 sentence on the unexported names,
and `pending.md`'s increment 64 bullet. The tip at launch is the commit
adding this brief; line numbers below are db2312f's. Find passages in
`docs/design/implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **Two blocks, one pair of equations.** `StateSpace` holds `A`, `B`, `C`,
  `D` and `x0`; `TransferFunction` holds its coefficients and a realized
  `StateSpace` it forwards every stage to. The companion's section 6 is the
  case and section 8 the decision; this brief restates only what the
  keyboard needs. Neither block earns a log entry: D-313 admits by
  judgement, and the PID set the precedent (user, 2026-10-07).
- **The direct term picks the stage, in the type.** `FT::Bool` is a type
  parameter. `FT = false` publishes `out` from `y_state`, `FT = true` from
  `y_direct`, and `x_deriv` is one method over both (§5.3). The constructor
  sets it, `!iszero(D)` for the matrices and the degree comparison for a
  transfer function. A probe confirmed the consequence the test asserts: a
  scalar block with `D = 0` in a unit-feedback loop through a difference
  junction builds, and the same loop with `D = 1` is refused as an
  `AlgebraicCycle` classified `:real`.
- **Full-shape matrices with length parameters.** `SMatrix{N, M, Float64}`
  is abstract, since a static matrix carries its length as a fourth
  parameter, and a field declared without it boxes in every stage body. The
  first prototype did, and allocated about 1,100 bytes per step. The struct
  is therefore

  ```julia
  struct StateSpace{NX, NU, NY, FT, LA, LB, LC, LD} <: AbstractComponent
      A::SMatrix{NX, NX, Float64, LA}
      B::SMatrix{NX, NU, Float64, LB}
      C::SMatrix{NY, NX, Float64, LC}
      D::SMatrix{NY, NU, Float64, LD}
      x0::SVector{NX, Float64}
  end
  ```

  with which every probed shape steps allocation-free, matching the scalar
  and vector lags byte for byte (companion, section 8). The ugliness of
  `typeof` is accepted; `Matrix` fields converted in the body measured the
  same and were not chosen, for the heap field in instance data.
- **Ports from the shapes.** `in` is `Float64` when `NU == 1` and
  `SVector{NU, Float64}` otherwise; `out` likewise over `NY`. One layout:
  the bodies always do matrix products, a scalar input is lifted to an
  `SVector{1}` and a one-element result is read out, both by two-method
  helpers dispatching on `Real`/`SVector` and `SVector{1}`/`SVector`.
  Matrices are pinned `Float64` instance data; the state and the ports walk
  under `Dual` through `SMatrix * SVector` promotion (§7.2), confirmed by
  building under `(Float64, LinearizeDual)` at every probed shape.
- **`StateSpace(; A, B, C, D = zero, x0 = zero)`**, the keyword constructor
  with no positional face in the docstring. `A`, `B`, `C`, `D` are taken as
  any `AbstractMatrix` (an `SMatrix`, a `Matrix`, a `[-1.0;;]` literal) and
  converted to the static shapes with `float.`, so integer entries promote;
  `nx = size(A, 1)`, `nu = size(B, 2)`, `ny = size(C, 1)`, and a `D` left out
  is the zero matrix, which makes `FT = false`. A shape mismatch is an
  `ArgumentError` from the constructor, in one sentence naming the two
  sizes; `SMatrix` construction would throw a `DimensionMismatch` of its
  own, so check first and say it plainly. `x0` is any `AbstractVector` of
  length `nx`, or a `Real` when `nx == 1`.
- **`TransferFunction(; num, den, u0 = 0.0)`**, one input and one output,
  coefficients highest power first as tuples or vectors, any `Real`
  entries. The helper `realize(num, den)` is the companion's section 2
  listing, returning the four static matrices with the direct term split
  off and the denominator made monic; it is a package function of the
  submodule, unexported, and increment 65 reuses it. Refusals, each an
  `ArgumentError` in one sentence: `length(num) > length(den)` (an
  improper function); a leading `den` coefficient of zero; `u0 ≠ 0` with a
  zero constant coefficient `den[end]` (a pole at the origin has no steady
  state). With `u0 = 0` the state is zero; otherwise `x0 = -(A \ (B *
  SVector(u0)))`, solved once at construction. The probe confirmed that a
  static `\` on a singular matrix returns `Inf`/`NaN` and never throws, so
  the explicit test is the only refusal.
- **The transfer function's struct** is

  ```julia
  struct TransferFunction{N, FT, M, K, LA} <: AbstractComponent
      num::NTuple{M, Float64}
      den::NTuple{K, Float64}
      realization::StateSpace{N, 1, 1, FT, LA, N, N, 1}
  end
  ```

  `N` the order, `K = N + 1`, `M ≤ K`, `LA = N²`. The coefficients are kept
  as the user wrote them, scaled to `Float64`, so the default `show`
  displays the transfer function and not its realization. Ports are
  `Float64`; `x_init`, `x_deriv`, `y_state`/`y_direct` forward to
  `realization` with no `Group`, no cell and no gather, the forwarding arm
  selected by `FT` exactly as on `StateSpace`.
- **Names.** `StateSpace` and `TransferFunction` collide with
  ControlSystemsBase's exports; the companion's section 7 is the ruling and
  the inventory's section 4 the one sentence a user needs. No alias, no
  rename, no bridge.
- **Every number in the stages below was probed at db2312f's parent** against
  the shapes above, at `h = 1//100`, sampling by `step!`. The companion's
  section 8 tabulates them. Confirm each in a probe before writing an
  assertion, and report the probe's numbers.

## Out of scope

- The discrete forms (`DiscreteTransferFunction`, increment 65).
- Transfer matrices, zeros-poles-gain spellings, balanced or observable
  realizations, an initial output `y0`.
- A `show` method, a ControlSystems bridge, an export.
- Any spec or log edit, and any companion edit beyond a one-line status in
  the inventory rows.

## Reading, in order

- `docs/design/pending.md`, the increment 64 bullet, lines 20 to 32.
- `docs/design/companions/linear_blocks.md` whole, then
  `docs/design/companions/library_inventory.md` sections 2 to 4.
- `docs/design/spec.md` §5.3, lines 826 to 1037, above all the two rules
  under "Stage roles"; §5.4, lines 1038 to 1107; §5.5, lines 1108 to 1127;
  §7.2, lines 1625 to 1694; §13.7, lines 9726 to 9954; §14.10, lines 11130
  to 11373. Never read the spec whole.
- `docs/design/decisions.md` D-226, D-263 and D-313.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/blocks.jl` and
  `### test/imports.jl`; "Authoring caveats", its first three bullets;
  "Naming"; "Running the suite". Never restate either in a commit or a
  comment.
- `src/blocks.jl` whole, 521 lines. `FirstOrderLag` (lines 143 to 166) is
  the shape to copy for a stage-1 block, `PID` (lines 390 to 468) for a
  stage-2 block whose `x_deriv` reads the bundle, and the section comments
  at lines 13, 68, 123, 168, 210, 390 and 470 give the file's order.
- `test/test_blocks.jl` whole, 806 lines: the models at top level (lines 1
  to 200), `block_linearization` (line 44), the vector-state and vector-input
  tap spellings (lines 470 to 476), the loop refusal's assertions (lines 610
  to 619), the keyword testset (line 734), the allocation testset over
  `phase_bodies` (lines 278 and 751), the shadowing testset (line 775).
- `test/utils.jl` lines 1 to 30: `single` and `fed`.

## Stage 1: `StateSpace`

### The shape

A new section `# --- the linear blocks (§13.7, §5.3, D-313) ---` after the
continuous dynamics section, before the step's, holding both blocks by the
end of stage 2. The struct of "What is settled", its keyword constructor,
`x_init(c) = (q = c.x0,)`, `u_types`/`y_types` from `NU`/`NY`, one
`x_deriv`, and the two output arms. The docstring shows the keyword form,
states the port rule, names `FT` as the feedthrough class and says what
picks it, and sends the reader to `linear_blocks.md` for the realization
and the names.

Probed values for the tests, all at `h = 1//100`:

- the two-state block `A = [-1 0.5; 0 -2]`, `B = [1 0.5; 0 1]`,
  `C = [1 2; 0 1]`, `D = 0`, under root faces `in` and `out`, input
  `SVector(1.0, -1.0)`, stepped to `t = 0.3`: `linearize` over
  `x = (q1, q2)` by `get_state("c", "q[1]")`…, `u = (in1, in2)` by
  `get_input("in[1]")`…, `y = (out1, out2)` by `get_face("out[1]")`…
  recovers `A`, `B`, `C`, `D` to `atol = 1e-12`;
- `block_linearization(StateSpace(A = [-2.0;;], B = [3.0;;], C = [1.0;;]))`
  gives `A = [-2.0;;]`, `B = [3.0;;]`;
- the scalar block `A = -1`, `B = 1`, `C = 1`, `x0 = 2`, fed by
  `Constant(1.0)`, has `q(1) = 1 + e⁻¹` to `rtol = 1e-7`;
- `loop(D) = Group((; r = Constant(1.0), e = Junction{Float64, Float64, 2}(-),
  p = StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], D = [D;;]));
  local_wires = ("r/out" => "e/in1", "p/out" => "e/in2", "e/out" => "p/in"))`:
  `build(loop(0.0)) isa Build`; `build(loop(1.0))` throws a
  `DiagnosticError` whose one diagnostic is an `AlgebraicCycle` with
  `classification === :real`.

### Tests

New testsets in `test/test_blocks.jl`, after the lag's, models at top
level:

- "the state space linearizes to its own matrices at any operating point,
  over scalar or vector ports (§13.7, §14.10, D-313)": the two-state
  linearization and the scalar `block_linearization` above; `u_types` and
  `y_types` asserted directly for the shapes `(NU, NY) = (1, 1)`, `(2, 2)`
  and `(2, 1)`, the last `(in = SVector{2, Float64},)` with
  `(out = Float64,)`.
- "the direct term picks the stage: `D = 0` breaks the loop, `D ≠ 0`
  closes an algebraic cycle (§5.3, §5.5, D-313)": the two `loop` builds,
  the diagnostic's kind and classification, and
  `StateSpace(…, D = [1.0;;]) isa StateSpace{1, 1, 1, true}` beside the
  default's `false`.
- "the state space runs from `x0` and walks under `Dual` (§7.2, §13.7)":
  the `1 + e⁻¹` sample, and `build(model; activations = (Float64,
  LinearizeDual)) isa Build` for the scalar and the two-state models.
- The keyword testset gains `StateSpace(A = [-1;;], B = [1;;], C = [1;;])
  isa StateSpace{1, 1, 1, false}` and an `x0 = 1` integer promoting; and
  `@test_throws ArgumentError` for `B` with the wrong row count and for an
  `x0` of the wrong length.
- The shadowing testset's tuple gains a scalar `D = 0`, a scalar `D = 1` and
  the two-state instance.
- A new "the linear blocks' phase bodies allocate nothing (§7.5)" over
  `phase_bodies`, the idiom of line 278, for the two-state model under
  `Constant(SVector(1.0, -1.0))` and for `loop(0.0)`; stage 2 extends it.

### Routing

`src/blocks.jl` is the `blocks` row: run `blocks build` under the flags of
"Running the suite", in the foreground, 600 s per invocation.

### Bookkeeping, in the same commit

- `test/imports.jl` line 77: `StateSpace` joins the `import Redstone.Blocks:`
  line.
- `docs/design/implementation.md` `### src/blocks.jl`: one bullet,
  "`StateSpace`, over scalar or `SVector` ports by its matrix shapes, its
  feedthrough class the type parameter `FT` (D-313)". Constructs, not
  behaviour.
- `docs/design/companions/library_inventory.md`: the `StateSpace` row's
  status becomes *shipped*. Linkified spelling; run the battery, `linkify`
  a no-op on rerun.

## Stage 2: `TransferFunction`

### The shape

`realize(num, den)` and the struct of "What is settled", in the same
section, after `StateSpace`. The constructor validates, realizes, solves
`x0` from `u0` and builds the `StateSpace` by its positional form. The
docstring shows the keyword form with the coefficient order, states that
the block has no `x0` and why in one sentence, names the three refusals,
and sends the reader to `linear_blocks.md` sections 2 and 5.

Probed values, at `h = 1//100`:

- `TransferFunction(num = (1,), den = (0.5, 1))` realizes to `A = -2`,
  `B = 1`, `C = 2`, `D = 0`, type `{1, false, 1, 2, 1}`;
  `TransferFunction(num = (1, 2), den = (1, 5))` to `A = -5`, `B = 1`,
  `C = -3`, `D = 1`, type `{1, true, 2, 2, 1}`;
  `TransferFunction(num = (4,), den = (1, 1.2, 4))` to
  `A = [0 1; -4 -1.2]`, `B = [0; 1]`, `C = [4 0]`, `D = 0`, type
  `{2, false, 1, 3, 4}`. All exact in floating point;
- the first beside `FirstOrderLag(τ = 0.5)`, both from `Constant(1.0)`, at
  `t = 1`: both outputs `0.8646647163964265`, equal to the last bit in the
  probe, and the transfer function's `q` is `0.4323…`, half the lag's.
  Assert `≈` at `rtol = 1e-12`, not `==`;
- the lead-lag under root faces, `linearize` with `y = (out =
  get_face(:out),)`: `A = -5`, `B = 1`, `C = -3`, `D = 1` at `atol = 1e-12`;
- the second-order block likewise, `H(s) = (C * ((s * I - A) \ B) + D)[1]`
  from the linearization against `G(s) = 4 / (s² + 1.2s + 4)` at
  `s = 0, i, 2i, 1 + 3i`: `|H - G| ≤ 2.3e-16` in the probe; assert
  `< 1e-12`;
- `TransferFunction(num = (1,), den = (0.5, 1), u0 = 3.0)` under root
  faces, `init!` with `in = 3.0`: `out == 3.0` at start and `≈ 3.0` after
  one second;
- `TransferFunction(num = (1,), den = (1, 0))` builds, type
  `{1, false, …}`, and fed by `Constant(1.0)` has `out ≈ 1` at `t = 1`.

### Tests

- "the transfer function realizes in controllable canonical form, the
  direct term split off (§13.7, D-313)": the three realizations' matrices
  read off `realization`, exactly, and the three types.
- "the transfer function of the lag matches the lag block (§13.7)": the
  `t = 1` sample and one at `t = 0.3`, both `rtol = 1e-12`.
- "the lead-lag and the second-order system linearize to their transfer
  functions (§14.10, D-313)": the lead-lag's four matrices and the
  second-order's four `|H - G|`.
- "the transfer function starts at rest or at the steady state for `u0`, and
  refuses an improper function or an origin pole with `u0` (§13.7)": the
  `u0 = 3` start and its hold; the integrator with `u0 = 0` building and
  integrating; `@test_throws ArgumentError` for `num = (1, 1, 1), den =
  (1, 1)`, for `den = (1, 0), u0 = 1.0`, and for `den = (0, 1)`.
- "the transfer function's stage follows its degree (§5.3)": the lead-lag
  in `loop`'s place is refused as `AlgebraicCycle` `:real`, the lag form
  builds. Reuse stage 1's `loop` with the block as a parameter if the
  model reads well; otherwise a second model.
- The keyword testset gains `TransferFunction(num = (1,), den = (1, 2)) isa
  TransferFunction{1, false}` from integer tuples and the same from
  vectors; the shadowing tuple gains the lag form, the lead-lag and the
  second-order block; the allocation testset gains the lag-form model and
  the lead-lag in a loop with a stage-1 plant (a `FirstOrderLag`), under
  `(Float64, LinearizeDual)` builds asserted beside.

### Routing

`blocks build`, as in stage 1.

### Bookkeeping, in the same commit

- `test/imports.jl`: `TransferFunction` joins the line.
- `docs/design/implementation.md` `### src/blocks.jl`: the stage 1 bullet
  grows to "`StateSpace` … and `TransferFunction`, realized by `realize`
  and forwarding to a held `StateSpace` (D-313)".
- `docs/design/companions/library_inventory.md`: the `TransferFunction`
  row's status becomes *shipped*.
- `docs/design/pending.md`: the increment 64 sub-bullet is removed, the
  parent reads "two remaining tranches", and the two remaining sub-bullets
  keep their numbers. `check_refs.jl` and `check_rows.jl` read this file;
  run the battery.

## The cold review

One fresh Opus reviewer over the two code commits: open-mind stance, probe
scripts under `/tmp`, "empty is acceptable". Dimensions:

- **Each block against its sketch here and the companion**: the length
  parameters on every matrix field, the arm selection by `FT`, the port
  rule, the coefficient order, the direct-term split, the monic
  normalization, the three refusals, the forwarding with no `Group`.
- **The submodule's imports.** `src/blocks.jl` reaches the parent through
  its import list alone; `SMatrix`, `SVector` and `I` are the StaticArrays
  and LinearAlgebra names the section may add, by name.
- **Mutants on a scratch copy**, each named test going red: a matrix field
  without its length parameter (the allocation testset); `y_direct` dropping
  `D * u` (the lead-lag's `D`); `FT` set from `D === nothing` instead of
  `iszero(D)` (an explicit zero `D` in the loop); `realize` skipping the
  monic division (the lag match); the direct term not subtracted from the
  numerator (the lead-lag's `C`); `reverse` dropped from `C` (the
  second-order `H(s)`); `x0` from `A \ (B u0)` with the sign dropped (the
  `u0 = 3` start); the origin-pole check dropped (the `ArgumentError`). A
  surviving mutant is a missing test.
- **The numbers.** Re-probe every asserted value against the companion's
  section 8 table and this brief.
- **`Dual`.** Every new model builds under `(Float64, LinearizeDual)`, and
  the linearizations assert the matrices, so a `Float64` pin on the
  continuous path is a red test.
- **The register, the inventory and the companion.** `implementation.md`'s
  rows name constructs; behaviour is in docstrings; the docstrings and
  `linear_blocks.md` agree, the `x0`/`u0` rule above all.
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
