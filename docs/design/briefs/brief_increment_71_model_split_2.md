# Brief: increment 71, the model split, part two: the checkpoint split and the services on the `Model`

One docs stage, two code stages, one cold review and a fixer if the review
needs one. Written at 6730b90 on 2026-10-09, increment 70's last commit.
Every line number below is from `git show 6730b90:file`. Find passages in
`docs/design/implementation.md` by heading. The register this brief
delivers is `briefs/roadmap_model_split.md`'s "Increment two" paragraph
with R4, R6 and R10, under D-317 and D-318 as landed; where this brief and
the roadmap differ, this brief rules, and every difference is named under
"What is settled". The final tree of increment 70 passes 5943 of 5943 on
Julia 1.13.1.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

The user's rulings of 2026-10-09, restated with the spellings the code
takes. Seven points are this brief's own, each flagged **(this brief)**
with its reason; all seven go into D-319 and the user confirms them before
launch.

- **The checkpoint splits (R6).** `ModelState{T}` is the model's state as
  one value: the nine fields `Checkpoint{T}` holds today less the two
  counters, that is `x`, `s`, `m`, `table`, `prior`, `t`, `t₀`,
  `deployment` and `layout` (`src/checkpoint.jl` 41 to 53). `Checkpoint`
  wraps one with the run's cursor: `state::ModelState{Float64}`,
  `frame::Int`, `boundary::Int`. **(this brief)** `Checkpoint` loses its
  scalar parameter: a cursor belongs to a trajectory, and only a nominal
  model has one, so a `Checkpoint` is nominal by type, as `Trace` and `Run`
  became in increment 70. The scalar refusal moves to the bare state
  (below).
- **The model's doors (R10).** `checkpoint(model) → ModelState` and
  `restore!(model, model_state; hooks = NoHooks())`. The read is legal at
  `:consistent` with the clock on a grid top, refused otherwise:
  `ServiceLifecycle(op = :checkpoint, status = model.status, legal =
  [:consistent])` at `:built` or `:inconsistent`, and `CheckpointMidFrame`
  with the frame the clock sits inside when it is off the grid. **(this
  brief)** The two gates mirror the simulation's, since §12.6 says a
  checkpoint is the state at a frame top and §14 says an errored state may
  not become one; a model's `:inconsistent` is the simulation's `errored`.
  The restore door is today's `_restore_state!(model, cp; hooks)`
  (`src/model.jl` 540 to 546) made public: the claim's gate, then the
  fingerprint check collected into one `CheckpointMismatch` throw before
  any write, then the copy, `settled!(hooks)` and `:consistent` last. No
  status gate on it: restoring into a `:built` twin is the door's use
  (`test/test_trace.jl` 1441 to 1446). `_restore_state!(model, model_state;
  hooks)` stays as the ungated inner the simulation's door body calls, the
  `apply!`/`_apply_plan!` shape of D-318.
- **The simulation's doors.** `checkpoint(sim) → Checkpoint` keeps its
  gate and its mid-frame test (`src/sim.jl` 647 to 664) and wraps
  `checkpoint(sim.model)` with `sim.run.frame` and `sim.run.boundary`.
  `restore!(sim, cp::Checkpoint; kw…)` is unchanged in behaviour. **(this
  brief)** A second door, `restore!(sim, model_state::ModelState{Float64};
  kw…)`, is how a state prepared on a standalone model enters a simulation
  (§9.2 3999 to 4002, D-318): the same gate, recording keywords and
  fingerprint check as the checkpoint form, then `_enter_checkpoint!` with
  `Checkpoint(model_state, k, 1)`, where `k = round(Int, (t - t₀) / h)` and
  `t == t₀ + k·h` is checked first (`CheckpointMidFrame` otherwise, frame
  `k`). The restored boundary publishes under ordinal 0 and the run's
  counter reads 1 after it, exactly `init!`'s shape: a standalone model has
  no trajectory whose ordinals could continue, so the door opens a fresh
  one at the state's grid position. The scalar refusal is on this door and
  on the model's: `restore!(::Simulation, ::ModelState{T})` and
  `restore!(::Model{T}, ::ModelState{S})` throw
  `CheckpointMismatch(what = :scalar, expected = <the state's>, found =
  <the target's>)`; the `Checkpoint{T}` fallback at `src/sim.jl` 723 to 725
  retires with the parameter. The `:scalar` message (`src/diagnostics.jl`
  2181 to 2186) names a `Model`.
