# Leaf walk over the closed value vocabulary (spec §7.1): real scalars, static
# arrays, and isbits structs whose fields are drawn from the same vocabulary.
# A port value admits a third leaf kind (§4.3, §4.4, D-237): a concrete
# immutable type that is not isbits is one *opaque* leaf, stored whole with its
# references — the field handle. The walk never looks inside one.
#
# Shared by both candidates: the continuous state buffer is flat by decision
# (§7.1), so *some* flatten/reconstruct machinery is needed either way. C2 then
# reuses it for cells; C1 uses it only for state.

# D-237's opaque leaf: a concrete immutable type that is not isbits — a
# handle, a `String`, a `Symbol` — stored whole. Abstract types are not
# leaves and fall through to the struct walk as before.
_opaque(::Type{P}) where {P} = isconcretetype(P) && !isbitstype(P) && !ismutabletype(P)

"""
    nleaves(P)

Number of activation-scalar leaves a value of type `P` occupies in a flat
buffer. Layout-time only — never on an evaluation path.
"""
nleaves(::Type{<:Real}) = 1
nleaves(::Type{P}) where {P<:StaticArray} = length(P) * nleaves(eltype(P))
nleaves(::Type{P}) where {P} = _opaque(P) ? 1 : sum(nleaves, fieldtypes(P); init = 0)

"""
    leaf_types(P)

The element type of each leaf a value of type `P` occupies, in flat order.
Layout-time only — the shape counterpart of `nleaves`, used to check a declared
cell against the store it has to live in. An opaque leaf is its own eltype: the
handle type itself, one entry (D-237).
"""
leaf_types(::Type{P}) where {P<:Real} = Type[P]
leaf_types(::Type{P}) where {P<:StaticArray} = repeat(leaf_types(eltype(P)), length(P))
leaf_types(::Type{P}) where {P} =
    _opaque(P) ? Type[P] :
    reduce(vcat, (leaf_types(FT) for FT in fieldtypes(P)); init = Type[])

"""
    leaf_eltypes(P)

The distinct leaf eltypes of `P`, in first-appearance order over the flat
walk — the one canonical order, shared by layout (which allocates one cursor
per entry) and by the store bundle's generated gather/scatter (which bind one
buffer per entry). `K = length(leaf_eltypes(P))` is a pure function of `P`.
"""
leaf_eltypes(::Type{P}) where {P} = unique(leaf_types(P))

"""
    leaf_names(P)

The dotted spelling of each leaf a value of type `P` occupies, in flat order:
`"q"`, `"v[2]"`, `"pose.x"`. The naming counterpart of `leaf_types`, walking
the same fields and static-array lengths. Cold path only — §13.4's nonfinite
sweep calls it once, at throw time, to name the offending state leaf.
"""
leaf_names(::Type{P}) where {P} = _leaf_names!(String[], P, "")

_leaf_names!(out, ::Type{P}, pre) where {P<:Real} = (push!(out, pre); out)

function _leaf_names!(out, ::Type{P}, pre) where {P<:StaticArray}
    for i in 1:length(P)
        _leaf_names!(out, eltype(P), string(pre, "[", i, "]"))
    end
    out
end

function _leaf_names!(out, ::Type{P}, pre) where {P}
    _opaque(P) && return (push!(out, pre); out)
    for (n, FT) in zip(fieldnames(P), fieldtypes(P))
        _leaf_names!(out, FT, isempty(pre) ? string(n) : string(pre, ".", n))
    end
    out
end

"""
    mutable_position(P)

The dotted name and type of the first mutable type the leaf walk over `P`
meets, or `nothing`. Layout-time only — `place!`'s refusal (D-237).
"""
mutable_position(::Type{P}) where {P} = _mutable_position(P, "")

function _mutable_position(::Type{P}, pre) where {P}
    P <: Real && return nothing                  # `BigFloat` is a mutable `Real`, and a leaf
    ismutabletype(P) && return (pre, P)
    P <: StaticArray && return _mutable_position(eltype(P), string(pre, "[1]"))
    _opaque(P) && return nothing                 # the walk never looks inside a handle
    for (n, FT) in zip(fieldnames(P), fieldtypes(P))
        r = _mutable_position(FT, isempty(pre) ? string(n) : string(pre, ".", n))
        r === nothing || return r
    end
    nothing
end

# --- expression builders (compile time) --------------------------------------

# Returns (expr, next_base): `expr` reconstructs a `P` from `buf` starting at
# `off + base + 1`, with all indices static relative to `off`.
function _reconstruct_expr(::Type{P}, base::Int) where {P}
    if P <: StaticArray
        args = Expr[]
        b = base
        for _ in 1:length(P)
            e, b = _reconstruct_expr(eltype(P), b)
            push!(args, e)
        end
        return Expr(:call, P, args...), b
    elseif P <: Real || _opaque(P)
        return :(@inbounds buf[off + $(base + 1)]), base + 1
    else
        args = Expr[]
        b = base
        for FT in fieldtypes(P)
            e, b = _reconstruct_expr(FT, b)
            push!(args, e)
        end
        # NamedTuples take their fields as one tuple; everything else positionally
        P <: NamedTuple && return Expr(:call, P, Expr(:tuple, args...)), b
        return Expr(:call, P, args...), b
    end
