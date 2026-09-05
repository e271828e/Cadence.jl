# The audit against the register

Coordinator's merge of the nine slice reports in this directory, diffed
against `docs/design/pending.md`, the file no agent was allowed to read. Tip
`70672d1`, 2026-09-05. The three `v*_*.md` files are the verification round:
every claim in section B below that carries a `v` mark was re-checked by a
cold Opus verifier with its own probes, and the mark says what it found.

## Tally

| agent | slice | accurate | short | stand-in | absent | n/a | rows |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A | §1–§7 | 129 | 10 | 2 | 22 | 32 | 195 |
| B | §8 | 97 | 11 | 4 | 8 | 21 | 141 |
| C | §9 | 133 | 21 | 5 | 29 | 14 | 202 |
| D | §10 | 165 | 2 | 0 | 14 | 23 | 204 |
| E | §11 | 153 | 6 | 2 | 24 | 23 | 208 |
| F | §12 | 146 | 5 | 4 | 20 | 18 | 193 |
| G | §13 + App. C | 127 | 44 | 1 | 27 | 5 | 204 |
| H | §14 | 164 | 8 | 0 | 23 | 18 | 213 |
| I | App. A + B | 126 | 7 | 4 | 18 | 2 | 157 |
| | **total** | **1240** | **114** | **22** | **185** | **156** | **1717** |

Of the 78 Appendix C kinds, 66 exist and 12 do not. One agent (C) read about
ten lines into `implementation.md`'s caveats through a grep context window;
nothing in its report depends on them. No agent opened `pending.md`.

The absences cluster in five unbuilt features, and most of the 185 absent
rows are those features spread over their sentences: §10.7 pacing with its
§11.8/§12.2 diagnostics, §11.7's GUI write path with the `gui` flag and the
shipped greedy binding, §12's pause and operator-interrupt masking, §14.9
mounting and §14.10 linearization with the NLopt fallback, and §5.6's
feedthrough tracer. All five are in the register. What follows is where the
register is wrong or silent.

## A. Contradicts something the register asserts

**A1. The first-violation list is incomplete.** `pending.md` 27–33 names six
kinds reached fail-fast where Appendix C reads `collected`. Verifier 3's
sweep of every raising site (`v3_errors_api.md` §1, correcting agent G's
count) finds eleven kinds with at least one site that throws a lone
`BuildError` with nothing gathered: the register's six plus `ClassMixed`
(`assembly.jl:44`), `UnknownFaceSelection` (`assembly.jl:421,425`),
`WireTypeMismatch` (`build.jl:1033`), `ProducedByTwoStages` (`build.jl:517`)
and `DeploymentInvalid`, whose `bind_schedule` has nine lone-throwing arms
(`build.jl:702–752`) against a `collected` column. A second, weaker
population collects within one component and throws before the next:
`DeclarationOnWrongTier(:tier_form)` (`build.jl:96`), `ContainerMixed`,
`ChildNameCollision` and `TransparentContainerUnknown` (all at
`assembly.jl:156`). `FaceNameCollision` and `RootInputTypeConflict` conform.
The probe behind it: a two-child assembly with one typo'd wire leaving two
inputs unfed reports the `UnknownPort` alone, so §13.1 6993's own worked
example (did-you-mean plus both unconnected inputs) does not hold, which is
the "uniform fail-fast" D-057 rejects. G also finds `classify_tier` called
from inside the wiring walk (`assembly.jl:705`), so an unreadable tier aborts
the walk before Stratum A's barrier. _v3.1: CONFIRMED in substance, counts
corrected as above._

**A2. "Candidate lists are carried and rendered" holds per arm, not per
kind.** `pending.md` 22–25 says the lists are carried and only the ranking is
absent, with a mistyped *path* the one exception. Agent E (4.3) finds
`ReadBindingUnresolved` fills `candidates` on one arm of three: the
`get_input` miss carries the list, the `get_output` (`:unknown_cell`) and
`get_face` (`:unknown_output_face`) misses carry none. Those are name misses,
not path misses. Agent H (4.4) finds the same hole on `ConditionResolution`'s
`:unknown_path` arm and in `_read_component`. The previous pass reported this
at tip 2c02afb; it is still not in the register.

