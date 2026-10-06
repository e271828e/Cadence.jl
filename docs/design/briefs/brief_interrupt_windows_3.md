# Brief: the init bracket's leak and the lost loop failure

The two interrupt gaps the second cold review left open (see
`notes_standalone_updates.md`, "The older windows", item 6, "Open, for the
user"), plus two relatives found while probing them. The user ruled on
2026-10-01 that all are fixed as one increment. One Opus builder, one
commit; a cold reviewer follows with the gate.

The docs half landed first as `cc42741`: §11.6 and D-268 now say `shutdown!`
may run on a device whose `init!` never began.

Design and code are peers, neither subservient. The shapes below are the
coordinator's, probed on a scratch copy. Where the tree contradicts a claim
made here, follow the tree and say so in the report.

## The four windows, with what each does at `cc42741`

Each was confirmed by an injected `throw(InterruptException())` on a
`git archive` copy.

1. **The init bracket leaks** (`src/devices.jl`, `_init_devices!`). The
   bracket collects into a local `live` that `_run_body!` receives only
   through `append!` after the bracket returns. An interrupt escaping the
   bracket reaches `run!`'s arm with `live` empty, so the direct release
   shuts down nothing. Probe: device 1 logs `[:init]`, never `:shutdown`;
   the run lands `stopped`.
2. **The failure arm loses the loop's throw** (`src/sim.jl`, `_run_body!`,
   `loop_failure = (err, catch_backtrace())`). The allocation is a safepoint
   outside every `try`. An interrupt there skips the `LoopError`, and the
   `finally` reads `source === nothing` as an exhausted frame budget. Probe:
   `InterruptException` out of `run!`, lifecycle `initialized`, no record,
   over a failed frame.
3. **The inner `finally` loses it too** (`_run_body!`, the loop on the
   calling task). `_finish!` runs while the `StepError` propagates. An
   interrupt in its lock wait replaces the `StepError`, and the outer catch
   sees the interrupt alone. Probe: nothing thrown, lifecycle `stopped`,
   source `ControlRequestedStop(:interrupt)`, over a failed frame.
4. **`step!`'s failure arm** (`src/sim.jl`, `error_source = LoopError(err)`).
   The compiled body allocates the box before the store
   (`ijl_gc_small_alloc` in `code_llvm`), so the window is real. Probe: as
   window 2.

§12.4 says a frame that throws with an interrupt pending ends `errored`
(D-268). Windows 2 to 4 contradict it. §11.6 guarantees the release on
every exit path. Window 1 contradicts that.

## Reading, in order

- `docs/design/briefs/brief_interrupt_windows.md`, its "Runtime traps"
  section, and `brief_interrupt_windows_2.md`, whole. Both apply unchanged.
- `docs/design/spec.md` §11.6 lines 6479–6504 (the three tolerance
  paragraphs); §12.4 "Initialization" (7480–7580) and "The operator
  interrupt" (7581–7667); §13.4's disposition and §13.6 by heading. Read by
  line range, never whole.
- `docs/design/decisions.md` D-268 (from line 10507), both amendments.
- `docs/design/implementation.md`: the `src/sim.jl` row's §12.4 bullet list
  (line 428, "§12.4's mask and the handling around it"); the
  `src/devices.jl` row's init bracket bullet (line 705); "Authoring
  caveats"; "Naming"; "Running the suite", the one home of test policy.
- `src/sim.jl`: `_run_body!` in full (from line 1287), `_await_loop`,
  `_advance!`, `step!`'s body (from line 1782); `src/devices.jl`:
  `_shutdown!`, `_wrap`, `_init_devices!`, `_finish!`, `_tail!`;
  `src/control.jl`: `_request_stop!`.
- `test/test_devices.jl`: `parked_in`, `interrupt_parked`, `HookedInline`,
  `LoopRecorder`, `TailProbe` (in `fixtures.jl`), the testsets at lines 536,
  587 and 974. `test/test_failures.jl`: the two testsets at lines 387 and
  401, and `test/test_lifecycle.jl` line 495 for the `Exploder` idiom.
- A reference diff of the probed shapes sits at
  `/private/tmp/claude-501/-Users-miguel--julia-dev-Redstone-jl/359debee-5390-4a7a-b7f2-3320c3ab741b/scratchpad/ref/reference.diff`.
  It is evidence that the shapes work, not text to paste: its comments are
  placeholders, and it drops a comment block this brief keeps.

## The shapes

**Window 1: the bracket fills the run's list.** `_init_devices!` takes the
run's `live` as a third argument and returns it. It pushes each entry before
that entry's `init!`, and pops it after the bracket's own release when the
`init!` threw:

    for entry in roster
        push!(live, entry)
        try
            init!(entry.dev)
        catch err
            _shutdown!(entry)
            …                       # the two arms, unchanged
            pop!(live)
        end
    end

`_run_body!` calls `_init_devices!(sim, roster, live)` in place of the
`append!`. Nothing else in the arm changes: with `tasks === nothing` its
direct release already walks `live`. An interrupt between the `push!` and
the `try` releases a device that opened nothing, which §11.6 now admits. An
interrupt between the bracket's `_shutdown!` and the `pop!` runs `shutdown!`
twice, which §11.6 admitted already. The docstring says what the bracket now
does with `live` and why the listing precedes `init!`.

**Windows 2 and 3: the cause is stored first, and the `finally` owns the
disposition.** In `_run_body!`:

- A local `cause`, declared beside `source`, replaces `error_source` among
  the body's locals. It holds the loop's throw.
