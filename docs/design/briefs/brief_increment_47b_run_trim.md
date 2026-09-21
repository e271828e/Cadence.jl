# Increment 47b — The run's trim: `t₀` and the policy off the run, the mode read off the feed, a `Float64` origin, `TraceRegister` retired (§11.5, §12.6, §12.7, §13.5, Appendix B, D-260)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `142c00a` (the docs commit below) plus the commit that adds this
brief. The line numbers cited are those of `142c00a`.
Never `cd` elsewhere (`cd` is aliased to zoxide in the user's shell; use
absolute paths).

**Standing.** D-260 (`decisions.md:9686`) amends D-255: a `Run{T}` keeps
what lasts from one door to the next and the state that evolves in between,
and nothing else. The spec says so since `142c00a`. The code still holds a
six-field `Run{T}` (`sim.jl:82–89`) whose `t₀` no reader reads, whose
`policy` is written at every `run!` and `step!` (`sim.jl:1012`, `1333`)
only so two readers without the loop's argument can reach it
(`localization.jl:153`, `sim.jl:370`), and whose `const mode` makes the two
flips rebuild the run (`sim.jl:960`, `1045`). The origin is typed in the
deployment's scalar on the clock (`store.jl:123`), the header
(`trace.jl:46`) and `init!`'s keyword (`sim.jl:730`), so a `Dual`
simulation refuses `t0 = 0.25`. And `TraceRegister` (`trace.jl:141–152`)
holds five fields the plane carries for the drain: a switch, a duplicate of
the run's trace, a frame ordinal the trace already counts, a writer range
read only where it is written, and the replay feed, which is run state.
This is an in-between increment of `roadmap_pipeline_redesign.md`, step 6b,
before increment 48.

**The pre-flight probe** (2026-09-21, greps at `142c00a`, no REPL). No test
reads `run.policy`; the two policy reads in the suite go through
`termination(sim).policy` (`test_lifecycle.jl:247`, `254`). `Run.t₀` is read
twice, both in the placeholder testset (`test_lifecycle.jl:66`, `75`); the
clock's `t₀` three times, all `=== 0.5`-style on `Float64` simulations
(`test_readers.jl:216`, `test_trim.jl:107`, `469`); the header's `t₀` twice
(`test_trace.jl:93`, `539`). The plane's `recorder` is read seven times, all
in `test_trace.jl`: `live_writers` at 140, 156 and 659, `feed === nothing`
at 437, 595, 634 and 674. Two tests assert that a flip builds a new run,
`sim2.run !== r` (`test_trace.jl:598`, `675`); both keep asserting the log
and trace identities. The kill-switch tests read the placeholder trace's
fields at `test_trace.jl:104`, `884` and `885`. `Trace{Float64}(…)` is
constructed by hand three times (`test_trace.jl:201`, `277`, `288`), always
from an existing header. `init!` passes `t0` at 15 sites, none on a `Dual`
simulation. `mode(` is called 23 times, `closed(` 10, `termination(` 51,
`trace(sim` 33, `live!(` 6. `test/imports.jl` imports `Run`, `closed`,
`mode`, `ReplayFeed`, `Trace`, `TraceHeader`; it does not import
`TraceRegister`, and no test names it.

**Two stages, two commits, in this order.**

- **Stage 1, the origin and the policy.** `t₀` off the run and `Float64` on
  the clock, the header and `init!`; the policy threaded through the frame
  call and the record's assembly, and off the run.
- **Stage 2, the mode and the register.** `mode` folded into a writable
  `feed` on the run, the flips and the close as writes, `TraceRegister`
  retired, the thunks closing over the run's trace, the ordinal off the
  trace's own count, the switch riding on the run.

Both stages touch `sim.jl` and stage 1 touches `store.jl`, so the routed
subset is the table's last row, all of it, under the sandbox flags.
`implementation.md`'s "Running the suite" (114–165) is the one home of
test policy; this brief does not restate it. The gate is the reviewer's.

