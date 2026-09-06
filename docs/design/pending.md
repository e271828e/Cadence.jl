# Pending against the spec

What `src/` and `test/` still owe the design: the constructs not yet built,
the ones built in a shape the spec's is not, and the ones awaiting a ruling.
Every item here is known and recorded; none is abandoned. `check_refs.jl` and
`check_rows.jl` read this file, so every `§N` and `D-nnn` below resolves or
the tools go red.

The 2026-09-04 conformance audit (`docs/reports/20260904_conformance/`, tip
`70672d1`) is folded in. Its merge, `01_merge.md`, is cited as `M-A1`, `M-B3`
and so on; the entry carries the argument, the probe and the line numbers at
that tip. The reports are frozen evidence; this file is the register.

## Not yet built

Where the reason is not given here, the cited decision carries it:

- **The Appendix C kinds whose mechanism is absent** — an absence gets no
  struct (`ThreadBudget`, `DeadStage`, `BundleFieldError`, `UserCodeFraming`,
  `UnboundedRun`; likewise `IllegalStateLeaf`, `MissingProbeValue`,
  `AbstractAtRoot`, `TierSignatureMismatch` and `WalkingFaceAtFrozenEntry`,
  whose *checks* are absent; `TapResolution` comes from the read register
  alone, never §14.10's absent tap register). One periphery refusal is still
  a plain `error(...)` with no kind — a datum naming no channel of a
  `TableBinding` (`bindings.jl` ~93): it runs on the device task inside the
  author's own mapping and reaches the framework as a `DeviceCrash` `cause`,
  so D-216 leaves it there. Its two former neighbours are
  `DeviceContractMismatch` now — a device defining no `loop`, and `gather` on
  a handle whose binding declares no output side. Absent with them:
  did-you-mean **ranking** (no list is ever ordered), and the lists
  themselves on some arms — `ReadBindingUnresolved` fills `candidates` on the
  `get_input` miss only, `ConditionResolution`'s `:unknown_path` arm and
  `_read_component` carry none, and a mistyped *path* gets none anywhere
  (M-A2); and §11.8's maxlog renderer (count-only display past 25 cumulative
  occurrences per writer × kind).
- **First-violation refusals where the kinds' policy reads `collected`**
  (M-A1, M-B11, M-B17). Lone throws with nothing gathered:
  `resolve_source`/`resolve_dest`/`resolve_terminal`/`_one_level`/
  `_wrong_direction` in `assembly.jl` (reaching `UnknownPort`,
  `PathResolution`, `FaceDirectionConflict`), `classify_tier` per component in
  `build.jl` (`ClassUnreadable`, `StoreWithoutUpdate`, `TierUnreadable`,
  `DeclarationOnWrongTier`), `ClassMixed`, `UnknownFaceSelection`,
  `WireTypeMismatch`, `ProducedByTwoStages`, and `DeploymentInvalid`, whose
  `bind_schedule` throws on nine arms against §9.1's `collected` so deployment
  validation runs under three barriers (keyword ranges, the first five
  `bind_schedule` checks, the anchor loop). A weaker population collects
  within one component and throws before the next:
  `DeclarationOnWrongTier(:tier_form)`, `ContainerMixed`, `ChildNameCollision`,
  `TransparentContainerUnknown`. `classify_tier` is also called from inside
  the wiring walk, so an unreadable tier aborts the walk before Stratum A's
  barrier. Retiring the family needs a sentinel-returning resolution pass,
  its own increment, and a ruling on the scope of "collected" (below).
- **Kinds carrying less than their Appendix C payload column.** D-216 rules
  that the column is the design and the implementation's gaps stay visible
  as such, and it leaves the enumeration here: `AlgebraicCycle` no wires and no
  §5.6 real/artificial classification, `FaceNameCollision` no per-entry
  provenance, `ContainerMixed` no element keys or indices, `UnconnectedInput`
  no declared entry type and no obligation-chain level,
  `ClassUnreadable`/`StoreWithoutUpdate` no §8.1 shadowing note,
  `ClassUnreadable`/`TierUnreadable` no type and no declarations-found list,
  `DeclaredNotProduced` no state-field list, `ProducedByTwoStages` no stage
  names, `TransparentContainerUnknown` no container-field list,
  `StopFaceInvalid` no binding site (constructor vs. `run!`),
  `ConformanceFailure` no simulation time on its runtime occurrences,
  `TapResolution` no candidates on the path-selector arms and none of
  §14.10's tap-set half; and from the audit (M-C, M-B14, M-B17, M-B19):
  `TwoProducers` producer terminals only inside provenance strings,
  `PathResolution` no generic-holding arm, `AttachUnknownFace`/
  `ReadBindingUnresolved` the binding type where the column says device type,
  `ServiceLifecycle.legal` empty at `init!`, `trim!` and `replay!` (only
  `capture` fills it), `DeclarationOnWrongTier` naming the two tiers rather
  than §8.5's two forms, `EventHalfMissing.found` a model type interpolated
  into the message against §13.2 (`_typename` is one screen up). The writer
  id missing from `OutOfClaimEntry`/`DeviceCrash`/`ReplayDiscardedStaging`/
  `MalformedDatum`/`EntryTypeMismatch` awaits the spec-pass ruling below.
