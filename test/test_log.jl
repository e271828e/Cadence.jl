# --- the log (§11.2, increment 11) ----------------------------------------------
# Publication now follows *every* boundary — t* boundaries included, retiring
# the increment-9 stand-in — and the log is retention policy over exactly those
# publications: the switch, the stride, the bound with its progressive
# re-decimation, and the two unconditional endpoints outside it.

function test_log()
    @testset "every boundary publishes: t* included, boundary-consistent (§11.2, §10.6)" begin
        model = Group((; src = Sawtooth(1.0), s = Stamper(0.315));
                      wires = ("src/q" => "s/sig",))
        sim = Simulation(model; h = 1//10)
        init!(sim)
        run!(sim; t_end = 0.5)
        snapshots = logged(sim)
        t★ = modes(sim, "s").t_fired
        i = findfirst(snapshot -> snapshot.t == t★,
                       snapshots)   # bitwise: a snapshot published at t* itself
        @test i !== nothing
        @test length(snapshots) == 7               # boundary zero + 5 frame tops + one t*
        @test [snapshot.frame for snapshot in snapshots] == [0, 1, 2, 3, 4, 4, 5]   # t* shares its frame's ordinal
        # The t* snapshot is the settled boundary's: the re-sweep after the firing
        # is what it captures, so `armed` has already dropped — while the boundary
        # before it still shows the armed value. Boundary-consistency at t*.
        @test port(snapshots[i], "s", :armed) === false
        @test port(snapshots[i-1], "s", :armed) === true
        ts = [snapshot.t for snapshot in snapshots]
        @test issorted(ts) && allunique(ts)    # t never decreases, t* strictly inside
    end

    @testset "the log is the publications themselves: full density, zero copies (§11.2)" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(sim, fragment(inputs = (in = 1.0,)))
        step!(sim; t_plus = 1.0)
        snapshots = logged(sim)
        @test [snapshot.frame for snapshot in snapshots] == collect(0:10)      # boundary zero + every frame top
        @test snapshots[end] === latest(sim)                     # the same object publication handed out
        ys = [port(snapshot, "c", :y) for snapshot in snapshots]
        @test issorted(ys) && allunique(ys)                  # the step response, one value per boundary
        @test ys[end] === port(sim, "c", :y)        # the terminal endpoint is the live boundary
        step!(sim; t_plus = 1.0)
        @test length(logged(sim)) == 21                      # the session accumulates: one trajectory, one log
    end

    @testset "log_every thins retention, never publication (§11.2)" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(sim, fragment(inputs = (in = 0.0,)); log_every = 3)
        step!(sim; frames = 1)
        @test latest(sim).frame == 1                         # published to live readers…
        @test [snapshot.frame for snapshot in logged(sim)] == [0, 1]       # …not retained: `last` alone holds it
        step!(sim; t_plus = 0.9)
        @test [snapshot.frame for snapshot in logged(sim)] == [0, 3, 6, 9, 10]
    end

    @testset "the endpoints are unconditional and outside the bound (§11.2)" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(sim, fragment(inputs = (in = 0.0,)); log_every = 4, log_max = 2)
        run!(sim; t_end = 4.0)
        snapshots = logged(sim)
        @test [snapshot.frame for snapshot in snapshots] ==
              [0, 16, 32, 40]    # two generations in
        @test sim.run.log.live == 2                              # the bound counts the middle alone
    end

    @testset "re-decimation: stride doubles, coverage stays global, the bound holds continuously (§11.2, D-137)" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(sim, fragment(inputs = (in = 0.0,)); log_max = 8)
        ok_bound = ok_ends = ok_sorted = true
        for k in 1:128                                       # one frame at a time: every
            step!(sim; frames = 1)                           # intermediate state is checked
            ok_bound &= sim.run.log.live ≤ 8
            snapshots = logged(sim)
            ok_ends &= snapshots[1].frame == 0 && snapshots[end].frame == k
            ts = [snapshot.t for snapshot in snapshots]
            ok_sorted &= issorted(ts) && allunique(ts)
        end
        @test ok_bound && ok_ends && ok_sorted
        # 128 = 16·8 boundaries, four generations in: the middle sits at exactly
        # stride·(1..max) — coverage global at the effective stride, gap-free —
        # and the retained final boundary dedups against the terminal endpoint.
        @test sim.run.log.stride == 16
        @test [snapshot.frame for snapshot in sim.run.log.snaps] == collect(16:16:128)
        @test length(logged(sim)) == 9

        # The effective stride composes with the authored one: log_every · 2^k.
        sim2 = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(sim2, fragment(inputs = (in = 0.0,)); log_every = 2, log_max = 4)
        run!(sim2; t_end = 4.0)
        @test [snapshot.frame for snapshot in logged(sim2)] == [0, 8, 16, 24, 32, 40]
        @test sim2.run.log.stride == 16                          # 2 · 2³
    end

    @testset "log = false retains nothing; publication is upstream of the switch (§11.2)" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(sim, fragment(inputs = (in = 0.0,)); log = false)
        run!(sim; t_end = 0.5)
        @test isempty(logged(sim))
        @test latest(sim).frame == 5
    end

    @testset "view policies, never trajectory-determining (§11.2)" begin
        # A localized-event trajectory, so the t* machinery is in the loop too:
        # retention differing in every keyword, the trajectory bitwise the same.
        function session(; kw...)
            sim = Simulation(single(Bouncer(1.0, 0.315)); h = 1//10)
            init!(sim; kw...)
            sim
        end
        full, unlogged, thinned =
            session(), session(log = false), session(log_every = 7, log_max = 3)
        foreach(sim -> run!(sim; t_end = 2.0), (full, unlogged, thinned))
        q_reference = state(full, "c").q
        @test q_reference === state(unlogged, "c").q
        @test q_reference === state(thinned, "c").q
        count_reference = modes(full, "c").count
        @test count_reference === modes(unlogged, "c").count
        @test count_reference === modes(thinned, "c").count
    end

    @testset "a warm restart is a new trajectory: the log starts over (§11.2)" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//10)
        init!(sim, fragment(inputs = (in = 0.0,)))
        run!(sim; t_end = 1.0)
        @test length(logged(sim)) == 11
        init!(sim, fragment(inputs = (in = 0.0,)))
        @test [snapshot.frame for snapshot in logged(sim)] ==
              [0]          # the new boundary zero, alone
    end

    @testset "logged is a stopped-sim read behind the §11.3 gate" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//100000)
        init!(sim, fragment(inputs = (in = 0.0,)); log_max = 16)
        logged(sim)                                          # warms the compile path, so the
                                                             # mid-run check below races no JIT
        task = Threads.@spawn run!(sim; t_end = 1.0)
        while lifecycle(sim) !== :running
            yield()
        end
        err = try logged(sim) catch err; err end
        wait(task)
        @test err isa DiagnosticError && diagnostic(err) isa ServiceLifecycle
        # the readers' gate refuses `:running` alone, post-mortem reads included (§13.6)
        @test diagnostic(err).legal == [:built, :initialized, :stopped, :errored]
        @test length(logged(sim)) ≥ 2                        # the gate lifts with the run
    end

    @testset "the retention keywords are validated with their siblings (§11.2)" begin
        sim = Simulation(fed(Plant(), "u"); h = 1//10)
        authored = fragment(inputs = (in = 0.0,))
        # View policies are the door's keywords, so they are `ArgumentInvalid`s
        # at `call = :init!` (D-261), refused before any write.
        d = only(diagnostics(failure(() -> init!(sim, authored; log = 1))))
        @test d isa ArgumentInvalid && d.call === :init! && d.argument === :log
        d = only(diagnostics(failure(() -> init!(sim, authored; log_every = 0))))
        @test d isa ArgumentInvalid && d.argument === :log_every && d.reason === :range
        d = only(diagnostics(failure(() -> init!(sim, authored; log_max = 0))))
        @test d isa ArgumentInvalid && d.argument === :log_max
        d = only(diagnostics(failure(() -> init!(sim, authored; log_max = 1.5))))
        @test d isa ArgumentInvalid && d.argument === :log_max
        @test lifecycle(sim) === :built
        init!(sim, authored; log_max = Inf)                         # the explicit opt-out
        run!(sim; t_end = 1.0)
        @test length(logged(sim)) == 11
    end
end
