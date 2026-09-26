# Brief: pause, the operator interrupt and the interactive disposition (D-268)

Tip at launch: `73fc5ce`. Two stages, one cold review, one fixer. Retires
`pending.md`'s first bullet, "§12 beyond its built slices". Pacing, `margin`
and the pacer wait are the next bullet and stay out.

Design and code are peers, neither subservient. The spec's shape landed
docs-first in `73fc5ce` (D-268); this increment conforms the code to it. If
the spec's shape proves wrong at the keyboard, stop and report rather than
deviate silently.

## What the spec now says

Read these by line range at `73fc5ce`, not whole sections:

- §12.1, `spec.md` 6983–7042: the control plane; the stop word and its
  issuer; the pause paragraphs at 7022–7040 (the verbs, the frame-top
  consultation, `step!` blocking, the tail clearing the flag, no pause on
  the handle).
- §12.4, the tail, 7203–7260: steps (1)–(7) and the one-line summary. Step
  (2), "a stop issued while paused therefore works", and step (5), the join.
- §12.4, the bracket, 7345–7445: the sketch at 7351–7364 with its
  `InterruptException` arm, and the rule at 7435–7445.
- §12.4, the operator interrupt, 7446–7512: masking is normative; the unmask
  points are the frame top and the pause block; the face-first rule at
  7483–7489; the masked bookkeeping at 7491–7498; the second interrupt
  collapsing the joins at 7500–7506.
- §13.4, 8350–8520: the catch site; "the one exception never wrapped" at
  8466–8474; the disposition at 8476–8484, with the roster as `run!`'s
  discriminator and `step!` always rethrowing.
- §13.5's consultation order, 8571–8574, which the face-first rule applies.
- §13.6, 8675–8735: the abnormal entry the disposition change reports
  rather than rethrows.
- D-268 in `decisions.md`: the five rulings, their rationale and the probe
  that confirmed the masking mechanism.
- `implementation.md`: rows 29 (`sim.jl`), 33 (`dataplane.jl`), 37
  (`devices.jl`); the authoring caveats at 63–124 in full; the "Naming"
  section and "Running the suite", both cited below and never restated.
- `pending.md`, the first bullet under "Not yet built", 20–25.

The four spellings: `pause!(sim)`, `resume!(sim)`, `paused(sim)`,
`stop!(sim)`. The handle keeps `running` and `stop!` alone.

## What exists

- `Control` (`devices.jl` 65–74): `stop_issuer`, `stopped`, `wake`,
  `counter`, `lifecycle`, `join_timeout`. No pause field.
- `_request_stop!` (79–80): a bare compare-and-swap. It notifies nobody, so
  a paused loop would never observe a stop.
- `_advance!` (`sim.jl` 1209–1253, its comment 1193–1208): the frame loop
  with the normative consultation order at its top and the defensive
  `InterruptException` branch in its catch (1241–1249), which today
  abandons the frame unpublished.
- `_run_body!` (1107–1176): the run's shape; its outer catch turns every
  throw into `LoopError`, `InterruptException` included, and rethrows.
- `_init_devices!` (`devices.jl` 378–395, docstring 364–377): the bracket;
  its catch reports every throw as `DeviceCrash`.
- `_finish!` (411–421, comment 406–410) and `_tail!` (436–469, docstring
  423–435): tail steps (1)–(5).
- `_wrap` (337–359): already discriminates the interrupt (D-132).
- `run!` (1055–1069, docstring 1010–1054) rethrows whatever `_run_body!`
  throws.
- `step!` (1369–1418): shares `_advance!`; its own tail and bookkeeping.

Verified at the tip, in scratchpad scripts under `Base.exit_on_sigint(false)`
with `kill(getpid(), SIGINT)`:

- `Base.disable_sigint(f)` is `sigatomic_begin(); res = f(); sigatomic_end();
  res` with no `try`: on a throw, the unwinder restores the counter to what
  the enclosing `try` saved. Read it in `Base` `c.jl`, near line 165.
- A signal sent inside the mask is held through a `sleep` and raised as
  `InterruptException` at `sigatomic_end`. Nothing lingers afterwards.
- A signal during `wait` on a `Threads.Condition` raises inside the wait,
  the lock re-taken and then released on the way out.
