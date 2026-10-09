# The model split: rulings and roadmap

The settled register of the 2026-10-09 design session, and the three
increments that deliver it. Grounded in the tree at `dd4d092`. Each increment
follows the delegation pipeline: a brief in this directory written against the
landed tree of the previous one, one fresh agent per stage, one cold review, a
fixer, push. The briefs for increments two and three are written only after
their predecessor lands, because they name files and lines the predecessor
reshapes. This file is what those briefs draw on.

## Origin

A `Simulation` built at any scalar other than `Float64` runs without discrete
ticks and without state events. Two rules in `src/build.jl` do it:
`_frozen` (line 1060) gates a discrete component off at every non-`Float64`
scalar, and the event system compiles only under `T === Float64` (line 1551).

Both rules are correct. They transcribe §9.4 and the glossary's `nominal`: the
`Float64` activation is the only one that runs in real time, and every other
activation evaluates the model at a frozen instant, discrete stages gated off
and guards never run. A `Dual` simulation stepped through `run!` is that
frozen-instant evaluation, and the suite exercises it deliberately
(`test_discrete.jl`'s frozen-tier testset, `test_lifecycle.jl`'s `Dual` clock
assertion under D-260). The defect is elsewhere: `Simulation(deployment,
Float32)` is accepted, and a request that reads as a precision choice is
answered with a frozen-instant evaluator, silently.

Widening the two rules to `AbstractFloat` was rejected. It would create an
unspecified third mode, continuous tier at `Float32` beside a discrete tier
pinned at `Float64` (§9.4, D-263), with D-053's embedding rounding at every
wire and nothing in CI pinning any of it. A type heuristic at the `Simulation`
door was rejected too, once the deeper diagnosis below was made.

## Diagnosis

`Simulation` fuses two things. The model's structure and behaviour live in
`deployment` and `exec`. The runtime that steps it through time and talks to
devices lives in `plane`, `control` and `run`. The stopped-sim services, and
`init!`, need only the first pair:

- `apply!` on a simulation is defined as `apply!` on its executor
  (`conditions.jl:572`).
- `boundary_zero!` reads `sim.exec` and nothing else (`sim.jl:507`).
- `port`, `state` and `modes` read `exec` and `deployment.build`.
- `trim!` already builds the pair anonymously: its scratch set is
  `compile(build, activation, schedule)` with no plane, control or run around
  it (`trim.jl:568`).

A `Dual` simulation therefore allocates a data plane, a control block and a
placeholder run it can never use, and exposes a loop whose semantics at that
scalar are an accident of genericity. Nothing in `src` steps a `Dual`
simulation; the services compile their own scratch. The spec's only use for a
stepped `Dual` is forward sensitivities, filed under the sampled-data
extension with a saltation diagnostic that does not exist yet.

## Rulings

Numbered for citation from the briefs.

**R1. The split.** A new type holds the model: the `Deployment` and the
`Executor`, at one scalar `T`. The `Simulation` wraps one of them at `Float64`
beside the `DataPlane`, the `Control` and the `Run`. Every field of each type
is used by every instance of it.

**R2. The name is `Model`.** No type or variable holds the word today. The
spec uses "model" for the component tree, for its built counterpart and
loosely elsewhere; increment three moves the tree's uses to "the component
tree" or "the root" where the new meaning would collide, and the built-counterpart
uses become correct rather than loose. The two vocabularies never coexist: the
rewording lands with the type.

**R3. The scalar rule.** `Simulation` takes a `Model{Float64}` only. A
`Model{T}` at any `T` is a well-defined thing, a materialized activation that
can be written to and evaluated. Only the loop is nominal, so the constraint
lives on the one constructor that owns a loop, as a type. The two `build.jl`
rules stay exactly as they are. No `AbstractFloat` heuristic anywhere.

**R4. The `Dual` model is a service's scratch, not its argument.** `trim!` and
`linearize` take `Model{Float64}`, the holder of the operating point, and
instantiate a `Model{Dual}` internally from the same deployment, as `trim!`
does today. Activations stay cached on the `Build` by scalar type; executors
are instantiated per invocation and never cached (D-282 holds). A
`Model{Dual}` is public, because the tests need it and the sampled-data
extension will.

