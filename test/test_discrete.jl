# --- the discrete tier: one rate, then several (§10.5) ------------------------
# §10.5 is "Multi-rate tick scheduling", and the single-rate case is its D = 1,
# Φ = 0 corner — which is why the ZOH proof runs twice in this file. Once at one
# rate, where the closed form is the plain sampled-data recursion and the only
# claim is that the hold is real; and once at several, where the same reference
# closes only if the gate admits a component at exactly its own ticks, the hold
# spans the sub-ticks and off-tick boundaries, and the bundle's `Δt` is the
# compiled schedule's. Read them in that order.

function discrete_one_rate()
    @testset "the sampled loop matches the exact ZOH discretization" begin
        # The reference is the hybrid system solved exactly: over each interval the
        # plant is linear with a *constant* input, so its transition is
        # `q[k+1] = Ad q[k] + Bd s[k]` with `Ad = exp(A Δt)`, and the controller
        # advances by its own recursion. Nothing here matches unless the hold is
        # real — a mid-step re-run of `ctl` would move `u` inside the interval and
        # break the closed form.
        kI, ω, ζ, Δt, r, n_samples = 3.0, 2.0, 0.1, 0.02, 0.7, 100
        A = SMatrix{2,2}(0.0, -ω^2, 1.0, -2ζ * ω)
        B = SVector(0.0, 1.0)
        Ad = exp(A * Δt)
        Bd = A \ ((Ad - I) * B)

        q, s = SVector(0.0, 0.0), 0.0
        for _ in 1:n_samples
            q, s = Ad * q + Bd * s, s + kI * Δt * (r - q[1])
        end
        snext = s + kI * Δt * (r - q[1])   # the update boundary n_samples itself performs

        sim = Simulation(sampled_loop(; kI, ω, ζ); h = 1//50)   # h = Δt: one rate, N_base = 1
        init!(sim, fragment(inputs = (ref = r,)))
        run!(sim; t_end = n_samples * Δt)

        # The tolerance is RK4's, not the semantics': the reference integrates
        # exactly where the loop takes one RK4 step per sample, which at `ωΔt` this
        # size leaves ~1e-8 relative. A violated hold moves `u` mid-interval and
        # costs ~1e-3, so the margin still separates the two by orders of magnitude.
        @test state(sim, "plant").q ≈ q rtol = 1e-6
        # The cell holds `s[n_samples]` — the output stage ran at this boundary — while
        # the store already holds `s[n_samples+1]`. That gap *is* the sampled-data
        # ordering: output stages before updates, within one boundary (§10.5).
        @test port(sim, "ctl", :u) ≈ s rtol = 1e-6
        @test state(sim, "ctl").acc ≈ snext rtol = 1e-6
    end

    @testset "the ZOH holds by compile-time absence (§10.5)" begin
        sim = Simulation(sampled_loop(); h = 1//50)
        init!(sim, fragment(inputs = (ref = 1.0,)))    # excite the loop, or nothing moves at all

        # Structural: the interior variants carry continuous entries only, so there
        # is no gating test on the hot path — the hold is not implemented, it is
        # the absence of any way to change the cell.
        @test length(walked(sim.exec.bodies.sweep_1, :interior)) == 1        # plant only
        @test length(walked(sim.exec.bodies.sweep_1)) == 2                   # plus ctl
        @test isempty(walked(sim.exec.bodies.ticks, :interior))
        @test length(walked(sim.exec.bodies.ticks)) == 1

        # Semantic: a step is made of interior evaluations, so the discrete cell
        # cannot move across one, while the continuous table does. Run a few
        # boundaries first — the loop starts at rest with `u` held at zero, so the
        # very first interval moves nothing at all.
        run!(sim; t_end = 0.1)
        u₀, y₀ = port(sim, "ctl", :u), port(sim, "plant", :y)
        @test u₀ != 0.0
        step!(sim, 0.02)
        @test port(sim, "ctl", :u) == u₀   # untouched: never gathered, never written
        @test port(sim, "plant", :y) != y₀
    end

end

function discrete_frozen_activation()
    @testset "the discrete tier is frozen at a non-nominal activation (§7.2)" begin
        # The plant's input walks and is wired to a discrete `Float64` cell:
        # a lawful arrival, embedded as a zero-partial. `ctl`'s stages are outside
        # this activation's executable set, so they do not run at all — boundary
        # zero's wide gate included (D-205 admits entries, and a frozen component
        # has none) — and its cell holds the nominal products §9.4 carried across,
        # pinned for the whole run.
        dual_sim = Simulation(sampled_loop(), D8; h = 1//50)
        @test isempty(walked(dual_sim.exec.bodies.ticks))
        @test length(walked(dual_sim.exec.bodies.sweep_1)) == 1          # plant only; ctl frozen
        @test port(dual_sim, "ctl", :u) isa Float64

        init!(dual_sim, fragment(inputs = (ref = 0.0,)))
        run!(dual_sim; t_end = 0.04)
        @test state(dual_sim, "plant").q isa SVector{2,D8}
        @test port(dual_sim, "ctl", :u) == 0.0              # held, never recomputed
    end
end

# --- the rate fold and the schedule it produces (§8.7, §9.1, §9.2) ------------

# An undeclared container's twin of the `Group` in the fold above: the same two children
# under the same two declarations, keyed by the composite name D-211 leaves
# untouched.
struct OpaqueRoster{K <: NamedTuple, R <: NamedTuple} <: AbstractComponent
    kids::K
    rates::R
end
child_connections(::OpaqueRoster) = ()
sample_times(comp::OpaqueRoster) = comp.rates

# A bare container key over a tuple of elements: one `Absolute` entry, applied
# to every element by §8.7's sugar, establishes one anchor (§9.1).
struct AnchoredBank <: AbstractComponent
    units::NTuple{2,TickCounter}
    clock::TickCounter
end
child_connections(::AnchoredBank) = ()
sample_times(::AnchoredBank) = (units = Absolute(Hz(10), 1//150), clock = Absolute(Hz(500)))

function discrete_rate_fold()
    @testset "the fold validates with path attribution (§8.7, §9.1)" begin
        rated(rates) = Group((; c = TickCounter()); rates = rates)

        err = failure(() -> build(rated((; c = 2))))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa RatesViolation && d.reason === :value_vocabulary && d.key === :c &&
              d.value == 2

        for (rates, reason) in (((; c = Relative(0)),               :multiplier),
                                ((; c = Relative(2, 2)),            :phase),
                                ((; c = Absolute(Period(0))),       :period),
                                ((; c = Absolute(Hz(50), 1//40)),   :offset))
            err = failure(() -> build(rated(rates)))
            @test err isa DiagnosticError
            d = only(diagnostics(err))
            @test d isa RatesViolation && d.reason === reason && d.key === :c
        end

        # A key names an immediate child, and nothing else: a stray name and a deep
        # key meet the same rule.
        for key in (:nav, Symbol("c/x"))
            err = failure(() -> build(rated(NamedTuple{(key,)}((Relative(2),)))))
            @test err isa DiagnosticError
            d = only(diagnostics(err))
            @test d isa RatesViolation && d.reason === :unknown_child && d.key === key &&
                  d.candidates == ["c"]
        end

        # A key on a continuous child is the Δt-on-continuous error at declaration
        # time: keys name discrete or scope children (§8.7).
        err = failure(() -> build(Group((; c = Gain(1.0)); inputs = ("in" => "c/e",),
                                        rates = (; c = Relative(2)))))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa RatesViolation && d.reason === :continuous_child && d.key === :c

        # A bare container field name applies one declaration to every element.
        sim = Simulation(Group((; c1 = TickCounter(), c2 = TickCounter());
                               rates = (; children = Relative(2, 1))); h = 1//10)
        rows = sim.deployment.schedule.rows
        @test length(rows) == 2
        @test all(e.D == 2 && e.Φ == 1 for e in rows)
    end

    @testset "bare rate keys drive the grid the composite ones did (§8.7, D-211)" begin
        bare = Simulation(Group((; a = TickCounter(), b = TickCounter());
                                rates = (; a = Relative(2), b = Relative(3, 1))); h = 1//10)
        opaque = Simulation(OpaqueRoster((a = TickCounter(), b = TickCounter()),
                                         (; var"kids/a" = Relative(2),
                                            var"kids/b" = Relative(3, 1))); h = 1//10)
        bare_rows, opaque_rows =
            bare.deployment.schedule.rows, opaque.deployment.schedule.rows
        @test [(e.D, e.Φ) for e in bare_rows] == [(2, 0), (3, 1)]
        @test [(e.D, e.Φ) for e in bare_rows] == [(e.D, e.Φ) for e in opaque_rows]
        @test paths(bare.deployment.build.structure) == ["a", "b"] &&
              paths(opaque.deployment.build.structure) == ["kids/a", "kids/b"]
    end

    # The schedule the fold produces: the spec's own worked example, and the
    # hyperperiod it lays out.
    @testset "the worked example compiles to the spec's pairs (§9.2)" begin
        # Three discrete components under two scopes, deployed at Δt_base = 2 ms:
        # inner (1, 0), outer (5, 2), gnss (10, 0) — §9.2's table, exactly.
        sim = Simulation(MultiRate(); h = 1//500)
        deployment = sim.deployment
        @test deployment.N_base == 1 && deployment.Δt_base == 0.002
        @test [(e.path, e.D, e.Φ) for e in deployment.schedule.rows] ==
              [("fcs/inner", 1, 0), ("fcs/outer", 5, 2), ("gnss", 10, 0)]
        @test [e.Δt for e in deployment.schedule.rows] ≈ [0.002, 0.01, 0.02]

        # The gate is structural: the interior variants carry no discrete entry, the
        # boundary variants gate every one of them, and nothing else.
        @test isempty(walked(sim.exec.bodies.sweep_2, :interior))
        @test gated(sim.exec.bodies.sweep_2) == 3
        @test gated(sim.exec.bodies.sweep_1) == 0            # the ramp is continuous
    end

    @testset "the hyperperiod chart is readable off the cells (§10.5)" begin
        # The ramp makes every sample carry its acquisition time (1 + t), so each
        # cell says when its owner last ticked — the chart's dots, and the
        # deterministic aging of the stagger, in the spec's own numbers.
        sim = Simulation(MultiRate(); h = 1//500)
        init!(sim)                                       # boundary zero: Φ = 0 is due
        @test port(sim, "fcs/inner", :out) == 1.0
        @test port(sim, "gnss", :out) == 1.0

        step!(sim; frames = 2)                           # base tick 2: outer's first tick
        @test port(sim, "fcs/inner", :out) ≈ 1.004       # fresh at every tick
        @test port(sim, "fcs/outer", :out) == 1.0        # gnss's k = 0 sample: two ticks old
        step!(sim; frames = 5)                           # base tick 7
        @test port(sim, "fcs/outer", :out) == 1.0        # the same sample, seven ticks old
        @test port(sim, "gnss", :out) == 1.0             # gnss itself holds until k = 10
        step!(sim; frames = 3)                           # base tick 10
        @test port(sim, "gnss", :out) ≈ 1.02             # its second tick
        run!(sim; t_end = 12 * 0.002)
        @test port(sim, "fcs/outer", :out) ≈ 1.02        # re-aged two ticks at k = 12
    end

    @testset "relative scopes compose affinely; anchors sever (§10.5, §9.1)" begin
        # Under a scope at Relative(2, 1): D = K·Dₛ, Φ = Φₛ + φ·Dₛ.
        inner_group = Group((; a = TickCounter(), b = TickCounter());
                            rates = (; a = Relative(1), b = Relative(5, 2)))
        sim = Simulation(Group((; f = inner_group);
                               rates = (; f = Relative(2, 1))); h = 1//100)
        @test [(e.D, e.Φ) for e in sim.deployment.schedule.rows] == [(2, 1), (10, 5)]

        # Neither has Φ = 0, so boundary zero admits neither; over base ticks 1…10,
        # `a` ticks at the odd indices and `b` at 5 alone.
        init!(sim)
        @test state(sim, "f/a") === (n = 0,)
        run!(sim; t_end = 10 * 0.01)
        @test state(sim, "f/a") === (n = 5,)
        @test state(sim, "f/b") === (n = 1,)

        # An anchor severs: a relative child of an anchored subtree composes against
        # the anchor, not the enclosing grid — D = 3·D₁ with D₁ = (1//50)/(1//500).
        gps = Group((; rx = TickCounter());
                    rates = (; rx = Relative(3)))
        sim = Simulation(Group((; gps = gps);
                               rates = (; gps = Absolute(Hz(50)))); h = 1//500)
        @test [(e.D, e.Φ) for e in sim.deployment.schedule.rows] == [(30, 0)]
    end
end

# --- deployment binding, and the gate at run time (§9.1, §9.2, §10.5) ---------

function discrete_deployment()
    # The artifact deployment binding produces (§9.1, §9.2, D-254): the build plus
    # the grid parameters, scalar-free, carrying the typed `Schedule`. The
    # `Simulation` materializes it, and the two convenience forms compose the two.
    @testset "the Deployment is the artifact the grid parameters fix (§9.1, D-254)" begin
        multirate_build = build(MultiRate())
        deployment = Deployment(multirate_build; h = 1//500)
        @test deployment isa Deployment
        @test deployment.h == 0.002 && deployment.N_base == 1 &&
              deployment.Δt_base == 0.002
        @test deployment.algorithm === RK4 && deployment.firing_budget == 4 &&
              deployment.localization_budget == 8 && deployment.localization_tol == 1e-6
        # the very build, never a reconstruction
        @test deployment.build === multirate_build

        # The typed schedule: the §9.2 worked example's rows, each with the anchor
        # it resolved against (0 is the base grid) and the `sample_times` links met
        # on the way down. `MultiRate` declares `fcs = Relative(1)` and
        # `gnss = Absolute(Hz(50))`, and `FCS` declares `inner = Relative(1)` and
        # `outer = Relative(5, 2)`.
        rows = deployment.schedule.rows
        @test [(row.path, row.D, row.Φ) for row in rows] ==
              [("fcs/inner", 1, 0), ("fcs/outer", 5, 2), ("gnss", 10, 0)]
        @test [row.Δt for row in rows] ≈ [0.002, 0.01, 0.02]
        @test [row.anchor for row in rows] == [0, 0, 1]
        @test [[(l.scope, l.key) for l in row.rates] for row in rows] ==
              [[("", :fcs), ("fcs", :inner)],
               [("", :fcs), ("fcs", :outer)],
               [("", :gnss)]]
        @test rows[3].rates[1].entry isa Absolute
        @test rows[2].rates[2].entry == Relative(5, 2)

        # The per-component gates the executor compiles over are derived from
        # the rows at `compile` (D-261) and hold every tier: `src` is continuous,
        # so it carries (1, 0, 0.0) between the discrete rows.
        D, Φ, Δt = _gates(deployment.schedule, multirate_build.structure)
        @test D == [1, 1, 5, 10] && Φ == [0, 0, 2, 0]
        @test Δt ≈ [0.0, 0.002, 0.01, 0.02]

        # One scope row per assembly an explicit key opened — `fcs` here — resolved
        # by the same multiply-add its members use, off the structure's own timing.
        scope = only(multirate_build.structure.scopes)
        @test (scope.path, scope.key, Tuple(scope.timing)) == ("fcs", :fcs, (0, 1, 0))
        @test only(deployment.schedule.scopes) == ScopeEntry("fcs", :fcs, 0, 1, 0)

        # A completed constructor carries its warnings; there is no producer here.
        @test warnings(deployment) == Diagnostic[]
    end

    @testset "two deployments compare as values; the build is not compared (§12.7)" begin
        multirate_build = build(MultiRate())
        deployment = Deployment(multirate_build; h = 1//500)
        @test deployment == Deployment(multirate_build; h = 1//500) &&
              hash(deployment) == hash(Deployment(multirate_build; h = 1//500))
        # Each compared field moves the trajectory, so each one differing severs.
        @test deployment != Deployment(multirate_build; h = 1//500, N_base = 2)
        @test deployment != Deployment(multirate_build; h = 1//500, algorithm = Heun)
        @test deployment != Deployment(multirate_build; h = 1//500, firing_budget = 8)
        @test deployment != Deployment(multirate_build; h = 1//500, localization_tol = 1e-8)
        @test deployment != Deployment(multirate_build; h = 1//500, localization_budget = 4)
        # The build is not compared: a what-if replay re-drives a recording against
        # a modified model of the same structure, so comparing it would refuse what
        # §12.7 admits. Two builds of one model therefore deploy equal.
        deployment2 = Deployment(build(MultiRate()); h = 1//500)
        @test deployment2.build !== deployment.build && deployment2 == deployment &&
              hash(deployment2) == hash(deployment)
    end

    @testset "materializing fixes the scalar; one deployment backs many (§9.2, D-254)" begin
        multirate_build = build(MultiRate())
        deployment = Deployment(multirate_build; h = 1//500)
        sim = Simulation(deployment, Float64)
        @test sim.deployment === deployment
        # the sugar, *defined as* the composition
        reference = Simulation(multirate_build; h = 1//500)
        @test sim.deployment == reference.deployment
        init!(sim); run!(sim; t_end = 12 * 0.002)
        init!(reference); run!(reference; t_end = 12 * 0.002)
        @test port(sim, "fcs/outer", :out) == port(reference, "fcs/outer", :out)
        @test port(sim, "gnss", :out) == port(reference, "gnss", :out)

        # The same deployment at a second scalar: scalar-free means one backs many.
        dual = Simulation(deployment, D8)
        @test dual.deployment === deployment && eltype(dual.exec.xbuf) === D8

        # `warnings(sim)` is the concatenation of its artifacts' lists (D-250);
        # neither has a producer here.
        @test warnings(sim) == Diagnostic[]
        @test warnings(sim.deployment.build) == Diagnostic[] &&
              warnings(deployment) == Diagnostic[]
    end

    @testset "one Build backs many Simulations; Δt_base has three sources (§9.1)" begin
        multirate_build = build(MultiRate())

        # The N_base·h product (the default path), an explicit N_base, the explicit keyword
        # (Rational or quantity): the anchored divisor is deployment's, not the
        # build's — the same Build lands gnss at D = 10 or D = 5.
        default_sim = Simulation(multirate_build; h = 1//500)
        n_base_sim = Simulation(multirate_build; h = 1//500, N_base = 2)
        Δt_base_sim = Simulation(multirate_build; h = 1//500, Δt_base = 1//250)
        period_sim = Simulation(multirate_build; h = 1//500, Δt_base = Period(1//250))
        @test [e.D for e in default_sim.deployment.schedule.rows] == [1, 5, 10]
        @test [e.D for e in n_base_sim.deployment.schedule.rows] == [1, 5, 5]
        # The deployment is a value (§12.7, D-254): two spellings of one base tick
        # period, over one build, deploy equal — and hash equal with it.
        @test Δt_base_sim.deployment.N_base == 2
        @test Δt_base_sim.deployment == n_base_sim.deployment == period_sim.deployment
        @test hash(Δt_base_sim.deployment) == hash(period_sim.deployment)

        # Nothing writable is shared: each Simulation materializes its own buffers.
        init!(default_sim); run!(default_sim; t_end = 0.02)
        init!(n_base_sim)
        @test port(default_sim, "fcs/inner", :out) ≈ 1.02
        @test port(n_base_sim, "fcs/inner", :out) == 1.0

        # Cross-validation: one `DeploymentInvalid` per refused deployment, the
        # parameter and the failed relation on the payload.
        for (f, param, reason) in
            ((() -> Simulation(multirate_build),                          :h, :missing),
             (() -> Simulation(multirate_build; h = 1e-3),                :h, :inexact),
             (() -> Simulation(multirate_build; h = 1//500, Δt_base = 1//250, N_base = 3),
                               :Δt_base, :disagrees_with_n),
             (() -> Simulation(multirate_build; h = 1//300, Δt_base = 1//500),
                               :Δt_base, :not_harmonic),
             (() -> Simulation(multirate_build; h = 1//500, N_base = 0),  :N_base, :range))
            d = only(diagnostics(failure(f)))
            @test d isa DeploymentInvalid && d.parameter === param && d.reason === reason
        end

        # The call is the barrier (§9.1, D-229): `h` and `N_base` are independent
        # premises, so both refusals arrive in one throw.
        err = failure(() -> Simulation(multirate_build; h = 1e-3, N_base = 0))
        @test Set((d.parameter, d.reason) for d in diagnostics(err)) ==
              Set([(:h, :inexact), (:N_base, :range)])

        # Deploying, materializing and initializing are separate calls (§9.2,
        # D-254, D-256, D-261), each with its own barrier: `log_every` is the
        # door's keyword, refused under `ArgumentInvalid` before any write.
        sim = Simulation(multirate_build; h = 1//500)
        d = only(diagnostics(failure(() -> init!(sim; log_every = 0))))
        @test d isa ArgumentInvalid && d.call === :init! && d.argument === :log_every
        @test lifecycle(sim) === :built

        # `Δt_base` is a third independent premise: the explicit keyword reads only
        # itself and derivation reads the tiers and the anchors, so neither is
        # suppressed by an unsound `h` or `N_base`.
        err = failure(() -> Simulation(multirate_build; h = 1e-3, Δt_base = 1e-3))
        @test Set((d.parameter, d.reason) for d in diagnostics(err)) ==
              Set([(:h, :inexact), (:Δt_base, :inexact)])
        err = failure(() ->
            Simulation(multirate_build; h = 1//500, Δt_base = :derive, N_base = 0))
        @test Set((d.parameter, d.reason) for d in diagnostics(err)) ==
              Set([(:N_base, :range), (:Δt_base, :unanchored)])

        # `N_base` is a count: a non-integer is refused as a range violation, not left
        # to fail inside the exact arithmetic.
        d = only(diagnostics(failure(() ->
            Simulation(multirate_build; h = 1//500, N_base = 2.5))))
        @test d isa DeploymentInvalid && d.parameter === :N_base && d.reason === :range

        # A non-dividing anchor is refused with its declaring scope and key, and the
        # attribution is named off the pool (§9.2, D-187). `MultiRate`'s pool is the
        # one anchor period, and a pool of one refines nothing.
        err = failure(() -> Simulation(multirate_build; h = 1//500, Δt_base = 3//250))
        @test err isa DiagnosticError
        d = only(diagnostics(err))
        @test d isa DeploymentInvalid && d.reason === :anchor_period
        @test d.scope == "" && d.key === :gnss && d.grid.admissible == 1//50
        @test [(e.kind, e.value, e.factor) for e in d.grid.pool] == [(:period, 1//50, 1)]

        # A driving offset's refusal carries the repair: the nearest offsets on the
        # grid the rest of the pool already supports (§9.2, D-187).
        offset = Group((; a = TickCounter(), b = TickCounter());
                       rates = (; a = Absolute(Hz(500)), b = Absolute(Hz(10), 1//150)))
        d = only(diagnostics(failure(() -> Simulation(offset; h = 1//500))))
        @test d isa DeploymentInvalid && d.reason === :anchor_offset
        @test d.grid.admissible == 1//1500
        @test only(e.alternatives for e in d.grid.pool if e.kind === :offset) ==
              [3//500, 1//125]

        # One anchor per `Absolute` entry: a bare container key's elements share
        # it, so the pool holds no twin to mask the offset's leave-one-out factor,
        # and the offset is named as a driver with its repair (§8.7, §9.1, §9.2).
        anchored_build = build(AnchoredBank((TickCounter(), TickCounter()), TickCounter()))
        @test length(anchored_build.structure.anchors) == 2
        @test [Tuple(e.timing) for e in anchored_build.structure.components] ==
              [(1, 1, 0), (1, 1, 0), (2, 1, 0)]
        d = only(diagnostics(failure(() -> Deployment(anchored_build; h = 1//500))))
        @test d isa DeploymentInvalid && d.reason === :anchor_offset
        @test [(e.kind, e.factor) for e in d.grid.pool] ==
              [(:period, 1), (:period, 10), (:offset, 3)]
        @test only(e.alternatives for e in d.grid.pool if e.kind === :offset) ==
              [3//500, 1//125]
    end

    @testset "Δt_base derivation demands an all-anchored model (§9.1)" begin
        # Derivation with an unanchored component present is action at a distance:
        # refused constructively, naming the components whose periods would rescale.
        d = only(diagnostics(failure(() -> Simulation(build(MultiRate()); h = 1//500, Δt_base = :derive))))
        @test d isa DeploymentInvalid
        @test d.parameter === :Δt_base && d.reason === :unanchored
        @test "fcs/inner" in d.paths

        # All anchored: the pool is every period and every nonzero offset, and the
        # derived value is its GCD — the offset drives the grid 2× finer here.
        anchored = Group((; c = TickCounter());
                         rates = (; c = Absolute(Hz(50), 1//100)))
        sim = @test_logs (:info, r"derived") (:warn, r"^GridUtilization") Simulation(
            anchored; h = 1//500, Δt_base = :derive)
        @test sim.deployment.Δt_base == 0.01 && sim.deployment.N_base == 5
        @test [(e.D, e.Φ) for e in sim.deployment.schedule.rows] == [(2, 1)]

        # The offset alone refines, so the grid is twice the fastest declared work
        # and the advisory says so, with the repair: no offset keeps the 50 Hz grid
        # (§9.2, D-187). The advisory lives on the deployment (D-250).
        warning = only(warnings(sim.deployment))
        @test warning isa GridUtilization && warning.Δt_base == 1//100 &&
              warning.utilization == 2
        @test warning.fastest == "c"
        driver = only(e for e in warning.grid.pool if e.factor > 1)
        @test driver.kind === :offset && driver.factor == 2
        @test driver.alternatives == [0//1]
    end

    @testset "the grid attribution is exact, and derivation prints it (§9.2, D-187)" begin
        # The companion's worked case: a 500 Hz anchor and a 10 Hz one offset by
        # 1//150 s. The offset's denominator brings the prime 3 the rest of the pool
        # has not, so the derived grid is three times finer than the 500 Hz period.
        comp = Group((; a = TickCounter(), b = TickCounter());
                     rates = (; a = Absolute(Hz(500)), b = Absolute(Hz(10), 1//150)))
        deployment = @test_logs (:info, r"derived") (:warn, r"^GridUtilization") Deployment(
            build(comp); h = 1//1500, Δt_base = :derive)
        grid = deployment.grid
        @test deployment.Δt_base == Float64(1//1500) && deployment.N_base == 1
        @test grid.admissible == 1//1500 &&
              [row.D for row in deployment.schedule.rows] == [3, 150]

        # The pool is one entry per anchor period and one per nonzero offset, in
        # anchor order, periods first, each carrying its anchor's declaring scope and key.
        @test [(e.kind, e.value) for e in grid.pool] ==
              [(:period, 1//500), (:period, 1//10), (:offset, 1//150)]
        @test [(e.scope, e.key) for e in grid.pool] == [("", :a), ("", :b), ("", :b)]

        # Leave-one-out: how much coarser the grid would be without each entry.
        # Both the 500 Hz period and the offset drive, which is the honest answer —
        # without the period the offset alone would suffice, and the 10 Hz period
        # refines nothing.
        @test [e.factor for e in grid.pool] == [10, 1, 3]

        # Prime attribution, the sharper cut: 1500 = 2²·3·5³, with 2² and 5³ from
        # the 500 Hz period alone and the single prime 3 from the offset alone.
        @test grid.primes == [(prime = 2, power = 2, suppliers = [1]),
                              (prime = 3, power = 1, suppliers = [3]),
                              (prime = 5, power = 3, suppliers = [1])]

        # The driving offset's repair: its neighbours on the 1//500 grid the rest of
        # the pool supports. Only a driving offset gets them.
        @test grid.pool[3].alternatives == [3//500, 1//125]
        @test isempty(grid.pool[1].alternatives) && isempty(grid.pool[2].alternatives)

        # The advisory the derivation path carries: the fastest declared work ticks
        # every third base tick, so two boundaries in three are empty.
        warning = only(warnings(deployment))
        @test warning isa GridUtilization && warning.Δt_base == 1//1500 &&
              warning.utilization == 3
        @test warning.fastest == "a" && warning.grid === grid
        @test [e.value for e in warning.grid.pool if e.factor > 1] == [1//500, 1//150]

        # Drop the offset and the prime 3 goes with it: the grid is the 500 Hz
        # period itself, the fastest work fills every base tick, and `u == 1` is no
        # information — the line prints, nothing warns.
        plain = Group((; a = TickCounter(), b = TickCounter());
                      rates = (; a = Absolute(Hz(500)), b = Absolute(Hz(10))))
        deployment2 = @test_logs (:info, r"derived") Deployment(build(plain); h = 1//500,
                                                                Δt_base = :derive)
        @test deployment2.grid.admissible == 1//500 &&
              [e.factor for e in deployment2.grid.pool] == [50, 1]
        @test [row.D for row in deployment2.schedule.rows] == [1, 50] &&
              warnings(deployment2) == Diagnostic[]

        # Where every entry divides what the others already give, no entry refines
        # another and the line says exactly that.
        harmonic = Group((; a = TickCounter(), b = TickCounter(), c = TickCounter());
                         rates = (; a = Absolute(Hz(4)), b = Absolute(Hz(6)),
                                    c = Absolute(Hz(12))))
        deployment3 = @test_logs (:info, r"no entry refines another") Deployment(
            build(harmonic); h = 1//12, Δt_base = :derive)
        @test deployment3.grid.admissible == 1//12 &&
              [e.factor for e in deployment3.grid.pool] == [1, 1, 1]
        @test [row.D for row in deployment3.schedule.rows] == [3, 2, 1] &&
              warnings(deployment3) == Diagnostic[]
    end

    # --- multi-rate: the gate at run time (§10.5) -----------------------------------

    @testset "boundary zero admits Φ = 0 for updates, and publishes every output stage" begin
        # `z` at Relative(2, 1) is not due at boundary zero: its first tick is at
        # Φ·Δt_base. Its output stage runs there all the same (D-205), publishing
        # from the t₀ table — the ramp *at t₀*, not the build probe's value; the
        # dueness the gate reads at index 0 governs the `state_update` updates alone (§10.5).
        late = Group((; src = Ramp(5.0), z = ZOH());
                     wires = ("src/out" => "z/in",),
                     outputs = ("z/out" => "y",),
                     rates = (; z = Relative(2, 1)))
        sim = Simulation(late; h = 1//100)
        init!(sim)
        @test port(sim, "", :y) == 5.0                   # the ramp at t₀, evaluated
        step!(sim)                                       # base tick 1: the first tick
        @test port(sim, "", :y) ≈ 5.01
        step!(sim)                                       # base tick 2: not due, holds
        @test port(sim, "", :y) ≈ 5.01
    end

    @testset "a multi-rate sampled loop matches its exact discretization" begin
        # The increment-3 reference, one level harder: the controller ticks every
        # second base tick and every base tick is two continuous steps, so the exact
        # recursion runs at Δt_ctl = D·Δt_base = 4h — and only matches if the gate
        # admits `ctl` at exactly its own ticks, the hold spans the sub-ticks and
        # off-tick boundaries, and the bundle's Δt is the compiled schedule's
        # (§10.5's single source of truth), not h or Δt_base.
        kI, ω, ζ, r, n_samples = 3.0, 2.0, 0.1, 0.7, 50
        Δt_ctl = 0.02
        A = SMatrix{2,2}(0.0, -ω^2, 1.0, -2ζ * ω)
        B = SVector(0.0, 1.0)
        Ad = exp(A * Δt_ctl)
        Bd = A \ ((Ad - I) * B)
        q, s = SVector(0.0, 0.0), 0.0
        for _ in 1:n_samples
            q, s = Ad * q + Bd * s, s + kI * Δt_ctl * (r - q[1])
        end

        # §10.5's exposed-multiplier idiom: the deployment preference arrives as a
        # constructor parameter, and the declaration stays the assembly's.
        sim = Simulation(SampledLoop(; kI, ω, ζ, ctl_rate = Relative(2)); h = 1//200, N_base = 2)
        @test [(e.path, e.D, e.Φ) for e in sim.deployment.schedule.rows] == [("ctl", 2, 0)]
        @test sim.deployment.schedule.rows[1].Δt ≈ Δt_ctl
        init!(sim, fragment(inputs = (ref = r,)))
        run!(sim; t_end = n_samples * Δt_ctl)
        @test state(sim, "plant").q ≈ q rtol = 1e-6
        @test port(sim, "ctl", :u) ≈ s rtol = 1e-6
    end

    @testset "the gated boundary walk does not allocate (§7.5)" begin
        sim = Simulation(MultiRate(); h = 1//500)
        init!(sim)
        bodies = phase_bodies(sim)
        for name in (:sweep_1, :sweep_2, :rhs, :ticks)
            body = bodies[name]
            body(); body(1); body(2)
            @test @ballocated($body()) == 0
            @test @ballocated($body(2)) == 0             # a boundary where gates split
        end
        sim2 = Simulation(SampledLoop(; ctl_rate = Relative(2)); h = 1//200, N_base = 2)
        init!(sim2, fragment(inputs = (ref = 0.0,)))
        @test @ballocated(step!($sim2, 0.005)) == 0
        @test @ballocated(offtick_boundary!($sim2)) == 0
        @test @ballocated(boundary!($sim2, 3)) == 0
    end
end

function test_discrete()
    discrete_one_rate()
    discrete_frozen_activation()
    discrete_rate_fold()
    discrete_deployment()
end
