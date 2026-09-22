# Naming survey — slice F, services

Tip `2844584`. Files: `src/conditions.jl`, `src/readers.jl`, `src/trim.jl`.
Function definitions examined: 131 (63 in `conditions.jl`, 45 in `readers.jl`,
23 in `trim.jl`), every long-form and short-form method, inner function and
closure in the three files. Date: 2026-09-22.

Glance threshold used throughout: a binding's last use within **5** source
lines of its definition (inclusive) counts as one glance; a comprehension,
`do`-block or anonymous-function argument whose own body is 1–2 lines counts
as one glance regardless of that gap. Both rules appear in the rows below as
plain "glance"; the span column carries the actual gap so the threshold can
be moved.

Two of §5.2's bundle letters recur as genuine survivors in this slice: `x`
denotes the component's declared state-field NamedTuple (`d.x`) in
`_leaf_offset` and `_capture_x` (`conditions.jl`), and `N` denotes a tuple
length baked into a type parameter (`ForwardDiff.Dual{TrimTag,Float64,N}`) in
`trim!` (`trim.jl`). No other spec letter (`s`, `u`, `y`, `m`, `t`, `T`, `D`,
`Φ`, `h`, `io`, …) appears as a plain single-letter binding in these three
files; every `s` met here is a read selector or a condition-tree scope
prefix, never the discrete-state `s`.

## Conventions

**`conditions.jl`**

- **A.** `_flat(n::Kind, path, level, prov, pos, structure, diags)` (lines
  167–182 `Fragment`, 184–190 `Scoped`, 192–196 `Combined`, 202–217
  `Override`): every method takes `n`, the condition-tree node being
  flattened. All four are glance (`n`'s own last use sits 3–5 lines from its
  parameter line in every method).
- **B.** `_scoped!(n::Kind, pos, out)` (lines 714 `Fragment`, 715–716
  `Scoped`, 717–720 `Combined`, 721–724 `Override`): every method takes `n`,
  the node whose `Scoped` prefixes are collected. All four are glance
  (one-line or near-one-line bodies).
- **C.** `combine(a::Kind, b::Kind)` (lines 110, 111), the mixed-argument
  misuse pair: `a` is the first operand, `b` the second, roles swapping with
  the argument order across the two methods. Both one-liners, both glance.
- **K.** `_write!(w::Kind, ex::Executor, tree)` (lines 608–609 `XWrite`,
  611–612 `InputWrite`, 614–619 `StoreWrite`): every method takes `w`, the
  compiled write being applied. All three one-liner or near-one-liner,
  glance.

**`readers.jl`**

- **D.** `_spell(s::Kind)` (lines 99–103, `GetState`/`GetDeriv`/`GetOutput`/
  `GetInput`/`GetFace`): every method takes `s`, the selector being rendered
  for a diagnostic. All five one-liners, glance.
- **E.** The selector-field accessors `_selpath(s::Kind)` (277),
  `_selindex(s::Kind)` (279), `_field(s::Kind)` (302, 303): every named-`s`
  method takes `s`, the selector queried for one of its fields. All
  one-liners, glance. (The unnamed-argument overloads at 278 and 280 bind
  nothing.)
- **F.** `_read(r::Kind, ex::Executor)` (lines 166–176,
  `StateRead`/`DerivRead`/`StoreRead`/`CellRead`): every method takes `r`,
  the compiled read entry. All one-liners, glance.
- **G.** `_resolve_selector(s::Kind, label, build_or_b, act, diags)` (lines
  305–318 `GetState`, 320–336 `GetDeriv`, 338–350 `GetOutput`, 352–361
  `GetInput`, 363–375 `GetFace`): every method takes `s`, the read selector
  being resolved against a build. `s`'s own last use sits 7–13 lines past its
  parameter line in every method, so the family renames uniformly to
  `selector` (no collision). Separately, the family is **not** internally
  consistent on its build parameter: `GetState` and `GetDeriv` already spell
  it `build`, while `GetOutput`, `GetInput` and `GetFace` spell it `b`
  (individually tabulated below, all glance there).
- **H.** `_declares(label, s, declares, declared::Kind)` (lines 292, 298):
  both methods take `s`, the selector naming an undeclared field. Both
  one-liners, glance.
- **I.** `_index_arg(i::Integer)` / `_index_arg(i)` (lines 83, 84): both
  methods take `i`, the index argument being validated. Both one-liners,
  glance.
