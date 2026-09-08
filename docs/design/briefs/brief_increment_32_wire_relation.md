# Increment 32 — the wire relation, the root meet, the Stratum A pass

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `236a964`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** A conformance increment. The design landed docs-first at
`7c00fd2` as D-236, and its Appendix C and D-229 consistency fix lands ahead
of this stage as `236a964` (see "Docs first" below; D-229's Rejected list
and everything after it in the log sit four lines lower than cited). The
code owes the spec exactly what D-236 says, and nothing else. One stage, one
commit.

**Read, all in `docs/design/spec.md`:** §6.1's "Type-checking a wire"
(1085–1126) in full; §8.2's `input_types` subsection (1958–2079): the three
entry forms (1968–1996), the two clauses (2004–2023), root inputs and the
meet (2042–2079); §9.1's Stratum A (2920–2961), the two type clauses at
2952–2961; §13.1's dependency rule (7069–7089); §4.4's substitutability
paragraph (533–539); Appendix C's rows `WireTypeMismatch` (10385),
`WalkingFaceAtFrozenEntry` (10386), `AbstractAtRoot` (10388),
`RootInputTypeConflict` (10389); the glossary's *abstract entry*
(10492–10496). In `docs/design/decisions.md`: D-236 in full (8472–8528) —
its Position is the shape, its Rationale records the one admitted limit, its
Rejected list is what you must not build instead; D-167 (5652–5722) for the
tier scope and the failure asymmetry; D-168 (5723–5760) for the meet, with
its 2026-09-08 annotation; D-229 (8190–8240) for where a pass runs and where
the throw is; D-166's embed-accept (5562–5651) for the relation this one
extends.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–144).
- The file-table rows for `src/leaves.jl` (19), `src/diagnostics.jl` (20),
  `src/declare.jl` (21), `src/assembly.jl` (22) and `src/build.jl` (25).
- **"Authoring caveats" in full (60–108)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list, so add the ones you introduce there; a type's
  printed form depends on the printing module.

In `docs/design/pending.md`, this increment retires two deviation bullets
and two names in one absence clause, named under "Register edits" below.
Nothing else in that file bears on the work.

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
iterating, `julia --project=test test/runtests.jl leaves diagnostics build
assembly conditions trace` runs the files this change reaches most directly;
`diagnostics.jl` is cross-cutting, so gate on the full suite and then on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push. Never stash, reset or check
out the working tree; a baseline is read with `git show 236a964:path`.

---

## The problem

Every claim below was checked at the tip on Julia 1.12.7.

