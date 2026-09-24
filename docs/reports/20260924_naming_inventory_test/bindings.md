# Naming inventory: test/test_bindings.jl

Tip: 0c0a899. Sites flagged: 39. Renames: 27. Collisions: 0. Roster proposals: 2.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 0, keep:glance 7, keep:family 3, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None. `d`/`h` in `Telemetry`'s and `Poller`'s contract methods are the same "wrong spec spelling" pattern as `test_devices.jl` — see that report's first Question.

## The `Telemetry`/`Poller` fixtures — lines 13–65

`Telemetry`'s and `Poller`'s `loop` methods extend `src/devices.jl`'s `loop(dev::AbstractDevice, handle)`; neither spells its parameters that way.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 17 | `d` | parameter (`loop(d::Telemetry, h)`) | the device | rename | `dev` |
| 17 | `h` | parameter (`loop(d::Telemetry, h)`) | the handle | rename | `handle` |
| 19 | `snap` | local | the observed snapshot, read on the next line | rename | `snapshot` |
| 54 | `d` | parameter (`loop(d::Poller, h)`) | the device | rename | `dev` |
| 54 | `h` | parameter (`loop(d::Poller, h)`) | the handle | rename | `handle` |
| 59 | `f` | destructured (`(f, v) = first(pairs)`) | the staged face, read by `Symbol(f)` inside the `while` | rename | `face` |
| 59 | `v` | destructured (`(f, v) = first(pairs)`) | the staged value, read inside the `while` | rename | `value` |
| 61 | `snap` | local | the observed snapshot, read on the next line | rename | `snapshot` |

`Poller(datum) = Poller(datum, false)` (line 53) already keeps `datum`, `map_input`'s own spelling. `pairs` (line 57) is not flagged: this file never calls `Base.pairs`.

## "TableBinding construction validates the table's shape (§11.6)" — line 68

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 70 | `diag` | local | the diagnostic under test | rename | `d` |
| 74 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 78 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 82 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 86 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |

`err` (lines 69, 73, 77, 81, 85) is the roster's own spelling, not flagged — five sequential rebinds, none simultaneous.

## "the input side is declared and the claim is the table's face set (§11.6)" — line 91

`b` (line 92, the `TableBinding` under test, read by four further calls) is the family letter — `keep:family`, not tabled.

## "the conditioning: deadzone rescales, expo attenuates, endpoints fixed (§11.4)" — line 103

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 108 | `val` | local function | the closure computing one channel's conditioned level, called by every assertion below | rename | `value` |

`b` (line 104) is the family letter — `keep:family`. `x` (line 126, `[val((; stick = x)) for x in -1.0:0.05:1.0]`) is a comprehension variable — `keep:glance`.

## "map_input is sparse over the datum, and an unknown channel is drift (§11.4, §11.6)" — line 134

`b` (line 135) is the family letter — `keep:family`, not tabled. `err` (line 142) is the roster's own spelling.

## "the loop idiom end to end: poll → map_input(binding(handle)) → stage! (§11.6)" — line 146

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 158 | `ref` | local | the directly-staged comparison simulation | roster? | `ref` — "reference [comparison instance]"; see `devices.md`'s running count |
| 160 | `ref_val` | local | the reference simulation's conditioned stage value | roster? | `ref_value` — same `ref` proposal, plus `val` → `value` |

`h` (line 148, read on the next line only) is `keep:glance`.

## "the output side completes the conformance check, both directions (§11.6)" — line 177

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 179 | `diag` | local | the diagnostic under test | rename | `d` |
| 181 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 183 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 185 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |

## "reads resolve at attach: binding drift fails there, never on the wire (§11.2, §14.4)" — line 190

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 192 | `diag` | local | the diagnostic under test | rename | `d` |
| 198 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 200 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 202 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |
| 204 | `diag` | local | the diagnostic under test (rebound) | rename | `d` |

`h` (line 207) is bound and never read again — `keep:glance`. The `v =`/`alt =`/`raw =`/`cmd =` names inside every `Readout(...)` call are the binding's own selector labels, not locals.

## "the compiled gather: wait → gather → map_output on the device task (§11.2, §12.3)" — line 213

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 216 | `h` | local | the attached handle, read once more nine lines down, past several intervening statements | rename | `handle` |

`nt` (lines 224, 225, comprehension variables; line 232, read on the next line only) is `keep:glance` at all three sites.

## "gather without an output side is a contract misuse, by name (§11.6)" — line 236

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 240 | `diag` | local | the diagnostic under test | rename | `d` |

`h` (line 238, read on the next line only) is `keep:glance`.

## "a bidirectional binding composes both halves (§11.6)" — line 244

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 246 | `h` | local | the attached handle, staged then gathered on two further lines | rename | `handle` |
| 251 | `nt` | local | the gathered readout, read by two further assertions | rename | `readout` |

## Collisions

None in this file.

## Roster proposals

- `ref` — "the comparison/reference simulation." 2 sites in this file (`ref`, `ref_val`); see `devices.md` for the group's running count.

## Questions

- Same device/binding-contract `keep:api`-at-spec-spelling question as `devices.md`; `Telemetry`'s and `Poller`'s `loop` methods are two more sites in the same pattern.
- `val` (line 108): a test-local helper function, so the brief's "words in full, no API name shared" bullet applies to it directly, not just to its parameters. I've proposed `value`; if the coordinator reads that bullet as reaching parameters only, `val` stands and only its parameter (already `datum`) is in scope.
- `h` at line 216 is read only once, but nine lines and several statements after it binds. I've called that a rename (the gap breaks "one glance"), unlike the same pattern at lines 148, 207 and 238, where the single read follows immediately. The coordinator may want one rule for "read once, but not soon" sites rather than a per-site call.
