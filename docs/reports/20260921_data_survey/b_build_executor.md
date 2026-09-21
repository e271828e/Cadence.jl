# Data survey, slice B — build and executor

Tip `aa9162a` (the brief names `34f8a39`; `aa9162a` adds the brief and touches no `src/`). Date 2026-09-21.

Files: `src/store.jl`, `src/executor.jl`, `src/build.jl`, `src/deployment.jl`, `src/stepper.jl`, and `GridEntry`, `GridReport` in `src/diagnostics.jl`.

| struct | file | fields | outcome |
| --- | --- | --- | --- |
| `Schedule` | `deployment.jl:137` | 5 | finding 1 |
| `ExecutionCursor` | `executor.jl:20` | 5 | finding 2 |
| `Executor{T,S,B,CL,EV,M}` | `build.jl:1286` | 16 | finding 3 |
| `Activation{T}` | `build.jl:603` | 4 | finding 4 |
| `Deployment` | `deployment.jl:306` | 11 | finding 5; `Δt_base` in Questions |
| `Dataflow` | `build.jl:618` | 5 | finding 6 |
| `Layout` | `build.jl:503` | 3 | finding 7 |
| `Chunk{E,S,X,CL}` | `executor.jl:450` | 5 | finding 8 |
| `GridEntry` | `diagnostics.jl:1216` | 6 | finding 9 |
| `EventSet{E,P,S,X}` | `executor.jl:262` | 19 | finding 10 |
| `CellAddr{P,K}` | `store.jl:11` | 1 | clean |
| `CellStore{T}` | `store.jl:15` | 1 | clean |
| `StoreBundle{NT}` | `store.jl:29` | 1 | clean |
| `Clock{T}` | `store.jl:123` | 4 | clean |
| `StageEntry{…}` | `executor.jl:49` | 15 | clean; `fname`, `Δt` in Questions |
| `RHSEntry{…}` | `executor.jl:67` | 10 | clean |
| `UpdateEntry{…}` | `executor.jl:80` | 10 | clean |
| `EventEntry{…}` | `executor.jl:190` | 15 | clean |
| `ProjectEntry{Comp,XT,CL}` | `executor.jl:228` | 6 | clean |
| `Gated{E}` | `executor.jl:407` | 3 | clean |
| `Establish` | `executor.jl:425` | 0 | clean |
| `PhaseBody{I,B}` | `executor.jl:489` | 2 | clean |
| `Decls` | `build.jl:94` | 4 | clean |
| `Events` | `build.jl:634` | 2 | clean |
| `Build` | `build.jl:653` | 6 | clean |
| `ProbeTag` | `build.jl:663` | 0 | clean |
| `Marker` | `build.jl:763` | 0 | clean |
| `ScheduleRow` | `deployment.jl:101` | 6 | clean; `Δt` named in finding 1 |
| `ScopeRow` | `deployment.jl:123` | 5 | clean; in Questions |
| `RK4{T}` | `stepper.jl:40` | 5 | clean |
| `Heun{T}` | `stepper.jl:78` | 3 | clean |
| `GridReport` | `diagnostics.jl:1231` | 3 | clean |

Structs surveyed: 32. Findings: 10 (dead 5, duplicate 4, misplaced/courier 1); 5 of them spec-rostered.