end

# Returns (block, next_base): statements storing the leaves of the value
# denoted by expression `v` into `buf` starting at `off + base + 1`.
function _flatten_expr(::Type{P}, v, base::Int) where {P}
    stmts = Expr[]
    if P <: StaticArray
        b = base
        for i in 1:length(P)
            blk, b = _flatten_expr(eltype(P), :(@inbounds $v[$i]), b)
            push!(stmts, blk)
        end
        return Expr(:block, stmts...), b
    elseif P <: Real || _opaque(P)
        push!(stmts, :(@inbounds buf[off + $(base + 1)] = $v))
        return Expr(:block, stmts...), base + 1
    else
        b = base
        for (i, FT) in enumerate(fieldtypes(P))
            blk, b = _flatten_expr(FT, :(getfield($v, $i)), b)
            push!(stmts, blk)
        end
        return Expr(:block, stmts...), b
    end
end

# --- mixed-cell expression builders (compile time) ----------------------------
# The per-eltype generalization of the two builders above: a cell whose leaves
# span several eltypes lives split across the per-eltype buffers, so leaf i is
# drawn from the buffer bound as `buf<k>` for its own eltype, at
# `offs[k] + <static index>` — one running base per eltype, all indices static
# relative to the offsets. The homogeneous cell is the `K = 1` case, where
# these emit exactly the single-base expressions above.

function _mreconstruct_expr(::Type{P}, Ls::Vector, bases::Vector{Int}) where {P}
    if P <: StaticArray
        args = [_mreconstruct_expr(eltype(P), Ls, bases) for _ in 1:length(P)]
        return Expr(:call, P, args...)
    elseif P <: Real || _opaque(P)
        k = findfirst(==(P), Ls)
        bases[k] += 1
        return :(@inbounds $(Symbol(:buf, k))[offs[$k] + $(bases[k])])
    else
        args = [_mreconstruct_expr(FT, Ls, bases) for FT in fieldtypes(P)]
        P <: NamedTuple && return Expr(:call, P, Expr(:tuple, args...))
        return Expr(:call, P, args...)
    end
end

function _mflatten_expr(::Type{P}, v, Ls::Vector, bases::Vector{Int}) where {P}
    stmts = Expr[]
    if P <: StaticArray
        for i in 1:length(P)
            push!(stmts, _mflatten_expr(eltype(P), :(@inbounds $v[$i]), Ls, bases))
        end
    elseif P <: Real || _opaque(P)
        k = findfirst(==(P), Ls)
        bases[k] += 1
        push!(stmts, :(@inbounds $(Symbol(:buf, k))[offs[$k] + $(bases[k])] = $v))
    else
        for (i, FT) in enumerate(fieldtypes(P))
            push!(stmts, _mflatten_expr(FT, :(getfield($v, $i)), Ls, bases))
        end
    end
    Expr(:block, stmts...)
end

# --- evaluation-path entry points --------------------------------------------

"""
    reconstruct(P, buf, off)

Materialize a `P` from `nleaves(P)` consecutive entries of `buf` starting at
`off + 1`. Fully unrolled; register-level for isbits `P`.
"""
@generated function reconstruct(::Type{P}, buf::AbstractVector, off::Int) where {P}
    expr, _ = _reconstruct_expr(P, 0)
    quote
        $(Expr(:meta, :inline))
        $expr
    end
end

# --- the activation walk (§7.2) ----------------------------------------------
# Declarations are written at concrete `Float64`; cell and view types per
# activation come from this walk over them, never from inference through user
# code. `Float64` leaves and `Float64` type parameters follow the activation
# scalar; everything else (`Int`, `Bool`, sizes) is pinned and passes through.

"""
    retype(T, P)

`P` with every `Float64` position replaced by `T`; a position already at `T`
stays, so the walk is idempotent. Build time only.
"""
retype(::Type{T}, ::Type{Float64}) where {T} = T
function retype(::Type{T}, ::Type{P}) where {T,P}
    P === T && return P
    P isa DataType && !isempty(P.parameters) || return P
    P.name.wrapper{(p isa Type ? retype(T, p) : p for p in P.parameters)...}
end

"""Value counterpart: the same value with its leaves converted to `T`."""
function retype_value(::Type{T}, v) where {T}
    P = retype(T, typeof(v))
    reconstruct(P, T[T(l) for l in _leaf_values(v)], 0)
end

