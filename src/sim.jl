# The simulation object with its deployment binding (§9.1, §9.2), the stepper
# seam (§10.2) and the phase-body accessor (§9.7). The framework owns the loop;
# the one delegated operation is "advance the continuous state from `t` by `h`".

"""
§13.5's termination sources (D-203): the diagnostic convention applied to the
run's outcome — each kind is its identity, its payload plain data — without
joining Appendix C's diagnostic set, the record being outcome, not warning.
`EndTimeReached` carries nothing: the record's own `t` is the fact, and the
configured bound lives with the policy. `ModelRequestedStop` carries the
first named `stop_on` face observed holding, in declaration order.
`ControlRequestedStop` carries its issuer — `:code` from `stop!(sim)`, the
requesting device's name from `stop!(handle)`, or `:interrupt`, requested by
§13.4's carve-out when an `InterruptException` reaches the catch site or by
§11.6's wrapper when one leaves a device loop body — through the same
first-writer-wins word, so an earlier issuer keeps it (§12.4's masking and the
operator-interrupt entry itself are still absent, `pending.md`). `LoopError` is §13.6's abnormal entry, `exception` the retained
cause — a `StepError` from the frame loop's one catch site (§13.4), which
carries the raw cause in turn.
"""
abstract type TerminationSource end

struct EndTimeReached <: TerminationSource end

struct ModelRequestedStop <: TerminationSource
    face::Symbol
end

struct ControlRequestedStop <: TerminationSource
    issuer::Union{Symbol,String}
end

struct LoopError <: TerminationSource
    exception::Any
end

"""
The stop policy one advance declares (§13.5, D-255): the clock bound and the
stop faces with their compiled root-cell addresses, built and validated by
`run!`, `replay!` and `step!` per call and bound on the run for that advance.
`ControlRequestedStop` is outside it: the policy is what the caller declares,
the stop word is what anyone can issue (§12.1).
"""
struct StopPolicy
    t_end::Float64            # Inf = no clock bound
    faces::Vector{Symbol}     # declaration order: the order a holding face is reported in
    addrs::Vector{Any}        # their compiled root-cell addresses
end

"""
§13.5's termination record: the run's *outcome*, and the policy of the advance
that ended it — so a stopped simulation answers "why did it stop?", and "how
did the stop go?", without its consumer reconstructing either from the clock or
the log stream (D-203). `t` is the final snapshot's boundary time in the
deployment's own scalar (§7.2), always present since boundary zero precedes
every record (D-233); `policy` is the terminating advance's `StopPolicy`, so
`EndTimeReached`'s bound is read off the record rather than off a constructor
default that no longer exists (D-255); `source` is the typed source above;
`residue` is what the run's-end sweep collected — recorded here and presented
through the logging backend, never published (D-201, D-203). It lives on the
`Run`, written once by the loop's tail, so a fresh run starts without one
(§12.6, D-255).
"""
struct TerminationRecord{T}
    t::T
    policy::StopPolicy
    source::TerminationSource
    residue::Vector{ResidueRecord}
end

"""
The state one run owns (§12.6, D-255): the origin, the input mode, the log and
the trace, fixed by the constructing entry point; the stop policy the current
advance bound, and the termination record the loop's tail writes once. `init!`
and `replay!` construct one, and a change of mode is a change of run — `live!`,
and the flip at a recording's end (D-218).

A `Simulation` is built with a placeholder run — `t₀ = zero(T)`, `:live`, an
empty log and trace, no termination — so every accessor has a run to read;
`lifecycle(sim)` is what says whether that run ever started.
"""
mutable struct Run{T}
    const t₀::T
    const mode::Symbol                            # :live | :replay (§12.6, D-218)
    const log::SnapshotLog                        # §11.2's retained snapshots
    const trace::Trace{T}                         # §11.5's recording of this run
    policy::StopPolicy                            # the current advance's (§13.5)
    termination::Union{Nothing,TerminationRecord{T}}   # the tail's one write (§13.5)
end

"""
    closed(run)

True once the loop's tail has written the run's termination record (§12.6,
§13.5, Appendix B) — the run's own answer to "did it end?", beside
`lifecycle(sim)`'s answer about the simulation.
"""
closed(run::Run) = run.termination !== nothing

# The five things a simulation is (§12.6, D-256): every other value belongs to
# one of them, and each field's comment names what it carries.
mutable struct Simulation{T,E}
    const deployment::Deployment  # what the grid parameters fixed (§9.1, D-254), and through it
                                  # the build — the schema authority a condition resolves
                                  # against (§14.3). Held once: a second reference would be
                                  # an invariant with no enforcer (§12.1, D-256)
    const exec::E                 # the nominal executor this simulation owns (§9.2, §9.7),
                                  # with its stepper, arrival buffers and `chunk_size`
    run::Run{T}                   # §12.6's run state: rebound at each door (D-255)
    const plane::DataPlane        # the §11.3 roster, the harness and loop writers, §11.2's
                                  # published holder and §11.5's recorder
    const control::Control        # §12.1's stop word, §12.4's sticky status and join cap,
                                  # §12.3's wait (devices.jl)
end

"""
    Simulation(deployment::Deployment, T = Float64; join_timeout = 5.0,
               trace = true, log = true, log_every = 1,
               log_max = 65536, chunk_size = 16)
    Simulation(build::Build, T = Float64; h, N_base = nothing, Δt_base = nothing,
               algorithm = RK4, firing_budget = 4, localization_tol = 1e-6,
               localization_budget = 8, kw...)
    Simulation(root, T = Float64; …)

Materialization (§9.2, D-254): deploying and materializing are two steps, with
two sugar forms over them. The `Deployment` is scalar-free and one backs many
`Simulation`s; this call fixes the scalar, allocating the buffers and the
stopped-sim services. The scalar picks the activation the entries compile over,
through `activation(d.build, T)`, which serves the nominal `Float64` entry the
build inserted and derives and caches any other (§9.4). The two convenience
forms are *defined as* the compositions: `Simulation(build; kw…)` is
`Simulation(Deployment(build; grid kw…), T; rest…)`, and `Simulation(root; kw…)`
calls `build` first. Entry compilation lives behind the deployment because `Δt`,
`D` and `Φ` are entry data, and one `Build` backs many deployments.

The build is held once, through the deployment (§12.1, D-256): `sim.deployment.build`
is the schema authority a condition resolves against (§14.3), and a second
reference on the `Simulation` would be an invariant with no enforcer.

What compilation returns is one `Executor` (§9.7), and the `Simulation` owns
it: every buffer set has exactly one owner (§9.2), so a service invocation
instantiates an executor of its own from the same cached layouts rather than
writing through this one.

The grid parameters, the algorithm and the three event parameters are the
`Deployment`'s, documented there and validated under `DeploymentInvalid`. The
keywords below are this call's, and they validate under `ArgumentInvalid`
(D-256).

`join_timeout` is §12.4's: the shutdown tail's join cap in seconds of wall
clock — a positive real defaulting to 5, generous for GUI teardown and socket
closes, short enough that an abandoned join reads as a diagnosed timeout
rather than a hang (D-198). It is the one *operational* keyword: never
trajectory-determining, because the trajectory has ended at the final
snapshot before any join begins, yet not a view policy either — it tunes the
tail's wall-clock patience, nothing more.

§13.5's termination policy is declared per advance and is no keyword here
(D-255): `t_end` and `stop_on` belong to `run!`, `replay!` and `step!`, each
call building and validating the `StopPolicy` it binds.

`trace` is §11.5's kill switch (default `true`): the input trace is on by
default because it is **primary** data and the log derived — given the initial
state and the trace the log is recomputable, never the reverse, and an
untraced interactive session is unreproducible permanently (D-029). The switch
covers the memory-constrained marathon session, and nothing else: no sampling,
no rolling window. Like the log keywords below it is a view policy, never
trajectory-determining — recording reads the drained batch and writes nowhere.

`log`, `log_every` and `log_max` are §11.2's retention keywords: the plain
switch (default `true`), the keep-every-kth stride over published boundaries
(an integer ≥ 1, default 1) and the bound on retained snapshot references (an
integer ≥ 1 defaulting to 65536 = 2¹⁶ — about 22 minutes at 50 Hz and full
density before anything is dropped — with `Inf` the explicit opt-out). Unlike
every deployment keyword they are **view policies, never trajectory-determining**:
two simulations differing only here produce bitwise-identical trajectories,
retention being reference bookkeeping over what publication already built.

The recording flags are carried to `init!`, which is what builds the run with
its log and trace (§12.6, D-255, Appendix B): the three log flags ride on the
placeholder run, the trace switch on the register the plane holds.
"""
function Simulation(d::Deployment, ::Type{T} = Float64; join_timeout = 5.0,
                    trace = true, log = true, log_every = 1,
                    log_max = 65536, chunk_size::Int = 16) where {T}
    # This call's own keywords are not deployment parameters, so they are
    # `ArgumentInvalid`s (D-256, Appendix C), collected into one throw
    # (§9.1, D-229). The stop policy is no longer among them (D-255).
    diags = Diagnostic[]
    _arg(name, v) = push!(diags, ArgumentInvalid(call = :Simulation, reason = :range,
                                                 argument = name, value = v))
    join_timeout isa Real && join_timeout > 0 || _arg(:join_timeout, join_timeout)
    trace isa Bool || _arg(:trace, trace)
    log isa Bool || _arg(:log, log)
    log_every isa Integer && log_every ≥ 1 || _arg(:log_every, log_every)
    (log_max isa Integer && log_max ≥ 1) || log_max === Inf || _arg(:log_max, log_max)
    isempty(diags) || throw(DiagnosticError(diags))    # one throw per call (§9.1, D-229)
    act = activation(d.build, T)
    sch = d.schedule
    ex = compile(d.build, act, sch.D, sch.Φ, sch.Δt; chunk_size, algorithm = d.algorithm)
    reg = TraceRegister(trace)     # the drain thunks close over it, so it precedes the plane
    # §12.6's placeholder run (D-255): the recording flags ride on it until `init!`
    # reads them off and builds the run that records for real.
    run = Run{T}(zero(T), :live,
                 SnapshotLog(log, Int(log_every), log_max === Inf ? typemax(Int) : Int(log_max)),
                 Trace{T}(nothing, Pair{String,Vector{Symbol}}[], TraceBatch[], 0),
                 StopPolicy(Inf, Symbol[], Any[]), nothing)
    Simulation{T,typeof(ex)}(d, ex, run, DataPlane(act.layout, ex.store, reg),
                             Control(Float64(join_timeout)))
end

# The two sugar forms, each *defined as* the composition (§9.2, D-254): every
# existing call site deploys and materializes in one call, and nothing in the
# artifact is lost by composing.
Simulation(b::Build, ::Type{T} = Float64; h = nothing, N_base = nothing,
           Δt_base = nothing, algorithm = RK4, firing_budget = 4,
           localization_tol = 1e-6, localization_budget = 8, kw...) where {T} =
    Simulation(Deployment(b; h, N_base, Δt_base, algorithm, firing_budget,
                          localization_tol, localization_budget), T; kw...)
