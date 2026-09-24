# Naming inventory: test/test_events.jl

Tip: 0c0a899. Sites flagged: 70. Renames: 9. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 6, keep:spec 27, keep:glance 0, keep:family 11, keep:roster 17, keep:api 0.

## Letters with more than one meaning in this file

- `m`: the mode bundle field, destructured as `(; m)` throughout the malformed-event structs
  at the top of the file (keep:spec, many sites) — vs. a `Group` model bound as a bare local
  at line 203 (`due updates run after quiescence...`) → renamed to `model` there; every other
  `m = Group(...)` in the file (lines 10, 39, 67, 123, 184) is read exactly once on the next
  line and stays `keep:glance`, so only the one non-glance site needed the rename.
- `s`: the discrete state bundle field, destructured as `(; s)` (keep:spec, `EventsOnDiscrete`
  and `ProjectOnDiscrete`) — vs. `ProjectOnDiscrete`'s own `state_projection` method (line 57),
  which binds its raw-state parameter `s` where every other `state_projection` extension in
  the file and in `test/fixtures.jl` spells it `x` → renamed to `x` below, both resolving the
  clash and fixing the cross-method inconsistency (rule 3).
- `t`: the time bundle field (implicit in the events bundle `(:m, :u, :y, :t)`, line 122) —
  vs. the `TerminationRecord` bound at line 311 → renamed to `record`.

## Malformed event and projection declarations — line 4

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 57 | `s` | parameter | the raw state `state_projection` is asked to project; every other extension of this generic (line 62 in this file, and `Rotor`/`Primer`/`Diverger` in `test/fixtures.jl`) spells this parameter `x` | rename | `x` |

## "the θ = 0 validation" through "budget exhaustion degrades" (lines 180–257)

## "an x-writing handler's carried overshoot is resolution-invariant" — line 180

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 186 | `N` | parameter (`q_ref`, a local function) | the number of 0.03 increments the reference recursion runs | rename | `n_steps` |
| 188 | `n` | for-loop | which `N_base` value this iteration drives (`Simulation(...; N_base = n)`) | rename | `n_base` |

## "due updates run after quiescence, from post-transition values (§10.6)" — line 198

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 203 | `m` | local | the `Group` model, read on the next line only here but sharing its letter with the mode bundle field used throughout the rest of the file | rename | `model` |

## "budget exhaustion degrades, reported on the loop's cell (§10.6, §11.8)" — line 217

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 228 | `lw` | local | the loop's writer status, read across the rest of the testset (reassigned at line 236) | rename | `loop_status` |
| 229 | `fb` | local | the `FiringBudget` report the loop's status carries | rename | `firing_report` |
| 236 | `lw` | local | the loop's writer status, re-read after the exhausted boundary | rename | `loop_status` |
| 253 | `fb2` | local | the second simulation's `FiringBudget` report | rename | `firing_report2` |

## "a handler's mode flip reaches its cell through the next sweep (§5.3, D-154)" — line 301

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 311 | `t` | local | the run's `TerminationRecord` — `termination` (the natural noun, and the function that produces it) can't be used here without shadowing `termination(sim)` on the same line | rename | `record` |

## Collisions

None in this file: every flagged site above is a bare short name or an inconsistent spelling,
not a name that already matches a reachable function.

## Roster proposals

None from this file.

## Questions

- Line 57's `s` (`ProjectOnDiscrete`): this struct exists specifically to trigger
  `DeclarationOnWrongTier` for `state_projection` on a discrete-only fixture. Renaming its
  parameter to `x` for consistency is presumably harmless (the mismatch being tested is the
  tier, not the parameter name), but flagging in case the original `s` was a deliberate
  signal rather than an oversight.
- `t` → `record` (line 311): `record` is generic; if the coordinator has a preferred noun for
  a bound termination record elsewhere in the suite, this site should match it.
- `fb`/`fb2` (lines 229, 253) and `lw` (lines 228, 236): these mirror a pattern that recurs in
  `test/test_localization.jl` (`cb`, `lw`) for `ChatteringBudget` instead of `FiringBudget`.
  Worth one ruling covering both files so `firing_report`/`chattering_report` and
  `loop_status` land the same way in each.
