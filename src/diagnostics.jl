# The diagnostic layer (§13.1, §13.2, Appendix C, D-058, D-214, D-215): the
# closed kind set the build and the services raise, and the one carrier that
# moves it. A diagnostic is a plain value whose *type* is its kind and whose
# fields are Appendix C's payload column — paths and names as strings and
# symbols, never component instances and never model types; the declared and
# observed *port* types are the payload exception, and they are small. Severity
# is a property of the kind, read as `severity(d)` and never stored per
# occurrence (§13.2 as amended, D-214). Where an occurrence surfaces and how it
# is reported are facts of the site, not of the value, so no kind carries them.
#
# Messages are presentation: `message(d)` renders one diagnostic in the didactic
# style (state the fix, show the list-in-hand) and carries no kind name —
# the carrier's `showerror` leads each line with it. Tests match on kind plus
# payload, never on message text (§13.2).
#
# The runtime warning stream's nine kinds live in `src/dataplane.jl` beside the
# cells that carry them; they are parented here so `severity` covers them too.

"""
The root of the closed kind set (§13.2, Appendix C). Every kind is an immutable
struct under it, with three methods: `severity(d)`, `path(d)` and `message(d)`.
"""
abstract type Diagnostic end

# A user type's name, for a payload field or a writer label: `nameof`, never the
# type itself. Interpolating a type qualifies it with the module it is defined
# in unless that module is the printing context, so one component would be named
# differently from `Main` and from a package or test module — and some of these
# names are recorded in a trace header (§11.5) and matched on replay.
_typename(value) = string(nameof(typeof(value)))
# A `Union` has no name of its own: spell it from its members, each unqualified.
_typename(type::Type) =
    type isa Union ? "Union{" * join(_typename.(Base.uniontypes(type)), ", ") * "}" :
                     string(nameof(type))
# A declared generic holding: `nameof` has no method, and `string` on the
# variable qualifies its bound the same way interpolating a type does.
_typename(typevar::TypeVar) = "$(typevar.name)<:$(_typename(typevar.ub))"
# A plain-data type with its shape, for the two container kinds alone: the outer
# name through `_typename` and every parameter spelled the same way, so a
# `Tuple{Gain,Gain}` keeps its arity and stays unqualified. A port type is
# interpolated whole (§13.2's exception), a label goes through `_typename`.
_typespell(type::Type) =
    !(type isa DataType) || isempty(type.parameters) ? _typename(type) :
    _typename(type) * "{" *
    join((p isa Type ? _typespell(p) : string(p) for p in type.parameters), ", ") * "}"

"""
The kind's severity (§13.2, D-214): `:error` — an occurrence throws, alone or
within a collection — or `:warning`, which never throws and joins no throw. The
default is `:error`; the warning kinds override it.
"""
severity(::Diagnostic) = :error

"""
The component or assembly path a diagnostic is attributed to, in slash form and
without decoration — the renderer's sort key within a kind group. Kinds that
name no path answer `""`.
"""
path(::Diagnostic) = ""

# `message(d)::String` is the third method; it has no default, so a kind added
# without one fails loudly at its first rendering rather than printing a stub.

# --- the shared renderings ----------------------------------------------------
# The framework's own spellings, shared so every rendering spells a component
# path, a name list and a face set the same way.

_at_path(path::AbstractString) = isempty(path) ? "the root component" : "`$path`"
_namelist(list) = isempty(list) ? "none" : join(("`$n`" for n in list), ", ")
_faceset(list) = isempty(list) ? "empty" : "{$(join(list, ", "))}"
_plainlist(list) = join(list, ", ")
_symtuple(list) = "(" * join((":$n" for n in list), ", ") * (length(list) == 1 ? ",)" : ")")

# --- the carrier (§13.1, §13.2, D-058) ----------------------------------------

"""
The one carrier: a fail-fast site throws it holding a single diagnostic, a
step barrier holding the whole collection its passes returned (§13.1). The
type parameter is the policy (§13.2, D-222): the diagnostic's kind for a
fail-fast throw, `Vector{Diagnostic}` for a collected one. Rendering, `kinds`
and the catch site's species rule dispatch on it.

`warnings` carries the build's warnings so far, and is empty everywhere else: a
step that throws renders its warnings with the collection it throws, because the
artifact that would have carried them never returned (§9.1, D-250). A warning
joins no collection, so `diagnostic`, `diagnostics` and `kinds` never see one.
"""
struct DiagnosticError{P <: Union{Diagnostic, Vector{Diagnostic}}} <: Exception
    carried::P
    warnings::Vector{Diagnostic}
end

DiagnosticError(d::Diagnostic, warning_list::Vector{Diagnostic} = Diagnostic[]) =
    DiagnosticError{typeof(d)}(d, warning_list)
DiagnosticError(diags::AbstractVector{<:Diagnostic},
                warning_list::Vector{Diagnostic} = Diagnostic[]) =
    DiagnosticError{Vector{Diagnostic}}(Vector{Diagnostic}(diags), warning_list)

"The one diagnostic a fail-fast throw, or a `StepError` species, carries."
diagnostic(carrier::DiagnosticError{<:Diagnostic}) = carrier.carried

"The collection a barrier's throw carries."
diagnostics(carrier::DiagnosticError{Vector{Diagnostic}}) = carrier.carried

"The kinds present in a collection, in first-appearance order — what a test asks first."
kinds(carrier::DiagnosticError{Vector{Diagnostic}}) = unique(typeof.(carrier.carried))

# Groups in first-appearance order, each sorted by path; the sort is stable, so
# two diagnostics at one path keep the order the pass produced them in.
function _groups(diags::Vector{Diagnostic})
    order = DataType[]
    for d in diags
        kind = typeof(d)
        kind in order || push!(order, kind)
    end
    [sort(filter(d -> typeof(d) === kind, diags); by = path, alg = MergeSort)
     for kind in order]
end

# The warnings tail both renderings end with, one line per warning in
# first-appearance order and in the carrier's own layout (§9.1, D-250).
function _show_warnings(io::IO, warning_list::Vector{Diagnostic})
    for d in warning_list
        print(io, "\n  ", nameof(typeof(d)), ": ", message(d))
    end
    nothing
end

function Base.showerror(io::IO, carrier::DiagnosticError{<:Diagnostic})
    print(io, "DiagnosticError: ", nameof(typeof(carrier.carried)), ": ",
          message(carrier.carried))
    _show_warnings(io, carrier.warnings)
end

function Base.showerror(io::IO, carrier::DiagnosticError{Vector{Diagnostic}})
    diags, warning_list = carrier.carried, carrier.warnings
    print(io, "DiagnosticError: ", length(diags), " diagnostics")
    isempty(warning_list) ||
        print(io, ", ", length(warning_list),
              length(warning_list) == 1 ? " warning" : " warnings")
    for group in _groups(diags), d in group
        print(io, "\n  ", nameof(typeof(d)), ": ", message(d))
    end
    _show_warnings(io, warning_list)
end

"""
A warning-severity kind's rendering for the log (§13.2, D-214's `logged`
policy): the same kind-name-leading line the carrier prints, minus the carrier
— a logged warning never throws, so it has no `showerror` to lead it. Named
`logline` rather than `logged` because the policy's name is taken here by
`logged(sim)`, the retained-snapshot accessor (§11.4), and one generic function
over both would be two unrelated meanings sharing a name.
"""
logline(d::Diagnostic) = string(nameof(typeof(d)), ": ", message(d))

"""
The build's warning channel (§9.1, D-250). `build` binds it around its three
steps, so a helper raising a warning from inside a declaration body appends to
the build's list without knowing the build — a declaration body has no artifact
in hand. Unbound is the honest standalone case, and `_warn!` logs there instead.
"""
const BUILD_WARNINGS = ScopedValue{Union{Nothing,Vector{Diagnostic}}}(nothing)

"""
Raise a warning (§9.1, D-250): append it to the bound build's list, or, outside
any build, log it directly. Logging is presentation and never a home, so the
bound case does not log here — `build` logs each warning once at return.
"""
function _warn!(d::Diagnostic)
    severity(d) === :warning ||
        throw(InternalInvariant("`$(nameof(typeof(d)))` is an error-severity kind: it is " *
                                "collected or thrown, never warned"))
    warning_list = BUILD_WARNINGS[]
    warning_list === nothing ? (@warn logline(d)) : push!(warning_list, d)
    nothing
end

# --- the runtime carrier (§13.4, D-059) ---------------------------------------

# Appendix C's time payloads are plain `Float64` (D-214): a diagnostic is
# reportage, never a value the model differentiates through. Under a `Dual`
# activation the clock and the snapshot's stamp are `Dual`s, which `Float64` has
# no method for, so the seconds are read off the value — recursively, so a
# nested activation's `Dual{…,Dual}` unwraps too.
_seconds(t::Real) = Float64(t)
_seconds(t::ForwardDiff.Dual) = _seconds(ForwardDiff.value(t))

"""
An immutable copy of the execution cursor at the catch (§13.4): the frame a
`StepError` carries. `path` is the component's — `""` for a bare-leaf build's
own root component — and `nothing` where the cursor named none, which the
rendering drops rather than spelling as the root.
"""
struct CursorFrame
    path::Union{Nothing,String}
    fn::Symbol
    phase::Symbol
    index::Int
end

# A payload value, compared as one: the default for an immutable holding a
# `String` is egality, which two equal frames built apart would fail.
Base.:(==)(a::CursorFrame, b::CursorFrame) =
    a.path == b.path && a.fn === b.fn && a.phase === b.phase && a.index == b.index

"""
§13.4's runtime carrier, `DiagnosticError`'s counterpart: the cursor's frame, the
clock at the failure, the frame-entry boundary index — the replay pointer — and
the cause. The parameter is the cause's type (D-225): the diagnostic's kind when
the cause is one, the exception model code threw otherwise. A *species* is a
`StepError` whose `cause` is a typed diagnostic, which is what lets a runtime
check throw its kind and reach the one catch site as a plain thrower.
"""
struct StepError{C <: Union{Diagnostic, Exception}} <: Exception
    frame::CursorFrame
    t::Float64       # `_seconds(clock.t)` at the catch: the boundary time in a boundary
                     # phase, the stage or trial time mid-integration
    boundary::Int    # the frame-entry boundary index: replay!(…; to_boundary = boundary)
    cause::C
end

# The species' payload, read as a fail-fast `DiagnosticError`'s is (D-225).
diagnostic(carrier::StepError{<:Diagnostic}) = carrier.cause

# The phase, spelled per case (§13.4). The index rides only where one applies:
# an `:integrate` frame at index 0 is the framework's own act inside the
# integrate — the nonfinite sweep — and not a stage. A phase this list does not
# know renders as its own symbol, never as another phase's spelling.
_phase_text(frame::CursorFrame) =
    frame.phase === :integrate  ? (frame.index == 0 ? "integration" :
                                                "integration stage $(frame.index)") :
    frame.phase === :arrival    ? "arrival sweep" :
    frame.phase === :validation ? "θ = 0 validation" :
    frame.phase === :trial      ? "localization trial $(frame.index)" :
    frame.phase === :project    ? "projection" :
    frame.phase === :round      ? "event round $(frame.index)" :
    frame.phase === :ticks      ? "tick updates" :
    frame.phase === :drain      ? "drain" : string(frame.phase)

# §13.2's doctrine: the didactic frame first, the raw throw second. The frame
# line names the path, the function, the phase, the time and the pointer, and
# states the reproduction; a `Diagnostic` cause renders as its logline. A frame
# whose cursor named no component drops the "in …" clause entirely: `_at_path`
# spells the empty path as "the root component", which is a *component* of a
# bare-leaf build and not "nowhere".
function Base.showerror(io::IO, carrier::StepError)
    frame = carrier.frame
    print(io, "StepError: ")
    if frame.path !== nothing
        print(io, "in ", _at_path(frame.path))
        frame.fn === :none || print(io, " ", frame.fn)
        print(io, ", ")
    end
    print(io, _phase_text(frame), " of the frame from boundary ", carrier.boundary,
          " (t = ", carrier.t, "):\n  ")
    # The pointer degenerates at zero (§13.4, D-223): boundary zero and frame
    # one share it, and the replay of the captured header reproduces either —
    # the `step!` the general recipe names is what a boundary-zero failure
    # would refuse.
    carrier.boundary == 0 ?
        print(io, "replay!(sim2, trc) reproduces it") :
        print(io, "replay!(sim2, trc; to_boundary = ", carrier.boundary,
              ") then step!(sim2) reproduces it")
    print(io, "\n  cause: ")
    carrier.cause isa Diagnostic ? print(io, logline(carrier.cause)) :
                                   showerror(io, carrier.cause)
    nothing
end

"""
A nonfinite continuous-state leaf found by the boundary's first act (§13.4,
D-157): the sweep over `x` immediately after integrate returns, before
`state_projection` and before the boundary sweep, so the component whose own block
diverged is the one named — not the innocent downstream one the NaN would
reach next. Thrown as a fail-fast `DiagnosticError`, and the frame loop's
catch site makes it a `StepError` species.
"""
Base.@kwdef struct NonfiniteState <: Diagnostic
    path::String
    leaf::String     # the leaf's dotted spelling within the state, `"q"` or `"v[2]"`
    value::Any       # the offending value: NaN, Inf or -Inf
    t::Float64       # the frame-top time the integrate landed on
    boundary::Int    # the frame-entry boundary index, as the carrier's
