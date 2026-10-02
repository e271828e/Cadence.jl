# C1 verify report

**Counts.** Phase 1: 65 assertions (V1–V65). Inventory: 79 claims. 78 MATCH, including C1-065, which R7 maps to D-205's Rationale (log 7261–7263); that span says the same thing. 1 DRIFT, a citation-scope drift only. 0 LOST. ADDED: 6, all glosses, the sweep definition or the F14 clause. None changes meaning.

**DRIFT**
- C1-016 (citation scope). Old: "…no tick index, and neither does a `t*` boundary." (uncited). New: the same sentence with "(§10.4, D-147)". D-147's Position carries only the `t*` half, and only as "due set empty… the tick counter has not advanced". It does not say "no tick index", and nothing carries the off-tick half (rulings.md admits this). D-185's Rationale ("`t*` emptiness remaining arity selection (no sentinel index…)") fits "no index" better. Fix: keep §10.4 as the `t*` pointer, and either drop D-147 or cite D-185 with D-147 and list both under Rationale-only.

**Citations.** Every old citation survives with its claim. D-019 and D-147 moved within the same paragraph, so the later sentences still cite by adjacency. I checked each added or replaced citation against the log:
- D-019 Position carries the grid, ZOH-at-own-ticks and virtual-assembly rulings. The un-sample reason is in its Rejected list, as the old text had it.
- D-147 Position carries the two variants, interior, boundary, both blocks and the due set, one sentence each.
- D-185 is a true Rationale-only citation for the `(D, Φ)` pair and the gate, and rulings.md lists both.
- D-205 at the boundary-zero due set holds only by implication. The Position says "`g` updates remain gated by `Φ`" and that D-185's "gate composition and residue invariant stand". The words "everything with `Φ = 0`" are D-185's Rationale. This is acceptable under the brief. Adding D-185 beside D-205 would tighten it.
- F7: spec 5047 and D-082 support `tₖ = t₀ + k·h`.

**Bold.** There are 10 bolds, and each is a headline clause followed by its entry. The five D-147 bolds map to five separate Position sentences (variants, interior, boundary, both blocks, due set). They pass the mechanical test, and no ruling is bolded twice. The shared-bold alternative in rulings.md would break the test, so I advise against it. The gate bold also states the definition of *due*. It passes because it is D-185's gate ruling. D-205's publication rule is correctly plain here, because it is bold in §14.5.

**Glossary.** *sweep* is linked once, at its first use (line 45). The two `#g-sweep` links on interior and boundary sweep were dropped correctly. The defining sentence "A sweep is one pass through the execution order" repeats the glossary entry and adds no claim. The new links (frame, signal table, execution order, assembly) each sit at the term's first use, and each gloss matches the glossary.

**F14.** The companion (flight_case_studies.md section 2) shows `outer.output → inner.input`, and spec 5391 has `FCS` with `inner`/`outer`. Both support "outer loops feeding its inner loop". The clause claims no more than that.

**Moves and labels.** M7 (coincidence/stagger) left this unit. The five labels match the brief in order, and the "in that order" promise is kept. R7 and F7 are applied. No other moves.

**Reader-cold names.**
- (2) FCS is now introduced.
- (2), optional: "a receiver" in the intro is self-explaining enough.
- "probe" (line 104) is a spec term with `#g-probe`, but it has no gloss or link. It is cited only to §9.3. This was already so in the old text. Suggest linking it with a gloss.
- `y_state`, `y_direct`, `s_update`, the `s` store, "macro-sequence" and "authored world" are spec terms defined elsewhere (§5.3, §10.6, §14.5), not Flight.jl machinery.
- No category (1) names.

**Other.**
- Lines 45 and 113 run past 80 rendered columns. Line 113 is about 127. Rewrap both.
- The proposed correction in rulings.md ("after the sweep" → "after quiescence") is well founded. D-020 and the glossary's *due* and *quiescence* entries all say "after quiescence".

## Re-check (after the rewriter's fixes)

1. `t*` sentence (C1-016) now cites §10.4 and D-185. D-185 Rationale (log 6502, "`t*` emptiness remaining arity selection (no sentinel index…)") carries "no tick index" at `t*`; listed as Rationale-only. The off-tick half still has no entry, as rulings.md says. Wording unchanged. Clean.
2. Boundary zero (C1-054) cites D-185 and D-205. D-185 Rationale carries "everything with `Φ = 0`", D-205 Position the `Φ`-gated `g` updates. Bullet otherwise unchanged. Clean.
3. R10 (C1-070): only "the sweep" became "quiescence". "In any order", the next sentence and the FCS "therefore" are intact; the causal link still holds. Matches D-020 and the glossary. Clean.
4. Probe: link at first use; the gloss sentence "the build's single evaluation of a user function with real values" is verbatim from the glossary entry and claims nothing more. §9.3 moved one sentence along, to the gloss; §9.3 ("Probing and input synthesis") covers both sentences, so the scope holds. Optional: "synthesized values" next to "real values" may puzzle a cold reader; the glossary's *probe value* entry reconciles them.
5. Rewrap: no prose line now exceeds 80 rendered columns (line 17 is display math). The checker prints "checks failed: 0".

Verdict: clean.
