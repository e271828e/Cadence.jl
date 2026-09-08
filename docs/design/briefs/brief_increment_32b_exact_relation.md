# Increment 32b — the exact relation, and the narrow-bound arm of `TierSignatureMismatch`

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `73ac506`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** Increment 32's two review findings, each ratified docs-first at
`73ac506`: D-238 decides embed-accept on the type, and `TierSignatureMismatch`
gains its narrow-bound arm (§8.5, Appendix C). The code owes the spec exactly
those two things. **One stage, two commits**, in the order below: the
relation first, because the second commit's test reads a wire the first
commit's relation admits. Suite green after each.

**Read, all in `docs/design/spec.md`:** §9.5's "Exact match at nominal"
paragraph (3447–3485), the D-238 sentence at 3460–3464; §6.1's bound-check
paragraph (1089–1092); §8.5's "Contract signature shape follows the class"
(2550–2569); Appendix C's rows `TierSignatureMismatch` (10402) and
`DeclarationOnWrongTier` (10401). In `docs/design/decisions.md`: D-238 in
full (8575–8609) — its Position is the relation, its Rejected list names the
built shape you are replacing; D-166's embed-accept paragraph (5585–5590)
and its 2026-09-08 annotation (5633–5634); D-235's Position (8418–8430) for
the writes that call the relation at generation; D-167's mandated signature
(5652–5665).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–144).
- The file-table rows for `src/leaves.jl` (19), `src/diagnostics.jl` (20),
  `src/declare.jl` (21) and `src/build.jl` (25).
- **"Authoring caveats" in full (60–108)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`, this increment retires one deviation bullet and
one name in the absence clause, and moves one clause; all named under
"Register edits" below.

**Stance: conservative reading.** Build what the sections below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root. While iterating, `julia --project=test test/runtests.jl leaves store
build failures diagnostics` runs the files this change reaches most directly;
the relation sits under every write, so gate each commit on the full suite,
and the second commit on `julia --project=. -e 'using Pkg; Pkg.test()'` as
well. Commit subject: one sentence, no body, no attribution. Do not push.
Never stash, reset or check out the working tree; a baseline is read with
`git show 73ac506:path`.

---

## Commit 1 — the exact relation (D-238)

### The problem

`_accepts` (`src/leaves.jl:214–226`) is D-166's relation checked on the
leaves: a struct's name and field types, a static array's size and eltype.
Three facts that distinguish concrete types are type parameters, not leaves,
and it never looks at them. Verified at the tip:

| entry `P` | arrival `V` | `_accepts` | `<:` |
|---|---|---|---|
| `@NamedTuple{a::Float64}` | `@NamedTuple{b::Float64}` | true | false |
| `Labeled{:a}` | `Labeled{:b}` | true | false |
| `SVector{3,Float64}` | `MVector{3,Float64}` | true | false |

A wire between such types passes Stratum A and fails at the probe as a raw
`FieldError` inside the consumer's stage, or runs with the wrong tag. The
same relation decides the D-235 writes at generation (`src/store.jl:96`,
`src/leaves.jl:280`) and the probe's checks (`src/build.jl:178, 668, 1155`),
so the laxity reaches every seam.

### The relation

D-238: `V` is accepted at `P` at activation `T` when lifting `V`'s `Float64`
positions to `T` exactly where `P` has `T` yields `P`, compared by identity.
Decided without constructing a type, by walking the two parameter lists in
parallel; the lift is the second line. Replace the body of `_accepts`
(`src/leaves.jl:215–226`) with:

```julia
function _accepts(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T}
    P === V && return true
    V === Float64 && P === T && return true          # the one embedding
    (P isa DataType && V isa DataType && P.name === V.name && !isempty(V.parameters) &&
     length(P.parameters) == length(V.parameters)) || return false
    all(p isa Type && v isa Type ? _accepts(p, v, T) : p === v
        for (p, v) in zip(P.parameters, V.parameters))
