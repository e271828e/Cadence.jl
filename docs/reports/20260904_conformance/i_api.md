# Agent I — Appendix A (taught contracts) and Appendix B (API synopsis)

## 1. Header

- **Agent**: I
- **Slice**: Appendix A, the author-facing index of taught contracts; Appendix
  B, the API synopsis of entry points.
- **Spec lines**: 9679–10129 of `docs/design/spec.md`, read whole.
- **Tip**: `70672d1`, Julia 1.12.7.
- **Probes run**: yes, three, all foreground `julia --project=.` from the
  repository root. (1) A name-existence sweep over every symbol Appendix B
  names, plus `names(Cadence)`. (2) A `Base.kwarg_decl` sweep over the
  keyword signatures of `Simulation`, `run!`, `step!`, `attach!`, `build`,
  `trim!`, `replay!` and `fragment`, plus `Cadence._t_bound_diag(Inf)` and
  `fieldnames(TrimProblem)`. (3) A one-model run asserting the `t_end`
  rounding rule. Scripts are in the session scratchpad.
- **Forbidden files opened**: none. I read `docs/design/implementation.md`'s
  "What is real here" table only, `docs/design/decisions.md` only at `D-017`,
  and the body sections Appendix A and B cite (§4.4, §5.3, §9.2, §13.3,
  §14.2) for meaning.

## 2. Summary

The two appendices describe a package whose names almost all exist and whose
signatures almost all match. The declaration surface, the build primitives,
the passthrough helpers, the roster and binding surface, the device contract
and handle, the condition algebra, the trim service and the replay family are
built as written, often more precisely than the prose. Most of Appendix B's
sixty-odd entry points are accurate at the level of name, arity and keyword
default.

Four things stand out.

**Nothing is exported.** `src/Cadence.jl` carries no `export` statement, and
`names(Cadence)` returns `[:Cadence]` alone. Appendix B calls its contents
"the user-facing surface"; §4.4 and §9.4 say "exported function" and
"exported canonical probe scalar". The test suite reaches the whole surface
through one 200-name `import Cadence: …` block in `test/CadenceTests.jl`. A
user writing `using Cadence` gets nothing. This is the single largest gap
between the appendix's framing and the package, and it is one line of work.

**The pacing and GUI half of `run!` does not exist.** `run!(sim; …)` takes
`t_end` and `stop_on` and nothing else. `gui`, `pace` and `margin` are absent
from `src/` entirely, and with them the run-scoped GUI attachment, the
"paced and unpaced runs are bit-identical" law, the standard greedy GUI
binding, §11.7's derived liveness, and the pause/un-pause and pace-change
half of the control plane. The stop half of the control plane is built and
solid.

**`t_end` behaves differently from the appendix in two ways.** The
constructor default is `nothing`, not `Inf`, and `Inf` is actively *refused*
(`DeploymentInvalid(:t_end, :range, Inf)`, confirmed by probe): a run without
a clock bound from some site is an `ArgumentInvalid(:run!, :no_clock_bound)`
error rather than an open-ended session. And the run's end frame is
`round(Int, t_end/h)`, not the ceiling: my probe showed `t_end = 0.05` at
`h = 0.02` ending at `t = 0.04`, one frame *before* the bound the appendix
says the run reaches or exceeds.

**Three named entry points have no code**: `ProbeDual`, `linearize` and a
framework-owned `condition` generic. `at`'s lifting of whole `TrimProblem`s
and tap sets is absent too, and the `Build`'s "plain printable data" is
present as struct fields but has no `show` method and no public accessor.

Smaller but real: the stepper keyword is spelled `method = RK4` (a type), not
`algorithm = RK4()` (an instance); `resolve` enforces the one-level rule but
not the generic-holding rule; `phase_bodies` returns the four blocks without
the per-event guards/handlers and per-component `state_projection` the
appendix promises; and auto-published ports do not exist, so the `y`
footnote's `output_types ∪ auto-published` union collapses to its first term
(an unproduced declared port is `DeclaredNotProduced`, a build error).

Appendix A fares better than Appendix B. Sixteen of its eighteen taught
contracts have the code they point at, several of them exactly (the prior
register and its boundary-zero reset, the per-component one-event-per-round
latch, the `shutdown!`-on-every-path bracket, the trait/method conformance
cross-check). Only derived liveness is absent, and only stage totality is
short.

## 3. Findings table

### Appendix A — taught contracts

| § (line) | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| A (9681) | framing: index not a second home | n/a | — | — | rationale |
| A (9693) | stage funnel: stage name ⊇ bundle ⊇ destructured reads | accurate | `src/declare.jl:278-299` | `test_declare.jl:35` | |
| A (9701) | one home per datum: table holds produced signals only, no mirror stores | accurate | `src/build.jl:267-304` | `test_store.jl` | cells for declared ports + root inputs; faces are address aliases |
| A (9704) | the value-level constructor | n/a | — | — | a shipped component's obligation, no framework code (§4.4) |
| A (9710) | boundary sampling: a due tick's gated stages run inside the boundary sweep | accurate | `src/executor.jl:330-360`, `src/sim.jl:350` | `test_discrete.jl:11` | |
| A (9715) | interval alignment: `state_update` outgoing, runs at boundary zero | accurate | `src/sim.jl:608-700` | `test_discrete.jl:290` | |
| A (9720) | same-tick reset consumption on the discrete tier | accurate | `src/declare.jl:287-289` | `test_discrete.jl:11` | mechanism = `u` in the discrete `output_direct` bundle |
| A (9728) | continuous reset is an event; §10.6 re-sweeps to quiescence | accurate | `src/sim.jl:414-475` | `test_events.jl:138` | |
| A (9741) | guards, edges, priors; boundary zero sets every prior not-holding | accurate | `src/executor.jl:251`, `src/sim.jl:540` | `test_events.jl:114`, `test_conditions.jl:316` | |
| A (9750) | handler-phase visibility; one event per component per round | accurate | `src/executor.jl:239`, `src/sim.jl:443-458` | `test_events.jl:153` | `comp_fired` |
| A (9756) | stage totality: probe evaluates every user function; throw is a build failure | short | `src/build.jl:465-575`, `src/build.jl:615` | `test_build.jl:28` | see 4.1 |
| A (9762) | stop-face sampling in completed-boundary snapshots | accurate | `src/sim.jl:185-215`, `src/localization.jl` | `test_lifecycle.jl:141`, `:162` | |
| A (9767) | levels, never deltas; idempotent under coalescing | accurate | `src/dataplane.jl` (CAS merge), `src/bindings.jl:91` | `test_dataplane.jl:56` | |
| A (9772) | device loop idioms; `DeviceJoinTimeout` by name; stale heartbeat | accurate | `src/devices.jl:205,294,425-450` | `test_devices.jl:241`, `:266` | |
| A (9779) | `shutdown!` on every exit path, failed `init!` included | accurate | `src/devices.jl:373-388` | `test_devices.jl:201` | |
| A (9785) | traits called once at attach and cross-checked; `map_*` never framework-called | accurate | `src/roster.jl:74-90`, `src/bindings.jl:199` | `test_roster.jl:30`, `test_bindings.jl:146` | |
| A (9792) | bad datum vs bug: `report!(handle, MalformedDatum(cause))`, rest is `DeviceCrash` | accurate | `src/devices.jl:291,352` | `test_diagnostics.jl:59` | |
| A (9797) | derived liveness: widget live iff its feed chain ends in a root input in the GUI's claim | absent | — | — | see 4.2 |
| A (9801) | two observation registers; store selectors read live stores only | accurate | `src/readers.jl:22-52`, `src/bindings.jl:157`, `src/dataplane.jl:573` | `test_readers.jl:114` | |

