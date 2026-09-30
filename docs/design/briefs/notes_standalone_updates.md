# Notes: the standalone updates, run of 2026-09-30

Rulings made while the user was away, in order, each with its reason. The
user's own rulings from the same session are listed too and marked as such.
The user reads this file first on return.

1. **Nothing is pushed.** Every commit lands locally on `master`. The push
   follows the user's diff review.
2. **No brief was written for these updates.** Each went to one fresh Opus
   agent with a prompt that carried the scope, the rulings, the reading
   route and the report format. The coordinator verified each diff before
   launching the next agent. There was no cold reviewer.
3. **Every update ran the gate itself**, because each touches `sim.jl` or
   `diagnostics.jl`, the routing table's last row.

## The frame index's rename

Commits `fffa9d4` (spec) and `320fd19` (code). Gate green, 3951 assertions
before and after.

4. **`StepError.frame` is `StepError.cursor`** (user ruling). The type
   `CursorFrame` keeps its name.
5. **Locals holding a `CursorFrame` no longer take the name `frame`** in the
   functions the rename touched. In `diagnostics.jl`, `_phase_text`'s
   parameter and `showerror`'s local are `cursor`. In `_wrap_step` the
   `CursorFrame` is built inline, because `cursor` holds the
   `ExecutionCursor` there. The reason is the rule of one meaning per file.
6. **Four prose phrases that named the field were reworded**, for example
   "the clock's step increments" to "the clock's frame increments". The
   agent judged that they name the field, and the coordinator agrees.
7. **The log was not swept.** A rename applies forward
   (`decisions_style.md`, rule 2).

Left for the user:

- `CheckpointMismatch` has a `what = :frame` arm, and its clock arm now
  carries `name = :frame`. The fields differ and nothing collides.
- `CursorFrame` is a third sense of the word, the cursor's own. The ruling
  covered the field alone, so the type stays.

## The carrier's host

Commits `02199eb` (spec and log) and `b265f95` (code). Gate green, 3982
assertions, 31 added.

8. **The field is `host::Symbol`**, between `boundary` and `cause`, with
   the values `:boundary_zero` and `:loop`. §13.4 already says the service
   "hosts the same catch", and the code names `_host_boundary_zero!`.
   Rejected: `origin`, which `sim.jl` uses for `t₀`, and `site`, which
   `diagnostics.jl` uses for the advance that declared a policy. A `Bool`
   was rejected because the file's other discriminators are symbols with
   their values listed in a comment.
9. **The general recipe holds from pointer 0** (user ruling). The rendering
   branches on `host` alone. Boundary zero names `init!` under the same
   condition. A frame's failure names the halt then `step!` at every
   pointer. Since D-274 the halt at pointer 0 restores the header and runs
   no boundary zero, so frame one's record is still ahead. The tests prove
   it on a fresh twin, for a raw cause and for `NonfiniteState`.
10. **D-274's last bullet was amended in place**, with a dated annotation
    in the form the log already uses. `pending.md` said the sentence moves
    with the update, and D-274 was corrected in place once before
    (`41929ec`). D-223's bullet on the pointer stays as the record of its
    day.
11. **One lead-in in §13.4 changed.** "What differs is the disposition."
    became "Boundary zero's disposition differs from the loop's as well."
    After the new sentences on frame one, the old lead-in read as a
    contrast with frame one's reproduction.

The final text of the changed passages, for review without a diff:

- **§13.4, "How handled".** "A `StepError` carries five things: the
  cursor's frame, the boundary time, the **frame-entry boundary index**,
  the host of the catch, and the original exception as `cause`." And,
  after the sentence on the legal replay halt: "The host names the catch
  that took the throw. It is `:loop` for a throw inside a frame, and
  `:boundary_zero` for a throw inside the boundary zero that `init!` runs."
- **§13.4, the sketch.** `host::Symbol   # :boundary_zero under init!,
  :loop inside a frame`
