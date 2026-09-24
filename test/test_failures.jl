# --- runtime failures (§13.4; increment 24) -------------------------------------
# The execution cursor written per dispatch and per phase transition, the one
# catch site wrapping into `StepError` against it, and the `InterruptException`
# carve-out to the stop path, then the `isfinite` sweep over `x` as the
# boundary's first act and the replay pointer it names. The fixtures are library
# components (`Tripwire`, `Mine`, `Landmine`, `Sapper`, `Primer`, `Interrupter`,
# `Diverger`, `Consumer`, `LateDiverger`); the models below live at top level for
# `implementation.md`'s local-scope reason.

# The interrupter armed by its own ramp: `q = t` crosses the trigger's level at
# boundary 2, so frame 3's integrate is the first that raises the interrupt.
interrupted() = Group((c = Interrupter(), trig = Trigger(0.15));
                      wires = ("c/q" => "trig/sig", "trig/on" => "c/arm"))

# The interrupter whose armed RHS runs a hook before raising: the window between
# the frame top's stop-word read and the carve-out's catch, where another issuer
# can land first.
struct HookedInterrupter <: AbstractComponent
    hook::Base.RefValue{Any}
end
HookedInterrupter() = HookedInterrupter(Ref{Any}(nothing))
init_x(::HookedInterrupter) = (q = 0.0,)
input_types(::HookedInterrupter, ::Type{T}) where {T <: Real} = (arm = Bool,)
output_types(::HookedInterrupter, ::Type{T}) where {T <: Real} = (q = T,)
output_state(::HookedInterrupter, (; x)) = (q = x.q,)
state_derivative(c::HookedInterrupter, (; x, u)) =
    u.arm ? (c.hook[](); throw(InterruptException())) : (q = one(x.q),)
hooked_interrupted(c) = Group((c = c, trig = Trigger(0.15));
                              wires = ("c/q" => "trig/sig", "trig/on" => "c/arm"))

# The diverger and the innocent component downstream of it: `con` reads `div`'s
# state through the ordinary signal path, so a sweep running later than the
# integrate would blame the lookup rather than the block that blew up.
diverging() = Group((div = Diverger(), con = Consumer());
                    wires = ("div/q" => "con/in",), inputs = ("in" => "div/arm",))

# --- §9.5's always-on check at the write (D-235) --------------------------------
# Every fixture below conforms on the branch the probe sees at `t = 0` and
# diverges on the one a later frame takes — the case the probe cannot reach and
# the generated write refuses.

struct LateInteger <: AbstractComponent end
output_types(::LateInteger, ::Type{T}) where {T <: Real} = (q = T,)
output_state(::LateInteger, (; t)) = (q = t < 0.05 ? 1.0 : 0,)

# An array's mutability is a type parameter, not a leaf (D-238): the leafwise
# relation converted this write silently.
struct LateMutable <: AbstractComponent end
output_types(::LateMutable, ::Type{T}) where {T <: Real} = (v = SVector{2,T},)
output_state(::LateMutable, (; t)) = (v = t < 0.05 ? SVector(1.0, 2.0) : MVector(1.0, 2.0),)

struct LateExtraPort <: AbstractComponent end
output_types(::LateExtraPort, ::Type{T}) where {T <: Real} = (q = T,)
output_state(::LateExtraPort, (; t)) = t < 0.05 ? (q = 1.0,) : (q = 1.0, extra = 2.0)

struct LateMissingPort <: AbstractComponent end
output_types(::LateMissingPort, ::Type{T}) where {T <: Real} = (a = T, b = T)
output_state(::LateMissingPort, (; t)) = t < 0.05 ? (a = 1.0, b = 2.0) : (a = 1.0,)

# The names are the pairing: the same return in another order, at both seams.
struct ScrambledPorts <: AbstractComponent end
output_types(::ScrambledPorts, ::Type{T}) where {T <: Real} = (a = T, b = T)
output_state(::ScrambledPorts, (; t)) = (b = 2.0, a = 1.0)

