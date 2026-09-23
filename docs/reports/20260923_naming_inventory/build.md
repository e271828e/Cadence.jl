# Naming inventory: src/build.jl

Tip: f64b9f3. Sites flagged: 325. Renames: 174. Collisions: 4. Roster proposals: 6.

Counts are table rows; a row groups names bound together on one line (`ppath`, `pport`). Rows by code: rename 174, keep:spec 39, keep:index 32, keep:glance 28, keep:typeparam 25, roster? 20, collision 4, keep:roster 3.

## Letters with more than one meaning in this file

- `d`: a component's `Decls` (most sites), the carried `UserCodeFraming` (`at_component`), an `AlgebraicCycle` (`_cycle_diagnostics`) → all renamed below: `decl`, `framing`, `cycle`
- `t`: the tier at every site; the rules reserve `t` for time, which here appears only as the bundle symbol `:t` → every tier site renamed `tier`
- `e`: a caught exception (catch sites and `_passes_frame`), a declared input type (`_root_input_cell` lambda), a projection entry (`compile` comprehension) → the two non-exception sites renamed; long catch blocks take `exception`
- `v`: a declared field value, a graph node (`_tarjan`, `_cluster_walk`, `_cycle_diagnostics`), a vote (`classify_tier` lambdas), a synthesized probe value, a probed input → the node sites take `node`/`ci`, the value sites `value`; votes and one-line consumptions stay
- `w`: a successor and, in the same closure, the popped member (`_tarjan`) → `successor`, `member`
- `f`: the `at_component` thunk, a face (`_cycle_diagnostics`, `_root_input_cell`, `_check_wires`) → `thunk`, `face_name`, `consumer_face`
- `p`: a port string (`_cycle_diagnostics`) and a pair (lambdas) → the port site renamed `port_name`; lambda pairs stay
- `P`: a type parameter for a port type, a local cell type (`cell_layout` line 548), a value parameter (`_probe_input`) → the local and the value parameter renamed `cell_type`, `entry_type`
- `n`: a bundle field name, the component count, a component's leaf count, a buffer length, a port name → the first three renamed `field`, `ncomponents`, `width`; generator and lambda sites stay
- `k`: the pre-loop diagnostics count, a position, a field name, a returned key → the first and the last two renamed `recorded`, `field`, `key`; position sites stay
- `i`: a loop index, the decider's position (`classify_tier`), a root-input index (`_root_input_cell`), the offending leaf (`_walking_leaf`) → the three non-loop sites renamed
- `ws`: a workspace keyword (`_bundle_values`), the cluster's wires (`_cycle_diagnostics`), the build's warning list (`build`) → `wires`, `raised_warnings`; the keyword stays as the bundle's field name
- `comp`: the roster's component instance, and one strongly connected component in `_tarjan` → the `_tarjan` site renamed `scc`

## `_passes_frame(e)` — line 22

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 22 | `e` | param | the caught exception | keep:glance | — |

## `invoke_declaration(fn, c, args...)` — line 35

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 35 | `fn` | param | the declaration function invoked | roster? | `fn` (see Roster proposals) |
| 35 | `c` | param | the component instance | rename | `comp` |
| 38 | `e` | catch | the exception out of the declaration | keep:glance | — |

## `invoke_probed(fn, family::Symbol, path::String, c, t::Tier, bundle::NamedTuple)` — line 50

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 50 | `fn` | param | the probed stage function | roster? | `fn` |
| 50 | `c` | param | the component instance | rename | `comp` |
| 50 | `t` | param | the tier | rename | `tier` |
| 53 | `e` | catch | the exception out of the stage; read over nine lines (`e.type`, `e.field`, `cause = e`) | rename | `exception` |

## `_inputs_spelling(b::NamedTuple)` — line 68

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 68 | `b` | param | the probed bundle | rename | `bundle` (the name `invoke_probed` passes it under) |
| 71 | `e` | catch | the exception out of the author's `show` | keep:glance | — |

## `at_component(f, path::String)` — line 79

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 79 | `f` | param (`do`-block target) | the per-component body to run | rename | `thunk` |
| 82 | `e` | catch | the exception out of the body; read over six lines | rename | `exception` |
| 84 | `d` | local | the carried `UserCodeFraming`; `d` is a `Decls` elsewhere in the file | rename | `framing` |

## `state_decls(d::Decls, t::Tier)` — line 102

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 102 | `d` | param | one component's declarations | rename | `decl` |
| 102 | `t` | param | the tier | rename | `tier` |

## `declarations(c, t::Tier, ::Type{T})` — line 110

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 110 | `c` | param | the component instance | rename | `comp` |
| 110 | `t` | param | the tier | rename | `tier` |
| 110 | `T` | type param | the activation scalar | keep:typeparam | — |

## `check_state_leaves(path::String, c, diags::Vector{Diagnostic})` — line 136

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 136 | `c` | param | the component instance | rename | `comp` |
| 137 | `v` | `for` destructure | one `init_x` field's declared value | rename | `value` |
| 138 | `L` | local | that field's leaf eltype, read on four lines | rename | `leaf_eltype` (`eltype` is called in the line that binds it) |

