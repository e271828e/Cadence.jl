# G — error discipline and the diagnostic kind set

## 1. Header

- **Agent**: G
- **Slice**: §13 error discipline, spec lines 6941–7644; Appendix C, spec lines
  10130–10287.
- **Tip**: `70672d1`, Julia 1.12.7.
- **Probes run**: yes, three. `p1.jl` (cross-component collection of
  `StoreWithoutUpdate`), `p2.jl` (§13.1's typo'd-wire no-cascade-suppression
  example), `p3.jl` (an illegal `init_x` leaf). All foreground
  `julia --project=.` from the repository root.
- **Cited passages read for meaning only**: §9.5 (runtime conformance), §11.8
  (the cells), §12.4 (the tail), §12.7 (replay), §14 (service lifecycle),
  Appendix B (unbounded run). Decision log entries read: D-057, D-058, D-059,
  D-060, D-084, D-157, D-203, D-209, D-214, D-217.
- **Forbidden files opened**: none. `src/dataplane.jl:36`, `src/dataplane.jl:8`
  and a few sibling comments *mention* `pending.md` by name; I did not open it.

## 2. Summary

The diagnostic layer is the most finished thing in this slice. `src/diagnostics.jl`
is a single closed set of 56 kinds under one `Diagnostic` root with
`severity`/`path`/`message`, one `BuildError` carrier that renders compiler-style
grouped by kind and sorted by path, and a runtime warning channel of nine more
kinds in `src/dataplane.jl` re-parented onto the same root. §13.4 is built
essentially verbatim: one `try` around the whole frame loop, a four-field
`ExecutionCursor` written by one store per dispatch, `StepError` with frame,
time, replay pointer and cause, the interrupt carve-out, and the nonfinite sweep
placed exactly where D-157 puts it. §13.5 and §13.6 are likewise complete —
typed termination sources, the constructor/`run!` precedence rule with identical
validation at both sites, the fixed consultation order, one tail with two
entries, and `ServiceLifecycle` refusals on an `errored` simulation.

The gaps cluster in three places.

**First, the reporting policy.** §13.1 splits the build's failure sites into
collecting declarative passes and fail-fast user-code evaluation, and D-057
explicitly rejects uniform fail-fast for "N clustered wiring errors". The
implementation collects inside `flatten`'s obligation pass and inside several
per-component passes, but the wiring resolver itself throws on the first
`UnknownPort`, `FaceDirectionConflict`, `PathResolution` or `UnknownFaceSelection`,
and `classify`, `classify_tier` and `children` throw per component rather than
per stratum. Nine Appendix C kinds whose policy column reads *collected* are
raised fail-fast. The flagship example of §13.1 — a wire typo'd as `:throtle`
reporting both the did-you-mean and the unconnected `throttle` — does not hold:
probe `p2` produced exactly one diagnostic.

**Second, twelve Appendix C kinds have no code at all.** `WalkingFaceAtFrozenEntry`,
`AbstractAtRoot`, `IllegalStateLeaf`, `TierSignatureMismatch`, `MissingProbeValue`,
`DeadStage`, `BundleFieldError`, `UserCodeFraming`, `GridUtilization`,
`DebtReanchor`, `ThreadBudget`, `UnboundedRun`. Two of these are load-bearing for
the whole error discipline. `UserCodeFraming` is §13.2's framing diagnostic: there
is no `try` anywhere in `src/build.jl`, so a user-code exception during a probe
propagates raw, with no component path and no probe context. `BundleFieldError`
is §13.2's one *recognized* class, the `FieldError` matched against the bundle's
NamedTuple type; no `FieldError` handling exists anywhere in `src/`. `IllegalStateLeaf`'s
absence is visible in probe `p3`: an `init_x` holding a `Vector` reaches
`build` and dies as a bare `MethodError`, which is precisely the non-local,
unreadable failure §8.4 and §13 exist to eliminate.

**Third, §13.7's deliverables are absent.** There is no standard component
library — no junction, no Bool gate, no `Or{N}`, no `UnitDelay{V}`, no
`Constant{V}` — and no `Build` printer, so face provenance is unrendered. `Group`
is the one library member built. The spec dates the library to the migration
phase, so this is deferral rather than drift, but the rig idiom of §13.7 depends
on `Constant` and cannot be written today.

Smaller but worth naming: `ConformanceFailure` is spec'd as raised "build, at
probe; runtime thereafter" and every one of its fifteen raising sites is in
`src/build.jl`; the runtime table-write point does no conformance check, so
§13.4's "conformance failure needs no separate path" is half true. About fifteen
kinds carry a payload column short of Appendix C by one variable field — most
often a list-in-hand or a provenance tag that is stated in the message but not
matchable by a test, which is exactly what §13.2 says a test must be able to
match on. And one kind, `EventHalfMissing`, carries a *model type* in its
payload (`found = typeof(c)`), against §13.2's "strings, never instances, never
model types" doctrine, with `_typename` sitting one file away.

What surprised me, positively: the runtime warning channel's decision to make
writer attribution the *cell's* rather than the payload's is coherent, documented
at `src/dataplane.jl:38-42`, and costs five Appendix C payload fields — a real
short, but an argued one. And `test/test_diagnostics.jl:492` asserts
`Set(typeof.(occurrences)) == Set(subtypes(Diagnostic))`, a closure test that
makes the kind set self-policing against additions. It does not police against
Appendix C, which is why twelve kinds can be missing with a green suite.

## 3. Findings

### 3.1 §13.1 Reporting policy (spec 6951–6999)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 13.1 / 6955 | declarative checks over collected structure return their full violation list | short | `src/assembly.jl:658`, `src/build.jl:416` | `test_conditions.jl:134`, `test_readers.jl:77`, `test_trim.jl:229` | see 4.1 |
| 13.1 / 6957 | the whole-tree obligation check computes the *set of* unfed inputs | accurate | `src/assembly.jl:641-651` | `test_assembly.jl:420` | |
| 13.1 / 6970 | user-code evaluation fails fast: the first exception aborts the phase (D-057) | short | no `try` in `src/build.jl` | no test | see 4.2 — nothing catches, so "aborts the phase" holds only by propagation, unframed |
| 13.1 / 6983 | strata are barriers: a stratum producing an error-severity diagnostic throws before the next begins | accurate | `src/build.jl:381-392` | no test | `flatten` → `classify_tier` → events → Stratum C, each throwing on its own |
| 13.1 / 6988 | the only partial results carried past a failure are violation lists from pure checking passes | accurate | `src/build.jl:416`, `src/conditions.jl:475` | no test | |
| 13.1 / 6993 | no cascade suppression: a typo'd wire reports both the did-you-mean and the unconnected input | absent | `src/assembly.jl:478-490` | no test | see 4.1; probe `p2` yields one diagnostic |
| 13.1 / 6997 | diagnostics render adjacently, sorted by path | accurate | `src/diagnostics.jl:81-102` | `test_diagnostics.jl:506-518` | |

