# --- the standard component library (§13.7, §6.2) -------------------------------
# The blocks of `Redstone.Blocks`, each built in a model and read off the
# snapshot: the junction's contract and its folds, the source, the delay, the
# stop-gradient, the integrator, the lag, the step, the limited integrator, the
# relay and the PID, and two loops built from them alone. The models are built
# at top level, like the fixtures they reuse: `RealEntry` and `PinnedEntry` are
# test_build.jl's.

# One gate over three `Constant` sources, at the given input values.
gate_model(gate, (a, b, c)) =
    Group((; a = Constant(a), b = Constant(b), c = Constant(c), g = gate);
          local_wires = ("a/out" => "g/in1", "b/out" => "g/in2", "c/out" => "g/in3"))

# A sum over a walking source, a pinned source and a delayed copy of the first.
blocks_sum_model() =
    Group((; r = Ramp(1.0), k = Constant(2.0), d = UnitDelay(0.5), s = SumJunction{Float64,3}());
          local_wires = ("r/out" => "s/in1", "k/out" => "s/in2", "d/out" => "s/in3",
                         "r/out" => "d/in"))

# A delay behind a tick counter: the counter's `n` is its tick index.
delay_model(v0) = Group((; c = TickCounter(), d = UnitDelay(v0)); local_wires = ("c/n" => "d/in",))

# The pendulum's angle leaving the root twice, once through a freeze.
freeze_model() = Group((; p = Pendulum(), f = Freeze{Float64}());
                       local_wires = ("p/θ" => "f/in",), input_wires = ("τ" => "p/u",),
                       output_wires = ("p/θ" => "direct", "f/out" => "frozen"))

# An integrator from `x0` fed by a constant.
integrator_model(x0, value) =
    Group((; k = Constant(value), i = Integrator(x0 = x0)); local_wires = ("k/out" => "i/in",))

# A lag at `τ = 0.5` from rest, fed by a constant.
lag_model(value) =
    Group((; k = Constant(value), l = FirstOrderLag(τ = 0.5, x0 = zero(value)));
          local_wires = ("k/out" => "l/in",))

# A step into an integrator, which ramps from the instant the jump lands.
step_model(source) = Group((; s = source, i = Integrator()); local_wires = ("s/out" => "i/in",))

# The step's row of the events product.
step_events(model) = only(row for row in build(model).events.components if row.path == "s")

# A block's one-state linearization through the root input `in`.
block_linearization(comp) =
    (sim = Simulation(fed(comp, "in"); h = 1//100);
     init!(sim, fragment(u = (in = 0.0,)));
     linearize(sim, taps(x = (q = get_state("c", :q),), u = (in = get_input(:in),))))

# A limited integrator fed by a step from `1` down to `-1`.
limited_model(localized) =
    Group((; s = Step(t_step = 1.05, before = 1.0, after = -1.0),
             li = LimitedIntegrator(lower = -1.0, upper = 0.5, localized = localized));
          local_wires = ("s/out" => "li/in",))

# A limited integrator fed by the ramp `1.05 - t`, which crosses zero at 1.05
# with slope `-1`.
ramp_limited_model(localized) =
    Group((; k = Constant(-1.0), ramp = Integrator(x0 = 1.05),
             li = LimitedIntegrator(lower = -2.0, upper = 0.4, localized = localized));
          local_wires = ("k/out" => "ramp/in", "ramp/out" => "li/in"))

# The limited integrator's row of the events product.
limited_events(model) = only(row for row in build(model).events.components if row.path == "li")

# A limited integrator whose input falls from `level` to exactly zero at 1.05
# and returns to `level` at 2.05.
zero_input_model(level, lower, upper, localized) =
    Group((; release = Step(t_step = 1.05, before = level, after = 0.0),
             push = Step(t_step = 2.05, before = 0.0, after = level),
             input = SumJunction{Float64, 2}(),
             li = LimitedIntegrator(lower = lower, upper = upper, localized = localized));
          local_wires = ("release/out" => "input/in1", "push/out" => "input/in2",
                         "input/out" => "li/in"))

# A relay reading an integrator that a step drives up, then down.
relay_model() =
    Group((; s = Step(t_step = 1.0, before = 1.0, after = -1.0), i = Integrator(),
             r = Relay(lower = 0.2, upper = 0.8));
          local_wires = ("s/out" => "i/in", "i/out" => "r/in"))

# A vector limited integrator fed by a step: component 2 saturates at 0.4 and
# component 1 at 0.5; after 1.05 component 1 leaves and reaches its lower limit
# at 2.55, while component 2's input is exactly zero and it stays saturated.
vector_limited_model(localized) =
    Group((; s = Step(t_step = 1.05, before = SVector(1.0, 2.0), after = SVector(-1.0, 0.0)),
             li = LimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(0.5, 0.8),
                                    localized = localized));
          local_wires = ("s/out" => "li/in",))

