# Increment 33 — opaque leaves and reference-carrying ports (D-237)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `234c5a2`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** D-237 is ratified and its spec touches are in (§4.3's leaf-walk
paragraph, Appendix C's `IllegalPortType` row). The code owes the spec the
classification, the store arms and the two refusals. **One stage, one
commit**, suite green, `Pkg.test()` green.

**Read, all in `docs/design/spec.md`:** §4.3's "What a port may hold"
(414–428, the leaf-walk paragraph at 421–426); §4.4 in full (474–548, the
handle pattern and the value-level constructor); Appendix C's
`IllegalPortType` row (10412); the glossary's field-handle entry
(10666–10669). In `docs/design/decisions.md`: D-237 in full (8537–8573),
whose Rejected list names the built shape you are replacing. §7.1 (1298–1312)
is the *state* vocabulary; handles never enter it.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–144).
- The file-table rows for `src/leaves.jl` (19), `src/diagnostics.jl` (20),
  `src/store.jl` (23), `src/build.jl` (25) and `test/fixtures.jl` (37).
- **"Authoring caveats" in full (60–108)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module (`_cell_key` exists for that reason: key stores with it, never with
  `Symbol(::Type)`).

In `docs/design/pending.md`, this increment retires M-B8, the
reference-carrying clause of the port-value-coverage bullet (91–98). M-B7
(enums) and M-B10 (containers of containers) stay.

**Stance: conservative reading.** Build what the sections below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root. While iterating, `julia --project=test test/runtests.jl leaves store
build diagnostics log trace` covers the files this change reaches; gate the
commit on the full suite and on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push. Never stash, reset or check
out the working tree; a baseline is read with `git show 234c5a2:path`.

---

## The problem

`leaf_types` (`src/leaves.jl:25–27`) descends `fieldtypes` into anything
that is not a `Real` or a `StaticArray`. For §4.4's handle pattern — an
immutable struct holding a reference to bulk data — it walks into the
`Matrix`'s own fields. Verified at the tip with
`struct HeightField; z::Matrix{Float64}; h0::Float64; end`:

| call | result |
|---|---|
| `leaf_types(HeightField)` | `[Int64, Int64, Int64, Float64]` |
| `build` of a producer/consumer pair wired on a `HeightField` port | builds |
| `Simulation(m; h = 1//10)` | constructs |
| `init!`, `run!` | `StepError{MethodError}` in the consumer's stage, from the gather's reconstruct |
| `HeightField` face surfacing as a root input | raw `MethodError` from `probe_value`, `HeightField()` |
| a `mutable struct` port | builds silently |

Also verified: `isbitstype(HeightField) === false`,
`ismutabletype(HeightField) === false`,
`Base.allocatedinline(HeightField) === true` (Julia stores an immutable
struct with reference fields inline in a `Vector`, so a cell of that type is
one load and one store); `zeros(HeightField, 2)` throws (`zero` undefined),
`Vector{HeightField}(undef, 2)` allocates with unassigned slots;
`retype(D8, HeightField) === HeightField` (no parameters, nothing to walk);
`_accepts(HeightField, HeightField, D8) === true` by identity.

## The classification

D-237: the walk descends through `Real`s, static arrays and isbits structs;
stops at a concrete immutable type that is not isbits and treats it as one
opaque leaf; refuses a mutable type wherever the walk meets one.

**The reading of "anywhere".** The mutability check applies at every
position the walk *visits*: the port type itself, a static array's eltype,
an isbits struct's fields (which cannot be mutable, so in practice the first
two). The walk never looks inside an opaque leaf, so a `Matrix` field of a
handle is what makes the handle a handle, not a refusal. By the same rule an
immutable struct holding a `Ref` is opaque and accepted; §4.4's "never
`Ref`s" is authoring guidance the walk does not police. Build this reading.

In `src/leaves.jl`, one predicate above `nleaves`, and the arm in every
walker:

```julia
# D-237's opaque leaf: a concrete immutable type that is not isbits — a
# handle, a `String`, a `Symbol` — stored whole. Abstract types are not
# leaves and fall through to the struct walk as before.
_opaque(::Type{P}) where {P} = isconcretetype(P) && !isbitstype(P) && !ismutabletype(P)
```

