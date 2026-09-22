# Naming survey — slice D, authoring

Tip `2844584`. Files: `src/assembly.jl`, `src/declare.jl`, `src/leaves.jl`,
`src/tracer.jl`, `src/show.jl`. Functions examined (long form, short form,
inner functions and closures, including `@eval`-generated method families
counted once per distinct call site in source): 143 across the five files
(assembly.jl 61, declare.jl 27, leaves.jl 24, tracer.jl 22, show.jl 9). Date
2026-09-22.

Two blanket notes apply across every file below and are not repeated per row:

- **`T` the activation scalar** (§7.2, §9.4) survives everywhere it denotes
  the scalar a declaration or a leaf walk is evaluated at (`retype`,
  `_accepts`, `flatten_state!`, `_walk`/`_lift`/`_tag`/`_sample`, the tracer's
  own `Type{T}` parameters, `input_types`/`output_types`'s `::Type{T}`, the
  activation keys in `show.jl`'s `_activations_label`). Not tabulated per
  occurrence. Two exceptions where a `T` in scope does **not** carry that
  meaning are called out as their own rows (declare.jl's `Period`
  constructors, show.jl's artifact-type loop).
- **`ci` the component index** survives everywhere it denotes a position in
  `Structure.components` (per the naming rule's own carve-out). Not
  tabulated per occurrence.

## Conventions

### `assembly.jl`

- **`c` the component instance.** Used as a parameter throughout the file
  for "the instance being classified/walked." Per the naming rule this is
  *not* §5.2's `comp` and does not survive on meaning; whether it stays is
  therefore the ordinary span test, decided per function below. Functions
  where it is glance (span ≤ 5, not tabulated): `declarations_found`,
  `_holds_components`, `children`, `_container_fields`, `_check_transparent`,
  `_declared_holding`, `_held_concretely`, `_contract`, `input_faces`,
  `output_faces`, `_walked_faces`. Functions where it outlives the span and
  is proposed for rename appear as rows (`leaf_declarations`, `classify`,
  `_children`).
- **`Group`'s four accessors** (`child_connections`, `input_connections`,
  `output_connections`, `sample_times` at lines 271–274) each take the
  instance as `g::Group`, one-line bodies — glance, not tabulated.

### `declare.jl`

- **`c` the component instance**, same convention as `assembly.jl`. Glance
  (not tabulated): `foreign_declarations`, `has_stage`, `_declares`,
  `declared_at`, `_declares_workspace`. Rename (tabulated below):
  `bundle_names`, `event_bundle_names`.
- **`t::Tier`** is used as a parameter name for the continuous/discrete tier
  in `declared_at`, `bundle_names`, `classify_bundle_field`, `_tier_names`,
  `_declares_workspace`. Per the naming rule's own example, "a `t` that is a
  tier does not survive" — none of these is spec's time `t`. Glance where
  short (`declared_at`, `classify_bundle_field`, `_declares_workspace`,
  `_tier_names`), rename where it outlives the span (`bundle_names`).

### `leaves.jl`

- **`_leaf_names!`'s dispatch family** (lines 71–72, one-liners for
  `P<:Real`/`P<:Enum`) takes no single-letter parameter — `out`/`pre` are
  the value/prefix, `P` a type parameter — nothing to tabulate.
- **`_leaf_values`'s dispatch family** (six methods, lines 248–255, one per
  leaf shape) each take the value as `v`, every body one line — glance
  throughout, not tabulated per method.

### `tracer.jl`

- **The binary/n-ary operand convention.** Every `@eval`-generated method
  for `+, -, *, /, ^, atan, hypot, min, max, copysign, rem, mod` (lines
  53–56), the comparison family `<, <=, ==, isless` (lines 105–110), and
  `Base.muladd` (lines 58–59) take their `Tracer{S}` operands as `a`, `b`
  (`, c` for `muladd`) — one-line bodies, glance throughout, not tabulated.
