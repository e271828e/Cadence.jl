# Increment 31 — the always-on conformance check at the generated write

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `7c00fd2`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** A conformance increment. The design landed docs-first at
`7c00fd2` as D-235. The code owes the spec exactly what that entry says, and
nothing else. One stage, one commit.

**Read, all in `docs/design/spec.md`:** §9.5 in full (3399–3522): the
expected type (3405–3422), the names-are-the-pairing rule (3423–3441),
exact-at-nominal and embed-accept (3442–3479), the uniformity paragraph
(3480–3500) and the failure payload (3514–3522); §7.1's "What `Ẋ` is"
(1317–1327); §13.4's species rule (7350–7375); Appendix C's
`ConformanceFailure` row (10414). In `docs/design/decisions.md`: D-235 in
full (8418–8471) — its Position is the shape, its Rejected list is what you
must not build instead; D-053 (1430–1457) for the economics; D-166's
embed-accept paragraph (5585–5588).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–142).
- The file-table rows for `src/leaves.jl` (19), `src/store.jl` (23),
  `src/executor.jl` (24) and `src/build.jl` (25).
- **"Authoring caveats" in full (60–109)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list, so add the ones you introduce there.

In `docs/design/pending.md`, this increment retires two deviation bullets
and one absence clause, named under "Register edits" below. Nothing else in
that file bears on the work.

**Stance: conservative reading.** Build what the sections below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** The spec is written before the code, not instead
of it, and the two are kept mutually consistent. A deviation that improves
the design is raised in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root (the first run after an `src/` edit pays a ~15 s precompile). While
iterating, `julia --project=test test/runtests.jl leaves store build
executor failures events discrete` runs the files this change reaches most
directly; `store.jl` is cross-cutting, so gate on the full suite and then on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push. Never stash, reset or check
out the working tree; a baseline is read with `git show 7c00fd2:path`.

---

## The problem

The probe checks each stage return once, on the initial state's branch,
with the embed-accept relation `_accepts` (`src/build.jl:197–208`). The
runtime writes apply no relation at all:

- `scatter_group!` (`src/store.jl:81–87`) fetches the declared names by
  `getfield` and `scatter!` (`55–67`) writes each leaf as `buf[i] = v`. An
  `Int64` returned where `T` was declared is converted to `1.0`, an extra
  returned field is dropped, and a missing one raises a raw `FieldError`
  (verified on 1.12.7: `getfield((a = 1,), :b)` throws `FieldError`) inside
  a `StepError`.
- `flatten!` (`src/leaves.jl:209–216`) writes the derivative and the two
  wholesale state writes positionally, from `_flatten_expr` (`93–118`):
  a return whose fields are reordered against the state scrambles the
  buffer silently, against §9.5's names-are-the-pairing rule.
- The probe's state checks, `_check_derivative` (`src/build.jl:1087–1110`)
  and `_check_state_write` (`609–630`), compare `nleaves` per field, so an
  `Int64` leaf for a `Float64` state passes at the probe and converts at
  the write. `_check_state_write` also compares key *order*.
- The discrete successor `e.sstore[] = state_update(...)` and the mode
  merge `e.mstore[] = merge(...)` go through `Ref` assignment, which
  converts (verified: `r = Ref((n = 1.0,)); r[] = (n = 1,)` stores
  `(n = 1.0,)`).

D-235 puts one relation at the probe and at every write, against the type
of the cells the stage writes, decided when the write's method is generated
over the cell type and the return type.

## The design core

**One relation.** Move `_accepts` and `_pin_hint` (`src/build.jl:188–212`,
comment block included) to `src/leaves.jl`, after the activation walk
(`retype`, `retype_value`, `_leaf_values`, 170–200), since the generated
writers in `store.jl` call `_accepts` at expansion time and `leaves.jl`
loads first (`src/Cadence.jl:5–11`). `_embed` and `_embed_ports` stay in
`build.jl`. The relation's body does not change.

**The activation scalar at the write.** The relation needs `T` to tell a
declared-`T` cell from a pinned `Float64` one. Read it off the clock every
entry already holds: in `src/store.jl`, next to `Clock`,

