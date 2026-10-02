# Unit D verify, phase 1 (blind read of new.md)

Intro (L3-5)
- V1. Section states how an assembly is declared, how declarations mark assembly vs primitive, how container fields contribute children, how `Group` assembles on the fly. (pointer)

Opening (L7-18)
- V2. **An assembly is a plain struct.** [D-039] (bold)
- V3. Fields typed `<: AbstractComponent` are its children. [D-039]
- V4. All other fields are inert parameters. [D-039]
- V5. Field names are path segments.
- V6. Substitutability and variants use ordinary parametric fields.
- V7. Exactly the shape of `Cessna172X{K, A}`, introduced as Flight.jl's Cessna 172 model.
- V8. Well-known declarations come alongside the struct.
- V9. `inner_connections(::A)` is mandatory even when empty.
- V10. `u_connections`, `y_connections`, `sample_times` join it.
- V11. `transparent_container(::A)` is optional, default `nothing`.
- V12. Naming a container field there drops that field's segment from its children's names (pointer to "Container children").

Class by declaration shape (L20-54)
- V13. **There is no `AbstractAssembly`, only one root `AbstractComponent`.** [D-039] (bold)
- V14. Two reasons rule out a supertype for class. Class glossed as primitive-vs-assembly status.
- V15. Reason 1: domain hierarchies (`AbstractAircraft`, engine families) must carry both classes.
- V16. Example, introduced "In an aircraft library, for example": field `E <: AbstractEngine` must accept primitive `PistonEngine` and composite turbofan assembly alike.
- V17. Reason 2: class is implementation detail behind the contract. [§8.3] Contract glossed as declared interface.
- V18. Class is declared by which well-known declarations a type defines.
- V19. **`inner_connections` is the marker**, mandatory even when empty; defining it makes an assembly. [D-039] (bold)
- V20. Any leaf declaration makes a primitive.
- V21. Leaf declarations listed: `x_init`/`s_init`/`m_init`, `ws_init`, `u_types`/`y_types`, `state_events`, any stage, `x_deriv`, `s_update`, `x_projection` method.
- V22. The rule is total.
- V23. A `<: AbstractComponent` type declaring neither family is a build error naming both families.
- V24. Rationale: rather than a silence that fails later and elsewhere.
- V25. With component-typed fields, the error sharpens into a did-you-mean (glossed: name-shaped failure carrying the list-in-hand).
- V26. Its message reads "holds components but declares no `inner_connections`".
- V27. `inner_connections` plus any leaf declaration on one type is a build error.
- V28. Assemblies have no state of their own; this is the no-atomic-assemblies rule at declaration time. [§10.5]
- V29. Assemblies have no contract of their own.
- V30. An assembly's faces are derived from its children. [§8.6] Face glossed.
- V31. Reading which declarations exist is reading declarations; same move as visibility-by-declaration-site [§8.3], not banned inference-by-evaluation [§8.1].

One arity on both tiers (L56-65)
- V32. Class fixes which declarations a type may define, nothing about their shape.
- V33. Every declaration of a structural fact takes the component alone, on a leaf of either tier and on an assembly.
- V34. Tier glossed as continuous or discrete.
- V35. One exception, the allocator's scalar, is the same on both tiers. [§7.3, D-263]
- V36. Tier is read from the store every leaf declares. [§8.2]
- V37. §8.2 states the arity rule and tier agreement in full. (pointer)
- V38. A declaration on the wrong tier is `DeclarationOnWrongTier`. [Appendix C]

