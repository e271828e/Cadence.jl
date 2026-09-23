# The build pipeline (§9.2, §9.3, §5.5). Plain printable data in, a compiled
# executor out. Three jobs, in order, because each needs the previous one's
# answer:
#
#   1. probe stage 1 — needs no wiring at all (an `output_state` bundle carries
#      no `u`), which is what makes it the fixed point the rest of the build
#      stands on;
#   2. derive the feedthrough graph and schedule stage 2 topologically, since a
#      stage-1 port carries no dependence and therefore breaks would-be loops;
#   3. probe stage 2 in that order (real upstream values available by
#      construction) and the update law last, against the now-complete table.
#
# Its input is the flattened tree (`src/assembly.jl`): primitives by absolute
# path, one resolved producer per input. Assemblies are virtual from here on.

# --- the user-code frame (§13.2, D-248) ---------------------------------------
# Every user-authored method the build invokes is reached through one of the two
# accessors below, and every per-component body that reads declarations without
# a path in hand runs under `at_component`, which fills the path in.

# What passes through a frame unwrapped: none of these is user code failing.
_passes_frame(e) = e isa DiagnosticError || e isa InternalInvariant || e isa InterruptException

"""
The framing accessor for a declaration (§13.2, D-248): `fn(comp, args...)`, a
throw out of it framed as `UserCodeFraming` naming the method. The path is
not known here; `at_component` fills it.

A few reads stay bare because the build already invoked the same declaration
through this accessor and it returned: `conditions.jl`'s `_resolve_entries`,
`_store_bases` and `_declared_workspace`, `establish_defaults!` below,
`children`, `resolve_authored` and `authored_chain` reaching `assembly.jl`'s
`_children`, and `tracer.jl`'s sampled `_trace_direct`.
"""
function invoke_declaration(fn, comp, args...)
    try
        fn(comp, args...)
    catch err
        _passes_frame(err) && rethrow()
        throw(DiagnosticError(UserCodeFraming(fn = String(nameof(fn)), cause = err)))
    end
end

"""
The framing accessor for a probed bundle-taking function (§13.2, D-248):
`fn(comp, bundle)`. A `FieldError` matched against the bundle's own type is the
bundle-law diagnostic, classified (§5.2); any other throw is the plain frame,
carrying the bundle's names and the synthesized inputs as a spelling.
"""
function invoke_probed(fn, family::Symbol, path::String, comp, tier::Tier, bundle::NamedTuple)
    try
        fn(comp, bundle)
    catch err
        _passes_frame(err) && rethrow()
        if err isa FieldError && err.type === typeof(bundle)
            throw(DiagnosticError(BundleFieldError(path = path, family = String(family),
                tier = tier === CONTINUOUS ? :continuous : :discrete, field = err.field,
                legal = collect(keys(bundle)),
                reason = classify_bundle_field(family, tier, err.field))))
        end
        throw(DiagnosticError(UserCodeFraming(path = path, fn = String(family),
            bundle = collect(keys(bundle)), inputs = _inputs_spelling(bundle), cause = err)))
    end
end

# One line, whatever the author's `show` does. A `show` that throws must not
# replace the throw the frame is already carrying.
function _inputs_spelling(bundle::NamedTuple)
    haskey(bundle, :u) || return ""
    try replace(sprint(show, bundle.u; context = :compact => true), '\n' => ' ')
    catch err; err isa InterruptException ? rethrow() : "<unshowable>" end
end

"""
The component frame (§13.2, D-248): runs `thunk()` for the component at `path`
and fills the path into a `UserCodeFraming` an accessor raised without one.
Every other throw passes.
"""
function at_component(thunk, path::String)
    try
        thunk()
    catch err
        if err isa DiagnosticError{UserCodeFraming} && isempty(err.carried.path)
            framing = err.carried
            throw(DiagnosticError(UserCodeFraming(path = path, fn = framing.fn, bundle = framing.bundle,
                                                  inputs = framing.inputs, cause = framing.cause)))
        end
        rethrow()
    end
end

# --- 1. declarations at the activation scalar ---------------------------------

struct Decls
    x::NamedTuple          # continuous state, walked to the activation scalar
    s::NamedTuple          # discrete state, pinned wholesale (D-195)
    ins::NamedTuple        # face => type, evaluated at the activation scalar
    outs::NamedTuple       # port => type, evaluated at the activation scalar
end

"""The tier's own state register: exactly one of the two is ever populated."""
state_decls(decl::Decls, tier::Tier) = tier === CONTINUOUS ? decl.x : decl.s

# The two declaration kinds split by D-166's criterion: `init_x` is by value
# and its types are *walked*; `input_types`/`output_types` are functions of the
# activation scalar on the continuous tier and are *evaluated*. There is no
# output-side leaf walk — the cell types at an activation are literally what the
# declaration returns at that `T`. On the discrete tier the plain forms declare
# the pinned world, so `init_s` does not walk and nothing is evaluated at `T`.
function declarations(comp, tier::Tier, ::Type{T}) where {T}
    tier === CONTINUOUS ?
        Decls(retype_value(T, invoke_declaration(init_x, comp)), NamedTuple(),
              invoke_declaration(input_types, comp, T), invoke_declaration(output_types, comp, T)) :
        Decls(NamedTuple(), invoke_declaration(init_s, comp),
              declared_at(input_types, comp, tier), declared_at(output_types, comp, tier))
end

# --- tier classification (§8.2) -----------------------------------------------
# Tier is read off the declaration shape, never announced. For a **stateful**
# leaf `init_x`/`state_derivative` carry it continuous against
# `init_s`/`state_update` discrete, the two disjoint (D-195), with the update
# law the decider — the output stages are one pair of names shared by both
# tiers (D-220) and no longer vote. A **stateless** leaf has no update law, so
# its contract arities decide, `output_types` being mandatory and therefore the
# decider: the two-argument forms declare cells at the activation scalar, the
# plain forms the pinned discrete world (D-166/D-167). Every other tier-implying
# declaration must then agree, and disagreement names the offending one —
# including the wrong-tier cases the split state letters make visible, an
# `init_x` on a leaf whose update law is `state_update` and the converse.
#
# The classifier sees primitives only: a component that declares nothing at all
# has no *class* to read, which §8.5 settles before this runs.

# §7.1, §8.2, D-094: every `init_x` field is a `Float64` or an `SArray` of them,
# and the declaration is flat. The arm names where the value belongs instead.
function check_state_leaves(path::String, comp, diags::Vector{Diagnostic})
    for (name, value) in pairs(invoke_declaration(init_x, comp))
        leaf_eltype = value isa SArray ? eltype(value) : typeof(value)
        leaf_eltype === Float64 && continue
        reason = value isa NamedTuple ? :nested :
                 leaf_eltype <: Union{Integer,Enum} ? :mode_value :
                 leaf_eltype <: Real ? :eltype : :wrapper
        push!(diags, IllegalStateLeaf(path = path, name = name, declared = typeof(value),
                                      reason = reason))
    end
end

# §8.2, D-247: every by-value store is a `NamedTuple`, and the classifier and
# the two field checks below read it as one. Returns whether this primitive
# can be read further; the fallbacks return `NamedTuple()` and pass.
function check_store_form(path::String, comp, diags::Vector{Diagnostic})
    readable = true
    for (name, fn) in ((:init_x, init_x), (:init_s, init_s), (:init_m, init_m))
        contents = invoke_declaration(fn, comp)
        contents isa NamedTuple && continue
        push!(diags, StoreNotNamedTuple(path = path, store = name, declared = typeof(contents)))
        readable = false
    end
    readable
end

# §7.3, D-231: every store field is isbits or a `Symbol`, checked on both stores.
function check_stores(path::String, comp, diags::Vector{Diagnostic})
    for (store, contents) in ((:init_s, invoke_declaration(init_s, comp)),
                        (:init_m, invoke_declaration(init_m, comp)))
        for (name, value) in pairs(contents)
            isbits(value) || value isa Symbol ||
                push!(diags, IllegalStoreField(path = path, store = store,
                                               name = name, declared = typeof(value)))
        end
    end
end

# The tier-announcing family (§8.2, §8.5): the names the vote loop below reads,
# in vote order — the list-in-hand a `TierUnreadable` carries.
const TIER_FAMILY = (:state_derivative, :state_update, :init_x, :init_s, :init_m,
                     :state_events, :output_types, :input_types, :init_workspace)

# §8.5's two contract signature forms, as the tier mandates them.
_form(tier::Tier) = tier === CONTINUOUS ? :two_argument : :plain

