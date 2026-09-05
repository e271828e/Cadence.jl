# Agent E — §11, the runtime periphery data plane

**Slice**: `docs/design/spec.md` §11 (11.1–11.8), lines 4715–6069.
**Tip**: `70672d1`. Julia 1.12.7.
**Probes run**: yes, two, from `scratchpad/agentE/` with `julia --project=.`
from the repository root (allocation accounting at `publish!` and `drain!`).
**Forbidden reads**: none. I read `docs/design/spec.md` (my range and the
passages it cites for meaning), all of `src/` and `test/`, and the
"What is real here" file table in `docs/design/implementation.md`. I did not
open `pending.md`, `briefs/`, the top-level `reports/`, or any other report in
this directory.

## Summary

The data plane is the best-built chapter I could have drawn. §11.1–§11.6 and
§11.8 are implemented close to the letter, in the spec's own shapes and with
the spec's own names: staging cells with a CAS merge, a frame-top
`atomicswap` drain applying an attach-compiled scatter, snapshot publication
through a single release-store, the log as retained references with amortized
re-decimation, one sparse trace record per drained batch behind a header
captured at `init!`, the three-part roster admission, the bidirectional
binding conformance check, and one diagnostic cell per writer with a
sixteen-deep ring and a per-kind isbits counter record. The allocation claims
are pinned by tests rather than asserted, and the log's three normative
guarantees are checked frame by frame over 128 frames.

The gaps cluster in three places, and they are of different weights.

