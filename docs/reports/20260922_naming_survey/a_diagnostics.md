# Naming survey — slice A, diagnostics

Tip `2844584` (identical to `src/` at `6b76a9a`). File: `src/diagnostics.jl`
(1989 lines). Function definitions examined: 182 (≈153 per-kind
`severity`/`path`/`message`/helper methods across 69 `Diagnostic` subtypes,
plus 29 file-level helpers, carriers and `showerror` methods). Date:
2026-09-22.

Struct field names (every `Base.@kwdef struct ... <: Diagnostic` block, plus
`CursorFrame`, `StepError`, `GridEntry`, `GridReport`, `DiagnosticError`) are
out of scope per the brief and are not tabulated.

## Conventions

**Convention 1 — the diagnostic instance is `d`.** The abstract type's own
docstring (`Diagnostic`, lines 19–22) fixes the contract: "Every kind is an
immutable struct under it, with three methods: `severity(d)`, `path(d)` and
`message(d)`." Every one of the ~69 kinds' `severity(d::Kind)`,
`path(d::Kind)` and `message(d::Kind)` methods follows it (lines 282–1989),
together with the private per-kind helpers a `message` body calls under the
same instance — `_cf_what`/`_pin` (`ConformanceFailure`), `_cleaf`/`_ctail`
(`ConditionResolution`/`DuplicateConditionLeaf`), `_prov` (`ChildNameCollision`,
shares `d` with a second param, see below), `_rates_entry`
(`RatesViolation`), `_tapviol` (`TapResolution`, shares `d` with a second
param), `_replay_subject`/`_replay_deployment` (`ReplayHeaderMismatch`),
`_trim_bad` (`TrimProblemInvalid`) — plus `logline(d::Diagnostic)` (149),
`_warn!(d::Diagnostic)` (166) and the `DiagnosticError(d::Diagnostic, ws)`
constructor (94). Proposal: **`diagnostic`**. See Collisions: this shadows
the module-level accessor `diagnostic(e)` (100, 220), never called from
inside any of these bodies.

**Convention 2 — the carrier/exception instance is `e`.** Every accessor
over the two exception types names its argument `e`:
`diagnostic(e::DiagnosticError{<:Diagnostic})` (100),
`diagnostics(e::DiagnosticError{Vector{Diagnostic}})` (103),
`kinds(e::DiagnosticError{Vector{Diagnostic}})` (106),
`diagnostic(e::StepError{<:Diagnostic})` (220), and the four
`Base.showerror` methods below. Proposal: **`err`**.

**Convention 3 — `io` is the output stream (spec survivor).** Every
function that renders to a stream keeps `io`:
`_show_warnings(io::IO, ws::Vector{Diagnostic})` (121),
`Base.showerror(io::IO, e::DiagnosticError{<:Diagnostic})` (128),
`Base.showerror(io::IO, e::DiagnosticError{Vector{Diagnostic}})` (133),
`Base.showerror(io::IO, e::StepError)` (243),
`Base.showerror(io::IO, e::InternalInvariant)` (297).

