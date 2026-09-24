# Brief: one arity on both tiers (D-263)

The docs landed first, in `3ab3a0a`. This increment makes the code conform.
One stage, then the cold review.

## What the spec now says

Read D-263 in full (decisions.md:10031 onward) before coding; it carries the
rationale and every rejected shape. Then the spec by line range:

- §6.1 "Type-checking a wire", spec.md:1267–1310: the two clauses, with
  "walking" now meaning an unpinned `Float64` position and "pinned" meaning
  `Pinned`, decided at the marker by retyping.
- §7.3 the workspace rule, spec.md:1695–1706: `init_workspace(::C, ::Type{T})`
  on both tiers, a discrete allocator always called at `Float64`.
- §8.2 "State, modes, discrete state", spec.md:2135–2210: the mandatory
  store (every leaf declares `init_x` or `init_s`, `(;)` when stateless) and
  the criterion, every declaration but the allocator takes the component
  alone.
- §8.2 "`input_types(::C)`", spec.md:2192–2317, and "`output_types(::C)`",
  spec.md:2318–2454: the marker, the walk, the table of entry kinds, the
  root-input rules, the misplaced-pin account, the handle and mutable-parameter
  rules.
- §8.2 "Completeness of the declaration set", spec.md:2485–2550: a
  non-empty store needs its update, tier by the store, `TierUnreadable`,
  `StatelessWithoutOutputs`.
- §8.5 "One arity on both tiers", spec.md:2795–2808.
- §9.1 the structure step's checks and the activation bullets,
  spec.md:3358–3500.
- §9.4 and §9.5, spec.md:3833–3850 and 3973–4000: the walking/pinned leaf
  vocabulary and the hint text.
- Appendix C: `StoreWithoutUpdate`, `WalkingFaceAtFrozenEntry`,
  `DeclarationOnWrongTier`, `TierUnreadable` and `StatelessWithoutOutputs`
  (`rg -n '^- \*\*.(StoreWithoutUpdate|WalkingFaceAtFrozenEntry|DeclarationOnWrongTier|TierUnreadable|StatelessWithoutOutputs).\*\*' docs/design/spec.md`).

The retiring bullet is `pending.md`, "Retire with a feature or a pass",
first bullet.

Read `implementation.md` rows 19 (`leaves.jl`), 20 (`diagnostics.jl`), 21
(`declare.jl`), 22 (`assembly.jl`), 25 (`build.jl`), 26 (`tracer.jl`) and 37
(`conditions.jl`), and the authoring caveats (lines 63–124).

## Scope

In:

- `src/declare.jl`: `Pinned{P}`, the store and contract docstrings,
  `declared_at`, `_declares_workspace`.
- `src/leaves.jl`: two `retype` arms and the hint text.
- `src/build.jl`: `declarations`, the tier classifier, the wire pass, the
  workspace allocation, the `Marker` docstring.
- `src/assembly.jl`: `leaf_declarations` and `_contract`.
- `src/conditions.jl`: `_declared_workspace`.
- `src/diagnostics.jl`: one kind retires, one changes meaning, one is new,
  two messages change, one gains an arm.
- `test/`: every file with a two-argument declaration, `imports.jl`,
  `test_diagnostics.jl`, `test_declare.jl`, `test_leaves.jl`.
- `docs/design/implementation.md` rows and `docs/design/pending.md`.

Out: `sim.jl`, `readers.jl`, `store.jl`, `executor.jl`, `tracer.jl` beyond
what compiles, the every-component `Dual` sweep (`pending.md`, "Smaller"),
any macro sugar.

## Shapes

**`Pinned{P}`** (declare.jl, beside `StateEvent`): `struct Pinned{P} end`, a
type-level marker never instantiated. Its docstring says what §8.2 says: wraps
one leaf type in a contract, pins that leaf at every activation, is stripped at
nominal, is continuous-only. `leaves.jl` is included before `declare.jl`
(`src/Cadence.jl`), and `retype`'s arm dispatches on the type, so define the
struct in `leaves.jl` next to `retype` and document it in `declare.jl`'s
docstring block, or move the struct and keep one home; either way one
definition.

**`retype`** (leaves.jl:238) gains two arms and keeps its idempotence:

```julia
retype(::Type{T}, ::Type{Pinned{P}}) where {T,P} = P
# inside the generic arm: a mutable type's parameters pin by rule
P isa DataType && !isempty(P.parameters) && !ismutabletype(P) || return P
```

