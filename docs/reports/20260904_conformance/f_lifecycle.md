# Agent F — §12 runtime periphery: lifecycle and orchestration

**Slice.** `docs/design/spec.md` §12, lines 6070–6922 (§12.1 control plane,
§12.2 loop scheduling, §12.3 the next-snapshot wait, §12.4 the shutdown
protocol, §12.5 the mid-run mutation doctrine, §12.6 the run lifecycle and
partial advance, §12.7 replay).

**Tip.** `70672d1`. Julia 1.12.7.

**Probes.** Three, all foreground `julia --project=.` from the repository
root, all reported in section 4: the `t_end` rounding (4.2), the boundary
ordinal across a warm restart (see 6), and the wrapper's classification of an
`unblock!`-induced raise (4.1).

**Forbidden reads.** None. I read `docs/design/spec.md` (my slice, the
glossary entries it links, and the cited §13.5/§14.5 sentences for meaning
only), all of `src/` and `test/`, the "What is real here" file table in
`docs/design/implementation.md`, and the `D-027`/`D-028` entries in
`docs/design/decisions.md`.

## 2. Summary

The slice divides cleanly in two. Everything that touches **stop, shutdown,
lifecycle and replay** is built, and built close to the letter: the stop word
with its first-wins CAS issuer, the ordered tail, the pre-spawn `init!`
bracket down to its pseudocode, the join under `join_timeout` with
`DeviceJoinTimeout` by name, the run's-end residue sweep, the five-state
lifecycle, the input mode with its three doors, and the whole of §12.7's
replay including the two substitutions, the up-front entry pass, `to_time`,
`live!` and the mode flip at the recording's end. The test suite covers this
half unusually well; `test_devices.jl`, `test_lifecycle.jl` and
`test_trace.jl` between them assert most of it directly.

Everything that touches **pacing** is absent, and it takes a cluster of §12.1
and §12.2 claims with it: pause and un-pause, the `pace` and `margin` fields
on the control plane, the coarse-phase `sleep`, the spin phase, the pacer
diagnostics beside the liveness record. The explicit `yield()` survives and
carries §12.2's yield rule on its own. The `Threads.nthreads()` startup
warning is not built either, and neither is the operator interrupt's masking:
the code keeps only the defensive catch §13.4 allows, which routes an
`InterruptException` to the stop path but abandons the frame mid-boundary —
exactly the state §12.4 says the masking exists to prevent. The `gui = true`
flag and the shipped GUI device do not exist, so the one roster mutation
§12.4 assigns to the tail has nothing to perform.

Three deviations are worth the reader's attention beyond that absence list.
First, `unblock!` works but the framework wrapper does not honour §12.4(3)'s
promise to treat the raise it provokes as shutdown: it files a `DeviceCrash`
against the device on every clean stop unless the *author* catches the raise
(4.1). Second, `t_end` is taken to the *nearest* frame rather than the first
frame reaching or exceeding it, so a run can end short of its own clock bound
by up to `h/2` (4.2) — a live wrong result, not a missing feature. Third, the
interrupt carve-out returns its termination source directly instead of
writing the control-plane stop word, so it can overwrite an issuer that won
the CAS earlier (4.3).

