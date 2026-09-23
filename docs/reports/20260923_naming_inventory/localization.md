# Naming inventory: src/localization.jl

Tip: f64b9f3. Sites flagged: 52. Renames: 13. Collisions: 1. Roster proposals: 0.

## Letters with more than one meaning in this file

- `x`-prefixed names: the spec's state (`x₀`, `sim.exec.xbuf`, `xnext`) in `_localized_frame!`, and three ITP points in θ (`xh`, `xf`, `xt`) in `_crossing` → the ITP points renamed `θ_mid`, `θ_falsi`, `θ_trunc`
- `s`: the ITP sign (`_crossing`, line 212); the spec's `s` is the discrete state → renamed `direction`
- `n`: the event count (`_localized_frame!`); `nmax` in `_crossing` is ITP's `n_max`, an iteration bound → the count renamed `event_count`, `nmax` spelled `n_max` as its comment does
- `i`: the event index in `_localized_frame!` and `_crossing`; `j`: the ITP iteration counter (`_crossing`) → indices, kept
- `k`: the frame index (`_grid_time`, `frame!`) → one meaning, kept

## `_grid_time(sim::Simulation, k::Int)` — line 17

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 17 | `sim` | param | the simulation | keep:roster | — |
| 17 | `k` | param | the frame index | keep:index | — |

## `frame!(sim::Simulation{T}, k::Int, pol::StopPolicy, addrs::Vector{Any}) where {T}` — line 33

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 33 | `sim` | param | the simulation | keep:roster | — |
| 33 | `T` | type param | the deployment's scalar | keep:typeparam | — |
| 33 | `k` | param | the frame index | keep:index | — |
| 33 | `pol` | param | the advance's stop policy (the docstring: "the advance's stop policy") | rename | `policy` |
| 33 | `addrs` | param | the stop faces' compiled addresses | keep:roster | — |

## `_localized_frame!(sim::Simulation{T}, t_to, pol::StopPolicy, addrs::Vector{Any}) where {T}` — line 48

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 48 | `sim` | param | the simulation | keep:roster | — |
| 48 | `T` | type param | the deployment's scalar | keep:typeparam | — |
| 48 | `pol` | param | the advance's stop policy | rename | `policy` (as in `frame!`) |
| 48 | `addrs` | param | the stop faces' compiled addresses | keep:roster | — |
| 49 | `es` | destructure | the executor's event set, read on nearly every line of the 115-line body | rename | `events` (unbound as a function in `src/`) |
| 49 | `cur` | destructure | the execution cursor | rename | `cursor` |
| 50 | `n` | local | the number of declared events, the bound of four loops | rename | `event_count` |
| 51 | `x₀` | destructure | the state at the segment start, the seam's retained `x(t_seg)` | keep:spec | — |
| 51 | `_` | destructure | the retained derivative, discarded | keep:glance | — |
| 52 | `count` | local | the localizations produced in this frame, against `localization_budget`; shares its name with `Base.count` | collision | `localizations` |
| 55 | `t_seg` | local | the segment's start time | keep:spec | — |
| 56 | `h′` | local | the segment's length | keep:spec | — |
| 69 | `any_trig` | local | whether any event triggered at arrival | rename | `any_triggered` |
| 70 | `i` | for | the event index | keep:index | — |
| 80 | `i` | for | the event index | keep:index | — |
| 107 | `i` | for | the event index | keep:index | — |
| 129 | `θ★` | local | the earliest crossing in θ | keep:spec | — |
| 130 | `i` | for | the event index | keep:index | — |

## `_trial!(sim::Simulation, θ::Float64, t_seg, h′)` — line 173

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 173 | `sim` | param | the simulation | keep:roster | — |
| 173 | `θ` | param | the trial point in the segment's unit interval | keep:spec | — |
| 173 | `t_seg` | param | the segment's start time | keep:spec | — |
| 173 | `h′` | param | the segment's length | keep:spec | — |

## `_crossing(sim::Simulation, i::Int, σ₀::Float64, σ₁::Float64, t_seg, h′)` — line 193

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 193 | `sim` | param | the simulation | keep:roster | — |
| 193 | `i` | param | the event index | keep:index | — |
| 193 | `σ₀`, `σ₁` | param | the guard at the bracket's ends (the docstring's `σ₀`, `σ₁`) | keep:spec | — |
| 193 | `t_seg`, `h′` | param | the segment's start and length | keep:spec | — |
| 194 | `es` | local | the executor's event set, read once on line 220 | rename | `events` (as in `_localized_frame!`) |
| 199 | `tol` | local | the bracket-width stop in θ (the docstring's `tol·h/h′`) | keep:spec | — |
| 200 | `lo`, `hi` | destructure | the bracket's ends in θ; the docstring names `hi` | keep:spec | — |
| 201 | `σlo`, `σhi` | destructure | the guard at `lo` and `hi` | keep:spec | — |
| 205 | `ε` | local | ITP's half-width target (the comment's `ε`) | keep:spec | — |
| 206 | `nmax` | local | ITP's iteration bound, spelled `n_max` in the comment above it | rename | `n_max` |
| 207 | `j` | local | the ITP iteration counter (ITP's `j`), also the trial ordinal less one | keep:index | — |
| 209 | `xh` | local | ITP's bisection point `x_½`, in θ; the `x` prefix reads as the state | rename | `θ_mid` (the comment's "midpoint") |
| 211 | `xf` | local | ITP's regula-falsi point `x_f`, in θ | rename | `θ_falsi` |
| 212 | `s` | local | ITP's sign `σ = sign(x_½ − x_f)`; the spec's `s` is the discrete state and `σ` is the guard here | rename | `direction` |
| 213 | `δ` | local | ITP's truncation size `δ = κ₁(b − a)^κ₂` | keep:spec | — |
| 214 | `xt` | local | ITP's truncated point `x_t`, in θ | rename | `θ_trunc` |
| 215 | `r` | local | ITP's minmax radius (the comment's "minmax radius") | rename | `radius` |
| 216 | `θ` | local | the projected trial point, ITP's `x_ITP` | keep:spec | — |
| 220 | `σθ` | local | the guard at the trial point | keep:spec | — |

## Collisions

- `count` (line 52, `_localized_frame!`): `Base.count`. Not called inside `_localized_frame!` (nor anywhere in the file). Proposal `localizations`, the docstring's noun ("the budget counts localizations").

## Roster proposals

None.

## Questions

- `_crossing`'s ITP locals are the paper's symbols (Oliveira & Takahashi 2020), which the docstring cites but does not spell. Kept as `keep:spec` where the comments name them (`ε`, `hi`, `tol`) or the name is the paper's Greek (`δ`); renamed where the Latin letter clashes with the spec's `x` or `s`. If the user prefers the paper's spelling throughout, `x_half`, `x_f`, `x_t` would keep the reference readable at the cost of the `x` clash.
- `t_to` (lines 34, 48) is the frame top's time, unflagged by length and not an abbreviation; `t_top` would say which end it is. No proposal made.
- `j` counts ITP iterations and is also the cursor's trial ordinal less one (line 218). Kept as an index; `iteration` would name both uses.