"""
The tier the primitive at `path` announces, or `nothing` with what disagrees
recorded in `diags` (§13.1).
"""
function classify_tier(path::String, comp, diags::Vector{Diagnostic})
    votes = Tuple{Symbol,Tier}[]
    has_stage(state_derivative, comp) && push!(votes, (:state_derivative, CONTINUOUS))
    has_stage(state_update, comp) && push!(votes, (:state_update, DISCRETE))
    !isempty(invoke_declaration(init_x, comp)) && push!(votes, (:init_x, CONTINUOUS))
    !isempty(invoke_declaration(init_s, comp)) && push!(votes, (:init_s, DISCRETE))
    !isempty(invoke_declaration(init_m, comp)) && push!(votes, (:init_m, CONTINUOUS))
    !isempty(invoke_declaration(state_events, comp)) && push!(votes, (:state_events, CONTINUOUS))
    for (name, fn) in ((:output_types, output_types), (:input_types, input_types),
                       (:init_workspace, init_workspace))
        _declares(fn, comp, Type{Float64}) && push!(votes, (name, CONTINUOUS))
        _declares(fn, comp) && push!(votes, (name, DISCRETE))
    end

    # The decider, by §8.2's two cases.
    state_store = !isempty(invoke_declaration(init_x, comp)) ? :init_x :
            !isempty(invoke_declaration(init_s, comp)) ? :init_s : nothing
    if state_store !== nothing
        decider = findfirst(v -> first(v) === :state_derivative || first(v) === :state_update, votes)
        if decider === nothing
            push!(diags, StoreWithoutUpdate(path = path, store = state_store))
            return nothing
        end
    else
        decider = findfirst(v -> first(v) === :output_types, votes)
        if decider === nothing
            push!(diags, TierUnreadable(path = path, type = _typename(comp),
                                       family = collect(TIER_FAMILY),
                                       declarations = Symbol[first(v) for v in votes]))
            return nothing
        end
    end

    # The vote loop collects (§13.1): a leaf written half in each tier's spelling
    # names every declaration that disagrees, not the first one found. The tier
    # is announced only if none does. A contract arity against the announced tier
    # is the contract's own kind, on a stateful leaf and a stateless one alike
    # (§8.5, D-249); every other name is `DeclarationOnWrongTier`'s.
    tier = last(votes[decider])
    recorded = length(diags)
    for (name, vote_tier) in votes
        vote_tier === tier && continue
        if name === :input_types || name === :output_types
            push!(diags, TierSignatureMismatch(path = path, declaration = name,
                                               tier = Symbol(tier_word(tier)), reason = :arity,
                                               found = _form(vote_tier), mandated = _form(tier)))
        else
            push!(diags, DeclarationOnWrongTier(path = path, declaration = name,
                                               reason = :tier_form,
                                               found = Symbol(tier_word(vote_tier)),
                                               announced = Symbol(tier_word(tier))))
        end
    end
    length(diags) == recorded ? tier : nothing
end

# --- 2. probing ---------------------------------------------------------------

"""
Probe the stage-1 function — `output_state`, on either tier (D-220) — for
every component in this activation's executable set: no wiring
is needed, so this runs first and tells the rest of the build which ports are
stage-1 — the ones that carry no dependence on inputs and therefore break loops
(§5.3). A frozen component's stages are outside the set (§9.4), so it probes
nothing here; `probe_stage2` carries its complete product across from the
nominal activation.

The `Δt` the discrete bundles carry is a fabricated, probe-scoped placeholder
(§9.3): `Δt` in seconds does not exist until the `Deployment` binds `Δt_base`, and
the probe checks types, not physics.
"""
function probe_stage1(structure::Structure, decls::Vector{Decls},
                      workspaces::Vector, mstores::Vector, ::Type{T}) where {T}
    map(enumerate(structure.components)) do (ci, entry)
        path, comp, decl = entry.path, entry.instance, decls[ci]
        at_component(path) do
            _frozen(entry.tier, T) && return NamedTuple()
            has_stage(output_state, comp) || return NamedTuple()
            stage = String(nameof(output_state))
            bundle_fields = bundle_names(output_state, comp, entry.tier, ())
            y = invoke_probed(output_state, :output_state, path, comp, entry.tier,
                              _bundle_values(bundle_fields, decl, NamedTuple(), NamedTuple(), T;
                                             ws = workspaces[ci], m = mstores[ci], Δt = 1.0))
            y isa NamedTuple ||
                throw(DiagnosticError(ConformanceFailure(path = path, what = stage,
                                                    reason = :return_type, shape = :ports,
                                                    observed = typeof(y))))
            isempty(y) && throw(DiagnosticError(DeadStage(path = path, stage = stage)))
            _check_ports(path, stage, y, decl.outs, T)
            _embed_ports(y, decl.outs, T)
        end
    end
end

function _bundle_values(bundle_fields, decl::Decls, u, y1, ::Type{T}; y = NamedTuple(), ws = nothing,
                        m = nothing, Δt = 0.0) where {T}
    field_values = map(bundle_fields) do field
        field === :x   ? decl.x :
        field === :s   ? decl.s :
        field === :m   ? m[] :
        field === :u   ? u :
        field === :y_x ? y1 :
        field === :y_s ? y1 :
        field === :y   ? y :
        field === :ws  ? ws :
        field === :t   ? zero(T) :
        field === :Δt  ? Δt : throw(InternalInvariant("no probe source for $field"))
    end
    NamedTuple{bundle_fields}(field_values)
end

# The per-port loop collects (§13.1): a stage returning three wrong types names
# all three.
function _check_ports(path, stage, y::NamedTuple, outs::NamedTuple, ::Type{T}) where {T}
    diags = Diagnostic[]
    for (name, value) in pairs(y)
        if !haskey(outs, name)
            push!(diags, UndeclaredReturnField(path = path, stage = stage, name = name,
                                              candidates = collect(keys(outs))))
            continue                               # nothing declared to compare against
        end
        _accepts(outs[name], typeof(value), T) ||
            push!(diags, ConformanceFailure(path = path, what = stage, reason = :field_type,
                                           shape = :ports, field = name,
                                           observed = typeof(value), declared = outs[name],
                                           activation = T))
    end
    isempty(diags) || throw(DiagnosticError(diags))
    nothing
end

"""
What the cell will hold: an accepted `Float64` arrival stored into the
activation buffer *is* a zero-partial, so the probe hands downstream the
embedded value rather than the literal the stage returned. Without this the
probe's product types diverge from the ones the runtime gather produces. The
lift is leaf by leaf, exactly where `_accepts` admitted it: a `Float64` leaf
at a position `P` declares `T`; every other leaf, a pinned `Float64`, a `Bool`,
an enum, passes through.
"""
_embed(::Type{P}, v, ::Type{T}) where {P,T} =
    typeof(v) === P ? v :
    reconstruct(P, Any[lt === T && l isa Float64 ? T(l) : l
                       for (lt, l) in zip(leaf_types(P), _leaf_values(v))], 0)

_embed_ports(y::NamedTuple, outs::NamedTuple, ::Type{T}) where {T} =
    NamedTuple{keys(y)}(map(n -> _embed(outs[n], y[n], T), keys(y)))

# --- 2b. the store homes (§7.1, §8.3, D-252) ----------------------------------
# All that is left of the port classification's store side: `DeclaredNotProduced`
# names the declared port no stage returns, and the store fields are the context
# that points at the remedy.

"""
The tier's state homes, in merge order: `x` then `m` on the continuous tier, `s`
on the discrete (§5.3, §7.1). `m` arrives as the probe-scoped `Ref`, or `nothing`
where the component declares no modes.
"""
_homes(decl::Decls, tier::Tier, m) =
    tier === CONTINUOUS ? (x = decl.x, m = m === nothing ? NamedTuple() : m[]) : (s = decl.s,)

"""The tier's store field names, for `DeclaredNotProduced`'s list-in-hand (§8.3)."""
_state_fields(homes::NamedTuple) = Symbol[keys(merge(values(homes)...))...]

# --- 3. the nominal evaluation's products -------------------------------------

"""
The `Outputs` (§9.1, D-253, D-261): every component's declared ports split into
the stage-1 names and the stage-2 remainder, and the execution order Kahn takes
over the feedthrough graph. The artifact carries the two name lists and the
order; the graph stays the builder's scratch. Edges run producer → consumer for
every consumed **stage-2** port; consuming a stage-1 port adds no edge, which is
the whole structural payoff of the split — a stage-1 port takes no input and so
carries no input dependence (§5.3). A stall is not reported as its residue: the
residue is *decomposed* into one `AlgebraicCycle` per strongly connected cluster
below (§5.6, D-012), which is why `edges` keeps each dependence's port and face,
which Kahn itself discards.
"""
function _outputs(structure::Structure, decls::Vector{Decls},
                  stage1::Vector, mstores::Vector)
    ncomponents = length(structure.components)
    ports = [Symbol[keys(decls[ci].outs)...] for ci in 1:ncomponents]
    stage1_names = [Symbol[keys(stage1[ci])...] for ci in 1:ncomponents]
    stage2_names = [filter(∉(stage1_names[ci]), ports[ci]) for ci in 1:ncomponents]
    dependencies = [Int[] for _ in 1:ncomponents]
    edges = [Tuple{Int,Symbol,Symbol}[] for _ in 1:ncomponents]    # per consumer: (producer, port, face)
    for (ci, entry) in enumerate(structure.components)
        has_stage(output_direct, entry.instance) || continue
        for (face, (producer_path, producer_port)) in entry.conns
            isempty(producer_path) && continue           # a root input: no producer to wait for
            producer_ci = index_of(structure, producer_path)
            haskey(stage1[producer_ci], producer_port) && continue   # stage-1 position: no dependence
            push!(dependencies[ci], producer_ci)
            push!(edges[ci], (producer_ci, producer_port, face))
        end
    end

    order = Int[]
    ready = [ci for ci in 1:ncomponents if isempty(dependencies[ci])]
    remaining = Set(1:ncomponents)
    while !isempty(ready)
        ci = popfirst!(ready)
        push!(order, ci)
        delete!(remaining, ci)
        for cj in collect(remaining)
            if ci in dependencies[cj]
                dependencies[cj] = filter(!=(ci), dependencies[cj])
                isempty(dependencies[cj]) && push!(ready, cj)
            end
        end
    end

    isempty(remaining) ||
        throw(DiagnosticError(_cycle_diagnostics(structure, edges, remaining, order, decls,
                                                 stage1, mstores)))
    Outputs([ComponentOutputs(entry.path, stage1_names[ci], stage2_names[ci])
             for (ci, entry) in enumerate(structure.components)], order)
end

