# The input trace (§11.5): the header captured at `init!` — the resolved
# initial state, the root-input values, the run's `Deployment` and its `t₀` —
# and behind it the writers' schemas and one sparse record per drained batch,
# in the one record format D-176 unified on. The trace is *primary* data (D-029,
# D-038): the log is recomputable from it, and what recomputes it is replay
# (§12.7), whose entry pass — the validation and normalization a trace is
# admitted through — lives at the tail of this file, beside the capture it
# mirrors.
#
# This file holds the trace itself and the pure mechanics; the `Simulation`-facing
# surface — the capture's placement in `init!`, the drain's frame stamp,
# `trace(sim)`, `_compile_feed`'s scalar gate, `replay!` and the drain
# substitution — lives in sim.jl, beside the loop that runs it. The drain
# thunks are compiled here too
# (`_install_writers!`), because the writer's schema index rides in them and
# nothing else may fix it.

"""
The trace header (§11.5): the full initial state as **resolved values**, never
the authored overlay (D-038), captured after `apply!` and the root-input
writes and before the boundary-zero sequence — both halves of §14.5's
placement being essential, since replay re-executes boundary zero and a
post-sequence capture would hand it already-transitioned state.

`x` is the flat continuous buffer; `s` and `m` carry each component's store
value (`nothing` where the component owns none). `root_inputs` is what makes
replay possible at all: an unfed `mixture = 0.5` appears in no batch, so the
initial root-input values are recorded beside the stores. The writers' schemas
are the `Trace`'s, not the header's (D-255): the list grows at every roster
change, and an artifact does not.

`deployment` and `layout` are the two fingerprints: the trajectory depends on
the deployment exactly as it depends on the stores (the `Deployment` sits
outside the `Build`, and `t₀` post-dates even deployment), and the structural
half is what a replay target is compared against (§12.7). Replay compares the
two deployments as values and *applies* `t₀`, never comparing it. The header
holds no policy: `t_end` and `stop_on` are the advance's, and the termination
record carries the terminating one (§13.5, D-255).
"""
struct TraceHeader{T}
    x::Vector{T}                                    # a copy of xbuf after apply!
    s::Vector{Any}                                  # per component: the store value, or nothing
    m::Vector{Any}                                  # likewise for the mode stores
    root_inputs::Vector{Pair{Symbol,Any}}           # face => the resolved value in its cell
    deployment::Deployment                          # compared as a value at replay (§12.7)
    t₀::Float64                                     # applied at replay, never compared (D-260)
    layout::@NamedTuple{sizes::Vector{Pair{DataType,Int}}, root_faces::Vector{Symbol},
                        paths::Vector{String}, stypes::Vector{Any}, mtypes::Vector{Any}}
end

"""
One drained batch, retained sparse (§11.5, D-176): the masked (touched)
positions as `position ⇒ value` pairs against the writer's schema, which is
`trace.schemas[writer]`. `frame` is the frame ordinal the batch was drained
at the top of — the drain runs before the clock's step increments, so a batch
drained at the top of frame `k` carries `frame = k` and replays there.
"""
struct TraceBatch
    frame::Int
    writer::Int                       # index into the trace's schema list
    entries::Vector{Pair{Int,Any}}
end

# A record is a *value*, and the claim replay makes about a continuation — the
# recording is a bit-identical prefix of what the continued session records
# (§12.7) — is an equality between records built by two different drains.
# The default `==` on a mutable-free struct with a `Vector` field is egal, which
# would make that claim untestable, so the field-wise one is defined here, and
# `hash` with it as Julia's convention requires.
Base.:(==)(a::TraceBatch, b::TraceBatch) =
    a.frame == b.frame && a.writer == b.writer && a.entries == b.entries
Base.hash(b::TraceBatch, h::UInt) = hash(b.entries, hash(b.writer, hash(b.frame, h)))

