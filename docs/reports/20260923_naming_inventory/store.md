# Naming inventory: src/store.jl

Tip: f64b9f3. Sites flagged: 36. Renames: 15. Collisions: 0. Roster proposals: 0.

## Letters with more than one meaning in this file

- `T`: the activation scalar in every binding (`scatter_group!`, `Clock`, `activation_scalar`); one meaning, kept
- `P`: a type parameter (`gather`, `scatter!`), a local holding a cell's type (`scatter_group!`) → the local renamed below
- `L`: a type parameter (`_cell_key`), a comprehension variable holding a leaf eltype (`gather`, `scatter!`); both a leaf eltype, kept
- `y`: the spec's outputs in `scatter_group!`; one meaning, kept

## `_cell_key(::Type{L}) where {L} = …` — line 40

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 40 | `L` | where | the leaf eltype | keep:typeparam | — |

## `@generated function gather(b::StoreBundle, a::CellAddr{P,K}) where {P,K}` — line 42

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 42 | `b` | param | the store bundle; quoted in `binds` | rename | `bundle` |
| 42 | `a` | param | the cell address; quoted as `a.offs` | rename | `addr` (the singular `readers.md` proposes for the roster; else `address`) |
| 42 | `P`, `K` | where | the cell's type, its eltype count | keep:typeparam | — |
| 43 | `Ls` | local | the cell's leaf eltypes | rename | `eltypes` |
| 45 | `k` | comprehension destructure | the eltype's position, its buffer's number | keep:index | — |
| 45 | `L` | comprehension destructure | the leaf eltype | keep:glance | — |
| 49 | `offs` | generated local | the address's per-eltype offsets; `leaves.jl`'s builders emit reads of it | rename | `offsets` |
| 50 | `buf1` … `bufK` | generated locals | the per-eltype buffers, named by `Symbol(:buf, k)` and read by `leaves.jl`'s builders | rename | `buffer1` … `bufferK` |

## `@generated function scatter!(b::StoreBundle, a::CellAddr{P,K}, v) where {P,K}` — line 55

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 55 | `b` | param | the store bundle | rename | `bundle` |
| 55 | `a` | param | the cell address | rename | `addr` (else `address`) |
| 55 | `v` | param | the value scattered; quoted as `:v` on line 59 | rename | `value` |
| 55 | `P`, `K` | where | the cell's type, its eltype count | keep:typeparam | — |
| 56 | `Ls` | local | the cell's leaf eltypes | rename | `eltypes` |
| 58 | `k` | comprehension destructure | the eltype's position | keep:index | — |
| 58 | `L` | comprehension destructure | the leaf eltype | keep:glance | — |
| 62 | `offs` | generated local | the per-eltype offsets | rename | `offsets` |
| 63 | `buf1` … `bufK` | generated locals | the per-eltype buffers | rename | `buffer1` … `bufferK` |

## `@generated function gather_group(addrs::NamedTuple{Ns}, store) where {Ns}` — line 73

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 73 | `addrs` | param | the face-keyed address group | keep:roster | — |
| 73 | `Ns` | where | the face names | keep:typeparam | — |
| 74 | `i` | comprehension | the face's position | keep:index | — |

## `@generated function scatter_group!(store, addrs::NamedTuple{Ns}, y::NamedTuple{Ys}, ::Type{T}, path::String, what::Symbol) where {Ns,Ys,T}` — line 86

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 86 | `addrs` | param | the face-keyed address group | keep:roster | — |
| 86 | `y` | param | the returned outputs, the spec's `y` | keep:spec | — |
| 87 | `Ns`, `Ys`, `T` | where | the declared port names, the returned names, the activation scalar | keep:typeparam | — |
| 92 | `stmts` | local | the scatter statements | rename | `statements` |
| 93 | `i` | for destructure | the port's position | keep:index | — |
| 93 | `n` | for destructure | the port's name, read four times | rename | `port` |
| 94 | `P` | local | the cell's declared type, a local and not a type parameter | rename | `declared` |
| 95 | `V` | local | the returned field's type, a local | rename | `observed` |

## `Clock{T}(t₀::Float64) where {T} = …` — line 129

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 129 | `T` | where | the deployment's scalar | keep:typeparam | — |
| 129 | `t₀` | param | the origin | keep:spec | — |

## `activation_scalar(::Clock{T}) where {T} = T` — line 132

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 132 | `T` | where | the activation scalar | keep:typeparam | — |

## Collisions

None.

## Roster proposals

None here. `a` → `addr` rides on `readers.md`'s proposal to add the singular `addr` beside `addrs`.

## Questions

- `offs` and `buf1` … `bufK` are locals of the code these generators emit, and `leaves.jl`'s `_mreconstruct_expr`/`_mflatten_expr` emit the reads of them. Renaming them is one change across both files, matched with `leaves.md`'s `buf`/`off` question. Does Step 3 include generated-code names?
- `offs` could instead stand as a spec derivative, beside the rules' `x_offs`; this report renames it because the rules list `x_offs` and not `offs`.
