# §5.6's feedthrough tracer and the cycle classifier (D-012, D-140, D-245).
#
# Diagnostic only, never relied on for correctness: scheduling correctness comes
# from the structural two-stage split alone. What runs here is the *local*
# variant of D-012 — the schedule-free per-member trace at the probe point,
# inside Stratum B's failure path, where no schedule and no layout for the
# cluster exist. The other variant, the tracer *activation* of §9.4, is a
# whole-model run at this scalar and is not built here.

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
    @eval Base.$f(a::Tracer{S}, b::Tracer{S}) where {S} =
        Tracer{S}($f(a.val, b.val), a.deps | b.deps)
end
Base.:^(x::Tracer{S}, n::Integer) where {S} = Tracer{S}(x.val^n, x.deps)
Base.muladd(a::Tracer{S}, b::Tracer{S}, c::Tracer{S}) where {S} =
    Tracer{S}(muladd(a.val, b.val, c.val), a.deps | b.deps | c.deps)
Base.clamp(x::Tracer{S}, lo::Real, hi::Real) where {S} =
    min(max(x, Tracer{S}(lo)), Tracer{S}(hi))
Base.ifelse(b::Bool, x::Tracer{S}, y::Tracer{S}) where {S} =
    Tracer{S}(ifelse(b, x.val, y.val), x.deps | y.deps)   # branch-free: both sets survive

for f in (:-, :abs, :abs2, :sqrt, :cbrt, :exp, :log, :log2, :log10, :sin, :cos, :tan,
          :asin, :acos, :sinh, :cosh, :tanh, :sign, :inv, :floor, :ceil, :round, :trunc)
    @eval Base.$f(x::Tracer{S}) where {S} = Tracer{S}($f(x.val), x.deps)
end

"""
A decision is legal when no operand carries a set, or when the local tracer is
deciding on its primal. State, modes, parameters and time carry empty sets, so a
branch on them decides at the probe state in either mode (§5.6's boundaries).
"""
_decide(S::Bool, deps::UInt64) = (S && !iszero(deps)) ? throw(Undecidable()) : nothing

for f in (:<, :<=, :(==), :isless)
    @eval function Base.$f(a::Tracer{S}, b::Tracer{S}) where {S}
        _decide(S, a.deps | b.deps)
        $f(a.val, b.val)
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
    s = UInt64(0)
    for l in _leaf_values(v)
        l isa Tracer && (s |= l.deps)
    end
    s
end

# --- the per-member trace ------------------------------------------------------

"""
One member's evaluation (§5.6): `output_direct` once, in isolation, at the
probe point. The in-cluster faces of `fs` are seeded with their tags, every
other bundle field untagged — only inputs are seeded, so a branch on state,
modes, parameters or time never interferes (§5.6's boundaries). Returns
`port => the union of the tags the port's leaves carry`, over `qs`.

With an `rng` this is one sampled evaluation instead: the state and the seeded
faces carry redrawn primals, everything else the probe point's own values.
"""
function _trace_direct(ci::Int, dT::Decls, fs::Vector{Symbol}, tf::Vector{Bool},
                       qs::Vector{Symbol}, flat::Flat, tiers::Vector{Tier},
                       decls::Vector{Decls}, stage1::Vector, mstores::Vector,
                       products::Vector{NamedTuple}, inscc::Set{Int}, ::Type{T};
                       rng = nothing) where {T}
    c, dc = flat.comps[ci], decls[ci]
    u = NamedTuple{tuple(keys(dc.ins)...)}(tuple(
        (_seed(ci, face, fs, tf, flat, tiers, products, inscc, T, rng)
         for face in keys(dc.ins))...))
    # The nominal `x` carries `Float64` leaves, which the sampled walk redraws;
    # `dT.x` is the declared one, already at `T`.
    d = rng === nothing ? dT :
        Decls(_sample(rng, T, dc.x, UInt64(0)), dT.s, dT.ins, dT.outs)
    bn = bundle_names(output_direct, c, CONTINUOUS, tuple(keys(stage1[ci])...))
    ws = _declares_workspace(c, CONTINUOUS) ? init_workspace(c, T) : nothing
    y2 = output_direct(c, _bundle_values(bn, d, u, _lift(T, stage1[ci]), T;
                                         ws = ws, m = mstores[ci], Δt = 1.0))
    Dict{Symbol,UInt64}(q => _depset(y2[q]) for q in qs)