### Appendix B — the entry points

| § (line) | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| B (9811) | "the user-facing surface": these names are exported | absent | `src/Cadence.jl:1-24` | — | see 4.3 |
| B (9820) | continuous leaf: `init_x`/`init_m`, `init_workspace(::C,::Type{T})`, `input_types`/`output_types` by type | accurate | `src/declare.jl:22,37,46,55,68` | `test_declare.jl:35` | |
| B (9823) | stages `output_state`/`output_direct`/`state_derivative` | accurate | `src/declare.jl:224-226` | `test_continuous.jl:4` | |
| B (9824) | `StateEvent(guard, handler)`; policy from the guard's return type | accurate | `src/declare.jl:182`, `src/build.jl:615-640` | `test_events.jl:108` | |
| B (9826) | `state_projection` | accurate | `src/declare.jl:202` | `test_events.jl:247` | |
| B (9827) | discrete leaf: `init_s`, `init_workspace(::C)`, stages incl. `state_update` | accurate | `src/declare.jl:30,46,227` | `test_discrete.jl:11` | |
| B (9830) | assembly: `child_connections` mandatory (class marker) | accurate | `src/declare.jl:82`, `src/assembly.jl:29-60` | `test_assembly.jl:29` | no fallback method |
| B (9831) | `input_connections`, `output_connections`, `sample_times` | accurate | `src/declare.jl:89,95,171` | `test_assembly.jl:399` | |
| B (9832) | `transparent_container` optional, default `nothing` | accurate | `src/declare.jl:108` | `test_assembly.jl:195` | |
| B (9833) | shipped conditions: `condition(::C; kw)` fragment functions | absent | — | `test_conditions.jl:329` (fixture-local) | see 4.4 |
| B (9838) | bundle `output_state` continuous = `x, m, t [, ws]` | accurate | `src/declare.jl:278-299` | `test_declare.jl:35` | code orders `ws` before `t`; destructuring is by name |
| B (9839) | bundle `output_direct` continuous = `x, m, u, y_x, t [, ws]` | accurate | `src/declare.jl:287-292` | `test_declare.jl:35` | |
| B (9840) | bundle `state_derivative` = `x, m, y, u, t [, ws]` | accurate | `src/declare.jl:287-294` | `test_declare.jl:35` | |
| B (9841) | bundle `output_state` discrete = `s, t, Δt [, ws]` | accurate | `src/declare.jl:284,296-297` | `test_declare.jl:35` | |
| B (9842) | bundle `output_direct` discrete = `s, u, y_s, t, Δt [, ws]` | accurate | `src/declare.jl:287-292` | `test_declare.jl:35` | |
| B (9843) | bundle `state_update` = `s, y, u, t, Δt [, ws]` | accurate | `src/declare.jl:287-294` | `test_declare.jl:35` | |
| B (9844) | bundle guard/handler = `x, m, y, u, t [, ws]` | accurate | `src/declare.jl:310-319` | `test_events.jl` | |
| B (9845) | `state_projection` positional `(comp, x)`, no bundle | accurate | `src/executor.jl:222`, `src/build.jl:571` | `test_events.jl:247` | |
| B (9850) | `u` iff family may see inputs **and** `input_types` declared | accurate | `src/declare.jl:287-289` | `test_declare.jl:35` | |
| B (9851) | `y` iff the component produces any table cell (`output_types` ∪ auto-published) | short | `src/declare.jl:293` | `test_declare.jl:35` | see 4.5 |
| B (9853) | `x`/`s`/`m`/`ws` iff declared | accurate | `src/declare.jl:281-295` | `test_declare.jl:35` | |
| B (9854) | `y_x`/`y_s` iff the stage-1 return is non-empty, auto-published excluded | accurate | `src/declare.jl:290-292`, `src/build.jl:507` | `test_declare.jl:35` | exclusion vacuous, see 4.5 |
| B (9856) | `Δt` on the discrete tier only | accurate | `src/declare.jl:297` | `test_declare.jl:35` | |
| B (9856) | a stage returns a NamedTuple of port values | accurate | `src/build.jl:510-518`, `_check_ports` | `test_build.jl:28` | |
| B (9857) | `state_derivative` returns the layout image of `X` | accurate | `src/build.jl:1041-1055` | `test_build.jl:28` | |
| B (9858) | handler returns `(; x, m)`, key iff store exists and is updated; `x` complete, `m` partial | accurate | `src/build.jl:649-675`, `src/executor.jl:310-315` | `test_events.jl:72` | |
| B (9862) | `build(world) → Build`, standalone | accurate | `src/build.jl:381` | `test_build.jl:44` | |
| B (9862) | the `Build` is the inspectable artifact: wire list, face table with provenance, schedule, root inputs | short | `src/build.jl:364-370`, `src/assembly.jl:504-514` | `test_discrete.jl:162` | see 4.6 |
| B (9864) | `build(world; activations = (Float64, ProbeDual))` | short | `src/build.jl:381` | `test_build.jl:241` | keyword present; `ProbeDual` is not a name |
| B (9865) | `ProbeDual`, the exported canonical concrete probe scalar | absent | — | — | see 4.7 |
| B (9866) | pre-materializes activations so a parallel sweep shares an immutable `Build` | accurate | `src/build.jl:387-390,429` | `test_build.jl:241` | the cache Dict stays mutable, but is filled |
| B (9868) | `resolve(asm, path) → AbstractComponent`, the one-level rule for wiring | accurate | `src/assembly.jl:308-316` | `test_assembly.jl:647`, `:663` | |
| B (9869) | `resolve` enforces the generic-holding rule for deep reads | absent | — | — | see 4.8 |
| B (9871) | `input_faces(c)`/`output_faces(c) → Vector{String}`, declaration order | accurate | `src/assembly.jl:342,352` | `test_assembly.jl:654-658` | |
| B (9873) | `input_passthrough`/`output_passthrough(asm, path; prefix, sep, except, only)` | accurate | `src/assembly.jl:382,404` | `test_assembly.jl:672`, `:694` | |
| B (9880) | keyword `algorithm = RK4()` | stand-in | `src/sim.jl:130` | `test_stepper.jl` | see 4.9 |
| B (9880) | `h` required, no framework default | accurate | `src/build.jl:719-723` | `test_discrete.jl:228` | |
| B (9880) | `n = 1`; given `Δt_base`, `n` derived and validated integer ≥ 1 | accurate | `src/build.jl:724,744-753` | `test_discrete.jl:228` | |
| B (9880) | `Δt_base = nothing`; `Rational`/`Period`/`Hz` or `:derive`; three sources | accurate | `src/build.jl:698-745` | `test_discrete.jl:228`, `:270` | |
| B (9881) | `t_end = Inf` default | stand-in | `src/sim.jl:131,186` | `test_lifecycle.jl:94` | see 4.10 |
| B (9882) | `stop_on = ()` | accurate | `src/sim.jl:133,185-215` | `test_lifecycle.jl:126` | |
| B (9882) | `localization_tol = 1e-6` | accurate | `src/sim.jl:132,143` | `test_localization.jl` | |
| B (9882) | `localization_budget = 8` | accurate | `src/sim.jl:132,145` | `test_localization.jl` | |
| B (9883) | `firing_budget = 4`, integer ≥ 1 | accurate | `src/sim.jl:131,139` | `test_events.jl:205` | |
| B (9883) | `join_timeout = 5.0` | accurate | `src/sim.jl:133,147` | `test_devices.jl:318` | |
| B (9884) | `trace = true` | accurate | `src/sim.jl:134,149` | `test_trace.jl:99` | |
| B (9884) | `log = true` | accurate | `src/sim.jl:134,151` | `test_log.jl:90` | |
| B (9884) | `log_every = 1` | accurate | `src/sim.jl:134,153` | `test_log.jl:43` | |
| B (9884) | `log_max = 65536`, `Inf` the opt-out | accurate | `src/sim.jl:135,155` | `test_log.jl:53` | |
| B (9886) | `Simulation(world;…) = Simulation(build(world);…)`; the `Build` overload takes the same keywords | accurate | `src/sim.jl:130,178-179` | `test_discrete.jl:228` | |
| B (9903) | derivation printed with its drivers | absent | — | — | see 4.6 |
| B (9912) | `t_end = Inf` the honest interactive default, bounded by `log_max` | stand-in | `src/sim.jl:186` | `test_lifecycle.jl:94` | see 4.10 |
| B (9914) | a run with no finite `t_end`, no `stop_on` and `pace = Inf` warns at start | absent | — | — | no pacing, and no clock bound is refused outright |
| B (9916) | a run ends at the first grid boundary reaching or exceeding `t_end`, whole frames | stand-in | `src/sim.jl:888` | `test_lifecycle.jl:94` | see 4.11 |
| B (9917) | `stop_on` recorded in run metadata, the trace header's deployment block | accurate | `src/trace.jl:43-46` | `test_trace.jl:75`, `:209` | |
| B (9922) | exhausting `firing_budget` loses further edges under a `FiringBudget` warning | accurate | `src/sim.jl:440-455` | `test_events.jl:205` | |
| B (9924) | the three trajectory keywords validated (`DeploymentInvalid`) and recorded, replay compares | accurate | `src/sim.jl:139-146`, `src/trace.jl:43-46` | `test_trace.jl:209` | |
| B (9928) | `join_timeout` outside the deployment block; replay neither records nor compares | accurate | `src/trace.jl:43-46` | `test_devices.jl:318` | |
| B (9932) | `log_every` admissible on the artifact only, never the trace | accurate | `src/trace.jl` (no stride keyword) | `test_trace.jl:99` | vacuously: the trace has only an on/off switch |
| B (9934) | log fills → stride doubles; endpoints retained unconditionally, outside the bound | accurate | `src/dataplane.jl:637-690` | `test_log.jl:53`, `:62` | |
| B (9938) | all four recording keywords are view policies; none enters the deployment block | accurate | `src/trace.jl:43-46` | `test_log.jl:98` | |
| B (9940) | `attach!(sim, dev::AbstractDevice, binding::AbstractBinding; should_abort = false)` | accurate | `src/sim.jl:1213` | `test_roster.jl:52` | |
| B (9945) | the roots are mandatory: the signature is the gate | accurate | `src/sim.jl:1213`, `src/roster.jl:26-27` | `test_roster.jl:30` | |
| B (9948) | `should_abort` per-attachment: set requests a stop; clear holds the claims to run end | accurate | `src/sim.jl:1245`, `src/devices.jl:352-356` | `test_devices.jl:173`, `:190` | |
| B (9950) | a departure is the loop returning, a crash, or a failed `init!` | accurate | `src/devices.jl:339-388` | `test_devices.jl:201` | |
| B (9956) | `is_input(b)` default `false` on `AbstractBinding` | accurate | `src/roster.jl:36` | `test_roster.jl:30` | |
| B (9957) | `is_output(b)` default `false` | accurate | `src/roster.jl:37` | `test_roster.jl:30` | |
| B (9958) | `is_greedy(b)` default `false`, switches the claim's source | accurate | `src/roster.jl:38,201` | `test_roster.jl:111` | |
| B (9959) | `claims(b)` / `map_input(datum, b)`: the enumerated face set is the claim | accurate | `src/roster.jl:50,203`, `src/bindings.jl:91` | `test_bindings.jl:91`, `:134` | |
| B (9961) | `reads(b)` / `map_output(nt, b)`: the output side | accurate | `src/roster.jl:61`, `src/bindings.jl:199` | `test_bindings.jl:177`, `:220` | |
| B (9964) | conformance at attach pairs each trait against its method; both `BindingContractMismatch` | accurate | `src/roster.jl:74-90` | `test_roster.jl:30` | error fallbacks and `which`-against-the-fallback both present |
| B (9969) | a claim registered with exclusivity; staged shape and shim compiled | accurate | `src/sim.jl:1231-1244` | `test_roster.jl:52`, `test_dataplane.jl:91` | |
| B (9971) | `reads` selectors validated and compiled to one gather | accurate | `src/sim.jl:1240`, `src/bindings.jl:135-190` | `test_bindings.jl:197` | |
| B (9972) | greedy: complement computed at attach; empty remainder legal, `EmptyGreedyClaim`; greedy without input an error | accurate | `src/roster.jl:80,201`, `src/sim.jl:1250` | `test_roster.jl:111`, `:142` | |
| B (9977) | `TableBinding` is the shipped data-driven binding | accurate | `src/bindings.jl:21-95` | `test_bindings.jl:68` | |
| B (9977) | the standard GUI binding is the shipped greedy one | absent | — | — | see 4.2 |
| B (9979) | `attach!` legal in `built`/`initialized`/`stopped`, `ServiceLifecycle` while `running` | accurate | `src/devices.jl:131-133`, `src/sim.jl:1216` | `test_roster.jl:201` | also admits `errored`, which the appendix does not name |
| B (9980) | admission: `AlreadyAttached`, `CallerTaskConflict`, `ClaimConflict`, in that order | accurate | `src/sim.jl:1219-1238` | `test_roster.jl:52` | |
| B (9983) | `attach!` registers only; the task appears at the next `run!` | accurate | `src/sim.jl:1252-1258`, `src/devices.jl:391` | `test_roster.jl:190` | |
| B (9981) | `detach!(sim, device)` removes the entry and releases claims; stopped-sim only | accurate | `src/sim.jl:1263` | `test_roster.jl:201` | |
| B (9983) | a mid-run exit does not detach; claims persist to run end | accurate | `src/devices.jl:339-357` | `test_devices.jl:173` | |
| B (9985) | device contract: `<: AbstractDevice` + `init!`/`loop`/`shutdown!`/optional `unblock!` | accurate | `src/roster.jl:26`, `src/devices.jl:183-187` | `test_devices.jl:297` | |
| B (9987) | optional trait `needs_calling_task(dev) = false`, at most one per roster, loop body inline | accurate | `src/roster.jl:39`, `src/sim.jl:934,1223` | `test_devices.jl:281` | |
| B (9990) | per-run `init!` on the calling task, bracketed; throw → `shutdown!` + `DeviceCrash` by name, dead from boundary zero | accurate | `src/devices.jl:373-388` | `test_devices.jl:201` | |
| B (9993) | author task body inside the framework's try/catch/finally wrapper; voluntary exit = return | accurate | `src/devices.jl:339-357` | `test_devices.jl:110` | |
| B (9995) | one handle type: `running`, `latest`, `wait_next_snapshot`, `stage!`, `binding`, `gather`, `report!` | accurate | `src/devices.jl:205,236,306,248,228,267,291` | `test_devices.jl:110`, `:130` | all seven present |
| B (10001) | `fragment(; x, s, m, inputs)` | accurate | `src/conditions.jl:60` | `test_conditions.jl:35` | |
| B (10003) | `at(prefix, node)`: scoping, stores never applies | accurate | `src/conditions.jl:75` | `test_conditions.jl:35`, `:198` | |
| B (10003) | `at` also lifts whole `TrimProblem`s and linearization tap sets | absent | — | — | see 4.12 |
| B (10005) | `combine(nodes...)`: symmetric; duplicate leaves error with dual provenance; NamedTuple blend a directive error | accurate | `src/conditions.jl:87,93-95` | `test_conditions.jl:54`, `:113` | |
| B (10008) | `override(base, patches...)`: ordered, patch wins, provenance keeps both | accurate | `src/conditions.jl:110` | `test_conditions.jl:66` | |
| B (10010) | `condition(comp; kw)` the shipped fragment-function idiom | absent | — | `test_conditions.jl:329` | see 4.4 |
| B (10016) | `init!(sim, condition; t0 = 0.0)`; totality pre-write then boundary zero | accurate | `src/sim.jl:608` | `test_conditions.jl:225`, `:286` | |
| B (10020) | `trim!(sim, problem; baseline, t0 = 0.0, backend) → TrimReport` | accurate | `src/trim.jl:383` | `test_trim.jl:92` | |
| B (10022) | nonlinear least squares with exact Dual Jacobians against the problem's `tolerances` | accurate | `src/trim.jl:179-260,440-460` | `test_trim.jl:117` | |
| B (10023) | `residuals(reads, d) → NamedTuple`, packed in `tolerances`' order; decisions in `guess`'s | accurate | `src/trim.jl:408,445` | `test_trim.jl:132` | |
| B (10025) | the problem closes at seven fields | accurate | `src/trim.jl:48-59` | `test_trim.jl:229` | probe: `fieldnames` = guess, lower, upper, condition, reads, residuals, tolerances |
| B (10026) | setup and commit both carry the root-input-totality check | accurate | `src/trim.jl:383-420,560-575` | `test_trim.jl:352` | |
| B (10028) | commit = `init!` with `override(baseline, solution)`; recordings cleared | accurate | `src/trim.jl:555-575` | `test_trim.jl:444` | |
| B (10030) | resume-at-time = `capture`'s returned `t` as `t0` | accurate | `src/trim.jl:383`, `src/conditions.jl:813` | `test_trim.jl:457` | |
| B (10031) | `converged` = the service's per-residual box test at the backend's point, the commit's gate | accurate | `src/trim.jl:170,560-572` | `test_trim.jl:152`, `:305` | |
| B (10033) | backend status and counts recorded diagnostically, verbatim | accurate | `src/trim.jl:87-90` | `test_trim.jl:204` | |
| B (10034) | seam: `solve(backend, eval!, d0, lower, upper, tol) → (; d, status, nevals, niters)`, in-place `eval!(r, J, d)` filling `J` iff not `nothing` | accurate | `src/trim.jl:134,179` | `test_trim.jl:305` | |
| B (10037) | non-convergence reports, never throws | accurate | `src/trim.jl:71-90,560` | `test_trim.jl:152` | |
| B (10038) | `capture(sim) → (condition, t)`, full-store gather including root inputs | accurate | `src/conditions.jl:813-836` | `test_readers.jl:154`, `:183` | |
| B (10040) | `linearize(sim, taps) → labeled (ẋ₀, x₀, u₀, y₀, A, B, C, D)` | absent | — | — | see 4.13 |
| B (10047) | `run!(sim; gui, pace, margin, t_end, stop_on)` | short | `src/sim.jl:875` | `test_lifecycle.jl:94` | probe: keywords are `[:t_end, :stop_on]` |
| B (10048) | `run!` blocks until the run ends; deviceless fully synchronous; `init!` required first | accurate | `src/sim.jl:875-890,297-303` | `test_lifecycle.jl:42`, `:67` | |
| B (10050) | paced and unpaced runs are bit-identical | absent | — | — | no pacing exists to compare against |
| B (10054) | `gui = false`: run-scoped GUI attachment iff none rostered | absent | — | — | see 4.2 |
| B (10055) | `pace = 1`, the run's pacing rate | absent | — | — | see 4.2 |
| B (10056) | `margin = 0.002`, the single pacing knob | absent | — | — | see 4.2 |
| B (10057) | `t_end` overrides the constructor default for this run only | accurate | `src/sim.jl:877` | `test_lifecycle.jl:94` | |
| B (10058) | `stop_on` override, validated against the `Build` exactly as at construction | accurate | `src/sim.jl:879-880,185` | `test_lifecycle.jl:126`, `:174` | one `_stop_faces` for both sites |
| B (10060) | the GUI is an ordinary rostered device on the calling task; the tail detaches it | absent | — | — | see 4.2 |
| B (10068) | a rostered calling-task device moves the loop to a spawned task | accurate | `src/sim.jl:934-960` | `test_devices.jl:281` | built generically; the GUI instance of it is not |
| B (10072) | `margin` defaults to 2 ms | absent | — | — | see 4.2 |
| B (10074) | the constructor's `t_end`/`stop_on` pair recorded in run metadata | accurate | `src/trace.jl:43-46` | `test_trace.jl:75` | |
| B (10074) | the override is reported by the termination record when it fires | short | `src/devices.jl:72-76` | `test_lifecycle.jl:94` | see 4.14 |
| B (10075) | `step!(sim; frames = 1) → frames_advanced`; `t_plus` the exclusive duration spelling | accurate | `src/sim.jl:1116-1128` | `test_lifecycle.jl:184` | |
| B (10079) | returns the frames actually advanced, fewer when a source ended the run | accurate | `src/sim.jl:1160` | `test_lifecycle.jl:212` | |
| B (10081) | between calls `initialized`; `run!` may follow; a stepping session is deviceless | accurate | `src/sim.jl:1150-1158` | `test_lifecycle.jl:184` | |
| B (10084) | `stage!(sim, "face" => value, …)`: task-free, traced, drained last, surface-checked as the GUI's writes | accurate | `src/sim.jl:1294-1300`, `src/dataplane.jl:363` | `test_dataplane.jl:68`, `test_roster.jl:142` | "as the GUI's" is vacuous; no GUI |
| B (10090) | `latest(sim) → snapshot`, the same immutable value device handles read | accurate | `src/sim.jl:1476`, `src/devices.jl:236` | `test_dataplane.jl:129` | |
| B (10093) | `phase_bodies(sim)` returns the four blocks in both arities | accurate | `src/sim.jl:316`, `src/build.jl:1006`, `src/executor.jl:420-421` | `test_executor.jl:8` | |
| B (10095) | plus per-event guards/handlers and per-component `state_projection`, keyed by the roster | short | `src/sim.jl:316` | `test_executor.jl:11` | see 4.15 |
| B (10098) | `@ballocated(body()) == 0` per body after warm-up | accurate | `src/executor.jl:440-448` | `test_executor.jl:17`, `:34` | |
| B (10100) | isolated invocation leaves buffers valid but off-trajectory; re-run `init!` | accurate | `src/sim.jl:608` | `test_conditions.jl:269` | documented property, `init!` re-establishes |
| B (10102) | control plane: pause/un-pause and pace/`margin` changes | absent | — | — | see 4.2 |
| B (10102) | stop on a separate atomic surface, never staged | accurate | `src/devices.jl:108-122`, `src/sim.jl:1174` | `test_devices.jl:155` | |
| B (10105) | termination: `stop_on` faces read at every published boundary | accurate | `src/sim.jl:185-215`, `src/localization.jl` | `test_lifecycle.jl:141` | |
| B (10106) | shutdown completes a boundary, publishes the final snapshot, then joins | accurate | `src/devices.jl:400-460` | `test_devices.jl:241` | |
| B (10108) | post-run: the log is retained snapshots | accurate | `src/sim.jl:1491` | `test_log.jl:29` | spelled `logged(sim)`; the appendix names no accessor |
| B (10108) | `trace(sim) → trc` retrieves the always-on input trace | accurate | `src/sim.jl:1518` | `test_trace.jl:99` | |
| B (10110) | `replay!(sim2, trc; to_boundary = k)` re-drives a fresh `Simulation` bit-identically, ending `initialized` | accurate | `src/sim.jl:720` | `test_trace.jl:399`, `:460` | |
| B (10113) | `to_time = t` the exclusive time spelling, floored to the last frame top | accurate | `src/sim.jl:727,736-757` | `test_trace.jl:482`, `:516` | |
| B (10118) | `mode(sim) → :live \| :replay` | accurate | `src/sim.jl:254` | `test_trace.jl:552` | |
| B (10121) | `live!(sim)` detaches the remainder, touches neither trajectory nor trace; stopped-sim, `:replay` only, already-live refuses | accurate | `src/sim.jl:822-831` | `test_trace.jl:629`, `:666` | |

