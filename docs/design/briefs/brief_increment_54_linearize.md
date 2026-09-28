# Brief: `linearize`, §14.10's seeded pass over the tap set (D-271, D-272)

Tip at launch: `5b9cdd6`, the docs commit that ruled the surface (D-271,
D-272). One stage, one cold review, one fixer. Retires the `linearize` half
of `pending.md`'s §14 bullet, which this increment first splits into five
sub-bullets (Bookkeeping). Mounting (§14.9), the NLopt fallback, the two
addressing items and the `check` entry stay out.

Design and code are peers, neither subservient. The rulings landed
docs-first; this increment conforms the code to the amended text. If the
spec's shape proves wrong at the keyboard, stop and report rather than
deviate silently.

`docs/design/briefs/walkthrough_linearization.md` is a study note that runs
the whole mechanism on the fixture this increment uses. Read it once, in
full, before the spec: it is the fastest route into the pass. Where it and
the spec disagree, the spec wins.

## What the spec says

Read these by line range at `5b9cdd6`, not whole sections:

- §14.10, `spec.md` 10156–10275. The tap declaration and its Rule
  (10158–10192): the `taps` set, closed membership per list, one scalar per
  tap. The evaluation and the `width` Rule (10194–10213). What the pass
  seeds and what it holds frozen, with the table (10215–10243): the pinned
  root input, the fan-out meet, the frozen tier. The pure query and
  `capture` (10245–10257). The returned `Linearization` (10259–10275). The
  rest of the section is recorded material and stays out.
- §14.4, 9346–9424: the family with the index on every member (9348–9352),
  the source rule (9365–9372), the table (9418–9424).
- §14, 9068–9069: the two lifecycle rows for `linearize`.
- §14.8, 9862–9890: scratch stores, stated without type luck; the
  root-input totality check at setup.
- §9.7, 3935–3960: the `activations` keyword and `ProbeDual`; the
  pre-materialization idiom the `width` default serves.
- Appendix B, 10814–10820, the `linearize` row; Appendix C, 11232–11235,
  the `TapResolution` row and its payload.
- D-271, `decisions.md` 10808–10836; D-272, 10838–10898: the position's six
  bullets and the four rejections. D-197 (6900), D-213 (7510), D-167 (5716)
  and D-168 (5792) are the rulings the rejections and the frozen copy rest
  on; read their Position fields only.
- `implementation.md`: the entries for `src/readers.jl` (251–263),
  `src/bindings.jl` (493–501), `src/trim.jl` (591–600), `src/diagnostics.jl`
  (43–85), `src/Cadence.jl` (16–19), `test/imports.jl` (641–644); the
  authoring caveats at 670–731 in full; the "Naming" section (732) and
  "Running the suite" (809), both cited below and never restated.
- `pending.md` 21–24, the §14 bullet.

## What exists

- `readers.jl` 71–79, `GetInput` and `GetFace`, the two selectors without
  an index; 93–94, their constructors; 105–106, their `_spell`; 285–288,
  `_selpath`/`_selindex`; 294–299, `_check_index`, which refuses an index
  on a `Real` leaf and admits it on anything else; 367–392, the two
  resolution arms, each ending in a `CellRead{typeof(addr),Nothing}`. 116–135,
  `Reads` and `reads`/`_reads`, the shape `taps` mirrors. 162–168,
  `CellRead` and `_take`. 170–181, the `_read` methods: a `StateRead`
  reconstructs at `offset` in `xbuf`, a `DerivRead` at the same offset in
  `ẋbuf`. 230–255, `_compile_reads` and `_resolve_reads`, the collecting
  form. 276–283, `_reader_violation` and `_tap`. 314–329, the `GetState`
  arm: a continuous leaf yields `StateRead{P,I}(first(xblocks[ci]) - 1 +
  _leaf_offset(decl.x, field), i)`, a discrete one a `StoreRead`.
- `bindings.jl` 173–214, `_resolve_read`: the `GetOutput` arm refuses an
  index with `:indexed` (179–182); the `GetInput` and `GetFace` arms do not
  look at one.
- `diagnostics.jl` 1633–1687, `TapResolution` and its message: the reasons
  are name- and index-shaped, plus `:discrete_deriv`. 1477–1500,
  `ReadBindingUnresolved`, whose `:indexed` message cites `pending.md`.
  1818–1870, `ArgumentInvalid`: the `:non_nominal` and `:not_a_problem`
  arms (1850–1859) spell `trim!` by name. 1922–1935, `ReadSetMisuse`.
  1161–1175, `STOPPED_SIM_LEGAL` and `ServiceLifecycle`.
