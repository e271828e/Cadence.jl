# Notes toward the briefs for increments 32 and 33

Working notes from the 2026-09-08 design session that ratified D-235–D-237,
kept so the two later briefs can be written from a fresh context. The
rulings themselves live in `decisions.md` (D-236, D-237) and the spec
(§4.3, §6.1, §8.2, §9.1, §9.5, Appendix C); this file carries what the
rulings do not: the code sites, the shapes the session settled, the claims
already verified, the tests sketched, and the register bookkeeping. Line
numbers are at `7c00fd2`; increment 31 touches `build.jl`, `leaves.jl`,
`store.jl` and `executor.jl`, so re-anchor every number before it goes into
a brief.

The three increments and their dependencies: 31 (the always-on check,
`brief_increment_31_always_on_check.md`) depends on nothing. 32 (the wire
relation) depends on nothing in 31 but should follow it, since both rewrite
callers of `_accepts`. 33 (opaque leaves) needs 32 only for its
abstract-entry test; its concrete-entry path stands alone.

## Increment 32 — the wire relation, the root meet, the Stratum A pass

**Ruling.** D-236. Spec touches already landed: §6.1's abstract-entry
sentence, §8.2's two-candidate sentence. §9.1 (2952–2967) already places
both clauses in Stratum A at a marker scalar. Appendix C rows:
`WireTypeMismatch` (10380), `WalkingFaceAtFrozenEntry` (10381),
`AbstractAtRoot` (10383), `RootInputTypeConflict` (10384).

**What the code does today.**

- The only wire check is `_probe_input` (`src/build.jl:1063–1082`), in
  Stratum C, on the probed value's type, throwing a single
  `WireTypeMismatch` fail-fast. `_accepts` (moved to `leaves.jl` by
  increment 31) requires nominal identity on struct types
  (`P.name === V.name`) and so refuses any abstract entry.
- `_root_input_type` (`src/build.jl:336–352`) takes the first consumer's
  entry evaluated at the current activation. At nominal it compares every
  consumer's evaluated entry for `!==` identity, so an abstract co-consumer
  would report `RootInputTypeConflict`. It is called from `cell_layout`
  (`312`) with `check = T === Float64`. No `AbstractAtRoot`: a `Real` entry
  reaches `probe_value` (`src/declare.jl:327–330`) and is refused blaming a
  synthesized `Int64`; an abstract struct throws from `leaf_types`
  (`src/leaves.jl:25–27`) before any diagnostic.
- No marker pass exists. `declarations(c, t, T)` (`src/build.jl:34–39`)
  also retypes `init_x` by value, so it cannot be called at a marker
  scalar; a marker pass calls `input_types(c, M)` and `output_types(c, M)`
  directly on continuous leaves and the plain forms on discrete ones.
- `WalkingFaceAtFrozenEntry` and `AbstractAtRoot` have no struct
  (`pending.md:21`).

**The relation, as settled.** `V` (producer's declaration at the
activation) is accepted at `P` (entry at the activation) when some leafwise
embedding of `V`, lifting any subset of its `Float64` leaves to `T`, is
`<:` `P`. Implementation:

- Concrete `P`: the existing per-leaf `_accepts` walk, unchanged.
- Abstract `P`: `V <: P || retype(T, V) <: P`. `retype` (`src/leaves.jl:~178`)
  replaces every `Float64` parameter by `T`. Exact whenever `P`'s parameters
  are uniformly `T` or uniformly pinned; the mixed abstract case is a
  recorded limit (D-236 Rationale), admitted by the definition and refused
  by the check.
- At nominal every lift is the identity and the whole thing is `V <: P`.
- Worked cases at `Dual`: entry `AbstractVector{T}` → `AbstractVector{Dual}`
  accepts `SVector{3,Dual}` (first test) and pinned `SVector{3,Float64}`
  (second test); entry `SVector{3,Float64}` refuses `SVector{3,Dual}` (both
  fail) and accepts `SVector{3,Float64}`; entry `Real` accepts `Dual`.

**The root side, as settled.** Slot-level meet with two candidates,
computed per activation where `cell_layout` places the root input:

```julia
# P_F: the unique concrete entry at Float64 among the consumers
walk = retype(T, P_F)                                   # every leaf follows T
cell = all(e -> _accepts_wire(e, walk, T), entries) ? walk : P_F
```

`entries` are every consumer's entry evaluated at `T`. A pinned candidate
is accepted by every entry by construction. `AbstractAtRoot` is
`!isconcretetype(P_F)` for every consumer, i.e. no concrete entry exists;
collected under the layout's barrier (`cell_layout`'s `diags`), payload per
Appendix C (face, consuming leaf path, the abstract entry, remedy hint).
`RootInputTypeConflict` becomes "the concrete entries at `Float64`
disagree"; abstract co-consumers do not vote in the conflict and are
checked against `P_F` by the bound clause. The seedability consequence
(a `B`-matrix tap on a pinned slot rejected naming the pinning consumer)
belongs to `linearize`, absent; stays in the register.

