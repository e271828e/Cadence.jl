# --- the read-selector family, the compiled reader and `capture` (§14.4, §14.1;
# increment 21) ------------------------------------------------------------------
# The five deferred reads, their resolution against a build in §13.1's
# collecting form, the gather twin of `apply!` over an executor, and the
# service that reads the committed world back as a condition. The fixtures live
# at top level for `implementation.md`'s local-scope reason.

# Every home a read can come from, and nothing that fires: a continuous `x`
# (the plant's `q`) with its derivative, a discrete `s` (the integrator's
# `acc`), a mode store no event transitions (`ModedSource`, §8.2), two root
# inputs and one root-exported output face.
readable() = Group((; plant = Plant(), ctl = DiscreteIntegrator(3.0), src = ModedSource());
                   inputs = ("u" => "plant/u", "e" => "ctl/e"),
                   outputs = ("plant/y" => "y",))

# The captured world, authored: every store off its declared default, and `e`
# at zero so the integrator's `state_update` is stationary — boundary zero's
# outgoing transition (§14.5) is a mover like any handler, and a bit-for-bit
# round trip is a claim about the *establishment*, not about a `state_update`
# that would run again.
readable_condition(q = SVector(0.3, -0.2), acc = 4.0) =
    combine(at("plant", fragment(x = (q = q,))),
            at("ctl", fragment(s = (acc = acc,))),
            at("src", fragment(m = (phase = :running,))),
            fragment(inputs = (u = 1.5, e = 0.0)))

# The read set the two activations share.
readable_reads() = reads(q = get_state("plant", :q), v = get_state("plant", :q, 2),
                         acc = get_state("ctl", :acc), q̇ = get_deriv("plant", :q),
                         a = get_deriv("plant", :q, 2), y = get_output("plant", :y),
                         u = get_input(:u), face = get_face(:y))

# The stores a capture has to reproduce, read straight out of an executor.
world(sim) = (copy(sim.exec.xbuf),
              [s === nothing ? nothing : s[] for s in sim.exec.sstores],
              [m === nothing ? nothing : m[] for m in sim.exec.mstores],
              [port(sim, "", f) for f in sim.deployment.build.structure.root_inputs],
              sim.exec.clock.t)

