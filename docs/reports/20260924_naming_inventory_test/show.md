# Naming inventory: test/test_show.jl

Tip: 0c0a899. Sites flagged: 7. Renames: 1. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 2, keep:typeparam 0, keep:spec 0, keep:glance 4, keep:family 0, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- None: `x` (the `plain`/`compact` parameter and the two print-target for
  loops) consistently holds "the object under print," and `k` is always a
  hyperperiod-chart index.

## "Schedule: the rows and the hyperperiod chart (§9.2, D-257)" — line 130

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 138 | `L` | local | the hyperperiod length in base ticks, `lcm` of the rows' `D` divisors | rename | `hyperperiod` |

## Collisions

None in this file.

## Roster proposals

None in this file.

## Questions

- `L` (line 138) has no established spec symbol in the file's own
  vocabulary beyond the prose noun "hyperperiod"; I propose `hyperperiod`
  for lack of a shorter spec-fixed alternative (e.g. an `L_hyper`-style
  symbol) — flag in case the design docs use a different term for it.
