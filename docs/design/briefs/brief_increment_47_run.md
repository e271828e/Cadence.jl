# Increment 47 — `Run`, `StopPolicy`, the trace split and the `Simulation` regroup (§11.5, §11.8, §12.1, §12.6, §12.7, §13.5, Appendix B, Appendix C, D-250, D-255, D-256)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `9e1577d` (the docs amendment below) plus the commit that adds this
brief. The line numbers cited are those of `8b5a574`; the docs commit shifts
the spec by two lines after §11.5 and one more after Appendix C's
`ReplayHeaderMismatch` row, and the log by three lines after D-255's third
bullet.
Never `cd` elsewhere (`cd` is aliased to zoxide in the user's shell; use
absolute paths).

**Standing.** D-255 made the run state with a type of its own and its stop
policy a value bound per advance; D-256 regrouped the `Simulation` into five
fields by owner. The spec says all of it since `5502e1a`. The code still
keeps `t_end` and `stop_on` as constructor defaults with `run!`/`replay!`
overrides (`sim.jl:26–28`, 87–96), a mutable `RunPolicy` carrying the loop's
`hit` scratch (`sim.jl:13–17`), `termination` on `Control`
(`devices.jl:115`), the trace header growing its schema list in place
(`trace.jl:43`, `_reschema` at 208), a `TraceRegister` holding the whole
recording (`trace.jl:134–143`), and a 19-field immutable `Simulation`
(`sim.jl:19–43`). `UnboundedRun` does not exist (`dataplane.jl:36–37`), and
`EmptyGreedyClaim` is a log line only (`sim.jl:1344–1345`). This increment is
step 6 of `roadmap_pipeline_redesign.md`: items 22–27, item 6, the rest of
item 28 of `notes_pipeline_redesign.md`, and `UnboundedRun`.

**The pre-flight probe** (2026-09-20, greps and reads at `8b5a574`, no
REPL). The suite passes `t_end` or `stop_on` to the *constructor* at 63
sites, not the roadmap's three: `test_failures.jl` 35, `test_lifecycle.jl`
20, `test_trace.jl` 4, and one each in `test_build.jl` (69),
`test_events.jl` (306), `test_readers.jl` (259) and `test_trim.jl` (521).
In those files 44 `run!` calls pass no `t_end` and rely on the constructor's
(lifecycle 16, failures 21, trace 3, and one each in the other four), and
`step!` is called 62 times, none with a policy. No test reads
`control.termination`; every read goes through `termination(sim)`.
`test_trace.jl` reads `header.` 18 times, ten of them `header.schemas`, and
`sim.trace.live_writers` three times (142, 158, 620). `test_log.jl` reads
`sim.log.*` at 59, 68, 78, 79, 87; `test_stepper.jl` reads `sim.stepper` at
9 and 11; `test_localization.jl:208` reads `sim.has_localized`;
`test_trim.jl:483` reads `sim.chunk_size`. `_reschema` is on
`test/imports.jl` and used once (`test_trace.jl:245`).

**Three stages, three commits, in this order.** The roadmap listed five.
`Run{T}` and the trace split merge, since a `Run` holding today's register
would be an interim shape every trace test crosses twice; the greedy-claim
move joins the regroup, both being the plane's business.

- **Stage 1, `StopPolicy` and `UnboundedRun`.** The immutable policy built
  and validated by each advance, `t_end` and `stop_on` leaving the
  constructor for `run!`, `replay!` and `step!`, `hit` onto the execution
  cursor, the record's policy, the advisory, and the 63-site sweep.
- **Stage 2, `Run{T}` and the trace split.** The mutable five-field-bound
  `Simulation`, the run built by `init!` and `replay!`, `termination`
  leaving `Control`, `Trace{T}` as header plus two lists, the register
  reduced to the drain's bookkeeping, the header check's fallback walk.
- **Stage 3, the periphery.** `EmptyGreedyClaim` into the roster entry's
  cell, and the regroup's remainder: the executor's stepper, buffers and
  `chunk_size`; `join_timeout` into `Control`; the loop's cell, account and
  the published holder into the plane.

Every stage touches `sim.jl`, so the routed subset is the table's last row,
all of it. The gate is the reviewer's. `implementation.md`'s "Running the
suite" (114–165) is the one home of test policy; this brief does not
restate it.

