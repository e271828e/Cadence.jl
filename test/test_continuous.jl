# --- the continuous skeleton fixture (increment 2) ----------------------------

function continuous_skeleton()
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

# --- auto-published cells at runtime (§5.3, D-016, D-169) ---------------------
# `build.jl`'s file owns the classification; what is asserted here is what the
# cells *hold* once the loop runs them — the store's own value, at every reader.

function continuous_auto_publication()
    @testset "a published cell carries the store, not an integration (§5.3, D-163)" begin
        sim = Simulation(fed(Motor(1.0), "M_load"); h = 1//100)
        # A root input must be covered at `init!` (§14.6, `UninitializedInputs`),
        # and `M_load = 0` is what makes the closed form below exact.
        init!(sim, fragment(inputs = (in = 0.0,)))
        # Boundary zero's `ESTABLISH` round published the authored stores.
        @test port(sim, "c", :ω) == 0.0
        @test port(sim, "c", :running) === false

        run!(sim; t_end = 0.5)
        # `running` flips at `t = 0.1` and `M_shaft` is 1 after it, so with
        # `J = 1` and `M_load = 0` the closed form is `ω(t) = max(t − 0.1, 0)`.
        # The tolerance is RK4's over the ramp, not the semantics' — the event is
        # boundary-detected and `h = 1//100` places 0.1 exactly on the grid, so
        # the crossing costs no localization error of its own.
        @test port(sim, "c", :ω) ≈ 0.4 rtol = 1e-9
        @test port(sim, "c", :running) === true
        # Bitwise, and the one place the suite may be: the claim is that the
        # cell *is* a copy of the store at the boundary, not a second
        # integration of it (D-163's stamp exception).
        @test port(sim, "c", :ω) == state(sim, "c").ω
        @test port(sim, "c", :running) === modes(sim, "c").running
        # A cell is a cell: the snapshot carries the published one (§11.2).
        @test port(latest(sim), "c", :ω) == state(sim, "c").ω
        @test port(latest(sim), "c", :running) === true
    end

    @testset "a loop closed through a published port integrates alike (§5.3, D-169)" begin
        # `AutoPlant` publishes its whole state vector and `StateFeedback` reads
        # it; `feedback_model` closes the same loop through `Sum` and `Gain`
        # with `ref = 0`. Both start off the origin — at `q₀ = 0` and `ref = 0`
        # both trajectories are identically zero and the comparison is vacuous.
        q₀ = SVector(1.0, 0.0)
        a = Simulation(auto_feedback_model(; k = 4.0, q₀); h = 1//100)
        f = Simulation(feedback_model(; k = 4.0, q₀); h = 1//100)
        init!(a)
        init!(f, fragment(inputs = (ref = 0.0,)))
        run!(a; t_end = 2.0)
        run!(f; t_end = 2.0)
        # The same RK4 steps on the same closed loop, so this is exact agreement
        # up to the order the two right-hand sides sum their terms in.
        @test port(a, "plant", :q) ≈ state(f, "plant").q rtol = 1e-12
        @test state(a, "plant").q ≈ state(f, "plant").q rtol = 1e-12
    end
end

function test_continuous()
    continuous_skeleton()
    continuous_auto_publication()
end
