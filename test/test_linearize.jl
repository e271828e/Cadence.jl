# --- the linearization service (§14.10; increment 54) ------------------------------
# The tap set, its collecting resolution with the four tap refusals, the seeded
# passes of `width` directions over D-213's two-half scratch world, and the
# returned value checked against the closed forms. The fixtures live at top
# level for `implementation.md`'s local-scope reason; `PEND_G_L` and `PEND_C` are
# test_trim.jl's, `resume_condition` test_lifecycle.jl's, `LeafPose`
# test_readers.jl's.

# The walkthrough's model: a sum of two root inputs drives the pendulum's
# torque, and two faces leave the root, one of them the sum's feedthrough.
lin_pend() = Group((; s = Sum(), c = Pendulum()); wires = ("s/e" => "c/u",),
                   inputs = ("τ" => "s/a", "d" => "s/b"),
                   outputs = ("c/θ" => "θ", "s/e" => "u_eff"))
lin_point(θ = 0.3) = combine(at("c", condition(Pendulum(); θ = θ)),
                             fragment(inputs = (τ = PEND_G_L * sin(θ), d = 0.0)))
lin_taps() = taps(x = (θ = get_state("c", :θ), ω = get_state("c", :ω)),
                  u = (τ = get_input(:τ), d = get_input(:d)),
                  y = (θ = get_face(:θ), u_eff = get_face(:u_eff)))

