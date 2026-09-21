# Increment 47c — The data survey's fixes: D-261's placements and the unrostered fixes (§9.2, §11.2, §11.3, §12.6, §13.5, Appendix B, D-261)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `296f4a0` (the docs commit below) plus the commit that adds this
brief. Line numbers for `src/sim.jl` are those of `296f4a0`. Every other
`src/` file is unchanged since `aa9162a`, the survey's tip, so the slice
reports' line numbers hold there. Never `cd` elsewhere (`cd` is aliased to
zoxide in the user's shell; use absolute paths).

**Standing.** D-261 (`decisions.md:9771`) states three ownership rules and
settles twelve placements under them; the spec says so since `296f4a0`. The
evidence is the data survey of 2026-09-21, `docs/reports/20260921_data_survey/`:
`merge.md` is the register (22 findings, ids A1–E1), and the five slice
reports carry each finding's writers, readers and REPL evidence at
`aa9162a`. This brief cites findings by id and restates only what changes;
**read the slice entry for each id before touching it**, since it lists
every reader. `pending.md:77–89` is the deviation bullet this increment
retires. Roadmap step 6c of `roadmap_pipeline_redesign.md`, before
increment 48.

Three of the findings are rulings to keep (B5, B6, C7), two are "leave"
(C6, D2), and B7 was retired by D-261's periphery placement. None of those
six is touched here.

**The pre-flight probe** (2026-09-21, greps at `296f4a0`, no REPL). The
four recording keywords are passed to `Simulation(…)` at 32 test sites in
8 files: `test_log.jl` 17, `test_discrete.jl` 4, `test_dataplane.jl` 4,
`test_diagnostics.jl` 3, `test_trace.jl` 2, `test_roster.jl` 2,
`test_stepper.jl` 1, `test_localization.jl` 1. Two helpers forward `kw...`
into `Simulation(…)`: `mk` (`test_log.jl:101`) and `replay_twin`
(`test_trace.jl:422–426`, which calls `init!` itself). `StopPolicy(Inf,
Symbol[], Any[])` is built by hand twice (`test_stepper.jl:93`,
`test_localization.jl:221`); `termination(sim).policy` is read at
`test_lifecycle.jl:249` and `256`, `t_end` and `faces` only; no test reads
`.hit` or `.addrs`. `d.schedule.D/Φ/Δt` are read at `test_discrete.jl:271–272`;
`compile(b, act, sch.D, sch.Φ, sch.Δt; …)` is called at `test_trim.jl:483`.
`fieldnames(Run)` is asserted at `test_lifecycle.jl:65`. `activation(b,
T).stage1` is read at `test_build.jl:370`, `1195`, `1196`, `1212`
(`df.stage1` at 122–142 is the `Dataflow`'s and stays). `GridEntry.anchor`
is read at `test_discrete.jl:465` (`r.anchor` at 261 is a `ScheduleRow`'s and
stays). The face slot of `ConditionPlan.inputs` is read at
`test_conditions.jl:86`. `sim.plane.roster[i].writer.faces` is read at
`test_bindings.jl:100`, `247`, `test_roster.jl:110`, `133`; `.binding` at
`test_bindings.jl:151`; `.diag` at `test_roster.jl:136`; `.id` at
`test_bindings.jl:208` (stays). `ArgumentInvalid(call = :Simulation, …)`
with the four recording arguments is constructed at
`test_diagnostics.jl:515–518`. `test/imports.jl` imports `Run`,
`StopPolicy`, `Schedule`, `frame!`, `compile`, `Dataflow`, `Snapshot`,
`GridEntry`, `ConditionPlan`, `DeviceHandle`; nothing new is needed.

**Four stages, four commits, in this order.** Every stage touches a file in
the routing table's last row (`sim.jl` or `deployment.jl`), so each routed
subset is all of it, under the sandbox flags. `implementation.md`'s
"Running the suite" (124–175) is the one home of test policy; this brief
does not restate it. The gate is the reviewer's.

- **Stage 1, authoring and build.** A1 with the `Structure`'s construction
  order, B1, B3, B4, B8, B9, B10.
- **Stage 2, the loop.** B2 and D3, the same three functions once.
- **Stage 3, the periphery.** C1 with the plane's constructor, C2, C3, C4,
  E1.
- **Stage 4, the run.** D1: the recording keywords on the doors.

**Read, in `docs/design/spec.md`:** §9.2's schedule paragraph and the
artifact rule, 3306–3322. §11.2's snapshot sentence, 5160–5166. §11.3's
periphery paragraph, 5447–5453. §11.5's default paragraph, 5876–5884.
§12.6's opening, 7062–7106 (`Run{T}` at 7064–7075, the placeholder at
7079–7085, the five fields at 7087–7100, the rule at 7102–7105). §13.5's
policy paragraph, 8018–8030. Appendix B's constructor entry, 10807–10820,
`init!`'s, 10907–10928, and the `replay!` synopsis, 11024–11036. The
glossary's `Schedule` (11898), `Run` (12200), snapshot (12226),
`StopPolicy` (12236), execution cursor (12429), artifact (12469). In
`docs/design/decisions.md`: **D-261 (9771–9880)**, D-254 (9380), D-255
(9431), D-256 (9513), D-260 (9687).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (124–175)**: the routed subset, the flags.
- The file-table rows for the files a stage touches: `src/assembly.jl`
  (22), `src/executor.jl` (24), `src/build.jl` (25), `src/sim.jl` (28),
  `src/deployment.jl` (30), `src/localization.jl` (31), `src/dataplane.jl`
  (32), `src/trace.jl` (33), `src/roster.jl` (34), `src/devices.jl` (36),
  `src/conditions.jl` (37), `src/diagnostics.jl` (20), `test/imports.jl`
  (40).
