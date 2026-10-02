# B2 verify, phase 1 (blind read of new.md)

V1. A `u_types` declaration is a bare `NamedTuple` of types. [D-263]
V2. It is written at nominal `Float64`. [D-263]
V3. It takes the component alone on both tiers. [D-263]
V4. The one piece of framework vocabulary it admits is the `Pinned{P}` marker.
V5. The marker wraps a leaf type to say the leaf never follows the activation scalar.
V6. The marker wraps the whole entry.
V7. **A marker below the top of an entry is `IllegalPortType`.** [D-265]
V8. On a continuous consumer the declaration is walked: every `Float64` position follows the scalar.
V9. On a continuous consumer a `Pinned` leaf stays `Float64`.
V10. On a discrete consumer the declaration pins wholesale.
V11. A `Pinned` entry on a discrete consumer says nothing. [§8.5, D-263]
V12. A `Pinned` entry on a discrete consumer is `DeclarationOnWrongTier`. [§8.5, D-263]
V13. **Entries are face bounds, not cell types.** [D-263, D-078]
V14. **The reading (of entries) is permissive.** [D-263, D-078]
V15. Definition: a face is the name a port (one declared input or output) wears on its component's boundary.
V16. An entry states, per leaf, what the consumer allows to arrive there.
V17. Entries come in three forms.
V18. Table row 1: `Float64` alone or as type parameter (`SVector{3, Float64}`, `RQuat{Float64}`) is tolerant; activation scalar or frozen `Float64` may arrive.
V19. Table row 2: `Pinned{Float64}`, or `Pinned{P}` around any leaf type, is demanding frozen; never partials.
V20. Table row 3: `Int`/`Bool`/enum leaves and abstract reference-typed entries are as they always were; what the declared bound admits.
V21. An unpinned entry is what a promoting consumer writes.
V22. The unpinned entry is the overwhelmingly common case.
V23. A walking producer, a frozen discrete producer and a root input are all admissible behind an unpinned entry.
V24. Definition: a root input is the root component's own input face, produced by no component.
V25. Therefore substitution stays intact.
V26. A `Pinned` entry is the FFI door: the input must never carry partials.
V27. A component whose internals cannot propagate `Dual`s (opaque wrapper, C table, hand-rolled solver) declares it.
V28. Its AD-incompatibility then becomes schema-visible instead of folklore.
V29. The failure moves from a `MethodError` inside user math at the first `Dual` probe to a named wiring error at build. [§6.1]
V30. Definition: probe = the build's checking evaluation of a user function.
V31. **`Pinned` records that a leaf carries no partials, not that an implementation cannot take them.** [D-266]
V32. An AD-opaque implementation that must participate keeps its entry tolerant and supplies a local derivative rule. [§14.10]
V33. A walking producer feeds a pinned entry through the `Freeze` block. [§13.7]
V34. `Int`/`Bool`/enum leaves and abstract reference-typed entries admit what their declared bound admits.
V35. **Abstract entries state structural substitutability.** [D-078]
V36. Several concrete producer types are admissible behind one stable face.
V37. The field handles are the demonstrated client, e.g. `terrain = AbstractTerrainField`. [§4.4]
V38. Field handles carry no scalar position, because they are references rather than numbers.
V39. Abstract entries are never the tool for eltype genericity.
V40. The tool for eltype genericity is exactly an unpinned entry (a promoting consumer writing `SVector{3, Float64}` rather than an abstract bound).
V41. Inputs are the component's requirements.
V42. Only against requirements are the unconnected-input error, over-wiring detection and did-you-mean messages definable at all. [§6.1]
V43. Definition: a did-you-mean message is the offending name plus the list-in-hand it should have matched.
V44. D-033 records the rejected names-only contracts. [D-033]
V45. **Two clauses check a wire.** [§6.1, D-263, D-236]
V46. The first is the nominal bound check, stated at nominal.
V47. The producer's declaration at `Float64`, markers stripped, must be `<:` the entry at `Float64`. [D-078]
V48. The bound check is one uniform rule.
V49. It degenerates to exact equality for a concrete entry, because concrete types are final.
V50. The second is the tier-scoped walk-compatibility clause.
V51. For a continuous consumer, a walking producer leaf (one the producer left unpinned) requires an unpinned entry.
V52. A pinned producer leaf satisfies either entry, because frozen values embed upward.
V53. An opaque leaf embeds nothing and is admitted at an unpinned entry as the producer's cell. [D-264]
V54. Both sides are plain declarations the walk retypes.
V55. Therefore the clause is decidable in the structure step by retyping them at a marker scalar.
V56. Definition: structure step = the build's first step, declaration reading only.
V57. No user stage code runs (in deciding the clause). [§9.1]
V58. A violation is `WalkingFaceAtFrozenEntry`.
V59. §6.1 names the bound check's kind too, and gives the remedies this violation's message carries. [§6.1]
V60. **Discrete consumers take the bound check only.** [D-263]
V61. That scope is a correctness rule rather than tidiness.
V62. A discrete stage reads exclusively at real ticks in the nominal world.
V63. Definition: ticks = the instants a discrete component runs.
V64. A `Dual`-carrying cell exists only inside activations discrete stages never run in. [§9.4]
V65. Therefore wires from a continuous producer to a discrete consumer are unconditionally legal.
V66. The unscoped variant is rejected.
V67. Because entries are bounds, nothing is ever "overwritten".
V68. Cell types are single-sourced from the producer side per activation. [§9.4, D-054]
V69. A `Dual`-carrying cell behind an unpinned entry is the design working, not a promise broken.
V70. The genericity obligation is the code-level complement.
V71. It says that whatever scalars the wiring delivers, the consumer's math promotes.
V72. It is checked by the `Dual` probe, never declared. [D-054]
V73. **The obligation is scoped to the unpinned entries.** [D-263]
V74. A `Pinned` input imposes no such obligation, which is its point.
V75. **Declarations record choices, and obligations are checked.** [D-078]
V76. The marker's absence records the tolerance choice, and the probe checks the promotion.
V77. The permissive reading is the operative one. [D-263]
V78. It escapes two other readings: predictive (entry says what will arrive) and envelope (a promise to promote).
V79. The log rejects both. [D-054, D-078]
V80. The permissive reading predicts nothing.
V81. It is not constant, because pinned entries are rare but real.
V82. That is what makes the marker carry information here.

