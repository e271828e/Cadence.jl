# Brief: increment 57, the leaf address (§14.4, D-276)

Tip at launch: `b9720ce`. Three stages, then one cold review and one
fixer. Retires `pending.md`'s two "leaf address" bullets under "Not yet
built" (lines 27–36): the selector surface (the audit's finding A 4.3) and
the binding register.

Design and code are peers, neither subservient. The ruling has landed
docs-first (`6110a27`, `39fc253`, `b9720ce`: §4.2, §4.3, §14.4, §14.7,
§14.10, Appendix B, Appendix C, the glossary, D-276, D-271 superseded, a
D-272 annotation). The three stages conform the code and the suite. If the
ruled shape proves wrong at the keyboard, stop and report rather than
deviate silently.

Increment 56 (mounting, `brief_increment_56_mounting.md`) touches
`readers.jl` and `TapResolution` too. This brief is written against
`b9720ce` with no mounting code in the tree. If mounting lands first, every
stage re-reads `readers.jl`, `linearize.jl` and `diagnostics.jl` at the
then-tip and finds each passage by wording; the shapes below are unchanged
by mounting, which rewrites a selector's *path*, never its leaf.

## The ruling, in one paragraph

The second argument of every read selector is a leaf address: the field or
face name followed by `.name` and `[k]` or `[k,l]` steps in any order,
`get_output("kin", "pose.q_eb[2]")`, `get_state("dyn", "ω_eb_b[1]")`,
`get_input("wind[1]")`. A bare `Symbol` is the short form of a plain name.
The trailing integer index retires on all five members. Each step is
checked at resolution against the type resolved so far: a `.name` step
needs an isbits struct with that field, an index step needs an `SArray`
with one index or one per dimension, and no step enters an opaque leaf. The
address is a field of the selector value; the baked read carries the
resolved step chain as a type parameter and runs it as `getfield` and
`getindex` calls unrolled at compile time. A binding read admits the
address like every inspection reader, and the binding register's gather
becomes the family's baked read, its index refusal gone. Diagnostics spell a
matrix leaf `m[i,j]`. A tap's address resolves to one scalar; on the seeded
lists (`x`, `u`) it reaches that scalar through index steps alone, since a
seed writes a whole cell or one `SArray` component and the framework has no
lens into struct slots (D-036).

## What the spec says

Read these by line range at `b9720ce`. Line numbers are that tip's; find
each passage by wording.

- §14.4, `spec.md` 9402–9541: the family and the leaf-address rule
  (9440–9471), the source rule and the client table (9472–9541).
- §4.3, 527–560: "What a port may hold" (a port value's leaves, the opaque
  leaf, 527–546) and "Granularity, read side" (548–560).
- §7.1, 1497–1530: the state is flat; a field is one scalar or `SArray`.
- §14.10, 10264–10300: the tap rule and its example (10276–10292).
- §14.7, 9759–9776: the read side's spelling.
- Appendix C, 11346–11351 (`ReadBindingUnresolved`) and 11367–11371
  (`TapResolution`): the payloads as now described.
- Appendix D: `selector` (12237), `leaf address` (12244), `taps` (12430).
- `decisions.md`: D-276 in full (11134–11223), D-271 (10822, superseded),
  D-272's 2026-09-30 annotation (10926–10930), D-036 (1069), D-094 (2655).
- `implementation.md`: `leaves.jl` (21–42), `diagnostics.jl` (43–112),
  `readers.jl` (280–294), `bindings.jl` (598–608), `linearize.jl`
  (710–729); the authoring caveats (804–868) in full; "Naming" (869) and
  "Running the suite" (947), cited below and never restated.

## What exists

At `b9720ce`, by wording:

- `src/readers.jl`. The five selector structs carry `path`, `field` or
  `name` or `face` as a `Symbol`, and `i::Union{Nothing,Int}` (52–83).
  The constructors accept `Union{Symbol,AbstractString}` and an optional
  index through `_index_arg`, which throws `ArgumentInvalid(:index_not_integer)`
  (87–99). `_spell` prints the selector as authored with `_ipart` for the
  index (101–111). The four entry types `StateRead{P,I}`, `DerivRead{P,I}`,
  `StoreRead{S,F,I}`, `CellRead{A,I}` hold the index as a field of type
  `I`, and `_take(value, i)` applies it inside `_read` (152–186). The
  resolvers `_resolve_selector` (five methods, 318–398) call
  `_check_index`, which refuses an index on a `Real` with `:scalar_index`
  and checks nothing else (298–303). `_reader_violation` builds a
  `TapResolution` with `index = _selindex(selector)` (281–292). `_field`
  (315–316) and `_selpath` serve the payloads.
