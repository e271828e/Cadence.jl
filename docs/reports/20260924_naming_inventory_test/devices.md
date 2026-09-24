# Naming inventory: test/test_devices.jl

Tip: 0c0a899. Sites flagged: 63. Renames: 44. Collisions: 0. Roster proposals: 1.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 1, keep:glance 8, keep:family 1, keep:roster 0, keep:api 0. (Of the 14 `keep:glance` and 3 `keep:spec` sites found, 6 and 2 respectively are tabled below because their permission was arguable — `v`, `cfe`, `dc`, `rr`×2, `h` (line 380), and `t0`×2 — so they are not double-counted here.)

## Letters with more than one meaning in this file

- `t`: time (the boundary-time comprehension variable in `wait_next_snapshot observes...`, keep:spec) vs. a `TerminationRecord` (`t = termination(sim2)` in the failed-`init!` testset) → the termination-record site renamed below.
- `d`/`h`: the device and handle in every fixture's contract method (`init!`, `shutdown!`, `unblock!`, `loop`) vs. the correct spec spelling used nowhere in this file — every occurrence renames to `dev`/`handle` below.

## The device fixtures — lines 9–132

Every fixture's `init!`, `shutdown!`, `unblock!` and `loop` method extends `src/devices.jl`'s generic (`init!(::AbstractDevice)`, `shutdown!(::AbstractDevice)`, `unblock!(::AbstractDevice)`, `loop(dev::AbstractDevice, handle)`). Per the brief, these parameters are `keep:api` at the spec's spelling — `dev` for the device, `handle` for the handle (the classification table's own example, and the spelling `test/fixtures.jl`'s `loop(::Pad, handle)` already uses). None of this file's fixtures use that spelling: every one spells the device `d` and the handle `h`, both flagged by length and neither at the spec's spelling, so every occurrence renames.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 14 | `v` | parameter (`OneShot(v)`) | the value the device stages, consumed on the next line | keep:glance | — |
| 15 | `d` | parameter (`init!(d::OneShot)`) | the device | rename | `dev` |
| 16 | `d` | parameter (`shutdown!(d::OneShot)`) | the device | rename | `dev` |
| 17 | `d` | parameter (`loop(d::OneShot, h)`) | the device | rename | `dev` |
| 17 | `h` | parameter (`loop(d::OneShot, h)`) | the handle | rename | `handle` |
| 32 | `d` | parameter (`loop(d::Collector, h)`) | the device | rename | `dev` |
| 32 | `h` | parameter (`loop(d::Collector, h)`) | the handle | rename | `handle` |
| 34 | `snap` | local | the observed snapshot, read across the loop body | rename | `snapshot` |
| 47 | `d` | parameter (`shutdown!(d::Crasher)`) | the device | rename | `dev` |
| 48 | `d` | parameter (`loop(d::Crasher, h)`) | the device | rename | `dev` |
| 48 | `h` | parameter (`loop(d::Crasher, h)`) | the handle | rename | `handle` |
| 55 | `d` | parameter (`init!(d::BadInit)`) | the device | rename | `dev` |
| 56 | `d` | parameter (`shutdown!(d::BadInit)`) | the device | rename | `dev` |
| 57 | `d` | parameter (`loop(d::BadInit, h)`) | the device | rename | `dev` |
| 57 | `h` | parameter (`loop(d::BadInit, h)`) | the handle | rename | `handle` |
| 65 | `d` | parameter (`shutdown!(d::Stubborn)`) | the device | rename | `dev` |
| 66 | `d` | parameter (`loop(d::Stubborn, h)`) | the device | rename | `dev` |
| 66 | `h` | parameter (`loop(d::Stubborn, h)`) | the handle | rename | `handle` |
| 74 | `d` | parameter (`unblock!(d::Blocked)`) | the device | rename | `dev` |
| 75 | `d` | parameter (`shutdown!(d::Blocked)`) | the device | rename | `dev` |
| 76 | `d` | parameter (`loop(d::Blocked, h)`) | the device | rename | `dev` |
| 76 | `h` | parameter (`loop(d::Blocked, h)`) | the handle | rename | `handle` |
| 94 | `d` | parameter (`unblock!(d::Raising)`) | the device | rename | `dev` |
| 95 | `d` | parameter (`shutdown!(d::Raising)`) | the device | rename | `dev` |
| 96 | `d` | parameter (`loop(d::Raising, h)`) | the device | rename | `dev` |
| 96 | `h` | parameter (`loop(d::Raising, h)`) | the handle | rename | `handle` |
| 109 | `d` | parameter (`shutdown!(d::Interrupting)`) | the device | rename | `dev` |
| 110 | `d` | parameter (`loop(d::Interrupting, h)`) | the device | rename | `dev` |
| 110 | `h` | parameter (`loop(d::Interrupting, h)`) | the handle | rename | `handle` |
| 120 | `d` | parameter (`loop(d::Inline, h)`) | the device | rename | `dev` |
| 120 | `h` | parameter (`loop(d::Inline, h)`) | the handle | rename | `handle` |

