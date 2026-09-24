# Naming inventory: test/test_trace.jl

Tip: 0c0a899. Sites flagged: 163. Renames: 27. Collisions: 1. Roster proposals: 0.
Kept without a row: keep:index 2, keep:typeparam 0, keep:spec 4, keep:glance 20, keep:family 38, keep:roster 71, keep:api 0.

## Letters with more than one meaning in this file

- `d`: the diagnostic under test almost everywhere (keep:family, 38 sites) — vs. the device
  parameter of `loop(d::Nudge, h)` (line 12) and `loop(d::HarnessPoker, h)` (line 802) →
  renamed to `dev` below.
- `h`: never bound as the grid-step spec symbol in this file (that meaning appears only at
  API-keyword call sites, out of scope) — but the letter is bound for two different things:
  the device handle parameter of the same two `loop` methods (renamed to `handle`) and the
  trace header local at line 78 (renamed to `header`).
- `b`: the drained `TraceBatch`, almost everywhere (renamed to `batch`/`batch1`…`batch4`
  below — including `recorded_faces`'s parameter, a two-line method that would otherwise be
  `keep:glance`) — vs. `same_trajectory`'s second parameter, a sequence of logged snapshots
  (renamed to `reference`).
- `k`: the fixture's gain/rate multiplier (`Gain(k)`, `Relative(k)`, threaded through
  `replay_model`, `replay_twin`, `sampled_root`, `sampled_session` — `keep:spec`, 4 sites) —
  vs. a frame ordinal used as a plain parameter in `at_frame` and `prefix` (renamed to
  `frame`) — vs. a genuine dictionary-key comprehension index in `snap_cells` (line 397,
  `keep:index`, unaffected by the other two).
