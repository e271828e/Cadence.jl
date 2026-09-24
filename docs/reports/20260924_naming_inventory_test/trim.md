# Naming inventory: test/test_trim.jl

Tip: 0c0a899. Sites flagged: 56. Renames: 25. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 1, keep:spec 15, keep:glance 5, keep:family 10, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- `d`: the trim decision vector, in every top-level helper (`torque_only`, `decide_u`, `decide_θ`, `decide_both`, `decide_θ_alone`, `snap_decide_u`, `eltype_split`), and the diagnostic family letter throughout the testset bodies. Both are the settled reading for this file (rule 4's own text: "`d` is a diagnostic in the diagnostic families and the trim decision vector in `trim.jl`, nothing else") — neither needs a rename.
- `b`: `sim.deployment.build` at line 480, and a `trim!` report at line 144 → the report site renamed to `permuted_report` below.
- `c`: the component, in `Snapback`'s own fixture methods (lines 77–80), and a captured `ConditionNode` at line 461 → the captured-condition site renamed to `captured` below.

## "permuted bounds are a non-event: names pair, order never does (§14.7, §9.5)" — line 132

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 143 | `a` | local | the `trim!` report from the declared-order problem | rename | `declared_report` |
| 144 | `b` | local | the `trim!` report from the permuted-order problem | rename | `permuted_report` |

## "no convergence, no commit: the simulation is untouched (§14.8)" — line 152

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 176 | `r2` | local | the `trim!` report from the already-initialized simulation, beside `report` (line 163) for the fresh one | rename | `live_report` |

## "the empty problem is the equilibrium probe, and the solver is bypassed (§14.8)" — line 204

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 223 | `no` | local | the `trim!` report when the baseline is not an equilibrium, paired with `yes` at line 214 | rename | `unconverged_report` |

## "a malformed problem is a collected `TrimProblemInvalid` (§14.7, §13.1)" — line 229

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 236 | `e` | local | the `DiagnosticError` collecting three violations (bounds key-set, guess field type, read-set path) | rename | `err` |
| 242 | `ks` | local | the `TrimProblemInvalid` diagnostic for the bounds key-set mismatch | rename | `key_set_diag` |
| 244 | `ft` | local | the `TrimProblemInvalid` diagnostic for the guess's field types | rename | `field_types_diag` |
| 248 | `tap` | local | the `PathResolution` diagnostic from the read set's own path refusal | rename | `path_diag` |
| 255 | `e2` | local | the `DiagnosticError` from a residuals key-set mismatch | rename | `residuals_err` |
| 260 | `d2` | local | the `TrimProblemInvalid` diagnostic for the residuals key-set mismatch | rename | `residuals_diag` |
| 266 | `e3` | local | the `DiagnosticError` from a non-`Float64` tolerance and a bare read set | rename | `tol_reads_err` |
| 271 | `tol` | local | the `TrimProblemInvalid` diagnostic for the non-`Float64` tolerance | rename | `tol_diag` |
| 273 | `rd` | local | the `TrimProblemInvalid` diagnostic for the bare read set | rename | `reads_diag` |
| 280 | `e4` | local | the `DiagnosticError` from an inverted box | rename | `inverted_box_err` |
| 285 | `d4` | local | the `TrimProblemInvalid` diagnostic for the inverted box | rename | `inverted_box_diag` |
| 294 | `e5` | local | the `DiagnosticError` from two nonpositive tolerances | rename | `nonpositive_tol_err` |

## "the box is honored at every point the backend returns (§14.8, D-070)" — line 306

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 330 | `r2` | local | the `trim!` report from the degenerate box | rename | `degenerate_report` |

## "the residual return is re-checked at the first seeded point (§14.7, §14.8)" — line 336

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 343 | `e` | local | the `DiagnosticError` from a residuals return that changes shape at the seeded point | rename | `err` |

## "the scratch world's frozen cells are established, not probe-seeded (D-213)" — line 368

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 393 | `e` | local | the `DiagnosticError` from authoring a decision variable into the frozen discrete store | rename | `err` |

## "a warm restart trims from a capture at its own time (§14.1, §14.8)" — line 456

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 461 | `c` | local (destructuring) | the captured `ConditionNode`, used as `trim!`'s baseline; `c` elsewhere in this file means "the component" (`Snapback`'s fixture methods) | rename | `captured` |

## "the per-iteration write and read are free at the seeded activation (§7.5)" — line 474

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 480 | `b` | local | `sim.deployment.build` | rename | `build` |
| 482 | `ex` | local | the executor compiled from the build at `TD`'s activation | rename | `exec` |
| 498 | `v` | local | the seeded read's torque value, with partials | rename | `seeded_torque` |

## "`trim!` is a stopped-sim service on a nominal deployment (§14.8, §12.6)" — line 503

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 515 | `d2` | local | the `ArgumentInvalid` diagnostic from passing a non-problem value to `trim!` | rename | `not_problem_diag` |
| 528 | `d3` | local | the `ServiceLifecycle` diagnostic from calling `trim!` on a running simulation | rename | `running_diag` |

## Collisions

None in this file.

## Roster proposals

None in this file. `sampled_base`'s `acc` parameter (line 57) mirrors `DiscreteIntegrator`'s own field directly and is exempt as a field-mirroring parameter, the same as `readable_condition`'s in `test_readers.jl`.

## Questions

- At line 223, `no` (two characters) is flagged purely by length even though it is a genuine English word paired with `yes` (three characters, not flagged) at line 214. Should the pair get matching treatment — both renamed, or a documented exception for short real words — or does the length rule stand as an intentional bright line even here?
- `d` in this file legitimately carries two meanings at once (the trim decision vector per rule 4, and the diagnostic family letter): should the naming rules flag trim.jl explicitly as the one file where a single letter is allowed two meanings, since the "letters with more than one meaning" convention everywhere else in this inventory always signals a needed fix?
- This testset's `err`/diagnostic pairs recur constantly (six pairs in "a malformed problem is a collected `TrimProblemInvalid`" alone, each renamed here to a bespoke `..._err`/`..._diag` name). Would the coordinator prefer a shorter, systematic naming scheme (e.g. always `err`/`d` reused sequentially, relying on scope rather than distinct words) over the bespoke names proposed here?