**A3. Docstrings that state the spec's shape over code that does not
produce it.** Not register text, but the same rule ("nothing deviates
silently") applies, and each one cost an agent a probe:

- `diagnostics.jl:580–582` describes `AlgebraicCycle.members` as "the SCC's
  member terminals, in slash form"; `build.jl:246` passes the whole
  topological residue as component paths (A 4.9, C 4.9).
- `localization.jl:178` attributes the segment-relative stopping rule to
  D-133; D-133 and §10.4 state it relative to the frame (D 4.2).
- `sim.jl:874` says `t_end` is "taken to the nearest frame top", which is
  what the code does and not what §12.4 says (F 4.2).
- `declare.jl:26` says `init_s` takes "any isbits type, pinned wholesale";
  §7.3 says any immutable value under the frozen-reference rule, and requires
  a mutable RNG state to live there (A friction).
- `build.jl:429–434`'s docstring says the torn-state guarantee is met "by
  having none", while §9.2 promises concurrent `Simulation`s over one
  `Build` (C 4.10).

## B. Deviations the register does not record

Ordered by consequence. A `v` mark names the verifier entry and its verdict.

**B1. `t_end` lands on the nearest frame, not the first frame reaching it.**
`run!`, `step!` and `replay!` compute the target as `round(Int, t_end/h)`
(`sim.jl:793,891,1136`) where §12.4 6335 and Appendix B 9916 say the first
grid boundary at or past `t_end`. `t_end = 0.54` at `h = 1/10` ends at
`t = 0.5` reporting `EndTimeReached`. Every suite `t_end` is grid-aligned, so
nothing catches it. Found by F and I independently, and by the previous pass
at 2c02afb: ten commits later it is unfixed and unrecorded. _v2.1:
CONFIRMED, and enlarged: the target frame also ignores the start time.
`t_end_frame` is compared against `clock.step`, which `_open_trajectory!`
resets to 0, so `init!(sim; t0 = 10.0)` then `run!(sim; t_end = 12.0)` runs
to t = 22. No report caught this; the verifier did._

**B2. The D-168 fan-out meet is not implemented.** `_root_input_type`
(`build.jl:318–332`) takes the first consumer's entry in flatten order, so a
root input fanned into a `T` entry and a `Float64` entry pins or walks by
field declaration order. In the walking order the build delivers `Dual`s to
the pinned entry, which D-168 records as the rejected join, and the message
blames the pinned consumer. D-168's legitimate configuration, the FFI door
beside a promoting leaf, is refused (B 4.3). _v1.4: CONFIRMED, and D-168
names the join as rejected._

**B3. The nominal bound check is equality-modulo-embedding, not `<:`.**
`_accepts` (`build.jl:179–190`) has no subtype arm, so a component-fed entry
declared abstract (`Real`, or `AbstractTerrainField`) refuses its lawful
concrete producer with `WireTypeMismatch`. §4.4's substitutability idiom and
§8.2's "abstract reference-typed entries stand as they always were" have no
code. Abstract at root: a `Real` entry reaches `probe_value` and is refused
blaming a synthesized `Int64`; an abstract struct entry throws a raw
`ArgumentError` from `leaf_types` before any diagnostic (A 4.4, B 4.5,
C 4.1). `AbstractAtRoot` itself is in the register; the general check is
not. _v1.3: CONFIRMED; both root cases hold, split on `P <: Real`._

**B4. The runtime table write converts, the shape D-053 rejects.** The
register records §9.5's always-on check as absent. It does not record what
stands in its place: `scatter_group!` fetches declared names by `getfield`
and `scatter!` writes `buf[i] = v`, so an `Int64` returned where `T` was
declared is converted to `1.0`, an extra field is silently dropped, and a
missing field is a raw `FieldError` inside a `StepError` (C 4.11, B 4.8).
_v1.6: CONFIRMED, and D-053 names convert-on-write as rejected._

**B5. `AlgebraicCycle` reports the raw stall residue, the shape D-012
rejects.** The register records the missing wires and classification. It does
not record that `members` is every component Kahn's algorithm could not
place, including acyclic components downstream of the cycle, as component
paths rather than terminals in loop order, with two disjoint cycles merged
into one diagnostic (A 4.9, C 4.9). `test_build.jl:59` asserts the current
shape. _v1.7: CONFIRMED with one correction: the order is flatten index, not
alphabetical (`sort!` runs on component indices). D-012 names the raw residue
as rejected._

**B6. Derivative and projection conformance is checked by leaf count, not
shape at `T`.** `_check_derivative` and `_check_state_write` compare
`nleaves` per field, so an `Int64` derivative leaf for a `Float64` state, or
an `SVector{3,Int64}` for an `SVector{3,Float64}`, passes and is converted on
the way into the buffer (A 4.12, C 4.16). §7.1 1306–1313 and §9.5 3424 state
the predicate as shape at `T`. _v1.5: CONFIRMED._

**B7. Enum-valued ports are refused.** `leaf_types` returns empty for an
`Enum`, so `place!` raises `IllegalPortType`; `probe_value` has no enum arm
(A 4.1, C 4.13). §4.1 lists enums among legal port values and §7.5 names
publishing a mode as the remedy for the missing event stream. _v1.1:
CONFIRMED._

**B8. Reference-carrying signals build and then crash at the first gather.**
`leaf_types` walks `fieldtypes` into a `Vector`'s internals, so a port type
carrying a bulk-data reference (§4.4's handle pattern) passes `place!`,
constructs a `Simulation`, and dies in generated code with a raw
`MethodError` on the first read (A 4.2). Neither supported nor refused.
_v1.2: CONFIRMED._

**B9. The state-leaf vocabulary: what the absence admits.** `IllegalStateLeaf`
is in the register. Not recorded: `reconstruct` emits `Expr(:call, P, …)`,
so an invariant-carrying leaf's normalizing constructor runs on every view
materialization, the projection-on-read D-094 names as rejected; and an `Int`
or `Bool` leaf in `init_x` builds and silently becomes `Float64` in every
bundle (A 4.11, B 4.6). _v1.12: CONFIRMED, and D-094 names constructor-on-read
as rejected._

**B10. Containers of containers are silently dropped.** A tuple of tuples of
components takes `_children`'s "inert data" branch (`assembly.jl:122`); the
build succeeds with `flat.paths` empty and three declared components gone
(B 4.7). §8.5 2382 says such containers are rejected. _v1.8: CONFIRMED._

**B11. Deployment validation runs under three barriers.** `Simulation`
collects keyword-range violations and throws; then `bind_schedule`'s first
five checks each throw on the spot; then the anchor loop collects (C 4.5).
§9.1 3027 says collected like its declarative siblings; the suite asserts
each case in isolation. _v1.9: CONFIRMED._

**B12. The device wrapper files the `unblock!`-provoked raise as a
`DeviceCrash`.** §12.4(3) 6273 says the framework wrapper treats that raise
as shutdown. `_wrap` (`devices.jl:348–358`) catches everything uniformly, so
a conforming device whose `unblock!` closes its channel produces a warning
and a `DeviceCrash` residue on every clean run; the suite's `Blocked` fixture
does the discrimination itself (F 4.1). The register's neighbouring edge, the
`InterruptException` in a device loop, is the same catch. _v2.3, v2.4:
CONFIRMED by probe._

**B13. The interrupt carve-out bypasses the stop word.** The register records
that masking is absent and the stores can be left mid-boundary. It does not
record that `sim.jl:1058` returns `ControlRequestedStop(:interrupt)` without
`_request_stop!`, so an interrupt arriving after another issuer won the
first-writer-wins CAS reports `:interrupt` as the source (F 4.3). _v2.5:
CONFIRMED by probe: stop word `:code`, record `ControlRequestedStop(:interrupt)`;
`_advance!` alone decides the source and never re-reads the word._

**B14. A model type in a payload.** `EventHalfMissing.found` is filled with
`typeof(c)` and interpolated into the message, against §13.2 7068's "never
model types"; `_typename` is one screen up (G 4.4). _v3.2: CONFIRMED; the
doctrine sentence is at 7051._

**B15. The activation cache is an unguarded `get!`.** §9.4 3337 makes
torn-state-free lazy materialization normative and §9.2 3063 promises one
`Build` behind many concurrent `Simulation`s (C 4.10). _v1.10: CONFIRMED._

**B16. Walkthrough 5 delivers one of its two diagnostics.** A typo'd return
field raises `UndeclaredReturnField` from `_check_ports` before the
`DeclaredNotProduced` pass runs, so the author learns of the unproduced port
on the next build (B 4.10). _v1.11: CONFIRMED._

**B17. Two `DeclarationOnWrongTier` shortfalls.** The message names the two
tiers rather than the two forms §8.5 2511 asks for, and `classify_tier`
throws at the first offending component (B 4.9). _v3.9: CONFIRMED by a
two-component probe; the `:continuous_only`/`:no_manifold` arms at
`build.jl:562,567` collect model-wide._

**B18. The heartbeat is read at publication, not at the drain.** `drain!`
never touches `_heartbeat`; `_status` acquire-loads it from `publish!`, and a
`t*` boundary publishes without a drain (E 4.2). Nothing observable breaks;
the reading site is not the one §11.8 6003 fixes. _v2.6: CONFIRMED; the
drain-less `t*` publication is at `localization.jl:144–145`, and §11.2's
sentence is at 4862–4863._

**B19. `ServiceLifecycle.legal` is empty at three of four sites.** Only
`capture` fills it; `init!`, `trim!` and `replay!` construct the kind with
`op` and `status` alone (H 4.2). The rendered text does not suffer; the
structured payload does. _v3.3: CONFIRMED over all eleven sites._

**B20. `phase_bodies` returns four bodies.** Guards, handlers and
`state_projection` callables live on `Executor.events` and are reachable only
through the private field, unkeyed (C 4.17, I 4.15); §9.7 3628 and Appendix B
10093 say they are returned with the four blocks. _v1.13: CONFIRMED;
`bodies` is built at `build.jl:1006–1009`._

**B21. Auto-publication is an active refusal, not a quiet absence.** The
register lists auto-published ports as unbuilt. It does not say that the
shape is a `DeclaredNotProduced` build error, so §8.2's own worked `Engine`
(whose `output_types` declares the state field `ω`) does not build, and three
clauses elsewhere (the bundle law's `y` row, D-169's hand-down exclusion,
§7.1's state-cell table) are correct but vacuous (A 4.5, B 4.2, I 4.5).

**B22. The standard component library is absent and unrecorded.** §13.7
7558's inventory (`SumJunction{W,N}`, the Bool gates, `Or{N}`, `UnitDelay{V}`,
`Constant{V}`) and the §13.7 rig, plus §6.2's `SumJunction` and `Constant`
spellings, have no code (A, G 4.7). `implementation.md` says the old
`library.jl` became fixtures; `pending.md` does not list the library, and the
spec calls it a migration-phase deliverable, so this may belong in the
register as a deferral rather than a gap.

**B23. Nothing is exported, and three surface names do not exist.**
`names(Cadence) == [:Cadence]`; there is no `condition` generic (two model
packages defining it would define two functions, breaking §14.2's pull
composition); `ProbeDual` and `ProbeTag` are not names; there is no `check`
entry (I 4.3, 4.4, 4.7, C 4.15). Whether "exported" is normative is a
spec-side question (section D). _v3.8: CONFIRMED by probe._

**B24. The stepper keyword is `method = RK4`, a type; Appendix B and six
other spec sites spell `algorithm = RK4()`.** The trace's deployment block
records `method::Symbol`, so the name has reached the replay comparison
surface (I 4.9). No decision found ratifying the spelling. _v3.5: CONFIRMED;
the validation is at `sim.jl:137–138`, and no decision ratifies `method`._

**B25. The shadowing check (§8.1 1725) is absent.** This is the
forgotten-import diagnostic in the project's queue and a caveat in
`implementation.md`, and it is not in `pending.md` (B 4.1).

**B26. Smaller unrecorded items.**

- No `sizehint!` anywhere; the log is a `Vector` of snapshot references, each
  a fresh buffer copy, not inline records (A 4.13, E). _v2.8: CONFIRMED._
- The roster is a mutable `Vector` re-read every frame; the freeze is
  `assert_stopped`'s policy, not immutability (E 4.4). _v2.7: CONFIRMED._
- Device-side diagnostics go through the internal `_report!(cell, d)`; no
  `report!(entry, d)` addressed by roster entry exists (F). _v2.9: CONFIRMED;
  the only methods are `report!(::DeviceHandle, ::MalformedDatum)` and
  `_report!(::DiagCell, ::DiagValue)`._
- Localization stops at `tol·h′` over the current segment, tighter than the
  `tol·h` §10.4 and D-133 state, on remainder segments only (D 4.2; scored
  accurate by D, listed here for the docstring in A3). _v2.2: CONFIRMED;
  D-133 and §10.4 both say `tol·h`, the docstring misattributes._
- `capture`, the trace header and the compiled `Reader` are three separate
  walks over the same stores, sharing only `gather` on root inputs, against
  §14.1 7712 and §14.4 8028's "one mechanism" (H 4.3). _v3.7: CONFIRMED._
- The suite has no every-component `Dual` sweep; D-166's CI policy is one
  fixture (B, C 4.15).
- §13.4 7289's interactive-session behaviour (log and surface the status
  rather than rethrow) has no discrimination in `run!` (G).
- The face table keeps the resolved endpoint only; the routing chain §9.1
  2882 and §13.7's printer call provenance is discarded in `resolve_source`'s
  tail recursion (C 4.7).
- Every `Build` and schedule artifact is data with no `show`: no anchor
  table, no `A₀` row, no rate-scope rows, no hyperperiod chart, no derivation
  line (C 4.6, I 4.6). D-187's diagnostics are in the register; the printers
  are only implied by "the bound schedule is plain data".
- The termination record does not say whether the bound that fired was the
  constructor's or `run!`'s override (I 4.14). _v3.6: CORRECTED: the fact
  holds, but §13.5 7382 gives `EndTimeReached` no payload, so no distinction
  is required. Not a deviation._
- `Snapshot.boundary` is stamped from the control plane's counter, which
  `init!` never resets, so a second trajectory opens at the first one's
  count; the field's comment says "boundary zero = 0" (F friction). Needs a
  ruling more than a fix.

## C. Recorded and re-found

Every `pending.md` item was independently reached by at least one agent, with
one exception noted at the end. The list, by register bullet:

- **Absent kinds** (11): all twelve Appendix C absences G counts are the
  register's ten plus `GridUtilization` and `DebtReanchor`, which the register
  names under D-187 and §11.8 rather than in the kind bullet. `TapResolution`
  from the read register alone: H. The `bindings.jl` plain `error` and the
  two `DeviceContractMismatch` neighbours: E. Did-you-mean ranking absent:
  B, E, H. The maxlog renderer: E 4.7.
- **First-violation refusals** (six kinds): G, with the additions in A1.
- **Payload shortfalls**: G's Appendix C table reproduces every line of the
  register's enumeration and adds `TwoProducers` (producer terminals only
  inside provenance strings), `OutOfClaimEntry`/`DeviceCrash`/
  `ReplayDiscardedStaging`/`MalformedDatum`/`EntryTypeMismatch` (no writer
  id, argued at `dataplane.jl:38–42`), `AttachUnknownFace`/
  `ReadBindingUnresolved` (binding type where the column says device type),
  `PathResolution` (no generic-holding arm), and `ServiceLifecycle` (B19).
  Verifier 3 read the columns for the id and type claims. _v3.4: CONFIRMED._
