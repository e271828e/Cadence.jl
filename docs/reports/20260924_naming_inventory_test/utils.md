# Naming inventory: test/utils.jl

Tip: 0c0a899. Sites flagged: 15. Renames: 2. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 0, keep:glance 12, keep:family 0, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- `e`: an entry, in the `walked`/`gated` comprehensions (two sites) — a caught
  exception in `failure` → the exception site renamed to `err` below.

## `failure(f)` — line 41

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 41 | `f` | parameter | the callable under test, called once; the try/catch puts the method at 7 lines, past the glance clause's "about five" | keep:glance | — |
| 45 | `e` | catch | the caught exception, returned as the diagnostic value | rename | `err` |

## `writer_status(snap, who::String)` — line 58

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 58 | `snap` | parameter | the snapshot whose writer record is looked up | rename | `snapshot` |

## Collisions

None.

## Roster proposals

None.

## Questions

- `failure`'s `f` is kept as `keep:glance` although its try/catch body puts the
  method at 7 lines, past rule 2's "about five" — the extra lines are the catch
  and its one-line return, not further uses of `f` (still called exactly once).
  Flag if the coordinator wants it renamed regardless.
