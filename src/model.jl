# The model layer (§9.2, §12.6, D-317): a deployment materialized at one
# scalar, and everything done to it with no simulation around it — the frame's
# hooks, the doors, evaluation, the boundaries, the stepper seam's framework
# side, the reads, the one `StepError` constructor and the checkpoint's
# model-level half. Every door that writes the model's status lives here; the
# one other writer is `frame!`'s catch site (frame.jl).

"""
    Model(deployment::Deployment, T = Float64; chunk_size = 16)
    Model(build::Build, T = Float64; h, N_base = nothing, Δt_base = nothing,
          algorithm = RK4, firing_budget = 4, localization_tol = 1e-6,
          localization_budget = 8, chunk_size = 16)
    Model(root, T = Float64; …)

A deployment materialized at one scalar `T` (§9.2, D-317): the `Deployment` and
the `Executor` compiled from it, the activation that can be written to,
evaluated and stepped. It runs nothing in real time, talks to no device and
records nothing; a `Simulation` does that around a `Model{Float64}`.

Deploying and materializing are two steps (D-254). The `Deployment` is
scalar-free and one backs many models; this call fixes the scalar, allocating
the buffers. The scalar picks the activation the entries compile over, through
`activation(deployment.build, T)`, which serves the nominal `Float64` entry the
build inserted and derives and caches any other (§9.4). `chunk_size` is the
unroll width `compile` takes. The two other forms are *defined as* the
compositions: `Model(build; kw…)` is `Model(Deployment(build; grid kw…), T;
chunk_size)`, and `Model(root; kw…)` calls `build` first.

- `deployment`: what the grid parameters fixed (§9.1, D-254), and through it
  the build, the schema authority a condition resolves against (§14.3). Held
  once: a second reference would be an invariant with no enforcer (§12.1,
  D-256).
- `exec`: the executor this model owns (§9.2, §9.7), with its stepper,
  arrival buffers and `chunk_size`. Every buffer set has exactly one owner, so
  a service invocation instantiates an executor of its own from the same
  cached layouts rather than writing through this one.
- `status`: `:built` until boundary zero completes, `:consistent` once it has
  completed or a checkpoint has been restored, and `:inconsistent` after a
  throw inside a frame. A throw inside boundary zero writes `:built`. Only the
  model's own doors and catch sites write it, and `lifecycle(sim)` reads it
  (§12.6, D-317).
- `claimed`: set once by `Simulation(model)` through a compare-and-swap and
  never cleared, so a simulation owns its model and never shares it (§9.2,
  §12.6, D-318).
- `frame_diag`: the frame's own diagnostic cell, where the chattering and
  firing-budget reports go. A simulation's drain folds it into the loop's
  account beside the loop's own cell (§11.8, D-317).
"""
mutable struct Model{T,E}
    const deployment::Deployment
    const exec::E
    @atomic status::Symbol
    @atomic claimed::Bool
    const frame_diag::DiagCell
end

function Model(deployment::Deployment, ::Type{T} = Float64; chunk_size::Int = 16) where {T}
    act = activation(deployment.build, T)
    exec = compile(deployment.build, act, deployment.schedule; chunk_size,
                   algorithm = deployment.algorithm)
    Model{T,typeof(exec)}(deployment, exec, :built, false, DiagCell(EMPTY_DIAG))
end

# The two sugar forms, each *defined as* the composition (§9.2, D-254).
Model(build::Build, ::Type{T} = Float64; h = nothing, N_base = nothing,
      Δt_base = nothing, algorithm = RK4, firing_budget = 4,
      localization_tol = 1e-6, localization_budget = 8, kw...) where {T} =
    Model(Deployment(build; h, N_base, Δt_base, algorithm, firing_budget,
                     localization_tol, localization_budget), T; kw...)
Model(root::AbstractComponent, ::Type{T} = Float64; kw...) where {T} =
    Model(build(root), T; kw...)