## The table

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 30 | `_typename(x)` | x | untyped — the value whose type is named | param | rename | value | |
| 32 | `_typename(T::Type)` | T | the type to spell (not the activation scalar) | param | rename | type | |
| 37 | `_typename(v::TypeVar)` | v | the declared generic's type variable | param | rename | typevar | |
| 42 | `_typespell(T::Type)` | T | the type to spell, shape included | param | rename | type | |
| 45 | `_typespell` | p | a type parameter of T, or its bare value | 45–45 | glance | | one-line generator |
| 69 | `_at_path(p::AbstractString)` | p | the component path, "" for root | param | rename | path | shadows `path(d)`, not called here — see Collisions |
| 70 | `_namelist(ns)` | n | one name in the list | 70–70 | glance | | one-line generator |
| 73 | `_symtuple(ns)` | n | one name in the tuple | 73–73 | glance | | one-line generator |
| 112 | `_groups` | d | one diagnostic in the collection | 112–113 | glance | | for-loop var |
| 113 | `_groups` | T | the diagnostic's own type (not the scalar) | 113–114 | glance | | |
| 116 | `_groups` | d | one diagnostic, filtered | 116–116 | glance | | anonymous-fn arg |
| 116 | `_groups` | T | one kind's type, in `order` | 116–116 | glance | | comprehension var |
| 122 | `_show_warnings` | d | one warning | 122–123 | glance | | for-loop var |
| 137 | `Base.showerror` (Vector) | g | one path-sorted group | 137–137 | glance | | for-loop var |
| 137 | `Base.showerror` (Vector) | d | one diagnostic in the group | 137–138 | glance | | for-loop var |
| 200 | `Base.:(==)(a::CursorFrame, b::CursorFrame)` | a | the frame compared | param | rename | frame | |
| 200 | `Base.:(==)(a::CursorFrame, b::CursorFrame)` | b | the other frame compared | param | rename | other | |
| 398 | `message(d::AbstractAtRoot)` | p | a consuming leaf's path | 398–398 | glance | | comprehension var |
| 398 | `message(d::AbstractAtRoot)` | P | that leaf's declared entry type | 398–398 | glance | | comprehension var |
| 421 | `message(d::RootInputTypeConflict)` | p | a consuming component's path | 421–421 | glance | | comprehension var |
| 421 | `message(d::RootInputTypeConflict)` | P | that component's declared entry type | 421–421 | glance | | comprehension var |
| 743 | `_prov(d, i)` | i | which provenance entry, 1 or 2 | param | rename | index | `d` under Convention 1 |
| 887 | `_wirelist(ws)` | p | a wire's producer terminal | 887–887 | glance | | comprehension var |
| 887 | `_wirelist(ws)` | c | a wire's consumer terminal | 887–887 | glance | | comprehension var |
| 888 | `_hop((m, f, q))` | m | the cluster member | param | rename | member | |
| 888 | `_hop((m, f, q))` | f | the unrouted input face | param | rename | face | |
| 888 | `_hop((m, f, q))` | q | the output port that fails to route it | param | rename | port | |
| 891 | `_modes(traced)` | m | one member's path, traced | 891–892 | glance | | comprehension var |
| 891 | `_modes(traced)` | t | that member's trace mode | 891–892 | glance | | comprehension var |
| 894 | `_modes(traced)` | t | a member's trace mode, tested for `:global` | 894–894 | glance | | comprehension var |
| 899 | `_cycle_hint(dead)` | m | the dead member being hinted at | 899–902 | glance | | comprehension var (outer) |
| 899 | `_cycle_hint(dead)` | f | an unrouted face at that member | 899–899 | glance | | comprehension var (inner) |
| 899 | `_cycle_hint(dead)` | mm | a dead-hop's member, matched against `m` | 899–899 | glance | | comprehension var |
| 906 | `message(d::AlgebraicCycle)` | s | the "real" cycle's rendered sentence | 910–914 | glance | | mutated local |
| 906 | `message(d::AlgebraicCycle)` | h | one dead hop, appended to `s` | 911–912 | glance | | for-loop var |
| 906 | `message(d::AlgebraicCycle)` | h | one dead hop, in the artificial-cycle hop list | 917–919 | glance | | comprehension var |
| 931 | `message(d::ProducedByTwoStages)` | p | one doubly-produced port | 931–931 | glance | | comprehension var |
| 999 | `_cf_expect(s::Symbol)` | s | the shape `message` expects the return to fit | param | rename | shape | |
| 1007 | `_cf_section(s::Symbol)` | s | the shape, to pick the section tag | param | rename | shape | |
| 1077 | `_bundle_declaration(f::Symbol)` | f | the bundle field that would have admitted it | param | rename | field | |
| 1193 | `_stop_site(s::Symbol)` | s | the advance (`run!`/`replay!`/`step!`) that bound `stop_on` | param | rename | site | |
| 1259 | `_dep_constraint(p::Symbol)` | p | the deployment parameter at fault | param | rename | parameter | |
| 1267 | `_dep_section(p::Symbol)` | p | the deployment parameter at fault | param | rename | parameter | |
| 1282 | `_sup(n::Int)` | n | the prime's power, to superscript | param | rename | power | |
| 1282 | `_sup(n::Int)` | c | one digit of the power | 1282–1282 | glance | | comprehension var |
| 1287 | `_grid_block(g::Union{Nothing,GridReport})` | g | the grid attribution to render | param | rename | grid | 22-line body, well past one glance |
| 1289 | `_grid_block` | e | one pool entry, for its label | 1289–1289 | glance | | comprehension var |
| 1290 | `_grid_block` | e | one pool entry, for its kind/value | 1290–1290 | glance | | comprehension var |
| 1291 | `_grid_block` | e | one pool entry, for its refinement factor | 1291–1291 | glance | | comprehension var |
| 1294 | `_grid_block` | i | the pool row index | 1294–1295 | glance | | for-loop var |
| 1294 | `_grid_block` | e | the pool entry being rendered | 1294–1297 | glance | | for-loop var |
| 1301 | `_grid_block` | p | one prime-power record, for its label | 1301–1301 | glance | | comprehension var |
| 1303 | `_grid_block` | i | the prime row index | 1303–1304 | glance | | for-loop var |
| 1303 | `_grid_block` | p | the prime-power record being rendered | 1303–1305 | glance | | for-loop var |
| 1305 | `_grid_block` | j | a supplier index into `g.pool` | 1305–1305 | glance | | comprehension var |
| 1523 | `_role_word(r)` | r | the role a condition leaf plays | param | rename | role | |
| 1622 | `_tap_noun(s)` | s | which declaration kind (`:state_field`/`:output_port`) | param | rename | declares | |
| 1674 | `_trim_shape(f::Symbol)` | f | the `TrimProblem` field at fault | param | rename | field | |
| 1680 | `_trim_floats(f::Symbol)` | f | the `TrimProblem` field at fault | param | rename | field | |
| 1683 | `_trim_verb(f::Symbol)` | f | the `TrimProblem` field at fault | param | rename | field | |
| 1684 | `_trim_bad(d)` | k | one bad field's name | 1684–1684 | glance | | comprehension var; `d` under Convention 1 |
| 1684 | `_trim_bad(d)` | v | that field's observed type | 1684–1684 | glance | | comprehension var |
| 1721 | `message(d::TrimCommitEvents)` | p | a fired handler's component path | 1721–1721 | glance | | comprehension var |
| 1721 | `message(d::TrimCommitEvents)` | n | that handler's event name | 1721–1721 | glance | | comprehension var |
| 1732 | `message(d::TrimCommitResiduals)` | k | a residual's name | 1732–1732 | glance | | comprehension var |
| 1732 | `message(d::TrimCommitResiduals)` | v | that residual's committed value | 1732–1732 | glance | | comprehension var |
| 1732 | `message(d::TrimCommitResiduals)` | t | that residual's tolerance (not the spec's time) | 1732–1732 | glance | | comprehension var |
| 1744 | `_drift_position(P::Tuple)` | P | the tree position tuple | param | rename | position | |
| 1744 | `_drift_position` | s | one path segment, symbol or index | 1744–1744 | glance | | comprehension var |
| 1881 | `message(d::NotAttached)` | r | one rostered device id | 1881–1881 | glance | | comprehension var |
| 1909 | `_replay_paths(ps)` | p | one unanchored/schedule path | 1909–1909 | glance | | comprehension var |

