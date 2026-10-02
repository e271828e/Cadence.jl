### 10.7 Real-time pacing

A real-time run must keep to wall-clock time, and its trajectory must not
depend on how fast it runs. [Pacing](#g-pacing) (the waits that hold a run to
wall-clock time) does the first without breaking the second. This section covers
the invariant with the wall-clock map, the wait, the diagnostics, and where
staging and concurrency live.

#### The invariant and the wall-clock map

**Pacing is outside the semantics** ([D-021][d-021]). That is the section's
invariant. The pacer inserts waits between completed [frames](#g-frame)
(iterations of the loop). It never reorders, skips or alters the
[boundary](#g-boundary) sequence. A paced and an unpaced run with identical
input [traces](#g-trace) (the records of each frame's drained inputs) produce
bit-identical trajectories. So deterministic [replay](#g-replay)
([§2.2][s2-2]) extends over pace. Interactive runs differ only because their
*inputs* differ.

Detection policy is inside the semantics. **Event localization runs
identically paced or unpaced** ([§10.4][s10-4], [D-080][d-080]). Its
[sweep](#g-sweep) cost is absorbed as debt (wall time that later
frames repay) like any other expensive frame ([D-080][d-080]). Degrading to
boundary detection under pacing was rejected ([D-080][d-080]).

**The wall-clock map is piecewise affine, re-anchored at every knee**
([D-021][d-021]). A knee is a point where the map changes slope or offset. A
pace change, an un-pause and a forgiveness re-anchor each make one. The map is
$\tau(t) = \tau_{\mathrm{anchor}} + (t - t_{\mathrm{anchor}})/p$, with the
anchor pair as its reference point. Here $p$ is the pace and $\tau$ is
wall-clock time. The anchor pair $(t_{\mathrm{anchor}}, \tau_{\mathrm{anchor}})$
is the sim time and wall-clock time at the most recent anchor. A live pace
change re-establishes the anchor at the current `(t, τ)`, so the new slope
applies only forward ([D-021][d-021]). Un-pause re-anchors for the same reason.
Debt is cleared at re-anchor. A deliberate user action is a natural sync point.
The counters record what was forgiven. The frame that follows an anchor has no
wait, because its deadline is the anchor itself. The run's first anchor is taken
when its loop starts, so the first frame runs at once ([D-269][d-269]).

**The deadline law is an absolute schedule with bounded debt**
([D-021][d-021]). Frame deadlines come from the map. A frame that exceeds its
wall budget `h/p` leaves debt. Subsequent frames repay it by running short or
without waiting. The long-run rate is therefore exact, and ms-scale hiccups
from GC or the scheduler are invisible.

**Debt beyond a threshold of five frames' worth of budget, `5·h/p`, is
forgiven** by re-anchor plus a warning ([D-133][d-133]). As a result, long
stalls (a debugger, laptop sleep) do not trigger catch-up bursts. Five frames'
worth sits comfortably above the ms-scale hiccups that debt exists to absorb
silently, and far below the seconds-to-minutes stalls that forgiveness exists
for. Neither case lands near the threshold.

**`p = ∞` is pacer-off, not a limit value** ([D-021][d-021]). Unpaced mode is
the explicit *absence* of deadlines. There are no waits, no debt and no
warnings. By the invariant, it is the same execution with the waits deleted.

#### The wait

**The wait mechanism is a hybrid sleep-then-spin with one knob**
([D-021][d-021]). Non-realtime OSes guarantee only a lower bound on sleep. The
thread becomes runnable no earlier than requested. The wake-up is best-effort,
subject to timer granularity, scheduler load and macOS timer coalescing, with
no hard upper bound. Measured on the dev machine, idle, against 2 ms requests
(2026-07), Julia `sleep` overshoots by about 1.4 ms median, and
`Libc.systemsleep` by about 0.5 ms. Behind the `sleep` figure are libuv's
millisecond-granularity timers. Sub-ms requests are accepted and rounded up.
Spikes under load are unbounded. The pacer therefore sleeps toward
`deadline − margin` and spins the remainder:

```julia
remaining = deadline - margin - τ()
remaining > 0 && sleep(remaining)   # coarse phase: cheap, lower-bound-only (runs at most once)
while τ() < deadline                # spin phase: µs-precise, CPU cost bounded by margin
    GC.safepoint()                  # a safepoint, never a yield: GC and signals get through
end
```

`margin` is a single constant calibrated to cover the primitive's granularity
*plus* typical overshoot ([D-021][d-021]). There is no second threshold. The
resolution floor is absorbed into the calibration. A margin below the
primitive's granularity defeats the spin phase's purpose.

**The default `margin` is 2 ms** ([D-133][d-133]), the value the measurements
above imply. It covers libuv's millisecond timer granularity and `sleep`'s
median overshoot of about 1.4 ms. Anything larger merely spends more core in
the spin phase. The knob spans the whole design space ([D-021][d-021]):

- `margin = 0` is pure sleep, the cheapest in CPU. Frame spacing is bursty,
  but the absolute schedule still delivers the exact *average* rate through
  debt repayment. The spin phase buys regularity, never rate correctness.
- `margin = 2 ms` is the hybrid default. It sleeps about 90% of a 20 ms budget
  and lands within µs of the deadline at a few percent of one core.
- `margin = ∞` is pure busy-wait, FlightCore's behavior, with maximum frame
  regularity at one pinned core. The "best attempt at real time" mode is the
  knob's endpoint, not a separate mechanism.

When the frame budget is at or below the margin (for example `h = 0.01` at
`p = 5`, a 2 ms budget), the hybrid degenerates to pure spin per frame by
construction. Rare wake-ups past the deadline are overruns, absorbed as debt.

Which primitive the coarse phase uses, task-yielding `sleep` or
thread-blocking `Libc.systemsleep`, is settled in [§12.2][s12-2]. The coarse
phase uses task-yielding `sleep`, with `margin` absorbing its overshoot
([D-027][d-027]).

The wait sits at the frame top, after the
[control plane](#g-control-plane) (the atomic surface carrying pause, pace and
stop) is consulted. A control change issued during a wait is observed at the
next frame top, at most one frame budget `h/p` later ([§12.1][s12-1],
[D-269][d-269]). The wait is an unmask point ([§12.4][s12-4],
[D-132][d-132]) for the [operator interrupt](#g-operator-interrupt) (Ctrl-C in
an interactive session). The interrupt raises out of the coarse phase's
`sleep`.

#### Diagnostics

Overrun count, current and peak debt, forgiven-debt events and wait
statistics are published as [framework status](#g-framework-status) (the
frozen diagnostics value each snapshot carries beside the signal table) for
GUI and logs. The record carries `pace`, the pace the loop's frames run
under (`Inf` where no frame waits). It carries `debt` and `peak_debt`, in
seconds, and `overruns`, the frames that exceeded their budget. It carries
`reanchors`, every re-anchor after the run's first, and `forgiven`, the
seconds of debt those re-anchors cleared. It also carries `waits` and
`waited`, the frames that waited and their total wall time ([D-269][d-269]).

A deliberate re-anchor, from a pace change or an un-pause, is counted and
raises no warning. The forgiveness re-anchor is counted and reports
`DebtReanchor` ([Appendix C][sC]). A live switch to `p = ∞` is a pace change
like any other. It re-anchors, and the debt it clears is counted as forgiven
([D-269][d-269]).

#### Where staging and concurrency live

The wait interval is the natural staging slot for externally injected inputs,
which are drained at the next frame top. The staging rules belong to
[§11][s11] and [§12][s12], as does the concurrency model generally.
[§10.3][s10-3] constrains the concurrency model but does not decide it.

---

