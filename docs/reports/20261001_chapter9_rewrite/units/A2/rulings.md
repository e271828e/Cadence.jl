# A2 rulings: §9.2 "The `Build` and `Deployment` artifacts"

Line numbers are `new.md` lines unless marked `log` (`decisions.md`) or
`spec` (`spec.md`).

## Corrections proposed

1. **F4, a stale relative date.** Line 130: "the `N_base·h` product when only
   `N_base` is given, today's rule, with the default `N_base = 1`". "Today"
   is the time before D-186 added derivation. The clause dates the text and
   says nothing the default does not. Proposed: "the `N_base·h` product when
   only `N_base` is given, with the default `N_base = 1`;".

2. **F5, the wrong step count.** Line 21: "The first three are the products of
   §9.1's three steps." D-259 Position bullet 1 (log 9717–9721): the structure
   step outputs `Structure`; the nominal evaluation outputs `Dataflow` (now
   `Outputs`), `Events` and the nominal activation. Structure, outputs and
   events come from the first two steps. Proposed: "The first three are the
   products of the structure step and the nominal evaluation
   ([§9.1][s9-1])."

3. **F6, "under the lock".** Lines 42–44: "the lazily populated activation
   dictionary, under the lock that makes insertion torn-state-free". §9.4
   (v4) says "The mechanism is unspecified. A guard around insertion
   suffices", after D-135 Rationale log 4117–4121 ("mechanism unspecified").
   The text keeps the old claim. Proposed: "The one mutable thing on the
   artifact is the lazily populated activation dictionary, whose insertion
   is torn-state-free." D-253 bullet 5 (log 9409–9410, "under the existing
   lock") also conflicts with D-135, which is a matter for the log.

4. **F7, "immutable" beside a mutable dictionary.** Line 40: "The `Build` is
   immutable and may back any number of deployments and `Simulation`s,
   concurrently". Two sentences later: "The one mutable thing on the artifact
   is the lazily populated activation dictionary". Evidence: D-135 Position
   limits immutability to the cached "immutable compiled artifacts", and v4
   says "An entry is immutable once constructed". Proposed: "The `Build` is
   immutable apart from its lazily filled activation dictionary, and may back
   any number of deployments and `Simulation`s, concurrently
   ([D-135][d-135])."

5. **F8, "against it".** Lines 14–17: "`attach!` validates device bindings
   against it." The wording is the old text's. After M5, "it" most naturally
   reads as the `Build`, which is what D-049 Rejected ("acceptance tests and
   `attach!` want the contract artifact") and D-253 Rationale ("bindings
   validate against it") intend. Proposed: "against the `Build`".

6. **F9, the `Schedule`'s rows.** Old 3723–3726 ran the component rows and
   the rate-scope rows together after a colon, with no conjunction. The
   colon had to go. The new text (lines 188–191) states two row kinds, which
   is the literal reading of the comma list and what D-254 bullet 2 and D-261
   bullet 4 ("its component rows and its rate-scope rows") say. No further
   change proposed. The verifier should check this reading.

7. **F10, `show(::Events)` and the feedthrough line.** Lines 96–102 list
   `show` for `Structure`, `Outputs`, `Schedule`, `Build` and `Deployment`.
   D-257's amendments (log 9641–9647) add `Events`, which "renders itself
   too, each component's event names with their policies", and a
   feedthrough-edges line in `show(::Build)`. Proposed, as two bullets:
   - "`show(::Events)` prints each component's event names with their
     policies."
   - "`show(::Build)` and `show(::Deployment)` print a summary and their
     parts. `show(::Build)`'s parts include the events, and a line of the
     feedthrough edges between the outputs table and the events table. The
     edges are derived from the structure's connections and the producers'
     stage-2 names."

   §13.7 (spec 8984–8989) has the same gap.

8. **An unstated "throws once".** Spec 8304 (§13.1), D-229's Position (log
   8294) and `implementation.md` 495 rely on deployment validation throwing
   once. Neither the old text nor the new one says "throws once". It says
   "collected" and "reported as `DeploymentInvalid`". Proposed, after the
   violation list (line 181): "Every check whose premise holds runs, and the constructor throws
   once."