"""
The trace (§11.5, D-255): a fixed header, written once at `init!` and never
again, plus two append-only lists — the writers' schemas, grown at every roster
change, and the sparse records, one per drained batch — and its length, the
drains since the capture, which is also the ordinal each record carries
(D-260). `Run.trace` is the live one, `nothing` under the kill switch;
`trace(sim)` hands back a detached value of the same type, which no drain ever
advances.

A record is meaningless without its schema entry: the positions are against
`schemas[batch.writer]`, and replay does not reconstruct claims (§12.7). The
tags are §11.8's own writer names, `_who(entry)` and `"harness"`.
"""
mutable struct Trace{T}
    const header::Union{Nothing,TraceHeader{T}}    # nothing: the placeholder run, or the kill switch
    const schemas::Vector{Pair{String,Vector{Symbol}}}   # writer tag => face-name-by-position
    const batches::Vector{TraceBatch}              # in drain order: by frame, then by writer index
    frames::Int
end

"""
One normalized record (§12.7): the frame ordinal it applies at, the compiled
scatter as a zero-argument thunk, and the `TraceBatch` it came from — carried
beside the thunk so a replayed frame re-records exactly what the recording
held, under the recording's own writer index (§12.7: "the new trace inherits
the old header").
"""
const ReplayRecord = @NamedTuple{frame::Int, thunk::Function, record::TraceBatch}

"""
What `_compile_feed` hands the loop (§12.7): the whole recording normalized to
compiled scatters against the *target* layout, in drain order — by frame, then
by the recording's writer index — with a cursor into it.

The conversion is paid here, once, off the loop: the replay drain applies
compiled scatters exactly as the live drain does, and no face name is resolved
per frame under replay either (D-101). `next` is the first record not yet
applied. `frames` is the recording's own length — the bound every advance in
`:replay` is capped at (D-218), carried here so `step!` and `run!` can cap
without holding the `Trace`; `to_boundary` caps `replay!`'s own advance
earlier, and `replay!` computes that one from the `Trace` in hand.
"""
mutable struct ReplayFeed
    records::Vector{ReplayRecord}
    next::Int
    frames::Int
end

# The conversion at the drain (§11.5, D-176), inside the drain thunk so nothing
# on the frame path boxes an argument: two O(surface-width) scans of the mask —
# one to count the touched positions, one to fill — so the `entries` vector is
# allocated once at its final length rather than grown. The cost of a drained
# batch is then that vector and the values boxed into it, and nothing
# width-dependent beyond them — the cost D-176 records rather than argues away.
# A drained batch always carries at least one touched position (`_normalize`
# returns `nothing` for one that would not), so no record here is empty.
function _record!(trc::Trace, widx::Int, batch::Batch)
    mask = batch.mask
    k = 0
    for i in 1:length(mask)
        mask[i] && (k += 1)
    end
    entries = Vector{Pair{Int,Any}}(undef, k)
    j = 0
    for i in 1:length(mask)
        mask[i] && (entries[j += 1] = i => batch.vals[i])
    end
    push!(trc.batches, TraceBatch(trc.frames, widx, entries))
    nothing
end

# The run's writers in the drain's own order (§11.3, §11.4): each rostered
# device in attachment order, then the harness writer. The tags are §11.8's
# writer names, so a trace and a published status name a writer identically.
function _writer_schemas(plane)
    schemas = Pair{String,Vector{Symbol}}[_who(e) => copy(e.writer.faces) for e in plane.roster]
    push!(schemas, "harness" => copy(plane.harness.faces))
    schemas
end

# The recording's header, detached, for the replay that *inherits* it (§12.7):
# every mutable field copied — the stores by value, being isbits (D-231) — so
# the trace the replay goes on to build is a value of its own and nothing the
# caller still holds is reachable from it. The `Deployment` and the layout
# fingerprint are immutable artifacts and ride as they are.
_detach(h::TraceHeader{T}) where {T} =
    TraceHeader{T}(copy(h.x), copy(h.s), copy(h.m), copy(h.root_inputs),
                   h.deployment, h.t₀, h.layout)