"""
    FrameHooks
    frame_top!(hooks)
    settled!(hooks) → Bool

What a model's frame calls out to (§10.4, §11.2, D-317). `frame!(model, k,
hooks)` and the model's `init!` take one value of a `FrameHooks` subtype, a
struct with concrete fields built once per advance, and call two generic
functions on it:

- `frame_top!(hooks)` runs first, before the model touches any state. It is
  where external inputs arrive.
- `settled!(hooks)` runs at every settled boundary before integration resumes:
  the `t*` boundaries, the frame top's and, in `init!`, boundary zero's. It
  returns whether to abandon the frame's remainder, and a `true` is `frame!`'s
  return. §11.2's rule that every boundary publishes before integration
  resumes is a contract on it.

`NoHooks()` does nothing and returns `false`, for a model stepped on its own;
the simulation's are `LoopHooks` (sim.jl).
"""
abstract type FrameHooks end

"The hooks of a model stepped on its own: nothing at the top, never an abandon (D-317)."
struct NoHooks <: FrameHooks end

frame_top!(::NoHooks) = nothing
settled!(::NoHooks) = false

# The claim's gate at the top of each model door (D-318): a claimed model
# refuses every hooks but its simulation's. The `LoopHooks` method (sim.jl)
# returns `nothing`, so dispatch compiles the check away on the loop's path.
_claimed_gate(model::Model, ::FrameHooks, call::Symbol) =
    (@atomic :acquire model.claimed) && throw(DiagnosticError(ArgumentInvalid(
        call = call, reason = :claimed, argument = :model)))

"""
    init!(model, condition = fragment(); t0 = 0.0, hooks = NoHooks())
    init!(model, plan::ConditionPlan; t0 = 0.0, hooks = NoHooks())

The model's door into `:consistent` (§14.5, D-317): the state at the declared
defaults with the condition's overrides applied, the clock at `t₀`, every
event prior not-holding, and boundary zero run. The condition resolves and its
root-input totality is checked before any write (§14.3, §14.6). The plan method
does the writes alone, so the simulation's `init!` can resolve before it
touches its run. Boundary zero settles through `settled!(hooks)`, whose return
nothing reads here.

The plan method hosts §13.4's catch around boundary zero (D-223): a throw
inside it takes the one `StepError` constructor, with the frame from the
cursor, `t₀`, pointer 0 and host `:boundary_zero`, and writes the status back
to `:built`. An interrupt is not model code failing and has no stop path here,
so it writes the status and propagates raw.
"""
function init!(model::Model{T}, condition = fragment(); kw...) where {T}
    plan = resolve_condition(condition, model.deployment.build, T)   # both refusals precede every write
    assert_total(plan, model.deployment.build.structure, :init!)     # (§14.6): all-or-nothing
    init!(model, plan; kw...)
end

function init!(model::Model{T}, plan::ConditionPlan; t0::Real = 0.0,
               hooks::FrameHooks = NoHooks()) where {T}
    _claimed_gate(model, hooks, :init!)
    exec = model.exec
    establish_defaults!(exec.xbuf, exec.sstores, exec.mstores,
                        model.deployment.build.structure.components,
                        activation(model.deployment.build, T).decls)   # D-063's reset
    _apply_plan!(model, plan)
    exec.clock.t = Float64(t0)        # the origin at the door, into the deployment's scalar (D-260)
    exec.clock.t₀ = Float64(t0)       # exact: the clock's origin is a `Float64` too
    fill!(exec.events.prior, false)   # every prior not-holding (§10.6)
    try
        boundary_zero!(model)
    catch err
        @atomic :release model.status = :built
        err isa InterruptException && rethrow()
        rethrow(_wrap_step(model, 0, :boundary_zero, err))
    end
    settled!(hooks)                   # the boundary-zero snapshot (§11.2, §14.5)
    @atomic :release model.status = :consistent   # boundary zero completed (D-317)
    nothing
end

# The public door gates; the simulation's forwarding method and `init!` take
# the inner one (D-318).
apply!(model::Model, plan::ConditionPlan) =
    (_claimed_gate(model, NoHooks(), :apply!); _apply_plan!(model, plan))
_apply_plan!(model::Model, plan::ConditionPlan) = apply!(model.exec, plan)

