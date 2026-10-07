# --- the standard component library (§13.7, §6.2) -------------------------------
# The blocks of `Redstone.Blocks`, each built in a model and read off the
# snapshot: the junction's contract and its folds, the source, the delay, the
# stop-gradient, the integrator, the lag, the state space, the transfer function,
# the step, the limited integrator, the relay and the PID, the PID assembled from
# blocks, and the loops built from them alone. The models are built at top level,
# like the fixtures they reuse: `RealEntry` and `PinnedEntry` are test_build.jl's.

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

# The two-state state space with two inputs and two outputs, strictly proper.
two_state_block() = StateSpace(A = [-1 0.5; 0 -2], B = [1 0.5; 0 1], C = [1 2; 0 1])

# A linear block fed by a constant.
linear_model(block, value) = Group((; k = Constant(value), c = block); local_wires = ("k/out" => "c/in",))

# A linear block under the root faces `in` and `out`.
linear_root_model(block) =
    Group((; c = block); input_wires = ("in" => "c/in",), output_wires = ("c/out" => "out",))

# A unit-feedback loop through a difference junction around a scalar linear
# block, or around a scalar state space whose direct term is `D`.
feedback_loop(plant) =
    Group((; r = Constant(1.0), e = Junction{Float64, Float64, 2}(-), p = plant);
          local_wires = ("r/out" => "e/in1", "p/out" => "e/in2", "e/out" => "p/in"))
feedback_loop(D::Real) = feedback_loop(StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], D = [D;;]))

# The transfer functions: the lag `1/(0.5s + 1)`, the lead-lag `(s + 2)/(s + 5)`
# and the second-order `4/(s² + 1.2s + 4)`.
lag_form() = TransferFunction(num = (1,), den = (0.5, 1))
lead_lag() = TransferFunction(num = (1, 2), den = (1, 5))
second_order() = TransferFunction(num = (4,), den = (1, 1.2, 4))

# The lag form beside the lag block at the same time constant, both fed by one
# constant.
lag_pair_model() =
    Group((; k = Constant(1.0), tf = lag_form(), l = FirstOrderLag(τ = 0.5));
          local_wires = ("k/out" => "tf/in", "k/out" => "l/in"))

# The lead-lag driving a lag plant in a unit-feedback loop.
lead_lag_loop() =
    Group((; r = Constant(1.0), e = Junction{Float64, Float64, 2}(-), controller = lead_lag(),
             plant = FirstOrderLag(τ = 1.0));
          local_wires = ("r/out" => "e/in1", "plant/out" => "e/in2", "e/out" => "controller/in",
                         "controller/out" => "plant/in"))

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

# The PID's first variant as library blocks, the inspector's example beside
# the block: the integrator is what splits the stages (§5.4).
pid_assembly(; Kp, Ki, Kd, τd, Tt, u_min, u_max) = Group((
        err = Junction{Float64, Float64, 2}((r, y) -> r - y),
        lag = FirstOrderLag(; τ = τd),
        der = Junction{Float64, Float64, 2}((y, yf) -> (y - yf) / τd),
        int = Integrator(),
        raw = Junction{Float64, Float64, 3}((e, q, rate) -> Kp * e + q - Kd * rate),
        sat = Junction{Float64, Float64, 1}(v -> clamp(v, u_min, u_max)),
        aw  = Junction{Float64, Float64, 3}((e, u, u_raw) -> Ki * e + (u - u_raw) / Tt));
      input_wires  = ("r" => "err/in1", "y" => ("err/in2", "lag/in", "der/in1")),
      local_wires  = ("lag/out" => "der/in2",
                      "err/out" => "raw/in1", "int/out" => "raw/in2", "der/out" => "raw/in3",
                      "raw/out" => "sat/in1",
                      "err/out" => "aw/in1", "sat/out" => "aw/in2", "raw/out" => "aw/in3",
                      "aw/out" => "int/in"),
      output_wires = ("sat/out" => "u", "raw/out" => "u_raw"))

# A single loop on the own limits: the controller drives an integrator plant.
pid_single_loop(controller) = Group((
        reference = Step(t_step = 0.5, after = 5.0), controller = controller, plant = Integrator());
      local_wires = ("reference/out" => "controller/r", "plant/out" => "controller/y",
                     "controller/u" => "plant/in"),
      output_wires = ("plant/out" => "y",))