- **The services take a `Model{Float64}` (R4, R10).** `trim!(model,
  problem; baseline, t0 = 0.0, backend = LevenbergMarquardt())` and
  `linearize(model, tap_set; about = nothing, t0 = nothing, width =
  LINEARIZE_WIDTH)`, both `model::Model{Float64}`. Each scratch half is
  `_scratch(model, T)`, a `Model` as today (`src/trim.jl` 562 to 563, over
  the model's deployment and `chunk_size`). `trim!` on a model is gated on
  the claim first, `_claimed_gate(model, NoHooks(), :trim!)` before any
  check, since it commits; `linearize` is a read and carries no claim gate.
  **(this brief)** The simulation's `trim!` is not a plain forward: the
  commit is `init!(sim, …)`, whose run opening and trace header bracket the
  model's `init!` and whose outcome is decided only after the solve. So
  `trim.jl` factors the solve out of the commit: `_solve_problem(model,
  problem; baseline, backend)` runs today's body from the setup checks
  through the verdict evaluation (`src/trim.jl` 450 to 547, with the
  zero-decision bypass) and returns what `_verdict!` needs; `_verdict!`
  takes the model and a one-argument `commit!` callable it hands the
  committed condition to, and reads the committed world off `model.exec`
  (614 to 661). The model's `trim!` passes `condition -> init!(model,
  condition; t0 = Float64(t0))`, the simulation's `condition -> init!(sim,
  condition; t0 = Float64(t0))`. One call per `trim!`, off every hot path.
  `linearize` likewise splits into `_check_linearize_call(about, t0,
  width)` (`src/linearize.jl` 121 to 124), the operating point, and
  `_linearize(model, tap_set, operating_point, about, t0, width)` (134 to
  199). The model's default operating point is `checkpoint(model)`, behind
  its own `ServiceLifecycle(op = :linearize, status = model.status, legal =
  [:consistent])` so the refusal names the service as the simulation's
  does; the simulation's is `checkpoint(sim).state`, so the mid-frame
  payload stays the simulation's (`test/test_linearize.jl` 196 to 197,
  `test/test_trace.jl` 1230 to 1231).
- **The simulation's methods live in `sim.jl`.** `trim!(sim::Simulation,
  problem::TrimProblem; kw…)` and `linearize(sim::Simulation,
  tap_set::Taps; kw…)` carry today's lifecycle gates (`src/trim.jl` 444 to
  448, `src/linearize.jl` 126 to 131) and compose as above; `trim!(sim,
  other; kw…)` and `linearize(sim, other; kw…)` forward to the model's
  misuse fallbacks, which move from `::Simulation` to `::Model` (553 to
  555, 202 to 204). `trim.jl` and `linearize.jl` then name no `Simulation`
  and move above `sim.jl` (the layout rule of `brief_source_layout_model.md`):
  `src/Redstone.jl` 7 to 31 becomes `…, conditions, model, stepper, frame,
  trim, linearize, sim, devices, show, blocks`.
- **The `:non_nominal` refusals return, on the model.** `trim!(model::Model{T},
  problem::TrimProblem; kw…) where {T}` and `linearize(model::Model{T},
  tap_set::Taps; kw…) where {T}` throw `ArgumentInvalid(call, reason =
  :non_nominal, value = "Model{$T}")`; the `Model{Float64}` methods are
  more specific and win. The message (`src/diagnostics.jl` 1977 to 1985)
  says "needs a nominal `Model{Float64}`".
- **The grid arithmetic moves to the frame.** **(this brief)** `_frame_slack`,
  `_frames_to` and `_frame_at` (`src/sim.jl` 255 to 267, their comment
  included) move to `src/frame.jl` beside `_grid_time` (15 to 18);
  `_t_end_frame` (268 to 269) stays. `checkpoint(model)` reads the frame
  the clock sits inside through `_frames_to`, and a call resolves at
  runtime whatever the include order, but grid arithmetic the model layer
  reads belongs with the frame.
- **Appendix B's `Model` block.** As the roadmap states it, with one
  correction **(this brief)**: the closing sentence says the stepping
  primitives `evaluate!`, `integrate!`, `boundary!`, `offtick_boundary!`
  and `boundary_zero!` are internals the spec names only as mechanisms,
  outside the API and outside the claim's gate, and that `apply!` is an
  internal outside the API that the claim's gate refuses on a claimed
  model, since D-318 rules exactly that and the code does it (`src/model.jl`
  159 to 161). The roadmap's "`apply!` … outside the gate" is read as
  "outside Appendix B's API"; the user confirms.
- **Verified before writing.** `ModelState`, `_solve_problem`,
  `_check_linearize_call` and `_linearize` bind nothing in `src/` or
  `test/`. `Checkpoint{Float64}` is spelled in `test/` twice
  (`test_trace.jl` 85 and 1114) and in `src/trace.jl` 56 and 60.
  `_take_checkpoint` has two test sites (`test_trace.jl` 1261 and 1438)
  and three in `src/sim.jl` (624, 663, 911); `_restore_state!` has three
  test sites (`test_lifecycle.jl` 193, `test_trace.jl` 1444 and 1449), two
  definitions (`checkpoint.jl` 59, `model.jl` 540) and three callers
  (`model.jl` 542, `sim.jl` 684, `linearize.jl` 141).
  `GuardedRamp`'s guards return `Bool` (`test_trace.jl` 1082 to 1083), so
  they are boundary-detected and produce no `t*`; the `t*` fixture is
  `test_localization.jl`'s (283 to 290), with `RecordingHooks` (9 to 17).
  `string(typeof(other))` appears once each in `trim.jl` (555) and
  `linearize.jl` (204), the two the authoring caveat names. `README.md`
  names none of `trim!`, `linearize`, `checkpoint`, `restore!` or
  `Checkpoint`. `publish!` stamps `run.boundary` and then increments it
  (`src/sim.jl` 1889 to 1892), so after `init!` the header reads frame 0,
  boundary 1 (`test_trace.jl` 99).

## Out of scope

- The "model" vocabulary sweep over the spec and the companions, the
  glossary `nominal` sentence, and the three companions that spell the old
  forms (`flight_case_studies.md`, `linearization_walkthrough.md`,
  `trim_environment_walkthrough.md`): increment three. The simulation forms
  they show stay true.
- `R12`: `CursorFrame`/`ExecutionCursor`, the sampled-data activation.
- Any change to `frame!`, the hooks, the loop or the drain. The frame
  canaries and the inference claims of increment 70 stand untouched.
- A `show` method for `ModelState` or `Checkpoint` beyond what keeps the
  REPL from throwing.
- The pinned sites in `test_trace.jl` 1455 to 1515 (the `restore = false`
  clock mismatches) change only by the field sweep.

## Reading, in order

- `docs/design/briefs/roadmap_model_split.md` whole (280 lines), then
  `notes_increment_70.md` rulings 15 to 21 and the open points.
- `docs/design/pending.md` 16 to 27.
- `docs/design/decisions.md` D-274 (11382 to 11475), D-282 (11841 to
  11871), D-317 (13467 to 13627), D-318 (13628 to 13698); the linkify
  marker is 13699.
- `docs/design/spec.md` §9.2's two rulings, 3988 to 4002; §9.6, 4747 to
  4777; §12.6's checkpoint paragraph, 8772 to 8790, and the four-field
  paragraph, 8627 to 8646; §14's head and legality table, 10128 to 10173;
  §14.5's `t0` bullet, 10636 to 10645; §14.8's seam paragraph, 10902 to
  10911, and "Scratch stores", 10989 to 11058; §14.10's pure-query
  paragraph, 11405 to 11420; Appendix B's `Model` and `Simulation` rows,
  11834 to 11862, and the services, 11942 to 12008; Appendix C's
  `CheckpointMismatch`, `CheckpointMidFrame` and `ArgumentInvalid` rows,
  12443 to 12482; the glossary entries `Model` 13111 and `checkpoint`
  13375. Never read the spec whole.
- `docs/design/tools/spec_style.md` and `decisions_style.md` whole, stage 0
  only.
- `docs/design/implementation.md`: the head of "What is real here" (11 to
  41); the rows `### src/Redstone.jl` (43 to 50), `### src/checkpoint.jl`
  (228 to 252), `### src/diagnostics.jl` (444 to 484), `### src/frame.jl`
  (516 to 530), `### src/linearize.jl` (556 to 589), `### src/model.jl` (591
  to 635), `### src/sim.jl` (723 to 792), `### src/trace.jl` (820 to 849),
  `### src/trim.jl` (862 to 879), `### test/imports.jl` (902 to 906), `###
  test/utils.jl` (908 to 926); "Authoring caveats" whole (933 to 1067), the
  mutant caveat last of all; "Naming" (1069 to 1148); "Running the suite"
  (1150 to 1223). Never restate either in a commit or a comment.
