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