"""
§5.6, D-012: the stalled subgraph decomposed. Every nontrivial strongly connected
component of the subgraph induced on the unplaced components is one cluster and
one diagnostic; the innocent downstream cone the residue also holds lies in no
such component and is reported nowhere. `members` is the depth-first preorder
along the cluster's own wires from its lowest flatten index, neighbours taken in
flatten order, and `wires` follows the members. Each cluster is then handed to
the tracer for §5.6's classification, `placed` being the acyclic prefix its
out-of-cycle faces read from.
"""
function _cycle_diagnostics(structure::Structure, edges::Vector{Vector{Tuple{Int,Symbol,Symbol}}},
                            remaining::Set{Int}, placed::Vector{Int},
                            decls::Vector{Decls}, stage1::Vector, mstores::Vector)
    nodes = sort!(collect(remaining))
    successors = [Int[] for _ in structure.components]  # producer → consumer, inside the residue
    for ci in nodes, (producer_ci, _, _) in edges[ci]
        producer_ci in remaining && push!(successors[producer_ci], ci)
    end
    for ci in nodes
        successors[ci] = sort!(unique(successors[ci]))
    end

    clusters = Tuple{Int,AlgebraicCycle}[]
    for scc in _tarjan(nodes, successors)
        length(scc) > 1 || first(scc) in successors[first(scc)] || continue
        member_set = Set(scc)
        order = _cluster_walk(scc, successors, member_set)
        position = Dict(ci => i for (i, ci) in enumerate(order))
        wires = Tuple{Int,Int,String,String}[]
        for ci in order, (producer_ci, producer_port, face) in edges[ci]
            producer_ci in member_set &&
                push!(wires,
                     (position[producer_ci], position[ci], string(producer_port), string(face)))
        end
        sort!(wires)
        path_at(ci) = structure.components[ci].path
        cycle = AlgebraicCycle(members = String[path_at(ci) for ci in order],
                           wires = ["$(path_at(order[producer_position]))/$port_name" =>
                                    "$(path_at(order[consumer_position]))/$face_name"
                                    for (producer_position, consumer_position, port_name,
                                         face_name) in wires])
        push!(clusters, (minimum(scc), _classify(cycle, order, edges, placed, structure, decls,
                                                 stage1, mstores)))
    end
    sort!(clusters; by = first)
    Diagnostic[cycle for (_, cycle) in clusters]
end

"Tarjan's algorithm over `nodes`, recursive: the strongly connected components."
function _tarjan(nodes::Vector{Int}, successors::Vector{Vector{Int}})
    index, low, onstack, stack, sccs = Dict{Int,Int}(), Dict{Int,Int}(), Set{Int}(), Int[], Vector{Int}[]
    function strong!(node)
        index[node] = low[node] = length(index) + 1
        push!(stack, node)
        push!(onstack, node)
        for successor in successors[node]
            if !haskey(index, successor)
                strong!(successor)
                low[node] = min(low[node], low[successor])
            elseif successor in onstack
                low[node] = min(low[node], index[successor])
            end
        end
        if low[node] == index[node]
            scc = Int[]
            while true
                member = pop!(stack)
                delete!(onstack, member)
                push!(scc, member)
                member == node && break
            end
            push!(sccs, scc)
        end
    end
    for node in nodes
        haskey(index, node) || strong!(node)
    end
    sccs
end

"The cluster's members in walk order: a cluster is strongly connected, so one walk reaches all."
function _cluster_walk(scc::Vector{Int}, successors::Vector{Vector{Int}}, member_set::Set{Int})
    order, seen = Int[], Set{Int}()
    function visit!(node)
        push!(seen, node)
        push!(order, node)
        for successor in successors[node]
            successor in member_set && !(successor in seen) && visit!(successor)
        end
    end
    visit!(minimum(scc))
    order
end

# --- 4. cell layout -----------------------------------------------------------
# Every declared port gets a cell; so does every root input face, the one
# terminal legitimately fed by no component, its initial value synthesized by
# `probe_value` (§6.1, §9.3, §11.3). A root input's *type* is the structure
# step's, fixed once by the wire pass and carried on the `Structure`; the layout
# picks its cells per activation from that type, by the meet below (D-168, D-236).
#
# An assembly's faces get no cells of their own. A face *is* its ultimate
# internal endpoint (§8.6), so it is entered as an alias onto that endpoint's
# address — which is what makes a face's type and tier derived rather than
# declared.

struct Layout
    addr::Dict{Tuple{String,Symbol},Any}     # (path, port|face) => CellAddr
    root_inputs::Vector{Tuple{Symbol,Any}}   # root inputs, with their probe values
    sizes::Vector{Pair{DataType,Int}}        # leaf eltype => buffer length, name-sorted
    xblocks::Vector{UnitRange{Int}}          # per component: its range in the flat `x` buffer, empty where it owns none
end

function cell_layout(structure::Structure, decls::Vector{Decls}, ::Type{T}) where {T}
    addr = Dict{Tuple{String,Symbol},Any}()
    root_inputs = Tuple{Symbol,Any}[]
    offsets = Dict{DataType,Int}()
    # Placement collects (§13.1): every leafless declaration in the model is
    # named, every mutable one and every handle surfacing as a root input
    # (D-237), and the barrier throws before the alias pass, which would
    # otherwise look up an address placement never made.
    diags = Diagnostic[]
    function place!(path, site::Symbol, name, ::Type{P}) where {P}
        mutable_site = mutable_position(P)
        if mutable_site !== nothing
            push!(diags, IllegalPortType(path = path, site = site, name = name, declared = P,
                                         reason = :mutable, position = first(mutable_site)))
            return false
        end
        leaves = leaf_types(P)
        if isempty(leaves)
            push!(diags, IllegalPortType(path = path, site = site, name = name, declared = P))
            return false
        end
        eltypes = leaf_eltypes(P)
        addr[(path, name)] = CellAddr{P,length(eltypes)}(Tuple(get(offsets, L, 0) for L in eltypes))
        for L in eltypes
            offsets[L] = get(offsets, L, 0) + count(==(L), leaves)
        end
        true
    end
    for (entry, decl) in zip(structure.components, decls)
        for (port_name, P) in pairs(decl.outs)
            place!(entry.path, :port, port_name, P)
        end
    end
    for (i, face) in enumerate(structure.root_inputs)
        cell_type = _root_input_cell(structure, decls, i, face, T)
        # An opaque leaf at a root input, a handle or a `Symbol`, has no
        # synthesis and no producer (D-237, D-243), so it is refused here, ahead
        # of `probe_value`. A real or an enum leaf has a synthesis (§9.3). A
        # mutable `P` is left to `place!`'s own arm on the next line, whatever
        # its leaves.
        if mutable_position(cell_type) === nothing &&
           any(L -> !(L <: Real || L <: Enum), leaf_types(cell_type))
            push!(diags, IllegalPortType(path = "", site = :root_input, name = face,
                                         declared = cell_type, reason = :handle_at_root))
            continue
        end
        place!("", :root_input, face, cell_type) || continue
        # §9.3, D-051: the synthesis chain ends at `P()`, and a type reaching
        # it with no zero-argument constructor has no probe value. Collected,
        # beside the placement refusals above. A `MethodError` out of an
        # author's override is the override's own and propagates.
        value = try
            probe_value(cell_type)
        catch err
            (err isa MethodError && _framework_synthesis(cell_type)) || rethrow()
            push!(diags, MissingProbeValue(face = face, declared = cell_type))
            continue
        end
        push!(root_inputs, (face, value))
    end
    isempty(diags) || throw(DiagnosticError(diags))
    for (alias, target) in structure.out_faces
        addr[alias] = addr[target]
    end
    sizes = sort!([L => n for (L, n) in offsets]; by = p -> string(first(p)))
    # The flat buffer's layout is the declaration walk (§7.1): one range per
    # component, the one home every `x` offset is read from (§13.4, D-261).
    xblocks, n_x = UnitRange{Int}[], 0
    for (decl, entry) in zip(decls, structure.components)
        width = entry.tier === CONTINUOUS ? nleaves(typeof(decl.x)) : 0
        push!(xblocks, (n_x+1):(n_x+width))
        n_x += width
    end
    Layout(addr, root_inputs, sizes, xblocks)
end

# A root input's cells at an activation: D-168's meet, at the level of the whole
# root input, with D-236's two candidates — the root-input type with every leaf
# following `T` when every consumer's entry at `T` admits it, the root-input type
# itself otherwise. The structure step fixed the type and checked the entries, so nothing
# is recorded here; at nominal the two candidates coincide.
function _root_input_cell(structure::Structure, decls::Vector{Decls}, root_index::Int, face::Symbol,
                          ::Type{T}) where {T}
    P_F = structure.root_types[root_index]
    walked_type = retype(T, P_F)
    consumer_types = (decls[ci].ins[consumer_face] for (ci, entry) in enumerate(structure.components)
               for (consumer_face, producer) in entry.conns if producer === ("", face))
    all(input_type -> _accepts_wire(input_type, walked_type, T), consumer_types) ? walked_type : P_F
end

"""Address of the cell feeding `face`: its resolved producer's port, or a root input."""
input_addr(layout::Layout, conns::Vector{Pair{Symbol,Tuple{String,Symbol}}}, face::Symbol) =
    layout.addr[last(conns[findfirst(p -> first(p) === face, conns)])]

# --- 5. the Build artifact and its activations (§9.2, §9.4) ---------------------

"""
One activation: the typed products at a concrete scalar `T` (§9.1) —
declarations evaluated at `T`, the probe chain run over exactly the function
set this activation can execute (§9.4), cells laid out. Immutable once
constructed; the probe products are what a cell holds until first written
(§10.5).
"""
struct Activation{T}
    decls::Vector{Decls}
    products::Vector{NamedTuple}   # complete probe products, per component
    layout::Layout
end