- `src/bindings.jl`. `ReadGather{L,A}` holds bare `CellAddr`s, and
  `gather_snapshot` reads each whole cell from `snapshot.store` (124–130).
  `_compile_gather(layout, selectors, binding_type, device)` maps
  `_resolve_read` over the selectors (141–154). The three table-member
  methods of `_resolve_read` refuse `selector.i !== nothing` with
  `ReadBindingUnresolved(reason = :indexed)` before their name checks
  (174–219). The comment at 103–115 says a binding read is a whole cell
  and cites `pending.md`. `sim.jl` 2002–2004 calls `_compile_gather`;
  `devices.jl` 63 types the handle's `gatherer` as `Union{Nothing,ReadGather}`
  and 202 calls `gather_snapshot`.
- `src/linearize.jl`. `_site_key(::Val{:u}, entry::CellRead)` is
  `(entry.addr, entry.i)` (262). `_check_seedable` refuses a non-`Real`
  without an index as `:vector_tap` and admits `Float64` whole or an
  `SVector{n,Float64}` component (268–276). The `x` tap's seed site is
  `entry.offset + something(entry.i, 1)` (290). The `y` tap refuses a
  non-`Real` without an index (325–333). `_seed_site!` writes the whole cell
  for `CellRead{A,Nothing}` and `Base.setindex(gather_cell(…), seed, site.i)`
  for `CellRead{A,Int}` (344–349).
- `src/leaves.jl`. `leaf_names` and `_leaf_names!` (62–91): a
  `StaticArray` prints `[i]` over `1:length(P)`, linear. Callers: the
  nonfinite sweep (`sim.jl` 633) and the walk-clause refusal (`build.jl`
  902). `_opaque(P)` (18) is the opaque-leaf predicate the walk uses.
- `src/diagnostics.jl`. `TapResolution` (1636–1653): reasons
  `:assembly_path`, `:scalar_index`, `:undeclared`, `:discrete_deriv`,
  `:unknown_root_input`, `:root_input_not_face`, `:unknown_output_face`,
  and the tap set's; fields include `index::Union{Nothing,Int}`.
  `_tap_violation` prints "(tap `x`, index 2)" (1666–1670); the arms run
  1672–1712. `ReadBindingUnresolved` (1480–1490): reasons `:store_selector`,
  `:indexed`, `:unknown_cell`, `:unknown_root_input`, `:root_input_not_output`,
  `:unknown_output_face`; arms 1491–1518. `ArgumentInvalid`'s
  `:index_not_integer` arm (1939–1941).
- Tests. `test_readers.jl`: the fixture read sets spell the index
  (24–26); the collecting testset asserts `:scalar_index` with `index == 1`
  (96–108); the source-rule testset asserts `:indexed` on three attaches
  (158–164). `test_linearize.jl`: indexed taps (198–200, 275, 301), the
  `:vector_tap` and `:scalar_index` assertions (241–257). `test_trim.jl`
  258 asserts a spelled selector, `get_state(\"nope\", :q)`.
  `test_diagnostics.jl`'s rendering testset builds `ReadBindingUnresolved`
  and `TapResolution` values with the old spellings and `:indexed`,
  `:scalar_index` (453–489). `test_leaves.jl` 178–181 pins `leaf_names(Body)`
  with `m[1]`…`m[4]` for an `SMatrix{2,2}`.
- The companion `linearization_walkthrough.md` and the spec's examples
  already spell the new form.

## Scope

In:

- The leaf address on all five selectors: the value, the constructors, the
  parse, the per-step resolution, the baked step chain, `_spell`.
- The retirement of `i` and of `ArgumentInvalid(:index_not_integer)`.
- The binding register on the family's baked read; the `:indexed` refusal
  gone; `devices.jl`'s field type.
- `linearize`'s tap resolution and seeding over the chain; the index-only
  rule on the seeded lists.
- `leaf_names`'s matrix spelling.
- `TapResolution` and `ReadBindingUnresolved`: the leaf reasons and
  payloads, their messages, the rendering tests.
- `implementation.md`'s rows for the five files and the "Naming" clause
  that lists "the selectors' `i`" as out of reach; `pending.md`'s two
  bullets.

Out:

