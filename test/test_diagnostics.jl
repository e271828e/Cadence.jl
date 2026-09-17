# --- the diagnostic channel and the framework status (§11.8; increments 13–14) --
# report! from the author's loop body, the per-writer single-writer cells with
# their ring-plus-counts bound, the frame-top fold beside the staging drain,
# the published status — delta plus totals, heartbeat and task_state — and the
# run's-end sweep. The devices below live at top level for `implementation.md`'s
# local-scope reason.

# A datum-stream parser: the §11.6 tolerance idiom verbatim — catch its own
# parser error, stage nothing for that datum, report, continue with the next.
mutable struct Parser <: AbstractDevice
    datums::Vector{Any}
    fired::Bool
end
Parser(datums...) = Parser(collect(Any, datums), false)
function loop(d::Parser, h)
    d.fired && return nothing
    d.fired = true
    for datum in d.datums
        try
            datum isa Number || throw(ArgumentError("unparseable: $(repr(datum))"))
            stage!(h, "a" => datum)
        catch e
            e isa ArgumentError || rethrow()     # a bug → wrapper → DeviceCrash
            report!(h, MalformedDatum(e))        # garbage → visible, bounded, alive
        end
    end
    stop!(h)
    nothing
end

# A late reporter: its one report races the run's last frame top, so its
# account may land in the terminal status or in the run's-end sweep.
mutable struct LateReporter <: AbstractDevice
    fired::Bool
end
LateReporter() = LateReporter(false)
function loop(d::LateReporter, h)
    d.fired && return nothing
    d.fired = true
    report!(h, MalformedDatum("late"))
    stop!(h)
    nothing
end

# A snapshot consumer that stays in its loop: the liveness testset's device.
mutable struct Ticker <: AbstractDevice
    n::Int
end
Ticker() = Ticker(0)
function loop(d::Ticker, h)
    while running(h)
        wait_next_snapshot(h)
        (d.n += 1) ≥ 3 && return stop!(h)
    end
    nothing
end

