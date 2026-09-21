# Data survey, slice A — authoring

Tip `aa9162a` (the brief names `34f8a39`; `aa9162a` adds the brief itself and touches no `src/`). Files: `src/leaves.jl`, `src/declare.jl`, `src/assembly.jl`, `src/tracer.jl`. Structs surveyed: 9 (`leaves.jl` defines none; `RateLink` and `RateScope` in `assembly.jl` are `@NamedTuple` aliases, covered through the fields that hold them). Date 2026-09-21.

Every "no reader" or "same object" claim below was checked in a REPL (`julia --project=test -L test/repl.jl`) on the `Pendulum` and `MultiRate` fixtures, besides the grep.

## Findings

### `Walk.root_types` — misplaced (courier)
`src/assembly.jl:771`. `Vector{Any}`. Writers: `Walk(root)` (`assembly.jl:784`, `Any[]`), and nothing during the walk: no `push!(w.root_types` anywhere. Readers: `wire!` (`assembly.jl:980`), which hands the empty vector to `Structure`; the vector is then filled after the `Structure` exists, by `_check_wires` in `src/build.jl:832`, `838`, `852` (`push!(s.root_types, …)`), and read by `_root_input_cell` (`build.jl:583`) and `_classify` (`tracer.jl:245`).
Evidence: `grep -rn '\.root_types' src/` returns the definition lines, the `wire!` hand-off and the three `push!(s.root_types` in `build.jl`; REPL: after `flatten!` on `Pendulum`, `w.root_types == Any[]` while `w.root_inputs == [:u]`; after `wire!`, `s.root_types === w.root_types` is `true` and its length is 0; after `_check_wires`, `s.root_types == Any[Float64]`.
Proposal: drop the field; `wire!` allocates `root_types = Any[]` beside the `conns` and `in_faces` it already derives locally, and `Walk(root)` loses one argument. Changes: the `Walk` struct and its constructor (`assembly.jl:771`, `784`), one line in `wire!`. The post-construction fill by `_check_wires` is a separate question (below).
Spec: not rostered. `Structure.root_types` is the spec's root-input type (§8.2, D-236), but the `Walk` field is not.

## Clean

| struct | file:line | fields | note |
| --- | --- | --- | --- |
| `Period` | `declare.jl:126` | 1 | `T` read by `period`, `Absolute`'s constructor, `deployment.jl:15` |
| `Relative` | `declare.jl:144` | 2 | `K`, `φ` read by `_check_sample_times` and `_child_scope` (`assembly.jl:837`, `890`) |
| `Absolute` | `declare.jl:155` | 2 | `T`, `τ` read by `_check_sample_times` and the anchor push (`assembly.jl:840`, `898`) |
| `StateEvent` | `declare.jl:183` | 2 | `guard`, `handler` read in `build.jl:745`, `1168`, `1174`, `1456` |
| `Group` | `assembly.jl:250` | 5 | `children` read by the reflective container walk `_children` via `transparent_container(::Group)`; `wires`, `inputs`, `outputs`, `rates` by the four declaration accessors (`assembly.jl:271–274`) |
| `Structure` | `assembly.jl:737` | 14 | every field has a reader outside `assembly.jl`; `provenance` reaches `ScheduleRow.provenance` and is read only by the deployment's `==`/`hash` and the replay header diff (`deployment.jl:115`, `117`; `trace.jl:302`), no printer in `src/` |
| `Walk` | `assembly.jl:765` | 16 | 15 clean: each accumulator is written in `_walk!`/`_claim!` and read by `flatten!`, `wire!`, the resolvers or `WALK_FACES`; `claims` is read for `TwoProducers`' message only, which is what it is for |
| `Tracer` | `tracer.jl:27` | 2 | `val` and `deps` read by every lifted operation; `val` is read in global mode too, for untainted decisions (`_decide` at `tracer.jl:103`) |
| `Undecidable` | `tracer.jl:33` | 0 | marker |

## Questions

- **`Structure.root_types` is completed after construction.** `Structure` is the immutable structure-step artifact (D-253), yet `_check_wires` (`build.jl:782–855`) fills `s.root_types` by `push!` on a `Structure` that `wire!` already returned. The value belongs to the `Structure` (the spec's root-input type, §8.2), so the field is not misplaced; the construction order is. If the user wants the artifact complete at construction, `_check_wires` would return the vector and `build` would compose the `Structure` after the barrier, which moves `Structure(...)` out of `wire!`.
- **`Structure.conns` and the primitive rows of `Structure.in_faces` hold the same fact.** `wire!` derives both from `w.feeds` (`assembly.jl:964–982`); `in_faces` is `routes`' rows plus every `conns` row (REPL on `MultiRate`: 5 rows in `in_faces`, 3 of them the `conns` rows). Readers differ: `conns` is indexed per component by `build.jl` and `tracer.jl`, `in_faces` by `(path, face)` in `conditions.jl:440–446` alone. One writer, immutable after, so the agreement has an enforcer; §9.2 asks for the input side to be total, so the overlap looks intended. Not counted as a finding.
- **`Structure.aprov` is a rendering.** Per anchor it holds the string `` "`sample_times` at …, key `k`" `` (`assembly.jl:895`), used as the anchor's identity in `_child_scope` (`findfirst(==(prov), w.aprov)`), carried onto `GridEntry.provenance`, and parsed back with a regex for the key in `_grid_label` (`diagnostics.jl:1280`). §9.2 describes the anchor table as "the declaring scope's path and key". `scopes` does not substitute for it: a keyed primitive child gets an anchor but no `RateScope` row (REPL on `MultiRate`: `aprov` names `gnss`, `scopes` holds `fcs` only). A structured `(path, key)` per anchor would remove the regex; a representation choice, not a smell.
- **`Walk.root` beside `flatten!`'s `root` argument.** `build` calls `Walk(root)` then `flatten!(w, root, diags)` (`build.jl:694–695`); `w.root === root` in the REPL. The field's one reader is `wire!` (`assembly.jl:979`), which places it on `Structure`. Either the argument or the field is redundant; since `Walk` is by design the pre-`Structure`, the field is the natural one to keep and the argument the one to drop, but that is a signature matter.
- **Straddles slice B.** `Layout.root_inputs` (`build.jl`) carries `(face, probe value)` pairs, and six readers read only the names off it (`Symbol[f for (f, _) in layout.root_inputs]` in `roster.jl:199`, `215`, `254`, `bindings.jl:151`, `trace.jl:215`, `sim.jl:282`), which `Structure.root_inputs` already holds in the same order. Slice B's field; named here because the name list is this slice's.

## Coverage

All nine structs reached. `leaves.jl` defines no struct (grep `struct |abstract type|@kwdef|primitive type` returns comments only). `RateLink` and `RateScope` are NamedTuple aliases, not structs, and are surveyed through `Structure.provenance`/`Walk.provenance` and `Structure.scopes`/`Walk.scopes`; `RateLink.scope` and `RateLink.entry` have no reader by name in `src/` beyond `==`/`hash` on `ScheduleRow` and the replay diff, which is the reader `provenance` exists for (§12.7).