```julia
"The activation scalar an executor runs at, read off its clock (§9.4)."
activation_scalar(::Clock{T}) where {T} = T
```

**The component path at the write.** `ConformanceFailure` names the
component path, and the entries hold only `ci`. Add a `path::String` field
to `StageEntry`, `RHSEntry`, `UpdateEntry`, `EventEntry` and `ProjectEntry`
(`src/executor.jl:42–90, 176–218`), filled from `flat.paths[ci]` at the
construction sites in `compile` (`src/build.jl:969–1010`). It is read only
on the throwing path.

**The port write.** Replace `scatter_group!` with a generated function over
the address group, the return type and the scalar:

```julia
# §9.5's always-on check, decided at generation (D-235): the key sets must
# agree as sets, and each returned field must be a lawful arrival at its
# cell under the embed-accept relation. A conformant return type generates
# the straight stores below; a non-conformant one generates a throw, which
# is how the check costs nothing on the conformant path.
@generated function scatter_group!(store, addrs::NamedTuple{Ns}, y::NamedTuple{Ys},
                                   ::Type{T}, path::String, what::Symbol) where {Ns,Ys,T}
    Set(Ys) == Set(Ns) ||
        return :(throw(DiagnosticError(ConformanceFailure(
            path = path, what = String(what), reason = :field_set, shape = :ports,
            observed_fields = $(collect(Ys)), declared_fields = $(collect(Ns))))))
    stmts = Expr[]
    for (i, n) in enumerate(Ns)
        P = fieldtype(addrs, i).parameters[1]        # the cell's type, CellAddr{P,K}
        V = fieldtype(y, n)
        _accepts(P, V, T) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), reason = :field_type, shape = :ports,
                field = $(QuoteNode(n)), observed = $V, declared = $P, activation = $T))))
        push!(stmts, :(scatter!(store, addrs[$i], getfield(y, $(QuoteNode(n))))))
    end
    quote
        $(Expr(:meta, :inline))
        $(stmts...)
        nothing
    end
end
```

`scatter!` itself does not change: once the relation has admitted `V` at
`P`, the per-leaf `buf[i] = v` into the `T` buffer *is* the zero-partial
embedding §9.5 describes, and it is the only conversion left. The call at
`src/executor.jl:147` becomes
`scatter_group!(store, e.outs, y, activation_scalar(e.clock), e.path, e.fname)`.
The seeding call in `compile` (`src/build.jl:960`) passes `T`, `path` and
`:probe`; its products are embedded already and conform by construction.

Verified in a scratch script on 1.12.7 with the pattern above: a
branch-divergent return (`Dual` on one branch, `Float64` on the other, in a
different field order) generates two straight-store specializations and no
conformance throw, embeds the `Float64` as a zero-partial, pairs fields by
name, and allocates nothing; an `Int64` field and an extra field each
generate the throw.

**The state writes.** Add to `src/leaves.jl`, after `flatten!`, a checked
variant for the three state seams — the derivative, the projection's
return and a handler's `x` key:

```julia
"""
    flatten_state!(buf, off, v, XT, T, path, what, shape)

The wholesale state write with §9.5's always-on check decided at generation
(D-235): `v`'s key set must equal the state's, and each field must be a
lawful arrival at the state's field type under embed-accept. Fields pair by
name, never by position. `shape` is the diagnostic's shape: `:init_x` for a
derivative, `:state` for a projection or a handler's `x` key.
"""
@generated function flatten_state!(buf::AbstractVector, off::Int, v::NamedTuple{Vs},
                                   ::Type{XT}, ::Type{T}, path::String, what::Symbol,
                                   shape::Symbol) where {Vs,XT<:NamedTuple,T}
    Xs = fieldnames(XT)
    Set(Vs) == Set(Xs) ||
        return :(throw(DiagnosticError(ConformanceFailure(
            path = path, what = String(what), reason = :field_set, shape = shape,
            observed_fields = $(collect(Vs)), declared_fields = $(collect(Xs))))))
    stmts, base = Expr[], 0
    for k in Xs
        P, V = fieldtype(XT, k), fieldtype(v, k)
        _accepts(P, V, T) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), reason = :field_type, shape = shape,
                field = $(QuoteNode(k)), observed = $V, declared = $P, activation = $T))))
        blk, base = _flatten_expr(P, :(getfield(v, $(QuoteNode(k)))), base)
        push!(stmts, blk)
    end
    quote
        $(Expr(:meta, :inline))
        $(stmts...)
        nothing
    end
end

# A non-NamedTuple return is the law's first clause failing.
flatten_state!(buf, off, v, ::Type{XT}, ::Type{T}, path, what, shape) where {XT,T} =
    throw(DiagnosticError(ConformanceFailure(path = path, what = String(what),
                                             reason = :return_type, shape = shape,
                                             observed = typeof(v))))
```