## 4. Deviations in detail

### 4.1 Stage totality: a user throw during the probe is not a diagnostic

Appendix A (9756): "the probe evaluates every user function against values
chosen for their types alone, and a value-level throw is a build failure
there and a `StepError` at runtime."

The probe does evaluate every user function: `probe_stage1`/`probe_stage2`
(`src/build.jl:465-575`), `probe_events` (`src/build.jl:615`), the update
laws (`src/build.jl:544-552`) and `state_projection` (`src/build.jl:557-573`).
The runtime half is exact: one catch site wraps a throw into a `StepError`
with the execution cursor (`src/sim.jl:1063-1074`).

What is short is the build half. There is no `try`/`catch` around any of the
probe's calls into user code, so a value-level throw during `build` escapes
raw — a `DomainError` or a `MethodError`, not a `BuildError` with a path.
The build does fail, so the letter of "a build failure there" holds, but the
diagnostic discipline the rest of the pipeline observes (a path, a stage
name, the collecting barrier) does not reach it, and the author gets a
stack trace instead of the component's path.

### 4.2 The pacing, GUI and pause surface is absent wholesale

Appendix B (10047): "`run!(sim; gui = false, pace = 1, margin = 0.002, …)`",
(10050) "Paced and unpaced runs are bit-identical", (10054) the `gui`
run-scoped attachment, (10072) "`margin` defaults to 2 ms", (10102)
"Control plane — pause/un-pause, pace and `margin` changes"; and (9977)
"the standard GUI binding the shipped greedy one", and Appendix A (9797)
derived liveness.

