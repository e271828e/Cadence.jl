# The compiled executor (§9.7): schedule entries carrying what selects code in
# type parameters and what is plain data in fields, gathered into chunked
# statically-typed tuples behind non-inlined barriers, traversed by a
# compile-time-unrolled walk.

# --- the execution cursor (§13.4, D-059) ---------------------------------------

"""
Where in the compiled schedule execution is (§13.4): one plain mutable struct
the executor owns, overwritten by one cheap store per user-code dispatch and
one per phase transition, read only at the catch site (`_wrap_step`, sim.jl).
No allocation and no exception frames — framing information does not need to
be caught into existence. The cursor holds its dispatch fields alone: a `t*`
stop hit is `frame!`'s return value, never a field here (§13.5, D-261).
"""
mutable struct ExecutionCursor
    comp::Int        # the component's index in the flat, 0 = none
    fn::Symbol       # :output_state | :output_direct | :state_derivative | :state_update |
                     # :guard | :handler | :state_projection | :none
    phase::Symbol    # :drain | :integrate | :arrival | :validation | :trial | :project | :round | :ticks
    index::Int       # the RK stage, the event round, the trial ordinal; 0 where none applies
end
ExecutionCursor() = ExecutionCursor(0, :none, :drain, 0)

"A phase transition: written by the loop, never per dispatch (§13.4)."
@inline function _phase!(cursor::ExecutionCursor, phase::Symbol, index::Int = 0)
    cursor.phase = phase
    cursor.index = index
    nothing
end

# --- entries ------------------------------------------------------------------
# Three kinds, by where the product comes from and where it goes: a stage entry
# writes cells (both tiers — one entry type carries either tier's output stage,
# one shared pair of names over both tiers (D-220), an RHS entry writes the flat
# `ẋ` buffer, and an update entry writes its own discrete state store. All three
# build their §5.2 bundle the same way, from `BN` — the bundle name set the law
# fixed at build time.
#
# What selects code sits in type parameters, what varies per instance in fields
# (§9.7): the state store is a `Ref` whose *type* is shared by every instance of
# a component type, so two instances still compile to one body.

struct StageEntry{F,Comp,XT,BN,IA<:NamedTuple,YA<:NamedTuple,OA<:NamedTuple,CL,SS,MS,WS}
    fn::F
    comp::Comp
    inputs::IA      # input face => cell address (the wiring's name binding)
    y1::YA          # own stage-1 port => cell address (`y_x`, `y_s` on the discrete tier)
    outputs::OA        # port this entry writes => cell address
    x_off::Int      # continuous state offset into the flat buffer
    clock::CL
    sstore::SS      # discrete state store, or nothing on the continuous tier
    mstore::MS      # mode store, or nothing
    ws::WS          # workspace, or nothing
    Δt::Float64     # sample period; unused on the continuous tier
    path::String    # the component's path, for the write's diagnostic (§9.5)
    ci::Int         # the schedule index, for the cursor's store (§13.4)
    fn_name::Symbol   # `nameof(fn)`, computed once in `compile`: a field read, never a call
    cursor::ExecutionCursor
end

struct RHSEntry{Comp,XT,BN,IA<:NamedTuple,YA<:NamedTuple,CL,MS,WS}
    comp::Comp
    inputs::IA
    y::YA           # every own port — `state_derivative` reads the complete fresh table (§5.3)
    x_off::Int
    clock::CL
    mstore::MS
    ws::WS
    path::String
    ci::Int
    cursor::ExecutionCursor
end

struct UpdateEntry{Comp,BN,IA<:NamedTuple,YA<:NamedTuple,CL,SS,WS}
    comp::Comp
    inputs::IA
    y::YA           # every own port — `state_update` reads the complete fresh table too
    clock::CL
    sstore::SS      # written by this entry, and by nothing else
    ws::WS
    Δt::Float64
    path::String
    ci::Int
    cursor::ExecutionCursor
end

# Outer constructors: only `XT`/`BN` cannot be inferred from the arguments.
StageEntry{XT,BN}(fn, comp, inputs, y1, outputs, x_off, clock, sstore, mstore, ws, Δt,
                  path, ci, cursor) where {XT,BN} =
    StageEntry{typeof(fn),typeof(comp),XT,BN,typeof(inputs),typeof(y1),typeof(outputs),
               typeof(clock),typeof(sstore),typeof(mstore),typeof(ws)}(
        fn, comp, inputs, y1, outputs, x_off, clock, sstore, mstore, ws, Δt,
        path, ci, nameof(fn), cursor)

