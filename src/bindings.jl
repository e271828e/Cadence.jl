# The binding's runtime half (§11.6): the shipped `TableBinding` with its
# generic `map_input` — the one data-driven binding the framework writes, and
# the owner of the shared pure conditioning helper (§11.4) — and the output
# side: the table members of §14.4's read-selector family, the resolution
# `attach!` runs against the build, and the one compiled gather whose labeled
# NamedTuple is what `map_output` receives (§11.2). `map_input`/`map_output`
# are *conventions of the author-owned loop idiom*: the framework never calls
# them, so what is enforced here is only what construction and attach can
# check — the table's own shape, and the enumerated `reads`. Everything the
# mappings touch at runtime is bounded elsewhere: `map_input` by the staging
# checks (§11.4), on the writer's own task; `map_output` by receiving exactly
# the gather's NamedTuple, what it puts on the wire being the peer's business.
#
# The framework-legible half of the binding vocabulary — the roots, the
# declared sides, `claims`/`reads` and the conformance check — lives in
# roster.jl.

"""
    TableBinding(; channel = (face = "...", deadzone = ..., expo = ...), ...)

The shipped data-driven binding (§11.6): the framework writes its `map_input`
once, and a table value — channel name => entry — is constructed per
device × deployment pairing, where configurations are made. Each entry names
the root input face its channel writes (`face`, mandatory) and optionally the
conditioning parameters the generic `map_input` applies (`deadzone`, `expo`);
any other key is a typo caught here, at construction. The entry tuple rides
in the type, so the mapping specializes per table with no dynamic dispatch.

The input side is declared (`is_input`), and the claim is the table's face
set — `claims` derives it, so what the binding may write is exactly what its
entries name. A *code-driven* binding looks identical to the framework: a
JSON telecommand peer whose `claims` returns the vocabulary and whose
`map_input` parses bytes.
"""
struct TableBinding{T<:NamedTuple} <: AbstractBinding
    table::T
end

const _TABLE_ENTRY_VOCABULARY = Symbol[:face, :deadzone, :expo]

function TableBinding(; entries...)
    table = NamedTuple(entries)
    diags = Diagnostic[]
    for (channel, entry) in pairs(table)
        if !(entry isa NamedTuple)
            push!(diags, ArgumentInvalid(
                call = :TableBinding, reason = :entry_shape, entry = channel))
            continue
        end
        if !haskey(entry, :face)
            push!(diags, ArgumentInvalid(
                call = :TableBinding, reason = :no_face, entry = channel))
        elseif !(entry.face isa Union{AbstractString,Symbol})
            push!(diags, ArgumentInvalid(call = :TableBinding, reason = :face_name,
                                          entry = channel, value = entry.face))
        end
        for key in keys(entry)
            key in _TABLE_ENTRY_VOCABULARY || push!(diags, ArgumentInvalid(
                call = :TableBinding, reason = :vocabulary, entry = channel, argument = key,
                vocabulary = _TABLE_ENTRY_VOCABULARY))
        end
        deadzone = get(entry, :deadzone, nothing)
        deadzone === nothing || 0 <= deadzone < 1 || push!(diags, ArgumentInvalid(
            call = :TableBinding, reason = :deadzone, entry = channel, value = deadzone))
        expo = get(entry, :expo, nothing)
        expo === nothing || 0 <= expo <= 1 || push!(diags, ArgumentInvalid(
            call = :TableBinding, reason = :expo, entry = channel, value = expo))
    end
    isempty(diags) || throw(DiagnosticError(diags))
    TableBinding(table)
end

is_input(::TableBinding) = true
claims(b::TableBinding) = String[String(e.face) for e in values(b.table)]

