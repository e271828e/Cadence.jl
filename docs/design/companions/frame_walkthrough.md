# One frame, end to end: the loop mapped to the implementation

*Companion explainer, non-normative. The spec ([§10.4][s10-4], [§10.5][s10-5], [§10.6][s10-6]; the seam
in [§10.2][s10-2], publication in [§11.2][s11-2]) wins wherever the two disagree. Written
against the tree at `f40585e` ([D-232][d-232]): every function named here is the
implementation's, and the code moves more often than the spec. Function names
are given without line numbers for that reason; `grep` finds them.*

This document follows a single frame through the frame loop and names, at
each step, the function that performs it. It exists because the spec states
the loop's rules across four sections, and the implementation spreads their
mechanics across four files: `sim.jl` owns the loop and the boundary entries,
`localization.jl` the in-frame localization, `stepper.jl` the integration
seam, and `executor.jl` the compiled sweeps and the event registers. A reader
who has both open can follow one frame here and know which rule each line
serves.

The running example is a deployment with `h = 0.01` and `N_base = 4`, so
`Δt_base = 0.04` and only every fourth frame top is a base tick. The model
holds a continuous plant with a localized sign-form guard, and a discrete
controller with `(D, Φ) = (1, 0)`, which ticks at every base tick. The frame
followed is `k = 8`, whose top `t = 0.08` is base tick `2`; section 3 notes
where frame `k = 7`, an off-tick frame top, differs.

## Section 1 — The frame loop and the drain

**The frame top.** One iteration of `_advance!` in `sim.jl` is one frame. It
checks the stop word and the frame bound, drains, integrates, runs the
boundary, publishes, and samples the stop faces:

```julia
entry = sim.exec.clock.step
drain!(sim)
k = (sim.exec.clock.step += 1)
frame!(sim, k)
if pol.hit === nothing
    k % sim.N_base == 0 ? boundary!(sim, k ÷ sim.N_base) : offtick_boundary!(sim)
    publish!(sim)
    face = _stop_hit(sim, pol)
```

Three things happen in order. `drain!` applies the device writes, `frame!`
carries the continuous state across `[t₇, t₈]` and fires any localized event
inside it, and one of two boundary entries runs at the frame top. For `k = 8`
the selector picks `boundary!(sim, 2)`, the tick index being `k ÷ N_base`. For
`k = 7` it picks `offtick_boundary!`. This selector is the whole of the
frame/tick discrimination [§10.5][s10-5] describes: the gate reads a tick index, and an
off-tick frame top has none.

**The drain.** `drain!` sets the cursor's phase to `:drain`, records the frame
ordinal the trace will file this frame's batches under ([§11.5][s11-5]), and swaps each
roster entry's staged batch into the root-input cells through the entry's
compiled drain thunk. The harness cell drains last, and the diagnostic cells
fold into the per-writer accounts at the same point ([§11.8][s11-8]). In `:replay` the
branch reads the recording instead ([D-101][d-101]). The root inputs are now the values
every sweep in this frame reads, which matters for the validation in
section 2: a root input that flips a guard here is an edge with no in-frame
crossing.

## Section 2 — Integration and localization

**`frame!`** in `localization.jl` computes the frame top from the index,
never by accumulation, and picks the path:

```julia
t_to = _grid_time(sim, k)                      # t₀ + k·h
sim.has_localized ? _localized_frame!(sim, t_to) : step!(sim, T(sim.h))
sim.policy.hit === nothing && (sim.exec.clock.t = t_to)
```

A model with no localized events takes one bare `step!`. Ours enters
`_localized_frame!`, whose loop integrates one segment per turn: the whole
frame first, then a remainder from each `t*`.

**One integration segment.** `step!(sim, h′)` in `sim.jl` sets the cursor
phase to `:integrate` and crosses the stepper seam ([§10.2][s10-2]) to the backend's
`step!(::RK4, sim, h)` in `stepper.jl`:

```julia
copyto!(x₀, x)
evaluate!(sim); copyto!(k₁, ẋ)
_advance!(x, x₀, k₁, h / 2); sim.exec.clock.t = t₀ + h / 2
evaluate!(sim); copyto!(k₂, ẋ)
...
x[i] = x₀[i] + (h / 6) * (k₁[i] + 2k₂[i] + 2k₃[i] + k₄[i])
```

Each RK stage is one `evaluate!`, and evaluating the right-hand side means
running the sweep ([§5.3][s5-3]):

```julia
ex.cursor.index += 1
ex.bodies.sweep_1()      # output_state block, interior variant
ex.bodies.sweep_2()      # output_direct block, interior variant
ex.bodies.rhs()          # state_derivative block
```

The zero-argument call on a `PhaseBody` in `executor.jl` walks the interior
chunk tuple, which `chunked_body` compiled from continuous entries only
([D-147][d-147]). Each `run_entry!(::StageEntry)` calls the author's stage on a bundle of
views and scatters the returned ports into the table; each `run_entry!(::RHSEntry)`
writes the derivative into `ẋbuf`. The controller's output cells are not
touched at any of the four stages. That is the zero-order hold, by absence
rather than by a runtime test ([§10.5][s10-5]). On return, `_check_finite!` sweeps `x`
before anything reads it ([§13.4][s13-4]).

**Arrival sweep and trigger.** Back in `_localized_frame!`, the state is at
`t₈` in the buffer. One interior sweep refreshes the table, `_guards!` in
`executor.jl` evaluates every guard into the predicate register `now` and the
numeric register `σ`, and the arrival samples are kept as `σ1`:

```julia
es.trig[i] = es.localized[i] && !es.prior[i] && es.σ1[i] ≥ 0
```

An event triggers when its policy is localized, its prior at the last settled
boundary was not-holding, and it holds now ([§10.4][s10-4]). If nothing triggers the
function returns and the frame goes straight to section 3. Say the plant's
guard triggered.

**The θ = 0 validation.** The frame-start state is recovered from the seam's
retained `startpoint`, put back in the buffer with the clock at `t_seg`, and
swept once more:

```julia
copyto!(sim.exec.xbuf, x₀); sim.exec.clock.t = t_seg
sim.exec.bodies.sweep_1(); sim.exec.bodies.sweep_2(); _guards!(es)
copyto!(es.σ0, es.σ)
es.trig[i] = es.trig[i] && es.σ0[i] < 0
```

This is where a drain-caused edge is filtered out. If the guard already holds
at `θ = 0` with this frame's inputs, there is no crossing inside the frame:
the trigger is dropped, the arrival state is restored, and the event fires in
the frame-top boundary's own iteration instead. It consumes no budget. The
reasoning is `localization_validation_walkthrough.md`'s.

**Root-finding.** One `evaluate!` at the arrival state pays `ẋₙ₊₁`,
completing the four values the cubic Hermite interpolant needs. Then
`_crossing` runs ITP ([D-018][d-018]) on `θ ∈ [0, 1]`, each iteration one `_trial!`:

```julia
dense!(sim.stepper, sim.exec.xbuf, sim.xnext, sim.ẋnext, θ, h′)
sim.exec.clock.t = t_seg + θ * h′
sim.exec.bodies.sweep_1(); sim.exec.bodies.sweep_2()
_guards!(sim.exec.events)
```

`dense!` in `stepper.jl` writes `x̂(θ)` from `(x₀, ẋ₀)` and `(x₁, ẋ₁)`. A
trial is an interior sweep on raw, unprojected state; the discrete cells hold
through every trial. The cursor phase `:trial` with the iteration ordinal is
what a `StepError` reports if a guard throws here ([§13.4][s13-4]). The earliest `θ★`
across the triggered events wins, and a `θ★` of exactly one is discarded as a
crossing at the frame top.

**The `t*` boundary.** The interpolated state goes into the buffer, the clock
moves to `t* = t_seg + θ★·h′`, and the boundary runs as an off-tick boundary:

```julia
dense!(sim.stepper, sim.exec.xbuf, sim.xnext, sim.ẋnext, θ★, h′)
sim.exec.clock.t = t_seg + θ★ * h′
offtick_boundary!(sim)
publish!(sim)
```

