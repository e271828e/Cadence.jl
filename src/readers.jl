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
# members of the family declared here. Every member takes a leaf address
# (§14.4, D-276): a linearization tap on a vector leaf needs it (linearize.jl),
# and a binding read takes it as every reader does. What it needs from the
# condition algebra — the `x`-offset walk and the "is this path a level of the
# build at all" predicate — it calls at resolution time, which is long after
# conditions.jl has been read.

# --- the selector family (§14.4), closed --------------------------------------

"""
§14.4's read-selector family, closed: `get_state(path, leaf)`,
`get_deriv(path, leaf)`, `get_output(path, leaf)`, `get_input(leaf)` and
`get_face(leaf)` — one address space for every reader of the model.

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

`leaf` is a leaf address (§14.4, D-276): the field or face name, then `.name`
and `[k]` or `[k,l]` steps in any order, `"pose.q_eb[2]"`. A bare `Symbol` is
the short form of a plain name. The address is kept as authored and parsed at
resolution, where each step is checked against the declared type.
"""
struct GetState
    path::String
    leaf::Union{Symbol,String}
end

struct GetDeriv
    path::String
    leaf::Union{Symbol,String}
end

struct GetOutput
    path::String
    leaf::Union{Symbol,String}
end

struct GetInput
    leaf::Union{Symbol,String}
end

struct GetFace
    leaf::Union{Symbol,String}
end

const ReadSelector = Union{GetState,GetDeriv,GetOutput,GetInput,GetFace}
const StoreSelector = Union{GetState,GetDeriv}

_authored_leaf(leaf::Symbol) = leaf
_authored_leaf(leaf::AbstractString) = String(leaf)

get_state(path::AbstractString, leaf::Union{Symbol,AbstractString}) =
    GetState(String(path), _authored_leaf(leaf))
get_deriv(path::AbstractString, leaf::Union{Symbol,AbstractString}) =
    GetDeriv(String(path), _authored_leaf(leaf))
get_output(path::AbstractString, leaf::Union{Symbol,AbstractString}) =
    GetOutput(String(path), _authored_leaf(leaf))
get_input(leaf::Union{Symbol,AbstractString}) = GetInput(_authored_leaf(leaf))
get_face(leaf::Union{Symbol,AbstractString}) = GetFace(_authored_leaf(leaf))

# The selector as authored, for the diagnostics: a refusal names the read the
# way its author wrote it, which is what makes a collected list readable. A
# `Symbol` leaf prints as `:θ`, a string one in quotes.
_spell(selector::GetState) = "get_state(\"$(selector.path)\", $(repr(selector.leaf)))"
_spell(selector::GetDeriv) = "get_deriv(\"$(selector.path)\", $(repr(selector.leaf)))"
_spell(selector::GetOutput) = "get_output(\"$(selector.path)\", $(repr(selector.leaf)))"
_spell(selector::GetInput) = "get_input($(repr(selector.leaf)))"
_spell(selector::GetFace) = "get_face($(repr(selector.leaf)))"

# The address as authored, without the quotes: the payloads' `leaf`.
_leaf_string(selector) = String(selector.leaf)

# --- the leaf address (§14.4, D-276) --------------------------------------------
# Parsed and resolved once, in the collecting form; nothing here runs per read.
# A step is a `Symbol` for `.name` and an `Int` tuple for `[k]` or `[k,l]`, so a
# resolved chain of steps is a legal type parameter.

const LeafStep = Union{Symbol,Tuple{Vararg{Int}}}

"""
One step a leaf address cannot take (§14.4, D-276): the reason, the step as
spelled (`".q"`, `"[2,3]"`), the type in hand at that step, and the field
names in hand where a `.name` step missed. Not a diagnostic: each caller wraps
it in its own kind.
"""
struct LeafRefusal
    reason::Symbol   # :leaf_syntax|:no_such_field|:opaque_leaf|:not_indexable|
                     # :index_arity|:index_bounds
    step::String
    declared::Any
    candidates::Vector{Symbol}
end

LeafRefusal(reason::Symbol, step::AbstractString, declared = nothing) =
    LeafRefusal(reason, String(step), declared, Symbol[])

_step_string(name::Symbol) = ".$name"
_step_string(index::Tuple{Vararg{Int}}) = "[" * join(index, ",") * "]"

