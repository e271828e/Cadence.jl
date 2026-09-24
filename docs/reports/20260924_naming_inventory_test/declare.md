# Naming inventory: test/test_declare.jl

Tip: 0c0a899. Sites flagged: 4. Renames: 4. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 0, keep:glance 0, keep:family 0, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None found in this file.

## "the wrappers are plain data over exact rationals (D-185)" — line 13

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 19 | `d1` | local | the diagnostic `Period(0.02)`'s inexact-float throw carries | rename | `d` |
| 21 | `d2` | local | the diagnostic `Hz(0.5)`'s inexact-float throw carries | rename | `d` |
| 23 | `d3` | local | the diagnostic `Absolute(Hz(50), 0.001)`'s inexact throw carries | rename | `d` |
| 25 | `d4` | local | the diagnostic `Absolute(1//50)`'s not-a-quantity throw carries | rename | `d` |

(The other two testsets, "the bundle law (§5.2)" and "a foreign binding of a family name is the forgotten import (§8.1, D-246)", bind no locals: every argument is a literal or a direct call result read inline, so they contribute no sites and get no table.)

## Collisions

None.

## Roster proposals

None.

## Questions

- Lines 19–25 read four independent, sequential diagnostics: each is bound, checked on the very next line, and never touched again or compared to a sibling. Since none of them needs to coexist with another, I propose collapsing all four to the plain family letter `d` (rebinding it four times, the idiom `test_build.jl` uses throughout for this exact "the diagnostic in an assertion" pattern) rather than reading them as roles under "a second diagnostic is named by role" — there is no second diagnostic in play here, just four non-overlapping first ones.