- **A frame that throws with a signal pending** loses the frame's own error
  under both naive shapes. With the mask begun outside a `try`, the catch's
  restore raises the interrupt at the catch's entry and it escapes the
  catch. With `sigatomic_end` in a `finally`, its raise replaces the model
  error. Either way the run would end `stopped` over a half-written
  boundary, which §12.4's guarantee forbids. The shape below is the one
  that works: the `try` sits inside the mask, the catch unmasks under its
  own `try` that swallows an `InterruptException`, and the model error then
  propagates with nothing pending.

## Scope

Stage 1, the pause:

- `src/devices.jl`: `Control` gains `@atomic paused::Bool`, `false` at
  construction; `_request_stop!` notifies `wake` after its CAS; a new
  helper `wait_resume!(control)` blocks while paused and no stop is
  pending; `_finish!` clears `paused` beside `stopped`.
- `src/sim.jl`: `pause!(sim)`, `resume!(sim)`, `paused(sim)` beside
  `stop!(sim)`; `_advance!` calls `wait_resume!` at the frame top before the
  stop-word read.
- `test/imports.jl`, `test/test_devices.jl` or `test/test_lifecycle.jl`.
- Docstrings and comments named under "Prose to correct".

Stage 2, the interrupt and the disposition:

- `src/sim.jl`: the mask across the frame body in `_advance!`; the catch's
  interrupt arm consulting the frame's face first; `_run_body!`'s outer
  catch discriminating the interrupt; the masked bookkeeping in
  `_run_body!`'s and `step!`'s `finally`; `run!`'s roster discrimination.
- `src/devices.jl`: the bracket's interrupt arm in `_init_devices!`; the
  tail's collapse in `_tail!`.
- `test/fixtures.jl`, `test/test_failures.jl`, `test/test_devices.jl`,
  `test/test_lifecycle.jl` (one testset changes).
- `implementation.md` rows and `pending.md`.

Out: pace, `margin`, the pacer wait and its debt (§10.7, the next bullet);
a pause on the handle; any `FrameworkStatus` field for the pause; the
`replay!` disposition, which stays the rethrow (§13.4 names `run!`; flagged
for the reviewer, not a change); `ThreadBudget` and the rest of the §11.8
remainder.

## Shapes

### Stage 1

```julia
mutable struct Control
    @atomic stop_issuer::Union{Nothing,Symbol,String}
    @atomic stopped::Bool
    @atomic paused::Bool
    wake::Threads.Condition
    counter::Int
    @atomic lifecycle::Symbol
    join_timeout::Float64
end
```

The stop word's write path wakes the pause: after the CAS, `lock(wake);
notify(wake); unlock(wake)`, from any task. `_request_stop!` is called from
device tasks, the wrapper's catch, the bracket and `stop!(sim)`; none holds
the lock, so no re-entrancy arises.

```julia
# The pause block (§12.1): the loop parks here at frame top while the flag is
# set and no stop is pending. An unmask point (§12.4): an interrupt delivered
# inside the wait raises out of it, the lock released.
function wait_resume!(control::Control)
    (@atomic control.paused) || return nothing
    lock(control.wake)
    try
        while (@atomic control.paused) && (@atomic control.stop_issuer) === nothing
            wait(control.wake)
        end
    finally
        unlock(control.wake)
    end
    nothing
end

pause!(sim::Simulation) = (@atomic sim.control.paused = true; nothing)
function resume!(sim::Simulation)
    control = sim.control
    @atomic control.paused = false
    lock(control.wake); try notify(control.wake) finally unlock(control.wake) end
    nothing
end
paused(sim::Simulation) = @atomic sim.control.paused
```

The frame top's order becomes: `wait_resume!`, then the stop word, `t_end`,
the budget, the yield, the drain. A stop issued while paused therefore ends
the run at that frame top with no further frame, the source `:code` or the
device's name. `_finish!` adds `@atomic control.paused = false` before the
notify: the tail clears the flag (§12.1's rule), and no run start does.
`step!` shares `_advance!` and blocks the same way; nothing else changes
there.

### Stage 2

The mask. `disable_sigint` takes a closure, and a closure that assigns the
frame count or the face boxes them, an allocation per frame. Call
`Base.sigatomic_begin()` and `Base.sigatomic_end()` directly, the count and
the face inside the mask, and the frame's `try` inside the mask too:

```julia
# the frame loop's body, per iteration
wait_resume!(control)                           # the pause block: an unmask point (§12.4)
issuer = @atomic control.stop_issuer
issuer === nothing || return (ControlRequestedStop(issuer), advanced)
…                                               # t_end, the budget, the yield
entry_boundary = sim.exec.clock.step
Base.sigatomic_begin()                          # §12.4: masked across the boundary sequence
try
    drain!(sim)
    …                                           # the frame, the boundary, the publication
    face = …
    advanced += 1
