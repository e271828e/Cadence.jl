# Naming inventory: src/bindings.jl

Tip: f64b9f3. Sites flagged: 41. Renames: 30. Collisions: 0. Roster proposals: 1.

## Letters with more than one meaning in this file

- `s`: a snapshot (`_gather`), a read selector (`_compile_gather`, `_resolve_read`) → both renamed below
- `a`: a cell address (`_gather`'s lambda), the conditioned magnitude (`_condition`) → the magnitude renamed below
- `e`: a table entry everywhere in code; the expo in `_condition`'s comment formula → the entry sites renamed below
- `T`: the binding's type (`_compile_gather`, `_resolve_read`), never the numeric type the rules reserve it for → renamed below
- `x`: the clamped axis value in `_condition`, not the state → renamed below

## `function TableBinding(; entries...)` — line 41

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 43 | `diags` | local | the collected diagnostics | keep:roster | — |
| 44 | `k` | for destructure | the channel name, read through line 64 | rename | `channel` |
| 44 | `e` | for destructure | the channel's table entry, read through line 64 | rename | `entry` |
| 60 | `dz` | local | the entry's deadzone | rename | `deadzone` |
| 63 | `ex` | local | the entry's expo | rename | `expo` |

## `claims(b::TableBinding) = …` — line 72

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 72 | `b` | param | the table binding; `roster.jl`'s `claims`/`reads` fallbacks name it `b` too | roster? | `b` as the binding family's letter (see Roster proposals) |
| 72 | `e` | comprehension | one table entry | keep:glance | — |

## `function map_input(datum::NamedTuple, b::TableBinding)` — line 91

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 91 | `b` | param | the table binding; `binding` is a function (`devices.jl:207`), so the plain noun is taken | roster? | `b` as the binding family's letter, else `table_binding` |
| 92 | `k` | do-block param | the datum field's channel name, read four times | rename | `channel` |
| 96 | `e` | local | the channel's table entry | rename | `entry` |

## `ReadGather{L}(addrs::A) where {L,A<:Tuple} = …` — line 124

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 124 | `L`, `A` | where | the labels, the address tuple's type | keep:typeparam | — |
| 124 | `addrs` | param | the resolved cell addresses | keep:roster | — |

## `_gather(r::ReadGather{L}, s::Snapshot) where {L} =` — line 126

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 126 | `r` | param | the compiled gather; `gather` is a function, so the plain noun is taken | rename | `read_gather` |
| 126 | `s` | param | the published snapshot | rename | `snapshot` |
| 126 | `L` | where | the labels | keep:typeparam | — |
| 127 | `a` | lambda param | one cell address | keep:glance | — |

## `function _compile_gather(layout::Layout, nt, T::Type, device::String)` — line 138

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 138 | `nt` | param | what the binding's `reads` returned, the labeled selectors; `reads` is a function | rename | `selectors` |
| 138 | `T` | param | the binding's type, not the numeric type | rename | `binding_type` |
| 142 | `addrs` | local | the resolved cell addresses | keep:roster | — |
| 142 | `s` | do-block param | one read selector, read three times over four lines | rename | `selector` |

## `_root_input_names(layout::Layout) = …` — line 151

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 151 | `f` | comprehension destructure | a root input's face name | keep:glance | — |

## `_cells_at(layout::Layout, p::AbstractString) =` — line 157

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 157 | `p` | param | the selector's component path | rename | `path` (the rules' `path` exception) |
| 158 | `q` | comprehension destructure | an address key's path, compared with `p`; three short names in one line | rename | `cell_path` |
| 158 | `n` | comprehension destructure | an address key's cell name | rename | `name` |

## `function _root_output_faces(layout::Layout)` — line 159

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 161 | `q` | comprehension destructure | an address key's path, tested against `""` | rename | `cell_path` |
| 161 | `n` | comprehension destructure | an address key's cell name | rename | `name` |

## `_resolve_read(::Layout, s::StoreSelector, T::Type, device::String) = …` — line 168

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 168 | `s` | param | the store selector at fault | rename | `selector` |
| 168 | `T` | param | the binding's type | rename | `binding_type` |

## `function _resolve_read(layout::Layout, s::GetOutput, T::Type, device::String)` — line 172

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 172 | `s` | param | the `get_output` selector | rename | `selector` |
| 172 | `T` | param | the binding's type | rename | `binding_type` |

## `function _resolve_read(layout::Layout, s::GetInput, T::Type, device::String)` — line 183

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 183 | `s` | param | the `get_input` selector | rename | `selector` |
| 183 | `T` | param | the binding's type | rename | `binding_type` |

## `function _resolve_read(layout::Layout, s::GetFace, T::Type, device::String)` — line 191

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 191 | `s` | param | the `get_face` selector | rename | `selector` |
| 191 | `T` | param | the binding's type | rename | `binding_type` |

## `function _condition(v, e)` — line 222

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 222 | `v` | param | the datum's raw channel value | rename | `value` |
| 222 | `e` | param | the channel's table entry | rename | `entry` |
| 223 | `dz` | local | the entry's deadzone | rename | `deadzone` |
| 224 | `ex` | local | the entry's expo | rename | `expo` |
| 226 | `x` | local | the value clamped to [-1, 1], not the state `x` | rename | `clamped` |
| 227 | `a` | local | the conditioned magnitude, rewritten twice | rename | `magnitude` |

## Collisions

None. No current local shares a name with a function. Two proposals avoid one: `r` takes `read_gather` because `gather` is a function (`devices.jl:248`, `readers.jl:202`), and `nt` takes `selectors` because `reads` is one (`readers.jl:125`).

## Roster proposals

- `b`: 2 sites here (`claims` line 72, `map_input` line 91), plus `roster.jl`'s `claims`/`reads` fallbacks (lines 50, 61). It is the binding family's parameter letter, not an abbreviation. The plain noun `binding` is a function (`devices.jl:207`), so the alternative is `table_binding` here and `binding_type`-style qualifiers there.

## Questions

- The rules reserve `T` for the numeric type, but this file uses a positional `T::Type` for the binding's type in five methods; the renames assume the rule wins over the file's habit.
- `_condition`'s comment writes the expo blend as `a = (1-e)·a + e·a³`; with `a` → `magnitude` and `e` → `entry`, the comment's letters no longer match the code. Step 3 should restate it in the new names.