"""
    map_input(datum::NamedTuple, b::TableBinding) -> ("face" => value, ...)

`TableBinding`'s generic mapping — the shared pure conditioning helper, with
an owner (§11.4, §11.6). The datum is whatever the author's loop assembled,
one field per *touched* channel: `map_input` returns face ⇒ value pairs for
exactly those, so a sparse datum stages a sparse batch and merge does the
rest (§11.4). The idiom is `stage!(handle, map_input(datum, binding(handle))...)`,
on the device's own task.

A datum field naming no table channel is configuration drift, not a bad
datum: the mapping and the datum are written by the same author, so the
throw is deliberate — it lands in the wrapper as the `DeviceCrash` it is
(§11.6). Cross-datum state — press counters, edge detection — lives in the
device struct, maintained by the loop, and arrives *inside* the datum:
`map_input` stays pure, and staged values are levels, never deltas (§11.4).
"""
function map_input(datum::NamedTuple, b::TableBinding)
    map(keys(datum)) do channel
        haskey(b.table, channel) || error(
            "map_input: the datum carries `$channel`, which names no channel of this " *
            "TableBinding — its channels are $(_faceset(keys(b.table))) (§11.6)")
        entry = b.table[channel]
        String(entry.face) => _condition(datum[channel], entry)
    end
end

# --- the output side: selectors, resolution, the compiled gather (§14.4, §11.2) --

# The selectors themselves are §14.4's closed family, declared in readers.jl
# above this file: the three *table* members are what a snapshot-bound reader
# may name, and the source rule is enforced here, at the attach point where the
# source is finally known (§14.4). `get_output` is an inspection read —
# deep paths, zero promises, free access, right for looking at *this* build —
# and `get_face` an integration read: a root-exported output face, named,
# curated, meaning-stable under substitution (§11.2). `get_input` reads a root
# input back, the source cell it is. What these reads do not take is depth
# *inside* a cell: a binding read is a whole cell, as every reader of the
# published table is (`pending.md`).

"""
The compiled gather (§11.2, §14.4): one attachment's `reads`, resolved and
frozen — the labels as a type parameter, the cell addresses as a tuple — so
`gather(handle, snap)` builds its labeled NamedTuple with no name resolved
per read. The exact mirror of the compiled scatter the drain applies
(§11.4), run in the other direction over a published snapshot.
"""
struct ReadGather{L,A<:Tuple}
    addrs::A
end
ReadGather{L}(addrs::A) where {L,A<:Tuple} = ReadGather{L,A}(addrs)

_gather(read_gather::ReadGather{L}, snapshot::Snapshot) where {L} =
    NamedTuple{L}(map(a -> gather(snapshot.store, a), read_gather.addrs))

"""
Resolve one attachment's `reads` against the build and compile the gather —
`attach!`'s output-side work (§11.2), run once at the attach point so a
binding that drifted from its model fails there, not with silent garbage on
the wire. The shape is fixed: `reads` returns a NamedTuple of labeled
selectors, `(; label = get_output(...), ...)`, and the labels are the
NamedTuple `map_output` receives. Every failure names the selector at fault;
the did-you-mean candidate lists are absent (`pending.md`).
"""
function _compile_gather(layout::Layout, selectors, binding_type::Type, device::String)
    selectors isa NamedTuple || throw(DiagnosticError(
        BindingContractMismatch(binding = _typename(binding_type),
                                 reason = :reads_not_namedtuple,
                                 observed = typeof(selectors))))
    addrs = map(values(selectors)) do selector
        selector isa ReadSelector || throw(DiagnosticError(
            BindingContractMismatch(binding = _typename(binding_type),
                                     reason = :reads_not_selectors,
                                     observed = typeof(selector))))
        _resolve_read(layout, selector, binding_type, device)
    end
    ReadGather{keys(selectors)}(addrs)
end

_root_input_names(layout::Layout) = Symbol[f for (f, _) in layout.root_inputs]

# The two name-shaped read misses carry candidate lists (§14.4). One lists the
# cells at the selector's path, and an assembly path lists its faces, which the
# alias pass entered into `addr`. The other lists the root-exported output faces,
# the names at the root that are not root inputs.
_cells_at(layout::Layout, path::AbstractString) =
    sort!(Symbol[name for (cell_path, name) in keys(layout.addr) if cell_path == path])
