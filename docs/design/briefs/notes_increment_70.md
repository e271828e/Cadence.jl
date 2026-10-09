# Notes: increment 70, the run of 2026-10-09

The coordinator's rulings, each with its reason, and the open points left
for the user. Nothing here is pushed.

## The arc

| commit | what |
| --- | --- |
| 9a4c6ae | the brief |
| 7317a7e | stage 0: D-317, the spec amendments, the pending bullet |
| 631bd4d | stage 1: `Model{T,E}`, `Simulation` as four fields, the forwarding doors |
| 23460d7 | stage 2: the counters on the run, the derived lifecycle |
| 697ff66 | stage 3: `FrameHooks`, `frame!` on the model with the catch, the model's `init!` and cell, `LoopHooks` |
| 29c3f5b | stage 4: `Simulation(model::Model{Float64})`, `Run`, `Trace`, `TerminationRecord` without `T`, the `Dual` fixtures as models |
| 22cc4db | the review fixes, F2 to F5 |

Gate on the real tree at 29c3f5b: 5888 of 5888 on Julia 1.13.1, and at
22cc4db: 5902 of 5902. The
review's bit-identity against 49592cc held on every fixture and door,
replay included; `frame!` allocates nothing beyond the `Snapshot` under
`LoopHooks` and nothing under `NoHooks`; `LoopHooks` is stack-allocated;
`frame!` infers `Bool` under both hooks.

## Rulings made

1. **Stage 0's supersedes line names D-255, D-260 and D-261 beside the
   three the brief listed, without annotations.** Each has a clause D-317
   falsifies (the lifecycle on `Control`; the four-field `Run`; the `t*`
   hit typed as a face or `nothing`, and `chunk_size` on the `Simulation`
   constructor). The log's practice for partial supersession has no
   annotation (D-260 superseded D-255's bullets and D-255 got none), so
   only the three the brief named carry one.
2. **Stage 0's extra spec sentences stand.** The brief's rule was "only
   the sentences the code would otherwise falsify", and a grep for
   `Simulation{`, `Run{`, "clock in full", "lifecycle state" and
   "materializ" found claims outside the brief's list that the same rule
   reaches (§9.4's owner bullet, §11.8's writer roster, §12.4's
   `join_timeout`, Appendix B's `algorithm` row, Appendix C's keyword
   rows, four glossary entries).
3. **The spec spells the type `Model` and says "the executor's clock".**
   Keeps the type apart from the lowercase "model" that still means the
   component tree until increment three sweeps it.
4. **§13.4's boundary-zero paragraph says the throw writes the `Model`'s
   status back to `:built`**, which the derived lifecycle reads as
   `built`, rather than the brief's "the simulation's `init!` moves the
   lifecycle". That is stage 3's design; the brief's phrasing predates
   the derived lifecycle.
5. **The model's diagnostic cell is `frame_diag::DiagCell`.** The brief
   wrote `diag`; "Naming" says `diag` in the singular never joins the
   roster (it shadows `LinearAlgebra.diag`). The plane's cells are
   `loop_diag` and `harness_diag`, and the model's is the frame's.

6. **Stage 1's deviations stand.** The three boundary routines and
   `event_phase!` take the plane's loop cell as an explicit `loop_diag`
   argument until stage 3 gives the model its own cell; `_check_finite!`
   and `_nonfinite` moved onto the model with `integrate!`; `_set_clock!`
   keeps taking an `Executor`, since only scratch executors reach it;
   `Model{T,E}` carries no `E<:Executor{T}` bound, as the brief spelled
   it; `join_timeout` is validated after the model compiles, since the
   check lives on `Simulation(model; …)` and nothing is retained.

7. **`_nonfinite` derives its payload's `boundary` from the clock's grid
   position** (`_frames_to(t, t₀, h) - 1`), since stage 1 put it under the
   model door `integrate!` and the model never sees the run.
   `_frames_to` rounds up with a four-ulp slack, so inside a frame the
   value equals the old `clock.frame - 1` for every segment end beyond
   that slack above `tₖ₋₁`. The alternative, threading `k - 1` down
   through `integrate!`, would widen a door's signature for a cause
   payload's one field. The reviewer checks the existing payload
   assertions.
8. **Stage 2's other deviations stand.** `restore!` writes `:consistent`
   only through `_enter_checkpoint!`; `lifecycle(sim)` acquire-loads the
   flag and the status and reads `closed(run)` plain, ordered by the
   releasing `running = false`; the two gates in `control.jl` take an
   untyped `sim` since `control` is included before `sim`; the `Run`
   field-names assertion in `test_lifecycle.jl` reads the six-tuple; four
   `sim.jl` docstrings and one in `trace.jl` name the run's counter. The
   brief's "testset at 571 to 584" for the errored `init!` refusal is in
   `test_lifecycle.jl`'s §13.6 testset, not `test_failures.jl`.

9. **The loop's `:errored` arms no longer write the model's status.**
   D-317 says only the model's doors and catch sites write it, and a
   frame throw reaches `_run_body!`'s and `step!`'s arms already marked
   `:inconsistent` by `frame!`'s catch. A throw outside the frame (the
   pacer, a yield, the tail) therefore ends as `:stopped` with a
   `LoopError` record rather than `:errored`, which is right: the model
   sits at a settled boundary and is consistent; the run, not the model,
   failed. No test exercises that path. Flagged below.
