# Brief: increment 55, checkpoints (D-273, D-274)

Tip at launch: `c39a37d`, the docs commit that ruled D-273 and D-274. Three
stages, docs first, then one cold review and one fixer. Retires
`pending.md`'s "Checkpoints" bullet under "Not yet built". The deferred
update placement (branch `deadend-update-placement`) is a rejected
alternative recorded in D-273 and is not resumed in any form.

Design and code are peers, neither subservient. The rulings landed
docs-first in the log; stage 1 conforms the spec, stages 2 and 3 conform
the code and the suite. If the ruled shape proves wrong at the keyboard,
stop and report rather than deviate silently.

## The ruling, in one paragraph

A condition is an initial condition and nothing else; `capture` leaves the
algebra. A `Checkpoint{T}` is the executor's state at a frame top: the flat
buffer, the `s` and `m` stores, the whole signal table, the guard priors,
the clock in full, and the fingerprint. `checkpoint(sim)` takes one at any
frame-top rest and refuses mid-frame; `init!` takes one at the end of
boundary zero, after the first publication, and it is the run's trace
header. `restore!(sim, cp)` checks the fingerprint, copies the state back,
opens a fresh run, publishes one snapshot and runs no boundary zero.
`replay!` is a restore of the trace's header plus the feed from frame 1.
The due updates stay at the end of their boundary. `linearize`'s default
operating point is the checkpoint. The mid-run trim baseline and the tweak
of a captured state retire. A throw inside boundary zero leaves no run and
is reproduced by `init!` under the same condition.

## What the spec says

Read these by line range at `c39a37d`; the spec is unchanged since
`73475cd`, the log gained D-273 and D-274 at its end. Every line stage 1
rewrites is listed under "Stage 1"; this is the reading.

- `decisions.md`: D-273 and D-274 in full (search `### D-273`); the
  Position fields of D-038 (primary trace header), D-063, D-067, D-101
  (replay's two substitutions), D-205, D-213 (the frozen tier's
  establishment), D-218 (input modes), D-223 (a throw inside boundary
  zero), D-230 (the boundary ordinal), D-255, D-260, D-272.
- §11.5, `spec.md` 6258–6390: the trace, the record format, the header
  paragraphs (6333–6362) and the on-by-default paragraph (6364–6376).
- §12.6, 7834–7845: the re-run cycle and the warm restart.
- §12.7, 7892–7935 (the two substitutions) and 8050–8125 (the entry pass,
  the header check, the disposition table).
- §13.7, 9088–9100: the stopped-sim services table, the `capture` and
  `linearize` rows.
- §14.1, 9094–9104; §14.5, 9515–9519; §14.8, 9778 and 9944–9950; §14.9,
  10076–10082; §14.10, 10255–10268.
- Appendix B: the `init!` row (10781–10796), the `trim!` row
  (10804–10813), the `capture` row (10822–10823), the `linearize` row
  (10824–10827), the `replay!` row (10908–10920). Appendix C: the
  `ReplayHeaderMismatch` row (11270–11279). Appendix D: `replay` (12176),
  `trace header` (12192), `capture` (12227).
- `implementation.md`: the entries for `trace.jl` (453–480),
  `conditions.jl` (587–601), `sim.jl` (275–374), `linearize.jl` (613–628),
  `trim.jl` (602–612), `localization.jl` (412–427), `stepper.jl`
  (375–380), `diagnostics.jl` (43–95), the fixtures and repl entries
  (652–696); the authoring caveats (697–758) in full; "Naming" (759) and
  "Running the suite" (836), cited below and never restated.
- `tools/spec_style.md`, `tools/decisions_style.md`, and the header of
  `tools/check_glossary.jl` before touching the spec, the log or the
  glossary.

## What exists

- `trace.jl`: `TraceHeader{T}` (40–49: `x`, `s`, `m`, `root_inputs`,
  `deployment`, `t₀`, `layout`); `Trace{T}` (88–93) with `const header`;
  `_detach` (161–163); `_fingerprint` (215–223: sizes, root faces, paths,
  store types); `_capture_header` (228–238), called from `init!` before
  boundary zero; `_check_header!` (258–289) pushing `ReplayHeaderMismatch`;
  `_deployment_diff!`, `_walk_deployment!`, `_check_schemas!` (291–352) and
  the record compilation (358–454), untouched.
