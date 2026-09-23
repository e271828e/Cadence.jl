# Naming inventory: src/trim.jl

Tip: f64b9f3. Sites flagged: 118. Renames: 44. Collisions: 3. Roster proposals: 3.

## Letters with more than one meaning in this file

- `v`: a problem field's NamedTuple (`_check_decisions!`, `_check_floats!`), one tolerance (`_check_tolerances!`), one seeded residual entry (`eval!`), the positional decisions (`_seeded`) → all renamed below
- `m`, `n`, `N`: the residual count (`solve`), the decision count (`solve`), the decision count as the `Dual`'s width (`trim!`, `_seeded`); the spec's `m` is the mode store → `m` and `n` renamed, `N` kept as the type parameter it becomes
- `dt`: the trial decisions (`solve`); `dt` reads as a time step beside the spec's `Δt` and `h` → renamed with its siblings `rt`, `Jt`
- `k`: a key symbol in every loop and comprehension; the rules reserve it for an index → the loop sites with long bodies renamed `key`, comprehensions kept
- `r`: the packed residual vector (`solve`, `eval!`, `_verdict!`) and the residual return NamedTuple (`_check_residuals`); the spec uses `r` for both (§14.7's `NamedTuple{keys(tolerances)}(r)`, §14.8's `eval!(r, J, d)`) → kept
- `d`: the spec's decision vector (§14.7, §14.8) throughout; the rules say `d` is a diagnostic in `diagnostics.jl` and nothing elsewhere → kept as `keep:spec`, see Questions
- `T`, `TD`: the activation scalar (a type parameter) and, in `trim!`, the seeded scalar bound as a local → `TD` renamed `T`

## `TrimProblem(; guess, lower, upper, condition, reads, residuals, tolerances)` — line 59

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 59 | `condition` | keyword | the condition-valued function; shares its name with `condition(c; kw...)`, `conditions.jl:53` | collision | keep the keyword: it is §14.7's normative field name and the API's spelling (see Questions) |
| 59 | `reads` | keyword | the declared read set; shares its name with the exported `reads(…)` (§14.4) | collision | keep the keyword, as above |

## `LevenbergMarquardt(; maxiter::Integer = 100, λ₀::Real = 1e-3)` — line 164

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 164 | `maxiter` | keyword | the iteration cap; the API's keyword and the field name | roster? | `maxiter` (see Roster proposals) |
| 164 | `λ₀` | keyword | the initial damping, the docstring's `λ₀` | keep:spec | — |

