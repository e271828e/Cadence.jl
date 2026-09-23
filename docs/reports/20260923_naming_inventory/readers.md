# Naming inventory: src/readers.jl

Tip: f64b9f3. Sites flagged: 100. Renames: 60. Collisions: 2. Roster proposals: 2.

## Letters with more than one meaning in this file

- `s`: a read selector in every binding; the discrete state store `d.s` it reads through (line 317) is a field, but a reader meets `s` as both on one line → selector sites renamed below
- `b`: the build (`_compile_reads`, `_resolve_reads`, three `_resolve_selector` methods), while two other `_resolve_selector` methods name the same parameter `build` → unified below
- `d`: a component's declarations (`_resolve_selector`); the rules reserve `d` for `diagnostics.jl`'s diagnostic → renamed below
- `t`: the tier (`_resolve_selector`); `t` is time → renamed below
- `P`: a type parameter (`_read`, `_check_index`), a local holding a field type (`_resolve_selector`) → the locals renamed below
- `e`: a reader entry (`gather`'s lambda, `_resolve_reads`) → one meaning; the `_resolve_reads` local renamed below
- `i`: the selector's component index into a vector leaf (`_index_arg`, the constructors, `_ipart`, `_take`), never a loop index here → renamed below

## `_index_arg(i::Integer) = Int(i)` — lines 83–84

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 83 | `i` | param | the authored component index | rename | `index` |
| 84 | `i` | param | the refused non-integer index | rename | `index` |

## `get_state(path, field, i = nothing) =` — lines 87–94

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 87 | `i` | optional param | the component index into a vector leaf (`get_state`) | rename | `index` |
| 89 | `i` | optional param | the component index (`get_deriv`) | rename | `index` |
| 91 | `i` | optional param | the component index (`get_output`) | rename | `index` |

## `_ipart(i) = …` — line 98

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 98 | `i` | param | the selector's index or `nothing` | rename | `index` |

## `_spell(s::GetState) = …` — lines 99–103

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 99 | `s` | param | the state selector | rename | `selector` |
| 100 | `s` | param | the derivative selector | rename | `selector` |
| 101 | `s` | param | the output selector | rename | `selector` |
| 102 | `s` | param | the root-input selector | rename | `selector` |
| 103 | `s` | param | the face selector | rename | `selector` |

## `reads(; sels...) = …` — line 125

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 125 | `sels` | keyword splat | the labeled selectors; abbreviation off the roster | rename | `selectors` |

## `function _reads(nt::NamedTuple)` — line 127

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 127 | `nt` | param | the labeled selectors | rename | `selectors` |
| 128 | `s` | for destructure | one selector, possibly not one | rename | `selector` |
| 131 | `v` | comprehension | one value of the tuple | keep:glance | — |

## `_take(v, ::Nothing) = v` — lines 163–164

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 163 | `v` | param | the value read | rename | `value` |
| 164 | `v` | param | the value read | rename | `value` |
| 164 | `i` | param | the component index | rename | `index` |

## `@inline _read(r::StateRead{P}, ex::Executor) where {P} =` — lines 166–176

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 166 | `r` | param | the state read entry | rename | `entry` |
| 166 | `ex` | param | the executor | rename | `exec` |
| 166 | `P` | where | the field's type | keep:typeparam | — |
| 168 | `r` | param | the derivative read entry | rename | `entry` |
| 168 | `ex` | param | the executor | rename | `exec` |
| 168 | `P` | where | the field's type | keep:typeparam | — |
| 174 | `r` | param | the store read entry | rename | `entry` |
| 174 | `ex` | param | the executor | rename | `exec` |
| 174 | `S`, `F` | where | the store type, the field name | keep:typeparam | — |
| 176 | `r` | param | the cell read entry | rename | `entry` |
| 176 | `ex` | param | the executor | rename | `exec` |

## `Reader{T,L}(entries::E) where {T,L,E<:Tuple} = …` — line 197

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 197 | `T`, `L`, `E` | where | the activation scalar, the labels, the entry tuple's type | keep:typeparam | — |

## `@inline gather(r::Reader{T,L}, ex::Executor{T}) where {T,L} =` — line 199

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 199 | `r` | param | the compiled reader | rename | `reader` |
| 199 | `ex` | param | the executor | rename | `exec` |
| 199 | `T`, `L` | where | the activation scalar, the labels | keep:typeparam | — |
| 200 | `e` | lambda param | one read entry | keep:glance | — |

## `gather(::Reader{T}, ::Executor{S}) where {T,S} = …` — line 202

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 202 | `T`, `S` | where | the reader's activation, the executor's | keep:typeparam | — |

## `function _compile_reads(rs::Reads, b::Build, ::Type{T} = Float64) where {T}` — line 225

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 225 | `rs` | param | the declared read set | rename | `read_set` |
| 225 | `b` | param | the build | rename | `build` (see Questions: `build` is a function) |
| 225 | `T` | where | the activation scalar | keep:typeparam | — |
| 226 | `diags` | destructure | the collected violations | keep:roster | — |

## `function _resolve_reads(rs::Reads, b::Build, ::Type{T}) where {T}` — line 241

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 241 | `rs` | param | the declared read set | rename | `read_set` |
| 241 | `b` | param | the build | rename | `build` (see Questions) |
| 241 | `T` | where | the activation scalar | keep:typeparam | — |
| 242 | `act` | local | the activation; `activation` is a function, called on this very line | roster? | `act` (see Roster proposals) |
| 243 | `diags` | local | the collected violations | keep:roster | — |
| 245 | `s` | for destructure | one selector | rename | `selector` |
| 246 | `e` | local | the resolved read entry, or `nothing` | rename | `entry` |

## `function _read_component(s, label::Symbol, structure::Structure, diags::Vector{Diagnostic})` — line 257

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 257 | `s` | param | the path-addressed selector | rename | `selector` |
| 257 | `diags` | param | the violation list | keep:roster | — |
| 260 | `ci` | local | the component index, or `nothing` | keep:index | — |

## `_rviol(label::Symbol, s, reason::Symbol; kw...) =` — line 269

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 269 | `s` | param | the selector at fault | rename | `selector` |
| 269 | `kw` | keyword splat | the arm's extra payload fields | rename | `payload` |

## `_selpath(s::Union{GetState,GetDeriv,GetOutput}) = s.path` — lines 277–280

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 277 | `s` | param | a path-addressed selector (`_selpath`) | rename | `selector` |
| 279 | `s` | param | a path-addressed selector (`_selindex`) | rename | `selector` |

## `function _check_index(s, label::Symbol, ::Type{P}, diags::Vector{Diagnostic}) where {P}` — line 286

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 286 | `s` | param | the selector | rename | `selector` |
| 286 | `P` | where | the resolved leaf's declared type | keep:typeparam | — |
| 286 | `diags` | param | the violation list | keep:roster | — |

## `_declares(label::Symbol, s, declares::Symbol, declared::NamedTuple) =` — lines 292, 298

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 292 | `s` | param | the selector | rename | `selector` |
| 298 | `s` | param | the selector | rename | `selector` |

## `_field(s::Union{GetState,GetDeriv}) = s.field` — lines 302–303

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 302 | `s` | param | a store selector | rename | `selector` |
| 303 | `s` | param | the output selector | rename | `selector` |

## `function _resolve_selector(s::GetState, label::Symbol, build::Build, act::Activation, …)` — line 305

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 305 | `s` | param | the state selector | rename | `selector` |
| 305 | `build` | param | the build; `build` is a function (`build.jl:720`), not called here | collision | keep `build` under a `path`-style exception (see Questions) |
| 305 | `act` | param | the activation; `activation` is a function | roster? | `act` |
| 306 | `diags` | param | the violation list | keep:roster | — |
| 307 | `ci` | local | the component index | keep:index | — |
| 309 | `d` | destructure | the component's declarations at this activation | rename | `decls` |
| 309 | `t` | destructure | the component's tier; `t` is time | rename | `tier` |
| 313 | `P` | local | the state field's type, a local and not a type parameter | rename | `field_type` |

## `function _resolve_selector(s::GetDeriv, label::Symbol, build::Build, act::Activation, …)` — line 320

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 320 | `s` | param | the derivative selector | rename | `selector` |
| 320 | `build` | param | the build; `build` is a function, not called here | collision | keep `build` under a `path`-style exception |
| 320 | `act` | param | the activation | roster? | `act` |
| 321 | `diags` | param | the violation list | keep:roster | — |
| 322 | `ci` | local | the component index | keep:index | — |
| 324 | `d` | destructure | the component's declarations | rename | `decls` |
| 324 | `t` | destructure | the component's tier | rename | `tier` |
| 331 | `P` | local | the state field's type | rename | `field_type` |

## `function _resolve_selector(s::GetOutput, label::Symbol, b::Build, act::Activation, …)` — line 338

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 338 | `s` | param | the output selector | rename | `selector` |
| 338 | `b` | param | the build; its sibling methods call it `build` | rename | `build` (see Questions) |
| 338 | `act` | param | the activation | roster? | `act` |
| 339 | `diags` | param | the violation list | keep:roster | — |
| 340 | `ci` | local | the component index | keep:index | — |
| 342 | `d` | local | the component's declarations | rename | `decls` |
| 348 | `addr` | local | the port's cell address | roster? | `addr` (see Roster proposals) |

## `function _resolve_selector(s::GetInput, label::Symbol, b::Build, act::Activation, …)` — line 352

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 352 | `s` | param | the root-input selector | rename | `selector` |
| 352 | `b` | param | the build | rename | `build` (see Questions) |
| 352 | `act` | param | the activation | roster? | `act` |
| 353 | `diags` | param | the violation list | keep:roster | — |
| 359 | `addr` | local | the root input's cell address | roster? | `addr` |

## `function _resolve_selector(s::GetFace, label::Symbol, b::Build, act::Activation, …)` — line 363

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 363 | `s` | param | the face selector | rename | `selector` |
| 363 | `b` | param | the build | rename | `build` (see Questions) |
| 363 | `act` | param | the activation | roster? | `act` |
| 364 | `diags` | param | the violation list | keep:roster | — |
| 365 | `p` | comprehension destructure | an output face's scope path, tested for `""` | rename | `face_path` |
| 365 | `f` | comprehension destructure | the face's name | rename | `face` |
| 373 | `addr` | local | the face's cell address | roster? | `addr` |

## Collisions

- `build` (line 305, `_resolve_selector(::GetState, …)`; line 320, `_resolve_selector(::GetDeriv, …)`) shares its name with the exported `build(root; activations)` at `build.jl:720`. Neither scope calls `build`. The function is API and keeps its name; the parameter is the spec's noun for the artifact. Proposal: extend the rules' `path` exception to `build`, which also settles the five `b` sites renamed to `build` above. Without the exception, every `Build` parameter in the package needs a qualifier, and none reads better than `build`.
- Function level, not a local: `_declares` has methods in two files with unrelated meanings. `declare.jl:260` asks whether a declaration function has a method for a component (`_declares(fn, c, extra...)`); `readers.jl:292` and `:298` build an `:undeclared` violation (`_declares(label, selector, declares, declared)`). They are one generic, told apart by dispatch alone, and break "every method of a function names its parameters alike". Proposal: rename this file's pair, for example `_undeclared_violation`, next to `_rviol`.

## Roster proposals

- `act`: 6 sites here (`_resolve_reads` line 242 and the five `_resolve_selector` methods), 75 word occurrences across `assembly.jl`, `build.jl`, `conditions.jl`, `diagnostics.jl`, `readers.jl`, `sim.jl`, `trace.jl`, `trim.jl`. It abbreviates "activation", and the full noun is taken by the function `activation(b::Build, T)` (`build.jl:923`), which `_resolve_reads` calls on the line that binds the local.
- `addr`: 3 sites here (lines 348, 359, 373), 52 word occurrences across eight files. The singular of the roster's `addrs`, "address"; `addrs` is on the roster and `addr` is not.

## Questions

- `build` as a parameter name: the rules forbid it (a package function), the spec uses it as the noun, and the file already uses it in two of five methods of `_resolve_selector`. Does `build` join `path` as a named exception?
- `ex` for the executor (five `_read` methods, `gather`): the proposals take the roster's `exec`; the brief's example table does not settle whether a parameter already spelled differently from a roster entry is a rename or a roster question.
- The selector's `i` (§14.10's "component index") is a field of four structs and a positional parameter of the exported `get_state`/`get_deriv`/`get_output`. The field stays `i` (out of scope); renaming the parameter to `index` makes the constructors read `GetState(path, field, index)` into a field named `i`. Acceptable, or is `i` the spec's own symbol here?