- Mounting (increment 56) and everything `at(prefix, …)` does to a path.
- The unbundling component (a §13.7 library candidate, D-276).
- Nested `NamedTuple`s in the state (D-276's rejected list).
- A lens into struct slots on the write side: a `.name` step on a seeded
  tap is refused, not built (D-036).
- The GUI, inspector and audit folders, untracked.

## Shapes

### The selector value

```julia
struct GetState
    path::String
    leaf::Union{Symbol,String}     # as authored: `:θ` or "q[2]"
end
# GetDeriv, GetOutput alike; GetInput and GetFace carry `leaf` alone.

get_state(path::AbstractString, leaf::Union{Symbol,AbstractString}) =
    GetState(String(path), leaf isa Symbol ? leaf : String(leaf))
```

The two-argument and one-argument forms are the whole surface. No method
takes a third positional argument: a call with one is a `MethodError`, and
`_index_arg` and `ArgumentInvalid(:index_not_integer)` go, with the arm's
rendering test. `_spell` prints the leaf as authored: `:θ` for a `Symbol`,
`"q[2]"` in quotes for a string. `_field(selector)` returns the parsed
leaf's head name (below), which is what the payloads' `field` carries.

### The parse

At resolution, in the collecting form, never at construction. One
function, in `readers.jl` above the resolvers:

```julia
# "pose.q_eb[2,3]" → (:pose, [:q_eb, (2, 3)]); a Symbol is its String.
parse_leaf(leaf) → (head::Symbol, steps::Vector{Union{Symbol,Tuple{Vararg{Int}}}})
```

The head is the maximal run up to the first `.` or `[`. A `.name` step is a
`.` followed by such a run; an index step is `[`, one or more decimal
integers separated by `,`, `]`. Anything else (an empty head, an empty
name, whitespace, a stray character, an unclosed bracket, a non-integer
index, an index below one) is a refusal with reason `:leaf_syntax` and
the offending fragment in `step`. Steps may follow in any order:
`"legs[2].force"` is legal. The parse is string work of the shape, run
once (§14.4).

### The per-step resolution

One function, shared by `readers.jl` and `bindings.jl`, over a declared
type:

```julia
# Walk the declared type through the steps. Returns the chain as a tuple
# for the type parameter and the leaf's type, or one LeafRefusal.
resolve_leaf(::Type{P}, steps) → (chain::Tuple, leaf_type::DataType) | LeafRefusal
```

`LeafRefusal` is a plain struct, not a `Diagnostic`: `reason::Symbol`,
`step::String` (the offending step as spelled, `".q"` or `"[2,3]"`),
`declared::Any` (the type in hand at that step), `candidates::Vector{Symbol}`.
The caller wraps it in its own kind. The rules, in order, at each step
with `P` the type in hand:

- a `.name` step: `P <: Real`, `P <: Enum` or `P <: StaticArray` refuses
  `:no_such_field` with empty candidates; `_opaque(P)` refuses
  `:opaque_leaf`; otherwise `name ∈ fieldnames(P)` or `:no_such_field` with
  `candidates = collect(fieldnames(P))`; the type in hand becomes
  `fieldtype(P, name)`;
- an index step: `P <: StaticArray` or `:not_indexable` (a `Real`, an enum,
  an opaque leaf or a struct all refuse alike, `declared = P`); the arity is
  1 or `ndims(P)` or `:index_arity`; each index within `size(P)` (linear:
  within `length(P)`) or `:index_bounds`; the type in hand becomes
  `eltype(P)`.

An empty step list resolves to `((), P)`. The chain is the tuple of steps
as parsed, index steps as `Int` tuples, so `(:q_eb, (2,))` is a legal type
parameter. Nothing is checked against a value; the schema's types decide
everything, as `_check_index` did.

### The baked read

```julia
struct StateRead{P,C}   offset::Int end     # C = the chain
struct DerivRead{P,C}   offset::Int end
struct StoreRead{S,F,C} ci::Int     end     # F = the store field, as today
struct CellRead{A,C}    addr::A     end

@inline _read(entry::StateRead{P,C}, exec::Executor) where {P,C} =
    walk_leaf(reconstruct(P, exec.xbuf, entry.offset), Val(C))
```

`walk_leaf(value, ::Val{C})` unrolls the chain: a `Symbol` step is
`getfield`, an `Int`-tuple step is `getindex` with the tuple splatted. A
`@generated` body in `reconstruct`'s style or a recursive `@inline` over
`Base.tail`, whichever the builder finds inferable; the acceptance test is
the gather-twin testset's `@allocated == 0` over a read set that includes a
two-step address. `_take` goes. The `C = ()` case is the whole value, as
`I = Nothing` was.

`_read` gains a store-level core so both gathers share it:

```julia
@inline _read(entry::CellRead{A,C}, store::StoreBundle) where {A,C} =
    walk_leaf(gather_cell(store, entry.addr), Val(C))
@inline _read(entry::CellRead, exec::Executor) = _read(entry, exec.store)
```

### The resolvers

Each `_resolve_selector` method parses the leaf, finds the declared type
as today (`typeof(declared[head])`, `decl.outs[head]`, `_port_type(addr)`),
calls `resolve_leaf`, and on a `LeafRefusal` pushes
`_reader_violation(label, selector, refusal.reason; step, declared,
candidates)`. The store selectors accept what `resolve_leaf` accepts; since
a state field is a scalar or `SArray` (§7.1), a `.name` step there falls
out as `:no_such_field` with no candidates, and no separate flatness
check is written.

### Linearize

- `_site_key(::Val{:u}, ::CellRead{A,C})` is `(addr, C)`.
- `_check_seedable` takes the chain and the leaf type: any `Symbol` step in
  the chain of an `x` or `u` tap is `:unseedable` with `declared` the
  port's or field's type (the seed writes a whole cell or one `SArray`
  component); a leaf type that is not `Real` is `:vector_tap` as today; a
  leaf type that is not `Float64` is `:unseedable` as today. The `y` list
  keeps its `:vector_tap` check on the leaf type and takes any chain.
- The `x` seed site is `entry.offset + linear`, where `linear` is 1 for an
  empty chain and otherwise `LinearIndices(size(P))[idx...]` for the one
  index step, computed at resolution.
- `_seed_site!` for `CellRead{A,()}` writes the whole cell; for a one-step
  index chain it writes `Base.setindex(gather_cell(…), seed, linear)` with
  the same linear index.

### The binding register

`ReadGather{L,E<:Tuple}` keeps its name and holds `CellRead` entries in
`entries`; `gather_snapshot` maps `_read(entry, snapshot.store)`.
`_resolve_read`'s three table methods keep their name checks, then parse
and `resolve_leaf` against `_port_type(addr)`, and wrap a `LeafRefusal` in
`ReadBindingUnresolved(reason = refusal.reason, leaf, step, declared,
candidates)`. `:indexed` goes, with its arm and its rendering test. The
comment block at 103–115 says what is now true: the three table members
take a leaf address, the checks are the family's, and a binding gather is
the family's baked read over a snapshot. `devices.jl` 63 keeps
`Union{Nothing,ReadGather}`.

### `leaf_names`

The `StaticArray` method iterates `CartesianIndices(size(P))` in order and
prints `[i]` for `ndims(P) == 1`, `[i,j,…]` otherwise, so the flat order is
unchanged and a matrix leaf reads as a selector's own step. `test_leaves.jl`
178–181 pins the new spelling.

### Diagnostics

`TapResolution`: `index` goes; `leaf::String = ""` (the address as
authored, without the quotes) and `step::String = ""` join. Reasons:
`:scalar_index` goes; `:leaf_syntax`, `:no_such_field`, `:opaque_leaf`,
`:not_indexable`, `:index_arity`, `:index_bounds` join. `_tap_violation`
drops the ", index 2" clause. One shared clause function renders the six
leaf reasons for both kinds, in the file's style, each naming the step:

- `:leaf_syntax`: "its leaf address `pose.q_eb[` cannot be read at `[` — an
  address is a name followed by `.name` and `[k]` or `[k,l]` steps";
- `:no_such_field`: "`.q` steps into `KinPose{Float64}`, which has no field
  `q` — its fields are …" (a `Real`, enum or `SArray` in hand: "which has no
  fields");
- `:opaque_leaf`: "`.p` steps into `ISAField`, an opaque leaf the walk
  stops at — it is read whole";
- `:not_indexable`: "`[2]` indexes `Float64`, which has no components — an
  index step takes an `SArray`";
- `:index_arity`: "`[2,3]` gives two indices to `SVector{3, Float64}`,
  which takes one";
- `:index_bounds`: "`[4]` is outside `SVector{3, Float64}`".

Every arm cites §14.4 and D-276. `ReadBindingUnresolved` gains the same
fields and reasons and renders them through the same clause after its
device prefix. `Appendix C`'s two rows already describe the payloads.
`_reader_violation` passes `leaf = _leaf_string(selector)` on every arm.

### Naming

Under "Naming" (`implementation.md` 869). `leaf` for the authored address
(the field and the constructor parameter, a public spelling), `head` for
the parsed name, `steps` for the parsed vector, `chain` for the resolved
tuple and `C` for its type parameter, `step` for one step and for the
payload's spelled step, `leaf_type` for the type a chain resolves to,
`refusal` for a `LeafRefusal`, `linear` for the linear index of an `x` or
`u` seed. `parse_leaf`, `resolve_leaf` and `walk_leaf` are the new package
functions, each appending its target. No local named `leaf` in a scope
that reads a selector's `leaf` field beside it. The "Naming" clause that
lists "the selectors' `i`" among the parameters out of reach is edited to
name `leaf` instead.

## Stage 1: `leaf_names` and the matrix spelling

One commit. `leaves.jl`'s `_leaf_names!` for `StaticArray`; `test_leaves.jl`
178–181 and any other pinned matrix spelling (grep `test/` for `m[3]`-style
literals first). `leaves.jl` is in the routing table's last row, so this
stage runs the gate itself. `implementation.md`'s `leaves.jl` row (33)
says "`leaf_names`' dotted spelling of a flat position, a matrix leaf by
its indices".

## Stage 2: the selector surface and the compiled read

One commit, the larger one. `readers.jl` in full as shaped above;
`diagnostics.jl` for `TapResolution`, the shared clause and the retired
`ArgumentInvalid` arm; `linearize.jl` for the chain. Tests:

- `test_readers.jl`. Re-spell every indexed selector. The five-selectors
  testset adds a fixture whose output is an isbits struct with a nested
  `SVector` and an `SMatrix{2,2}` (grep every new fixture name across
  `test/` first) and reads `"pose.v[2]"`, `"pose.m[1,2]"`, `"pose.m[3]"`
  (equal to the former), `"pose"` whole, `:pose`, and `"q[2]"` on the
  state, at both activations. The gather-twin testset includes a two-step
  address in its `@allocated == 0` read set. The collecting testset asserts
  every leaf reason once, each with `step` and `declared`, and
  `:no_such_field` with candidates; the `:scalar_index` assertions become
  `:not_indexable`. `_spell` is asserted for a `Symbol` and for a string
  leaf.
- `test_linearize.jl`. Re-spell the taps. Add: a `[1,2]` `x` tap on an
  `SMatrix` state leaf (a small fixture; `x_init` may hold an `SMatrix`,
  §7.1) whose column matches the linear-index tap `[3]`; a `.name` step in
  `u` on a struct-typed root input refused `:unseedable`; the
  `:vector_tap` assertions unchanged in meaning.
- `test_trim.jl` 258: the spelled selector.
- `test_diagnostics.jl`'s rendering testset: the new fields and reasons on
  both kinds, the old ones gone; message text asserted as a non-empty
  string only.

`diagnostics.jl` beyond a new kind is the table's last row: this stage
runs the gate. `implementation.md`'s `readers.jl`, `linearize.jl` and
`diagnostics.jl` rows say what is now true, D-276 cited, D-271 dropped
from `readers.jl`'s and `linearize.jl`'s citation lines; the "Naming"
clause edited. `pending.md`'s first leaf-address bullet retires.

## Stage 3: the binding register

One commit. `bindings.jl` as shaped; `devices.jl` untouched unless the
field type must change. Tests: `test_readers.jl`'s source-rule testset
turns its three `:indexed` attaches into reads that succeed and yield the
component, `gather(handle, snapshot)` asserted against the snapshot's
value; a `.name` read through a binding on the struct-output fixture; one
`ReadBindingUnresolved` per leaf reason is not needed, one `:no_such_field`
and one `:index_bounds` are, each asserting `step`. Routed subset: the
`bindings` row of the table plus `readers`. `implementation.md`'s
`bindings.jl` row says what is now true; `pending.md`'s second
leaf-address bullet retires.

## The cold review

One fresh Opus reviewer over the three commits: open-mind stance, probe
scripts in the scratchpad, "empty is acceptable". Dimensions: D-276's
seven bullets against the code, one by one; the schema-only rule (no step
checked against a value); allocation-free gathers with two-step addresses
over an executor and over a snapshot, measured; the seeded lists' index-only
rule and the `[k,l]` seed site against a hand-computed column; the two
gathers sharing one `_read` core; "Naming" (`implementation.md` 869) over
every touched file; message text of every new arm read as a user would;
the docs battery green; the gate, run once, reported with the findings.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or
check out the working tree; baselines come from `git show b9720ce:file`.
Never add or commit a file this brief does not name: the tree carries
another session's untracked and modified files, and `git add -A` is
forbidden. Grep every new fixture name across `test/` before defining it:
a same-named type rebinds a fixture module silently. Fixtures live at top
level. Report: the commit hash, the files touched, the routed subset's
result with the assertion count, and every deviation from this brief with
its reason.