"""
The growth rule (§11.5), and the one site a drain thunk is compiled at: append
the current writer set to the trace's schema list, name the appended range
`live_writers`, and recompile every thunk with its writer's new index. The list
grows *in place* (D-255) — a `Trace` a caller holds is a detached value, its
own copy of the schemas, so the growth cannot reach it.

Reached from three places, all of them stopped-sim: the two doors that build a
run, `init!` and `replay!`, and `reclaim!`'s two callers, `attach!` and
`detach!`. With no trace to write into — before the first `init!`, or under
`trace = false` — nothing is appended and the indices are provisional; no drain
runs before boundary zero has, so nothing reads them.

The appended range is a local (D-260): the thunks are compiled against it here
and nothing reads it afterwards. `trc` is the run's trace, `nothing` under the
switch, and each thunk closes over it concretely — so the record branch inside
`_drain!` folds away where there is nothing to record.
"""
function _install_writers!(plane, trc)
    k = length(plane.roster) + 1
    live_writers = if trc === nothing
        1:k
    else
        n = length(trc.schemas)
        append!(trc.schemas, _writer_schemas(plane))
        (n + 1):(n + k)
    end
    for (i, e) in enumerate(plane.roster)
        # the entry is immutable and its thunk carries the index, so the
        # recompilation replaces the entry itself (§11.4's stopped-sim compile)
        plane.roster[i] = RosterEntry(
            e.dev, e.binding, e.id, e.writer,
            _drain_thunk(plane.store, e.writer, trc, live_writers[i]),
            e.should_abort, e.diag, e.acct, e.handle)
    end
    plane.harness_drain = _drain_thunk(plane.store, plane.harness, trc, live_writers[k])
    nothing
end

"""
The structural fingerprint (§11.5, §12.7): the layout's cell sizes, the root
input-face list, the flat's component paths and each component store's value
type. One function because it has two sides — the capture writes it into the
header, and replay compares the header's against the target's — and two
spellings of one fingerprint would be a silent way for a replay to pass.
`sim` is untyped for include order alone, as `_capture_header` below is.
"""
function _fingerprint(sim)
    ex = sim.exec
    layout = ex.act.layout
    (sizes = copy(layout.sizes),
     root_faces = Symbol[f for (f, _) in layout.root_inputs],
     paths = copy(sim.deployment.build.structure.paths),
     stypes = Any[st === nothing ? nothing : typeof(st[]) for st in ex.sstores],
     mtypes = Any[st === nothing ? nothing : typeof(st[]) for st in ex.mstores])
end

# §11.5's header, read off the simulation at §14.5's placement. `sim` is
# untyped for include order alone — this file precedes sim.jl, the drain
# thunks it compiles being what the data plane is built with.
function _capture_header(sim)
    ex = sim.exec
    layout = ex.act.layout
    T = eltype(ex.xbuf)      # the deployment's scalar, off the buffer that carries it
    s = Any[st === nothing ? nothing : st[] for st in ex.sstores]
    m = Any[st === nothing ? nothing : st[] for st in ex.mstores]
    roots = Pair{Symbol,Any}[f => gather(ex.store, layout.addr[("", f)])
                             for (f, _) in layout.root_inputs]
    TraceHeader{T}(copy(ex.xbuf), s, m, roots, sim.deployment, ex.clock.t₀, _fingerprint(sim))
end

# ==============================================================================
# Replay's entry pass (§12.7): validation, then normalization
# ==============================================================================
# "Validation is loud and up front" — the whole trace is checked and converted
# before the first frame, so every refusal precedes every write and the replay
# drain resolves no name. The pass is two-staged: the header's own disagreements
# with the target build fail fast as a collection, and only then are the records
# resolved through the schemas the first stage just validated. `sim` is untyped
# throughout for include order alone; the scalar gate that dispatches into this
# is `_compile_feed` in sim.jl, beside the loop it feeds.

# The header against the target `Build` and its deployment binding (§12.7's
# disposition table): the structural fingerprint compared field for field, then
# the two deployments as *values* — one `==`, which is what D-254 asks for, with
# `_walk_deployment!` below as its explanation rather than as a second spelling.
# `t₀` is applied rather than compared. The header holds no policy (§11.5,
# D-255): `t_end` and `stop_on` are the terminating advance's, and the
# termination record has them.
function _check_header!(diags::Vector{Diagnostic}, sim, h::TraceHeader)
    f = _fingerprint(sim)
    l = h.layout
    l.sizes == f.sizes ||
        push!(diags, ReplayHeaderMismatch(what = :store, name = :sizes,
                                          expected = l.sizes, found = f.sizes))
    l.paths == f.paths ||
        push!(diags, ReplayHeaderMismatch(what = :store, name = :paths,
                                          expected = l.paths, found = f.paths))
    l.root_faces == f.root_faces ||
        push!(diags, ReplayHeaderMismatch(what = :root_input,
                                          expected = l.root_faces, found = f.root_faces))
    # the per-component store types, only where the path lists agree on what a
    # component *index* means — otherwise the comparison would be by position
    # between two different models, and the path mismatch above is the honest fact
    if l.paths == f.paths
        for (i, p) in enumerate(f.paths)
            l.stypes[i] === f.stypes[i] ||
                push!(diags, ReplayHeaderMismatch(what = :store, path = p, name = :s,
                                                  expected = l.stypes[i], found = f.stypes[i]))
            l.mtypes[i] === f.mtypes[i] ||
                push!(diags, ReplayHeaderMismatch(what = :store, path = p, name = :m,
                                                  expected = l.mtypes[i], found = f.mtypes[i]))
        end
    end
    h.deployment == sim.deployment || _walk_deployment!(diags, h.deployment, sim.deployment)
    nothing