"""
One component's outputs (§9.1): the port names each stage produces, `stage1`
in the return's order, `stage2` the declared remainder in `output_types`
order. Their concatenation is the products' order, stage 1 then stage 2.
"""
struct ComponentOutputs
    path::String
    stage1::Vector{Symbol}
    stage2::Vector{Symbol}
end

"The output port names in the products' order (§8.3): stage 1, then stage 2."
_ports(entry::ComponentOutputs) = vcat(entry.stage1, entry.stage2)

"""
The nominal evaluation's product (§9.1, D-253, D-261): per component, in walk
order, the output ports each stage produces, and the execution order over the
component indices. Structural and `T`-independent, names only, which is why a
reader wanting a name list takes it from here rather than from a scalar-typed
activation. The feedthrough graph the order was computed over is not carried;
where it is shown it is derived from the structure's connections and the
producers' `stage2`.
"""
struct Outputs
    components::Vector{ComponentOutputs}   # in walk order; the index is `ci`
    order::Vector{Int}                     # the execution order over `ci`
end

"""
One component's events (§9.1, §10.4): the detection policy each guard's return
form fixes, by event name in declaration order, and the event bundle's field
names, `()` where the component declares no events.
"""
struct ComponentEvents
    path::String
    policies::NamedTuple   # event name => :boundary | :localized
    bundle::Tuple
end

"""
The nominal evaluation's other product (§9.1, D-253), built last, after the
stage probes: one row per component in walk order, the index being `ci`. It is
structural and `T`-independent like the `Outputs`, and separate from it because
a different input fixes it, the event declarations, read after the probes, so
a consumer of the execution order never carries the event tables.
"""
struct Events
    components::Vector{ComponentEvents}
end

"""
The deployment-free product of the build pipeline (§9.2): structure, outputs,
events, the activations and `warnings`, the first three being what §9.1's three
steps produce. Everything here is settled before `Δt_base` exists, and the first
three are `T`-independent by construction (§9.1). The activations are one
dictionary keyed by scalar type, the nominal `Float64` entry included like any
other; the rest are derived at first request (§9.4). The schedule the structure
carries is anchor-relative — each component entry's `timing` against
`structure.anchors` — because final divisors for anchored entries do not exist
until `Δt_base` binds.
The `Build` is immutable and backs any number of deployments and `Simulation`s,
each materializing its own stores and buffers, so nothing writable lives here;
the one mutable thing is the activation dictionary, whose insertion the lock
makes torn-state-free (§9.4).
"""
struct Build
    structure::Structure
    outputs::Outputs
    events::Events
    activations::Dict{DataType,Any}   # keyed by scalar type, the nominal `Float64` entry included
    lock::ReentrantLock               # guards `activations` (§9.4's torn-state guarantee)
    warnings::Vector{Diagnostic}      # the warnings the build raised (§9.1, D-250)
end

"The probe scalar's own tag (§9.4): what keeps a probe activation distinguishable from trim's (`TrimTag`) and from a user's own."
struct ProbeTag end

"""
The framework's public canonical probe scalar (§9.4, D-166): the one concrete
`Dual` a CI activation list spells, `build(world; activations = (Float64,
ProbeDual))`. An activation is keyed by a concrete scalar, and the bare `Dual`
`UnionAll` can key none. The width is one because what CI pins is genericity,
not any particular Jacobian; §14.10 chunks at whatever widths it needs.
"""
const ProbeDual = ForwardDiff.Dual{ProbeTag,Float64,1}

"""
    build(root; activations = ()) → Build

The structure step, the nominal evaluation and the eager activations (§9.1). The
structure step flattens, classifies and type-checks the wires into the
`Structure`; the nominal evaluation probes at `Float64` and returns the
`Outputs`, the `Events` and the nominal activation, which is its own product and
never a separate pass (D-253, D-259). Nothing here needs `Δt_base`, `h` or
`N_base` — those are the `Deployment`'s. `activations` is §9.4's opt-in exhaustive
mode: each listed scalar's activation is materialized eagerly instead of at first
request.
"""
function build(root::AbstractComponent; activations::Tuple = ())
    # One binding around all three steps, and one list (§9.1, D-250): a helper
    # inside a declaration body appends to it without knowing the build, the
    # completed `Build` carries it, and a throw leaving the build takes it along.
    raised_warnings = Diagnostic[]
    built = try
        with(BUILD_WARNINGS => raised_warnings) do
            diags = Diagnostic[]
            draft = StructureDraft(root)
            flatten!(draft, root, diags)    # structure, tiers, claims, the obligation check
            _check_event_declarations(draft, diags)
            # The dependency rule (§13.1, D-229): the wire pass reads the wiring, which a
            # dirty walk never produced, so it runs on a clean walk alone.
            isempty(diags) || throw(DiagnosticError(diags))
            conns, in_faces = wire!(draft)  # the derivation, on a clean walk
            root_types = _check_wires(draft, conns, diags)
            # The structure step's barrier (§13.1, D-229): every pass that ran merges here, and
            # nothing derived from the wiring is computed before it. No cascade
            # suppression — a typo'd wire reports its unknown port *and* the input it
            # left unfed.
            isempty(diags) || throw(DiagnosticError(diags))
            structure = Structure(draft, conns, in_faces, root_types)   # the artifact, complete at construction (D-261)
            outputs, events, nominal = _nominal(structure)
            built = Build(structure, outputs, events, Dict{DataType,Any}(Float64 => nominal),
                          ReentrantLock(), raised_warnings)
            for scalar in activations
                activation(built, scalar)
            end
            built
        end
    catch err
        # The rewrap sits here, not at each barrier: a barrier throws the
        # collection its own passes produced and stays ignorant of the channel,
        # and only the entry point knows the whole build's warnings (D-250).
        (err isa DiagnosticError && !isempty(raised_warnings)) &&
            throw(DiagnosticError(err.carried, raised_warnings))
        rethrow()
    end
    # The completed build carries the record; the entry point logs each warning
    # once at return, through the standard backend (Appendix C's `logged`).
    for warning in raised_warnings
        @warn logline(warning)
    end
    built
end

# An event needs both halves (§8.2): a guard or handler with no method for the
# component type is caught by method lookup at declaration-reading time, rather
# than as a `MethodError` at the first firing — an event firing only in a corner
# of the envelope would otherwise hide the omission indefinitely.
function _check_event_declarations(draft::StructureDraft, diags::Vector{Diagnostic})
    # The pass runs before `wire!` derives the `Structure`, so it reads the draft's
    # own columns. It collects (§13.1): every malformed entry in the model is
    # named, not the first one the walk reaches, and the list merges into the step's.
    for (path, comp) in zip(draft.paths, draft.instances)
        at_component(path) do
            for (name, event) in pairs(invoke_declaration(state_events, comp))
                if !(event isa StateEvent)
                    push!(diags, EventHalfMissing(path = path, event = name,
                                                 reason = :not_an_event, found = _typename(event)))
                    continue                       # neither half exists to look up
                end
                for (half, fn) in ((:guard, event.guard), (:handler, event.handler))
                    hasmethod(fn, Tuple{typeof(comp),NamedTuple}) ||
                        push!(diags, EventHalfMissing(path = path, event = name, reason = half,
                                                     found = _typename(comp)))
                end
            end
        end
    end
    nothing
end

# --- The structure step's wire pass (§6.1, §9.1, D-236) -----------------------

"""
The marker scalar (§6.1, §9.1): the continuous contracts are evaluated at it to
tell a walking leaf from a pinned one — a leaf typed `Marker` walks with the
activation, anything else is pinned. It never enters arithmetic.
"""
struct Marker <: Real end
Base.show(io::IO, ::Type{Marker}) = print(io, "T")   # a declaration at the marker prints as written

# The bound a two-argument contract puts on its `T`, read off the method matched
# at `Float64` (§8.5): the type variable's upper bound, or the argument type
# itself when the second argument is not `Type{…}`. Throwing path only.
function _contract_bound(fn, comp)
    argument_type = Base.unwrap_unionall(which(fn, Tuple{typeof(comp),Type{Float64}}).sig).parameters[3]
    unwrapped = Base.unwrap_unionall(argument_type)
    (unwrapped isa DataType && unwrapped.name === Base.typename(Type)) || return argument_type
    parameter = unwrapped.parameters[1]
    parameter isa TypeVar ? parameter.ub : parameter
end

