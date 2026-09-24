# Naming inventory: test/test_roster.jl

Tip: 0c0a899. Sites flagged: 40. Renames: 34. Collisions: 0. Roster proposals: 1.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 0, keep:glance 1, keep:family 4, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None within this file alone. `t = Threads.@spawn run!(...)` (line 213) is the same "a Task, never time" pattern `test_lifecycle.jl` flags repeatedly — see that report's header note.

The six malformed-binding fixtures (lines 9–27: `NoSides`, `NoEnum`, `GreedyPlus`, `Sourceless`, `Drifted`, `Unwritten`) bind no names — every trait method takes an anonymous `::Type` parameter.

## "the binding conformance check names every drift at the attach point (§11.6)" — line 30

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 32 | `d` | local | the device every malformed binding is attached to, read across the whole testset | rename | `dev` |
| 33 | `b` | `for`-loop variable | one malformed binding per iteration — the family letter (R4) | keep:family | — |
| 38 | `diag` | local (loop body) | the diagnostic under test | rename | `d` |
| 44 | `diag` | local | the diagnostic under test (the output-side check, after the loop) | rename | `d` |

## "admission is three checks in spec order (§11.3)" — line 49

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 51 | `d1` | local | the first attached device, read by three later statements | rename | `dev` |
| 56 | `diag` | local | the `ClaimConflict` diagnostic | rename | `d` |
| 62 | `du` | local | the `AttachUnknownFace` diagnostic, sequential with `diag` (fully consumed first) | rename | `d` |

`err` (line 55) is the roster's own spelling for a caught exception, not flagged.

## "a device writes inside its claim, every check at its own staging (§11.3, §11.4)" — line 73

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 75 | `da` | destructured | the first device, paired with `db` | rename | `dev_a` |
| 75 | `db` | destructured | the second device, paired with `da` | rename | `dev_b` |
| 76 | `ha` | local | `da`'s handle | rename | `handle_a` |
| 77 | `hb` | local | `db`'s handle | rename | `handle_b` |
| 94 | `dw` | local | the first device's writer status, read across three further statements | rename | `status` |
| 99 | `hc` | local | the third device's handle, read on two further lines | rename | `handle_c` |

`d` (line 96, a generator variable over `dw.recent`) is the family letter — `keep:family`. `ooc` (line 96, read on the next line) is `keep:glance`.

## "the computed claim is the complement at the attach instant (§11.3, §11.6)" — line 107

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 109 | `d1` | destructured | the enumerated device | rename | `dev` |
| 109 | `g` | destructured | the greedy (GUI) device, paired with `g2` below | rename | `greedy` |
| 111 | `hg` | local | `g`'s handle, read across four further statements | rename | `greedy_handle` |
| 127 | `hring` | local | the harness diag batch's ring, read across three further statements | rename | `ring` |
| 132 | `g2` | local | the second greedy device | rename | `greedy2` |

`d` (lines 128–129, two generator variables over `hring`) is the family letter — `keep:family`.

## "the harness surface is the unclaimed complement, recomputed at roster changes (§11.3)" — line 144

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 147 | `d` | local | the device, read on two further lines | rename | `dev` |
| 156 | `cfe` | local | the harness's claimed-face entry, read on two further lines | rename | `entry` |

## "the recompilation seam: a pending harness batch is renormalized at attach (§11.4)" — line 167

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 178 | `cfe` | local | the harness's claimed-face entry, read on two further lines | rename | `entry` |
| 183 | `d2` | local | the second simulation's device | rename | `dev` |

## "device ids are monotonic per Simulation and never reused (§11.3)" — line 192

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 194 | `d1` | local | the device, read on two further lines | rename | `dev` |

`err` (line 200) is the roster's own spelling, not flagged.

## "the roster is frozen per run: attach and detach are stopped-sim operations (§11.3)" — line 206

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 209 | `d` | local | the device, read across the whole testset | rename | `dev` |
| 213 | `t` | local | the spawned `run!` task | rename | `task` |
| 219 | `e` (×2) | `catch` clause and its returned value | the exception `attach!` raised mid-run | rename | `err` |
| 219 | `err_a` | local | the caught `attach!` exception, coexisting with `err_d` | rename | `attach_err` |
| 220 | `e` (×2) | `catch` clause and its returned value | the exception `detach!` raised mid-run | rename | `err` |
| 220 | `err_d` | local | the caught `detach!` exception, coexisting with `err_a` | rename | `detach_err` |

## "the frame's outcome is a pure function of the drained batches, whoever staged them (§11.4)" — line 230

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 232 | `da` | destructured | the first device | rename | `dev_a` |
| 232 | `db` | destructured | the second device | rename | `dev_b` |
| 233 | `ha` | local | `da`'s handle | rename | `handle_a` |
| 234 | `hb` | local | `db`'s handle | rename | `handle_b` |
| 240 | `ref` | local | the directly-poked comparison simulation | roster? | `ref` — "reference [comparison instance]"; see `devices.md`'s running count |

## "an empty drain stays free with a populated roster (§11.1, §11.4)" — line 249

No flagged sites: both devices are constructed inline and never bound.

## "a populated device drain is as free as an empty one (§11.4, D-202)" — line 257

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 259 | `ha` | local | the enumerated device's handle | rename | `handle_a` |
| 260 | `hg` | local | the greedy device's handle | rename | `greedy_handle` |

## Collisions

None in this file.

## Roster proposals

- `ref` — "the comparison/reference simulation." 1 site in this file (line 240); see `devices.md` for the group's running count.

## Questions

- `da`/`db`/`ha`/`hb` (and `hc`/`hg`) recur across three testsets in this file (and again in `test_dataplane.jl`, `test_bindings.jl`). I've proposed `dev_a`/`dev_b`/`handle_a`/`handle_b`, extending the roster's `dev` and the spec's `handle` with a role letter, matching how `sim`/`sim2` is already accepted. If the coordinator prefers a different pattern for a device pair (e.g. naming by the fixture's own `"da"`/`"db"` strings), it applies uniformly across all these sites.
- `err_a`/`err_d` (line 206 testset): I read these as still flagged (single-letter role suffixes that aren't spec symbols), proposing `attach_err`/`detach_err`. If a short role suffix on the roster's `err` is acceptable, these two rows — and the parallel `run_err`/`replay_err`/`step_err` rows in `test_lifecycle.jl` — would keep their current spelling instead.