- **J.** `_take(v, ::Nothing)` / `_take(v, i::Int)` (lines 163, 164): both
  methods take `v`, the value read (whole or about to be indexed); the
  second also takes `i`, the vector-leaf index (tabulated at line 164
  below, since only one method has it). Both glance.

No convention was found worth stating for `trim.jl`: `p::TrimProblem`
recurs as a parameter name across `_check_decisions!`, `_check_tolerances!`,
`_check_reads!` and `_verdict!`, but these are four distinct function names,
not one generic dispatched over a type — the brief's convention shortcut
(`show(io, x)`, `message(d::Kind)`) does not apply, so each occurrence is its
own row below.

## The table

### `src/conditions.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 82 | `_payload` | `p` | a fragment payload, checked as a NamedTuple | param | glance | — | |
| 92–93 | `at` (2 methods) | — | (no single-letter names) | — | — | — | |
| 110–111 | `combine` (misuse pair) | `a`, `b` | see convention C | param | glance | — | |
| 130 | `_misuse_in` | `n` (anon-fn arg) | each candidate operand, tested for `ConditionNode`-ness | 130–130 | glance | — | |
| 131 | `_misuse_in` | `n` (generator var) | each `ConditionNode` operand, collected for the message | 131–131 | glance | — | distinct scope from line 130's `n` |
| 133 | `_node_misuse` | `v` | the misused value handed to a node builder | param | glance | — | |
| 164 | `_key` | `e` | the flattened entry being keyed for dedup | param | glance | — | |
| 165 | `_step` | `s` | the provenance step label | param | glance | — | |
| 167–182 | `_flat` (`Fragment`) | `n` | see convention A | param | glance | — | |
| 172 | `_flat` (`Fragment`) | `v` (loop var) | the payload field's authored value | 172–173 | glance | — | |
| 173 | `_flat` (`Fragment`) | `e` (local, reassigned 176) | the entry being built for this payload field | 173–178 | glance | — | |
| 184–190 | `_flat` (`Scoped`) | `n` | see convention A | param | glance | — | |
| 192–196 | `_flat` (`Combined`) | `n` | see convention A | param | glance | — | |
| 196 | `_flat` (`Combined`) | `i` (generator var) | the node's position in `combine`'s tuple | 194–196 | glance | — | |
| 196 | `_flat` (`Combined`) | `k` (generator var) | the child node being flattened | 194–196 | glance | — | |
| 202–217 | `_flat` (`Override`) | `n` | see convention A | param | glance | — | |
| 205 | `_flat` (`Override`) | `i` (loop var) | the layer's position | 205–207 | glance | — | |
| 209 | `_flat` (`Override`) | `e` (loop var) | the incoming entry from this layer | 209–213 | glance | — | |
| 210 | `_flat` (`Override`) | `a` (anon-fn arg) | each accumulated entry, tested for a matching key | 210–210 | glance | — | |
| 210 | `_flat` (`Override`) | `j` (local) | the matching index in the accumulator | 210–212 | glance | — | |
| 223 | `_check_duplicates!` | `e` (loop var) | the candidate entry checked against the seen table | 223–230 | rename | `entry` | |
| 224 | `_check_duplicates!` | `k` (local) | the entry's dedup key (path/store/field, or input face) | 224–230 | rename | `key` | |
| 279 | `resolve_condition` | `b` | the build resolved against | param | rename | `build` | |
| 287 | `resolve_condition` | `r` (loop var) | the resolved entry pairing a flattened entry with its destination | 287–295 | rename | `resolved_entry` | collision — see below |
| 288 | `resolve_condition` | `e` (local) | the resolved entry's underlying flattened entry | 288–295 | rename | `entry` | |
| 344 | `_resolve_entries` | `P` | the destination leaf type (input face) | 344–347 | glance | — | |
| 345 | `_resolve_entries` | `ok`, `v` (input branch) | whether the conversion succeeded; the converted value | 345–347 | glance | — | |
| 353 | `_resolve_entries` | `c` | the component instance addressed by the entry | 353–360 | rename | `instance` | |
| 353 | `_resolve_entries` | `d` | the component's declared-fields record (`Decls`) | 353–364 | rename | `decl` | collision — see below |
| 340 | `_resolve_entries` | `e` (loop var) | the flattened entry being resolved | 340–364 | rename | `cond_entry` | collision — see below |
| 361 | `_resolve_entries` | `L` | the destination leaf type (component field) | 361–365 | glance | — | |
| 362 | `_resolve_entries` | `ok`, `v` (non-input branch) | whether the conversion succeeded; the converted value | 362–364 | glance | — | |
| 381 | `_leaf_offset` | `x` | the component's declared x-bundle field NamedTuple | param | survivor(x) | — | §5.2 bundle: the state-field declarations |
| 383 | `_leaf_offset` | `k` (loop var) | the field name being compared | 383–384 | glance | — | |
| 383 | `_leaf_offset` | `v` (loop var) | the field's declared value, for its leaf count | 383–385 | glance | — | |
| 390 | `_convert` | `v` | the value to convert | param | glance | — | |
| 399 | `_cviol` | `e` | the entry being reported | param | glance | — | |
| 408 | `_component` | `e` | the entry naming the path to resolve | param | glance | — | |
| 422 | `_root_input` | `e` | the input entry whose face is resolved | param | rename | `entry` | |
| 428 | `_root_input` | `k` (local) | the position of `e`'s face in the input-face table | 428–433 | glance | — | |
| 428 | `_root_input` | `p` (anon-fn arg) | each in-face table entry's (path, field) key | 428–428 | glance | — | |
| 430 | `_root_input` | `f` (generator var) | the candidate in-face name at `e`'s path | 430–430 | glance | — | |
| 430 | `_root_input` | `p` (generator var) | the candidate entry's owning path | 430–430 | glance | — | distinct scope from line 428's `p` |
| 443 | `_no_store` | `e` | the entry naming an unavailable store | param | glance | — | |
| 449 | `_undeclared` | `e` | the undeclared entry | param | glance | — | |
| 449 | `_undeclared` | `c` | the component instance, checked for the field's real family | param | glance | — | |
| 457 | `_declared_workspace` | `c` | the component instance | param | glance | — | |
| 465 | `_unconvertible` | `e` | the unconvertible entry | param | glance | — | |
| 465 | `_unconvertible` | `v` | the authored value that failed conversion | param | glance | — | |
| 496 | `assert_total` | `f` (generator var) | the candidate root input checked for coverage | 496–496 | glance | — | |
| 516 | `apply!(ex, plan::ConditionPlan)` | `v` (loop var, `plan.xs`) | the authored x-leaf value | 516–517 | glance | — | |
| 519 | `apply!(ex, plan::ConditionPlan)` | `v` (loop var, `plan.stores`) | the store's authored overlay value | 519–520 | glance | — | |
| 522 | `apply!(ex, plan::ConditionPlan)` | `v` (loop var, `plan.inputs`) | the authored input value | 522–523 | glance | — | |
| 608–619 | `_write!` (3 methods) | `w` | see convention K | param | glance | — | |
| 615 | `_write!` (`StoreWrite`) | `a` (anon-fn arg) | each field's compiled lens (`Authored` callable) | 615–615 | glance | — | |
| 674 | `compile_plan` | `b` | the build resolved against | param | rename | `build` | |
| 680 | `compile_plan` | `r` (loop var) | the resolved entry pairing a flattened entry with its destination | 680–687 | rename | `resolved_entry` | collision — see below |
| 681 | `compile_plan` | `e` (local) | the resolved entry's underlying flattened entry | 681–687 | rename | `entry` | |
| 695 | `compile_plan` | `r` (generator var) | each overlaid resolved entry for this store/component | 695–695 | glance | — | distinct scope from the outer loop's `r` |
| 696 | `compile_plan` | `r` (generator var) | each overlaid resolved entry for this store/component | 696–696 | glance | — | distinct scope again |
| 700 | `compile_plan` | `p` (generator var) | the node's tree position (`Prefix` type parameter) | 700–700 | glance | — | |
| 700 | `compile_plan` | `v` (generator var) | the node's authored prefix string | 700–700 | glance | — | |
| 771 | `_compare` | `p` | the compiled prefix check being verified | param | glance | — | |
| 826 | `capture` | `d` (loop var) | the component's declared-fields record (`Decls`) | 826–829 | glance | — | |
| 838 | `capture` | `f` (generator var) | each root input name being gathered | 838–838 | glance | — | |
| 849 | `_capture_x` | `x` | the component's declared x-bundle field NamedTuple | param | survivor(x) | — | §5.2 bundle: the state-field declarations |
| 851 | `_capture_x` | `v` (loop var) | the state field's declared value | 851–853 | glance | — | |

