# Brief: increment 70, the model split, part one: `Model`, the hooked frame and the nominal-only `Simulation`

One docs stage, four code stages, one cold review and a fixer if the
review needs one. Written at 49592cc on 2026-10-09. Every line number
below is from `git show 49592cc:file`; `src/` and `test/` are identical
there to dd4d092, increment 69's last commit. Find passages in
`docs/design/implementation.md` by heading. The register this brief
delivers is `briefs/roadmap_model_split.md` (R1 to R12); where this brief
and the roadmap differ, this brief rules, and the two differences are
named under "What is settled".

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

The user's rulings of 2026-10-09, recorded in the roadmap and restated here
with the spellings the code takes. Two of them moved while this brief was
written, each for a reason the inventory surfaced; both are flagged and
both go into D-317.

- **The split (R1, R2).** `Model{T,E}` holds the deployment and the
  executor, `Simulation` holds a `Model{Float64}` beside the plane, the
  control and the run. `Model` binds nothing in `src/` or `test/`; the
  seven `Model` hits in the spec and the log are checked by stage 0 before
  the glossary entry lands.
- **The scalar rule (R3).** `Simulation` takes a `Model{Float64}`, as a
  type. `_frozen` (`src/build.jl` 1060) and the event compile guard (1551)
  stay exactly as they are. No `AbstractFloat` heuristic anywhere.
- **The `Dual` model is a scratch and stays public (R4).** Nothing in this
  increment moves `trim!` or `linearize`; they keep taking a
  `Simulation{Float64}` through forwarding, and increment two moves them.
- **The clock keeps its name and loses its counters (R5, revised).**
  `Clock{T}` (`src/store.jl` 128) keeps `t::T` and `t₀::Float64` and loses
  `frame` and `boundary`, which move onto `Run`. The revision: the roadmap
  put `t₀` on the run. The frame computes its target as `t₀ + k·h`
  (`_grid_time`, `src/localization.jl` 18), and the model owns the frame
  (R7), so the model needs `t₀`; `init!` on the model sets it with `t`, and
  it is time, not a count. D-260's clause "the origin `t₀` is not a run
  field; the clock holds it" therefore survives verbatim. The two counters
  are the run's: reset at every door, advanced by the loop, published in
  every snapshot. `Clock` stays a mutable struct with a concrete field type
  and the `Executor` stays immutable; the entries keep their `clock::CL`
  field and `_bundle_expr`'s one read of `entry.clock.t`
  (`src/executor.jl` 122) is untouched, as are the five
  `activation_scalar(entry.clock)` calls (154, 160, 238, 376, 425).
- **The checkpoint is not split here (R6).** `Checkpoint{T}`
  (`src/checkpoint.jl` 40) keeps its eleven fields and its parameter;
  `_take_checkpoint` reads `t` and `t₀` off the model's clock and `frame`
  and `boundary` off the run. Increment two splits it.
- **The model owns the frame, with two hooks (R7).** `frame!(model, k,
  hooks = NoHooks()) → Bool`. `hooks` is a `FrameHooks` value with two
  generic functions, `frame_top!(hooks)` run first, before the model
  touches any state, and `settled!(hooks)::Bool` run at every settled
  boundary, `t*` boundaries and the frame top's included. `true` from
  `settled!` abandons the frame's remainder and is `frame!`'s return. The
  simulation's `LoopHooks` is one struct with concrete fields, the
  simulation, the roster, the pacer and the ignore mask, built once per
  advance; `frame_top!` on it is today's `drain!` body and `settled!` is
  `publish!` then `_stop_hit`. The model never learns who requested the
  stop; `_advance!` reads `_stop_hit` again after a `true`. `NoHooks` is a
  singleton whose two methods do nothing and return `false`. `init!` on
  the model takes `hooks` too, so boundary zero publishes through
  `settled!`. The chattering report (`localization.jl` 94) and the firing
  budget report (`sim.jl` 567) go to the model's own `DiagCell`, which the
  simulation folds into the plane's `loop_account` at the drain beside the
  plane's loop cell. §11.2's rule that every boundary publishes before
  integration resumes becomes a contract on `settled!`.
- **The cursor is the model's (R8).** `ExecutionCursor` stays on the
  executor. Every phase write moves into model code; the `:drain` phase
  with its `comp = 0; fn = :none` reset (`sim.jl` 2034 to 2036) is written
  by `frame!` before `frame_top!`.
- **Two lifecycles (R9, revised).** `Model` is a mutable struct whose
  `@atomic status::Symbol` is `:built`, `:consistent` or
  `:inconsistent`, written only by the model's own doors and catch sites.
  `Control.lifecycle` is replaced by `@atomic running::Bool`, and
  `lifecycle(sim)` is derived, keeping its five observable values:

  | `running` | `status` | `closed(sim.run)` | `lifecycle(sim)` |
  |---|---|---|---|
  | true | any | any | `:running` |
  | false | `:built` | any | `:built` |
  | false | `:inconsistent` | any | `:errored` |
  | false | `:consistent` | false | `:initialized` |
  | false | `:consistent` | true | `:stopped` |

  The revision: the roadmap had the model rethrow raw and the simulation
  wrap. The model's frame knows every fact a `StepError` carries, the
  cursor, `t`, the entry boundary `k - 1` and the host, so the model's
  `frame!` and `init!` host the catch and build the carrier through
  `_wrap_step(model, …)`, the one constructor. The simulation's catch in
  `_advance!` keeps only the disposition: the mask, the interrupt arms and
  the termination. Without this, `test_failures.jl` 471 to 492 loses the
  cursor frame it asserts on a `Dual` executor. An `InterruptException`
  is neither wrapped nor marks the status, exactly as the `err isa
  InterruptException ||` arms at `sim.jl` 1559 and 1665 read today, so
  D-268's interrupt windows are unchanged.
