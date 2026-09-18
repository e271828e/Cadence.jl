# --- the compiled executor (§9.7) ---------------------------------------------
# The four phase bodies are the loop's whole surface onto compiled code: a fixed
# roster, total in both arities, and allocation-free however wide the chunked
# walk gets. The tier gating over those same entries is asserted where the rates
# are (`test_multirate.jl`).

const BLOCKS = (:sweep_1, :sweep_2, :rhs, :ticks)   # the four blocks, both arities

function test_executor()
    @testset "the phase-body roster is fixed and total (§9.7)" begin
        sim = Simulation(feedback_model(); h = 1//100)
        b = phase_bodies(sim)
        @test keys(b) === (:sweep_1, :sweep_2, :rhs, :ticks, :events, :projections)
        @test b.ticks() === nothing            # empty body: legal, a no-op
        @test b.ticks(3) === nothing           # and total in both arities
        @test isempty(b.events) && isempty(b.projections)
        for name in BLOCKS
            body = b[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end

        # One stage-1 return over both homes (§5.3): `Motor` returns `ω` from
        # `x` and `running` from `m` in a single `output_state`, so its stage-1
        # block is one `StageEntry` and the canary holds over it.
        mot = Simulation(fed(Motor(1.0), "M_load"); h = 1//100)
        b = phase_bodies(mot)
        walk = walked(b.sweep_1, :interior)
        @test count(e -> e isa StageEntry, walk) == 1
        for name in BLOCKS
            body = b[name]
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
                    inputs = ("ref" => ntuple(i -> "m$(i)/ref", 6),))
        sim = Simulation(six; h = 1//100, chunk_size = 1)
        @test length(sim.exec.bodies.sweep_2.interior) > 16
        for name in BLOCKS
            body = phase_bodies(sim)[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end
    end

    @testset "the event and projection callables ride with the four blocks (§9.7)" begin
        sim = Simulation(Group((; rot = Rotor(), saw = Sawtooth(1.0))); h = 1//100)
        init!(sim)
        b = phase_bodies(sim)
        @test collect(keys(b.events)) == [("saw", :wrap)]
        @test collect(keys(b.projections)) == ["rot"]
        ev = b.events[("saw", :wrap)]
        @test ev.guard() isa Float64           # the sign-form guard over the live bundle
        ev.handler(); b.projections["rot"]()
        for f in (ev.guard, ev.handler, b.projections["rot"])
            @test @ballocated($f()) == 0
        end
    end
end