- **The unary operand convention.** Every generated method for the unary
  list at lines 65–71, the predicate family `iszero, isnan, isfinite, isinf,
  signbit` (111–116), the `round/floor/trunc` integer-arg forms (117–122),
  and `Base.Int`/`Base.Bool` (123–130) take their `Tracer{S}` operand as
  `x` — one-line bodies, glance throughout, not tabulated. `Base.:^(x, n)`
  and `Base.clamp(x, lo, hi)` reuse this `x`; their extra single-letter
  parameter (`^`'s `n`) is tabulated below.

### `show.jl`

- **`io` the stream.** Every `Base.show` method (`Structure` l.60, `Outputs`
  l.94, `Events` l.114, `Schedule` l.135, `Build` l.191, `Deployment` l.234,
  and the generated `MIME"text/plain"` loop l.256–258) takes the stream as
  `io::IO` — the spec's own survivor letter (`io` the stream). Not
  tabulated.

## The table

### `src/assembly.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 27 | `leaf_declarations` | c | untyped, the component instance | param, 27–42 | rename | `component` | |
| 57 | `classify` | c | untyped, the component instance | param, 57–69 | rename | `component` | |
| 75 | `_terminal` | t | `Tuple{String,Symbol}`, a producer terminal | param, one line | glance | | not spec's time `t`; a (path, port) pair |
| 79 | `_holds_components` | v | untyped, one field's value | do-block, 80–82 | glance | | fits the do-block-body exception |
| 82 | `_holds_components` | e | untyped, anon-fn arg | one line | glance | | |
| 106 | `children` | c | untyped, the component instance | param, one line | glance | | |
| 115 | `_children` | c | untyped, the component instance | param, 115–187 | rename | `component` | |
| 139 | `_children` | v | untyped, a field's value (child / container / inert data) | 139–186 | rename | `field_value` | |
| 145 | `_children` | n | `Int`, count of container elements that are components | 145–153 | rename | `component_count` | |
| 163 | `_children` | k | untyped, the container element's key | 163–181 | rename | `key` | |
| 164 | `_children` | p | `String`, the child's provenance label | 164–183 | rename | `label` | close to `prov` (the accumulator); kept distinct |
| 195 | `_is_container` | v | untyped | param, one line | glance | | |
| 195 | `_is_container` | e | untyped, anon-fn arg | one line | glance | | |
| 198 | `_container_fields` | c | untyped, the component instance | param, one line | glance | | |
| 198 | `_container_fields` | n | `Symbol`, comprehension var, a field name | one line | glance | | |
| 201 | `_bears_component` | v | untyped | param, one line | glance | | |
| 202 | `_bears_component` | e | untyped, anon-fn arg | one line | glance | | |
| 206 | `_check_transparent` | c | untyped, the component instance | param, 206–211 | glance | | borderline, exactly 5 |
| 220 | `_check_child_names` | i | `Int`, outer index | 220–224 | glance | | |
| 220 | `_check_child_names` | j | `Int`, inner index | 220–224 | glance | | |
| 268 | `_entries` | p | `Pair`, one entry | param, one line | glance | | |
| 269 | `_entries` | t | untyped, a tuple already in entries form | param, one line | glance | | not spec's time `t` |
| 307 | `resolve_terminal` (entry-taking) | r | untyped, `_one_level`'s match result | 307–309 | glance | | |
| 323 | `_one_level` | j | untyped, the matched child's index | 323–333 | rename | `idx` | |
| 330 | `_one_level` | k | `String`, comprehension var, a candidate name | one line | glance | | |
| 347 | `_declared_holding` | c | untyped, the component instance | param, one line | glance | | |
| 349 | `_held_concretely` | c | untyped, the component instance | param, one line | glance | | |
| 367 | `resolve_authored` | i | `Int`, position in `segs` | 367–405 | rename | `pos` | mutable across the whole `while` loop |
| 386 | `resolve_authored` | j | untyped, the matched child's index | 386–396 | rename | `idx` | |
| 418 | `authored_chain` | i | `Int`, position in `segs` | 421–431 | rename | `pos` | consistent with `resolve_authored` |
| 424 | `authored_chain` | j | untyped, the matched child's index | 424–428 | glance | | shorter-lived than `resolve_authored`'s `j` |
| 453 | `resolve` (asm, path) | r | untyped, `_one_level`'s match result | 459–462 | glance | | |
| 474 | `resolve_terminal` (asm, path) | r | untyped, `resolve_terminal`'s match result | 476–478 | glance | | |
| 485 | `_contract` | c | untyped, the component instance | param, one line | glance | | |
| 498 | `input_faces` | c | untyped, the component instance | param, 498–500 | glance | | |
| 499 | `input_faces` | k | `Symbol`, comprehension var, a face key | one line | glance | | |
| 511 | `output_faces` | c | untyped, the component instance | param, 511–513 | glance | | |
| 512 | `output_faces` | k | `Symbol`, comprehension var, a port key | one line | glance | | |
| 523 | `_walked_faces` | c | untyped, the component instance | param, 523–526 | glance | | |
| 592 | `_labelled` | n | untyped, the face name | param, one line | glance | | |
| 608 | `_passthrough_faces` | g | `Symbol`, comprehension var, a given-selector name | one line | glance | | |
| 609 | `_passthrough_faces` | n | untyped, comprehension var, a candidate face name | one line | glance | | |
| 614 | `_passthrough_faces` | n | untyped, comprehension var, an `only`-listed face name | one line | glance | | |
| 616 | `_passthrough_faces` | n | untyped, comprehension var, an `except`-listed face name | one line | glance | | |
| 624 | `_passthrough_faces` | n | untyped, comprehension var, an `except`-listed face name (warning path) | one line | glance | | |
| 644 | `resolve_source` | r | untyped, `resolve_terminal`'s match result | 644–646 | glance | | |
| 650 | `resolve_source` | i | untyped, matched `out_faces` index | 650–651 | glance | | |
| 667 | `resolve_dest` | r | untyped, `resolve_terminal`'s match result | 667–669 | glance | | |
| 673 | `resolve_dest` | i | untyped, matched `routes` index | 673–674 | glance | | |
| 684 | `_endpoints` | p | `AbstractString`, one endpoint | param, one line | glance | | |
| 690 | `_fanout` | p | untyped, comprehension var, one endpoint | one line | glance | | |
| 858 | `_check_sample_times` | k | `Symbol`, the rate declaration's key | 864–878 | rename | `key` | loop var, destructured from `pairs(st)` |
| 864 | `_check_sample_times` | v | untyped, the `Relative`/`Absolute` wrapper value | 864–874 | rename | `entry` | |
| 878 | `_check_sample_times` | p | untyped, comprehension var, one existing child pair | one line | glance | | |
| 893 | `_rate_entry` | k | `Symbol`, loop var (first `pairs` loop) | 893–894 | glance | | |
| 893 | `_rate_entry` | v | untyped, loop var (first `pairs` loop) | 893–894 | glance | | |
| 896 | `_rate_entry` | k | `Symbol`, loop var (second `pairs` loop) | 896–897 | glance | | |
| 896 | `_rate_entry` | v | untyped, loop var (second `pairs` loop) | 896–897 | glance | | |
| 917 | `_child_scope` | k | `Symbol`, the rate entry's key | 917–925 | rename | `key` | |
| 917 | `_child_scope` | v | untyped, the rate entry's wrapper value | 917–925 | rename | `entry` | |
| 923 | `_child_scope` | a | untyped, the matched anchor index | 923–928 | glance | | borderline, exactly 5 |
| 1033 | `_walk!` | t | `Union{Nothing,Tier}`, the classified tier (PRIMITIVE branch) | 1056/1060–1073 | rename | `tier` | not spec's time `t` |
| 1033 | `_walk!` | t | `Tier`, a child's returned tier (assembly branch) | 1095–1098 | glance | | second, mutually exclusive binding of the same name |
| 1184 | `_check_face_names` | n | `String`, loop var, one face name | 1187–1189 | glance | | |
| 1184 | `_check_face_names` | n | `String`, comprehension var, second binding | one line | glance | | |
| 1205 | `_check_root_faces` | n | `String`, comprehension var, an input face name | one line | glance | | |

### `src/declare.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 128 | `Period` (ctor 1) | T | `Union{Integer,Rational{<:Integer}}`, a period-length argument | param, one line | glance | | not the activation-scalar `T`; kept only by span |
| 129 | `Period` (ctor 2, float refusal) | T | `AbstractFloat`, same role | param, one line | glance | | same note |
| 133 | `Hz` | f | `Union{Integer,Rational{<:Integer}}`, the frequency value | param, one line | glance | | |
| 134 | `Hz` (float refusal) | f | `AbstractFloat`, same role | param, one line | glance | | |
| 137 | `period` | q | `Period`, the quantity instance | param, one line | survivor(q) | | spec's own `q` for a quantity value, §10.5 (spec.md:4562) |
| 148 | `Relative` (outer ctor) | K | `Integer`, the multiplier | param, one line | glance | | spec's own `K` (Appendix B); see Questions |
| 158 | `Absolute` (ctor 1) | q | `Period`, the quantity instance | param, one line | survivor(q) | | as above |
| 158 | `Absolute` (ctor 1) | τ | `Union{Integer,Rational{<:Integer}}`, the phase offset | param, one line | survivor(τ) | | spec's own `τ`, §10.5/Appendix B (spec.md:3072, 4557) |
| 159 | `Absolute` (ctor 2, float refusal) | τ | `AbstractFloat`, same role | param, one line | survivor(τ) | | |
| 161 | `Absolute` (ctor 3, refusal) | q | `Real`, the mis-typed quantity argument | param, one line | survivor(q) | | |
| 206 | `_holding` | σ | `Bool` | param, one line | survivor(σ) | | spec's guard return, §2.1/§5.2 (spec.md:592) |
| 207 | `_holding` | σ | untyped | param, one line | survivor(σ) | | |
| 246 | `foreign_declarations` | M | untyped, the component's parent module | 247–249 | glance | | |
| 246 | `foreign_declarations` | n | `Symbol`, comprehension var, a declaration-family name | one line | glance | | |
| 277 | `declared_at` | t | `Tier` | param, one line | glance | | not spec's time `t` |
| 305 | `bundle_names` | c | untyped, the component instance | param, 305–322 | rename | `component` | |
| 305 | `bundle_names` | t | `Tier` | param, 305–324 | rename | `tier` | not spec's time `t` |
| 337 | `event_bundle_names` | c | untyped, the component instance | param, 337–343 | rename | `component` | |
| 361 | `_tier_names` | v | untyped, comprehension var, one bundle-field name | one line | glance | | |
| 369 | `classify_bundle_field` | t | `Tier` | param, 369–372 | glance | | not spec's time `t` |

### `src/leaves.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 74 | `_leaf_names!` (StaticArray arm) | i | `Int`, loop index | 75–76 | glance | | |
| 81 | `_leaf_names!` (struct arm) | n | `Symbol`, loop var, a field name | 83–84 | glance | | |
| 97 | `_mutable_position` | n | `Symbol`, loop var, a field name | 103–104 | glance | | |
| 97 | `_mutable_position` | r | untyped, the recursive result | 104–105 | glance | | |
| 114 | `_reconstruct_expr` (StaticArray arm) | b | `Int`, running base offset | 117–122 | glance | | borderline, exactly 5 |
| 114 | `_reconstruct_expr` (StaticArray arm) | e | `Expr`, one element's reconstruct expr | 119–120 | glance | | |
| 114 | `_reconstruct_expr` (struct arm) | b | `Int`, running base offset | 127–132 | glance | | borderline, exactly 5 |
| 114 | `_reconstruct_expr` (struct arm) | e | `Expr`, one field's reconstruct expr | 129–130 | glance | | |
| 140 | `_flatten_expr` | v | untyped, the expression denoting the value being flattened | param, 140–155 | rename | `expr` | |
| 140 | `_flatten_expr` (StaticArray arm) | b | `Int`, running base offset | 143–148 | glance | | borderline |
| 140 | `_flatten_expr` (StaticArray arm) | i | `Int`, loop index | 144–145 | glance | | |
| 140 | `_flatten_expr` (struct arm) | b | `Int`, running base offset | 153–158 | glance | | borderline |
| 140 | `_flatten_expr` (struct arm) | i | `Int`, loop index (from `enumerate`) | 154–155 | glance | | |
| 170 | `_mreconstruct_expr` | k | `Int`, index into `Ls`/`bases` | 175–177 | glance | | |
| 185 | `_mflatten_expr` | v | untyped, the expression denoting the value | param, 185–197 | rename | `expr` | same role as `_flatten_expr`'s `v` |
| 185 | `_mflatten_expr` (StaticArray arm) | i | `Int`, loop index | 188–189 | glance | | |
| 185 | `_mflatten_expr` (atom arm) | k | `Int`, index into `Ls`/`bases` | 192–194 | glance | | |
| 185 | `_mflatten_expr` (struct arm) | i | `Int`, loop index (from `enumerate`) | 196–197 | glance | | |
| 232 | `retype` | p | untyped, comprehension var, one of `P`'s parameters | one line | glance | | |
| 243 | `retype_value` | v | untyped, the value being retyped | param, 243–245 | glance | | |
| 243 | `retype_value` | P | untyped, `retype(T, typeof(v))` | 244–245 | glance | | |
| 243 | `retype_value` | l | untyped, one leaf value, comprehension var | one line | glance | | |
| 277 | `_accepts` | p | untyped, comprehension var, one of `P`'s parameters | one line | glance | | |
| 277 | `_accepts` | v | untyped, comprehension var, one of `V`'s parameters | one line | glance | | |
| 311 | `flatten!` (generated) | v | `P`, the value to flatten | param, unused in generator body | glance | | dispatch-only; the generated code references it by its quoted symbol, not this binding |
| 330 | `flatten_state!` (generated) | v | `NamedTuple{Vs}`, the caller's field-value bundle | param, 330–347 | rename | `assignment` | |
| 330 | `flatten_state!` (generated) | k | `Symbol`, loop var, the field being checked | 340–347 | rename | `fieldname` | `field` was considered but echoes the `field = ` keyword built from it |
| 330 | `flatten_state!` (generated) | P | `Type`, the field's declared type | 341–346 | rename | `decl_type` | `declared` considered, echoes the `declared = ` keyword |
| 330 | `flatten_state!` (generated) | V | `Type`, the field's observed type | 341–346 | rename | `obs_type` | `observed` considered, same reason |

### `src/tracer.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 57 | `Base.:^` | n | `Integer`, the exponent | param, one line | glance | | |
| 62 | `Base.ifelse` | b | `Bool`, the branch condition | param, one line | glance | | |
| 62 | `Base.ifelse` | x | `Tracer{S}`, the true-branch value | param, one line | glance | | |
| 62 | `Base.ifelse` | y | `Tracer{S}`, the false-branch value | param, one line | glance | | |
| 84 | `Base.hypot` | x | `Tracer{S}` | param, 84–85 | glance | | |
| 84 | `Base.hypot` | y | `Tracer{S}` | param, 84–85 | glance | | |
| 84 | `Base.hypot` | z | `Tracer{S}...`, vararg | param, 84–85 | glance | | |
| 84 | `Base.hypot` | t | untyped, the operand tuple `(x, y, z...)` | 85–86 | glance | | not spec's time `t` |
| 84 | `Base.hypot` | v | untyped, anon-fn arg, one operand (×2, `.val`/`.deps`) | one line | glance | | |
| 89 | `_norm` | v | `AbstractArray`/untyped | param, one line | glance | | |
| 89 | `_norm` | p | `Real`, the norm order | param, one line | glance | | |
| 89 | `_norm` | x | untyped, anon-fn arg, one array entry | one line | glance | | not spec's state `x` |
| 91 | `LinearAlgebra.norm` (AbstractArray) | v | `AbstractArray{<:Tracer}` | param, 91–92 | glance | | |
| 91 | `LinearAlgebra.norm` (AbstractArray) | p | `Real` | param, 91–92 | glance | | |
| 95 | `LinearAlgebra.norm` (StaticArray) | v | `StaticArray{S,<:Tracer}` | param, 95–96 | glance | | |
| 95 | `LinearAlgebra.norm` (StaticArray) | p | `Real` | param, 95–96 | glance | | |
| 103 | `_decide` | S | `Bool`, whether the global tracer mode is active | param, one line | glance | | |
| 139 | `_walk` | v | untyped, the value | param, one line | glance | | |
| 139 | `_walk` | f | untyped, the per-leaf conversion function | param, one line | glance | | |
| 139 | `_walk` | l | untyped, comprehension var, one leaf | one line | glance | | |
| 143 | `_lift` | v | untyped, the value | param, one line | glance | | |
| 143 | `_lift` | l | untyped, anon-fn arg, one leaf | one line | glance | | |
| 150 | `_tag` | v | untyped, the value | param, 150–151 | glance | | |
| 150 | `_tag` | l | untyped, anon-fn arg, one leaf | one line | glance | | |
| 159 | `_sample` | v | untyped, the value | param, 159–160 | glance | | |
| 159 | `_sample` | l | untyped, anon-fn arg, one leaf | one line | glance | | |
| 163 | `_depset` | v | untyped, the value | param, 163–165 | glance | | |
| 163 | `_depset` | s | `UInt64`, the accumulated tag set | 164–168 | glance | | not spec's state `s`; a bitmask accumulator |
| 163 | `_depset` | l | untyped, loop var, one leaf | 165–166 | glance | | |
| 183 | `_trace_direct` | c | untyped, the component instance | 188–196 | rename | `component` | destructured local, not a parameter |
| 183 | `_trace_direct` | u | `NamedTuple`, the seeded input bundle | 189–196 | survivor(u) | | §5.2 bundle table (spec.md:581, 586) |
| 183 | `_trace_direct` | d | untyped, `Decls`, possibly resampled | 192–196 | glance | | not spec's `D`; a `Decls` record |
| 183 | `_trace_direct` | q | `Symbol`, comprehension var, an out-port key | one line | glance | | |
| 211 | `_trace_sampled` | q | `Symbol`, comprehension var | one line | glance | | |
| 211 | `_trace_sampled` | r | untyped, one draw's route map | 220–223 | glance | | |
| 211 | `_trace_sampled` | q | `Symbol`, loop var | 222–223 | glance | | second, separate binding |
| 238 | `_seed` | p | untyped, anon-fn arg, one connection pair | one line | glance | | |
| 238 | `_seed` | k | `Int`, the root-input index | 244–245 | glance | | |
| 238 | `_seed` | j | `Union{Int,Nothing}`, the in-cluster face index | 250–252 | glance | | |
| 272 | `_classify` | d | `AlgebraicCycle`, the cycle being classified | param, whole function | rename | `cycle` | |
| 272 | `_classify` | i | `Int`, position of the member in `scc` | 292–327 | rename | `member_idx` | first binding |
| 272 | `_classify` | f | `Symbol`, comprehension var, an in-cluster face | 294–295 | glance | | |
| 272 | `_classify` | e | untyped, anon-fn arg, one edge tuple | one line | glance | | first binding |
| 272 | `_classify` | q | `Symbol`, comprehension var, an out-port | 296–297 | glance | | |
| 272 | `_classify` | e | untyped, anon-fn arg, one edge tuple | one line | glance | | second, nested binding |
| 272 | `_classify` | f | `Symbol`, loop var | 309–310 | glance | | second binding |
| 272 | `_classify` | q | `Symbol`, loop var | 309–310 | glance | | second binding |
| 272 | `_classify` | e | `Exception`, catch var | 317–318 | glance | | third binding |
| 272 | `_classify` | a | `Int`, `enumerate` index | 323–324 | glance | | |
| 272 | `_classify` | f | `Symbol`, loop var | 323–327 | glance | | third binding |
| 272 | `_classify` | b | `Int`, `enumerate` index | 323–324 | glance | | |
| 272 | `_classify` | q | `Symbol`, loop var | 323–327 | glance | | third binding |
| 272 | `_classify` | k | untyped, closure param, a node key | one line | glance | | `id!`'s own parameter |
| 272 | `_classify` | i | `Int`, loop var | 338–339 | glance | | second, separate binding |
| 272 | `_classify` | f | `Symbol`, loop var | 338–339 | glance | | fourth binding |
| 272 | `_classify` | q | `Symbol`, loop var | 338–339 | glance | | fourth binding |
| 272 | `_classify` | i | `Int`, loop var | 341–344 | glance | | third, separate binding |
| 272 | `_classify` | j | `Union{Int,Nothing}`, the matched `scc` position | 343–344 | glance | | |
| 272 | `_classify` | m | `String`, comprehension var, a cluster member's name | one line | glance | | not spec's mode-store `m` |
| 272 | `_classify` | t | `Symbol`, comprehension var, a trace mode | one line | glance | | not spec's time `t`; `:global`/`:sampled`/`:structural` |
| 272 | `_classify` | e | `Exception`, catch var | 351–352 | glance | | fourth binding |
| 371 | `_has_cycle` (`grey!`) | v | `Int`, the graph vertex being visited | param, 373–379 | rename | `vertex` | |
| 371 | `_has_cycle` (`grey!`) | w | `Int`, a neighboring vertex | 375–377 | glance | | |
| 371 | `_has_cycle` | v | `Int`, anon-fn arg, separate binding | one line | glance | | |

### `src/show.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 15 | `_anchor_name` | c | `Char`, comprehension var, one digit of the anchor index | one line | glance | | |
| 18 | `_count` | n | `Int`, the count | param, one line | glance | | |
| 38 | `_table` | j | `Int`, comprehension var, a column index | one line | glance | | |
| 66 | `_lines(::Structure)` | k | `Int`, comprehension-destructure var, an anchor's 1-based index | 86–87 | glance | | |
| 146 | `_lines(::Schedule)` | L | `Int`, the hyperperiod length in base ticks | 165–176 | rename | `hyperperiod` | no dedicated spec symbol; `lcm(Dᵢ)` is written out in spec.md:3335 |
| 146 | `_lines(::Schedule)` | k | `Int`, loop var, a ruler tick | 170–171 | glance | | |
| 146 | `_lines(::Schedule)` | k | `Int`, comprehension var, a chart tick | one line | glance | | second, separate binding |
| 256 | (module-scope loop generating the `MIME"text/plain"` methods) | T | `DataType`, one of the six artifact types | one line | glance | | not the activation-scalar `T`; ranges over `Structure, Outputs, Events, Schedule, Build, Deployment` |
| 257 | generated `show(io, ::MIME"text/plain", x::$T)` | x | untyped, the artifact instance being printed | param, one line | glance | | not spec's state `x` |

## Collisions

None found against a module-level function or constant: `component`,
`field_value`, `component_count`, `key`, `label`, `idx`, `pos`, `entry`,
`tier`, `expr`, `assignment`, `fieldname`, `decl_type`, `obs_type`, `cycle`,
`member_idx`, `vertex`, `hyperperiod` — none of these names a top-level
binding anywhere in `src/`, checked by grep across the whole tree. Two
proposals were adjusted to avoid an *echo* against a keyword argument built
from the same local inside the same call (not a true Julia collision, but a
readability near-miss the naming rule's step 4 spirit covers): `leaves.jl`'s
`flatten_state!` renames `k`→`fieldname` rather than `field` (the call
builds `field = $(QuoteNode(k))`), and its `P`/`V`→`decl_type`/`obs_type`
rather than `declared`/`observed` (the same call builds
`declared = $P, observed = $V`). No two proposals within one function
collide with each other.

## Neighbours

- `bn` — `bundle_names`'s result, tracer.jl:194 (`_trace_direct`). Matches
  the brief's own example list verbatim; flagged for visibility only.
- `pi` — a local holding a producer's component index, shadowing
  `Base.pi`, at tracer.jl:247 (`_seed`) and tracer.jl:341/343 (`_classify`,
  destructured as `(pi, pport, face)`). Two letters, out of scope by length,
  but worth a look in the sweep since the shadow is real.
- `dc`, `bn`, `ws`, `y2` (tracer.jl `_trace_direct`) — short but not
  single-letter; left as encountered.
- `st`, `dT`, `dc` (assembly.jl / tracer.jl) — likewise short multi-letter
  locals for "sample-times value" / "declarations at T" / "this member's
  Decls", met while tabulating but not proposed.

## Questions

- **Is `K` (declare.jl:148, `Relative`'s multiplier) a survivor?** It is the
  spec's own letter in the Appendix B / §10.5 table (`Relative(K, Φ = 0)`),
  but the naming rule's survivor list names only `D` and `Φ` as "the
  schedule's symbols," and `K`/`Φ` (lowercase `φ` in the `Relative` struct
  field) belong to the *rate declaration*, one step before the bound
  schedule. Classified `glance` here since the constructor is one line
  regardless, but the sweep should decide whether `K` gets the same
  survivor status as `D`/`Φ` for consistency.
- **`q` and `τ` classified survivor** on the strength of spec.md:4557–4562
  and :3072 using those exact letters for `Absolute(q, τ = 0)`. Flagging
  in case the sweep wants a narrower reading of "the spec's own letter"
  that excludes Appendix B's declaration-level table and reserves survivor
  status for §5.2's bundle table and the bound schedule alone.
- **`declare.jl`'s `Period` struct field is also named `T`** (a rational
  period length), distinct from the activation-scalar `T` and out of scope
  as a struct field name — noted here only because a reader tabulating the
  constructors could otherwise mistake the two for the same letter's two
  uses; no row was needed since the constructor argument is glance and the
  field itself is out of scope.

## Coverage

All function definitions in the five files were read and tabulated,
including inner functions, closures, `do`-blocks, and `@eval`-generated
method families (grouped under Conventions where the same one-line pattern
repeats). Nothing was skipped for lack of time. Type-parameter-only
occurrences (`where {P}`, `::Type{P}` with no further named binding) and
struct/`@NamedTuple` field names (`Timing`'s `m`/`c`, `Relative`'s `K`/`φ`,
`Absolute`/`Period`'s `T`/`τ`, `RateLink`'s `scope`/`key`/`entry`) were
excluded per the brief's scope, not overlooked.

## The `_at`/`_at_path` fold (`pending.md:50–51`)

`assembly.jl:72`:
```julia
_at(path::String) = isempty(path) ? "the root component" : "`$path`"
```
`diagnostics.jl:69`:
```julia
_at_path(p::AbstractString) = isempty(p) ? "the root component" : "`$p`"
```
The two bodies are identical modulo the parameter's name and its type
annotation (`String` vs. `AbstractString`, and every call site passes a
`String`) — same branch, same two literal-string shapes. Confirmed the same
function twice, as `pending.md` states.

**Callers of `_at(`** — 6, all inside `assembly.jl` (grep also matches
`declared_at(`, `path_at(`, `_walk_at(`, `_frame_at(`, `_cells_at(`
elsewhere in `src/`, none of which is this function; excluded):
- assembly.jl:300, :321 — default value of the `owner::String` keyword
  parameter in `resolve_terminal`/`_one_level`.
- assembly.jl:378, :391, :400 — `owner = _at(at)` inside `resolve_authored`'s
  `PathResolution` diagnostics.
- assembly.jl:1163 — inside `_entry`'s message-building string
  interpolation.

**Callers of `_at_path(`** — 55, all inside `diagnostics.jl`, exclusively in
`message`/rendering methods for the framework's `Diagnostic` kinds (no
caller outside `diagnostics.jl`): lines 247, 284, 318, 332, 398, 421, 499,
515, 529, 542, 555, 594, 597, 610, 612, 623, 626, 641, 695, 698, 708, 711,
746, 750, 755, 768, 801, 805, 808, 821, 835, 858, 967, 1083, 1087, 1093,
1124, 1125, 1228, 1485, 1487, 1520, 1521, 1528, 1535, 1538, 1543, 1552,
1635, 1642, 1646, 1907, 1909, 1931, 1935.
