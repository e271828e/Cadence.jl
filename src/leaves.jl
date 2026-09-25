# Leaf walk over the closed value vocabulary (spec §7.1): real scalars, static
# arrays, and isbits structs whose fields are drawn from the same vocabulary.
# A port value admits two more leaf kinds. An enum (§4.1, §8.2) is a primitive
# isbits type with no fields, one leaf of its own eltype, pinned. A concrete
# immutable type that is not isbits is one *opaque* leaf (§4.3, §4.4, D-237),
# stored whole with its references — the field handle. The walk never looks
# inside either.
#
# Shared by both candidates: the continuous state buffer is flat by decision
# (§7.1), so *some* flatten/reconstruct machinery is needed either way. C2 then
# reuses it for cells; C1 uses it only for state.

# D-237's opaque leaf: a concrete immutable type that is not isbits — a
# handle, a struct holding a `Ref` — stored whole. A `Symbol` is one by ruling
# (D-243): Julia classifies it mutable, but it is interned and never freed.
# Abstract types are not leaves and fall through to the struct walk as before;
# `String` is a mutable type to Julia and is refused as such.
_opaque(::Type{P}) where {P} =
    P === Symbol || (isconcretetype(P) && !isbitstype(P) && !ismutabletype(P))

# A type the walk stores whole, as one leaf of its own eltype: a real, an enum,
# an opaque leaf. Everything else is a static array or a struct it descends.
_atom(::Type{P}) where {P} = P <: Real || P <: Enum || _opaque(P)

"""
    nleaves(P)

Number of activation-scalar leaves a value of type `P` occupies in a flat
buffer. Layout-time only — never on an evaluation path.
"""
nleaves(::Type{<:Real}) = 1
nleaves(::Type{<:Enum}) = 1
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
leaf_types(::Type{P}) where {P<:Enum} = Type[P]
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

_leaf_names!(out, ::Type{P}, prefix) where {P<:Real} = (push!(out, prefix); out)
_leaf_names!(out, ::Type{P}, prefix) where {P<:Enum} = (push!(out, prefix); out)

function _leaf_names!(out, ::Type{P}, prefix) where {P<:StaticArray}
    for i in 1:length(P)
        _leaf_names!(out, eltype(P), string(prefix, "[", i, "]"))
    end
    out
end

function _leaf_names!(out, ::Type{P}, prefix) where {P}
    _opaque(P) && return (push!(out, prefix); out)
    for (name, field_type) in zip(fieldnames(P), fieldtypes(P))
        _leaf_names!(out, field_type,
                     isempty(prefix) ? string(name) : string(prefix, ".", name))
    end
    out
end

"""
    mutable_position(P)

The dotted name and type of the first mutable type the leaf walk over `P`
meets, or `nothing`. Layout-time only — `place!`'s refusal (D-237).
"""
mutable_position(::Type{P}) where {P} = _mutable_position(P, "")

function _mutable_position(::Type{P}, prefix) where {P}
    P <: Real && return nothing                  # `BigFloat` is a mutable `Real`, and a leaf
    P === Symbol && return nothing               # an opaque leaf by ruling (D-243)
    ismutabletype(P) && return (prefix, P)
    P <: StaticArray && return _mutable_position(eltype(P), string(prefix, "[1]"))
    _opaque(P) && return nothing                 # the walk never looks inside a handle
    for (name, field_type) in zip(fieldnames(P), fieldtypes(P))
        position = _mutable_position(
            field_type, isempty(prefix) ? string(name) : string(prefix, ".", name))
        position === nothing || return position
    end
    nothing
end

# --- expression builders (compile time) --------------------------------------