**R5. The clock dissolves.**

- `t` is model state. It moves into the `Executor` as a one-field mutable
  cell of the executor's own, with a concrete field type (`Ref{T}` is
  abstract and would make every read dynamic). The `Executor` stays
  immutable; the compiled bodies close over the cell as they close over the
  clock today. The cell carries the clock's docstring about `t` as a bundle
  field varying at RK internal times, and `activation_scalar` dispatches on
  it.
- `t₀`, `frame` and `boundary` are the trajectory's cursor and move onto the
  `Run`. Frame tops are `t₀ + k·h`, computed from the index and never
  accumulated (`store.jl:116`), so the grid position `(t₀, k)` is the source
  of truth and the loop writes the derived `t` into the model. All three are
  reset at every door and live as long as a trajectory does, which is the
  run's definition. D-260 kept `t₀` off the run because the clock held it;
  that reason goes with the clock.
- `t₀` does not go on the `Deployment`. The deployment is a value shared by
  many simulations and compared as one at replay and restore. The origin is
  chosen per trajectory at every door, two runs of one deployment start at
  different origins (`test_lifecycle.jl` does this), and replay already
  checks the header's `t₀` as a clock mismatch, not a deployment one.
- `Run`, `Trace` and `TerminationRecord` lose their `T` parameter. It existed
  only because the clock's `t` was in the deployment's scalar.

**R6. The checkpoint splits.** One value type holds the model's state: the
flat buffer, the `s` and `m` stores, the table, the guard priors, `t`, the
deployment and the layout fingerprint. `Checkpoint` wraps it with the run's
cursor. `checkpoint` and `restore!` on a model take and return the inner
value; a `Model{Dual}` can checkpoint and restore without ever having a
cursor.

**R7. The model owns the frame, with two hooks.** `frame!` moves to the
model: `frame!(model, k, hooks)`. A hybrid system's trajectory is defined by
where its events fire, so the `t*` boundaries are model behaviour; whether
anyone publishes them is the runtime's business.

- `hooks` is one callable struct with concrete fields (the roster, the pacer,
  the ignore mask, the plane), built once per advance, never per frame. Ad
  hoc closures are ruled out: a reassigned capture becomes a `Core.Box` and an
  abstract captured field makes the return abstract, either turning the
  branch into dynamic dispatch. The compiler specializes `frame!` on the
  struct's type as it would on a closure.
- The top hook runs first, before the model touches any state. The
  simulation's hook body is today's `drain!` (`sim.jl:2032`), unchanged: the
  writers' cells, the trace record and the replay feed stay on the
  simulation. The ordering rule that a batch taken at the top of frame `k` is
  recorded at `k` holds because the run's counter advances where the
  simulation chooses.
- The boundary hook fires at every settled boundary, `t*` boundaries
  included, and the frame top's own. The simulation's hook publishes and
  samples stop requests. §11.2's rule that every boundary publishes before
  integration resumes becomes a contract on the hook.
- Both hooks return `Bool`. `true` makes the model abandon the frame's
  remainder and return `true`. The model never learns who requested the
  stop; the simulation reads the latest snapshot again after the call, the
  same snapshot the hook sampled, a lock-free read. No union leaves the
  model's side.
- The chattering-budget report is a diagnostic, not a boundary. The model
  owns a diagnostic cell for its frame, the report goes there, and the
  simulation folds it at the drain beside the writers' cells. §11.8's
  "loop's own cell" becomes the model's.
- `init!` on the model takes the same hooks with a no-op default, so boundary
  zero publishes through the boundary hook rather than after the call.
- A `Dual` model stepping a frame for a service passes the no-op hooks; its
  root inputs stay what `init!` or `apply!` wrote. The closed-loop trim door
  and discrete-time linearization, both future, get a `Dual` model that
  advances whole frames, ticks included.

