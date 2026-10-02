# Chapter 8 track 2: cold verification — 2026-10-02

Checks the uncommitted edits in `docs/design/decisions.md`, `spec.md` and
`extensions.md` against `rulings_batch.md` (Status, K10 to K30) and
`backlog_applied.md`. Line numbers are the working tree's.

## Counts

| check | checked | findings |
|---|---|---|
| 1. New entries D-295 to D-299 (35 Position bullets, 5 Rationales, form, placement) | 5 entries | 1 |
| 2. New chapter-8 citations | 34 | 0 |
| 3. Annotations (K18 eight, K19 four) | 12 | 0 |
| 4. Spec field additions (K20 sixteen, D-215's §8.2) | 17 | 0 |
| 5. Outside edits (K17, K24, K26 ×3, K27 ×2, K28, K30) | 9 | 0 |
| 6. Diff hunks no item orders | all hunks | 0 |
| 7. Battery | 4 tools | 0 |

One finding, minor. Three notes record deviations from an item's literal
wording that the applier reported and that hold up.

## Findings

**F1.** `docs/design/decisions.md` 12292, D-295 Rationale. "superseded by
D-263, whose Position states none of these rulings" overstates. D-263's
first bullet carries the `x_init` walk ("the leaf walk that types `init_x`"),
which is D-295 bullet 4's second sentence (12278), as K10's evidence itself
notes. Fix: "whose Position states none of these rulings beyond the walk of
`x_init`".

## Notes (no fix needed)

- **K17 placement.** `spec.md` 2670–2671. K17 says to put the sentence after
  N769's `EventHalfMissing` sentence. It sits two sentences later, at the
  paragraph's end. Placed where K17 says, it would leave "Method lookup
  catches it" and "the omission" without a clear referent. The text matches
  K17's proposal word for word.
- **K10, N456.** `spec.md` 2353–2354. K10 says N456 should cite D-295 "beside
  D-263", but its evidence lists the sentence as uncited, and D-263 does not
  state the rejection. Citing D-295 alone is right.
- **D-297 bullet 4's source.** `decisions.md` 12358–12359. The definition
  ("a `T` belongs in a signature exactly where …") first appears in D-166's
  2026-08-16 annotation. The Rationale names D-166's Rejected list, which holds
  the "criterion, not uniformity" phrase, and D-263's Rationale, which repeats
  the definition. Both clauses have a named source, so this is not a finding.

## What holds

- **Entries.** Every Position clause traces to the source the applier names.
  No clause adds a claim the source lacks. The vocabulary is today's
  (`x_init`, `s_init`, `m_init`, `ws_init`, `sample_times`, root input,
  `Pinned`/unpinned, input face surface, retyped). The renames to
  `Pinned`/unpinned rest on D-167's 2026-09-24 annotation, as the Rationale
  says. The fields (Status, Position headline plus bullets, Spec, Rationale,
  "Rejected. None beyond the source entries' lists.") match D-290 to D-292
  and D-294. All five entries sit before the link-definition marker. The ids
  and the K13 fold follow the Status.
- **Citations.** Each new citation shares its sentence with the source entry
  the item names, or else fills a sentence that had no citation where the
  item calls for one (2354, 2593, 2734, 2985). Each sentence's claim appears
  in a bullet of the cited entry. No bold span in chapter 8 changed.
  `check_bold` still counts 67 spans and 632 words.
- **Annotations.** Each annotation sits after its entry's Rationale, in the
  "Annotation (2026-10-02): amended by D-nnn …" form used at HEAD. Each claim
  matches what the named entry rules: D-165 and D-179 (D-033), D-194 (D-034),
  D-165 and D-194 (D-055), D-170 and D-279 (D-041), D-254 and D-256 (D-042),
  D-039 and D-122 (D-164), D-209 (D-171), and D-211 and D-279 (D-184). Each
  K19 retarget points to a section that holds the content (§8.5 2833, §8.1's
  `isdefined`/`!==` check, §8.8 3556–3557). D-166 is not annotated.
- **Spec fields.** Each added section cites the entry in the landed chapter,
  checked by script for all 17. Each addition follows its field's own order.
  That includes D-170's and D-179's out-of-order §8 runs. D-146 is untouched.
- **Outside edits.** K24 removes only the two asterisk pairs. K26 makes
  exactly the three proposed edits. K27 edits 7406 and the *nominal* entry
  and leaves 7134. K28 replaces only the phrase. K30 adds only the one list
  item.
- **Other hunks.** The only other hunks are the generated index rows and the
  link definitions.

## Battery

- `check_refs.jl`: OK — every citation and every anchor resolves.
- `check_rows.jl`: newly cited by the spec (fine): [295, 296, 297, 298, 299];
  OK — every decision citation names an existing entry.
- `check_bold.jl`: chapter 8: 67 bold spans, 632 bold words; OK — every bold
  span in a rewritten chapter carries its D-citation.
- `check_glossary.jl --strict`: OK (3 advisory unmatched entry terms).
