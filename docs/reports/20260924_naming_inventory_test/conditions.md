# Naming inventory: test/test_conditions.jl

Tip: 0c0a899. Sites flagged: 81. Renames: 30. Collisions: 2. Roster proposals: 1.
Kept without a row: keep:index 1, keep:typeparam 0, keep:spec 9, keep:glance 15, keep:family 23, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

- `q`: the spec position symbol (`state(sim, "plant").q` destructured at line 248, and the local at line 375) in most testsets, and a resolved condition plan at line 225 → the plan site renamed to `direct_plan` below.
- `d`: the diagnostic family letter, pervasive throughout the file, and a seeded `Dual` value at line 598 → the `Dual`-value site renamed to `seed` below.
- `m`: a mode-store bundle field (`landed()`'s comprehension, `Ledger`'s own bundle) and the `tri()` model at line 340 → the model site renamed to `model` below.
- `f`: a root-input face symbol (the `input` helper's parameter at line 86, `landed()`'s comprehension at line 485) and a misuse-case lambda at line 132 → the lambda's loop variable renamed to `case` below.

## "composition is inert and lazy: no path arithmetic, no validation (§14.2)" — line 35

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 38 | `n` | local | the composed condition tree built by `combine`/`at`/`fragment`, read by five assertions | rename | `composition` |

## "a `combine` collision names both origins and the layering combinator (§14.2)" — line 70

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 72 | `e` | local | the collision's `DiagnosticError`, read by two separate assertions | rename | `err` |

## "`override` layers: the patch wins, untouched leaves pass through (§14.6)" — line 82

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 83 | `b` | local | the build from `tri()`, read by six calls | rename | `build` |
| 88 | `p` | local | the resolved plan after the single-patch override | rename | `plan` |
| 95 | `p3` | local | the resolved plan after the two-layer override, last layer winning | rename | `plan2` |
| 115 | `p4` | local | the resolved plan over the full-coverage baseline under a component-scoped patch | rename | `plan3` |

## "blending a node with a bare NamedTuple is a directive error method (§14.2)" — line 129

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 132 | `f` | `for` (loop variable) | each misuse-case lambda under test | rename | `case` |

## "resolution collects every violation into one throw (§14.3, §13.1)" — line 150

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 151 | `b` | local | the build from `tri()`, read by two calls; the same testset also calls `build(Vehicle())` inline, so `build` itself is unavailable | rename | `tri_build` |
| 158 | `e` | local | the `DiagnosticError` collecting all five violations, read by four assertions | rename | `err` |
| 163 | `pr` | local | the `PathResolution` diagnostic filtered out of the collection | rename | `path_resolution` |
| 166 | `cr` | local | the `ConditionResolution` diagnostics filtered out of the collection | rename | `condition_resolutions` |
| 171 | `dup` | local | the `DuplicateConditionLeaf` diagnostic filtered out of the collection | rename | `duplicate` |

## "input faces resolve through the export chain to a root input (§14.2)" — line 193

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 194 | `b` | local | the build from `tri()`, read by five calls | rename | `build` |

## "an `at` prefix stopping at an assembly resolves its faces (§14.2, D-207)" — line 218

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 219 | `b` | local | the build from `nested()`; the same testset also calls `build(Vehicle())` inline, so `build` itself is unavailable | rename | `nested_build` |
| 225 | `q` | local | the plan resolved through the plain `fragment(inputs = (in = 1.0,))` spelling, compared against `p` | rename | `direct_plan` |

