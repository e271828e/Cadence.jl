# Increment 21 brief — trim (§14.7–§14.8), with the executor extraction, the read-selector family, the specialized `apply!` register and `capture`

> **Historical record.** Written before the 2026-08-29 spin-off, so the paths
> below are the old layout: the worktree `~/.julia/dev/Flight.jl-core-redesign-2`
> is now this repository, `prototypes/kernel/` is its root, `README.md`, `MAP.md`
> and `NOTES.md` are `docs/kernel_guide.md`, `docs/kernel_map.md` and
> `docs/kernel_notes.md`, and the design documents live in `docs/`.

You are implementing increment 21 of the kernel prototype in
`/Users/miguel/.julia/dev/Flight.jl-core-redesign-2/prototypes/kernel` (a git
worktree, branch `core-redesign-2`; never `cd` elsewhere — `cd` is aliased to
zoxide in the user's shell, use absolute paths). The prototype is the
implementation's seed, built to keepable standards; it follows the spec
closely, and its test battery never goes red across an increment.

**Stance: conservative reading.** Build what the spec and this brief say.
Where the spec is silent, choose the simplest thing that does not foreclose the
spec'd shape, and record the choice in your friction report. Where the spec and
this brief disagree, or where following either would produce something wrong,
**do not deviate silently and do not take the deviation yourself** — build the
literal reading if it is buildable, and flag it in the friction report;
deviations are settled with the user. The friction report is evidence; it has
reversed adjudications before.

## Read first

1. `prototypes/kernel/README.md` — the whole file: what is real, the absences,
   the stand-ins rule (**normative and transactional**: every construct a reader
   could mistake for the design's is accounted for in the "what is real" table,
   the absence list, or a stand-in row, in the same commit) and the authoring
   caveat (test fixtures at top level).
2. `prototypes/kernel/NOTES.md` — the "Increment 18" and "Increment 20"
   paragraphs and the tail of the property bullets, for the register your own
   narrative and bullets are written in.
3. Spec sections, in `docs/notes/design/framework_spec.md` (headings
   `### 14.n …`): §14.1, §14.3, §14.4 (both application registers and the
   read-selector family), §14.5 (boundary zero; the "Trim is untouched" and
   "commit-fired handler" bullets), §14.6, §14.7, §14.8 in full — including the
   paragraph "**The frozen cells are established, not probe-seeded**" added by
   D-213 today — and §9.4's "Each activation probes exactly the function set it
   can execute", §9.5's first two paragraphs, §9.6. Appendix C rows
   `UninitializedInputs`, `TrimProblemInvalid`, `TrimCommitEvents`,
   `TrimCommitResiduals`. Glossary entries `executor`, `scratch`, `lens`,
   `selector`, `capture`.
4. Decision entries in `docs/notes/design/framework_decisions.md`: D-066,
   D-205, D-213.
5. Source: `src/conditions.jl` (all of it — the algebra, `resolve_condition`,
   `assert_total`, the dynamic-walk `apply!`), `src/sim.jl` (the `Simulation`
   struct and constructor, `evaluate!`, `boundary_zero!`, `_round!`,
   `event_phase!`, `init!`, `state`, `port`, `modes`), `src/build.jl` §5–§7
   (`Activation`, `Build`, `activation`, `establish_defaults!`, `compile`),
   `src/store.jl`, `src/executor.jl` (`EventSet`, `Establish`), `src/stepper.jl`,
   `src/localize.jl`, `src/library.jl` (the `condition` idiom, `Plant`,
   `DiscreteIntegrator`, `sampled_loop`, `Trigger`, `ZOH`), `test/utils.jl`,
   `test/test_conditions.jl`.

Run the suite before touching anything and record the counts:
`julia --project=. test/runtests.jl` from `prototypes/kernel` (at tip: 165
testsets / 903 assertions).

## Scope

**In.** Four stages, one commit each, the suite green after each:

- **Stage 0 — the `Executor{T}` extraction.** The compile product becomes a
  named type; `Simulation` holds one.
- **Stage 1 — the read-selector family, the compiled reader, `capture`.**
- **Stage 2 — the specialized `apply!` register**: `Getter{P}` lenses, baked
  converters, the folded shape check.
- **Stage 3 — `TrimProblem`, `reads`, the `solve` seam with an in-house
  Levenberg–Marquardt, `trim!`, `TrimReport`, the `Trim*` kinds.**

**Out, recorded in the README's absence list** (add these): §14.9 mounting
(`at` over problems and read sets); the derivative-free fallback
(`NLoptBackend`, a package extension) and the nominal-activation evaluation
loop it would run on; linearization (§14.10); `ReadBindingUnresolved` — the
prototype's bindings do not take selectors, so no snapshot-bound reader can
name a store selector yet; the §13.2 structured diagnostic carrier (already
absent: every kind here is a `BuildError` whose message starts with the kind
name, or an `@warn` whose message starts with it, the house framing).

## Stage 0 — `Executor{T}`

**What.** `compile` currently returns a NamedTuple of fresh buffers and the
phase bodies closed over them. That product is the spec's *executor* (§9.7,
glossary): the compiled execution form of the schedule over its buffers, at one
scalar. Give it a type, in `src/build.jl` beside `compile`:

```julia
struct Executor{T,S,B,CL,EV}
    act::Activation{T}     # the layout and probe products it was materialized from
    store::S               # the signal table: cells and root inputs
    xbuf::Vector{T}        # continuous state, the flat buffer (§7.1)
    ẋbuf::Vector{T}        # its derivative — integrator scratch (§7.5)
    sstores::Vector{Any}   # discrete state stores, by component index
    mstores::Vector{Any}   # mode stores, by component index
    clock::CL
    bodies::B              # the phase bodies, closed over the buffers above
    events::EV             # the compiled event set, likewise (nominal only)
end
```

`compile(b, act, D, Φ, Δt; chunk_size)` returns one. `Simulation` drops its
`store`, `xbuf`, `ẋbuf`, `clock`, `bodies`, `events`, `sstores`, `mstores`,
`layout` and `flat` fields for one `exec::Executor` field (`layout` is
`exec.act.layout`, `flat` is `build.flat`; keep `build`). Every `sim.xbuf`,
`sim.store`, `sim.bodies`, … in `src/` and `test/` becomes `sim.exec.xbuf` and
so on — an `rg` sweep, mechanical. Do **not** add `getproperty` forwarding: the
call sites should show the new type.

The three evaluation entry points move onto the executor, the `Simulation`
forms delegating:

```julia
evaluate!(ex::Executor)            # sweep_1, sweep_2, rhs — as today
_round!(ex::Executor, tick)        # the three arities, as today
apply!(ex::Executor, plan::ConditionPlan)   # the dynamic walk, as today
```