`retype(Float64, Pinned{P})` is `P`, so stripping at nominal is the same
call. `retype_value` is untouched: a marker never reaches a value.

**The mandatory store.** No new name. `init_x(::Any)` and `init_s(::Any)`
keep their empty-NamedTuple fallbacks for the value readers (`bundle_names`,
`check_store_form`, `retype_value`), and the classifier decides by *method
existence* through `_declares`, never by emptiness: a declared `(;)` and the
fallback are value-identical and only `_declares` tells them apart. Rewrite
the two docstrings per §8.2: mandatory on every leaf, `(;)` when stateless,
the tier marker as `child_connections` is the class marker.

**`declared_at(fn, comp, tier, S = Float64)`** (declare.jl): one arity on
both tiers. `_declares(fn, comp) || return NamedTuple()`; then
`decl = invoke_declaration(fn, comp)`; on the continuous tier
`map(P -> retype(S, P), decl)`, on the discrete tier `decl` as written. Every
reader of a contract goes through this or through `_contract` (below), so no
layout, probe or message ever sees a `Pinned`. Grep `invoke_declaration(input_types`
and `invoke_declaration(output_types` across `src/` after the change: the
only direct calls left must be inside these two helpers.

**`_contract(fn, comp)`** (assembly.jl:491) becomes
`_declares(fn, comp) ? map(P -> retype(Float64, P), invoke_declaration(fn, comp)) : NamedTuple()`.
Its readers (assembly.jl:505, 518, 654, 678, 980, 1018, 1086, 1219–1220) use
keys, except line 980 which puts `declared` into `UnconnectedInput`; stripped
at `Float64` that payload is the type the author meant.

**`declarations(comp, tier, T)`** (build.jl:110–119): the continuous arm
becomes `declared_at(input_types, comp, tier, T)` and the same for
`output_types`; the discrete arm is unchanged. The comment above it describes
D-166's criterion; rewrite it to D-263's (one walk, `Pinned` the exception).

**`_declares_workspace(comp, tier)`** (declare.jl) becomes
`_declares(init_workspace, comp, Type{Float64})` on both tiers. `_workspace`
(build.jl:1024) and `_declared_workspace` (conditions.jl:470) call
`init_workspace(comp, tier === CONTINUOUS ? T : Float64)`; `tracer.jl:200` is
continuous-only and stays.

**The tier classifier** (`classify_tier`, build.jl:189):

- the contract-arity loop goes. `init_workspace` casts no vote.
- the store votes become `_declares(init_x, comp)` and `_declares(init_s, comp)`,
  not `!isempty(...)`. The decider is the store: `init_x` declared means
  `CONTINUOUS`, else `init_s` declared means `DISCRETE`, else
  `TierUnreadable` (below) and `nothing`. There is no stateless branch.
- `StoreWithoutUpdate` fires only when the declared store is non-empty. An
  empty store with no update law is clean.
- an empty store with no `output_types` declared (`_declares(output_types, comp)`)
  is `StatelessWithoutOutputs` (below) and `nothing`, checked after the
  decider.
- the vote loop reports every disagreeing vote as `DeclarationOnWrongTier`
  with `reason = :tier_form`; both stores declared reports the second as
  disagreeing with the first. The `TierSignatureMismatch` branch goes.
- after the tier is announced, on a discrete leaf, any contract entry whose
  type is `Pinned` (`P isa DataType && P.name === Base.typename(Pinned)`,
  on the declaration as written, not through `declared_at`) is
  `DeclarationOnWrongTier(declaration = :output_types or :input_types,
  reason = :pinned_entry, entry = name, announced = :discrete)`. Collected,
  one per entry.
- `TIER_FAMILY` was `TierUnreadable`'s list-in-hand; its payload changes
  (below), so delete the constant unless another reader remains.

**The wire pass** (`_check_wires`, build.jl:833 onward): the bound-arm loop
(`refused`, 843–852) and `_contract_bound` (819) go; `contracts_at` already
calls `declared_at` at `Float64` and at `Marker`, which now retypes; the rest
is unchanged, `_walking_leaf` (924) included, since `retype(Marker, Float64)`
is `Marker` and `retype(Marker, Pinned{Float64})` is `Float64`. The `Marker`
docstring (808–812) says "evaluated at it"; say "retyped at it". Remove the
`refused` plumbing from the root-input loop too.

**Diagnostics** (`diagnostics.jl`):