function _root_output_faces(layout::Layout)
    inputs = _root_input_names(layout)
    sort!(Symbol[name for (cell_path, name) in keys(layout.addr)
                 if cell_path == "" && name ∉ inputs])
end

# §14.4's source rule, enforced where the source is known: a snapshot carries
# no state stores by construction (§11.2) and `ẋ` is integrator scratch, so a
# snapshot-bound reader naming a store selector is a resolution error at
# attach — in the didactic style, with the remedy named.
_resolve_read(::Layout, selector::StoreSelector, binding_type::Type, device::String) =
    throw(DiagnosticError(
        ReadBindingUnresolved(device = device, binding = _typename(binding_type),
                               selector = _spell(selector), reason = :store_selector,
                               path = _selpath(selector), field = _field(selector))))

function _resolve_read(layout::Layout, selector::GetOutput, binding_type::Type, device::String)
    selector.i === nothing || throw(DiagnosticError(
        ReadBindingUnresolved(device = device, binding = _typename(binding_type),
                               selector = _spell(selector), reason = :indexed,
                               path = selector.path, field = selector.name)))
    haskey(layout.addr, (selector.path, selector.name)) || throw(DiagnosticError(
        ReadBindingUnresolved(device = device, binding = _typename(binding_type),
                               selector = _spell(selector), reason = :unknown_cell,
                               path = selector.path, field = selector.name,
                               candidates = _cells_at(layout, selector.path))))
    layout.addr[(selector.path, selector.name)]
end

function _resolve_read(layout::Layout, selector::GetInput, binding_type::Type, device::String)
    selector.face in _root_input_names(layout) || throw(DiagnosticError(
        ReadBindingUnresolved(device = device, binding = _typename(binding_type),
                               selector = _spell(selector), reason = :unknown_root_input,
                               field = selector.face, candidates = _root_input_names(layout))))
    layout.addr[("", selector.face)]
end

function _resolve_read(layout::Layout, selector::GetFace, binding_type::Type, device::String)
    selector.name in _root_input_names(layout) && throw(DiagnosticError(
        ReadBindingUnresolved(device = device, binding = _typename(binding_type),
                               selector = _spell(selector), reason = :root_input_not_output,
                               field = selector.name)))
    haskey(layout.addr, ("", selector.name)) || throw(DiagnosticError(
        ReadBindingUnresolved(device = device, binding = _typename(binding_type),
                               selector = _spell(selector), reason = :unknown_output_face,
                               field = selector.name, candidates = _root_output_faces(layout))))
    layout.addr[("", selector.name)]
end

"""
    map_output(nt, b) -> wire datum

The output side's convention name (§11.6), declared here for the loop idiom —
`send(dev.socket, map_output(gather(handle, snap), binding(handle)))` — and
never called by the framework: it receives exactly the compiled gather's
labeled NamedTuple, and what it puts on the wire is the peer's business. An
output binding defines its own method; the identity one returns the NamedTuple
itself.
"""
function map_output end

# The conditioning (§11.4): axis-convention values in [-1, 1], symmetric about
# zero. The deadzone zeroes the band and rescales the remainder so the
# endpoints stay fixed; expo blends linear into cubic — magnitude =
# (1-expo)·magnitude + expo·magnitude³ — attenuating the midrange with the
# endpoints again fixed. An entry declaring neither passes its value through
# untouched, which is what carries a throttle's [0, 1] level or a press
# counter (the levels doctrine): faces take post-conditioning semantics, and
# only where conditioning is declared does the axis convention bind.
function _condition(value, entry)
    deadzone = get(entry, :deadzone, nothing)
    expo = get(entry, :expo, nothing)
    deadzone === nothing && expo === nothing && return value
    clamped = clamp(float(value), -1, 1)
    magnitude = abs(clamped)
    deadzone === nothing ||
        (magnitude = magnitude <= deadzone ?
            zero(magnitude) : (magnitude - deadzone) / (1 - deadzone))
    expo === nothing || (magnitude = (1 - expo) * magnitude + expo * magnitude^3)
    flipsign(magnitude, clamped)
end
