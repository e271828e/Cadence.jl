# Hierarchy (§8.5, §8.6, §6.1): class by declaration shape, path resolution, and
# the flatten pass. Assemblies are virtual for execution (§10.5) — what leaves
# this file is a flat list of primitives with their absolute paths and one
# resolved producer per input, and nothing downstream knows the tree existed.

# --- class (§8.5) -------------------------------------------------------------
# Class is not announced either: `child_connections` is the assembly marker, any
# leaf declaration a primitive's, and the rule is total — a component-typed
# struct declaring neither family has no class to read.

@enum Class PRIMITIVE ASSEMBLY

const ASSEMBLY_FAMILY = (:child_connections,)
const LEAF_FAMILY = (:init_x, :init_s, :init_m, :init_workspace, :input_types,
                     :output_types, :state_events, :output_state, :output_direct,
                     :state_derivative, :state_update, :state_projection)

# The five `DECLARATION_FAMILY` names no leaf declaration covers: the assembly
# marker, the two boundary declarations and the two sugars.
const _OTHER_FAMILY = ((:child_connections, child_connections),
                       (:input_connections, input_connections),
                       (:output_connections, output_connections),
                       (:sample_times, sample_times),
                       (:transparent_container, transparent_container))

"""The leaf declarations `comp` defines, in inventory order (§8.2, §8.5)."""
function leaf_declarations(comp)
    found = Symbol[]
    for (name, fn) in ((:init_x, init_x), (:init_s, init_s), (:init_m, init_m))
        _declares(fn, comp) && push!(found, name)
    end
    # Either arity is a leaf declaration; which one is lawful is the tier's
    # question, settled by the classifier (§8.2), not this one.
    for (name, fn) in ((:init_workspace, init_workspace), (:input_types, input_types),
                       (:output_types, output_types))
        (_declares(fn, comp) || _declares(fn, comp, Type{Float64})) && push!(found, name)
    end
    _declares(state_events, comp) && push!(found, :state_events)
    for (name, fn) in ((:output_state, output_state), (:output_direct, output_direct),
                       (:state_derivative, state_derivative), (:state_update, state_update),
                       (:state_projection, state_projection))
        has_stage(fn, comp) && push!(found, name)
    end
    found
end

"""The `DECLARATION_FAMILY` names `comp` defines, in family order (§8.1, §8.5)."""
function declarations_found(comp)
    found = leaf_declarations(comp)
    for (name, fn) in _OTHER_FAMILY
        _declares(fn, comp) && push!(found, name)
    end
    Symbol[n for n in DECLARATION_FAMILY if n in found]
end

"""The class of `comp` at `path`, or a `DiagnosticError` naming what makes it unreadable."""
function classify(path::String, comp)
    leaves = leaf_declarations(comp)
    if _declares(child_connections, comp)
        isempty(leaves) ||
            throw(DiagnosticError(ClassMixed(path = path, declarations = leaves)))
        return ASSEMBLY
    end
    isempty(leaves) || return PRIMITIVE
    throw(DiagnosticError(ClassUnreadable(path = path, type = _typename(comp),
                                     found = declarations_found(comp),
                                     assembly_family = collect(ASSEMBLY_FAMILY),
                                     leaf_family = collect(LEAF_FAMILY),
                                     holds_components = _holds_components(comp))))
end

# A producer terminal spelled for a payload string: a component's port, or the
# root's own input face, whose path is the empty one.
_terminal(terminal::Tuple{String,Symbol}) =
    isempty(first(terminal)) ? "root input `$(last(terminal))`" :
                               "`$(first(terminal))`.$(last(terminal))"
_join(path::String, segment::String) = isempty(path) ? segment : path * "/" * segment

_holds_components(comp) = any(fieldnames(typeof(comp))) do name
    v = getfield(comp, name)
    v isa AbstractComponent ||
        ((v isa NamedTuple || v isa Tuple) && any(e -> e isa AbstractComponent, v))
end

# --- children (§8.5) ----------------------------------------------------------
# Fields whose type is `<: AbstractComponent` are children, the field name their
# path segment. A `Tuple` or `NamedTuple` field whose elements are *all*
# components is a container: transparent grouping with no contract and no wiring
# of its own, contributing its elements as children *of the parent*, path-named
# `"field/1"…"field/N"` or `"field/key"`. Every other field is inert parameter
# data.
#
# One container field per type may be declared **name-transparent** (D-211), and
# its elements are then contributed under their bare keys — `"key"`, `"1"` —
# everywhere a child name appears. Naming is the only thing the declaration
# changes: the elements are the parent's children exactly as before, in the same
# declaration order, and the container keeps its transparency of contract. What
# pays for it is one declaration check — the declared symbol must name a
# container field — and a collision family in three arms: no two children may
# end up sharing a name, and the two collisions a bare key reaches that no child
# name can, its own field's name (which the rate declaration's sugar already
# spells) and a sibling container field's name, where that field contributes
# children (whose `"field/key"` segment grammar it would shadow).

"""`segment => instance` for every child of `comp`, in field order."""
children(path::String, comp) = first(_children(path, comp))

"""
`(kids, fields)`: the children of `comp` as `segment => instance` pairs, and per
child the field name that contributed it — the rate declaration's second key
form, the bare field name applying one entry to every element of a container
(§8.7). The sugar keys on the *field*, so a name-transparent container keeps it
unchanged.
"""
function _children(path::String, comp)
    transparent_field = invoke_declaration(transparent_container, comp)
    kids = Pair{String,Any}[]
    fields = Symbol[]
    contributors = String[]                    # per child, who contributed it
    # The child-naming pass collects (§13.1): every field is walked, and the
    # whole violation list leaves through one throw at the end. A component with
    # three mixed containers reports three, not the first.
    diags = Diagnostic[]
    # The sibling fields a bare key could shadow: those that currently contribute
    # children, because the grammar a key shadows is the one that currently
    # reaches something. An empty field reserves nothing, and it has to be that
    # way round: an empty `Tuple` or `NamedTuple` is an empty container and empty
    # inert parameter data at once — the value cannot tell them apart, and the
    # walk below already treats them as one case — so reserving every empty
    # field's name would refuse a bare key over inert data, a false positive
    # where no shadow exists. Legality is then per-instantiation, which is the
    # framework's norm: every wire is validated against the instance too.
    # Collected before the walk, because the shadowed field may be declared
    # after the transparent one.
    shadowable = String[String(name) for name in fieldnames(typeof(comp))
                        if name !== transparent_field && _is_container(getfield(comp, name)) &&
                           !isempty(getfield(comp, name))]
    for name in fieldnames(typeof(comp))
        value = getfield(comp, name)
        if value isa AbstractComponent
            push!(kids, string(name) => value)
            push!(fields, name)
            push!(contributors, "field `$name`")
        elseif value isa NamedTuple || value isa Tuple
            n_components = count(e -> e isa AbstractComponent, value)
            if n_components == 0
                # Inert data, an empty container too — unless an element is
                # itself a container bearing components, the nesting §8.5
                # refuses in the first cut.
                nested = [k for k in keys(value) if _bears_component(value[k])]
                isempty(nested) ||
                    push!(diags, ContainerNested(path = path, field = name, keys = nested,
                                                types = [_typespell(typeof(value[k])) for k in nested]))
                continue
            end
            if n_components != length(value)
                mixed = [k for k in keys(value) if !(value[k] isa AbstractComponent)]
                push!(diags, ContainerMixed(path = path, field = name, keys = mixed,
                                           types = unique([_typespell(typeof(value[k])) for k in mixed])))
                continue
            end
            bare = name === transparent_field
            for key in keys(value)
                contributor = "$(bare ? "name-transparent " : "")container field `$name`, element `$key`"
                # The collision family's other two arms, both reachable only by a
                # bare key and neither of them a duplicate *child* name, so
                # `_check_child_names` below can see neither (§8.5, D-211, D-212).
                hit = false
                if bare && string(key) == string(name)
                    push!(diags, ChildNameCollision(path = path, name = string(key),
                                                   reason = :sample_times_sugar,
                                                   declarations = [contributor], field = name))
                    hit = true
                end
                if bare && string(key) in shadowable
                    push!(diags, ChildNameCollision(path = path, name = string(key),
                                                   reason = :sibling_field,
                                                   declarations = [contributor]))
                    hit = true
                end
                hit && continue                    # a shadowed key names no child
                push!(kids, (bare ? string(key) : string(name, "/", key)) => value[key])
                push!(fields, name)
                push!(contributors, contributor)
            end
        end
    end
    _check_transparent(path, comp, transparent_field, diags)
    _check_child_names(path, kids, contributors, diags)
    isempty(diags) || throw(DiagnosticError(diags))
    kids, fields