end

_dep_diff!(diags::Vector{Diagnostic}, path::String, name::Symbol, expected, found) =
    expected == found ? nothing :
    push!(diags, ReplayHeaderMismatch(what = :deployment, path = path, name = name,
                                      expected = expected, found = found))

# What the `==` above refused, named (§12.7, Appendix C): the seven
# trajectory-determining parameters by name, then the schedule, which the value
# covers with every column — the anchor and provenance included, so a rate
# re-declared through a different anchor at the same tick table is a different
# deployment. The walk covers exactly what `Deployment`'s and `Schedule`'s `==`
# compare, so a refusal is never silent.
function _walk_deployment!(diags::Vector{Diagnostic}, rec::Deployment, tgt::Deployment)
    for name in (:Δt_base, :h, :N_base, :algorithm, :localization_tol,
                 :localization_budget, :firing_budget)
        _dep_diff!(diags, "", name, getfield(rec, name), getfield(tgt, name))
    end
    a, b = rec.schedule, tgt.schedule
    # the rows, identified by path: a differing row count or path list is the
    # whole list, since rows past the first difference name different components
    if [r.path for r in a.rows] == [r.path for r in b.rows]
        for (ra, rb) in zip(a.rows, b.rows), col in (:anchor, :D, :Φ, :Δt, :provenance)
            _dep_diff!(diags, ra.path, col, getfield(ra, col), getfield(rb, col))
        end
    else
        _dep_diff!(diags, "", :schedule, [r.path for r in a.rows], [r.path for r in b.rows])
    end
    if [(s.path, s.key) for s in a.scopes] == [(s.path, s.key) for s in b.scopes]
        for (sa, sb) in zip(a.scopes, b.scopes), col in (:anchor, :D, :Φ)
            _dep_diff!(diags, sa.path, Symbol("scope.", col), getfield(sa, col), getfield(sb, col))
        end
    else
        _dep_diff!(diags, "", Symbol("scope.key"),
                   [string(s.path, ':', s.key) for s in a.scopes],
                   [string(s.path, ':', s.key) for s in b.scopes])
    end
    # the per-component vectors the executor compiles over: every tier, so they
    # move where a continuous component does and the rows do not. They resolve
    # from the rows above, so a reachable difference is already named there. This
    # arm is the backstop that keeps the walk covering what `==` compares.
    for col in (:D, :Φ, :Δt)
        _dep_diff!(diags, "", Symbol("schedule.", col), getfield(a, col), getfield(b, col))
    end
    nothing
end

# Each recorded writer's schema against the target's root-input faces (§12.7):
# a recorded name this model does not export is a replay error, reported per
# writer with the whole schema and the list-in-hand beside it. Superseded schema
# entries are checked with the live ones — a batch may still reference them, and
# the compiled scatters below are built from whatever a batch names.
function _check_schemas!(diags::Vector{Diagnostic}, faces::Vector{Symbol},
                         schemas::Vector{Pair{String,Vector{Symbol}}})
    for (tag, schema) in schemas
        unknown = Symbol[s for s in schema if !(s in faces)]
        isempty(unknown) ||
            push!(diags, ReplaySchemaMismatch(writer = tag, schema = schema,
                                              unknown = unknown, faces = faces))
    end
    nothing
end

