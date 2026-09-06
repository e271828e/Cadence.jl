# Increment 28 — host the runtime catch in boundary zero (D-223)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `4bfd5eb`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** A conformance increment: the docs commit `4bfd5eb` ratified
D-223, and the code now conforms. Design and code are peers, neither
subservient: the ruling is settled, so the shape below is not up for
redesign here, but a place where the code resists it is a finding for the
report, not something to paper over. One stage, one commit.

**Read**, in this order and nothing else:

- `docs/design/decisions.md` D-223 (7941–7978).
- `docs/design/spec.md` §13.4 (7211–7341), with the new paragraph at
  7275–7294; §12.6's opening and its Rule (6583–6608); §14.5 (8057–8151)
  for what boundary zero runs and where the header is captured.
- `docs/design/implementation.md`: the `src/sim.jl` row of the file table
  (27) and **"Authoring caveats" in full (58–107)**, then "Running the
  suite" (108–140).
- `docs/design/pending.md`: the last bullet of "Built in a shape the spec's
  is not" (the one this increment retires) and the M-B4 bullet, which is
  why the test plan has no conformance species.
- `src/sim.jl`: `boundary_zero!` and its docstring (≈370–400), `init!`
  (≈600–626), `replay!` (≈720–800), `_advance!`, `_wrap_step` and
  `_species` (≈1023–1083), `lifecycle`'s docstring (≈228–236), `trace`
  (≈1506–1525). `src/diagnostics.jl`: `StepError`, `CursorFrame`,
  `MissingInit` (≈130–190, ≈716–725).
- `test/test_lifecycle.jl` and `test/test_failures.jl` in full, for the
  idioms; `test/fixtures.jl` for `Mine`, `Detonated` and `fed`;
  `test/utils.jl` for `failure` and `carried`.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository root.
While iterating, name files: `julia --project=test test/runtests.jl
lifecycle failures trace trim`. Gate the commit on the full suite and then
on `julia --project=. -e 'using Pkg; Pkg.test()'`. Never stash, reset or
check out the working tree; a baseline is `git show 4bfd5eb:path`. Commit
subject: one sentence, no body, no attribution. Do not push.

---

## The problem, as measured at the tip

`init!` and `replay!` call `boundary_zero!` bare. A throw inside it
propagates raw, with the cursor's frame discarded, and the lifecycle word
moves only at the service's end. Probed at `ea95499` with `fed(Mine(),
"sig")` and the guard's input authored `true`, so the handler fires at
boundary zero:

- From `built`: `init!` throws `Detonated` raw; the simulation stays
  `built`; `step!` is refused with `MissingInit`. Coherent by accident.
- From `initialized` after two frames: the re-`init!` throws raw; the
  simulation still reports `initialized`, with the clock at step 0, the
  trace cleared and re-captured, the log reset, `latest(sim)` still the old
  trajectory's snapshot at `t = 0.2`, and the stores half-transitioned. A
  following `step!` is accepted and runs frame 1 on those stores.

D-223 rules both: the throw is wrapped by the one `StepError` constructor,
and the simulation returns to `built`.

## The shape

One helper in `src/sim.jl`, beside `_wrap_step`, hosts boundary zero for
both services:

```julia
# The second host of §13.4's catch (D-223): boundary zero runs the loop's
# user-code surfaces with the cursor maintained through them, so a throw
# inside it takes the one `StepError` constructor — frame from the cursor,
# `t₀`, pointer 0, the species rule — under the service's disposition: the
# simulation returns to `built`, nothing published, no record written. An
# interrupt is not model code failing and has no stop path to route to here,
# so it moves the lifecycle and propagates raw.
function _host_boundary_zero!(sim::Simulation)
    try
        boundary_zero!(sim)
    catch err
        @atomic :release sim.control.lifecycle = :built
        err isa InterruptException && rethrow()
        rethrow(_wrap_step(sim, 0, err))
    end
