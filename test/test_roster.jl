# --- the roster and claims (§11.3, §11.4, §11.6's attach-point slice) -----------
# Increment 10: attach/detach admission, both claim sources, per-device staging
# cells, and the harness writer as the derived remainder.
#
# The malformed bindings live at top level for `implementation.md`'s local-scope
# reason: a trait method defined inside a @testset binds a new local function,
# and the conformance check would see a binding declaring nothing at all.

struct NoSides <: AbstractBinding end                # neither side declared

struct NoEnum <: AbstractBinding end                 # input declared, enumeration missing
is_input(::NoEnum) = true

struct GreedyPlus <: AbstractBinding end             # both claim sources at once
is_input(::GreedyPlus) = true
is_greedy(::GreedyPlus) = true
claims(::GreedyPlus) = ("a",)

struct Sourceless <: AbstractBinding end             # a source without its side
is_greedy(::Sourceless) = true

struct Drifted <: AbstractBinding end                # `claims` under a false `is_input`
is_output(::Drifted) = true
claims(::Drifted) = ("a",)

struct Unwritten <: AbstractBinding end              # output side only: absent here
is_output(::Unwritten) = true

function test_roster()
    @testset "the binding conformance check names every drift at the attach point (§11.6)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Pad("d")
        for (b, reason) in ((NoSides(), :neither_side),
                            (NoEnum(), :claims_missing),
                            (GreedyPlus(), :greedy_with_claims),
                            (Sourceless(), :greedy_without_input),
                            (Drifted(), :claims_without_input))
            d = carried(@test_throws DiagnosticError{BindingContractMismatch} attach!(sim, dev, b))
            @test d.reason === reason
        end
        # The output side is an absence, not a conformance drift, and it is named
        # *after* the conformance clauses — which is why Drifted above reported its
        # drift rather than falling through to this.
        d = carried(@test_throws DiagnosticError{BindingContractMismatch} attach!(sim, dev, Unwritten()))
        @test d.reason === :reads_missing
        @test isempty(sim.plane.roster)                  # none of the six was rostered
    end

    @testset "admission is three checks in spec order (§11.3)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Pad("d1")
        attach!(sim, dev, Enumerated("a"))
        @test sim.plane.roster[end].id == 1
        # Identity before claims: the same instance re-attached — even under an
        # overlapping claim — is AlreadyAttached, never a self-ClaimConflict.
        @test_throws DiagnosticError{AlreadyAttached} attach!(sim, dev, Enumerated("a"))
        # Claims: face exclusivity, always two *distinct* devices named.
        err = failure(() -> attach!(sim, Pad("d2"), Enumerated("b", "a")))
        d = only(diagnostics(err))
        @test err isa DiagnosticError && d isa ClaimConflict
        @test occursin("device 1", d.incumbent)
        # Affinity: the calling task is a single-slot resource.
        attach!(sim, Panel("p1"), Enumerated("b"))
        @test sim.plane.roster[end].id == 2
        @test_throws DiagnosticError{CallerTaskConflict} attach!(sim, Panel("p2"), Enumerated())
        # An enumeration drifted onto a nonexistent face is a diagnosable anomaly.
        d = carried(@test_throws DiagnosticError{AttachUnknownFace} attach!(sim, Pad("d3"), Enumerated("flaps")))
        @test d.device == "Pad" && d.binding == "Enumerated" && d.face === :flaps
        # Detaching what was never rostered is an error, not a silent no-op.
        @test_throws DiagnosticError{NotAttached} detach!(sim, Pad("ghost"))
    end

    @testset "a device writes inside its claim, every check at its own staging (§11.3, §11.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev_a, dev_b = Pad("da"), Pad("db")
        handle_a = attach!(sim, dev_a, Enumerated("a"))           # the handle is the write capability (§11.6)
        handle_b = attach!(sim, dev_b, Enumerated("b"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        stage!(handle_a, "a" => 1.0)
        stage!(handle_b, "b" => 2)                       # the shim converts to the root input's Float64
        @test port(sim, "", :a) === 0.0                  # staged is pending, never applied (§11.1)
        step!(sim; frames = 1)
        @test port(sim, "", :a) === 1.0
        @test port(sim, "", :b) === 2.0
        # Out-of-claim is always OutOfClaimEntry for a device — naming the incumbent
        # when the face is claimed elsewhere — and the rest of the batch stands.
        # The rejection lands in the *staging* device's own cell (§11.8), folded
        # into its record at the next frame top.
        stage!(handle_a, "b" => 9.0, "a" => 3.0)
        stage!(handle_a, "flaps" => 1.0)
        step!(sim; frames = 1)
        @test port(sim, "", :a) === 3.0
        @test port(sim, "", :b) === 2.0
        status = writer_status(latest(sim), "device 1 (Pad)")
        @test status.totals.out_of_claim == 2
        ooc = only(d for d in status.recent if d.face === :b)
        @test ooc.incumbent == "device 2 (Pad)" && ooc.value == 9.0 && ooc.surface == [:a]
        @test only(d for d in status.recent if d.face === :flaps).incumbent === nothing
        # The empty enumeration: an honest may-write-nothing degenerate (§11.6).
        handle_c = attach!(sim, Pad("dc"), Enumerated())
        stage!(handle_c, "a" => 9.0)
        entry = only((@atomic handle_c.diag.batch).ring)       # pending in the cell until the next drain
        @test entry isa OutOfClaimEntry
        @test entry.surface == Symbol[] && entry.incumbent == "device 1 (Pad)"
    end

    @testset "the computed claim is the complement at the attach instant (§11.3, §11.6)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev, greedy = Pad("d1"), Pad("gui")
        attach!(sim, dev, Enumerated("a"))
        # greedy last: exactly what is left
        greedy_handle = attach!(sim, greedy, Greedy())
        @test sim.plane.roster[2].handle.writer.faces == [:b]
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        stage!(greedy_handle, "b" => 5.0)
        run!(sim; t_end = 0.1)
        @test port(sim, "", :b) === 5.0
        # Past the attach point nothing downstream tells the sources apart.
        stage!(greedy_handle, "a" => 9.0)
        @test only((@atomic greedy_handle.diag.batch).ring) isa OutOfClaimEntry

        # A rostered greedy claimant empties the harness surface: every harness
        # stage! in such a session is rejected by name into the harness writer's
        # own cell (D-192, §11.8).
        @test isempty(sim.plane.harness.faces)
        stage!(sim, "b" => 9.0)
        stage!(sim, "a" => 9.0)
        ring = (@atomic sim.plane.harness_diag.batch).ring
        @test [d.face for d in ring] == [:b, :a]
        @test all(d isa ClaimedFaceEntry for d in ring)
        @test ring[1].incumbent == "device 2 (Pad)" && ring[2].incumbent == "device 1 (Pad)"

        # A second greedy stakes the empty remainder: legal, useless, said out loud.
        greedy2 = Pad("gui2")
        @test_logs (:warn, r"^EmptyGreedyClaim: ") attach!(sim, greedy2, Greedy())   # `logged`, kind first
        @test isempty(sim.plane.roster[3].handle.writer.faces)
        # The line is presentation; the warning's home is the new entry's own
        # cell (§11.8, D-250), so the next run's status carries it.
        @test only((@atomic sim.plane.roster[3].handle.diag.batch).ring) isa EmptyGreedyClaim
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))   # cells survive a fresh trajectory
        step!(sim; frames = 1)
        @test writer_status(latest(sim), "device 3 (Pad)").totals.empty_greedy == 1
    end

    @testset "the harness surface is the unclaimed complement, recomputed at roster changes (§11.3)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        @test sim.plane.harness.faces == [:a, :b]        # the empty roster's complement
        dev = Pad("d")
        attach!(sim, dev, Enumerated("a"))
        @test sim.plane.harness.faces == [:b]
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        stage!(sim, "a" => 1.0)                          # claimed: rejected into the harness cell
        stage!(sim, "b" => 2.0)
        step!(sim; frames = 1)
        @test port(sim, "", :a) === 0.0
        @test port(sim, "", :b) === 2.0
        entry = only(writer_status(latest(sim), "harness").recent)
        @test entry isa ClaimedFaceEntry && entry.face === :a
        @test entry.incumbent == "device 1 (Pad)" && entry.site === :staging
        # Detach releases the claims: the surface regains the face from the next frame.
        detach!(sim, dev)
        @test sim.plane.harness.faces == [:a, :b]
        stage!(sim, "a" => 3.0)
        step!(sim; frames = 1)
        @test port(sim, "", :a) === 3.0
    end

    @testset "the recompilation seam: a pending harness batch is renormalized at attach (§11.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))  # first: a pre-init! batch would clear (§12.6)
        stage!(sim, "a" => 1.0, "b" => 2.0)              # staged while stopped, roster still empty
        # The attach reshapes the pending batch through the new schema, discarding
        # the newly claimed face into the harness cell with the incumbent and the
        # site named.
        attach!(sim, Pad("d"), Enumerated("a"))
        run!(sim; t_end = 0.1)
        @test port(sim, "", :a) === 0.0                  # discarded at the attach, never drained
        @test port(sim, "", :b) === 2.0                  # reshaped, re-staged, drained
        entry = only(writer_status(latest(sim), "harness").recent)
        @test entry isa ClaimedFaceEntry && entry.face === :a
        @test entry.incumbent == "device 1 (Pad)" && entry.site === :renormalization
        # At detach the surface only broadens: every pending entry survives.
        sim2 = Simulation(two_root_inputs(); h = 1//10)
        init!(sim2, fragment(inputs = (a = 0.0, b = 0.0)))
        dev = Pad("d2")
        attach!(sim2, dev, Enumerated("a"))
        stage!(sim2, "b" => 4.0)
        detach!(sim2, dev)
        run!(sim2; t_end = 0.1)
        @test port(sim2, "", :b) === 4.0
    end

    @testset "device ids are monotonic per Simulation and never reused (§11.3)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Pad("d1")
        attach!(sim, dev, Enumerated("a"))
        @test sim.plane.roster[end].id == 1
        attach!(sim, Pad("d2"), Enumerated("b"))
        @test sim.plane.roster[end].id == 2
        detach!(sim, dev)
        err = failure(() -> attach!(sim, Pad("dx"), Enumerated("b")))     # rejected: ClaimConflict
        @test err isa DiagnosticError
        attach!(sim, Pad("d3"), Enumerated("a"))
        @test sim.plane.roster[end].id == 3                                # not 1, and no id burned
    end

    @testset "the roster is frozen per run: attach and detach are stopped-sim operations (§11.3)" begin
        sim = Simulation(chain3(); h = 1//100000)
        init!(sim, fragment(inputs = (u = 0.0,)))
        dev = Pad("d")
        # also warms both compile paths, so
        attach!(sim, dev, Enumerated("u"))
        @test sim.plane.roster[end].id == 1              # the mid-run checks below race no JIT
        detach!(sim, dev)
        task = Threads.@spawn run!(sim; t_end = 1.0)                # 100k frames: alive throughout the checks
        while lifecycle(sim) !== :running
            yield()
        end
        # Inline try/catch rather than `failure`: a fresh closure would JIT-compile
        # mid-run, and the run could end inside that pause.
        attach_err = try attach!(sim, dev, Enumerated("u")) catch err; err end
        detach_err = try detach!(sim, dev) catch err; err end
        wait(task)
        @test attach_err isa DiagnosticError && diagnostic(attach_err) isa ServiceLifecycle
        @test detach_err isa DiagnosticError && diagnostic(detach_err) isa ServiceLifecycle
        # The freeze lifts with the run: the same operations are legal again.
        attach!(sim, dev, Enumerated("u"))
        @test sim.plane.roster[end].id == 2
        detach!(sim, dev)
    end

    @testset "the frame's outcome is a pure function of the drained batches, whoever staged them (§11.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev_a, dev_b = Pad("da"), Pad("db")
        handle_a = attach!(sim, dev_a, Enumerated("a"))
        handle_b = attach!(sim, dev_b, Enumerated("b"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        step!(sim; t_plus = 0.3)
        stage!(handle_a, "a" => 0.7)
        stage!(handle_b, "b" => -1.3)
        step!(sim; t_plus = 0.5)
        reference = Simulation(two_root_inputs(); h = 1//10)
        init!(reference, fragment(inputs = (a = 0.0, b = 0.0)))
        step!(reference; t_plus = 0.3)
        # the counterfactual, under the data plane
        poke!(reference, "a", 0.7)
        poke!(reference, "b", -1.3)
        step!(reference; t_plus = 0.5)
        @test port(sim, "s", :e) === port(reference, "s", :e)
    end

    @testset "an empty drain stays free with a populated roster (§11.1, §11.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("da"), Enumerated("a"))
        attach!(sim, Pad("gui"), Greedy())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        @test @ballocated(drain!($sim)) == 0
    end

    @testset "a populated device drain is as free as an empty one (§11.4, D-202)" begin
        # `trace = false`: the scatter's cost is what this measures, §11.5's sparse
        # record being the drain's one admitted allocation (test_dataplane.jl)
        sim = Simulation(two_root_inputs(); h = 1//10)
        handle_a = attach!(sim, Pad("da"), Enumerated("a"))
        greedy_handle = attach!(sim, Pad("gui"), Greedy())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)); trace = false)
        # warm both scatters
        stage!(handle_a, "a" => 1.0); stage!(greedy_handle, "b" => 1.0); drain!(sim)
        @test @ballocated(drain!($sim), setup = (stage!($handle_a, "a" => 2.0)),
                           evals = 1) == 0
        @test @ballocated(drain!($sim), setup = (stage!($greedy_handle, "b" => 2.0)),
                           evals = 1) == 0
    end
end
