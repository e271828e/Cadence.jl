# --- the build pipeline (§9.2, §9.3): what it refuses, and in which order ------
# `build` is the fixed point the rest stands on, so its refusals are the bulk of
# this file: the probe's four, the tier classifier's, the root input's type under
# fan-out, and the activation seam's lazy lurk. The schedule it derives is here
# too, being the one product visible without a deployment.

# Malformed components for the probe tests. Defined at top level, not inside the
# testset: a declaration written in a local scope binds a *new local function*
# of that name rather than adding a method to the global one (D-164), so `build`
# would dispatch on the untouched global and silently see the fallback
# declarations instead.
struct Undeclared <: AbstractComponent end
output_types(::Undeclared, ::Type{T}) where {T <: Real} = (a = T,)
output_state(::Undeclared, (; t)) = (a = 1.0, b = 2.0)

struct Unproduced <: AbstractComponent end
output_types(::Unproduced, ::Type{T}) where {T <: Real} = (a = T, b = T)
output_state(::Unproduced, (; t)) = (a = 1.0,)

struct BadDerivative <: AbstractComponent end
init_x(::BadDerivative) = (q = SVector(0.0, 0.0),)
state_derivative(::BadDerivative, (; x)) = (q = 0.0,)

# The same law at the leaf: an `Int` rate for a `Float64` state, which the leaf
# count the probe used to compare could not see (§9.5, D-235).
struct IntegerRate <: AbstractComponent end
init_x(::IntegerRate) = (q = 0.0,)
state_derivative(::IntegerRate, (; x)) = (q = 0,)

# And the permutation that is no error at all: names are the pairing (§9.5).
struct ScrambledDerivative <: AbstractComponent end
init_x(::ScrambledDerivative) = (a = 1.0, b = 2.0)
state_derivative(::ScrambledDerivative, (; x)) = (b = 0.0, a = 1.0)

struct NoFlow <: AbstractComponent end
init_x(::NoFlow) = (q = 1.0,)

# A stage that returns bare `(;)` (§5.2, §9.3), one per position. Each produces
# every declared port from the *other* stage, so nothing else is wrong:
# `DeclaredNotProduced` stays silent, and only the dead-stage rule sees it.
struct DeadStateStage <: AbstractComponent end
init_x(::DeadStateStage) = (; a = 0.0)
output_types(::DeadStateStage, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::DeadStateStage, (; x)) = (;)
output_direct(::DeadStateStage, (; x)) = (p = x.a,)
state_derivative(::DeadStateStage, (; x)) = (; a = 0.0)

struct DeadDirectStage <: AbstractComponent end
init_x(::DeadDirectStage) = (; a = 0.0)
output_types(::DeadDirectStage, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::DeadDirectStage, (; x)) = (p = x.a,)
output_direct(::DeadDirectStage, (; x)) = (;)
state_derivative(::DeadDirectStage, (; x)) = (; a = 0.0)