end

path(d::NonfiniteState) = d.path
message(d::NonfiniteState) = string(
    _at_path(d.path), ": state leaf `", d.leaf, "` is ", d.value, " at the frame top t = ",
    d.t, " (from boundary ", d.boundary, ") — the model diverged; replay to ",
    d.boundary, " and step! to inspect the frame")

"""
An internal invariant firing (D-215): not a diagnostic and not a kind, because
it names no failure the user can fix. Its own exception type so the assertions
stay outside the acceptance-test contract.
"""
struct InternalInvariant <: Exception
    msg::String
end

Base.showerror(io::IO, invariant::InternalInvariant) =
    print(io, "InternalInvariant: internal invariant violated: ", invariant.msg)

# ==============================================================================
# The structure step — declaration and wiring (§6.1, §8.2, §8.5–§8.8; collected)
# ==============================================================================

"§6.1, §8.4 w1: a wire end naming no port of the endpoint it resolved to, with that end's port list."
Base.@kwdef struct UnknownPort <: Diagnostic
    entry::String                            # the declaring method and entry
    end_::Symbol                             # :source | :destination | :connection (D-210)
    path::String = ""                        # the component that end resolved to
    spelling::String = ""                    # the endpoint path as the entry wrote it
    port::Union{Nothing,Symbol} = nothing    # the unknown port or face name
    candidates::Vector{Symbol} = Symbol[]    # that end's port list, the did-you-mean
end
path(d::UnknownPort) = d.path
message(d::UnknownPort) =
    d.end_ === :connection ?
    "$(d.entry): the entry routes to no internal endpoint — every `input_connections` " *
    "entry routes to at least one, a face feeding nothing declaring nothing (§8.6)" :
    "$(d.entry): `$(d.spelling)` names no `$(d.port)` on $(_at_path(d.path)) — its " *
    "faces are $(_plainlist(d.candidates))"

"§6.1, §8.4 w2: an input no wire and no `input_connections` chain feeds."
Base.@kwdef struct UnconnectedInput <: Diagnostic
    path::String
    face::Symbol
    declared::Any                            # the declared entry type, at nominal
    level::String                            # the obligation chain's last level; the leaf's own path when no route names it
end
path(d::UnconnectedInput) = d.path
message(d::UnconnectedInput) =
    "`$(d.path)`.$(d.face) declared $(d.declared) is fed by nothing" *
    (d.level == d.path ? "" :
     ", handed up to $(_at_path(d.level)) and fed by nothing there") *
    " — every input is fed exactly once, by a wire or by an `input_connections` chain " *
    "ending at a root input face (§6.1)"

"§6.1, §8.8: an input claimed twice, both producers named with their declarations."
Base.@kwdef struct TwoProducers <: Diagnostic
    path::String                             # the destination terminal's component
    port::Symbol                             # the destination terminal's port
    incumbent::String                        # the entry that claimed it first
    entry::String                            # the entry that claimed it second
    incumbent_producer::String               # the terminal the first entry feeds it from
    producer::String                         # the terminal the second entry feeds it from
end
path(d::TwoProducers) = d.path
message(d::TwoProducers) =
    "`$(d.path)`.$(d.port) is fed twice: from $(d.incumbent_producer) by $(d.incumbent), " *
    "and from $(d.producer) by $(d.entry) — every input takes exactly one connection, " *
    "across levels included (§6.1)"

"§6.1, §8.2, §8.4 w4: a wire whose producer's declaration at `Float64` is not `<:` the consumer's entry at `Float64`."
Base.@kwdef struct WireTypeMismatch <: Diagnostic
    path::String                             # the consumer
    face::Symbol
    declared::Any                            # the declared entry type
    producer_path::String                    # "" for a root input
    producer_port::Symbol
    observed::Any                            # the producer face type
end
path(d::WireTypeMismatch) = d.path
message(d::WireTypeMismatch) =
    "`$(d.path)`.$(d.face) declared $(d.declared), fed from " *
    (isempty(d.producer_path) ? "root input `$(d.producer_port)`" :
     "`$(d.producer_path)`.$(d.producer_port)") *
    "::$(d.observed)"

"§6.1, §8.2: a walking producer leaf feeding a pinned entry leaf of a continuous consumer."
Base.@kwdef struct WalkingFaceAtFrozenEntry <: Diagnostic
    path::String                             # the consumer
    face::Symbol                             # its entry
    producer_path::String
    producer_port::Symbol
    leaf::Union{Nothing,String}              # the offending leaf's dotted spelling; `nothing` when the entry is abstract
    declared::Any                            # the entry's type there: a pinned leaf type, or the whole abstract entry
    observed::Any                            # the producer's declaration there, at the marker
end
path(d::WalkingFaceAtFrozenEntry) = d.path
message(d::WalkingFaceAtFrozenEntry) =
    "`$(d.path)`.$(d.face)" *
    (d.leaf === nothing || isempty(d.leaf) ? "" : " at leaf `$(d.leaf)`") *
    " is declared $(d.declared), frozen, but `$(d.producer_path)`.$(d.producer_port) " *
    "declares $(d.observed) there, which walks with the activation — declare the entry " *
    "`T` if the consumer promotes; feed it from a non-walking source if the freeze is " *
    "genuine (§6.1, §8.2)"

"§8.2: a root input whose consumers all declare abstract entries, so no type determines it."
Base.@kwdef struct AbstractAtRoot <: Diagnostic
    face::Symbol
    paths::Vector{String}                    # the consuming leaves
    declared::Vector{Any}                    # their abstract entries
end
path(::AbstractAtRoot) = ""
# A port type is §13.2's one payload exception, so the entry is interpolated
# whole, as `RootInputTypeConflict` beside it does: `_typename` would strip the
# parameters and print `AbstractVector{Float64}` as `AbstractArray`.
message(d::AbstractAtRoot) =
    "root input `$(d.face)` is declared " *
    join(("$(_at_path(p))::$(P)" for (p, P) in zip(d.paths, d.declared)), ", ") *
    " — every entry is abstract, and a root input is typed by its consumers alone, so " *
    "nothing determines its type; wire `$(d.face)` to a concrete producer — in a test " *
    "rig, a stub child (§8.2, §13.7)"

"""
§8.2: two consumers of one root input face declaring different entry types.
A root input takes its type from the consumer declaration alone, so under
fan-out the concrete declaration has to be unique. The comparison is *at
nominal*, which is what makes a tolerance difference no conflict: `SVector{3,T}`
and `SVector{3,Float64}` both evaluate to `SVector{3,Float64}` there, and their
disagreement about partials is the fan-out meet (D-168), a legitimate model.
The comparison runs in the structure step's wire pass over the *concrete* entries alone;
an abstract co-consumer names no type to conflict with, and is checked against
the one the concrete entries fixed by the bound clause (D-236).
"""
Base.@kwdef struct RootInputTypeConflict <: Diagnostic
    face::Symbol                             # the root input face
    paths::Vector{String}                    # the consuming components
    declared::Vector{Any}                    # their entry declarations at nominal
end
message(d::RootInputTypeConflict) =
    "root input `$(d.face)` is declared " *
    join(("$(_at_path(p))::$(P)" for (p, P) in zip(d.paths, d.declared)), ", ") *
    " — a root input is typed by its consumers alone, so its concrete declaration " *
    "has to be unique across the fan-out; agree the entries, or give the face a " *
    "producer (§8.2, D-168)"

"§6.1, §13.3: a path that resolves to nothing, or reaches past the one level its client admits."
Base.@kwdef struct PathResolution <: Diagnostic
    entry::String                            # the condition or wiring entry
    spelling::String                         # the path as written
    reason::Symbol   # :not_a_terminal|:unknown_child|:reaches_past|:past_generic|:empty_path
    owner::String = ""                       # the component the path was resolved against
    segment::String = ""                     # the offending segment
    level::String = ""                       # the level it stopped at
    candidates::Vector{String} = String[]    # the sibling child names
    tail::Int = 0                            # 1 for a wiring endpoint, 0 for a bare child path
    declared::Any = nothing                  # the offending field's declared type, where generic
end
path(d::PathResolution) = d.spelling
function message(d::PathResolution)
    d.reason === :not_a_terminal &&
        return "$(d.entry): `$(d.spelling)` is not an endpoint — a terminal path names a " *
               "child and one of its ports or faces (§8.6)"
    d.reason === :empty_path &&
        return "$(d.entry): the empty path names no child — a path here names an immediate " *
               "child of the component in hand (§13.3)"
    d.reason === :unknown_child &&
        return "$(d.entry): `$(d.spelling)` names no child `$(d.segment)` of $(d.owner)" *
               (isempty(d.candidates) ? " — it has no children" :
                " — its children are $(_plainlist(d.candidates))")
    d.reason === :past_generic &&
        return "$(d.entry): `$(d.spelling)` reaches past `$(d.level)`, which $(d.owner) " *
               "holds through the non-concrete declared type `$(_typename(d.declared))` — a " *
               "service path stops at a generically held child or stays within a " *
               "concretely declared subtree: address the child at its own level, read a " *
               "face it exports, or declare the field's concrete type (§13.3, §14.2)"
    "$(d.entry): `$(d.spelling)` reaches past `$(d.level)` — " *
    (d.tail == 1 ?
     "a connection endpoint names an immediate child and one of its faces, so an " *
     "endpoint path is one child segment (plus the key segment where the child is a " *
     "container element) and one face name; route through `$(d.segment)`'s own face " *
     "instead, declared level by level (§6.1)" :
     "a path here names an immediate child: one child segment, plus the key " *
     "segment where the child is a container element, and nothing further (§6.1, §13.3)")
end

"§8.2: a declared store with no update — `init_x` without `state_derivative`, `init_s` without `state_update`."
Base.@kwdef struct StoreWithoutUpdate <: Diagnostic
    path::String
    store::Symbol                            # :init_x | :init_s
end
path(d::StoreWithoutUpdate) = d.path
message(d::StoreWithoutUpdate) =
    "`$(d.path)` declares `$(d.store)` but defines neither `state_derivative` nor " *
    "`state_update` — a store needs its update (§8.2)"

"§8.2: an event declared with one half, or a `state_events` entry that is not a `StateEvent` (D-215)."
Base.@kwdef struct EventHalfMissing <: Diagnostic
    path::String
    event::Symbol
    reason::Symbol                           # :guard | :handler | :not_an_event
    found::String                            # the component type's name, or the entry type's
end
path(d::EventHalfMissing) = d.path
message(d::EventHalfMissing) =
    d.reason === :not_an_event ?
    "`$(d.path)`: `state_events` entry `$(d.event)` is a `$(d.found)` — an entry is " *
    "`StateEvent(guard, handler)`, with no detection keyword (§8.2)" :
    "`$(d.path)`: event `$(d.event)`'s $(d.reason) has no method for `$(d.found)` — an " *
    "event needs both halves (§8.2)"

"§8.1, D-246: a family name the component's module binds to a function of its own — the forgotten import."
Base.@kwdef struct DeclarationShadowed <: Diagnostic
    path::String
    mod::String                              # the parent module, `string(M)`
    names::Vector{Symbol}                    # the foreign names, family order
end
path(d::DeclarationShadowed) = d.path
message(d::DeclarationShadowed) =
    "$(_at_path(d.path)): its module `$(d.mod)` defines its own $(_namelist(d.names)), " *
    "distinct from " *
    (length(d.names) == 1 ? "`Cadence.$(only(d.names))`" : "`Cadence`'s") *
    "; add `import Cadence: $(join(d.names, ", "))` (§8.1)"

"§8.5: a component declaring neither family, so its class cannot be read off declaration shape."
Base.@kwdef struct ClassUnreadable <: Diagnostic
    path::String
    type::String                             # the component type's name
    found::Vector{Symbol}                    # the `DECLARATION_FAMILY` names it does declare, family order
    assembly_family::Vector{Symbol}          # the assembly family list, the list-in-hand
    leaf_family::Vector{Symbol}              # the leaf family list, the list-in-hand
    holds_components::Bool = false
end
path(d::ClassUnreadable) = d.path
message(d::ClassUnreadable) =
    "$(_at_path(d.path))::`$(d.type)` declares neither family: " *
    "$(_namelist(d.assembly_family)) would make it an assembly, any of " *
    "$(_namelist(d.leaf_family)) a primitive (§8.5)" *
    (isempty(d.found) ? "" : " — it declares $(_namelist(d.found))") *
    (d.holds_components ?
     " — it holds components but declares no `child_connections`" : "")

"§8.5: a component declaring both families — an assembly owns no state and no contract."
Base.@kwdef struct ClassMixed <: Diagnostic
    path::String
    declarations::Vector{Symbol}             # the offending leaf declarations
end
path(d::ClassMixed) = d.path
message(d::ClassMixed) =
    "$(_at_path(d.path)) declares `child_connections` and the leaf declaration(s) " *
    "$(_plainlist(d.declarations)) — an assembly owns no state and no contract of its " *
    "own (§8.5)"

"§8.5: a container field mixing components with plain data."
Base.@kwdef struct ContainerMixed <: Diagnostic
    path::String
    field::Symbol
    keys::Vector{Any}                        # the non-component element keys or indices
    types::Vector{String}                    # the unique non-component element types, spelled with their shape (§13.2)
end
path(d::ContainerMixed) = d.path
message(d::ContainerMixed) =
    "$(_at_path(d.path)): container field `$(d.field)` mixes components with " *
    "$(_plainlist(d.types)) at $(_namelist(d.keys)) — a container holds components only " *
    "(§8.5)"

