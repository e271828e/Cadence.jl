# §5.6's feedthrough tracer and the cycle classifier (D-012, D-140, D-245).
#
# Diagnostic only, never relied on for correctness: scheduling correctness comes
# from the structural two-stage split alone. What runs here is the *local*
# variant of D-012 — the schedule-free per-member trace at the probe point,
# inside the nominal evaluation's failure path, where no schedule and no
# layout for the cluster exist. The other variant, the tracer *activation* of
# §9.4, is a whole-model run at this scalar and is not built here.
#
# SparseConnectivityTracer.jl offers the same global/local pair, and its "requires
# primal value" error is this file's `Undecidable`. It was weighed and not
# adopted: its global tracer carries no primal, so a branch on state, on a mode or
# on time would force the sampled fallback where this scalar decides at the probe
# point. It is the drop-in behind `_lift`, `_tag` and `_classify` if the method
# list below proves too narrow on a real model.

# --- the scalar ---------------------------------------------------------------

"""
§5.6's set-propagation scalar. Every leaf carries the set of in-cycle input
faces it may depend on, as a bitmask, unioned by every operation; `val` is a
primal the local mode branches on. `S = true` is the global, value-blind
tracer: a comparison or a value-severing conversion touching a tagged operand
throws `Undecidable`, since either arm would drop the other's set. `S = false`
is the local tracer: it decides on `val` and reports the taken path (D-012).
"""
struct Tracer{S} <: Real
    val::Float64
    deps::UInt64
end

"The global tracer's refusal at a tainted decision (§5.6). A marker, never rendered."
struct Undecidable <: Exception end

Tracer{S}(x::Real) where {S} = Tracer{S}(Float64(x), UInt64(0))
Tracer{S}(x::Tracer{S}) where {S} = x

Base.promote_rule(::Type{Tracer{S}}, ::Type{<:Real}) where {S} = Tracer{S}
# The two non-nominal scalars never meet in one evaluation; this rule exists only
# to keep the method table free of an ambiguity with ForwardDiff's own.
Base.promote_rule(::Type{Tracer{S}}, ::Type{ForwardDiff.Dual{T,V,N}}) where {S,T,V,N} = Union{}
Base.zero(::Type{Tracer{S}}) where {S} = Tracer{S}(0.0, UInt64(0))
Base.one(::Type{Tracer{S}}) where {S} = Tracer{S}(1.0, UInt64(0))
Base.float(x::Tracer) = x

# The documented blind spot (§5.6): a value-severing conversion drops the set,
# which the local tracer accepts and the global one refuses.
Base.Float64(x::Tracer{false}) = x.val
Base.Float64(::Tracer{true}) = throw(Undecidable())

# Set union. `min`/`max` are here rather than on the deciders below because a
# saturated `clamp` still reports its argument's set — may-depend semantics.
for f in (:+, :-, :*, :/, :^, :atan, :hypot, :min, :max, :copysign, :rem, :mod)
    @eval Base.$f(x::Tracer{S}, y::Tracer{S}) where {S} =
        Tracer{S}($f(x.val, y.val), x.deps | y.deps)
end
Base.:^(x::Tracer{S}, n::Integer) where {S} = Tracer{S}(x.val^n, x.deps)
Base.muladd(x::Tracer{S}, y::Tracer{S}, z::Tracer{S}) where {S} =
    Tracer{S}(muladd(x.val, y.val, z.val), x.deps | y.deps | z.deps)
Base.clamp(x::Tracer{S}, lo::Real, hi::Real) where {S} =
    min(max(x, Tracer{S}(lo)), Tracer{S}(hi))
Base.ifelse(test::Bool, x::Tracer{S}, y::Tracer{S}) where {S} =
    Tracer{S}(ifelse(test, x.val, y.val), x.deps | y.deps)   # branch-free: both sets survive

