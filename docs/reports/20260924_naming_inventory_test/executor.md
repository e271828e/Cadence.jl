# Naming inventory: test/test_executor.jl

Tip: 0c0a899. Sites flagged: 13. Renames: 5. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 2, keep:typeparam 0, keep:spec 0, keep:glance 3, keep:family 0, keep:roster 3, keep:api 0.

## Letters with more than one meaning in this file

None found in this file.

## "the phase-body roster is fixed and total (§9.7)" — line 10

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 12 | `b` | local | the phase bodies `phase_bodies(sim)` returns | rename | `bodies` |
| 27 | `mot` | local | a second `Simulation`, testing `Motor`'s one-stage-1-block return | rename | `motor_sim` |
| 28 | `b` | local | the phase bodies of the Motor simulation | rename | `bodies` |

(`sim` at line 11 is `keep:roster`, not tabled; `e` at line 30 is a lambda parameter consumed within the same `count(...)` call, `keep:glance`, not tabled.)

## "the chunk walk is allocation-free at any width (§9.7)" — line 39

No tabled rows. `six` (line 44) is a plain descriptive word, not an abbreviation. The two `i`s inside the `ntuple` lambdas (line 44) play a position-index role, `keep:index`; the `_` in the third `ntuple` lambda is `keep:glance`. `sim` (line 46) is `keep:roster`.

## "the event and projection callables ride with the four blocks (§9.7)" — line 56

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 59 | `b` | local | the phase bodies | rename | `bodies` |
| 62 | `ev` | local | the `("saw", :wrap)` event, read by three assertions | rename | `event` |

(`sim` at line 57 is `keep:roster`; `f` at line 65 is a `for`-loop variable consumed on the one line inside the loop body, `keep:glance`.)

## Collisions

None.

## Roster proposals

None.

## Questions

- `mot` (line 27) plays the same "second value of one type, named by role" part the brief's `sim`/`sim2` example covers, but spells the role as a content-based abbreviation instead of a number. I propose `motor_sim` (full word plus the roster's `sim`) rather than `sim2`, since this second simulation is not interchangeable with the first — it exists specifically to exercise `Motor`'s single-`StageEntry` return — but the coordinator may prefer the plainer numbered form for consistency with other files.