### 3.2 §13.2 Diagnostics as values (spec 7001–7100)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 13.2 / 7009 | a diagnostic is a plain value from a small closed set of kinds (D-058) | accurate | `src/diagnostics.jl:23` | `test_diagnostics.jl:492` | |
| 13.2 / 7010 | Appendix C enumerates that set normatively | short | `src/diagnostics.jl`, `src/dataplane.jl:56-131` | `test_diagnostics.jl:492` | 66 of 78 rows built; see 3.6–3.9 |
| 13.2 / 7016 | each kind carries its own structured payload, incl. the did-you-mean list-in-hand | short | per-kind | `test_diagnostics.jl:236` | ~15 kinds short by a field; see 3.6–3.9 |
| 13.2 / 7020 | a kind *is* a Julia type | accurate | `src/diagnostics.jl:23` | `test_diagnostics.jl:492` | |
| 13.2 / 7021 | severity is `error` or `warning`, a property of the kind, read as `severity(d)`, never stored per occurrence | accurate | `src/diagnostics.jl:38`, `src/dataplane.jl:148-156` | `test_diagnostics.jl:485` | no kind has a severity field |
| 13.2 / 7024 | where an occurrence surfaces and how it is reported are facts of the site, not of the value | accurate | `src/diagnostics.jl:8` | no test | no kind carries a stage or policy field |
| 13.2 / 7031 | checking passes return diagnostics; the stratum barrier throws one `BuildError` wrapping the collection | short | `src/diagnostics.jl:69` | `test_diagnostics.jl:504` | the carrier exists; the barrier is per-pass, see 4.1 |
| 13.2 / 7034 | `showerror` renders the carrier compiler-style, grouped by kind, sorted by path | accurate | `src/diagnostics.jl:90-102` | `test_diagnostics.jl:506-518` | |
| 13.2 / 7050 | a user-code exception is wrapped in a framing diagnostic (path, function, probe context) with the original as `cause` | absent | — | no test | see 4.2 |
| 13.2 / 7055 | a `FieldError` matched against the bundle's NamedTuple type becomes the bundle-law did-you-mean with the legal set and classification | absent | — | no test | see 4.3 |
| 13.2 / 7061 | nothing is recovered by reading message text | accurate | `src/sim.jl:1082` | no test | `_species` discriminates on type |
| 13.2 / 7063 | tests match on kind plus payload, never on message text | accurate | `test/` | `test_diagnostics.jl:498-503` | the suite states and enforces the one exception |
| 13.2 / 7068 | strings, never instances; never model types; expected/observed *port* types the exception | short | `src/diagnostics.jl:26-30` | no test | see 4.4 — `EventHalfMissing.found = typeof(c)` |
| 13.2 / 7072 | the didactic register is policy: every diagnostic states the fix or the lists-in-hand | accurate | `src/diagnostics.jl` messages | `test_diagnostics.jl:520-536` | |
| 13.2 / 7077 | the build diagnostic stream's warning set is currently empty (D-084) | accurate | `src/diagnostics.jl:38` | `test_diagnostics.jl:479-483` | no warning-severity kind is raised at build |
| 13.2 / 7085 | the runtime stream is per-occurrence, carried by per-writer diagnostic cells | accurate | `src/dataplane.jl:134-231` | `test_diagnostics.jl:169` | |
| 13.2 / 7087 | the rate limit is structural: a bounded ring plus per-kind suppressed counts, drained at frame top | accurate | `src/dataplane.jl:224` (`DIAG_RING = 16`), `:189-213` | `test_diagnostics.jl:86` | |
| 13.2 / 7096 | a service warning is a synchronous per-call annotation emitted once at the call's return beside the value, its payload duplicated as plain report fields | accurate | `src/trim.jl:565,576`; `src/trim.jl:97-108` | `test_trim.jl` trim-commit sets | `TrimReport.fired_events` / `.committed_residuals` duplicate the payloads |
| 13.2 / 7104 | committed runtime warning: chattering / localization-budget exhaustion | accurate | `src/localization.jl:78` | `test_localization.jl` | |
| 13.2 / 7106 | committed runtime warning: firing-budget exhaustion | accurate | `src/sim.jl:452` | `test_events.jl` | |
| 13.2 / 7108 | committed runtime warning: forgiven-debt re-anchor | absent | — | no test | pacer absent; `DebtReanchor` unbuilt |
| 13.2 / 7110 | committed runtime warnings: the write-surface and entry violations, all at staging | accurate | `src/dataplane.jl:465-492` | `test_dataplane.jl`, `test_roster.jl` | |
| 13.2 / 7119 | committed runtime warning: a tolerated device-side datum failure via `report!(handle, …)` | accurate | `src/devices.jl:291`, `:275` | `test_diagnostics.jl:59` | |
| 13.2 / 7122 | committed runtime warning: staging discarded during replay | accurate | `src/sim.jl:1403` | `test_trace.jl` | |
| 13.2 / 7124 | committed runtime warning: thread-budget tightness, once per `run!` | absent | — | no test | `ThreadBudget` unbuilt |
| 13.2 / 7126 | committed runtime warning: device join timeout, collected into the termination record | accurate | `src/devices.jl:448`, `src/sim.jl:975` | `test_diagnostics.jl:149` | |
| 13.2 / 7131 | committed runtime warning: device crash, the sim continuing with the device absent | accurate | `src/devices.jl:352,382` | `test_devices.jl` | |
| 13.2 / 7133 | committed runtime warning: unbounded run | absent | — | no test | `UnboundedRun` unbuilt |

### 3.3 §13.3 Build primitives and the register scoping (spec 7136–7215)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 13.3 / 7141 | `resolve(asm, path::String) → AbstractComponent`, the getfield walk along `/`-segments | accurate | `src/assembly.jl:308` | `test_assembly.jl:647` | |
| 13.3 / 7143 | `input_faces(c)` / `output_faces(c) → Vector{String}` over the two classes | accurate | `src/assembly.jl:342,352` | `test_assembly.jl:647` | |
| 13.3 / 7147 | declaration order preserved | accurate | `src/assembly.jl:342-355` | `test_assembly.jl:647` | |
| 13.3 / 7149 | `resolve_terminal(asm, path) → (component, name)`, splitting the final segment | accurate | `src/assembly.jl:324` | `test_assembly.jl:647` | |
| 13.3 / 7155 | the one-level rule: a connection endpoint resolves to an immediate child and one of its faces | accurate | `src/assembly.jl:274-289` | `test_assembly.jl:325` | |
| 13.3 / 7159 | the generic-holding rule: a segment traversing *past* a generically-held field is a diagnostic | absent | — | no test | see 4.5 |
| 13.3 / 7164 | an unknown segment errors with the sibling field list in hand | accurate | `src/assembly.jl:280-284` | `test_assembly.jl:325` | |
| 13.3 / 7172 | register table row: structural — wiring resolution, one-level rule | accurate | `src/assembly.jl:257-289` | `test_assembly.jl:325` | |
| 13.3 / 7173 | register table row: load-bearing — conditions, trim `reads`, taps; strict, at the authoring or mount level | short | `src/conditions.jl:258`, `src/readers.jl`, `src/trim.jl` | `test_conditions.jl`, `test_readers.jl` | resolution runs against the flattened build's absolute paths, with no strictness rule to enforce; see 4.5 |
| 13.3 / 7174 | register table row: diagnostic — device read bindings, snapshot inspection; the instance walk | accurate | `src/bindings.jl:139-186` | `test_bindings.jl`, `test_readers.jl` | |
| 13.3 / 7187 | drift stays loud: an unknown path is an attach-time `ReadBindingUnresolved` with did-you-mean | accurate | `src/bindings.jl:162-186` | `test_readers.jl` | |
| 13.3 / 7208 | `resolve_terminal` is first-class, shared by five clients across the three registers | stand-in | `src/assembly.jl:257`, `:324` | `test_assembly.jl:647` | the structural clients share it; conditions, taps and read bindings resolve against the flat build with their own splitters, so there is not one did-you-mean site |
| 13.3 / 7205 | which register a client resolves under is internal framework fact, never user-facing API | accurate | no register argument anywhere | no test | |