- **Doors (R10).** On the model: `init!`, `apply!`, `evaluate!`,
  `integrate!`, `boundary!`, `offtick_boundary!`, `boundary_zero!`,
  `frame!`, `phase_bodies`, `warnings`, `port`, `state`, `modes`. On the
  simulation: `run!`, `step!`, `replay!`, `restore!`, `checkpoint`,
  `live!`, the devices, the recording and every accessor it has today.
  `init!(sim, …)` forwards to `init!(sim.model, …; hooks)` after the
  operational gate and does the loop's bookkeeping after. The seven model
  doors that exist on the simulation today (`apply!`, `evaluate!`,
  `integrate!`, the three boundary routines, `phase_bodies`) keep a
  one-line forwarding method, since 57 test sites call them on a sim; no
  gate lives on a model door in this increment.
- **Constructors (R11).** `Model(deployment, T = Float64; chunk_size =
  16)`, `Model(build, T = Float64; grid kw…, chunk_size)`, `Model(root, T =
  Float64; kw…)`; `Simulation(model::Model{Float64}; join_timeout = 5.0)`;
  the sugar `Simulation(deployment; join_timeout, chunk_size)`,
  `Simulation(build; kw…)` and `Simulation(root; kw…)`, each defined as
  the composition through a `Float64` model. The positional scalar leaves
  every `Simulation` form in stage 4; a `Simulation(deployment, Float32)`
  is then a `MethodError`, which is the type refusal R3 asks for.
  `chunk_size` is `compile`'s and moves to `Model`'s constructors;
  `join_timeout` stays `Simulation`'s and still validates under
  `ArgumentInvalid`.
- **Out of scope, recorded (R12).** `CursorFrame` and `ExecutionCursor`
  stay two structs; the sampled-data activation stays an extension.
- **A stepping helper for a standalone model.** `frames!(model, n)` in
  `test/utils.jl`: `k₀ = round(Int, (clock.t - clock.t₀) / h)`, then
  `frame!(model, k₀ + i)` for `i in 1:n` under `NoHooks()`. It is what the
  eleven `Dual` tests that advance a simulation today run on.
- **Verified before writing.** `Model`, `FrameHooks`, `NoHooks`,
  `LoopHooks`, `frame_top!`, `settled!` and `frames!` bind nothing in
  `src/` or `test/`. `src/Redstone.jl` has no export lines; the include
  order (lines 7 to 31) puts `store` before `executor` and `build`,
  `build` before `checkpoint`, `trace`, `control` and `sim`, and
  `localization` after `sim`. `Simulation` appears as a type annotation in
  `test/` once, `test_roster.jl` 32 to 36 (`RosterEmptier.sim`). The Julia
  floor is 1.13. `test/utils.jl` 3 is `D8`; `LinearizeDual` is
  `src/linearize.jl` 60 and `ProbeDual` `src/build.jl` 762. No test calls
  `boundary_zero!`, `_stop_hit`, `_grid_time`, `_open_trajectory!`,
  `_open_run!` or `_take_checkpoint` directly, and none spells `Run{`,
  `Snapshot{` or `ExecutionCursor`.

## Out of scope

- `trim!` and `linearize` onto `Model{Float64}`, and the checkpoint split
  (increment two). Their `Simulation{Float64}` methods and `:non_nominal`
  refusals stay as they are, reached through `sim.model`.
- The "model" vocabulary sweep over the spec and the companions, and the
  glossary `nominal` sentence (increment three). Stage 0 edits only the
  sentences the code would otherwise falsify.
- Gates on the model's doors, a `Model`-level `checkpoint`, and any
  `show` method for `Model` beyond what makes the REPL not throw.
- `frame_walkthrough.md`'s pseudo-code (`sim.exec.clock.…`, `sim.stepper`),
  already stale against the tree; increment three's sweep.

## Reading, in order

- `docs/design/briefs/roadmap_model_split.md` whole (240 lines).
- `docs/design/pending.md` 16 to 26.
- `docs/design/decisions.md` D-254 (9730 to 9780), D-256 (9868 to 9914),
  D-260 (10056 to 10139), D-261 (10140 to 10282), D-274 (11370 to 11462),
  D-282 (11829 to 11855), D-052 (1555 to 1577), D-268 (10815 to 10949).
- `docs/design/spec.md` §9.1's pipeline table, 3770 to 3778; §9.2's
  materialization, 3972 to 3985 and 4046 to 4055; §9.4, 4375 to 4517;
  §11.5's trace paragraphs, 7160 to 7237; §11.8, 7774 to 7913; §12.1,
  7920 to 7993; §12.6, 8562 to 8760; §13.4, 9364 to 9470; §13.5's return
  sentence, 9598 to 9606; §14.5, 10489 to 10589; Appendix C's
  `Simulation` listing, 11762 to 11770; the glossary entries `executor`
  12996, `nominal` 13024, `Run` 13211, `checkpoint` 13278, `StopPolicy`
  13256, `execution cursor` 13457. Never read the spec whole.
- `docs/design/tools/spec_style.md` and `decisions_style.md` whole, stage 0
  only.
- `docs/design/implementation.md`: the head of "What is real here" (11 to
  42) down to its rule on deviations (27 to 31); the rows `### src/sim.jl`
  (657 to 708), `### src/store.jl` (717 to 732), `### src/build.jl` (157
  to 223), `### src/executor.jl` (470 to 499), `### src/localization.jl`
  (555 to 570), `### src/stepper.jl` (709 to 716), `### src/checkpoint.jl`
  (224 to 247), `### src/control.jl` (268 to 304), `### src/dataplane.jl`
  (305 to 331), `### src/trace.jl` (733 to 762), `### src/devices.jl` (387
  to 430), `### src/conditions.jl` (248 to 267); "Authoring caveats" whole
  (821 to 956), the mutant caveat last of all; "Naming" (957 to 1037);
  "Running the suite" (1038 to 1111). Never restate either in a commit or
  a comment.
