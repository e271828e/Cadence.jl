# Chapter 8: cold final verification of the post-unit edits

Compared `b04abda:docs/spec_rewrite/ch08/chapter_new.md` (1,770 lines) with the
current `chapter_new.md` (1,733 lines), using
`git diff --no-index -U0 --word-diff` on copies in `scratch_final/`. Each hunk
was traced to `chapter_fixes.md` (P1–P44, P46, P48) or `ruled_edits.md` (K2,
K3, K5, K6, two follow-ups), and checked against `chapter_old.md`,
`spec_style.md`, the glossary (spec 12085–13042), Appendix C (spec
11709–11993) and `src/diagnostics.jl`.

## Counts

- Hunks checked: 75 (line-level, `-U0`).
- Hunks OK: 69.
- Findings: 6. Five sit on hunks (F1–F5, six hunks). F6 is an inventory
  defect left by a hunk whose text is correct.

## Checker

`python3 checks/check_unit.py ch08 check <U>`, last line:

| Unit | Result |
|---|---|
| A | checks failed: 0 |
| B1 | checks failed: 0 |
| B2 | checks failed: 0 |
| B3 | checks failed: 0 |
| B4 | **checks failed: 1** (`SPAN MISSING AT units/B1/new.md B4-025`) |
| D | checks failed: 0 |
| E1 | checks failed: 0 |
| E2 | checks failed: 0 |
| F | checks failed: 0 |

## Findings

**F1.** `chapter_new.md` 859–864 (§8.3, "Schema authority is total over the
table"). Source: none. A whitespace-only rewrap of a paragraph that holds no
edit and that P38/P39 do not list (P38 names 727, 847, 849, 894 for B4; P39
names 838, 850). No word changed.
Fix: record it under P39 in `chapter_fixes.md`; no text change.

**F2.** `chapter_new.md` 1135–1137 (§8.6, "Every pair runs strictly from a
child face to a child face"). Source: none. Same as F1: a whitespace-only
rewrap of an unedited paragraph that P39 does not list (E1: 1141, 1172,
1221). No word changed.
Fix: record it under P39 in `chapter_fixes.md`; no text change.

**F3.** `chapter_new.md` 906 and 909 (§8.5 opening). Sources: P15 (assembly
gloss) and P13 (component link). P15's gloss "(a component of pure
composition)" put an unlinked "component" at 906, before P13's link on
"[components](#g-component)" at 909. The section's first use is now unlinked.
§8.6 (1103) and §8.8 (1519) link component inside the same gloss.
Fix: 906 "(a [component](#g-component) of pure composition)"; 909 plain
"assembles components".

**F4.** `chapter_new.md` 1462 and 1475 (§8.7). Sources: P30 (assembly gloss)
and P15 (component link and gloss at old 1508). The new gloss puts an unlinked
"component" at 1462; the link and its gloss "(the unit of modeling, leaf or
assembly)" come 13 lines later.
Fix: 1462 "(a [component](#g-component) of pure composition)"; 1475 plain
"per discrete component.", dropping its gloss.

**F5.** `chapter_new.md` 1040–1042 (§8.5, `transparent_container` bullet).
Source: K2. Before the split, "([D-211][d-211], [D-215][d-215])" closed the one
sentence that held both rules. Now it closes only the second sentence, and
"`transparent_container` must name a container field of the type, and a name
that matches none is `TransparentContainerUnknown`" carries no citation. K2's
own proposal said to cite on each sentence if the split narrows them, and it
does. Appendix C cites D-211 for `TransparentContainerUnknown`. (The old
chapter cited neither; the unit added both.)
Fix: end the first sentence "… is `TransparentContainerUnknown`
([D-211][d-211])."