- `src/model.jl` 1 to 7, 8 to 70 (`Model`), 95 to 161 (the hooks, the gate,
  `init!`, `apply!`), 504 to 546 (the checkpoint half). `src/checkpoint.jl`
  whole (159 lines). `src/sim.jl` 86 to 145 (`Run`, `Simulation`), 253 to
  270 (the grid helpers), 319 to 345 (`lifecycle`), 426 to 458 (the gates
  and the forwarding methods), 495 to 520 (`_open_run!`), 519 to 626
  (`init!`), 628 to 725 (`checkpoint`, `_enter_checkpoint!`, `restore!`,
  the scalar fallback), 727 to 760 (`_compile_feed`), 765 to 923
  (`replay!`), 1279 to 1292 (`LoopHooks`), 1885 to 1895 (`publish!`'s
  stamp), 1995 to 2007 (`trace`, the forwarding reads). `src/trace.jl` 1 to
  62, 170 to 190, 275 to 290. `src/trim.jl` whole (661 lines).
  `src/linearize.jl` 1 to 220. `src/diagnostics.jl` 1170 to 1208, 1960 to
  2040, 2110 to 2195. `src/frame.jl` 1 to 60. `src/readers.jl` 340 to 372.
  `src/Redstone.jl` whole.
- `test/utils.jl` whole (79 lines); `test/imports.jl` whole (82 lines);
  `test/RedstoneTests.jl` whole; the test passages each stage names.

## Stage 0: the ruling and the spec

### The shape

One docs commit, written under `spec_style.md` and `decisions_style.md`
read first. Three kinds of edit: a new log entry with its annotations, the
spec sentences the code would otherwise falsify plus the Appendix B block
the roadmap owes, and the queue bullet.