"§8.5: a container whose element is itself a component-bearing container — deeper grouping is what assemblies are for."
Base.@kwdef struct ContainerNested <: Diagnostic
    path::String
    field::Symbol
    keys::Vector{Any}                        # the offending element keys or indices
    types::Vector{String}                    # their types, spelled with their shape, one per key (§13.2)
end
path(d::ContainerNested) = d.path
message(d::ContainerNested) =
    "$(_at_path(d.path)): container field `$(d.field)` holds containers at " *
    "$(_namelist(d.keys)) ($(_plainlist(d.types))) — containers of containers are " *
    "rejected in the first cut; deeper grouping is an assembly (§8.5)"

"§5.2, §8.2, §8.5: a declaration written in the other tier's form, or `state_projection` off the continuous tier."
Base.@kwdef struct DeclarationOnWrongTier <: Diagnostic
    path::String
    declaration::Symbol                      # the offending declaration
    reason::Symbol                           # :tier_form | :continuous_only | :no_manifold
    found::Union{Nothing,Symbol} = nothing   # the tier the declaration is written in
    announced::Union{Nothing,Symbol} = nothing  # the tier the other declarations announce
end
path(d::DeclarationOnWrongTier) = d.path
message(d::DeclarationOnWrongTier) =
    d.reason === :continuous_only ?
    "`$(d.path)` declares `$(d.declaration)`, which is continuous-only — projection " *
    "normalizes continuous state (§5.2)" :
    d.reason === :no_manifold ?
    "`$(d.path)` declares `$(d.declaration)` but no `init_x` — there is no state " *
    "manifold to project onto (§5.2)" :
    "`$(d.path)`: `$(d.declaration)` is declared in the $(d.found)-tier form, but this " *
    "component's other declarations announce the $(d.announced) tier (§8.2)"

"§6.1, §8.2, §8.5, D-249: a contract signature whose form is not the one its tier mandates — the arity arm, and the bound arm, a `T` narrower than `Real`."
Base.@kwdef struct TierSignatureMismatch <: Diagnostic
    path::String
    declaration::Symbol                      # :input_types | :output_types
    tier::Symbol                             # :continuous | :discrete
    reason::Symbol                           # :bound | :arity
    found::Any                               # the bound the method puts on `T`, or the form declared
    mandated::Any                            # the mandated bound, or the form the tier mandates
end
path(d::TierSignatureMismatch) = d.path
# §8.5's two spellings, the form symbols the `:arity` arm carries rendered as the
# section writes them.
_signature(form::Symbol) =
    form === :two_argument ? "(::C, ::Type{T}) where {T <: Real}" : "(::C)"
message(d::TierSignatureMismatch) =
    d.reason === :arity ?
    "$(_at_path(d.path)): `$(d.declaration)` is declared `$(_signature(d.found))`, but " *
    "this component's other declarations announce the $(d.tier) tier, whose contract " *
    "signatures are `$(_signature(d.mandated))` — declare it that way (§8.5)" :
    "$(_at_path(d.path)): `$(d.declaration)` bounds its `T` by $(d.found), but a " *
    "continuous contract is a function of every activation scalar — declare it " *
    "`where {T <: Real}` (§8.5)"

"§8.6: a face name holding `/`, the separator reserved for structural paths."
Base.@kwdef struct FaceNameIllegal <: Diagnostic
    path::String
    face::String
    invariant::Symbol                        # the invariant broken; :contains_slash is §8.6's
end
path(d::FaceNameIllegal) = d.path
message(d::FaceNameIllegal) =
    d.invariant === :contains_slash ?
    "$(_at_path(d.path)): face name `$(d.face)` contains `/`, which is reserved for " *
    "structural paths (§8.6)" :
    "$(_at_path(d.path)): face name `$(d.face)` breaks the `$(d.invariant)` invariant (§8.6)"

"§8.6: one face name declared twice — across an assembly's two methods, or at a primitive root."
Base.@kwdef struct FaceNameCollision <: Diagnostic
    path::String
    faces::Vector{String}
    site::Symbol                             # :assembly | :root
end
path(d::FaceNameCollision) = d.path
message(d::FaceNameCollision) =
    d.site === :root ?
    "$(_at_path("")): face name(s) $(_plainlist(d.faces)) appear twice — at the root a " *
    "primitive's faces are its `input_types` and `output_types` keys together, and a key " *
    "declared in both is the same build error a duplicate assembly face name is (§8.6)" :
    "$(_at_path(d.path)): face name(s) $(_plainlist(d.faces)) appear twice — face names " *
    "are unique across `input_connections` and `output_connections` together; to route " *
    "one input face to several children, write `name => (path, path, …)` (§8.6)"

"§8.6: an entry whose endpoint resolves to a port of the opposite direction."
Base.@kwdef struct FaceDirectionConflict <: Diagnostic
    entry::String                            # the declaring method and entry
    path::String                             # the child the endpoint resolved to
    spelling::String                         # the endpoint path as written
    found::Symbol                            # :input | :output — the resolved direction
    wanted::Symbol                           # :producer | :consumer — the entry's side
end
path(d::FaceDirectionConflict) = d.path
message(d::FaceDirectionConflict) =
    "$(d.entry): `$(d.spelling)` resolves to " *
    (d.found === :input ? "an input" : "an output") * " of $(_at_path(d.path)), but this " *
    "entry's endpoint is a $(d.wanted) — direction is declared by the method (§8.6)"

"§8.8: a passthrough filter naming faces the child does not have, or giving more than one selector."
Base.@kwdef struct UnknownFaceSelection <: Diagnostic
    who::String                              # the calling helper
    path::String                             # the child path
    reason::Symbol                           # :multiple_selectors | :unknown_names
    names::Vector{String} = String[]         # the offending names, or the selectors given
    candidates::Vector{String} = String[]    # the child's face list
end
path(d::UnknownFaceSelection) = d.path
message(d::UnknownFaceSelection) =
    d.reason === :multiple_selectors ?
    "`$(d.who)` at `$(d.path)`: $(_namelist(d.names)) were given together — the three " *
    "selectors are exclusive, one per call, and a second rule takes a second call (§8.8)" :
    "`$(d.who)` at `$(d.path)`: $(_namelist(d.names)) " *
    "$(length(d.names) == 1 ? "names" : "name") no face of that child — its faces are " *
    "$(_namelist(d.candidates)) (§8.8)"

"§8.8, D-251: a passthrough selector that kept no face of the child."
Base.@kwdef struct EmptyFaceSelection <: Diagnostic
    who::String                              # the calling helper
    path::String                             # the child path
    # `:only` is in the vocabulary but never constructed by the helper: a
    # non-empty `only` of known names keeps them all (`_passthrough_faces`).
    selector::Symbol                         # :except | :only | :select
    names::Vector{String} = String[]         # the selector's names; empty for `select`
    candidates::Vector{String} = String[]    # the child's face list on that side
end
severity(::EmptyFaceSelection) = :warning
path(d::EmptyFaceSelection) = d.path
function message(d::EmptyFaceSelection)
    side = startswith(d.who, "input") ? "input" : "output"
    isempty(d.candidates) &&
        return "`$(d.who)` at `$(d.path)`: `$(d.selector)` was given and the child has no " *
               "$side face, so nothing passes through — a bare call over a faceless child " *
               "says the same thing without the selector (§8.8)"
    isempty(d.names) &&
        return "`$(d.who)` at `$(d.path)`: `$(d.selector)` accepted no face of the child, so " *
               "nothing passes through — its $side faces are $(_namelist(d.candidates)) (§8.8)"
    "`$(d.who)` at `$(d.path)`: `$(d.selector)` names $(_namelist(d.names)), every $side face " *
    "of the child, so nothing passes through (§8.8)"
end

"§8.7, §10.5: a `sample_times` declaration outside the value vocabulary, the residue bounds or the key rule."
Base.@kwdef struct RatesViolation <: Diagnostic
    path::String
    reason::Symbol   # :declaration_shape|:value_vocabulary|:multiplier|:phase|:period|:offset|:unknown_child|:continuous_child
    key::Union{Nothing,Symbol} = nothing     # the offending key
    value::Any = nothing                     # the offending value
    candidates::Vector{String} = String[]    # the immediate child names
end
path(d::RatesViolation) = d.path
_rates_entry(d) = "`sample_times` at $(_at_path(d.path)), key `$(d.key)`"
function message(d::RatesViolation)
    d.reason === :declaration_shape &&
        return "$(_at_path(d.path)): `sample_times` must return a NamedTuple of child " *
               "name => `Relative`/`Absolute` entries (§8.7)"
    d.reason === :value_vocabulary &&
        return "$(_rates_entry(d)): $(repr(d.value)) — the wrappers are the whole value " *
               "vocabulary; a bare integer or bare quantity is a declaration error (§8.7)"
    d.reason === :multiplier && return "$(_rates_entry(d)): K = $(d.value), and K ≥ 1 (§10.5)"
    d.reason === :phase && return "$(_rates_entry(d)): φ = $(d.value), and 0 ≤ φ < K (§10.5)"
    d.reason === :period && return "$(_rates_entry(d)): period $(d.value), and T > 0 (§10.5)"
    d.reason === :offset && return "$(_rates_entry(d)): offset $(d.value), and 0 ≤ τ < T (§10.5)"
    d.reason === :continuous_child &&
        return "`sample_times` at $(_at_path(d.path)) schedules `$(d.key)`, a continuous " *
               "component — a sample time is a discrete-tier fact; keys name discrete or " *
               "scope children (§8.7, §10.5)"
    "$(_rates_entry(d)): names no immediate child of $(_at_path(d.path)) — keys are " *
    "immediate child names only; a deep key would edit another type's design from " *
    "outside (§8.7)" *
    (isempty(d.candidates) ? "" : "; its children are $(_plainlist(d.candidates))")
end

"""
§9.3, D-051: a root input whose type the synthesis chain cannot produce a probe
value for. A `MethodError` out of the framework's own chain reports as this
kind. One out of an author's override is the override's own bug and propagates
as itself.
"""
Base.@kwdef struct MissingProbeValue <: Diagnostic
    face::Symbol                             # the root input face
    declared::Any                            # the face's type at this activation
end
path(::MissingProbeValue) = ""               # a root input's path is the root's
# The remedy spells the type with its parameters, so `d.declared` is interpolated
# directly, as `IllegalPortType` does; `_typename` would strip them.
message(d::MissingProbeValue) =
    "no `probe_value` for `$(d.declared)` at face `$(d.face)` — define " *
    "`probe_value(::Type{$(d.declared)})` or a zero-argument constructor (§9.3)"

"§8.5, D-211, D-212: two children under one name — a bare container key against the sugar, a sibling field, or a plain duplicate."
Base.@kwdef struct ChildNameCollision <: Diagnostic
    path::String
    name::String                             # the colliding child name
    reason::Symbol                           # :sample_times_sugar | :sibling_field | :two_children
    declarations::Vector{String} = String[]  # one entry for the bare-key arms, two for the duplicate
    field::Union{Nothing,Symbol} = nothing   # the container field the key came from
end
path(d::ChildNameCollision) = d.path
_declaration(d, ordinal) = ordinal ≤ length(d.declarations) ?
                           d.declarations[ordinal] : "an undetermined declaration"
message(d::ChildNameCollision) =
    d.reason === :sample_times_sugar ?
    "$(_at_path(d.path)): the bare key `$(d.name)` — " *
    "$(_declaration(d, 1)) — collides with " *
    "`sample_times`' field-name sugar, which spells one declaration for every element of " *
    "`$(d.field)` under that same name (§8.5, §8.7, D-211)" :
    d.reason === :sibling_field ?
    "$(_at_path(d.path)): the bare key `$(d.name)` — " *
    "$(_declaration(d, 1)) — collides with " *
    "container field `$(d.name)`, whose own children are named " *
    "`$(d.name)/<key>`: no " *
    "child bears the bare name, but the segment grammar that reaches those children does, " *
    "and the key shadows it — leaving them unreachable behind a diagnostic naming the " *
    "wrong child (§8.5, §6.1, D-212)" :
    "$(_at_path(d.path)): two children are named `$(d.name)` — " *
    "$(_declaration(d, 1)) and " *
    "$(_declaration(d, 2)); a child name is a path segment, and a path segment " *
    "addresses one component (§8.5, D-211)"

"§8.5, D-211: `transparent_container` naming no container field of the type."
Base.@kwdef struct TransparentContainerUnknown <: Diagnostic
    path::String
    field::Symbol
    component::String                        # the declaring type, as a string
    candidates::Vector{Symbol}               # the type's container fields, the list-in-hand
end
path(d::TransparentContainerUnknown) = d.path
message(d::TransparentContainerUnknown) =
    "$(_at_path(d.path)): `transparent_container` returns `:$(d.field)`, which names no " *
    "container field of `$(d.component)` — its container fields are " *
    "$(_namelist(d.candidates)); a name-transparent declaration names a `Tuple` " *
    "or `NamedTuple` field whose elements are all components, the empty one included " *
    "(§8.5, D-211)"

"§5.2, §8.2, §8.5, D-215: the tier twin of `ClassUnreadable` — no `output_types` and no state."
Base.@kwdef struct TierUnreadable <: Diagnostic
    path::String
    type::String                             # the component type's name
    family::Vector{Symbol}                   # the tier-announcing family, the list-in-hand
    declarations::Vector{Symbol} = Symbol[]  # the tier-announcing declarations found
