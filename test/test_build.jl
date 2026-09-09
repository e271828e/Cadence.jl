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

function build_probe_refusals()
    @testset "the probe rejects malformed components (§9.3)" begin
        d = only(diagnostics(failure(() -> build(single(Undeclared())))))
        @test d isa UndeclaredReturnField && d.name === :b && d.candidates == [:a]
        d = only(diagnostics(failure(() -> build(single(Unproduced())))))
        @test d isa DeclaredNotProduced && d.ports == [:b] && d.products == [:a]
        d = only(diagnostics(failure(() -> build(single(BadDerivative())))))
        @test d isa ConformanceFailure && d.what == "state_derivative" && d.reason === :field_type &&
              d.field === :q && d.observed === Float64
        d = only(diagnostics(failure(() -> build(single(IntegerRate())))))
        @test d isa ConformanceFailure && d.what == "state_derivative" &&
              d.reason === :field_type && d.observed === Int64 && d.declared === Float64
        @test failure(() -> build(single(ScrambledDerivative()))) === nothing
        sim = Simulation(single(ScrambledDerivative()); h = 1//100, t_end = 0.05)
        @test failure(() -> (init!(sim); run!(sim))) === nothing
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

        # It is Stratum A's wire pass that catches it, ahead of stage-2 probing —
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

# --- the two wire clauses in Stratum A (§6.1, §9.1, D-236) --------------------
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
        @test occursin("declare the entry `T`", message(d))

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

    @testset "the wire pass collects to Stratum A's barrier (§13.1, D-229, D-236)" begin
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

# --- Stratum A's one barrier (§13.1, D-229) -----------------------------------

# One failure from each of the stratum's passes, in one model: a wire typo'd on
# the producer's port, the input it leaves unfed, a store with no update law and
# an event missing its handler. `HalfEvent` is `test_events.jl`'s, which this
# file precedes, so the children are a `Group`'s values rather than a struct's
# declared fields.
merged_failures() = Group((; g = Gain(1.0), s = Sum(), n = NoFlow(), h = HalfEvent());
                          wires = ("g/ot" => "s/a",),
                          inputs = ("e" => "g/e", "b" => "s/b"))

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
    build_wire_clauses()
    build_port_type_refusals()
    build_tier()
    build_store_values()
    build_stratum_a()
    build_embed_accept()
    build_activations()
end