"""
    phase_bodies(model)
    phase_bodies(sim)

The compiled bodies of the model's activation, bound over its own buffers, and
a simulation's are its nominal model's — **these are the bodies the loop runs**, not re-derivations, which is
what makes the §7.5 measurement honest. The roster is fixed and total: a model
with no discrete components still gets `ticks`, empty, compiling to a no-op
whose `@ballocated` assertion passes vacuously, so consumers iterate uniformly
with no per-model branching. Beside the four blocks ride `events`, the guard
and handler per event keyed by `(path, name)`, and `projections`, the
`x_projection` call per component keyed by path — each a zero-argument
callable over the same buffers.
"""
phase_bodies(model::Model) = model.exec.bodies

# --- evaluation ---------------------------------------------------------------

"""
One RHS evaluation: *evaluating the RHS means running the sweep* (§5.3). The
interior variant of each sweep block, then the `x_deriv` block
against the complete fresh table. Leaves `ẋbuf` holding the derivative of
whatever `xbuf` holds.
"""
@inline function evaluate!(exec::Executor)
    exec.cursor.index += 1          # §13.4: the stage ordinal counts RHS evaluations,
    exec.bodies.sweep_1()           # so the backends stay untouched
    exec.bodies.sweep_2()
    exec.bodies.rhs()
    nothing
end

@inline evaluate!(model::Model) = evaluate!(model.exec)

"""
The boundary macro-sequence at a base tick, final form (§5.3, §10.6):

> integrate → project → [sweep → guards → handlers] iterated to quiescence
> (under the firing budget) → all due `s_update` calls

Integration has just written the state, so projection runs first — between the
write and its decode; the event phase then iterates with the due set fixed for
the whole boundary, and the due updates run last, after quiescence, reading
post-transition values off the settled table. Output stages before updates, so
a discrete component's cells carry `y[k]` computed from `s[k]` while
`s_update` produces `s[k+1]` — the sampled-data recursion, ordered by
construction rather than by convention.

The three boundary routines run on the model, and the event phase reports a
`FiringBudget` into the model's `frame_diag` (§11.8, D-317).
"""
@inline function boundary!(model::Model, tick::Int)
    cursor = model.exec.cursor
    _phase!(cursor, :project)
    _projects!(model.exec.events, model.exec.xbuf)
    event_phase!(model, tick)
    _phase!(cursor, :ticks)
    model.exec.bodies.ticks(tick)
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
@inline function offtick_boundary!(model::Model)
    _phase!(model.exec.cursor, :project)
    _projects!(model.exec.events, model.exec.xbuf)
    event_phase!(model, nothing)
    nothing
end

"""
Boundary zero's macro-sequence (§14.5, D-205): the ordinary one, with the
sweep's discrete entries admitted **due or not**. Every output stage runs and
publishes — from the authored `s` and the `t₀` table, in the ordinary sorted
walk — so the `t₀` snapshot carries the authored world fully evaluated and no
published cell holds the probe's synthesized values (§14.6's barrier extended
from the root inputs to the whole table).

The `s_update` calls keep the ordinary gate at index 0, which under the
canonical residue admits exactly `Φ = 0` (§10.5): that evaluation is
establishment, not a scheduled sample, and an offset component's first
*consumed* sample stays its `Φ·Δt_base` tick's. A component frozen at a
non-nominal activation has no entries here at all (§9.4's executable set), so
its pinned cells keep the carried nominal products — at boundary zero as
everywhere.

Never called bare: the model's `init!` (above) hosts it, the one door
that runs it (D-274), wrapping a throw as §13.4's catch does (D-223, D-317).
"""
@inline function boundary_zero!(model::Model)
    cursor = model.exec.cursor
    _phase!(cursor, :project)
    _projects!(model.exec.events, model.exec.xbuf)
    event_phase!(model, ESTABLISH)
    _phase!(cursor, :ticks)
    model.exec.bodies.ticks(0)
    nothing
end

# One iteration round's sweep: the whole gated schedule (§10.6), in the due-set
# arity the boundary fixed — never the update laws, which wait for quiescence.
@inline _round!(exec::Executor, tick::Int) =
    (exec.bodies.sweep_1(tick); exec.bodies.sweep_2(tick); nothing)
@inline _round!(exec::Executor, ::Nothing) =
    (exec.bodies.sweep_1(); exec.bodies.sweep_2(); nothing)