**Read, in `docs/design/spec.md`:** §11.5 in full, 5752–5867 (the header's
contents at 5818–5826, `Trace{T}` at 5828–5832, the schema list at
5833–5840, the length at 5850–5853). §11.8's opening, 6346–6360 (the loop's
kinds and `EmptyGreedyClaim`'s home). §12.1's `Control` paragraphs,
6505–6519. §12.4's interrupt paragraph, 6921–6932. §12.6 in full, 7040–7212
(`Run{T}` at 7042–7052, the five fields at 7055–7066, the mode at
7077–7081, the fresh run at 7156–7160, the per-advance policy at
7201–7206). §12.7's header-check block and disposition table, 7392–7420.
§13.1's runtime-warning list, 7658–7705. §13.5 in full, 7953–8103 (the
policy bullet at 7977–8000, the unbounded run at 8001–8014, the record at
8027–8032). Appendix B's running entries, 10902–10995 (`run!`, `step!`,
`replay!`, `closed`, `mode`, `live!`) and the `Simulation(deployment, T)`
entry, 10762–10790.
Appendix C's rows for `StopFaceInvalid` (11249–11252), `EmptyGreedyClaim`
(11270–11273), `ReplayHeaderMismatch` (11330–11337), `ArgumentInvalid`
(11345–11352) and `UnboundedRun` (11406–11411). The glossary's `Run`
(12141–12145), `StopPolicy` (12177–12182), termination record (12401–12404)
and recorders (12223). In `docs/design/decisions.md`: **D-255
(9429–9506)**, **D-256 (9508–9553)**, D-250 (9157–9218), D-203 (7047), D-218
(7723), D-219 (7768).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (114–165)**: the routed subset, the flags, the gate.
- The file-table rows for `src/diagnostics.jl` (20), `src/executor.jl`
  (24), `src/build.jl` (25), `src/sim.jl` (28), `src/stepper.jl` (29),
  `src/deployment.jl` (30), `src/localization.jl` (31), `src/dataplane.jl`
  (32), `src/trace.jl` (33), `src/roster.jl` (34), `src/devices.jl` (36),
  `src/trim.jl` (38), `test/fixtures.jl` (39), `test/imports.jl` (40).
- **"Authoring caveats" in full (62–112)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module; the init-service keyword is `t0` while the concept stays `t₀`.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–42), the
umbrella for increments 43–48; this increment delivers its run sentence
(37–39) and the `EmptyGreedyClaim` clause (31–32). The "§12 beyond its
built slices" bullet (43–47) ends "`run!` requires a finite `t_end`", which
retires here. The "§11.7 … §11.8 remainder" bullet (48–50) names
`UnboundedRun`, which leaves it.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the decisions and this brief disagree, stop and say so in the
report rather than improvising. Where a site does not hold what the brief
claims, report it rather than inventing a substitute.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show <tip>:path`. Never run the suite in the background. The build
tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset. A REPL check of a fixture
defined in a `test_*.jl` file loads `test/repl.jl`, `using Test, Logging`
and `test/utils.jl` (`single`, `fed`, `failure`, `carried`), then
reproduces the fixture. The audit refresh under
`docs/reports/20260915_audit` sits uncommitted on purpose: never
`git add -A`; add each path by name.

## Decisions taken in this brief

Settled 2026-09-20 while briefing, each a reading of the spec where it
leaves a shape open; the reviewer checks them against the sections cited.

- **The recording's length lives on the trace, not on the run.** D-255
  rostered `frames` among `Run`'s writable fields, and §11.5 says the trace
  "carries its length" (5850–5853) because `replay!` needs it in the value
  `trace(sim)` hands back (`_compile_feed`'s bound, D-218). At `8b5a574` the
  live counter has one reader, `trace(sim)`, and every reader of the length
  reads a `Trace`; the loop reads `clock.step`. So `Trace{T}` is a `mutable
  struct` with `const header`, `const schemas`, `const batches` and a
  writable `frames`, and `Run{T}` has six fields, no `frames`. Ruled
  2026-09-20 and landed as `9e1577d`: D-255's first and third bullets,
  §12.6's opening, §11.5's `Trace{T}` paragraph and the glossary's `Run`
  entry say so.
- **The register is the drain's bookkeeping and lives on the plane.**
  D-255 keeps "the cursor fields and the replay feed" on the register
  without naming its home. The drain thunks close over it (`trace.jl:249`,
  252), it outlives every run, and the plane holds the writers, so
  `DataPlane` gains `recorder::TraceRegister` and the register keeps
  `enabled`, `frame`, `live_writers`, `feed` and a reference to the current
  run's `Trace`. `mode` is the run's, as D-255 says.
- **`hit` sits on the execution cursor.** §13.5 puts the loop's `hit`
  scratch "beside the execution cursor, never in the policy" (7986–7988).
  `ExecutionCursor` (`executor.jl:15–21`) gains
  `hit::Union{Nothing,Symbol}`; the frame loop resets it per frame,
  `_localized_frame!` writes it, `frame!` and `_advance!` read it.
- **`UnboundedRun` fires when the frame budget is unbounded.** Appendix C
  says "raised at `run!` when `t_end` is `Inf` and no stop faces are given".
  A `run!` in `:replay` is bounded by the recording (D-218) and ends
  `initialized`, so the advisory would be false there: it is raised at
  `run!` in `:live` mode with `Inf` and no faces, and nowhere else (`step!`
  is bounded by its count, `replay!` by the recording).

## Docs amended ahead of launch

Landed docs-commit-first as `9e1577d`, the four tools green:

- D-255's first and third bullets, §12.6 (7044–7048), §11.5's `Trace{T}`
  paragraph (5828–5833) and the glossary's `Run` (12143–12147): `Run` has
  six fields, `frames` is the trace's (above).
- Appendix C's `ReplayHeaderMismatch` row (11332–11340): the deployment
  arm gained a schedule clause, a schedule row whose column differs (the
  component path, the column, recorded vs. bound value), since §12.7 as
  amended on 2026-09-20 has the value cover the schedule with every column.
- Appendix C's `ArgumentInvalid` row (11348–11350): "where it joins
  `StopFaceInvalid` in the one throw" went; with `stop_on` off the
  materialization, `StopFaceInvalid` is an advance's own throw.

## Stage 1 — `StopPolicy` and `UnboundedRun`

Files: `src/sim.jl`, `src/executor.jl`, `src/localization.jl`,
`src/devices.jl`, `src/dataplane.jl`, `src/diagnostics.jl`, `src/trace.jl`,
`test/imports.jl`, `test/test_lifecycle.jl`, `test/test_failures.jl`,
`test/test_trace.jl`, `test/test_events.jl`, `test/test_readers.jl`,
`test/test_trim.jl`, `test/test_build.jl`, `test/test_devices.jl`,
`test/test_diagnostics.jl`, `docs/design/implementation.md`,
`docs/design/pending.md`.

### The policy

```julia
"""
The stop policy one advance declares (§13.5, D-255): the clock bound and the
stop faces with their compiled root-cell addresses, built and validated by
`run!`, `replay!` and `step!` per call and bound on the run for that advance.
`ControlRequestedStop` is outside it: the policy is what the caller declares,
the stop word is what anyone can issue (§12.1).
"""
struct StopPolicy
    t_end::Float64            # Inf = no clock bound
    faces::Vector{Symbol}     # declaration order: the order a holding face is reported in
    addrs::Vector{Any}        # their compiled root-cell addresses