### 3.4 §13.4 Runtime failures (spec 7217–7317)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 13.4 / 7219 | the loop wraps each execution of the boundary macro-sequence in a single `try`, never per stage or per component (D-059) | accurate | `src/sim.jl:1029-1060` | `test_failures.jl:22-105` | the `try` spans the whole frame loop |
| 13.4 / 7223 | the executor maintains an execution cursor, a plain mutable field of the loop state | accurate | `src/executor.jl:15-22` | `test_failures.jl:22` | |
| 13.4 / 7226 | the cursor records the component path, as a schedule index | accurate | `src/executor.jl:16`, `src/sim.jl:1072` | `test_failures.jl:32` | |
| 13.4 / 7227 | the cursor records which function is running (the seven named) | accurate | `src/executor.jl:145,151,161,221,291,306,321` | `test_failures.jl:32,46,90` | |
| 13.4 / 7229 | the cursor records the boundary phase: RK stage, event round, localization trial, tick | accurate | `src/executor.jl:25`, `src/sim.jl:327,370,432,487` | `test_failures.jl:32,46,64,76` | |
| 13.4 / 7232 | one cheap store per dispatch: no allocation, no exception frames | accurate | `src/executor.jl:145` etc. | no test | plain `Int`/`Symbol` field writes |
| 13.4 / 7234 | it covers every user-code surface uniformly, RK stage points and guard trial points included | accurate | `src/sim.jl:327`, `src/localization.jl` | `test_failures.jl:32,64` | environment closures are not a construct that exists |
| 13.4 / 7247 | the catch site wraps the original exception in `StepError` | accurate | `src/sim.jl:1067-1074` | `test_failures.jl:32` | |
| 13.4 / 7248 | `StepError` carries frame, boundary time, frame-entry boundary index, cause | accurate | `src/diagnostics.jl:149-155` | `test_failures.jl:32,251` | |
| 13.4 / 7251 | the frame-entry index is the frame-top boundary at which the failing frame began, always a legal replay halt | accurate | `src/sim.jl:1045` (`entry = clock.step`) | `test_failures.jl:251`, `test_trace.jl:460` | |
| 13.4 / 7255 | a `StepError` is rendered with compact frames | accurate | `src/diagnostics.jl:178-191` | `test_failures.jl:136` | |
| 13.4 / 7257 | conformance failure is thrown as its typed diagnostic at the table-write point and arrives at the same catch site as a `StepError` species | short | `src/store.jl:81`, `src/build.jl` only | `test_failures.jl:188` (for `NonfiniteState`) | see 4.6 — no runtime conformance check; the species *mechanism* exists |
| 13.4 / 7262 | staged inputs are drained and recorded to the trace at the frame top, before the boundary executes | accurate | `src/sim.jl:1046-1048` | `test_trace.jl:460` | |
| 13.4 / 7266 | `replay!(sim2, trc; to_boundary = k)` halts at that frame top in `:replay`, the failing record still ahead | accurate | `src/sim.jl:718-760`, `:1379` | `test_failures.jl:251`, `test_trace.jl:460` | |
| 13.4 / 7277 | an `InterruptException` is discriminated and routed to the stop path, the run ending `stopped` | accurate | `src/sim.jl:1058` | `test_failures.jl:114` | |
| 13.4 / 7286 | the `Simulation` ends `stopped` or `errored` with the exception retrievable | accurate | `src/sim.jl:976-987`, `:265` | `test_lifecycle.jl:222` | |
| 13.4 / 7287 | a synchronous unattended run rethrows after the shutdown tail completes | accurate | `src/sim.jl:962-971` (`rethrow()` before `finally`) | `test_lifecycle.jl:228` | |
| 13.4 / 7289 | an interactive session logs the rendered error and surfaces the status rather than rethrowing | absent | — | no test | `run!` rethrows unconditionally; no interactive/unattended discrimination exists |
| 13.4 / 7293 | a loop-level `isfinite` sweep over `x` at boundaries fails fast as a `StepError` species | accurate | `src/sim.jl:501-508`, `:511-524` | `test_failures.jl:188` | |
| 13.4 / 7295 | it names the offending component's state block and the boundary | accurate | `src/diagnostics.jl:201-206` | `test_failures.jl:188`, `test_leaves.jl:95` | |
| 13.4 / 7299 | placement: the boundary's **first act**, immediately after integrate, before `state_projection` and the boundary sweep | accurate | `src/sim.jl:489` | `test_failures.jl:188,208` | |
| 13.4 / 7309 | `ẋ` does not participate (D-157) | accurate | `src/sim.jl:494-499` | no test | the sweep reads `xbuf` only |
| 13.4 / 7313 | domain separation: a device-side bug takes the per-device crash path (`DeviceCrash`) while the sim keeps running | accurate | `src/devices.jl:352,382` | `test_devices.jl` | |
| 13.4 / 7316 | an unmappable datum is tolerated and reported (`MalformedDatum`) | accurate | `src/devices.jl:275,291` | `test_diagnostics.jl:59` | |