- `trim.jl` 87, `TrimTag`; 422–532, `trim!`: the lifecycle refusals
  (424–428), the nominal half (441–449: `_scratch`, `resolve_condition`,
  `assert_total`, `apply!`, `_round!(…, ESTABLISH)`), the seeded half
  (465–471: the `Dual` type, `activation`, `_scratch`, `_establish_frozen!`),
  the value/partials split (490–498), the two refusal methods (534–539).
  546–556, `_scratch`; 558–573, `_establish_frozen!`; 575–583, `_seeded`.
- `sim.jl` 438–446, `evaluate!`, the three phase bodies; 519–526,
  `_round!`; 655–656, how `init!` writes the clock, `t` into the scalar and
  `t₀` as a `Float64`. `store.jl` 124–130, `Clock`.
- `conditions.jl` 286, `resolve_condition(node, build, T)`, and 529,
  `apply!(exec, plan)`: the dynamic walk at a seeded activation, verified
  at this tip. Applying a captured condition to a `Dual{_,Float64,8}`
  scratch executor leaves every `xbuf` entry and every root-input cell a
  zero-partial dual. 508, `assert_total`; 835–865, `capture`.
- `build.jl` 603–614, `_root_input_cell`: D-168's meet, per consumer,
  through `_accepts_wire(decls[ci].ins[face], retype(T, P_F), T)`. A
  `Pinned{Float64}` entry reads `Float64` in `act.decls[ci].ins` at every
  activation (`retype_entry` strips the marker), so the *declared* entry
  comes off `u_types(entry.instance)[face]`, `ComponentEntry.instance`
  being the user's component (`assembly.jl` 750). 708–717, `ProbeTag`
  and `ProbeDual`, the docstring saying "§14.10 chunks at whatever widths
  it needs"; 731, `build(root; activations)`; 915, `activation(build, T)`,
  the cache; 702, `Build.activations`, keyed by scalar type. 1005,
  `_frozen`. `xblocks` and `_leaf_offset` are `T`-independent, so an offset
  resolved at one activation is the offset at every activation.
- `leaves.jl` 255–260, `retype`; 343, `_accepts_wire`.
- `test/test_readers.jl` 1–35, the `readable` fixture and its read set,
  the model for a reader test; 41–65, the five-selectors testset with
  `D8`; 77–116, the collecting-violation pattern with `failure` and
  `carried`. `test/test_trim.jl` 55–58, `sampled_pend` and
  `sampled_base`; 421–432, the D-213 testset; 573–590, the capture idiom;
  620 on, the lifecycle testset. `test/test_bindings.jl` 159, the
  `:indexed` assertion. `test/test_diagnostics.jl` 476–500, the
  `TapResolution` rendering rows; 590, `warning_kinds`.
- `test/fixtures.jl`: `Plant` 15–35, `VectorPlant` 66–86 (`q` an
  `SVector{2}` state and a stage-1 port, `power = u * q[2]` stage 2),
  `StateFeedback` 88–96 (`q::SVector{2}` in, `u = -k q[1]` out), `Sum`
  160–171 (`e = sa·a + sb·b`, defaults `1.0`, `-1.0`), `DiscreteIntegrator`
  183–192, `PinnedGain` 864–870 (`e = Pinned{Float64}` in), `Pendulum`
  1480–1495. `test/utils.jl` 3, `D8`; 17, `fed`; 41–58, `failure` and
  `carried`.

