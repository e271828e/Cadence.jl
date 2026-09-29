# The input trace (§11.5): the header, the checkpoint `init!` takes at the end of
# boundary zero (checkpoint.jl, D-274), and behind it the writers' schemas and one
# sparse record per drained batch, in the one record format D-176 unified on.
# The trace is *primary* data (D-029, D-038): the log is recomputable from it,
# and what recomputes it is replay (§12.7), whose entry pass — the validation
# and normalization a trace is admitted through — lives at the tail of this file.
#
# This file holds the trace itself and the pure mechanics; the `Simulation`-facing
# surface — the header's placement in `init!`, the drain's frame stamp,
# `trace(sim)`, `_compile_feed`'s scalar gate, `replay!` and the drain
# substitution — lives in sim.jl, beside the loop that runs it. The drain
# thunks are compiled here too
# (`_install_writers!`), because the writer's schema index rides in them and
# nothing else may fix it.

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
Base.hash(record::TraceBatch, seed::UInt) =
    hash(record.entries, hash(record.writer, hash(record.frame, seed)))

"""
The trace (§11.5, D-255): a header written once and never again, plus two
append-only lists — the writers' schemas, grown at every roster change, and the
sparse records, one per drained batch — and its length, the frame ordinal of the
last drain, which is also the ordinal each record carries (D-260). The header is
a `Checkpoint` (D-274): `init!` writes it after boundary zero's first
publication, so it is `nothing` only between the run's opening and that
publication, and `restore!` and `replay!` open their run with the checkpoint
they restore. The length starts at the header's frame index, so a trace opened
by a restore keys its records by the trajectory's own frames. `Run.trace` is
the live one, `nothing` under the kill switch; `trace(sim)` hands back a
detached value of the same type, which no drain ever advances.

A record is meaningless without its schema entry: the positions are against
`schemas[batch.writer]`, and replay does not reconstruct claims (§12.7). The
tags are §11.8's own writer names, `_who(entry)` and `"harness"`.
"""
mutable struct Trace{T}
    header::Union{Nothing,Checkpoint{T}}          # written once, by the door (D-274)
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
function _record!(trc::Trace, writer_index::Int, batch::Batch)
    mask = batch.mask
    touched = 0
    for i in 1:length(mask)
        mask[i] && (touched += 1)
    end
    entries = Vector{Pair{Int,Any}}(undef, touched)
    j = 0
    for i in 1:length(mask)
        mask[i] && (entries[j += 1] = i => batch.staged[i])
    end
    push!(trc.batches, TraceBatch(trc.frames, writer_index, entries))
    nothing
end

# The run's writers in the drain's own order (§11.3, §11.4): each rostered
# device in attachment order, then the harness writer. The tags are §11.8's
# writer names, so a trace and a published status name a writer identically.
function _writer_schemas(plane)
    schemas = Pair{String,Vector{Symbol}}[_who(e) => copy(_handle(e).writer.faces)
                                          for e in plane.roster]
    push!(schemas, "harness" => copy(plane.harness.faces))
    schemas
end

"""
The growth rule (§11.5), and the one site a drain thunk is compiled at: append
the current writer set to the trace's schema list, name the appended range
`live_writers`, and recompile every thunk with its writer's new index. The list
grows *in place* (D-255) — a `Trace` a caller holds is a detached value, its
own copy of the schemas, so the growth cannot reach it.

Reached from four places, all of them stopped-sim: the three doors that build a
run, `init!`, `restore!` and `replay!`, and `reclaim!`'s two callers, `attach!` and
`detach!`. With no trace to write into, under the door's `trace = false` or at
a roster change before the first door, whose placeholder run has no trace
(D-261), nothing is appended and the indices are provisional. No drain runs
before a door has, so nothing reads either.

The appended range is a local (D-260): the thunks are compiled against it here
and nothing reads it afterwards. `store` is the executor's and `trc` the run's
trace, `nothing` under the switch, both taken as arguments (D-261) and closed
over concretely — so the record branch inside `_drain!` folds away where there
is nothing to record.
"""
function _install_writers!(plane, store, trc)
    writer_count = length(plane.roster) + 1
    live_writers = if trc === nothing
        1:writer_count
    else
        schema_count = length(trc.schemas)
        append!(trc.schemas, _writer_schemas(plane))
        (schema_count + 1):(schema_count + writer_count)
    end
    for (i, entry) in enumerate(plane.roster)
        # the entry is immutable and its thunk carries the index, so the
        # recompilation replaces the entry itself (§11.4's stopped-sim compile)
        plane.roster[i] = RosterEntry(
            entry.dev, entry.id,
            _drain_thunk(store, _handle(entry).writer, trc, live_writers[i]),
            entry.should_abort, entry.account, entry.handle)
    end
    plane.harness_drain =
        _drain_thunk(store, plane.harness, trc, live_writers[writer_count])
    nothing
end

# ==============================================================================
# Replay's entry pass (§12.7): validation, then normalization
# ==============================================================================
# "Validation is loud and up front" — the whole trace is checked and converted
# before the first frame, so every refusal precedes every write and the replay
# drain resolves no name. The pass is two-staged: the header's own disagreements
# with the target build (`_check_checkpoint!`, checkpoint.jl) and the schemas'
# fail fast as a collection, and only then are the records
# resolved through the schemas the first stage just validated. `sim` is untyped
# throughout for include order alone; the scalar gate that dispatches into this
# is `_compile_feed` in sim.jl, beside the loop it feeds.