### 3.5 §13.5 Termination and §13.6 abnormal shutdown, §13.7 tooling (spec 7319–7644)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 13.5 / 7321 | no `SimulationTermination` counterpart; exceptions from model code are always abnormal (D-060) | accurate | `src/devices.jl:36-48` | `test_lifecycle.jl:222` | no informational-throw path exists |
| 13.5 / 7327 | detection is ordinary guard/handler/mode machinery | accurate | `src/executor.jl:176-330` | `test_lifecycle.jl:141,162` | |
| 13.5 / 7336 | publication is an ordinary `Bool` output face exported to the root | accurate | `src/sim.jl:194-222` | `test_lifecycle.jl:126` | |
| 13.5 / 7346 | `stop_on` names root-exported `Bool` output faces, OR-combined and validated against the `Build` | accurate | `src/sim.jl:194-222`, `:284-291` | `test_lifecycle.jl:126` | |
| 13.5 / 7348 | the pair is recorded in the run metadata / trace header | accurate | `src/trace.jl:291-292` | `test_trace.jl` | the *constructor's* pair, per D-217 |
| 13.5 / 7350 | after **every** published boundary the loop reads the named faces in the snapshot it just published | accurate | `src/sim.jl:1049-1052`, `:284-291` | `test_lifecycle.jl:141,162` | grid, `t*` and boundary zero alike |
| 13.5 / 7353 | the first `true` initiates shutdown with *this* snapshot as final, no roll-back | accurate | `src/sim.jl:1051`, `:1027` | `test_lifecycle.jl:141,162` | |
| 13.5 / 7359 | `run!` checks the boundary-zero snapshot before the first step | accurate | `src/sim.jl:1026-1027` | `test_lifecycle.jl:152` | |
| 13.5 / 7363 | the default is no stop faces and a run to `t_end` | accurate | `src/sim.jl:877` | `test_lifecycle.jl:94` | |
| 13.5 / 7367 | both are `run!`-time overridable with the constructor value as the default | accurate | `src/sim.jl:877-885` | `test_lifecycle.jl:94,174` | |
| 13.5 / 7370 | nothing about the `Simulation` is mutated, so the next `run!` gets the constructor's policy | accurate | `src/sim.jl:881-884` | `test_lifecycle.jl:174` | `pol` is per-run scratch; `sim.t_end`/`sim.stop_on` untouched |
| 13.5 / 7391 | `stop_on` validation runs at **both** binding sites, identically | accurate | `src/sim.jl:194` called at `:161` and `:882` | `test_lifecycle.jl:126` | |
| 13.5 / 7391 | `t_end` validation runs at both sites, identically | accurate | `src/sim.jl:186-192` | `test_lifecycle.jl:94` | |
| 13.5 / 7411 | the termination record holds the final boundary time (absent when no boundary ran), the source and the tail residue | accurate | `src/devices.jl:72-76`, `src/sim.jl:279` | `test_lifecycle.jl`, `test_diagnostics.jl:149` | |
| 13.5 / 7418 | `EndTimeReached` — no payload | accurate | `src/devices.jl:36` | `test_lifecycle.jl:94` | |
| 13.5 / 7421 | `ModelRequestedStop` — the holding face | accurate | `src/devices.jl:38-40` | `test_lifecycle.jl:141` | |
| 13.5 / 7423 | `ControlRequestedStop` — its issuer (device, `:code`, `:interrupt`) | accurate | `src/devices.jl:42-44`, `src/sim.jl:1058` | `test_devices.jl:119,164`, `test_failures.jl:114` | |
| 13.5 / 7425 | `LoopError` — the propagated cause; the record covers `errored` as it covers `stopped` | accurate | `src/devices.jl:46-48`, `src/sim.jl:971,978` | `test_lifecycle.jl:222` | |
| 13.5 / 7433 | the operator interrupt is a tag on an ordinary stop, not a kind of its own | accurate | `src/sim.jl:1058` | `test_failures.jl:114` | |
| 13.5 / 7437 | sources are consulted in a fixed order: pending control stop at frame top, then `t_end`, then the stop faces (D-203) | accurate | `src/sim.jl:1031-1051` | `test_lifecycle.jl` | |
| 13.5 / 7402 | taught contract: both stop-flag shapes work without framework latching | accurate | `src/sim.jl:284-291` | `test_lifecycle.jl:141` | the loop reacts to the first `true` |
| 13.5 / 7409 | rejected mechanisms (predicate closures, root-declared policy, blessed terminal types, observation-by-path) | n/a | — | — | rationale, D-060 |
| 13.5 / 7444 | post-terminal dynamics are the model's job (the `robot2d` argument) | n/a | — | — | rationale |
| 13.5 / 7462 | the observation doctrine: diagnostic observation vs. load-bearing observation | n/a | — | — | doctrine, realized by the `stop_on` rows above |
| 13.6 / 7474 | the boundary is all-or-nothing outside the sim task; snapshot publication is the only externally visible act, at the very end | accurate | `src/sim.jl:1049-1050` | `test_lifecycle.jl:222` | |
| 13.6 / 7487 | the abnormal path discards the failed boundary and promotes the previous snapshot to final | accurate | `src/sim.jl:962-971` | `test_lifecycle.jl:222` | nothing to discard: the frame published nothing |
| 13.6 / 7489 | one tail with two entries; everything downstream of "final snapshot" runs identically | accurate | `src/sim.jl:941-942` (`finally`), `src/devices.jl:_tail!` | `test_lifecycle.jl:222` | |
| 13.6 / 7513 | the termination record covers this entry, source `LoopError` | accurate | `src/sim.jl:971,978` | `test_lifecycle.jl:222` | |
| 13.6 / 7518 | tail hygiene: each hook individually caught-and-logged | accurate | `src/devices.jl:329,436` | `test_devices.jl` | |
| 13.6 / 7524 | what is lost is quarantined: the stores are retained on the errored `Simulation` for post-mortem | accurate | `src/sim.jl:978-980` | `test_lifecycle.jl:238` | nothing is cleared on the error path |
| 13.6 / 7527 | an errored sim is terminally stopped, not resumable; the services refuse it outright (`ServiceLifecycle`) | short | `src/sim.jl:612,725`, `src/trim.jl:387`, `src/conditions.jl:815` | `test_trace.jl:826` | `attach!`/`detach!` refuse only `:running` (`src/devices.jl:131-133`), so an errored sim still admits roster edits |
| 13.6 / 7532 | the published record ends at the last consistent boundary; nothing downstream sees half a boundary | accurate | `src/sim.jl:1049-1050` | `test_lifecycle.jl:238` | |
| 13.7 / 7539 | predicate-based selection alongside `except`/`only` on both passthrough helpers (D-209) | absent | `src/assembly.jl:382,404` | `test_assembly.jl:672,694` | `except`/`only` built; no predicate filter |
| 13.7 / 7548 | the `Build` printer owes face provenance (root face → resolved chain to the producing terminal) | absent | no `Base.show` for `Build` anywhere | no test | see 4.7 |
| 13.7 / 7558 | a standard component library: summing junctions, Bool gates, `UnitDelay`, `Constant{V}` | absent | — | no test | see 4.7 |
| 13.7 / 7566 | `Group`, the on-the-fly assembly (D-184) | accurate | `src/assembly.jl:209-234` | `test_assembly.jl` | |
| 13.7 / 7571 | library blocks are ordinary components, no framework privileges | n/a | — | — | doctrine over an unbuilt library |
| 13.7 / 7579 | `Or{N}` builds its face set from a type parameter | absent | — | no test | |
| 13.7 / 7588 | `UnitDelay{V}` is a discrete leaf at `K = 1` | absent | — | no test | |
| 13.7 / 7605 | `Constant{V}` is the source block, deliberately pinned at `V` | absent | — | no test | |
| 13.7 / 7627 | any component may be the root of a build, its input faces becoming root inputs (D-208) | accurate | `src/assembly.jl:679-692` | `test_assembly.jl` | |
| 13.7 / 7630 | the rig is a one-child assembly surfacing the child's face set via `input_passthrough` verbatim | absent | — | no test | depends on `Constant`; no rig fixture exists |
| 13.7 / 7643 | the rig adds zero new machinery | n/a | — | — | consequence of the row above |

### 3.6 Appendix C — declaration and wiring (Stratum A), 26 rows