- **§13.4, boundary zero.** "The pointer is `0`. […] The reproduction of a
  boundary-zero failure is `init!` under the same condition (D-274).
  Boundary zero is frame one's entry boundary too, so a frame-one failure
  carries the same pointer. The carrier's `host` tells the two apart, and
  the rendered recipe reads it. A frame-one failure has a trace, and the
  halt-then-`step!` recipe above holds for it at pointer `0`. The halt
  restores the header and stops there, and `step!` re-executes frame one
  from the record. Boundary zero's disposition differs from the loop's as
  well."
- **Appendix C, `StepError`.** The row lists "the host of the catch
  (`:loop` or `:boundary_zero`)" after the replay pointer.
- **D-274, last bullet.** "Its reproduction is `init!` under the same
  condition. Frame one shares pointer 0, and the `StepError`'s `host` tells
  the two apart. The general recipe, restore to the pointer then `step!`,
  holds from pointer 0 for a frame's failure. (Amended 2026-09-30: the
  bullet started the general recipe at pointer 1, from the time one
  rendered text served both failures at pointer 0. The halt at pointer 0
  restores the header and runs no boundary zero, so frame one's record is
  still ahead of it and `step!` re-executes that frame.)"

Left for the user:

- D-274's **Spec** field does not list §13.4, which cites D-274 and which
  the amended bullet is about.
- `init!`'s docstring says a boundary-zero throw "arrives as a `StepError`
  with pointer 0". It is accurate and does not name the host.
- §12.7 says error reproduction "replays to `k − 1`", where §13.4 uses `k`
  for the pointer itself. The two agree only if §12.7's `k` is the failing
  frame's number.

## The frame slack

Commits `25ac836` (a docstring rewrap) and `3a3fc46` (the fix). Gate green,
3994 assertions, 12 added.

12. **The slack measures the larger of `|t|` and `|t₀|`.** The formula is
    `4 * eps(max(abs(t), abs(t₀))) / h`. The grid time `t₀ + k·h` and the
    difference `t - t₀` both round at that magnitude, so `eps(t)` alone
    collapses wherever `|t|` is much smaller than `|t₀|`. The defect was
    wider than the bullet's "near `t = 0`".
13. **The factor stays 4.** A random search over 5 million grid times,
    weighted toward `t ≈ 0` and `t ≈ -t₀`, found that no case needs more
    than 1.5. A worst-case bound on paper gives 4.5, but its four error
    terms never peak together. Midpoints still floor onto their own frame
    and ceil onto the next, so the slack is not too large either.
14. **The tests came first and failed at the tip**: seven failures in
    `lifecycle trace`, among them both cases the bullet names.
15. **`StepError`'s docstring was rewrapped in its own commit.** The host
    update had left one line far over the file's width. No word changed.

Left for the user:

- The comment above the helpers said the origin is a `Float64`. That was
  already wrong for `step!`'s `t_plus`, which passes its clock as the
  origin. The agent corrected the sentence with the fix.
- No test drove `step!(; t_plus)` on a `Dual` activation before. One does
  now.

## The "Smaller" bullet

Taken item by item after the three entries, on the user's instruction, with
a context check before each one.

16. **`report!(entry, DeviceCrash(…))`** (commit `5174126`, gate green,
    3999). One method beside the handle's, admitting `DeviceCrash` alone.
    It asserts no attachment and beats no heartbeat, since a beat would
    claim life for a device that did not run or has just died. Both
    framework sites file through it, the pre-spawn bracket §12.4 names and
    the wrapper, which holds the entry and writes the same cell. No handle
    method for `DeviceCrash` was added: the handle's docstring says a
    device's author may file `MalformedDatum` alone, and a handle method
    would open the crash to the author.
17. **The log's `sizehint!`** (commit `7464639`, gate green, 4002). The
    constructor hints the middle's capacity to `log_max` when the log is
    enabled and the bound is finite. Since D-255 moved `t_end` to the
    advances, `init!` knows no duration, so the bound alone sets the hint.
    At the default `65536` that is 512 kB of references per `init!`.