## "root-input totality is checked pre-write, and a rejection changes nothing (§14.6, D-068)" — line 245

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 249 | `lc` | local (destructuring) | the simulation's lifecycle symbol before the rejected `init!`; `lifecycle` itself is called again later in the same testset | rename | `initial_lifecycle` |
| 249 | `acc` | local (destructuring) | the integrator's accumulator value before the rejected `init!`, mirroring the fixture's own field name | roster? | — (1 site in this file; `tri_tree`'s `acc` parameter mirrors the same field directly and is exempt as a field-mirroring parameter) |

## "an authored state fires its guard at t₀ (§14.5, §10.6)" — line 336

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 340 | `m` | local | the `tri()` model, read by `Simulation` and by the plant's own `condition` call | rename | `model` |

## "the fragment-function idiom composes by pull across two levels (§14.2)" — line 349

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 350 | `veh` | local | the `Vehicle` model, read by `Simulation` and by `condition` | rename | `vehicle` |

## "a deep `at` path stays within a concretely declared subtree (§13.3, §14.2, D-130)" — line 374

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 380 | `bc` | local | the build of `ConcreteHold(SampledLoop())` | rename | `concrete_build` |
| 382 | `csim` | local | the `Simulation` over `ConcreteHold(SampledLoop())` | rename | `concrete_sim` |
| 389 | `bg` | local | the build of `GenericHold(SampledLoop())` | rename | `generic_build` |
| 401 | `gsim` | local | the `Simulation` over `GenericHold(SampledLoop())` | rename | `generic_sim` |
| 421 | `b` | local | the build of `nested()`; the same testset also calls `build(tri())` inline (line 432), so `build` itself is unavailable | rename | `nested_build` |

## `tri_tree(q, acc, state, u, e)` — line 470

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 470 | `state` | parameter | the trigger's own mode-state value, passed into `fragment(m = (state = state,))`; `state` is imported and called throughout the file | collision | `trig_state` |

`tri_tree`'s `acc` parameter mirrors `DiscreteIntegrator`'s own field directly (the same pattern as a constructor parameter mirroring its field) and is counted, not tabled.

## "shape drift is a structured error, and nothing is written (§14.4, §9.5)" — line 534

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 553 | `d2` | local | the second `ConditionShapeDrift` diagnostic, from the drifted-prefix `apply!` | rename | `prefix_drift` |

## "the prefix sweep compares content, so a computed prefix passes (§14.4)" — line 560

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 569 | `paths` | local | the three prefix strings, freshly built as data rather than literals | collision | `prefix_words` |

## "the converters are baked per leaf, at the activation (§14.3)" — line 584

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 586 | `b` | local | `sim.deployment.build` | rename | `build` |
| 598 | `d` | local | a seeded `Dual` value (partials at index 1) | rename | `seed` |
| 607 | `e` | local | the `DiagnosticError` from compiling a decision variable into a frozen discrete store | rename | `err` |
| 608 | `r` | local | the `ConditionResolution` diagnostic from the seeded-activation refusal | rename | `d` |
| 614 | `r0` | local | the `ConditionResolution` diagnostic from the nominal-activation refusal, named by role beside `d` | rename | `nominal_refusal` |

## Collisions

- `state` (line 470, `tri_tree`'s third parameter): origin `test/imports.jl`'s import list. The file calls `state(sim, ...)` extensively elsewhere (e.g. `state(sim, "plant").q`), so the parameter shadows it for the whole function body.
- `paths` (line 569): origin `test/utils.jl`'s helper `paths(structure::Structure)`. The file calls `paths(bo.structure)` elsewhere (line 442), in a different testset scope; no runtime shadowing occurs, but the name collides file-wide under the rule.

## Roster proposals

- `acc` — 1 site (line 249's destructured local). Abbreviates "accumulator": the discrete integrator's own accumulated value, spelled exactly as the fixture's own field (`DiscreteIntegrator`'s `acc`). `tri_tree`'s own `acc` parameter (line 470) mirrors the same field directly and is exempt under the field-mirroring rule; this destructured local isn't a parameter, so `roster?` is offered as the conservative flag — see the first question below.

## Questions

- At lines 224–226, `p` and `q` are compared as a matched pair (`p.inputs == q.inputs && p.faces == q.faces == [:in]`); `q` breaks one-meaning (the letter already means the spec position symbol elsewhere in the file) and must rename, but `p` is legitimately glance-permitted and stays bare. Should the pair get matching role names instead of one lone, asymmetric rename?
- Is a destructured local or parameter that mirrors a fixture's own field name verbatim (`acc`, from `state(sim, "ctl").acc` or from `DiscreteIntegrator`'s own field) covered by the field-mirroring exception (built for constructor parameters mirroring their fields), or does it need a roster entry because it is still an abbreviation coined nowhere near a constructor?
- The `bc`/`bg`/`b`/`bo` builds in "a deep `at` path stays within a concretely declared subtree" cannot rename to the exception word `build`, because that same testset scope also makes a bare `build(tri())` call (line 432) that a local `build` would shadow. The rule states the `build` exception "where no scope holding one calls the function" — should its wording say explicitly that this is a per-scope test, since it means sibling builds in one testset can't all take the same exception name?