| kind | verdict | location | test | note |
|---|---|---|---|---|
| `UnknownPort` | short, rejected D-057 | `src/diagnostics.jl:232`; raised `src/assembly.jl:483`, `:729` | `test_diagnostics.jl:239` | payload full; policy is *collected* in Appendix C but the wire-end arm throws fail-fast. See 4.1 |
| `UnconnectedInput` | short | `src/diagnostics.jl:249`; raised `src/assembly.jl:647` | `test_assembly.jl:420` | payload lacks the declared entry type and the obligation chain's last level. Policy collected, correct |
| `TwoProducers` | short | `src/diagnostics.jl:259`; raised `src/assembly.jl:756` | `test_diagnostics.jl:245` | both producer *terminals* appear only inside the two provenance strings, not as matchable fields |
| `WireTypeMismatch` | short, rejected D-057 | `src/diagnostics.jl:271`; raised `src/build.jl:1033` | `test_diagnostics.jl:247` | payload full (plus the activation for the pin hint); raised fail-fast inside `_probe_input`, spec says collected |
| `WalkingFaceAtFrozenEntry` | absent | — | no test | no kind, no check |
| `PathResolution` | short, rejected D-057 | `src/diagnostics.jl:313`; raised `src/assembly.jl:261,280,286,311` | `test_diagnostics.jl:250` | no arm for a read-side traversal past a generically-held field, so that half of the payload column is unreachable; fail-fast, spec says collected |
| `AbstractAtRoot` | absent | — | no test | |
| `RootInputTypeConflict` | short, rejected D-057 | `src/diagnostics.jl:300`; raised `src/build.jl:298` region | `test_diagnostics.jl:249` | payload full; check collects within its own pass |
| `IllegalStateLeaf` | absent | — | no test | see 4.8; probe `p3` shows a bare `MethodError` in its place |
| `StoreWithoutUpdate` | short, rejected D-057 | `src/diagnostics.jl:346`; raised `src/build.jl:77` | `test_diagnostics.jl:258` | no shadowing note; thrown per component, probe `p1` shows one of two named |
| `EventHalfMissing` | short | `src/diagnostics.jl:356`; raised `src/build.jl:405,411` | `test_diagnostics.jl:259` | payload full but `found` is the *model type*, against §13.2. See 4.4. Policy collected, correct |
| `ClassUnreadable` | short, rejected D-057 | `src/diagnostics.jl:371`; raised `src/assembly.jl:48` | `test_diagnostics.jl:261` | no type, no shadowing note; fail-fast, spec says collected |
| `ClassMixed` | short, rejected D-057 | `src/diagnostics.jl:384`; raised `src/assembly.jl:44` | `test_diagnostics.jl:262` | payload adequate; fail-fast, spec says collected |
| `ContainerMixed` | short | `src/diagnostics.jl:395`; raised `src/assembly.jl:124` | `test_diagnostics.jl:263` | payload lacks the offending element keys/indices; collected per component |
| `DeclarationOnWrongTier` | short, rejected D-057 | `src/diagnostics.jl:406`; raised `src/build.jl:90` | `test_diagnostics.jl:264` | payload full; collects within one component, throws before the next |
| `TierSignatureMismatch` | absent | — | no test | |
| `FaceNameIllegal` | accurate | `src/diagnostics.jl:425`; raised `src/assembly.jl:776` | `test_assembly.jl:413` | collected, correct |
| `FaceNameCollision` | short | `src/diagnostics.jl:438`; raised `src/assembly.jl:781`, `:798` | `test_assembly.jl:413` | payload lacks both entries' provenance (hand-written / computed) |
| `FaceDirectionConflict` | short, rejected D-057 | `src/diagnostics.jl:453`; raised `src/assembly.jl:487` | `test_diagnostics.jl:270` | payload full; fail-fast, spec says collected |
| `UnknownFaceSelection` | short, rejected D-057 | `src/diagnostics.jl:467`; raised `src/assembly.jl:421,425` | `test_assembly.jl:694` | payload full; fail-fast, spec says collected |
| `RatesViolation` | accurate | `src/diagnostics.jl:484`; raised `src/assembly.jl:705`, `_check_sample_times` | `test_assembly.jl` | payload a superset; collected |
| `MissingProbeValue` | absent | — | no test | |
| `ChildNameCollision` | accurate | `src/diagnostics.jl:515`; raised `src/assembly.jl:137,144,183` | `test_assembly.jl` | payload full; collected per component |
| `TransparentContainerUnknown` | short | `src/diagnostics.jl:540`; raised `src/assembly.jl:169` | `test_diagnostics.jl:291` | payload lacks the type's container fields, the list-in-hand |
| `TierUnreadable` | short, rejected D-057 | `src/diagnostics.jl:553`; raised `src/build.jl:81` | `test_diagnostics.jl:292` | payload lacks the type; fail-fast, spec says collected |
| `IllegalPortType` | accurate | `src/diagnostics.jl:565`; raised `src/build.jl:278` | `test_diagnostics.jl:293` | the leaf vocabulary is a constant, carried in the message; collected |

### 3.7 Appendix C — schedule and contract conformance (Strata B and C), 10 rows

| kind | verdict | location | test | note |
|---|---|---|---|---|
| `AlgebraicCycle` | short | `src/diagnostics.jl:581`; raised `src/build.jl:246` | `test_build.jl` | members are component paths, not terminals; no wires among them, no real/artificial classification. Also reports the whole unresolved remainder, not per-SCC |
| `ProducedByTwoStages` | short, rejected D-057 | `src/diagnostics.jl:590`; raised `src/build.jl:517` | `test_build.jl` | payload lacks both stage names; fail-fast, spec says collected |
| `DeclaredNotProduced` | short | `src/diagnostics.jl:599`; raised `src/build.jl:532` | `test_build.jl` | payload lacks the state-field list; collected |
| `UndeclaredReturnField` | accurate | `src/diagnostics.jl:611`; raised `src/build.jl:155` | `test_build.jl` | payload full; fail-fast per Appendix C |
| `DeadStage` | absent | — | no test | a stage returning bare `(;)` is not refused |
| `ConformanceFailure` | short | `src/diagnostics.jl:627`; 15 sites, all in `src/build.jl` | `test_diagnostics.jl:298-309` | the *runtime* half of the raised column is absent (see 4.6); no `t` field, so the simulation time is the carrier's |
| `GuardForm` | accurate | `src/diagnostics.jl:683`; raised `src/build.jl:633` | `test_diagnostics.jl:311` | both admissible forms are a constant, carried in the message; fail-fast |
| `BundleFieldError` | absent | — | no test | see 4.3 |
| `HandlerReturnKey` | accurate | `src/diagnostics.jl:695`; raised `src/build.jl` handler pass | `test_diagnostics.jl:312` | payload full; fail-fast |
| `UserCodeFraming` | absent | — | no test | see 4.2 |

### 3.8 Appendix C — deployment, periphery and services, 28 rows