Grepping `src/` for `pace`, `margin`, `gui`, `pause` returns no
implementation: the only hits are prose about GUI teardown in a docstring and
a comment at `src/dataplane.jl:8` recording the pacer diagnostics as
deliberately absent. `Base.kwarg_decl` on `run!` returns `[:t_end, :stop_on]`.

Consequences within my slice: `pace`, `margin` and `gui` are not accepted
keywords, so every appendix sentence about them is unrealizable; there is no
standard GUI device and no shipped greedy binding, so `is_greedy` has no
shipped instance (the trait and its complement machinery are built and
tested with fixture bindings); §11.7's derived liveness has no code at all,
there being no widget, port marking or claim-partition walk anywhere; and
the control plane is stop-only. The generic machinery a GUI would sit on —
`needs_calling_task` moving the loop to a spawned task, the greedy claim
source, the run-scoped roster — is all built, so what is missing is the
shipped instance and the pacing clock, not the substrate.

### 4.3 Nothing is exported

Appendix B (9813) calls its contents "The user-facing surface on one page".
§4.4 requires field constructors to be "plain, pure, exported"; §9.4 calls
`ProbeDual` "the framework's exported canonical probe scalar".

`src/Cadence.jl` is 24 lines: a `using`, twenty `include`s, `end`. No file
under `src/` contains the word `export`. My probe confirmed
`names(Cadence) == [:Cadence]` and that all 74 Appendix-B names I checked
report `exported = false`. `test/CadenceTests.jl:6-…` reaches the surface
through one long `import Cadence: …`.

