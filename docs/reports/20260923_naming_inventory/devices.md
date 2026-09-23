# Naming inventory: src/devices.jl

Tip: f64b9f3. Sites flagged: 46. Renames: 32. Collisions: 1. Roster proposals: 3.

## Letters with more than one meaning in this file

- `h`: the device handle in every handle primitive; `h` is the spec's continuous step → all renamed below
- `s`: a snapshot (`gather`, `_tail!`), a suppressed count (`_residue!`) → all renamed below
- `t`: a device task (`_tail!`); `t` is time, and `s.t` on the next lines of the same loop reads the snapshot's time → renamed below
- `e`: a roster entry in every run-bracket helper → all renamed below
- `d`: a diagnostic value (`report!`, `_residue!`); `d` belongs to `diagnostics.jl` → renamed below

## `_request_stop!(ctl::Control, issuer::Union{Symbol,String})` — line 79

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 79 | `ctl` | param | the simulation's control surface | rename | `control` (the `Simulation` field's name; see Questions for the roster alternative) |

## `assert_stopped(ctl::Control, op::Symbol)` — line 91

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 91 | `ctl` | param | the control surface | rename | `control` |
| 91 | `op` | param | the refused service call's name | roster? | `op` (the `ServiceLifecycle` payload field it fills) |

## `assert_configurable(ctl::Control, op::Symbol)` — line 96

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 96 | `ctl` | param | the control surface | rename | `control` |
| 96 | `op` | param | the refused service call's name | roster? | `op` |
| 97 | `lc` | local | the lifecycle state loaded | rename | `status` (`lifecycle` is a function, `sim.jl:323`; `status` is the payload field it fills) |

## `_assert_attached(h::DeviceHandle)` — line 139

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 139 | `h` | param | the device handle | rename | `handle` (the contract's `loop(dev, handle)` spelling; `h` is the spec's step) |

## `loop(dev::AbstractDevice, handle)` — line 165

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 165 | `dev` | param | the device | roster? | `dev` (the spec's contract signature, §11.6: `loop(dev, handle)`) |

## `running(h::DeviceHandle)`, `stop!(h::DeviceHandle)`, `binding(h::DeviceHandle)`, `latest(h::DeviceHandle)` — lines 184, 195, 207, 215

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 184, 195, 207, 215 | `h` | param (×4) | the device handle | rename | `handle` (the docstrings already say `running(handle)`, `stop!(handle)`, …) |

## `stage!(h::DeviceHandle, pairs::Pair...)` — line 228

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 228 | `h` | param | the device handle | rename | `handle` |
| 228 | `pairs` | param | the author's face ⇒ value entries | collision | `entries` (`Base.pairs`; not called in the scope; matches `_normalize`'s proposed name in `dataplane.jl`) |