| kind | verdict | location | test | note |
|---|---|---|---|---|
| `MissingInit` | accurate | `src/diagnostics.jl:712`; raised `src/sim.jl:300`, `:1522` | `test_lifecycle.jl` | fail-fast |
| `ServiceLifecycle` | short | `src/diagnostics.jl:721`; 13 sites | `test_diagnostics.jl:316-319` | `legal` is left empty at most sites; `linearize` has no code to be an op of |
| `StopFaceInvalid` | short | `src/diagnostics.jl:750`; raised `src/sim.jl:207-219` | `test_lifecycle.jl:126` | payload lacks the binding site (constructor or `run!`); collected over the given faces, correct |
| `DeploymentInvalid` | short | `src/diagnostics.jl:767`; raised `src/sim.jl:130-158`, `src/build.jl:702-772` | `test_build.jl`, `test_lifecycle.jl` | every parameter of the column is covered (`:method` is the algorithm); two grid arms (`build.jl:749,752`) throw fail-fast where the column says collected |
| `AttachUnknownFace` | short | `src/diagnostics.jl:841`; raised `src/roster.jl:205` | `test_roster.jl` | payload names the *binding* type, not the device type; fail-fast, correct |
| `AlreadyAttached` | accurate | `src/diagnostics.jl:851`; raised `src/sim.jl:1220` | `test_roster.jl` | fail-fast |
| `CallerTaskConflict` | accurate | `src/diagnostics.jl:861`; raised `src/sim.jl:1225` | `test_roster.jl` | fail-fast |
| `ClaimConflict` | accurate | `src/diagnostics.jl:870`; raised `src/sim.jl:1234` | `test_roster.jl` | collected over the claim set |
| `EmptyGreedyClaim` | accurate | `src/diagnostics.jl:880`; raised `src/sim.jl:1250` | `test_roster.jl` | warning, `@warn logline(…)` — the `logged` policy |
| `BindingContractMismatch` | accurate | `src/diagnostics.jl:890`; raised `src/roster.jl:79-87` | `test_bindings.jl` | all nine arms present; fail-fast |
| `DeviceContractMismatch` | accurate | `src/diagnostics.jl:928`; raised `src/roster.jl:105` | `test_bindings.jl` | fail-fast |
| `ReadBindingUnresolved` | short | `src/diagnostics.jl:940`; raised `src/bindings.jl:157-186` | `test_readers.jl` | names the binding type, not the device type; the `reason` covers the source-rule discrimination; fail-fast |
| `ConditionResolution` | accurate | `src/diagnostics.jl:974`; raised `src/conditions.jl:415` etc. | `test_conditions.jl:134` | all four sub-kinds and the tier/role/producer fields present; collected |
| `DuplicateConditionLeaf` | accurate | `src/diagnostics.jl:1043`; raised `src/conditions.jl` `_check_duplicates!` | `test_conditions.jl:134` | collected |
| `ConditionNodeMisuse` | accurate | `src/diagnostics.jl:1056`; raised `src/conditions.jl:62,116` | `test_conditions.jl:129` | fail-fast |
| `UninitializedInputs` | accurate | `src/diagnostics.jl:1073`; raised `src/conditions.jl:497` | `test_conditions.jl` | every uncovered face in declaration order; collected |
| `TapResolution` | short | `src/diagnostics.jl:1084`; raised `src/trim.jl`, `src/readers.jl` | `test_trim.jl`, `test_readers.jl:77` | no arm for a declaredly-unseedable root input, so the pinning consumer's path and `input_types` entry are never carried; collected |
| `TrimProblemInvalid` | accurate | `src/diagnostics.jl:1140`; raised `src/trim.jl:390-233` | `test_trim.jl:229` | collected |
| `TrimCommitEvents` | accurate | `src/diagnostics.jl:1194`; raised `src/trim.jl:565` | `test_trim.jl` | warning, logged, duplicated in `TrimReport.fired_events` |
| `TrimCommitResiduals` | accurate | `src/diagnostics.jl:1205`; raised `src/trim.jl:576` | `test_trim.jl` | warning, logged, duplicated in `TrimReport.committed_residuals` |
| `ConditionShapeDrift` | accurate | `src/diagnostics.jl:1216`; raised `src/conditions.jl:776,779` | `test_conditions.jl` | fail-fast |
| `GridUtilization` | absent | — | no test | no site derives or reports grid utilization |
| `ReplayHeaderMismatch` | accurate | `src/diagnostics.jl:1356`; raised `src/trace.jl:331-456`, `src/sim.jl:656` | `test_trace.jl` | all five discriminators; collected (D-217) |
| `ReplaySchemaMismatch` | accurate | `src/diagnostics.jl:1397`; raised `src/trace.jl:374` | `test_trace.jl` | collected |
| `ReplayUnknownFace` | accurate | `src/diagnostics.jl:1411`; raised `src/trace.jl:395,433,448` | `test_trace.jl` | bare-position arm present (D-217); collected |
| `ArgumentInvalid` | accurate | `src/diagnostics.jl:1239`; 23 sites | `test_diagnostics.jl:440-446` | fail-fast at call sites, collected over a `TableBinding`'s entry table (`src/bindings.jl:67`); also raised at build in `sample_times` (`src/declare.jl:129-161`) |
| `ReadSetMisuse` | accurate | `src/diagnostics.jl:1321`; raised `src/readers.jl:129,233` | `test_readers.jl` | fail-fast |
| `NotAttached` | accurate | `src/diagnostics.jl:1338`; raised `src/sim.jl:1267` | `test_roster.jl` | fail-fast |

### 3.9 Appendix C — runtime, 14 rows

| kind | verdict | location | test | note |
|---|---|---|---|---|
| `StepError` | accurate | `src/diagnostics.jl:149`; built `src/sim.jl:1067` | `test_failures.jl:32-264` | all four payload facts; fail-fast at the one catch site |
| `NonfiniteState` | accurate | `src/diagnostics.jl:201`; raised `src/sim.jl:518` | `test_failures.jl:188,208` | path, leaf, value, time, boundary index; fail-fast as a `StepError` species |
| `ChatteringBudget` | accurate | `src/dataplane.jl:84`; raised `src/localization.jl:78` | `test_localization.jl` | full payload; `_report!` into the loop's cell |
| `FiringBudget` | accurate | `src/dataplane.jl:93`; raised `src/sim.jl:452` | `test_events.jl` | full payload; `_report!` |
| `DebtReanchor` | absent | — | no test | pacer absent |
| `ClaimedFaceEntry` | accurate | `src/dataplane.jl:68`; raised `src/dataplane.jl:477`, `src/roster.jl:244` | `test_dataplane.jl`, `test_roster.jl` | both sites (`:staging`, `:renormalization`); rate-limited |
| `OutOfClaimEntry` | short | `src/dataplane.jl:60`; raised `src/dataplane.jl:475,479` | `test_dataplane.jl` | no device id in the payload — attribution is the cell's, argued at `src/dataplane.jl:38-42`; otherwise full |
| `ThreadBudget` | absent | — | no test | |
| `DeviceJoinTimeout` | accurate | `src/dataplane.jl:110`; raised `src/devices.jl:448` | `test_diagnostics.jl:149` | `who`, timeout, time, boundary; written to the loop's cell and swept into the record (D-203) |
| `DeviceCrash` | short | `src/dataplane.jl:99`; raised `src/devices.jl:352,382` | `test_devices.jl` | no device id (cell attribution); `cause` and `abort` present; init-time arm present at `:382` |
| `ReplayDiscardedStaging` | short | `src/dataplane.jl:126`; raised `src/sim.jl:1403` | `test_trace.jl` | no device id (cell attribution); faces and frame present |
| `MalformedDatum` | short | `src/dataplane.jl:56`; raised `src/devices.jl:275,291` | `test_diagnostics.jl:59` | no device id (cell attribution); `cause` present |
| `EntryTypeMismatch` | short | `src/dataplane.jl:76`; raised `src/dataplane.jl:486` | `test_dataplane.jl` | no writer id (cell attribution); face, value and declared type present |
| `UnboundedRun` | absent | — | no test | no check at run start for `t_end === nothing` with empty `stop_on` |

