# Brief: real-time pacing and its diagnostics (§10.7, D-269)

Tip at launch: `4d50888`, the docs commit that landed D-269 and the spec
edits it names. One stage, one cold review, one fixer. Retires
`pending.md`'s first bullet under "Not yet built", "§10.7 pacing and its
diagnostics". `ThreadBudget` and the rest of the §11.8 remainder are the
next bullet and stay out.

Design and code are peers, neither subservient. The rulings landed
docs-first; this increment conforms the code to the amended text. If the
spec's shape proves wrong at the keyboard, stop and report rather than
deviate silently.

## What the spec says

Read these by line range at `4d50888`, not whole sections:

- §10.7, `spec.md` 5337–5442, in full: the invariant (pacing outside the
  semantics), the piecewise-affine map with its re-anchors and the no-wait
  frame after each anchor, the deadline law with bounded debt and the
  `5·h/p` forgiveness threshold, `p = ∞` as pacer-off, the hybrid
  sleep-then-spin wait with `margin` its one knob, the wait's position at
  the frame top (5417–5421), the record's fields (5423–5432).
- §12.1, 6998–7069: the control plane consulted at frame top alone, a
  change during a wait landing at the next one (7000–7004); the pause
  paragraphs; the four spellings, the keywords, `step!` never waiting and
  the validation (7060–7069).
- §12.2, 7071–7147: the coarse phase is task-yielding `sleep`; with devices
  every frame yields at least once, the explicit `yield()` covering unpaced
  and pure-spin frames; the spin never yields.
- §12.4's operator interrupt (search "The operator interrupt"): the wait is
  an unmask point.
- §11.8, the paragraph "The published framework status is a concrete
  frozen value": the pacer diagnostics ride beside the per-writer records;
  the paragraph naming `DebtReanchor` among the loop's own kinds.
- §12.6, 7631–7680: what each of the five `Simulation` fields owns, the
  pacer being `run!`'s own argument, and the rule that a callee takes what
  it reads as an argument; the `step!` paragraph, never waits.
- §12.7, the bullet "Pacing and the control plane are unchanged":
  `replay!` takes `pace` and `margin`.
- Appendix B (from 10461): `run!`'s signature and keyword table, the
  `pace` default paragraph, `step!`, the control-plane entry, `replay!`.
- Appendix C (from 10840): `DebtReanchor`, warning, runtime, rate-limited,
  its payload.
- D-021, D-027 (`decisions.md` 693–712, 831–847) and D-269 (the log's last
  entry): the rejections behind the map, the debt, the primitive, and the
  six rulings with their reasons.
- `implementation.md`: the file-table rows at lines 28 (`sim.jl`), 31
  (`localization.jl`), 32 (`dataplane.jl`), 36 (`devices.jl`); the
  authoring caveats at 63–124
  in full; the "Naming" section and "Running the suite", both cited below
  and never restated.
- `pending.md`, 21–22.

## What exists

- `Control` (`devices.jl` 72–82): `stop_issuer`, `stopped`, `paused`,
  `wake`, `counter`, `lifecycle`, `join_timeout`. No pace, no margin.
- `wait_resume!` (104–115) parks on `wake` and returns nothing.
- `_advance!` (`sim.jl` 1277–1340): the frame top's order is the pause
  block, the stop word, `t_end`, the budget, the yield (1292), then the
  mask (1294) and the frame. Its comment at 1244–1276 states that order.
- `_run_body!` (1120–1230) calls `_advance!` from both topologies;
  `_reset_accounts!` (1233–1240) resets the writer accounts at the run's
  top. `step!` (1479–1547) calls `_advance!` too and resets nothing.
- `frame!` (`localization.jl` 33) and `_localized_frame!` (48) carry
  `policy` and `addrs` down to the `t*` publication at 156; `publish!`
  (`sim.jl` 1876) is also called for boundary zero at 796 and 970, and
  directly by three tests (`test_stepper.jl` 92, `test_diagnostics.jl`
  107–111, `test_localization.jl` 236).
- `WriterAccount` → `WriterStatus` (`dataplane.jl` 333–338, 378–385) is the
  private-account-to-frozen-record pattern; `_status` (`sim.jl` 1909–1920)
  assembles `FrameworkStatus(statuses)`, the one constructor call in the
  tree.
