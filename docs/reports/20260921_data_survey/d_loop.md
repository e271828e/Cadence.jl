# Data survey, slice D — the loop

Tip `aa9162a` (the brief names `34f8a39`; `aa9162a` adds the brief and touches no `src/`). Date 2026-09-21.

Files: `src/sim.jl`, `src/localization.jl`, and `CursorFrame`, `StepError`, `InternalInvariant` in `src/diagnostics.jl`. `localization.jl` defines no struct.

| struct | file | fields | outcome |
| --- | --- | --- | --- |
| `Run{T}` | `sim.jl:95` | 4 | finding 1 |
| `StepError{C}` | `diagnostics.jl:211` | 4 | finding 2 |
| `TerminationRecord{T}` | `sim.jl:66` | 4 | finding 3 |
| `StopPolicy` | `sim.jl:46` | 3 | clean; `addrs` named in finding 3 |
| `Simulation{T,E}` | `sim.jl:113` | 5 | clean |
| `EndTimeReached` | `sim.jl:23` | 0 | clean |
| `ModelRequestedStop` | `sim.jl:25` | 1 | clean |
| `ControlRequestedStop` | `sim.jl:29` | 1 | clean |
| `LoopError` | `sim.jl:33` | 1 | clean |
| `CursorFrame` | `diagnostics.jl:191` | 4 | clean |
| `InternalInvariant` | `diagnostics.jl:293` | 1 | clean |

Structs surveyed: 11. Findings: 3 (misplaced/courier 1, duplicate 1, misplaced 1), all three spec-rostered.

Method note. Every reader count below is a grep over all of `src/` (`\.name\b` plus the constructor calls). Runtime claims were checked in `julia --project=test -L test/repl.jl`; the scripts are in the scratchpad (`check_d.jl`, `check_d2.jl`, `check_d3.jl`).

## Findings

### `Run.log`, `Run.trace` on the placeholder run — misplaced (courier), spec-rostered

`src/sim.jl:96-97`. `const log::SnapshotLog`, `const trace::Union{Nothing,Trace{T}}`.
Writers: the positional constructor at two sites, `Simulation()` (`sim.jl:218-220`, the placeholder: an empty log carrying the three log keywords, an empty headerless `Trace` or `nothing` for the switch) and `_open_run!` (`sim.jl:681`, args 1 and 2).
Readers: as the run's own log and trace, `publish!` (`log!`, `sim.jl:1668`), `logged` (`1730`), `attach!`/`detach!` (`1461`, `1465`, `1499`), `drain!` (`1564`), `_replay_drain!` (`1622`), `trace(sim)` (`1756`), `init!`/`replay!` header capture (`762`, `932`). As the *carrier of the materialization keywords*: `_open_run!` (`sim.jl:679-681`) reads `L.enabled`, `L.every`, `L.max` and `sim.run.trace === nothing` off the run the last door left, and `init!` (`762`) and `replay!` (`932`) read `sim.run.trace === nothing` to decide whether to capture a header.
Evidence: `grep -n 'Run{T}(' src/*.jl` → 2 sites; `grep -n '\.enabled\b\|\.every\b\|\.max\b' src/sim.jl` → `679-681` only. REPL: `Simulation(…; log_every = 3, log_max = 7, trace = false)` gives `sim.run.log` flags `(true, 3, 7)` and `sim.run.trace === nothing`; after `init!` the run is a new object with the same flags and `nothing` again.
Reading: `log`, `log_every`, `log_max` and `trace` are keywords of `Simulation(deployment, T)` with no field of their own. `Simulation()` builds a `Run` before any door so the flags have somewhere to sit until `init!`, and every later door copies them out of the previous run into the next. The flags are written once at construction and read only by `_open_run!`; the run is the courier, and a chain of runs carries the configuration forward. The trace switch is the same thing spelled as an absence: `trace === nothing` on a run that never recorded is the kill switch, so a `trace = false` simulation is indistinguishable from one whose trace was dropped. The placeholder has a second job, giving the accessors (`mode`, `termination`, `logged`, `trace(sim)`) and the plane's drain thunks a run to read, which this finding does not touch.
Proposal: hold the four recording flags as one immutable value the `Simulation` owns (a sixth field, or a field of `Control`, which already holds the other operational keyword `join_timeout`), read by `_open_run!` and by the two header-capture sites. What changes: `Simulation()` (`sim.jl:196-223`) stores the value and may still build the placeholder run for the accessors; `_open_run!` (`676-683`) builds `SnapshotLog` and `Trace` from the value instead of from `sim.run`; `init!` (`762`) and `replay!` (`932`) test the flag rather than `sim.run.trace === nothing`; D-256's "five fields" sentence.
Spec: D-256 ("the recording flags carried to `init!`, which builds the run"), D-260 ("The trace switch rides on the run: a run built under `trace = false` has no trace"), §12.6, Appendix B. A ruling to raise, since D-256 and D-260 both chose the carriage explicitly.