function diagnostics_channel()
    @testset "a bad datum is tolerated: catch, stage nothing, report, continue (§11.6)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Parser(0.7, "garbage", 0.9)
        hp = attach!(sim, dev, Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1000.0)                        # ends by the device's stop
        end
        msgs = [string(l.message) for l in logs]
        # The link survived its truncated datagram: no crash, and the report is
        # accounted device-attributed exactly once — in the terminal status when a
        # frame top folded it, in the run's-end sweep when none remained (§11.8).
        @test !any(occursin("DeviceCrash", m) for m in msgs)
        @test accounted(sim, logs, "device 1 (Parser)", :malformed, "MalformedDatum")
        # The author's cause survives wherever the record landed: in some logged
        # snapshot's recent, or in the sweep's presentation.
        carried = any(d isa MalformedDatum && occursin("unparseable", string(d.cause))
                      for s in logged(sim)
                      for d in writer_status(s, "device 1 (Parser)").recent)
        @test carried ⊻ any(occursin("unparseable", m) for m in msgs)
        # The stream's good datums survived — newest wins within the staged batch —
        # applied by a drain the stop did not beat, or still pending in the cell:
        # exactly one of the two, timing's choice.
        p = @atomic hp.writer.cell.pending
        @test (p === nothing ? port(sim, "", :a) : p[].vals[1]) === 0.9
    end

    @testset "the ring's bound is the rate limit: 16 retained, excess to the counts (§11.8)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        h = attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        for k in 1:20                                # one frame's flood, pending in the cell
            report!(h, MalformedDatum("datum $k"))
        end
        run!(sim; t_end = 0.1)                               # the first frame top folds the cell
        mw = writer_status(latest(sim), "device 1 (Pad)")
        # Earliest-in-frame retained: the first occurrences carry the diagnostic
        # content, the excess becomes exactly a per-kind count beside them.
        @test [d.cause for d in mw.recent] == ["datum $k" for k in 1:DIAG_RING]
        @test mw.suppressed.malformed == 4
        # Nothing is lost by not looking: the totals carry the full account.
        @test mw.totals.malformed == 20
    end

    @testset "a quiet publication allocates the capture, the status vector and the snapshot (§11.8, D-241)" begin
        sim = Simulation(two_root_inputs(); h = 1//10, log = false)
        attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        publish!(sim); capture(sim.exec.store)               # warm
        # Nothing scales with diagnostic activity: the store capture's own
        # allocations, the status vector (object and memory), and the snapshot
        # they are frozen into — a fixed shape whatever the roster holds.
        @test @allocations(publish!(sim)) == @allocations(capture(sim.exec.store)) + 3
        @test length(latest(sim).status.writers) == 3
    end

    @testset "the status: the delta rides one snapshot, totals ride every one (§11.8, §11.2)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        h = attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        # Boundary zero's status: the writers in the drain's order — devices in
        # attachment order, the harness writer, the loop — every account zero,
        # and no run task to be alive: device tasks are run-scoped observables.
        st0 = latest(sim).status
        @test [w.who for w in st0.writers] == ["device 1 (Pad)", "harness", "loop"]
        @test all(w.totals == KindCounts() && isempty(w.recent) for w in st0.writers)
        @test writer_status(latest(sim), "device 1 (Pad)").task_state === :none
        # The harness's and the loop's records have no task and no heartbeat to
        # judge: never stale, `nothing` for both fields.
        @test writer_status(latest(sim), "loop").heartbeat === nothing
        @test !stale(writer_status(latest(sim), "harness"))
        report!(h, MalformedDatum("one"))            # pending before the run: folded at frame 1's top
        run!(sim; t_end = 0.5)
        snaps = logged(sim)                          # boundary zero, then frames 1..5
        dw(s) = writer_status(s, "device 1 (Pad)")
        # Exactly one snapshot carries the occurrence in `recent` — the first
        # published after the fold — while `totals` is monotone from there on:
        # a 60 Hz reader sees it once, an occasional sampler still reads the
        # complete account, and log decimation loses *which* boundary, never
        # *how many* (§11.8).
        @test [length(dw(s).recent) for s in snaps] == [0, 1, 0, 0, 0, 0]
        @test [dw(s).totals.malformed for s in snaps] == [0, 1, 1, 1, 1, 1]
        @test only(dw(snaps[2]).recent).cause == "one"
    end

    @testset "liveness: heartbeat and task_state ride the device's record (§11.8, §12.2, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Ticker()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 1000.0)                            # ends by the device's stop, ≥ 3 boundaries in
        @test dev.n ≥ 3
        tw = writer_status(latest(sim), "device 1 (Ticker)")
        # The device consumed boundaries through the handle primitives, each pass
        # storing the heartbeat: the terminal record reads fresh, with a live (or
        # by now returned) task — never `:none`, never the stale silence of a
        # device that was never there (§12.2: a starved or dead device shows as a
        # stale heartbeat with a name on it).
        @test tw.heartbeat > 0 && !stale(tw)
        @test tw.task_state in (:running, :done)
    end

    @testset "the run's-end sweep: past the final frame top, loud rather than lost (§11.8, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = LateReporter()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1000.0)
        end
        # The report races the last frame top: folded into the terminal status, or
        # — no drain remaining — presented by the sweep, the tail's renderer of
        # last resort. Exactly one account either way (§11.8, D-201).
        @test accounted(sim, logs, "device 1 (LateReporter)", :malformed, "MalformedDatum")
        # A fresh trajectory opens a fresh account (§11.8): init! resets the
        # totals, and the stepped frames — deviceless, the reporter never respawns —
        # publish a zeroed record for it.
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        step!(sim; frames = 2)
        @test writer_status(latest(sim), "device 1 (LateReporter)").totals.malformed == 0
    end

    @testset "the cell is kind-generic: mixed rings, per-kind suppression (§11.8, §13.2)" begin
        # The closed set rides one union; the counter record is fixed-shape isbits,
        # a type rather than a lookup (§11.8), and + is the fold between records.
        @test isbitstype(KindCounts)
        a = _bump(_bump(KindCounts(), :malformed), :crash)
        b = _bump(KindCounts(), :malformed)
        @test (a + b).malformed == 2 && (a + b).crash == 1
        @test _total(a + b) == 3

        # A raw cell takes any kind of the set; the ring preserves arrival order
        # across kinds, earliest-in-frame retained.
        cell = DiagCell(EMPTY_DIAG)
        _report!(cell, MalformedDatum("m1"))
        _report!(cell, OutOfClaimEntry(:flaps, 1.0, [:a, :b], nothing))
        _report!(cell, ClaimedFaceEntry(:a, "device 1 (Pad)", 2.0, :staging))
        _report!(cell, EntryTypeMismatch(:b, "high", Float64))
        _report!(cell, ChatteringBudget("c", :pop, 0.1, 8, 8))
        _report!(cell, FiringBudget("e", :up, 0.0, 4, 4))
        _report!(cell, DeviceCrash(ErrorException("boom"), false))
        _report!(cell, DeviceJoinTimeout("device 9 (Ghost)", 5.0, 1.0, 10))
        batch = _take!(cell)
        @test length(batch.ring) == 8
        @test batch.ring[1] isa MalformedDatum && batch.ring[8] isa DeviceJoinTimeout
        @test batch.suppressed == KindCounts()

        # Past the bound, suppression counts by kind: the record answers "how many
        # of what", not one blurred integer.
        for k in 1:DIAG_RING
            _report!(cell, MalformedDatum("datum $k"))
        end
        _report!(cell, MalformedDatum("late m"))
        _report!(cell, DeviceCrash(ErrorException("late c"), true))
        _report!(cell, DeviceCrash(ErrorException("later c"), true))
        batch = _take!(cell)
        @test length(batch.ring) == DIAG_RING
        @test all(d isa MalformedDatum for d in batch.ring)
        @test batch.suppressed.malformed == 1 && batch.suppressed.crash == 2
        @test _total(batch.suppressed) == 3
        # The take re-arms the sentinel: the next report allocates afresh on the
        # writer's side, and the drained batch is frozen.
        @test _take!(cell) === EMPTY_DIAG
    end

    @testset "the heartbeat rides in the cell, stored by the handle primitives (§11.8, §12.2)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        h = attach!(sim, Pad("p"), Enumerated("a"))
        # A never-heartbeated cell reads its initial 0.0 — stale against any wall
        # clock, which is what marks a failed init!'s device with no machinery
        # (§12.4): dead is "no recent timestamp", recorded nowhere else.
        @test _heartbeat(h.diag) == 0.0
        before = time()
        running(h)                            # any loop-pass primitive beats —
        hb = _heartbeat(h.diag)               # (false here: no run has started)
        @test hb ≥ before
        stage!(h, "a" => 1.0)                 # and so does each of the others
        @test _heartbeat(h.diag) ≥ hb
    end
end

# --- the kind set and its carrier (§13.1, §13.2, Appendix C; increment 22) ------
# One plausible occurrence per kind, so the constructors, `severity`, `path` and
# `message` are exercised for every one of them, and the severity column of
# Appendix C is checked against the listed warning set rather than trusted.

using InteractiveUtils: subtypes    # the coverage check below

function diagnostics_kind_set()
    @testset "diagnostic kinds (§13.2, Appendix C, D-214, D-215)" begin
        occurrences = Diagnostic[
            # Stratum A
            UnknownPort(entry = "child_connections at `a`, entry `x => y`", end_ = :destination,
                        path = "a/b", spelling = "b/throtle", port = :throtle,
                        candidates = [:throttle, :mixture]),
            UnknownPort(entry = "input_connections at `a`, entry `:u => ()`", end_ = :connection,
                        path = "a", port = :u),
            UnconnectedInput(path = "a/b", face = :u),
            TwoProducers(path = "a/b", port = :u, incumbent = "a sibling wire",
                         entry = "an interface connection"),
            WireTypeMismatch(path = "a/b", face = :u, declared = Float64, producer_path = "a/c",
                             producer_port = :y, observed = Bool),
            WalkingFaceAtFrozenEntry(path = "a/b", face = :u, producer_path = "a/c",
                                     producer_port = :y, leaf = "p[1]", declared = Float64,
                                     observed = Marker),
            AbstractAtRoot(face = :in, paths = ["a"], declared = Any[AbstractComponent]),
            RootInputTypeConflict(face = :in, paths = ["a", "b"], declared = Any[Float64, Bool]),
            PathResolution(entry = "`resolve` on `Group`", spelling = "a/b/c",
                           reason = :not_a_terminal),
            PathResolution(entry = "`resolve` on `Group`", spelling = "z/y", reason = :unknown_child,
                           owner = "`a`", segment = "z", candidates = ["b", "c"]),
            PathResolution(entry = "`resolve` on `Group`", spelling = "a/b/c",
                           reason = :reaches_past, level = "a/b", segment = "b", tail = 1),
            PathResolution(entry = "at(\"a/b\")", spelling = "a/b", reason = :past_generic,
                           owner = "the root component", segment = "a", level = "a",
                           declared = TypeVar(:L, AbstractComponent)),
            PathResolution(entry = "`resolve` on `Group`", spelling = "", reason = :empty_path),
            StoreWithoutUpdate(path = "a/b", store = :init_x),
            EventHalfMissing(path = "a/b", event = :snap, reason = :guard, found = Int),
            EventHalfMissing(path = "a/b", event = :snap, reason = :not_an_event, found = Int),
            DeclarationShadowed(path = "a/b", mod = "Main.MyModel",
                                names = [:init_x, :output_types]),
            ClassUnreadable(path = "a", families = "`init_x`, `init_s`", holds_components = true),
            ClassMixed(path = "a", declarations = [:init_x, :output_types]),
            ContainerMixed(path = "a", field = :kids, types = Any[Int, Float64]),
            ContainerNested(path = "a", field = :kids, keys = Any[1, :b],
                            types = Any[Tuple{Int}, @NamedTuple{c::Int}]),
            DeclarationOnWrongTier(path = "a/b", declaration = :init_workspace, reason = :tier_form,
                                   found = :continuous, announced = :discrete),
            DeclarationOnWrongTier(path = "a/b", declaration = :state_projection, reason = :continuous_only,
                                   found = :discrete),
            DeclarationOnWrongTier(path = "a/b", declaration = :state_projection, reason = :no_manifold),
            TierSignatureMismatch(path = "a/b", declaration = :output_types, tier = :continuous,
                                  reason = :bound, found = AbstractFloat),
            FaceNameIllegal(path = "a", face = "u/v", invariant = :contains_slash),
            FaceNameCollision(path = "a", faces = ["u"], site = :assembly),
            FaceNameCollision(path = "", faces = ["u"], site = :root),
            FaceDirectionConflict(entry = "child_connections at `a`", path = "a/b",
                                  spelling = "b/u", found = :input, wanted = :producer),
            UnknownFaceSelection(who = "input_passthrough", path = "a/b", reason = :both_given),
            UnknownFaceSelection(who = "input_passthrough", path = "a/b",
                                 reason = :unknown_names, names = ["q"], candidates = ["u", "v"]),
            RatesViolation(path = "a", reason = :declaration_shape),
            RatesViolation(path = "a", reason = :value_vocabulary, key = :b, value = 3),
            RatesViolation(path = "a", reason = :multiplier, key = :b, value = 0),
            RatesViolation(path = "a", reason = :phase, key = :b, value = 5),
            RatesViolation(path = "a", reason = :period, key = :b, value = 0//1),
            RatesViolation(path = "a", reason = :offset, key = :b, value = 3//1),
            RatesViolation(path = "a", reason = :unknown_child, key = :z, candidates = ["b"]),
            RatesViolation(path = "a", reason = :continuous_child, key = :b),
            MissingProbeValue(face = :in, declared = Float64),
            ChildNameCollision(path = "a", name = "b", reason = :sample_times_sugar,
                               provenance = ["container field `kids`, element `b`"], field = :kids),
            ChildNameCollision(path = "a", name = "b", reason = :sibling_field,
                               provenance = ["container field `kids`, element `b`"], field = :kids),
            ChildNameCollision(path = "a", name = "b", reason = :two_children,
                               provenance = ["field `b`", "container field `kids`, element `b`"]),
            TransparentContainerUnknown(path = "a", field = :kids, component = "Group"),
            TierUnreadable(path = "a/b", declarations = [:init_m]),
            IllegalPortType(path = "a/b", site = :port, name = :y, declared = Nothing),
            IllegalPortType(path = "a/b", site = :port, name = :y, declared = Vector{Float64},
                            reason = :mutable, position = ""),
            IllegalPortType(path = "a/b", site = :port, name = :y, declared = Float64,
                            reason = :mutable, position = "p.z"),
            IllegalPortType(path = "", site = :root_input, name = :terrain, declared = Nothing,
                            reason = :handle_at_root),
            StoreNotNamedTuple(path = "a/b", store = :init_x, declared = Float64),
            IllegalStoreField(path = "a/b", store = :init_s, name = :label, declared = String),
            IllegalStateLeaf(path = "a/b", name = :gear_count, declared = Int, reason = :mode_value),
            IllegalStateLeaf(path = "a/b", name = :q, declared = Float32, reason = :eltype),
            IllegalStateLeaf(path = "a/b", name = :pose, declared = NamedTuple, reason = :nested),
            IllegalStateLeaf(path = "a/b", name = :q_nb, declared = Symbol, reason = :wrapper),
            # Strata B and C
            AlgebraicCycle(members = ["a/b", "a/c"],
                           wires = ["a/b/y" => "a/c/u", "a/c/y" => "a/b/u"]),
            AlgebraicCycle(members = ["a/b", "a/c"],
                           wires = ["a/b/y" => "a/c/u", "a/c/y" => "a/b/u"],
                           classification = :artificial, dead = [("a/c", :u, :y)],
                           traced = ["a/b" => :global, "a/c" => :sampled]),
            AlgebraicCycle(members = ["a/b", "a/c"],
                           wires = ["a/b/y" => "a/c/u", "a/c/y" => "a/b/u"],
                           classification = :real,
                           traced = ["a/b" => :structural, "a/c" => :structural]),
            ProducedByTwoStages(path = "a/b", ports = [:y]),
            DeclaredNotProduced(path = "a/b", ports = [:y], products = [:z],
                                state_fields = [:q]),
            UndeclaredReturnField(path = "a/b", stage = "output_state", name = :q, candidates = [:y]),
            DeadStage(path = "a/b", stage = "output_state"),
            ConformanceFailure(path = "a/b", what = "output_state", reason = :return_type, shape = :ports,
                               observed = Int),
            ConformanceFailure(path = "a/b", what = "state_projection", reason = :field_set, shape = :state,
                               observed_fields = [:p], declared_fields = [:q]),
            ConformanceFailure(path = "a/b", what = "state_derivative", reason = :field_type, shape = :init_x,
                               field = :q, observed = Float64, declared = Bool),
            ConformanceFailure(path = "a/b", what = "output_state", reason = :field_type, shape = :ports,
                               field = :y, observed = Int, declared = Float64,
                               activation = Float64),
            ConformanceFailure(path = "a/b", what = "auto-publication", reason = :field_type,
                               shape = :ports, field = :q, observed = D8,
                               declared = Float64, activation = D8),
            ConformanceFailure(path = "a/b", what = "state_update", reason = :field_set, shape = :init_s,
                               observed = NamedTuple{(:q,),Tuple{Int}},
                               declared = NamedTuple{(:q,),Tuple{Float64}}),
            ConformanceFailure(path = "a/b", what = "event `e`'s handler", reason = :field_set,
                               shape = :mode, field = :k, declared_fields = [:m]),
            GuardForm(path = "a/b", event = :snap, observed = Int),
            HandlerReturnKey(path = "a/b", event = :snap, key = :s, stores = [:x, :m]),
            # Deployment, periphery and services
            MissingInit(op = :run!, status = :built),
            ServiceLifecycle(op = :attach!, status = :running, legal = [:built, :initialized]),
            ServiceLifecycle(op = :capture, status = :errored),
            ServiceLifecycle(op = :run!, status = :stopped),
            ServiceLifecycle(op = :capture, status = :built, legal = [:initialized, :stopped]),
            StopFaceInvalid(face = :done, reason = :unknown, candidates = [:hit]),
            StopFaceInvalid(face = :done, reason = :root_input),
            StopFaceInvalid(face = :done, reason = :not_bool, declared = Float64),
            DeploymentInvalid(parameter = :firing_budget, reason = :range, value = 0),
            DeploymentInvalid(parameter = :h, reason = :inexact, value = 0.01),
            DeploymentInvalid(parameter = :Δt_base, reason = :not_a_quantity, value = Int),
            DeploymentInvalid(parameter = :h, reason = :missing),
            DeploymentInvalid(parameter = :Δt_base, reason = :unanchored, paths = ["a/b"]),
            DeploymentInvalid(parameter = :Δt_base, reason = :no_constraint),
            DeploymentInvalid(parameter = :Δt_base, reason = :not_harmonic, value = 1//3,
                              related = 1//100),
            DeploymentInvalid(parameter = :Δt_base, reason = :disagrees_with_n, value = 1//50,
                              related = 3, quotient = 2),
            DeploymentInvalid(parameter = :Δt_base, reason = :anchor_period, value = 1//30,
                              related = 1//100, provenance = "`sample_times` at `a`, key `b`",
                              admissible = 1//300),
            DeploymentInvalid(parameter = :Δt_base, reason = :anchor_offset, value = 1//7,
                              related = 1//100, provenance = "`sample_times` at `a`, key `b`",
                              admissible = 1//300),
            AttachUnknownFace(binding = "Enumerated", face = :q, candidates = [:a, :b]),
            AlreadyAttached(device = "Pad", incumbent = "device 1 (Pad)", binding = "Enumerated"),
            CallerTaskConflict(device = "Pad", incumbent = "device 1 (Poller)"),
            ClaimConflict(face = :a, device = "Pad", incumbent = "device 1 (Pad)"),
            EmptyGreedyClaim(device = "device 2 (Pad)", binding = "GreedyPlus"),
            BindingContractMismatch(binding = "NoEnum", reason = :claims_missing),
            BindingContractMismatch(binding = "NoEnum", reason = :reads_missing),
            BindingContractMismatch(binding = "NoEnum", reason = :greedy_without_input),
            BindingContractMismatch(binding = "NoEnum", reason = :neither_side),
            BindingContractMismatch(binding = "NoEnum", reason = :greedy_with_claims),
            BindingContractMismatch(binding = "NoEnum", reason = :claims_without_input),
            BindingContractMismatch(binding = "NoEnum", reason = :reads_without_output),
            BindingContractMismatch(binding = "NoEnum", reason = :reads_not_namedtuple,
                                    observed = Int),
            BindingContractMismatch(binding = "NoEnum", reason = :reads_not_selectors,
                                    observed = "1"),
            DeviceContractMismatch(device = "Loopless", reason = :no_loop),
            DeviceContractMismatch(device = "device 1 (Pad)", reason = :no_output_side),
            ReadBindingUnresolved(binding = "T", selector = "get_state(\"a\", :x)",
                                  reason = :store_selector, path = "a", field = :x),
            ReadBindingUnresolved(binding = "T", selector = "get_output(\"a\", :y[1])",
                                  reason = :indexed, path = "a", field = :y),
            ReadBindingUnresolved(binding = "T", selector = "get_output(\"a\", :y)",
                                  reason = :unknown_cell, path = "a", field = :y),
            ReadBindingUnresolved(binding = "T", selector = "get_input(:q)",
                                  reason = :unknown_root_input, field = :q, candidates = [:a]),
            ReadBindingUnresolved(binding = "T", selector = "get_face(:a)",
                                  reason = :root_input_not_output, field = :a),
            ReadBindingUnresolved(binding = "T", selector = "get_face(:q)",
                                  reason = :unknown_output_face, field = :q),
            ConditionResolution(path = "a", field = :u, reason = :assembly_path, provenance = "fragment"),
            ConditionResolution(field = :q, reason = :unexported_face, candidates = [:a],
                                provenance = "fragment"),
            ConditionResolution(path = "a", field = :q, reason = :no_input_face,
                                candidates = [:u], provenance = "fragment"),
            ConditionResolution(path = "a", field = :u, reason = :internally_wired,
                                producer = ("a/b", :y), provenance = "fragment"),
            ConditionResolution(path = "a/b", store = :x, field = :q, reason = :no_store,
                                tier = :discrete, provenance = "fragment"),
            ConditionResolution(path = "a/b", store = :x, field = :q, reason = :undeclared_field,
                                candidates = [:p], role = :output_port, provenance = "fragment"),
            ConditionResolution(path = "a/b", store = :x, field = :p, reason = :unconvertible,
                                declared = Float64, observed = String, value = "x", provenance = "fragment"),
            DuplicateConditionLeaf(path = "a/b", store = :x, field = :p,
                                   provenance = ["fragment", "at(\"a\") → fragment"]),
            ConditionNodeMisuse(observed = NamedTuple, in_hand = [:Fragment]),
            ConditionNodeMisuse(observed = Int, reason = :fragment_payload, payload = :x),
            UninitializedInputs(op = :init!, faces = [:a, :b]),
            TapResolution(label = :r, selector = "get_state(\"a\", :x)", reason = :assembly_path,
                          path = "a"),
            TapResolution(label = :r, selector = "get_state(\"a/b\", :x[1])",
                          reason = :scalar_index, path = "a/b", declared = Float64, index = 1),
            TapResolution(label = :r, selector = "get_state(\"a/b\", :q)", reason = :undeclared,
                          path = "a/b", field = :q, declares = :state_field, candidates = [:p]),
            TapResolution(label = :r, selector = "get_deriv(\"a/b\", :q)",
                          reason = :discrete_deriv, path = "a/b", field = :q),
            TapResolution(label = :r, selector = "get_input(:q)", reason = :unknown_root_input,
                          field = :q, candidates = [:a]),
            TapResolution(label = :r, selector = "get_face(:a)", reason = :root_input_not_face,
                          field = :a),
            TapResolution(label = :r, selector = "get_face(:q)", reason = :unknown_output_face,
                          field = :q, candidates = [:done]),
            TrimProblemInvalid(field = :guess, reason = :not_a_namedtuple, observed = Int),
            TrimProblemInvalid(field = :lower, reason = :key_set, names = [:a],
                               expected = [:a, :b]),
            TrimProblemInvalid(field = :residuals, reason = :key_set, names = [:r],
                               expected = [:s]),
            TrimProblemInvalid(field = :guess, reason = :field_types,
                               bad = Pair{Symbol,Any}[:a => Int]),
            TrimProblemInvalid(field = :residuals, reason = :field_types,
                               bad = Pair{Symbol,Any}[:r => String]),
            TrimProblemInvalid(field = :lower, reason = :inverted_box, key = :a, value = 2.0,
                               bound = 1.0),
            TrimProblemInvalid(field = :tolerances, reason = :nonpositive_tolerance, key = :r,
                               value = 0.0),
            TrimProblemInvalid(field = :reads, reason = :not_a_read_set, observed = NamedTuple),
            TrimCommitEvents(events = [("a/b", :snap)]),
            TrimCommitResiduals(residuals = [(:r, 1.0, 0.5)]),
            ConditionShapeDrift(reason = :tree_type, compiled = Int, observed = Float64),
            ConditionShapeDrift(reason = :prefix, compiled = "a", observed = "b",
                                position = (:x, 1)),
            ArgumentInvalid(call = :Period, reason = :inexact, value = 0.02),
            ArgumentInvalid(call = :Hz, reason = :inexact, value = 0.5),
            ArgumentInvalid(call = :Absolute, reason = :inexact, value = 0.5),
            ArgumentInvalid(call = :Absolute, reason = :not_a_quantity, value = 1),
            ArgumentInvalid(call = :step!, reason = :both_given),
            ArgumentInvalid(call = :step!, reason = :range, argument = :frames, value = 0),
            ArgumentInvalid(call = :step!, reason = :range, argument = :t_plus, value = -1.0),
            ArgumentInvalid(call = :replay!, reason = :both_given),
            ArgumentInvalid(call = :replay!, reason = :range, argument = :to_boundary, value = 9),
            ArgumentInvalid(call = :replay!, reason = :range, argument = :to_time, value = 9.0),
            ArgumentInvalid(call = :live!, reason = :not_replaying),
            ArgumentInvalid(call = :trim!, reason = :non_nominal, value = "Simulation{Dual}"),
            ArgumentInvalid(call = :trim!, argument = :problem, reason = :not_a_problem,
                            value = "NamedTuple"),
            ArgumentInvalid(call = :trace, reason = :disabled),
            ArgumentInvalid(call = :selector, reason = :index_not_integer, value = 1.5),
            ArgumentInvalid(call = :TableBinding, reason = :entry_shape, entry = :a),
            ArgumentInvalid(call = :TableBinding, reason = :no_face, entry = :a),
            ArgumentInvalid(call = :TableBinding, reason = :face_name, entry = :a, value = 1),
            ArgumentInvalid(call = :TableBinding, reason = :vocabulary, entry = :a,
                            argument = :gain, vocabulary = [:face, :deadzone, :expo]),
            ArgumentInvalid(call = :TableBinding, reason = :deadzone, entry = :a, value = 1.5),
            ArgumentInvalid(call = :TableBinding, reason = :expo, entry = :a, value = 2.0),
            ReadSetMisuse(observed = Int, reason = :not_a_selector, label = :r),
            ReadSetMisuse(observed = NamedTuple, reason = :not_a_read_set),
            NotAttached(device = "Pad", roster = ["device 1 (Pad)"]),
            ReplayHeaderMismatch(what = :scalar, expected = Float64, found = D8),
            ReplayHeaderMismatch(what = :store, name = :paths, expected = ["a"],
                                 found = ["a", "b"]),
            ReplayHeaderMismatch(what = :store, path = "a", name = :s, expected = NamedTuple,
                                 found = nothing),
            ReplayHeaderMismatch(what = :root_input, expected = [:a], found = [:a, :b]),
            ReplayHeaderMismatch(what = :root_input, name = :a, expected = Float64, found = "x"),
            ReplayHeaderMismatch(what = :deployment, name = :h, expected = 0.1, found = 0.05),
            ReplayHeaderMismatch(what = :frame, name = :harness, expected = 1:8, found = 99),
            ReplaySchemaMismatch(writer = "harness", schema = [:a, :z], unknown = [:z],
                                 faces = [:a, :b]),
            ReplayUnknownFace(face = 7, frame = 1, writer = "harness", faces = [:a, :b]),
            ReplayUnknownFace(face = :z, frame = 1, writer = "device 1 (Pad)", faces = [:a, :b]),
            # §13.4's runtime species, the one kind a `StepError` carries as its cause
            NonfiniteState(path = "a/b", leaf = "v[2]", value = NaN, t = 0.14, boundary = 6),
            # the runtime stream's nine, re-parented (§11.8)
            MalformedDatum(ArgumentError("bad")),
            OutOfClaimEntry(:a, 1.0, [:b], "device 1 (Pad)"),
            ClaimedFaceEntry(:a, "device 1 (Pad)", 1.0, :staging),
            EntryTypeMismatch(:a, "x", Float64),
            ChatteringBudget("a/b", :snap, 1.0, 8, 9),
            FiringBudget("a/b", :snap, 1.0, 4, 5),
            DeviceCrash(ArgumentError("bad"), false),
            DeviceJoinTimeout("device 1 (Pad)", 5.0, 1.0, 10),
            ReplayDiscardedStaging([:a, :b], 3),
        ]

        # Appendix C's severity column, as the list it is: every other kind is an
        # error, so a kind added on the wrong side of the line fails here.
        warning_kinds = Set{DataType}([EmptyGreedyClaim, TrimCommitEvents, TrimCommitResiduals,
                                      MalformedDatum, OutOfClaimEntry, ClaimedFaceEntry,
                                      EntryTypeMismatch, ChatteringBudget, FiringBudget,
                                      DeviceCrash, DeviceJoinTimeout, ReplayDiscardedStaging])
        for d in occurrences
            @test severity(d) === (typeof(d) in warning_kinds ? :warning : :error)
            @test path(d) isa String
            m = message(d)
            @test m isa String && !isempty(m)
        end
        # A declared generic holding renders through `_typename` like any other
        # name: the variable and its bound, unqualified, whoever is printing — the
        # `string(::TypeVar)` spelling reads `Cadence.AbstractComponent` from
        # anywhere but this module. A payload claim, so it sits here rather than in
        # the rendering testset below.
        m = message(only(d for d in occurrences
                         if d isa PathResolution && d.reason === :past_generic))
        @test occursin("`L<:AbstractComponent`", m) && !occursin("Cadence.", m)
        # A `Union`-typed holding has no name to take: it renders from its members,
        # in the order Julia itself keeps them.
        @test _typename(Union{Plant, Gain}) == "Union{Gain, Plant}"

        # Every kind of the closed set has an occurrence above: the coverage
        # check is over `Diagnostic`'s own subtypes, so adding a kind without an
        # occurrence fails here rather than going unrendered.
        @test Set(typeof.(occurrences)) == Set(subtypes(Diagnostic))

    end

    # --- rendering: the suite's one deliberate exception -----------------------------
    # Everywhere else a test matches a diagnostic's *kind and payload*, never its
    # text (§13.2). Here, and only here, the rendered string is the claim: the
    # carrier's compiler-style layout, and the didactic style `message` is for —
    # state the fix, show the list in hand. Nothing outside this testset may
    # `occursin` on a rendered diagnostic; a wording change is free everywhere else
    # and lands here.
    @testset "rendering: the carrier compiler-style, the didactic style (§13.1, §13.2)" begin
        # Two kinds × two paths: groups in first-appearance order, paths sorted
        # within a group, the kind name leading each line, the count line above.
        e = DiagnosticError(Diagnostic[UnconnectedInput(path = "b", face = :u),
                                  FaceNameIllegal(path = "b", face = "p/q", invariant = :contains_slash),
                                  UnconnectedInput(path = "a", face = :v),
                                  FaceNameIllegal(path = "a", face = "r/s",
                                                  invariant = :contains_slash)])
        @test kinds(e) == [UnconnectedInput, FaceNameIllegal]
        lines = split(sprint(showerror, e), '\n')
        @test lines[1] == "DiagnosticError: 4 diagnostics"
        @test startswith(lines[2], "  UnconnectedInput: `a`.v")
        @test startswith(lines[3], "  UnconnectedInput: `b`.u")
        @test startswith(lines[4], "  FaceNameIllegal: ") && occursin("`r/s`", lines[4])
        @test startswith(lines[5], "  FaceNameIllegal: ") && occursin("`p/q`", lines[5])

        # A fail-fast site's single diagnostic renders on one line, no count.
        @test sprint(showerror, DiagnosticError(UnconnectedInput(path = "a", face = :v))) ==
              "DiagnosticError: UnconnectedInput: " * message(UnconnectedInput(path = "a", face = :v))

        # The parameter is the policy, and the outer constructors choose it (D-222).
        d = UnconnectedInput(path = "a", face = :v)
        @test DiagnosticError(d) isa DiagnosticError{typeof(d)}
        @test DiagnosticError([d]) isa DiagnosticError{Vector{Diagnostic}}
        @test diagnostic(DiagnosticError(d)) === d
        @test diagnostics(DiagnosticError([d])) == [d]
        # Each accessor is defined on one policy: the other is a MethodError, which
        # is how a test states which policy a throw has.
        @test_throws MethodError diagnostics(DiagnosticError(d))
        @test_throws MethodError diagnostic(DiagnosticError([d]))
        # The parameter bound is closed; Julia refuses the substitution itself.
        @test_throws TypeError DiagnosticError{Int}(1)

        # The did-you-mean list is carried, not ranked (`pending.md`): the
        # candidates the site had in hand are printed, and no edit distance orders
        # them.
        m = message(UnknownPort(entry = "wires", end_ = :destination, path = "a/b",
                                spelling = "a/b", port = :throtle,
                                candidates = [:throttle, :brake]))
        @test occursin("names no `throtle`", m) && occursin("throttle, brake", m)

        # The synthesis chain's miss names the face, the type with its parameters,
        # and both remedies (§9.3, D-051).
        m = message(MissingProbeValue(face = :pilot, declared = NamedTuple{(:a,),Tuple{Float64}}))
        @test occursin("probe_value(::Type{", m) && occursin("zero-argument constructor", m)

        # The dead stage names the return it got and the stage it got it from.
        m = message(DeadStage(path = "a/b", stage = "output_state"))
        @test occursin("`(;)`", m) && occursin("output_state", m)

        # A read miss that is name-shaped prints the list the site had in hand.
        m = message(ReadBindingUnresolved(binding = "Readout", selector = "get_output(\"p\", :nope)",
                                          reason = :unknown_cell, path = "p", field = :nope,
                                          candidates = [:power, :y]))
        @test occursin("{power, y}", m)

        # The forgotten import (§8.1, D-246) states its fix as the line to paste,
        # spelled for exactly the names the module shadowed.
        m = message(DeclarationShadowed(path = "a/b", mod = "Main.MyModel",
                                        names = [:init_x, :output_types]))
        @test occursin("import Cadence: init_x, output_types", m)

        # A bare store value (§8.2, D-247) spells the wrap for the store at fault.
        m = message(StoreNotNamedTuple(path = "a/b", store = :init_x, declared = Float64))
        @test occursin("init_x(::C) = (; ω = 0.0)", m)
        m = message(StoreNotNamedTuple(path = "a/b", store = :init_s, declared = Float64))
        @test occursin("init_s(::C) = (; n = 0)", m)
        m = message(StoreNotNamedTuple(path = "a/b", store = :init_m, declared = Int))
        @test occursin("init_m(::C) = (; phase = :idle)", m)

        # The forgotten-`T` hint on the input side (§6.1, §8.2, D-236) states the
        # fix by name.
        m = message(WalkingFaceAtFrozenEntry(path = "c", face = :u, producer_path = "src",
                                             producer_port = :val, leaf = "",
                                             declared = Float64, observed = Marker))
        @test occursin("declare the entry `T`", m)

        # The cycle's three forms (§5.5, §5.6, D-245), over constructed values: the
        # cluster's wires read as one loop, and the classification, where there is
        # one, names the dead hops in the ladder's own words.
        m = message(AlgebraicCycle(members = ["plant", "sum", "ctl"],
                                   wires = ["plant/power" => "sum/b", "sum/e" => "ctl/e",
                                            "ctl/out" => "plant/u"]))
        @test occursin("plant/power → sum/b, sum/e → ctl/e, ctl/out → plant/u", m)
        @test occursin("break it with a state", m)
        # Artificial: the hop, then §5.4's two exits, each dead member named once.
        m = message(AlgebraicCycle(members = ["d", "g"],
                                   wires = ["d/y" => "g/e", "g/out" => "d/b"],
                                   classification = :artificial, dead = [("d", :b, :y)],
                                   traced = ["d" => :global, "g" => :global]))
        @test occursin("artificial at port level", m)
        @test occursin("`d`'s `y` does not route `b`", m)
        @test occursin("split `d`, or narrow", m)
        # Real with a dead chord: the hop is still listed, as a wire to delete.
        m = message(AlgebraicCycle(members = ["s", "g", "i"],
                                   wires = ["s/e" => "g/e", "s/e" => "i/b",
                                            "g/out" => "s/a", "i/y" => "s/b"],
                                   classification = :real, dead = [("i", :b, :y)],
                                   traced = ["s" => :global, "g" => :global, "i" => :global]))
        @test occursin("a wire the loop does not need", m)
        # The mode rides in the message: a structural map can never kill a hop.
        m = message(AlgebraicCycle(members = ["p", "q"],
                                   wires = ["p/b" => "q/a", "q/b" => "p/a"],
                                   classification = :real,
                                   traced = ["p" => :structural, "q" => :structural]))
        @test occursin("structurally", m)
        # The sampled fallback rides in both forms: as the mode phrase under a
        # real verdict, and as the caveat on a hop it found under an artificial
        # one, an untaken branch being its only miss (§5.6, D-012).
        m = message(AlgebraicCycle(members = ["m", "g1", "g2"],
                                   wires = ["m/F" => "g1/e", "g1/out" => "m/f"],
                                   classification = :real, dead = [("m", :g, :F)],
                                   traced = ["m" => :sampled, "g1" => :global,
                                             "g2" => :global]))
        @test occursin("`m` at sampled states, the rest globally", m)
        m = message(AlgebraicCycle(members = ["m", "g2"],
                                   wires = ["m/F" => "g2/e", "g2/out" => "m/g"],
                                   classification = :artificial, dead = [("m", :g, :F)],
                                   traced = ["m" => :sampled, "g2" => :global]))
        @test occursin("on the sampled paths; an untaken branch may still route it", m)

        # The remedy form: the shortfall, then the fix, with the list in hand.
        m = message(UninitializedInputs(op = :init!, faces = [:u, :e]))
        @test occursin("`init!`", m) && occursin("`u`, `e`", m)
        @test occursin("nothing was written", m)

        # A `logged`-policy warning renders like a carrier line — the kind name, then
        # the message — because it never gets a `showerror` to lead it (D-214). The
        # rendering is `logline`; `logged` is the snapshot accessor (§11.4).
        d = TrimCommitResiduals(residuals = [(:torque, 1.0, 0.5)])
        @test logline(d) == "TrimCommitResiduals: " * message(d)
        @test startswith(logline(d), "TrimCommitResiduals: ") && severity(d) === :warning
    end
end

function test_diagnostics()
    diagnostics_channel()
    diagnostics_kind_set()
end