# Where a name run starting at `start` ends: the first `.` or `[`, or past the end.
_name_end(leaf::String, start::Int) =
    something(findnext(c -> c == '.' || c == '[', leaf, start), ncodeunits(leaf) + 1)

"""
    parse_leaf(leaf) → (head, steps) | LeafRefusal

Split a leaf address into its head name and its steps, `"pose.q_eb[2,3]"` into
`(:pose, [:q_eb, (2, 3)])`. A `Symbol` is its string. A name is a Julia
identifier; an index step is one or more decimal integers of at least one,
separated by `,`. Anything else is `:leaf_syntax` with the fragment it stopped
at.
"""
parse_leaf(leaf::Symbol) = parse_leaf(String(leaf))

function parse_leaf(leaf::String)
    stop = _name_end(leaf, 1)
    head = leaf[1:prevind(leaf, stop)]
    Base.isidentifier(head) || return LeafRefusal(:leaf_syntax,
        isempty(head) ? leaf[1:min(stop, ncodeunits(leaf))] : head)
    steps = parse_steps(leaf, stop)
    steps isa LeafRefusal ? steps : (Symbol(head), steps)
end

# The steps from `start` to the end of the address, as `parse_leaf` reads them
# after the head, or the refusal of the first that does not parse.
function parse_steps(leaf::String, start::Int)
    steps = LeafStep[]
    while start <= ncodeunits(leaf)
        if leaf[start] == '.'
            stop = _name_end(leaf, start + 1)
            name = leaf[start+1:prevind(leaf, stop)]
            Base.isidentifier(name) ||
                return LeafRefusal(:leaf_syntax, leaf[start:prevind(leaf, stop)])
            push!(steps, Symbol(name))
        elseif leaf[start] == '['
            closing = findnext(==(']'), leaf, start)
            closing === nothing && return LeafRefusal(:leaf_syntax, leaf[start:end])
            index = map(split(leaf[start+1:prevind(leaf, closing)], ',')) do digits
                all(isdigit, digits) ? something(tryparse(Int, digits), 0) : 0
            end
            all(≥(1), index) || return LeafRefusal(:leaf_syntax, leaf[start:closing])
            push!(steps, Tuple(index))
            stop = closing + 1
        else
            return LeafRefusal(:leaf_syntax,
                               leaf[start:prevind(leaf, _name_end(leaf, start))])
        end
        start = stop
    end
    steps
end

"""
    match_leaf(leaf, faces) → (head, steps) | LeafRefusal | nothing

Match a face selector's address against the faces it may name (§14.4, D-276). A
face name is an arbitrary string and may hold a dot (§8.6), so the head is not
parsed: it is the longest name in `faces` the address starts with, followed by
the end, a `.` or a `[`, and the steps after it parse as `parse_leaf`'s. A
`Symbol` names a face whole, with no steps. `nothing` where no face matches.
"""
function match_leaf(leaf::Union{Symbol,String}, faces)
    head = match_face(leaf, faces)
    head === nothing && return nothing
    leaf isa Symbol && return (head, LeafStep[])
    steps = parse_steps(leaf, ncodeunits(String(head)) + 1)
    steps isa LeafRefusal ? steps : (head, steps)
end

# The face `match_leaf` takes for the head, or `nothing`.
match_face(leaf::Symbol, faces) = leaf in faces ? leaf : nothing
function match_face(leaf::String, faces)
    matched = ""
    for face in faces
        name = String(face)
        stop = ncodeunits(name) + 1
        ncodeunits(name) > ncodeunits(matched) && startswith(leaf, name) &&
            (stop > ncodeunits(leaf) || leaf[stop] in ('.', '[')) && (matched = name)
    end
    isempty(matched) ? nothing : Symbol(matched)
end

