# The checkpoint (§12.6, D-274): the executor's state at a frame top as one
# value, taken by `checkpoint(sim)` and by `init!` for the trace header, and put
# back by `restore!` and `replay!`. This file holds the value, the restore into
# an executor and the fingerprint check the two restoring doors share. The
# model-level functions, the fingerprint, the one read and the model's restore
# door, live in model.jl; the doors themselves live in sim.jl, beside the loop.

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
The executor's state at a frame top (§12.6, D-274): the flat buffer, the `s`
and `m` stores (`nothing` where a component owns none), the whole signal table
with every cell buffer copied, the guard priors, the clock's `t` and `t₀`, the
run's frame index and boundary ordinal (D-317), and the fingerprint. The
priors are the one event register that crosses a boundary: `last` equals them
at rest. What every frame rewrites before reading it, the derivative buffer,
the arrival pair and the localization samples, stays out.

The table holds the root-input cells as values, never the authored overlay
(D-038). A checkpoint is not a condition and has no algebra (D-273). `==` is
identity: compare one field by field.
"""
struct Checkpoint{T}
    x::Vector{T}                     # the flat buffer
    s::Vector{Any}                   # per component: the store value, or nothing
    m::Vector{Any}                   # likewise for the mode stores
    table::StoreBundle               # the signal table, every cell buffer copied
    prior::Vector{Bool}              # the guard priors
    t::T                             # the clock's time
    frame::Int                       # the run's two counters (D-317)
    boundary::Int
    t₀::Float64                      # the clock's origin
    deployment::Deployment           # compared as a value at restore (§12.7)
    layout::Fingerprint              # compared against the `Build`
end

# The inverse: every field copied back into the executor, the clock's `t` and
# `t₀` written as the checkpoint has them. The counters are the run's, which
# the door opens from the checkpoint (D-317). Nothing is published here and
# nothing runs, so a caller that publishes owns the ordinal.
function _restore_state!(exec::Executor{T}, cp::Checkpoint{T}) where {T}
    copyto!(exec.xbuf, cp.x)
    _restore_stores!(exec, cp)
    foreach((cell_store, saved) -> copyto!(cell_store.buffer, saved.buffer),
            values(exec.store.stores), values(cp.table.stores))
    copyto!(exec.events.prior, cp.prior)
    copyto!(exec.events.last, cp.prior)
    clock = exec.clock
    clock.t, clock.t₀ = cp.t, cp.t₀
    restore_stepper!(exec.stepper, cp)
    nothing
end

# The `s` and `m` stores by value. A store's type is the same at every
# activation (build.jl's `declarations`, `_mstores`), so `linearize`'s seeded
# scratch takes this write as it is.
function _restore_stores!(exec::Executor, cp::Checkpoint)
    for ci in eachindex(cp.s)
        cp.s[ci] === nothing || (exec.sstores[ci][] = cp.s[ci])
    end
    for ci in eachindex(cp.m)
        cp.m[ci] === nothing || (exec.mstores[ci][] = cp.m[ci])
    end
    nothing
end

# A checkpoint for the trace that inherits it (§12.7): every mutable field
# copied, so nothing the caller still holds is reachable from the new trace.
# The `Deployment` and the fingerprint are immutable artifacts and ride as
# they are.
_detach(cp::Checkpoint{T}) where {T} =
    Checkpoint{T}(copy(cp.x), copy(cp.s), copy(cp.m), capture_stores(cp.table), copy(cp.prior),
                  cp.t, cp.frame, cp.boundary, cp.t₀, cp.deployment, cp.layout)

# The fingerprint check `restore!` and replay's entry pass share (§12.6, §12.7):
# the structural fingerprint compared field for field, then the two deployments
# as *values*, one `==` as D-254 asks, with `_walk_deployment!` (trace.jl) as
# its explanation. The clock is restored, never compared. `sim` is untyped
# because this file precedes sim.jl.
function _check_checkpoint!(diags::Vector{Diagnostic}, sim, cp::Checkpoint)
    target = _fingerprint(sim.model)
    recorded = cp.layout
    recorded.sizes == target.sizes ||
        push!(diags, CheckpointMismatch(what = :store, name = :sizes,
                                        expected = recorded.sizes, found = target.sizes))
    recorded.paths == target.paths ||
        push!(diags, CheckpointMismatch(what = :store, name = :paths,
                                        expected = recorded.paths, found = target.paths))
    recorded.root_faces == target.root_faces ||
        push!(diags, CheckpointMismatch(what = :root_input,
                                        expected = recorded.root_faces,
                                        found = target.root_faces))
    # the per-component store types, only where the path lists agree on what a
    # component *index* means — otherwise the comparison would be by position
    # between two different models, and the path mismatch above is the honest fact
    if recorded.paths == target.paths
        for (i, path) in enumerate(target.paths)
            # the `x` type fixes the block's width and what each position holds
            recorded.xtypes[i] === target.xtypes[i] ||
                push!(diags, CheckpointMismatch(what = :store, path = path, name = :x,
                                                expected = recorded.xtypes[i],
                                                found = target.xtypes[i]))
            recorded.stypes[i] === target.stypes[i] ||
                push!(diags, CheckpointMismatch(what = :store, path = path, name = :s,
                                                expected = recorded.stypes[i],
                                                found = target.stypes[i]))
            recorded.mtypes[i] === target.mtypes[i] ||
                push!(diags, CheckpointMismatch(what = :store, path = path, name = :m,
                                                expected = recorded.mtypes[i],
                                                found = target.mtypes[i]))
        end
        recorded.addrs == target.addrs || _check_addresses!(diags, recorded.addrs, target.addrs)
        recorded.events == target.events ||
            push!(diags, CheckpointMismatch(what = :store, name = :events,
                                            expected = recorded.events, found = target.events))
    end
    cp.deployment == sim.model.deployment ||
        _walk_deployment!(diags, cp.deployment, sim.model.deployment)
    nothing
end

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
