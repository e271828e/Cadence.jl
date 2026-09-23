# Naming inventory: src/deployment.jl

Tip: f64b9f3. Sites flagged: 79. Renames: 30. Collisions: 8. Roster proposals: 0.

## Letters with more than one meaning in this file

- `h`: the continuous step (`bind_schedule`, `Deployment`), the hash seed (the three `Base.hash` methods) → hash-seed sites renamed below
- `r`: a rational quantity (`_as_int`), the leave-one-out refinement factor (`_grid_report`) → both renamed below
- `m`: the cofactor left to divide (`_prime_powers`); `m` is the spec's mode store, and `timing.m` (a field) the rate multiplier → renamed below
- `d`: a `Deployment` (`hash`, `warnings`); `d` means a diagnostic in `diagnostics.jl` and nothing elsewhere → renamed below
- `e`: a prime's exponent (`_prime_powers`, the `primes` comprehension), a grid entry (`Deployment`'s generator) → exponent sites renamed below
- `g`: a partial gcd (`_grid_report`), the grid report (`Deployment`) → both renamed below
- `D`, `Φ`: the spec's per-anchor period and offset in ticks (the anchor loop), the per-component gate (the component loop); one concept at two levels, kept as spec symbols

## `_exact(name::Symbol, v, diags::Vector{Diagnostic})` — lines 13–20

Five one-line methods; every row applies to all five.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 13, 14, 15, 16, 18 | `v` | param (×5) | the parameter's user-supplied value | rename | `value` (the `DeploymentInvalid` field it lands in) |
| 13, 14, 15, 16, 18 | `diags` | param (×5) | the call's diagnostic list | keep:roster | — |

## `_as_int(r::Rational)` — line 22

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 22 | `r` | param | the exact quantity tested for integrality | rename | `value` (`r` is the refinement factor in `_grid_report`) |