end

# The container form, the empty one included — it contributes zero children, and
# parametric code then needs no special case (§8.5).
_is_container(v) = (v isa NamedTuple || v isa Tuple) && all(e -> e isa AbstractComponent, v)

# The container fields of `comp`'s type: what a name-transparent declaration may name.
_container_fields(comp) =
    Symbol[n for n in fieldnames(typeof(comp)) if _is_container(getfield(comp, n))]

# A container holding a component at any depth: the shape `ContainerNested` names.
_bears_component(v) = (v isa NamedTuple || v isa Tuple) &&
                      any(e -> e isa AbstractComponent || _bears_component(e), v)

# The declaration is checked after the walk, so a mixed container reports as one
# rather than as a bad transparency declaration.
function _check_transparent(path::String, comp, transparent_field, diags::Vector{Diagnostic})
    transparent_field === nothing && return nothing
    ok = transparent_field in fieldnames(typeof(comp)) &&
        _is_container(getfield(comp, transparent_field))
    ok || push!(diags, TransparentContainerUnknown(path = path, field = transparent_field,
                                                  component = _typename(comp),
                                                  candidates = _container_fields(comp)))
    nothing
end

# General, not transparency-specific: whatever mix of fields and containers
# produced them, two children may not share a name. Bare keys make the case
# reachable, but the rule is the older one — a child name is a path segment, and
# a path segment addresses one component.
function _check_child_names(path::String, kids, contributors, diags::Vector{Diagnostic})
    for i in eachindex(kids), j in 1:(i - 1)
        first(kids[i]) == first(kids[j]) &&
            push!(diags, ChildNameCollision(path = path, name = first(kids[i]),
                                           reason = :two_children,
                                           declarations = [contributors[j], contributors[i]]))
    end
    nothing
end

# --- the anonymous assembly (§8.5, D-211) -------------------------------------

"""
`Group`: the on-the-fly assembly, the one component type the framework itself
provides, whose *values* are the ad-hoc topologies. It needs no new rule — the
container-children rule makes the `children` field's elements children of the
`Group` itself, and the four declarations are ordinary functions of the
instance, free to read its fields.

The one declaration it adds is `transparent_container` (D-211): `children` is
name-transparent, so its elements go by **bare key** everywhere a child name
appears — `"ctl/out" => "plant/u"` for a wire, `(ctl = Relative(2),)` for a rate,
`at("ctl", …)` for a condition prefix, `"plant/y"` for a read path. A `Group`'s
declarations are then textually identical to a named assembly's; the rate
declaration's field-name sugar, keying on the field rather than on a path
segment, keeps working as `(children = Relative(2),)` for the uniform case.

The type parameters carry the children's concrete types, so specialization is
unchanged; what is given up against a named type is dispatch, which exploratory
composition does not want.
"""
struct Group{C <: NamedTuple, W, I, O, R <: NamedTuple} <: AbstractComponent
    children::C      # component-typed elements → children by the container rule
    wires::W         # inert parameter data
    inputs::I
    outputs::O
    rates::R         # the ad-hoc rate scope, keyed by bare element name (§8.7)
end

"""
    Group(children; wires = (), inputs = (), outputs = (), rates = (;))

The convenience form. A bare `Pair` passed for `wires`, `inputs` or `outputs` is
the one-entry tuple — the declarations are ordered collections of pairs, and a
single wire should not have to be written `("a/x" => "b/y",)`.
"""
Group(children; wires = (), inputs = (), outputs = (), rates = (;)) =
    Group(children, _entries(wires), _entries(inputs), _entries(outputs), rates)

_entries(connections::Pair) = (connections,)
_entries(connections) = connections

child_connections(g::Group) = g.wires
input_connections(g::Group) = g.inputs
output_connections(g::Group) = g.outputs
sample_times(g::Group) = g.rates
transparent_container(::Group) = :children

# --- paths (§8.6, §6.1) -------------------------------------------------------
# Slash-separated, relative to the declaring assembly, no leading slash: the one
# canonical form, used verbatim in declarations and in error messages. A terminal
# path's last segment is a port or face name; the prefix names one child. Deep
# structural paths survive on the read side — inspection, the face routes, the
# table accessors — and nowhere in the three wiring declarations (D-207).

"""
Resolve terminal `path` against assembly `assembly` at `base`, returning the component
it names, that component's absolute path, and the final segment — or recording
the refusal in `diags` and returning `nothing` (§13.1).

§6.1's one-level rule lives here (D-207): a connection endpoint names an
**immediate child and one of its faces** — one child segment, plus the key
segment where the child is a container element (`"units/1/e"` is one level, not
two), and one face name. Anything deeper is a build error whatever the declared
field types along it, which is why the generic-holding question never arises in
wiring resolution: an endpoint stops before any field it could traverse past
(§13.3). Faces are the only currency crossing a boundary, so a route through
several levels is declared level by level, each assembly speaking of its own
children alone.
"""
function resolve_terminal(entry::String, base::String, assembly, path::AbstractString,
                          diags::Vector{Diagnostic}; owner::String = _at_path(base))
    segments = String.(split(path, '/'))
    if length(segments) ≤ 1
        push!(diags, PathResolution(entry = entry, spelling = String(path),
                                   reason = :not_a_terminal, owner = owner))
        return nothing
    end
    resolved = _one_level(entry, base, assembly, path, segments, 1, diags; owner)
    resolved === nothing && return nothing
    kid, segment = resolved
    kid, _join(base, segment), Symbol(segments[end])
end