## `_within(r, tol)` — line 173

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 173 | `r` | param | the residual vector (§14.8's `r`) | keep:spec | — |
| 173 | `tol` | param | the tolerance vector (§14.8's `tol`) | keep:spec | — |
| 173 | `i` | lambda | the residual index | keep:index | — |

## `_scaled_norm(r, tol)` — line 178

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 178 | `r`, `tol` | param | the residual and tolerance vectors | keep:spec | — |
| 178 | `i` | lambda | the residual index | keep:index | — |

## `solve(bk::LevenbergMarquardt, eval!, d0::Vector{Float64}, …)` — line 180

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 180 | `bk` | param | the backend | rename | `backend` (what `trim!` passes and the docstring's signature says) |
| 180 | `eval!` | param | the evaluation callback, §14.8's name | keep:spec | — |
| 180 | `d0` | param | the starting decisions, §14.8's name | keep:spec | — |
| 181 | `tol` | param | the tolerance vector | keep:spec | — |
| 182 | `n` | destructure | the decision count | rename | `n_decisions` |
| 182 | `m` | destructure | the residual count; the spec's `m` is the mode store | rename | `n_residuals` |
| 183 | `d`, `r`, `J` | destructure | the current decisions, residuals and Jacobian (§14.8's `eval!(r, J, d)`) | keep:spec | — |
| 184 | `dt` | destructure | the trial decisions; reads as a time step | rename | `d_trial` |
| 184 | `rt` | destructure | the trial residuals | rename | `r_trial` |
| 184 | `Jt` | destructure | the trial Jacobian; reads as a transpose beside `J'` | rename | `J_trial` |
| 186 | `λ` | destructure | the damping, the docstring's `λ` | keep:spec | — |
| 188 | `iter` | for | the iteration number, read in the returns | rename | `iteration` |
| 196 | `A` | destructure | the normal matrix `JᵀJ`, read three lines below | rename | `JᵀJ` (the docstring's spelling; a legal identifier) |
| 196 | `g` | destructure | the gradient `Jᵀr` | rename | `Jᵀr` |
| 197 | `damp` | local | Marquardt's diagonal scaling | rename | `damping` |
| 198 | `nrm` | local | the current point's scaled residual norm | rename | `current_norm` (`_scaled_norm` is the function computing it) |
| 201 | `δ` | local | the step, the docstring's `δ` | keep:spec | — |

## `_report_trim!(diags::Vector{Diagnostic})` — line 232

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 232 | `diags` | param | the collected setup diagnostics | keep:roster | — |

## `_tviol(field::Symbol, reason::Symbol; kw...)` — line 237

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 237 | `kw` | keyword splat | the kind's remaining payload fields | roster? | `kw` (see Roster proposals) |

## `_check_decisions!(diags::Vector{Diagnostic}, p::TrimProblem)` — line 243

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 243 | `diags` | param | the collected diagnostics | keep:roster | — |
| 243 | `p` | param | the trim problem, read throughout the 28-line body | rename | `problem` (the name `trim!` passes it under) |
| 245 | `v` | for (destructure) | the problem field's value, `guess`, `lower` or `upper` | rename | `field_value` |
| 251 | `v` | for (destructure) | a bound NamedTuple, `lower` or `upper` | rename | `field_value` |
| 256 | `v` | for (destructure) | the problem field's value | rename | `field_value` |
| 263 | `k` | for | one decision name, read seven times over six lines and emitted as the payload's `key` | rename | `key` |

## `_check_tolerances!(diags::Vector{Diagnostic}, p::TrimProblem)` — line 279

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 279 | `diags` | param | the collected diagnostics | keep:roster | — |
| 279 | `p` | param | the trim problem | rename | `problem` |
| 285 | `k` | for | one residual name, emitted as the payload's `key` | rename | `key` |
| 286 | `v` | local | that residual's tolerance, read three times | rename | `tolerance` |

## `_check_floats!(diags::Vector{Diagnostic}, name::Symbol, v::NamedTuple)` — line 294

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 294 | `diags` | param | the collected diagnostics | keep:roster | — |
| 294 | `v` | param | the problem field's NamedTuple whose leaves must be `Float64` | rename | `field_value` (the name its callers bind, above) |
| 295 | `k` | comprehension | one field name | keep:glance | — |

## `_check_reads!(diags::Vector{Diagnostic}, p::TrimProblem, b::Build)` — line 305

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 305 | `diags` | param | the collected diagnostics | keep:roster | — |
| 305 | `p` | param | the trim problem | rename | `problem` |
| 305 | `b` | param | the build | rename | `built` (`build` is the package function, `build.jl:720`; `built` is what other groups propose for the same parameter) |
| 310 | `rviol` | destructure | the read set's `TapResolution` violations | rename | `read_violations` |

## `_check_residuals(r, tolerances::NamedTuple)` — line 319

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 319 | `r` | param | the residual return, a NamedTuple (§14.7's `NamedTuple{keys(tolerances)}(r)`) | keep:spec | — |
| 320 | `diags` | local | the collected diagnostics | keep:roster | — |
| 327 | `k` | comprehension | one residual name | keep:glance | — |

## `trim!(sim::Simulation{Float64}, problem::TrimProblem; baseline, t0::Real = 0.0, backend = …)` — line 384

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 384 | `sim` | param | the simulation | keep:roster | — |
| 385 | `t0` | keyword | the commit's origin; the init-service keyword (implementation.md's `t0`/`t₀` caveat) | keep:spec | — |
| 386 | `lc` | local | the lifecycle state loaded | rename | `status` (`lifecycle` is the function called on this line; `status` is the payload field it fills) |
| 392 | `b` | local | the build, read eleven times over 90 lines | rename | `built` |
| 393 | `diags` | local | the collected setup diagnostics | keep:roster | — |
| 400 | `K` | destructure | the decision names, `keys(guess)` | rename | `decision_names` (`names` is a Base function) |
| 400 | `RK` | destructure | the residual names, `keys(tolerances)` | rename | `residual_names` |
| 401 | `N` | local | the decision count, the seeded `Dual`'s width parameter | keep:typeparam | — |
| 402 | `tol` | local | the packed tolerance vector (§14.8's `tol`) | keep:spec | — |
| 402 | `k` | comprehension | one residual name | keep:glance | — |
| 405 | `ex_nom` | local | the nominal scratch executor | rename | `nominal_exec` |
| 411 | `r0` | local | the residual return at the guess, nominal | keep:spec | — |
| 417 | `r` | local | the packed residual vector of the bypassed problem | keep:spec | — |
| 417 | `k` | comprehension | one residual name | keep:glance | — |
| 423 | `TD` | local | the seeded scalar, `Dual{TrimTag,Float64,N}` | rename | `T` (the rules' numeric type; `T` is otherwise unbound in this scope) |
| 424 | `act` | local | the seeded activation; `activation` is the function called on this line | roster? | `act` (see Roster proposals) |
| 425 | `ex` | local | the seeded scratch executor, captured by `eval!` | rename | `seeded_exec` |
| 427 | `d_dual` | local | the guess as seeded decisions | keep:spec | — |
| 428 | `plan_d` | local | the shape-compiled plan at the seeded scalar | rename | `seeded_plan` |
| 429 | `reader_d` | local | the compiled reader at the seeded scalar | rename | `seeded_reader` |
| 444 | `eval!` | local function | §14.8's evaluation callback | keep:spec | — |
| 444 | `r`, `J`, `d` | param (`eval!`) | the residual vector, the Jacobian or `nothing`, the packed decisions | keep:spec | — |
| 445 | `d_nt` | local | the decisions as a seeded NamedTuple, the form `residuals` receives | rename | `decisions` (role beside the packed `d`) |
| 453 | `res` | local | the residual return reordered to `tolerances`' order | rename | `residuals` (unbound in this scope; `problem.residuals` is a field) |
| 454 | `i` | for | the residual index | keep:index | — |
| 455 | `v` | local | one residual as a `Dual`, read on the two lines below | rename | `residual` |
| 458 | `j` | for | the decision index | keep:index | — |
| 465 | `k` | comprehension | one decision name | keep:glance | — |
| 466 | `k` | comprehension | one decision name | keep:glance | — |
| 474 | `d0` | local | the starting decisions, projected into the box | keep:spec | — |
| 474 | `k` | comprehension | one decision name | keep:glance | — |
| 479 | `r` | local | the residual vector at the returned point | keep:spec | — |

## `trim!(sim::Simulation, ::TrimProblem; kw...)`, `trim!(::Simulation, other; kw...)` — lines 490, 493

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 490 | `sim` | param | the simulation | keep:roster | — |
| 490 | `kw` | keyword splat | the ignored keywords | roster? | `kw` |
| 493 | `other` | param | the non-problem second argument; the first method names that position `problem` | rename | `problem` (every method names its parameters alike) |
| 493 | `kw` | keyword splat | the ignored keywords | roster? | `kw` |

## `_scratch(sim::Simulation, ::Type{T}[, act::Activation{T}]) where {T}` — lines 502, 503

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 502 | `sim` | param | the simulation | keep:roster | — |
| 502 | `T` | type param | the scratch scalar | keep:typeparam | — |
| 503 | `T` | type param | the scratch scalar | keep:typeparam | — |
| 503 | `act` | param | the activation to compile at; `activation` is called by the one-line method above | roster? | `act` |

## `_establish_frozen!(ex::Executor, act::Activation{T}, nom::Executor, build::Build)` — line 514

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 514 | `ex` | param | the seeded scratch executor written | rename | `seeded_exec` |
| 514 | `act` | param | the seeded activation | roster? | `act` |
| 514 | `nom` | param | the nominal scratch executor read | rename | `nominal_exec` |
| 515 | `build` | param | the build; shares its name with `build(root; activations)`, `build.jl:720` | collision | `built` |
| 515 | `T` | type param | the seeded scalar | keep:typeparam | — |
| 516 | `ci` | for (enumerate) | the component index | keep:index | — |

## `_seeded(K::Tuple, v, ::Type{ForwardDiff.Dual{TG,Float64,N}}) where {TG,N}` — line 531

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 531 | `K` | param | the decision names | rename | `decision_names` |
| 531 | `v` | param | the decisions, a vector or the guess NamedTuple, indexed positionally | rename | `decisions` |
| 531 | `TG`, `N` | type param | the dual's tag and width | keep:typeparam | — |
| 532 | `i` | lambda | the decision index | keep:index | — |
| 533 | `j` | lambda | the partial slot | keep:index | — |

## `_saturated(K::Tuple, d::Vector{Float64}, lower::Vector{Float64}, upper::Vector{Float64})` — line 539

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 539 | `K` | param | the decision names | rename | `decision_names` |
| 539 | `d` | param | the returned decisions | keep:spec | — |
| 542 | `i` | for | the decision index | keep:index | — |

## `_verdict!(sim::Simulation, p::TrimProblem, baseline, solution::NamedTuple, r, tol, …, reader, t0)` — line 552

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 552 | `sim` | param | the simulation | keep:roster | — |
| 552 | `p` | param | the trim problem, read five times over 33 lines | rename | `problem` |
| 553 | `r` | param | the residual vector at the returned point | keep:spec | — |
| 553 | `tol` | param | the tolerance vector | keep:spec | — |
| 555 | `t0` | param | the commit's origin | keep:spec | — |
| 556 | `RK` | local | the residual names | rename | `residual_names` |
| 568 | `es` | local | the executor's event set | rename | `events` (unbound as a function in `src/`) |
| 569 | `i` | comprehension | the event index | keep:index | — |
| 578 | `k` | comprehension (enumerate) | one residual name | keep:glance | — |
| 579 | `i` | comprehension (enumerate) | the residual index | keep:index | — |

## Collisions

- `condition` (line 59, `TrimProblem`'s keyword): `condition(c; kw...)` at `src/conditions.jl:53`. Not called inside the one-line constructor. The keyword is §14.7's normative field name and the public spelling, so the proposal keeps it; the rule would otherwise ask for a rename the API cannot take.
- `reads` (line 59, `TrimProblem`'s keyword): `reads(; sels...)` at `src/readers.jl:125` (and the fallback at `src/roster.jl:61`). Not called inside the constructor. Kept for the same reason.
- `build` (line 515, `_establish_frozen!`'s parameter): `build(root::AbstractComponent; …)` at `src/build.jl:720`. Not called inside `_establish_frozen!`. Proposal `built`, matching the `b` → `built` renames at lines 305 and 392.

Near-collisions avoided in the proposals: `lifecycle` (`src/sim.jl:323`, called at line 386), hence `status`; `activation` (`src/build.jl`, called at lines 424 and 502), hence the `act` roster proposal; `names` (Base), hence `decision_names`/`residual_names`; `_scaled_norm`, hence `current_norm`.

## Roster proposals

- `act`: 3 sites here (lines 424, 503, 514); abbreviates "activation", whose full noun is the exported function `activation`, called in two of the three scopes. `Executor.act` is the field name (read at line 521). Other groups report the same proposal (`build.md`, `readers.md`).
- `kw`: 3 sites here (lines 237, 490, 493); abbreviates "keywords", Julia's own idiom for a keyword splat (`condition(c; kw...)` in `conditions.jl` uses it too).
- `maxiter`: 1 site (line 164); abbreviates "maximum iterations". It is a public keyword of `LevenbergMarquardt` and its field name, spelled as Optim.jl and NLsolve.jl spell it, so a rename is an API change.

## Questions

- The rules say `d` is a diagnostic in `diagnostics.jl` "and nothing elsewhere", but §14.7 and §14.8 name the trim decision vector `d` (`residuals(reads, d)`, `eval!(r, J, d)`, D-213 era text, decisions.md line 6839). This report classifies every decision `d` as `keep:spec`; the rule's wording should admit it or the spec should change.
- `TrimProblem`'s keywords `condition` and `reads` collide with package functions and are the normative field names (§14.7). The rules' one exception is `path`; `condition` and `reads` may need the same standing for keyword parameters that mirror a public field.
- `A`/`g` → `JᵀJ`/`Jᵀr` uses Unicode modifier letters, legal in Julia and the docstring's own spelling. If the user prefers ASCII, `normal_matrix` and `gradient`.
- `N` (line 401) is a local integer that becomes the `Dual`'s width parameter; classified `keep:typeparam`. The alternative is `n_decisions`, matching `solve`'s proposal, at the cost of a lowercase type argument.
- `_tviol` (line 237) is a helper function name, outside the brief's sites, but it abbreviates "trim violation" the way the locals here do. Flagged for the user; no proposal made.
- `out` (lines 475, 541), `raw` (448), `bad` (295, 327) and `off` (578) are three-letter words, not abbreviations, and were not flagged. `out` holds two different things in two functions (the backend's return in `trim!`, the saturation list in `_saturated`); `solved` would name the first by role if wanted.