end
path(d::TierUnreadable) = d.path
message(d::TierUnreadable) =
    "`$(d.path)`::`$(d.type)` declares no `output_types` and owns no state — there is " *
    "nothing for the tier to be read off: declare `output_types`, or give the component " *
    "an `init_x`/`init_s` store with the update law that drives it. Its tier-announcing " *
    "declarations are $(_namelist(d.declarations)), out of $(_namelist(d.family)) (§8.2)"

"§4.3, §7.1, §8.2, D-215, D-237, D-243: a port type the leaf walk cannot lay out — no leaves, a mutable type on the walk, or an opaque leaf at a root input."
Base.@kwdef struct IllegalPortType <: Diagnostic
    path::String
    site::Symbol                             # :port | :root_input
    name::Symbol
    declared::Any                            # the offending type
    reason::Symbol = :no_leaves              # :no_leaves | :mutable | :handle_at_root
    position::Any = nothing                  # :mutable — the dotted position of the mutable type, "" for the port itself
end
path(d::IllegalPortType) = d.path
function message(d::IllegalPortType)
    site = d.site === :root_input ? "root input" : "port"
    d.reason === :mutable &&
        return "$(_at_path(d.path)): $site `$(d.name)` declares $(d.declared), which is " *
               "mutable$(d.position == "" ? "" : " at `$(d.position)`") — a port value is " *
               "immutable, bulk data rides behind an immutable handle (§4.4)"
    d.reason === :handle_at_root &&
        return "$(_at_path(d.path)): root input `$(d.name)` declares $(d.declared), an opaque " *
               "leaf, which has no synthesis and no producer here — wire a component that " *
               "emits it, or a stub child in a rig (§4.3, §9.3, D-237)"
    "$(_at_path(d.path)): $site `$(d.name)` declares $(d.declared), which has no leaves"
end

"§8.2, D-247: a store declaration returning something other than a `NamedTuple`, the one admitted form."
Base.@kwdef struct StoreNotNamedTuple <: Diagnostic
    path::String
    store::Symbol                            # :init_x | :init_s | :init_m
    declared::Any                            # the observed type
end
path(d::StoreNotNamedTuple) = d.path
function message(d::StoreNotNamedTuple)
    wrap = d.store === :init_x ? "(; ω = 0.0)" :
           d.store === :init_s ? "(; n = 0)" : "(; phase = :idle)"
    "$(_at_path(d.path)): `$(d.store)` returns `$(d.declared)`, not a `NamedTuple` — a " *
    "store is declared by initial value as named fields, one leaf per field, " *
    "`$(d.store)(::C) = $wrap` (§8.2)"
end

"§7.1, §8.2, D-094: an `init_x` field outside the closed vocabulary — a mode value, a real off the common eltype, a nested `NamedTuple`, or a wrapper type."
Base.@kwdef struct IllegalStateLeaf <: Diagnostic
    path::String
    name::Symbol
    declared::Any                            # the offending field type
    reason::Symbol                           # :mode_value | :eltype | :nested | :wrapper
end
path(d::IllegalStateLeaf) = d.path
function message(d::IllegalStateLeaf)
    head = "$(_at_path(d.path)): `init_x` field `$(d.name)::$(d.declared)`"
    d.reason === :mode_value &&
        return "$head is not a continuous state — integers, `Bool`s and enums belong in " *
               "`init_m` (§7.1, §8.2)"
    d.reason === :eltype &&
        return "$head is not at the common eltype — state leaves are written at `Float64` " *
               "and walked to the activation scalar (§7.1, §7.2)"
    d.reason === :nested &&
        return "$head is not a state leaf — a field is one scalar or `SArray`; split it " *
               "into fields, structure comes from the component tree (§7.1)"
    "$head is not a state leaf — declare the `SVector` backing and cast where the domain " *
    "semantics are wanted (§7.1)"
end

"§7.3, §8.2, D-231: a store field that is neither isbits nor a `Symbol`."
Base.@kwdef struct IllegalStoreField <: Diagnostic
    path::String
    store::Symbol                            # :init_s | :init_m
    name::Symbol
    declared::Any                            # the offending field type
end
path(d::IllegalStoreField) = d.path
message(d::IllegalStoreField) =
    "$(_at_path(d.path)): `$(d.store)` field `$(d.name)::$(d.declared)` is not a store " *
    "value — store fields are isbits or `Symbol`s; text and bulk data belong on the " *
    "component instance (§7.3)"

# ==============================================================================
# The nominal evaluation and activation — schedule and contract conformance
# (§5.5, §8.3, §9.3, §9.5)
# ==============================================================================

"""
§5.5, §5.6: one strongly connected cluster of the stage-2 feedthrough graph.
`members` are component paths in walk order and `wires` the cluster's own
wires as `producer/port => consumer/face`, in the same order. The
classification is D-245's graph verdict, `nothing` when a member's
evaluation threw; `dead` lists every hop the trace found unrouted, as
(member, input face, output port); `traced` records each member's mode,
`:global`, `:sampled` or `:structural`.
"""
Base.@kwdef struct AlgebraicCycle <: Diagnostic
    members::Vector{String}
    wires::Vector{Pair{String,String}}
    classification::Union{Nothing,Symbol} = nothing
    dead::Vector{Tuple{String,Symbol,Symbol}} = Tuple{String,Symbol,Symbol}[]
    traced::Vector{Pair{String,Symbol}} = Pair{String,Symbol}[]
end
path(d::AlgebraicCycle) = first(d.members)

# The cluster read out: its wires as one loop, a dead hop in the ladder's own
# words, and the per-member tracing modes as one phrase (§5.6, D-245).
_wirelist(wires) = join(("$p → $c" for (p, c) in wires), ", ")
_hop((member, face, output_port)) = "`$member`'s `$output_port` does not route `$face`"

function _modes(traced)
    rest = ["`$member` " * (tracing === :sampled ? "at sampled states" : "structurally")
            for (member, tracing) in traced if tracing !== :global]
    isempty(rest) && return "traced globally"
    join(rest, ", ") *
        (any(tracing === :global for (_, tracing) in traced) ? ", the rest globally" : "")
end

# The ladder's two exits (§5.4, D-140), each dead member named once.
_cycle_hint(dead) =
    join((let dead_faces = unique(face for (hop_member, face, _) in dead
                                  if hop_member == member)
              "split `$member`, or narrow the neighbor's contract if $(_namelist(dead_faces)) " *
              (length(dead_faces) == 1 ? "is" : "are") *
              " consumed only in a fallback branch"
          end for member in unique(first.(dead))), "; ") * " (§5.4)"

const _BREAK_CYCLE = "break it with a state, a unit delay or a stage-1 (`output_state`) port (§5.5)"

function message(d::AlgebraicCycle)
    head = "algebraic loop among $(_namelist(d.members)): $(_wirelist(d.wires))"
    d.classification === nothing && return "$head — $_BREAK_CYCLE"
    if d.classification === :real
        sentence = "$head — real: a loop survives the trace ($(_modes(d.traced)))"
        for hop in d.dead
            sentence *= "; $(_hop(hop)), a wire the loop does not need"
        end
        return "$sentence; $_BREAK_CYCLE"
    end
    member_tracing = Dict(d.traced)
    hops = join((_hop(hop) * (get(member_tracing, first(hop), :global) === :sampled ?
                              " (on the sampled paths; an untaken branch may still route it)" :
                              "")
                 for hop in d.dead), ", ")
    "$head — artificial at port level: $hops; $(_cycle_hint(d.dead))"
end

"§4.3, §8.3: one port written by both stages."
Base.@kwdef struct ProducedByTwoStages <: Diagnostic
    path::String
    ports::Vector{Symbol}
end
path(d::ProducedByTwoStages) = d.path
message(d::ProducedByTwoStages) =
    "`$(d.path)`: " *
    join(("`$p` by `output_state` and by `output_direct`" for p in d.ports), ", ") *
    " — a port is produced once: drop it from `output_direct`, or from its stage-1 " *
    "producer (§5.3, §8.3)"

"§8.3: a declared port no stage writes — a cell no one fills, reading as a silent zero."
Base.@kwdef struct DeclaredNotProduced <: Diagnostic
    path::String
    ports::Vector{Symbol}
    products::Vector{Symbol} = Symbol[]      # the stage-product list
    state_fields::Vector{Symbol} = Symbol[]  # the tier's store field names (§5.3)
end
path(d::DeclaredNotProduced) = d.path
message(d::DeclaredNotProduced) =
    "`$(d.path)`: declared port(s) $(_plainlist(d.ports)) produced by no stage — " *
    "`output_state` returns them, or `output_types` drops them (§5.3, §8.3); the stages " *
    "return $(_namelist(d.products)); the state fields are $(_namelist(d.state_fields))"

"§8.3, §8.4 w5: a stage returning a field `output_types` does not declare."
Base.@kwdef struct UndeclaredReturnField <: Diagnostic
    path::String
    stage::String
    name::Symbol
    candidates::Vector{Symbol} = Symbol[]    # `output_types`' keys
end
path(d::UndeclaredReturnField) = d.path
message(d::UndeclaredReturnField) =
    "`$(d.path)`: $(d.stage) returns `$(d.name)`, which `output_types` does not declare — " *
    "declare it, or drop it from the return; the declared ports are $(_namelist(d.candidates))"

"§5.2, §9.3: a stage method that returned bare `(;)`, producing no ports."
Base.@kwdef struct DeadStage <: Diagnostic
    path::String
    stage::String                            # "output_state" | "output_direct"
end
path(d::DeadStage) = d.path
message(d::DeadStage) =
    "$(_at_path(d.path)): `$(d.stage)` returns bare `(;)`, producing no ports — a stage " *
    "that produces nothing computes nothing any consumer can read; return the ports the " *
    "stage owns, or drop the method so the stage is absent (§5.2, §9.3)"

"""
§9.5: the return laws, probed. `shape` names what the return had to be shaped
like and `reason` which half of the law failed — the return's own type, its
field set, or one field's type. `event` is the event name on a handler's
occurrence, at the probe and at run time alike (D-249); the simulation time of
a runtime occurrence rides the `StepError` carrier, never the diagnostic.
"""
Base.@kwdef struct ConformanceFailure <: Diagnostic
    path::String
    what::String                             # the function or stage at fault
    reason::Symbol                           # :return_type | :field_set | :field_type
    shape::Symbol                            # :ports|:namedtuple|:state|:init_x|:init_s|:stores|:mode
    observed::Any = nothing
    declared::Any = nothing
    field::Union{Nothing,Symbol} = nothing
    observed_fields::Vector{Symbol} = Symbol[]
    declared_fields::Vector{Symbol} = Symbol[]
    activation::Any = nothing                # the activation scalar, for the pin hint
    event::Union{Nothing,Symbol} = nothing   # the event, on a handler's occurrence
end
path(d::ConformanceFailure) = d.path

# The function at fault, with its event where it has one: `what` names the
# handler and `event` the occurrence it belongs to, and the two compose here
# rather than at each construction site.
_conformance_what(d::ConformanceFailure) =
    d.event === nothing ? d.what : "event `$(d.event)`'s $(d.what)"

_conformance_expect(shape::Symbol) =
    shape === :ports      ? "must return a NamedTuple of port values" :
    shape === :state      ? "must return a NamedTuple shaped like the state" :
    shape === :init_x     ? "must return a NamedTuple shaped like `init_x`" :
    shape === :init_s     ? "must return a NamedTuple shaped like `init_s`" :
    shape === :stores     ? "must return a NamedTuple of the stores it writes" :
    shape === :mode       ? "must be a NamedTuple" :
                        "must return a NamedTuple"
_conformance_section(shape::Symbol) = (shape === :stores || shape === :mode) ? " (§5.2)" : ""

# §9.5's didactic hint: `0` where a real was declared names the fix outright.
# Otherwise the D-166 pin hint, as `_pin` renders it everywhere else.
_pin(d::ConformanceFailure) =
    d.observed isa Type && d.declared isa Type &&
        d.observed <: Integer && d.declared <: AbstractFloat ?
    " — an integer literal where a real was declared: return `zero(…)` of a value at " *
    "the activation, not `0`" :
    d.declared isa Type && d.observed isa Type && d.activation isa Type ?
    _pin_hint(d.declared, d.observed, d.activation) : ""

function message(d::ConformanceFailure)
    d.reason === :return_type &&
        return "`$(d.path)`: $(_conformance_what(d)) $(_conformance_expect(d.shape)), got $(d.observed)" *
               _conformance_section(d.shape)
    if d.reason === :field_set
        d.shape === :mode &&
            return "`$(d.path)`: $(_conformance_what(d)) writes mode `$(d.field)`, and `init_m` declares " *
                   "$(_symtuple(d.declared_fields)) — `m` is a names-subset write (§5.2)"
        d.shape === :init_s &&
            return "`$(d.path)`: $(_conformance_what(d)) returns $(d.observed), state store is " *
                   "$(d.declared) — a discrete successor is the store's own type exactly (§7.3)"
        d.shape === :init_x &&
            return "`$(d.path)`: $(_conformance_what(d)) returns fields $(_symtuple(d.observed_fields)), " *
                   "state has $(_symtuple(d.declared_fields)) — derivative completeness is " *
                   "structural (§7.1)"
        return "`$(d.path)`: $(_conformance_what(d)) returns fields $(_symtuple(d.observed_fields)), " *
               "state has $(_symtuple(d.declared_fields)) — a state write-back is complete " *
               "against the field set (§9.3, §9.5)"
    end
    d.shape === :ports &&
        return "`$(d.path)`: $(_conformance_what(d)) returns `$(d.field)`::$(d.observed), " *
               "declared $(d.declared)" * _pin(d)
    d.shape === :mode &&
        return "`$(d.path)`: $(_conformance_what(d)) mode `$(d.field)` is $(d.observed), declared " *
               "$(d.declared) (§5.2)"
    d.shape === :init_x &&
        return "`$(d.path)`: derivative field `$(d.field)` is $(d.observed), state field " *
               "is $(d.declared)" * _pin(d)
    "`$(d.path)`: $(_conformance_what(d)) field `$(d.field)` is $(d.observed), state field is " *
    "$(d.declared)" * _pin(d)