# The child half of the rule, shared by both of §13.3's path primitives: `tail`
# is how many segments follow the child — one face name for a terminal path,
# none for `resolve`'s bare child path. Container children match under their
# D-211 naming, which is what the two-segment lookahead serves: an undeclared
# container's element spends two segments on the child, a transparent one's
# spends one, and neither is "deeper".
function _one_level(entry::String, base::String, assembly, path::AbstractString,
                    segments::Vector{String}, tail::Int, diags::Vector{Diagnostic};
                    owner::String = _at_path(base))
    kids = children(base, assembly)
    child_index = findfirst(kid -> first(kid) == segments[1], kids)
    child_index === nothing && length(segments) > 1 + tail &&
        (child_index = findfirst(kid -> first(kid) == segments[1] * "/" * segments[2], kids))
    if child_index === nothing
        push!(diags, PathResolution(entry = entry, spelling = String(path),
                                   reason = :unknown_child, owner = owner,
                                   segment = segments[1],
                                   candidates = String[first(k) for k in kids]))
        return nothing
    end
    segment, kid = kids[child_index]
    if count(==('/'), segment) + 1 + tail != length(segments)
        push!(diags, PathResolution(entry = entry, spelling = String(path),
                                   reason = :reaches_past, owner = owner,
                                   segment = segment, level = _join(base, segment), tail = tail))
        return nothing
    end
    kid, segment
end

# A child's holding, read off the type's definition rather than the instance:
# a field typed by a parameter is a `TypeVar` there, whatever the
# instantiation filled in (§8.5, D-061). Container elements follow their
# container's declared type.
_declared_holding(comp, field::Symbol) =
    fieldtype(Base.unwrap_unionall(typeof(comp).name.wrapper), field)
_held_concretely(comp, field::Symbol) =
    (ft = _declared_holding(comp, field); !(ft isa TypeVar) && isconcretetype(ft))

"""
The service walk (§13.3, D-130): `path`'s segments from
`level`, the component at `base`, following the declared field types
alongside the instances. Resolving *to* a generically held child is legal;
traversing *past* one is the refusal, whatever the instance in hand — the
authoring level speaks its own fields and its declared children's names
(§14.2), and a deep path is legitimate exactly within an owned concrete
subtree. Returns the component the path names, primitive or assembly, or
`nothing` after recording the refusal against `entry`. The empty path names
`level` itself.
"""
function resolve_authored(entry::String, base::String, level, path::AbstractString,
                          diags::Vector{Diagnostic})
    isempty(path) && return level
    segments = String.(split(path, '/'))
    here, here_path, i = level, base, 1
    while i ≤ length(segments)
        # A primitive has no children in this walk. A component-typed field of one
        # is inert to the composition — `flatten!` stops at the primitive and never
        # descends, so no path indexes what the field holds (§8.5,
        # `ClassUnreadable.holds_components`) — and asking `_children` about it
        # would invent a child, or raise the container checks over a component the
        # build never walked. Every level below is a child the flatten pass walked,
        # so `classify` only reads back a class it already proved readable.
        if classify(here_path, here) === PRIMITIVE
            push!(diags, PathResolution(entry = entry, spelling = String(path),
                                       reason = :unknown_child, owner = _at_path(here_path),
                                       segment = segments[i]))
            return nothing
        end
        # `_children` re-runs the container collision checks and throws on its
        # own when they fail; the build proved this tree clean, so here the call
        # only hands the list back.
        kids, fields = _children(here_path, here)
        child_index = findfirst(kid -> first(kid) == segments[i], kids)
        child_index === nothing && i < length(segments) &&
            (child_index =
                 findfirst(kid -> first(kid) == segments[i] * "/" * segments[i + 1], kids))
        if child_index === nothing
            push!(diags, PathResolution(entry = entry, spelling = String(path),
                                       reason = :unknown_child, owner = _at_path(here_path),
                                       segment = segments[i],
                                       candidates = String[first(k) for k in kids]))
            return nothing
        end
        segment, kid = kids[child_index]
        i += count(==('/'), segment) + 1            # a matched pair consumes two segments
        if i ≤ length(segments) && !_held_concretely(here, fields[child_index])
            push!(diags, PathResolution(entry = entry, spelling = String(path),
                                       reason = :past_generic, owner = _at_path(here_path),
                                       segment = segment, level = _join(here_path, segment),
                                       declared = _declared_holding(here, fields[child_index])))
            return nothing
        end
        here, here_path = kid, _join(here_path, segment)
    end
    here
end

"""
The child names an absolute `path` traverses, outermost first, as `_children`
names them — so a D-211 container pair such as `"units/1"` is one name, not two
segments. The same greedy match `resolve_authored` runs, over a path the build
compiled and which therefore always resolves. A service that authors a
condition back out of the flattened list spells it level by level from this, the
one spelling the service walk admits across a generic seam (§14.2, §13.3).
"""
function authored_chain(root, path::AbstractString)
    isempty(path) && return String[]
    segments = String.(split(path, '/'))
    chain, here, here_path, i = String[], root, "", 1
    while i ≤ length(segments)
        kids, = _children(here_path, here)
        child_index = findfirst(kid -> first(kid) == segments[i], kids)
        child_index === nothing && i < length(segments) &&
            (child_index =
                 findfirst(kid -> first(kid) == segments[i] * "/" * segments[i + 1], kids))
        child_index === nothing && throw(InternalInvariant("no child of `$here_path` at `$path`"))
        segment, kid = kids[child_index]
        push!(chain, segment)
        i += count(==('/'), segment) + 1
        here, here_path = kid, _join(here_path, segment)
    end
    chain
end

# --- §13.3's build primitives -------------------------------------------------
# The four the declaration surface calls: `resolve` and `resolve_terminal` in
# their public, entry-less forms, plus the two face-list accessors. Those are the
# *wiring resolution* of §13.3's table — the one-level rule verbatim, the same
# walk wiring resolution runs, entered from a declaration body with no wiring
# entry to attribute the failure to. `resolve_authored` above is *the service
# walk*, entered by the services with an entry to attribute the refusal to.

"""
    resolve(assembly, path) → AbstractComponent

The declared-field walk along `/` segments, container children included under
their D-211 naming (bare keys for a name-transparent container). One level
(§6.1, D-207): `path` names an **immediate child** — one child segment, plus the
key segment where the child is a container element — and anything deeper is a
build error naming the child it reaches past.
"""
function resolve(assembly, path::AbstractString)
    who = "`resolve` on `$(nameof(typeof(assembly)))`"
    isempty(path) &&
        throw(DiagnosticError(PathResolution(entry = who, spelling = "", reason = :empty_path,
                                        owner = "the component in hand")))
    # A declaration body is user code (§13.1), so the one recorded refusal throws
    # alone here rather than reaching the step's list.
    diags = Diagnostic[]
    resolved = _one_level(who, "", assembly, path, String.(split(path, '/')), 0, diags;
                          owner = "the component in hand")
    resolved === nothing && throw(DiagnosticError(only(diags)))
    first(resolved)
end

"""
    resolve_terminal(assembly, path) → (component, name)

The terminal split: the final segment is the port or face name, the prefix
resolves through `resolve`. The split is unambiguous because face names may
contain dots, never slashes (§8.6).
"""
function resolve_terminal(assembly, path::AbstractString)
    diags = Diagnostic[]
    resolved = resolve_terminal("`resolve_terminal` on `$(nameof(typeof(assembly)))`",
                                "", assembly, path, diags;
                                owner = "the component in hand")
    resolved === nothing && throw(DiagnosticError(only(diags)))   # declaration code: fail-fast
    comp, _, name = resolved
    comp, String(name)
