# Naming inventory: test/test_store.jl

Tip: 0c0a899. Sites flagged: 12. Renames: 5. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 0, keep:spec 5, keep:glance 1, keep:family 1, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None.

## The `PinnedLeaf`/`MixedCell`/`PinnedInside`/`WidenedUpdate` fixtures — lines 12–169

Every `output_state`/`state_update` method here destructures a bundle field (`t` in `PinnedLeaf`, `MixedCell`, `PinnedInside`; `s` in `WidenedUpdate`, twice) — the fixture-stage-method bullet's `keep:spec`, five sites, none arguable, no rows.

## "the workspace is scratch, on both tiers (§7.3)" — line 112

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 125 | `b` | local | the model's compiled phase bodies, indexed on four further lines | rename | `bodies` |

`sm`, `src`, `wg` (line 113) are the assembly's own component names, not locals.

## "instances of one component type share one compiled body (D-162)" — line 138

No flagged sites: `two`, `types`, `counters` are full words, `a`/`b`/`c1`/`c2` (lines 142, 153) are component names, and `e` (line 145, a comprehension variable) is `keep:glance`.

## "a discrete successor is the store's own type (§7.3)" — line 172

`d` (line 173) is the diagnostic under test, already correctly spelled — `keep:family`, no row.

## "a handle type is its own cell store (§4.4, D-237)" — line 183

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 198 | `simd` | local | the `D8`-activated simulation, read across five further statements — two words fused with no underscore | rename | `sim_d8` |
| 206 | `b` | local | the model's compiled phase bodies, indexed on four further lines | rename | `bodies` |
| 225 | `absm` | local | the abstract-entry model — a fused, unclear abbreviation | rename | `abstract_model` |
| 227 | `sima` | local | that model's simulation — fused with no underscore | rename | `abs_sim` |

`trc` (line 218) is the roster's own spelling, not flagged. `twin` (line 219) is a full word.

## Collisions

None in this file.

## Roster proposals

None in this file.

## Questions

- `b = phase_bodies(sim)` recurs twice in this file (lines 125, 206) with the same shape and the same proposal (`bodies`). If the coordinator would rather see the compiled-bodies local carry a more specific name (e.g. tying it to the testset's own vocabulary), one rename covers both sites.
- `simd`/`sima`/`absm` are the file's only fused-compound names; I read "words join with underscores... two words never fuse in a local" as reaching these regardless of length, since none of the three is a spec-symbol derivative (`sim`/`abs`/`m` are all whole words or generic letters, not symbols with digit/plural/listed-suffix derivatives).
