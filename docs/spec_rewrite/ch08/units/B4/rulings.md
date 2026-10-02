# Unit B4: rulings, citations and open points

Unit B4 covers old spec 2501–2526, 2541–2596 and 2612–2693: §8.2's events,
stage membership and completeness, then §8.3 and §8.4. M1 and M2 took
2597–2611 and 2527–2540 out before the rewrite.

## Corrections proposed

1. Old 2574–2575: "Every declaration takes the component alone, and
   `ws_init` takes the scalar on both tiers ([D-263][d-263])." This is the
   problem F22 found at 2216 and 2870–2871. The stages, update laws, guards,
   handlers and `x_projection` take a bundle or a state as well. The
   evidence is D-263 Position, log 10171: "Every contract declaration takes
   the component alone on both tiers". **Ruled in as R13**, which extends
   R7's F22. The sentence now reads "Every declaration of a structural fact
   takes the component alone, except `ws_init`, which takes the scalar on
   both tiers", using the words units B1 and D use. The re-check asked for
   "except" so the sentence no longer contradicts itself. The inventory
   tags it `R`, ruling `R13`.

## Citations added or replaced

- **D-179** at "Detection policy is declared by the guard's return type
  instead". Position, log 6354–6355: "Detection policy is declared by the
  guard's return type — `Bool` ⇒ boundary-detected, nominal scalar ⇒
  localized". It is cited without bold, because §10.4 (spec 4878) already
  bolds this ruling.
- **D-033** at the bold "No port carries a stage tag, and stage membership is
  derived". Position, log 1017–1018: "stage membership derived (inputless
  `h_x` probes first, remainder is stage 2), no stage tags". The log uses the
  old vocabulary there, and none of it is carried into the spec.
- **D-112, D-249** at the bold "The remaining tier-implying declarations must
  agree". D-112 Position, log 3319–3322: "`events` joins the tier markers ...
  a continuous-tier marker since the event system is continuous-side only".
  D-249 Position bullet 1, log 9274–9276: "`DeclarationOnWrongTier` keeps the
  update laws, the stores, `state_events`, `init_m`, `state_projection`".
  D-249's annotation, log 9312–9314, adds the `Pinned` entry on a discrete
  leaf.
- **D-263** at `StatelessWithoutOutputs` in §8.2. Position bullet 6, log
  10197–10199: "an empty-store leaf with no `output_types` is
  `StatelessWithoutOutputs`". The old text cited it only through adjacency.
- **D-263 and §8.2** at the new clause in §8.3's rule list (R7, F23). They
  rest on the same words.
- **D-034** at the bold "Visibility is decided by *where the value goes*".
  Position, log 1053: "declared = public; absent `output_types()` = no
  outputs; ... undeclared stage-return fields = build error".
- **D-034** at the bold branch-shape rule. Position, log 1056:
  "branch-shape-stable returns".
- **D-032 and D-034** at the unbolded "Schema authority is total over the
  table" (R9, and the verifier's fix). D-032 Position, log 980–981: "schema
  authority — declarations define, probe evaluation checks (build probe with
  real values + free always-on conformance)". D-034 Position, log 1056:
  "undeclared stage-return fields = build error". With every returned field
  declared, every cell traces to a declaration. The phrase "schema
  authority total" itself is D-055's (log 1570), which R9 keeps out.
- **D-239** at "Return typos cannot silently define new cells" (R9).
  Position, log 8828–8829: "A stage returning a field `output_types` does not
  declare is reported by the port check's `UndeclaredReturnField` alone."
- **D-239 in place of D-055** at "the return-side analogue of §8.4
  walkthrough 1" (R9, old 2647). The D-239 words are those above. D-034
  stays.
- **D-055 dropped** at "Probe-observed expected types remain rejected" (R9,
  old 2660). D-034 and D-194 stay. D-034 Rejected (log 1063–1067) and D-194
  Rejected (log 6925–6927) carry the rejection. D-239's Position does not
  carry it, so D-239 goes on the return-typo sentence instead.
- **D-055 kept** in the R4 pointer (old 2662). Only D-055 Rejected (log
  1584–1585) holds the opt-in variant with the `Float64`-under-`Dual`
  diagnostic. D-055's status is ratified and its Rejected list stands.
- **D-194** moved one sentence earlier, from "One line in `y_types` ..." to
  "The inspection path for an intermediate is declaration". That sentence is
  unbolded, because the next one makes it a consequence of the visibility
  rule.
  Position, log 6860–6862: "a cross-stage intermediate is an ordinary declared
  port".
- **§8.5** pointer added at "the same move as class-by-declaration-shape".
- **§7.4 dropped** with the R4 cut of "identity publication by default
  (§7.4 step 4)". The inventory maps the item to D-016 Rejected, log
  591–592.