Simulation(root::AbstractComponent, ::Type{T} = Float64; kw...) where {T} =
    Simulation(build(root), T; kw...)

"""
    warnings(sim::Simulation) → Vector{Diagnostic}

The concatenation of the simulation's artifacts' lists, the build's first and
the deployment's second (§9.2, D-250). Warnings raised while *mutating state*
live in that state's status record instead (§11.8), so nothing runtime reaches
here.
"""
warnings(sim::Simulation) = vcat(warnings(sim.deployment.build), warnings(sim.deployment))

# §13.5's clock bound, validated identically at the three binding sites, and an
# `ArgumentInvalid` at each: `t_end` is a keyword of the advance, never a
# deployment parameter (D-255, D-256). `call` is the site that named it, and
# the throw is fail-fast — an advance is one call, so the bound refuses before
# the stop faces are looked at. `Inf` is a value, not an absence: it is the
# default every advance states, and `_frames_to` maps it onto the frame loop's
# unbounded budget.
_t_bound(t, call::Symbol) = (t isa Real && t ≥ 0) ? Float64(t) :
    throw(DiagnosticError(ArgumentInvalid(call = call, reason = :range,
                                          argument = :t_end, value = t)))

# Whole frames from the origin `t₀` until the grid boundary `t₀ + k·h` first
# reaches the bound `t` (§12.4, §12.6), and its floor sibling, the last
# boundary at or before `t`. Both carry a slack of a few ulps of `t` in frame
# units: the boundary is an absolute time computed at `t`'s magnitude, so
# that magnitude, not the duration's, is the precision the comparison has —
# `0.3/0.1` is `2.9999999999999996`, and at a large clock the subtraction
# alone is off by more than a fixed frame fraction would absorb.
# The scalars are the deployment's own `T` (a `Dual` included), the step the
# bound `Float64`.
_frame_slack(t::Real, h::Float64) = 4 * eps(t) / h
function _frames_to(t::Real, t₀::Real, h::Float64)
    isinf(t) && return typemax(Int)
    max(0, ceil(Int, (t - t₀) / h - _frame_slack(t, h)))
end
_frame_at(t::Real, t₀::Real, h::Float64) = floor(Int, (t - t₀) / h + _frame_slack(t, h))
_t_end_frame(sim::Simulation, te::Float64) = _frames_to(te, sim.exec.clock.t₀, sim.deployment.h)

# §13.5's stop-face validation and compilation, run identically at the three
# binding sites — `run!`, `replay!` and `step!` (§12.7): each name must be a
# root-exported Bool *output* face. `site` is the one the refusal names
# (D-249). Duplicates collapse; the order kept is the declaration's, which is
# the order the first-holding face is reported in. The pass records into the
# list it is given and always returns the pair.
function _stop_faces(layout::Layout, stop_on, diags::Vector{Diagnostic}; site::Symbol)
    faces, addrs = Symbol[], Any[]
    root_input_names = Symbol[f for (f, _) in layout.root_inputs]
    # The root output-face list Appendix C asks a refusal to carry: every cell
    # the root addresses, less the root inputs — `addr` is a dictionary, so the
    # order is fixed here rather than left to hashing.
    out_faces = sort!(Symbol[f for ((p, f), _) in layout.addr
                             if isempty(p) && !(f in root_input_names)])
    for f in stop_on
        s = Symbol(f)
        if !haskey(layout.addr, ("", s))
            push!(diags, StopFaceInvalid(face = s, reason = :unknown, site = site,
                                         candidates = out_faces))
            continue
        end
        if s in root_input_names
            push!(diags, StopFaceInvalid(face = s, reason = :root_input, site = site))
            continue
        end
        a = layout.addr[("", s)]
        if _port_type(a) !== Bool
            push!(diags, StopFaceInvalid(face = s, reason = :not_bool, site = site,
                                         declared = _port_type(a)))
            continue
        end
        s in faces || (push!(faces, s); push!(addrs, a))
    end
    (faces, addrs)
end

# Each advance declares its own faces in a call of its own, so a fresh list
# thrown here is that call's one barrier (§13.1, D-229).
function _stop_faces(layout::Layout, stop_on; site::Symbol)
    diags = Diagnostic[]
    r = _stop_faces(layout, stop_on, diags; site)
    isempty(diags) || throw(DiagnosticError(diags))
    r
end

# §13.5's one binder, shared by `run!`, `replay!` and `step!` (D-255): the
# advance's declared pair validated and compiled into the immutable value it
# binds on the run. The bound refuses first — `_t_bound` is fail-fast, and the
# faces are a collecting pass behind it — so a call naming both a bad bound and
# a bad face is refused for the bound.
function _bind_policy(sim::Simulation, t_end, stop_on, site::Symbol)
    te = _t_bound(t_end, site)
    (faces, addrs) = _stop_faces(sim.exec.act.layout, stop_on; site)
    StopPolicy(te, faces, addrs)
end

"""
    lifecycle(sim)

§12.6's five-state lifecycle: `:built` — stores allocated, boundary zero not
completed — the cold state, and where a throw inside boundary zero returns the
simulation to (§13.4, D-223); `:initialized` — boundary-consistent and ready to
advance, the state `init!` establishes and a completed `step!` returns to;
`:running` — `run!` or `step!` holds the loop, and the §11.3 freeze with it; and
the two terminal states, `:stopped` and `:errored` (§13.6). Readable from any
task.
"""
lifecycle(sim::Simulation) = @atomic :acquire sim.control.lifecycle

"""
    mode(sim)

§12.6's input mode, read beside the lifecycle state: `:live` — the next frame's
drain takes its batches from the staging cells — or `:replay` — it takes them
from the recording `replay!` attached (§12.7, D-218). State and mode are
orthogonal: the state says whether the simulation may advance, the mode says
what it will advance on.

While the mode is `:replay` the recording is the bound: every advance's frame
budget is capped at the recording's last frame, and the mode returns to `:live`
exactly when a halt lands there, the records exhausted. `init!` and a fresh
`replay!` reset it with the trajectory, `live!` moves it alone (D-219), and a
terminal state makes it moot — nothing advances until one of those three doors
is taken.
"""
mode(sim::Simulation) = sim.run.mode

"""
    termination(sim)

§13.5's termination record (devices.jl, D-203) — the current run's outcome: the
final snapshot's boundary time, the terminating advance's `StopPolicy`, the
typed source that ended the run (`EndTimeReached`, `ModelRequestedStop` with
the face, `ControlRequestedStop` with its issuer, or `LoopError` with the
cause retained), and the tail residue the run's-end sweep collected.

`nothing` until the loop's tail writes it, which is `closed(sim.run)`. No
lifecycle gate is needed for that: `init!` and `replay!` each build a *fresh*
run (§12.6, D-255), so no record of a previous one is reachable here.
"""
termination(sim::Simulation) = sim.run.termination

# The record's assembly (§13.5, D-203), once per advance entry in its
# outermost `finally`, after the sweep has the residue in hand. `t` is the
# final snapshot's boundary time in the deployment's own scalar: both entries
# refuse a `built` simulation and boundary zero published, so the snapshot
# exists (D-233). The policy is the terminating advance's, the one that
# explains the stop (D-255).
_record(sim::Simulation{T}, src::TerminationSource, residue::Vector{ResidueRecord}) where {T} =
    TerminationRecord{T}(latest(sim).t, sim.run.policy, src, residue)

# §13.5's sampling read, after every publication: the named faces off the
# just-published snapshot, first holding face wins, in declaration order.
function _stop_hit(sim::Simulation, pol::StopPolicy)
    isempty(pol.addrs) && return nothing
    snap = latest(sim)
    for i in eachindex(pol.addrs)
        gather(snap.store, pol.addrs[i]) === true && return pol.faces[i]
    end
    nothing
end

# The shared entry gate of the two advance entries (§12.6), and of `live!`
# beside them (D-219): only `:initialized` admits one, and each refusal names
# its own way out — the `:running` sentence discriminating on the op, since
# `live!` meets a running loop as a stopped-sim operation.
function _assert_advanceable(sim::Simulation, op::Symbol)
    lc = @atomic sim.control.lifecycle
    lc === :initialized && return nothing
    lc === :built && throw(DiagnosticError(MissingInit(op = op, status = lc)))
    lc === :running && throw(DiagnosticError(ServiceLifecycle(op = op, status = :running,
                                                              legal = collect(ADVANCE_LEGAL))))
    lc === :stopped && throw(DiagnosticError(ServiceLifecycle(op = op, status = :stopped,
                                                              legal = collect(ADVANCE_LEGAL))))
    throw(DiagnosticError(ServiceLifecycle(op = op, status = :errored, legal = collect(ADVANCE_LEGAL))))
end

"""
    phase_bodies(sim)

The compiled bodies of the nominal activation, bound over this simulation's own
buffers — **these are the bodies the loop runs**, not re-derivations, which is
what makes the §7.5 measurement honest. The roster is fixed and total: a model
with no discrete components still gets `ticks`, empty, compiling to a no-op
whose `@ballocated` assertion passes vacuously, so consumers iterate uniformly
with no per-model branching. Beside the four blocks ride `events`, the guard
and handler per event keyed by `(path, name)`, and `projections`, the
`state_projection` call per component keyed by path — each a zero-argument
callable over the same buffers.
"""
phase_bodies(sim::Simulation) = sim.exec.bodies

# --- evaluation ---------------------------------------------------------------

"""
One RHS evaluation: *evaluating the RHS means running the sweep* (§5.3). The
interior variant of each sweep block, then the `state_derivative` block
against the complete fresh table. Leaves `ẋbuf` holding the derivative of
whatever `xbuf` holds.
"""
@inline function evaluate!(ex::Executor)
    ex.cursor.index += 1          # §13.4: the stage ordinal counts RHS evaluations,
    ex.bodies.sweep_1()           # so the backends stay untouched
    ex.bodies.sweep_2()
    ex.bodies.rhs()
    nothing
end

@inline evaluate!(sim::Simulation) = evaluate!(sim.exec)

"""
The boundary macro-sequence at a base tick, final form (§5.3, §10.6):

> integrate → project → [sweep → guards → handlers] iterated to quiescence
> (under the firing budget) → all due `state_update` calls

Integration has just written the state, so projection runs first — between the
write and its decode; the event phase then iterates with the due set fixed for
the whole boundary, and the due updates run last, after quiescence, reading
post-transition values off the settled table. Output stages before updates, so
a discrete component's cells carry `y[k]` computed from `s[k]` while
`state_update` produces `s[k+1]` — the sampled-data recursion, ordered by
construction rather than by convention.
"""
@inline function boundary!(sim::Simulation, tick::Int)
    cur = sim.exec.cursor
    _phase!(cur, :project)
    _projects!(sim.exec.events)
    event_phase!(sim, tick)
    _phase!(cur, :ticks)
    sim.exec.bodies.ticks(tick)
    nothing