end

# The key set of a contract declaration, whichever arity declares it: the keys are
# a tier-independent fact, and §8.2's classifier is what settles a disagreement.
_contract(fn, comp) = _declares(fn, comp, Type{Float64}) ? invoke_declaration(fn, comp, Float64) :
                   _declares(fn, comp) ? invoke_declaration(fn, comp) : NamedTuple()

"""
    input_faces(comp) → Vector{String}

A leaf's `input_types` keys — asked at the nominal `Float64`, the key set being
`T`-independent — or an assembly's `input_connections` face names. Declaration
order is preserved: deterministic printouts, stable diagnostics (§13.3). Inside a
walk the walk has already evaluated the body once and this primitive does not
evaluate it again (Appendix C); standalone the primitive evaluates it. Either way
the list returned is a fresh vector, the caller's to mutate.
"""
input_faces(comp) = classify("", comp) === PRIMITIVE ?
                 String[String(k) for k in keys(_contract(input_types, comp))] :
                 _walked_faces(comp, 1, input_connections, first)

"""
    output_faces(comp) → Vector{String}

`input_faces`' mirror: a leaf's `output_types` keys, or an assembly's
`output_connections` face names, in declaration order (§13.3). Inside a walk the
walk has already evaluated the body once and this primitive does not evaluate it
again (Appendix C); standalone the primitive evaluates it. Either way the list
returned is a fresh vector, the caller's to mutate.
"""
output_faces(comp) = classify("", comp) === PRIMITIVE ?
                  String[String(k) for k in keys(_contract(output_types, comp))] :
                  _walked_faces(comp, 2, output_connections, last)

# The walk's list when the walk evaluated this assembly, the one body asked for
# otherwise — one side per primitive, so that a miss evaluates only the body
# asked for: outside a walk a caller asks for one side, and evaluating the other
# for nothing would raise its warnings for nothing. A miss inside a walk has no
# reader today (children are walked before any parent reads them); the fallback
# is correctness, not a path. The hit is copied on the way out: the memo is the
# walk's own record, and a caller sorting or emptying what a primitive handed it
# would otherwise reorder the boundary the walk goes on to compute.
function _walked_faces(comp, side::Int, fn, face_of)
    memo = WALK_FACES[]
    memo !== nothing && haskey(memo, comp) && return copy(memo[comp][side])
    String[String(face_of(pair)) for pair in invoke_declaration(fn, comp)]
end

# --- §8.8's passthrough helpers -----------------------------------------------
# `input_connections` and `output_connections` are ordinary functions evaluated
# at build against the concrete instance, so they may *compute* entries from
# child contracts. These two are the framework's own sugar over the primitives
# above — the pass-through case, where an assembly re-exports the faces of a
# child it does not itself feed. Two helpers rather than one keyword, because
# after the boundary split a single call cannot emit into two declarations
# (D-209). Nothing else about computed connections is built here: the entries
# they return are ordinary pairs, mixing freely with hand-written ones, and
# every check that meets them is the build's own.

"""
    input_passthrough(assembly, child_path; sep = ".",
                      prefix = replace(child_path, "/" => sep),
                      except = (), only = (), select = nothing)

Every input face of `child_path` the assembly does not feed, exposed on its own
boundary under `prefix * sep * face` — splatted into `input_connections` (§8.8).
The default `prefix` folds the path's slash into `sep`, so an undeclared
container element (`"units/1"`) labels its faces `"units.1.…"` — a legal face
name — by default; an explicit `prefix` is used verbatim, and `prefix = ""`
drops the prefixing entirely. `except`, `only` and `select` filter face names
within the child's set and are exclusive, one selector per call (D-251):
`select` is a predicate over face names, receiving each as a `String` and
keeping the ones it accepts. A selector that keeps nothing warns
`EmptyFaceSelection` on the `Build` (§9.1), while a bare call over a faceless
child is silent. `child_path` names an immediate child (a bare key where the
container is name-transparent); a deeper path meets `resolve`'s one-level
rejection like any other wiring endpoint.
"""
function input_passthrough(assembly, child_path::AbstractString;
                           sep::AbstractString = ".",
                           prefix::AbstractString = replace(child_path, "/" => sep),
                           except::Tuple = (), only::Tuple = (), select = nothing)
    names = input_faces(resolve(assembly, child_path))
    wanted = _passthrough_faces("input_passthrough", child_path, names, except, only, select)
    Tuple(_labelled(prefix, sep, n) => string(child_path, "/", n) for n in wanted)
end

"""
    output_passthrough(assembly, child_path; sep = ".",
                       prefix = replace(child_path, "/" => sep),
                       except = (), only = (), select = nothing)

`input_passthrough`'s sibling on the outward boundary (D-209), splatted into
`output_connections`: the same surface over `output_faces` — the same folded
default `prefix` included, and the same three exclusive selectors, one per
call, `select` accepting face names and an empty selection warning
`EmptyFaceSelection` (§8.8, D-251) — its pairs reading along the flow —
internal source => face name — as every pair in that declaration does. Its
consumer is one-level routing (§6.1): every level re-exports the outputs it
surfaces, so the output side needs the computed spelling the input side
already has.
"""
function output_passthrough(assembly, child_path::AbstractString;
                            sep::AbstractString = ".",
                            prefix::AbstractString = replace(child_path, "/" => sep),
                            except::Tuple = (), only::Tuple = (), select = nothing)
    names = output_faces(resolve(assembly, child_path))
    wanted = _passthrough_faces("output_passthrough", child_path, names, except, only, select)
    Tuple(string(child_path, "/", n) => _labelled(prefix, sep, n) for n in wanted)
end

_labelled(prefix, sep, n) = isempty(prefix) ? String(n) : string(prefix, sep, n)

# Exclusivity is enforced, not documented, and a filter naming a face the child
# does not have errors with the list in hand — the same did-you-mean shape every
# declaration-time refusal takes here (§8.8). The order of the checks is the
# spec's: exclusivity, the unknown names, the selection, then the warning a
# selector that kept nothing raises (D-251).
function _passthrough_faces(who::String, child_path::AbstractString,
                            names::Vector{String}, except_faces::Tuple, only_faces::Tuple, select)
    given = Symbol[]
    isempty(except_faces) || push!(given, :except)
    isempty(only_faces) || push!(given, :only)
    select === nothing || push!(given, :select)
    length(given) ≤ 1 ||
        throw(DiagnosticError(UnknownFaceSelection(who = who, path = String(child_path),
                                              reason = :multiple_selectors,
                                              names = String[String(g) for g in given])))
    unknown = [String(n) for n in (except_faces..., only_faces...) if !(String(n) in names)]
    isempty(unknown) ||
        throw(DiagnosticError(UnknownFaceSelection(who = who, path = String(child_path),
                                              reason = :unknown_names, names = unknown,
                                              candidates = names)))
    wanted = !isempty(only_faces) ? String[String(n) for n in only_faces] :
             select !== nothing ? filter(select, names) :
                                  setdiff(names, String[String(n) for n in except_faces])
    # A selector that kept nothing is almost always a typo the unknown-names check
    # cannot see; a bare call over a faceless child asked for nothing and is
    # silent. `only` cannot reach here — a non-empty `only` of known names keeps
    # them all — so only `except` has names to carry.
    if length(given) == 1 && isempty(wanted)
        selector = given[1]
        _warn!(EmptyFaceSelection(who = who, path = String(child_path), selector = selector,
                                  names = selector === :except ?
                                          String[String(n) for n in except_faces] : String[],
                                  candidates = names))
    end
    wanted