**Read, in `docs/design/spec.md`:** §12.6's opening, 7042–7075 (`Run{T}` at
7044–7054, the placeholder run at 7055–7060, the five fields at 7061–7075),
the mode paragraph at 7084–7090, and the per-advance policy paragraph at
7209–7216. §12.7's flip and `live!` bullets, 7308–7332, and the re-record
bullet, 7356–7359. §11.5's header bullet, 5818–5826, `Trace{T}` at
5828–5833, and the switch paragraph, 5857–5867. §13.5 in full, 7963–8110.
Appendix B's `init!` entry, 10887–10891, and `mode`/`live!`, 11001–11010.
The glossary's `Run` (12160), input mode (12231), recorders (12242), run
metadata (12252) and termination record (12420). In
`docs/design/decisions.md`: **D-260 (9686–9760)**, D-255 (9430), D-256
(9512), D-218 (7724), D-219 (7769), D-060 (1640).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (114–165)**: the routed subset, the flags.
- The file-table rows for `src/store.jl` (23), `src/build.jl` (25),
  `src/sim.jl` (28), `src/localization.jl` (31), `src/dataplane.jl` (32),
  `src/trace.jl` (33), `src/roster.jl` (34), `test/fixtures.jl` (39),
  `test/imports.jl` (40).
- **"Authoring caveats" in full (62–112)** — always. The init-service
  keyword is `t0` while the concept stays `t₀`.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–45); this
increment delivers its last sentence, "The run's trim … (D-260)", which
stage 2 retires.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the decision and this brief disagree, stop and say so in the
report rather than improvising. Where a site does not hold what the brief
claims, report it rather than inventing a substitute. No behaviour beyond
the trim: no new validation of `t0`, no new accessor, no rendering.

---

## Stage 1 — the origin and the policy

### The origin

The origin is a `Float64`, like `h` (`deployment.jl:308`) and
`StopPolicy.t_end` (`sim.jl:45`). The clock's `t` stays in the deployment's
scalar `T`; only `t₀` changes type.

- `Clock{T}` (`store.jl:119–125`): `t₀::Float64`. The one constructor site
  is `build.jl:1360`, `Clock(zero(T))`; give the clock a constructor that
  takes the `Float64` origin and converts it into `t`, and use it there.
  Check in a REPL that a `Dual` clock still constructs (`zero(Dual)` into a
  `Float64` field is the trap; the origin must arrive as a `Float64`).
- `TraceHeader{T}` (`trace.jl:40–49`): `t₀::Float64`. `_capture_header`
  (`trace.jl:260–268`) reads it off the clock, unchanged. `_detach`
  (`trace.jl:200`) copies it, unchanged. `replay!` reads `trc.header.t₀` at
  `sim.jl:881` for `to_time`'s bound and applies it at 906; both stand.
- `_open_trajectory!(sim, t₀::Float64)` (`sim.jl:636`): the `clock.t = t₀`
  write converts into `T`; `clock.t₀ = t₀` is exact.
- `init!(sim, condition = fragment(); t0::Real = 0.0)` (`sim.jl:730`):
  `Float64(t0)` at the door. The docstring's "`t0` is a service argument"
  sentence stands; say the origin is held as a `Float64`.
- `Run{T}` loses `t₀`. `_open_run!` (`sim.jl:658`) loses the argument, the
  placeholder (`sim.jl:203`) loses `zero(T)`, and the two rebuilds
  (`sim.jl:960`, `1045`) lose `r.t₀`. Every reader of the origin already
  reads `sim.exec.clock.t₀` (`sim.jl:259`, `localization.jl:14`,
  `trace.jl:268`); confirm by grep that none reads the run's.

### The policy

The policy is the advance's argument from the call to the record.

- `Run{T}` loses `policy`; `_open_run!` loses the `pol` argument; `run!`
  (`sim.jl:1012`) and `step!` (`sim.jl:1333`) drop the `sim.run.policy =
  pol` write; `replay!` (`sim.jl:914`) passes `pol` to `_run_body!` alone.