### `src/readers.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 83 | `_index_arg` (`Integer`) | `i` | see convention I | param | glance | — | |
| 84 | `_index_arg` (fallback) | `i` | see convention I | param | glance | — | |
| 87 | `get_state` | `i` | the optional vector-leaf index | param | glance | — | |
| 89 | `get_deriv` | `i` | the optional vector-leaf index | param | glance | — | |
| 91 | `get_output` | `i` | the optional vector-leaf index | param | glance | — | |
| 98 | `_ipart` | `i` | the optional index being rendered | param | glance | — | |
| 99–103 | `_spell` (5 methods) | `s` | see convention D | param | glance | — | |
| 128 | `_reads` | `s` (loop var) | the candidate selector value being validated | 128–129 | glance | — | |
| 131 | `_reads` | `v` (generator var) | each already-valid selector, listed for the error | 131–131 | glance | — | |
| 163 | `_take(v, ::Nothing)` | `v` | see convention J | param | glance | — | |
| 164 | `_take(v, i::Int)` | `v` | see convention J | param | glance | — | |
| 164 | `_take(v, i::Int)` | `i` | the vector-leaf index | param | glance | — | |
| 166–176 | `_read` (4 methods) | `r` | see convention F | param | glance | — | |
| 199 | `gather` | `r` | the compiled reader being applied | param | glance | — | |
| 200 | `gather` | `e` (anon-fn arg) | each compiled read entry | 200–200 | glance | — | |
| 225 | `_compile_reads` | `b` | the build resolved against | param | glance | — | |
| 241 | `_resolve_reads` | `b` | the build resolved against | param | glance | — | |
| 245 | `_resolve_reads` | `s` (loop var) | the declared selector, one entry of the read set | 245–246 | glance | — | |
| 246 | `_resolve_reads` | `e` (local) | the resolved read entry, or `nothing` on failure | 246–247 | glance | — | |
| 257 | `_read_component` | `s` | the path-addressed selector | param | glance | — | |
| 269 | `_rviol` | `s` | the selector being reported | param | glance | — | |
| 277, 279, 302, 303 | `_selpath`/`_selindex`/`_field` | `s` | see convention E | param | glance | — | |
| 286 | `_check_index` | `s` | the selector whose index is checked | param | glance | — | |
| 292, 298 | `_declares` (2 methods) | `s` | see convention H | param | glance | — | |
| 305–318 | `_resolve_selector(s::GetState)` | `s` | see convention G | param | rename | `selector` | |
| 309 | `_resolve_selector(s::GetState)` | `d` | the component's declared-fields record (`Decls`) | 309–317 | rename | `decl` | |
| 309 | `_resolve_selector(s::GetState)` | `t` | the component's tier | 309–316 | rename | `tier` | |
| 313 | `_resolve_selector(s::GetState)` | `P` | the state field's declared type | 313–317 | glance | — | |
| 320–336 | `_resolve_selector(s::GetDeriv)` | `s` | see convention G | param | rename | `selector` | |
| 324 | `_resolve_selector(s::GetDeriv)` | `d` | the component's declared-fields record (`Decls`) | 324–333 | rename | `decl` | |
| 324 | `_resolve_selector(s::GetDeriv)` | `t` | the component's tier | 324–325 | glance | — | |
| 331 | `_resolve_selector(s::GetDeriv)` | `P` | the state field's declared type | 331–333 | glance | — | |
| 338–350 | `_resolve_selector(s::GetOutput)` | `s` | see convention G | param | rename | `selector` | |
| 338 | `_resolve_selector(s::GetOutput)` | `b` | the build resolved against | param | glance | — | spelled `b`, not `build`; see convention G |
| 342 | `_resolve_selector(s::GetOutput)` | `d` | the component's declared-fields record (`Decls`) | 342–346 | glance | — | |
| 352–361 | `_resolve_selector(s::GetInput)` | `s` | see convention G | param | rename | `selector` | |
| 352 | `_resolve_selector(s::GetInput)` | `b` | the build resolved against | param | glance | — | spelled `b`, not `build`; see convention G |
| 363–375 | `_resolve_selector(s::GetFace)` | `s` | see convention G | param | rename | `selector` | |
| 363 | `_resolve_selector(s::GetFace)` | `b` | the build resolved against | param | glance | — | spelled `b`, not `build`; see convention G |
| 365 | `_resolve_selector(s::GetFace)` | `f` (generator var) | the candidate exported face name | 365–365 | glance | — | |
| 365 | `_resolve_selector(s::GetFace)` | `p` (generator var) | the candidate entry's owning path (root check) | 365–365 | glance | — | |

