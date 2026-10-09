# Notes: increment 71, the checkpoint split and the services on the `Model`

Rulings and acceptances made while the user was away, each with its reason,
and the open points the stages surfaced. Brief:
`brief_increment_71_model_split_2.md`, launched 2026-10-09 at a7b0fe1.

## Stage 0 (79cc401): accepted deviations

1. §12.6's counters sentence gained one sentence: the bare-state door sets
   frame `k` and ordinal 0, as `init!` does. The old sentence ("`restore!`
   and `replay!` set the counters to the checkpoint's") was false of a
   `ModelState`, which carries none.
2. Appendix C's `CheckpointMismatch` row says "simulation or model", since
   the model's `restore!` raises it now.
3. Appendix C's `CheckpointMidFrame` row scopes "abandoned unpublished" to a
   simulation and says `restore!` raises the kind for an off-grid
   `ModelState`.
4. §14's sentence after the legality table is four sentences, one burden
   each; `linearize` with an explicit `about` is listed at any status, which
   is what the brief's `about === nothing` gate implies.
5. Appendix C's `ArgumentInvalid` row gained a `:non_nominal` sentence,
   since no reasons sentence existed to amend.
6. D-317's annotation adds that `checkpoint` on the model carries a status
   gate the default `linearize` inherits; D-317's own "no model door carries
   a gate" would otherwise read as still true.
7. §12.6's dispatch sentence drops "as a trace is": a trace has carried no
   scalar since D-317.

The brief counted seven "(this brief)" points and flagged six; the
Appendix B correction sits in D-319's Rationale, the other five in its
Position. No substance lost.

## Open points for the user

Stale sentences stage 0 left alone as out of scope:

- Appendix C's `ArgumentInvalid` call list does not name `init!`, `frame!`,
  `apply!` or `restore!`, all of which raise `:claimed` since D-318.
- §9.6's sketch says "the simulation's stores" and "trace header", true only
  of the simulation form of the services.
- The glossary's `service lifecycle` entry names only simulation states.
- The gloss "(the executor's state at a frame top, as one value)" in §12.6,
  §14, §14.8 and §14.10 is looser than the glossary's `checkpoint` entry now.
  Candidate for increment 72's vocabulary sweep.
- D-319's include-order and grid-helper bullets are arguably implementation
  policy under `decisions_style.md` rule 9; they stand because the brief
  asked for them.

## Stage 1 (b1de9d4): accepted deviations

Gate 5983 of 5983 against 5943, the 40 new assertions in `trace` (33),
`localization` (3) and `diagnostics` (4).

1. The brief's clock literals `t == 0.3` and `latest(sim).t === 0.3` are
   not bitwise frame tops; the test asserts `model_state.t === 0.0 + 3 * 0.1`
   and `latest(sim).t === model_state.t`, as `implementation.md` asks.
2. The other-deployment and off-grid refusals run on the same simulation
   after its `run!` to 0.6, so `assert_unwritten` and the unchanged
   lifecycle are checked against a `:stopped` one. The off-grid frame is
   `round(Int, 0.25 / 0.1) == 2` on 1.13 (round to even).
3. Two assertions added: `restore!` on a `:built` model with a state from
   another deployment is `CheckpointMismatch` and the model stays `:built`.
   Without them the reviewer's "skip the fingerprint check" mutant survives.
4. `test_diagnostics.jl`'s `:scalar` rendering assertion follows the new
   message ("the target is a `Model{`"), the old phrase being gone.
5. Three `Checkpoint{Float64}` sites the brief's count missed (a
   `test_trace.jl` comment, two `sim.jl` signatures, one `sim.jl`
   docstring) were rewritten with the four it listed.

## Open points for the user, from stage 1

- **`CheckpointMidFrame`'s message on the bare-state door.** The message
  opens "`checkpoint` with the clock inside frame k and short of its top".
  `restore!(sim, model_state)` computes `k` by `round`, so a state's `t`
  can lie past `t_frame`; for `t = 0.25` it renders "inside frame 2 and
  short of its top at t = 0.2", which is false. D-319 rules `frame = k` by
  `round`, so stage 1 left the message alone. Routed to the reviewer;
  the fix is either a message arm for the door or `floor` in place of
  `round`, the latter a change to D-319.
- `src/stepper.jl` 36 and 45: `restore_stepper!`'s parameter `cp` now
  receives a `ModelState`; "Naming" asks for `model_state`. Routed to the
  reviewer and the fixer.
- `src/deployment.jl` 8: the comment names `Checkpoint.deployment`, now
  `ModelState.deployment`. Routed likewise.
- `replay!(…; restore = false)` now reads `checkpoint(sim.model)`, so an
  `:initialized` simulation with an off-grid clock would raise
  `CheckpointMidFrame` there before any write; stage 1 knows no path that
  reaches that state. The reviewer probes it.

## Stage 2 (70cf84a): accepted deviations

Gate 6010 of 6010 against 5983, the 27 new assertions in `trim` (13) and
`linearize` (14). Cold load proved; five methods per service.

1. The standalone `linearize` testset uses `t0 = before.t`, the bitwise
   grid time after three frames, not the brief's `0.3`, which is not a
   frame top. Same reason as stage 1's first deviation.
2. The claimed-model `trim!` refusal is also asserted on the `infeasible`
   problem, which proves the claim gate precedes the solve: with
   `u_problem` alone, a gate moved after the solve would still be refused
   by the model's `init!`. The infeasible problem is a local copy of five
   lines, the no-convergence testset untouched.