## 3. Findings

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 12.1 / 6079 | a separate atomic control surface, consulted by the loop at frame top | accurate | `src/devices.jl:108-116`, `src/sim.jl:1031-1032` | `test_devices.jl:155` | |
| 12.1 / 6079 | pause / un-pause fields on it | absent | — | — | nothing in `src/` pauses; `grep -rn pause src/` finds only comments |
| 12.1 / 6079 | pace-change field on it | absent | — | — | no pacer exists |
| 12.1 / 6082 | `margin` rides the control plane | absent | — | — | no wait, so no margin |
| 12.1 / 6087 | the stop's issuers are GUI, device handle, code, operator interrupt | short | `src/devices.jl:216`, `src/sim.jl:1174`, `src/sim.jl:1058` | `test_devices.jl:110,155`, `test_failures.jl:114` | three of four; no GUI is shipped |
| 12.1 / 6092 | each issuing site writes its identity by CAS from empty, first writer wins | accurate | `src/devices.jl:121-122` | `test_devices.jl:155` | the interrupt path bypasses it, see 4.3 |
| 12.1 / 6096 | the frame-top read consults the word for non-empty | accurate | `src/sim.jl:1031-1032` | `test_devices.jl:155` | |
| 12.1 / 6097 | the issuer lands in the termination record's `ControlRequestedStop` | accurate | `src/devices.jl:42-44`, `src/sim.jl:276-281` | `test_devices.jl:119` | |
| 12.1 / 6099 | control is not staged: it rides outside the drain/trace path | accurate | `src/devices.jl:108-116` | — | |
| 12.1 / 6104 | while paused the loop blocks on a condition, not a spin | absent | — | — | no pause state |
| 12.2 / 6112 | **Rule** coarse phase uses task-yielding `sleep`; no `systemsleep` variant | absent | — | — | no pacer wait is built at all |
| 12.2 / 6115 | why `sleep` buys the wait slot; the `systemsleep` guarded addition | n/a | — | — | rationale |
| 12.2 / 6124 | **Rule** with devices attached, every frame yields at least once | accurate | `src/sim.jl:1035` | no test | gated on a non-empty roster |
| 12.2 / 6128 | the yield is implicit in the coarse-phase `sleep` | absent | — | — | |
| 12.2 / 6129 | an explicit `yield()` covers unpaced and pure-spin frames | accurate | `src/sim.jl:1035` | no test | every run is unpaced here |
| 12.2 / 6131 | the spin phase never yields | absent | — | — | no spin phase |
| 12.2 / 6134 | the thread-occupancy consequence; no framework monopolist | n/a | — | — | rationale |
| 12.2 / 6140 | **Rule** thread budget = sizing rule + startup warning, not a hard error | absent | — | — | see 4.4 |
| 12.2 / 6142 | why FlightCore's `nthreads` error cannot reproduce | n/a | — | — | rationale |
| 12.2 / 6154 | `run!` warns when `Threads.nthreads()` is tight, naming `julia -t`, once per run | absent | — | — | see 4.4 |
| 12.2 / 6162 | the published framework status carries per-device liveness: timestamp + `task_state` | accurate | `src/dataplane.jl:351-358`, `src/sim.jl:1456-1466` | `test_diagnostics.jl:132` | |
| 12.2 / 6165 | liveness sits next to the pacer diagnostics | absent | — | — | `FrameworkStatus` (`src/dataplane.jl:368-370`) carries writers only |
| 12.2 / 6166 | the mechanism is the per-writer cell plus the `Task` handles, and nothing besides | accurate | `src/dataplane.jl:290-291,388-389` | `test_diagnostics.jl:212` | |
| 12.2 / 6174 | **stale** = a liveness timestamp more than 2 s behind wall clock | accurate | `src/dataplane.jl:373,385-386` | `test_devices.jl:201` (`stale(bw)`) | threshold value itself untested |
| 12.2 / 6175 | the heartbeat is advisory: never a kill trigger, never a detach | accurate | `src/dataplane.jl:385-386` | — | nothing in `src/` consumes `stale` |
| 12.3 / 6183 | **Rule** a monotonic boundary counter published with the snapshot + one `Threads.Condition` | accurate | `src/devices.jl:111-112`, `src/dataplane.jl:567` | `test_devices.jl:146` | |
| 12.3 / 6187 | the counter counts published boundaries — grid, `t*`, boundary zero — not frames | accurate | `src/sim.jl:622,1042`, `src/localization.jl:145` | `test_log.jl:8`, `test_devices.jl:146` | |
| 12.3 / 6191 | publication is `lock; counter += 1; notify; unlock` | accurate | `src/sim.jl:1438-1443` | — | |
| 12.3 / 6195 | `wait_next_snapshot(handle)` blocks under the canonical predicate loop | accurate | `src/devices.jl:306-319` | `test_devices.jl:130` | |
| 12.3 / 6198 | shutdown works: the tail wakes all waiters and each predicate routes its owner out | accurate | `src/devices.jl:406-416` | `test_devices.jl:130` | |
| 12.3 / 6203 | a `Base.Event` latch is the wrong primitive | n/a | — | — | rejected alternative |
| 12.3 / 6207 | the boundary index is carried *in* the snapshot, with `t` | accurate | `src/dataplane.jl:567` | `test_devices.jl:146` | not per-trajectory; see 6 |
| 12.3 / 6210 | the loop mirrors the index in the state the wait predicate tests | accurate | `src/devices.jl:112`, `src/devices.jl:161` | `test_devices.jl:130` | |
| 12.3 / 6212 | **Rule** the release-store of `latest` happens before the counter increment under the lock | accurate | `src/sim.jl:1434-1443` | `test_devices.jl:130` (no stale wake) | ordering not asserted directly |
| 12.3 / 6226 | `counter > last_seen` implies `latest` holds at least that boundary; newer is expected | n/a | — | — | consequence |
| 12.3 / 6232 | newest-wins, no queues, no backpressure, the loop never waits on anyone | accurate | `src/devices.jl:306-319`, `src/sim.jl:1426-1444` | `test_devices.jl:130` | |
| 12.3 / 6236 | the GUI does not use the wait | n/a | — | — | no GUI shipped |
| 12.4 / 6252 | **Rule** steps (1)–(5) run in that order on every stop | accurate | `src/sim.jl:938-942,957-960` | `test_devices.jl:241,266` | |
| 12.4 / 6256 | (1) three initiating events: `t_end`, a control stop, a `stop_on` face | accurate | `src/sim.jl:1032-1033,1043` | `test_lifecycle.jl:94,141`, `test_devices.jl:155` | |
| 12.4 / 6262 | (1) the loop completes the current boundary sequence, never stops mid-frame | accurate | `src/sim.jl:1031-1034` | `test_devices.jl:155` | the interrupt path violates it, see 4.3 |
| 12.4 / 6264 | (1) the final snapshot is published, and only then the sticky stopped status | accurate | `src/sim.jl:1042` then `src/devices.jl:408` | `test_devices.jl:110` | |
| 12.4 / 6266 | (2) the next-snapshot wait is woken | accurate | `src/devices.jl:406-416` | `test_devices.jl:130` | |
| 12.4 / 6267 | (2) the pause is woken too, so a stop issued while paused works | absent | — | — | no pause |
| 12.4 / 6270 | (3) the `unblock!(device)` hook, default no-op | accurate | `src/devices.jl:185,432-439` | `test_devices.jl:266` | not called for the calling-task device (structurally impossible) |
| 12.4 / 6273 | (3) the framework wrapper catches the raise it provokes and treats it as shutdown | short | `src/devices.jl:348-358` | `test_devices.jl:266` (author-side catch) | see 4.1 |
| 12.4 / 6276 | (4) exit is the author's own `while running(handle)` | accurate | `src/devices.jl:205` | `test_devices.jl:130,281` | |
| 12.4 / 6280 | (4) the wrapper's `finally shutdown!(device)` is guaranteed on every exit path | accurate | `src/devices.jl:354` | `test_devices.jl:173,201,266` | |
| 12.4 / 6282 | (5) join under `join_timeout`, a `Simulation` keyword, positive real, default 5 | accurate | `src/sim.jl:133,145-146`, `src/devices.jl:440` | `test_devices.jl:318` | |
| 12.4 / 6284 | (5) an over-running task is reported *by name* | accurate | `src/devices.jl:448` | `test_devices.jl:241` | |
| 12.4 / 6286 | (5) abandoned with `DeviceJoinTimeout`, swept into the termination record and logged | accurate | `src/devices.jl:443-450,467-497` | `test_devices.jl:241` | |
| 12.4 / 6292 | (6) voluntary exit when the loop body returns; no `should_close` hook | accurate | `src/devices.jl:348-358` | `test_devices.jl:110,281` | |
| 12.4 / 6294 | (6) with `should_abort` set the exit path also requests a sim stop | accurate | `src/devices.jl:355` | `test_devices.jl:110,190` | |
| 12.4 / 6296 | (6) otherwise the sim continues with the task absent; roster entry and claims persist | accurate | `src/devices.jl:348-358` | `test_devices.jl:173` | |
| 12.4 / 6301 | (6) the orphaned root inputs hold their last-drained values | accurate | `src/sim.jl:1326-1345` | no test | nothing resets a root cell mid-run |
| 12.4 / 6302 | (6) a crashing device task is caught by the wrapper and logged by name (`DeviceCrash`) | accurate | `src/devices.jl:352`, `src/dataplane.jl:102-105` | `test_devices.jl:173,190` | |
| 12.4 / 6305 | (7) a loop-side failure runs (1)–(5) from the catch path | accurate | `src/sim.jl:938-942` | `test_lifecycle.jl:222` | |
| 12.4 / 6307 | (7) the failed boundary is discarded, the previous snapshot promoted to final | accurate | `src/sim.jl:963-970` | `test_lifecycle.jl:222`, `test_failures.jl:106` | |
| 12.4 / 6321 | **Rule** the terminal snapshot is retained in the log under any `log_every`/`log_max` | accurate | `src/dataplane.jl:660` | `test_log.jl:53` | |
| 12.4 / 6327 | the terminal snapshot's status carries the run's cumulative counters up to its frame top | accurate | `src/sim.jl:1446-1466` | `test_diagnostics.jl:103` | |
| 12.4 / 6330 | what the tail produces is recorded and logged, never published | accurate | `src/devices.jl:467-497`, `src/sim.jl:971-975` | `test_devices.jl:241`, `test_diagnostics.jl:149` | |
| 12.4 / 6335 | `t_end` lands on the grid: the first grid boundary whose time reaches or exceeds it | stand-in | `src/sim.jl:891,1033,1136` | `test_lifecycle.jl:94` (grid-aligned only) | `round`, not `ceil`; see 4.2 |
| 12.4 / 6337 | whole frames only, never a shortened final step | accurate | `src/sim.jl:1033-1039` | `test_lifecycle.jl:94` | |
| 12.4 / 6340 | the termination record carries the actual final `t` | accurate | `src/sim.jl:276-281` | `test_lifecycle.jl:94` | |
| 12.4 / 6345 | `t_end` is a grid fact; `stop_on` is checked at every published boundary, `t*` included | accurate | `src/sim.jl:1033` vs `1026,1043`, `src/localization.jl:151` | `test_lifecycle.jl:141,162` | |
| 12.4 / 6349 | why the default is five seconds | n/a | — | — | rationale |
| 12.4 / 6353 | the cap is deployment, not trajectory-determining; outside the trace header; never compared at replay | accurate | `src/trace.jl:44-48`, `src/trace.jl:353-361` | `test_devices.jl:318` | |
| 12.4 / 6364 | the calling-task device sits outside the join; `run!` returns after the joins | accurate | `src/sim.jl:944-961` | `test_devices.jl:281` | |
| 12.4 / 6371 | the honest asymmetry: a blocking calling-task device hangs `run!` | n/a | — | — | acknowledged consequence |
| 12.4 / 6374 | the shipped GUI's render loop polls once per frame and never blocks | absent | — | — | no GUI device is shipped |
| 12.4 / 6376 | after (5) the task set is empty and `shutdown!` has released each device's resources | accurate | `src/sim.jl:972`, `src/devices.jl:354` | `test_devices.jl:173,266` | |
| 12.4 / 6379 | what survives is the roster entry: binding, claims, device id; never a task or a live resource | accurate | `src/sim.jl:535-550` (roster untouched) | `test_devices.jl:173` | |
| 12.4 / 6382 | `stopped` is where `detach!` removes an entry and releases its claims | accurate | `src/sim.jl:1263-1272`, `src/devices.jl:131-133` | `test_roster.jl:201` | |
| 12.4 / 6384 | **one roster change belongs to this tail**: the `gui = true` GUI is detached here | absent | — | — | the flag does not exist; see 4.5 |
| 12.4 / 6390 | the next `run!` re-runs device `init!`, acquisition being per-run | accurate | `src/devices.jl:374-389`, `src/sim.jl:930` | `test_devices.jl:110` (`:init` once per run) | |
| 12.4 / 6392 | it spawns fresh tasks against the re-armed §12.3 counter | accurate | `src/devices.jl:394-399` | `test_devices.jl:130` | |
| 12.4 / 6394 | while stopped there are no device tasks at all | accurate | `src/sim.jl:972` | `test_devices.jl:201` (`task_state === :none`) | |
| 12.4 / 6388 | **Rule** `init!` once per roster entry, in attachment order, on the calling task, before any spawn | accurate | `src/devices.jl:374-389`, `src/sim.jl:930-931` | `test_devices.jl:201` | |
| 12.4 / 6399 | the bracket: `shutdown!` on throw, report, mark dead, `should_abort && stop!` | accurate | `src/devices.jl:381-385` | `test_devices.jl:201` | |
| 12.4 / 6410 | why the bracket: partial acquisition released, not leaked | accurate | `src/devices.jl:382`, `src/devices.jl:325-333` | `test_devices.jl:201` | |
| 12.4 / 6414 | the report is the ordinary `DeviceCrash`, payload = device id, cause, `should_abort` | accurate | `src/dataplane.jl:102-105`, `src/devices.jl:382` | `test_devices.jl:201` | |
| 12.4 / 6418 | **Rule** written through the ordinary `report!(address, diagnostic)`, addressed by the roster entry | stand-in | `src/devices.jl:382` | `test_devices.jl:201` | the internal `_report!(cell, d)`; no `report!(entry, …)` method exists |
| 12.4 / 6426 | **Rule** no task is spawned for a failed device; dead from boundary zero | accurate | `src/devices.jl:386` | `test_devices.jl:201` | |
| 12.4 / 6430 | its cell never receives a heartbeat, so it reads stale from the first frame | accurate | `src/dataplane.jl:385-386` | `test_devices.jl:201` | |
| 12.4 / 6435 | **Rule** the claims of a failed device persist to run end | accurate | `src/devices.jl:374-389` (roster untouched) | `test_devices.jl:201` | |
| 12.4 / 6439 | the orphaned root inputs hold their initial values | accurate | `src/sim.jl:608-625` | no test | |
| 12.4 / 6443 | flag clear: the remaining entries initialize, the run starts, the device is absent from frame zero | accurate | `src/devices.jl:386-388` | `test_devices.jl:201` | |
| 12.4 / 6448 | flag set: the stop is *already pending* at boundary zero; zero frames, same tail | accurate | `src/devices.jl:383`, `src/sim.jl:1031-1032` | `test_devices.jl:201` | |
| 12.4 / 6455 | every rostered device still gets its `init!`/`shutdown!` pair uniformly | accurate | `src/devices.jl:374-389,354` | `test_devices.jl:201` | |
| 12.4 / 6457 | the run publishes boundary zero and ends `stopped` at `t₀` with the source named | accurate | `src/sim.jl:622,975-982` | `test_devices.jl:201` | |
| 12.4 / 6465 | topology is derived *after* initialization, not from the roster alone | accurate | `src/devices.jl:388`, `src/sim.jl:933` | no test | no fixture fails a `needs_calling_task` `init!` |
| 12.4 / 6468 | the shipped GUI attaches with `should_abort = true` | absent | — | — | no GUI device |
| 12.4 / 6471 | the operator interrupt is a stop: the run completes the boundary, publishes, takes the tail, ends `stopped` | short | `src/sim.jl:1058` | `test_failures.jl:114` | ends `stopped`, but the frame is abandoned mid-boundary; see 4.3 |
| 12.4 / 6479 | it needs no entry point of its own; the stop rides the control plane | stand-in | `src/sim.jl:1058` | `test_failures.jl:114` | the source is returned directly, the stop word never written; see 4.3 |
| 12.4 / 6482 | the unpaced deviceless configuration is what `UnboundedRun` names | absent | — | — | the kind is not built |
| 12.4 / 6487 | **Rule** masking across the boundary is normative | absent | — | — | no `disable_sigint` anywhere in `src/` |
| 12.4 / 6494 | the loop masks with `disable_sigint` and unmasks at frame top, wait and pause | absent | — | — | see 4.3 |
| 12.4 / 6500 | the §13.4 catch site therefore never sees the interrupt | stand-in | `src/sim.jl:1055-1059` | `test_failures.jl:114` | the catch site is the only thing that sees it |
| 12.4 / 6502 | a second interrupt during the tail collapses the remaining joins immediately | absent | `src/devices.jl:431-453` | — | `_tail!` has no interrupt handling |
| 12.4 / 6508 | interactive-session scope; the framework flips nothing process-global | accurate | — | — | nothing calls `exit_on_sigint` |
| 12.5 / 6518 | the FlightCore `user_callback!` survey and its two archetypes | n/a | — | — | prior art |
| 12.5 / 6532 | **Rule** a sim-time script becomes a component; a wall-clock interaction becomes a device | n/a | — | — | an authoring doctrine, no code obligation |
| 12.5 / 6537 | a script-as-component is periodic discrete, synchronous, replayed by recomputation with no trace | accurate | `src/build.jl:369`, `src/trace.jl:80-83` | `test_trace.jl:38` | only devices and the harness write trace records |
| 12.5 / 6543 | the four ways the component mapping is richer than the callback | n/a | — | — | worked example |
| 12.5 / 6558 | `user_callback!` is eliminated | accurate | — | — | no such construct in `src/` |
| 12.5 / 6562 | manual event triggering needs no mechanism: a root input + a boundary-detected guard | accurate | `src/build.jl:631` (`:boundary` policy) | `test_events.jl` | machinery already settled |
| 12.5 / 6570 | mid-run re-initialization is not built | accurate | — | — | correctly absent |
| 12.5 / 6577 | the doctrine: the periphery stages root-input writes and issues control commands, nothing else | accurate | `src/devices.jl:151-162,216,248` | `test_roster.jl:77` | the handle's whole surface |
| 12.6 / 6585 | five states: built, initialized, running, stopped, errored | accurate | `src/sim.jl:236`, `src/devices.jl:113` | `test_lifecycle.jl:42` | |
| 12.6 / 6587 | **built** is stores allocated, nothing authored | accurate | `src/devices.jl:116` | `test_lifecycle.jl:43` | |
| 12.6 / 6588 | **initialized** is `init!` completed boundary zero | accurate | `src/sim.jl:622-623` | `test_lifecycle.jl:53` | |
| 12.6 / 6591 | an input mode `:live`/`:replay`, read as `mode(sim)` | accurate | `src/sim.jl:254`, `src/trace.jl:143` | `test_trace.jl:552` | |
| 12.6 / 6595 | state and mode are orthogonal | accurate | `src/sim.jl:236,254` | `test_trace.jl:552,592` | |
| 12.6 / 6597 | **Rule** `init!` is mandatory | accurate | `src/sim.jl:297-304` | `test_lifecycle.jl:42` | |
| 12.6 / 6599 | the refusal is a kind naming `init!`, distinct from `UninitializedInputs` | accurate | `src/diagnostics.jl:712-719` | `test_lifecycle.jl:45-50` | |
| 12.6 / 6603 | `replay!` is the one alternative entry, running boundary zero from the header | accurate | `src/sim.jl:720-795` | `test_trace.jl:399` | |
| 12.6 / 6605 | the loop runs on the calling task unless a calling-task device is rostered | accurate | `src/sim.jl:933-961` | `test_devices.jl:281` | |
| 12.6 / 6610 | deviceless, `run!` is fully synchronous | accurate | `src/sim.jl:934-943` | `test_lifecycle.jl:94` | |
| 12.6 / 6614 | `step!(sim; frames = 1)` advances whole frames synchronously through the ordinary sequence | accurate | `src/sim.jl:1116-1162` | `test_lifecycle.jl:184` | |
| 12.6 / 6616 | a stepped simulation is bit-identical to the same frames under `run!` | accurate | `src/sim.jl:1023` (one shared loop) | `test_lifecycle.jl:196-200` | |
| 12.6 / 6618 | `step!(sim; t_plus)`, mutually exclusive with `frames`, whole frames until the time covers the duration | accurate | `src/sim.jl:1119-1130` | `test_lifecycle.jl:187,204` | |
| 12.6 / 6623 | partial advance is the test-harness and REPL register | n/a | — | — | rationale |
| 12.6 / 6627 | a stepping session is deviceless; `attach!` is legal between calls; the task appears at the next `run!` | accurate | `src/sim.jl:1116-1162` (no spawn), `src/devices.jl:131-133` | `test_roster.jl:201` | |
| 12.6 / 6633 | the frame-top drain still runs under `step!` | accurate | `src/sim.jl:1037` | `test_lifecycle.jl:184` | |
| 12.6 / 6634 | what it drains is the harness cell; the write path is `stage!(sim, …)` | accurate | `src/sim.jl:1294-1300,1337` | `test_roster.jl:142` | |
| 12.6 / 6638 | staged batches are ordinary: traced, replayable, applied at the next frame top, surface-checked | accurate | `src/sim.jl:1294-1300,1326-1345` | `test_roster.jl:142,223`, `test_trace.jl:38` | |
| 12.6 / 6642 | the read half is `latest(sim)`, the same snapshot value a handle acquires | accurate | `src/sim.jl:1476`, `src/devices.jl:236` | `test_devices.jl:130` | |
| 12.6 / 6646 | both entry points work under `run!`; the harness cell is not step-scoped | accurate | `src/sim.jl:1294`, `src/roster.jl` harness register | `test_lifecycle.jl:67` | |
| 12.6 / 6651 | between `step!` calls the simulation reports **initialized** | accurate | `src/sim.jl:1155-1157` | `test_lifecycle.jl:188` | |
| 12.6 / 6656 | `run!` may follow `step!`, continuing from the current boundary; so may another `step!` | accurate | `src/sim.jl:297-304` | `test_lifecycle.jl:184` | |
| 12.6 / 6658 | termination policy is honored throughout: a `t_end` or `stop_on` hit inside `step!` ends the run there | accurate | `src/sim.jl:1150-1160` | `test_lifecycle.jl:189,212` | |
| 12.6 / 6663 | `step!` returns the number of frames actually advanced | accurate | `src/sim.jl:1162` | `test_lifecycle.jl:184-190,212` | |
| 12.6 / 6668 | `stopped → init! → run!` is the supported cycle; `init!` re-runs boundary zero | accurate | `src/sim.jl:608-625` | `test_lifecycle.jl:62` | |
| 12.6 / 6670 | `init!` clears the trace, the log, the termination record, and staged batches | accurate | `src/sim.jl:535-550,618` | `test_log.jl:113`, `test_trace.jl:99`, `test_devices.jl:126`, `test_lifecycle.jl:64` | |
| 12.6 / 6674 | `init!` returns the input mode to `:live` | accurate | `src/trace.jl:157-165` | `test_trace.jl:592` | |
| 12.6 / 6675 | a fresh `replay!` sets the mode as it sets the trajectory | accurate | `src/sim.jl:786-787` | `test_trace.jl:552` | |
| 12.6 / 6676 | `live!` is the third door, the only one moving the mode alone | accurate | `src/sim.jl:822-830` | `test_trace.jl:629` | |
| 12.6 / 6678 | a terminal state makes the mode moot: nothing advances until one of the three doors is taken | accurate | `src/sim.jl:297-304` | `test_trace.jl:666,815` | |
| 12.6 / 6681 | device attachments persist across re-initialization: binding, claims, id survive; tasks do not | accurate | `src/sim.jl:535-550,972` | no direct test | `init!` never touches `plane.roster` |
| 12.6 / 6687 | each `run!` re-initializes every rostered device and spawns its task | accurate | `src/sim.jl:930-935` | `test_devices.jl:110` | |
| 12.6 / 6688 | `attach!` while stopped only registers | accurate | `src/sim.jl:1213-1252` | `test_roster.jl:201` | |
| 12.6 / 6690 | task topology follows the roster each time | accurate | `src/sim.jl:933-961` | `test_devices.jl:281` | the GUI half of the sentence is moot |
| 12.6 / 6694 | **the `gui = true` flag**: run-scoped, attaches the standard GUI greedily with `should_abort = true` iff none is rostered | absent | — | — | see 4.5 |
| 12.6 / 6697 | the shutdown tail detaches it again | absent | — | — | see 4.5 |
| 12.6 / 6700 | a persistent GUI session is spelled by hand: `attach!` while stopped, `detach!` when done | accurate | `src/sim.jl:1213,1263` | `test_roster.jl:201` | the mechanism exists; the GUI does not |
| 12.6 / 6703 | what the scoping buys: no everything-claim outliving its run | n/a | — | — | rationale |
| 12.6 / 6708 | the accepted cost: a fresh device id per run for that GUI | n/a | — | — | rationale |
| 12.6 / 6711 | run policy is re-bindable per cycle: `run!` may override `t_end` and `stop_on` | accurate | `src/sim.jl:876-881` | `test_lifecycle.jl:94,174` | |
| 12.6 / 6713 | `errored` is terminal; reproduction is trace replay, not resurrection | accurate | `src/sim.jl:301-304,967-970` | `test_lifecycle.jl:222`, `test_trace.jl:815` | |
| 12.7 / 6719 | the four-call surface: `trace(sim)`, `Simulation(world)`, `replay!`, `replay!` with a halt | accurate | `src/sim.jl:1518,720` | `test_trace.jl:399,460,482` | |
| 12.7 / 6727 | `replay!` is the ordinary loop with exactly two substitutions, not a second loop | accurate | `src/sim.jl:794` (shares `_run_body!`) | `test_trace.jl:399` | |
| 12.7 / 6731 | boundary zero from the header: stores and root inputs applied directly, no resolution, totality by capture | accurate | `src/sim.jl:770-780` | `test_trace.jl:399` | |
| 12.7 / 6737 | it then executes the ordinary boundary-zero sequence | accurate | `src/sim.jl:782-783` | `test_trace.jl:399` | |
| 12.7 / 6738 | authored-condition events re-fire identically; the header predates the sequence | accurate | `src/sim.jl:619-621`, `src/trace.jl:20-23` | `test_trace.jl:75,399` | |
| 12.7 / 6741 | the drain reads the trace by frame ordinal; it does not swap the roster's staging cells | accurate | `src/sim.jl:1366-1397` | `test_trace.jl:399,721` | |
| 12.7 / 6746 | ordinal keying is exact: frame *k* of the replay is frame *k* of the recording | accurate | `src/sim.jl:1368,1382-1391` | `test_trace.jl:310,399` | |
| 12.7 / 6748 | recorded batches apply verbatim, with no surface re-check | accurate | `src/trace.jl:412-465` | `test_trace.jl:441` | claims are never reconstructed |
| 12.7 / 6751 | **Rule** the mode decides which source the one drain branch reads; one loop, one drain | accurate | `src/sim.jl:1332`, `src/sim.jl:786-787` | `test_trace.jl:552` | |
| 12.7 / 6759 | why a mode that outlives the call | n/a | — | — | rationale |
| 12.7 / 6767 | in `:replay` every advance's frame budget is capped at the recording's last frame | accurate | `src/sim.jl:893-895` | `test_trace.jl:552,579` | |
| 12.7 / 6769 | `to_boundary = k` caps it earlier | accurate | `src/sim.jl:736-740,793` | `test_trace.jl:460`, `test_failures.jl:264` | |
| 12.7 / 6771 | `to_boundary` runs *through* the frame that published boundary `k`; replay halts at a frame top | accurate | `src/sim.jl:793,1034` | `test_trace.jl:460` | |
| 12.7 / 6776 | a localized `t*` boundary is reproduced but not stoppable-at | accurate | `src/sim.jl:1034` (frames only) | `test_failures.jl:264` | |
| 12.7 / 6779 | replay may end earlier under `t_end`/`stop_on` overrides, which bind as at `run!` | accurate | `src/sim.jl:754-757,793` | no test | no test passes either keyword to `replay!` |
| 12.7 / 6784 | `to_time` is mutually exclusive with `to_boundary` and floors onto the earlier frame top | accurate | `src/sim.jl:733-735,741-753` | `test_trace.jl:482,516` | a 1e-9 frame slack guards binary-float on-grid times |
| 12.7 / 6790 | the rounding is the deliberate opposite of `t_end`'s reach-or-exceed | short | `src/sim.jl:753` vs `src/sim.jl:891` | `test_trace.jl:482` | the `to_time` half is right, the `t_end` half is not; see 4.2 |
| 12.7 / 6795 | `to_time` validation: real, finite, ≥ `t₀`, covered by the recording, before any write | accurate | `src/sim.jl:749-753` | `test_trace.jl:516` | |
| 12.7 / 6800 | the mode flips to `:live` exactly at the recording's last frame, and stays `:replay` otherwise | accurate | `src/sim.jl:903-911` | `test_trace.jl:552,579` | |
| 12.7 / 6805 | a `run!` past the recording halts at the last recorded frame; the next call is the live continuation | accurate | `src/sim.jl:893-895,975-978` | `test_trace.jl:608` | |
| 12.7 / 6809 | `live!(sim)` sets the mode `:live` and detaches the remainder, touching nothing else | accurate | `src/sim.jl:822-830` | `test_trace.jl:629` | |
| 12.7 / 6814 | `live!` is legal only on an `initialized` simulation in `:replay`; every other case refuses loudly | accurate | `src/sim.jl:823-826` | `test_trace.jl:666` | |
| 12.7 / 6821 | the rewrite-workflow worked example | n/a | — | — | example |
| 12.7 / 6838 | replay ends `initialized`, never `stopped` | accurate | `src/sim.jl:977-979` | `test_trace.jl:460,552` | |
| 12.7 / 6841 | the three workflows: state inspection, error reproduction, continuation | accurate | `src/sim.jl:720-795` | `test_failures.jl:251`, `test_trace.jl:608` | |
| 12.7 / 6853 | replay re-records: the new trace inherits the old header, a bit-identical prefix | accurate | `src/sim.jl:785-789`, `src/sim.jl:1388-1390` | `test_trace.jl:629` | |
| 12.7 / 6858 | pacing and the control plane are unchanged under replay | short | `src/sim.jl:794` | — | the control plane is; there is no pacing to leave unchanged |
| 12.7 / 6863 | devices are readers: rostered devices init and spawn normally and consume snapshots | accurate | `src/sim.jl:924-961` (shared body) | `test_trace.jl:721` | |
| 12.7 / 6866 | no live staging cell is drained in `:replay`; a staged batch is discarded under `ReplayDiscardedStaging`, rate-limited | accurate | `src/sim.jl:1399-1406`, `src/dataplane.jl:129-132` | `test_trace.jl:721,763` | |
| 12.7 / 6873 | the header is validated against the `Build` (store layout, root input faces) before the first frame | accurate | `src/trace.jl:327-349` | `test_trace.jl:209` | |
| 12.7 / 6874 | the trace's batch entries are validated against the root input-face list | accurate | `src/trace.jl:370-378,433-455` | `test_trace.jl:246,265` | |
| 12.7 / 6875 | each batch's frame ordinal is validated against the recording's length | accurate | `src/trace.jl:419-429` | `test_trace.jl:289` | |
| 12.7 / 6876 | each writer's face-name → position schema is validated; disagreement is a replay error | accurate | `src/trace.jl:370-378` | `test_trace.jl:246` | |
| 12.7 / 6879 | the checks are attach-style, and a failure reports did-you-mean | accurate | `src/diagnostics.jl:1397-1423` | `test_trace.jl:246,265` | offending name plus the list-in-hand, as payload |
| 12.7 / 6881 | the kinds are `ReplayHeaderMismatch`, `ReplaySchemaMismatch`, `ReplayUnknownFace` | accurate | `src/diagnostics.jl:1356,1397,1411` | `test_trace.jl:209,246,265` | |
| 12.7 / 6884 | the same pass normalizes the sparse records to positional batches, once, off the loop | accurate | `src/trace.jl:412-465` | `test_trace.jl:310` | |
| 12.7 / 6888 | the replay drain applies compiled scatters; no face name is resolved per frame | accurate | `src/sim.jl:1382-1391`, `src/trace.jl:383` | `test_trace.jl:310` | |
| 12.7 / 6891 | structural mismatch is an error; parametric difference is the what-if register | accurate | `src/trace.jl:327-364` | `test_trace.jl:798` | |
| 12.7 / 6898 | the deployment block validates in the same pass, on the structural side | accurate | `src/trace.jl:353-361` | `test_trace.jl:209` | |
| 12.7 / 6900 | all seven trajectory-determining parameters are compared against the target's binding | accurate | `src/trace.jl:353-361` | `test_trace.jl:209` | `Δt_base`, `h`, `n`, method, both localization keys, `firing_budget` |
| 12.7 / 6903 | mismatch is `ReplayHeaderMismatch` with a deployment-parameter discriminator | accurate | `src/trace.jl:359-361`, `src/diagnostics.jl:1357` | `test_trace.jl:209` | |
| 12.7 / 6911 | `t₀` is applied, not compared; `replay!` takes no `t0` argument | accurate | `src/sim.jl:720,781` | `test_trace.jl:399` | |
| 12.7 / 6913 | the header's `t_end`/`stop_on` pair is neither compared nor applied | accurate | `src/trace.jl:327-364` | `test_trace.jl:209` | recorded in the header, never read back |
| 12.7 / 6916 | the disposition table | n/a | — | — | a restatement of the six rows above |
| 12.7 / 6921 | rejected shapes: a `run!(replay = trc)` flag, a playback device, replay ending `stopped` | n/a | — | — | rejected alternatives |