Root inputs
V83. Root inputs are the one place an entry types a cell.
V84. A root input is produced by no component, so it has only the consumer declaration to take a type from.
V85. The root-input type is the entry at `Float64`, markers stripped. [D-078]
V86. Only a tight bound determines a root-input type. [D-078]
V87. Therefore a face surfacing as a root input must resolve to a concrete declaration.
V88. Staging cells, the trace header and `probe_value` all need that concrete declaration.
V89. Definition: staging cells hold each device's pending writes.
V90. Definition: the trace header is the trace's fixed preamble.
V91. **Abstract-at-root is a build error.** [D-236]
V92. The uniform root doctrine below does not relax it. [D-208]
V93. A leaf declaring an abstract entry (`terrain = AbstractTerrainField`) still cannot be built bare, because a root input must resolve to a concrete declaration.
V94. `AbstractAtRoot` names the face and the remedy.
V95. The remedy is to wire a concrete producer, or a stub child in a test rig.
V96. Definition: the component test rig is a one-child wrapper exporting its child's whole input face set. [§13.7]
V97. The rig is the idiom for that case. 
V98. It satisfies the entry with a stub child inside the rig. [D-120]
V99. Under fan-out the root-input type is the unique concrete declaration among its consumers. [D-236]
V100. Abstract co-consumers are checked against it. [D-236]
V101. Two different concrete declarations remain an error.
V102. The root-input cells at an activation follow the root-input type by retyping that same entry at the activation's `T`.
V103. **That retyping makes seedability schema-visible.** [D-263]
V104. An unpinned root input is a lawful linearization `B`-matrix tap. [§14.10]
V105. A `Pinned` root input is declaredly unseedable. [§14.10]
V106. **Fan-out combines tolerance by a meet, not by agreement.** [D-168]
V107. The root input pins at every activation if any consumer's entry pins.
V108. It follows the scalar only when every consumer tolerates.
V109. Root-input cells at an activation are the root-input type with every leaf following the scalar when every consumer's entry admits that type, and the root-input type itself otherwise.
V110. Therefore a mixture of pins across leaves pins the whole root input. [D-236]
V111. Two consumers of one root input may agree at nominal and still differ in tolerance.
V112. `SVector{3, Float64}` and `Pinned{SVector{3, Float64}}` are one type at nominal.
V113. Therefore the root-input type is unambiguous while the entries disagree about partials.
V114. That mixture is a legitimate model rather than a mistake.
V115. Example: a command consumed by a promoting aerodynamics leaf and by an AD-opaque table is the FFI door in use.
V116. The direction of the meet is forced by embedding.
V117. A pinned root-input cell feeds an unpinned entry lawfully, because frozen values embed upward as zero-partial constants. [§9.5]
V118. A `Dual`-carrying cell arriving at a `Pinned` entry is precisely what that entry forbids.
V119. Therefore the meet is the only assignment satisfying every consumer at once.
V120. The meet mirrors the walk-compatibility clause on the producer side. [§6.1]
V121. What the mixture costs is stated where it is paid.
V122. Such a root input is unseedable.
V123. A tap selecting it is rejected naming the pinning consumer rather than the face alone. [§14.10, D-168]
V124. **Any component may be the root of a build.** [D-208]
V125. **The model's root inputs are the root's own input faces.** [D-208] (same bold sentence as V124)
V126. Definition: an assembly is a component of pure composition.
V127. For an assembly the root inputs are the faces declared through `u_connections`, each traced through the face chain to the leaf entries consuming it. [§6.1, §11.3]
V128. For a primitive they are its `u_types` keys directly, because a leaf's faces are its own port names. [§8.6]
V129. Each (primitive key) is then its own consuming entry.
V130. The type derivation is one rule across both cases: the tight bound at the ultimate consuming entry.
V131. At the root the two contract declarations share one face namespace. [§8.6, D-210]
V132. So a key declared in both is a build error. [§8.6, D-210]