- **§9.5's always-on conformance check** (the return laws are checked once,
  at the probe; what stands in its place is a deviation, below); **§8.3
  visibility**; **auto-published ports** — not a quiet absence but a
  `DeclaredNotProduced` refusal, so §8.2's own worked `Engine`, whose
  `output_types` names the state field `ω`, does not build, and the bundle
  law's `y` row, D-169's hand-down exclusion and §7.1's state-cell table are
  correct but vacuous (M-B21); §13.3's generic-holding check in the
  *load-bearing* register — increment 19 deleted `generically_held` when
  one-level routing left the structural register nothing to police, and
  nothing regrew it for the deep paths condition entries and trim `reads`
  still write, so §14.2's locality law rides as convention here.
- **§8.8 beyond the helper pair** (the feed-list idiom, generic-holding sugar,
  required-faces declarations, D-209's predicate filter on the passthrough
  helpers); **D-187's grid diagnostics** (the bound schedule is plain data;
  refusals name the anchor and the pool's GCD); and **every `show`** — no
  `Build` or schedule artifact renders: no anchor table, no `A₀` row, no
  rate-scope rows, no hyperperiod chart, no derivation line (M-B26).
- **§14**: `linearize` (§14.10), mounting (§14.9), the NLopt fallback and the
  nominal-activation loop it would run on; sub-port-field addressing; index
  addressing in the binding register; the `check` entry point (M-B23).
- **§11.7's GUI write path**, §10.7 pacing and its diagnostics, the §11.8
  remainder (`DebtReanchor`, `ThreadBudget`, `UnboundedRun`, the maxlog
  renderer). Two unguarded edges stay: staging through a handle whose device
  was detached lands in an orphaned cell and is lost, and an
  `InterruptException` in a device loop reports as `DeviceCrash` — the same
  uniform catch as M-B12 below.
- **§12 beyond its built slices**: pause and the control plane's surface; the
  operator interrupt — §13.4's carve-out exists, the masking and the entry do
  not, so a stopped run can hold mid-boundary stores here; §13.4's
  interactive-session behaviour (log and surface the status rather than
  rethrow) has no discrimination in `run!`. `run!` requires a finite `t_end`;
  every non-running state admits `attach!`/`detach!`.
- **Port-value coverage** (M-B7, M-B8, M-B10): enum-valued ports are refused
  — `leaf_types` returns empty for an `Enum`, so `place!` raises
  `IllegalPortType`, and `probe_value` has no enum arm, against §4.1 and
  §7.5's publish-a-mode remedy; a reference-carrying port type (§4.4's handle
  pattern) is neither supported nor refused — `leaf_types` walks into the
  `Vector`'s fields, the build succeeds and the first `gather` dies in a raw
  `MethodError`; containers of containers take `_children`'s inert-data
  branch and are silently dropped where §8.5 says rejected.
- **The declaration side of the bundle law**: a non-bundle `init_x`/`init_s`
  refuses as a raw `MethodError` from `Decls`' field type (`build.jl` ~17);
  no Appendix C kind owns it, the return side has `ConformanceFailure`.
- **§8.1's shadowing check**, the forgotten-import diagnostic (M-B25). The
  mechanism is `implementation.md`'s second caveat; it needs a decision entry
  and an Appendix C payload column on `ClassUnreadable`/`TierUnreadable`.
- **Two surface names do not exist**: there is no `condition` generic (two
  model packages defining one would define two functions, breaking §14.2's
  pull composition), and `ProbeDual`/`ProbeTag` are not names (M-B23).
- **§13.7's standard component library** (`SumJunction{W,N}`, the Bool gates,
  `Or{N}`, `UnitDelay{V}`, `Constant{V}`, the rig; §6.2's spellings) — a
  migration-phase deliverable by the spec's word, deferred with §16 (M-B22).
