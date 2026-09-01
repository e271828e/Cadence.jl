# Conformance audit — §11–12, Runtime periphery (Agent D)

Slice: `docs/design/spec.md` lines 4662–6869. Repository at `master`, tip
`2c02afb`. `docs/design/implementation.md` was not opened. No Julia process was
started; every finding below is read off the source.

## 1. Summary

The slice is in good shape where it is built, and what is missing is missing in
whole sections rather than in fragments. The five planes of §11.1 are all
present and the mechanics are close to the letter: the staging cell is one
atomic reference holding a boxed batch, the merge is exactly the spec's
positional mask sketch (`_merge`, `dataplane.jl:502`, unrolled by `@generated`),
the drain is one `atomicswap` per cell in attachment order with the harness
last, the scatter is compiled and masked, and publication is a single
release-store followed by the counter increment under the lock in the normative
order (`publish!`, `sim.jl:1424`). §11.4, §11.5, §11.8's data half and §12.7 are
the strongest parts of the slice — §12.7 in particular reads as a faithful
implementation of every bullet, including `to_time`'s floor, the mode register,
`live!`, re-recording and the seven-parameter deployment comparison.

Three whole obligations are absent, and they are the shape of the gap. **§11.7
(the GUI write path) has no implementation at all** — no port resolution, no
peek, no derived liveness, no orphan rendering; grep for `peek`, `draw!`,
`input_slider`, `read_only`, `live_widget`, `resolve_port` returns nothing in
`src/`. **§12.1's pause/pace/`margin` surface and §12.2's coarse-phase `sleep`,
`systemsleep` disposition and thread-budget warning are absent** (`pause`,
`margin`, `sleep`, `nthreads` all empty in `src/`); only the stop word, the
per-frame `yield()` and the 2 s staleness constant survive. **§12.4's normative
interrupt masking is absent** — there is no `disable_sigint`, only a defensive
`InterruptException` branch in the frame loop's catch, which is precisely the
`stopped`-with-dirty-stores outcome the masking rule exists to forbid.

The three findings I would raise first are all arithmetic or ordering, not
absence:

1. **`t_end` lands on the wrong grid boundary** (`sim.jl:883`, `sim.jl:1131`).
   The frame target is `round(Int, t_end / h)`, but §12.4 and D-133 both require
   the *first* boundary whose time reaches or exceeds `t_end` — `ceil`. D-133
   explicitly rejects "ending at the last boundary before `t_end`", which is
   what `round` produces for every `t_end/h` with fractional part below ½. No
   test pins it: every test uses an exact multiple.
2. **`t_end` is measured from step 0, not from the clock.** The same expression
   ignores `clock.t₀`. With `init!(sim; t0 = 10.0)` and `t_end = 12.0` the run
   ends at t = 22, not 12. §12.4 says "the first grid boundary whose *time*
   reaches or exceeds `t_end`", which reads absolute.
3. **The join cap is one shared deadline for the whole tail, not a per-device
   cap** (`_tail!`, `devices.jl:440`). With n devices the last one can be
   allotted zero patience and be abandoned under `DeviceJoinTimeout` although it
   would have joined inside `join_timeout`. D-198 says "the join loop has one
   patience", which arguably ratifies one *value*; it does not obviously ratify
   one *deadline*, and the two are observably different.

Beyond those: `_wrap` (`devices.jl:348`) reports an `InterruptException` as a
`DeviceCrash`, which §11.6 forbids in as many words; §11.8's presentation half
(the 25-occurrence `maxlog` switch to count-only display) has no renderer at
all; the published `FrameworkStatus` carries only the per-writer records, the
pacer diagnostics §11.2 lists beside them being absent with the pacer; and the
attach-time did-you-mean §11.2 requires of output-binding resolution is carried
by `GetInput` alone, not by `get_output`/`get_face`.

Two unguarded edges are worth the coordinator's attention. `stage!(sim, …)`
(`sim.jl:1292`) reads `plane.harness` and `plane.claimedby` with no lifecycle
gate and no synchronization, so a concurrent stopped-sim `attach!` — legal, and
`reclaim!` swaps the harness writer non-atomically — can lose a harness batch
into the orphaned cell, bypassing exactly the renormalization §11.4's seam rule
exists to perform. And `port(sim, …)`/`state(sim, …)` read the live store with
no `assert_stopped`, unlike `logged(sim)` which has one; under the
calling-task-device topology the loop is on another task and those reads race
the sweep. Neither is reachable from the device handle, which is why I rate them
low rather than high.

No section defeated me. §11.7 is the one I would double-check: it is so
completely absent that I want the verification pass to confirm no build-time
port-to-root-input resolution exists under a name I did not guess.

## 2. The table

### §11.1 — No shared mutable model (4679–4778)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.1 (4700–4712) | Five planes: staging, drain, publication, control, task topology | accurate | `dataplane.jl:24`, `sim.jl:1324`, `sim.jl:1424`, `devices.jl:108`, `sim.jl:922` | all five present, control minus pause/pace | `test_dataplane.jl` "a staged batch lands at its frame top…" | high |
| §11.1 (4703) | A frame is drain, integrate, boundary sequence, publication; `step!` counts frames | accurate | `sim.jl:1030–1046` | `clock.step` is the ordinal, stamped into the trace and the snapshot | `test_lifecycle.jl` "step! advances whole frames…" | high |
| §11.1 (4706) | Devices never touch live root inputs; the drain is the one application point | accurate | `dataplane.jl:510`, `sim.jl:1324` | `_stage!` writes the cell only | `test_dataplane.jl` "a staged batch lands at its frame top, and nowhere earlier" | high |
| §11.1 (4709) | The drain is at frame top only, never at a `t*` boundary; no lock held during stepping | accurate | `sim.jl:1033–1036`, `localization.jl` | `drain!` is called once per frame before `frame!`; the only lock is `ctl.cond` at publication | `test_localization.jl:57` | high |
| §11.1 (4718) | `run!` spawns one task per roster entry after device `init!`; `attach!` never spawns | accurate | `devices.jl:394`, `sim.jl:937`, `sim.jl:1246` | `attach!` only pushes an entry | `test_devices.jl` "a failed init! is bracketed…" | high |
| §11.1 (4723–4740) | Calling-task affinity: at most one holder; with one rostered the loop moves to a spawned task and the calling task runs that device's body inline through the same wrapper | accurate | `sim.jl:932–960`, `roster.jl:39` | `_wrap(e_ct)` is the identical wrapper called inline | `test_devices.jl` "a calling-task device runs inline and the loop moves…" | high |
| §11.1 (4750) | Topology derived after initialization, from the live entries, never from `run!`'s keywords | accurate | `sim.jl:932` (`ct = findfirst(…, live)`) | `live` is `_init_devices!`'s return, so a failed calling-task holder returns the loop to the caller | none directly | high |
| §11.1 (4756) | Spawn-inside-`run!` is the start gate; no `Event` latch | accurate | `devices.jl:394`, `devices.jl:306` | the wait is counter-plus-condition | `test_devices.jl` "wait_next_snapshot observes ordered boundaries…" | high |
| §11.1 (4761) | Every handoff is one atomic reference operation on a release/acquire `@atomic` field | accurate | `dataplane.jl:24`, `dataplane.jl:262`, `dataplane.jl:586` | the batch rides boxed in a `Ref` so the field is pointer-width whatever the surface | `test_dataplane.jl` "the exchange is wait-free and coherent…" | high |
| §11.1 (4770) | No user code and no unbounded work inside a framework critical section | accurate | `sim.jl:1435–1441` | the only lock holds `counter += 1; notify` | none | high |
| §11.1 (4770) | Deep immutability of exchanged objects is what makes the pattern sound | partial | `dataplane.jl:564`, `dataplane.jl:576` | `Snapshot` is immutable but `capture` copies only the cell buffers; a cell whose value is a user mutable struct is shared with the live store, and nothing enforces immutability | none | medium |
| §11.1 (4777) | An unattended run is the same loop with empty staging and no readers | accurate | `sim.jl:922` | one `_run_body!` for both registers | `test_lifecycle.jl` throughout | high |

