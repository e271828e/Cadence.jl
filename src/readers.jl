# The read-selector family and the compiled reader (§14.4, §14.7): the closed
# set of deferred reads every reader of the model addresses through, the
# declared read set they are labeled in, and the compiled gather that runs one
# such set against an executor.
#
# The reader is `apply!`'s **gather twin** (§14.4): one primitive family run in
# both directions over the same layout tables. What the condition algebra
# resolves to a plan of baked destinations, a read set resolves to a tuple of
# baked sources — the same resolve-once/execute-many shape, the same §13.1
# collecting form on the way in, and the same rule that all string work is
# a function of the *shape* and none of it survives into the read.
#
# This file sits above the data plane because the selectors are its vocabulary
# too: an output binding's `reads` (§11.2, bindings.jl) names the three table
# members of the family declared here. What it needs from the condition algebra
# — the `x`-offset walk and the "is this path a level of the build at all"
# predicate — it calls at resolution time, which is long after conditions.jl
# has been read.

# --- the selector family (§14.4), closed --------------------------------------

"""
§14.4's read-selector family, closed: `get_state(path, field[, i])`,
`get_deriv(path, field[, i])`, `get_output(path, field[, i])`,
`get_input(face)` and `get_face(name)` — one address space for every reader of
the model.

The names carry a deliberate `get_` prefix. A selector is a *deferred read*: a
value describing the read the compiled gather will perform, inert until it is
resolved against a source. The prefix names that action, and it keeps five
short common nouns out of the namespace user declarations share with domain
code.

The family splits by **source**, not by client (§14.4's source rule). The
store selectors `get_state`/`get_deriv` resolve only against live stores, which
here means an `Executor` — the only live-store holder there is; the
table selectors `get_output`/`get_input`/`get_face` resolve against a table
source, an executor's own signal table or a published snapshot. A
snapshot-bound reader naming a store selector is therefore refused at attach
(`ReadBindingUnresolved`, bindings.jl), by source rather than by client.

`get_output` is an *inspection read* — a component's own declared output
port, addressed by path — and `get_face` an *integration read*: a
root-exported output face, named, curated, meaning-stable under substitution
(§11.2). `get_input` reads a root input back, the source cell it is. Only cells
and stores are addressable: there is no selector for a value a component
computes without declaring it, and the remedy is the same in every case —
the component exports it (§5.2, §8.3).

`i` is the optional component index (§14.10): the read is `v[i]`, so a vector
leaf yields named scalars. Absent, the whole value is read.
"""
struct GetState
    path::String
    field::Symbol
    i::Union{Nothing,Int}
end

struct GetDeriv
    path::String
    field::Symbol
    i::Union{Nothing,Int}
end

struct GetOutput
    path::String
    name::Symbol
    i::Union{Nothing,Int}
end

struct GetInput
    face::Symbol
end

struct GetFace
    name::Symbol
end

const ReadSelector = Union{GetState,GetDeriv,GetOutput,GetInput,GetFace}
const StoreSelector = Union{GetState,GetDeriv}

_index_arg(::Nothing) = nothing
_index_arg(index::Integer) = Int(index)
_index_arg(index) = throw(DiagnosticError(
    ArgumentInvalid(call = :selector, reason = :index_not_integer, value = index)))

get_state(path::AbstractString, field::Union{Symbol,AbstractString}, i = nothing) =
    GetState(String(path), Symbol(field), _index_arg(i))
get_deriv(path::AbstractString, field::Union{Symbol,AbstractString}, i = nothing) =
    GetDeriv(String(path), Symbol(field), _index_arg(i))
get_output(path::AbstractString, name::Union{Symbol,AbstractString}, i = nothing) =
    GetOutput(String(path), Symbol(name), _index_arg(i))
get_input(face::Union{Symbol,AbstractString}) = GetInput(Symbol(face))
get_face(name::Union{Symbol,AbstractString}) = GetFace(Symbol(name))

# The selector as authored, for the diagnostics: a refusal names the read the
# way its author wrote it, which is what makes a collected list readable.
_ipart(index) = index === nothing ? "" : ", $index"
_spell(selector::GetState) =
    "get_state(\"$(selector.path)\", :$(selector.field)$(_ipart(selector.i)))"
