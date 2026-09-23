# Naming inventory: src/stepper.jl

Tip: f64b9f3. Sites flagged: 50. Renames: 14. Collisions: 0. Roster proposals: 0.

## Letters with more than one meaning in this file

- `m`: the stepper in every method (`step!`, `startpoint`, `dense!`); the spec's `m` is the mode store → renamed `stepper`
- `t₀`: the step's start time (`step!`, lines 52, 88); the spec's `t₀` is the run's origin, `Clock.t₀` → renamed `t`, the seam's "advance from `t` by `h`" (§10.2)
- `dt`: the partial step `_advance!` takes, `h` or `h / 2` → renamed `h`
- `n`: the flat buffer's length (`RK4`, `Heun` constructors), the spec's `nx` → renamed `nx`
- `k`: a stage derivative (`_advance!`), the RK stages `k₁`…`k₄` beside it → one meaning, kept

## `RK4(::Type{T}, n::Int) where {T}` — line 47

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 47 | `T` | type param | the scalar | keep:typeparam | — |
| 47 | `n` | param | the flat state buffer's length (the docstring's `RK4(T, n)`) | rename | `nx` (the spec's state length) |
| 47 | `_` | lambda | discarded | keep:glance | — |

## `step!(m::RK4, sim, h)` — line 49

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 49 | `m` | param | the RK4 stepper; the spec's `m` is the mode store | rename | `stepper` (the seam's noun; no function of that name) |
| 49 | `sim` | param | the simulation | keep:roster | — |
| 49 | `h` | param | the step | keep:spec | — |
| 50 | `x`, `ẋ` | destructure | the state and derivative buffers | keep:spec | — |
| 51 | `x₀`, `k₁`, `k₂`, `k₃`, `k₄` | destructure | the start state and the four stage derivatives, RK4's own symbols | keep:spec | — |
| 52 | `t₀` | local | the step's start time; the spec's `t₀` is the run's origin (`Clock.t₀`) | rename | `t` (§10.2: "advance the continuous state from `t` by `h`") |
| 63 | `i` | for | the buffer index | keep:index | — |

## `startpoint(m::RK4)` — line 69

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 69 | `m` | param | the stepper (the docstring's `startpoint(m)`) | rename | `stepper` |

## `Heun(::Type{T}, n::Int) where {T}` — line 83

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 83 | `T` | type param | the scalar | keep:typeparam | — |
| 83 | `n` | param | the flat state buffer's length | rename | `nx` |
| 83 | `_` | lambda | discarded | keep:glance | — |

## `step!(m::Heun, sim, h)` — line 85

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 85 | `m` | param | the Heun stepper | rename | `stepper` (as in the RK4 method) |
| 85 | `sim` | param | the simulation | keep:roster | — |
| 85 | `h` | param | the step | keep:spec | — |
| 86 | `x`, `ẋ` | destructure | the state and derivative buffers | keep:spec | — |
| 87 | `x₀`, `k₁`, `k₂` | destructure | the start state and the two stage derivatives | keep:spec | — |
| 88 | `t₀` | local | the step's start time | rename | `t` |
| 95 | `i` | for | the buffer index | keep:index | — |

## `startpoint(m::Heun)` — line 101

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 101 | `m` | param | the stepper | rename | `stepper` |

## `_advance!(x, x₀, k, dt)` — line 103

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 103 | `x`, `x₀` | param | the state written, the start state | keep:spec | — |
| 103 | `k` | param | one stage derivative, the RK stage symbol | keep:spec | — |
| 103 | `dt` | param | the partial step, `h` or `h / 2` | rename | `h` (the seam's step; the callers pass `h` or `h / 2`) |
| 104 | `i` | for | the buffer index | keep:index | — |

## `dense!(m::AbstractStepper, x̂, x₁, ẋ₁, θ::Float64, h′)` — line 122

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 122 | `m` | param | the stepper (the docstring's `dense!(m, …)`) | rename | `stepper` |
| 122 | `x̂`, `x₁`, `ẋ₁`, `θ`, `h′` | param | the interpolant's output, the arrival pair, the trial point, the segment length | keep:spec | — |
| 123 | `x₀`, `ẋ₀` | destructure | the retained start pair | keep:spec | — |
| 124 | `θ²`, `θ³` | local | powers of `θ` | keep:spec | — |
| 125 | `b₀`, `b₁` | local | the cubic Hermite weights on `x₀` and `x₁`; no docstring or spec text names them | rename | `w_x₀`, `w_x₁` |
| 127 | `d₀`, `d₁` | local | the Hermite weights on `ẋ₀` and `ẋ₁`, scaled by `h′`; `d` is a diagnostic by rule | rename | `w_ẋ₀`, `w_ẋ₁` |
| 129 | `i` | for | the buffer index | keep:index | — |

## Collisions

None. `stepper` is not a function in `src/` or Base; `step!`, `startpoint` and `dense!` are the file's own functions, and no local takes their names.

## Roster proposals

None.

## Questions

- The docstrings spell the stepper `m` (`startpoint(m)`, `dense!(m, …)`, the file comment's `step!(m, sim, h)`); the rename to `stepper` implies editing those three docstring signatures too. §10.2 itself names no parameter.
- `step!(m, sim, h)` here and `step!(sim::Simulation, h)` in `sim.jl` are methods of one function whose first positions differ (`stepper` against `sim`). The rule "every method names its parameters alike" cannot hold across different arities; the report assumes it binds only positions that hold the same thing.
- `t` for the step's start (line 52) follows §10.2's wording, but the value is fixed while the clock moves through `t + h / 2`. If the user reads `t` as "the current time", `t_seg` (the spec's segment start, as `localization.jl` binds it) is the alternative.
- `b₀`/`d₀` could instead take the textbook Hermite basis names `h₀₀`, `h₀₁`, `h₁₀`, `h₁₁`, which clash with the spec's `h`; hence the `w_` proposal.