- `src/sim.jl` 1 to 240 (the sources, the policy, `Run`, `Simulation`, the
  constructors); 262 to 272; 325 to 413 (the accessors and the gates); 440
  to 672 (the boundary routines, the event phase, `integrate!`, the
  sweep, the trajectory and periphery openers); 690 to 925 (`_open_run!`,
  `init!`, `checkpoint`, the checkpoint door, `restore!`); 930 to 965
  (`_compile_feed`); 1040 to 1125 (`replay!`); 1140 to 1160 (`live!`);
  1220 to 1270 (`run!`, the replay bound, the mode settle); 1285 to 1470
  (`_run_body!`, the accounts, the thread budget); 1500 to 1670
  (`_advance!`, the interrupt source, `_wrap_step`, `_species`,
  `_host_boundary_zero!`); 1700 to 1780 (`step!`); 1900 to 1980 (`attach!`,
  `detach!`); 2025 to 2115 (`drain!`, `_replay_drain!`); 2140 to 2290
  (`publish!`, `_status`, the accessors).
- `src/localization.jl` whole (239 lines). `src/stepper.jl` 40 to 112.
  `src/store.jl` 110 to 140. `src/build.jl` 1370 to 1410 and 1430 to 1465
  and 1595 to 1610. `src/executor.jl` 1 to 130. `src/checkpoint.jl` whole
  (167 lines). `src/control.jl` 55 to 135. `src/roster.jl` 120 to 130 and
  190 to 216. `src/dataplane.jl` 330 to 400 and 655 to 680.
  `src/devices.jl` 495 to 605. `src/conditions.jl` 550 to 575.
  `src/trim.jl` 440 to 450 and 565 to 575 and 624 to 671.
  `src/linearize.jl` 119 to 135 and 205 to 220. `src/readers.jl` 360 to
  372. `src/trace.jl` 50 to 95. `src/Redstone.jl` whole.
- `test/utils.jl` whole (68 lines); `test/RedstoneTests.jl` whole (110
  lines); the test passages each stage names.

## Stage 0: the ruling and the spec

### The shape

One docs commit, written under `spec_style.md` and `decisions_style.md`
read first. Three kinds of edit: a new log entry, the spec sentences the
code would otherwise falsify, and the queue bullet.

**`docs/design/decisions.md`, D-317**, after D-316's body (13449) and
before the linkify marker (13451). Title: "Split the `Model` from the
`Simulation`, and run only the nominal one". Position: a headline
sentence, then one bullet per ruling: the split and the four fields; only
a `Model{Float64}` is run, as a type on the `Simulation` constructor; the
`Dual` model as a service's scratch, public, executors never cached; the
clock as `t` and `t₀` on the executor, the frame and boundary counters on
the run; the model owning the frame with the two hooks returning `Bool`,
the frame's diagnostics in the model's cell; the cursor the model's; the
three-valued model status with `lifecycle(sim)` derived by the table
above; the model's doors hosting the catch and building the `StepError`;
the model's door set and the simulation's. Spec: §9.1, §9.2, §11.5,
§11.8, §12.1, §12.6, §13.4, §13.5, §14.5. Rationale: the diagnosis from
the roadmap's "Diagnosis", the `apply!`, `boundary_zero!` and `_scratch`
facts included, and the `t₀` and catch-site reasons above. Rejected, one
item each, as the roadmap records them: widening the two `build.jl` rules
to `AbstractFloat`; a type heuristic refusing `AbstractFloat` scalars at
the door; refusing only the advance doors at a non-nominal simulation;
`t₀` on the `Deployment`; `t₀` on the run (this brief's revision); the
model rethrowing raw (likewise); ad hoc closures as hooks; a boolean
model status; two cursors; absorbing the drain into the frame; caching
executors. A closing prose line in the Position, in D-255's form (9819
to 9822): supersedes D-254's "`Simulation` materializes a deployment at
`T`" bullet, D-256's five-field roster and its placement of the loop's
diagnostic cell on the plane alone, and D-282's "the `Simulation` owns
its nominal activation's buffers" bullet, each now the `Model`'s; D-260's
`t₀` clause stands. Those three entries get a dated annotation paragraph
in the log's existing form (13017 is one) and keep `ratified`.

**`docs/design/spec.md`.** Each passage keeps its claims and changes only
what the split falsifies; the claim-inventory procedure of
`spec_style.md` applies to every paragraph touched.

- §9.1's table, 3776: materialization consumes "the `Deployment`, a
  scalar `T`" and produces `Model{T}`; a new last row, "the simulation",
  consumes "a `Model{Float64}`" and produces `Simulation`, user code
  "none". The sentence after the table (3779 to 3781) names the three
  constructors.
- §9.2, 3972 to 3985: deploying and materializing stay two steps; the
  constructor block becomes four lines, `Model(deployment, T)`,
  `Simulation(model)`, `Simulation(build; kw...)`, `Simulation(world;
  kw...)`, each with its comment. A new bold ruling after the block,
  citing D-317: **a `Simulation` runs a `Model{Float64}` and nothing
  else**, with one sentence each on why (the nominal activation is the
  only one that runs in real time, §9.4) and on what a `Model` at another
  scalar is for (the services' scratch, stepped frame by frame with no
  ticks and no events). 4051: "`Model` materializes it at a scalar type
  `T`, and `Simulation` runs a `Model{Float64}`".
- §11.5, 7164 to 7165 and 7190: "the clock in full" becomes "`t` and
  `t₀`, the frame and boundary counters"; `Trace{T}` becomes `Trace`
  with the sentence that the recording is the nominal simulation's.
- §11.8: where the loop's own cell is introduced (7797 to 7798), one
  sentence that the model's frame writes its own cell, the chattering
  and firing-budget reports, and the drain folds it into the loop's
  account beside the loop's own cell (D-317).
- §12.1, 7947 and 7963: `Control` holds the running flag rather than the
  lifecycle state; `lifecycle(sim)` is derived (§12.6).