R4's cut items map to these log spans: identity publication by default to
D-016 Rejected (log 591–592) and D-034 Rejected (log 1070); probe-observed
private cells to D-034 Rejected (log 1063–1067) and D-194 Rejected (log
6925–6927); the `Private(T)` fallback to D-034 Rejected (log 1071–1072) and
D-194 Rejected (log 6928–6931); the opt-in variant to D-055 Rejected (log
1584–1585). The `unlisted` flag is in D-016 Rejected (log 591–595) and D-034
Rejected (log 1068–1069). Its "satellite-function representation" appears
nowhere in the log, so the clause stays in the pointer sentence.

## Rationale-only rulings

- "Probe-observed expected types remain rejected" (§8.3). Only D-034
  Rejected (log 1063–1067) and D-194 Rejected (log 6925–6927) state it.
  Both are cited. It is a rejection, so it may need no Position.
- "Publicity is never implicit" (§8.3, old 2631). Only D-034 Rejected (log
  1070) and D-041 Rejected (log 1240) state it. It is carried uncited, as
  before (survey part E, item 14).
- The bundle letter of an empty store (§8.2, old 2590–2592). Only D-263
  Rationale (log 10242–10244) states it. It is carried with its §5.2
  pointer, as before (survey part E, item 13).

## Bold on the same entry elsewhere

- **D-033.** Unit A bolds its Rationale ruling, that contracts are functions
  of the type. Unit B1 bolds the by-value `init_*` ruling. B4 bolds stage
  membership, derived, with no stage tags. These are three different rulings
  of D-033's Position and Rationale, so none is a double.
- **D-034.** B4 bolds two of its Position's chained rulings in §8.3:
  visibility (declared = public) and the branch-shape rule. The schema
  authority sentence is unbolded (see D-032 below). No other unit bolds D-034.
- **D-032.** Unit A bolds "Declarations *define* the model's structure"
  (D-032's schema-authority ruling) in §8.1. B4 bolds "Schema authority is
  total over the table", citing D-032 beside D-034. B4's bold states the
  ruling's reach over the table, the undeclared-return clause of D-034. It
  could be read as a second bold on D-032's schema-authority ruling.
  **Ruled by the coordinator:** D-032's schema-authority ruling is one
  ruling, bold in §8.1, where it is stated first. B4's sentence is unbolded
  and keeps both citations, D-032 and D-034.
- **D-252.** B4 bolds "A declared port must be produced by exactly one
  stage" in §8.3. Spec §5.3 (old 879–880, chapter 5, not yet rewritten)
  states the same ruling under a **Rule.** label. Chapter 5's rewrite must
  not bold it a second time, or one of the two should yield.
- **D-179.** It is bolded at §10.4 (spec 4878). B4 cites it without bold.
- **D-263.** B4 bolds nothing on D-263. Units B1 and B2 bold its rulings.

## Inbound citations affected

- Appendix C's w1–w5 references (spec 11709, 11713, 11719, 11839) and the
  log's "walkthrough 1/2/5": the numbering and order of §8.4 are unchanged.
- Spec 3953 ("banned by the branch-shape rule (§8.3)"): the term stays,
  in the bold sentence.
- Spec 3496–3502 (§9.1 lists the completeness rules, citing §8.2): §8.2 now
  says "three rules". §9.1's five bullets map onto those three rules and
  the stateless-leaf paragraph, all still in §8.2.
- Spec 862 (§5.3: "A stateful leaf's declarations must agree on one tier
  throughout (§8.2)"): still true.
- Spec 3572 (ports classified over `y_types` alone, citing §8.3): still
  true.
- Spec 11807 (Appendix C cites §8.2 and §8.5 for
  `StatelessWithoutOutputs`): §8.3 now names the kind too, after F23. F27
  already records the stale §8.5 citation.

## Open questions

- Appendix C cites §8.2 for `StoreWithoutUpdate` (spec 11747) and
  `EventHalfMissing` (spec 11751). §8.2 states both rules but names neither
  kind. Naming them in "Completeness" would add a claim, so B4 leaves it to
  the owner.
- "The didactic style says exactly that" (old 2553). The referent is
  unclear. It probably means that the diagnostic's message tells the author
  that a parameter is a plain struct field. It is carried verbatim.
- The R4 pointer keeps "its satellite-function representation", which the
  log does not carry. Either the log records it, or a later pass drops it.
- "decoder" in "the 'decoder takes no inputs' property" (§8.2, stage
  membership) is left unglossed. Neither B4's old text nor the glossary says
  what it is. Spec §7.4 (line 1810) calls stage 1 "the stage-1 decoder itself
  (today's `y_state`)", and that line could source a gloss later.
- Reader-cold names, after the verifier's report. FlightCore's `Model`
  became "FlightCore's model output", and `P_shaft` is introduced as "a
  declared shaft power". "split state letters" (D-195) and "the didactic
  style" stay as written, as ruled.