### 3.10 Appendix C — preamble claims

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| C / 10132 | the kinds are the closed set D-058 commits to | short | `src/diagnostics.jl:23` | `test_diagnostics.jl:492` | closed, but 12 rows short of the appendix |
| C / 10139 | every row's payload is *in addition to* §13.2's requirements | short | per-kind | `test_diagnostics.jl:236` | see 4.4 |
| C / 10144 | severity takes one of two values, `error` or `warning` | accurate | `src/diagnostics.jl:38` | `test_diagnostics.jl:479-486` | |
| C / 10148 | an error occurrence throws, alone or within a collection | accurate | `src/diagnostics.jl:69` | `test_diagnostics.jl:504` | |
| C / 10150 | a warning occurrence never throws and joins no throw | accurate | `src/diagnostics.jl:107`, `src/dataplane.jl:148-156` | `test_diagnostics.jl:534` | |
| C / 10163 | the three stages: build, service, runtime | accurate | site-level | no test | not stored, correctly |
| C / 10172 | policy `collected` — gathered with its siblings and thrown as one carrier | short | `src/diagnostics.jl:69` | `test_conditions.jl:134` | honoured at the service tier; 9 build kinds throw fail-fast instead, see 4.1 |
| C / 10176 | policy `fail-fast` — the first occurrence throws on its own | accurate | many | `test_failures.jl` | |
| C / 10180 | policy `logged` — emitted at the call site through the standard logging backend, beside the returned value | accurate | `src/diagnostics.jl:107`, `src/trim.jl:565,576`, `src/sim.jl:1250` | `test_diagnostics.jl:534` | |
| C / 10186 | policy `rate-limited` — bounded per writer per boundary, a ring of sixteen plus per-kind suppressed counts | accurate | `src/dataplane.jl:224`, `:189-231` | `test_diagnostics.jl:86` | |
| C / 10194 | the build warning set is currently empty (D-084) | accurate | `src/diagnostics.jl:38` | `test_diagnostics.jl:479` | |

## 4. Deviations in detail

### 4.1 Nine collected kinds are raised fail-fast, and §13.1's own example fails

§13.1 (6955): "**These passes collect:** each returns its full violation list."
And 6993: "A wire typo'd as `:throtle` produces both a did-you-mean error … and
an unconnected-input error for the intended `throttle`; both are reported."
D-057 rejects "*Uniform fail-fast:* N build cycles for N clustered wiring
errors."

`src/assembly.jl:478-490` (`_wrong_direction`) throws a lone-diagnostic
`BuildError` for `UnknownPort` and `FaceDirectionConflict`; `src/assembly.jl:261,
280,286,311` do the same for `PathResolution`; `:421,425` for
`UnknownFaceSelection`. These sit inside `resolve_source`/`resolve_dest`, which
`_walk!` calls per wiring entry (`src/assembly.jl:713-715`), so the first bad
wire aborts the walk before the obligation pass at `:641` ever runs. Separately,
`src/assembly.jl:44,48` (`classify`), `src/assembly.jl:156` (`children`) and
`src/build.jl:77,81,96` (`classify_tier`) each throw per component, so a model
with two offending leaves reports one.

Probe `p2` builds a two-child assembly whose one wire is typo'd, leaving two
inputs unfed. Result: `BuildError` with `n = 1`, kind `UnknownPort`. The unfed
`throttle` and `other` are not reported. Probe `p1` builds two leaves each
declaring `init_x` with no update law. Result: `BuildError` with `n = 1`, kind
`StoreWithoutUpdate`.

Why it matters: this is exactly the N-build-cycles cost D-057 was decided
against. It also silently changes what an acceptance test can assert — a test
written against §13.1's worked example would fail on the count.

### 4.2 `UserCodeFraming` is absent, so a probe failure has no frame

§13.2 (7050): "A user-code exception is wrapped in a framing diagnostic —
component path, which function, the probe context including synthesized inputs —
with the original exception as `cause`. The didactic frame therefore renders
first and the raw throw second."

There is no `try` anywhere in `src/build.jl`, and no `UserCodeFraming` type. A
component whose `output_state` throws during stage-1 probing propagates that
exception raw out of `build`, naming no path, no function and no synthesized
inputs. The runtime counterpart (`StepError`, `src/sim.jl:1067`) is built and
tested; the build counterpart is not. `test/test_failures.jl:169` even remarks
that a runtime throw must not lose its cause — the same care is absent at build.

### 4.3 `BundleFieldError` is absent, so §5.2's bundle-law did-you-mean does not exist

§13.2 (7055): "One class is recognized rather than merely framed. A `FieldError`
carries its type and field as data. Matched against the bundle's own NamedTuple
type … it becomes the bundle-law did-you-mean (§5.2), carrying the legal set and
the undeclared-store / wrong-tier / illegal-for-this-function classification."

`grep -rn FieldError src/` returns nothing. `src/executor.jl:105-119`
(`_bundle_expr`) builds the bundle from the compile-time name set `BN` and the
comment at `:99` states the intent — "a body destructuring what it does not own
fails at the destructuring (§5.2)" — but nothing recognizes that failure. At
build the raw error escapes unframed (4.2); at runtime it reaches
`_wrap_step` and rides inside a `StepError` as an unclassified cause. The legal
field set, which the executor holds in `BN`, is never shown to the author.

### 4.4 A model type in a payload, against §13.2's rendering doctrine

§13.2 (7068): "**Strings, never instances.** Diagnostics carry paths and names as
strings, never component instances and never model types — the
`compact_backtrace` lesson. Expected/observed *port* types are the payload
exception."

`src/diagnostics.jl:360` declares `EventHalfMissing.found::Any`, documented as
"the component type, or the entry's type", and `src/build.jl:411` raises it with
`found = typeof(c)`. `message` interpolates it directly
(`src/diagnostics.jl:367`): "event `$(d.event)`'s $(d.reason) has no method for
$(d.found)". For a parameterized component this renders the full type, which is
the failure mode the doctrine names. The file already has the remedy one screen
up: `_typename` at `src/diagnostics.jl:29`, used by `TransparentContainerUnknown`,
`AlreadyAttached` and others.

### 4.5 The generic-holding rule has no code, in either register that needs it

§13.3 (7159): "the walk follows *declared field types* alongside instances, and a
segment that traverses **past** a generically-held field — one whose declared
type is non-concrete — is a diagnostic even though the concrete instance in hand
would resolve it."

