# Naming inventory: test/test_discrete.jl

Tip: 0c0a899. Sites flagged: 122. Renames: 36. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 22, keep:glance 25, keep:family 11, keep:roster 24, keep:api 0.

## Letters with more than one meaning in this file

- `d`: a diagnostic almost everywhere (keep:family, 11 sites, always bound via
  `only(diagnostics(...))` or `carried(...)`) — vs. a `Deployment` at 8 sites across five
  testsets (`the Deployment is the artifact...` line 246, `two deployments compare...` lines
  289/300, `materializing fixes the scalar...` line 306, `the grid attribution is exact...`
  lines 460/501/511, and the worked-example testset's line 178) → all eight renamed to
  `deployment`/`deployment2`/`deployment3` below, leaving `d` meaning only "diagnostic" in
  this file.
- `r`: the reference input value / spec symbol, kept (`discrete_one_rate`, line 18, and the
  multi-rate sampled-loop testset, line 545) — vs. a schedule-row comprehension variable
  reused at 7 sites across two testsets (lines 259, 261, 262, 263, 464, 504, 515), and
  `OpaqueRoster`'s own `sample_times` parameter (line 102) → all renamed away (`row`, `comp`)
  so `r` keeps its one meaning.

## `sample_times(r::OpaqueRoster) = r.rates` — line 102

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 102 | `r` | parameter | the `OpaqueRoster` whose declared rates are returned (a one-line method, otherwise `keep:glance` under R7) — `r` already means the reference input value elsewhere in this file | rename | `comp` |

## "the sampled loop matches the exact ZOH discretization" — line 11

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 18 | `N` | destructuring | the sample count driving the reference recursion (`for _ in 1:N`, `t_end = N * Δt`); no spec symbol it derives from | rename | `n_samples` |
| 19 | `A` | local | the reference linear system's continuous state matrix (`Ad = exp(A * Δt)` below) | keep:spec | — |
| 20 | `B` | local | the reference linear system's continuous input matrix | keep:spec | — |
| 28 | `s_next` | local | the discrete state one boundary ahead of `s`, read by the last assertion | rename | `snext` |

`A`/`B` are arguable: they read like the reference system's own state-space matrices, and
`Ad`/`Bd` (kept without a row) already fit rule 5's digit/suffix derivative pattern cleanly,
but `A`/`B` themselves are not in the rule's example list — see Questions.

## "bare rate keys drive the grid the composite ones did (§8.7, D-211)" — line 159

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 165 | `br` | destructuring | `bare`'s schedule rows | rename | `bare_rows` |
| 165 | `op` | destructuring | `opaque`'s schedule rows — not the roster's `op` (a lifecycle payload's operation) | rename | `opaque_rows` |

## "the worked example compiles to the spec's pairs (§9.2)" — line 174

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 178 | `d` | local | the `MultiRate` deployment, read across the rest of the testset | rename | `deployment` |

## "relative scopes compose affinely; anchors sever (§10.5, §9.1)" — line 212

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 214 | `inner_g` | local | the inner `Group`, wired under the outer scope two lines below | rename | `inner_group` |

## "the Deployment is the artifact the grid parameters fix (§9.1, D-254)" — line 244

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 245 | `b` | local | the `MultiRate` build, read across the rest of the testset | rename | `build` (see Questions) |
| 246 | `d` | local | the deployment under test, read across the rest of the testset | rename | `deployment` |
| 259 | `r` | generator | one row of `d.schedule.rows` | rename | `row` |
| 261 | `r` | generator | one row of `d.schedule.rows` | rename | `row` |
| 262 | `r` | generator | one row of `d.schedule.rows` | rename | `row` |
| 263 | `r` | generator | one row of `d.schedule.rows` (outer comprehension) | rename | `row` |
| 279 | `sc` | local | the one `ScopeEntry` the `"fcs"` key opened | rename | `scope` |

## "two deployments compare as values; the build is not compared (§12.7)" — line 287

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 288 | `b` | local | the `MultiRate` build, read across the rest of the testset — `build(MultiRate())` is called again at line 300, so `build` itself would shadow the function twice over here (see Questions) | rename | `build` (see Questions) |
| 289 | `d` | local | the deployment under test | rename | `deployment` |
| 300 | `d2` | local | a second deployment, off a fresh build of the same model, compared against the first | rename | `deployment2` |

## "materializing fixes the scalar; one deployment backs many (§9.2, D-254)" — line 304

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 305 | `b` | local | the `MultiRate` build | rename | `build` (see Questions) |
| 306 | `d` | local | the deployment under test, read across the rest of the testset | rename | `deployment` |

## "one Build backs many Simulations; Δt_base has three sources (§9.1)" — line 326

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 327 | `b` | local | the `MultiRate` build, read across the rest of the testset (reassigned at line 415) | rename | `build` (see Questions) |
| 332 | `s1` | local | the default-path simulation (`N_base·h`) | rename | `sim_default` |
| 333 | `s2` | local | the simulation with an explicit `N_base` | rename | `sim_nbase` |
| 334 | `s3` | local | the simulation with an explicit `Δt_base` (`Rational`) | rename | `sim_dtbase` |
| 335 | `s4` | local | the simulation with an explicit `Δt_base` (`Period` quantity) | rename | `sim_dtbase_qty` |
| 415 | `b` | local | a second build, of `AnchoredBank`, replacing the first once it is done being read | rename | `build` (see Questions) |

## "Δt_base derivation demands an all-anchored model (§9.1)" — line 426

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 446 | `w` | local | the one `GridUtilization` advisory the derivation raises, read across the rest of the testset | rename | `warning` |

## "the grid attribution is exact, and derivation prints it (§9.2, D-187)" — line 454

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 460 | `d` | local | the deployment under test | rename | `deployment` |
| 462 | `g` | local | the deployment's `GridReport`, read across the rest of the testset | rename | `grid` |
| 464 | `r` | generator | one schedule row | rename | `row` |
| 491 | `w` | local | the one `GridUtilization` advisory | rename | `warning` |
| 501 | `d2` | local | a second deployment, off a plain (unoffset) model | rename | `deployment2` |
| 504 | `r` | generator | one schedule row | rename | `row` |
| 511 | `d3` | local | a third deployment, off a fully harmonic model | rename | `deployment3` |
| 515 | `r` | generator | one schedule row | rename | `row` |

## "a multi-rate sampled loop matches its exact discretization" — line 538

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 545 | `N` | destructuring | the sample count driving the reference recursion, same pattern as line 18 | rename | `n_samples` |
| 547 | `A` | local | the reference linear system's continuous state matrix | keep:spec | — |
| 548 | `B` | local | the reference linear system's continuous input matrix | keep:spec | — |

## "the gated boundary walk does not allocate (§7.5)" — line 567

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 570 | `bods` | local | the compiled phase bodies, read across the rest of the testset | rename | `bodies` |

## Collisions

None in this file: every flagged site is a bare short name, not a name that already matches
a reachable function.

## Roster proposals

None from this file.

## Questions

- `build` (lines 245, 288, 305, 327, 415): renaming these locals to `build`, as the roster
  entry and rule 6's exception both suggest, does not actually compile. `x = build(...)`
  makes `build` local to the enclosing scope for its whole extent, so the call on the very
  same line resolves to the not-yet-assigned local, not the imported function —
  `UndefVarError: build not defined` (confirmed empirically: `sum = sum(xs)` fails the same
  way). The `path`/`build` exception in the rules most likely describes a *parameter* named
  `build` (bound at call time, no self-reference) or a local built from a field access
  (`build = deployment.build`), not a local assigned straight from calling the `build`
  function. None of the five sites here can take the bare word `build` without either
  restructuring the call (e.g. `Cadence.build(...)`) or taking a different name entirely. I
  have proposed `build` anyway, matching the ruling's intent, but the coordinator needs to
  settle what the sweep actually writes at these five sites — this is likely to recur in
  other groups' files too, wherever `x = build(model)` appears.
- `A`, `B` (lines 19–20, 547–548): are the reference system's state-space matrices meant to
  count as spec symbols/derivatives under rule 2, given they are not in the rule's example
  list? `Ad`, `Bd` fit the digit/suffix derivative pattern regardless of how `A`/`B` are
  ruled.
- `s_next` (line 28): proposed `snext` to match the fusion pattern `xnext` in the rules' own
  example list, rather than the underscored form the file currently spells. Confirm the
  fused (no-underscore) spelling is actually wanted here, since `Δt_base` and other
  roster-suffixed names in this same file do use an underscore.

