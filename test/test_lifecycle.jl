# --- run lifecycle and termination (§12.6, §13.5, §13.6; increment 16) ----------
# The five-state machine behind `lifecycle(sim)`, the stop policy each advance
# declares and binds, partial advance, the §13.5 termination record and
# §13.6's abnormal entry.

# A monitored ramp: the trigger fires at the first boundary whose sweep sees the
# ramp at its level, and the stop request publishes it from that boundary on —
# the boundary-detected request.
ramp_request(level, reason) =
    Group((; src = Ramp(0.0), trig = Trigger(level), stop = StopRequest(reason = reason));
          local_wires = ("src/out" => "trig/sig", "trig/on" => "stop/request"))
monitored() = ramp_request(0.35, "ramp at level")

# Two monitored ramps, `a` first in build order.
two_ramps(level_a, level_b) =
    Group((; a = ramp_request(level_a, "a at level"), b = ramp_request(level_b, "b at level")))
two_ramps_swapped(level_a, level_b) =
    Group((; b = ramp_request(level_b, "b at level"), a = ramp_request(level_a, "a at level")))

# Two requests on one component, both holding from boundary zero: one path
# owns two roster entries (§13.5, D-316).
struct TwoFlags <: AbstractComponent end
x_init(::TwoFlags) = (;)
y_types(::TwoFlags) = (fa = StopFlag, fb = StopFlag)
y_state(::TwoFlags, _) = (fa = STOP_REQUESTED, fb = STOP_REQUESTED)
stop_reason(::TwoFlags) = "two"

# A root-input-fed trigger feeding a stop request: the boundary-zero stop's model.
armed() = Group((; c = Trigger(0.5), stop = StopRequest(reason = "input at level"));
                input_wires = ("in" => "c/sig",), local_wires = ("c/on" => "stop/request",))

# The hooked interrupter beside a request that never holds: a requester
# honoured, or ignored, while only a control-plane stop can end the run.
hooked_requested(c) = Group((; run = hooked_interrupted(c), r = requested(false, "never")))

# The pendulum's torque held by a discrete integrator, and the condition D-273's
# probe authored: a sampled model, where a resume from the stores alone ran one
# tick ahead on the discrete tier.
resume_pend() = Group((; ctl = DiscreteAccumulator(1.0), c = Pendulum());
                      local_wires = ("ctl/u" => "c/u",), input_wires = ("in" => "ctl/e",))
resume_condition() = combine(at("ctl", fragment(s = (acc = 4.0,))),
                             at("c", condition(Pendulum(); θ = 0.2)),
                             fragment(u = (in = 0.5,)))

