# Naming inventory: src/conditions.jl

Tip: f64b9f3. Sites flagged: 153. Renames: 77. Collisions: 4. Roster proposals: 2 (7 sites).

## Letters with more than one meaning in this file

- `s`: the discrete state (the `fragment` keyword, spec), a label string (`_step`) → the `_step` site renamed below; `S` is also a type parameter for a store's value type (`StoreWrite`, `_write!`) and for the executor's scalar (`apply!` fallbacks)
- `k`: a key (`_check_duplicates!`, `_leaf_offset`), a child node (`_flat` on `Combined`, `_scoped!`), a row of `structure.in_faces` (`_root_input`) → the non-key sites and the long-lived key renamed below
- `p`: a payload (`_payload`), a face-table pair (`_root_input` lambda), a path (`_root_input` comprehension), a `Prefix` (`_compare`), a prefix's tree position (`compile_plan` generator) → `_compare`'s renamed below
- `d`: a component's declarations (`_resolve_entries`, `capture`); the rules reserve `d` for a diagnostic in `diagnostics.jl` → both renamed below
- `P`: a port type held as a value (`_resolve_entries`), a tree position held as a value (`_prefix_drift`), and a type parameter for a lens position (`Getter`, `Authored`, `Prefix`, `_compare`) or a target type (`_convert`, `_unconvertible`, `_seeded_into_pinned`) → the two value sites renamed below
- `L`: a leaf type held as a value (`_resolve_entries`) and `Authored`'s type parameter → the value site renamed below
- `ex`: the executor (`apply!`, `_write!`, `_writes!`, `capture`) and a quoted expression (`Getter`'s generated body) → all renamed below
- `entry` (not a letter, same problem): a `CEntry` (`_flat`, `_check_duplicates!`, `_cviol`), a `ComponentEntry` (`_resolve_entries`, `_store_bases`, `_component`, `capture`), and an origin label string (`_flat` on `Scoped`) → `CEntry` keeps `entry` (and takes over `e`), the others renamed below

## `function fragment(; x = (;), s = (;), m = (;), inputs = (;))` — line 74

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 74 | `x`, `s`, `m` | keyword param | the continuous-state, discrete-state and mode payloads | keep:spec | — |

## `_payload(name, p)` — line 82

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 82 | `p` | param | the payload being checked | keep:glance | — |

## `combine(a::ConditionNode, b::NamedTuple)` / `combine(a::NamedTuple, b::ConditionNode)` — lines 110–111

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 110 | `a` | param | the left operand, a node | rename | `left` |
| 110 | `b` | param | the right operand, a bare `NamedTuple` | rename | `right` |
| 111 | `a` | param | the left operand, a bare `NamedTuple` | rename | `left` |
| 111 | `b` | param | the right operand, a node | rename | `right` |

## `_misuse_in(args::Tuple)` — line 130

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 130 | `n` | lambda param | an argument | keep:glance | — |
| 131 | `n` | generator | an argument that is a node | keep:glance | — |

## `_node_misuse(v, in_hand)` — line 133

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 133 | `v` | param | the value that is not a node | keep:glance | — |

## `_key(e::CEntry)` — line 164

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 164 | `e` | param | a condition entry; renamed with every other `CEntry` site for one name per file | rename | `entry` |

## `_step(origin::String, s::String)` — line 165

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 165 | `s` | param | the step's label; `s` is the discrete state by the spec | rename | `label` |

## `function _flat(n::Fragment, path::String, level, origin::String, pos::Tuple,` — line 167

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 167 | `n` | param | the node being flattened; all four methods use it | rename | `node` |
| 167 | `pos` | param | the node's tree position | rename | `tree_position` |
| 172 | `v` | for (destructure) | the authored value, consumed on the next line | keep:glance | — |

## `function _flat(n::Scoped, path::String, level, origin::String, pos::Tuple,` — line 184

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 184 | `n` | param | the `Scoped` node | rename | `node` |
| 184 | `pos` | param | the node's tree position | rename | `tree_position` |
| 186 | `entry` | local | the origin extended by this `at` step, a string, where `entry` elsewhere in the file is a `CEntry` | rename | `scoped_origin` |

## `_flat(n::Combined, path::String, level, origin::String, pos::Tuple,` — line 192

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 192 | `n` | param | the `Combined` node | rename | `node` |
| 192 | `pos` | param | the node's tree position | rename | `tree_position` |
| 196 | `i` | generator | the operand's position | keep:index | — |
| 196 | `k` | generator | the operand node; `k` is a key elsewhere in the file | rename | `child` |

## `function _flat(n::Override, path::String, level, origin::String, pos::Tuple,` — line 202

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 202 | `n` | param | the `Override` node | rename | `node` |
| 202 | `pos` | param | the node's tree position | rename | `tree_position` |
| 204 | `acc` | local | the entries layered so far | rename | `layered` |
| 205 | `i` | for | the layer's position | keep:index | — |
| 207 | `es` | local | the layer's own flattened entries | rename | `layer_entries` |
| 210 | `j` | local | the position in `acc` of the entry this one overrides, from `findfirst`, read over three lines | rename | `overridden` |
| 210 | `a` | lambda param | an entry already layered | keep:glance | — |

## `function _check_duplicates!(es::Vector{CEntry}, diags::Vector{Diagnostic})` — line 222

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 222 | `es` | param | the entries checked | rename | `entries` |
| 225 | `k` | local | the entry's leaf key, read over seven lines | rename | `key` |

## `function resolve_condition(node::ConditionNode, b::Build, ::Type{T} = Float64) where {T}` — line 280

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 280 | `b` | param | the build; `build` is taken by the function `build` | rename | `built` |
| 280 | `T` | type param | the activation's scalar | keep:typeparam | — |
| 281 | `act` | destructure | the activation; `activation` is taken by the function | roster? | — |
| 284 | `xs` | local | the plan's `x` writes, `(offset, value)` | keep:spec | — |
| 288 | `r` | for | one surviving `Resolved` entry, read over nine lines | rename | `survivor` |
| 289 | `e` | local | the survivor's condition entry | rename | `entry` |
| 303 | `ci` | for (destructure) | the component index | keep:roster | — |
| 304 | `ov` | local | the component's overlay pairs for this store | rename | `overlay` |

## `function _resolve_entries(node::ConditionNode, build::Build, ::Type{T}) where {T}` — line 332

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 332 | `build` | param | the build; shares its name with `build` (build.jl:720) | collision | `built` |
| 332 | `T` | type param | the activation's scalar | keep:typeparam | — |
| 334 | `act` | local | the activation | roster? | — |
| 341 | `e` | for | the condition entry checked, read over 25 lines | rename | `entry` |
| 344 | `addr` | local | the root input's cell address | roster? | — |
| 345 | `P` | local | the root input's port type, a value | rename | `port_type` |
| 346 | `ok`, `v` | destructure | whether the value converted, and the converted value, read on the next two lines | keep:glance | — |
| 351 | `ci` | local | the component index | keep:roster | — |
| 353 | `entry` | local | the `ComponentEntry`; beside the `CEntry` it becomes `entry` | rename | `comp_entry` |
| 354 | `c` | destructure | the component instance | rename | `comp` |
| 354 | `d` | destructure | the component's declarations at this activation, read to line 365 | rename | `decl` |
| 362 | `L` | local | the destination leaf type, a value, read to line 366 | rename | `leaf_type` |
| 363 | `ok`, `v` | destructure | whether the value converted, and the converted value | keep:glance | — |

## `_store_bases(build::Build, act::Activation)` — line 373

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 373 | `build` | param | the build; shares its name with `build` (build.jl:720) | collision | `built` |
| 373 | `act` | param | the activation | roster? | — |
| 374 | `ci` | comprehension | the component index | keep:roster | — |
| 375 | `entry` | comprehension | the `ComponentEntry` | rename | `comp_entry` |

## `function _leaf_offset(x::NamedTuple, field::Symbol)` — line 382

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 382 | `x` | param | a continuous-state declaration | keep:spec | — |
| 383 | `off` | local | the running leaf offset | rename | `offset` |
| 384 | `k`, `v` | for (destructure) | a field name and its declared value, consumed in the two-line body | keep:glance | — |

## `_convert(::Type{P}, v) where {P}` — line 391

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 391 | `P` | type param | the target type | keep:typeparam | — |
| 391 | `v` | param | the value converted | keep:glance | — |

## `_cviol(entry::CEntry, reason::Symbol; kw...)` — line 400

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 400 | `kw` | keyword splat | the arm's extra payload fields | rename | `payload` |

## `function _component(structure::Structure, e::CEntry, diags::Vector{Diagnostic})` — line 409

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 409 | `e` | param | the condition entry | rename | `entry` |
| 410 | `ci` | local | the component index | keep:roster | — |
| 410 | `entry` | lambda param | a `ComponentEntry`; freed for the `CEntry` | rename | `comp_entry` |

## `function _root_input(structure::Structure, e::CEntry, diags::Vector{Diagnostic})` — line 423

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 423 | `e` | param | the input entry | rename | `entry` |
| 429 | `k` | local | the row of `structure.in_faces` naming the face, from `findfirst`, read at 430 and 435 | rename | `row` |
| 429 | `p` | lambda param | an `in_faces` pair | keep:glance | — |
| 431 | `p`, `f` | comprehension (destructure) | a level's path and one of its input faces | keep:glance | — |
| 435 | `path` | destructure | the producer's path, beside `entry.path` in the same scope | rename | `producer_path` |
| 435 | `port` | destructure | the producer's port; shares its name with `port` (dataplane.jl:598, sim.jl:1806) | collision | `producer_port` |

## `_no_store(e::CEntry, tier::Tier)` — line 444

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 444 | `e` | param | the condition entry | rename | `entry` |

## `function _undeclared(e::CEntry, c, tier::Tier, declared::NamedTuple, ::Type{T}) where {T}` — line 450

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 450 | `e` | param | the condition entry | rename | `entry` |
| 450 | `c` | param | the component instance | rename | `comp` |
| 450 | `T` | type param | the activation's scalar | keep:typeparam | — |

## `_declared_workspace(c, tier::Tier, ::Type{T}) where {T}` — line 458

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 458 | `c` | param | the component instance | rename | `comp` |
| 458 | `T` | type param | the activation's scalar | keep:typeparam | — |

## `function _unconvertible(e::CEntry, v, ::Type{P}, ::Type{T}) where {P,T}` — line 466

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 466 | `e` | param | the condition entry | rename | `entry` |
| 466 | `v` | param | the authored value that failed to convert | keep:glance | — |
| 466 | `P`, `T` | type param | the destination leaf type, the activation's scalar | keep:typeparam | — |

## `_seeded_into_pinned(::Type{V}, ::Type{P}, ::Type{T}) where {V,P,T}` — line 471

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 471 | `V`, `P`, `T` | type param | the value's type, the leaf type, the activation's scalar | keep:typeparam | — |

## `function assert_total(plan::ConditionPlan, structure::Structure, op::Symbol)` — line 495

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 495 | `op` | param | the service operation checked, passed on as the kind's `op` field | rename | `operation` |
| 497 | `f` | comprehension | a root input face | keep:glance | — |

## `function apply!(ex::Executor{T}, plan::ConditionPlan{T}) where {T}` — line 516

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 516 | `ex` | param | the executor written into | rename | `exec` |
| 516 | `T` | type param | the activation's scalar | keep:typeparam | — |
| 517 | `off` | for (destructure) | the `xbuf` offset | rename | `offset` |
| 517 | `v` | for (destructure) | the value written; one-line body | keep:glance | — |
| 520 | `ci` | for (destructure) | the component index | keep:roster | — |
| 520 | `v` | for (destructure) | the whole store value; one-line body | keep:glance | — |
| 523 | `addr` | for (destructure) | the root input's cell address | roster? | — |
| 523 | `v` | for (destructure) | the root input's value; one-line body | keep:glance | — |

## `apply!(::Executor{S}, ::ConditionPlan{T}) where {S,T}` — line 529

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 529 | `S`, `T` | type param | the executor's scalar, the plan's | keep:typeparam | — |

## `@generated function (::Getter{P})(tree) where {P}` — line 555

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 555 | `P` | type param | the tree position | keep:typeparam | — |
| 556 | `ex` | local | the access expression being built; `ex` is the executor elsewhere in the file | rename | `access` |
| 557 | `step` | for | one position step, a field symbol or an index; shares its name with `Base.step`, which the file never calls | collision | `path_step` |

## `@inline (::Authored{P,L})(tree) where {P,L}` — line 579

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 579 | `P`, `L` | type param | the tree position, the destination leaf type | keep:typeparam | — |

## `StoreWrite{K,S,F}(ci::Int, defaults::S, authored::A) where {K,S,F,A<:Tuple}` — line 606

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 606 | `K`, `S`, `F`, `A` | type param | the store symbol, the store's value type, the overlay's field names, the lens tuple's type | keep:typeparam | — |
| 606 | `ci` | param | the component index | keep:roster | — |

## `@inline _write!(w::XWrite, ex::Executor, tree)` and its two siblings — lines 609, 612, 615

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 609 | `w` | param | the baked `x` write | keep:glance | — |
| 609 | `ex` | param | the executor | rename | `exec` |
| 612 | `w` | param | the baked input write | keep:glance | — |
| 612 | `ex` | param | the executor | rename | `exec` |
| 615 | `w` | param | the baked store write | keep:glance | — |
| 615 | `ex` | param | the executor | rename | `exec` |
| 615 | `K`, `S`, `F` | type param | the store symbol, its value type, the overlay's field names | keep:typeparam | — |
| 616 | `ov` | local | the overlay read through the lenses | rename | `overlay` |
| 616 | `a` | lambda param | one lens | keep:glance | — |

## `SpecializedPlan{T,NT}(xs::XS, stores::ST, inputs::IN, prefixes::PF) where {T,NT,XS,ST,IN,PF}` — line 658

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 658 | `T`, `NT`, `XS`, `ST`, `IN`, `PF` | type param | the activation's scalar, the tree type, the four tuple types | keep:typeparam | — |
| 658 | `xs` | param | the baked `x` writes | keep:spec | — |

## `function compile_plan(node::ConditionNode, b::Build, ::Type{T} = Float64) where {T}` — line 675

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 675 | `b` | param | the build; `build` is taken by the function `build` | rename | `built` |
| 675 | `T` | type param | the activation's scalar | keep:typeparam | — |
| 676 | `act` | destructure | the activation | roster? | — |
| 679 | `xs` | destructure | the `x` writes | keep:spec | — |
| 681 | `r` | for | one surviving `Resolved` entry, read over eight lines | rename | `survivor` |
| 682 | `e` | local | the survivor's condition entry | rename | `entry` |
| 693 | `ci` | for (destructure) | the component index | keep:roster | — |
| 694 | `ov` | local | the survivors overlaying this store | rename | `overlay` |
| 696 | `r` | generator | a survivor in the overlay | keep:glance | — |
| 697 | `r` | generator | a survivor in the overlay | keep:glance | — |
| 701 | `p`, `v` | generator (destructure) | a prefix's tree position and its string | keep:glance | — |

## `_scoped!(n::Scoped, pos::Tuple, out::Vector)` and its two siblings — lines 716, 718, 722

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 716 | `n` | param | the `Scoped` node | rename | `node` |
| 716 | `pos` | param | the node's tree position | rename | `tree_position` |
| 718 | `n` | param | the `Combined` node | rename | `node` |
| 718 | `pos` | param | the node's tree position | rename | `tree_position` |
| 719 | `i` | for | the operand's position | keep:index | — |
| 719 | `k` | for | the operand node | rename | `child` |
| 722 | `n` | param | the `Override` node | rename | `node` |
| 722 | `pos` | param | the node's tree position | rename | `tree_position` |
| 723 | `i` | for | the layer's position | keep:index | — |
| 723 | `k` | for | the layer node | rename | `child` |

## `function apply!(ex::Executor{T}, plan::SpecializedPlan{T,NT}, tree::NT) where {T,NT}` — line 746

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 746 | `ex` | param | the executor | rename | `exec` |
| 746 | `T`, `NT` | type param | the activation's scalar, the tree type | keep:typeparam | — |

## `apply!(::Executor{T}, ::SpecializedPlan{T,NT}, tree)` / `apply!(::Executor{S}, ::SpecializedPlan{T}, tree)` — lines 754, 757

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 754 | `T`, `NT` | type param | the activation's scalar, the compiled tree type | keep:typeparam | — |
| 757 | `S`, `T` | type param | the executor's scalar, the plan's | keep:typeparam | — |

## `@inline function _writes!(ws::Tuple, ex::Executor, tree)` — line 761

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 761 | `ws` | param | the remaining baked writes | rename | `writes` |
| 761 | `ex` | param | the executor | rename | `exec` |

## `@inline function _sweep_prefixes(ps::Tuple, tree)` — line 767

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 767 | `ps` | param | the remaining compiled prefixes | rename | `prefixes` |

## `@inline function _compare(p::Prefix{P}, tree) where {P}` — line 772

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 772 | `p` | param | the compiled prefix | rename | `prefix` |
| 772 | `P` | type param | the prefix field's tree position | keep:typeparam | — |

## `@noinline _shape_drift(::Type{NT}, ::Type{O}) where {NT,O}` — line 778

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 778 | `NT`, `O` | type param | the compiled tree type, the observed one | keep:typeparam | — |

## `@noinline _prefix_drift(P::Tuple, expected::String, observed::String)` — line 781

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 781 | `P` | param | the prefix's tree position, a value, not a type parameter | rename | `tree_position` |

## `function capture(sim::Simulation{T}) where {T}` — line 819

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 819 | `T` | type param | the simulation's scalar | keep:typeparam | — |
| 820 | `lc` | local | the lifecycle status; `lifecycle` is the function called on the same line | rename | `status` |
| 823 | `ex` | destructure | the executor | rename | `exec` |
| 824 | `act` | local | the activation | roster? | — |
| 826 | `ci` | for (destructure) | the component index | keep:roster | — |
| 826 | `entry` | for (destructure) | the `ComponentEntry` | rename | `comp_entry` |
| 827 | `d` | local | the component's declarations, read to line 830 | rename | `decl` |
| 843 | `f` | generator | a root input face | keep:glance | — |

## `function _capture_x(x::NamedTuple, buf::Vector, base::Int)` — line 850

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 850 | `x` | param | the continuous-state declaration | keep:spec | — |
| 850 | `buf` | param | the executor's `xbuf` | rename | `xbuf` |
| 851 | `off` | destructure | the running offset | rename | `offset` |
| 851 | `vals` | destructure | the reconstructed field values; `values` is the Base function called at line 852 | rename | `field_values` |
| 852 | `v` | for | a field's declared value; two-line body | keep:glance | — |

## Collisions

| line | local | function | defined at | called in the binding scope? |
| --- | --- | --- | --- | --- |
| 332 | `build` (`_resolve_entries` param) | `build` | `src/build.jl:720` | no |
| 373 | `build` (`_store_bases` param) | `build` | `src/build.jl:720` | no |
| 435 | `port` (`_root_input` destructure) | `port` | `src/dataplane.jl:598`, `src/sim.jl:1806` | no |
| 557 | `step` (`Getter`'s generated body) | `Base.step` | Base; the file never calls it | no |

## Roster proposals

- `act` (activation): 5 sites (lines 281, 334, 373, 676, 824). The function `activation` takes the full word, and build.jl's `compile` already uses `act`.
- `addr` (address): 2 sites (lines 344, 523), plus the `InputWrite` field. It is the singular of the roster's `addrs`.

## Questions

- The brief gives tip `4a3b725`; the tree was at `f64b9f3`, which adds only this brief. The header uses `f64b9f3`.
- `Build` parameters: across `src/`, 15 are `b`, 11 are `build` (colliding with the function) and 3 are `built` (show.jl). I proposed `built` here. It needs one ruling for the whole package.
- `Resolved`'s fields `e`, `L`, `v` and `CEntry`'s field `pos` are fields, out of scope, but every `r.e`, `r.L`, `r.v` reads beside the renamed locals. Should the fields follow (`entry`, `leaf_type`, `value`, `tree_position`)?
- `pos`: I proposed `tree_position` over a roster entry because trace.jl uses `pos` for a schema position, a different meaning.
- `op` in `assert_total` matches the diagnostic kinds' `op` field and diagnostics.jl's `_advance_entry(op)`. I proposed `operation`; group C's report may prefer a roster entry.
- `at(prefix, node)` / `at(::AbstractString, other)`, and `resolve_condition(other, …)` / `compile_plan(other, …)`: the misuse methods name their parameter `other` against `node`, on purpose. "Every method alike" would force `node`. Not flagged; needs a ruling.
- `combine(nodes...)` and `combine(left, right)` cannot name alike, one being variadic.
- `step`: the rules say "reached from Base", the brief says "a Base function the file calls". I listed `step` under the rules' wording.
- `w` in `_write!` stays `keep:glance`: `write` is the natural noun but shadows `Base.write`.
- `kid` in `_flat` on `Scoped` (line 187) is a plain word and not flagged; it holds the component at the prefix, and `child` would read better.
- `xs` is `keep:spec` as the plural of the spec's `x` and the plan's field name; confirm the reading.
- `_cviol` is an abbreviated function name; function names are out of scope, but it is the kind of name the sweep targets.
- The brief's example table renames `compile`'s `act` to `activation`, which would shadow the function `activation` (called in this file at lines 334 and 824). That is why I propose `act` for the roster instead.
