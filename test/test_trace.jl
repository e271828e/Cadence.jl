# Shared fixture: the replay-loop and discarded-staging sections both attach a
# `Nudge`.

# A device that stages once from its own task and departs (§12.4(6)'s voluntary
# exit): deterministic in *what* it stages — which is what a replay test can
# assert — never in when, the frame a wall-clock task reaches being exactly the
# scheduler-determined timing §11.1 indicts.
mutable struct Nudge <: AbstractDevice
    face::String
    v::Float64
end
loop(dev::Nudge, handle) = (stage!(handle, dev.face => dev.v); nothing)

# --- the input trace (§11.5, increment 23) --------------------------------------
# The header, the checkpoint `init!` takes at the end of boundary zero, and one
# sparse record per drained batch behind it: what replay (§12.7) consumes, and
# the primary record the log is derived from (D-038). The fixtures live at top
# level for `implementation.md`'s local-scope reason.

# Three root inputs, so a record's *position* against the writer's schema is a
# fact worth asserting rather than a coincidence at width one.
three_root_inputs() = Group((; s = Sum(sa = 1.0, sb = 1.0), g = Gain(2.0));
                            input_wires = ("a" => "s/a", "b" => "s/b", "c" => "g/e"))

# A model whose boundary-zero sequence moves both discrete state homes (§14.5):
# the trigger's guard holds in the authored state and fires at `t₀`, and the
# integrator's due `s_update` runs there too. What the header must hold is what
# both left behind (D-274).
boundary_movers() = Group((; t = Trigger(0.5), d = DiscreteAccumulator(1.0));
                          input_wires = ("sig" => "t/sig", "e" => "d/e"))

# One record's face, resolved the way a consumer resolves it: through the
# writer's schema in the header (§11.5).
recorded_faces(trc, batch::TraceBatch) =
    Symbol[last(trc.schemas[batch.writer])[i] for (i, _) in batch.entries]

# The root-input cells a checkpoint's table holds, face by face, read through the
# layout's addresses: the values the header records (§11.5, D-038).
table_inputs(sim, cp::Checkpoint) =
    Pair{Symbol,Any}[f => gather_cell(cp.state.table, sim.model.exec.act.layout.addr[("", f)])
                     for (f, _) in sim.model.exec.act.layout.root_inputs]