# Returns (expr, next_base): `expr` reconstructs a `P` from `buffer` starting at
# `offset + base + 1`, with all indices static relative to `offset`.
function _reconstruct_expr(::Type{P}, base::Int) where {P}
    if P <: StaticArray
        args = Expr[]
        next_base = base
        for _ in 1:length(P)
            child_expr, next_base = _reconstruct_expr(eltype(P), next_base)
            push!(args, child_expr)
        end
        return Expr(:call, P, args...), next_base
    elseif _atom(P)
        return :(@inbounds buffer[offset + $(base + 1)]), base + 1
    else
        args = Expr[]
        next_base = base
        for field_type in fieldtypes(P)
            child_expr, next_base = _reconstruct_expr(field_type, next_base)
            push!(args, child_expr)
        end
        # NamedTuples take their fields as one tuple; everything else positionally
        P <: NamedTuple && return Expr(:call, P, Expr(:tuple, args...)), next_base
        return Expr(:call, P, args...), next_base
    end
end

# Returns (block, next_base): statements storing the leaves of the value
# denoted by expression `value_expr` into `buffer` starting at `offset + base + 1`.
function _flatten_expr(::Type{P}, value_expr, base::Int) where {P}
    statements = Expr[]
    if P <: StaticArray
        next_base = base
        for i in 1:length(P)
            block, next_base = _flatten_expr(eltype(P), :(@inbounds $value_expr[$i]), next_base)
            push!(statements, block)
        end
        return Expr(:block, statements...), next_base
    elseif _atom(P)
        push!(statements, :(@inbounds buffer[offset + $(base + 1)] = $value_expr))
        return Expr(:block, statements...), base + 1
    else
        next_base = base
        for (i, field_type) in enumerate(fieldtypes(P))
            block, next_base = _flatten_expr(field_type, :(getfield($value_expr, $i)), next_base)
            push!(statements, block)
        end
        return Expr(:block, statements...), next_base
    end
end

# --- mixed-cell expression builders (compile time) ----------------------------
# The per-eltype generalization of the two builders above: a cell whose leaves
# span several eltypes lives split across the per-eltype buffers, so leaf i is
# drawn from the buffer bound as `buffer<k>` for its own eltype, at
# `offsets[k] + <static index>` — one running base per eltype, all indices static
# relative to the offsets. The homogeneous cell is the `K = 1` case, where
# these emit exactly the single-base expressions above.

function _mreconstruct_expr(::Type{P}, eltypes::Vector, bases::Vector{Int}) where {P}
    if P <: StaticArray
        args = [_mreconstruct_expr(eltype(P), eltypes, bases) for _ in 1:length(P)]
        return Expr(:call, P, args...)
    elseif _atom(P)
        eltype_index = findfirst(==(P), eltypes)
        bases[eltype_index] += 1
        return :(@inbounds $(Symbol(:buffer, eltype_index))[offsets[$eltype_index] +
                                                            $(bases[eltype_index])])
    else
        args = [_mreconstruct_expr(field_type, eltypes, bases) for field_type in fieldtypes(P)]
        P <: NamedTuple && return Expr(:call, P, Expr(:tuple, args...))
        return Expr(:call, P, args...)
    end
end

function _mflatten_expr(::Type{P}, value_expr, eltypes::Vector, bases::Vector{Int}) where {P}
    statements = Expr[]
    if P <: StaticArray
        for i in 1:length(P)
            push!(statements,
                  _mflatten_expr(eltype(P), :(@inbounds $value_expr[$i]), eltypes, bases))
        end
    elseif _atom(P)
        eltype_index = findfirst(==(P), eltypes)
        bases[eltype_index] += 1
        push!(statements, :(@inbounds $(Symbol(:buffer, eltype_index))[offsets[$eltype_index] +
                                                                       $(bases[eltype_index])] =
                                                                       $value_expr))
    else
        for (i, field_type) in enumerate(fieldtypes(P))
            push!(statements,
                  _mflatten_expr(field_type, :(getfield($value_expr, $i)), eltypes, bases))
        end
    end
    Expr(:block, statements...)
end

# --- evaluation-path entry points --------------------------------------------