- **The only wire check is at the probe, on the value.** `_probe_input`
  (`src/build.jl:1040–1061`) compares the probed value's type against the
  entry at the current activation with `_accepts`
  (`src/leaves.jl:212–224`) and throws one `WireTypeMismatch` fail-fast.
  That is one stratum late and blind to the walk clause at nominal: a
  continuous consumer declaring `u = Float64` fed by a producer declaring
  `val = T` builds clean at `Float64` and fails only when a `Dual`
  activation is first materialized, with the output-side hint ("declare it
  `T`") aimed at the wrong endpoint. §6.1 promises the failure at the first
  nominal build, at the wire, both endpoints named.
- **Nominal acceptance is identity, not `<:`.** `_accepts` requires
  `P.name === V.name` on struct types, so an entry declared abstract
  (`f = AbstractField`, `v = AbstractVector{T}`, `u = Real`) refuses its
  lawful concrete producer. §4.4's substitutability and §8.2's abstract
  entries have no code (M-B3).
- **The root input takes the first consumer's entry.** `_root_input_type`
  (`src/build.jl:309–323`) returns `first(declared)`, so a root input fanned
  into a `T` entry and a pinned `Float64` entry walks or pins by declaration
  order: `_fanned_root(RealEntry(), PinnedEntry())` at `D8` fails with
  `WireTypeMismatch` blaming the pinned consumer, and the swapped order
  builds with a `Float64` cell (M-B2). It also compares every consumer's
  entry for identity, so an abstract co-consumer would report
  `RootInputTypeConflict`.
- **Abstract at root has no diagnostic.** A `Real` entry surfacing as a root
  input reaches `probe_value` (`src/declare.jl:327`), which synthesizes
  `zero(Real) === 0`, and the probe refuses it blaming an `Int64`. An
  abstract struct entry throws a raw `ArgumentError` from `leaf_types`
  (`src/leaves.jl:27`, "type does not have a definite number of fields")
  inside `place!`. Neither `AbstractAtRoot` nor `WalkingFaceAtFrozenEntry`
  has a struct (`pending.md:21`).
- **No marker pass exists.** `declarations(c, t, T)` (`src/build.jl:34–39`)
  retypes `init_x` by value, so it cannot run at a marker; the pass below
  evaluates `input_types` and `output_types` alone.

Two traps the code does not warn about, both verified:

- `retype` (`src/leaves.jl:185–189`) replaces every `Float64` *type
  parameter*. Applied to a declaration already evaluated at a `Dual` it
  nests the `Dual` (`retype(D8, SVector{3,D8})` is
  `SVector{3, Dual{Nothing, D8, 8}}`), and applied to a `Union` or a
  `UnionAll` it throws a `FieldError` on `.parameters`. The lifted
  candidate below must never be built by retyping a `T`-evaluated type
  without the short-circuit this brief adds.
- Only type parameters walk. A non-parametric struct with `Float64` fields
  (`struct Pose; p::SVector{3,Float64}; end`) evaluates to itself at every
  scalar and is pinned wholesale; a walking struct is parametric
  (`Pose{T}`). Test fixtures that need a walking struct leaf must be
  parametric, or the walk clause has nothing to refuse.

## The design core

### The relation

`V` (the producer's declaration at an activation) is accepted at `P` (the
entry at the same activation) when some leafwise embedding of `V`, lifting
any subset of its `Float64` leaves to `T`, is `<:` `P` (D-236). In
`src/leaves.jl`, directly after `_pin_hint` (226–229):

```julia
"""
    _accepts_wire(P, V, T)

Is a producer declaring `V` a lawful feed for an entry declaring `P`, both
evaluated at activation `T` (§6.1, D-236)? A concrete entry is `_accepts`
leaf by leaf. An abstract entry has no leaves to walk, so it is decided on
the whole declaration: `V` as declared, or `V` with every pinned leaf lifted
to `T`, must be `<:` `P`. The two candidates are exact whenever `P`'s
parameters are uniformly `T` or uniformly pinned; the mixed case is D-236's
recorded limit.
"""
_accepts_wire(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T} =
    isconcretetype(P) ? _accepts(P, V, T) : (V <: P || retype(T, V) <: P)
```

`retype` gains the short-circuit and the guard that make the lifted
candidate safe on a `T`-evaluated declaration (verified: idempotent,
`retype(D8, Pose{Float64})` is `Pose{D8}`, `retype(D8, Pose{D8})` is
unchanged, a `Union` or `UnionAll` passes through):

```julia
"""
    retype(T, P)

`P` with every `Float64` position replaced by `T`; a position already at `T`
stays, so the walk is idempotent. Build time only.
"""
retype(::Type{T}, ::Type{Float64}) where {T} = T
function retype(::Type{T}, ::Type{P}) where {T,P}
    P === T && return P
    P isa DataType && !isempty(P.parameters) || return P
    P.name.wrapper{(p isa Type ? retype(T, p) : p for p in P.parameters)...}
end
```

`retype_value` and every other caller are unaffected: `init_x` values are
written at `Float64` and never carry `T`.

Verified at `D8` with this pair: entry `AbstractVector{T}` accepts
`SVector{3,T}` and pinned `SVector{3,Float64}`; entry `SVector{3,Float64}`
refuses `SVector{3,T}` and accepts `SVector{3,Float64}`; entry `Real`
accepts `T` and `Float64`; entry `AbstractField` accepts `FieldA`. At the
marker: `Float64` entry refuses a `Marker` leaf, `Marker` entry accepts
`Float64`, `Int` accepts `Int`, `AbstractVector{Float64}` refuses
`SVector{3,Marker}`.

### The marker scalar

In `src/build.jl`, at the head of a new section "Stratum A's wire pass"
placed after `_check_event_declarations` (397–415):

```julia
"""
The marker scalar (§6.1, §9.1): the continuous contracts are evaluated at it
to tell a walking leaf from a pinned one — a leaf typed `Marker` walks with
the activation, anything else is pinned. It never enters arithmetic.
"""
struct Marker <: Real end
Base.show(io::IO, ::Type{Marker}) = print(io, "T")   # a declaration at the marker prints as written
```

The `show` method is the one place a framework type gets one: it makes a
declaration evaluated at the marker render as the author wrote it
(`SVector{3, T}`), which is what a `WalkingFaceAtFrozenEntry` message shows.
The payload keeps the true type; tests match `=== Marker`.

`declared_at` (`src/declare.jl:250–253`) gains the scalar as an optional
fourth argument, `Float64` by default, so the pass reads both evaluations
through the one helper that already guards the arity:

```julia
declared_at(fn, c, t::Tier, ::Type{S} = Float64) where {S} =
    t === CONTINUOUS ? (_declares(fn, c, Type{Float64}) ? fn(c, S) : NamedTuple()) :
                       (_declares(fn, c) ? fn(c) : NamedTuple())
```

A contract bounded narrower than `Real` (`where {T <: AbstractFloat}`) has
no method at the marker and raises a raw `MethodError` here; it already
raises one at any `Dual` activation today. Record it in the register (below);
do not add a check.

### The Stratum A pass

`build` (`src/build.jl:372–391`) becomes:

```julia
    flatten!(w, root, diags)
    _check_event_declarations(w.flat, diags)
    # The dependency rule (§13.1, D-229): the wire pass reads the wiring, which a
    # dirty walk never produced, so it runs on a clean walk alone.
    isempty(diags) || throw(DiagnosticError(diags))
    flat = wire!(w)
    tiers = Vector{Tier}(w.tiers)
    _check_wires(flat, tiers, diags)
    # Stratum A's barrier (§13.1, D-229): every pass that ran merges here, and
    # nothing derived from the wiring is computed before it. No cascade
    # suppression — a typo'd wire reports its unknown port *and* the input it
    # left unfed.
    isempty(diags) || throw(DiagnosticError(diags))
    nominal, order = _stratum_c(flat, tiers, nothing, nothing, Float64)
```

The first throw is not a second barrier: it is D-229's rule that a pass whose
input never came to exist does not run. `wire!` (`src/assembly.jl:701–713`)
indexes `w.feeds` for every face, which a failed wire leaves absent, so it
cannot run on a dirty walk either. Amend `build`'s docstring (364–371) to
list the wire check: "flatten, classify, type-check the wires, probe at
`Float64`, schedule, lay out".

The pass, sketched; the shape is prescribed, the spelling is yours:

```julia
# Stratum A's wire pass (§6.1, §9.1, D-236): the two type clauses on every
# resolved wire, and the root-input type with its two refusals. Pure
# declaration reading — the contracts are evaluated at `Float64` for the bound
# clause and at the marker for the walk clause; no stage runs. The pass
# collects (§13.1): every wire is checked, and the barrier throws once.
function _check_wires(flat::Flat, tiers::Vector{Tier}, diags::Vector{Diagnostic})
    at(fn, S) = [declared_at(fn, c, t, S) for (c, t) in zip(flat.comps, tiers)]
    ins_F, outs_F = at(input_types, Float64), at(output_types, Float64)
    ins_M, outs_M = at(input_types, Marker), at(output_types, Marker)
    for (ci, conns) in enumerate(flat.conns), (face, (ppath, pport)) in conns
        isempty(ppath) && continue                  # a root input: typed below
        pi = index_of(flat, ppath)
        P_F, V_F = ins_F[ci][face], outs_F[pi][pport]
        if !_accepts_wire(P_F, V_F, Float64)
            push!(diags, WireTypeMismatch(path = flat.paths[ci], face = face, declared = P_F,
                                          producer_path = ppath, producer_port = pport,
                                          observed = V_F))
            continue        # the walk clause reads a shape the bound clause has vouched for
        end
        tiers[ci] === CONTINUOUS || continue        # D-167's tier scope
        P_M, V_M = ins_M[ci][face], outs_M[pi][pport]
        _accepts_wire(P_M, V_M, Marker) && continue
        leaf, declared, observed = _walking_leaf(P_M, V_M)
        push!(diags, WalkingFaceAtFrozenEntry(path = flat.paths[ci], face = face,
                                              producer_path = ppath, producer_port = pport,
                                              leaf = leaf, declared = declared,
                                              observed = observed))
    end
    for face in flat.root_inputs
        # every consumer's (path, entry face, entry at Float64) for this root input
        ...
        conc = findall(isconcretetype, entries)
        if isempty(conc)
            push!(diags, AbstractAtRoot(face = face, paths = paths, declared = entries))
            push!(flat.root_types, nothing)
            continue
        end
        P_F = entries[first(conc)]
        any(k -> entries[k] !== P_F, conc) &&
            push!(diags, RootInputTypeConflict(face = face, paths = paths[conc],
                                               declared = entries[conc]))
        for k in eachindex(entries)                 # abstract co-consumers: the bound clause
            k in conc && continue
            _accepts_wire(entries[k], P_F, Float64) ||
                push!(diags, WireTypeMismatch(path = paths[k], face = faces[k],
                                              declared = entries[k], producer_path = "",
                                              producer_port = face, observed = P_F))
        end
        push!(flat.root_types, P_F)
    end
    nothing
end
```

Discrete producers and consumers evaluate to their plain declarations at both
scalars, which is what makes a continuous → discrete wire pass the bound
clause alone and a discrete → continuous wire pass the walk clause (a pinned
leaf satisfies either entry). The existing `pair()` in `build_activations`
(`test/test_build.jl:305–306`) is the first case and must keep building.

`_walking_leaf(P_M, V_M)` names the offending leaf. For a concrete entry the
bound clause has established that `leaf_types(P_M)` and `leaf_types(V_M)`
align, and a walk failure is exactly a pinned entry leaf fed by a walking
producer leaf (verified on `Pose{Float64}` fed by `Pose{T}`: leaf `p[1]`,
entry `Float64`, producer `Marker`):

```julia
function _walking_leaf(::Type{P}, ::Type{V}) where {P,V}
    isconcretetype(P) || return nothing, P, V     # decided on the whole declaration
    lp, lv = leaf_types(P), leaf_types(V)
    i = findfirst(k -> lp[k] === Float64 && lv[k] === Marker, eachindex(lp))
    i === nothing && throw(InternalInvariant("walk clause failed at `$P` ← `$V` with no walking leaf"))
    leaf_names(P)[i], lp[i], lv[i]
end
```

`leaf_names(Float64)` is `[""]`: a scalar entry's leaf is the face itself,
and the message omits the "at leaf" clause when `leaf` is empty.

**`Flat` carries the root-input types.** Add `root_types::Vector{Any}` to
`Flat` (`src/assembly.jl:542–552`), per root input in `root_inputs` order,
filled by the pass (`nothing` where it refused; the barrier throws before any
reader). Update the `Walk()` constructor (572–579), the only construction
site. Stratum C then reads the type §8.2 fixes at nominal without
re-evaluating anything, which it could not do at a `Dual` activation, where
its `decls` are at `Dual` and no `Float64` entry is in hand.

### The diagnostics

In `src/diagnostics.jl`, beside `WireTypeMismatch` and `RootInputTypeConflict`
(288–329):

- `WireTypeMismatch` loses its `activation` field and the `_pin(d)` suffix
  in its message: the bound clause runs at `Float64`, where the hint never
  fires, and Appendix C's payload column does not list it. Its docstring
  (288) becomes "§6.1, §8.2, §8.4 w4: a wire whose producer's declaration at
  `Float64` is not `<:` the consumer's entry at `Float64`". The generic
  `_pin` (305–309) then has no caller; delete it, keeping the
  `ConformanceFailure` method (685) and its comment. Update the construction
  in `test/test_diagnostics.jl:247–248`.
- `RootInputTypeConflict`'s docstring (311–318) still holds; add that the
  comparison runs in Stratum A's wire pass over the concrete entries alone,
  abstract co-consumers being checked against the type by the bound clause.
- Two new kinds, with `path` methods and messages in the didactic register:

```julia
"§6.1, §8.2: a walking producer leaf feeding a pinned entry leaf of a continuous consumer."
Base.@kwdef struct WalkingFaceAtFrozenEntry <: Diagnostic
    path::String                             # the consumer
    face::Symbol                             # its entry
    producer_path::String
    producer_port::Symbol
    leaf::Union{Nothing,String}              # the offending leaf's dotted spelling; `nothing` when the entry is abstract
    declared::Any                            # the entry's type there: a pinned leaf type, or the whole abstract entry
    observed::Any                            # the producer's declaration there, at the marker
end

"§8.2: a root input whose consumers all declare abstract entries, so no type determines it."
Base.@kwdef struct AbstractAtRoot <: Diagnostic
    face::Symbol
    paths::Vector{String}                    # the consuming leaves
    declared::Vector{Any}                    # their abstract entries
end
```

`WalkingFaceAtFrozenEntry`'s message carries both remedies verbatim from
Appendix C: "declare the entry `T` if the consumer promotes; feed it from a
non-walking source if the freeze is genuine". `AbstractAtRoot`'s carries the
remedy with the face: wire it to a concrete producer, in a test rig a stub
child (§13.7). `path(d::AbstractAtRoot)` is `""`, the root's, as
`RootInputTypeConflict`'s is. Add one occurrence of each to the kinds list
in `test/test_diagnostics.jl` (236–262, the Stratum A group).

### The layout and the probe

`cell_layout` (`src/build.jl:258–295`) places each root input at the meet.
Replace `_root_input_type` and its comment block (297–323) with:

```julia
# A root input's cells at an activation: D-168's meet, at the level of the whole
# root input, with D-236's two candidates — the root-input type with every leaf
# following `T` when every consumer's entry at `T` admits it, the root-input
# type itself otherwise. Stratum A fixed the type and checked the entries, so
# nothing is recorded here; at nominal the two candidates coincide.
function _root_input_cell(flat::Flat, decls::Vector{Decls}, i::Int, face::Symbol,
                          ::Type{T}) where {T}
    P_F = flat.root_types[i]
    walk = retype(T, P_F)
    entries = (decls[ci].ins[f] for (ci, conns) in enumerate(flat.conns)
               for (f, producer) in conns if producer === ("", face))
    all(e -> _accepts_wire(e, walk, T), entries) ? walk : P_F
end
```

and the root loop becomes `for (i, face) in enumerate(flat.root_inputs)`,
placing `_root_input_cell(flat, decls, i, face, T)`. A pinned candidate is
accepted by every entry by construction; `IllegalPortType` at `place!` still
guards a type with no leaves. Rewrite `cell_layout`'s header comment
(242–250) to say the root input's type is Stratum A's and the layout picks
its cells per activation.

Verified with the sketch: entries `(T, Float64)` give a `Float64` cell at
`D8`; `(SVector{3,T}, AbstractVector{T})` give `SVector{3,D8}`;
`(SVector{3,T}, AbstractVector{Float64})` give `SVector{3,Float64}`.

**`_probe_input`** (1040–1061) keeps its value routing and loses its
`WireTypeMismatch`. Both clauses are decided in Stratum A; the products
`_embed_ports` hands down have exactly the producer's declared type at `T`,
and a root input's cell admits every entry by the meet, so a refusal here
can only be a framework bug. Fence it:

```julia
    _accepts_wire(P, typeof(v), T) ||
        throw(InternalInvariant("probe input `$path`.$face: $(typeof(v)) at an entry declaring $P, which Stratum A admitted"))
```

Rewrite its comment (1040–1047) accordingly. The report says this is the
choice made (fence, not deletion) and why.

## Tests

Fixtures at top level, each under a comment naming the rule it exercises. A
walking struct leaf must be parametric (see the trap above).

In `test/test_leaves.jl`, a testset "the wire relation with its abstract arm
(§6.1, D-236)" asserting `_accepts_wire` directly on the worked cases listed
under "The relation" above, at `D8`, at `Float64` and at `Marker`, plus
`retype`'s idempotence (`retype(D8, retype(D8, P)) === retype(D8, P)`) and
its pass-through on `AbstractVector` and `Union{Float64,Int}`. Add
`_accepts_wire` and `Marker` to `test/imports.jl`.

In `test/test_build.jl`, extend `build_root_input_type` (104–122) and add a
section "the two wire clauses in Stratum A (§6.1, §9.1, D-236)" after it,
registered in `test_build` (337–346). Reuse `RealEntry`, `PinnedEntry`,
`BoolEntry`, `_fanned_root` (83–102) and `NomSource` (290–292).

- **An abstract struct entry.** `abstract type AbstractField end`, two
  isbits producers `FieldA <: AbstractField` (`a::Float64`) and
  `FieldB <: AbstractField` (`b::SVector{2,Float64}`), each behind a
  stage-1 source whose `output_types` names the concrete type and whose
  `output_state` returns a constant (`FieldA(2.0)`; a `Dual` `t` would not
  convert into the pinned field), and a consumer `FieldReader` with
  `input_types = (f = AbstractField,)`, `output_types = (out = T,)`,
  `output_direct = (out = value(u.f),)` over a two-method `value`. Both
  wirings build, run a few frames at `Float64` and at `D8`, and
  `port(sim, "r", :out)` is the producer's value: the bundle field carried
  the concrete type.
- **A `Real` entry fed by a `T` producer.** `RealReader` with
  `input_types = (u = Real,)`, `output_types = (out = T,)`,
  `output_direct = (out = 2 * u.u,)`, fed by `NomSource`: builds at nominal;
  at `D8`, `port(sim, "r", :out) isa D8`.
- **`AbstractVector{T}` fed by `SVector{3,T}` and by a pinned
  `SVector{3,Float64}`.** `VecReader` with `input_types = (v = AbstractVector{T},)`,
  `output_types = (n = T,)`, `output_direct = (n = sum(u.v),)`; two
  producers, one declaring `SVector{3,T}`, one `SVector{3,Float64}`. Both
  build at `D8`; the pinned one's `port(sim, "r", :n) isa D8` (a `Float64`
  sum embedded at the write, D-235).
