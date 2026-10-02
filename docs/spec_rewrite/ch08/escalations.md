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

## E2. The naming convention's semantic axis: D-146 and D-267 disagree

Survey F1, q8. The orchestrator first ruled a transcription correction
(brief R8), then withdrew it after unit A's verifier found D-267. Unruled;
the text stays as written.

- §8.1 (old 2052–2054) says a declaration "names its *content*, never the
  *consequence* the declaration has".
- Before commit `c512ee6` (2026-09-23) the paragraph read "A bare-noun
  declaration names the *consequence* a declaration has rather than its
  *content*." That commit moved the paragraph out of Part V and inverted
  the sentence.
- D-146's Rationale reads the axis as consequence-naming: `faces`/`selectors`
  "were content-named where the spec's own `exports` precedent is
  consequence-named, naming the role the declaration plays rather than the
  material it returns".
- D-267's Position, ratified after the move, rules §8.1's class 1: "a
  declaration is a noun phrase naming what it returns". That is the content
  reading, and it is what the text says now.
- The paragraph is incoherent under either reading. Under the content
  reading, the sentence saying `claims`/`reads` "apply that axis"
  contradicts D-146, and the `*_connections` family's content naming is no
  exception. Under the consequence reading, class 1 two paragraphs above
  contradicts it.

Recommendation: decide which axis holds. If D-267's class 1 is the rule,
the semantic-axis paragraph should drop the consequence vocabulary and say
that `claims`/`reads` and `input_passthrough` were named by what they
return. If D-146's axis holds, class 1 needs the bare-noun scope the
pre-`c512ee6` text had. Either way a Position should state the axis, since
today only a Rationale does.