# The contract-bound check, the two type clauses on every resolved wire, and the
# root-input type with its two refusals. Pure declaration reading — the
# contracts are evaluated at `Float64` for the bound clause and at the marker for
# the walk clause; no stage runs. The pass collects (§13.1): every wire is
# checked, and the barrier throws once. Runs on the clean draft and the `conns`
# `wire!` derived, ahead of the `Structure`, and returns the root-input types
# the artifact takes at construction (D-236, D-261). The list holds `nothing`
# only on the two refusal arms below, each of which records a diagnostic, so
# the barrier throws before the `Structure` narrows it.
function _check_wires(draft::StructureDraft, conns::Vector{Vector{Pair{Symbol,Tuple{String,Symbol}}}},
                      diags::Vector{Diagnostic})
    # A continuous contract bounded narrower than `Real` (§8.5) has no method at
    # the marker, so its marker declaration is the `::Any` fallback's empty
    # `NamedTuple` — refuse the component and skip every wire and root entry that
    # touches it, rather than index that emptiness by face.
    refused = falses(length(draft.paths))
    for (ci, (comp, tier)) in enumerate(zip(draft.instances, draft.tiers))
        tier === CONTINUOUS || continue
        for fn in (input_types, output_types)
            (_declares(fn, comp, Type{Float64}) && !_declares(fn, comp, Type{Marker})) || continue
            push!(diags, TierSignatureMismatch(path = draft.paths[ci], declaration = nameof(fn),
                                               tier = :continuous, reason = :bound,
                                               found = _contract_bound(fn, comp), mandated = Real))
            refused[ci] = true
        end
    end
    contracts_at(fn, scalar) = [at_component(() -> declared_at(fn, draft.instances[ci],
                                                                draft.tiers[ci], scalar),
                              draft.paths[ci]) for ci in eachindex(draft.paths)]
    ins_F, outs_F = contracts_at(input_types, Float64), contracts_at(output_types, Float64)
    ins_M, outs_M = contracts_at(input_types, Marker), contracts_at(output_types, Marker)
    for (ci, consumer_conns) in enumerate(conns),
        (face, (producer_path, producer_port)) in consumer_conns
        isempty(producer_path) && continue           # a root input: typed below
        producer_ci = index_of(draft, producer_path)
        (refused[ci] || refused[producer_ci]) && continue
        P_F, V_F = ins_F[ci][face], outs_F[producer_ci][producer_port]
        if !_accepts_wire(P_F, V_F, Float64)
            push!(diags, WireTypeMismatch(path = draft.paths[ci], face = face, declared = P_F,
                                          producer_path = producer_path,
                                          producer_port = producer_port, observed = V_F))
            continue        # the walk clause reads a shape the bound clause has vouched for
        end
        draft.tiers[ci] === CONTINUOUS || continue    # D-167's tier scope
        P_M, V_M = ins_M[ci][face], outs_M[producer_ci][producer_port]
        _accepts_wire(P_M, V_M, Marker) && continue
        leaf, declared, observed = _walking_leaf(P_M, V_M)
        push!(diags, WalkingFaceAtFrozenEntry(path = draft.paths[ci], face = face,
                                              producer_path = producer_path,
                                              producer_port = producer_port,
                                              leaf = leaf, declared = declared,
                                              observed = observed))
    end
    root_types = Any[]
    for face in draft.root_inputs
        paths, faces, consumer_types, routed = String[], Symbol[], Any[], false
        for (ci, consumer_conns) in enumerate(conns), (consumer_face, producer) in consumer_conns
            producer === ("", face) || continue
            routed = true
            refused[ci] && continue
            push!(paths, draft.paths[ci]); push!(faces, consumer_face)
            push!(consumer_types, ins_F[ci][consumer_face])
        end
        routed || throw(InternalInvariant("root input face `$face` routes to no input"))
        if isempty(paths)                   # every consumer refused; the barrier throws
            push!(root_types, nothing)
            continue
        end
        concrete = findall(isconcretetype, consumer_types)
        if isempty(concrete)
            push!(diags, AbstractAtRoot(face = face, paths = paths, declared = consumer_types))
            push!(root_types, nothing)
            continue
        end
        P_F = consumer_types[first(concrete)]
        any(k -> consumer_types[k] !== P_F, concrete) &&
            push!(diags, RootInputTypeConflict(face = face, paths = paths[concrete],
                                               declared = consumer_types[concrete]))
        for k in eachindex(consumer_types)           # abstract co-consumers: the bound clause
            k in concrete && continue
            _accepts_wire(consumer_types[k], P_F, Float64) ||
                push!(diags, WireTypeMismatch(path = paths[k], face = faces[k],
                                              declared = consumer_types[k], producer_path = "",
                                              producer_port = face, observed = P_F))
        end
        push!(root_types, P_F)
    end
    root_types
end

# The offending leaf, for the walk clause's message. For a concrete entry the
# bound clause at `Float64` is exact (`V_F === P_F`, D-238), so the two leaf
# lists align position for position and a walk failure at the marker can only be
# a `Marker` in `V_M` where `P_M` has `Float64` — a pinned entry leaf fed by a
# walking producer leaf. Throwing path only.
function _walking_leaf(::Type{P}, ::Type{V}) where {P,V}
    isconcretetype(P) || return nothing, P, V     # decided on the whole declaration
    entry_leaves, producer_leaves = leaf_types(P), leaf_types(V)
    offending = findfirst(k -> entry_leaves[k] === Float64 && producer_leaves[k] === Marker,
                          eachindex(entry_leaves))
    offending === nothing &&
        throw(InternalInvariant("walk clause failed at `$P` ← `$V` with no walking leaf"))
    leaf_names(P)[offending], entry_leaves[offending], producer_leaves[offending]
end

"""
    activation(build, T) → Activation{T}

The activation at `T`, from the build's dictionary or derived at first request
(§9.4). The nominal `Float64` entry is one key there like any other, put in by
the nominal evaluation. An activation is a pure function of the build and the
concrete scalar type, so caching is invisible. The lookup and the insertion each
hold the build's lock and the re-run happens between them, so concurrent first
requests never see a torn dictionary: the worst race is a duplicated re-run, and
the first writer's activation is the one every caller gets.
"""
function activation(build::Build, ::Type{T}) where {T}
    hit = @lock build.lock get(build.activations, T, nothing)
    hit === nothing || return hit::Activation{T}
    nominal = (@lock build.lock build.activations[Float64])::Activation{Float64}
    derived = _activate(build.structure, build.outputs, nominal, T)
    (@lock build.lock get!(build.activations, T, derived))::Activation{T}
end

"""
    warnings(build::Build) → Vector{Diagnostic}

The warnings the build raised (§9.2, D-250). The build produces artifacts, so
its warnings live on them; the log line each one got at return is presentation,
never the home. `Deployment` and `Simulation` answer the same generic
(`deployment.jl`, `sim.jl`).
"""
warnings(build::Build) = build.warnings

# The nominal evaluation (§9.1, D-253, D-259): the build's one
# evaluation-feeds-structure step, a function of the structure alone. It runs the
# whole nominal probe chain once and returns its three products — the outputs,
# the events and the nominal `Float64` activation — so the structure and the
# `Float64` typing are fixed together rather than in two passes. Every stage is
# probed (§9.3's probe-everything scope), the classification and the execution
# order fall out between the two probe passes, and the event declarations are read
# last, against every component's complete nominal product and the layout.
function _nominal(structure::Structure)
    decls = _declarations(structure, Float64)

    # Probe-scoped mode stores and workspaces (§9.3): the probes need `m` and
    # `ws` to build bundles, and everything these hold is garbage once the
    # build finishes — each `Simulation` materializes its own.
    mstores = _mstores(structure)
    workspaces = _workspaces(structure, Float64)

    stage1 = probe_stage1(structure, decls, workspaces, mstores, Float64)
    outputs = _outputs(structure, decls, stage1, mstores)
    layout = cell_layout(structure, decls, Float64)
    products = probe_stage2(structure, decls, stage1, outputs.order, layout,
                            workspaces, mstores, nothing, Float64)
    nominal = Activation{Float64}(decls, products, layout)
    outputs, probe_events(structure, nominal), nominal
end

# Every component's declarations at `T`, each read under its component frame (§13.2, D-248).
_declarations(structure::Structure, ::Type{T}) where {T} =
    [at_component(() -> declarations(entry.instance, entry.tier, T), entry.path)
     for entry in structure.components]

# Activation at another scalar (§9.1, §9.4): the nominal evaluation's typed half
# re-run at `T`, with nothing structural recomputed. Declarations are evaluated at
# `T`, the probe chain runs and the cells are laid out, over the `Outputs`'
# execution order, which is `T`-independent. A frozen component's products are
# carried across from the nominal activation rather than probed, its stages being
# outside this activation's executable set.
function _activate(structure::Structure, outputs::Outputs, nominal::Activation{Float64},
                   ::Type{T}) where {T}
    decls = _declarations(structure, T)
    mstores = _mstores(structure)
    workspaces = _workspaces(structure, T)

    stage1 = probe_stage1(structure, decls, workspaces, mstores, T)
    layout = cell_layout(structure, decls, T)
    products = probe_stage2(structure, decls, stage1, outputs.order, layout,
                            workspaces, mstores, nominal, T)
    Activation{T}(decls, products, layout)
end

# Probe-scoped mode stores (§9.3). One read of `init_m` per component, under the
# component frame (§13.2, D-248).
_mstores(structure::Structure) =
    Any[at_component(() -> (m = invoke_declaration(init_m, entry.instance);
                            isempty(m) ? nothing : Ref(m)), entry.path)
        for entry in structure.components]

# Declaration by allocation (§7.3, D-077): sizes from the instance, eltypes from
# the activation. Called once per probe and once per `Simulation`.
_workspaces(structure::Structure, ::Type{T}) where {T} =
    Any[_workspace(entry.path, entry.instance, entry.tier, T) for entry in structure.components]

_workspace(path::String, comp, tier::Tier, ::Type{T}) where {T} =
    at_component(path) do
        _declares_workspace(comp, tier) || return nothing
        tier === CONTINUOUS ? invoke_declaration(init_workspace, comp, T) :
                           invoke_declaration(init_workspace, comp)
    end

# A discrete component's stages never run at a non-nominal activation: its
# cells are frozen `Float64` constants with zero partials, holding what the
# probe wrote, which is exactly what a tick at `t₀⁻` would have produced
# (§7.2, §10.5; `frozen_discrete_walkthrough.md`).
_frozen(tier::Tier, ::Type{T}) where {T} = tier === DISCRETE && T !== Float64

