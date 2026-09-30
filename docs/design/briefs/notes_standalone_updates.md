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