end
```

Rewrite the section comment (206–212) and the docstring (214) to D-238's
terms: the relation is decided on the type; a parameterless type compares by
identity; a `Float64` lifts to `T` where `P` has `T` and nowhere else. Keep
the constant-branch sentence, it is still the point.

Verified on 25 cases at the tip, with these verdicts: `D8 ← Float64` at `D8`
true, `Float64 ← D8` false, `D8 ← Int` false, `Int ← Int` true,
`SVector{3,D8} ← SVector{3,Float64}` true and the converse false,
`SVector{3,Float64} ← SVector{2,Float64}` false, `Pose{D8} ← Pose{Float64}`
true and the converse false, a non-parametric `Fixed` by identity,
`Wrapped{D8} ← Wrapped{Float64}` through a parameter feeding an `SVector`
field, `SVector{2,Pose{D8}} ← SVector{2,Pose{Float64}}` nested,
`@NamedTuple{a::D8, b::Int} ← @NamedTuple{a::Float64, b::Int}` true,
reordered `NamedTuple` fields false, `Tuple{D8,Int} ← Tuple{Float64,Int}`
true, and the three rows above false. Every verdict except those three rows
agrees with today's relation, so the suite's D-166 behaviour (the
constant-branch idiom, the `PinnedGetsDual` hint, the D-235 embedding at
`D8`) must not move. If a fixture leaned on the laxity the suite will say
so; report it rather than loosening the relation.

`_accepts_wire` (243–244), `_pin_hint` (229) and every caller are unchanged.
`_walking_leaf`'s premise (`src/build.jl:477–480`) gets stronger, not
weaker: with the exact relation the bound clause at `Float64` is `V_F === P_F`
for a concrete entry, so a walk failure at the marker can only be a `Marker`
in `V_M` where `P_M` has `Float64`; amend the comment to say so.

### Tests

In `test/test_leaves.jl`, `leaves_wire_relation` (193–235): after the
existing concrete-entry assertions, add a block "exact on the type (D-238)"
asserting `_accepts` directly on the three rows above (false), on
`@NamedTuple{a::D8, b::Int} ← @NamedTuple{a::Float64, b::Int}` at `D8`
(true), on a nested `SVector{2,Pose{D8}} ← SVector{2,Pose{Float64}}` (true),
and on reordered `NamedTuple` fields (false). The file's `Tagged{T}` (line 25)
is parametric on a numeric type, so define a symbol-tagged fixture of your
own (`Labeled{S}` with a `Float64` field) and a parametric `Pose{T}`-shaped
one under a name that does not collide with the non-parametric `Pose` at
line 11. Add `_accepts` to `test/imports.jl`.

In `test/test_build.jl`, `build_wire_clauses` (230–360), one more testset:
a producer declaring `(q = @NamedTuple{b::T},)` wired into an entry
`(q = @NamedTuple{a::T},)` is refused at `build` with `WireTypeMismatch`,
both endpoints named, `declared === @NamedTuple{a::Float64}`,
`observed === @NamedTuple{b::Float64}`. Verified at the tip: this model
builds and then throws a raw `FieldError` from the consumer's stage.

In `test/test_failures.jl`, `failures_conformance` (433 onward): a stage
returning an `MVector{2,Float64}` where `SVector{2,T}` was declared, on a
late branch (the file's fixture idiom, conformant at `t = 0`, divergent
after), fails `run!` with `StepError{ConformanceFailure}`,
`reason === :field_type`, `observed === MVector{2,Float64}`. Today it
converts silently at the write.

### Register edits, commit 1

- `docs/design/pending.md`: delete the bullet **"The concrete arm of the wire
  relation is looser than `<:`"** (179–188); restore the section intro
  (128–130) to "All but the last two were found by the audit, none of them
  chosen; the merge entry has the probe."
- `docs/design/implementation.md`, `src/leaves.jl` row (19): "embed-accept's
  relation `_accepts` (D-166)" → "embed-accept's relation `_accepts`
  (D-166, decided on the type per D-238)"; add `D-238` to the citations.
- Commit: "Decide embed-accept on the type by lifting and exact comparison
  (D-238)".

## Commit 2 — the narrow-bound arm of `TierSignatureMismatch`

### The problem

The mandated continuous form is `where {T <: Real}` (§8.5, 2555–2556).
`declared_at` (`src/declare.jl:255`) decides a component declares a contract
by `_declares(fn, c, Type{Float64})` (238–240), which is true for a method
bounded `where {T <: AbstractFloat}`. At the marker that method does not
apply, dispatch falls to the `::Any` fallback (56, 69), which returns an
empty `NamedTuple`, and `_check_wires` (`src/build.jl:425–475`) indexes it
by face: a raw `FieldError` at the nominal build. Verified at the tip with
an `output_types(::Narrow, ::Type{T}) where {T <: AbstractFloat}` producer
wired into a `T` entry. The same fallthrough happens at any `Dual`
activation; `_declares(fn, c, Type{Marker})` is `false` for it and `true`
for the mandated form (verified, including a multi-parameter
`where {W, T <: Real}`).

### The kind

In `src/diagnostics.jl`, directly after `DeclarationOnWrongTier` (453–470):

```julia
"§8.2, §8.5: a contract signature whose form is not the one its tier mandates — here the bound arm, a `T` narrower than `Real`."
Base.@kwdef struct TierSignatureMismatch <: Diagnostic
    path::String
    declaration::Symbol                      # :input_types | :output_types
    tier::Symbol                             # :continuous
    reason::Symbol                           # :bound — the arity arms ride as `DeclarationOnWrongTier`'s `:tier_form`
    found::Any                               # the bound the method puts on `T`
    mandated::Any = Real
end
path(d::TierSignatureMismatch) = d.path
message(d::TierSignatureMismatch) =
    "$(_at_path(d.path)): `$(d.declaration)` bounds its `T` by $(d.found), but a " *
    "continuous contract is a function of every activation scalar — declare it " *
    "`where {T <: Real}` (§8.5)"
