# --- the device contract and its tasks (§11.6, §11.1, §12.4; increment 12) ------
# The handle, the wrapper, the pre-spawn bracket and the tail. Every device
# below lives at top level for `implementation.md`'s local-scope reason, and every
# timing-sensitive assertion is a property check with generous slack, never a
# tight wall-clock equality: single-threaded schedulers must pass.

# A one-shot input device: stages once through its handle, requests the stop,
# and records the contract calls in order on whatever task runs them.
mutable struct OneShot <: AbstractDevice
    v::Float64
    fired::Bool
    log::Vector{Symbol}
end
OneShot(v) = OneShot(v, false, Symbol[])
init!(dev::OneShot) = (push!(dev.log, :init); nothing)
shutdown!(dev::OneShot) = (push!(dev.log, :shutdown); nothing)
function loop(dev::OneShot, handle)
    dev.fired && return nothing
    dev.fired = true
    push!(dev.log, :loop)
    stage!(handle, "a" => dev.v)
    stop!(handle)
    nothing
end

# A boundary-driven consumer: the §12.3 wait as its whole wait structure.
mutable struct Collector <: AbstractDevice
    seen::Vector{Tuple{Float64,Int}}    # (t, boundary ordinal) per observed snapshot
    log::Vector{Symbol}
end
Collector() = Collector(Tuple{Float64,Int}[], Symbol[])
function loop(dev::Collector, handle)
    while true
        # returns on publication or on the stop wake
        snapshot = wait_next_snapshot(handle)
        snapshot === nothing || push!(dev.seen, (Float64(snapshot.t), snapshot.boundary))
        running(handle) || break                  # record first: the stop wake carries the final world
    end
    push!(dev.log, :returned)
    nothing
end

# A crasher: the wrapper's catch path, with shutdown! still guaranteed.
mutable struct Crasher <: AbstractDevice
    log::Vector{Symbol}
end
Crasher() = Crasher(Symbol[])
shutdown!(dev::Crasher) = (push!(dev.log, :shutdown); nothing)
loop(dev::Crasher, handle) = (push!(dev.log, :loop); error("boom"))

# A failed acquisition: the §12.4 initialization bracket's customer.
mutable struct BadInit <: AbstractDevice
    log::Vector{Symbol}
end
BadInit() = BadInit(Symbol[])
init!(dev::BadInit) = (push!(dev.log, :init); error("no hardware"))
shutdown!(dev::BadInit) = (push!(dev.log, :shutdown); nothing)
loop(dev::BadInit, handle) = (push!(dev.log, :loop); nothing)

# The taught obligation violated: no running check, a blocking call with no
# unblock! override — the join-timeout path's customer.
mutable struct Stubborn <: AbstractDevice
    log::Vector{Symbol}
end
Stubborn() = Stubborn(Symbol[])
shutdown!(dev::Stubborn) = (push!(dev.log, :shutdown); nothing)
loop(dev::Stubborn, handle) = (sleep(0.8); push!(dev.log, :woke); nothing)

# The obligation met: a blocking wait made interruptible by unblock! (§12.4(3)).
mutable struct Blocked <: AbstractDevice
    ch::Channel{Int}
    log::Vector{Symbol}
end
Blocked() = Blocked(Channel{Int}(1), Symbol[])
unblock!(dev::Blocked) = (close(dev.ch); nothing)
shutdown!(dev::Blocked) = (push!(dev.log, :shutdown); nothing)
function loop(dev::Blocked, handle)
    while running(handle)
        try
            take!(dev.ch)                       # blocks; unblock! closes → raises here
        catch
            break                             # the raise is shutdown, not a crash
        end
    end
    nothing
end

# The same obligation met with no catch of its own: the raise unblock! provokes
# leaves the body, and the wrapper files it as shutdown, not a crash (§12.4(3)).
mutable struct Raising <: AbstractDevice
    ch::Channel{Int}
    log::Vector{Symbol}
end
Raising() = Raising(Channel{Int}(1), Symbol[])
unblock!(dev::Raising) = (close(dev.ch); nothing)
shutdown!(dev::Raising) = (push!(dev.log, :shutdown); nothing)
function loop(dev::Raising, handle)
    while running(handle)
        take!(dev.ch)                           # blocks; unblock! closes → raises out of the body
    end
    nothing
end

# The operator's Ctrl-C landing inside a loop body: the wrapper's one
# discrimination (§11.6, D-132) — a stop forwarded, never a crash.
mutable struct Interrupting <: AbstractDevice
    log::Vector{Symbol}
end
Interrupting() = Interrupting(Symbol[])
shutdown!(dev::Interrupting) = (push!(dev.log, :shutdown); nothing)
loop(dev::Interrupting, handle) = (push!(dev.log, :loop); throw(InterruptException()))