end

"""
The macro-sequence at a step boundary that is *not* a base tick: the tick
counter has not advanced, so the due set is empty — and emptiness is arity
selection, never a sentinel index failing every gate (§10.5, D-185). The
zero-arg interior bodies are exactly the boundary walk with every discrete
entry gated out, so consistency is restored and nothing discrete can move;
projection and the event phase run in full — every step boundary is a boundary
(§10.4).
"""
@inline function offtick_boundary!(sim::Simulation)
    _phase!(sim.exec.cursor, :project)
    _projects!(sim.exec.events)
    event_phase!(sim, nothing)
    nothing
end

"""
Boundary zero's macro-sequence (§14.5, D-205): the ordinary one, with the
sweep's discrete entries admitted **due or not**. Every output stage runs and
publishes — from the authored `s` and the `t₀` table, in the ordinary sorted
walk — so the `t₀` snapshot carries the authored world fully evaluated and no
published cell holds the probe's synthesized values (§14.6's barrier extended
from the root inputs to the whole table).

The `state_update` calls keep the ordinary gate at index 0, which under the
canonical residue admits exactly `Φ = 0` (§10.5): that evaluation is
establishment, not a scheduled sample, and an offset component's first
*consumed* sample stays its `Φ·Δt_base` tick's. A component frozen at a
non-nominal activation has no entries here at all (§9.4's executable set), so
its pinned cells keep the carried nominal products — at boundary zero as
everywhere.

Never called bare: `_host_boundary_zero!` below hosts it for both services,
wrapping a throw as §13.4's catch does (D-223).
"""
@inline function boundary_zero!(sim::Simulation)
    cur = sim.exec.cursor
    _phase!(cur, :project)
    _projects!(sim.exec.events)
    event_phase!(sim, ESTABLISH)
    _phase!(cur, :ticks)
    sim.exec.bodies.ticks(0)
    nothing
end

# One iteration round's sweep: the whole gated schedule (§10.6), in the due-set
# arity the boundary fixed — never the update laws, which wait for quiescence.
@inline _round!(ex::Executor, tick::Int) =
    (ex.bodies.sweep_1(tick); ex.bodies.sweep_2(tick); nothing)
@inline _round!(ex::Executor, ::Nothing) =
    (ex.bodies.sweep_1(); ex.bodies.sweep_2(); nothing)
# Boundary zero's round: the whole schedule, gated by nothing (§14.5, D-205).
@inline _round!(ex::Executor, e::Establish) =
    (ex.bodies.sweep_1(e); ex.bodies.sweep_2(e); nothing)
@inline _round!(sim::Simulation, tick) = _round!(sim.exec, tick)

"""
The event phase (§10.6): [sweep → guards → handlers] iterated to quiescence,
the fixed point where a round of handlers fires nothing. The first round always
runs — it is the boundary sweep that restores table consistency — so a model
with no events degenerates to exactly that sweep, with no register work at all.

An event fires in a round iff its predicate is observed holding, the sample
observed before it was not-holding, and its firing count for this boundary is
below the budget; at most one event fires per component per round, the first
eligible in declaration order — priority with re-decision. The one register
subtlety is D-191's: an eligible-but-blocked event's last-observed sample is
*not* overwritten, so the edge it presented stands into the next round. Budget
exhaustion degrades rather than throwing: the event's further edges at this
boundary are lost under a `FiringBudget` warning, at most once per event per
boundary, while every other event iterates untouched. At quiescence the prior
is updated unconditionally from the final samples — every prior an honest
observation of a settled boundary.
"""
function event_phase!(sim::Simulation, tick)
    es, cur = sim.exec.events, sim.exec.cursor
    _phase!(cur, :round, 1)       # §13.4: the boundary sweep is round 1, and the guard
    _round!(sim, tick)            # walk and the fire walk of a round carry its index
    n = length(es.prior)
    n == 0 && return nothing
    copyto!(es.last, es.prior)
    fill!(es.count, 0)
    fill!(es.warned, false)
    budget = sim.deployment.firing_budget
    while true
        _guards!(es)
        fill!(es.comp_fired, false)
        any_fired = false
        for i in 1:n
            edge = !es.last[i] && es.now[i]
            eligible = edge && es.count[i] < budget
            if edge && !eligible && !es.warned[i]
                es.warned[i] = true       # at most one report per event per boundary
                (path, name) = es.names[i]
                # the loop's own cell (§11.8): folded at the next frame top
                _report!(sim.plane.loop_diag,
                         FiringBudget(path, name, _seconds(sim.exec.clock.t), budget,
                                      es.count[i]))
            end
            firing = eligible && !es.comp_fired[es.owner[i]]
            es.fire[i] = firing
            if firing
                es.comp_fired[es.owner[i]] = true
                es.count[i] += 1
                any_fired = true
            end
            # A blocked edge stays unconsumed (D-191): only the eligible-but-
            # blocked sample stands; every other event takes this round's.
            (eligible && !firing) || (es.last[i] = es.now[i])
        end
        any_fired || break
        _fire!(es)
        cur.index += 1
        _round!(sim, tick)
    end
    copyto!(es.prior, es.last)
    nothing
end

# --- the stepper seam, framework side (§10.2) ----------------------------------

"""
    step!(sim, h)

Advance the continuous state from `t` by `h`, delegated across the stepper
seam to whichever backend the deployment bound (stepper.jl). The seam is never
entered empty: with no continuous state the step degenerates to advancing `t`,
the backend is simply not called, and no backend contract has to say what it
would do at N = 0.
"""
@inline function step!(sim::Simulation, h)
    _phase!(sim.exec.cursor, :integrate)     # §13.4: `evaluate!` counts the stages from here
    isempty(sim.exec.xbuf) ? (sim.exec.clock.t += h) : step!(sim.exec.stepper, sim, h)
    _check_finite!(sim)
    nothing
end

# The boundary's first act (D-157, §13.4): one pass over the flat state buffer,
# immediately after the backend returns and before anything reads the state —
# `frame!`'s bare path and every segment of a localized frame alike, which is
# why the site is the seam's framework side and not the frame loop. `ẋ` does
# not participate: a nonfinite derivative contaminates its own block's step
# result within that very step, so this is the same detection with the same
# attribution, and `ẋ` is integrator scratch besides.
@inline function _check_finite!(sim::Simulation)
    x = sim.exec.xbuf
    @inbounds for i in eachindex(x)
        isfinite(x[i]) || _nonfinite(sim, i)      # the throw is the cold path
    end
    nothing
end

# The owner of flat index `i` and its leaf within that component's block, both
# read off `xblocks`. Thrown as a fail-fast `DiagnosticError`, which the catch
# site's species rule unwraps into the `StepError`'s `cause`.
@noinline function _nonfinite(sim::Simulation, i::Int)
    ex = sim.exec
    owner = findfirst(b -> i in b, ex.xblocks)::Int
    cur = ex.cursor                   # the phase stays `:integrate`, but the sweep is the
    cur.comp = owner; cur.fn = :none  # framework's own act between the stages and the
    cur.index = 0                     # boundary — no stage of its own, so no ordinal
    names = leaf_names(typeof(ex.act.decls[owner].x))
    throw(DiagnosticError(NonfiniteState(
        path = sim.deployment.build.structure.paths[owner],
        leaf = names[i - first(ex.xblocks[owner]) + 1],
        value = ex.xbuf[i],
        t = _seconds(ex.clock.t),
        boundary = ex.clock.step - 1)))   # the frame-entry index: this frame's own top
end

# The trajectory's opening, shared by the two entries that own one (§12.6):
# `init!` below and `replay!` (§12.7), whose difference is *how the state is
# established* — a resolved condition against the header's recorded values —
# and nothing else. Everything here is the wholesale opening §12.6 describes:
# the clock anchored at `t₀`, every event prior cleared (§10.6), the §11.8
# accounts reset, every staged batch dropped so none survives into the
# trajectory it predates (§11.4), and the stop word cleared. The log, the trace,
# the mode and the termination record are *not* cleared here: each door builds a
# fresh `Run` behind this call, and a fresh run is all four at once (D-255). The
# diagnostic *cells* are deliberately untouched at both entries: a rejection
# recorded while stopped is a fact about what happened.
function _open_trajectory!(sim::Simulation{T}, t₀::T) where {T}
    sim.exec.clock.t = t₀
    sim.exec.clock.t₀ = t₀
    sim.exec.clock.step = 0
    sim.exec.clock.boundary = 0
    fill!(sim.exec.events.prior, false)
    _reset_accounts!(sim)         # a new trajectory opens a fresh account (§11.8)
    for e in sim.plane.roster     # §12.6: no staged batch survives into the
        @atomic e.writer.cell.pending = nothing   # trajectory it predates
    end
    @atomic sim.plane.harness.cell.pending = nothing
    @atomic sim.control.stop_issuer = nothing
    nothing
end

# The run one door opens (§12.6, D-255): the log flags ride on the run the last
# door left — the placeholder's, before the first `init!` — and the fresh run
# gets a log and a trace of its own rather than cleared ones. The register is
# pointed at that trace and its cursor fields cleared with it; under the kill
# switch it points at nothing instead, nothing is ever recorded and `trace(sim)`
# refuses for the switch. `_install_writers!` then fixes the drain's indices for
# the trajectory about to open.
function _open_run!(sim::Simulation{T}, t₀::T, mode::Symbol, header, schemas,
                    pol::StopPolicy) where {T}
    reg = sim.plane.recorder
    L = sim.run.log
    trc = Trace{T}(header, schemas, TraceBatch[], 0)
    sim.run = Run{T}(t₀, mode, SnapshotLog(L.enabled, L.every, L.max), trc, pol, nothing)
    reg.trace = reg.enabled ? trc : nothing
    reg.frame = 0
    reg.feed = nothing
    _install_writers!(reg, sim.plane)
    nothing
end

