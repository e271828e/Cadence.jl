# E1 verify, phase 1 (blind read of new.md)

Context paragraph
- V1. An assembly is a component of pure composition, with no dynamics of its own. [glossary link only]
- V2. An assembly wires its children and names its boundary with strings.
- V3. A face is the name a port wears on its component's boundary. [glossary link only]
- V4. Pointer: section covers path form, three wiring declarations and their shared direction invariant, face names, root inputs, root face uniqueness; worked IMU closes it. (pointer)

Paths
- V5. **Paths are slash-separated strings**, relative to the assembly or model root they are read from. [D-040]
- V6. Paths have no leading slash. [D-040]
- V7. There is one canonical form. [D-040 by position]
- V8. Declarations, error messages, device/trace addressing and the HDF5 log tree share it verbatim. [§11.3]
- V9. Container children are the elements of a tuple field holding only components. [§8.5]
- V10. Container children add index and key segments, e.g. "aircraft/2", "aircraft/red". [D-085]
- V11. These are ordinary segments, resolved against the container field.
- V12. A container declared name-transparent adds no segment of its own; its elements go by bare key. [§8.5, D-211]
- V13. Instance navigation, tuples of symbols and dotted paths were all rejected. [D-040]

Short/long paths
- V14. The three wiring declarations use only the short case: one child segment and one face name. [§6.1, D-207]
- V15. The read side walks the full depth, e.g. "systems/ldg/left/trn" in a snapshot or the log tree.
- V16. A snapshot is the immutable per-boundary publication. [glossary link]
- V17. The read side is the inspection side.
- V18. It resolves a path with `resolve` under the instance walk. [§13.3]
- V19. One fact behind the rejection of instance navigation is relied on downstream.
- V20. Symmetric immutable siblings are `===`-identical, so a path is unrecoverable from an instance.
- V21. That is why the helpers name the child by path. [§8.8]

inner_connections
- V22. `inner_connections(::A)` is an ordered collection of "src/face" => "dst/face" pairs.
- V23. **Every pair runs strictly from a child face to a child face.** [D-170]
- V24. The wiring rules of §6.1 apply. [§6.1]
- V25. One wire per input.
- V26. Every endpoint is an immediate child and one of its faces, container key segments included.

Boundary
- V27. **The boundary is declared by two further methods, one per direction.** [D-170]
- V28. `u_connections(::A)` is an ordered collection of pairs, face name => internal endpoint path.
- V29. An input face routed to several immediate children takes a tuple of paths instead, e.g. "trn" => ("left/trn_field", "right/trn_field", …).
- V30. This is fan-out through the boundary.
- V31. **Every entry routes to at least one internal endpoint.** [D-210]
- V32. An empty tuple is a declaration error. [D-210]
- V33. Because a face feeding nothing declares nothing. [D-210]
- V34. `y_connections(::A)` runs internal source path => face name ("aircraft/pose" => "view_pose").
- V35. Purpose: so its pairs, like every pair in the three declarations, read along the flow.

Direction invariant
- V36. One invariant spans all three declarations: every pair's arrow points the way the signal flows.
- V37. Left side is a producer or entry point; right side is a consumer.
- V38. Every right side is fed exactly once.
- V39. **Direction is therefore declared by the method**, not inferred. [D-170]
- V40. Resolved endpoints only cross-check it.
- V41. An entry whose endpoint resolves to a port of the wrong direction is a build error.
- V42. The error names the method, the entry and the resolved port's actual direction.
- V43. A mixed entry is not expressible, because the single list that made that error class possible does not exist.
- V44. Two entries producing the same output face remain the ordinary two-producers error.

Face types and tiers
- V45. **Face types and tiers are derived from the internal endpoints.** [D-041]
- V46. A tier is the continuous or discrete side of the hybrid formalism.
- V47. This derivation is the blessed (explicitly sanctioned) derivation-from-declarations. [§8.2]
- V48. The derivation is forced, not merely convenient.
- V49. An assembly is tier-neutral.
- V50. It exports continuous-sourced and discrete-sourced ports side by side.
- V51. A face's cells (entries of the signal table) follow the producer's own declaration. [§8.5]
- V52. They are evaluated at the activation scalar on the continuous tier and pinned on the discrete.
- V53. Three alternative spellings are rejected. [D-041, D-170] (which three is not stated)
- V54. Publicity is never implicit. [§8.3]