Why it matters: `using Cadence` in a model package brings in nothing, so
every author-side declaration (`init_x`, `output_direct`, `child_connections`)
must be extended as `Cadence.init_x` or imported by name. That is a working
arrangement, but it is not the one the appendix describes, and the
distinction the spec draws between a curated exported surface and internal
machinery is not drawn anywhere in the code.

### 4.4 `condition` has no framework generic

Appendix B (9833) lists "Shipped conditions: `condition(::C; kw)` fragment
functions" in the authoring surface, and (10010) "`condition(comp; kw)` — the
shipped fragment-function idiom".

`isdefined(Cadence, :condition)` is `false`. The idiom is exercised only in
`test/fixtures.jl:746,749,758,767,929`, where `condition` is a fresh function
local to the test module. `TrimProblem` has a `condition` *field*
(`src/trim.jl:52`), which is unrelated.

The aircraft baselines the bullet names (`ready_for_taxi`, `cold_and_dark`)
are model-package material and rightly absent. But without a framework-owned
generic, two model packages that each define `condition` define two different
functions, and §14.2's "composed by pull from the structure's owner" — an
assembly calling `condition(sys.pwp.engine; n_eng)` on a child from another
package — does not resolve. Declaring `function condition end` beside the
other declaration stubs in `src/declare.jl` is what the idiom needs.