Left for the user, with a recommendation each:

- **§11.6's wrapper sketch** writes `report!(handle, DeviceCrash(e))`.
  The code files by entry, and a handle method would let an author file a
  crash. Recommendation: the sketch reads `report!(entry, DeviceCrash(e))`.
- **The routing chain** (item 2) is a feature, not a loose fix, and it
  needs a ruling on shape. §13.7's one example,
  `"crashed" → aircraft/monitor/out ← systems/ldg/{left,right,nose}/damaged`,
  reads as more than a chain of aliased faces: the `←` half lists the
  producing component's own inputs, a dataflow view. The chain `Structure`
  records and the printer's format both follow from that reading. The
  coordinator's proposal: `resolve_source` records the hops
  `(path, face)` from a face to its producing terminal in the face table's
  row, one chain per output face and one per consumer for an input face
  that fans out; the printer prints the hops joined by `→` and stops at the
  terminal, with no `←` half. The user rules whether the `←` half is owed.
- **The log's inline records** (item 3, second half). §7.5 says snapshots
  are records stored inline in a `Vector`. `Snapshot{T,S}` is immutable
  and concrete per run, so a `Vector{Snapshot{T,S}}` would store the
  records inline. The log's middle is `Vector{Union{Nothing,Snapshot}}`,
  abstract and with `nothing` marking a released slot, so it holds boxed
  references. Inline storage needs a per-run concrete log type and another
  way to mark a released slot, which touches the thinning algorithm
  (D-137). Recommendation: leave the shape and soften §7.5's sentence to
  the claim it makes in its next sentence, that the snapshot's fields ride
  as references to frozen data with no per-boundary garbage.
- **The roster's freeze** (item 4). §11.3 says the roster is "a plain
  immutable value the loop reads once at `run!`". The code re-reads
  `plane.roster` every frame and the freeze is `assert_stopped`'s gate.
  The audit itself grades this a stand-in, the guarantee holding. The two
  ways to conform: the run takes a copy of the roster at `run!` and the
  loop iterates that, or the sentence softens to the gate. Recommendation:
  the copy, since `_init_devices!` already derives `live` from the roster
  at run start and the loop could iterate it.
- **`ReplayDiscardedStaging`'s presentation** (item 6). The coordinator
  could not determine what "unpresented" was meant to say. The audit's
  tables grade the kind accurate and rate-limited, and note only that its
  payload has no device id, which the cell's attribution supplies. The
  clause stays until the user says what is owed.
18. **The every-component `Dual` sweep** (commit `4297ca7`, gate green,
    4007). The sweep reads the concrete component types off the live suite
    module, covers those with a zero-argument constructor and a nominal
    build, and requires the `ProbeDual` activation of each. Four fixtures
    are pinned on purpose and listed by name; the test asserts the refusers
    equal that list. Two fixtures throw past the diagnostic channel on
    purpose and are listed too. The covered count is a floor, the skipped
    count exact, so a new argument-taking fixture is classified on purpose.
    The sweep costs about 36 s inside the gate, which grew from about 5:00
    to 5:19. The coordinator added one guard after the agent's commit: a
    real interrupt during a nominal build stops the sweep instead of being
    counted as a pass-through.
19. **`run!`'s interrupt arm awaits the spawned loop** (commits `e2df80f`,
    `0376fd2` and one test commit after them; gate green, 4021). The ruling
    was the bullet's own text. The arm requests the stop, awaits the loop
    with `_await_loop`, takes the loop's outcome as the source, and feeds a
    loop failure into one block shared with the other arm. The agent found
    a deterministic test: the observer holds the control plane's lock, so
    the calling task parks in the deregistration `finally`, outside every
    catch, and takes the interrupt there. A cold reviewer then ran over
    the change. Its one real finding: a third interrupt landing inside
    `_await_loop`'s own stop request escaped as the loop's failure and
    ended the run `errored`. The coordinator ruled the fix into
    `_await_loop` itself, a pending flag with the request inside the `try`,
    so the ordinary path is covered by the same change. The reviewer's
    other findings, the inline body's stale registration, a rebound `err`,
    a test that could not tell the loop's outcome from the arm's fallback,
    and two wordings, were fixed too; the reviewer verified the delta. The
    coordinator then removed a timing dependence the verification found:
    the hold cap is now a 30 s safety net and the observers release the
    held frame themselves. That commit ran `devices` on both thread
    layouts and not the full gate, since it touches that file's tests
    alone.