catch err
    # The frame failed, so its throw is the disposition and a pending
    # interrupt is moot: consumed here, never raised past this catch.
    unmask_quietly()
    if err isa InterruptException               # §13.4's defensive branch: a synchronous
        _request_stop!(control, :interrupt)     # throw from model code, the frame abandoned
        return (ControlRequestedStop(something(@atomic control.stop_issuer)), advanced)
    end
    rethrow(_wrap_step(sim, entry_boundary, err))
end
try
    Base.sigatomic_end()                        # the frame-top unmask: a deferred raise lands here
catch err
    err isa InterruptException || rethrow()
    face === nothing || return (ModelRequestedStop(face), advanced)   # D-268: the face was consulted first
    _request_stop!(control, :interrupt)
    return (ControlRequestedStop(something(@atomic control.stop_issuer)), advanced)
end
face === nothing || return (ModelRequestedStop(face), advanced)
```

`unmask_quietly()` is `try Base.sigatomic_end() catch err; err isa
InterruptException || rethrow() end`, a helper in `devices.jl` beside the
control surface, named under the "Naming" section's helper rule. The
`wait_resume!` call and the `yield` are unmasked, so a raise there is
caught the same way as the unmask's, with `face` necessarily `nothing`;
wrap the frame top's three unmasked calls in one small `try` with that
arm rather than a second copy of it. The outer `try` around the whole
`while` goes: every arm now sits at its own point, and `_wrap_step` stays
the one constructor.

A deferred raise fires at the unmask after `advanced += 1` and after the
face was read, so the published frame counts and a holding face wins. A
synchronous `throw(InterruptException())` from model code is not a signal:
the mask does not defer it, it takes the catch's defensive arm, skips the
count, and the two existing carve-out tests in `test_failures.jl` (288–318)
keep exercising exactly that arm unchanged. `face` is `nothing` on every
iteration that reaches the frame body, since a holding face returns.

**The corner this settles**, stated as the assumption the code builds on: a
frame that throws while an interrupt is pending ends `errored` under the
frame's own `StepError`, and the interrupt is consumed. The alternative,
`stopped` over a half-written boundary, is what §12.4's masking exists to
prevent. The spec does not state the corner; the reviewer flags it and the
increment's closing docs commit adds the sentence.

The bracket's arm, mirroring `_wrap`'s:

```julia
catch err
    _shutdown!(entry)
    if err isa InterruptException
        _request_stop!(entry.handle.control, :interrupt)   # the operator's stop (§12.4, D-268)
    else
        report_cell!(_handle(entry).diag_cell, DeviceCrash(err, entry.should_abort))
        entry.should_abort && stop!(entry.handle)
    end
    false
end
```

The tail's collapse. Any `InterruptException` reaching `_tail!`, in the
`unblock!` loop or in the join loop, abandons the remaining joins at once:
every entry whose task is not done is reported by name under
`DeviceJoinTimeout`, exactly as the cap's path reports it, and `_tail!`
returns. The `unblock!` loop's `catch err` must let the interrupt through to
that arm rather than warn and continue. Nothing propagates out of `_tail!`.

The outer catch of `_run_body!` discriminates the interrupt too: a raise
that reaches it, from the microseconds between the loop's return and the
tail, is a stop, not a `LoopError`. It sets `:interrupt` through the stop
word, takes `ControlRequestedStop` of the word's issuer as `source`, and
does not rethrow. The inner `finally` has already run the tail. Neither the
`TaskFailedException` arm nor `step!`'s catch needs this: the spawned loop
returns the interrupt as its source, and `step!` reaches `_advance!` alone.

The masked bookkeeping: the whole body of `_run_body!`'s outermost
`finally` and of `step!`'s runs between `Base.sigatomic_begin()` and
`Base.sigatomic_end()`, so the sweep, the record and the terminal lifecycle
land whatever arrives. A raise deferred to the end propagates raw out of
`run!` or `step!`, the simulation already terminal. No test; the reviewer
reads it.

`run!`'s disposition:

```julia
try
    _run_body!(sim, policy, addrs, typemax(Int), _t_end_frame(sim, policy.t_end))