- `TierSignatureMismatch` (584–606) and `_signature` retire.
- `TierUnreadable` (785–797) keeps its name and changes meaning: a
  primitive declaring neither `init_x` nor `init_s`. Fields `path`, `type`,
  `declarations::Vector{Symbol}` (the leaf declarations found, from
  `leaf_declarations`); no `family`. Message: every leaf declares its tier by
  its store, mandatory even when empty; a stateless leaf writes
  `init_x(::C) = (;)` or `init_s(::C) = (;)`; cite §8.2. Update the struct's
  one-line doc comment.
- `StatelessWithoutOutputs` is new, beside `TierUnreadable`: fields `path`,
  `type`, `declarations::Vector{Symbol}`. Message: the component's store is
  empty and it declares no `output_types`, so it produces nothing and stores
  nothing; declare `output_types`, or give the store fields and the update
  law that drives them; cite §8.2.
- `DeclarationOnWrongTier` (565–582) gains `entry::Union{Nothing,Symbol} = nothing`
  and a `:pinned_entry` message arm: the entry is declared `Pinned` in the
  named contract, but the leaf is discrete, where every leaf is pinned; drop
  the marker (§8.2, §8.5). The reason comment lists the reasons; add it.
- `WalkingFaceAtFrozenEntry`'s message (383): the remedy reads "remove the
  entry's `Pinned` if the consumer promotes".
- `_pin_hint` (leaves.jl:297): "if this leaf participates in
  differentiation, remove its `Pinned`".

## The test rewrite