- **§9.5 always-on check**: B 4.8, C 4.11, G 4.6. **§8.3 visibility**: B.
  **Auto-published ports**: A, B, C, I (B21). **§13.3 generic holding in the
  load-bearing register**: G 4.5, I 4.8.
- **§8.8 beyond the helper pair**: B. D-209's predicate filter on the
  passthrough helpers, which G lists absent, is not in the bullet's three
  items. **D-187 grid diagnostics**: C 4.4 in full.
- **§14**: `linearize`, mounting, NLopt, the tap register: H 4.1, 4.5, I
  4.12, 4.13. Sub-port-field addressing: A 4.3. Index addressing in the
  binding register: not reached by any agent; the one register item with no
  independent confirmation.
- **§11.7, §10.7, §11.8 remainder**: E 4.6, D 4.1, E 4.1, F 4.4, 4.6. The
  two unguarded edges: E 4.5 for the interrupt; the detached-handle staging
  edge was not reached by any agent.
- **§12**: pause, the control-plane surface, the interrupt masking and
  entry, `run!`'s finite `t_end`, attach/detach on every non-running state:
  F 4.3, 4.6, I 4.10, G, I friction.
- **The stand-in row**: E 4.8 measures it at 432 B per quiet boundary on a
  two-writer roster.
- **The species rule and boundary zero outside the catch**: G 4.6 confirms
  the species mechanism; no agent disputed either reading.
