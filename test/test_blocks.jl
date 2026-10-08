# --- the standard component library (§13.7, §6.2) -------------------------------
# The blocks of `Redstone.Blocks`, each built in a model and read off the
# snapshot: the junction's contract and its folds, the pack, the unpack and the
# switch, the source, the delay, the discrete integrators and the rate limiter,
# the noise, the time source, the stop-gradient, the stop request, the
# integrator, the lag, the state space, the transfer function, their discrete
# twins, the step, the limited integrator, the relay, the PID and its discrete
# twin, the PID assembled from blocks, and the loops built from them alone. The
# models are built at top level, like the fixtures they reuse: `RealEntry`,
# `PinnedEntry` and `requested` are test_build.jl's.

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

# A block fed by a source, under the given rates.
fed_by(src, c; sample_times = (;)) =
    Group((; k = src, c = c); local_wires = ("k/out" => "c/in",), sample_times = sample_times)

# A pack over a walking source and a pinned one.
pack_model(p) = Group((; a = Ramp(0.0), b = Constant(2.0), p = p);
                      local_wires = ("a/out" => "p/in1", "b/out" => "p/in2"))

# A pack under the root inputs `a` and `b` and the root output `v`.
pack_root_model() = Group((; p = Pack{Float64, 2}()); input_wires = ("a" => "p/in1", "b" => "p/in2"),
                          output_wires = ("p/out" => "v",))

# An unpack fed by a constant vector.
unpack_model() = fed_by(Constant(SVector(1.0, -2.0, 3.5)), Unpack{Float64, 3}())

# An unpack under the root input `v` and the root outputs `a` and `b`.
unpack_root_model() = Group((; u = Unpack{Float64, 2}()); input_wires = ("v" => "u/in",),
                            output_wires = ("u/out1" => "a", "u/out2" => "b"))

# A pack into an unpack, over a walking source and a pinned one.
round_trip_model() =
    Group((; a = Ramp(0.0), b = Constant(2.0), p = Pack{Float64, 2}(), u = Unpack{Float64, 2}());
          local_wires = ("a/out" => "p/in1", "b/out" => "p/in2", "p/out" => "u/in"))

# A switch under the root inputs `in1`, `in2` and `select` and the root output
# `out`.
switch_root() =
    Group((; s = Switch{Float64}());
          input_wires = ("in1" => "s/in1", "in2" => "s/in2", "select" => "s/select"),
          output_wires = ("s/out" => "out",))

# A switch between two constant vectors, selecting the second.
vector_switch_model() =
    Group((; a = Constant(SVector(1.0, 2.0)), b = Constant(SVector(-1.0, -2.0)), k = Constant(false),
             s = Switch{SVector{2, Float64}}());
          local_wires = ("a/out" => "s/in1", "b/out" => "s/in2", "k/out" => "s/select"))

# A switch between a walking source and a pinned one.
mixed_switch_model() =
    Group((; r = Ramp(0.0), k = Constant(2.0), f = Constant(true), s = Switch{Float64}());
          local_wires = ("r/out" => "s/in1", "k/out" => "s/in2", "f/out" => "s/select"))

# A switch whose selector is a memoryless function of its own output.
switch_cycle_model() =
    Group((; s = Switch{Float64}(), a = Constant(1.0), b = Constant(-1.0),
             g = Junction{Float64, Bool, 1}(v -> v > 0));
          local_wires = ("a/out" => "s/in1", "b/out" => "s/in2", "s/out" => "g/in1", "g/out" => "s/select"))

# A switch from `-1` to `1` at 0.5, its selector a source of `t`, into an
# integrator.
flip_model() =
    Group((; a = Constant(1.0), b = Constant(-1.0), k = Source{Bool}(t -> t >= 0.5), s = Switch{Float64}(),
             i = Integrator());
          local_wires = ("a/out" => "s/in1", "b/out" => "s/in2", "k/out" => "s/select", "s/out" => "i/in"))

# A vector source of `t` into a vector integrator.
vector_source_model() =
    fed_by(Source{SVector{2, Float64}}(t -> SVector(sin(t), cos(t))), Integrator(x0 = SVector(0.0, 0.0)))

# A discrete limited integrator fed by a step from `1` down to `-1` at 0.1.
discrete_limited_model() =
    fed_by(Step(t_step = 0.1, before = 1.0, after = -1.0), DiscreteLimitedIntegrator(lower = -0.03, upper = 0.05))

# A rate limiter rising at 2 and falling at 5, fed by a step at 0.1 and
# starting at the step's first value.
limiter_model(before, after) =
    fed_by(Step(t_step = 0.1, before = before, after = after),
           RateLimiter(rising = 2.0, falling = 5.0, s0 = before))

# A noise source as the root's one child `c`, under the given rates.
noise_model(noise; sample_times = (;)) = Group((; c = noise); sample_times = sample_times)

