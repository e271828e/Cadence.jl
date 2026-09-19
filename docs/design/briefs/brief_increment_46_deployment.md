# Increment 46 — `Deployment`, `Schedule` and the grid diagnostics (§9.1, §9.2, §10.5, §12.7, Appendix B, Appendix C, D-187, D-250, D-254, D-256)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `cc01746` plus the commit that adds this brief.
Never `cd` elsewhere (`cd` is aliased to zoxide in the user's shell; use
absolute paths).

**Standing.** D-254 made deployment binding produce an artifact. The
`Deployment` is the build plus the grid parameters, the algorithm and the
three event parameters, scalar-free, carrying the `Schedule`, D-187's grid
diagnostics and its own warnings, and compared as a value. D-256 moved
`h`, `N_base`, `Δt_base`, the event trio, `sched`, `D`, `Φ` and `Δt` off
the `Simulation` onto it, and ruled that `DeploymentInvalid` names
deployment parameters only while the materialization's keywords validate
under `ArgumentInvalid`. The spec says all of it since `5502e1a`. The code
still binds inside `Simulation`'s constructor (`sim.jl:132–177`) through
`bind_schedule` (`build.jl:1270–1359`), keeps the schedule as a
`Vector` of named tuples on `sim.sched`, and has none of the grid
diagnostics: no leave-one-out factors, no prime attribution, no nearest
offsets, no derivation line, no `GridUtilization`. This increment is step 5
of `roadmap_pipeline_redesign.md`, items 19–21 and the deployment half of
item 28 of `notes_pipeline_redesign.md`.

**The pre-flight probe** (2026-09-19, `probe46.jl` in the session
scratchpad, plain Julia). Over the companion's pool `{1//500, 1//10,
1//150}`, `reduce(gcd, pool)` is `1//1500`; the leave-one-out factors are
`10`, `1`, `3`, all integers; `denominator(1//1500) = 1500 = 2²·3·5³`, with
`2²` and `5³` supplied by `1//500` alone and `3` by `1//150` alone;
`gcd(pool ∖ 1//150) = 1//500`, and the nearest multiples of it around
`1//150` are `3//500` and `4//500` (Julia prints the latter `1//125`).
`gcd(2//5, 2//7) = 2//35`, so `denominator(gcd(pool))` is the lcm of the
entries' denominators. `reduce(gcd, Rational{Int}[])` throws
`ArgumentError`, so the singleton pool needs a guard.

**Two stages, two commits, in this order.** The roadmap listed three; the
`Schedule` and the `Deployment` merge into one here, since a `Schedule` on
the `Simulation` with no `Deployment` around it would be an interim state
every test site would have to cross twice.

- **Stage 1, `Schedule` and `Deployment`.** The two types in a new
  `src/deployment.jl`, `bind_schedule` moved into the `Deployment`
  constructor, `Simulation(deployment, T; kw...)` as the materialization,
  the two sugar forms over it, every reader of the moved fields re-pointed,
  `==` and `hash` by value, `warnings` on the deployment and the
  simulation, the materialization keywords under `ArgumentInvalid`.
- **Stage 2, the grid diagnostics.** The attribution substrate on the
  deployment, the refusal payloads carrying it, the derivation line and
  `GridUtilization` on the deployment's list.

Both stages touch `sim.jl`, so the routed subset is the table's last row,
all of it. The gate is the reviewer's. `implementation.md`'s "Running the
suite" (113–164) is the one home of test policy; this brief does not
restate it.