# A servo loop: a first-order position servo limited at ±1 between the
# controller and the plant, whose position the controller tracks.
pid_servo_loop(controller) = Group((
        reference = Step(t_step = 0.5, after = 5.0), controller = controller,
        servo_error = Junction{Float64, Float64, 2}(-),
        servo = LimitedIntegrator(lower = -1.0, upper = 1.0), plant = Integrator());
      local_wires = ("reference/out" => "controller/r", "plant/out" => "controller/y",
                     "controller/u" => "servo_error/in1", "servo/out" => "servo_error/in2",
                     "servo_error/out" => "servo/in", "servo/out" => "controller/v",
                     "servo/out" => "plant/in"),
      output_wires = ("plant/out" => "y",))

# A cascade: the controller sets a velocity servo's reference and reads the
# position that integrates the velocity; `hold` wires the inner block's
# saturation into the controller, `tracking` the velocity into `v`.
function pid_cascade(controller; hold = false, tracking = false)
    wires = Pair{String, String}[
        "reference/out" => "controller/r", "position/out" => "controller/y",
        "controller/u" => "error/in1", "velocity/out" => "error/in2",
        "error/out" => "inner/in", "inner/out" => "actuator/in",
        "actuator/out" => "velocity/in", "velocity/out" => "position/in"]
    hold && push!(wires, "inner/saturation" => "controller/saturation")
    tracking && push!(wires, "velocity/out" => "controller/v")
    Group((reference = Step(t_step = 0.5, after = 5.0), controller = controller,
           error = Junction{Float64, Float64, 2}(-), inner = LimitedIntegrator(lower = -1.2, upper = 1.2),
           actuator = FirstOrderLag(τ = 0.1), velocity = FirstOrderLag(τ = 1.0), position = Integrator());
          local_wires = Tuple(wires), output_wires = ("position/out" => "y",))
end