`offtick_boundary!` in `sim.jl` is projection followed by the event phase,
with no tick argument:

```julia
_projects!(sim.exec.events)
event_phase!(sim, nothing)
```

Projection first. `_projects!` walks every `ProjectEntry`, and `run_project!`
reconstructs each component's `x` from the buffer, applies
`state_projection`, and writes it back wholesale ([§5.3][s5-3]). Authority over the
state rests here, not with the raw trials.

Then `event_phase!` ([§10.6][s10-6]). Round one is the boundary sweep,
`_round!(ex, nothing)`, which is the two zero-argument sweeps: the same
interior walk, with no discrete entry in it ([D-185][d-185]). The registers are then
armed for this boundary, `last` from `prior`, counts and warned flags cleared,
and the iteration runs:

```julia
_guards!(es)
for i in 1:n
    edge = !es.last[i] && es.now[i]
    eligible = edge && es.count[i] < budget
    firing = eligible && !es.comp_fired[es.owner[i]]
    ...
end
any_fired || break
_fire!(es)
_round!(sim, tick)
```

An event fires when it presents an edge, its firing count is below
`firing_budget`, and no event of the same component fired this round. An
eligible-but-blocked event keeps its edge for the next round ([D-191][d-191]). `_fire!`
in `executor.jl` runs the handler, `_latch!` writes the returned `x` into the
buffer and merges `m` into the mode store, and `_fire_project!` re-projects
that component. A fresh sweep follows, and the loop goes around until a round
fires nothing. At quiescence the priors are updated from the settled samples.
The controller played no part in this boundary: `t*` is off the grid, so its
due set is empty by construction.

`publish!` then captures a snapshot, appends it to the log, and bumps the wait
counter ([§11.2][s11-2], [D-230][d-230]). The `t*` snapshot is a published consistency point
like any other, and `_stop_hit` samples the stop faces on it ([§13.5][s13-5]). If none
holds, the localization count increments and the loop turns again.

**The remainder.** The next turn sets `t_seg = t*` and `h′ = t₈ − t*`, and
`step!(sim, h′)` runs a full RK4 step from the post-handler state. A one-step
method restarts from a new state at no cost, which is why the seam admits
nothing else ([D-017][d-017]). The arrival sweep at `t₈` finds no new edge,
`_localized_frame!` returns, and `frame!` stamps the clock at `t₈`. Had the
remainder triggered again, the loop would localize once more, up to
`localization_budget` per frame, after which further crossings are left to
the frame-top boundary under a `ChatteringBudget` warning ([§10.4][s10-4]).

## Section 3 — The frame-top boundary and publication

**The tick boundary, `boundary!(sim, 2)`** in `sim.jl`:

```julia
_projects!(sim.exec.events)
event_phase!(sim, tick)
sim.exec.bodies.ticks(tick)
```

The difference from the `t*` boundary lies in the argument.
`_round!(ex, tick::Int)` calls `sweep_1(tick)` and `sweep_2(tick)`, the
one-argument variant of the phase body, which walks the full chunk tuple.
Continuous entries run through the fallback `run_at!` unchanged. Each discrete
entry wears a `Gated` wrapper whose `run_at!` is the [§10.5][s10-5] gate:

```julia
(tick - g.Φ) % g.D == 0 && run!(g.e, store, xbuf, ẋbuf)
```

With `tick = 2` and `(D, Φ) = (1, 0)` the controller is due. Its
`output_state` runs in the stage-1 walk from the current `s`, its
`output_direct` in the stage-2 walk from the freshly swept inputs, and its
cells now carry `y[k]` computed from `s[k]`. The event iteration proceeds as
at `t*`, and every re-sweep of the iteration uses the same due set, since the
tick index is the boundary's and does not change between rounds.

After quiescence, `bodies.ticks(tick)` walks the update block through the
same gate. `run_entry!(::UpdateEntry)` computes `state_update` off the settled table
and writes `s[k+1]` into the component's store. Updates run last, so they read
post-transition values, and they run after the output stages, so the
sampled-data recursion holds by construction: outputs from `s[k]`, then the
update to `s[k+1]` ([§10.6][s10-6]).