for f in (:-, :abs, :abs2, :sqrt, :cbrt, :exp, :log, :log2, :log10, :sin, :cos, :tan,
          :asin, :acos, :sinh, :cosh, :tanh, :sign, :inv, :floor, :ceil, :round, :trunc,
          :atan, :asinh, :acosh, :atanh, :expm1, :log1p, :exp2, :exp10, :sinpi, :cospi,
          :deg2rad, :rad2deg, :sind, :cosd, :tand, :asind, :acosd, :atand,
          :sec, :csc, :cot, :mod2pi)
    @eval Base.$f(x::Tracer{S}) where {S} = Tracer{S}($f(x.val), x.deps)
end

# A function off these lists degrades in one of two ways, and the classifier's
# catch ships the cluster unclassified under either: a `MethodError` from the
# member's evaluation, or — where Base routes a `Real` through `f(float(x))` —
# a `StackOverflowError`, `float` being the identity here. That identity stays:
# `AbstractFloat(x)` instead would route through `Float64(::Tracer)`, which throws
# in global mode and silently severs the set in local mode, both worse.

# `hypot` beyond two arguments and `norm` scale by the largest operand, a
# comparison the global tracer refuses; the union is that answer without the
# branch. An infinite `p` keeps Base's own walk: `Inf` reaches the union `max`
# and passes, `-Inf` meets a tainted comparison and refuses (§5.6).
function Base.hypot(x::Tracer{S}, y::Tracer{S}, z::Tracer{S}...) where {S}
    operands = (x, y, z...)
    Tracer{S}(hypot(map(v -> v.val, operands)...), reduce(|, map(v -> v.deps, operands)))
end

_norm(v, p::Real) = p == 2 ? sqrt(sum(abs2, v)) : sum(x -> abs(x)^p, v)^(1 / p)

LinearAlgebra.norm(v::AbstractArray{<:Tracer}, p::Real = 2) =
    isfinite(p) ? _norm(v, p) : invoke(LinearAlgebra.norm, Tuple{Any,Real}, v, p)
# StaticArrays' own `norm` is the more specific method on an `SVector`, so the
# scalar has to meet it there too.
LinearAlgebra.norm(v::StaticArray{S,<:Tracer}, p::Real = 2) where {S<:Tuple} =
    isfinite(p) ? _norm(v, p) : invoke(LinearAlgebra.norm, Tuple{StaticArray,Real}, v, p)

"""
A decision is legal when no operand carries a set, or when the local tracer is
deciding on its primal. State, modes, parameters and time carry empty sets, so a
branch on them decides at the probe state in either mode (§5.6's boundaries).
"""
_decide(S::Bool, deps::UInt64) = (S && !iszero(deps)) ? throw(Undecidable()) : nothing

for f in (:<, :<=, :(==), :isless)
    @eval function Base.$f(x::Tracer{S}, y::Tracer{S}) where {S}
        _decide(S, x.deps | y.deps)
        $f(x.val, y.val)
    end
end
for f in (:iszero, :isnan, :isfinite, :isinf, :signbit)
    @eval function Base.$f(x::Tracer{S}) where {S}
        _decide(S, x.deps)
        $f(x.val)
    end
end
for f in (:round, :floor, :trunc)
    @eval function Base.$f(::Type{I}, x::Tracer{S}) where {I<:Integer,S}
        _decide(S, x.deps)
        $f(I, x.val)
    end
end
function Base.Int(x::Tracer{S}) where {S}
    _decide(S, x.deps)
    Int(x.val)
end
function Base.Bool(x::Tracer{S}) where {S}
    _decide(S, x.deps)
    Bool(x.val)
end

# --- the leaf-wise lift and tag -----------------------------------------------

# `_embed` and `retype_value` convert *every* leaf through `T`, which a `Tracer`
# converts none of back (a `Bool` or an `Int` leaf survives that round trip at a
# `Dual` and does not here). These walk the same leaves and touch `Float64` ones
# only; an opaque leaf (D-237) passes through untouched. `reconstruct` indexes
# the buffer and lets each constructor convert, so an `Any` buffer is enough.
_walk(::Type{T}, v, f) where {T} =
    reconstruct(retype(T, typeof(v)), Any[f(l) for l in _leaf_values(v)], 0)