"""
Probe stage 2 in topological order — real upstream values available by
construction — and the update laws last, checking every return against the
declaration (§9.3); then the declaration-completeness check, for every
component. Frozen components are not probed: their complete products come from
`carry`, the nominal activation (§9.4). The discrete bundles' `Δt` is the
probe-scoped placeholder of `probe_stage1`. Returns the complete probe
products.
"""
function probe_stage2(structure::Structure, decls::Vector{Decls},
                      stage1, order::Vector{Int}, layout::Layout,
                      workspaces::Vector, mstores::Vector, carry, ::Type{T}) where {T}
    # The complete product is a value table read by name, never sliced: a reader
    # wanting a name list takes it from the `Outputs` instead (§9.1, D-253).
    products = NamedTuple[s1 for s1 in stage1]

    # A frozen component's stages never run at this activation, so its complete
    # product is the *nominal* activation's, carried across (§9.4): its cells
    # hold what a tick at `t₀⁻` computed from real nominal inputs — pinned
    # `Float64` constants, which downstream continuous consumers embed as
    # zero-partials. The dependence through it is temporal, not instantaneous
    # (`frozen_discrete_walkthrough.md`), so nothing here needs to gather the
    # `Dual` cell its pinned input declaration would otherwise have to refuse.
    for (ci, entry) in enumerate(structure.components)
        _frozen(entry.tier, T) && (products[ci] = carry.products[ci])
    end

    in_values(ci, decl) = NamedTuple{tuple(keys(decl.ins)...)}(tuple(
        (_probe_input(structure, layout, products, ci, face, decl.ins[face], T)
         for face in keys(decl.ins))...))

    for ci in order
        _probe_direct!(products, ci, structure, decls, stage1, layout,
                       workspaces, mstores, T)
    end

    # Completeness of the declaration set (§8.2), for every component and not
    # only the stateful ones: an unproduced port would otherwise own a cell that
    # no stage ever writes, and read as a silent zero forever. The pass collects
    # (§13.1): every component with an unproduced port is named, and the barrier
    # throws once for the whole model — as the two below it do.
    diags = Diagnostic[]
    for (ci, entry) in enumerate(structure.components)
        missing_ports = setdiff(keys(decls[ci].outs), keys(products[ci]))
        isempty(missing_ports) ||
            push!(diags, DeclaredNotProduced(path = entry.path,
                                            ports = collect(missing_ports),
                                            products = collect(keys(products[ci])),
                                            state_fields = _state_fields(
                                                _homes(decls[ci], entry.tier, mstores[ci]))))
    end
    isempty(diags) || throw(DiagnosticError(diags))

    # The update laws, probed against the now-complete table: `state_derivative`
    # for shape, `state_update` for the store's own type. A frozen component's
    # `state_update` is outside the executable set like its output stages (§9.4).
    empty!(diags)
    for (ci, entry) in enumerate(structure.components)
        comp, path, decl, tier = entry.instance, entry.path, decls[ci], entry.tier
        (isempty(state_decls(decl, tier)) || _frozen(tier, T)) && continue
        at_component(path) do
            update = update_of(tier)
            bundle_fields = bundle_names(update, comp, tier, tuple(keys(stage1[ci])...))
            bundle = _bundle_values(bundle_fields, decl, in_values(ci, decl), stage1[ci], T;
                                  y = products[ci], ws = workspaces[ci], m = mstores[ci], Δt = 1.0)
            append!(diags, tier === CONTINUOUS ?
                _check_derivative(path,
                    invoke_probed(state_derivative, :state_derivative, path, comp, tier, bundle),
                    decl.x, T) :
                _check_update(path,
                    invoke_probed(state_update, :state_update, path, comp, tier, bundle), decl.s))
        end
    end
    isempty(diags) || throw(DiagnosticError(diags))

    # `state_projection`, probed at every activation it runs at — its result is
    # written back to the buffer wholesale at both schedule positions (§5.3), so
    # the check holds it *complete* against `X`'s own shape at `T` (§9.3).
    empty!(diags)
    for (ci, entry) in enumerate(structure.components)
        comp = entry.instance
        has_stage(state_projection, comp) || continue
        path, decl = entry.path, decls[ci]
        if entry.tier !== CONTINUOUS
            push!(diags, DeclarationOnWrongTier(path = path, declaration = :state_projection,
                                               reason = :continuous_only))
            continue                               # no manifold to run it against
        end
        if isempty(decl.x)
            push!(diags, DeclarationOnWrongTier(path = path, declaration = :state_projection,
                                               reason = :no_manifold))
            continue
        end
        append!(diags, at_component(path) do
            _check_state_write(path, "state_projection",
                               invoke_declaration(state_projection, comp, decl.x), decl.x, T)
        end)
    end
    isempty(diags) || throw(DiagnosticError(diags))
    products
end

"""
One component's stage-2 probe, writing its complete product into `products[ci]`:
the body of `probe_stage2`'s topological loop, factored so the cycle classifier
can run the same chain over the acyclic prefix Kahn did place (§5.6). A
component with no `output_direct`, and a frozen one, is a no-op.
"""
function _probe_direct!(products::Vector{NamedTuple}, ci::Int, structure::Structure,
                        decls::Vector{Decls}, stage1,
                        layout::Layout, workspaces::Vector, mstores::Vector, ::Type{T}) where {T}
    entry = structure.components[ci]
    comp, path, decl, stage1_product = entry.instance, entry.path, decls[ci], stage1[ci]
    (has_stage(output_direct, comp) && !_frozen(entry.tier, T)) || return nothing
    at_component(path) do
        stage = String(nameof(output_direct))
        bundle_fields = bundle_names(output_direct, comp, entry.tier, tuple(keys(stage1_product)...))
        u = NamedTuple{tuple(keys(decl.ins)...)}(tuple(
            (_probe_input(structure, layout, products, ci, face, decl.ins[face], T)
             for face in keys(decl.ins))...))
        y2 = invoke_probed(output_direct, :output_direct, path, comp, entry.tier,
                           _bundle_values(bundle_fields, decl, u, stage1_product, T;
                                  ws = workspaces[ci], m = mstores[ci], Δt = 1.0))
        y2 isa NamedTuple ||
            throw(DiagnosticError(ConformanceFailure(path = path, what = stage,
                                                reason = :return_type, shape = :namedtuple,
                                                observed = typeof(y2))))
        isempty(y2) && throw(DiagnosticError(DeadStage(path = path, stage = stage)))
        _check_ports(path, stage, y2, decl.outs, T)
        # Stage-1 position is the stage's: a stage-2 return of a port stage 1
        # already returned writes it twice (§5.3, §8.3).
        twice = intersect(keys(stage1_product), keys(y2))
        isempty(twice) ||
            throw(DiagnosticError(ProducedByTwoStages(path = path, ports = collect(twice))))
        products[ci] = merge(stage1_product, _embed_ports(y2, decl.outs, T))
    end
    nothing
end

# The complete state write-back (§9.3): the same predicate for
# `state_projection`'s return and a handler's `x` key, both written to the flat
# buffer wholesale.
#
# It returns its violation list rather than throwing, so its two callers — the
# `state_projection` pass and the handler check — can put it under their own
# barrier (§13.1). The two shape checks are sequential: neither later one is
# meaningful once an earlier one fails.
function _check_state_write(path, what, x⁺, x::NamedTuple, ::Type{T};
                            event = nothing) where {T}
    x⁺ isa NamedTuple ||
        return Diagnostic[ConformanceFailure(path = path, what = what, event = event,
                                             reason = :return_type, shape = :state,
                                             observed = typeof(x⁺))]
    Set(keys(x⁺)) == Set(keys(x)) ||
        return Diagnostic[ConformanceFailure(path = path, what = what, event = event,
                                             reason = :field_set, shape = :state,
                                             observed_fields = collect(keys(x⁺)),
                                             declared_fields = collect(keys(x)))]
    diags = Diagnostic[]
    for field in keys(x)
        _accepts(typeof(x[field]), typeof(x⁺[field]), T) ||
            push!(diags, ConformanceFailure(path = path, what = what, event = event,
                                           reason = :field_type,
                                           shape = :state, field = field,
                                           observed = typeof(x⁺[field]),
                                           declared = typeof(x[field]), activation = T))
    end
    diags
end

"""
Probe the event system, at the nominal activation only (§9.3, D-052): guards
and handlers never run at a non-nominal activation (§9.4), so nothing here is
parametric in the scalar. Each guard runs against real probed values and its
return type *is* the detection policy (§10.4, D-179) — `Bool` boundary-detected,
the nominal scalar localized, anything else an error naming both admissible
forms. Each handler runs once and its return is held to the §5.2 return law,
key by key. Returns the `Events`, the nominal evaluation's last product (§9.1,
D-253): one row per component, its policy register beside the bundle names its
guards and handlers are called with.
"""
function probe_events(structure::Structure, nominal::Activation{Float64})
    decls, layout, products = nominal.decls, nominal.layout, nominal.products
    mstores = _mstores(structure)
    workspaces = _workspaces(structure, Float64)
    rows = ComponentEvents[]
    for (ci, entry) in enumerate(structure.components)
        comp, path, decl = entry.instance, entry.path, decls[ci]
        policies, bundle_fields = at_component(path) do
            declared_events = invoke_declaration(state_events, comp)
            isempty(declared_events) && return NamedTuple(), ()
            bundle_fields = event_bundle_names(comp)
            u = NamedTuple{tuple(keys(decl.ins)...)}(tuple(
                (_probe_input(structure, layout, products, ci, face, decl.ins[face], Float64)
                 for face in keys(decl.ins))...))
            bundle = _bundle_values(bundle_fields, decl, u, NamedTuple(), Float64; y = products[ci],
                                  ws = workspaces[ci], m = mstores[ci])
            NamedTuple{tuple(keys(declared_events)...)}(map(tuple(keys(declared_events)...)) do name
                σ = invoke_probed(declared_events[name].guard, :guard, path, comp, CONTINUOUS, bundle)
                policy = σ isa Bool ? :boundary :
                         σ isa Float64 ? :localized :
                         throw(DiagnosticError(GuardForm(path = path, event = name,
                                                    observed = typeof(σ))))
                _check_handler(path, name,
                    invoke_probed(declared_events[name].handler, :handler, path, comp,
                                 CONTINUOUS, bundle),
                    decl, comp)
                policy
            end), bundle_fields
        end
        push!(rows, ComponentEvents(path, policies, bundle_fields))
    end
    Events(rows)