end

# --- endpoint resolution (§8.6) -----------------------------------------------
# Faces are kind-blind (D-172): an endpoint's final segment resolves to a
# primitive's port or to a sub-assembly's face alike, and a face resolves
# recursively to its own internal endpoint. A face's type and tier are therefore
# derived — they are its ultimate internal endpoint's — never declared.

"""
The primitive port a producing endpoint ultimately names, as `(path, port)`, or
`nothing` with the refusal recorded in `diags` — the endpoint then claims nothing
and the obligation pass reports what it left unfed (§13.1).
"""
function resolve_source(draft, entry::String, base::String, assembly, path::AbstractString,
                        diags::Vector{Diagnostic})
    resolved = resolve_terminal(entry, base, assembly, path, diags)
    resolved === nothing && return nothing
    comp, comp_path, name = resolved
    if classify(comp_path, comp) === PRIMITIVE
        haskey(_contract(output_types, comp), name) && return (comp_path, name)
    else
        # Children are walked before wires, so the child's faces are already
        # resolved: an output face's producer is its recorded row, and a face
        # whose source was refused was refused there, once (D-229).
        row = findfirst(pr -> first(pr) == (comp_path, name), draft.out_faces)
        row === nothing || return last(draft.out_faces[row])
        String(name) in output_faces(comp) && return nothing   # declared, refused at the child
    end
    # the parent's own typo
    _wrong_direction(entry, path, comp_path, name, comp, "producer", diags)
end

"""
The primitive inputs a consuming endpoint ultimately names, as `(path, face)`.
Several, when the endpoint is a sub-assembly's input face fanning out through the
boundary; none, when the endpoint failed to resolve and the refusal was recorded.
"""
function resolve_dest(draft, entry::String, base::String, assembly, path::AbstractString,
                      diags::Vector{Diagnostic})
    resolved = resolve_terminal(entry, base, assembly, path, diags)
    resolved === nothing && return Tuple{String,Symbol}[]
    comp, comp_path, name = resolved
    if classify(comp_path, comp) === PRIMITIVE
        haskey(_contract(input_types, comp), name) && return [(comp_path, name)]
    else
        # Children are walked before wires, so the child's faces are already
        # resolved: a face's consumers are its recorded route, and a face whose
        # route was refused was refused there, once (D-229).
        row = findfirst(rt -> rt[1] == comp_path && rt[2] === name, draft.routes)
        row === nothing || return copy(draft.routes[row][3])
        String(name) in input_faces(comp) && return Tuple{String,Symbol}[]   # refused at the child
    end
    # the parent's own typo
    _wrong_direction(entry, path, comp_path, name, comp, "consumer", diags)
    Tuple{String,Symbol}[]
end

_endpoints(inner::AbstractString) = (inner,)
_endpoints(inner::Tuple) = inner

# Called by the declaring level alone, on its own children's endpoints: a parent
# reading the face reads the route this built.
_fanout(draft, entry, base, comp, inner, diags) =
    reduce(vcat, (resolve_dest(draft, entry, base, comp, p, diags) for p in _endpoints(inner));
           init = Tuple{String,Symbol}[])

# Direction is declared by the method; the resolved endpoint only cross-checks it.
# The mismatch is recorded, never thrown: the wire simply resolves to nothing.
function _wrong_direction(entry, path, comp_path, name, comp, wanted, diags)
    input_names, output_names = input_faces(comp), output_faces(comp)
    found = String(name) in input_names ? "an input" :
            String(name) in output_names ? "an output" : nothing
    if found === nothing
        push!(diags, UnknownPort(entry = entry,
                                endpoint = wanted == "producer" ? :source : :destination,
                                path = comp_path, spelling = String(path), port = name,
                                candidates = Symbol.(vcat(input_names, output_names))))
        return nothing
    end
    push!(diags, FaceDirectionConflict(entry = entry, path = comp_path,
                                      spelling = String(path),
                                      found = found == "an input" ? :input : :output,
                                      wanted = Symbol(wanted)))
    nothing
end

# --- the flatten pass ---------------------------------------------------------

"""
One `sample_times` link (§9.1, D-253): the declaring assembly's path, the key as
`_rate_entry` returned it, and the `Relative` or `Absolute` value under it.
"""
const RateLink = @NamedTuple{scope::String, key::Symbol, entry::Union{Relative,Absolute}}

"The sample-time fold's value for one scope or component (§9.1): the anchor it hangs from (0 the base grid), and its period multiple and phase in that anchor's ticks."
const Timing = @NamedTuple{anchor::Int, m::Int, c::Int}

"""One keyed scope: the assembly an explicit `sample_times` key names, and its timing."""
const RateScope = @NamedTuple{path::String, key::Symbol, timing::Timing}

"""
One anchor (§9.1, §9.2): the exact `(T, τ)` an `Absolute` entry seeds, with
the `sample_times` entry that declared it, by scope path and key. Anchor 0,
the base grid, has no record here; it is symbolic until `Δt_base` binds.
"""
struct Anchor
    T::Rational{Int}
    τ::Rational{Int}
    scope::String
    key::Symbol
end

"""
One component of the structure (§9.1): its path, the instance, the tier the
walk read, the `sample_times` links met on the way down and the timing the
fold made of them, and each declared input face resolved to its producer.
"""
struct ComponentEntry
    path::String
    instance::AbstractComponent
    tier::Tier
    rates::Vector{RateLink}
    timing::Timing
    conns::Vector{Pair{Symbol,Tuple{String,Symbol}}}   # face => (producer path, port)
end

"""
The structure step's product (§9.1, D-253): everything the root instance alone
fixes, nothing in it depending on a scalar type, held as rows (D-261). One
`ComponentEntry` per primitive in walk order — its absolute path, instance and
tier, the `sample_times` links met on the way down and the timing the fold made
of them, and one resolved producer per declared input — and one `Anchor` per
`Absolute` entry, the exact `(T, τ)` with the declaring scope and key. Beside
them each keyed scope's own timing, the root's input faces (the
[root inputs](§11.3)) with the types the wire pass fixed, and §9.2's two-sided
face table — the assembly faces the periphery may read, aliased onto the cells
they derive from, and beside them every input face at every level with the
producer it routes to. The input side is total: one-level routing gives every
signal crossing a boundary a declared face there (D-207), so a fragment's
`inputs` payload resolves from any authoring level (§14.2). The root itself is
retained, because the service walk resolves against the tree the paths index
rather than against the compiled list (§13.3). The component index `ci` is the
position in `components`; nothing pushes into a `Structure`'s vectors after
construction.
"""
struct Structure
    root::AbstractComponent                # the tree the paths index (§13.3's service walk)
    components::Vector{ComponentEntry}     # in walk order; the index is `ci` everywhere
    anchors::Vector{Anchor}                # anchors 1…K
    scopes::Vector{RateScope}              # one row per keyed assembly, in walk order
    root_inputs::Vector{Symbol}            # root input faces, in order
    root_types::Vector{Type}               # per root input: the type the wire pass fixed (D-236, D-261)
    in_faces::Vector{Pair{Tuple{String,Symbol},Tuple{String,Symbol}}}   # (path, face) => producer
    out_faces::Vector{Pair{Tuple{String,Symbol},Tuple{String,Symbol}}}  # (path, face) => producer
