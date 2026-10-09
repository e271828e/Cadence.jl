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

# The operator's Ctrl-C landing inside init!: the bracket's discrimination
# (§12.4, D-268) — a stop, never a crash.
mutable struct InitInterrupted <: AbstractDevice
    log::Vector{Symbol}
end
InitInterrupted() = InitInterrupted(Symbol[])
init!(dev::InitInterrupted) = (push!(dev.log, :init); throw(InterruptException()))
shutdown!(dev::InitInterrupted) = (push!(dev.log, :shutdown); nothing)
loop(dev::InitInterrupted, handle) = (push!(dev.log, :loop); nothing)

# A device whose `init!` parks on a hook until an interrupt cuts it short, its
# calls counted, so the test can land one interrupt inside the bracket and a
# second escaping it (§11.6, §12.4). Clearing `hold` under the hook's lock and
# notifying frees the caller when a regression leaves it parked.
mutable struct HookedInit <: AbstractDevice
    hook::Threads.Condition
    hold::Bool
    inits::Int
    shutdowns::Int
end
HookedInit() = HookedInit(Threads.Condition(), true, 0, 0)
function init!(dev::HookedInit)
    dev.inits += 1
    lock(dev.hook)
    try
        dev.hold && wait(dev.hook)
    finally
        unlock(dev.hook)
    end
    nothing
end
shutdown!(dev::HookedInit) = (dev.shutdowns += 1; nothing)
loop(dev::HookedInit, handle) = nothing

# A body ignoring the predicate, blocked until the test releases it, whose
# unblock! hangs on a condition the test holds: the tail parks the calling task
# there, where the operator's second interrupt finds it (§12.4, D-268).
mutable struct Wedged <: AbstractDevice
    release::Channel{Int}
    hook::Threads.Condition
    task::Union{Nothing,Task}
    log::Vector{Symbol}
end
Wedged() = Wedged(Channel{Int}(1), Threads.Condition(), nothing, Symbol[])
shutdown!(dev::Wedged) = (push!(dev.log, :shutdown); nothing)
function loop(dev::Wedged, handle)
    dev.task = current_task()
    take!(dev.release)
    push!(dev.log, :released)
    nothing
end
unblock!(dev::Wedged) = (lock(dev.hook); try wait(dev.hook) finally unlock(dev.hook) end; nothing)

# `Exploder`'s throw held at a gate: from `t = 0.2` on, past the build's probe
# and boundary zero, the evaluation marks `armed`, waits for the observer's
# `go`, then throws, so the observer picks what the calling task meets on the
# failing frame's way out (§12.4, §13.6).
struct GatedExploder <: AbstractComponent
    armed::Threads.Atomic{Bool}
    go::Channel{Nothing}
end
GatedExploder() = GatedExploder(Threads.Atomic{Bool}(false), Channel{Nothing}(1))
x_init(::GatedExploder) = (q = 0.0,)
y_types(::GatedExploder) = (q = Float64,)
y_state(::GatedExploder, (; x)) = (q = x.q,)
function x_deriv(c::GatedExploder, (; x, t))
    t ≥ 0.2 || return (q = one(x.q),)
    c.armed[] = true
    take!(c.go)
    throw(Exploded())
end

# A device with no loop method at all: the error-throwing fallback's customer.
mutable struct Loopless <: AbstractDevice end
mutable struct NarrowLoop <: AbstractDevice end   # `loop` on the handle type itself
loop(::NarrowLoop, ::DeviceHandle) = nothing
mutable struct BindingLoop <: AbstractDevice end  # `loop` on the binding the handle's type carries
loop(::BindingLoop, ::DeviceHandle{<:Enumerated}) = nothing

# Issue a stop against a paused run and wait for the run to leave `:running`
# (§12.1). A stop that fails to wake the pause is followed by a `resume!`, so
# the regression fails the assertion rather than hanging the suite.
function stop_while_paused(sim, request)
    request()
    ended = timedwait(() -> lifecycle(sim) !== :running, 10.0) === :ok
    ended || resume!(sim)
    ended
end

# One `pause!`/`resume!` round, the flag read back through `paused` after each.
pause_round(sim) = (pause!(sim); set = paused(sim); resume!(sim); (set, paused(sim)))

# Is `task` parked in `waited_on`'s wait? Read under the lock, which a notify
# needs, so the answer holds while the caller keeps the lock.
parked_in(task, waited_on) =
    (lock(waited_on); try task.queue === waited_on.waitq finally unlock(waited_on) end)

# Throw the operator's interrupt into `task` once it is parked on `waited_on`,
# as Ctrl-C lands in a blocked wait (§12.4): `true` when thrown, `false` when
# the task never parked. The lock held across the check and the throw is what
# confines the throw to a parked task; no timing is involved. The check under
# it reads the queue directly, since a task's own condition takes a
# non-reentrant lock.
function interrupt_parked(task, waited_on)
    timedwait(() -> parked_in(task, waited_on), 10.0) === :ok || return false
    lock(waited_on)
    try
        task.queue === waited_on.waitq || return false
        schedule(task, InterruptException(); error = true)
    finally
        unlock(waited_on)
    end
    true
end