"""
    reconstruct(P, buffer, offset)

Materialize a `P` from `nleaves(P)` consecutive entries of `buffer` starting at
`offset + 1`. Fully unrolled; register-level for isbits `P`.
"""
@generated function reconstruct(::Type{P}, buffer::AbstractVector, offset::Int) where {P}
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
# scalar; everything else (`Int`, `Bool`, sizes) is pinned and passes through,
# and so is a mutable type's parameters (D-263) and a whole entry wrapped in
# `Pinned`, which `retype_entry` strips at the top alone (D-265).

# The contract marker, documented with the declarations (`declare.jl`); defined
# here because the entry walk dispatches on it.
struct Pinned{P} end

_is_marker(::Type{P}) where {P} = P isa DataType && P.name === Base.typename(Pinned)

# The marker below the top of an entry, in a type parameter at any depth: the
# parameter-position pin D-263 rejected, refused as `IllegalPortType` (D-265).
# Read on the declaration as written, so a top `Pinned{Q}` is checked on `Q`.
_holds_marker(::Type{P}) where {P} =
    P isa DataType && any(p isa Type && (_is_marker(p) || _holds_marker(p)) for p in P.parameters)

"""
    retype(T, P)

`P` with every `Float64` position replaced by `T`; a position already at `T`
stays, so the walk is idempotent. A mutable type's parameters pin by rule
(D-263). The marker is not this walk's business: `retype_entry` strips it at
the top of an entry, and one below the top never reaches a walk (D-265).
Build time only.
"""
retype(::Type{T}, ::Type{Float64}) where {T} = T
function retype(::Type{T}, ::Type{P}) where {T,P}
    P === T && return P
    P isa DataType && !isempty(P.parameters) && !ismutabletype(P) || return P
    P.name.wrapper{(p isa Type ? retype(T, p) : p for p in P.parameters)...}
end

"""
    retype_entry(T, P)

A contract entry at `T`: a `Pinned{P}` at its top yields `P`, which is also
how the marker is stripped at nominal, and any other entry is `retype`
(D-263, D-265).
"""
retype_entry(::Type{T}, ::Type{Pinned{P}}) where {T,P} = P
retype_entry(::Type{T}, ::Type{P}) where {T,P} = retype(T, P)

"""
Value counterpart: the same value with its `Float64` leaves converted to `T`.
Every other leaf — a `Bool`, an `Int`, an enum, an opaque handle — is pinned
by the type walk above and passes through untouched.
"""
function retype_value(::Type{T}, value) where {T}
    retyped = retype(T, typeof(value))
    reconstruct(retyped, Any[l isa Float64 ? T(l) : l for l in _leaf_values(value)], 0)
end

_leaf_values(value::Real) = (value,)
_leaf_values(value::Enum) = (value,)
_leaf_values(value::StaticArray) = Iterators.flatten(map(_leaf_values, Tuple(value)))
# An opaque leaf is one value, not a field walk (D-237); the tuple arms agree.
_leaf_values(value::NamedTuple) = isbits(value) ? Iterators.flatten(map(_leaf_values,
    values(value))) : (value,)
_leaf_values(value::Tuple) = isbits(value) ? Iterators.flatten(map(_leaf_values, value)) : (value,)
_leaf_values(value) = isbits(value) ? Iterators.flatten(map(_leaf_values,
    ntuple(i -> getfield(value, i), fieldcount(typeof(value))))) : (value,)

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
# silent narrowing. An opaque leaf (D-237) is accepted by identity alone at a
# store: the cell holds it whole, so the lift never enters it, and a handle
# built from literals at a `Dual` activation is refused rather than converted.
# At a wire the entry is a bound and nothing is stored, so a frozen opaque
# arrival is admitted as the producer's cell (D-264).