### §11.2 — Outbound: snapshot publication (4779–4976)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.2 (4790) | Build in private memory, publish with one release-store to `@atomic latest`; readers acquire-load | accurate | `sim.jl:1424–1434`, `dataplane.jl:586`, `sim.jl:1474` | | `test_dataplane.jl` "publication: one immutable value per frame-top boundary" | high |
| §11.2 (4791) | The snapshot carries the boundary-consistent signal table, `t` and the framework status | accurate | `dataplane.jl:564–572` | also `frame` and `boundary` | `test_dataplane.jl:99` | high |
| §11.2 (4797) | Publication happens only after the boundary sequence completes | accurate | `sim.jl:1038–1040`, `localization.jl` | grid, off-tick and `t*` publications all follow their sequence | `test_log.jl` "every boundary publishes: t* included…" | high |
| §11.2 (4801) | Binding rule: nothing reachable from a published snapshot is ever written again | accurate | `dataplane.jl:576`, `sim.jl:1444–1450` | `capture` copies the buffers; `_writer_status` takes the account's vector and re-arms the shared empty, and `_fold!` copies rather than appending to it | `test_diagnostics.jl` "the status: the delta rides one snapshot…" | high |
| §11.2 (4806) | The framework status is a concrete frozen value carrying pacer diagnostics, per-writer batches, suppressed and cumulative counters and liveness timestamps | partial | `dataplane.jl:368`, `sim.jl:1454` | `FrameworkStatus` has one field, `writers`. The per-writer half is complete (recent, suppressed, totals, heartbeat, task_state); the **pacer diagnostics are absent**, with §10.7's pacer | `test_diagnostics.jl:103` | high |
| §11.2 (4814) | The captured table is the whole table, every declared port and auto-published field | accurate | `dataplane.jl:576` (`capture` copies all cell stores) | | `test_dataplane.jl:110` | high |
| §11.2 (4823) | The captured table includes the root inputs | accurate | `dataplane.jl:576`; root inputs are ordinary cells at `("", face)` | | `test_dataplane.jl:110` | high |
| §11.2 (4834) | The snapshot deliberately does **not** carry `x`, `s`, `m` | accurate | `dataplane.jl:564–572` — no store fields | | `test_dataplane.jl:99` | high |
| §11.2 (4847) | The log is a vector of retained snapshot references, zero extra copies | accurate | `dataplane.jl:617`, `dataplane.jl:654` | | `test_log.jl` "the log is the publications themselves: full density, zero copies" | high |
| §11.2 (4857) | Retention: on/off switch plus `log_every` keep-every-kth | accurate | `sim.jl:135`, `dataplane.jl:654` | | `test_log.jl` "log_every thins retention, never publication" | high |
| §11.2 (4874) | `log_max` bound, default 65536, `Inf` the explicit opt-out | accurate | `sim.jl:135`, `sim.jl:153`, `sim.jl:175` | `Inf` stored as `typemax(Int)` | `test_log.jl` "the retention keywords are validated with their siblings" | high |
| §11.2 (4891) | When the log fills, the retention stride doubles; coverage stays global; amortized thinning | accurate | `dataplane.jl:675` | bound holds continuously (release-then-push keeps `live == max`); compaction once per generation restores the index-by-ordinal invariant | `test_log.jl` "re-decimation: stride doubles, coverage stays global…" | high |
| §11.2 (4911) | Normative guarantees: bound respected continuously, coverage global at the effective stride, endpoints kept | accurate | `dataplane.jl:675`, `dataplane.jl:654` | | `test_log.jl:62`, `test_log.jl:53` | high |
| §11.2 (4930) | Boundary-zero and terminal snapshots retained unconditionally, outside the bound | accurate | `dataplane.jl:622–623`, `dataplane.jl:654–664` | `first` set at `nb == 0`, `last` re-pointed at every publication | `test_log.jl` "the endpoints are unconditional and outside the bound" | high |
| §11.2 (4941) | `log_max` is a view policy: out of the trace header's deployment block, never compared at replay | accurate | `trace.jl:43–46` (no `log_max`), `trace.jl:352–361` | | `test_log.jl` "view policies, never trajectory-determining" | high |
| §11.2 (4949) | Output-device bindings are snapshot bindings, addressed with §14.4 selectors, compiled to one gather | accurate | `bindings.jl:121–149`, `devices.jl:267` | | `test_bindings.jl` "the compiled gather: wait → gather → map_output…" | high |
| §11.2 (4955) | A binding is resolved at attach against the `Build` **with did-you-mean** (offending name plus the list-in-hand) | partial | `bindings.jl:157–187`, `sim.jl:1237` | resolution and refusal are at attach ✔, but only `GetInput`'s `unknown_root_input` carries `candidates`; `GetOutput`'s `unknown_cell` and `GetFace`'s `unknown_output_face` carry none. `bindings.jl:136` says so in comment | `test_bindings.jl` "reads resolve at attach: binding drift fails there…" | high |
| §11.2 (4957) | `map_output` receives a labeled NamedTuple keyed by the names `reads` declared | accurate | `bindings.jl:126`, `bindings.jl:148` | labels are the type parameter, order preserved | `test_bindings.jl:220` | high |
| §11.2 (4970) | The two registers: deep path (inspection) vs `get_face(name)` (integration) | accurate | `bindings.jl:161`, `bindings.jl:179` | `get_face` refuses a root input and requires a root-exported output | `test_bindings.jl:197` | high |

### §11.3 — Inbound: root inputs, claims, the frozen roster (4977–5159)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.3 (4979) | The write surface is root inputs; the periphery addresses them by **face name**, never slash path | accurate | `dataplane.jl:430` (`layout.addr[("", f)]`), `dataplane.jl:464` | `_normalize` takes `Symbol(face)` only | `test_roster.jl:77` | high |
| §11.3 (5005) | One writer per root input at any time; claiming a claimed root input is an attach-time error | accurate | `sim.jl:1227–1232` (`ClaimConflict`) | | `test_roster.jl` "admission is three checks in spec order" | high |
| §11.3 (5008) | Detaching releases claims | accurate | `sim.jl:1261`, `roster.jl:230` | `reclaim!` rebuilds `claimedby` from the surviving roster | `test_roster.jl:142` | high |
| §11.3 (5023) | A data-dependent writer claims the binding's enumerated allowed set | accurate | `roster.jl:199–210` | `claims(b)` once at attach | `test_bindings.jl:91` | high |
| §11.3 (5035) | A batch entry reaches a root input iff the face is inside the writer's surface; anything else is discarded with a runtime warning | accurate | `dataplane.jl:464–495` | out-of-schema → `OutOfClaimEntry`/`ClaimedFaceEntry`; the rest of the batch stands | `test_dataplane.jl` "every check runs at staging, on the writer's side; the drain is pure" | high |
| §11.3 (5039) | Enforcement runs entirely at staging, on the writer's own task; the drain performs no checks | accurate | `dataplane.jl:464` vs `dataplane.jl:524` (`_apply!` is masked scatter only) | | `test_dataplane.jl:68` | high |
| §11.3 (5044) | Returned claim source: `is_input && !is_greedy` ⇒ `claims(b)` staked; drift onto an unenumerated face is `OutOfClaimEntry`, never a silent write | accurate | `roster.jl:203`, `dataplane.jl:471` | | `test_roster.jl:77` | high |
| §11.3 (5054) | Computed claim source: `is_greedy` ⇒ all root faces minus the union of rostered claims, at that instant, never recomputed | accurate | `roster.jl:201` | | `test_roster.jl` "the computed claim is the complement at the attach instant" | high |
| §11.3 (5063) | Past the attach point nothing distinguishes the two sources | accurate | `roster.jl:120`, `sim.jl:1240` (`Writer(layout, claim)` either way) | | `test_roster.jl:111` | high |
| §11.3 (5075) | The harness register: `stage!(sim, "face" => value, …)`, always-present cell, drained, traced and surface-checked as any device's | accurate | `sim.jl:1292`, `roster.jl:170`, `sim.jl:1339` | | `test_roster.jl` "the frame's outcome is a pure function of the drained batches, whoever staged them" | high |
| §11.3 (5081) | The harness surface is the unclaimed complement, recomputed at every stopped-sim roster change | accurate | `roster.jl:230–247` | | `test_roster.jl` "the harness surface is the unclaimed complement…" | high |
| §11.3 (5086) | A `stage!` write to a claimed face is rejected at staging with `ClaimedFaceEntry` naming the incumbent | accurate | `dataplane.jl:474–477` | | `test_dataplane.jl:68`, `test_roster.jl:127` | high |
| §11.3 (5088) | A rostered greedy claimant empties the harness surface outright (D-192) | accurate | `roster.jl:237` (complement of a full `claimedby` is empty) | | `test_roster.jl:127` | high |
| §11.3 (5093) | The harness cell drains **last**, by convention | accurate | `sim.jl:1335–1339` (roster loop, then `harness_drain()`) | | `test_trace.jl:38` (record order) | high |
| §11.3 (5100) | Root-input initial values owned by init/trim; totality enforced pre-write at every complete-world application | accurate | `sim.jl:611` (`assert_total(plan, …, :init!)`) | §14.6 is Agent E's; the pre-write placement is here and correct | `test_readers.jl` / `test_conditions.jl` | medium |
| §11.3 (5107) | `attach!`/`detach!` legal in `built`, `initialized` and `stopped`; error while `running`, with `ServiceLifecycle` | partial | `devices.jl:131`, `sim.jl:1213` | correct for the three named states and for `:running` (which spans the tail). The code **also admits `:errored`**, a state §11.3's list does not mention; the rationale is post-mortem reconfiguration. Not ratified by any D-nnn I found; see Spec problems | `test_roster.jl` "the roster is frozen per run…" | high |
| §11.3 (5117) | The roster is a plain immutable value read once at `run!`; no republication machinery, no atomic roster reference, no sequence numbers | accurate | `roster.jl:168` (`DataPlane` mutable but gated), `sim.jl:1335` | no atomics on `roster` | `test_roster.jl:201` | high |
| §11.3 (5126) | The trace tags entries with a stable device id, never a roster index | partial | `trace.jl:203` (`_who(e)` = `"device $id ($(typename))"`) | the tag is a **string** containing the id, not the id; it also carries the type name and moves if the type is renamed. Functionally stable within a run and across runs, but a schema entry is keyed by that string | `test_trace.jl:129` | medium |
| §11.3 (5137) | Device identity is the instance; `===` may occupy at most one entry | accurate | `sim.jl:1220` (`e.dev === dev`) | | `test_roster.jl:52` | high |
| §11.3 (5139) | Stable id assigned at `attach!`, monotonic per `Simulation`, never reused, living as long as the entry | accurate | `sim.jl:1238–1239` | assigned only on admission, so a rejected attach consumes none | `test_roster.jl` "device ids are monotonic per Simulation and never reused" | high |
| §11.3 (5146) | Admission is three checks in order: identity → `AlreadyAttached`, affinity → `CallerTaskConflict`, claims → `ClaimConflict` | accurate | `sim.jl:1219–1233` | order is exactly as written, which is what keeps `ClaimConflict` naming two distinct devices | `test_roster.jl` "admission is three checks in spec order" | high |
| §11.3 (5136) | Device death does not detach: the entry and its claims persist to run end; the loop is structurally indifferent | accurate | `devices.jl:348–357` (no roster mutation on crash) | | `test_devices.jl` "a crash is caught, shutdown! runs, the run continues, claims persist" | high |
| §11.3 (5136) | The orphan renders visibly ("claimed by `T16000M` — task dead") | pending | greps empty in `src/`: `orphan` (only a `devices.jl` comment), `task dead`, `read_only`, `provenance` (only build-time uses) | this is §11.7's rendering obligation, absent with §11.7 | none | high |