- §12.6, 8564 to 8580: `Run` has six fields, the four of today plus
  `frame` and `boundary`, the trajectory's counters, reset by every door
  and advanced by the loop; "the origin `t₀` is not a run field" stays
  and now says the model's clock holds it beside `t`. 8582 to 8587:
  `Simulation` rather than `Simulation{T}`. 8589 to 8606: **`Simulation`
  is a mutable struct of four fields** (D-317), the model, the run, the
  plane and the control, and the model is the deployment, the executor,
  its status and its diagnostic cell; the sentence placing the loop's
  cell on the plane gains "and the frame's own on the model". 8611 to
  8619: the five states stay the observable vocabulary, and a new
  sentence states that `lifecycle(sim)` derives them from the model's
  status, the running flag and `closed(run)` (D-317), with the table
  above rendered in prose or as a table.
- §13.4, 9366 to 9369 and 9372 to 9373: the model's frame, not the loop,
  wraps the macro-sequence in the one `try`, and the loop's own `try`
  disposes; "a plain mutable field in the loop state" becomes "of the
  executor". 9456 to 9460: boundary zero's catch is the model's `init!`,
  and the simulation's `init!` moves the lifecycle.
- §13.5, 9602 to 9603, and the glossary at 13260: `frame!` returns
  whether the frame was abandoned, and the loop reads the requester off
  the snapshot it just published.
- §14.5, 10563 to 10566: `init!(model, condition; t0)` with the
  simulation's `init!` forwarding to it.
- Appendix C, 11762 to 11770: `Model(deployment, T; chunk_size = 16) →
  Model{T}` with the `chunk_size` row, and `Simulation(model;
  join_timeout = 5.0) → Simulation` with the `join_timeout` row.
- The glossary: a new `Model` entry (`g-model`, alphabetical place), six
  lines; `Run` (13211) gains the counters; `checkpoint` (13278) says `t`,
  `t₀` and the counters; `executor` and `execution cursor` unchanged. The
  seven existing `Model` word hits in the spec and the log are read
  first; if any names the component tree, stage 0 reports it and leaves
  it, since increment three sweeps.

**`docs/design/pending.md`**, 16 to 26: the bullet is rewritten as
increment 70's, stating what the code owes D-317 by stage (the split,
stage 1; the clock and the lifecycle, stage 2; the hooked frame, stage
3; the nominal-only simulation and the `Dual` fixtures, stage 4), and
what increments two and three still owe (the services and the checkpoint
split; the vocabulary sweep). Stage 4 retires the stage lines and leaves
the two later increments' lines.

### The battery

`linkify.jl` first, then `check_refs.jl`, `check_rows.jl`,
`check_glossary.jl --strict`, `check_bold.jl`, then `linkify.jl` again as
a no-op; `audit_fragments.jl 49592cc` over the log. A scripted edit reads
and asserts every file's matches before opening any for writing; `git
diff --stat` before committing.

### Bookkeeping

Nothing in `src/` or `test/`. The commit touches `spec.md`,
`decisions.md` and `pending.md`, and nothing else.

## Stage 1: the split

### The shape

In `src/sim.jl`, before `Simulation` (135): `Model{T,E}`, an immutable
struct of `deployment::Deployment` and `exec::E`, with the docstring
saying what it is (the materialized activation that can be written to,
evaluated and stepped) and what it is not (nothing that runs in real
time, talks to devices or records). Its constructors follow
`Simulation`'s three forms (192 to 223) with `T` positional and
`chunk_size` the materialization's keyword; the diagnostics
`Simulation`'s constructor raises for `join_timeout` stay there.
`Simulation{T,E}` becomes four fields, `model::Model{T,E}`, `plane`,
`control`, `run`, and `Simulation(deployment, T; join_timeout,
chunk_size)` is defined as `Simulation(Model(deployment, T; chunk_size);
join_timeout)`; the two sugar forms compose as today. `T` stays on
`Simulation` through stage 3.

Every `sim.exec` and `sim.deployment` read in `src/` goes through
`sim.model`; the source inventory in the roadmap's "Facts" and the
reading list above name every site. The seven model doors gain their
model method and keep a forwarding method on the simulation: `apply!`
(`src/conditions.jl` 572), `evaluate!` (446), `integrate!` (602 to 607),
`boundary!` (462 to 470), `offtick_boundary!` (481 to 486),
`boundary_zero!` (507 to 515), `phase_bodies` (428); `event_phase!` and
`_round!` (526 to 589) take the model, and the firing-budget report at
567 keeps writing the plane's loop cell through a `sim` argument until
stage 3 (pass the cell, not the sim). `port`, `state`, `modes` (2269 to
2289) and `warnings` (233) get model methods, the simulation's defined
as the forwarding. `_scratch` (`src/trim.jl` 569 to 573) and `_verdict!`
(624 to 671), `linearize` (`src/linearize.jl` 119 to 200) and
`_set_clock!` (216 to 220), `gather_reads` (`src/readers.jl` 367) and
`_fingerprint` (`src/checkpoint.jl` 57) reach the executor through the
model. `integrate!(stepper, sim, h)` (`src/stepper.jl` 62, 98) takes the
model. `frame!`, `_localized_frame!`, `_trial!` and `_crossing` keep
their simulation signatures until stage 3 and read `sim.model.exec`.

### Tests

- A scripted sweep over `test/`: `.exec.` becomes `.model.exec.` and
  `.deployment` becomes `.model.deployment` on every simulation receiver;
  the receivers are the variables the test survey lists (`sim`,
  `dual_sim`, `seeded`, `target`, `twin`, `sim2`, `reference`, …), so the
  script matches `<ident>.exec.` and `<ident>.deployment` and asserts the
  count per file against this list before writing: `.exec` hits
  `test_bindings.jl` 2, `test_build.jl` 3, `test_conditions.jl` 25,
  `test_continuous.jl` 1, `test_dataplane.jl` 2, `test_devices.jl` 15,
  `test_diagnostics.jl` 2, `test_discrete.jl` 10, `test_events.jl` 3,
  `test_executor.jl` 17, `test_failures.jl` 5, `test_lifecycle.jl` 18,
  `test_linearize.jl` 2, `test_localization.jl` 1, `test_readers.jl` 30,
  `test_stepper.jl` 2, `test_store.jl` 16, `test_trace.jl` 41,
  `test_trim.jl` 7, `utils.jl` 2; `.deployment` hits `test_assembly.jl`
  11, `test_bindings.jl` 1, `test_blocks.jl` 10, `test_build.jl` 2,
  `test_conditions.jl` 11, `test_continuous.jl` 1, `test_discrete.jl` 27,
  `test_failures.jl` 2, `test_lifecycle.jl` 4, `test_linearize.jl` 3,
  `test_localization.jl` 6, `test_readers.jl` 17, `test_stepper.jl` 1,
  `test_trace.jl` 4, `test_trim.jl` 3. A `.deployment` hit on a variable
  holding a `Deployment` (`test_discrete.jl` 300 to 330 has several) is
  not a receiver; the script lists every rewritten line for the report.
  `test_trim.jl` 629 (`compile(build, activation(build, TD),
  sim.deployment.schedule; …)`) reads the schedule through
  `sim.model.deployment` and otherwise stands.
- `test_discrete.jl` 310 to 326 gains `Model(deployment, D8)` beside the
  two simulations: `model.deployment === deployment`,
  `eltype(model.exec.xbuf) === D8`, and `Simulation(deployment,
  D8).model isa Model{D8}`.
- `test_continuous.jl` 27: `exec isa Executor{Float64}` stands; add
  `sim.model isa Model{Float64}`.

### Routing

`sim.jl` is touched: all of it, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/sim.jl`: a `Model{T,E}` line
  before the `Simulation` line, the `Simulation` line reading four fields,
  the materialization line reading `Model(deployment, T)` with the three
  `Simulation` forms as compositions; the accessors line naming the model
  methods and the forwarding. `### src/conditions.jl`: `apply!` on a
  model. Constructs, not behaviour.
