# Brief: the three older interrupt windows

The cold review of `aca2e50` (see `brief_interrupt_windows.md` and
`notes_standalone_updates.md`, item 2) listed three windows around `run!`'s
interrupt arm that the earlier ruling did not name. The user ruled on
2026-09-30 that all three are fixed, as one fix with a cold review after
it. One Opus fixer, one commit; a cold reviewer follows with the gate.

## The three windows, as the review stated them

1. **An interrupt inside `_spawn!` between spawns, or between `_spawn!`
   and `_register_tasks!`.** `tasks` stays unbound, so the arm's direct
   release runs `shutdown!` on entries whose wrappers already run on spawned
   tasks, concurrently, and those tasks are never registered or joined.
2. **The gap between the outer `catch` and the fallback store.** The
   `ControlRequestedStop` allocation is a safepoint. An interrupt there
   leaves `source` unset, so the run lands `initialized`; in the
   calling-task topology the loop keeps running with no stop requested.
3. **An interrupt escaping the arm's own tail lines** skips the remaining
   shutdowns and joins with the run landed `stopped`. The escape points are
   `_finish!`'s wait on the `wake` lock, the `filter(...)` allocation, the
   gaps between entries of `foreach(_shutdown!, live)`, and the gap between
   `_tail!` and the inline release. §12.4 promises that an interrupt
   reaching the tail collapses it, every unjoined entry reported by name and
   nothing propagating; these points sit outside `_tail!`'s own collapse.

Design and code are peers, neither subservient. The shapes below are the
coordinator's. Where the tree contradicts a claim made here, follow the tree
and say so in the report.

## Reading, in order

- `docs/design/briefs/brief_interrupt_windows.md`, whole: the previous fix's
  brief, whose "Runtime traps" section applies here unchanged.
- `docs/design/spec.md` §12.4 (lines 7298–7640), the tail's steps and the
  collapse; §11.6's new paragraph "The same tolerance covers a second call"
  (around line 6478). Read by line range, never whole.
- `docs/design/decisions.md` D-268 (from line 10497), its position's last
  bullet included.
- `docs/design/implementation.md`: the `src/sim.jl` row's §12.4 bullet list
  (grep "the mask and the handling around it"); "Authoring caveats";
  "Naming"; "Running the suite", the one home of test policy.
- `src/sim.jl`: `_run_body!` in full (from line 1287), `_await_loop`,
  `_interrupt_source`; `src/devices.jl`: `_shutdown!`, `_wrap`, `_spawn!`,
  `_finish!`, `_tail!`, `_report_join_timeout!`; `src/control.jl`:
  `_request_stop!`.
- `test/test_devices.jl`: `parked_in`, `interrupt_parked`, `HeldInline`,
  `LoopRecorder`, `Wedged`, and the interrupt testsets (grep "interrupt").

## The shapes

**Window 1: mask the spawns and the registrations.** In the unattended arm,
`tasks = _spawn!(live)` and `_register_tasks!(plane, live, tasks)` go
between `Base.sigatomic_begin()` and `Base.sigatomic_end()`, both on that
level, no `try` between them. In the calling-task arm, one mask runs from
`tasks = _spawn!(others)` through the loop spawn's existing
`Base.sigatomic_end()`: the registrations, the inline entry's two lines and
the loop spawn all sit under it. None of those lines runs user code.
Probe, in the scratchpad, that a task spawned under the mask starts with the
count at zero (read it as the first act of a device loop body and of the
spawned loop, with no enclosing `try`).

**Window 2: mask the arm's head.** Inside the `InterruptException` branch,
the first statement is `Base.sigatomic_begin()`, and `Base.sigatomic_end()`
follows the re-request line:

    if err isa InterruptException
        Base.sigatomic_begin()
        returned || (source = ControlRequestedStop(…))
        returned || loop_task !== nothing || _request_stop!(control, :interrupt)
        Base.sigatomic_end()

Both ends inside the branch, no `try` between them. The two statements
before the mask (`loop_failure = nothing`, the `isa`) allocate nothing, so
no safepoint precedes it. `_request_stop!` takes `wake` under the mask; the
lock is held briefly by publishers and waiters, so the masked wait is
bounded.

**Window 3: the tail block retries.** The `!tail_ran` block becomes a loop
in the shape of `_await_loop`: a `try` whose body runs the tail's steps and
`break`s, and a `catch` that swallows `InterruptException` alone and goes
round again. Each step is idempotent or cursor-tracked, so a retry resumes
where the interrupt cut it:

- `_finish!` is idempotent already.
- The direct release (`tasks === nothing`) iterates `live` by index behind a
  cursor local advanced after each `_shutdown!` returns. An interrupt
  between the return and the advance runs that entry's `shutdown!` twice,
  which §11.6 now admits.
- `_tail!` collapses on its own when the interrupt lands inside it and
  returns normally; a flag set after it returns keeps a retry from running
  it twice, since a second run would report the abandoned joins again.
- The `filter(...)` moves inside the `try`, ahead of `_tail!`; recomputing
  it on a retry is harmless.
- The inline release keeps its `released[]` guard.

Name the cursor and the flag for what they hold. Keep the block's shape
readable: three or four small steps, one comment saying why it retries.

**The arm's comment** is rewritten once more so it describes the arm as it
now stands: the masked head, the await, the retrying tail, and the windows
that remain (the few instructions between a `catch` and its next `try`,
which only a forced raise reaches). Concise.

## Tests and probes

- Extend the existing multi-interrupt testset (`interrupt_count in (1, 2)`)
  only if a third interrupt can be parked deterministically somewhere the
  retrying tail covers, with no timing; the observer holding `wake` while
  the arm's `_finish!` takes it is the candidate, but the spawned loop's own
  `_finish!` needs the same lock to end, so check the ordering before you
  build on it. If no deterministic park exists, add no test and say so.
- Every window gets an injection probe in the scratchpad, on a copy built by
  `git archive` of your working tree (never the tree itself): a
  `throw(InterruptException())` placed at the window, a run, and the
  outcome read (lifecycle, source, each device's `init!`/`shutdown!`
  counts, joined or not, the count after `run!`). Run each probe at `-t 1`
  and `-t auto`. The reviewer's scratchpad copies from the last review may
  still be there (`inst/`, `fixinst/`); you may read their technique, but
  build your own. Report the outcomes in a table.
- Every existing interrupt testset stays green.

## Bookkeeping

- `docs/design/implementation.md`, `src/sim.jl` row, the §12.4 bullet list:
  the masked spawns and registrations, the masked arm head, the retrying
  tail. Run `docs/design/tools/check_refs.jl`, `check_rows.jl` and
  `linkify.jl` afterwards; all green.
- No `pending.md` change: these windows were never registered there.
- The change touches `src/sim.jl`: run the full gate yourself, foreground,
  600 s timeout, then `devices` alone at `-t 1`. Both green before the one
  commit:

      JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

## Rules

- One commit. Message: single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says. Stage
  files by explicit path; the tree holds untracked directories that are not
  yours (`docs/design/gui_*`, `docs/reports/`).
- No background work, probes included. Never stash, reset or check out the
  working tree. No bare `ls` (`/bin/ls` or `fd`).
- Every changed line traces to this brief.

## Report

The commit hash and subject; files touched with one line each; the test
added or the reason none was; the probe table; the gate's summary line and
the `-t 1` run's; the mask probe's counts; any deviation from this brief and
why; anything left for the user or the reviewer.