end

"§9.5: a guard returning neither of the two admissible forms."
Base.@kwdef struct GuardForm <: Diagnostic
    path::String
    event::Symbol
    observed::Any
end
path(d::GuardForm) = d.path
message(d::GuardForm) =
    "`$(d.path)`: event `$(d.event)`'s guard returns $(d.observed) — a guard is " *
    "`Bool`-valued (boundary-detected) or returns the continuous sign value (localized) " *
    "(§2.1, §10.4)"

"§5.2, §13.2: a bundle field a component function destructured that its bundle does not carry, classified against the legal sets."
Base.@kwdef struct BundleFieldError <: Diagnostic
    path::String
    family::String                           # "output_state" | "output_direct" | "state_derivative" | "state_update" | "guard" | "handler"
    tier::Symbol                             # :continuous | :discrete
    field::Symbol                            # the requested field
    legal::Vector{Symbol}                    # the bundle's own field names, the list in hand
    reason::Symbol                           # :undeclared | :wrong_tier | :illegal_for_family
end
path(d::BundleFieldError) = d.path

# The declaration that would have put the field in the bundle (§5.2's iff
# table). `y_x`/`y_s` name no declaration at all, a stage-1 port being a probe
# discovery. That arm gets its own sentence below.
_bundle_declaration(field::Symbol) =
    field === :x  ? "init_x"  : field === :s ? "init_s" : field === :m ? "init_m" :
    field === :ws ? "init_workspace" : field === :u ? "input_types" :
    field === :y  ? "output_types" : ""

function message(d::BundleFieldError)
    head = "$(_at_path(d.path)): `$(d.family)` destructures `$(d.field)`"
    tail = " — the bundle carries $(_faceset(d.legal)) (§5.2"
    if d.reason === :undeclared
        decl = _bundle_declaration(d.field)
        return head * ", but " * _at_path(d.path) *
               (isempty(decl) ? " produces no stage-1 port" : " declares no `$decl`") *
               tail * ")"
    end
    d.reason === :wrong_tier &&
        return head * ", a $(d.tier === :continuous ? "discrete" : "continuous")-tier fact, " *
               "and $(_at_path(d.path)) is $(d.tier)" * tail * ", D-195)"
    head * ", which no `$(d.family)` bundle carries on the $(d.tier) tier" * tail * ")"
end

"§5.2, §9.5: a handler key naming no store the component declares."
Base.@kwdef struct HandlerReturnKey <: Diagnostic
    path::String
    event::Symbol
    key::Symbol
    stores::Vector{Symbol} = Symbol[]        # `{x, m}` narrowed to what exists
end
path(d::HandlerReturnKey) = d.path
message(d::HandlerReturnKey) =
    "`$(d.path)`: event `$(d.event)`'s handler returns `$(d.key)` — a handler's keys name " *
    "the stores it writes, and this component's are " *
    (isempty(d.stores) ? "none" : _namelist(d.stores)) * " (§5.2)"

"§13.2, D-248: a throw out of a user-authored method the build invoked, framed with where it ran."
Base.@kwdef struct UserCodeFraming <: Diagnostic
    path::String = ""                        # empty until the component frame fills it
    fn::String                               # the method's name
    bundle::Vector{Symbol} = Symbol[]        # the bundle's field names; empty for a declaration
    inputs::String = ""                      # the synthesized inputs as a spelling; empty without `u`
    cause::Exception
end
path(d::UserCodeFraming) = d.path

# The frame first, the raw throw second: the didactic sentence says where the
# code ran, and `showerror` on the cause says what it said (§13.2).
function message(d::UserCodeFraming)
    head = isempty(d.bundle) ?
        "$(_at_path(d.path)): `$(d.fn)` threw while the build read its declarations (§13.2)" :
        "$(_at_path(d.path)): `$(d.fn)` threw during the build's probe — bundle " *
        _faceset(d.bundle) * (isempty(d.inputs) ? "" : ", inputs $(d.inputs)") * " (§13.2)"
    head * "\n  cause: " * sprint(showerror, d.cause)
end

# ==============================================================================
# Deployment, periphery and services (§9.1, §11, §12, §13.5, §14)
# ==============================================================================

"§12.6: an advance entry called before boundary zero has completed."
Base.@kwdef struct MissingInit <: Diagnostic
    op::Symbol                               # the entry point called
    status::Symbol                           # the simulation's status
end
message(d::MissingInit) =
    "`$(d.op)` before `init!`: boundary zero has not completed and this simulation is " *
    "`$(d.status)` — `init!` is mandatory (§12.6)"

# §12.6's legality table and §11.3's sentence, as the lists a refusal carries.
# The advance entries admit `:initialized` alone; a reader admits every status
# but `:running`; a stopped-sim operation adds `:errored` to the refusals
# (D-232). `capture` narrows further and names its own list at the site. Each is
# an immutable tuple and every site fills the payload through `collect`, so no
# two refusals share one mutable list.
const ADVANCE_LEGAL = (:initialized,)
const READER_LEGAL = (:built, :initialized, :stopped, :errored)
const STOPPED_SIM_LEGAL = (:built, :initialized, :stopped)

"§11.3, §14: a service call against a lifecycle status that does not admit it."
Base.@kwdef struct ServiceLifecycle <: Diagnostic
    op::Symbol
    status::Symbol
    legal::Vector{Symbol}                    # the statuses that admit the operation
end

# `:running` refuses two different operations, and the sentence differs: an
# advance entry is refused *because the loop is already advancing*, while every
# other refusal at this status is a stopped-sim operation meeting a running loop.
_advance_entry(op::Symbol) = op === :run! || op === :step!

message(d::ServiceLifecycle) =
    d.status === :running ?
    (_advance_entry(d.op) ?
     "`$(d.op)`: the simulation is already running — one advance owns the stores between " *
     "drains, and a second one from another thread would race it (§12.6)" :
     "`$(d.op)` is a stopped-sim operation and the simulation is running — the roster is " *
     "frozen per run and the loop owns the stores between drains (§11.3, §12.5, §12.6)") :
    d.status === :errored ?
    "`$(d.op)` on a simulation that ended `errored` — terminally stopped, never resumable " *
    "or re-initialized; reproduction is replaying its trace on a fresh `Simulation` " *
    "(§13.6, §12.7)" :
    d.status === :stopped ?
    "`$(d.op)` on a stopped simulation: re-running is the `stopped → init! → run!` cycle " *
    "— `init!` re-runs boundary zero and opens a fresh trajectory (§12.6)" :
    "`$(d.op)` is legal in $(_namelist(d.legal)), and this simulation is `$(d.status)` " *
    "(§12.6, §14)"

"§13.5: a `stop_on` name that is no root-exported `Bool` output face."
Base.@kwdef struct StopFaceInvalid <: Diagnostic
    face::Symbol
    reason::Symbol                           # :unknown | :root_input | :not_bool
    site::Symbol                             # :run! | :replay! | :step!
    declared::Any = nothing                  # the declared type, for :not_bool
    candidates::Vector{Symbol} = Symbol[]    # the root output-face list
end

# The binding site the name came from (§13.5, §12.7, D-249): the advance that
# declared it — `run!`, `replay!` or `step!` (D-255).
_stop_site(site::Symbol) = "`$(site)`'s `stop_on`"

message(d::StopFaceInvalid) =
    d.reason === :unknown ?
    "$(_stop_site(d.site)) names `$(d.face)`, which is no root face — a stop face is a " *
    "root-exported Bool output face, and this model exports $(_namelist(d.candidates)) (§13.5)" :
    d.reason === :root_input ?
    "$(_stop_site(d.site)) names `$(d.face)`, a root input — a stop face is a root-exported " *
    "*output*: the model detects and exports the condition, and the deployment names it (§13.5)" :
    "$(_stop_site(d.site)) names `$(d.face)`, whose declared type is $(d.declared) — stop " *
    "faces are Bool, OR-combined (§13.5)"

# --- the grid attribution (§9.2, D-187) -----------------------------------------
# Deployment substrate rather than diagnostics: `deployment.jl`'s `_grid_report`
# is what fills these two, and the `Deployment` carries one. They are defined
# here because the two payloads below name them and this file is included first.

"""
One constraint-pool entry (§9.1, §9.2): an anchor's period or its nonzero offset,
with the scope path and key of the `sample_times` entry that declared the
anchor, its leave-one-out refinement factor `r_p = gcd(pool ∖ p) / gcd(pool)`
and, for an offset that drives, the nearest offsets on the grid the rest of
the pool supports.
"""
struct GridEntry
    kind::Symbol                          # :period | :offset
    value::Rational{Int}
    scope::String                         # the anchor's declaring scope path
    key::Symbol                           # the anchor's declaring key
    factor::Int                           # r_p ≥ 1
    alternatives::Vector{Rational{Int}}   # a driving offset's nearest non-refining neighbours; else empty
end

# The anchor's declaring entry, as every grid consumer names it.
_anchor_label(scope::String, key::Symbol) =
    "`sample_times` at $(_at_path(scope)), key `$key`"

"""
The grid attribution (§9.2, D-187): the pool, the coarsest admissible `Δt_base`
and each prime power of its denominator traced to the entries supplying it. A
pure function of the structure's anchors, printed by the refusal path's
suggestion and the derivation path's line alike.
"""
struct GridReport
    pool::Vector{GridEntry}
    admissible::Union{Nothing,Rational{Int}}   # gcd(pool); nothing for an empty pool
    primes::Vector{@NamedTuple{prime::Int, power::Int, suppliers::Vector{Int}}}  # indices into pool
end

"§9.1: a deployment parameter outside its constraint, or a grid that does not close."
Base.@kwdef struct DeploymentInvalid <: Diagnostic
    parameter::Symbol
    reason::Symbol   # :range|:inexact|:not_a_quantity|:missing|:unanchored|:no_constraint|:not_harmonic|:disagrees_with_n|:anchor_period|:anchor_offset
    value::Any = nothing
    related::Any = nothing                   # the value it is measured against
    quotient::Union{Nothing,Int} = nothing   # Δt_base / h, where that is the fact
    paths::Vector{String} = String[]         # the unanchored components
    scope::String = ""                       # the anchor's declaring scope path, on the two anchor arms
    key::Union{Nothing,Symbol} = nothing     # the anchor's declaring key, on the two anchor arms
    grid::Union{Nothing,GridReport} = nothing   # the attribution, on the three grid refusals
end

# The parameter set is Appendix C's row: deployment parameters alone. The
# materialization's keyword and the doors' recording keywords validate under
# `ArgumentInvalid` (D-256, D-261), and their constraint text and section moved
# with them.
_deployment_constraint(parameter::Symbol) =
    parameter === :algorithm           ? "must be a stepper type — RK4 or Heun" :
    parameter === :firing_budget       ? "must be an integer ≥ 1" :
    parameter === :localization_tol    ? "must be a positive real" :
    parameter === :localization_budget ? "must be an integer ≥ 1" :
    parameter === :h                   ? "must be positive" :
    parameter === :N_base              ? "must be an integer ≥ 1" :
                                 "is outside its constraint"
_deployment_section(parameter::Symbol) =
    parameter === :algorithm           ? " (§10.2)" :
    parameter === :firing_budget       ? " (§10.6)" :
    (parameter === :localization_tol || parameter === :localization_budget) ? " (§10.4)" :
    parameter === :N_base              ? " (§9.1)" : ""

# The grid block (§9.2, D-187), appended to the first line of every consumer that
# names the grid: the three grid refusals, the derivation path's info line and
# the `GridUtilization` advisory. Its rows are the admissible set with the
# coarsest value; the pool table, every entry and not only the drivers, since a
# ×1 beside a ×10 tells the reader which entry is innocent, with a driving
# offset's repair on its row's tail; and the prime attribution, one prime power
# per row naming its suppliers. The block indents two spaces, its rows four. An
# empty pool renders no block.
const _SUPERSCRIPTS = collect("⁰¹²³⁴⁵⁶⁷⁸⁹")
_superscript(power::Int) = power == 1 ? "" : join(_SUPERSCRIPTS[c - '0' + 1] for c in string(power))

# A supplier's short label: the anchor's declaring key and the entry's kind.
_grid_label(entry::GridEntry) = "$(entry.key) $(entry.kind)"