**The Stratum A pass, as settled.** A sentinel `struct Marker <: Real end`
(name open; it never enters arithmetic). For every wire `producer face →
consumer entry`: evaluate both contract declarations at `Float64` for the
bound clause and at `Marker` for the walk clause; a leaf typed `Marker` is
a walking leaf, anything else is pinned. Continuous consumers take both
clauses, discrete consumers the bound clause only (D-167's tier scope,
§6.1 1113–1119). Collected under Stratum A's barrier in `build`
(`src/build.jl:395–412`): the pass runs after `wire!` (which needs the
barrier clean) and before `_stratum_c`, so it needs its own barrier throw
between them, or `wire!` moves under a widened one; read D-229 before
choosing. Diagnostics: `WireTypeMismatch` (existing struct, 289–297) for the
bound clause; a new `WalkingFaceAtFrozenEntry` with the Appendix C payload
(consumer path and entry, producer path and face, the offending leaf, both
declared leaf types, both remedies in the message). Once the pass exists,
`_probe_input`'s check is redundant; drop it to an `InternalInvariant` or
delete it, and say which in the report.

The payoff to assert: an input-side forgotten `T` (a `Float64` entry fed by
a producer declaring `T`) fails at the first *nominal* `build`, at the wire,
with both endpoints named. Today it fails only when a `Dual` activation is
first built (M-B3's neighbour; check `test_build.jl`'s `PinnedGetsDual`
family at 241–318 for the output-side precedent and for how `D8`
activations are asserted).

**Tests sketched.**

- An abstract struct entry: `abstract type AbstractField end`, two concrete
  producers `FieldA <: AbstractField`, `FieldB <: AbstractField` (isbits, no
  references — handles are increment 33), a consumer with
  `input_types = (f = AbstractField,)`; both wire and build; the consumer's
  bundle field has the producer's concrete type.
- A `Real` entry fed by a `T` producer: builds at nominal and at `D8`.
- `AbstractVector{T}` entry fed by `SVector{3,T}` and by a pinned
  `SVector{3,Float64}`: both build at `D8`.
- Abstract at root: `input_types = (f = AbstractField,)` with `f` surfacing
  as a root input → `AbstractAtRoot` at `build`, collected (two such faces
  report together).
- The meet: one root input fanned into a `T` entry and a `Float64` entry;
  at `D8` the slot cell is `Float64` and the `T` consumer still builds
  (today: order-dependent, M-B2). Assert the cell type through
  `port`/`trace` header, and that swapping the two consumers' declaration
  order changes nothing.
- Forgotten `T` at the wire: fails at nominal `build` with
  `WalkingFaceAtFrozenEntry` naming both endpoints; the message carries
  both remedies.
- Abstract co-consumer under fan-out is not a conflict; two different
  concrete entries still are.

**Register bookkeeping.** Retires `pending.md`'s M-B2 (136–140) and M-B3
(141–147) deviation bullets; removes `AbstractAtRoot` and
`WalkingFaceAtFrozenEntry` from the absent-checks list (21); the
"abstract struct entry throws a raw `ArgumentError`" clause goes with M-B3.
`implementation.md` rows: `build.jl` (Stratum A gains the wire pass),
`leaves.jl` (`_accepts_wire` beside `_accepts`), `diagnostics.jl` (the new
kind), `declare.jl` if the marker lives there. `test/imports.jl` gains the
new kind.

## Increment 33 — opaque leaves and reference-carrying ports

**Ruling.** D-237. Spec touches landed: §4.3's leaf-walk paragraph,
Appendix C's `IllegalPortType` row (10402). §4.4 (483–542) is the
description the classification reads off the type.

**What the code does today.** `leaf_types` (`src/leaves.jl:25–27`) descends
`fieldtypes` into anything that is not `Real` or `StaticArray`, so a
`Matrix` field is walked into its internals; `place!` (`src/build.jl:293–300`)
accepts the result, the build succeeds, and the first gather dies in a raw
`MethodError` (M-B8, `pending.md:91–100`). `place!` refuses only a type
with *no* leaves (`IllegalPortType`, struct at `src/diagnostics.jl:583–591`,
`site` is `:port | :root_input`). Enum ports fall in the same trap the other
way (`leaf_types` empty → refused, M-B7); adjacent, not in scope, but the
classification arm is the natural place to note it.