RHSEntry{XT,BN}(comp, inputs, y, x_off, clock, mstore, ws, path, ci, cursor) where {XT,BN} =
    RHSEntry{typeof(comp),XT,BN,typeof(inputs),typeof(y),typeof(clock),
             typeof(mstore),typeof(ws)}(comp, inputs, y, x_off, clock, mstore, ws,
                                        path, ci, cursor)

UpdateEntry{BN}(comp, inputs, y, clock, sstore, ws, Δt, path, ci, cursor) where {BN} =
    UpdateEntry{typeof(comp),BN,typeof(inputs),typeof(y),typeof(clock),
                typeof(sstore),typeof(ws)}(comp, inputs, y, clock, sstore, ws, Δt,
                                           path, ci, cursor)

# One bundle-expression builder, three @generated entry points. Absent names are
# absent, never `nothing`-filled: a body destructuring what it does not own
# fails at the destructuring (§5.2). The two state letters name the two homes
# outright (D-195): `x` reconstructs from the flat buffer, `s` reads the
# component's own store, and no name selects a home by tier at compile time
# because the tier already picked the name.
function _bundle_expr(BN, XT)
    args = map(BN) do field
        field === :x   ? :(reconstruct($XT, xbuf, e.x_off)) :
        field === :s   ? :(e.sstore[]) :
        field === :m   ? :(e.mstore[]) :
        field === :u   ? :(gather_group(e.inputs, store)) :
        field === :y_x ? :(gather_group(e.y1, store)) :
        field === :y_s ? :(gather_group(e.y1, store)) :
        field === :y   ? :(gather_group(e.y, store)) :
        field === :ws  ? :(e.ws) :
        field === :t   ? :(e.clock.t) :
        field === :Δt  ? :(e.Δt) :
        throw(InternalInvariant("no source for bundle field $field"))
    end
    :(NamedTuple{$BN}(($(args...),)))
end

@generated function make_bundle(e::StageEntry{F,Comp,XT,BN}, store,
                                xbuf) where {F,Comp,XT,BN}
    quote
        $(Expr(:meta, :inline))
        $(_bundle_expr(BN, XT))
    end
end

@generated function make_bundle(e::RHSEntry{Comp,XT,BN}, store, xbuf) where {Comp,XT,BN}
    quote
        $(Expr(:meta, :inline))
        $(_bundle_expr(BN, XT))
    end
end

@generated function make_bundle(e::UpdateEntry{Comp,BN}, store, xbuf) where {Comp,BN}
    quote
        $(Expr(:meta, :inline))
        $(_bundle_expr(BN, Nothing))
    end
end

@inline function run_entry!(entry::StageEntry, store, xbuf, ẋbuf)
    entry.cursor.comp = entry.ci; entry.cursor.fn = entry.fn_name     # the dispatch store (§13.4)
    y = entry.fn(entry.comp, make_bundle(entry, store, xbuf))
    scatter_group!(store, entry.outputs, y, activation_scalar(entry.clock), entry.path, entry.fn_name)
end

@inline function run_entry!(entry::RHSEntry{Comp,XT}, store, xbuf, ẋbuf) where {Comp,XT}
    entry.cursor.comp = entry.ci; entry.cursor.fn = :state_derivative
    ẋ = state_derivative(entry.comp, make_bundle(entry, store, xbuf))
    flatten_state!(ẋbuf, entry.x_off, ẋ, XT, activation_scalar(entry.clock), entry.path,
                   :state_derivative, :init_x, nothing)
    nothing
end

# The jump map: `state_update` reads the fresh table and writes only its own
# store, which is what makes the update block order-free with disjoint writes
# (§9.7).
@inline function run_entry!(entry::UpdateEntry, store, xbuf, ẋbuf)
    entry.cursor.comp = entry.ci; entry.cursor.fn = :state_update
    _store_successor!(entry.sstore, state_update(entry.comp, make_bundle(entry, store, xbuf)),
                      entry.path, :state_update)
    nothing
end