# Boundary zero's round: the whole schedule, gated by nothing (§14.5, D-205).
@inline _round!(exec::Executor, tick::Establish) =
    (exec.bodies.sweep_1(tick); exec.bodies.sweep_2(tick); nothing)
@inline _round!(model::Model, tick) = _round!(model.exec, tick)

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
function event_phase!(model::Model, tick)
    events, cursor = model.exec.events, model.exec.cursor
    _phase!(cursor, :round, 1)       # §13.4: the boundary sweep is round 1, and the guard
    _round!(model, tick)            # walk and the fire walk of a round carry its index
    n_events = length(events.prior)
    n_events == 0 && return nothing
    copyto!(events.last, events.prior)
    fill!(events.count, 0)
    fill!(events.warned, false)
    budget = model.deployment.firing_budget
    while true
        _guards!(events, model.exec.store, model.exec.xbuf)
        fill!(events.comp_fired, false)
        any_fired = false
        for i in 1:n_events
            edge = !events.last[i] && events.now[i]
            eligible = edge && events.count[i] < budget
            if edge && !eligible && !events.warned[i]
                events.warned[i] = true       # at most one report per event per boundary
                (path, name) = events.names[i]
                # the frame's own cell (§11.8, D-317): folded at the next frame top
                report_cell!(model.frame_diag,
                             FiringBudget(path, name, _seconds(model.exec.clock.t), budget,
                                          events.count[i]))
            end
            firing = eligible && !events.comp_fired[events.owner[i]]
            events.fire[i] = firing
            if firing
                events.comp_fired[events.owner[i]] = true
                events.count[i] += 1
                any_fired = true
            end
            # A blocked edge stays unconsumed (D-191): only the eligible-but-
            # blocked sample stands; every other event takes this round's.
            (eligible && !firing) || (events.last[i] = events.now[i])
        end
        any_fired || break
        _fire!(events, model.exec.store, model.exec.xbuf)
        cursor.index += 1
        _round!(model, tick)
    end
    copyto!(events.prior, events.last)
    nothing
end

# --- the stepper seam, framework side (§10.2) ----------------------------------

"""
    integrate!(model, h)
    integrate!(sim, h)

Advance the continuous state from `t` by `h`, delegated across the stepper
seam to whichever backend the deployment bound (stepper.jl). The seam is never
entered empty: with no continuous state the step degenerates to advancing `t`,
the backend is simply not called, and no backend contract has to say what it
would do at N = 0.
"""
@inline function integrate!(model::Model, h)
    _phase!(model.exec.cursor, :integrate)     # §13.4: `evaluate!` counts the stages from here
    isempty(model.exec.xbuf) ? (model.exec.clock.t += h) : integrate!(model.exec.stepper, model, h)
    _check_finite!(model)
    nothing
end

# The boundary's first act (D-157, §13.4): one pass over the flat state buffer,
# immediately after the backend returns and before anything reads the state —
# `frame!`'s bare path and every segment of a localized frame alike, which is
# why the site is the seam's framework side and not the frame loop. `ẋ` does
# not participate: a nonfinite derivative contaminates its own block's step
# result within that very step, so this is the same detection with the same
# attribution, and `ẋ` is integrator scratch besides.
@inline function _check_finite!(model::Model)
    x = model.exec.xbuf
    @inbounds for i in eachindex(x)
        isfinite(x[i]) || _nonfinite(model, i)      # the throw is the cold path
    end
    nothing
end

# The owner of `flat_index` and its leaf within that component's block, both
# read off the layout's `xblocks`. Thrown as a fail-fast `DiagnosticError`, which
# the catch site's species rule unwraps into the `StepError`'s `cause`.
@noinline function _nonfinite(model::Model, flat_index::Int)
    exec = model.exec
    xblocks = exec.act.layout.xblocks
    owner = findfirst(b -> flat_index in b, xblocks)::Int
    cursor = exec.cursor                    # the phase stays `:integrate`, but the sweep is the
    cursor.comp = owner; cursor.fn = :none  # framework's own act between the stages and the
    cursor.index = 0                        # boundary — no stage of its own, so no ordinal
    x_leaf_names = leaf_names(typeof(exec.act.decls[owner].x))
    throw(DiagnosticError(NonfiniteState(
        path = model.deployment.build.structure.components[owner].path,
        leaf = x_leaf_names[flat_index - first(xblocks[owner]) + 1],
        value = exec.xbuf[flat_index],
        t = _seconds(exec.clock.t),
        # the frame-entry index, off the grid time the clock sits on: every
        # `integrate!` inside `frame!` ends at one, so rounding is exact at any
        # scalar. The counters are the run's, which the model never sees (D-317)
        boundary = round(Int, (_seconds(exec.clock.t) - exec.clock.t₀) / model.deployment.h) - 1)))