### `src/trim.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 173 | `_within` | `r` | the residual vector | param | glance | — | |
| 173 | `_within` | `i` (anon-fn arg) | the residual's index | 173–173 | glance | — | |
| 178 | `_scaled_norm` | `r` | the residual vector | param | glance | — | |
| 178 | `_scaled_norm` | `i` (anon-fn arg) | the residual's index | 178–178 | glance | — | |
| 182 | `solve` | `n` | the decision count | 182–183 | glance | — | |
| 182 | `solve` | `m` | the residual count | 182–183 | glance | — | |
| 183 | `solve` | `d` | the current decision vector | 183–218 | rename | `decisions` | |
| 183 | `solve` | `r` | the residual vector at the current point | 183–218 | rename | `residual` | |
| 183 | `solve` | `J` | the Jacobian matrix at the current point | 183–218 | rename | `jacobian` | |
| 186 | `solve` | `λ` | the LM damping coefficient | 186–214 | rename | `damping_scale` | distinct from local `damp`, the damping matrix |
| 196 | `solve` | `A` | the Gauss-Newton normal matrix (JᵀJ) | 196–201 | glance | — | |
| 196 | `solve` | `g` | the Gauss-Newton gradient (Jᵀr) | 196–201 | glance | — | |
| 201 | `solve` | `δ` | the trial LM step | 201–203 | glance | — | |
| 243 | `_check_decisions!` | `p` | the trim problem being validated | param | rename | `problem` | |
| 245 | `_check_decisions!` | `v` (loop var) | the candidate bound NamedTuple (guess/lower/upper) | 245–247 | glance | — | |
| 251 | `_check_decisions!` | `v` (loop var) | the bound NamedTuple being key-compared | 251–253 | glance | — | distinct scope from line 245 |
| 256 | `_check_decisions!` | `v` (loop var) | the bound NamedTuple being float-checked | 256–257 | glance | — | distinct scope again |
| 259 | `_check_decisions!` | `k` (loop var) | the decision's name, shared by guess/lower/upper | 259–263 | glance | — | |
| 279 | `_check_tolerances!` | `p` | the trim problem being validated | param | rename | `problem` | |
| 285 | `_check_tolerances!` | `k` (loop var) | the tolerance's name | 285–289 | glance | — | |
| 286 | `_check_tolerances!` | `v` (local) | the tolerance value | 286–289 | glance | — | |
| 294 | `_check_floats!` | `v` | the NamedTuple whose fields are type-checked | param | glance | — | |
| 295 | `_check_floats!` | `k` (generator var) | the field's name | 295–295 | glance | — | |
| 305 | `_check_reads!` | `p` | the trim problem being validated | param | glance | — | |
| 305 | `_check_reads!` | `b` | the build resolved against | param | glance | — | |
| 319 | `_check_residuals` | `r` | the residual return being validated | param | rename | `residuals` | |
| 327 | `_check_residuals` | `k` (generator var) | the residual's name | 327–327 | glance | — | |
| 392 | `trim!` | `b` | the build trimmed against | 392–429 | rename | `build` | |
| 400 | `trim!` | `K` | the decision names, in `guess`'s field order | 400–483 | rename | `decision_keys` | |
| 401 | `trim!` | `N` | the decision count | 401–458 | survivor(N) | — | tuple length in the type parameter `ForwardDiff.Dual{TrimTag,Float64,N}` |
| 444 | `eval!` (closure in `trim!`) | `r` | the residual output buffer | 444–456 | rename | `residuals` | |
| 444 | `eval!` (closure in `trim!`) | `J` | the Jacobian output buffer, or `nothing` | 444–459 | rename | `jacobian` | |
| 444 | `eval!` (closure in `trim!`) | `d` | the decision vector at this trial point | 444–445 | glance | — | |
| 454 | `eval!` (closure in `trim!`) | `i` (loop var) | the residual's index | 454–459 | glance | — | |
| 455 | `eval!` (closure in `trim!`) | `v` (local) | the dual-valued residual entry (value + partials) | 455–459 | glance | — | |
| 458 | `eval!` (closure in `trim!`) | `j` (loop var) | the decision's index, the partial-derivative column | 458–459 | glance | — | |
| 465 | `trim!` | `k` (generator var) | the decision's name | 465–465 | glance | — | |
| 466 | `trim!` | `k` (generator var) | the decision's name | 466–466 | glance | — | |
| 474 | `trim!` | `k` (generator var) | the decision's name | 474–474 | glance | — | |
| 479 | `trim!` | `r` | the residual vector at the returned point | 479–481 | glance | — | |
| 531 | `_seeded` | `K` | the decision names | param | glance | — | |
| 531 | `_seeded` | `v` | the decision vector (packed values) | param | glance | — | |
| 532 | `_seeded` | `i` (anon-fn arg) | the decision's index, the unit-partial slot | 532–533 | glance | — | |
| 533 | `_seeded` | `j` (anon-fn arg) | the partial's index, compared against `i` | 533–533 | glance | — | |
| 539 | `_saturated` | `K` | the decision names | param | glance | — | |
| 539 | `_saturated` | `d` | the decisions at the returned point | param | glance | — | |
| 542 | `_saturated` | `i` (loop var) | the decision's index | 542–544 | glance | — | |
| 552 | `_verdict!` | `p` | the trim problem being reported | param | rename | `problem` | |
| 553 | `_verdict!` | `r` | the residuals at the returned point | param | glance | — | |
| 566 | `_verdict!` | `i` (generator var) | the event's index, checked for a nonzero fire count | 566–566 | glance | — | |
| 572 | `_verdict!` | `i` (generator var) | the residual's index, into `tol` | 571–573 | glance | — | |
| 572 | `_verdict!` | `k` (generator var) | the residual's name | 571–573 | glance | — | |