"""
    init!(sim, condition = fragment(); t0 = zero(T))

Initialize: state at the declared defaults with the condition's overrides
applied, table consistent, clock at `t₀`.

The condition is §14.1's path-addressed sparse overlay, and the overlay base
is **always the declared defaults**: `init!` re-establishes the three state
homes — `xbuf` and the `s`/`m` stores, from `init_x`/`init_s`/`init_m` —
before applying anything, so applying a condition means "fresh run from the
declared defaults, with these overrides" (D-063) and warm restart needs no
second semantics. Nothing re-seeds the cells, and nothing needs to: boundary
zero *derives* every one of them below (D-205). Root inputs have no declared
default at all, and the condition's totality is what supplies them (§14.6). It
resolves first (§14.3), then checks root-input totality against the build's
root input faces (§14.6), and only then writes: a rejected `init!` leaves the
simulation exactly as it was, and a root input gets a condition value or the
call errors — the services path contains no call to `probe_value`. `t0` is a
service argument, never a condition entry: time is not a store of any
component (§14.5).

Boundary zero is an ordinary boundary with an empty integrate (§10.5, §14.5),
run with the sweep's one amendment: every discrete output stage publishes,
due or not (D-205, `boundary_zero!`), while the `state_update` calls keep
the gate at index 0 — which admits exactly the components with `Φ = 0`,
implemented by nothing.

Boundary zero also establishes every event prior as not-holding (§10.6), so a
predicate already holding in the authored state fires at `t₀` — derived, not
asserted — and a warm restart (`init!` again) resets all three registers from
scratch: such predicates fire again at the new `t₀`. A warm restart is a new
trajectory and therefore a new `Run` (§12.6, D-255): the log and the
trace are fresh *objects* rather than cleared ones, and the log's boundary zero
lands as a first endpoint of its own (§11.2). The trace's header is captured
*here* — after `apply!` and the clock writes, before the sequence runs — which
is §14.5's placement, essential on both sides: the header holds the resolved
stores and root inputs rather than the authored overlay (D-038), and it never
holds the post-transition result, boundary zero being re-executed under replay
(§12.7).

`init!` is §12.6's door into `initialized` from an *authored* condition, and
some door is mandatory: `run!` and `step!` refuse a simulation whose boundary
zero has not completed. `replay!` (§12.7) is the one alternative — it stands
in the same lifecycle position with the trace header in the condition's place
(D-101), and the trajectory-opening tail below is literally shared with it. It
opens the fresh trajectory wholesale — the stop word and *every staged batch
still in a staging cell* clear, while the §13.5 termination record and the
input mode's return to `:live` (§12.6, D-218) are the new run itself (§12.6: no stale batch
survives to clobber the boundary zero it predates — the pre-run sequence is
`init!` → `stage!` → `run!`, the batch then waiting for the first frame top as
§11.4 says). The diagnostic cells are
deliberately not cleared: a rejection recorded while stopped is a fact about
what happened, not a stale input, and it surfaces in the next run's first
status (§11.8). `init!` is itself a stopped-sim operation: refused while
`running`, and refused on an `errored` simulation, which is terminally
stopped (§13.6) — reproduction is trace replay, not resurrection. A throw
inside boundary zero arrives as a `StepError` with pointer 0 and leaves the
simulation `built`, `init!` and `replay!` legal again (§13.4, D-223).
"""
function init!(sim::Simulation{T}, condition = fragment(); t0::T = zero(T)) where {T}
    ctl = sim.control
    lc = @atomic ctl.lifecycle
    lc === :running && throw(DiagnosticError(ServiceLifecycle(op = :init!, status = :running,
                                                              legal = collect(STOPPED_SIM_LEGAL))))
    lc === :errored && throw(DiagnosticError(ServiceLifecycle(op = :init!, status = :errored,
                                                              legal = collect(STOPPED_SIM_LEGAL))))
    plan = resolve_condition(condition, sim.deployment.build, T)      # both refusals precede every write
    assert_total(plan, sim.deployment.build.structure, :init!)   # (§14.6): all-or-nothing
    establish_defaults!(sim.exec.xbuf, sim.exec.sstores, sim.exec.mstores, sim.deployment.build.structure.comps,
                        activation(sim.deployment.build, T).decls, sim.deployment.build.structure.tiers)   # D-063's reset
    apply!(sim, plan)
    _open_trajectory!(sim, t0)
    # §11.5's capture, at §14.5's placement — after `apply!` and the clock
    # writes, before the sequence — and the fresh run it opens (§12.6)
    reg = sim.plane.recorder
    _open_run!(sim, t0, :live, reg.enabled ? _capture_header(sim) : nothing,
               Pair{String,Vector{Symbol}}[], StopPolicy(Inf, Symbol[], Any[]))
    _host_boundary_zero!(sim)
    publish!(sim)                 # the boundary-zero snapshot (§11.2, §14.5)
    @atomic :release ctl.lifecycle = :initialized
    nothing
end

"""
Replay's entry pass (§12.7), called by `replay!` below before any state is
touched, so every refusal precedes every write. The pass runs in two
stages, and the split is one of order rather than of policy — each stage
collects within itself: the header's own disagreements with this build are
thrown before a single record is looked at, because a record resolved through a
schema this model has already contradicted would report noise; the records are
then collected in turn, so a trace with three bad entries reports three.
(Both stages collect, as Appendix C's column reads, D-217.) What
comes back is the whole recording normalized to compiled scatters against *this*
layout — the conversion paid once, off the loop (D-101).

The scalar is the outermost structural fact, and it is dispatch rather than a
comparison: the method below takes a `Trace{T}` against a `Simulation{T}`, and
the fallback beside it is what a `Trace{Float64}` offered to a
`Simulation{Dual}` reaches. `replay!` carries exactly the same pair.
"""
function _compile_feed(sim::Simulation{T}, trc::Trace{T}) where {T}
    faces = Symbol[f for (f, _) in sim.exec.act.layout.root_inputs]
    diags = Diagnostic[]
    h = trc.header
    # `trace(sim)` refuses a headerless trace (`MissingInit`) and the two doors
    # are the only builders of one, so a `nothing` here is an invariant firing
    # rather than a case the pass handles (§11.5, D-255).
    h === nothing && throw(InternalInvariant(
        "a Trace with no header reached replay's entry pass (§11.5, §12.7)"))
    _check_header!(diags, sim, h)
    _check_schemas!(diags, faces, trc.schemas)
    isempty(diags) || throw(DiagnosticError(diags))     # the header before the entries
    records = _compile_records!(diags, sim, trc, faces)
    isempty(diags) || throw(DiagnosticError(diags))
    ReplayFeed(records, 1, trc.frames)
end

_compile_feed(sim::Simulation{Ts}, trc::Trace{Tt}) where {Ts,Tt} =
    throw(DiagnosticError(ReplayHeaderMismatch(what = :scalar, expected = Tt, found = Ts)))

"""
    replay!(sim, trc; to_boundary = nothing, t_end = Inf, stop_on = ())
    replay!(sim, trc; to_time)

Re-drive a recorded session (§12.7) — **the ordinary loop with exactly two
substitutions** (D-101), not a separate execution mode, which is what keeps
every property proved of the loop true of a replay:

1. *Boundary zero comes from the header.* `replay!` stands in `init!`'s
   lifecycle position: it applies the recorded stores and root-input values
   directly — no condition resolution, and §14.6's totality holding by capture
   — then opens the trajectory and runs the ordinary boundary-zero sequence.
   The header predates that sequence (§14.5's placement, §11.5), so authored
   events re-fire identically: nothing is applied twice and nothing skipped.
2. *The drain reads the trace.* Each frame top applies the recording's batches
   for that frame ordinal, verbatim and with no surface re-check — the
   write-surface rule ran at recording time — while every live staging cell is
   taken and dropped under `ReplayDiscardedStaging` (`drain!`). Ordinal keying
   is exact because the frame sequence is itself deterministic.

Everything else is the loop as specified. The frame budget is the recording's
length, or `to_boundary = k` frames — §13.4's replay pointer, defined as
running *through* the frame that publishes boundary `k`, and every frame top is
a grid boundary (§10.4), so the halt is exactly at `clock.step == k` and a
replay always halts at a frame top; a `t*` boundary inside a frame is
reproduced but is not stoppable-at (§10.4 keeps the two indices apart).
`to_time` is that same halt addressed by time (D-219), mutually exclusive with
`to_boundary`: it halts at the **last frame top at or before** the time given,
`k = ⌊(to_time − t₀)/h⌋` against the header's `t₀`, so a time between two frame
tops floors onto the earlier one. The rounding is the deliberate opposite of
`t_end`'s reach-or-exceed rule (§12.4) — `t_end` bounds a run, `to_time`
positions an inspection, and the point of halting is to stand *before* the
anomaly. `t_end`
and `stop_on` bind for this replay exactly as at `run!`, `Inf` and no faces by
default, the recording bounding an unbounded pair.
Budget exhausted, the replay ends
**`initialized`**, never `stopped` (§12.7): boundary-consistent and ready to
advance, which is what makes replay-to-inspect, replay-to-`k−1`-then-`step!`
and `run!`-continuation real. A §13.5 source firing first ends it `stopped`
like any run, and a loop-side throw `errored`.

The recording and the **input mode** it enters outlive the call (§12.6, D-218):
a partial replay is a resumable position, not the end of an operation, and the
`step!` or `run!` that follows goes on consuming the records from the halt —
which is what makes §13.4's reproduction workflow run through the ordinary
entry points. The mode returns to `:live`, the recording detaching with it,
exactly when a halt lands at the recording's last frame; every advance in
`:replay` is capped there, so none ever runs past the records and goes on
live.

Replay re-records: the trace register runs normally and **the new trace
inherits the old header** (§12.7), this simulation's writers appended under
§11.5's growth rule, so the re-drained batches keep the recording's own writer
indices — a bit-identical prefix — while a continuation's live drains record
under this session's own. Rostered devices init, spawn and consume snapshots
normally (§11.1): they are readers here, and a session that wants live input is
a continuation, not a replay.

Refused while `running` and on an `errored` simulation, as `init!` is. Every
refusal — the lifecycle gate, `to_boundary`'s range, `to_time`'s, the keyword
validation and the whole entry pass — precedes every write. A throw inside
boundary zero arrives as a `StepError` with pointer 0 and leaves the simulation
`built`, `init!` and `replay!` legal again (§13.4, D-223).
"""
function replay!(sim::Simulation{T}, trc::Trace{T}; to_boundary = nothing,
                 to_time = nothing, t_end = Inf, stop_on = ()) where {T}
    ex, ctl = sim.exec, sim.control
    lc = @atomic ctl.lifecycle
    lc === :running && throw(DiagnosticError(ServiceLifecycle(op = :replay!, status = :running,
                                                              legal = collect(STOPPED_SIM_LEGAL))))
    lc === :errored && throw(DiagnosticError(ServiceLifecycle(op = :replay!, status = :errored,
                                                              legal = collect(STOPPED_SIM_LEGAL))))
    to_boundary === nothing || to_time === nothing ||     # two spellings of one halt (D-219)
        throw(DiagnosticError(ArgumentInvalid(call = :replay!, reason = :both_given)))
    # §13.4's pointer, in grid boundaries: whole and non-negative, and no further
    # than the recording reaches — every frame top is one, so it counts frames
    to_boundary === nothing || (to_boundary isa Integer && to_boundary ≥ 0 &&
        to_boundary ≤ trc.frames) || throw(DiagnosticError(
            ArgumentInvalid(call = :replay!, reason = :range, argument = :to_boundary,
                            value = to_boundary)))
    if to_time !== nothing
        # D-219's time spelling of the same pointer, floored onto the last frame
        # top at or before it: the *header's* `t₀` as the origin and the
        # *header's* `h` as the stride — the recording's own grid, so
        # `k ≤ trc.frames` names a boundary of the recording, and a target
        # bound at a different `h` falls through to the entry pass below,
        # which refuses it honestly (`ReplayHeaderMismatch`, never a false
        # word about a time the recording covers). `_frame_at` carries the
        # slack: without it the plain floor would halt one boundary short of
        # the one named.
        t₀ = trc.header.t₀
        to_time isa Real && isfinite(to_time) && to_time ≥ t₀ || throw(DiagnosticError(
            ArgumentInvalid(call = :replay!, reason = :range, argument = :to_time,
                            value = to_time)))
        to_boundary = _frame_at(Float64(to_time), t₀, trc.header.deployment.h)
        to_boundary ≤ trc.frames || throw(DiagnosticError(     # a time the recording never reached
            ArgumentInvalid(call = :replay!, reason = :range, argument = :to_time,
                            value = to_time)))
    end
    pol = _bind_policy(sim, t_end, stop_on, :replay!)   # this advance's policy, validated
    feed = _compile_feed(sim, trc)        # the entry pass: every refusal precedes every write
    # substitution (1): the header applied where `establish_defaults!` + `apply!`
    # stand in `init!`. The recorded values are already resolved (D-038), so
    # there is nothing to resolve and nothing to check for totality.
    h = trc.header
    ex.xbuf .= h.x
    for ci in eachindex(h.s)
        h.s[ci] === nothing || (ex.sstores[ci][] = h.s[ci])
    end
    for ci in eachindex(h.m)
        h.m[ci] === nothing || (ex.mstores[ci][] = h.m[ci])
    end
    for (f, v) in h.root_inputs
        scatter!(ex.store, ex.act.layout.addr[("", f)], v)
    end
    _open_trajectory!(sim, h.t₀)                # `t₀` is applied, never compared (§12.7)
    reg = sim.plane.recorder
    # The new run, and substitution (2) with it: the mode is one of the run's
    # `const` fields, so entering `:replay` *is* constructing this run (§12.6,
    # D-255), and its policy is this call's, bound past the last refusal (§13.5).
    # The new trace inherits the old header, detached — every mutable field of it
    # copied — and the recording's own schema entries, so neither the growth
    # below nor a continuation's writes ever reach the `Trace` the caller holds.
    _open_run!(sim, h.t₀, :replay, reg.enabled ? _detach(h) : nothing,
               reg.enabled ? copy(trc.schemas) : Pair{String,Vector{Symbol}}[], pol)
    # the recording attached, outliving this call — the halt below detaches it
    # only where it lands at the recording's last frame (§12.6, §12.7, D-218)
    reg.feed = feed
    _host_boundary_zero!(sim)
    publish!(sim)                               # the boundary-zero snapshot (§11.2, §14.5)
    upto = to_boundary === nothing ? trc.frames : Int(to_boundary)
    _run_body!(sim, pol, upto, _t_end_frame(sim, pol.t_end))
    nothing