end

# The structure step's accumulator, disposable: the per-component columns the
# `Structure`'s rows are built from at the barrier, with the slack the dirty
# pass needs (a tier is `nothing` where a store-form failure was recorded, and
# narrows on the clean walk `wire!` runs on), plus the walk's scratch — the
# claims, the routes and the evaluated face lists. `conns` and `in_faces` are
# not here — they are derived past the barrier, by `wire!` itself — and neither
# are the root-input types, which the wire pass fixes (D-236) and the
# `Structure` takes at construction (D-261). Violations are not held here
# either: the step's list is an argument of every helper that can add to it.
struct StructureDraft
    root::AbstractComponent
    paths::Vector{String}
    instances::Vector{AbstractComponent}
    tiers::Vector{Union{Nothing,Tier}}   # per primitive, beside `paths`; `nothing` = recorded
    rates::Vector{Vector{RateLink}}      # per primitive: the links met on the way down
    timings::Vector{Timing}              # per primitive: the fold's value
    anchors::Vector{Anchor}
    scopes::Vector{RateScope}
    root_inputs::Vector{Symbol}
    out_faces::Vector{Pair{Tuple{String,Symbol},Tuple{String,Symbol}}}
    feeds::Dict{Tuple{String,Symbol},Tuple{String,Symbol}}
    claims::Dict{Tuple{String,Symbol},String}                  # who claimed it, for the message
    routes::Vector{Tuple{String,Symbol,Vector{Tuple{String,Symbol}}}}   # (path, face, consumers)
    faces::IdDict{Any,Tuple{Vector{String},Vector{String}}}   # per assembly instance, (inputs, outputs)
end

StructureDraft(root::AbstractComponent) =
    StructureDraft(root, String[], AbstractComponent[],
                   Union{Nothing,Tier}[],
                   Vector{RateLink}[], Timing[],
                   Anchor[], RateScope[],
                   Symbol[],
                   Pair{Tuple{String,Symbol},Tuple{String,Symbol}}[],
                   Dict{Tuple{String,Symbol},Tuple{String,Symbol}}(),
                   Dict{Tuple{String,Symbol},String}(),
                   Tuple{String,Symbol,Vector{Tuple{String,Symbol}}}[],
                   IdDict{Any,Tuple{Vector{String},Vector{String}}}())

function index_of(structure::Structure, path::String)
    ci = findfirst(entry -> entry.path == path, structure.components)
    ci === nothing && throw(InternalInvariant("no component at path `$path`"))
    ci
end
function index_of(draft::StructureDraft, path::String)
    ci = findfirst(==(path), draft.paths)
    ci === nothing && throw(InternalInvariant("no component at path `$path`"))
    ci
end

"""
The running walk's evaluated face lists (§13.3, Appendix C): `flatten!` binds it
around the walk, so a primitive asked for an assembly's faces while the walk runs
— by a passthrough helper inside a parent's body, or by endpoint resolution
building a did-you-mean list — reads the lists the walk already evaluated rather
than evaluating the body again. Unbound outside a walk, where the primitives
evaluate the body themselves. Keyed by instance because the helpers name a child
by a path relative to the assembly, never absolutely, and a face list is a
function of the instance's value (§8.8).
"""
const WALK_FACES = ScopedValue{Union{Nothing,IdDict{Any,Tuple{Vector{String},Vector{String}}}}}(nothing)

# --- the sample-time fold (§8.7, §9.1, §10.5) -----------------------------------
# Nested rate declarations compile to one `(anchor, m, c)` timing per component,
# folding down the tree beside the wiring walk: the root scope seeds
# `(A₀, 1, 0)`, `Relative(K, φ)` under a scope at `(a, mₛ, cₛ)` steps to
# `(a, K·mₛ, cₛ + φ·mₛ)`, and `Absolute` severs and re-seeds a fresh anchor at
# `(Aₖ, 1, 0)` — a nested anchor simply severs again. Anchor 0 is the base grid,
# symbolic until deployment binds `Δt_base`: final divisors for anchored entries
# do not exist until then (§9.1). The canonical residue `c < m` holds within each
# anchor's subtree by the affine law's one-line induction.

"""
Validate a scope's `sample_times` against §10.5's constraints, with path
attribution (§9.1, §13.1): wrapper-typed values only, `K ≥ 1`, `0 ≤ φ < K`,
`T > 0`, `0 ≤ τ < T`, and every key naming an immediate child.
"""
function _check_sample_times(path::String, rate_decl, kids, fields, diags::Vector{Diagnostic})
    record_violation(reason; kw...) =
        push!(diags, RatesViolation(; path = path, reason = reason, kw...))
    if !(rate_decl isa NamedTuple)
        record_violation(:declaration_shape)       # nothing further is iterable
        return nothing
    end
    for (key, rate) in pairs(rate_decl)
        if !(rate isa Relative || rate isa Absolute)
            record_violation(:value_vocabulary; key = key, value = rate)
            continue                               # neither residue arm applies
        end
        # The residue bound is stated against the multiplier, so an invalid `K`
        # (or `T`) leaves `φ` (or `τ`) with nothing to be measured against: the
        # dependent check is skipped, not doubled up.
        if rate isa Relative
            rate.K ≥ 1 ? (0 ≤ rate.φ < rate.K ||
                          record_violation(:phase; key = key, value = rate.φ)) :
                         record_violation(:multiplier; key = key, value = rate.K)
        else
            rate.T > 0 ? (0 ≤ rate.τ < rate.T ||
                          record_violation(:offset; key = key, value = rate.τ)) :
                         record_violation(:period; key = key, value = rate.T)
        end
        any(seg == String(key) for (seg, _) in kids) ||
            any(String(fld) == String(key) for fld in fields) ||
            record_violation(:unknown_child; key = key,
                             candidates = String[first(p) for p in kids])
    end
    nothing
end

# The entry scheduling the child at segment `segment`, contributed by field `field`, or
# `nothing` for the `Relative(1)` default. Exact match first; then the bare field
# name, which applies one declaration to every element of a container (§8.7). The
# sugar keys on the *field*, so a name-transparent container keeps it unchanged:
# `(children = Relative(2),)` is the uniform spelling for a `Group` (D-211).
function _rate_entry(rate_decl, segment::String, field::Symbol)
    rate_decl isa NamedTuple || return nothing         # the shape refusal is already collected
    for (k, v) in pairs(rate_decl)
        String(k) == segment && return (k, v)
    end
    for (k, v) in pairs(rate_decl)
        String(k) == String(field) && return (k, v)
    end
    nothing
end

"""The chain a child walks under: the links above it, plus its own when it has one."""
_extend(chain::Vector{RateLink}, link::Union{Nothing,RateLink}) =
    link === nothing ? copy(chain) : push!(copy(chain), link)

