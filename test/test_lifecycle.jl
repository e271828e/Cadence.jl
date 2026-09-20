# --- run lifecycle and termination (§12.6, §13.5, §13.6; increment 16) ----------
# The five-state machine behind `lifecycle(sim)`, the stop policy each advance
# declares and binds, partial advance, the §13.5 termination record and
# §13.6's abnormal entry. The devices below live at top level for `implementation.md`'s
# local-scope reason.

# A monitored ramp: `hit` goes true at the first boundary whose sweep sees the
# ramp at the trigger's level — the boundary-detected stop face.
monitored() = Group((; src = Ramp(0.0), trig = Trigger(0.35));
                    wires = ("src/out" => "trig/sig",),
                    outputs = ("trig/on" => "hit",))

# A root-input-fed trigger exporting its flag: the boundary-zero stop's model.
armed() = Group((; c = Trigger(0.5)); inputs = ("in" => "c/sig",),
                outputs = ("c/on" => "stop",))

# A resource-bracket witness for the abnormal tail, and the empty-claim binding
# that rosters it.
mutable struct TailProbe <: AbstractDevice
    log::Vector{Symbol}
end
TailProbe() = TailProbe(Symbol[])
init!(d::TailProbe) = (push!(d.log, :init); nothing)
shutdown!(d::TailProbe) = (push!(d.log, :shutdown); nothing)
function loop(d::TailProbe, h)
    while running(h)
        wait_next_snapshot(h)
    end
    nothing
end
struct NoClaim <: AbstractBinding end
is_input(::NoClaim) = true
claims(::NoClaim) = ()

