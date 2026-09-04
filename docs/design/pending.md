# Pending against the spec

What `src/` and `test/` still owe the design: the constructs not yet built,
and the stand-ins built in a shape the spec's is not. Every item here is known
and recorded; none is abandoned. `check_refs.jl` and `check_rows.jl` read this
file, so every `§N` and `D-nnn` below resolves or the tools go red.

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
  did-you-mean **ranking** (candidate lists are carried and rendered, never
  ordered; a mistyped *path* gets no list at all) and §11.8's maxlog renderer
  (count-only display past 25 cumulative occurrences per writer × kind).
- **First-violation refusals where the kinds' policy reads `collected`**:
  `resolve_source`/`resolve_dest`/`resolve_terminal`/`_one_level`/
  `_wrong_direction` in `assembly.jl`, and `classify_tier` per component in
  `build.jl` — reaching `UnknownPort`, `PathResolution`,
  `FaceDirectionConflict`, `ClassUnreadable`, `StoreWithoutUpdate` and
  `TierUnreadable`; retiring them needs a sentinel-returning resolution pass,
  its own increment.
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
  `ConformanceFailure` no simulation time on its runtime occurrences, and
  `TapResolution` no candidates on the path-selector arms and none of
  §14.10's tap-set half.
- **§9.5's always-on conformance check** (the return laws are checked once,
  at the probe); **§8.3 visibility**; auto-published ports; §13.3's
  generic-holding check in the *load-bearing* register — increment 19 deleted
  `generically_held` when one-level routing left the structural register
  nothing to police, and nothing regrew it for the deep paths condition
  entries and trim `reads` still write, so §14.2's locality law rides as
  convention here.
- **§8.8 beyond the helper pair** (the feed-list idiom, generic-holding sugar,
  required-faces declarations); **D-187's grid diagnostics** (the bound
  schedule is plain data; refusals name the anchor and the pool's GCD).
- **§14**: `linearize` (§14.10), mounting (§14.9), the NLopt fallback and the
  nominal-activation loop it would run on; sub-port-field addressing; index
  addressing in the binding register.
- **§11.7's GUI write path**, §10.7 pacing and its diagnostics, the §11.8
  remainder (`DebtReanchor`, `ThreadBudget`, `UnboundedRun`, the maxlog
  renderer). Two unguarded edges stay: staging through a handle whose device
  was detached lands in an orphaned cell and is lost, and an
  `InterruptException` in a device loop reports as `DeviceCrash`.
- **§12 beyond its built slices**: pause and the control plane's surface; the
  operator interrupt — §13.4's carve-out exists, the masking and the entry do
  not, so a stopped run can hold mid-boundary stores here. `run!` requires a
  finite `t_end`; every non-running state admits `attach!`/`detach!`.

## Stand-ins: where the implementation's shape is not the spec's

Transactional: the commit introducing a stand-in adds its row, the one
retiring it deletes it.

| spec shape | stand-in here | retirement |
| --- | --- | --- |
| the per-writer status rides inline in the snapshot's one per-boundary allocation — zero additional heap allocation on a quiet frame (§11.8) | a `Vector` of per-writer records built at each publication, the small extra allocation the simple shape costs | an allocation-tightening pass (an `NTuple` status type fixed per run) |

Two readings run ahead of the spec's letter, flagged for the spec pass:

- **The species rule is the implementation's spelling.** §13.4 says a
  conformance failure "is thrown as its typed diagnostic at the table-write
  point, and it arrives at the same catch site. There it is a species of
  `StepError`", without saying how the catch site recognizes one. Here a
  `BuildError` carrying exactly one diagnostic, thrown inside the sequence,
  arrives unwrapped as that diagnostic — which keeps the catch site the only
  `StepError` constructor while letting a runtime check throw its own kind. A
  multi-diagnostic carrier stays raw, having no single species.
- **Boundary zero sits outside the catch.** `init!` and `replay!` run it as
  stopped-sim services and propagate raw. The spec calls boundary zero "the
  ordinary macro-sequence with an empty integrate" and a legal replay halt, so
  a reading that wraps it too is available. The conservative choice here is
  that a service's own refusal path is not a frame, there being no frame-entry
  pointer for a frame that has not begun.

Also short of the spec's word, and needing a test before it can be called a
stand-in: §14.2 reads "rebuilding the tree per trim iteration is stack-only
construction", which does not hold for a tree carrying `at` prefixes — an `at`
node holds a `String` and is not isbits, so construction allocates. The
register's own write is free and asserted so (`test_conditions.jl`); the
construction cost is noted in that file's comments and guarded by nothing.