`Loopless` and `NarrowLoop` (lines 130–132) bind no names (`loop(::NarrowLoop, ::DeviceHandle) = nothing`).

## "a device stages through its handle from its own task, and departure consults should_abort (§11.6, §12.4)" — line 135

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 138 | `h` | local | the attached handle, read by four later assertions | rename | `handle` |

## "wait_next_snapshot observes ordered boundaries and wakes on the stop (§12.3, §12.4)" — line 155

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 167 | `snap` | local | the handle's re-read snapshot, read on the next line | rename | `snapshot` |

`b`/`t` in `[b for (_, b) in dev.seen]` / `[t for (t, _) in dev.seen]` (lines 163–164) are comprehension variables — `keep:glance`, and `t` there is also the time spec symbol — `keep:spec`.

## "a crash is caught, shutdown! runs, the run continues, claims persist (§12.4(6))" — line 207

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 220 | `cfe` | local | the harness diag batch's one entry, read on the next line | keep:glance | — |

## "a failed init! is bracketed: shutdown!, no task, claims persist (§12.4)" — line 235

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 246 | `bw` | local | `BadInit`'s writer status, read two lines apart (`.totals.crash`, then `stale(bw) && bw.task_state`) | rename | `status` |
| 248 | `dc` | local | the failed device's one recent record, read on the next line | keep:glance | — |
| 269 | `t` | local | the second simulation's `TerminationRecord` — the file's other `t` is time, never this | rename | `record` |
| 271 | `rr` | local | `record`'s one matching residue entry, read on the next line | keep:glance | — |

## "a body ignoring the predicate is abandoned under join_timeout, by name (§12.4(5))" — line 275

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 280 | `t0` | local | the wall-clock origin, a `t` derivative (a digit suffix, §5 R5) | keep:spec | — |
| 289 | `rr` | local | the loop writer's matching residue entry, read on the next line | keep:glance | — |
| 290 | `jt` | local | the `DeviceJoinTimeout` record, read by two further assertions | rename | `timeout` |

## "unblock! makes the blocking call return: a clean exit, no timeout (§12.4(3))" — line 300

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 305 | `t0` | local | the wall-clock origin | keep:spec | — |

## "a calling-task device runs inline and the loop moves, trajectory untouched (§11.1)" — line 353

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 363 | `ref` | local | the comparison simulation with no device attached | roster? | `ref` — "reference [comparison instance]"; ~5 sites across this group's files |

## "a device with no loop method is refused at attach!, by kind (§11.6)" — line 369

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 371 | `diag` | local | the diagnostic under test | rename | `d` |

## "gather without an output side is a contract misuse, by kind (§11.6)" — line 378

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 380 | `h` | local | the attached handle, read on the next line | keep:glance | — |
| 382 | `diag` | local | the diagnostic under test | rename | `d` |

## "a detached handle's writes refuse by name, its reads stay legal (§11.6, D-244)" — line 386

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 389 | `h` | local | the first attachment's handle, read by six later statements | rename | `handle` |
| 393 | `diag` | local | the diagnostic under test | rename | `d` |
| 395 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 401 | `h2` | local | the fresh attachment's handle | rename | `handle2` |

## "join_timeout is validated and never trajectory-determining (§12.4, D-198)" — line 407

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 411 | `diag` | local | the diagnostic under test | rename | `d` |
| 415 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |

`cap` (line 417, the `do`-block parameter) is consumed on the same line — `keep:glance`. `err` (lines 410, 414) is the roster's own spelling for a caught exception, not flagged.

## Collisions

None in this file.

## Roster proposals

- `ref` — "the comparison/reference simulation built beside the one under test." 1 site in this file (line 363); the group also sees it in `test_lifecycle.jl`, `test_roster.jl`, `test_bindings.jl` (as `ref` and `ref_val`) and `test_dataplane.jl` — ~6 sites total across this group's files, likely more elsewhere in the suite.

## Questions

- The device/binding-contract bullet says these methods' parameters are `keep:api` "at the spec's spelling." `src/devices.jl`'s own generic spells them `loop(dev::AbstractDevice, handle)`, and `test/fixtures.jl`'s `Pad`/`Panel` already use `handle`. This file's eleven fixtures instead spell them `d`/`h` throughout — every one tabled above as a rename. If the intended reading is narrower (e.g., "keep:api" applies regardless of the letter chosen, since Julia dispatch never sees these names), all thirty rows in the fixtures table collapse to `keep:api` and the count drops accordingly. Flagging because of the scale either way.
- `t = termination(sim2)` (line 269) is the only site in this file where `t` means anything but time; the same pattern recurs, much more heavily, in `test_lifecycle.jl` (5 sites) — see that report's Questions.
- `bw`, `jt` and similar entry-abbreviations (`dc`, `cfe`, `rr`) are judged by usage span: read once, right after binding, they are `keep:glance`; read again after an intervening statement, they rename. The line between the two is a judgment call the coordinator may want to settle once, suite-wide, rather than per site.

