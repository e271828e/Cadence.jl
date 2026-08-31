# --- the declaration layer (§5.2, §8.2) ---------------------------------------
# Declarations are ordinary functions of the instance, so what the framework
# reads off them is computed, never announced. The bundle law is the first such
# reading: which names a stage's argument carries is a function of the stores
# and facts that exist, and of nothing else. Both tiers are here, because the
# claim D-195 makes is about the two together — the state letters are disjoint
# by construction, `x`/`y_x` against `s`/`y_s`.

function test_declare()
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
