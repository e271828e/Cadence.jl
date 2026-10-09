# The control plane (§12.1) and the pacer that rides on it (§10.7): the few
# atomic words anyone may poke — the stop word, the pause flag, the two pacing
# knobs — beside §12.3's counter-plus-condition wait, the running flag and
# §12.4's join cap; the stop word's one write path; the pause block; the two
# lifecycle gates; and the pacer's schedule with its wait, the hybrid
# sleep-then-spin of §10.7 and §12.2. Included ahead of devices.jl, whose
# handle reads the control plane, and of sim.jl, whose loop consults it at
# frame top and calls the verbs on it (`stop!`, `pause!`, `pace!`, …, defined
# there beside `attach!`). The pacer's frozen record, `PacerStatus`, stays in
# dataplane.jl beside the status it rides in.

"""
The control surface — §12.1's stop and the running flag. `stop_issuer` is
the control-plane stop word, and it carries its issuer (D-203): set by
`stop!` from any task through a compare-and-swap from `nothing` — the first
writer wins, so the recorded issuer is the request that actually initiated
the tail — consulted for non-empty by the loop at frame top, cleared at the
top of the next run (which is what lets an init bracket's `should_abort`
failure leave a stop *already pending* at the run's start, §12.4) and at
`init!` (a fresh trajectory owes nothing to the last one's stop). `stopped`
is §12.4(1)'s sticky status: set only after the final snapshot is published,
and read by `running(handle)`, which is how loop bodies observe the run's
end.

`paused` is §12.1's pause flag (D-268): set by `pause!(sim)` and cleared by
`resume!(sim)`, from any task in any lifecycle state. The loop consults it at
frame top, before the stop word, and parks on `wake` while it holds and no
stop is pending: `resume!` and every stop request notify `wake`, so a stop
issued while paused ends the run at that frame top (§12.4(2)). The tail
clears it beside `stopped`; a run's start never does, which is what lets a
`pause!` before `run!` start the run paused.

`running` is the §11.3 freeze (D-317): set as `run!` or `step!` takes the
loop, and it deliberately spans the whole of the call — tail included, the
flag clearing in the outermost `finally` — while `stopped` flips at tail
step (1), so device loops exit while the joins are still ahead. §12.6's
lifecycle is stored nowhere: `lifecycle(sim)` derives it from this flag, the
model's status and whether the run is closed. A run's *outcome* is not a
control surface, so §13.5's termination record is the `Run`'s and not here
(§12.1, §12.6, D-255); the control plane is what anyone may poke.

`wake` and `counter` are §12.3's two artifacts: the counter counts *published
boundaries* — grid, `t*`, boundary zero — mirrored under the lock right
behind each release-store of `latest`, in that normative order, so a waiter
observing `counter > last_seen` can never wake onto a stale snapshot. The
counter is monotonic across runs and never re-armed: its absolute value is
nowhere normative, and monotonicity keeps the predicate sound with no
per-run reset.

`pace` and `margin` are §10.7's two knobs (D-269): the pace `p`, `Inf` being
pacer-off rather than a limit value, and the wait's coarse/spin split in
seconds, 2 ms by default. `pace!(sim, p)` and `margin!(sim, m)` write them
from any task in any lifecycle state, and `run!` and `replay!` write their
keywords at entry. The loop reads them at frame top alone, `pace` for the
anchor and both in the wait, so a change issued while a frame runs or waits
lands at the next frame top; nothing notifies, since nothing waits on them.

`join_timeout` is §12.4's shutdown cap in seconds, validated at
materialization and fixed for the simulation's life: the tail runs here, so
the parameter it waits under is `Control`'s (§12.1, D-256).
"""
mutable struct Control
    @atomic stop_issuer::Union{Nothing,Symbol,String}
    @atomic stopped::Bool
    @atomic paused::Bool
    @atomic pace::Float64     # §10.7's p; Inf is pacer-off, never a limit value
    @atomic margin::Float64   # §10.7's one knob, seconds
    wake::Threads.Condition
    counter::Int
    @atomic running::Bool
    join_timeout::Float64
end
Control(join_timeout::Float64) =
    Control(nothing, true, false, Inf, 0.002, Threads.Condition(), 0, false, join_timeout)

# The stop word's one write path (§12.1, D-203): first CAS from empty wins —
# the same arbitration as the loop reacting to the first holding stop request —
# and a later issuer is dropped, the tail already having its initiator. The
# notify wakes a loop parked in the pause block (§12.4(2)); no caller holds
# the lock.
function _request_stop!(control::Control, issuer::Union{Symbol,String})
    @atomicreplace control.stop_issuer nothing => issuer
    lock(control.wake)
    try
        notify(control.wake)
    finally
        unlock(control.wake)
    end
    nothing
end