- **Smaller** (M-B26): no `report!(entry, d)` addressed by roster entry, only
  the internal `_report!(cell, d)`; the face table keeps the resolved endpoint
  and discards §9.1's routing chain that §13.7's provenance would print;
  `capture`, the trace header and the compiled `Reader` are three walks over
  the same stores against §14.1/§14.4's "one mechanism"; no `sizehint!`, and
  the log is a `Vector` of snapshot references, not inline records; the
  roster is a mutable `Vector` re-read every frame, frozen by
  `assert_stopped`'s policy rather than by type; the suite has no
  every-component `Dual` sweep, so D-166's CI policy is one fixture; the
  once-per-frame `ReplayDiscardedStaging` noise from a live device during
  replay is unpresented (§11.8).

## Built in a shape the spec's is not

Transactional: the commit introducing a deviation adds its bullet, the one
retiring it deletes it. All but the last two were found by the audit, none
of them chosen; the merge entry has the probe.

- **`t_end` lands on the nearest frame, not the first at or past it**
  (M-B1). `run!`, `step!` and `replay!` take `round(Int, t_end/h)` where
  §12.4 and Appendix B say the first grid boundary reaching `t_end`, and the
  target frame is compared against `clock.step`, which `_open_trajectory!`
  resets to 0, so it ignores `t0`: `init!(sim; t0 = 10.0)` then
  `run!(sim; t_end = 12.0)` runs to 22. Every suite `t_end` is grid-aligned
  from 0. Found by the previous pass at 2c02afb and lost.
- **The D-168 fan-out meet is not implemented** (M-B2). `_root_input_type`
  takes the first consumer's entry in flatten order, so a root input fanned
  into a `T` entry and a `Float64` entry pins or walks by declaration order,
  and the walking order delivers `Dual`s to the pinned entry — the join
  D-168 rejects — blaming the pinned consumer.
- **Nominal acceptance is equality modulo embedding, not `<:`** (M-B3).
  `_accepts` has no subtype arm, so an entry declared abstract refuses its
  lawful concrete producer with `WireTypeMismatch`; §4.4's substitutability
  idiom and §8.2's abstract reference-typed entries have no code. At root, a
  `Real` entry is refused blaming a synthesized `Int64`, and an abstract
  struct entry throws a raw `ArgumentError` from `leaf_types` before any
  diagnostic (`AbstractAtRoot`, above).
- **The runtime table write converts** (M-B4), the shape D-053 rejects.
  `scatter_group!` fetches declared names by `getfield` and `scatter!` writes
  `buf[i] = v`, so an `Int64` where `T` was declared becomes `1.0`, an extra
  field is dropped, a missing one is a raw `FieldError` inside a `StepError`.
- **Derivative and projection conformance is checked by leaf count**
  (M-B6). `_check_derivative` and `_check_state_write` compare `nleaves` per
  field where §7.1 and §9.5 state shape at `T`, so an `Int64` leaf for a
  `Float64` state passes and converts.
- **`AlgebraicCycle` reports the raw stall residue** (M-B5), the shape D-012
  rejects: every component Kahn's algorithm could not place, downstream
  acyclic ones included, as component paths in flatten order, two disjoint
  cycles merged into one diagnostic. `test_build.jl` asserts the current
  shape. Retires with §5.6's tracer, not alone.
- **State-leaf construction runs on every view** (M-B9). `reconstruct`
  emits `Expr(:call, P, …)`, so an invariant-carrying leaf's normalizing
  constructor runs on every materialization, the projection-on-read D-094
  rejects; and an `Int` or `Bool` leaf in `init_x` builds and silently becomes
  `Float64` (`IllegalStateLeaf`, above).
- **The activation cache is an unguarded `get!`** (M-B15) where §9.4 makes
  torn-state-free lazy materialization normative and §9.2 promises concurrent
  `Simulation`s over one `Build`. `build.jl`'s docstring says the guarantee
  is met "by having none".
- **`phase_bodies` returns four bodies** (M-B20); guards, handlers and the
  `state_projection` callables live on `Executor.events` alone, against §9.7
  and Appendix B.
- **The device wrapper files the `unblock!`-provoked raise as a
  `DeviceCrash`** (M-B12). `_wrap` catches uniformly where §12.4 says the
  wrapper treats that raise as shutdown, so a conforming device whose
  `unblock!` closes its channel leaves a warning and a residue on every clean
  run; the suite's `Blocked` fixture does the discrimination itself. Retires
  with §12's interrupt work.