- `test/imports.jl`: `Model` on the `import Redstone:` list.

## Stage 2: the clock and the lifecycle

### The shape

`src/store.jl` 115 to 137: `Clock{T}` keeps `t` and `t₀`, the docstring
loses the `frame` sentence and says the counters are the run's. `Run{T}`
(`src/sim.jl` 103 to 108) gains `frame::Int` and `boundary::Int`, both
writable, and `_open_run!` (703 to 712) takes them, `init!` passing zeros
and `_enter_checkpoint!` (870 to 880) the checkpoint's, so the `boundary
-= 1` at 877 lands on the run it just opened. Every `clock.frame` and
`clock.boundary` site in the source inventory becomes `run.frame` and
`run.boundary`: `_open_trajectory!` 648 to 649 (which now writes the
model's clock, the event priors and the periphery, the counters being the
fresh run's), `_nonfinite` 640, `_open_run!` 705, `checkpoint` 854 to 859,
`_compile_feed` 951 to 952, `replay!` 1076, `_settle_mode!` 1266,
`_advance!` 1527 to 1536, `step!` 1738, `_replay_drain!` 2082,
`publish!` 2149 to 2151; `src/checkpoint.jl` 82 reads them off the run
and 97 writes them into the run (`_restore_state!` takes the model and
the run, or `_enter_checkpoint!` writes the counters itself). The
`clock.t` and `clock.t₀` sites stay, on `sim.model.exec.clock`. `Clock{T}`'s
constructor (134) drops the two zeros.

`src/control.jl` 62 to 75: `lifecycle::Symbol` becomes `@atomic
running::Bool`, `false` at construction. `Model` becomes mutable with
`const deployment`, `const exec` and `@atomic status::Symbol`, `:built`
at construction. `lifecycle(sim)` (332) is the table under "What is
settled", reading the three facts with acquire loads. Writers: `init!`
writes `:consistent` on the model after boundary zero; `restore!` and
`_enter_checkpoint!` write `:consistent`; `_host_boundary_zero!` (1660 to
1668) writes `:built` on a throw; `_run_body!` 1307 and `step!` 1733
write `running = true`, and their tails (1423, 1427, 1430, 1764, 1768,
1772) write `running = false` once, the `:errored` arms writing
`:inconsistent` on the model instead. `assert_stopped` and
`assert_configurable` (121 to 133) take the simulation and read
`lifecycle(sim)`; their callers are `logged` (2224) and `attach!` (1910).
The direct `@atomic control.lifecycle` reads at 404, 802, 903, 1056 and
1428 read `lifecycle(sim)`. `STOPPED_SIM_LEGAL`, `READER_LEGAL` and every
`ServiceLifecycle` payload are unchanged.

### Tests

- The sweep: `.model.exec.clock.frame` becomes `.run.frame` and
  `.model.exec.clock.boundary` becomes `.run.boundary` on every simulation
  receiver, 67 and 3 sites in the files the test survey lists
  (`test_bindings.jl`, `test_conditions.jl`, `test_devices.jl`,
  `test_failures.jl`, `test_lifecycle.jl`, `test_trace.jl`,
  `test_trim.jl`); the script asserts the counts before writing. The 19
  `.clock.t` and 4 `.clock.t₀` sites stay.
- `test_lifecycle.jl`, a new testset after 130, "`lifecycle(sim)` is
  derived from the model's status, the running flag and the closed run
  (§12.6, D-317)": a fresh simulation reads `:built` with
  `sim.model.status === :built`; after `init!`, `:initialized` with
  `:consistent` and `!closed(sim.run)`; after `run!(sim; t_end = 0.1)`,
  `:stopped` with `:consistent` and `closed(sim.run)`; after `step!(sim;
  frames = 2)` on a re-initialized simulation, `:initialized`; a
  `Tripwire` simulation (`test_failures.jl`'s fixture) run into its throw
  reads `:errored` with `:inconsistent`; and `init!` on it is refused as
  `ServiceLifecycle` with `status = :errored`, the refusal the testset at
  571 to 584 already asserts, unchanged.
- `test_failures.jl` 550 to 611 and `test_lifecycle.jl` 48 to 67 read the
  lifecycle through the public accessor and need no change beyond the
  sweep; the reviewer checks they pass unchanged.

### Routing

All of it, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/store.jl`: the `Clock` lines
  read `t` and `t₀`, the counters named as the run's. `### src/sim.jl`:
  the `Run{T}` line gains the counters; the `Model` line gains the status;
  "The lifecycle and the termination record" reads "derived". `###
  src/control.jl`: `running` for `lifecycle`; `assert_stopped` and
  `assert_configurable` on the simulation. `### src/checkpoint.jl`: where
  the counters come from.