# A calling-task device: records which task ran its body (§11.1's pinning),
# polling between running checks and never blocking across them (§12.4).
mutable struct Inline <: AbstractDevice
    task::Union{Nothing,Task}
    log::Vector{Symbol}
end
Inline() = Inline(nothing, Symbol[])
needs_calling_task(::Inline) = true
function loop(dev::Inline, handle)
    dev.task = current_task()
    while running(handle)
        sleep(0.001)
    end
    push!(dev.log, :returned)
    nothing
end

# A device with no loop method at all: the error-throwing fallback's customer.
mutable struct Loopless <: AbstractDevice end
mutable struct NarrowLoop <: AbstractDevice end   # `loop` on the handle type itself
loop(::NarrowLoop, ::DeviceHandle) = nothing

function test_devices()
    @testset "a device stages through its handle from its own task, and departure consults should_abort (§11.6, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = OneShot(0.7)
        handle = attach!(sim, dev, Enumerated("a"); should_abort = true)
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 1000.0)                        # ends by the device's stop, not t_end
        @test sim.exec.clock.step < 10000             # the stop truncated the run
        @test dev.log[1:3] == [:init, :loop, :shutdown]
        # the sticky status, read off the handle
        @test !running(handle)
        # The record names the channel and its issuer (§13.5, D-203): the stop
        # rode the departing device's should_abort, so the device is the issuer.
        @test termination(sim).source === ControlRequestedStop("device 1 (OneShot)")
        # The staged batch was applied by a drain the stop did not beat, or still
        # pends in the cell — exactly one of the two, timing's choice — and init!
        # clears whatever pends with the trajectory it predates (§12.6).
        @test (port(sim, "", :a) === 0.7) ⊻
              ((@atomic handle.writer.cell.pending) !== nothing)
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        @test (@atomic handle.writer.cell.pending) === nothing
    end

    @testset "wait_next_snapshot observes ordered boundaries and wakes on the stop (§12.3, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Collector()
        attach!(sim, dev, Enumerated())          # the may-write-nothing degenerate: a pure reader
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 1.0)
        @test dev.log == [:returned]             # exited through the woken wait, before the join
        @test !isempty(dev.seen)                 # at least one boundary observed in ten frames
        @test issorted([b for (_, b) in dev.seen])       # never a stale wake: newest-wins only
        @test issorted([t for (t, _) in dev.seen])
        # While stopped the wait returns at once instead of parking (§12.3's
        # predicate routes on the sticky status): re-read through the handle.
        snapshot = wait_next_snapshot(sim.plane.roster[1].handle)
        @test snapshot === latest(sim)
    end

    @testset "the boundary ordinal rides in the snapshot (§12.3)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))  # boundary zero: ordinal 0
        run!(sim; t_end = 0.5)
        @test latest(sim).boundary == 5
        @test latest(sim).t ≈ 0.5
        @test logged(sim)[1].boundary == 0

        # A second trajectory restarts the ordinal at boundary zero (D-230); the
        # §12.3 wait counter keeps counting across it, never re-armed.
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        @test latest(sim).boundary == 0
        run!(sim; t_end = 0.5)
        @test latest(sim).boundary == 5
        @test logged(sim)[1].boundary == 0
        @test sim.control.counter == 12
    end

    @testset "stop! from any task ends the run at a frame top (§12.1, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("p"), Enumerated("a"))  # a rostered device keeps the loop yielding (§12.2)
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        stopper = Threads.@spawn (sleep(0.05); stop!(sim))
        run!(sim; t_end = 1.0e6)
        wait(stopper)
        @test sim.exec.clock.step < 10^7              # truncated, and stopped is sticky:
        @test !running(sim.plane.roster[1].handle)
        # One channel, and the record names who spoke (§13.5, D-203): stop!(sim)
        # is calling code from any task, issuer :code.
        @test termination(sim).source === ControlRequestedStop(:code)
        # A fresh trajectory owes nothing to this stop: init! clears the word.
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        @test step!(sim; frames = 3) == 3
        @test sim.exec.clock.step == 3
    end

    @testset "a crash is caught, shutdown! runs, the run continues, claims persist (§12.4(6))" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Crasher()
        attach!(sim, dev, Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 0.5)
        end
        @test sim.exec.clock.step == 5                # the run reached t_end regardless
        @test dev.log == [:loop, :shutdown]      # the bracket held on the crash path
        @test crash_accounted(sim, logs, "device 1 (Crasher)")
        # Death is not detach: the claim stands, and the harness cannot take the face.
        stage!(sim, "a" => 9.0)
        entry = only((@atomic sim.plane.harness_diag.batch).ring)
        @test entry isa ClaimedFaceEntry && entry.incumbent == "device 1 (Crasher)"
    end

    @testset "a crash under should_abort requests the stop (§12.4(6))" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Crasher(), Enumerated("a"); should_abort = true)
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1000.0)
        end
        @test sim.exec.clock.step < 10000             # ended by the crash's stop, not t_end
        @test crash_accounted(sim, logs, "device 1 (Crasher)")
    end

    @testset "a failed init! is bracketed: shutdown!, no task, claims persist (§12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = BadInit()
        attach!(sim, dev, Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 0.5)
        @test dev.log == [:init, :shutdown]      # loop never ran: no task was spawned
        @test sim.exec.clock.step == 5                # flag clear: the run proceeds without it
        # The report was written pre-spawn, addressed by the entry (§12.4), so it
        # deterministically makes the first frame top's fold: the first frame's
        # snapshot carries the delta, the terminal status the totals.
        status = writer_status(latest(sim), "device 1 (BadInit)")
        @test status.totals.crash == 1
        crash = only(writer_status(logged(sim)[2], "device 1 (BadInit)").recent)
        @test crash isa DeviceCrash && crash.cause isa ErrorException &&
              crash.abort === false
        # Dead from boundary zero, with no marking machinery (§12.4): the cell was
        # never heartbeated — stale against any clock — and no task ever existed.
        @test stale(status) && status.task_state === :none
        stage!(sim, "a" => 9.0)                  # claims persist: death is not detach
        @test only((@atomic sim.plane.harness_diag.batch).ring) isa ClaimedFaceEntry
        # With should_abort set the stop is already pending at the loop's start:
        # the run advances zero frames and ends through the same tail — no frame
        # top ever folds the report, so only the run's-end sweep can present it.
        sim2 = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim2, BadInit(), Enumerated("a"); should_abort = true)
        init!(sim2, fragment(inputs = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim2; t_end = 0.5)
        end
        @test sim2.exec.clock.step == 0
        @test any(occursin("DeviceCrash from device 1 (BadInit), past the final", string(l.message))
                  for l in logs)
        # The same crash is recorded, not just presented (D-203): the residue
        # carries the device's record, and the abort's stop names it as issuer.
        record = termination(sim2)
        @test record.source === ControlRequestedStop("device 1 (BadInit)")
        writer_residue = only(residue for residue in record.residue
                              if residue.writer == "device 1 (BadInit)")
        @test only(writer_residue.recent) isa DeviceCrash
    end

    @testset "a body ignoring the predicate is abandoned under join_timeout, by name (§12.4(5))" begin
        sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = 0.2)
        dev = Stubborn()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        t0 = time()
        # The abandonment is written to the loop's own cell and presented by the
        # run's-end sweep, the record's renderer (§12.4(5), D-203).
        @test_logs (:warn, r"DeviceJoinTimeout from loop, past the final snapshot's account:.*Stubborn") #=
            =# match_mode=:any run!(sim; t_end = 0.3)
        @test time() - t0 < 0.6                  # abandoned at ~0.2 s, not the sleep's 0.8 s
        @test :woke ∉ dev.log                    # the straggler had not returned when run! did
        # Recorded, not just loud (D-203): the termination record's residue holds
        # the structured kind, by name, with the cap and the final boundary.
        writer_residue = only(residue for residue in termination(sim).residue
                              if residue.writer == "loop")
        timeout = only(d for d in writer_residue.recent if d isa DeviceJoinTimeout)
        @test timeout.who == "device 1 (Stubborn)" && timeout.timeout == 0.2
        @test timeout.t == termination(sim).t ≈ 0.3 &&
              timeout.boundary == latest(sim).boundary
        # Abandonment is not a kill: let the straggler expire inside this testset —
        # its wrapper still runs shutdown! — rather than leave it parked in the
        # timer wheel across process teardown.
        sleep(1.0)
        @test dev.log == [:woke, :shutdown]
    end

    @testset "unblock! makes the blocking call return: a clean exit, no timeout (§12.4(3))" begin
        sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = 2.0)
        dev = Blocked()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        t0 = time()
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 0.3)
        end
        @test time() - t0 < 1.5                  # joined promptly, well inside the cap
        @test !any(occursin("DeviceJoinTimeout", string(l.message)) for l in logs)
        @test isempty(termination(sim).residue)  # nothing landed past the account (D-203)
        @test dev.log == [:shutdown]
    end

    @testset "the raise unblock! provokes is shutdown, not a crash (§12.4(3))" begin
        sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = 2.0)
        dev = Raising()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 0.3)
        end
        @test !any(occursin("DeviceCrash", string(l.message)) for l in logs)
        @test isempty(termination(sim).residue)
        @test writer_status(latest(sim), "device 1 (Raising)").totals.crash == 0
        @test dev.log == [:shutdown]
    end

    @testset "an interrupt leaving a loop body is a stop, never a crash (§11.6, D-132)" begin
        sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = 2.0)
        dev = Interrupting()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1000.0)
        end
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:interrupt)
        @test sim.exec.clock.step < 10000        # ended by the forwarded stop, not t_end
        @test writer_status(latest(sim), "device 1 (Interrupting)").totals.crash == 0
        @test !any(occursin("DeviceCrash", string(l.message)) for l in logs)
        @test isempty(termination(sim).residue)
        @test dev.log == [:loop, :shutdown]      # shutdown! on this exit path too
        # No should_abort consultation: the interrupt already holds the stop word,
        # and the abort's later request loses the first-writer CAS (§11.6).
        sim2 = Simulation(two_root_inputs(); h = 1//10, join_timeout = 2.0)
        attach!(sim2, Interrupting(), Enumerated(); should_abort = true)
        init!(sim2, fragment(inputs = (a = 0.0, b = 0.0)))
        run!(sim2; t_end = 1000.0)
        @test termination(sim2).source === ControlRequestedStop(:interrupt)
    end

    @testset "a calling-task device runs inline and the loop moves, trajectory untouched (§11.1)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Inline()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        caller = current_task()
        run!(sim; t_end = 0.5)
        @test dev.task === caller                # the pinning: the body ran on run!'s task
        @test dev.log == [:returned]             # and left through the ordinary predicate
        @test sim.exec.clock.step == 5
        # the movable loop moved nothing else
        reference = Simulation(two_root_inputs(); h = 1//10)
        init!(reference, fragment(inputs = (a = 0.0, b = 0.0)))
        run!(reference; t_end = 0.5)
        @test port(sim, "s", :e) === port(reference, "s", :e)
    end

    @testset "a device with no loop method is refused at attach!, by kind (§11.6)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        d = carried(@test_throws DiagnosticError{DeviceContractMismatch} attach!(sim, Loopless(), Enumerated()))
        @test d.reason === :no_loop && d.device == "Loopless"
        @test isempty(sim.plane.roster)               # the rejection consumed no id
        # a `loop` declared on `DeviceHandle` itself is the method the wrapper calls
        @test attach!(sim, NarrowLoop(), Enumerated()) isa DeviceHandle
    end

    @testset "gather without an output side is a contract misuse, by kind (§11.6)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        handle = attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        d = carried(@test_throws DiagnosticError{DeviceContractMismatch} gather(handle, latest(sim)))
        @test d.reason === :no_output_side && d.device == "device 1 (Pad)"
    end

    @testset "a detached handle's writes refuse by name, its reads stay legal (§11.6, D-244)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Pad("p")
        handle = attach!(sim, dev, Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        stage!(handle, "a" => 1.0)                    # attached: the ordinary path
        detach!(sim, dev)
        d = carried(@test_throws DiagnosticError{DeviceContractMismatch} stage!(handle, "a" => 2.0))
        @test d.reason === :detached && d.device == "device 1 (Pad)"
        d = carried(@test_throws DiagnosticError{DeviceContractMismatch} report!(handle, MalformedDatum(ErrorException("x"))))
        @test d.reason === :detached
        @test occursin("was detached", logline(d))
        @test latest(handle) === latest(sim)          # the reads touch shared state alone
        @test running(handle) === false
        # A fresh attachment is a fresh handle; the retired one stays refused.
        handle2 = attach!(sim, dev, Enumerated("a"))
        @test handle2 !== handle
        stage!(handle2, "a" => 3.0)
        @test_throws DiagnosticError{DeviceContractMismatch} stage!(handle, "a" => 4.0)
    end

    @testset "join_timeout is validated and never trajectory-determining (§12.4, D-198)" begin
        # It is a keyword of the materialization, not a deployment parameter, so it
        # is an `ArgumentInvalid` (D-256).
        err = failure(() -> Simulation(two_root_inputs(); h = 1//10, join_timeout = 0))
        d = only(diagnostics(err))
        @test err isa DiagnosticError && d isa ArgumentInvalid && d.call === :Simulation
        @test d.argument === :join_timeout && d.reason === :range
        err = failure(() -> Simulation(two_root_inputs(); h = 1//10, join_timeout = "5"))
        d = only(diagnostics(err))
        @test err isa DiagnosticError && d isa ArgumentInvalid && d.argument === :join_timeout
        trajectories = map((5.0, 0.01)) do cap
            sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = cap)
            attach!(sim, Pad("p"), Enumerated("a"))
            init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
            run!(sim; t_end = 0.5)
            port(sim, "s", :e)
        end
        @test trajectories[1] === trajectories[2]
    end
end