Verified at this tip, in a REPL: the four models below build; on the
vector model the `qin` cell and the `q` face are `SVector{2,Dual}` at a
`Dual` activation; on the pinned model the `τ` cell is `Float64` at the
`Dual` activation with `g`'s `conns` reading `[:e => ("", :τ)]`; on the
sampled model `("ctl", :u)` is `Float64` at the `Dual` activation and
`xblocks == [1:0, 1:2]`; on the pendulum model, seeding `xbuf[1]`,
`xbuf[2]` and the two root-input cells with unit partials 1–4 of width 8
and calling `evaluate!` gives `ẋbuf[2]`'s partials `(-9.3719, -0.5, 1.0,
-1.0, 0, 0, 0, 0)` and the `u_eff` cell's `(0, 0, 1.0, -1.0, …)`, the sim's
own `xbuf` untouched. A scratch executor's clock reads `0.0` whatever the
sim's clock says.

## Scope

- `src/readers.jl`: the index on `GetInput` and `GetFace` (field,
  constructor, `_spell`, `_selindex`, the two resolution arms checking it
  against the cell's port type). The family docstring (22–54) says every
  member carries it.
- `src/bindings.jl` 192–214: the two arms refuse an index with `:indexed`,
  as the `GetOutput` arm does, before their name checks.
- `src/diagnostics.jl`: `TapResolution` gains the four tap-set reasons and
  two fields; `ReadSetMisuse` gains `:not_a_tap_list`; `ArgumentInvalid`
  gains `:not_a_tap_set`, `:t0_without_about` and `:nonpositive_width`, and
  its `:non_nominal` arm names `d.call`.
- `src/linearize.jl`, new, included after `trim.jl`: `Taps`/`taps`,
  `LinearizeTag`, `LINEARIZE_WIDTH`, `LinearizeDual`, `Linearization`,
  `linearize` and its private helpers.
- `src/Cadence.jl`: the include.
- `test/test_linearize.jl`, new; `test/CadenceTests.jl` (include, `live`,
  the `runall` docstring's list if it names files); `test/imports.jl`;
  `test/test_bindings.jl`; `test/test_diagnostics.jl`.
- `implementation.md` entries, `pending.md`, the prose under "Prose to
  correct".

Out: mounting (`at` over a `Taps` or a `TrimProblem`); a `show` method for
`Linearization` (none exists for `TrimReport` either; raise it in the
report); `subsystem`/`delete_vars`; any change to `trim!`, including the
scratch clock it leaves at zero (a pre-existing gap: `trim!` evaluates at
`t = 0` whatever `t0` says; name it in the report, do not fix it); the
`:indexed` refusal in bindings beyond extending it to the two new arms;
the `check` entry.

## Shapes

### The index on the two table selectors (D-271)

```julia
struct GetInput
    face::Symbol
    i::Union{Nothing,Int}
end

struct GetFace
    name::Symbol
    i::Union{Nothing,Int}
end