- The failure arm's first statement is `cause = err`, ahead of
  `catch_backtrace()`. No allocation precedes the store.
- The interrupt arm's value path sets `cause = first(outcome)` where it
  takes the tuple from `_await_loop`.
- The inner `try` around `_advance!`, in the loop-on-calling-task arm, gains
  a `catch` that stores a non-interrupt `err` in `cause` and rethrows. An
  `InterruptException` is not a cause.
- The masked `finally` builds the `LoopError` from `cause`, unwrapping the
  `TaskFailedException` as now, and lands `errored` whenever `cause` is set.
- The disposition block after the two arms keys on `cause`, not on
  `loop_failure`. With an empty roster it rethrows the cause. Otherwise it
  logs: the tuple where a backtrace was taken, the bare cause where the
  interrupt arm ran with no tuple (window 3's path).
- The "§13.6's abnormal entry" comment block moves with the `LoopError` to
  the `finally`, reworded only as far as the move requires.

What this leaves: an interrupt cutting the failure arm after the store
propagates raw out of `run!`, the simulation already `errored` with the
record written. That matches §12.4's rule for the masked bookkeeping and is
ruled acceptable. The disposition (rethrow or log) is skipped on that path.

**Window 4: `step!` takes the same store.** `cause` replaces `error_source`;
the arm is `cause = err; rethrow()`; the `finally` builds `LoopError(cause)`
under its mask.

**`step!`'s interrupt arm stays.** A second interrupt in its
`_request_stop!` escapes with `source` unset and lands `initialized` at a
consistent frame top, the stop word set. Ruled harmless: no loop is left
running and no store is mid-boundary. Add one clause to the arm's comment
naming that window and its outcome. No code change there.

**Comments.** `_run_body!`'s arm comment names the bracket's escape among
the places the stop can land and says the direct release finds every entry
whose `init!` began. Keep the comment density of the file. Do not grow the
arm comment beyond what these changes require.

## Tests

Tests never pass by timing: park on a condition and assert against that.

- **Window 1**, in `test/test_devices.jl` beside the testset at line 974.
  Two devices. The first counts its calls (`TailProbe` does). The second's
  `init!` parks on a hook, and its `shutdown!` counts. The observer waits
  for the caller to park in the hook, takes `wake`, throws the first
  interrupt into the hook park, then throws the second into the caller's
  park on `wake.lock.cond_wait` (the bracket's `_request_stop!`), then
  releases `wake`. Assert: both sent; the first device logs
  `[:init, :shutdown]`; the second saw one `init!` and two `shutdown!`s
  (the bracket's and the arm's, as §11.6 admits); `run!` threw nothing;
  lifecycle `stopped`; source `ControlRequestedStop(:interrupt)`. The
  test must be red at `cc42741` on the first device's log. Check that
  before you fix.
- **Window 3**, in `test/test_failures.jl` or `test_devices.jl`, whichever
  holds the helpers it needs without a new import. A component whose armed
  evaluation signals the observer, waits for a go, then throws. The
  observer takes `wake` before the go, so the caller parks in the inner
  `finally`'s `_finish!`, and the interrupt goes into that park. Two
  variants: rostered (a `TailProbe` under `NoClaim()`), asserting `run!`
  returns, lifecycle `errored`, the source a `LoopError` holding the
  component's `StepError`, one error log; and deviceless, asserting `run!`
  throws that `StepError` and the same record. Both red at `cc42741`.
  Check `wait_resume!`, the drain and publication for any take of `wake`
  between the frame's throw and `_finish!` before you build on the park;
  the coordinator found none by reading.
- **Windows 2 and 4** have no park (`catch_backtrace()` and the store
  never block). No test. Each gets an injection probe, below.
- A new fixture name is grepped across all of `test/` first. A new
  `AbstractComponent` fixture routes `build` into the subset
  (`implementation.md`'s table).
- Every existing interrupt testset stays green.

## Probes

On a `git archive` copy of your working tree in your scratchpad, never the
tree itself: a `throw(InterruptException())` at each of the four windows,
before and after the fix, at `-t 1` and `-t auto`. Read the thrown value,
the lifecycle, the record's source and each device's log. Report the table.

## Bookkeeping

- `docs/design/implementation.md`: in the `src/sim.jl` row's §12.4 list,
  say that the loop's throw is stored before anything can cut the arm and
  that the masked bookkeeping builds the `LoopError` from it, in `run!` and
  `step!` alike; in the `src/devices.jl` row, say the bracket lists each
  entry before its `init!` in the run's own list. Then run
  `docs/design/tools/check_refs.jl`, `check_rows.jl` and `linkify.jl`; all
  green.
- No `pending.md` change: these windows were never registered there.
- The change touches `src/sim.jl`: run the full gate yourself, foreground,
  600 s timeout, then `devices` and `failures` at `-t 1`. All green before
  the one commit:

      JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

## Rules

- One commit. Message: single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says. Stage
  files by explicit path; the tree holds a deleted file and untracked
  directories that are not yours (`docs/design/inspector/`,
  `docs/design/gui_*`). Never `git add -A`.
- No background work, probes included. Never stash, reset or check out the
  working tree. No bare `ls` (`/bin/ls` or `fd`). Re-read a file before a
  scripted edit.
- Every changed line traces to this brief. A further window you meet goes
  in the report, not in the commit.

## Report

The commit hash and subject; files touched with one line each; each test,
what it parks on, and that it was red before the fix; the probe table; the
gate's summary line and the `-t 1` runs'; any deviation from this brief and
why; anything left for the user or the reviewer.
