# Unit E, §9.7: rulings

Line numbers are `spec.md` lines unless marked `log` (`decisions.md`).

## Corrections proposed

1. **F16, the D-185 citation for arity selection.** Quote, spec 4229–4231:
   "`t*`'s empty due set is **arity selection, not an index trick**
   ([D-147][d-147], [D-185][d-185])". D-147's Position (log 4917–4920) says
   only that the due set is empty at `t*`. The words "arity selection" are
   in D-185's Rationale (log 6468, "`t*` emptiness remaining arity selection
   (no sentinel index fails every gate)"). The new text keeps both citations,
   as the convention allows, and lists the case below. Proposed: a new entry
   that states in its Position that `t*`'s empty due set is arity selection
   and that one gate serves all three tick-sensitive blocks (survey part E,
   item 13). No text change.
2. **F17, the anchors table and the mitigation ladder** (spec 4256–4280).
   Copied verbatim, as the brief freezes them. Evidence that they are stale:
   - `docs/reports/20260930_compile_cost/report.md` §4 (line 216): "§9.7's
     anchor of about 9 s for an 8-partial `Dual` executor did not reproduce".
     Its table gives 2.8 s for 8 partials on 64 loops.
   - The same report, §7 (lines 313–319): the anchor table "is replaced by §1
     and §4"; "Lazy activation saves 2 to 3 s, not tens"; a reduced optimizer
     level "buys nothing measurable"; precompile workloads "remain right, for
     the generic part".
   - `pending.md` 17–24: "§9.7's anchors do not hold", and the ruling on the
     table and the ladder comes first.
   - D-162 Rationale (log 5453) already "demotes §9.7's mitigation ladder to
     optional".
   - "Re-measurement on a real model of that scale is pending (`pending.md`)"
     is half stale. The measurement exists; the ruling is what is pending.

   Proposed text: none here. It belongs to the compile-time ruling.

## Citations added or replaced

Each added citation sits on a bold ruling sentence.

| where in new text | entry | the words that rule it |
|---|---|---|
| "The execution form is a concretely-typed tuple of entries …" | D-086 | Position, log 2449–2452: "schedule data compiled per activation into a concretely-typed entry tuple over statically typed storage, walked by compile-time unrolling". Moved from the reason sentence ("reachable only under full specialization"), which sits in the same paragraph and is the second half of the same Position. |
| "Cells are stored per element type, not per cell" | D-162 | Position, log 5433–5436: "per-eltype homogeneous cell stores: cells flattened by §7.1's leaf walk into one contiguous buffer per element type, build-time offsets carried in entry fields". The old citation at "measured rather than argued" stays. |
| "Phase bodies are the outer decomposition, and they are semantically forced" | D-086 | Rationale only, see below. |
| "Each sweep block compiles in two arities off one entry list" | D-147 | Position, log 4896–4897: "The sweep is two statically distinct variants compiled from one entry list"; log 4909–4910: "the two sweep bodies gain an arity distinction". The old D-147 at "`rhs` takes no index" now rests on this and on the `t*` sentence in the same paragraph. |
| "`t*`'s empty due set is arity selection, not an index trick" | D-147, D-185 | Unchanged citations; D-185's part is Rationale only (correction 1). |
| "These bodies communicate only through the stores and the table" | D-194 | Position bullet 3, log 6770–6772: "passes communicate only through the table and the stores, no value crosses a phase-body or chunk seam". Moved from the fusion sentence in the same paragraph, whose ruling is the same bullet's "Round fusion ceases to be a design constraint on the executor". |
| "Views are spelled rebuild-per-call" | D-086 | Rationale only, see below. |
| "Construction is type-opaque, and only the executor specializes" | D-086 | Rationale only, see below. |
| "The phase bodies are the §7.5 measurement seam" | D-116 | Position, log 3374–3376: "The zero-allocation invariant's measurement seam: `phase_bodies(sim)` returns the compiled bodies of the nominal activation". |
| "The four-body roster is fixed and total" | D-156 | Position, log 5296: "`phase_bodies` always returns the fixed four-body roster, missing phases compiled to no-ops". |
| "These are the bodies the loop runs, not re-derivations" | D-116 | Position, log 3379–3380: "one inspection promise: identity with the bodies the loop runs". |
| "CI is warm-then-assert over the roster" | D-116 | Position, log 3380–3382: "CI is warm-then-assert at per-body granularity (a documented tolerance loosens exactly one assertion)". |
| "each sweep arity in its own right" | D-147 | Position, log 4915–4916: "each arity is asserted in its own right at the CI seam". A mechanism sentence resting on a different entry. |
| "Publication is not a phase body" | D-116 | Rationale only, see below. |