"""
    resolve_leaf(P, steps) → (chain, leaf_type) | LeafRefusal

Walk the declared type `P` through the steps (§14.4, D-276). A `.name` step
needs an isbits struct with that field and never enters an opaque leaf; an
index step needs a static array, one index or one per dimension, within its
size. The chain is the steps as a tuple, the baked read's type parameter;
nothing is checked against a value.
"""
function resolve_leaf(::Type{P}, steps) where {P}
    in_hand = P
    for step in steps
        if step isa Symbol
            if in_hand <: Union{Real,Enum,StaticArray} || !(in_hand isa DataType) ||
               isabstracttype(in_hand)
                return LeafRefusal(:no_such_field, _step_string(step), in_hand)
            end
            _opaque(in_hand) && return LeafRefusal(:opaque_leaf, _step_string(step), in_hand)
            field_names = Symbol[name for name in fieldnames(in_hand) if name isa Symbol]
            step in field_names ||
                return LeafRefusal(:no_such_field, _step_string(step), in_hand, field_names)
            in_hand = fieldtype(in_hand, step)
        else
            in_hand <: StaticArray ||
                return LeafRefusal(:not_indexable, _step_string(step), in_hand)
            length(step) == 1 || length(step) == ndims(in_hand) ||
                return LeafRefusal(:index_arity, _step_string(step), in_hand)
            checkbounds(Bool, LinearIndices(size(in_hand)), step...) ||
                return LeafRefusal(:index_bounds, _step_string(step), in_hand)
            in_hand = eltype(in_hand)
        end
    end
    (Tuple(steps), in_hand)
end

"""
    walk_leaf(value, Val(chain))

Run a resolved chain on a value: a `Symbol` step is `getfield`, an index step
`getindex`, unrolled at generation so the read carries no loop and no branch.
The empty chain is the value itself.
"""
@generated function walk_leaf(value, ::Val{C}) where {C}
    expr = :value
    for step in C
        expr = step isa Symbol ? :(getfield($expr, $(QuoteNode(step)))) :
                                 :(getindex($expr, $(step...)))
    end
    quote
        $(Expr(:meta, :inline))
        $expr
    end
end

# --- the declared read set (§14.7) ---------------------------------------------

"""
The declared read set (§14.7): the labeled selectors in one type, so that a
bare NamedTuple of selectors reaching a service is refused with a directive
rather than a `MethodError`, exactly as `combine` refuses one in the condition
algebra (§14.2).
"""
struct Reads{NT<:NamedTuple}
    selectors::NT
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
# One entry per selector, its leaf type and its resolved chain in the entry's
# *type*, so the gather is a tuple walk the compiler unrolls: no dictionary, no
# address arithmetic and no branch survives resolution. The four entry kinds
# are the four homes a read can come from — the flat state buffer, the
# derivative buffer beside it, a discrete component's own store, and the
# signal table. `C` is the chain `walk_leaf` runs on the value read there; the
# empty chain reads it whole.

struct StateRead{P,C}
    offset::Int
end

struct DerivRead{P,C}
    offset::Int
end

struct StoreRead{S,F,C}
    ci::Int
end

struct CellRead{A,C}
    addr::A
end

@inline _read(entry::StateRead{P,C}, exec::Executor) where {P,C} =
    walk_leaf(reconstruct(P, exec.xbuf, entry.offset), Val(C))
@inline _read(entry::DerivRead{P,C}, exec::Executor) where {P,C} =
    walk_leaf(reconstruct(P, exec.ẋbuf, entry.offset), Val(C))
# The `s` stores are held by component index in a `Vector{Any}` — one store
# type per component type, not per model — so the baked store type is what
# keeps the read inferable. The assertion goes on the *reference*: asserting
# the dereferenced value instead leaves the `[]` a dynamic call, which boxes.
@inline _read(entry::StoreRead{S,F,C}, exec::Executor) where {S,F,C} =
    walk_leaf(getfield((exec.sstores[entry.ci]::Base.RefValue{S})[], F), Val(C))
# The signal table's read is store-level, so every gather over a table shares it.
@inline _read(entry::CellRead{A,C}, store::StoreBundle) where {A,C} =
    walk_leaf(gather_cell(store, entry.addr), Val(C))
@inline _read(entry::CellRead, exec::Executor) = _read(entry, exec.store)

