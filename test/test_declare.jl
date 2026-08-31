# --- the declaration layer (§5.2, §8.2, §8.7) ---------------------------------
# Declarations are ordinary functions of the instance, so what the framework
# reads off them is computed, never announced. The bundle law is the first such
# reading: which names a stage's argument carries is a function of the stores
# and facts that exist, and of nothing else. Both tiers are here, because the
# claim D-195 makes is about the two together — the state letters are disjoint
# by construction, `x`/`y_x` against `s`/`y_s`. The rate registers are the other
# such product: plain data carriers, normalized and range-checked at
# construction, with everything positional — the fold, the grid, the schedule —
# left to the files that own it (`test_multirate.jl`).

function test_declare()
    @testset "the wrappers are plain data over exact rationals (D-185)" begin
        # `Period` and `Hz` are one quantity, two spellings, normalized at
        # construction; floats are refused with the exact spelling named.
        @test period(Hz(50)) === 1//50
        @test period(Period(1//50)) === 1//50
        @test period(Hz(1//2)) === 2//1
        d1 = only(failure(() -> Period(0.02)).diagnostics)
        @test d1 isa ArgumentInvalid && d1.call === :Period && d1.reason === :inexact
        d2 = only(failure(() -> Hz(0.5)).diagnostics)
        @test d2 isa ArgumentInvalid && d2.call === :Hz && d2.reason === :inexact
        d3 = only(failure(() -> Absolute(Hz(50), 0.001)).diagnostics)
        @test d3 isa ArgumentInvalid && d3.call === :Absolute && d3.reason === :inexact
        d4 = only(failure(() -> Absolute(1//50)).diagnostics)
        @test d4 isa ArgumentInvalid && d4.call === :Absolute && d4.reason === :not_a_quantity

        # Plain data carriers: no range checks of their own — those are Stratum A's,
        # with path attribution, at the fold.
        @test Relative(5) === Relative(5, 0)
        @test Relative(0).K == 0
        @test Absolute(Period(0)).T == 0
    end

    @testset "the bundle law (§5.2)" begin
        # A name appears iff the store or fact exists: the stateless gain sees no
        # `x`, the no-feedthrough stage sees no `u`, `t` is always there.
        @test bundle_names(h_x, Plant(), CONTINUOUS, ()) === (:x, :t)
        @test bundle_names(h_xu, Plant(), CONTINUOUS, (:y,)) === (:x, :u, :y_x, :t)
        @test bundle_names(f, Plant(), CONTINUOUS, (:y,)) === (:x, :u, :y, :t)
        @test bundle_names(h_xu, Gain(1.0), CONTINUOUS, ()) === (:u, :t)

        # The discrete sets against them: `Δt` is a discrete-tier fact, `m` a
        # continuous one, and each tier's state letters are its own (D-195).
        @test bundle_names(h_s, DiscreteCounter(), DISCRETE, ()) === (:s, :t, :Δt)
        @test bundle_names(g, DiscreteCounter(), DISCRETE, (:n,)) === (:s, :y, :t, :Δt)
        @test bundle_names(h_su, DiscreteMap(), DISCRETE, ()) === (:u, :t, :Δt)
        @test bundle_names(h_su, DiscreteCounter(), DISCRETE, (:n,)) === (:s, :y_s, :t, :Δt)
    end
end