No superseded entry is cited. D-086, D-116, D-147, D-156, D-162, D-185, D-194
and D-253 are all ratified.

## Rationale-only rulings

| bold sentence | entry | field | log line |
|---|---|---|---|
| Phase bodies are the outer decomposition, and they are semantically forced | D-086 | Rationale | 2456 "Phase bodies as the semantically forced outer decomposition" |
| `t*`'s empty due set is arity selection, not an index trick | D-185 | Rationale | 6468 "`t*` emptiness remaining arity selection" |
| Views are spelled rebuild-per-call | D-086 | Rationale and Rejected | 2463 "views rebuild-per-call (hoisting = compiler CSE …)"; 2474 "Framework-maintained view hoisting" |
| Construction is type-opaque, and only the executor specializes | D-086 | Rationale | 2464 "schedule tuples constructed type-opaquely, consumed only by the walk" |
| Publication is not a phase body | D-116 | Rationale | 3388 "publication is not a phase body — the §7.5 carve-out made structural" |

Plain sentences ruled only in a Rationale, left uncited: "Two options this
structure opens for free are recorded, not committed" (D-086 Rationale, log
2458) and "One gate serves all three tick-sensitive blocks" (D-185
Rationale, log 6467–6468; D-185 is cited in the same paragraph). Inside the
frozen block, "Chunking bounds the compile cost" (D-086 Rationale, log
2459–2461) and the ladder (log 2461–2462) also rest on a Rationale only.

## Inbound citations affected

None. No content leaves §9.7. The only move is inside the section: views and
type-opaque construction now come before the compile-cost block. The facts
inbound citations rely on all stay in §9.7: the entry typing (spec 2089,
2095), the executor's definition (2818, glossary 12084), the CSE legality
rule as the "staleness rule" (1546), the two arities in the phase-body
signatures (4884), chunking as the only representation freedom (12063),
`phase_bodies` and its one promise (1848, 12107), re-running `init!` (11085),
the recompilation-granularity sentence (D-147 Rationale, log 4928), and the
entry fields carrying `Φ` (`sample_time_proposal.md` 360, 775).

## Open questions

1. **The frozen block's bold.** The block keeps every word, but its two bold
   spans, "**Chunking bounds the compile cost.**" and the lead-in "**The
   mitigation ladder**", had no D-citation, and the bold check fails on them.
   I removed the `**` markers and changed nothing else. After the
   compile-time ruling, "Chunking bounds the compile cost" should become a
   bold ruling with its entry (D-086 Rationale today, or a new entry), and
   the ladder lead-in should stay plain.
2. **"One promise, and it is diagnostic only (§13.5)."** "It" can be the
   promise or the seam. Appendix B (spec 11083) calls the seam "an
   inspection-only surface", and §13.5's inspection doctrine sits at spec
   8898–8903. The new text, "The seam makes one promise, and it is
   diagnostic only", keeps the ambiguity. Proposed: "The seam is diagnostic
   only ([§13.5][s13-5]), and it makes one promise."
3. **FlightCore in normative text.** "This is the successor of the migration
   suite's `@ballocated f_ode!`/`f_step!`/`f_periodic!` idiom" and the
   FlightCore comparison sentence are lineage, not rules.
   `companions/migration_outline.md` line 39 already says it. Proposed: move
   both sentences there, under the same ruling as unit D's M13.
4. **How many bold sentences D-116 carries.** Four: the seam, the promise,
   CI's warm-then-assert and publication. Each is a separate clause of
   D-116's Position or Rationale. If one bold per entry is preferred, the
   CI and publication sentences can go plain.
5. **Display blocks.** `phase_bodies(sim)` and `@ballocated(body()) == 0` are
   now display blocks. The gate `(tick − Φ) % D == 0` and the arity forms
   `sweep_1()`, `sweep_2(tick)` stay inline. The gate is a formula with a
   Unicode minus, and the arity forms read as names in their bullets.
6. **Stale Spec fields** (survey part E, not changed here): D-033, D-106 and
   D-256 list §9.7, which holds nothing of theirs. D-163 lists §9.7 for a
   float-comparison rule §9.7 does not state, though its Rationale (log 5482)
   does rely on §9.7's chunk-size freedom.