- **The interrupt carve-out bypasses the stop word** (M-B13). `sim.jl`
  returns `ControlRequestedStop(:interrupt)` without `_request_stop!`, so an
  interrupt arriving after another issuer won the first-writer-wins CAS
  reports `:interrupt` as the source. Retires with §12's interrupt work.
- **The heartbeat is read at publication, not at the drain** (M-B18);
  `drain!` never touches `_heartbeat`, and a `t*` boundary publishes without
  a drain. Nothing observable breaks; the site is not the one §11.8 fixes.
- **Walkthrough 5 delivers one of its two diagnostics** (M-B16). A typo'd
  return field raises `UndeclaredReturnField` from `_check_ports` before the
  `DeclaredNotProduced` pass runs.
- **Localization stops at `tol·h′` over the current segment** on remainder
  segments, tighter than the `tol·h` §10.4 and D-133 state (M-B26).
- **Docstrings that state the spec's shape over code that does not produce
  it** (M-A3): `diagnostics.jl`'s `AlgebraicCycle.members` ("the SCC's member
  terminals"); `localization.jl`'s attribution of the segment-relative rule
  to D-133; `sim.jl`'s `t_end` "taken to the nearest frame top"; `declare.jl`'s
  `init_s` "any isbits type" where §7.3 says any immutable under the
  frozen-reference rule; `build.jl`'s torn-state "by having none".
- **The per-writer status is a `Vector` of records built at each
  publication** (chosen). §11.8 has it ride inline in the snapshot's one
  per-boundary allocation, zero additional heap allocation on a quiet frame;
  the simple shape costs one small allocation. Retires with an
  allocation-tightening pass, an `NTuple` status type fixed per run.
- **Trim's per-iteration tree rebuild allocates** where §14.2 reads
  "rebuilding the tree per trim iteration is stack-only construction": an
  `at` node holds a `String` and is not isbits. The register's own write is
  free and asserted so (`test_conditions.jl`); the construction cost is noted
  in that file's comments and guarded by nothing. Needs a test before it can
  be called more than a note.

## Awaiting a ruling

Where the code's shape is coherent and the spec may be what moves. Each is
the user's call; a ruling lands docs-commit-first, then the bullet above it
retires or the code conforms. All are the audit's (M-D and M-B26):

- **`method = RK4` vs `algorithm = RK4()`** (M-B24). A type versus an
  instance, and a different name, already in the trace header's deployment
  block; Appendix B and six other sites spell the latter, no decision
  ratifies either.
- **`t_end = Inf` as the interactive default.** The code refuses `Inf` and
  demands a bound; Appendix B's unbounded-run warning and `log_max` as the
  memory bound describe a mode the package refuses to enter. `run!` in
  `:replay` demands the bound too, where the trace has one.
- **Writer ids in the periphery kinds.** `dataplane.jl` argues the cell
  attributes the writer; Appendix C's columns were not amended.
- **"Printable."** §9.2's "plain printable data" read as inspectable makes
  the missing `show`s a non-gap; read as rendered it does not.
- **"Collected" has no stated scope.** §13.1's worked example (did-you-mean
  plus both unconnected inputs from one typo'd wire) requires the stratum
  scope, which D-057 backs; the code collects per component, per pass and
  never per stratum.
- **`Snapshot.boundary` is stamped from the control plane's counter**, which
  `init!` never resets, so a second trajectory opens at the first one's
  count; the field's comment says "boundary zero = 0".
- **`init_s`'s vocabulary.** The docstring says isbits, §7.3 says any
  immutable under the frozen-reference rule and requires a mutable RNG state
  to live there; the code enforces neither.
- **`attach!` on an errored sim.** The docstring calls it deliberate
  (post-mortem); Appendix B lists three legal states without it.
- **Prose that does not match the mechanism it describes, with the code
  right**: §10.5's "the gate's image of the frame index" is wrong for
  `n > 1`; D-133 calls `localization_budget` `event_budget`; §10.6's
  "exhaustion emits a `FiringBudget` warning" admits a reading the code does
  not take; §10.4's "in declaration order within the iteration" needs §10.6's
  one-per-component rule to be true; §11.5's bound sentence is weaker than
  the code's; §13.5's "absent when no boundary ever ran" names a case no run
  can reach, boundary zero preceding every record, so the field's `nothing`
  arm is dead.