# --- the event machinery (§10.6, §5.3) ------------------------------------------
# Not sweep entries: guards and handlers are driven by the boundary iteration in
# `sim.jl`, against per-event registers, so their entries live in their own
# compiled set. One entry per declared event, carrying both halves plus its
# component's `state_projection` (or `nothing`), and a global index into the register
# vectors — global order is executor component order, then declaration order
# within a component, which is what makes the §13.4-style dispatch order
# deterministic. Bundles are built exactly like every other entry's, from the
# event name set the law fixed at build time (`x, m, u, y, ws, t`, §5.2).

struct EventEntry{G,H,P,Comp,XT,BN,IA<:NamedTuple,YA<:NamedTuple,CL,MS,WS}
    guard::G
    handler::H
    projection::P         # the component's `state_projection`, or nothing
    comp::Comp
    event_index::Int        # global event index into the register vectors
    inputs::IA
    y::YA           # every own port — guards and handlers read the complete fresh table
    x_off::Int
    clock::CL
    mstore::MS
    ws::WS
    path::String
    event::Symbol   # the event this entry declares, for a handler write's diagnostic
    ci::Int
    cursor::ExecutionCursor
end

EventEntry{XT,BN}(guard, handler, projection, comp, event_index, inputs, y, x_off, clock,
                  mstore, ws, path, event, ci, cursor) where {XT,BN} =
    EventEntry{typeof(guard),typeof(handler),typeof(projection),typeof(comp),XT,BN,
               typeof(inputs),typeof(y),typeof(clock),typeof(mstore),typeof(ws)}(
        guard, handler, projection, comp, event_index, inputs, y, x_off, clock, mstore, ws,
        path, event, ci, cursor)

@generated function make_bundle(e::EventEntry{G,H,P,Comp,XT,BN}, store,
                                xbuf) where {G,H,P,Comp,XT,BN}
    quote
        $(Expr(:meta, :inline))
        $(_bundle_expr(BN, XT))
    end
end

"""
Projection between a state write and its decode (§5.3): reconstruct, project,
write back wholesale — the write itself holding the return to §9.5's check
against the state's shape at this activation (D-235).
"""
struct ProjectEntry{Comp,XT,CL}
    comp::Comp
    x_off::Int
    clock::CL
    path::String
    ci::Int
    cursor::ExecutionCursor
end
ProjectEntry{XT}(comp, x_off, clock, path, ci, cursor) where {XT} =
    ProjectEntry{typeof(comp),XT,typeof(clock)}(comp, x_off, clock, path, ci, cursor)

@inline function run_project!(entry::ProjectEntry{Comp,XT}, xbuf) where {Comp,XT}
    entry.cursor.comp = entry.ci; entry.cursor.fn = :state_projection
    flatten_state!(xbuf, entry.x_off,
                   state_projection(entry.comp, reconstruct(XT, xbuf, entry.x_off)),
                   XT, activation_scalar(entry.clock), entry.path, :state_projection,
                   :state, nothing)
    nothing
end

"""
The per-`Simulation` compiled event set: the entry tuples plus the §10.6
registers. The three normative registers — prior, last-observed sample, firing
count — are detection bookkeeping, not model memory: plain vectors indexed by
the global event index, in no state store, reconstructed deterministically.
`now`, `fire` and `comp_fired` are the iteration's round-scoped scratch, and
`warned` implements "at most once per event per boundary" for the
`FiringBudget` degradation.

The localization registers (§10.4) sit beside them: `localized` is the
runtime's read, fixed at compilation, of the policies the `Events` rows carry;
`σ` holds each sign-form guard's numeric sample from the latest walk (`now`
holds its predicate, `σ ≥ 0`); `σ0`/`σ1` retain the θ = 0 validation and arrival
samples across the trials that clobber `σ`; `trig` is the frame's triggered set
and `loc_warned` the `ChatteringBudget` once-per-event-per-frame latch.
"""
struct EventSet{E<:Tuple,P<:Tuple}
    entries::E
    projects::P
    owner::Vector{Int}                   # component index per event
    names::Vector{Tuple{String,Symbol}}  # (path, event name), for the degradation warnings
    localized::Vector{Bool}              # detection policy per event (§10.4)
    now::Vector{Bool}
    prior::Vector{Bool}
    last::Vector{Bool}
    fire::Vector{Bool}
    count::Vector{Int}
    warned::Vector{Bool}
    comp_fired::Vector{Bool}             # per component, round-scoped
    σ::Vector{Float64}
    σ0::Vector{Float64}
    σ1::Vector{Float64}
    trig::Vector{Bool}
    loc_warned::Vector{Bool}