end

"""
    live!(sim)

§12.6's third door, and the only one that moves the input mode alone (§12.7,
D-219): take a replaying simulation live where it stands. The mode becomes
`:live` and the recording's remainder detaches, and **nothing else is
touched** — not the trajectory, which stands at the halt, and not the trace
register, which keeps the header it inherited and the batches it has
re-recorded. The next `run!` or `step!` is therefore the live continuation from
the replayed boundary, and its drains append to the replayed prefix, so the
session leaves behind one seamless recording of itself.

The automatic flip is D-218's, and it fires only at the recording's end: right
for an unattended reproduction, wrong for the rewrite workflow, where the
caller wants the remainder abandoned rather than consumed — interrupt at
t = 110, `replay!(sim2, trc; to_time = 100.0)`, inspect, `live!`, fly the last
ten seconds again.

A stopped-sim operation, legal only on an `initialized` simulation in
`:replay`. The lifecycle gate is the advance entries' (§12.6): `:built` refuses
for want of a door into `initialized`, `:running` because the loop owns the
stores, and both terminal states because nothing advances from them. A
simulation already `:live` refuses too — the call would have nothing to do, and
a silent no-op would let the caller believe a recording was dropped that was
never attached.
"""
function live!(sim::Simulation{T}) where {T}
    _assert_advanceable(sim, :live!)
    r = sim.run
    r.mode === :replay || throw(DiagnosticError(
        ArgumentInvalid(call = :live!, reason = :not_replaying)))
    sim.plane.recorder.feed = nothing
    # §12.6: the mode is a `const` field, so a change of mode is a change of run
    # — the same log, the same trace, the same policy and record (D-255)
    sim.run = Run{T}(r.t₀, :live, r.log, r.trace, r.policy, r.termination)
    nothing
end

"""
    run!(sim; t_end = Inf, stop_on = ())

Advance one frame at a time, each frame §11.1's anatomy — drain, integrate,
boundary sequence, publication — under §11.1's task topology and §12.4's
bracket and tail, until a §13.5 termination source ends the run: `t_end`'s
frame reached, a named `stop_on` face observed holding in a published
snapshot, or a control-plane stop observed at frame top. Both keywords declare
**this advance's** policy, `Inf` and no faces by default, built and validated
per call (§13.5, D-255). A run with `t_end = Inf` and no stop face ends only by
a control-plane stop, Ctrl-C included (§12.4); it is allowed, and the loop
raises `UnboundedRun` into its own cell against it (§11.8). Only
an `initialized` simulation runs (`init!` is mandatory, §12.6), and the run
leaves it terminally `stopped` — the §13.5 record readable through
`termination(sim)` — or `errored` on a loop-side failure (§13.6): the failed
boundary published nothing, so the last published snapshot is already the
promoted final one; the tail runs identically, the cause is retained on the
record, and `run!` rethrows after the tail completes (§13.4's synchronous
rule).

The run's shape, in order: the policy binds and the §11.3 freeze rises (the
lifecycle's `:running`, spanning the tail); the stop word is cleared (a fresh
run owes nothing to the last one's stop); the §12.4 init bracket runs per
roster entry on the calling task; the topology is derived from the *live*
entries — with a `needs_calling_task` holder among them the loop moves to a
spawned task and the calling task runs that device's loop body inline,
otherwise the loop runs here and one task is spawned per live entry — the
loop advances until a termination source fires; and the tail closes the run
(devices.jl): sticky status after the final snapshot, waits woken,
`unblock!`, the join under `join_timeout`. Either way `run!` blocks its
caller until the run ends; what varies is what the calling task spends the
run doing (§11.1).

Inside the loop, `frame!` carries each grid step `[tₖ₋₁, tₖ]` through the
§10.4 localization loop, firing any `t*` boundaries it brackets on the way;
the frame-top boundary (§10.3) is a base tick every `N_base` frames, where the
gate reads the tick index, and the empty-due-set boundary in between. The
drain runs at the frame top only, never at a `t*` boundary (§10.4), while
publication follows *every* boundary sequence (§11.2) — the frame top's here,
a `t*` boundary's inside the frame loop, before integration resumes — and
every publication is a stop-face sampling point (§13.5), a `t*` hit ending
the run with the `t*` snapshot final. The grid is driven by the step counter,
so the run ends at the first frame top reaching or exceeding `t_end`, whole
frames from `t₀` (§12.4).
"""
function run!(sim::Simulation; t_end = Inf, stop_on = ())
    _assert_advanceable(sim, :run!)
    pol = _bind_policy(sim, t_end, stop_on, :run!)
    sim.run.policy = pol
    # §13.5's advisory (D-255): a live run bounded by neither clock nor face
    # ends only by the operator interrupt, so the loop says so once, into its
    # own cell. A `:replay` run is bounded by the recording (D-218), so the
    # warning would be false there.
    sim.run.mode === :live && isinf(pol.t_end) && isempty(pol.faces) &&
        _report!(sim.plane.loop_diag, UnboundedRun(pol.t_end, copy(pol.faces)))
    # a live run owes its end to a §13.5 source alone, so its frame budget is
    # unbounded here; in `:replay` the recording binds it (`_run_body!`, D-218)
    _run_body!(sim, pol, typemax(Int), _t_end_frame(sim, pol.t_end))
    nothing
end

# §12.7's bound (D-218): while the mode is `:replay` the recording caps every
# advance's frame budget, `to_boundary` capping it earlier — so no advance ever
# runs past the records and goes on live, and every frame of a session is either
# record-driven or live before it runs.
_replay_bound(sim::Simulation, upto::Int) =
    sim.run.mode === :replay ? min(upto, _feed(sim.plane.recorder).frames) : upto

# §12.7's flip (D-218), at the one place the terminal disposition already lives:
# the mode becomes `:live` exactly when the halt consumed the recording's last
# frame, the records exhausted and the recording detached with them; short of
# that it stays `:replay`, and the next `step!` or `run!` goes on consuming the
# recording. An `errored` exit leaves both as they stand: the frame was
# abandoned mid-execution, nothing advances from a terminal state, and `init!`
# and `replay!` are the resets.
function _settle_mode!(sim::Simulation{T}) where {T}
    r = sim.run
    r.mode === :replay || return nothing
    reg = sim.plane.recorder
    if sim.exec.clock.step ≥ _feed(reg).frames
        reg.feed = nothing
        sim.run = Run{T}(r.t₀, :live, r.log, r.trace, r.policy, r.termination)
    end
    nothing
end