## Citations added or replaced

| where | entry | words that rule it |
|---|---|---|
| line 14, `build(world) → Build` is a standalone entry point | D-049 Position | "Standalone `build(world) → Build` artifact — inspectable wire list/face table/schedule/root slots" |
| line 17, the rejection sentence | D-049 (dropped there) | covered by the bold in the same paragraph; Rejected: "*Build inside the `Simulation` ctor only*" |
| line 24, deploying and materializing are two steps | D-254 Position | "Deployment binding produces an artifact, and the `Simulation` materializes it." Bullet 4: "`Simulation(build; kw...)` and `Simulation(root; kw...)` stay as sugar composing the deployment constructor." The citation moved here from the `Simulation(world; kw...)` sentence, which is now a display block. |
| line 40, the `Build` is immutable (plain, not bold, since inbound citations rely on its words) | D-135 Rationale | "the `Build` is an **immutable artifact that may back any number of `Simulation`s, concurrently**" (Rationale only; see below) |
| line 56, the face table is two-sided | D-207 Position, bullet 2 | "The face graph is therefore total … and the `Build` retains it, input side beside the output side". Moved from the reason sentence, which keeps §6.1. |
| line 65, the timing tables are anchor-relative | D-186 Rationale | "the `Build` gaining the anchor and component tables with rate chain, final divisors for anchored entries deferred to binding" (Rationale only) |
| line 86, an artifact holds declared facts | D-261 Position, bullet 2 | "An artifact holds declared facts. Its consumer compiles what it needs from them once, at one home". Moved from the following sentence. |
| line 108, the chart guard is binary | D-257 Position, bullet 2 | "The chart guard is binary". Moved from the sentence after it. |
| line 114, a `Deployment` is scalar-free (bold covers only this) | D-254 Position, bullet 1 | "It is scalar-free." |
| line 125, three sources | D-186 Rationale | "`Δt_base` binds from exactly one of three cross-validated sources" (Rationale only) |
| line 144, unanchored means declare | D-186 Rationale | "derive `Δt_base` only when every discrete component is anchored … otherwise deployment must declare it, the refusal constructive" (Rationale only) |
| line 169, deployment validation is collected | D-229 Position, last bullet | "Outside the strata the unit is the call. Deployment validation (§9.1) runs every check whose premise holds and throws once." |
| line 225, every `r_p > 1` is listed | D-187 Rationale and Rejected | "with every `r_p > 1` listed (joint responsibility is the honest answer)"; Rejected: "*Crowning the single largest refinement factor*" (Rationale only) |
| line 236, blame against the actual pool | D-187 Rejected | "so blame is computed against what is actually declared". Moved from the sentence after it. (Rejected only) |

These were dropped:
- Five self-citations became internal: three to §9.2 in the moved §9.1 text,
  and two to §9.1 in the old §9.2.
- §9.4 ×2 (the lock clause and the mutable-dictionary sentence) became one
  §9.4 pointer (M4). The two claims themselves stay in §9.2.
- D-254's "`D`, `Φ`, `Δt` vectors" clause is superseded by D-261. Nothing here
  cites it.
- D-187's Position puts the bound schedule "on the `Simulation`". D-254
  rejects that placement as superseded, but D-187 carries no annotation. Both
  D-187 citations rest on its Rationale and Rejected, not on that clause.

## Rationale-only rulings

| ruling | entry | field | log line |
|---|---|---|---|
| the `Build` is immutable and may back many deployments and `Simulation`s concurrently (plain, cited) | D-135 | Rationale | 4114–4117 |
| `Structure`'s timing tables are anchor-relative; divisors deferred to binding (bold) | D-186 | Rationale | 6526–6529 |
| `Δt_base` has exactly one of three cross-validated sources (bold) | D-186 | Rationale | 6534–6537 |
| unanchored component present means deployment must declare `Δt_base` (bold) | D-186 | Rationale | 6531–6534 |
| every `r_p > 1` is listed (bold) | D-187 | Rationale, Rejected | 6571, 6592 |
| blame is computed against the actual pool (bold) | D-187 | Rejected | 6585–6588 |
| admissibility is exact GCD arithmetic over the constraint pool (plain) | D-186 | Rationale | 6529–6531 |
| `Dₖ`, `Φₖ` exact or `DeploymentInvalid` naming the anchor (plain) | D-186 | Rationale | 6537–6540 |
| the artifact deployed is the very build CI checked (plain) | D-119 | Rationale | 3486–3489 |
| derivation requested explicitly as `Δt_base = :derive`, never by default (plain) | none | — | no entry (survey E item 2) |