Method note. Every reader count below is a grep over all of `src/` (the access `\.name` with `rg -P` and a non-identifier boundary, since macOS `grep`'s `\b` fails after a Unicode character, plus the constructor calls). Runtime claims were checked in `julia --project=test -L test/repl.jl`. Two scripts in the scratchpad: `scan3.jl` walks the 1.13 global method table, takes every method whose module is `Cadence` (1833, closures and `Base` extensions included) and lists every lowered `getproperty`/`getfield` on a given field name; `stage1_check.jl` and `chunk_check.jl` re-evaluate one function with the field's write replaced and compare results. Dynamic reads (`getfield(x, name)` with a runtime `Symbol`, in `_walk_deployment!`) were counted by hand.

## Findings

### `Schedule.D`, `Schedule.Φ`, `Schedule.Δt` — duplicate (of the rows), spec-rostered

`src/deployment.jl:140-142`. `D::Vector{Int}`, `Φ::Vector{Int}`, `Δt::Vector{Float64}`, one entry per component of every tier.
Writers: the positional constructor at one site, `bind_schedule` (`deployment.jl:262`, args 3-5), filled in the same loop that pushes the `ScheduleRow`s (`245-256`): a discrete `ci` pushes `(D, Φ, D·Δtb)` onto both, a continuous one pushes `(1, 0, 0.0)` and no row.
Readers: `compile`'s callers, `Simulation()` (`sim.jl:213`) and trim's `_scratch` (`trim.jl:505`), passing the three vectors positionally; `==` and `hash` (`deployment.jl:146`, `148`); the replay header walk's backstop arm (`trace.jl:321-323`), whose own comment says "They resolve from the rows above, so a reachable difference is already named there"; tests `test_discrete.jl:271-272`, `test_diagnostics.jl:563`.
Evidence: `rg -P '(sch|schedule|s|a|b)\.(D|Φ|Δt)(?![\w])' src/` → the six sites above; `scan3.jl` on `:scopes`/`:rows` confirms the rows' readers are `bind_schedule`'s advisory (`deployment.jl:351-354`), `==`/`hash` and `_walk_deployment!` (`trace.jl:301-315`). Not run-confirmed beyond the scan: the equality of the two homes is by construction in one loop, both immutable.
Reading: for a discrete `ci`, `D[ci] == rows[j].D`, `Φ[ci] == rows[j].Φ`, `Δt[ci] == rows[j].Δt` for the row with `path == structure.paths[ci]`; for a continuous `ci` the triple is the constant `(1, 0, 0.0)`, a function of `structure.tiers`. The three vectors are the rows re-indexed by component, and `ScheduleRow.Δt` and `Schedule.Δt` are both `D · Deployment.Δt_base` exactly (the same float product). The `==`, `hash` and header walk each carry a clause for the vectors that the rows already decide.
Proposal: the rows are the home (§9.2's typed schedule). `compile` takes the `Schedule` (or a helper `_gates(sched, structure)` returns the per-component triple, built from the rows by path with the tier's constant elsewhere); the three vector fields, `==`'s and `hash`'s vector clauses and `_walk_deployment!`'s backstop arm go. What changes: `Schedule` (`deployment.jl:137-148`), `bind_schedule` (`243-262`), `compile`'s signature (`build.jl:1331`) and its three callers (`sim.jl:213`, `trim.jl:505`, `test/test_trim.jl:483`), `trace.jl:321-323`, the two tests. Whether `Δt` stays a row column or is read as `D · Δt_base` is a second, smaller ruling.
Spec: §9.2, §10.5, D-254 ("per discrete component `(D, Φ, Δt)` with anchor and provenance columns, the rate-scope rows, and the `D`, `Φ`, `Δt` vectors"). Both homes are rostered, so this is a ruling to raise.

### `ExecutionCursor.hit` — misplaced (courier), spec-rostered

`src/executor.jl:26`. `hit::Union{Nothing,Symbol}`, on the executor's cursor.
Writers: `ExecutionCursor()` (`executor.jl:28`, arg 5, `nothing`); `_localized_frame!` (`localization.jl:159`, `cur.hit = face`, immediately before `return nothing`); `_advance!` (`sim.jl:1190`, `cur.hit = nothing` at each frame top).
Readers: `frame!` (`localization.jl:34`, to skip the frame-top clock stamp); `_advance!` (`sim.jl:1194`, `1199`, to take the `t*` hit as the frame's stop face).
Evidence: `rg -P '\.hit(?![\w])' src/` → the five sites above; `scan3.jl` on `:hit` → `frame!`, `_advance!` and nothing else. No entry, no catch site and no diagnostic reads it: `_wrap_step` (`sim.jl:1232-1233`) builds the `CursorFrame` from `comp`, `fn`, `phase`, `index` alone.
Reading: `_localized_frame!` observes a stop face at a `t*` publication and needs to tell its two callers, `frame!` and `_advance!`, so the frame's remainder is abandoned and the snapshot is final. It returns `nothing` on both paths and writes the face onto the cursor instead, which the callers read back and clear. That is the courier form D-260 removed from `Run.policy`: a field written only to reach a caller without the argument. The cursor's other four fields are written per dispatch by the entries and read once at the catch site; `hit` is written and read by the frame loop only, and the cursor is where it sits because the cursor is the one mutable loop register reachable from `sim.exec`.
Proposal: `_localized_frame!` returns the face or `nothing` (a `Union{Nothing,Symbol}`, no allocation, off the measured `body()` path), `frame!` returns it, `_advance!` reads the return. What changes: `_localized_frame!` (`localization.jl:44-165`, its `return nothing` at `160` and the frame-top exit), `frame!` (`31-36`), `_advance!` (`sim.jl:1190-1200`), `ExecutionCursor` and its constructor (`executor.jl:20-28`), the docstring at `executor.jl:15-18`.
Spec: §13.5 ("The loop's `hit` scratch sits beside the execution cursor, never in the policy", `spec.md:7997-7999`), the `StopPolicy` glossary entry (`spec.md:12201`), D-255 ("`hit` leaves it for the loop's scratch beside the cursor"). The spec fixed the placement while moving `hit` out of the policy, so this is a ruling to raise.

### `Executor.xblocks` — duplicate (of the declaration walk), misplaced

`src/build.jl:1298`. `xblocks::Vector{UnitRange{Int}}`, each component's range in the flat `x` buffer.
Writers: `compile` (`build.jl:1349-1356`, the inline `x_offs`/`xblocks` loop over `decls` and `tiers`), then the positional `Executor(...)` at `1491` (arg 11).
Readers: `_nonfinite` (`sim.jl:631`, `638`), the throwing path of the seam's `isfinite` sweep, to name the owner and leaf of a nonfinite index.
Evidence: `rg -P '\.xblocks(?![\w])' src/` → `sim.jl:631`, `638`; `scan3.jl` on `:xblocks` → `_nonfinite` only. The same fact is computed three more times from `act.decls` and `tiers`: `_x_offsets` (`conditions.jl:384-391`) called at `readers.jl:243`, `conditions.jl:339` and `conditions.jl:836`, and `compile`'s own inline loop, which does not call `_x_offsets`. Not run-confirmed; the agreement is by identical arithmetic over identical inputs.
Reading: the block layout is a pure function of the activation's declarations and the tiers, per activation and `T`-independent in shape. It is cached on the executor for one cold reader while three services recompute it, and `compile` recomputes it a fourth time to fill the cache. The executor neither mutates it nor is the reader it exists for.
Proposal: home it on the `Layout` (or the `Activation`), computed once in `cell_layout` beside `sizes`, and have `_x_offsets`'s three callers, `compile` and `_nonfinite` read it (`_nonfinite` through `ex.act.layout`). What changes: `Layout` (`build.jl:503-507`) and `cell_layout` (`572-573`); `compile` (`1349-1356`, `1491`); `Executor` (`1298`); `_nonfinite` (`sim.jl:631`, `638`); `_x_offsets` and its callers (`conditions.jl:384`, `339`, `836`, `readers.jl:243`), which then read a field instead of recomputing.
Spec: not rostered (`xblocks` and "flat-buffer range" appear in neither `spec.md` nor `decisions.md`; §13.4 asks for the owner lookup, not its home).

### `Activation.stage1` — dead (read by tests only), duplicate (of `products` under `Dataflow.stage1`)

`src/build.jl:605`. `stage1::Vector{NamedTuple}`, the stage-1 probe products per component.
Writers: the positional constructor at two sites, `_nominal` (`build.jl:922`, arg 2) and `_activate` (`943`, arg 2).
Readers: one in `src/`, `probe_stage1` (`build.jl:261`, `carry.stage1[ci]` for a frozen component at a non-nominal activation); tests `test_build.jl:370`, `1195-1196`, `1212`.
Evidence: `rg -P '\.stage1(?![\w])' src/` → `build.jl:261` on an `Activation`, the rest on `Dataflow.stage1`; `scan3.jl` on `:stage1` → `#probe_stage1##2 @ build.jl:261` as the sole `Activation` read. The value that read returns is inert: it lands in `_activate`'s local `stage1`, which `probe_stage2` copies into `products` (`986`) and then overwrites for every frozen `ci` with `carry.products[ci]` (`996`); `_probe_direct!` reads `stage1[ci]` (`1082`) and returns on the frozen test (`1083`); the update-law loop skips frozen components (`1031`). REPL (`stage1_check.jl`): with `probe_stage1`'s frozen branch re-evaluated to return `NamedTuple()`, a fresh `build` of a `TickCounter` rig activated at `ProbeDual` gives `products` and `layout.addr` equal to the unpatched activation's.
Reading: the field exists so `_activate` can hand the nominal stage-1 products to the frozen components, but nothing downstream consumes them there. It is also derivable: `stage1[ci] == products[ci][Tuple(dataflow.stage1[ci])]`, the names being the `Dataflow`'s by D-253 ("a reader wanting a name list takes it from the `Dataflow`").
Proposal: remove the field; `probe_stage1` returns `NamedTuple()` for a frozen component (or `_activate` passes no carry); the four tests read `products` restricted by `dataflow.stage1`. What changes: `Activation` (`build.jl:603-608`), `_nominal` (`922`), `_activate` (`943`), `probe_stage1` (`257`, `261`), the tests.
Spec: not rostered by field (the `activation` glossary entry, `spec.md:11903`, describes the probe chain; D-253 rosters the name sets on the `Dataflow`).

### `Deployment.grid` — dead (read by tests only), spec-rostered

`src/deployment.jl:316`. `grid::GridReport`.
Writers: the positional constructor at one site, `Deployment()` (`deployment.jl:359`, arg 10, `bound.grid`).
Readers: none in `src/`. `==` and `hash` exclude it by design (`371`: "`grid` and `warnings` are not compared either — both are functions of the rest"); the derivation line and the `GridUtilization` advisory read `bound.grid`, the local (`343-355`), not the field; the `_grid_block` renderings read the payload copies on `DeploymentInvalid` and `GridUtilization` (out of scope). Tests `test_discrete.jl:396-511` read `d.grid`.
Evidence: `rg -P '\.grid(?![\w])' src/` → `deployment.jl:343`, `359` (the local and the write) and `diagnostics.jl` payload reads; `scan3.jl` on `:grid` → the constructor's write, the two `@kwdef` constructors and `message` on the payloads, no read of a `Deployment`. Not run-confirmed beyond the scan.
Reading: the artifact carries the attribution as a value the user can inspect, and it is derivable from the build (`_grid_report(structure.anchors, structure.aprov)`). Its prospective `src/` reader is D-257's `show(::Deployment)`, which `pending.md:41-43` lists as unbuilt (M-B26).
Proposal: none to make now. Either the field waits for its renderer, or it goes and `show(::Deployment)` calls `_grid_report` when it prints. A ruling, since the spec places it.
Spec: §9.2 ("The grid diagnostics live on the `Deployment`", `spec.md:3352`), §9.1 (`spec.md:3168`), D-254 ("It carries the `Schedule`, the grid diagnostics of D-187 and its warnings"), the `Deployment` glossary entry.

### `Dataflow.edges` — dead (read by tests only), spec-rostered

`src/build.jl:622`. `edges::Vector{Vector{Tuple{Int,Symbol,Symbol}}}`, per consumer `(producer, port, face)`.
Writers: the positional constructor at one site, `_dataflow` (`build.jl:399`, arg 4).
Readers: none in `src/` after construction. The local `edges` is read by `_cycle_diagnostics` (`412-443`) and the tracer's `_classify` (`tracer.jl:271-353`) on the throwing path, before the `Dataflow` exists. Tests `test_build.jl:130-132`.
Evidence: `rg -P '\.edges(?![\w])' src/` → nothing; `scan3.jl` on `:edges` → four closure reads of the captured local in `_classify`, no `getproperty(::Dataflow, :edges)`. Not run-confirmed beyond the scan.
Reading: the graph is kept on the artifact because D-253 kept the name `Dataflow` for it ("the artifact carries the edges and the name sets as well as the order, and a graph is what 'dataflow' names"). D-257's `show(::Dataflow)` prints "the execution order with port classes", not the edges, so no renderer is pending for the field either.
Proposal: none to make now; a ruling. If the graph is wanted as an inspectable value it stays; if not, `Dataflow` drops to four fields and `_dataflow` hands `edges` to the cycle path only.
Spec: D-253 and the `Dataflow` glossary entry (`spec.md:11932`: "the feedthrough edges with their provenance"), §9.1.

### `Layout.root_inputs` — duplicate (its name half, of `Structure.root_inputs`)

`src/build.jl:505`. `root_inputs::Vector{Tuple{Symbol,Any}}`, each root input face with its probe value.
Writers: `cell_layout` (`build.jl:566`, one push per face of `s.root_inputs` in order) and the positional `Layout(...)` at `573` (arg 2).
Readers of the value half: `compile`'s seed (`build.jl:1381-1382`), `_probe_input` (`1513`), `Writer` (`dataplane.jl:459`). Readers of the name half only: `_stop_faces` (`sim.jl:282`), `_compile_feed` (`sim.jl:788`), `_fingerprint` (`trace.jl:215`), `_root_input_names` (`bindings.jl:151`), `DataPlane` (`roster.jl:199`), `_claim` (`roster.jl:215`), `reclaim!` (`roster.jl:254`), each spelling `Symbol[f for (f, _) in layout.root_inputs]`.
Evidence: `rg -n '\.root_inputs' src/` → the ten sites above on a `Layout` and eleven on a `Structure`; `scan3.jl` on `:root_inputs` lists both receivers. Not run-confirmed; the name list equals `structure.root_inputs` by construction (`542-567` iterates it in order and every refusal throws before `573`).
Reading: seven readers rebuild the structure's list from the layout's pairs because they hold a `Layout` and not a `Structure`. The face list is the structure's fact (slice A, `assembly.jl:979`); the probe values are the layout's, per activation.
Proposal: the layout keeps the values alone, as a `Vector{Any}` parallel to `structure.root_inputs` or a `Dict{Symbol,Any}`, and the seven name readers read `structure.root_inputs` (the `Simulation` and the header have the structure in hand; `Writer`, `DataPlane`, `_claim` and `reclaim!` would take the face list as an argument beside the layout). What changes: `Layout` and `cell_layout` (`build.jl:503-573`), the three value readers, the seven name readers and the signatures of `Writer(layout, …)` (`dataplane.jl:456`), `DataPlane(layout, …)` (`roster.jl:198`), `_claim` (`roster.jl:214`), `reclaim!` (`roster.jl:247`). Straddles slice A (`Structure.root_inputs`).
Spec: not rostered by field (§6.1, §9.3, §11.3 speak of root inputs and their synthesized values, not of the layout's list).

### `Chunk.clock` — dead

`src/executor.jl:455`. `clock::CL`.
Writers: the positional `Chunk(...)` in `chunked_body` (`executor.jl:516-517`, arg 5), from `chunked_body`'s `clock` argument, which `compile` passes (`build.jl:1474`).
Readers: none. The two call methods `(c::Chunk)()` and `(c::Chunk)(idx)` (`458-459`) read `entries`, `store`, `xbuf`, `ẋbuf`; every entry reaches the clock through its own `clock` field (`e.clock`, six sites).
Evidence: `rg -P '\.clock(?![\w])' src/ -o | sort | uniq -c` → `e.clock` 6, `ex.clock` 4, `sim.exec.clock` 29, no `c.clock`; `scan3.jl` on `:clock` → every `getproperty` is on an entry, an executor or `sim.exec`; the `Core.getfield(_1, :clock)` hits in `chunks`/`body` are the closures' captured locals. REPL (`chunk_check.jl`): with `chunked_body` re-evaluated to pass `nothing` as the chunk's clock, a `TickCounter` simulation run to `t_end = 1.0` gives the same port value and clock as the unpatched one, and the chunk's `CL` parameter is `Nothing`.
Proposal: remove the field and `chunked_body`'s `clock` argument. What changes: `Chunk` (`executor.jl:450-456`), `chunked_body` (`514-521`), `compile` (`build.jl:1474`). The alternative, passing `clock` and `cursor` down the walk and dropping them from the six entry types, is the larger design question noted below.
Spec: not rostered.

### `GridEntry.anchor` — dead (read by tests only), duplicate (of `provenance`)

`src/diagnostics.jl:1219`. `anchor::Int`, the entry's index into the structure's anchor table.
Writers: the positional `GridEntry(...)` in `_grid_report` (`deployment.jl:86`, arg 3, `ks[i]`; arg 4 is `prov[ks[i]]`).
Readers: none in `src/`. `_grid_block` and `_grid_label` (`diagnostics.jl:1278-1305`) read `kind`, `value`, `provenance`, `factor`, `alternatives`. Test `test_discrete.jl:465`.
Evidence: `rg -P '\.anchor(?![\w])' src/` → `ScheduleRow`'s `==`/`hash` only; `scan3.jl` on `:anchor` → the same. Not run-confirmed beyond the scan.
Reading: `provenance == aprov[anchor]` by construction, so the two fields state one fact and the rendering reads the string.
Proposal: drop `anchor` (the test reads `provenance` instead), or keep it and drop the string, with `_grid_block` looking the provenance up through the structure it does not have. The first is the smaller change: `GridEntry` (`diagnostics.jl:1216-1223`), `_grid_report` (`deployment.jl:86`), the test.
Spec: not rostered by field (§9.2 and D-187 describe the pool's entries by period, offset, factor, attribution and alternatives).

### `EventSet.store`, `EventSet.xbuf` — duplicate (references to `Executor.store`, `Executor.xbuf`)

`src/executor.jl:265-266`. `store::S`, `xbuf::X`.
Writers: `EventSet(...)` (`executor.jl:288`, args 3-4) from `compile` (`build.jl:1486`), the same locals that become `Executor.store` and `Executor.xbuf` (`1490`, args 2-3).
Readers: `_projects!`, `_guards!`, `_fire!` (`executor.jl:300`, `307`, `321`), each called with `sim.exec.events` from a site holding `sim.exec` (`sim.jl:467`, `485`, `512`; `localization.jl:176`; `event_phase!` and the two register sweeps read the registers only).
Evidence: `rg -P 'es\.(store|xbuf)' src/` → the three walk entry points; `rg -n 'exec\.events' src/` → every caller has the executor in hand. Not run-confirmed; the pairing is by construction, both structs immutable and co-lived.
Reading: two references to one object, held so the three `@noinline` walks take one argument. It is the shape 47b classed as a duplicate in `TraceRegister.trace`, without that case's staleness risk, since the executor's buffers never rebind. `Chunk.store`/`xbuf`/`ẋbuf` are the same shape but are the §9.7 closure design (`body()` takes no arguments, D-116), so they are not reported.
Proposal: `_guards!(es, store, xbuf)`, `_fire!(es, store, xbuf)`, `_projects!(es, xbuf)` with the callers passing `sim.exec.store`, `sim.exec.xbuf`; the two fields go. What changes: `EventSet` and its constructor (`executor.jl:262-292`), the three walks (`300-321`), `compile` (`build.jl:1486`), the callers listed above. Low consequence.
Spec: not rostered (§10.6 and the `EventSet` docstring roster the registers, not the buffer references).

## Clean

- `CellAddr{P,K}` (`store.jl:11`), 1 field: `offs` read by `gather`/`scatter!`.
- `CellStore{T}` (`store.jl:15`), 1 field: `buf` read by the two generated binders.
- `StoreBundle{NT}` (`store.jl:29`), 1 field: `stores` read by `gather`, `scatter!`, `capture` (`dataplane.jl:604`), `apply!` (`conditions.jl:527`, `757`).
- `Clock{T}` (`store.jl:123`), 4 fields: `t` everywhere; `step` written `sim.jl:658`, `1192`, read `641`, `1060`, `1186-1189`, `1354`, `1603`, `1664`; `boundary` written `659`, `1666`, read `1664`; `t₀` written `store.jl:129`, `sim.jl:657`, read `localization.jl:16`, `sim.jl:272`, `trace.jl:232`.
- `StageEntry{…}` (`executor.jl:49`), 15 fields: all read by `run!` (`156-160`) or `_bundle_expr` (`117-132`); `fname` and `Δt` in Questions.
- `RHSEntry{…}` (`executor.jl:67`), 10 fields: all read by `run!` (`162-168`) or the bundle.
- `UpdateEntry{…}` (`executor.jl:80`), 10 fields: all read by `run!` (`173-178`) or the bundle.
- `EventEntry{…}` (`executor.jl:190`), 15 fields: all read by the guard and fire walks (`309-340`), `_fire_project!` (`378-384`) or the bundle.
- `ProjectEntry{Comp,XT,CL}` (`executor.jl:228`), 6 fields: all read by `run_project!` (`239-244`).
- `Gated{E}` (`executor.jl:407`), 3 fields: read by `run_at!` (`434-446`).
- `Establish` (`executor.jl:425`), 0 fields.
- `PhaseBody{I,B}` (`executor.jl:489`), 2 fields: read by the two call methods (`494-495`).
- `Decls` (`build.jl:94`), 4 fields: `x`, `s`, `ins`, `outs` read across `build.jl`, `readers.jl`, `conditions.jl`, `tracer.jl`, `sim.jl:635`.
- `Events` (`build.jl:634`), 2 fields: `policies`, `bundles` read by `compile` (`build.jl:1447`).
- `Build` (`build.jl:653`), 6 fields: `structure`, `dataflow`, `events` read throughout; `activations` and `lock` by `activation` (`882-886`); `warnings` by `warnings(::Build)` (`897`) and `build`'s rewrap (`718`).
- `ProbeTag` (`build.jl:663`), 0 fields. `Marker` (`build.jl:763`), 0 fields.
- `ScheduleRow` (`deployment.jl:101`), 6 fields: all read by `==`/`hash` (`113-117`) and `_walk_deployment!` (`trace.jl:301-306`); `D` and `path` by the `GridUtilization` advisory (`deployment.jl:352-354`). `Δt` named in finding 1.
- `ScopeRow` (`deployment.jl:123`), 5 fields: all read by `==`/`hash` and `_walk_deployment!` (`trace.jl:308-315`). In Questions.
- `Deployment` (`deployment.jl:306`), 11 fields less `grid` (finding 5): `build` throughout; `h` (`localization.jl:16`, `33`, `198`, `sim.jl:272`, `901`, `1344`); `N_base` (`sim.jl:1177`); `Δt_base` by `==`/`hash` and the header walk only, in Questions; `algorithm` (`sim.jl:213`, `trim.jl:506`); `firing_budget` (`sim.jl:557`); `localization_tol`, `localization_budget` (`localization.jl:75`, `83`, `198`); `schedule` (`sim.jl:212`, `trim.jl:504`, `trace.jl:298`); `warnings` (`warnings(::Deployment)`, `389`).
- `Executor{…}` (`build.jl:1286`), 16 fields less `xblocks` (finding 3): `act` (`.layout`, `.decls` at 20+ sites), `store`, `xbuf`, `ẋbuf`, `sstores`, `mstores`, `clock`, `bodies`, `events`, `cursor` throughout `sim.jl`, `localization.jl`, `trace.jl`, `conditions.jl`, `readers.jl`; `chunk_size` (`trim.jl:506`); `stepper`, `xnext`, `ẋnext` (`sim.jl:606`, `localization.jl:47-173`); `has_localized` (`localization.jl:33`), in Questions.
- `RK4{T}` (`stepper.jl:40`), 5 fields: destructured in `step!` (`51`), `x₀`/`k₁` by `startpoint` (`69`).
- `Heun{T}` (`stepper.jl:78`), 3 fields: destructured in `step!` (`87`), `x₀`/`k₁` by `startpoint` (`101`).
- `GridReport` (`diagnostics.jl:1231`), 3 fields: `pool`, `admissible`, `primes` read by `_grid_block` (`1284-1303`) and `bind_schedule` (`deployment.jl:192-195`, `344-353`).
- `EventSet{…}` (`executor.jl:262`), 17 of 19 fields (less `store`, `xbuf`, finding 10): the twelve registers and `owner`, `names`, `localized`, `entries`, `projects` all read by the boundary iteration (`sim.jl:552-589`), the localization loop (`localization.jl:46-128`, `219`), the three walks and trim's commit report (`trim.jl:570`).
- `ExecutionCursor` (`executor.jl:20`), 4 of 5 fields (less `hit`, finding 2): `comp`, `fn` written per dispatch and by `_nonfinite` (`sim.jl:633`) and `drain!` (`1558`), `phase`, `index` by `_phase!` and the stage counters, all four read by `_wrap_step` (`sim.jl:1232-1233`) and `_species` (`1252-1253`).
- `Activation{T}` (`build.jl:603`), 3 of 4 fields (less `stage1`, finding 4): `decls`, `products`, `layout` read by `compile`, `probe_events`, the services and the header.
- `Dataflow` (`build.jl:618`), 4 of 5 fields (less `edges`, finding 6): `ports` (`readers.jl:344`, `build.jl:1423`, `1457`, `trim.jl:520`), `stage1` (`build.jl:1397-1422`, `sim.jl:1255`), `stage2` (`build.jl:1410`), `order` (`build.jl:920`, `941`, `1403`).
- `Layout` (`build.jl:503`), 2 of 3 fields (less `root_inputs`, finding 7): `addr` at 25+ sites, `sizes` (`build.jl:1345-1347`, `trace.jl:214`, `256`).
- `Schedule` (`deployment.jl:137`), 2 of 5 fields (less `D`, `Φ`, `Δt`, finding 1): `rows`, `scopes` read by the advisory, `==`/`hash` and the header walk.
- `Chunk{…}` (`executor.jl:450`), 4 of 5 fields (less `clock`, finding 8): read by the two call methods (`458-459`).
- `GridEntry` (`diagnostics.jl:1216`), 5 of 6 fields (less `anchor`, finding 9): read by `_grid_block`/`_grid_label` and the derivation line (`deployment.jl:345`).

## Questions

- `Deployment.Δt_base` (`deployment.jl:310`) has comparison readers only: `==`, `hash` and `_walk_deployment!`. The loop reads `N_base` and `h`, and the entries carry `Schedule.Δt`. It is exactly `N_base · h` as rationals, but not as the stored floats: in the REPL, `Float64(N·h) == N·Float64(h)` failed for 4495 of 20000 random `(h, N)` pairs, so the field holds the correctly rounded exact value and cannot be recomputed from its siblings. §9.1 wants three cross-validated sources and D-256 rosters all three on the artifact. A design choice, not a smell, but the reader set is worth knowing.
- `StageEntry.fname` (`executor.jl:63`) is `nameof(fn)`, computed once by the outer constructor so `run!` does a field read instead of a call on the hot path. One writer, derived from a sibling; a cache rather than a duplicate.
- `Executor.has_localized` (`build.jl:1304`) is `any(events.localized)`, computed once in `compile` as the frame loop's fast-path key (D-256). Same shape as `fname`.
- `EventSet.owner`, `names`, `localized` (`executor.jl:267-269`) mirror the entries' `ci`, `(path, event)` and `Events.policies` as plain vectors, so the boundary iteration can index by global event index without touching the heterogeneous entry tuple. The compiled form §9.7 asks for; not reported.
- Six entry types each carry `clock` and `cursor` references so a body reaches them without an argument, while `Chunk` already passes `store`, `xbuf`, `ẋbuf` down the walk and holds a `clock` nobody reads (finding 8). Passing `clock` and `cursor` from the chunk instead would drop two fields from every entry type; whether the per-instance reference or the walk argument is the §9.7 shape is a design question.
- `ScopeRow` (`deployment.jl:123`) is read by comparison alone (`==`, `hash`, the header walk). D-254 rosters the rate-scope rows and D-257's `show(::Schedule)` is their pending renderer (`pending.md:41-43`).
- `StageEntry.Δt` (`executor.jl:60`) is `0.0` on every continuous-tier instance and is read only where `:Δt` is in the bundle names, which the continuous tier never has. One entry type serves both tiers (D-220), so the field is idle on half its instances by construction.
- `Decls.x` and `Decls.s` (`build.jl:95-96`): exactly one is populated, per the tier. The tier lives on `Structure.tiers`; an empty `x` on a stateless continuous component keeps the pair from being a tier encoding.

## Coverage

All 32 structs in the slice were reached. Two limits on the evidence: the method-table scan covers lowered `getproperty`/`getfield` with a literal field name, so `getfield(x, name)` with a runtime `Symbol` (`_walk_deployment!`'s `_dep_diff!` calls, `trace.jl:296-322`) was counted by hand; and "no reader" for `Deployment.grid`, `Dataflow.edges` and `GridEntry.anchor` rests on the grep and the scan, not on a patched run, since no code path would change.