end

"""
The sampled fallback (§5.6, D-012): where the global tracer met an
input-tainted branch, the local tracer decides on its primal and reports the
paths that decision took. Eight evaluations at a fixed seed, the state and the
in-cycle faces redrawn for each, the map their union — so a face routed on any
sampled path counts as routed, and only a branch none of the eight took is
missed. The seed is per member, so the verdict is reproducible.
"""
function _trace_sampled(ci::Int, fs::Vector{Symbol}, tf::Vector{Bool}, qs::Vector{Symbol},
                        flat::Flat, tiers::Vector{Tier}, decls::Vector{Decls},
                        stage1::Vector, mstores::Vector, products::Vector{NamedTuple},
                        inscc::Set{Int})
    T = Tracer{false}
    dT = declarations(flat.comps[ci], CONTINUOUS, T)
    rng = Xoshiro(0)
    routes = Dict{Symbol,UInt64}(q => UInt64(0) for q in qs)
    for _ in 1:8
        r = _trace_direct(ci, dT, fs, tf, qs, flat, tiers, decls, stage1, mstores,
                          products, inscc, T; rng = rng)
        for q in qs
            routes[q] |= r[q]
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
function _seed(ci::Int, face::Symbol, fs::Vector{Symbol}, tf::Vector{Bool}, flat::Flat,
               tiers::Vector{Tier}, products::Vector{NamedTuple}, inscc::Set{Int},
               ::Type{T}, rng) where {T}
    conns = flat.conns[ci]
    (ppath, pport) = last(conns[findfirst(p -> first(p) === face, conns)])
    if isempty(ppath)
        k = findfirst(==(pport), flat.root_inputs)
        return probe_value(retype(T, flat.root_types[k]))
    end
    pi = index_of(flat, ppath)
    declared() = probe_value(declarations(flat.comps[pi], tiers[pi], T).outs[pport])
    j = pi in inscc ? findfirst(==(face), fs) : nothing
    if j !== nothing
        bit = tf[j] ? UInt64(1) << (j - 1) : UInt64(0)
        return rng === nothing ? _tag(T, declared(), bit) : _sample(rng, T, declared(), bit)
    end
    haskey(products[pi], pport) ? _lift(T, products[pi][pport]) : declared()
end

# --- the verdict ---------------------------------------------------------------

