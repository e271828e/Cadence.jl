# Naming survey — slice B, build

Tip `2844584`. Files: `src/build.jl`, `src/executor.jl`, `src/store.jl`,
`src/stepper.jl`. Function/method/closure definitions examined: 51 in
`build.jl`, ~36 named functions (~50 methods, counting the recursive-walk
pairs and generated-function overloads) in `executor.jl`, 7 in `store.jl`, 9
in `stepper.jl` — 103 named definitions in all, every one read in full.
Date: 2026-09-22.

Type parameters (every name bound by a `where {...}` clause or appearing only
as `::Type{X}`) are out of scope per the brief regardless of letter count,
and are not tabulated: `T` (the activation scalar, everywhere), and per
struct/generated method `P`, `K` (`store.jl`'s `CellAddr`), `F`, `Comp`, `XT`,
`BN`, `IA`, `YA`, `OA`, `CL`, `SS`, `MS`, `WS` (`executor.jl`'s entry
structs), `G`, `H` (`EventEntry`), `E`, `P` (`EventSet`), `E`, `S`, `X`
(`Chunk`), `I`, `B` (`PhaseBody`), `L` (`store.jl`'s `_cell_key`), `Ns`, `Ys`,
`NT` (`store.jl`'s bundles). Struct field names and keyword-argument names
are likewise excluded throughout (e.g. every `Δt`, `y`, `ws`, `m`, `event`
appearing after a `;` or as a struct field).

## Conventions

- **`ci`** — the component index, the rule's own permanent survivor —
  appears dozens of times across `build.jl` and `executor.jl` as a
  parameter, `do`-block argument, `for`-loop variable and comprehension
  variable (representative sites: `build.jl:257,364,401,443,459,1039,1073,
  1128,1201,1301,1379,1430,1459,1487,1552`; every entry struct in
  `executor.jl` carries it as a field, out of scope there). It is never
  proposed for rename, at any span. Individual occurrences are not
  tabulated below — this is a scope-management decision for this report,
  not a Julia dispatch convention.
- **`e`** (`executor.jl`) — the compiled schedule entry (`StageEntry` /
  `RHSEntry` / `UpdateEntry` / `EventEntry` / `ProjectEntry`) — covers
  `run!(e::StageEntry,...)`, `run!(e::RHSEntry{Comp,XT},...)`,
  `run!(e::UpdateEntry,...)`, `make_bundle(e::StageEntry{F,Comp,XT,BN},...)`,
  `make_bundle(e::RHSEntry{Comp,XT,BN},...)`,
  `make_bundle(e::UpdateEntry{Comp,BN},...)`,
  `make_bundle(e::EventEntry{G,H,P,Comp,XT,BN},...)`,
  `run_at!(e, store, xbuf, ẋbuf, idx)` (the ungated fallback),
  `_latch!(e::EventEntry{...},...)`, `_fire_project!(e::EventEntry{...},...)`,
  `_event_bodies(e::EventEntry,...)`, `_project_body(e::ProjectEntry,...)`,
  `run_project!(e::ProjectEntry{Comp,XT},...)`. Proposal: `entry` (see
  Questions — `build.jl` already uses `entry` for `ComponentEntry`).
- **`t::Tuple`** (`executor.jl`) — the remaining tuple in a
  compile-time-unrolled recursive walk — covers `_walk(t::Tuple,...)` beside
  its `::Tuple{}` base case, `_walk_at(t::Tuple,...)`, `_guard_walk(t::Tuple,
  ...)`, `_fire_walk(t::Tuple,...)`, `_proj_walk(t::Tuple,...)`,
  `_walkchunks(t::Tuple)`/`_walkchunks(t::Tuple, idx)`. Proposal: `rest`.
- **`g::Gated`** (`executor.jl`) — the gate-wrapped entry — covers both
  `run_at!(g::Gated,...,tick::Int)` and `run_at!(g::Gated,...,::Establish)`.
  Proposal: `gated`.
- **`c::Chunk`** (`executor.jl`) — the compiled chunk callable — covers
  `(c::Chunk)()` and `(c::Chunk)(idx)`. Proposal: `chunk`.
- **`b::PhaseBody`** (`executor.jl`) — the compiled phase-body callable —
  covers `(b::PhaseBody)()` and `(b::PhaseBody)(idx)`. Proposal: `body`.
- **`m`** (`stepper.jl`) — the stepper instance under dispatch — covers
  `step!(m::RK4, sim, h)`, `step!(m::Heun, sim, h)`, `startpoint(m::RK4)`,
  `startpoint(m::Heun)`, `dense!(m::AbstractStepper,...)`. Proposal:
  `stepper`.
- **`b`/`a`** (`store.jl`) — the store bundle / cell address pair — covers
  `gather(b::StoreBundle, a::CellAddr{P,K})` and
  `scatter!(b::StoreBundle, a::CellAddr{P,K}, v)`. Proposal: `bundle`/`addr`.

## The table

### `src/build.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 22 | `_passes_frame` | e | untyped, the exception under test | param | rename | exc | |
| 35 | `invoke_declaration` | c | untyped, the component instance | param | rename | comp | |
| 38 | `invoke_declaration` | e | the caught exception | 38–40 | glance | | |
| 50 | `invoke_probed` | c | untyped, the component instance | param | rename | comp | |
| 50 | `invoke_probed` | t | `::Tier`, the tier | param | rename | tier | |
| 53 | `invoke_probed` | e | caught exception, reclassified into a bundle diagnostic | 53–62 | rename | exc | exceeds the glance span, unlike most `catch e` in this file |
| 68 | `_inputs_spelling` | b | `::NamedTuple`, the probe bundle | param | rename | bundle | |
| 71 | `_inputs_spelling` | e | the caught exception | 71–71 | glance | | |
| 79 | `at_component` | f | untyped, the per-component thunk | param | rename | thunk | |
| 82 | `at_component` | e | the caught exception | 82–84 | glance | | |
| 84 | `at_component` | d | the framing payload (`e.carried`) | 84–86 | glance | | |
| 102 | `state_decls` | d | `::Decls`, the tier declarations | param | rename | decl | see Collisions |
| 102 | `state_decls` | t | `::Tier`, the tier | param | rename | tier | |
| 110 | `declarations` | c | untyped, the component instance | param | rename | comp | |
| 110 | `declarations` | t | `::Tier`, the tier | param | rename | tier | |
| 136 | `check_state_leaves` | c | untyped, the component instance | param | rename | comp | |
| 137 | `check_state_leaves` | v | the declared `init_x` field value | 137–143 | rename | value | loop body > 5 lines |
| 138 | `check_state_leaves` | L | the leaf's element type | 138–142 | glance | | |
| 151 | `check_store_form` | c | untyped, the component instance | param | rename | comp | |
| 154 | `check_store_form` | v | the by-value store returned | 154–156 | glance | | |
| 163 | `check_stores` | c | untyped, the component instance | param | rename | comp | |
| 166 | `check_stores` | v | the store field value | 166–169 | glance | | |
| 180 | `_form` | t | `::Tier`, the tier | param | rename | tier | |
| 186 | `classify_tier` | c | untyped, the component instance | param | rename | comp | |
| 204 | `classify_tier` | v | lambda arg, the vote tuple tested | 204–204 | glance | | anonymous-fn arg |
| 210 | `classify_tier` | v | lambda arg, the vote tuple tested | 210–210 | glance | | |
| 204/210 | `classify_tier` | i | the index of the deciding vote | 204/210–224 | rename | vote_index | one binding, assigned in either branch |
| 214 | `classify_tier` | v | comprehension var, the vote tuple | 214–214 | glance | | |
| 224 | `classify_tier` | t | the decided tier | 224–239 | rename | tier | no clash — this function's own params are `path,c,diags` |
| 225 | `classify_tier` | k | diagnostics count before the vote loop | 225–239 | rename | before_count | |
| 257 | `probe_stage1` | — | (see Conventions: `ci`) | | | | |
| 260 | `probe_stage1` | c | the component instance | 260–266 | rename | comp | |
| 260 | `probe_stage1` | d | the component's `Decls` | 260–275 | rename | decl | see Collisions |
| 266/274 | `probe_stage1` | y | the stage's returned bundle | — | survivor(y) | | |
| 280 | `_bundle_values` | d | `::Decls`, the component's `Decls` | param | rename | decl | see Collisions |
| 280 | `_bundle_values` | u | the input bundle | param | survivor(u) | | |
| 282 | `_bundle_values` | n | `do`-block arg, the bundle field name | 282–293 | rename | field | 11-line ternary, not "1–2 lines" |
| 299 | `_check_ports` | y | `::NamedTuple`, the stage's returned bundle | param | survivor(y) | | |
| 301 | `_check_ports` | v | the port's returned value | 301–310 | rename | value | |
| 326 | `_embed` | v | the value to embed | param | rename | value | |
| 328 | `_embed` | l | comprehension var, the leaf value | 328–329 | glance | | |
| 331 | `_embed_ports` | y | `::NamedTuple`, the probed bundle | param | survivor(y) | | |
| 344 | `_homes` | d | `::Decls`, the component's `Decls` | param | rename | decl | see Collisions |
| 344 | `_homes` | t | `::Tier`, the tier | param | rename | tier | |
| 344 | `_homes` | m | probe-scoped mode `Ref`, or `nothing` | param | survivor(m) | | |
| 366 | `_outputs` | n | the component count | 366–385 | rename | ncomps | |
| 423 | `_cycle_diagnostics` | v | `for v in nodes`, the residue node | 423–424 | glance | | |
| 432 | `_cycle_diagnostics` | i | comprehension var, the walk position | 432–432 | glance | | in `Dict(ci=>i for (i,ci) in enumerate(order))` |
| 439 | `_cycle_diagnostics` | d | the constructed `AlgebraicCycle` | 439–442 | glance | | |
| 452 | `_tarjan` (`strong!`) | v | closure param, the node under DFS | 452–473 | rename | node | recursive, whole-function span |
| 456 | `_tarjan` (`strong!`) | w | `for`-loop var, the successor node | 456–463 | rename | neighbor | |
| 467 | `_tarjan` (`strong!`) | w | `while`-loop var, the node popped off the DFS stack | 466–470 | rename | popped | non-overlapping with the `for`-loop `w` above |
| 475 | `_tarjan` | v | outer driving loop, the unvisited node | 475–476 | glance | | inconsistent with `strong!`'s renamed `v`; see Questions |
| 484 | `_cluster_walk` (`visit!`) | v | closure param, the node visited | 484–489 | rename | node | |
| 487 | `_cluster_walk` (`visit!`) | w | `for`-loop var, the neighbor | 487–487 | glance | | |
| 536 | `cell_layout` (`place!`) | L | `for`-loop var, the leaf eltype | 536–538 | glance | | |
| 536 | `cell_layout` (`place!`) | L | comprehension var, the leaf eltype | 536–536 | glance | | second occurrence, same line |
| 542 | `cell_layout` | d | the component's `Decls` | 542–543 | glance | | short-lived here, unlike other `d`s |
| 543 | `cell_layout` | P | `for`-loop var, the port's declared type | 543–544 | glance | | a real runtime binding, not the type parameter `P` |
| 547 | `cell_layout` | i | the root input's position | 547–548 | glance | | |
| 548 | `cell_layout` | P | local, the root input's cell type | 548–571 | rename | cell_type | not the type parameter `P` — a plain local holding a `Type` |
| 564 | `cell_layout` | v | the synthesized probe value | 564–571 | rename | value | |
| 566 | `cell_layout` | e | the caught exception | 566–567 | glance | | |
| 577 | `cell_layout` | p | lambda arg, the (eltype, count) pair | 577–577 | glance | | |
| 581 | `cell_layout` | d | the component's `Decls` | 581–582 | glance | | |
| 582 | `cell_layout` | n | the component's leaf count | 582–584 | glance | | |
| 594 | `_root_input_cell` | i | `::Int`, the root input's position | param | rename | pos | |
| 598 | `_root_input_cell` | f | comprehension var, the consuming face name | 598–599 | glance | | |
| 600 | `_root_input_cell` | e | lambda arg, the input entry's declared type | 600–600 | glance | | |
| 604 | `input_addr` | p | lambda arg, the connection pair | 605–605 | glance | | |
| 750 | `build` | e | the caught exception | 750–754 | glance | | |
| 745 | `build` | A | `for`-loop var, the activation scalar type | 745–745 | glance | | |
| 773 | `_check_event_declarations` | c | the component instance | 773–787 | rename | comp | |
| — | `Base.show(io::IO, ::Type{Marker})` | io | the stream | — | survivor(io) | | |
| 805 | `_contract_bound` | c | untyped, the component instance | param | rename | comp | |
| 806 | `_contract_bound` | a | the matched signature's third parameter | 806–808 | glance | | |
| 807 | `_contract_bound` | b | the unwrapped bound | 807–809 | glance | | |
| 829 | `_check_wires` | c | the component instance | 829–838 | rename | comp | |
| 829 | `_check_wires` | t | the tier | 829–838 | rename | tier | |
| 839 | `_check_wires` (`at`) | S | local-fn param, the activation scalar to declare at | param | rename | scalar | not the file's `T`; see Questions |
| 866 | `_check_wires` | f | nested `for`, the consuming face name | 866–870 | glance | | |
| 887 | `_check_wires` | k | `for`-loop var, the co-consumer's position | 887–892 | glance | | |
| 888 | `_check_wires` | k | lambda arg, the co-consumer's position | 888–888 | glance | | |
| 906 | `_walking_leaf` | i | the position of the walking leaf | 906–909 | glance | | |
| 907 | `_walking_leaf` | k | lambda arg, the leaf position tested | 907–907 | glance | | |
| 923 | `activation` | b | `::Build`, the build artifact | param | rename | artifact | **collision** — see Collisions |
| 939 | `warnings(::Build)` | b | `::Build`, the build artifact | param | rename | artifact | same collision |
| 994 | `_mstores` (closure) | m | the component's `init_m` | — | survivor(m) | | |
| 1003 | `_workspace` | c | untyped, the component instance | param | rename | comp | |
| 1003 | `_workspace` | t | `::Tier`, the tier | param | rename | tier | |
| 1043 | `probe_stage2` (`in_values`) | d | local-fn param, the component's `Decls` | param | rename | decl | see Collisions |
| 1074 | `probe_stage2` | c | the component instance | 1074–1086 | rename | comp | |
| 1074 | `probe_stage2` | d | the component's `Decls` | 1074–1086 | rename | decl | see Collisions |
| 1074 | `probe_stage2` | t | the tier | 1074–1086 | rename | tier | |
| 1096 | `probe_stage2` | c | the component instance | 1096–1111 | rename | comp | |
| 1098 | `probe_stage2` | d | the component's `Decls` | 1098–1112 | rename | decl | see Collisions |
| 1128 | `_probe_direct!` | c | the component instance | 1128–1150 | rename | comp | |
| 1128 | `_probe_direct!` | d | the component's `Decls` | 1128–1150 | rename | decl | see Collisions |
| 1133 | `_probe_direct!` | u | the input bundle | 1133–1137 | survivor(u) | | |
| 1163 | `_check_state_write` | x⁺ | the returned state | param | survivor(x) | | spec's `x⁺` (§9.3/§13.5, `spec.md:594`) |
| 1163 | `_check_state_write` | x | `::NamedTuple`, the declared state | param | survivor(x) | | |
| 1175 | `_check_state_write` | k | `for`-loop var, the state field name | 1175–1181 | glance | | single wrapped statement |
| 1203 | `probe_events` | c | the component instance | 1203–1220 | rename | comp | |
| 1203 | `probe_events` | d | the component's `Decls` | 1203–1211 | rename | decl | see Collisions |
| 1208 | `probe_events` | u | the input bundle | 1208–1211 | survivor(u) | | |
| 1214 | `probe_events` | σ | the guard's numeric/boolean sample | — | survivor(σ) | | |
| 1238 | `_check_handler` | d | `::Decls`, the component's `Decls` | param | rename | decl | no local collision in this function; kept for consistency |
| 1238 | `_check_handler` | c | untyped, the component instance | param | rename | comp | |
| 1244 | `_check_handler` | m₀ | the component's declared initial modes | 1244–1274 | survivor(m) | | `m` with a subscript-0, "initial" reading |
| 1249 | `_check_handler` | k | `for`-loop var, the returned key | 1249–1251 | glance | | |
| 1264 | `_check_handler` | k | `for`-loop var, the returned mode field name | 1264–1276 | rename | field | |
| 1302 | `establish_defaults!` | d | the component's `Decls` | 1302–1309 | rename | decl | see Collisions |
| 1304 | `establish_defaults!` | l | `for`-loop var, the leaf value | 1304–1306 | glance | | |
| 1379 | `compile` | D_c, Φ_c, Δt_c | the per-component gate triple | — | survivor(D)/(Φ)/(Δt) | | `_c` suffix, matches `y_x`/`y_s`'s compound-survivor pattern |
| 1385 | `compile` | d | comprehension var, the component's `Decls` | 1385–1385 | glance | | |
| 1390 | `compile` | L | comprehension var, the leaf eltype | 1390–1390 | glance | | `for (L,_) in layout.sizes` |
| 1391 | `compile` | L, n | comprehension vars, the leaf eltype / buffer length | 1391–1392 | glance | | `for (L,n) in layout.sizes` |
| 1394 | `compile` | r | comprehension var, the component's `x` block | 1394–1394 | glance | | |
| 1402 | `compile` (`addr_group`) | n | comprehension var, the address-group field name | 1402–1402 | glance | | |
| 1404 | `compile` (`in_group`) | d | local-fn param, the component's `Decls` | param | rename | decl | collides with the plural `decls` local in `compile` |
| 1431 | `compile` | c | the component instance | 1431–1436 | glance | | span = 5, borderline |
| 1433 | `compile` | d | the component's `Decls` | 1433–1435 | glance | | |
| 1445 | `compile` | c | the component instance | 1445–1450 | glance | | span = 5, borderline |
| 1445 | `compile` | d | the component's `Decls` | 1445–1450 | glance | | span = 5, borderline |
| 1460 | `compile` | c | the component instance | 1460–1471 | rename | comp | |
| 1460 | `compile` | d | the component's `Decls` | 1460–1466 | rename | decl | see Collisions |
| 1460 | `compile` | t | the tier | 1460–1465 | glance | | span = 5, borderline |
| 1488 | `compile` | c | the component instance | 1488–1498 | rename | comp | |
| 1492 | `compile` | d | the component's `Decls` | 1492–1499 | rename | decl | see Collisions |
| 1520 | `compile` (`ev_bodies`) | i | comprehension var, the event entry's position | 1520–1520 | glance | | |
| 1522 | `compile` (`proj_bodies`) | e | comprehension var, the projection entry | 1522–1522 | glance | | |
| 1552 | `_probe_input` | P | untyped, the declared input type | param | rename | declared | not the type parameter `P` |
| 1556 | `_probe_input` | p | lambda arg, the connection pair | 1556–1556 | glance | | |
| 1557 | `_probe_input` | v | the fed value | 1557–1565 | rename | value | |
| 1558 | `_probe_input` | r | lambda arg, the root-input pair | 1558–1558 | glance | | |
| 1570 | `_check_derivative` | ẋ | the returned derivative | param | survivor(x) | | spec's `ẋ` |
| 1570 | `_check_derivative` | x | `::NamedTuple`, the declared state | param | survivor(x) | | |
| 1582 | `_check_derivative` | k | `for`-loop var, the state field name | 1582–1588 | glance | | single wrapped statement |
| 1597 | `_check_update` | s⁺ | the returned successor store | param | survivor(s) | | spec's `s⁺` |
| 1597 | `_check_update` | s | `::NamedTuple`, the declared store | param | survivor(s) | | |

### `src/executor.jl`

(Rows covered by a Convention above — `e`, `t::Tuple`, `g::Gated`,
`c::Chunk`, `b::PhaseBody` — are not repeated here.)

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 26 | `_phase!` | c | `::ExecutionCursor`, the execution cursor | param | rename | cursor | |
| 112 | `_bundle_expr` | n | `do`-block arg, the bundle field name | 113–125 | rename | field | same proposal as `build.jl`'s analogous case |
| 153 | `run!(::StageEntry,...)` | y | the stage's returned bundle | — | survivor(y) | | |
| 159 | `run!(::RHSEntry,...)` | ẋ | the returned derivative | — | survivor(x) | | |
| 280 | `EventSet(...)` outer constructor | n | the event count | 280–284 | glance | | whole constructor body is 5 lines |
| 304 | `_guard_walk` | e | local (`e = t[1]`), the entry under test | 304–307 | glance | | distinct from the file's `e`-convention parameter, which here is `t`'s head |
| 306 | `_guard_walk` | σ | the guard's numeric sample | — | survivor(σ) | | |
| 318 | `_fire_walk` | e | local (`e = t[1]`), the firing entry | 318–322 | glance | | |
| 350 | `_merge_modes!` (`@generated`) | k | `for`-loop var, the mode field name | 350–361 | rename | field | same proposal as the file's other field-name loops |

### `src/store.jl`

(Rows covered by the `b`/`a` Convention above are not repeated here.)

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 44 | `gather` (`@generated`) | k, L | comprehension vars, the leaf position / leaf eltype | 44–44 | glance | | `for (k,L) in enumerate(Ls)` |
| 55 | `scatter!` (`@generated`) | v | untyped, the value scattered | param | rename | value | |
| 57 | `scatter!` (`@generated`) | k, L | comprehension vars, same as `gather`'s | 57–57 | glance | | |
| 74 | `gather_group` (`@generated`) | i | comprehension var, the field position | 74–74 | glance | | |
| 86 | `scatter_group!` (`@generated`) | y | `::NamedTuple{Ys}`, the scattered values | param | survivor(y) | | |
| 93 | `scatter_group!` (`@generated`) | i | `for`-loop var, the field position | 93–100 | rename | pos | 9-line loop body |
| 93 | `scatter_group!` (`@generated`) | n | `for`-loop var, the field name | 93–100 | rename | field | |
| 94 | `scatter_group!` (`@generated`) | P | local, the cell's declared type | 94–99 | glance | | not the type parameter `P` — a plain local holding a `Type` |
| 95 | `scatter_group!` (`@generated`) | V | local, the returned field's type | 95–99 | glance | | |
| 129 | `Clock{T}(t₀::Float64)` | t₀ | `::Float64`, the run's origin | param | survivor(t) | | `Clock`'s own field; no ambiguity here (contrast `stepper.jl`, see Questions) |

### `src/stepper.jl`

(Rows covered by the `m` Convention above are not repeated here.)

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 47 | `RK4(::Type{T}, n::Int)` | n | `::Int`, the buffer length | param | rename | nx | not the survivor `N` (a type-parameter tuple length only) |
| 51 | `step!(m::RK4,...)` | x, ẋ | the flat state / derivative buffers | — | survivor(x) | | |
| 51 | `step!(m::RK4,...)` | x₀ | destructured, the segment-start state | 51–65 | survivor(x) | | matches spec's `xₙ` |
| 51 | `step!(m::RK4,...)` | k₁, k₂, k₃, k₄ | destructured, the four RK4 stage derivatives | 51–65 | rename | stage1..stage4 | mirrors the out-of-scope struct field spelling — see Questions |
| 52 | `step!(m::RK4,...)` | t₀ | the time at the start of this step | 52–60 | survivor(t) (tentative) | | same spelling as `Clock.t₀`, a different quantity — see Questions |
| 64 | `step!(m::RK4,...)` | i | `for`-loop var, the buffer position | 64–65 | glance | | |
| 83 | `Heun(::Type{T}, n::Int)` | n | `::Int`, the buffer length | param | rename | nx | |
| 87 | `step!(m::Heun,...)` | x, ẋ | the flat state / derivative buffers | — | survivor(x) | | |
| 87 | `step!(m::Heun,...)` | x₀ | destructured, the segment-start state | 87–96 | survivor(x) | | |
| 87 | `step!(m::Heun,...)` | k₁, k₂ | destructured, the two Heun stage derivatives | 87–96 | rename | stage1, stage2 | same note as RK4's |
| 88 | `step!(m::Heun,...)` | t₀ | the time at the start of this step | 88–92 | survivor(t) (tentative) | | see Questions |
| 95 | `step!(m::Heun,...)` | i | `for`-loop var, the buffer position | 95–96 | glance | | |
| 103 | `_advance!` | x | the buffer written | param | survivor(x) | | |
| 103 | `_advance!` | x₀ | the segment-start state | param | survivor(x) | | |
| 103 | `_advance!` | k | untyped, the derivative sample scaled | param | rename | deriv | generic — not tied to a stage index |
| 104 | `_advance!` | i | `for`-loop var, the buffer position | 104–105 | glance | | |
| 122 | `dense!` | x̂ | the written interpolant | param | survivor(x) | | |
| 122 | `dense!` | x₁, ẋ₁ | the arrival state / derivative | param | survivor(x) | | |
| 122 | `dense!` | θ | `::Float64`, the interpolation parameter | param | survivor(θ) | | |
| 122 | `dense!` | h′ | untyped, the segment width | param | survivor(h) | | spec's `h′` |
| 123 | `dense!` | x₀, ẋ₀ | destructured, the segment-start state/derivative | 123–130 | survivor(x) | | |
| 124 | `dense!` | θ², θ³ | powers of θ | 124–130 | survivor(θ) | | |
| 125 | `dense!` | b₀ | the left Hermite basis weight | 125–130 | glance | | not spec notation, but short-lived — see Questions |
| 126 | `dense!` | b₁ | the right Hermite basis weight | 126–130 | glance | | |
| 127 | `dense!` | d₀ | the left Hermite derivative weight | 127–130 | glance | | |
| 128 | `dense!` | d₁ | the right Hermite derivative weight | 128–130 | glance | | |
| 129 | `dense!` | i | `for`-loop var, the buffer position | 129–130 | glance | | |

## Collisions

- **`activation(b::Build,...)` / `warnings(b::Build)`** (`build.jl:923,939`)
  — the natural name for `b`, `build`, would shadow the module-level
  `build` function — the brief's own worked example. Alternative chosen:
  `artifact`, matching the type's own description ("the deployment-free
  product of the build pipeline").
- **`d` → `decl`** — chosen throughout `build.jl` specifically to avoid
  colliding with the plural `decls::Vector{Decls}` parameter or local
  present in the same or an enclosing scope. Affected sites: `state_decls`,
  `probe_stage1`, `_bundle_values`, `_homes`, `probe_stage2`'s `in_values`
  and its two per-component loops (state-update and `state_projection`),
  `_probe_direct!`, `probe_events`, `establish_defaults!`, `compile`'s
  `in_group` and its update-law and event loops. (`_check_handler`'s
  `d::Decls` has no such local collision but keeps `decl` for consistency
  with every other `Decls`-typed binding in the file.)

## Neighbours

- `P_F`/`V_F`/`P_M`/`V_M`, `ins_F`/`outs_F`/`ins_M`/`outs_M`
  (`build.jl:822–897`, `_check_wires`/`_root_input_cell`) — the
  Float64-clause/Marker-clause type pairs; all multi-character.
- `ws` (2-letter) is reused for two things unrelated to the survivor
  workspace: the build's warning list (`build.jl:724`, `ws = Diagnostic[]`)
  and the cycle diagnostic's wire list (`build.jl:433`,
  `ws = Tuple{Int,Int,String,String}[]`).
- `vt` (`build.jl:226`, `classify_tier`'s vote loop) — "the vote's tier."
- `pi` (`build.jl`, several sites) — "the producer's component index."
- `Ls` (`build.jl:530` `place!`; `store.jl:43,56`) — "the leaf eltypes
  list."
- `lp`/`lv` (`build.jl:906`, `_walking_leaf`) — "the two leaf-type lists
  compared."
- `dt` (`stepper.jl:103`, `_advance!`) — an ASCII stand-in for the
  survivor `Δt`, spelled differently from it.
- `es`/`gs` (`build.jl:1517` `compile`'s local `body(es,gs)`;
  `executor.jl:509` `chunked_body`'s local `chunks(es)`) — "entries"/
  "gates" abbreviated.

## Questions

- `t₀` local to `stepper.jl`'s two `step!` methods means "the time at the
  start of this step" (spec's `tₙ`), but reuses the exact spelling of
  `store.jl`'s `Clock.t₀`, which means "the run's origin anchor" — a
  different quantity (§10.4 vs. §12.6). Is this a survivor by virtue of
  the `t`-family, or does it need its own name (`t_start`?) so the two
  `t₀`s are not read as the same thing across files?
- Proposing `entry` for `executor.jl`'s compiled-entry parameter `e`
  (Conventions) reuses a word `build.jl` already uses pervasively for
  `ComponentEntry` (`for (ci, entry) in enumerate(structure.components)`).
  Within either single file there is no technical collision, but is the
  word overloaded enough across the pair of files to warrant something
  more specific for `executor.jl` (`xentry`? `slot`?) instead?
- `dense!`'s Hermite basis weights `b₀,b₁,d₀,d₁` (`stepper.jl:125–128`) are
  classified `glance` purely on span; unlike `x̂,θ,h′` in the same function
  they are not spec notation at all — this implementation's own choice.
  Should "not a spec symbol" be its own trigger for a permanent name
  regardless of span, or is the short, single-block span reason enough to
  leave them?
- `_check_wires`'s local helper `at(fn, S)` (`build.jl:839`) takes a bare,
  untyped `S` for the activation scalar to declare at (`Float64` or
  `Marker`), rather than the file's usual type-parameter `T`. Is `S` a
  genuine second, independent value-level "scalar" role (proposal:
  `scalar`), or does it really stand in for `T` and deserve that same word
  once `T`'s type-parameter form is out of the picture?

## Coverage

Every function, method, closure, local function and `do`-block in all four
files was read and tabulated (or excluded per the brief's out-of-scope
categories: type parameters, struct fields, keyword-argument names). No
gaps.