- `_record(sim, pol::StopPolicy, src, residue)` (`sim.jl:369–370`) takes
  the policy. Its four call sites, `sim.jl:1115`, `1122`, `1349` and `1357`,
  all hold `pol` in scope.
- `frame!(sim, k, pol)` (`localization.jl:28`) and
  `_localized_frame!(sim, t_to, pol)` (`localization.jl:41`) carry it to
  the t* sampling read at `localization.jl:153`, which becomes
  `_stop_hit(sim, pol)`. The one caller is `sim.jl:1179` inside `_advance!`,
  which has `pol`. The stepper seam `step!(sim, h)` (`sim.jl:585`) is a
  different function and does not change.
- Comments and docstrings that say the policy is "bound on the run"
  (`StopPolicy`'s at `sim.jl:37–43`, `Run`'s at 72–80, `termination`'s at
  349–360, `_record`'s at 363–368, `run!`'s at 964–1008, `step!`'s at
  1281–1313, the §13.5 comment at `localization.jl:149–152`) say instead
  that it is the advance's argument and the record's field. Grep
  `rg -n "bound on the run|binds on the run|rebound" src/` and sweep.

### Tests

- `test_lifecycle.jl:66` and `75`: drop the `r0.t₀`/`r1.t₀` conjuncts;
  the rest of the placeholder testset stands until stage 2.
- Add one assertion on a `Dual` simulation: `init!(sim; t0 = 0.25)`
  succeeds, `sim.exec.clock.t₀ === 0.25` and `sim.exec.clock.t` is a `Dual`
  whose value is `0.25`. Find an existing `Dual`-materialized fixture in
  `test_conditions.jl`, `test_store.jl` or `test_readers.jl` (grep
  `Simulation(` beside `Dual`) rather than writing a new one; if none
  materializes at `Dual`, say so in the report and add the smallest one
  beside the readers' twin.
- No test reads `run.policy`. The record's policy tests
  (`test_lifecycle.jl:236–255`) must pass unchanged.

### Bookkeeping

`implementation.md`'s rows for `src/store.jl` (23, if it names the clock),
`src/sim.jl` (28: the `Run{T}` sentence and the "binds on the run" clause),
`src/localization.jl` (31, if it names the t* read) and `src/trace.jl` (33:
"its `t₀`"), with D-260 joining their citation columns. One commit, subject
line only, no attribution, for example "Take the origin off the run as a
Float64 and thread the stop policy from the call to the record".

---

## Stage 2 — the mode and the register

### The run's final shape

```julia
mutable struct Run{T}
    const log::SnapshotLog
    const trace::Union{Nothing,Trace{T}}          # nothing under the trace switch
    feed::Union{Nothing,ReplayFeed}               # attached ⇔ the mode is :replay
    termination::Union{Nothing,TerminationRecord{T}}
end
mode(sim::Simulation) = sim.run.feed === nothing ? :live : :replay
```

`init!` and `replay!` construct one and rebind `sim.run`; nothing else
rebinds it. The two flips write `feed = nothing`; the two tails write
`termination`. `closed(run)` (`sim.jl:98`) stands.

- `_open_run!(sim, header, schemas, feed)` (`sim.jl:658–669`): the log
  flags ride on the previous run as today; the switch rides the same way,
  `sim.run.trace === nothing` meaning off, so the new run's trace is
  `nothing` or a fresh `Trace{T}(header, schemas, TraceBatch[], 0)`. The
  feed goes in at construction: `nothing` from `init!`, the compiled feed
  from `replay!`, which drops its `reg.feed = feed` line (`sim.jl:918`).
  Then `_install_writers!` against the new trace (below).
- `init!` (`sim.jl:745–747`) and `replay!` (`sim.jl:907–915`) read the
  switch off `sim.run.trace` instead of `reg.enabled` when deciding whether
  to capture or detach a header.
- `live!` (`sim.jl:952–962`): refuse when `r.feed === nothing`
  (`ArgumentInvalid(call = :live!, reason = :not_replaying)`, unchanged);
  otherwise `r.feed = nothing`. No rebuild.