end

# The handler return law (§5.2, §9.3): a key is present iff the store exists on
# the component and the handler updates it. Key set first — an unknown key, or a
# key naming a store the component does not declare, names the stores that
# exist. Then per key: `x` complete (the flat buffer is written back wholesale),
# `m` a names-subset with matching types (per-field stores merge naturally).
#
# The key loops collect under one barrier per handler (§13.1): a handler naming
# three stores it does not own names all three.
function _check_handler(path, name, returned, decl::Decls, comp)
    what = "handler"        # the event rides beside it, and the renderer composes the two
    returned isa NamedTuple ||
        throw(DiagnosticError(ConformanceFailure(path = path, what = what, event = name,
                                            reason = :return_type,
                                            shape = :stores, observed = typeof(returned))))
    m₀ = invoke_declaration(init_m, comp)
    stores = Symbol[]
    isempty(decl.x) || push!(stores, :x)
    isempty(m₀) || push!(stores, :m)
    diags = Diagnostic[]
    for key in keys(returned)
        key in stores ||
            push!(diags, HandlerReturnKey(path = path, event = name, key = key, stores = stores))
    end
    # Per key, but only for a store the component actually declares: the key set
    # is the outer fact, and holding a write to `x` against an empty state would
    # report the same omission twice in different words.
    haskey(returned, :x) && :x in stores &&
        append!(diags, _check_state_write(path, "$what `x`", returned.x, decl.x, Float64; event = name))
    if haskey(returned, :m) && :m in stores
        if !(returned.m isa NamedTuple)
            push!(diags, ConformanceFailure(path = path, what = "$what `m`", event = name,
                                           reason = :return_type, shape = :mode,
                                           observed = typeof(returned.m)))
        else
            for field in keys(returned.m)
                if !haskey(m₀, field)
                    push!(diags, ConformanceFailure(path = path, what = what, event = name,
                                                   reason = :field_set, shape = :mode,
                                                   field = field,
                                                   declared_fields = collect(keys(m₀))))
                elseif typeof(returned.m[field]) !== typeof(m₀[field])
                    push!(diags, ConformanceFailure(path = path, what = what, event = name,
                                                   reason = :field_type, shape = :mode,
                                                   field = field, observed = typeof(returned.m[field]),
                                                   declared = typeof(m₀[field])))
                end
            end
        end
    end
    isempty(diags) || throw(DiagnosticError(diags))
    nothing
end

# --- 7. entry compilation, per deployment ---------------------------------------
# What moves behind deployment binding: `Δt`, `D` and `Φ` are entry data (§9.7),
# so the executor cannot exist until `Δt_base` does. Each call materializes its
# own stores and buffers — the `Build` stays immutable and backs many
# `Simulation`s (§9.2). No user stage runs here: every check already ran at the
# probe, and what compiles is the checked shape.

"""
The declared defaults, established into the three state homes (§7.3, §8.2):
`x` into the flat buffer by the declaration walk, `s` and `m` into the
component stores they were allocated for. The stores' *types* are fixed by
their allocation; this only ever writes values into them.

Construction and `init!` share this one path, which is what makes an
application "fresh run from the `init_*` defaults, with these overrides"
(D-063) rather than an overlay on whatever the last trajectory left behind.
"""
function establish_defaults!(xbuf::Vector{T}, sstores::Vector, mstores::Vector,
                             components::Vector{ComponentEntry}, decls::Vector{Decls}) where {T}
    offset = 0
    for (ci, (decl, entry)) in enumerate(zip(decls, components))
        if entry.tier === CONTINUOUS
            for leaf_value in _leaf_values(decl.x)
                offset += 1
                xbuf[offset] = T(leaf_value)
            end
        end
        sstores[ci] === nothing || (sstores[ci][] = decl.s)
        mstores[ci] === nothing || (mstores[ci][] = init_m(entry.instance))
    end
    nothing
end

"""
One executor (§9.7, glossary): the compiled execution form of the schedule over
its own buffers, at one scalar — the entries' concretely-typed tuples closed
into the phase bodies, beside the store set they read and write.

Buffers are never cached, because every buffer set has exactly one owner
(§9.2): a `Simulation` owns its nominal executor, and every service invocation
instantiates its own from the same cached layouts.

The stepper, the arrival buffers, `chunk_size` and the localized-event key are
the executor's too (§12.6, D-256): it is the one thing that writes them. The
stepper's type is the parameter `M` because `stepper.jl` is included after this
file, which a call tolerates and a field type would not.
"""
struct Executor{T,S,B,CL,EV,M}
    act::Activation{T}     # the layout and probe products it was materialized from
    store::S               # the signal table: cells and root inputs
    xbuf::Vector{T}        # continuous state, the flat buffer (§7.1)
    ẋbuf::Vector{T}        # its derivative — integrator scratch (§7.5)
    sstores::Vector{Any}   # discrete state stores, by component index
    mstores::Vector{Any}   # mode stores, by component index
    clock::CL
    bodies::B              # the phase bodies, closed over the buffers above
    events::EV             # the compiled event set, likewise (nominal only)
    cursor::ExecutionCursor          # §13.4: where execution is, written per dispatch
    chunk_size::Int        # the unroll width it was compiled at, retained so a service
                           # can compile one of its own exactly as this was
    stepper::M             # the seam's backend (§10.2), with its own scratch
    xnext::Vector{T}       # the retained arrival pair (§10.4), xₙ₊₁ saved
    ẋnext::Vector{T}       # ẋₙ₊₁, paid only past a validated trigger
    has_localized::Bool    # any localized event compiled in: the frame loop's fast-path key
end

"""
The refusal every product compiled *against one activation* owes the executor
it is handed. A reader's `xbuf` offsets and store types and a plan's cell
addresses and converters are one activation's (§9.4), so running one against
another's buffer set would read and write the wrong slot in silence rather than
fail. The scalar rides in each product's own type and the executor carries it
too, so the pairing is dispatch — the fallback method, never a runtime test on
the hot path.

It carries no kind name, because it names no user-facing failure: §14.4 makes
the pairing a framework invariant the services uphold, neither plans nor
readers being user values, so reaching here is an internal assertion firing.
"""
@noinline _activation_mismatch(what::String, ::Type{T}, ::Type{S}) where {T,S} =
    throw(InternalInvariant(
        "this $what was compiled at $T and the executor " *
        "handed to it runs at $S — a service paired its products wrongly (§14.4). The " *
        "offsets, store types and cell addresses it bakes belong to one activation (§9.4), " *
        "and against another's buffer set they would read and write the wrong slot in " *
        "silence; one product is compiled per activation (§9.2)"))