function build_probe_refusals()
    @testset "the probe rejects malformed components (§9.3)" begin
        d = only(diagnostics(failure(() -> build(single(Undeclared())))))
        @test d isa UndeclaredReturnField && d.name === :b && d.candidates == [:a]
        d = only(diagnostics(failure(() -> build(single(Unproduced())))))
        @test d isa DeclaredNotProduced && d.ports == [:b] && d.products == [:a] &&
              d.state_fields == Symbol[]
        d = only(diagnostics(failure(() -> build(single(BadDerivative())))))
        @test d isa ConformanceFailure && d.what == "state_derivative" && d.reason === :field_type &&
              d.field === :q && d.observed === Float64
        d = only(diagnostics(failure(() -> build(single(IntegerRate())))))
        @test d isa ConformanceFailure && d.what == "state_derivative" &&
              d.reason === :field_type && d.observed === Int64 && d.declared === Float64
        @test failure(() -> build(single(ScrambledDerivative()))) === nothing
        sim = Simulation(single(ScrambledDerivative()); h = 1//100)
        @test failure(() -> (init!(sim); run!(sim; t_end = 0.05))) === nothing
        d = only(diagnostics(failure(() -> build(single(NoFlow())))))
        @test d isa StoreWithoutUpdate && d.store === :init_x
    end

    @testset "a stage returning bare `(;)` is dead, whichever position (§5.2, §9.3)" begin
        # The rule is fail-fast and throws alone, beside the shape check, so the
        # carrier is the singular one (D-222).
        err = failure(() -> build(single(DeadStateStage())))
        @test err isa DiagnosticError{DeadStage}
        d = diagnostic(err)
        @test path(d) == "c" && d.stage == "output_state"
        err = failure(() -> build(single(DeadDirectStage())))
        @test err isa DiagnosticError{DeadStage}
        d = diagnostic(err)
        @test path(d) == "c" && d.stage == "output_direct"
    end
end

# --- the feedthrough graph and the schedule (§5.3, §5.5) ----------------------

# Stage 1 returns its two ports in the reverse of the declared order: the product
# is addressed by name, so the `Dataflow`'s two name lists differ here on purpose.
struct SwappedPorts <: AbstractComponent end
init_x(::SwappedPorts) = (p = 1.0, q = 2.0)
output_types(::SwappedPorts, ::Type{T}) where {T <: Real} = (p = T, q = T)
output_state(::SwappedPorts, (; x)) = (q = x.q, p = x.p)
state_derivative(::SwappedPorts, (; x)) = (p = -x.p, q = -x.q)

function build_schedule()
    @testset "the schedule follows the feedthrough graph (§5.3)" begin
        sim = Simulation(feedback_model(); h = 1//1000)
        # sum first (both its inputs are loop-breaking), then ctl, then plant
        paths = [e.comp isa Sum ? :sum : e.comp isa Gain ? :ctl : :plant
                 for e in walked(sim.exec.bodies.sweep_2)]
        @test paths == [:sum, :ctl, :plant]
        @test length(walked(sim.exec.bodies.sweep_1)) == 1
        @test length(walked(sim.exec.bodies.rhs)) == 1
    end

    @testset "the nominal evaluation's products are names and edges (§9.1, D-253)" begin
        # The same model, read off the `Dataflow` rather than off a compiled
        # executor: names and edges, fixed by the structure and one nominal
        # evaluation, with no scalar type in sight.
        b = build(feedback_model())
        df = b.dataflow
        plant, ctl, sm = index_of(b.structure, "plant"), index_of(b.structure, "ctl"),
                         index_of(b.structure, "sum")
        # Every declared port in `output_types` order, split into the stage-1
        # names and the stage-2 remainder. `Plant` returns `y` from stage 1 and
        # `power` from stage 2; `Gain` and `Sum` are stage-2 only.
        @test df.ports[plant] == [:y, :power]
        @test df.stage1[plant] == [:y] && df.stage2[plant] == [:power]
        @test df.ports[ctl] == [:out]
        @test isempty(df.stage1[ctl]) && df.stage2[ctl] == [:out]
        @test df.ports[sm] == [:e]
        @test isempty(df.stage1[sm]) && df.stage2[sm] == [:e]
        # One edge per consumed stage-2 port, on the consumer's row, carrying the
        # producer's index, its port and the consuming face. `sum/b` consumes
        # `plant/y`, a stage-1 port, so the wire that closes the loop is no edge.
        @test df.edges[plant] == [(ctl, :out, :u)]
        @test df.edges[ctl] == [(sm, :e, :e)]
        @test isempty(df.edges[sm])
        # The order the testset above reads off the compiled sweep.
        @test df.order == [sm, ctl, plant]

        # The stage-1 list follows the *return*, the port list the declaration,
        # and the two are free to disagree: the product is a value table read by
        # name (§8.3).
        b2 = build(single(SwappedPorts()))
        i, df2 = index_of(b2.structure, "c"), b2.dataflow
        @test df2.ports[i] == [:p, :q]
        @test df2.stage1[i] == [:q, :p]
        @test isempty(df2.stage2[i])
    end

    @testset "an algebraic loop is a build error (§5.5)" begin
        # `build` alone: rejection needs no deployment, which is the build's
        # split from deployment.
        # One cluster, one diagnostic, and the carrier is the collected one — the
        # policy the stall takes now that a residue can hold several (§5.6).
        err = failure(() -> build(feedback_model(feedback_port = "power")))
        @test err isa DiagnosticError{Vector{Diagnostic}}
        d = only(diagnostics(err))
        @test d isa AlgebraicCycle
        # the walk from the lowest flatten index, and the wires behind it
        @test d.members == ["plant", "sum", "ctl"]
        @test d.wires == ["plant/power" => "sum/b", "sum/e" => "ctl/e", "ctl/out" => "plant/u"]
        # The trace's verdict over this same cluster is asserted below.
    end
end

# --- the algebraic-cycle clusters (§5.5, §5.6, D-012, D-245) ------------------
# The SCC decomposition, then the trace's verdict over it: kind and payload only
# (§13.2). The three message forms are rendered in `test_diagnostics.jl`.

function build_algebraic_cycles()
    @testset "each cluster is one diagnostic and the tail is in none (§5.6, D-012)" begin
        # Two disjoint loops and a tail hanging off `b`. Kahn's residue holds all
        # five, which is the shape D-012 rejects; the decomposition holds two
        # clusters and leaves the innocent tail out of both.
        err = failure(() -> build(Group((a = Gain(1.0), b = Gain(1.0), c = Gain(1.0),
                                         d = Gain(1.0), e = Gain(1.0));
                                        wires = ("a/out" => "b/e", "b/out" => "a/e",
                                                 "c/out" => "d/e", "d/out" => "c/e",
                                                 "b/out" => "e/e"))))
        @test err isa DiagnosticError{Vector{Diagnostic}}
        ds = diagnostics(err)
        @test length(ds) == 2
        @test ds[1].members == ["a", "b"]
        @test ds[1].wires == ["a/out" => "b/e", "b/out" => "a/e"]
        @test ds[2].members == ["c", "d"]
        @test ds[2].wires == ["c/out" => "d/e", "d/out" => "c/e"]
        @test all(d -> !("e" in d.members), ds)
    end

    @testset "a self-wire is a one-member cluster with its wire (§5.6)" begin
        # A self-edge is a nontrivial SCC of size one, and the wire is its own.
        d = only(diagnostics(failure(() -> build(
            Group((plant = Plant(),); wires = ("plant/power" => "plant/u",))))))
        @test d.members == ["plant"]
        @test d.wires == ["plant/power" => "plant/u"]
    end

    @testset "a tangle is one cluster with every wire among its members (§5.6, D-245)" begin
        # Two loops sharing `s`: one cluster, and every wire among its members,
        # the chord `s/e → i/b` included.
        d = only(diagnostics(failure(() -> build(
            Group((s = Sum(), g = Gain(1.0), i = DerivativeFed());
                  wires = ("s/e" => "g/e", "g/out" => "s/a",
                           "s/e" => "i/b", "i/y" => "s/b"),
                  inputs = "a" => "i/a")))))
        @test d.members == ["s", "g", "i"]
        @test d.wires == ["s/e" => "g/e", "s/e" => "i/b",
                          "g/out" => "s/a", "i/y" => "s/b"]
    end

    @testset "a loop every hop routes is real (§5.6)" begin
        d = only(diagnostics(failure(() -> build(feedback_model(feedback_port = "power")))))
        @test d.classification === :real
        @test isempty(d.dead)
        @test d.traced == ["plant" => :global, "sum" => :global, "ctl" => :global]
        # A self-wire is one hop and the same verdict.
        d = only(diagnostics(failure(() -> build(
            Group((plant = Plant(),); wires = ("plant/power" => "plant/u",))))))
        @test d.classification === :real && isempty(d.dead)
        @test d.traced == ["plant" => :global]
    end

    @testset "a hop stage 2 does not route makes the loop artificial (§5.4, §5.6)" begin
        # `DerivativeFed` consumes `b` in `state_derivative` alone, so the wire
        # closing the loop through `b` is §5.4's false dependency.
        d = only(diagnostics(failure(() -> build(
            Group((d = DerivativeFed(), g = Gain(1.0));
                  wires = ("d/y" => "g/e", "g/out" => "d/b"), inputs = "a" => "d/a")))))
        @test d.classification === :artificial
        @test d.dead == [("d", :b, :y)]
        @test d.traced == ["d" => :global, "g" => :global]
        # The same pair closed through `a`, which stage 2 does route, is real.
        d = only(diagnostics(failure(() -> build(
            Group((d = DerivativeFed(), g = Gain(1.0));
                  wires = ("d/y" => "g/e", "g/out" => "d/a"), inputs = "b" => "d/b")))))
        @test d.classification === :real && isempty(d.dead)
    end

    @testset "a tangle is real through its surviving loop and lists the dead chord (D-245)" begin
        # `s ↔ g` survives the trace, so the cluster is real; the chord through
        # `i` is dead and is listed anyway, being a wire the author can delete.
        d = only(diagnostics(failure(() -> build(
            Group((s = Sum(), g = Gain(1.0), i = DerivativeFed());
                  wires = ("s/e" => "g/e", "g/out" => "s/a",
                           "s/e" => "i/b", "i/y" => "s/b"),
                  inputs = "a" => "i/a")))))
        @test d.classification === :real
        @test d.dead == [("i", :b, :y)]
        @test d.traced == ["s" => :global, "g" => :global, "i" => :global]
    end

    @testset "out-of-cycle inputs come from the prefix and never tag (§5.6)" begin
        # `pre` is placed by Kahn, so `i/a` reads its probe product rather than a
        # synthesized value — untagged either way, and the verdict is unchanged.
        d = only(diagnostics(failure(() -> build(
            Group((s = Sum(), g = Gain(1.0), i = DerivativeFed(), pre = Gain(1.0));
                  wires = ("s/e" => "g/e", "g/out" => "s/a", "s/e" => "i/b",
                           "i/y" => "s/b", "pre/out" => "i/a"),
                  inputs = "a" => "pre/e")))))
        @test d.classification === :real
        @test d.dead == [("i", :b, :y)]
        @test d.members == ["s", "g", "i"]
    end

    @testset "a discrete member traces structurally (§5.6)" begin
        # The discrete tier's wholesale-pinned declarations admit no tracer
        # scalar, so every hop is alive by structure alone.
        d = only(diagnostics(failure(() -> build(
            Group((p = DiscreteMap(), q = DiscreteMap());
                  wires = ("p/b" => "q/a", "q/b" => "p/a"))))))
        @test d.classification === :real
        @test d.traced == ["p" => :structural, "q" => :structural]
    end

    @testset "a pinned face traces structurally (§5.6, D-245)" begin
        # A continuous declaration with no walking leaf admits no scalar either.
        d = only(diagnostics(failure(() -> build(
            Group((a = PinnedGain(), b = PinnedGain());
                  wires = ("a/out" => "b/e", "b/out" => "a/e"))))))
        @test d.classification === :real
        @test d.traced == ["a" => :structural, "b" => :structural]
    end

    @testset "a member that throws ships the cluster unclassified (§5.6)" begin
        # Classification is a bonus on the cycle error, never its precondition:
        # the members and the wires still name the loop.
        d = only(diagnostics(failure(() -> build(
            Group((a = TypedGain(), b = TypedGain());
                  wires = ("a/out" => "b/e", "b/out" => "a/e"))))))
        @test d.classification === nothing
        @test isempty(d.dead) && isempty(d.traced)
        @test d.members == ["a", "b"]
        @test d.wires == ["a/out" => "b/e", "b/out" => "a/e"]
    end

    @testset "an input-dependent branch falls back to sampled states (§5.6, D-012)" begin
        # `Piecewise` branches on `v`, an in-cycle face: either arm would drop the
        # other's set, so the global tracer refuses and the local one decides on
        # redrawn primals. `F` routes `f` on both arms, so the loop through `g1`
        # survives the sampled map and the cluster is real.
        loop = Group((m = Piecewise(), g1 = Gain(1.0), g2 = Gain(1.0));
                     wires = ("m/F" => "g1/e", "g1/out" => "m/f", "g1/out" => "m/v",
                              "m/F" => "g2/e", "g2/out" => "m/g"))
        d = only(diagnostics(failure(() -> build(loop))))
        @test d.classification === :real
        @test d.traced == ["m" => :sampled, "g1" => :global, "g2" => :global]
        # `v` rides the positive arm's arithmetic, so its hop lives on the sampled
        # paths; `g` is consumed in `state_derivative` alone and stays dead, a
        # chord the real verdict lists anyway.
        @test d.dead == [("m", :g, :F)]

        # The branch decided at the prefix instead: `v` comes from `g1`, which
        # Kahn places, so it is untagged and the global tracer reads it. The
        # cluster is `m ↔ g2` alone and `g` is its only entering face, which no
        # arm routes — artificial at port level, traced globally throughout.
        d = only(diagnostics(failure(() -> build(
            Group((m = Piecewise(), g1 = Gain(1.0), g2 = Gain(1.0));
                  wires = ("m/F" => "g2/e", "g2/out" => "m/g", "g1/out" => "m/v"),
                  inputs = ("r" => "g1/e", "f" => "m/f"))))))
        @test d.members == ["m", "g2"]
        @test d.classification === :artificial
        @test d.dead == [("m", :g, :F)]
        @test d.traced == ["m" => :global, "g2" => :global]

        # The seed is fixed and per member, so two builds of one model agree —
        # `AlgebraicCycle` has no `==`, so the payload is compared field by field.
        a = only(diagnostics(failure(() -> build(loop))))
        b = only(diagnostics(failure(() -> build(loop))))
        @test (a.members, a.wires, a.classification, a.dead, a.traced) ==
              (b.members, b.wires, b.classification, b.dead, b.traced)
    end

    @testset "the tracer unions sets and refuses a tainted branch (§5.6)" begin
        @test (Tracer{true}(1.0, 0b01) + Tracer{true}(2.0, 0b10)).deps == 0b11
        # May-depend semantics: a saturated `clamp` still reports its set.
        @test clamp(Tracer{true}(5.0, 0b1), 0.0, 1.0).deps == 0b1
        # Either arm would drop the other's set, so the global tracer refuses.
        @test_throws Undecidable Tracer{true}(1.0, 0b1) < Tracer{true}(0.0, UInt64(0))
        @test !(Tracer{true}(1.0, UInt64(0)) < Tracer{true}(0.0, UInt64(0)))
        # The local tracer decides on the primal and reports the taken path.
        @test Tracer{false}(1.0, 0b1) < Tracer{false}(2.0, 0b10)
    end

    @testset "the unary list and the norms carry the set through (§5.6)" begin
        t = Tracer{true}(0.5, 0b1)
        @test atan(t).deps == 0b1
        @test asinh(t).deps == 0b1
        # Base routes `deg2rad` through `float`, the identity here: without its
        # own method the fallback recurses instead of raising a `MethodError`.
        @test deg2rad(t) isa Tracer{true}
        @test deg2rad(t).deps == 0b1
        # The overflow-scaling guards of `hypot` and `norm` compare their
        # operands, which the global tracer refuses; the union answers instead.
        t1, t2, t3 = Tracer{true}(1.0, 0b1), Tracer{true}(2.0, 0b10), Tracer{true}(3.0, 0b100)
        @test hypot(t1, t2, t3).deps == 0b111
        v = SVector(t1, t2, t3)
        @test norm(v).deps == 0b111
        @test norm(v, 1).deps == 0b111
    end
end

# --- the two port classes (§5.3, §8.3, §9.1, D-252) ---------------------------
# The classification alone is here, being what the schedule is built from; the
# runtime properties of the cells it opens belong to the tiers' own files.

function build_port_classes()
    @testset "a state or mode field is exposed by returning it from stage 1 (§5.3, D-252)" begin
        # §8.2's own worked engine: `ω` from `init_x` and `running` from
        # `init_m`, both returned by `output_state`, `M_shaft` the one stage-2
        # product. The products' order is the invariant every downstream reader
        # takes its stage-2 tail off — stage 1, then stage 2.
        b = build(fed(Motor(1.0), "M_load"))
        i = index_of(b.structure, "c")
        @test keys(activation(b, Float64).stage1[i]) === (:ω, :running)
        @test keys(activation(b, Float64).products[i]) === (:ω, :running, :M_shaft)
        # The hand-down carries the stage-1 return, so `y_x` is now in stage 2's
        # bundle.
        @test bundle_names(output_direct, Motor(1.0), CONTINUOUS,
                           tuple(b.dataflow.stage1[i]...)) === (:x, :m, :u, :y_x, :t)
    end

    @testset "a loop closes through a stage-1 port carrying the state vector (§5.3, §5.5)" begin
        # The port takes no input, so consuming it adds no edge.
        @test failure(() -> build(vector_feedback_model())) === nothing
        # The exemption is that port's alone: the same loop routed through
        # `power`, a genuine stage-2 product, is still an algebraic cycle.
        d = only(diagnostics(failure(() -> build(
            Group((plant = VectorPlant(), fb = StateFeedback(1.0), g = Gain(1.0));
                  wires = ("plant/q" => "fb/q", "plant/power" => "g/e",
                           "g/out" => "plant/u"))))))
        @test d.members == ["plant", "g"]
        @test d.wires == ["plant/power" => "g/e", "g/out" => "plant/u"]
    end

    @testset "a declared port no stage returns is refused at every home (§8.3, D-252)" begin
        # One refusal per store home — `s`, then `m`, then `x` — the last of them
        # beside a non-empty product list, so the report tells an unreturned port
        # from a component that produces nothing at all.
        d = only(diagnostics(failure(() -> build(single(UnreturnedCounter())))))
        @test d isa DeclaredNotProduced && d.ports == [:n] && d.products == Symbol[] &&
              d.state_fields == [:n]
        d = only(diagnostics(failure(() -> build(fed(UnreturnedMode(0.315), "sig")))))
        @test d isa DeclaredNotProduced && d.ports == [:tripped] &&
              d.products == Symbol[] && d.state_fields == [:tripped]
        d = only(diagnostics(failure(() -> build(single(ModeNamedProduct())))))
        @test d isa DeclaredNotProduced && d.ports == [:q] && d.products == [:flag] &&
              d.state_fields == [:q, :flag]
    end

    @testset "a port is produced by one stage (§8.3)" begin
        d = carried(@test_throws DiagnosticError{ProducedByTwoStages} build(single(Twice())))
        @test d.ports == [:q]
    end

    @testset "a pinned declaration of a walking field is refused at the stage-1 port check (§9.5, D-166)" begin
        # At the nominal activation the type test is exact; at the walking one
        # the returned port no longer embeds, and taking it stripped would be a
        # stop-gradient the author never wrote.
        b = build(single(PinnedState()))
        d = only(diagnostics(failure(() -> activation(b, D8))))
        @test d isa ConformanceFailure && d.what == "output_state" &&
              d.reason === :field_type && d.field === :q &&
              d.observed === D8 && d.declared === Float64
    end
end

# --- the root input's type, under fan-out (§8.2, D-168) -----------------------
# A root input is produced by no component, so its type comes from the consumer
# declarations alone; with several consumers the concrete declaration has to be
# unique among them.

struct RealEntry <: AbstractComponent            # a `T` entry: follows the activation
end
input_types(::RealEntry, ::Type{T}) where {T<:Real} = (u = T,)
output_types(::RealEntry, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::RealEntry, (; u)) = (y = u.u,)

struct BoolEntry <: AbstractComponent            # ...against a `Bool` at the same face
end
input_types(::BoolEntry, ::Type{T}) where {T<:Real} = (u = Bool,)
output_types(::BoolEntry, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::BoolEntry, (; u)) = (y = u.u ? 1.0 : 0.0,)

struct PinnedEntry <: AbstractComponent          # ...against a pinned `Float64`
end
input_types(::PinnedEntry, ::Type{T}) where {T<:Real} = (u = Float64,)
output_types(::PinnedEntry, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::PinnedEntry, (; u)) = (y = u.u,)

_fanned_root(a, b) = Group((a = a, b = b);
                           inputs = ("in" => ("a/u", "b/u"),), outputs = ("a/y" => "y",))

function build_root_input_type()
    @testset "two consumers of one root input declare one concrete type (§8.2, D-168)" begin
        err = failure(() -> build(_fanned_root(RealEntry(), BoolEntry())))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa RootInputTypeConflict && d.face === :in
        @test d.paths == ["a", "b"] && d.declared == [Float64, Bool]
        @test path(d) == ""                        # the face's own path is the root's

        # It is the structure step's wire pass that catches it, ahead of stage-2 probing —
        # so the surfacing this replaces, the second consumer's probe reading the
        # first's cell, is gone: no `WireTypeMismatch` for this model.
        @test !any(x -> x isa WireTypeMismatch, diagnostics(err))

        # A tolerance difference is no conflict (D-168's meet): `T` and a pinned
        # `Float64` are one type at nominal, and they disagree about partials alone.
        @test build(_fanned_root(RealEntry(), PinnedEntry())) isa Build

        # The meet itself, at a seeded activation: one pinning consumer pins the
        # whole root input, whichever order it is declared in, and the tolerant
        # consumer still walks downstream of its own frozen read (D-168, D-236).
        for m in (_fanned_root(RealEntry(), PinnedEntry()),
                  _fanned_root(PinnedEntry(), RealEntry()))
            sim = Simulation(build(m), D8; h = 1//100)
            @test port(sim, "", :in) isa Float64
            @test port(sim, "a", :y) isa D8
        end

        # With every consumer tolerant the root input follows the scalar.
        simr = Simulation(build(_fanned_root(RealEntry(), RealEntry())), D8; h = 1//100)
        @test port(simr, "", :in) isa D8
    end
end

# --- the two wire clauses in the structure step (§6.1, §9.1, D-236) -----------
# Both clauses are one relation, decided by reading declarations: the bound
# clause at `Float64`, the walk clause at the marker scalar. Fixtures at top
# level, each under the rule it exercises.

# §4.4's substitutability: several concrete producer types behind one stable
# abstract face. Both fields are isbits and made of `Float64`, so they lay out.
abstract type AbstractField end

struct FieldA <: AbstractField
    a::Float64
end

struct FieldB <: AbstractField
    b::SVector{2,Float64}
end

field_scalar(f::FieldA) = f.a
field_scalar(f::FieldB) = sum(f.b)

# Stage-1 sources naming the concrete type. The value is a constant: a `Dual`
# `t` would not convert into the pinned field.
struct FieldSourceA <: AbstractComponent end
output_types(::FieldSourceA, ::Type{T}) where {T<:Real} = (fld = FieldA,)
output_state(::FieldSourceA, (; t)) = (fld = FieldA(2.0),)

struct FieldSourceB <: AbstractComponent end
output_types(::FieldSourceB, ::Type{T}) where {T<:Real} = (fld = FieldB,)
output_state(::FieldSourceB, (; t)) = (fld = FieldB(SVector(1.0, 2.0)),)

struct FieldReader <: AbstractComponent end
input_types(::FieldReader, ::Type{T}) where {T<:Real} = (f = AbstractField,)
output_types(::FieldReader, ::Type{T}) where {T<:Real} = (out = T,)
output_direct(::FieldReader, (; u)) = (out = field_scalar(u.f),)

# An abstract *numeric* entry: `Real` admits the activation scalar and a frozen
# `Float64` alike, and it has no leaves to enumerate.
struct RealReader <: AbstractComponent end
input_types(::RealReader, ::Type{T}) where {T<:Real} = (u = Real,)
output_types(::RealReader, ::Type{T}) where {T<:Real} = (out = T,)
output_direct(::RealReader, (; u)) = (out = 2 * u.u,)

# An abstract container entry against a walking and a pinned producer.
struct VecReader <: AbstractComponent end
input_types(::VecReader, ::Type{T}) where {T<:Real} = (v = AbstractVector{T},)
output_types(::VecReader, ::Type{T}) where {T<:Real} = (n = T,)
output_direct(::VecReader, (; u)) = (n = sum(u.v),)

struct VecSource <: AbstractComponent end
output_types(::VecSource, ::Type{T}) where {T<:Real} = (v = SVector{3,T},)
output_state(::VecSource, (; t)) = (v = SVector(1.0, 2.0, 3.0),)

struct PinnedVecSource <: AbstractComponent end
output_types(::PinnedVecSource, ::Type{T}) where {T<:Real} = (v = SVector{3,Float64},)
output_state(::PinnedVecSource, (; t)) = (v = SVector(1.0, 2.0, 3.0),)

# The concrete co-consumers the abstract container entry fans out beside.
struct SVecEntry <: AbstractComponent end
input_types(::SVecEntry, ::Type{T}) where {T<:Real} = (v = SVector{3,T},)
output_types(::SVecEntry, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::SVecEntry, (; u)) = (y = sum(u.v),)

struct PinnedSVecEntry <: AbstractComponent end
input_types(::PinnedSVecEntry, ::Type{T}) where {T<:Real} = (v = SVector{3,Float64},)
output_types(::PinnedSVecEntry, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::PinnedSVecEntry, (; u)) = (y = sum(u.v),)

# The input-side forgotten `T`: a continuous consumer writing the habitual
# `Float64` at an entry its producer walks (§6.1's failure asymmetry).
struct FrozenEntry <: AbstractComponent end
input_types(::FrozenEntry, ::Type{T}) where {T<:Real} = (u = Float64,)
output_types(::FrozenEntry, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::FrozenEntry, (; u)) = (y = u.u,)

# The same one leaf deep. Only type parameters walk, so a walking struct leaf has
# to be parametric; `Frame{Float64}` freezes what `Frame{T}` produces.
struct Frame{T}
    p::SVector{3,T}
    n::Int
end

struct FrameSource <: AbstractComponent end
output_types(::FrameSource, ::Type{T}) where {T<:Real} = (f = Frame{T},)
output_state(::FrameSource, (; t)) = (f = Frame(SVector(1.0, 2.0, 3.0), 7),)

struct FrameReader <: AbstractComponent end
input_types(::FrameReader, ::Type{T}) where {T<:Real} = (f = Frame{Float64},)
output_types(::FrameReader, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::FrameReader, (; u)) = (y = sum(u.f.p),)

_fanned_v(a, b) = Group((a = a, b = b); inputs = ("in" => ("a/v", "b/v"),))

# A bundle's field names are type parameters, not leaves (D-238): these two
# declarations carry one `T` leaf each and name it differently.
struct BundleB <: AbstractComponent end
output_types(::BundleB, ::Type{T}) where {T<:Real} = (q = @NamedTuple{b::T},)
output_state(::BundleB, (; t)) = (q = (b = 1.0 + t,),)

struct BundleA <: AbstractComponent end
input_types(::BundleA, ::Type{T}) where {T<:Real} = (q = @NamedTuple{a::T},)
output_types(::BundleA, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::BundleA, (; u)) = (y = u.q.a,)

function build_wire_clauses()
    @testset "an abstract entry takes any concrete producer below it (§4.4, §8.2, D-236)" begin
        for (src, want) in ((FieldSourceA(), 2.0), (FieldSourceB(), 3.0))
            m = Group((; s = src, r = FieldReader()); wires = ("s/fld" => "r/f",))
            b = build(m)
            @test b isa Build
            for A in (Float64, D8)
                sim = Simulation(b, A; h = 1//100)
                init!(sim)
                run!(sim; t_end = 0.02)
                # the bundle field carried the concrete type, not the bound
                @test port(sim, "r", :out) == want
            end
        end

        # An abstract numeric entry: `Real` takes the activation scalar, and the
        # consumer's own math promotes behind it.
        b = build(Group((; src = NomSource(), r = RealReader()); wires = ("src/val" => "r/u",)))
        @test b isa Build
        @test port(Simulation(b, D8; h = 1//100), "r", :out) isa D8

        # An abstract container entry: the walking producer matches as declared,
        # the pinned one through the lifted candidate. Its `Float64` sum embeds at
        # the write into a cell declared `T` (D-235).
        for src in (VecSource(), PinnedVecSource())
            m = Group((; s = src, r = VecReader()); wires = ("s/v" => "r/v",))
            sim = Simulation(build(m), D8; h = 1//100)
            @test port(sim, "r", :n) isa D8
        end
    end

    @testset "a root input with no concrete entry is refused (§8.2, D-236)" begin
        err = failure(() -> build(Group((; r = FieldReader()); inputs = ("f" => "r/f",))))
        @test err isa DiagnosticError          # not the raw `ArgumentError` from `leaf_types`
        d = only(diagnostics(err))
        @test d isa AbstractAtRoot && d.face === :f
        @test d.paths == ["r"] && d.declared == [AbstractField]
        @test path(d) == ""                    # the face's own path is the root's

        # Two such faces in one model report together: the pass collects (§13.1).
        err2 = failure(() -> build(Group((; r = FieldReader(), q = RealReader());
                                         inputs = ("f" => "r/f", "u" => "q/u"))))
        ds = diagnostics(err2)
        @test all(x -> x isa AbstractAtRoot, ds)
        @test Set(x.face for x in ds) == Set([:f, :u])
    end

    @testset "an abstract co-consumer votes but does not type a root input (§8.2, D-236)" begin
        # The concrete entry fixes the type; the abstract one is checked against
        # it and takes part in the meet, so no `RootInputTypeConflict`.
        b = build(_fanned_v(VecReader(), SVecEntry()))
        @test b isa Build
        @test port(Simulation(b, D8; h = 1//100), "", :in) isa SVector{3,D8}

        # Beside a pinning co-consumer the whole root input pins (D-168's meet).
        simp = Simulation(build(_fanned_v(VecReader(), PinnedSVecEntry())), D8; h = 1//100)
        @test port(simp, "", :in) isa SVector{3,Float64}

        # An abstract co-consumer whose bound fails is the bound clause's, named
        # against the root input rather than a producing component.
        err = failure(() -> build(Group((a = FieldReader(), b = RealEntry());
                                        inputs = ("in" => ("a/f", "b/u"),))))
        d = only(diagnostics(err))
        @test d isa WireTypeMismatch && d.path == "a" && d.face === :f
        @test d.producer_path == "" && d.producer_port === :in
        @test d.declared === AbstractField && d.observed === Float64
    end

    @testset "the walk clause fails at the first nominal build (§6.1, §8.2, D-236)" begin
        # The input-side forgotten `T`: at the tip this model built clean and
        # detonated only at the first `Dual` activation.
        err = failure(() -> build(Group((; src = NomSource(), c = FrozenEntry());
                                        wires = ("src/val" => "c/u",))))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa WalkingFaceAtFrozenEntry && d.path == "c" && d.face === :u
        @test d.producer_path == "src" && d.producer_port === :val
        @test d.leaf == "" && d.declared === Float64 && d.observed === Marker

        # One leaf deep the offending leaf is named by its dotted spelling.
        err2 = failure(() -> build(Group((; s = FrameSource(), r = FrameReader());
                                         wires = ("s/f" => "r/f",))))
        d2 = only(diagnostics(err2))
        @test d2 isa WalkingFaceAtFrozenEntry && d2.leaf == "p[1]"
        @test d2.declared === Float64 && d2.observed === Marker

        # D-167's tier scope: a discrete consumer takes the bound clause alone, so
        # a continuous producer feeding a pinned discrete entry stays legal.
        @test build(Group((; src = NomSource(), rd = FrozenReader());
                          wires = ("src/val" => "rd/in",))) isa Build
    end

    @testset "the wire pass collects to the structure step's barrier (§13.1, D-229, D-236)" begin
        # The bound clause, both endpoints named.
        err = failure(() -> build(Group((; src = NomSource(), c = BoolEntry());
                                        wires = ("src/val" => "c/u",))))
        d = only(diagnostics(err))
        @test d isa WireTypeMismatch && d.path == "c" && d.face === :u
        @test d.producer_path == "src" && d.producer_port === :val
        @test d.declared === Bool && d.observed === Float64

        # Two bad wires in one model are two diagnostics in one throw.
        err2 = failure(() -> build(Group((; src = NomSource(), c = BoolEntry(), e = BoolEntry());
                                         wires = ("src/val" => "c/u", "src/val" => "e/u"))))
        ds = diagnostics(err2)
        @test length(ds) == 2 && all(x -> x isa WireTypeMismatch, ds)
        @test Set(x.path for x in ds) == Set(["c", "e"])

        # A bound failure, a walk failure and an abstract-at-root face merge.
        err3 = failure(() -> build(Group((; src = NomSource(), c = BoolEntry(),
                                            z = FrozenEntry(), r = FieldReader());
                                         wires = ("src/val" => "c/u", "src/val" => "z/u"),
                                         inputs = ("f" => "r/f",))))
        @test Set(kinds(err3)) ==
              Set([WireTypeMismatch, WalkingFaceAtFrozenEntry, AbstractAtRoot])

        # The dependency rule: the wire pass reads the wiring, which a dirty walk
        # never produced, so an unfed input beside a bad wire reports the walk's
        # kinds alone.
        err4 = failure(() -> build(Group((; src = NomSource(), c = BoolEntry(), lone = RealEntry());
                                         wires = ("src/val" => "c/u",))))
        @test Set(kinds(err4)) == Set([UnconnectedInput])
    end

    @testset "a bundle's field names are part of the entry's type (§6.1, D-238)" begin
        # Same leaf list, different face: the leafwise relation passed this wire
        # the consumer's stage then failed on the missing field at the probe.
        d = only(diagnostics(failure(() -> build(Group((; p = BundleB(), c = BundleA());
                                                       wires = ("p/q" => "c/q",))))))
        @test d isa WireTypeMismatch
        @test d.path == "c" && d.face === :q
        @test d.producer_path == "p" && d.producer_port === :q
        @test d.declared === @NamedTuple{a::Float64}
        @test d.observed === @NamedTuple{b::Float64}
    end
end

# --- the port type the walk cannot lay out (§4.3, §4.4, D-237) ----------------
# `IllegalPortType`'s other two arms, both raised by `cell_layout`: a mutable
# type anywhere the walk visits, and a handle-typed face surfacing as a root
# input, which has no producer and no synthesis. The fixtures are in
# `fixtures.jl`, shared with `test_store.jl`.

# A product-type root input with `Real` leaves and no zero-argument constructor
# (§9.3, D-051): it passes the handle check and reaches the synthesis chain's
# last arm, `P()`. `WithProbe` is the same shape with the remedy the message names.
struct NoDefault{T}
    a::T
    b::T
end
struct Unsynthesized <: AbstractComponent end
input_types(::Unsynthesized, ::Type{T}) where {T <: Real} = (q = NoDefault{T},)
output_types(::Unsynthesized, ::Type{T}) where {T <: Real} = (s = T,)
output_direct(::Unsynthesized, (; u)) = (s = u.q.a + u.q.b,)

struct WithProbe{T}
    a::T
    b::T
end
probe_value(::Type{WithProbe{T}}) where {T} = WithProbe(zero(T), one(T))
struct Synthesized <: AbstractComponent end
input_types(::Synthesized, ::Type{T}) where {T <: Real} = (q = WithProbe{T},)
output_types(::Synthesized, ::Type{T}) where {T <: Real} = (s = T,)
output_direct(::Synthesized, (; u)) = (s = u.q.a + u.q.b,)

# An override that is itself broken: its `MethodError` is the author's, not a
# missing synthesis, and propagates as itself.
struct BrokenProbe{T}
    a::T
end
probe_value(::Type{BrokenProbe{T}}) where {T} = BrokenProbe(sqrt("one"))
struct Misprobed <: AbstractComponent end
input_types(::Misprobed, ::Type{T}) where {T <: Real} = (q = BrokenProbe{T},)
output_types(::Misprobed, ::Type{T}) where {T <: Real} = (s = T,)
output_direct(::Misprobed, (; u)) = (s = u.q.a,)

function build_port_type_refusals()
    @testset "a mutable port and a handle at root are refused (§4.4, D-237)" begin
        d = only(diagnostics(failure(() -> build(Group((; c = MutableSource()))))))
        @test d isa IllegalPortType
        @test d.site === :port && d.reason === :mutable && d.name === :c
        @test d.declared === Cache && d.position == ""      # the port type itself

        # A handle at a root input is refused ahead of `probe_value`, so the
        # surfacing this replaces — a raw `MethodError` from `HeightField()` —
        # is gone.
        err = failure(() -> build(Group((; q = Query()); inputs = ("terrain" => "q/terrain",))))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa IllegalPortType
        @test d.site === :root_input && d.reason === :handle_at_root
        @test d.name === :terrain && d.declared === HeightField
        @test path(d) == ""                                 # the face's own path is the root's

        # A mutable root type is a mutable type first, not a handle: its leaves
        # are not all `Real`, and the reason must still be `:mutable`.
        err = failure(() -> build(Group((; e = MatrixEntry()); inputs = ("m" => "e/m",))))
        d = only(diagnostics(err))
        @test d isa IllegalPortType && d.site === :root_input
        @test d.reason === :mutable && d.position == "" && d.declared === Matrix{Float64}

        # Placement collects, so one model reports both and throws once.
        err2 = failure(() -> build(Group((; c = MutableSource(), q = Query());
                                         inputs = ("terrain" => "q/terrain",))))
        @test err2 isa DiagnosticError
        ds = diagnostics(err2)
        @test length(ds) == 2 && all(d -> d isa IllegalPortType, ds)
        @test Set(d.reason for d in ds) == Set([:mutable, :handle_at_root])
    end

    @testset "a root input the synthesis chain cannot value is `MissingProbeValue`, collected (§9.3, D-051)" begin
        # The chain's last arm is `P()`, and `NoDefault` has no zero-argument
        # constructor.
        err = failure(() -> build(Group((; c = Unsynthesized()); inputs = ("in" => "c/q",))))
        d = only(diagnostics(err))
        @test d isa MissingProbeValue
        @test d.face === :in && d.declared === NoDefault{Float64} && path(d) == ""

        # The remedy the message names: an override, and the value it returns is
        # the one the layout carries.
        b = build(Group((; c = Synthesized()); inputs = ("in" => "c/q",)))
        @test (:in, WithProbe(0.0, 1.0)) in activation(b, Float64).layout.root_inputs

        # Collected: two unsynthesizable faces are one throw carrying both.
        err2 = failure(() -> build(Group((; a = Unsynthesized(), b = Unsynthesized());
                                         inputs = ("in1" => "a/q", "in2" => "b/q"))))
        ds2 = diagnostics(err2)
        @test length(ds2) == 2 && all(d -> d isa MissingProbeValue, ds2)
        @test Set(d.face for d in ds2) == Set([:in1, :in2])

        # An override's own `MethodError` is not a missing synthesis: it
        # propagates as itself, never as this kind.
        err3 = failure(() -> build(Group((; c = Misprobed()); inputs = ("in" => "c/q",))))
        @test err3 isa MethodError
    end

    @testset "an opaque leaf is accepted by identity alone (D-237)" begin
        # Built at `T`, the handle's cell follows the activation and the query
        # carries partials.
        sim = Simulation(offset_model(OffsetAtT()), D8; h = 1//10)
        init!(sim)
        @test port(sim, "src", :terrain) isa OffsetField{D8}
        @test port(sim, "q", :h) isa D8

        # Built from a literal, the nominal build runs and the `Dual` activation
        # is refused at the probe with both types named, where the tip before
        # D-237's identity rule died in a raw `MethodError` from the embedding.
        m = offset_model(OffsetAtLiteral())
        sim = Simulation(m; h = 1//10)
        init!(sim)
        @test port(sim, "q", :h) == 2.0
        d = only(diagnostics(failure(() -> Simulation(m, D8; h = 1//10))))
        @test d isa ConformanceFailure && d.reason === :field_type && d.field === :terrain
        @test d.observed === OffsetField{Float64} && d.declared === OffsetField{D8}
    end
end

# --- the user-code frame at the build (§13.2, D-248) --------------------------
# The framing coverage set: a throw out of each probed function and out of each
# kind of declaration, the seven bundle-law classes, the type match's negative,
# and the two throws that pass through the frame unwrapped.

# A stage that throws: the plain frame names the method, the bundle and the
# probe's inputs.
struct Thrower <: AbstractComponent end
init_x(::Thrower) = (; a = 0.0)
output_types(::Thrower, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::Thrower, (; x)) = error("boom")
state_derivative(::Thrower, (; x)) = (; a = 0.0)

# The same throw with a non-empty `u`: one input face, fed from a root input, so
# the frame carries the synthesized inputs as a spelling.
struct ThrowingDirect <: AbstractComponent end
input_types(::ThrowingDirect, ::Type{T}) where {T <: Real} = (in = T,)
output_types(::ThrowingDirect, ::Type{T}) where {T <: Real} = (p = T,)
output_direct(::ThrowingDirect, (; u)) = error("direct boom")

# A throw out of each other probed function, one fixture each.
struct ThrowingDerivative <: AbstractComponent end
init_x(::ThrowingDerivative) = (; a = 0.0)
output_types(::ThrowingDerivative, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ThrowingDerivative, (; x)) = (p = x.a,)
state_derivative(::ThrowingDerivative, (; x)) = error("derivative boom")

struct ThrowingGuard <: AbstractComponent end
init_x(::ThrowingGuard) = (; a = 0.0)
output_types(::ThrowingGuard, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ThrowingGuard, (; x)) = (p = x.a,)
state_derivative(::ThrowingGuard, (; x)) = (; a = 0.0)
throwing_guard(::ThrowingGuard, (; x)) = error("guard boom")
throwing_guard_handler(::ThrowingGuard, (; x)) = (x = (; a = 0.0),)
state_events(::ThrowingGuard) = (e = StateEvent(throwing_guard, throwing_guard_handler),)

struct ThrowingHandler <: AbstractComponent end
init_x(::ThrowingHandler) = (; a = 0.0)
output_types(::ThrowingHandler, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ThrowingHandler, (; x)) = (p = x.a,)
state_derivative(::ThrowingHandler, (; x)) = (; a = 0.0)
# A sign-form guard, so the probe reaches the handler with a policy in hand.
throwing_handler_guard(::ThrowingHandler, (; x)) = x.a - 1.0
throwing_handler(::ThrowingHandler, (; x)) = error("handler boom")
state_events(::ThrowingHandler) = (e = StateEvent(throwing_handler_guard, throwing_handler),)

struct ThrowingProjection <: AbstractComponent end
init_x(::ThrowingProjection) = (; a = 0.0)
output_types(::ThrowingProjection, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ThrowingProjection, (; x)) = (p = x.a,)
state_derivative(::ThrowingProjection, (; x)) = (; a = 0.0)
state_projection(::ThrowingProjection, x) = error("projection boom")

# Declarations that throw: the frame names the declaration and the walk's path.
# One by value, one by type at `T`, one by allocation, one assembly declaration.
# `BadInit` is taken (`test_devices.jl`), so the four read `Throwing*`.
struct ThrowingInit <: AbstractComponent end
init_x(::ThrowingInit) = error("init boom")
state_derivative(::ThrowingInit, (; x)) = (; a = 0.0)

struct ThrowingInputTypes <: AbstractComponent end
init_x(::ThrowingInputTypes) = (; a = 0.0)
input_types(::ThrowingInputTypes, ::Type{T}) where {T <: Real} = error("input_types boom")
output_types(::ThrowingInputTypes, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ThrowingInputTypes, (; x)) = (p = x.a,)
state_derivative(::ThrowingInputTypes, (; x)) = (; a = 0.0)

struct ThrowingWorkspace <: AbstractComponent end
init_x(::ThrowingWorkspace) = (; a = 0.0)
init_workspace(::ThrowingWorkspace, ::Type{T}) where {T <: Real} = error("workspace boom")
output_types(::ThrowingWorkspace, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ThrowingWorkspace, (; x)) = (p = x.a,)
state_derivative(::ThrowingWorkspace, (; x)) = (; a = 0.0)

struct ThrowingChildren <: AbstractComponent
    inner::ScrambledDerivative
end
ThrowingChildren() = ThrowingChildren(ScrambledDerivative())
child_connections(::ThrowingChildren) = error("child_connections boom")

# Bundle-law misses, one per class and per direction (§5.2): the continuous
# `output_state` reading `m` with no `init_m` (undeclared), `u` (illegal for
# the family), `s` (wrong tier); a discrete `output_state` reading `x` (wrong
# tier); a `state_derivative` reading `y_x` (illegal: that is `output_direct`'s
# name) and `foo` (illegal, a name from nowhere); a guard reading `s`.
struct ReadsM <: AbstractComponent end
init_x(::ReadsM) = (; a = 0.0)
output_types(::ReadsM, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ReadsM, (; x, m)) = (p = x.a,)
state_derivative(::ReadsM, (; x)) = (; a = 0.0)

struct ReadsU <: AbstractComponent end
init_x(::ReadsU) = (; a = 0.0)
output_types(::ReadsU, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ReadsU, (; x, u)) = (p = x.a,)
state_derivative(::ReadsU, (; x)) = (; a = 0.0)

struct ReadsS <: AbstractComponent end
init_x(::ReadsS) = (; a = 0.0)
output_types(::ReadsS, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ReadsS, (; x, s)) = (p = x.a,)
state_derivative(::ReadsS, (; x)) = (; a = 0.0)

struct DiscreteReadsX <: AbstractComponent end
init_s(::DiscreteReadsX) = (n = 0,)
output_types(::DiscreteReadsX) = (p = Int,)
output_state(::DiscreteReadsX, (; s, x)) = (p = s.n,)
state_update(::DiscreteReadsX, (; s)) = (n = s.n + 1,)

struct DerivativeReadsYx <: AbstractComponent end
init_x(::DerivativeReadsYx) = (; a = 0.0)
output_types(::DerivativeReadsYx, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::DerivativeReadsYx, (; x)) = (p = x.a,)
state_derivative(::DerivativeReadsYx, (; x, y_x)) = (; a = 0.0)

struct ReadsFoo <: AbstractComponent end
init_x(::ReadsFoo) = (; a = 0.0)
output_types(::ReadsFoo, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ReadsFoo, (; x)) = (p = x.a,)
state_derivative(::ReadsFoo, (; x, foo)) = (; a = 0.0)

struct GuardReadsS <: AbstractComponent end
init_x(::GuardReadsS) = (; a = 0.0)
output_types(::GuardReadsS, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::GuardReadsS, (; x)) = (p = x.a,)
state_derivative(::GuardReadsS, (; x)) = (; a = 0.0)
guard_reads_s(::GuardReadsS, (; s)) = s.n > 0
guard_reads_s_handler(::GuardReadsS, (; x)) = (x = (; a = 0.0),)
state_events(::GuardReadsS) = (e = StateEvent(guard_reads_s, guard_reads_s_handler),)

# The type match's negative: a `FieldError` on the author's own struct inside
# a stage is not a bundle miss, and frames as the plain frame with the
# `FieldError` as cause.
struct Own; a::Float64; end
struct OwnFieldMiss <: AbstractComponent end
init_x(::OwnFieldMiss) = (; a = 0.0)
output_types(::OwnFieldMiss, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::OwnFieldMiss, (; x)) = (p = Own(x.a).b,)
state_derivative(::OwnFieldMiss, (; x)) = (; a = 0.0)

# The pass-through: a carrier a framework call inside the stage threw, and an
# interrupt, both leave the frame unwrapped.
struct CarrierInside <: AbstractComponent end
init_x(::CarrierInside) = (; a = 0.0)
output_types(::CarrierInside, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::CarrierInside, (; x)) = (fragment(x = 1.0); (p = x.a,))
state_derivative(::CarrierInside, (; x)) = (; a = 0.0)

struct InterruptInside <: AbstractComponent end
init_x(::InterruptInside) = (; a = 0.0)
output_types(::InterruptInside, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::InterruptInside, (; x)) = throw(InterruptException())
state_derivative(::InterruptInside, (; x)) = (; a = 0.0)

# The lateness pair for the runtime arm (§13.4, exercised in `test_failures.jl`):
# the probe only ever takes the early branch, so the build passes and the miss
# surfaces at the frame loop.

# A destructure the probe never sees: `m` is read only past t = 0.05.
struct LateRead <: AbstractComponent end
init_x(::LateRead) = (; a = 0.0)
output_types(::LateRead, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::LateRead, b) = b.t > 0.05 ? (p = b.m.phase,) : (p = b.x.a,)
state_derivative(::LateRead, (; x)) = (; a = 1.0)

# The same lateness on the author's own struct: stays a raw `FieldError`.
struct LateOwnMiss <: AbstractComponent end
init_x(::LateOwnMiss) = (; a = 0.0)
output_types(::LateOwnMiss, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::LateOwnMiss, b) = b.t > 0.05 ? (p = Own(b.x.a).b,) : (p = b.x.a,)
state_derivative(::LateOwnMiss, (; x)) = (; a = 1.0)

function build_user_code_framing()
    @testset "a throw out of a probed function is framed with the method, the bundle and the inputs (§13.2, D-248)" begin
        err = failure(() -> build(single(Thrower())))
        @test err isa DiagnosticError{UserCodeFraming}
        d = diagnostic(err)
        @test path(d) == "c" && d.fn == "output_state"
        @test d.bundle == [:x, :t] && d.inputs == ""
        @test d.cause isa ErrorException

        # A fed face puts the synthesized inputs in the frame.
        d = diagnostic(failure(() -> build(fed(ThrowingDirect(), :in))))
        @test d.fn == "output_direct" && :u in d.bundle
        @test d.inputs == sprint(show, (in = 0.0,); context = :compact => true)

        @test diagnostic(failure(() -> build(single(ThrowingDerivative())))).fn ==
              "state_derivative"
        # The event bundle is the update law's view (§5.2): `x`, the table `y`, `t`.
        d = diagnostic(failure(() -> build(single(ThrowingGuard()))))
        @test d.fn == "guard" && d.bundle == [:x, :y, :t]
        d = diagnostic(failure(() -> build(single(ThrowingHandler()))))
        @test d.fn == "handler" && d.bundle == [:x, :y, :t]
        # `state_projection` takes `x` positionally, so it frames as a declaration.
        @test diagnostic(failure(() -> build(single(ThrowingProjection())))).fn ==
              "state_projection"
    end

    @testset "a throw out of a declaration is framed with the walk's path (§13.2, D-248)" begin
        err = failure(() -> build(single(ThrowingInit())))
        @test err isa DiagnosticError{UserCodeFraming}
        d = diagnostic(err)
        @test d.fn == "init_x" && path(d) == "c" && isempty(d.bundle)
        d = diagnostic(failure(() -> build(single(ThrowingInputTypes()))))
        @test d.fn == "input_types" && path(d) == "c"
        d = diagnostic(failure(() -> build(single(ThrowingWorkspace()))))
        @test d.fn == "init_workspace" && path(d) == "c"
        d = diagnostic(failure(() -> build(Group((; a = ThrowingChildren())))))
        @test d.fn == "child_connections" && path(d) == "a"
    end

    @testset "a bundle field the bundle lacks is `BundleFieldError`, classified (§5.2, §13.2)" begin
        err = failure(() -> build(single(ReadsM())))
        @test err isa DiagnosticError{BundleFieldError}
        d = diagnostic(err)
        @test (d.family, d.field, d.reason) == ("output_state", :m, :undeclared)
        @test d.legal == [:x, :t] && path(d) == "c" && d.tier === :continuous
        for (c, family, field, reason) in
                ((ReadsU(), "output_state", :u, :illegal_for_family),
                 (ReadsS(), "output_state", :s, :wrong_tier),
                 (DerivativeReadsYx(), "state_derivative", :y_x, :illegal_for_family),
                 (ReadsFoo(), "state_derivative", :foo, :illegal_for_family),
                 (GuardReadsS(), "guard", :s, :wrong_tier))
            err = failure(() -> build(single(c)))
            @test err isa DiagnosticError{BundleFieldError}
            @test (diagnostic(err).family, diagnostic(err).field, diagnostic(err).reason) ==
                  (family, field, reason)
        end
        err = failure(() -> build(single(DiscreteReadsX())))
        @test err isa DiagnosticError{BundleFieldError}
        d = diagnostic(err)
        @test (d.family, d.field, d.reason) == ("output_state", :x, :wrong_tier)
        @test d.tier === :discrete
    end

    @testset "the match is by the bundle's own type (§5.2)" begin
        err = failure(() -> build(single(OwnFieldMiss())))
        @test err isa DiagnosticError{UserCodeFraming}
        @test diagnostic(err).cause isa FieldError
    end

    @testset "a carrier and an interrupt pass through the frame unwrapped (§13.2, D-248)" begin
        @test failure(() -> build(single(CarrierInside()))) isa
              DiagnosticError{ConditionNodeMisuse}
        @test failure(() -> build(single(InterruptInside()))) isa InterruptException
    end

    @testset "`classify_bundle_field`'s three classes (§5.2, Appendix B)" begin
        @test classify_bundle_field(:output_state, CONTINUOUS, :m) === :undeclared
        @test classify_bundle_field(:output_state, CONTINUOUS, :u) === :illegal_for_family
        @test classify_bundle_field(:output_state, CONTINUOUS, :Δt) === :wrong_tier
        @test classify_bundle_field(:state_update, DISCRETE, :x) === :wrong_tier
        @test classify_bundle_field(:guard, CONTINUOUS, :foo) === :illegal_for_family
    end

    @testset "the legal sets are Appendix B's eight rows (§5.2)" begin
        @test length(LEGAL_BUNDLE) == 8
    end
end

# --- tier classification (§8.2) -----------------------------------------------
# Tier is read off the declaration shape. `DiscreteCounter` and `DiscreteMap` are
# the two shapes the classifier has to separate (`fixtures.jl`, shared with the
# bundle law in `test_declare.jl`); these are the four ways a declaration set can
# disagree.

struct BothUpdates <: AbstractComponent       # `state_derivative` and `state_update` on one component
end
init_x(::BothUpdates) = (q = 1.0,)
output_types(::BothUpdates, ::Type{T}) where {T <: Real} = (a = T,)
output_state(::BothUpdates, (; x)) = (a = x.q,)
state_derivative(::BothUpdates, (; x)) = (q = 0.0,)
state_update(::BothUpdates, (; x)) = (q = x.q,)

struct WrongArity <: AbstractComponent        # `state_update` beside a two-argument contract
end
init_s(::WrongArity) = (n = 0,)
output_types(::WrongArity, ::Type{T}) where {T <: Real} = (a = T,)
output_state(::WrongArity, (; s)) = (a = 1.0,)
state_update(::WrongArity, (; s)) = (n = s.n,)

struct ModesOnDiscrete <: AbstractComponent   # `init_m` is continuous-only
end
init_s(::ModesOnDiscrete) = (n = 0,)
init_m(::ModesOnDiscrete) = (phase = :idle,)
output_types(::ModesOnDiscrete) = (a = Int,)
output_state(::ModesOnDiscrete, (; s)) = (a = s.n,)
state_update(::ModesOnDiscrete, (; s)) = (n = s.n,)

struct BothArities <: AbstractComponent       # a member of both contract families
end
output_types(::BothArities, ::Type{T}) where {T <: Real} = (a = T,)
output_types(::BothArities) = (a = Float64,)
output_state(::BothArities, (; t)) = (a = 1.0,)

# §8.5's bound arm: a continuous contract whose `T` is narrower than `Real` has
# no method at the marker, so the `::Any` fallback answers with an empty
# declaration and the wire pass would index that emptiness by face.
struct NarrowOutput <: AbstractComponent end
output_types(::NarrowOutput, ::Type{T}) where {T <: AbstractFloat} = (a = T,)
output_state(::NarrowOutput, (; t)) = (a = 1.0,)

struct NarrowInput <: AbstractComponent end
input_types(::NarrowInput, ::Type{T}) where {T <: AbstractFloat} = (u = T,)
output_types(::NarrowInput, ::Type{T}) where {T <: Real} = (y = T,)
output_direct(::NarrowInput, (; u)) = (y = u.u,)

struct AnonBound <: AbstractComponent end
output_types(::AnonBound, ::Type{<:AbstractFloat}) = (a = Float64,)
output_state(::AnonBound, (; t)) = (a = 1.0,)

# --- enum- and Symbol-valued ports (§4.1, §4.3, §8.2, §9.3) --------------------
# The fixtures are in `fixtures.jl`: a discrete producer, a consumer and a
# public mode for each of the two label types.

function build_label_ports()
    @testset "an enum port is one pinned leaf of its own eltype (§4.1, §8.2)" begin
        m = Group((; sel = GearSelector(), rd = GearReader());
                  wires = ("sel/gear" => "rd/gear",), inputs = ("x" => "rd/x",))
        b = build(m)
        sim = Simulation(b; h = 1//10)
        init!(sim, fragment(inputs = (x = 1.0,)))
        @test port(sim, "sel", :gear) === up
        @test port(sim, "rd", :code) == 1
        # The producer's tick moves the store, and the cell follows it whole.
        run!(sim; t_end = 0.1)
        @test port(sim, "sel", :gear) === down
        @test port(sim, "rd", :code) == 2
        # At the walking activation the real walks and the enum pins; the
        # discrete producer is outside that activation's executable set (D-052),
        # so its cell holds the nominal probe's product.
        simd = Simulation(b, D8; h = 1//10)
        init!(simd, fragment(inputs = (x = 1.0,)))
        @test port(simd, "rd", :drag) isa D8
        @test port(simd, "sel", :gear) === up
    end

    @testset "an enum root input is synthesized as the first instance (§9.3, D-051)" begin
        m = Group((; rd = GearReader()); inputs = ("gear" => "rd/gear", "x" => "rd/x"))
        b = build(m)
        @test activation(b, Float64).products[index_of(b.structure, "rd")].code == 1
        # Probe values are probe-scoped: the run's value is the one the fragment
        # authored, and an enum converts through the condition apply as itself.
        sim = Simulation(b; h = 1//10)
        init!(sim, fragment(inputs = (gear = down, x = 1.0)))
        @test port(sim, "", :gear) === down
        @test port(sim, "rd", :code) == 2
    end

    @testset "an enum mode is returned from stage 1 (§7.5)" begin
        b = build(single(GearMode()))
        i = index_of(b.structure, "c")
        @test activation(b, Float64).stage1[i] === (gear = up, y = 0.0)
        @test keys(activation(b, D8).stage1[i]) === (:gear, :y)
        sim = Simulation(b, D8; h = 1//10)
        @test port(sim, "c", :gear) === up
    end

    @testset "a Symbol port is one opaque leaf, with no synthesis at a root (§4.3, D-243)" begin
        m = Group((; sel = PhaseSelector(), rd = PhaseReader());
                  wires = ("sel/phase" => "rd/phase",))
        sim = Simulation(build(m); h = 1//10)
        init!(sim, fragment())
        @test port(sim, "sel", :phase) === :idle && !port(sim, "rd", :armed)
        run!(sim; t_end = 0.1)
        @test port(sim, "sel", :phase) === :armed && port(sim, "rd", :armed)

        # The mode label is returned (§7.5's remedy on the idiomatic label).
        b = build(single(PhaseMode()))
        @test activation(b, Float64).stage1[index_of(b.structure, "c")] === (phase = :idle, y = 0.0)

        # At a root input the leaf has no synthesis, so the refusal is the
        # opaque leaf's, ahead of `probe_value`.
        d = only(diagnostics(failure(() -> build(fed(PhaseReader(), "phase")))))
        @test d isa IllegalPortType && d.site === :root_input
        @test d.reason === :handle_at_root && d.declared === Symbol
    end
end

function build_tier()
    @testset "tier is read off the declaration shape (§8.2)" begin
        # The two deciders: the update law for a stateful leaf, the contract arity
        # for a stateless one.
        diags = Diagnostic[]
        @test classify_tier("c", Plant(), diags) === CONTINUOUS
        @test classify_tier("c", Gain(1.0), diags) === CONTINUOUS
        @test classify_tier("c", DiscreteCounter(), diags) === DISCRETE
        @test classify_tier("c", DiscreteMap(), diags) === DISCRETE
        @test isempty(diags)

        # Disagreement names the offending declaration and the tier the rest
        # announce (§8.2). The classifier records and returns no tier.
        for (c, offender) in ((BothUpdates(), :state_update), (ModesOnDiscrete(), :init_m))
            diags = Diagnostic[]
            @test classify_tier("c", c, diags) === nothing
            # The vote loop collects: every declaration off the announced tier is
            # reported, and the one this case is written around is among them.
            @test all(d -> d isa DeclarationOnWrongTier && d.reason === :tier_form, diags)
            @test offender in [d.declaration for d in diags]
        end

        # A contract arity against the announced tier is the contract's own kind,
        # on a stateful leaf and a stateless one alike (§8.5, D-249). `WrongArity`
        # announces discrete in its store and update law; `BothArities` declares
        # `output_types` twice, the second form reported against the first.
        for (c, tier, found, mandated) in ((WrongArity(), :discrete, :two_argument, :plain),
                                           (BothArities(), :continuous, :plain, :two_argument))
            diags = Diagnostic[]
            @test classify_tier("c", c, diags) === nothing
            d = only(diags)
            @test d isa TierSignatureMismatch && d.reason === :arity
            @test d.declaration === :output_types && d.tier === tier
            @test d.found === found && d.mandated === mandated
        end

        # A store with no update law is §8.2's sibling of the classless component.
        diags = Diagnostic[]
        @test classify_tier("c", NoFlow(), diags) === nothing
        @test only(diags) isa StoreWithoutUpdate

        # The tier twin of `ClassUnreadable` (§8.2, D-215): no store to decide the
        # tier and no `output_types` to read it off. `init_m` and a derivative vote
        # continuous, but neither is a decider, so the payload carries what the
        # component does declare against the whole tier-announcing family.
        diags = Diagnostic[]
        @test classify_tier("c", ModesNoContract(), diags) === nothing
        d = only(diags)
        @test d isa TierUnreadable && path(d) == "c" && d.type == "ModesNoContract"
        @test d.declarations == [:state_derivative, :init_m]
        @test d.family == [:state_derivative, :state_update, :init_x, :init_s, :init_m,
                           :state_events, :output_types, :input_types, :init_workspace]

        # The base tick period is deployment's, not the build's: the same `Build`
        # deploys at any admissible grid, and the executor cannot exist before one
        # binds because `Δt`, `D` and `Φ` are entry-field data (§9.1, §9.7).
        b = build(single(DiscreteCounter()))
        @test b isa Build
        d = only(diagnostics(failure(() -> Simulation(b))))
        @test d isa DeploymentInvalid
        @test d.parameter === :h && d.reason === :missing
        @test Simulation(b; h = 1//10) isa Simulation
    end

    @testset "a continuous contract bounded narrower than Real is refused (§8.5)" begin
        d = only(diagnostics(failure(() -> build(single(NarrowOutput())))))
        @test d isa TierSignatureMismatch
        @test path(d) == "c" && d.declaration === :output_types && d.tier === :continuous
        @test d.reason === :bound && d.found === AbstractFloat && d.mandated === Real

        # The anonymous form `::Type{<:AbstractFloat}` names no `T`; its bound is read
        # off the argument type.
        da = only(diagnostics(failure(() -> build(single(AnonBound())))))
        @test da isa TierSignatureMismatch && da.found === AbstractFloat

        # The wire it feeds is skipped, so the refusal is the whole report.
        d2 = only(diagnostics(failure(() -> build(Group((; p = NarrowOutput(), c = RealEntry());
                                                        wires = ("p/a" => "c/u",))))))
        @test d2 isa TierSignatureMismatch && d2.declaration === :output_types

        d3 = only(diagnostics(failure(() -> build(Group((; src = NomSource(), c = NarrowInput());
                                                        wires = ("src/val" => "c/u",))))))
        @test d3 isa TierSignatureMismatch && path(d3) == "c" && d3.declaration === :input_types

        # Both refusals and an unrelated walk failure merge into one throw.
        err = failure(() -> build(Group((; p = NarrowOutput(), n = NarrowInput(),
                                           src = NomSource(), z = FrozenEntry());
                                        wires = ("src/val" => "n/u", "src/val" => "z/u"))))
        ds = diagnostics(err)
        @test err isa DiagnosticError && length(ds) == 3
        @test Set(kinds(err)) == Set([TierSignatureMismatch, WalkingFaceAtFrozenEntry])
        @test Set((d.path, d.declaration) for d in ds if d isa TierSignatureMismatch) ==
              Set([("p", :output_types), ("n", :input_types)])
    end
end

# --- The structure step's one barrier (§13.1, D-229) --------------------------

# One failure from each of the step's passes, in one model: a wire typo'd on
# the producer's port, the input it leaves unfed, a store with no update law, an
# event missing its handler and a store that is not a `NamedTuple`. `HalfEvent`
# is `test_events.jl`'s, which this file precedes, so the children are a
# `Group`'s values rather than a struct's declared fields.
merged_failures() = Group((; g = Gain(1.0), s = Sum(), n = NoFlow(), h = HalfEvent(),
                             f = BareState());
                          wires = ("g/ot" => "s/a",),
                          inputs = ("e" => "g/e", "b" => "s/b"))

# A store that is not a `NamedTuple` (§8.2, D-247), one per store. `BareVector`
# is the value that segfaulted the generated `reconstruct` before the check;
# `BareModes` is the one that built silently, and it carries a vocabulary fault
# in its other store: the only finding is still the form, because the field
# checks do not read a primitive the form check refused.
struct BareState <: AbstractComponent end
init_x(::BareState) = zeros(SVector{3})
state_derivative(::BareState, (; x)) = zeros(SVector{3})

struct BareVector <: AbstractComponent end
init_x(::BareVector) = [1.0]
state_derivative(::BareVector, (; x)) = [0.0]

struct BareDiscrete <: AbstractComponent end
init_s(::BareDiscrete) = 0.0
output_types(::BareDiscrete) = (a = Float64,)
output_state(::BareDiscrete, (; s)) = (a = s,)
state_update(::BareDiscrete, (; s)) = s

struct BareModes <: AbstractComponent end
init_x(::BareModes) = (gear_count = 3,)      # `IllegalStateLeaf`, were it read
init_m(::BareModes) = 1
state_derivative(::BareModes, (; x)) = (gear_count = 0,)

struct LabelInStore <: AbstractComponent end   # a `String` in `init_s` (D-231)
init_s(::LabelInStore) = (n = 0, phase = :armed, label = "armed")
output_types(::LabelInStore) = (a = Int,)
output_state(::LabelInStore, (; s)) = (a = s.n,)
state_update(::LabelInStore, (; s)) = (n = s.n, phase = s.phase, label = s.label)

struct LabelInModes <: AbstractComponent end   # a `String` in `init_m`
init_x(::LabelInModes) = (q = 1.0,)
init_m(::LabelInModes) = (phase = :idle, label = "x")
output_types(::LabelInModes, ::Type{T}) where {T <: Real} = (a = T,)
output_state(::LabelInModes, (; x)) = (a = x.q,)
state_derivative(::LabelInModes, (; x)) = (q = 0.0,)

# `init_x` fields outside §7.1's closed vocabulary, one per arm. `UnitVec` is
# D-094's rejected shape: a normalizing inner constructor that would run on
# every view. The derivatives exist so the tier reads clean and the vocabulary
# check is the only finding.
struct UnitVec
    v::SVector{2,Float64}
    UnitVec(v) = new(v / norm(v))
end

struct ModeInState <: AbstractComponent end
init_x(::ModeInState) = (gear_count = 3, armed = true, ω = 0.0)
state_derivative(::ModeInState, (; x)) = (gear_count = 0, armed = false, ω = 0.0)

struct NarrowState <: AbstractComponent end
init_x(::NarrowState) = (q = 1.0f0, v = SVector{2,Int}(1, 2))
state_derivative(::NarrowState, (; x)) = (q = 0.0f0, v = SVector{2,Int}(0, 0))

struct ShapedState <: AbstractComponent end
init_x(::ShapedState) = (pose = (x = 0.0, v = 0.0), u = UnitVec(SVector(3.0, 4.0)), ω = 0.0)
state_derivative(::ShapedState, (; x)) = (pose = (x = 0.0, v = 0.0), u = x.u, ω = 0.0)

function build_state_leaves()
    @testset "an init_x field is a Float64 or an SArray of them, flat (§7.1, §8.2, D-094)" begin
        # One throw for the whole model, every offending field named with the
        # arm that says where the value belongs; the `Float64` leaves pass.
        err = failure(() -> build(Group((; a = ModeInState(), b = NarrowState(),
                                          c = ShapedState()))))
        ds = diagnostics(err)
        @test all(d -> d isa IllegalStateLeaf, ds)
        @test Set((d.path, d.name, d.declared, d.reason) for d in ds) ==
              Set([("a", :gear_count, Int, :mode_value), ("a", :armed, Bool, :mode_value),
                   ("b", :q, Float32, :eltype), ("b", :v, SVector{2,Int}, :mode_value),
                   ("c", :pose, typeof((x = 0.0, v = 0.0)), :nested),
                   ("c", :u, UnitVec, :wrapper)])
    end
end

function build_store_values()
    @testset "a store field is isbits or a Symbol, checked field by field (§7.3, D-231)" begin
        # The `String` fields are refused, one throw for both stores; the `Symbol`
        # modes beside them pass.
        err = failure(() -> build(Group((; a = LabelInStore(), b = LabelInModes()))))
        ds = diagnostics(err)
        @test all(d -> d isa IllegalStoreField, ds)
        @test Set((d.path, d.store, d.name, d.declared) for d in ds) ==
              Set([("a", :init_s, :label, String), ("b", :init_m, :label, String)])
    end
end

function build_store_form()
    @testset "a store declaration is a NamedTuple, checked before the stores are read (§8.2, §9.1, D-247)" begin
        # One throw for the model, each bare store named with the store at fault
        # and the type it returned. `BareModes`' `gear_count` raises no
        # `IllegalStateLeaf`: the form check refused the primitive, and the
        # vocabulary check never read it.
        err = failure(() -> build(Group((; a = BareState(), b = BareVector(),
                                          c = BareDiscrete(), d = BareModes()))))
        ds = diagnostics(err)
        @test all(d -> d isa StoreNotNamedTuple, ds)
        @test Set(kinds(err)) == Set([StoreNotNamedTuple])
        @test Set((d.path, d.store, d.declared) for d in ds) ==
              Set([("a", :init_x, SVector{3,Float64}), ("b", :init_x, Vector{Float64}),
                   ("c", :init_s, Float64), ("d", :init_m, Int)])
    end
end

function build_barrier()
    @testset "every structure-step pass that ran merges into one throw (§13.1, D-229)" begin
        # The wiring walk, the obligation check, tier classification, the event
        # declarations and the store form each read a result the others did not
        # spoil, so all five run and the model is refused once.
        err = failure(() -> build(merged_failures()))
        @test Set(kinds(err)) ==
              Set([UnknownPort, UnconnectedInput, StoreWithoutUpdate, EventHalfMissing,
                   StoreNotNamedTuple])
    end
end

# --- the activation seam (§9.4, D-166) ----------------------------------------
# Shared fixture: the embed-accept and activation sections both build a
# `PinnedGetsDual`.

# A `Dual` arriving at a deliberately pinned leaf: the one honest cause, and the
# one that earns the didactic hint.
struct PinnedGetsDual <: AbstractComponent end
output_types(::PinnedGetsDual, ::Type{T}) where {T <: Real} = (frozen = Float64,)
output_state(::PinnedGetsDual, (; t)) = (frozen = t,)

# The constant-branch idiom (D-166): a literal `Float64` returned into a
# declared-`T` port is a lawful arrival, embedded as a zero-partial.
struct ConstantBranch <: AbstractComponent end
input_types(::ConstantBranch, ::Type{T}) where {T <: Real} = (in = T,)
output_types(::ConstantBranch, ::Type{T}) where {T <: Real} = (out = T, vec = SVector{2,T})
output_direct(::ConstantBranch, (; u)) = (out = u.in > 0 ? u.in : 0.0, vec = SVector(0.0, 1.0))

function build_embed_accept()
    @testset "a mixed-leaf port embeds leaf by leaf (§4.1, §9.4, D-166)" begin
        # The enum leaf is pinned and passes through; the `Float64` beside it
        # lifts to the activation scalar as a zero-partial.
        b = build(Group((; c = GearStateSource())))
        v = activation(b, D8).products[index_of(b.structure, "c")].gs
        @test v isa GearState{D8} && v.gear === down && ForwardDiff.value(v.h) == 1.0
    end

    @testset "embed-accept keeps the constant branch legal (D-166)" begin
        # Both ports return literal `Float64`s at a `Dual` activation — the scalar
        # through a branch not taken, the `SVector` wholesale.
        sim = Simulation(Group((; c = ConstantBranch()); inputs = ("in" => "c/in",)),
                         D8; h = 1//100)
        init!(sim, fragment(inputs = (in = 0.0,)))
        # What the table holds is the cell's type, the constant embedded into it.
        @test port(sim, "c", :out) isa D8
        @test port(sim, "c", :vec) isa SVector{2,D8}
        @test ForwardDiff.value(port(sim, "c", :vec)[2]) == 1.0

        # The converse is not accepted: a `Dual` at a pinned leaf is an error, with
        # the hint that names the one honest cause. It fails at the `Dual`
        # activation's own lazy derivation, not at `build` (§9.4's lazy lurk).
        b = build(single(PinnedGetsDual()))
        err = failure(() -> activation(b, D8))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa ConformanceFailure && d.shape === :ports && d.reason === :field_type
        @test d.declared === Float64 && d.observed === D8 && d.activation === D8
    end
end

# The activation seam (§9.1, §9.4): the nominal activation runs at build, any
# other is a cached activation derived from the nominal one, and a frozen
# component's products are carried across from the nominal activation rather
# than probed or synthesized.
struct NomSource <: AbstractComponent end
output_types(::NomSource, ::Type{T}) where {T <: Real} = (val = T,)
output_state(::NomSource, (; t)) = (val = 3.0 + t,)

struct FrozenReader <: AbstractComponent end
input_types(::FrozenReader) = (in = Float64,)
output_types(::FrozenReader) = (out = Float64,)
output_direct(::FrozenReader, (; u)) = (out = 2.0 * u.in,)

struct ClockStamp <: AbstractComponent end
output_types(::ClockStamp) = (stamp = Float64,)
output_state(::ClockStamp, (; t)) = (stamp = t,)

function build_activations()
    @testset "a non-nominal activation is derived from the nominal one; frozen products carry (§9.4)" begin
        pair() = Group((; src = NomSource(), rd = FrozenReader());
                       wires = ("src/val" => "rd/in",))

        # The nominal activation runs at build and *is* the Float64 activation; a
        # non-nominal one materializes at first request and is cached on the Build.
        b = build(pair())
        @test activation(b, Float64) === b.activations[Float64]
        @test activation(b, D8) === activation(b, D8)

        # The frozen reader's cells hold what the *nominal* probe computed from its
        # real upstream value — 2·(3.0 + 0.0) — not a value synthesized off its
        # declaration. Its cell pins while its producer's walks.
        simd = Simulation(b, D8; h = 1//100)
        @test port(simd, "src", :val) isa D8
        @test port(simd, "rd", :out) === 6.0

        # A discrete stage is never probed at a non-nominal activation (§9.4's
        # executable set): `t` in a discrete bundle is lawful, because it is a
        # `Float64` whenever the stage actually runs — so this must not detonate
        # as a `Dual` arriving at a pinned declaration.
        sims = Simulation(single(ClockStamp()), D8; h = 1//100)
        @test port(sims, "c", :stamp) === 0.0

        # The framework's canonical probe scalar (§9.4): concrete, so it can key
        # an activation, and one partial wide, because what CI pins is genericity
        # and not any particular Jacobian.
        @test isconcretetype(ProbeDual)
        @test ProbeDual <: ForwardDiff.Dual && ForwardDiff.npartials(ProbeDual) == 1
        @test haskey(build(pair(); activations = (Float64, ProbeDual)).activations, ProbeDual)

        # §9.4's opt-in exhaustive mode: the listed activations materialize at
        # build time, which is where CI catches a lurking pinned leaf. D-166's
        # CI pin is spelled with `ProbeDual`; `D8` stands in for a trim's or a
        # user's own activation elsewhere in the suite.
        err = failure(() -> build(single(PinnedGetsDual());
                                  activations = (Float64, ProbeDual)))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa ConformanceFailure && d.declared === Float64 &&
              d.activation === ProbeDual
    end

    @testset "concurrent first requests share one activation (§9.4's torn-state guarantee)" begin
        # Several tasks race for the same non-nominal activation on a fresh
        # build: the cache is guarded, so every caller gets the one object the
        # first writer stored and the cache holds a single entry. Under one
        # thread the tasks serialize and the test pins the contract at no cost.
        b = build(Group((; src = NomSource(), rd = FrozenReader());
                        wires = ("src/val" => "rd/in",)))
        acts = fetch.([Threads.@spawn activation(b, D8) for _ in 1:8])
        @test all(a -> a === first(acts), acts)
        @test first(acts) === activation(b, D8)
        # Two entries: the nominal `Float64` one the build inserted, and the
        # single `D8` one the race produced.
        @test length(b.activations) == 2
    end
end

# --- the build's warnings (§9.1, §13.2, D-250) --------------------------------
# The channel is exercised by a test-local warning kind and two assemblies whose
# declaration bodies raise it: a synthetic kind tests the channel without the
# producer's own selection logic, so what these tests prove stays theirs while
# `EmptyFaceSelection`'s own testset below covers the producer. The body is a
# boundary declaration because that is where the real producer sits, and the
# walk reads each boundary declaration once: one evaluation feeds both the
# face-name check and the face pass, so a warning raised inside one fires once
# per call (Appendix C).

struct SyntheticWarning <: Diagnostic
    note::String
end
severity(::SyntheticWarning) = :warning
message(d::SyntheticWarning) = d.note

# An assembly whose declaration body warns through the channel, and whose model
# is otherwise sound: the build completes and carries the warning.
struct WarningWires <: AbstractComponent
    c::Gain
end
child_connections(::WarningWires) = ()
input_connections(::WarningWires) = (_warn!(SyntheticWarning("synthetic")); ("in" => "c/e",))
output_connections(::WarningWires) = ("c/out" => "out",)

# The same warning under a model that cannot build: nothing feeds the gain's
# input, so the structure step throws and the warning travels with it.
struct WarningUnfed <: AbstractComponent
    c::Gain
end
child_connections(::WarningUnfed) = ()
# The empty tuple declares no input face, so the gain stays unfed.
input_connections(::WarningUnfed) = (_warn!(SyntheticWarning("unfed")); ())
output_connections(::WarningUnfed) = ("c/out" => "out",)

# The shapes that ask a child for its face lists (§13.3, Appendix C). A parent
# computing its whole boundary off `WarningWires` asks the primitives for the
# child's lists, and a grandparent asks again one level up; without the walk's
# memo each asker re-evaluates the child's `input_connections` and the warning
# fires once per level.
struct WarningPassthrough <: AbstractComponent
    w::WarningWires
end
child_connections(::WarningPassthrough) = ()
input_connections(p::WarningPassthrough) = input_passthrough(p, "w")
output_connections(p::WarningPassthrough) = output_passthrough(p, "w")

struct WarningGrandparent <: AbstractComponent
    p::WarningPassthrough
end
child_connections(::WarningGrandparent) = ()
input_connections(g::WarningGrandparent) = input_passthrough(g, "p")
output_connections(g::WarningGrandparent) = output_passthrough(g, "p")

# The did-you-mean path: the wire names a face the child does not have, so
# endpoint resolution asks the child for both face lists to build the candidate
# list. The step throws, and the warning still travels with it once.
struct WarningTypo <: AbstractComponent
    w::WarningWires
    g::Gain
end
child_connections(::WarningTypo) = ("w/nope" => "g/e",)
input_connections(::WarningTypo) = ("in" => "w/in",)
output_connections(::WarningTypo) = ("g/out" => "out",)

# §8.8's producer: `except` naming every input face of the child keeps nothing,
# so the helper warns, while the hand-written wire feeds the face the boundary no
# longer exposes and the build completes (D-251).
struct EmptySelection <: AbstractComponent
    g::Gain
    src::Gain
end
child_connections(::EmptySelection) = ("src/out" => "g/e",)
input_connections(a::EmptySelection) = (input_passthrough(a, "g"; except = ("e",))...,
                                        "in" => "src/e")
output_connections(::EmptySelection) = ("g/out" => "out",)

# The same shape with one anchored discrete child, so that the build warns and
# the deployment warns too: `warnings(sim)` is the concatenation of both lists
# (§9.2, D-250), and each artifact holds its own.
struct EmptySelectionRated <: AbstractComponent
    g::Gain
    src::Gain
    c::TickCounter
end
child_connections(::EmptySelectionRated) = ("src/out" => "g/e",)
input_connections(a::EmptySelectionRated) = (input_passthrough(a, "g"; except = ("e",))...,
                                             "in" => "src/e")
output_connections(::EmptySelectionRated) = ("g/out" => "out",)
sample_times(::EmptySelectionRated) = (; c = Absolute(Hz(50), 1//100))

# One passthrough level above it, which asks the child for its face lists: the
# walk's memo keeps the warning's count at one (§13.3, Appendix C).
struct EmptySelectionParent <: AbstractComponent
    kid::EmptySelection
end
child_connections(::EmptySelectionParent) = ()
input_connections(p::EmptySelectionParent) = input_passthrough(p, "kid")
output_connections(p::EmptySelectionParent) = output_passthrough(p, "kid")

function build_warnings()
    @testset "a warning raised inside a declaration body lands on the Build and is logged once at return (§9.1, D-250)" begin
        # A declaration body has no artifact in hand, so it appends through the
        # channel `build` binds. The completed build carries the record and the
        # entry point logs it once at return — logging is presentation, never a
        # home — and the binding is gone once `build` returns.
        b = @test_logs (:warn, r"^SyntheticWarning: synthetic") build(WarningWires(Gain(1.0)))
        @test only(warnings(b)) isa SyntheticWarning
        @test only(warnings(b)).note == "synthetic"
        @test BUILD_WARNINGS[] === nothing
        # One level down the count is still one: the parent's wiring names the
        # child's faces without evaluating the child's declaration bodies.
        n = @test_logs (:warn, r"^SyntheticWarning: synthetic") build(
            Group((; w = WarningWires(Gain(1.0)));
                  inputs = ("in" => "w/in",), outputs = ("w/out" => "out",)))
        @test only(warnings(n)) isa SyntheticWarning
        # A passthrough level asks the child for its face lists, and a second
        # level asks again: the count stays one because the walk records each
        # assembly's evaluated lists and the primitives read them (§13.3,
        # Appendix C).
        p = @test_logs (:warn, r"^SyntheticWarning: synthetic") build(
            WarningPassthrough(WarningWires(Gain(1.0))))
        @test length(warnings(p)) == 1
        @test only(warnings(p)) isa SyntheticWarning
        g = @test_logs (:warn, r"^SyntheticWarning: synthetic") build(
            WarningGrandparent(WarningPassthrough(WarningWires(Gain(1.0)))))
        @test length(warnings(g)) == 1
        # The memo is the walk's, and the binding is gone once `build` returns.
        @test WALK_FACES[] === nothing
    end

    @testset "a step that throws carries its warnings beside the collection (§9.1, D-250)" begin
        # The artifact that would have carried the warning never returned, so
        # the throw renders it beside the collection. Nothing is logged: the log
        # line at return belongs to a build that completed. `failure` returns the
        # throw rather than propagating it, so `@test_logs` sees the whole call.
        e = @test_logs failure(() -> build(WarningUnfed(Gain(1.0))))
        @test kinds(e) == [UnconnectedInput]
        @test length(e.warnings) == 1
        # A warning joins no collection (Appendix C): the accessors never see it.
        @test only(diagnostics(e)) isa UnconnectedInput
        # The did-you-mean path asks the child for both face lists, after the
        # walk recorded them: the throw carries one warning, not one per asker.
        t = @test_logs failure(() -> build(WarningTypo(WarningWires(Gain(1.0)), Gain(1.0))))
        @test UnknownPort in kinds(t)
        @test length(t.warnings) == 1
    end

    @testset "the empty selection lands on the Build (§8.8, D-251)" begin
        # The helper inside a declaration body has no artifact in hand, so the
        # warning reaches the `Build` through the channel and the entry point logs
        # it once at return. The model is sound, so the build completes.
        b = @test_logs (:warn, r"^EmptyFaceSelection") build(EmptySelection(Gain(2.0), Gain(3.0)))
        d = only(warnings(b))
        @test d isa EmptyFaceSelection
        @test d.who == "input_passthrough" && d.path == "g" && d.selector === :except
        @test d.names == ["e"] && d.candidates == ["e"]
        # One passthrough level above, the parent asks the child for its face
        # lists and the count stays one: the walk evaluated the body once.
        n = @test_logs (:warn, r"^EmptyFaceSelection") build(
            EmptySelectionParent(EmptySelection(Gain(2.0), Gain(3.0))))
        @test length(warnings(n)) == 1 && only(warnings(n)) isa EmptyFaceSelection
    end

    @testset "warnings(sim) concatenates its artifacts' lists (§9.2, D-250)" begin
        # A producer on each side: the empty selection on the build, and the
        # derivation path's `GridUtilization` on the deployment — the offset drives
        # the grid twice as fine as the one discrete child's own period. Each
        # artifact logs its own once at return, in the order the two steps run.
        sim = @test_logs (:warn, r"^EmptyFaceSelection") (:info, r"derived") (:warn, r"^GridUtilization") Simulation(
            EmptySelectionRated(Gain(2.0), Gain(3.0), TickCounter()); h = 1//500,
            Δt_base = :derive)
        @test only(warnings(sim.deployment.build)) isa EmptyFaceSelection
        @test only(warnings(sim.deployment)) isa GridUtilization
        @test [typeof(w) for w in warnings(sim)] == [EmptyFaceSelection, GridUtilization]
    end

    @testset "outside a build the helper logs directly (D-250)" begin
        # Unbound channel, no artifact to append to, and a log line is the honest
        # fallback.
        @test_logs (:warn, r"^SyntheticWarning") _warn!(SyntheticWarning("x"))
    end

    @testset "the helper refuses an error-severity kind (D-250)" begin
        # An error-severity kind is collected or thrown, never warned.
        @test_throws InternalInvariant _warn!(UnconnectedInput(path = "a", face = :v,
                                                               declared = Float64, level = "a"))
    end
end

function test_build()
    build_probe_refusals()
    build_user_code_framing()
    build_schedule()
    build_algebraic_cycles()
    build_port_classes()
    build_root_input_type()
    build_wire_clauses()
    build_port_type_refusals()
    build_label_ports()
    build_tier()
    build_store_values()
    build_store_form()
    build_state_leaves()
    build_barrier()
    build_embed_accept()
    build_activations()
    build_warnings()
end
