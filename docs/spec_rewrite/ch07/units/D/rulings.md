# Unit D (§7.4, §7.5): rulings

Log line numbers are `docs/design/decisions.md` lines in the working tree on
2026-10-02. Old spec lines are at the base commit `8032ff2`.
`make_inventory.py` writes `inventory.json`.

## Corrections proposed

None beyond the ruled edits applied.

- **F7 (R8), applied.** Old spec 1833, "Against a split-form spelling of the
  same model". New: "of a rigid-body kinematics and dynamics core", cited to
  D-015, with no file name.
- **F9 (R8), applied.** Old spec 1813, "(today's `y_state`)" becomes "(now
  `y_state`)", inside the parenthesis. "That decoder" keeps its antecedent.
- **F10 (R8), applied.** Old spec 1808. New: "Once contract visibility
  (§8.3, D-034) made a port's publicity a declaration".
- **F12, left as written.** Old spec 1847–1851, `x_projection` "at both of
  its §5.3 positions" among the unconditional items. The bullet's wording is
  unchanged.
- **F14, left as written.** Old spec 1879–1880, the scheduled `GC.gc(false)`
  at frame boundaries. `pending.md` already holds it.
- F11, F13 and F15 are outside this unit.

No new factual problem found.

## Citations added or replaced

All are additions. None replaces an old citation.

- **§5.3**, in §7.4's new context sentence (R3, brief's unit D line). §5.3
  (spec 1022–1037): "Derivative/output overlap is the *norm* in physical and
  control models"; "Shared expensive computations are thereby solved
  uniformly".
- **D-034**, at "Once contract visibility (§8.3, D-034) made a port's
  publicity a declaration" (R8, F10). Position (log 1067): "Contract
  visibility: declared = public". D-035 Rejected (log 1110–1111): the
  camouflage "fell with contract visibility".
- **D-015**, at "the cache-free formulation that fits this design's purity
  rules". Position (log 563–566): "Fused evaluation: `f`/`h` read the fresh
  table (own `y` included) ... single computation site for derivatives and
  outputs is the *rewarded* idiom". The cache's verdict is Rejected only
  (below).
- **D-015**, at "The computer/integrator split remains fully expressible
  without any framework support". Position (log 565–566): "the *rewarded*
  idiom, not an impossibility claim".
- **D-015**, at the split-form measurement (R8, F7). Rejected only (below).
- **D-014**, at "The allocation policy is not dogma". Position (log 551):
  "Scoped allocation invariant". "Not dogma" is Rejected only (below).
- **D-014**, at the bold "The budget is exactly zero, CI-enforced". Position
  (log 551): "Scoped allocation invariant, CI-enforced on the hot path".
- **D-116** and **§9.7**, at the same sentence. D-116 Position (log
  3479–3487): "The zero-allocation invariant's measurement seam:
  `phase_bodies(sim)` returns the compiled bodies ... CI is warm-then-assert
  at per-body granularity". The old `[§9.7][s9-7]` moved to the sentence's
  citation parenthesis.
- **D-116**, at "The rare exception has a documented tolerance". Position
  (log 3486–3487): "a documented tolerance loosens exactly one assertion".
- **D-137**, at "The log retains the published snapshot objects themselves,
  by reference". Position (log 4332–4333): "`log_max` — the maximum number of
  retained snapshot references".
- **D-135** and **§14.8** (R5), at "The zero-allocation invariant is scoped
  to the stepping loop, and the stopped-sim services were always
  allocation-tolerant". D-135 Rationale (log 4229–4230): "§7.5's
  zero-allocation invariant being scoped to the stepping loop (the services
  were always allocation-tolerant, §14.8)". Spec 4406 (§9.4): "covers only
  the stepping loop, and the services were always allocation-tolerant".
- **D-288**, **§9.7** and **§11.2** (R5), at "Publication is not a phase
  body ..., and its one snapshot allocation per boundary sits with logging on
  the framework side of that scope". D-288 Position bullet 6 (log 11988):
  "Publication is not a phase body." Spec 4916 (§9.7): "Publication is not a
  phase body (D-288)". Spec 6420–6421 (§11.2): "The cost is one snapshot
  allocation per boundary, on the framework side of the §7.5 scope, which
  already carved out logging."
