# --- the compiled executor (§9.7) ---------------------------------------------
# The four phase bodies are the loop's whole surface onto compiled code: a fixed
# roster, total in both arities, and allocation-free however wide the chunked
# walk gets. The tier gating over those same entries is asserted where the rates
# are (`test_multirate.jl`).

const BLOCKS = (:sweep_1, :sweep_2, :rhs, :ticks)   # the four blocks, both arities

function test_executor()
    @testset "the phase-body roster is fixed and total (§9.7)" begin
        sim = Simulation(feedback_model(); h = 1//100)
        bodies = phase_bodies(sim)
        @test keys(bodies) === (:sweep_1, :sweep_2, :rhs, :ticks, :events, :projections)
        @test bodies.ticks() === nothing            # empty body: legal, a no-op
        @test bodies.ticks(3) === nothing           # and total in both arities
        @test isempty(bodies.events) && isempty(bodies.projections)
        for name in BLOCKS
            body = bodies[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end

        # One stage-1 return over both homes (§5.3): `Motor` returns `ω` from
        # `x` and `running` from `m` in a single `y_state`, so its stage-1
        # block is one `StageEntry` and the canary holds over it.
        motor_sim = Simulation(fed(Motor(1.0), "M_load"); h = 1//100)
        bodies = phase_bodies(motor_sim)
        walk = walked(bodies.sweep_1, :interior)
        @test count(e -> e isa StageEntry, walk) == 1
        for name in BLOCKS
            body = bodies[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end
    end

    @testset "the chunk walk is allocation-free at any width (§9.7)" begin
        # Six independent loops at chunk_size = 1: sweep_2 walks 18 one-entry
        # chunks — a chunk count no other fixture approaches — so the §7.5 canary
        # covers the outer walk over the chunk tuple itself, not just the entry
        # walks within one chunk.
        six = Group(NamedTuple{ntuple(i -> Symbol(:m, i), 6)}(ntuple(_ -> feedback_model(), 6));
                    input_wires = ("ref" => ntuple(i -> "m$(i)/ref", 6),))
        sim = Simulation(six; h = 1//100, chunk_size = 1)
        @test length(sim.model.exec.bodies.sweep_2.interior) > 16
        for name in BLOCKS
            body = phase_bodies(sim)[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end

        # Past 32 elements, where a `Base.tail` recursion stops inferring and
        # allocates at every call. Forty loops at chunk_size = 1 give sweep_2 a
        # tuple of 120 chunks; at chunk_size = 40 one chunk holds 40 entries.
        forty = Group(NamedTuple{ntuple(i -> Symbol(:m, i), 40)}(ntuple(_ -> feedback_model(), 40));
                      input_wires = ("ref" => ntuple(i -> "m$(i)/ref", 40),))
        for chunk_size in (1, 40)
            sim = Simulation(forty; h = 1//100, chunk_size)
            sweep_2 = sim.model.exec.bodies.sweep_2
            @test length(sweep_2.interior) == 120 ÷ chunk_size
            @test length(first(sweep_2.interior).entries) == chunk_size
            for name in BLOCKS
                body = phase_bodies(sim)[name]
                body(); body(0)
                @test @ballocated($body()) == 0
                @test @ballocated($body(1)) == 0
            end
        end

        # The event set's three walks, at 40 projections and 40 events: forty
        # one-entry chunks at chunk_size = 1, one chunk of forty at 40.
        rotors = Group(NamedTuple{ntuple(i -> Symbol(:p, i), 40)}(
            ntuple(_ -> Group((; rot = Rotor(), saw = Sawtooth(1.0))), 40)))
        for chunk_size in (1, 40)
            sim = Simulation(rotors; h = 1//100, chunk_size)
            init!(sim)
            @test length(phase_bodies(sim).projections) == 40
            @test length(phase_bodies(sim).events) == 40
            events, store, xbuf = sim.model.exec.events, sim.model.exec.store, sim.model.exec.xbuf
            @test length(events.entries) == length(events.projects) == 40 ÷ chunk_size
            _projects!(events, xbuf); _guards!(events, store, xbuf); _fire!(events, store, xbuf)
            @test @ballocated(_projects!($events, $xbuf)) == 0
            @test @ballocated(_guards!($events, $store, $xbuf)) == 0
            @test @ballocated(_fire!($events, $store, $xbuf)) == 0
        end
    end

    @testset "chunks and the event set are held by reference (§9.7)" begin
        # The executor holds one pointer per chunk, so its inline size grows by
        # one word per phase-body chunk whatever the chunk holds. It holds the
        # event set by one pointer too, and the event set holds one pointer per
        # event chunk.
        count_chunks(sim) =
            sum(length(getfield(sim.model.exec.bodies[name], variant))
                for name in BLOCKS for variant in (:interior, :boundary))
        loops(n) = Group(NamedTuple{ntuple(i -> Symbol(:m, i), n)}(ntuple(_ -> feedback_model(), n));
                         input_wires = ("ref" => ntuple(i -> "m$(i)/ref", n),))
        # Each loop runs at its own rate, so a walk that reorders or drops an
        # entry changes the state below.
        rotor_saws(n) = Group(NamedTuple{ntuple(i -> Symbol(:p, i), n)}(
            ntuple(i -> Group((; rot = Rotor(; ω = 1.0 + i / 100),
                                 saw = Sawtooth(1.0 + i / 100))), n)))
        for model in (loops, rotor_saws)
            small, big = Simulation(model(6); h = 1//100), Simulation(model(40); h = 1//100)
            @test sizeof(big.model.exec) - sizeof(small.model.exec) ==
                  sizeof(Int) * (count_chunks(big) - count_chunks(small))
        end
        events = Simulation(rotor_saws(40); h = 1//100).model.exec.events
        @test ismutable(events)
        @test sizeof(events.entries) == sizeof(Int) * length(events.entries)
        @test sizeof(events.projects) == sizeof(Int) * length(events.projects)

        # The event-set walks cross chunk borders: forty events and forty
        # projections at chunk size 4 sit in ten chunks each, and the run past
        # three wraps is the run at 16 and at 64.
        rotors = rotor_saws(40)
        runs = map((4, 16, 64)) do chunk_size
            sim = Simulation(rotors; h = 1//100, chunk_size)
            init!(sim)
            run!(sim; t_end = 3.5)
            sim
        end
        @test length(runs[1].model.exec.events.entries) == 10
        @test length(runs[1].model.exec.events.projects) == 10
        @test all(state(runs[1], "p$(i)/saw").q < 1 for i in 1:40)   # every saw wrapped
        @test runs[1].model.exec.xbuf == runs[2].model.exec.xbuf == runs[3].model.exec.xbuf

        # A body with no gated entry walks its interior at a boundary: its two
        # tuples have one type, and the boundary call writes what the interior does.
        sim = Simulation(feedback_model(); h = 1//100)
        init!(sim, fragment(u = (ref = 0.5,)))
        run!(sim; t_end = 0.1)
        rhs = phase_bodies(sim).rhs
        @test fieldtype(typeof(rhs), :interior) === fieldtype(typeof(rhs), :boundary)
        rhs(); ẋ_interior = copy(sim.model.exec.ẋbuf)
        fill!(sim.model.exec.ẋbuf, NaN); rhs(3)
        @test sim.model.exec.ẋbuf == ẋ_interior
        # It reuses the interior's compiled walk: no boundary walk exists for
        # this body's entries.
        entries_types = [typeof(chunk.entries) for chunk in rhs.interior]
        @test !any(Base.specializations(only(methods(_walk_at)))) do method_instance
            Base.unwrap_unionall(method_instance.specTypes).parameters[2] in entries_types
        end
    end

    @testset "the event and projection callables ride with the four blocks (§9.7)" begin
        sim = Simulation(Group((; rot = Rotor(), saw = Sawtooth(1.0))); h = 1//100)
        init!(sim)
        bodies = phase_bodies(sim)
        @test collect(keys(bodies.events)) == [("saw", :wrap)]
        @test collect(keys(bodies.projections)) == ["rot"]
        event = bodies.events[("saw", :wrap)]
        @test event.guard() isa Float64        # the sign-form guard over the live bundle
        event.handler(); bodies.projections["rot"]()
        for f in (event.guard, event.handler, bodies.projections["rot"])
            @test @ballocated($f()) == 0
        end
    end
end
