# Naming inventory: test/test_lifecycle.jl

Tip: 0c0a899. Sites flagged: 46. Renames: 34. Collisions: 0. Roster proposals: 1.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 0, keep:glance 2, keep:family 9, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- `t`: a spawned `Task` (`t = Threads.@spawn run!(...)`, line 104) vs. a `TerminationRecord` (lines 125, 217, 229, 238, 351). Neither is the time spec symbol — both rename below, to `task` and `record` respectively.
- `d`: the family letter for a diagnostic under test, already spelled correctly at nine sites (kept, no row) — and, in the fixtures, the device parameter of `TailProbe`'s contract methods, which is a different thing entirely and renames to `dev` (see `devices.md`'s Question on the same pattern).

## The `TailProbe`/`NoClaim` fixtures — lines 19–33

Same finding as `test_devices.jl`: `TailProbe`'s `init!`, `shutdown!` and `loop` extend `src/devices.jl`'s generic (`init!(::AbstractDevice)`, `loop(dev::AbstractDevice, handle)`), so their parameters are `keep:api` only at the spec's spelling. This file spells them `d`/`h`.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 23 | `d` | parameter (`init!(d::TailProbe)`) | the device | rename | `dev` |
| 24 | `d` | parameter (`shutdown!(d::TailProbe)`) | the device | rename | `dev` |
| 25 | `d` | parameter (`loop(d::TailProbe, h)`) | the device (unused in the body) | rename | `dev` |
| 25 | `h` | parameter (`loop(d::TailProbe, h)`) | the handle | rename | `handle` |

`NoClaim`'s `is_input`/`claims` methods (lines 32–33) bind no names.