# `algorithm` takes no default: it is trajectory-determining (§12.7), so a
# scratch executor silently built on `RK4` against a `Heun` deployment would
# give a wrong answer with no diagnostic. Every caller passes the deployment's.
# `schedule` is the deployment's `Schedule`, untyped here because `deployment.jl` is
# included after this file; the per-component gates are derived from its rows
# by `_gates` there (§9.2, D-261).
function compile(build::Build, act::Activation{T}, schedule; chunk_size::Int = 16, algorithm) where {T}
    structure, outputs, decls, layout = build.structure, build.outputs, act.decls, act.layout
    components = structure.components
    D_c, Φ_c, Δt_c = _gates(schedule, structure)

    # Three homes for state, and no store mirrors another (§7.3): the flat
    # buffer for continuous `x`, one store per discrete `s`, one per mode set.
    # A store's *type* is shared by every instance of a component type, so
    # instances still compile to one body; only the reference varies.
    sstores = Any[entry.tier === DISCRETE && !isempty(decl.s) ? Ref(decl.s) : nothing
                  for (decl, entry) in zip(decls, components)]
    mstores = _mstores(structure)
    workspaces = _workspaces(structure, T)

    store = StoreBundle(NamedTuple{tuple((_cell_key(L) for (L, _) in layout.sizes)...)}(
        tuple((CellStore(L <: Real ? zeros(L, n) : Vector{L}(undef, n))
               for (L, n) in layout.sizes)...)))

    x_offs = [first(r) - 1 for r in layout.xblocks]
    n_x = sum(length, layout.xblocks; init = 0)
    xbuf = zeros(T, n_x)
    establish_defaults!(xbuf, sstores, mstores, components, decls)
    ẋbuf = zeros(T, n_x)
    clock = Clock{T}(0.0)
    cursor = ExecutionCursor()     # closed over by every entry, exactly as `clock` is (§13.4)

    addr_group(path, names) =
        NamedTuple{tuple(names...)}(tuple((layout.addr[(path, n)] for n in names)...))
    in_group(ci, decl) =
        NamedTuple{tuple(keys(decl.ins)...)}(
            tuple((input_addr(layout, components[ci].conns, face) for face in keys(decl.ins))...))

    # A cell holds what the build probe populated until a sweep first writes it
    # (§10.5): this is the table's pre-`init!` content, and a frozen
    # component's pinned cells are this seed for the whole run (§9.4). It is
    # also what leaves no handle cell unassigned: an opaque-leaf buffer starts
    # `undef`, every handle port is a component product this seed writes, and a
    # handle at a root input is refused at layout (D-237).
    for (ci, entry) in enumerate(components)
        isempty(act.products[ci]) ||
            scatter_group!(store, addr_group(entry.path, keys(act.products[ci])),
                           act.products[ci], T, entry.path, :probe)
    end
    # Root inputs hold their synthesized values until a writer replaces them.
    for (face, v) in layout.root_inputs
        scatter!(store, layout.addr[("", face)], v)
    end

    frozen(ci) = _frozen(components[ci].tier, T)
    gate(ci) = components[ci].tier === DISCRETE ? (D_c[ci], Φ_c[ci]) : nothing

    stage1_entries, stage2_entries, rhs_entries, tick_entries = Any[], Any[], Any[], Any[]
    stage1_gates, stage2_gates, rhs_gates, tick_gates = Any[], Any[], Any[], Any[]

    for (ci, entry) in enumerate(components)
        comp, path = entry.instance, entry.path
        (has_stage(output_state, comp) && !frozen(ci)) || continue
        decl = decls[ci]
        bundle_fields = bundle_names(output_state, comp, entry.tier, ())
        push!(stage1_entries, StageEntry{typeof(decl.x),bundle_fields}(
            output_state, comp, NamedTuple(), NamedTuple(),
            addr_group(path, outputs.components[ci].stage1),
            x_offs[ci], clock, sstores[ci], mstores[ci], workspaces[ci], Δt_c[ci],
            path, ci, cursor))
        push!(stage1_gates, gate(ci))
    end

    for ci in outputs.order
        entry = components[ci]
        comp, path, decl = entry.instance, entry.path, decls[ci]
        (has_stage(output_direct, comp) && !frozen(ci)) || continue
        stage1_names = outputs.components[ci].stage1
        bundle_fields = bundle_names(output_direct, comp, entry.tier, tuple(stage1_names...))
        push!(stage2_entries, StageEntry{typeof(decl.x),bundle_fields}(
            output_direct, comp, in_group(ci, decl), addr_group(path, stage1_names),
            addr_group(path, outputs.components[ci].stage2), x_offs[ci], clock,
            sstores[ci], mstores[ci], workspaces[ci], Δt_c[ci], path, ci, cursor))
        push!(stage2_gates, gate(ci))
    end

    # The update law, one block per tier: `state_derivative` into the flat
    # derivative buffer, `state_update` into the component's own store. Both
    # read the complete fresh table.
    for (ci, entry) in enumerate(components)
        comp, path, decl, tier = entry.instance, entry.path, decls[ci], entry.tier
        (isempty(state_decls(decl, tier)) || frozen(ci)) && continue
        update = update_of(tier)
        bundle_fields = bundle_names(update, comp, tier, tuple(outputs.components[ci].stage1...))
        output_addrs, input_addrs = addr_group(path, _ports(outputs.components[ci])), in_group(ci, decl)
        if tier === CONTINUOUS
            push!(rhs_entries, RHSEntry{typeof(decl.x),bundle_fields}(
                comp, input_addrs, output_addrs, x_offs[ci], clock, mstores[ci], workspaces[ci],
                path, ci, cursor))
            push!(rhs_gates, nothing)
        else
            push!(tick_entries, UpdateEntry{bundle_fields}(
                comp, input_addrs, output_addrs, clock, sstores[ci], workspaces[ci], Δt_c[ci],
                path, ci, cursor))
            push!(tick_gates, gate(ci))
        end
    end

    # The event system compiles at the nominal activation only: guards and
    # handlers are outside every other activation's executable set (§9.4,
    # D-052), so the event phase there is the bare sweep. Entries carry a global
    # index into the register vectors, in executor component order then
    # declaration order within a component (§10.6), and each carries the policy
    # its component's `Events` row fixes into the compiled mask — which is what
    # the frame loop's trigger check reads (§10.4).
    event_entries, event_owner = Any[], Int[]
    event_names = Tuple{String,Symbol}[]
    event_localized = Bool[]
    if T === Float64
        for (ci, entry) in enumerate(components)
            comp, path = entry.instance, entry.path
            row = build.events.components[ci]
            policies, bundle_fields = row.policies, row.bundle
            isempty(policies) && continue
            decl = decls[ci]
            # The names, the policies and the bundle are the product's; the guard
            # and handler are functions, which no product carries.
            declared_events = at_component(() -> invoke_declaration(state_events, comp), path)
            projection = has_stage(state_projection, comp) ? state_projection : nothing
            for name in keys(policies)
                push!(event_entries, EventEntry{typeof(decl.x),bundle_fields}(
                    declared_events[name].guard, declared_events[name].handler, projection, comp,
                    length(event_entries) + 1,
                    in_group(ci, decl), addr_group(path, _ports(outputs.components[ci])),
                    x_offs[ci], clock, mstores[ci], workspaces[ci], path, name, ci, cursor))
                push!(event_owner, ci)
                push!(event_names, (path, name))
                push!(event_localized, policies[name] === :localized)
            end
        end
    end

    # Projection runs at every activation — it is continuous machinery, inside
    # every executable set — between the integrate's state write and its decode
    # (§5.3).
    projection_entries = Any[ProjectEntry{typeof(decls[ci].x)}(entry.instance, x_offs[ci], clock,
                                                        entry.path, ci, cursor)
                       for (ci, entry) in enumerate(components)
                       if entry.tier === CONTINUOUS && has_stage(state_projection, entry.instance)]

    body(entries, gates) = chunked_body(entries, gates, store, xbuf, ẋbuf; chunk_size)
    # Beside the four blocks ride the per-event and per-projection callables,
    # keyed by the roster (§9.7): (path, event name) and path.
    event_bodies = Dict{Tuple{String,Symbol},NamedTuple}(
        event_names[i] => _event_bodies(event_entries[i], store, xbuf) for i in eachindex(event_entries))
    projection_bodies = Dict{String,Function}(entry.path => _project_body(entry, xbuf)
                                              for entry in projection_entries)
    bodies = (sweep_1 = body(stage1_entries, stage1_gates),
              sweep_2 = body(stage2_entries, stage2_gates),
              rhs = body(rhs_entries, rhs_gates),
              ticks = body(tick_entries, tick_gates),
              events = event_bodies, projections = projection_bodies)

    event_set = EventSet(event_entries, projection_entries, event_owner, event_names, event_localized,
                     length(components))
    # The seam's backend and the arrival pair are this buffer set's, so they are
    # built here rather than by the caller (§12.6, D-256).
    Executor(act, store, xbuf, ẋbuf, sstores, mstores, clock, bodies, event_set, cursor,
             chunk_size, algorithm(T, n_x), zeros(T, n_x), zeros(T, n_x),
             any(event_localized))
end

# A probed input value: the producer's product, or the synthesized value of the
# root input the obligation chain ends at. Stage-2 probing runs in topological
# order, so upstream products exist by construction.
#
# The entry is a *bound*, read permissively (D-167): a `T` entry is tolerant of
# both lawful arrivals, a pinned `Float64` entry demands a frozen one. The value
# passed on is the producer's, unembedded — the consumer gathers the producer's
# cell at runtime, so the cell's type is what its bundle carries.
#
# Both wire clauses were decided in the structure step (D-236). The products
# `_embed_ports` hands down carry exactly the producer's declared type at `T`,
# and a root input's cell is admitted by every entry by the meet, so a refusal
# here is a framework bug rather than a model error — hence the fence, not a
# diagnostic.
function _probe_input(structure::Structure, layout::Layout, products, ci, face, entry_type,
                      ::Type{T}) where {T}
    entry = structure.components[ci]
    path = entry.path
    (producer_path, producer_port) = last(entry.conns[findfirst(p -> first(p) === face, entry.conns)])
    value = if isempty(producer_path)
        last(layout.root_inputs[findfirst(r -> first(r) === producer_port, layout.root_inputs)])
    else
        products[index_of(structure, producer_path)][producer_port]
    end
    _accepts_wire(entry_type, typeof(value), T) ||
        throw(InternalInvariant("probe input `$path`.$face: $(typeof(value)) at an entry " *
                                "declaring $entry_type, which the structure step admitted"))
    value
end

# §7.1: `Ẋ` has exactly `X`'s shape at the activation scalar. Checked
# structurally here so the runtime `flatten!` into the derivative block is safe.
function _check_derivative(path, ẋ, x::NamedTuple, ::Type{T}) where {T}
    ẋ isa NamedTuple ||
        return Diagnostic[ConformanceFailure(path = path, what = "state_derivative",
                                             reason = :return_type,
                                             shape = :init_x, observed = typeof(ẋ))]
    Set(keys(ẋ)) == Set(keys(x)) ||
        return Diagnostic[ConformanceFailure(path = path, what = "state_derivative",
                                             reason = :field_set,
                                             shape = :init_x,
                                             observed_fields = collect(keys(ẋ)),
                                             declared_fields = collect(keys(x)))]
    diags = Diagnostic[]
    for field in keys(x)
        _accepts(typeof(x[field]), typeof(ẋ[field]), T) ||
            push!(diags, ConformanceFailure(path = path, what = "state_derivative",
                                           reason = :field_type,
                                           shape = :init_x, field = field,
                                           observed = typeof(ẋ[field]), declared = typeof(x[field]),
                                           activation = T))
    end
    diags
end

# §7.3: a discrete store is overwritten wholesale with what `state_update`
# returns, so the successor must be the store's own type exactly. The discrete
# world is pinned — no walk, no embedding — which makes the store assignment
# type-stable and the ban on arithmetic over stores enforceable by construction.
function _check_update(path, s⁺, s::NamedTuple)
    s⁺ isa NamedTuple ||
        return Diagnostic[ConformanceFailure(path = path, what = "state_update",
                                             reason = :return_type,
                                             shape = :init_s, observed = typeof(s⁺))]
    typeof(s⁺) === typeof(s) ||
        return Diagnostic[ConformanceFailure(path = path, what = "state_update",
                                             reason = :field_set,
                                             shape = :init_s, observed = typeof(s⁺),
                                             declared = typeof(s))]
    Diagnostic[]
end