```

The arity arms stay absent from this kind: `DeclarationOnWrongTier`'s
`:tier_form` already reports them, and the register records that overlap
(below). `found` is read off the method:

```julia
# The upper bound a two-argument contract puts on its `T`, read off the method
# matched at `Float64`. Throwing path only.
function _contract_bound(fn, c)
    body = Base.unwrap_unionall(which(fn, Tuple{typeof(c),Type{Float64}}).sig)
    tv = body.parameters[3].parameters[1]
    tv isa TypeVar ? tv.ub : tv
end
```

(verified: `AbstractFloat` for the narrow method, `Real` for the mandated
one and for `where {W, T <: Real}`). Put it in `src/build.jl` beside the
check.

### The check

In `_check_wires`, before the `at(…)` evaluations, a loop over continuous
components recording the refusal and marking the component, so the wire loop
and the root loop skip anything touching it (a refused component's marker
evaluation is the fallback's empty declaration, which must not be indexed):

```julia
    refused = falses(length(flat.comps))
    for (ci, (c, t)) in enumerate(zip(flat.comps, tiers))
        t === CONTINUOUS || continue
        for fn in (input_types, output_types)
            (_declares(fn, c, Type{Float64}) && !_declares(fn, c, Type{Marker})) || continue
            push!(diags, TierSignatureMismatch(path = flat.paths[ci], declaration = nameof(fn),
                                               tier = :continuous, reason = :bound,
                                               found = _contract_bound(fn, c)))
            refused[ci] = true
        end
    end
```

In the wire loop, `(refused[ci] || refused[pi]) && continue` right after
`pi` is computed; in the root loop, skip a consumer entry whose component is
refused. The `Float64` evaluations stay valid for a refused component, so
nothing else in Stratum A changes. Amend the pass's header comment
(420–424) to name the third thing it checks.

### Tests

In `test/test_build.jl`, `build_tier` (391–440): fixtures `NarrowOutput`
(`output_types(::_, ::Type{T}) where {T <: AbstractFloat} = (a = T,)`,
`output_state = (a = 1.0,)`) and `NarrowInput` (the same bound on
`input_types`, a mandated `output_types`, `output_direct` passing the input
through). Assert:

- `build(single(NarrowOutput()))` fails with one `TierSignatureMismatch`,
  `declaration === :output_types`, `reason === :bound`,
  `found === AbstractFloat`, `mandated === Real`, `path(d) == "c"`.
- `NarrowOutput` wired into `RealEntry`'s `u` (83–87) fails with that one
  diagnostic and nothing else: the wire it feeds is skipped, no
  `FieldError`. Verified at the tip: this model raises the raw `FieldError`.
- `NarrowInput` fed by `NomSource` (522–524): one diagnostic,
  `declaration === :input_types`.
- Both in one model report together, in one throw, beside a
  `WalkingFaceAtFrozenEntry` from an unrelated wire (`build_wire_clauses`'
  `FrozenEntry` idiom, 207–212): three kinds, one `DiagnosticError`.

Add one occurrence to the kinds list in `test/test_diagnostics.jl` next to
the `DeclarationOnWrongTier` ones (267–271), and `TierSignatureMismatch` to
`test/imports.jl`.

### Register edits, commit 2

- `docs/design/pending.md`:
  - In the absence clause (18–26), delete `TierSignatureMismatch` from the
    absent-checks list together with the parenthetical "(a contract bounded
    narrower than `Real` … at the nominal build)", so it reads "likewise
    `IllegalStateLeaf` and `MissingProbeValue`, whose *checks* are absent".
  - In the payload-column bullet, after "`DeclarationOnWrongTier` naming the
    two tiers rather than §8.5's two forms" (58–59), insert ",
    `TierSignatureMismatch` its bound arm alone, the arity arms riding as
    `DeclarationOnWrongTier`'s `:tier_form`".
- `docs/design/implementation.md`, `src/build.jl` row (25): in the wire-pass
  clause, after "the root-input type and its two refusals" insert ", the
  contract-bound check (`TierSignatureMismatch`'s bound arm)".
- Run `julia --project=@. docs/design/tools/check_refs.jl` and
  `julia --project=@. docs/design/tools/check_rows.jl`; both must pass.
- Commit: "Refuse a continuous contract bounded narrower than Real as
  TierSignatureMismatch in Stratum A's wire pass".

## Verification

- Full suite green after each commit; `Pkg.test()` green at the end.
- `rg -n "fieldtypes|fieldcount" src/leaves.jl` lists the leaf walk and
  `_leaf_values` only, never `_accepts`.
- `rg -n "FieldError" test/test_build.jl` is empty (the narrow-bound model
  is asserted through the diagnostic, not the raw error).
- `test/test_executor.jl` unchanged.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report all three totals.

## Report format

Under 300 words: the two commit hashes; the files each touched; any fixture
the exact relation refused and what you did about it; any test you could not
write as specified and why, with file:line; any place the spec and this
brief disagreed; the assertion totals; friction with this brief, especially
any line number that had drifted.