# A vector relay reading a vector integrator: component 1 is `relay_model`'s,
# and component 2 climbs to 0.5 and never reaches its upper threshold.
vector_relay_model() =
    Group((; s = Step(t_step = 1.0, before = SVector(1.0, 0.5), after = SVector(-1.0, -0.5)),
             i = Integrator(x0 = SVector(0.0, 0.0)),
             r = Relay(lower = SVector(0.2, 0.2), upper = SVector(0.8, 0.8)));
          local_wires = ("s/out" => "i/in", "i/out" => "r/in"))

# The servo loop: a reference step, the error, a limited integrator as the
# controller, a lag as the actuator and a lag as the plant, whose `out` leaves
# the root.
servo_loop(localized) =
    Group((; reference = Step(t_step = 0.5), error = Junction{Float64, Float64, 2}(-),
             controller = LimitedIntegrator(lower = -1.2, upper = 1.2, localized = localized),
             actuator = FirstOrderLag(τ = 0.1), plant = FirstOrderLag(τ = 1.0));
          local_wires = ("reference/out" => "error/in1", "plant/out" => "error/in2",
                         "error/out" => "controller/in", "controller/out" => "actuator/in",
                         "actuator/out" => "plant/in"),
          output_wires = ("plant/out" => "out",))

# The bang-bang loop: a relay switching an integrator's input on its output.
bang_bang_loop() =
    Group((; integrator = Integrator(), relay = Relay(lower = 0.2, upper = 0.8, off = 1.0, on = -1.0));
          local_wires = ("relay/out" => "integrator/in", "integrator/out" => "relay/in"))

# The PID at the gains its direct calls and linearizations use, in one spelling.
pid_controller(hold, tracking) =
    PID(Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, Tt = 1.0, u_min = -1.0, u_max = 1.0,
        hold = hold, tracking = tracking)

# A PID as the root's one child: its ports are root inputs, and `u` and `u_raw`
# leave the root.
function pid_root_model(controller::PID{Hold, Track}) where {Hold, Track}
    inputs = ["r" => "controller/r", "y" => "controller/y"]
    Hold && push!(inputs, "saturation" => "controller/saturation")
    Track && push!(inputs, "v" => "controller/v")
    Group((; controller = controller); input_wires = Tuple(inputs),
          output_wires = ("controller/u" => "u", "controller/u_raw" => "u_raw"))
end

# A tracking PID whose `v` is a memoryless clamp of its own `u`, the clamp also
# driving an integrator plant.
pid_clamp_loop() =
    Group((; reference = Step(t_step = 0.5, after = 5.0),
             controller = PID(Kp = 1.0, Ki = 0.5, Kd = 0.2, Tt = 1.0, tracking = true),
             sat = Junction{Float64, Float64, 1}(v -> clamp(v, -1.0, 1.0)), plant = Integrator());
          local_wires = ("reference/out" => "controller/r", "plant/out" => "controller/y",
                         "controller/u" => "sat/in1", "sat/out" => "controller/v",
                         "sat/out" => "plant/in"))