3. `_solve_problem` packs its result as one NamedTuple,
   `(; solution, r, tol, status, n_evaluations, n_iterations, saturated,
   reader)`, bound as `solved` at both call sites; `_verdict!(model,
   problem, baseline, solved, commit!)` unpacks it. The brief left the
   packing to the stage.

## Open points for the user, from stage 2

- `implementation.md`'s `src/model.jl` row says "`frame!` (frame.jl) is
  the fourth gated door"; `trim!` is now claim-gated too. Routed to the
  reviewer and the fixer.
- The authoring caveat's "the two `string(typeof(...))` left in `trim.jl`"
  counts one in `trim.jl` and one in `linearize.jl`; the new `"Model{$T}"`
  values also render a type as a string. Routed likewise.

## The cold review

Bit-identity against 6730b90 held on forty probes (checkpoint, restore,
replay, every `trim!` and `linearize` fixture), the gate 6010 of 6010, the
battery clean, and the brief's nine mutants plus ten of the reviewer's own
all killed. Three defects, four surviving mutants of the reviewer's, nits.
Probe scripts are in this session's scratchpad under `review/`.

### Rulings made in the user's absence

1. **The bare-state door's frame arithmetic.** `restore!(sim, model_state)`
   took `k = round(Int, (t - t₀) / h)`, so an off-grid `t` could lie past
   `t_frame` and the `CheckpointMidFrame` message ("inside frame k and short
   of its top") was false; a `t` before `t₀` was accepted into frame −1.
   Ruled: `k = _frames_to(t, t₀, h)`, the arithmetic `checkpoint(model)`
   uses; same `k` on the grid, the frame the clock sits inside off it, and
   frame 0 for a `t` before `t₀`, which the exact check then refuses.
   D-319's bullet is corrected in place in its own docs commit, since the
   entry is this unpushed increment's and the clause was found false the
   day it landed. **If the user prefers an annotation or a D-320 under
   `decisions_style.md` rule 1, it is a one-bullet change before the push.**
2. **The `CheckpointMidFrame` message named `checkpoint` for both callers**
   and advised stopping the run, wrong for a restore. Ruled: the message is
   reworded so every sentence holds for `checkpoint` on a run or a model
   and for `restore!` on a bare state; the payload is unchanged. The
   reviewer's alternative, an `op` field on the payload, changes Appendix
   C's row and is the user's option.
3. Four tests added for the reviewer's surviving mutants: the bare-state
   door's recording check and lifecycle gate, the model's `restore!`
   forwarding `hooks`, and `checkpoint(model)` refusing `:inconsistent`.
4. Nits landed: `lifecycle_state` in the moved simulation methods, the
   model arm of `ServiceLifecycle` rendering `:status`, `restore_stepper!`'s
   parameter and docstring, `deployment.jl`'s comment, the `model.jl` row's
   gated-door sentence, the authoring caveat's `string(typeof)` count, and
   the queue bullet's "owes D-317 the other two".

### Open points for the user, from the review

- **Should the model's `restore!` share the grid check?** It checks only
  the fingerprint, as D-319 rules; a hand-built `ModelState` at `t = 0.25`
  restores into a twin, `:consistent`, clock off the grid, and a later
  `frame!` integrates from there. Only a hand-built state reaches it.
- **Should `restore!(sim, cp::Checkpoint)` check the grid?** It never has;
  a hand-built `Checkpoint` at `t = 0.25` with frame 2 restores, and a
  following `replay!(…; restore = false)` now raises `CheckpointMidFrame`
  at frame 3 through `checkpoint(sim.model)` before any write, where the
  old code went on silently. Predates the increment; no regression.
- `trim!(claimed_model, <not a problem>)` answers `:not_a_problem` rather
  than `:claimed`, correct as built: a claim gate on the misuse method
  would make `trim!(sim, other)` answer `:claimed` wrongly.
- Warm allocation: `trim!(sim)` costs 176 B more per call than at 6730b90,
  the commit closure and the packed solve tuple, off every hot path.
  `checkpoint`, `linearize` and `frame!` are unchanged.

## The fix and its verification

- 0e60f6a: D-319's bare-state bullet corrected in place, the queue clause
  reworded. Battery green.
- dfeaaec: "Fix increment 71's review findings", everything under
  "Rulings made in the user's absence". The off-grid refusals are one loop
  over `(0.25, 3)`, `(0.34, 4)` and `(-0.1, 0)`; the recording-check test
  asserts through `only(diagnostics(failure(…)))`, since `_check_recording`
  throws a collected `DiagnosticError`.
- 5b14a14: `CheckpointMidFrame`'s docstring names its three raisers.
- The reviewer verified every item on the delta, re-ran the four mutants
  (red at `test_trace.jl` 1458 and 1182, `test_localization.jl` 308,
  `test_failures.jl` 193), re-ran bit-identity against 6730b90 (byte-
  identical), and ran the gate on 5b14a14: 6037 of 6037.

### Wording nits left for the user

- For a state before its origin the message says "inside frame 0 and short
  of its top at t = 0.0"; frame 0 has no interior.
- "a checkpoint is the state at a published frame top" fits a standalone
  model loosely, since it publishes nothing; the clause after it is true.
- A hand-typed `t = 0.3` is refused against the indexed top
  `0.30000000000000004`, one ulp away. True, not a regression, puzzling.
- `checkpoint(sim)`'s local is still `status` where the file's name is
  `lifecycle_state`; it predates the increment.

## Not pushed

Seven commits on a7b0fe1 (itself unpushed with bd2d7ae): 79cc401, b1de9d4,
70cf84a, 0e60f6a, dfeaaec, 5b14a14 and the notes commit. The user
diff-verifies the arc, rules on the open points, and pushes.