## Stage 3: the hooked frame

### The shape

In `src/localization.jl`, before `frame!` (38): `abstract type FrameHooks
end`, `struct NoHooks <: FrameHooks end`, `frame_top!(::NoHooks) =
nothing`, `settled!(::NoHooks) = false`, with a docstring stating the
contract: `frame_top!` runs before the model touches any state and is
where external inputs arrive; `settled!` runs at every settled boundary
before integration resumes and returns whether to abandon the frame.
`frame!(model::Model{T}, k::Int, hooks::FrameHooks = NoHooks()) → Bool`:
the `:drain` cursor write and reset from `drain!` (`src/sim.jl` 2034 to
2036), `frame_top!(hooks)`, `_phase!(cursor, :integrate)`, then today's
body (41 to 44) with `_localized_frame!(model, t_to, hooks)` in place of
the four runtime arguments, then the frame top's boundary and
`settled!(hooks)` (the `k % N_base` arm of `_advance!` 1539 to 1541 moves
in), returning the hit. `_localized_frame!` (54 to 175): `report_cell!`
at 94 writes `model.diag`; 163 to 171 become `offtick_boundary!(model)`
then `settled!(hooks) && return true`. `_grid_time(model, k)`,
`_trial!`, `_crossing` take the model. The whole of `frame!` sits in one
`try` whose catch writes `:inconsistent` and rethrows
`_wrap_step(model, k - 1, :loop, err)` for anything but an
`InterruptException`, which rethrows raw; `_wrap_step` (`src/sim.jl` 1596
to 1605) and `_species` (1612 to 1651) take the model.

`init!` on the model has two methods in `src/sim.jl`. `init!(model,
plan::ConditionPlan; t0::Real = 0.0, hooks::FrameHooks = NoHooks())` does
the writes: `establish_defaults!`, `apply!`, the model's half of
`_open_trajectory!` (646 to 647 and 650), then `boundary_zero!` under the
same `try` with `:built` on a throw and host `:boundary_zero`, pointer
`0`, then `settled!(hooks)` with its return ignored, then `:consistent`.
`init!(model, condition = fragment(); kw…)` resolves (`resolve_condition`,
`assert_total`, 808 to 809) and calls the plan method. The split exists so
the simulation's `init!` can resolve before it touches the run: a refused
condition leaves the simulation exactly as it was, as the docstring at
826 onward promises. `_host_boundary_zero!` (1660 to 1668) retires into
the plan method, and `_reset_periphery!` (663 to 671) leaves
`_open_trajectory!` for the simulation's `init!`.

`Model` gains `diag::DiagCell`, `DiagCell(EMPTY_DIAG)` at construction,
and the firing-budget report (`sim.jl` 567) writes it. `drain!` (2032 to
2055) loses its cursor lines and folds `sim.model.diag` into
`plane.loop_account` beside 2053; `_replay_drain!` (2080 to 2112)
likewise beside 2090; `_sweep_tail!` (`src/devices.jl` 590 to 602)
likewise beside 599.

In `src/sim.jl`, beside `_advance!`: `struct LoopHooks{S<:Simulation} <:
FrameHooks` with `sim::S`, `roster::Vector{RosterEntry}`,
`pacer::Union{Nothing,Pacer}`, `ignore_mask::Vector{Bool}`;
`frame_top!(h::LoopHooks) = drain!(h.sim, h.roster)` and
`settled!(h::LoopHooks) = (publish!(h.sim, h.roster, h.pacer); _stop_hit(h.sim,
h.ignore_mask) !== nothing)`. `_advance!` (1510 to 1577) builds one
before its loop and its frame body becomes: `k = (run.frame += 1)`;
`hit = frame!(sim.model, k, hooks)`; `requester = hit ? _stop_hit(sim,
ignore_mask) : nothing`; the `advanced += 1` and the catch as today, the
catch no longer calling `_wrap_step` (the `StepError` arrives built) and
keeping its interrupt arm, the mask and the `failure` carry. The
simulation's `init!` (799 to 825) becomes, in order: the gate,
`_check_recording`, `resolve_condition` and `assert_total`,
`_reset_periphery!`, `_open_run!(…, 0, 0)`, `init!(sim.model, plan; t0,
hooks = LoopHooks(sim, sim.plane.roster, nothing, Bool[]))`, the trace
header; `running` untouched. A throw inside boundary zero propagates
after the model wrote `:built`, so the run `init!` opened stays behind
empty, as §13.4 says. The `ignore_mask` at boundary zero is empty because
nothing reads `settled!`'s return there.

The `k % N_base` gate needs `N_base` and `h`, both `model.deployment`'s.
A `Model{Dual}` stepped under `NoHooks` runs ticks at `k % N_base == 0`
through `boundary!`, where every discrete entry is frozen out, so the
frozen semantics are unchanged.

### Tests

- The direct callers: `test_localization.jl` 227 and 237 and
  `test_stepper.jl` 98 and 105 spell `frame!($sim, 1, $no_mask,
  $(sim.plane.roster), nothing)` under `@ballocated`; they become
  `frame!($(sim.model), 1, $hooks)` with `hooks = LoopHooks(sim,
  sim.plane.roster, nothing, no_mask)` built outside the macro, and the
  zero-allocation assertion stands. `test_diagnostics.jl` 107 and 111,
  `test_localization.jl` 236 and `test_stepper.jl` 96 and 103 call
  `publish!(sim, sim.plane.roster)` and stand. The 14 `drain!` sites
  stand. `boundary!(sim, 1)` and `offtick_boundary!(sim)` sites stand on
  the forwarding methods.