- `conditions.jl`: `capture` and its docstring (803–862), `_capture_x`
  (871–878), no other caller.
- `sim.jl`: `_open_trajectory!` (654–666: clock to `t₀`, frame and
  boundary to 0, priors cleared, accounts reset, staged batches dropped,
  stop word cleared); `_open_run!` (692–698: builds the `Trace` with the
  header passed in); `init!` (785–807: gate, recording keywords, resolve
  and totality, defaults, `apply!`, open trajectory, open run with the
  header captured at 803, `_host_boundary_zero!` at 805, `publish!` at 806);
  `replay!` (914–984: `to_time` through `trc.header`, `_compile_feed`
  validating the header at 952, the header written into the executor at
  955–966, open trajectory at `header.t₀`, open run with the detached
  header, boundary zero, publish, run body); `publish!` (1990–1999) with
  `capture_stores`, the table copy the snapshot takes, and the boundary
  ordinal increment; the frame counter at 1371; `_assert_advanceable`
  (403–412). `_replay_drain!` (1927–1958) applies records keyed
  `clock.step + 1`, so a feed started from a restored frame `k` applies
  the batches from `k+1` with no offset.
- `store.jl` 124–129: `Clock{T}` with `t`, `step`, `boundary`, `t₀`.
- `executor.jl` 262–274: `EventSet`'s registers, `prior` and `last` the
  two that cross a boundary and are equal at rest (`sim.jl` 596 copies one
  into the other). `_guard_walk` (303–312) rewrites `σ` on every call, and
  `localization.jl` 64–71 calls it first in the arrival sweep, so no
  localization sample survives a frame: none is checkpointed.
- `stepper.jl`: RK4 and Heun retain a `startpoint` pair within a step for
  dense output; nothing crosses a frame top.
- `linearize.jl`: the docstring (76–105); the `t0`-without-`about` guard
  and the lifecycle gate (111–120); the operating point at 121, `capture`
  or `about`; the nominal half (123–131: resolve, `apply!`, one
  `ESTABLISH` round); the seeded half with `_establish_frozen!` (133–139);
  `_set_clock!` (187–190) writing `t` and `t₀` only.
- `trim.jl`: `baseline` is a required condition keyword (426–434); nothing
  reads a header or calls `capture`.
- `diagnostics.jl`: `ReplayHeaderMismatch` and its renderer (2032–2100),
  whose `:root_input` arm says the header's values are applied at boundary
  zero; `t0_without_about`'s message (1921–1923) naming `capture(sim)`;
  `StepError`'s renderer, pointer-0 branch (about 1900–1912); the
  `ServiceLifecycle` comment on `capture`'s legal list (1156–1160).
- `Cadence.jl` includes `trace.jl` before `sim.jl`; `test/imports.jl`
  imports `TraceHeader` (33), `_compile_feed` (44), `capture` and
  `capture_stores` (47–48). `show.jl` has no site.

## Scope

In:

- `Checkpoint{T}`, `checkpoint(sim)`, `restore!(sim, cp)`, the shared copy
  and the shared fingerprint check.
- The trace header unified with the checkpoint; `init!` taking it after
  the first publication; `replay!` as restore plus feed, with the
  what-if form that feeds without restoring.
- `CheckpointMismatch`, the one kind for the entry pass and `restore!`,
  replacing `ReplayHeaderMismatch`; `CheckpointMidFrame`, the refusal
  after a `t*` stop.
- `capture` retired; `linearize`'s default operating point from the
  checkpoint; the mid-run trim test retired.
- The `StepError` pointer-0 recipe naming `init!`.
- The spec, the glossary, `implementation.md`, the suite.

Out:

- On-disk serialization of a checkpoint or a trace (§11.5's persistence
  question stays pending).
- A partial first frame after a `t*` checkpoint; an override surface on a
  checkpoint; a mid-run trim.
- The stepper hook's content for multistep methods: the hook exists,
  RK4 and Heun implement it empty.