**R8. The execution cursor is the model's.** The compiled bodies close over
it at compile time, so it must exist when the model is compiled. Every phase
transition is written by `frame!`, including `:drain`, written before the top
hook runs, with the `comp = 0; fn = :none` reset that keeps a drain-side throw
from naming a stale entry. No foreign writer remains, so the two-cursor
alternative loses its argument.

**R9. Two lifecycles.** The model's status is three-valued: `:built`,
`:consistent`, `:inconsistent`. `init!` and a completed frame write
`:consistent`; a throw inside a sequence writes `:inconsistent`. Only the
model's own doors and its own catch site write it. The model's catch rethrows
raw; the simulation's catch wraps into the `StepError` as now, since the
entry boundary and the host are the run's facts and the cursor is reachable
through the model. A standalone model used by a service surfaces the raw
throw to that service's catch. `lifecycle(sim)` keeps its five observable
values and becomes derived: `:running` from the control's flag, `:built` and
`:errored` from the model's status, `:initialized` versus `:stopped` from
whether the run is closed. The stopped-sim services gate on the model's
status; the forwarding methods add the operational gate.

**R10. Doors.** The model's: `init!`, `apply!`, `frame!`, `checkpoint` and
`restore!` of the inner value, and the reads `port`, `state`, `modes`. The
simulation's: `run!`, `step!` in frames, `replay!`, `restore!` of a
`Checkpoint`, devices and recording. `init!`, `trim!` and `linearize` on a
simulation forward to the model after the operational gate and do the loop's
bookkeeping after, the run opening, the snapshot, the trace header. The inner
model is not a public handle during a run.

**R11. Constructors.** `Model(deployment, T)` and `Model(build; grid kw…)`;
`Simulation(model::Model{Float64}; join_timeout, chunk_size)`; the two
existing `Simulation` sugar forms kept, defined as compositions through a
`Float64` model.

**R12. Out of scope, recorded.**

- `ExecutionCursor` and `CursorFrame` differ in one field, `comp::Int` on the
  hot path against `path::Union{Nothing,String}` in a diagnostic that renders
  standalone. A parametric `CursorFrame{C}` with the live cursor a one-field
  mutable holder would remove the duplication, at the cost of whole-struct
  stores on the executor's measured zero-allocation path. A separate cleanup
  with the canary as its test.
- The sampled-data `Dual` activation and forward sensitivities stay the
  extension they are.

## Staging

**Increment one: the type and the frame.** `Model{T}` with its doors; the
time cell and the run's cursor (R5); the three-valued status and the derived
`lifecycle(sim)` (R9); the hooked `frame!` with the hooks struct, the top hook
carrying the drain, the boundary hook carrying publication and the stop
sample, the model's diagnostic cell (R7, R8); `Simulation` as the wrapper over
a `Model{Float64}` with the forwarding methods (R3, R10, R11). The services
keep taking a simulation through forwarding. The `Dual` fixtures in
`test_build.jl`, `test_discrete.jl`, `test_lifecycle.jl`, `test_store.jl`,
`test_conditions.jl` and `test_readers.jl` (`D8` in `utils.jl`) become `Model`
fixtures; the frozen-tier testset reads products after `init!` on the model;
the D-260 `Dual` clock assertion goes. Spec edits for what changes: §9.2's
pipeline table and `Simulation(deployment, T)` listing, §12.1 and §12.6's
field roster, §11.5 and §13.4 where `Run{T}` and the clock appear, §11.8's
loop cell. One new decision entry states the split and supersedes the clauses
of D-254, D-256, D-260 and D-282 that the split retires, because
`spec_style.md` has every bolded ruling cite the entry that rules it and
`decisions_style.md` rule 1 amends the log by a later entry; the entry lands
docs-commit-first, in this increment's docs stage. The allocation canary
guards the hooks.