end

function EventSet(entries::Vector, projects::Vector,
                  owner::Vector{Int}, names::Vector{Tuple{String,Symbol}},
                  localized::Vector{Bool}, n_components::Int)
    n_events = length(entries)
    EventSet(tuple(entries...), tuple(projects...), owner, names, localized,
             fill(false, n_events), fill(false, n_events), fill(false, n_events),
             fill(false, n_events), zeros(Int, n_events), fill(false, n_events),
             fill(false, n_components), zeros(n_events), zeros(n_events),
             zeros(n_events), fill(false, n_events), fill(false, n_events))
end

# The three walks the iteration drives, each the compile-time-unrolled tuple
# recursion of the phase bodies, over the executor's buffers the caller hands
# them (D-261). Guard evaluation writes each predicate sample into `now` by
# global index; the fire walk runs `handler → state_projection` for exactly the
# masked entries, latching the returned stores — `x` into the flat buffer, `m`
# merged into the mode store, per the return law's iff shape (§5.2).

@noinline _projects!(event_set::EventSet, xbuf) = _proj_walk(event_set.projects, xbuf)
@inline _proj_walk(::Tuple{}, xbuf) = nothing
@inline function _proj_walk(projects::Tuple, xbuf)
    run_project!(projects[1], xbuf)
    _proj_walk(Base.tail(projects), xbuf)
end

@noinline _guards!(event_set::EventSet, store, xbuf) =
    _guard_walk(event_set.entries, store, xbuf, event_set.now, event_set.σ)
@inline _guard_walk(::Tuple{}, store, xbuf, now, σs) = nothing
@inline function _guard_walk(entries::Tuple, store, xbuf, now, σs)
    entry = entries[1]
    entry.cursor.comp = entry.ci; entry.cursor.fn = :guard
    σ = entry.guard(entry.comp, make_bundle(entry, store, xbuf))
    now[entry.event_index] = _holding(σ)
    # The numeric sample, for the localization brackets (§10.4). The guard's
    # return type is in the entry's type, so the branch folds per entry: a
    # `Bool` guard never touches the register.
    σ isa Bool || (σs[entry.event_index] = σ)
    _guard_walk(Base.tail(entries), store, xbuf, now, σs)
end

@noinline _fire!(event_set::EventSet, store, xbuf) =
    _fire_walk(event_set.entries, store, xbuf, event_set.fire)
@inline _fire_walk(::Tuple{}, store, xbuf, fire) = nothing
@inline function _fire_walk(entries::Tuple, store, xbuf, fire)
    entry = entries[1]
    if fire[entry.event_index]
        entry.cursor.comp = entry.ci; entry.cursor.fn = :handler
        _latch!(entry, entry.handler(entry.comp, make_bundle(entry, store, xbuf)), xbuf)
        _fire_project!(entry, xbuf)
    end
    _fire_walk(Base.tail(entries), store, xbuf, fire)
end

@inline function _latch!(entry::EventEntry{G,H,P,Comp,XT}, returned::NamedTuple,
                         xbuf) where {G,H,P,Comp,XT}
    haskey(returned, :x) && flatten_state!(xbuf, entry.x_off, returned.x, XT,
                                           activation_scalar(entry.clock), entry.path,
                                           :handler, :state, entry.event)
    haskey(returned, :m) &&
        _merge_modes!(entry.mstore, returned.m, entry.path, :handler, entry.event)
    nothing
end

# §7.3: a discrete successor is the store's own type exactly — the assignment
# that would convert is refused at generation instead (D-235).
@inline _store_successor!(sstore::Base.RefValue{S}, s⁺::S, path, what) where {S} =
    (sstore[] = s⁺; nothing)
_store_successor!(sstore::Base.RefValue{S}, s⁺, path, what) where {S} =
    throw(DiagnosticError(ConformanceFailure(path = path, what = String(what),
                                             reason = s⁺ isa NamedTuple ? :field_set : :return_type,
                                             shape = :init_s, observed = typeof(s⁺),
                                             declared = S)))

