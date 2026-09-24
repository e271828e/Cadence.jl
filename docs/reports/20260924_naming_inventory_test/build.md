# Naming inventory: test/test_build.jl

Tip: 0c0a899. Sites flagged: 388. Renames: 65. Collisions: 2. Roster proposals: 0.
Kept without a row: keep:index 1, keep:typeparam 75, keep:spec 114, keep:glance 6, keep:family 68, keep:roster 57, keep:api 0.

Methodology note on the tallies: this file defines roughly 90 one-off fixture
components at top level, each a few lines of `output_types`/`output_state`/
`state_derivative`/… methods carrying the same handful of bundle-destructure
and `::Type{T}) where {T <: Real}` parameters (the `keep:spec` and
`keep:typeparam` counts). These were counted by a systematic search of every
`(; …)` destructure and every `where {T` clause in the file, not re-verified
one by one, since they are the exact repetitive pattern the bundle-law and
R7/R9 rulings already settle. Every non-repetitive site — every local bound
inside a testset or a named parameter of a non-anonymous method — was read
in place and classified individually; that is where all 64 renames and both
collisions come from.

## Letters with more than one meaning in this file

- `b`: the value `build(...)` produces, in nearly every testset (renamed to
  `build` or a role-qualified `*_build` name below); a diagnostic under
  comparison at line 320 (renamed to `repeat`); the whole stage-1 bundle
  argument of two fixture methods at lines 1001 and 1008 (renamed to
  `bundle`) — three distinct meanings, all resolved by the renames below.

(`the probe rejects malformed components (§9.3)`, line 56, and `a stage
returning bare `(;)` is dead, whichever position (§5.2, §9.3)`, line 75, bind
only sequential `d`s (`keep:family`), `err`s and `sim` (`keep:roster`); no
tabled rows.)

## "the schedule follows the feedthrough graph (§5.3)" — line 100

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 103 | `paths` | local | the per-entry schedule labels (`:sum`/`:ctl`/`:plant`) of the compiled sweep | collision | `order` |

(`sim` at line 101 is `keep:roster`; `e` in the comprehension at line 104 is `keep:glance`.)

## "the nominal evaluation's products are names and an order (§9.1, D-253, D-261)" — line 110

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 115 | `b` | local | the build of `feedback_model()` | rename | `feedback_build` |
| 117 | `ctl` | local (destructure) | the controller component's index | rename | `control` |
| 117–118 | `sm` | local (destructure) | the sum component's index | rename | `sum_ci` |
| 135 | `b2` | local | the build of `single(SwappedPorts())` | rename | `swapped_build` |

`build(...)` is called twice in this testset (lines 115 and 135), so rule
6's `build` exception (a local named after the function that produced it)
is unavailable for either — binding either local to the bare word `build`
would shadow the function before the other call runs. `plant` (also bound
at line 117) is already a full word, not tabled.

## "each cluster is one diagnostic and the tail is in none (§5.6, D-012)" — line 163

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 173 | `ds` | local | the two `AlgebraicCycle` diagnostics of the two disjoint loops | rename | `diags` |

## "an input-dependent branch falls back to sampled states (§5.6, D-012)" — line 288

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 293 | `loop` | local | the model whose algebraic cycle branches on an in-cycle face | collision | `model` |
| 319 | `a` | local | the first of two builds' diagnostics, compared for determinism | rename | `first` |
| 320 | `b` | local | the second (repeat) build's diagnostic | rename | `repeat` |

`a` and `b` here are the one place in the file where two diagnostics from
separate builds are compared directly against each other in the same
assertion, so a role name (rather than the plain family letter `d`) is
actually called for; I used the brief's own example vocabulary ("first,
repeat").

## "the unary list and the norms carry the set through (§5.6)" — line 336

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 337 | `t` | local | a `Tracer{true}` test value | rename | `tracer` |
| 346 | `t1` | local | the first of three `Tracer` operands passed to `hypot`/`norm` | rename | `tracer1` |
| 346 | `t2` | local | the second operand | rename | `tracer2` |
| 346 | `t3` | local | the third operand | rename | `tracer3` |