**The off-tick frame top.** For frame `k = 7` the selector picks
`offtick_boundary!` instead. Projection and the event phase run in full, the
sweeps are the zero-argument ones, and no `ticks` body runs at all. The
controller's cells still hold the values it published at `t = 0.04`, and its
`s` is untouched until `t = 0.08`.

**Publication.** `publish!` builds the snapshot from the clock, the boundary
ordinal and a capture of the store, then releases it and wakes device waiters
([§11.2][s11-2]). `_stop_hit` samples the stop faces on that snapshot. If one holds,
the loop returns `ModelRequestedStop(face)` ([§13.5][s13-5]). Otherwise the loop
proceeds to the next frame top, and the cursor's trail restarts: `:drain`,
`:integrate`, `:arrival`, `:validation`, `:trial`, `:project`, `:round`,
`:ticks`, the sequence a `StepError`'s frame is read from ([§13.4][s13-4]).

**Boundary count.** Frame 8 in this example published twice, at the `t*`
boundary and at the tick boundary. Frame 7 without an event publishes once, at
the off-tick boundary. The frame index advanced by one in both cases and the
tick index only at frame 8, which is what the code's `k ÷ N_base` expresses.

## Section 4 — Boundary zero, for contrast

`init!` and `replay!` run boundary zero through `_host_boundary_zero!`, which
calls `boundary_zero!` under the catch that returns a throwing simulation to
`built` ([§13.4][s13-4], [D-223][d-223]). The sequence is the ordinary one with one difference:
`event_phase!(sim, ESTABLISH)` passes a marker in place of a tick index, and
`run_at!` on a `Gated` entry admits every discrete output stage against it,
due or not ([§14.5][s14-5], [D-205][d-205]), so the `t₀` snapshot carries the authored world
fully evaluated. The update block keeps the ordinary gate at index `0`, which
under the canonical residue admits exactly the `Φ = 0` components ([§10.5][s10-5]).
Nothing in the frame loop above is entered: boundary zero has no integrate and
no drain.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-017]: ../decisions.md#d-017--framework-owned-simulation-loop-with-a-stepper-seam
[d-018]: ../decisions.md#d-018--tier-2-event-localization-via-dense-output-and-bracketed-root-finding
[d-101]: ../decisions.md#d-101--implement-replay-as-the-ordinary-loop-with-two-substitutions
[d-147]: ../decisions.md#d-147--split-the-sweep-into-static-interior-and-boundary-variants
[d-185]: ../decisions.md#d-185--adopt-the-phased-two-form-sample-time-declaration
[d-191]: ../decisions.md#d-191--defer-not-consume-the-edge-on-a-blocked-event
[d-205]: ../decisions.md#d-205--boundary-zero-publishes-every-discrete-output-stage-due-or-not
[d-223]: ../decisions.md#d-223--host-the-runtime-catch-in-boundary-zero-under-the-services-disposition
[d-230]: ../decisions.md#d-230--stamp-the-snapshot-with-the-trajectorys-boundary-ordinal-not-the-wait-counter
[d-232]: ../decisions.md#d-232--refuse-the-roster-operations-on-an-errored-simulation
[s10-2]: ../spec.md#102-the-stepper-seam
[s10-4]: ../spec.md#104-localization-mechanics
[s10-5]: ../spec.md#105-multi-rate-tick-scheduling
[s10-6]: ../spec.md#106-event-iteration-at-boundaries-to-quiescence-budgeted
[s11-2]: ../spec.md#112-outbound-snapshot-publication
[s11-5]: ../spec.md#115-inbound-the-input-trace
[s11-8]: ../spec.md#118-diagnostics-and-liveness-the-per-writer-cell
[s13-4]: ../spec.md#134-runtime-failures-one-catch-site-an-execution-cursor
[s13-5]: ../spec.md#135-termination-is-a-state-not-an-exception
[s14-5]: ../spec.md#145-boundary-zero-an-ordinary-boundary-with-authored-incoming-transitions
[s5-3]: ../spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
