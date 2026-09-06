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

# The diverger and the innocent component downstream of it: `con` reads `div`'s
# state through the ordinary signal path, so a sweep running later than the
# integrate would blame the lookup rather than the block that blew up.
diverging() = Group((div = Diverger(), con = Consumer());
                    wires = ("div/q" => "con/in",), inputs = ("in" => "div/arm",))

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
        @test e isa StepError && e.cause isa Detonated
        @test e.frame == CursorFrame("c", :handler, :round, 1)
        @test e.boundary == 0

        # The pointer is the frame-entry index actually recorded, not a constant.
        sim2 = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)
        init!(sim2, fragment(inputs = (in = false,)))
        @test step!(sim2; frames = 3) == 3
        stage!(sim2, "in" => true)
        e2 = failure(() -> step!(sim2))
        @test e2 isa StepError && e2.boundary == 3 && e2.cause isa Detonated
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
        sim2 = Simulation(fed(Mine(), "sig"); h = 1//10, t_end = 5.0)
        e2 = failure(() -> replay!(sim2, trc))
        @test e2 isa StepError && e2.cause isa Detonated
        @test e2.frame == e.frame && e2.boundary == 0
        @test lifecycle(sim2) === :built
        @test mode(sim2) === :live                      # the mode is entered after the boundary

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
        @test e isa StepError && e.cause isa Detonated
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
        @test e isa StepError && e.cause isa Detonated
        @test e.frame.path == "c" && e.frame.fn === :guard && e.frame.phase === :arrival
        @test e.boundary == 0 && e.t == 0.1             # the frame top the integrate landed on
    end

    @testset "a throw in `state_update` or in `state_projection` names its own block (§13.4)" begin
        sim = Simulation(fed(Sapper(), "sig"); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = false,)))
        stage!(sim, "in" => true)
        e = failure(() -> step!(sim))
        @test e isa StepError && e.cause isa Detonated
        @test e.frame.path == "c" && e.frame.fn === :state_update && e.frame.phase === :ticks

        simp = Simulation(single(Primer(0.15)); h = 1//10, t_end = 5.0)
        init!(simp)
        ep = failure(() -> run!(simp))
        @test ep isa StepError && ep.cause isa Detonated
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

    @testset "the rendering states the frame and the reproduction (§13.4, §13.2)" begin
        sim = Simulation(fed(Tripwire(0.05), "arm"); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = true,)))
        e = failure(() -> run!(sim))
        s = sprint(showerror, e)
        @test occursin("`c`", s) && occursin("state_derivative", s) && occursin("stage 2", s)
        @test occursin("to_boundary = 0", s) && occursin("step!", s)

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
        @test !occursin("root component", sn0) && !occursin(" in ", sn0)

        # An unrecognized phase renders as itself, never as another phase's spelling.
        odd = StepError(CursorFrame("c", :state_derivative, :nowhere, 0), 0.3, 3, Tripped())
        @test occursin("nowhere of the frame", sprint(showerror, odd))
    end

    @testset "the `Dual` activations reach the same carrier and cause (§13.4, §9.4)" begin
        # Appendix C's payloads are `Float64` and the clock under a `D8` activation
        # is a `Dual`, which `Float64` has no method for: the framing is what would
        # throw a `MethodError` over the model's own failure, losing the cause.
        sim = Simulation(fed(Tripwire(0.05), "arm"), D8; h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = true,)))
        e = failure(() -> run!(sim))
        @test e isa StepError && e.cause isa Tripped
        @test e.frame == CursorFrame("c", :state_derivative, :integrate, 2)
        @test e.t == 0.05 && e.boundary == 0
        @test lifecycle(sim) === :errored

        # The sweep's own species too: `isfinite` is defined on a `Dual`, the value
        # rides as the `Dual` it is, and the payload times are seconds either way.
        dv = Simulation(diverging(), D8; h = 1//10, t_end = 5.0)
        init!(dv, fragment(inputs = (in = true,)))
        en = failure(() -> step!(dv))
        @test en isa StepError && en.cause isa NonfiniteState
        @test !(en.cause isa DiagnosticError)   # the species rule unwrapped the carrier
        @test en.cause.path == "div" && en.cause.leaf == "q" && isnan(en.cause.value)
        @test en.t == 0.1 && en.cause.t == 0.1 && en.cause.boundary == 0
    end

    @testset "the sweep names the diverging block, never its downstream (§13.4, D-157)" begin
        sim = Simulation(diverging(); h = 1//10, t_end = 5.0)
        init!(sim, fragment(inputs = (in = false,)))
        @test step!(sim) == 1
        stage!(sim, "in" => true)                       # frame 2's drain arms the RHS
        e = failure(() -> step!(sim))
        @test e isa StepError && e.cause isa NonfiniteState
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
        @test e isa StepError && e.cause isa NonfiniteState
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
        grid() = Simulation(feedback_model(); h = 1//10, n = 2, t_end = 5.0)
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
        @test sim2.exec.clock.step % sim2.n == 1        # and 3 is an off-tick frame top here
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

function test_failures()
    failures_runtime()
    failures_pointer_twin()
end