get_input(face::Union{Symbol,AbstractString}, i = nothing) = GetInput(Symbol(face), _index_arg(i))
get_face(name::Union{Symbol,AbstractString}, i = nothing) = GetFace(Symbol(name), _index_arg(i))
_spell(selector::GetInput) = "get_input(:$(selector.face)$(_ipart(selector.i)))"
_spell(selector::GetFace) = "get_face(:$(selector.name)$(_ipart(selector.i)))"
_selindex(selector) = selector.i       # one method: every member has the field now
```

Each resolution arm, after its name checks, reads the port type off the
address and checks the index against it exactly as the `GetOutput` arm does
(the `:scalar_index` refusal, `declared` the port type), then builds
`CellRead{typeof(addr),typeof(selector.i)}(addr, selector.i)`. The port
type of a `CellAddr{P,K}` is `P`; add a one-line accessor in `store.jl` if
none exists (grep `CellAddr{P` first).

### The tap set

In `linearize.jl`, mirroring `Reads`/`reads`:

```julia
"""
    taps(; x = (;), u = (;), y = (;)) → Taps

§14.10's tap set: three labeled selector lists with closed membership, `x`
taking `get_state`, `u` `get_input`, `y` `get_output` and `get_face`. The
labels are the axes of the returned matrices. Membership is checked at
resolution, in the collecting form; here each list is checked to be a
NamedTuple of selectors, as `reads` checks its own (D-272).
"""
struct Taps{X<:Reads,U<:Reads,Y<:Reads}
    x::X
    u::U
    y::Y
end
```

`taps` hands each list to `_reads` after checking it is a `NamedTuple`; a
list that is not one raises `ReadSetMisuse(observed = typeof(list), reason
= :not_a_tap_list, label = :x)`, the label naming the list. An empty list
is legal.

### The scalar, the width, the return

```julia
struct LinearizeTag end
const LINEARIZE_WIDTH = 8
"""The default width's scalar, pre-materializable: `build(m; activations = (Float64, LinearizeDual))` (§14.10, D-272)."""
const LinearizeDual = ForwardDiff.Dual{LinearizeTag,Float64,LINEARIZE_WIDTH}

"""
§14.10's returned object (D-272): the operating point and the four
Jacobians, the four vectors as NamedTuples under the tap labels, the
matrices row- and column-ordered by the label tuples. Every entry is exact
to round-off; nothing here is a finite difference.
"""
struct Linearization
    ẋ₀::NamedTuple
    x₀::NamedTuple
    u₀::NamedTuple
    y₀::NamedTuple
    A::Matrix{Float64}
    B::Matrix{Float64}
    C::Matrix{Float64}
    D::Matrix{Float64}
    x_labels::Tuple{Vararg{Symbol}}
    u_labels::Tuple{Vararg{Symbol}}
    y_labels::Tuple{Vararg{Symbol}}
end
```

### `linearize`

```julia
function linearize(sim::Simulation{Float64}, tap_set::Taps; about = nothing,
                   t0 = nothing, width::Int = LINEARIZE_WIDTH)
```

The docstring states the seven steps of the walkthrough's section 6 in the
spec's words: the operating point, the two-half scratch world (D-213), the
seeds at the resolved sites, the passes of `width` directions, the
readback, the pure query. In order:

1. **Arguments.** `width ≥ 1` or `ArgumentInvalid(call = :linearize,
   argument = :width, reason = :nonpositive_width, value = width)`. `t0`
   given without `about` is `ArgumentInvalid(call = :linearize, argument =
   :t0, reason = :t0_without_about)`: the default operating point carries
   its own time, and a silently ignored keyword is worse than a refusal.
2. **Lifecycle** (§14's table, 9068–9069). `about === nothing`: legal in
   `:initialized` and `:stopped`, else `ServiceLifecycle(op = :linearize,
   status, legal = [:initialized, :stopped])`. `about` given: legal in
   `STOPPED_SIM_LEGAL`, else the same kind with that list. Both before any
   resolution, as `trim!` orders it.
3. **The operating point.** `(condition, t) = about === nothing ?
   capture(sim) : (about, Float64(something(t0, 0.0)))`.
4. **Tap resolution**, `_resolve_taps(tap_set, build, T) → (x_entries,
   u_entries, y_entries)` in the collecting form, one `DiagnosticError`
   with every violation. All checks run against the nominal activation so
   every payload carries nominal types, except the seedability check,
   which reads the seeded layout. Per list, in this order:
   - membership: a selector outside the list's kinds is `TapResolution(…,
     reason = :tap_kind, list = <the list>, tap = _tap(selector))`;
   - `_resolve_selector(selector, label, build, nominal_act, diags)`, the
     existing arms, collecting their own refusals;
   - `x`: a `StoreRead` (a discrete store) is `:discrete_state`, path and
     field in hand (D-197); a leaf whose nominal type `P` is not `Float64`
     without an index or not an `SVector{n,Float64}` with one is
     `:unseedable` with `declared = P`; a non-`Real` leaf without an index
     is `:vector_tap` with `declared = P` (checked before `:unseedable`, so
     an unindexed `SVector` reads `:vector_tap`);
   - `u`: `:vector_tap` and `:unseedable` on the nominal port type as for
     `x`; then the meet: with `P_F = structure.root_types[root_index]` and
     `walked = retype(T, P_F)`, every consumer `(ci, consumer_face)` with
     `producer === ("", face)` whose `act_T.decls[ci].ins[consumer_face]`
     fails `_accepts_wire(entry, walked, T)` is a pinning consumer, and one
     or more gives `:unseedable` with `pinning = [entry.path =>
     u_types(entry.instance)[consumer_face], …]` and `declared = P_F`
     (D-167, D-168). The seeded cell type is the direct witness: assert
     internally that the meet's verdict and `act_T.layout.addr[("",
     face)]`'s port type agree;
   - `y`: `:vector_tap` on an unindexed non-`Real` leaf. Any `Real` leaf is
     readable, `Float64` or not, since a `y` row is a read, not a seed.

   The `x` entries are the resolved `StateRead`s (offsets `T`-independent)
   paired with `DerivRead{retype(T, P),I}(offset, i)` for the readback and
   the seeded leaf type; the `u` and `y` entries are `CellRead`s rebuilt
   over `act_T.layout.addr[key]`. Plain `Vector`s: this is a stopped-sim
   service (§7.5), and dynamic dispatch per read is fine.
5. **The nominal half.** `nominal_exec = _scratch(sim, Float64)`; `plan =
   resolve_condition(condition, build, Float64)`; `assert_total(plan,
   build.structure, :linearize)`; `apply!(nominal_exec, plan)`;
   `_round!(nominal_exec, ESTABLISH)`. Set `nominal_exec.clock.t = t` and
   `clock.t₀ = t`.
6. **The seeded half.** `T = ForwardDiff.Dual{LinearizeTag,Float64,width}`;
   `act = activation(build, T)`; `seeded_exec = _scratch(sim, T, act)`;
   `apply!(seeded_exec, resolve_condition(condition, build, T))`;
   `_establish_frozen!(seeded_exec, act, nominal_exec, build)`; the clock
   as above, `t` converted to `T`.
7. **The passes.** `N = n_x + n_u`. `sites` is the `N` seed sites in list
   order, `x` first: an `x` site writes `seeded_exec.xbuf[offset + (i ===
   nothing ? 1 : i)]`; a `u` site writes its cell, whole for a scalar and
   through `StaticArrays.setindex(gather_cell(…), seed, i)` for a vector.
   For each `group` in `Iterators.partition(1:N, width)`: write every site
   `k` as `ForwardDiff.Dual{LinearizeTag}(value, ntuple(j -> Float64(j ==
   pos), Val(width))...)` with `pos` the position of `k` in `group` (zero
   partials when `k ∉ group`); `evaluate!(seeded_exec)`; for each `x` entry
   `i`, `v = _read(deriv_entry, seeded_exec)`, `ẋ₀[i] =
   ForwardDiff.value(v)`, and for each `(pos, k)` in `group`, `k ≤ n_x ?
   A[i, k] : B[i, k - n_x]` takes `ForwardDiff.partials(v, pos)`; the same
   over the `y` entries into `y₀`, `C`, `D`. `x₀` and `u₀` are the value
   parts of the sites' reads. With `N == 0`, one `evaluate!` fills `ẋ₀`
   and `y₀` and every matrix has zero columns.
8. **Return** `Linearization(…)` with the NamedTuples built over the label
   tuples. Both executors are locals. Nothing on `sim` is read after step
   6 or written at any point.

The two refusal methods mirror `trim!`'s: a non-nominal `Simulation` is
`ArgumentInvalid(call = :linearize, reason = :non_nominal, value =
string(typeof(sim)))`, and a second argument that is not a `Taps` is
`ArgumentInvalid(call = :linearize, argument = :taps, reason =
:not_a_tap_set, value = string(typeof(other)))`.

### `TapResolution`

Two fields and four reasons, the reason comment extended:

```julia
    list::Union{Nothing,Symbol} = nothing          # :tap_kind — the list the selector sat in
    pinning::Vector{Pair{String,Any}} = Pair{String,Any}[]   # :unseedable — consumer path => its declared entry
```

Messages, each one clause in the existing `_tap_violation` frame:
`:tap_kind` names the list and what it takes; `:discrete_state` says the
path is a discrete component, the tier is frozen in the pass, a tap there
could only yield a zero row and column, and the step map $\Phi$ is the
recorded next move (D-197); `:vector_tap` says a tap is one scalar and
the leaf is declared `P`, so the author writes one indexed tap per
component (D-271); `:unseedable` with a non-empty `pinning` names each
pinning consumer and its entry and points at a tolerant entry or a route
around it (D-167, D-168), and with an empty one names the declared type.

## Tests

`test/test_linearize.jl`, one function `test_linearize()`, section header
naming §14.10 and this increment, fixtures at top level, every testset name
stating its property and citing its section. Grep every new fixture name
across `test/` before choosing it. Add every new name to `test/imports.jl`.

Fixtures, verified against the tree:

```julia
lin_pend() = Group((; s = Sum(), c = Pendulum()); wires = ("s/e" => "c/u",),
                   inputs = ("τ" => "s/a", "d" => "s/b"),
                   outputs = ("c/θ" => "θ", "s/e" => "u_eff"))
lin_point(θ = 0.3) = combine(at("c", condition(Pendulum(); θ = θ)),
                             fragment(inputs = (τ = PEND_G_L * sin(θ), d = 0.0)))
lin_taps() = taps(x = (θ = get_state("c", :θ), ω = get_state("c", :ω)),
                  u = (τ = get_input(:τ), d = get_input(:d)),
                  y = (θ = get_face(:θ), u_eff = get_face(:u_eff)))
lin_vector() = Group((; p = VectorPlant(), fb = StateFeedback(2.0));
                     wires = ("fb/u" => "p/u",), inputs = ("qin" => "fb/q",),
                     outputs = ("p/q" => "q", "p/power" => "power"))
lin_pinned() = Group((; g = PinnedGain(), c = Pendulum());
                     wires = ("g/out" => "c/u",), inputs = ("τ" => "g/e",))
lin_sampled() = Group((; ctl = DiscreteIntegrator(1.0), c = Pendulum());
                      wires = ("ctl/u" => "c/u",), inputs = ("in" => "ctl/e",))
```

`PEND_G_L` and `PEND_C` are `test_trim.jl`'s top-level constants (8–9),
module globals usable from this file as they are; include
`test_linearize.jl` right after `test_trim.jl`.

- the pendulum linearizes to its closed form, exact to round-off (§14.10):
  `Simulation(lin_pend(); h = 1//10)`, `init!(sim, lin_point())`, `L =
  linearize(sim, lin_taps())`. `L.A ≈ [0 1; -PEND_G_L*cos(0.3) -PEND_C]`,
  `L.B ≈ [0 0; 1 -1]`, `L.C ≈ [1 0; 0 0]`, `L.D ≈ [0 0; 1 -1]`, all with
  `atol = 1e-12`; `L.ẋ₀.θ == 0.0` and `abs(L.ẋ₀.ω) < 1e-12`; `L.x₀ == (θ =
  0.3, ω = 0.0)`; `L.u₀.τ == PEND_G_L * sin(0.3)`; `L.y₀ == (θ = 0.3, u_eff =
  L.u₀.τ)`; `L.x_labels == (:θ, :ω)`, `L.u_labels == (:τ, :d)`, `L.y_labels
  == (:θ, :u_eff)`; `size(L.A) == (2, 2)` and the other three shapes.
- the default operating point is the capture, and the sim is untouched
  (§14.10, §14.1): after `run!(sim; t_end = 0.3)`, record `xbuf`, the
  root-input cells, `latest(sim)`, `lifecycle(sim)` and `sim.exec.clock.t`;
  `(captured, t) = capture(sim)`; `linearize(sim, lin_taps())` and
  `linearize(sim, lin_taps(); about = captured, t0 = t)` agree field for
  field with `==`; every recorded value is `===` or `==` what it was, and
  `lifecycle(sim) === :stopped`.
- `about` is legal in `built`, where the default form is refused (§14):
  a fresh `Simulation(lin_pend(); h = 1//10)`: `linearize(sim, lin_taps())`
  is `DiagnosticError{ServiceLifecycle}` with `op === :linearize`, `status
  === :built` and `legal == [:initialized, :stopped]`; `linearize(sim,
  lin_taps(); about = lin_point())` returns the closed form above and
  leaves `lifecycle(sim) === :built`; a `t0` without `about` is
  `ArgumentInvalid` with `reason === :t0_without_about`; `width = 0` is
  `:nonpositive_width`. Mirror `test_trim.jl` 620 on for the `:running`
  refusal if that testset's idiom transfers cheaply; otherwise assert the
  `:errored` refusal is out of reach here and say so in a comment.
- the width groups the directions and never changes the answer (D-272):
  `width = 1`, `width = 3` and the default give matrices equal to the
  closed form at `atol = 1e-12` and equal to each other with `==`; if
  bitwise equality across widths fails, report the first differing entry
  and relax that one assertion to `≈`, saying why.
- the default width's activation is pre-materializable, and a custom width
  keys its own (§9.7, D-272): `b = build(lin_pend(); activations =
  (Float64, LinearizeDual))`, `haskey(b.activations, LinearizeDual)`;
  `Simulation(b; h = 1//10)`, `init!`, `linearize` at the default width
  adds no key; `linearize(…; width = 3)` adds exactly
  `ForwardDiff.Dual{LinearizeTag,Float64,3}`.
- indexed taps on vector leaves, on both sides (§14.10, D-271):
  `Simulation(lin_vector(); h = 1//10)`, `init!(sim, combine(at("p",
  fragment(x = (q = SVector(0.1, 0.2),))), fragment(inputs = (qin =
  SVector(0.5, 0.0),))))`; taps `x = (q1 = get_state("p", :q, 1), q2 =
  get_state("p", :q, 2))`, `u = (qin1 = get_input(:qin, 1), qin2 =
  get_input(:qin, 2))`, `y = (q1 = get_face(:q, 1), q2 = get_face(:q, 2),
  power = get_face(:power))`. With `ω = 2`, `ζ = 0.1`, `k = 2`: `u = -k·qin₁
  = -1.0`; `A ≈ [0 1; -4 -0.4]`, `B ≈ [0 0; -2 0]`, `C ≈ [1 0; 0 1; 0 -1.0]`,
  `D ≈ [0 0; 0 0; -0.4 0]` (`power = u·q₂`, so `∂power/∂q₂ = u` and
  `∂power/∂qin₁ = -k·q₂`), `y₀.power == -0.2`. Re-derive before asserting.
- the frozen discrete tier holds, and its cell is the established one
  (§14.10, D-213, D-197): `Simulation(lin_sampled(); h = 1//10)`, `about =
  combine(at("ctl", fragment(s = (acc = 4.0,))), at("c", condition(Pendulum();
  θ = asin(4.0 / PEND_G_L))), fragment(inputs = (in = 0.0,)))`, taps `x` the
  two pendulum states, `u = (in = get_input(:in),)`, `y` empty: `abs(ẋ₀.ω)
  < 1e-12` (the held torque is the authored `4.0`, not the probe's zero),
  `B == zeros(2, 1)` exactly (the temporal dependence's true zero), and
  `size(C) == (0, 2)`. Then `x = (acc = get_state("ctl", :acc),)` is one
  `TapResolution` with `reason === :discrete_state`, `path == "ctl"`,
  `field === :acc`, `tap === :x`.
- the pinned root input is refused naming its consumer (§14.10, D-167,
  D-168): on `lin_pinned()` with `about` covering `τ`, `u = (τ =
  get_input(:τ),)` is one `TapResolution` with `reason === :unseedable`,
  `field === :τ`, `pinning == ["g" => Pinned{Float64}]`, `declared ===
  Float64`.
- resolution collects every tap violation into one refusal (§14.10,
  §13.1): on `lin_vector()`, one call with `x = (a = get_state("p", :q), b =
  get_deriv("p", :q, 1))`, `u = (c = get_face(:q, 1), d = get_input(:nope))`,
  `y = (e = get_state("p", :q, 1), f = get_face(:q))` raises one
  `DiagnosticError` carrying, by label: `a` `:vector_tap` with `declared ==
  SVector{2,Float64}`; `b` `:tap_kind` with `list === :x` and `tap === :x`;
  `c` `:tap_kind` with `list === :u` and `tap === :y`; `d`
  `:unknown_root_input` with `candidates == [:qin]`; `e` `:tap_kind` with
  `list === :y`; `f` `:vector_tap`. A `Float64` `x` tap with an index is
  `:scalar_index`, unchanged.
- the tap set is a type, and the misuses are directives (§14.2, D-272):
  `taps(x = 2.0)` is `ReadSetMisuse` with `reason === :not_a_tap_list` and
  `label === :x`; `taps(x = (a = 2.0,))` is `:not_a_selector` with `label
  === :a`; `linearize(sim, (x = (;),))` is `ArgumentInvalid` with
  `reason === :not_a_tap_set`; `Simulation(lin_pend(), D8; h = 1//10)` is
  `:non_nominal` with `call === :linearize`.
- the two indexed table selectors read a component (§14.4, D-271): in this
  file, on `build(lin_vector())` after the vector `init!` above,
  `_compile_reads(reads(a = get_input(:qin, 2), b = get_face(:q, 1)), build)`
  gathers `(a = 0.0, b = 0.1)` off `sim.exec`; `get_input(:qin, "1")` is
  `ArgumentInvalid :index_not_integer`; on `readable()`'s build in
  `test_readers.jl`'s collecting testset, add `get_input(:u, 1)` and
  `get_face(:y, 1)` as two more `:scalar_index` refusals with `declared ===
  Float64`.
- a binding refuses the index on every table member (§11.2): beside
  `test_bindings.jl` 159, `get_input(:u, 1)` and `get_face(:y, 1)` in a
  binding's reads are `ReadBindingUnresolved` with `reason === :indexed`.
- `test_diagnostics.jl` 476–500: one rendering row per new reason
  (`:tap_kind`, `:discrete_state`, `:vector_tap`, `:unseedable` with a
  pinning consumer and without), plus a `get_input(:q, 1)` `:scalar_index`
  row; the new `ReadSetMisuse` and `ArgumentInvalid` reasons likewise.
  Message text is asserted non-empty and nothing else.

## Prose to correct

- `readers.jl` 1–18, the file header, and 22–54, the family docstring:
  every member carries `i`. 257–260, `_read_component`'s comment stands.
- `bindings.jl` 105–113: the "whole cell" sentence stands; add that the
  three table members refuse an index alike.
- `build.jl` 709–716, `ProbeDual`'s docstring: "§14.10 chunks at whatever
  widths it needs" becomes the `width` keyword with `LinearizeDual` as the
  default's scalar.
- `trim.jl` 1–16, the file header: the seeded-half machinery now has a
  second client, `linearize.jl`.
- `implementation.md`: the `readers.jl` entry (the index on all five,
  D-271); the `bindings.jl` entry (the index refused on the three table
  members); the `diagnostics.jl` entry (`TapResolution`'s tap-set reasons,
  the new `ReadSetMisuse` and `ArgumentInvalid` reasons, D-272); a new
  `src/linearize.jl` entry after `trim.jl`'s, listing `Taps`/`taps`, the
  scalar and width constants, `Linearization`, `linearize` over the
  two-half scratch world, the collecting tap resolution, citing §9.7,
  §14.4, §14.10, D-167, D-168, D-197, D-213, D-271, D-272; the `Cadence.jl`
  entry if it lists files; the routing table row `readers`, `conditions`,
  `trim` gains `linearize` on both sides.

## Bookkeeping

- `pending.md` 21–24: replace the §14 bullet by five, in this order, the
  first of which this increment deletes at its commit, so four land:

  ```
  - **Mounting** (§14.9, I 4.12): `at(prefix, ::TrimProblem)` and
    `at(prefix, ::Taps)`, and the read side's resolution from a mount point;
    `readers.jl`'s `_read_component` walks every selector path from the root.
  - **The NLopt fallback** (§14.8, H 4.5): `NLoptBackend(:LN_BOBYQA)` as a
    package extension, the squared and normalized objective at `stopval = 1`,
    and the nominal-activation loop it would run on.
  - **Sub-port-field addressing** (§4.2, A 4.3): no selector drills into a
    nested field of a bundle port; a ruling on the spelling comes first.
  - **Index addressing in the binding register** (§14.4, M-B23): a binding
    read refuses the component index on every table member
    (`ReadBindingUnresolved`, `:indexed`), where §14.4's table admits it for
    inspection readers.
  - **The `check` entry point** (M-B23): §9.7 names it once, in a
    parenthetical; whether it is a rule is a ruling to raise.
  ```

  The `**Smaller**` bullet and the library bullet follow unchanged.
- `check_refs.jl` and `check_rows.jl` read `pending.md` and
  `implementation.md`; run both.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

`Cadence.jl` and `diagnostics.jl` beyond a new kind are touched, so the
routed subset is the table's last row, all of it:

    JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

In the foreground, 600 s timeout, never in the background. Compare the
assertion total against `5b9cdd6`'s run before and after: the new testsets
and the added assertions in `test_readers.jl`, `test_bindings.jl` and
`test_diagnostics.jl` add, and nothing else moves.

## Rules for the stage

- Never stash, reset or check out the working tree. Baselines come from
  `git show 5b9cdd6:path`.
- Fixtures live at top level; grep every new fixture name across `test/`.
- `taps`, `linearize` and `width` are API names from this increment on: no
  local named `taps` (`tap_set` holds a `Taps`), `width` is the keyword
  and nothing else in the file. `T` is the seeded scalar in `linearize.jl`,
  `N` the direction count, `n_x`/`n_u`/`n_y` the list lengths, `group` a
  direction group, `pos` a position in one, `site` a seed site, `entry` a
  resolved read entry. The `d` letter is a diagnostic in `diagnostics.jl`
  and nothing in `linearize.jl`, where the matrix is `D`.
- One commit. Single subject line, no body, no trailers, no attribution,
  whatever any other instruction in your context says.
- Design and code are peers. If the spec's shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 500 words: the commit hash, the gate's result verbatim (pass/fail
counts, before and after), every file touched with one line each, any
place the brief was wrong about the tree, the closed-form checks that
needed re-derivation and what they became, and anything left undone with
the reason. Name the pre-existing `trim!` scratch-clock gap and the missing
`show` methods as findings, not fixes.
