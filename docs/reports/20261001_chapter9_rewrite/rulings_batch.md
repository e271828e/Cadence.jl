# Chapter 9 rewrite: rulings batch — 2026-10-01

This batch gathers every open ruling from the six units' `rulings.md` and
`verify.md`, `chapter_pass.md`, `inbound_check.md`, `survey.md` parts E and F
(items 20–26), and the two known §9.4 trial items. Items several sources raise
appear once and cite every source. Items that a later fix resolved were dropped.
The list at the end names them.

Locations are unit `new.md` lines as of 22:05 on 2026-10-01, after the
chapter-pass editorial scripts (`units/*/chapter_fixes_*.py`) ran. `v4` means
`docs/reports/20261001_spec_rewrite_sample/versions/v4_flat.md`. `spec` and
`log` mean `docs/design/spec.md` and `docs/design/decisions.md` at the working
tree. `chapter_new.md` predates the editorial scripts, so its line numbers in
the sources are off by a few lines.

An item **blocks landing** when one of these holds:

- the rewrite caused the problem;
- the item departs from the brief and needs approval;
- landing the chapter without it breaks something outside the chapter;
- applying an already-ruled change depends on the item.

Problems inherited from the old text do not block landing.

## Summary

| group | items | block landing |
|---|---|---|
| 1. Convention questions | 9 | 4 |
| 2. Factual corrections inside the chapter | 20 | 0 |
| 3. Edits to §9.4's v4 text | 6 | 3 |
| 4. Moves to confirm | 11 | 7 |
| 5. Unintroduced names and Flight.jl machinery | 14 | 0 |
| 6. Edits outside the chapter | 9 | 4 |
| 7. Log track 2 | 27 | 1 |
| 8. Problems outside the chapter | 7 | 0 |
| **total** | **103** | **19** |

## Status (2026-10-02)

Every item below is closed except R29. The owner ruled checkpoints 2 and 3
and delegated the rest (groups 1, 3, 4, 6, 7 and 8 not ruled at checkpoint 3)
to the orchestrator. Where an item was applied, the record is the log named.

| items | outcome | record |
|---|---|---|
| F6, bold trim | applied | `ruled_edits.md`, `trim_log.md` |
| R1 | applied: one bold per Position sentence or bullet; semicolon-chained rulings in old entries count as bullets | `ruled_edits.md` |
| R2, R3, R4, R36 | applied as proposed | `ruled_edits.md`, `units/S94/changes.md` |
| R5, R6 | ruled as proposed: Rationale-only rulings keep their bold; bold where the section states what the entry decides | — |
| R7, R8, R9, R37–R42, R43, R46 | confirmed; no text change beyond what was already done | — |
| R10–R26, R28, R44, R45, R47–R60 | applied (R15 scoped per-leaf to concrete entries; R49 "landing-gear", no package; R50 "a discrete GNSS component", not "a GNSS receiver") | `rulings_applied_A.md`, `rulings_applied_B.md`, `final_verify.md` |
| R27 | both citations kept; D-053 annotated (R91) | `backlog_applied_2.md` |
| R29 | **open**: deferred to the compile-time ruling in `pending.md`, with the SROA/TTFX acronyms and chapter_pass 1.12 | — |
| R30–R33, R35 | applied to §9.4 | `units/S94/changes.md` |
| R34 | rejected (no §9.4 clause; §8.2 states it) | — |
| R61–R64, R70, R94 | applied at landing (`9a7d84f`) | report, step 7 |
| R65–R69, R97–R103 | applied; R69 leaves D-139's and D-152's Rationale citations as history | `backlog_applied_1.md` |
| R71 | accepted at checkpoint 1: rule 2's citation exception covers moved content | — |
| R72–R74, R77–R85 | new entries D-283 (Δt_base binding and the rate fold), D-284 (grid diagnostics), D-285 (§9.3 probe rules), D-286 (pinned leaves), D-287 (conformance details), D-288 (executor structure; chunking and the ladder excluded); chapter 9's citations moved to them | `backlog_applied_2.md`, `backlog_verify.md` |
| R75 | folded into D-282's Position; §9.2 cites D-282 | `backlog_applied_2.md` |
| R76 | rejected: the factorization's reason, not a rule | — |
| R86 | no entries: the first rests on D-253; the kind name waits for §8.2's rewrite | — |
| R87–R89, R91–R93 | annotated | `backlog_applied_2.md` |
| R90 | already annotated on D-077 (2026-09-24) | — |
| R95, R96 | applied; D-066, D-256 and the superseded D-166 left as they were | `backlog_applied_2.md` |
| found in passing | §10.4's convergence paragraph and the glossary `Δt_base` entry name the `Deployment` constructor; `check_refs.jl`'s comment matches R102 | `backlog_applied_2.md` |

## Already ruled

- **F6, "under the lock" (§9.2).** Apply A2's proposed text: "The one mutable
  thing on the artifact is the lazily populated activation dictionary, whose
  insertion is torn-state-free." Sources: A2 rulings correction 3, survey F6,
  A2 verify A2-056, chapter_pass 2.1. D-253 bullet 5's "under the existing
  lock" stays open as a log item (R89).
- **Bold weight.** Trim every bold span to its headline clause, the shortest
  clause that states the ruling, with the D-citation following it. Sources:
  chapter_pass 3.1, 3.3, 6.2. The 3.3 trims (A1 gloss inside the bold, A1's
  three linked names, C's real-time aside, C's payload diff list) fall under
  this ruling.

F7 (R16) and F8 (R17) remain open.

## 1. Convention questions

### R1. Several bold sentences from one entry — blocks landing

- **Where:** §9.2 D-254 at A2 24, 88, 162, 220; D-186 at A2 69, 99, 118. §9.3
  D-115 at B 35 and the `t` sentence, D-051 ×2, D-142 ×2. §9.5 D-053 at C 73,
  82, 137, 164, 177, 189, 198, 202. §9.7 D-086 ×4 and D-116 ×4 (E 152–202).
  §9.4 D-052 ×3 (v4). D-253 ×6 across §9.1, §9.2 and §9.4.
- **Problem:** The sources disagree on whether several bold sentences that
  state clauses of one Position count as one ruling bolded several times.
- **Evidence:** A2 verify: "Ruling bolded three times … Fix: bold only 'A
  `Deployment` is scalar-free'." (The "carries everything" sentence is now
  plain. The `Schedule` and grid-diagnostics bolds remain.) C verify: D-053's
  "uniform", guard-form and handler-`m` bolds "are clauses of one Position
  sentence, so this is near a ruling bolded three times". chapter_pass 3.2:
  "Each bold states a different part of its entry, so none is a duplicate
  under the convention. The weight comes from the count." Also A2 OQ5, B OQ5,
  C OQ1, E OQ4 and chapter_pass 3.6.
- **Proposed:** One bold per distinct clause of a Position. Where several
  bolds restate one Position sentence, keep the first bold and make the rest
  plain with the citation. In practice that means the following. §9.2 keeps
  "two steps" and "scalar-free" bold, and makes the `Schedule` and
  grid-diagnostics sentences plain. §9.5 keeps "uniform" and makes the guard
  form and handler `m` plain. §9.7 makes D-116's CI and publication sentences
  plain.
- **Recommendation:** discuss

### R2. Bold removed inside the frozen §9.7 block — blocks landing

