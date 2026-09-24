# Naming inventory: test/test_dataplane.jl

Tip: 0c0a899. Sites flagged: 14. Renames: 4. Collisions: 0. Roster proposals: 1.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 1, keep:glance 3, keep:family 2, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None. The fixtures (`two_root_inputs`, `chain3`, `wide_root_inputs`, `wide_zero`) bind no site the rules reach beyond loop indices and one-glance parameters.

## "a staged batch lands at its frame top, and nowhere earlier (§11.1, §11.4)" — line 17

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 29 | `ref` | local | the directly-poked comparison simulation | roster? | `ref` — "reference [comparison instance]"; see `devices.md`'s running count |

## "every check runs at staging, on the writer's side; the drain is pure (§11.4)" — line 68

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 82 | `hw` | local | the harness's writer status, read across three further statements | rename | `status` |

`d` (lines 85, 87, generator variables over `hw.recent`) is the family letter — `keep:family`. `ooc` (line 85) and `etm` (line 87), each read on the next line only, are `keep:glance`.

## "publication: one immutable value per frame-top boundary (§11.2)" — line 99

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 106 | `snap` | local | the frame-5 snapshot, read across five further statements | rename | `snapshot` |
| 123 | `simo` | local | the off-tick deployment's simulation | rename | `offtick_sim` |
| 103 | `snap0` | local | the boundary-zero snapshot, read on the next line only | keep:glance | — |

`y5` (line 117, `port(snap, "p", :y)`) is a `y` derivative with a digit suffix, matching `y1`/`y2` — `keep:spec`, not arguable.

## "the exchange is wait-free and coherent: no reader ever sees a torn world (§11.2)" — line 129

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 135 | `s` | local (task body) | the reader's latest observed snapshot, read on four further lines | rename | `snapshot` |
| 134 | `tprev` | destructured | the previous snapshot's time, a `t` derivative fused with a whole word rather than one of rule 4's listed suffixes | keep:spec | — |

## "staging from another task: the CAS merge loses nothing it shouldn't (§11.4)" — line 157

No flagged sites: `writer` and `i` (the spawned task and its loop index) are compliant.

## `wide_root_inputs`/`wide_zero` — lines 199–207

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 199 | `n` | parameter (`wide_root_inputs(n)`) | the surface's width, read three times in one expression | keep:glance | — |
| 206 | `n` | parameter (`wide_zero(n)`) | the surface's width, read once | keep:glance | — |

## "a wide surface stages, merges and drains like a narrow one (§11.4, D-202)" — line 210

No flagged sites: `dense` (the local closure) is a full word, and its internal `i` is a comprehension index.

## Collisions

None in this file.

## Roster proposals

- `ref` — "the comparison/reference simulation." 1 site in this file (line 29); see `devices.md` for the group's running count.

## Questions

- `n` (`wide_root_inputs`/`wide_zero`) spells no spec symbol (R5: "`n` spells no spec symbol," `n_ok`/`n_i` rename). Read narrowly, that ruling is about compounds like `n_ok`; read broadly, it would flag bare `n` here too, since it is not one of the reserved index/type-param/spec-symbol uses and is read three times in `wide_root_inputs`. I've kept both under R7's glance clause (short functions, `n` consumed within one expression) but flagged the tension.
- `tprev` fuses the time spec symbol with a whole word ("prev") rather than one of rule 4's listed suffixes (`buf`, `store(s)`, `next`, `_off(s)`, `_r`, `b`). I've read "a suffix or word" as open-ended and kept it, parallel to `xnext`, but it is the one clearly arguable call in this file.
