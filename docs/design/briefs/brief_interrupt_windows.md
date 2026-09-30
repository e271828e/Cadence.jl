# Brief: three interrupt windows around `run!`'s arm

The first "Retire alone" bullet of `pending.md`, ruled 2026-09-30 as one fix
with a cold review after it. One Opus fixer, one commit; a cold reviewer
follows with the gate.

## The ruling

`pending.md`, lines 48–67:

> **Three interrupt windows around `run!`'s arm** (§11.6, §12.4, D-268):
> the cold review of the arm's await (`e2df80f`, `0376fd2`) found three
> older windows. Ruled 2026-09-30 as one fix, with a cold review after it.
> - An interrupt inside the arm's own lines (the stop request, the
>   deregistration, `_finish!`, the direct shutdowns) escapes with `source`
>   unset. The outer `finally` then lands `initialized` with no record, and
>   in the calling-task topology the loop may still be running. The
>   fallback source moves to the arm's top, so an escape lands `stopped`,
>   and the stop request and the deregistration move inside
>   `_await_loop`'s `try`.
> - An interrupt after `Threads.@spawn` schedules the loop but before
>   `loop_task` is bound leaves the arm nothing to await. The spawn line is
>   masked, so the interrupt is deferred until the task is bound.
> - An interrupt between the other devices' spawn and the inline wrapper's
>   `try` never shuts the inline entry down, against §11.6's every exit
>   path. The arm shuts it down when its wrapper never started.
>
> With it, `implementation.md`'s "The inline wrapper removes its entry"
> names `_run_body!`'s `finally` instead. A non-interrupt throw before the
> tail runs no tail and stays so: only a framework fault reaches it.

Design and code are peers, neither subservient. The ruling is settled; the
shapes below are the coordinator's. Where the tree contradicts a claim made
here, follow the tree and say so in the report.

## Reading, in order

- `docs/design/pending.md` lines 40–67.
- `docs/design/spec.md` §12.4 (lines 7298–7640) for the shutdown protocol
  and the mask; §11.6 lines 6430–6470 for the wrapper and "every exit path";
  §11.1's topology table (lines 5500–5545). Read by line range, never whole.
- `docs/design/decisions.md` D-268 (lines 10497–10560).
- `docs/design/implementation.md`: the `src/sim.jl` row (lines 295–416,
  especially the publication paragraph at "The inline wrapper removes its
  entry" and the §12.4 bullet list under "the mask and the handling around
  it"); the `src/devices.jl` row (620–659); "Authoring caveats" (778–842);
  "Naming" (843–920); "Running the suite" (921–end), the one home of test
  policy.
- `src/sim.jl`: `_run_body!` (lines 1276–1430) in full, `_await_loop`
  (1565–1590), `_interrupt_source`; `src/devices.jl`: `_shutdown!`, `_wrap`,
  `_spawn!`, `_finish!`, `_tail!` (lines 360–560); `src/control.jl`:
  `_request_stop!` (75–90).
- `test/test_devices.jl`: the helpers `parked_in` and `interrupt_parked`
  (lines 215–240), the fixtures `LoopRecorder` and `HeldInline`, and the
  interrupt testsets at lines 456–560, 875–990.

## Runtime traps, read before touching a mask or a test

- A `try` exit restores Julia's sigatomic count to its entry value on 1.13,
  on the normal exit too. A mask begins and ends outside any `try` that
  encloses only one of them. The spawn line's mask therefore has both ends
  on the same level of `_run_body!`, both inside its outer `try`, with no
  `try` between them. Verify a mask by reading the count after every exit
  path, with no enclosing `try`, in a REPL probe.
- A real SIGINT lands on thread 1's current task; a task parked in a wait
  takes an exception through `schedule(task, exc; error = true)`, which is
  what `interrupt_parked` does. A test never passes by timing: park the
  task on a condition and assert against that, never after a `sleep`.
- The suite's helper `interrupt_parked(task, waited_on)` throws the
  interrupt only into a task parked on `waited_on`, under its lock.

## The shapes

**Window 1: the arm's own lines.** The arm's first statement is the fallback
source, before anything that can be interrupted:

    returned || (source = ControlRequestedStop(something(@atomic control.stop_issuer, :interrupt)))

An earlier issuer keeps the record, as the stop word's CAS keeps it. Any
interrupt escaping the arm past this line now propagates raw out of `run!`
with the run landed `stopped` by the outer `finally` (which already runs
masked). The arm's own `_request_stop!` line and its deregistration
(`filter!` under `wake`) are deleted from the arm; both move into
`_await_loop`, inside its `try`, each done once and retried when an interrupt
cuts it short, on the pattern `stop_pending` already uses. Give `_await_loop`
a way to know it is the arm's call (a third positional argument carrying the
plane, or a keyword; pick the one whose name says what it holds). The
ordinary call at line 1333 requests nothing and deregisters nothing, as now.
In the unattended topology (`loop_task === nothing`) no loop is running when
the arm runs, so the arm requests no stop there; the fallback source carries
the record. Later assignments (`source = _await_loop(...)`) overwrite the
fallback, and a loop failure still takes the failure block, so the ordering
of the rest of the arm stays.