Face names
- V55. **Face names are arbitrary strings with two build-checked invariants.** [D-046]
- V56. First: a face name contains no `/`, reserved for structural paths.
- V57. Second: uniqueness across the union of the two boundary declarations' face names. [D-170]
- V58. Every other naming choice is author convention, not framework law.
- V59. Separators and grouping prefixes like "pilot.throttle_axis" are such choices.
- V60. The `input_passthrough` helper's defaults document the house style without legislating it. [§8.8]

Two notations
- V61. The two-notation rule is directional. **It separates structure from derived contract, not read from write.** [D-129]
- V62. Slash is structure: endpoint paths walking real children and ports, and the inspection side's snapshot and log addressing.
- V63. Face names are opaque derived-contract tokens.
- V64. The periphery is everything outside the loop that exchanges data with it. [glossary link]
- V65. The periphery's write side is input devices, mappings, the trace and the GUI write path.
- V66. That write side speaks face names exclusively. [§11.3]
- V67. The read side speaks face names wherever it wants meaning that outlives the build: integration bindings (`get_face`, §11.2) and service reads (§14.4).
- V68. The three declarations return pairs of strings rather than NamedTuples. [D-046]

Root inputs
- V69. Root inputs fall out with no vocabulary of their own.
- V70. At every non-root level an input face declared through u_connections is fed by the parent's wire.
- V71. At the root there is no parent.
- V72. There the root component's input faces are the write surface. [§11.3]
- V73. Write surface = the set of faces a writer's batch entries may reach. [§11.3]
- V74. Which declaration supplies them follows the root's class. [D-208] (not bold)
- V75. Class is a component's primitive-versus-assembly status.
- V76. Assembly root supplies its u_connections keys; primitive root its u_types keys. [§8.2]
- V77. Nothing downstream distinguishes the two.
- V78. The whole-tree obligation model states the complementary error rule. [§6.1]
- V79. An assembly never declares its external connections.
- V80. Those live in the parent that instantiates it, exactly as a leaf's do.

Root uniqueness
- V81. **At the root the uniqueness invariant follows the root's class.** [D-210]
- V82. A primitive root declares no boundary methods.
- V83. Its face set is therefore the union of its u_types and y_types keys.
- V84. A key declared in both is the same build error a duplicate face name is.
- V85. The root is where those two declarations first share an address space.
- V86. A root input places a cell the periphery writes, so a collision would put two cells at one name. [§11.3]
- V87. Below the root nothing collides, because a primitive's input faces alias their producers' cells and place nothing.
- V88. Non-root leaves are left alone.

Worked IMU
- V89. The strapdown IMU of §3.4 is spelled here in full. [§3.4]
- V90. Worked example = a full spelling of a mechanism against a concrete case. [glossary]
- V91. It is a mixed-tier assembly.
- V92. It exercises paths, faces and sample times together.
- V93. (code block) IMU has three children: integrals (continuous; cumulative Θ, q, Υ, V), sampler (discrete; integrate-and-difference latches), errors (discrete; scale/bias/noise on sample); inner wires integrals→sampler on Θ,q,Υ,V and sampler/sample→errors/sample; u_connections splats input_passthrough(imu, "integrals"); y_connections maps sampler/sample→sample, errors/sample_meas→sample_meas; sample_times sampler = Relative(1), errors = Relative(1).
- V94. `input_passthrough` enumerates the child's input faces and nothing else. [§8.8]
- V95. That is why the integrals' pass-through of kinematic-truth inputs (q_eb, r_eb_e, ω_eb_b, a_ib_b, α_ib_b) is a bare splat with nothing to say about direction.
- V96. The measured-increment face sources errors/sample_meas, the error model's output port, not errors/sample, the input the sampler already feeds.
- V97. Listing errors/sample in y_connections would fail the direction cross-check.
- V98. Listing it in u_connections while it is wired is the two-producers error. [§8.8]
- V99. Fact 1: the assembly is tier-neutral.
- V100. Every face's type and tier derive from its internal endpoint.
- V101. A sample_times key on integrals, the continuous child, would be a build error. [§8.7]
- V102. Fact 2: the two discrete children default to Relative(1) anyway, so this sample_times declaration is declaratory.
- V103. Their absolute rate arrives from the enclosing scope at deployment. [§8.7]
- V104. The latch-back wire (below), where the integrals consume the sampler's published latch, would join inner_connections as one more ordinary pair.

Notes from blind read
- N1. V53: "Three alternative spellings" are never named in new.md; reader cannot tell what they are.
- N2. V104 "(below)" points forward to something outside this unit.
- N3. V19 "relied on downstream" — the downstream use is V21 (§8.8 helpers).
- N4. "write surface", "two-producers error", "instance walk", "pinned" are used via links/citations only.
