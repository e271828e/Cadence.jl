# Chapter 8: findings for the owner

Serious findings from chapter 8's rewrite, each with its evidence and a
recommendation. The orchestrator does not rule on them, except where an
item says it ruled and lists the ruling here for audit.

## E1. `Group`'s rate scope exists in `src/` and nowhere in the design

Survey F6, q1. Unruled; the text stays as written.

- The spec's `Group` sketch (§8.5, old spec 2794–2813) has four fields and
  no `sample_times` method.
- `src/assembly.jl` 292–311 adds a fifth field, `rates`, a `rates = (;)`
  keyword and `sample_times(g::Group) = g.rates`. `test/test_discrete.jl`
  uses it.
- §8.5 already relies on it: "`(children = Relative(2),)` is the uniform
  spelling for a `Group`" (old 2772–2773).
- No decision entry records the field, and neither `pending.md`'s deviation
  list nor `implementation.md` names it.

Recommendation: record the built shape. A new entry rules the field, the
keyword and the method, and the sketch gains them. The rate scope is what
makes `(children = Relative(2),)` work, and every `Group`-hosted discrete
test relies on it. The alternative is to remove it from `src/` and drop the
sentence from §8.5.

## E2. The naming convention's semantic axis was inverted in a move

Survey F1, q8. Ruled by the orchestrator as a transcription correction
(brief R8); listed here for audit.

- §8.1 (old 2052–2054) says a declaration "names its *content*, never the
  *consequence* the declaration has".
- Before commit `c512ee6` the same paragraph read "A bare-noun declaration
  names the *consequence* a declaration has rather than its *content*."
  That commit moved the paragraph out of Part V and inverted the sentence.
- D-146's Rationale applies the axis that way: `faces`/`selectors` "were
  content-named where the spec's own `exports` precedent is
  consequence-named". The paragraph's own last sentences agree: the
  `*_connections` family names content "deliberately", as a recorded
  exception.

Ruling: restore the consequence reading, citing D-146. No Position states
the axis, so track 2 owes one.
