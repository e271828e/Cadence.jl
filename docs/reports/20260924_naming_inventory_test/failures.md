# Naming inventory: test/test_failures.jl

Tip: 0c0a899. Sites flagged: 87. Renames: 37. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 13, keep:spec 28, keep:glance 3, keep:family 2, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- `s`: a rendered `showerror` string (the "rendering" testset, line 314) and a snapshot iterated in a comprehension (line 461) → the rendered-string site renamed below.
- `t`: at line 136 it holds a termination record, never time — this file has no other local `t`, so there is no in-file conflict, but it breaks rule 4's "t is time … nothing else" on its own; renamed below regardless.

## Top-level fixtures (lines 10–114): no table

`HookedInterrupter`, `LateInteger`, `LateMutable`, `LateExtraPort`, `LateMissingPort`, `ScrambledPorts`, `ScrambledRate`, `LateIntegerRate`, `LateIntegerProjection`, `DecayingBranch`, `LateSuccessor`, `LateMode`, `LateModeScalar` and their `init_x`/`init_s`/`init_m`/`output_types`/`output_state`/`state_derivative`/`state_update`/`state_projection`/`state_events`/`late_mode_guard`/`late_mode_handler`/`late_mode_scalar_handler` methods are all fixture stage methods (§the brief's carve-out). Every `::Type{T} where {T <: Real}` is `keep:typeparam` (13 sites); every destructured bundle field (`x`, `t`, `s`, `u`, `m`) is `keep:spec` (28 sites, including `state_projection`'s bare positional `x`); `HookedInterrupter`'s one-line `state_derivative(c::HookedInterrupter, …)` and the one-line `hooked_interrupted(c)` name their component `c` under R7's tiny-method glance (2 sites). None of these are arguable, so none are tabled.

## "the cursor names where execution was after a quiet frame (§13.4)" — line 117

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 121 | `cur` | local | the executor's cursor; the src ruling (README §2) already flags `cur` for rename | rename | `cursor` |

## "a throw mid-integration names the component, `state_derivative` and the stage (§13.4)" — line 127

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 130 | `e` | local | the `StepError` from `failure(() -> run!(…))`, read by five lines | rename | `err` |
| 136 | `t` | local | the termination record; `t` is reserved for time | rename | `record` |