function _grid_block(grid::Union{Nothing,GridReport})
    (grid === nothing || grid.admissible === nothing) && return ""
    labels = [_anchor_label(e.scope, e.key) for e in grid.pool]
    kind_values = ["$(e.kind) $(e.value)" for e in grid.pool]
    factors = ["×$(e.factor)" for e in grid.pool]
    label_width, kind_value_width, factor_width =
        maximum(textwidth, labels), maximum(textwidth, kind_values), maximum(textwidth, factors)
    rows = ["  admissible: gcd(pool)/k, coarsest $(grid.admissible)", "  pool:"]
    for (i, entry) in enumerate(grid.pool)
        row = "    " * rpad(labels[i], label_width) * "  " * rpad(kind_values[i], kind_value_width) *
              "  " * rpad(factors[i], factor_width)
        isempty(entry.alternatives) ||
            (row *= "  declaring " * join(entry.alternatives, " or ") *
                    " keeps $(entry.factor * grid.admissible)")
        push!(rows, rstrip(row))
    end
    # A whole-second grid has no prime to attribute, so the section is absent.
    prime_powers = ["$(p.prime)$(_superscript(p.power))" for p in grid.primes]
    isempty(prime_powers) ||
        push!(rows, "  primes: $(denominator(grid.admissible)) = " *
                    join(prime_powers, "·"))
    for (i, attribution) in enumerate(grid.primes)
        push!(rows, "    " *
                    rpad(prime_powers[i], maximum(textwidth, prime_powers)) * "  " *
                    join((_grid_label(grid.pool[j]) for j in attribution.suppliers), ", "))
    end
    "\n" * join(rows, "\n")
end

function message(d::DeploymentInvalid)
    d.reason === :inexact &&
        return "`$(d.parameter)` must be exact — a Rational (`$(d.parameter) = 1//100`) or " *
               "a `Period`/`Hz` value: grid derivation is GCD arithmetic, ill-defined over " *
               "floats (§9.1, §10.5)"
    d.reason === :not_a_quantity &&
        return "`$(d.parameter)` must be a Rational or a `Period`/`Hz` value, got $(d.value)"
    d.reason === :missing &&
        return "deployment needs the continuous step: `Simulation(…; h = 1//100)` — a " *
               "domain rate is not a framework default (§9.1)"
    d.reason === :unanchored &&
        return "Δt_base cannot be derived: `$(join(d.paths, "`, `"))` is/are unanchored, " *
               "with period `m·Δt_base` — an anchor edit anywhere in the tree would " *
               "silently rescale it. Declare the base tick period instead: `Δt_base = …`, " *
               "or `N_base = …` (§9.1)" * _grid_block(d.grid)
    d.reason === :no_constraint &&
        return "Δt_base cannot be derived: no anchor declares a constraint to derive it " *
               "from (§9.1)"
    d.reason === :not_harmonic &&
        return "harmonic grid: Δt_base = $(d.value) is not an integer multiple of " *
               "h = $(d.related) (Δt_base = N_base·h, N_base ≥ 1, §10.5)"
    d.reason === :disagrees_with_n &&
        return "Δt_base = $(d.value) disagrees with N_base = $(d.related): Δt_base/h = " *
               "$(d.quotient) (§9.1)"
    d.reason === :anchor_period &&
        return "$(_anchor_label(d.scope, d.key)): period $(d.value) is not an integer " *
               "multiple of Δt_base = $(d.related) (§9.1)" * _grid_block(d.grid)
    d.reason === :anchor_offset &&
        return "$(_anchor_label(d.scope, d.key)): offset $(d.value) does not land on the " *
               "base grid at Δt_base = $(d.related) (§9.1)" * _grid_block(d.grid)
    "`$(d.parameter)` $(_deployment_constraint(d.parameter)), got $(d.value)" *
    _deployment_section(d.parameter)
end

"§9.1, §9.2: the derived grid is finer than the fastest declared work."
Base.@kwdef struct GridUtilization <: Diagnostic
    Δt_base::Rational{Int}
    utilization::Int                     # min_i Dᵢ over the discrete rows
    fastest::String                      # the path attaining it
    grid::GridReport                     # the attribution the block renders
end
severity(::GridUtilization) = :warning
message(d::GridUtilization) =
    "Δt_base derived as $(d.Δt_base) s: the grid is $(d.utilization)× finer than the " *
    "fastest declared work (`$(d.fastest)` at D = $(d.utilization)) (§9.2)" * _grid_block(d.grid)

"§11.3: a claim naming no root input face."
Base.@kwdef struct AttachUnknownFace <: Diagnostic
    device::String                           # the device type, admission not yet reached
    binding::String                          # the binding type, as a string
    face::Symbol
    candidates::Vector{Symbol} = Symbol[]    # the root input-face list
end
message(d::AttachUnknownFace) =
    "$(d.device)'s $(d.binding) claims `$(d.face)`, which names no root input face — the " *
    "root faces are $(_faceset(d.candidates)) (§11.3)"

"§11.3: the same device instance offered to `attach!` twice."
Base.@kwdef struct AlreadyAttached <: Diagnostic
    device::String                           # the candidate's type, as a string
    incumbent::String                        # the existing roster entry's device id
    binding::String                          # the incumbent's binding type
end
message(d::AlreadyAttached) =
    "this $(d.device) instance is already rostered as $(d.incumbent) under $(d.binding) — " *
    "rebinding is spelled `detach!` then `attach!` (§11.3)"

"§11.1, §11.3: two devices claiming the calling task, a single-slot resource."
Base.@kwdef struct CallerTaskConflict <: Diagnostic
    device::String
    incumbent::String
end
message(d::CallerTaskConflict) =
    "$(d.device) declares `needs_calling_task`, and $(d.incumbent) already holds the " *
    "calling task (§11.1, §11.3)"

"§11.3: one root input face claimed by two devices."
Base.@kwdef struct ClaimConflict <: Diagnostic
    face::Symbol
    device::String
    incumbent::String
end
message(d::ClaimConflict) =
    "`$(d.face)` is claimed by both $(d.device) and $(d.incumbent) — one writer per root " *
    "input at any time (§11.3)"

"§11.3, §11.6: a greedy binding whose computed complement was empty — every face already claimed."
Base.@kwdef struct EmptyGreedyClaim <: Diagnostic
    device::String
    binding::String
end
severity(::EmptyGreedyClaim) = :warning
message(d::EmptyGreedyClaim) =
    "$(d.device) under $(d.binding) staked the empty remainder — every root input face is " *
    "already claimed (§11.6)"

"§11.6: a binding whose traits and whose methods disagree, in either direction."
Base.@kwdef struct BindingContractMismatch <: Diagnostic
    binding::String                          # the binding type, by name (§13.2)
    reason::Symbol   # :claims_missing|:reads_missing|:greedy_without_input|:neither_side|
                     # :greedy_with_claims|:claims_without_input|:reads_without_output|
                     # :reads_not_namedtuple|:reads_not_selectors
    observed::Any = nothing                  # what `reads` returned, where that is the fact
end
function message(d::BindingContractMismatch)
    d.reason === :claims_missing &&
        return "$(d.binding) declares an input side and defines no `claims` enumeration — " *
               "the enumeration is the interface (§11.6)"
    d.reason === :reads_missing &&
        return "$(d.binding) declares an output side and defines no `reads` enumeration — " *
               "the enumeration is the interface (§11.6)"
    d.reason === :greedy_without_input &&
        return "$(d.binding) declares `is_greedy` without `is_input` — greediness is a " *
               "claim source within the input side, and a source without its side is " *
               "meaningless (§11.6)"
    d.reason === :neither_side &&
        return "$(d.binding) declares neither side — a binding that touches nothing is a " *
               "configuration mistake, not a degenerate (§11.6)"
    d.reason === :greedy_with_claims &&
        return "$(d.binding) declares `is_greedy` and defines its own `claims` — the two " *
               "claim sources are alternatives, not layers (§11.6)"
    d.reason === :claims_without_input &&
        return "$(d.binding) defines `claims` while `is_input` reads false — a method " *
               "written and never reached is exactly the drift this check catches (§11.6)"
    d.reason === :reads_without_output &&
        return "$(d.binding) defines `reads` while `is_output` reads false — a method " *
               "written and never reached is exactly the drift this check catches (§11.6)"
    d.reason === :reads_not_namedtuple &&
        return "$(d.binding)'s `reads` must return a NamedTuple of labeled selectors — " *
               "(; label = get_output(...), ...) — got $(d.observed) (§11.6, §14.4)"
    "$(d.binding)'s `reads` entries must be read selectors — get_output, get_input or " *
    "get_face (§14.4) — got $(d.observed)"
end

"§11.6: the device twin of `BindingContractMismatch` — no `loop` method, `gather` against a binding with no output side, or a write through a detached handle (D-244)."
Base.@kwdef struct DeviceContractMismatch <: Diagnostic
    device::String                           # the device type, or the roster id where that is what the site holds
    reason::Symbol                           # :no_loop | :no_output_side | :detached
end
function message(d::DeviceContractMismatch)
    d.reason === :no_loop &&
        return "$(d.device) defines no `loop` method — the task body is the authoring " *
               "contract's one mandatory function (§11.6)"
    d.reason === :detached &&
        return "$(d.device) was detached — its handle's `stage!` and `report!` have no " *
               "roster entry to reach, and rebinding is spelled `attach!` (§11.6, D-244)"
    "$(d.device)'s binding declares no output side — `gather` serves the compiled " *
    "`reads` enumeration (§11.6)"
end

"§11.2, §14.4: a binding read that does not resolve against the published snapshot."
Base.@kwdef struct ReadBindingUnresolved <: Diagnostic
    device::String                           # the device type, admission not yet reached
    binding::String                          # the binding type, by name (§13.2)
    selector::String                         # the selector as authored
    reason::Symbol   # :store_selector|:indexed|:unknown_cell|:unknown_root_input|
                     # :root_input_not_output|:unknown_output_face
    path::String = ""
    field::Union{Nothing,Symbol} = nothing
    candidates::Vector{Symbol} = Symbol[]
end
path(d::ReadBindingUnresolved) = d.path
function message(d::ReadBindingUnresolved)
    d.reason === :store_selector &&
        return "$(d.device)'s $(d.binding) reads $(d.selector), a *store* selector — the " *
               "store selectors resolve only against live stores, and a binding reads a " *
               "published snapshot, which deliberately carries none (§14.4, §11.2). The " *
               "remedy is to declare the field public and read the port published from it"
    d.reason === :indexed &&
        return "$(d.device)'s $(d.binding) reads $(d.selector) — a binding read is a whole " *
               "cell, and sub-cell index addressing is absent in a binding read " *
               "(§14.4, docs/design/pending.md)"
    d.reason === :unknown_cell &&
        return "$(d.device)'s $(d.binding) reads $(d.selector), which names no cell — " *
               (isempty(d.candidates) ?
                "$(_at_path(d.path)) has no cells; only declared outputs, assembly " *
                "faces and root inputs are addressable" :
                "the cells at $(_at_path(d.path)) are $(_faceset(d.candidates))") * " (§14.4)"
    d.reason === :unknown_root_input &&
        return "$(d.device)'s $(d.binding) reads $(d.selector), which names no root input " *
               "face — the root inputs are $(_faceset(d.candidates)) (§14.4)"
    d.reason === :root_input_not_output &&
        return "$(d.device)'s $(d.binding) reads $(d.selector), which names a root *input* " *
               "face — the integration reads are the exported output faces, and a root " *
               "input is read back with get_input (§14.4, §11.2)"
    "$(d.device)'s $(d.binding) reads $(d.selector): `$(d.field)` is no root-exported " *
    "output face — the output faces are $(_faceset(d.candidates)) (§14.4, §11.2)"
end

"§14.2, §14.3: a condition leaf that does not resolve against this build."
Base.@kwdef struct ConditionResolution <: Diagnostic
    path::String = ""
    store::Symbol = :input                   # :x | :s | :m | :input
    field::Symbol
    reason::Symbol   # :assembly_path|:unexported_face|:no_input_face|
                     # :internally_wired|:no_store|:undeclared_field|:unconvertible
    face::Union{Nothing,Symbol} = nothing    # the root input the chain lands on
    origin::String = ""                      # the tree's chain to this value
    candidates::Vector{Symbol} = Symbol[]
    declared::Any = nothing                  # the declared leaf type
    observed::Any = nothing                  # the authored value's type
    value::Any = nothing
    tier::Union{Nothing,Symbol} = nothing
    role::Union{Nothing,Symbol} = nothing    # :output_port | :input_face | :workspace
    producer::Union{Nothing,Tuple{String,Symbol}} = nothing
    activation::Any = nothing                # set when this is the seeded activation's refusal
end
path(d::ConditionResolution) = d.path

_cleaf(d) = d.face !== nothing ? "root input `$(d.face)`" :
            d.store === :input ? "input face `$(d.field)` of $(_at_path(d.path))" :
                                 "`$(d.store).$(d.field)` at $(_at_path(d.path))"
_ctail(d) = " (§14.3) [$(d.origin)]"
_role_word(role) = role === :output_port ? "an output port" :
                role === :input_face  ? "an input face" : "a workspace entry"