**Read, in `docs/design/spec.md`:** §9.1's "The `Deployment` constructor",
3159–3230, and "Where a build warning lives", 3231–3241. §9.2 from
"Deploying and materializing are two steps", 3251–3262, and from
"`Structure`'s timing tables", 3290–3386. §10.5's "The base grid",
4400–4430, and "`Δt` has a single source of truth", 4685–4715. §12.7's
header paragraph, 7392–7410. Appendix B's `Deployment` entry, 10715–10754,
the `Simulation(deployment, T)` entry, 10755–10779, and the sugar forms,
10780–10783. Appendix C's `logged` policy, 11042–11050, and the rows for
`DeploymentInvalid` (11246–11252), `GridUtilization` (11317–11322) and
`ArgumentInvalid` (11338–11343). The glossary entries at 11831–11836 and
11908–11912. In `docs/design/decisions.md`: **D-187 (6509–6550)**, D-250
(9157–9218), **D-254 (9378–9427)**, **D-256 (9508–9551)**. In
`docs/design/companions/sample_time_proposal.md`: §7.4 and §8, 631–745,
the worked case the numbers above come from; the spec wins where they
differ.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (113–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/diagnostics.jl` (20), `src/executor.jl`
  (24), `src/build.jl` (25), `src/sim.jl` (28), `src/stepper.jl` (29),
  `src/trace.jl` (32), `src/trim.jl` (37), `test/fixtures.jl` (38),
  `test/imports.jl` (39).
- **"Authoring caveats" in full (61–111)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–41), the
umbrella for increments 43–48. This increment delivers its D-254 sentence
(33–36) and the "`Deployment`'s own list waits on increment 46" clause
(32).

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the decisions and this brief disagree, stop and say so in the
report rather than improvising. Where a site does not hold what the brief
claims, report it rather than inventing a substitute.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show <tip>:path`. Never run the suite in the background. The build
tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset. A REPL check of a fixture
defined in a `test_*.jl` file loads `test/repl.jl`, `using Test, Logging`
and `test/utils.jl` (`single`, `fed`, `failure`, `carried`), then
reproduces the fixture. The audit refresh under
`docs/reports/20260915_audit` sits uncommitted on purpose: never
`git add -A`; add each path by name.

**What this increment leaves to increment 47.** The trace header keeps its
`deployment` named tuple (`trace.jl:43–46`, `_capture_header` at 287–292,
`_check_header!` at 349–358); its reads move to the deployment's fields
and nothing else changes there. Increment 47 replaces the block with the
`Deployment` itself when the header loses its policy. `t_end`, `stop_on`
and `chunk_size` stay keywords of the materialization until 47's
`StopPolicy` and executor regroup take them. `join_timeout` stays a
`Simulation` field until 47 moves it into `Control`. `RunPolicy` is
untouched.

## Stage 1 — `Schedule` and `Deployment`

Files: `src/deployment.jl` (new), `src/Cadence.jl`, `src/build.jl`,
`src/sim.jl`, `src/trace.jl`, `src/localization.jl`, `src/trim.jl`,
`src/conditions.jl`, `src/diagnostics.jl`, `test/imports.jl`,
`test/test_discrete.jl`, `test/test_lifecycle.jl`, `test/test_devices.jl`,
`test/test_log.jl`, `test/test_localization.jl`, `test/test_bindings.jl`,
`test/test_failures.jl`, `test/test_trim.jl`, `test/test_diagnostics.jl`,
`test/test_conditions.jl`, `test/test_assembly.jl`, `test/test_readers.jl`,
`test/test_continuous.jl`, `docs/design/implementation.md`,
`docs/design/pending.md`.

### The types

`src/deployment.jl` is included after `stepper.jl` and before `sim.jl`
(`Cadence.jl:21–22`): the constructor checks `algorithm <: AbstractStepper`
(`stepper.jl:21`), which `build.jl` cannot see, and `sim.jl` materializes
the type. Section 6 of `build.jl` (1238–1359, `_exact`, `_as_int` and
`bind_schedule`) moves there whole; `build.jl`'s docstrings that say the
grid parameters are "`Simulation`'s" (`Build`'s at 640–648 and 681–682)
say "the `Deployment`'s".

```julia
"""
One discrete component's row of the schedule (§9.2): its `(D, Φ, Δt)` with
the anchor it resolved against (0 is the base grid `A₀`) and its declaration
provenance, the `sample_times` links met on the way down.
"""
struct ScheduleRow
    path::String
    anchor::Int
    D::Int
    Φ::Int
    Δt::Float64
    provenance::Vector{RateLink}
end

"""
One rate scope's row (§9.2, §10.5): the assembly an explicit `sample_times`
key opened, resolved to its own `(Dₛ, Φₛ)` by the same multiply-add its
members use.
"""
struct ScopeRow
    path::String
    key::Symbol
    anchor::Int
    D::Int
    Φ::Int
end

"""
The typed schedule (§9.2, §10.5, D-254): one row per discrete component in
walk order, the rate-scope rows, and the per-component `D`, `Φ` and `Δt`
vectors the executor compiles over, every tier included (a continuous
component holds `(1, 0, 0.0)`). The single source of truth for `Δt`.
"""
struct Schedule
    rows::Vector{ScheduleRow}
    scopes::Vector{ScopeRow}
    D::Vector{Int}
    Φ::Vector{Int}
    Δt::Vector{Float64}
end
```

`rows` is today's `sched` with two columns added. `anchor` is
`structure.triples[ci][1]`; `provenance` is `structure.provenance[ci]`
(the vector itself, not a copy; the structure is immutable). `scopes` is
one row per `structure.scopes` entry, its `(D, Φ)` from its `triple` by the
component formula (`Dₛ = m·Dₐ`, `Φₛ = Φₐ + c·Dₐ`). `RateLink` and
`RateScope` are `assembly.jl:718` and `723`.

```julia
"""
The deployment (§9.1, §9.2, D-254): the build plus the grid parameters,
the algorithm and the three event parameters, scalar-free, carrying the
`Schedule` the constructor built, the grid attribution of §9.2 and its own
warnings. `Simulation` materializes it at a scalar type; one deployment
backs many. Two deployments compare as values (§12.7).
"""
struct Deployment
    build::Build
    h::Float64
    N_base::Int
    Δt_base::Float64
    algorithm::Type          # <: AbstractStepper, materialized at Simulation construction (D-227)
    firing_budget::Int
    localization_tol::Float64
    localization_budget::Int
    schedule::Schedule
    grid::GridReport         # stage 2; stage 1 leaves the field out
    warnings::Vector{Diagnostic}
end
```

Stage 1 builds the struct without `grid`; stage 2 adds the field. The
`Float64` fields keep today's representation and every reader's
(`trace.jl:43`, `localization.jl:14`, `sim.jl:210`); the exact rationals
the arithmetic ran on are stage 2's report.

### The constructor

```julia
Deployment(b::Build; h = nothing, N_base = nothing, Δt_base = nothing,
           algorithm = RK4, firing_budget = 4, localization_tol = 1e-6,
           localization_budget = 8) → Deployment
```

The body is today's constructor split at the seam. The keyword checks for
`algorithm`, `firing_budget`, `localization_tol` and `localization_budget`
(`sim.jl:138–145`) come first into one `diags` list; then `bind_schedule`
records into the same list; then the one throw per call (§9.1, D-229),
`DiagnosticError(diags)` with no warnings tail in stage 1 (stage 2 threads
the list). `bind_schedule` returns a `Schedule` in place of its named
tuple's `sched`, `D`, `Φ`, `Δt` fields; keep its `h`, `N_base`, `Δt_base`
return beside it or return the four and let the constructor assemble. Its
docstring's "per `Simulation`" wording becomes "per `Deployment`".
`warnings` is an empty `Diagnostic[]` in stage 1.

The `Deployment` docstring takes over the grid half of `Simulation`'s
(`sim.jl:51–130`): the three sources paragraph, `algorithm`,
`firing_budget`, the localization pair. Proof-read what you move; it is
the docstring users read.

**`==` and `hash`.** Two deployments are equal when `h`, `N_base`,
`Δt_base`, `algorithm`, the event trio and the schedules are equal;
`Schedule` equality is field-wise over its five vectors, `ScheduleRow` and
`ScopeRow` are immutable structs of `isbits` and `String` fields plus the
provenance vector, so the default `==` on them is by value already and
only `Schedule` and `Deployment` need methods. **The build is not
compared**: §12.7's header check is the consumer, and a what-if replay
re-drives a recording against a modified model of the same structure, so
`==` on the build would refuse what the spec admits. Say so in the method's
comment. `warnings` is not compared either; it is a function of the rest.
Define `Base.hash` consistently over the compared fields.

**`warnings`.** `warnings(d::Deployment) = d.warnings` beside
`warnings(::Build)` (`build.jl:890–897`, whose docstring's last sentence
retires), and `warnings(sim::Simulation) =
vcat(warnings(sim.deployment.build),
warnings(sim.deployment))` in `sim.jl`, with a docstring citing D-250's
concatenation rule and §11.8 for where status-side warnings live.

### The materialization

```julia
Simulation(d::Deployment, ::Type{T} = Float64; join_timeout = 5.0, t_end = Inf,
           stop_on = (), trace = true, log = true, log_every = 1,
           log_max = 65536, chunk_size::Int = 16) → Simulation{T,E,M}
```

`Simulation{T,E,M}` (`sim.jl:19–49`) loses `build`, `h`, `N_base`,
`Δt_base`, `firing_budget`, `localization_tol`, `localization_budget`,
`sched`, `D`, `Φ`, `Δt` and gains `deployment::Deployment` in `build`'s
place. **The build is held once, through the deployment** (D-256, §12.1):
`sim.build === sim.deployment.build` would be an invariant with no
enforcer. Every `sim.build` reader spells `sim.deployment.build`; no
accessor, since `build` is the entry point's name and a `build(sim)`
method would give one name two meanings (D-122). The body validates its own keywords, resolves the stop faces
against the activation, throws its one collection, then compiles:
`compile(b, act, d.schedule.D, d.schedule.Φ, d.schedule.Δt; chunk_size)`
and `d.algorithm(T, length(ex.xbuf))`.

The two sugar forms, each *defined as* the composition:

```julia
Simulation(b::Build, ::Type{T} = Float64; h = nothing, N_base = nothing,
           Δt_base = nothing, algorithm = RK4, firing_budget = 4,
           localization_tol = 1e-6, localization_budget = 8, kw...) where {T} =
    Simulation(Deployment(b; h, N_base, Δt_base, algorithm, firing_budget,
                          localization_tol, localization_budget), T; kw...)
Simulation(root::AbstractComponent, ::Type{T} = Float64; kw...) where {T} =
    Simulation(build(root), T; kw...)
```

The suite's 531 `Simulation(…; h = …)` call sites are untouched by this.

**The materialization's keywords validate under `ArgumentInvalid`**
(D-256, Appendix C 11338–11343): `join_timeout`, `trace`, `log`,
`log_every`, `log_max` and `t_end` become
`ArgumentInvalid(call = :Simulation, reason = :range, argument = name,
value = v)`, collected into the materialization's one throw beside
`StopFaceInvalid`. `_t_bound_diag` and `_t_bound` (`sim.jl:188–193`) build
that kind, the fail-fast form taking the site (`:run!` at `sim.jl:924`,
`:replay!` at 799) as its `call`. `message(::ArgumentInvalid)`
(`diagnostics.jl:1693`) gains one arm per argument, each carrying the
constraint text and section its `_dep_constraint`/`_dep_section` line
carried (`diagnostics.jl:1218–1242`); those lines then leave
`DeploymentInvalid`'s tables, whose parameter set is the spec's row
(11246–11252). `ArgumentInvalid`'s `call` comment at 1685 already lists `:run!` and
`:replay!`; add `:Simulation`.

One observable changes: `Simulation(b; log_every = 0)` on a build with no
`h` threw one collection carrying `:log_every` and `:h`
(`test_discrete.jl:265–267`). Now the deployment refuses first, on `:h`
alone, and `log_every` is refused by a separate materialization call. The
test asserts both, each on its own call. `test_lifecycle.jl:164–165`'s
`kinds(err) == [DeploymentInvalid, StopFaceInvalid]` on
`Simulation(m; stop_on = ("nope",))` with no `h` likewise becomes a
deployment refusal on `:h` alone; assert the stop-face refusal on a
deployment that binds, joined with a bad `t_end` in one materialization
throw, `kinds(err) == [ArgumentInvalid, StopFaceInvalid]`.

### Re-pointing the readers

Read off the tree, not from memory; the counts below are from `cc01746`.

- `src/sim.jl`: `sim.h` at 210 and 1232, `sim.firing_budget` at 477,
  `sim.N_base` at 1087, the constructor's `_stop_faces` site.
- `sim.build` (20 sites in `src/`, 31 in `test/`, `grep -rn "\.build\b"`
  minus `src/build.jl`): `sim.jl` 556, 655–658, 1124, 1146–1147, 1164,
  1651–1654, 1663; `trim.jl` 392, 426, 502, 504; `conditions.jl` 834–835;
  `trace.jl` 269; tests in `test_conditions.jl` (9), `test_assembly.jl`
  (9), `test_readers.jl` (9), `test_discrete.jl`, `test_continuous.jl`,
  `test_failures.jl`, `test_trim.jl` (1 each).
- `src/trace.jl`: `_capture_header` at 287–292 (`Δt_base`, `h`, `N_base`,
  `localization_tol`, `localization_budget`, `firing_budget`; `algorithm`
  keeps reading `nameof(typeof(sim.stepper))` or becomes
  `nameof(d.algorithm)`, equal either way), `_check_header!` at 350–354.
- `src/localization.jl`: `sim.h` at 14, 30, 192; `sim.localization_budget`
  at 72, 79; `sim.localization_tol` at 192.
- `src/trim.jl:504`: `sim.D`, `sim.Φ`, `sim.Δt` become the schedule's.
- Tests reading the moved fields (26 hits, all listed by
  `grep -rn "\.\(sched\|N_base\|Δt_base\|firing_budget\|localization_tol\|localization_budget\)\b\|sim\.h\b\|\.D\b\|\.Φ\b\|\.Δt\b" test/*.jl`
  minus `test_diagnostics.jl`): `test_discrete.jl` at 145–146, 155–156,
  166–169, 205, 221, 238–240, 308–309, 353–354, `test_bindings.jl:163`,
  `test_localization.jl` 60, 73, 129, 130, `test_lifecycle.jl:176`,
  `test_failures.jl:456`, `test_trim.jl:482`. The `sched` sites read
  `sim.deployment.schedule.rows`; `s3.sched == s2.sched == s4.sched` at
  240 becomes `s3.deployment == s2.deployment == s4.deployment`, which is
  the value equality's first test.
- `test_trace.jl:93–94` reads the header block and stays as it is.
- Tests whose kind changes: `test_devices.jl:410, 413` (`join_timeout`),
  `test_log.jl:142–148` (the retention keywords), `test_lifecycle.jl:140–143`
  (`t_end` at both sites: `dc.argument == dr.argument == :t_end`, the
  constructor's `call === :Simulation`, `run!`'s `:run!`).

### Tests

`test_discrete.jl`'s `discrete_deployment` (228–312) is the home. Beside
the re-pointed assertions:

- `Deployment(b; h = 1//500)` alone is a `Deployment`; its `schedule.rows`
  carry the worked example's paths, `(D, Φ, Δt)`, anchors (`0, 0, 1`) and
  a provenance chain per row (`MultiRate`'s `gnss` row's single link has
  `entry isa Absolute`; `fcs/outer`'s has the `fcs` link then its own).
  Check `MultiRate`'s declaration in `test/fixtures.jl` first and assert
  what it declares.
- The scope rows: `MultiRate` opens `fcs` under a key, so one `ScopeRow`
  at `("fcs", :fcs, 0, D, Φ)` with the values the fold gives it; assert
  them off the structure's `scopes` triple by hand.
- Equality: two deployments of one build with the same keywords are `==`
  and hash equal; differing in `N_base`, `algorithm` or `firing_budget`
  are not; two builds of the same model deploy `==` (the build is not
  compared).
- `Simulation(Deployment(b; h = 1//500), Float64)` runs the worked example
  as `Simulation(b; h = 1//500)` does; `Simulation(d, D8)` materializes the
  same deployment at a `Dual`, and `sim.deployment === d`.
- `warnings(d)` and `warnings(sim)` are empty vectors here; the
  concatenation is asserted in stage 2 with a producer on each side.
- `test_diagnostics.jl`'s rendering testset (occurrences at ~400–420 and
  ~511): one occurrence per new `ArgumentInvalid` arm, and the
  `DeploymentInvalid` occurrences stay.

### Bookkeeping

- `test/imports.jl`: `Deployment`, `Schedule`, `ScheduleRow`, `ScopeRow`.
- `implementation.md`: a new row for `src/deployment.jl` after
  `src/stepper.jl`'s; `build.jl`'s row drops "deployment binding (one
  throw per `Simulation` call)"; `sim.jl`'s row says the materialization
  and the two sugar forms, `Simulation` holding the build through its
  `deployment`; `diagnostics.jl`'s row notes `ArgumentInvalid`'s
  materialization arms; `trace.jl`'s row stands.
- `pending.md`'s umbrella bullet: the D-254 sentence records "delivered by
  increment 46" for the artifacts, with the grid diagnostics still owed
  until stage 2 lands; stage 2 then closes it.

## Stage 2 — the grid diagnostics

Files: `src/deployment.jl`, `src/diagnostics.jl`, `test/imports.jl`,
`test/test_discrete.jl`, `test/test_diagnostics.jl`,
`docs/design/implementation.md`, `docs/design/pending.md`.

### The substrate

Everything D-187 asks for is a function of the constraint pool alone, so
one report is computed once per constructor call before the `Δt_base`
branch, carried on the deployment, and handed to every refusal that names
the grid.

```julia
"""
One constraint-pool entry (§9.1, §9.2): an anchor's period or its nonzero
offset, with the anchor's provenance, its leave-one-out refinement factor
`r_p = gcd(pool ∖ p) / gcd(pool)` and, for an offset that drives, the
nearest offsets on the grid the rest of the pool supports.
"""
struct GridEntry
    kind::Symbol                          # :period | :offset
    value::Rational{Int}
    anchor::Int                           # 1…K, into the structure's anchor table
    provenance::String                    # the anchor's declaring scope and key
    factor::Int                           # r_p ≥ 1
    alternatives::Vector{Rational{Int}}   # a driving offset's nearest non-refining neighbours; else empty
end

"""
The grid attribution (§9.2, D-187): the pool, the coarsest admissible
`Δt_base` and each prime power of its denominator traced to the entries
supplying it. A pure function of the structure's anchors, printed by the
refusal path's suggestion and the derivation path's line alike.
"""
struct GridReport
    pool::Vector{GridEntry}
    admissible::Union{Nothing,Rational{Int}}   # gcd(pool); nothing for an empty pool
    primes::Vector{@NamedTuple{prime::Int, power::Int, suppliers::Vector{Int}}}  # indices into pool
end
```

The rules, each checked in the probe:

- **The pool** is today's (`build.jl:1283`), one entry per anchor period
  and one per nonzero offset, in anchor order, periods first as today.
- **`admissible`** is `reduce(gcd, values)`, `nothing` when the pool is
  empty.
- **The factor** for entry `p` is `gcd(pool ∖ p) / admissible`, an
  integer (assert with `_as_int` and an `InternalInvariant` on `nothing`).
  A singleton pool gives every entry factor 1, by convention, since the
  empty reduction has no value.
- **The primes** factor `denominator(admissible)` by trial division (no
  `Primes` dependency; the integers are grid denominators); `suppliers`
  are the pool indices whose `denominator(value)` is divisible by
  `prime^power`.
- **The alternatives** exist for an offset entry with factor above 1:
  with `g′ = gcd(pool ∖ p)`, the neighbours `floor(τ/g′)·g′` and
  `ceil(τ/g′)·g′`, the upper one dropped when it reaches the anchor's
  period `T` (the fold requires `0 ≤ τ < T`, `assembly.jl:819`); `0` stays,
  since declaring no offset is a repair.

### The refusals carry it

`DeploymentInvalid` (`diagnostics.jl:1207–1216`) replaces its `admissible`
field with `grid::Union{Nothing,GridReport}`, set on the `:unanchored`,
`:anchor_period` and `:anchor_offset` arms (the three refusals whose
remedy is a `Δt_base` the pool admits). The message's `_dep_admissible`
becomes the suggestion: the coarsest admissible value, the admissible set
as `gcd(pool)/k`, and one clause per driver (`factor > 1`), each as
provenance, kind, value and `×factor`, with a driving offset's
alternatives after it ("declaring `3//500` or `4//500` keeps
`Δt_base = 1//500`"). No drivers, no clause. Keep the message a single
line; the rendering testset asserts it.

`test_discrete.jl:288–292`'s `d.admissible == 1//50` becomes
`d.grid.admissible == 1//50`.

### The derivation line and `GridUtilization`

On the derivation path (`Δt_base === :derive`, bound to `admissible`),
after the schedule is built:

- **The line, always.** `@info` one line: the derived value, and its
  drivers with factors, or "no entry refines another" when every factor is
  1. Presentation, not a home (§9.1's rule, D-250).
- **The advisory, when refined.** With `u = minimum(D over the discrete
  rows)`, `u > 1` pushes `GridUtilization` onto the deployment's
  `warnings`; `u == 1` is no information and stays silent. The
  constructor logs each warning once at return through `logline`, as
  `build` does (`build.jl:724`); with no user body running inside it the
  constructor pushes to its own list directly rather than through
  `_warn!`.

```julia
"§9.1, §9.2: the derived grid is finer than the fastest declared work."
Base.@kwdef struct GridUtilization <: Diagnostic
    Δt_base::Rational{Int}
    utilization::Int                     # min_i Dᵢ over the discrete rows
    fastest::String                      # the path attaining it
    drivers::Vector{GridEntry}           # the entries with factor > 1
end
severity(::GridUtilization) = :warning
```

Message shape: "Δt_base derived as 1//1500 s: the grid is 3× finer than
the fastest declared work (`sensors/imu` at D = 3) — drivers: … (§9.2)".
`path(::GridUtilization)` stays the default `""`; it is a deployment-level
fact. The kind joins `test_diagnostics.jl`'s `warning_kinds` set (555) or
the kinds loop fails on its severity, and gets a rendering occurrence with
two drivers, one of them an offset with alternatives.

### Tests

In `test_discrete.jl`'s derivation testset (295–312), built inline from
`Group` and `TickCounter` with `rates`, no new fixture types:

- The companion's case at `Hz(500)` and `Absolute(Hz(10), 1//150)` under
  `Δt_base = :derive`: `Δt_base == 1//1500`, `D == [3, 150]`, the
  report's factors `[10, 1, 3]` in pool order, primes
  `[(2, 2, [1]), (3, 1, [3]), (5, 3, [1])]`, the offset's alternatives
  `[3//500, 1//125]`, one `GridUtilization` on `warnings(d)` with
  `utilization == 3`, `fastest` the 500 Hz path and two drivers, logged
  once at return (`@test_logs (:info, r"derived") (:warn, r"^GridUtilization")`
  around the constructor, in that order; check the order the code emits
  and assert that).
- The same pool without the offset: factors all 1, no warning, the info
  line alone.
- The existing case at 307–309 (`Absolute(Hz(50), 1//100)`, `Δt_base ==
  1//100`, `u = 2`): now warns; wrap it in `@test_logs` and assert the
  warning.
- The refusal at 288–292 carries the report; a refusal on a driving
  offset (`h = 1//500` against `Absolute(Hz(10), 1//150)`) carries the
  alternatives.
- `warnings(sim)` concatenates: a producer on each side. `EmptySelection`
  (`test_build.jl:1639–1646`, two continuous `Gain` children) cannot
  derive a grid, so the test goes beside it in `test_build.jl`'s
  `build_warnings`, on a test-local type `EmptySelectionRated` (grep the
  name across `test/` first; it is free at `cc01746`): `EmptySelection`'s
  shape plus one `TickCounter` child under
  `sample_times = (; c = Absolute(Hz(50), 1//100))`. Deployed under
  `Δt_base = :derive`, `warnings(sim)` lists the build's
  `EmptyFaceSelection` first and the deployment's `GridUtilization`
  second, `warnings(sim.deployment.build)` and `warnings(sim.deployment)`
  holding one each.

### Bookkeeping

- `test/imports.jl`: `GridEntry`, `GridReport`, `GridUtilization`.
- `implementation.md`: `deployment.jl`'s row gains the report, the
  suggestion and the advisory; `diagnostics.jl`'s row gains
  `GridUtilization` and the `grid` payload.
- `pending.md`: the umbrella bullet's D-254 sentence reads "delivered by
  increment 46" in full, and the "`Deployment`'s own list waits on
  increment 46" clause says increment 46 delivered it.

## Report format

For each stage: the commit hash and subject; the routed run's command and
its summary line; every deviation from this brief with its reason; every
place a site did not hold what the brief claims; open questions for the
user. Increment 47 reads the stage-1 report for the header and the
materialization keywords, so name their final shapes explicitly.