# §9.5's partial-`m` predicate at the write: every written mode exists and keeps
# its type, decided at generation like the port write.
@generated function _merge_modes!(mstore::Base.RefValue{M}, m::NamedTuple{Ms},
                                  path::String, what::Symbol,
                                  event::Union{Nothing,Symbol}) where {M,Ms}
    for mode_field in Ms
        hasfield(M, mode_field) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), event = event, reason = :field_set,
                shape = :mode,
                field = $(QuoteNode(mode_field)), declared_fields = $(collect(fieldnames(M)))))))
        fieldtype(M, mode_field) === fieldtype(m, mode_field) ||
            return :(throw(DiagnosticError(ConformanceFailure(
                path = path, what = String(what), event = event, reason = :field_type,
                shape = :mode,
                field = $(QuoteNode(mode_field)), observed = $(fieldtype(m, mode_field)),
                declared = $(fieldtype(M, mode_field))))))
    end
    :(mstore[] = merge(mstore[], m); nothing)
end

# A non-NamedTuple `m` is the law's first clause failing, as the probe reports it.
_merge_modes!(mstore::Base.RefValue{M}, m, path, what, event) where {M} =
    throw(DiagnosticError(ConformanceFailure(path = path, what = String(what), event = event,
                                             reason = :return_type, shape = :mode,
                                             observed = typeof(m))))

@inline function _fire_project!(entry::EventEntry{G,H,P,Comp,XT}, xbuf) where {G,H,P,Comp,XT}
    P === Nothing && return nothing
    entry.cursor.fn = :state_projection # the component is the handler's own
    flatten_state!(xbuf, entry.x_off,
                   entry.projection(entry.comp, reconstruct(XT, xbuf, entry.x_off)), XT,
                   activation_scalar(entry.clock), entry.path, :state_projection, :state, nothing)
    nothing
end

# The §7.5 seam's view of one event and one projection (§9.7): the guard and
# the handler as the walks run them, closed over the entry and the buffers, so
# `@ballocated(body()) == 0` measures the loop's own call. The entry arrives
# typed through this barrier, never as the `Any` the build collects it in.
function _event_bodies(entry::EventEntry, store, xbuf)
    guard() = (entry.cursor.comp = entry.ci; entry.cursor.fn = :guard;
               entry.guard(entry.comp, make_bundle(entry, store, xbuf)))
    handler() = (entry.cursor.comp = entry.ci; entry.cursor.fn = :handler;
                 _latch!(entry, entry.handler(entry.comp, make_bundle(entry, store, xbuf)), xbuf);
                 _fire_project!(entry, xbuf))
    (guard = guard, handler = handler)
end
_project_body(entry::ProjectEntry, xbuf) = () -> run_project!(entry, xbuf)

# --- the gate (§10.5, D-185, D-205) ---------------------------------------------
# The boundary sweep walks the full list with *discrete* entries gated by
# `(tick − Φ) % D == 0`. The gate is a wrapper only discrete entries wear, so a
# continuous entry pays nothing at a boundary, and the interior walk — compiled
# from continuous entries alone — never meets an index at all: an empty due set
# is arity selection, never a sentinel index failing every gate (D-185).

struct Gated{E}
    entry::E
    D::Int
    Φ::Int
end

"""
Boundary zero's wide gate (§14.5, D-205), spelled as the marker the boundary
walk takes in place of a tick index: every discrete output stage runs there,
due or not, publishing from the authored `s` and the `t₀` table, so no
published cell holds the probe's synthesized values.

It is a *marker*, not an index, precisely so the measured path keeps its
shape: `run_at!` against an `Int` is the method the frame loop compiles and
nothing was added to it. The `state_update` updates are not walked this way —
they take the ordinary index 0 and stay gated by `Φ`, an offset component's
first consumed sample remaining its `Φ·Δt_base` tick's.
"""
struct Establish end
const ESTABLISH = Establish()

# The walk's index parameter is unconstrained from here down: `run_at!` is the
# one site that reads it, and dispatch there is what separates the two gates.
# Every caller passes a concrete `Int` or `ESTABLISH`, so each specializes
# exactly as it did when the annotation was `::Int`.
@inline run_at!(entry, store, xbuf, ẋbuf, tick) = run_entry!(entry, store, xbuf, ẋbuf)