**`docs/design/decisions.md`, D-319**, after D-318's body and before the
linkify marker (13699). Title: "Split the checkpoint into the `Model`'s
state and the run's cursor, and put the services on the `Model`". Position:
a headline sentence, then one bullet per ruling under "What is settled":
`ModelState{T}` and the non-parametric `Checkpoint`; `checkpoint(model)`
with its two refusals and `restore!(model, model_state; hooks)` with the
fingerprint check and no status gate; `checkpoint(sim)` as the wrap and
`restore!(sim, model_state)` as the door a standalone state takes, with
the fresh ordinals and the `CheckpointMidFrame` check; the scalar refusal
on the two bare-state methods; `trim!` and `linearize` on a
`Model{Float64}` with their simulation methods gating and composing, the
commit being each level's own `init!`, `trim!` gated on the claim and
`linearize` not; `:non_nominal` on a model at another scalar; the two
files above `sim.jl`; the grid arithmetic on the frame. Spec: §9.2, §12.6,
§14, §14.5, §14.8, §14.10, Appendix B, Appendix C. Rationale: the roadmap's
R6 and R10 reasons (a `Model{Dual}` checkpoints and restores without ever
having a cursor; the services need only the model's pair), the commit
reason above (the run opening and the header bracket the model's `init!`,
and the commit's outcome is decided only after the solve), and the fresh
ordinal reason (no trajectory to continue). Rejected, one item each: a
parametric `Checkpoint{T}` (a cursor is a nominal trajectory's); a
`getproperty` forward from `Checkpoint` to its state (hides the split the
type exists to show); `ModelState` carrying the counters (a model has no
trajectory); the simulation's `trim!` forwarding whole to the model's (the
commit would run through the model's `init!` with no run opened and no
header taken, the wedge D-318 closed); a status gate on the model's
`restore!` (the `:built` twin is its use); the carried state's boundary
ordinal continuing from its frame index (nothing published those
boundaries); a claim gate on `linearize` (a pure query reads the model as
`port` does). Annotations in the log's existing form (D-282's at 11863 is
one): D-274 (the clock-in-full bullet and the "another activation" bullet,
now the state's and the bare state's), D-282 (every service invocation
owns a scratch `Model`), D-317 (the model's door roster gains
`checkpoint`, `restore!`, `trim!` and `linearize`; the simulation's
`trim!` and `linearize` gate and compose), D-318 (the restore door is
`restore!(model, model_state; hooks)`, and `trim!` joins the doors the
claim refuses). No supersession line: every clause the entry amends stays
true of the simulation's doors.

**`docs/design/spec.md`.** Each passage keeps its claims and changes only
what the split falsifies; the claim-inventory procedure of `spec_style.md`
applies to every paragraph touched.

- §12.6, 8772 to 8790: the bold ruling becomes **`checkpoint` and
  `restore!` exist on the `Model` and on the `Simulation`, and a
  `Checkpoint` is the `Model`'s state beside the run's cursor** (D-319).
  The paragraph then says: `checkpoint(model)` returns the state alone, a
  `ModelState`, legal at `:consistent` with the clock on a grid top;
  `checkpoint(sim)` wraps it with the frame index and the boundary ordinal;
  `restore!(model, model_state)` checks the fingerprint, copies, settles
  through the hooks and writes `:consistent`; `restore!(sim, cp)` as today;
  `restore!(sim, model_state)` opens a fresh trajectory at the state's
  frame, its restored boundary ordinal 0 as boundary zero's is; a state
  taken at another scalar is refused by dispatch with `CheckpointMismatch`,
  a `Checkpoint` being nominal by type. The existing sentences on the
  mid-frame test, the fingerprint, the fresh run, the re-publication and
  the continuing ordinal stand.
- §14's table, 10155 to 10161: unchanged. After the table and before the
  `errored` sentence at 10163, one sentence: each row's service has a `Model` form, gated by the model's
  status alone, `checkpoint` and the default `linearize` at `:consistent`,
  `init!`, `restore!` and `trim!` at any status, and refused on a claimed
  model where it writes (D-318, D-319).
- §14.5, 10639 to 10641: "`trim!`'s commit" names both forms,
  `trim!(model, …)` committing through the model's `init!` and `trim!(sim,
  …)` through the simulation's.
- §14.8, 10905: the signature sentence reads `trim!(model, problem;
  baseline, t0 = 0.0, backend = LevenbergMarquardt())` on a
  `Model{Float64}`, with `trim!(sim, …)` gating on the simulation's
  lifecycle and committing through the simulation's `init!` (D-319). In
  "Scratch stores", 10989 to 10996: the fresh working store set is a
  scratch `Model` per half (D-317, D-319); the one-writer rule's "the
  simulation's authoritative stores" stands.
- §14.10, 11411 to 11416: the default operating point is `checkpoint(sim)`
  on a simulation and `checkpoint(model)` on a model, each restored into
  the scratch world with no boundary zero (D-319); `linearize(model, taps)`
  named beside `linearize(sim, taps)`.
- Appendix B: after the `Model(deployment, T)` row (11834 to 11840) and
  before the `Simulation(model; …)` row (11841), the `Model` block, one bullet: "`Model`'s own doors, for a model stepped on
  its own or used as a service's scratch (D-317, D-318, D-319)" listing
  `init!(model, condition; t0 = 0.0, hooks = NoHooks())`, `frame!(model,
  k, hooks = NoHooks()) → Bool` with `FrameHooks` as the hooks' contract
  and `NoHooks` the no-op, `port`, `state`, `modes` and `warnings`,
  `checkpoint(model) → ModelState`, `restore!(model, model_state; hooks =
  NoHooks())`, `trim!(model, problem; …)` and `linearize(model, taps; …)`,
  each writing door (`init!`, `frame!`, `restore!`, `trim!`) marked as
  refused on a claimed model as `ArgumentInvalid` `:claimed`; the closing
  sentence as settled above. The `checkpoint(sim) → Checkpoint` row (11983
  to 11989): the `Model`'s state and the run's two counters, the state as
  `checkpoint(model)` reads it. The `restore!` row (11990 to 11996): gains
  the `restore!(sim, model_state; kw…)` form with its fresh trajectory. The
  `trim!` row (11967) and the `linearize` row (11997): each names its
  `Model` form in one clause.
- Appendix C: `CheckpointMismatch` (12443 to 12461): "the scalar type (the
  recorded one vs. the simulation's)" becomes "vs. the target model's".
  `CheckpointMidFrame` (12462 to 12466): "on a simulation" becomes "on a
  simulation or a model". `ArgumentInvalid` (12474 to 12482): the call
  list gains `linearize` if absent, and the reasons sentence names
  `:non_nominal` on a `Model` at another scalar.
- The glossary: `checkpoint` (13375 to 13380) says the `Model`'s state as
  one value, `ModelState`, beside the run's two counters, read by
  `checkpoint(model)` and `checkpoint(sim)`; `Model` (13111 to 13117) gains
  "its doors are Appendix B's `Model` block". A new entry only if
  `check_glossary.jl --strict` demands one for `ModelState`; otherwise the
  `checkpoint` entry carries the name.

**`docs/design/pending.md`**, 20 to 26: the increment-two sub-bullet is
rewritten as increment 71's, stating what the code owes D-319 by stage (the
checkpoint split and the two doors, stage 1; the services on the model and
the include order, stage 2), and increment three's line stays. Stage 2
retires the stage lines.

### The battery

`linkify.jl` first, then `check_refs.jl`, `check_rows.jl`,
`check_glossary.jl --strict`, `check_bold.jl`, then `linkify.jl` again as
a no-op; `audit_fragments.jl 6730b90` over the log. A scripted edit reads
and asserts every file's matches before opening any for writing; `git
diff --stat` before committing.

### Bookkeeping

Nothing in `src/` or `test/`. The commit touches `spec.md`,
`decisions.md` and `pending.md`, and nothing else.

## Stage 1: the checkpoint split

### The shape

`src/checkpoint.jl`: `Checkpoint{T}` (28 to 53) becomes `ModelState{T}`
with its nine fields, the docstring rewritten for the model's state as one
value (the counters are the run's, carried by `Checkpoint` below) and its
`==` sentence kept; after it, `Checkpoint` with `state::ModelState{Float64}`,
`frame::Int`, `boundary::Int` and a docstring saying what it is (a nominal
model's state at a frame top beside the trajectory's two counters, the
value `checkpoint(sim)` returns and the trace header holds) and why it has
no scalar parameter. `_restore_state!(exec::Executor{T},
model_state::ModelState{T})` (55 to 70) and `_restore_stores!` (72 to 85)
take the state; `_detach` (87 to 91) gains a `ModelState` method and its
`Checkpoint` method composes it. `_check_checkpoint!` (93 to 138) moves to
`src/model.jl` typed `(diags::Vector{Diagnostic}, model::Model,
model_state::ModelState)`, its comment losing the untyped-`sim` sentence;
`_check_addresses!` (140 to 159) stays. The header comment (1 to 7) says
where the check went. Every local or parameter holding a `ModelState` is
`model_state` (`state` is a function the module sees, "Naming"); the
roster gains nothing.

`src/model.jl` 522 to 535: `_take_checkpoint(model, frame, boundary)`
becomes `checkpoint(model::Model) → ModelState` with the two refusals
settled above, in this order: the status, then `k = _frames_to(clock.t,
clock.t₀, h)`, `t_frame = _grid_time(model, k)`, `clock.t == oftype(clock.t,
t_frame)` or `CheckpointMidFrame(t = _seconds(clock.t), t_frame, frame = k)`.
Its docstring is `checkpoint(sim)`'s mechanism half (`src/sim.jl` 628 to
646) rewritten for the model. 537 to 546: `_restore_state!(model,
model_state; hooks)` loses its `_claimed_gate` line and keeps the rest;
above it, the public door `restore!(model::Model{T},
model_state::ModelState{T}; hooks::FrameHooks = NoHooks()) where {T}`:
`_claimed_gate(model, hooks, :restore!)`, `diags = Diagnostic[]`,
`_check_checkpoint!(diags, model, model_state)`, the collected throw, then
`_restore_state!(model, model_state; hooks)`. Beside it the scalar
fallback `restore!(::Model{T}, ::ModelState{S}; kw…) where {T,S}` throwing
`CheckpointMismatch(what = :scalar, expected = S, found = T)`. The file's
header comment (1 to 6) names the two doors. `_frame_slack`, `_frames_to`
and `_frame_at` move from `src/sim.jl` 255 to 267 to `src/frame.jl` after
`_grid_time` (18), comment included; `_t_end_frame` stays at 268.

`src/sim.jl`: `init!` 624 takes the header as
`Checkpoint(checkpoint(sim.model), sim.run.frame, sim.run.boundary)`;
`checkpoint(sim)` 647 to 664 keeps its gate and test and returns the same
wrap; `_enter_checkpoint!` 677 to 686 takes a `Checkpoint`, opens the run
with `cp.frame` and `cp.boundary` and calls `_restore_state!(sim.model,
cp.state; hooks = …)`; `restore!(sim, cp::Checkpoint; kw…)` 707 to 721
checks `_check_checkpoint!(diags, sim.model, cp.state)`; the new
`restore!(sim, model_state::ModelState{Float64}; kw…)` follows it, the
gate and `_check_recording` first, then the fingerprint check, then the
grid check and `_enter_checkpoint!(sim, Checkpoint(model_state, k, 1), …)`;
then `restore!(::Simulation, ::ModelState{T}; kw…) where {T}` with the
scalar refusal, replacing 723 to 725. `_compile_feed` 752 to 754 reads
`trc.header.state.t₀` and `trc.header.frame`; `replay!` 892 and 896 read
`trc.header.state.t₀` and `trc.header.state.deployment.h`, 911 builds
`Checkpoint(checkpoint(sim.model), sim.run.frame, sim.run.boundary)`, 916
reads `cp.frame`. The `restore!` docstring (688 to 706) gains the bare
state's paragraph. `src/trace.jl` 56 and 60: `Checkpoint`; 281 stands.
`src/linearize.jl` 133 to 164: the local `cp` becomes `operating_point`, a
`ModelState` from `checkpoint(sim)` at 133 read as `.state` for now
(stage 2 moves the call); `_restore_state!(nominal_exec, operating_point)`,
`.x`, `.t`, `.t₀` on it.

`src/diagnostics.jl`: the `:scalar` arm (2181 to 2186) reads "the
checkpoint was taken on a `Model{$(d.expected)}` and the target is a
`Model{$(d.found)}` — the scalar is a structural fact of the activation,
and a model's state goes back into a model at the scalar it was taken at
(§9.2, §12.6)". `ServiceLifecycle`'s message (1193 to 1208) gains an arm
before the final fallback, `d.legal == [:consistent]`: "`$(d.op)` on a
model whose status is `$(d.status)` — a model's state is read at
`:consistent`, after `init!` or a restore and before any throw (§12.6,
D-319)". `CheckpointMismatch`'s field comment at 2119 stands.

### Tests

- A scripted sweep over `test/`: on the receivers `cp`, `before`, `after`,
  `header` and `low_only`, `<recv>.<f>` becomes `<recv>.state.<f>` for `f`
  in `x`, `s`, `m`, `table`, `prior`, `t`, `t₀`, `deployment`, `layout`,
  and `.frame`/`.boundary` on them stand. The regex
  `\b(cp|before|after|header|low_only)\.(x|s|m|table|prior|t|t₀|deployment|layout)\b`
  hits `test_trace.jl` 82 times (the `header` receiver matches `trc.header.x`
  and `recording.header.x` too, which is wanted), `test_linearize.jl` 20,
  `test_events.jl` 1, and `dual_cp`'s two hits at `test_trace.jl` 1439 are
  excluded from the script and rewritten by hand; the script asserts the
  three counts before writing and lists every rewritten line for the
  report. `test_devices.jl` 654 and 657 read a snapshot's `frame` and are
  untouched by construction.
- `test_trace.jl` 85 and 1114: `isa Checkpoint`. 1255 to 1264: `dual_state
  = checkpoint(dual_model)` replaces `_take_checkpoint(dual_model, 0, 0)`,
  the `:scalar` assertion stands on `restore!(Simulation(…), dual_state)`
  with `expected === D8 && found === Float64`; add `restore!(Model(replay_model();
  h = 1//10), dual_state)` refused the same way with `found === Float64`.
  1436 to 1450: `dual_state = checkpoint(dual)` after `frames!(dual, 5)`,
  `isempty(dual_state.layout.events) && isempty(dual_state.prior)`,
  `restore!(twin, dual_state)` through the public door, `twin.status`
  `:built` before and `:consistent` after, the `MethodError` at 1449 stands
  on `_restore_state!(low_high.model.exec, dual_state)`.
- `test_lifecycle.jl` 191 to 194: `restore!(model, cp.state)` refused
  `:claimed` with `d.call === :restore!`.
- A new testset in `test_trace.jl` after the `Dual` twin testset's end
  (1450) and before 1452,
  "`checkpoint` and `restore!` on a model: the state alone, and a standalone
  state entering a simulation (§12.6, D-319)": a `Model(replay_model(); h =
  1//10)` at `Float64`; `checkpoint(model)` before `init!` is
  `ServiceLifecycle` with `op === :checkpoint`, `status === :built`, `legal
  == [:consistent]`; after `init!(model, <the condition recorded_run uses>)`
  and `frames!(model, 3)`, `model_state = checkpoint(model)` is a
  `ModelState{Float64}` with `t == 0.3` and `t₀ == 0.0`; a fresh
  `Simulation(replay_model(); h = 1//10)` takes it through `restore!(sim,
  model_state)`: `lifecycle(sim) === :initialized`, `mode(sim) === :live`,
  `sim.run.frame == 3`, `sim.run.boundary == 1`, `latest(sim).frame == 3`,
  `latest(sim).boundary == 0`, `latest(sim).t === 0.3`, `trace(sim).frames
  == 3`, and `state(sim, "plant") === state(model, "plant")`; `run!(sim;
  t_end = 0.6)` then matches a second simulation taken from `init!` under
  the same condition through `run!` to 0.6, `state` by `===` per component
  and `snap_cells(latest(…))` equal, as the resume-identity testset asserts
  (`test_lifecycle.jl` 712 to 730); a state from another deployment
  (`replay_model(); h = 1//20`) is `CheckpointMismatch` on `restore!(sim,
  …)` with the simulation unwritten (`assert_unwritten`, 1101 to 1108) and
  `lifecycle` unchanged; a state whose `t` is off the grid, built by
  `ModelState` with `t = 0.25` over the fields of a legal one, is
  `CheckpointMidFrame` with `frame == 2` or `3` as `round` places it,
  asserted against the value `round(Int, 0.25 / 0.1)` gives on 1.13.
- In `test_localization.jl`'s model-stepping testset (283 to 338), after
  the abandon at `t*` (314 to 322): `checkpoint(model)` is
  `CheckpointMidFrame` with `d.frame == 4`, `d.t_frame == 4 *
  deployment.h` and `d.t == model.exec.clock.t`; and on the model stepped
  ten frames under `NoHooks` (293), `checkpoint(model).t == 1.0`.
- `test_diagnostics.jl`: the occurrence list gains `ServiceLifecycle(op =
  :checkpoint, status = :built, legal = [:consistent])` beside 415; the
  rendering testset asserts the new arm's opening words on it and 995
  reads `"the checkpoint was taken on a \`Model{Float64}\`"`.
- `test/imports.jl`: `ModelState` joins the type list at 27; `_take_checkpoint`
  leaves line 50; `_restore_state!` stays. `test/utils.jl` is unchanged.

### Routing

`sim.jl` and `model.jl` are touched: all of it, under the flags, in the
foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/checkpoint.jl`: `ModelState{T}`
  and the non-parametric `Checkpoint` as the two constructs, `_restore_state!`
  on an executor taking the state, `_detach`'s two methods, the fingerprint
  check now model.jl's. `### src/model.jl`: `checkpoint(model)` with its two
  refusals and `restore!(model, model_state; hooks)` with the fingerprint
  check over the inner `_restore_state!`, the scalar fallback,
  `_check_checkpoint!`. `### src/sim.jl`: `checkpoint(sim)` as the wrap,
  `restore!`'s two forms and the scalar fallback on the bare state,
  `_enter_checkpoint!` over a `Checkpoint`; the grid helpers gone to
  frame.jl. `### src/frame.jl`: the three grid helpers. `### src/trace.jl`:
  the header a `Checkpoint`. `### src/diagnostics.jl`: the `:scalar` arm
  naming a `Model`, `ServiceLifecycle`'s model arm. Constructs, not
  behaviour.
- `docs/design/pending.md`: stage 1's line retires.

## Stage 2: the services on the model

### The shape

`src/trim.jl`: `trim!` (391 to 551) becomes `trim!(model::Model{Float64},
problem::TrimProblem; baseline, t0::Real = 0.0, backend =
LevenbergMarquardt())`: `_claimed_gate(model, NoHooks(), :trim!)`, then
`solved = _solve_problem(model, problem; baseline, backend)`, then
`_verdict!(model, problem, baseline, solved…, condition -> init!(model,
condition; t0 = Float64(t0)))`. `_solve_problem` is 450 to 547 verbatim
over `model` (`build = model.deployment.build`, `_scratch(model, T)`,
`model.deployment.build` at 490), returning, for both the bypassed and the
solved form, the solution, `r`, `tol`, the status, the two counts, the
saturated list and `reader`; how those are packed is the stage's. `_verdict!`
(611 to 661) takes `model::Model` in place of `sim`, calls `commit!(override(
baseline, problem.condition(solution)))` at 625, and reads `model.exec` at
630, 639 and 640. The docstring (391 to 441) keeps every mechanism paragraph
and loses its last one (438 to 440), which goes with the simulation's
method; one sentence says the commit is the model's own `init!` and that a
claimed model refuses the call. The misuse fallback (553 to 555) reads
`trim!(::Model, other; kw…)`; the `:non_nominal` method as settled, placed
after it. `_scratch` (559 to 563) takes `model::Model`. The header comment
(1 to 19) says the simulation's method is sim.jl's.

`src/linearize.jl`: `linearize` (119 to 200) becomes `linearize(model::Model{Float64},
tap_set::Taps; about = nothing, t0 = nothing, width::Int = LINEARIZE_WIDTH)`:
`_check_linearize_call(about, t0, width)` (the two throws of 121 to 124),
then, under `about === nothing`, the status gate settled above and
`operating_point = checkpoint(model)`, else `nothing`; then
`_linearize(model, tap_set, operating_point, about, t0, width)`, which is
134 to 199 over `model` with `_scratch(model, …)`. The docstring (90 to
118) keeps its seven steps, step 1 reading "`checkpoint(model)` on a
model, `checkpoint(sim)` on a simulation", and its lifecycle sentence
goes with the simulation's method. The misuse fallback (202 to 204) reads
`linearize(::Model, other; kw…)`; the `:non_nominal` method after it. The
header comment (1 to 13) likewise.

`src/sim.jl`, after `restore!`'s scalar fallback and before `_compile_feed`'s
docstring (727): `trim!(sim::Simulation, problem::TrimProblem; baseline,
t0::Real = 0.0, backend = LevenbergMarquardt())` with the gate of
`src/trim.jl` 444 to 448 then `_solve_problem(sim.model, …)` and
`_verdict!(sim.model, …, condition -> init!(sim, condition; t0 =
Float64(t0)))`; `trim!(sim::Simulation, other; kw…) = trim!(sim.model,
other; kw…)`; `linearize(sim::Simulation, tap_set::Taps; about = nothing,
t0 = nothing, width::Int = LINEARIZE_WIDTH)` with `_check_linearize_call`
first, the gate of `src/linearize.jl` 126 to 131, `operating_point = about
=== nothing ? checkpoint(sim).state : nothing`, then `_linearize(sim.model,
…)`; `linearize(sim::Simulation, other; kw…) = linearize(sim.model, other;
kw…)`. Each carries a short docstring: the lifecycle sentence it inherited
and the one-line composition. `src/Redstone.jl` 7 to 31: the order settled
above. `src/diagnostics.jl` 1977 to 1985: the `:non_nominal` message as
settled.

The commit's bookkeeping under the simulation's `trim!` is `init!(sim)`'s
own, unchanged: `_reset_periphery!`, `_open_run!`, the model's `init!`
under `LoopHooks`, the header. A non-converged solve calls no `init!` and
leaves the simulation as it was, lifecycle included.

### Tests

- `test_trim.jl` 664 to 668: the `MethodError` becomes
  `DiagnosticError{ArgumentInvalid}` with `d.call === :trim!`, `d.reason ===
  :non_nominal` and `startswith(d.value, "Model{")`; the comment goes.
  A new testset after it, "`trim!` on a standalone model commits through
  the model's `init!` (§14.8, D-319)": `model = Model(fed(Pendulum(), :u);
  h = 1//10)`, `trim!(model, u_problem(); baseline = pend_base(), t0 = 0.25)`
  returns the report the simulation's first testset reads (125 to 131,
  `converged`, `solution.u ≈ PEND_G_L * sin(0.5)`, the box test), and
  `model.status === :consistent`, `model.exec.clock.t == 0.25`,
  `model.exec.clock.t₀ == 0.25`; the `infeasible` problem (191 to 196) on a
  fresh model leaves `model.status === :built` and `committed_residuals
  === nothing`; on a claimed model (`Simulation(model)` first) the call is
  `ArgumentInvalid` `:claimed` with `d.call === :trim!` and `lifecycle(sim)
  === :built`, so the refusal precedes every evaluation.
- `test_linearize.jl` 370 to 373: the `MethodError` becomes the `:non_nominal`
  refusal with `d.call === :linearize`. A new testset after the default-point
  testset (132), "`linearize` on a standalone model reads its own
  checkpoint (§14.10, D-319)": `model = Model(lin_pend(); h = 1//10)`;
  `linearize(model, lin_taps())` at `:built` is `ServiceLifecycle` with
  `d.op === :linearize`, `d.status === :built`, `d.legal == [:consistent]`,
  and `linearize(model, lin_taps(); about = lin_point())` is a
  `Linearization` there; after `init!(model, lin_point())`, `linearize(model,
  lin_taps())` equals the closed form as 97 to 100 assert; after
  `frames!(model, 3)` the default form equals `about = <the at-rest
  condition of 116 to 118 built off the model>, t0 = 0.3` through
  `same_linearization`, and `checkpoint(model)` before and after agree
  field by field; a model claimed by a simulation still linearizes
  directly, since the query is a read (assert the `Linearization` and
  `lifecycle(sim) === :built`).
- `test_diagnostics.jl` 622 and 625: `value = "Model{Dual}"`.
- Every other `trim!(` and `linearize(` call site stands on the
  simulation's methods: 44 in `test_trim.jl` besides the `dual` one, 38 in
  `test_linearize.jl` besides its `dual` one and the function definition,
  14 in `test_blocks.jl` and 1 in `test_trace.jl`; the stage confirms the
  counts by `rg -c` before and after.

### Routing

`sim.jl` and `Redstone.jl` are touched: all of it, under the flags, in the
foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/trim.jl`: `trim!` on a
  `Model{Float64}`, `_solve_problem`, `_verdict!` taking the commit, the
  `:non_nominal` and misuse fallbacks on a `Model`, `_scratch` over a model;
  the "takes a `Simulation`" bullet (872 to 874) goes. `### src/linearize.jl`:
  likewise with `_check_linearize_call` and `_linearize`; 567 to 569 goes.
  `### src/sim.jl`: the two services' simulation methods beside
  `checkpoint` and `restore!`. `### src/Redstone.jl`: the include order.
  `### src/diagnostics.jl`: `:non_nominal` raised on a `Model`. The routing
  table's `trim`/`linearize` row stands.
- `docs/design/pending.md`: stage 2's line retires; increment three's line
  stays. Run the battery.

## The cold review

One fresh Opus reviewer over the two code commits, the docs commit read
for what they owe: open-mind stance, probe scripts in the scratchpad,
"empty is acceptable". Dimensions:

- **D-319 against the tree.** Every Position bullet holds of the code: the
  nine fields and the three; `checkpoint(model)`'s two refusals in order;
  the public `restore!(model, …)` gating, checking and writing last; the
  bare-state door's `(k, 1)` and the ordinal 0 it publishes; the two scalar
  fallbacks; `trim!`'s claim gate before any check and `linearize`'s
  absence of one; the simulation's `trim!` committing through `init!(sim)`
  (a probe: after a converged `trim!(sim, …)`, `trace(sim).header` exists
  and `sim.run.frame == 0`); the include order loading on a cold process.
- **Bit-identity.** On a scratch copy against a `git worktree` of 6730b90
  (copy the root `Manifest.toml` in): `checkpoint → restore! → run!` and
  `replay!` on `test_trace.jl`'s `recorded_run` and `test_lifecycle.jl`'s
  `resume_pend` give identical states and snapshot ordinals; `trim!`
  reports on `test_trim.jl`'s `u_problem`, `θ_problem` and the mounted
  problems have bitwise-equal `solution`, `residuals` and
  `committed_residuals`; `linearize` on `test_linearize.jl`'s and
  `test_blocks.jl`'s taps gives bitwise-equal matrices.
- **Mutants on a scratch copy**, each named test going red: the model's
  `restore!` skipping the fingerprint check; `checkpoint(model)` not
  refusing `:built`; `checkpoint(model)` not refusing an off-grid clock;
  the bare-state door opening at boundary `k` rather than 1; the
  simulation's `trim!` committing through `init!(sim.model, …)` under
  `NoHooks`; `_verdict!` committing on a non-converged solve; the
  `:non_nominal` fallback declared without `where {T}` so it shadows the
  `Float64` method; `linearize(sim)`'s default point taken off
  `checkpoint(sim.model)` rather than `checkpoint(sim)` (`test_linearize.jl`
  196 to 197 reads the simulation's payload); the sweep's `.state.`
  dropped at one `header` site. A surviving mutant is a missing test.
- **Allocation and inference.** `test_trim.jl`'s backend-side probe (655
  to 662) still reads zero; `frame!`'s canaries in `test_localization.jl`
  and `test_stepper.jl` are untouched and pass; `@code_warntype` on
  `_linearize` shows no new `Any` beyond 6730b90's `linearize`.
- **The register and the docstrings.** Rows name constructs; `ModelState`'s,
  `Checkpoint`'s, `checkpoint(model)`'s and the two `restore!` docstrings
  say what D-319 says and no more; the moved comments cite the file they
  now live in.
- "Naming" over every touched file, the docs battery, and the gate once on
  the real tree, on the Julia floor `Project.toml` declares.

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
