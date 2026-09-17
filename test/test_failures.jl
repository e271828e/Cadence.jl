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
        sim = Simulation(feedback_model(); h = 1//50, t_end = 1.0)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        step!(sim)
        cur = sim.exec.cursor
        @test cur.phase === :ticks                      # the sequence's last block, empty here
        @test cur.fn === :output_direct                 # the last dispatch the sweep walked
        @test cur.comp == index_of(sim.build.flat, "plant")
    end

    @testset "a throw mid-integration names the component, `state_derivative` and the stage (§13.4)" begin
        sim = Simulation(fed(Tripwire(0.05), "arm"); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = true,)))
        e = failure(() -> run!(sim))
        @test e isa StepError
        @test e.frame == CursorFrame("c", :state_derivative, :integrate, 2)   # RK4's half-step evaluation
        @test e.boundary == 0 && e.t == 0.05
        @test e.cause isa Tripped
        @test lifecycle(sim) === :errored
        t = termination(sim)
        @test t.source isa LoopError && t.source.exception === e   # the record retains the wrap
        @test latest(sim).t == 0.0                      # the failed frame published nothing
    end

    @testset "a throw in a handler names the event round (§13.4)" begin
        sim = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = false,)))
        stage!(sim, "in" => true)                       # frame 1's drain arms the guard
        e = failure(() -> step!(sim))
        @test e isa StepError{Detonated}
        @test e.frame == CursorFrame("c", :handler, :round, 1)
        @test e.boundary == 0

        # The pointer is the frame-entry index actually recorded, not a constant.
        sim2 = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)
        init!(sim2, fragment(inputs = (in = false,)))
        @test step!(sim2; frames = 3) == 3
        stage!(sim2, "in" => true)
        e2 = failure(() -> step!(sim2))
        @test e2 isa StepError{Detonated} && e2.boundary == 3
    end

    @testset "a bundle field missed past the probe is a `BundleFieldError` species (§13.2, §13.4, D-248)" begin
        sim = Simulation(single(LateRead()); h = 1//100)
        init!(sim)
        e = failure(() -> run!(sim; t_end = 0.2))
        @test e isa StepError{BundleFieldError}
        @test e.frame.fn === :output_state
        d = diagnostic(e)
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
        sim = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)
        e = failure(() -> init!(sim, fragment(inputs = (in = true,))))
        @test e isa StepError
        @test e.frame == CursorFrame("c", :handler, :round, 1)
        @test e.boundary == 0 && e.t == 0.0             # the pointer degenerates at zero
        @test e.cause isa Detonated

        # The service's disposition: back to `built`, no termination record, and
        # the advance entries meet §12.6's ordinary refusal.
        @test lifecycle(sim) === :built
        @test termination(sim) === nothing
        ds = carried(@test_throws DiagnosticError{MissingInit} step!(sim))
        @test ds.op === :step! && ds.status === :built
        dr = carried(@test_throws DiagnosticError{MissingInit} run!(sim))
        @test dr.op === :run! && dr.status === :built

        # The reproduction: the header is captured before boundary zero runs, so
        # the trace already holds it — and at zero it needs no `step!` after.
        trc = trace(sim)
        @test trc.frames == 0
        @test occursin("replay!(sim2, trc) reproduces it", sprint(showerror, e))
        @test !occursin("step!", sprint(showerror, e))  # which a `step!` after would be refused

        # The twin is put in `:replay` first, by a partial replay of a good
        # recording, so the words below are ones the failed replay moved.
        ok = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)
        init!(ok, fragment(inputs = (in = false,)))
        @test step!(ok; frames = 2) == 2
        trc_ok = trace(ok)
        sim2 = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)
        replay!(sim2, trc_ok; to_boundary = 1)
        @test lifecycle(sim2) === :initialized && mode(sim2) === :replay

        e2 = failure(() -> replay!(sim2, trc))
        @test e2 isa StepError{Detonated}
        @test e2.frame == e.frame && e2.boundary == 0
        @test lifecycle(sim2) === :built
        @test mode(sim2) === :live                      # the reset precedes the boundary

        # The remedy is a corrected condition, and `init!` re-establishes first.
        init!(sim, fragment(inputs = (in = false,)))
        @test lifecycle(sim) === :initialized
        @test step!(sim) == 1
    end

    @testset "a throw in a guard trial names the localization trial (§13.4)" begin
        # Arrival, validation and the boundary rounds all sit on the grid before any
        # t* has occurred, so the off-grid guard is reachable by a trial alone.
        sim = Simulation(single(Landmine(1.0, 0.35, 0.1)); h = 1//10, t_end = 5.0)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{Detonated}
        @test e.frame.path == "c" && e.frame.fn === :guard && e.frame.phase === :trial
        @test e.frame.index ≥ 1
        @test e.boundary == 3 && 0.3 < e.t < 0.4        # strictly inside the frame
    end

    @testset "a throw in the arrival sweep names that phase (§13.4)" begin
        # The same guard, told a grid it is not deployed on: every frame top is now
        # "off the grid", so the first evaluation of the frame — the arrival sweep at
        # the segment's end — is the one that throws. The ordinal is deliberately not
        # asserted: `evaluate!` counts RHS evaluations within the phase, so the sweep
        # reads 0 and the ẋₙ₊₁ evaluation beside it 1.
        sim = Simulation(single(Landmine(1.0, 0.35, 0.03)); h = 1//10, t_end = 5.0)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{Detonated}
        @test e.frame.path == "c" && e.frame.fn === :guard && e.frame.phase === :arrival
        @test e.boundary == 0 && e.t == 0.1             # the frame top the integrate landed on
    end

    @testset "a throw in `state_update` or in `state_projection` names its own block (§13.4)" begin
        sim = Simulation(fed(Sapper(), "sig"); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = false,)))
        stage!(sim, "in" => true)
        e = failure(() -> step!(sim))
        @test e isa StepError{Detonated}
        @test e.frame.path == "c" && e.frame.fn === :state_update && e.frame.phase === :ticks

        simp = Simulation(single(Primer(0.15)); h = 1//10, t_end = 5.0)
        init!(simp)
        ep = failure(() -> run!(simp))
        @test ep isa StepError{Detonated}
        @test ep.frame.path == "c" && ep.frame.fn === :state_projection && ep.frame.phase === :project
        @test ep.boundary == 1                          # `q` reaches the level in frame 2
    end

    @testset "a failed frame is not counted, and the record ends at the last one (§13.4)" begin
        sim = Simulation(fed(Tripwire(0.25), "arm"); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = true,)))
        e = failure(() -> step!(sim; frames = 5))
        @test e isa StepError && e.boundary == 2        # frame 3 throws at its half step
        @test latest(sim).t == 0.2 && termination(sim).t == 0.2
    end

    @testset "the interrupt carve-out routes to the stop path (§13.4, §12.4)" begin
        sim = Simulation(interrupted(); h = 1//10, t_end = 5.0)
        probe = TailProbe()
        attach!(sim, probe, NoClaim())
        init!(sim)
        run!(sim)                                       # returns normally: never a StepError
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:interrupt)
        # The frame is abandoned unpublished, so the last published boundary is
        # final and the graceful tail runs over it.
        @test latest(sim).t == 0.2 && termination(sim).t == 0.2
        @test probe.log == [:init, :shutdown]

        # The count itself, which only the carve-out makes observable through the
        # advance's return: the interrupted frame is not one advanced.
        sim2 = Simulation(interrupted(); h = 1//10, t_end = 5.0)
        init!(sim2)
        @test step!(sim2; frames = 5) == 2
        @test lifecycle(sim2) === :stopped
        @test termination(sim2).source === ControlRequestedStop(:interrupt)
    end

    @testset "an interrupt after another issuer keeps that issuer as the source (§12.1, §13.4)" begin
        c = HookedInterrupter()
        sim = Simulation(hooked_interrupted(c); h = 1//10, t_end = 5.0)
        c.hook[] = () -> stop!(sim)     # lands between the frame top's read and the raise
        init!(sim)
        run!(sim)
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:code)
    end

    @testset "the rendering states the frame and the reproduction (§13.4, §13.2)" begin
        sim = Simulation(fed(Tripwire(0.05), "arm"); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = true,)))
        e = failure(() -> run!(sim))
        s = sprint(showerror, e)
        @test occursin("`c`", s) && occursin("state_derivative", s) && occursin("stage 2", s)
        # The pointer degenerates at zero (D-223): the replay alone reproduces it.
        @test occursin("replay!(sim2, trc) reproduces it", s) && !occursin("step!", s)

        # A `Diagnostic` cause renders as its logline: the kind name leads, and the
        # leaf the sweep named is in the line.
        dv = Simulation(diverging(); h = 1//10, t_end = 5.0)
        init!(dv, fragment(inputs = (in = true,)))
        sn = sprint(showerror, failure(() -> step!(dv)))
        @test occursin("NonfiniteState", sn) && occursin("`q`", sn)
        # …and the sweep is no stage: the integrate phase renders bare at index 0.
        @test occursin("integration of the frame", sn) && !occursin("stage 0", sn)

        # A frame whose cursor named no component drops the clause entirely: `""` is
        # a bare-leaf build's *own* root component, and "the root component" would
        # name a component where the cursor named none.
        none = StepError(CursorFrame(nothing, :none, :drain, 0), 0.3, 3, Tripped())
        sn0 = sprint(showerror, none)
        @test occursin("StepError: drain of the frame from boundary 3", sn0)
        # …and away from zero the recipe is the general one, halt then step.
        @test occursin("replay!(sim2, trc; to_boundary = 3) then step!(sim2)", sn0)
        @test !occursin("root component", sn0) && !occursin(" in ", sn0)

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
        sim = Simulation(fed(Tripwire(0.05), "arm"), D8; h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = true,)))
        e = failure(() -> run!(sim))
        @test e isa StepError{Tripped}
        @test e.frame == CursorFrame("c", :state_derivative, :integrate, 2)
        @test e.t == 0.05 && e.boundary == 0
        @test lifecycle(sim) === :errored

        # The sweep's own species too: `isfinite` is defined on a `Dual`, the value
        # rides as the `Dual` it is, and the payload times are seconds either way.
        dv = Simulation(diverging(), D8; h = 1//10, t_end = 5.0)
        init!(dv, fragment(inputs = (in = true,)))
        en = failure(() -> step!(dv))
        @test en isa StepError{NonfiniteState}
        @test !(en.cause isa DiagnosticError)   # the species rule unwrapped the carrier
        @test en.cause.path == "div" && en.cause.leaf == "q" && isnan(en.cause.value)
        @test en.t == 0.1 && en.cause.t == 0.1 && en.cause.boundary == 0
        @test diagnostic(en) === en.cause
    end

    @testset "the sweep names the diverging block, never its downstream (§13.4, D-157)" begin
        sim = Simulation(diverging(); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = false,)))
        @test step!(sim) == 1
        stage!(sim, "in" => true)                       # frame 2's drain arms the RHS
        e = failure(() -> step!(sim))
        @test e isa StepError{NonfiniteState}
        d = e.cause
        @test d.path == "div" && d.leaf == "q" && isnan(d.value)
        @test d.boundary == 1 && d.t ≈ 0.2
        @test e.boundary == 1 && e.t ≈ 0.2              # the frame from boundary 1, at its top
        # The sweep is the boundary's first act: the cursor is still the integrate's,
        # named at the block's owner and at no function, and neither `div`'s own
        # `state_projection` nor `con`'s lookup has run on the NaN.
        @test e.frame.path == "div" && e.frame.fn === :none && e.frame.phase === :integrate
        @test e.frame.index == 0                        # the sweep is no stage, so no ordinal
        @test !(e.cause isa DomainError) && d.path != "con"
        @test lifecycle(sim) === :errored
    end

    @testset "the sweep covers a localized frame's remainder segment (§13.4, D-157)" begin
        # `q` crosses 0.15 inside frame 2; the handler latches, and the remainder
        # segment from t* to the frame top is the integrate that diverges.
        sim = Simulation(single(LateDiverger(1.0, 0.15)); h = 1//10, t_end = 5.0)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{NonfiniteState}
        @test e.cause.path == "c" && e.cause.leaf == "q" && isnan(e.cause.value)
        @test e.frame.phase === :integrate && e.frame.path == "c"
        @test e.boundary == 1 && e.t ≈ 0.2              # the frame top, past the t* at 0.15
        @test e.cause.t ≈ 0.2 && e.cause.boundary == 1
    end
end

# §13.4's reproduction, end to end: a staged session that fails, the pointer its
# error names, and the same failure on a fresh twin one `step!` past the halt.
# The stage arms the failing frame *itself* — the batch is drained at that
# frame's own top and recorded at its ordinal, so the record the reproduction
# needs is the one past the halt, which is what the `:replay` mode keeps a
# consumer for (§12.7, D-218).
function reproduction(model, quiet::Int)
    sim = Simulation(model; h = 1//10, t_end = 5.0)
    init!(sim, fragment(inputs = (in = false,)))
    step!(sim; frames = quiet)                      # the quiet frames before it
    stage!(sim, "in" => true)                       # drained at the failing frame's top
    failure(() -> step!(sim))
    e = termination(sim).source.exception
    sim2 = Simulation(model; h = 1//10, t_end = 5.0)
    init!(sim2, fragment(inputs = (in = false,)))
    replay!(sim2, trace(sim); to_boundary = e.boundary)
    @test lifecycle(sim2) === :initialized          # the pointer is always a legal halt
    @test mode(sim2) === :replay                    # …with the recording still ahead of it
    @test sim2.exec.clock.step == e.boundary
    e2 = failure(() -> step!(sim2))
    @test e2 isa StepError
    @test e2.frame == e.frame && e2.t == e.t && e2.boundary == e.boundary
    @test typeof(e2.cause) === typeof(e.cause)
    @test lifecycle(sim2) === :errored
    @test latest(sim2).t == latest(sim).t
    e
end

function failures_pointer_twin()
    @testset "the error's pointer reproduces the failure on a fresh twin (§13.4, §12.7)" begin
        # An ordinary cause: the RHS throws at frame 4's half step, armed by that
        # frame's own drain.
        e = reproduction(fed(Tripwire(0.35), "arm"), 3)
        @test e.cause isa Tripped && e.boundary == 3
        @test e.frame == CursorFrame("c", :state_derivative, :integrate, 2)

        # And the nonfinite species, which the sweep raises rather than model code.
        en = reproduction(diverging(), 1)
        @test en.cause isa NonfiniteState && en.cause.path == "div"
        @test en.boundary == 1                          # frame 2's own drain armed it
    end

    @testset "`to_boundary` counts grid boundaries, not base ticks (§12.7, §13.4)" begin
        grid() = Simulation(feedback_model(); h = 1//10, N_base = 2, t_end = 5.0)
        sim = grid()
        init!(sim, fragment(inputs = (ref = 1.0,)))
        stage!(sim, "ref" => 2.0)
        @test step!(sim; frames = 6) == 6
        trc = trace(sim)
        @test trc.frames == 6

        sim2 = grid()
        init!(sim2, fragment(inputs = (ref = 0.0,)))
        replay!(sim2, trc; to_boundary = 3)
        @test lifecycle(sim2) === :initialized
        @test sim2.exec.clock.step == 3                 # the halt is at `k`, never at `k · n`
        @test sim2.exec.clock.step % sim2.N_base == 1        # and 3 is an off-tick frame top here
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
        sim = Simulation(single(LateInteger()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.path == "c" && e.cause.what == "output_state"
        @test e.cause.reason === :field_type && e.cause.shape === :ports
        @test e.cause.field === :q
        @test e.cause.observed === Int64 && e.cause.declared === Float64
        @test e.frame.fn === :output_state
        @test lifecycle(sim) === :errored
        @test occursin("zero(", message(e.cause))      # §9.5's didactic hint
    end

    @testset "a mutable static array on a late branch is refused at the write (§9.5, D-238)" begin
        sim = Simulation(single(LateMutable()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.path == "c" && e.cause.what == "output_state"
        @test e.cause.reason === :field_type && e.cause.shape === :ports
        @test e.cause.field === :v
        @test e.cause.observed === MVector{2,Float64}
        @test e.cause.declared === SVector{2,Float64}
        @test lifecycle(sim) === :errored
    end

    @testset "an extra and a missing port on a late branch are key-set failures (§9.5)" begin
        sim = Simulation(single(LateExtraPort()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.reason === :field_set && e.cause.shape === :ports
        @test Set(e.cause.observed_fields) == Set([:q, :extra])
        @test e.cause.declared_fields == [:q]

        sim2 = Simulation(single(LateMissingPort()); h = 1//100, t_end = 0.2)
        init!(sim2)
        e2 = failure(() -> run!(sim2))
        @test e2 isa StepError{ConformanceFailure}
        @test e2.cause.reason === :field_set && e2.cause.shape === :ports
        @test e2.cause.observed_fields == [:a]
        @test Set(e2.cause.declared_fields) == Set([:a, :b])
    end

    @testset "the names are the pairing, at the port write and the state write (§9.5)" begin
        sim = Simulation(single(ScrambledPorts()); h = 1//100, t_end = 0.05)
        init!(sim)
        run!(sim)
        @test port(sim, "c", :a) == 1.0
        @test port(sim, "c", :b) == 2.0

        simr = Simulation(single(ScrambledRate()); h = 1//100, t_end = 0.1)
        init!(simr)
        run!(simr)
        @test port(simr, "c", :pa) ≈ 1.1        # ȧ = 1, over 0.1 s
        @test port(simr, "c", :pb) == 2.0       # ḃ = 0, untouched
    end

    @testset "an integer derivative leaf on a late branch is refused (§7.1, §9.5)" begin
        sim = Simulation(single(LateIntegerRate()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.what == "state_derivative" && e.cause.shape === :init_x
        @test e.cause.reason === :field_type && e.cause.field === :a
        @test e.cause.observed === Int64 && e.cause.declared === Float64
        @test e.frame.fn === :state_derivative
        @test lifecycle(sim) === :errored
    end

    @testset "an integer projection leaf on a late branch is refused (§9.3, §9.5)" begin
        sim = Simulation(single(LateIntegerProjection()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.what == "state_projection" && e.cause.shape === :state
        @test e.cause.reason === :field_type && e.cause.field === :a
        @test e.cause.observed === Int64 && e.cause.declared === Float64
        @test e.frame.fn === :state_projection
        @test lifecycle(sim) === :errored
    end

    @testset "the constant branch embeds as a zero-partial at the write (§9.5, D-166)" begin
        sim = Simulation(single(DecayingBranch()), D8; h = 1//100)
        init!(sim)
        run!(sim; t_end = 0.2)                  # `a` decays under 0.5 mid-run
        q = port(sim, "c", :q)
        @test q isa D8
        @test ForwardDiff.value(q) == 0.0
        @test iszero(ForwardDiff.partials(q))
    end

    @testset "a discrete successor of another type on a late tick is refused (§7.3)" begin
        sim = Simulation(single(LateSuccessor()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.what == "state_update" && e.cause.shape === :init_s
        @test e.cause.observed === typeof((n = 0,))
        @test e.cause.declared === typeof((n = 0.0,))
        @test e.frame.fn === :state_update
        @test lifecycle(sim) === :errored
    end

    @testset "a mode write of another type on the second firing is refused (§5.2, §9.5)" begin
        sim = Simulation(single(LateMode()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.what == "handler" && e.cause.shape === :mode
        @test e.cause.reason === :field_type && e.cause.field === :k
        @test e.cause.observed === Float64 && e.cause.declared === Int
        @test e.frame.fn === :handler
        @test lifecycle(sim) === :errored
    end

    @testset "a mode write that is not a NamedTuple on the second firing is refused (§5.2, §9.5)" begin
        sim = Simulation(single(LateModeScalar()); h = 1//100, t_end = 0.2)
        init!(sim)
        e = failure(() -> run!(sim))
        @test e isa StepError{ConformanceFailure}
        @test e.cause.what == "handler" && e.cause.shape === :mode
        @test e.cause.reason === :return_type && e.cause.observed === Int
        @test occursin("NamedTuple", message(e.cause))
        @test e.frame.fn === :handler
        @test lifecycle(sim) === :errored
    end
end

function test_failures()
    failures_runtime()
    failures_conformance()
    failures_pointer_twin()
end
