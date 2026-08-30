# --- runtime failures (§13.4; increment 24) -------------------------------------
# The execution cursor written per dispatch and per phase transition, the one
# catch site wrapping into `StepError` against it, and the `InterruptException`
# carve-out to the stop path. The fixtures are library components (`Tripwire`,
# `Mine`, `Landmine`, `Sapper`, `Primer`, `Interrupter`); the models below live
# at top level for `status.md`'s local-scope reason.

# The interrupter armed by its own ramp: `q = t` crosses the trigger's level at
# boundary 2, so frame 3's integrate is the first that raises the interrupt.
interrupted() = Group((c = Interrupter(), trig = Trigger(0.15));
                      wires = ("c/q" => "trig/sig", "trig/on" => "c/arm"))

@testset "the cursor names where execution was after a quiet frame (§13.4)" begin
    sim = Simulation(feedback_model(); h = 1//50, t_end = 1.0)
    init!(sim, fragment(inputs = (ref = 0.0,)))
    step!(sim)
    cur = sim.exec.cursor
    @test cur.phase === :ticks                      # the sequence's last block, empty here
    @test cur.fn === :h_xu                          # the last dispatch the sweep walked
    @test cur.comp == index_of(sim.build.flat, "plant")
end

@testset "a throw mid-integration names the component, `f` and the stage (§13.4)" begin
    sim = Simulation(fed(Tripwire(0.05), "arm"); h = 1//10, t_end = 5.0)
    init!(sim, fragment(inputs = (in = true,)))
    e = failure(() -> run!(sim))
    @test e isa StepError
    @test e.frame == CursorFrame("c", :f, :integrate, 2)   # RK4's half-step evaluation
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

@testset "a throw in `g` or in `project` names its own block (§13.4)" begin
    sim = Simulation(fed(Sapper(), "sig"); h = 1//10, t_end = 5.0)
    init!(sim, fragment(inputs = (in = false,)))
    stage!(sim, "in" => true)
    e = failure(() -> step!(sim))
    @test e isa StepError && e.cause isa Detonated
    @test e.frame.path == "c" && e.frame.fn === :g && e.frame.phase === :ticks

    simp = Simulation(single(Primer(0.15)); h = 1//10, t_end = 5.0)
    init!(simp)
    ep = failure(() -> run!(simp))
    @test ep isa StepError && ep.cause isa Detonated
    @test ep.frame.path == "c" && ep.frame.fn === :project && ep.frame.phase === :project
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
    @test occursin("`c`", s) && occursin("f", s) && occursin("stage 2", s)
    @test occursin("to_boundary = 0", s) && occursin("step!", s)
end