- `_settle_mode!` (`sim.jl:1039–1048`): `f = sim.run.feed`; return when
  `nothing`; when `clock.step ≥ f.frames`, `sim.run.feed = nothing`. No
  rebuild.
- `_replay_bound` (`sim.jl:1029–1030`): read the feed off the run.
- `drain!` (`sim.jl:1542–1564`) and `_replay_drain!` (`sim.jl:1585–1613`):
  the replay branch is selected by `sim.run.feed`; `_replay_drain!` takes
  the feed and reads the trace off the run.
- `_feed` (`trace.jl:156–161`) and its `InternalInvariant` go: the state it
  guarded is unrepresentable.
- The placeholder (`sim.jl:200–207`): the run is built before the plane,
  with `trace ? Trace{T}(nothing, Pair{String,Vector{Symbol}}[], TraceBatch[], 0) : nothing`,
  no feed, no termination; `TraceRegister(trace)` goes.
- The `Simulation` docstring's last paragraph (`sim.jl:175–178`) and the
  "placeholder run" comment say the switch rides on the run.

### The register's retirement

`TraceRegister` (`trace.jl:120–152`), its docstring, `_feed`, and the
plane's `recorder` field (`roster.jl:190–191`) go, with the ordering note
above `DataPlane`'s constructor (`roster.jl:194–197`) and the `reg =
TraceRegister(trace)` line (`sim.jl:201`). Its five fields land as follows.

- **`trace`.** The drain thunks close over the run's trace.
  `_drain_thunk(store, w, trc, widx)` (`roster.jl:146`) and
  `_drain!(store, w, trc, widx)` (`dataplane.jl:566–572`), with
  `trc === nothing || _record!(trc, widx, batch)` inside. The closure
  captures a concrete `Trace{T}` or `nothing`, so the branch folds. Keep
  `trc` untyped in `_drain!`'s signature for include order, as `reg` is
  today (`dataplane.jl:560–561`).
- **`frame`.** `_record!(trc::Trace, widx, batch)` (`trace.jl:171–183`)
  stamps `trc.frames`. `drain!` increments `trc.frames` **at its top**,
  before the replay branch, for both paths; the two tail increments
  (`sim.jl:1562`, `1611`) go. The invariant this rests on: boundary zero
  drains nothing, every frame drains exactly once, and the clock's `step`
  increments after the drain, so at drain time `trc.frames` after the
  increment equals `clock.step + 1`, the ordinal `TraceBatch` documents
  (`trace.jl:52–57`). It holds across a `to_boundary` halt continued live,
  since both counters continue from the halt. `_replay_drain!` keeps
  `frame = clock.step + 1` for the feed's record matching and the discard
  reports, since the trace may be `nothing` there.
- **`live_writers`.** A local of `_install_writers!(plane, trc)`
  (`trace.jl:217–237`): `trc === nothing` keeps the provisional `1:k`,
  otherwise the appended range; the thunks are compiled against it and the
  range is not stored. Its callers: `_open_run!` and `reclaim!`
  (`roster.jl:247–257`), which takes the current run's trace from its own
  callers, `attach!` and `detach!` (grep `reclaim!(` for the full list;
  `sim.jl:1448` compiles the provisional thunk with index 0 against the
  run's trace before `reclaim!` recompiles it).
- **`feed`.** On the run, above.
- **`enabled`.** The run's trace is `nothing`; `trace(sim)`
  (`sim.jl:1739–1746`) refuses `:disabled` on `nothing` and `MissingInit`
  on a headerless trace, the same two refusals as today. Grep
  `rg -n "\.enabled" src/` and confirm every remaining hit is the log's.
- `DataPlane(layout, store, trc)` (`roster.jl:199–204`) compiles the
  harness thunk against the placeholder run's trace; the `Simulation`
  constructor builds the run first.

Grep `rg -n "register|recorder|TraceRegister" src/` after the change and
sweep every comment and docstring that survives: `trace.jl`'s `Trace`
docstring (76–83), `roster.jl:170–172`, `dataplane.jl:558–564`, `sim.jl`'s
`drain!` docstring, `_replay_drain!`'s, `live!`'s ("a change of mode is a
change of run", 958–959), `_settle_mode!`'s, `mode(sim)`'s (330–345) and
`Run`'s. The three residues the roadmap's step 6 records stand; the second,
a `replay!` that throws inside boundary zero leaving a `built` simulation
with the feed attached, is now "with `feed` set on the fresh run".

### Tests

- `test_trace.jl:437`, `595`, `634`, `674`: `sim2.run.feed === nothing`.
- `test_trace.jl:598`, `675`: the flip writes the run, so
  `sim2.run === r`, with the log and trace conjuncts kept. Reword the
  comments (the mode is read off the feed; D-260).
- `test_trace.jl:140`, `156`, `659`: `live_writers` is gone. At 140 and
  156 the batches' `writer` indices at 146–148 and 157–158 already assert
  what the range did; drop the range conjuncts. At 659 assert instead that
  a batch drained after the continuation carries a writer index past
  `length(trc.schemas)`, which is what the range said.
- `test_trace.jl:104`, `884–885`: under the switch the run's trace is
  `nothing`; assert `off.run.trace === nothing` and that `trace(off)`
  still refuses `:disabled` (the refusal is likely asserted beside; keep
  it).
- `test_lifecycle.jl:60–78`, the placeholder testset: add
  `@test fieldnames(Run) === (:log, :trace, :feed, :termination)` and
  `sim.run.feed === nothing`; the `r1 !== r0` assertion stands (a door
  rebinds) and `sim.run === r1` after `run!` stands (the close writes).
- Add one assertion that the ordinal comes off the trace: after
  `init!`, three `stage!`/`step!` pairs, `trace(sim).frames == 3 ==
  sim.exec.clock.step` and the last batch's `frame == 3`. The roster
  testset at `test_trace.jl:120–160` already stages and steps; extend it
  rather than adding a fixture.
- The `:not_replaying` refusal of `live!` on a live simulation must still
  pass (grep `not_replaying` in `test_trace.jl`).

### Bookkeeping

`implementation.md`'s rows for `src/sim.jl` (28: the run's fields, "the
mode being one of the run's `const` fields so a change of mode is a change
of run", the placeholder's flags), `src/dataplane.jl` (32, if it names the
register), `src/trace.jl` (33: "`TraceRegister` reduced to the drain's
bookkeeping and held by the plane" goes; the thunks close over the run's
trace, the ordinal is the trace's count), `src/roster.jl` (34: "§11.5's
trace register on the plane" goes; the plane holds `DataPlane(layout,
store, trc)`), D-260 in their citation columns. `pending.md`: retire the
"The run's trim … (D-260)" sentence of the umbrella bullet (43–45). One
commit, subject line only, no attribution, for example "Read the mode off
the run's feed and retire the trace register".

---

## Rules for both stages

- Run the routed subset in the foreground with a 600 s timeout, under the
  sandbox flags of "Running the suite"; never in the background. Never
  stash, reset or check out the working tree. Baselines come from
  `git show 142c00a:<file>`.
- Check every runtime claim above in a REPL before relying on it
  (`julia --project=test -L test/repl.jl` opens one with the fixtures).
  Two to check first: that a `Dual` clock constructs from a `Float64`
  origin, and that a closure over `nothing` folds the record branch (look
  at `@code_typed` of the thunk, or simply at the allocation count of a
  drain under the switch, which `test_trace.jl`'s allocation tests may
  already measure; grep `@allocated` there).
- `test/imports.jl` lists every framework name a test calls; nothing new
  is needed unless a test names one it does not list.
- A stage that finds the suite red on a file it did not touch stops and
  reports, with the failing testset's name.

## Report format

For each stage: the commit hash and subject; every site the brief cited
that did not hold as described, with what was there instead; every
deviation from the shapes above, with the reason; the routed run's result
line (the pass/fail/error counts) and its wall time; and handoff notes for
the next stage or the reviewer, one line each, on anything the reviewer
should probe.