# A loop run at `h = 1//100` and sampled every 0.1 up to `t_end`: `read(sim)`
# at each sample.
function loop_samples(read, model, t_end)
    sim = Simulation(model; h = 1//100)
    init!(sim, fragment())
    [(step!(sim; frames = 10); read(sim)) for _ in 1:round(Int, 10 * t_end)]
end

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

    @testset "the state space linearizes to its own matrices at any operating point, over scalar or vector ports (§13.7, §14.10, D-313)" begin
        sim = Simulation(linear_root_model(two_state_block()); h = 1//100)
        init!(sim, fragment(u = (in = SVector(1.0, -1.0),)))
        step!(sim; t_plus = 0.3)
        linearization = linearize(sim, taps(x = (q1 = get_state("c", "q[1]"), q2 = get_state("c", "q[2]")),
                                            u = (in1 = get_input("in[1]"), in2 = get_input("in[2]")),
                                            y = (out1 = get_face("out[1]"), out2 = get_face("out[2]"))))
        @test isapprox(linearization.A, [-1 0.5; 0 -2]; atol = 1e-12)
        @test isapprox(linearization.B, [1 0.5; 0 1]; atol = 1e-12)
        @test isapprox(linearization.C, [1 2; 0 1]; atol = 1e-12)
        @test isapprox(linearization.D, zeros(2, 2); atol = 1e-12)
        # The state is an `SVector` at every size, so a scalar block's tap takes
        # an index step.
        scalar_sim = Simulation(fed(StateSpace(A = [-2.0;;], B = [3.0;;], C = [1.0;;]), "in"); h = 1//100)
        init!(scalar_sim, fragment(u = (in = 0.0,)))
        scalar_linearization = linearize(scalar_sim, taps(x = (q = get_state("c", "q[1]"),),
                                                          u = (in = get_input(:in),)))
        @test isapprox(scalar_linearization.A, [-2.0;;]; atol = 1e-12)
        @test isapprox(scalar_linearization.B, [3.0;;]; atol = 1e-12)
        # The ports are scalars one wide and `SVector`s wider, by the matrix shapes.
        scalar_block = StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;])
        @test u_types(scalar_block) == (in = Float64,) && y_types(scalar_block) == (out = Float64,)
        @test u_types(two_state_block()) == (in = SVector{2, Float64},)
        @test y_types(two_state_block()) == (out = SVector{2, Float64},)
        single_output = StateSpace(A = [-1 0.5; 0 -2], B = [1 0.5; 0 1], C = [1 2])
        @test u_types(single_output) == (in = SVector{2, Float64},) && y_types(single_output) == (out = Float64,)
    end

    @testset "the direct term picks the stage: `D = 0` breaks the loop, `D ≠ 0` closes an algebraic cycle (§5.3, §5.5, D-313)" begin
        @test build(feedback_loop(0.0)) isa Build
        err = failure(() -> build(feedback_loop(1.0)))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :real
        @test StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], D = [1.0;;]) isa StateSpace{1, 1, 1, true}
        @test StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;]) isa StateSpace{1, 1, 1, false}
    end

    @testset "the state space runs from `x0` and walks under `Dual` (§7.2, §13.7)" begin
        scalar_model = linear_model(StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], x0 = 2), 1.0)
        sim = Simulation(scalar_model; h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 1.0)
        @test state(sim, "c").q[1] ≈ 1 + exp(-1) rtol = 1e-7
        @test port(sim, "c", :out) == state(sim, "c").q[1]
        @test build(scalar_model; activations = (Float64, LinearizeDual)) isa Build
        @test build(linear_model(two_state_block(), SVector(1.0, -1.0)); activations = (Float64, LinearizeDual)) isa Build
        @test build(linear_root_model(two_state_block()); activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the transfer function realizes in controllable canonical form, the direct term split off (§13.7, D-313)" begin
        for (block, A, B, C, D, parameters) in
                ((lag_form(), [-2.0;;], [1.0;;], [2.0;;], [0.0;;], (1, false, 1, 2, 1)),
                 (lead_lag(), [-5.0;;], [1.0;;], [-3.0;;], [1.0;;], (1, true, 2, 2, 1)),
                 (second_order(), [0.0 1.0; -4.0 -1.2], [0.0; 1.0;;], [4.0 0.0], [0.0;;], (2, false, 1, 3, 4)))
            system = Redstone.Blocks.realization(block)
            @test system.A == A
            @test system.B == B
            @test system.C == C
            @test system.D == D
            @test typeof(block) === TransferFunction{parameters...}
        end
        # The class follows the true degree, so a leading zero in `num` is strictly proper.
        @test TransferFunction(num = (0, 1), den = (1, 5)) isa TransferFunction{1, false}
    end

    @testset "the transfer function of the lag matches the lag block (§13.7)" begin
        sim = Simulation(lag_pair_model(); h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 0.3)
        @test port(sim, "tf", :out) ≈ port(sim, "l", :out) rtol = 1e-12
        step!(sim; t_plus = 0.7)
        @test port(sim, "tf", :out) ≈ port(sim, "l", :out) rtol = 1e-12
        # The realized state is the lag's scaled by `τ`.
        @test state(sim, "tf").q[1] ≈ 0.5 * state(sim, "l").q rtol = 1e-12
        @test build(lag_pair_model(); activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the lead-lag and the second-order system linearize to their transfer functions (§14.10, D-313)" begin
        sim = Simulation(linear_root_model(lead_lag()); h = 1//100)
        init!(sim, fragment(u = (in = 0.0,)))
        linearization = linearize(sim, taps(x = (q = get_state("c", "q[1]"),), u = (in = get_input(:in),),
                                            y = (out = get_face(:out),)))
        @test isapprox(linearization.A, [-5.0;;]; atol = 1e-12)
        @test isapprox(linearization.B, [1.0;;]; atol = 1e-12)
        @test isapprox(linearization.C, [-3.0;;]; atol = 1e-12)
        @test isapprox(linearization.D, [1.0;;]; atol = 1e-12)
        second_sim = Simulation(linear_root_model(second_order()); h = 1//100)
        init!(second_sim, fragment(u = (in = 0.0,)))
        (; A, B, C, D) = linearize(second_sim, taps(x = (q1 = get_state("c", "q[1]"), q2 = get_state("c", "q[2]")),
                                                    u = (in = get_input(:in),), y = (out = get_face(:out),)))
        for s in (0, im, 2im, 1 + 3im)
            H = (C * ((s * I - A) \ B) + D)[1]
            @test abs(H - 4 / (s^2 + 1.2s + 4)) < 1e-12
        end
    end

    @testset "the transfer function starts at rest or at the steady state for `u0`, and refuses an improper function or an origin pole with `u0` (§13.7)" begin
        sim = Simulation(linear_root_model(TransferFunction(num = (1,), den = (0.5, 1), u0 = 3.0)); h = 1//100)
        init!(sim, fragment(u = (in = 3.0,)))
        @test port(sim, "c", :out) == 3.0
        step!(sim; t_plus = 1.0)
        @test port(sim, "c", :out) ≈ 3.0 rtol = 1e-12
        # A pole at the origin starts at rest.
        origin_pole = TransferFunction(num = (1,), den = (1, 0))
        @test origin_pole isa TransferFunction{1, false}
        origin_sim = Simulation(linear_model(origin_pole, 1.0); h = 1//100)
        init!(origin_sim, fragment())
        step!(origin_sim; t_plus = 1.0)
        @test port(origin_sim, "c", :out) ≈ 1.0 rtol = 1e-12
        @test_throws ArgumentError TransferFunction(num = (1, 1, 1), den = (1, 1))
        @test_throws ArgumentError TransferFunction(num = (1,), den = (1, 0), u0 = 1.0)
        @test_throws ArgumentError TransferFunction(num = (1,), den = (0, 1))
        @test_throws ArgumentError TransferFunction(num = (2,), den = (1,))
        @test_throws ArgumentError TransferFunction(num = (), den = ())
    end

    @testset "the transfer function's stage follows its degree, and it declares no stage of its own (§5.3, D-313)" begin
        @test build(feedback_loop(lag_form())) isa Build
        err = failure(() -> build(feedback_loop(lead_lag())))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :real
        # The arms on `LinearBlock` are the only stages, picked by `FT`.
        @test !Redstone.has_stage(y_direct, lag_form())
        @test !Redstone.has_stage(y_state, lead_lag())
    end

    @testset "the linear blocks' phase bodies allocate nothing (§7.5)" begin
        for model in (linear_model(two_state_block(), SVector(1.0, -1.0)), feedback_loop(0.0),
                      linear_model(lag_form(), 1.0), lead_lag_loop())
            @test build(model; activations = (Float64, LinearizeDual)) isa Build
            sim = Simulation(model; h = 1//100)
            bodies = phase_bodies(sim)
            for name in (:sweep_1, :sweep_2, :rhs, :ticks)
                body = bodies[name]
                body(); body(0)
                @test @ballocated($body()) == 0
                @test @ballocated($body(1)) == 0
            end
        end
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

    @testset "the vector limited integrator linearizes each component by its own mode (§7.2, §14.10, D-276, D-313)" begin
        # At 0.7 component 1 is clamped at its upper limit and component 2 is free.
        rig = Simulation(fed(LimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(0.5, 0.8)), "in"); h = 1//10)
        init!(rig, fragment(u = (in = SVector(1.0, 0.0),)))
        step!(rig; t_plus = 0.7)
        linearization = linearize(rig, taps(x = (q1 = get_state("c", "q[1]"), q2 = get_state("c", "q[2]")),
                                            u = (in1 = get_input("in[1]"), in2 = get_input("in[2]"))))
        @test isapprox(linearization.A, zeros(2, 2); atol = 1e-12)
        @test isapprox(linearization.B, diagm([0.0, 1.0]); atol = 1e-12)
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

    @testset "the PID's correction against its own limits stops a single loop's windup (§13.7, D-313)" begin
        gains = (Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, u_min = -1.0, u_max = 1.0)
        @test build(pid_single_loop(PID(; gains..., Tt = 1.0)); activations = (Float64, LinearizeDual)) isa Build
        uncorrected, corrected =
            (loop_samples(sim -> (y = port(sim, "", :y), q = state(sim, "controller").q),
                          pid_single_loop(PID(; gains..., Tt = Tt)), 40) for Tt in (Inf, 1.0))
        @test maximum(sample.y for sample in uncorrected) > 8.0    # 8.18
        @test maximum(sample.y for sample in corrected) < 5.5      # 5.33
        @test uncorrected[end].y ≈ 5.0 atol = 1e-4
        @test corrected[end].y ≈ 5.0 atol = 1e-4
        # The windup itself: the integral term peaks at 6.25 uncorrected, 0.67 corrected.
        @test maximum(abs(sample.q) for sample in corrected) < maximum(abs(sample.q) for sample in uncorrected)
    end

    @testset "the PID assembled from library blocks runs and linearizes as the block (§13.7, §5.4, §8.5)" begin
        gains = (Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, Tt = 1.0, u_min = -1.0, u_max = 1.0)
        @test build(pid_single_loop(pid_assembly(; gains...)); activations = (Float64, LinearizeDual)) isa Build
        # One law in another association order. The assembly's integral term is
        # its child `int`, and its `u` a face. At `Tt = 2.0` the division by `Tt`
        # changes the correction.
        for Tt in (1.0, 2.0)
            block_samples = loop_samples(sim -> (y = port(sim, "", :y), u = port(sim, "controller", :u),
                                                 q = state(sim, "controller").q),
                                         pid_single_loop(PID(; gains..., Tt = Tt)), 40)
            assembly_samples = loop_samples(sim -> (y = port(sim, "", :y), u = port(sim, "controller", :u),
                                                    q = state(sim, "controller/int").q),
                                            pid_single_loop(pid_assembly(; gains..., Tt = Tt)), 40)
            for name in (:y, :u, :q)
                @test maximum(abs(getfield(block_sample, name) - getfield(assembly_sample, name))
                              for (block_sample, assembly_sample) in zip(block_samples, assembly_samples)) ≤ 1e-9
            end
        end
        # Each as the root, its ports as root inputs, at a free operating point.
        plain_matrices = (A = [0.0 0.0; 0.0 -10.0], B = [0.5 -0.5; 0.0 10.0], C = [1.0 2.0], D = [1.0 -3.0])
        for (model, state_taps) in
                ((pid_root_model(pid_controller(false, false)), (q = get_state("controller", :q), yf = get_state("controller", :yf))),
                 (pid_assembly(; gains...), (q = get_state("int", :q), yf = get_state("lag", :q))))
            @test build(model; activations = (Float64, LinearizeDual)) isa Build
            sim = Simulation(model; h = 1//100)
            init!(sim, fragment(u = (r = 0.0, y = 0.0)))
            linearization = linearize(sim, taps(x = state_taps, u = (r = get_input(:r), y = get_input(:y)),
                                                y = (u = get_face(:u),)))
            @test isapprox(linearization.A, plain_matrices.A; atol = 1e-12)
            @test isapprox(linearization.B, plain_matrices.B; atol = 1e-12)
            @test isapprox(linearization.C, plain_matrices.C; atol = 1e-12)
            @test isapprox(linearization.D, plain_matrices.D; atol = 1e-12)
        end
    end

    @testset "the tracking PID follows a stateful servo, whose `v` from state closes no cycle (§13.7, §5.4, D-313)" begin
        # The positive half of the artificial-cycle refusal above.
        gains = (Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1)
        @test build(pid_servo_loop(PID(; gains..., tracking = true, Tt = 1.0)); activations = (Float64, LinearizeDual)) isa Build
        untracked, tracked = (loop_samples(sim -> port(sim, "", :y),
                                           pid_servo_loop(PID(; gains..., tracking = true, Tt = Tt)), 40)
                              for Tt in (Inf, 1.0))
        @test maximum(untracked) > 8.5    # 8.71
        @test maximum(tracked) < 6.5      # 5.96
        @test untracked[end] ≈ 5.0 atol = 1e-2
        @test tracked[end] ≈ 5.0 atol = 1e-2
    end

    @testset "in a cascade, ungated tracking couples the loops and the hold's gate removes the coupling (§13.7, D-313)" begin
        # pid_anti_windup.md, section 3: a shorter `Tt` slaves an ungated
        # integrator to the inner loop's transients, and costs a gated one nothing.
        gains = (Kp = 0.5, Ki = 0.1)
        @test build(pid_cascade(PID(; gains..., Tt = 2.0, hold = true, tracking = true); hold = true, tracking = true);
                    activations = (Float64, LinearizeDual)) isa Build
        plain, held, tracking_long, tracking_short, gated_long, gated_short =
            (loop_samples(sim -> port(sim, "", :y),
                          pid_cascade(PID(; gains..., Tt = Tt, hold = hold, tracking = tracking);
                                      hold = hold, tracking = tracking), 60)
             for (hold, tracking, Tt) in ((false, false, Inf), (true, false, Inf), (false, true, 2.0),
                                          (false, true, 0.5), (true, true, 2.0), (true, true, 0.5)))
        @test maximum(plain) - maximum(held) > 2.0                              # 8.33 against 6.10
        @test maximum(gated_long) < maximum(held) && maximum(gated_short) < maximum(held)
        @test maximum(tracking_short) - maximum(tracking_long) > 1.0            # 7.27 against 6.13
        @test maximum(gated_short) < maximum(gated_long)                        # 5.09 against 5.20
        for outputs in (plain, held, tracking_long, tracking_short, gated_long, gated_short)
            @test outputs[end] ≈ 5.0 atol = 3e-2
        end
    end

    @testset "every keyword constructor builds a `Float64` block from integer keywords, and a flag keyword or a misfit shape refuses one (§7.2)" begin
        @test Integrator(x0 = 1) isa Integrator{Float64}
        @test FirstOrderLag(τ = 1, x0 = 1) isa FirstOrderLag{Float64}
        @test Step(t_step = 0.25, before = 0, after = 2) isa Step{Float64, true}
        @test LimitedIntegrator(lower = -1, upper = 1) isa LimitedIntegrator{Float64}
        @test LimitedIntegrator(lower = -1, upper = 1, localized = false) isa LimitedIntegrator{Float64, false}
        @test Relay(lower = 0, upper = 1) isa Relay{Float64}
        @test LimitedIntegrator(lower = SVector(-1, -1), upper = SVector(1, 1)) isa
              LimitedIntegrator{SVector{2, Float64}, true}
        @test PID(Kp = 1) isa PID{false, false}
        @test StateSpace(A = [-1;;], B = [1;;], C = [1;;]) isa StateSpace{1, 1, 1, false}
        @test StateSpace(A = [-1;;], B = [1;;], C = [1;;], x0 = 1).x0 === SVector(1.0)
        @test TransferFunction(num = (1,), den = (1, 2)) isa TransferFunction{1, false}
        @test TransferFunction(num = [1], den = [1, 2]) isa TransferFunction{1, false}
        @test all(field -> getfield(PID(Kp = 1), field) isa Float64, fieldnames(PID))
        @test_throws TypeError Step(t_step = 0.25, localized = 1)
        @test_throws TypeError LimitedIntegrator(lower = -1, upper = 1, localized = 1)
        @test_throws TypeError PID(Kp = 1, hold = 1)
        @test_throws TypeError PID(Kp = 1, tracking = 1)
        @test_throws ArgumentError StateSpace(A = [-1 0.5; 0 -2], B = [1 0.5], C = [1 2; 0 1])
        @test_throws ArgumentError StateSpace(A = [-1 0.5; 0 -2], B = [1 0.5; 0 1], C = [1 2; 0 1], x0 = [1, 2, 3])
        @test_throws ArgumentError StateSpace(A = zeros(0, 0), B = zeros(0, 1), C = zeros(1, 0), D = [2.0;;])
    end

    @testset "the loops' phase bodies and their quiet boundaries allocate nothing (§7.5)" begin
        for model in (servo_loop(true), servo_loop(false), bang_bang_loop(),
                      vector_limited_model(true), vector_limited_model(false), vector_relay_model(),
                      pid_single_loop(pid_controller(false, false)),
                      pid_single_loop(pid_assembly(Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, Tt = 1.0,
                                                   u_min = -1.0, u_max = 1.0)),
                      pid_servo_loop(PID(Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, Tt = 1.0, tracking = true)),
                      pid_cascade(PID(Kp = 0.5, Ki = 0.1, Tt = 2.0, hold = true, tracking = true);
                                  hold = true, tracking = true))
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
                     PID(Kp = 1.0, hold = true, tracking = true),
                     StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], D = [0.0;;]),
                     StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], D = [1.0;;]), two_state_block(),
                     lag_form(), lead_lag(), second_order(),
                     Group((; k = Constant(1.0))))
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