## 4. Deviations in detail

### 4.1 The wrapper does not treat an `unblock!`-induced raise as shutdown

§12.4(3), line 6270: "The hook is `unblock!(device)`, default no-op. A network
input's override closes its own socket, which raises in the blocked task. **The
framework wrapper catches that raise and treats it as shutdown.**"

`_wrap` (`src/devices.jl:348-358`) catches every throw out of `loop` and files
`DeviceCrash(err, e.should_abort)` into the device's own cell. It does not
consult the sticky stopped status, so it cannot tell a shutdown-provoked raise
from a genuine crash. The obligation is silently transferred to the author: the
suite's own `Blocked` fixture (`test/test_devices.jl:76-83`) carries a
`try … catch; break` around its `take!` with the comment "the raise is
shutdown, not a crash", which is exactly the discrimination the spec assigns to
the framework.

Probe (`p3.jl`): a device whose `unblock!` closes its channel and whose loop
body is the plain `while running(h); take!(d.ch); end`, run to a clean `t_end`.
Output:

```
┌ Warning: DeviceCrash from device 1 (Naive), past the final snapshot's account:
│ DeviceCrash(InvalidStateException("Channel is closed.", :closed), false)
source=Cadence.EndTimeReached()
residue writer=device 1 (Naive) recent=DataType[DeviceCrash]
```