_spell(selector::GetDeriv) =
    "get_deriv(\"$(selector.path)\", :$(selector.field)$(_ipart(selector.i)))"
_spell(selector::GetOutput) =
    "get_output(\"$(selector.path)\", :$(selector.name)$(_ipart(selector.i)))"
_spell(selector::GetInput) = "get_input(:$(selector.face))"
_spell(selector::GetFace) = "get_face(:$(selector.name))"

# --- the declared read set (§14.7) ---------------------------------------------

"""
The declared read set (§14.7): the labeled selectors in one type, so that a
bare NamedTuple of selectors reaching a service is refused with a directive
rather than a `MethodError`, exactly as `combine` refuses one in the condition
algebra (§14.2).
"""
struct Reads{NT<:NamedTuple}
    sels::NT
end

"""
    reads(; label = selector, …)

The read set a service declares: the labels are the names the gathered
NamedTuple carries, and the names a trim problem's residual function
destructures (§14.7). Order is the declared side's own, as everywhere at an
author↔framework NamedTuple seam (§9.5).
"""
reads(; selectors...) = _reads(NamedTuple(selectors))

function _reads(selectors::NamedTuple)
    for (label, selector) in pairs(selectors)
        selector isa ReadSelector || throw(DiagnosticError(ReadSetMisuse(
            observed = typeof(selector), reason = :not_a_selector, label = label,
            in_hand = Symbol[nameof(typeof(v)) for v in values(selectors)
                             if v isa ReadSelector])))
    end
    Reads(selectors)
end

# --- the compiled reader (§14.4) ------------------------------------------------
# One entry per selector, its leaf type and its index in the entry's *type*, so
# the gather is a tuple walk the compiler unrolls: no dictionary, no address
# arithmetic and no branch survives resolution. The four entry kinds are the
# four homes a read can come from — the flat state buffer, the derivative
# buffer beside it, a discrete component's own store, and the signal table.

struct StateRead{P,I}
    off::Int
    i::I
end

struct DerivRead{P,I}
    off::Int
    i::I
end

struct StoreRead{S,F,I}
    ci::Int
    i::I
end

struct CellRead{A,I}
    addr::A
    i::I
end

_take(value, ::Nothing) = value
_take(value, index::Int) = value[index]

@inline _read(entry::StateRead{P}, exec::Executor) where {P} =
    _take(reconstruct(P, exec.xbuf, entry.off), entry.i)
@inline _read(entry::DerivRead{P}, exec::Executor) where {P} =
    _take(reconstruct(P, exec.ẋbuf, entry.off), entry.i)
# The `s` stores are held by component index in a `Vector{Any}` — one store
# type per component type, not per model — so the baked store type is what
# keeps the read inferable. The assertion goes on the *reference*: asserting
# the dereferenced value instead leaves the `[]` a dynamic call, which boxes.
@inline _read(entry::StoreRead{S,F}, exec::Executor) where {S,F} =
    _take(getfield((exec.sstores[entry.ci]::Base.RefValue{S})[], F), entry.i)
@inline _read(entry::CellRead, exec::Executor) =
    _take(gather(exec.store, entry.addr), entry.i)

"""
One compiled read set (§14.4): the labels as a type parameter, the resolved
entries as a tuple carrying their leaf types. `gather(reader, executor)` is the
gather twin of `apply!` — a stack-only NamedTuple per evaluation, type-stable
and allocation-free for scalar and `SVector` leaves, which is what lets a
service's per-iteration read cost nothing beyond the sweep it follows.

A reader is compiled at one activation and resolves against an executor at that
activation: store selectors reach live stores (§14.4's source rule), and the
executor is the only live-store holder here. That activation is `T`, the first
type parameter — the entries bake offsets, store types and cell addresses that
are one activation's, so the pairing is dispatch and a mismatch is the
internal-invariant refusal build.jl raises (§14.4) rather than a silent read of
another cell's slot.
"""
struct Reader{T,L,E<:Tuple}
    entries::E
end

Reader{T,L}(entries::E) where {T,L,E<:Tuple} = Reader{T,L,E}(entries)

@inline gather(reader::Reader{T,L}, exec::Executor{T}) where {T,L} =
    NamedTuple{L}(map(e -> _read(e, exec), reader.entries))

