# Naming inventory: test/test_continuous.jl

Tip: 0c0a899. Sites flagged: 13. Renames: 3. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 10, keep:glance 0, keep:family 0, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- None.

## "a simulation owns one executor, and it is the one the loop runs (§9.2, §9.7)" — line 24

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 26 | `ex` | local | the simulation's executor | rename | `exec` |

## "a loop closed through a state-vector port integrates like the scalar one (§5.3)" — line 103

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 110 | `a` | local | the simulation over `vector_feedback_model` (the state-vector port) | rename | `vector_sim` |
| 111 | `f` | local | the simulation over `feedback_model` (the scalar comparison) | rename | `scalar_sim` |

## Collisions

None in this file.

## Roster proposals

None in this file.

## Questions

None beyond what `assembly.md` already raises about `ex`'s roster spelling
(`exec`, confirmed by the README's roster-proposals table) and the rule 6
`path`/`build` exception, neither of which recurs in this file.