- **§14.2's stack-only construction caveat**: H did not reach it.

## D. Findings that read as spec-side

Where the code's shape is coherent and the spec may be what moves. Each is
the user's call; the audit only lists them.

- **"Exported."** Nothing is, and the whole suite works by qualified import.
  The spec uses the word normatively in three places (§4.4, §9.4, Appendix
  B's title).
- **`method = RK4` vs `algorithm = RK4()`.** A type versus an instance, and a
  different name, already in the trace header.
- **`t_end = Inf` as the interactive default.** The code refuses `Inf` and
  demands a bound from some site; Appendix B's two following sentences (the
  unbounded-run warning, `log_max` as the memory bound) describe a mode the
  package refuses to enter.
- **Writer ids in the periphery kinds.** `dataplane.jl:38–42` argues the
  cell attributes the writer; Appendix C's columns were not amended.
- **"Printable."** Four of C's short rows become accurate if §9.2's "plain
  printable data" means inspectable rather than rendered.
- **"Collected" has no stated scope.** G judged every build kind at the
  stratum scope because §13.1's worked example requires it; the code collects
  per component, per pass and never per stratum.
- **The component library** is a migration-phase deliverable by the spec's
  own words and absent from both registers.
- **Prose that does not match the mechanism it describes, with the code
  right** (D friction): §10.5 4187's "the gate's image of the frame index" is
  wrong for `n > 1`; D-133 calls `localization_budget` `event_budget`; §10.6
  4584's "exhaustion emits a `FiringBudget` warning" admits a reading the
  code does not take; §10.4 3986's "in declaration order within the
  iteration" needs §10.6's one-per-component rule to be true.