**One, §11.7 is entirely absent.** No GUI, no panel walk, no port-to-root-input
feed-chain resolution, no derived liveness, no peek, no widget staging
contract, no orphan rendering. Nothing in `src/` looks at a port and answers
"is this transitively driven by a root input, and which one?". That is the
single largest hole in the slice, and it takes with it every §11.2/§11.3
sentence that reaches forward into the GUI (the peek fallback, the read-only
mirrors under joystick claim, "a released root input's widgets are live again
from the next run"). The shipped GUI device and its greedy binding are absent
with it; the *mechanism* they were the paradigm case for — `is_greedy`, the
computed complement — is fully built and tested against fixture devices.

**Two, the wrapper's interrupt discrimination is missing.** §11.6 spends a
paragraph on "an `InterruptException` is never a `DeviceCrash`", and
`_wrap` (`src/devices.jl:348`) catches every exception uniformly and reports
`DeviceCrash` with a `should_abort` consultation behind it. Under the
calling-task topology the inline body is on the task an operator Ctrl-C hits,
so this is the exact case the spec carves out. The loop's own catch site has
its carve-out (`src/sim.jl:1058`); the wrapper's does not.

**Three, small honest shortfalls in the published status and in the attach-time
did-you-mean.** The framework status carries no pacer diagnostics (the pacer
is absent, §10.7), the heartbeat is acquire-loaded at publication rather than
at the drain, `maxlog`'s 25-occurrence presentation rule has no renderer to
live in, and the status assembly allocates ~430 B per boundary on a quiet
frame where §11.8 promises it "rides inline in the one per-boundary snapshot
allocation". The output-binding resolution names the offending selector but
carries the list-in-hand for only one of its three failure modes.

What surprised me, in the good direction: the recompilation seam
(`reclaim!`, `src/roster.jl:230`) is built exactly as §11.4 describes it,
including the renormalization of a pending harness batch across an `attach!`,
with a `site` field on `ClaimedFaceEntry` distinguishing it from ordinary
staging. That is a corner the spec mentions once and the code takes seriously.
Also `_install_writers!` (`src/trace.jl:236`) implements the only-growing
schema list by rebuilding the header rather than mutating it, so a `Trace`
already handed out keeps a valid prefix — a subtlety §11.5 implies and does
not spell out.

## Findings

| § (line) | claim | verdict | location | test | note |
| --- | --- | --- | --- | --- | --- |
| 11.1 (4734–4744) | FlightCore's `io_lock`, D-022's three costs | n/a | — | — | rationale |
| 11.1 (4746–4751) | the frame is the unit of account: drain, integrate, boundary sequence, publication; `step!` counts frames | accurate | `sim.jl:1041–1058` | `test_dataplane.jl:17` | |
| 11.1 (4753) | plane 1: devices stage at any wall-clock moment, never touching live root inputs | accurate | `dataplane.jl:510–518`, `devices.jl:248` | `test_dataplane.jl:157` | |
| 11.1 (4755–4757) | plane 2: exactly one drain per frame, at its top, never at a `t*` boundary | accurate | `sim.jl:1326–1348`, `sim.jl:1050` | `test_log.jl:8` | |
| 11.1 (4757) | between drains the loop owns its data; no lock held during stepping | accurate | `sim.jl:1426–1444` | no test | the only lock is `ctl.cond`, taken after the release-store |
| 11.1 (4759) | plane 3: an immutable snapshot per boundary sequence, read without coordinating | accurate | `sim.jl:1426–1444`, `dataplane.jl:563–578` | `test_dataplane.jl:99,129` | |
| 11.1 (4762) | plane 4: pause, pace and stop on a few-word atomic surface | short | `devices.jl:108–116` | `test_devices.jl:155` | stop word built; pause and pacing absent (§12.1) |
| 11.1 (4764) | plane 5: one loop, one task per rostered device except the calling-task device, run-scoped | accurate | `sim.jl:938–962`, `devices.jl:394–399` | `test_devices.jl:281` | |
| 11.1 (4770–4773) | `run!` spawns after device `init!`; `attach!` never spawns | accurate | `sim.jl:937–941`, `sim.jl:1213` | `test_devices.jl:201` | |
| 11.1 (4775–4788) | calling-task device pinned, the loop moves to a spawned task; the topology table | accurate | `sim.jl:944–962` | `test_devices.jl:281` | |
| 11.1 (4778) | the shipped GUI declares `needs_calling_task` | absent | — | — | no shipped GUI; the trait and its single-slot check exist |
| 11.1 (4790–4797) | `run!` blocks its caller until the run ends, either topology | accurate | `sim.jl:955` (`fetch(loop_task)`) | `test_devices.jl:281` | |
| 11.1 (4799–4802) | topology derived after initialization, from the roster plus `init!` outcomes | accurate | `sim.jl:937–944` | `test_devices.jl:201` | |
| 11.1 (4804–4808) | spawn-inside-`run!`; first-boundary sync is the counter-plus-condition wait, never a `Base.Event` | accurate | `devices.jl:306–319`, `394–399` | `test_devices.jl:130` | |
| 11.1 (4810–4817) | every handoff is one atomic reference operation on a single word | accurate | `dataplane.jl:24–26`, `254–257`, `578–581` | no test | the batch rides boxed in a `Ref`, so width does not widen the handoff |
| 11.1 (4819–4826) | no user code and no unbounded work inside a framework critical section | accurate | `dataplane.jl:521–530` (drain is pure application) | `test_dataplane.jl:68` | mappings run on device tasks by construction |
| 11.1 (4828–4831) | interactive and unattended stop being different modes | n/a | — | — | consequence, not an obligation |
| 11.2 (4844–4849) | snapshot built private, published by one release-store to `@atomic latest`; carries the table, `t`, the framework status | accurate | `sim.jl:1426–1444`, `dataplane.jl:563–578` | `test_dataplane.jl:99` | |
| 11.2 (4849–4850) | the calling task reads the same value through `latest(sim)` | accurate | `sim.jl:1470` | `test_log.jl:29` | |
| 11.2 (4852–4855) | the exchange is wait-free in both directions | accurate | `sim.jl:1430–1441` | `test_dataplane.jl:129` | |
| 11.2 (4856) | publication only after the boundary sequence completes | accurate | `sim.jl:1052–1056` | `test_log.jl:8` | |
| 11.2 (4858–4861) | binding rule: nothing reachable from a published snapshot is written again | accurate | `dataplane.jl:582` (`capture`), `sim.jl:1447–1450` | `test_dataplane.jl:129` | the status's `recent` vector is *taken* from the account |
| 11.2 (4863–4869) | the framework status carries the pacer diagnostics beside the per-writer records | absent | — | — | see 4.1 |
| 11.2 (4866–4867) | the status carries per-writer batches, suppressed and cumulative counters, and liveness timestamps taken at frame top | short | `dataplane.jl:351–358`, `sim.jl:1456–1465` | `test_diagnostics.jl:103` | timestamps acquire-loaded at publication, not at the drain; see 4.2 |
| 11.2 (4871–4877) | the captured table is the whole table, every cell public, nothing to filter | accurate | `dataplane.jl:582`, `sim.jl:1428` | `test_log.jl:29` | |
| 11.2 (4877–4879) | promotion to a declared output is the inspection path for a private intermediate | n/a | — | — | doctrine |
| 11.2 (4880–4883) | the captured table also includes the root inputs | accurate | root inputs are layout cells; `capture` copies every store | `test_trace.jl:75` | |
| 11.2 (4884–4887) | the §11.7 peek falls back to the snapshot; read-only mirrors of claimed root inputs | absent | — | — | §11.7 absent entirely |
| 11.2 (4889–4896) | the snapshot deliberately does not carry `x`, `s`, `m` | accurate | `dataplane.jl:568–575` | `test_readers.jl` (store selectors refused) | enforced downstream at `_resolve_read` |
| 11.2 (4894–4896) | checkpoints and a dev-mode auto-publish flag are guarded additions | n/a | — | — | future work |
| 11.2 (4899–4905) | the log is retained snapshot references, zero extra copies; one snapshot allocation per boundary | accurate | `dataplane.jl:614–637`, `sim.jl:1431` | `test_log.jl:29` | |
| 11.2 (4907–4915) | retention: the plain switch plus `log_every` | accurate | `dataplane.jl:641–654`, `sim.jl:151–152` | `test_log.jl:43,90` | |
| 11.2 (4924–4926) | `log_max`, default 65536, `Inf` the explicit opt-out | accurate | `sim.jl:135,153–154,175` | `test_log.jl:137` | |
| 11.2 (4928–4933) | a count, not a memory budget | n/a | — | — | rationale |
| 11.2 (4935–4938) | the default is finite unconditionally, not keyed on `t_end` | accurate | `sim.jl:135` | `test_log.jl:137` | |
| 11.2 (4940–4945) | when the log fills the stride doubles; re-decimation is progressive, not a rolling window | accurate | `dataplane.jl:665–685` | `test_log.jl:62` | |
| 11.2 (4953–4956) | three guarantees: bound respected continuously, coverage global at `log_every·2^k`, endpoints kept | accurate | `dataplane.jl:665–685` | `test_log.jl:62` | asserted at every intermediate state over 128 frames |
| 11.2 (4958–4970) | mechanism sketch: one predecessor released per retained append, compaction once per generation | accurate | `dataplane.jl:672–681` | `test_log.jl:62` | non-binding, but built as sketched |
| 11.2 (4972–4978) | endpoints retained unconditionally and outside the bound; the terminal snapshot's status carries the final counters | accurate | `dataplane.jl:645–651`, `sim.jl:1491–1510` | `test_log.jl:53` | |
| 11.2 (4980–4983) | `totals` monotonicity survives decimation; `log_max` is a view policy, outside the trace header | accurate | `trace.jl:41–47` (no log fields), `dataplane.jl:355` | `test_log.jl:98` | |
| 11.2 (4984–4987) | the `sizehint!` for the expected duration, capped by `log_max` | absent | — | — | no `sizehint!` anywhere in `src/`; §7.5 owns the hint |
| 11.2 (4990–4993) | output-device bindings are snapshot bindings, consumed via §12.3 | accurate | `devices.jl:267–272,306–319` | `test_bindings.jl:220` | |
| 11.2 (4993–4995) | addressed with the §14.4 selectors, reaching any cell, deep paths in the diagnostic register | accurate | `bindings.jl:157–187` | `test_bindings.jl:197` | |
| 11.2 (4995–4997) | resolved at attach against the `Build` with did-you-mean (offending name plus list-in-hand) | short | `bindings.jl:161–187`, `diagnostics.jl:940–971` | `test_bindings.jl:197` | see 4.3 |
| 11.2 (4997–5000) | compiled to one gather; `map_output` receives a labeled NamedTuple keyed by `reads`' names | accurate | `bindings.jl:121–149`, `devices.jl:267–272` | `test_bindings.jl:220` | |
| 11.2 (5002–5008) | this is diagnostic observation, no effect on run semantics | n/a | — | — | register statement |
| 11.2 (5010–5017) | a binding chooses its register: deep path vs. `get_face(name)` | accurate | `bindings.jl:161–187`, `readers.jl` (`GetFace`) | `test_bindings.jl:197` | |
| 11.2 (5019–5028) | why the choice matters; wrapper types make face semantics checkable | n/a | — | — | rationale |
| 11.3 (5032–5040) | the write surface is root inputs; a root input is the root component's own input face | accurate | `roster.jl:200`, `dataplane.jl:428` | `test_roster.jl:77` | |
| 11.3 (5042–5047) | reading a root input as the invisible producer's output face | n/a | — | — | rationale |
| 11.3 (5049–5051) | root inputs are scheduler sources, constants within a frame, the only thing the periphery may write | accurate | `dataplane.jl:521–530` | `test_dataplane.jl:17` | |
| 11.3 (5051–5057) | the write side speaks root-contract face names only; slash paths never cross it | accurate | `dataplane.jl:456–479` (`Symbol(face)` against `w.faces`) | `test_roster.jl:77` | |
| 11.3 (5059–5062) | root-input exclusivity: one writer per root input; claiming a claimed root input is an attach-time error | accurate | `sim.jl:1233–1238` | `test_roster.jl:52` | `ClaimConflict` |
| 11.3 (5062–5064) | detaching releases the claims; the released root input's GUI widgets are live again from the next run | short | `sim.jl:1263–1276`, `roster.jl:230–237` | `test_roster.jl:142` | release built; the widget half is §11.7, absent |
| 11.3 (5064–5066) | exclusivity replaces any cross-device conflict policy; cells, CAS merge and atomicswap stay | accurate | `dataplane.jl:510–546` | `test_dataplane.jl:56` | |
| 11.3 (5068–5078) | a claim is what a device may write; a data-dependent writer claims the binding's enumerated set | accurate | `roster.jl:199–210`, `bindings.jl:72` | `test_bindings.jl:91` | |
| 11.3 (5076–5078) | a broad claim costs liveness: the derived-liveness rule renders the widget read-only | absent | — | — | §11.7 absent |
| 11.3 (5080–5087) | a batch entry reaches a root input iff the face is inside the writer's surface; else discarded with a runtime warning; enforcement entirely at staging; the drain performs no checks | accurate | `dataplane.jl:456–479`, `521–546` | `test_dataplane.jl:68` | |
| 11.3 (5089–5097) | returned claim source: `is_input`, `claims(b)` called once at attach, faces staked; drift is `OutOfClaimEntry`, never a silent write | accurate | `roster.jl:203–209`, `sim.jl:1232` | `test_roster.jl:77` | |
| 11.3 (5098–5104) | computed claim source: `is_greedy`, all root faces minus the union of rostered claims at that instant | accurate | `roster.jl:201` | `test_roster.jl:111` | |
| 11.3 (5106–5120) | the source is exhausted at attach; everything downstream is blind to it; attaching the greedy claimant last is the idiom; no opportunistic writing | accurate | `roster.jl:120–130`, `sim.jl:1232–1247` | `test_roster.jl:111` | |
| 11.3 (5122–5127) | the harness register: task-free `stage!(sim, "face" => value, …)` from the calling task | accurate | `sim.jl:1294–1301` | `test_dataplane.jl:17` | |
| 11.3 (5127–5128) | its always-present cell is drained, traced and surface-checked exactly as any device's | accurate | `roster.jl:184–188`, `sim.jl:1342–1343` | `test_trace.jl:38` | |
| 11.3 (5128–5133) | its surface is the derived unclaimed complement, recomputed at every stopped-sim roster change | accurate | `roster.jl:230–239` | `test_roster.jl:142` | |
| 11.3 (5133–5135) | a `stage!` write to a claimed face is rejected at staging with `ClaimedFaceEntry` naming the incumbent | accurate | `dataplane.jl:463–468` | `test_roster.jl:142` | |
| 11.3 (5135–5138) | a rostered greedy claimant empties the harness surface outright (D-192) | accurate | `roster.jl:237` | `test_roster.jl:111` | |
| 11.3 (5138–5140) | the seam: a batch staged while stopped whose face a later `attach!` claims is renormalized at the attach | accurate | `roster.jl:240–246` | `test_roster.jl:165` | |
| 11.3 (5140–5142) | the harness cell drains last, by convention | accurate | `sim.jl:1340–1343` | `test_trace.jl:38` | |
| 11.3 (5144–5151) | root-input initial values owned by the init/trim services; `init!` establishes every one; the header captures the result | accurate | `sim.jl:617–620` (`assert_total`), `trace.jl:294–296` | `test_trace.jl:75` | §14.6 owns the totality rule itself |
| 11.3 (5153–5157) | the roster is frozen per run: `attach!`/`detach!` legal in `built`/`initialized`/`stopped`, `ServiceLifecycle` while running | accurate | `devices.jl:131–133`, `sim.jl:1215,1265` | `test_roster.jl:201` | also admitted in `:errored`, a state §11.3's list predates (§13.6) |
| 11.3 (5157–5160) | the prohibition includes pause | absent | — | — | pause itself is absent (§12.1); the running gate spans the whole run |
| 11.3 (5160–5163) | the roster is a plain immutable value the loop reads once at `run!` | stand-in | `roster.jl:168–178` | `test_roster.jl:201` | see 4.4 |
| 11.3 (5163–5166) | the surface partition is printable before the run starts (the provenance register, §13.7) | absent | — | — | no printer for the roster or its partition |
| 11.3 (5166–5169) | no republication machinery: no atomic roster reference, no per-frame acquire-load, no sequence numbers | accurate | `roster.jl:168–178` | no test | |
| 11.3 (5169) | attachment order is the roster's own order | accurate | `roster.jl:169`, `sim.jl:1339` | `test_roster.jl:223` | |
| 11.3 (5170–5172) | the trace tags entries with a stable device id, never a roster index | accurate | `trace.jl:202–205` (`_who(e)` tags), `dataplane.jl:132` | `test_trace.jl:129` | the record's `writer` is a schema index whose entry carries the id |
| 11.3 (5172–5176) | attach validation, claim registration and shape compilation all run at the attach point | accurate | `sim.jl:1213–1250` | `test_roster.jl:52` | |
| 11.3 (5177–5180) | identity is the instance: the same object may occupy at most one roster entry | accurate | `sim.jl:1219–1221` | `test_roster.jl:52` | |
| 11.3 (5180–5185) | the device id is assigned at `attach!`, monotonic per `Simulation`, never reused, living as long as the entry | accurate | `sim.jl:1240–1241` | `test_roster.jl:190` | |
| 11.3 (5187–5196) | three-part admission in order — identity/`AlreadyAttached`, affinity/`CallerTaskConflict`, claims/`ClaimConflict` | accurate | `sim.jl:1219–1238` | `test_roster.jl:52` | |
| 11.3 (5198–5206) | why the order: `ClaimConflict` always names two distinct devices | accurate | `sim.jl:1219` before `1233` | `test_roster.jl:52` | |
| 11.3 (5208–5213) | device death does not detach: the task ends, the entry and its claims persist to run end | accurate | `devices.jl:348–358` | `test_devices.jl:173` | |
| 11.3 (5213–5216) | the read-only widgets render the orphan visibly ("claimed by … — task dead") | absent | — | — | §11.7 absent |
| 11.3 (5216–5219) | recovery is between runs: stop, `detach!`, then `init!` or `replay!`-to-end plus `run!` | accurate | `sim.jl:1263`, `sim.jl:720` | `test_trace.jl:608` | |
| 11.3 (5221–5229) | a pure reader attaching mid-run is a guarded addition | n/a | — | — | admitted, not built, by design |
| 11.3 (5229–5231) | the §12.2 thread-budget warning runs once per `run!` against the frozen population | absent | — | — | `ThreadBudget` has no source |
| 11.4 (5223–5231) | staging keeps one atomic cell per attached device, single-writer, holding the latest pending batch | accurate | `dataplane.jl:24–26`, `roster.jl:124` | `test_dataplane.jl:17` | |
| 11.4 (5228–5231) | one coalescing policy: CAS merge, newest wins per face; untouched faces survive | accurate | `dataplane.jl:502–518` | `test_dataplane.jl:56` | |
| 11.4 (5231–5233) | the CAS can fail only because a drain intercepted the old batch; the retry is bounded and the failure case correct | accurate | `dataplane.jl:510–518` | `test_dataplane.jl:157` | |
| 11.4 (5235–5245) | why merge is the only policy; `complete(binding)` is closed | accurate | no overwrite path exists | — | D-104 honoured by absence |
| 11.4 (5247–5262) | the staged representation is fixed per attachment, compiled at attach from the claim set and root-input types | accurate | `dataplane.jl:508–518`, `sim.jl:1242` | `test_dataplane.jl:91` | |
| 11.4 (5251–5258) | a values tuple `Tuple{T₁…Tₙ}` plus a parallel `Bool` mask; set means staged, clear means untouched, never "reset" | accurate | `dataplane.jl:392–397` | `test_dataplane.jl:56` | |
| 11.4 (5256–5258) | untouched positions carry placeholders and are never read; the mask guards every consumer | accurate | `dataplane.jl:420–428`, `524–526` | `test_dataplane.jl:210` | |
| 11.4 (5259–5261) | the face-name → position schema lives in the roster entry | accurate | `dataplane.jl:409–415`, `roster.jl:124` | `test_trace.jl:38` | |
| 11.4 (5263–5279) | the sketch: shim, merge, scatter | accurate | `dataplane.jl:432–546` | `test_dataplane.jl:56,68` | |
| 11.4 (5281–5288) | why one concrete layout; the `Union{Nothing,Tᵢ}` carrier rejected (D-202) | accurate | `dataplane.jl:502–530` | `test_dataplane.jl:180,210` | zero-allocation drain asserted for every touched-face pattern |
| 11.4 (5290–5297) | the merge is positional and mask-driven, compiles straight-line, does not degrade with width | accurate | `dataplane.jl:502–508` (`@generated`) | `test_dataplane.jl:210` (34 faces) | |
| 11.4 (5294–5297) | the drain applies each cell through an attach-compiled scatter, the mirror of the output gather | accurate | `dataplane.jl:521–530`, `bindings.jl:126` | `test_dataplane.jl:180` | |
| 11.4 (5299–5307) | authors never build the shape: `map_input` returns face ⇒ value pairs, normalized by an attach-compiled shim doing name→position, convert, set mask | accurate | `dataplane.jl:456–479`, `bindings.jl:91–99` | `test_bindings.jl:146` | |
| 11.4 (5309–5312) | a greedy entry needs no special treatment: its cell is compiled exactly as a joystick's | accurate | `sim.jl:1242` | `test_roster.jl:111` | |
| 11.4 (5314–5321) | the harness cell gets the same treatment, recompiled at each `attach!`/`detach!`, shim/merge/scatter alike | accurate | `roster.jl:235–239` | `test_roster.jl:142` | |
| 11.4 (5323–5325) | no face name is ever resolved inside the loop's frame | accurate | `dataplane.jl:521–530` | `test_dataplane.jl:180` | |
| 11.4 (5327–5331) | the recompilation seam: a pending harness batch is reshaped, newly-claimed faces discarded with `ClaimedFaceEntry` | accurate | `roster.jl:240–246` | `test_roster.jl:165` | |
| 11.4 (5333–5344) | diagnostic sites follow the compilation, all to staging: `OutOfClaimEntry`, `ClaimedFaceEntry`, `EntryTypeMismatch` | accurate | `dataplane.jl:456–479` | `test_dataplane.jl:68` | |
| 11.4 (5346–5348) | nothing remains at the drain; the drain is pure application | accurate | `dataplane.jl:534–546` | `test_dataplane.jl:68` | |
| 11.4 (5350–5353) | doctrine: staged values are levels, never deltas | n/a | — | — | author doctrine, unenforceable |
| 11.4 (5355–5359) | at frame top the drain takes each cell with one `atomicswap(cell, nothing)`, then scatters, in attachment order | accurate | `dataplane.jl:534–546`, `sim.jl:1339–1343` | `test_roster.jl:223` | |
| 11.4 (5361–5363) | which frame a write lands in is wall-clock reality; the frame's outcome is a pure function of the drained batches | accurate | `sim.jl:1326–1348` | `test_roster.jl:223` | |
| 11.4 (5365–5372) | the drain is compilable because the roster is fixed; iterating a roster array remains acceptable | accurate | `roster.jl:144`, `sim.jl:1339` | `test_roster.jl:242,250` | the spec licenses the implemented form |
| 11.4 (5374–5375) | per-input atomic cells and a shared batch stack rejected (D-024) | n/a | — | — | |
| 11.4 (5377–5381) | mappings run on the device task; `map_input(data, mapping) → batch`; the trace holds root-input-level batches | accurate | `bindings.jl:91–99`, `devices.jl:248–253` | `test_bindings.jl:146` | |
| 11.4 (5383–5388) | mappings are binding data: a declarative table plus per-axis conditioning, applied by `TableBinding`'s generic `map_input` | accurate | `bindings.jl:35–99`, `209–218` | `test_bindings.jl:103` | |
| 11.4 (5390–5395) | a face's meaning is writer-independent; conditioning sits upstream | n/a | — | — | doctrine |
| 11.4 (5397–5404) | aircraft-semantic derivation must not ride along | n/a | — | — | doctrine |
| 11.4 (5406–5410) | the trace records post-conditioning levels, so replay is exact | accurate | `dataplane.jl:544` (record after the shim) | `test_trace.jl:399` | |
| 11.5 (5398–5403) | the trace is the sequence of drained, device-tagged batches per frame | accurate | `trace.jl:52–66`, `dataplane.jl:544` | `test_trace.jl:38` | |
| 11.5 (5400–5403) | replaying a recorded session reproduces the trajectory bit-identically, staging fed from the recording, no devices present | accurate | `sim.jl:1366–1397` | `test_trace.jl:399,441` | |
| 11.5 (5405–5412) | one record format: every batch retained sparse, masked entries as (position ⇒ value) against the header schema | accurate | `trace.jl:171–191` | `test_trace.jl:38` | |
| 11.5 (5410–5412) | an O(surface-width) scan and one small allocation per drained batch | accurate | `trace.jl:174–188` (two scans, one exact-length vector) | `test_dataplane.jl:180` (measured with `trace = false`) | |
| 11.5 (5414–5423) | why one format; keying by claim source rejected (D-176) | n/a | — | — | |
| 11.5 (5425–5441) | the costs, and the reversibility of the decision | n/a | — | — | |
| 11.5 (5443–5447) | the header captures the full initial state `(x, s, m)` plus the initial root-input values at `init!` | accurate | `trace.jl:283–302` | `test_trace.jl:75` | |
| 11.5 (5445–5447) | captured after `apply!` and the root-input writes, before the boundary-zero sequence | accurate | `sim.jl:620–624` | `test_trace.jl:75` | |
| 11.5 (5448–5455) | the header holds resolved stores and root inputs, never the authored overlay, and never the post-transition result | accurate | `trace.jl:288–292`, `sim.jl:620–624` | `test_trace.jl:75` | |
| 11.5 (5457–5461) | an unfed `mixture = 0.5` never appears in a batch, so the header carries root inputs | accurate | `trace.jl:294–296` | `test_trace.jl:75` | |
| 11.5 (5463–5471) | the header carries each writer's face-name → position schema; the schema list only grows, every capture and roster change appending, earlier records keeping their index | accurate | `trace.jl:236–253` | `test_trace.jl:129` | |
| 11.5 (5472–5479) | the deployment block: `t₀`, `Δt_base`, `h`, `n`, method, `localization_tol`, `localization_budget`, `firing_budget`, `t_end`/`stop_on`, captured at the same instant | accurate | `trace.jl:297–305` | `test_trace.jl:209` | |
| 11.5 (5477–5479) | a `run!` override post-dates the capture; the header records what `init!` knows | accurate | `trace.jl:297–305`, `sim.jl:879–881` | `test_trace.jl:209` | |
| 11.5 (5481–5486) | the deployment block is also the artifact's run metadata (§13.5, Appendix B) | n/a | — | — | §13.5/Appendix B own it |
| 11.5 (5488–5491) | the trace carries its length, the number of drains since the capture; a recording whose last frames drained nothing still ran them | accurate | `trace.jl:79–83`, `sim.jl:1345` | `test_trace.jl:552` | |
| 11.5 (5493–5499) | trace recording on by default; cleared at `init!`; retrievable after the run; a plain kill switch | accurate | `sim.jl:55,134,622`, `sim.jl:1518` | `test_trace.jl:99` | |
| 11.5 (5495–5499) | no sampling, no rolling window (D-029) | accurate | `trace.jl:186–190` (append only) | `test_trace.jl:99` | |
| 11.6 (5502–5504) | the input/output/GUI trichotomy has no referent (D-025) | n/a | — | — | |
| 11.6 (5507–5510) | every attached device gets the same handle: read, stage, control access | accurate | `devices.jl:151–162` | `test_devices.jl:110` | |
| 11.6 (5509–5510) | read returns the latest snapshot, optionally waiting for the next boundary | accurate | `devices.jl:236,306–319` | `test_devices.jl:130` | |
| 11.6 (5512–5518) | `should_abort` is an `attach!` keyword defaulting to `false`, per-attachment, never a device property | accurate | `sim.jl:1214`, `roster.jl:126` | `test_devices.jl:190` | |
| 11.6 (5515–5518) | clear: departure reported, run continues; set: departure also requests a stop | accurate | `devices.jl:354–356` | `test_devices.jl:173,190` | |
| 11.6 (5518) | a departure is the loop body returning, a crash, or a failed `init!` | accurate | `devices.jl:348–358,374–389` | `test_devices.jl:190,201` | |
| 11.6 (5518–5521) | the shipped GUI attaches with `should_abort = true`; `gui = true`'s run-scoped attachment | absent | — | — | no shipped GUI, no `gui` keyword |
| 11.6 (5523–5527) | input-only and output-only devices are degenerate uses, not classes; a bidirectional peer is one device | accurate | `roster.jl:26–39`, `bindings.jl` | `test_bindings.jl:253` | |
| 11.6 (5531–5545) | the authoring contract: `MyDevice <: AbstractDevice`; `init!`, `loop`, `shutdown!`, `unblock!`, `needs_calling_task` | accurate | `roster.jl:26`, `devices.jl:183–187`, `roster.jl:39` | `test_devices.jl:266,297` | |
| 11.6 (5547–5560) | the wrapper: `init!` bracketed pre-spawn; spawn, catch → `DeviceCrash`, finally `shutdown!` and mark dead | accurate | `devices.jl:348–358,374–389` | `test_devices.jl:173,201` | `mark_dead!` is subsumed by `task_state` plus a stale heartbeat |
| 11.6 (5562–5566) | a `needs_calling_task` device runs the identical wrapper inline | accurate | `sim.jl:953` | `test_devices.jl:281` | |
| 11.6 (5568–5577) | `shutdown!` must tolerate a partial init; the bracket sends a throwing `init!` straight to `shutdown!`; `init!` is not asked to clean up | accurate | `devices.jl:374–389` | `test_devices.jl:201` | |
| 11.6 (5579–5586) | an `InterruptException` is never a `DeviceCrash`; the wrapper forwards the stop and lets the body leave through `running(handle)`, with no `should_abort` consultation | absent | — | — | see 4.5 |
| 11.6 (5588–5595) | the author owns the loop body; no framework-owned hook loop (D-102) | accurate | `devices.jl:348–358` | `test_devices.jl:110` | |
| 11.6 (5597–5625) | the three worked loop bodies | n/a | — | — | examples |
| 11.6 (5627–5632) | a forgotten predicate check surfaces as `DeviceJoinTimeout` with the device's name; a stall as a stale heartbeat | accurate | `devices.jl:443–450`, `dataplane.jl:385` | `test_devices.jl:241` | |
| 11.6 (5632–5635) | liveness timestamps ride inside the handle primitives, stored in the device's own cell | accurate | `devices.jl:205,236,249,268,291,307` | `test_diagnostics.jl:212` | |
| 11.6 (5637–5642) | `should_close` dissolves: a return is the departure; claims and the entry persist to run end | accurate | `devices.jl:348–358` | `test_devices.jl:173` | |
| 11.6 (5645–5660) | a binding subtypes `AbstractBinding`; sides declared by traits with `false` defaults on the root | accurate | `roster.jl:27,36–39` | `test_bindings.jl:91,177` | |
| 11.6 (5662–5665) | the root carries `is_greedy = false` beside the two side defaults | accurate | `roster.jl:38` | `test_roster.jl:30` | |
| 11.6 (5667–5678) | no framework contract on the datum; `map_input`/`map_output` are loop-idiom conventions the framework never calls | accurate | `bindings.jl:91,199`, `devices.jl:228` | `test_bindings.jl:146` | |
| 11.6 (5680–5687) | `reads(b)` returns a labeled NamedTuple of selectors; labels carried through compilation in declaration order (D-199) | accurate | `bindings.jl:138–149` | `test_bindings.jl:220` | |
| 11.6 (5689–5694) | `claims` and `reads` have error-throwing fallbacks on the root | accurate | `roster.jl:50–62` | `test_bindings.jl:177`, `test_roster.jl:30` | |
| 11.6 (5695–5717) | the bidirectional conformance check, all six cases | accurate | `roster.jl:74–90` | `test_roster.jl:30`, `test_bindings.jl:177` | |
| 11.6 (5719–5721) | every violation reports `BindingContractMismatch` naming the binding type, the trait, the method at fault and the direction | accurate | `diagnostics.jl:890–923` | `test_roster.jl:30` | trait, method and direction ride in `reason` and its message, not as separate fields |
| 11.6 (5723–5731) | this closes the shadowing hole (D-177) | n/a | — | — | rationale |
| 11.6 (5733–5741) | greediness stays orthogonal to `reads`: greedy plus a compiled gather is legal | accurate | `roster.jl:74–90` (no cross-check) | no test | uninstantiated by design |
| 11.6 (5741–5744) | the binding is an `attach!` argument, never a device field | accurate | `sim.jl:1213`, `devices.jl:154,228` | `test_bindings.jl:146` | |
| 11.6 (5746–5756) | why the periphery gets roots where components have one | n/a | — | — | rationale |
| 11.6 (5758–5762) | the binding-type taxonomy and a `sides(b)` trait rejected (D-177) | n/a | — | — | |
| 11.6 (5764–5779) | `is_greedy` is a claim source, not a device class; every downstream mechanism is blind to it | accurate | `roster.jl:120–130`, `sim.jl:1232–1247` | `test_roster.jl:111` | |
| 11.6 (5781–5789) | a second greedy attach stakes the empty remainder; the attach succeeds and reports `EmptyGreedyClaim` naming the device and its binding | accurate | `sim.jl:1249–1250`, `diagnostics.jl:880–887` | `test_roster.jl:111` | |
| 11.6 (5791–5796) | several interactive front ends may be rostered at once; only `needs_calling_task` is single-holder | accurate | `sim.jl:1225–1230` | `test_roster.jl:52` | |
| 11.6 (5798–5809) | the shipped GUI binding is a greedy one, declaring no `claims` and no `reads` | absent | — | — | no shipped GUI binding |
| 11.6 (5811–5822) | the empty enumeration is an honest degenerate; drift on it is `OutOfClaimEntry`; `claims` never returns a sentinel | accurate | `roster.jl:203–209`, `dataplane.jl:456–466` | `test_roster.jl:77` | |
| 11.6 (5824–5836) | `TableBinding` is data-driven: entry names a face plus optional deadzone/expo, riding in the type | accurate | `bindings.jl:35–69` | `test_bindings.jl:68` | |
| 11.6 (5838–5841) | its generic `map_input` is the shared pure conditioning helper, and its owner | accurate | `bindings.jl:91–99,209–218` | `test_bindings.jl:103` | |
| 11.6 (5841–5847) | a code-driven binding looks identical; cross-datum state lives in the device struct | accurate | `bindings.jl:91–99` | `test_bindings.jl:134` | purity is taught, not enforced |
| 11.6 (5849–5857) | bad datum: catch, stage nothing, `report!(handle, MalformedDatum(cause))`, continue; bounded by the device's cell | accurate | `devices.jl:291`, `dataplane.jl:269–278` | `test_diagnostics.jl:59` | |
| 11.6 (5859–5866) | any other exception propagates to the wrapper as `DeviceCrash`; no marked exception type is provided (D-105) | accurate | `devices.jl:348–353` | `test_diagnostics.jl:59` | |
| 11.6 (5866–5871) | `report!` is the single-writer entry into that device's cell and nothing more; not a general user-diagnostics channel | accurate | `devices.jl:291` (typed `::MalformedDatum`) | `test_diagnostics.jl:59` | |
| 11.7 (5857–5866) | panels are per-component extensions; widgets name the component's own ports | absent | — | — | see 4.6 |
| 11.7 (5860–5862) | the build-time wiring answers "is this port transitively driven by a root input, and which one?", totally | absent | — | — | see 4.6 |
| 11.7 (5864–5870) | root-driven and inside the GUI's claim → live widget peeking and staging through the GUI's own cell | absent | — | — | see 4.6 |
| 11.7 (5867–5870) | component-driven or claimed elsewhere → read-only rendering with the source as provenance | absent | — | — | see 4.6 |
| 11.7 (5872–5882) | a widget is live exactly when the input is yours to command; read-only rendering is first-class | absent | — | — | see 4.6 |
| 11.7 (5884–5895) | liveness is derived and transitive, walked through wires and interface connections across all levels, and combined with claim membership | absent | — | — | see 4.6 |
| 11.7 (5896–5905) | liveness is baked once at run start, never consulted at render; no per-port "GUI-controlled" marking | absent | — | — | see 4.6 |
| 11.7 (5905–5913) | unexported ports are unpokeable | accurate | `roster.jl:203–209` (only root faces claimable) | `test_roster.jl:77` | the honest cost holds by construction |
| 11.7 (5915–5923) | peek rule: own pending write if any, else the snapshot value; own cell only; paused edits display indefinitely | absent | — | — | see 4.6 |
| 11.7 (5925–5936) | staging contract: widgets stage on interaction events only; edge widgets stage `k+1` from the peek | absent | — | — | see 4.6 |
| 11.7 (5938–5945) | no claim-transition policy; the orphan display rule | absent | — | — | see 4.6 |
| 11.7 (5947–5955) | the panel-authoring calling convention is deferred to §16 | n/a | — | — | explicitly deferred |
| 11.8 (5951–5962) | three channels cross the same boundaries, written at staging, by device tasks, and by the loop (`ChatteringBudget`, `FiringBudget`, `DebtReanchor`) | short | `localization.jl:77`, `sim.jl:451`, `dataplane.jl:456–479`, `devices.jl:291` | `test_diagnostics.jl:169` | `DebtReanchor` absent with the pacer |
| 11.8 (5964–5972) | one diagnostic cell per writer: per device, one for the harness, one for the loop (D-200) | accurate | `roster.jl:127,172`, `sim.jl:47` | `test_diagnostics.jl:169` | |
| 11.8 (5968–5972) | the harness cell is written from whichever task stages, carries no heartbeat and no `task_state` | accurate | `sim.jl:1463`, `dataplane.jl:351–358` | `test_diagnostics.jl:103` | |
| 11.8 (5972–5975) | the cell holds a bounded ring of capacity 16, a per-kind suppressed count, and one atomic liveness timestamp | accurate | `dataplane.jl:231–265` | `test_diagnostics.jl:86` | |
| 11.8 (5977–5984) | the bound *is* the rate limit; the drop policy is earliest-in-frame retained, excess becomes counts | accurate | `dataplane.jl:269–278` | `test_diagnostics.jl:86` | |
| 11.8 (5984–5989) | rate limiting is structural; no writer can starve another, the cells being disjoint | accurate | `dataplane.jl:246–257` | `test_diagnostics.jl:169` | |
| 11.8 (5991–5996) | the diagnostic drain is the staging drain: one `atomicswap` per cell at frame top, a shared empty sentinel swapped in | accurate | `dataplane.jl:243,283`, `sim.jl:1339–1344` | `test_dataplane.jl:174` | |
| 11.8 (5996–6001) | the take is what makes publication sound: the batch is exclusively the loop's before any snapshot reaches it | accurate | `dataplane.jl:317–331`, `sim.jl:1447–1450` | `test_diagnostics.jl:103` | |
| 11.8 (6003–6010) | the heartbeat rides in the same cell, stored on every loop pass, acquire-loaded by the loop at the drain | stand-in | `dataplane.jl:286–287`, `sim.jl:1461` | `test_diagnostics.jl:212` | read at publication, not at the drain; see 4.2 |
| 11.8 (6008–6011) | the 2 s staleness threshold is read against this field; the heartbeat is a field, never a kind | accurate | `dataplane.jl:372,385` | `test_devices.jl:218` | |
| 11.8 (6013–6019) | the status carries per writer `recent`, `suppressed`, `totals` (copied), `heartbeat` and `task_state` | accurate | `dataplane.jl:351–358`, `sim.jl:1446–1465` | `test_diagnostics.jl:103,132` | |
| 11.8 (6019–6021) | beside the per-writer records ride the pacer diagnostics | absent | — | — | see 4.1 |
| 11.8 (6021–6026) | delta plus total makes the status legible at any reading cadence | accurate | `sim.jl:1446–1450`, `dataplane.jl:317–331` | `test_diagnostics.jl:103` | |
| 11.8 (6028–6035) | presentation is where `maxlog` lives: 25 cumulative occurrences per writer × kind, then count-only | absent | — | — | see 4.7 |
| 11.8 (6037–6041) | the terminal snapshot carries the run's final cumulative counters | accurate | `sim.jl:1456–1465`, `dataplane.jl:645–651` | `test_diagnostics.jl:149` | |
| 11.8 (6041–6050) | final means final at the last frame top (D-201); the run's-end take becomes the termination record's tail residue, presented through the logging backend, never published | accurate | `devices.jl:467–496`, `sim.jl:990` | `test_diagnostics.jl:149` | |
| 11.8 (6052–6056) | on a quiet frame there is zero additional heap allocation | short | `dataplane.jl:283,317–320`, `sim.jl:1456–1465` | `test_dataplane.jl:174` | see 4.8 |
| 11.8 (6056–6059) | the per-kind counters are a fixed-shape isbits record, never a `Dict` | accurate | `dataplane.jl:190–210` | `test_diagnostics.jl:169` | |
| 11.8 (6059–6068) | on a noisy frame values allocate at emission on the writer's task; a drained ring is frozen and the writer allocates afresh | accurate | `dataplane.jl:269–278` | `test_diagnostics.jl:86` | |
| 11.8 (6068–6071) | the rate limit is an allocation bound: one ring of sixteen per writer per boundary worst case | accurate | `dataplane.jl:271–275` | `test_diagnostics.jl:86` | |
| 11.8 (6071–6073) | §7.5's zero-allocation invariant untouched; the cells sit on the framework side | accurate | `dataplane.jl:283` | `test_dataplane.jl:174` | |
| 11.8 (6075–6080) | `totals` is monotone across logged snapshots, so decimation loses which boundary, never how many | accurate | `dataplane.jl:322–330` | `test_log.jl:98` | |
| 11.8 (6082–6084) | a shared queue under a lock, a live-accumulator status, ring double-buffering and unbounded accumulation rejected (D-136) | n/a | — | — | |

## Deviations in detail

### 4.1 The framework status carries no pacer diagnostics

§11.2 (4864–4866): "It carries the pacer diagnostics ([§10.7]), plus the
per-writer diagnostic batches …". §11.8 (6019–6021) repeats it: "Beside the
per-writer records ride the pacer diagnostics."

`FrameworkStatus` (`src/dataplane.jl:368–370`) has exactly one field,
`writers::Vector{WriterStatus}`. There is no pacer field, and `rg -n "pacer"`
over `src/` returns only the header comment at `src/dataplane.jl:8` saying the
pacer diagnostics are deliberately absent. The `DebtReanchor` kind §11.8 names
among the loop's own writes is absent with it (`src/dataplane.jl:36`). This is
downstream of the pacer itself being unbuilt (§10.7, another agent's slice), so
the gap is one of feature ordering rather than of shape: `FrameworkStatus`
takes a second field the day the pacer lands.

### 4.2 The heartbeat is acquire-loaded at publication, not at the drain

§11.8 (6003–6007): "as an atomic timestamp field the device task stores on
every loop pass … and the loop acquire-loads **at the drain**." §11.2
(4866–4868) says the same from the other end: "liveness timestamps the loop
takes **at frame top**."

`drain!` (`src/sim.jl:1326–1348`) never touches `_heartbeat`. The read happens
in `_status` (`src/sim.jl:1461`), called from `publish!`. Two consequences,
both small. The published timestamp is fresher than the spec's, since
publication follows the drain within the frame. And a `t*` boundary publishes
without a preceding drain (`src/sim.jl:1052–1056`), so its status carries a
heartbeat read at a moment the spec's rule never names. Nothing observable
breaks — `stale` is a display rule with a 2 s threshold — but the reading site
is not the one the spec fixes.

### 4.3 Attach-time read resolution has no did-you-mean for two of three misses

§11.2 (4995–4997): "A binding is resolved at attach against the `Build` with
[did-you-mean] (the offending name plus the list-in-hand it should have
matched)".

`ReadBindingUnresolved` carries a `candidates::Vector{Symbol}` field
(`src/diagnostics.jl:946`), and exactly one call site fills it:
`_resolve_read(::Layout, ::GetInput, …)` at `src/bindings.jl:172–175`. The two
misses a real binding is most likely to hit leave it empty —
`:unknown_cell` for a `get_output` path (`src/bindings.jl:165–167`) and
`:unknown_output_face` for a `get_face` name (`src/bindings.jl:183–185`) — and
their messages say only "which names no cell — only declared outputs, assembly
faces and root inputs are addressable" and "is no root-exported output face".
The refusal is loud and at the right site; what is missing is the list the
author was supposed to have matched, which is the half that makes the
diagnostic actionable on a large build. `src/bindings.jl:136` records the
absence in a comment.

### 4.4 The roster is a mutable vector under a lifecycle gate, not an immutable value

§11.3 (5160–5163): "The roster — entries, claims, attachment order — is
therefore a plain immutable value the loop reads once at `run!`."

`DataPlane.roster` is a `Vector{RosterEntry}` (`src/roster.jl:169`) inside a
`mutable struct`, and the loop re-reads it every frame: `drain!` iterates
`plane.roster` at `src/sim.jl:1339`, and `_status` iterates it again at
`src/sim.jl:1459`. What enforces the freeze is `assert_stopped`
(`src/devices.jl:131–133`) refusing `attach!`/`detach!` while the lifecycle is
`:running`, not the value's immutability. The docstring at
`src/roster.jl:150–155` is explicit about why: the harness writer's *type*
changes at every roster change, so it cannot be a `Simulation` type parameter.

I call this a stand-in rather than a deviation that bites. The observable
guarantee — the roster cannot move during a run — holds, and §11.4
(5365–5372) explicitly licenses "iterating a roster array" over the tuple
specialization. But the spec's phrasing promises a property (no mutation
possible) that the code delivers as a policy (no mutation permitted), and a
future caller reaching `sim.plane.roster` directly would find nothing stopping
it.

### 4.5 The wrapper turns an `InterruptException` into a `DeviceCrash`

§11.6 (5579–5586), in full: "One discrimination in that wrapper: **an
`InterruptException` is never a `DeviceCrash`.** Under the spawned-loop
topology the calling task is the one running a device loop body inline — the
GUI's. An operator Ctrl-C therefore raises *there*, inside user code that did
nothing wrong. The wrapper forwards the control-plane stop and lets the body
leave through the ordinary `running(handle)` predicate. There is no crash
report for what is not a crash, and no `should_abort` consultation, a stop
being already requested."

`_wrap` (`src/devices.jl:348–358`) is:

```julia
try
    loop(e.dev, e.handle)
catch err
    _report!(e.diag, DeviceCrash(err, e.should_abort))
finally
    _shutdown!(e)
    e.should_abort && stop!(e.handle)
end
```

No branch on `err isa InterruptException`. So a Ctrl-C into a
`needs_calling_task` device's inline body — the exact case the spec names —
produces a `DeviceCrash` diagnostic in the device's cell, published as a
warning in the next status, and consults `should_abort` as though the device
had failed. The stop it then requests is recorded with the device's name as
its issuer (`src/devices.jl:216`) rather than as an interrupt.

The framework knows how to do this elsewhere: `_advance!` has the carve-out at
`src/sim.jl:1058`, returning `ControlRequestedStop(:interrupt)`. Only the
wrapper lacks it. The file header at `src/devices.jl:6–7` says the operator
interrupt is absent, which reads as a deliberate deferral rather than an
oversight, but the discrimination itself is three lines and independent of any
interrupt-masking machinery. What it costs today is a misleading message: a
run stopped by the operator reports a device crash by name.

### 4.6 §11.7 is not built

The whole of §11.7 (5855–5947) has no code behind it. There is no GUI device,
no panel walk, no drawing context, no widget vocabulary. More consequentially
for the rest of the chapter, the *framework* half §11.7 depends on is absent
too: nothing in `src/` resolves a component port through wires and interface
connections to the root input that feeds it. `rg -n "root-driven|driven by|feed
chain|source_of"` over `src/` finds nothing; `resolve`/`resolve_terminal` in
`src/assembly.jl:308–330` resolve a path to a component and a name, which is a
different question. So the derived-liveness verdict, the peek, the read-only
provenance string, the orphan rendering and the interaction-event staging
contract all have no partial implementation to grade.

Three claims elsewhere in the slice are absent for this reason and are listed
separately in the table: §11.2's peek fallback and read-only mirrors
(4884–4887), §11.3's "a released root input's GUI widgets are live again from
the next run" (5062–5064) and its orphan rendering (5213–5216).

One §11.7 sentence *is* satisfied, by construction rather than by code:
"unexported ports are unpokeable" (5905–5913). A claim can only name a root
input face (`src/roster.jl:203–209`), and staging can only reach a claimed
face, so there is no path by which an unexported port could be written from
the periphery.

### 4.7 `maxlog` has no renderer to live in

§11.8 (6028–6033): "A status renderer prints a given writer × kind up to
**25** cumulative occurrences and then switches to count-only display".

There is no status renderer at all. `rg -n "maxlog|FrameworkStatus"` over
`src/` finds the type, its construction in `publish!`, and nothing that
displays it; `Base.show` is defined only for the three error carriers
(`src/diagnostics.jl:90,178,224`). The channel-side bound the spec calls
normative (the sixteen-deep ring) is built and tested; the presentation policy
it contrasts against is simply not there, along with the thing it would be a
policy for. The tail residue does get printed (`src/devices.jl:489–493`) with
no such threshold, which is the one place a flood could reach a terminal
today — bounded, though, by the ring itself.

### 4.8 A quiet frame's publication allocates the status

§11.8 (6052–6056): "On a quiet frame there is **zero additional heap
allocation**: the sentinel swap allocates nothing and the per-writer status
rides inline in the one per-boundary snapshot allocation §11.2 already
accepted."

The sentinel swap half holds: `drain!` on a quiet frame measures 0 bytes, both
in my probe and in `test/test_dataplane.jl:174`. The status half does not.
`_status` (`src/sim.jl:1456–1465`) allocates a fresh `Vector{WriterStatus}` of
length `nroster + 2` and one `WriterStatus` per writer at every publication,
which is not "inline in the one snapshot allocation" — it is one vector plus N
structs beside it, growing with the roster.

Probe, `julia --project=.` from the repository root, on
`Simulation(fed(Plant(), "u"); h = 1//10)` after `init!`, with an empty roster
(so two writers, harness and loop) and a quiet frame:

```
capture allocs: 3616      # first, cold call
_status allocs: 432
publish allocs: 752
drain!  allocs: 0
```

432 bytes per boundary, on the loop task, on the framework side of §7.5's
scope. It is small and constant per writer, and it is inside the carve-out
publication already lives in, so nothing about the zero-allocation model sweep
is at risk. But the sentence as written promises zero *additional* allocation
and the code allocates proportionally to the writer count at every boundary,
so I record it short rather than accurate.

## Tally

| verdict | count |
| --- | --- |
| accurate | 153 |
| short | 6 |
| stand-in | 2 |
| absent | 24 |
| n/a | 23 |
| **total** | **208** |

## Friction

- **The shared scratchpad.** The directory named in my environment is shared
  with the other agents in this audit, and my first probe script was silently
  overwritten by another agent's file with the same name between writing it
  and running it — the run printed someone else's output. I moved to an
  `agentE/` subdirectory. Worth naming per-agent scratchpads in the brief.

- **`test/fixtures.jl` cannot be loaded on its own.** It reads the framework's
  names from `Main`, which only `test/CadenceTests.jl` puts there, and
  `CadenceTests` needs `BenchmarkTools` from `test/Project.toml` while the
  brief pins probes to `--project=.`. Getting a two-line allocation probe
  running took four attempts. A `fixtures.jl` that did its own importing, or a
  documented probe preamble, would have paid for itself.

- **Two claims I could not decide cleanly, and where I landed.** §11.3's "the
  roster is a plain immutable value" reads as a shape claim on one reading and
  as a restatement of the freeze on another; I graded it stand-in (4.4) and
  said why. §11.8's "zero additional heap allocation" reads as a claim about
  the diagnostic channel alone on one reading, in which case it is accurate,
  and about the whole quiet frame on another, in which case `_status`'s vector
  breaks it; the sentence's own second clause ("rides inline in the one
  per-boundary snapshot allocation") decided me for the second reading (4.8).

- **§11.7's absence is invisible from the code side.** Every other gap in this
  slice announced itself somewhere — a comment naming what is deferred, a
  diagnostic kind with no source. §11.7 has no footprint at all, so
  establishing it was absent meant proving a negative across `src/` with four
  different search vocabularies. A one-line "the GUI write path has no code
  here" in `src/dataplane.jl`'s header, of the kind the pacer already gets,
  would have made it a five-second check.

- **`test_dataplane.jl:180`'s comment is load-bearing and easy to miss.** The
  populated-drain allocation tests run with `trace = false`, because the trace
  record is the drain's one admitted allocation. Read quickly, the testset name
  ("a populated drain is as free as an empty one") promises more than the suite
  checks. The comment says so plainly; the name does not.
