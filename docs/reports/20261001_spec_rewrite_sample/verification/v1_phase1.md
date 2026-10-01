# Phase 1: atomic claims of new.md (blind)

N1. The build types the model once, at Float64.
N2. Linearization and gradient trim need the same model at another scalar type, a Dual.
N3. An activation is the build's typed products at a given scalar type; it supplies that typing.
N4. (Rule) An activation at T re-runs the activation step with a different scalar.
N5. (Rule) It redoes five things (list N6-N16).
N6. Producer-fed cells are re-typed by walking the producing component's output declaration at T (§8.2).
N7. A continuous producer's declaration follows the scalar at every unpinned leaf.
N8. A discrete producer's declaration pins.
N9. Root-input cells are re-typed by walking the consuming u_types entry at T.
N10. §8.2 reads that entry permissively.
N11. An unpinned u_types entry follows the activation; a Pinned entry stays frozen.
N12. The state type is re-derived by the walk over x_init's leaves.
N13. The table and state buffers are laid out again.
N14. Workspace allocators are invoked again at T; the activation does not introduce them.
N15. Their first invocation precedes the nominal evaluation's probes (§9.1/§9.3).
N16. A continuous component's scratch carries the activation's scalar (§7.3).
N17. The probe chain runs again.
N18. Nothing structural moves across activations.
N19. Structure is the structure step's product; Outputs is the nominal evaluation's product.
N20. Neither depends on T, by construction.
N21. So (because of N19-N20) no execution order and no name list changes across activations (D-253).
N22. (Rule) Each activation probes exactly the set of functions it can execute.
N23. (Example) A Dual activation, as linearization and gradient trim use, evaluates the model at a frozen instant.
N24. In it, discrete stages are gated off and hold Float64 values; this is the frozen-constant semantics of §8.2.
N25. Guards and handlers never run (in a Dual activation).
N26. Event localization runs as Float64 sweeps by design (§10.4).
N27. Only the continuous output stages (y_state/y_direct) and x_deriv ever see a Dual.
N28. So only they are probed at Dual.
N29. (Why) Probing discrete stages, s_update or guards at Dual would check code against a number type it cannot receive.
N30. The rule (N22) has no special cases.
N31. The §5.6 tracer activation follows it identically.
N32. "Tracer activation" names the global set-tracer (D-012).
N33. It is a whole-model run at the tracer scalar, and so an activation like any other.
N34. The cycle classifier (§5.6) is the other tracer variant (D-012).
N35. The cycle classifier traces each member of a cycle locally and needs no execution order.
N36. It runs in the nominal evaluation's failure path and is not an activation at all.
N37. (Rule) Non-nominal activations run at first request, not at build.
N38. (Why) Their dominant cost is compiling the continuous chain a second time, at Dual.
N39. For interactive fly-around use, that cost is pure waste.
N40. Laziness has a price, and the spec states it openly.
N41. A successful build does not certify that the model is linearizable.
N42. A pinned Float64 (§7.2) may hide in a constructor.
N43. A leaf that really participates may be declared Pinned; that is the misplaced pin of §8.2.
N44. Either one lurks until the first Dual activation.
N45. The probe then fails and names the offending constructor or leaf.
N46. (Rule) The repository's test suite enforces genericity by policy, not by advice (D-166).
N47. (Rule) Every component gets a Dual activation built in CI.
N48. The exhaustive mode does it: build(world; activations = (Float64, ProbeDual)).
N49. This call runs the exhaustive set.
N50. It catches both genericity violations and misplaced pins at PR time.
N51. Its cost is one activation per component.
N52. The keyword is the whole entry point; no separate check function exists (D-275).
N53. The same keyword is also recommended for the parallel-sweep idiom (§11.1).
N54. (Recommendation) Pre-materialize the activations the sweep will need.
N55. The shared Build is then a fully immutable artifact, and no path needs synchronization.
N56. ProbeDual is the framework's public canonical probe scalar: const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}.
N57. ProbeDual exists because an activation is keyed by a concrete scalar type.
N58. The bare Dual is a UnionAll.
N59. It cannot key an activation, be walked to, or answer zero(T).
N60. The width of ProbeDual is arbitrary.
N61. CI pins genericity, not any particular Jacobian.
N62. So one canonical width suffices, even though §14.10 chunks at whatever widths it needs.
N63. (Rule) Caching is an implementation detail, not semantics.
N64. An activation is a pure function of the build and the concrete scalar type.
N65. So the activation dictionary belongs to the Build.
N66. The nominal Float64 entry is one key in it like any other (D-253).
N67. Each entry holds layouts, compiled plans and a validated flag, keyed by that type.
N68. An entry is immutable once constructed, and so freely shareable.
N69. (Rule) Buffers are never cached, because every buffer set has exactly one owner.
N70. The Simulation owns its nominal activation's buffers.
N71. It materializes them from the cached layouts at construction.
N72. The loop's zero-allocation stepping runs on them.
N73. Every service invocation owns the scratch set it instantiates from those same layouts.
N74. §14.8 states this for trim!; it is the general rule, not local to trim.
N75. Julia itself caches compiled code, process-wide.
N76. The framework cache saves the expensive part: probe re-runs, layout construction, and Julia's compilation of the Dual chain.
N77. These savings amortize in loops that reuse an activation.
N78. In the envelope-grid gain-schedule case, hundreds of trim-then-linearize points pay those costs once.
N79. The per-point allocation of a working store set does not amortize.
N80. It is O(model size), and trivial against the solve it feeds.
N81. The zero-allocation invariant (§7.5) covers only the stepping loop.
N82. The services were always allocation-tolerant.
N83. Nothing numerical is ever cached.
N84. Dual{Tag,V,N} carries the partial count.
N85. Therefore a different seeding width is a different scalar type.
N86. It gets a separate entry and a separate Julia compile.
N87. (Rule) Lazy materialization is torn-state-free.
N88. (Rule) Concurrent first requests for the same activation must never expose partially populated cache state.
N89. The mechanism is unspecified.
N90. A guard around insertion suffices, paid at service time and never on the hot path.
N91. (Why) An activation is a pure function of build and scalar, so the worst benign race is duplicated work.
N92. Torn state is excluded by contract, not by luck.