Two `survivor(t)` rows, not tabulated above with the rest since they need no
proposal: `_seconds(t::Real)` (182) and `_seconds(t::ForwardDiff.Dual)` (183)
— `t` is the clock/snapshot time being read down to `Float64` seconds,
§13.4's own `t`.

## Collisions

- `_at_path(p::AbstractString)` (69): proposing `path` shadows the
  module-level accessor `path(d)` defined repeatedly in this same file. Not
  a functional collision under the brief's own test — `_at_path`'s body
  never calls `path(...)` — but it is a same-file, same-name accessor vs.
  local shadow the sweep should see before deciding. No alternative
  proposed; `path` is the accurate role name and the shadow is inert.
- Convention 1's proposal `diagnostic` shadows the module-level accessor
  `diagnostic(e::DiagnosticError{<:Diagnostic})` / `diagnostic(e::StepError)`
  (100, 220) — a different function, on a different argument, never called
  from inside any `severity(d::Kind)`/`path(d::Kind)`/`message(d::Kind)`
  body. Flagged for the sweep's brief to decide; `occurrence` (the file's
  own word for a diagnostic value, line 8) was considered as a
  collision-free alternative and rejected here only because `diagnostic` is
  the more legible name for ~150 uses.
- `Base.:(==)(a::CursorFrame, b::CursorFrame)` (200): both parameters have
  the same role (a compared `CursorFrame`); proposals `frame`/`other`
  distinguish them rather than reusing `frame` twice.

## Neighbours

- `ws` — two unrelated terse meanings in this file: "warnings" (the
  `DiagnosticError`/`_warn!`/`_show_warnings` list) and "wires"
  (`_wirelist(ws)`, 887) — never the spec's workspace `ws`.
- `fr` — `CursorFrame` instance, in `_phase_text(fr::CursorFrame)` (226) and
  `Base.showerror(io::IO, e::StepError)`'s local `fr = e.frame` (244).
- `ns` — a name list, throughout `_namelist`/`_faceset`/`_plainlist`/
  `_symtuple` (70–73).
- `ds` — a diagnostics list, in `_groups` (110) and the Vector
  `showerror` (134).
- `ps` — a path list, in `_replay_paths(ps)` (1909).
- `pw`, `wp`, `wk`, `wf` — column-width locals in `_grid_block` (1289–1305).

## Questions

None. Every single-letter binding in this file was either a short-lived
loop/comprehension variable settled by span (glance), a plain runtime value
settled by role against the payload it renders (rename), or `t` read
straight off the clock (survivor). No binding's status turned on a spec
passage beyond §13.4's `t`.

## Coverage

Full coverage. Every function definition in `src/diagnostics.jl` — long and
short form, every per-kind `severity`/`path`/`message` method, every private
helper, every closure/comprehension/anonymous-function argument and `for`
variable — was read and classified. The two default methods
`severity(::Diagnostic) = :error` and `path(::Diagnostic) = ""` take an
anonymous argument and contribute no row.