### 4.5 Auto-published ports do not exist

Appendix B's footnote (9851): "`y` iff the component produces any table cell
(`output_types` ∪ auto-published)", and (9854) "`y_x`/`y_s` iff the stage-1
*return* is non-empty (auto-published names excluded)".

`bundle_names` computes `y`'s presence from
`!isempty(declared_at(output_types, c, t))` alone (`src/declare.jl:293`).
There is no auto-publication anywhere: grepping `src/` for
`auto_publish`/`auto-published`/`autopublish` returns nothing, and a declared
output no stage produces is a build error, `DeclaredNotProduced`
(`src/build.jl:527-539`), not a framework write from the state store.

So the `y` row is short by exactly the auto-published half of its union, and
the `y_x`/`y_s` exclusion clause is vacuous — the set it excludes is empty.
The practical effect within my slice is small (both footnotes still compute
the right answer for models with no auto-published ports), but §5.3's rule
that a declared output matching a state field by name and type is published
by the framework has no code, which is agents A and B's finding to weigh.

### 4.6 The `Build` holds the data but prints nothing

Appendix B (9862): "the inspectable derived-contract artifact: wire list,
face table with provenance, schedule, root inputs"; and (9908) derivation
"printed with its drivers".

The data are all there. `Flat` (`src/assembly.jl:504-514`) carries `conns`
(the wire list), `in_faces`/`out_faces` (the two-sided face table with
producers), `root_inputs`, and `triples`/`anchors`/`aprov` (the
anchor-relative schedule with provenance). `Simulation` carries the bound
schedule as `sched` (`src/sim.jl:33`).

