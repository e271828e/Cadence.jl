# C1 verify, phase 1 (blind read of new.md)

Intro
- V1. A model runs several clocks at once: integrator on step `h`, inner loop at one rate, outer loop at another, receiver at a third.
- V2. Each must hold its outputs steady between its own firings.
- V3. For that to be well-defined, three things must be fixed: the shared time lattice, the test deciding which components run at a boundary, the declaration surface. (pointer: this section fixes all three in order)
- V4. A boundary is a published consistency point (gloss).

Base grid and gate
- V5. **Every discrete component's period is an integer multiple of a base tick period Δt_base** [D-019].
- V6. Δt_base is an integer multiple of the continuous step: Δt_base = N_base·h, N_base ≥ 1. That is the harmonic grid.
- V7. Ticks therefore land on step boundaries.
- V8. Step boundaries are the only place anything discrete ever happens.
- V9. Frames (loop iterations) are counted by frame index k.
- V10. Frame top at t = t₀ + k·h is a base tick exactly when k is a multiple of N_base; tick index = k ÷ N_base.
- V11. A frame top that is no base tick has no tick index [§10.4, D-147].
- V12. A boundary at a localized event time t* has no tick index [§10.4, D-147].
- V13. **However declared/nested, the build compiles a rate to two integers per discrete component** [D-185].
- V14. D = period in base ticks; Φ = offset in base ticks.
- V15. Pair kept in canonical residue 0 ≤ Φ < D; ticks fall at Φ, Φ+D, Φ+2D, ...
- V16. **Component due at a boundary when (tick − Φ) % D == 0, tick = boundary's tick index** [D-185].
- V17. That subtraction and remainder are the whole admission test.
- V18. It costs one subtraction more than a phase-free test, over a lattice fixed at build time.
- V19. (pointer) declaration surface below says where (D, Φ) comes from.

ZOH and sweep variants
- V20. **A discrete component's y_state/y_direct run only at its own ticks** [D-019].
- V21. Its cells (entries in the signal table) hold in between; this is ZOH stated in sweep terms.
- V22. A sweep is one pass through the execution order (definition).
- V23. Reason for the hold: re-running a discrete component's stages at every boundary would un-sample a sampled-data controller.
- V24. **Delivering the hold takes two statically distinct sweep variants compiled from one entry list** [D-147].
- V25. Discreteness is a build-time fact, so the split is static, not a runtime test.
- V26. **Interior sweep walks continuous entries only** [D-147].
- V27. RK stage evaluations [§10.3] and localization guard trial evaluations [§10.4] run the interior variant.
- V28. ZOH therefore holds mid-step by construction.
- V29. Discrete entries are not gated at runtime; absent at compile time; hot path carries no gating test at all.
- V30. **Boundary sweep walks the full list**, discrete entries gated by (tick − Φ) % D against boundary tick index [D-147].
- V31. It is the variant the §10.6 macro-sequence runs.
- V32. It is not one fixed list either, because different boundaries run different subsets of the execution order.
- V33. **The split applies to both sweep blocks** [D-147].
- V34. Discrete tier's y_state entries absent from interior stage-1 walk, exactly as y_direct entries absent from interior stage-2 walk.
- V35. The variants surface in phase-body signatures: interior bodies take no arguments, boundary bodies take the tick index [§9.7].

Due sets
- V36. **Due set computed once per boundary, reused by every re-sweep of its quiescence iteration** [D-147].
- V37. Quiescence is the fixed point where a round of handlers fires nothing [§10.6].
- V38. Due set is a property of the boundary, not the sweep call.
- V39. Because a due component is at its tick instant for the whole boundary, not one round.
- V40. Tick frame top (every N_base-th frame top): due set = every discrete component whose gate admits the tick index.
- V41. Off-tick frame top (N_base > 1, no base tick): due set empty; tick counter has not advanced, so no component at a tick instant.
- V42. t* boundary: due set empty for same reason.
- V43. A modulo test against the unadvanced index would wrongly re-admit the previous tick's due set.
- V44. Boundary zero is the initialization boundary, runs ordinary macro-sequence with an empty integrate (gloss).
- V45. Boundary zero due set = everything with Φ = 0 [D-205].
- V46. At tick 0 gate reads (0 − Φ) % D == 0; under canonical residue holds iff Φ = 0.
- V47. Nothing implements this rule; it falls out of the ordinary gate.
- V48. Dueness at boundary zero governs the s_update calls alone.
- V49. Output stages publish due or not [D-205], as §14.5 specifies.
- V50. An offset component's first tick is at Φ·Δt_base.
- V51. Until then its cells hold its boundary-zero publication.
- V52. Its output stages run at t₀ due or not, evaluated from the authored world [D-205, §14.5].
- V53. The probe's synthesized values [§9.3] reach no published cell.
- V54. In a phase-free model every Φ is 0, so at boundary zero everything is due and the distinction is empty.

Simultaneous ticks
- V55. Several components can be due at one boundary; settled machinery already orders them.
- V56. All due components run output stages in topological order within the sweep.
- V57. All due s_update calls run after the sweep, in any order.
- V58. Each reads the table and writes only its own s store.
- V59. Intra-tick ordering of the FCS cascade (a flight control system's outer loops feeding its inner loop) is therefore a sweep property, not an update-order property.

Assemblies and rate scopes
- V60. **An assembly is virtual for execution** [D-019].
- V61. Children scheduled individually; assembly never runs as a unit.
- V62. For declaration, a rate scope is an assembly's sample_times declaration against the enclosing scope.
- V63. No atomic assemblies, no opt-in variant [D-019].
- V64. No coarsening needed, because the signal table makes interleaving semantically invisible.
- V65. Consumers read cells whose freshness is guaranteed by topological order rather than contiguity.

Citations: D-019 (V5, V20, V60, V63), D-185 (V13, V16), D-147 (V11-12, V24, V26, V30, V33, V36), D-205 (V45, V49, V52), §10.4, §10.3, §10.6, §9.7, §14.5, §9.3.
Glossary links: boundary, component, tick, harmonic-grid, frame, tick-index, phase, due, cell, signal-table, sweep, execution-order, guard, tier, quiescence, boundary-zero, assembly, rate-scope.