Why it matters: an ordinary, correct shutdown of an author-conforming device
produces a warning and a `DeviceCrash` in the termination record on every run.
With `should_abort = true` it would also request a stop, harmless at that
moment but misattributed. The diagnostic account of a clean run is wrong.

### 4.2 `t_end` is taken to the nearest frame, not the first frame reaching it

§12.4, line 6335: "**`t_end` lands on the grid.** The run ends at the first
grid boundary whose time reaches or exceeds `t_end`. … The final boundary may
therefore overshoot `t_end` by up to `h`."

All three advance entries compute the target frame with `round`:
`src/sim.jl:891` (`run!`), `src/sim.jl:1136` (`step!`) and `src/sim.jl:793`
(`replay!`), each `round(Int, te / sim.h)`. The rule asks for `ceil`. With
`round`, a `t_end` whose fractional frame part is below one half ends the run
*short* of the bound, by up to `h/2`, instead of overshooting it by up to `h`.

Probe (`p1.jl`), `h = 1//10`:

```
t_end=0.54 -> final t=0.5 step=5
t_end=0.55 -> final t=0.6 step=6
t_end=0.56 -> final t=0.6 step=6
t_end=0.5  -> final t=0.5 step=5
t_end=0.501-> final t=0.5 step=5
```

`t_end = 0.54` ends at `t = 0.5`. Why it matters: the run does not cover the
duration the caller asked for, and the termination record reports
`EndTimeReached` at a time that never reached the end time. The existing test
(`test_lifecycle.jl:94`) only uses grid-aligned bounds (`1.0`, `0.5` at
`h = 1/50`), where `round` and `ceil` agree, so nothing catches it. §12.7 at
line 6790 leans on this rule when it contrasts `to_time`'s flooring with
`t_end`'s: the contrast is only half real in the code.