`_flatten_expr(P, …)` walks the *state's* field type `P` and reads the
value's leaves through it; the relation has guaranteed the value has `P`'s
shape, so the walk is safe and the leaf store embeds where it must. The
four executor sites convert:

- `src/executor.jl:153` (the RHS entry):
  `flatten_state!(ẋbuf, e.x_off, ẋ, XT, activation_scalar(e.clock), e.path, :state_derivative, :init_x)`.
  Delete the trailing comment "shape conformance established at probe time".
- `222` (`run_project!`) and `322` (`_fire_project!`): the same with
  `xbuf`, `:state_projection`, `:state`.
- `314` (`_latch!`'s `x` key): `:handler`, `:state`. The probe names the
  event in `what`; the runtime occurrence cannot without a further field,
  and the register records that (below).

`ProjectEntry` needs the clock for the scalar: add a `clock::CL` field and
type parameter, filled at its construction site. Amend its docstring
(`207–209`) so it no longer claims the probe's completeness makes the write
safe by construction; the write now checks.

`flatten!` stays as it is for the condition-side writes
(`src/conditions.jl:516, 608`), whose values the condition register
validates; they are outside this increment.

**The discrete stores.** Two small generated checks in `src/executor.jl`,
beside `_latch!`:

```julia
# §7.3: a discrete successor is the store's own type exactly — the
# assignment that would convert is refused at generation instead (D-235).
@inline _store_successor!(ref::Base.RefValue{S}, s⁺::S, path, what) where {S} = (ref[] = s⁺; nothing)
_store_successor!(ref::Base.RefValue{S}, s⁺, path, what) where {S} =
    throw(DiagnosticError(ConformanceFailure(path = path, what = String(what),
                                             reason = s⁺ isa NamedTuple ? :field_set : :return_type,
                                             shape = :init_s, observed = typeof(s⁺),
                                             declared = S)))

# §9.5's partial-`m` predicate at the write: every written mode exists and
# keeps its type, decided at generation like the port write.
@generated function _merge_modes!(ref::Base.RefValue{M}, m::NamedTuple{Ms},
                                  path::String, what::Symbol) where {M,Ms}
    for k in Ms
        hasfield(M, k) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), reason = :field_set, shape = :mode,
                field = $(QuoteNode(k)), declared_fields = $(collect(fieldnames(M)))))))
        fieldtype(M, k) === fieldtype(m, k) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), reason = :field_type, shape = :mode,
                field = $(QuoteNode(k)), observed = $(fieldtype(m, k)),
                declared = $(fieldtype(M, k))))))
    end
    :(ref[] = merge(ref[], m); nothing)
end
```

The `UpdateEntry` `run!` (`src/executor.jl:157–163`) calls
`_store_successor!(e.sstore, state_update(...), e.path, :state_update)`;
`_latch!`'s `m` branch calls `_merge_modes!(e.mstore, ret.m, e.path, :handler)`.
Payload fields mirror the probe's `_check_update` (`src/build.jl:1113–1125`)
and its mode check (`691–705`) so `message` renders both occurrences the
same way.

**The probe.** `_check_derivative` and `_check_state_write` take `T` and
apply the relation: replace `keys(x⁺) === keys(x)` with a set comparison,
and `nleaves(typeof(x⁺[k])) == nleaves(typeof(x[k]))` with
`_accepts(typeof(x[k]), typeof(x⁺[k]), T)`; the payload gains
`activation = T`. Call sites: `573` (pass `T`), `595` (`T`), and `691`
inside `probe_events`, which runs at `Float64` (pass `Float64`). The
docstring on `_check_state_write` (`601–608`) says "two shape checks are
sequential"; keep it, it is still true. `_check_ports` and `_embed_ports`
do not change.

**The didactic hint for an integer literal.** §9.5 wants the nominal error
to say "return `zero(x.ω)`, not `0`". Extend `_pin` (`src/diagnostics.jl:307–308`)
so that a `ConformanceFailure` with `observed <: Integer` and
`declared <: AbstractFloat` renders the suffix
`" — an integer literal where a real was declared: return `zero(…)` of a
value at the activation, not `0`"`. Apply the suffix in `message` on the
`:ports`, `:init_x` and `:state` per-field arms (`691–700`), where `_pin`
already applies on `:ports` alone. Do not touch the other arms.

## Tests

A new function `failures_conformance()` in `test/test_failures.jl`,
registered in `test_failures()` (`356–359`) after `failures_runtime()`.
Fixtures at the top of the file, at top level, under a comment naming the
rule they exercise: conformant on the branch the probe sees at `t = 0`,
divergent on the one a later frame takes. Assert with the file's own idiom
(`failure`, `StepError{ConformanceFailure}`, `e.frame`, `lifecycle`).

- **A stage returning an integer on a late branch.** Continuous,
  `output_types = (q = T,)`, `output_state(::_, (; t)) = (q = t < 0.05 ? 1.0 : 0,)`.
  `Simulation(single(...); h = 1//100, t_end = 0.2)`, `init!`, then
  `run!` fails: `e isa StepError{ConformanceFailure}`, `e.cause.reason === :field_type`,
  `e.cause.field === :q`, `e.cause.observed === Int64`,
  `e.cause.declared === Float64`, `e.frame.fn === :output_state`,
  `lifecycle(sim) === :errored`, and `occursin("zero(", message(e.cause))`.
- **An extra field and a missing field on a late branch**, two fixtures:
  `reason === :field_set` with `observed_fields` and `declared_fields` as
  declared.
- **Fields pair by name.** `output_types = (a = T, b = T)`, the stage
  always returning `(b = 2.0, a = 1.0)`: `run!` succeeds and
  `port(sim, "c", :a) == 1.0`, `port(sim, "c", :b) == 2.0`.
- **The derivative pairs by name too.** `init_x = (a = 1.0, b = 2.0)`,
  `state_derivative` returning `(b = 0.0, a = 1.0)`: after `run!` to
  `t_end = 0.1`, `a ≈ 1.1` and `b == 2.0` (read the state through
  `capture` or the port the fixture publishes; the file has precedent).
  This scrambles at the tip; the test must fail there.
- **An integer derivative leaf on a late branch**:
  `state_derivative(::_, (; t)) = (a = t < 0.05 ? -1.0 : 0,)`, species
  with `what == "state_derivative"`, `shape === :init_x`.
- **An integer projection leaf on a late branch**: `init_x = (a = 1.0,)`,
  derivative `(a = -10.0 * x.a,)`, `state_projection(::_, x) = x.a > 0.5 ? (a = x.a,) : (a = 0,)`;
  species with `what == "state_projection"`, `shape === :state`,
  `e.frame.fn === :state_projection`.
- **The embedding at a `Dual` activation.** `init_x = (a = 1.0,)`,
  `output_types = (q = T,)`, `output_state(::_, (; x)) = (q = x.a > 0.5 ? 2.0 * x.a : 0.0,)`,
  derivative `(a = -10.0 * x.a,)`. `Simulation(single(...), D8; h = 1//100)`,
  `init!`, `run!(sim; t_end = 0.2)` succeeds; `port(sim, "c", :q) isa D8`,
  `ForwardDiff.value(...) == 0.0` and `iszero(ForwardDiff.partials(...))`.
  Verified at the tip in a scratch script: the branch flips inside the run
  and the cell holds a zero-partial `D8`; this test pins the behaviour
  through the new write.
- **A discrete successor of the wrong type on a late tick.** A discrete
  leaf like `DiscreteIntegrator` (`test/fixtures.jl:77–86`) with
  `state_update(::_, (; s, t)) = (n = t < 0.05 ? s.n + 1.0 : 0,)`;
  `Simulation(single(...); h = 1//100)` deploys it at `N_base = 1`. Species
  with `what == "state_update"`, `shape === :init_s`.
- **A mode write of the wrong type on a second firing.** Follow `Trigger`'s
  shape (`test/fixtures.jl:190–202`): `init_m = (k = 0,)`, a sign-form guard
  `t - 0.05 * (m.k + 1)`, a handler returning `(m = (k = m.k + 1,))` when
  `m.k == 0` and `(m = (k = 1.5,))` otherwise. The probe sees the first
  firing; the second fires at `t = 0.1` and is refused: species with
  `shape === :mode`, `reason === :field_type`, `field === :k`.

Probe-side, in `test/test_build.jl`'s `build_probe_refusals` (28–39): a
`BadDerivative` sibling whose derivative leaf is `0` for a `Float64` state
fails at `build` with `reason === :field_type`, `observed === Int64`, and a
sibling returning the state's fields reordered builds and runs. The
existing `BadDerivative` assertion (34–35) must keep passing.

The existing canary (`test/test_executor.jl`, both testsets) must stay green
unchanged: it is the empirical fold §9.5 names. Do not add `code_typed`
assertions.

Every new framework name a test calls (`message` is already listed; check
`flatten_state!`, `activation_scalar` if you assert on them) goes on
`test/imports.jl`.

## Register edits

- `docs/design/pending.md`:
  - Delete the deviation bullets **"The runtime table write converts"**
    (148–151) and **"Derivative and projection conformance is checked by
    leaf count"** (152–155).
  - In the absence bullet at 59, delete the clause "**§9.5's always-on
    conformance check** (the return laws are checked once, at the probe;
    what stands in its place is a deviation, below); " so the bullet opens
    with "**§8.3 visibility**".
  - In the payload-column bullet, change "`ConformanceFailure` no
    simulation time on its runtime occurrences" to "`ConformanceFailure`
    no simulation time on its runtime occurrences and no event name on a
    handler's".
  - The section intro's "All but the last two were found by the audit"
    (126) stays true.
- `docs/design/implementation.md`:
  - `src/leaves.jl` row (19): append ", embed-accept's relation `_accepts`
    (D-166) and the checked state write `flatten_state!` (D-235)" to the
    implements column; add `§9.5, D-166, D-235` to the citations.
  - `src/store.jl` row (23): "gather/scatter" → "gather and the checked
    scatter (§9.5's always-on check decided at generation, D-235)"; add
    `§9.5, D-235`.
  - `src/executor.jl` row (24): "entries" → "entries (each carrying its
    component's path, for the write's diagnostic)"; add `§9.5, D-235`.
  - `src/build.jl` row (25): "embed-accept" → "the probe's embedding of
    products (`_embed`)"; add `D-235`.
- Run `julia --project=@. docs/design/tools/check_refs.jl` and
  `julia --project=@. docs/design/tools/check_rows.jl` after the register
  edits; both must pass.

## Verification

- Full suite green in the foreground, then `Pkg.test()` green.
- `rg -n "nleaves\(typeof" src/build.jl` is empty.
- `rg -n "flatten!\(" src/executor.jl` is empty.
- `rg -n "shape conformance established" src/` is empty.
- `test/test_executor.jl` unchanged (`git diff --stat` does not list it).
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; the `what` spelled for
each runtime occurrence; any test from the list above you could not write
as specified and why, with file:line; the assertion totals before and
after; friction with this brief, especially any line number that had
drifted.
