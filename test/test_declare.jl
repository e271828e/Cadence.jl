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
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} Period(0.02))
        @test d.call === :Period && d.reason === :inexact
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} Hz(0.5))
        @test d.call === :Hz && d.reason === :inexact
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} Absolute(Hz(50), 0.001))
        @test d.call === :Absolute && d.reason === :inexact
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} Absolute(1//50))
        @test d.call === :Absolute && d.reason === :not_a_quantity

        # Plain data carriers: no range checks of their own — those are the structure step's,
        # with path attribution, at the fold.
        @test Relative(5) === Relative(5, 0)
        @test Relative(0).K == 0
        @test Absolute(Period(0)).T == 0
    end

    @testset "the bundle law (§5.2)" begin
        # A name appears iff the store or fact exists: the stateless gain sees no
        # `x`, the no-feedthrough stage sees no `u`, `t` is always there.
        @test bundle_names(y_state, Plant(), CONTINUOUS, ()) === (:x, :t)
        @test bundle_names(y_direct, Plant(), CONTINUOUS, (:y,)) === (:x, :u, :y_x, :t)
        @test bundle_names(x_derivative, Plant(), CONTINUOUS, (:y,)) === (:x, :u, :y, :t)
        @test bundle_names(y_direct, Gain(1.0), CONTINUOUS, ()) === (:u, :t)

        # A declared empty store puts no letter in the bundle (§5.2, D-263):
        # `Gain` declares `x_init(::Gain) = (;)`, and no bundle of it carries `x`.
        @test :x_init in leaf_declarations(Gain(1.0))
        @test bundle_names(y_state, Gain(1.0), CONTINUOUS, ()) === (:t,)

        # The discrete sets against them: `Δt` is a discrete-tier fact, `m` a
        # continuous one, and each tier's state letters are its own (D-195).
        @test bundle_names(y_state, DiscreteCounter(), DISCRETE, ()) === (:s, :t, :Δt)
        @test bundle_names(s_update, DiscreteCounter(), DISCRETE, (:n,)) === (:s, :y, :t, :Δt)
        @test bundle_names(y_direct, DiscreteMap(), DISCRETE, ()) === (:u, :t, :Δt)
        @test bundle_names(y_direct, DiscreteCounter(), DISCRETE, (:n,)) === (:s, :y_s, :t, :Δt)
    end

    @testset "a foreign binding of a family name is the forgotten import (§8.1, D-246)" begin
        # The evidence the shadowing check acts on: a family name the component's
        # parent module binds to something other than the framework's function,
        # listed in family order. `using Cadence` alone leaves the name undefined
        # (the family is unexported, D-117), so only the bare definition shows.
        @test foreign_declarations(ForgottenImport.Inventory.Leaf()) ==
              [:x_init, :y_types, :y_state, :x_derivative]
        @test foreign_declarations(ForgottenImport.Update.Leaf()) == [:x_derivative]
        @test foreign_declarations(ForgottenImport.Events.Leaf()) == [:state_events]
        @test foreign_declarations(ForgottenImport.Rates.Assembly(ForgottenImport.Rates.Leaf())) ==
              [:sample_times]

        # The evidence is a fact about the *module*, not the component: the sound
        # leaf of a module whose assembly forgot one import reads the same list.
        @test foreign_declarations(ForgottenImport.Rates.Leaf()) == [:sample_times]

        # A module that imported what it extends has nothing foreign — the suite's
        # own fixtures — and neither has a framework-owned type, whose parent
        # module is `Cadence` itself.
        @test isempty(foreign_declarations(Plant()))
        @test isempty(foreign_declarations(Group((; c = Plant()))))
    end
end
