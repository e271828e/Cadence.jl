# The checkpoint (§12.6, D-274): the executor's state at a frame top as one
# value, taken by `checkpoint(sim)` and by `init!` for the trace header, and put
# back by `restore!` and `replay!`. This file holds the value, the one read, its
# inverse and the fingerprint check the two restoring doors share; the doors
# themselves live in sim.jl, beside the loop. `sim` is untyped throughout for
# include order alone, this file preceding sim.jl.

"""
The structural fingerprint (§11.5, §12.7): the layout's cell sizes, the root
input-face list, the flat's component paths, each component store's value
type, each component's block in the flat buffer, and every address of the
table, `(path, name) => (type, offsets)` sorted by key. A checkpoint carries it,
and a restore compares it against the target's: the restore copies `x` and the
table by position, and the blocks and the addresses are what make the
positions mean the same thing.
"""
struct Fingerprint
    sizes::Vector{Pair{DataType,Int}}
    root_faces::Vector{Symbol}
    paths::Vector{String}
    stypes::Vector{Any}
    mtypes::Vector{Any}
    xblocks::Vector{UnitRange{Int}}
    addrs::Vector{Pair{Tuple{String,Symbol},Tuple{Any,Tuple}}}
end

"""
The executor's state at a frame top (§12.6, D-274): the flat buffer, the `s`
and `m` stores (`nothing` where a component owns none), the whole signal table
with every cell buffer copied, the guard priors, the clock in full and the
fingerprint. The priors are the one event register that crosses a boundary:
`last` equals them at rest. What every frame rewrites before reading it, the
derivative buffer, the arrival pair and the localization samples, stays out.

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
    t::T                             # the clock, in full
    step::Int
    boundary::Int
    t₀::Float64
    deployment::Deployment           # compared as a value at restore (§12.7)
    layout::Fingerprint              # compared against the `Build`
end

# The fingerprint off the simulation, one function for its two sides: the take
# writes it into the checkpoint and the check compares against it, since two
# spellings of one fingerprint would be a silent way for a restore to pass.
function _fingerprint(sim)
    exec = sim.exec
    layout = exec.act.layout
    Fingerprint(copy(layout.sizes),
                Symbol[f for (f, _) in layout.root_inputs],
                String[entry.path for entry in sim.deployment.build.structure.components],
                Any[st === nothing ? nothing : typeof(st[]) for st in exec.sstores],
                Any[st === nothing ? nothing : typeof(st[]) for st in exec.mstores],
                copy(layout.xblocks),
                sort!(Pair{Tuple{String,Symbol},Tuple{Any,Tuple}}[
                          key => (_port_type(addr), addr.offsets) for (key, addr) in layout.addr];
                      by = first))
end

# The one read, behind `checkpoint(sim)` and the trace header `init!` takes.
# The stores are copied by value, being isbits (D-231).
function _take_checkpoint(sim)
    exec = sim.exec
    clock = exec.clock
    T = eltype(exec.xbuf)      # the deployment's scalar, off the buffer that carries it
    s = Any[st === nothing ? nothing : st[] for st in exec.sstores]
    m = Any[st === nothing ? nothing : st[] for st in exec.mstores]
    checkpoint_stepper(exec.stepper)   # empty for a one-step method (stepper.jl)
    Checkpoint{T}(copy(exec.xbuf), s, m, capture_stores(exec.store), copy(exec.events.prior),
                  clock.t, clock.step, clock.boundary, clock.t₀, sim.deployment,
                  _fingerprint(sim))
end

# The inverse: every field copied back into the executor, the clock written as
# the checkpoint has it. Nothing is published here and nothing runs, so a
# caller that publishes owns the ordinal.
function _restore_state!(exec::Executor{T}, cp::Checkpoint{T}) where {T}
    copyto!(exec.xbuf, cp.x)
    _restore_stores!(exec, cp)
    foreach((cell_store, saved) -> copyto!(cell_store.buffer, saved.buffer),
            values(exec.store.stores), values(cp.table.stores))
    copyto!(exec.events.prior, cp.prior)
    copyto!(exec.events.last, cp.prior)
    clock = exec.clock
    clock.t, clock.step, clock.boundary, clock.t₀ = cp.t, cp.step, cp.boundary, cp.t₀
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
                  cp.t, cp.step, cp.boundary, cp.t₀, cp.deployment, cp.layout)

# The fingerprint check `restore!` and replay's entry pass share (§12.6, §12.7):
# the structural fingerprint compared field for field, then the two deployments
# as *values*, one `==` as D-254 asks, with `_walk_deployment!` (trace.jl) as
# its explanation. The clock is restored, never compared.
function _check_checkpoint!(diags::Vector{Diagnostic}, sim, cp::Checkpoint)
    target = _fingerprint(sim)
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
            recorded.stypes[i] === target.stypes[i] ||
                push!(diags, CheckpointMismatch(what = :store, path = path, name = :s,
                                                expected = recorded.stypes[i],
                                                found = target.stypes[i]))
            recorded.mtypes[i] === target.mtypes[i] ||
                push!(diags, CheckpointMismatch(what = :store, path = path, name = :m,
                                                expected = recorded.mtypes[i],
                                                found = target.mtypes[i]))
            # by width: the blocks are consecutive, so one component's width
            # moves every later block, and only the first is at fault
            length(recorded.xblocks[i]) == length(target.xblocks[i]) ||
                push!(diags, CheckpointMismatch(what = :store, path = path, name = :x,
                                                expected = recorded.xblocks[i],
                                                found = target.xblocks[i]))
        end
        recorded.addrs == target.addrs || _check_addresses!(diags, recorded.addrs, target.addrs)
    end
    cp.deployment == sim.deployment ||
        _walk_deployment!(diags, cp.deployment, sim.deployment)
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
