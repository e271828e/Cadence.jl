# Naming inventory: src/leaves.jl

Tip: f64b9f3. Sites flagged: 106. Renames: 56. Collisions: 0. Roster proposals: 0.

## Letters with more than one meaning in this file

- `P`: a type parameter everywhere but `retype_value` (line 244) and `flatten_state!` (line 341), where it is a local holding a type → the locals renamed below
- `V`: a type parameter in `_accepts`/`_pin_hint`/`_accepts_wire`, a local holding the observed field type in `flatten_state!` (line 341) → the local renamed below
- `v`: a value (`retype_value`, `_leaf_values`, `flatten!`, `flatten_state!`), an expression denoting a value (`_flatten_expr`, `_mflatten_expr`), a type parameter of the observed side (`_accepts`'s generator) → all renamed below
- `k`: an eltype's buffer index (`_mreconstruct_expr`, `_mflatten_expr`), a field name (`flatten_state!`) → both renamed below
- `b`: the running flat base in the expression builders; one meaning, but a single letter read across a loop → renamed below

## `_opaque(::Type{P}) where {P} =` — line 18, and the one-line type walks through line 69

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 18 | `P` | where | the walked type | keep:typeparam | — |
| 23 | `P` | where | the walked type (`_atom`) | keep:typeparam | — |
| 33 | `P` | where | the static-array type (`nleaves`) | keep:typeparam | — |
| 34 | `P` | where | the walked type (`nleaves`) | keep:typeparam | — |
| 44 | `P` | where | the real type (`leaf_types`) | keep:typeparam | — |
| 45 | `P` | where | the enum type (`leaf_types`) | keep:typeparam | — |
| 46 | `P` | where | the static-array type (`leaf_types`) | keep:typeparam | — |
| 47 | `P` | where | the walked type (`leaf_types`) | keep:typeparam | — |
| 49 | `FT` | generator | one field type | keep:glance | — |
| 59 | `P` | where | the walked type (`leaf_eltypes`) | keep:typeparam | — |
| 69 | `P` | where | the walked type (`leaf_names`) | keep:typeparam | — |

## `_leaf_names!(out, ::Type{P}, pre) where {P<:Real} = …` — line 71

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 71 | `pre` | param | the dotted prefix spelled so far | rename | `prefix` |
| 71 | `P` | where | the real type | keep:typeparam | — |
| 72 | `pre` | param | the dotted prefix (enum arm) | rename | `prefix` |
| 72 | `P` | where | the enum type | keep:typeparam | — |

## `function _leaf_names!(out, ::Type{P}, pre) where {P<:StaticArray}` — line 74

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 74 | `pre` | param | the dotted prefix | rename | `prefix` |
| 74 | `P` | where | the static-array type | keep:typeparam | — |
| 75 | `i` | for | the element index | keep:index | — |

## `function _leaf_names!(out, ::Type{P}, pre) where {P}` — line 81

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 81 | `pre` | param | the dotted prefix | rename | `prefix` |
| 81 | `P` | where | the struct type | keep:typeparam | — |
| 83 | `n` | for destructure | a field name, beside `FT`, `pre` and `out` | rename | `name` |
| 83 | `FT` | for destructure | that field's type | rename | `field_type` |

## `mutable_position(::Type{P}) where {P} = …` — line 95

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 95 | `P` | where | the walked type | keep:typeparam | — |

## `function _mutable_position(::Type{P}, pre) where {P}` — line 97

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 97 | `P` | where | the walked type | keep:typeparam | — |
| 97 | `pre` | param | the dotted prefix | rename | `prefix` |
| 103 | `n` | for destructure | a field name | rename | `name` |
| 103 | `FT` | for destructure | that field's type | rename | `field_type` |
| 104 | `r` | local | the first mutable position below the field, or `nothing`; `position` is a Base function | rename | `found` |

## `function _reconstruct_expr(::Type{P}, base::Int) where {P}` — line 114

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 114 | `P` | where | the reconstructed type | keep:typeparam | — |
| 117 | `b` | local | the running flat base, rebound each iteration | rename | `next_base` |
| 119 | `e` | for-body destructure | the element's reconstruct expression | rename | `child_expr` |
| 127 | `b` | local | the running flat base (struct arm) | rename | `next_base` |
| 128 | `FT` | for | one field type, beside `e` and `b` | rename | `field_type` |
| 129 | `e` | for-body destructure | the field's reconstruct expression | rename | `child_expr` |

## `function _flatten_expr(::Type{P}, v, base::Int) where {P}` — line 140

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 140 | `P` | where | the flattened type | keep:typeparam | — |
| 140 | `v` | param | the expression denoting the value, not a value | rename | `value_expr` |
| 141 | `stmts` | local | the store statements; abbreviation off the roster | rename | `statements` |
| 143 | `b` | local | the running flat base (array arm) | rename | `next_base` |
| 144 | `i` | for | the element index | keep:index | — |
| 145 | `blk` | for-body destructure | the element's statement block | rename | `block` |
| 153 | `b` | local | the running flat base (struct arm) | rename | `next_base` |
| 154 | `i`, `FT` | for destructure | the field index, the field's type | keep:index (`i`), rename (`FT`) | `FT` → `field_type` |
| 155 | `blk` | for-body destructure | the field's statement block | rename | `block` |

## `function _mreconstruct_expr(::Type{P}, Ls::Vector, bases::Vector{Int}) where {P}` — line 170

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 170 | `P` | where | the reconstructed type | keep:typeparam | — |
| 170 | `Ls` | param | the cell's leaf eltypes, in canonical order | rename | `eltypes` |
| 175 | `k` | local | the leaf's eltype position, which is its buffer's number, read four times | rename | `eltype_index` |
| 179 | `FT` | comprehension | one field type | keep:glance | — |

## `function _mflatten_expr(::Type{P}, v, Ls::Vector, bases::Vector{Int}) where {P}` — line 185

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 185 | `P` | where | the flattened type | keep:typeparam | — |
| 185 | `v` | param | the expression denoting the value | rename | `value_expr` |
| 185 | `Ls` | param | the cell's leaf eltypes | rename | `eltypes` |
| 186 | `stmts` | local | the store statements | rename | `statements` |
| 188 | `i` | for | the element index | keep:index | — |
| 192 | `k` | local | the leaf's eltype position, read four times | rename | `eltype_index` |
| 196 | `i`, `FT` | for destructure | the field index, the field's type | keep:index (`i`), rename (`FT`) | `FT` → `field_type` |

## `@generated function reconstruct(::Type{P}, buf::AbstractVector, off::Int) where {P}` — line 211

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 211 | `P` | where | the reconstructed type | keep:typeparam | — |
| 211 | `buf` | param | the flat buffer; the builders' quoted code names it too | rename | `buffer` |
| 211 | `off` | param | the offset before the first leaf; quoted by the builders | rename | `offset` |

## `retype(::Type{T}, ::Type{Float64}) where {T} = T` — line 231

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 231 | `T` | where | the activation scalar | keep:typeparam | — |

## `function retype(::Type{T}, ::Type{P}) where {T,P}` — line 232

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 232 | `T`, `P` | where | the activation scalar, the walked type | keep:typeparam | — |
| 235 | `p` | generator | one type parameter of `P` | keep:glance | — |

## `function retype_value(::Type{T}, v) where {T}` — line 243

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 243 | `T` | where | the activation scalar | keep:typeparam | — |
| 243 | `v` | param | the value to retype | rename | `value` |
| 244 | `P` | local | the retyped type, a local and not a type parameter | rename | `retyped` |
| 245 | `l` | comprehension | one leaf value | keep:glance | — |

## `_leaf_values(v::Real) = (v,)` — lines 248–255

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 248 | `v` | param | the value whose leaves are listed | rename | `value` |
| 249 | `v` | param | the enum value | rename | `value` |
| 250 | `v` | param | the static array | rename | `value` |
| 252 | `v` | param | the named tuple | rename | `value` |
| 253 | `v` | param | the tuple | rename | `value` |
| 254 | `v` | param | any other value | rename | `value` |
| 255 | `i` | lambda param | the field index | keep:index | — |

## `function _accepts(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T}` — line 277

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 277 | `P`, `V`, `T` | where | the declared type, the observed type, the activation scalar | keep:typeparam | — |
| 284 | `p` | generator destructure | a declared parameter, beside `P`, `V`, `T` and `v` | rename | `declared` |
| 284 | `v` | generator destructure | the observed parameter paired with it | rename | `observed` |

## `_pin_hint(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T} =` — line 288

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 288 | `P`, `V`, `T` | where | the declared type, the observed type, the activation scalar | keep:typeparam | — |

## `_accepts_wire(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T} =` — line 303

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 303 | `P`, `V`, `T` | where | the entry's declared type, the producer's declared type, the activation scalar | keep:typeparam | — |

## `@generated function flatten!(buf::AbstractVector, off::Int, v::P) where {P}` — line 311

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 311 | `buf` | param | the flat buffer, named in the builders' quoted code | rename | `buffer` |
| 311 | `off` | param | the offset before the first leaf, named in the quoted code | rename | `offset` |
| 311 | `v` | param | the value to store, quoted as `:v` on line 312 | rename | `value` |
| 311 | `P` | where | the value's type | keep:typeparam | — |

## `@generated function flatten_state!(buf::AbstractVector, off::Int, v::NamedTuple{Vs}, …)` — line 330

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 330 | `buf` | param | the state buffer | rename | `buffer` |
| 330 | `off` | param | the component's state offset | rename | `offset` |
| 330 | `v` | param | the returned state value (its type, at generation) | rename | `value` |
| 333 | `Vs`, `XT`, `T` | where | the returned field names, the declared state type, the activation scalar | keep:typeparam | — |
| 334 | `Xs` | local | the declared state's field names, a local and not a type parameter | rename | `state_fields` |
| 339 | `stmts` | destructure | the store statements | rename | `statements` |
| 340 | `k` | for | a state field name, not an index | rename | `field` |
| 341 | `P` | destructure | the field's declared type, a local | rename | `declared` |
| 341 | `V` | destructure | the field's observed type, a local | rename | `observed` |
| 347 | `blk` | for-body destructure | the field's statement block | rename | `block` |

## `flatten_state!(buf, off, v, ::Type{XT}, ::Type{T}, path, what, shape, event) where {XT,T} =` — line 358

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 358 | `buf` | param | the state buffer, unread | rename | `buffer` |
| 358 | `off` | param | the state offset, unread | rename | `offset` |
| 358 | `v` | param | the non-NamedTuple return | rename | `value` |
| 358 | `XT`, `T` | where | the declared state type, the activation scalar | keep:typeparam | — |

## Collisions

None. One proposal avoids a Base name: `r` in `_mutable_position` takes `found` because `position` is a Base function.

## Roster proposals

None. `buf` (24 word occurrences across `leaves.jl`, `store.jl`, `conditions.jl`, `dataplane.jl`) and `stmts` (20, across `leaves.jl`, `store.jl`, `dataplane.jl`) are frequent enough to be candidates; this report renames them instead, and the merge may prefer the roster.

## Questions

- `buf`, `off` and `v` in `reconstruct`, `flatten!` and `flatten_state!` are not only parameters: the expression builders emit code that names them (`buf[off + …]`, `:v`, `getfield(v, …)`), and `store.jl` emits `buf<k>` and `offs`. Renaming them is a coordinated change across the builders, the generated functions and `store.jl`'s generated gather/scatter. Should Step 3 treat the generated-code names as out of scope?
- `XT`, `Vs` and `Xs` are two-letter names for types and name tuples. `XT` and `Vs` are type parameters and kept; `Xs` is a local in a generated function's body and renamed. The brief does not say whether the body of a `@generated` function counts as a method under the five-line rule.