_deployment_diff!(diags::Vector{Diagnostic}, path::String, name::Symbol, expected, found) =
    expected == found ? nothing :
    push!(diags, CheckpointMismatch(what = :deployment, path = path, name = name,
                                    expected = expected, found = found))

# What the `==` above refused, named (§12.7, Appendix C): the seven
# trajectory-determining parameters by name, then the schedule, which the value
# covers with every column — the anchor and the rates included, so a rate
# re-declared through a different anchor at the same tick table is a different
# deployment. The walk covers exactly what `Deployment`'s and `Schedule`'s `==`
# compare, so a refusal is never silent.
function _walk_deployment!(diags::Vector{Diagnostic}, recorded::Deployment,
                           target::Deployment)
    for name in (:Δt_base, :h, :N_base, :algorithm, :localization_tol,
                 :localization_budget, :firing_budget)
        _deployment_diff!(diags, "", name, getfield(recorded, name), getfield(target, name))
    end
    recorded_schedule, target_schedule = recorded.schedule, target.schedule
    # the rows, identified by path: a differing row count or path list is the
    # whole list, since rows past the first difference name different components
    if [r.path for r in recorded_schedule.rows] == [r.path for r in target_schedule.rows]
        for (recorded_row, target_row) in zip(recorded_schedule.rows, target_schedule.rows),
            column in (:anchor, :D, :Φ, :Δt, :rates)
            _deployment_diff!(diags, recorded_row.path, column, getfield(recorded_row, column),
                              getfield(target_row, column))
        end
    else
        _deployment_diff!(diags, "", :schedule, [r.path for r in recorded_schedule.rows],
                          [r.path for r in target_schedule.rows])
    end
    if [(scope.path, scope.key) for scope in recorded_schedule.scopes] ==
       [(scope.path, scope.key) for scope in target_schedule.scopes]
        for (recorded_scope, target_scope) in
                zip(recorded_schedule.scopes, target_schedule.scopes),
            column in (:anchor, :D, :Φ)
            _deployment_diff!(diags, recorded_scope.path, Symbol("scope.", column),
                              getfield(recorded_scope, column), getfield(target_scope, column))
        end
    else
        _deployment_diff!(diags, "", Symbol("scope.key"),
                          [string(scope.path, ':', scope.key)
                           for scope in recorded_schedule.scopes],
                          [string(scope.path, ':', scope.key) for scope in target_schedule.scopes])
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
        unknown = Symbol[face for face in schema if !(face in faces)]
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
    for face in absent
        push!(diags, ReplayUnknownFace(face = face, frame = frame, writer = tag,
                                       faces = faces))
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
    replay_records = ReplayRecord[]
    recorded_frames = (trc.header.step + 1):trc.frames
    for record in trc.batches
        if !(record.frame in recorded_frames)
            # the batch disagrees with the trace's *own* frames: the drain visits
            # every frame after the header's up to `frames` exactly once, so an
            # ordinal outside them names a frame that never comes round and the
            # record would silently never apply. Named by the writer's tag where
            # the schema list has one
            push!(diags, CheckpointMismatch(
                what = :frame,
                name = 1 ≤ record.writer ≤ length(schemas) ?
                       Symbol(first(schemas[record.writer])) :
                       Symbol("writer #$(record.writer)"),
                expected = recorded_frames, found = record.frame))
            continue
        end
        if !(1 ≤ record.writer ≤ length(schemas))
            # no schema to resolve the positions through, and the writer index is
            # what is missing — the tag §11.8 cannot supply is spelled positionally
            for (face_position, _) in record.entries
                push!(diags, ReplayUnknownFace(face = face_position, frame = record.frame,
                                               writer = "writer #$(record.writer)",
                                               faces = faces))
            end
            continue
        end
        (tag, schema) = schemas[record.writer]
        if !haskey(writers, record.writer)
            writer = _replay_writer(layout, diags, tag, schema, record.frame, faces)
            writer === nothing && continue
            writers[record.writer] = writer
        end
        writer = writers[record.writer]
        batch_values, mask, resolved =
            Any[writer.blank.staged...], fill(false, length(schema)), true
        for (face_position, value) in record.entries
            if !(1 ≤ face_position ≤ length(schema))
                push!(diags, ReplayUnknownFace(face = face_position, frame = record.frame,
                                               writer = tag, faces = faces))
                resolved = false
                continue
            end
            batch_values[face_position] = try
                convert(writer.types[face_position], value)
            catch
                push!(diags, CheckpointMismatch(what = :root_input,
                                                name = schema[face_position],
                                                expected = writer.types[face_position],
                                                found = value))
                resolved = false
                continue
            end
            mask[face_position] = true
        end
        resolved || continue
        batch = Batch(convert(typeof(writer.blank.staged), (batch_values...,)), (mask...,))
        push!(replay_records,
              (frame = record.frame, thunk = _apply_thunk(store, writer.addrs, batch),
               record = record))
    end
    # the drain's own order (§11.5): by frame, then by the recording's writer
    # index. Stable, so a trace already in drain order — every trace the drain
    # produces — keeps exactly the order it was recorded in.
    sort!(replay_records; by = r -> (r.frame, r.record.writer), alg = MergeSort)
    replay_records
end