# A `Staller` under the root input `in`, its paced loop compiled by a short
# fast-paced run and then re-initialized, so a pacing test measures the wait and
# never the JIT (§10.7). Staging `in` afterwards arms the stall for frame 1.
function warm_staller()
    sim = Simulation(fed(Staller(), "stall"); h = 1//100)
    init!(sim, fragment(u = (in = 0.0,)))
    run!(sim; t_end = 0.03, pace = 1.0e6)
    init!(sim, fragment(u = (in = 0.0,)))
    sim
end

# Wall seconds `run!` takes under the keywords given.
timed_run!(sim; kw...) = (start = time_ns(); run!(sim; kw...); (time_ns() - start) / 1.0e9)

# The `DebtReanchor`s the loop's own records carried across a run's snapshots.
loop_reanchors(sim) =
    [d for snapshot in logged(sim) for d in writer_status(snapshot, "loop").recent
     if d isa DebtReanchor]

# One round of the pacing knobs, each read back after its write.
knob_round(sim) = (pace!(sim, 2.0); margin!(sim, 0.01); (pace(sim), margin(sim)))

# --- the panel kit (§11.7, D-270; increment 53) ----------------------------------
# A two-level model whose ports resolve three ways: `ctl/e` to the root input
# `in`, `inner/g/e` through `inner`'s face to `gain_in`, and `inner/c/u` to
# `ctl`'s output across the wire.
panel_model() = Group((; inner = Group((; c = Pendulum(), g = Gain(2.0));
                                       input_wires = ("u" => "c/u", "e" => "g/e"),
                                       output_wires = ("c/θ" => "θ",)),
                         ctl = DiscreteAccumulator(1.0));
                      local_wires = ("ctl/u" => "inner/u",),
                      input_wires = ("in" => "ctl/e", "gain_in" => "inner/e"))

# One root input fanned out to two ports.
fanned_gains() = Group((; a = Gain(1.0), b = Gain(1.0)); input_wires = ("in" => ("a/e", "b/e"),))

# The incumbent's record off the latest snapshot once it reads `:done`, else
# `nothing`.
orphan_record(sim, view) =
    (record = incumbent_status(view, latest(sim)); orphaned(record) ? record : nothing)

function test_devices()
    @testset "a device stages through its handle from its own task, and departure consults should_abort (§11.6, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = OneShot(0.7)
        handle = attach!(sim, dev, Enumerated("a"); should_abort = true)
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 1000.0)                        # ends by the device's stop, not t_end
        @test sim.run.frame < 10000            # the stop truncated the run
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
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        @test (@atomic handle.writer.cell.pending) === nothing
    end

    @testset "wait_next_snapshot observes ordered boundaries and wakes on the stop (§12.3, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Collector()
        attach!(sim, dev, Enumerated())          # the may-write-nothing degenerate: a pure reader
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
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
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))  # boundary zero: ordinal 0
        run!(sim; t_end = 0.5)
        @test latest(sim).boundary == 5
        @test latest(sim).t ≈ 0.5
        @test logged(sim)[1].boundary == 0

        # A second trajectory restarts the ordinal at boundary zero (D-230); the
        # §12.3 wait counter keeps counting across it, never re-armed.
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        @test latest(sim).boundary == 0
        run!(sim; t_end = 0.5)
        @test latest(sim).boundary == 5
        @test logged(sim)[1].boundary == 0
        @test sim.control.counter == 12
    end

    @testset "stop! from any task ends the run at a frame top (§12.1, §12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("p"), Enumerated("a"))  # a rostered device keeps the loop yielding (§12.2)
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        stopper = Threads.@spawn (sleep(0.05); stop!(sim))
        run!(sim; t_end = 1.0e6)
        wait(stopper)
        @test sim.run.frame < 10^7             # truncated, and stopped is sticky:
        @test !running(sim.plane.roster[1].handle)
        # One channel, and the record names who spoke (§13.5, D-203): stop!(sim)
        # is calling code from any task, issuer :code.
        @test termination(sim).source === ControlRequestedStop(:code)
        # A fresh trajectory owes nothing to this stop: init! clears the word.
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        @test step!(sim; frames = 3) == 3
        @test sim.run.frame == 3
    end

    @testset "pause! from another task parks the loop at a frame top, and resume! lets it advance (§12.1)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("p"), Enumerated("a"))  # a rostered device keeps the loop yielding (§12.2)
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        loop_task = current_task()               # a rostered device keeps the loop here (§11.1)
        observer = Threads.@spawn begin
            timedwait(() -> latest(sim).frame > 0, 10.0)   # the run under way
            pause!(sim)
            # the frame in flight completes, then the loop parks at the frame top
            parked = timedwait(() -> parked_in(loop_task, sim.control.wake), 10.0) === :ok
            first_read = latest(sim)
            # the parked frame top's last publication is its own boundary
            consistent = first_read.frame == sim.run.frame && first_read.t == sim.model.exec.clock.t
            state_read = (paused(sim), lifecycle(sim))
            second_read = latest(sim)
            still_parked = parked_in(loop_task, sim.control.wake)
            resume!(sim)
            advanced = timedwait(() -> latest(sim).frame > second_read.frame, 10.0) === :ok
            stop!(sim)
            (parked && still_parked, first_read.frame, second_read.frame, consistent, state_read,
             advanced)
        end
        run!(sim; t_end = 1.0e6)
        (parked, first_frame, second_frame, consistent, state_read, advanced) = fetch(observer)
        @test parked                             # parked in the pause block across both reads
        @test first_frame > 0 && second_frame == first_frame
        @test consistent
        @test state_read == (true, :running)     # read, and set, while the run holds the freeze
        @test advanced
        @test termination(sim).source === ControlRequestedStop(:code)
        @test !paused(sim)
    end

    @testset "a stop issued while paused ends the run at that frame top, with no further frame (§12.1, §12.4(2))" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        handle = attach!(sim, Pad("p"), Enumerated("a"))
        loop_task = current_task()               # a rostered device keeps the loop here (§11.1)
        for (request, issuer) in ((() -> stop!(sim), :code), (() -> stop!(handle), "device 1 (Pad)"))
            init!(sim, fragment(u = (a = 0.0, b = 0.0)))
            observer = Threads.@spawn begin
                timedwait(() -> latest(sim).frame > 0, 10.0)   # the run under way
                pause!(sim)
                parked = timedwait(() -> parked_in(loop_task, sim.control.wake), 10.0) === :ok
                frozen = latest(sim).frame
                (parked, frozen, stop_while_paused(sim, request))
            end
            run!(sim; t_end = 1.0e6)
            (parked, frozen, ended) = fetch(observer)
            @test parked && ended
            @test frozen > 0 && sim.run.frame == frozen && latest(sim).frame == frozen
            @test termination(sim).source === ControlRequestedStop(issuer)
            @test !paused(sim)                   # the tail cleared the flag
        end
    end

    @testset "pause! before run! starts the run paused at its first frame top, and the tail clears the flag (§12.1)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        pause!(sim)
        loop_task = current_task()               # a rostered device keeps the loop here (§11.1)
        observer = Threads.@spawn begin
            parked = timedwait(() -> parked_in(loop_task, sim.control.wake), 10.0) === :ok
            (parked, latest(sim).frame, stop_while_paused(sim, () -> stop!(sim)))
        end
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1.0)               # ten frames, were the flag ignored
        end
        (parked, first_top, ended) = fetch(observer)
        @test parked && first_top == 0 && ended
        @test sim.run.frame == 0
        @test termination(sim).source === ControlRequestedStop(:code)
        @test !paused(sim)
        # No frame top drained the thread budget's warning where one device and
        # the loop are tight, so the run's-end sweep presents it (§12.2, §11.8).
        tight = Threads.nthreads() < 2
        @test count(l -> l.level ≥ Base.CoreLogging.Warn, logs) == Int(tight)
        @test count(d isa ThreadBudget for residue in termination(sim).residue
                    for d in residue.recent) == Int(tight)
        # No run start clears the flag, and the tail left none: the next
        # trajectory advances without a resume!.
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        @test step!(sim; frames = 3) == 3
    end

    @testset "step! blocks while paused until a resume! from another task, then advances in full (§12.1)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        pause!(sim)
        resumer = Threads.@spawn begin
            sleep(0.2)
            parked_at = latest(sim).frame        # step! is parked at its first frame top
            resume!(sim)
            parked_at
        end
        @test step!(sim; frames = 5) == 5
        @test fetch(resumer) == 0
        @test sim.run.frame == 5 && !paused(sim)
        @test lifecycle(sim) === :initialized
    end

    @testset "an interrupt in the pause wait ends the run stopped at that frame top (§12.1, §12.4, D-268)" begin
        # Delivered through `schedule`, which the mask does not see: this
        # exercises the frame top's interrupt arm. A real signal's delivery
        # into the pause is covered by the review's probe, not here.
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        pause!(sim)                              # the run parks at its first frame top
        loop_task = current_task()               # a rostered device keeps the loop here (§11.1)
        observer = Threads.@spawn begin
            sent = interrupt_parked(loop_task, sim.control.wake)
            sent || stop!(sim)                   # a regression fails below rather than hangs
            sent
        end
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1.0e6)
        end
        @test fetch(observer)
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:interrupt)
        @test sim.run.frame == 0 && latest(sim).frame == 0  # no frame in flight
        @test !paused(sim)                       # the tail cleared the flag
        # No frame top drained the thread budget's warning where one device and
        # the loop are tight, so the run's-end sweep presents it (§12.2, §11.8).
        tight = Threads.nthreads() < 2
        @test count(l -> l.level ≥ Base.CoreLogging.Warn, logs) == Int(tight)
        @test count(d isa ThreadBudget for residue in termination(sim).residue
                    for d in residue.recent) == Int(tight)
    end

    @testset "an interrupt in the failed frame's `_finish!` on the calling task keeps its StepError (§12.4, §13.4, D-268)" begin
        # The armed frame waits at its gate until the observer holds `wake`, so
        # the throw's `_finish!` parks on it and the interrupt lands there.
        # Rostered, the failure is logged and `run!` returns; deviceless, rethrown.
        for rostered in (true, false)
            comp = GatedExploder()
            sim = Simulation(single(comp); h = 1//10)
            rostered && attach!(sim, TailProbe(), NoClaim())
            init!(sim)
            caller = current_task()
            wake = sim.control.wake
            observer = Threads.@spawn begin
                armed = timedwait(() -> comp.armed[], 10.0) === :ok
                lock(wake)
                try
                    put!(comp.go, nothing)       # always, so a regression fails rather than hangs
                    armed && interrupt_parked(caller, wake.lock.cond_wait)
                finally
                    unlock(wake)
                end
            end
            logs, thrown = Test.collect_test_logs() do
                try
                    run!(sim; t_end = 5.0)
                    nothing
                catch err
                    err
                end
            end
            @test fetch(observer)
            @test rostered ? thrown === nothing : thrown isa StepError{Exploded}
            @test lifecycle(sim) === :errored
            source = termination(sim).source
            @test source isa LoopError && source.exception isa StepError{Exploded}
            rostered || @test source isa LoopError && source.exception === thrown
            @test count(l -> l.level == Base.CoreLogging.Error, logs) == Int(rostered)
        end
    end

    @testset "paused reads the flag in every lifecycle state, and the verbs refuse none (§12.1, D-268)" begin
        # `:running` is read, and both verbs issued, from another task above.
        sim = Simulation(fed(Exploder(), "arm"); h = 1//10)
        @test lifecycle(sim) === :built && pause_round(sim) == (true, false)
        init!(sim, fragment(u = (in = false,)))
        @test lifecycle(sim) === :initialized && pause_round(sim) == (true, false)
        step!(sim; frames = 1, t_end = 0.1)
        @test lifecycle(sim) === :stopped && pause_round(sim) == (true, false)
        init!(sim, fragment(u = (in = false,)))
        stage!(sim, "in" => true)                # armed: frame 1 throws (§13.6)
        @test_throws StepError step!(sim; t_end = 5.0)
        @test lifecycle(sim) === :errored && pause_round(sim) == (true, false)
    end

    @testset "paced and unpaced runs are bit-identical (§10.7)" begin
        runs = map((Inf, 50)) do p
            sim = Simulation(feedback_model(); h = 1//100)
            init!(sim, fragment(u = (ref = 1.0,)))
            stage!(sim, "ref" => 2.0)            # a traced batch, so the traces carry one
            run!(sim; t_end = 0.2, pace = p)     # twenty frames
            sim
        end
        (unpaced, paced) = runs
        @test latest(paced).status.pacer.pace == 50 && latest(paced).status.pacer.waits > 0
        @test same_trajectory(logged(paced), logged(unpaced))
        @test trace(paced).frames == trace(unpaced).frames == 20
        @test trace(paced).batches == trace(unpaced).batches
    end

    @testset "the deadline law's long-run rate: every frame after the anchor waits for its deadline (§10.7)" begin
        sim = warm_staller()
        elapsed = timed_run!(sim; t_end = 0.05, pace = 0.5)   # five frames, 20 ms apiece
        record = latest(sim).status.pacer
        @test elapsed ≥ 4 * 0.01 / 0.5           # the first frame has no wait (D-269)
        # A hiccup turns a wait into an overrun, and one past a budget makes
        # the next frame a repayment, neither a wait nor an overrun (D-269).
        # Without an overrun, every frame after the anchor waits.
        @test record.waits == 4 || record.overruns > 0
        @test record.waits + record.overruns ≤ 4 && record.waited > 0
        @test record.pace == 0.5
    end

    @testset "pace = Inf is pacer-off: no deadline, no debt, no warning however long a frame stalls (§10.7)" begin
        sim = warm_staller()
        stage!(sim, "in" => 0.06)                # past five 10 ms budgets at pace 1
        run!(sim; t_end = 0.1)
        @test all(snapshot.status.pacer === PacerStatus(nothing) for snapshot in logged(sim))
        @test latest(sim).status.pacer.pace == Inf
        @test isempty(loop_reanchors(sim))
        @test writer_status(latest(sim), "loop").totals.reanchor == 0
    end

    @testset "an overrun leaves debt that later frames repay (§10.7)" begin
        sim = warm_staller()
        stage!(sim, "in" => 0.03)                # frame 1 stalls 30 ms against a 10 ms budget
        run!(sim; t_end = 0.21, pace = 1)        # then twenty quiet frames
        record = latest(sim).status.pacer
        @test record.overruns ≥ 1 && record.peak_debt ≥ 0.019
        @test record.debt < record.peak_debt     # repaid, not forgiven
        @test record.reanchors == 0 && record.forgiven == 0
        @test writer_status(latest(sim), "loop").totals.reanchor == 0
    end

    @testset "debt past five budgets is forgiven by a re-anchor and a warning (§10.7, §11.8)" begin
        sim = warm_staller()
        stage!(sim, "in" => 0.1)                 # frame 1 stalls 100 ms against a 10 ms budget
        run!(sim; t_end = 0.1, pace = 1)
        record = latest(sim).status.pacer
        warning = only(loop_reanchors(sim))
        @test writer_status(latest(sim), "loop").totals.reanchor == 1
        @test warning.forgiven > 0.05 && warning.t == 0.01   # the frame top that saw it
        @test record.reanchors ≥ 1 && record.forgiven ≥ warning.forgiven
        @test record.waits > 0                   # the remaining frames wait normally
    end

    @testset "a live pace! re-anchors and applies forward (§10.7, §12.1)" begin
        sim = warm_staller()
        attach!(sim, TailProbe(), NoClaim())    # the loop yields every frame (§12.2)
        task = Threads.@spawn run!(sim; t_end = 1.0e6, pace = 1)
        started = timedwait(() -> latest(sim).frame ≥ 2, 10.0; pollint = 0.001) === :ok
        pace!(sim, 100)
        landed = timedwait(() -> latest(sim).status.pacer.pace == 100, 10.0; pollint = 0.001) === :ok
        stop!(sim)
        wait(task)
        @test started && landed
        @test latest(sim).status.pacer.reanchors ≥ 1
        @test pace(sim) == 100 && latest(sim).status.pacer.pace == 100
        @test termination(sim).source === ControlRequestedStop(:code)
    end

    @testset "a live switch to pace = Inf re-anchors and clears the debt (§10.7, D-269)" begin
        sim = warm_staller()
        attach!(sim, TailProbe(), NoClaim())    # the loop yields every frame (§12.2)
        task = Threads.@spawn run!(sim; t_end = 1.0e6, pace = 1)
        started = timedwait(() -> lifecycle(sim) === :running &&   # anchored at pace 1
                                  latest(sim).status.pacer.pace == 1, 10.0; pollint = 0.001) === :ok
        pace!(sim, Inf)
        landed = timedwait(() -> latest(sim).status.pacer.pace == Inf, 10.0; pollint = 0.001) === :ok
        stop!(sim)
        wait(task)
        snapshots = logged(sim)
        i = findfirst(snapshot -> snapshot.frame > 0 && snapshot.status.pacer.pace == Inf,
                      snapshots)
        (before, after) = (snapshots[i-1].status.pacer, snapshots[i].status.pacer)
        @test started && landed
        @test snapshots[i].frame == snapshots[i-1].frame + 1 && before.pace == 1
        @test after.debt == 0
        @test after.reanchors == before.reanchors + 1
        @test after.forgiven == before.forgiven + before.debt   # the cleared debt, counted
    end

    # The switch with debt outstanding, which the spawned run above cannot
    # time: the wait driven directly, the stall landing between two frame tops.
    @testset "the switch to pace = Inf forgives outstanding debt, counted (§10.7, D-269)" begin
        control, pacer, cell = Control(5.0), Pacer(), DiagCell(EMPTY_DIAG)
        h = 0.01
        @atomic control.pace = 1.0
        anchor!(pacer, 0.0, 1.0)
        Libc.systemsleep(0.03)                   # frame 1 took 30 ms against a 10 ms budget
        wait_deadline!(control, pacer, cell, h, h)
        @test pacer.overruns == 1 && pacer.debt ≥ 0.02 && pacer.forgiven == 0
        @atomic control.pace = Inf
        wait_deadline!(control, pacer, cell, 2h, h)
        @test pacer.pace == Inf && pacer.debt == 0
        @test pacer.reanchors == 1 && pacer.forgiven == pacer.peak_debt
        @test pacer.overruns == 1 && pacer.waits == 0
        wait_deadline!(control, pacer, cell, 3h, h)   # pacer-off: nothing moves
        @test pacer.reanchors == 1 && pacer.debt == 0
        @test isempty(_take!(cell).ring)              # a deliberate re-anchor warns nothing
    end

    @testset "un-pause re-anchors and clears the debt (§10.7, §12.1)" begin
        sim = warm_staller()
        attach!(sim, TailProbe(), NoClaim())
        task = Threads.@spawn run!(sim; t_end = 1.0e6, pace = 1)
        started = timedwait(() -> latest(sim).frame ≥ 2, 10.0; pollint = 0.001) === :ok
        pause!(sim)
        parked = timedwait(() -> parked_in(task, sim.control.wake), 10.0; pollint = 0.001) === :ok
        before = latest(sim)                     # the parked frame top's last publication
        resume!(sim)
        advanced = timedwait(() -> latest(sim).frame > before.frame, 10.0; pollint = 0.001) === :ok
        stop!(sim)
        wait(task)
        after = first(snapshot for snapshot in logged(sim) if snapshot.frame == before.frame + 1)
        @test started && parked && advanced
        @test after.status.pacer.reanchors == before.status.pacer.reanchors + 1
        @test after.status.pacer.debt == 0
    end

    @testset "a stop issued during a wait lands at the next frame top (§12.1, D-269)" begin
        sim = warm_staller()
        attach!(sim, TailProbe(), NoClaim())
        task = Threads.@spawn run!(sim; t_end = 1.0e6, pace = 0.1)   # 100 ms budgets
        started = timedwait(() -> latest(sim).frame ≥ 1, 10.0; pollint = 0.001) === :ok
        seen = latest(sim).frame
        stop!(sim)
        wait(task)
        @test started
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:code)
        @test latest(sim).frame ≤ seen + 1       # at most the frame the wait held
    end

    @testset "margin tunes the wait, never the arithmetic (§10.7, §12.1)" begin
        sim = warm_staller()
        logs = map((Inf, 0.0)) do seconds           # pure spin, then pure sleep
            init!(sim, fragment(u = (in = 0.0,)))
            @test timed_run!(sim; t_end = 0.05, pace = 1, margin = seconds) ≥ 4 * 0.01
            @test margin(sim) == seconds
            logged(sim)
        end
        @test same_trajectory(logs[1], logs[2])

        # retuned mid-run: legal, and no re-anchor
        init!(sim, fragment(u = (in = 0.0,)))
        attach!(sim, TailProbe(), NoClaim())
        task = Threads.@spawn run!(sim; t_end = 1.0e6, pace = 1)
        started = timedwait(() -> latest(sim).frame ≥ 2, 10.0; pollint = 0.001) === :ok
        margin!(sim, 0.0)
        frame = latest(sim).frame
        advanced = timedwait(() -> latest(sim).frame ≥ frame + 2, 10.0; pollint = 0.001) === :ok
        margin!(sim, Inf)
        stop!(sim)
        wait(task)
        @test started && advanced
        @test margin(sim) == Inf
        @test latest(sim).status.pacer.reanchors == 0
    end

    @testset "step! never waits, whatever pace the control plane holds (§12.6, D-269)" begin
        sim = warm_staller()
        pace!(sim, 1.0e-3)                       # a 10 s budget, were step! paced
        @test step!(sim; frames = 3) == 3
        @test pace(sim) == 1.0e-3
        @test all(snapshot.status.pacer === PacerStatus(nothing) for snapshot in logged(sim))
    end

    @testset "the pacing keywords and verbs validate, and every lifecycle state admits the verbs (§12.1, D-269)" begin
        sim = Simulation(fed(Exploder(), "arm"); h = 1//10)
        @test (pace(sim), margin(sim)) == (Inf, 0.002)   # the control plane's defaults
        @test lifecycle(sim) === :built && knob_round(sim) == (2.0, 0.01)
        init!(sim, fragment(u = (in = false,)))
        @test lifecycle(sim) === :initialized && knob_round(sim) == (2.0, 0.01)
        step!(sim; frames = 2)
        trc = trace(sim)
        refusals = Any[(:pace, p) for p in (0, -1, NaN, "1")]
        push!(refusals, (:margin, -1))
        target = Simulation(fed(Exploder(), "arm"); h = 1//10)
        for (argument, value) in refusals
            calls = ((:run!, () -> run!(sim; t_end = 0.2, argument => value)),
                     (:replay!, () -> replay!(target, trc; argument => value)),
                     argument === :pace ? (:pace!, () -> pace!(sim, value)) :
                                          (:margin!, () -> margin!(sim, value)))
            for (call, attempt) in calls
                d = carried(@test_throws DiagnosticError{ArgumentInvalid} attempt())
                @test d.call === call && d.reason === :range
                @test d.argument === argument && isequal(d.value, value)
            end
        end
        @test (pace(sim), margin(sim)) == (2.0, 0.01)    # every refusal precedes the write
        @test lifecycle(sim) === :initialized && lifecycle(target) === :built
        @test pace!(sim, Inf) === nothing && margin!(sim, Inf) === nothing   # Inf admitted by both
        step!(sim; frames = 1, t_end = 0.1)
        @test lifecycle(sim) === :stopped && knob_round(sim) == (2.0, 0.01)
        init!(sim, fragment(u = (in = false,)))
        stage!(sim, "in" => true)                # armed: frame 1 throws (§13.6)
        @test_throws StepError step!(sim; t_end = 5.0)
        @test lifecycle(sim) === :errored && knob_round(sim) == (2.0, 0.01)
    end

    @testset "a crash is caught, shutdown! runs, the run continues, claims persist (§12.4(6))" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Crasher()
        attach!(sim, dev, Enumerated("a"))
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 0.5)
        end
        @test sim.run.frame == 5               # the run reached t_end regardless
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
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1000.0)
        end
        @test sim.run.frame < 10000            # ended by the crash's stop, not t_end
        @test crash_accounted(sim, logs, "device 1 (Crasher)")
    end

    @testset "a failed init! is bracketed: shutdown!, no task, claims persist (§12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = BadInit()
        attach!(sim, dev, Enumerated("a"))
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 0.5)
        @test dev.log == [:init, :shutdown]      # loop never ran: no task was spawned
        @test sim.run.frame == 5               # flag clear: the run proceeds without it
        # The report was written pre-spawn, addressed by the entry (§12.4), so it
        # deterministically makes the first frame top's fold: the first frame's
        # snapshot carries the delta, the terminal status the totals.
        status = writer_status(latest(sim), "device 1 (BadInit)")
        @test status.totals.crash == 1
        crash = only(writer_status(logged(sim)[2], "device 1 (BadInit)").recent)
        @test crash isa DeviceCrash && crash.cause isa ErrorException &&
              crash.abort === false
        # Dead from boundary zero, with no marking machinery (§12.4): the cell was
        # never heartbeated — stale against any clock — and with no task of its
        # own inside the run it reads `:done` (§12.2).
        @test stale(status) && status.task_state === :done
        stage!(sim, "a" => 9.0)                  # claims persist: death is not detach
        @test only((@atomic sim.plane.harness_diag.batch).ring) isa ClaimedFaceEntry
        # With should_abort set the stop is already pending at the loop's start:
        # the run advances zero frames and ends through the same tail — no frame
        # top ever folds the report, so only the run's-end sweep can present it.
        sim2 = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim2, BadInit(), Enumerated("a"); should_abort = true)
        init!(sim2, fragment(u = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim2; t_end = 0.5)
        end
        @test sim2.run.frame == 0
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

    @testset "report! by roster entry files a crash in that entry's cell alone, with no beat (§12.4)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        attach!(sim, Pad("p"), Enumerated("a"))
        attach!(sim, Pad("q"), Enumerated("b"))
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        run!(sim; t_end = 0.2)
        @test lifecycle(sim) === :stopped
        entry, bystander = sim.plane.roster
        heartbeat = _heartbeat(entry.handle.diag_cell)
        report!(entry, DeviceCrash(ErrorException("x"), false))
        crash = only((@atomic entry.handle.diag_cell.batch).ring)
        @test crash isa DeviceCrash && crash.cause isa ErrorException && crash.abort === false
        @test _heartbeat(entry.handle.diag_cell) == heartbeat   # a beat would claim life
        @test (@atomic bystander.handle.diag_cell.batch) === EMPTY_DIAG
        # DeviceCrash is the one kind the framework files by entry.
        @test_throws MethodError report!(entry, MalformedDatum("x"))
    end

    @testset "an interrupt inside init! is the operator's stop: released, no crash, no task (§12.4, D-268)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = InitInterrupted()
        probe = TailProbe()
        attach!(sim, dev, Enumerated("a"))
        attach!(sim, probe, Enumerated())
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 0.5)
        end
        @test dev.log == [:init, :shutdown]      # released; no task, so its loop never ran
        @test probe.log == [:init, :shutdown]    # the other entry still initialized, then the tail
        @test sim.run.frame == 0          # the stop was pending at the first frame top
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:interrupt)
        status = writer_status(latest(sim), "device 1 (InitInterrupted)")
        @test status.totals.crash == 0 && status.task_state === :none
        @test !any(d isa DeviceCrash for residue in termination(sim).residue for d in residue.recent)
        # No crash presented, nor any warning but the thread budget's where two
        # devices and the loop are tight: no frame top drained it, so the
        # run's-end sweep presents it (§12.2, §11.8).
        tight = Threads.nthreads() < 3
        @test count(l -> l.level ≥ Base.CoreLogging.Warn, logs) == Int(tight)
        @test count(d isa ThreadBudget for residue in termination(sim).residue
                    for d in residue.recent) == Int(tight)
    end

    @testset "an interrupt escaping the init bracket still releases every device whose init! began (§11.6, §12.4, D-268)" begin
        # The first interrupt cuts the hooked `init!`, and the bracket catches it,
        # releases the device and drops it from `live`; its stop request then
        # parks on `wake`, which the observer holds, and a second interrupt there
        # escapes the bracket into `run!`'s arm.
        sim = Simulation(two_root_inputs(); h = 1//10)
        probe = TailProbe()
        dev = HookedInit()
        attach!(sim, probe, Enumerated())
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        caller = current_task()
        wake = sim.control.wake
        observer = Threads.@spawn begin
            sent = 0
            send(waited_on) = interrupt_parked(caller, waited_on) && (sent += 1; true)
            ok = timedwait(() -> parked_in(caller, dev.hook), 10.0) === :ok
            lock(wake)
            try
                ok = ok && send(dev.hook) && send(wake.lock.cond_wait)
            finally
                unlock(wake)
            end
            if !ok                               # a regression fails below rather than hangs
                lock(dev.hook)
                try
                    dev.hold = false
                    notify(dev.hook)
                finally
                    unlock(dev.hook)
                end
                stop!(sim)
            end
            sent
        end
        _, thrown = Test.collect_test_logs() do
            try
                run!(sim; t_end = 0.5)
                nothing
            catch err
                err
            end
        end
        @test fetch(observer) == 2
        @test thrown === nothing
        @test probe.log == [:init, :shutdown]    # listed before the escape, so the arm released it
        @test dev.inits == 1 && dev.shutdowns == 1   # the bracket's release alone: dropped before the arms
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:interrupt)
    end

    @testset "a body ignoring the predicate is abandoned under join_timeout, by name (§12.4(5))" begin
        sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = 0.2)
        dev = Stubborn()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
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

    @testset "an interrupt during the tail collapses the joins, the device named (§12.4, D-268)" begin
        sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = 30.0)
        dev = Wedged()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        tail_task = current_task()               # the tail runs on the calling task
        observer = Threads.@spawn begin
            sent = interrupt_parked(tail_task, dev.hook)
            # a regression fails below rather than hangs
            sent || (lock(dev.hook); try notify(dev.hook) finally unlock(dev.hook) end)
            sent
        end
        t0 = time()
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 0.3)
        end
        @test fetch(observer)
        @test time() - t0 < 15.0                 # the collapse, not the 30 s cap
        @test lifecycle(sim) === :stopped        # escalation never reclassifies the run
        # one warning, the residue's own: the interrupt was not warned past as
        # an `unblock!` throw
        @test count(l -> l.level == Base.CoreLogging.Warn, logs) == 1
        writer_residue = only(residue for residue in termination(sim).residue
                              if residue.writer == "loop")
        timeout = only(d for d in writer_residue.recent if d isa DeviceJoinTimeout)
        @test timeout.who == "device 1 (Wedged)" && timeout.timeout == 30.0
        @test :released ∉ dev.log                # abandoned, still blocked, when run! returned
        # Abandonment is not a kill: release the straggler inside this testset.
        @test timedwait(() -> dev.task !== nothing, 10.0) === :ok
        put!(dev.release, 1)
        wait(dev.task)
        @test dev.log == [:released, :shutdown]
    end

    @testset "unblock! makes the blocking call return: a clean exit, no timeout (§12.4(3))" begin
        sim = Simulation(two_root_inputs(); h = 1//10, join_timeout = 2.0)
        dev = Blocked()
        attach!(sim, dev, Enumerated())
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
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
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
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
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        logs, _ = Test.collect_test_logs() do
            run!(sim; t_end = 1000.0)
        end
        @test lifecycle(sim) === :stopped
        @test termination(sim).source === ControlRequestedStop(:interrupt)
        @test sim.run.frame < 10000       # ended by the forwarded stop, not t_end
        @test writer_status(latest(sim), "device 1 (Interrupting)").totals.crash == 0
        @test !any(occursin("DeviceCrash", string(l.message)) for l in logs)
        @test isempty(termination(sim).residue)
        @test dev.log == [:loop, :shutdown]      # shutdown! on this exit path too
        # No should_abort consultation: the interrupt already holds the stop word,
        # and the abort's later request loses the first-writer CAS (§11.6).
        sim2 = Simulation(two_root_inputs(); h = 1//10, join_timeout = 2.0)
        attach!(sim2, Interrupting(), Enumerated(); should_abort = true)
        init!(sim2, fragment(u = (a = 0.0, b = 0.0)))
        run!(sim2; t_end = 1000.0)
        @test termination(sim2).source === ControlRequestedStop(:interrupt)
    end

    @testset "a device with no loop method is refused at attach!, by kind (§11.6)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        d = carried(@test_throws DiagnosticError{DeviceContractMismatch} attach!(sim, Loopless(), Enumerated()))
        @test d.reason === :no_loop && d.device == "Loopless"
        @test isempty(sim.plane.roster)               # the rejection consumed no id
        # a `loop` declared on `DeviceHandle` itself is the method the wrapper calls
        @test attach!(sim, NarrowLoop(), Enumerated()) isa DeviceHandle
        # and so is one narrowed on the binding's type, which the handle's carries
        @test attach!(sim, BindingLoop(), Enumerated()) isa DeviceHandle
    end

    @testset "gather without an output side is a contract misuse, by kind (§11.6)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        handle = attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
        d = carried(@test_throws DiagnosticError{DeviceContractMismatch} gather(handle, latest(sim)))
        @test d.reason === :no_output_side && d.device == "device 1 (Pad)"
    end

    @testset "a detached handle's writes refuse by name, its reads stay legal (§11.6, D-244)" begin
        sim = Simulation(two_root_inputs(); h = 1//10)
        dev = Pad("p")
        handle = attach!(sim, dev, Enumerated("a"))
        init!(sim, fragment(u = (a = 0.0, b = 0.0)))
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
            init!(sim, fragment(u = (a = 0.0, b = 0.0)))
            run!(sim; t_end = 0.5)
            port(sim, "s", :e)
        end
        @test trajectories[1] === trajectories[2]
    end

    @testset "port views resolve every port across levels, and liveness follows the claim (§11.7)" begin
        sim = Simulation(panel_model(); h = 1//10)
        enumerated_handle = attach!(sim, Pad("a"), Enumerated("in"))
        alone_views = port_views(enumerated_handle)   # before the second claim exists
        greedy_handle = attach!(sim, Pad("b"), Greedy())
        views = port_views(enumerated_handle)
        # Three primitive inputs, `inner`'s two faces, the root's two, five produced cells.
        @test length(views) == 12
        view = views[("ctl", :e)]
        @test view.live && view.slot == 1 && view.source == ("", :in) &&
              view.incumbent == "device 1 (Pad)"
        view = views[("inner/g", :e)]
        @test !view.live && view.slot == 0 && view.source == ("", :gain_in) &&
              view.incumbent == "device 2 (Pad)"
        # An assembly's face shares the producer and the verdict of the port behind it.
        face_view = views[("inner", :e)]
        @test (face_view.source, face_view.live, face_view.slot, face_view.addr,
               face_view.incumbent) ==
              (view.source, view.live, view.slot, view.addr, view.incumbent)
        @test views[("inner", :u)].source == ("ctl", :u) && !views[("inner", :u)].live
        # A root input's own view is its source, live for the handle claiming it.
        view = views[("", :in)]
        @test view.live && view.slot == 1 && view.source == ("", :in) &&
              view.incumbent == "device 1 (Pad)"
        @test !views[("", :gain_in)].live && views[("", :gain_in)].incumbent == "device 2 (Pad)"
        view = views[("inner/c", :u)]
        @test !view.live && view.slot == 0 && view.source == ("ctl", :u) && view.incumbent == ""
        produced = [("ctl", :u), ("inner", :θ), ("inner/c", :θ), ("inner/c", :ω), ("inner/g", :out)]
        @test all(k -> !views[k].live && views[k].source == k && views[k].incumbent == "", produced)
        greedy_views = port_views(greedy_handle)
        @test greedy_views[("inner/g", :e)].live && greedy_views[("inner/g", :e)].slot == 1
        @test greedy_views[("ctl", :e)].incumbent == "device 1 (Pad)"
        # Baked before the second attach, the incumbent is the harness (D-270).
        @test alone_views[("inner/g", :e)].incumbent == "harness"
        # Fan-out: two ports on one root input share liveness, slot and address.
        fan_sim = Simulation(fanned_gains(); h = 1//10)
        fan_views = port_views(attach!(fan_sim, Pad("f"), Greedy()))
        @test fan_views[("a", :e)].live && fan_views[("b", :e)].live
        @test (fan_views[("a", :e)].slot, fan_views[("a", :e)].addr) ==
              (fan_views[("b", :e)].slot, fan_views[("b", :e)].addr)
    end

    @testset "pending reads the cell without taking it, and the peek composes it with the snapshot (§11.7, §11.4)" begin
        sim = Simulation(panel_model(); h = 1//10)
        dev = Pad("a")
        enumerated_handle = attach!(sim, dev, Enumerated("in"))
        greedy_handle = attach!(sim, Pad("b"), Greedy())
        init!(sim, fragment(u = (in = 1.0, gain_in = 2.0)))
        views = port_views(enumerated_handle)
        @test pending(enumerated_handle, 1) === nothing
        stage!(enumerated_handle, "in" => 3)             # converted at staging
        @test pending(enumerated_handle, 1) === Some(3.0)
        @test (@atomic enumerated_handle.writer.cell.pending) !== nothing   # a read, never a take
        @test pending(greedy_handle, 1) === nothing       # another device's write is invisible
        snapshot = latest(sim)
        @test peek(views[("ctl", :e)], enumerated_handle, snapshot) === 3.0
        @test port(snapshot, "", :in) === 1.0
        @test peek(views[("inner/g", :e)], enumerated_handle, snapshot) === 2.0
        @test peek(views[("inner/g", :out)], enumerated_handle, snapshot) === 4.0
        stage!(enumerated_handle, "in" => 4.0)
        @test pending(enumerated_handle, 1) === Some(4.0) # newest wins
        run!(sim; t_end = 0.3)
        @test pending(enumerated_handle, 1) === nothing   # the drain took it
        @test port(latest(sim), "", :in) === 4.0
        detach!(sim, dev)
        @test pending(enumerated_handle, 1) === nothing   # a read, legal on a retired handle
    end

    @testset "an edge widget counts multi-click through the pending peek (§11.7)" begin
        sim = Simulation(panel_model(); h = 1//10)
        handle = attach!(sim, Pad("a"), Enumerated("in"))
        init!(sim, fragment(u = (in = 1.0, gain_in = 2.0)))
        view = port_views(handle)[("ctl", :e)]
        snapshot = latest(sim)
        for _ in 1:3
            stage!(handle, "in" => peek(view, handle, snapshot) + 1.0)
        end
        @test pending(handle, 1) === Some(4.0)
        @test port(latest(sim), "", :in) === 1.0
    end

    @testset "a staged edit shows through the peek while paused, and through the snapshot after the un-pause drain (§11.7, §12.1)" begin
        sim = Simulation(panel_model(); h = 1//10)
        handle = attach!(sim, Pad("a"), Enumerated("in"))
        init!(sim, fragment(u = (in = 1.0, gain_in = 2.0)))
        view = port_views(handle)[("ctl", :e)]
        loop_task = current_task()               # a rostered device keeps the loop here (§11.1)
        observer = Threads.@spawn begin
            timedwait(() -> latest(sim).frame > 0, 10.0)
            pause!(sim)
            parked = timedwait(() -> parked_in(loop_task, sim.control.wake), 10.0) === :ok
            stage!(handle, "in" => 7.0)
            peeked = peek(view, handle, latest(sim))
            held_back = port(latest(sim), "", :in)
            resume!(sim)
            applied = timedwait(() -> port(latest(sim), "", :in) == 7.0, 10.0) === :ok
            after = pending(handle, 1)
            stop!(sim)
            (parked, peeked, held_back, applied, after)
        end
        run!(sim; t_end = 1.0e6)
        (parked, peeked, held_back, applied, after) = fetch(observer)
        @test parked
        @test peeked === 7.0
        @test held_back === 1.0                  # the snapshot waits for the drain
        @test applied
        @test after === nothing
    end

    @testset "incumbent_status joins the view to the writer record, and orphaned reads the task state (§11.7, §12.2)" begin
        sim = Simulation(panel_model(); h = 1//10)
        handle = attach!(sim, Pad("a"), Enumerated("in"))
        attach!(sim, Pad("b"), Greedy())
        init!(sim, fragment(u = (in = 1.0, gain_in = 2.0)))
        views = port_views(handle)
        record = incumbent_status(views[("inner/g", :e)], latest(sim))
        @test record.who == "device 2 (Pad)" && record.task_state === :none
        @test !orphaned(record)                       # outside a run, not a dead task
        @test incumbent_status(views[("inner/c", :u)], latest(sim)) === nothing
        # A stepped frame spawns no task and is no run (§12.6): still `:none`.
        step!(sim)
        record = incumbent_status(views[("inner/g", :e)], latest(sim))
        @test latest(sim).frame == 1 && record.task_state === :none && !orphaned(record)
        alone_sim = Simulation(panel_model(); h = 1//10)
        alone_handle = attach!(alone_sim, Pad("a"), Enumerated("in"))
        init!(alone_sim, fragment(u = (in = 1.0, gain_in = 2.0)))
        harness_record = incumbent_status(port_views(alone_handle)[("inner/g", :e)], latest(alone_sim))
        @test harness_record.who == "harness" && !orphaned(harness_record)

        # During a run: the Pad's loop returns at once, the Crasher's throws. The
        # wrapper catches the crash, so both tasks end `:done`, and the crash
        # count tells them apart.
        run_sim = Simulation(panel_model(); h = 1//10)
        run_handle = attach!(run_sim, Pad("a"), Enumerated("in"))
        attach!(run_sim, Crasher(), Enumerated("gain_in"))
        init!(run_sim, fragment(u = (in = 1.0, gain_in = 2.0)))
        run_views = port_views(run_handle)
        observer = Threads.@spawn begin
            returned = timedwait(() -> orphan_record(run_sim, run_views[("ctl", :e)]) !== nothing,
                                 10.0) === :ok
            crashed = timedwait(10.0) do
                latest_record = orphan_record(run_sim, run_views[("inner/g", :e)])
                latest_record !== nothing && latest_record.totals.crash ≥ 1
            end === :ok
            records = (orphan_record(run_sim, run_views[("ctl", :e)]),
                       orphan_record(run_sim, run_views[("inner/g", :e)]))
            stop!(run_sim)
            (returned && crashed, records)
        end
        Test.collect_test_logs() do
            run!(run_sim; t_end = 1.0e6)
        end
        (seen, (pad_record, crasher_record)) = fetch(observer)
        @test seen
        @test pad_record.who == "device 1 (Pad)" && pad_record.task_state === :done
        @test pad_record.totals.crash == 0
        @test crasher_record.who == "device 2 (Crasher)" && crasher_record.task_state === :done
        @test crasher_record.totals.crash == 1
        @test stale(crasher_record; now = crasher_record.heartbeat + 3.0)
        @test !stale(crasher_record; now = crasher_record.heartbeat + 1.0)

        # No live task of its own inside a run reads `:done` too (§12.2): the
        # Pad's body returns at once, and the BadInit's `init!` throws so no
        # task is spawned. `run!` returns only when the loop ends, so the
        # observer stops the sim.
        dead_sim = Simulation(panel_model(); h = 1//10)
        dead_handle = attach!(dead_sim, Pad("p"), Enumerated("in"))
        attach!(dead_sim, BadInit(), Enumerated("gain_in"))
        init!(dead_sim, fragment(u = (in = 1.0, gain_in = 2.0)))
        dead_views = port_views(dead_handle)
        observer = Threads.@spawn begin
            seen = timedwait(10.0) do
                orphan_record(dead_sim, dead_views[("ctl", :e)]) !== nothing &&
                    orphan_record(dead_sim, dead_views[("inner/g", :e)]) !== nothing
            end === :ok
            records = (orphan_record(dead_sim, dead_views[("ctl", :e)]),
                       orphan_record(dead_sim, dead_views[("inner/g", :e)]))
            stop!(dead_sim)
            (seen, records)
        end
        Test.collect_test_logs() do
            run!(dead_sim; t_end = 1.0e6)
        end
        (seen, (dead_record, init_record)) = fetch(observer)
        @test seen
        @test dead_record.who == "device 1 (Pad)" && dead_record.task_state === :done
        @test dead_record.totals.crash == 0
        @test init_record.who == "device 2 (BadInit)" && init_record.task_state === :done
        @test init_record.totals.crash == 1 && orphaned(init_record)
    end
end