gather(::Reader{T}, ::Executor{S}) where {T,S} = _activation_mismatch("reader", T, S)

# --- resolution (§14.4, §13.1) --------------------------------------------------

"""
    _compile_reads(read_set::Reads, build::Build, T = Float64) → Reader

Resolve a declared read set against a build and compile it, validating every
selector in §13.1's collecting form — full list, violations collected, one
`DiagnosticError`. Schema is the authority on *may you read this, at what type*, and
the activation's layout supplies the source: an `xbuf` offset for a continuous
state field, the `ẋbuf` offset beside it for its derivative, a component index
for a discrete `s`, a cell address for a port, a root input or a root-exported
face.

The standalone entry point is internal, because a read set is only ever
compiled inside a client: `trim!` splices the collected list into its own throw
beside the problem's `TrimProblemInvalid` values (§14.8), and a device binding
raises `ReadBindingUnresolved` at attach instead (§11.2). That is why the
collecting pass is factored apart from the throw. The violations are
`TapResolution` values either way — the kind is the read's own, and it is the
*site* that decides where they surface (§13.2, Appendix C).
"""
function _compile_reads(read_set::Reads, build::Build, ::Type{T} = Float64) where {T}
    reader, diags = _resolve_reads(read_set, build, T)
    isempty(diags) || throw(DiagnosticError(diags))
    reader
end

# A bare NamedTuple of selectors is the §14.2 misuse in the read side: the
# same slip, the same directive, and not a `MethodError`.
_compile_reads(other, ::Build, ::Type = Float64) = throw(DiagnosticError(
    ReadSetMisuse(observed = typeof(other), reason = :not_a_read_set)))

"""
The collecting half of `_compile_reads`, shared with the services that own their
own setup diagnostic (§14.8): returns the compiled reader and the violation
list, the reader being `nothing` when anything failed.
"""
function _resolve_reads(read_set::Reads, build::Build, ::Type{T}) where {T}
    act = activation(build, T)
    diags = Diagnostic[]
    entries = Any[]
    for (label, selector) in pairs(read_set.sels)
        entry = _resolve_selector(selector, label, build, act, diags)
        entry === nothing || push!(entries, entry)
    end
    (isempty(diags) ? Reader{T,keys(read_set.sels)}(Tuple(entries)) : nothing, diags)
end

# The component a path-addressed selector names. No mounting exists, so every
# selector path is authored at the root and walked from it in full (§13.3): the
# walk owns the unknown-segment refusal and its candidates, and the past-generic
# one with them. What stays here is `_component`'s residue, one case over —
# a level the walk admitted that owns no state of its own.
function _read_component(selector, label::Symbol, structure::Structure,
                         diags::Vector{Diagnostic})
    description = "the read labeled `$label`, $(_spell(selector))"
    resolve_authored(description, "", structure.root, selector.path, diags) === nothing &&
        return nothing
    ci = findfirst(component -> component.path == selector.path, structure.components)
    ci === nothing || return ci
    push!(diags, _rviol(label, selector, :assembly_path))
    nothing
end

# One `TapResolution` off a selector: the label and the selector as authored are
# what makes a collected list readable, and the tap set, path and index come off
# the selector's own kind (§14.10's payload); each arm adds what it observed.
_rviol(label::Symbol, selector, reason::Symbol; kw...) =
    TapResolution(; label = label, selector = _spell(selector), reason = reason,
                  tap = _tap(selector), path = _selpath(selector),
                  index = _selindex(selector), kw...)

_tap(::Union{GetState,GetDeriv}) = :x
_tap(::Union{GetOutput,GetFace}) = :y
_tap(::GetInput) = :u

_selpath(selector::Union{GetState,GetDeriv,GetOutput}) = selector.path
_selpath(::Union{GetInput,GetFace}) = ""
_selindex(selector::Union{GetState,GetDeriv,GetOutput}) = selector.i
_selindex(::Union{GetInput,GetFace}) = nothing

# `i` is checked against the resolved leaf's declared type in exactly one
# respect: `getindex` has to mean something there. A scalar leaf is refused;
# nothing further is checked, the index being the author's own coordinate
# choice over a value whose length the schema does not fix everywhere.
function _check_index(selector, label::Symbol, ::Type{P},
                      diags::Vector{Diagnostic}) where {P}
    (selector.i === nothing || !(P <: Real)) && return true
    push!(diags, _rviol(label, selector, :scalar_index; declared = P))
    false