"""
The child's scope timing, and the link an explicit key declared — the declaring
assembly's path, the key as `_rate_entry` returned it, and the wrapper value —
or `nothing` for an unlisted child. The unlisted child continues at the
enclosing timing: the `Relative(1)` default is the affine law at
`(K, φ) = (1, 0)`, implemented by nothing.
"""
function _child_scope(draft::StructureDraft, path::String, rate_decl, segment::String,
                      field::Symbol, scope::Timing)
    hit = _rate_entry(rate_decl, segment, field)
    hit === nothing && return scope, nothing
    (key, rate) = hit
    # `_check_sample_times` collects rather than throwing (§13.1), so the fold
    # runs on past a value outside the wrapper vocabulary — which has no affine
    # law to apply. The violation is already recorded; the child continues at the
    # enclosing scope, as an unlisted one would.
    (rate isa Relative || rate isa Absolute) || return scope, nothing
    link = RateLink((scope = path, key = key, entry = rate))
    if rate isa Relative
        Timing((scope.anchor, rate.K * scope.m, scope.c + rate.φ * scope.m)), link
    else
        # One anchor per `Absolute` entry (§9.1): a bare container key applies one
        # declaration to every element (§8.7), so the elements share the anchor
        # the first of them established rather than each pushing a twin.
        anchor_index = findfirst(anchor -> anchor.scope == path && anchor.key === key,
                                 draft.anchors)
        if anchor_index === nothing
            push!(draft.anchors, Anchor(rate.T, rate.τ, path, key))
            anchor_index = length(draft.anchors)
        end
        Timing((anchor_index, 1, 0)), link
    end
end

"""
    flatten!(draft, root, diags)

The tree walk of the structure step (§9.1): components collected by path, classes and
tiers read, wiring resolved to absolute leaf terminals, sample times folded to
`(anchor, m, c)` timings, the one-producer-per-input and whole-tree obligation
rules checked. Violations are recorded in `diags` and the walk runs on; the
throw is `build`'s, at the step barrier. Any component may be the root
(D-208) — a primitive one flattens to the single leaf at the root path, its
`input_types` keys the model's root inputs.
"""
function flatten!(draft::StructureDraft, root, diags::Vector{Diagnostic})
    # the root scope: anchor 0, the base grid itself; no link above it and none of its own.
    # The face memo is the walk's own and is bound around it alone: the obligation
    # loop below reads `input_types`, never a face list.
    with(WALK_FACES => draft.faces) do
        _walk!(draft, "", root, Timing((0, 1, 0)), RateLink[], nothing, diags)
    end

    # The obligation model (§6.1): an input is fed by a wire in some ancestor's
    # `child_connections` or by an `input_connections` chain handing it up level
    # by level, and the chain that never terminates is the error. The one
    # legitimate unfed terminus is the root's own input face. A wire that failed
    # to resolve claimed nothing, so the input it should have fed is reported
    # here beside the refusal itself.
    for (path, instance) in zip(draft.paths, draft.instances)
        at_component(path) do
            for (face, declared) in pairs(_contract(input_types, instance))
                haskey(draft.feeds, (path, face)) ||
                    push!(diags, UnconnectedInput(path = path, face = face,
                                                 declared = declared,
                                                 level = _last_level(draft, path, face)))
            end
        end
    end
    nothing
end

# The obligation chain's last level (§6.1): the topmost face an
# `input_connections` chain handed `(path, face)` up to — the shortest route path
# naming it as a consumer, an ancestor's path being a prefix of the leaf's. The
# leaf's own path when no route names it: `draft.routes` records only routes with
# consumers, so an entry nobody handed up has no row.
function _last_level(draft::StructureDraft, path::String, face::Symbol)
    level = path
    for (route_path, _, consumers) in draft.routes
        (path, face) in consumers && length(route_path) < length(level) && (level = route_path)
    end
    level
end

"""
§9.2's input side, derived on a walk the barrier has already proved clean: every
input is fed exactly once, so an assembly's face and the leaf entries behind it
share the one producer above them and `(path, face) => producer` is well
defined. A primitive's own entries complete the record, so the graph carries
every input face at every level, whatever the level's class. Returns the
per-component `conns` and the `in_faces` table; the `Structure` is built from
them once the wire pass has fixed the root-input types.
"""
function wire!(draft::StructureDraft)
    conns = Vector{Pair{Symbol,Tuple{String,Symbol}}}[]
    in_faces = Pair{Tuple{String,Symbol},Tuple{String,Symbol}}[]
    for (path, instance) in zip(draft.paths, draft.instances)
        push!(conns, [face => draft.feeds[(path, face)]
                      for face in keys(_contract(input_types, instance))])
    end
    for (path, face, consumers) in draft.routes
        push!(in_faces, (path, face) => draft.feeds[first(consumers)])
    end
    for (path, comp_conns) in zip(draft.paths, conns), (face, producer) in comp_conns
        push!(in_faces, (path, face) => producer)
    end
    conns, in_faces
end

# The structure step's last act (D-261): the artifact, complete at construction,
# its rows built from the draft's columns, what `wire!` derived and the
# root-input types the wire pass fixed. The walk is clean, so no recorded
# failure is left and the tiers and root types narrow (§13.1, D-229). No code
# pushes into a `Structure`'s vector after this call.
Structure(draft::StructureDraft, conns::Vector{Vector{Pair{Symbol,Tuple{String,Symbol}}}},
          in_faces::Vector{Pair{Tuple{String,Symbol},Tuple{String,Symbol}}},
          root_types::Vector{Any}) =
    Structure(draft.root,
              [ComponentEntry(path, instance, tier, rates, timing, cs)
               for (path, instance, tier, rates, timing, cs) in
                   zip(draft.paths, draft.instances, Vector{Tier}(draft.tiers),
                       draft.rates, draft.timings, conns)],
              draft.anchors, draft.scopes, draft.root_inputs, Vector{Type}(root_types),
              in_faces, draft.out_faces)