### 4.3 The operator interrupt: no masking, and the stop word is bypassed

§12.4, line 6487: "**Rule.** Masking across the boundary is normative, not an
implementation hint." Line 6494: "The loop masks delivery across the boundary
macro-sequence, using Julia's `disable_sigint` … It takes the deferred raise at
the unmask points: the frame top … and inside its wait and pause blocks. All of
those points are boundary-consistent. Caught at one of them, the interrupt sets
the control-plane stop and enters this tail. The catch site ([§13.4]) therefore
never sees it."

Nothing in `src/` calls `disable_sigint` or `reenable_sigint`. What exists is
the defensive branch at `src/sim.jl:1055-1059`:

```julia
err isa InterruptException && return (ControlRequestedStop(:interrupt), adv)
```

Its own comment is candid: "The frame is abandoned unpublished and the stores
may be mid-boundary — this is the masked guarantee without the masking". Three
consequences follow. (a) The run ends `stopped` and the previously published
snapshot is final, so a consumer of snapshots sees a consistent world, but the
*live* stores are left mid-sequence — the very state §12.4 says the masking
buys against, and `capture`/`state(sim, …)` read those stores after the run.
(b) The catch site is precisely what sees the interrupt, contradicting line
6500. (c) The stop word is never written: `_request_stop!` is not called, and
the termination source is returned directly. So an interrupt arriving after a
device or `stop!(sim)` already won the CAS at `src/devices.jl:121-122` reports
`ControlRequestedStop(:interrupt)` rather than the first issuer, breaking
§12.1's first-writer-wins rule (line 6092) for that one issuer. Line 6502's
second-interrupt escalation in the tail is not built either.