end
```

`RunPolicy` (`sim.jl:5–17`) goes, docstring and all. One binder shared by
the three advances, in `sim.jl` beside `_stop_faces`:

```julia
_bind_policy(sim, t_end, stop_on, site::Symbol) → StopPolicy
```

It validates `t_end` through `_t_bound(t_end, site)` (the `_t_bound_diag`
half and its `:Simulation` arm retire with the constructor keyword) and the
faces through `_stop_faces(layout, stop_on; site)`, the fail-fast pair as
today at `run!` (`sim.jl:913–915`). `site` is `:run!`, `:replay!` or
`:step!`; `StopFaceInvalid`'s `site` comment (`diagnostics.jl:1186`, 1191)
and `ArgumentInvalid`'s `call` comment lose `:constructor` and
`:Simulation` for `t_end` (`:Simulation` stays for the materialization's
own keywords, D-256). Spec: §13.5 7977–8000, Appendix B 10902–10947.

**The keywords leave the constructor.** `Simulation(d, T; …)` (`sim.jl:115`)
loses `t_end` and `stop_on`; the docstring's two paragraphs on them
(87–96) go, and the "validated here exactly as at `run!`" sentence with
them. The fields `t_end`, `stop_on`, `stop_addrs` leave the struct; `policy`
becomes `policy::StopPolicy`, initialized to `StopPolicy(Inf, Symbol[],
Any[])`. `Simulation` becomes `mutable struct` in this stage, since an
immutable policy is rebound rather than written into; stage 2 shrinks it.

```julia
run!(sim; t_end = Inf, stop_on = ())
replay!(sim, trc; to_boundary = nothing, to_time = nothing, t_end = Inf, stop_on = ())
step!(sim; frames = nothing, t_plus = nothing, t_end = Inf, stop_on = ())
```

Each binds `sim.policy = _bind_policy(sim, t_end, stop_on, :run!)` (its own
site) ahead of the lifecycle-independent work it already does, and passes
the value down: `_run_body!(sim, pol, …)` and `_advance!(sim, pol, …)` take
a `StopPolicy`, `_stop_hit(sim, pol)` reads `pol.faces`/`pol.addrs`. The
`nothing`-means-default branches at `sim.jl:788–790`, 913–915 and 1224–1226
go. `replay!`'s docstring sentence "the constructor's standing where they
are not given" (721–723) and `run!`'s "the constructor's values standing"
(872–876) say the defaults are the call's. `step!`'s docstring paragraph
"Termination policy is honored throughout, from the `Simulation`'s own
defaults" (1195–1201) says the call's `t_end` and `stop_on`, `Inf` and no
faces by default.

**`hit` onto the cursor.** `ExecutionCursor` gains `hit::Union{Nothing,Symbol}`
(`executor.jl:15–22`, the constructor's default `nothing`). `_advance!`
sets `cur.hit = nothing` where it stamps the frame entry (`sim.jl:1072`),
`frame!` reads `sim.exec.cursor.hit` (`localization.jl:35`),
`_localized_frame!` writes it (151–153), `_advance!` reads it after
`frame!` (1075–1080). Nothing else touches it.

**The record carries its policy** (§13.5 8027–8032, glossary 12401–12404).
`TerminationRecord{T}` (`devices.jl:73–77`) gains `policy::StopPolicy` as
its second field; `_record(sim, src, residue)` (`sim.jl:297–298`) reads
`sim.policy`. Its docstring says the record holds the terminating advance's
policy, so `EndTimeReached`'s bound is read off the record rather than the
constructor.

**The trace header stops recording a policy.** `TraceHeader.deployment`'s
named tuple (`trace.jl:43–46`) loses `t_end` and `stop_on`, `_capture_header`
(277–291) stops reading them, and the comment on the effective pair above
the block goes; stage 2 replaces the block with the `Deployment` itself.

### `UnboundedRun`

In `dataplane.jl` beside the loop's other kinds (84–100):

```julia
"§13.5's unbounded run: `run!` with `t_end = Inf` and no stop faces, the interactive shape whose escape is the operator interrupt (§12.4)."
struct UnboundedRun <: Diagnostic
    t_end::Float64            # Inf
    stop_on::Vector{Symbol}   # empty