- `test/utils.jl`: `frames!(model, n)` as settled, after `gated`.
- A new testset in `test_localization.jl` after 237, "a model steps its
  frame under no hooks, and the hooks see every settled boundary (§10.4,
  D-317)": a `Model(deployment)` from the file's localized fixture,
  `init!`, `frames!(model, 10)`, and its state equals `state` of a
  simulation over the same deployment after `run!` to the same frame,
  component by component; a recording `FrameHooks` defined in the test
  (fields `tops::Int`, `boundaries::Vector{Float64}`, `settled!` pushing
  `model.exec.clock.t` and returning `false`) sees ten tops and, over a
  frame with one `t*` boundary, two boundaries whose times are the `t*`
  and the frame top; a hooks value whose `settled!` returns `true` at the
  first `t*` makes `frame!` return `true` with the clock at `t*` and the
  remainder unrun; and `frame!` on a `Model(deployment, D8)` after
  `init!` returns `false` and moves the continuous state.
- `test_failures.jl`: the `Tripwire` testset at 471 to 492 and the loop
  catch tests at 181 to 267 assert `err.cursor`, `err.t`, `err.boundary`
  and `err.host` as today and stand; add, in the testset at 471, that
  `frames!` on a `Model(…, D8)` of the same fixture throws the same
  `StepError{Tripped}` with the same cursor frame and `boundary == 0`,
  and leaves `model.status === :inconsistent`.
- The `ChatteringBudget` and `FiringBudget` assertions in
  `test_localization.jl` (three sites) and `test_events.jl` (two) read the
  loop writer's account off the status and stand; the stage confirms each
  still arrives through `loop_account`, now by way of the model's cell.

### Routing

All of it, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/localization.jl`: `FrameHooks`,
  `NoHooks`, `frame!` on the model with the hooks and the `try`, the
  model's diagnostic cell. `### src/sim.jl`: `LoopHooks`, `init!` on the
  model hosting boundary zero's catch, the simulation's `init!` as gate
  plus bookkeeping, `_advance!` disposing only, `_host_boundary_zero!`
  retired, the `drain!` fold of the model's cell. `### src/devices.jl`:
  the tail's fold. `### src/dataplane.jl` unchanged unless `DiagCell`'s
  docstring names its writers.

## Stage 4: the nominal-only simulation

### The shape

`Simulation(model::Model{Float64}; join_timeout = 5.0)` is the one
materializing constructor; `Simulation{E}` loses `T`, and so do `Run`,
`Trace` (`src/trace.jl` 57, header `Union{Nothing,Checkpoint{Float64}}`)
and `TerminationRecord` (`src/sim.jl` 73, `t::Float64`). The sugar forms
lose their positional scalar: `Simulation(deployment; join_timeout,
chunk_size)`, `Simulation(build; kw…)`, `Simulation(root; kw…)`. The
`Simulation{T}` methods in the source inventory (`_record` 378,
`_stop_hit` 387, `_open_run!` 703, `init!` 799, `_enter_checkpoint!` 870,
`restore!` 900, `_compile_feed` 942, `replay!` 1049, `logged` 2223,
`trace` 2253, `state` 2276) drop the parameter; `restore!`'s fallback
(918) stays as `restore!(::Simulation, cp::Checkpoint)` for a
`Checkpoint{T}` with `T !== Float64`, reached by a checkpoint taken from
a `Dual` model (below); `_compile_feed`'s fallback (961) goes, since a
`Trace` holds a `Checkpoint{Float64}` by type. `trim!` (`src/trim.jl` 442) and `linearize`
(`src/linearize.jl` 119) read `::Simulation`, their `:non_nominal`
refusals (557 to 562, 205 to 210) now unreachable from a `Simulation`
and kept for increment two, which moves them to the model. `_scratch`
(569 to 573) builds `Model(sim.model.deployment, T; chunk_size)`.
`_take_checkpoint(model, frame, boundary)` takes the model and the two
counters, so a test can take one from a standalone model.

### Tests

The 44 non-`Float64` `Simulation(` sites the test survey lists move, by
hand, in one of three ways; the report lists each site with its way.

- **A `Model` and reads.** Sites that only read ports, state or fields:
  `test_assembly.jl` 602; `test_build.jl` 479, 485, 627, 634, 660, 663,
  710, 720, 917, 929, 1342, 1368, 1649, 1712, 1720; `test_conditions.jl`
  621; `test_discrete.jl` 323; `test_events.jl` 312; `test_readers.jl`
  549, 572; `test_store.jl` 24, 73, 202; `test_linearize.jl` 370;
  `test_trim.jl` 669. `Simulation(x, D8; kw…)` becomes `Model(x, D8;
  kw…)`, `init!` stays `init!`, `port`/`state`/`modes` stay, and field
  paths drop `.model`. 370 and 669 pass the model to `linearize` and
  `trim!`, which take `::Simulation`, so a `Model` is a `MethodError`;
  both sites assert `MethodError` and a comment says increment two gives
  them a diagnostic. `test_readers.jl` 572 to 576 reads `model.exec.clock.t₀`
  and `.t`.