end

"""
    warnings(model::Model) → Vector{Diagnostic}
    warnings(sim::Simulation) → Vector{Diagnostic}

The concatenation of the model's artifacts' lists, the build's first and
the deployment's second (§9.2, D-250); a simulation's are its model's.
Warnings raised while *mutating state* live in that state's status record
instead (§11.8), so nothing runtime reaches here.
"""
warnings(model::Model) = vcat(warnings(model.deployment.build), warnings(model.deployment))

# --- reading and writing the table outside the loop ---------------------------
# Path-addressed, dictionary-driven, deliberately off the measured path: these
# are boundary-time operations, never called from inside a phase body. Paths are
# §8.6's canonical strings, and an assembly's own path addresses its faces —
# which resolve to the cells they derive from.

port(model::Model, path::String, name::Symbol) =
    gather_cell(model.exec.store, model.exec.act.layout.addr[(path, name)])

"""
State at `path`, from whichever home owns it: `x` in the flat buffer on the
continuous tier, `s` in the component's own store on the discrete one (§7.3).
"""
function state(model::Model{T}, path::String) where {T}
    ci = index_of(model.deployment.build.structure, path)
    model.exec.sstores[ci] === nothing || return model.exec.sstores[ci][]
    _tier(i) = model.deployment.build.structure.components[i].tier
    _decls(i) = declarations(model.deployment.build.structure.components[i].instance, _tier(i), T)
    x_offset = 0
    for i in 1:(ci-1)
        _tier(i) === CONTINUOUS && (x_offset += nleaves(typeof(_decls(i).x)))
    end
    reconstruct(typeof(_decls(ci).x), model.exec.xbuf, x_offset)
end

"""Modes at `path` (§7.3). Read-only here: modes are written by handlers alone."""
modes(model::Model, path::String) =
    model.exec.mstores[index_of(model.deployment.build.structure, path)][]

# The one `StepError` constructor (§13.4, D-059): the frame from the cursor, the
# clock at the failure, the frame-entry boundary as the replay pointer, the host
# its caller names, and the cause under the species rule below. Nothing inside
# the sequence throws a `StepError`, so one arriving here is an invariant firing,
# not a re-wrap. Two callers reach it, both the model's catch sites (D-317):
# `frame!` (frame.jl) as `:loop`, and the model's `init!` (above)
# around boundary zero as `:boundary_zero` (D-223). It stays the only
# constructor.
function _wrap_step(model::Model, entry_boundary::Int, host::Symbol, err)
    err isa StepError && throw(InternalInvariant(
        "a StepError reached the catch site (§13.4), which is its only constructor — " *
        "something inside the boundary sequence wrapped one"))
    cursor = model.exec.cursor
    StepError(CursorFrame(cursor.comp == 0 ? nothing :
                              model.deployment.build.structure.components[cursor.comp].path,
                          cursor.fn, cursor.phase, cursor.index),
              _seconds(model.exec.clock.t), entry_boundary, host, _species(model, err))
end

# The species rule (§13.4, D-221): a fail-fast carrier thrown inside the
# sequence arrives as its diagnostic unwrapped — which is what lets a runtime
# check (§9.5's conformance failure, the nonfinite sweep) be a plain thrower
# of its kind while the catch site stays the only wrap. A collected carrier has
# no single kind and rides as the cause it is.
_species(::Model, err) = err
_species(::Model, err::DiagnosticError{<:Diagnostic}) = err.carried

