# The checkpoint (§12.6, D-274, D-319): a model's state as one value, and that
# state beside the run's two counters, the value `checkpoint(sim)` returns and
# `init!` takes for the trace header, put back by `restore!` and `replay!`. This
# file holds the two values and the restore into an executor. The model-level
# functions, the fingerprint, the one read, the fingerprint check and the
# model's restore doors, live in model.jl; the simulation's doors live in
# sim.jl, beside the loop.

"""
The structural fingerprint (§11.5, §12.7): the layout's cell sizes, the root
input-face list, the flat's component paths, each component's `x`, `s` and `m`
store types, every address of the table, `(path, name) => (type, offsets)`
sorted by key, and the events in the priors' order, `(path, name)` each. A
checkpoint carries it, and a restore compares it against the target's: the
restore copies `x`, the table and the priors by position, and the store types,
the addresses and the events are what make the positions mean the same thing.
"""
struct Fingerprint
    sizes::Vector{Pair{DataType,Int}}
    root_faces::Vector{Symbol}
    paths::Vector{String}
    xtypes::Vector{Any}
    stypes::Vector{Any}
    mtypes::Vector{Any}
    addrs::Vector{Pair{Tuple{String,Symbol},Tuple{Any,Tuple}}}
    events::Vector{Tuple{String,Symbol}}
end

"""
A model's state as one value (§12.6, D-274, D-319): the flat buffer, the `s` and
`m` stores (`nothing` where a component owns none), the whole signal table with
every cell buffer copied, the guard priors, the clock's `t` and `t₀`, and the
fingerprint, the `Deployment` and the structural layout. The priors are the one
event register that crosses a boundary: `last` equals them at rest. What every
frame rewrites before reading it, the derivative buffer, the arrival pair and
the localization samples, stays out. The frame index and the boundary ordinal
are the run's, and a `Checkpoint` carries them beside the state. `t` is an
indexed grid time, `t₀ + k·h` as the clock writes it, so a hand-typed decimal
can miss the grid by an ulp and be refused.

The table holds the root-input cells as values, never the authored overlay
(D-038). A model's state is not a condition and has no algebra (D-273). `==` is
identity: compare one field by field.
"""
struct ModelState{T}
    x::Vector{T}                     # the flat buffer
    s::Vector{Any}                   # per component: the store value, or nothing
    m::Vector{Any}                   # likewise for the mode stores
    table::StoreBundle               # the signal table, every cell buffer copied
    prior::Vector{Bool}              # the guard priors
    t::T                             # the clock's time
    t₀::Float64                      # the clock's origin
    deployment::Deployment           # compared as a value at restore (§12.7)
    layout::Fingerprint              # compared against the `Build`
end

"""
A nominal model's state at a frame top beside the trajectory's two counters, the
frame index and the boundary ordinal (§12.6, D-274, D-319): the value
`checkpoint(sim)` returns and a trace's header holds. It has no scalar
parameter, because a cursor belongs to a trajectory and only a nominal model
has one, so the state is a `ModelState{Float64}` by type.
"""
struct Checkpoint
    state::ModelState{Float64}       # the model's state
    frame::Int                       # the run's two counters (D-317)
    boundary::Int
end

# The inverse: every field copied back into the executor, the clock's `t` and
# `t₀` written as the state has them. The counters are the run's, which the
# door opens from the checkpoint (D-317). Nothing is published here and nothing
# runs, so a caller that publishes owns the ordinal.
function _restore_state!(exec::Executor{T}, model_state::ModelState{T}) where {T}
    copyto!(exec.xbuf, model_state.x)
    _restore_stores!(exec, model_state)
    foreach((cell_store, saved) -> copyto!(cell_store.buffer, saved.buffer),
            values(exec.store.stores), values(model_state.table.stores))
    copyto!(exec.events.prior, model_state.prior)
    copyto!(exec.events.last, model_state.prior)
    clock = exec.clock
    clock.t, clock.t₀ = model_state.t, model_state.t₀
    restore_stepper!(exec.stepper, model_state)
    nothing
end

# The `s` and `m` stores by value. A store's type is the same at every
# activation (build.jl's `declarations`, `_mstores`), so `linearize`'s seeded
# scratch takes this write as it is.
function _restore_stores!(exec::Executor, model_state::ModelState)
    for ci in eachindex(model_state.s)
        model_state.s[ci] === nothing || (exec.sstores[ci][] = model_state.s[ci])
    end
    for ci in eachindex(model_state.m)
        model_state.m[ci] === nothing || (exec.mstores[ci][] = model_state.m[ci])
    end
    nothing
end

# A state for the trace that inherits it (§12.7): every mutable field copied, so
# nothing the caller still holds is reachable from the new trace. The
# `Deployment` and the fingerprint are immutable artifacts and ride as they are.
_detach(model_state::ModelState{T}) where {T} =
    ModelState{T}(copy(model_state.x), copy(model_state.s), copy(model_state.m),
                  capture_stores(model_state.table), copy(model_state.prior),
                  model_state.t, model_state.t₀, model_state.deployment, model_state.layout)
_detach(cp::Checkpoint) = Checkpoint(_detach(cp.state), cp.frame, cp.boundary)

# The table's addresses key by key, each named `port.<name>` at its path, with
# `nothing` for a side that lacks the key: first the cells present and their
# types, then, only where those all agree, the offsets. A cell more or less
# shifts every later offset of its type, and the ports behind it are not at fault.
function _check_addresses!(diags::Vector{Diagnostic}, recorded, target)
    recorded_addrs, target_addrs = Dict(recorded), Dict(target)
    port_keys = sort!(collect(union(keys(recorded_addrs), keys(target_addrs))))
    reported = length(diags)
    for differs in (((a, b) -> a === nothing || b === nothing || a[1] != b[1]), !=)
        for key in port_keys
            expected, found = get(recorded_addrs, key, nothing), get(target_addrs, key, nothing)
            differs(expected, found) &&
                push!(diags, CheckpointMismatch(what = :store, path = first(key),
                                                name = Symbol("port.", last(key)),
                                                expected = expected, found = found))
        end
        length(diags) > reported && break
    end
    nothing
end