- **`init_s`'s vocabulary.** The docstring says isbits, the spec says any
  immutable under the frozen-reference rule; the code enforces neither.
- **`attach!` on an errored sim.** The docstring calls it deliberate
  (post-mortem); Appendix B 9979 lists three legal states without it.

## E. Friction worth acting on

- **The shared scratchpad.** Two agents had a probe file overwritten by
  another agent's same-named file between write and run. The next brief
  should assign a subdirectory per agent.
- **`test/fixtures.jl` cannot be loaded outside `CadenceTests`.** It reads
  the framework's names from `Main`, and the test module needs
  `BenchmarkTools`, which `--project=.` does not have. A self-importing
  fixtures file or a documented probe preamble would have saved four attempts
  per agent.
- **Test names that promise more than they check**: `test_lifecycle.jl:94`
  (grid-aligned `t_end` only), `test_devices.jl:76–83` ("a clean exit" with
  the discrimination in the fixture), `test_dataplane.jl:174–180` (the
  populated drain runs with `trace = false`), `test_diagnostics.jl:492`
  (closure over implemented kinds, named after Appendix C),
  `test_executor.jl`'s allocation assertions (vacuous for §9.5),
  `test_build.jl:59` (asserts the residue shape).
- **Absences with no footprint.** §11.7 and §5.6 leave no marker in `src/`;
  every other gap announces itself in a header comment. One line each in
  `dataplane.jl`'s and `build.jl`'s headers would make them a five-second
  check.
- **Slice seams.** §8.2 and §6.1 both state the wiring clauses; §5.6 and §9.4
  both own the cycle classifier; §9.5 splits into a mechanism and a predicate
  list. Three pairs of reports overlap there and agree.
