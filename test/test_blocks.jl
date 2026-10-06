# --- the standard component library (§13.7, §6.2) -------------------------------
# The blocks of `Redstone.Blocks`, each built in a model and read off the
# snapshot: the junction's contract and its folds, the source, the delay and the
# stop-gradient. The models are built at top level, like the fixtures they reuse:
# `RealEntry` and `PinnedEntry` are test_build.jl's.

# One gate over three `Constant` sources, at the given input values.
gate_model(gate, (a, b, c)) =
    Group((; a = Constant(a), b = Constant(b), c = Constant(c), g = gate);
          inner_wires = ("a/out" => "g/in1", "b/out" => "g/in2", "c/out" => "g/in3"))

# A sum over a walking source, a pinned source and a delayed copy of the first.
blocks_sum_model() =
    Group((; r = Ramp(1.0), k = Constant(2.0), d = UnitDelay(0.5), s = SumJunction{Float64,3}());
          inner_wires = ("r/out" => "s/in1", "k/out" => "s/in2", "d/out" => "s/in3",
                         "r/out" => "d/in"))

# A delay behind a tick counter: the counter's `n` is its tick index.
delay_model(v0) = Group((; c = TickCounter(), d = UnitDelay(v0)); inner_wires = ("c/n" => "d/in",))

# The pendulum's angle leaving the root twice, once through a freeze.
freeze_model() = Group((; p = Pendulum(), f = Freeze{Float64}());
                       inner_wires = ("p/θ" => "f/in",), input_wires = ("τ" => "p/u",),
                       output_wires = ("p/θ" => "direct", "f/out" => "frozen"))

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
                      inner_wires = ("p/θ" => "f/in", "f/out" => "e/u"), input_wires = ("τ" => "p/u",))
        @test build(model; activations = (Float64, LinearizeDual)) isa Build
        # `V` is a `Real` or a `StaticArray` of them, constrained at the type.
        @test_throws TypeError Freeze{HeightField}
    end

    @testset "a `Constant` spells the zero contributor into either entry (§6.2, D-312)" begin
        @test y_types(Constant(0.0)) == (out = Pinned{Float64},)
        for consumer in (RealEntry(), PinnedEntry())
            model = Group((; k = Constant(0.0), e = consumer); inner_wires = ("k/out" => "e/u",))
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

    @testset "every block passes the shadowing check from its own module (§8.1, D-246, D-313)" begin
        # The reason `Blocks` is a submodule: its parent module is `Blocks`, which
        # reaches the declarations by import alone, as a user's component file
        # does, so a missing import here would surface as `DeclarationShadowed`.
        for comp in (Or{3}(), And{2}(), SumJunction{Float64,2}(), Junction{Float64,Float64,2}(max),
                     Constant(1.0), UnitDelay(0.0), Freeze{Float64}(),
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