- **Abstract at root.** `Group((; r = FieldReader()); inputs = ("f" => "r/f",))`
  → `only(diagnostics(err)) isa AbstractAtRoot`, `face === :f`,
  `paths == ["r"]`, `declared == [AbstractField]`, `path(d) == ""`. Two
  such faces in one model (`FieldReader` and `RealReader`) report together
  in one throw. Assert today's raw `ArgumentError` is gone: the failure is a
  `DiagnosticError`.
- **The meet.** `Simulation(build(_fanned_root(RealEntry(), PinnedEntry())), D8; h = 1//100)`
  builds; `port(sim, "", :in) isa Float64` (the root input's own cell) and
  `port(sim, "a", :y) isa D8`. The swapped order gives the same. With two
  `RealEntry`s the cell is a `D8`. The first of these fails at the tip
  (verified: `WireTypeMismatch` blaming `b`).
- **An abstract co-consumer under fan-out.** A concrete `SVector{3,T}`
  entry beside `VecReader`'s `AbstractVector{T}` on one root input builds,
  no `RootInputTypeConflict`, and the cell at `D8` is `SVector{3,D8}`;
  beside a pinned `SVector{3,Float64}` entry it is `SVector{3,Float64}`.
  An abstract co-consumer whose bound fails — `FieldReader`'s
  `AbstractField` beside `RealEntry`'s `T` on one face — is
  `WireTypeMismatch` with `producer_path == ""`, `producer_port === :in`,
  `observed === Float64`, `declared === AbstractField`. The existing
  `RealEntry`/`BoolEntry` conflict assertions (106–116) stay as they are.
- **Forgotten `T` at the wire.** `FrozenEntry`, continuous, with
  `input_types = (u = Float64,)`, `output_types = (y = T,)`,
  `output_direct = (y = u.u,)`, fed by `NomSource`: `build` fails at
  nominal with `WalkingFaceAtFrozenEntry`, `path == "c"`, `face === :u`,
  `producer_path == "src"`, `producer_port === :val`, `leaf == ""`,
  `declared === Float64`, `observed === Marker`, and
  `occursin("declare the entry `T`", message(d))`. Verified at the tip:
  this model builds clean and fails only at `activation(b, D8)`.
- **The offending leaf is named.** A parametric `Pose{T}` (`p::SVector{3,T}`,
  `n::Int`) produced walking and consumed at an entry `Pose{Float64}`:
  `leaf == "p[1]"`, `declared === Float64`, `observed === Marker`.
- **The bound clause collects.** `NomSource` wired into `BoolEntry`'s `u`
  is `WireTypeMismatch` with `declared === Bool`, `observed === Float64`,
  both endpoints named; two such wires in one model give two diagnostics in
  one throw; a bound failure, a walk failure and an abstract-at-root face in
  one model give the three kinds in one throw
  (`Set(kinds(err))`). A model with an unfed input beside a bad wire reports
  the walk's kinds alone: the pass did not run (`build_stratum_a`'s idiom,
  235–244).