- **§11.2** at the remedy sentence moved from after "The honest remedy" to
  the sentence's end beside D-252, when the semicolon split the sentence.
  Not an addition.

`[d-014]` has no link definition in `spec.md` yet (D-014 was cited nowhere).
Linkify adds it at landing.

## Rationale-only rulings

- **D-014, Rejected (log 556–557).** "*Blanket dogma:* fights logging
  reality"; "*No policy:* loses the type-instability canary". Carries "not
  dogma" and the canary. Cited at "not dogma".
- **D-015, Rejected (log 573–574).** "*Mutable caches between `f` and
  outputs:* S-function/FMI style — hidden state, purity violation". Carries
  the cache-free formulation's fit with the purity rules.
- **D-015, Rejected (log 578–579).** "2× components/wiring for the
  domain-normal overlap case". Carries the split-form measurement.
- **D-116, Rationale (log 3491–3493).** Guards and projection join the
  exactly-zero tier; handlers join the tick tier's zero-by-idiom. The bullets'
  tier membership rests on it. Not cited at the bullets beyond the Position
  citations above.
- **D-135, Rationale (log 4229–4230).** The invariant's scope (R5 sentence 1).
  Track 2 owes it a Position, as survey part G q5 says.

## Bold on the same entry elsewhere

One bold: "The budget is exactly zero, CI-enforced", citing D-014. No bold
in chapters 8 to 10 cites D-014 (grep of `spec.md`: D-014 appears nowhere).
No other unit's `new.md` cites D-014. D-116 and D-288 are bold
at §9.7; this unit cites both plain.

## Inbound citations affected

- §7.4's step numbers survive (spec 10578 and D-125 cite step 2, D-169 step
  4). Step 2 keeps "a one-line function body"; step 4 keeps the identity
  decode as transport.
- §5.3 1035 sends the reader to §7.4 for the split "including when the
  factoring earns its keep": kept as "the idiom of choice when the factoring
  earns reuse".
- "the canary" (spec 4484, D-151) and "a documented tolerance" (spec 4914)
  stay word for word.
- "§7.5's remedy" (D-243 Rationale 9086, 9097; `test/fixtures.jl` 1413,
  1444): the remedy stays, now in M9's paragraph.
- The scope family (spec 4406, 10220, 10778; D-066, D-135) now finds the
  stepping-loop scope and the services' tolerance in §7.5.
- "the §7.5 carve-out" (spec 4917, D-116 Rationale, D-288 Rationale) and
  "the framework side of the §7.5 scope" (spec 6420): §7.5 now places
  publication on the framework side of the scope with logging. It does not
  use the word "carve-out". The rows read it in substance.
- Spec 12548 (glossary *scratch*) still cites §7.5 for the integrator's
  buffers and the mid-step table, which §7.5 does not mention. Unchanged,
  track 2 as the survey says.
- Old spec 1859 and 1871 held two `[log](#g-log)` links. One stays, moved to its
  new first use in §7.5's context paragraph.

## Open questions

- §7.4's context sentence says every step addresses the shared computation
  between derivatives and outputs, as the brief orders. Step 1 (N output
  groups to exactly two) is about feedthrough structure (D-006), so the
  verifier may read "every step" as a stretch. It is the brief's wording.
- I kept the `f_ode!` gloss "(its in-place derivative function)" from the
  survey's part F list. R2 only says the name stays in §7.4; drop the gloss if
  the orchestrator wants none here.

## Edits after verification

- **D-044 drift.** "The seam's granularity scopes the tolerance per body, so
  the tolerance never loosens the continuous assertions."
- **R14.** §7.4's context sentence is now "Overlap between derivatives and
  outputs is the norm in physical and control models (§5.3)", §5.3's words
  (spec 1024). "Every step below addresses that problem" is gone. It is a
  declared addition, so it carries no tag in the inventory.
- **R15.** R5's second sentence now ends "sits with logging on the framework
  side, outside what the invariant claims is zero (§11.2)". Spec 4917: "What
  the accessor exposes is exactly what the invariant claims is zero"; spec
  6420: "on the framework side of the §7.5 scope, which already carved out
  logging". A declared addition, untagged for the same reason.
- **R16.** "Modelica/MTK (ModelingToolkit) write `der(x) = expr` natively,
  with symbolic common-subexpression elimination" (claim D-022, tagged R16).
  CSE appears nowhere else in the unit.