# §13.2's bundle-field match at runtime (D-248): a `FieldError` whose type is the
# bundle the cursor's function received is the bundle-law diagnostic, classified
# as at the probe. Any other `FieldError` is the author's own and rides as the
# cause it is. `UserCodeFraming` gets no runtime arm: the carrier already names
# the frame and the function through the cursor.
function _species(model::Model, err::FieldError)
    cursor = model.exec.cursor
    cursor.comp == 0 && return err
    ci, family = cursor.comp, cursor.fn
    comp_entry = model.deployment.build.structure.components[ci]
    comp, tier = comp_entry.instance, comp_entry.tier
    stage1_ports = tuple(model.deployment.build.outputs.components[ci].stage1...)
    # Reading the names invokes declarations, and a throw here would replace the
    # author's error, the cursor frame and the `StepError` with a frame of its own.
    legal_names = try
        family === :guard || family === :handler ?
            event_bundle_names(comp) :
        family === :y_state ?
            bundle_names(y_state, comp, tier, stage1_ports) :
        family === :y_direct ?
            bundle_names(y_direct, comp, tier, stage1_ports) :
        family === :x_deriv || family === :s_update ?
            bundle_names(update_of(tier), comp, tier, stage1_ports) :
        return err
    catch lookup_err
        lookup_err isa InterruptException && rethrow()
        return err
    end
    # By names, not by the exact type: the runtime bundle's value types differ
    # from the probe's at a non-nominal activation, and the names are the law's
    # invariant (§5.2).
    (err.type <: NamedTuple && fieldnames(err.type) == legal_names) || return err
    BundleFieldError(path = comp_entry.path, family = String(family),
                     tier = tier === CONTINUOUS ? :continuous : :discrete, field = err.field,
                     legal = collect(legal_names),
                     reason = classify_bundle_field(family, tier, err.field))
end

# The fingerprint off the model, one function for its two sides: the take
# writes it into the checkpoint and the check compares against it, since two
# spellings of one fingerprint would be a silent way for a restore to pass.
function _fingerprint(model::Model)
    exec = model.exec
    layout = exec.act.layout
    Fingerprint(copy(layout.sizes),
                Symbol[f for (f, _) in layout.root_inputs],
                String[entry.path for entry in model.deployment.build.structure.components],
                Any[isempty(decl.x) ? nothing : typeof(decl.x) for decl in exec.act.decls],
                Any[st === nothing ? nothing : typeof(st[]) for st in exec.sstores],
                Any[st === nothing ? nothing : typeof(st[]) for st in exec.mstores],
                sort!(Pair{Tuple{String,Symbol},Tuple{Any,Tuple}}[
                          key => (_port_type(addr), addr.offsets) for (key, addr) in layout.addr];
                      by = first),
                copy(exec.events.names))   # the priors' own index, empty off the nominal activation
end

# The one read, behind `checkpoint(sim)` and the trace header `init!` takes.
# The stores are copied by value, being isbits (D-231). The counters are the
# run's, passed in, so a standalone model checkpoints too (D-317).
function _take_checkpoint(model::Model, frame::Int, boundary::Int)
    exec = model.exec
    clock = exec.clock
    T = eltype(exec.xbuf)      # the model's scalar, off the buffer that carries it
    s = Any[st === nothing ? nothing : st[] for st in exec.sstores]
    m = Any[st === nothing ? nothing : st[] for st in exec.mstores]
    checkpoint_stepper(exec.stepper)   # empty for a one-step method (stepper.jl)
    Checkpoint{T}(copy(exec.xbuf), s, m, capture_stores(exec.store), copy(exec.events.prior),
                  clock.t, frame, boundary, clock.t₀, model.deployment,
                  _fingerprint(model))
end

# The same restore as a model door (D-317), in `init!`'s shape: the state
# copied back, the restored boundary settled through `settled!(hooks)`, whose
# return nothing reads here, and the status written `:consistent` last.
function _restore_state!(model::Model, cp::Checkpoint; hooks::FrameHooks = NoHooks())
    _claimed_gate(model, hooks, :restore!)
    _restore_state!(model.exec, cp)
    settled!(hooks)                   # the restored boundary's snapshot (§11.2, §12.6)
    @atomic :release model.status = :consistent
    nothing
end