The five bold ones and the immutability sentence need entries that state them in a Position (survey E items
1, 4, 6).

## Inbound citations affected

The retitle changes the slug `#92-the-build-artifact`. `linkify.jl`
regenerates the definitions, and the Contents entry (spec 50) changes by hand.

Facts that inbound citations rely on, and where they now sit in §9.2:

| citing line | fact relied on | now in §9.2 | cites today |
|---|---|---|---|
| spec 3196 (§8.7) | `Δt_base`'s three sources | The `Deployment`, line 125 | §9.1, retarget |
| spec 4798 (§10.4) | event parameters beside `h`, `N_base`, the algorithm | The `Deployment`, lines 116–120 and the violation list | §9.1, retarget |
| spec 5046 (§10.5) | the deployment-time constraint pool | The `Deployment`, the pool table | §9.1, retarget |
| spec 5054 (§10.5) | a deployment binds `Δt_base` | The `Deployment`, lines 125–151 | §9.1, retarget |
| spec 6343, 6372 (§12.1) | where the `Deployment` comes from; its constructor | The `Deployment`, lines 114–121; The `Build`, lines 24–26 | §9.1, retarget |
| spec 7793 (§12.6) | grid and event parameters are the deployment's | The `Deployment`, lines 116–121 | §9.1, retarget |
| spec 8304 (§13.1) | deployment validation throws once | Not found in old or new §9.2. Line 169 says "collected"; "throws once" is unstated (correction 8) | §9.1, retarget |
| spec 10827, 10828, 10833 (App. B) | `N_base`, `Δt_base`, the three sources | The `Deployment`, lines 125–138 | §9.1, retarget |
| spec 11379 (App. C) | `DeploymentInvalid` | The `Deployment`, lines 170–181 | §9.1, retarget |
| spec 11457 (App. C) | `GridUtilization` | Warnings, lines 261–262 (the derivation line itself is under Grid diagnostics, lines 240–246) | §9.1, §9.2 → §9.2 alone |
| spec 11868, 11898 (App. D) | anchors join the pool; the harmonic grid | The `Deployment`, pool table and violation list | §9.1, retarget |
| log 8294 (D-229 Position), 8332 (D-229 Rejected) | deployment validation collected | The `Deployment`, line 169 | §9.1; log text keeps its day unless the user extends rule 2's exception |
| `implementation.md` 495 | the constructor has one throw per call | as spec 8304 | §9.1, retarget |
| `sample_time_proposal.md` 304, 335 | deployment binding, `DeploymentInvalid` | The `Deployment` | §9.1, only if the adopted proposal is kept current |
| spec 3233, 3272 (§8.8) | `EmptyFaceSelection` reaches the `Build`'s list through the channel | Warnings, lines 255–259 | §9.1, retarget (M3) |
| spec 8424 (§13.2) | build warnings live on the artifacts; `warnings(x)` | Warnings | §9.1, §9.2 → §9.2 alone |
| `pending.md` 90 | a build warning | Warnings | §9.1, retarget |
| spec 5548 (§11.1) | one immutable `Build` shared across workers; each `Simulation` owns its own buffers | The `Build`, line 40 for the first half. Line 42 for the second half ("Each `Simulation` materializes its own buffers from the shared layouts"). The ownership rule itself is §9.4's (v4, "Every buffer set has exactly one owner"). | §9.2; needs a §9.4 citation for "each `Simulation` owns its own buffers" |
| spec 11781 (glossary, buffer) | a service invocation's store set, instantiated from the layout | Not found in old or new §9.2. It sits in §9.4 (v4) and §14.8. | §9.2, §14.8; consider §9.4 for §9.2 |
| spec 9322 (§14.x) | the chain a sub-assembly's face routes through is in the `Build` | The `Build`, line 56 (face table); Rendering, lines 97–99 (routes, pointer to §13.7) | unchanged |
| spec 8984, 4950, 5039, 5049, 5068, 11997, 12587 | `show` per artifact; the `Schedule`; attribution as the engine's job; one hyperperiod is the complete truth; the schedule as the single source of truth for `Δt`; the artifact rule | Rendering; The `Deployment`; Grid diagnostics | unchanged |
| log 4115–4116 (D-135 Rationale) | quotes §9.2's "true by construction once buffers are single-owner" | The `Build`, lines 41–42, kept verbatim for this reason | unchanged |
| log 9847 (D-260 Rejected) | "an invariant with no enforcer (§9.2)" | Rendering, lines 88–90 | unchanged |
| log 3365 (D-115 Rejected) | the standalone build | The `Build`, line 14 | unchanged |