"""
Is a value of type `V` a lawful arrival at a cell declared `P`, at activation
`T` (D-238)? Lift `V`'s `Float64` positions to `T` wherever `P` has `T`, and
ask whether the result is `P` itself. At a store an opaque leaf is identity
alone; `at_wire` lets the lift enter it (D-237, D-264).
"""
function _accepts(::Type{P}, ::Type{V}, ::Type{T}, at_wire::Bool = false) where {P,V,T}
    P === V && return true
    V === Float64 && P === T && return true          # the one embedding
    _opaque(P) && !at_wire && return false           # a store holds an opaque leaf whole (D-237)
    (P isa DataType && V isa DataType && P.name === V.name &&
     length(P.parameters) == length(V.parameters)) || return false
    all(declared isa Type && observed isa Type ? _accepts(declared, observed, T, at_wire) :
                                                 declared === observed
        for (declared, observed) in zip(P.parameters, V.parameters))
end

# The one honest cause of a `Dual` at a pinned leaf (§8.2, D-263).
_pin_hint(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T} =
    T === Float64 || P === T ? "" :
    " — if this leaf participates in differentiation, remove its `Pinned`"

"""
    _accepts_wire(P, V, T)

Is a producer declaring `V` a lawful feed for an entry declaring `P`, both
retyped at activation `T` (§6.1, D-236, D-263)? A concrete entry is `_accepts`,
decided on the type, with a frozen opaque arrival admitted as the producer's
cell (D-264). An abstract entry has no leaves to walk, so it is decided on
the whole declaration: `V` as declared, or `V` with every pinned leaf lifted
to `T`, must be `<:` `P`. The two candidates are exact whenever `P`'s
parameters are uniformly `T` or uniformly pinned; the mixed case is D-236's
recorded limit.
"""
_accepts_wire(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T} =
    isconcretetype(P) ? _accepts(P, V, T, true) : (V <: P || retype(T, V) <: P)

"""
    flatten!(buffer, offset, value)

Store the leaves of `value` into `buffer` starting at `offset + 1`. Returns `nothing`.
"""
@generated function flatten!(buffer::AbstractVector, offset::Int, value::P) where {P}
    block, _ = _flatten_expr(P, :value, 0)
    quote
        $(Expr(:meta, :inline))
        $block
        nothing
    end
end

"""
    flatten_state!(buffer, offset, value, XT, T, path, what, shape, event)

The wholesale state write with §9.5's always-on check decided at generation
(D-235): `value`'s key set must equal the state's, and each field must be a lawful
arrival at the state's field type under embed-accept. Fields pair by name,
never by position. `shape` is the diagnostic's shape: `:x_init` for a
derivative, `:state` for a projection or a handler's `x` key. `event` names the
event on a handler's write and is `nothing` everywhere else (D-249).
"""
@generated function flatten_state!(buffer::AbstractVector, offset::Int, value::NamedTuple{Vs},
                                   ::Type{XT}, ::Type{T}, path::String, what::Symbol,
                                   shape::Symbol,
                                   event::Union{Nothing,Symbol}) where {Vs,XT<:NamedTuple,T}
    state_fields = fieldnames(XT)
    Set(Vs) == Set(state_fields) ||
        return :(throw(DiagnosticError(ConformanceFailure(
            path = path, what = String(what), event = event, reason = :field_set, shape = shape,
            observed_fields = $(collect(Vs)),
            declared_fields = $(collect(state_fields))))))
    statements, base = Expr[], 0
    for field in state_fields
        declared, observed = fieldtype(XT, field), fieldtype(value, field)
        _accepts(declared, observed, T) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), event = event, reason = :field_type,
                shape = shape,
                field = $(QuoteNode(field)), observed = $observed, declared = $declared,
                activation = $T))))
        block, base = _flatten_expr(declared, :(getfield(value, $(QuoteNode(field)))), base)
        push!(statements, block)
    end
    quote
        $(Expr(:meta, :inline))
        $(statements...)
        nothing
    end
end

# A non-NamedTuple return is the law's first clause failing.
flatten_state!(buffer, offset, value, ::Type{XT}, ::Type{T}, path, what, shape,
               event) where {XT,T} =
    throw(DiagnosticError(ConformanceFailure(path = path, what = String(what), event = event,
                                             reason = :return_type, shape = shape,
                                             observed = typeof(value))))