### §11.4 — Inbound: staging, representation, the drain (5160–5342)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.4 (5172) | One atomic staging cell per attached device, single writer, holding the latest pending batch | accurate | `dataplane.jl:24`, `dataplane.jl:420` | | `test_dataplane.jl:17` | high |
| §11.4 (5176) | Coalescing: CAS merge, newest wins per face; untouched faces survive | accurate | `dataplane.jl:502` (`_merge`), `dataplane.jl:510` (`_stage!`) | the generated body is the spec's sketch line for line | `test_dataplane.jl` "coalescing: merge only — newest wins per face…" | high |
| §11.4 (5180) | The CAS retry is bounded; an intercepted batch must not be re-staged | partial | `dataplane.jl:510` | correct for a single-writer cell. The harness cell admits *any* task (§11.3), so a CAS can also lose to another stager and the retry is not bounded in principle; the code's own docstring says this and the spec does not. See Spec problems | `test_dataplane.jl` "staging from another task: the CAS merge loses nothing it shouldn't" | high |
| §11.4 (5183) | Merge is the only policy; no `complete(binding)` overwrite opt-in | accurate | `dataplane.jl:502` is the sole path | grep `complete(` empty | `test_dataplane.jl:56` | high |
| §11.4 (5196) | The staged representation is fixed per attachment, compiled at attach, from the claim set and root-input types | accurate | `dataplane.jl:430` (`Writer(layout, faces)`), `sim.jl:1240` | | `test_roster.jl:77` | high |
| §11.4 (5203) | A values tuple `Tuple{T₁…Tₙ}` plus a parallel `NTuple{n,Bool}` mask; untouched positions carry placeholders and are never read | accurate | `dataplane.jl:402`, `dataplane.jl:430–437` | placeholders drawn from `layout.root_inputs` probe values, converted to `Tᵢ` | `test_dataplane.jl` "a wide surface stages, merges and drains like a narrow one" | high |
| §11.4 (5210) | The face-name → position schema lives in the roster entry | accurate | `dataplane.jl:421` (`Writer.faces`), `roster.jl:124` | | `test_trace.jl:38` | high |
| §11.4 (5237) | The drain applies each cell through an attach-compiled scatter, position → root-input cell, statically typed, masked positions skipped | accurate | `dataplane.jl:524` (`@generated _apply!`), `dataplane.jl:540` | | `test_roster.jl` "a populated device drain is as free as an empty one" | high |
| §11.4 (5243) | `stage!` normalizes face ⇒ value pairs through an attach-compiled shim: name → position, convert, set mask | accurate | `dataplane.jl:464` | the name → position step is a `findfirst` linear scan, O(width) per entry — permitted (writer's task) but note it for wide greedy surfaces | `test_dataplane.jl` "the shim converts to the activation's root-input types" | high |
| §11.4 (5253) | A greedy entry needs no special treatment: its cell is compiled exactly as a joystick's | accurate | `sim.jl:1240` | one code path | `test_roster.jl:111` | high |
| §11.4 (5258) | The harness cell is compiled to a positional shape unasked, recompiled at each `attach!`/`detach!`, with the same shim, merge and scatter | accurate | `roster.jl:230–247`, `roster.jl:184` | | `test_roster.jl:142` | high |
| §11.4 (5270) | The recompilation seam: a pending harness batch is reshaped at attach, newly-claimed faces discarded with `ClaimedFaceEntry` | accurate | `roster.jl:236–246` (`site = :renormalization`) | | `test_roster.jl` "the recompilation seam: a pending harness batch is renormalized at attach" | high |
| §11.4 (5277) | Every diagnostic site is at staging: face validity, surface membership, convertibility | accurate | `dataplane.jl:464–495` | `OutOfClaimEntry`, `ClaimedFaceEntry`, `EntryTypeMismatch`, all in `_normalize` | `test_dataplane.jl:68` | high |
| §11.4 (5290) | Nothing remains at the drain; the drain is pure application | accurate | `dataplane.jl:540` | | `test_dataplane.jl:68` | high |
| §11.4 (5294) | Staged values are levels, never deltas | accurate | doctrine; `bindings.jl:209` (`_condition` passes counters through) | not enforceable, correctly taught | `test_bindings.jl:103` | high |
| §11.4 (5298) | The drain takes each cell with one `atomicswap(cell, nothing)` — an indivisible take, no lost-write window | accurate | `dataplane.jl:541` | | `test_dataplane.jl:157` | high |
| §11.4 (5302) | Applied in attachment order | accurate | `sim.jl:1335` iterates `plane.roster`, which is attachment order | | `test_trace.jl:38` | high |
| §11.4 (5314) | Because the roster is fixed, the drain is compilable with zero dynamic dispatch at frame top | accurate | `roster.jl:144` (`_drain_thunk`), `trace.jl:384` | the per-entry dispatch the spec licenses as acceptable | `test_dataplane.jl` "an empty drain is free…", "a populated drain is as free as an empty one" | high |
| §11.4 (5324) | Mappings run on the device task; `map_input(data, mapping) → batch` is pure | accurate | `bindings.jl:91`; framework never calls it | | `test_bindings.jl` "the loop idiom end to end: poll → map_input(binding(handle)) → stage!" | high |
| §11.4 (5330) | `TableBinding` applies deadzone/expo in its generic `map_input`, on the device task | accurate | `bindings.jl:209` | endpoints fixed, midrange attenuated, as described | `test_bindings.jl` "the conditioning: deadzone rescales, expo attenuates, endpoints fixed" | high |
| §11.4 (5340) | The trace records post-conditioning levels | accurate | conditioning happens in `map_input` upstream of `stage!`; `_record!` sees the drained tuple | | `test_trace.jl:38` | high |

### §11.5 — Inbound: the input trace (5343–5446)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.5 (5345) | The trace is the sequence of drained, device-tagged batches per frame | accurate | `trace.jl:58`, `trace.jl:184` | | `test_trace.jl` "one sparse record per drained batch, against the writer's schema" | high |
| §11.5 (5352) | One record format: every batch retained sparse, masked entries as (position ⇒ value) against the writer's schema | accurate | `trace.jl:184–197` | two O(width) scans, exact-length allocation | `test_trace.jl:38` | high |
| §11.5 (5358) | Uniform regardless of claim source or width (D-176) | accurate | `trace.jl:184` — one path | | `test_trace.jl:38` | high |
| §11.5 (5359) | The conversion site is the drain, not the staging shim, because the drained tuple is the coalesced truth | accurate | `dataplane.jl:545` (`_record!` inside `_drain!`) | | `test_trace.jl:61` | high |
| §11.5 (5388) | The header captures the full initial state `(x, s, m)` plus the initial root-input values | accurate | `trace.jl:277–298` | `s`/`m` deep-copied per component | `test_trace.jl` "the header is the pre-sequence state, resolved" | high |
| §11.5 (5389) | Captured **after `apply!` and the root-input writes, before the boundary-zero sequence** | accurate | `sim.jl:615–617` (`apply!` → `_open_trajectory!` → `_capture!` → `boundary_zero!`) | | `test_trace.jl:75` | high |
| §11.5 (5392) | The header holds resolved values, never the authored overlay | accurate | `trace.jl:281–284` reads the stores and cells | | `test_trace.jl:75` | high |
| §11.5 (5407) | The header carries each writer's face-name → position schema | accurate | `trace.jl:42`, `trace.jl:202` | | `test_trace.jl:129` | high |
| §11.5 (5408) | The schema list only grows: every capture and roster change appends the current set; earlier records keep their index | accurate | `trace.jl:234–254` | header rebuilt rather than mutated, so an already-handed-out `Trace` keeps a valid prefix | `test_trace.jl` "a roster change appends the writer set; earlier records keep their schema" | high |
| §11.5 (5415) | The deployment block: `t₀`, `Δt_base`, `h`, `n`, algorithm, `localization_tol`, `localization_budget`, `firing_budget`, `t_end`/`stop_on`, captured at the same instant | accurate | `trace.jl:43–46`, `trace.jl:287–292` | all ten present; `t_end`/`stop_on` are the constructor's, `run!`'s override post-dating the capture as specified | `test_trace.jl:90` | high |
| §11.5 (5432) | The trace carries its length — the number of drains since the capture | accurate | `trace.jl:83`, `sim.jl:1341` | one increment per drain, live and replay paths both | `test_trace.jl:38` | high |
| §11.5 (5437) | Trace recording is on by default, cleared at `init!`, retrievable after the run, with a plain kill switch | accurate | `sim.jl:134` (`trace = true`), `sim.jl:616`, `sim.jl:1516` | `trace(sim)` refuses under the switch and before the first `init!` | `test_trace.jl` "the kill switch, and the clearing at `init!`" | high |

### §11.6 — Devices: the authoring contract (5447–5801)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.6 (5453) | One handle per attached device, carrying read, stage and control access | accurate | `devices.jl:151`, `devices.jl:205–319` | `running`, `stop!`, `latest`, `wait_next_snapshot`, `stage!`, `gather`, `report!`, `binding` | `test_devices.jl:110` | high |
| §11.6 (5461) | `should_abort` is an `attach!` keyword defaulting `false`, per attachment | accurate | `sim.jl:1212`, `roster.jl:126` | | `test_devices.jl` "a crash under should_abort requests the stop" | high |
| §11.6 (5479) | A device subtypes `AbstractDevice`; a binding subtypes `AbstractBinding` | accurate | `roster.jl:26–27` | | `test_roster.jl:30` | high |
| §11.6 (5485) | Four functions plus one trait: `init!`, `loop`, `shutdown!`, `unblock!`, `needs_calling_task` | accurate | `devices.jl:183–187`, `roster.jl:39` | defaults: no-op ×3, error-throwing `loop`, `false` trait | `test_devices.jl` "a device with no loop method is refused at attach!, by kind" | high |
| §11.6 (5498) | The wrapper: spawn, `catch` → `DeviceCrash`, `finally` → `shutdown!` + heartbeat-only death mark | accurate | `devices.jl:348–358` | no `mark_dead!` machinery, correctly: `task_state` and the stale heartbeat carry it (§11.8/§12.2) | `test_devices.jl:173` | high |
| §11.6 (5512) | `shutdown!` must tolerate a partially initialized device; `init!` is bracketed and is not asked to clean up | accurate | `devices.jl:374–389`, `devices.jl:325` | `_shutdown!` also guards a throw out of `shutdown!` itself | `test_devices.jl` "a failed init! is bracketed: shutdown!, no task, claims persist" | high |
| §11.6 (5527) | **An `InterruptException` is never a `DeviceCrash`**: the wrapper forwards the control-plane stop and lets the body leave through `running(handle)`, with no crash report and no `should_abort` consultation | deviation | `devices.jl:348–357` | `_wrap` catches every `err` and reports `DeviceCrash(err, should_abort)`, then consults `should_abort` in the `finally`. Nothing discriminates `InterruptException`. No D-nnn covers it; the file header (`devices.jl:6`) records the operator interrupt as absent generally | none | high |
| §11.6 (5541) | Author-owned loop body; no framework hook loop | accurate | `devices.jl:350` calls `loop(dev, handle)` and nothing else | | `test_bindings.jl:146` | high |
| §11.6 (5583) | Liveness timestamps ride inside the handle primitives | accurate | `devices.jl:205, 236, 249, 268, 291, 307` — every primitive calls `_beat!` | | `test_diagnostics.jl` "the heartbeat rides in the cell, stored by the handle primitives" | high |
| §11.6 (5580) | A forgotten predicate check surfaces as `DeviceJoinTimeout` with the device's name | accurate | `devices.jl:448` | | `test_devices.jl` "a body ignoring the predicate is abandoned under join_timeout, by name" | high |
| §11.6 (5588) | `should_close` dissolves: a window ✕ or EOT is the loop body returning | accurate | grep `should_close` empty in `src/` | | `test_devices.jl:110` | high |
| §11.6 (5602) | Sides declared by `is_input`/`is_output`/`is_greedy` with `false` roots | accurate | `roster.jl:36–38` | | `test_roster.jl:30` | high |
| §11.6 (5636) | `reads(b)` returns a labeled NamedTuple of selectors; labels carried through compilation in declaration order | accurate | `bindings.jl:138–149` | `ReadGather{L}` with `L = keys(nt)` | `test_bindings.jl:220` | high |
| §11.6 (5645) | `claims`/`reads` have error-throwing fallbacks on the root | accurate | `roster.jl:50`, `roster.jl:61` | both throw `BindingContractMismatch` | `test_roster.jl:30` | high |
| §11.6 (5648–5666) | Bidirectional conformance check, all six rules | accurate | `roster.jl:74–90` | `:greedy_without_input`, `:neither_side`, `:greedy_with_claims`, `:claims_without_input`, `:reads_without_output`, plus the two `_missing` fallbacks. Detection is one `which` against the fallback, at a stopped-sim point | `test_roster.jl` "the binding conformance check names every drift at the attach point"; `test_bindings.jl` "the output side completes the conformance check, both directions" | high |
| §11.6 (5668) | Every violation reports `BindingContractMismatch` naming the binding type, the trait, the method at fault and the direction | partial | `roster.jl:50–88`, `diagnostics.jl` | the payload is `(binding, reason)`; `reason` encodes method + direction jointly, and there is no separate trait field. Also inconsistent naming: the fallbacks use `_typename(b)` while `check_binding` uses `string(T)` | `test_roster.jl:30` | medium |
| §11.6 (5698) | Greediness stays orthogonal to `reads` | accurate | `roster.jl:74–90` — no rule couples them | | `test_bindings.jl:177` | high |
| §11.6 (5729) | A second greedy attach stakes the empty remainder and reports `EmptyGreedyClaim` naming device and binding | accurate | `sim.jl:1247–1248` | emitted as `@warn logline(...)`, a service warning | `test_roster.jl:111` (D-192 case) | high |
| §11.6 (5748) | The empty enumeration is an honest degenerate; drift is `OutOfClaimEntry`; `claims` never returns a sentinel | accurate | `roster.jl:202–209`, `roster.jl:50` | | `test_roster.jl:103` | high |
| §11.6 (5762) | `TableBinding` is data-driven; the entry tuple rides in the type; face mandatory, deadzone/expo optional; any other key is a construction error | accurate | `bindings.jl:35–69` | vocabulary check, range checks on deadzone/expo, collected as `ArgumentInvalid` | `test_bindings.jl` "TableBinding construction validates the table's shape" | high |
| §11.6 (5788) | Bad datum vs bug: `report!(handle, MalformedDatum(cause))`, catch/stage nothing/continue; any other exception propagates to the wrapper | accurate | `devices.jl:291`, typed `::MalformedDatum` so nothing else fits | | `test_diagnostics.jl` "a bad datum is tolerated: catch, stage nothing, report, continue" | high |
| §11.6 (5796) | `report!` is not a general user-diagnostics channel; no marked exception type provided | accurate | `devices.jl:291` — the method admits only `MalformedDatum` | | `test_diagnostics.jl:59` | high |
| §11.6 (5451) | The shipped GUI declares `needs_calling_task` and attaches with `should_abort = true` | pending | greps empty in `src/`: `GUI`, `gui`, `CImGui`, `draw!` | no shipped GUI device exists; the trait and the topology that serve it do | `test_devices.jl:281` (a test stub holds the trait) | high |

### §11.7 — The GUI write path (5802–5895)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.7 (5808) | Build-time port resolution: is this port transitively driven by a root input, and which one | pending | greps empty in `src/`: `resolve_port`, `port_resolution`, `root_driven`, `root-driven`, `feed chain`, `transitively`, `driven by`, `commandable` | | none | high |
| §11.7 (5810) | Root-driven and within the GUI's claim ⇒ live widget: peeks and stages the resolved root input | pending | greps empty in `src/`: `peek`, `live_widget`, `input_slider` | | none | high |
| §11.7 (5812) | Component-driven or claimed elsewhere ⇒ read-only rendering with the source as provenance | pending | greps empty in `src/`: `read_only`, `readonly`, `provenance` (only build-time `SchedulingInvalid`/condition uses) | | none | high |
| §11.7 (5831) | Liveness is derived and transitive; baked once at run start, never consulted at render; no per-port "GUI-controlled" marking | pending | greps empty in `src/`: `derived liveness`, `live iff`, `baked` | | none | high |
| §11.7 (5860) | Peek rule: own pending write if any, else the snapshot value; own-cell only | pending | grep `peek` empty in `src/` | | none | high |
| §11.7 (5869) | Staging contract: widgets stage on interaction events only; edge widgets stage `k+1` from the peek | pending | grep `peek`/`widget` empty in `src/` | | none | high |
| §11.7 (5884) | The orphan display rule: "claimed by `T16000M` — task dead" beside the ordinary snapshot value | pending | greps empty in `src/`: `task dead`, `orphan` (one comment only) | the *data* it would render exists: `WriterStatus.task_state` (`dataplane.jl:357`) and `stale` (`dataplane.jl:385`) | none | high |
| §11.7 (5888) | Panel calling convention deferred to §16, with four fixed constraints | pending | n/a | the spec itself defers this; recorded for completeness, not a gap | none | high |

### §11.8 — Diagnostics and liveness: the per-writer cell (5896–6016)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §11.8 (5900) | Writers are: whichever task stages, the device tasks, and the loop (`ChatteringBudget`, `FiringBudget`, `DebtReanchor`) | partial | `dataplane.jl:464`, `devices.jl:291`, `sim.jl:449` (`FiringBudget`), `localization.jl` (`ChatteringBudget`) | **`DebtReanchor` is absent**, with the pacer. The other five sources are present | `test_localization.jl:116`, `test_diagnostics.jl:59` | high |
| §11.8 (5910) | One diagnostic cell per writer: one per rostered device, one for the harness register, one for the loop | accurate | `roster.jl:127`, `roster.jl:172`, `sim.jl:47` | | `test_diagnostics.jl:103` | high |
| §11.8 (5913) | The harness register's cell carries no heartbeat and its status record no `task_state` | accurate | `sim.jl:1461` (`nothing, nothing`) | same for the loop's | `test_diagnostics.jl:103` | high |
| §11.8 (5917) | Bounded accumulation: a ring of capacity **16** plus a per-kind count of what it could not hold, and one atomic liveness timestamp | accurate | `dataplane.jl:226` (`DIAG_RING = 16`), `dataplane.jl:238`, `dataplane.jl:262` | | `test_diagnostics.jl` "the ring's bound is the rate limit: 16 retained, excess to the counts" | high |
| §11.8 (5921) | Drop policy: earliest-in-frame retained, excess becomes counts | accurate | `dataplane.jl:271–280` | | `test_diagnostics.jl:86` | high |
| §11.8 (5931) | The cells are disjoint, so no writer can starve another | accurate | one `DiagCell` per writer, no shared structure | | `test_diagnostics.jl:169` | high |
| §11.8 (5934) | The drain is the same drain §11.4 specifies: one `atomicswap` per cell at frame top; a shared **empty sentinel** is swapped in | accurate | `dataplane.jl:286` (`_take!`), `dataplane.jl:245` (`EMPTY_DIAG`), `sim.jl:1336–1340` | quiet frame gets the sentinel back, no allocation, no load-only path | `test_dataplane.jl` "an empty drain is free…" | high |
| §11.8 (5946) | The heartbeat rides in the same cell as an atomic timestamp, stored by the handle primitives, acquire-loaded by the loop | accurate | `dataplane.jl:264`, `dataplane.jl:290–291`, `sim.jl:1458` | acquire-load happens at **publication**, not at the drain as §11.8's prose says; §12.2/D-193 puts `task_state` at publication too, so this is the consistent reading | `test_diagnostics.jl` "the heartbeat rides in the cell…" | medium |
| §11.8 (5951) | The heartbeat is a field, always present, never a diagnostic kind | accurate | `dataplane.jl:264` | | `test_diagnostics.jl:212` | high |
| §11.8 (5954) | Per writer the status carries `recent`, `suppressed`, `totals` (copied), `heartbeat` and `task_state` | accurate | `dataplane.jl:351–358`, `sim.jl:1444–1450` | `KindCounts` is isbits, so the read is the copy | `test_diagnostics.jl:103` | high |
| §11.8 (5960) | `totals` is owned privately by the loop and is cumulative since the run began | accurate | `dataplane.jl:307`, `sim.jl:995` (`_reset_accounts!` at every run top and at `init!`) | | `test_diagnostics.jl:161` | high |
| §11.8 (5962) | Beside the per-writer records ride the pacer diagnostics | pending | greps empty in `src/`: `pacer`, `margin`, `debt`, `PacerDiagnostics` | absent with §10.7 | none | high |
| §11.8 (5971) | Presentation: a status renderer prints a writer × kind up to **25** cumulative occurrences and then switches to count-only | pending | greps empty in `src/`: `maxlog`, `Base.show(.*FrameworkStatus`, `Base.show(.*WriterStatus`, `= 25`, `MAXLOG` | there is **no status renderer at all**. The only presentation in the slice is `_residue!`'s per-entry `@warn` (`devices.jl:489`), which is the termination record's, not the status's | none | high |
| §11.8 (5980) | The terminal snapshot carries the run's final cumulative counters, complete to the final frame top | accurate | `sim.jl:1454`, `dataplane.jl:664` (`L.last`) | | `test_diagnostics.jl:149` | high |
| §11.8 (5986) | What lands after the final frame top is taken once more at the run's end and folded into the termination record as the tail residue, presented through the logging backend, never published | accurate | `devices.jl:467–496`, `sim.jl:985–987` | `@warn` per entry plus a suppressed-count line | `test_diagnostics.jl` "the run's-end sweep: past the final frame top, loud rather than lost" | high |
| §11.8 (5995) | Zero additional heap allocation on a quiet frame; the counters are a fixed-shape isbits record, never a `Dict` | accurate | `dataplane.jl:196` (`KindCounts`), `dataplane.jl:325–329` (early return on the sentinel) | | `test_dataplane.jl:174`, `test_roster.jl:242` | high |
| §11.8 (6005) | A drained non-empty ring is frozen and never written again; the writer allocates a fresh ring lazily at its next emission | accurate | `dataplane.jl:271–280` — `_report!` copies the ring on append and `_take!` swaps the sentinel in | | `test_diagnostics.jl:86` | high |
| §11.8 (6012) | `totals` monotone across logged snapshots | accurate | `dataplane.jl:334` (`a.totals = a.totals + counts`), never reset within a run | | `test_diagnostics.jl:126` | high |

### §12.1 — Control plane (6024–6049)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §12.1 (6026) | Pause, un-pause, pace changes, `margin` changes, stop: a few scalar fields on a separate atomic surface, consulted at frame top and inside the wait and pause states | partial | `devices.jl:108` (`Control`) | the surface exists and carries stop plus the sticky status. **Pause, un-pause, pace and `margin` are absent** — greps empty in `src/`: `pause`, `unpause`, `pace` (only `namespace`/`paces` hits), `margin` | `test_devices.jl:155` | high |
| §12.1 (6034) | The stop word carries its issuer; each site writes its identity by CAS from empty and the first writer wins | accurate | `devices.jl:109`, `devices.jl:121` (`@atomicreplace ctl.stop_issuer nothing => issuer`) | `:code`, the device's name, `:interrupt` | `test_devices.jl` "stop! from any task ends the run at a frame top" | high |
| §12.1 (6038) | The loop's frame-top read consults the word for non-empty; the issuer lands in `ControlRequestedStop` | accurate | `sim.jl:1030–1031`, `devices.jl:42` | | `test_devices.jl:155` | high |
| §12.1 (6041) | Not staging, structurally: control rides outside the drain/trace path | accurate | `Control` is disjoint from `DataPlane` | | none | high |
| §12.1 (6047) | While paused the loop blocks on a condition, not a spin | pending | greps empty in `src/`: `pause`, `paused`, `unpause` | absent with the pause | none | high |

### §12.2 — Loop scheduling, yields, thread budget (6050–6123)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §12.2 (6060) | The coarse phase uses task-yielding `sleep`; no `systemsleep` variant | pending | greps empty in `src/`: `sleep`, `systemsleep` | there is no coarse phase; the pacer is absent | none | high |
| §12.2 (6072) | With devices attached, every frame yields at least once | accurate | `sim.jl:1033` (`isempty(plane.roster) || yield()`) | keyed on the roster being non-empty rather than on live entries; a rostered device whose `init!` failed still buys the yield, which is harmless and arguably right | none | high |
| §12.2 (6079) | The spin phase never yields | pending | grep `spin` empty in `src/` | absent with the pacer | none | high |
| §12.2 (6088) | The thread budget is a documented sizing rule and a startup warning, not a hard error; `run!` warns when `Threads.nthreads()` is tight, naming `julia -t`, once per run against the frozen roster | pending | greps empty in `src/`: `nthreads`, `ThreadBudget`, `julia -t`. `dataplane.jl:36` records `ThreadBudget` as an absent kind | | none | high |
| §12.2 (6103) | Liveness heartbeat: the record is the published framework status, carrying the timestamp and `task_state` beside the pacer diagnostics | partial | `dataplane.jl:351–358`, `sim.jl:1456–1458` | timestamp and `task_state` present and read off the run's `Task` handles at publication (D-193). The pacer diagnostics half is absent | `test_diagnostics.jl` "liveness: heartbeat and task_state ride the device's record" | high |
| §12.2 (6112) | `task_state` read off the device `Task` handles the loop owns | accurate | `roster.jl:174` (`run_tasks`), `dataplane.jl:390` (`_task_state`), `sim.jl:1457` | `:none`/`:running`/`:done`/`:failed`; `run_tasks` is filled before the loop starts and emptied at run end | `test_diagnostics.jl:132` | high |
| §12.2 (6119) | Stale means a timestamp more than **2 s** behind wall clock; advisory only, never a kill trigger or a detach | accurate | `dataplane.jl:373` (`STALE_S = 2.0`), `dataplane.jl:385` | a never-heartbeated cell's `0.0` reads stale unconditionally, which is the failed-`init!` case §12.4 wants | `test_diagnostics.jl:132` | high |

### §12.3 — The next-snapshot wait (6124–6184)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §12.3 (6131) | Two artifacts: a monotonic boundary counter published with the snapshot, plus one `Threads.Condition` | accurate | `devices.jl:111–112`, `dataplane.jl:567` | | `test_devices.jl` "the boundary ordinal rides in the snapshot" | high |
| §12.3 (6135) | The counter counts *published boundaries* — grid, `t*`, boundary zero — not frames | accurate | `sim.jl:1436` — incremented once per `publish!`, and `publish!` follows every boundary sequence | | `test_log.jl:8` | high |
| §12.3 (6139) | The loop's publication is `lock; counter += 1; notify; unlock` | accurate | `sim.jl:1435–1441` | | `test_devices.jl:130` | high |
| §12.3 (6143) | `wait_next_snapshot(handle)` blocks until `counter > last_seen && running`, under the canonical predicate loop | accurate | `devices.jl:306–319` | predicate is `counter <= last_seen && !stopped`; `last_seen` refreshed after the wake | `test_devices.jl` "wait_next_snapshot observes ordered boundaries and wakes on the stop" | high |
| §12.3 (6148) | Shutdown works because §12.4 wakes all waiters and each predicate routes its owner out | accurate | `devices.jl:406–415` — `@atomic stopped = true` then `lock/notify/unlock`; Julia's `notify` defaults to all | no lost-wakeup: a waiter testing the predicate holds the lock, so `_finish!` blocks until it parks | `test_devices.jl:130` | high |
| §12.3 (6150) | An `Event` latch is the wrong primitive | accurate | grep `Event(` empty in `src/` | | none | high |
| §12.3 (6154) | The boundary index is carried *in* the snapshot with `t`; the loop mirrors it in the state the predicate tests | accurate | `dataplane.jl:567`, `devices.jl:111` | the snapshot's `boundary` is the pre-increment value, so `snap.boundary == k` corresponds to `counter == k+1`; the spec never fixes that convention (see Spec problems) | `test_devices.jl:146` | high |
| §12.3 (6160) | **Normative order**: the release-store of `latest` happens **before** the counter increment under the lock | accurate | `sim.jl:1430` then `sim.jl:1435–1441` | `log!` sits between them, which touches nothing a waiter observes | `test_devices.jl:130` | high |
| §12.3 (6178) | Newest-wins, no queues, no backpressure; the loop never waits on anyone | accurate | `devices.jl:318` returns `latest(h)` after the wake, not a queued value | | `test_devices.jl:130` | high |
| §12.3 (6183) | The GUI does not use the wait | pending | no GUI in `src/` | not a gap in the mechanism | none | high |

### §12.4 — Shutdown protocol (6185–6462)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §12.4(1) (6199) | Three initiation events: `t_end`, a control-plane stop, a `stop_on` face true in the just-published snapshot | accurate | `sim.jl:1030–1032`, `sim.jl:284` (`_stop_hit`) | | `test_lifecycle.jl:94, 141, 174`; `test_devices.jl:155` | high |
| §12.4(1) (6206) | The loop always completes the current boundary sequence and never stops mid-frame; then publishes the final snapshot; only then sets the sticky stopped status | accurate | `sim.jl:1029–1049`, `devices.jl:406–408` | the stop word is read at frame top, so the previous frame is complete and published | `test_devices.jl:155` | high |
| §12.4(2) (6209) | Wake all framework waits: the next-snapshot wait and the pause | partial | `devices.jl:406–415` | the next-snapshot wait is woken; there is no pause to wake | `test_devices.jl:130` | high |
| §12.4(3) (6213) | Unblock device-specific blocking calls via `unblock!(device)`, default no-op | accurate | `devices.jl:185`, `devices.jl:432–439` | a throw out of the hook is warned and the tail proceeds | `test_devices.jl` "unblock! makes the blocking call return: a clean exit, no timeout" | high |
| §12.4(4) (6219) | Loop bodies exit through `while running(handle)`; the wrapper's `finally shutdown!` is guaranteed | accurate | `devices.jl:205`, `devices.jl:354` | | `test_devices.jl:173` | high |
| §12.4(5) (6225) | Join under the `join_timeout` cap; a device exceeding it is abandoned with `DeviceJoinTimeout` rather than left to hang `run!` | deviation | `devices.jl:440–451` | the cap is applied as **one shared deadline for the whole tail** (`deadline = time() + join_timeout`, each device getting `deadline - time()`), not per device. With n devices the last may get zero patience and be abandoned though it would have joined. D-198's "one value for the whole tail: the join loop has one patience" plausibly ratifies one *value*; it does not clearly ratify one *deadline* | `test_devices.jl` "a body ignoring the predicate is abandoned under join_timeout, by name" (single device, so the two readings coincide) | medium |
| §12.4(5) (6225) | `join_timeout` is a `Simulation` deployment keyword, positive real, default 5 | accurate | `sim.jl:134`, `sim.jl:147` | | `test_devices.jl` "join_timeout is validated and never trajectory-determining" | high |
| §12.4(5) (6229) | The timeout is written to the loop's own cell, collected by the run's-end sweep into the termination record and presented through the logging backend, the terminal snapshot preceding the join | accurate | `devices.jl:448`, `devices.jl:476–478`, `devices.jl:489` | | `test_devices.jl:241` | high |
| §12.4(6) (6232) | Voluntary exit; with `should_abort` set the wrapper's exit path also requests a sim stop; otherwise the sim continues with the task absent, entry and claims persisting | accurate | `devices.jl:355` | | `test_devices.jl:110, 190` | high |
| §12.4(6) (6243) | A crashing task is caught by the wrapper and follows the same path, logged with the device's name | accurate | `devices.jl:351–352`; the writer attribution is the cell's | | `test_devices.jl:173` | high |
| §12.4(7) (6246) | Loop-side failure runs steps (1)–(5) from the catch path; the failed boundary is discarded and the previous snapshot promoted | accurate | `sim.jl:938–941` (`finally _finish!; _tail!`), `sim.jl:961–970` | publication is a boundary's last act, so a failed boundary published nothing | `test_lifecycle.jl` "§13.6: a loop-side throw discards the failed boundary and promotes the last one" | high |
| §12.4 (6270) | The final snapshot goes out before the status is set | accurate | `_advance!` returns after the last `publish!`; `_finish!` runs after it | | `test_devices.jl:155` | high |
| §12.4 (6278) | The terminal snapshot is retained in the log unconditionally, under any `log_every` and any `log_max` | accurate | `dataplane.jl:664` (`L.last = snap` on every publication) | `log = false` retains nothing at all, which the spec does not address (see Spec problems) | `test_log.jl:53` | high |
| §12.4 (6281) | **`t_end` lands on the grid: the run ends at the first grid boundary whose time reaches or exceeds `t_end`**, whole frames only, overshooting by up to `h` | deviation | `sim.jl:883` (`round(Int, te / sim.h)`), `sim.jl:1131` (same in `step!`), `sim.jl:790` (same in `replay!`) | `round` gives the **last** boundary before `t_end` whenever `t_end/h` has fractional part below ½ — e.g. `h = 0.1, t_end = 0.24` stops at t = 0.2. D-133 (decisions.md:3891) states the reach-or-exceed rule and **explicitly rejects** "ending at the last boundary before `t_end`". Unratified. `step!`'s `t_plus` uses `ceil` correctly (`sim.jl:1127`), so the two spellings disagree | `test_lifecycle.jl:94` uses `t_end = 1.0, h = 1//50` — an exact multiple, so the bug is invisible | high |
| §12.4 (6281) | The boundary *time* is what reaches `t_end` | deviation | `sim.jl:883`, `sim.jl:1131` | the target ignores `clock.t₀`: the comparison is `clock.step < round(t_end/h)`, so with `init!(sim; t0 = 10.0)` a `t_end = 12.0` run ends at t = 22. `t₀` is a legitimate `init!` argument (`sim.jl:606`) and is used by trim's resumed spelling. No D-nnn found | none (no test combines `t0 ≠ 0` with `t_end`) | medium |
| §12.4 (6293) | The two termination sources differ in kind: `t_end` a grid fact, `stop_on` checked at every published boundary including `t*` | accurate | `sim.jl:1032` vs `sim.jl:1041, 1044` | | `test_lifecycle.jl` "a localized stop ends the run at t*, the crossing state final" | high |
| §12.4 (6304) | The calling-task device sits outside the join | accurate | `sim.jl:958` (`_tail!(sim, others, tasks)`) | | `test_devices.jl:281` | high |
| §12.4 (6318) | What survives the tail: the roster entry, binding, claims, id; never a task, never a live resource | accurate | `sim.jl:974` (`empty!(plane.run_tasks)`), roster untouched | | `test_devices.jl:173` | high |
| §12.4 (6324) | One roster change belongs to the tail: a `gui = true` GUI is detached here, releasing its computed claim, on the failure path too | pending | greps empty in `src/`: `gui`, `gui = true`, `GUI` | absent with the GUI | none | high |
| §12.4 (6331) | The next run re-runs device `init!` and spawns fresh tasks against the re-armed §12.3 counter | accurate | `sim.jl:930`, `devices.jl:394–396` | the counter is not re-armed; `last_seen` is refreshed at spawn instead, which is equivalent and documented (`devices.jl:100–106`) | `test_devices.jl:130` | high |
| §12.4 (6343) | Initialization: `init!` once per roster entry, in attachment order, on the calling task, before any spawn, each in its own bracket | accurate | `devices.jl:374–389`, called at `sim.jl:930` before `_spawn!` | | `test_devices.jl` "a failed init! is bracketed: shutdown!, no task, claims persist" | high |
| §12.4 (6355) | The bracket: `shutdown!` unconditionally, `report!(entry, DeviceCrash(e))`, mark dead, `should_abort && stop!` | accurate | `devices.jl:380–384` | the report is addressed by the entry's own cell; no `mark_dead!` needed — the never-heartbeated `0.0` reads stale from frame one | `test_devices.jl:201` | high |
| §12.4 (6372) | The report is the ordinary `DeviceCrash`, not a kind of its own; addressed by the roster entry, no call passes a device id | accurate | `devices.jl:382`, `dataplane.jl:104` (payload is `cause`, `abort`) | | `test_devices.jl:201` | high |
| §12.4 (6386) | No task is spawned for a failed device; it is dead from boundary zero, its cell never receiving a timestamp | accurate | `devices.jl:386` (`ok && push!(live, e)`), `dataplane.jl:267` (`DiagCell(b) = DiagCell(b, 0.0)`) | | `test_devices.jl:201` | high |
| §12.4 (6396) | The claims of a failed device persist to run end | accurate | no roster mutation in `_init_devices!` | | `test_devices.jl:201` | high |
| §12.4 (6404) | With `should_abort` set the stop is already pending at boundary zero; the run publishes boundary zero and ends `stopped` at `t₀` through the same tail; remaining entries still get their `init!`/`shutdown!` pair | accurate | `devices.jl:383`, `sim.jl:928–931`, `sim.jl:1030` | boundary zero was published by `init!`; `_advance!` advances zero frames and returns `ControlRequestedStop` | `test_devices.jl:190` | high |
| §12.4 (6420) | Topology derived after initialization: a failed calling-task holder returns the loop to the calling task | accurate | `sim.jl:932` searches `live`, not `plane.roster` | | none directly | high |
| §12.4 (6428) | The operator interrupt is a stop, not a failure: complete the boundary, publish, take the tail, end `stopped`, fully serviceable and resumable | partial | `sim.jl:1056` | the frame loop's catch turns an `InterruptException` into `ControlRequestedStop(:interrupt)` and takes the ordinary tail, so the *classification* is right. But without masking the frame is abandoned mid-boundary and the stores may be half-written — exactly the outcome the masking rule exists to prevent, as the code's own comment concedes | none | high |
| §12.4 (6445) | **Masking across the boundary is normative**: `disable_sigint` across the macro-sequence, the deferred raise taken at the frame top and inside the wait and pause blocks | pending | greps empty in `src/`: `disable_sigint`, `sigatomic`, `sigatomic_begin`, `unmask` | | none | high |
| §12.4 (6456) | A second interrupt during the tail collapses the remaining joins immediately; the run still ends `stopped` | pending | greps empty in `src/`: `disable_sigint`, `second interrupt`; `_tail!` has no interrupt handling | | none | high |
| §12.4 (6459) | Interactive-session scope: the framework flips nothing process-global | accurate | grep `exit_on_sigint` empty in `src/` | | none | high |

### §12.5 — Scripts and mid-run mutation (6463–6529)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §12.5 (6477) | A sim-time script becomes a source or supervisor component; a wall-clock interaction becomes a device | accurate | structural: `declare.jl`/`assembly.jl` admit an ordinary periodic discrete component reading `t` from its bundle; `roster.jl:26` is the device door | nothing in `src/` privileges a "script" — which is the point | `test_discrete.jl` (periodic components) | medium |
| §12.5 (6493) | `user_callback!` is eliminated | accurate | grep `user_callback` empty in `src/` | | none | high |
| §12.5 (6499) | Manual event triggering needs no mechanism: a root input plus a boundary-detected guard | accurate | `executor.jl` event set + `stage!` | | `test_localization.jl:156` ("the u seam, through the drain") | medium |
| §12.5 (6505) | Mid-run re-initialization is not built | accurate | `init!` refuses `:running` (`sim.jl:609`) | | `test_lifecycle.jl:67` | high |
| §12.5 (6513) | The doctrine's final form: while a simulation runs the periphery stages root-input writes and issues control commands, and nothing else | accurate | the only mutating entry points reachable from a handle are `stage!` and `stop!` (`devices.jl:151`, which deliberately does not carry the `Simulation`) | `stage!(sim, …)` and `port(sim, …)`/`state(sim, …)` are reachable from a held `Simulation` with no lifecycle gate — see the unguarded-edge note in §1 | `test_readers.jl:193` | medium |

### §12.6 — Run lifecycle and partial advance (6530–6661)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §12.6 (6532) | Five states: built, initialized, running, terminally stopped or errored | accurate | `devices.jl:113`, `sim.jl:236` | | `test_lifecycle.jl` "the five states, and the gates between them" | high |
| §12.6 (6535) | Built is stores allocated, nothing authored; initialized is `init!` completed boundary zero | accurate | `devices.jl:116` (`Control()` starts `:built`), `sim.jl:619` | | `test_lifecycle.jl:42` | high |
| §12.6 (6540) | An input mode `:live` or `:replay`, read as `mode(sim)`, orthogonal to the state | accurate | `trace.jl:142`, `sim.jl:254` | | `test_trace.jl:552` | high |
| §12.6 (6549) | `init!` is mandatory; `run!`/`step!` on an uninitialized sim errors naming `init!`, distinct from `UninitializedInputs` | accurate | `sim.jl:300` (`MissingInit(op, status)`) | | `test_lifecycle.jl:42` | high |
| §12.6 (6553) | `replay!` is the one alternative entry, running boundary zero from a header | accurate | `sim.jl:718`, `sim.jl:781–782` | | `test_trace.jl:432` | high |
| §12.6 (6557) | The loop runs on the calling task unless a calling-task device is rostered; deviceless `run!` is fully synchronous | accurate | `sim.jl:932–960` | | `test_devices.jl:281` | high |
| §12.6 (6565) | `step!(sim; frames = 1)` advances whole frames through the ordinary sequence and returns; bit-identical to `run!` | accurate | `sim.jl:1114`, sharing `_advance!` with `run!` | | `test_lifecycle.jl` "step! advances whole frames and returns the count actually advanced" | high |
| §12.6 (6568) | `step!(sim; t_plus)` is the duration spelling, mutually exclusive with `frames`, advancing whole frames until the boundary time first covers the duration | accurate | `sim.jl:1117–1133` | `ceil(Int, t_plus/h - 1e-9)`, min 1 — the correct rounding, and the one `t_end` should have used | `test_lifecycle.jl:184` | high |
| §12.6 (6577) | A stepping session is deviceless by construction; `attach!` is legal between calls and the task appears at the next `run!` | accurate | `step!` never spawns; `assert_stopped` admits `:initialized` | | `test_lifecycle.jl:42`, `test_roster.jl:201` | high |
| §12.6 (6584) | The frame-top drain still runs in `step!` and what it drains is the harness cell | accurate | `sim.jl:1035` → `drain!` → `plane.harness_drain()` | it also drains device cells, which is right: a batch staged into a rostered device's cell while stopped applies | `test_roster.jl:223` | high |
| §12.6 (6586) | `stage!(sim, "face" => value, …)` with the calling task as writer; batches traced, applied at the next frame top, surface-checked | accurate | `sim.jl:1292`, `dataplane.jl:545` | | `test_dataplane.jl:38` | high |
| §12.6 (6594) | The read half is `latest(sim)`, the same immutable snapshot a device handle acquires; both entry points work under `run!` too | accurate | `sim.jl:1474`, `devices.jl:236` | | `test_dataplane.jl:99` | high |
| §12.6 (6601) | Between `step!` calls the simulation reports **initialized**; `run!` may follow `step!`, continuing from the current boundary | accurate | `sim.jl:1152` | | `test_lifecycle.jl:184` | high |
| §12.6 (6609) | Termination policy honored throughout; a stop inside `step!` ends the run there through the ordinary tail and leaves it `stopped` | accurate | `sim.jl:1154–1159` | | `test_lifecycle.jl` "a stop face inside step! truncates it through the deviceless tail" | high |
| §12.6 (6613) | `step!` returns the number of frames actually advanced | accurate | `sim.jl:1161` (`adv`) | | `test_lifecycle.jl:184` | high |
| §12.6 (6619) | `stopped → init! → run!`; `init!` clears the trace, the log, the termination record **and** any batches still in staging cells; it returns the mode to `:live` | accurate | `sim.jl:533–548`, `sim.jl:616` | every clause present: `_reset!(sim.log)`, `_reset_accounts!`, both cells nulled, `stop_issuer` and `termination` cleared, `_reset!(sim.trace)` returning `:live` | `test_dataplane.jl` "a staged batch waits for the first frame top; one predating init! clears with it"; `test_trace.jl:592` | high |
| §12.6 (6626) | `live!` is the third door, moving the mode alone | accurate | `sim.jl:820–828` | | `test_trace.jl` "`live!` takes a replayed halt live, and the session records itself" | high |
| §12.6 (6633) | Device attachments persist across re-initialization: binding, claims and id survive; tasks and OS resources do not | accurate | `init!` does not touch `plane.roster`; `sim.jl:974` empties `run_tasks` | | `test_devices.jl:201` | high |
| §12.6 (6641) | Task topology follows the roster each time | accurate | `sim.jl:932` per run | | `test_devices.jl:281` | high |
| §12.6 (6644) | The `gui = true` flag is run-scoped: attaches at run entry iff no GUI is rostered, detached by the tail | pending | greps empty in `src/`: `gui`, `gui =`, `GUI` | `run!` takes only `t_end` and `stop_on` (`sim.jl:873`) | none | high |
| §12.6 (6655) | Run policy is re-bindable per cycle: `t_end` and `stop_on` are `Simulation` defaults that `run!` may override | accurate | `sim.jl:873–880`, validated identically at both sites (`_t_bound`, `_stop_faces`) | note `step!` takes no overrides, which matches the spec | `test_lifecycle.jl` "t_end: constructor default, run! override…", "stop_on overrides bind per run" | high |
| §12.6 (6659) | `errored` is terminal; reproduction is trace replay, not resurrection | accurate | `sim.jl:302–303` (`ServiceLifecycle`), `sim.jl:610` (`init!` refuses `:errored`) | | `test_lifecycle.jl:222` | high |

### §12.7 — Replay (6662–6869)

| anchor | obligation | verdict | where | notes | test | conf |
|---|---|---|---|---|---|---|
| §12.7 (6666) | `replay!(sim, trc)`, with `to_boundary` and `to_time` partial spellings | accurate | `sim.jl:718` | | `test_trace.jl:460, 482` | high |
| §12.7 (6674) | Replay is the ordinary loop with exactly two substitutions | accurate | `sim.jl:786–789` then `_run_body!`, shared verbatim with `run!` | | `test_trace.jl` "a replay reproduces the recorded trajectory bitwise" | high |
| §12.7 (6679) | Substitution 1: boundary zero from the header — resolved stores and root inputs applied directly, no condition resolution, then the ordinary boundary-zero sequence | accurate | `sim.jl:757–782` | | `test_trace.jl:432` | high |
| §12.7 (6688) | Substitution 2: the drain reads the trace, keyed by frame ordinal; recorded batches apply verbatim with no surface re-check | accurate | `sim.jl:1364–1395`, `trace.jl:412–471` | | `test_trace.jl` "a device's recorded batches replay on a deviceless twin" | high |
| §12.7 (6701) | Two input modes; the mode decides which source the one drain branch reads; `replay!` attaches and enters `:replay`; there is still one loop and one drain | accurate | `sim.jl:1329` (`reg.mode === :replay && return _replay_drain!(…)`), `sim.jl:786–788` | | `test_trace.jl:552` | high |
| §12.7 (6714) | In `:replay` every advance's frame budget is capped at the recording's last frame; `to_boundary = k` caps it earlier | accurate | `sim.jl:891` (`_replay_bound`), `sim.jl:790` | | `test_trace.jl` "the recording bounds a replaying advance, and the end flips the mode" | high |
| §12.7 (6718) | `to_boundary = k` runs **through the frame whose execution published boundary `k`**; replay always halts at a frame top | accurate | `sim.jl:1032` (`clock.step < upto`) so the halt is at `clock.step == k` | | `test_trace.jl:460` (asserts `clock.step == 5`) | high |
| §12.7 (6725) | A localized `t*` boundary is reproduced but not stoppable-at | accurate | the budget is frame-indexed only | | `test_trace.jl:460` | high |
| §12.7 (6728) | `t_end` and `stop_on` overrides bind for a replay exactly as at `run!` | accurate | `sim.jl:754–756` | | `test_trace.jl:815` | high |
| §12.7 (6733) | `to_time` halts at the last frame top at or before the time: `k = ⌊(to_time − t₀)/h⌋` against the **header's** `t₀`; mutually exclusive with `to_boundary` | accurate | `sim.jl:723`, `sim.jl:735–748` | uses the header's `t₀` and the header's `h`, with a `1e-9` slack for binary-float on-grid times | `test_trace.jl` "`to_time` addresses the same halt by time" | high |
| §12.7 (6745) | `to_time` validation: real, finite, at least `t₀`, and naming a time the recording covers; the checks run before the replay writes anything | accurate | `sim.jl:745–751`, all before the first store write at `sim.jl:759` | | `test_trace.jl` "`to_time`'s refusals precede every write" | high |
| §12.7 (6751) | The halt flips the mode only at the recording's end; a frame budget that runs out leaves the simulation `initialized` | accurate | `sim.jl:901–910` (`_settle_mode!`), `sim.jl:979–981` | | `test_trace.jl:552` | high |
| §12.7 (6760) | `live!(sim)` sets the mode to `:live` and detaches the remainder, touching nothing else; legal only on an `initialized` sim in `:replay`; already-`:live` refuses | accurate | `sim.jl:820–828` | `_assert_advanceable` covers `:built`, `:running`, both terminal states | `test_trace.jl` "`live!`'s refusals are loud, never a no-op" | high |
| §12.7 (6786) | Replay ends `initialized`, never `stopped` | accurate | `sim.jl:980–981` (`term === nothing` ⇒ `:initialized`) | | `test_trace.jl:404` | high |
| §12.7 (6798) | Replay re-records: the new trace inherits the old header and accumulates the re-drained batches | accurate | `sim.jl:770–775` (`_detach(h)` then `_install_writers!`), `sim.jl:1387–1389` | the inherited header is deep-copied, so the caller's `Trace` is untouched | `test_trace.jl` "a continuation is a live session from the replayed boundary" | high |
| §12.7 (6803) | Pacing and the control plane unchanged | partial | control plane unchanged (`sim.jl:1030`); pacing is absent everywhere | | none | high |
| §12.7 (6809) | Devices are readers: rostered devices init and spawn normally and consume snapshots | accurate | `_run_body!` is shared, so `_init_devices!`/`_spawn!` run for a replay too | | `test_trace.jl:721` | high |
| §12.7 (6810) | No live staging cell is drained under `:replay`: a batch found staged is discarded with a rate-limited `ReplayDiscardedStaging` | accurate | `sim.jl:1397–1404`, `dataplane.jl:128` | rate-limited structurally: one take per cell per frame | `test_trace.jl` "live staging met by a replay is discarded, and reported"; "…into the harness is discarded on its own cell" | high |
| §12.7 (6818) | Validation before the first frame: the header against the `Build` (store layout, root faces), the batch entries against the root-face list, each ordinal against the recording's length | accurate | `trace.jl:327–363`, `trace.jl:412–437`, `sim.jl:642–654` | | `test_trace.jl:209, 265, 289` | high |
| §12.7 (6822) | Each writer's schema validated in the same pass; disagreement is a replay error | accurate | `trace.jl:370–378` | superseded schema entries checked with the live ones | `test_trace.jl` "a recorded schema is validated against the target's own faces" | high |
| §12.7 (6825) | Failures report did-you-mean; the kinds are `ReplayHeaderMismatch`, `ReplaySchemaMismatch`, `ReplayUnknownFace` | accurate | `trace.jl:374`, `trace.jl:395` both carry `faces`; `trace.jl:331–360` | | `test_trace.jl:246, 265` | high |
| §12.7 (6832) | The reverse conversion is paid once, off the loop; the replay drain applies compiled scatters and resolves no name per frame | accurate | `trace.jl:412–471`, `trace.jl:384` (`_apply_thunk`) | | `test_trace.jl` "a valid trace normalizes to compiled scatters, in drain order" | high |
| §12.7 (6839) | Structural mismatch is an error; parametric difference is the what-if register | accurate | `_check_header!` compares the structural fingerprint and the deployment block only | | `test_trace.jl` "a changed parameter replays deterministically: the what-if register" | high |
| §12.7 (6845) | The seven trajectory-determining deployment parameters compared: `Δt_base`, `h`, `n`, algorithm, `localization_tol`, `localization_budget`, `firing_budget`; mismatch is `ReplayHeaderMismatch` with a deployment discriminator | accurate | `trace.jl:352–361` — all seven, `what = :deployment, name = …` | | `test_trace.jl` "the header is compared against the build and the deployment binding" | high |
| §12.7 (6856) | `t₀` is applied, not compared; `replay!` takes no `t0` argument | accurate | `sim.jl:766`, and the signature has no `t0` | | `test_trace.jl:241` | high |
| §12.7 (6858) | The header's `t_end`/`stop_on` pair is neither compared nor applied | accurate | `_check_header!` never reads them; `sim.jl:754` uses the target's own | | `test_trace.jl:241` | high |
| §12.7 (6862) | The disposition table's five rows | accurate | `trace.jl:327–378`, `sim.jl:757–766` | every row implemented as written | `test_trace.jl:209` | high |
| §12.7 (6867) | Rejected shapes: no `run!(sim; replay = trc)` flag, no synthetic playback device, replay does not end `stopped` | accurate | `run!`'s keywords are `t_end`/`stop_on` only; no playback device; `:initialized` on budget exhaustion | | `test_trace.jl:404` | high |

## 3. Two lists

### Observed outside my slice

- §10.7's pacer is absent in full: no `margin`, no debt absorption, no
  sleep-then-spin wait, no `DebtReanchor`. Agent C's territory, but it is what
  makes §11.2's "pacer diagnostics" and §12.2's wait-slot argument unimplementable.
- `sim.jl:883`, `sim.jl:1131` and `sim.jl:790` all convert `t_end` to a frame index with
  `round`; §10.4's grid rule (`tₖ = t₀ + k·h`) is what the correct `ceil` would
  have to respect. Flagged in my table under §12.4 because §12.4 states the rule.
- `check_binding` (`roster.jl:79–88`) names the user's binding type with
  `string(T)` while the `claims`/`reads` fallbacks (`roster.jl:51, 62`) use
  `_typename(b)`. The same diagnostic kind therefore renders a user type two
  ways depending on which arm fired. Agent F.
- `ReadBindingUnresolved` carries `candidates` for `GetInput` only
  (`bindings.jl:171–177`); the `GetOutput` and `GetFace` arms construct it
  without one. Agent F for the payload, me for §11.2's did-you-mean obligation.
- `AttachUnknownFace`, `ClaimConflict`, `AlreadyAttached`, `CallerTaskConflict`,
  `NotAttached`, `EmptyGreedyClaim`, `DeviceContractMismatch`,
  `BindingContractMismatch`, `ServiceLifecycle`, `MissingInit`,
  `StopFaceInvalid`, `ArgumentInvalid`, `DeploymentInvalid` are all constructed
  from sites in my slice; their payloads and rendering are Agent F's.
- `port(sim, path, name)` and `state(sim, path)` (`sim.jl:1530, 1536`) read the
  live store with no `assert_stopped`, unlike `logged(sim)` (`sim.jl:1489`)
  which has one. Under the calling-task-device topology the loop is on a
  different task, so these race the sweep.
- `_wrap_step`/`StepError`/the execution cursor (`sim.jl:1065`) belong to §13.4;
  I read them only to confirm the tail's error path.
- `assert_total(plan, …, :init!)` at `sim.jl:611` is §14.6's totality gate; I
  confirmed only its placement (pre-write) as §11.3 requires.

### Spec problems

1. **§11.4's bounded-retry claim is false for the harness cell.** "The CAS can
   fail only because a drain intercepted the old batch, so the retry is
   bounded" (5180) assumes one writer per cell. §11.3 (5075) explicitly makes
   the harness register's cell writable from *whichever task stages*, so two
   REPL/test tasks staging concurrently can lose the CAS to each other
   indefinitely. `dataplane.jl:19–22` states the honest version. The spec should
   either say the harness cell is single-writer by convention or drop the
   "only".
2. **§11.3's stopped-sim state list omits `errored`.** It names `built`,
   `initialized` and `stopped` as legal for `attach!`/`detach!` and `running` as
   the error. §12.6 makes `errored` a fifth, terminal state, and the spec never
   says which side of the gate it falls on. The code admits it
   (`devices.jl:131`) for post-mortem reconfiguration, which reads right; the
   spec should say so.
3. **§11.8 assigns `maxlog = 25` to "a status renderer" with no addressee.** The
   threshold is called presentation policy belonging "to whoever renders", and
   no framework surface is obliged to render. It is therefore unimplementable as
   a framework obligation and untestable as a conformance item. Either the
   framework ships a `show(::FrameworkStatus)` carrying the rule, or the rule
   belongs in §16's migration material.
4. **§12.4(5) is ambiguous between a per-device cap and a whole-tail deadline.**
   "Join under the `join_timeout` cap. A device task exceeding it is reported by
   name" reads per-device; D-198's "one value for the whole tail: the join loop
   has one patience" reads shared-deadline, which is what the code does. With n
   devices the two differ observably. One sentence would settle it.
5. **§12.4 never says whether `t_end` is an absolute clock time or a duration.**
   "The first grid boundary whose *time* reaches or exceeds `t_end`" reads
   absolute, but `t₀` is a service argument to `init!` (§14.5) that can be
   non-zero, and nothing in §12.4, §13.5 or Appendix B ties the two together.
   The code reads it as a duration from step 0.
6. **§11.2's endpoint rule is silent on `log = false`.** "The endpoints are
   retained unconditionally… survive any `log_every` and any `log_max`" says
   nothing about the switch. The code retains nothing at all when the switch is
   off, which is the sane reading, but "unconditionally" invites the other.
7. **§12.3 leaves the counter/snapshot-ordinal convention unfixed.** The counter
   is "published with the snapshot" and the predicate is `counter > last_seen`.
   The code stamps the snapshot with the pre-increment value, so
   `snap.boundary == k` while the predicate's counter reads `k+1`. Both are
   consistent internally, but a consumer correlating a snapshot's `boundary`
   with a wake has no stated convention to rely on.
8. **§11.3's "stable device id" and §11.5's writer tag are two different
   things.** §11.3 says the trace "tags entries with a stable device id, never a
   roster index". §11.5 says the header carries "each writer's face-name →
   position schema" without saying how a writer is named. The code names it with
   the §11.8 display string `"device 3 (T16000M)"`, which couples the trace's
   primary record to a rendering choice and to the device's type name. A bare
   integer id plus a separate display name would be more robust; the spec should
   say which.
9. **§11.8 puts the heartbeat acquire-load "at the drain" (5946) while §12.2 and
   D-193 put `task_state` at publication.** The two facts sit in one
   `WriterStatus` and must be read at the same instant to be coherent; the code
   reads both at publication. §11.8's sentence should follow.
