# Unit F, phase 1 (blind assertion list from new.md)

## §8.7 Rate scopes
V1. An assembly schedules its children through one declaration, `sample_times`. (pointer: section outline)
V2. The declaration maps each child name to a `Relative` or `Absolute` entry (example `sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))`).
V3. These are the two forms §10.5 defines. [D-185]
V4. Relative entries compose affinely down the tree. [§10.5 context]
V5. Absolute entries anchor.
V6. All are compiled to one `(D, Φ)` pair per discrete component.
V7. §10.5 holds the wrappers' definitions, their validation and the default for an unlisted discrete child. (pointer)
V8. The declaration is optional, and so is any given key. [D-042]
V9. Under that default, only multiplied, phased or anchored children need appear.
V10. **Keys are immediate child names only.** [D-042] (bold)
V11. A deep key would edit another type's design from outside.
V12. The composition rule guarantees an author never needs a deep key.
V13. Container elements (§8.5) are immediate children, so `"aircraft/red"` is a legal key. [D-085]
V14. `sample_times` needs no rule change for container elements. [D-085]
V15. The bare field name is sugar for a uniform declaration across all elements; it applies one declaration to every element.
V16. The sugar keys on the field, not on a path segment, so a name-transparent container keeps it unchanged.
V17. `(children = Relative(2),)` is the uniform spelling for a `Group`.
V18. A `sample_times` key on a continuous child is a build error. [D-042]
V19. That error is the declaration-time side of a run-time fact: a continuous bundle carries no `Δt`. [§10.5]
V20. `Δt_base`, `h` and `N_base` appear in no declaration.
V21. They are deployment decisions fixed at deployment. [D-254]
V22. §9.2 gives the three sources for `Δt_base`.
V23. The declaration belongs to the assembly type, not to the child instance. [D-042]
V24. Reason: a sample time is a design ratio or a modeled instrument's intrinsic rate (§10.5), never a per-instance value.
V25. An instance wrapper in the style of FlightCore's `Subsampled` is rejected. [D-042]

