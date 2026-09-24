# --- the stepper seam (§10.2, increment 8) --------------------------------------
# Interchangeability is the claim under test: the loop, the localization
# machinery and the deployment surface are method-blind, and the two backends
# differ exactly where their orders say they must.

function test_stepper()
    @testset "the method is a deployment binding, RK4 the default (§10.2)" begin
        sim = Simulation(feedback_model(); h = 1//100)
        @test sim.exec.stepper isa RK4{Float64}
        heun_sim = Simulation(feedback_model(); h = 1//100, algorithm = Heun)
        @test heun_sim.exec.stepper isa Heun{Float64}
        # validated with its siblings: a backend is named by stepper type, and
        # anything else is refused at binding, not deep in a MethodError
        d = only(diagnostics(failure(() -> Simulation(feedback_model(); h = 1//100, algorithm = 4))))
        @test d isa DeploymentInvalid && d.parameter === :algorithm
        d = only(diagnostics(failure(() -> Simulation(feedback_model(); h = 1//100, algorithm = Int))))
        @test d isa DeploymentInvalid && d.parameter === :algorithm
    end

    @testset "convergence order: each backend is itself — 4 and 2 (§10.2)" begin
        # The sharp form of the interchangeability claim: same model, same loop,
        # same reference, and the fitted order is the method's own. A mislabeled
        # backend cannot sit in both bands, where a shared loose tolerance would
        # let it hide.
        ω, ζ, k, r = 2.0, 0.1, 4.0, 0.7
        A = SMatrix{2,2}(0.0, -ω^2, 1.0, -2ζ * ω)
        B = SVector(0.0, 1.0)
        Acl = A - B * k * SVector(1.0, 0.0)'
        exact(t) = exp(Acl * t) * (Acl \ (B * k * r)) - Acl \ (B * k * r)
        function final_error(algorithm, h)
            sim = Simulation(feedback_model(; k, ω, ζ); h, algorithm)
            init!(sim, fragment(inputs = (ref = r,)))
            run!(sim; t_end = 2.0)
            norm(state(sim, "plant").q - exact(2.0))
        end
        hs = (1//10, 1//20, 1//40, 1//80)   # errors 5e-8..2e-4: well above float noise
        for (algorithm, p) in ((RK4, 4.0), (Heun, 2.0))
            errs = [final_error(algorithm, h) for h in hs]
            orders = [log2(errs[i] / errs[i+1]) for i in 1:3]
            @test all(o -> abs(o - p) < 0.3, orders)
        end
    end

    @testset "localization is seam-generic: t* under Heun (§10.2, §10.4)" begin
        # Linear trajectory: Heun and the Hermite are both exact, so the stamp is
        # method-independent down to the bracket width — the machinery, not the
        # method, sets the error.
        m = Group((; src = Sawtooth(1.0), s = Stamper(0.315));
                  wires = ("src/q" => "s/sig",))
        sim = Simulation(m; h = 1//10, algorithm = Heun)
        init!(sim)
        run!(sim; t_end = 0.5)
        @test modes(sim, "s").count == 1
        @test modes(sim, "s").t_fired ≈ 0.315 atol = 1e-6

        # Nonlinear trajectory: the stamp error is now the discrete solution's
        # O(h²), not RK4's O(h⁴) — quartering under h-halving is the method
        # showing through the same machinery. (Boundary-resolution firing would
        # sit at ~h and shrink linearly instead.)
        stamp_error(h) = begin
            mr = Group((; src = Rotor(; ω = 1.0, r₀ = SVector(-1.0, 0.0)), s = Stamper(-0.5));
                       wires = ("src/c" => "s/sig",))
            rotor_sim = Simulation(mr; h, algorithm = Heun)
            init!(rotor_sim)
            run!(rotor_sim; t_end = 1.5)
            @test modes(rotor_sim, "s").count == 1
            abs(modes(rotor_sim, "s").t_fired - π / 3)
        end
        coarse_error, fine_error = stamp_error(1//10), stamp_error(1//40)
        @test coarse_error < 5e-3
        @test 10 < coarse_error / fine_error < 24               # h²: ×16 over two halvings

        # The frame-top claims never depended on the method: an epoch-caused edge
        # falls through to fire at the indexed grid time bitwise under Heun too.
        fed_sim = Simulation(fed(Stamper(0.5), "sig"); h = 1//10, algorithm = Heun)
        init!(fed_sim, fragment(inputs = (in = 0.0,)))
        step!(fed_sim; t_plus = 0.3)
        stage!(fed_sim, "in" => 1.0)                   # frame 4's drain, at its frame top
        step!(fed_sim; t_plus = 0.3)
        @test modes(fed_sim, "c").t_fired == 4 * fed_sim.deployment.h
    end

    @testset "gate 4: the second backend holds the §7.5 invariant" begin
        sim = Simulation(feedback_model(); h = 1//1000, algorithm = Heun)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        step!(sim, 1e-3)
        @test @ballocated(step!($sim, 1e-3)) == 0
        # The localizing frame allocates exactly its t* boundary's publication —
        # the framework-side carve-out (§7.5, §11.2) — as under RK4 (gate 3).
        bouncer_sim = Simulation(single(Bouncer(1.0, 0.07)); h = 1//10, algorithm = Heun)
        init!(bouncer_sim; log = false)
        pub = @ballocated publish!($bouncer_sim)
        stop_policy, addrs = StopPolicy(Inf, Symbol[]), Any[]   # the advance's arguments (D-260, D-261)
        @test @ballocated(frame!($bouncer_sim, 1, $stop_policy, $addrs), setup = (init!($bouncer_sim; log = false)), evals = 1) == pub
    end

    @testset "the second backend is generic over the scalar (§7.2)" begin
        sim = Simulation(feedback_model(), D8; h = 1//1000, algorithm = Heun)
        init!(sim, fragment(inputs = (ref = D8(0.7),)))
        run!(sim; t_end = 0.05)
        @test state(sim, "plant").q isa SVector{2,D8}
    end
end