"""`v` at the tracer scalar, untagged: a probed prefix value entering the trace."""
_lift(::Type{T}, v) where {T} = _walk(T, v, l -> l isa Float64 ? T(l) : l)

"""
`v` at the tracer scalar with every walking leaf seeded by one face's tag. A
face synthesized through `probe_value` at `T` arrives already carrying `Tracer`
leaves, which is why the walk re-tags those as well as `Float64` ones.
"""
_tag(::Type{T}, v, bit::UInt64) where {T} =
    _walk(T, v, l -> l isa Float64 ? T(l, bit) : l isa Tracer ? T(l.val, bit) : l)

"""
`_tag` with the primal redrawn: the sampled fallback's seed (§5.6). The local
tracer decides on `val`, so a state and an in-cycle face have to move between
evaluations for the branches to move with them; the leaf order is the walk's,
so one `rng` gives one reproducible draw per evaluation.
"""
_sample(rng, ::Type{T}, v, bit::UInt64) where {T} =
    _walk(T, v, l -> l isa Float64 || l isa Tracer ? T(randn(rng), bit) : l)

"""The union of the tags a value's `Tracer` leaves carry; a `Float64` port has none (D-166)."""
function _depset(v)
    deps = UInt64(0)
    for leaf in _leaf_values(v)
        leaf isa Tracer && (deps |= leaf.deps)
    end
    deps
end

# --- the per-member trace ------------------------------------------------------

"""
One member's evaluation (§5.6): `output_direct` once, in isolation, at the
probe point. The in-cluster faces of `faces` are seeded with their tags, every
other bundle field untagged — only inputs are seeded, so a branch on state,
modes, parameters or time never interferes (§5.6's boundaries). Returns
`port => the union of the tags the port's leaves carry`, over `ports`.

With an `rng` this is one sampled evaluation instead: the state and the seeded
faces carry redrawn primals, everything else the probe point's own values.
"""
function _trace_direct(ci::Int, traced_decl::Decls, faces::Vector{Symbol},
                       face_traceable::Vector{Bool}, ports::Vector{Symbol}, structure::Structure,
                       decls::Vector{Decls}, stage1::Vector, mstores::Vector,
                       products::Vector{NamedTuple}, cluster_set::Set{Int}, ::Type{T};
                       rng = nothing) where {T}
    comp, decl = structure.components[ci].instance, decls[ci]
    u = NamedTuple{tuple(keys(decl.ins)...)}(tuple(
        (_seed(ci, face, faces, face_traceable, structure, products, cluster_set, T, rng)
         for face in keys(decl.ins))...))
    # The nominal `x` carries `Float64` leaves, which the sampled walk redraws;
    # `traced_decl.x` is the declared one, already at `T`.
    evaluation_decl = rng === nothing ? traced_decl :
        Decls(_sample(rng, T, decl.x, UInt64(0)), traced_decl.s, traced_decl.ins,
             traced_decl.outs)
    bundle_fields = bundle_names(output_direct, comp, CONTINUOUS, tuple(keys(stage1[ci])...))
    workspace = _declares_workspace(comp, CONTINUOUS) ? init_workspace(comp, T) : nothing
    y2 = output_direct(comp, _bundle_values(bundle_fields, evaluation_decl, u,
                                         _lift(T, stage1[ci]), T;
                                         ws = workspace, m = mstores[ci], Δt = 1.0))
    Dict{Symbol,UInt64}(q => _depset(y2[q]) for q in ports)
end

"""
The sampled fallback (§5.6, D-012): where the global tracer met an
input-tainted branch, the local tracer decides on its primal and reports the
paths that decision took. Eight evaluations at a fixed seed, the state and the
in-cycle faces redrawn for each, the map their union — so a face routed on any
sampled path counts as routed, and only a branch none of the eight took is
missed. The seed is per member, so the verdict is reproducible.
"""
function _trace_sampled(ci::Int, faces::Vector{Symbol}, face_traceable::Vector{Bool},
                        ports::Vector{Symbol}, structure::Structure, decls::Vector{Decls},
                        stage1::Vector, mstores::Vector, products::Vector{NamedTuple},
                        cluster_set::Set{Int})
    T = Tracer{false}
    traced_decl = declarations(structure.components[ci].instance, CONTINUOUS, T)
    rng = Xoshiro(0)
    routes = Dict{Symbol,UInt64}(q => UInt64(0) for q in ports)
    for _ in 1:8
        sample_routes = _trace_direct(ci, traced_decl, faces, face_traceable, ports, structure,
                          decls, stage1, mstores, products, cluster_set, T; rng = rng)
        for q in ports
            routes[q] |= sample_routes[q]
        end
    end
    routes