end
```

It joins `DiagValue` (134–136), `KindCounts` as `unbounded` (196–207,
`_kind` at 209–217, the zero constructor), the `severity` list (144–152),
and gets a `message` beside the others' (grep `message(d::FiringBudget)`):
the effective `t_end` and the `stop_on` set, the remedy naming both
keywords of `run!`, and the operator interrupt as the sanctioned escape
(Appendix C 11406–11411). The comment at 33–37 drops it from the absent
three, leaving `DebtReanchor` and `ThreadBudget`.

Raised in `run!`, after the policy binds and before `_run_body!`, exactly
when `sim.trace.mode === :live && isinf(pol.t_end) && isempty(pol.faces)`
(the register's `mode`, `trace.jl:142`; stage 2 moves it to the run):
`_report!(sim.loop_diag, UnboundedRun(pol.t_end, copy(pol.faces)))`. Once
per `run!`; the cell's ring is the rate limit. The first frame-top drain
folds it into the loop's account and the next publication carries it
(§11.8): `latest(sim).status.writers[end]` is the loop's record
(`sim.jl:1557–1567`, `WriterStatus` at `dataplane.jl:351–358`).

### The sweep

Read the sites off `grep -n 'Simulation(.*\(t_end\|stop_on\)' test/*.jl`
at the tip, not off this list; the 63 are those. Rule: delete the pair from
the constructor and pass it to **every** `run!`, `replay!` and `step!` on
that simulation whose testset relied on it — a `run!(sim)` left bare on a
model with no stop of its own is an unbounded run that never returns. Read
each testset before moving: `test_lifecycle.jl:126–134` asserts `Inf` as a
value (`unbound.t_end === Inf` at 127 retires; the `lifted` case becomes a
`run!(lifted; t_end = Inf, stop_on = ("hit",))` after a `run!(lifted;
t_end = 0.2, stop_on = ("hit",))` on a fresh `init!`); `test_lifecycle.jl:231`
becomes `step!(sim; frames = 100, t_end = 1.0) == 20`; `test_failures.jl`'s
35 sites mostly end by the model's own throw before `t_end`, and every one
still moves. Sites whose kind changes:

- `test_lifecycle.jl:136–147`: the constructor's `dc` retires; assert
  `run!`, `replay!` and `step!` with `t_end = -1.0`, `argument`, `reason`
  and `value` equal across the three and `call` the site.
- `test_lifecycle.jl:150–168`: the three sites are `:run!`, `:replay!`,
  `:step!`, and the `:constructor` arm goes; `dc.site === :constructor`
  becomes the `step!` site's assertion.
- `test_lifecycle.jl:171–176`: `Simulation(m; stop_on = ("nope",))` is now
  an unknown keyword, not a refusal; the `[ArgumentInvalid,
  StopFaceInvalid]` materialization throw retires (the stop faces are an
  advance's own), and `run!(sim; t_end = -1.0, stop_on = ("nope",))` throws
  the fail-fast `ArgumentInvalid` first, as `_t_bound` runs before the
  faces; assert that order.
- `test_trace.jl:91–95`: `d.t_end` and `d.stop_on` go (the header block
  has no policy); 234–237: drop the keywords and the comment.
- `test_trace.jl` sites at 436, 690, 823: move to the advances.

New assertions, in `test_lifecycle.jl`:

- The record carries the policy: after `run!(sim; t_end = 1.0, stop_on =
  ("hit",))`, `termination(sim).policy.t_end == 1.0 && .faces == [:hit]`;
  after a `step!` that stops on `t_end`, the record's policy is the
  `step!`'s.
- `UnboundedRun`: the `stop!`-from-model idiom of
  `test_failures.jl:296–305` (`HookedInterrupter`, hook `() -> stop!(sim)`)
  on a plain `run!(sim)`: the run ends `ControlRequestedStop(:code)`, the
  final status's loop record has `totals.unbounded == 1`, and the same
  model under `run!(sim; t_end = 5.0)` has `0`. A `step!(sim)` with the
  defaults raises nothing.
- `test_diagnostics.jl`: `UnboundedRun` joins the rendering occurrences
  (567–571) and `warning_kinds` (576–581).

### Bookkeeping

- `test/imports.jl`: `StopPolicy`, `UnboundedRun`.
- `implementation.md`: `sim.jl`'s row says the policy is built per advance
  and bound on the run, `devices.jl`'s row says the record carries it,
  `dataplane.jl`'s row gains `UnboundedRun`, `executor.jl`'s row says the
  cursor carries the stop hit.
- `pending.md`: the "§12 beyond its built slices" bullet drops "`run!`
  requires a finite `t_end`"; the §11.8-remainder bullet drops
  `UnboundedRun`; the umbrella's run sentence is stage 2's.

## Stage 2 — `Run{T}` and the trace split

Files: `src/sim.jl`, `src/trace.jl`, `src/roster.jl`, `src/devices.jl`,
`src/dataplane.jl`, `src/diagnostics.jl`, `src/localization.jl`,
`test/imports.jl`, `test/test_trace.jl`, `test/test_log.jl`,
`test/test_lifecycle.jl`, `test/test_devices.jl`, `test/test_failures.jl`,
`test/test_diagnostics.jl`, `docs/design/implementation.md`,
`docs/design/pending.md`.

### The types

In `trace.jl`, the header loses its schema list and holds the deployment
and `t₀` (§11.5 5818–5832):

```julia
struct TraceHeader{T}
    x::Vector{T}
    s::Vector{Any}
    m::Vector{Any}
    root_inputs::Vector{Pair{Symbol,Any}}
    deployment::Deployment          # compared as a value at replay (§12.7)
    t₀::T                           # applied, never compared
    layout::@NamedTuple{…}          # unchanged
end
```

`trace.jl` precedes `deployment.jl` in the include order (`Cadence.jl:18`,
22); move `include("trace.jl")` to after `deployment.jl` and before
`sim.jl`, or type the field `Any`. Move the include: `roster.jl`'s
`DataPlane` takes the register untyped already (`roster.jl:186`), and
nothing in `bindings.jl`, `devices.jl`, `stepper.jl` or `deployment.jl`
names a trace type (check with `grep -n 'Trace\|TraceRegister' src/*.jl`
first and report what you find).

```julia
"""
The trace (§11.5, D-255): a fixed header, written once at `init!` and never
again, plus two append-only lists — the writers' schemas, grown at every
roster change, and the sparse records, one per drained batch — and its
length, the drains since the capture. `Run.trace` is the live one; `trace(sim)`
hands back a detached value of the same type.
"""
mutable struct Trace{T}
    const header::Union{Nothing,TraceHeader{T}}   # nothing: the placeholder run, or the kill switch
    const schemas::Vector{Pair{String,Vector{Symbol}}}
    const batches::Vector{TraceBatch}
    frames::Int
end
```

The register keeps the drain's bookkeeping and points at the run's trace:

```julia
mutable struct TraceRegister
    enabled::Bool
    trace::Union{Nothing,Trace}       # the current run's; nothing before the first init!
    frame::Int
    live_writers::UnitRange{Int}
    feed::Union{Nothing,ReplayFeed}
end
```

`mode` leaves it for the run; `header`, `batches`, `frames` leave it for the
trace. `_reset!(reg)` (157) goes: `init!` and `replay!` build a fresh `Trace` and
point the register at it; `feed` is cleared there. `_record!` (184) pushes
onto `reg.trace.batches`; `_install_writers!` (234) pushes the current
writer set onto `reg.trace.schemas` in place and `_reschema` (208) retires
(§11.5 5833–5840). `_detach(h)` (216) keeps copying the header's four
arrays — a `Trace` a caller
holds must stay unreachable from the run's — and `replay!` builds the new
run's trace as `Trace{T}(_detach(h), copy(trc.schemas), TraceBatch[], 0)`
before `_install_writers!` appends this session's writers. `DataPlane` gains
`recorder::TraceRegister` (`roster.jl:170–180`, constructor at 186–190), and
`reclaim!(plane, layout, reg)` (233) reads `plane.recorder` instead of
taking it.

In `sim.jl`, ahead of `Simulation`:

```julia
"""
The state one run owns (§12.6, D-255): the origin, the input mode, the log
and the trace, fixed by the constructing entry point; the stop policy the
current advance bound, and the termination record the loop's tail writes
once. `init!` and `replay!` construct one; a change of mode is a change of
run (`live!`, and the flip at a recording's end, D-218). `Simulation` is built
with a placeholder, `t₀ = zero(T)`, `:live`, an empty log and trace, no
termination, so every accessor has a run to read; `lifecycle(sim)` says
whether it started.
"""
mutable struct Run{T}
    const t₀::T
    const mode::Symbol                 # :live | :replay (§12.6, D-218)
    const log::SnapshotLog
    const trace::Trace{T}
    policy::StopPolicy
    termination::Union{Nothing,TerminationRecord{T}}
end

closed(run::Run) = run.termination !== nothing
```

`Simulation{T,E,M}` becomes a `mutable struct` with `deployment`, `exec`,
`run::Run{T}`, `plane`, `control`, plus, until stage 3 moves them,
`join_timeout`, `has_localized`, `chunk_size`, `stepper`, `xnext`, `ẋnext`,
`published`, `loop_diag`, `loop_acct`. `policy`, `log` and `trace` leave it
for the run. `Control` (`devices.jl:109–117`) loses `termination`; its
docstring (80–108) drops the record sentence and says the outcome is the
run's (§12.1 6513–6519).

### The doors

**The placeholder.** The materialization builds
`Run{T}(zero(T), :live, SnapshotLog(log, every, max), Trace{T}(nothing, [], [], 0),
StopPolicy(Inf, Symbol[], Any[]), nothing)` and a register
`TraceRegister(trace, nothing, 0, 1:1, nothing)` into the plane. The
recording flags are carried to `init!` on the placeholder itself: `init!`
reads `enabled`, `every`, `max` off `sim.run.log` and `enabled` off
`plane.recorder` (Appendix B 10778–10786).

**`init!`** (`sim.jl:637–656`): after `apply!`, build
`run = Run{T}(t0, :live, SnapshotLog(L.enabled, L.every, L.max),
Trace{T}(header, [], [], 0), StopPolicy(Inf, Symbol[], Any[]), nothing)`
with `header = reg.enabled ? _capture_header(sim) : nothing`, assign
`sim.run = run`, point `reg.trace` at `run.trace` (or `nothing` under the
switch), clear `reg.feed`, then `_install_writers!`. `_open_trajectory!`
(561–577) loses `_reset!(sim.log)`, `ctl.termination = nothing` and the
mode reset, all of which the fresh run is. `_capture_header` reads the
deployment and `t₀` off `sim` (`sim.deployment`, `sim.exec.clock.t₀`) and
the docstring's "allocates fresh objects rather than clearing" is §12.6
7152–7160.

**`replay!`** (753–826): the same, with `header = _detach(h)`, `t₀ =
h.t₀`, `mode = :replay`, the inherited schemas, and `reg.feed = feed`. The
mode is set at construction, not after the sequence, since the run is the
mode (`reg.mode = :replay` at 822 goes). `_open_trajectory!(sim, h.t₀)`.

**The flip and `live!`.** `_settle_mode!` (938–948) and `live!` (856–864)
replace the run with one whose `mode` is `:live` and whose other five
fields are the current run's objects (`Run{T}(r.t₀, :live, r.log, r.trace,
r.policy, r.termination)`), clearing `reg.feed`. §12.6 7079–7081: "a change
of mode is a change of run". `mode(sim) = sim.run.mode` (276);
`_replay_bound` and `drain!` read the mode off the run and the feed off
`plane.recorder`.

**The tail.** `ctl.termination = _record(…)` at 1013, 1020, 1241, 1249
becomes `sim.run.termination = …`. `termination(sim)` (287–290) returns
`sim.run.termination`; the lifecycle gate it carries today is redundant
with the run being fresh at every door, so drop it and say so in the
docstring. `closed(run)` is exported beside it (Appendix B 10984–10985).

**The drain.** `drain!` (1425–1443) and `_replay_drain!` (1465–1495) read
`reg = sim.plane.recorder`, stamp `reg.frame`, and count `reg.trace.frames
+= 1` under `reg.enabled`. `trace(sim)` (1619–1625) refuses `:disabled` off
the register and `MissingInit` on a `nothing` header, and returns
`Trace{T}(t.header, copy(t.schemas), copy(t.batches), t.frames)`.
`publish!` (1525–1532) logs into `sim.run.log`; `logged` (1592) reads it.

### The header check

`_check_header!` (`trace.jl:325`): the fingerprint half stands; the
seven-parameter loop becomes `h.deployment == sim.deployment || _walk_deployment!(diags, h.deployment, sim.deployment)`.
The walk keeps `ReplayHeaderMismatch`'s discriminator (§12.7 7405–7410,
Appendix C as amended): the seven parameters by name as today, then the
schedule — a differing row count or path list as `what = :deployment, name
= :schedule, expected/found` the path lists; a row differing in a column as
`what = :deployment, path = row.path, name = column` (`:anchor`, `:D`, `:Φ`,
`:Δt`, `:provenance`), with the two values; scope rows likewise under `name
= Symbol("scope.", column)`. `Deployment`'s `==` is `deployment.jl:371–375`,
`ScheduleRow`'s 112–116. The message's deployment arm (`diagnostics.jl:1908–1912`)
gains the row wording; the "seven trajectory-determining parameters" phrase
stays for the parameter case. The comment at 320–324 says the check is one
`==` with the walk as its explanation.

The scalar fallback (`sim.jl:686–687`) stands, and `to_time`'s reads of
the header (`trc.header.deployment.t₀`, `.h` at 779–783) become
`trc.header.t₀` and `trc.header.deployment.h`.

### Re-pointing the readers

- `test_trace.jl`: `header.schemas` (35, 49, 138–141, 158, 424, 619–620) →
  `trc.schemas`; 91–95 → `h.deployment == sim.deployment && h.t₀ === 0.0`;
  106 and 842 (`off.trace.*`) → `off.run.trace.header === nothing`,
  `isempty(off.run.trace.batches)`, `.frames == 0`; 142, 158, 620
  (`sim.trace.live_writers`) → `sim.plane.recorder.live_writers`; 245–256:
  `bent` becomes a `Trace{Float64}(trc.header, [("harness" => [:a, :zzz,
  :c])], copy(trc.batches), trc.frames)` and `_reschema` leaves
  `test/imports.jl`; 420–424: `rec.schemas !== trc.schemas`; 505:
  `trc.header.t₀`.
- `test_log.jl` 59, 68, 78, 79, 87: `sim.run.log.*`.
- `test_lifecycle.jl:39, 57, 312`, `test_trace.jl:400, 557`,
  `test_failures.jl:189`: `termination(sim) === nothing` stands; add
  `!closed(sim.run)` at 39 and `closed(sim.run)` after a stop.
- A schedule-row mismatch test in `test_trace.jl`'s header testset
  (203–238): the target bound at a different rate for one component (a
  fixture pair with one `sample_times` difference; grep the names you add
  across `test/` first), refused with `what === :deployment`, `path` the
  row's, `name === :D`; and a same-tick-table-different-anchor case if a
  fixture pair exists that produces one, else say so in the report.
- The placeholder: `Simulation(...)` before `init!` has `sim.run.t₀ ==
  0.0`, `mode(sim) === :live`, `!closed(sim.run)`, `trace(sim)` refusing
  `MissingInit`; `init!` replaces the object (`sim.run !== r0`); a `live!`
  and the recording's-end flip replace it again with the same `log` and
  `trace` objects (`===`).

### Bookkeeping

- `test/imports.jl`: `Run`, `closed`, `TraceHeader`; `_reschema` leaves.
- `implementation.md`: `sim.jl`'s row says the five fields (with stage 3's
  moves pending), the run and its doors; `trace.jl`'s row says the header
  holds the deployment, `Trace{T}`'s lists grow in place, the register is
  the plane's; `devices.jl`'s row loses the record from `Control`;
  `roster.jl`'s row gains the recorder; `diagnostics.jl`'s row notes the
  schedule arm.
- `pending.md`: the umbrella's run sentence reads "delivered by increment
  47" for `Run{T}`, the trace split, `StopPolicy` and `UnboundedRun`, the
  five fields pending stage 3.

## Stage 3 — the periphery

Files: `src/sim.jl`, `src/build.jl`, `src/executor.jl`, `src/roster.jl`,
`src/dataplane.jl`, `src/devices.jl`, `src/localization.jl`, `src/trim.jl`,
`src/trace.jl`, `test/imports.jl`, `test/test_roster.jl`,
`test/test_stepper.jl`, `test/test_localization.jl`, `test/test_trim.jl`,
`test/test_executor.jl`, `test/test_devices.jl`, `test/test_diagnostics.jl`,
`docs/design/implementation.md`, `docs/design/pending.md`.

### `EmptyGreedyClaim` into the entry's cell

`attach!` (`sim.jl:1344–1345`) reports the kind into the entry's own
`diag` through `_report!` and keeps the `@warn logline(...)` beside it
(§11.8 6355–6359, §13.1 7660–7663, Appendix C 11270–11273, D-250). The
kind (`diagnostics.jl:1395–1402`) joins `DiagValue`, `KindCounts` as
`empty_greedy`, and `_kind`; its `severity` is already `:warning`. The
cell is folded at the first frame-top drain, so the status carries it at
the next publication and the terminal one's totals keep it (§11.8).

`test_roster.jl:130–134`: after the `@test_logs` attach, `init!`, `step!`,
and the status's record for `"device 3 (Pad)"` has `totals.empty_greedy ==
1` (`latest(sim).status.writers[3]`, attachment order); the `@test_logs`
stays, the line being kept.

### The regroup

- **To the executor** (`build.jl:1281–1294`, `compile` at 1317):
  `chunk_size::Int`, `stepper::M`, `xnext::Vector{T}`, `ẋnext::Vector{T}`,
  `has_localized::Bool`, with `M` a new type parameter. `compile` takes
  `algorithm` as a keyword beside `chunk_size` and builds `algorithm(T,
  length(xbuf))`; `stepper.jl` is included after `build.jl`, which is fine
  for a call and would not be for a field type, so the field is `M`. The
  materialization passes `d.algorithm`; `_scratch` (`trim.jl:502–506`)
  passes `sim.deployment.algorithm` and `sim.exec.chunk_size`;
  `test_trim.jl:483` and `test_executor.jl:46` follow. Readers: `sim.stepper`
  at `sim.jl:514`, `localization.jl:44, 140`, `test_stepper.jl:9, 11`;
  `sim.xnext`/`ẋnext` at `localization.jl` (six, `grep -n xnext`);
  `sim.has_localized` at `localization.jl:34`, `test_localization.jl:208`.
  `Simulation{T,E,M}` becomes `Simulation{T,E}`; `trim.jl:495`'s
  `string(typeof(other))` names the framework type with its parameters on
  purpose (the authoring caveat), and nothing asserts their count.
- **`join_timeout` into `Control`** (`devices.jl:109–117`): a
  `join_timeout::Float64` field, `Control(join_timeout)`; readers at
  `devices.jl:482, 490`. The keyword stays the materialization's and
  validates as today (`test_devices.jl:407–420` stands).
- **Into the plane** (`roster.jl:170–190`): `loop_diag::DiagCell`,
  `loop_acct::WriterAccount`, `published::Published`. Readers:
  `sim.loop_diag` at `sim.jl:477`, `localization.jl:77`, `devices.jl:490,
  518`; `sim.loop_acct` at `sim.jl:1037, 1441, 1474, 1565`,
  `devices.jl:518–519`; `sim.published` at `sim.jl:1337, 1531, 1577`.
  `latest(sim)` reads `sim.plane.published.latest`. `Published`'s docstring
  (`dataplane.jl:580–585`) says the holder keeps the *plane* immutable-safe,
  not the `Simulation`, which is mutable now.
- `Simulation` ends as `deployment`, `exec`, `run`, `plane`, `control`
  (§12.6 7054–7066, D-256). Its docstring's field comments move with the
  fields; the struct's own comments name the owner each field went to.

### Bookkeeping

- `implementation.md`: `sim.jl`'s row says five fields; `build.jl`'s row
  says the executor owns its stepper, arrival buffers and `chunk_size`;
  `devices.jl`'s row says `Control` carries `join_timeout`; `roster.jl`'s
  row says the plane holds the loop's cell and account and the published
  holder; `dataplane.jl`'s row gains the greedy-claim kind in the cell.
- `pending.md`: the umbrella's `EmptyGreedyClaim` clause (31–32) says
  increment 47 delivered it; the run sentence reads "delivered by
  increment 47" in full.

## Report format

For each stage: the commit hash and subject; the routed run's command and
its summary line; every deviation from this brief with its reason; every
place a site did not hold what the brief claims; open questions for the
user. Increment 48 reads the stage-2 report for `Run`'s and `Trace`'s
final shapes and the stage-3 report for the executor's, so name them
explicitly.