function test_readers()
    @testset "the five selectors read what they name, at either activation (§14.4)" begin
        for T in (Float64, D8)
            sim = Simulation(readable(), T; h = 1//10)
            init!(sim, readable_condition())
            evaluate!(sim.exec)                     # `ẋ` is integrator scratch: fill it first
            r = _compile_reads(readable_reads(), sim.deployment.build, T)
            v = gather_reads(r, sim.exec)

            @test keys(v) === (:q, :v, :acc, :q̇, :a, :y, :u, :face)
            @test v.q == SVector{2,T}(0.3, -0.2)     # the whole leaf, out of `xbuf`
            @test v.v === v.q[2]                     # `i` indexes the read value
            @test v.acc === 4.0                      # the discrete store, pinned Float64
            @test v.q̇[1] === v.q[2]                  # `state_derivative`'s own output, out of `ẋbuf`
            @test v.a === v.q̇[2]
            @test v.y === v.q[1]                     # the stage-1 port's cell
            @test v.u === T(1.5)                     # the root input cell
            @test v.face === v.y                     # the exported face is its producer's cell

            # The leaf types are the activation's, so a `Dual` world reads `Dual`s
            # and the frozen discrete store stays pinned (§9.4, D-166).
            @test v.q isa SVector{2,T} && v.q̇ isa SVector{2,T} && v.y isa T
            @test v.acc isa Float64
        end
    end

    @testset "the reader is the gather twin: allocation-free over an executor (§14.4, §7.5)" begin
        sim = Simulation(readable(); h = 1//10)
        init!(sim, readable_condition())
        evaluate!(sim.exec)
        reader, exec = _compile_reads(readable_reads(), sim.deployment.build), sim.exec
        gather_reads(reader, exec)
        @test @ballocated(gather_reads($reader, $exec)) == 0
        @test @inferred(gather_reads(reader, exec)) isa NamedTuple
        @test gather_reads(_compile_reads(reads(), sim.deployment.build), exec) === (;)   # the empty set reads nothing
    end

    @testset "resolution collects every violation into one refusal (§14.4, §13.1)" begin
        readable_build = build(readable())
        err = failure(() -> _compile_reads(reads(a = get_state("plnt", :q),
                                               b = get_output("plant", :thrust),
                                               c = get_deriv("ctl", :acc),
                                               d = get_face(:nope)), readable_build))
        @test err isa DiagnosticError && length(diagnostics(err)) == 4              # the full list, one throw
        (a, b_, c, d) = diagnostics(err)
        # The path itself is the walk's refusal, one case over, and the one
        # path arm that now carries a list in hand (§13.3).
        @test a isa PathResolution && a.reason === :unknown_child && a.segment == "plnt" &&
              a.candidates == ["plant", "ctl", "src"]
        @test startswith(a.entry, "the read labeled `a`")
        @test all(x -> x isa TapResolution, (b_, c, d))
        @test b_.reason === :undeclared && b_.declares === :output_port &&
              b_.field === :thrust && b_.candidates == [:y, :power]            # the list in hand
        @test c.selector == "get_deriv(\"ctl\", :acc)" && c.reason === :discrete_deriv
        @test d.reason === :unknown_output_face && d.field === :nope && d.candidates == [:y]
        @test [x.label for x in (b_, c, d)] == [:b, :c, :d]                     # each read, by label

        # An assembly path, a root input read as a face, an index on a scalar leaf,
        # and a state field the component does not declare.
        err = failure(() -> _compile_reads(reads(a = get_output("", :y), b = get_face(:u),
                                               c = get_output("plant", :y, 1),
                                               d = get_state("plant", :ω)),
                                          readable_build))
        (a, b_, c, d) = diagnostics(err)
        @test a.reason === :assembly_path && a.path == "" && a.tap === :y
        @test b_.reason === :root_input_not_face && b_.field === :u
        @test c.reason === :scalar_index && c.index == 1 && c.declared === Float64
        @test d.reason === :undeclared && d.declares === :state_field && d.field === :ω &&
              d.candidates == [:q]

        # The read set is a type, not a NamedTuple: the bare spelling is refused
        # with a directive, not a `MethodError` (§14.2's rule, one case over).
        d = carried(@test_throws DiagnosticError{ReadSetMisuse} _compile_reads((q = get_state("plant", :q),), readable_build))
        @test d.reason === :not_a_read_set
        d = carried(@test_throws DiagnosticError{ReadSetMisuse} reads(q = 2.0))                    # nor is 2.0 a selector
        @test d.reason === :not_a_selector && d.label === :q
    end

    @testset "a read selector's path stays within a concretely declared subtree (§13.3, §14.7, D-125)" begin
        # No mounting exists, so every selector path is authored at the root and
        # walked from it in full: the first segment may be generically held, a
        # segment past one may not. `ConcreteHold`/`GenericHold` hold the same
        # instance two ways (`test_assembly.jl`).
        deep = reads(q = get_state("inner/plant", :q))
        d = only(diagnostics(failure(() -> _compile_reads(deep,
                                              build(GenericHold(SampledLoop()))))))
        @test d isa PathResolution && d.reason === :past_generic && d.segment == "inner"

        # Declaring the field's concrete type restores the deep read legally, with
        # the hard-coding visible in the declaration itself (§13.3).
        sim = Simulation(ConcreteHold(SampledLoop()); h = 1//50)
        init!(sim, combine(at("inner/plant", fragment(x = (q = SVector(0.3, 0.1),))),
                           fragment(inputs = (ref = 1.0,))))
        evaluate!(sim.exec)
        @test gather_reads(_compile_reads(deep, sim.deployment.build), sim.exec).q == SVector(0.3, 0.1)

        # D-125's own remedy, and the one that survives substitution: the seam
        # publishes a face, which is what the read binds to.
        for holder in (ConcreteHold(SampledLoop()), GenericHold(SampledLoop()))
            @test _compile_reads(reads(y = get_face(:y)), build(holder)) isa Reader
        end

        # The walk stops at a primitive here too: a leaf's component-typed field is
        # no level of the build, so the segment past it names no child and the
        # refusal has no list to offer (§8.5, §13.3).
        opaque_build = build(OpaqueHold(OpaqueLeaf(Gain(2.0))))
        d = only(diagnostics(failure(() ->
                _compile_reads(reads(z = get_state("c/hidden", :z)), opaque_build))))
        @test d isa PathResolution && d.reason === :unknown_child
        @test d.segment == "hidden" && d.owner == "`c`" && d.candidates == String[]
        @test startswith(d.entry, "the read labeled `z`")
    end

    @testset "the source rule: a snapshot-bound reader may not name a store selector (§14.4)" begin
        sim = Simulation(readable(); h = 1//10)
        d = carried(@test_throws DiagnosticError{ReadBindingUnresolved} attach!(sim, Pad("t"), Readout(q = get_state("plant", :q))))
        @test d.reason === :store_selector &&
              d.selector == "get_state(\"plant\", :q)"
        d = carried(@test_throws DiagnosticError{ReadBindingUnresolved} attach!(sim, Pad("t"), Readout(y = get_output("plant", :y, 1))))
        @test d.reason === :indexed
        @test isempty(sim.plane.roster)              # every rejection left the roster untouched
    end

    @testset "a reader and a plan belong to one activation, by dispatch (§9.4, §14.4)" begin
        # The offsets, store types and cell addresses a compiled product bakes are
        # one activation's, so a `Float64` product against a `Dual` executor would
        # read and write another cell's slot in silence. The scalar rides in each
        # product's type, the pairing is dispatch, and the mismatch is refused with
        # both scalars named — before anything is touched. §14.4 makes that pairing
        # an invariant the services uphold, so the refusal is an internal assertion
        # and carries no kind name.
        nominal = Simulation(readable(); h = 1//10)
        seeded = Simulation(readable(), D8; h = 1//10)
        init!(seeded, readable_condition())
        before = world(seeded)

        err = failure(() -> gather_reads(_compile_reads(readable_reads(), nominal.deployment.build), seeded.exec))
        @test err isa InternalInvariant         # not a diagnostic kind, and not a DiagnosticError
        @test occursin("compiled at Float64", err.msg) && occursin("Dual{Nothing, Float64, 8}", err.msg)
        # `InternalInvariant` carries a message and no payload by design (D-215),
        # so it is matched on text — it is no diagnostic kind.

        authored = readable_condition()
        err = failure(() -> apply!(seeded.exec, resolve_condition(authored, nominal.deployment.build)))
        @test err isa InternalInvariant
        err = failure(() -> apply!(seeded.exec, compile_plan(authored, nominal.deployment.build), authored))
        @test err isa InternalInvariant

        @test world(seeded) == before                # every refusal left the executor alone
    end

    @testset "the origin is a `Float64`, so a seeded simulation takes `t0` (§12.6, D-260)" begin
        # `t₀` is the grid's anchor and no design reader wants it perturbed, so
        # it is a `Float64` on the clock while `t` stays in the deployment's
        # scalar. A `T`-typed keyword refused `t0 = 0.25` here.
        seeded = Simulation(readable(), D8; h = 1//10)
        init!(seeded, readable_condition(); t0 = 0.25)
        @test seeded.exec.clock.t₀ === 0.25
        @test seeded.exec.clock.t isa D8 && ForwardDiff.value(seeded.exec.clock.t) === 0.25
    end

    @testset "`capture` reads the committed world back as a total condition (§14.1, §14.10)" begin
        sim = Simulation(readable(); h = 1//10)
        twin = Simulation(readable(); h = 1//10)
        init!(sim, readable_condition())

        (captured, t) = capture(sim)
        @test t === 0.0                              # the condition is time-free; `t` rides beside
        @test captured isa ConditionNode
        init!(twin, captured; t0 = t)
        @test world(twin) == world(sim)              # x, every `s` and `m`, root inputs, clock

        # It is total by construction (§14.6): no baseline underneath, and the
        # authored values are what a re-application establishes — the defaults
        # would show as `phase = :idle` and `acc = 0.0`.
        @test resolve_condition(captured, twin.deployment.build).faces == twin.deployment.build.structure.root_inputs
        @test modes(twin, "src") === (phase = :running,)
        @test state(twin, "ctl").acc === 4.0

        # And after a trajectory: the same pair, taken at the run's end, is the
        # warm restart's baseline — clock included, which is what `t0 = t` is for.
        run!(sim; t_end = 0.5)
        @test lifecycle(sim) === :stopped && state(sim, "plant").q != SVector(0.3, -0.2)
        (warm_capture, t2) = capture(sim)
        @test t2 === 0.5
        init!(twin, warm_capture; t0 = t2)
        @test world(twin) == world(sim)
        @test twin.exec.clock.t === 0.5 && twin.exec.clock.t₀ === 0.5
    end

    @testset "`capture` authors level by level, so it re-applies across a generic seam (§14.1, §14.2)" begin
        # The absolute path is a compiled derivative; the authored spelling is one
        # `at` per child segment. Both models hold their children generically — a
        # `Group` through its `children` parameter, `GenericHold` through `L` — so
        # a capture spelled `at("loop/plant", …)` would refuse at its own walk, and
        # the cycle capture → tweak → `init!` would not close (§13.3, §14.2).
        for (model, inputs, leaf) in ((nested, (in = 1.0,), "loop/plant"),
                                      (() -> GenericHold(SampledLoop()), (ref = 1.0,),
                                       "inner/plant"))
            sim = Simulation(model(); h = 1//50)
            init!(sim, fragment(inputs = inputs))
            run!(sim; t_end = 0.1)
            (captured, t) = capture(sim)
            # every `at` names one child
            @test all(p -> !occursin('/', p), prefixes(captured))
            @test !isempty(prefixes(captured))

            twin = Simulation(model(); h = 1//50)
            init!(twin, captured; t0 = t)
            # The continuous stores come back bitwise. The discrete one need not:
            # the re-application runs boundary zero's outgoing transition, which is
            # capture's documented caveat, not a resolution failure — and the
            # controller here is a mover, unlike `readable_condition`'s.
            @test state(twin, leaf).q === state(sim, leaf).q
            @test twin.exec.xbuf == sim.exec.xbuf
            @test twin.exec.clock.t === t
        end
    end

    @testset "`capture` is legal in `initialized` and `stopped`, and nowhere else (§14)" begin
        sim = Simulation(readable(); h = 1//10)
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} capture(sim))
        @test d.op === :capture
        @test d.status === :built && d.legal == [:initialized, :stopped]  # no committed stores yet
        init!(sim, readable_condition())
        @test capture(sim) isa Tuple                         # `initialized`
        run!(sim; t_end = 0.1)
        @test capture(sim) isa Tuple                         # `stopped`

        # `running` is the §11.3 freeze: the loop owns the stores between drains.
        # Both ends of the run are test-controlled, exactly as in test_lifecycle.
        live = Simulation(armed(); h = 1//100)
        init!(live, fragment(inputs = (in = 0.0,)))
        task = Threads.@spawn run!(live; t_end = 3.0e5, stop_on = ("stop",))
        while lifecycle(live) !== :running
            yield()
        end
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} capture(live))
        stage!(live, "in" => 1.0)
        wait(task)
        @test d.op === :capture
        @test d.status === :running
    end
end