- `r`: `sim2.run` (renamed to `run`, R1's exception for a `Run`) — vs. a discard-report
  string in `trace_discarded_staging` (renamed to `report`).

## `Nudge`, `loop(d::Nudge, h)` — line 8

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 12 | `d` | parameter | the device; the same letter is the diagnostic family letter everywhere else in this file | rename | `dev` |
| 12 | `h` | parameter | the device handle; `src/devices.jl`'s own signature spells it `loop(dev, handle)` | rename | `handle` |

## `recorded_faces(trc, b::TraceBatch)` — line 34

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 34 | `b` | parameter | the batch whose recorded faces are resolved; not glance-exempt because `b` also means the drained `TraceBatch` at dozens of non-glance sites in this file | rename | `batch` |

## "one sparse record per drained batch, against the writer's schema (§11.5, D-176)" — line 38

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 46 | `b` | local | the batch drained this frame, read across the rest of the testset | rename | `batch` |

## "the header is the pre-sequence state, resolved (§11.5, §14.5, D-038)" — line 75

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 78 | `h` | local | the trace's header, read across the rest of the testset | rename | `header` |

## "a roster change appends the writer set; earlier records keep their schema (§11.5)" — line 123

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 129 | `hd` | local | the handle `attach!` returns for the newly attached device | rename | `handle` |
| 141 | `b1` | destructuring | the first of three drained batches, read again at line 158 | rename | `batch1` |
| 141 | `b2` | destructuring | the second batch | rename | `batch2` |
| 141 | `b3` | destructuring | the third batch | rename | `batch3` |
| 156 | `b4` | local | the batch recorded after the detach | rename | `batch4` |

## "the header is compared against the build and the deployment binding (§12.7)" — line 223

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 230 | `paths` | local | the header-mismatch diagnostic named `:paths`; shadows `test/utils.jl`'s `paths` | collision | `d` |

## "a valid trace normalizes to compiled scatters, in drain order (§12.7, D-101)" — line 340

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 342 | `tgt` | local | the replay target, read across the rest of the testset (including the nested `cells()` helper) | rename | `target` |

## `same_trajectory(a, b)` — line 400

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 400 | `a` | parameter | the candidate session's logged snapshots | rename | `candidate` |
| 400 | `b` | parameter | the reference session's logged snapshots; not glance-exempt because `b` also means `TraceBatch` in this file | rename | `reference` |

## `at_frame(snaps, k::Int)` — line 406

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 406 | `k` | parameter | the frame ordinal sought; not glance-exempt because `k` also means the fixture's gain/rate multiplier in this file | rename | `frame` |

## "a replay reproduces the recorded trajectory bitwise (§12.7, D-101)" — line 430

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 456 | `rec` | local | the continuation's own trace, compared field by field against `trc` | rename | `recording` |

## "`to_time` addresses the same halt by time (§12.7, D-219)" — line 514

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 516 | `k` | parameter (`prefix`, a local function) | the frame ordinal bounding the prefix; same conflict as `at_frame`'s `k` | rename | `frame` |

## "`to_time`'s refusals precede every write (§12.7, D-219)" — line 548

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 553 | `tgt` | local | the replay target | rename | `target` |
| 561 | `tgt` | local (for-loop body) | the replay target, rebuilt each iteration | rename | `target` |
| 579 | `e` | local | the error `replay!` raises on a mismatched grid; every other site of this idiom in the file binds `err` | rename | `err` |

## "the recording bounds a replaying advance, and the end flips the mode (§12.7, D-218)" — line 584

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 594 | `r` | local | the run object, `sim2.run`, compared by identity after the mode flip | rename | `run` |

## "a continuation is a live session from the replayed boundary (§12.7)" — line 645

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 657 | `cont` | local | the session's own trace, compared against the recording it continues | rename | `continuation` |

## "`live!` takes a replayed halt live, and the session records itself (§12.7, D-219)" — line 669

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 678 | `r` | local | the run object, `sim2.run`, compared by identity after the mode flip | rename | `run` |
| 702 | `cont` | local | the session's own trace, compared against the recording it continues | rename | `continuation` |

## "live staging met by a replay is discarded, and reported (§12.7, §11.8)" — line 764

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 785 | `r` | local | the one discard-report string `discard_reports` returns; not glance-exempt because `r` also means `sim2.run` in this file | rename | `report` |

## `HarnessPoker`, `loop(d::HarnessPoker, h)` — line 798

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 802 | `d` | parameter | the device; the same letter is the diagnostic family letter everywhere else in this file | rename | `dev` |
| 802 | `h` | parameter | the device handle; `src/devices.jl`'s own signature spells it `loop(dev, handle)` | rename | `handle` |

## Collisions

- `paths` (line 230, `test/test_trace.jl`): shadows `test/utils.jl`'s
  `paths(structure::Structure)`. The file never calls `paths(...)` itself, but the function
  is reachable from the same `CadenceTests` scope, which the brief's flagging rule treats as
  enough. Renamed to `d`, joining the testset's other sequentially-bound diagnostic locals
  (`:h`, `:localization_budget`, `:firing_budget`), each already fully read before the next
  is bound.

## Roster proposals

None from this file.

## Questions

- `loop(d::Nudge, h)` (line 12) and `loop(d::HarnessPoker, h)` (line 802) both abbreviate the
  device-contract parameters to single letters instead of `src/devices.jl`'s own
  `loop(dev, handle)` spelling. The same `d`/`h` pattern recurs in every device fixture's
  `loop` method across the whole suite (at least `test_bindings.jl`, `test_devices.jl`,
  `test_diagnostics.jl`, `test_lifecycle.jl`), so a fix here alone would be inconsistent with
  the rest of the suite; this is worth one ruling that covers every group, not a per-file one.
- `same_trajectory`'s first parameter `a` (line 400) has only one meaning in this file and
  would be `keep:glance` on its own (the method is three lines). It is renamed to `candidate`
  here only for symmetry with `b`, whose rename is required by the one-meaning rule. If the
  coordinator would rather keep `a` and rename only `b`, that reads fine too.
- `whatif` (line 846) fuses "what" and "if" without an underscore, which the words-join-with-
  underscores rule seems to forbid. It is not "flagged" under the brief's three conditions
  (not short, not an abbreviation, no collision), so it is not tabled above, but it looks like
  a genuine violation worth a look in a later pass.
- `b1`/`b2`/`b3`/`b4` (lines 141, 156) are named by ordinal position, paralleling `sim`/`sim2`.
  None of the four plays a distinguishable role beyond "which batch, in order," so no more
  descriptive role name suggested itself; the coordinator may prefer one tied to the writer
  each batch came from instead.