- The update placement, the priors' and origin's condition entries: all
  rejected in D-273, none built.
- The untracked GUI, inspector and audit folders.

## Shapes

### The value

```julia
# checkpoint.jl, included before trace.jl
struct Checkpoint{T}
    x::Vector{T}                     # the flat buffer
    s::Vector{Any}                   # per component: the store value, or nothing
    m::Vector{Any}                   # likewise for the mode stores
    table::StoreBundle               # the signal table, every cell buffer copied
    prior::Vector{Bool}              # the guard priors; `last` equals it at rest
    t::T                             # the clock, in full
    step::Int
    boundary::Int
    t₀::Float64
    deployment::Deployment           # the fingerprint: compared at restore
    layout::Fingerprint              # today's `layout` NamedTuple, named
end
```

`_take_checkpoint(sim) → Checkpoint{T}` is `_capture_header`'s successor:
the same reads plus `capture_stores(exec.store)`, `copy(events.prior)` and
the four clock fields. `_restore_state!(exec, cp)` is its inverse:
`copyto!` into `xbuf`, the store references rebound, every cell buffer
copied back, `prior` and `last` both set from `cp.prior`, the clock
written. The stepper seam gains `checkpoint!(stepper)`/`restore!(stepper,
cp)`-style hooks only if a backend holds cross-frame state; RK4 and Heun
hold none, so the seam gets one documented no-op pair and nothing else.
`_check_checkpoint!(diags, sim, cp)` is `_check_header!` over the two
shared fields, pushing `CheckpointMismatch`.

### The services and the door

```julia
checkpoint(sim)                       # :initialized or :stopped; refused mid-frame
restore!(sim, cp; trace = true, log = true, log_every = 1, log_max = 65536)
```