`_one_level` (`src/assembly.jl:274-290`) resolves through `children(base, asm)`,
which walks *instances* via `getfield` (`src/assembly.jl:115-150`). No declared
field type is ever consulted, and `isconcretetype` appears nowhere in `src/`.
In the structural register this is harmless and the spec says so (the one-level
rule stops the walk first), which is why `PathResolution`'s `reason` vocabulary
has no arm for it. The load-bearing register is the one that needs it: condition
entries, trim `reads` and taps resolve against `b.flat.paths`, the *compiled*
absolute paths of the flattened instance tree (`src/conditions.jl:258-330`), so a
deep read past a generically-held field resolves silently. §13.3 (7194) says the
strictness exists because "a wire reaching past one would fail at substitution
time, at a different site" — that non-local failure is available today through a
condition, a trim read or a tap.

### 4.6 No runtime conformance check, so `ConformanceFailure`'s runtime half is unreachable

§13.4 (7257): "Conformance failure (§9.5) needs no separate path. It is thrown as
its typed diagnostic at the table-write point, and it arrives at the same catch
site. There it is a species of `StepError` carrying the field-diff payload."
Appendix C's row for it reads "build, at probe; runtime thereafter".

All fifteen `ConformanceFailure(` constructions in `src/` are in `src/build.jl`.
The table-write point is `scatter_group!` (`src/store.jl:81-88`), a generated
function that does `getfield(y, name)` per declared port with no check. A stage
whose return drifts at runtime produces a raw Julia error, wrapped by
`_wrap_step` into a `StepError` whose cause is untyped. The *species* mechanism
is real and correct (`_species`, `src/sim.jl:1082-1084`, exercised for
`NonfiniteState`), so what is missing is the check, not the plumbing. The
payload's "simulation time" is likewise not a field; at runtime the carrier's
`t` would supply it.

### 4.7 No component library, no `Build` printer

§13.7 (7548): "**The `Build` printer owes face provenance.** For every root face,
that means the resolved chain down to the producing terminal." There is no
`Base.show` method for `Build` anywhere in `src/`; `grep -n "function Base.show"
src/*.jl` returns only the two `showerror` methods in `src/diagnostics.jl`. The
data is available — `flat.out_faces` maps `(path, face)` to its producing
terminal — but nothing renders it.

§13.7 (7558): the starting inventory is "wrench/scalar summing junctions, the
Bool gates the termination chains use, `UnitDelay` … and `Constant{V}`". None
exists. `Group` (`src/assembly.jl:209`) is the one library member built, and it
is the member admitted by persona rather than by demonstrated need. The
consequence reaches §13.7's rig: the rig is spelled with a
`Constant{SampleTerrainField}` stub child, so the abstract-entry isolation idiom
cannot be written today. The spec calls the library "a migration-phase
deliverable", so this is deferral on the record rather than drift.

### 4.8 `IllegalStateLeaf` absent: an illegal state leaf dies as a `MethodError`

Appendix C's row: "`IllegalStateLeaf` | component path, `init_x` field name, leaf
type, the closed vocabulary (scalar / `SArray` at the common eltype)". The name
survives only in a docstring at `src/diagnostics.jl:564` ("the port twin of
`IllegalStateLeaf`"), and `IllegalPortType` (`src/build.jl:278`) checks the port
side alone.

Probe `p3` declares `init_x(::BadLeaf) = (q = [1.0, 2.0],)` — a `Vector`, outside
the closed vocabulary — with a matching `state_derivative`. `build` throws a bare
`MethodError`, with no component path, no field name and no vocabulary. That is
the error-locality inversion §8.4 designs out of the build tier, reintroduced at
the one place a leaf's shape is first read.

## 5. Tally

| verdict | count |
|---|---|
| accurate | 127 |
| short | 44 |
| stand-in | 1 |
| absent | 27 |
| n/a | 5 |
| **total** | **204** |

Breakdown by table: §13.1 prose 7 rows; §13.2 prose 28; §13.3 prose 13; §13.4
prose 24; §13.5–§13.7 prose 43; Appendix C Stratum A 26; Strata B/C 10; services
28; runtime 14; Appendix C preamble 11.

Of the 27 absent rows, twelve are Appendix C kinds with no code
(`WalkingFaceAtFrozenEntry`, `AbstractAtRoot`, `IllegalStateLeaf`,
`TierSignatureMismatch`, `MissingProbeValue`, `DeadStage`, `BundleFieldError`,
`UserCodeFraming`, `GridUtilization`, `DebtReanchor`, `ThreadBudget`,
`UnboundedRun`). Six are §13.7's unbuilt library and rig; three are §13.2's
restatement of the three unbuilt runtime warnings; the remaining six are
§13.1's no-cascade-suppression example, §13.2's framing diagnostic and
`FieldError` recognition, §13.3's generic-holding rule, §13.4's interactive
branch, and §13.7's predicate filter and `Build` printer.

The 44 short rows cluster in two families: about fifteen Appendix C payloads
missing one variable field, and nine Appendix C kinds whose *collected* policy is
implemented fail-fast (4.1).

## 6. Friction

- **"Collected" is not defined at a scope.** §13.1 says a pass returns its full
  violation list and the *stratum* barrier throws; Appendix C's policy column
  says "gathered with its siblings and thrown as one carrier". The
  implementation collects at three different scopes — per component
  (`children`, `classify_tier`), per pass (`_check_event_declarations`,
  `flatten`'s obligation pass) and per stratum (nowhere). I judged every
  build-tier kind against the stratum reading, because that is what
  §13.1's typo'd-wire example requires, but a reader could defend the
  per-pass reading for `classify_tier` and `children`. The rows carrying
  "rejected D-057" are the ones where the example itself settles it.

- **Payload vs. message is undecidable for constants.** Appendix C lists facts
  like "the closed vocabulary", "both admissible forms" and "both remedies in
  the message" in the payload column, while §13.2 says messages are pure
  presentation and tests match on payload. I ruled that a *constant* stated in
  the message satisfies the column (`IllegalPortType`, `GuardForm`) and a
  *variable* fact that is not a field does not (`TransparentContainerUnknown`'s
  list-in-hand, `TwoProducers`' producer terminals). The appendix could say
  which column a constant belongs in.

- **Writer attribution.** Five runtime kinds are marked short for lacking the
  device/writer id their Appendix C rows name. `src/dataplane.jl:38-42` argues
  the omission well — the channel is per-writer, so the cell supplies it — and
  the argument is probably right. The appendix has not been amended, so I
  reported the gap; it may be a spec fix rather than a code fix.

- **`test/test_diagnostics.jl:492`'s closure test reads stronger than it is.**
  `Set(typeof.(occurrences)) == Set(subtypes(Diagnostic))` guarantees every
  *implemented* kind has an occurrence and a rendering. Its testset name is
  "diagnostic kinds (§13.2, Appendix C, D-214, D-215)", which promises coverage
  of Appendix C; twelve appendix rows are missing with the suite green.

- **`resolve`'s spec sentence and its code disagree in scope.** §13.3 (7141)
  defines `resolve` as "the getfield walk along `/`-segments" with no depth
  limit, then assigns the one-level rule to the structural register in the
  table below. `src/assembly.jl:308` enforces one level unconditionally. Two
  readings fit: `resolve` is the structural register's primitive (code's
  reading), or `resolve` is register-neutral and the diagnostic register wants a
  deep variant. The diagnostic register in fact uses `Layout`-based address
  lookup instead of `resolve` at all, so nothing breaks; I marked the row
  accurate and the register-table row for load-bearing short.