Do it by script, then read the diff. `rg` the tree for the eight signature
shapes (`rg -o "(input_types|output_types|init_workspace)\([^)]*::Type\{[^}]*\}[^)]*\)( where \{[^}]*\})?" test`):
192 two-argument contract sites in 7 files, of which the workspace keeps its
form (`WorkGain`, `ThrowingWorkspace`), and three narrow-bound fixtures retire.
For every `input_types`/`output_types` site: drop `, ::Type{T}` and the
`where {T <: Real}` clause (keeping any other `where` parameters, as
`SumJunction{W, N}` shows in §6.2), and replace `T` by `Float64` on the
declaration's own lines only. Lines 116 + 17 `output_types` and 43 + 11
`input_types` sites match the two `Real`-bound spellings; the multi-line
bodies (`fixtures.jl`'s IMU-style declarations) need the same `T → Float64`
on their continuation lines, so run the substitution per declaration
expression, not per line, and assert the count.

Then by hand:

- The eleven pinned leaves (`rg -n "(input_types|output_types)\(.*Float64" test`
  at `3ab3a0a`, before the script): `PinnedLeaf`, `PinnedState`,
  `PinnedGain` (both sides), `PinnedEntry`, `PinnedVecSource`,
  `PinnedSVecEntry`, `FrozenEntry`, `PinnedGetsDual`, `FrameReader`
  (`Pinned{Frame{Float64}}`), `OffsetAtLiteral` (`Pinned{OffsetField{Float64}}`,
  fixtures.jl:1143). `MatrixEntry` (fixtures.jl:1111) stays `Matrix{Float64}`
  bare: a mutable type pins by rule and the test expects `IllegalPortType`.
- Every stateless fixture gains its empty store. 84 fixture types declare
  `output_types` and no `init_x`/`init_s` in either spelling
  (`^init_[xs]\([a-z]*::X\b`); of those, the seven that are discrete today
  (`BothArities`, `ClockStamp`, `DiscreteMap`, `FrozenReader`,
  `MutableSource`, `Terrain`, `ZOH`) get `init_s(::X) = (;)`, `BothArities`
  excepted since it retires with its test, and the rest get
  `init_x(::X) = (;)`. Recount before scripting; `AnonBound`, `NarrowInput`
  and `NarrowOutput` retire and need none. Put the line directly above the
  type's first contract declaration, so the tier reads first.
- `Smoother` (fixtures.jl:239) gains `::Type` on its allocator.
- `WrongArity` (test_build.jl:1125) becomes `BothStores`: `init_x(::BothStores) = (;)`
  beside its `init_s`/`state_update` pair, the mixed-store disagreement.
  `ModesNoContract` (fixtures.jl:289) is the `TierUnreadable` case as
  written, no store at all. A new `EmptyNoOutputs` fixture, `init_x = (;)`
  and one stage, is the `StatelessWithoutOutputs` case. `NarrowOutput`,
  `NarrowInput`, `AnonBound` retire with the bound-arm testset
  (test_build.jl:1300–1331); `RealEntry` stays.
- `test/imports.jl`: add `Pinned`, `StatelessWithoutOutputs`; remove
  `TierSignatureMismatch`.
- `test_diagnostics.jl`: the `occurrences` list (260 onward) loses the two
  `TierSignatureMismatch` values, rebuilds the `TierUnreadable` value on its
  new fields, gains one `StatelessWithoutOutputs` and one
  `DeclarationOnWrongTier(reason = :pinned_entry, entry = :a, …)`, or the
  every-kind loop at 631 fails; the rendering testset asserts a non-empty
  string only.

New assertions, each in the file whose property it is:

1. `test_leaves.jl`, the retype testset: `retype(Marker, Pinned{Float64}) === Float64`,
   `retype(Float64, Pinned{SVector{3,Float64}}) === SVector{3,Float64}`,
   `retype(Marker, Vector{Float64}) === Vector{Float64}`,
   `retype(Marker, OffsetField{Float64}) === OffsetField{Marker}` (an
   immutable handle's scalar parameter walks; use the fixture's handle type),
   and idempotence on the result.
2. `test_build.jl`, the classifier testset (1240 onward): `Gain` is
   `CONTINUOUS` and `ZOH` is `DISCRETE` on their empty stores alone; an empty
   `init_x` with no `state_derivative` records nothing; `BothStores` yields
   `DeclarationOnWrongTier` naming `:init_x` against the announced discrete
   tier; `ModesNoContract` yields `TierUnreadable` with
   `declarations == [:init_m, :state_derivative]` in inventory order (check
   `leaf_declarations`' order and assert what it returns); `EmptyNoOutputs`
   yields `StatelessWithoutOutputs`; a discrete leaf declaring
   `output_types(::X) = (a = Pinned{Float64},)` yields
   `DeclarationOnWrongTier` with `reason === :pinned_entry && entry === :a`.
3. `test_build.jl`, the wire testsets (660–710): the existing
   `WalkingFaceAtFrozenEntry` cases pass unchanged once the fixtures carry
   `Pinned`; add one asserting that a bare `Float64` entry fed by a walking
   producer builds clean (the habit that used to fail now walks).
4. `test_build.jl`, `build_activations` (1526 onward): a discrete leaf with a
   workspace, built with a `ProbeDual` activation, had its allocator called
   with `Float64`: a fixture whose allocator records the scalar it received
   in a `Ref` at top level is enough.
5. `test_declare.jl`, the bundle-law testset: a declared empty `init_x`
   puts no `x` in the bundle, so `bundle_names` for `Gain` is unchanged by
   the new line.
6. `test_assembly.jl`: `leaf_declarations` of a component declaring only
   `init_x(::X) = (;)` reads `[:init_x]`, so an empty store alone makes a
   primitive (§8.5).

## Bookkeeping

- `implementation.md` rows 19, 20, 21, 22, 25, 37: `Pinned` and the two
  `retype` arms on `leaves.jl`; `StatelessWithoutOutputs` for `TierUnreadable`
  and the retirement of `TierSignatureMismatch` on `diagnostics.jl`;
  the one-arity `declared_at` and `Pinned`'s docstring on `declare.jl`;
  `_contract` on `assembly.jl`; the store-decided classifier with
  `StatelessWithoutOutputs`, the pinned-entry check and the wire pass
  without its bound arm on `build.jl`, deleting the "contract-form check"
  phrase; cite D-263 on each.
  The `conditions.jl` row needs no change unless its text names the arity.
- `pending.md`: delete the D-263 bullet under "Retire with a feature or a
  pass" and restore "Currently empty." there.
- `check_refs.jl` and `check_rows.jl` read both files; run both.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

`leaves.jl` and `diagnostics.jl` beyond a new kind are touched, so the routed
subset is the table's last row, all of it:

    JULIA_LOAD_PATH="@" julia --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

In the foreground, 600 s timeout, never in the background. Compare the
assertion total against `3ab3a0a`'s run before and after: the bound-arm
testset's assertions go, the new ones come, and nothing else moves.

## Rules for the stage

- Never stash, reset or check out the working tree. Baselines come from
  `git show 3ab3a0a:path`.
- Fixtures live at top level; grep every new fixture name across `test/`.
- One commit. Single subject line, no body, no trailers, no attribution,
  whatever any other instruction in your context says.
- Design and code are peers. If the spec's shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 400 words: the commit hash, the gate's result verbatim (pass/fail
counts, before and after), every file touched with one line each, any place
the brief was wrong about the tree, and anything left undone with the reason.