# The compiled scatter as a zero-argument thunk, the `_drain_thunk` idiom: the
# store, the address tuple and the batch are captured *concretely*, so the
# `@generated` `_apply!` specializes once per writer at this stopped-sim compile
# and the replayed frame calls through a barrier with nothing left to infer.
_apply_thunk(store, addrs::Tuple, batch::Batch) = () -> _apply!(store, addrs, batch)

# One recorded writer's compiled scatter against the *target* layout. The
# schema check above already proved every face addressable, so the guard here
# never fires; it is kept because `Writer` would answer an absent face with a
# `KeyError` rather than with the kind that names it.
function _replay_writer(layout::Layout, diags::Vector{Diagnostic}, tag::String,
                        schema::Vector{Symbol}, frame::Int, faces::Vector{Symbol})
    absent = Symbol[f for f in schema if !haskey(layout.addr, ("", f))]
    isempty(absent) && return Writer(layout, schema)
    for f in absent
        push!(diags, ReplayUnknownFace(face = f, frame = frame, writer = tag, faces = faces))
    end
    nothing
end

"""
The trace-record conversion in reverse (§12.7, D-176), paid once and off the
loop: every sparse record's positions are resolved through the writer's schema,
the values converted to the target's declared types, and the whole batch
rebuilt as the positional `Batch` the compiled scatter takes. The recorded
`TraceBatch` rides beside its thunk, because a replay re-records.

Everything here is *collected* — Appendix C gives `ReplayUnknownFace` the
`collected` policy — so a trace with three bad entries reports three. A batch
that produced a diagnostic contributes no record: a partially applied frame is
not a replay of anything.
"""
function _compile_records!(diags::Vector{Diagnostic}, sim, trc::Trace, faces::Vector{Symbol})
    layout, store, schemas = sim.exec.act.layout, sim.exec.store, trc.schemas
    writers = Dict{Int,Writer}()
    recs = ReplayRecord[]
    for b in trc.batches
        if !(1 ≤ b.frame ≤ trc.frames)
            # the batch disagrees with the trace's *own* frame count: the drain
            # visits every frame in `1:frames` exactly once, so an ordinal outside
            # it names a frame that never comes round and the record would silently
            # never apply. Named by the writer's tag where the schema list has one
            push!(diags, ReplayHeaderMismatch(
                what = :frame,
                name = 1 ≤ b.writer ≤ length(schemas) ? Symbol(first(schemas[b.writer])) :
                                                        Symbol("writer #$(b.writer)"),
                expected = 1:trc.frames, found = b.frame))
            continue
        end
        if !(1 ≤ b.writer ≤ length(schemas))
            # no schema to resolve the positions through, and the writer index is
            # what is missing — the tag §11.8 cannot supply is spelled positionally
            for (pos, _) in b.entries
                push!(diags, ReplayUnknownFace(face = pos, frame = b.frame,
                                               writer = "writer #$(b.writer)", faces = faces))
            end
            continue
        end
        (tag, schema) = schemas[b.writer]
        if !haskey(writers, b.writer)
            w = _replay_writer(layout, diags, tag, schema, b.frame, faces)
            w === nothing && continue
            writers[b.writer] = w
        end
        w = writers[b.writer]
        vals, mask, ok = Any[w.blank.vals...], fill(false, length(schema)), true
        for (pos, v) in b.entries
            if !(1 ≤ pos ≤ length(schema))
                push!(diags, ReplayUnknownFace(face = pos, frame = b.frame, writer = tag,
                                               faces = faces))
                ok = false
                continue
            end
            vals[pos] = try
                convert(w.types[pos], v)
            catch
                push!(diags, ReplayHeaderMismatch(what = :root_input, name = schema[pos],
                                                  expected = w.types[pos], found = v))
                ok = false
                continue
            end
            mask[pos] = true
        end
        ok || continue
        batch = Batch(convert(typeof(w.blank.vals), (vals...,)), (mask...,))
        push!(recs, (frame = b.frame, thunk = _apply_thunk(store, w.addrs, batch), record = b))
    end
    # the drain's own order (§11.5): by frame, then by the recording's writer
    # index. Stable, so a trace already in drain order — every trace the drain
    # produces — keeps exactly the order it was recorded in.
    sort!(recs; by = r -> (r.frame, r.record.writer), alg = MergeSort)
    recs
end
