# Naming inventory: test/test_stepper.jl

Tip: 0c0a899. Sites flagged: 32. Renames: 9. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 1, keep:typeparam 0, keep:spec 12, keep:glance 4, keep:family 0, keep:roster 5, keep:api 0.

## Letters with more than one meaning in this file

None found: `h`, `r`, `m` and the other single letters this file binds each carry one
consistent meaning throughout.

## "the method is a deployment binding, RK4 the default (§10.2)" — line 7

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 10 | `simh` | local | the Heun-stepper `Simulation`, compared against the default `sim` | rename | `heun_sim` |
| 14 | `d1` | local | the `DeploymentInvalid` from `algorithm = 4` | rename | `d` |
| 16 | `d2` | local | the `DeploymentInvalid` from `algorithm = Int`; fully read before the next diagnostic would be bound | rename | `d` |

## "convergence order: each backend is itself — 4 and 2 (§10.2)" — line 20

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 51 | `simr` | local (inside `stamp_error`, a nine-line local function) | the rotor-model `Simulation`, read twice more in the same function | keep:glance | — |

## "localization is seam-generic: t* under Heun (§10.2, §10.4)" — line 40

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 57 | `e10` | destructuring | the stamp-time error at the coarser grid, `h = 1//10` | rename | `coarse_error` |
| 57 | `e40` | destructuring | the stamp-time error at the finer grid, `h = 1//40` | rename | `fine_error` |
| 61 | `simf` | local | the `Simulation` of `fed(Stamper(0.5), "sig")`, read across the rest of the testset | rename | `fed_sim` |

## "gate 4: the second backend holds the §7.5 invariant" — line 69

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 74 | `siml` | local | the `Simulation` of `single(Bouncer(1.0, 0.07))`, read across the rest of the testset | rename | `bouncer_sim` |
| 77 | `nopol` | destructuring | the empty `StopPolicy` handed to `frame!`; the only stop policy bound in this file | rename | `stop_policy` |
| 77 | `noaddrs` | destructuring | the empty compiled-address list handed to `frame!`; `addrs` is already the roster's plural | rename | `addrs` |

## Collisions

None from this file.

## Roster proposals

None from this file.

## Questions

- `d1`/`d2` (lines 14, 16) are the same "`d2` is not a role" pattern flagged in this group's
  other two files: each is fully read before the next would be bound, so plain `d` (reused
  sequentially) is proposed for both.
- This file names its extra `Simulation`s by appending a letter to `sim` (`simh`, `siml`,
  `simr`, `simf`), one per testset, each letter standing for something different (an
  algorithm, a fixture, a component). Only `sim`/`sim2` (ordinal role) is blessed by the
  rules; these letter suffixes are proposed as full words instead. If the coordinator would
  rather keep the terser family (it is at least internally consistent across the file), that
  reads as a reasonable alternative to flag back.