Container children (L67-142)
- V39. **Field typed `Tuple`/`NamedTuple` with every element `<: AbstractComponent` contributes elements as container children.** [D-085] (bold)
- V40. Path-named `"field/1"…"field/N"` (tuple), `"field/key"` (NamedTuple).
- V41. Declaration order governs layout.
- V42. **Containers are transparent grouping, not assemblies.** [D-085] (bold)
- V43. Containers have no contract, no `inner_connections`, no rate scope (glossed: an assembly's `sample_times` declaration), no existence beyond the path segment.
- V44. Elements are children of the parent.
- V45. Parent's `inner_connections`, `u_connections`, `y_connections`, `sample_times` address them by element name.
- V46. Anything wanting its own wiring or faces declares itself an assembly.
- V47. Payoff is parametric composition: `Formation{NT <: NamedTuple}` holds any roster per instantiation, any size, any names, mixed aircraft types.
- V48. Its declaration bodies generate wires by comprehension over keys.
- V49. That is the arity-via-computed-contracts pattern §6.2 uses for `SumJunction{W, N}`, at structure scale. [§6.2]
- V50. Swarm worlds consume it directly. [§14.9]
- V51. Mounting consumes it too; mounting glossed as relocation of a whole problem or tap set with `at("aircraft/red", problem)`.
- V52. **A component may declare at most one container field name-transparent.** [D-211] (bold)
- V53. Declaration `transparent_container(::MyType) = :field`, default `nothing`.
- V54. That field's elements contribute under bare keys `"key"`, `"1"` instead of `"field/key"`, `"field/1"`.
- V55. Bare keys apply everywhere a child name appears: wiring endpoints, `sample_times` keys, read paths, `at` prefixes, diagnostics. [D-211]
- V56. Naming is the only thing the declaration changes.
- V57. Elements are parent's children as before, laid out in declaration order.
- V58. Container keeps contract transparency: no `inner_connections`, no faces, no rate scope.
- V59. Edges of the container form are fixed by rule. (lead-in)
- V60. Mixing component and non-component elements is a build error in the did-you-mean family. [D-085]
- V61. The error carries the offending name plus the list-in-hand it should have matched.
- V62. All-component elements are children; zero-component elements are inert parameter data.
- V63. Containers of containers are rejected in the first cut, because deeper grouping is what assemblies are for. [D-085]
- V64. The element whose value is a component-bearing container is named, with its type (`ContainerNested`).
- V65. Empty containers are legal, contribute zero children, so parametric code needs no special case. [D-085]
- V66. Abstract element types follow the plain-field concreteness discipline: directly concrete or concrete through type-parameter bounds.
- V67. That is the generic holding (glossed) §8.8 allows. [§8.8]
- V68. **Bare key from a name-transparent container colliding with any sibling child name is a build error naming both.** [D-211] (bold)
- V69. The §8.7 `sample_times` sugar (container's bare field name keys one declaration for all its elements) leaves one ambiguity. [§8.7]
- V70. A transparent element's bare key equal to its own field's name joins this collision error. [D-215]
- V71. **Bare key equal to the name of a sibling container field that contributes children is refused the same way.** [D-212] (bold)
- V72. No child bears that name, but the key would shadow the container's `"field/key"` segment grammar. [§6.1]
- V73. Its elements would be unreachable behind a diagnostic blaming the wrong child.
- V74. **An empty field reserves nothing** [D-212] (bold), because it reaches no children and its value cannot be told from empty inert parameter data.
- V75. The judgment is therefore per-instantiation, like every wiring judgment.
- V76. `transparent_container` must name a container field of the type. [D-211]
- V77. Declaring two transparent containers on one type is a declaration error. [D-211]

Group (L144-201)
- V78. The immutable version of grouping components by plain calls needs no builder (`Assembly()` + `add!`/`connect!`, rejected below).
- V79. It is already expressible under this section's rules.
- V80. **`Group` expresses it as a single library component** (bold), part of the starting inventory. [§13.7, D-184]
- V81. A `NamedTuple` field's elements are its children by the container rule, name-transparent so bare keys. [D-211]
- V82. Its declarations are ordinary functions of the instance, free to read its fields.
- V83. Code block: `Group{C,W,I,O}` struct with children/wires/inputs/outputs; inner/u/y_connections return the fields; `transparent_container(::Group) = :children`; keyword constructor; example `world` with Plant and PID.
- V84. `Group` is one type, defined once; every ad-hoc topology is a value of it.
- V85. Type parameters carry children's concrete types, so activation is unchanged.
- V86. So is the executor (glossed: compiled form of stage execution order). [§9.7]
- V87. Wiring validation, did-you-mean errors, two-producer check all run at build against the instance as for a named assembly.
- V88. What is given up vs a named type is exactly what named types are for: dispatching domain code on `::Cessna172X`, and reusable identity for the topology.
- V89. The exploratory/programmatic composition `Group` serves does not want it anyway.
- V90. **The builder (`Assembly()` + `add!`/`connect!`) is rejected.** [D-039] (bold)
- V91. Its one real advantage, programmatic generation, survives intact in type-based form.
- V92. A declaration is an ordinary function body; loops and comprehensions build the returned tuple.
- V93. The reach of the builder rejection is fixed by D-184. [D-184]
- V94. It targets mutable recipes, not type-based semantics.
- V95. `Group` is the library's anonymous assembly form beside named types, shipped as Julia ships anonymous functions alongside named ones.
- V96. It serves the model assembler (persona for whom topology is data rather than a named type) [§13.7].
- V97. With a library addition resting on one opt-in declaration, `transparent_container`. [D-211]
- V98. With that declaration, a `Group`'s wiring and rate declarations read exactly like a named assembly's, child and face, with no `children/` boilerplate.

Bold count: 11 spans (V2, V13, V19, V39, V42, V52, V68, V71, V74, V80, V90).