# The run's body: the §11.3 freeze, §12.4's bracket, §11.1's topology, the tail
# and §13.5's terminal disposition — everything from `:running` to the terminal
# store, shared verbatim by `run!` and `replay!` because D-101's claim is that
# replay *is* this loop. `upto` is the frame budget, `target` the `t_end` frame.
#
# The terminal mapping is `step!`'s. `term === nothing` means the budget ran out
# rather than a source firing, which only a bounded advance can reach — a
# `replay!`, or any run in `:replay`, where the recording is the bound (D-218) —
# and it lands `initialized` at a frame top, §12.7's promise. A §13.5 source is
# `stopped` with the record, a throw `errored` with the cause retained. The mode
# settles here too, on every exit but the errored one.
function _run_body!(sim::Simulation, pol::StopPolicy, upto::Int, target::Int)
    plane, ctl = sim.plane, sim.control
    upto = _replay_bound(sim, upto)             # §12.7: the recording bounds a replaying run
    @atomic :release ctl.lifecycle = :running   # the §11.3 freeze: the roster is fixed for the run
    term, err_src = nothing, nothing
    try
        @atomic ctl.stop_issuer = nothing
        _reset_accounts!(sim)                 # §11.8: totals count since the run began
        live = _init_devices!(sim)            # §12.4's pre-spawn bracket, attachment order
        @atomic ctl.stopped = false
        ct = findfirst(e -> needs_calling_task(e.dev), live)
        if ct === nothing                     # the unattended mode (§11.1)
            tasks = _spawn!(live)
            _register_tasks!(plane, live, tasks)
            try
                term = _advance!(sim, pol, upto, target)[1]
            finally
                _finish!(sim)                 # tail (1)–(2), even off a loop-side throw
                _tail!(sim, live, tasks)      # tail (3)–(5)
            end
        else                                  # the loop is the movable piece (§11.1)
            e_ct = live[ct]
            others = [live[i] for i in eachindex(live) if i != ct]
            tasks = _spawn!(others)
            _register_tasks!(plane, others, tasks)
            plane.run_tasks[e_ct.id] = current_task()   # the inline body's task (§11.1)
            e_ct.handle.last_seen = ctl.counter
            loop_task = Threads.@spawn try
                _advance!(sim, pol, upto, target)[1]
            finally
                _finish!(sim)                 # the spawned loop wakes the inline body too
            end
            _wrap(e_ct)                       # the identical wrapper, inline (§11.6)
            try
                term = fetch(loop_task)       # run! blocks until the run ends (§11.1)
            finally
                _tail!(sim, others, tasks)    # the calling-task device sits outside the join
            end
        end
    catch err
        # §13.6's abnormal entry: the failed boundary is discarded by
        # construction — publication is a boundary's last act, so it published
        # nothing and the previous snapshot is already final. The source
        # retains the cause as the frame loop wrapped it — a `StepError`
        # against the execution cursor (§13.4) — unwrapped from the spawned
        # loop's task failure where the topology moved it; the record itself is
        # assembled below, after the sweep (D-203).
        err_src = LoopError(err isa TaskFailedException ? err.task.exception : err)
        rethrow()
    finally
        @atomic ctl.stopped = true
        residue = _sweep_tail!(sim)           # the run's last take (§11.8): what landed past
        empty!(plane.run_tasks)               # the final frame top — recorded and presented,
        if err_src !== nothing                # never published (D-201, D-203)
            sim.run.termination = _record(sim, err_src, residue)
            @atomic :release ctl.lifecycle = :errored
        else
            _settle_mode!(sim)                # §12.7's flip, at the halt (D-218)
            if term === nothing               # the frame budget ran out: a replay ended at a
                @atomic :release ctl.lifecycle = :initialized  # frame top (§12.7)
            elseif (@atomic ctl.lifecycle) === :running
                sim.run.termination = _record(sim, term, residue)
                @atomic :release ctl.lifecycle = :stopped
            end
        end
    end
    nothing
end

# The per-run reset (§11.8): every writer's account starts the run — and, from
# init!, the trajectory — at zero. The cells are deliberately not touched: a
# batch reported or staged while stopped waits for the first frame top's
# drain, exactly as a staged input batch waits (§11.4).
function _reset_accounts!(sim::Simulation)
    for e in sim.plane.roster
        _reset!(e.acct)
    end
    _reset!(sim.plane.harness_acct)
    _reset!(sim.plane.loop_acct)
    nothing
end

_register_tasks!(plane::DataPlane, entries::Vector{RosterEntry}, tasks::Vector{Task}) =
    (for (e, t) in zip(entries, tasks); plane.run_tasks[e.id] = t; end; nothing)

# The frame loop, shared by both advance entries (§12.6: a stepped frame is
# bit-identical to a run frame because this is the same code) — returns
# `(source, frames advanced)`, the §13.5 source `nothing` exactly when the
# frame budget `upto` ran out, which only `step!` binds finitely. The
# consultation order is normative (D-203; the recorded source of a boundary
# where two sources hold is the first in it): the stop word at frame top
# (§12.1 — the loop never stops mid-frame, so a stop observed here leaves the
# last published boundary as the final snapshot, §12.4(1)); `t_end`'s frame
# completed; and the stop faces at every publication — the entry check first
# (a boundary-zero or authored condition already terminal advances nothing,
# §13.5), then after each frame's own publications, where a mid-frame `t*`
# hit arrives through the cursor's `hit` with the frame's remainder already
# abandoned (D-255: the scratch sits beside the cursor, never in the policy).
# With devices rostered every frame yields at least once (§12.2, the unpaced
# case): the explicit yield is the co-resident device tasks' scheduling slot.
function _advance!(sim::Simulation, pol::StopPolicy, upto::Int, t_end_frame::Int)
    plane, ctl, cur = sim.plane, sim.control, sim.exec.cursor
    nb = sim.deployment.N_base
    adv = 0
    face = _stop_hit(sim, pol)
    face === nothing || return (ModelRequestedStop(face), adv)
    entry = 0                     # the frame-entry boundary index, read at the frame top
    try                           # before the drain, so the catch has it wherever the
        while true                # throw came from (§13.4)
            issuer = @atomic ctl.stop_issuer
            issuer === nothing || return (ControlRequestedStop(issuer), adv)
            sim.exec.clock.step < t_end_frame || return (EndTimeReached(), adv)
            sim.exec.clock.step < upto || return (nothing, adv)
            isempty(plane.roster) || yield()
            entry = sim.exec.clock.step
            cur.hit = nothing     # the frame's own scratch, cleared where it is stamped
            drain!(sim)
            k = (sim.exec.clock.step += 1)
            frame!(sim, k)
            if cur.hit === nothing
                k % nb == 0 ? boundary!(sim, k ÷ nb) : offtick_boundary!(sim)
                publish!(sim)
                face = _stop_hit(sim, pol)
            else
                face = cur.hit    # a t* publication hit (§13.5): that snapshot is final
            end
            # a frame counts once it has published a boundary — which a `t*` stop
            # hit has done, its remainder abandoned; the carve-out below is what
            # makes the count observable, a throw carrying no return value out
            adv += 1
            face === nothing || return (ModelRequestedStop(face), adv)
        end
    catch err
        # §13.4's one exception never wrapped: the operator's stop command, not
        # model code failing, so it routes to the stop path (§12.4). The frame is
        # abandoned unpublished and the stores may be mid-boundary — this is the
        # masked guarantee without the masking, the defensive branch §13.4 keeps.
        if err isa InterruptException
            _request_stop!(ctl, :interrupt)   # through the stop word, so an earlier issuer keeps it
            issuer = @atomic ctl.stop_issuer
            return (ControlRequestedStop(something(issuer)), adv)
        end
        rethrow(_wrap_step(sim, entry, err))
    end
end

# The one `StepError` constructor (§13.4, D-059): the frame from the cursor, the
# clock at the failure, the frame-entry boundary as the replay pointer, and the
# cause under the species rule below. Nothing inside the sequence throws a
# `StepError`, so one arriving here is an invariant firing, not a re-wrap. Two
# callers reach it — the frame loop above and the boundary-zero host below
# (D-223) — and it stays the only constructor.
function _wrap_step(sim::Simulation, entry::Int, err)
    err isa StepError && throw(InternalInvariant(
        "a StepError reached the catch site (§13.4), which is its only constructor — " *
        "something inside the boundary sequence wrapped one"))
    cur = sim.exec.cursor
    frame = CursorFrame(cur.comp == 0 ? nothing : sim.deployment.build.structure.paths[cur.comp],
                        cur.fn, cur.phase, cur.index)
    StepError(frame, _seconds(sim.exec.clock.t), entry, _species(sim, err))
end

# The species rule (§13.4, D-221): a fail-fast carrier thrown inside the
# sequence arrives as its diagnostic unwrapped — which is what lets a runtime
# check (§9.5's conformance failure, the nonfinite sweep) be a plain thrower
# of its kind while the catch site stays the only wrap. A collected carrier has
# no single kind and rides as the cause it is.
_species(::Simulation, err) = err
_species(::Simulation, err::DiagnosticError{<:Diagnostic}) = err.carried

# §13.2's bundle-field match at runtime (D-248): a `FieldError` whose type is the
# bundle the cursor's function received is the bundle-law diagnostic, classified
# as at the probe. Any other `FieldError` is the author's own and rides as the
# cause it is. `UserCodeFraming` gets no runtime arm: the carrier already names
# the frame and the function through the cursor.
function _species(sim::Simulation, err::FieldError)
    cur = sim.exec.cursor
    cur.comp == 0 && return err
    ci, fam = cur.comp, cur.fn
    c, t = sim.deployment.build.structure.comps[ci], sim.deployment.build.structure.tiers[ci]
    s1 = tuple(sim.deployment.build.dataflow.stage1[ci]...)
    # Reading the names invokes declarations, and a throw here would replace the
    # author's error, the cursor frame and the `StepError` with a frame of its own.
    bn = try
        fam === :guard || fam === :handler       ? event_bundle_names(c) :
        fam === :output_state                    ? bundle_names(output_state, c, t, s1) :
        fam === :output_direct                   ? bundle_names(output_direct, c, t, s1) :
        fam === :state_derivative || fam === :state_update ? bundle_names(update_of(t), c, t, s1) :
        return err
    catch e
        e isa InterruptException && rethrow()
        return err
    end
    # By names, not by the exact type: the runtime bundle's value types differ
    # from the probe's at a non-nominal activation, and the names are the law's
    # invariant (§5.2).
    (err.type <: NamedTuple && fieldnames(err.type) == bn) || return err
    BundleFieldError(path = sim.deployment.build.structure.paths[ci], family = String(fam),
                     tier = t === CONTINUOUS ? :continuous : :discrete, field = err.field,
                     legal = collect(bn), reason = classify_bundle_field(fam, t, err.field))
end

# The second host of §13.4's catch (D-223): boundary zero runs the loop's
# user-code surfaces with the cursor maintained through them, so a throw inside
# it takes the one `StepError` constructor — frame from the cursor, `t₀`,
# pointer 0, the species rule — under the service's disposition: the simulation
# returns to `built`, nothing published, no record written. An interrupt is not
# model code failing and has no stop path to route to here, so it moves the
# lifecycle and propagates raw.
function _host_boundary_zero!(sim::Simulation)
    try
        boundary_zero!(sim)
    catch err
        @atomic :release sim.control.lifecycle = :built
        err isa InterruptException && rethrow()
        rethrow(_wrap_step(sim, 0, err))
    end
end