struct ScrambledRate <: AbstractComponent end
init_x(::ScrambledRate) = (a = 1.0, b = 2.0)
output_types(::ScrambledRate, ::Type{T}) where {T <: Real} = (pa = T, pb = T)
output_state(::ScrambledRate, (; x)) = (pa = x.a, pb = x.b)
state_derivative(::ScrambledRate, (; x)) = (b = 0.0, a = 1.0)

struct LateIntegerRate <: AbstractComponent end
init_x(::LateIntegerRate) = (a = 1.0,)
output_types(::LateIntegerRate, ::Type{T}) where {T <: Real} = (q = T,)
output_state(::LateIntegerRate, (; x)) = (q = x.a,)
state_derivative(::LateIntegerRate, (; t)) = (a = t < 0.05 ? -1.0 : 0,)

struct LateIntegerProjection <: AbstractComponent end
init_x(::LateIntegerProjection) = (a = 1.0,)
output_types(::LateIntegerProjection, ::Type{T}) where {T <: Real} = (q = T,)
output_state(::LateIntegerProjection, (; x)) = (q = x.a,)
state_derivative(::LateIntegerProjection, (; x)) = (a = -10.0 * x.a,)
state_projection(::LateIntegerProjection, x) = x.a > 0.5 ? (a = x.a,) : (a = 0,)

# The lawful late `Float64`: the constant branch under a `Dual` activation, which
# the write embeds as a zero-partial rather than refusing (§9.5, D-166).
struct DecayingBranch <: AbstractComponent end
init_x(::DecayingBranch) = (a = 1.0,)
output_types(::DecayingBranch, ::Type{T}) where {T <: Real} = (q = T,)
output_state(::DecayingBranch, (; x)) = (q = x.a > 0.5 ? 2.0 * x.a : 0.0,)
state_derivative(::DecayingBranch, (; x)) = (a = -10.0 * x.a,)

struct LateSuccessor <: AbstractComponent end
init_s(::LateSuccessor) = (n = 0.0,)
output_types(::LateSuccessor) = (u = Float64,)
output_state(::LateSuccessor, (; s)) = (u = s.n,)
state_update(::LateSuccessor, (; s, t)) = (n = t < 0.05 ? s.n + 1.0 : 0,)

# The probe sees the first firing; the second writes `k` at another type.
struct LateMode <: AbstractComponent end
init_m(::LateMode) = (k = 0,)
output_types(::LateMode, ::Type{T}) where {T <: Real} = (k = Int,)
output_state(::LateMode, (; m)) = (k = m.k,)
late_mode_guard(::LateMode, (; m, t)) = t - 0.05 * (m.k + 1)
late_mode_handler(::LateMode, (; m)) = m.k == 0 ? (m = (k = m.k + 1,),) : (m = (k = 1.5,),)
state_events(::LateMode) = (fire = StateEvent(late_mode_guard, late_mode_handler),)

# The probe sees the first firing; the second writes `m` as a scalar, not a NamedTuple.
struct LateModeScalar <: AbstractComponent end
init_m(::LateModeScalar) = (k = 0,)
output_types(::LateModeScalar, ::Type{T}) where {T <: Real} = (k = Int,)
output_state(::LateModeScalar, (; m)) = (k = m.k,)
late_mode_guard(::LateModeScalar, (; m, t)) = t - 0.05 * (m.k + 1)
late_mode_scalar_handler(::LateModeScalar, (; m)) = m.k == 0 ? (m = (k = m.k + 1,),) : (m = 5,)
state_events(::LateModeScalar) = (fire = StateEvent(late_mode_guard, late_mode_scalar_handler),)