- **"Authoring caveats" in full (62–122)** — always. The last two are
  D-261's rules.

In `docs/design/pending.md`: the "Retire alone" bullet (77–89). Each stage
deletes the clauses it retires; stage 4 deletes the bullet.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the decision, the slice report and this brief disagree, stop and
say so in the report rather than improvising. Where a site does not hold
what the brief claims, report it rather than inventing a substitute. No
behaviour beyond the placements: no new accessor, no rendering, no new
validation beyond the four keywords moving.

---

## Stage 1 — authoring and build

### A1, and the `Structure` complete at construction

Slice A, "`Walk.root_types`" and the first question. `Walk.root_types`
(`assembly.jl:771`, constructor `784`) is never written during the walk;
`wire!` hands the empty vector to `Structure` (`979`), and `_check_wires`
(`build.jl:782–855`) fills it by `push!` after the artifact exists (`832`,
`838`, `852`).

- Drop the `Walk` field and its constructor argument.
- `_check_wires` reads six things off the `Structure`: `s.comps`, `s.conns`,
  `s.paths`, `s.root_inputs`, `s.tiers`, and it writes `s.root_types`. All
  but `conns` are on the `Walk`; `conns` is derived inside `wire!`
  (`assembly.jl:964–982`). Restructure so the constructor call is the last
  act of the structure step: `wire!` derives its parts, `_check_wires`
  takes the walk and the derived `conns` and **returns** the root-type
  vector, and the `Structure` is built from both. Whether `wire!` returns
  the parts and `build` composes (`build.jl:700–701` is the call pair), or
  `wire!` takes the check as an argument, is the agent's call; the
  invariant is that no code pushes into a `Structure`'s vector after the
  constructor. `_root_input_cell` (`build.jl:583`) and `_classify`
  (`tracer.jl:245`) keep reading `s.root_types`.
- The `Structure` docstring's sentence on `root_types` and
  `implementation.md`'s `assembly.jl` row ("`Structure.root_types` holding
  the root-input types the wire pass fixes") say the check fixes them
  before construction.

### B1, the schedule's vectors

Slice B, finding 1. `Schedule` (`deployment.jl:137–148`) loses `D`, `Φ`,
`Δt`; the rows keep their `Δt` column (D-261, rejected list).