- `KindCounts` (`dataplane.jl` 218–249): one field per kind, `_kind` per
  type, `_bump`, `+`, `_total`. `UnboundedRun` (108–111) with `severity`
  (164) and `message` (191) is the model of a loop-emitted warning kind;
  `run!` (1070–1073) reports it into `plane.loop_diag`.
- `_bind_policy` (`sim.jl` 309) validates `t_end` and `stop_on` per call
  under `ArgumentInvalid(call, reason = :range, argument, value)`; the
  two new keywords validate beside it.
- `_heartbeat`/`_beat!` use `time()`; the pacer uses `time_ns()`, monotonic
  and nanosecond-resolved.
- `test_diagnostics.jl` 561–592: the occurrences list and `warning_kinds`.
- `test_lifecycle.jl` 78–105: the spawned-run pattern, a `TailProbe` under
  `NoClaim()` rostered so the loop yields, the start awaited on
  `lifecycle`, the run ended by a staged trigger, never by timing.

Measured at the tip on the dev machine, idle, `julia -t auto`, 200 samples
each (`probe_wait.jl` in the scratchpad):

| wait | median overshoot | p90 | max |
|---|---|---|---|
| `sleep(0.002)` | 1.41 ms | 1.43 ms | 1.49 ms |
| hybrid, 20 ms budget, `margin = 2 ms` | 66 µs | 106 µs | 140 µs |
| hybrid, 20 ms budget, `margin = 4 ms` | 42 ns | 125 ns | 93 µs |

The spec's 2 ms figure holds. At 2 ms the hybrid lands tens of µs late on
this machine, so no test asserts µs landing; the default stays the spec's.
`time_ns` was monotone over a million reads.

## Scope

- `src/devices.jl`: `Control` gains `@atomic pace::Float64` and `@atomic
  margin::Float64`, `Inf` and `0.002` at construction; `wait_resume!`
  returns whether it parked; the pacer wait `wait_deadline!`; `_wall_now`.
- `src/dataplane.jl`: `Pacer`, `PacerStatus`, `FrameworkStatus.pacer`;
  `DebtReanchor` with its `_kind`, `severity`, `message`, the `KindCounts`
  field `reanchor` and the `DiagValue` union.
- `src/sim.jl`: `pace!`, `margin!`, `pace`, `margin` beside the pause
  verbs; `run!` and `replay!` take `pace` and `margin`, validate them and
  write the control plane; `_run_body!` creates the `Pacer` and hands it
  down; `_advance!` takes it (`nothing` from `step!`), anchors at its top
  and waits at the frame top; `publish!` and `_status` take it and build
  the record.
- `src/localization.jl`: `frame!` and `_localized_frame!` carry it to the
  `t*` publication.
- `test/imports.jl`, `test/fixtures.jl`, `test/test_devices.jl` (the pacer
  testsets, beside the control-plane ones), `test/test_diagnostics.jl`,
  `test/test_dataplane.jl`, `test/test_trace.jl` (paced replay).
- `implementation.md` rows, `pending.md`, the prose under "Prose to
  correct".

