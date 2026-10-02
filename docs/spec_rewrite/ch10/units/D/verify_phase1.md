# Unit D — phase 1 (blind) assertion list

Source: units/D/new.md only.

## Intro
- V1. §5.3 leaves open how far the event phase runs at a boundary and how often each event may fire. [§5.3]
- V2. A boundary is a published consistency point where the macro-sequence completes. [#g-boundary gloss]
- V3. This section answers both questions.

## Rule
- V4. (bold) The event phase iterates. [D-020]
- V5. One round re-runs the boundary sweep, evaluates all guards against it, fires eligible events. [D-020]
- V6. The boundary sweep is the pass over the full execution order with due discrete entries gated in. [gloss]
- V7. Guards are the declared functions defining each event's predicate. [gloss]
- V8. (bold) A component fires at most one event per round. [D-154]
- V9. Each firing is handler → x_projection. [D-154 by adjacency]
- V10. Rounds continue to quiescence, the fixed point where a round fires nothing.
- V11. (bold) An event fires in a round iff three conditions hold. [D-181]
- V12. Condition 1: predicate observed holding in that round.
- V13. Condition 2: sample observed before it was not-holding.
- V14. Condition 3: event's firing count for this boundary < firing_budget.
- V15. That is the whole definition of "newly fired".
- V16. The predicate is §2.1's: Bool true or σ ≥ 0. [§2.1]
- V17. firing_budget is a deployment keyword, integer ≥ 1, default 4.
- V18. It caps how many times each declared event may fire at one boundary.

## Why iterate
- V19. Under a single pass, a cascade of N simultaneous transitions takes N steps, latency N·h.
- V20. Model semantics would then depend on step size; h is an execution parameter.
- V21. Same class of footgun §2.2 cited when killing f_step! (an unconditional per-step hook). [§2.2, D-020]
- V22. Externalized FSM components are blessed, making cross-component cascades the expected idiom. [§3.1]
- V23. Hybrid automata take sequences of instantaneous transitions at one time point.
- V24. Modelica iterates events to quiescence.
- V25. Stateflow runs charts to completion within a tick. Tick gloss: instant at which a discrete component's stages and update run.
- V26. Boundary-detection timing remains h-dependent, a different quantity (crossing-notice resolution).
- V27. Cascade delay would have been framework-inserted structure between model-simultaneous transitions.

## Registers
- V28. Three registers per event decide the rule, all named normatively.
- V29. Prior = previous boundary's quiescent sample; first round tests against it.
- V30. Last-observed sample initialized from prior at boundary open, overwritten by every round's evaluation; later rounds test against it.
- V31. Exception: eligible-but-blocked event keeps its sample, because blocking defers its edge rather than consuming it.
- V32. Firing count incremented at each firing, reset when the boundary ends.
- V33. Eligibility inside a boundary is an edge, not-holding → holding, never a bare sign change.
- V34. The edge is read against the last-observed sample, not the prior entered with. [D-181]
- V35. Sticky predicates need no special case; fire once at the boundary where first held.
- V36. A predicate genuinely falsified and re-enabled inside the boundary by another handler's cascade fires again at this boundary against a fresh sweep. [D-181]
- V37. Sketch: entering: last ← prior, count ← 0; loop while previous round fired (first always runs); sweep with due set fixed for boundary; eligible test; per component first eligible in declaration order; last ← now unless eligible and not firing; fire handler → x_projection, count += 1; exit at quiescence; prior ← last.
- V38. (bold) Prior updated at each boundary's quiescence from final post-iteration samples. [D-082]
- V39. Update is unconditional; every prior is an honest observation of a settled boundary.
- V40. That makes the θ = 0 discriminator conclusive. [§10.4]
- V41. The frame-top drain is the only possible source of disagreement between prior and left-end trial evaluation. Drain gloss: swap publishing staged device writes into root inputs.
- V42. All three registers are detection bookkeeping, not model memory; correctly absent from every state store. [D-082]
- V43. A checkpoint (executor's state at a frame top, as one value) carries the prior, the one register crossing a boundary. [§12.6, D-274]
- V44. The trace header is such a checkpoint.
- V45. restore! copies a checkpoint's prior back. [D-274]
- V46. The other two registers reset on entering each boundary.
- V47. Beyond the prior, cost is one Bool and one small counter per event.
- V48. Boundary zero is the initialization boundary.
- V49. (bold) Boundary zero sets every prior to not-holding. [D-082]
- V50. A predicate holding in authored state therefore fires at t₀; behavior derived, not asserted. [§14.5]
- V51. A re-run from a condition resets all three registers because init! re-runs boundary zero. [§14.5]
- V52. Predicates holding in newly applied state fire again at new t₀.
- V53. restore! keeps checkpoint priors and runs no boundary zero; nothing holding re-fires. [§12.6, D-274]

## Handler view
- V54. Each round re-runs the whole boundary sweep, gated entries included. [D-020]
- V55. Reason: a transition reaches the signal table only through a sweep. Signal table gloss.
- V56. A handler writes its component's state stores and nothing else.
- V57. So neither the component's own ports nor downstream stage-2 chains have moved. Port gloss.
- V58. Cost negligible: sweeps take microseconds; rounds beyond the first require an actual cascade.
- V59. Within a round, the table's single writer is the sweep. [D-154]
- V60. Handler returns transitions; framework latches into state stores; x_projection normalizes. Nothing moves the table mid-round.
- V61. The epoch rule is the core of this section.
- V62. (bold) A handler executes against exactly the world its guard fired on. [D-154]
- V63. Its own y, foreign u, own x/m all come from the firing round's sweep; y = h(x) holds at every handler entry.
- V64. No bundle (NamedTuple of zero-copy views) straddles two epochs.
- V65. An epoch here is the world one round's sweep produces; not §10.4's input epoch. [§10.4]
- V66. Serialization delivers this: state stores written only by own handlers, at most one event per round, so no same-round writer precedes handler entry.
- V67. (bold) A component's other eligible events are blocked, not lost. [D-191]
- V68. Each re-decided next round against post-transition sweep. [D-154]
- V69. Declaration order is priority with re-decision, not simultaneity.
- V70. An event whose premise the earlier transition falsified does not fire; under within-round sequencing it would fire on stale premise.
- V71. Blocking visible in registers [D-191]: blocked event's last-observed not overwritten, edge unconsumed.
- V72. A guard that keeps holding fires next round on the same edge; one falsified records not-holding; later re-rise is a fresh edge.
- V73. Prior stays honest at no cost: quiescent round blocks nothing, every sample takes final update before prior is written.
- V74. Across components, handler order within a round is semantically unobservable. [D-154]
- V75. Reason stronger than serialization: no delivering mechanism; nothing writes the table mid-round.
- V76. Execution order still fixed: executor component order, then declaration order within component. Executor gloss.
- V77. Keeps execution cursor (loop-state field, §13.4) and diagnostics stream deterministic; no trajectory depends on it. [§13.4]
- V78. The natural single-pass executor is exactly correct: builds bundles at dispatch from live table; no pre-materialization, staging pass, carrier, shadow table; allocates nothing.
- V79. (bold) A handler cannot opt into seeing a same-round foreign transition. [D-100]
- V80. Same-instant sequential coupling across components is a cascade, one round per link, deterministic.
- V81. Tighter coupling belongs inside one component; declaration order gives exact sequencing across rounds.
- V82. Synchronous languages' position: micro-step sees pre-state, effects appear next micro-step.
- V83. Serializing same-component firings costs one extra intra-boundary sweep per serialized event, microseconds on the rare boundary that fires.
- V84. D-154 records the rejected shapes. [D-154]

## Firing budget
- V85. A per-event firing budget lets a re-enabled event fire at its true boundary against a fresh sweep. Gloss.
- V86. The deferral design and the per-round cap are both rejected. [D-020, D-181]
- V87. Priors stay honest as a consequence; every prior is a sample actually taken.
- V88. Termination budget-bounded rather than structural; at most firing_budget·E firings per boundary, bounded rounds, deterministic, pace-independent.
- V89. A livelock (two FSMs toggling) does not resolve silently; each toggler spends its budget and warns; run proceeds and replays identically.
- V90. This is degradation, not an error, per §10.4's doctrine. [§10.4]
- V91. The warning names the actual chatterer; other events' iteration continues untouched.
- V92. The arbitrary-K objection [D-020] lives on in firing_budget; D-181 records what that buys.
- V93. (bold) Budget exhaustion degrades; it does not throw. [D-181]
- V94. After firing_budget firings at a boundary, further edges there are lost for the rest of the boundary; eligibility test skips it, others iterate normally.
- V95. A lost edge emits a FiringBudget warning, at most once per event per boundary. [§13.2, Appendix C]
- V96. An event that fires its budget out then quiesces lost nothing and warns nothing.
- V97. Warning carries component path, event name, boundary time, exhausted budget beside the boundary's firing count.
- V98. Default 4 chosen as §10.4 chooses per-frame localization budget's 8. [§10.4]
- V99. Legitimate re-enable is one or two firings deep; toggling pair chatters without bound; 4 separates them without binding on a healthy model.
- V100. Like every degradation here it depends on trajectory alone; run replays identically.
- V101. §10.4's doctrine governs both budgets. [§10.4]
- V102. Neither boundary iteration nor re-localization within the frame has a structural bound; each takes a budget.
- V103. firing_budget per event per boundary; localization_budget per frame.
- V104. Both degrade loudly rather than erroring, under a warning naming the offending event.
- V105. They differ only in what exhaustion sheds: localization sheds root-finding precision, preserves every firing at boundary granularity; firing budget sheds firings, which is what bounds the iteration.

## Ticks
- V106. (bold) Ticks stay outside the iteration, after quiescence. [D-020]
- V107. The two couplings resolve asymmetrically.
- V108. Events→ticks: due discrete output stages (y_state/y_direct) gated into the boundary sweep against a due set fixed for the whole iteration [§10.5]; every round refreshes them against same s and post-transition inputs.
- V109. Their s_update has not run yet.
- V110. At quiescence their outputs reflect the settled boundary instant, what "sampling at t" should mean.
- V111. Earlier rounds' tentative values are internal scratch, like RK stage evaluations; §10.3 states when external readers may observe the table. [§10.3]
- V112. Ticks→events structurally impossible: output stages run inside the sweep from current s; s_update writes s⁺ after the sweep; s⁺ first decoded at owner's next tick; invisible within the boundary.
- V113. Standard one-sample z⁻¹ delay, enforced by construction.
- V114. Nothing after quiescence can flip a guard; no combined event/tick fixed point.
- V115. Macro-sequence: integrate → project → [sweep → guards → handlers] iterated to quiescence (under the firing budget) → all due s_update → logging / I/O staging.
- V116. Boundary zero is the same sequence with an empty integrate. [§14.5, D-067]
- V117. The sequence decides the mixed case (continuous component handler and discrete observers' ticks on one boundary). Continuous component gloss.
- V118. Example: engine starting → running under a 50 Hz FCS; engine continuous component, FCS discrete observer; transition fires in iteration segment; re-sweep re-runs FCS stages against running-mode ports; s_update runs from post-transition values.