Left for the user, from the cold review, all older than these commits:

- An interrupt landing in the arm's own first lines, before the await's
  `try` (the stop request, and now the registration's removal), escapes
  the arm: no tail runs, the loop is not awaited, and the lifecycle lands
  `initialized`. The reviewer suggests guarding the removal with a `try`
  that swallows the interrupt, or naming the window in the arm's comment.
- An interrupt after `Threads.@spawn` schedules the loop but before
  `loop_task` is assigned reaches the arm with no loop to await.
- The inline entry is never `shutdown!` when the interrupt lands between
  the others' spawn and the wrapper's `try`, since the tail filters it out.
- The non-interrupt arm runs no tail for a throw that came before it.
- `implementation.md` says "The inline wrapper removes its entry"; the
  removal is `_run_body!`'s `finally`.

## The leftovers, 2026-09-30 (second session)

The five `pending.md` entries the user ruled at the end of the first session,
worked in order, one Opus agent each, nothing pushed. Briefs
`brief_face_routes.md`, `brief_interrupt_windows.md`, `brief_roster_copy.md`
and `brief_log_boxes.md` carry the coordinator's shapes; the rulings that
went beyond the bullets' text are listed here.

1. **Face routes** (`6df9c95` docs, `b36fd54` code; subset green, 2257).
   Shapes ruled by the coordinator: the resolvers return the route (the hops
   below a face, ending at the terminal) and the draft stores it; `Structure`
   keeps `in_faces`/`out_faces` unchanged for their five readers and gains
   `in_routes`/`out_routes`, one row per route at every level; the printer
   adds `input routes:`/`output routes:` blocks after the anchors, root faces
   only, one line per route, a side with no root face printing no block.
   §13.7's example gained the intermediate hop (`crashed → aircraft/crashed →
   aircraft/monitor/out`): under §6.1's one-level rule a root face reaches a
   grandchild's port only through the child's face, so the two-hop form is
   the only one the printer can produce. The agent found no amendment
   template in `decisions_style.md` and used the in-log "(Amended date: …)"
   parenthetical. Left: `src/assembly.jl`'s pre-existing comments near lines
   944–965 say "chain" for the obligation chain, beside the new route
   vocabulary; D-257's amended bullet still calls the item the "Smaller"
   bullet.
2. **Three interrupt windows** (`aca2e50`; gate green, 4050; `devices` at
   `-t 1` green). Shapes ruled by the coordinator: the fallback source is the
   arm's first statement, `ControlRequestedStop(something(stop_issuer,
   :interrupt))`; `_await_loop` takes the plane on the arm's call and does
   the deregistration and the stop request inside its `try`, each retried
   after an interrupt; the spawn is masked with both ends on one level; the
   inline release rides a `Ref{Bool}` the wrapper's `finally` sets after
   `_shutdown!`, the arm releasing the entry when it is unset. The fixer put
   the deregistration ahead of the request inside `_await_loop`, so the
   test's second interrupt lands in the deregistration; the order is
   neutral. The fixer's caveats, for the user: a few instructions between
   the `catch` and the fallback, and between the fallback and the await's
   `try`, still escape (the run landed `stopped`); in the unattended
   topology the arm no longer writes the stop word, so a device's `stop!`
   after the fallback read can leave the word and the record differing,
   with no reader of the word after a run found; an interrupt inside
   `_spawn!` itself stays open, out of the ruling's scope.
   The cold review (gate green, 4050; mask probed on every exit path at
   `-t 1` and `-t 4`) found no medium or high defect. Its two low findings
   and the nits were landed by the coordinator in the fix commit after it:
   with no loop to await the arm requests the stop again, since a forced
   raise inside the spawn's mask can leave a loop scheduled and unbound and
   at HEAD such an orphan ran unbounded where the parent stopped it within a
   frame; `HeldInline` counts its `shutdown!`s and the test pins one, which
   is what makes the `released` guard testable (a mutant without it passed);
   two comments corrected; the test local `interrupts` renamed
   `interrupt_count`. The reviewer judged the stop word and the record
   differing after a run not a defect (no reader of the word after a run,
   cleared at every door and run start). Out of scope, registered for the
   user: an interrupt escaping the arm's own tail lines skips the remaining
   shutdowns and joins with the run landed `stopped`; the gap between the
   outer `catch` and the fallback store (the `ControlRequestedStop`
   allocation is a safepoint) still lands `initialized`; an interrupt inside
   `_spawn!` between spawns leaves `tasks` unbound, so the direct release
   shuts down entries whose wrappers already run and never joins them. The
   reviewer also noted §11.6 never says `shutdown!` may run twice, which the
   `released` window can cause; one sentence there or in D-268 would settle
   it.
3. **The roster is read once per run** (`093012b`; gate green, 4061). Shape
   ruled by the coordinator: no new field, since D-260 puts the drain's
   bookkeeping off the `Run` and makes the stop policy the advance's
   argument; the copy is bound at the top of `_run_body!` and `step!` after
   the freeze and threaded as the pacer is, through `_advance!`, `frame!`,
   `_localized_frame!`, `publish!`, `_status`, `drain!`, `_replay_drain!`,
   `_reset_accounts!`, `report_thread_budget!`, `_init_devices!` and
   `_sweep_tail!`; the doors pass `sim.plane.roster`. The test reaches past
   the gate: a device empties `plane.roster` from its loop body, and every
   snapshot's status still names the two devices rostered at `run!`, with a
   datum report drained off the copy. Seven test files' direct calls of
   `drain!`/`publish!`/`frame!`/`report_thread_budget!` now pass the roster.
   Left: `companions/frame_walkthrough.md` still writes `drain!(sim)`,
   `publish!(sim)` and `frame!(sim, k)`, schematic already (no policy, no
   pacer). A rewrap of `_await_loop`'s comment landed as `078c4bf`.
4. **The log boxes each snapshot again** (`d5bb42d` docs, `d09f4cb` code;
   gate green, 4065). One deviation from the brief, the agent's, accepted:
   `@nospecialize` alone fails the ruling's check on a run past 511
   boundaries, since a dynamic read of an `Int` field returns a boxed `Int`
   that Julia caches only in -512..511 (16 B a frame from boundary 512 on,
   measured). `log!` therefore takes a third argument, the concrete snapshot
   type `publish!` knows statically, and reads the ordinal through it; the
   stores still reuse publication's box. `publish!` reloads `latest` with a
   monotonic load. `logged` is `Snapshot{T,typeof(sim.exec.store)}[]`, one
   spelling for the empty and the filled case, proven equal to
   `typeof(latest(sim))` by a test. The allocation test saw 816752 B on and
   off over 1000 frames of `feedback_model`. Left: the test costs about 9 s
   under BenchmarkTools' default budget; with a finite `log_max` in a run
   long enough to thin, a run allocates 1–3 KB more with the log on,
   probably the released slots growing the middle past its `sizehint!`
   before compaction, not investigated.
5. **§11.6's wrapper sketch** (`f8dafc7`). One line: the crash report is
   addressed by `entry`, as the code files it; the sketch still binds only
   `dev` and `handle`, so `entry` reads unbound there, as the ruling's own
   spelling has it. No prose sentence moved.

Nothing pushed. The arc from `7b69c23` is the user's to diff-review; the
cold review covered the interrupt fix alone, as ruled.