What is missing is the "plain printable data" half. `grep Base.show src/`
returns three hits, all `showerror` on error types. There is no `show` method
for `Build`, no `show` for the bound schedule (so no hyperperiod chart), no
accessor function taking a `Build` other than internal resolution helpers,
and no printout of a derived `Δt_base` with its drivers. `Build`'s fields are
untyped-access internals, so "the build a face-provenance table was printed
from" is not a thing a user can do today. The §9.2 detail belongs to agent C;
I record the appendix's own claim as short.

### 4.7 `ProbeDual` is not a name

Appendix B (9864): "`build(world; activations = (Float64, ProbeDual))`
additionally pins activation invariants for CI (`ProbeDual` the exported
canonical concrete probe scalar, §9.4)". §9.4 (spec:3309) spells it
`const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}`.

`isdefined(Cadence, :ProbeDual)` is `false`, and `grep -rn ProbeDual src/
test/` returns nothing. The `activations` keyword itself is built and tested
(`src/build.jl:381,387-390`; `test_build.jl:241` uses a Dual constructed
locally), so the gap is the one exported constant and the tag behind it. The
CI line the appendix writes cannot be typed as written.

### 4.8 `resolve` enforces one rule of the two

Appendix B (9868): "`resolve(asm, path) → AbstractComponent` — the getfield
walk along `/` segments, enforcing the one-level rule for wiring (§6.1) **and
the generic-holding rule for deep reads**, at the primitive (§13.3)."

`resolve` (`src/assembly.jl:308-316`) delegates to `_one_level`
(`src/assembly.jl:270-291`), which rejects anything past one child segment
with `PathResolution(:reaches_past)`. Its own docstring says "anything deeper
is a build error", and the comment at `src/assembly.jl:251` says the
generic-holding question "never arises in this register".

That is right for the structural register. But §13.3 (spec:7136-7143) places
a second duty on the *same* primitive: for the load-bearing register — the
deep paths condition entries, trim `reads` and taps write — the walk must
follow declared field types alongside instances and refuse a segment that
traverses past a generically-held field. `grep -rn isconcretetype src/`
returns nothing; there is no field-type walk anywhere, and no diagnostic kind
for it. The register-scoping table's middle row therefore has no
implementation, and a deep read past a `<: AbstractEngine` field resolves
silently on whatever concrete instance happens to be in hand — exactly the
substitution-time failure §13.3 says the strictness exists to prevent.

### 4.9 `algorithm = RK4()` is spelled `method = RK4`

Appendix B (9880, 9891): the keyword is `algorithm`, its default `RK4()`, an
instance. The spec spells it that way consistently (spec:9171, 2985, 4099,
5468, 6890, 10241 and the §12.7 replay table).

`src/sim.jl:130` declares `method = RK4`, and `src/sim.jl:172` validates it
as `method isa Type && method <: AbstractStepper`, then constructs at
`src/sim.jl:164` as `stepper = method(T, length(ex.xbuf))`. So both the
keyword name and the value's kind differ: `algorithm = RK4()` is a
`DeploymentInvalid(:method, :range)` twice over — the keyword is unknown, and
an instance would be refused if it were.

I found no `D-nnn` ratifying `method`; D-017 settles the seam and the two
backends but says nothing about the keyword's spelling. The trace's
deployment block records it as `method::Symbol` (`src/trace.jl:43`), so the
name has propagated into the replay comparison surface.

### 4.10 `t_end = Inf` is refused, not the default

Appendix B (9881, 9912): the constructor default is `Inf`, "the honest
interactive default — open-ended in time but bounded in memory, `log_max`
being what keeps such a session from growing without limit".

`src/sim.jl:131` defaults `t_end = nothing`, and `_t_bound_diag`
(`src/sim.jl:186`) is `(t isa Real && isfinite(t) && t ≥ 0)`, so `Inf` is
rejected. My probe confirmed:
`Cadence._t_bound_diag(Inf)` returns `DeploymentInvalid(:t_end, :range, Inf,
…)`. `run!` on a simulation with no bound from either site raises
`ArgumentInvalid(call = :run!, reason = :no_clock_bound)`
(`src/sim.jl:878`), asserted at `test_lifecycle.jl:114-118`.

The implemented policy is coherent and arguably safer — a run must name its
bound — but it is not the appendix's, and the two sentences that follow in
the appendix (the unbounded-run warning, `log_max` as the memory bound of an
open-ended session) describe a mode the package refuses to enter.

### 4.11 The run ends at the *nearest* frame top, not the first at or past `t_end`

Appendix B (9916): "A run ends at the first grid boundary reaching or
exceeding `t_end`, whole frames only (§12.4)."

`src/sim.jl:888` computes the target frame as `round(Int, te / sim.h)`, and
`step!` does the same at `src/sim.jl:1135`. `round` is nearest-with-ties-to-
even, not `ceil`. The docstring at `src/sim.jl:874` says "taken to the
nearest frame top", so the code is self-consistent and the spec is what it
diverges from.

Probe, run from the repository root:

```
sim = Simulation(feedback_model(); h = 1//50, t_end = 0.05)
init!(sim, fragment(inputs = (ref = 0.0,))); run!(sim)
# steps = 2, termination t = 0.04
```

With `h = 0.02` the grid boundaries are 0.04 and 0.06. The appendix says the
run ends at 0.06; it ends at 0.04, short of the requested bound. A caller
asking for `t_end = 0.05` gets 0.04 of trajectory. The existing test
(`test_lifecycle.jl:94`) uses `t_end = 1.0` on a `h = 1//50` grid, an exact
multiple, so it cannot see the difference.

### 4.12 `at` does not lift `TrimProblem`s or tap sets

Appendix B (10003): "`at(prefix, node)` — scoping; stores, never applies.
Also lifts whole `TrimProblem`s and linearization tap sets (§14.9, §14.10)."

`src/conditions.jl:75-76` defines exactly two methods:
`at(::AbstractString, ::ConditionNode)` and a catch-all that raises
`ConditionNodeMisuse`. There is no `at(::AbstractString, ::TrimProblem)` and
no method over a read set; `grep -rn mount src/` returns nothing. So a
`TrimProblem` authored against a sub-assembly cannot be mounted at a prefix
and reused from the root, which is §14.9's whole subject. Passing a
`TrimProblem` to `at` raises the misuse error rather than lifting it.

### 4.13 `linearize` is absent

