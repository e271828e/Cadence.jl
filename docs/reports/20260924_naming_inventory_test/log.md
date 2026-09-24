# Naming inventory: test/test_log.jl

Tip: 0c0a899. Sites flagged: 46. Renames: 15. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 1, keep:typeparam 0, keep:spec 4, keep:glance 13, keep:family 0, keep:roster 12, keep:api 0.

## Letters with more than one meaning in this file

- `s`: the logged `Snapshot` in every `for s in ...` comprehension and the line-16 lambda
  (`keep:glance`, 12 sites) — vs. a bound `Simulation` in the local helper `mk` (line 102)
  and the `foreach` lambda comparing view policies (line 107), both renamed to `sim`.
- `t`: never bound as the spec's time symbol in this file — the meaning only ever appears
  behind a field access (`s.t`, `t★`). The one bound site (line 130) holds a spawned `Task`,
  which the rule "`t` is time, never a tier" leaves no room for; renamed to `task`.
- `c`: a `Simulation` under the "thinned" view policy in the `a, b, c` triple (line 106) —
  vs. a fragment/condition value passed to `init!` (line 144). Both are renamed below
  (`thinned` and `cond` respectively), so the conflict does not survive the sweep.

## "every boundary publishes: t* included, boundary-consistent (§11.2, §10.6)" — line 8

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 16 | `i` | local | the index of the snapshot published at `t★`, read again at lines 23–24 | keep:index | — |

## "view policies, never trajectory-determining (§11.2)" — line 98

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 101 | `mk` | local function | builds and initializes a `Simulation` under one view policy | rename | `session` |
| 102 | `s` | local (inside `mk`) | the `Simulation` `mk` returns; not glance-exempt because `s` also means a logged `Snapshot` in this file | rename | `sim` |
| 106 | `a` | destructuring | the default-policy `Simulation` | rename | `full` |
| 106 | `b` | destructuring | the `log = false` `Simulation` | rename | `unlogged` |
| 106 | `c` | destructuring | the `log_every = 7, log_max = 3` `Simulation` | rename | `thinned` |
| 107 | `s` | lambda parameter (`foreach`) | each of `a`, `b`, `c` in turn; same conflict as line 102 | rename | `sim` |
| 108 | `qa` | local | the reference position `q`, from the default policy, compared against `b` and `c`'s | rename | `q_ref` |
| 111 | `ca` | local | the reference event count, from the default policy, compared against `b` and `c`'s | rename | `count_ref` |

## "logged is a stopped-sim read behind the §11.3 gate" — line 125

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 130 | `t` | local | the spawned task running `run!` | rename | `task` |
| 134 | `e` | `catch` | the exception `logged` raises mid-run; every other site of this idiom in the suite binds `err` | rename | `err` |

## "the retention keywords are validated with their siblings (§11.2)" — line 142

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 144 | `c` | local | the fragment/condition passed to every `init!` call in the testset | rename | `cond` |
| 147 | `d1` | local | the `ArgumentInvalid` from an invalid `log` | rename | `d` |
| 149 | `d2` | local | the `ArgumentInvalid` from an invalid `log_every`; fully read before `d1`'s successor is bound, so this is sequential reuse, not coexistence | rename | `d` |
| 151 | `d3` | local | the `ArgumentInvalid` from a zero `log_max` | rename | `d` |
| 153 | `d4` | local | the `ArgumentInvalid` from a fractional `log_max` | rename | `d` |

## Collisions

None from this file.

## Roster proposals

None from this file; see the Questions below on `cond`.

## Questions

- `d1`/`d2`/`d3`/`d4` (lines 147–153) are exactly the pattern the brief rules out as a role
  name ("`d2` is not a role"). Each is fully read before the next is bound, so they are
  sequential reuse like every other multi-diagnostic testset in this group's files; all four
  are proposed as plain `d`.
- `c = fragment(inputs = (in = 0.0,))` (line 144) can't take the spec's own noun
  (`condition`) without colliding with the imported `condition` function. `test_assembly.jl`
  already spells this local `cond`, which is why it's proposed here too, but `cond` is an
  abbreviation not on the roster — either it should join the roster (it looks likely to
  recur in other groups' files), or `fragment` deserves the same rule-6 exception `build`
  and `path` carry, since the shape is identical: a spec noun whose own constructor produces
  the value, called exactly once in the scope that holds it.