function test_blocks()
    @testset "the junction's arity and port types come from its type (§6.2, D-311)" begin
        @test u_types(Or{3}()) == (in1 = Bool, in2 = Bool, in3 = Bool)
        @test y_types(Or{3}()) == (out = Bool,)
        @test u_types(SumJunction{Float64,2}()) == (in1 = Float64, in2 = Float64)
        @test Junction{Float64,Float64,3}(max) isa Junction{Float64,Float64,3,typeof(max)}
        @test Or{3}() isa Junction && And{2}() isa Junction
        @test typeof(Or{3}()) === Junction{Bool,Bool,3,typeof(|)}
        @test SumJunction{Float64,2}().f === +
        @test y_direct(SumJunction{Float64,2}(), (; u = (in1 = 1.0, in2 = 2.5))) == (out = 3.5,)
        # The fold takes the inputs in positional order (§6.2).
        positional = Junction{Float64,Float64,3}((a, b, c) -> 100a + 10b + c)
        @test y_direct(positional, (; u = (in1 = 1.0, in2 = 2.0, in3 = 3.0))) == (out = 123.0,)
    end

    @testset "the gates fold their inputs at `|` and `&` (§13.7, D-311)" begin
        for (gate, truth) in ((Or{3}(), any), (And{3}(), all)),
            inputs in ((true, false, false), (false, true, true), (true, true, true),
                       (false, false, false))
            sim = Simulation(gate_model(gate, inputs); h = 1//100)
            init!(sim, fragment())
            @test port(sim, "g", :out) === truth(inputs)
        end
    end

    @testset "the sum adds a walking, a pinned and a delayed cell (§6.2, §6.1)" begin
        sim = Simulation(blocks_sum_model(); h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 3//100)
        cells = (port(sim, "r", :out), port(sim, "k", :out), port(sim, "d", :out))
        @test port(sim, "s", :out) == +(cells...)
        @test port(sim, "d", :out) ≈ 1.02 atol = 1e-12    # the ramp one tick back
        # The pinned producers feed the tolerant entries under a `Dual` activation.
        @test build(blocks_sum_model(); activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the delay publishes its input one tick late, and `v0` first (§13.7, D-312)" begin
        sim = Simulation(delay_model(-1); h = 1//100)
        init!(sim, fragment())
        @test port(sim, "c", :n) == 0 && port(sim, "d", :out) == -1
        for k in 1:4
            step!(sim; t_plus = 1//100)
            @test port(sim, "c", :n) == k && port(sim, "d", :out) == k - 1
        end
        # The store is isbits by rule (D-231), which bounds `V`.
        err = failure(() -> build(delay_model([1.0])))
        @test err isa DiagnosticError && only(diagnostics(err)) isa IllegalStoreField
    end

    @testset "the freeze drops the partials, and nothing else (§13.7, D-312)" begin
        sim = Simulation(freeze_model(); h = 1//10)
        init!(sim, combine(at("p", condition(Pendulum(); θ = 0.3)), fragment(u = (τ = 0.0,))))
        @test port(sim, "f", :out) == port(sim, "p", :θ) == 0.3
        linearization = linearize(sim, taps(x = (θ = get_state("p", :θ), ω = get_state("p", :ω)),
                                            u = (τ = get_input(:τ),),
                                            y = (direct = get_face(:direct), frozen = get_face(:frozen))))
        @test linearization.y_labels == (:direct, :frozen)
        @test isapprox(linearization.C[1, :], [1, 0]; atol = 1e-12)
        @test iszero(linearization.C[2, :])
        # Its purpose (§13.7, D-266): unfrozen, this wire is refused with `WalkingFaceAtFrozenEntry`.
        model = Group((; p = Pendulum(), f = Freeze{Float64}(), e = PinnedEntry());
                      local_wires = ("p/θ" => "f/in", "f/out" => "e/u"), input_wires = ("τ" => "p/u",))
        @test build(model; activations = (Float64, LinearizeDual)) isa Build
        # `V` is a `Real` or a `StaticArray` of them, constrained at the type.
        @test_throws TypeError Freeze{HeightField}
    end

    @testset "a `Constant` spells the zero contributor into either entry (§6.2, D-312)" begin
        @test y_types(Constant(0.0)) == (out = Pinned{Float64},)
        for consumer in (RealEntry(), PinnedEntry())
            model = Group((; k = Constant(0.0), e = consumer); local_wires = ("k/out" => "e/u",))
            @test build(model) isa Build
            @test build(model; activations = (Float64, LinearizeDual)) isa Build
        end
    end

    @testset "the sum model's phase bodies allocate nothing (§7.5)" begin
        sim = Simulation(blocks_sum_model(); h = 1//100)
        bodies = phase_bodies(sim)
        for name in (:sweep_1, :sweep_2, :rhs, :ticks)
            body = bodies[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end
    end

    @testset "the integrator integrates its input, scalar or vector, and linearizes to A = 0, B = 1 (§13.7, §7.2)" begin
        sim = Simulation(integrator_model(1.0, 2.0); h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 0.5)
        @test state(sim, "i").q ≈ 2.0 atol = 1e-12
        @test port(sim, "i", :out) == state(sim, "i").q
        vector_sim = Simulation(integrator_model(SVector(0.0, 1.0), SVector(1.0, -1.0)); h = 1//100)
        init!(vector_sim, fragment())
        step!(vector_sim; t_plus = 0.5)
        @test isapprox(state(vector_sim, "i").q, SVector(0.5, 0.5); atol = 1e-12)
        linearization = block_linearization(Integrator())
        @test isapprox(linearization.A, [0.0;;]; atol = 1e-12)
        @test isapprox(linearization.B, [1.0;;]; atol = 1e-12)
    end

    @testset "the lag relaxes to its input at 1/τ, and linearizes to A = -1/τ, B = 1/τ (§13.7, §7.2)" begin
        sim = Simulation(lag_model(1.0); h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 1.0)
        @test state(sim, "l").q ≈ 1 - exp(-2) rtol = 1e-7
        @test port(sim, "l", :out) == state(sim, "l").q
        vector_sim = Simulation(lag_model(SVector(1.0, -2.0)); h = 1//100)
        init!(vector_sim, fragment())
        step!(vector_sim; t_plus = 1.0)
        @test isapprox(state(vector_sim, "l").q, (1 - exp(-2)) * SVector(1.0, -2.0); rtol = 1e-7)
        linearization = block_linearization(FirstOrderLag(τ = 0.5))
        @test isapprox(linearization.A, [-2.0;;]; atol = 1e-12)
        @test isapprox(linearization.B, [2.0;;]; atol = 1e-12)
        # The time constant is pinned at `Float64` whatever the keyword's type.
        @test FirstOrderLag(τ = 1) isa FirstOrderLag{Float64}
    end

    @testset "the localized step jumps at the crossing (§2.1, §10.4, D-179)" begin
        sim = Simulation(step_model(Step(t_step = 0.25)); h = 1//10)
        init!(sim, fragment())
        step!(sim; t_plus = 0.2)
        @test port(sim, "s", :out) == 0.0 && state(sim, "i").q == 0.0
        step!(sim; t_plus = 0.1)
        bracket_width = sim.deployment.localization_tol * sim.deployment.h    # in time (§10.4)
        @test state(sim, "i").q ≈ 0.05 atol = bracket_width
        @test port(sim, "s", :out) == 1.0
        @test step_events(step_model(Step(t_step = 0.25))).policies === (fire = :localized,)
    end

    @testset "the boundary-detected step jumps at the first boundary at or after `t_step` (§2.1, §10.4, D-179)" begin
        sim = Simulation(step_model(Step(t_step = 0.25, localized = false)); h = 1//10)
        init!(sim, fragment())
        step!(sim; t_plus = 0.2)
        @test port(sim, "s", :out) == 0.0
        step!(sim; t_plus = 0.1)
        @test state(sim, "i").q == 0.0    # nothing lands inside the step
        @test port(sim, "s", :out) == 1.0
        step!(sim; t_plus = 0.1)
        @test state(sim, "i").q ≈ 0.1 atol = 1e-12
        @test step_events(step_model(Step(t_step = 0.25, localized = false))).policies === (fire = :boundary,)
    end

    @testset "a step at or before t₀ publishes `after` from boundary zero (§10.6)" begin
        for localized in (true, false), t_step in (0.0, -1.0)
            sim = Simulation(single(Step(t_step = t_step, localized = localized)); h = 1//10)
            init!(sim, fragment())
            @test modes(sim, "c").fired && port(sim, "c", :out) == 1.0
        end
    end

    @testset "the step switches a vector, and its keywords promote (§13.7)" begin
        @test y_types(Step(t_step = 1.0)) == (out = Pinned{Float64},)    # D-312
        source = Step(t_step = 0.25, before = SVector(0.0, 0.0), after = SVector(1.0, -1.0))
        sim = Simulation(single(source); h = 1//10)
        init!(sim, fragment())
        @test port(sim, "c", :out) == SVector(0.0, 0.0)
        step!(sim; t_plus = 0.3)
        @test port(sim, "c", :out) == SVector(1.0, -1.0)
        @test Step(t_step = 0.25, after = 2) isa Step{Float64, true}
        @test build(step_model(Step(t_step = 0.25)); activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the step model's phase bodies and its quiet boundary allocate nothing (§7.5)" begin
        for localized in (true, false)
            sim = Simulation(step_model(Step(t_step = 0.25, localized = localized)); h = 1//10)
            bodies = phase_bodies(sim)
            for name in (:sweep_1, :sweep_2, :rhs, :ticks)
                body = bodies[name]
                body(); body(0)
                @test @ballocated($body()) == 0
                @test @ballocated($body(1)) == 0
            end
            init!(sim, fragment())
            boundary!(sim, 1); offtick_boundary!(sim)
            @test @ballocated(boundary!($sim, 1)) == 0
            @test @ballocated(offtick_boundary!($sim)) == 0
        end
    end

    @testset "the limited integrator saturates exactly, frees on its input's sign, and linearizes by its mode (§10.4, §10.6, D-313)" begin
        @test y_types(LimitedIntegrator(lower = -1.0, upper = 0.5)) == (out = Float64, saturation = Int8)
        # The step's jump carries its own boundary, so the boundary-detected
        # departure fires there too.
        for localized in (true, false)
            sim = Simulation(limited_model(localized); h = 1//10)
            init!(sim, fragment())
            step!(sim; t_plus = 0.7)
            @test state(sim, "li").q == 0.5 && modes(sim, "li").saturation === Int8(1)
            @test port(sim, "li", :saturation) === modes(sim, "li").saturation
            step!(sim; t_plus = 1.3)
            bracket_width = sim.deployment.localization_tol * sim.deployment.h    # in time (§10.4)
            @test state(sim, "li").q ≈ -0.45 atol = bracket_width
            @test modes(sim, "li").saturation === Int8(0)
            @test port(sim, "li", :saturation) === modes(sim, "li").saturation
            step!(sim; t_plus = 1.0)
            @test state(sim, "li").q == -1.0 && modes(sim, "li").saturation === Int8(-1)
            @test port(sim, "li", :saturation) === modes(sim, "li").saturation
        end
        # The derivative reads the mode, so the Jacobian does too.
        @test isapprox(block_linearization(LimitedIntegrator(lower = -1.0, upper = 0.5)).B, [1.0;;]; atol = 1e-12)
        rig = Simulation(fed(LimitedIntegrator(lower = -1.0, upper = 0.5), "in"); h = 1//10)
        init!(rig, fragment(u = (in = 1.0,)))
        step!(rig; t_plus = 0.7)
        @test state(rig, "c").q == 0.5 && modes(rig, "c").saturation === Int8(1)
        linearization = linearize(rig, taps(x = (q = get_state("c", :q),), u = (in = get_input(:in),)))
        @test isapprox(linearization.B, [0.0;;]; atol = 1e-12)
        # An `x0` outside the limits is clamped at boundary zero (§10.6).
        clamped = Simulation(fed(LimitedIntegrator(x0 = 2.0, lower = -1.0, upper = 0.5), "in"); h = 1//10)
        init!(clamped, fragment(u = (in = 1.0,)))
        @test state(clamped, "c").q == 0.5 && modes(clamped, "c").saturation === Int8(1)
        clamped_lower = Simulation(fed(LimitedIntegrator(x0 = -2.0, lower = -1.0, upper = 0.5), "in"); h = 1//10)
        init!(clamped_lower, fragment(u = (in = -1.0,)))
        @test state(clamped_lower, "c").q == -1.0 && modes(clamped_lower, "c").saturation === Int8(-1)
        @test LimitedIntegrator(lower = -1, upper = 0.5) isa LimitedIntegrator{Float64}
        @test LimitedIntegrator(lower = -1, upper = 0.5).x0 === 0.0
    end

    @testset "an input of exactly zero at a limit keeps the limited integrator saturated (§10.4, D-313)" begin
        # Freed at the zero, `q` would pass the limit at the return with no edge.
        for (level, lower, upper, limit, saturation) in ((1.0, -1.0, 0.5, 0.5, Int8(1)),
                                                         (-1.0, -0.5, 1.0, -0.5, Int8(-1))),
            localized in (true, false)
            sim = Simulation(zero_input_model(level, lower, upper, localized); h = 1//10)
            init!(sim, fragment())
            step!(sim; t_plus = 3.0)
            @test state(sim, "li").q == limit && modes(sim, "li").saturation === saturation
        end
    end

    @testset "the vector limited integrator saturates and frees each component on its own (§10.4, §10.6, D-313)" begin
        # The step's jump carries its own boundary, so the boundary-detected
        # departure fires there too. At 0.4 only component 2 is clamped, which
        # tells a handler writing its one component from one writing them all;
        # from 1.05 component 2's input is exactly zero, which tells a leave
        # guard reading its own component from one reading the first.
        for localized in (true, false)
            sim = Simulation(vector_limited_model(localized); h = 1//10)
            init!(sim, fragment())
            step!(sim; t_plus = 0.4)
            @test state(sim, "li").q[1] ≈ 0.4 atol = 1e-12
            @test state(sim, "li").q[2] == 0.8
            @test modes(sim, "li").saturation == SVector{2, Int8}(0, 1)
            @test port(sim, "li", :saturation) === modes(sim, "li").saturation
            step!(sim; t_plus = 0.3)
            @test state(sim, "li").q == SVector(0.5, 0.8)
            @test modes(sim, "li").saturation == SVector{2, Int8}(1, 1)
            @test port(sim, "li", :saturation) === modes(sim, "li").saturation
            step!(sim; t_plus = 1.3)
            bracket_width = sim.deployment.localization_tol * sim.deployment.h    # in time (§10.4)
            @test state(sim, "li").q[1] ≈ -0.45 atol = bracket_width
            @test state(sim, "li").q[2] == 0.8
            @test modes(sim, "li").saturation == SVector{2, Int8}(0, 1)
            @test port(sim, "li", :saturation) === modes(sim, "li").saturation
            step!(sim; t_plus = 1.0)
            @test state(sim, "li").q == SVector(-1.0, 0.8)
            @test modes(sim, "li").saturation == SVector{2, Int8}(-1, 1)
            @test port(sim, "li", :saturation) === modes(sim, "li").saturation
        end
        @test y_types(LimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(0.5, 0.8))) ==
              (out = SVector{2, Float64}, saturation = SVector{2, Int8})
        @test build(vector_limited_model(true); activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the limited integrator's departures follow `localized`, and its arrivals are localized (§2.1, §10.4, D-179)" begin
        @test limited_events(limited_model(true)).policies ===
              (hit_upper = :localized, hit_lower = :localized, leave_upper = :localized, leave_lower = :localized)
        @test limited_events(limited_model(false)).policies ===
              (hit_upper = :localized, hit_lower = :localized, leave_upper = :boundary, leave_lower = :boundary)
        # Over a vector, `N` copies of each event, in the scalar order.
        @test limited_events(vector_limited_model(true)).policies ===
              (hit_upper_1 = :localized, hit_upper_2 = :localized, hit_lower_1 = :localized,
               hit_lower_2 = :localized, leave_upper_1 = :localized, leave_upper_2 = :localized,
               leave_lower_1 = :localized, leave_lower_2 = :localized)
        @test limited_events(vector_limited_model(false)).policies ===
              (hit_upper_1 = :localized, hit_upper_2 = :localized, hit_lower_1 = :localized,
               hit_lower_2 = :localized, leave_upper_1 = :boundary, leave_upper_2 = :boundary,
               leave_lower_1 = :boundary, leave_lower_2 = :boundary)
    end

    @testset "the boundary-detected departure is off by at most `a h² / 2` (§2.1, §10.4)" begin
        # The block reaches 0.4 at t = 0.5 and leaves it at the input's zero, 1.05,
        # or at the boundary 1.1: θ = 0.5 and a = 1, so the offset is
        # a h² (1 - θ)² / 2 = 0.00125.
        localized_sim = Simulation(ramp_limited_model(true); h = 1//10)
        init!(localized_sim, fragment())
        step!(localized_sim; t_plus = 3.0)
        bracket_width = localized_sim.deployment.localization_tol * localized_sim.deployment.h    # in time (§10.4)
        @test state(localized_sim, "li").q ≈ 0.4 - 1.95^2 / 2 atol = bracket_width
        boundary_sim = Simulation(ramp_limited_model(false); h = 1//10)
        init!(boundary_sim, fragment())
        step!(boundary_sim; t_plus = 3.0)
        @test state(boundary_sim, "li").q ≈ -1.5 atol = 1e-12    # RK4 is exact on the quadratic
        @test 0 < state(boundary_sim, "li").q - state(localized_sim, "li").q ≤ 0.1^2 / 2
    end

    @testset "the relay switches with hysteresis, from boundary zero on (§10.4, §10.6, D-313)" begin
        @test y_types(Relay(lower = 0.0, upper = 1.0)) == (out = Pinned{Float64},)    # D-312
        sim = Simulation(relay_model(); h = 1//10)
        init!(sim, fragment())
        # At t = 0.5, 0.9, 1.5 (inside the band, still on) and 1.9.
        for (t_plus, out, relay_state) in ((0.5, 0.0, Int8(0)), (0.4, 1.0, Int8(1)), (0.6, 1.0, Int8(1)),
                                            (0.4, 0.0, Int8(0)))
            step!(sim; t_plus = t_plus)
            @test port(sim, "r", :out) == out && modes(sim, "r").state === relay_state
        end
        for (value, relay_state) in ((1.0, Int8(1)), (0.5, Int8(0)))
            model = Group((; k = Constant(value), r = Relay(lower = 0.2, upper = 0.8));
                          local_wires = ("k/out" => "r/in",))
            constant_sim = Simulation(model; h = 1//10)
            init!(constant_sim, fragment())
            @test modes(constant_sim, "r").state === relay_state
        end
    end

    @testset "the vector relay switches each component with its own hysteresis (§10.4, §10.6, D-313)" begin
        @test y_types(Relay(lower = SVector(0.2, 0.2), upper = SVector(0.8, 0.8))) ==
              (out = Pinned{SVector{2, Float64}},)    # D-312
        sim = Simulation(vector_relay_model(); h = 1//10)
        init!(sim, fragment())
        # At t = 0.5, 0.9, 1.5 and 1.9; component 2 never reaches 0.8.
        for (t_plus, out, relay_state) in ((0.5, SVector(0.0, 0.0), SVector{2, Int8}(0, 0)),
                                           (0.4, SVector(1.0, 0.0), SVector{2, Int8}(1, 0)),
                                           (0.6, SVector(1.0, 0.0), SVector{2, Int8}(1, 0)),
                                           (0.4, SVector(0.0, 0.0), SVector{2, Int8}(0, 0)))
            step!(sim; t_plus = t_plus)
            @test port(sim, "r", :out) == out && modes(sim, "r").state == relay_state
        end
        model = Group((; k = Constant(SVector(1.0, 0.5)), r = Relay(lower = SVector(0.2, 0.2), upper = SVector(0.8, 0.8)));
                      local_wires = ("k/out" => "r/in",))
        constant_sim = Simulation(model; h = 1//10)
        init!(constant_sim, fragment())
        @test modes(constant_sim, "r").state == SVector{2, Int8}(1, 0)
    end

    @testset "the PID's ports follow its two parameters (§13.7, D-313)" begin
        @test u_types(PID(Kp = 1.0)) == (r = Float64, y = Float64)
        @test u_types(PID(Kp = 1.0, hold = true)) == (r = Float64, y = Float64, saturation = Int8)
        @test u_types(PID(Kp = 1.0, tracking = true)) == (r = Float64, y = Float64, v = Float64)
        @test u_types(PID(Kp = 1.0, hold = true, tracking = true)) ==
              (r = Float64, y = Float64, saturation = Int8, v = Float64)
        @test y_types(PID(Kp = 1.0)) == (u = Float64, u_raw = Float64)
        @test PID(Kp = 1.0, hold = true, tracking = true) isa PID{true, true}
    end

    @testset "the PID's law gates the error on the code's sign and falls back to `u` on a free path (§13.7, D-313)" begin
        # `u_raw = 2.5 + 0.3 - 0.8`, clamped to `u = 1`; `Ki e = 1.25`, and the
        # correction reads `1 - 2` against `u` or `0.7 - 2` against `v`.
        x = (q = 0.3, yf = 0.1)
        y = (u = 1.0, u_raw = 2.0)
        for (hold, tracking, u, q_deriv) in
                ((false, false, (r = 3.0, y = 0.5), 0.25),
                 (true, false, (r = 3.0, y = 0.5, saturation = Int8(1)), -1.0),    # the gate holds
                 (true, false, (r = 3.0, y = 0.5, saturation = Int8(-1)), 0.25),
                 (true, false, (r = 3.0, y = 0.5, saturation = Int8(0)), 0.25),
                 (false, true, (r = 3.0, y = 0.5, v = 0.7), -0.05),
                 (true, true, (r = 3.0, y = 0.5, saturation = Int8(1), v = 0.7), -1.3),
                 (true, true, (r = 3.0, y = 0.5, saturation = Int8(0), v = 0.7), 0.25))    # the fallback
            controller = pid_controller(hold, tracking)
            outputs = y_direct(controller, (; x, u))
            @test outputs.u_raw ≈ 2.0 atol = 1e-12
            @test outputs.u == 1.0
            deriv = x_deriv(controller, (; x, u, y))
            @test deriv.q ≈ q_deriv atol = 1e-12
            @test deriv.yf == 4.0
        end
    end

    @testset "the PID's four spellings linearize by the law and walk under `Dual` (§13.7, §7.2, D-313)" begin
        # Inside the limits the own correction is zero and the gate passes the
        # error, so only the ungated tracking variant adds the pole `-1/Tt`.
        plain_matrices = (A = [0.0 0.0; 0.0 -10.0], B = [0.5 -0.5; 0.0 10.0], C = [1.0 2.0], D = [1.0 -3.0])
        tracking_matrices = (A = [-1.0 -2.0; 0.0 -10.0], B = [-0.5 2.5 1.0; 0.0 10.0 0.0],
                             C = [1.0 2.0], D = [1.0 -3.0 0.0])
        both_matrices = (A = plain_matrices.A, B = [0.5 -0.5 0.0; 0.0 10.0 0.0],
                         C = plain_matrices.C, D = [1.0 -3.0 0.0])
        for (hold, tracking, inputs, expected) in
                ((false, false, (r = 0.0, y = 0.0), plain_matrices),
                 (true, false, (r = 0.0, y = 0.0, saturation = Int8(0)), plain_matrices),
                 (false, true, (r = 0.0, y = 0.0, v = 0.0), tracking_matrices),
                 (true, true, (r = 0.0, y = 0.0, saturation = Int8(0), v = 0.0), both_matrices))
            model = pid_root_model(pid_controller(hold, tracking))
            @test build(model; activations = (Float64, LinearizeDual)) isa Build
            sim = Simulation(model; h = 1//100)
            init!(sim, fragment(u = inputs))
            real_inputs = tracking ? (r = get_input(:r), y = get_input(:y), v = get_input(:v)) :
                                     (r = get_input(:r), y = get_input(:y))
            linearization = linearize(sim, taps(x = (q = get_state("controller", :q), yf = get_state("controller", :yf)),
                                                u = real_inputs, y = (u = get_face(:u),)))
            @test isapprox(linearization.A, expected.A; atol = 1e-12)
            @test isapprox(linearization.B, expected.B; atol = 1e-12)
            @test isapprox(linearization.C, expected.C; atol = 1e-12)
            @test isapprox(linearization.D, expected.D; atol = 1e-12)
        end
    end

    @testset "a tracking input wired from a clamp of the PID's own output closes an artificial cycle (§5.4)" begin
        # `u` is a stage-2 output, so `v` makes a feedthrough edge though only the
        # derivative reads it. The limits live inside the block for this reason.
        err = failure(() -> build(pid_clamp_loop()))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :artificial
        @test d.dead == [("controller", :v, :u)]
        @test d.wires == ["controller/u" => "sat/in1", "sat/out" => "controller/v"]
    end

    @testset "the bang-bang loop builds with no algebraic loop and cycles between the thresholds (§5.3, §13.7)" begin
        @test build(bang_bang_loop()) isa Build
        @test build(bang_bang_loop(); activations = (Float64, LinearizeDual)) isa Build
        sim = Simulation(bang_bang_loop(); h = 1//10)
        init!(sim, fragment())
        step!(sim; t_plus = 5.0)
        bracket_width = sim.deployment.localization_tol * sim.deployment.h    # in time, at slope 1
        @test 0.2 - bracket_width ≤ state(sim, "integrator").q ≤ 0.8 + bracket_width
    end

    @testset "the servo loop saturates its controller, leaves the limit and settles on its reference (§13.7)" begin
        @test build(servo_loop(true); activations = (Float64, LinearizeDual)) isa Build
        sim = Simulation(servo_loop(true); h = 1//100)
        init!(sim, fragment())
        # To t = 1, 2, 2.5, 4, 5, 10 and 40: the controller hits its upper limit
        # near t = 2.04 and leaves it near t = 3.15.
        for (t_plus, saturation) in ((1.0, Int8(0)), (1.0, Int8(0)), (0.5, Int8(1)), (1.5, Int8(0)),
                                     (1.0, Int8(0)), (5.0, Int8(0)), (30.0, Int8(0)))
            step!(sim; t_plus = t_plus)
            @test state(sim, "controller").q ≤ 1.2
            @test modes(sim, "controller").saturation === saturation
        end
        @test port(sim, "plant", :out) ≈ 1.0 atol = 1e-3
        # Boundary-detected, the departure moves by up to one step.
        boundary_sim = Simulation(servo_loop(false); h = 1//100)
        init!(boundary_sim, fragment())
        step!(boundary_sim; t_plus = 40.0)
        @test port(boundary_sim, "plant", :out) ≈ 1.0 atol = 1e-3
    end

    @testset "every keyword constructor builds a `Float64` block from integer keywords (§7.2)" begin
        @test Integrator(x0 = 1) isa Integrator{Float64}
        @test FirstOrderLag(τ = 1, x0 = 1) isa FirstOrderLag{Float64}
        @test Step(t_step = 0.25, before = 0, after = 2) isa Step{Float64, true}
        @test LimitedIntegrator(lower = -1, upper = 1) isa LimitedIntegrator{Float64}
        @test LimitedIntegrator(lower = -1, upper = 1, localized = false) isa LimitedIntegrator{Float64, false}
        @test Relay(lower = 0, upper = 1) isa Relay{Float64}
        @test LimitedIntegrator(lower = SVector(-1, -1), upper = SVector(1, 1)) isa
              LimitedIntegrator{SVector{2, Float64}, true}
        @test PID(Kp = 1) isa PID{false, false}
        @test all(field -> getfield(PID(Kp = 1), field) isa Float64, fieldnames(PID))
    end

    @testset "the loops' phase bodies and their quiet boundaries allocate nothing (§7.5)" begin
        for model in (servo_loop(true), servo_loop(false), bang_bang_loop(),
                      vector_limited_model(true), vector_limited_model(false), vector_relay_model())
            sim = Simulation(model; h = 1//10)
            bodies = phase_bodies(sim)
            for name in (:sweep_1, :sweep_2, :rhs, :ticks)
                body = bodies[name]
                body(); body(0)
                @test @ballocated($body()) == 0
                @test @ballocated($body(1)) == 0
            end
            init!(sim, fragment())
            boundary!(sim, 1); offtick_boundary!(sim)
            @test @ballocated(boundary!($sim, 1)) == 0
            @test @ballocated(offtick_boundary!($sim)) == 0
        end
    end

    @testset "every block passes the shadowing check from its own module (§8.1, D-246, D-313)" begin
        # The reason `Blocks` is a submodule: its parent module is `Blocks`, which
        # reaches the declarations by import alone, as a user's component file
        # does, so a missing import here would surface as `DeclarationShadowed`.
        for comp in (Or{3}(), And{2}(), SumJunction{Float64,2}(), Junction{Float64,Float64,2}(max),
                     Constant(1.0), UnitDelay(0.0), Freeze{Float64}(),
                     Integrator(), FirstOrderLag(τ = 1.0), Step(t_step = 1.0),
                     Step(t_step = 1.0, localized = false), LimitedIntegrator(lower = -1.0, upper = 1.0),
                     LimitedIntegrator(lower = -1.0, upper = 1.0, localized = false),
                     Relay(lower = 0.2, upper = 0.8),
                     LimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(1.0, 1.0)),
                     LimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(1.0, 1.0), localized = false),
                     Relay(lower = SVector(0.2, 0.2), upper = SVector(0.8, 0.8)),
                     PID(Kp = 1.0), PID(Kp = 1.0, hold = true), PID(Kp = 1.0, tracking = true),
                     PID(Kp = 1.0, hold = true, tracking = true), Group((; k = Constant(1.0))))
            @test parentmodule(typeof(comp)) === Redstone.Blocks
            @test isempty(foreign_declarations(comp))
            @test build(comp) isa Build
        end
    end

    @testset "the rig satisfies an abstract entry with a stub and surfaces the rest (§13.7, §8.2)" begin
        # Alone, the leaf's abstract entry becomes a root input nothing types.
        d = only(diagnostics(failure(() -> build(TerrainGain()))))
        @test d isa AbstractAtRoot && d.face === :terrain
        rig = TerrainRig()
        @test build(rig).structure.root_inputs == [:var"dut.k"]
        sim = Simulation(rig; h = 1//100)
        init!(sim, fragment(u = (var"dut.k" = 2.0,)))
        @test port(sim, "dut", :h) == rig.stub.value.h0 * 2
    end
end