`checkpoint` refuses `:running`, `:built` and `:errored` through
`ServiceLifecycle` with `op = :checkpoint` and the legal list
`[:initialized, :stopped]`, and refuses a stopped simulation whose clock is
not at a frame top, `t ≠ t₀ + step·h` within `_frame_slack`, through
`CheckpointMidFrame(t, t_frame, step)`. That is the state a `t*` stop
leaves (localization.jl's stop hit abandons the remainder).

`restore!` is a door in `sim.jl` beside `init!` and `replay!`: the
lifecycle gate `init!` uses, `_check_recording`, `_check_checkpoint!`
against the simulation (one `DiagnosticError` collecting the mismatches),
then `_restore_state!`, the parts of `_open_trajectory!` that are not the
clock and not the priors (accounts, staged batches, the stop word),
`_open_run!` with the checkpoint as the header, and one `publish!`. No
boundary zero, no sweep. The snapshot it publishes is the checkpoint's
table at the checkpoint's `t`, and the boundary ordinal continues from
`cp.boundary`. A restore into a `Simulation{S}` with `S ≠ T` is a
`MethodError` by dispatch, as `gather_reads` is.

### `init!` and the trace

`init!`'s order becomes: gate, keywords, resolve and totality, defaults,
`apply!`, `_open_trajectory!`, `_open_run!` with no header, boundary zero,
`publish!`, then `trace.header = _take_checkpoint(sim)`. `Trace{T}.header`
becomes a field written once, `Union{Nothing,Checkpoint{T}}`, `nothing`
only between the run's opening and the first publication, which a
boundary-zero throw makes permanent for a run that is then discarded
(D-223: the simulation returns to `built`). `trace(sim)` refuses a run
whose header is `nothing` with the lifecycle refusal it already raises for
`built`. `_detach` copies the checkpoint.

### `replay!`

```julia
replay!(sim, trc; to_boundary, to_time, pace, margin, t_end, stop_on,
        trace, log, log_every, log_max, restore = true)
```

With `restore = true`, the default: `_compile_feed` validates the schemas
and records as today and the header through `_check_checkpoint!`; then the
door body of `restore!` runs with `trc.header` and attaches the feed;
`_run_body!` follows. With `restore = false`, the what-if form of D-274:
the simulation must be `:initialized`, the feed is compiled and attached
against the simulation as it stands, its checkpoint left alone, and the
drain applies batches keyed from `clock.step + 1`. `to_time` reads the
checkpoint's `t₀` and the deployment's `h` as it read the header's. The
seekable run of D-274's rationale is `restore!(sim, cp_k)` then
`replay!(sim, trc; restore = false)`, and needs no code of its own: the
feed's records are keyed by frame and the drain looks them up from the
restored counter.

### Diagnostics

- `CheckpointMismatch` replaces `ReplayHeaderMismatch`: same fields (`what`,
  `path`, `name`, `expected`, `found`), same arms, the `:root_input` arm
  dropped since the checkpoint carries cells and not a root-input list, and
  the `:store` arm's text no longer naming boundary zero. Appendix C's row
  moves with it; `test_diagnostics.jl`'s `warning_kinds`/kinds loop follows.
- `CheckpointMidFrame(t, t_frame, step)`: fail-fast, Appendix C row,
  rendered in `test_diagnostics.jl`'s rendering testset.
- `t0_without_about`'s message names the checkpoint.
- `StepError`'s pointer-0 branch renders "`init!(sim2, condition)`
  reproduces it"; the general recipe becomes "`restore!(sim2, cp)` from
  `trace(sim).header` then `replay!(sim2, trc; to_boundary = k)` and
  `step!`", or simply keeps "`replay!(sim2, trc; to_boundary = k) then
  step!(sim2)`", which still holds since replay restores the header
  itself. Keep the general recipe as it is and change pointer 0 only.

### `linearize`

The default operating point is `checkpoint(sim)`, so the default form
inherits `checkpoint`'s legality, the mid-frame refusal included. The
nominal half for the default form is `_restore_state!` into the scratch
executor, no resolve, no `apply!`, no `ESTABLISH` round: the frozen tier's
cells are the checkpoint's held cells and `_establish_frozen!` copies them
as it copies the nominal world's today. The `about` form keeps its resolve,
`apply!`, `ESTABLISH` round and `_set_clock!`. `t0` stays admitted only
beside `about` (D-272).

### Retirements

`capture`, `_capture_x`, `_capture_header`, `TraceHeader`,
`ReplayHeaderMismatch`, the `capture` import. `capture_stores` keeps its
name: it is the snapshot's and now the checkpoint's table copy, and it
never produced a condition.

### Naming

`Checkpoint`, `checkpoint`, `restore!`, `_take_checkpoint`,
`_restore_state!`, `_check_checkpoint!`, `CheckpointMismatch`,
`CheckpointMidFrame`, `Fingerprint`, the `restore` keyword. `cp` is the
checkpoint local everywhere, `header` the trace's field. No local named
`checkpoint`.

## Stage 1: the docs amendment

One commit. Rostered files use the linkified spelling; run `linkify.jl`,
`check_refs.jl`, `check_rows.jl` and `check_glossary.jl --strict`, all
green. A new glossary entry needs its `<a id="g-checkpoint">` anchor and
the gloss-on-first-use rule of `spec_style.md`. Line numbers are
`c39a37d`'s; find each passage by wording and recount after every edit.

- §11.5, 6333–6362: the header paragraph becomes "**The trace header is the
  checkpoint `init!` takes at the end of boundary zero**, after the first
  snapshot is published (§12.6, D-274)": the checkpoint's contents in one
  sentence with the glossary link, the primary-data doctrine restated
  (values, never the authored overlay, D-038), the two placement bullets
  deleted, the deployment bullet kept as part of the fingerprint. 6380–6383
  ("`t₀` post-dates even deployment … the one full-state capture") rewritten:
  the checkpoint carries the clock, and a checkpoint is the one full-state
  capture, taken by `init!` and by `checkpoint(sim)`. Line 5645's deferred
  "periodic full-state checkpoints" sentence stays, pointing at `checkpoint`
  as the value it would serialize.
- §12.6, 7834–7836: "The warm restart is `checkpoint` → `restore!` → `run!`
  (§12.7, D-274); `stopped → init! → run!` remains the authored re-run."
  Add one sentence: `restore!` is a door like `init!`, builds a fresh run
  and runs no boundary zero.
- §12.7, 7892–7935: the code block gains `restore!(sim2, cp)`; "exactly two
  substitutions" becomes one: "**Restore from the header.** `replay!`
  restores the trace's checkpoint, the state the recording opened from,
  and runs no boundary zero; the drain then reads the trace." The second
  bullet stays. The Rule paragraph adds the `restore = false` form: the
  feed against the simulation as it stands, for the what-if of a modified
  model initialized under the authored condition. 8050–8125: "header" reads
  "checkpoint" throughout; the disposition table's rows "resolved stores,
  root-input values | applied directly at boundary zero" and "`t₀` |
  applied" become "the checkpoint's state | restored; no boundary zero" and
  "the clock | restored, `replay!` takes no `t0`"; the parametric what-if
  paragraph (8097–8099) says the spelling and the price: the trace is not
  self-sufficient for it, the authored condition comes from outside.
- §13.7, 9096–9099: the `capture` row becomes `checkpoint` with "error |
  legal | legal | a frame-top rest; refused mid-frame after a `t*` stop";
  the `linearize` row inherits it. Add a `restore!` row if the table has a
  door row for `init!`; else leave doors out as the table does.
- §14.1, 9094–9104: delete from "Warm restart needs no second semantics"
  through "one mechanism with two uses"; in its place two sentences:
  a condition is an initial condition and nothing else (D-273); a
  simulation's state past its initial instant is a checkpoint (§12.6,
  D-274), not a condition, and has no algebra.