**The classification, as settled.** In the leaf walk: `Real` and
`StaticArray` as today; an isbits struct is walked; an immutable type that
is not isbits is one opaque leaf; a mutable type is refused
(`IllegalPortType`, new reason). Concretely, `leaf_types(P)` gets an arm
before the struct fallback: `ismutabletype(P)` → signal refusal (the walk
returns a marker or `place!` checks first); `!isbitstype(P)` → `Type[P]`.
`nleaves` mirrors it (`= 1`). `leaf_eltypes` then lists the handle type
itself, so the store bundle gets one `CellStore{H}` per handle type via the
existing `_cell_key`; `compile`'s `zeros(L, n)` (`src/build.jl:933`) must
become an `undef` allocation for a non-numeric `L`, and every handle cell is
seeded by its producer's probe product (`960`) before any read, since a
handle at root is refused. `_mreconstruct_expr`/`_mflatten_expr`
(`src/leaves.jl:126–156`) and `_reconstruct_expr`/`_flatten_expr` (84–118)
each need the opaque arm: one `buf[k][off + i]` read or write of the whole
value. `_leaf_values` (194–199) needs an arm returning the value whole, or
`_embed` must short-circuit before it; `_embed` already returns `v` when
`typeof(v) === P`, which is always the case for a handle (no `T` in its
declaration, so declaration at any activation is the same type).

**Where handles must not go.** `retype`/`retype_value` apply to `init_x`
only, and §7.1's closed vocabulary excludes handles from state, so the
state walk never meets one. The store isbits check (D-231, `build.jl`)
governs discrete stores, not cells. `leaf_names` (`src/leaves.jl:~40–60`)
is called by the nonfinite sweep on state only.

**The edges.**

- A handle-typed face surfacing as a root input: refused in `cell_layout`'s
  root loop (`311–314`) with `IllegalPortType(site = :root_input)` and a
  reason that renders the remedy (wire a producer, or a stub child in a
  rig). `probe_value` never sees it.
- A mutable type anywhere in a port value: `IllegalPortType` with a reason
  naming the field; `place!` is the site, at both `:port` and `:root_input`.
- The trace and the log: §4.4 says loggers skip or summarize a handle.
  Find the sites by `rg -n "leaf_types\(|nleaves\(" src/readers.jl
  src/dataplane.jl src/trace.jl` at the tip of the day (at `7c00fd2` none of
  the three walks leaves directly; `capture`/the `Reader` gather cells by
  address, so a handle cell simply gathers as a value — check what the log
  and the trace header do with a non-numeric cell before deciding whether
  "skip" needs code).
- Julia stores an immutable struct with reference fields inline in a
  `Vector` of that type, so gather/scatter are one load and one store with
  no allocation; assert with `@ballocated` on a body that runs a
  handle-producing stage (the `test_executor.jl` canary pattern).

**Tests sketched.**

- `struct HeightField; z::Matrix{Float64}; h0::Float64; end` produced by
  a leaf (`output_types = (terrain = HeightField,)`, a one-line stage
  calling a plain constructor per §4.4's value-level constructor rule) and
  consumed by a leaf with a *concrete* entry `terrain = HeightField`; the
  consumer queries `z` in its stage. Builds, runs, allocation-free sweep,
  the value round-trips through the cell by identity (`===` on the
  `Matrix`). Runs at `D8` too, the cell type unchanged.
- The same with an abstract entry `AbstractTerrain` — needs increment 32.
- `mutable struct` port → `IllegalPortType` at `build`, naming the port and
  the field; a `Ref` field likewise.
- A `HeightField` face surfacing as a root input → `IllegalPortType` with
  `site === :root_input`.
- Trace/log: a run with a handle port produces a trace and a log without
  error; whatever the skip/summarize decision is, assert it.

**Register bookkeeping.** Retires M-B8 (`pending.md:94–98`, the
reference-carrying clause of the port-value-coverage bullet; M-B7 enums and
M-B10 containers-of-containers stay). `implementation.md` rows:
`leaves.jl`, `store.jl`, `build.jl`; `diagnostics.jl` if `IllegalPortType`
gains a reason field. `test/fixtures.jl` gains the handle fixture if more
than one file uses it.

## Claims verified this session, reusable

On Julia 1.12.7 at `7c00fd2` (scripts in the session scratchpad, not
kept):

- A `@generated` function over a `NamedTuple{Ns}` of `CellAddr{P,K}` and a
  `NamedTuple{Ys}` return decides key sets and per-field `_accepts` at
  generation, emits straight stores on the conformant path with zero
  allocation, embeds `Float64 → Dual` through the leaf store, pairs fields
  by name, and generates a throw for an `Int` field or an extra field.
- A `Simulation` at `D8` runs `run!` across a branch flip
  (`x.a > 0.5 ? 2.0 * x.a : 0.0` with `a` decaying) and the cell holds a
  zero-partial `D8` afterwards.
- `getfield((a = 1,), :b)` throws `FieldError`; `Ref` assignment converts a
  `NamedTuple` field (`(n = 1,)` stored into a `Ref((n = 1.0,))` reads
  `(n = 1.0,)`).
- `flatten!` is positional (`_flatten_expr` uses `getfield(v, i)`), so a
  reordered derivative return scrambles the buffer at the tip.