**F6.** `units/B4/inventory.json` B4-025 (claim held at `chapter_new.md` 334).
Source: `ruled_edits.md`, follow-up "B1: the store's link moves". The
follow-up changed B1's "The [store](#g-store) (the model's memory, declared by
initial value) is the tier marker" to "The store is the tier marker". B4-025,
a P44 cut, still quotes the old B1 span, so B4's checker fails. The log
reports `checks failed: 0` for B1 only. The claim itself is held in substance
("The store is the tier marker. It is therefore mandatory even when empty").
Fix: set B4-025's `new` to "The store is the tier marker. It is therefore
mandatory even when empty" and re-run B4's checker.

## Checks that passed

- **P43/P44 cuts.** Each cut claim is held in B1 where B4's inventory says:
  the arity criterion (B4-045 to B4-047, the B1 criterion bold with D-263 and
  the `ws_init(c, T)` sentence), the empty store as tier marker and the
  "exactly one of `x_init` and `s_init`" bold (B4-025, B4-038), "in one
  place" (B4-039), `TierUnreadable` (B4-055). The F6 span is the only stale
  string. "The stores" exists as B1's heading (310).
- **Kind names.** Each matches its Appendix C row and docstring.
  `ClassUnreadable` (neither family), `ClassMixed` (`inner_connections` plus a
  leaf declaration), `ContainerMixed` (component and non-component elements),
  `TransparentContainerUnknown` (names no container field),
  `ChildNameCollision` (named at the two-children arm; the sugar arm and the
  sibling-field arm join it in the next sentence and bullet),
  `StoreWithoutUpdate` (non-empty store, no update law). `EventHalfMissing` is
  named where §8.2 states two of its three arms; the third arm (an entry that
  is not a `StateEvent`) is already K17, track 2.
- **Glosses.** All new glosses stay within the glossary: probe, schema
  authority, executor, component, bundle, port, assembly, device ("outside the
  loop" is the glossary's *periphery*), trace, leaf walk, generic holding,
  condition, error locality, did-you-mean. P32's "states its fix" is §13.2's
  didactic style narrowed, not widened.
- **Links.** No section links a term twice. Every other link moved by P7–P16,
  P30 and the follow-ups sits at its section's first use.
- **Bold.** The same number of spans before and after. The only bold change is P24's dropped
  "therefore"; P10 unlinked inside a bold with the bold kept.
- **Meaning.** P24 keeps the invariant as the reason for the direction rule.
  P40 keeps old "no other way" as "only". P21's C172X clause survives at 1654.
  P18's cut clause survives at 481–482. P20's default survives at 919. K6 and
  P22 match §8.2's `y_types` reading.
- **Wrap.** No prose line exceeds 80 rendered columns; only display math
  (1299) does, which is exempt.

## Re-check

I re-checked the four edits that `ruled_edits.md` lists under "Final-verify
fixes", against `scratch_final/v_now.md`. The diff holds exactly those edits.
F1 and F2 are logged under P39 in `chapter_fixes.md`.

- **F3 (906, 909):** component is now linked inside the assembly gloss, and
  "assembles components" at 909 is plain. §8.5 links component once. The gloss
  is unchanged, so it still has one parenthetical. OK.
- **F4 (1462, 1475):** component is now linked inside the assembly gloss, and
  1475 reads "per discrete component.", with the gloss gone. §8.7 links
  component once. The gloss is also gone from F's files, and nothing in §8.7
  needed it. OK.
- **F5 (1041):** "`TransparentContainerUnknown` ([D-211][d-211])." Both
  sentences now carry a citation, and the pair on the second is unchanged. The
  inventory entry D-067 matches. OK.
- **F6:** B4-025's `new` now quotes "The store is the tier marker. It is
  therefore mandatory even when empty", which B1's text holds at
  `units/B1/new.md` 100. OK.
- **Nearby text:** no antecedent moved and no bold changed. Every edited line
  fits in 80 rendered columns (906–909, 1040–1042, 1462–1464, 1474–1477).
- **Checkers:** A, B1, B2, B3, B4, D, E1, E2 and F each end
  `checks failed: 0`.

Result: all six findings are closed, and no new finding.