# The pause block (§12.1): the loop parks here at frame top while the flag is
# set and no stop is pending, woken by `resume!` or a stop request. Returns
# whether it parked, the un-pause being a re-anchor (§10.7). An unmask point
# (§12.4): an interrupt delivered inside the wait raises out of it, the lock
# released.
function wait_resume!(control::Control)
    (@atomic control.paused) || return false
    parked = false
    lock(control.wake)
    try
        while (@atomic control.paused) && (@atomic control.stop_issuer) === nothing
            parked = true
            wait(control.wake)
        end
    finally
        unlock(control.wake)
    end
    parked
end

"""
The §11.3 freeze, keyed on the simulation's lifecycle (§12.6), as two gates.
The readers' gate, `assert_stopped`, refuses exactly while `run!` or `step!`
holds the simulation `:running` — which spans the tail, so a roster change
cannot race the joins — and admits every other state, `:errored` included:
post-mortem inspection of a terminally stopped simulation is reading (§13.6).
The roster's gate, `assert_configurable`, adds `:errored` to the refusals
(D-232): a roster change configures the next run, and an errored simulation
has none. Both take the simulation, whose `lifecycle` is defined in sim.jl
(D-317).
"""
assert_stopped(sim, op::Symbol) =
    lifecycle(sim) === :running ?
    throw(DiagnosticError(ServiceLifecycle(op = op, status = :running,
                                           legal = collect(READER_LEGAL)))) : nothing

function assert_configurable(sim, op::Symbol)
    lifecycle_state = lifecycle(sim)
    lifecycle_state === :running && throw(DiagnosticError(ServiceLifecycle(
        op = op, status = :running, legal = collect(STOPPED_SIM_LEGAL))))
    lifecycle_state === :errored && throw(DiagnosticError(ServiceLifecycle(
        op = op, status = :errored, legal = collect(STOPPED_SIM_LEGAL))))
    nothing
end

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

"τ(): the pacer's wall clock, monotonic, in seconds (§10.7)."
_wall_now() = time_ns() / 1.0e9

# §10.7's anchor: the map's reference pair set to `(t, τ())` under the pace
# `p`, the debt cleared. The run's first is taken as its loop starts (D-269).
function anchor!(pacer::Pacer, t::Float64, p::Float64)
    pacer.pace = p
    pacer.t_anchor = t
    pacer.τ_anchor = _wall_now()
    pacer.debt = 0.0
    nothing
end

# Every anchor after the run's first: a pace change, an un-pause or the
# forgiveness, the debt it clears counted as forgiven (§10.7, D-021).
function reanchor!(pacer::Pacer, t::Float64, p::Float64)
    pacer.forgiven += pacer.debt
    pacer.reanchors += 1
    anchor!(pacer, t, p)
end

# §10.7's wait, at the frame top after the yield and before the mask (D-269):
# the deadline off the piecewise-affine map, an overrun left as debt and
# forgiven past `5·h/p` with `DebtReanchor` on the loop's own cell, otherwise
# the hybrid sleep-then-spin toward it. It reads the two knobs once each and
# nothing else on the control plane: a stop or pause issued during it lands at
# the next frame top. The frame after an anchor has no wait, its deadline
# being the anchor itself. The `sleep` is the coarse phase's one primitive
# (§12.2, D-027), task-yielding and an unmask point (§12.4); the spin never
# yields, and its safepoint lets a collection or a signal through.
function wait_deadline!(control::Control, pacer::Pacer, loop_diag::DiagCell, t::Float64,
                        h::Float64)
    p = @atomic control.pace
    p == pacer.pace || reanchor!(pacer, t, p)           # a live pace change, Inf too (D-021, D-269)
    isinf(p) && return nothing                          # pacer-off: no deadline, no debt (§10.7)
    t == pacer.t_anchor && return nothing               # the anchor is this frame's deadline
    deadline = pacer.τ_anchor + (t - pacer.t_anchor) / p
    now = _wall_now()
    if now > deadline                                   # late: debt, no wait
        # An overrun grows the debt; a frame that merely repays debt is not
        # one (§10.7, D-269).
        debt = now - deadline
        debt > pacer.debt && (pacer.overruns += 1)
        pacer.debt = debt
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
    while _wall_now() < deadline                        # the spin phase: never yields
        GC.safepoint()                                  # a safepoint, not a yield (§12.2, D-027)
    end
    pacer.waits += 1
    pacer.waited += _wall_now() - now
    nothing
end

# The record's copy off a live pacer (§10.7): isbits, one read per field.
PacerStatus(pacer::Pacer) =
    PacerStatus(pacer.pace, pacer.debt, pacer.peak_debt, pacer.overruns, pacer.reanchors,
                pacer.forgiven, pacer.waits, pacer.waited)