function message(d::ConditionResolution)
    d.reason === :assembly_path &&
        return "the condition addresses $(_at_path(d.path)), which is an assembly — " *
               "assemblies own no state, and a condition addresses components and root " *
               "inputs (§14.1, §8.5) [$(d.origin)]"
    d.reason === :unexported_face &&
        return "`$(d.field)` is no root input face — the root's inputs are " *
               "$(_namelist(d.candidates)) (§14.2) [$(d.origin)]"
    d.reason === :no_input_face &&
        return "$(_at_path(d.path)) declares no input face `$(d.field)` " *
               "— its input faces are $(_namelist(d.candidates)) (§14.2) " *
               "[$(d.origin)]"
    d.reason === :internally_wired &&
        return "$(_at_path(d.path))'s input face `$(d.field)` reaches no " *
               "root input — it is wired internally, to `$(first(d.producer))`." *
               "$(last(d.producer)), and " *
               "the first sweep overwrites it; unexported stays unpokeable (§14.2) " *
               "[$(d.origin)]"
    d.reason === :no_store &&
        return "$(_cleaf(d)) — $(_at_path(d.path)) is a $(d.tier) " *
               "component and declares " *
               "no `init_$(d.store)`" *
               (d.store === :x && d.tier === :discrete ?
                "; the discrete tier's state is `s` (D-195)" :
                d.store === :s && d.tier === :continuous ?
                "; the continuous tier's state is `x` (D-195)" :
                d.store === :m ?
                "; modes are declared by `init_m`, continuous-only (§3.2)" : "") *
               _ctail(d)
    d.reason === :undeclared_field &&
        return "$(_cleaf(d)) is not declared — `init_$(d.store)` at " *
               "$(_at_path(d.path)) " *
               "declares $(_namelist(d.candidates))" *
               (d.role === nothing ? "" :
                "; `$(d.field)` is $(_role_word(d.role)), and a condition " *
                "specifies state, " *
                "modes and root inputs — never outputs, never workspace (§14.1)") *
               _ctail(d)
    "$(_cleaf(d)) takes $(d.declared), and the authored value is " *
    "$(repr(d.value))::$(d.observed), which does not convert" *
    (d.activation === nothing ? "" :
     "; this is the seeded activation's own refusal — a value at $(d.activation) " *
     "is a decision variable and this leaf is pinned, and a decision variable descends into " *
     "neither a frozen discrete `s` nor a pinned leaf (§14.3, §9.4)") * _ctail(d)
end

"§14.2: one leaf written by two fragments of a `combine` — collision-intolerant by design."
Base.@kwdef struct DuplicateConditionLeaf <: Diagnostic
    path::String = ""
    store::Symbol = :input
    field::Symbol
    face::Union{Nothing,Symbol} = nothing
    origins::Vector{String} = String[]       # both chains
end
path(d::DuplicateConditionLeaf) = d.path
_origin(d, ordinal) = ordinal ≤ length(d.origins) ?
                         d.origins[ordinal] : "an undetermined declaration"
message(d::DuplicateConditionLeaf) =
    "$(_cleaf(d)) is written twice — by $(_origin(d, 1)), and by " *
    "$(_origin(d, 2)). `combine` " *
    "is collision-intolerant by design — use `override(base, patch)` to layer (§14.2, §14.6)"

"§14.2: a value handed to a condition combinator that is not a condition node."
Base.@kwdef struct ConditionNodeMisuse <: Diagnostic
    observed::Any                            # the offending argument's type
    reason::Symbol = :not_a_node             # :not_a_node | :fragment_payload
    payload::Union{Nothing,Symbol} = nothing # which `fragment` payload, for :fragment_payload
    in_hand::Vector{Symbol} = Symbol[]       # the node kinds in hand
end
message(d::ConditionNodeMisuse) =
    d.reason === :fragment_payload ?
    "`fragment`'s `$(d.payload)` payload is $(d.observed) — every payload is a NamedTuple " *
    "of the authoring level's own names (§14.2)" :
    "$(d.observed) is not a condition node" *
    (isempty(d.in_hand) ? "" :
     ", and the node kind(s) in hand are $(_plainlist(d.in_hand))") *
    " — wrap the NamedTuple in `fragment(…)`, or in `at(prefix, fragment(…))`, and " *
    "combine nodes with nodes (§14.2)"

"§14.6: an application whose condition leaves a root input with no value — nothing is written."
Base.@kwdef struct UninitializedInputs <: Diagnostic
    op::Symbol
    faces::Vector{Symbol}                    # every uncovered root face, in declaration order
end
message(d::UninitializedInputs) =
    "the condition given to `$(d.op)` covers no value for root input(s) " *
    "$(_namelist(d.faces)) — root inputs are the one initialized datum with no declared " *
    "default (§11.3), so an application establishing a complete world authors every one of " *
    "them; nothing was written (§14.6, D-068)"

"§14.10: a read selector that does not resolve against this build."
Base.@kwdef struct TapResolution <: Diagnostic
    label::Symbol                            # the read's label in the set
    selector::String                         # the selector as authored
    reason::Symbol   # :assembly_path|:scalar_index|:undeclared|:discrete_deriv|
                     # :unknown_root_input|:root_input_not_face|:unknown_output_face
    tap::Union{Nothing,Symbol} = nothing     # :x | :u | :y
    path::String = ""
    field::Union{Nothing,Symbol} = nothing
    index::Union{Nothing,Int} = nothing
    declares::Union{Nothing,Symbol} = nothing  # :state_field | :output_port
    declared::Any = nothing
    candidates::Vector{Symbol} = Symbol[]
end
path(d::TapResolution) = d.path

_tap_noun(declares) = declares === :output_port ? "output port" : "state field"

# The tap set and the index come off the selector's own kind, so every arm has
# them and the shared prefix shows them: which of `x`/`u`/`y` the read addresses
# is §14.10's payload, and the index is the coordinate the author wrote.
_tap_violation(d, what) =
    "the read labeled `$(d.label)` is $(d.selector)" *
    (d.tap === nothing ? "" :
     " (tap `$(d.tap)`" * (d.index === nothing ? "" : ", index $(d.index)") * ")") *
    ", and $what (§14.4)"

function message(d::TapResolution)
    d.reason === :assembly_path &&
        return _tap_violation(d, "$(_at_path(d.path)) is an assembly — a path selector addresses " *
                           "a component's own declarations, and a root-exported face is " *
                           "read with `get_face`")
    d.reason === :scalar_index &&
        return _tap_violation(d, "the leaf it names is declared $(d.declared) — a scalar has no " *
                           "index, and `i` addresses a component of a vector leaf")
    d.reason === :discrete_deriv &&
        return _tap_violation(d, "$(_at_path(d.path)) is a discrete component — a discrete `s` " *
                           "has no derivative, and `ẋ` exists on the continuous tier alone " *
                           "(§7.1, D-195)")
    d.reason === :undeclared &&
        return _tap_violation(d, "$(_at_path(d.path)) declares no $(_tap_noun(d.declares)) " *
                           "`$(d.field)` — its $(_tap_noun(d.declares)) names are " *
                           "$(_namelist(d.candidates))")
    d.reason === :unknown_root_input &&
        return _tap_violation(d, "`$(d.field)` is no root input face — the root's inputs are " *
                           "$(_namelist(d.candidates))")
    d.reason === :root_input_not_face &&
        return _tap_violation(d, "`$(d.field)` is a root *input* face — the integration reads " *
                           "are the root-exported output faces, and a root input is read " *
                           "back with `get_input`")
    _tap_violation(d, "`$(d.field)` is no root-exported output face — the root exports " *
                "$(_namelist(d.candidates))")
end

"§14.7, §14.8: a `TrimProblem` field that does not meet the problem's closed shape."
Base.@kwdef struct TrimProblemInvalid <: Diagnostic
    field::Symbol
    reason::Symbol   # :not_a_namedtuple|:key_set|:field_types|:inverted_box|
                     # :nonpositive_tolerance|:not_a_read_set
    observed::Any = nothing
    names::Vector{Symbol} = Symbol[]         # the names in hand
    expected::Vector{Symbol} = Symbol[]      # the names it has to match
    key::Union{Nothing,Symbol} = nothing     # the offending decision or residual
    value::Any = nothing
    bound::Any = nothing
    bad::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]   # field => observed type
end

_trim_shape(field::Symbol) =
    field === :tolerances ?
        "the per-residual convergence test is an all-`Float64` NamedTuple" :
    field === :residuals ?
        "the residual system is a NamedTuple of named equations, " *
        "same-named as `tolerances`" :
        "the decisions and their two bounds are same-named all-`Float64` " *
        "NamedTuples"
_trim_floats(field::Symbol) =
    field === :tolerances ?
        "a tolerance is a `Float64` in its residual's own physical units" :
        "decisions and bounds are `Float64`"
_trim_verb(field::Symbol) = field === :residuals ? "returned" : "is"
_trim_bad(d) = join(("`$k`::$v" for (k, v) in d.bad), ", ")

function message(d::TrimProblemInvalid)
    d.reason === :not_a_read_set &&
        return "`reads` is $(d.observed) — the declared read set is a `reads(…)` value: " *
               "reads(name = get_deriv(\"path\", :field), …) (§14.4)"
    d.reason === :not_a_namedtuple &&
        return "`$(d.field)` $(_trim_verb(d.field)) $(d.observed) — $(_trim_shape(d.field)) " *
               "(§14.7)"
    d.reason === :key_set &&
        return d.field === :residuals ?
               "`residuals` returns $(_namelist(d.names)) and `tolerances` names " *
               "$(_namelist(d.expected)) — the two share one key set, and order is never a " *
               "mismatch (§14.7)" :
               "`$(d.field)` names $(_namelist(d.names)) and `guess` names " *
               "$(_namelist(d.expected)) — the three share one key set, a permuted " *
               "spelling pairing by name (§14.7)"
    d.reason === :field_types &&
        return d.field === :residuals ?
               "`residuals` field(s) $(_trim_bad(d)) — each residual is a real scalar (§14.7)" :
               "`$(d.field)` field(s) $(_trim_bad(d)) — $(_trim_floats(d.field)) (§14.7)"
    d.reason === :inverted_box &&
        return "`lower` names `$(d.key)` = $(d.value) above `upper`'s $(d.bound) — a " *
               "decision's box is `lower ≤ upper`, and an inverted pair admits no point at " *
               "all (§14.7)"
    "`tolerances` names `$(d.key)` = $(d.value) — a tolerance is finite and strictly " *
    "positive: it is the half-width of the box its residual has to sit in, and the " *
    "normalized acceptance test divides by it (§14.7)"
end

"§14.8: boundary zero fired events at the commit, moving the committed stores off the solved point."
Base.@kwdef struct TrimCommitEvents <: Diagnostic
    events::Vector{Tuple{String,Symbol}}     # component path and event name
end
severity(::TrimCommitEvents) = :warning
message(d::TrimCommitEvents) =
    "boundary zero fired " *
    join(("`$p`.$n" for (p, n) in d.events), ", ") * " at the commit — a handler that " *
    "fires there moves the committed stores off the solved point, and the committed-state " *
    "residuals are where they actually sit (§14.5, §14.8)"

"§14.8: a converged solve whose committed-state residuals leave the box."
Base.@kwdef struct TrimCommitResiduals <: Diagnostic
    residuals::Vector{Tuple{Symbol,Float64,Float64}}   # name, committed value, tolerance
end
severity(::TrimCommitResiduals) = :warning
message(d::TrimCommitResiduals) =
    "this solve converged, and the residuals re-gathered after the commit leave the box: " *
    join(("`$k` = $v against $tolerance" for (k, v, tolerance) in d.residuals), ", ") *
    " — the mover is " *
    "boundary zero's `state_projection` or a commit-fired handler, and the verdict is not " *
    "re-litigated: it gated the commit, at the solved point (§14.5, §14.8)"

"§14.4: a condition tree whose shape differs from the one its plan was compiled from."
Base.@kwdef struct ConditionShapeDrift <: Diagnostic
    reason::Symbol                           # :tree_type | :prefix
    compiled::Any = nothing                  # the compiled tree type, or the compiled prefix
    observed::Any = nothing
    position::Union{Nothing,Tuple} = nothing # the node position, for :prefix
end

_drift_position(node_position::Tuple) =
    "(" * join((segment isa Symbol ? ".$segment" : "[$segment]" for segment in node_position), "") *
    ")"

message(d::ConditionShapeDrift) =
    d.reason === :prefix ?
    "the `at` prefix at tree position $(_drift_position(d.position)) was " *
    "$(repr(d.compiled)) when this plan was compiled and is $(repr(d.observed)) now — " *
    "prefixes are runtime `String` fields the tree type cannot carry, so the specialized " *
    "`apply!` closes the shape with a `===` sweep over them, and a condition function has " *
    "to return one shape for every decision it is evaluated at (§14.4, §9.5, D-066)" :
    "this plan was compiled from a condition tree of type\n    $(d.compiled)\nand the tree " *
    "handed to `apply!` is\n    $(d.observed)\nThe specialized `apply!` proves the shape " *
    "by dispatch, so a condition function has to return one shape for every decision it is " *
    "evaluated at — a branch that authors a different field set, a different nesting or a " *
    "different leaf type is a different shape, and needs its own plan (§14.4, §9.5, D-066)"

"§8.7, §11.6, §12.4, §12.6, §14.7, D-215: an argument outside its constraint — `DeploymentInvalid`'s twin off the deployment surface."
Base.@kwdef struct ArgumentInvalid <: Diagnostic
    call::Symbol                             # :Simulation|:init!|:Period|:Hz|:Absolute|:step!|:run!|:replay!|:live!|:trim!|:trace|:TableBinding|:selector
    reason::Symbol
    argument::Union{Nothing,Symbol} = nothing
    value::Any = nothing
    entry::Union{Nothing,Symbol} = nothing   # the `TableBinding` entry at fault
    vocabulary::Vector{Symbol} = Symbol[]    # the legal entry keys