end

"""
One face's seed. An in-cluster face carries its tag, synthesized through
`probe_value` at the producer's declared type; a face the acyclic prefix feeds
carries that prefix's probe product, lifted and untagged; a root input is
synthesized untagged; an unplaced producer outside the cluster is synthesized
untagged too, there being no product to read. Only the in-cluster face's seed
is redrawn under an `rng`; everything the trace reads from outside the cluster
stays at the probe point.
"""
function _seed(ci::Int, face::Symbol, faces::Vector{Symbol}, face_traceable::Vector{Bool},
               structure::Structure, products::Vector{NamedTuple}, cluster_set::Set{Int},
               ::Type{T}, rng) where {T}
    conns = structure.components[ci].conns
    (producer_path, producer_port) = last(conns[findfirst(p -> first(p) === face, conns)])
    if isempty(producer_path)
        k = findfirst(==(producer_port), structure.root_inputs)
        return probe_value(retype(T, structure.root_types[k]))
    end
    producer_ci = index_of(structure, producer_path)
    producer = structure.components[producer_ci]
    declared() =
        probe_value(declarations(producer.instance, producer.tier, T).outs[producer_port])
    j = producer_ci in cluster_set ? findfirst(==(face), faces) : nothing
    if j !== nothing
        bit = face_traceable[j] ? UInt64(1) << (j - 1) : UInt64(0)
        return rng === nothing ? _tag(T, declared(), bit) : _sample(rng, T, declared(), bit)
    end
    haskey(products[producer_ci], producer_port) ?
        _lift(T, products[producer_ci][producer_port]) : declared()
end

# --- the verdict ---------------------------------------------------------------