catch err
    isempty(sim.plane.roster) && rethrow()   # unattended: CI fails honestly (§13.4)
    @error "run! ended errored; the cause is retained on termination(sim) (§13.4, §13.6)" *
           " and the simulation refuses every advance (§12.6)" exception = (err, catch_backtrace())
end
```

The roster, not the live entries: a rostered device whose `init!` failed
still makes the session interactive. `err` is the `StepError` from the
calling-task topology and the `TaskFailedException` from the spawned-loop
one; the spawned-loop topology always has a device, so the rethrow arm
never sees the wrapped form. The message text is the stage's; the test
asserts one `Error`-level record and nothing about its wording.

## Probe first

Run every probe in the scratchpad before writing the test that relies on
it, and record the outcome in the report.

1. Signal delivery from inside the frame: a component whose `x_derivative`
   calls `ccall(:kill, Cint, (Cint, Cint), getpid(), Cint(2))` when armed,
   under `Base.exit_on_sigint(false)`. Deviceless, the loop runs on the
   test's own task, which is thread 1's, and the mask holds the signal to
   the unmask. Confirmed at the tip in a script; confirm it under the suite's
   process.
2. A raise inside the pause wait: `schedule(loop_task, InterruptException();
   error = true)` from a spawned task while the loop is parked in
   `wait_resume!`. `wait(::GenericCondition)` removes the task from the wait
   queue on an exception and re-locks before rethrowing, so the pattern
   should hold; confirm it. A real signal cannot target a parked task from
   another task in a single-threaded process, since the sender is the
   current task when it sends.
3. A raise inside the join: the same `schedule` against the task parked in
   `_tail!`'s `timedwait`, from a device task ignoring the predicate. If
   neither 2 nor 3 is reliable, cover the arm by reading and say so in the
   report; never ship a test that passes by timing.
4. The corner: a signal sent inside the frame by a component that then
   throws. Confirmed at the tip for the shape above (the model error
   propagates, the interrupt is consumed, nothing fires later); confirm it
   under the suite's process and test it: the run ends `errored` with the
   `StepError` on the record, source `LoopError`.

`Base.exit_on_sigint(false)` is set at the top of each signal test and
restored to `!isinteractive()` in a `finally`, so a script process gets its
kill back and a REPL session keeps its prompt. A test that sends a real
signal never runs with the flag `true`.

## Tests

Every testset name states its property and cites its section. Fixtures live
at top level; grep every new fixture name across `test/` before choosing
it. Add every new public name to `test/imports.jl`.

Stage 1:

- `pause!` from another task freezes the frame counter at a frame top with
  `latest` boundary-consistent, and `resume!` lets it advance (§12.1). A
  rostered `Pad` keeps the loop yielding; read the counter twice across a
  `sleep` while paused.
- a stop issued while paused ends the run at that frame top, source `:code`
  or the device's name, frames advanced equal to the count at the pause
  (§12.1, §12.4(2)).
- `pause!` before `run!` starts the run paused at its first frame top, and
  the tail clears the flag: after the run, `paused(sim)` is `false`, and
  `init!` then `step!` advances without a `resume!` (§12.1).
- `step!` blocks while paused until a `resume!` from another task, then
  returns the full count (§12.1).
- `paused(sim)` reads the flag in every lifecycle state, and the two verbs
  refuse nothing (§12.1).

Stage 2:

- a signal inside the frame is deferred to the unmask: the run ends
  `stopped` with `ControlRequestedStop(:interrupt)`, `latest(sim).t` is the
  interrupted frame's own boundary time, and `step!` counts that frame
  (§12.4, D-268). Contrast with the synchronous test at
  `test_failures.jl` 288, whose frame is abandoned; keep both.
- a deferred interrupt yields to a stop face holding at the same
  publication: the source is `ModelRequestedStop` with the face (§12.4,
  §13.5, D-268).
- a frame that throws with a signal pending ends `errored` under its own
  `StepError`, the interrupt consumed and nothing raised afterwards (§12.4,
  §13.4), probe 4.
- an interrupt in the pause wait ends the run `stopped` with `:interrupt`,
  no frame in flight (§12.1, §12.4), probe 2 permitting.
- an `InterruptException` thrown inside a device's `init!` is the operator's
  stop: `shutdown!` called, no `DeviceCrash` in the device's totals or the
  logs, no task, zero frames advanced, the other rostered device initialized
  and shut down, source `:interrupt` (§12.4, D-268). A synchronous throw
  exercises this arm; no signal needed.
- an interrupt during the join collapses it: a `Stubborn`-style device with
  `join_timeout = 30.0`, the run returning well inside that, the device
  named under `DeviceJoinTimeout` in the residue, the run `stopped` (§12.4,
  D-268), probe 3 permitting.
- `run!` with a rostered device returns after a loop-side failure, the
  lifecycle `errored`, `termination(sim).source` a `LoopError` with the
  `StepError` inside, one `Error`-level log record; deviceless it still
  rethrows (§13.4, D-268). The §13.6 testset at `test_lifecycle.jl` 356
  attaches a `TailProbe` and asserts `@test_throws StepError run!`; it
  changes to the logged form under `Test.collect_test_logs`, every other
  assertion in it unchanged. The two `@test_throws StepError run!` in
  `test_trace.jl` (750, 885) are deviceless and stay.
- `step!` on a simulation with a rostered device still rethrows (§13.4).

## Prose to correct

- `devices.jl` 1–12, the file header: pause and the interrupt are no longer
  absent; pacing alone is.
- `devices.jl` 31–64, the `Control` docstring: the `paused` field, its
  consultation points, the tail clearing it.
- `devices.jl` 406–410, `_finish!`'s comment: the clause "the §13.6 catch
  path is absent (`pending.md`)" is stale at the tip; replace it with what
  `_finish!` now does.
- `devices.jl` 364–377 and 423–435, the bracket's and `_tail!`'s
  docstrings: the interrupt arm and the collapse.
- `sim.jl` 12–14, `ControlRequestedStop`'s docstring: `:interrupt` is
  requested at an unmask point, the bracket, or the defensive branch.
- `sim.jl` 1010–1054, `run!`'s docstring: the rethrow sentence at 1028
  becomes the roster discrimination.
- `sim.jl` 1193–1208 and 1241–1245, `_advance!`'s comments: the pause block
  at the frame top; the mask, the unmask points and the corner above in
  place of "the masked guarantee without the masking".
- `sim.jl` 1420–1429, `stop!(sim)`'s docstring: it wakes a paused loop.

Every count and line number above was read at `73fc5ce`; a stage 2 agent
re-reads them after stage 1's commit moves them.

## Bookkeeping

- `implementation.md` row 37 (`devices.jl`): `Control` keeps the pause flag
  beside the stop word; the pause block; the bracket's interrupt arm; the
  tail's collapse; cite §12.1, D-268. Row 29 (`sim.jl`): the three pause
  verbs beside `stop!`; the mask and the unmask points in `_advance!`; the
  masked bookkeeping; `run!`'s roster discrimination; cite D-268.
- `pending.md`: delete the first bullet under "Not yet built" ("§12 beyond
  its built slices"). The pacing bullet then leads.
- `check_refs.jl` and `check_rows.jl` read both files; run both.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

`sim.jl` is touched in both stages, so the routed subset is the table's last
row, all of it, at every stage commit:

    JULIA_LOAD_PATH="@" julia --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

In the foreground, 600 s timeout, never in the background. Compare the
assertion total against `73fc5ce`'s run before and after: the new testsets
add, the §13.6 testset keeps its count, and nothing else moves. Note that
`JULIA_NUM_THREADS=auto` is set in the user's environment, so the suite runs
multi-threaded on this machine; every new test must pass single-threaded
too, which `-t 1` checks once per stage.

## Rules for the stage

- Never stash, reset or check out the working tree. Baselines come from
  `git show 73fc5ce:path`.
- Fixtures live at top level; grep every new fixture name across `test/`.
- No local named `control` may shadow a function; none exists. `pause!`,
  `resume!` and `paused` are new API names, so no helper may share them.
- One commit per stage. Single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says.
- Design and code are peers. If the spec's shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 400 words: the commit hash, the gate's result verbatim (pass/fail
counts, before and after, and the `-t 1` run), the three probes' outcomes,
every file touched with one line each, any place the brief was wrong about
the tree, and anything left undone with the reason.