- §14.5, 9517–9518: delete the `capture` sentence; "Conditions are
  time-free." stays.
- §14.8, 9944–9950: the resumed spelling paragraph becomes: a trim at a
  point reached by flying is not offered; trim takes an authored baseline,
  and fly-then-retrim is `checkpoint` the flight and author the trim's
  baseline from what the checkpoint shows (D-273). 9778's signature is
  unchanged.
- §14.9, 10079–10081: "The services unify as clients of one condition
  algebra. `init!` applies an explicit condition and `trim!` searches a
  family for the member satisfying its equations."
- §14.10, 10255–10268: "The default operating point is the checkpoint of
  the simulation as it stands (`checkpoint(sim)`, §12.6, D-274), restored
  into the scratch world with no boundary zero; the frozen tier's cells
  are the checkpoint's held cells. `about = <condition>`, with `t0` beside
  it as in `trim!`, linearizes anywhere else without touching the sim."
  Drop the root-input-totality sentence about capture → apply.
- Appendix B: the `init!` row ends "then the header and first snapshot" →
  "then the first snapshot, and the checkpoint that is the run's trace
  header (§11.5)"; the `trim!` row loses "Resume-at-time passes `capture`'s
  returned `t` as `t0`"; the `capture` row is replaced by two rows,
  `checkpoint(sim) → Checkpoint` and `restore!(sim, cp; trace, log,
  log_every, log_max)`, in the door row's form; the `linearize` row's
  default reads "the checkpoint of the simulation"; the `replay!` row
  reads "restores the trace's checkpoint and feeds the drain by frame
  ordinal from frame 1; `restore = false` feeds the simulation as it
  stands".
- Appendix C: `ReplayHeaderMismatch` → `CheckpointMismatch`, its arms less
  `:root_input`; a new `CheckpointMidFrame` row beside it.
- Appendix D: `replay` (12176): "the ordinary loop with one substitution:
  the drain reads the trace by frame ordinal, after the trace's checkpoint
  is restored"; `trace header` (12192): "the checkpoint `init!` takes at
  the end of boundary zero, after the first snapshot"; `capture` (12227)
  deleted; new `checkpoint`: "the executor's state at a frame top, taken
  by `checkpoint(sim)` and by `init!`, restored by `restore!` with no
  boundary zero; the trace's header (§11.5, §12.6, D-274)".
- `implementation.md`: a new `src/checkpoint.jl` entry between
  `dataplane.jl` and `trace.jl`; the `trace.jl` entry loses `TraceHeader`
  and `_capture_header` and gains the header's new placement; the
  `conditions.jl` entry loses `capture`; the `sim.jl` entry names
  `restore!` among the doors and the one-substitution replay; the
  `linearize.jl` entry's default point; the `diagnostics.jl` entry's kinds.
  One new authoring caveat: "`checkpoint` is refused after a `t*` stop; a
  test that checkpoints a stopped run stops it at a frame top (`t_end`, a
  stop face read at a grid boundary, or `stop!`)."