"""
One compiled read set (§14.4): the labels as a type parameter, the resolved
entries as a tuple carrying their leaf types. `gather_reads(reader, executor)` is the
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

@inline gather_reads(reader::Reader{T,L}, exec::Executor{T}) where {T,L} =
    NamedTuple{L}(map(e -> _read(e, exec), reader.entries))

gather_reads(::Reader{T}, ::Executor{S}) where {T,S} = _activation_mismatch("reader", T, S)

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
    for (label, selector) in pairs(read_set.selectors)
        entry = _resolve_selector(selector, label, build, act, diags)
        entry === nothing || push!(entries, entry)
    end
    (isempty(diags) ? Reader{T,keys(read_set.selectors)}(Tuple(entries)) : nothing, diags)
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
    push!(diags, _reader_violation(label, selector, :assembly_path))
    nothing
end

# One `TapResolution` off a selector: the label and the selector as authored are
# what makes a collected list readable, and the tap set, path and leaf address
# come off the selector itself (§14.10's payload); each arm adds what it observed.
_reader_violation(label::Symbol, selector, reason::Symbol; kw...) =
    TapResolution(; label = label, selector = _spell(selector), reason = reason,
                  tap = _tap(selector), path = _selpath(selector),
                  leaf = _leaf_string(selector), kw...)

# A step the leaf address cannot take, with what `resolve_leaf` or `parse_leaf`
# had in hand (§14.4, D-276). A face selector passes its matched face.
_leaf_violation(label::Symbol, selector, refusal::LeafRefusal; field = _field(selector)) =
    _reader_violation(label, selector, refusal.reason; field = field,
                      step = refusal.step, declared = refusal.declared,
                      candidates = refusal.candidates)

_tap(::Union{GetState,GetDeriv}) = :x
_tap(::Union{GetOutput,GetFace}) = :y
_tap(::GetInput) = :u

_selpath(selector::Union{GetState,GetDeriv,GetOutput}) = selector.path
_selpath(::Union{GetInput,GetFace}) = ""

# The head name the leaf address starts with, the payloads' `field`; `nothing`
# when the address does not parse.
function _field(selector::Union{GetState,GetDeriv,GetOutput})
    parsed = parse_leaf(selector.leaf)
    parsed isa LeafRefusal ? nothing : first(parsed)
end

# A face selector's head is matched against the faces it may name (§14.4,
# D-276): the face its address names, or the whole address where none matches.
_field(selector::Union{GetInput,GetFace}, faces) =
    something(match_face(selector.leaf, faces), Symbol(selector.leaf))

# The root-exported output faces, the names a `get_face` may take.
_exported_faces(structure::Structure) =
    Symbol[face for ((face_path, face), _) in structure.out_faces if isempty(face_path)]

# A path selector's parsed address, or `nothing` with its refusal collected;
# a face selector's is matched instead (`_matched_leaf`).
function _parsed_leaf(selector, label::Symbol, diags::Vector{Diagnostic})
    parsed = parse_leaf(selector.leaf)
    parsed isa LeafRefusal || return parsed
    push!(diags, _leaf_violation(label, selector, parsed))
    nothing
end

# A face selector's address matched against `faces`: the head and steps,
# `nothing` on a miss the caller refuses, or the refusal of a step, collected.
function _matched_leaf(selector, label::Symbol, faces, diags::Vector{Diagnostic})
    matched = match_leaf(selector.leaf, faces)
    matched isa LeafRefusal &&
        push!(diags, _leaf_violation(label, selector, matched; field = _field(selector, faces)))
    matched
end

# The chain the steps resolve to under the declared type `P`, or `nothing` with
# the refusal collected. The schema's types decide everything (§14.4).
function _leaf_chain(selector, label::Symbol, ::Type{P}, steps,
                     diags::Vector{Diagnostic}; field = _field(selector)) where {P}
    resolved = resolve_leaf(P, steps)
    resolved isa LeafRefusal || return first(resolved)
    push!(diags, _leaf_violation(label, selector, resolved; field = field))
    nothing
end

_undeclared_violation(label::Symbol, selector, declares::Symbol, declared::NamedTuple) =
    _reader_violation(label, selector, :undeclared; declares = declares, field = _field(selector),
                      candidates = collect(keys(declared)))

# The port list in hand is the `Outputs`' row concatenated by `_ports`, a fresh
# vector the payload is free to hold (D-253).
_undeclared_violation(label::Symbol, selector, declares::Symbol, declared::Vector{Symbol}) =
    _reader_violation(label, selector, :undeclared; declares = declares, field = _field(selector),
                      candidates = declared)

function _resolve_selector(selector::GetState, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    ci = _read_component(selector, label, build.structure, diags)
    ci === nothing && return nothing
    parsed = _parsed_leaf(selector, label, diags)
    parsed === nothing && return nothing
    head, steps = parsed
    decl, tier = act.decls[ci], build.structure.components[ci].tier
    declared = state_decls(decl, tier)
    haskey(declared, head) ||
        (push!(diags, _undeclared_violation(label, selector, :state_field, declared));
         return nothing)
    # A continuous field is flat, a scalar or an `SArray` (§7.1), so a `.name`
    # step falls out of the walk as `:no_such_field`. A discrete `s` field is any
    # isbits value and takes the full chain (§14.4, D-276).
    field_type = typeof(declared[head])
    chain = _leaf_chain(selector, label, field_type, steps, diags)
    chain === nothing && return nothing
    tier === CONTINUOUS ?
        StateRead{field_type,chain}(first(act.layout.xblocks[ci]) - 1 + _leaf_offset(decl.x, head)) :
        StoreRead{typeof(decl.s),head,chain}(ci)
end

function _resolve_selector(selector::GetDeriv, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    ci = _read_component(selector, label, build.structure, diags)
    ci === nothing && return nothing
    parsed = _parsed_leaf(selector, label, diags)
    parsed === nothing && return nothing
    head, steps = parsed
    decl, tier = act.decls[ci], build.structure.components[ci].tier
    if tier !== CONTINUOUS
        push!(diags, _reader_violation(label, selector, :discrete_deriv; field = head))
        return nothing
    end
    haskey(decl.x, head) ||
        (push!(diags, _undeclared_violation(label, selector, :state_field, decl.x));
         return nothing)
    field_type = typeof(decl.x[head])
    chain = _leaf_chain(selector, label, field_type, steps, diags)
    chain === nothing && return nothing
    # `ẋ` has `x`'s shape at the activation scalar (§7.1), so the derivative of
    # a state field sits at the state field's own offset in the other buffer.
    DerivRead{field_type,chain}(first(act.layout.xblocks[ci]) - 1 + _leaf_offset(decl.x, head))
end

function _resolve_selector(selector::GetOutput, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    ci = _read_component(selector, label, build.structure, diags)
    ci === nothing && return nothing
    parsed = _parsed_leaf(selector, label, diags)
    parsed === nothing && return nothing
    head, steps = parsed
    decl = act.decls[ci]
    ports = _ports(build.outputs.components[ci])
    head in ports ||
        (push!(diags, _undeclared_violation(label, selector, :output_port, ports));
         return nothing)
    # The port's *type* is the activation's, a type being no name list (D-253).
    chain = _leaf_chain(selector, label, decl.outs[head], steps, diags)
    chain === nothing && return nothing
    addr = act.layout.addr[(selector.path, head)]
    CellRead{typeof(addr),chain}(addr)
end

function _resolve_selector(selector::GetInput, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    inputs = build.structure.root_inputs
    matched = _matched_leaf(selector, label, inputs, diags)
    if matched === nothing
        push!(diags, _reader_violation(label, selector, :unknown_root_input;
                                       field = _field(selector, inputs), candidates = inputs))
        return nothing
    end
    matched isa LeafRefusal && return nothing
    head, steps = matched
    addr = act.layout.addr[("", head)]
    chain = _leaf_chain(selector, label, _port_type(addr), steps, diags; field = head)
    chain === nothing && return nothing
    CellRead{typeof(addr),chain}(addr)
end

function _resolve_selector(selector::GetFace, label::Symbol, build::Build,
                           act::Activation, diags::Vector{Diagnostic})
    exported, inputs = _exported_faces(build.structure), build.structure.root_inputs
    matched = _matched_leaf(selector, label, exported, diags)
    if matched === nothing
        push!(diags, match_face(selector.leaf, inputs) === nothing ?
                    _reader_violation(label, selector, :unknown_output_face;
                                      field = _field(selector, exported), candidates = exported) :
                    _reader_violation(label, selector, :root_input_not_face;
                                      field = _field(selector, inputs)))
        return nothing
    end
    matched isa LeafRefusal && return nothing
    head, steps = matched
    addr = act.layout.addr[("", head)]
    chain = _leaf_chain(selector, label, _port_type(addr), steps, diags; field = head)
    chain === nothing && return nothing
    CellRead{typeof(addr),chain}(addr)
end