### `StepError.t`, `StepError.boundary`, `StepError.frame.path` — duplicate (of the `NonfiniteState` species' payload), spec-rostered

`src/diagnostics.jl:213-215` and `192`. `t::Float64`, `boundary::Int`, `frame.path::Union{Nothing,String}`.
Writers: the one constructor `_wrap_step` (`sim.jl:1227-1235`), from `_seconds(sim.exec.clock.t)`, the frame-loop local `entry`, and the cursor's `comp`.
Readers: `Base.showerror(::StepError)` (`diagnostics.jl:243-263`) and `_phase_text`; tests. No other reader in `src/`.
Evidence: `grep -n '\.boundary\b' src/*.jl` → the carrier's two readers are `diagnostics.jl:251, 257, 259`, all presentation; `grep -n 'NonfiniteState(' src/*.jl` → `sim.jl:636` (in `_nonfinite`, `629-642`) builds the payload with `t = _seconds(ex.clock.t)`, `boundary = ex.clock.step - 1`, `path = paths[owner]`, and sets `cur.comp = owner` on the way. `entry` is `clock.step` before the frame's increment, so `clock.step - 1 == entry` for the whole frame, and `_check_finite!` is never reached from boundary zero (`boundary_zero!` calls no `step!`). REPL: the `Diverger` fixture armed at frame 2 gives `e.t == e.cause.t == 0.2`, `e.boundary == e.cause.boundary == 1`, `e.frame.path == e.cause.path == "div"`; `test/test_failures.jl:377-383` asserts the same three equalities.
Reading: for the one species whose payload also carries time, boundary and path, the carrier and its cause hold the same three facts, written at two sites from the same clock and cursor, with nothing but the frame loop's ordering keeping them equal. The payload's fields are out of this survey's scope (Appendix C rosters them), so the finding is reported from the carrier's side.
Proposal: one home. Either the payload drops `t` and `boundary` and `message(::NonfiniteState)` (`diagnostics.jl:283-287`) stops naming them, the carrier's own line already printing both above the cause; or the duplication is accepted so the diagnostic renders standalone through `logline`. What changes on the first: `_nonfinite` (`sim.jl:629-642`), the `NonfiniteState` struct and its `message`, Appendix C's row, `test_failures.jl` and `test_diagnostics.jl:571`.
Spec: §13.4 ("A `StepError` carries four things: the cursor's frame, the boundary time, the frame-entry boundary index, and the original exception"), Appendix C's `NonfiniteState` row ("Component path, the offending state block, boundary time and index"). Both sides rostered.

### `TerminationRecord.policy` (`StopPolicy.addrs`) — misplaced, spec-rostered

`src/sim.jl:68`, and `sim.jl:49`. `policy::StopPolicy`, whose `addrs::Vector{Any}` holds compiled root-cell addresses.
Writers: `_record` (`sim.jl:387-389`, arg 2) from the advance's `pol`; `StopPolicy` itself built at `_bind_policy` (`sim.jl:323-328`) only.
Readers of `.addrs`: `_stop_hit` (`sim.jl:394-397`), during the loop, off the argument `pol`. Readers of the record's `policy`: none in `src/`; `test/test_lifecycle.jl:249, 256` read `.t_end` and `.faces`. No `show` method on `TerminationRecord` or `StopPolicy`.
Evidence: `grep -n '\.addrs\b' src/*.jl` → `sim.jl:394-397` only (the other hits are `Reader.addrs` and `Writer.addrs`); `grep -n '\.policy\b' src/*.jl` → nothing. REPL: after `run!(u; stop_on = ("hit",))`, `termination(u).policy == StopPolicy(Inf, [:hit], Any[CellAddr{Bool,1}((0,))])` and `addrs[1] === u.exec.act.layout.addr[("", :hit)]`.
Reading: `StopPolicy` bundles what the caller declared (`t_end`, `faces`) with its compilation against the layout (`addrs`), a cache for the sampling read after every publication. The record is the policy's "one lasting home" (D-260), and it keeps the cache with it: a `Vector{Any}` of executor-internal addresses on a user-facing outcome value, derivable from `faces` and the layout, and read by nothing once the loop has returned. `addrs` is also a parallel vector to `faces`, index-aligned by construction at the one build site.
Proposal: the record keeps the declared pair and the addresses stay a loop local. Either `StopPolicy` shrinks to `(t_end, faces)` and `_bind_policy` returns the compiled addresses beside it, travelling as a second argument through `_advance!` → `frame!` → `_localized_frame!` → `_stop_hit` (`sim.jl:1179, 1197`, `localization.jl:31, 44, 157`); or `_record` stores the policy with `addrs` emptied. What changes: `StopPolicy` (`46-50`), `_bind_policy`, `_stop_hit`, the four `_record` calls, the three `frame!`-path signatures, §13.5's and glossary D.9's "with their resolved addresses".
Spec: §13.5 ("the immutable value of `t_end` plus the stop faces with their resolved addresses … afterwards only on the termination record"), glossary `StopPolicy`, D-255, D-260. A ruling to raise.

## Clean

- `Simulation{T,E}` (`sim.jl:113-124`): 5 fields. `deployment` 41 reads, `exec` 119, `run` 25, `plane` 28, `control` 19 across `src/`; `run` the only non-`const`, rebound at `_open_run!` only.
- `StopPolicy` (`sim.jl:46-50`): 3 fields. `t_end` read by `_t_end_frame` (3 sites) and the `UnboundedRun` advisory; `faces` by `_stop_hit` and the advisory; `addrs` by `_stop_hit`. The retained copy on the record is finding 3.
- `EndTimeReached` (`sim.jl:23`): 0 fields.
- `ModelRequestedStop` (`sim.jl:25-27`): 1 field. `face` written at `_advance!` (2 sites); read by tests only, no `show` method in `src/`.
- `ControlRequestedStop` (`sim.jl:29-31`): 1 field. `issuer` written at `_advance!` (2 sites); read by tests only.
- `LoopError` (`sim.jl:33-35`): 1 field. `exception::Any` written at `_run_body!` and `step!`; read by tests only.
- `CursorFrame` (`diagnostics.jl:191-196`): 4 fields. A value copy of the mutable `ExecutionCursor` at the catch (`_wrap_step`), needed because the cursor moves on; read by `_phase_text`, `showerror`, `==` and tests, presentation only. `path` is named in finding 2 for the one species.
- `InternalInvariant` (`diagnostics.jl:293-295`): 1 field. `msg` written at 13 throw sites across 7 files; read by `showerror` only.

Of the structs with findings, the remaining fields are clean: `Run.feed` (written at construction, `live!`, `_settle_mode!`; read by `mode`, `_replay_bound`, `_settle_mode!`, `live!`, `drain!`), `Run.termination` (written by the two tails at 4 sites; read by `closed`, `termination`); `StepError.frame` and `.cause` (`diagnostic`, `showerror`, tests); `TerminationRecord.source` and `.residue` (read by tests only; the residue is presented by `_residue!`'s `@warn` lines on the way into the record, not off it).

## Questions

1. `TerminationRecord.t` equals `latest(sim).t` and `sim.run.log.last.t` at assembly (REPL: `0.5 == 0.5 == 0.5`, and `0.4` on the face-stopped run), since nothing publishes after the tail. §13.5 wants the record self-contained ("the record's own `t` is the fact"), and a caller may hold the record past the next `init!`. Value semantics or derivable copy is a ruling, not a smell to fix.
2. The record's four fields and the three sources' payloads have no reader in `src/` and no `show` method; every reader is a test. They are the user-facing outcome (§13.5, D-203), so "read by tests only" is by design here, but the reader should know the record is never rendered by the framework.
3. `Run.trace === nothing` does double duty as §11.5's kill switch (D-260). A run whose trace is absent by configuration and one whose trace was never built read the same; `trace(sim)` reports the first as `ArgumentInvalid(:disabled)` because the doors propagate `nothing` faithfully. The overloading is what makes finding 1's carriage necessary.
4. `StopPolicy.faces` and `StopPolicy.addrs` are index-aligned parallel vectors, `addrs[i]` derivable from `faces[i]` and the layout. Built once at an immutable struct's single constructor site, the alignment has an enforcer by construction; raised only because finding 3 turns on the same field.

## Coverage

All 11 structs reached. `localization.jl` defines no struct; its state lives on the `Executor` (`xnext`, `ẋnext`, `has_localized`) and the `EventSet` (`σ0`, `σ1`, `trig`, `loc_warned`), slice B. `NonfiniteState` is a diagnostic kind and out of scope; it is named in finding 2 as the other half of a duplicate. The `Run` was surveyed like any other struct; increment 47b's own removals were not re-derived.