# `chain` is the links above `comp`, outermost first, and `link` its own — the
# entry the enclosing assembly's `sample_times` named it under, or `nothing`.
function _walk!(draft::StructureDraft, path::String, comp, scope::Timing,
                chain::Vector{RateLink}, link::Union{Nothing,RateLink},
                diags::Vector{Diagnostic})
    # The forgotten import (§8.1, D-246), first and alone: a module holding a
    # foreign binding of a family name declares nothing the framework can read,
    # so the class below would be read off an empty set. `ClassUnreadable` is
    # fail-fast too, and would throw alone with a message that is false from the
    # author's chair — the declarations were written, to the wrong function.
    foreign = foreign_declarations(comp)
    isempty(foreign) || throw(DiagnosticError(DeclarationShadowed(
        path = path, names = foreign,
        parent_module = string(parentmodule(typeof(comp))))))
    if classify(path, comp) === PRIMITIVE
        # Everything below reads this primitive's own declarations, so it runs
        # under the component frame: an accessor's `UserCodeFraming` leaves the
        # path empty and this is where the path is known (§13.2, D-248).
        return at_component(path) do
            push!(draft.paths, path)
            push!(draft.instances, comp)
            push!(draft.timings, scope)
            push!(draft.rates, _extend(chain, link))
            # The store-form check (§8.2, D-247) gates the rest: the tier classifier
            # and the two field checks read a store value as a `NamedTuple`, so a
            # primitive that fails the form is read no further. The one tier
            # classification (§8.2) follows: a failure is recorded and the walk
            # carries `nothing` where the tier would be.
            if check_store_form(path, comp, diags)
                tier = classify_tier(path, comp, diags)
                check_stores(path, comp, diags)
                check_state_leaves(path, comp, diags)
            else
                tier = nothing                      # D-247: read no further
            end
            push!(draft.tiers, tier)
            # A primitive at the root: its `input_types` keys are the model's root
            # inputs, each face its own consuming entry (§8.6, §11.3, D-208), fed by
            # the same pseudo-producer an assembly root's faces get.
            if isempty(path)
                _check_root_faces(comp, diags)
                for face in keys(_contract(input_types, comp))
                    push!(draft.root_inputs, face)
                    _claim!(draft, (path, face), ("", face),
                            "the root component's `input_types` entry `$face`", diags)
                end
            end
            tier
        end
    end
    at_component(path) do
        # One row per assembly an explicit key names, in walk order: the scope a
        # `sample_times` key opened, with the timing everything under it folds from.
        link === nothing ||
            push!(draft.scopes, RateScope((path = path, key = link.key, timing = scope)))
        below = _extend(chain, link)
        rate_decl = invoke_declaration(sample_times, comp)
        kids, fields = _children(path, comp)
        _check_sample_times(path, rate_decl, kids, fields, diags)
        for ((segment, kid), field) in zip(kids, fields)
            child_path = _join(path, segment)
            kid_scope, kid_link = _child_scope(draft, path, rate_decl, segment, field, scope)
            # a primitive's tier, `nothing` for an assembly
            tier = _walk!(draft, child_path, kid, kid_scope, below, kid_link, diags)
            # A key on a continuous child is the Δt-on-continuous error at
            # declaration time (§8.7): keys name discrete or scope children only.
            kid_link !== nothing && tier === CONTINUOUS &&
                push!(diags, RatesViolation(path = path, reason = :continuous_child,
                                           key = Symbol(segment)))
        end

        # The boundary declarations are read only after the children are walked: a
        # computed entry (`input_passthrough`, §8.8) classifies the child it names,
        # and a shadowed child must meet its own check above first, at its own path
        # (D-246). Each body is evaluated exactly once and its entries reused by
        # the name check and by the face loop below: a warning raised inside one
        # fires once per call (Appendix C).
        input_entries = invoke_declaration(input_connections, comp)
        output_entries = invoke_declaration(output_connections, comp)
        # The evaluated lists, recorded for the primitives (`WALK_FACES`): the
        # readers are a parent's own body and its wire resolution, both later, so
        # nothing below this line reads the row just written.
        draft.faces[comp] = (String[String(f) for (f, _) in input_entries],
                             String[String(f) for (_, f) in output_entries])
        _check_face_names(path, input_entries, output_entries, diags)

        for pair in invoke_declaration(child_connections, comp)
            entry = _entry("child_connections", path, pair)
            producer = resolve_source(draft, entry, path, comp, first(pair), diags)
            producer === nothing && continue   # recorded; the destination stays unfed
            for consumer in resolve_dest(draft, entry, path, comp, last(pair), diags)
                _claim!(draft, consumer, producer, entry, diags)
            end
        end

        # Both boundary declarations are resolved wherever they appear, so their
        # entries are checked at every level; only the root's input faces *feed*
        # anything, there being no parent above them to claim the obligation.
        for (face, inner) in input_entries
            entry = _entry("input_connections", path, face => inner)
            consumers = _fanout(draft, entry, path, comp, inner, diags)
            # Every entry routes to at least one internal endpoint, at every level
            # (D-210): a face feeding nothing declares nothing, and the empty tuple
            # would otherwise reach no consumer, leave no row in §9.2's face graph,
            # and let a condition addressing it misdiagnose as a bare typo. Declared
            # empty is the refusal; empty because every endpoint failed to resolve is
            # already recorded, and registers nothing more.
            if isempty(consumers)
                isempty(_endpoints(inner)) &&
                    push!(diags, UnknownPort(entry = entry, endpoint = :connection,
                                            path = path, port = Symbol(face)))
                continue                       # a route with no consumer registers nothing
            end
            push!(draft.routes, (path, Symbol(face), consumers))
            isempty(path) || continue
            push!(draft.root_inputs, Symbol(face))
            for consumer in consumers
                _claim!(draft, consumer, ("", Symbol(face)), entry, diags)
            end
        end
        for (source, face) in output_entries
            entry = _entry("output_connections", path, source => face)
            producer = resolve_source(draft, entry, path, comp, source, diags)
            producer === nothing && continue   # recorded; the face registers no row
            push!(draft.out_faces, (path, Symbol(face)) => producer)
        end
    end
    nothing
end

_entry(method::String, path::String, pair::Pair) =
    "$method at $(_at_path(path)), entry `$(repr(first(pair))) => $(repr(last(pair)))`"

# Every input takes exactly one connection, and the rule spans levels (§6.1): an
# input fed both by a sibling wire and by an ancestor's route — or handed up while
# also wired — meets its second claim here.
function _claim!(draft::StructureDraft, consumer, producer, entry::String,
                 diags::Vector{Diagnostic})
    if haskey(draft.feeds, consumer)
        push!(diags, TwoProducers(path = consumer[1], port = consumer[2],
                                 incumbent = draft.claims[consumer], entry = entry,
                                 incumbent_producer = _terminal(draft.feeds[consumer]),
                                 producer = _terminal(producer)))
        return nothing                     # the incumbent keeps the claim
    end
    draft.feeds[consumer] = producer
    draft.claims[consumer] = entry
    nothing
end

# §8.6's two face-name invariants, over the boundary entries the walk already
# evaluated. Every other naming choice is author convention.
function _check_face_names(path::String, input_entries, output_entries, diags::Vector{Diagnostic})
    names = vcat(String[String(face) for (face, _) in input_entries],
                 String[String(face) for (_, face) in output_entries])
    for n in names
        occursin('/', n) &&
            push!(diags, FaceNameIllegal(path = path, face = n, invariant = :contains_slash))
    end
    allunique(names) ||
        push!(diags, FaceNameCollision(path = path, site = :assembly,
                                      faces = unique(n for n in names
                                                     if count(==(n), names) > 1)))
    nothing
end

# The same invariant at a *primitive* root, whose face set is its two contract
# declarations' keys together (§8.6, D-210). The root is where those two first
# share the periphery's address space: a root input places a cell of its own, so
# a shared key would put two cells at one name and the root input's placement
# would silently overwrite the port's. Below the root nothing collides — a
# primitive's input faces alias their producers' cells and place nothing — and
# non-root leaves are left alone.
function _check_root_faces(comp, diags::Vector{Diagnostic})
    output_names = String.(keys(_contract(output_types, comp)))
    duplicates = [n for n in String.(keys(_contract(input_types, comp))) if n in output_names]
    isempty(duplicates) ||
        push!(diags, FaceNameCollision(path = "", faces = duplicates, site = :root))
    nothing
end