- **A `Model` and `frames!`.** Sites that advance: `test_build.jl` 614
  (the `A` loop, `frames!(model, 2)` for `run!` to `0.02` at `h = 1//100`;
  compute the count from the site's `h` and `t_end`); `test_continuous.jl`
  51; `test_discrete.jl` 80 (the frozen-tier
  testset, `frames!` for `run!` to `0.04`); `test_events.jl` 305;
  `test_failures.jl` 475, 485 (the step-bound spelling `step!(…; t_end)`
  becomes `frames!` until the throw), 714; `test_lifecycle.jl` 183 (the `Dual`
  clock assertion: `frames!(model, 3)` and `model.exec.clock.t isa D8`,
  the `step!` returns dropped); `test_localization.jl` 212;
  `test_stepper.jl` 109; `test_trace.jl` 1400 (`ramp(…; T = D8)` returns
  a `Model` after `frames!(model, 5)`; `dual_cp = _take_checkpoint(dual,
  5, 5)`, the twin is a `Model`, `_restore_state!` puts the checkpoint
  back and the assertion reads `state(twin, "c") == state(dual, "c")`
  with the frame assertion dropped).
- **The scalar refusal.** `test_trace.jl` 1261 builds a `Checkpoint{D8}`
  through `_take_checkpoint(Model(replay_model(), D8; h = 1//10), 0, 0)`
  after `init!`, and its `:scalar` `CheckpointMismatch` assertion stands
  on `restore!(sim, dual_cp)`. `test_trace.jl` 242's arm retires with a
  comment: a `Trace` holds a `Checkpoint{Float64}` by type, so
  `_compile_feed` has no scalar to mismatch and its fallback (961) goes.
- **Retired.** `test_dataplane.jl` 95 to 100, the shim converting to a
  `D8` root input: the plane only ever writes a `Float64` model, so the
  conversion it proves is unreachable; the `EntryTypeMismatch` arm above
  it keeps the shim's `Float64` conversion covered. A one-line comment at
  the site says why.
- `test_diagnostics.jl` 615 and 618 carry the string `Simulation{Dual}`
  in a rendered message; the `:non_nominal` message at
  `src/diagnostics.jl` 1978 stays this increment, so the strings stand.
  `test_lifecycle.jl` 139 reads `TerminationRecord`, `test_trace.jl` 85
  and 1116 `Checkpoint{Float64}` (stands), 230 `Trace(…)`.
- `test_discrete.jl` 312: `Simulation(deployment, Float64)` becomes
  `Simulation(deployment)`; `test_build.jl` 614's loop keeps `Float64` as
  a `Simulation` and `D8` as a `Model`.
- A new arm in `test_discrete.jl`'s materialization testset (310 to 326):
  `Simulation(Model(deployment, D8))` is a `MethodError`, and so is
  `Simulation(deployment, Float32)`.

### Routing

All of it, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`: `### src/sim.jl` (`Simulation(model)`,
  the sugar forms, `Run`, `TerminationRecord` without `T`); `###
  src/trace.jl` (`Trace` without `T`); `### src/checkpoint.jl`
  (`_take_checkpoint` on a model); `### src/trim.jl` and `###
  src/linearize.jl` (the scratch as a `Model`, the refusals kept for
  increment two); line 806's `Dual` sweep sentence if it names
  `Simulation`; `### test/fixtures.jl`'s neighbour rows gain nothing, but
  "Running the suite"'s table row for a new fixture is re-read for the
  recording hooks type the stage 3 test defines (it is not an
  `AbstractComponent`).
- `docs/design/pending.md`: the increment 70 stage lines retire; the two
  later increments' lines stay. Run the battery.
- `test/imports.jl`: `FrameHooks`, `NoHooks`, `LoopHooks`, `frame_top!`,
  `settled!`, `_take_checkpoint`, `_restore_state!` as the tests need
  them.

## The cold review

One fresh Opus reviewer over the four code commits, the docs commit read
for what they owe: open-mind stance, probe scripts in the scratchpad,
"empty is acceptable". Dimensions:

- **D-317 against the tree.** Every Position bullet holds of the code:
  the four fields and the two of the model; the `MethodError` at
  `Simulation(Model(…, D8))`; the clock's two fields and the run's two
  counters; the hooks' order inside `frame!` (top, integrate, settled at
  every boundary) and the `Bool` return; the cursor's `:drain` write
  before `frame_top!`; the status writers, by grep, being only the
  model's doors and catch sites; the derived lifecycle table, each row
  reached by a test.
- **Bit-identity.** On a scratch copy, the `MultiRate` and localized
  fixtures under `run!`, `step!` in frames and `frames!` on a bare model
  with recording hooks: identical state and identical snapshot ordinals at
  every frame against 49592cc's trajectories (`git worktree` the old tip,
  copy the root `Manifest.toml` in).
- **Mutants on a scratch copy**, each named test going red: `settled!`
  called before the frame-top boundary rather than after; the `:drain`
  phase written after `frame_top!`; `frame!` returning `false` on a `true`
  from `settled!`; the model's catch not writing `:inconsistent`; `init!`'s
  catch writing `:inconsistent` instead of `:built`; `lifecycle(sim)`
  reading `:stopped` with the run open; `t₀` taken from the run; `k % N_base`
  gating on `k - 1`; the model's cell folded nowhere; `_take_checkpoint`
  reading the counters off the clock. A surviving mutant is a missing test.
- **Allocation.** `frame!` under `LoopHooks` allocates nothing in
  `test_localization.jl`'s and `test_stepper.jl`'s canaries;
  `phase_bodies` canaries in `test_executor.jl` unchanged; one
  `LoopHooks` per advance, by a count over a 1000-frame `run!`; `frames!`
  on a `Model{D8}` allocates only what `integrate!` allocated at 49592cc
  (report both numbers).
- **Inference.** `@code_warntype` on `frame!(model, k, hooks)` with a
  `LoopHooks` shows a `Bool` return and no `Any` from `settled!`; the
  same with `NoHooks`.
- **The register and the docstrings.** Rows name constructs; `Model`'s,
  `FrameHooks`'s and `Clock`'s docstrings say what D-317 says and no
  more; the `Simulation` docstring (143 to 191) is rewritten for the
  wrapper and keeps every keyword sentence it has today.
- "Naming" over every touched file, the docs battery, and the gate once
  on the real tree, on the Julia floor `Project.toml` declares.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new name across `test/`
before defining it. Models and helpers live at top level. Report: the
commit hash, the files touched, the suite's result with the assertion
count against the predecessor's, the probe's numbers for every asserted
value, every rewritten test site with its way, and every deviation from
this brief with its reason.
