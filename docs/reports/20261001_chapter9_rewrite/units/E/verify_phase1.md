# Unit E, phase 1 (blind read of new.md)

Intro
- V1. The execution order exists in two representations at two lifecycle stages.
- V2. On `Outputs` (nominal evaluation's product, port classes and execution order) it is plain printable data: paths, stage names, order. [§9.2]
- V3. That data is the authoring and diagnostic form.
- V4. The executor compiles from that order. [D-253]
- V5. This section covers the other form, the one the loop runs. (pointer)

The execution form
- V6. At `Simulation` construction, and per activation (the build's typed products at a scalar type), the data is compiled into the execution form.
- V7. (bold) The execution form is a concretely-typed tuple of entries over statically typed cell storage, traversed by a compile-time-unrolled walk. [D-086]
- V8. This is forced, not a preference.
- V9. Zero-allocation invariant [§7.5], fold-away conformance test [§9.5] and zero runtime graph logic [§5.1] are reachable only under full specialization.
- V10. An entry carries code-selecting things in type parameters: component type and stage.
- V11. It carries plain data in fields: tick divisor, phase, bundle `Δt`, layout offsets.
- V12. Gating compiles to `(tick − Φ) % D == 0` inside the specialized boundary body.
- V13. Interior bodies hold no discrete entries to test. [§10.5]

Cell storage
- V14. (bold) Cells are stored per element type, not per cell. [D-162]
- V15. The signal table is one contiguous block per element type. [§7.1]
- V16. That is the construction pointed at signals rather than state. [§7.1]
- V17. A cell address is a build-time offset into it.
- V18. The offset is carried in an entry field, with the port type as the address's own parameter.
- V19. Gathers reconstruct and scatters flatten through the same leaf walk.
- V20. So the closed vocabulary earns its keep twice.
- V21. This is the entry rule above paying off.
- V22. Two instances of one component type differ only in field values, share an entry type, compile to one body.
- V23. A store enumerating every cell in its own type, indexed in the type domain, compiles one body per instance.
- V24. It also grows the store type with the model.
- V25. The choice was measured, not argued. [D-162, prototypes/cellstore_bench]

Phase bodies, arities and seams
- V26. (bold) Phase bodies are the outer decomposition, and are semantically forced. [D-086]
- V27. Boundary sweep's stage-1 block, both tiers' `y_state` entries alike, is order-free by definition.
- V28. Because the no-feedthrough stage reads no `u`.
- V29. Stage-2 block gates in the due discrete stages (components this boundary admits by compiled `(D, Φ)`).
- V30. Stage-2 is the only topologically ordered block.
- V31. `x_deriv` block (RHS body the stepper calls per stage evaluation) and `s_update` block are order-free with disjoint writes.
- V32. Guards and handlers are their own small callables inside the §10.6 iteration. [§10.6]
- V33. (bold) Each sweep block compiles in two arities off one entry list. [D-147]
- V34. Arities follow the interior/boundary split fixed by §10.5. [§10.5]
- V35. Zero-arg `sweep_1()`/`sweep_2()` are interior variants over continuous entries only.
- V36. That makes `@ballocated(sweep_2()) == 0` a well-defined measurement of the interior path rather than of whichever tick phase.
- V37. `sweep_1(tick)`/`sweep_2(tick)` are boundary variants.
- V38. They gate discrete entries by `(tick − Φ) % D` against the passed tick index, symmetric with `ticks(tick)`.
- V39. `rhs` takes no index.
- V40. One gate serves all three tick-sensitive blocks.
- V41. Because due-ness is per component, per boundary, never per stage.
- V42. (bold) `t*`'s empty due set is arity selection, not an index trick. [D-147, D-185]
- V43. The `t*` iteration therefore runs zero-arg arities, whose bodies contain no discrete entries. [§10.5]
- V44. (bold) These bodies communicate only through stores and the table. [D-194]
- V45. No value crosses a seam (between passes, between blocks of one pass, between chunks).
- V46. Seams therefore cost nothing; decomposition stays free.
- V47. Fusing a step's sweep with its `x_deriv` block, or an event round's sweep with guards and fired handlers [§10.6], is an optimization it may take or decline.
- V48. Two options this structure opens for free are recorded, not committed.
- V49. Deterministic parallel evaluation of order-free blocks.
- V50. They have disjoint writes and no FP reductions to reorder, because §6.2 made every sum an ordered junction entry. [§6.2]
- V51. Finer recompilation granularity: editing a discrete component invalidates the boundary body, not the RHS body.
- V52. Literal under the two-arity split, since discrete entries exist only in boundary variants.

Views and construction
- V53. (bold) Views are spelled rebuild-per-call. [D-086]
- V54. Every entry constructs its bundle (NamedTuple of zero-copy views) at its own position.
- V55. No framework-maintained hoisting, so no cache-invalidation obligation.
- V56. Hoisting belongs to the code generator.
- V57. CSE merges repeated loads exactly where no intervening store invalidates them, which is precisely the staleness rule.
- V58. Sweep-varying bundle fields (`u`, `y_x`/`y_s`) are per-call by topological necessity either way. [§7.1]
- V59. (bold) Construction is type-opaque, and only the executor specializes. [D-086]
- V60. Entry tuples are built from untyped buffers and splatted once.
- V61. Generic tuple utilities (range indexing, long `ntuple` closures, naive recursion) are inference traps at the entry list's length.
- V62. A 400-entry heterogeneous tuple can send generic `getindex` inference into combinatorial collapse.
- V63. The compiled tuple's type therefore has exactly one consumer, the unrolled walk.

Compile cost
- V64. Chunking bounds the compile cost.
- V65. Within a large block the tuple splits into chunks behind non-inlined but statically-typed function barriers.
- V66. Inside a chunk static dispatch, inlining, view SROA, check folding, zero allocation survive.
- V67. At the seams only cross-entry fusion is lost, which table-mediated flow barely had.
- V68. Chunk size is the implementation's only representation freedom (endpoints fully fused, chunk-of-one).
- V69. It converts compile cost from superlinear in the largest body to linear in entry count.
- V70. Anchors measured 2026-07 over synthetic ~15-op bodies on Apple Silicon.
- V71. Last two rows extrapolated to a full aircraft model of ~200–400 entries with larger bodies, assuming chunked mode.
- V72. Table rows: 400 fused Float64 ~0.8 s; 400 chunked Float64 ~0.34 s; 400 chunked 8-partial Dual ~9 s; aircraft nominal seconds; aircraft Dual tens of seconds before mitigation.
- V73. Fused curve is visibly superlinear.
- V74. 8-partial Dual multiplies instruction count ~20x; its chunked curve is linear, instruction-bound not structure-bound.
- V75. Re-measurement on a real model of that scale is pending (`pending.md`).
- V76. Mitigation 1: activations are lazy [§9.4]; a session that never linearizes never compiles `Dual`.
- V77. Mitigation 2: non-nominal activations may compile at reduced optimizer level, because their sweeps run inside service loops where microseconds are irrelevant; a one-line per-module policy.
- V78. Mitigation 3: activations bake into package images via ordinary precompile workloads.
- V79. An aircraft package exercising build-plus-one-sweep per activation turns TTFX from a session tax into a CI artifact.

The measurement seam
- V80. (bold) The phase bodies are the §7.5 measurement seam. [D-116]
- V81. The accessor returns compiled bodies of the nominal activation as named callables bound over the simulation's own buffers.
- V82. `phase_bodies(sim)` returns four blocks: `rhs` (x_deriv), `sweep_1` both arities, `sweep_2` both arities, `ticks` (takes tick index).
- V83. Also returned: per-event guards and handlers, per-component `x_projection` callables, keyed by the model's own roster.
- V84. (bold) The four-body roster is fixed and total. [D-156]
- V85. The accessor returns all of it always, whatever the model declares.
- V86. A model with no discrete components, no events or no continuous state still gets every body.
- V87. Empty ones are legal, compile to no-ops, and their `@ballocated` assertion passes vacuously.
- V88. Consumers then iterate uniformly, no existence checks, no per-model branching.
- V89. The seam makes one promise, diagnostic only. [§13.5]
- V90. (bold) These are the bodies the loop runs, not re-derivations. [D-116]
- V91. That makes the measurement honest, and each callable carries real in-loop argument types by construction.
- V92. A hand-built standalone test cannot reproduce those types.
- V93. D-116 records why per-component tests cannot discharge the invariant. [D-116]
- V94. (bold) CI is warm-then-assert over the roster. [D-116]
- V95. One call compiles, then CI asserts `@ballocated(body()) == 0`.
- V96. At per-body granularity, each sweep arity in its own right [D-147], interior bare, boundary at a due index.
- V97. So a documented §7.5 tolerance loosens exactly one assertion.
- V98. Successor of the migration suite's `@ballocated f_ode!/f_step!/f_periodic!` idiom.
- V99. Also the seam the FlightCore comparison in `migration_outline.md` measures through.
- V100. (bold) Publication is not a phase body. [D-116]
- V101. That is the §7.5 carve-out made structural.
- V102. The accessor exposes exactly what the invariant claims is zero.
- V103. Invoking bodies in isolation mutates buffers outside any frame sequence (a tick entry advances discrete state with no clock advance).
- V104. It leaves them valid but off-trajectory.
- V105. A session wanting to continue meaningfully re-runs `init!`.