_leaf_values(v::Real) = (v,)
_leaf_values(v::StaticArray) = Iterators.flatten(map(_leaf_values, Tuple(v)))
_leaf_values(v::NamedTuple) = Iterators.flatten(map(_leaf_values, values(v)))
_leaf_values(v::Tuple) = Iterators.flatten(map(_leaf_values, v))
# An opaque leaf is one value, not a field walk (D-237).
_leaf_values(v) = isbits(v) ? Iterators.flatten(map(_leaf_values,
    ntuple(i -> getfield(v, i), fieldcount(typeof(v))))) : (v,)

# --- embed-accept (D-166, decided on the type per D-238) ----------------------
# The relation is decided on the type, not leaf by leaf: `V` is accepted at `P`
# when lifting `V`'s `Float64` positions to `T` exactly where `P` has `T` yields
# `P` itself, compared by identity. Deciding it walks the two parameter lists in
# parallel and constructs no type, so a field name, a non-numeric parameter and
# an array's mutability are refused like any other mismatch; a parameterless
# type compares by identity. A `Float64` lifts to `T` where `P` has `T` and
# nowhere else — **embedded as a zero-partial**, which is what keeps the
# constant-branch idiom (`flow > 0 ? f(x) : 0.0`) legal as written at a `Dual`
# activation. A deliberately pinned `Float64`, an `Int`, a `Bool` lift nowhere,
# so an observed `Dual` at a pinned leaf is an error with a hint rather than a
# silent narrowing.

"""
Is a value of type `V` a lawful arrival at a cell declared `P`, at activation
`T` (D-238)? Lift `V`'s `Float64` positions to `T` wherever `P` has `T`, and
ask whether the result is `P` itself.
"""
function _accepts(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T}
    P === V && return true
    V === Float64 && P === T && return true          # the one embedding
    (P isa DataType && V isa DataType && P.name === V.name &&
     length(P.parameters) == length(V.parameters)) || return false
    all(p isa Type && v isa Type ? _accepts(p, v, T) : p === v
        for (p, v) in zip(P.parameters, V.parameters))
end

# The one honest cause of a `Dual` at a leaf declared `Float64`, per D-166.
_pin_hint(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T} =
    T === Float64 || P === T ? "" :
    " — if this leaf participates in differentiation, declare it `T`"

"""
    _accepts_wire(P, V, T)

Is a producer declaring `V` a lawful feed for an entry declaring `P`, both
evaluated at activation `T` (§6.1, D-236)? A concrete entry is `_accepts`,
decided on the type. An abstract entry has no leaves to walk, so it is decided
on the whole declaration: `V` as declared, or `V` with every pinned leaf lifted
to `T`, must be `<:` `P`. The two candidates are exact whenever `P`'s
parameters are uniformly `T` or uniformly pinned; the mixed case is D-236's
recorded limit.
"""
_accepts_wire(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T} =
    isconcretetype(P) ? _accepts(P, V, T) : (V <: P || retype(T, V) <: P)

"""
    flatten!(buf, off, v)

Store the leaves of `v` into `buf` starting at `off + 1`. Returns `nothing`.
"""
@generated function flatten!(buf::AbstractVector, off::Int, v::P) where {P}
    block, _ = _flatten_expr(P, :v, 0)
    quote
        $(Expr(:meta, :inline))
        $block
        nothing
    end
end

"""
    flatten_state!(buf, off, v, XT, T, path, what, shape)

The wholesale state write with §9.5's always-on check decided at generation
(D-235): `v`'s key set must equal the state's, and each field must be a lawful
arrival at the state's field type under embed-accept. Fields pair by name,
never by position. `shape` is the diagnostic's shape: `:init_x` for a
derivative, `:state` for a projection or a handler's `x` key.
"""
@generated function flatten_state!(buf::AbstractVector, off::Int, v::NamedTuple{Vs},
                                   ::Type{XT}, ::Type{T}, path::String, what::Symbol,
                                   shape::Symbol) where {Vs,XT<:NamedTuple,T}
    Xs = fieldnames(XT)
    Set(Vs) == Set(Xs) ||
        return :(throw(DiagnosticError(ConformanceFailure(
            path = path, what = String(what), reason = :field_set, shape = shape,
            observed_fields = $(collect(Vs)), declared_fields = $(collect(Xs))))))
    stmts, base = Expr[], 0
    for k in Xs
        P, V = fieldtype(XT, k), fieldtype(v, k)
        _accepts(P, V, T) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), reason = :field_type, shape = shape,
                field = $(QuoteNode(k)), observed = $V, declared = $P, activation = $T))))
        blk, base = _flatten_expr(P, :(getfield(v, $(QuoteNode(k)))), base)
        push!(stmts, blk)
    end
    quote
        $(Expr(:meta, :inline))
        $(stmts...)
        nothing
    end
end

# A non-NamedTuple return is the law's first clause failing.
flatten_state!(buf, off, v, ::Type{XT}, ::Type{T}, path, what, shape) where {XT,T} =
    throw(DiagnosticError(ConformanceFailure(path = path, what = String(what),
                                             reason = :return_type, shape = shape,
                                             observed = typeof(v))))
