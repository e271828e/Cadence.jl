# Chapter 7: final verification (step 6b)

Diff: `git diff 0128709 -- docs/spec_rewrite/ch07/units/`.

## Coverage

- 14 diff hunks in `new.md` and `companion_addition.md`: A 3, B 3, companion 1,
  C 5, D 2. They hold 39 logged edits: 38 fixer entries in `chapter_fixes.md`
  and the orchestrator's E12 revision. Every other changed line is an E18
  rewrap of a paragraph that an edit touched or that E18 names. The
  orchestrator rewrap of unit C (the "continuous side" paragraph) is also
  E18's §7.3 309–312 item.
- 4 inventory hunks, one per unit. Every edited claim carries its item in
  `ruling`, and every new gloss or clause is in `added`.
- `check_unit.py ch07 check X`: `checks failed: 0` for A, B, C and D.

Checks (a) to (e) hold for every edit. Each edit does what its ruling orders.
No claim changed meaning, strength, scope or causal direction against
`old.md`. Antecedents hold: "the table" at C 30 now points back to the signal
table at C 19, "those declarations" at C 82 follows the `x_init` sentence
after E10, "That multiplicity" still follows the continuous calls, and "It"
at D 35 is the fused formulation. Each inserted gloss uses its glossary
entry's words (view, boundary, tier, snapshot, measurement seam, tick,
replay, buffer). Citations stay with their claims: E11 moves D-077 onto the
bold sentence that now holds "never by initial value", and E14's split keeps
D-288 and §9.7 on the first sentence and §11.2 on the second. Bold is
unchanged. E11 adds "never by initial value" outside the bold span. No term
has two glossary links in one section.

## Problems

1. **Unit D, hunk 1 (§7.4 prior art), line 29: wrap.** Current: "Simulink
   diagrams make integrators explicit blocks. Derivatives are ordinary wires
   into `1/s`, and the" on one source line, 100 rendered columns. Why: the
   orchestrator's E12 revision rewrapped lines 27–28 and joined two lines.
   The touch log records only the wording. Fix: rewrap lines 27–36 greedily
   at 80 rendered columns, with no word changes.

## Minor, no fix required

- Unit D inventory: "Their allocation is zero by idiom." now carries the
  added `newcites: ["§7.3"]` but keeps `tag: "F"`. The brief tags an added
  citation `C`. Its `new` span also overlaps the next claim's span. The
  checker passes either way.
- `units/B/companion_addition.md` lost its trailing newline in the rewrap.
  This matters only if the landing splices it by script.

## Unlogged edits

None in the text, apart from problem 1's join, which the E12 touch made
without logging it.