"""
§5.6's classification, D-245's verdict. Returns `cycle` carrying `classification`,
`dead` and `traced`, or `cycle` unchanged when any member's evaluation threw —
classification is a bonus on the cycle error, never its precondition.

`scc` is the cluster in `cycle.members` order and `placed` Kahn's partial schedule,
whose components are the acyclic prefix the out-of-cycle faces read from. The
whole body runs under one `try`: an `InternalInvariant` is a framework bug and
is rethrown, and everything else ships the cluster unclassified. An
`Undecidable` is not "everything else": it is the global tracer's own refusal,
and the member falls back to the sampled trace below.
"""
function _classify(cycle::AlgebraicCycle, scc::Vector{Int}, edges, placed::Vector{Int},
                   structure::Structure, decls::Vector{Decls}, stage1::Vector,
                   mstores::Vector)
    T = Tracer{true}
    try
        # The acyclic prefix's probe products, at the nominal scalar: the same
        # chain `probe_stage2` runs, stopped where Kahn stopped.
        layout = cell_layout(structure, decls, Float64)
        workspaces = _workspaces(structure, Float64)
        products = NamedTuple[s1 for s1 in stage1]
        for ci in placed
            _probe_direct!(products, ci, structure, decls, stage1, layout,
                           workspaces, mstores, Float64)
        end

        cluster_set = Set(scc)
        member_faces = [Symbol[] for _ in scc]         # entering faces, in `decls` order
        member_ports = [Symbol[] for _ in scc]         # leaving ports, in `decls` order
        alive = [Set{Tuple{Symbol,Symbol}}() for _ in scc]
        trace_modes = Symbol[]
        dead = Tuple{String,Symbol,Symbol}[]

        for (i, ci) in enumerate(scc)
            decl = decls[ci]
            faces = Symbol[face for face in keys(decl.ins)
                        if any(edge -> edge[3] === face && edge[1] in cluster_set, edges[ci])]
            ports = Symbol[q for q in keys(decl.outs)
                        if any(cj -> any(edge -> edge[1] == ci && edge[2] === q, edges[cj]),
                               scc)]
            member_faces[i], member_ports[i] = faces, ports

            # A discrete member's pinned declarations admit no tracer scalar, and
            # neither does a continuous face or port declared with no walking leaf
            # (§5.6, D-245). Beyond 64 faces the bitmask runs out.
            traced_decl = structure.components[ci].tier === CONTINUOUS && length(faces) ≤ 64 ?
                 declarations(structure.components[ci].instance, CONTINUOUS, T) : nothing
            face_traceable = traced_decl === nothing ? falses(length(faces)) :
                 Bool[T in leaf_types(traced_decl.ins[face]) for face in faces]
            port_traceable = traced_decl === nothing ? falses(length(ports)) :
                 Bool[T in leaf_types(traced_decl.outs[q]) for q in ports]

            if !any(face_traceable) || !any(port_traceable)   # no traceable hop: structure alone
                push!(trace_modes, :structural)
                for face in faces, port_name in ports
                    push!(alive[i], (face, port_name))
                end
                continue
            end
            # The global tracer is exact in one evaluation and refuses an
            # input-tainted branch; the local one then decides on its primal
            # over sampled states, missing only an untaken branch (§5.6, D-012).
            routes, trace_mode = try
                _trace_direct(ci, traced_decl, faces, face_traceable, ports, structure, decls,
                              stage1, mstores, products, cluster_set, T), :global
            catch err
                err isa Undecidable || rethrow()
                _trace_sampled(ci, faces, face_traceable, ports, structure, decls, stage1,
                               mstores, products, cluster_set), :sampled
            end
            push!(trace_modes, trace_mode)
            # An untraceable face or port leaves its hops alive; a traced hop the
            # map does not route is dead, and is listed under either verdict (D-245).
            for (j, face) in enumerate(faces), (k, port_name) in enumerate(ports)
                if !face_traceable[j] || !port_traceable[k] ||
                        !iszero(routes[port_name] & (UInt64(1) << (j - 1)))
                    push!(alive[i], (face, port_name))
                else
                    push!(dead, (cycle.members[i], face, port_name))
                end
            end
        end

        # The port graph: a node per cluster wire endpoint, every wire an edge,
        # a member's surviving hops the edges inside it. Real iff a cycle
        # survives it (D-245).
        node = Dict{Tuple{Int,Bool,Symbol},Int}()
        adjacency = Vector{Int}[]
        node_id!(endpoint) = get!(node, endpoint) do
            push!(adjacency, Int[])
            length(adjacency)
        end
        for i in eachindex(scc), face in member_faces[i], port_name in member_ports[i]
            (face, port_name) in alive[i] &&
                push!(adjacency[node_id!((i, true, face))], node_id!((i, false, port_name)))
        end
        for (i, ci) in enumerate(scc), (producer_ci, producer_port, face) in edges[ci]
            producer_ci in cluster_set || continue
            j = findfirst(==(producer_ci), scc)
            push!(adjacency[node_id!((j, false, producer_port))], node_id!((i, true, face)))
        end

        AlgebraicCycle(members = cycle.members, wires = cycle.wires,
                       classification = _has_cycle(adjacency) ? :real : :artificial,
                       dead = dead,
                       traced = [member => trace_mode
                                 for (member, trace_mode) in zip(cycle.members, trace_modes)])
    catch err
        err isa InternalInvariant && rethrow()
        cycle
    end
end

"Depth-first search for a back edge: white/grey/black, recursive as Tarjan above."
function _has_cycle(adjacency::Vector{Vector{Int}})
    color = zeros(UInt8, length(adjacency))
    function grey!(vertex)
        color[vertex] = 0x1
        for successor in adjacency[vertex]
            color[successor] == 0x1 && return true
            color[successor] == 0x0 && grey!(successor) && return true
        end
        color[vertex] = 0x2
        false
    end
    any(v -> color[v] == 0x0 && grey!(v), eachindex(adjacency))
end