## §8.8 Computed connections and generic holding
V26. `u_connections` and `y_connections` are ordinary functions evaluated at build against the concrete instance. [D-043]
V27. They may therefore compute entries from child contracts (each child's declared interface).
V28. That is derivation from declarations, which §8.2 blesses.
V29. (pointer) Section covers passthrough helpers, single feed list, generic holding.

### Passthrough helpers
V30. `input_passthrough` is a framework helper; sketch shown. Faces are the names ports wear on component boundaries.
V31. Sketch: `declaration_error` has two shapes, (path, why::Symbol) and (path, unknown, legal) with did-you-mean against the legal set.
V32. Sketch signature: `input_passthrough(assembly, child_path; sep=".", prefix=replace(child_path,"/"=>sep), except=(), only=(), select=nothing)`; `prefix=""` means no prefixing; one selector per call; `select` is a predicate over face names.
V33. Sketch: `resolve` does a getfield walk along "/" segments.
V34. Sketch: `input_faces(child)` is the leaf's `u_types` keys, or entries of `u_connections(c)` for an assembly.
V35. Sketch: giving more than one selector raises `declaration_error(child_path, :multiple_selectors)`; exclusivity enforced, not documented.
V36. Sketch: unknown names in except/only raise `declaration_error` with the list in hand.
V37. Sketch: `given == 1` with empty `wanted` is EmptyFaceSelection, a build warning through §9.2's channel; a bare call over a faceless child is silent.
V38. Sketch: label is `prefix * sep * n` unless prefix empty; returns pairs label => "child_path/n".
V39. Sketch: World example with `except = ("atm","trn")` yielding "aircraft.pilot.throttle_axis", and `prefix="env", sep="_"` yielding "env_wind_N"; `y_connections` maps "aircraft/pose" => "view_pose".
V40. The child is named by path and never passed as an instance, because the `===` problem (§8.6) makes a path unrecoverable from an instance.
V41. A face name containing dots is a legal final path segment on the internal-endpoint side. [D-046]
V42. That holds precisely because slash is the only structural separator.
V43. Computed entries mix freely with hand-written ones in either declaration. [D-043]
V44. `resolve` and `input_faces` are build-pipeline primitives needed anyway; `input_passthrough` is a thin composition; that keeps the helper sugar rather than machinery.
V45. There is no `rename` hook, because the boundary declarations are ordinary code. [D-046]
V46. An author renames by mapping over the pairs.
V47. Normative signatures for both primitives are in §13.3.
V48. Every error stays first-class.
V49. An `except` face the assembly then fails to wire is an ordinary unconnected input.
V50. A face both wired and passed through is a two-producers error. [D-145]
V51. `except` or `only` naming a nonexistent face errors with the child's face list in hand.
V52. A `prefix = ""` collision is caught by the build's uniqueness check like any hand-written duplicate.
V53. **The selectors are exclusive.** [D-251] (bold) A call takes `except`, `only` or `select`, one and no more.
V54. `select` is a predicate over the child's face names; the helper keeps the names it accepts.
V55. More than one selector is `UnknownFaceSelection` with reason `:multiple_selectors`, "more than one selector given", payload naming the selectors given.
V56. **A call that gives a selector and keeps nothing raises `EmptyFaceSelection`** (bold), a warning on the `Build`'s list. [§9.2, D-251]
V57. A bare call over a faceless child is silent, because passing nothing through is what it asked for.
V58. EmptyFaceSelection payload names the helper, the child path, the selector given with its names, and the child's face list.
V59. The warning exists because an empty selection is almost always a typo the unknown-names check cannot see (e.g. `only` naming existing faces while `select` matches none, or `except` listing every face).
V60. It warns rather than errors because a level may legitimately pass nothing through under one configuration of a generic child.
V61. `select` exists for feed lists.
V62. At the scale of Flight.jl's C172X demo, the feed list below already computes the `except` tuple; a closure over the same list says the same thing without building the tuple.
V63. The effective face list is plain printable data, the inspectable derived contract of this instantiation.
V64. Computation does not auto-bubble. [D-043]
V65. The author wrote down "every input face of this child that I don't feed, I expose under this prefix", explicit at the type level and evaluated at build.
V66. The helpers come in pairs, because the name carries the direction. [D-171]
V67. `input_passthrough` reads `input_faces(child)`; the selector filters face names within that set.
V68. The helper exists for the pass-through case, where an assembly hands a child's unfed requirements up one level.
V69. **`output_passthrough` is its sibling.** [D-209] (bold)
V70. `output_passthrough` is splatted into `y_connections`, reads `output_faces(child)`, has the same prefix/sep surface, the same three exclusive selectors and the same declaration-time error set.
V71. Example: `y_connections(sys::Systems)` with `output_passthrough(sys,"ldg"; only=("damaged",))` yielding "ldg.damaged", plus "aero/wrench" => "wrench".
V72. Its consumer is one-level routing. [§6.1, D-209]
V73. Every level re-exports the outputs it surfaces, so the output side needs the computed spelling the input side already has.
V74. Both helpers take `child_path` naming an immediate child, container key segments included. [D-207]
V75. The default `prefix` folds the path's slash into `sep`, so `"gear/1"` labels faces `"gear.1.…"`.
V76. The default stays a legal face name for every blessed `child_path`.
V77. An explicit `prefix` is used verbatim.
V78. A deeper path meets `resolve`'s one-level rejection like any other wiring endpoint. [§13.3, D-207]
V79. There are two helpers rather than one keyword. [D-171]
V80. The boundary declarations split by direction into `u_connections` and `y_connections`; after that split a single call cannot emit entries into two declarations.

### One authored feed list
V81. The World example's two-entry `except` understates the real shape.
V82. Every level of a realistic tree is a generic seam (narrow, named interface kept deliberately thin).
V83. An assembly that feeds some of a child's input faces while passing the rest up must name the fed ones in `except`.
V84. At the scale of Flight.jl's C172X demo, that is four seams and roughly ten names at the innermost one.
V85. Each `except` tuple restates the wire list in the same assembly's `inner_connections`.
V86. That is structure kept in two artifacts [D-039], the shape this design refuses elsewhere.
V87. **Removing the duplication needs no vocabulary.** [D-145] (bold)
V88. Declaration bodies are ordinary code (§8.5), so the author writes the feed list once and both declarations compute their share.
V89. In the block, `Systems` holds an actuator child `act` whose output faces feed its `aero` and `ldg` children.
V90. Code: `ACT_FEEDS` (~10 entries for the C172X), `fed_faces`, `inner_connections(::Systems)`, `u_connections(sys::Systems)` with `except = fed_faces(...)`.
V91. Adding an actuator channel is then one edit. [D-145]
V92. The new pair simultaneously creates the wire and removes the face from the input face surface.
V93. The two declarations cannot drift, because neither holds the shared names.
V94. Both are projections of the authored list, so the drift class is removed rather than detected.
V95. Every misspelling stays loud: a mistyped destination is an unknown-face error with the child's face list in hand, whether the wire or the `except` entry meets it first.
V96. A pair omitted from the list is not an error but a structural change (stated openly as an asymmetry).
V97. The face leaves the `except` set and joins the input face surface, ultimately a root input for conditions to cover (§14.6).
V98. What the idiom preserves, and the helper below surrenders, is that the feed statement exists to be reviewed.
V99. An omission is legible in one authored artifact, not defined away as the complement of the wire list.
V100. The line not to cross is deriving `except` from `inner_connections` itself.
V101. A helper `except = fed(sys, "aero")` reading the assembly's own wire list would cross it; that is auto-bubbling under another name. [D-043, D-145]
V102. **The single source must be authored data, never inferred structure.** [D-145] (bold)

### Generic holding
V103. **Generic holding is an imposed derived contract.** [D-043] (bold)
V104. A parent holding a child generically constrains it exactly through the faces its wires and interface connections reference.
V105. Build a `World` whose concrete aircraft lacks a referenced face, and the error names the `World` entry.
V106. That is build-time structural typing with no new vocabulary.
V107. A formal required-faces declaration on domain abstract types remains possible sugar. [D-251]
V108. Scalar faces make partial scripting compose. [D-207]
V109. A guidance scenario component (home of a sim-time script) wires two of the faces, `mode_req` and `EAS_ref`.
V110. The remaining faces stay exported for GUI or defaults.
V111. That is impossible with a bundled face, under the write-side rule of §4.3.
V112. Unit ends with `---`.

Bold count: 7 (V10, V53, V56, V69, V87, V102, V103).