function trace_recording()
    @testset "one sparse record per drained batch, against the writer's schema (§11.5, D-176)" begin
        sim = Simulation(three_root_inputs(); h = 1//10)
        init!(sim, fragment(u = (a = 0.0, b = 0.0, c = 0.0)))
        @test isempty(trace(sim).batches) && trace(sim).frames == 0

        stage!(sim, "b" => 1.0)
        step!(sim)
        trc = trace(sim)
        batch = only(trc.batches)
        @test batch.frame == 1                     # the drain precedes the frame increment
        @test batch.writer == 1                    # the harness writer, sole writer here
        @test first(trc.schemas[batch.writer]) == "harness"
        (position, v) = only(batch.entries)        # sparse: the touched position alone
        @test position == 2 && v === 1.0       # `b` is position 2 of {a, b, c}
        @test recorded_faces(trc, batch) == [:b]
        @test trc.frames == 1

        # A frame nobody staged into records nothing and still advances the count:
        # `frames` is the recording's length, not its batch count.
        step!(sim)
        trc = trace(sim)
        @test length(trc.batches) == 1 && trc.frames == 2

        # A merged batch is recorded once, coalesced (§11.4): the drain is where the
        # conversion happens because the drained tuple is the coalesced truth.
        stage!(sim, "a" => 1.0)
        stage!(sim, "c" => 2.0, "a" => 3.0)
        step!(sim)
        batch = last(trace(sim).batches)
        @test batch.frame == 3 && recorded_faces(trace(sim), batch) == [:a, :c]
        @test [v for (_, v) in batch.entries] == [3.0, 2.0]

        # The quiet frame stays free: the trace's drain count is one field write,
        # and nothing is recorded where nothing was drained (§11.1, D-260).
        @test @ballocated(drain!($sim, $(sim.plane.roster))) == 0
    end

    @testset "the header is the post-sequence checkpoint (§11.5, §12.6, D-274)" begin
        sim = Simulation(boundary_movers(); h = 1//10)
        init!(sim, fragment(u = (sig = 1.0, e = 2.0)))
        header = trace(sim).header
        @test header isa Checkpoint
        # `flat.paths` is ["t", "d"]: boundary zero has fired the trigger's guard
        # and run the integrator's due `s_update`, and the header holds both.
        @test header.state.m == Any[(state = :fired, count = 1), nothing]
        @test header.state.s == Any[nothing, (acc = 0.2,)]
        @test header.state.m[1] == modes(sim, "t") && header.state.s[2] == state(sim, "d")
        # the table is the published one, every cell, and the prior the guard's
        # boundary-zero sample
        @test same_table(header.state.table, latest(sim).store)
        @test all(x.buffer !== y.buffer
                  for (x, y) in zip(values(header.state.table.stores), values(latest(sim).store.stores)))
        @test header.state.prior == [true]
        # the clock in full: frame 0, one publication behind it
        @test header.state.t === 0.0 && header.state.t₀ === 0.0
        @test header.frame == 0 && header.boundary == 1 == sim.run.boundary

        # The root inputs ride in the table as resolved values (§11.5): neither
        # face is ever staged, so no batch would carry them and replay would have
        # nothing.
        @test table_inputs(sim, header) == Pair{Symbol,Any}[:sig => 1.0, :e => 2.0]

        # The fingerprint, the `Deployment` itself and the structural layout
        # (§11.5, D-255): a restore compares both, and restores the clock.
        @test header.state.deployment == sim.model.deployment
        @test header.state.layout.paths == ["t", "d"] && header.state.layout.root_faces == [:sig, :e]

        # `trace(sim)` hands the header out detached: a write to the copy never
        # reaches the run's own.
        @test header !== sim.run.trace.header
        header.state.s[2] = (acc = 9.0,)
        header.state.prior[1] = false
        @test trace(sim).header.state.s[2] == (acc = 0.2,) && trace(sim).header.state.prior == [true]
    end

    @testset "the kill switch, and the clearing at `init!` (§11.5, D-029)" begin
        off = Simulation(three_root_inputs(); h = 1//10)
        init!(off, fragment(u = (a = 0.0, b = 0.0, c = 0.0)); trace = false)
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} trace(off))
        @test d.call === :trace && d.reason === :disabled
        stage!(off, "a" => 1.0)
        step!(off)
        @test off.run.trace === nothing        # the switch rides on the run (D-260)

        # Before the first `init!` there is no header, so there is no recording, and
        # the refusal is the one an advance entry gives (§12.6).
        sim = Simulation(three_root_inputs(); h = 1//10)
        d = carried(@test_throws DiagnosticError{MissingInit} trace(sim))
        @test d.op === :trace && d.status === :built

        init!(sim, fragment(u = (a = 0.0, b = 0.0, c = 0.0)))
        stage!(sim, "a" => 1.0)
        step!(sim)
        @test length(trace(sim).batches) == 1 && trace(sim).frames == 1
        # A re-run is a new trajectory: the trace is cleared and its header retaken.
        init!(sim, fragment(u = (a = 5.0, b = 0.0, c = 0.0)))
        trc = trace(sim)
        @test isempty(trc.batches) && trc.frames == 0
        @test table_inputs(sim, trc.header) == Pair{Symbol,Any}[:a => 5.0, :b => 0.0, :c => 0.0]
    end

    @testset "a roster change appends the writer set; earlier records keep their schema (§11.5)" begin
        sim = Simulation(three_root_inputs(); h = 1//10)
        init!(sim, fragment(u = (a = 0.0, b = 0.0, c = 0.0)))
        stage!(sim, "b" => 1.0)
        step!(sim)                                   # frame 1, against the whole surface

        handle = attach!(sim, Pad("d"), Enumerated("a"))  # a stopped-sim roster change
        stage!(sim, "b" => 2.0)                      # the harness surface is {b, c} now
        stage!(handle, "a" => 5.0)
        step!(sim)                                   # frame 2, in the drain's own order

        trc = trace(sim)
        # The list only grows: the first set stays, the new one is appended whole.
        @test length(trc.schemas) == 3
        @test trc.schemas[1] == ("harness" => [:a, :b, :c])
        @test trc.schemas[2] == ("device 1 (Pad)" => [:a])
        @test trc.schemas[3] == ("harness" => [:b, :c])

        (batch1, batch2, batch3) = trc.batches
        # `b` is position 2 of the old schema and position 1 of the new one, and both
        # records resolve to the same face — which is why the list may not be rewritten.
        @test batch1.frame == 1 && batch1.writer == 1 &&
              batch1.entries == Pair{Int,Any}[2 => 1.0]
        @test batch2.frame == 2 && batch2.writer == 2 &&
              batch2.entries == Pair{Int,Any}[1 => 5.0]
        @test batch3.frame == 2 && batch3.writer == 3 &&
              batch3.entries == Pair{Int,Any}[1 => 2.0]
        @test recorded_faces(trc, batch1) == [:b] && recorded_faces(trc, batch3) == [:b]
        @test recorded_faces(trc, batch2) == [:a]

        # A detach appends again, and the batches recorded under the wider set stand.
        detach!(sim, sim.plane.roster[1].dev)
        stage!(sim, "a" => 7.0)
        step!(sim)
        trc = trace(sim)
        @test length(trc.schemas) == 4
        batch4 = last(trc.batches)
        @test batch4.frame == 3 && batch4.writer == 4 && recorded_faces(trc, batch4) == [:a]
        @test trc.batches[1:3] ==
              [batch1, batch2, batch3]        # the earlier records, untouched
        # The ordinal a record carries is the trace's own drain count (D-260):
        # advanced at the top of the drain, one per frame, so after three frames
        # it is the clock's frame and the last batch's `frame` is it.
        @test trc.frames == 3 == sim.run.frame
    end
end

# --- replay's entry pass (§12.7, increment 23 stage 2) ---------------------------
# Validation and normalization, tested through `_compile_feed` alone: `replay!`
# and its loop are stage 3, and the pass is what a trace has to survive before a
# single write happens.

# The same three root inputs under one extra component: same faces, a different
# `Build` — §12.7's structural line, on the error side of it.
extra_component() = Group((; s = Sum(sa = 1.0, sb = 1.0), g = Gain(2.0), k = TickCounter());
                          input_wires = ("a" => "s/a", "b" => "s/b", "c" => "g/e"))

# One structure, one grid, one `sample_times` difference: `SampledLoop` exposes
# its controller's multiplier, so the pair differs in a schedule *row* and in
# nothing else §12.7 compares.
sampled_root(k) = Group((; l = SampledLoop(; ctl_rate = Relative(k)));
                        input_wires = ("ref" => "l/ref"))

sampled_session(k) = begin
    sim = Simulation(sampled_root(k); h = 1//10)
    init!(sim, fragment(u = (ref = 0.0,)))
    stage!(sim, "ref" => 1.0)
    step!(sim; frames = 2)
    sim
end

# A short recorded session over `three_root_inputs()`: two frames, one batch each.
function recorded_session()
    sim = Simulation(three_root_inputs(); h = 1//10)
    init!(sim, fragment(u = (a = 0.0, b = 0.0, c = 0.0)))
    stage!(sim, "b" => 1.0)
    step!(sim)
    stage!(sim, "a" => 2.0, "c" => 3.0)
    step!(sim)
    trace(sim)
end

# A recording's header and schemas behind a hand-built record list: the entry
# pass is what the assertions are about, so only the batches vary.
rebatch(trc, batches, frames) =
    Trace(trc.header, copy(trc.schemas), batches, frames)

# A fresh, initialized target of the recording's own build.
function replay_target()
    sim = Simulation(three_root_inputs(); h = 1//10)
    init!(sim, fragment(u = (a = 0.0, b = 0.0, c = 0.0)))
    sim
end

function trace_entry_pass()
    @testset "the scalar is a type, not a comparison (§12.7, D-317)" begin
        trc = recorded_session()
        # A `Trace` holds a `Checkpoint`, nominal by type, so `_compile_feed` has
        # no scalar to mismatch, and its refusal arm retired with its fallback.
        @test _compile_feed(replay_target(), trc) isa ReplayFeed
    end

    @testset "the header is compared against the build and the deployment binding (§12.7)" begin
        trc = recorded_session()

        # An extra component is a different store layout: the path list and the
        # cell-size list both move, and both are `:store`.
        err = failure(() -> _compile_feed(Simulation(extra_component(); h = 1//10), trc))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        d = only(d for d in diagnostics(err) if d.name === :paths)
        @test d.what === :store && d.expected == ["s", "g"] && d.found == ["s", "g", "k"]
        @test any(d -> d.what === :store && d.name === :sizes, diagnostics(err))

        # The seven trajectory-determining parameters, one assertion each where the
        # keyword is independently settable. `h` moves `Δt_base` with it — the two
        # are one grid — so the collection carries both.
        err = failure(() -> _compile_feed(Simulation(three_root_inputs(); h = 1//20), trc))
        d = only(x for x in diagnostics(err) if x.name === :h)
        @test d.what === :deployment && d.expected === 0.1 && d.found === 0.05
        @test any(x -> x.what === :deployment && x.name === :Δt_base, diagnostics(err))

        err = failure(() -> _compile_feed(
            Simulation(three_root_inputs(); h = 1//10, localization_budget = 4), trc))
        d = only(diagnostics(err))
        @test d.what === :deployment && d.name === :localization_budget
        @test d.expected == 8 && d.found == 4

        err = failure(() -> _compile_feed(
            Simulation(three_root_inputs(); h = 1//10, firing_budget = 2), trc))
        d = only(diagnostics(err))
        @test d.what === :deployment && d.name === :firing_budget
        @test d.expected == 4 && d.found == 2

        # The clock is restored rather than compared (§12.7).
        @test _compile_feed(Simulation(three_root_inputs(); h = 1//10), trc) isa ReplayFeed
    end

    @testset "a schedule row whose column differs is refused by path and column (§12.7)" begin
        # §12.7's value covers the schedule with every column, so a component
        # re-declared at half the rate is a different deployment — and the refusal
        # names the row's path and the column rather than a bare parameter.
        trc = trace(sampled_session(1))
        err = failure(() -> _compile_feed(sampled_session(2), trc))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        d = only(x for x in diagnostics(err) if x.name === :D)
        @test d.what === :deployment && d.path == "l/ctl"
        @test d.expected == 1 && d.found == 2
        # the other columns the one re-declaration moves ride beside it, each named
        @test any(x -> x.path == "l/ctl" && x.name === :Δt, diagnostics(err))
        @test any(x -> x.path == "l/ctl" && x.name === :rates, diagnostics(err))
        # …and the same deployment against itself is no refusal at all
        @test _compile_feed(sampled_session(1), trc) isa ReplayFeed
    end

    @testset "a recorded schema is validated against the target's own faces (§11.5, §12.7)" begin
        trc = recorded_session()
        # The header rebuilt with one foreign name in the harness schema: the
        # positional records are meaningless without the schema, so the schema is
        # what has to agree with this model.
        bent = Trace(trc.header, [("harness" => [:a, :zzz, :c])],
                     copy(trc.batches), trc.frames)
        err = failure(() -> _compile_feed(replay_target(), bent))
        d = only(diagnostics(err))
        @test err isa DiagnosticError && d isa ReplaySchemaMismatch
        @test d.writer == "harness" && d.unknown == [:zzz]
        @test d.schema == [:a, :zzz, :c] && d.faces == [:a, :b, :c]

        # The header's own disagreements come first and alone: a trace that is both
        # schema-bent and entry-bent reports the schema, because a record resolved
        # through a contradicted schema would report noise (§12.7's two stages).
        bad = Trace(trc.header, copy(bent.schemas),
                    [TraceBatch(1, 1, Pair{Int,Any}[9 => 1.0])], 1)
        @test kinds(failure(() -> _compile_feed(replay_target(), bad))) == [ReplaySchemaMismatch]
    end

    @testset "every position resolves through its schema, and the misses collect (§12.7)" begin
        trc = recorded_session()
        # Three bad records in one trace: a position past the schema's end, a
        # position below its start, and a batch naming a writer the schema list does
        # not have — which is the same failure with the tag spelled positionally.
        bad = rebatch(trc, [TraceBatch(1, 1, Pair{Int,Any}[7 => 1.0]),
                            TraceBatch(2, 1, Pair{Int,Any}[0 => 1.0, 2 => 5.0]),
                            TraceBatch(2, 9, Pair{Int,Any}[1 => 1.0])], 2)
        err = failure(() -> _compile_feed(replay_target(), bad))
        @test err isa DiagnosticError && all(d isa ReplayUnknownFace for d in diagnostics(err))
        @test [(d.face, d.frame, d.writer) for d in diagnostics(err)] ==
              [(7, 1, "harness"), (0, 2, "harness"), (1, 2, "writer #9")]
        @test all(d -> d.faces == [:a, :b, :c], diagnostics(err))

        # An unconvertible recorded value is not a face problem: the face is known
        # and the *value* is what the target's compiled scatter cannot take.
        err = failure(() -> _compile_feed(
            replay_target(), rebatch(trc, [TraceBatch(1, 1, Pair{Int,Any}[1 => "x"])], 1)))
        d = only(diagnostics(err))
        @test d isa CheckpointMismatch && d.what === :root_input
        @test d.name === :a && d.expected === Float64 && d.found == "x"
    end

    @testset "a frame ordinal outside the recording's own length is refused (§12.7)" begin
        trc = recorded_session()
        # The drain visits each frame of `1:frames` exactly once, so a record stamped
        # outside that range names a frame that never comes round: under an exactly
        # keyed cursor it would silently never apply. Both misses collect, named by
        # the writer whose schema the record was written under.
        bad = rebatch(trc, [TraceBatch(0, 1, Pair{Int,Any}[1 => 9.0]),
                            TraceBatch(99, 1, Pair{Int,Any}[1 => 9.0])], 2)
        err = failure(() -> _compile_feed(replay_target(), bad))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        @test all(d -> d.what === :frame && d.name === :harness && d.expected == 1:2,
                  diagnostics(err))
        @test [d.found for d in diagnostics(err)] == [0, 99]

        # With no schema to name the writer either, the tag is spelled positionally —
        # and the frame is the one fault reported, the record being unreachable.
        d = only(diagnostics(failure(() -> _compile_feed(replay_target(),
                    rebatch(trc, [TraceBatch(0, 9, Pair{Int,Any}[1 => 9.0])], 2)))))
        @test d isa CheckpointMismatch && d.what === :frame && d.name === Symbol("writer #9")

        # A trace a restore opened starts at the checkpoint's frame: a record
        # stamped at or before it is behind the feed and never comes round either.
        replayed = replay_target()
        replay!(replayed, trc)
        opened = Simulation(three_root_inputs(); h = 1//10)
        restore!(opened, checkpoint(replayed))
        late = trace(opened)
        @test late.header.frame == 2
        bad = rebatch(late, [TraceBatch(1, 1, Pair{Int,Any}[1 => 9.0]),
                             TraceBatch(2, 1, Pair{Int,Any}[1 => 9.0]),
                             TraceBatch(3, 1, Pair{Int,Any}[1 => 9.0])], 3)
        err = failure(() -> _compile_feed(replay_target(), bad))
        @test err isa DiagnosticError &&
              all(d -> d isa CheckpointMismatch && d.what === :frame && d.expected == 3:3,
                  diagnostics(err))
        @test [d.found for d in diagnostics(err)] == [1, 2]
    end

    @testset "a valid trace normalizes to compiled scatters, in drain order (§12.7, D-101)" begin
        trc = recorded_session()
        target = replay_target()
        feed = _compile_feed(target, trc)
        @test [record.frame for record in feed.records] == [1, 2]
        @test feed.next == 1 && length(feed.records) == 2
        # The recorded batch rides beside its thunk: a replay re-records, and what it
        # re-records is the recording's own value (§12.7).
        @test [record.record for record in feed.records] == trc.batches

        # The thunks *are* the recording, applied to this build's cells: sparse, so
        # an untouched face keeps whatever the target's own `init!` put there.
        cells() = (port(target, "", :a), port(target, "", :b), port(target, "", :c))
        @test cells() == (0.0, 0.0, 0.0)
        feed.records[1].thunk()
        @test cells() == (0.0, 1.0, 0.0)
        feed.records[2].thunk()
        @test cells() == (2.0, 1.0, 3.0)

        # A superseded schema entry is compiled against the target's layout like any
        # other, so a recording that outlived a roster change replays whole.
        sim = Simulation(three_root_inputs(); h = 1//10)
        init!(sim, fragment(u = (a = 0.0, b = 0.0, c = 0.0)))
        stage!(sim, "b" => 1.0)
        step!(sim)
        attach!(sim, Pad("d"), Enumerated("a"))
        stage!(sim, "b" => 2.0)
        step!(sim)
        grown = _compile_feed(replay_target(), trace(sim))
        @test [record.record.writer for record in grown.records] == [1, 3]   # both schema entries live
    end
end

# --- replay as the ordinary loop (§12.7, increment 23 stage 3) -------------------
# The restore from the header and the drain reading the trace (D-274), and the
# properties they exist to buy: bit-identity against the identical build, partial
# replay and the reproduction it opens, continuation, the discard of live
# staging, and the what-if replay.

# One model reaching all three state homes with a localized event in the middle:
# the reference-fed plant of `feedback_model` (continuous state, a feedback
# wire), a discrete integrator on a second root input (discrete state), and an
# autonomous bouncer whose reset lands *between* frame tops — so a replay has to
# reproduce `t*` boundaries (§10.4) and mode state, not just a grid of frames.
# `k` is the parameter the what-if replay moves.
replay_model(k = 4.0) =
    Group((plant = Plant(; ω = 2.0, ζ = 0.1), ctl = Gain(k), sum = Sum(),
           acc = DiscreteAccumulator(1.0), b = Bouncer(1.0, 0.32));
          local_wires = ("ctl/out" => "plant/u", "sum/e" => "ctl/e", "plant/y" => "sum/b"),
          input_wires = ("ref" => "sum/a", "rate" => "acc/e"),
          output_wires = ("b/q" => "bq", "acc/u" => "u"))

# Every cell of a published table, in a build-independent order: two sessions
# are two `Simulation`s, so their layouts are equal *values* rather than one
# object, and the sorted address list is what makes "the same table" mean the
# same thing on both sides. Bit-identity is asserted with `==` — that is the
# claim (§12.7), D-163's tolerance rule being about numerical agreement.
snap_cells(s::Snapshot) =
    Any[gather_cell(s.store, s.layout.addr[k]) for k in sort!(collect(keys(s.layout.addr)))]

# Two sessions' logs, boundary for boundary: the `t` stamps and every cell.
same_trajectory(candidate, reference) =
    length(candidate) == length(reference) &&
    all(x.t == y.t && x.frame == y.frame && snap_cells(x) == snap_cells(y)
        for (x, y) in zip(candidate, reference))

# The frame-top publication of frame `frame`: a frame with a `t*` boundary publishes
# more than once under the same ordinal, and the frame's own boundary is last.
at_frame(snapshots, frame::Int) =
    last(snapshot for snapshot in snapshots if snapshot.frame == frame)

# A recorded session over `replay_model()`, staged from the harness across
# frames: eight frames, batches at 1 and 4, two localized resets inside.
function recorded_run()
    sim = Simulation(replay_model(); h = 1//10)
    init!(sim, fragment(u = (ref = 1.0, rate = 0.0)))
    stage!(sim, "ref" => 2.0)
    step!(sim; frames = 3)
    stage!(sim, "rate" => 1.0)
    step!(sim; frames = 5)
    (sim, trace(sim))
end

# A fresh target of that build, initialized from a *different* condition — so
# nothing but the header can put it on the recorded trajectory. The keywords
# are `init!`'s recording keywords, for this door alone (D-261).
function replay_twin(k = 4.0; kw...)
    sim = Simulation(replay_model(k); h = 1//10)
    init!(sim, fragment(u = (ref = 0.0, rate = 0.0)); kw...)
    sim
end

function trace_replay_loop()
    @testset "a replay reproduces the recorded trajectory bitwise (§12.7, D-101)" begin
        (sim, trc) = recorded_run()
        sim2 = replay_twin()
        replay!(sim2, trc)

        # §12.7: the replay ends `initialized`, never `stopped` — boundary-consistent
        # and ready to advance, which is what makes inspect/step/continue real.
        @test lifecycle(sim2) === :initialized && termination(sim2) === nothing
        @test !closed(sim2.run)
        # …and `:live`, the halt having landed at the recording's last frame: the
        # records are exhausted, so whatever advances next is a live frame (D-218).
        @test mode(sim2) === :live && sim2.run.feed === nothing
        @test sim2.run.frame == trc.frames
        @test same_trajectory(logged(sim2), logged(sim))
        # …including the localized boundaries the recording never stored: `t*` is
        # derived from state (§10.4), so reproducing the state reproduces the timing.
        @test length(logged(sim)) == trc.frames + 3     # boundary zero + two resets
        # the live stores agree too, the snapshots deliberately not carrying them
        @test state(sim2, "plant").q === state(sim, "plant").q
        @test state(sim2, "acc") === state(sim, "acc") && modes(sim2, "b") === modes(sim, "b")
        # and the replay re-records: the header inherited, the batches re-drained
        @test trace(sim2).frames == trc.frames
        @test trace(sim2).batches == trc.batches

        # …as an *equal value*, never the recording's own objects: the two traces are
        # two values, so a continuation's growth cannot reach the `Trace` in hand.
        recording = trace(sim2)
        @test all(recording.batches[i] !== trc.batches[i] for i in eachindex(trc.batches))
        @test recording.header.state.x !== trc.header.state.x && recording.header.state.x == trc.header.state.x
        @test recording.header.state.s !== trc.header.state.s && recording.header.state.m !== trc.header.state.m
        @test recording.header.state.s == trc.header.state.s && recording.header.state.m == trc.header.state.m
        @test recording.header.state.prior !== trc.header.state.prior &&
              recording.header.state.prior == trc.header.state.prior
        @test all(x.buffer !== y.buffer for (x, y) in zip(values(recording.header.state.table.stores),
                                                           values(trc.header.state.table.stores)))
        @test same_table(recording.header.state.table, trc.header.state.table)
        @test table_inputs(sim2, recording.header) == table_inputs(sim, trc.header)
        # …and the replay's snapshots carry the recording's ordinals, the first
        # one re-published under the header's own boundary (D-230, D-274)
        @test [x.boundary for x in logged(sim2)] == [x.boundary for x in logged(sim)]
        @test recording.schemas !== trc.schemas

        # §12.7's own door — `Simulation(world)` then `replay!`, no `init!` at
        # all: `replay!` *is* a door into `initialized`, so it owes one to nothing.
        raw = Simulation(replay_model(); h = 1//10)
        @test lifecycle(raw) === :built
        replay!(raw, trc)
        @test lifecycle(raw) === :initialized
        @test same_trajectory(logged(raw), logged(sim))
    end

    @testset "replay! paces, bit-identical to the unpaced replay (§12.7, §10.7)" begin
        (sim, trc) = recorded_run()
        unpaced = replay_twin()
        replay!(unpaced, trc)
        paced = replay_twin()
        start = time_ns()
        replay!(paced, trc; pace = 10)                 # 10 ms budgets at h = 0.1
        elapsed = (time_ns() - start) / 1.0e9
        @test elapsed ≥ (trc.frames - 1) * 0.1 / 10     # the first frame has no wait (D-269)
        @test pace(paced) == 10 && latest(paced).status.pacer.pace == 10
        @test latest(paced).status.pacer.waits > 0
        @test same_trajectory(logged(paced), logged(unpaced))
        @test same_trajectory(logged(paced), logged(sim))
    end

    @testset "a device's recorded batches replay on a deviceless twin (§12.7)" begin
        sim = Simulation(replay_model(); h = 1//10)
        attach!(sim, Nudge("rate", 3.0), Enumerated("rate"))
        init!(sim, fragment(u = (ref = 1.0, rate = 0.0)))
        stage!(sim, "ref" => 2.0)      # the harness surface is {ref}: the device holds {rate}
        run!(sim; t_end = 2.0)
        trc = trace(sim)
        @test lifecycle(sim) === :stopped

        # "No devices or mappings present" (§12.7): the recorded batches carry the
        # device's writes, and the schemas resolve them against this build's faces.
        sim2 = replay_twin()
        replay!(sim2, trc)
        @test lifecycle(sim2) === :initialized
        @test same_trajectory(logged(sim2), logged(sim))
        @test state(sim2, "acc") === state(sim, "acc")
        @test trace(sim2).batches == trc.batches
    end

    @testset "partial replay halts at a frame top, and the next frame reproduces (§12.7, §13.4)" begin
        (sim, trc) = recorded_run()
        sim2 = replay_twin()
        replay!(sim2, trc; to_boundary = 5)
        @test lifecycle(sim2) === :initialized      # the replay pointer: ready to advance
        @test sim2.run.frame == 5     # the halt is at `k` itself (§12.7, §13.4)
        @test trace(sim2).frames == 5
        @test same_trajectory(logged(sim2),
                              [snapshot for snapshot in logged(sim) if snapshot.frame ≤ 5])

        # §12.6's register, read beside the lifecycle: the halt is short of the
        # recording's end, so the recording is still attached and still the source
        # of the next frame's inputs (D-218).
        @test mode(sim2) === :replay

        # §13.4's workflow minus the error: step the next frame under whatever
        # instrumentation is wanted, and it is the recording's frame 6 bitwise.
        @test step!(sim2) == 1
        @test snap_cells(latest(sim2)) == snap_cells(at_frame(logged(sim), 6))
        @test latest(sim2).t == at_frame(logged(sim), 6).t
        @test mode(sim2) === :replay                # two frames of the recording left
    end

    @testset "`to_time` addresses the same halt by time (§12.7, D-219)" begin
        (sim, trc) = recorded_run()
        prefix(frame) = [snapshot for snapshot in logged(sim) if snapshot.frame ≤ frame]

        # On grid: the time of boundary 5 halts *at* 5, never at the one below it.
        on = replay_twin()
        replay!(on, trc; to_time = 0.5)
        @test lifecycle(on) === :initialized && on.run.frame == 5
        @test mode(on) === :replay                  # short of the end, so still attached
        @test same_trajectory(logged(on), prefix(5))

        # …and on grid means on the grid the caller *names*, not the one binary
        # floats compute: `0.3 / 0.1` is `2.9999999999999996`, so the plain floor
        # would halt at 2. The guard is `step!`'s `t_plus` slack, in the other
        # direction.
        fuzz = replay_twin()
        replay!(fuzz, trc; to_time = 0.3)
        @test fuzz.run.frame == 3

        # Between two frame tops the halt floors onto the earlier one — D-219's
        # deliberate opposite of `t_end`'s reach-or-exceed rule, because the point
        # of halting is to stand *before* the anomaly.
        between = replay_twin()
        replay!(between, trc; to_time = 0.55)
        @test between.run.frame == 5
        @test same_trajectory(logged(between), prefix(5))

        # `t₀` itself is the empty halt: boundary zero and no frame.
        zero = replay_twin()
        replay!(zero, trc; to_time = trc.header.state.t₀)
        @test zero.run.frame == 0 && lifecycle(zero) === :initialized
        @test trace(zero).frames == 0

        # An origin far from zero: at `t₀ = -0.3`, `to_time = 0.0` is boundary 3.
        # `0.3 / 0.1` falls short of 3 by more than an ulp of zero, so the floor's
        # slack measures the origin's magnitude, not the time's.
        shifted = Simulation(replay_model(); h = 1//10)
        init!(shifted, fragment(u = (ref = 1.0, rate = 0.0)); t0 = -0.3)
        step!(shifted; frames = 5)
        near_zero = replay_twin()
        replay!(near_zero, trace(shifted); to_time = 0.0)
        @test near_zero.run.frame == 3
    end

    @testset "`to_time`'s refusals precede every write (§12.7, D-219)" begin
        (_, trc) = recorded_run()

        # The two spellings are of one halt, so both together is a refusal, not a
        # precedence rule the reader would have to know.
        target = replay_twin()
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(target, trc; to_boundary = 5, to_time = 0.5))
        @test d.call === :replay! && d.reason === :both_given
        @test lifecycle(target) === :initialized && target.run.frame == 0 && mode(target) === :live

        # Before `t₀`, past the recording's own reach, and the two non-finites: each
        # names the argument and the value, and each precedes every write.
        for bad in (-0.1, 0.9, NaN, Inf)
            target = replay_twin()
            d = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(target, trc; to_time = bad))
            @test d.call === :replay! && d.reason === :range
            @test d.argument === :to_time && d.value === bad
            @test lifecycle(target) === :initialized && mode(target) === :live
        end

        # …including on a target that has never been through `init!`: a rejected
        # replay leaves it `built`, the door untaken.
        raw = Simulation(replay_model(); h = 1//10)
        @test failure(() -> replay!(raw, trc; to_time = 99.0)) isa DiagnosticError
        @test lifecycle(raw) === :built

        # A target bound at a different `h`: the conversion runs on the recording's
        # own grid, so a covered time is never refused as out of range — the
        # mismatch falls through to the entry pass, which names it honestly.
        coarse = Simulation(replay_model(); h = 1//20)
        init!(coarse, fragment(u = (ref = 0.0, rate = 0.0)))
        err = failure(() -> replay!(coarse, trc; to_time = 0.5))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        @test any(d.what === :deployment && d.name === :h for d in diagnostics(err))
    end

    @testset "the recording bounds a replaying advance, and the end flips the mode (§12.7, D-218)" begin
        (sim, trc) = recorded_run()
        sim2 = replay_twin()
        replay!(sim2, trc; to_boundary = 5)
        @test mode(sim2) === :replay

        # A `run!` whose `t_end` lies far past the recording does not run past it:
        # the frame budget is capped at the last recorded frame, the halt lands
        # there `initialized`, and only *then* does the mode go `:live`.
        stage!(sim2, "ref" => 99.0)                 # a live batch met by a replaying frame
        run = sim2.run
        run!(sim2; t_end = 5.0)
        @test lifecycle(sim2) === :initialized && termination(sim2) === nothing
        @test !closed(sim2.run)
        @test sim2.run.frame == trc.frames
        @test mode(sim2) === :live && sim2.run.feed === nothing
        # §12.6: the mode is read off the feed, so the flip is a *write* to the
        # run — the same object, with the same log and the same trace (D-260)
        @test sim2.run === run && sim2.run.log === run.log && sim2.run.trace === run.trace
        @test same_trajectory(logged(sim2), logged(sim))    # the recording's own trajectory
        @test port(sim2, "", :ref) == 2.0                   # never the 99.0 staged into it
        seen = [d for snapshot in logged(sim2) for w in snapshot.status.writers
                  if w.who == "harness" for d in w.recent if d isa ReplayDiscardedStaging]
        @test length(seen) == 1 && only(seen).faces == [:ref] && only(seen).frame == 6

        # The next call is the live continuation: the same staging surface, applied.
        stage!(sim2, "ref" => 7.0)
        run!(sim2; t_end = 1.0)
        @test lifecycle(sim2) === :stopped && mode(sim2) === :live
        @test port(sim2, "", :ref) == 7.0
    end

    @testset "a `step!` past the recording's end advances only to it (§12.7, D-218)" begin
        (_, trc) = recorded_run()
        sim2 = replay_twin()
        replay!(sim2, trc; to_boundary = 5)
        # The return value is the truncation, as under a §13.5 stop: three frames of
        # recording left, ten asked for.
        @test step!(sim2; frames = 10) == 3
        @test sim2.run.frame == trc.frames
        @test lifecycle(sim2) === :initialized && mode(sim2) === :live
        @test step!(sim2; frames = 2) == 2           # and the next call is live again
        @test sim2.run.frame == trc.frames + 2
    end

    @testset "`init!` after a partial replay returns the mode to `:live` (§12.6, D-218)" begin
        (_, trc) = recorded_run()
        sim2 = replay_twin()
        replay!(sim2, trc; to_boundary = 5)
        @test mode(sim2) === :replay

        # `init!` opens a fresh trajectory, and the mode returns with it: the
        # recording detaches, and the next frame's drain is the staging cells'.
        init!(sim2, fragment(u = (ref = 0.0, rate = 0.0)))
        @test mode(sim2) === :live && sim2.run.feed === nothing
        @test sim2.run.frame == 0
        stage!(sim2, "ref" => 3.0)
        @test step!(sim2) == 1
        @test port(sim2, "", :ref) == 3.0
    end

    @testset "a continuation is a live session from the replayed boundary (§12.7)" begin
        (sim, trc) = recorded_run()
        sim2 = replay_twin()
        replay!(sim2, trc)
        @test mode(sim2) === :live                  # a full replay exhausts the records
        stage!(sim2, "rate" => 4.0)                 # so this batch is applied, not discarded
        run!(sim2; t_end = 1.4)                     # `run!` after `replay!`
        @test mode(sim2) === :live && port(sim2, "", :rate) == 4.0
        @test lifecycle(sim2) === :stopped && termination(sim2).source === EndTimeReached()
        @test sim2.run.frame == 14           # it proceeded from frame 8, not from zero
        # The session leaves behind a complete, valid trace of *itself*, with the
        # recording as a bit-identical prefix and no special stitching (§12.7).
        continuation = trace(sim2)
        @test continuation.frames == 14 > trc.frames
        @test continuation.batches[1:length(trc.batches)] == trc.batches
        @test same_table(continuation.header.state.table, trc.header.state.table)   # the header inherited
        # the recording's schema entries stand, this session's appended behind them
        @test continuation.schemas[1:length(trc.schemas)] == trc.schemas
        # the continuation's own drains write under the appended set, never the
        # recording's (D-260: the range is local to the recompile, so the batch
        # index is what names it)
        @test last(continuation.batches).writer > length(trc.schemas)
    end

    @testset "`live!` takes a replayed halt live, and the session records itself (§12.7, D-219)" begin
        (sim, trc) = recorded_run()
        sim2 = replay_twin()
        replay!(sim2, trc; to_time = 0.5)
        @test mode(sim2) === :replay && sim2.run.frame == 5

        # The door moves the mode and nothing else: the trajectory stands at the
        # halt, and so does the run's trace with the header it inherited and the
        # batches it has re-recorded.
        run = sim2.run
        live!(sim2)
        @test mode(sim2) === :live && sim2.run.feed === nothing
        # the flip is a write, not a rebuild: the same run, log and trace (D-260)
        @test sim2.run === run && sim2.run.log === run.log && sim2.run.trace === run.trace
        @test lifecycle(sim2) === :initialized && sim2.run.frame == 5
        at_halt = trace(sim2)
        @test at_halt.frames == 5 && at_halt.batches == trc.batches
        @test same_table(at_halt.header.state.table, trc.header.state.table)

        # The remainder is *dropped*, not consumed: a batch staged now is applied
        # rather than discarded, and the continuation leaves the recording's tail.
        stage!(sim2, "rate" => 9.0)
        run!(sim2; t_end = 0.8)
        @test lifecycle(sim2) === :stopped && mode(sim2) === :live
        @test termination(sim2).source === EndTimeReached()
        @test port(sim2, "", :rate) == 9.0
        @test sim2.run.frame == trc.frames
        @test snap_cells(at_frame(logged(sim2), 8)) != snap_cells(at_frame(logged(sim), 8))
        @test same_trajectory([snapshot for snapshot in logged(sim2) if snapshot.frame ≤ 5],
                              [snapshot for snapshot in logged(sim) if snapshot.frame ≤ 5])

        # …and the trace left behind is one seamless recording of the session: the
        # replayed prefix bit for bit, then the frames flown live after it.
        continuation = trace(sim2)
        @test continuation.frames == 8
        @test continuation.batches[1:length(trc.batches)] == trc.batches
        @test length(continuation.batches) == length(trc.batches) + 1
        @test last(continuation.batches).frame == 6
    end

    @testset "`live!`'s refusals are loud, never a no-op (§12.7, §12.6, D-219)" begin
        (_, trc) = recorded_run()

        # Already `:live`, having never replayed at all…
        fresh = replay_twin()
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} live!(fresh))
        @test d.call === :live! && d.reason === :not_replaying
        @test mode(fresh) === :live && lifecycle(fresh) === :initialized

        # …and already `:live` because the replay ran to the recording's end, where
        # D-218's automatic flip already did the work.
        done = replay_twin()
        replay!(done, trc)
        @test mode(done) === :live
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} live!(done))
        @test d.call === :live! && d.reason === :not_replaying

        # `live!` is not a door into `initialized`: it moves the mode of a simulation
        # that already has a trajectory, so `built` refuses as an advance entry does.
        raw = Simulation(replay_model(); h = 1//10)
        d = carried(@test_throws DiagnosticError{MissingInit} live!(raw))
        @test d.op === :live! && d.status === :built

        # Both terminal states refuse under the ordinary lifecycle gate.
        stopped = replay_twin()
        run!(stopped; t_end = 0.2)
        @test lifecycle(stopped) === :stopped
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} live!(stopped))
        @test d.op === :live! && d.status === :stopped

        crashed = Simulation(fed(Exploder(), "arm"); h = 1//10)
        init!(crashed, fragment(u = (in = 0.0,)))
        stage!(crashed, "in" => true)
        @test_throws StepError run!(crashed; t_end = 5.0)
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} live!(crashed))
        @test d.op === :live! && d.status === :errored
        # (`live!` from `:running` is the same gate the two advance entries share,
        # and reaching it needs `test_lifecycle.jl`'s spawned-run idiom; it is
        # asserted there, for those two entries, and not here.)
    end

    @testset "the replay door checks the thread budget too (§12.2, §11.3)" begin
        # `replay!` shares the run body, so it checks once against the frozen
        # roster as `run!` does. One claimless probe per thread makes the run
        # tight on every layout.
        (_, trc) = recorded_run()
        sim2 = replay_twin()
        for _ in 1:Threads.nthreads()
            attach!(sim2, TailProbe(), NoClaim())
        end
        replay!(sim2, trc)
        @test lifecycle(sim2) === :initialized
        records = [writer_status(snapshot, "loop") for snapshot in logged(sim2)[2:end]]
        @test all(record.totals.thread_budget == 1 for record in records)
        @test [length(record.recent) for record in records] ==
              [1; zeros(Int, length(records) - 1)]
        @test only(records[1].recent) == ThreadBudget(Threads.nthreads(), Threads.nthreads())
    end
end

# Every discard this writer's account carried, rendered: off a published
# status's `recent` where the frame-top fold caught it (§11.8), and off the
# run's-end sweep's warning where the device's stage landed past the final frame
# top (§12.4) — a replay ends `initialized`, so the sweep has no termination
# record to file its residue in and the log is where it surfaces.
discard_reports(sim, logs, who::String) =
    vcat(String[message(d) for snapshot in logged(sim) for w in snapshot.status.writers
                if w.who == who for d in w.recent if d isa ReplayDiscardedStaging],
         String[string(l.message) for l in logs
                if occursin("ReplayDiscardedStaging from $who, past the final",
                            string(l.message))])

function trace_discarded_staging()
    @testset "live staging met by a replay is discarded, and reported (§12.7, §11.8)" begin
        (sim, trc) = recorded_run()
        sim2 = replay_twin()
        dev = Nudge("rate", 99.0)                   # a value that would move the trajectory
        attach!(sim2, dev, Enumerated("rate"))
        logs, _ = Test.collect_test_logs() do
            replay!(sim2, trc)                      # devices are readers: they init and spawn
        end
        @test lifecycle(sim2) === :initialized

        # The property the discard exists to protect: the trajectory is still the
        # recording's, bit for bit, with a live writer staging into the run.
        @test same_trajectory(logged(sim2), logged(sim))
        @test state(sim2, "acc") === state(sim, "acc")
        @test trace(sim2).batches == trc.batches    # and nothing of the device's is recorded

        # …and the drop is loud: one report, on the device's own cell (§11.8's
        # attribution), naming the faces it cost. Wherever the device's timing put
        # it — the account's totals, or the run's-end sweep — it is accounted once.
        who = "device 1 (Nudge)"
        @test accounted(sim2, logs, who, :replay_discarded, "ReplayDiscardedStaging")
        report = only(discard_reports(sim2, logs, who))
        @test occursin("{rate}", report)
        seen = [d for snapshot in logged(sim2) for w in snapshot.status.writers
                  if w.who == who for d in w.recent if d isa ReplayDiscardedStaging]
        @test all(d -> d.faces == [:rate] && 1 ≤ d.frame ≤ trc.frames, seen)
    end
end

# The harness arm of the same discard, with a concurrent route into it: a
# spawned device whose `stage!(sim, …)` — the harness writer's own surface,
# not the device's claim — lands mid-replay, frame after frame, from its own
# task beside the loop on the calling task (§11.1).
mutable struct HarnessPoker <: AbstractDevice
    sim::Any
end
loop(dev::HarnessPoker, handle) = (while running(handle);
                                   stage!(dev.sim, "ref" => 99.0); yield(); end;
                                   nothing)

function trace_discarded_harness()
    @testset "live staging into the harness is discarded on its own cell (§12.7, §11.8)" begin
        # A long recording, so the poker's task is scheduled against a run with
        # frames left to give it: its stage is deterministic, its timing never is.
        sim = Simulation(replay_model(); h = 1//10)
        init!(sim, fragment(u = (ref = 1.0, rate = 0.0)))
        stage!(sim, "ref" => 2.0)
        step!(sim; frames = 400)
        trc = trace(sim)

        sim2 = replay_twin()
        dev = HarnessPoker(nothing)
        attach!(sim2, dev, Enumerated("rate"))     # the device claims `rate`; `ref` stays the harness's
        dev.sim = sim2
        logs, _ = Test.collect_test_logs() do
            replay!(sim2, trc)
        end
        @test lifecycle(sim2) === :initialized

        # The same property the device arm buys, through the other writer: the
        # trajectory is the recording's bit for bit, and none of the poker's 99.0 is
        # recorded — the header's `ref` survives to the end.
        @test same_trajectory(logged(sim2), logged(sim))
        @test trace(sim2).batches == trc.batches
        @test port(sim2, "", :ref) == 2.0

        # …and the drop is loud on the *harness* cell (§11.8's attribution), naming
        # the faces it cost — the device's own account untouched, it never staged.
        seen = [d for snapshot in logged(sim2) for w in snapshot.status.writers
                  if w.who == "harness" for d in w.recent if d isa ReplayDiscardedStaging]
        @test !isempty(discard_reports(sim2, logs, "harness"))
        @test all(d -> d.faces == [:ref] && 1 ≤ d.frame ≤ trc.frames, seen)
        @test writer_status(latest(sim2), "harness").totals.replay_discarded ≥ length(seen) ≥ 1
        @test writer_status(latest(sim2), "device 1 (HarnessPoker)").totals.replay_discarded == 0
    end

    @testset "a changed parameter replays deterministically: the what-if replay (§12.7, D-274)" begin
        (sim, trc) = recorded_run()
        # Same structure, a different gain — *parametric* difference, on the
        # non-error side of §12.7's line: the recorded inputs re-driven through a
        # modified model. The trace's header holds the recording model's state, so
        # the modified model is initialized under the authored condition, which
        # comes from outside the trace, and the feed restores nothing.
        # Determinism is promised; reproduction is not.
        what_if() = (candidate = Simulation(replay_model(9.0); h = 1//10);
                     init!(candidate, fragment(u = (ref = 1.0, rate = 0.0)));
                     candidate)
        first_run = what_if()
        replay!(first_run, trc; restore = false)
        @test lifecycle(first_run) === :initialized && mode(first_run) === :live
        @test first_run.run.frame == trc.frames
        @test state(first_run, "plant").q != state(sim, "plant").q
        # the new trace opens from the simulation's own state and re-records the feed
        @test trace(first_run).header.frame == 0 && trace(first_run).batches == trc.batches

        # Deterministic: the same what-if twice is the same trajectory.
        second_run = what_if()
        replay!(second_run, trc; restore = false)
        @test same_trajectory(logged(second_run), logged(first_run))
        @test [x.boundary for x in logged(second_run)] == [x.boundary for x in logged(first_run)]

        # The entry pass runs under this form too: a deployment change is never a
        # what-if (§12.7).
        coarse = Simulation(replay_model(9.0); h = 1//20)
        init!(coarse, fragment(u = (ref = 1.0, rate = 0.0)))
        err = failure(() -> replay!(coarse, trc; restore = false))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        @test any(d.what === :deployment && d.name === :h for d in diagnostics(err))
        @test coarse.run.frame == 0 && lifecycle(coarse) === :initialized

        # …and it joins a trajectory in progress, so only `initialized` admits it.
        raw = Simulation(replay_model(9.0); h = 1//10)
        d = carried(@test_throws DiagnosticError{MissingInit} replay!(raw, trc; restore = false))
        @test d.op === :replay! && d.status === :built
    end

    @testset "the lifecycle and range refusals of `replay!` (§12.7, §12.6)" begin
        (_, trc) = recorded_run()
        # `to_boundary` is a pointer into the recording: past its end there is
        # nothing to replay, and the refusal names the argument and its value.
        for bad in (9, -1, 2.5)
            d = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(replay_twin(), trc; to_boundary = bad))
            @test d.call === :replay! && d.reason === :range
            @test d.argument === :to_boundary && d.value == bad
        end
        @test lifecycle(replay_twin()) === :initialized      # a rejected replay wrote nothing

        # `restore` is a door keyword like the recording four, collected with them.
        target = replay_twin()
        err = failure(() -> replay!(target, trc; restore = nothing, log_every = 0))
        @test err isa DiagnosticError && all(d isa ArgumentInvalid && d.call === :replay! &&
                                             d.reason === :range for d in diagnostics(err))
        @test [(d.argument, d.value) for d in diagnostics(err)] ==
              [(:log_every, 0), (:restore, nothing)]
        @test lifecycle(target) === :initialized && target.run.frame == 0 &&
              mode(target) === :live

        # `errored` is terminal (§13.6): never resumable, never re-initialized, and
        # `replay!` is refused there exactly as `init!` is — reproduction is
        # replaying the trace on a *fresh* simulation, which is the arm above.
        crashed = Simulation(fed(Exploder(), "arm"); h = 1//10)
        init!(crashed, fragment(u = (in = 0.0,)))
        own = trace(crashed)
        stage!(crashed, "in" => true)
        @test_throws StepError run!(crashed; t_end = 5.0)        # §13.4's wrap, the cause one level down
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} replay!(crashed, own; t_end = 5.0))
        @test d.op === :replay! && d.status === :errored
        @test d.legal == [:built, :initialized, :stopped]   # §12.6's stopped-sim row
        # (`replay!` from `:running` is the same gate one line above it, and reaching
        # it needs the spawned-run idiom `test_lifecycle.jl` exercises for `init!`
        # and `run!`; it is asserted there, for those two entries, and not here.)
    end

    @testset "a replay runs under the kill switch, and records nothing (§11.5, §12.7)" begin
        (sim, trc) = recorded_run()
        off = replay_twin(; trace = false)
        replay!(off, trc; trace = false)       # the replay's own run takes the switch (D-261); the feed
        @test lifecycle(off) === :initialized   # is compiled from the `Trace` in hand, never the target's
        @test same_trajectory(logged(off), logged(sim))
        @test off.run.trace === nothing        # the switch rides on the run (D-260)
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} trace(off))
        @test d.reason === :disabled
    end
end

# --- checkpoints and the restoring doors (§12.6, §12.7, D-274) ------------------
# `checkpoint` takes the executor's state at a frame top, `restore!` puts it back
# as a door, and replay is a restore plus the feed — which is what makes a seek.

# A session over `replay_model()` out to t = 1.0, staged across frames: batches
# at 1, 4 and 8.
function long_recorded_run()
    sim = Simulation(replay_model(); h = 1//10)
    init!(sim, fragment(u = (ref = 1.0, rate = 0.0)))
    stage!(sim, "ref" => 2.0)
    step!(sim; frames = 3)
    stage!(sim, "rate" => 1.0)
    step!(sim; frames = 4)
    stage!(sim, "ref" => 3.0)
    step!(sim; frames = 3)
    (sim, trace(sim))
end

# The pendulum with a third continuous state, its ports unchanged, and with its
# two ports declared in the other order: each agrees with `Pendulum` on every
# path, cell size and store type, and a restore that copies by position has to
# refuse it all the same.
struct ClockedPendulum <: AbstractComponent end
x_init(::ClockedPendulum) = (θ = 0.0, ω = 0.0, e = 0.0)
u_types(::ClockedPendulum) = (u = Float64,)
y_types(::ClockedPendulum) = (θ = Float64, ω = Float64)
y_state(::ClockedPendulum, (; x)) = (θ = x.θ, ω = x.ω)
x_deriv(::ClockedPendulum, (; x, u)) =
    (θ = x.ω, ω = -9.81 * sin(x.θ) - 0.5 * x.ω + u.u, e = 1.0)

struct SwappedPendulum <: AbstractComponent end
x_init(::SwappedPendulum) = (θ = 0.0, ω = 0.0)
u_types(::SwappedPendulum) = (u = Float64,)
y_types(::SwappedPendulum) = (ω = Float64, θ = Float64)
y_state(::SwappedPendulum, (; x)) = (ω = x.ω, θ = x.θ)
x_deriv(::SwappedPendulum, (; x, u)) = (θ = x.ω, ω = -9.81 * sin(x.θ) - 0.5 * x.ω + u.u)

# The pendulum with its two states declared in the other order, its ports
# unchanged: the same block width, each position holding the other state.
struct ReorderedPendulum <: AbstractComponent end
x_init(::ReorderedPendulum) = (ω = 0.0, θ = 0.0)
u_types(::ReorderedPendulum) = (u = Float64,)
y_types(::ReorderedPendulum) = (θ = Float64, ω = Float64)
y_state(::ReorderedPendulum, (; x)) = (θ = x.θ, ω = x.ω)
x_deriv(::ReorderedPendulum, (; x, u)) =
    (ω = -9.81 * sin(x.θ) - 0.5 * x.ω + u.u, θ = x.ω)

# A ramp `q̇ = 1` counting its firings in `n`, declaring the guards `names` in
# that order: `low` holds from q = 0.25 on, `high` never within a test. Every
# other declaration is shared, so two ramps agree on everything the fingerprint
# holds but the events.
struct GuardedRamp{names} <: AbstractComponent end
x_init(::GuardedRamp) = (q = 0.0,)
m_init(::GuardedRamp) = (n = 0,)
y_types(::GuardedRamp) = (q = Float64, n = Int)
y_state(::GuardedRamp, (; x, m)) = (q = x.q, n = m.n)
x_deriv(::GuardedRamp, (; x)) = (q = one(x.q),)
ramp_low(::GuardedRamp, (; x)) = x.q ≥ 0.25
ramp_high(::GuardedRamp, (; x)) = x.q ≥ 10.0
ramp_count(::GuardedRamp, (; m)) = (m = (n = m.n + 1,),)
state_events(::GuardedRamp{names}) where {names} =
    NamedTuple{names}(Tuple(StateEvent(name === :low ? ramp_low : ramp_high, ramp_count)
                            for name in names))

# A tick that raises an `InterruptException` when armed: a synchronous throw from
# a boundary phase, after the frame's integration and before its publication, so
# the frame is abandoned with the clock at its top (§12.4).
struct TickInterrupter <: AbstractComponent end
s_init(::TickInterrupter) = (n = 0,)
u_types(::TickInterrupter) = (arm = Bool,)
y_types(::TickInterrupter) = (n = Int,)
y_state(::TickInterrupter, (; s)) = (n = s.n,)
s_update(::TickInterrupter, (; s, u)) = u.arm ? throw(InterruptException()) : (n = s.n + 1,)

# A refused call writes nothing: the simulation against a checkpoint taken
# before it, field by field.
function assert_unwritten(sim, before::Checkpoint)
    after = checkpoint(sim)
    @test after.state.x == before.state.x && after.state.s == before.state.s && after.state.m == before.state.m
    @test after.state.prior == before.state.prior && sim.model.exec.events.last == before.state.prior
    @test same_table(after.state.table, before.state.table)
    @test (after.state.t, after.frame, after.boundary, after.state.t₀) ==
          (before.state.t, before.frame, before.boundary, before.state.t₀)
end

function trace_checkpoints()
    @testset "`restore!` is a door: a fresh run from the checkpoint, one snapshot (§12.6, D-274)" begin
        (sim, _) = recorded_run()
        cp = checkpoint(sim)
        @test cp isa Checkpoint
        @test cp.frame == 8 && cp.boundary == sim.run.boundary == latest(sim).boundary + 1

        twin = replay_twin()                       # another state, another run
        stage!(twin, "ref" => 99.0)                # staged before the door: dropped by it
        old_run = twin.run
        restore!(twin, cp)
        @test lifecycle(twin) === :initialized && mode(twin) === :live
        @test termination(twin) === nothing
        @test twin.run !== old_run && twin.run.log !== old_run.log &&
              twin.run.trace !== old_run.trace

        # the trace's header is the checkpoint restored, field by field and detached
        header = trace(twin).header
        @test header !== cp && header.state.x !== cp.state.x && header.state.x == cp.state.x
        @test header.state.s == cp.state.s && header.state.m == cp.state.m && header.state.prior == cp.state.prior
        @test same_table(header.state.table, cp.state.table)
        @test (header.state.t, header.frame, header.boundary, header.state.t₀) ==
              (cp.state.t, cp.frame, cp.boundary, cp.state.t₀)
        @test header.state.deployment == cp.state.deployment && header.state.layout === cp.state.layout
        # its records are keyed by the trajectory's own frames
        @test trace(twin).frames == cp.frame && isempty(trace(twin).batches)

        # One snapshot, at the checkpoint's `t`, re-publishing the checkpoint's
        # boundary under its own ordinal: the clock reads `cp.boundary` after it.
        @test length(logged(twin)) == 1
        @test latest(twin).t === cp.state.t && latest(twin).frame == cp.frame
        @test latest(twin).boundary == cp.boundary - 1 == latest(sim).boundary
        @test snap_cells(latest(twin)) == snap_cells(latest(sim))
        @test twin.run.boundary == cp.boundary && twin.run.frame == cp.frame
        @test state(twin, "plant").q === state(sim, "plant").q
        @test state(twin, "acc") === state(sim, "acc") && modes(twin, "b") === modes(sim, "b")

        # The staged batch is gone, and the next frame is the original's next frame.
        @test step!(twin) == 1 && step!(sim) == 1
        @test port(twin, "", :ref) == 2.0
        @test snap_cells(latest(twin)) == snap_cells(latest(sim))
        @test latest(twin).boundary == latest(sim).boundary

        # `run!` is legal from the door, and the restored run's trace replays: its
        # header is restored and its records apply at their own frames.
        run!(twin; t_end = 1.4)
        @test lifecycle(twin) === :stopped
        third = Simulation(replay_model(); h = 1//10)
        replay!(third, trace(twin))
        @test same_trajectory(logged(third), logged(twin))
        @test [x.boundary for x in logged(third)] == [x.boundary for x in logged(twin)]

        # Under the door's kill switch the run has no trace at all (§11.5, D-261).
        untraced = Simulation(replay_model(); h = 1//10)
        restore!(untraced, cp; trace = false)
        @test untraced.run.trace === nothing && lifecycle(untraced) === :initialized
    end

    @testset "the refusals of `checkpoint` and `restore!` (§12.6, D-274)" begin
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} checkpoint(
            Simulation(replay_model(); h = 1//10)))
        @test d.op === :checkpoint && d.status === :built && d.legal == [:initialized, :stopped]

        crashed = Simulation(fed(Exploder(), "arm"); h = 1//10)
        init!(crashed, fragment(u = (in = 0.0,)))
        before = checkpoint(crashed)
        stage!(crashed, "in" => true)
        @test_throws StepError run!(crashed; t_end = 5.0)
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} checkpoint(crashed))
        @test d.op === :checkpoint && d.status === :errored
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} restore!(crashed, before))
        @test d.op === :restore! && d.status === :errored

        # `running` is the §11.3 freeze, reached with `test_lifecycle.jl`'s idiom:
        # both ends of the run are test-controlled.
        spinning = Simulation(armed(); h = 1//100)
        init!(spinning, fragment(u = (in = 0.0,)))
        attach!(spinning, TailProbe(), NoClaim())
        task = Threads.@spawn run!(spinning; t_end = 3.0e5)
        while lifecycle(spinning) !== :running && !istaskdone(task)
            yield()
        end
        running_checkpoint = carried(@test_throws DiagnosticError{ServiceLifecycle} checkpoint(spinning))
        stage!(spinning, "in" => 1.0)
        wait(task)
        @test running_checkpoint.op === :checkpoint && running_checkpoint.status === :running

        # A `t*` stop leaves the clock inside the frame, short of its top: refused,
        # with the clock, the top and the frame index. A stop at a frame top is not.
        sim = Simulation(overloaded(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 5.0)
        @test lifecycle(sim) === :stopped
        d = carried(@test_throws DiagnosticError{CheckpointMidFrame} checkpoint(sim))
        @test d.t ≈ 0.315 atol = 1e-6
        @test d.t_frame == 0.4 && d.frame == 4
        at_top = Simulation(overloaded(); h = 1//10)
        init!(at_top)
        run!(at_top; t_end = 0.3)
        @test lifecycle(at_top) === :stopped && checkpoint(at_top).frame == 3

        # An interrupt from model code abandons its frame unpublished and ends the
        # run `stopped`. Thrown from a boundary phase it leaves the clock at the
        # frame top, the stores possibly mid-boundary: refused all the same, and
        # `linearize`'s default form with it. Thrown mid-integration it leaves the
        # clock inside the frame.
        for (model, at_frame_top) in ((fed(TickInterrupter(), "arm"), true),
                                      (fed(Interrupter(), "arm"), false))
            abandoned = Simulation(model; h = 1//10)
            init!(abandoned, fragment(u = (in = false,)))
            step!(abandoned; frames = 2)
            stage!(abandoned, "in" => true)
            run!(abandoned; t_end = 5.0)
            @test lifecycle(abandoned) === :stopped
            @test termination(abandoned).source === ControlRequestedStop(:interrupt)
            @test abandoned.run.frame == 3 && latest(abandoned).frame == 2
            @test (abandoned.model.exec.clock.t == 3 * 0.1) == at_frame_top    # frame 3's top
            d = carried(@test_throws DiagnosticError{CheckpointMidFrame} checkpoint(abandoned))
            @test d.frame == 3 && d.t_frame == 3 * 0.1
            @test d.t == abandoned.model.exec.clock.t
            d = carried(@test_throws DiagnosticError{CheckpointMidFrame} linearize(abandoned, taps()))
            @test d.frame == 3 && d.t == abandoned.model.exec.clock.t
        end

        # A frame top is the time the loop writes there, at any origin: near zero,
        # where `t` has few ulps to spare, and far from it.
        for (t0, frames) in ((-0.3, 3), (-0.30000000000000004, 3), (1.0e9, 5))
            anchored = Simulation(fed(Plant(), "u"); h = 1//10)
            init!(anchored, fragment(u = (in = 0.0,)); t0 = t0)
            step!(anchored; frames = frames)
            @test checkpoint(anchored).frame == frames
        end
        anchored = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(anchored, fragment(u = (in = 0.0,)); t0 = -0.3)
        run!(anchored; t_end = 0.0)
        @test lifecycle(anchored) === :stopped && checkpoint(anchored).frame == 3

        # Another deployment is a fingerprint mismatch, collected before any write.
        (recorded, _) = recorded_run()
        cp = checkpoint(recorded)
        fine = Simulation(replay_model(); h = 1//20)
        err = failure(() -> restore!(fine, cp))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        d = only(x for x in diagnostics(err) if x.name === :h)
        @test d.what === :deployment && d.expected === 0.1 && d.found === 0.05
        @test lifecycle(fine) === :built

        # A state taken on a model at another scalar is refused by dispatch, with
        # the same kind, by a simulation and by a model (D-317, D-319).
        dual_model = Model(replay_model(), D8; h = 1//10)
        init!(dual_model, fragment(u = (ref = 1.0, rate = 0.0)))
        dual_state = checkpoint(dual_model)
        d = carried(@test_throws DiagnosticError{CheckpointMismatch} restore!(
            Simulation(replay_model(); h = 1//10), dual_state))
        @test d.what === :scalar && d.expected === D8 && d.found === Float64
        d = carried(@test_throws DiagnosticError{CheckpointMismatch} restore!(
            Model(replay_model(); h = 1//10), dual_state))
        @test d.what === :scalar && d.expected === D8 && d.found === Float64

        # The recording keywords are the door's own, validated under its name.
        d = only(diagnostics(failure(() -> restore!(Simulation(replay_model(); h = 1//10), cp;
                                                    log_every = 0))))
        @test d isa ArgumentInvalid && d.call === :restore!
        @test d.argument === :log_every && d.value == 0
    end

    @testset "a seek: `restore!` then the feed from the next frame (§12.7, D-274)" begin
        (sim, trc) = long_recorded_run()
        # the checkpoint at 0.5, from a second run of the recording halted there
        halted = replay_twin()
        replay!(halted, trc; to_boundary = 5)
        cp = checkpoint(halted)
        @test cp.frame == 5

        seeker = Simulation(replay_model(); h = 1//10)
        restore!(seeker, cp)
        replay!(seeker, trc; restore = false)
        @test lifecycle(seeker) === :initialized && mode(seeker) === :live
        @test seeker.run.frame == trc.frames
        # bitwise the original from 0.5, ordinals included
        from_seek = [x for x in logged(sim) if x.boundary ≥ cp.boundary - 1]
        @test same_trajectory(logged(seeker), from_seek)
        @test [x.boundary for x in logged(seeker)] == [x.boundary for x in from_seek]
        @test state(seeker, "plant").q === state(sim, "plant").q
        @test state(seeker, "acc") === state(sim, "acc")
        # the re-recorded trace holds the records from frame 6 on
        @test trace(seeker).batches == [b for b in trc.batches if b.frame > 5]
    end

    @testset "a halt before the feed's first frame is refused (§12.7, D-274)" begin
        (_, trc) = long_recorded_run()
        halted = replay_twin()
        replay!(halted, trc; to_boundary = 5)
        cp = checkpoint(halted)
        opened = Simulation(replay_model(); h = 1//10)
        restore!(opened, cp)
        step!(opened; frames = 3)
        late = trace(opened)
        @test late.header.frame == 5 && late.frames == 8

        # The trace opens at frame 5, so a halt short of it names a frame the
        # replay never stands at, by either spelling, refused before any write.
        for (argument, bad) in ((:to_boundary, 0), (:to_boundary, 4), (:to_time, 0.2),
                                (:to_time, 0.45))
            target = Simulation(replay_model(); h = 1//10)
            d = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(target, late; argument => bad))
            @test d.call === :replay! && d.reason === :range
            @test d.argument === argument && d.value === bad
            @test lifecycle(target) === :built
        end
        # …and the frame itself halts at once, where the restore left it.
        for halt in ((to_boundary = 5,), (to_time = 0.5,))
            target = Simulation(replay_model(); h = 1//10)
            replay!(target, late; halt...)
            @test lifecycle(target) === :initialized && target.run.frame == 5
            @test mode(target) === :replay
        end

        # Under `restore = false` the feed starts from the simulation's own frame.
        ahead = Simulation(replay_model(); h = 1//10)
        restore!(ahead, cp)
        step!(ahead)
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(ahead, trc; restore = false, to_boundary = 5))
        @test d.argument === :to_boundary && d.value == 5
        @test lifecycle(ahead) === :initialized && ahead.run.frame == 6 &&
              mode(ahead) === :live
        replay!(ahead, trc; restore = false, to_boundary = 6)
        @test ahead.run.frame == 6 && mode(ahead) === :replay
    end

    @testset "the fingerprint covers what the restore copies by position (§12.6, §12.7, D-274)" begin
        source = Simulation(fed(Pendulum(), "u"); h = 1//10)
        init!(source, combine(at("c", condition(Pendulum(); θ = 0.3)),
                              fragment(u = (in = 0.0,))))
        step!(source; frames = 2)
        cp = checkpoint(source)

        # One continuous state more: the component's `x` type, which fixes its
        # block in the flat buffer, and the refusal names it before any write,
        # at both doors.
        pendulum_x = @NamedTuple{θ::Float64, ω::Float64}
        clocked_x = @NamedTuple{θ::Float64, ω::Float64, e::Float64}
        wider = Simulation(fed(ClockedPendulum(), "u"); h = 1//10)
        init!(wider, fragment(u = (in = 0.0,)))
        d = only(diagnostics(failure(() -> restore!(wider, cp))))
        @test d isa CheckpointMismatch && d.what === :store
        @test d.path == "c" && d.name === :x && d.expected === pendulum_x && d.found === clocked_x
        @test wider.model.exec.xbuf == [0.0, 0.0, 0.0] && wider.run.frame == 0
        replayed = Simulation(fed(ClockedPendulum(), "u"); h = 1//10)
        d = only(diagnostics(failure(() -> replay!(replayed, trace(source)))))
        @test d isa CheckpointMismatch && d.name === :x && lifecycle(replayed) === :built
        # …and one fewer is the same refusal, never a copy out of bounds
        d = only(diagnostics(failure(() -> restore!(source, checkpoint(wider)))))
        @test d isa CheckpointMismatch && d.name === :x
        @test d.expected === clocked_x && d.found === pendulum_x
        @test source.run.frame == 2

        # The same width with the states in the other order: each position would
        # take the other state, so the type is compared, not the width.
        reordered = Simulation(fed(ReorderedPendulum(), "u"); h = 1//10)
        init!(reordered, fragment(u = (in = 0.0,)))
        before = checkpoint(reordered)
        d = only(diagnostics(failure(() -> restore!(reordered, cp))))
        @test d isa CheckpointMismatch && d.what === :store && d.path == "c" && d.name === :x
        @test d.expected === pendulum_x && d.found === @NamedTuple{ω::Float64, θ::Float64}
        assert_unwritten(reordered, before)
        d = only(diagnostics(failure(() -> replay!(reordered, trace(source)))))
        @test d isa CheckpointMismatch && d.name === :x
        assert_unwritten(reordered, before)

        # The same ports in another order: every cell has its type, not its place.
        swapped = Simulation(fed(SwappedPendulum(), "u"); h = 1//10)
        init!(swapped, fragment(u = (in = 0.0,)))
        err = failure(() -> restore!(swapped, cp))
        @test err isa DiagnosticError &&
              all(d -> d isa CheckpointMismatch && d.what === :store && d.path == "c",
                  diagnostics(err))
        @test [d.name for d in diagnostics(err)] == [Symbol("port.θ"), Symbol("port.ω")]
        @test diagnostics(err)[1].expected == (Float64, (0,)) &&
              diagnostics(err)[1].found == (Float64, (1,))
        @test swapped.run.frame == 0 && lifecycle(swapped) === :initialized

        # Other ports altogether, one leaf wider: the cells that differ are named,
        # and the root input they shift is not reported, having kept its type.
        err = failure(() -> restore!(Simulation(fed(VectorPlant(), "u"); h = 1//10), cp))
        ports = [d.name for d in diagnostics(err)
                 if d isa CheckpointMismatch && startswith(String(d.name), "port.")]
        @test ports == [Symbol("port.power"), Symbol("port.q"), Symbol("port.θ"), Symbol("port.ω")]
        d = only(d for d in diagnostics(err) if d.name === Symbol("port.q"))
        @test d.path == "c" && d.expected === nothing && d.found == (SVector{2,Float64}, (0,))
    end

    @testset "the fingerprint covers the guards: the priors are copied by position (§12.6, D-274)" begin
        # Five frames in, `low` has fired at frame 3 and holds: its prior is set.
        ramp(names) =
            (sim = Simulation(single(GuardedRamp{names}()); h = 1//10);
             init!(sim); step!(sim; frames = 5); sim)
        low_high = ramp((:low, :high))
        cp = checkpoint(low_high)
        @test cp.state.prior == [true, false]
        @test cp.state.layout.events == [("c", :low), ("c", :high)]

        # A guard more, a guard fewer, the same guards in the other order: each
        # refused before any write, never a stale prior, a `BoundsError` or a
        # holding guard firing again.
        for (names, found) in (((:low,), [("c", :low)]),
                               ((:high, :low), [("c", :high), ("c", :low)]))
            target = ramp(names)
            before = checkpoint(target)
            d = only(diagnostics(failure(() -> restore!(target, cp))))
            @test d isa CheckpointMismatch && d.what === :store && d.name === :events
            @test d.path == "" && d.expected == cp.state.layout.events && d.found == found
            assert_unwritten(target, before)
        end
        target = ramp((:low, :high))
        low_only = checkpoint(ramp((:low,)))
        before = checkpoint(target)
        d = only(diagnostics(failure(() -> restore!(target, low_only))))
        @test d.name === :events && d.expected == [("c", :low)] && d.found == cp.state.layout.events
        assert_unwritten(target, before)
        # …at replay's entry pass too
        target = ramp((:high, :low))
        before = checkpoint(target)
        d = only(diagnostics(failure(() -> replay!(target, trace(low_high)))))
        @test d isa CheckpointMismatch && d.name === :events
        assert_unwritten(target, before)

        # Off the nominal activation the events compile out, so the list is
        # empty, and a `Dual` model's state goes back into its twin (D-317, D-319).
        dual = Model(single(GuardedRamp{(:low, :high)}()), D8; h = 1//10)
        init!(dual); frames!(dual, 5)
        dual_state = checkpoint(dual)
        @test isempty(dual_state.layout.events) && isempty(dual_state.prior)
        # The restore is a model door: a twin never initialized leaves it
        # consistent.
        twin = Model(single(GuardedRamp{(:low, :high)}()), D8; h = 1//10)
        @test twin.status === :built
        restore!(twin, dual_state)
        @test twin.status === :consistent
        @test state(twin, "c") == state(dual, "c")
        # The executor's method is typed by scalar, so a `D8` state never
        # enters a `Float64` executor.
        @test_throws MethodError _restore_state!(low_high.model.exec, dual_state)
    end

    @testset "`checkpoint` and `restore!` on a model: the state alone, and a standalone state entering a simulation (§12.6, D-319)" begin
        initial_condition = fragment(u = (ref = 1.0, rate = 0.0))
        model = Model(replay_model(); h = 1//10)
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} checkpoint(model))
        @test d.op === :checkpoint && d.status === :built && d.legal == [:consistent]
        init!(model, initial_condition)
        frames!(model, 3)
        model_state = checkpoint(model)
        @test model_state isa ModelState{Float64}
        @test model_state.t === 0.0 + 3 * 0.1 && model_state.t₀ === 0.0   # the indexed top

        # The state opens a fresh trajectory at its own frame: the restored
        # boundary under boundary zero's ordinal, the run's counter one past it.
        sim = Simulation(replay_model(); h = 1//10)
        restore!(sim, model_state)
        @test lifecycle(sim) === :initialized && mode(sim) === :live
        @test sim.run.frame == 3 && sim.run.boundary == 1
        @test latest(sim).frame == 3 && latest(sim).boundary == 0
        @test latest(sim).t === model_state.t && trace(sim).frames == 3
        @test state(sim, "plant") === state(model, "plant")

        # It goes on as the trajectory `init!` opens under the same condition.
        reference = Simulation(replay_model(); h = 1//10)
        init!(reference, initial_condition)
        run!(sim; t_end = 0.6)
        run!(reference; t_end = 0.6)
        for path in ("plant", "ctl", "sum", "acc", "b")
            @test state(sim, path) === state(reference, path)
        end
        @test snap_cells(latest(sim)) == snap_cells(latest(reference))

        # A state from another deployment is refused before any write.
        before = checkpoint(sim)
        fine = Model(replay_model(); h = 1//20)
        init!(fine, initial_condition)
        err = failure(() -> restore!(sim, checkpoint(fine)))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        @test lifecycle(sim) === :stopped
        assert_unwritten(sim, before)
        # …and by a model, which stays as it was.
        twin = Model(replay_model(); h = 1//10)
        err = failure(() -> restore!(twin, checkpoint(fine)))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        @test twin.status === :built

        # A state off the grid is refused at the frame `round` places it in.
        off_grid = ModelState(model_state.x, model_state.s, model_state.m, model_state.table,
                              model_state.prior, 0.25, model_state.t₀,
                              model_state.deployment, model_state.layout)
        d = carried(@test_throws DiagnosticError{CheckpointMidFrame} restore!(sim, off_grid))
        @test d.frame == round(Int, 0.25 / 0.1) == 2
        @test d.t === 0.25 && d.t_frame === 0.0 + 2 * 0.1
        @test lifecycle(sim) === :stopped
        assert_unwritten(sim, before)
    end

    @testset "`restore = false` feeds on the recording's clock (§12.7, D-274)" begin
        (_, trc) = recorded_run()        # t₀ = 0, eight frames

        # Another origin: the records' frames would name other times.
        shifted = replay_twin(; t0 = 0.05)
        before, old_run = checkpoint(shifted), shifted.run
        d = only(diagnostics(failure(() -> replay!(shifted, trc; restore = false))))
        @test d isa CheckpointMismatch && d.what === :clock && d.name === :t₀
        @test d.expected === 0.0 && d.found === 0.05
        assert_unwritten(shifted, before)
        @test shifted.run === old_run

        # The simulation's frame runs from the header's to one short of the
        # recording's last: before the header the feed would run frames the
        # recording never covered, and at the last nothing is left to feed. A
        # refusal keeps the run and its log. The trace below opens at frame 5
        # and ends at 8.
        (_, long_trc) = long_recorded_run()
        halted = replay_twin()
        replay!(halted, long_trc; to_boundary = 5)
        opened = Simulation(replay_model(); h = 1//10)
        restore!(opened, checkpoint(halted))
        step!(opened; frames = 3)
        late = trace(opened)
        @test late.header.frame == 5 && late.frames == 8
        for frame in (4, 8, 9)
            outside = replay_twin()
            replay!(outside, long_trc; to_boundary = frame)
            before, old_run, old_log = checkpoint(outside), outside.run, logged(outside)
            d = only(diagnostics(failure(() -> replay!(outside, late; restore = false))))
            @test d isa CheckpointMismatch && d.what === :clock && d.name === :frame
            @test d.expected == 5:7 && d.found == frame
            assert_unwritten(outside, before)
            @test outside.run === old_run && logged(outside) == old_log
        end
        for frame in (5, 7)
            inside = replay_twin()
            replay!(inside, long_trc; to_boundary = frame)
            replay!(inside, late; restore = false)
            @test inside.run.frame == 8 && mode(inside) === :live
            @test trace(inside).header.frame == frame
        end

        # The clock's refusal precedes the halt's, which reads the clock: a halt
        # beside a simulation off the recording's clock is refused for the clock.
        shifted = replay_twin(; t0 = 1.0)
        d = only(diagnostics(failure(() -> replay!(shifted, trc; restore = false,
                                                   to_time = 1.5))))
        @test d isa CheckpointMismatch && d.what === :clock && d.name === :t₀
        past = replay_twin()
        replay!(past, long_trc; to_boundary = 9)
        d = only(diagnostics(failure(() -> replay!(past, trc; restore = false,
                                                   to_boundary = 8))))
        @test d isa CheckpointMismatch && d.what === :clock && d.name === :frame
        @test d.expected == 0:7 && d.found == 9

        # Both refusals collect in one pass, with the fingerprint's.
        both = Simulation(replay_model(); h = 1//20)
        init!(both, fragment(u = (ref = 1.0, rate = 0.0)); t0 = 0.05)
        step!(both; frames = 9)
        before = checkpoint(both)
        err = failure(() -> replay!(both, trc; restore = false))
        @test err isa DiagnosticError && all(d isa CheckpointMismatch for d in diagnostics(err))
        @test [d.name for d in diagnostics(err) if d.what === :clock] == [:t₀, :frame]
        @test any(d.what === :deployment && d.name === :h for d in diagnostics(err))
        assert_unwritten(both, before)
    end
end

function test_trace()
    trace_recording()
    trace_entry_pass()
    trace_replay_loop()
    trace_discarded_staging()
    trace_discarded_harness()
    trace_checkpoints()
end
