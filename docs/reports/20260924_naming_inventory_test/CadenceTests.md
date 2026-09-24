# Naming inventory: test/CadenceTests.jl

Tip: 0c0a899. Sites flagged: 7. Renames: 1. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 0, keep:glance 5, keep:family 0, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None.

## `runonly(names::AbstractString...)` — line 93

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 94 | `fs` | local | the resolved test functions, read in the `for` loop three lines below | rename | `functions` |
| 95 | `s` | local | the test's function symbol, read twice in the next two lines | keep:glance | — |

## Collisions

None.

## Roster proposals

None.

## Questions

- `runonly`'s do-block `s` (line 95) is read twice across the do-block's three
  lines; treated as `keep:glance` on the same footing as the rule's own
  comprehension-variable and lambda-parameter examples. Flag if that reads as
  too generous for a binding read more than once.
- `live`'s `f` (line 46) and `runonly`'s for-loop `f` (line 100) hold the same
  thing (a test file's `test_*` function) as `live`'s parameter — consistent,
  no rename needed.