@inline function run_at!(entry::Gated, store, xbuf, ẋbuf, tick::Int)
    # Under the canonical residue 0 ≤ Φ < D, truncated rem is never 0 on the
    # negative pre-first-tick differences, so one subtraction and one remainder
    # are the whole admission test — and "everything with Φ = 0" is this same
    # gate at index 0, implemented by nothing (§10.5).
    (tick - entry.Φ) % entry.D == 0 && run_entry!(entry.entry, store, xbuf, ẋbuf)
    nothing
end

# Establishment admits every gated entry (§14.5, D-205). Dueness at boundary
# zero governs the `state_update` updates alone.
@inline run_at!(entry::Gated, store, xbuf, ẋbuf, ::Establish) =
    (run_entry!(entry.entry, store, xbuf, ẋbuf); nothing)

# --- the walk -----------------------------------------------------------------

struct Chunk{E<:Tuple,S,X}
    entries::E
    store::S
    xbuf::X
    ẋbuf::X
end

@noinline (chunk::Chunk)() = _walk(chunk.entries, chunk.store, chunk.xbuf, chunk.ẋbuf)
@noinline (chunk::Chunk)(tick) = _walk_at(chunk.entries, chunk.store, chunk.xbuf, chunk.ẋbuf, tick)

@inline _walk(::Tuple{}, store, xbuf, ẋbuf) = nothing
@inline function _walk(entries::Tuple, store, xbuf, ẋbuf)
    run_entry!(entries[1], store, xbuf, ẋbuf)
    _walk(Base.tail(entries), store, xbuf, ẋbuf)
end

@inline _walk_at(::Tuple{}, store, xbuf, ẋbuf, tick) = nothing
@inline function _walk_at(entries::Tuple, store, xbuf, ẋbuf, tick)
    run_at!(entries[1], store, xbuf, ẋbuf, tick)
    _walk_at(Base.tail(entries), store, xbuf, ẋbuf, tick)
end

"""
A phase body: **two chunk tuples compiled from one entry list** (§9.7, §10.5).

The zero-arg call is the *interior* variant, walking continuous entries only —
what RK stage evaluations and guard trial evaluations run, and what
`@ballocated(body()) == 0` measures. The ZOH therefore holds mid-step **by
construction**: discrete entries are not gated out at runtime, they are absent
from the compiled walk, and the hot path carries no gating test at all.

The one-arg call is the *boundary* variant, walking the full list with each
discrete entry gated by `(tick - Φ) % D` against the index it takes (§10.5,
D-185) — or admitted outright, when the argument is `ESTABLISH` rather than an
index (§14.5, D-205). Both take the one compiled tuple; only `run_at!`'s
dispatch differs, so boundary zero's wide walk costs the measured path
nothing.
"""
struct PhaseBody{I<:Tuple,B<:Tuple}
    interior::I
    boundary::B
end

@inline (body::PhaseBody)() = _walkchunks(body.interior)
@inline (body::PhaseBody)(tick) = _walkchunks(body.boundary, tick)

@inline _walkchunks(::Tuple{}) = nothing
@inline function _walkchunks(chunks::Tuple)
    chunks[1]()
    _walkchunks(Base.tail(chunks))
end

@inline _walkchunks(::Tuple{}, tick) = nothing
@inline function _walkchunks(chunks::Tuple, tick)
    chunks[1](tick)
    _walkchunks(Base.tail(chunks), tick)
end

# Construction is type-opaque: entries are built into untyped buffers and
# splatted once per chunk; the compiled tuple's only consumer is the walk.
# `gates` runs parallel to `entries`: `nothing` for a continuous entry, the
# compiled `(D, Φ)` pair for a discrete one — which is also what selects the
# interior subset, discreteness being a build-time fact (§10.5, D-147).
function chunked_body(entries::Vector, gates::Vector, store, xbuf, ẋbuf;
                      chunk_size::Int = 16)
    chunks(walk_entries) =
        tuple((Chunk(tuple(walk_entries[lo:min(lo + chunk_size - 1, length(walk_entries))]...),
                    store, xbuf, ẋbuf)
              for lo in 1:chunk_size:length(walk_entries))...)
    PhaseBody(chunks([e for (e, gt) in zip(entries, gates) if gt === nothing]),
              chunks([gt === nothing ? e : Gated(e, gt[1], gt[2])
                      for (e, gt) in zip(entries, gates)]))
end
