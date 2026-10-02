# Unit C verification (§7.3)

**Counts.** 81 inventory claims: 79 MATCH, 2 DRIFT (minor, one item), 0 LOST. 84 phase-1 assertions. 10 ADDED entries, none meaning-changing. `check_unit.py ch07 check C` prints `checks failed: 0`.

## DRIFT

- **C-069/C-070 (minor causal).** Old text: "`Xoshiro` is mutable, so it is scratch and lives in the workspace … immutable, so they are state and live in `s`". New text: the bold states the placement with no cause. Then "mutable, so it is scratch" and "immutable, so they are state". The step from mutability to the workspace now depends on the definition of a workspace as mutable scratch. That inference holds, so the fix is optional: "so it is scratch and lives there, allocated once" and "so they are state and live there".

## ADDED

All ten are glosses that match the glossary (buffer, store, tick, replay, tier, probe, boundary, blessed), the roadmap sentence, the "rests on what state is" transition and the `#### Idioms` label. None claims more than a pointer.

## Citations

- Every old citation survives with its claim. D-183 moved from "No poisoning…" to the paragraph's bold first sentence. The whole paragraph is still adjacent to it, which is acceptable.
- **D-013** (×3). The Position reads "Immutable `z` in cells + workspace + snapshot idiom". With `z` read as `s` and cells as stores, it carries `s` in stores, the workspace and the Kalman idiom. No old vocabulary is imported. It does not name `m`. `m`'s store home is carried by D-302 ("`x`, `s` or `m`") and D-231 ("any leaf's `m`"). Optional fix: add D-302 at the bold. At "component-declared mutable scratch, instantiated by the framework", D-013 carries only that a workspace exists. This is thin but true.
- **D-302**: "Stores are not cells" carries the claim. **D-074**: "`project(comp, x)` alone stays positional" carries it, and §5.2 at spec 719 cites it the same way.
- **D-183** (×2): the Position carries both claims word for word.
- **D-077** (×2): "Workspace by allocation … the method *is* the allocator, called per activation and per scratch-store set" carries both claims.
- **D-263**: bullet 4 carries "both tiers", and the head sentence ("every contract declaration takes the component alone") carries "the one declaration that does".
- **D-231** (×3): sentences 1, 2 and 3 carry the three bolds.

## Bold

Seven bolds. Each is a headline clause with its D-entry in the same sentence. None sits on mechanism, a definition or a lead-in.

- **D-231.** D-231's third Position sentence joins its two halves with a semicolon, which the brief's one-bold test would split. R4 reads it as one ruling, so it is fine.
- **No ruling is bold twice.** §8.1 (spec 2254–2258) states "by allocation" plain, and §9.1 bolds the check rather than the field rule.

## Moves

R4, M6, M7, F1, F2, F3 and F5 are done.

- **F1.** Only the `s_init` line differs in the code. Both blocks are otherwise byte-identical.
- **M6.** "That multiplicity" still directly follows the continuous calls.
- **M7.** The double-buffering sentence is one sentence that closes the stores block and cites D-013.
- **One unlisted reorder.** Within the field-rule paragraph, the `String` sentence now comes before the `Symbol` sentences. Scope is unchanged.
- **Quoted phrases.** "governed by contract rather than by checks" and "interned, immutable and never freed" are verbatim.
- **Glossary links.** The second `g-tick` link was dropped and the `g-store` link added. Both changes are fine.

## Other

- **Define-before-use.** *activation* is linked at its first use (line 81, inside the bold) and used again at line 88 ("`Dual` activation"), but its gloss stays at line 98. Fix: move "(the build's typed products at a given scalar type)" to line 81, after the bold clause.
- **Two senses of "contract".** After the M6 merge, "`x_init` … and the contracts take the component alone" sits next to "Nothing in the workspace contract is tier-specific". These are two different senses of "contract". Fix: write "the contract declarations".
- **Two senses of "snapshot".** The idiom's "snapshot" (copy scratch into an isbits value) differs from the glossary's *snapshot* (the per-boundary publication). Neither old nor new introduces it. Optional clause at line 121.
- **Three "Why" reasons.** old.md has two **Why.** labels, not three. Both reasons survive with their causal direction, and so does the "because the discrete tier never runs at another scalar" clause.
- **Cosmetic.** Line 127 is not wrapped.

## Reader-cold names

- **No category (1) or (3) names.** No Flight.jl machinery appears, and FlightCore is not named.
- **Category (2), borderline.** The "n≈20 Kalman filter" is generic estimation, not aerospace.
- **Example types.** `KF`, `KFState` and `Noise` are introduced only by context, as in old.md. `KF` must stay verbatim (§8.1).
- **Other names.** `Dual` is used earlier in §7.2. StaticArrays, `Xoshiro`, `mul!` and `cholesky!` are ordinary Julia names. "Scratch-store set" points to §14.8.

## Re-check

`check_unit.py ch07 check C` prints `checks failed: 0`. All five edits pass.

1. **PRNG causes (C-069, C-070).** Both causal links are restored. "The values" still refers to the bold's "the values that determine its next draw", two sentences back, with no closer plural noun in between. The new sentences repeat where each thing lives, which the bold already says. That repetition is acceptable.
2. **Gloss sentence (C-082).** The *activation* gloss matches the glossary word for word and now comes before its next use. The gloss at the allocator paragraph is removed. The *tier* gloss ("the continuous or the discrete side") matches the glossary's "the continuous or discrete side of the hybrid formalism". The sentence claims nothing more, and it is declared under `added`.
3. **"The contract declarations" (C-048).** The new phrase means what the old one did, and it no longer collides with "workspace contract".
4. **Stores bold.** It now cites §7.1, D-013 and D-302. D-302's Position ("home of … `x`, `s` or `m`") covers `m`.
5. **Rewraps.** Line 104 is 86 characters (cosmetic). The code line over 80 characters is the F1 line, which must stay as it is. Line 16 breaks right after the citation, which is harmless in Markdown.
