# Naming inventory: test/test_localization.jl

Tip: 0c0a899. Sites flagged: 35. Renames: 12. Collisions: 1. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 0, keep:glance 6, keep:family 0, keep:roster 16, keep:api 0.

## Letters with more than one meaning in this file

None: `m` means "the `Group` model" everywhere it is bound in this file (six sites), never
the mode bundle field, and the rest of the flagged names below (`m2`, `mt`, `mq`, `lw`, `cb`,
`gated`, `nopol`, `noaddrs`, `pub`, `d1`/`d2`/`d3`) each occur once. See Questions for a
consistency note on `m` itself.

## "multiple crossings in one frame: earliest first, re-localized on the remainder" — line 76

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 77 | `m2` | local function | the two-stamper model (`s1`, `s2` off one `Sawtooth`), called at lines 80 and 103 | rename | `two_stamper_model` |
| 90 | `mt` | local | the tied-crossing model (`s1`, `s2` at the same level) | rename | `tied_model` |
| 108 | `lw` | local | the loop's writer status | rename | `loop_status` |
| 109 | `cb` | local | the `ChatteringBudget` report the loop's status carries | rename | `chattering_report` |

## "the gate idiom localizes; a gate flip is an epoch edge (§10.4)" — line 153

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 154 | `gated` | local function | the gated-stamper model, called at lines 157, 162 and 170 | collision | `gated_model` |

## "the two deployment keywords are validated with their siblings (§10.4)" — line 194

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 195 | `m` | local | the `Bouncer` model, read by three further diagnostics below — not glance-exempt (three assertions read it, not just the next line) | rename | `model` |
| 196 | `d1` | local | the diagnostic from a zero `localization_tol` | rename | `zero_tol` |
| 198 | `d2` | local | the diagnostic from a negative `localization_tol` — a second diagnostic in one testset is named by role, not by number | rename | `negative_tol` |
| 200 | `d3` | local | the diagnostic from a zero `localization_budget` | rename | `zero_budget` |

## "gate 3: localized frames do not allocate (§7.5)" — line 214

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 216 | `mq` | local | the quiet-frame model (no crossing in the run) | rename | `quiet_model` |
| 221 | `nopol` | destructuring | the empty `StopPolicy` fed to `frame!` as a stand-in for the advance's real one | rename | `no_policy` |
| 221 | `noaddrs` | destructuring | the empty address list fed to `frame!` alongside it | rename | `no_addrs` |
| 231 | `pub` | local | the allocation `publish!` alone costs, the baseline the last assertion compares against | rename | `publish_bytes` |

## Collisions

- `gated` (line 154, `test/test_localization.jl`): a local function defined inside the "the
  gate idiom localizes..." testset, shadowing `test/utils.jl`'s `gated(body)` for the rest of
  that scope. The file does not call the `utils.jl` helper itself, but it is reachable from
  the same `CadenceTests` scope, which the brief's flagging rule treats as enough.

## Roster proposals

None from this file.

## Questions

- `m` (lines 10, 39, 67, 123, 184) is `keep:glance` five times (bound, then read exactly once
  on the next line) and renamed to `model` once (line 195, read three times). All six bindings
  hold the same kind of thing. If the coordinator would rather have one spelling throughout
  the file regardless of glance status, all six should become `model`; as tabled, only the
  non-glance one is forced to change.
- `d1`/`d2`/`d3` (lines 196, 198, 200): renamed by role per the brief's explicit rule against
  numbered diagnostics, using the parameter and value each diagnostic's `Simulation(...)` call
  varies (`zero_tol`, `negative_tol`, `zero_budget`). If the coordinator prefers names tied to
  the deployment keyword instead of the value (e.g. `tol_zero_diag`, `tol_negative_diag`,
  `budget_zero_diag`), these read fine too.
- `fb`/`cb`/`lw` in this file and `test/test_events.jl`: see that report's Questions section —
  `loop_status` and `chattering_report`/`firing_report` should probably be ruled once, for
  both files together.