### 4.4 No thread-budget check at `run!`

§12.2, line 6140: "**Rule.** The thread budget is a documented sizing rule and
a **startup warning**, not a hard error"; line 6154: "`run!` warns when
`Threads.nthreads()` is tight for the attached population, naming the `julia
-t` remedy. That is one check per run, against the frozen roster."

`grep -rn "nthreads" src/` returns nothing. `run!` performs no such check.
D-027 ratifies the rule ("thread budget = sizing rule + startup warning") and
rejects only the hard error, so the log does not settle the absence. Why it
matters: the failure mode the spec accepts — an undersized session degrading to
laggy inputs and stale snapshots — is now undiagnosed at its cause. The
liveness heartbeat still shows the symptom, so this is a missing hint rather
than a missing guarantee.

### 4.5 The `gui = true` flag and the tail's one roster mutation

§12.4, line 6384: "**One roster change belongs to this tail.** A GUI attached
by `run!`'s `gui = true` is detached here, releasing its computed claim … It is
the only roster mutation the protocol itself performs." §12.6, line 6694:
"**The `gui = true` flag itself is run-scoped.** At run entry it attaches the
standard GUI device under the greedy binding, with `should_abort = true`, iff
no GUI is rostered."

`run!` takes only `t_end` and `stop_on` (`src/sim.jl:875`), and no GUI device
type exists anywhere in `src/`. The tail therefore performs no roster mutation
at all. Everything the flag is *made of* is built and tested — the greedy
computed claim (`src/roster.jl`, `test_roster.jl:111`), `should_abort`
(`test_devices.jl:190`), `attach!`/`detach!` while stopped
(`test_roster.jl:201`) — so this is a convenience entry point missing over a
complete substrate, not a hole in the protocol. Its absence also makes the
§12.4 sentences about the shipped GUI's polling render loop (line 6374) and its
`should_abort = true` attachment (line 6468) unbacked.