- `bind_schedule` (`165–262`): the loop at `245–256` stops filling the
  vectors; the constructor call at `262` loses three arguments.
- `==` (`146`) and `hash` (`147`) lose the vector clauses.
- `_walk_deployment!` (`trace.jl:293–323`): the backstop arm at `321–323`
  goes, as its own comment anticipates. `test_diagnostics.jl:563` constructs
  a `ReplayHeaderMismatch` with `name = Symbol("schedule.D")` for the
  rendering testset; the payload stays constructible, so the test stands.
- `compile(b, act, sch::Schedule; chunk_size, algorithm)` (`build.jl:1331`)
  takes the schedule. A helper beside it, `_gates(sch::Schedule, s::Structure)`
  or a name of the agent's choosing, yields the per-component `(D, Φ, Δt)`
  from the rows by `s.paths[ci]`, and `(1, 0, 0.0)` for a component with no
  row (the continuous tier); the executor's entries are built from that as
  today. Callers: `sim.jl:221`, `trim.jl:505`, `test_trim.jl:483`.
- Tests: `test_discrete.jl:271–272` assert over the rows (or over the
  helper's output) the same numbers; the `Δt ≈` conjunct keeps its
  tolerance.
- The `Schedule` docstring and `implementation.md`'s `deployment.jl` row
  ("and the `D`/`Φ`/`Δt` vectors the executor compiles over") and
  `build.jl` row (`compile`'s signature) follow.

### B3, `xblocks` on the layout

Slice B, finding 3. `Executor.xblocks` (`build.jl:1298`) has one cold
reader, `_nonfinite` (`sim.jl:639`, `646`), while `_x_offsets`
(`conditions.jl:384–391`) recomputes the same ranges at `readers.jl:243`,
`conditions.jl:339` and `836`, and `compile` recomputes them a fourth time
(`build.jl:1349–1356`).

- `Layout` (`build.jl:503–507`) gains `xblocks::Vector{UnitRange{Int}}`,
  computed once in `cell_layout` (`509–573`) beside `sizes`, from the same
  arithmetic; `_x_offsets` may become that computation's one home, called
  from `cell_layout` alone, or be inlined there and deleted.
- `compile` reads `act.layout.xblocks` and drops its inline loop and the
  `Executor` field (`1298`, constructor arg 11 at `1491`); `_nonfinite`
  reads `ex.act.layout.xblocks`; the three service callers read the field.
- Check in a REPL, on `MultiRate` or the fixture of `test_conditions.jl`,
  that the field equals what `_x_offsets` returned before the change.

### B4, `Activation.stage1`

Slice B, finding 4, REPL-confirmed inert. `Activation` (`build.jl:603–608`)
loses `stage1`; `_nominal` (`907`, arg at `922`) and `_activate` (`932`,
arg at `943`) stop building it; `probe_stage1` (`256–261`) returns
`NamedTuple()` for a frozen component, or `_activate` passes no carry,
whichever reads cleaner. Tests `test_build.jl:370`, `1195`, `1196`, `1212`
read `products[ci]` restricted to `dataflow.stage1[ci]`'s names, which is
what the field held (`stage1[ci] == products[ci][Tuple(dataflow.stage1[ci])]`).

### B8, `Chunk.clock`

Slice B, finding 8, REPL-confirmed. `Chunk` (`executor.jl:450–456`) loses
`clock` and its type parameter; `chunked_body` (`514–521`) loses the
`clock` argument; `compile` (`build.jl:1474`) stops passing it.

### B9, `GridEntry.anchor`

Slice B, finding 9. `GridEntry` (`diagnostics.jl:1216–1223`) loses
`anchor`; `_grid_report` (`deployment.jl:53`, the constructor call at `86`)
stops passing `ks[i]`. `test_discrete.jl:465` asserts `provenance` in its
place; the strings are the `aprov` renderings, so match with `occursin` on
the key as `396` does, or compare the whole strings the fixture produces.

### B10, the event set's buffer references

Slice B, finding 10. `EventSet` (`executor.jl:262–292`) loses `store` and
`xbuf`; `_projects!(es, xbuf)`, `_guards!(es, store, xbuf)` and `_fire!(es,
store, xbuf)` (`300`, `307`, `321`) take them; the callers hold
`sim.exec` (`sim.jl`, grep `exec.events`; `localization.jl:176`); `compile`
(`build.jl:1486`) stops passing them.

### Bookkeeping

`implementation.md`'s rows for `assembly.jl` (22), `executor.jl` (24),
`build.jl` (25), `deployment.jl` (30) and `diagnostics.jl` (20, if it
names `GridEntry`'s columns), D-261 in their citation columns.
`pending.md:77–89`: delete the `Schedule` clause. One commit, subject line
only, no attribution, for example "Derive the executor's gates from the
schedule's rows and drop the build's dead and duplicate fields".

---

## Stage 2 — the loop

The two changes thread the same three functions, `_localized_frame!`
(`localization.jl:44–165`), `frame!` (`31–36`) and `_advance!`
(`sim.jl:1183–1215`), so they land together.

### B2, the hit as a return value

Slice B, finding 2. `ExecutionCursor` (`executor.jl:20–28`) loses `hit`
and its docstring line (`15–18`).

- `_localized_frame!` returns the face at the site that wrote it
  (`localization.jl:159`, `cur.hit = face; return nothing` becomes `return
  face`) and `nothing` at the frame-top exit. Its return type is
  `Union{Nothing,Symbol}`, no allocation; the measured `body()` path is not
  touched.
- `frame!` returns what `_localized_frame!` returns, `nothing` from the
  `step!` branch, and stamps the clock only when the return is `nothing`
  (today's `cur.hit === nothing` test at `34`).
- `_advance!` drops the `cur.hit = nothing` write at the frame top
  (`sim.jl:1198`) and reads `frame!`'s return where it read `cur.hit`
  (`1202`, `1207`).
- Check in a REPL that the `t*` stop test in `test_lifecycle.jl` (grep
  `stop_on` beside a localized fixture) still stops at the `t*` snapshot,
  and that the drain and frame allocate nothing where `test_trace.jl`'s
  `@allocated` assertions already measure.

### D3, the addresses as the loop's argument

Slice D, finding 3. `StopPolicy` (`sim.jl:46–50`) shrinks to `(t_end,
faces)`; the docstring above it (`37–45`) loses "with their compiled
root-cell addresses".

- `_bind_policy` (`332`) returns the policy and the compiled addresses
  beside it, `(pol, addrs)`.
- `_stop_hit(sim, pol, addrs)` (`401`) reads the addresses off the
  argument; `_advance!` (`1183`), `frame!` and `_localized_frame!` carry
  `addrs` beside `pol`; `_run_body!` (`1083`) and its callers `run!`
  (`1032`), `replay!` (`879`) and `step!` (`1336`) hold both from the
  binding to the loop. `_record` (`395`; calls at `1137`, `1144`, `1370`,
  `1378`) takes `pol` as today, now the declared pair.
- `UnboundedRun`'s advisory reads `t_end` and `faces` (grep
  `UnboundedRun(` in `sim.jl`); unchanged.
- Tests: `test_stepper.jl:93` and `test_localization.jl:221` build
  `StopPolicy(Inf, Symbol[])` and pass `Any[]` as the addresses to
  `frame!`; `test_lifecycle.jl:249`, `256` stand.
- Comments naming the policy's addresses: grep
  `rg -n "resolved addresses|compiled.*addresses|addrs" src/sim.jl src/localization.jl`
  and sweep.

### Bookkeeping

`implementation.md`'s rows for `executor.jl` (24: "carrying the loop's stop
hit beside the frame it names"), `sim.jl` (28: `StopPolicy`'s description)
and `localization.jl` (31: "off the policy `frame!` carries"), D-261 in
their citation columns. `pending.md:77–89`: delete the cursor and
`StopPolicy` clause. One commit, for example "Return the t* stop hit from
frame! and carry the stop faces' addresses as the loop's argument".

---

## Stage 3 — the periphery

### C1, and the plane's constructor

Slice C, finding 1, and D-261's "no drain thunk at construction". The
plane holds `store::Any` (`roster.jl:190`) for `_install_writers!` alone
(`trace.jl:196`, `199`), and `DataPlane(layout, store, trc)`
(`roster.jl:198–204`) compiles the harness thunk against the placeholder
run's trace, which the first door discards; that compile is why
`Simulation()` builds the run ahead of the plane (`sim.jl:222–231` and the
comment above `DataPlane`'s constructor, `roster.jl:194–197`).

- `DataPlane(layout::Layout)`: no store, no trace. The `store` field goes.
  `harness_drain` is initialized to a sentinel,
  `_no_drain() = throw(InternalInvariant("drain thunk called before a door compiled it"))`,
  defined beside `_drain_thunk` (`roster.jl:147`).
- `_install_writers!(plane, store, trc)` (`trace.jl:182–200`) takes the
  store; it stays the one compile site. `reclaim!(plane, layout, store,
  trc)` (`roster.jl:247–262`) passes it through and keeps compiling
  unconditionally, at every roster change, as today. Callers: `attach!`
  (`sim.jl:1473`), `detach!` (`1507`), `_open_run!` (`690`), each with
  `sim.exec.store` in hand.
- `attach!`'s provisional entry thunk (`sim.jl:1469`) becomes `_no_drain`;
  `reclaim!` replaces it before `attach!` returns.
- `Simulation()` builds the plane without the run; the ordering comment
  goes. The docstring of `DataPlane` ("the store the thunks compile
  against") and `_install_writers!`'s ("Before the first `init!` the
  appends land on the placeholder run's trace") follow; after stage 4 the
  placeholder's trace is `nothing`, so nothing is appended before a door.
- Check in a REPL: `attach!` on a `built` simulation, then `init!`, `run!`
  to some `t_end`, and the device's writes land as before
  (`test_devices.jl` has the idiom); and `detach!` after a stop followed by
  `run!` with no door between still drains through recompiled thunks.

### C2, the handle's `id`

Slice C, finding 2. `DeviceHandle` (`devices.jl:122–135`) loses `id`; the
constructor call at `sim.jl:1466` drops its first argument. The handle's
`who` string keeps rendering the id.

### C3, the entry's mirrors

Slice C, finding 3, as D-261 reduced it: `RosterEntry` (`roster.jl:120–130`)
loses `binding`, `writer` and `diag`, keeps `dev`, `id`, `drain`,
`should_abort`, `acct`, `handle`.

- The include order (`Cadence.jl:17–21`: `dataplane`, `trace`, `roster`,
  `bindings`, `devices`) puts `DeviceHandle` after `RosterEntry`, and the
  handle holds a `Control` and a compiled gather from the two later files,
  so typing the field would move three definitions across files. Do not.
  Keep `handle::Any` and add `_handle(e::RosterEntry) = e.handle::DeviceHandle`
  beside `_who` (`134`), which already pays the assert; every reader goes
  through it. A typeassert is a check, not an allocation; confirm on the
  frame top with `@allocated` where `test_trace.jl` measures the drain.
- Readers to reroute: `e.writer` at `roster.jl:249`, `trace.jl:149`, `196`
  and `sim.jl:671`, `1613`; `e.diag` at `sim.jl:1578`, `1613–1614`, `1706`
  and `devices.jl:350`, `381`, `471`; `e.binding` at `sim.jl:1445`
  (`binding(_handle(e))`). The constructor calls at `sim.jl:1468` and
  `trace.jl:194–197` lose the three arguments.
- Tests: `test_bindings.jl:100`, `247`, `test_roster.jl:110`, `133` read
  `.handle.writer.faces`; `test_bindings.jl:151` reads `binding(h) ===
  binding(sim.plane.roster[1].handle)`, or simply that `h ===
  sim.plane.roster[1].handle`; `test_roster.jl:136` reads `.handle.diag`.
- §12.4's "binding, claims, stable device id" survive a stop on the entry
  through its handle; the `RosterEntry` docstring says so.

### C4, the handle's plane

Slice C, finding 4. `DeviceHandle.plane::DataPlane` (`devices.jl:127`)
becomes `claimedby::Dict{Symbol,String}`, the plane's own `Dict` by
reference; `stage!` (`229`) reads `h.claimedby`; `attach!` passes
`plane.claimedby` (`sim.jl:1466`). `published` stands. The handle's
docstring ("deliberately *not* the `Simulation`") gains that it holds the
exclusivity index alone, not the plane.

### E1, the plan's face slot

Slice E. `ConditionPlan.inputs` (`conditions.jl:257`) becomes
`Vector{Tuple{Any,Any}}`, `(cell address, value)`; `resolve_condition`
(`279`; the push at `290`, the constructor at `307`) drops the face;
`apply!` (`534`) destructures `(addr, v)`. Check whether `compile_plan`'s
specialized `inputs` (`665`, `700–711`) carries the same slot and drop it
there too if so. `faces` (`258`) stays the plan's root-input coverage.
Test `test_conditions.jl:86`: read the value by position through `p.faces`
(`only(v for (f, (_, v)) in zip(p.faces, p.inputs) if f === face)`); `92`,
`118`, `226` stand.

### Bookkeeping

`implementation.md`'s rows for `roster.jl` (34: "`DataPlane(layout, store,
trc)` compiling the harness thunk against the run's trace"), `trace.jl`
(33: `_install_writers!`), `devices.jl` (36, the handle), `conditions.jl`
(37, if it names the plan's tuple) and `sim.jl` (28, if it names the
plane's construction), D-261 in their citation columns. `pending.md:77–89`:
delete the handle, entry and `DataPlane` clauses. One commit, for example
"Compile the drain thunks at the doors alone and read the entry's writer,
cell and binding through its handle".

---

## Stage 4 — the run

Slice D, finding 1, as D-261 rules it: `trace`, `log`, `log_every` and
`log_max` are keywords of `init!` and `replay!`, with the same defaults;
`Simulation(deployment, T; join_timeout = 5.0, chunk_size = 16)` keeps
two.

### The doors

- `Simulation()` (`sim.jl:204–231`): the four keywords and their
  validation go; the placeholder is `Run{T}(SnapshotLog(true, 1, typemax(Int)),
  nothing, nothing, nothing)`, an empty log built at the defaults that
  nothing reads and no trace. The docstring's synopsis (its head, through
  `142`) and its "The recording flags are carried to `init!`" paragraph
  (`198–202`) say the keywords are the doors'.
- `init!(sim, condition = fragment(); t0 = 0.0, trace = true, log = true,
  log_every = 1, log_max = 65536)` (`755`): validates the four exactly as
  the constructor did (`ArgumentInvalid(call = :init!, reason = :range,
  argument = …)`, collected into one throw, D-229), after the lifecycle
  gate and before `resolve_condition`, so a refused keyword writes
  nothing. It passes the four to `_open_run!` and tests `trace` where it
  tested `sim.run.trace === nothing` for the header capture (`770`).
- `replay!(sim, trc; …, trace = true, log = true, log_every = 1, log_max =
  65536)` (`879`): the same validation under `call = :replay!`, beside the
  `to_boundary`/`to_time` refusals it already collects; `on = trace` at
  `940`.
- `_open_run!(sim, header, schemas, feed, trace::Bool, log::Bool,
  log_every::Int, log_max)` (`686–691`), or a small `NamedTuple` for the
  four, builds `SnapshotLog(log, log_every, log_max === Inf ? typemax(Int)
  : Int(log_max))` and `trace ? Trace{T}(header, schemas, TraceBatch[], 0)
  : nothing`; it reads nothing off the previous run. Its comment (`678–685`)
  follows.
- `trace(sim)` (`1763–1770`): the lifecycle check first, `MissingInit` on
  `:built`; then `nothing` refuses `:disabled`; the headerless check stays
  as an invariant of a door-built trace or goes, the agent's call, with a
  line in the report. Its docstring's "construction-time kill switch"
  becomes the door's keyword.
- `live!` (`976`) is unchanged: it builds no run.

### Diagnostics and comments

- `diagnostics.jl:1799–1801`, the `:disabled` message: "this simulation was
  initialized with `trace = false` … the door's keyword (D-261)", D-029's
  citation kept for the default. The comment at `1826–1828` ("The
  materialization's keywords (D-256)") splits: `join_timeout` stays the
  materialization's, the four are the doors'. The comment at `1250` names
  the same clause.
- Grep `rg -n "trace = false|log_every|materializ|construction-time|placeholder" src/`
  and sweep every comment and docstring that places the keywords on the
  constructor: `Run`'s docstring (`74–94`, "fixed by the constructing
  entry point" stands, "the trace switch rides here" stands), `trace.jl:172`,
  `SnapshotLog`'s docstring if it names the constructor.

### Tests

- The 32 sites move the keyword from `Simulation(…)` to the `init!` (or
  `replay!`) that follows. `mk` (`test_log.jl:101`) forwards `kw...` to
  `init!` instead. `replay_twin` (`test_trace.jl:422–426`) takes the four
  for its own `init!`, and the testset at `884–890` passes `trace = false`
  to **both** its `init!` and its `replay!`, since the replay builds a run
  of its own. `test_trace.jl:98` likewise.
- `test_diagnostics.jl:515–518`: `call = :init!`. `test_log.jl:145–151`
  and `test_discrete.jl:367–372`: the refusals land at `init!`, and the
  latter's premise, that `log_every` refuses on its own barrier beside the
  deployment's `h`, becomes trivial; keep one assertion that `init!(sim;
  log_every = 0)` refuses with `d.call === :init!` and leaves the
  simulation `built`.
- `test_lifecycle.jl:60–80`, the placeholder testset: `trace(sim)` before
  the first `init!` still refuses `MissingInit` with `status === :built`.
  Add: `init!(sim, …; trace = false)` then `trace(sim)` refuses
  `:disabled`; a second `init!(sim, …)` at the defaults records again,
  `trace(sim).frames == 0` and `sim.run.trace !== nothing`. That is the
  per-run policy D-261 buys.
- `test_lifecycle.jl:65`'s `fieldnames(Run)` stands.

### Bookkeeping

`implementation.md`'s rows for `sim.jl` (28: "the materialization
`Simulation(deployment, T)` with its own keywords under `ArgumentInvalid`,
its placeholder run built ahead of the plane and carrying the recording
flags to `init!`, the trace switch among them" becomes the doors' keywords
and an empty placeholder), `diagnostics.jl` (20: `ArgumentInvalid`'s arms),
`trace.jl` (33, if it names the switch), D-261 in their citation columns.
`pending.md:77–89`: delete the bullet. One commit, for example "Take the
four recording keywords on init! and replay! and empty the placeholder
run".

---

## Rules for every stage

- Run the suite in the foreground with a 600 s timeout, under the sandbox
  flags of "Running the suite"; never in the background. Never stash, reset
  or check out the working tree. Baselines come from `git show
  296f4a0:<file>`.
- Check every runtime claim above in a REPL before relying on it
  (`julia --project=test -L test/repl.jl` opens one with the fixtures). The
  slice reports' scratchpad scripts are gone; re-derive what a stage needs.
- Read the slice entry for each finding before editing: it lists every
  reader, and a reader this brief does not name is still a reader.
- `test/imports.jl` lists every framework name a test calls; nothing new is
  expected unless a test names one it does not list.
- A stage that finds the suite red on a file it did not touch stops and
  reports, with the failing testset's name.

## Report format

For each stage: the commit hash and subject; every site the brief or the
slice report cited that did not hold as described, with what was there
instead; every deviation from the shapes above, with the reason; the
suite's result line (the pass/fail/error counts) and its wall time; and
handoff notes for the next stage or the reviewer, one line each, on
anything the reviewer should probe.
