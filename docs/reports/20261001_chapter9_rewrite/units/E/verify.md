# Unit E (§9.7): cold verification

**Counts.** Phase 1 found 105 assertions (V1–V105). The inventory has 106 claims, with 106 MATCH, 0 DRIFT and 0 LOST. ADDED has 11 entries: 6 `####` labels, 4 transitions or pointers, and 1 borderline lead-in. `check9.py check E` reports 0 failures.

**Frozen block (spec 4247–4280 = new.md 116–149).** I diffed it against the current spec. With `**` stripped from the spec text, the two are byte-identical, including line breaks, the italic `*only*`, the table and the colon. The only changes are the two bold removals.

On those removals:
- "The mitigation ladder" is a lead-in label. Removing its bold is what the convention requires, and the survey says the same (§9.7's bold lead-ins "become `####` topic labels or plain text").
- "Chunking bounds the compile cost" is a ruling. It rests only on D-086's Rationale, log 2459–2461 (survey row 141, class R). Removing the bold drops its ruling mark, and nothing else in "Compile cost" is bold.

Verdict: acceptable. It breaks the brief's "verbatim" by 8 characters, but it is the least-bad way to settle the conflict between the freeze and the bold rule, because the other fix would add `([D-086][d-086])` inside the frozen block. It is declared in rulings.md OQ1, and the user should approve it. Fix after the compile-time ruling: restore "**Chunking bounds the compile cost** ([D-086][d-086] or its successor)".

**Citation-scope notes (MATCH, no fix needed).** Three citations moved to the bold headline of the same paragraph.
- E-009: D-086 moved from "reachable only under full specialization" to E-007. D-086's Position states both halves.
- E-033: D-147 moved from "`rhs` takes no index". D-147 still sits in that paragraph, on the `t*` sentence.
- E-040: D-194 moved from the fusion sentence to E-037. Position bullet 3 covers both sentences.

**Citations checked in decisions.md.**
- Every added citation matches the field rulings.md names: D-086 Position (2449–2452), D-162 Position (5433–5436), D-147 Position (4896–4897, 4909–4910, and 4915–4916 for "each arity is asserted in its own right"), D-194 bullet 3 (6770–6772), D-116 Position (3374–3382) and D-156 Position (5296).
- The Rationale-only cases are D-086 at 2456, 2463 and 2464 (plus Rejected at 2474), D-116 at 3388 and D-185 at 6468. All are confirmed, and all are listed in rulings.md.
- No old citation is lost, and no glossary link is lost.

**Bold.** There are 13 spans, each followed by its D-entry, and no ruling is bolded twice.
- Borderline: "**`t*`'s empty due set is arity selection, not an index trick**". D-185 words it as a consequence ("`t*` emptiness *remaining* arity selection"), and the old text bolded only the phrase. Leave it pending survey E-13's new entry.
- D-116 now has four bold headlines: the seam, the promise, warm-then-assert and publication. They are distinct clauses, so this is fine, as OQ4 notes.
- Old `**one** body` became `*one* body`. That is fine.

**Moves.** The order follows the brief: representation, cells, phase bodies, views and construction, compile cost, then the seam. Views and construction moved ahead of the frozen block. No other content moved. The six `####` labels are short topic labels.

**ADDED, borderline.** "The decomposition has these parts." It lists stage-1, stage-2, `x_deriv`/`s_update` and guards/handlers as a closed set, and the old text did not claim the set was complete. Fix: "The blocks are as follows."

**Minor wording (MATCH).**
- E-017: "paying rent" became "paying off".
- E-089: "The seam makes one promise" supplies the missing subject. This fits D-116 ("one inspection promise"). OQ2's reorder would remove the ambiguity of "it".

**Reader-cold names.**
- (1) Flight.jl machinery: "the migration suite's `@ballocated f_ode!`/`f_step!`/`f_periodic!` idiom" (line 197). The spec says nothing else about these names. Support OQ3: move the sentence to `migration_outline.md`.
- (2) Aerospace example: "full aircraft model", "Aircraft-scale model" and "An aircraft package" are inside the frozen block, so leave them for now.
- (3) FlightCore named as the predecessor, "the FlightCore comparison in `migration_outline.md`": fine.
- Other names carried over unchanged:
  - "the staleness rule". The spec uses it only here; §7.1 at 1544 calls it the "buffer-unchanged-within-a-sweep rule".
  - The acronyms SROA, CSE and TTFX are never spelled out.
  - `t*` is used without a pointer to §10.6.

**Other.** "Re-measurement … is pending" is stale (F17), but it is correctly left frozen.