- **Where:** E 117 ("Chunking bounds the compile cost") and E 144 ("The
  mitigation ladder").
- **Problem:** The brief freezes spec 4247–4280 verbatim. The two bold spans
  had no D-citation and failed the bold check, so E removed the `**` markers
  and changed nothing else.
- **Evidence:** E OQ1. E verify: "byte-identical" with `**` stripped; "It
  breaks the brief's 'verbatim' by 8 characters, but it is the least-bad way
  … the user should approve it."
- **Proposed:** Approve the removal. After the compile-time ruling, restore
  "**Chunking bounds the compile cost** ([D-086][d-086] or its successor)".
  The ladder lead-in stays plain.
- **Recommendation:** accept

### R3. Which clause carries the bold where the bold is a label or lacks a subject — blocks landing

- **Where:** A1 93 ("It is decided by retyping …"); A2 214 ("The chart guard
  is binary"); B 91 ("Enforcement is the pre-write `UninitializedInputs`
  check …").
- **Problem:** The ruled trim needs a headline clause. At these three places
  the bold sentence has no subject when skimmed alone, is a label, or makes
  the mechanism the subject.
- **Evidence:** chapter_pass 3.4.
- **Proposed:** As chapter_pass 3.4 gives them. A1: "**The walk-compatibility
  clause is decided by retyping both declarations …**". A2: bold the next
  sentence ("The chart prints whole … at most 100 base ticks") and move the
  citation after it. B: "**Every complete-world application, namely `init!`,
  trim setup and trim commit, carries the pre-write `UninitializedInputs`
  check** ([§14.6][s14-6], [D-149][d-149])."
- **Recommendation:** accept

### R4. One glossary link per term per section — blocks landing

- **Where:** A1 (§9.1 repeats removed by `chapter_fixes_A1.py`), B (second
  `g-tier`), E (second `g-measurement-seam`), A2 (merge dropped a second
  `#g-deployment` and two `#g-schedule`), v4 (`g-walked` twice).
- **Problem:** The brief says "Keep every glossary link the old text had in
  that section." The editorial pass and A2's merge have already dropped the
  repeats, which departs from the brief.
- **Evidence:** chapter_pass 1.15 ("keep only the first link in each, if the
  user lifts the keep-every-link rule"); A2 OQ3; A1 OQ5; D OQ6 (links that
  left with M13 content).
- **Proposed:** Lift the rule. Link each term once per section, at first use.
  Apply it to v4's second `g-walked` too.
- **Recommendation:** accept

### R5. Bold on a ruling found only in a Rationale or Rejected field

- **Where:** A2 69, 99, 118 (D-186), 228, 239 (D-187); C 129 (D-263 freeze),
  158, 164 (D-090), 198 (D-053 Rejected); E 47, 99, 107 (D-086), 74 (D-185),
  202 (D-116).
- **Problem:** The brief says to cite such an entry and list it. It is silent
  on whether the sentence may be bold. Some are now plain: A1's fold, A2's
  immutability and C's pinned leaf. The sentences above are still bold.
- **Evidence:** A2 verify ("Keep the bold only if an entry rules it in a
  Position"); chapter_pass 3.4 on C 198; chapter_pass 3.6 on E 202; E verify
  calls the `t*` bold "borderline" because D-185 words it as a consequence.
- **Proposed:** Keep the bold. Track 2 (R72–R85) gives each an entry that
  states it in a Position. Make a sentence plain only if its track-2 entry is
  declined.
- **Recommendation:** discuss

### R6. Bold for a ruling whose home is another section

- **Where:** A1 79 and 83 (store form, D-247; isbits, D-231; home §8.2 and
  §7.3); A1 89 and 93 (D-078, D-263 wire clauses; home §8.2); C 140 and 149
  (D-190, D-111; home §7.1).
- **Problem:** Is the bold placed where the entry's claim is stated or where
  the rule's home is?
- **Evidence:** A1 OQ2 (the entries rule *where* the checks run, which is
  §9.1's claim). A1 verify: when §8.2 is rewritten, "their bold belongs there
  and §9.1's should become plain". C OQ1: "Should the D-190 and D-111 rulings
  stay bold here, or only in §7.1?"
- **Proposed:** Bold where the section states what the entry rules. Keep
  §9.1's bold now, and revisit D-078 and D-263 when §8.2 is rewritten. §9.5's
  D-190 and D-111 stay bold, since the entries rule the conformance predicate.
- **Recommendation:** discuss

### R7. D-070 stays plain in §9.6

- **Where:** D 20, "A failed trim leaves the simulation's stores untouched".
- **Problem:** Survey part A counts it as a rule. D reads it as a consequence
  of D-070's Position, so §9.6 has no bold.
- **Evidence:** D OQ1. D verify: "Keeping it plain is defensible."
- **Proposed:** Keep it plain.
- **Recommendation:** accept

### R8. The heading "Activation, parametric in `T`"

- **Where:** A1 194.
- **Problem:** It is a topic label with a qualifier. Survey part C suggests
  "Activation".
- **Evidence:** A1 OQ3. The §9.4 trial report says this subsection "should be
  merged" with §9.4's list at the real rewrite. M1 has done that, leaving
  three sentences and a pointer.
- **Proposed:** Keep the heading.
- **Recommendation:** accept

### R9. Display blocks and quoted diagnostic messages

- **Where:** A2 (`build(world) → Build` inline; `Δt_base = 2 ms` inline);
  E (the gate `(tick − Φ) % D == 0` and the arity forms inline); B 62–65 and
  C 76–77 (an em dash inside a quoted message).
- **Problem:** These are judgment calls under the brief's display-code and
  no-em-dash rules.
- **Evidence:** A2 OQ4, E OQ5, B OQ6, C OQ6.
- **Proposed:** Keep them as written. Quoted diagnostic text stays verbatim.
- **Recommendation:** accept

## 2. Factual corrections inside the chapter

### R10. The steps table's probed set (§9.1)

- **Where:** A1 39, "the stage functions, guards and handlers, at `Float64`".
- **Problem:** The set lacks `x_deriv`, `s_update` and `x_projection`.
- **Evidence:** §9.3 (B 9–12) and D-050 Position: "All user functions — the
  `h_*` stages, `f`, `g`, guards, handlers and `project` — are probed once".
  Sources: A1 correction 1, survey F1, chapter_pass 2.7.
- **Proposed:** "every user function once, at `Float64` ([§9.3][s9-3])", or
  the full list.
- **Recommendation:** accept

### R11. "Both products are structural" (§9.1)

- **Where:** A1 184.
- **Problem:** The sentence follows a list whose step produces three
  artifacts. "Both" means `Outputs` and `Events` only by inference.
- **Evidence:** A1 correction 2, survey F2.
- **Proposed:** "`Outputs` and `Events` are structural."
- **Recommendation:** accept

### R12. "The nominal `Float64` activation runs at build" (§9.1)

- **Where:** A1 203–204.
- **Problem:** Under the activation heading, this reads as if the activation
  step runs at `Float64`.
- **Evidence:** A1 188–192; D-259 Rationale (log 9746–9750): a `Float64` run
  of the activation step "would be a second pass". Sources: A1 correction 3,
  survey F3.
- **Proposed:** "The nominal evaluation produces the `Float64` activation at
  build. Every other activation re-runs *only this step* ([§9.4][s9-4])."
- **Recommendation:** accept

### R13. "Absolute rate divisors" in the chapter opening

- **Where:** A1 6.
- **Problem:** The build cannot produce final divisors for anchored entries,
  because `Δt_base` binds at deployment. The build produces `(anchor, m, c)`
  triples. "The flat state layout" is likewise an activation's product.
- **Evidence:** A1 131–134; A2 69–83. A1 correction 4 notes that survey F25
  (`extensions.md`) has the same staleness.
- **Proposed:** "the anchor-relative rate triples" for "absolute rate
  divisors". A1 proposes no wording for the state layout. Decide whether it
  changes too.
- **Recommendation:** accept

### R14. The shadowing check is missing from the structure step

- **Where:** A1, after the walk list (A1 57–66).
- **Problem:** Spec 1979 says the shadowing check runs "in the structural
  walk (§9.1)". §9.1 has never mentioned it.
- **Evidence:** D-246 Position (log 8990): "The shadowing check is one pass of
  Stratum A's structural walk". Sources: A1 correction 5, inbound_check note
  on spec 1979.
- **Proposed:** "Before a component's class is read, the walk runs the
  shadowing check ([§8.1][s8-1], [D-246][d-246])." This adds a claim the old
  text lacked.
- **Recommendation:** accept

### R15. "comparing per leaf" is unconditional

- **Where:** A1 93–94.
- **Problem:** The walk-compatibility clause compares per leaf in all cases.
  D-236 checks a concrete entry leaf by leaf and an abstract entry on the
  whole declaration.
- **Evidence:** A1 verify ("One older point, not drift"); D-236 Position (log
  8572): "A concrete entry is checked leaf by leaf." The old text had it too.
- **Proposed:** Scope "per leaf" to concrete entries as D-236 does. No text is
  drafted yet.
- **Recommendation:** discuss

### R16. "Immutable" beside a mutable dictionary, F7 (§9.2)

- **Where:** A2 41–42.
- **Problem:** "The `Build` is immutable" is followed by "The one mutable
  thing on the artifact is the lazily populated activation dictionary" (kept
  by the F6 ruling).
- **Evidence:** D-135 Position limits immutability to the cached "immutable
  compiled artifacts". v4: "An entry is immutable once constructed." Sources:
  A2 correction 4, survey F7, A2 verify (bold on a consequence).
- **Proposed:** "The `Build` is immutable apart from its lazily filled
  activation dictionary, and may back any number of `Deployment`s and
  `Simulation`s, concurrently ([D-135][d-135])."
- **Recommendation:** accept

### R17. "validates device bindings against it", F8 (§9.2)

- **Where:** A2 16–17.
- **Problem:** "It" can read as the face table or the `Build`. After M5 it
  reads as the `Build`, which is the intended reading.
- **Evidence:** D-049 Rejected ("acceptance tests and `attach!` want the
  contract artifact"); D-253 Rationale ("bindings validate against it").
  Sources: A2 correction 5, survey F8, A2 verify A2-084.
- **Proposed:** "against the `Build`".
- **Recommendation:** accept

### R18. "The first three are the products of §9.1's three steps", F5 (§9.2)

- **Where:** A2 21–22.
- **Problem:** Structure, outputs and events come from the first two steps.
- **Evidence:** D-259 Position bullet 1 (log 9717–9721). Sources: A2
  correction 2, survey F5.
- **Proposed:** "The first three are the products of the structure step and
  the nominal evaluation ([§9.1][s9-1])."
- **Recommendation:** accept

### R19. "today's rule", F4 (§9.2)

- **Where:** A2 104.
- **Problem:** A stale relative date from before D-186 added derivation.
- **Evidence:** A2 correction 1, survey F4.
- **Proposed:** Drop "today's rule,".
- **Recommendation:** accept

### R20. "Throws once" is unstated (§9.2)

- **Where:** A2, after the violation list (A2 156).
- **Problem:** Spec 8304, D-229 Position (log 8294) and `implementation.md`
  495 rely on deployment validation throwing once. Neither the old text nor
  the new one says so.
- **Evidence:** D-229 Position: "Deployment validation (§9.1) runs every check
  whose premise holds and throws once." Sources: A2 correction 8, A2 verify,
  inbound_check row 8304.
- **Proposed:** "Every check whose premise holds runs, and the constructor
  throws once."
- **Recommendation:** accept

### R21. The `Schedule`'s two row kinds, F9 (§9.2)

- **Where:** A2 162–168.
- **Problem:** The old list lacked its conjunction. The rewrite states two row
  kinds. A2 asked the verifier to check this reading, and A2's verify.md does
  not mention it.
- **Evidence:** D-254 bullet 2 and D-261 bullet 4: "its component rows and its
  rate-scope rows". Sources: A2 correction 6, survey F9.
- **Proposed:** Confirm the two-row-kind reading. No text change.
- **Recommendation:** accept

### R22. `show(::Events)` and the feedthrough line, F10 (§9.2)

- **Where:** A2 201–208.
- **Problem:** D-257's amendments add `show(::Events)` and a feedthrough-edges
  line in `show(::Build)`. Neither is in the spec.
- **Evidence:** log 9641–9647. Sources: A2 correction 7, survey F10. §13.7 has
  the same gap (R103).
- **Proposed:** Two bullets: "`show(::Events)` prints each component's event
  names with their policies." Then "`show(::Build)` and `show(::Deployment)`
  print a summary and their parts. `show(::Build)`'s parts include the events,
  and a line of the feedthrough edges between the outputs table and the events
  table. The edges are derived from the structure's connections and the
  producers' stage-2 names."
- **Recommendation:** accept

### R23. Who probes, F11 (§9.3)

- **Where:** B 9, "The nominal activation probes every user function".
- **Problem:** The nominal *evaluation* probes, and the activation is its
  product. This is the only place in the chapter where the two names swap.
- **Evidence:** A1 39 and 154; v4 "precedes the nominal evaluation's probes".
  Sources: B correction 1, survey F11, chapter_pass 1.5, B verify.
- **Proposed:** "**The nominal evaluation probes every user function once, at
  the initial state, with real values** ([D-050][d-050])." The `activation`
  link then has no first use in §9.3 and goes.
- **Recommendation:** accept

### R24. Who binds `Δt_base`, F12 (§9.3)

- **Where:** B 85, "`Δt` in seconds does not exist until `Simulation` binds
  `Δt_base`".
- **Problem:** The `Deployment` constructor binds `Δt_base`. The editorial
  rewrite of this paragraph (chapter_pass 6.5) kept "`Simulation`".
- **Evidence:** A2 88–96; D-254 Position bullet 1. Sources: B correction 2,
  survey F12, B verify.
- **Proposed:** "… until the `Deployment` constructor binds `Δt_base`, since
  deployment post-dates the build."
- **Recommendation:** accept

### R25. The hand-down's tiers (§9.3)

- **Where:** B 24, "`y_x` and `y_s` on the discrete tier".
- **Problem:** It can read as both names belonging to the discrete tier.
- **Evidence:** Spec 685–691 and 734: `y_x` is the continuous spelling, `y_s`
  the discrete. Source: B correction 3.
- **Proposed:** "The stage-1 hand-down, `y_x` on the continuous tier and `y_s`
  on the discrete, …".
- **Recommendation:** accept

### R26. Two antecedents resolved in §9.5

- **Where:** C 62–63 ("The economics' one baked type test"); C 69 ("the
  payload's diff").
- **Problem:** C resolved two ambiguous antecedents and asks for confirmation.
  chapter_pass 5.5 also found "the economics" unintroduced. The editorial pass
  fixed C 62 ("the check's economics") but not C 63.
- **Evidence:** D-235 Rationale (log 8540–8541): "This is D-053's one baked
  type test resolved by dispatch". Sources: C note 2, chapter_pass 5.5.
- **Proposed:** Confirm both readings. At C 63, write "The check's one baked
  type test".
- **Recommendation:** accept

### R27. The payload sentence cites D-053, whose Position lists `t` (§9.5)

- **Where:** C 189–191.
- **Problem:** The bold cites D-053 and D-249. D-053's Position lists
  "path + stage + field diff + `t`". D-249 says a runtime `ConformanceFailure`
  carries no simulation time. C's rulings table says D-053 is not cited, which
  no longer matches the text.
- **Evidence:** C verify citation 2 ("cite D-249 alone, or note the
  conflict"). C rulings: D-249 does not list path, function and diff.
- **Proposed:** Keep both citations until D-053 is annotated (R91). D-249
  alone would leave the list uncited.
- **Recommendation:** discuss

### R28. "one promise, and it is diagnostic only" (§9.7)

- **Where:** E 181.
- **Problem:** "It" can be the promise or the seam.
- **Evidence:** Appendix B (spec 11083) calls the seam "an inspection-only
  surface". Sources: E OQ2, E verify.
- **Proposed:** "The seam is diagnostic only ([§13.5][s13-5]), and it makes
  one promise."
- **Recommendation:** accept

### R29. The frozen anchors table and ladder are stale, F17 (§9.7)

- **Where:** E 117–150.
- **Problem:** The 9 s `Dual` anchor did not reproduce. Lazy activation saves
  2–3 s, "not tens". A reduced optimizer level "buys nothing measurable".
  "Re-measurement … is pending" is half stale.
- **Evidence:** `docs/reports/20260930_compile_cost/report.md` §4 (line 216)
  and §7 (313–319); `pending.md` 17–24; D-162 Rationale (log 5453). Sources:
  E correction 2, survey F17. For the same ruling, chapter_pass 1.12
  ("Measured anchors" clashes with the glossary's timing *anchor*) and 5.5
  (SROA, TTFX unexpanded).
- **Proposed:** Defer to the compile-time ruling. Carry 1.12 and the acronyms
  into it.
- **Recommendation:** discuss

## 3. Edits to §9.4's v4 text

### R30. "is read once" was dropped — blocks landing

- **Where:** v4 15, "A discrete producer's declaration pins."
- **Problem:** Old §9.1 3567 said "a discrete producer's is read once and
  pinned". M1 maps it to v4, and nothing in chapter 9 now says "read once".
- **Evidence:** A1 verify A1-117 (DRIFT); A1 rulings, inbound section.
- **Proposed:** "A discrete producer's declaration is read once and pins."
- **Recommendation:** accept

### R31. "the flat `x` buffer" was dropped — blocks landing

- **Where:** v4 19–20, "The table and state buffers are laid out again."
- **Problem:** Old §9.1 3568 said "The flat `x` buffer and the table are laid
  out." "State buffers" could take in store buffers.
- **Evidence:** A1 verify A1-121 (DRIFT). inbound_check: D-195 Rationale (log
  6859) relies on old §9.1's flat buffer.
- **Proposed:** "The table and the flat `x` buffer are laid out again."
- **Recommendation:** accept

### R32. A stale pointer after M8 — blocks landing

- **Where:** v4 25, "([§9.1][s9-1]/[§9.3][s9-3])".
- **Problem:** After M8, §9.1 holds only a pointer to §9.3. Nothing else in
  the spec uses a slash-joined citation.
- **Evidence:** chapter_pass 2.4.
- **Proposed:** "([§9.3][s9-3])".
- **Recommendation:** accept

### R33. §8.2 on the state-type bullet

- **Where:** v4 19.
- **Problem:** Old §9.1's state-type item cited §8.2. v4's bullet does not.
- **Evidence:** A1 verify ("v4's state-type bullet carries no §8.2"); A1
  old.md 173.
- **Proposed:** Add "([§8.2][s8-2])" after "the leaf walk".
- **Recommendation:** accept

### R34. A store-types clause in §9.4

- **Where:** v4, the first bullet list (v4 12–28).
- **Problem:** Old §9.1's "the `s_init`- and `m_init`-derived store types pin"
  has no v4 line. It is mapped to §8.2.
- **Evidence:** Spec 2479–2481: "`m_init` and `s_init` pin wholesale,
  mirroring the discrete-producer rule". A1 verify: "acceptable … The clause in
  §9.4 is optional."
- **Proposed:** Leave v4 as it is.
- **Recommendation:** reject

### R35. Three stacked bold one-liners

- **Where:** v4 107, 110, 112.
- **Problem:** Three one-sentence paragraphs in a row, each wholly bold, read
  as a run of headlines.
- **Evidence:** chapter_pass 3.5.
- **Proposed:** Join 107 and 110 to the cache paragraph (v4 100–105) as
  sentences inside it. Let 112 open the ownership list.
- **Recommendation:** accept

## 4. Moves to confirm

### R36. M4 half applied — blocks landing

- **Where:** A2 41–47.
- **Problem:** The brief asks for the lock clause and the immutability
  argument to become one pointer to §9.4. A2 kept the argument ("true by
  construction once buffers are single-owner … nothing writable is shared")
  and added the pointer. §9.4 says the same at v4 112–121. F6 is ruled.
- **Evidence:** chapter_pass 2.1 [high]. A2 kept the words because D-135's
  Rationale (log 4115–4116) quotes "true by construction once buffers are
  single-owner" (A2 inbound table, OQ6). Spec 5548 relies on "each
  `Simulation` owns its own buffers".
- **Proposed:** Keep the immutability sentence (as R16 settles it), the F6
  sentence and the §9.4 pointer. Drop the "true by construction … nothing
  writable is shared" sentences. The D-135 quote then stays as log history,
  and spec 5548 gains a §9.4 citation (R61).
- **Recommendation:** discuss

### R37. Rendering moved after The `Deployment` — blocks landing

- **Where:** A2 190–216.
- **Problem:** The brief's label order put Rendering before The `Deployment`,
  so `show(::Schedule)` and the chart came before the `Schedule`. The
  editorial pass moved Rendering after The `Deployment` and before Grid
  diagnostics. The brief does not list this move.
- **Evidence:** chapter_pass 5.1 and 6.1 [high]; A2 OQ2;
  `chapter_fixes_A2.py`.
- **Proposed:** Confirm the move.
- **Recommendation:** accept

### R38. §9.3's `ws`/`t` paragraph moved before the two checks — blocks landing

- **Where:** B 33–38.
- **Problem:** The editorial pass moved the paragraph so that all argument
  sourcing precedes the checks. The brief does not list this move.
- **Evidence:** chapter_pass 5.2 and 4.4; `chapter_fixes_B.py`.
- **Proposed:** Confirm the move.
- **Recommendation:** accept

### R39. §9.1's root-inputs paragraph moved after the type clauses — blocks landing

- **Where:** A1, after the walk-compatibility paragraph (A1 93–100).
- **Problem:** The editorial pass moved the paragraph out from between the
  store form and the type clauses. The brief does not list this move.
- **Evidence:** chapter_pass 5.10; `chapter_fixes_A1.py`.
- **Proposed:** Confirm the move.
- **Recommendation:** accept

### R40. M13 is narrower than the brief's ranges — blocks landing

- **Where:** D 7–21; `units/D/companion_addition.md`.
- **Problem:** Only the comparisons moved. "Only the assignment's *output* is
  framework vocabulary" (old 4154), the service loop's parts and the
  failed-trim sentence stay in §9.6. The companion repeats the failed-trim
  sentence for context.
- **Evidence:** D OQ2. D verify: "defensible … the user should confirm it."
- **Proposed:** Confirm.
- **Recommendation:** accept

### R41. M12 merged rather than deleted — blocks landing

- **Where:** D 9–14.
- **Problem:** The duplicate trim default added "through the `T`-generic
  assignment math", which the first statement lacked. D merged the two so
  nothing is lost.
- **Evidence:** D OQ4; D verify ("loses nothing").
- **Proposed:** Confirm.
- **Recommendation:** accept

### R42. §9.6's bullet order and the service-loop bullet — blocks landing

- **Where:** D 9–27.
- **Problem:** The bullets now run trim, service loop, linearization, so the
  pointers run §14.7, §14.8, §14.10. The brief asks for bullets that are "each
  an activation", but the service-loop bullet names none, because the old text
  names none for it.
- **Evidence:** D OQ3, OQ5.
- **Proposed:** Confirm both.
- **Recommendation:** accept

### R43. The `atmosphere::Model` respelling leaves the spec

- **Where:** `companion_addition.md` bullet 2.
- **Problem:** After M13 the spec no longer states that the initializer's
  `atmosphere::Model` argument becomes a field handle. Only D-139's Rationale
  and the companion state it.
- **Evidence:** D rulings (Rationale-only); D verify ("Companion vs. spec");
  D-139 Rationale (log 4400).
- **Proposed:** Accept the move. If the spec should still state it, place it
  in §14.7 or §14.9 with an entry that states it in a Position.
- **Recommendation:** discuss

### R44. "Final divisors wait for `Δt_base`" is said three times

- **Where:** A1 132–134; A2 82–84; A2 187–188.
- **Problem:** Survey overlap 3. No move covered it. The survey judged the A2
  82–84 statement the best.
- **Evidence:** chapter_pass 2.2.
- **Proposed:** Keep A1's first sentence and replace the "Final divisors …
  genuinely cannot exist" sentence with "[§9.2][s9-2] states why final
  divisors wait for that binding."
- **Recommendation:** accept

### R45. The `Deployment` constructor's inputs, stated twice in §9.2

- **Where:** A2 25 and A2 90.
- **Problem:** "takes a `Build` and the grid parameters" and "consumes the
  `Build` and the grid parameters" say the same thing (survey overlap 7).
- **Evidence:** A2 OQ5; A2 verify ("Other"); chapter_pass 2.3.
- **Proposed:** At A2 25, write "The `Deployment` constructor (below) is the
  first step".
- **Recommendation:** accept

### R46. Pairing by name after the per-function predicates

- **Where:** C 39–69.
- **Problem:** Survey part C suggests moving "Pairing by name" after the
  per-function predicates. The brief lists no move for C, so the old order
  stands.
- **Evidence:** C OQ5.
- **Proposed:** Keep the old order.
- **Recommendation:** discuss

## 5. Unintroduced names and Flight.jl machinery

### R47. `get_x_ss`/`assign_x_ss!` (§9.6)

- **Where:** D 23–24.
- **Problem:** Flight.jl names in normative text, outside M13's ranges.
- **Evidence:** Survey F18; D rulings F18; chapter_pass 5.6. §7.1 (spec 1583)
  says "the hand-written per-aircraft state-space mapping layer".
- **Proposed:** "replace FlightCore's hand-written per-aircraft state-space
  mapping layer (`get_x_ss`/`assign_x_ss!`)" (chapter_pass), or §7.1's wording
  with no names (D).
- **Recommendation:** accept

### R48. The migration suite's idiom and the FlightCore comparison (§9.7)

- **Where:** E 198–200.
- **Problem:** "the migration suite's `@ballocated f_ode!`/`f_step!`/
  `f_periodic!` idiom" uses FlightCore names as if known. Both sentences are
  history, not rules.
- **Evidence:** E OQ3 (`companions/migration_outline.md` line 39 already says
  it); E verify; chapter_pass 5.6.
- **Proposed:** Move both sentences to `migration_outline.md`, under the same
  reasoning as M13. The fallback is chapter_pass's wording: "the successor of
  FlightCore's … idiom, as used in the migration suite."
- **Recommendation:** accept

### R49. "Three habits of shipped code" (§9.3)

- **Where:** B 114.
- **Problem:** The shipped code is Flight.jl's `landinggear.jl` (D-142
  Rationale), which the text never names.
- **Evidence:** B verify, class 1.
- **Proposed:** "Three habits of shipped landing-gear code", with no Flight.jl
  name, in line with F18.
- **Recommendation:** discuss

### R50. `fcs` and `gnss` (§9.2)

- **Where:** A2 172–181.
- **Problem:** M7 removed the prose that introduced them. The editorial pass
  reworded the opener but added no gloss.
- **Evidence:** A2 verify ("Category 2"); chapter_pass 5.6 and 5.7.
- **Proposed:** "a flight-control scope `fcs` and a GNSS receiver `gnss`",
  checked against §10.5's code block (spec 5056–5063).
- **Recommendation:** accept

### R51. "the assignment" (§9.6)

- **Where:** D 12 and 16.
- **Problem:** M13 moved out the sentence that introduced the assignment.
- **Evidence:** chapter_pass 5.5 and 6.6. §14.7 (spec 9801): "the pure
  `trim_condition(ac, params, d)` fragment-tree function".
- **Proposed:** "… seeded through the `T`-generic assignment (the user's
  function from decision variables to a [condition](#g-condition),
  [§14.7][s14-7]) …".
- **Recommendation:** accept

### R52. §9.3's aerospace examples

- **Where:** B 117 (strut on a touchdown overload), 121 (contact algebra
  cancelling a velocity component), 127 (`else error("unrecognized surface
  type")`), 128 (a coefficient constructor asserting an ordering).
- **Problem:** Each needs one introducing clause.
- **Evidence:** B verify, class 2; chapter_pass 5.6.
- **Proposed:** "A landing-gear strut model that throws on a touchdown
  overload"; "a ground-surface kind"; "friction coefficients, static ≥
  dynamic".
- **Recommendation:** accept

### R53. The `P = M*ω` / `M_shaft` example (§9.5)

- **Where:** C 48–49 and the message at C 76–77.
- **Problem:** The example names are opaque.
- **Evidence:** C verify, category 2.
- **Proposed:** Introduce them as "a shaft's power and torque".
- **Recommendation:** accept

### R54. v4's aerospace examples

- **Where:** v4 59 ("interactive fly-around use") and v4 126 ("the
  envelope-grid gain-schedule case").
- **Problem:** Each needs one introducing clause.
- **Evidence:** chapter_pass 5.6.
- **Proposed:** "interactive use, such as flying the model by hand,";
  "computing a gain schedule over a grid of flight conditions, where hundreds
  of …".
- **Recommendation:** accept

### R55. `t*` (§9.7)

- **Where:** E 74–76.
- **Problem:** `t*` is never introduced in the chapter.
- **Evidence:** §10.4 (spec 4500) defines it as the localized event time.
  Sources: chapter_pass 5.5, E verify.
- **Proposed:** "**At a localized event time `t*` ([§10.4][s10-4]), the empty
  due set is arity selection, not an index trick**". The bold follows the
  ruled trim.
- **Recommendation:** accept

### R56. `rhs`, `ticks` and "the three tick-sensitive blocks" (§9.7)

- **Where:** E 57, 71, 73, 168.
- **Problem:** The phase-body list names "the `s_update` block". The arity
  text and the seam list call bodies `rhs` and `ticks`. The reader cannot tell
  that they are the same blocks.
- **Evidence:** chapter_pass 1.9 and 5.5. Appendix B 11076–11079 lists the
  four bodies as `rhs`, `sweep_1`, `sweep_2`, `ticks`.
- **Proposed:** After confirming the mapping, name the bodies where the
  blocks are listed: "the `x_deriv` block (`rhs`, …)" and "the `s_update`
  block (`ticks`)".
- **Recommendation:** accept

### R57. CSE, SROA, TTFX (§9.7)

- **Where:** E 102 (CSE); E 120 and 150 (SROA, TTFX, inside the frozen block).
- **Problem:** The acronyms are never spelled out.
- **Evidence:** chapter_pass 5.5; E verify.
- **Proposed:** "Common-subexpression elimination (CSE) merges …". Carry SROA
  and TTFX into the compile-cost ruling (R29).
- **Recommendation:** accept

### R58. "the staleness rule" (§9.7)

- **Where:** E 103.
- **Problem:** The spec uses the name only here. §7.1 (spec 1544) calls it the
  "buffer-unchanged-within-a-sweep rule".
- **Evidence:** E verify.
- **Proposed:** Use §7.1's name, with a [§7.1][s7-1] pointer.
- **Recommendation:** accept

### R59. "the gate is pure modulo arithmetic" (§9.2)

- **Where:** A2 212–213.
- **Problem:** The gate comes before §9.7 introduces gating.
- **Evidence:** chapter_pass 5.5.
- **Proposed:** "the gate (`(tick − Φ) % D == 0`, [§9.7][s9-7]) is pure
  modulo arithmetic".
- **Recommendation:** accept

### R60. Three smaller names: "the classifier", "the probing scalar", the branch-shape rule

- **Where:** A1 79 ("the classifier"); A1 172 and B 35 ("the probing
  scalar"); B 74 and 103 ("the branch-shape rule"); B 55 (`RQuat`).
- **Problem:** "The classifier" can be confused with §9.4's cycle classifier.
  "The probing scalar" is never named. The branch-shape rule (spec 2651, §8.3)
  appears with no pointer. `RQuat` has no gloss.
- **Evidence:** chapter_pass 5.5 and 5.6; B verify ("Other cold terms").
- **Proposed:** "before the class reading (step 2) and the vocabulary checks
  read the value", if that is the meaning. "the probing scalar (`Float64` at
  build)", if that holds. Add [§8.3][s8-3] at the first branch-shape rule.
  Optionally gloss `RQuat` as "the rotation-quaternion type".
- **Recommendation:** discuss

## 6. Edits outside the chapter

### R61. `spec.md`: retargets the rewrite causes — blocks landing

- **Problem:** The moves leave inbound citations pointing at the old section.
- **Evidence:** inbound_check (§9.1 → §9.2, 28 rows; §9.1 → §9.4, 2 rows); A2
  inbound table; A2 verify on 5548.
- **Rows:**
  - §9.1 → §9.2: 3196, 3233, 3272, 4798, 5046, 5054, 6343, 6372, 7793, 8304,
    10827, 10828, 10833, 11379, 11868, 11898.
  - Cite §9.2 alone (drop §9.1): 8424, 10821, 11457, 12069.
  - §9.1 → §9.4, or cite both: 2303, 12095.
  - Add §9.4: 5548 ("each `Simulation` owns its own buffers").
  - VAGUE: 8242, "§9.1 already fixed when each check runs" → "§9.1–§9.2".
  - Mechanical, with no ruling needed: the Contents entry at spec 50 changes by
    hand for the retitle. `linkify.jl` regenerates the `#92-…` slug and the
    `[d-151]` and `[d-111]` definitions (C OQ7). Restore the missing blank
    lines before `### 9.4`, `### 9.5` and `### 9.6` (survey F15; C note 1).
- **Proposed:** Apply all of these.
- **Recommendation:** accept

### R62. `companions/flight_case_studies.md`: section 4 — blocks landing

- **Problem:** M13's content must land with the chapter.
- **Evidence:** `units/D/companion_addition.md`; D OQ7.
- **Proposed:** Append the section. After "Section 3 reads …", add "Section 4
  reads today's C172 trim against the stopped-sim services." Let `linkify.jl`
  supply the link definitions (`s9-6`, `s14`, `s14-1`, `s14-7`, `s14-8`,
  `s14-9`, `s4-4`, `d-139`).
- **Recommendation:** accept

### R63. `implementation.md` — blocks landing (rows 118 and 495)

- **Rows:** 118 (`src/diagnostics.jl` Spec list names §9.1 only; add §9.2);
  495 ("one throw per call", §9.1 → §9.2); 511 (`src/deployment.jl`, VAGUE:
  §9.1 keeps only the steps-table row, and §9.2 is already listed); 832
  ("(§9.4, D-166)": D-166 is superseded, so §9.4 now cites draft D-280).
- **Evidence:** inbound_check; survey part E, "Superseded citations".
- **Proposed:** Retarget 118 and 495. Drop §9.1 at 511. Replace D-166 with
  D-280 at 832 once D-280 lands.
- **Recommendation:** accept

### R64. `pending.md` 90 — blocks landing

- **Problem:** It cites §9.1 for a build warning, which now sits in §9.2's
  Warnings.
- **Evidence:** inbound_check; A2 inbound table.
- **Proposed:** §9.1 → §9.2.
- **Recommendation:** accept

### R65. `spec.md`: citations wrong before the rewrite

- **Rows:**
  - 10379 (§14.10): `activations` cites §9.7. The keyword is §9.4's (survey
    F23).
  - 11781 (glossary, buffer): cites §9.2. The fact is §9.4's (A2 OQ, A2
    verify).
  - 11832 (glossary, execution order): cites §9.1. The fact is §9.7's.
  - 9866 (§14.7): cites §9.6 for "nonlinear least squares … LM family". §9.6
    never stated it. §14.8 names the LM default (D rulings).
  - 11496 (Appendix C, `ArgumentInvalid`): cites §9.2 for collection "over
    the materialization's keywords". No chapter states that (A2 OQ8).
- **Evidence:** inbound_check, "RETARGET already mis-targeted" and
  "PREEXISTING".
- **Proposed:** Retarget the first four. For 11496, drop the §9.2 citation or
  decide where materialization-keyword collection is stated.
- **Recommendation:** accept

### R66. `linearization_walkthrough.md` 595

- **Problem:** It cites §9.7 for `build(m; activations = …)`. The keyword is
  §9.4's. This predates the rewrite.
- **Evidence:** inbound_check.
- **Proposed:** §9.7 → §9.4.
- **Recommendation:** accept

### R67. `trim_environment_walkthrough.md` 6, 502, 576

- **Problem:** The three rows cite §9.6 for the trim respelling, the
  per-residual scalings and the `Initializer` claim. All three moved to the
  companion.
- **Evidence:** inbound_check, COMPANION; D rulings.
- **Proposed:** Retarget to `flight_case_studies.md` section 4. For 502, §14.7
  also works. The alternative is to leave them as history.
- **Recommendation:** discuss

### R68. `sample_time_proposal.md`

- **Rows:** 304, 335, 769 (§9.1 → §9.2); 412 (§9.3; superseded by D-205);
  772 (§9.2; superseded by D-254).
- **Problem:** This is an adopted proposal. A2 says to retarget "only if the
  adopted proposal is kept current".
- **Evidence:** inbound_check; A2 inbound table.
- **Proposed:** Leave it as written, unless adopted proposals are kept
  current.
- **Recommendation:** discuss

### R69. `decisions.md` log text that cites chapter 9

- **Rows:** 8294 and 8332 (D-229, deployment validation, §9.1 → §9.2); 6859
  (D-195 Rationale, the flat buffer); 4400 (D-139 Rationale, now in the
  companion); 10895 (D-272 Position, cites §9.7 for the `activations`
  keyword, which predates the rewrite); 5163 (D-152 Rationale, auto-published
  cells, which no chapter states; C OQ8); 9414 (D-253, see R92).
- **Problem:** Log text keeps its day unless rule 2's exception extends to
  moved content (R71).
- **Evidence:** inbound_check; A2 inbound table; D rulings.
- **Proposed:** Edit none, except 8294 and 8332 if R71 is accepted.
- **Recommendation:** discuss

## 7. Log track 2

### R70. D-280 to D-282 must land with v4 — blocks landing

- **Problem:** v4 cites D-280 (the CI `Dual` policy), D-281 (torn-state
  freedom) and D-282 (buffer ownership). They are drafted but not in the log.
- **Evidence:** §9.4 trial report, "Before adopting it"; survey E15;
  inbound_check ("drafts with no entry in `decisions.md` yet").
- **Proposed:** Land them with the chapter. D-282 may also absorb D-135's
  immutability ruling (R75).
- **Recommendation:** accept

### R71. Does rule 2's citation exception cover moved content?

- **Problem:** `decisions_style.md` rule 2's exception covers renumbering
  ("every entry … cites the CURRENT § numbering"). A content move is not a
  renumbering. Every Spec-field edit below, and the R69 log rows, wait on this.
- **Evidence:** Survey part D; A2 inbound section; D inbound section.
- **Proposed:** Extend the exception to content moves.
- **Recommendation:** accept

Rulings that need an entry stating them in a Position, by entry:

### R72. D-186 Rationale: `Δt_base` binding and the fold

- **Rulings:** the fold into `(anchor, m, c)` triples (A1, plain); the timing
  tables are anchor-relative (A2 69, bold); three sources, cross-validated (A2
  99, bold); unanchored means declare (A2 118, bold); admissibility is exact
  GCD arithmetic (A2 126, plain); `Dₖ`, `Φₖ` exact or `DeploymentInvalid` (A2
  138, plain); derivation only when all components are anchored.
- **Evidence:** log 6523–6540; survey E1 and E3; A1 and A2 Rationale-only
  tables.
- **Proposed:** A new entry, or an amendment to D-186, that states these in
  its Position.
- **Recommendation:** accept

### R73. No entry: `Δt_base = :derive` is explicit, never the default

- **Where:** A2 108–115.
- **Evidence:** Survey E2; A2 table. Appendix B 10828 states it too.
- **Proposed:** A new entry.
- **Recommendation:** accept

### R74. D-187 Rationale and Rejected: grid-diagnostic details

- **Rulings:** every `r_p > 1` is listed (A2 228, bold); blame is computed
  against the actual pool (A2 239, bold).
- **Evidence:** log 6571, 6585–6592; survey E6.
- **Proposed:** State them in D-187's Position or a successor's.
- **Recommendation:** accept

### R75. D-135 Rationale: the `Build` is immutable and backs many deployments concurrently

- **Where:** A2 41–42 (plain, cited).
- **Evidence:** log 4114–4117; survey E4 ("Draft D-282 (buffer ownership)
  may absorb it").
- **Proposed:** Fold it into D-282's Position.
- **Recommendation:** accept

### R76. D-119 Rationale: "the artifact deployed is the very build CI checked"

- **Where:** A2 35–39 (plain).
- **Evidence:** log 3486–3489; survey E5 ("Borderline: it may be read as the
  factorization's reason, not a rule").
- **Proposed:** No entry. Read it as the reason for the factorization.
- **Recommendation:** reject

### R77. D-142 Rationale: totality's two dispositions

- **Rulings:** a plausibility check becomes a `Bool` face plus `stop_on`; a
  self-consistency assert belongs in the test suite (B 116–124, plain).
- **Evidence:** log 4618–4626; survey E7; B rulings.
- **Proposed:** State them in a Position.
- **Recommendation:** accept

### R78. §9.3 rulings with no current entry

- **Rulings:** a non-`NamedTuple` stage return fails at the probe (B 40–41;
  survey E8). The hand-down's sourcing (B 24) was D-169's, which is superseded
  by D-252 and not restated. `DeadStage` "fail-fast" (B 43) was D-165's,
  which is superseded by D-194 and not restated, though D-194 is cited. The
  `Δt = 1.0` placeholder (B 86): D-115 calls it "settled", but no settling
  entry was found. Topological probing (B 29): D-048 is borderline.
- **Evidence:** B rulings ("Citations", OQ2–OQ4); B verify.
- **Proposed:** One entry that restates the probe's return-shape and
  dead-stage rules, the hand-down sourcing and the placeholder.
- **Recommendation:** discuss

### R79. D-238, D-263 and D-079: the pinned leaf's exact check

- **Rulings:** a pinned leaf takes the exact check at every activation (C 101,
  plain, cites D-238 and D-263); the misplaced-pin error and its hint "remove
  its `Pinned`" (C 105–107). The hint has no current entry. Superseded D-166
  had "declare it `T`".
- **Evidence:** C Rationale table; C OQ2; survey E9.
- **Proposed:** A new entry.
- **Recommendation:** accept

### R80. D-263, D-079 and D-266: the stop-gradient doctrine

- **Rulings:** the pinned leaf is the schema-visible freeze (C 128–129, bold);
  stripping at an unpinned leaf remains legal (C 131–133, plain).
- **Evidence:** log 10112–10115, 10371–10373, 2267–2268; survey E10.
- **Proposed:** A new entry.
- **Recommendation:** accept

### R81. D-090 Rationale: handler returns

- **Rulings:** the key set is checked first, and an unknown key gets a
  did-you-mean (C 158, bold); `x` is complete against the state field set (C
  164, bold).
- **Evidence:** log 2569–2572; C Rationale table. Survey part E has no item
  for this.
- **Proposed:** State them in D-090's Position or a successor's.
- **Recommendation:** accept

### R82. No entry: struct-valued ports; the absent source branch

- **Rulings:** struct-valued ports use the standard cross-eltype constructor,
  and a missing one fails loudly (C 86–88). The payload omits the source
  branch (C 198, bold; D-053 Rejected only).
- **Evidence:** survey E11; C OQ3 asks whether the constructor is what
  "rebuilds the declaration from" the leaves (D-238 Rationale, log
  8706–8709).
- **Proposed:** A new entry. Answer C OQ3 when drafting it.
- **Recommendation:** accept

### R83. D-086 Rationale: the executor's structure

- **Rulings:** phase bodies are forced (E 47, bold); two options recorded, not
  committed (E 87, plain); views rebuild-per-call (E 99, bold); type-opaque
  construction (E 107, bold); chunking and the ladder (frozen; wait on the
  compile-time ruling).
- **Evidence:** log 2456–2474; survey E12; E Rationale table.
- **Proposed:** A new entry for the first four now. Chunking and the ladder
  wait on the compile-time ruling.
- **Recommendation:** accept

### R84. D-185 Rationale: `t*` arity selection and one gate, F16

- **Rulings:** `t*`'s empty due set is arity selection (E 74–76, bold, cites
  D-147 and D-185); one gate serves all three tick-sensitive blocks (E 73,
  plain).
- **Evidence:** log 6467–6468; D-147 Position (log 4917–4920) says only that
  the due set is empty. Sources: E correction 1, survey F16 and E13.
- **Proposed:** A new entry. No text change.
- **Recommendation:** accept

### R85. D-116 Rationale: publication is not a phase body

- **Rulings:** publication is not a phase body (E 202, bold); isolated
  invocation leaves buffers off-trajectory.
- **Evidence:** log 3388; survey E14.
- **Proposed:** State it in D-116's Position or a successor's.
- **Recommendation:** accept

### R86. Minor Rationale-only wordings

- **Rulings:** "fixes the structure and the `Float64` typing at once" (A1
  188, plain; D-259 Rationale, log 9749; the ruling itself is D-253's amended
  Position). The kind name `WalkingFaceAtFrozenEntry` (A1, uncited; D-167
  superseded and D-264 Rationale, log 5752 and 10248). D-139's respelling (see
  R43).
- **Evidence:** A1 Rationale table; D rulings.
- **Proposed:** No entries. The first rests on D-253. Name the kind in the
  entry that settles §8.2's wire clauses when §8.2 is rewritten.
- **Recommendation:** discuss

Stale Positions and entry text:

### R87. D-048 Position, and D-119 Rationale: "deployment binding at `Simulation` construction"

- **Problem:** D-254 moved binding to the `Deployment` constructor. Neither
  entry is annotated.
- **Evidence:** survey part E; A1 Rationale section; A1 verify.
- **Proposed:** Annotate both as amended by D-254.
- **Recommendation:** accept

### R88. D-187 Position: "the bound schedule on the `Simulation`"

- **Evidence:** D-254 Rejected lists it as superseded. D-187 is "ratified"
  with no annotation (survey part E; A2 citations note).
- **Proposed:** Annotate it as amended by D-254.
- **Recommendation:** accept

### R89. D-253 bullet 5: "under the existing lock" (open after the F6 ruling)

- **Evidence:** log 9409–9410 against D-135 Rationale log 4117–4121
  ("mechanism unspecified") and D-281. Sources: A2 correction 3, survey part
  E.
- **Proposed:** Annotate it to defer to D-135 and D-281.
- **Recommendation:** accept

### R90. D-077 Position: discrete `workspace(::C)` takes no scalar

- **Evidence:** D-263 bullet 4 gives both tiers the scalar. D-077 has no
  annotation (survey part E). v4's bullet follows D-263.
- **Proposed:** Annotate it as amended by D-263.
- **Recommendation:** accept

### R91. D-053 Position: `t` in the failure payload

- **Evidence:** log 1484, "path + stage + field diff + `t`", against D-249
  bullet 2. Sources: C OQ9, C verify.
- **Proposed:** Annotate it as amended by D-249. This settles R27.
- **Recommendation:** accept

### R92. D-253's last bullet (log 9414)

- **Evidence:** "§9.1 says Stratum B is the nominal evaluation's structural
  half, and the nominal activation is B's products plus C's typing". D-259
  amended bullet 4 in place, but this bullet still says what D-259 and §9.1
  deny. Sources: survey part E; inbound_check, PREEXISTING.
- **Proposed:** Annotate it as superseded by D-259.
- **Recommendation:** accept

### R93. D-235 Position names D-166's embed-accept

- **Evidence:** log 8513–8514. D-166 is superseded by D-263 (C OQ4).
- **Proposed:** Annotate it to point at D-263.
- **Recommendation:** accept

Spec fields (all wait on R71):

### R94. Spec-field changes the rewrite causes

- **Rows:** D-139 drops §9.6. D-113, D-133, D-227 and D-234 change §9.1 to
  §9.2. D-229 adds §9.2, and keeps §9.1 only for the barrier sentence. D-254,
  D-250 and D-187 drop §9.1. D-186 keeps both. D-263 keeps §9.1 and already
  lists §9.4.
- **Evidence:** inbound_check, "Caused by the rewrite"; survey part D; A2
  inbound section.
- **Proposed:** Apply.
- **Recommendation:** accept

### R95. Spec fields for entries the rewrite newly cites

- **Rows:** D-185 adds §9.1. D-052 adds §9.4 (also in the trial report). D-078
  (§9.1), D-060 (§9.3), D-099 (§9.4) and D-157 (§9.5) have Spec fields
  without these sections. D-048, D-050 and D-070 have no Spec field.
- **Evidence:** inbound_check, "Newly cited" and "Outside the brief"; survey
  part E.
- **Proposed:** Add the sections, and give the three entries without one a
  Spec field.
- **Recommendation:** accept

### R96. Spec fields stale before the rewrite

- **Rows:** D-261 adds §9.1. D-253 adds §9.7. D-033, D-106 and D-256 drop
  §9.7 (D-256 is borderline). D-163 lists §9.7 for a float-comparison rule
  §9.7 does not state. D-152 and D-168 list §9.5 for content it lacks. D-066
  is borderline. D-166 (superseded) lists §9.4 and §9.5. D-079 lists neither
  §9.4 nor §9.5.
- **Evidence:** inbound_check, "Already stale"; survey parts D and E; E OQ6.
- **Proposed:** Apply. Leave the borderline D-066 and D-256 as they are.
- **Recommendation:** accept

## 8. Problems outside the chapter

### R97. §8.7: "fixed at `Simulation` construction" (survey F20)

- **Where:** spec 3195–3196.
- **Evidence:** D-254 moved deployment decisions to the `Deployment`
  constructor.
- **Proposed:** "fixed at deployment ([§9.2][s9-2])". This joins R61's 3196
  retarget.
- **Recommendation:** accept

### R98. §10.4: localization keywords are `Simulation` keywords (survey F21)

- **Where:** spec 4797.
- **Evidence:** D-256 bullet 5 makes them `Deployment` constructor keywords.
  §9.2 validates them there (A2 154–156).
- **Proposed:** "are `Deployment` constructor keywords".
- **Recommendation:** accept

### R99. Appendix B: derivation by omission (survey F22)

- **Where:** spec 10835–10837, "The third, in a fully anchored model omitting
  both, is derivation".
- **Evidence:** §9.2 and Appendix B's own table (10828) require an explicit
  `:derive`. Sources: A2 OQ7; inbound_check note on 10838.
- **Proposed:** "The third, requested with `Δt_base = :derive` in a fully
  anchored model, is derivation …".
- **Recommendation:** accept

### R100. §13.1: retired strata vocabulary (survey F24)

- **Where:** spec 8278 (the survey's 8287–8288 has shifted): "the stage-1
  probes in B and the probe chain in C".
- **Evidence:** D-259 retired the strata.
- **Proposed:** "the stage-1 probes and the probe chain of the nominal
  evaluation".
- **Recommendation:** accept

### R101. `extensions.md` 191: "Stratum A flattens … absolute divisors" (survey F25)

- **Evidence:** Retired vocabulary and pre-anchor content. A1 correction 4 is
  the same staleness.
- **Proposed:** Align it with R13's wording.
- **Recommendation:** accept

### R102. `tools/spec_style.md`, "The battery" (survey F26)

- **Evidence:** It says `decisions.md` keeps plain citations. `decisions.md`
  is first in `linkify.jl`'s `ROSTER` (line 63) and carries reference links.
- **Proposed:** Correct the sentence.
- **Recommendation:** accept

### R103. §13.7 gaps

- **Where:** spec 8980–9000.
- **Problem:** No `show(::Events)`, and no feedthrough line in
  `show(::Build)`. §13.7 also says "records the routing chain at every level"
  where D-257's amendment and §9.2 say "each face's".
- **Evidence:** A2 correction 7; survey F10; A2 verify A2-115.
- **Proposed:** Mirror R22 in §13.7, and write "each face's routing chain".
- **Recommendation:** accept

## Dropped as resolved

A later fix in the current `new.md` resolved these:

- A1: the antecedent of "computes its products" (now "does its work"); "They
  require wrapper-typed values"; the unbolding of the fold, root inputs and
  "fixes the structure" (A1 verify); "Error-*reporting*".
- A2: the derivation line moved to Grid diagnostics, and `GridUtilization`
  with D-250 placed under Warnings (A2 verify); "carries everything the grid
  parameters fix" made plain; "two sugar forms, then three forms"
  (chapter_pass 5.8); the Rendering order (now R37, to confirm).
- B: B-013 ("That hand-down is …"), B-049 ("that D-051 rejects"), B-038
  (§8.2 scope), "The allocator runs that early", the plausibility and
  self-consistency bullets made plain (B verify); the clock paragraph's
  repetition (chapter_pass 6.5, apart from F12); the parallel habit bullets
  (5.9).
- C: C-010, C-088/089, C-057 made plain, C-095 citing D-090, the C-004 bold
  moved to C-007 (C verify); the activation gloss moved back to "non-nominal
  activation" (C OQ10, chapter_pass 5.4); `Expected`; the predicate bullets
  reordered to match the subsections (5.11); the two leaf kinds named (5.3);
  "fold" (1.10).
- E: "The decomposition has these parts" became "The blocks are as follows"
  (E verify); `chunks` linked (5.13).