## `gather(h::DeviceHandle, s::Snapshot)` — line 248

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 248 | `h` | param | the device handle | rename | `handle` |
| 248 | `s` | param | the snapshot read | rename | `snapshot` (the docstring's `gather(handle, snap)` would follow) |

## `report!(h::DeviceHandle, d::MalformedDatum)` — line 272

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 272 | `h` | param | the device handle | rename | `handle` |
| 272 | `d` | param | the author's bad-datum diagnostic | rename | `occurrence` (as proposed for `_report!` in `dataplane.jl`; `d` belongs to `diagnostics.jl`) |

## `wait_next_snapshot(h::DeviceHandle)` — line 288

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 288 | `h` | param | the device handle | rename | `handle` |
| 290 | `ctl` | local | the control surface | rename | `control` |

## `_shutdown!(e::RosterEntry)` — line 307

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 307 | `e` | param | the roster entry | rename | `entry` |
| 310 | `err` | catch | the exception `shutdown!` threw | roster? | `err` (`error` is Base's; see Roster proposals) |

## `_unblocks(dev::AbstractDevice)` — line 332

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 332 | `dev` | param | the device | roster? | `dev` |

## `_wrap(e::RosterEntry)` — line 335

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 335 | `e` | param | the roster entry, read over 20 lines | rename | `entry` |
| 338 | `err` | catch | the loop body's exception | roster? | `err` |

## `_init_devices!(sim)` — line 375

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 375 | `sim` | param | the simulation | keep:roster | — |
| 377 | `e` | for | a roster entry | rename | `entry` |
| 378 | `ok` | local | whether `init!` returned | rename | `initialized` |
| 381 | `err` | catch | `init!`'s exception | roster? | `err` |

## `_spawn!(entries::Vector{RosterEntry})` — line 395

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 396 | `e` | for | a roster entry | rename | `entry` |
| 399 | `e` | comprehension | a roster entry | keep:glance | — (`entry` if the loop above takes it, for one name per function) |

## `_finish!(sim)` — line 407

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 407 | `sim` | param | the simulation | keep:roster | — |
| 408 | `ctl` | local | the control surface | rename | `control` |

## `_tail!(sim, entries::Vector{RosterEntry}, tasks::Vector{Task})` — line 432

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 432 | `sim` | param | the simulation | keep:roster | — |
| 433 | `e` | for | a spawned entry | rename | `entry` |
| 436 | `err` | catch | `unblock!`'s exception | roster? | `err` |
| 442 | `e` | for destructure | a spawned entry | rename | `entry` |
| 442 | `t` | for destructure | the entry's task | rename | `task` (`t` is time; `s.t` three lines on is a time) |
| 448 | `s` | local | the latest snapshot | rename | `snapshot` |

## `_sweep_tail!(sim)` — line 469

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 469 | `sim` | param | the simulation | keep:roster | — |
| 472 | `e` | for | a roster entry | rename | `entry` |

## `_residue!(out::Vector{ResidueRecord}, who::String, a::WriterAccount)` — line 486

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 486 | `out` | param | the residue list appended to | rename | `residue` (the caller's name for it) |
| 486 | `a` | param | the writer's account | rename | `account` (as proposed for `_fold!` in `dataplane.jl`) |
| 488 | `r` | local | the writer's residue record | rename | `record` |
| 490 | `d` | for | a residual diagnostic value | rename | `occurrence` |
| 493 | `s` | local | the suppressed-occurrence total | rename | `suppressed_count` |

## Collisions

- line 228, `pairs` in `stage!(h, pairs...)`: `Base.pairs`; not called in `stage!`. The name is also the public signature's parameter; the docstring spells the call `stage!(handle, "face" => value, ...)`, so the rename is invisible to callers.

## Roster proposals

- `dev`: 2 sites here (lines 165, 332), abbreviating "device". The spec's contract spells `init!(dev)` and `loop(dev, handle)` (spec lines 6340–6341), `RosterEntry` carries the field `dev`, and `sim.jl` has about 20 lines using it. `device` is taken in the file's vocabulary for the device's id string (`_normalize`'s keyword, `DeviceContractMismatch`'s `device` field), so the roster form keeps the two apart.
- `err`: 4 sites here (lines 310, 338, 381, 436), abbreviating "error"; the full word is `Base.error`. `sim.jl` has about 22 more lines using it.
- `op`: 2 sites here (lines 91, 96), abbreviating "operation", the refused service call's name. It fills `ServiceLifecycle`'s `op` field, and the word recurs in `diagnostics.jl`, `conditions.jl`, `trim.jl`, `build.jl` and `sim.jl`.

## Questions

- `ctl` is a field of `DeviceHandle` (line 130) and a local in `sim.jl` about 29 times. The table renames the locals to `control`, which no function takes. If the user prefers one spelling for field and local, `ctl` is the other candidate for the roster; this report does not propose it because `control` is short and free.
- `stop!(h::DeviceHandle)` and `latest(h::DeviceHandle)` share their functions with `stop!(sim)` and `latest(sim)` in `sim.jl`. "Every method names its parameters alike" cannot hold across a handle and a simulation; the table names each by what it holds.
- `gather(h::DeviceHandle, s::Snapshot)` is a method of the same function as `store.jl`'s cell `gather` and `readers.jl`'s `gather(::Reader, ::Executor)`. Three meanings under one name is a function-naming question the local rules do not reach.
- The docstrings at lines 237 and 242 spell `gather(handle, snap)`; if `snap` stays off the roster, they should read `snapshot` with the parameter.