## "a state or mode field is exposed by returning it from stage 1 (§5.3, D-252)" — line 359

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 364 | `b` | local | the build of the fed `Motor` model | rename | `build` |
| 365 | `i` | local | the fed component's index | rename | `ci` |

Only one `build(...)` call in this testset, so the plain `build` name is available.

## "a pinned declaration of a walking field is refused at the stage-1 port check (§9.5, D-166)" — line 407

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 411 | `b` | local | the build of `single(PinnedState())` | rename | `build` |

## "two consumers of one root input declare one concrete type (§8.2, D-168)" — line 446

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 466 | `m` | `for`-loop variable | one of the two fanned-root models under test | rename | `model` |

(`simr` at line 474 is `keep:roster`.)

## "an abstract entry takes any concrete producer below it (§4.4, §8.2, D-236)" — line 583

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 585 | `m` | `for`-loop body local | the field-source/`FieldReader` model | rename | `model` |
| 586 | `b` | local | that model's build | rename | `field_build` |
| 599 | `b` | local | the build of the `NomSource`/`RealReader` model | rename | `real_build` |
| 607 | `m` | `for`-loop body local | the vec-source/`VecReader` model | rename | `model` |

`build(...)` is called three times across this testset (lines 586, 599 and
607), so no site here gets the bare `build` exception.

## "a root input with no concrete entry is refused (§8.2, D-236)" — line 613

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 624 | `ds` | local | the two `AbstractAtRoot` diagnostics | rename | `diags` |

## "an abstract co-consumer votes but does not type a root input (§8.2, D-236)" — line 629

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 632 | `b` | local | the build of the fanned `VecReader`/`SVecEntry` model | rename | `vec_build` |

`build(...)` runs again at lines 637 and 642 in this same testset, blocking the bare `build` exception.

## "the walk clause fails at the first nominal build (§6.1, §8.2, D-236)" — line 650

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 664 | `d2` | local | the frame-source/`FrameReader` diagnostic, one leaf deeper than `d` above it | rename | `d` |

Sequential, non-overlapping use of the same one-diagnostic-at-a-time idiom as `d` at line 656; no role is needed.

## "the wire pass collects to the structure step's barrier (§13.1, D-229, D-236)" — line 674

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 686 | `ds` | local | the two `WireTypeMismatch` diagnostics from the two bad wires | rename | `diags` |

## "a mutable port and a handle at root are refused (§4.4, D-237)" — line 759

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 787 | `ds` | local | the two `IllegalPortType` diagnostics from the combined model | rename | `diags` |

## "a root input the synthesis chain cannot value is `MissingProbeValue`, collected (§9.3, D-051)" — line 792

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 802 | `b` | local | the build of the `Synthesized` model | rename | `synth_build` |
| 808 | `ds2` | local | the two `MissingProbeValue` diagnostics from the combined model | rename | `diags2` |

`build(...)` is called four times in this testset (lines 795, 802, 806, 814), so `b` cannot take the bare `build` name.

## "an opaque leaf is accepted by identity alone (D-237)" — line 818

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 829 | `m` | local | the `offset_model(OffsetAtLiteral())` model | rename | `model` |

## Fixture methods for the lateness pair — lines 1001, 1008

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1001 | `b` | parameter of `output_state(::LateRead, b)` | the whole stage-1 bundle (undestructured) | rename | `bundle` |
| 1008 | `b` | parameter of `output_state(::LateOwnMiss, b)` | the whole stage-1 bundle (undestructured) | rename | `bundle` |

## "an enum port is one pinned leaf of its own eltype (§4.1, §8.2)" — line 1155

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1156 | `m` | local | the `GearSelector`/`GearReader` model | rename | `model` |
| 1158 | `b` | local | that model's build | rename | `build` |

Only one `build(...)` call in this testset.

## "an enum root input is synthesized as the first instance (§9.3, D-051)" — line 1176

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1177 | `m` | local | the `GearReader` root-input model | rename | `model` |
| 1178 | `b` | local | that model's build | rename | `build` |

## "an enum mode is returned from stage 1 (§7.5)" — line 1188

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1189 | `b` | local | the build of `single(GearMode())` | rename | `build` |
| 1190 | `i` | local | the component's index | rename | `ci` |
| 1191 | `s1` | local | the component's stage-1 return tuple | rename | `stage1` |