"""
§5.6's classification, D-245's verdict. Returns `d` carrying `classification`,
`dead` and `traced`, or `d` unchanged when any member's evaluation threw —
classification is a bonus on the cycle error, never its precondition.

`scc` is the cluster in `d.members` order and `placed` Kahn's partial schedule,
whose components are the acyclic prefix the out-of-cycle faces read from. The
whole body runs under one `try`: an `InternalInvariant` is a framework bug and
is rethrown, and everything else ships the cluster unclassified. An
`Undecidable` is not "everything else": it is the global tracer's own refusal,
and the member falls back to the sampled trace below.
"""
function _classify(d::AlgebraicCycle, scc::Vector{Int}, edges, placed::Vector{Int},
                   flat::Flat, tiers::Vector{Tier}, decls::Vector{Decls}, stage1::Vector,
                   published::Vector, mstores::Vector)
    T = Tracer{true}
    try
        # The acyclic prefix's probe products, at the nominal scalar: the same
        # chain `probe_stage2` runs, stopped where Kahn stopped.
        layout = cell_layout(flat, decls, Float64)
        wss = _workspaces(flat, tiers, Float64)
        products = NamedTuple[merge(s1, pub) for (s1, pub) in zip(stage1, published)]
        for ci in placed
            _probe_direct!(products, ci, flat, decls, tiers, stage1, published, layout,
                           wss, mstores, Float64)
        end

        inscc = Set(scc)
        faces = [Symbol[] for _ in scc]         # entering faces, in `decls` order
        ports = [Symbol[] for _ in scc]         # leaving ports, in `decls` order
        alive = [Set{Tuple{Symbol,Symbol}}() for _ in scc]
        modes = Symbol[]
        dead = Tuple{String,Symbol,Symbol}[]

        for (i, ci) in enumerate(scc)
            dc = decls[ci]
            fs = Symbol[f for f in keys(dc.ins)
                        if any(e -> e[3] === f && e[1] in inscc, edges[ci])]
            qs = Symbol[q for q in keys(dc.outs)
                        if any(cj -> any(e -> e[1] == ci && e[2] === q, edges[cj]), scc)]
            faces[i], ports[i] = fs, qs

            # A discrete member's pinned declarations admit no tracer scalar, and
            # neither does a continuous face or port declared with no walking leaf
            # (§5.6, D-245). Beyond 64 faces the bitmask runs out.
            dT = tiers[ci] === CONTINUOUS && length(fs) ≤ 64 ?
                 declarations(flat.comps[ci], CONTINUOUS, T) : nothing
            tf = dT === nothing ? falses(length(fs)) :
                 Bool[T in leaf_types(dT.ins[f]) for f in fs]
            tq = dT === nothing ? falses(length(qs)) :
                 Bool[T in leaf_types(dT.outs[q]) for q in qs]

            if !any(tf) || !any(tq)             # no traceable hop: structure alone
                push!(modes, :structural)
                for f in fs, q in qs
                    push!(alive[i], (f, q))
                end
                continue
            end
            # The global tracer is exact in one evaluation and refuses an
            # input-tainted branch; the local one then decides on its primal
            # over sampled states, missing only an untaken branch (§5.6, D-012).
            routes, mode = try
                _trace_direct(ci, dT, fs, tf, qs, flat, tiers, decls, stage1, mstores,
                              products, inscc, T), :global
            catch e
                e isa Undecidable || rethrow()
                _trace_sampled(ci, fs, tf, qs, flat, tiers, decls, stage1, mstores,
                               products, inscc), :sampled
            end
            push!(modes, mode)
            # An untraceable face or port leaves its hops alive; a traced hop the
            # map does not route is dead, and is listed under either verdict (D-245).
            for (a, f) in enumerate(fs), (b, q) in enumerate(qs)
                if !tf[a] || !tq[b] || !iszero(routes[q] & (UInt64(1) << (a - 1)))
                    push!(alive[i], (f, q))
                else
                    push!(dead, (d.members[i], f, q))
                end
            end
        end

        # The port graph: a node per cluster wire endpoint, every wire an edge,
        # a member's surviving hops the edges inside it. Real iff a cycle
        # survives it (D-245).
        node = Dict{Tuple{Int,Bool,Symbol},Int}()
        adj = Vector{Int}[]
        id!(k) = get!(node, k) do
            push!(adj, Int[])
            length(adj)
        end
        for i in eachindex(scc), f in faces[i], q in ports[i]
            (f, q) in alive[i] && push!(adj[id!((i, true, f))], id!((i, false, q)))
        end
        for (i, ci) in enumerate(scc), (pi, pport, face) in edges[ci]
            pi in inscc || continue
            j = findfirst(==(pi), scc)
            push!(adj[id!((j, false, pport))], id!((i, true, face)))
        end

        AlgebraicCycle(members = d.members, wires = d.wires,
                       classification = _has_cycle(adj) ? :real : :artificial,
                       dead = dead,
                       traced = [m => t for (m, t) in zip(d.members, modes)])
    catch e
        e isa InternalInvariant && rethrow()
        d
    end
end

"Depth-first search for a back edge: white/grey/black, recursive as Tarjan above."
function _has_cycle(adj::Vector{Vector{Int}})
    color = zeros(UInt8, length(adj))
    function grey!(v)
        color[v] = 0x1
        for w in adj[v]
            color[w] == 0x1 && return true
            color[w] == 0x0 && grey!(w) && return true
        end
        color[v] = 0x2
        false
    end
    any(v -> color[v] == 0x0 && grey!(v), eachindex(adj))
end
