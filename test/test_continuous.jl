# --- the continuous walking skeleton (increment 2) ------------------------------

function continuous_skeleton()
    @testset "the activation walk (§7.2)" begin
        @test retype(D8, Float64) === D8
        @test retype(D8, SVector{3,Float64}) === SVector{3,D8}
        @test retype(D8, Int) === Int
        @test retype(Float64, SVector{2,Float64}) === SVector{2,Float64}
        @test retype_value(D8, (q = SVector(1.0, 2.0),)).q isa SVector{2,D8}
    end

    @testset "the bundle law (§5.2)" begin
        # A name appears iff the store or fact exists: the stateless gain sees no
        # `x`, the no-feedthrough stage sees no `u`, `t` is always there.
        @test bundle_names(h_x, Plant(), CONTINUOUS, ()) === (:x, :t)
        @test bundle_names(h_xu, Plant(), CONTINUOUS, (:y,)) === (:x, :u, :y_x, :t)
        @test bundle_names(f, Plant(), CONTINUOUS, (:y,)) === (:x, :u, :y, :t)
        @test bundle_names(h_xu, Gain(1.0), CONTINUOUS, ()) === (:u, :t)
    end

    @testset "the loop integrates the right trajectory" begin
        # Closed-loop reference: ẋ = (A - B k C) x + B k r, integrated exactly.
        ω, ζ, k, r = 2.0, 0.1, 4.0, 0.7
        A = SMatrix{2,2}(0.0, -ω^2, 1.0, -2ζ * ω)
        B = SVector(0.0, 1.0)
        Acl = A - B * k * SVector(1.0, 0.0)'
        exact(t) = exp(Acl * t) * (Acl \ (B * k * r)) - Acl \ (B * k * r)

        sim = Simulation(feedback_model(; k, ω, ζ); h = 1//1000)
        init!(sim, fragment(inputs = (ref = r,)))
        run!(sim; t_end = 2.0)

        # Tolerance, never `==` (D-163): RK4 truncation dominates at ~1e-12 here.
        @test state(sim, "plant").q ≈ exact(2.0) rtol = 1e-8
        @test port(sim, "plant", :y) ≈ exact(2.0)[1] rtol = 1e-8
        # the table is consistent at the boundary: `power` is a fresh decode
        @test port(sim, "plant", :power) ≈
              port(sim, "ctl", :out) * exact(2.0)[2] rtol = 1e-8
    end

    @testset "the phase-body roster is fixed and total (§9.7)" begin
        sim = Simulation(feedback_model(); h = 1//100)
        b = phase_bodies(sim)
        @test keys(b) === (:sweep_1, :sweep_2, :rhs, :ticks)
        @test b.ticks() === nothing            # empty body: legal, a no-op
        @test b.ticks(3) === nothing           # and total in both arities
        for name in keys(b)
            body = b[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end
    end

    @testset "a simulation owns one executor, and it is the one the loop runs (§9.2, §9.7)" begin
        sim = Simulation(feedback_model(); h = 1//100)
        ex = sim.exec
        @test ex isa Executor{Float64}
        @test ex.act === activation(sim.build, Float64)   # the activation it was compiled from
        @test phase_bodies(sim) === ex.bodies             # the loop's bodies, not a re-derivation

        # The evaluation entry points are the executor's; the `Simulation` forms
        # delegate to the one executor it owns, buffers and all.
        init!(sim, fragment(inputs = (ref = 0.5,)))
        evaluate!(sim)
        ẋ = copy(ex.ẋbuf)
        fill!(ex.ẋbuf, 0.0)
        evaluate!(ex)
        @test ex.ẋbuf == ẋ
        @test @ballocated(evaluate!($ex)) == 0
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
        for name in keys(phase_bodies(sim))
            body = phase_bodies(sim)[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end
    end

    @testset "gate 1: stepping does not allocate (§7.5)" begin
        sim = Simulation(feedback_model(); h = 1//1000)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        step!(sim, 1e-3)
        @test @ballocated(step!($sim, 1e-3)) == 0
        @test @ballocated(evaluate!($sim)) == 0
    end

    @testset "the whole continuous path is generic over the scalar (§7.2)" begin
        sim = Simulation(feedback_model(), D8; h = 1//1000)
        init!(sim, fragment(inputs = (ref = D8(0.7),)))
        run!(sim; t_end = 0.05)
        @test state(sim, "plant").q isa SVector{2,D8}
        @test ForwardDiff.value(port(sim, "plant", :y)) != 0.0
    end

end

function test_continuous()
    continuous_skeleton()
end