10. **The frame canaries assert publication's bytes under `LoopHooks`
    and zero under `NoHooks`.** The brief had the `== 0` assertion
    standing, but `frame!` now carries the frame top's publication
    through `settled!`, and a `Snapshot` allocates (800 to 944 bytes per
    publish). The quiet frame equals one publication and the localizing
    frames two; the `NoHooks` arms carry the zero-allocation claim for
    the frame itself, and the `LoopHooks` arms show the hooks add nothing
    beyond publication.
11. **Stage 3's other deviations stand.** The hook types and `LoopHooks`
    live in `sim.jl` and the model's `init!` in `conditions.jl`, by the
    include order; `_replay_drain!` reads `run.frame` without `+ 1` since
    the index now advances before the top hook drains; `frame!` writes no
    explicit `:integrate` phase since `integrate!` does; the catch builds
    the `StepError` before writing `:inconsistent` so an interrupt during
    classification writes nothing; the model's `init!` calls `settled!`
    outside the boundary-zero `try` as `publish!` sat today;
    `DiagCell`'s and `MalformedDatum`'s docstrings name the model's cell.
12. **Two `executor.jl` docstrings the increment made false go into
    stage 4's commit** (`_phase!`'s "written by the loop",
    `ExecutionCursor`'s "`frame!`'s return value").

13. **The `:non_nominal` refusal methods are deleted, not kept.** Once
    `trim!` and `linearize` take `::Simulation`, a refusal method with
    the same signature would overwrite them and precompilation refuses
    the overwrite. The reason and its message stay in `diagnostics.jl`
    with no raiser; increment two raises them on the model.
14. **Stage 4's other deviations stand.** `_scratch(sim, T)` returns a
    `Model` and its three-argument form is gone; `_fingerprint` takes
    the model; `test_readers.jl`'s `world` helper takes a model with a
    forwarding method; stage 1's duplicate `Model(deployment, D8)` line
    in `test_discrete.jl` is removed; `ramp` in `test_trace.jl` loses
    its `T` keyword. The brief's count of 44 included three
    `for T in (Float64, D8)` loops in `test_readers.jl` it did not list;
    they moved as `Model`s at both scalars.

15. **The review's F2 to F5 go to the fixer; F1 is the user's.** F2:
    `_restore_state!` gains a `Model` method that writes `:consistent`,
    and `_enter_checkpoint!` drops its own write, so the status writers
    are the model's doors as D-317 says. F3: `_nonfinite`'s `boundary`
    rounds to the grid (`round(Int, (t - t₀) / h) - 1`), since a
    `Float32` model's `t` carries rounding beyond `_frames_to`'s slack.
    F4 and F5: the surviving mutants (the `:drain` write after the top
    hook; the replay drain's fold alone; a frame-top abandon) get tests.
    The fixer's `_restore_state!(model, cp)` takes an untyped `model`,
    since `checkpoint.jl` is included before `sim.jl`, and runs first in
    `_enter_checkpoint!`, so `:consistent` lands before the run opens.

## Open points for the user

- Two docstring sentences in `src/deployment.jl` (289 at 49592cc,
  "`Simulation` materializes it") and `src/build.jl` (1381, "a
  `Simulation` owns its nominal executor") are loose but true through the
  model; increment three's sweep.
- **F1, the user's ruling.** `Simulation(model)` accepts a model at any
  status, and `lifecycle(sim)` reads the model's status as if only this
  simulation's doors wrote it. A model that went through `init!` on its
  own, or one shared by two simulations, makes a simulation read
  `:initialized` with no snapshot; `run!` then throws from `_record` in
  `_run_body!`'s `finally` and the running flag never clears, so the
  simulation is wedged at `:running`. Unreachable at 49592cc, where every
  simulation compiled its own executor.
- Ruling 9: a loop throw outside the frame now reads `:stopped` with a
  `LoopError` record, not `:errored`. Nothing tests it; if `:errored` is
  wanted there, the arm writes `:inconsistent` back and D-317's writer
  roster gains the loop.
- The `:scalar` `CheckpointMismatch` message in `diagnostics.jl` still
  says "taken on a `Simulation{…}`"; a `Dual` checkpoint is now taken on
  a `Model`, and `test_diagnostics.jl` asserts the current text.
  Increment two, with the checkpoint split.
- The increment-two sub-bullet in `pending.md` still says "with their
  `Dual` scratch a `Model`", which `_scratch` already does.
- Appendix C still says "the two convenience forms" where R11 now has
  three sugar forms (`Simulation(deployment; kw…)` joins `build` and
  `root`). A one-line docs fix, or increment three's sweep.
- The `ReplayHeaderMismatch` payload row in Appendix C still says "the
  simulation's clock (the `t₀` or the frame)"; the frame is the run's.
- §13.4 still says "the catch site discriminates" the interrupt; there are
  now two catch sites. Not false.
- Seven `Model` word hits in the spec and the log were left for increment
  three: spec 5935 (§10.6, "Model semantics", the modelled system) and
  11986 (Appendix B, "Model state") name the tree; the other five are
  FlightCore's or Flight.jl's `Model` in log text and in §11.1 and §14.9.