end

_undeclared_violation(label::Symbol, selector, declares::Symbol, declared::NamedTuple) =
    _rviol(label, selector, :undeclared; declares = declares, field = _field(selector),
           candidates = collect(keys(declared)))

# The port list in hand is the `Outputs`' row concatenated by `_ports`, a fresh
# vector the payload is free to hold (D-253).
_undeclared_violation(label::Symbol, selector, declares::Symbol, declared::Vector{Symbol}) =
    _rviol(label, selector, :undeclared; declares = declares, field = _field(selector),
           candidates = declared)

_field(selector::Union{GetState,GetDeriv}) = selector.field
_field(selector::GetOutput) = selector.name

function _resolve_selector(selector::GetState, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    ci = _read_component(selector, label, build.structure, diags)
    ci === nothing && return nothing
    decl, tier = act.decls[ci], build.structure.components[ci].tier
    declared = state_decls(decl, tier)
    haskey(declared, selector.field) ||
        (push!(diags, _undeclared_violation(label, selector, :state_field, declared));
         return nothing)
    field_type = typeof(declared[selector.field])
    _check_index(selector, label, field_type, diags) || return nothing
    tier === CONTINUOUS ?
        StateRead{field_type,typeof(selector.i)}(
            first(act.layout.xblocks[ci]) - 1 + _leaf_offset(decl.x, selector.field), selector.i) :
        StoreRead{typeof(decl.s),selector.field,typeof(selector.i)}(ci, selector.i)
end

function _resolve_selector(selector::GetDeriv, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    ci = _read_component(selector, label, build.structure, diags)
    ci === nothing && return nothing
    decl, tier = act.decls[ci], build.structure.components[ci].tier
    if tier !== CONTINUOUS
        push!(diags, _rviol(label, selector, :discrete_deriv; field = selector.field))
        return nothing
    end
    haskey(decl.x, selector.field) ||
        (push!(diags, _undeclared_violation(label, selector, :state_field, decl.x));
         return nothing)
    field_type = typeof(decl.x[selector.field])
    _check_index(selector, label, field_type, diags) || return nothing
    # `ẋ` has `x`'s shape at the activation scalar (§7.1), so the derivative of
    # a state field sits at the state field's own offset in the other buffer.
    DerivRead{field_type,typeof(selector.i)}(
        first(act.layout.xblocks[ci]) - 1 + _leaf_offset(decl.x, selector.field),
        selector.i)
end

function _resolve_selector(selector::GetOutput, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    ci = _read_component(selector, label, build.structure, diags)
    ci === nothing && return nothing
    decl = act.decls[ci]
    ports = _ports(build.outputs.components[ci])
    selector.name in ports ||
        (push!(diags, _undeclared_violation(label, selector, :output_port, ports));
         return nothing)
    # The port's *type* is the activation's, a type being no name list (D-253).
    _check_index(selector, label, decl.outs[selector.name], diags) || return nothing
    addr = act.layout.addr[(selector.path, selector.name)]
    CellRead{typeof(addr),typeof(selector.i)}(addr, selector.i)
end

function _resolve_selector(selector::GetInput, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    if !(selector.face in build.structure.root_inputs)
        push!(diags, _rviol(label, selector, :unknown_root_input; field = selector.face,
                           candidates = build.structure.root_inputs))
        return nothing
    end
    addr = act.layout.addr[("", selector.face)]
    CellRead{typeof(addr),Nothing}(addr, nothing)
end

function _resolve_selector(selector::GetFace, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    exported = Symbol[face for ((face_path, face), _) in build.structure.out_faces
                      if isempty(face_path)]
    if !(selector.name in exported)
        push!(diags, selector.name in build.structure.root_inputs ?
                    _rviol(label, selector, :root_input_not_face; field = selector.name) :
                    _rviol(label, selector, :unknown_output_face; field = selector.name,
                           candidates = exported))
        return nothing
    end
    addr = act.layout.addr[("", selector.name)]
    CellRead{typeof(addr),Nothing}(addr, nothing)
end