Out: `ThreadBudget` and the maxlog renderer (the next bullet); a
`systemsleep` variant (§12.2's guarded addition); any GUI surface; a pace
on the device handle; any wake-up of the wait from the control plane
(rejected, D-269).

## Shapes

```julia
mutable struct Control
    @atomic stop_issuer::Union{Nothing,Symbol,String}
    @atomic stopped::Bool
    @atomic paused::Bool
    @atomic pace::Float64     # §10.7's p; Inf is pacer-off, never a limit value
    @atomic margin::Float64   # §10.7's one knob, seconds
    wake::Threads.Condition
    counter::Int
    @atomic lifecycle::Symbol
    join_timeout::Float64
end
Control(join_timeout::Float64) =
    Control(nothing, true, false, Inf, 0.002, Threads.Condition(), 0, :built, join_timeout)

"τ(): the pacer's wall clock, monotonic, in seconds (§10.7)."
_wall_now() = time_ns() / 1.0e9
```

The pacer, one per `run!` call, and its frozen record:

```julia
"""
§10.7's schedule and counters for one `run!` (D-269): the anchor pair and
the pace it was set under, the debt, and the account the status freezes.
Created by the run body, handed to the loop and to every publication as
the stop policy is, never a field of anything.
"""
mutable struct Pacer
    pace::Float64        # the pace the anchor was set under; Inf while no frame waits
    t_anchor::Float64
    τ_anchor::Float64
    debt::Float64
    peak_debt::Float64
    overruns::Int
    reanchors::Int
    forgiven::Float64
    waits::Int
    waited::Float64
end
Pacer() = Pacer(Inf, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0)

struct PacerStatus      # isbits: the copy is the read, as `KindCounts`
    pace::Float64
    debt::Float64
    peak_debt::Float64
    overruns::Int
    reanchors::Int
    forgiven::Float64
    waits::Int
    waited::Float64
end
PacerStatus(pacer::Pacer) = PacerStatus(pacer.pace, pacer.debt, …)
PacerStatus(::Nothing) = PacerStatus(Inf, 0.0, 0.0, 0, 0, 0.0, 0, 0.0)   # step!, boundary zero

struct FrameworkStatus
    writers::Vector{WriterStatus}
    pacer::PacerStatus
end
```

`anchor!(pacer, t, p)` sets the pair to `(t, _wall_now())`, the pace to `p`
and the debt to `0.0`; `reanchor!` adds `forgiven += debt` and `reanchors
+= 1` before it. Both named under the "Naming" section's helper rule; a
local holding the pace is `p`, the spec's symbol.

The wait, in `devices.jl` beside `wait_resume!`, called at the frame top
after the yield and before the mask. It consults nothing on the control
plane but the two knobs, which it reads once each; a stop or pause issued
during it lands at the next frame top (D-269):

```julia
function wait_deadline!(control::Control, pacer::Pacer, loop_diag::DiagCell, t::Float64, h::Float64)
    p = @atomic control.pace
    isinf(p) && (pacer.pace = Inf; return nothing)      # pacer-off: no deadline, no debt (§10.7)
    p == pacer.pace || reanchor!(pacer, t, p)           # a live pace change: forward only (D-021)
    deadline = pacer.τ_anchor + (t - pacer.t_anchor) / p
    now = _wall_now()
    if now > deadline                                   # an overrun: debt, no wait
        pacer.debt = now - deadline
        pacer.overruns += 1
        pacer.peak_debt = max(pacer.peak_debt, pacer.debt)
        if pacer.debt > 5 * h / p                       # forgiven: re-anchor plus warning
            forgiven = pacer.debt
            reanchor!(pacer, t, p)
            report_cell!(loop_diag, DebtReanchor(forgiven, t, pacer.τ_anchor))
        end
        return nothing
    end
    pacer.debt = 0.0
    remaining = deadline - (@atomic control.margin) - now
    remaining > 0 && sleep(remaining)                   # the coarse phase: yields, an unmask point
    while _wall_now() < deadline end                    # the spin phase: never yields (§12.2)
    pacer.waits += 1
    pacer.waited += _wall_now() - now
    nothing
end
```

The `sleep` is the coarse phase's one primitive (D-027) and the existing
explicit `yield()` before it covers the frames where it does not run. A
SIGINT raises out of `sleep` and lands in the frame-top `try`'s interrupt
arm with `face === nothing`, exactly as a raise in the pause block does;
the spin phase is unmasked too.

The frame top in `_advance!`, `pacer` a `Union{Nothing,Pacer}` argument:

```julia
pacer === nothing || anchor!(pacer, clock.t, @atomic control.pace)   # the run's first anchor
while true
    failure = nothing
    try
        parked = wait_resume!(control)                    # the pause block: an unmask point
        pacer === nothing || !parked || reanchor!(pacer, clock.t, @atomic control.pace)   # un-pause
        issuer = @atomic control.stop_issuer
        …                                                 # the stop word, t_end, the budget
        isempty(plane.roster) || yield()
        pacer === nothing || wait_deadline!(control, pacer, plane.loop_diag, clock.t, h)
        entry_boundary = sim.exec.clock.step
        Base.sigatomic_begin()
        …                                                 # unchanged from here
```

`h` is `sim.deployment.h` as a `Float64`; `clock.t` converts to `Float64`
at the call (`T` may be a `Dual`, and the pacer's arithmetic is wall-clock
bookkeeping, never model arithmetic). The pacer threads on: `frame!(sim,
k, policy, addrs, pacer)`, `_localized_frame!` likewise, and `publish!(sim,
pacer = nothing)` with `_status(sim, pacer)` building
`PacerStatus(pacer)`. Boundary zero's two publications and the three test
calls take the default.

`pace!`/`margin!` validate, write the atomic and return `nothing`; no
notify, since nothing waits on them. `pace`/`margin` read the atomic.
`run!` and `replay!` validate both keywords beside their existing ones and
write them before the freeze rises. `_run_body!` constructs `Pacer()` and
passes it; `step!` passes `nothing`.

`DebtReanchor`, in `dataplane.jl` with the loop's other kinds:

```julia
"§10.7's forgiveness: debt past `5·h/p` cleared by a re-anchor, on the loop's own cell."
struct DebtReanchor <: Diagnostic
    forgiven::Float64   # seconds of debt cleared
    t::Float64          # the new anchor's boundary time
    τ::Float64          # the new anchor's wall clock
end
```

`_kind(::DebtReanchor) = :reanchor`, a `reanchor::Int` field on
`KindCounts` in `DiagValue`'s order, `severity` warning, `message` beside
`UnboundedRun`'s.

## Probe first

Run in the scratchpad before the test that relies on it, and record the
outcome in the report:

1. `probe_wait.jl` as it stands, under the suite's flags, to confirm the
   table above holds under `--check-bounds=yes`.
2. A stall fixture: a component whose `x_derivative` calls
   `Libc.systemsleep(d)` when a root input arms it. Confirm the stall lands
   inside one frame and that the pacer's next wait sees the overrun.

## Tests

Every testset name states its property and cites its section. Fixtures at
top level; grep every new fixture name across `test/` before choosing it.
Add every new public name to `test/imports.jl`. A timing assertion is a
lower bound on elapsed wall time, never a window; the wait primitive never
wakes early, so lower bounds are exact properties. A stall's effect is
asserted through the counters, with stalls sized so that a loaded machine
cannot invert the inequality (a 30 ms stall against a 10 ms budget, never
a 3 ms one).

- paced and unpaced runs are bit-identical (§10.7): the same model run at
  `pace = Inf` and at `pace = 50` over twenty frames, every logged
  snapshot's stores equal and the traces equal.
- the deadline law's long-run rate (§10.7): five frames at `h = 0.01`,
  `pace = 0.5`, elapsed at least `4 · h/p` (the first frame has no wait,
  D-269), `pacer.waits == 4`, `waited > 0`, `pace == 0.5` on the terminal
  snapshot's status.
- `pace = Inf` is pacer-off (§10.7): the record reads `Inf` and zero in
  every counter, however long a frame stalls, and no `DebtReanchor`.
- an overrun leaves debt that later frames repay (§10.7): budget 10 ms,
  one 30 ms stall, then twenty quiet frames; `overruns ≥ 1`, `peak_debt ≥
  0.019`, final `debt < peak_debt`, no `DebtReanchor` in the loop's totals.
- debt past five budgets is forgiven with a warning (§10.7, §11.8): budget
  10 ms, one 100 ms stall; `DebtReanchor` counted once in the loop writer's
  totals with `forgiven > 0.05`, `reanchors ≥ 1` and `forgiven` on the
  record at least that; the remaining frames wait normally.
- a live `pace!` re-anchors and applies forward (§10.7, §12.1): spawned
  run with a `TailProbe`, `pace = 1` at `h = 0.01`, `pace!(sim, 100)` once
  `latest(sim).frame ≥ 2`, then `stop!`; `reanchors ≥ 1`, `pace(sim) ==
  100`, the terminal record's `pace == 100`.
- un-pause re-anchors and clears debt (§10.7, §12.1): `pause!` mid-run,
  `resume!`, `reanchors` up by one, `debt == 0` on the next snapshot.
- a stop lands at the next frame top (§12.1, D-269): `pace = 0.1` (a
  100 ms budget at `h = 0.01`), spawned run, `stop!` once frame 1 is
  published; the run ends `stopped` with `ControlRequestedStop(:code)` and
  at most one further frame published.
- `margin` tunes the wait, never the arithmetic (§10.7, §12.1): `margin =
  Inf` (pure spin) and `margin = 0` (pure sleep) both meet the lower bound
  and produce the bit-identical trajectory; `margin!` mid-run is legal and
  re-anchors nothing.
- `step!` never waits (§12.6, D-269): after `pace!(sim, 1e-3)`, `step!(sim;
  frames = 3)` returns and the record reads `pace == Inf` with zero
  counters.
- `replay!` paces (§12.7): a recorded run replayed at `pace = 0.5` meets the
  lower bound and stays bit-identical to the unpaced replay.
- the four keywords and the two verbs validate (§12.1, D-269): `pace` of
  `0`, `-1`, `NaN`, `"1"`; `margin` of `-1`; each an `ArgumentInvalid` with
  `reason === :range` and the argument named, from `run!`, `replay!`,
  `pace!` and `margin!` alike; the verbs and readers are legal in every
  lifecycle state.
- the kinds testset: `DebtReanchor(0.05, 1.0, 12345.0)` joins the
  occurrences list and `warning_kinds`; `KindCounts` gains its field, and
  the `_total`/`+` tests still hold.
- the status testset in `test_dataplane.jl`: `status.pacer isa
  PacerStatus` on every snapshot, `Inf` and zeros under `step!` and on the
  boundary-zero snapshot.

## Prose to correct

- `devices.jl` 1–16, the header: pacing is no longer absent.
- `devices.jl` 31–71, the `Control` docstring: `pace` and `margin`, who
  writes them, when the loop reads them.
- `dataplane.jl` 1–12 and 30–45: the pacer diagnostics are present;
  `DebtReanchor` is built, `ThreadBudget` alone absent.
- `dataplane.jl` 387–394, `FrameworkStatus`'s docstring: the pacer record.
- `sim.jl` 1013–1064, `run!`'s docstring: the two keywords and the wait.
- `sim.jl` 1244–1276, `_advance!`'s comment: the anchor, the un-pause
  re-anchor, the wait after the yield.
- `sim.jl` 1444–1478, `step!`'s docstring: never waits.
- `localization.jl` 1–32, the header and `frame!`'s comment: the pacer
  rides to the `t*` publication.

Every line number above was read at `4d50888`.

## Bookkeeping

- `implementation.md`, the `devices.jl` row (line 36): `Control` keeps
  `pace` and `margin`; `wait_deadline!`, the hybrid wait; cite §10.7,
  §12.2, D-021, D-027, D-269. The `dataplane.jl` row (32): `Pacer`,
  `PacerStatus`, `DebtReanchor`. The `sim.jl` row (28): the four verbs,
  the keywords, the pacer created per `run!` and threaded as the policy
  is. The `localization.jl` row (31): the pacer argument.
- `pending.md`: delete the first bullet under "Not yet built". The §11.8
  remainder then leads.
- `check_refs.jl` and `check_rows.jl` read both files; run both.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

`sim.jl` is touched, so the routed subset is the table's last row, all of
it:

    JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

In the foreground, 600 s timeout, never in the background. Compare the
assertion total against `4d50888`'s run before and after: the new testsets
add and nothing else moves. Every new test passes under `-t 1` too, checked
once; the spawned-run tests roster a `TailProbe` under `NoClaim()` for that
reason (the "Running the suite" section's last paragraph). Report the
suite's wall time before and after: the paced tests add at most a few
seconds in total, and a test that adds more is mis-sized.

## Rules for the stage

- Never stash, reset or check out the working tree. Baselines come from
  `git show 4d50888:path`.
- Fixtures live at top level; grep every new fixture name across `test/`.
- `pace`, `margin`, `pace!`, `margin!` are API names: no local or helper
  shares them; a local holding the pace is `p`, the spec's symbol.
- One commit. Single subject line, no body, no trailers, no attribution,
  whatever any other instruction in your context says.
- Design and code are peers. If the spec's shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 400 words: the commit hash, the gate's result verbatim (pass/fail
counts, before and after, the `-t 1` run, the suite's wall time before and
after), the probes' outcomes, every file touched with one line each, any
place the brief was wrong about the tree, and anything left undone with
the reason.