The stepper seam (`step!(m, sim, h)`) and the frame loop keep reading through
`sim` — whether they take `sim.exec` or `sim` is your call, but the loop's path
must not change: the §7.5 zero-allocation gates in `test_continuous.jl` and
the other `@ballocated` assertions are the acceptance test for this stage. Add
a one-line docstring to `Executor` in the register the file uses, and one
sentence in `Simulation`'s docstring saying it owns its nominal executor and
that services instantiate their own (§9.2: "every buffer set has exactly one
owner").

Commit: `Extract the compile product as Executor{T}, the buffer set and bodies a Simulation owns and a service instantiates`.

## Stage 1 — selectors, the compiled reader, `capture`

New file `src/readers.jl`, included after `conditions.jl` in `runtests.jl`.

**The selector family (§14.4), closed.** Five inert values with a deliberate
`get_` prefix, constructed by plain functions:

```julia
get_state(path::AbstractString, field::Symbol[, i])   # a declared x or s field
get_deriv(path::AbstractString, field::Symbol[, i])   # the derivative of a declared x field
get_output(path::AbstractString, field::Symbol[, i])  # a declared output port
get_input(face::Symbol)                                # a root input face
get_face(name::Symbol)                                 # a root-exported output face
```

`i` is an optional index applied to the read value (`v[i]`); absent, the whole
value is read. The read set is `reads(; name = selector, …)`, a NamedTuple of
selectors wrapped in one type (so a stray NamedTuple is refused with the same
kind of directive `combine` gives for its misuse, not a `MethodError`).

**Resolution → a compiled reader.** `compile_reads(rs, b::Build, T) → Reader`
validates every selector in §13.1's collecting register and compiles the
survivors:

- `get_state`: the path resolves to a component (did-you-mean over `flat.paths`
  as `_component` does — reuse it); the field is declared in its `init_x`
  (continuous) or `init_s` (discrete); the read is a reconstruct of that leaf
  out of `xbuf` at the baked offset, or `getfield` of the `s` store's value.
- `get_deriv`: as `get_state`, but the field must be an `init_x` field — a
  discrete `s` has no derivative, and the refusal says so — and the read comes
  from `ẋbuf`.
- `get_output`: the field is a key of the component's declared output types at
  this activation; the read is `gather(store, layout.addr[(path, field)])`.
- `get_input`: the face is in `flat.root_inputs`; the read is the root cell.
- `get_face`: the name is a root output face (`flat.out_faces` with path `""`);
  the read is its producer's cell.
- `i`: checked against the resolved value's declared type only in that
  `getindex` must apply (a scalar refused); do not over-engineer this.

Violations are collected as strings prefixed `ReadResolution:` (with the
selector spelled as authored, the offending name, and the list-in-hand); a
standalone `compile_reads` throws one `BuildError` listing them, and `trim!`
(Stage 3) folds the same list into its `TrimProblemInvalid`. Factor so the
collecting part is shared.

The reader is the **gather twin** (§14.4): `gather(r::Reader, ex::Executor) →
NamedTuple` named as the `reads` were, type-stable and allocation-free for
scalar and `SVector` leaves (a `@generated` or tuple-recursive walk over the
reader's compiled entries; the entries' types carry the leaf types). The reader
resolves only against an `Executor` — the source rule: store selectors reach
live stores, and the executor is the only live-store holder this prototype has.

**`capture(sim) → (condition, t)`** (§14.1, §14.10, glossary). Legal in
`initialized` and `stopped`; `built` is `ServiceLifecycle` ("committed,
boundary-consistent stores" do not exist yet), `running` and `errored` the
same kind, in the wording `init!` uses. It reads every component's `x` (per
field, reconstructed), every discrete `s` and every mode store, and every root
input, as one condition tree — `combine` of one `at(path, fragment(x = …,
s = …, m = …))` per component that has stores, plus one `fragment(inputs =
(face = value, …))` — and returns it with `sim.exec.clock.t`. The value must
re-apply under §14.6 (total by construction) and reproduce the stores it read
bit-for-bit through `init!(other, condition; t₀ = t)` on a twin sim (in an
event-free model, since boundary zero re-fires whatever holds). The condition
is time-free; `t` rides beside it.

Commit: `Add the read-selector family with its compiled reader, and capture`.

## Stage 2 — the specialized `apply!` register (§14.3, §14.4, D-066)

In `src/conditions.jl`. Today `resolve_condition` bakes *values* into a
`ConditionPlan` for the dynamic walk. The specialized register bakes *lenses*:
the plan is compiled once from a tree's **shape** and applied many times to
trees of that shape with different values.

- During flattening, each `CEntry` records its **tree position**: the
  `getfield`/`getindex` step tuple from the root node to the authored value
  (e.g. `(:nodes, 2, :node, :x, :θ)` for the `θ` leaf of a fragment scoped
  under the second node of a `combine`). For an `override`, the position is
  the winning layer's.
- `Getter{P}` is the lens: `struct Getter{P} end`, callable, navigating a tree
  by `P` with a generated or recursive walk so the access is type-stable.
- `compile_plan(node, b::Build, T) → SpecializedPlan` runs **the same
  validation** `resolve_condition` runs — factor the collecting pass so there
  is one implementation of the checks (§14.3's list), the two registers
  differing only in what they bake — and compiles per leaf a `Getter{P}`, a
  destination (an `xbuf` offset, a `(store, ci, field)`, or a root cell
  address) and a converter, the destination leaf type at this activation. The
  plan's type carries the tree type it was compiled from and its entries as
  tuples, so `apply!` unrolls.
- `apply!(ex::Executor, plan::SpecializedPlan{NT}, tree::NT)` writes every
  leaf through its lens and converter — `xbuf` leaves flattened at their
  offsets, each `s`/`m` store as one whole value `merge(defaults, (field =
  lens(tree), …))` with the merge base baked as today (§14.3's fork), root
  inputs scattered — with **no allocation** for a tree whose values are
  scalars/`SVector`s: `@ballocated apply!(ex, plan, tree) == 0` is the gate.
- **The shape check, folded.** The tree type is proven by dispatch: a tree of
  another type reaches a fallback method that throws
  `BuildError("ConditionShapeDrift: …")` naming the compiled and the observed
  tree types and the remedy (a condition function must return one shape for
  every decision). The prefix strings of `Scoped` nodes are runtime fields, so
  the plan records them in tree order and `apply!` sweeps them with `===`
  against the tree's, throwing the same kind with the position and both
  strings on a mismatch. That sweep must be allocation-free too.
- **Converters, per §14.3's two cases.** The destination leaf type at the
  activation is the converter: a value already at that type converts through
  the type's own methods (a `Dual` into a `Dual` leaf, partials untouched); a
  plain `Float64` into a `Dual` leaf is the zero-partial embedding `convert`
  already performs. A `Dual` authored into a `Float64` destination — a pinned
  leaf, or a discrete `s` store, which is frozen at a non-nominal activation —
  does not convert and is refused at resolution by the existing
  `_unconvertible` path; extend that message with one clause for the
  non-nominal case: a decision variable cannot descend into a frozen or
  pinned leaf.

Update the dynamic-walk `apply!`'s docstring (it currently says the specialized
register is "absent here, README").

Commit: `Add the specialized apply! register: Getter{P} lenses over a shape-compiled plan, with the folded shape check`.

## Stage 3 — `TrimProblem`, the backend seam, `trim!`, `TrimReport`

New file `src/trim.jl`, included after `readers.jl`.

### `TrimProblem` (§14.7)

Keyword constructor with exactly the six spec'd fields, all required:

```julia
TrimProblem(; guess, lower, upper, condition, reads, residuals, tolerances)
```

Setup validation, collected into one `BuildError("TrimProblemInvalid: …")`
naming each offending field with the names or types in hand:

- `guess`, `lower`, `upper`: NamedTuples with **equal key sets** and
  all-`Float64` fields; `lower`/`upper` are then canonicalized to `guess`'s
  order by `NamedTuple{keys(guess)}(lower)` — a permuted spelling is not an
  error and pairs by name.
- `tolerances`: an all-`Float64` NamedTuple.
- `reads`: a `reads(...)` value whose selectors resolve (the Stage 1 list,
  folded in).
- `residuals`' return: observed at the setup guess evaluation; its key set
  must equal `tolerances`' (order free — the return is canonicalized to
  `tolerances`' order by the type-level reorder), and each field must be a
  real scalar.
- `condition(guess)` must return a condition node — the existing
  `_node_misuse` directive covers a stray NamedTuple.

An **empty** problem, `guess = (;)` with matching empty bounds, is legal.

### The backend seam (§14.8)

```julia
solve(backend, eval!, d0, lower, upper, tol) -> (; d, status, nevals, niters)
```

`eval!(r, J, d)` fills `r` always and `J` iff `J !== nothing`; all vectors
are packed in the declared field orders (`guess`'s for `d`, `tolerances`' for
`r` and `tol`), `±Inf` in the bounds meaning unbounded. `status::Symbol` is
open and recorded verbatim.

`LevenbergMarquardt(; maxiter = 100, λ₀ = 1e-3)` is the default backend, in
house, dense: a damping loop on `(JᵀJ + λ·diag(JᵀJ)) δ = −Jᵀr` (plain `\`),
accept/reject on the residual norm with λ scaled down/up by 10, **step
projection onto the box**, stopping when `all(abs.(r) .≤ tol)` (the
per-residual test in the service's own units, LM testing exactly what the
service re-tests) or at `maxiter`, or when a step stalls below `eps`-scale.
Status from `{:converged, :maxiter, :stalled}` — a small core, ~100 lines,
readable. The backend sees vectors only.

### `trim!` (§14.8)

```julia
trim!(sim::Simulation{Float64}, problem; baseline, t₀ = 0.0, backend = LevenbergMarquardt()) → TrimReport
```

(The prototype spells `t₀` where the spec writes `t0`; keep `t₀`. A non-nominal
`Simulation` is refused with a one-line `BuildError`: trim commits through the
nominal world.)

1. **Lifecycle.** As `init!`: refused while `running`, refused on `errored`;
   legal in `built`, `initialized`, `stopped`.
2. **Validate the problem** (above). `N = length(guess)`.
3. **The nominal half (D-213).** Instantiate a nominal `Executor` from
   `sim.build` over the sim's bound schedule (`compile` needs `D`, `Φ`, `Δt`
   per component: take them from what `Simulation` already bound — keep the
   bound vectors on the sim if `sched` is inconvenient). Resolve
   `override(baseline, condition(guess))` with `resolve_condition`, check
   totality with `assert_total(plan, flat, "trim!")` (`UninitializedInputs`,
   nothing written, before any evaluation), apply by the dynamic walk, and run
   **one establishment round**: `_round!(ex, ESTABLISH)` — every discrete
   output stage due or not, no projection, no guards, no `g` — then `rhs`.
4. **The seeded half** (`N > 0`). `TD = ForwardDiff.Dual{TrimTag,Float64,N}`
   with a service-owned `TrimTag`; `activation(sim.build, TD)` (cached on the
   build), a second `Executor` at `TD`. Copy every frozen component's output
   cells from the nominal executor's store into it (a discrete producer's cells
   are pinned `Float64` at every activation, so this is a value copy; the
   zero-partial embedding happens where a continuous consumer reads them).
   Compile the specialized plan from `override(baseline, condition(d_dual))`
   at `TD`, where `d_dual` is `guess` seeded with unit partials; compile the
   reader at `TD`.
5. **`eval!(r, J, d)`.** Build `d_nt = NamedTuple{keys(guess)}` of `TD`s from
   `d` with unit seeds; `tree = override(baseline, condition(d_nt))`;
   `apply!(ex_dual, plan, tree)`; `evaluate!(ex_dual)` (sweeps + `rhs`);
   `gather(reader, ex_dual)`; `residuals(reads, d_nt)` reordered to
   `tolerances`' keys; `r .= value.(…)`, `J .= partials` when requested. The
   per-iteration path allocates nothing beyond what `residuals` itself does;
   assert `@ballocated` on the apply and the gather, not on `eval!` (the user
   lambda is theirs).
6. **Solve and verdict.** `solve(backend, eval!, d0, lower, upper, tol)`;
   then **one more `eval!` at the returned `d`** and `converged =
   all(abs.(r) .≤ tol)` — the service's verdict, never the backend's.
   `saturated` = the decisions at a bound at the returned point, as
   `(name, :lower | :upper)` pairs.
7. **Zero decisions.** Skip 4–6: the nominal half's establishment evaluation
   is the one evaluation; gather there, residuals, box test; `status =
   :bypassed`, `nevals = 1`, `niters = 0`.
8. **No convergence → no commit.** Return the report; the sim is bit-for-bit
   untouched, lifecycle included (a `built` sim stays `built`).
9. **Commit.** `init!(sim, override(baseline, condition(solution)); t₀)` —
   literally that call, `solution` the guess-shaped `Float64` NamedTuple. Then:
   the fired events, read from `sim.exec.events.count .> 0` right after `init!`
   returns (the counts are per boundary and reset at the next one) as
   `(path, name)` from `events.names`; non-empty →
   `@warn "TrimCommitEvents: …"` listing them. The **committed-state
   residuals**: `sim.exec.bodies.rhs()` on the sim's own executor (the table
   is boundary-consistent after boundary zero; `ẋbuf` is integrator scratch
   and this is a service evaluation), gather with a `Float64` reader against
   the sim's executor, `residuals(reads, solution)`; box test failing →
   `@warn "TrimCommitResiduals: …"` naming the offending residuals with their
   committed values and tolerances.
10. **Report.**

```julia
struct TrimReport
    converged::Bool                       # the service's box test at the returned point
    solution::NamedTuple                  # guess-shaped, warm-startable
    residuals::NamedTuple                 # solved-point, tolerances-shaped
    tolerances::NamedTuple
    committed_residuals::Union{Nothing,NamedTuple}   # nothing when there was no commit
    status::Symbol                        # the backend's, verbatim; :bypassed for N = 0
    nevals::Int
    niters::Int
    saturated::Vector{Tuple{Symbol,Symbol}}
    fired_events::Vector{Tuple{String,Symbol}}
end
```

No `committed` flag (§14.8: a converged solve is always committable);
`committed_residuals === nothing` is the absence of a commit, not a flag.

Commit: `Add trim!: TrimProblem, the solve seam with an in-house Levenberg–Marquardt, the two-half scratch world of D-213, and TrimReport`.

### Test model

Add to `src/library.jl`, in the `condition` idiom the file already uses:

```julia
"""Damped pendulum under a torque input: θ̈ = −(g/l)·sin θ − c·θ̇ + u."""
struct Pendulum <: AbstractComponent
    g_l::Float64
    c::Float64
end
Pendulum(; g_l = 9.81, c = 0.5) = Pendulum(g_l, c)
init_x(::Pendulum) = (θ = 0.0, ω = 0.0)
input_types(::Pendulum, ::Type{T}) where {T <: Real} = (u = T,)
output_types(::Pendulum, ::Type{T}) where {T <: Real} = (θ = T, ω = T)
h_x(::Pendulum, (; x)) = (θ = x.θ, ω = x.ω)
f(c::Pendulum, (; x, u)) = (θ = x.ω, ω = -c.g_l * sin(x.θ) - c.c * x.ω + u.u)
condition(::Pendulum; θ = 0.0, ω = 0.0) = fragment(x = (θ = θ, ω = ω))
```

Roots: `fed(Pendulum(), :u)` (root input `in`, child `c`); a sampled variant
(a `DiscreteIntegrator` or `ZOH` feeding `u`, its input a root face) for the
D-213 property; test-local fixtures at top level for the event cases.

## Test plan — `test/test_trim.jl` (and `test/test_readers.jl` if you prefer two files)

Every property below gets a testset; cite the section in the title as the
existing tests do.

**Executor (Stage 0).** Every existing test passes; the §7.5 gates unchanged.
A `Simulation`'s executor is the one the loop runs (`phase_bodies(sim) ===
sim.exec.bodies`).

**Selectors and the reader (Stage 1).**
- Each of the five selectors reads what it names, at `Float64` and at `D8`
  (the `Dual` alias in `test/utils.jl`), from an executor; `i` indexes.
- `gather` allocates nothing for scalar/`SVector` reads.
- Collected resolution: one `compile_reads` call with a misspelled path
  (did-you-mean), an undeclared field naming the declared list, `get_deriv`
  on a discrete `s`, an unknown root face — one `BuildError`, all four named.
- `capture`: after `init!` and after `run!` on an event-free model, `init!` of
  a twin with the captured pair reproduces `xbuf`, every `s`/`m` store, every
  root input cell and the clock exactly; `built` and `running` are refused as
  `ServiceLifecycle`.

**The specialized register (Stage 2).**
- Over the `tri()` fixture of `test_conditions.jl` (an `x`, an `s`, an `m`,
  two root inputs): a shape-compiled plan applied to a second tree of the same
  shape with other values lands the same stores the dynamic walk lands from
  that second tree (compare the executors' buffers afterwards).
- Zero allocation: `@ballocated apply!(ex, plan, tree) == 0`.
- The store merge is the composite's: baseline authors `s.a`, the per-iteration
  layer authors `s.b` on the same component; after apply both hold (the trap
  the composite plan exists to avoid).
- Drift: a tree of another type → `ConditionShapeDrift` naming both types; a
  tree with a different `at` prefix at the same position → the same kind
  naming both strings; the executor is untouched by either.
- Converters: a `Float64` leaf into a `Dual` executor's `x` reads back with
  zero partials; a `Dual` leaf reads back with its partials; a `Dual` into a
  discrete `s` is refused at resolution with the frozen/pinned clause.

**`trim!` (Stage 3)** — on the pendulum unless noted; `g_l = 9.81`, `c = 0.5`.
- **One-step linear problem**: decide `u` at fixed `θ = 0.5`:
  `guess = (u = 0.0,)`, `condition = d -> combine(at("c", condition(Pendulum(); θ = 0.5)), fragment(inputs = (in = d.u,)))`,
  `reads = reads(ω̇ = get_deriv("c", :ω))`, `residuals = (r, d) -> (torque = r.ω̇,)`,
  `tolerances = (torque = 1e-9,)`. Converged, `solution.u ≈ g_l·sin(0.5)`,
  `nevals` small; the sim is `initialized` afterwards at `t₀`, with `x.θ ==
  0.5` and the root input at the solution; `committed_residuals.torque`
  within tolerance; `fired_events` empty; no warning.
- **Iterative nonlinear problem**: decide `θ` at fixed `u = 4.0`:
  `guess = (θ = 0.1,)`, `lower = (θ = -π/2,)`, `upper = (θ = π/2,)`,
  the fragment mixing a `Dual` and a `Float64` leaf: `x = (θ = d.θ, ω = 0.0)`.
  Converged to `asin(4/g_l)` within a few iterations; the box bound picks the
  branch.
- **Permuted bounds** are a non-event: the same problem with `lower`/`upper`
  spelled in another field order (two-decision version: decide `(θ, u)` with
  residuals `(torque, hold = r.θ − 0.3)`) gives the same solution.
- **Infeasible**: `u = 2·g_l` → `converged == false`, `status` recorded,
  `committed_residuals === nothing`, the sim bit-for-bit untouched — on a
  never-initialized sim it stays `built` and `run!` still refuses; on an
  initialized one every buffer equals its pre-call copy.
- **Saturated and converged**: the two-decision problem with `upper = (θ =
  0.3, u = Inf)` and `hold = r.θ − 0.3`: converged with `saturated ==
  [(:θ, :upper)]`.
- **Empty problem**: `guess = (;)` on a baseline that is an equilibrium →
  converged, `status == :bypassed`, committed; on one that is not → not
  converged, untouched.
- **Malformed, collected**: one problem with a bounds key-set mismatch, an
  `Int` guess field, a residual/tolerances key-set mismatch and an unknown
  selector → one `TrimProblemInvalid` naming all four; nothing written.
- **Incomplete baseline** → `UninitializedInputs` at setup, nothing written.
- **D-213, the frozen cells**: the sampled pendulum, its `u` a discrete
  integrator's held output `kI·acc` with `acc` authored by the baseline; decide
  `θ` for `ω̇ = 0`. The solution is `asin(kI·acc/g_l)`, which is only reachable
  if the scratch world's frozen cell holds the authored `s`'s output rather
  than the probe's zero (where the solution would be `0`). Also: the same
  problem with `acc` as a decision variable is refused at resolution (a
  `Dual` into a frozen `s`).
- **Commit-fired events**: a `Trigger` on the pendulum's `θ` output with a
  level below the solution — `@test_logs (:warn, r"^TrimCommitEvents")` and
  `report.fired_events == [("trig", :fire)]`.
- **Commit residuals**: a top-level test fixture, a pendulum with an event
  whose handler resets `θ` to `0` when `θ > level` — the solve converges, the
  commit fires it, `@test_logs (:warn, r"^TrimCommitResiduals")`, and
  `report.committed_residuals.torque` is the residual at `θ = 0`, not the
  solved one.
- **The commit is literally an `init!`**: after a converged `trim!`, a twin sim
  `init!`ed by hand with `override(baseline, condition(report.solution))` at
  the same `t₀` has identical buffers, stores, root inputs and clock.
- **Warm restart**: `run!` an initialized pendulum for a while, `(c, t) =
  capture(sim)`, `trim!(sim, problem; baseline = c, t₀ = t)` → committed
  with the clock at `t`.

## Bookkeeping

- **README**: "what is real" rows for the executor, the selector family and
  reader, `capture`, the specialized register (retire the "absent here" wording
  where it appears), and trim; the absence list above; **stand-in rows** for
  anything you build that is not the spec's shape — none is expected; if you
  find you need one, that is friction, report it. Update the increments
  sentence in the opening paragraph.
- **NOTES.md**: an "Increment 21" narrative paragraph (or two: the executor,
  then the services) in the register of increments 18 and 20, and property
  bullets for each testset, appended to the properties section.
- **Commits**: four, as titled above — single-sentence subjects, no body, NO
  Co-Authored-By trailer, NO session link, no Claude/Anthropic attribution.
  Commit only files under `prototypes/kernel/`. `git status` clean at the end.

## Report back

1. The four commit hashes and the suite counts before and after.
2. **Friction**: every point where the spec or this brief was silent, wrong,
   or in tension with the code as you found it, and what you did about it —
   the literal reading built, and the alternative you would have taken. Include
   the questions you settled by "simplest thing" (e.g. the `guess`-outside-the
   -box case, `i`'s validation, how `D`/`Φ`/`Δt` reach `compile`).
3. Anything in the existing code you had to change beyond the extraction, with
   the reason.
4. The `@ballocated` gates' results, verbatim.