- `nleaves` (14–16): `_opaque(P)` → `1`, before the struct fallback.
- `leaf_types` (25–27): `_opaque(P)` → `Type[P]`, before the struct
  fallback.
- `_leaf_names!` (47–63): `_opaque(P)` → `push!(out, pre)`, the leaf's own
  dotted name.
- `_reconstruct_expr` (69–91) and `_flatten_expr` (95–115): the `Real` arm
  becomes the leaf arm, `P <: Real || _opaque(P)`, one whole-value read or
  write at `off + base + 1`.
- `_mreconstruct_expr` (125–138) and `_mflatten_expr` (140–156): the same,
  `k = findfirst(==(P), Ls)` finds the handle's own buffer.
- `_leaf_values` (199–204): an arm `_leaf_values(v) = isbits(v) ? <today's
  field walk> : (v,)`. Nothing on the tree reaches it with a handle (`_embed`
  short-circuits on `typeof(v) === P`, which always holds for a handle since
  its declaration has no `T`; `retype_value` and `establish_defaults!` walk
  state, which §7.1 closes to scalars and static arrays), but the walkers
  must agree with each other.

Write `_opaque` so that every arm tests it *after* the `Real` and
`StaticArray` arms and *before* the struct fallback; `BigFloat` is a
non-isbits `Real` and stays a `Real` leaf. Amend the file's header comment
(1–6) and `leaf_types`' docstring (18–24) to name the third leaf kind.

**The mutable refusal.** A walker beside `leaf_names`, same shape:

```julia
"""
    mutable_position(P)

The dotted name and type of the first mutable type the leaf walk over `P`
meets, or `nothing`. Layout-time only — `place!`'s refusal (D-237).
"""
```

walking `Real` (none), `StaticArray` (the eltype), opaque (none), struct
(the fields), and returning `(name, T)` at the first `ismutabletype`. The
port type itself is position `""`.

## The store

- `compile` (`src/build.jl:1013–1014`): `CellStore(zeros(L, n))` becomes
  `CellStore(L <: Real ? zeros(L, n) : Vector{L}(undef, n))`. Every handle
  cell is written by the probe-product seed (1039–1043) before any gather —
  a handle at root is refused below, so no cell is left to the root-input
  seed — and `capture` (`src/dataplane.jl:577`) copies buffers with `copy`,
  which tolerates unassigned slots. State that invariant in the comment at
  1036–1038.
- `_cell_key` (`src/store.jl:40`) already keys by the module-independent
  printed form; a handle type gets one homogeneous `CellStore{H}` beside the
  numeric ones. Nothing else in `store.jl` changes: `gather`/`scatter!` are
  the generated builders above.

## The two refusals

`IllegalPortType` (`src/diagnostics.jl:627–637`) gains a reason and, for the
mutable arm, the position:

```julia
"§4.3, §7.1, §8.2, D-215, D-237: a port type the leaf walk cannot lay out — no leaves, a mutable type on the walk, or a handle at a root input."
Base.@kwdef struct IllegalPortType <: Diagnostic
    path::String
    site::Symbol                             # :port | :root_input
    name::Symbol
    declared::Any                            # the offending type
    reason::Symbol = :no_leaves              # :no_leaves | :mutable | :handle_at_root
    position::Any = nothing                  # :mutable — the dotted position of the mutable type, "" for the port itself
end
```

`message` per reason: `:no_leaves` as today; `:mutable` — "`name` declares
`declared`, which is mutable at `position`" (or "which is mutable" when the
position is `""`) "— a port value is immutable, bulk data rides behind an
immutable handle (§4.4)"; `:handle_at_root` — "root input `name` declares
`declared`, a field handle, which has no producer here — wire a
field-emitting component, or a stub child in a rig (§4.4, D-237)". The
default `reason` keeps the existing constructor call in
`test/test_diagnostics.jl:298` valid.

In `cell_layout` (`src/build.jl:260–297`):

- `place!` (268–280): before `leaf_types`, `mp = mutable_position(P)`;
  `mp !== nothing` → push `IllegalPortType(…, reason = :mutable,
  position = first(mp))`, return `false`. The no-leaves arm follows,
  unchanged.