### 4.6 Pause is absent, and takes three §12.4 and §12.1 claims with it

§12.1 lists pause and un-pause among the control plane's scalar fields (line
6079) and says the paused loop blocks on a condition notified by un-pause and
stop (line 6104). §12.4(2) requires the tail to wake the pause as well as the
next-snapshot wait, "so a stop issued while paused therefore works" (line 6267).
None of it is built: `Control` (`src/devices.jl:108-116`) has `stop_issuer`,
`stopped`, `cond`, `counter`, `lifecycle` and `termination` and nothing else,
and `_finish!` wakes the one condition it has. The §12.2 pacing rules (coarse
`sleep`, the spin phase's non-yielding, the pacer diagnostics beside the
liveness record) fall the same way. This is an absence rather than a wrong
result — nothing claims to pause and fails — but it is the largest single block
of unbuilt obligation in the slice.

## 5. Tally

| verdict | count |
|---|---|
| accurate | 146 |
| short | 5 |
| stand-in | 4 |
| absent | 20 |
| n/a | 18 |
| **total** | **193** |

## 6. Friction

- **The snapshot's boundary ordinal is session-global, not per-trajectory.**
  `Snapshot.boundary` (`src/dataplane.jl:567`) is stamped from the control
  plane's counter, which `init!` never resets. A probe (`p2.jl`) shows the
  second trajectory of the same `Simulation` opening at `boundary = 6` and the
  log's first entry reading `6` rather than `0`. §12.3's glossary entry calls
  the counter "the monotonic count of published boundaries" and mandates no
  reset, and nothing in the code keys off the absolute value, so I scored the
  claim accurate. But the field's own comment says "boundary zero = 0", which
  holds only for a simulation's first trajectory, and §12.3's "any holder of
  one therefore indexes it without consulting the loop" reads more naturally as
  a per-trajectory index. Two readings fit; the coordinator may want a ruling.
- **"The framework wrapper catches that raise and treats it as shutdown"** (line
  6273) is the one sentence in the slice I had to probe rather than read,
  because the fixture at `test/test_devices.jl:76-83` performs the
  discrimination in the *device* and its testset name ("a clean exit, no
  timeout") promises the framework behaviour the spec describes. The test
  passes; the obligation it appears to cover is not the framework's.
- `test_lifecycle.jl:94`'s name — "t_end: constructor default, run! override,
  and a bound owed from some site" — promises more of §12.4's grid rule than it
  checks: every `t_end` it uses is grid-aligned, which is exactly the case where
  the `round`/`ceil` deviation of 4.2 is invisible.
- §12.4 mixes normative rules with the tail's narration at a fine grain; step
  (1) alone carries four separately checkable claims and step (5) three. Slicing
  it one claim per row was the least mechanical part of this audit, and another
  reader would plausibly land on a different count.
- No test passes `t_end` or `stop_on` to `replay!`, though §12.7 line 6779
  makes the binding normative and `src/sim.jl:754-757` implements it.
