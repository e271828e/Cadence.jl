# Chapter-pass fixes — 2026-10-01

Editorial fixes from `chapter_pass.md`, applied to `units/<U>/new.md` with the
matching `inventory.json` spans and `added` entries updated. Finding ids are
`chapter_pass.md`'s. Each unit's edits are recorded as a script,
`units/<U>/chapter_fixes_<U>.py` (already applied; they assert on the
pre-fix text, so they do not re-run). `chapter_new.md` was reassembled with
`checks/assemble.sh`.

Checks after the fixes, `python3 checks/check9.py check <U>`:

| unit | checks failed | bold spans (before → after) |
|---|---|---|
| A1 | 0 | 11 → 11 |
| A2 | 0 | 18 → 18 |
| B | 0 | 9 → 9 |
| C | 0 | 16 → 16 |
| D | 0 | 0 → 0 |
| E | 0 | 13 → 13 |

The rendered text of every bold span is unchanged. Only link markup inside
some bold spans was removed (1.15).

## Applied

| finding | unit | change |
|---|---|---|
| 1.1 | A2 | `` `Deployment` `` for the artifact: "The `Deployment` carries", "materializes a `Deployment`", roadmap "how a `Deployment` binds … explains its grid", "any number of `Deployment`s", "backs many `Deployment`s", "Two `Deployment`s compare". |
| 1.2 | A2 | `` `Schedule` `` for the artifact: "builds the `Schedule`"; "The per-component triples are the content of the `Schedule`, which the constructor builds and the `Deployment` carries"; "It is the typed schedule." → "It is typed."; "The `Schedule` is the single source of truth". |
| 1.4 | A2 | "The `GridUtilization` advisory is a deployment warning, so …". |
| 1.7 (C part), 5.4, 6.3 | C | Standalone sentence "An activation is the build's typed products at a given scalar type." removed; the gloss returns as a parenthetical on "non-nominal activation", where old §9.5 had it. Broken wrap at "writes,\nas the probe" fixed. |
| 1.10 | C | "verifies the fold empirically" → "verifies empirically that the check folds away, rather than by assertion". |
| 1.13 | A1 | Resolution list: "the whole-tree (unconnected-input) obligation check". |
| 1.14 | A1 | Roadmap links `Build`, `Deployment`, activations. |
| 1.14 | A2 | `Build` linked at its first use in §9.2. |
| 1.14 | B | "root inputs" linked at "Exactly one kind of terminal has no producer"; `ws` glossed and linked, "`ws`, the [workspace](#g-workspace), and `t`", in the plain sentence before the bold. |
| 1.14 | C | `execution order` linked in the executor gloss; the later link in the `x_projection` bullet removed. |
| 1.14 | E | `executor` linked at "The executor compiles from that order"; the later link in the bold construction sentence removed. Bundle gloss moved from "constructs its bundle (…)" to the linked first use, "the `Δt` of the [bundle](#g-bundle) (the NamedTuple of zero-copy views a component function receives)". |
| 1.15 | A1 | Repeat links removed in §9.1: `g-face`, `g-structure`, `g-outputs`, `g-events`, `g-activation` (×2), `g-root-input`, `g-tier`, `g-feedthrough`. |
| 1.15 | B | Second `g-tier` link removed. |
| 1.15 | E | Second `g-measurement-seam` link removed. |
| 4.2 | A1 | Lead sentence added before the ordering constraints: "This section states the build's steps, what each consumes and produces, and what each checks." Declared in `added`. |
| 5.1, 6.1 | A2 | "Rendering" moved after "The `Deployment`". Labels now read The `Build`, The `Deployment`, Rendering, Grid diagnostics, Warnings. The roadmap sentence follows that order: "what each artifact holds, how a `Deployment` binds, how each artifact prints, how a `Deployment` explains its grid, and where the warnings … live". |
| 5.2, 4.4 | B | The `ws`/`t` paragraph moved up to follow the sourcing list, so both checks come after all sourcing. |
| 5.3 | C | "… the two leaf kinds the declaration ([§8.2][s8-2]) distinguishes, walking and pinned, are checked differently. An opaque leaf has a rule of its own." The second sentence is declared in `added`. |
| 5.5 (C 796) | C | "`Expected`'s order" → "The expected type's order". |
| 5.5 (C 816) | C | "the economics ([D-053][d-053])" → "the check's economics ([D-053][d-053])". |
| 5.7, 6.4 | A2 | Stutter removed: "… and that section's code block gives their `sample_times`. At the root, the declarations are `fcs = Relative(1)` and `gnss = Absolute(Hz(50))`." The over-long line was rewrapped. |
| 5.8 | A2 | "The `Simulation` constructor has three forms, the materialization step and the two sugar forms:". |
| 5.9 | B | The habit bullets open in parallel: "A *self-consistency* assert, such as …, is a regression test about that algebra. Its home is the test suite"; "A *defensive exhaustiveness* branch is the third habit." Then "A defensive-exhaustiveness branch is not banned validation …" replaces "Such a branch". |
| 5.10 | A1 | The root-inputs paragraph now follows the type clauses. |
| 5.11 | C | Per-function bullets reordered so that handlers come before guards, matching the subsections. |
| 5.12 | D | "This section is only a sketch, kept here because it grounds the build's steps." |
| 5.13 | E | "between [chunks](#g-chunking)" linked at first use. |
| 6.5, 2.5 | B | Clock paragraph: "… ([§14.5][s14-5]), so `t` is a fabricated value. … Discrete-tier probes therefore supply a placeholder period (`1.0`) in the bundle. It is a fabricated, probe-scoped value like `t` and like any synthesized input." "Probe-scoped" now appears twice (the bold and the `Δt` sentence) instead of three times. The pointless "below" pointer and the double "So" are gone. "The same doctrine covers the clock." is kept. |
| 6.8 | all | Overlong lines reflowed to 80 columns in A1, A2, B, C, D and E. Short orphan lines left by link edits were reflowed too. |

