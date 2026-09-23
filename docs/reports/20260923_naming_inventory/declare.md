# Naming inventory: src/declare.jl

Tip: f64b9f3. Sites flagged: 45. Renames: 20. Collisions: 2. Roster proposals: 1.

## Letters with more than one meaning in this file

- `t`: the tier in every binding (`tier_word`, `declared_at`, `update_of`, `bundle_names`, `_declares_workspace`, `_tier_names`, `classify_bundle_field`), while the bundle symbol `:t` the same functions push is time → tier sites renamed below
- `T`: the activation's numeric type parameter (`input_types`, `output_types`, `probe_value`), the period value in `Period`'s constructors (the spec's `T = period(q)`) → kept on both counts, raised under Questions

## `input_types(::Any, ::Type{T}) where {T <: Real} = …` — line 56

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 56 | `T` | where | the activation scalar | keep:typeparam | — |

## `output_types(::Any, ::Type{T}) where {T <: Real} = …` — line 69

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 69 | `T` | where | the activation scalar | keep:typeparam | — |

## `Period(T::Union{Integer,Rational{<:Integer}}) = …` — line 128

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 128 | `T` | param | the period in seconds, the spec's `T` and the field it fills | keep:spec | — (see Questions) |
| 129 | `T` | param | the rejected float period | keep:spec | — (see Questions) |

## `Hz(f::Union{Integer,Rational{<:Integer}}) = …` — line 133

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 133 | `f` | param | the frequency | rename | `frequency` |
| 134 | `f` | param | the rejected float frequency | rename | `frequency` |

## `period(q::Period) = q.T` — line 137

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 137 | `q` | param | the quantity, the spec's `q` in `period(q)` | keep:spec | — |

## `Relative(K::Integer) = …` — line 148

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 148 | `K` | param | the tick multiplier, the spec's `K` | keep:spec | — |

## `Absolute(q::Period, τ::Union{Integer,Rational{<:Integer}} = 0) = …` — line 158

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 158 | `q` | param | the quantity | keep:spec | — |
| 158 | `τ` | param | the anchor offset | keep:spec | — |
| 159 | `τ` | param | the rejected float offset | keep:spec | — |
| 161 | `q` | param | the rejected non-quantity | keep:spec | — |
| 161 | `τ` | vararg param | whatever followed it, unread | keep:spec | — |

## `_holding(σ::Bool) = σ` — line 206

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 206 | `σ` | param | the guard's `Bool` return | keep:spec | — |
| 207 | `σ` | param | the guard's sign-form return | keep:spec | — |

## `function foreign_declarations(c)` — line 246

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 246 | `c` | param | the component instance | rename | `comp` |
| 247 | `M` | local | the component type's parent module | rename | `author_module` |
| 248 | `n` | comprehension | one family name, read three times beside `M` and `c` | rename | `name` |

## `has_stage(fn, c) = …` — line 252

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 252 | `fn` | param | the stage function asked about | roster? | `fn` (see Roster proposals), else `stage` |
| 252 | `c` | param | the component instance | rename | `comp` |

## `_declares(fn, c, extra...) =` — line 260

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 260 | `fn` | param | the declaration function asked about | roster? | `fn`, else `declaration` |
| 260 | `c` | param | the component instance | rename | `comp` |

## `tier_word(t::Tier) = …` — line 270

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 270 | `t` | param | the tier; `t` is time | rename | `tier` |

## `declared_at(fn, c, t::Tier, ::Type{S} = Float64) where {S} =` — line 277

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 277 | `fn` | param | the declaration function | roster? | `fn`, else `declaration` |
| 277 | `c` | param | the component instance | rename | `comp` |
| 277 | `t` | param | the tier | rename | `tier` |
| 277 | `S` | where | the scalar the continuous form is evaluated at | keep:typeparam | — |

## `update_of(t::Tier) = …` — line 285

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 285 | `t` | param | the tier | rename | `tier` |

## `function bundle_names(fn, c, t::Tier, stage1_ports::Tuple)` — line 305

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 305 | `fn` | param | the stage function whose bundle is built | roster? | `fn`, else `stage` |
| 305 | `c` | param | the component instance | rename | `comp` |
| 305 | `t` | param | the tier, beside the bundle symbol `:t` (time) it pushes on line 323 | rename | `tier` |
| 307 | `names` | local | the bundle's field names; `Base.names` is exported | collision | `fields` |

## `_declares_workspace(c, t::Tier) =` — line 328

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 328 | `c` | param | the component instance | rename | `comp` |
| 328 | `t` | param | the tier | rename | `tier` |

## `function event_bundle_names(c)` — line 337

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 337 | `c` | param | the component instance | rename | `comp` |
| 338 | `names` | local | the guard/handler bundle's field names; `Base.names` is exported | collision | `fields` |

## `_tier_names(t::Tier) = …` — line 361

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 361 | `t` | param | the tier | rename | `tier` |
| 361 | `tt` | generator destructure | a legal set's tier, compared with `t` | rename | `set_tier` |
| 361 | `v` | generator destructure | a legal set's field names; three short names in one line | rename | `fields` |

## `function classify_bundle_field(family::Symbol, t::Tier, field::Symbol)` — line 369

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 369 | `t` | param | the tier | rename | `tier` |

## `probe_value(::Type{T}) where {T<:Real} = zero(T)` — lines 381–385

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 381 | `T` | where | the real port type | keep:typeparam | — |
| 383 | `E` | where | the enum port type | keep:typeparam | — |
| 384 | `P` | where | the static-array port type | keep:typeparam | — |
| 385 | `P` | where | any other port type | keep:typeparam | — |

## `_framework_synthesis(::Type{P}) where {P} =` — line 390

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 390 | `P` | where | the port type | keep:typeparam | — |

## Collisions

- `names` (line 307, `bundle_names`; line 338, `event_bundle_names`) shares its name with `Base.names`, exported from Base. No `names` is defined in the package, and neither scope calls `Base.names`. Proposal `fields`.

## Roster proposals

- `fn`: 4 sites here (`has_stage`, `_declares`, `declared_at`, `bundle_names`), and 76 word occurrences across `assembly.jl`, `build.jl`, `diagnostics.jl`, `executor.jl`, `sim.jl` and this file. It abbreviates "function": a declaration or stage function passed by value. If the roster refuses it, the proposals are `stage` where a stage is asked for and `declaration` where a declaration is.

## Questions

- `Period`'s constructors bind `T` for the period, which is the spec's own symbol (`T = period(q)`, §10.5) and the field's name, so the rules' `keep:spec` applies. The same file binds `T` as the numeric type parameter (`input_types`, `output_types`, `probe_value`), and the rules say `T` is the numeric type. Which rule wins here?
- `Base.names` is exported but the file never calls it. The brief flags Base functions "the file calls" while the rules forbid any name "reached from Base"; this report follows the rules and flags it.
- `_declares` (line 260) shares its generic with `readers.jl`'s `_declares(label, s, declares, declared)` (lines 292, 298), which builds a violation and has nothing to do with this one. Proposal in `readers.md`: rename the readers pair.