function test_lifecycle()
    @testset "the five states, and the gates between them (§12.6)" begin
        sim = Simulation(feedback_model(); h = 1//50)
        @test lifecycle(sim) === :built
        @test termination(sim) === nothing && !closed(sim.run)
        d = carried(@test_throws DiagnosticError{MissingInit} run!(sim; t_end = 1.0))
        @test d.op === :run! && d.status === :built
        d = carried(@test_throws DiagnosticError{MissingInit} step!(sim; t_end = 1.0))
        @test d.op === :step!

        init!(sim, fragment(u = (ref = 0.0,)))
        @test lifecycle(sim) === :initialized
        init!(sim, fragment(u = (ref = 0.0,)))  # a warm restart from initialized is legal
        run!(sim; t_end = 1.0)
        @test lifecycle(sim) === :stopped && closed(sim.run)
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} run!(sim; t_end = 1.0))
        @test d.op === :run! && d.status === :stopped
        @test d.legal == [:initialized]               # §12.6: the advance entries' one state
        d = carried(@test_throws DiagnosticError{ServiceLifecycle} step!(sim; t_end = 1.0))
        @test d.op === :step! && d.status === :stopped
        init!(sim, fragment(u = (ref = 0.0,)))  # the supported cycle reopens it
        @test lifecycle(sim) === :initialized
        @test termination(sim) === nothing && !closed(sim.run)   # a fresh run, not a cleared one
    end

    @testset "the placeholder run, and the object each door replaces (§12.6, D-255, D-261)" begin
        # Every accessor has a run to read before the first `init!`: the
        # placeholder carries an empty log, no trace, no feed and no
        # termination, and the lifecycle is what says it never started. The
        # origin, the policy and the mode are not fields of it (D-260), and
        # neither is any configuration (D-261).
        @test fieldnames(Run) === (:log, :trace, :feed, :termination)
        sim = Simulation(feedback_model(); h = 1//50)
        placeholder = sim.run
        @test mode(sim) === :live && placeholder.feed === nothing && !closed(placeholder)
        @test isempty(logged(sim)) && termination(sim) === nothing
        @test placeholder.trace === nothing
        d = carried(@test_throws DiagnosticError{MissingInit} trace(sim))
        @test d.op === :trace && d.status === :built

        # `init!` allocates a fresh run rather than clearing this one (§12.6), and
        # the loop's tail writes the termination onto the run it ran.
        init!(sim, fragment(u = (ref = 0.0,)))
        run = sim.run
        @test run !== placeholder && run.feed === nothing && !closed(run)
        run!(sim; t_end = 0.1)
        @test sim.run === run && closed(run)
        @test termination(sim) === run.termination

        # Recording is per run (D-261): the door's keyword configures the run it
        # builds and the next door may declare otherwise.
        init!(sim, fragment(u = (ref = 0.0,)); trace = false)
        @test sim.run.trace === nothing
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} trace(sim))
        @test d.call === :trace && d.reason === :disabled
        init!(sim, fragment(u = (ref = 0.0,)))
        @test sim.run.trace !== nothing && trace(sim).frames == 0
    end

    @testset "the freeze is the lifecycle's :running — init! and run! refuse it too (§12.6)" begin
        # Both ends of the run are test-controlled: the spin below waits for its
        # start, and the run cannot reach *its* end until the input arming its
        # stop request is staged,
        # so the mid-run probes race nothing — no frame count and no JIT warming
        # stand between them. `t_end` is a loud safety net rather than the run's
        # expected end — 30M frames, twenty times what the probes' own compilation
        # costs — and reaching it fails the source assertion instead of hanging.
        sim = Simulation(armed(); h = 1//100)
        total = fragment(u = (in = 0.0,))           # below the trigger: the run holds
        init!(sim, total)
        attach!(sim, TailProbe(), NoClaim())   # a rostered device makes the loop yield every
                                               # frame (§12.2), so the spin gets its turn on one thread
        task = Threads.@spawn run!(sim; t_end = 3.0e5)
        while lifecycle(sim) !== :running && !istaskdone(task)   # a missed start fails below, never hangs
            yield()
        end
        init_diagnostic = carried(@test_throws DiagnosticError{ServiceLifecycle} init!(
            sim, total))
        run_diagnostic = carried(@test_throws DiagnosticError{ServiceLifecycle} run!(sim; t_end = 2.0))
        stage!(sim, "in" => 1.0)                         # now, and only now, may the run end:
        wait(task)                                          # the next drain arms the trigger (§12.6)
        @test init_diagnostic.op === :init! &&
              init_diagnostic.status === :running
        @test run_diagnostic.op === :run! &&
              run_diagnostic.status === :running
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ModelRequestedStop("stop", :flag, "input at level")
    end

    @testset "t_end is the advance's own bound, validated per call (§13.5)" begin
        sim = Simulation(feedback_model(); h = 1//50)
        init!(sim, fragment(u = (ref = 0.0,)))
        run!(sim; t_end = 1.0)                           # this advance's bound
        record = termination(sim)
        @test record isa TerminationRecord{Float64}           # the deployment's own scalar (§9.4, D-203)
        @test record.source === EndTimeReached() && record.t == 1.0
        @test isempty(record.residue)                         # a quiet tail contributes no record
        @test sim.model.exec.clock.frame == 50

        # §12.4: the run ends at the first frame top reaching or exceeding
        # `t_end`, whole frames from `t₀` — an off-grid bound overshoots by
        # less than `h`, an offset origin counts from itself, a bound at or
        # before the origin advances nothing, and a large clock still lands a
        # grid-aligned bound on its own frame (`_frames_to`'s slack scales
        # with the larger magnitude of the time and the origin; `step!`'s
        # `t_plus` is the same rule)
        init!(sim, fragment(u = (ref = 0.0,)))
        run!(sim; t_end = 0.99)
        @test termination(sim).t == 1.0 && sim.model.exec.clock.frame == 50
        init!(sim, fragment(u = (ref = 0.0,)); t0 = 10.0)
        run!(sim; t_end = 12.0)
        @test termination(sim).t == 12.0 && sim.model.exec.clock.frame == 100
        init!(sim, fragment(u = (ref = 0.0,)); t0 = 10.0)
        run!(sim; t_end = 5.0)
        @test termination(sim).source === EndTimeReached() && sim.model.exec.clock.frame == 0
        late = Simulation(feedback_model(); h = 1//50)   # the advance below carries the bound:
                                                        # one before `t0` advances nothing
        init!(late, fragment(u = (ref = 0.0,)); t0 = 86400.0)
        @test step!(late; t_plus = 1.0) == 50
        run!(late; t_end = 86402.0)
        @test termination(late).t == 86402.0 && late.model.exec.clock.frame == 100

        # An origin far from zero and a bound near it: at `t0 = -0.3` the loop
        # writes frame 3's time as `-0.3 + 3 * 0.1`, about `5.6e-17`. That time
        # as the bound ends at frame 3, not 4; so does a `t_plus` of three steps,
        # and the next `t_plus` counts from that frame top.
        shifted = Simulation(feedback_model(); h = 1//10)
        init!(shifted, fragment(u = (ref = 0.0,)); t0 = -0.3)
        step!(shifted; frames = 3)
        t_three = shifted.model.exec.clock.t
        init!(shifted, fragment(u = (ref = 0.0,)); t0 = -0.3)
        run!(shifted; t_end = t_three)
        @test termination(shifted).t == t_three && shifted.model.exec.clock.frame == 3
        init!(shifted, fragment(u = (ref = 0.0,)); t0 = -0.3)
        @test step!(shifted; t_plus = 3 * shifted.model.deployment.h) == 3
        @test shifted.model.exec.clock.t == t_three
        @test step!(shifted; t_plus = 0.3) == 3
        # The same at a `Dual` activation, whose clock is a `Dual` (D-260).
        dual_sim = Simulation(feedback_model(), D8; h = 1//10)
        init!(dual_sim, fragment(u = (ref = D8(0.0),)); t0 = -0.3)
        @test step!(dual_sim; t_plus = 3 * dual_sim.model.deployment.h) == 3
        @test dual_sim.model.exec.clock.t isa D8
        @test step!(dual_sim; t_plus = 0.3) == 3

        # Both helpers against the grid the loop writes, `t₀ + k * h`: every
        # frame top resolves to its own frame, and every midpoint floors onto
        # its frame and ceils onto the next. The origins take both signs, and
        # `k` runs through zero's neighborhood where the origin is negative.
        grid = [(t₀, h, k) for h in (1e-3, 0.02, 0.1, 0.25, 1/3)
                for t₀ in (-86400.0, -1000.0, -3.0, -1.3, -0.7, -0.3, 0.0, 0.3, 1.3, 86400.0)
                for k in unique(vcat(0:100, max(0, round(Int, -t₀ / h)) .+ (-100:100))) if k ≥ 0]
        @test all(_frame_at(t₀ + k * h, t₀, h) == k for (t₀, h, k) in grid)
        @test all(_frames_to(t₀ + k * h, t₀, h) == k for (t₀, h, k) in grid)
        @test all(_frame_at(t₀ + (k + 0.5) * h, t₀, h) == k for (t₀, h, k) in grid)
        @test all(_frames_to(t₀ + (k + 0.5) * h, t₀, h) == k + 1 for (t₀, h, k) in grid)

        init!(sim, fragment(u = (ref = 0.0,)))
        run!(sim; t_end = 0.5)                           # this advance only
        @test termination(sim).t == 0.5
        init!(sim, fragment(u = (ref = 0.0,)))
        run!(sim; t_end = 1.0)                           # a different bound, no rebuild (§12.6)
        @test termination(sim).t == 1.0

        # `Inf` is the default and a value (Appendix B): an advance bounded by its
        # stop request alone, and one advance's `Inf` after another's finite bound.
        unbound = Simulation(monitored(); h = 1//10)
        init!(unbound)
        run!(unbound)
        @test termination(unbound).source === ModelRequestedStop("stop", :flag, "ramp at level")
        lifted = Simulation(monitored(); h = 1//10)
        init!(lifted)
        run!(lifted; t_end = 0.2)
        @test termination(lifted).source === EndTimeReached() && termination(lifted).t == 0.2
        init!(lifted)
        run!(lifted; t_end = Inf)
        @test termination(lifted).t == 4 * lifted.model.deployment.h
        unbound = Simulation(feedback_model(); h = 1//50)
        init!(unbound, fragment(u = (ref = 0.0,)))
        # The bound is validated identically at the three binding sites: the same
        # payload — argument, reason and offending value — with the naming call the
        # one field that differs (§13.5, D-255, D-249).
        run_diagnostic = carried(@test_throws DiagnosticError{ArgumentInvalid} run!(unbound; t_end = -1.0))
        replay_diagnostic = carried(@test_throws DiagnosticError{ArgumentInvalid} replay!(unbound, trace(unbound); t_end = -1.0))
        step_diagnostic = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(unbound; t_end = -1.0))
        @test run_diagnostic.argument == replay_diagnostic.argument ==
              step_diagnostic.argument == :t_end
        @test run_diagnostic.reason == replay_diagnostic.reason ==
              step_diagnostic.reason == :range
        @test run_diagnostic.value == replay_diagnostic.value ==
              step_diagnostic.value == -1.0
        @test run_diagnostic.call === :run! && replay_diagnostic.call === :replay! &&
              step_diagnostic.call === :step!
    end

    @testset "ignore_stop_requests names requester paths, validated at all three sites (§13.5, D-316)" begin
        sim = Simulation(two_ramps(0.15, 0.35); h = 1//10)
        init!(sim)
        trc = trace(sim)                            # the header alone: `replay!` binds as `run!` does
        given = ("a/stop", "nope")                  # one requester, one path naming none
        run_err = failure(() -> run!(sim; t_end = 1.0, ignore_stop_requests = given))
        replay_err = failure(() -> replay!(sim, trc; ignore_stop_requests = given))
        step_err = failure(() -> step!(sim; ignore_stop_requests = given))
        run_diagnostic, replay_diagnostic, step_diagnostic =
            only(diagnostics(run_err)), only(diagnostics(replay_err)), only(diagnostics(step_err))
        @test run_err isa DiagnosticError && run_diagnostic isa StopRequestInvalid
        # identical at all three sites: the path, and the roster's paths in roster order
        @test run_diagnostic.path == replay_diagnostic.path == step_diagnostic.path == "nope"
        @test run_diagnostic.candidates == replay_diagnostic.candidates ==
              step_diagnostic.candidates == ["a/stop", "b/stop"]
        # The binding site is the one payload field that differs (§13.5, D-249).
        @test run_diagnostic.site === :run! && replay_diagnostic.site === :replay! &&
              step_diagnostic.site === :step!
        # Collected over the given paths: an assembly's path names no requester.
        err = failure(() -> run!(sim; t_end = 1.0, ignore_stop_requests = ("nope", "a", "b/stop")))
        @test [d.path for d in diagnostics(err)] == ["nope", "a"]
        # One advance is one call, and the bound refuses first: `_t_bound` is
        # fail-fast and runs ahead of the paths, so a call naming both a bad bound
        # and a bad path is refused for the bound (§13.5, D-229).
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} run!(sim; t_end = -1.0,
                                                                       ignore_stop_requests = ("nope",)))
        @test d.argument === :t_end && d.call === :run!

        @test lifecycle(sim) === :initialized            # a rejected advance bound nothing
    end

    @testset "a request stops the run by default, and the record names the requester (§13.5, D-316)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 5.0)
        record = termination(sim)
        # kind + payload, one typed value (D-203)
        @test record.source === ModelRequestedStop("stop", :flag, "ramp at level")
        @test record.t == 4 * sim.model.deployment.h                # the sweep at boundary 4 saw 0.4 ≥ 0.35
        @test sim.model.exec.clock.frame == 4                       # the run ended there, not at t_end
        # that snapshot is the final one
        @test latest(sim).t === record.t
    end

    @testset "an authored condition already terminal ends the run at t₀, integrating nothing (§13.5)" begin
        sim = Simulation(armed(); h = 1//10)
        init!(sim, fragment(u = (in = 1.0,)))        # holds in the authored state:
        #                                                boundary zero derives the firing (§10.6)
        run!(sim; t_end = 5.0)
        record = termination(sim)
        @test record.source === ModelRequestedStop("stop", :flag, "input at level") && record.t == 0.0
        @test sim.model.exec.clock.frame == 0             # zero frames: the check precedes the first step
    end

    @testset "a localized stop ends the run at t*, the crossing state final (§13.5, §10.4)" begin
        sim = Simulation(overloaded(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 5.0)
        record = termination(sim)
        @test record.source === ModelRequestedStop("stop", :flag, "overload tripped")
        @test record.t ≈ 0.315 atol = 1e-6                    # the analytic crossing, not a frame top
        @test record.t == sim.model.exec.clock.t                         # the frame's remainder was abandoned
        @test latest(sim).t === record.t
        @test logged(sim)[end] === latest(sim)           # the log's terminal endpoint is the t* boundary
    end

    @testset "ignore_stop_requests binds per advance, like t_end (§13.5, D-316)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        run!(sim; ignore_stop_requests = ("stop",), t_end = 1.0)
        @test termination(sim).source === EndTimeReached() && termination(sim).t == 1.0
        init!(sim)
        run!(sim; t_end = 1.0)                           # every request honoured: the default
        @test termination(sim).source isa ModelRequestedStop
    end

    @testset "the override is per requester, or all (§13.5, D-316)" begin
        # `a` holds from boundary 2, `b` from boundary 4.
        sim = Simulation(two_ramps(0.15, 0.35); h = 1//10)
        init!(sim)
        run!(sim; t_end = 1.0)
        @test termination(sim).source === ModelRequestedStop("a/stop", :flag, "a at level")
        @test sim.model.exec.clock.frame == 2
        init!(sim)
        run!(sim; t_end = 1.0, ignore_stop_requests = ("a/stop",))
        @test termination(sim).source === ModelRequestedStop("b/stop", :flag, "b at level")
        @test sim.model.exec.clock.frame == 4
        # the ignored request is still a cell in the snapshot
        @test port(latest(sim), "a/stop", :flag) === STOP_REQUESTED
        init!(sim)
        run!(sim; t_end = 1.0, ignore_stop_requests = ("b/stop", "a/stop"))
        @test termination(sim).source === EndTimeReached() && termination(sim).t == 1.0
        @test termination(sim).policy.ignored == ["b/stop", "a/stop"]   # in the order given
        init!(sim)
        run!(sim; t_end = 1.0, ignore_stop_requests = :all)
        @test termination(sim).source === EndTimeReached() && termination(sim).t == 1.0
        @test termination(sim).policy.ignored == ["a/stop", "b/stop"]   # the roster, expanded
    end

    @testset "two requests at one boundary resolve to the first in build order (D-316)" begin
        sim = Simulation(two_ramps(0.35, 0.35); h = 1//10)
        init!(sim)
        run!(sim; t_end = 1.0)
        @test termination(sim).source === ModelRequestedStop("a/stop", :flag, "a at level")
        @test sim.model.exec.clock.frame == 4
        @test port(latest(sim), "b/stop", :flag) === STOP_REQUESTED     # both hold there
        # The declaration order swapped, the roster and the record follow it.
        swapped = Simulation(two_ramps_swapped(0.35, 0.35); h = 1//10)
        init!(swapped)
        run!(swapped; t_end = 1.0)
        @test [r.path for r in swapped.model.exec.act.layout.requesters] == ["b/stop", "a/stop"]
        @test termination(swapped).source === ModelRequestedStop("b/stop", :flag, "b at level")
        @test swapped.model.exec.clock.frame == 4
    end

    @testset "two requests on one component share its path, named once (§13.5, D-316)" begin
        sim = Simulation(Group((; tf = TwoFlags())); h = 1//10)
        init!(sim)
        run!(sim; t_end = 0.5, ignore_stop_requests = :all)
        @test termination(sim).source === EndTimeReached()
        @test termination(sim).policy.ignored == ["tf"]                 # the path once, not per port
        init!(sim)
        run!(sim; t_end = 0.5, ignore_stop_requests = ("tf",))
        @test termination(sim).source === EndTimeReached() && termination(sim).t == 0.5
        @test port(latest(sim), "tf", :fa) === STOP_REQUESTED &&
              port(latest(sim), "tf", :fb) === STOP_REQUESTED
        init!(sim)
        d = only(diagnostics(failure(() -> run!(sim; t_end = 0.5, ignore_stop_requests = ("nope",)))))
        @test d isa StopRequestInvalid && d.candidates == ["tf"]
        run!(sim; t_end = 0.5)                          # the first port in roster order names it
        @test termination(sim).source === ModelRequestedStop("tf", :fa, "two")
        @test termination(sim).t == 0.0
    end

    @testset "a tick-detected request stops at the tick's own boundary (§10.5, D-316)" begin
        # Ignored, the run shows where the detector first holds: the third tick
        # at `Relative(3)`, frame 9, with the request already publishing there.
        free = Simulation(tick_alarmed(); h = 1//10)
        init!(free)
        step!(free; frames = 12, ignore_stop_requests = :all)
        snapshots = logged(free)
        first_alarm = findfirst(snapshot -> port(snapshot, "counter", :alarm), snapshots)
        tick = snapshots[first_alarm]
        @test tick.frame == 9
        @test port(tick, "stop", :flag) === STOP_REQUESTED
        @test port(snapshots[first_alarm - 1], "stop", :flag) === NO_STOP
        # Honoured, the run ends at that boundary, not one later.
        sim = Simulation(tick_alarmed(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 5.0)
        record = termination(sim)
        @test record.source === ModelRequestedStop("stop", :flag, "three ticks counted")
        @test record.t === tick.t && sim.model.exec.clock.frame == 9
    end

    @testset "the record carries the terminating advance's policy (§13.5, D-255)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        run!(sim; t_end = 1.0, ignore_stop_requests = ("stop", "stop"))
        policy = termination(sim).policy
        # the advance that ended the run, its duplicates collapsed
        @test policy.t_end == 1.0 && policy.ignored == ["stop"]
        # A `step!` that stops carries its own policy, which is where
        # `EndTimeReached`'s bound is read off now that no constructor holds one.
        init!(sim)
        @test step!(sim; frames = 10, t_end = 0.3) == 3
        @test termination(sim).source === EndTimeReached()
        @test termination(sim).policy.t_end == 0.3 && isempty(termination(sim).policy.ignored)
    end

    @testset "an unbounded run raises the advisory into the loop's cell (§13.5, §11.8)" begin
        # `t_end = Inf` with no honoured stop request is allowed and is the
        # interactive shape: nothing but a control-plane stop can end it, so the
        # loop says so once (D-255, D-316). The model stops itself from its own
        # RHS, `:code` the issuer. This one has no requester.
        comp = HookedInterrupter()
        sim = Simulation(hooked_interrupted(comp); h = 1//10)
        comp.hook[] = () -> stop!(sim)
        init!(sim)
        run!(sim)
        @test termination(sim).source === ControlRequestedStop(:code)
        @test writer_status(latest(sim), "loop").totals.unbounded == 1
        advisory = only(d for snapshot in logged(sim)
                          for d in writer_status(snapshot, "loop").recent if d isa UnboundedRun)
        @test advisory.t_end == Inf && isempty(advisory.ignored)

        # A requester honoured bounds the run, though it never holds.
        comp_honoured = HookedInterrupter()
        honoured = Simulation(hooked_requested(comp_honoured); h = 1//10)
        comp_honoured.hook[] = () -> stop!(honoured)
        init!(honoured)
        run!(honoured)
        @test termination(honoured).source === ControlRequestedStop(:code)
        @test writer_status(latest(honoured), "loop").totals.unbounded == 0
        # Every requester ignored, the run is unbounded again, and the advisory
        # names what was ignored.
        comp_ignored = HookedInterrupter()
        all_ignored = Simulation(hooked_requested(comp_ignored); h = 1//10)
        comp_ignored.hook[] = () -> stop!(all_ignored)
        init!(all_ignored)
        run!(all_ignored; ignore_stop_requests = :all)
        @test writer_status(latest(all_ignored), "loop").totals.unbounded == 1
        advisory = only(d for snapshot in logged(all_ignored)
                          for d in writer_status(snapshot, "loop").recent if d isa UnboundedRun)
        @test advisory.t_end == Inf && advisory.ignored == ["r/stop"]

        # A bound of either kind is the advisory's absence.
        comp2 = HookedInterrupter()
        bounded = Simulation(hooked_interrupted(comp2); h = 1//10)
        comp2.hook[] = () -> stop!(bounded)
        init!(bounded)
        run!(bounded; t_end = 5.0)
        @test writer_status(latest(bounded), "loop").totals.unbounded == 0

        # `step!` is bounded by its own count, so its defaults raise nothing.
        stepped = Simulation(monitored(); h = 1//10)
        init!(stepped)
        @test step!(stepped) == 1
        @test writer_status(latest(stepped), "loop").totals.unbounded == 0
    end

    @testset "the thread-budget check reports below the roster plus one (§12.2)" begin
        # The thread count is the check's argument, so the test drives it below
        # the machine's count: one device and the loop need two threads.
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("p"), Enumerated())
        report_thread_budget!(sim.plane, sim.plane.roster, 1)
        @test only(_take!(sim.plane.loop_diag).ring) == ThreadBudget(1, 1)
        report_thread_budget!(sim.plane, sim.plane.roster, 2)
        @test _take!(sim.plane.loop_diag) === EMPTY_DIAG
        # A deviceless run occupies the loop's task alone, which any thread hosts.
        bare = Simulation(two_root_inputs(); h = 1//10)
        report_thread_budget!(bare.plane, bare.plane.roster, 1)
        @test _take!(bare.plane.loop_diag) === EMPTY_DIAG
    end

    @testset "a run checks once, at its top, and the delta rides the first frame's snapshot (§12.2, §11.8)" begin
        # One claimless probe per thread makes the run tight on every layout:
        # the roster and the loop need one thread more than the machine has.
        sim = Simulation(two_root_inputs(); h = 1//10)
        for _ in 1:Threads.nthreads()
            attach!(sim, TailProbe(), NoClaim())
        end
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 0.5)
        records = [writer_status(snapshot, "loop") for snapshot in logged(sim)[2:end]]
        @test length(records) == 5                   # frames 1..5 after boundary zero
        @test all(record.totals.thread_budget == 1 for record in records)
        @test [length(record.recent) for record in records] == [1, 0, 0, 0, 0]
        @test only(records[1].recent) == ThreadBudget(Threads.nthreads(), Threads.nthreads())
    end

    @testset "a deviceless run never warns of the thread budget (§12.2)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 0.3)
        @test writer_status(latest(sim), "loop").totals.thread_budget == 0
    end

    @testset "step! advances whole frames and returns the count actually advanced (§12.6)" begin
        sim = Simulation(feedback_model(); h = 1//50)
        init!(sim, fragment(u = (ref = 0.0,)))
        @test step!(sim; t_end = 1.0) == 1               # the frames = 1 default
        @test step!(sim; frames = 4, t_end = 1.0) == 4
        @test step!(sim; t_plus = 0.5, t_end = 1.0) == 25   # the duration spelling
        @test lifecycle(sim) === :initialized            # between calls: ready to advance
        @test step!(sim; frames = 100, t_end = 1.0) == 20   # t_end truncates at frame 50
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === EndTimeReached()

        # A stepped trajectory is bit-identical to the same frames under run!.
        reference = Simulation(feedback_model(); h = 1//50)
        init!(reference, fragment(u = (ref = 0.0,)))
        run!(reference; t_end = 1.0)
        @test port(sim, "plant", :y) === port(reference, "plant", :y)
        @test state(sim, "plant").q === state(reference, "plant").q

        sim2 = Simulation(feedback_model(); h = 1//50)
        init!(sim2, fragment(u = (ref = 0.0,)))
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(sim2; frames = 1, t_plus = 0.1))
        @test d.call === :step! && d.reason === :both_given
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(sim2; frames = 0))
        @test d.call === :step! && d.argument === :frames && d.value == 0
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(sim2; t_plus = 0.0))
        @test d.call === :step! && d.argument === :t_plus && d.value == 0.0
        # `step!` reads its own keywords before the policy, as `replay!` does: a
        # call naming both a bad pair and a bad path is refused for the pair.
        d = carried(@test_throws DiagnosticError{ArgumentInvalid} step!(
            sim2; frames = 1, t_plus = 0.1, ignore_stop_requests = ("nope",)))
        @test d.call === :step! && d.reason === :both_given
    end

    @testset "a stop request inside step! truncates it through the deviceless tail (§12.6, §13.5)" begin
        sim = Simulation(monitored(); h = 1//10)
        init!(sim)
        # short of the trigger: an ordinary advance
        @test step!(sim; frames = 2, t_end = 5.0) == 2
        @test lifecycle(sim) === :initialized
        # the request holds at boundary 4
        @test step!(sim; frames = 10, t_end = 5.0) == 2
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ModelRequestedStop("stop", :flag, "ramp at level")
    end

    @testset "§13.6: a loop-side throw discards the failed boundary and promotes the last one" begin
        sim = Simulation(fed(Exploder(), "arm"); h = 1//10)
        probe = TailProbe()
        attach!(sim, probe, NoClaim())
        init!(sim, fragment(u = (in = 0.0,)))
        stage!(sim, "in" => true)                        # armed: frame 1's drain applies it,
        # frame 1's integration throws; the rostered probe makes the session
        # interactive, so `run!` logs the rendered error and returns (§13.4, D-268)
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 5.0)
        end
        @test count(l -> l.level == Base.CoreLogging.Error, logs) == 1
        @test lifecycle(sim) === :errored && closed(sim.run)
        record = termination(sim)
        # the loop's one catch site wrapped it, and the cause is one level down
        @test record.source isa LoopError && record.source.exception isa StepError
        @test record.source.exception.cause isa Exploded
        # The failed boundary published nothing: boundary zero is the promoted
        # final snapshot, and the published record ends at it.
        @test record.t == 0.0 && latest(sim).t == 0.0
        @test [snapshot.frame for snapshot in logged(sim)] ==
              [0]      # a post-mortem read, admitted (§13.6)
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

    @testset "run! reads §13.4's disposition off the roster, and step! always rethrows (§13.4, D-268)" begin
        # Interactive: a rostered device, spawned beside the loop on the
        # calling task (§11.1).
        for dev in (TailProbe(), Pad("p"))
            sim = Simulation(fed(Exploder(), "arm"); h = 1//10)
            attach!(sim, dev, NoClaim())
            init!(sim, fragment(u = (in = false,)))
            stage!(sim, "in" => true)                    # armed: frame 1 throws
            logs, _ = Test.collect_test_logs() do
                run!(sim; t_end = 5.0)                   # logged, and returned
            end
            @test lifecycle(sim) === :errored
            source = termination(sim).source
            @test source isa LoopError && source.exception isa StepError{Exploded}
            @test count(l -> l.level == Base.CoreLogging.Error, logs) == 1
        end
        # Unattended: nothing rostered, so the failure reaches the caller and CI
        # fails honestly.
        sim = Simulation(fed(Exploder(), "arm"); h = 1//10)
        init!(sim, fragment(u = (in = false,)))
        stage!(sim, "in" => true)
        @test_throws StepError{Exploded} run!(sim; t_end = 5.0)
        @test lifecycle(sim) === :errored
        # `step!` is deviceless by construction, a rostered device or not (§12.6).
        stepped = Simulation(fed(Exploder(), "arm"); h = 1//10)
        attach!(stepped, TailProbe(), NoClaim())
        init!(stepped, fragment(u = (in = false,)))
        stage!(stepped, "in" => true)
        @test_throws StepError{Exploded} step!(stepped; t_end = 5.0)
        @test lifecycle(stepped) === :errored
    end

    @testset "replay! reads §13.4's disposition off the roster as run! does (§13.4, §12.7, D-268)" begin
        # The recording: frame 1's drain applies the armed batch, and the frame throws.
        recorded = Simulation(fed(Exploder(), "arm"); h = 1//10)
        init!(recorded, fragment(u = (in = false,)))
        stage!(recorded, "in" => true)
        @test_throws StepError{Exploded} run!(recorded; t_end = 5.0)
        recording = trace(recorded)                      # a copy, the failed frame's batch in it
        # Interactive: a rostered reader makes the replay's failure logged, and returned.
        sim = Simulation(fed(Exploder(), "arm"); h = 1//10)
        attach!(sim, TailProbe(), NoClaim())
        logs, _ = Test.collect_test_logs() do
            replay!(sim, recording)
        end
        @test lifecycle(sim) === :errored
        source = termination(sim).source
        @test source isa LoopError && source.exception isa StepError{Exploded}
        @test count(l -> l.level == Base.CoreLogging.Error, logs) == 1
        # Unattended: the deviceless reproduction still reaches the caller.
        unattended = Simulation(fed(Exploder(), "arm"); h = 1//10)
        @test_throws StepError{Exploded} replay!(unattended, recording)
        @test lifecycle(unattended) === :errored
    end

    @testset "the resume identity: `restore!` continues a sampled trajectory bitwise (§12.6, D-274)" begin
        sim = Simulation(resume_pend(); h = 1//10)
        init!(sim, resume_condition())
        step!(sim; frames = 3)
        # at rest the store holds the state the next tick decodes, the cell the
        # sample the last tick published (D-273)
        @test port(sim, "ctl", :u) ≈ 4.15 && state(sim, "ctl").acc ≈ 4.20
        cp = checkpoint(sim)

        twin = Simulation(resume_pend(); h = 1//10)
        restore!(twin, cp)
        run!(sim; t_end = 0.6)
        run!(twin; t_end = 0.6)
        @test termination(twin).t === termination(sim).t && termination(sim).t ≈ 0.6
        @test state(twin, "c") === state(sim, "c") && state(twin, "ctl") === state(sim, "ctl")
        @test snap_cells(latest(twin)) == snap_cells(latest(sim))
        # the logged trajectory from 0.3, ordinals included
        from_checkpoint = [x for x in logged(sim) if x.boundary ≥ cp.boundary - 1]
        @test same_trajectory(logged(twin), from_checkpoint)
        @test [x.boundary for x in logged(twin)] == [x.boundary for x in from_checkpoint]
        @test port(sim, "ctl", :u) ≈ 4.30 && port(twin, "ctl", :u) === port(sim, "ctl", :u)
    end

    @testset "a throw inside boundary zero returns a warm simulation to `built` (§12.6, D-223)" begin
        sim = Simulation(fed(Mine(), "sig"); h = 1//10)
        init!(sim, fragment(u = (in = false,)))
        @test step!(sim; frames = 2, t_end = 5.0) == 2
        @test latest(sim).t == 0.2

        # The re-`init!` throws at boundary zero: the word moves before the throw
        # leaves, so no advance runs on the half-transitioned stores.
        @test failure(() -> init!(sim, fragment(u = (in = true,)))) isa StepError
        @test lifecycle(sim) === :built
        d = carried(@test_throws DiagnosticError{MissingInit} step!(sim; t_end = 5.0))
        @test d.op === :step! && d.status === :built
        @test termination(sim) === nothing
        @test latest(sim).t == 0.2                       # the last published snapshot stands
        # the header is taken after boundary zero publishes, so the throw left none
        d = carried(@test_throws DiagnosticError{MissingInit} trace(sim))
        @test d.op === :trace && d.status === :built

        init!(sim, fragment(u = (in = false,)))     # `built` is re-initializable
        @test lifecycle(sim) === :initialized
        @test step!(sim; t_end = 5.0) == 1
    end
end