- **The discrete scope.** `build_activations`' `pair()` (a `T` producer into
  a discrete `Float64` entry) keeps building, unchanged.

Every new framework name a test calls goes on `test/imports.jl`:
`WalkingFaceAtFrozenEntry`, `AbstractAtRoot`, `_accepts_wire`, `Marker`.

## Register edits

- `docs/design/pending.md`:
  - In the absence bullet at 18–23, change "likewise `IllegalStateLeaf`,
    `MissingProbeValue`, `AbstractAtRoot`, `TierSignatureMismatch` and
    `WalkingFaceAtFrozenEntry`, whose *checks* are absent" to "likewise
    `IllegalStateLeaf`, `MissingProbeValue` and `TierSignatureMismatch`,
    whose *checks* are absent (a contract bounded narrower than `Real` also
    reaches the marker evaluation, and any `Dual` activation, as a raw
    `MethodError`)".
  - Delete the deviation bullets **"The D-168 fan-out meet is not
    implemented"** (135–139) and **"Nominal acceptance is equality modulo
    embedding, not `<:`"** (140–146).
  - The section intro's "All but the last two were found by the audit"
    (125) stays true.
- `docs/design/implementation.md`:
  - `src/leaves.jl` row (19): after "embed-accept's relation `_accepts`
    (D-166)" insert "and the wire relation `_accepts_wire` with its abstract
    arm (D-236)"; add `§6.1, D-236` to the citations.
  - `src/assembly.jl` row (22): after "`wire!` deriving the two-sided face
    graph after the barrier" insert ", `Flat.root_types` holding the
    root-input types the wire pass fixes"; add `D-236`.
  - `src/build.jl` row (25): after "`build` owning Stratum A's one throw"
    insert ", the wire pass (both type clauses at `Float64` and at the marker
    scalar, the root-input type and its two refusals; D-236)"; replace "the
    layout" with "the layout with the root-input meet (D-168, D-236)"; add
    `§6.1, D-236`.