## "the five states, and the gates between them (§12.6)" — line 36

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 40 | `diag` | local | the diagnostic under test (`run!`'s refusal) | rename | `d` |
| 42 | `diag2` | local | the diagnostic under test (`step!`'s refusal); fully consumed before the next binding, so it is sequential with `diag`, not simultaneous | rename | `d` |
| 50 | `diag` | local | the diagnostic under test (`run!`'s refusal, `:stopped`) | rename | `d` |
| 53 | `diag2` | local | the diagnostic under test (`step!`'s refusal, `:stopped`) | rename | `d` |

## "the placeholder run, and the object each door replaces (§12.6, D-255, D-261)" — line 60

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 68 | `r0` | local | the placeholder run, read by three later assertions | rename | `placeholder` |
| 78 | `r1` | local | the run `init!` allocates, read by three later assertions | rename | `run` |

`d` (lines 72, 88) is the diagnostic under test, already spelled correctly — `keep:family`, sequential rebinds, no row.

## "the freeze is the lifecycle's :running — init! and run! refuse it too (§12.6)" — line 94

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 104 | `t` | local | the spawned `run!` task, waited on later — the file's other `t` is a `TerminationRecord`, neither is time | rename | `task` |
| 108 | `diag_i` | local | `init!`'s refusal, bound before `diag_r` and asserted after both are bound — the two coexist | rename | `init_diag` |
| 109 | `diag_r` | local | `run!`'s refusal, coexisting with `diag_i` | rename | `run_diag` |

## "t_end is the advance's own bound, validated per call (§13.5)" — line 121

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 125 | `t` | local | the run's `TerminationRecord`, read by three further assertions | rename | `record` |
| 178 | `dr` | local | `run!`'s bound-validation diagnostic, compared against `dp`/`ds` | rename | `run_diag` |
| 179 | `dp` | local | `replay!`'s, compared against `dr`/`ds` | rename | `replay_diag` |
| 180 | `ds` | local | `step!`'s, compared against `dr`/`dp` | rename | `step_diag` |

## "stop_on names root-exported Bool output faces, validated at all three sites (§13.5)" — line 187

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 193 | `er` | local (loop body) | `run!`'s failure, compared against `ep`/`es` | rename | `run_err` |
| 194 | `ep` | local (loop body) | `replay!`'s failure, compared against `er`/`es` | rename | `replay_err` |
| 195 | `es` | local (loop body) | `step!`'s failure, compared against `er`/`ep` | rename | `step_err` |
| 196 | `dr` | destructured (loop body) | `run!`'s diagnostic, compared against `dp`/`ds` | rename | `run_diag` |
| 196 | `dp` | destructured (loop body) | `replay!`'s diagnostic, compared against `dr`/`ds` | rename | `replay_diag` |
| 196 | `ds` | destructured (loop body) | `step!`'s diagnostic, compared against `dr`/`dp` | rename | `step_diag` |

`m` (line 188, the built model, read on the next line) is `keep:glance`. `trc` (line 191) is the roster's own spelling for a trace, not flagged. `d` (line 206) is the diagnostic under test, already correct — `keep:family`, no row.

## "a boundary-detected stop face ends the run at its own boundary (§13.5)" — line 213

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 217 | `t` | local | the run's `TerminationRecord`, read by three further assertions | rename | `record` |

## "an authored condition already terminal ends the run at t₀, integrating nothing (§13.5)" — line 224

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 229 | `t` | local | the run's `TerminationRecord` | rename | `record` |

## "a localized stop ends the run at t*, the crossing state final (§13.5, §10.4)" — line 234

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 238 | `t` | local | the run's `TerminationRecord`, read by four further assertions | rename | `record` |

## "the record carries the terminating advance's policy (§13.5, D-255)" — line 256

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 260 | `pol` | local | the terminating advance's `StopPolicy` | rename | `policy` |

## "an unbounded run raises the advisory into the loop's cell (§13.5, §11.8)" — line 270

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 274 | `c` | local | the `HookedInterrupter` component, whose `.hook` is set on a later line — not one-glance | rename | `comp` |
| 283 | `c2` | local | the second `HookedInterrupter` component | rename | `comp2` |

## "step! advances whole frames and returns the count actually advanced (§12.6)" — line 297

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 309 | `ref` | local | the comparison simulation advanced by `run!` instead of `step!` | roster? | `ref` — "reference [comparison instance]"; see `devices.md`'s roster proposal |
| 317 | `d1` | local | the diagnostic under test (`frames`+`t_plus` both given); bound, asserted and discarded before the next binding | rename | `d` |
| 319 | `d2` | local | the diagnostic under test (`frames = 0`); sequential with `d1`, `d3`, `d4` | rename | `d` |
| 321 | `d3` | local | the diagnostic under test (`t_plus = 0.0`) | rename | `d` |
| 325 | `d4` | local | the diagnostic under test (both given, with a `stop_on` face too) | rename | `d` |

## "§13.6: a loop-side throw discards the failed boundary and promotes the last one" — line 342

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 351 | `t` | local | the run's `TerminationRecord`, read by three further assertions | rename | `record` |

`s` (line 358, `[s.frame for s in logged(sim)]`) is a comprehension variable — `keep:glance`. `d` (lines 365, 367, 369, 373, 376) is the diagnostic under test, already correct — `keep:family`, five sequential rebinds within the one testset, no row.

## "a throw inside boundary zero returns a warm simulation to built (§12.6, D-223)" — line 380

No flagged sites beyond `d` (line 390), already correct — `keep:family`, no row.

## Collisions

None in this file.

## Roster proposals

- `ref` — "the comparison/reference simulation." 1 site in this file (line 309); see `devices.md` for the group's other sites and running count.

## Questions

- **`diag`/`diag2` vs. `d`, and when a second diagnostic needs a role.** Read against the brief's own already-compliant pattern (this file's "§13.6" testset reuses bare `d` five times, sequentially, with no role suffixes at all), I've treated a second diagnostic as needing a role name only when both are alive *together* — bound before either is asserted, or compared directly (`dr.argument == dp.argument`) — and as a plain sequential rebind of `d` when the first is fully asserted and discarded before the second binds (`diag`/`diag2` here, and `d1`–`d4` in "step! advances..."). The brief's text ("a second diagnostic in the same testset is named by role") reads more absolute than this, so if the intended rule is scope-wide rather than liveness-based, the `diag`/`diag2` and `d1`–`d4` rows above collapse from four/two proposals each to a single `d`, and the eight `d1`–`d4`-style rows disappear from the count entirely (replaced by four plain `keep:family` sites).
- **`c`/`c2` for `HookedInterrupter`.** I've proposed `comp`/`comp2` (the roster's word for a component), since `HookedInterrupter` is exactly that. If the coordinator prefers a name tied to the fixture itself rather than the generic role, a different proposal may read better.
- The device/binding-contract `keep:api`-at-spec-spelling question from `devices.md` applies identically to `TailProbe`'s three methods here; see that report's first Question for the full reasoning.
