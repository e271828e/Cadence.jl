# Chapter 8: fixes from the whole-chapter pass

Items of `chapter_pass.md` and `chapter_rulings.md`, applied to `units/*/new.md`
with each unit's inventory regenerated (B3's edited by hand). Every unit's
checker ends `checks failed: 0`. Paragraphs holding an edit were rewrapped to
80 rendered columns.

- P1, B1: `init_*` became "`x_init`, `s_init` and `m_init` describe stores"; the second "the model's memory" gloss is gone.
- P2, E2: "[RHS](#g-flow)" became "[flow](#g-flow)".
- P3, B4: walkthrough 5 names `DeclaredNotProduced` in place of "the completeness pass's error".
- P4, D: "the two-producer check" became "the two-producers error".
- P5, A: fallback form applied: "The reason is how executor entries are typed (§9.7)". The executor link and gloss stay where they were (see the end).
- P6, A: "a binding of a declaration name"; "test on those names".
- P7, B2: `activation` unlinked in the table.
- P8, B1 and B2: `port` linked and glossed at its first §8.2 use; plain at B2. The cells gloss was split into "There is one cell per output [port] (one declared input or output)", to avoid a nested parenthetical.
- P9, B1: `component` linked with "(the unit of modeling, leaf or assembly)" in the new opening sentence of P27, which is now its first use; `bundle` linked and glossed. The workspace gloss split into a second sentence, "The workspace arrives as the `ws` [bundle] field (…)", to avoid nesting.
- P10, F: `generic holding` linked and glossed in §8.8's context sentence; the bold is plain.
- P11, A: schema authority linked and glossed at 67; store, class and assembly linked.
- P12, B4: `component` linked in §8.3's opening; plain at 851.
- P13, D: `components` linked in §8.5's context sentence; plain in the class gloss.
- P14, E1, E2, F: port linked and glossed (E1); component linked inside the assembly gloss (E1); store linked (E2); in §8.8 the `World` assembly gloss became an appositive with component linked, ports linked inside the face gloss, conditions linked with an appositive gloss (a second parenthetical would have broken the one-per-sentence rule).
- P15, A, B4, D, E1, F: glosses added for probe (A), port (B4, with "A probe is …" as a following sentence), assembly (D, F), device and trace (E1, one following sentence), component (F 1508). §8.8's assembly is covered by P14, §8.7's by P30.
- P16, B1 and B2: structure-step gloss moved to its first use in B1; plain in B2.
- P17, B1 and B2: B1 says "the leaf marker `Pinned{P}`"; B2 says "the `Pinned{P}` marker (above)", its gloss sentence cut and mapped to B1's span.
- P18, B2: the repeated "because" clause cut, mapped to the root-input opening.
- P19, D: the bullet's gloss sentence deleted; the did-you-mean gloss reworded to "(the offending name plus the list-in-hand it should have matched)", which holds the cut claim.
- P20, D: "and its default is `nothing`" cut after the code block, mapped to the opening.
- P21, F: "`select` exists for feed lists, the idiom of "One authored feed list" below. There the feed list already computes the `except` tuple." The scale clause maps to 1689's.
- P22, E1: "([§8.5][s8-5])" became "([§8.2][s8-2])".
- P23, B4: "Walkthrough 3 of [§8.4][s8-4], the forgotten branch field, holds." This avoids a possessive citation.
- P24, E1: bold first, "**Direction is declared by the method**, not inferred (D-170). The reason is one invariant that spans all three declarations." "it" became "the direction".
- P25, B3: "What remains is deliberate, and it comes in two bugs. The first is writing `Pinned` … The second is omitting it …".
- P26, A: roadmap rewritten as given; §8.5 now names container children and `Group`.
- P27, B1: §8.2 opens with its context sentence above the `Engine` block; the old sentence after the block is gone.
- P28, B4: §8.4's opening rewritten as given, with error locality linked and glossed.
- P29, D: "what arity those declarations take" added to §8.5's context sentence.
- P30, F: §8.7 opens "An [assembly] (a component of pure composition) schedules its children through one declaration, `sample_times`, its [rate scope]."
- P31, B4: "The property that stage 1 takes no inputs …".
- P32, B3: "A didactic diagnostic is one that states its fix (§13.2)." follows the hint's sentence. The hint already sits in a parenthetical, so a second one was avoided.
- P33, B4: "the split state letters (`x` for continuous state, `s` for discrete, [D-195][d-195])".
- P34, B4: "A type declaring both the leaf and the assembly families of declarations, or neither, meets the class errors of §8.5."
- P35, B2 and B3: option 2. "`RQuat` is a domain wrapper type (§7.1)." follows the table; B3 reads "`Ranged` is a domain wrapper type too".
- P36, D: quotation marks dropped.
- P37, F: "wires `mode_req` and `EAS_ref`, the equivalent-airspeed reference. The remaining faces stay exported …". "only" was left out because the old text has no "only".
- P38, A, B1, B2, B4, D, E1, E2, F: all twelve lines rewrapped. Only the exempt display math runs past 80.
- P39, all units: listed short lines rewrapped; double blank lines at the B1/B2 seam and before §8.3 collapsed. Line 630 is left as it is (see the end). The rewraps include the §8.3 paragraph at chapter_new.md 859–864 and the §8.6 paragraph at 1135–1137, whitespace only (final verifier F1, F2).
- P40, B4: "FlightCore is the precedent. There an intermediate could be inspected only by putting it in the model's output."
- P41, E1: "The example carries two more facts."
- P42, B2: "A `u_types` declaration".
- P43, B4: Completeness reads "No arity carries a tier (above)". The cut claim is split in two, mapped to B1's criterion headline and B1's `ws_init(c, T)` sentence, `"ruling": "P43"`.
- P44, B4: "An empty store owes nothing (above)"; "Tier is declared by the store, as "The stores" above states (D-195, D-263)"; `TierUnreadable` sentence cut. Cut claims map to B1 spans, `"ruling": "P44"`. "A stateless leaf … the same way", the `x_init(::C) = (;)` sentence (§13.7's steering) and the `s_init(::C) = (;)` sentence (ticks, held outputs) stay, because B1 has no identical span for them.
- P45: no edit (both bolds stay).
- P46, D: "It is a build error, `ClassUnreadable`, naming both families"; "The error is `ChildNameCollision`." follows the collision bullet's bold. Both match the kinds' conditions in Appendix C and `src/diagnostics.jl` / `src/assembly.jl` (the bullet states the `:two_children` arm).
- P47: no edit (left as written).
- P48, B4: "is a build error, `StoreWithoutUpdate`" and "is a build error, `EventHalfMissing`". Each sentence states the kind's condition. `EventHalfMissing`'s third arm, an entry that is not a `StateEvent`, is not stated as an error in §8.2. That goes to track 2.

## Partly applied

- P5: the primary fix was not applied. Its gloss "the compiled form of one step of the stage execution order" describes an entry. The glossary gives "the compiled form of the stage execution order" for the executor and does not call an entry one step. The item's own fallback sentence was applied instead.
- P39, line 630 (B3): "A custom struct is a first-class port type, as in" stays short. The next token is the code span `` `contact = GearContact{Float64}`, ``, which would reach 81 rendered columns. Splitting the span was not worth the change.