- `pending.md`: delete the "Checkpoints" bullet.

## Stage 2: the checkpoint, the trace and replay

One commit, on stage 1's. `checkpoint.jl` with the value, the copy, the
restore and the check; `trace.jl` with `TraceHeader` gone and the header
field's new type; `sim.jl` with `checkpoint`, `restore!`, `init!`'s new
order and `replay!`'s new body and keyword; `diagnostics.jl` with
`CheckpointMismatch` and `CheckpointMidFrame` and the pointer-0 recipe;
`Cadence.jl`'s include; `test/imports.jl`. `capture` and `linearize` stay
as they are in this stage, so the suite stays green with `capture` still
reading the store; stage 3 retires it.

Tests in this stage, `test_trace.jl` unless named:

- The header is the post-sequence checkpoint (75–93 inverted): after
  `init!` on the `DiscreteIntegrator` fixture with `e = 2.0`, the header's
  `s` holds `acc = 0.2`, its table holds the published cells, its `prior`
  the boundary-zero samples, its clock `step = 0`, `boundary = 1`.
- `Trace` construction, detach, entry pass and the six mismatch testsets
  (97–343) over the checkpoint and `CheckpointMismatch`.
- Replay bitwise (436–478), `to_time` (536–605), continuation and `live!`
  (667–731) over the checkpoint.
- **The resume identity, single rate** (`test_lifecycle.jl`): the pending
  bullet's model and numbers (`DiscreteIntegrator(1.0)` driving the
  pendulum, `h = 1//10`, `N_base = 1`, `in = 0.5`, `acc0 = 4.0`, `θ0 = 0.2`,
  `ω0 = 0`); run to 0.3, `checkpoint`, `restore!` into a twin, run both to
  0.6: stores, cells and the logged trajectory from 0.3 bitwise equal;
  `ctl/u` reads `4.30` at 0.6 in both.
- **The resume identity, multi-rate** (`test_discrete.jl`): the
  `SampledLoop` at `ctl_rate = Relative(2)` with `N_base = 2` of the exact
  discretization testset, checkpointed at a frame top that is not a
  controller tick, restored into a twin, both run on: bitwise equal, and
  the controller's ticks continue on the original lattice.
- **Priors survive** (`test_events.jl`): a model with a guard holding at
  the checkpoint boundary; the twin's first boundary after the restore
  fires nothing, where `init!` from the same stores would fire it.
- **Refusals**: `checkpoint` on `:running` and `:built`
  (`ServiceLifecycle`); after a `t*` stop hit (`CheckpointMidFrame` with
  the fields); `restore!` into another deployment (`CheckpointMismatch`,
  `:deployment` arm) and into another activation (`MethodError`).
- **`restore!` is a door**: a fresh run, log and trace new objects, the
  trace's header equal to the checkpoint restored, one snapshot published
  at the checkpoint's `t` with the continued boundary ordinal, staged
  batches dropped, lifecycle `initialized`, `run!` legal.
- **Seek**: run with staged batches to 1.0, checkpoint at 0.5 (a second
  run of the same recording halted with `to_boundary`), `restore!` then
  `replay!(sim; restore = false)` on the full trace: bitwise the original
  from 0.5.
- **The what-if form**: `init!` a structurally identical model with a
  changed parameter under the same condition, `replay!(…; restore =
  false)` with the original trace; the run is deterministic (two such
  replays equal) and differs from the original.
- **Boundary-zero failure** (`test_failures.jl` 223–277): the throw leaves
  `built`, no run, `trace(sim)` refused; `init!` under the same condition
  reproduces it; the `StepError` renders the `init!` recipe (kind and
  fields asserted here, the text in `test_diagnostics.jl`).
- `test_diagnostics.jl`: the kind literals, the rendering testset's two new
  kinds, the `warning_kinds`/kinds loop.

## Stage 3: `capture` retires, `linearize` moves