- The root loop (286–290): after `_root_input_cell`, and before `place!`,
  `any(!(<: Real), leaf_types(P))` → push `IllegalPortType(path = "", site =
  :root_input, name = face, declared = P, reason = :handle_at_root)` and
  `continue`, so `probe_value` is never reached. A mutable root type is
  caught by `place!`'s arm on the next line as today's order has it; do not
  special-case it. Note `leaf_types` on a mutable `P` still walks its
  fields, as today, and that is harmless since `place!` refuses first.

Amend the placement comment (264–266) to name the two new refusals; the
barrier at 291 already collects them.

## Where nothing changes, and why

- The wire relation: `_accepts` (`src/leaves.jl:215–230`) compares a handle
  by identity; `_accepts_wire`'s abstract arm admits it at an abstract entry
  by `V <: P` (D-237's Rationale). No arm.
- The always-on check (`scatter_group!`, `_check_ports`, `flatten_state!`):
  decided on the type through `_accepts`; a handle passes by identity.
- The activation walk: `retype` (186–191) rewrites `Float64` *parameters*
  only. A **parametric** handle with a `Float64` inside its parameter list,
  `Grid{Matrix{Float64}}`, retypes to `Grid{Matrix{D8}}` (verified at the
  tip). `retype` reaches port types only through `_accepts_wire`'s abstract
  arm and `_root_input_cell`; the second is closed by the root refusal, the
  first would refuse a `Grid{Matrix{Float64}}` producer at an abstract
  entry only if `V <: P` also failed, which it does not for a subtype. Probe
  this once in the scratchpad, report the verdict, and leave the code alone
  unless it wires wrongly.
- The trace and the log: the trace header records root inputs (`src/trace.jl:283`)
  and the drain records writer values, both closed to handles by the root
  refusal; the log's snapshots copy the store buffers whole (`capture`), so
  a handle cell is one struct copy sharing the bulk reference. §4.4's
  "loggers skip or summarize" needs no code here — assert that a handle
  model logs and traces without error (below) and say so in the report.
- The conditions' `_seeded_into_pinned` (`src/conditions.jl:469–470`) calls
  `leaf_types` on a value type and an entry type; with the arm it sees the
  handle as one leaf and reports nothing new.

## Tests

**Fixtures** in `test/fixtures.jl` (used by three files): `HeightField`
(`z::Matrix{Float64}`, `h0::Float64`), a plain constructor call per §4.4;
`Terrain` (`output_types = (terrain = HeightField,)`, `output_direct` a
one-line call to a top-level `height_field(h0)` that builds a `2×2`
`Matrix`); `Query` (`input_types = (terrain = HeightField,)`,
`output_types = (h = T,)`, `output_direct` returning `u.terrain.h0 +
size(u.terrain.z, 1)`); `AbstractTerrainQuery` with the entry
`AbstractTerrain` over `abstract type AbstractTerrain end` and
`HeightField <: AbstractTerrain`; `MutableSource` with a `mutable struct`
port; `handle_model()` = `Group((; src = Terrain(), q = Query()); wires =
("src/terrain" => "q/terrain",))`. The bundle law: inputs arrive under `u`,
so a consumer's stage destructures `(; u)` and reads `u.terrain`.

`test/test_leaves.jl`, in `leaves_shape` (90): `nleaves(HeightField) == 1`,
`leaf_types(HeightField) == [HeightField]`, `leaf_names(HeightField) ==
[""]`, and for a struct `Framed` with fields `f::HeightField, s::Float64`:
`leaf_types == [HeightField, Float64]`, `leaf_names == ["f", "s"]`;
`mutable_position(Matrix{Float64}) == ("", Matrix{Float64})`,
`mutable_position(SVector{2,Matrix{Float64}}) == ("[1]", Matrix{Float64})`,
`mutable_position(HeightField) === nothing`, `mutable_position(Float64)
=== nothing`. In `leaves_roundtrip` (126): the file's `roundtrip` helper on
a `Framed` value, asserting the handle comes back `===` (the same `Matrix`).

`test/test_store.jl`, one new function `store_opaque_leaf` registered where
the others are:

- `Simulation(handle_model(); h = 1//10)`: `keys(sim.exec.store.stores)`
  is the set `{_cell_key(Float64), _cell_key(HeightField)}`; after `init!`,
  `port(sim, "src", :terrain) isa HeightField` and `port(sim, "q", :h) ==
  3.0`; `port(sim, "src", :terrain).z === port(sim, "src", :terrain).z`
  across two reads (the cell hands out the one reference).
- The same at `D8`: the handle cell's store is still keyed
  `_cell_key(HeightField)`, `port(sim, "q", :h) isa D8`.
- Allocation: on the nominal sim after `init!`, every body of
  `phase_bodies(sim)` satisfies `@ballocated($body()) == 0` and
  `@ballocated($body(1)) == 0`, the `test_executor.jl:14–19` idiom.
- The log and the trace: `run!(sim; t_end = 0.5)` succeeds;
  `port(latest(sim), "src", :terrain) isa HeightField`; `trace(sim)` builds
  and `replay!` into a fresh `Simulation(handle_model(); h = 1//10)` runs
  (`test/test_trace.jl:396` has the idiom).
- The abstract entry: `Terrain` wired into `AbstractTerrainQuery` builds
  and `port(sim, "q", :h) == 3.0`.

`test/test_build.jl`, one new testset in `build_wire_clauses` or a new
function beside it:

- `build(Group((; c = MutableSource())))` fails with one `IllegalPortType`,
  `reason === :mutable`, `position == ""`, `declared` the mutable type,
  `site === :port`.
- A `Query` face surfacing as a root input, `Group((; q = Query()); inputs =
  ("terrain" => "q/terrain",))`, fails with one `IllegalPortType`,
  `site === :root_input`, `reason === :handle_at_root`, `path(d) == ""`,
  and the error is a `DiagnosticError`, not the raw `MethodError`.
- Both in one model report together, two diagnostics, one throw.

`test/test_diagnostics.jl`: two more occurrences in the kinds list beside
298, one per new reason, so every message renders. Add `mutable_position`
to `test/imports.jl`; `latest`, `port`, `phase_bodies`, `trace`, `replay!`
are already on it.

## Register edits

- `docs/design/pending.md` (91–98): the bullet becomes "**Port-value
  coverage** (M-B7, M-B10): enum-valued ports are refused — … §7.5's
  publish-a-mode remedy; containers of containers take …". Delete the
  reference-carrying clause whole.
- `docs/design/implementation.md`:
  - `src/leaves.jl` row (19): after "the leaf walk" insert " (with D-237's
    opaque leaf and `mutable_position`)"; add `§4.3`, `§4.4`, `D-237` to the
    citations.
  - `src/build.jl` row (25): in the layout clause, "the layout with the
    root-input meet (D-168, D-236)" → "the layout with the root-input meet
    (D-168, D-236) and `IllegalPortType`'s three arms (D-237)"; add `D-237`.
  - `src/store.jl` row (23): "per-eltype cell stores" → "per-eltype cell
    stores (a handle type is its own eltype, D-237)"; add `D-237`.
  - `src/diagnostics.jl` row (20): no change unless a new kind appears.
- Run `julia --project=@. docs/design/tools/check_refs.jl` and
  `julia --project=@. docs/design/tools/check_rows.jl`; both must pass.
- Commit: "Classify a non-isbits immutable port type as one opaque leaf and
  refuse mutable ports and handles at root (D-237)".

## Verification

- Full suite green; `Pkg.test()` green.
- `rg -n "zeros\(L" src/build.jl` is empty.
- `rg -n "_opaque" src/leaves.jl` lists the predicate and seven arms
  (`nleaves`, `leaf_types`, `_leaf_names!`, the four expression builders)
  plus `_leaf_values`' `isbits` test; report the count.
- `test/test_executor.jl` unchanged.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; the `retype` probe's
verdict on the parametric handle; any test you could not write as specified
and why, with file:line; any place the spec and this brief disagreed; the
assertion totals; friction with this brief, especially any line number that
had drifted.