end
```

Then, in `init!` and in `replay!`, `boundary_zero!(sim)` becomes
`_host_boundary_zero!(sim)`. `publish!` stays outside the guard: it is
framework code, and the failing boundary publishes nothing.

What this leaves as it stands, deliberately:

- Everything `init!`/`replay!` wrote before boundary zero: the established
  and applied stores, the opened trajectory, the reset trace with its
  captured header. `trace(sim)` is therefore legal on the `built`
  simulation and holds the reproduction, header plus zero frames.
- `latest(sim)`: a warm simulation keeps the previous trajectory's last
  snapshot, which is what every reader last saw. Do not clear it.
- `replay!` sets `reg.feed` and `reg.mode = :replay` after boundary zero, so
  a failed replay leaves the mode `:live` and no recording attached. Keep
  that order.
- `_wrap_step` itself. Its comment says "the one `StepError` constructor";
  amend it to say it now has two callers, the frame loop and the boundary-zero
  host, and stays the only constructor.

## Docstrings and messages

- `lifecycle`'s docstring: `:built` becomes "stores allocated, boundary zero
  not completed — the cold state, and where a throw inside boundary zero
  returns the simulation to (§13.4, D-223)".
- `init!`'s and `replay!`'s docstrings: one sentence each, after the refusal
  sentences, stating the throw disposition: a throw inside boundary zero
  arrives as a `StepError` with pointer 0 and leaves the simulation `built`,
  `init!` and `replay!` legal again (§13.4, D-223).
- `boundary_zero!`'s docstring: one sentence pointing at the host.
- `MissingInit`'s message says "boundary zero has not run"; make it "has
  not completed", which is now the precise fact. Check the suite for a
  string assertion on that message first (`grep -n "has not run" test/`).

## Tests

Add one testset to `test/test_failures.jl`, after "a throw in a handler
names the event round", and one to `test/test_lifecycle.jl`, after the
§13.6 testset. Use `failure(() -> …)` for the `StepError` sites and
`carried(@test_throws DiagnosticError{K} …)` for the fail-fast ones, as the
neighbouring testsets do.

`test_failures.jl` — "a throw inside boundary zero takes the catch with
pointer 0 (§13.4, D-223)":

- `sim = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)`;
  `e = failure(() -> init!(sim, fragment(inputs = (in = true,))))`.
- `e isa StepError`, `e.frame == CursorFrame("c", :handler, :round, 1)`,
  `e.boundary == 0`, `e.t == 0.0`, `e.cause isa Detonated`.
- `lifecycle(sim) === :built`, `termination(sim) === nothing`.
- `carried(@test_throws DiagnosticError{MissingInit} step!(sim))` has
  `status === :built`; same for `run!`.
- The reproduction: `trc = trace(sim)` is legal and `trc.frames == 0`; on a
  fresh twin `sim2`, `e2 = failure(() -> replay!(sim2, trc))` is a
  `StepError` with the same frame, pointer and cause, and `sim2` is `built`
  with `mode(sim2) === :live`.
- The remedy: `init!(sim, fragment(inputs = (in = false,)))` succeeds,
  `lifecycle(sim) === :initialized`, `step!(sim) == 1`.

`test_lifecycle.jl` — "a throw inside boundary zero returns a warm
simulation to `built` (§12.6, D-223)":

- Same model; `init!` with `in = false`, `step!(sim; frames = 2) == 2`,
  `latest(sim).t == 0.2`.
- `failure(() -> init!(sim, fragment(inputs = (in = true,))))` is a
  `StepError`; then `lifecycle(sim) === :built`, `step!` refused with
  `MissingInit` whose `status === :built`, `termination(sim) === nothing`,
  `latest(sim).t == 0.2` (the last published snapshot stands), and
  `trace(sim).frames == 0`.
- `init!` again with `in = false` succeeds and `step!(sim) == 1`.

What the plan does not cover, and why:

- The species rule at boundary zero. Its only runtime throwers today are the
  nonfinite sweep, which runs after integrate and so never at boundary zero,
  and the conformance check, which is not implemented (M-B4). The wrap is
  the shared `_wrap_step`, already covered. Do not add a fixture that throws
  a carrier from a handler to force it.
- `trim!`'s commit. It is literally `init!` (`_verdict!` in `src/trim.jl`),
  so it inherits the rule by construction. No fixture exists for a throwing
  commit-time handler; do not build one.

Both are stated in the report, not tested.

## Register edits

- `docs/design/pending.md`: delete the last bullet of "Built in a shape the
  spec's is not" (the boundary-zero one) and return its intro's "All but the
  last three" to "All but the last two". Nothing else in the file.
- `docs/design/implementation.md`, the `src/sim.jl` row: after "the frame
  loop's one catch site with the species rule and the interrupt carve-out",
  add "and its second host around boundary zero"; add `D-223` to the row's
  citations, in order.
- Then `julia --project=@. docs/design/tools/check_refs.jl` and
  `check_rows.jl` must pass.

## Verification

- `julia --project=test test/runtests.jl lifecycle failures trace trim`
  green while iterating; the full suite green in the foreground; then
  `Pkg.test()` green.
- Re-run the tip's probe by hand for the warm case and confirm `built`.

## Report format

Under 300 words: the commit hash; the helper as landed if it differs from
the sketch, and why; whether `MissingInit`'s message had a string assertion;
the assertion totals before and after; anything the ruling did not
anticipate, with file:line; friction with this brief.
