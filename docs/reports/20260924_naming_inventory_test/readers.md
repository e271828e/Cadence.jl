# Naming inventory: test/test_readers.jl

Tip: 0c0a899. Sites flagged: 39. Renames: 19. Collisions: 3. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 1, keep:spec 3, keep:glance 8, keep:family 5, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None found: every single-letter local keeps one meaning throughout the file (the diagnostic family letter `d`, the spec symbols `q`/`t`, and `c` for "a captured condition" across every testset that binds it).

## "the reader is the gather twin: allocation-free over an executor (§14.4, §7.5)" — line 66

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 70 | `r` | local (destructuring) | the compiled reader, read by three calls | rename | `reader` |
| 70 | `ex` | local (destructuring) | the executor | rename | `exec` |

## "resolution collects every violation into one refusal (§14.4, §13.1)" — line 77

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 78 | `b` | local | the build from `readable()` | rename | `build` |
| 79 | `e` | local | the `DiagnosticError` collecting four violations, read by two assertions | rename | `err` |
| 84 | `a`, `b_`, `c`, `d` | local (destructuring) | the four diagnostics from the first refusal, one per read labeled `:a`/`:b`/`:c`/`:d` | rename | `diag_a`, `diag_b`, `diag_c`, `diag_d` |
| 102 | `a`, `b_`, `c`, `d` | local (destructuring) | the four diagnostics from the second refusal, one per read labeled `:a`/`:b`/`:c`/`:d` | rename | `diag_a`, `diag_b`, `diag_c`, `diag_d` |
| 111 | `diag` | local | the `ReadSetMisuse` diagnostic from a bare-NamedTuple read set | collision | `d` |

## "a read selector's path stays within a concretely declared subtree (§13.3, §14.7, D-125)" — line 117

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 144 | `b` | local | the build of `OpaqueHold(OpaqueLeaf(Gain(2.0)))`; the same testset calls `build(...)` inline elsewhere (lines 124, 138), so `build` itself is unavailable | rename | `opaque_build` |

## "the source rule: a snapshot-bound reader may not name a store selector (§14.4)" — line 152

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 154 | `diag` | local | the `ReadBindingUnresolved` diagnostic from a store-selector `Readout` | collision | `d` |
| 157 | `diag` | local | the `ReadBindingUnresolved` diagnostic from an indexed `Readout` | collision | `d` |

## "a reader and a plan belong to one activation, by dispatch (§9.4, §14.4)" — line 162

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 175 | `e` | local | the `InternalInvariant` from gathering reads at a mismatched activation, read by two assertions | rename | `err` |
| 182 | `e2` | local | the `InternalInvariant` from applying a resolved condition at a mismatched activation | rename | `resolve_err` |
| 184 | `e3` | local | the `InternalInvariant` from applying a compiled plan at a mismatched activation | rename | `plan_err` |

## "`capture` reads the committed world back as a total condition (§14.1, §14.10)" — line 200

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 205 | `c` | local (destructuring) | the captured `ConditionNode`, read by three assertions | rename | `captured` |
| 222 | `c2` | local (destructuring) | the captured `ConditionNode` after a run, the warm restart's baseline | rename | `warm_capture` |

## "`capture` authors level by level, so it re-applies across a generic seam (§14.1, §14.2)" — line 229

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 241 | `c` | local (destructuring) | the captured `ConditionNode`, read by three calls | rename | `captured` |

## Collisions

- `diag` (lines 111, 154, 157): the settled ruling excludes the singular `diag` from the roster because it shadows `LinearAlgebra.diag`. This file does not call `LinearAlgebra.diag` itself, but the exclusion is suite-wide, not per-file.

## Roster proposals

None. `readable_condition`'s second parameter (line 21) is also spelled `acc`, mirroring `DiscreteIntegrator`'s own field directly; as a parameter mirroring a struct field it is exempt and not flagged.

## Questions

- The `diag` collision recurs at three sites in this file alone (and again in `test_trim.jl`'s own group); is `d` (the diagnostic family letter) the intended universal replacement, or should the suite's own vocabulary for "the diagnostic under test" get a dedicated non-colliding word instead of leaning on the family letter every time?
- At lines 84 and 102, the four-diagnostic destructuring `(a, b_, c, d)` mirrors the read set's own selector labels `:a`/`:b`/`:c`/`:d`, which is the test's actual subject (see the comment "each read, by label"). Renaming to `diag_a`/`diag_b`/`diag_c`/`diag_d` keeps that correspondence readable but loses the one-glyph match to the bare label; is there a spelling the coordinator prefers that keeps both the label correspondence and family-letter economy?
