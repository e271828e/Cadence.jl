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

struct NoFlow <: AbstractComponent end
init_x(::NoFlow) = (q = 1.0,)

function build_probe_refusals()
    @testset "the probe rejects malformed components (§9.3)" begin
        d = only(diagnostics(failure(() -> build(single(Undeclared())))))
        @test d isa UndeclaredReturnField && d.name === :b && d.candidates == [:a]
        d = only(diagnostics(failure(() -> build(single(Unproduced())))))
        @test d isa DeclaredNotProduced && d.ports == [:b] && d.products == [:a]
        d = only(diagnostics(failure(() -> build(single(BadDerivative())))))
        @test d isa ConformanceFailure && d.what == "state_derivative" && d.reason === :field_type &&
              d.field === :q && d.observed === Float64
        d = only(diagnostics(failure(() -> build(single(NoFlow())))))
        @test d isa StoreWithoutUpdate && d.store === :init_x
    end
end

# --- the feedthrough graph and the schedule (§5.3, §5.5) ----------------------

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

    @testset "an algebraic loop is a build error (§5.5)" begin
        # `build` alone: rejection needs no deployment, which is the strata split.
        d = carried(@test_throws DiagnosticError{AlgebraicCycle} build(feedback_model(feedback_port = "power")))
        @test sort(d.members) == ["ctl", "plant", "sum"]
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

        # It is the layout barrier that catches it, ahead of stage-2 probing — so
        # the surfacing this replaces, the second consumer's probe reading the
        # first's cell, is gone: no `WireTypeMismatch` for this model.
        @test !any(x -> x isa WireTypeMismatch, diagnostics(err))

        # A tolerance difference is no conflict (D-168's meet): `T` and a pinned
        # `Float64` are one type at nominal, and they disagree about partials alone.
        @test build(_fanned_root(RealEntry(), PinnedEntry())) isa Build
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
        for (c, offender) in ((BothUpdates(), :state_update), (WrongArity(), :output_types),
                              (ModesOnDiscrete(), :init_m), (BothArities(), :output_types))
            diags = Diagnostic[]
            @test classify_tier("c", c, diags) === nothing
            # The vote loop collects: every declaration off the announced tier is
            # reported, and the one this case is written around is among them.
            @test all(d -> d isa DeclarationOnWrongTier && d.reason === :tier_form, diags)
            @test offender in [d.declaration for d in diags]
        end

        # A store with no update law is §8.2's sibling of the classless component.
        diags = Diagnostic[]
        @test classify_tier("c", NoFlow(), diags) === nothing
        @test only(diags) isa StoreWithoutUpdate

        # The base tick period is deployment's, not the build's: the same `Build`
        # deploys at any admissible grid, and the executor cannot exist before one
        # binds because `Δt`, `D` and `Φ` are entry-field data (§9.1, §9.7).
        b = build(single(DiscreteCounter()))
        @test b isa Build
        d = carried(@test_throws DiagnosticError{DeploymentInvalid} Simulation(b))
        @test d.parameter === :h && d.reason === :missing
        @test Simulation(b; h = 1//10) isa Simulation
    end
end

# --- Stratum A's one barrier (§13.1, D-229) -----------------------------------

# One failure from each of the stratum's passes, in one model: a wire typo'd on
# the producer's port, the input it leaves unfed, a store with no update law and
# an event missing its handler. `HalfEvent` is `test_events.jl`'s, which this
# file precedes, so the children are a `Group`'s values rather than a struct's
# declared fields.
merged_failures() = Group((; g = Gain(1.0), s = Sum(), n = NoFlow(), h = HalfEvent());
                          wires = ("g/ot" => "s/a",),
                          inputs = ("e" => "g/e", "b" => "s/b"))

function build_stratum_a()
    @testset "every Stratum A pass that ran merges into one throw (§13.1, D-229)" begin
        # The wiring walk, the obligation check, tier classification and event
        # declarations each read a result the others did not spoil, so all four
        # run and the model is refused once.
        err = failure(() -> build(merged_failures()))
        @test Set(kinds(err)) ==
              Set([UnknownPort, UnconnectedInput, StoreWithoutUpdate, EventHalfMissing])
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
        # activation's own Stratum-C re-run, not at `build` (§9.4's lazy lurk).
        b = build(single(PinnedGetsDual()))
        err = failure(() -> activation(b, D8))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa ConformanceFailure && d.shape === :ports && d.reason === :field_type
        @test d.declared === Float64 && d.observed === D8 && d.activation === D8
    end
end

# The activation seam (§9.1, §9.4): the nominal activation runs at build, any
# other is a cached Stratum-C re-run, and a frozen component's products are
# carried across from the nominal activation rather than probed or synthesized.
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
    @testset "a non-nominal activation re-runs Stratum C; frozen products carry (§9.4)" begin
        pair() = Group((; src = NomSource(), rd = FrozenReader());
                       wires = ("src/val" => "rd/in",))

        # The nominal activation runs at build and *is* the Float64 activation; a
        # non-nominal one materializes at first request and is cached on the Build.
        b = build(pair())
        @test activation(b, Float64) === b.nominal
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

        # §9.4's opt-in exhaustive mode: the listed activations materialize at
        # build time, which is where CI catches a lurking pinned leaf.
        err = failure(() -> build(single(PinnedGetsDual()); activations = (Float64, D8)))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa ConformanceFailure && d.declared === Float64 && d.activation === D8
    end
end

function test_build()
    build_probe_refusals()
    build_schedule()
    build_root_input_type()
    build_tier()
    build_stratum_a()
    build_embed_accept()
    build_activations()
end