"""
    step!(sim; frames = 1, t_end = Inf, stop_on = ())
    step!(sim; t_plus)

§12.6's partial advance: advance whole frames synchronously through the
ordinary frame sequence — drain, integrate, boundaries, publication — and
return the number of frames **actually advanced**. A stepped simulation is
bit-identical to the same frames under `run!`: the two entries share the one
frame loop. `t_plus` is the duration spelling, mutually exclusive with
`frames`: whole frames until the boundary time first covers the duration.

A stepping session is deviceless by construction (§12.6): no task is spawned
and no bracket runs — device tasks are per-`run!` artifacts — while the
frame-top drain still runs, so `stage!(sim, …)` → `step!` → `latest(sim)` is
the advance-assert-advance idiom, and a batch staged into a rostered
device's cell while stopped is applied exactly as §11.4 says. Between calls
the simulation reports `initialized`, so `attach!` is legal there and `run!`
may follow, continuing from the current boundary.

Termination policy is honored throughout, and `step!` declares it like the
other two advances (§13.5, D-255): `t_end` and `stop_on` are its keywords,
`Inf` and no faces by default, validated per call. `t_end` reached, a
`stop_on` face holding, or a pending control
stop ends the run *inside* the call through the deviceless §12.4 tail,
leaves the simulation terminally `stopped` with the §13.5 record set, and
returns the frames advanced before the stop — fewer than requested, which is
how a harness detects the truncation without inspecting the clock. A
loop-side failure ends it `errored` exactly as under `run!` (§13.6).

In `:replay` the frames come from the recording rather than the cells and the
recording is the bound (§12.7, D-218): a `step!` past its end advances only to
the last recorded frame and returns the truncation the same way, the mode
turning `:live` there.
"""
function step!(sim::Simulation; frames = nothing, t_plus = nothing,
               t_end = Inf, stop_on = ())
    ctl = sim.control
    _assert_advanceable(sim, :step!)
    # own keywords first, then the policy, then the write: `replay!`'s order too
    frames === nothing || t_plus === nothing ||
        throw(DiagnosticError(ArgumentInvalid(call = :step!, reason = :both_given)))
    if t_plus === nothing
        nf = frames === nothing ? 1 : frames
        nf isa Integer && nf ≥ 1 || throw(DiagnosticError(
            ArgumentInvalid(call = :step!, reason = :range, argument = :frames, value = nf)))
        nf = Int(nf)
    else
        t_plus isa Real && isfinite(t_plus) && t_plus > 0 || throw(DiagnosticError(
            ArgumentInvalid(call = :step!, reason = :range, argument = :t_plus, value = t_plus)))
        t = sim.exec.clock.t                  # the frame top the duration counts from
        nf = max(1, _frames_to(t + Float64(t_plus), t, sim.deployment.h))
    end
    pol = _bind_policy(sim, t_end, stop_on, :step!)   # this advance's policy (§13.5, D-255)
    sim.run.policy = pol
    t_end_frame = _t_end_frame(sim, pol.t_end)
    @atomic :release ctl.lifecycle = :running   # the freeze holds within the call
    term, adv, err_src = nothing, 0, nothing
    try
        # §12.7: in `:replay` the recording is the bound, so a `step!` past its
        # end advances only to the last recorded frame and returns fewer frames
        # than asked — the truncation the caller reads (D-218)
        upto = _replay_bound(sim, sim.exec.clock.step + nf)
        (term, adv) = _advance!(sim, pol, upto, t_end_frame)
    catch err
        err_src = LoopError(err)              # the record is assembled below,
        rethrow()                             # after the sweep (D-203)
    finally
        if err_src !== nothing                # §13.6, the stepped entry: same tail,
            _finish!(sim)                     # deviceless — waits woken, accounts swept
            sim.run.termination = _record(sim, err_src, _sweep_tail!(sim))
            @atomic :release ctl.lifecycle = :errored
        else
            _settle_mode!(sim)                # §12.7's flip, at the halt (D-218)
            if term === nothing
                @atomic :release ctl.lifecycle = :initialized
            else                              # a §13.5 source fired inside the call:
                _finish!(sim)                 # the deviceless §12.4 tail, then terminal
                sim.run.termination = _record(sim, term, _sweep_tail!(sim))
                @atomic :release ctl.lifecycle = :stopped
            end
        end
    end
    adv
end

"""
    stop!(sim)

Request a control-plane stop from any task (§12.1) — the calling code's
spelling of the stop a device handle issues with `stop!(handle)`, `:code`
riding as its issuer into the termination record (D-203). The loop observes
the word at the next frame top, completes that boundary, publishes, and
enters the tail (§12.4). Idempotent — a later issuer loses the first-wins
CAS; inert while stopped, the word being cleared at the top of the next run.
"""
stop!(sim::Simulation) = _request_stop!(sim.control, :code)

# --- the roster (§11.3): stopped-sim configuration -----------------------------

"""
    attach!(sim, dev::AbstractDevice, b::AbstractBinding;
            should_abort = false) -> DeviceHandle

Roster a device under a binding — a stopped-sim configuration operation
(`ServiceLifecycle` while running, the roster being frozen per run, pause
included, and on an errored simulation, which no run follows — D-232). The
binding's conformance check runs first (§11.6), then the
three-part admission in spec order (§11.3): identity — this instance already
rostered is `AlreadyAttached`, rebinding being spelled `detach!` then
`attach!` — affinity (`CallerTaskConflict`: at most one `needs_calling_task`
holder), and claims (`ClaimConflict`, which the identity check having run
first always makes two *distinct* devices). On the input side the claim is
staked from its source — the enumeration called once, or the unclaimed
complement computed at this instant and never recomputed, so attaching the
greedy claimant last is the idiom and a second greedy stakes the empty
remainder under an `EmptyGreedyClaim` warning, raised into the new entry's own
diagnostic cell and logged once here (§11.6, §11.8, D-250) — the entry's writer is
compiled over it, and the harness writer's surface is recompiled to the
complement that remains, renormalizing any pending harness batch (§11.4). On
the output side `reads(b)` is called once, resolved against the build and
compiled to the one gather `gather(handle, snap)` runs (§11.2, §14.4) — a
binding that drifted from its model fails here, not with silent garbage on
the wire. An output-only binding stakes no claim: its write surface is empty,
and the harness writer keeps every face.

`should_abort` is §11.6's per-attachment failure policy, never a device
property: set, the device's departure — its loop body returning, a crash, or
a failed `init!` — also requests a sim stop (§12.4(6)); clear, the run
continues with the device's task absent and its claims held to run end.

Returns the attachment's handle (devices.jl), carrying the entry's stable
device id and the device's capabilities — read, stage, control access — the
same object the wrapper passes to `loop(dev, handle)` on the device's task.
`attach!` never spawns: it registers, and the task appears at the next
`run!` (§11.1).
"""
function attach!(sim::Simulation, dev::AbstractDevice, b::AbstractBinding;
                 should_abort::Bool = false)
    plane = sim.plane
    assert_configurable(sim.control, :attach!)
    check_binding(b)
    check_device(dev)
    for e in plane.roster                          # identity, before claims (§11.3)
        e.dev === dev && throw(DiagnosticError(AlreadyAttached(
            device = _typename(dev), incumbent = _who(e), binding = _typename(e.binding))))
    end
    if needs_calling_task(dev)                     # affinity: a single-slot resource
        i = findfirst(e -> needs_calling_task(e.dev), plane.roster)
        i === nothing || throw(DiagnosticError(CallerTaskConflict(
            device = _typename(dev), incumbent = _who(plane.roster[i]))))
    end
    claim = is_input(b) ? _claim(plane, sim.exec.act.layout, b, _typename(dev)) : Symbol[]
    claim_diags = Diagnostic[]
    for f in claim                                 # claims: face exclusivity
        haskey(plane.claimedby, f) && push!(claim_diags, ClaimConflict(
            face = f, device = _typename(dev), incumbent = plane.claimedby[f]))
    end
    isempty(claim_diags) || throw(DiagnosticError(claim_diags))
    # The output side: reads → one gather, resolved before admission commits.
    rg = is_output(b) ? _compile_gather(sim.exec.act.layout, reads(b), typeof(b),
                                        _typename(dev)) : nothing
    id = plane.next_id                             # assigned on admission alone: a
    plane.next_id += 1                             # rejected attach consumes no id
    w = Writer(sim.exec.act.layout, claim)
    diag = DiagCell(EMPTY_DIAG)                    # the device's diagnostic cell (§11.8)
    h = DeviceHandle(id, "device $id ($(_typename(dev)))", b, w, plane, sim.control,
                     sim.plane.published, diag, rg, sim.control.counter, false)
    push!(plane.roster, RosterEntry(dev, b, id, w,
                                    _drain_thunk(sim.exec.store, w, plane.recorder, 0),
                                    should_abort, diag, WriterAccount(), h))
    # the writer index above is a placeholder: `reclaim!` appends the new writer
    # set to the trace's schema list and recompiles every thunk against it (§11.5)
    reclaim!(plane, sim.exec.act.layout)
    if is_greedy(b) && isempty(claim)
        # `attach!` mutates the roster, so the warning lives in the entry's own
        # cell (§11.3, §11.8, D-250): the first frame-top drain folds it into the
        # entry's account and every status from there on carries it. The line at
        # return stays, as presentation.
        egc = EmptyGreedyClaim(device = "device $id ($(_typename(dev)))",
                               binding = _typename(b))
        _report!(diag, egc)
        @warn logline(egc)
    end
    h
end

"""
    detach!(sim, dev)

Release a rostered device — the same stopped-sim gate as `attach!`. The
claims are released and the harness writer's surface regains them; a
pending undrained batch in the entry's cell is discarded with it, detach
being a deliberate reconfiguration, while the root inputs it fed hold their
last-drained values. The device id retires with the entry, never reused.
The handle `attach!` returned outlives the entry as an object only: its
`stage!` and `report!` refuse by name from here on, its reads stay legal
(D-244).
"""
function detach!(sim::Simulation, dev::AbstractDevice)
    plane = sim.plane
    assert_configurable(sim.control, :detach!)
    i = findfirst(e -> e.dev === dev, plane.roster)
    i === nothing && throw(DiagnosticError(NotAttached(
        device = _typename(dev), roster = [_who(e) for e in plane.roster])))
    @atomic :release plane.roster[i].handle.detached = true   # D-244
    deleteat!(plane.roster, i)
    reclaim!(plane, sim.exec.act.layout)
    nothing
end

# --- the data plane (§11): staging, the drain, publication ---------------------

"""
    stage!(sim, "face" => value, ...)          # the harness writer (§11.3)

Stage a batch of root-input writes from any task, at any wall-clock moment,
never touching a live root input (§11.1): the entries land in the writer's staging
cell under the one coalescing policy — CAS merge, newest wins per face
(§11.4). Untouched faces survive into the pending batch; re-staged faces take
the newest level. Every check runs here, on the writer's side, its findings
written into the harness writer's diagnostic cell (§11.8): a face outside
the harness surface is discarded — `ClaimedFaceEntry` naming the incumbent
when a rostered claim covers the face (a rostered greedy claimant empties the
harness surface outright, D-192) and `OutOfClaimEntry` when nothing does — an
unconvertible value under `EntryTypeMismatch`, and the rest of the batch
stands. The staged batch is applied by the drain at the top
of the next frame `run!` advances. A device stages through the handle its
`attach!` returned — `stage!(handle, pairs...)`, devices.jl — the same shim
against its own claim set.
"""
function stage!(sim::Simulation, pairs::Pair...)
    plane = sim.plane
    w = plane.harness
    batch = _normalize(w, pairs, plane.claimedby, plane.harness_diag)
    batch === nothing || _stage!(w, batch)
    nothing
end