## "a Symbol port is one opaque leaf, with no synthesis at a root (§4.3, D-243)" — line 1198

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1199 | `m` | local | the `PhaseSelector`/`PhaseReader` model | rename | `model` |
| 1208 | `b` | local | the build of `single(PhaseMode())` | rename | `mode_build` |
| 1209 | `i` | local | the component's index | rename | `ci` |

`build(...)` is also called at lines 1201 and 1214 in this testset, so `b` at line 1208 cannot take the bare `build` name.

## "tier is read off the declaration shape (§8.2)" — line 1221

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1276 | `b` | local | the build of `single(DiscreteCounter())` | rename | `build` |

This is the only `build(...)` call in the testset; the many `classify_tier(...)` calls earlier in it do not call `build`. `diags` (lines 1224, 1234, 1248, 1257, 1265) is `keep:roster`; the two `for (c, ...)` loop tuples are `keep:glance`.

## "a continuous contract bounded narrower than Real is refused (§8.5)" — line 1284

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1292 | `da` | local | the `AnonBound` diagnostic | rename | `d` |
| 1296 | `d2` | local | the `NarrowOutput`-fed diagnostic | rename | `d` |
| 1300 | `d3` | local | the `NarrowInput`-fed diagnostic | rename | `d` |
| 1308 | `ds` | local | the three merged tier/walk diagnostics | rename | `diags` |

`d`, `da`, `d2` and `d3` are four sequential, non-overlapping single-diagnostic checks (never compared to each other); I propose reusing the plain `d` for all four rather than inventing roles.

## "an init_x field is a Float64 or an SArray of them, flat (§7.1, §8.2, D-094)" — line 1387

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1392 | `ds` | local | the six `IllegalStateLeaf` diagnostics of the combined model | rename | `diags` |

## "a store field is isbits or a Symbol, checked field by field (§7.3, D-231)" — line 1403

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1407 | `ds` | local | the two `IllegalStoreField` diagnostics | rename | `diags` |

## "a store declaration is a NamedTuple, checked before the stores are read (§8.2, §9.1, D-247)" — line 1415

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1422 | `ds` | local | the four `StoreNotNamedTuple` diagnostics | rename | `diags` |

## "a mixed-leaf port embeds leaf by leaf (§4.1, §9.4, D-166)" — line 1461

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1464 | `b` | local | the build of `Group((; c = GearStateSource()))` | rename | `build` |

## "embed-accept keeps the constant branch legal (D-166)" — line 1469

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1483 | `b` | local | the build of `single(PinnedGetsDual())` | rename | `build` |

## "a non-nominal activation is derived from the nominal one; frozen products carry (§9.4)" — line 1510

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1516 | `b` | local | the build of the local `pair()` model | rename | `pair_build` |

`build(...)` is also called at lines 1539 and 1545 in this testset, so `b` cannot take the bare `build` name. The local zero-argument function `pair` (line 1511) is itself a site: a full word, no collision, not tabled.

## "concurrent first requests share one activation (§9.4's torn-state guarantee)" — line 1553

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1558 | `b` | local | the build of the `NomSource`/`FrozenReader` pair | rename | `build` |

Only one `build(...)` call in this testset. (`acts` at line 1560 is `keep:roster`; the lambda parameter `a` at line 1561 and the discarded `_` at line 1560 are `keep:glance`.)

## "a warning raised inside a declaration body lands on the Build and is logged once at return (§9.1, D-250)" — line 1670

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1675 | `b` | local | the build of the bare `WarningWires` component | rename | `leaf_build` |
| 1681 | `n` | local | the build one `Group` level down | rename | `wrapped_build` |
| 1689 | `p` | local | the build through one `WarningPassthrough` level | rename | `passthrough_build` |
| 1693 | `g` | local | the build through the `WarningGrandparent` level | rename | `grandparent_build` |

Four separate `build(...)` calls, so none of them can be the bare `build`.

## "a step that throws carries its warnings beside the collection (§9.1, D-250)" — line 1700

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1705 | `e` | local | the exception `build(WarningUnfed(...))` raises | rename | `err` |
| 1712 | `t` | local | the exception `build(WarningTypo(...))` raises | rename | `err` |