end

function message(d::ArgumentInvalid)
    d.reason === :inexact &&
        return d.call === :Period ?
               "a period is an exact Rational — write `Period(1//50)`, not $(repr(d.value)): " *
               "grid derivation is GCD arithmetic (§10.5)" :
               d.call === :Hz ?
               "a frequency is an exact Rational — write `Hz(1//2)` for 0.5 Hz, not " *
               "$(repr(d.value)): grid derivation is GCD arithmetic (§10.5)" :
               "an offset is an exact Rational — write `Absolute(Hz(50), 1//500)`, not " *
               "$(repr(d.value)): grid derivation is GCD arithmetic (§10.5)"
    d.reason === :not_a_quantity &&
        return "`Absolute` takes a quantity value: `Period(1//50)` or `Hz(50)` — got " *
               "$(repr(d.value)) (§10.5)"
    d.reason === :both_given &&
        return d.call === :replay! ?
               "replay! takes `to_boundary` or `to_time`, not both — the boundary index and " *
               "the time are two spellings of one halt (§12.7, D-219)" :
               "step! takes `frames` or `t_plus`, not both — the count and the duration are " *
               "two spellings of one advance (§12.6)"
    d.reason === :not_replaying &&
        return "live! on a simulation whose input mode is already `:live` — there is no " *
               "recording to drop, and a silent no-op would let a caller believe one was " *
               "attached (§12.7, D-219)"
    d.reason === :non_nominal &&
        return "`trim!` needs a nominal `Simulation{Float64}` and this one is $(d.value) — " *
               "trim commits through the nominal world, and the seeded activation it " *
               "iterates on is the service's own scratch, instantiated per invocation " *
               "(§14.8, §9.4)"
    d.reason === :not_a_problem &&
        return "`trim!` takes a `TrimProblem` and was given $(d.value) — the problem is " *
               "one value with a closed field set: TrimProblem(; guess, lower, upper, " *
               "condition, reads, residuals, tolerances) (§14.7)"
    d.reason === :disabled &&
        return "this simulation was initialized with `trace = false`, so there is no " *
               "recording to hand back — the switch is §11.5's plain kill switch for the " *
               "memory-constrained marathon session, the door's keyword (D-029, D-261)"
    d.reason === :index_not_integer &&
        return "a selector's index must be an integer — the component index of §14.10, " *
               "applied to the read value — got $(repr(d.value)) (§14.4)"
    d.reason === :entry_shape &&
        return "TableBinding: entry `$(d.entry)` must be a NamedTuple — " *
               "(face = ..., deadzone = ..., expo = ...) (§11.6)"
    d.reason === :no_face &&
        return "TableBinding: entry `$(d.entry)` names no `face` — the face is what the " *
               "channel writes (§11.6)"
    d.reason === :face_name &&
        return "TableBinding: entry `$(d.entry)`'s face must be a face name, got " *
               "$(repr(d.value)) (§11.6)"
    d.reason === :vocabulary &&
        return "TableBinding: entry `$(d.entry)` carries `$(d.argument)` — the entry " *
               "vocabulary is $(_namelist(d.vocabulary)) (§11.6)"
    d.reason === :deadzone &&
        return "TableBinding: entry `$(d.entry)`'s deadzone must lie in [0, 1), got " *
               "$(d.value) (§11.6)"
    d.reason === :expo &&
        return "TableBinding: entry `$(d.entry)`'s expo must lie in [0, 1], got " *
               "$(d.value) (§11.6)"
    # The materialization's `join_timeout` (D-256) and the doors' four recording
    # keywords (D-261): each carries the constraint text and section its
    # `DeploymentInvalid` row carried before the keywords moved off the
    # deployment surface.
    d.argument === :join_timeout &&
        return "`join_timeout` must be a positive real — the shutdown tail's join cap in " *
               "seconds of wall clock, got $(repr(d.value)) (§12.4)"
    d.argument === :trace &&
        return "`trace` must be true or false — §11.5's trace kill switch, got $(repr(d.value))"
    d.argument === :log &&
        return "`log` must be true or false — the retention switch, got $(repr(d.value)) (§11.2)"
    d.argument === :log_every &&
        return "`log_every` must be an integer ≥ 1, got $(repr(d.value)) (§11.2)"
    d.argument === :log_max &&
        return "`log_max` must be an integer ≥ 1, or Inf as the explicit opt-out, got " *
               "$(repr(d.value)) (§11.2)"
    d.argument === :t_end &&
        return "`t_end` must be a real ≥ 0 — the run's clock bound, taken to the nearest " *
               "frame top, Inf the unbounded default, got $(repr(d.value)) (§13.5)"
    d.argument === :frames ?
        "frames must be an integer ≥ 1, got $(d.value) (§12.6)" :
        d.argument === :to_boundary ?
        "to_boundary must be a whole grid boundary the recording covers — 0 through its " *
        "own length — got $(repr(d.value)) (§12.7, §13.4)" :
        d.argument === :to_time ?
        "to_time must be a finite real at or after the recording's `t₀`, naming a time the " *
        "recording covers — got $(repr(d.value)) (§12.7, D-219)" :
        "t_plus must be a finite real > 0 — the duration spelling — got $(d.value) (§12.6)"
end

"§14.4, D-215: a non-selector in a read set, or a non-`Reads` where one is expected — `ConditionNodeMisuse`'s twin."
Base.@kwdef struct ReadSetMisuse <: Diagnostic
    observed::Any                            # the offending argument's type
    reason::Symbol = :not_a_read_set         # :not_a_selector | :not_a_read_set
    label::Union{Nothing,Symbol} = nothing
    in_hand::Vector{Symbol} = Symbol[]       # the selector kinds in hand
end
message(d::ReadSetMisuse) =
    d.reason === :not_a_selector ?
    "the read labeled `$(d.label)` is $(d.observed)" *
    (isempty(d.in_hand) ? "" :
     ", and the selector kind(s) in hand are $(_plainlist(d.in_hand))") *
    " — a read set is labeled *selectors*, " *
    "get_state / get_deriv / get_output / get_input / get_face (§14.4)" :
    "$(d.observed) is not a read set — wrap the labeled selectors in `reads(…)`: " *
    "reads(name = get_deriv(\"path\", :field), …) (§14.4, §14.7)"

"§11.3, D-215: `detach!` offered a device the roster does not hold — `AlreadyAttached`'s mirror."
Base.@kwdef struct NotAttached <: Diagnostic
    device::String
    roster::Vector{String} = String[]        # the roster's device ids
end
message(d::NotAttached) =
    "this $(d.device) instance is not rostered — `detach!` releases an existing " *
    "attachment, and the roster holds " *
    (isempty(d.roster) ? "no device" : join(("`$(r)`" for r in d.roster), ", ")) * " (§11.3)"

# --- replay's entry validation (§12.7) -----------------------------------------
# The up-front pass a trace is admitted through, before any state is touched:
# the header against the target `Build` and its deployment binding, each
# writer's schema against the target's root-input faces, and every record's
# positions against the schema they were written under. The line the three
# kinds draw is §12.7's: *structural* mismatch is an error, *parametric*
# difference is the what-if replay and no error at all.

"§11.5, §12.7: the trace's header disagrees with the target build, its scalar or its deployment binding."
Base.@kwdef struct ReplayHeaderMismatch <: Diagnostic
    what::Symbol                             # :store | :root_input | :deployment | :scalar | :frame
    path::String = ""                        # the component path: the per-component :store arms,
                                             # a :deployment schedule row and a rate scope (§12.7)
    name::Symbol = Symbol("")                # :sizes|:paths|:s|:m, the root-input face, the
                                             # deployment parameter, a schedule or `scope.` column,
                                             # or a list name: :schedule, `scope.key`
    expected::Any = nothing                  # the trace's value
    found::Any = nothing                     # the target's
end
path(d::ReplayHeaderMismatch) = d.path

_replay_subject(d::ReplayHeaderMismatch) =
    d.name === :paths ? "component-path list" :
    d.name === :sizes ? "cell-size list" :
    "$(_at_path(d.path))'s $(d.name) store type"

_replay_paths(paths) = isempty(paths) ? "none" : join((_at_path(p) for p in paths), ", ")

# The `:deployment` arms, one per case the walk in `trace.jl` emits: the seven
# parameters and the two lists carry no path, a schedule row and a rate scope
# carry theirs, and a scope column rides in `name` behind its prefix.
_replay_deployment(d::ReplayHeaderMismatch) =
    isempty(d.path) ?
    (d.name === :schedule ?
     "replay: the recording's schedule covers $(_replay_paths(d.expected)) and " *
     "this deployment's covers $(_replay_paths(d.found)) — the rows are compared " *
     "by component path, so a differing component list is reported whole: past the first " *
     "difference the rows name different components (§12.7)" :
     d.name === Symbol("scope.key") ?
     "replay: the recording opened the rate scopes $(_namelist(d.expected)) and " *
     "this deployment opens $(_namelist(d.found)) — a scope is identified by its " *
     "path and its key, so a differing scope list is reported whole rather than column by " *
     "column (§12.7)" :
     "replay: the recording ran at `$(d.name)` = $(d.expected) and this " *
     "simulation is bound at $(d.found) — the seven trajectory-determining " *
     "deployment parameters are compared, the schedule with them, never taken as a " *
     "what-if: a deployment change moves the times the frame-ordinal batches apply at, " *
     "which is different inputs rather than a modified model (§12.7)") :
    startswith(String(d.name), "scope.") ?
    "replay: the rate scope at $(_at_path(d.path)) recorded " *
    "`$(chopprefix(String(d.name), "scope."))` = $(repr(d.expected)) and " *
    "this deployment binds $(repr(d.found)) — a scope is compared with every " *
    "column, the anchor included, because it is what the rates under it were declared " *
    "through (§12.7)" :
    "replay: the schedule row for $(_at_path(d.path)) recorded " *
    "`$(d.name)` = $(repr(d.expected)) and this deployment binds " *
    "$(repr(d.found)) — the schedule is " *
    "compared with every column, the anchor and rate chain included, so a rate re-declared " *
    "through a different anchor at the same tick table is a different deployment (§12.7)"

message(d::ReplayHeaderMismatch) =
    d.what === :scalar ?
    "replay: the trace was recorded on a `Simulation{$(d.expected)}` and this one is a " *
    "`Simulation{$(d.found)}` — the scalar is a structural fact of the deployment, and a " *
    "trace re-drives the build it was recorded on (§12.7)" :
    d.what === :deployment ? _replay_deployment(d) :
    d.what === :frame ?
    "replay: $(d.name)'s record is stamped frame $(d.found), which is outside the " *
    "recording's own $(d.expected) — a batch replays at the frame ordinal it was drained " *
    "at, and the trace's `frames` is how long the recording ran (§11.5, §12.7)" :
    d.what === :root_input ?
    (d.name === Symbol("") ?
     "replay: the trace records the root input-face list $(_faceset(d.expected)) and this " *
     "build's is $(_faceset(d.found)) — the header's root-input values are applied face by " *
     "face at boundary zero, so the two lists have to agree (§11.5, §12.7)" :
     "replay: the value $(repr(d.found)) recorded for the root input `$(d.name)` does not " *
     "convert to its declared type $(d.expected) — a record is replayed through the " *
     "target's own compiled scatter (§11.4, §12.7)") :
    "replay: the $(_replay_subject(d)) was $(repr(d.expected)) at the recording and is " *
    "$(repr(d.found)) here — the store layout is compared against the `Build`, structural " *
    "mismatch being a replay error and only *parametric* difference the what-if replay (§12.7)"

"§11.5, §12.7: a recorded writer schema naming faces the target model does not export as root inputs."
Base.@kwdef struct ReplaySchemaMismatch <: Diagnostic
    writer::String                           # the trace's writer tag (§11.8's own name)
    schema::Vector{Symbol}                   # the recorded face-name → position schema
    unknown::Vector{Symbol}                  # the disagreeing names
    faces::Vector{Symbol}                    # the target's root input-face list
end
message(d::ReplaySchemaMismatch) =
    "replay: $(d.writer)'s recorded schema $(_faceset(d.schema)) names " *
    "$(_namelist(d.unknown)), which this model does not export as a root input — its root " *
    "inputs are $(_faceset(d.faces)). A recorded schema is validated against the target's " *
    "own faces before the first frame, because the positional records mean nothing without " *
    "it (§11.5, §12.7)"

"§12.7: a record position that resolves to no face — no such position in the writer's schema, or no such face here."
Base.@kwdef struct ReplayUnknownFace <: Diagnostic
    face::Union{Symbol,Int}                  # the name when the schema has one, else the bare position
    frame::Int                               # the frame ordinal the record replays at
    writer::String                           # the trace's writer tag
    faces::Vector{Symbol} = Symbol[]         # the target's root input-face list
end
message(d::ReplayUnknownFace) =
    d.face isa Int ?
    "replay: the frame-$(d.frame) record for $(d.writer) touches position $(d.face), which " *
    "its recorded schema does not reach — a sparse record is a position against that " *
    "schema, and nothing else resolves it (§11.5, §12.7)" :
    "replay: the frame-$(d.frame) record for $(d.writer) names `$(d.face)`, which is no " *
    "root input face of this model — its root inputs are $(_faceset(d.faces)) (§12.7)"