**Increment two: the services onto the model.** `trim!` and `linearize` take
`Model{Float64}` and instantiate their `Dual` scratch as a `Model` (R4); the
checkpoint split (R6); `restore!` on both levels. Their two files move above
`sim.jl` in the include order once their methods take a model, under the
layout increment one set (`brief_source_layout_model.md`): `conditions.jl`,
`model.jl`, `stepper.jl` and `frame.jl` above `sim.jl`, `devices.jl` below
it, a file sitting above `sim.jl` as soon as nothing in it names a
`Simulation` in a signature. The `:non_nominal` refusals, deleted in
increment one because a refusal method on `::Simulation` would have
overwritten the service method, are raised on the model's doors, and the
`:scalar` `CheckpointMismatch` message names a `Model`. `restore!` on the
model takes the hooks, publishes through `settled!` and writes `:consistent`
last, in `init!`'s shape (D-318). A state carried from a standalone model
into a simulation goes through that door, never through the constructor.
Spec: §14.8, §14.10, D-282's owner roster.

**Increment three: the vocabulary.** The "model" sweep over the spec and the
companions (R2), and the glossary's `nominal` entry gains the sentence that
only a `Model{Float64}` can be run. The decision entries are increment one's
and two's, each with the spec text it rules.

**After increment one (2026-10-09).** It landed as 7317a7e to 22cc4db under
D-317, followed by the source reorganization and D-318, the claim:
`Simulation(model)` refuses a model already claimed or not at `:built`, so a
simulation owns its model and the lifecycle derivation stands. Where the
landed tree differs from the paragraph above, `notes_increment_70.md`
records the ruling: the `Dual` clock assertion became `frames!` on a model
rather than going, the model's cell is `frame_diag`, the loop's error arms
no longer write the status, and R9's "the model rethrows raw" was revised
in the brief before launch. The facts below are as of `dd4d092` and every
brief re-checks them.

## Facts the briefs will cite

As of `dd4d092`. Every one is re-checked against the tree before it enters a
brief.

- `_frozen`: `build.jl:1060`. The event compile guard: `build.jl:1551`.
- `Clock{T}`: `store.jl:128`, fields `t`, `frame`, `boundary`, `t₀`. Its
  docstring (`store.jl:116`) states the index-anchored grid rule.
- `Executor`: `build.jl:1389`, immutable, `clock::CL`, `cursor`, `stepper`,
  `xnext`, `ẋnext`, `has_localized`.
- `Simulation`: `sim.jl:135`, five fields; `Run{T}`: `sim.jl:103`.
- `Simulation(deployment, T)`: `sim.jl:192`; `activation(build, T)`:
  `build.jl:969`.
- `init!`: `sim.jl:799`; `_open_run!`: `sim.jl:703`; `_open_trajectory!`:
  `sim.jl:645`; `boundary_zero!`: `sim.jl:507`; `_host_boundary_zero!`:
  `sim.jl:1660`, resets the lifecycle to `:built` on a throw.
- The frame loop: `sim.jl:1515` onward, `drain!` then `frame!` then the
  boundary then `publish!` then `_stop_hit`, under `sigatomic`.
- `frame!`: `localization.jl:38`; `_localized_frame!` touches the runtime at
  `publish!`, `_stop_hit` and `report_cell!(sim.plane.loop_diag, …)`.
- `drain!`: `sim.jl:2032`, writes the cursor's `:drain` phase and the reset,
  increments `trc.frames`, dispatches to `_replay_drain!` under a feed.
- `ExecutionCursor`: `executor.jl:16`; `CursorFrame`: `diagnostics.jl:195`;
  `_wrap_step`: `sim.jl:1596`.
- `STOPPED_SIM_LEGAL`: `diagnostics.jl:1179`; the services' gate reads
  `lifecycle(sim)` at `trim.jl:444` and `linearize.jl:129`; `checkpoint`'s
  at-rest check at `sim.jl:846`.
- `trim!`'s scratch: `trim.jl:568`; its `Simulation{Float64}` restriction:
  `trim.jl:442`, diagnostic reason `:non_nominal` at `diagnostics.jl:1978`.
- `Checkpoint{T}`: `checkpoint.jl:40`.
- `Deployment`: `deployment.jl:320`.