# A noise model run at `h = 1//100`: `out` read after each of `n` steps.
function noise_samples(model, n)
    sim = Simulation(model; h = 1//100)
    init!(sim, fragment())
    [(step!(sim; t_plus = 1//100); port(sim, "c", :out)) for _ in 1:n]
end

# The mean of a sample, and its variance and kurtosis over its length.
function moments(samples)
    center = sum(samples) / length(samples)
    second = sum(sample -> (sample - center)^2, samples) / length(samples)
    fourth = sum(sample -> (sample - center)^4, samples) / length(samples)
    (mean = center, variance = second, kurtosis = fourth / second^2)
end

# A noise source driving an integrator.
noise_integrator_model() =
    Group((; n = GaussianWhiteNoise(seed = 1, σ = 1.0), i = Integrator()); local_wires = ("n/out" => "i/in",))

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

# The hold of the scalar lag `1/(s + 1)` from `x0`.
scalar_hold(; x0 = 0.0) = DiscretizedStateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], x0 = x0)

# The hold of the transfer function `num / den` beside a continuous block, both
# fed by one constant, under the given rates.
hold_pair_model(num, den, continuous; sample_times = (;)) =
    Group((; k = Constant(1.0), d = DiscretizedTransferFunction(num = num, den = den), c = continuous);
          local_wires = ("k/out" => "d/in", "k/out" => "c/in"), sample_times = sample_times)

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
# driving an integrator plant; the continuous block unless given.
pid_clamp_loop(controller = PID(Kp = 1.0, Ki = 0.5, Kd = 0.2, Tt = 1.0, tracking = true)) =
    Group((; reference = Step(t_step = 0.5, after = 5.0), controller = controller,
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

# A single loop on the own limits: the controller drives an integrator plant,
# continuous unless given.
pid_single_loop(controller; plant = Integrator()) = Group((
        reference = Step(t_step = 0.5, after = 5.0), controller = controller, plant = plant);
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

# A holding discrete PID driving a discrete integrator plant through a discrete
# limited integrator, whose code it reads.
discrete_hold_loop(controller) = Group((
        reference = Step(t_step = 0.5, after = 5.0), controller = controller,
        actuator = DiscreteLimitedIntegrator(lower = -1.0, upper = 1.0), plant = DiscreteIntegrator());
      local_wires = ("reference/out" => "controller/r", "plant/out" => "controller/y",
                     "controller/u" => "actuator/in", "actuator/out" => "plant/in",
                     "actuator/saturation" => "controller/saturation"))

# A loop run at `h = 1//100` and sampled every 0.1 up to `t_end`: `read(sim)`
# at each sample.
function loop_samples(read, model, t_end)
    sim = Simulation(model; h = 1//100)
    init!(sim, fragment())
    [(step!(sim; frames = 10); read(sim)) for _ in 1:round(Int, 10 * t_end)]
end

# The time of the first sample from which a loop's samples, taken every 0.1
# from 0.1, stay within 0.05 of the reference 5.
settling_time(samples) = (findlast(sample -> abs(sample - 5.0) > 0.05, samples) + 1) / 10

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

    @testset "the pack is the junction at a static vector, and linearizes to the identity (§6.2, §14.10, D-311)" begin
        @test u_types(Pack{Float64, 3}()) == (in1 = Float64, in2 = Float64, in3 = Float64)
        @test y_types(Pack{Float64, 3}()) == (out = SVector{3, Float64},)
        @test typeof(Pack{Float64, 2}()) === Junction{Float64, SVector{2, Float64}, 2, typeof(Redstone.Blocks.pack)}
        @test Pack{Float64, 2}().f === Redstone.Blocks.pack
        @test Redstone.has_stage(y_direct, Pack{Float64, 2}()) && !Redstone.has_stage(y_state, Pack{Float64, 2}())
        sim = Simulation(pack_model(Pack{Float64, 2}()); h = 1//10)
        init!(sim, fragment())
        step!(sim; t_plus = 0.3)
        @test isapprox(port(sim, "p", :out), SVector(0.3, 2.0); atol = 1e-12)
        @test build(pack_model(Pack{Float64, 2}()); activations = (Float64, LinearizeDual)) isa Build
        root_sim = Simulation(pack_root_model(); h = 1//100)
        init!(root_sim, fragment(u = (a = 1.0, b = 2.0)))
        linearization = linearize(root_sim, taps(u = (a = get_input(:a), b = get_input(:b)),
                                                 y = (v1 = get_face("v[1]"), v2 = get_face("v[2]"))))
        @test isapprox(linearization.D, [1 0; 0 1]; atol = 1e-12)
    end

    @testset "the unpack splits a static vector into scalar ports, named `out1` on (§13.7, D-313)" begin
        sim = Simulation(unpack_model(); h = 1//10)
        init!(sim, fragment())
        @test (port(sim, "c", :out1), port(sim, "c", :out2), port(sim, "c", :out3)) == (1.0, -2.0, 3.5)
        @test y_types(Unpack{Float64, 3}()) == (out1 = Float64, out2 = Float64, out3 = Float64)
        @test y_types(Unpack{Float64, 1}()) == (out1 = Float64,)
        @test Redstone.has_stage(y_direct, Unpack{Float64, 3}()) && !Redstone.has_stage(y_state, Unpack{Float64, 3}())
        @test build(unpack_model(); activations = (Float64, LinearizeDual)) isa Build
        root_sim = Simulation(unpack_root_model(); h = 1//100)
        init!(root_sim, fragment(u = (v = SVector(1.0, 2.0),)))
        linearization = linearize(root_sim, taps(u = (v1 = get_input("v[1]"), v2 = get_input("v[2]")),
                                                 y = (a = get_face(:a), b = get_face(:b))))
        @test isapprox(linearization.D, [1 0; 0 1]; atol = 1e-12)
        round_sim = Simulation(round_trip_model(); h = 1//10)
        init!(round_sim, fragment())
        step!(round_sim; t_plus = 0.3)
        @test port(round_sim, "u", :out1) ≈ 0.3 atol = 1e-12
        @test port(round_sim, "u", :out2) == 2.0
        @test build(round_trip_model(); activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the switch publishes the selected input and linearizes to its selection (§13.7, §14.10, D-313)" begin
        for (select, out, row) in ((true, 1.0, [1 0]), (false, -1.0, [0 1]))
            sim = Simulation(switch_root(); h = 1//100)
            init!(sim, fragment(u = (in1 = 1.0, in2 = -1.0, select = select)))
            @test port(sim, "s", :out) == out
            linearization = linearize(sim, taps(u = (in1 = get_input(:in1), in2 = get_input(:in2)),
                                                y = (out = get_face(:out),)))
            @test isapprox(linearization.D, row; atol = 1e-12)
        end
        @test build(switch_root(); activations = (Float64, LinearizeDual)) isa Build
        vector_sim = Simulation(vector_switch_model(); h = 1//10)
        init!(vector_sim, fragment())
        @test port(vector_sim, "s", :out) == SVector(-1.0, -2.0)
        @test u_types(Switch{SVector{2, Float64}}()) ==
              (in1 = SVector{2, Float64}, in2 = SVector{2, Float64}, select = Bool)
        @test build(vector_switch_model(); activations = (Float64, LinearizeDual)) isa Build
        # A walking value beside a pinned one.
        @test build(mixed_switch_model(); activations = (Float64, LinearizeDual)) isa Build
        # A selector published by a source of `t`.
        @test build(flip_model(); activations = (Float64, LinearizeDual)) isa Build
        @test Redstone.has_stage(y_direct, Switch{Float64}())
        @test !Redstone.has_stage(y_state, Switch{Float64}())
    end

    @testset "a selector wired from a memoryless function of the switch's own output closes an algebraic cycle (§5.3, §5.5)" begin
        err = failure(() -> build(switch_cycle_model()))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :real
    end

    @testset "the source publishes `f` at the grid time, pinned, and walks nothing (§13.7, §7.2, D-312, D-313)" begin
        sim = Simulation(fed_by(Source(sin), Integrator()); h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 1)
        @test state(sim, "c").q ≈ 1 - cos(1) atol = 1e-10
        @test port(sim, "k", :out) == sin(1.0)    # a frame-top stamp of the grid time
        @test y_types(Source(sin)) == (out = Pinned{Float64},)
        @test typeof(Source(sin)) === Source{Float64, typeof(sin)}
        @test build(fed_by(Source(sin), Integrator()); activations = (Float64, LinearizeDual)) isa Build
        vector_sim = Simulation(vector_source_model(); h = 1//100)
        init!(vector_sim, fragment())
        step!(vector_sim; t_plus = 1)
        @test isapprox(state(vector_sim, "c").q, SVector(1 - cos(1), sin(1)); atol = 1e-10)
        @test build(vector_source_model(); activations = (Float64, LinearizeDual)) isa Build
        start_sim = Simulation(single(Source(t -> 2t)); h = 1//10)
        init!(start_sim, fragment(); t0 = 1.0)
        @test port(start_sim, "c", :out) == 2.0
        # The pinned source feeds a pinned entry, which a walking `out` could not.
        model = Group((; s = Source(sin), e = PinnedEntry()); local_wires = ("s/out" => "e/u",))
        @test build(model; activations = (Float64, LinearizeDual)) isa Build
        integer_sim = Simulation(single(Source{Int}(t -> 1)); h = 1//10)
        init!(integer_sim, fragment())
        @test port(integer_sim, "c", :out) === 1
        @test Redstone.has_stage(y_state, Source(sin))
        @test !Redstone.has_stage(y_direct, Source(sin))
    end

    @testset "the source refuses a value that is not a `V` (§9.5)" begin
        for source in (Source(t -> 1), Source(t -> 1f0), Source(t -> SVector(t, t)))
            err = failure(() -> build(single(source)))
            @test err isa DiagnosticError && only(diagnostics(err)) isa ConformanceFailure
        end
    end

    @testset "the structure blocks' and the time source's phase bodies allocate nothing (§7.5)" begin
        for model in (pack_model(Pack{Float64, 2}()), unpack_model(), round_trip_model(),
                      switch_root(), vector_switch_model(), fed_by(Source(sin), Integrator()),
                      fed_by(Source(t -> 2 * sin(t)), Integrator()), vector_source_model(), flip_model(),
                      requested(true, "x"))
            sim = Simulation(model; h = 1//10)
            bodies = phase_bodies(sim)
            for name in (:sweep_1, :sweep_2, :rhs, :ticks)
                body = bodies[name]
                body(); body(0)
                @test @ballocated($body()) == 0
                @test @ballocated($body(1)) == 0
            end
        end
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

    @testset "the discrete integrator accumulates `Δt in` per tick from `s0`, at its own period, and breaks a loop from stage 1 (§7.3, §10.5, §5.5, D-313)" begin
        sim = Simulation(fed_by(Constant(1.0), DiscreteIntegrator()); h = 1//100)
        init!(sim, fragment())
        @test port(sim, "c", :out) == 0.0
        step!(sim; t_plus = 1//10)
        @test port(sim, "c", :out) ≈ 0.1 atol = 1e-12    # ten additions of 0.01
        # `Δt` is the component's own period, so half the rate reaches the same value.
        halved = Simulation(fed_by(Constant(1.0), DiscreteIntegrator(); sample_times = (c = Relative(2),));
                            h = 1//100)
        init!(halved, fragment())
        step!(halved; t_plus = 1//10)
        @test port(halved, "c", :out) ≈ 0.1 atol = 1e-12
        vector_model = fed_by(Constant(SVector(1.0, -2.0)), DiscreteIntegrator(s0 = SVector(0.0, 1.0)))
        vector_sim = Simulation(vector_model; h = 1//100)
        init!(vector_sim, fragment())
        step!(vector_sim; t_plus = 1//10)
        @test isapprox(port(vector_sim, "c", :out), SVector(0.1, 0.8); atol = 1e-12)
        @test build(vector_model; activations = (Float64, LinearizeDual)) isa Build
        @test !Redstone.has_stage(y_direct, DiscreteIntegrator())
        @test Redstone.has_stage(y_state, DiscreteIntegrator())
        # Forward Euler around unit feedback: the error decays by `1 - Δt` per tick.
        loop_sim = Simulation(feedback_loop(DiscreteIntegrator()); h = 1//100)
        init!(loop_sim, fragment())
        step!(loop_sim; t_plus = 1)
        @test port(loop_sim, "p", :out) ≈ 1 - 0.99^100 rtol = 1e-12
    end

    @testset "the discrete limited integrator clamps in one line and publishes its code off the state (§7.3, §13.7, D-313)" begin
        sim = Simulation(discrete_limited_model(); h = 1//100)
        init!(sim, fragment())
        @test port(sim, "c", :out) == 0.0 && port(sim, "c", :saturation) === Int8(0)
        # Up at 1 to the upper limit by tick 5; the step flips at tick 10, where
        # the code still reads the state on the limit; down at 1 from tick 11.
        for k in 1:16
            step!(sim; t_plus = 1//100)
            out, code = port(sim, "c", :out), port(sim, "c", :saturation)
            if 5 <= k <= 10
                @test out == 0.05 && code === Int8(1)
            else
                @test out ≈ (k < 5 ? 0.01k : 0.05 - 0.01(k - 10)) atol = 1e-12
                @test code === Int8(0)
            end
        end
        vector_block = DiscreteLimitedIntegrator(lower = SVector(-0.02, -0.02), upper = SVector(0.03, 0.03))
        vector_model = fed_by(Constant(SVector(1.0, -1.0)), vector_block)
        vector_sim = Simulation(vector_model; h = 1//100)
        init!(vector_sim, fragment())
        step!(vector_sim; t_plus = 1//10)
        @test port(vector_sim, "c", :out) == SVector(0.03, -0.02)
        @test port(vector_sim, "c", :saturation) === SVector{2, Int8}(1, -1)
        @test y_types(vector_block) == (out = SVector{2, Float64}, saturation = SVector{2, Int8})
        @test build(vector_model; activations = (Float64, LinearizeDual)) isa Build
        @test !Redstone.has_stage(y_direct, vector_block)
    end

    @testset "the rate limiter follows its input within two slews per tick and is feedthrough (§7.3, §5.3, D-313)" begin
        rising_sim = Simulation(limiter_model(0.0, 1.0); h = 1//100)
        init!(rising_sim, fragment())
        step!(rising_sim; t_plus = 1//10)
        @test port(rising_sim, "c", :out) == 0.02
        step!(rising_sim; t_plus = 1//100)
        @test port(rising_sim, "c", :out) == 0.04
        step!(rising_sim; t_plus = 1//4)
        @test port(rising_sim, "c", :out) ≈ 0.54 atol = 1e-12
        step!(rising_sim; t_plus = 1//4)
        @test port(rising_sim, "c", :out) == 1.0
        falling_sim = Simulation(limiter_model(1.0, 0.0); h = 1//100)
        init!(falling_sim, fragment())
        step!(falling_sim; t_plus = 1//10)
        @test port(falling_sim, "c", :out) == 0.95
        step!(falling_sim; t_plus = 1//10)
        @test port(falling_sim, "c", :out) ≈ 0.45 atol = 1e-12
        step!(falling_sim; t_plus = 1//10)
        @test port(falling_sim, "c", :out) == 0.0
        # `s0` is the previous output at the first tick, so `t₀` is one slew in.
        startup_sim = Simulation(fed_by(Constant(10.0), RateLimiter(rising = 2.0)); h = 1//100)
        init!(startup_sim, fragment())
        @test port(startup_sim, "c", :out) == 0.02
        step!(startup_sim; t_plus = 1//100)
        @test port(startup_sim, "c", :out) == 0.04
        @test Redstone.has_stage(y_direct, RateLimiter(rising = 1.0))
        @test !Redstone.has_stage(y_state, RateLimiter(rising = 1.0))
        err = failure(() -> build(feedback_loop(RateLimiter(rising = 1.0))))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :real
        vector_model = fed_by(Constant(SVector(1.0, -1.0)),
                              RateLimiter(rising = 2.0, falling = 5.0, s0 = SVector(0.0, 0.0)))
        vector_sim = Simulation(vector_model; h = 1//100)
        init!(vector_sim, fragment())
        step!(vector_sim; t_plus = 1//10)
        @test isapprox(port(vector_sim, "c", :out), SVector(0.22, -0.55); atol = 1e-12)
        @test build(vector_model; activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the Gaussian white noise is a pure function of its seed and tick, with the moments it claims (§7.3, §2.2, D-231, D-313)" begin
        sim = Simulation(noise_model(GaussianWhiteNoise(seed = 42, σ = 1.0)); h = 1//100)
        init!(sim, fragment())
        @test port(sim, "c", :out) == Redstone.Blocks.gaussian(42, 0)
        @test Redstone.Blocks.gaussian(42, 0) ≈ 0.882248906222269 atol = 1e-12
        samples = [(step!(sim; t_plus = 1//100); port(sim, "c", :out)) for _ in 1:1000]
        @test samples == [Redstone.Blocks.gaussian(42, k) for k in 1:1000]
        # The store counts the ticks run, `t₀`'s included: the next sample's index.
        @test state(sim, "c").k === UInt64(1001)
        sample_moments = moments(samples)
        @test abs(sample_moments.mean) < 0.1
        @test 0.9 < sqrt(sample_moments.variance) < 1.1
        # Replay reproduces the stream, and another seed is another stream.
        @test noise_samples(noise_model(GaussianWhiteNoise(seed = 42, σ = 1.0)), 10)[end] ===
              noise_samples(noise_model(GaussianWhiteNoise(seed = 42, σ = 1.0)), 10)[end]
        @test noise_samples(noise_model(GaussianWhiteNoise(seed = 43, σ = 1.0)), 10)[end] !=
              noise_samples(noise_model(GaussianWhiteNoise(seed = 42, σ = 1.0)), 10)[end]
        vector_noise = GaussianWhiteNoise(seed = 7, μ = SVector(1.0, -1.0), σ = SVector(1.0, 2.0))
        @test y_types(vector_noise) == (out = SVector{2, Float64},)
        vector_sim = Simulation(noise_model(vector_noise); h = 1//100)
        init!(vector_sim, fragment())
        @test isapprox(port(vector_sim, "c", :out), SVector(1.9884743323187353, -4.728511613462453); atol = 1e-12)
        # Three ticks on, `out` is sample 3, read over the sub-counters 6 and 7.
        for _ in 1:3
            step!(vector_sim; t_plus = 1//100)
        end
        @test port(vector_sim, "c", :out) ==
              SVector(1.0, -1.0) .+ SVector(1.0, 2.0) .* SVector(Redstone.Blocks.gaussian(7, 6), Redstone.Blocks.gaussian(7, 7))
        # A scalar pairs with a vector, `μ` defaults to the scale's zero, and
        # `Float32` widens.
        @test GaussianWhiteNoise(seed = 1, σ = SVector(1.0, 2.0)) isa GaussianWhiteNoise{SVector{2, Float64}}
        @test GaussianWhiteNoise(seed = 1, σ = SVector(1.0, 2.0)).μ == SVector(0.0, 0.0)
        @test GaussianWhiteNoise(seed = 1, μ = SVector(1.0, 2.0), σ = 1.0).σ == SVector(1.0, 1.0)
        @test GaussianWhiteNoise(seed = 1, σ = 1f0) isa GaussianWhiteNoise{Float64}
        # The first output of a SplitMix64 seeded with zero.
        @test Redstone.Blocks.splitmix(0, 0) == 0xe220a8397b1dcdaf
        stream_moments = moments([Redstone.Blocks.gaussian(42, k) for k in 0:999_999])
        @test abs(stream_moments.mean) < 0.005
        @test abs(stream_moments.variance - 1) < 0.01
        @test abs(stream_moments.kurtosis - 3) < 0.05
        @test Redstone.has_stage(y_state, vector_noise)
        @test !Redstone.has_stage(y_direct, vector_noise)
        @test build(noise_integrator_model(); activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the noise's density form scales by the period (§7.3, §10.5)" begin
        # `psd = 4` reads `σ = 2 / sqrt(Δt)`: 20 at the base period and `sqrt(200)`
        # at twice it, where each sample is read at two base steps.
        for (rates, σ) in (((;), 20.0), ((c = Relative(2),), sqrt(200.0)))
            samples = noise_samples(noise_model(GaussianWhiteNoise(seed = 1, psd = 4.0); sample_times = rates), 20_000)
            @test abs(sqrt(moments(samples).variance) / σ - 1) < 0.03
        end
    end

    @testset "the discrete tier's phase bodies allocate nothing (§7.5)" begin
        for model in (fed_by(Constant(1.0), DiscreteIntegrator()), feedback_loop(DiscreteIntegrator()),
                      discrete_limited_model(), limiter_model(0.0, 1.0),
                      fed_by(Constant(1.0), scalar_hold()),
                      fed_by(Constant(SVector(1.0, -1.0)), DiscretizedStateSpace(two_state_block())),
                      hold_pair_model((1,), (0.5, 1), FirstOrderLag(τ = 0.5)),
                      hold_pair_model((4,), (1, 1.2, 4), second_order()),
                      pid_single_loop(DiscretePID(Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, Tt = 1.0,
                                                  u_min = -1.0, u_max = 1.0)),
                      pid_cascade(DiscretePID(Kp = 0.5, Ki = 0.1, Tt = 2.0, hold = true, tracking = true);
                                  hold = true, tracking = true),
                      noise_model(GaussianWhiteNoise(seed = 42, σ = 1.0)),
                      noise_model(GaussianWhiteNoise(seed = 7, μ = SVector(1.0, -1.0), σ = SVector(1.0, 2.0))))
            @test build(model; activations = (Float64, LinearizeDual)) isa Build
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

    @testset "the stop request publishes its flag off its input, pinned, with its reason (§13.7, D-316)" begin
        for (value, flag) in ((true, STOP_REQUESTED), (false, NO_STOP))
            sim = Simulation(requested(value, "x"); h = 1//100)
            init!(sim, fragment())
            @test port(sim, "stop", :flag) === flag
            step!(sim; t_plus = 1//100)
            @test port(sim, "stop", :flag) === flag
        end
        @test stop_reason(StopRequest(reason = "x")) == "x"
        @test stop_reason(StopRequest()) == ""
        # Pinned: under `Dual` the cell is still a `StopFlag`, in its own buffer.
        linearize_build = build(requested(true, "x"); activations = (Float64, LinearizeDual))
        @test linearize_build isa Build
        @test (StopFlag => 1) in activation(linearize_build, LinearizeDual).layout.sizes
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
        scalar_model = fed_by(Constant(1.0), StateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], x0 = 2))
        sim = Simulation(scalar_model; h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 1.0)
        @test state(sim, "c").q[1] ≈ 1 + exp(-1) rtol = 1e-7
        @test port(sim, "c", :out) == state(sim, "c").q[1]
        @test build(scalar_model; activations = (Float64, LinearizeDual)) isa Build
        @test build(fed_by(Constant(SVector(1.0, -1.0)), two_state_block()); activations = (Float64, LinearizeDual)) isa Build
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
        origin_sim = Simulation(fed_by(Constant(1.0), origin_pole); h = 1//100)
        init!(origin_sim, fragment())
        step!(origin_sim; t_plus = 1.0)
        @test port(origin_sim, "c", :out) ≈ 1.0 rtol = 1e-12
        @test_throws ArgumentError TransferFunction(num = (1, 1, 1), den = (1, 1))
        @test_throws ArgumentError TransferFunction(num = (1,), den = (1, 0), u0 = 1.0)
        @test_throws ArgumentError TransferFunction(num = (1,), den = (0, 1))
        # The message is matched: both inputs threw Julia's own `ArgumentError`
        # before the explicit refusal existed.
        @test_throws "order zero" TransferFunction(num = (2,), den = (1,))
        @test_throws "order zero" TransferFunction(num = (), den = ())
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
        for model in (fed_by(Constant(SVector(1.0, -1.0)), two_state_block()), feedback_loop(0.0),
                      fed_by(Constant(1.0), lag_form()), lead_lag_loop())
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

    @testset "the pair in `z` mirrors the continuous pair over `DiscreteLinearBlock`, with `D` picking the stage (§13.7, §5.3, D-313)" begin
        block = DiscreteStateSpace(A = [0.5;;], B = [1.0;;], C = [1.0;;])
        @test typeof(block) === DiscreteStateSpace{1, 1, 1, false, 1, 1, 1, 1}
        sim = Simulation(fed_by(Constant(1.0), block); h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 5//100)
        @test port(sim, "c", :out) == 2(1 - 0.5^5)
        @test build(fed_by(Constant(1.0), block); activations = (Float64, LinearizeDual)) isa Build
        @test build(feedback_loop(block)) isa Build
        err = failure(() -> build(feedback_loop(DiscreteStateSpace(A = [0.5;;], B = [1.0;;], C = [1.0;;], D = [1.0;;]))))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :real
        two_state = DiscreteStateSpace(A = [0.5 0.1; 0 0.8], B = [1 0; 0 1], C = [1 0; 0 1])
        @test u_types(two_state) == (in = SVector{2, Float64},) && y_types(two_state) == (out = SVector{2, Float64},)
        two_state_model = fed_by(Constant(SVector(1.0, 1.0)), two_state)
        two_state_sim = Simulation(two_state_model; h = 1//100)
        init!(two_state_sim, fragment())
        step!(two_state_sim; t_plus = 3//100)
        @test isapprox(port(two_state_sim, "c", :out), SVector(1.98, 2.44); atol = 1e-12)
        @test build(two_state_model; activations = (Float64, LinearizeDual)) isa Build
    end

    @testset "the discrete transfer function realizes in `z`, starts at `G(1) u0` and refuses a pole at `z = 1` with `u0` by tolerance (§13.7, D-313)" begin
        strict = DiscreteTransferFunction(num = (0.5,), den = (1, -0.5))
        system = Redstone.Blocks.held(strict)
        @test system.A == [0.5;;] && system.B == [1.0;;] && system.C == [0.5;;] && system.D == [0.0;;]
        @test typeof(strict) === DiscreteTransferFunction{1, false, 1, 2, 1}
        sim = Simulation(fed_by(Constant(1.0), strict); h = 1//100)
        init!(sim, fragment())
        step!(sim; t_plus = 5//100)
        @test port(sim, "c", :out) == 0.96875
        @test build(fed_by(Constant(1.0), strict); activations = (Float64, LinearizeDual)) isa Build
        # The steady state solves `(I - A) q = B u0`, so `out` starts at `G(1) u0`.
        steady = DiscreteTransferFunction(num = (0.5,), den = (1, -0.5), u0 = 2.0)
        @test Redstone.Blocks.held(steady).x0 == SVector(4.0)
        steady_sim = Simulation(fed_by(Constant(2.0), steady); h = 1//100)
        init!(steady_sim, fragment())
        @test port(steady_sim, "c", :out) == 2.0
        step!(steady_sim; t_plus = 1)
        @test port(steady_sim, "c", :out) == 2.0
        # At this pole `I - A` differs from `A`, which the pole at 0.5 cannot show.
        slow = DiscreteTransferFunction(num = (0.2,), den = (1, -0.8), u0 = 2.0)
        @test isapprox(Redstone.Blocks.held(slow).x0, SVector(10.0); atol = 1e-12)
        slow_sim = Simulation(fed_by(Constant(2.0), slow); h = 1//100)
        init!(slow_sim, fragment())
        @test port(slow_sim, "c", :out) ≈ 2.0 atol = 1e-12
        proper = DiscreteTransferFunction(num = (1, -0.9), den = (1, -0.5))
        @test typeof(proper) === DiscreteTransferFunction{1, true, 2, 2, 1}
        # The third denominator sums to about 5.6e-17, which an exact test would pass.
        for den in ((1, -1), (1, -0.7, -0.3), (1, -1.5, 0.5))
            @test_throws ArgumentError DiscreteTransferFunction(num = (1,), den = den, u0 = 1.0)
        end
        @test build(fed(DiscreteTransferFunction(num = (1,), den = (1, -1)), "in")) isa Build
        @test !Redstone.has_stage(y_direct, strict)
        @test !Redstone.has_stage(y_state, proper)
    end

    @testset "the zero-order hold reproduces the exact solution at every period and keeps the class (§10.5, §13.7, D-313)" begin
        for sample_times in ((;), (c = Relative(2),))
            sim = Simulation(fed_by(Constant(1.0), scalar_hold(); sample_times); h = 1//100)
            init!(sim, fragment())
            step!(sim; t_plus = 1)
            @test port(sim, "c", :out) ≈ 1 - exp(-1) atol = 1e-12
        end
        from_x0 = Simulation(fed_by(Constant(1.0), scalar_hold(x0 = 2.0)); h = 1//100)
        init!(from_x0, fragment())
        step!(from_x0; t_plus = 1)
        @test port(from_x0, "c", :out) ≈ 1 + exp(-1) atol = 1e-12
        (; A, B) = Redstone.Blocks.realization(scalar_hold(), 0.01)
        @test A[1] ≈ exp(-0.01) && B[1] ≈ 1 - exp(-0.01)
        # The two-state hold against the continuous block it wraps, RK4 at the same h.
        hold_sim = Simulation(fed_by(Constant(SVector(1.0, -1.0)), DiscretizedStateSpace(two_state_block()));
                              h = 1//100)
        continuous_sim = Simulation(fed_by(Constant(SVector(1.0, -1.0)), two_state_block()); h = 1//100)
        for sim in (hold_sim, continuous_sim)
            init!(sim, fragment())
            step!(sim; t_plus = 3//10)
        end
        @test isapprox(port(hold_sim, "c", :out), port(continuous_sim, "c", :out); atol = 1e-8)
        lag_sim = Simulation(hold_pair_model((1,), (0.5, 1), FirstOrderLag(τ = 0.5)); h = 1//100)
        init!(lag_sim, fragment())
        step!(lag_sim; t_plus = 1)
        @test port(lag_sim, "d", :out) ≈ 1 - exp(-2) atol = 1e-12
        @test port(lag_sim, "d", :out) ≈ port(lag_sim, "c", :out) atol = 1e-8
        slow_sim = Simulation(hold_pair_model((1,), (0.5, 1), FirstOrderLag(τ = 0.5);
                                              sample_times = (d = Relative(5),)); h = 1//100)
        init!(slow_sim, fragment())
        step!(slow_sim; t_plus = 1)
        @test port(slow_sim, "d", :out) ≈ 1 - exp(-2) atol = 1e-12
        steady_sim = Simulation(fed_by(Constant(3.0), DiscretizedTransferFunction(num = (1,), den = (0.5, 1), u0 = 3.0));
                                h = 1//100)
        init!(steady_sim, fragment())
        @test port(steady_sim, "c", :out) == 3.0
        step!(steady_sim; t_plus = 1)
        @test port(steady_sim, "c", :out) ≈ 3.0 rtol = 1e-12
        second_sim = Simulation(hold_pair_model((4,), (1, 1.2, 4), second_order()); h = 1//100)
        init!(second_sim, fragment())
        step!(second_sim; t_plus = 1)
        @test port(second_sim, "d", :out) ≈ port(second_sim, "c", :out) atol = 1e-9
        # The class is the continuous one: the lag breaks a loop, the lead-lag closes one.
        lag = DiscretizedTransferFunction(num = (1,), den = (0.5, 1))
        lead_lag_hold = DiscretizedTransferFunction(num = (1, 2), den = (1, 5))
        @test typeof(lag) === DiscretizedTransferFunction{1, false, 1, 2, 1}
        @test typeof(lead_lag_hold) === DiscretizedTransferFunction{1, true, 2, 2, 1}
        @test build(feedback_loop(lag); activations = (Float64, LinearizeDual)) isa Build
        err = failure(() -> build(feedback_loop(lead_lag_hold)))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :real
        @test !Redstone.has_stage(y_direct, lag)
        @test !Redstone.has_stage(y_state, lead_lag_hold)
        @test_throws ArgumentError DiscretizedTransferFunction(num = (1,), den = (1, 0), u0 = 1.0)
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

    @testset "the discrete PID's law is the continuous one over `s`, with the backward filter and the exact correction step (§13.7, D-313)" begin
        # The continuous law's rows at `Δt = 0.01`: `u_raw = 2.5 + 0.3 - 0.2 · 0.4 / 0.11`,
        # clamped to `u = 1`; `Δt Ki e = 0.0125`, and the correction reads
        # `β (1 - 2)` against `u` or `β (0.7 - 2)` against `v`, `β = 1 - e^{-0.01}`.
        gains = (Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, Tt = 1.0, u_min = -1.0, u_max = 1.0)
        s = (q = 0.3, yf = 0.1)
        y = (u = 1.0, u_raw = 2.0)
        Δt = 0.01
        for (hold, tracking, u, q_next) in
                ((false, false, (r = 3.0, y = 0.5), 0.30254983374916805),
                 (true, false, (r = 3.0, y = 0.5, saturation = Int8(1)), 0.29004983374916804),    # the gate holds
                 (true, false, (r = 3.0, y = 0.5, saturation = Int8(-1)), 0.30254983374916805),
                 (true, false, (r = 3.0, y = 0.5, saturation = Int8(0)), 0.30254983374916805),
                 (false, true, (r = 3.0, y = 0.5, v = 0.7), 0.2995647838739185),
                 (true, true, (r = 3.0, y = 0.5, saturation = Int8(1), v = 0.7), 0.2870647838739185),
                 (true, true, (r = 3.0, y = 0.5, saturation = Int8(0), v = 0.7), 0.30254983374916805))    # the fallback
            controller = DiscretePID(; gains..., hold = hold, tracking = tracking)
            outputs = y_direct(controller, (; s, u, Δt))
            @test outputs.u_raw ≈ 2.0727272727272723 atol = 1e-12
            @test outputs.u == 1.0
            updated = s_update(controller, (; s, u, y, Δt))
            @test updated.q ≈ q_next atol = 1e-12
            @test updated.yf ≈ 0.13636363636363635 atol = 1e-12
        end
        # The correction's step alone, `-β` from `q = 0` with `Ki = 0`: exactly
        # zero at `Tt = Inf` and exactly one at `Tt = 0`.
        for (Tt, β) in ((1.0, 0.009950166250831947), (Inf, 0.0), (0.0, 1.0))
            updated = s_update(DiscretePID(Kp = 1.0, Tt = Tt),
                               (; s = (q = 0.0, yf = 0.0), u = (r = 0.0, y = 0.0), y, Δt))
            @test -updated.q == β
        end
        # At `τd = 0` the D term is the backward difference, `0.1 / Δt`.
        @test y_direct(DiscretePID(Kp = 1.0, Kd = 0.2, τd = 0.0),
                       (; s = (q = 0.0, yf = 0.4), u = (r = 0.0, y = 0.5), Δt)).u_raw == -2.5
        @test u_types(DiscretePID(Kp = 1.0, hold = true, tracking = true)) ==
              (r = Float64, y = Float64, saturation = Int8, v = Float64)
        @test y_types(DiscretePID(Kp = 1.0)) == (u = Float64, u_raw = Float64)
        @test PID(Kp = 1.0) isa Redstone.Blocks.PIDBlock{false, false}
        @test DiscretePID(Kp = 1.0, hold = true, tracking = true) isa Redstone.Blocks.PIDBlock{true, true}
        @test Redstone.has_stage(y_direct, DiscretePID(Kp = 1.0))
        @test !Redstone.has_stage(y_state, DiscretePID(Kp = 1.0))
    end

    @testset "the discrete PID's loops match the continuous block's, and `Tt = 0` and `τd = 0` are legal (§13.7, D-313)" begin
        # Peak and settling time beside the continuous block's at the same gains
        # and limits: 5.327 at 11.3 on the single loop, 5.931 at 23.6 on the servo,
        # 5.202 at 26.9 on the cascade.
        gains = (Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1, u_min = -1.0, u_max = 1.0)
        @test build(pid_single_loop(DiscretePID(; gains..., Tt = 1.0)); activations = (Float64, LinearizeDual)) isa Build
        for (model, t_end, peak, settled) in
                ((pid_single_loop(DiscretePID(; gains..., Tt = 1.0)), 40, 5.329, 11.3),
                 (pid_single_loop(DiscretePID(; gains..., Tt = Inf)), 40, 8.194, 18.7),
                 (pid_single_loop(DiscretePID(; gains..., Tt = 0.0)), 40, 5.229, 11.4),
                 (pid_single_loop(DiscretePID(; gains..., τd = 0.0, Tt = 1.0)), 40, 5.331, 11.2),
                 (pid_single_loop(DiscretePID(; gains..., Tt = 1.0); plant = DiscreteIntegrator()), 40, 5.329, 11.3),
                 (pid_servo_loop(DiscretePID(; gains..., Tt = 1.0, tracking = true)), 40, 5.935, 23.6),
                 (pid_cascade(DiscretePID(Kp = 0.5, Ki = 0.1, Tt = 2.0, hold = true, tracking = true);
                              hold = true, tracking = true), 60, 5.202, 27.0))
            samples = loop_samples(sim -> port(sim, "", :y), model, t_end)
            @test maximum(samples) ≈ peak atol = 0.005
            @test settling_time(samples) == settled
        end
        @test build(pid_single_loop(DiscretePID(; gains..., Tt = 1.0); plant = DiscreteIntegrator())) isa Build
        @test build(pid_cascade(DiscretePID(Kp = 0.5, Ki = 0.1, Tt = 2.0, hold = true, tracking = true);
                                hold = true, tracking = true); activations = (Float64, LinearizeDual)) isa Build
        # The hold wired from a discrete limited integrator's stage-1 code.
        @test build(discrete_hold_loop(DiscretePID(; gains..., Tt = 1.0, hold = true))) isa Build
    end

    @testset "a tracking input wired from a clamp of the discrete PID's own output is a real cycle, traced structurally (§5.4, §5.6)" begin
        # The continuous block's cycle is artificial with the hop named; a discrete
        # member admits no tracer scalar, so no hop is found dead.
        err = failure(() -> build(pid_clamp_loop(DiscretePID(Kp = 1.0, Ki = 0.5, Kd = 0.2, Tt = 1.0, tracking = true))))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle && d.classification === :real
        @test isempty(d.dead)
        @test d.wires == ["controller/u" => "sat/in1", "sat/out" => "controller/v"]
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
        @test DiscreteIntegrator(s0 = 1) isa DiscreteIntegrator{Float64}
        @test DiscreteLimitedIntegrator(lower = -1, upper = 1) isa DiscreteLimitedIntegrator{Float64}
        @test DiscreteLimitedIntegrator(lower = SVector(-1, -1), upper = SVector(1, 1)) isa
              DiscreteLimitedIntegrator{SVector{2, Float64}}
        @test RateLimiter(rising = 1) isa RateLimiter{Float64}
        @test RateLimiter(rising = 3).falling == 3.0
        @test PID(Kp = 1) isa PID{false, false}
        @test DiscretePID(Kp = 1) isa DiscretePID{false, false}
        @test StateSpace(A = [-1;;], B = [1;;], C = [1;;]) isa StateSpace{1, 1, 1, false}
        @test StateSpace(A = [-1;;], B = [1;;], C = [1;;], x0 = 1).x0 === SVector(1.0)
        @test TransferFunction(num = (1,), den = (1, 2)) isa TransferFunction{1, false}
        @test TransferFunction(num = [1], den = [1, 2]) isa TransferFunction{1, false}
        @test DiscreteStateSpace(A = [1;;], B = [1;;], C = [1;;]) isa DiscreteStateSpace{1, 1, 1, false}
        @test DiscreteTransferFunction(num = (1,), den = (2, -1)) isa DiscreteTransferFunction{1, false}
        @test DiscretizedStateSpace(A = [-1;;], B = [1;;], C = [1;;]) isa DiscretizedStateSpace{1, 1, 1, false}
        @test DiscretizedTransferFunction(num = (1,), den = (1, 2)) isa DiscretizedTransferFunction{1, false}
        @test all(field -> getfield(PID(Kp = 1), field) isa Float64, fieldnames(PID))
        @test all(field -> getfield(DiscretePID(Kp = 1), field) isa Float64, fieldnames(DiscretePID))
        @test_throws TypeError Step(t_step = 0.25, localized = 1)
        @test_throws TypeError LimitedIntegrator(lower = -1, upper = 1, localized = 1)
        @test_throws TypeError PID(Kp = 1, hold = 1)
        @test_throws TypeError PID(Kp = 1, tracking = 1)
        @test_throws ArgumentError StateSpace(A = [-1 0.5; 0 -2], B = [1 0.5], C = [1 2; 0 1])
        @test_throws ArgumentError StateSpace(A = [-1 0.5; 0 -2], B = [1 0.5; 0 1], C = [1 2; 0 1], x0 = [1, 2, 3])
        @test_throws ArgumentError StateSpace(A = zeros(0, 0), B = zeros(0, 1), C = zeros(1, 0), D = [2.0;;])
        @test_throws ArgumentError GaussianWhiteNoise(seed = 1)
        @test_throws ArgumentError GaussianWhiteNoise(seed = 1, σ = 1.0, psd = 1.0)
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
                     Pack{Float64, 2}(), Unpack{Float64, 2}(), Switch{Float64}(),
                     Source(sin), Source{Bool}(t -> t >= 0.5),
                     Constant(1.0), UnitDelay(0.0), Freeze{Float64}(), StopRequest(reason = "x"),
                     DiscreteIntegrator(), DiscreteLimitedIntegrator(lower = -1.0, upper = 1.0),
                     DiscreteLimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(1.0, 1.0)),
                     RateLimiter(rising = 1.0),
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
                     DiscreteStateSpace(A = [0.5;;], B = [1.0;;], C = [1.0;;]),
                     DiscreteTransferFunction(num = (0.5,), den = (1, -0.5)), scalar_hold(),
                     DiscretizedStateSpace(A = [-1.0;;], B = [1.0;;], C = [1.0;;], D = [1.0;;]),
                     DiscretizedTransferFunction(num = (1,), den = (0.5, 1)),
                     DiscretizedTransferFunction(num = (1, 2), den = (1, 5)),
                     DiscretePID(Kp = 1.0), DiscretePID(Kp = 1.0, hold = true),
                     DiscretePID(Kp = 1.0, tracking = true), DiscretePID(Kp = 1.0, hold = true, tracking = true),
                     GaussianWhiteNoise(seed = 1, σ = 1.0),
                     GaussianWhiteNoise(seed = 7, μ = SVector(1.0, -1.0), σ = SVector(1.0, 2.0)),
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
