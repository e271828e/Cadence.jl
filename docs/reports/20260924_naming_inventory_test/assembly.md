# Naming inventory: test/test_assembly.jl

Tip: 0c0a899. Sites flagged: 124. Renames: 24. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 8, keep:spec 22, keep:glance 20, keep:family 47, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- `r`: the reference signal (spec symbol, `assembly_two_level`, line 536), a `TupleRoster` instance in `assembly_primitives` (line 989) → the `TupleRoster` site renamed below.
- `m`: the feedback model under test in `assembly_primitives`'s first testset (line 908), a plain component under test in two more of its testsets (lines 957, 963) → the sites renamed below.

## "class is read off the declaration shape (§8.5)" — line 37

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 66 | `b` | local | the primitive root's build (`Plant()`), read by two further assertions | rename | `leaf_build` |

## "container children are path-named `field/key` and `field/1` (§8.5)" — line 148

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 170 | `tsim` | local | the simulation over the `TupleRoster` instance | rename | `tuple_sim` |

## "a name-transparent container contributes bare keys (§8.5, D-211)" — line 256

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 323 | `fld` | for (destructure) | the type's declared container field, the loop's second element | rename | `field` |
| 323 | `cands` | for (destructure) | the container fields list, the loop's third element | rename | `candidates` |

## "`Group`'s keyword form normalizes a bare `Pair` (§8.5, D-211)" — line 333

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 334 | `g` | local | the `Group` built from the keyword bare-`Pair` form | rename | `pair_group` |
| 340 | `w` | local | the `Group` built from the tuple `wires` form | rename | `tuple_group` |

## "a wiring endpoint names one child and one of its faces (§6.1, D-207)" — line 387

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 398 | `gsim` | local | the simulation over the generically-held `GenericHold` | rename | `generic_sim` |

## "a two-level assembly runs the sampled loop through its faces" — line 535

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 536 | `N` | local (destructure) | the number of reference-model integration steps | rename | `n_steps` |

## "a face's type and tier are its internal endpoint's (§8.6)" — line 556

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 572 | `simd` | local | the simulation activated at the `D8` dual type | rename | `dual_sim` |

## "the structure's rows record each component's rate chain and each keyed scope's timing (§9.1, §9.2, D-253, D-261)" — line 584

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 586 | `path` | parameter of local `entry` | a structure component's path, looked up by it | keep:spec | — (rule 6's `path` exception: no bare `path` call in this testset's scope) |
| 587 | `path` | parameter of local `timing` | the same, passed through to `entry` | keep:spec | — |

## "the §13.3 primitives resolve one level and list faces in order" — line 907

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 908 | `m` | local | the `feedback_model()` instance under test | rename | `model` |

## "the §8.8 passthrough pair computes what a hand-wired twin declares" — line 930

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 931 | `p` | local (destructure) | the `Passed` instance | rename | `passed` |
| 931 | `w` | local (destructure) | the `HandWired` instance | rename | `wired` |
| 941 | `bp` | local (destructure) | the build of `passed` | rename | `passed_build` |
| 941 | `bw` | local (destructure) | the build of `wired` | rename | `wired_build` |
| 945 | `sp` | local (destructure) | the simulation of `passed` | rename | `passed_sim` |
| 945 | `sw` | local (destructure) | the simulation of `wired` | rename | `wired_sim` |
| 946 | `cond` | local | the init condition shared by both simulations | rename | `init_condition` |

## "a primitive hands out a copy of the walk's face list (§13.3)" — line 952

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 957 | `m` | local | the `MutatedFaces` instance under test | rename | `component` |

## "the passthrough filters, and refuses what it cannot mean (§8.8)" — line 962

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 963 | `m` | local | the `faced()` `Group` under test | rename | `component` |
| 989 | `r` | local | a `TupleRoster` instance, exercised for its default `prefix` | rename | `roster` |

## "the helpers address a transparent container's child by bare key (D-211)" — line 1062

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1063 | `g` | local | the `PassedGroup` instance under test | rename | `group` |

## "the feed-list idiom: one authored list, two declarations (§8.8, D-251)" — line 1073

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1079 | `sys` | local | the `Systems{:one}` instance under test | rename | `systems` |
| 1089 | `b` | local | the build of `systems` | rename | `one_build` |
| 1094 | `path` | parameter of local `conns` | a structure component's path, looked up by it | keep:spec | — (rule 6's `path` exception) |
| 1116 | `b2` | local | the build of the inline `Systems{:two}` instance | rename | `two_build` |

## Collisions

No `collision`-coded rows in this file. Three sites hold a name that matches
the imported `path` function — `entry`'s and `timing`'s `path` parameters
(`assembly_rate_chains`, lines 586–587) and the local `conns`'s `path`
parameter (`assembly_primitives`, line 1094) — but each is held under rule
6's `path`/`build` exception (tabled above as `keep:spec`), since no call in
its testset's scope invokes `path` bare. The suite-wide ruling (the brief's
"What the suite adds" section) also names a local literally `structure` as a
possible shadow of an imported function; `test_assembly.jl` binds a local
`structure` once (`assembly_rate_chains`, line 585), but no lowercase
`structure` function is imported or reachable anywhere (only the
capitalized `Structure` type), so I did not treat it as a collision — see
Questions.

## Roster proposals

None in this file: every rename above takes a full word or an established
spec/role name, not a new abbreviation.

## Questions

- The suite-wide ruling text names `structure` as one of four locals —
  beside `condition`, `reads`, `declarations` — that "shadows an imported
  function the file calls," but gives proposed renames only for the other
  three (`plan`, `read_set`, `decls`). No lowercase `structure` function
  exists in `test/imports.jl` or is called in `src/`; only the capitalized
  `Structure` type is imported. I left the local `structure` at line 585
  untouched. Worth confirming this ruling targets a different file, or that
  `structure` should be treated as settled (no local rename needed) here.
- `N` (line 536) holds a step count, not a type parameter or a `Dual`
  width — the two roles the rules reserve a bare `N` for. I renamed it to
  `n_steps` rather than keep it, since it fits neither reserved role nor
  the roster. Flag in case the coordinator would rather keep a bare `N` as
  an established numeric-count convention instead.
- The classification codes have no entry specifically for rule 6's
  `path`/`build` exception (as opposed to `keep:roster`, `keep:family`,
  etc.). I used `keep:spec` for the three `path` parameters held under that
  exception (lines 586, 587, 1094), since rule 6 frames `path`/`build` as
  spec nouns — confirm this is the intended code, or that a new code is
  warranted for the sweep's brief.