Both are the same "a caught exception" idiom the rest of the file spells `err`; sequential, non-overlapping, so both can share the one name.

## "the empty selection lands on the Build (§8.8, D-251)" — line 1717

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1721 | `b` | local | the build of `EmptySelection(...)` | rename | `leaf_build` |
| 1728 | `n` | local | the build of `EmptySelectionParent(...)` | rename | `parent_build` |

## Fixture methods for the warning-channel assemblies — lines 1613–1667

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1613 | `p` | parameter of `input_connections(p::WarningPassthrough)` | the assembly itself | rename | `a` |
| 1614 | `p` | parameter of `output_connections(p::WarningPassthrough)` | the assembly itself | rename | `a` |
| 1620 | `g` | parameter of `input_connections(g::WarningGrandparent)` | the assembly itself | rename | `a` |
| 1621 | `g` | parameter of `output_connections(g::WarningGrandparent)` | the assembly itself | rename | `a` |
| 1666 | `p` | parameter of `input_connections(p::EmptySelectionParent)` | the assembly itself | rename | `a` |
| 1667 | `p` | parameter of `output_connections(p::EmptySelectionParent)` | the assembly itself | rename | `a` |

Two other `input_connections`/`output_connections` methods a few lines
earlier in this same file (`EmptySelection`, `EmptySelectionRated`, lines
1642/1655) already name this parameter `a`, matching `test/fixtures.jl`'s
own `input_connections(a::PassthroughOverForgotten)`. These six break that
"every method names alike" agreement within the file itself.

## Collisions

- `paths` (line 103) shares its name with `paths(structure::Structure)` in
  `test/utils.jl`. `test_build.jl` does not call `utils.jl`'s `paths`
  elsewhere, but the function is reachable from the same test module.
- `loop` (line 293) shares its name with the `loop` device-contract function
  in the `import Cadence:` list (`test/imports.jl`). `test_build.jl` does
  not call `loop` itself.

## Roster proposals

None.

## Questions

- Several testsets bind more than one `build(...)` result to separate
  locals in the same scope (lines 115/135, 585/599, 792's `b`/802, 1198's
  `b`/1208, 1510's `b`, 1670's four, 1717's two). Rule 6's `build` exception
  only fires when nothing in the enclosing scope calls `build` again, which
  none of these satisfy, so I gave each a descriptive `*_build` name off its
  fixture instead of a number. The `sim`/`sim2` precedent suggests the
  coordinator may prefer a uniform `build1`/`build2`-style numbering across
  all of these instead — I did not use it because, unlike the generic
  `sim`/`sim2` pair, most of these builds are of visibly different models
  and a number would erase that.
- `ds`/`ds2` (a `Vector{Diagnostic}` from `diagnostics(err)`) is not itself
  on the roster; I propose it take the roster's own `diags` spelling
  (already used for the `Diagnostic[]` collector in `build_tier`) rather
  than adding a second word for the same concept.
- `sm` (line 117) is a component index for `"sum"`; the bare noun `sum`
  would collide with `Base.sum`, which this file calls (e.g. line 497), so
  I propose `sum_ci` — pairing the roster's `ci` with the component's name —
  rather than the plain `sum` its neighbours `plant` and `control` get.
- Lines 1001 and 1008 bind the whole stage-1 bundle (not a destructure) to
  a parameter named `b`; I propose `bundle`, but if `src/`'s own leaf
  builders use a different name for an undestructured bundle parameter
  somewhere, that name should win instead for consistency.

- `m`: the mode store in bundle destructures (`(; x, m)`), used throughout
  the file's fixture methods, `keep:spec`; a local holding a `Group` model
  passed to `build`, at lines 466, 585, 607, 829, 1156, 1177 and 1199 (all
  renamed to `model` below) — two meanings, the second renamed away.
- `t`: time, in bundle destructures (`(; t)`), `keep:spec`; a `Tracer{true}`
  test value at line 337 and its three operands at line 346 (renamed to
  `tracer`/`tracer1`/`tracer2`/`tracer3`); a caught exception at line 1712
  (renamed to `err`) — three meanings, the last two renamed away.