function failures_runtime()
    @testset "the cursor names where execution was after a quiet frame (§13.4)" begin
        sim = Simulation(feedback_model(); h = 1//50)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        step!(sim; t_end = 1.0)
        cursor = sim.exec.cursor
        @test cursor.phase === :ticks                    # the sequence's last block, empty here
        @test cursor.fn === :output_direct              # the last dispatch the sweep walked
        @test cursor.comp == index_of(sim.deployment.build.structure, "plant")
    end

    @testset "a throw mid-integration names the component, `state_derivative` and the stage (§13.4)" begin
        sim = Simulation(fed(Tripwire(0.05), "arm"); h = 1//10)
        init!(sim, fragment(inputs = (in = true,)))
        err = failure(() -> run!(sim; t_end = 5.0))
        @test err isa StepError
        @test err.frame == CursorFrame("c", :state_derivative, :integrate, 2)   # RK4's half-step evaluation
        @test err.boundary == 0 && err.t == 0.05
        @test err.cause isa Tripped
        @test lifecycle(sim) === :errored
        record = termination(sim)
        @test record.source isa LoopError && record.source.exception === err   # the record retains the wrap
        @test latest(sim).t == 0.0                      # the failed frame published nothing
    end

    @testset "a throw in a handler names the event round (§13.4)" begin
        sim = Simulation(fed(Mine(), "sig"); h = 1//10)
        init!(sim, fragment(inputs = (in = false,)))
        stage!(sim, "in" => true)                       # frame 1's drain arms the guard
        err = failure(() -> step!(sim; t_end = 5.0))
        @test err isa StepError{Detonated}
        @test err.frame == CursorFrame("c", :handler, :round, 1)
        @test err.boundary == 0

        # The pointer is the frame-entry index actually recorded, not a constant.
        sim2 = Simulation(fed(Mine(), "sig"); h = 1//10)
        init!(sim2, fragment(inputs = (in = false,)))
        @test step!(sim2; frames = 3, t_end = 5.0) == 3
        stage!(sim2, "in" => true)
        err = failure(() -> step!(sim2; t_end = 5.0))
        @test err isa StepError{Detonated} && err.boundary == 3
    end

    @testset "a bundle field missed past the probe is a `BundleFieldError` species (§13.2, §13.4, D-248)" begin
        sim = Simulation(single(LateRead()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{BundleFieldError}
        @test err.frame.fn === :output_state
        d = diagnostic(err)
        @test d.reason === :undeclared && d.field === :m && d.legal == [:x, :t]
        @test lifecycle(sim) === :errored

        # The author's own struct, missed just as late: unmatched, so the raw throw.
        own = Simulation(single(LateOwnMiss()); h = 1//100)
        init!(own)
        @test failure(() -> run!(own; t_end = 0.2)) isa StepError{FieldError}
    end

    @testset "a throw inside boundary zero takes the catch with pointer 0 (§13.4, D-223)" begin
        # The same mine, armed by the *authored* condition: the guard holds against
        # the not-holding prior boundary zero establishes, so the handler fires
        # inside `init!` rather than inside the loop.
        sim = Simulation(fed(Mine(), "sig"); h = 1//10)
        err = failure(() -> init!(sim, fragment(inputs = (in = true,))))
        @test err isa StepError
        @test err.frame == CursorFrame("c", :handler, :round, 1)
        @test err.boundary == 0 && err.t == 0.0         # the pointer degenerates at zero
        @test err.cause isa Detonated

        # The service's disposition: back to `built`, no termination record, and
        # the advance entries meet §12.6's ordinary refusal.
        @test lifecycle(sim) === :built
        @test termination(sim) === nothing && !closed(sim.run)
        d =
            carried(@test_throws DiagnosticError{MissingInit} step!(sim; t_end = 5.0))
        @test d.op === :step! && d.status === :built
        d =
            carried(@test_throws DiagnosticError{MissingInit} run!(sim; t_end = 5.0))
        @test d.op === :run! && d.status === :built

        # The reproduction: the header is captured before boundary zero runs, so
        # the trace already holds it — and at zero it needs no `step!` after.
        trc = trace(sim)
        @test trc.frames == 0
        @test occursin("replay!(sim2, trc) reproduces it", sprint(showerror, err))
        @test !occursin("step!", sprint(showerror, err)) # which a `step!` after would be refused

        # The twin is put in `:replay` first, by a partial replay of a good
        # recording, so the run below is one the failed replay replaced.
        ok = Simulation(fed(Mine(), "sig"); h = 1//10)
        init!(ok, fragment(inputs = (in = false,)))
        @test step!(ok; frames = 2, t_end = 5.0) == 2
        trc_ok = trace(ok)
        sim2 = Simulation(fed(Mine(), "sig"); h = 1//10)
        replay!(sim2, trc_ok; to_boundary = 1, t_end = 5.0)
        @test lifecycle(sim2) === :initialized && mode(sim2) === :replay

        replay_err = failure(() -> replay!(sim2, trc; t_end = 5.0))
        @test replay_err isa StepError{Detonated}
        @test replay_err.frame == err.frame && replay_err.boundary == 0
        @test lifecycle(sim2) === :built
        # The failed `replay!`'s own run, built ahead of the boundary, is what
        # stands, and it carries the feed, so the mode reads `:replay` (§12.6, D-260).
        # `built` is what governs: nothing advances on it, and the next door
        # replaces the run wholesale.
        @test mode(sim2) === :replay

        # The remedy is a corrected condition, and `init!` re-establishes first.
        init!(sim, fragment(inputs = (in = false,)))
        @test lifecycle(sim) === :initialized
        @test step!(sim; t_end = 5.0) == 1
    end

    @testset "a throw in a guard trial names the localization trial (§13.4)" begin
        # Arrival, validation and the boundary rounds all sit on the grid before any
        # t* has occurred, so the off-grid guard is reachable by a trial alone.
        sim = Simulation(single(Landmine(1.0, 0.35, 0.1)); h = 1//10)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 5.0))
        @test err isa StepError{Detonated}
        @test err.frame.path == "c" && err.frame.fn === :guard && err.frame.phase === :trial
        @test err.frame.index ≥ 1
        @test err.boundary == 3 && 0.3 < err.t < 0.4    # strictly inside the frame
    end

    @testset "a throw in the arrival sweep names that phase (§13.4)" begin
        # The same guard, told a grid it is not deployed on: every frame top is now
        # "off the grid", so the first evaluation of the frame — the arrival sweep at
        # the segment's end — is the one that throws. The ordinal is deliberately not
        # asserted: `evaluate!` counts RHS evaluations within the phase, so the sweep
        # reads 0 and the ẋₙ₊₁ evaluation beside it 1.
        sim = Simulation(single(Landmine(1.0, 0.35, 0.03)); h = 1//10)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 5.0))
        @test err isa StepError{Detonated}
        @test err.frame.path == "c" && err.frame.fn === :guard &&
              err.frame.phase === :arrival
        @test err.boundary == 0 && err.t == 0.1         # the frame top the integrate landed on
    end

    @testset "a throw in `state_update` or in `state_projection` names its own block (§13.4)" begin
        sim = Simulation(fed(Sapper(), "sig"); h = 1//10)
        init!(sim, fragment(inputs = (in = false,)))
        stage!(sim, "in" => true)
        err = failure(() -> step!(sim; t_end = 5.0))
        @test err isa StepError{Detonated}
        @test err.frame.path == "c" && err.frame.fn === :state_update && err.frame.phase === :ticks

        projection_sim = Simulation(single(Primer(0.15)); h = 1//10)
        init!(projection_sim)
        err = failure(() -> run!(projection_sim; t_end = 5.0))
        @test err isa StepError{Detonated}
        @test err.frame.path == "c" && err.frame.fn === :state_projection && err.frame.phase === :project
        @test err.boundary == 1                         # `q` reaches the level in frame 2
    end

    @testset "a failed frame is not counted, and the record ends at the last one (§13.4)" begin
        sim = Simulation(fed(Tripwire(0.25), "arm"); h = 1//10)
        init!(sim, fragment(inputs = (in = true,)))
        err = failure(() -> step!(sim; frames = 5, t_end = 5.0))
        @test err isa StepError && err.boundary == 2    # frame 3 throws at its half step
        @test latest(sim).t == 0.2 && termination(sim).t == 0.2
    end

    @testset "the interrupt carve-out routes to the stop path (§13.4, §12.4)" begin
        sim = Simulation(interrupted(); h = 1//10)
        probe = TailProbe()
        attach!(sim, probe, NoClaim())
        init!(sim)
        run!(sim; t_end = 5.0)                          # returns normally: never a StepError
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:interrupt)
        # The frame is abandoned unpublished, so the last published boundary is
        # final and the graceful tail runs over it.
        @test latest(sim).t == 0.2 && termination(sim).t == 0.2
        @test probe.log == [:init, :shutdown]

        # The count itself, which only the carve-out makes observable through the
        # advance's return: the interrupted frame is not one advanced.
        sim2 = Simulation(interrupted(); h = 1//10)
        init!(sim2)
        @test step!(sim2; frames = 5, t_end = 5.0) == 2
        @test lifecycle(sim2) === :stopped
        @test termination(sim2).source === ControlRequestedStop(:interrupt)
    end

    @testset "an interrupt after another issuer keeps that issuer as the source (§12.1, §13.4)" begin
        c = HookedInterrupter()
        sim = Simulation(hooked_interrupted(c); h = 1//10)
        c.hook[] = () -> stop!(sim)     # lands between the frame top's read and the raise
        init!(sim)
        run!(sim; t_end = 5.0)
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:code)
    end

    @testset "the rendering states the frame and the reproduction (§13.4, §13.2)" begin
        sim = Simulation(fed(Tripwire(0.05), "arm"); h = 1//10)
        init!(sim, fragment(inputs = (in = true,)))
        err = failure(() -> run!(sim; t_end = 5.0))
        rendered = sprint(showerror, err)
        @test occursin("`c`", rendered) && occursin("state_derivative", rendered) &&
              occursin("stage 2", rendered)
        # The pointer degenerates at zero (D-223): the replay alone reproduces it.
        @test occursin("replay!(sim2, trc) reproduces it", rendered) &&
              !occursin("step!", rendered)

        # A `Diagnostic` cause renders as its logline: the kind name leads, and the
        # leaf the sweep named is in the line.
        diverging_sim = Simulation(diverging(); h = 1//10)
        init!(diverging_sim, fragment(inputs = (in = true,)))
        diverging_rendered =
            sprint(showerror, failure(() -> step!(diverging_sim; t_end = 5.0)))
        @test occursin("NonfiniteState", diverging_rendered) &&
              occursin("`q`", diverging_rendered)
        # …and the sweep is no stage: the integrate phase renders bare at index 0.
        @test occursin("integration of the frame", diverging_rendered) &&
              !occursin("stage 0", diverging_rendered)

        # A frame whose cursor named no component drops the clause entirely: `""` is
        # a bare-leaf build's *own* root component, and "the root component" would
        # name a component where the cursor named none.
        none = StepError(CursorFrame(nothing, :none, :drain, 0), 0.3, 3, Tripped())
        none_rendered = sprint(showerror, none)
        @test occursin("StepError: drain of the frame from boundary 3", none_rendered)
        # …and away from zero the recipe is the general one, halt then step.
        @test occursin("replay!(sim2, trc; to_boundary = 3) then step!(sim2)",
                      none_rendered)
        @test !occursin("root component", none_rendered) && !occursin(" in ", none_rendered)

        # An unrecognized phase renders as itself, never as another phase's spelling.
        odd = StepError(CursorFrame("c", :state_derivative, :nowhere, 0), 0.3, 3, Tripped())
        @test occursin("nowhere of the frame", sprint(showerror, odd))

        # D-225's bound: a bare value is no cause the carrier admits.
        @test_throws MethodError StepError(CursorFrame(nothing, :none, :drain, 0), 0.3, 3, "oops")
    end

    @testset "the `Dual` activations reach the same carrier and cause (§13.4, §9.4)" begin
        # Appendix C's payloads are `Float64` and the clock under a `D8` activation
        # is a `Dual`, which `Float64` has no method for: the framing is what would
        # throw a `MethodError` over the model's own failure, losing the cause.
        sim = Simulation(fed(Tripwire(0.05), "arm"), D8; h = 1//10)
        init!(sim, fragment(inputs = (in = true,)))
        err = failure(() -> run!(sim; t_end = 5.0))
        @test err isa StepError{Tripped}
        @test err.frame == CursorFrame("c", :state_derivative, :integrate, 2)
        @test err.t == 0.05 && err.boundary == 0
        @test lifecycle(sim) === :errored

        # The sweep's own species too: `isfinite` is defined on a `Dual`, the value
        # rides as the `Dual` it is, and the payload times are seconds either way.
        diverging_sim = Simulation(diverging(), D8; h = 1//10)
        init!(diverging_sim, fragment(inputs = (in = true,)))
        err = failure(() -> step!(diverging_sim; t_end = 5.0))
        @test err isa StepError{NonfiniteState}
        # the species rule unwrapped the carrier
        @test !(err.cause isa DiagnosticError)
        @test err.cause.path == "div" && err.cause.leaf == "q" &&
              isnan(err.cause.value)
        @test err.t == 0.1 && err.cause.t == 0.1 &&
              err.cause.boundary == 0
        @test diagnostic(err) === err.cause
    end

    @testset "the sweep names the diverging block, never its downstream (§13.4, D-157)" begin
        sim = Simulation(diverging(); h = 1//10)
        init!(sim, fragment(inputs = (in = false,)))
        @test step!(sim; t_end = 5.0) == 1
        stage!(sim, "in" => true)                       # frame 2's drain arms the RHS
        err = failure(() -> step!(sim; t_end = 5.0))
        @test err isa StepError{NonfiniteState}
        d = err.cause
        @test d.path == "div" && d.leaf == "q" && isnan(d.value)
        @test d.boundary == 1 && d.t ≈ 0.2
        @test err.boundary == 1 && err.t ≈ 0.2          # the frame from boundary 1, at its top
        # The sweep is the boundary's first act: the cursor is still the integrate's,
        # named at the block's owner and at no function, and neither `div`'s own
        # `state_projection` nor `con`'s lookup has run on the NaN.
        @test err.frame.path == "div" && err.frame.fn === :none &&
              err.frame.phase === :integrate
        @test err.frame.index == 0                      # the sweep is no stage, so no ordinal
        @test !(err.cause isa DomainError) && d.path != "con"
        @test lifecycle(sim) === :errored
    end

    @testset "the sweep covers a localized frame's remainder segment (§13.4, D-157)" begin
        # `q` crosses 0.15 inside frame 2; the handler latches, and the remainder
        # segment from t* to the frame top is the integrate that diverges.
        sim = Simulation(single(LateDiverger(1.0, 0.15)); h = 1//10)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 5.0))
        @test err isa StepError{NonfiniteState}
        @test err.cause.path == "c" && err.cause.leaf == "q" && isnan(err.cause.value)
        @test err.frame.phase === :integrate && err.frame.path == "c"
        @test err.boundary == 1 && err.t ≈ 0.2          # the frame top, past the t* at 0.15
        @test err.cause.t ≈ 0.2 && err.cause.boundary == 1
    end
end

# §13.4's reproduction, end to end: a staged session that fails, the pointer its
# error names, and the same failure on a fresh twin one `step!` past the halt.
# The stage arms the failing frame *itself* — the batch is drained at that
# frame's own top and recorded at its ordinal, so the record the reproduction
# needs is the one past the halt, which is what the `:replay` mode keeps a
# consumer for (§12.7, D-218).
function reproduction(model, quiet::Int)
    sim = Simulation(model; h = 1//10)
    init!(sim, fragment(inputs = (in = false,)))
    step!(sim; frames = quiet, t_end = 5.0)         # the quiet frames before it
    stage!(sim, "in" => true)                       # drained at the failing frame's top
    failure(() -> step!(sim; t_end = 5.0))
    err = termination(sim).source.exception
    sim2 = Simulation(model; h = 1//10)
    init!(sim2, fragment(inputs = (in = false,)))
    replay!(sim2, trace(sim); to_boundary = err.boundary, t_end = 5.0)
    @test lifecycle(sim2) === :initialized          # the pointer is always a legal halt
    @test mode(sim2) === :replay                    # …with the recording still ahead of it
    @test sim2.exec.clock.step == err.boundary
    twin_err = failure(() -> step!(sim2; t_end = 5.0))
    @test twin_err isa StepError
    @test twin_err.frame == err.frame && twin_err.t == err.t &&
          twin_err.boundary == err.boundary
    @test typeof(twin_err.cause) === typeof(err.cause)
    @test lifecycle(sim2) === :errored
    @test latest(sim2).t == latest(sim).t
    err
end

function failures_pointer_twin()
    @testset "the error's pointer reproduces the failure on a fresh twin (§13.4, §12.7)" begin
        # An ordinary cause: the RHS throws at frame 4's half step, armed by that
        # frame's own drain.
        err = reproduction(fed(Tripwire(0.35), "arm"), 3)
        @test err.cause isa Tripped && err.boundary == 3
        @test err.frame == CursorFrame("c", :state_derivative, :integrate, 2)

        # And the nonfinite species, which the sweep raises rather than model code.
        err = reproduction(diverging(), 1)
        @test err.cause isa NonfiniteState && err.cause.path == "div"
        @test err.boundary == 1               # frame 2's own drain armed it
    end

    @testset "`to_boundary` counts grid boundaries, not base ticks (§12.7, §13.4)" begin
        grid() = Simulation(feedback_model(); h = 1//10, N_base = 2)
        sim = grid()
        init!(sim, fragment(inputs = (ref = 1.0,)))
        stage!(sim, "ref" => 2.0)
        @test step!(sim; frames = 6, t_end = 5.0) == 6
        trc = trace(sim)
        @test trc.frames == 6

        sim2 = grid()
        init!(sim2, fragment(inputs = (ref = 0.0,)))
        replay!(sim2, trc; to_boundary = 3, t_end = 5.0)
        @test lifecycle(sim2) === :initialized
        @test sim2.exec.clock.step == 3                 # the halt is at `k`, never at `k · n`
        @test sim2.exec.clock.step % sim2.deployment.N_base == 1        # and 3 is an off-tick frame top here
        @test same_trajectory(logged(sim2), [s for s in logged(sim) if s.frame ≤ 3])

        # `to_time` counts the same boundaries: 0.3 is boundary 3's own time here,
        # off-tick and three grid steps in, not the base tick three ticks in (D-219).
        sim4 = grid()
        init!(sim4, fragment(inputs = (ref = 0.0,)))
        replay!(sim4, trc; to_time = 0.3)
        @test sim4.exec.clock.step == 3

        # The range is the recording's frame count, so one past it refuses.
        bad = trc.frames + 1
        sim3 = grid()
        init!(sim3, fragment(inputs = (ref = 0.0,)))
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(sim3, trc; to_boundary = bad))
        @test d.call === :replay! && d.reason === :range
        @test d.argument === :to_boundary && d.value == bad
        @test lifecycle(sim3) === :initialized           # a rejected replay wrote nothing
    end
end

# --- §9.5's always-on conformance check (D-235) ---------------------------------
# The probe validates one branch; the write holds every frame's return to the
# type of the cells it writes, decided when the write's method is generated.

function failures_conformance()
    @testset "an integer port on a late branch is refused at the write (§9.5)" begin
        sim = Simulation(single(LateInteger()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.path == "c" && err.cause.what == "output_state"
        @test err.cause.reason === :field_type && err.cause.shape === :ports
        @test err.cause.field === :q
        @test err.cause.observed === Int64 && err.cause.declared === Float64
        @test err.frame.fn === :output_state
        @test lifecycle(sim) === :errored
        @test occursin("zero(", message(err.cause))    # §9.5's didactic hint
    end

    @testset "a mutable static array on a late branch is refused at the write (§9.5, D-238)" begin
        sim = Simulation(single(LateMutable()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.path == "c" && err.cause.what == "output_state"
        @test err.cause.reason === :field_type && err.cause.shape === :ports
        @test err.cause.field === :v
        @test err.cause.observed === MVector{2,Float64}
        @test err.cause.declared === SVector{2,Float64}
        @test lifecycle(sim) === :errored
    end

    @testset "an extra and a missing port on a late branch are key-set failures (§9.5)" begin
        sim = Simulation(single(LateExtraPort()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.reason === :field_set && err.cause.shape === :ports
        @test Set(err.cause.observed_fields) == Set([:q, :extra])
        @test err.cause.declared_fields == [:q]

        sim2 = Simulation(single(LateMissingPort()); h = 1//100)
        init!(sim2)
        err = failure(() -> run!(sim2; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.reason === :field_set && err.cause.shape === :ports
        @test err.cause.observed_fields == [:a]
        @test Set(err.cause.declared_fields) == Set([:a, :b])
    end

    @testset "the names are the pairing, at the port write and the state write (§9.5)" begin
        sim = Simulation(single(ScrambledPorts()); h = 1//100)
        init!(sim)
        run!(sim; t_end = 0.05)
        @test port(sim, "c", :a) == 1.0
        @test port(sim, "c", :b) == 2.0

        rate_sim = Simulation(single(ScrambledRate()); h = 1//100)
        init!(rate_sim)
        run!(rate_sim; t_end = 0.1)
        @test port(rate_sim, "c", :pa) ≈ 1.1    # ȧ = 1, over 0.1 s
        @test port(rate_sim, "c", :pb) == 2.0   # ḃ = 0, untouched
    end

    @testset "an integer derivative leaf on a late branch is refused (§7.1, §9.5)" begin
        sim = Simulation(single(LateIntegerRate()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.what == "state_derivative" && err.cause.shape === :init_x
        @test err.cause.reason === :field_type && err.cause.field === :a
        @test err.cause.observed === Int64 && err.cause.declared === Float64
        @test err.frame.fn === :state_derivative
        @test lifecycle(sim) === :errored
    end

    @testset "an integer projection leaf on a late branch is refused (§9.3, §9.5)" begin
        sim = Simulation(single(LateIntegerProjection()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.what == "state_projection" && err.cause.shape === :state
        @test err.cause.event === nothing    # a projection is the component's, not an event's
        @test err.cause.reason === :field_type && err.cause.field === :a
        @test err.cause.observed === Int64 && err.cause.declared === Float64
        @test err.frame.fn === :state_projection
        @test lifecycle(sim) === :errored
    end

    @testset "the constant branch embeds as a zero-partial at the write (§9.5, D-166)" begin
        sim = Simulation(single(DecayingBranch()), D8; h = 1//100)
        init!(sim)
        run!(sim; t_end = 0.2)                  # `a` decays under 0.5 mid-run
        value = port(sim, "c", :q)
        @test value isa D8
        @test ForwardDiff.value(value) == 0.0
        @test iszero(ForwardDiff.partials(value))
    end

    @testset "a discrete successor of another type on a late tick is refused (§7.3)" begin
        sim = Simulation(single(LateSuccessor()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.what == "state_update" && err.cause.shape === :init_s
        @test err.cause.observed === typeof((n = 0,))
        @test err.cause.declared === typeof((n = 0.0,))
        @test err.frame.fn === :state_update
        @test lifecycle(sim) === :errored
    end

    @testset "a mode write of another type on the second firing is refused (§5.2, §9.5)" begin
        sim = Simulation(single(LateMode()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.what == "handler" && err.cause.shape === :mode
        @test err.cause.event === :fire      # the event name, at run time too (§9.5, D-249)
        @test err.cause.reason === :field_type && err.cause.field === :k
        @test err.cause.observed === Float64 && err.cause.declared === Int
        @test err.frame.fn === :handler
        @test lifecycle(sim) === :errored
    end

    @testset "a mode write that is not a NamedTuple on the second firing is refused (§5.2, §9.5)" begin
        sim = Simulation(single(LateModeScalar()); h = 1//100)
        init!(sim)
        err = failure(() -> run!(sim; t_end = 0.2))
        @test err isa StepError{ConformanceFailure}
        @test err.cause.what == "handler" && err.cause.shape === :mode
        @test err.cause.event === :fire
        @test err.cause.reason === :return_type && err.cause.observed === Int
        @test occursin("NamedTuple", message(err.cause))
        @test err.frame.fn === :handler
        @test lifecycle(sim) === :errored
    end
end

function test_failures()
    failures_runtime()
    failures_conformance()
    failures_pointer_twin()
end