- Run `julia --project=@. docs/design/tools/check_refs.jl` and
  `julia --project=@. docs/design/tools/check_rows.jl` after the register
  edits; both must pass.

## Docs first

Landed as `236a964`, ahead of the stage. D-236 moved both clauses to Stratum
A and collected them; two places still said the bound check is fail-fast:

- Appendix C's `WireTypeMismatch` row (10385): the policy cell "fail-fast —
  with the probe chain (D-229)" becomes "collected".
- D-229's Position (8204–8206) names "the wire bound check" among the checks
  that fail fast with the chain. Under the log's rule 1 the entry is
  annotated, not rewritten: at the end of its Rationale, "Annotation
  (2026-09-08): the wire bound check moved to Stratum A's wire pass with
  D-236 and collects under that stratum's barrier; the chain's fail-fast
  keeps stage-2 conformance and two-stage production."

Then `linkify.jl`, `check_refs.jl`, `check_rows.jl`; commit.

## Verification

- Full suite green in the foreground, then `Pkg.test()` green.
- `rg -n "WireTypeMismatch" src/build.jl` lists the wire pass alone.
- `rg -n "_root_input_type|activation = T\)" src/build.jl` is empty.
- `rg -n "_pin\(" src/diagnostics.jl` lists the `ConformanceFailure` method
  and its three callers only.
- `rg -n "leaf_types|nleaves" src/build.jl` gains no evaluation-path call
  (`_walking_leaf` runs on the throwing path only).
- `test/test_executor.jl` unchanged (`git diff --stat` does not list it).
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; where the marker and
the pass live; the `_probe_input` choice and why; any test from the list
above you could not write as specified and why, with file:line; any place
the spec and this brief disagreed; the assertion totals before and after;
friction with this brief, especially any line number that had drifted.