Inventory notes:

- E: the bundle gloss now sits in E-011's new span, and E-067's new span no
  longer contains it. The gloss's old source is E-067's old span.
- B-020's new span now contains "the workspace". That is a glossary gloss
  with no old source, and the cold verifier should treat it as one.

## Skipped: §9.4 (v4) findings

1.11 ("chunks" → "seeds"), 1.14 (`Build` link at 618), 1.15 (`g-walked`
repeat), 2.4 (the stale `[§9.1]/[§9.3]` pointer at 636), 3.5 (stacked bold
one-liners), 5.6 class 2 at 670 and 737.

## Left for the user

Bold (pending the bold-weight ruling):

- 3.1, 3.2, 6.2: bold weight; no edit.
- 3.3: trimming bold in A1 135–136 and 153–155, and C 827–828 and 940–942.
- 3.4: moving or rewording bold in A1 95, A2 313, B 564 and C 949.
- 3.6: E measurement-seam bold.

Pending ruling F6/F7:

- 2.1: the §9.2 lock clause and immutability argument. Only the word
  "deployments" → "`Deployment`s" was changed in that paragraph (1.1).

Introducing clauses for unintroduced names or Flight.jl machinery (pending
rulings):

- 5.5: E `t*` (also inside bold), E "CSE" (and the frozen block's SROA and
  TTFX), A2 "the gate" pointer to §9.7, D "assignment" (also 6.6), and "the
  probing scalar" (A1, B).
- 5.6: all classes (D `get_x_ss`/`assign_x_ss!`, E migration-suite idiom,
  `fcs`/`gnss`, strut, `RQuat`). In 5.7, `inner` and `outer` still first
  appear in the table header for the same reason.

Changes to a claim, or edits that need confirmation:

- 1.3: whether "structure, outputs, events" names types or fields. D-253 uses
  the lowercase form ("`Build` is structure, dataflow, events and the
  activations"), so the right spelling needs a ruling.
- 1.5: "The nominal activation probes" in place of the nominal evaluation.
  This is survey F11, already in B's rulings.
- 1.6: one gloss per artifact. A shared gloss adds content to one gloss and
  drops it from the other, and A1's gloss sits inside bold.
- 1.7 (A1 part): adding the activation gloss at 155 puts it inside bold.
- 1.8: dropping "scalar-free" from §9.2's opening gloss removes a statement
  at that place.
- 1.9: "the `s_update` block (`ticks`)" and "the `x_deriv` block (`rhs`)"
  assert a mapping the old text never states. Confirm it against Appendix B
  first.
- 1.1, line 349 old numbering: "deployment must declare `Δt_base`" sits
  inside bold and can be read as the step or the artifact. Left as is.
- 2.2: dropping §9.1's "Final divisors … genuinely cannot exist" sentence for
  a pointer removes a claim from §9.1, and no move covers that.
- 2.3: dropping "The `Deployment` constructor takes a `Build` and the grid
  parameters" at 229 removes a statement there. 5.8's wording fix was applied
  without it.
- 2.6: the proposed rewrite makes "assembled from the same probe chain" the
  cause of "fixes the structure and the typing at once", which is a new
  causal link.
- 5.5, A1 78: "the classifier" → "the class reading (step 2)" needs the
  meaning confirmed.
- 6.7: "That is because joint responsibility …" → "Joint responsibility …"
  drops the explicit "because".

Frozen block (E, Compile cost):

- 1.12: "Measured anchors" → "reference measurements", for the compile-cost
  ruling.
- The block is verbatim from spec 4247–4280 except for the two bold markers
  removed earlier. Its first line is still 86 columns long, and it was left
  unwrapped to keep the block verbatim.
- Its `[Chunking](#g-chunking)` link now repeats the one 5.13 added earlier
  in §9.7. Removing it would edit the frozen block.

Other notes:

- 1.15 removed repeat links, although the brief says to keep every link the
  old text had in a section. This followed the instruction for this pass, and
  the removals are listed above so they can be reverted.
- After 5.1, the D-261 rule that opens "Rendering" comes after its
  application in the `Schedule` paragraph ("derived from the rows at
  `compile`, never stored beside them"). 5.1's smaller alternative would move
  only the D-261 paragraph ahead of the `Schedule` paragraph.
- 2.7 needs no action.
