# Chapter 7 track 2: cold verification — 2026-10-02

Checked the uncommitted diff against `backlog_applied.md`, the track 2 status
in `rulings_batch.md`, recipe step 8 and lesson 17, and `decisions_style.md`.
Every source field was opened at its log line, and every line number that
`backlog_applied.md` gives matched.

## Hunks checked

35 hunks at `-U0`: `decisions.md` 10 (index rows, seven annotations, the three
entries, link definitions), `spec.md` 21, `extensions.md` 1, `README.md` 3.
Every hunk is logged in `backlog_applied.md`, including the Appendix A
orchestrator touch at spec 11432. No unlogged hunk.

## Results by check

1. **D-304 to D-306.** Every Position bullet restates its source field. The
   only change of strength is a narrowing that comes from the spec (D-306
   bullet 2's "configured at allocation", §7.3's own words). D-304's type
   stability bullet copies D-235 Rejected word for word, less the citation.
   It does not ratify §7.2's three author rules or the lookup rule (T-E1,
   T-E2). Vocabulary is today's. `project` (D-305 Rationale) and "scoped
   poison" (D-306 Rationale) appear only to name an old spelling and a
   rejected mechanism. Format matches the template, and the
   "None beyond the source entries' lists" Rejected line follows D-29x
   precedent. The Spec fields list exactly the sections that cite each entry.
   D-304 adds §7.2 to the Status's "§7.1, §7.3" because T-A9 and T-A10
   joined it, which is correct. Titles are 12 and 13 words.
2. **Annotations.** All seven are dated 2026-10-02, in the
   `Annotation (date):` form, and placed before `**Rejected.**`. Each is
   accurate against the spec and the entries it names. D-203's claim holds:
   §7.2 at D-203's commit (8abd821) has no clock, time or seed sentence, and
   no spec sentence has one today. Two citation nits are below (P2, P3).
3. **Chapter 7 citations.** Each sits beside its source entries, or alone on
   an uncited sentence. `check_bold.jl` reports 12 spans and 119 words for
   chapter 7. One placement problem is below (P1).
4. **Outside chapter 7.** §9.7 4833, Appendix C 12134 (§4.3 states the
   refusal at 546–548), glossary *scratch* 12616 (§7.5 names no integrator
   buffer or mid-step table), §8.2 2263, §5.2 822, glossary *one home per
   datum* 12599, Appendix A 11432 and `extensions.md` 283 (matches §7.2 rule
   3 at 1684): each is correct and no wider than ruled. No added line
   renders past 80 columns except two entry headings, which cannot wrap.
5. **README.md.** All four bullets are accurate at their lines (spec 304,
   331, 7886–7887, 10322).
6. **Battery.** `check_refs.jl` OK, `check_rows.jl` OK (D-304 to D-306 newly
   cited), `check_glossary.jl --strict` OK, `check_bold.jl` OK. After
   `linkify.jl`, the `git diff --stat` and the diff hash were unchanged.

## Problems

- **P1 (medium). spec 1741–1742**, "It is not snapshotted, not replayed and
  never a condition target ([§14.1], [D-306])." D-306 covers only the last
  clause. "Not snapshotted, not replayed" is T-E11, an owner item that must
  stay uncited. A citation at the end of the sentence reads as if D-306
  ratifies all three clauses. Fix: split the sentence into "It is not
  snapshotted and not replayed. It is never a condition target ([§14.1],
  [D-306])."
- **P2 (low). log 3520–3523, D-116 annotation**, "the invariant covers the
  stepping loop, and publication is not a phase body ([D-305])." D-305 records
  only the scope. "Publication is not a phase body" is D-288's Position. Fix:
  "...covers the stepping loop ([D-305]), and publication is not a phase
  body ([D-288])."
- **P3 (low). log 1119–1121, D-035 annotation**, "returning it from
  `y_state`." D-252, the entry the annotation names, says `output_state`, and
  D-267 renamed it. D-231's annotation cites D-267 for its renames. Fix:
  "returning it from `y_state` ([D-267])."
- **P4 (low). log ~12690, D-304 bullet 3**, "The isbits check is one exact
  predicate per field". D-231's Rationale says "The check", meaning the
  isbits-or-`Symbol` check, so "isbits check" misnames it. Fix: "The check
  is one exact predicate per field and does not recurse."

## Watch items (no fix needed)

- spec 1680, "Three rules are author-facing ([D-011], [D-235], [D-304])".
  D-304 sits beside its source entry, as ruled, and adds nothing beyond
  D-235's words. The three rules stay T-E1.
- spec 1707: D-304 closes a two-clause sentence and covers only "no
  arithmetic". The buffer clause rests on D-302, cited one sentence earlier.
- The Position bullets carry short reasons ("because ...", "for its
  publication races"). `decisions_style.md` puts reasons in Rationale, but
  many existing Positions do the same. Optional.
- Outside the ruling's scope: D-035's Position still names `h_zu`/`h_z`, and
  the T-B2 annotation does not mention them. D-013's annotation covers the
  `z` → `s` rename only for D-013.

## Fixes applied by the orchestrator

- **P1.** §7.3 now reads "It is not snapshotted and not replayed. It is never
  a condition target (§14.1, D-306)." The first sentence stays uncited, an
  owner item.
- **P2.** D-116's annotation cites D-305 after "the stepping loop" and D-288
  after "publication is not a phase body".
- **P3.** D-035's annotation adds "D-252's `output_state` is `y_state` since
  D-267."
- **P4.** D-304's bullet reads "The check is one exact predicate per field".

The battery is green after the fixes, and `linkify.jl` re-runs as a no-op.