function test_lifecycle()
    @testset "the five states, and the gates between them (§12.6)" begin
        sim = Simulation(feedback_model(); h = 1//50)
        @test lifecycle(sim) === :built
        @test termination(sim) === nothing
        diag = carried(@test_throws DiagnosticError{MissingInit} run!(sim; t_end = 1.0))
        @test diag.op === :run! && diag.status === :built
        diag2 = carried(@test_throws DiagnosticError{MissingInit} step!(sim; t_end = 1.0))
        @test diag2.op === :step!

        init!(sim, fragment(inputs = (ref = 0.0,)))
        @test lifecycle(sim) === :initialized
        init!(sim, fragment(inputs = (ref = 0.0,)))  # a warm restart from initialized is legal
        run!(sim; t_end = 1.0)
        @test lifecycle(sim) === :stopped
        diag = carried(@test_throws DiagnosticError{ServiceLifecycle} run!(sim; t_end = 1.0))
        @test diag.op === :run! && diag.status === :stopped
        @test diag.legal == [:initialized]               # §12.6: the advance entries' one state
        diag2 = carried(@test_throws DiagnosticError{ServiceLifecycle} step!(sim; t_end = 1.0))
        @test diag2.op === :step! && diag2.status === :stopped
        init!(sim, fragment(inputs = (ref = 0.0,)))  # the supported cycle reopens it
        @test lifecycle(sim) === :initialized
        @test termination(sim) === nothing               # the record cleared with the trajectory
    end

    @testset "the freeze is the lifecycle's :running — init! and run! refuse it too (§12.6)" begin
        # Both ends of the run are test-controlled: the spin below waits for its
        # start, and the run cannot reach *its* end until the stop face is staged,
        # so the mid-run probes race nothing — no frame count and no JIT warming
        # stand between them. `t_end` is a loud safety net rather than the run's
        # expected end — 30M frames, twenty times what the probes' own compilation
        # costs — and reaching it fails the source assertion instead of hanging.
        sim = Simulation(armed(); h = 1//100)
        total = fragment(inputs = (in = 0.0,))           # below the trigger: the run holds
        init!(sim, total)
        t = Threads.@spawn run!(sim; t_end = 3.0e5, stop_on = ("stop",))
        while lifecycle(sim) !== :running
            yield()
        end
        diag_i = carried(@test_throws DiagnosticError{ServiceLifecycle} init!(sim, total))
        diag_r = carried(@test_throws DiagnosticError{ServiceLifecycle} run!(sim; t_end = 2.0,
                                                                            stop_on = ("stop",)))
        stage!(sim, "in" => 1.0)                         # now, and only now, may the run end:
        wait(t)                                          # the next drain arms the trigger (§12.6)
        @test diag_i.op === :init! &&
              diag_i.status === :running
        @test diag_r.op === :run! &&
              diag_r.status === :running
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ModelRequestedStop(:stop)
    end

    @testset "t_end is the advance's own bound, validated per call (§13.5)" begin
        sim = Simulation(feedback_model(); h = 1//50)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        run!(sim; t_end = 1.0)                           # this advance's bound
        t = termination(sim)
        @test t isa TerminationRecord{Float64}           # the deployment's own scalar (§7.2, D-203)
        @test t.source === EndTimeReached() && t.t == 1.0
        @test isempty(t.residue)                         # a quiet tail contributes no record
        @test sim.exec.clock.step == 50

        # §12.4: the run ends at the first frame top reaching or exceeding
        # `t_end`, whole frames from `t₀` — an off-grid bound overshoots by
        # less than `h`, an offset origin counts from itself, a bound at or
        # before the origin advances nothing, and a large clock still lands a
        # grid-aligned bound on its own frame (`_frames_to`'s slack scales
        # with the time's magnitude; `step!`'s `t_plus` is the same rule)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        run!(sim; t_end = 0.99)
        @test termination(sim).t == 1.0 && sim.exec.clock.step == 50
        init!(sim, fragment(inputs = (ref = 0.0,)); t0 = 10.0)
        run!(sim; t_end = 12.0)
        @test termination(sim).t == 12.0 && sim.exec.clock.step == 100
        init!(sim, fragment(inputs = (ref = 0.0,)); t0 = 10.0)
        run!(sim; t_end = 5.0)
        @test termination(sim).source === EndTimeReached() && sim.exec.clock.step == 0
        late = Simulation(feedback_model(); h = 1//50)   # `t_end = Inf`: the default `1.0` would precede `t0`
        init!(late, fragment(inputs = (ref = 0.0,)); t0 = 86400.0)
        @test step!(late; t_plus = 1.0) == 50
        run!(late; t_end = 86402.0)
        @test termination(late).t == 86402.0 && late.exec.clock.step == 100

        init!(sim, fragment(inputs = (ref = 0.0,)))
        run!(sim; t_end = 0.5)                           # this advance only
        @test termination(sim).t == 0.5
        init!(sim, fragment(inputs = (ref = 0.0,)))
        run!(sim; t_end = 1.0)                           # a different bound, no rebuild (§12.6)
        @test termination(sim).t == 1.0

        # `Inf` is the default and a value (Appendix B): an advance bounded by its
        # stop face alone, and one advance's `Inf` after another's finite bound.
        unbound = Simulation(monitored(); h = 1//10)
        init!(unbound)
        run!(unbound; stop_on = ("hit",))
        @test termination(unbound).source === ModelRequestedStop(:hit)
        lifted = Simulation(monitored(); h = 1//10)
        init!(lifted)
        run!(lifted; t_end = 0.2, stop_on = ("hit",))
        @test termination(lifted).source === EndTimeReached() && termination(lifted).t == 0.2
        init!(lifted)
        run!(lifted; t_end = Inf, stop_on = ("hit",))
        @test termination(lifted).t == 4 * lifted.deployment.h
        unbound = Simulation(feedback_model(); h = 1//50)
        init!(unbound, fragment(inputs = (ref = 0.0,)))
        # The bound is validated identically at the three binding sites: the same
        # payload — argument, reason and offending value — with the naming call the
        # one field that differs (§13.5, D-255, D-249).
        dr = carried(@test_throws DiagnosticError{ArgumentInvalid} run!(unbound; t_end = -1.0))
        dp = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(unbound, trace(unbound); t_end = -1.0))
        ds = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(unbound; t_end = -1.0))
        @test dr.argument == dp.argument == ds.argument == :t_end
        @test dr.reason == dp.reason == ds.reason == :range
        @test dr.value == dp.value == ds.value == -1.0
        @test dr.call === :run! && dp.call === :replay! && ds.call === :step!
    end

    @testset "stop_on names root-exported Bool output faces, validated at all three sites (§13.5)" begin
        m = feedback_model()                        # "ref" a root input, "y" a Float64 export
        sim = Simulation(m; h = 1//50)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        trc = trace(sim)                            # the header alone: `replay!` binds as `run!` does
        for (bad, reason) in (("nope", :unknown), ("ref", :root_input), ("y", :not_bool))
            er = failure(() -> run!(sim; t_end = 1.0, stop_on = (bad,)))
            ep = failure(() -> replay!(sim, trc; stop_on = (bad,)))
            es = failure(() -> step!(sim; stop_on = (bad,)))
            dr, dp, ds = only(diagnostics(er)), only(diagnostics(ep)), only(diagnostics(es))
            @test er isa DiagnosticError && dr isa StopFaceInvalid && dr.reason === reason
            @test dr.face == dp.face == ds.face && dr.reason == dp.reason == ds.reason &&
                  dr.declared == dp.declared == ds.declared   # identical at all three sites
            # The binding site is the one payload field that differs (§13.5, D-249).
            @test dr.site === :run! && dp.site === :replay! && ds.site === :step!
        end
        # One advance is one call, and the bound refuses first: `_t_bound` is
        # fail-fast and runs ahead of the faces, so a call naming both a bad bound
        # and a bad face is refused for the bound (§13.5, D-229).
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} run!(sim; t_end = -1.0,
                                                                       stop_on = ("nope",)))
        @test d.argument === :t_end && d.call === :run!

        @test lifecycle(sim) === :initialized            # a rejected advance bound nothing
    end

    @testset "a boundary-detected stop face ends the run at its own boundary (§13.5)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 5.0, stop_on = ("hit",))
        t = termination(sim)
        @test t.source === ModelRequestedStop(:hit)      # kind + payload, one typed value (D-203)
        @test t.t == 4 * sim.deployment.h                # the sweep at boundary 4 saw 0.4 ≥ 0.35
        @test sim.exec.clock.step == 4                        # the run ended there, not at t_end
        @test latest(sim).t === t.t                      # that snapshot is the final one
    end

    @testset "an authored condition already terminal ends the run at t₀, integrating nothing (§13.5)" begin
        sim = Simulation(armed(); h = 1//10)
        init!(sim, fragment(inputs = (in = 1.0,)))        # holds in the authored state:
        #                                                boundary zero derives the firing (§10.6)
        run!(sim; t_end = 5.0, stop_on = ("stop",))
        t = termination(sim)
        @test t.source === ModelRequestedStop(:stop) && t.t == 0.0
        @test sim.exec.clock.step == 0              # zero frames: the check precedes the first step
    end

    @testset "a localized stop ends the run at t*, the crossing state final (§13.5, §10.4)" begin
        sim = Simulation(overloaded(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 5.0, stop_on = ("tripped",))
        t = termination(sim)
        @test t.source === ModelRequestedStop(:tripped)
        @test t.t ≈ 0.315 atol = 1e-6                    # the analytic crossing, not a frame top
        @test t.t == sim.exec.clock.t                         # the frame's remainder was abandoned
        @test latest(sim).t === t.t
        @test logged(sim)[end] === latest(sim)           # the log's terminal endpoint is the t* boundary
    end

    @testset "stop_on binds per advance, like t_end (§13.5)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        run!(sim; stop_on = ("hit",), t_end = 1.0)
        @test termination(sim).source isa ModelRequestedStop
        init!(sim)
        run!(sim; t_end = 1.0)                           # no faces: this advance's default
        @test termination(sim).source === EndTimeReached() && termination(sim).t == 1.0
    end

    @testset "the record carries the terminating advance's policy (§13.5, D-255)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 1.0, stop_on = ("hit",))
        pol = termination(sim).policy
        @test pol.t_end == 1.0 && pol.faces == [:hit]    # the advance that ended the run
        # A `step!` that stops carries its own policy, which is where
        # `EndTimeReached`'s bound is read off now that no constructor holds one.
        init!(sim)
        @test step!(sim; frames = 10, t_end = 0.3) == 3
        @test termination(sim).source === EndTimeReached()
        @test termination(sim).policy.t_end == 0.3 && isempty(termination(sim).policy.faces)
    end

    @testset "an unbounded run raises the advisory into the loop's cell (§13.5, §11.8)" begin
        # `t_end = Inf` with no stop face is allowed and is the interactive shape:
        # nothing but a control-plane stop can end it, so the loop says so once
        # (D-255). The model stops itself from its own RHS, `:code` the issuer.
        c = HookedInterrupter()
        sim = Simulation(hooked_interrupted(c); h = 1//10)
        c.hook[] = () -> stop!(sim)
        init!(sim)
        run!(sim)
        @test termination(sim).source === ControlRequestedStop(:code)
        @test writer_status(latest(sim), "loop").totals.unbounded == 1

        # A bound of either kind is the advisory's absence.
        c2 = HookedInterrupter()
        bounded = Simulation(hooked_interrupted(c2); h = 1//10)
        c2.hook[] = () -> stop!(bounded)
        init!(bounded)
        run!(bounded; t_end = 5.0)
        @test writer_status(latest(bounded), "loop").totals.unbounded == 0

        # `step!` is bounded by its own count, so its defaults raise nothing.
        stepped = Simulation(monitored(); h = 1//10)
        init!(stepped)
        @test step!(stepped) == 1
        @test writer_status(latest(stepped), "loop").totals.unbounded == 0
    end

    @testset "step! advances whole frames and returns the count actually advanced (§12.6)" begin
        sim = Simulation(feedback_model(); h = 1//50)
        init!(sim, fragment(inputs = (ref = 0.0,)))
        @test step!(sim; t_end = 1.0) == 1               # the frames = 1 default
        @test step!(sim; frames = 4, t_end = 1.0) == 4
        @test step!(sim; t_plus = 0.5, t_end = 1.0) == 25   # the duration spelling
        @test lifecycle(sim) === :initialized            # between calls: ready to advance
        @test step!(sim; frames = 100, t_end = 1.0) == 20   # t_end truncates at frame 50
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === EndTimeReached()

        # A stepped trajectory is bit-identical to the same frames under run!.
        ref = Simulation(feedback_model(); h = 1//50)
        init!(ref, fragment(inputs = (ref = 0.0,)))
        run!(ref; t_end = 1.0)
        @test port(sim, "plant", :y) === port(ref, "plant", :y)
        @test state(sim, "plant").q === state(ref, "plant").q

        sim2 = Simulation(feedback_model(); h = 1//50)
        init!(sim2, fragment(inputs = (ref = 0.0,)))
        d1 = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(sim2; frames = 1, t_plus = 0.1))
        @test d1.call === :step! && d1.reason === :both_given
        d2 = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(sim2; frames = 0))
        @test d2.call === :step! && d2.argument === :frames && d2.value == 0
        d3 = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(sim2; t_plus = 0.0))
        @test d3.call === :step! && d3.argument === :t_plus && d3.value == 0.0
    end

    @testset "a stop face inside step! truncates it through the deviceless tail (§12.6, §13.5)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        # short of the trigger: an ordinary advance
        @test step!(sim; frames = 2, t_end = 5.0, stop_on = ("hit",)) == 2
        @test lifecycle(sim) === :initialized
        # the face holds at boundary 4
        @test step!(sim; frames = 10, t_end = 5.0, stop_on = ("hit",)) == 2
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ModelRequestedStop(:hit)
    end

    @testset "§13.6: a loop-side throw discards the failed boundary and promotes the last one" begin
        sim = Simulation(fed(Exploder(), "arm"); h = 1//10)
        probe = TailProbe()
        attach!(sim, probe, NoClaim())
        init!(sim, fragment(inputs = (in = 0.0,)))
        stage!(sim, "in" => true)                        # armed: frame 1's drain applies it,
        # frame 1's integration throws (§13.4's synchronous rethrow, after the tail)
        @test_throws StepError run!(sim; t_end = 5.0)
        @test lifecycle(sim) === :errored
        t = termination(sim)
        # the loop's one catch site wrapped it, and the cause is one level down
        @test t.source isa LoopError && t.source.exception isa StepError
        @test t.source.exception.cause isa Exploded
        # The failed boundary published nothing: boundary zero is the promoted
        # final snapshot, and the published record ends at it.
        @test t.t == 0.0 && latest(sim).t == 0.0
        @test [s.frame for s in logged(sim)] == [0]      # a post-mortem read, admitted (§13.6)
        @test probe.log == [:init, :shutdown]            # the device took the ordinary tail
        # The stores may hold mid-boundary values — retained for inspection,
        # readable, and worth nothing more than inspection.
        @test state(sim, "c").q isa Float64

        # Errored is terminal: never advanced, never re-initialized.
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} run!(sim; t_end = 5.0))
        @test d.status === :errored
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} step!(sim; t_end = 5.0))
        @test d.status === :errored
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} init!(sim))
        @test d.status === :errored && d.legal == [:built, :initialized, :stopped]
        # The roster operations refuse it too (D-232): they configure the next
        # run, and there is none. The post-mortem read above stays admitted.
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} attach!(sim, TailProbe(), NoClaim()))
        @test d.op === :attach! && d.status === :errored
        @test d.legal == [:built, :initialized, :stopped]   # §11.3, D-232: no next run
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} detach!(sim, probe))
        @test d.op === :detach! && d.status === :errored
    end

    @testset "a throw inside boundary zero returns a warm simulation to `built` (§12.6, D-223)" begin
        sim = Simulation(fed(Mine(), "sig"); h = 1//10)
        init!(sim, fragment(inputs = (in = false,)))
        @test step!(sim; frames = 2, t_end = 5.0) == 2
        @test latest(sim).t == 0.2

        # The re-`init!` throws at boundary zero: the word moves before the throw
        # leaves, so no advance runs on the half-transitioned stores.
        @test failure(() -> init!(sim, fragment(inputs = (in = true,)))) isa StepError
        @test lifecycle(sim) === :built
        d = carried(@test_throws DiagnosticError{MissingInit} step!(sim; t_end = 5.0))
        @test d.op === :step! && d.status === :built
        @test termination(sim) === nothing
        @test latest(sim).t == 0.2                       # the last published snapshot stands
        @test trace(sim).frames == 0                     # the trace is the failed init!'s

        init!(sim, fragment(inputs = (in = false,)))     # `built` is re-initializable
        @test lifecycle(sim) === :initialized
        @test step!(sim; t_end = 5.0) == 1
    end
end