"""
The drain (§11.4): exactly one point in each frame, at its top, where the loop
takes each staged batch with one `atomicswap(cell, nothing)` — an indivisible
take, so there is no lost-write window — and applies it through the entry's
compiled scatter, masked-off positions skipped, every check long since spent
at staging.
Cells drain in attachment order, the harness writer's last by convention:
with every surface disjoint the order is unobservable, so the rule exists to
make the record read the same way every time, not to arbitrate (§11.3). Never
at a `t*` boundary (§10.4). Between drains the loop owns its data exclusively,
and the frame's outcome is a pure function of the drained batches.

The drain is also the trace's conversion site (§11.5, D-176): the drained
tuple is the *coalesced* truth, so each taken batch is recorded sparse against
its writer's schema on the way through — inside the thunk, where the writer's
index is closed over — and the frame's ordinal is stamped here, once, before
any thunk runs.

And it is the site of D-101's second substitution: in `:replay` the drain reads
the *trace* instead of the cells (`_replay_drain!` below). The branch is the
whole of the substitution — the live path underneath is untouched, which is
what "the ordinary loop" means (§12.7) — and what selects it is the input mode
the caller can read, not the incidental presence of a recording (§12.6, D-218).
"""
function drain!(sim::Simulation)
    plane = sim.plane
    reg = plane.recorder
    cur = sim.exec.cursor         # the one store per frame that keeps a stale frame from
    cur.comp = 0; cur.fn = :none  # being reported for a drain-side throw (§13.4)
    _phase!(cur, :drain)
    # the ordinal this frame's records take (§11.5): the drain runs before the
    # clock's step increments, so a batch taken at the top of frame `k` is
    # recorded — and replayed — at `k`
    reg.enabled && (reg.frame = sim.exec.clock.step + 1)
    sim.run.mode === :replay && return _replay_drain!(sim, reg, _feed(reg))
    for e in plane.roster
        e.drain()
        _fold!(e.acct, e.diag)    # the diagnostic cells drain at the same point (§11.8):
    end                           # retained values into the pending delta, every
    plane.harness_drain()         # occurrence into the totals
    _fold!(plane.harness_acct, plane.harness_diag)
    _fold!(sim.plane.loop_acct, sim.plane.loop_diag)
    # one drain per frame: the recording's length (§11.5). Counted through the
    # run, whose `trace` is the concrete `Trace{T}`, so the frame path stays free
    reg.enabled && (sim.run.trace.frames += 1)
    nothing
end

"""
D-101's second substitution: the frame's inputs come from the recording, and
the live cells are drained only to be *dropped*.

Every cell is still taken — the same indivisible swap, in the same order — so
nothing accumulates behind the replay and the continuation that may follow
starts clean; what changes is that the batch is discarded rather than applied,
and reported on its own writer's cell (§11.8's attribution rule: the emitting
site knows whose cell it writes). Mixing a live write into a replay would
destroy the property replay exists to provide (§12.7), and the rate limit
§11.8 asks for is structural: the drain takes each cell once per frame, and
coalescing makes a taken batch at most one per writer per frame.

The feed then applies every record whose frame has arrived — the compiled
scatters `_compile_feed` built against *this* layout, so no name is resolved
here either — and re-records each one under the recording's own writer index,
the header having been inherited (§12.7). The cursor only advances: the feed is
in drain order, and the loop visits frames in it.
"""
function _replay_drain!(sim::Simulation, reg::TraceRegister, feed::ReplayFeed)
    plane = sim.plane
    frame = sim.exec.clock.step + 1
    for e in plane.roster
        _discard_staged!(e.writer, e.diag, frame)
        _fold!(e.acct, e.diag)        # the diagnostic fold is the live path's, unchanged
    end
    _discard_staged!(plane.harness, plane.harness_diag, frame)
    _fold!(plane.harness_acct, plane.harness_diag)
    _fold!(sim.plane.loop_acct, sim.plane.loop_diag)
    i, n = feed.next, length(feed.records)
    # keyed exactly: the records are stably sorted by `(frame, writer)`, the entry
    # pass has validated every ordinal into `1:frames`, and the loop visits each
    # frame in `[1, upto]` once — so `==` cannot strand the cursor, and the
    # records past a `to_boundary` truncation are correctly left unapplied
    while i ≤ n && feed.records[i].frame == frame
        r = feed.records[i]
        r.thunk()
        # the recording's own `TraceBatch`, re-recorded as an equal value rather
        # than shared: re-recording is not a re-conversion — the prefix is
        # bit-identical by construction — but the two traces are two values
        reg.enabled && push!(reg.trace.batches,
                             TraceBatch(r.record.frame, r.record.writer, copy(r.record.entries)))
        i += 1
    end
    feed.next = i
    reg.enabled && (sim.run.trace.frames += 1)
    nothing
end

# One cell's take under a feed (§12.7): the batch is dropped, and what the drop
# cost — the faces it touched, read off the mask against the writer's schema —
# is reported on the writer's own diagnostic cell.
function _discard_staged!(w::Writer, cell::DiagCell, frame::Int)
    ref = @atomicswap w.cell.pending = nothing
    ref === nothing && return nothing
    mask = ref[].mask
    _report!(cell, ReplayDiscardedStaging(Symbol[w.faces[i] for i in 1:length(mask) if mask[i]],
                                          frame))
    nothing
end

"""
Publish this boundary (§11.2): build the snapshot in private memory — one
buffer copy, the framework side of §7.5's scope — then a single release-store
to `latest`. Runs only after the boundary sequence completes, so every
published table is boundary-consistent (§10.3), and the copy is what makes the
binding rule hold: nothing reachable from a published snapshot is ever written
again. The framework status is built here too (§11.8): each writer's record
takes the account's pending delta — so the drain's `recent` rides exactly one
snapshot, the first published after the frame top — beside the totals copy,
the heartbeat acquire-load and the `task_state` read off the run's `Task`
handle (D-193), fresh at every publication. Behind the store the snapshot
enters the log (§11.2) — logging dissolves into publication, retention being
the only thing the log adds — and the §12.3 counter increments under its
lock, *after* the release-store: the normative order, so a waiter observing
the new count finds at least this boundary in `latest`. The snapshot's
ordinal is the trajectory's, off the clock (D-230); the counter is the wait
predicate's alone.
"""
function publish!(sim::Simulation)
    ctl = sim.control
    clock = sim.exec.clock
    snap = Snapshot(clock.t, clock.step, clock.boundary, capture(sim.exec.store),
                    sim.exec.act.layout, _status(sim))
    clock.boundary += 1
    @atomic :release sim.plane.published.latest = snap
    log!(sim.run.log, snap)
    lock(ctl.cond)
    try
        ctl.counter += 1
        notify(ctl.cond)
    finally
        unlock(ctl.cond)
    end
    nothing
end

# One writer's record (§11.8): the account's pending delta is *taken* — the
# status owns the vector, the account re-arms the shared empty — and the
# totals, isbits, copy by read. `hb` and `ts` are `nothing` for the two
# writers with no task of their own.
function _writer_status(who::String, a::WriterAccount, hb, ts)
    ws = WriterStatus(who, a.recent, a.suppressed, a.totals, hb, ts)
    a.recent = EMPTY_RECENT
    a.suppressed = KindCounts()
    ws
end

# The status assembly (§11.8, §11.2), on the publishing task: per-writer
# records in the drain's order — devices in attachment order, then the
# harness writer, then the loop itself.
function _status(sim::Simulation)
    plane = sim.plane
    ws = Vector{WriterStatus}(undef, length(plane.roster) + 2)
    for (i, e) in enumerate(plane.roster)
        t = get(plane.run_tasks, e.id, nothing)
        ws[i] = _writer_status(_who(e), e.acct, _heartbeat(e.diag), _task_state(t))
    end
    ws[end-1] = _writer_status("harness", plane.harness_acct, nothing, nothing)
    ws[end] = _writer_status("loop", sim.plane.loop_acct, nothing, nothing)
    FrameworkStatus(ws)
end

"""
    latest(sim)

Acquire-load the most recently published snapshot — `nothing` before the first
`init!`. A reader on any task observes an immutable, coherent world for as
long as it holds the value, without coordinating with the loop; the calling
task reads the same reference, §12.6's inspection read.
"""
latest(sim::Simulation) = @atomic :acquire sim.plane.published.latest

"""
    logged(sim)

The log's retained snapshots, oldest first (§11.2): the boundary-zero
endpoint, the bounded middle at the effective stride, and the terminal
endpoint — the latest published boundary — deduplicated when retention
already holds it. A stopped-sim read behind the §11.3 gate: the log is
loop-task bookkeeping, so reading it beside a running loop is the same
hazard class as a mid-run `attach!`; a concurrent reader's inspection read is
`latest(sim)`, and it holds snapshots or loses them (§11.2). Empty before
the first `init!`, and empty under `log = false` — the switch gates
retention wholesale.
"""
function logged(sim::Simulation)
    assert_stopped(sim.control, :logged)
    L = sim.run.log
    out = Snapshot[]
    L.first === nothing && return out
    push!(out, L.first)
    for s in L.snaps
        s === nothing || push!(out, s)
    end
    L.last === out[end] || push!(out, L.last)
    out
end

"""
    trace(sim)

§11.5's recording, as a value detached from the register: the header captured
at the last `init!`, the sparse records of every batch drained since, and the
number of frames drained behind them. Header plus batches are the run's
*primary* record — the state trajectory, the log included, is derived from it
(D-038) — and what consumes it is `replay!` (§12.7).

Refused under `trace = false`, the construction-time kill switch (D-029), and
before the first `init!`, which is where the header is captured: with no
header there is no recording, and `MissingInit` names the way out exactly as
an advance entry's refusal does (§12.6).
"""
function trace(sim::Simulation{T}) where {T}
    sim.plane.recorder.enabled ||
        throw(DiagnosticError(ArgumentInvalid(call = :trace, reason = :disabled)))
    t = sim.run.trace
    t.header === nothing &&
        throw(DiagnosticError(MissingInit(op = :trace, status = lifecycle(sim))))
    Trace{T}(t.header, copy(t.schemas), copy(t.batches), t.frames)
end

# --- reading and writing the table outside the loop ---------------------------
# Path-addressed, dictionary-driven, deliberately off the measured path: these
# are boundary-time operations, never called from inside a phase body. Paths are
# §8.6's canonical strings, and an assembly's own path addresses its faces —
# which resolve to the cells they derive from.

port(sim::Simulation, path::String, name::Symbol) =
    gather(sim.exec.store, sim.exec.act.layout.addr[(path, name)])

"""
State at `path`, from whichever home owns it: `x` in the flat buffer on the
continuous tier, `s` in the component's own store on the discrete one (§7.3).
"""
function state(sim::Simulation{T}, path::String) where {T}
    ci = index_of(sim.deployment.build.structure, path)
    sim.exec.sstores[ci] === nothing || return sim.exec.sstores[ci][]
    _tier(i) = sim.deployment.build.structure.tiers[i]
    _decls(i) = declarations(sim.deployment.build.structure.comps[i], _tier(i), T)
    off = 0
    for i in 1:(ci-1)
        _tier(i) === CONTINUOUS && (off += nleaves(typeof(_decls(i).x)))
    end
    reconstruct(typeof(_decls(ci).x), sim.exec.xbuf, off)
end

"""Modes at `path` (§7.3). Read-only here: modes are written by handlers alone."""
modes(sim::Simulation, path::String) = sim.exec.mstores[index_of(sim.deployment.build.structure, path)][]