Appendix B (10040): "`linearize(sim, taps) → labeled (ẋ₀, x₀, u₀, y₀, A, B,
C, D)` — pure query, one seeded Dual pass on scratch; operating point defaults
to `capture(sim)`; taps = `get_state`/`get_input`/`get_output` selector lists
with control-design labels (§14.10)."

`isdefined(Cadence, :linearize)` is `false`; the only hit for the string in
`src/` is a comment in `src/trim.jl:189` about the linearized LM step. The
ingredients are all built — the selector family with its optional component
index for named scalars (`src/readers.jl:22-80`), the compiled reader
(`src/readers.jl:207-233`), `capture` (`src/conditions.jl:813`), the seeded
Dual activation machinery (`src/trim.jl:62-67`, `src/build.jl:429`) — but the
entry point that assembles them is not written.

### 4.14 The termination record does not mark an override

Appendix B (10074): "The constructor's `t_end`/`stop_on` pair is recorded in
the run metadata; the override is reported by the termination record when it
fires (§13.5)."

The first half is accurate: `TraceHeader.deployment`
(`src/trace.jl:43-46`) carries `t_end` and `stop_on`. The second half is
short. `TerminationRecord` (`src/devices.jl:72-76`) carries `t`, `source` and
`residue`; `TerminationSource` is `EndTimeReached()`,
`ModelRequestedStop(face)`, `ControlRequestedStop(issuer)` or
`LoopError(exception)` (`src/devices.jl:34-48`). None of them says whether
the bound that fired was the constructor's default or a `run!` override, so a
run ended at `run!(sim; t_end = 0.5)` reports `EndTimeReached()` with `t =
0.5` and nothing distinguishes it from a constructor default of 0.5. The
consumer must reconstruct the override from the call it made.

### 4.15 `phase_bodies` returns the four blocks and nothing else

Appendix B (10093): "`phase_bodies(sim) → named callables` — … the four
blocks (`rhs`, `sweep_1`, `sweep_2`, `ticks` …) **plus per-event
guards/handlers and per-component `state_projection`**, keyed by the model's
roster."

`phase_bodies(sim) = sim.exec.bodies` (`src/sim.jl:316`), and `bodies` is the
four-field NamedTuple built at `src/build.jl:1006-1009`. The event entries
and projection entries go into `EventSet` instead
(`src/build.jl:1011-1012`, `src/executor.jl:239-262`), reachable only as
`sim.exec.events`. `test_executor.jl:11` asserts the exact key set:
`@test keys(b) === (:sweep_1, :sweep_2, :rhs, :ticks)`.

The §7.5 allocation seam therefore cannot be exercised per event or per
projection through the published accessor. `test_events.jl:273` covers the
quiet-boundary allocation case through the loop instead, so the property is
tested; what is missing is the diagnostic register the appendix promises,
in which a model's guards and handlers are individually addressable and
individually measurable.

## 5. Tally

| verdict | count |
|---|---|
| accurate | 126 |
| short | 7 |
| stand-in | 4 |
| absent | 18 |
| n/a | 2 |
| **total** | **157** |

Short (7): A stage totality (4.1); B the `y` bundle footnote (4.5); B the
`Build`'s inspectability (4.6); B `build(…; activations = (…, ProbeDual))`
(4.7); B `run!`'s keyword set (4.2); B override reporting in the termination
record (4.14); B `phase_bodies`' roster (4.15).

Stand-in (4): B `algorithm = RK4()` spelled `method = RK4` (4.9); B
`t_end = Inf` as the constructor default and B the same claim restated as the
honest interactive default (4.10, two rows); B the run's end frame (4.11).

Absent (18): the export surface (4.3); `condition` as an authoring name and
again as the algebra's shipped idiom (4.4, two rows); `ProbeDual` (4.7); the
generic-holding rule in `resolve` (4.8); `at`'s lifting of `TrimProblem`s and
tap sets (4.12); `linearize` (4.13); `Δt_base` derivation printed with its
drivers (4.6); the unbounded-run warning; and the nine pacing/GUI rows —
derived liveness, the shipped greedy GUI binding, `gui`, `pace`, `margin`,
`margin`'s 2 ms rationale, the GUI as a rostered calling-task device, the
bit-identical pacing law, and the pause/pace half of the control plane (4.2).

n/a (2): Appendix A's framing paragraph, and the value-level constructor,
which §4.4 makes a shipped component's obligation with no framework code
behind it.

No row carries a **ratified** or **rejected** marker. I checked the decision
log only at D-017 (the stepper seam), which settles the seam and the two
backends but not the keyword's spelling, so the `method`/`algorithm`
divergence is unratified as far as my slice can see.

## 6. Friction

**Appendix A's granularity resists row-counting.** Each bullet is one recall
line standing for a normative statement elsewhere, and several of them
bundle three or four checkable facts ("Guard predicates, edges and priors"
carries the two guard forms, the edge rule, the per-event prior, the
boundary-zero prior and the negated-guard convention). I gave one row per
bullet, on the ground that the appendix's own claim is "this contract has
code", and split only where a bullet's halves have visibly different
standings. A reader wanting per-fact granularity should read agents A, D and
F on the owning sections.

**"Exported" is used loosely across the spec.** §4.4 says "plain, pure,
exported function", §9.4 says "the framework's exported canonical probe
scalar", and Appendix B's title says "the user-facing surface". Since nothing
in the package is exported in Julia's sense, I had to decide whether the word
is normative or descriptive. I treated it as normative and gave it one row,
because a package's export list is a checkable claim and the spec never says
"reachable by qualified name" where it says "exported".

**Some Appendix B bullets are pure prose about behaviour rather than
signature**, for example "Paced and unpaced runs are bit-identical" and
"isolated invocation leaves buffers valid but off-trajectory". These sit at
the edge of my slice's remit — the brief says I audit "name, signature and
behaviour" — so I rowed them, but where the mechanism they describe belongs
to another agent's section I did not chase it beyond confirming the code
exists.

**One claim I could not fully decide.** Appendix B (9979) says `attach!` is
"legal in `built`, `initialized` and `stopped`". `assert_stopped`
(`src/devices.jl:131-133`) refuses only `:running`, so `:errored` is admitted
too, and the docstring at `src/devices.jl:128` calls that deliberate
("Every other state admits them, `:errored` included: post-mortem"). The
appendix's list is not obviously exhaustive-by-intent, so I marked the row
accurate and noted the extra state rather than calling it a deviation.