One commit, on stage 2's. `conditions.jl` loses `capture` and
`_capture_x`; `linearize.jl`'s default form restores the checkpoint;
`diagnostics.jl`'s `t0_without_about` message and the `ServiceLifecycle`
comment; `test/imports.jl`.

Tests: `test_readers.jl` 210–266 retired, 268–291 rewritten for
`checkpoint`'s legality with the `t*` case; `test_linearize.jl` 68–79
rewritten, plus one assertion that the default form's frozen `ctl` cell
equals the live `port(sim, "ctl", :u)` on a discrete model at rest (D-213's
approximation is now exact); `test_trim.jl` 573–590 retired; every
`ServiceLifecycle(op = :capture, …)` literal becomes `:checkpoint`.

## Bookkeeping

- The pending bullet retires in stage 1. `check_refs.jl` and
  `check_rows.jl` read `pending.md` and `implementation.md`; run both.
- `implementation.md`'s file table gains `checkpoint.jl`'s row in the
  routing table: with `trace`'s group.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

`sim.jl` and `diagnostics.jl` beyond a new kind are touched, so the routed
subset is the table's last row, all of it, at stages 2 and 3:

    JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

In the foreground, 600 s timeout, never in the background. Compare the
assertion total against the tip's run: the retired testsets subtract, the
new ones add, and the report lists both.

## Rules for the stages

- Never stash, reset or check out the working tree. Baselines come from
  `git show c39a37d:path`.
- Fixtures at top level; grep every new fixture name across `test/`.
- Message text is asserted only in `test_diagnostics.jl`'s rendering
  testset; build and failure tests assert kind and payload.
- A scripted edit to a rostered doc matches the linkified spelling and
  checks `git diff --stat` before committing. A new log entry goes before
  the definitions marker line; none is expected in this increment.
- One commit per stage. Single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says.
- Design and code are peers. If the ruled shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 500 words per stage: the commit hash, the gate's result verbatim
(pass/fail counts, before and after; stages 2 and 3), every file touched
with one line each, any place the brief was wrong about the tree, and
anything left undone with the reason.

## Amendments at launch

Rulings and corrections made while the stages ran, 2026-09-29. Where one
disagrees with the text above, the amendment holds.

1. **The scalar refusal is one refusal for both doors** (user ruling). A
   restore into a simulation of another activation throws
   `CheckpointMismatch`, `:scalar` arm, from a fallback method, as
   `_compile_feed`'s fallback does for a trace. It is not a `MethodError`.
   D-274's "refused by dispatch" stands.
2. **The `:root_input` arm stays.** It covers the fingerprint's root-face
   list and a recorded value that does not convert to its declared type.
   Both checks survive the checkpoint.
3. **`restore!`'s snapshot is a re-publication.** `publish!` stamps the
   clock's ordinal and then increments it, so the door steps the ordinal back
   by one before it publishes. The resumed run's ordinals are the original's.
4. **Pointer 0 names both reproductions.** Boundary zero is frame one's entry
   boundary too. The renderer names `init!` for a throw inside `init!` and
   `replay!(sim2, trc)` for a throw inside frame one. `StepError` gains no
   field. The text is asserted in `test_failures.jl`'s `StepError` rendering
   testset, its existing home.
5. **A trace counts frames by the trajectory's index.** It opens with
   `frames = clock.step`, so a trace that a restore opens keeps the
   trajectory's own frame indices.
6. **The seek needs a cursor skip.** `replay!` starts the feed's cursor at the
   first record past the checkpoint's frame.
7. **The log's first endpoint is the run's first publication.** Retention
   counts boundaries from it.
8. **`restore = false` is a door too.** It builds a fresh run under the
   recording keywords, with the simulation's own checkpoint as the header,
   and publishes once. The whole entry pass runs under both forms.
9. **`linearize`'s seeded half** (user ruling). `_restore_state!` stays strict
   about the scalar. The nominal scratch takes the checkpoint through it. The
   seeded scratch takes four writes: `x` by a converting copy, the `s` and `m`
   stores by value, each root-input cell gathered from the nominal scratch
   and converted, and the frozen cells through `_establish_frozen!`.
10. **The table of stopped-sim services** sits in §14's preamble, not in
    §13.7.
