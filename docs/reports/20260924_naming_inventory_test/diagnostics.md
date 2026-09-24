# Naming inventory: test/test_diagnostics.jl

Tip: 0c0a899. Sites flagged: 74. Renames: 26. Collisions: 1. Roster proposals: 0.
Kept without a row: keep:index 3, keep:typeparam 1, keep:spec 0, keep:glance 31, keep:family 7, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- `d`: a diagnostic (the family letter, throughout the diagnostic-kind and rendering testsets) and a device (the `Parser`/`LateReporter`/`Ticker` `loop` methods' first parameter) → the device sites renamed below.
- `e`: a caught exception (`catch e` in `Parser`'s `loop`) and a `DiagnosticError` carrier under test (the rendering testset's `e`) → both renamed below, to `err` and `carrier` respectively.
- `w`: a writer-status record (`for w in st0.writers`, "the status" testset) and a warning diagnostic (the rendering testset's `w`) → the warning site renamed below.

## `function loop(d::Parser, h)` — line 15

`Parser` extends the device contract (`loop(dev::AbstractDevice, handle)`, `src/devices.jl`); the method is 15 lines, past R7's glance threshold, and `d` doubles as this file's diagnostic family letter.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 15 | `d` | parameter | the `Parser` device | rename | `dev` |
| 15 | `h` | parameter | the device handle | rename | `handle` |
| 22 | `e` | `catch` | the caught `ArgumentError` | rename | `err` |

## `function loop(d::LateReporter, h)` — line 37

Five body lines: `handle` fits R7's tiny-method glance; `d` still breaks the file's one-meaning rule regardless of size.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 37 | `d` | parameter | the `LateReporter` device | rename | `dev` |
| 37 | `h` | parameter | the device handle, read twice in a 5-line method | keep:glance | — |

## `function loop(d::Ticker, h)` — line 50

Same shape as `LateReporter`'s `loop`.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 50 | `d` | parameter | the `Ticker` device | rename | `dev` |
| 50 | `h` | parameter | the device handle, read three times in a ~4-line method | keep:glance | — |

## "a bad datum is tolerated: catch, stage nothing, report, continue (§11.6)" — line 59

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 62 | `hp` | local | the `Parser`'s handle, read once 20 lines later | rename | `handle` |
| 75 | `carried` | local | whether the cause survived in some snapshot's `recent`; shares the name of `utils.jl`'s `carried` | collision | `survived` |

## "the ring's bound is the rate limit: 16 retained, excess to the counts (§11.8)" — line 86

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 94 | `mw` | local | the `Pad`'s writer-status record | rename | `writer` |

## "the status: the delta rides one snapshot, totals ride every one (§11.8, §11.2)" — line 115

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 117 | `h` | local | the `Pad`'s handle, read once 13 lines later | keep:glance | — |
| 133 | `dw` | local function | the device's writer-status record, by snapshot | rename | `writer` |

## "liveness: heartbeat and task_state ride the device's record (§11.8, §12.2, §12.4)" — line 144

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 151 | `tw` | local | the `Ticker`'s writer-status record | rename | `writer` |

## "the cell is kind-generic: mixed rings, per-kind suppression (§11.8, §13.2)" — line 181

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 185 | `a` | local | a `KindCounts` bumped with `malformed` then `crash` | rename | `left` |
| 186 | `b` | local | a `KindCounts` bumped with `malformed` | rename | `right` |

## "the heartbeat rides in the cell, stored by the handle primitives (§11.8, §12.2)" — line 224

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 226 | `h` | local | the `Pad`'s handle, read five times | rename | `handle` |
| 233 | `hb` | local | the heartbeat read before `running(h)` | rename | `heartbeat` |

## "diagnostic kinds (§13.2, Appendix C, D-214, D-215)" — line 248

The `for d in occurrences` loop and the `only(d for d in occurrences if …)` generators (lines 587, 598, 608, 616) all bind `d` to one `Diagnostic`, consistent with rule 4's family letter; not tabled. `T` at line 627 (`Set(T for T in subtypes(Diagnostic) …)`) plays a type parameter's part (R9) and is not tabled either.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 608 | `m` | local | the anchor-offset refusal's rendered message, read by five `@test` lines | rename | `rendered` |
| 616 | `m` | local | the `GridUtilization` advisory's rendered message, read by two `@test` lines | rename | `rendered` |

## "rendering: the carrier compiler-style, the didactic style (§13.1, §13.2)" — line 638

This is the suite's one deliberate `occursin`-on-rendering exception (§13.2's carve-out). Most `m = message(...)` sites here are consumed by the single `@test` line that follows and nothing else (`keep:glance`, ~24 sites, not tabled); the ones read by more than one downstream line are tabled below. `d` at lines 667 and 839 binds a `Diagnostic` directly (not via `carried`/`diagnostic(failure(…))`) but still fits rule 4's "d is a diagnostic … nothing else"; tabled as arguable since it is a new construction pattern, not the brief's two literal examples.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 641 | `e` | local | the `DiagnosticError` carrying 4 diagnostics, no warning | rename | `carrier` |
| 658 | `w` | local | the one build warning (`TrimCommitResiduals`); shares no name but `warnings` (plural) is reachable, so kept distinct | rename | `warning` |
| 659 | `ew` | local | the same 4 diagnostics plus the warning | rename | `with_warning` |
| 660 | `wlines` | local | `ew`'s rendered lines; fuses two words | rename | `warning_lines` |
| 667 | `d` | local | the fail-fast site's single `Diagnostic` | keep:family | — |
| 672 | `dwlines` | local | the fail-fast carrier's rendered lines, with the warning appended; fuses three words | rename | `fail_fast_lines` |
| 698 | `m` | local | `MissingProbeValue`'s message, read by two `@test` lines | rename | `rendered` |
| 732 | `bfe` | local function | a `BundleFieldError`'s rendered message, by field/reason | rename | `bundle_field_message` |
| 746 | `m` | local | `UserCodeFraming`'s message, read by two `@test` lines | rename | `rendered` |
| 790 | `m` | local | the real cycle's message, read by two `@test` lines | rename | `rendered` |
| 796 | `m` | local | the artificial cycle's message, read by three `@test` lines | rename | `rendered` |
| 832 | `m` | local | `UninitializedInputs`'s message, read by two `@test` lines | rename | `rendered` |
| 839 | `d` | local | the `TrimCommitResiduals` warning under `logline` | keep:family | — |

## Collisions

- `carried` (line 75, testset "a bad datum is tolerated"): a local boolean shares the name of `test/utils.jl`'s `carried(p::Test.Pass)`. Not called in this file (the file uses `accounted` instead), but reachable through `include`; the local is proposed as `survived`.

## Roster proposals

None: no recurring non-roster abbreviation earned a fresh proposal here. `h`/`hp`/`mw`/`tw` are single- or double-letter handle/writer abbreviations; single letters cannot join the roster (rule 2 reserves single letters for five closed uses), and the doubled ones are proposed as the full words `handle`/`writer` instead of new roster entries.

## Questions

- `loop`'s second parameter is spelled `handle` only in `test/fixtures.jl`'s unused-parameter stubs (`Pad`, `Panel`); every device across the whole suite that actually uses it — including all three devices here — spells it `h`, and the device parameter itself is `d` everywhere rather than `src/devices.jl`'s `dev`. This report renames both per-site (to `dev`/`handle`, or keeps `h` where the method is short enough for R7's glance), but the same pattern recurs in essentially every other group's file (`test_devices.jl`, `test_bindings.jl`, `test_lifecycle.jl`, `test_trace.jl`, …). Worth a single suite-wide ruling rather than per-group renames that might disagree at the merge.
- The brief's "diagnostic under test" carve-out gives two literal patterns (`d = carried(@test_throws …)`, `d = diagnostic(failure(…))`). This file also binds `d` via direct `Diagnostic` construction (lines 667, 839) and via `for`/generator iteration over a list of diagnostics (lines 587, 598, 608, 616, 77, 97, 216). All fit rule 4's broader "d is a diagnostic … nothing else" and are treated as `keep:family` here; flagging in case the coordinator wants the carve-out read more narrowly.
- `mw`, `tw`, and the local function `dw` all become `writer` under this report's proposal (each in a different testset scope, so no in-file collision), consolidating three ad hoc device-writer abbreviations into one word. Flagging the consolidation in case the coordinator prefers distinct names instead.