## Collisions

- `conditions.jl:353`, `_resolve_entries` — `d` (the component's `Decls`)
  would propose `decls`, colliding with the local `decls` (line 334, the
  build-wide `Vector` of every component's `Decls`). Alternative: `decl`.
- `conditions.jl:340`, `_resolve_entries` — `e` (the loop's flattened entry)
  would propose `entry`, colliding with the local `entry` (line 352, the
  structure's `ComponentEntry`). Alternative: `cond_entry`.
- `conditions.jl:287`, `resolve_condition` — `r` (the loop's resolved entry)
  would propose `resolved`, colliding with the local `resolved` (line 280,
  the `Vector{Resolved}` it iterates). Alternative: `resolved_entry`.
- `conditions.jl:680`, `compile_plan` — the same pattern as above: `r`
  would collide with the local `resolved` (line 675). Alternative:
  `resolved_entry`.

## Neighbours

- `es` (`conditions.jl:207–216`) — one layer's flattened entries, inside
  `_flat`'s `Override` method.
- `ov` (`conditions.jl:303, 693`) — the collected overlay fields for one
  component's store write.
- `act` (all three files) — the resolved `Activation` at one scalar type.
- `ex` (`conditions.jl`, `trim.jl`) — the executor a plan or read is applied
  against.
- `lc` (`conditions.jl:819`, `trim.jl:386`) — the simulation's lifecycle
  symbol.
- `dt`, `rt`, `Jt` (`trim.jl:184`) — the trial decision/residual/Jacobian,
  mirroring `d`/`r`/`J`'s own naming.
- `d0` (`trim.jl:180, 474`), `r0` (`trim.jl:405, 411, 417`) — the initial
  decision vector and the nominal-half residual return.
- `res` (`trim.jl:453`) — the residual return reordered to `tolerances`'
  field order, inside `eval!`.
- `off` (`trim.jl:571`) — the committed residuals that left their box,
  inside `_verdict!`.
- `TD` (`trim.jl:423`) — the seeded `ForwardDiff.Dual` type trim resolves
  the specialized plan and reader at.
- `RK` (`trim.jl:400, 556`) — the residual names, `tolerances`' field order;
  pairs with the tabulated `K`.

## Questions

None. Every single-letter binding in this slice resolved cleanly against
§5.2's bundle table or against its own role — no letter's survivor status
turned on a spec passage I could not locate.

## Coverage

All 131 function definitions in the three files were examined; none were
skipped.