# The same model initialized at its trim point, for the refusals that need a
# legal call around them.
lin_pend_sim() = (sim = Simulation(lin_pend(); h = 1//10); init!(sim, lin_point()); sim)

# A vector state, a vector root input and a vector face, closed through
# `u = -k·qin₁`.
lin_vector() = Group((; p = VectorPlant(), fb = StateFeedback(2.0));
                     wires = ("fb/u" => "p/u",), inputs = ("qin" => "fb/q",),
                     outputs = ("p/q" => "q", "p/power" => "power"))
lin_vector_point() = combine(at("p", fragment(x = (q = SVector(0.1, 0.2),))),
                             fragment(inputs = (qin = SVector(0.5, 0.0),)))

# A root input whose one consumer declares its entry `Pinned`.
lin_pinned() = Group((; g = PinnedGain(), c = Pendulum());
                     wires = ("g/out" => "c/u",), inputs = ("τ" => "g/e",))

# The pendulum's torque held by a discrete producer: `sampled_pend` again.
lin_sampled() = Group((; ctl = DiscreteIntegrator(1.0), c = Pendulum());
                      wires = ("ctl/u" => "c/u",), inputs = ("in" => "ctl/e",))
lin_sampled_point() = combine(at("ctl", fragment(s = (acc = 4.0,))),
                              at("c", condition(Pendulum(); θ = asin(4.0 / PEND_G_L))),
                              fragment(inputs = (in = 0.0,)))

# The pendulum's closed form at θ₀, the walkthrough's section 2.
lin_closed_A(θ = 0.3) = [0 1; -PEND_G_L*cos(θ) -PEND_C]

# A continuous component whose derivative reads the clock, `q̇ = -t·q² + u`, so
# a linearization at the wrong time reads another slope.
struct TimedDecay <: AbstractComponent end
x_init(::TimedDecay) = (q = 1.0,)
u_types(::TimedDecay) = (u = Float64,)
y_types(::TimedDecay) = (q = Float64,)
y_state(::TimedDecay, (; x)) = (q = x.q,)
x_derivative(::TimedDecay, (; x, u, t)) = (q = -t * x.q^2 + u.u,)

# A matrix state, `ṁ = M·m` with `M = [-1 0; 0.5 -2]`, so
# `∂ṁ[i,j]/∂m[k,l] = M[i,k]·δ(j,l)`: a tap's column shows which entry it seeded.
struct MatrixDecay <: AbstractComponent end
x_init(::MatrixDecay) = (m = SMatrix{2,2}(1.0, 2.0, 3.0, 4.0),)
y_types(::MatrixDecay) = (m11 = Float64,)
y_state(::MatrixDecay, (; x)) = (m11 = x.m[1, 1],)
x_derivative(::MatrixDecay, (; x)) = (m = SMatrix{2,2}(-1.0, 0.5, 0.0, -2.0) * x.m,)

# A consumer of a struct-typed root input, for the `u` list's `.name` step.
struct PoseConsumer <: AbstractComponent end
x_init(::PoseConsumer) = (q = 0.0,)
u_types(::PoseConsumer) = (pose = LeafPose{Float64},)
y_types(::PoseConsumer) = (q = Float64,)
y_state(::PoseConsumer, (; x)) = (q = x.q,)
x_derivative(::PoseConsumer, (; x, u)) = (q = u.pose.v[1] - x.q,)

# Two linearizations field for field: the value holds matrices, so `==` on the
# struct would compare them by identity.
same_linearization(left, right) =
    all(getfield(left, f) == getfield(right, f) for f in fieldnames(Linearization))

function test_linearize()
    @testset "the pendulum linearizes to its closed form, exact to round-off (§14.10)" begin
        sim = Simulation(lin_pend(); h = 1//10)
        init!(sim, lin_point())
        linearization = linearize(sim, lin_taps())
        @test isapprox(linearization.A, lin_closed_A(); atol = 1e-12)
        @test isapprox(linearization.B, [0 0; 1 -1]; atol = 1e-12)
        @test isapprox(linearization.C, [1 0; 0 0]; atol = 1e-12)
        @test isapprox(linearization.D, [0 0; 1 -1]; atol = 1e-12)
        @test linearization.ẋ₀.θ == 0.0 && abs(linearization.ẋ₀.ω) < 1e-12         # a trim point, not assumed
        @test linearization.x₀ == (θ = 0.3, ω = 0.0)
        @test linearization.u₀.τ == PEND_G_L * sin(0.3) && linearization.u₀.d == 0.0
        @test linearization.y₀ == (θ = 0.3, u_eff = linearization.u₀.τ)
        @test linearization.x_labels == (:θ, :ω) && linearization.u_labels == (:τ, :d) && linearization.y_labels == (:θ, :u_eff)
        @test size(linearization.A) == (2, 2) && size(linearization.B) == (2, 2) &&
              size(linearization.C) == (2, 2) && size(linearization.D) == (2, 2)
    end

    @testset "the default operating point is the checkpoint, and the sim is untouched (§14.10, D-274)" begin
        sim = Simulation(lin_pend(); h = 1//10)
        init!(sim, lin_point())
        run!(sim; t_end = 0.3)
        before, snapshot = checkpoint(sim), latest(sim)

        # On a continuous model nothing is held, so a point authored from what
        # the checkpoint shows agrees with it.
        at_rest = combine(at("c", fragment(x = state(sim, "c"))),
                          fragment(inputs = (τ = port(sim, "", :τ), d = port(sim, "", :d))))
        linearization = linearize(sim, lin_taps())
        @test same_linearization(linearization, linearize(sim, lin_taps(); about = at_rest, t0 = before.t))

        after = checkpoint(sim)
        @test after.x == before.x && after.s == before.s && after.m == before.m &&
              after.prior == before.prior && same_table(after.table, before.table)
        @test (after.t, after.frame, after.boundary, after.t₀) ==
              (before.t, before.frame, before.boundary, before.t₀)
        @test after.deployment === before.deployment &&
              all(getfield(after.layout, f) == getfield(before.layout, f)
                  for f in fieldnames(typeof(before.layout)))
        @test latest(sim) === snapshot && lifecycle(sim) === :stopped
    end

    @testset "the default form's frozen cells are the checkpoint's held cells (§14.10, D-213, D-274)" begin
        sim = Simulation(lin_sampled(); h = 1//10)
        init!(sim, resume_condition())
        step!(sim; frames = 3)
        # at rest the store is one tick ahead of the cell it publishes (D-273)
        @test state(sim, "ctl").acc != port(sim, "ctl", :u)
        linearization = linearize(sim, taps(x = (θ = get_state("c", :θ), ω = get_state("c", :ω)),
                                            y = (u = get_output("ctl", :u),)))
        @test linearization.y₀.u === port(sim, "ctl", :u)
    end

    @testset "the default form linearizes at the checkpoint's own time (§14.10, D-274)" begin
        sim = Simulation(fed(TimedDecay(), "u"); h = 1//10)
        init!(sim, fragment(inputs = (in = 0.0,)); t0 = 0.2)
        step!(sim; frames = 3)
        t, q = sim.exec.clock.t, state(sim, "c").q
        @test t ≈ 0.5
        linearization = linearize(sim, taps(x = (q = get_state("c", :q),)))
        @test linearization.ẋ₀.q ≈ -t * q^2 && linearization.A ≈ [-2t * q;;]
    end

    @testset "`about` is legal in built and mid-frame, where the default form is refused (§14, D-274)" begin
        sim = Simulation(lin_pend(); h = 1//10)
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} linearize(sim, lin_taps()))
        @test d.op === :linearize && d.status === :built && d.legal == [:initialized, :stopped]

        linearization = linearize(sim, lin_taps(); about = lin_point())
        @test isapprox(linearization.A, lin_closed_A(); atol = 1e-12) &&
              isapprox(linearization.B, [0 0; 1 -1]; atol = 1e-12) &&
              isapprox(linearization.C, [1 0; 0 0]; atol = 1e-12) && isapprox(linearization.D, [0 0; 1 -1]; atol = 1e-12)
        @test lifecycle(sim) === :built

        # The default operating point carries its own time, so a `t0` beside it
        # would be silently ignored: refused instead.
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} linearize(sim, lin_taps(); t0 = 1.0))
        @test d.call === :linearize && d.reason === :t0_without_about && d.argument === :t0
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} linearize(sim, lin_taps(); about = lin_point(), width = 0))
        @test d.reason === :nonpositive_width && d.value == 0

        # `running` is the §11.3 freeze for both forms, as in test_trim. Both ends
        # of the run are test-controlled.
        running_sim = Simulation(armed(); h = 1//100)
        init!(running_sim, fragment(inputs = (in = 0.0,)))
        attach!(running_sim, TailProbe(), NoClaim())   # a rostered device makes the loop yield every
                                                # frame (§12.2), so the spin gets its turn on one thread
        task = Threads.@spawn run!(running_sim; t_end = 3.0e5, stop_on = ("stop",))
        while lifecycle(running_sim) !== :running && !istaskdone(task)   # a missed start fails below, never hangs
            yield()
        end
        by_default = carried(@test_throws DiagnosticError{ServiceLifecycle} linearize(running_sim, taps()))
        by_about = carried(@test_throws DiagnosticError{ServiceLifecycle} linearize(running_sim, taps(); about = fragment()))
        stage!(running_sim, "in" => 1.0)
        wait(task)
        @test by_default.op === :linearize && by_default.status === :running &&
              by_default.legal == [:initialized, :stopped]
        @test by_about.status === :running && by_about.legal == [:built, :initialized, :stopped]

        # A `t*` stop leaves the clock inside the frame: the default form inherits
        # `checkpoint`'s refusal, and `about` is legal there as anywhere `init!` is.
        tripped = Simulation(overloaded(); h = 1//10)
        init!(tripped)
        run!(tripped; t_end = 5.0, stop_on = ("tripped",))
        d = carried(@test_throws DiagnosticError{CheckpointMidFrame} linearize(tripped, taps()))
        @test d.t_frame == 0.4 && d.frame == 4
        @test linearize(tripped, taps(); about = fragment()) isa Linearization
    end

    @testset "the width groups the directions and never changes the answer (§14.10, D-272)" begin
        sim = Simulation(lin_pend(); h = 1//10)
        init!(sim, lin_point())
        results = [linearize(sim, lin_taps(); width = w) for w in (1, 3, LINEARIZE_WIDTH)]
        for linearization in results
            @test isapprox(linearization.A, lin_closed_A(); atol = 1e-12) &&
                  isapprox(linearization.B, [0 0; 1 -1]; atol = 1e-12) &&
                  isapprox(linearization.C, [1 0; 0 0]; atol = 1e-12) && isapprox(linearization.D, [0 0; 1 -1]; atol = 1e-12)
        end
        # Bitwise: each partial is the same arithmetic whatever slot it rides in.
        @test same_linearization(results[1], results[2]) && same_linearization(results[2], results[3])
    end

    @testset "the default width's activation is pre-materializable, and a custom width keys its own (§9.7, D-272)" begin
        materialized = build(lin_pend(); activations = (Float64, LinearizeDual))
        @test haskey(materialized.activations, LinearizeDual)
        sim = Simulation(materialized; h = 1//10)
        init!(sim, lin_point())
        before = Set(keys(materialized.activations))
        linearize(sim, lin_taps())
        @test Set(keys(materialized.activations)) == before            # no compile at the keyboard
        linearize(sim, lin_taps(); width = 3)
        @test setdiff(Set(keys(materialized.activations)), before) == Set([ForwardDiff.Dual{LinearizeTag,Float64,3}])
    end

    @testset "indexed taps on vector leaves, on both sides (§14.10, D-276)" begin
        # ω = 2, ζ = 0.1, k = 2: `u = -k·qin₁ = -1`, `power = u·q₂`, so
        # ∂power/∂q₂ = u and ∂power/∂qin₁ = -k·q₂.
        sim = Simulation(lin_vector(); h = 1//10)
        init!(sim, lin_vector_point())
        linearization = linearize(sim, taps(x = (q1 = get_state("p", "q[1]"), q2 = get_state("p", "q[2]")),
                                u = (qin1 = get_input("qin[1]"), qin2 = get_input("qin[2]")),
                                y = (q1 = get_face("q[1]"), q2 = get_face("q[2]"),
                                     power = get_face(:power))))
        @test isapprox(linearization.A, [0 1; -4 -0.4]; atol = 1e-12)
        @test isapprox(linearization.B, [0 0; -2 0]; atol = 1e-12)
        @test isapprox(linearization.C, [1 0; 0 1; 0 -1.0]; atol = 1e-12)
        @test isapprox(linearization.D, [0 0; 0 0; -0.4 0]; atol = 1e-12)
        @test linearization.x₀ == (q1 = 0.1, q2 = 0.2) && linearization.u₀ == (qin1 = 0.5, qin2 = 0.0)
        @test linearization.y₀.power == -0.2
    end

    @testset "a matrix leaf's `[k,l]` tap seeds the entry its linear `[k]` names (§14.10, D-276)" begin
        sim = Simulation(single(MatrixDecay()); h = 1//10)
        init!(sim)
        by_indices = linearize(sim, taps(x = (m11 = get_state("c", "m[1,1]"), m21 = get_state("c", "m[2,1]"),
                                              m12 = get_state("c", "m[1,2]"), m22 = get_state("c", "m[2,2]"))))
        by_linear = linearize(sim, taps(x = (m1 = get_state("c", "m[1]"), m2 = get_state("c", "m[2]"),
                                             m3 = get_state("c", "m[3]"), m4 = get_state("c", "m[4]"))))
        @test isapprox(by_indices.A, kron(Matrix(1.0I, 2, 2), [-1 0; 0.5 -2]); atol = 1e-12)
        @test isapprox(by_indices.A[:, 3], [0, 0, -1, 0.5]; atol = 1e-12)     # `m[1,2]`'s column
        @test by_indices.A == by_linear.A                                    # column for column
        @test by_indices.x₀ == (m11 = 1.0, m21 = 2.0, m12 = 3.0, m22 = 4.0)
        # One entry is one site, whichever spelling names it.
        d = only(diagnostics(failure(() -> linearize(sim, taps(
            x = (a = get_state("c", "m[1,2]"), b = get_state("c", "m[3]")))))))
        @test d.reason === :duplicate_site && d.label === :b && d.duplicate_of === :a
    end

    @testset "a seed follows index steps alone: a `.name` step is unseedable (§14.10, D-036, D-276)" begin
        # A seed writes a whole cell or one `SArray` component, and there is no
        # lens into a struct's slots, so the step is refused before any seed.
        sim = Simulation(fed(PoseConsumer(), "pose"); h = 1//10)
        about = fragment(inputs = (in = LeafPose(SVector(1.0, 0.0, 0.0),
                                                 SMatrix{2,2}(1.0, 0.0, 0.0, 1.0)),))
        d = only(diagnostics(failure(() -> linearize(sim, taps(u = (v1 = get_input("in.v[1]"),));
                                                     about = about))))
        @test d isa TapResolution && d.reason === :unseedable && d.tap === :u && d.field === :in
        @test d.step == ".v" && d.declared === LeafPose{Float64} && isempty(d.pinning)
    end

    @testset "the frozen discrete tier holds, and its cell is the established one (§14.10, D-213, D-197)" begin
        sim = Simulation(lin_sampled(); h = 1//10)
        state_taps = (θ = get_state("c", :θ), ω = get_state("c", :ω))
        linearization = linearize(sim, taps(x = state_taps); about = lin_sampled_point())
        @test abs(linearization.ẋ₀.ω) < 1e-12            # the held torque is the authored 4.0, not the probe's zero
        @test isapprox(linearization.A, lin_closed_A(asin(4.0 / PEND_G_L)); atol = 1e-12)
        @test size(linearization.B) == (2, 0) && size(linearization.C) == (0, 2)

        # A discrete store is no `x` tap: the tier is frozen in the pass.
        d = only(diagnostics(failure(() -> linearize(sim, taps(x = (acc = get_state("ctl", :acc),)); about = lin_sampled_point()))))
        @test d isa TapResolution && d.reason === :discrete_state && d.path == "ctl" &&
              d.field === :acc && d.tap === :x

        # A root input read by the discrete tier alone pins by the meet: a
        # discrete consumer's entries pin wholesale (§6.1, §8.2), so its cell is
        # `Float64` at every activation and a seed has nowhere to go. The
        # consumer is named with its tier, since there is no entry to promote.
        d = only(diagnostics(failure(() -> linearize(sim, taps(x = state_taps, u = (in = get_input(:in),)); about = lin_sampled_point()))))
        @test d isa TapResolution && d.reason === :unseedable && d.pinning == [("ctl", :discrete, Float64)]
    end

    @testset "the pinned root input is refused naming its consumer (§14.10, D-167, D-168)" begin
        sim = Simulation(lin_pinned(); h = 1//10)
        d = only(diagnostics(failure(() -> linearize(sim, taps(u = (τ = get_input(:τ),)); about = fragment(inputs = (τ = 0.0,))))))
        @test d isa TapResolution && d.reason === :unseedable && d.field === :τ && d.tap === :u
        @test d.pinning == [("g", :continuous, Pinned{Float64})] && d.declared === Float64
    end

    @testset "resolution collects every tap violation into one refusal (§14.10, §13.1)" begin
        sim = Simulation(lin_vector(); h = 1//10)
        init!(sim, lin_vector_point())
        err = failure(() -> linearize(sim, taps(x = (a = get_state("p", :q), b = get_deriv("p", "q[1]")),
                                                u = (c = get_face("q[1]"), d = get_input(:nope)),
                                                y = (e = get_state("p", "q[1]"), f = get_face(:q)))))
        @test err isa DiagnosticError && length(diagnostics(err)) == 6            # the full list, one throw
        @test all(d -> d isa TapResolution, diagnostics(err))
        by_label = Dict(d.label => d for d in diagnostics(err))
        @test sort(collect(keys(by_label))) == [:a, :b, :c, :d, :e, :f]
        @test by_label[:a].reason === :vector_tap && by_label[:a].declared == SVector{2,Float64}
        @test by_label[:b].reason === :tap_kind && by_label[:b].list === :x && by_label[:b].tap === :x
        @test by_label[:c].reason === :tap_kind && by_label[:c].list === :u && by_label[:c].tap === :y
        @test by_label[:d].reason === :unknown_root_input && by_label[:d].candidates == [:qin]
        @test by_label[:e].reason === :tap_kind && by_label[:e].list === :y
        @test by_label[:f].reason === :vector_tap

        # An index on a `Float64` state is the read side's own refusal (D-276).
        d = only(diagnostics(failure(() -> linearize(lin_pend_sim(), taps(x = (θ = get_state("c", "θ[1]"),))))))
        @test d isa TapResolution && d.reason === :not_indexable && d.declared === Float64 &&
              d.step == "[1]"
    end

    @testset "two seeds at one site are refused naming the earlier label, and a y tap may repeat (§14.10)" begin
        sim = lin_pend_sim()
        err = failure(() -> linearize(sim, taps(x = (a = get_state("c", :ω), b = get_state("c", :ω)),
                                                u = (τ = get_input(:τ), again = get_input(:τ)))))
        by_label = Dict(d.label => d for d in diagnostics(err))
        @test sort(collect(keys(by_label))) == [:again, :b]                    # the later tap, each list
        @test by_label[:b].reason === :duplicate_site && by_label[:b].duplicate_of === :a &&
              by_label[:b].tap === :x
        @test by_label[:again].reason === :duplicate_site && by_label[:again].duplicate_of === :τ &&
              by_label[:again].tap === :u

        # A vector leaf's site is its component: two components are two sites.
        vector_sim = Simulation(lin_vector(); h = 1//10)
        init!(vector_sim, lin_vector_point())
        d = only(diagnostics(failure(() -> linearize(vector_sim, taps(
            x = (q1 = get_state("p", "q[1]"), q2 = get_state("p", "q[2]"), again = get_state("p", "q[1]")))))))
        @test d.reason === :duplicate_site && d.label === :again && d.duplicate_of === :q1 && d.leaf == "q[1]"

        # A `y` row is a read, not a seed.
        linearization = linearize(sim, taps(x = (θ = get_state("c", :θ),), y = (a = get_face(:θ), b = get_face(:θ))))
        @test linearization.C[1, :] == linearization.C[2, :] && isapprox(linearization.C, [1.0; 1.0;;]; atol = 1e-12)
        @test linearization.y₀ == (a = 0.3, b = 0.3)
    end

    @testset "the tap set is a type, and the misuses are directives (§14.2, D-272)" begin
        d = carried(@test_throws DiagnosticError{ReadSetMisuse} taps(x = 2.0))
        @test d.reason === :not_a_tap_list && d.label === :x
        d = carried(@test_throws DiagnosticError{ReadSetMisuse} taps(x = (a = 2.0,)))
        @test d.reason === :not_a_selector && d.label === :a
        @test taps() isa Taps                                 # every list may be empty

        d = carried(@test_throws DiagnosticError{ArgumentInvalid} linearize(lin_pend_sim(), (x = (;),)))
        @test d.call === :linearize && d.reason === :not_a_tap_set && d.argument === :taps
        dual = Simulation(lin_pend(), D8; h = 1//10)
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} linearize(dual, lin_taps()))
        @test d.call === :linearize && d.reason === :non_nominal && occursin("Dual", d.value)
    end

    @testset "the two table selectors read a component through the leaf address (§14.4, D-276)" begin
        sim = Simulation(lin_vector(); h = 1//10)
        init!(sim, lin_vector_point())
        reader = _compile_reads(reads(a = get_input("qin[2]"), b = get_face("q[1]")), sim.deployment.build)
        @test gather_reads(reader, sim.exec) === (a = 0.0, b = 0.1)
        # The trailing index is retired: no selector takes a third argument.
        @test_throws MethodError get_input(:qin, 1)
    end
end