## `check_store_form(path::String, c, diags::Vector{Diagnostic})` — line 151

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 151 | `c` | param | the component instance | rename | `comp` |
| 152 | `ok` | local | whether every store is a `NamedTuple`, the return value | rename | `readable` (the comment's word: "whether this primitive can be read further") |
| 153 | `fn` | `for` destructure | the store's declaration function | roster? | `fn` |
| 154 | `v` | local | the declared store | rename | `contents` (as in `check_stores`, where `store` holds the store's symbol) |

## `check_stores(path::String, c, diags::Vector{Diagnostic})` — line 163

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 163 | `c` | param | the component instance | rename | `comp` |
| 164 | `nt` | `for` destructure | the declared store, a `NamedTuple` | rename | `contents` (`store` already holds the store's symbol) |
| 166 | `v` | `for` destructure | one store field's value | rename | `value` |

## `_form(t::Tier)` — line 180

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 180 | `t` | param | the tier | rename | `tier` |

## `classify_tier(path::String, c, diags::Vector{Diagnostic})` — line 186

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 186 | `c` | param | the component instance | rename | `comp` |
| 194 | `fn` | `for` destructure | the contract declaration function | roster? | `fn` |
| 201 | `state` | local | the populated store's name (`:init_x`, `:init_s`) or `nothing` | collision | `state_store` (`state` is `sim.jl:1813`'s accessor) |
| 204, 210 | `i` | local | the decider's position in `votes`, read at line 224; not a loop index | rename | `decider` |
| 204, 210 | `v` | lambda param | one vote | keep:glance | — |
| 214 | `v` | comprehension | one vote | keep:glance | — |
| 224 | `t` | local | the announced tier, read to line 239 | rename | `tier` |
| 225 | `k` | local | the diagnostics count before the vote loop; not a loop index | rename | `recorded` |
| 226 | `vt` | `for` destructure | one vote's tier | rename | `vote_tier` |

## `probe_stage1(structure::Structure, decls::Vector{Decls}, …)` — line 257

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 258 | `wss` | param | the per-component workspaces | rename | `workspaces` |
| 258 | `mstores` | param | the per-component mode stores | keep:spec | — (derivative of `m`, like `x_offs`; `sstores` beside it at line 1300) |
| 258 | `T` | type param | the activation scalar | keep:typeparam | — |
| 259 | `ci` | `do` destructure | the component index | keep:index | — |
| 260 | `c` | destructure | the component instance, read over sixteen lines | rename | `comp` |
| 260 | `d` | destructure | the component's declarations | rename | `decl` |
| 265 | `bn` | local | the stage's bundle field names | rename | `bundle_fields` (`bundle_names` is the function called on the same line) |
| 266 | `y` | local | the stage-1 return | keep:spec | — |

## `_bundle_values(bn, d::Decls, u, y1, ::Type{T}; y, ws, m, Δt)` — line 280

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 280 | `bn` | param | the bundle field names | rename | `bundle_fields` |
| 280 | `d` | param | the component's declarations | rename | `decl` |
| 280 | `u` | param | the input values | keep:spec | — |
| 280 | `y1` | param | the stage-1 outputs fed as `y_x`/`y_s` | keep:spec | — (derivative of `y`) |
| 280 | `T` | type param | the activation scalar | keep:typeparam | — |
| 280 | `y` | keyword | the full outputs | keep:spec | — |
| 280 | `ws` | keyword | the workspace | keep:spec | — (the bundle's own field name `:ws`, matched at line 290; see Questions) |
| 281 | `m` | keyword | the probe-scoped mode `Ref` | keep:spec | — |
| 281 | `Δt` | keyword | the probe's placeholder step | keep:spec | — |
| 282 | `vals` | local | the bundle's field values | rename | `field_values` (`values` is a Base function the file calls) |
| 282 | `n` | `do` param | one bundle field name, read ten times across the arm chain | rename | `field` |

## `_check_ports(path, stage, y::NamedTuple, outs::NamedTuple, ::Type{T})` — line 299

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 299 | `y` | param | the stage's return | keep:spec | — |
| 299 | `outs` | param | the declared output types, `Decls.outs` | roster? | `outs` |
| 299 | `T` | type param | the activation scalar | keep:typeparam | — |
| 301 | `v` | `for` destructure | one returned port's value | rename | `value` |

## `_embed(::Type{P}, v, ::Type{T})` — line 326

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 326 | `P` | type param | the declared port type | keep:typeparam | — |
| 326 | `v` | param | the returned value to embed; three-line method | keep:glance | — |
| 326 | `T` | type param | the activation scalar | keep:typeparam | — |
| 328 | `lt`, `l` | comprehension | one leaf's declared type and value | keep:glance | — |

## `_embed_ports(y::NamedTuple, outs::NamedTuple, ::Type{T})` — line 331

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 331 | `y` | param | the stage's return | keep:spec | — |
| 331 | `outs` | param | the declared output types | roster? | `outs` |
| 331 | `T` | type param | the activation scalar | keep:typeparam | — |
| 332 | `n` | lambda param | one port name | keep:glance | — |

## `_homes(d::Decls, t::Tier, m)` — line 344

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 344 | `d` | param | the component's declarations | rename | `decl` |
| 344 | `t` | param | the tier | rename | `tier` |
| 344 | `m` | param | the probe-scoped mode `Ref` or `nothing` | keep:spec | — |

## `_outputs(structure::Structure, decls::Vector{Decls}, stage1::Vector, mstores::Vector)` — line 364

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 365 | `mstores` | param | the per-component mode stores | keep:spec | — |
| 366 | `n` | local | the component count, read on five lines and in two loops | rename | `ncomponents` |
| 367–370, 384 | `ci` | comprehension | the component index | keep:index | — |
| 368 | `names1` | local | per component, the stage-1 port names | rename | `stage1_names` |
| 369 | `names2` | local | per component, the stage-2 port names | rename | `stage2_names` |
| 370 | `deps` | local | per consumer, the producers it still waits on | rename | `dependencies` |
| 372 | `ci` | `for` destructure | the consumer's component index | keep:index | — |
| 374 | `ppath`, `pport` | `for` destructure | the producer's path and port | rename | `producer_path`, `producer_port` |
| 376 | `pi` | local | the producer's component index; shadows `Base.pi` | rename | `producer_ci` |
| 387 | `ci` | local | the component Kahn places next | keep:roster | — |
| 390 | `cj` | `for` | a component still unplaced | keep:index | — |
| 401 | `ci` | comprehension | the component index | keep:index | — |

## `_cycle_diagnostics(structure::Structure, edges::…, …)` — line 415

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 417 | `mstores` | param | the per-component mode stores | keep:spec | — |
| 419 | `succ` | local | per node, its successors inside the residue | rename | `successors` |
| 420 | `ci` | `for` | a residue component | keep:index | — |
| 420 | `pi` | `for` destructure | the producer's component index; shadows `Base.pi` | rename | `producer_ci` |
| 423 | `v` | `for` | a residue component index | rename | `ci` (the same value line 420 calls `ci`) |
| 428 | `scc` | `for` | one strongly connected component | roster? | `scc` |
| 430 | `inscc` | local | the cluster's members as a set | rename | `member_set` |
| 432 | `pos` | local | component index → its position in the walk order | rename | `position` |
| 432 | `i`, `ci` | comprehension | position and component index | keep:index | — |
| 433 | `ws` | local | the cluster's wires as sortable tuples; `ws` is a workspace at line 280 | rename | `wires` |
| 434 | `ci` | `for` | a cluster member | keep:index | — |
| 434 | `pi` | `for` destructure | the producer's component index | rename | `producer_ci` |
| 434 | `pport` | `for` destructure | the producer's port | rename | `producer_port` |
| 438 | `ci` | local function param | the component index | keep:index | — |
| 439 | `d` | local | the cluster's `AlgebraicCycle`, read three lines below; `d` is a `Decls` elsewhere | rename | `cycle` |
| 439 | `ci` | comprehension | the component index | keep:index | — |
| 440 | `a`, `b`, `p`, `f` | comprehension destructure | producer and consumer positions, port and face strings; `p` and `f` mean a pair and a function elsewhere | rename | `producer_position`, `consumer_position`, `port_name`, `face_name` |
| 446 | `d` | comprehension destructure | one cluster's diagnostic | rename | `cycle` |

## `_tarjan(nodes::Vector{Int}, succ::Vector{Vector{Int}})` — line 450

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 450 | `succ` | param | per node, its successors | rename | `successors` |
| 451 | `sccs` | destructure | the components found, the return value | roster? | `sccs` |
| 452 | `v` | local function param | the node `strong!` visits, read eleven times over twenty lines | rename | `node` |
| 456 | `w` | `for` | a successor of `node` | rename | `successor` |
| 465 | `comp` | local | the component being popped off the stack; `comp` is the roster's component instance | rename | `scc` |
| 467 | `w` | local | the node popped; a second meaning for `w` in one closure | rename | `member` |
| 475 | `v` | `for` | a node to start from | rename | `node` |

## `_cluster_walk(scc::Vector{Int}, succ::Vector{Vector{Int}}, inscc::Set{Int})` — line 482

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 482 | `scc` | param | the cluster | roster? | `scc` |
| 482 | `succ` | param | per node, its successors | rename | `successors` |
| 482 | `inscc` | param | the cluster's members as a set | rename | `member_set` |
| 484 | `v` | local function param | the node `visit!` visits | rename | `node` |
| 487 | `w` | `for` | a successor of `node` | rename | `successor` |

## `cell_layout(structure::Structure, decls::Vector{Decls}, ::Type{T})` — line 514

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 514 | `T` | type param | the activation scalar | keep:typeparam | — |
| 515 | `addr` | local | (path, port or face) → cell address; the `Layout` field of the same name | roster? | `addr` (singular of the roster's `addrs`) |
| 517 | `offs` | local | per leaf eltype, the next free offset | rename | `offsets` |
| 523 | `P` | type param of `place!` | the port type placed | keep:typeparam | — |
| 524 | `mp` | local | `mutable_position(P)`'s hit, or `nothing` | rename | `mutable_site` |
| 530 | `lts` | local | the port type's leaf types | rename | `leaves` (`leaf_types` is called on the binding line) |
| 535 | `Ls` | local | the port type's leaf eltypes | rename | `eltypes` |
| 536 | `L` | generator | one leaf eltype | keep:glance | — |
| 537 | `L` | `for` | one leaf eltype, one-line body | keep:glance | — |
| 542 | `d` | `for` destructure | the component's declarations | rename | `decl` |
| 543 | `port` | `for` destructure | one declared port name | collision | `port_name` (`port` is `sim.jl:1806`'s and `dataplane.jl:598`'s accessor; not called here; see Questions) |
| 543 | `P` | `for` destructure | that port's declared type, consumed on the next line | keep:glance | — |
| 547 | `i` | `for` | the root input's index | keep:index | — |
| 548 | `P` | local | the root input's cell type at this activation, read over twenty lines | rename | `cell_type` |
| 554 | `L` | lambda param | one leaf type | keep:glance | — |
| 564 | `v` | local (`try`) | the root input's synthesized probe value | rename | `value` |
| 566 | `e` | catch | the exception out of `probe_value` | keep:glance | — |
| 577 | `L`, `n` | comprehension destructure | leaf eltype and buffer length | keep:glance | — |
| 577 | `p` | lambda param | one size pair | keep:glance | — |
| 580 | `nx` | destructure | the running flat `x` length | keep:spec | — |
| 581 | `d` | `for` destructure | the component's declarations | rename | `decl` |
| 582 | `n` | local | the component's `x` leaf count, read on two lines | rename | `width` (`nleaves` is called on the binding line) |

## `_root_input_cell(structure::Structure, decls::Vector{Decls}, i::Int, face::Symbol, ::Type{T})` — line 594

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 594 | `i` | param | the root input's index; a parameter, not a loop index | rename | `root_index` |
| 595 | `T` | type param | the activation scalar | keep:typeparam | — |
| 596 | `P_F` | local | the root-input type the structure step fixed | keep:spec | — (the wire pass's `P_F`, line 883; the comment at line 900 spells it) |
| 597 | `walk` | local | that type with every leaf following `T` | rename | `walked_type` (`walk` is a verb; `_walk` is a function) |
| 598 | `entries` | local | every consumer's declared input type for this face | rename | `consumer_types` |
| 598 | `ci` | generator | the component index | keep:index | — |
| 599 | `f` | generator destructure | the consumer's face | rename | `consumer_face` (`f` is a thunk at line 79) |
| 600 | `e` | lambda param | one consumer's declared input type; `e` is an exception elsewhere | rename | `input_type` |

## `input_addr(layout::Layout, conns::…, face::Symbol)` — line 604

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 605 | `p` | lambda param | one connection pair | keep:glance | — |

## `build(root::AbstractComponent; activations::Tuple = ())` — line 720

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 724 | `ws` | local | the build's warning list, bound to `BUILD_WARNINGS`; `ws` is a workspace at line 280 | rename | `raised_warnings` (`warnings` is a package function) |
| 745 | `A` | `for` | one eager activation's scalar type | rename | `scalar` |
| 750 | `e` | catch | the exception leaving the build | keep:glance | — |

## `_check_event_declarations(draft::StructureDraft, diags::Vector{Diagnostic})` — line 769

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 773 | `c` | `for` destructure | the component instance | rename | `comp` |
| 775 | `ev` | `for` destructure | one declared event | rename | `event` |
| 781 | `fn` | `for` destructure | the event's guard or handler | roster? | `fn` |

## `Base.show(io::IO, ::Type{Marker})` — line 800

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 800 | `io` | param | the output stream; one-line method, Base's own spelling | keep:glance | — |

## `_contract_bound(fn, c)` — line 805

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 805 | `fn` | param | the contract declaration function | roster? | `fn` |
| 805 | `c` | param | the component instance | rename | `comp` |
| 806 | `a` | local | the matched method's second argument type, a return value | rename | `argument_type` |
| 807 | `b` | local | that type unwrapped | rename | `unwrapped` |
| 809 | `tv` | local | `Type{…}`'s parameter, a `TypeVar` or a type | rename | `parameter` |

## `_check_wires(draft::StructureDraft, conns::…, diags::Vector{Diagnostic})` — line 822

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 829 | `ci` | `for` destructure | the component index | keep:index | — |
| 829 | `c` | `for` destructure | the component instance | rename | `comp` |
| 829 | `t` | `for` destructure | the component's tier | rename | `tier` |
| 831 | `fn` | `for` | the contract declaration function | roster? | `fn` |
| 839 | `at` | local function | each component's contract evaluated at a scalar | collision | `contracts_at` (`at` is `conditions.jl:92`'s; not called in this scope) |
| 839 | `fn` | local function param | the contract declaration function | roster? | `fn` |
| 839 | `S` | local function param | the scalar the contract is evaluated at (`Float64` or `Marker`) | rename | `scalar` |
| 839 | `ci` | comprehension | the component index | keep:index | — |
| 841 | `ins_F`, `outs_F` | destructure | per component, declared input and output types at `Float64` | roster? | `ins`/`outs`, with the spec's `_F` suffix |
| 842 | `ins_M`, `outs_M` | destructure | the same at `Marker` | roster? | `ins`/`outs`, with the `_M` suffix |
| 843 | `ci` | `for` destructure | the consumer's component index | keep:index | — |
| 843 | `cs` | `for` destructure | the consumer's connections | rename | `consumer_conns` |
| 843 | `ppath`, `pport` | `for` destructure | the producer's path and port | rename | `producer_path`, `producer_port` (the diagnostics' own keyword names) |
| 845 | `pi` | local | the producer's component index; shadows `Base.pi` | rename | `producer_ci` |
| 847 | `P_F`, `V_F` | destructure | entry and producer types at `Float64` | keep:spec | — (D-238's spelling, the comment at line 900) |
| 855 | `P_M`, `V_M` | destructure | entry and producer types at `Marker` | keep:spec | — |
| 866 | `ci` | `for` destructure | the consumer's component index | keep:index | — |
| 866 | `cs` | `for` destructure | the consumer's connections | rename | `consumer_conns` |
| 866 | `f` | `for` destructure | the consumer's face, read four lines below | rename | `consumer_face` |
| 865 | `entries` | destructure | the consumers' declared types for this root face | rename | `consumer_types` (as in `_root_input_cell`) |
| 877 | `conc` | local | positions of the concrete consumer types | rename | `concrete` |
| 883 | `P_F` | local | the root-input type chosen | keep:spec | — |
| 884 | `k` | lambda param | a position in `concrete` | keep:glance | — |
| 887 | `k` | `for` | a consumer position | keep:index | — |

## `_walking_leaf(::Type{P}, ::Type{V})` — line 904

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 904 | `P`, `V` | type params | the entry and producer types | keep:typeparam | — |
| 906 | `lp`, `lv` | destructure | the leaf types of `P` and `V`, read on three lines | rename | `entry_leaves`, `producer_leaves` |
| 907 | `i` | local | the offending leaf's position; not a loop index | rename | `offending` |
| 907 | `k` | lambda param | a leaf position | keep:glance | — |

## `activation(b::Build, ::Type{T})` — line 923

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 923 | `b` | param | the build | rename | `built` (the noun `build` is the package's `build`; `built` is what `build` itself calls it, line 725) |
| 923 | `T` | type param | the scalar requested | keep:typeparam | — |
| 927 | `act` | local | the activation derived at `T` | rename | `derived` (`activation` is the enclosing function) |

## `warnings(b::Build)` — line 939

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 939 | `b` | param | the build | rename | `built`, as in `activation`; the other methods say `d::Deployment` and `sim::Simulation` (see Questions) |

## `_nominal(structure::Structure)` — line 949

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 955 | `mstores` | local | the probe-scoped mode stores | keep:spec | — |
| 956 | `wss` | local | the probe-scoped workspaces | rename | `workspaces` |

## `_declarations(structure::Structure, ::Type{T})` — line 968

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 968 | `T` | type param | the activation scalar | keep:typeparam | — |

## `_activate(structure::Structure, outputs::Outputs, nominal::Activation{Float64}, ::Type{T})` — line 978

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 979 | `T` | type param | the activation scalar | keep:typeparam | — |
| 981 | `mstores` | local | the probe-scoped mode stores | keep:spec | — |
| 982 | `wss` | local | the probe-scoped workspaces | rename | `workspaces` |

## `_mstores(structure::Structure)` — line 993

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 994 | `m` | local (inside the lambda) | the component's `init_m` store | keep:spec | — |

## `_workspaces(structure::Structure, ::Type{T})` — line 1000

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1000 | `T` | type param | the activation scalar | keep:typeparam | — |

## `_workspace(path::String, c, t::Tier, ::Type{T})` — line 1003

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1003 | `c` | param | the component instance | rename | `comp` |
| 1003 | `t` | param | the tier | rename | `tier` |
| 1003 | `T` | type param | the activation scalar | keep:typeparam | — |

## `_frozen(tier::Tier, ::Type{T})` — line 1014

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1014 | `T` | type param | the activation scalar | keep:typeparam | — |

## `probe_stage2(structure::Structure, decls::Vector{Decls}, …)` — line 1025

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1027 | `wss` | param | the per-component workspaces | rename | `workspaces` |
| 1027 | `mstores` | param | the per-component mode stores | keep:spec | — |
| 1027 | `T` | type param | the activation scalar | keep:typeparam | — |
| 1030 | `s1` | comprehension | one component's stage-1 product | keep:glance | — |
| 1039 | `ci` | `for` destructure | the component index | keep:index | — |
| 1043 | `ci` | local function param | the component index | keep:index | — |
| 1043 | `d` | local function param | the component's declarations | rename | `decl` |
| 1047 | `ci` | `for` | the component index, in execution order | keep:index | — |
| 1058, 1073, 1095 | `ci` | `for` destructure | the component index | keep:index | — |
| 1074 | `c` | destructure | the component instance | rename | `comp` |
| 1074 | `d` | destructure | the component's declarations | rename | `decl` |
| 1074 | `t` | destructure | the tier | rename | `tier` |
| 1078 | `bn` | local | the update law's bundle field names | rename | `bundle_fields` |
| 1079 | `vals` | local | the probe bundle handed to the update law | rename | `bundle` (the name `invoke_probed` takes it under) |
| 1096 | `c` | local | the component instance | rename | `comp` |
| 1098 | `d` | destructure | the component's declarations | rename | `decl` |

## `_probe_direct!(products::Vector{NamedTuple}, ci::Int, structure::Structure, …)` — line 1124

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1124 | `ci` | param | the component index | keep:roster | — |
| 1126 | `wss` | param | the per-component workspaces | rename | `workspaces` |
| 1126 | `mstores` | param | the per-component mode stores | keep:spec | — |
| 1126 | `T` | type param | the activation scalar | keep:typeparam | — |
| 1128 | `c` | destructure | the component instance | rename | `comp` |
| 1128 | `d` | destructure | the component's declarations | rename | `decl` |
| 1128 | `s1` | destructure | the component's stage-1 product, read on five lines; `s` is the spec's discrete state | rename | `stage1_product` |
| 1132 | `bn` | local | `output_direct`'s bundle field names | rename | `bundle_fields` |
| 1133 | `u` | local | the probed input values | keep:spec | — |
| 1136 | `y2` | local | the stage-2 return | keep:spec | — (derivative of `y`, as `y1` at line 280) |

## `_check_state_write(path, what, x⁺, x::NamedTuple, ::Type{T}; event)` — line 1163

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1163 | `x⁺` | param | the returned state | keep:spec | — |
| 1163 | `x` | param | the declared state | keep:spec | — |
| 1163 | `T` | type param | the activation scalar | keep:typeparam | — |
| 1175 | `k` | `for` | one state field name, read on five lines; not an index | rename | `field` (the keyword it fills) |

## `probe_events(structure::Structure, act::Activation{Float64})` — line 1197

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1197 | `act` | param | the nominal activation | rename | `nominal` (what `_nominal` passes, line 964) |
| 1199 | `mstores` | local | the probe-scoped mode stores | keep:spec | — |
| 1200 | `wss` | local | the probe-scoped workspaces | rename | `workspaces` |
| 1202 | `ci` | `for` destructure | the component index | keep:index | — |
| 1203 | `c` | destructure | the component instance | rename | `comp` |
| 1203 | `d` | destructure | the component's declarations | rename | `decl` |
| 1204 | `policy` | destructure | the component's policy register, event name → policy; the closure's `policy` at line 1215 is one event's | rename | `policies` (the `ComponentEvents` field it fills) |
| 1204 | `bn` | destructure | the event bundle's field names | rename | `bundle_fields` |
| 1205 | `evs` | local | the component's declared events | rename | `declared_events` (`events` holds the `Events` in `build`) |
| 1207 | `bn` | local | the event bundle's field names | rename | `bundle_fields` |
| 1208 | `u` | local | the probed input values | keep:spec | — |
| 1211 | `vals` | local | the probe bundle | rename | `bundle` |
| 1214 | `σ` | local | the guard's return | keep:spec | — |

## `_check_handler(path, name, ret, d::Decls, c)` — line 1238

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1238 | `ret` | param | the handler's return | rename | `returned` |
| 1238 | `d` | param | the component's declarations | rename | `decl` |
| 1238 | `c` | param | the component instance | rename | `comp` |
| 1244 | `m₀` | local | the declared mode store | keep:spec | — |
| 1249 | `k` | `for` | one returned key; not an index | rename | `key` (the keyword it fills) |
| 1264 | `k` | `for` | one returned mode field; not an index | rename | `field` (the keyword it fills) |

## `establish_defaults!(xbuf::Vector{T}, sstores::Vector, mstores::Vector, …)` — line 1300

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1300 | `xbuf` | param | the flat `x` buffer | roster? | `xbuf` (with `ẋbuf`, line 1376 on) |
| 1300 | `sstores`, `mstores` | param | the per-component discrete and mode stores | keep:spec | — |
| 1301 | `T` | type param | the buffer's scalar | keep:typeparam | — |
| 1302 | `off` | local | the running offset into the flat buffer | rename | `offset` |
| 1303 | `ci` | `for` destructure | the component index | keep:index | — |
| 1303 | `d` | `for` destructure | the component's declarations | rename | `decl` |
| 1305 | `l` | `for` | one `x` leaf value; reads as `1` | rename | `leaf_value` |

## `_activation_mismatch(what::String, ::Type{T}, ::Type{S})` — line 1362

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1362 | `T`, `S` | type params | the product's scalar and the executor's | keep:typeparam | — |

## `compile(build::Build, act::Activation{T}, sch; chunk_size::Int = 16, algorithm)` — line 1376

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1376 | `build` | param | the build compiled from | collision | `built` (`build` is the package's entry point; not called in this scope) |
| 1376 | `act` | param | the activation compiled | roster? | `act` (the noun `activation` is the package function, not called in this scope; `act` is also `Executor.act`'s field; see Questions) |
| 1376 | `sch` | param | the deployment's `Schedule` | rename | `schedule` (`Base.schedule` exists; the file never calls it) |
| 1376 | `T` | type param | the activation scalar | keep:typeparam | — |
| 1379 | `D_c`, `Φ_c`, `Δt_c` | destructure | the per-component gates | keep:spec | — |
| 1385 | `d` | comprehension destructure | the component's declarations | rename | `decl` |
| 1385 | `sstores` | local | the discrete stores | keep:spec | — |
| 1387 | `mstores` | local | the mode stores | keep:spec | — |
| 1388 | `wss` | local | the workspaces, read on five entry constructions | rename | `workspaces` |
| 1390 | `L` | generator destructure | one leaf eltype | keep:glance | — |
| 1391 | `L`, `n` | generator destructure | leaf eltype and buffer length | keep:glance | — |
| 1394 | `x_offs` | local | per component, its first flat `x` offset | keep:spec | — |
| 1394 | `r` | comprehension | one component's `x` range | keep:glance | — |
| 1395 | `nx` | local | the flat `x` length | keep:spec | — |
| 1396 | `xbuf` | local | the flat `x` buffer | roster? | `xbuf` |
| 1398 | `ẋbuf` | local | the flat derivative buffer | roster? | `ẋbuf` |
| 1403 | `n` | generator | one port name | keep:glance | — |
| 1404 | `ci` | local function param | the component index | keep:index | — |
| 1404 | `d` | local function param | the component's declarations | rename | `decl` |
| 1414 | `ci` | `for` destructure | the component index | keep:index | — |
| 1420 | `v` | `for` destructure | the root input's synthesized value, consumed on the next line | keep:glance | — |
| 1424, 1425 | `ci` | local function params | the component index | keep:index | — |
| 1430 | `ci` | `for` destructure | the component index | keep:index | — |
| 1431 | `c` | destructure | the component instance | rename | `comp` |
| 1433 | `d` | local | the component's declarations | rename | `decl` |
| 1434 | `bn` | local | `output_state`'s bundle field names | rename | `bundle_fields` |
| 1443 | `ci` | `for` | the component index, in execution order | keep:index | — |
| 1445 | `c` | destructure | the component instance | rename | `comp` |
| 1445 | `d` | destructure | the component's declarations | rename | `decl` |
| 1447 | `y1keys` | local | the stage-1 port names | rename | `stage1_names` (as in `_outputs`) |
| 1448 | `bn` | local | `output_direct`'s bundle field names | rename | `bundle_fields` |
| 1459 | `ci` | `for` destructure | the component index | keep:index | — |
| 1460 | `c` | destructure | the component instance | rename | `comp` |
| 1460 | `d` | destructure | the component's declarations | rename | `decl` |
| 1460 | `t` | destructure | the tier, read on four lines | rename | `tier` |
| 1463 | `bn` | local | the update law's bundle field names | rename | `bundle_fields` |
| 1464 | `y_g` | destructure | the output cells' address group | rename | `output_addrs` |
| 1464 | `in_g` | destructure | the input cells' address group | rename | `input_addrs` |
| 1483 | `ev_entries`, `ev_owner` | destructure | the event entries and each one's component index | rename | `event_entries`, `event_owner` |
| 1484 | `ev_names` | local | (path, event name) per entry | rename | `event_names` |
| 1485 | `ev_localized` | local | per entry, whether its policy is localized | rename | `event_localized` |
| 1487 | `ci` | `for` destructure | the component index | keep:index | — |
| 1488 | `c` | destructure | the component instance | rename | `comp` |
| 1490 | `pol` | destructure | the component's policy register | rename | `policies` (the `ComponentEvents` field it reads) |
| 1490 | `bn` | destructure | the event bundle's field names | rename | `bundle_fields` |
| 1492 | `d` | local | the component's declarations | rename | `decl` |
| 1495 | `evs` | local | the component's declared events | rename | `declared_events` (as in `probe_events`) |
| 1496 | `pj` | local | `state_projection` or `nothing` | rename | `projection` |
| 1512 | `proj_entries` | local | the projection entries | rename | `projection_entries` |
| 1512, 1514 | `ci` | comprehension | the component index | keep:index | — |
| 1517 | `es`, `gs` | local function params | one block's entries and gates | rename | `entries`, `gates` |
| 1520 | `ev_bodies` | local | per event, its compiled callables | rename | `event_bodies` (`_event_bodies` is the function it calls; the underscore separates them) |
| 1521 | `i` | comprehension | the entry index | keep:index | — |
| 1522 | `proj_bodies` | local | per path, its projection callable | rename | `projection_bodies` |
| 1522 | `e` | comprehension | one projection entry; `e` is an exception elsewhere | rename | `entry` |
| 1529 | `evset` | local | the compiled event set | rename | `event_set` |

## `_probe_input(structure::Structure, layout::Layout, products, ci, face, P, ::Type{T})` — line 1552

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1552 | `ci` | param | the consumer's component index | keep:roster | — |
| 1552 | `P` | param (a value, not a type parameter) | the entry's declared input type | rename | `entry_type` |
| 1553 | `T` | type param | the activation scalar | keep:typeparam | — |
| 1556 | `ppath`, `pport` | destructure | the producer's path and port, read on five lines | rename | `producer_path`, `producer_port` |
| 1556 | `p` | lambda param | one connection pair | keep:glance | — |
| 1557 | `v` | local | the probed input value, the return | rename | `value` |
| 1558 | `r` | lambda param | one root input pair | keep:glance | — |

## `_check_derivative(path, ẋ, x::NamedTuple, ::Type{T})` — line 1570

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1570 | `ẋ`, `x` | param | returned derivative and declared state | keep:spec | — |
| 1570 | `T` | type param | the activation scalar | keep:typeparam | — |
| 1582 | `k` | `for` | one state field name; not an index | rename | `field` (the keyword it fills) |

## `_check_update(path, s⁺, s::NamedTuple)` — line 1597

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1597 | `s⁺`, `s` | param | returned and declared discrete store | keep:spec | — |

## Collisions

| line | local | function | defined at | called in the binding scope? | proposal |
| --- | --- | --- | --- | --- | --- |
| 201 | `state` (`classify_tier`) | `state(sim, path)` | `src/sim.jl:1813` | no | `state_store` |
| 543 | `port` (`cell_layout`) | `port(sim, path, name)`, `port(snapshot, path, name)` | `src/sim.jl:1806`, `src/dataplane.jl:598` | no | `port_name`, or extend the `path` exception to `port` (see Questions) |
| 839 | `at` (local function in `_check_wires`) | `at(prefix, node)` | `src/conditions.jl:92` | no (only the local is called, lines 841–842) | `contracts_at` |
| 1376 | `build` (`compile`'s parameter) | `build(root; activations)` | `src/build.jl:720` | no | `built`, as `build` itself names its result (line 725) |

## Roster proposals

| name | sites in this file | abbreviates | note |
| --- | --- | --- | --- |
| `fn` | 8 (lines 35, 50, 153, 194, 781, 805, 831, 839) | function: the declaration, stage, guard or handler a site invokes | matches `UserCodeFraming`'s own `fn` field; the alternative is `declaration`, which misfits the guard/handler sites |
| `ins`/`outs` | 4 rows, 6 names (lines 299, 331, 841, 842, the last two as `ins_F`, `outs_F`, `ins_M`, `outs_M`) | inputs/outputs: declared face and port types | the `Decls` fields' own names; the `_F`/`_M` suffixes follow the spec's `P_F`/`V_M` |
| `scc`/`sccs` | 4 (lines 428, 451, 482, and 465 once renamed) | strongly connected component | Tarjan's own term; the docstrings say "cluster" for the reported ones |
| `addr` | 1 (line 515), beside the `Layout.addr` field it builds | address | the singular of the roster's `addrs` |
| `xbuf`/`ẋbuf` | 3 (lines 1300, 1396, 1398); 12 uses here, 58 in `executor.jl` | the flat `x` buffer and its derivative | `Executor` field names |
| `act` | 1 (line 1376); `Executor.act` is read 10 times here and 11 in `tracer.jl` | activation | the full noun is the exported function `activation` |

## Questions

- The brief's header template names tip `4a3b725`; the dispatch named `f64b9f3`. `src/` is identical between them, so the line numbers hold for both.
- `port` is the spec's noun for a port name, as `path` is for a component path, and it collides with the `port` accessors. Should the `path` exception extend to `port`? Only one site here (line 543); other files may have more.
- `warnings` has three methods with three parameter names: `d::Deployment`, `sim::Simulation`, `b::Build`. Does "every method names its parameters alike" hold across methods that dispatch on unrelated types? If so, one name for all three is needed, and `built` fits only one.
- `act` (line 1376): the natural name is the exported `activation`. Roster `act`, or accept `compiled` or similar? `probe_events` and `activation` itself take `nominal` and `derived` by role.
- `ws` in `_bundle_values` is kept as the bundle's own field name (`:ws`, matched at line 290). The brief lists `ws` among the offenders; confirm the keyword stays and only the two other `ws` locals change.
- `c` → `comp` follows the brief's example. `comp` is on the roster without a gloss; confirm it means the component instance, while `entry` holds the `ComponentEntry`.
- `mstores`/`sstores` are classed `keep:spec` as derivatives of `m` and `s`, like `x_offs`. The rules' list of derivatives does not name them.
- `y1` (line 280) and `y2` (line 1136) are kept as derivatives of `y`, but `s1` (line 1128) is renamed because `s` is the spec's discrete state. Rename `y1`/`y2` too for symmetry (`stage1_outputs`, `stage2_return`)?
- `pi` (lines 376, 420, 434, 845) shadows `Base.pi`, a constant rather than a function; the rules do not cover it. Renamed anyway.
- `sch` → `schedule` shadows `Base.schedule`, which this file never calls, so the rules permit it.
- Not naming: the input `NamedTuple` is built three times from the same generator (`in_values` at 1043, `u` at 1133 and 1208). `_probe_direct!` and `probe_events` could call one helper. Proposed only.
