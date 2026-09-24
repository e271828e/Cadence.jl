# Naming inventory: test/test_leaves.jl

Tip: 0c0a899. Sites flagged: 29. Renames: 19. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 0, keep:typeparam 5, keep:spec 0, keep:glance 4, keep:family 0, keep:roster 0, keep:api 0.

## Letters with more than one meaning in this file

None.

## `roundtrip(v, off; E = Float64)` — line 69

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 69 | `v` | parameter | the value under round-trip, read three times in a seven-line helper — the method-length clause is borderline | keep:glance | — |
| 70 | `n` | local | the value's leaf count, read twice in the same short helper | keep:glance | — |
| 71 | `buf` | local | the oversized buffer, read on four further lines | rename | `buffer` |

`E` (the buffer's eltype keyword) plays a type parameter's part — `keep:typeparam`, not arguable.

## `mgather(P)`/`mscatter(P)` — lines 85, 92

No flagged sites beyond ones the rules settle outright: `P` (a type parameter's part) is `keep:typeparam`; `e` (the built `Expr`, read on the next line) and `a...` (the returned lambda's splat parameter) are `keep:glance`; `fn` is the roster's own spelling. `bases` is a full word. The quoted `:v` inside the built `Expr` is a generated-code symbol, not a local.

## "the flat shape of a value type (§7.1)" — line 100

No locals: every assertion calls `nleaves`/`leaf_types`/`leaf_eltypes`/`_accepts`/etc. directly on types and literals.

## "the dotted spelling of a flat position (§7.1, §13.4)" — line 174

No locals.

## "the flat round trip (§7.1)" — line 186

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 187 | `b` | local | the `Body` test value, read on two further lines | rename | `body` |
| 192 | `buf` | local | the oversized buffer, read on the next line | rename | `buffer` |
| 208 | `fr` | local | the `Framed` test value, read on four further lines | rename | `framed` |
| 210 | `buf` | local | a second buffer, rebound for the opaque-leaf case | rename | `buffer` |

## "a value whose leaves span several eltypes (§7.2)" — line 223

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 225 | `v` | local | the `Tagged{Float64}` test value, read on two further lines | rename | `value` |
| 228 | `scat` | destructured | the compiled scatter closure | rename | `scatter` |
| 228 | `sbases` | destructured | the scatter's per-eltype running bases | rename | `scatter_bases` |
| 235 | `f1` | destructured | the `Float64` buffer — the generated scatter/gather's own name for this position is `buffer1` | rename | `buffer1` |
| 235 | `f2` | destructured | the `Int` buffer — the generated position's own name is `buffer2` | rename | `buffer2` |
| 240 | `gath` | destructured | the compiled gather closure — `gather` itself is imported and out of reach | rename | `compiled_gather` |
| 240 | `gbases` | destructured | the gather's per-eltype running bases | rename | `gather_bases` |
| 245 | `gnt` | destructured | the compiled gather for a `NamedTuple` shape | rename | `nt_gather` |
| 248 | `gen` | destructured | the compiled gather for an enum-bearing `NamedTuple` | rename | `enum_gather` |
| 253 | `b` | local | a second `Body` test value | rename | `body` |
| 255 | `buf` | local | its buffer | rename | `buffer` |
| 257 | `ghom` | destructured | the compiled gather for the homogeneous (`K = 1`) case | rename | `homogeneous_gather` |
| 257 | `hbases` | destructured | its running bases | rename | `homogeneous_bases` |

`P` (line 224) plays a type parameter's part — `keep:typeparam`. `L` (line 230, a comprehension variable ranging over `leaf_eltypes(P)`, itself a type) is likewise `keep:typeparam`.

## "the activation walk (§7.2)" — line 263

No locals.

## "the wire relation with its abstract arm (§6.1, D-236)" — line 284

No locals.

## Collisions

None: `gath` would collide with the imported `gather` if renamed to it, which is why the proposal above is `compiled_gather` instead — no row, since the current spelling (`gath`) does not itself collide.

## Roster proposals

None in this file.

## Questions

- `v`/`n` in `roundtrip` (lines 69–70) sit right at R7's "about five lines" boundary (the body is five statements). I've kept them as `keep:glance`; if the coordinator counts the `function`/`end` lines against the clause, both cross into `rename` territory (`value`/leaf count spelled out).
- The `f1`/`f2` → `buffer1`/`buffer2` proposal borrows the names the compiled function's own signature uses (`Expr(:tuple, :buffer1, :buffer2, :offsets)`, lines 88 and 95) rather than inventing new ones — flagging in case the coordinator would rather keep test-side names independent of the generated signature's.