Moved inside §9.2, with no inbound citation affected:
- M5, the standalone-`build` justification. It now opens The `Build`.
- M6, route printing. One sentence and a §13.7 pointer stay, with "each
  face's routing chain at every level". The hop format and the fan-out line
  map to spec 8991–9000.
- M7, the example's declarations. The `fcs` and `gnss` clause stays, because
  the binding table uses both names. The `inner`/`outer` clause maps to
  §10.5's code block (spec 5056–5063).
- M4. The pointer keeps the per-`Simulation` materialization with its "so
  nothing writable is shared", the one mutable dictionary, and "under the
  lock" (F6, correction 3). It points to §9.4 for the ownership rule, the
  keying and the torn-state-free insertion. The dictionary's keying maps to
  v4.

Log Spec fields this unit would change: D-113, D-133, D-227 and D-234 lose
§9.1 and gain §9.2. D-187 and D-254 drop §9.1. D-229 and D-186 keep §9.1 and
already list §9.2 or need it (D-229). D-250 drops §9.1 under M3. Rule 2's
exception covers renumbering, not moves (survey D).

## Open questions

1. **Warnings vs. grid diagnostics.** Settled by the coordinator. The
   derivation-line paragraph closes Grid diagnostics. The `GridUtilization`
   deployment-warning sentence sits under Warnings with D-250.
2. **Rendering before The `Deployment`.** The survey's label order puts
   `show(::Schedule)` and the chart guard before the section defines the
   `Schedule`. The context paragraph glosses `Schedule` to cover that. The
   other choice is Rendering after The `Deployment`, with the D-261 rule
   beside the `Schedule` paragraph, where its "never stored beside them"
   application sits.
3. **Glossary links.** The merge leaves one section where there were two.
   The second `#g-deployment` link and two `#g-schedule` links are dropped,
   so each term is linked once. `Deployment` and `Schedule` are now linked,
   with their glosses, in the context paragraph, where each is first used.
   The `#g-rate-scope` link and its gloss moved to the `show(::Structure)`
   bullet, its first use.
4. **Display code.** The three `Simulation` forms are a display block with
   comments. `build(world) → Build` stays inline, because `→ Build` is not
   Julia. `Δt_base = :derive` is a display block. The worked example's
   `Δt_base = 2 ms` is a value, not code to type, and stays inline.
5. **Two bold sentences for D-254 bullet 1 and D-254's main sentence.**
   "Deploying and materializing are two steps" (The `Build`) and "A
   `Deployment` is scalar-free" (The `Deployment`) both rest on D-254. They are distinct rulings, the
   factorization and the artifact's content. The overlap "takes a `Build` and
   the grid parameters" / "consumes the `Build` and the grid parameters"
   (survey overlap 7) is kept, since no move covers it.
6. **The M4 pointer keeps "by construction".** The convention warns that "by
   construction" turns a rule into a consequence. Here the immutability is
   the cited rule and single ownership its cause, so the phrase stays. D-135's
   Rationale quotes it.
7. **Appendix B 10835–10837 (survey F22)** contradicts §9.2's explicit
   `:derive` request. It lies outside this unit. It is noted here because
   Appendix B cites §9.2 for it (spec 10838).
8. **Spec 11496** cites §9.2 for collection "over the materialization's
   keywords". §9.2 has never said that, old or new.