## "a throw in a handler names the event round (§13.4)" — line 141

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 145 | `e` | local | the first `StepError`, read by three lines | rename | `err` |
| 155 | `e2` | local | the second `StepError` (a fresh sim's twin case) | rename | `err2` |

## "a bundle field missed past the probe is a `BundleFieldError` species (§13.2, §13.4, D-248)" — line 159

`d = diagnostic(e)` at line 165 matches the brief's literal carve-out; `keep:family`, not tabled.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 162 | `e` | local | the `StepError`, read by three lines | rename | `err` |

## "a throw inside boundary zero takes the catch with pointer 0 (§13.4, D-223)" — line 175

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 180 | `e` | local | the `StepError` from the boundary-zero handler firing, read by seven lines | rename | `err` |
| 190 | `ds` | local | `carried(@test_throws … step!(…))`'s `MissingInit` | rename | `step_diagnostic` |
| 192 | `dr` | local | `carried(@test_throws … run!(…))`'s `MissingInit` | rename | `run_diagnostic` |
| 212 | `e2` | local | the replay's `StepError`, read by two lines | rename | `err2` |

## "a throw in a guard trial names the localization trial (§13.4)" — line 228

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 233 | `e` | local | the `StepError`, read by four lines | rename | `err` |

## "a throw in the arrival sweep names that phase (§13.4)" — line 240

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 248 | `e` | local | the `StepError`, read by three lines | rename | `err` |

## "a throw in `state_update` or in `state_projection` names its own block (§13.4)" — line 254

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 258 | `e` | local | `Sapper`'s `StepError` | rename | `err` |
| 264 | `ep` | local | `Primer`'s `StepError`, the testset's second failure | rename | `primer_err` |

## "a failed frame is not counted, and the record ends at the last one (§13.4)" — line 270

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 273 | `e` | local | the `StepError`, read once by the immediately following `@test` line | keep:glance | — |

## "the interrupt carve-out routes to the stop path (§13.4, §12.4)" — line 278

No flagged sites needing a row.

## "an interrupt after another issuer keeps that issuer as the source (§12.1, §13.4)" — line 300

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 301 | `c` | local | the `HookedInterrupter` instance, read twice near its definition | keep:glance | — |

## "the rendering states the frame and the reproduction (§13.4, §13.2)" — line 310

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 313 | `e` | local | the `StepError`, read once by the immediately following line | keep:glance | — |
| 314 | `s` | local | the rendered `showerror` text, read by two lines | rename | `rendered` |
| 321 | `dv` | local | a `Simulation` of `diverging()` | rename | `diverging_sim` |
| 323 | `sn` | local | the diverging failure's rendered text, read by two lines | rename | `diverging_rendered` |
| 332 | `sn0` | local | the "none"-cursor `StepError`'s rendered text, read by three lines | rename | `none_rendered` |

## "the `Dual` activations reach the same carrier and cause (§13.4, §9.4)" — line 346

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 352 | `e` | local | the `Tripwire` `StepError` under `D8` | rename | `err` |
| 360 | `dv` | local | a `Simulation` of `diverging()` under `D8` | rename | `diverging_sim` |
| 362 | `en` | local | the `NonfiniteState` `StepError`, this testset's second failure | rename | `nonfinite_err` |

## "the sweep names the diverging block, never its downstream (§13.4, D-157)" — line 370

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 375 | `e` | local | the `StepError{NonfiniteState}`, read by six lines | rename | `err` |
| 377 | `d` | local | `e.cause`, the `NonfiniteState` diagnostic | keep:family | — |

## "the sweep covers a localized frame's remainder segment (§13.4, D-157)" — line 390

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 395 | `e` | local | the `StepError{NonfiniteState}`, read by five lines | rename | `err` |

## `function reproduction(model, quiet::Int)` — line 410

Top-level helper, called by `failures_pointer_twin`'s testsets below. `model`/`quiet` are full words, not flagged.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 416 | `e` | local | the failing `step!`'s exception, read by six lines and returned | rename | `err` |
| 423 | `e2` | local | the twin's reproduced exception | rename | `err2` |

## "the error's pointer reproduces the failure on a fresh twin (§13.4, §12.7)" — line 433

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 436 | `e` | local | `reproduction`'s result for the `Tripwire` case | rename | `err` |
| 441 | `en` | local | `reproduction`'s result for the diverging (`NonfiniteState`) case | rename | `nonfinite_err` |

## "`to_boundary` counts grid boundaries, not base ticks (§12.7, §13.4)" — line 446

`d = carried(@test_throws … replay!(…))` at line 474 matches the brief's literal carve-out; `keep:family`, not tabled. No other flagged sites.

## "an integer port on a late branch is refused at the write (§9.5)" — line 486

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 489 | `e` | local | the `StepError{ConformanceFailure}`, read by seven lines | rename | `err` |

## "a mutable static array on a late branch is refused at the write (§9.5, D-238)" — line 500

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 503 | `e` | local | the `StepError{ConformanceFailure}`, read by six lines | rename | `err` |

## "an extra and a missing port on a late branch are key-set failures (§9.5)" — line 513

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 516 | `e` | local | `LateExtraPort`'s `StepError` | rename | `err` |
| 524 | `e2` | local | `LateMissingPort`'s `StepError` | rename | `err2` |

## "the names are the pairing, at the port write and the state write (§9.5)" — line 531

No flagged sites needing a row.

## "an integer derivative leaf on a late branch is refused (§7.1, §9.5)" — line 545

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 548 | `e` | local | the `StepError{ConformanceFailure}`, read by five lines | rename | `err` |

## "an integer projection leaf on a late branch is refused (§9.3, §9.5)" — line 557

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 560 | `e` | local | the `StepError{ConformanceFailure}`, read by six lines | rename | `err` |

## "the constant branch embeds as a zero-partial at the write (§9.5, D-166)" — line 570

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 574 | `q` | local | the port's value, read by three lines; mirrors the fixture's port name `:q`, not a framework spec symbol | rename | `value` |

## "a discrete successor of another type on a late tick is refused (§7.3)" — line 580

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 583 | `e` | local | the `StepError{ConformanceFailure}`, read by six lines | rename | `err` |

## "a mode write of another type on the second firing is refused (§5.2, §9.5)" — line 592

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 595 | `e` | local | the `StepError{ConformanceFailure}`, read by six lines | rename | `err` |

## "a mode write that is not a NamedTuple on the second firing is refused (§5.2, §9.5)" — line 605

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 608 | `e` | local | the `StepError{ConformanceFailure}`, read by six lines | rename | `err` |

## Collisions

None: no local in this file shares a name with the import list, `utils.jl`'s helpers, `fixtures.jl`'s fixture functions, or a Base function the file calls.

## Roster proposals

None. `err`, used throughout this report's proposals, is already on the roster ("a caught exception, always `catch err`"); this file's `e = failure(() -> …)` idiom returns a caught exception exactly as much as a literal `catch e` does, so it is treated the same way here even though the brief's "five sites remain" count is explicitly about the literal `catch e` form.

## Questions

- This file's dominant pattern is `e = failure(() -> …)`, not `catch e`, and the brief's naming-rule note ("catch e is rename to err, five sites remain") is written about the literal `catch` form. This report treats the two as the same concept (both are "a caught exception") and renames every multi-read `e`/`e2`/`en`/`ep` to `err`-based names; a single-read `e` is left as `keep:glance` (lines 273, 313) since a single letter's glance eligibility does not depend on which idiom produced it. If the coordinator reads the ruling more narrowly (only literal `catch e` counts), most of this file's renames would need to be reconsidered.
- Two `e`-glance sites (lines 273, 313) are read only once and immediately, so they pass R7/the throwaway-`@test` rule on their own terms, even though the same letter is renamed everywhere else in the file for the identical concept. Tabled as arguable for that reason; the coordinator may prefer renaming them too for file-wide consistency.
- `d = e.cause` (line 377) is a third shape of "the diagnostic under test," alongside the brief's `carried(@test_throws …)` and `diagnostic(failure(…))`. Treated as `keep:family` here; flagging in case the coordinator wants the carve-out read more narrowly (matches the same question raised in `diagnostics.md`).
- `dv`/`diverging_sim` and `en`/`nonfinite_err` each recur in two different testsets with the same meaning; proposed once, consistently, in case the coordinator wants a single ruling covering both sites.