## `_prime_powers(n::Int)` — line 28

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 28 | `n` | param | the grid denominator factored | rename | `integer` (`denominator` is Base's, called in this file) |
| 29 | `out` | local | the (prime, power) list returned | rename | `powers` |
| 30 | `m` | destructure | the cofactor still to divide | rename | `cofactor` (`m` is the spec's mode store) |
| 30 | `q` | destructure | the trial divisor | rename | `divisor` |
| 33 | `e` | local | the divisor's exponent | rename | `power` (the `GridReport` tuple's field) |

## `_grid_report(anchors::Vector{Anchor})` — line 53

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 54 | `kinds` | destructure | each pool entry's kind, `:period` or `:offset` | collision | `entry_kinds` (`kinds`, `diagnostics.jl:105`; not called in the scope) |
| 54 | `values` | destructure | each pool entry's value | collision | `entry_values` (`Base.values`; not called in the scope) |
| 54 | `ks` | destructure | each pool entry's anchor index | rename | `anchor_indices` |
| 55 | `k` | for | an anchor index | keep:index | — |
| 58 | `k` | for | an anchor index | keep:index | — |
| 65 | `adm` | local | `gcd(pool)`, the admissible grid | rename | `admissible` (the `GridReport` field it fills) |
| 67 | `i` | for | a pool index | keep:index | — |
| 70 | `g` | local | the leave-one-out gcd, read over 15 lines | rename | `partial` (the docstring's "partial gcd") |
| 71 | `j` | generator | a pool index | keep:index | — |
| 72 | `r` | local | the leave-one-out refinement factor `r_p` | rename | `factor` (the `GridEntry` field it fills; `r_p` is the spec's, but the one-letter form is not) |
| 76 | `alts` | local | a driving offset's nearest non-refining neighbours | rename | `alternatives` (the `GridEntry` field) |
| 81 | `τ`, `T` | destructure | the offset and its anchor's period | keep:spec | — |
| 82 | `lo` | local | the lower neighbour on the partial grid | rename | `lower` |
| 90 | `i` | comprehension | a pool index | keep:index | — |
| 91 | `q`, `e` | generator destructure | a prime and its power | rename | `prime`, `power` (as in `_prime_powers`; the comprehension spans three lines and uses `q^e` twice) |

## `Base.:(==)(a::ScheduleEntry, b::ScheduleEntry)` — line 114

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 114 | `a`, `b` | param | the two rows compared | keep:glance | — (operator operands with no roles; see Questions) |

## `Base.hash(entry::ScheduleEntry, h::UInt)` — line 117

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 117 | `h` | param | the hash seed | rename | `seed` (`h` is the continuous step in this file) |

## `Base.:(==)(a::Schedule, b::Schedule)` — line 144

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 144 | `a`, `b` | param | the two schedules compared | keep:glance | — |

## `Base.hash(schedule::Schedule, h::UInt)` — line 145

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 145 | `schedule` | param | the schedule hashed | collision | keep `schedule` (`Base.schedule`, not called in the scope; the spec's noun and the `Deployment` field; see Questions) |
| 145 | `h` | param | the hash seed | rename | `seed` |

## `_gates(schedule::Schedule, structure::Structure)` — line 150

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 150 | `schedule` | param | the deployment's schedule | collision | keep `schedule` (`Base.schedule`, not called in the scope; see Questions) |
| 151 | `byrow` | local | the rows keyed by component path | rename | `row_by_path` |
| 152 | `D_c`, `Φ_c`, `Δt_c` | destructure | the per-component gates | keep:spec | — |

## `bind_schedule(build::Build, h, N_base, Δt_base, diags::Vector{Diagnostic})` — line 177

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 177 | `build` | param | the build bound | collision | keep `build` (`build`, `build.jl:720`, not called in the scope; the spec's noun for the artifact; see Questions) |
| 177 | `h`, `N_base`, `Δt_base` | param | the grid parameters as supplied | keep:spec | — |
| 177 | `diags` | param | the call's diagnostic list | keep:roster | — |
| 178 | `k0` | local | the list's length on entry, compared twice 40 lines on | rename | `count_on_entry` |
| 180 | `h_r` | local | `h` as an exact rational | keep:spec | — (derivative of `h`) |
| 185 | `n_ok` | local | whether `N_base` is sound | rename | `N_base_sound` |
| 198 | `Δt_r` | destructure | `Δt_base` as an exact rational | keep:spec | — (derivative of `Δt_base`) |
| 220 | `n_i` | local | the resolved `N_base`, `Δt_base / h` as an integer | rename | `N_base_resolved` |
| 236 | `Dk`, `Φk` | destructure | the per-anchor period and offset in base ticks | keep:spec | — |
| 238 | `D` | local | an anchor's period in base ticks | keep:spec | — |
| 243 | `Φ` | local | an anchor's offset in base ticks | keep:spec | — |
| 255 | `Δtb` | local | the resolved `Δt_base` as a `Float64` | keep:spec | — (derivative of `Δt_base`; `Δt_base_f` would name the conversion if the user wants it spelled) |
| 256 | `bind` | local function | a timing's `(D, Φ)` by the multiply-add | collision | `timing_gates` (`Base.bind`; not called in the scope) |
| 261 | `D`, `Φ` | destructure | a component's gate | keep:spec | — |

## `Deployment(build::Build; h = nothing, N_base = nothing, Δt_base = nothing, …)` — line 326

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 326 | `build` | param | the build bound | collision | keep `build` (as in `bind_schedule`; `build` not called in the scope) |
| 326 | `h`, `N_base`, `Δt_base` | keyword param | the grid parameters as supplied | keep:spec | — |
| 331 | `diags` | destructure | the call's error list | keep:roster | — |
| 331 | `ws` | destructure | the warnings the constructor raises | collision | `raised` (`warnings`, defined at line 395, would be the natural noun; not called in the scope) |
| 349 | `g` | local | the grid report, read over 12 lines | rename | `grid` (the `Deployment` field) |
| 351 | `e` | generator | a pool entry | keep:glance | — |
| 358 | `u` | local | the minimum tick period, the utilization | rename | `utilization` (the payload field; `u` is the spec's input symbol) |
| 358, 360 | `row` | generator, lambda param (×2) | a schedule row | keep:glance | — |

## `Base.:(==)(a::Deployment, b::Deployment)` — line 378

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 378 | `a`, `b` | param | the two deployments compared | keep:glance | — |

## `Base.hash(d::Deployment, h::UInt)` — line 383

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 383 | `d` | param | the deployment hashed | rename | `deployment` |
| 383 | `h` | param | the hash seed | rename | `seed` |

## `warnings(d::Deployment)` — line 395

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 395 | `d` | param | the deployment | rename | `deployment` (the docstring at 389 too; `warnings`' other methods take `b::Build`, `build.jl:939`, and `sim::Simulation`, `sim.jl:225`) |

## Collisions

- line 54, `kinds` in `_grid_report`: `kinds`, `diagnostics.jl:105`; not called in `_grid_report`.
- line 54, `values` in `_grid_report`: `Base.values`; not called in `_grid_report`.
- line 145, `schedule` in `Base.hash(schedule::Schedule, h)`: `Base.schedule` (task scheduling); not called in the method.
- line 150, `schedule` in `_gates`: `Base.schedule`; not called in `_gates`.
- line 177, `build` in `bind_schedule`: `build`, `build.jl:720`; not called in `bind_schedule`.
- line 256, `bind` (local function) in `bind_schedule`: `Base.bind` (channel binding); not called in `bind_schedule`.
- line 326, `build` in `Deployment(build; …)`: `build`, `build.jl:720`; not called in the constructor.
- line 331, `ws` → `raised` in `Deployment(build; …)`: the natural name `warnings` is the function at line 395; not called in the constructor.

## Roster proposals

None.

## Questions

- `build` and `schedule` are the spec's nouns for two artifacts, and each shares its word with a function: the package's `build` and Base's `schedule`. Renaming every `build::Build` parameter across `src/` would be a large churn for a collision nobody can trip over, since neither function is called where the local lives. The rules name `path` as the one exception; should `build` and `schedule` join it? The table proposes keeping both pending that ruling.
- `Base.:(==)(a, b)` (three methods): operator operands have no roles to name; kept as `a`/`b`. Say if the rule should reach operator methods.
- `Base.hash`'s seed is `h` by Julia convention, and `trace.jl:72` uses `h` too. In this file `h` is also the continuous step, so the table renames the seed to `seed`; `trace.jl` (group G) should follow for "one name, one meaning" to hold package-wide.
- `warnings` has three methods with three parameter names (`b::Build`, `d::Deployment`, `sim::Simulation`). "Every method names its parameters alike" cannot hold literally across unrelated types; the table names each by what it holds.
- The spec-symbol rule admits "derivatives" without saying which suffixes count. The table keeps `h_r`, `Δt_r` (exact rationals) and `Δtb` as derivatives, and renames `n_ok` and `n_i`, whose `n` spells no spec symbol (the spec's is `N_base`). A ruling on the `_r`/`b` suffixes would settle the edge.
- `r_p` is D-187's symbol for the refinement factor, so line 72's `r` could claim `keep:spec`; the table renames it to `factor`, the field it fills, because a bare `r` also meant a rational in `_as_int`.