**Window 2: the spawn line.** Mask the spawn:

    Base.sigatomic_begin()
    loop_task = Threads.@spawn try ... end
    Base.sigatomic_end()

Both ends on the same level, no `try` between them (the task body's `try`
runs on the spawned task, not here). A deferred interrupt then raises at the
`sigatomic_end`, with `loop_task` bound and the arm able to await it.

**Window 3: the inline entry's release.** The arm releases the inline entry
itself when its wrapper's `finally` never ran. Hoist `inline_entry = nothing`
beside `live, tasks, loop_task`. Give `_wrap` an optional second argument, a
`Ref{Bool}` the wrapper's `finally` sets to `true` right after `_shutdown!`
(default a fresh `Ref(false)`, so `_spawn!` changes nothing). The arm, in its
`!tail_ran` block after the joins:

    inline_entry === nothing || tasks === nothing || released[] || _shutdown!(inline_entry)

When `tasks === nothing` the direct `foreach(_shutdown!, live)` already
covers the inline entry. Name the `Ref` for what it holds. The few
instructions between `_shutdown!`'s return and the flag's store are a window
of the same size `_await_loop`'s comment already admits; say so in the
comment, and prefer a second `shutdown!` over a leaked one.

**The comment.** Rewrite the arm's comment (lines 1340–1360) so it describes
the arm as it now stands: the fallback first, the await with its request and
deregistration retried inside it, the tail, the inline release. Keep it
concise. Drop "One test reaches the inline body's deregistration; the other
windows are covered by reading" and name what the tests now reach.

## Tests

In `test/test_devices.jl`, beside the two await testsets (lines 486–560):

- Window 1, deterministic: an interrupt landing inside the arm's own
  deregistration. The existing testset at line 509 holds `wake` so the
  calling task parks in the inline body's `finally`; extend it, or add a
  sibling, so that after the first interrupt reaches the arm the observer
  holds `wake` again, the arm's `_await_loop` parks on it in its
  deregistration, and a second interrupt lands there (`interrupt_parked`
  against `wake.lock.cond_wait`, as the existing test does). Assert: the
  observer sent both, the loop ended inside `run!`, `lifecycle(sim) ===
  :stopped`, the source is `ControlRequestedStop(:interrupt)`, and no frame
  published past the record.
- Windows 2 and 3 are not reachable deterministically from a test; they are
  covered by reading and by the reviewer's probes. Do not add a test that
  passes by timing.
- Every existing interrupt testset stays green; the one at line 509 must
  still exercise what its name says after the deregistration moves.

## Bookkeeping

- `docs/design/implementation.md`, `src/sim.jl` row: the publication
  paragraph's "The inline wrapper removes its entry when its body returns,
  under `wake`'s lock. `run!`'s interrupt arm removes it again before it
  awaits the loop" becomes: `_run_body!`'s `finally` removes the inline
  entry when its body returns, under `wake`'s lock, and `_await_loop`
  removes it again inside its `try` on the arm's call. The §12.4 bullet on
  the arm describes the fallback-first arm, the masked spawn and the inline
  release. Run `docs/design/tools/check_refs.jl`, `check_rows.jl` and
  `linkify.jl` afterwards (headers say how); all green.
- `docs/design/pending.md`: delete the "Three interrupt windows" bullet
  whole, its trailing paragraph included. Nothing else there moves. If the
  "Retire alone" list would be empty, it is not: two bullets follow.
- The change touches `src/sim.jl`, the table's last row: run the full gate
  yourself, in the foreground, 600 s timeout:

      JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

  Then `devices` alone once more at `-t 1`, since the interrupt tests have a
  single-threaded layout the gate's `-t auto` does not exercise. Both green
  before the one commit.

## Rules

- One commit. Message: single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says. Stage
  files by explicit path; the tree holds untracked directories that are not
  yours (`docs/design/gui_*`, `docs/reports/`).
- No background work, probes included. Never stash, reset or check out the
  working tree. No bare `ls` (`/bin/ls` or `fd`).
- Every changed line traces to this brief; the older windows the ruling does
  not name (an interrupt inside `_spawn!` itself, between the registrations)
  are out of scope and go in the report if you meet them.

## Report

The commit hash and subject; files touched with one line each; the test
added and what it parks on; the gate's summary line and the `-t 1` run's;
the mask probe's result (the count after each exit path); any deviation from
this brief and why; anything left for the user or the reviewer.
