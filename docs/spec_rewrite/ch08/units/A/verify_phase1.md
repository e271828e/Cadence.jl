# ch08 unit A — verify phase 1 (blind read of new.md)

Intro
- V1. Chapter 8 says how an author spells a component.
- V2. It covers where structural facts live, what the build takes as authoritative, what is checked against what.
- V3. §8.1–§8.4 cover the component side; §8.5–§8.8 the assembly side.
- V4. §8.1 lays the foundations of the declaration layer.
- V5. §8.2 lists the declaration inventory.
- V6. §8.3 says what a contract makes visible.
- V7. §8.4 gives the five failure walkthroughs that ground error locality.
- V8. §8.5 covers assembly declaration and how a type's class is read.
- V9. §8.6 covers paths, wiring and faces.
- V10. §8.7 covers rate scopes.
- V11. §8.8 covers computed connections and generic holding.
- V12. The build pipeline is §9; stopped-sim service spellings are §14.
- V13. Concrete syntax is near-final in shape, still illustrative in spelling.

§8.1 Position
- V14. A component is authored in ordinary Julia.
- V15. Its stage functions are ordinary multiple-dispatch methods.
- V16. They are `y_state` and `y_direct`, the two output stages every component provides on either tier.
- V17. Tier = continuous or discrete side of the hybrid formalism.
- V18. The methods follow the `GUI.draw!` precedent, per-component panel extensions in FlightCore's style (§11.7).
- V19. Structural facts are declared through a small set of well-known functions returning plain values, defined alongside those methods.
- V20. Five questions are settled, one per subsection: macros, schema, type, namespace, names (with their glosses).

Macros
- V21. **There is no macro DSL** [D-032].
- V22. The debugging, tooling and comprehension criterion (§1) decides it.
- V23. Redundancy between declarations and function bodies is accepted deliberately, under one non-negotiable condition.
- V24. Every inconsistency fails loudly, at build time where possible and at first execution otherwise [D-032].
- V25. **A convenience macro remains addable a posteriori** as pure sugar, on the `@kwdef` precedent, never essential [D-032].
- V26. Reason: a macro can only ever lower to a layer like this one.
- V27. A macro generating the well-known declarations is admissible sugar on top of plain-Julia forms; never a replacement, never required [D-032].
- V28. Every rule in this part is stated over the generated methods, so a lowering macro adds convenience and no semantics.

Schema
- V29. **Declarations define the model's structure** [D-032].
- V30. Evaluation checks conformance against them, never the reverse.
- V31. The build probes user functions with real values, no reliance on compiler inference, and compares observed against declared.
- V32. The same comparison runs on every subsequent evaluation for free, as a NamedTuple-type check that constant-folds away when conformant.
- V33. Inference-by-evaluation as schema authority is rejected on three counts, established by walkthrough (§8.4), litigated in D-032.
- V34. "Types come by declaration, values by execution, and conformance by comparison."

Type
- V35. **A leaf's contract declarations must be determined by the component's type**, type parameters included, never field values [D-033].
- V36. Those declarations are u_types, y_types, state_events, and the shapes of x_init/s_init/m_init.
- V37. `u_types(::Engine)` value-discarding signature is the visible form of the rule.
- V38. Idiom for a genuinely varying contract is the type parameter: SumJunction{Wrench,3} (§6.2), Or{N} (§13.7).
- V39. Arity is spelled in the type, at a price §6.2 states.
- V40. The entry typing decides it (§9.7).
- V41. A bundle is the NamedTuple of zero-copy views a component function receives; its key set is its contract's.
- V42. An executor entry (executor = compiled form of stage execution order) carries code-selecting things in type params and plain data in fields.
- V43. A field-value-derived key set would either climb into type params (multiplying specialization, changing the chunking cost model §9.7) or sit in fields (dissolving static typing that zero runtime graph logic §5.1, allocation invariant §7.5, fold-away conformance test §9.5 rest on).
- V44. Chunking = splitting a large phase body into statically typed chunks.
- V45. The build reads each declaration once, against the concrete instance, so a value-dependent contract does not announce itself.
- V46. This is a rule authors keep, not a check the build can run.
- V47. ws_init is the one explicit exception [D-033].
- V48. It is the by-allocation convention [D-077], an allocator the framework calls, not a schema it walks.
- V49. It legitimately takes sizes from the instance (ws_init(c::KF, ::Type{T}) reads c.n, §7.3), because no entry type is derived from it.

Namespace
- V50. **The framework's extensible functions are extended, not called** [D-117].
- V51. Authoring a component means adding methods to framework-owned generic functions.
- V52. Julia admits that only via explicit per-name import or qualified `Cadence.x_deriv(…) = …`.
- V53. The qualified form is the Base.show idiom that the exported-name audit in pending.md records for the extension-only periphery surface.
- V54. A component module therefore opens with the 17-name import list (listed).
- V55. `using Cadence` alone is a silent trap: after it, `x_deriv(eng::Engine,…)=…` defines new unrelated MyModule.x_deriv, no error/warning.
- V56. Declarations are deliberately unexported [D-117].
- V57. Hence bare using brings no name to clash with; nothing for the language to detect.
- V58. Left alone, build would see no x_deriv method and report modeling diagnostic StoreWithoutUpdate (non-empty store without update law, §8.2).
- V59. When the whole inventory was shadowed, it would report ClassUnreadable (§8.5).
- V60. One-line namespace mistake reported far from its line: the inversion of error locality that §8.4 traces, via the namespace.
- V61. Error locality = a mistake fails at its site.
- V62. Two mitigations, both normative.
- V63. First: the import list is authoring surface, stated wherever a component file is first shown [D-117].
- V64. **The structural walk runs the shadowing check on every component before its class is read** [§9.1, D-246].
- V65. The check looks for a binding of a family name (name in the import list) in the component's parent module.
- V66. **If distinct from the framework's function, the build throws DeclarationShadowed alone** [D-246].
- V67. Diagnostic names module, foreign names, missing import; message text quoted.
- V68. The check is a two-line isdefined/!== test.
- V69. Names distinctive by design [D-220], so a foreign binding is evidence of missing import, not coincidence.
- V70. Throws alone because nothing the module declares can be trusted; walk past would report cascades of the one cause.
- V71. Runs on every component because optional declarations (state_events, sample_times) have no absence to notice; shadowed, they drop features silently.
- V72. A convenience macro expanding to the import list remains addable a posteriori as sugar.
- V73. A re-export submodule is not an alternative [D-117].
- V74. Local-scope sibling trap [D-164]: in let/function body/@testset, `y_state(::MyComp,(;x))=…` binds a new local function, not a method of global y_state.
- V75. Calls within block resolve to it and look correct; the build's generic function never learns of the component, which reads as declaring nothing.
- V76. Code example illustrating it.
- V77. The shadowing check cannot reach this case: no parent-module binding; local binding disappears with block.
- V78. **A component that declares nothing and defines no stage is rejected at build time** [D-164], because an inert component is unwritable on purpose.
- V79. The refusal is ClassUnreadable (§8.5).
- V80. That check costs a line and catches the misspelled-declaration family.
- V81. Test code is the realistic victim (fixture inside its own @testset).
- V82. **Declarations live at module top level** [D-164].
- V83. Net holds when only a stage is shadowed, because y_types is still a declaration; ports declared but stage local reads as "declared but not produced" (§8.3), not as nothing to say.
- V84. Port = declared, addressable name.
- V85. An optional declaration shadowed locally (state_events, ws_init) drops its feature silently [D-178].

Names
- V86. **Every name on the framework's surface belongs to one of four classes**; class fixes grammatical shape [D-144].
- V87. Declarations are noun phrases naming what they return, prefixed by the bundle field they define where one exists [D-267].
- V88. Assembly boundary declarations take u and y too; there the letter names a contract side, which on a leaf is also a bundle field [D-279].
- V89. Author defines declarations, framework calls them.
- V90. They include inner_connections, u_/y_connections, state_events, u_types, ws_init, stage and update-law names [D-220], and claims(b) from the binding interface (§11.6).
- V91. Binding = value passed at attach! that makes a device framework-legible.
- V92. Value selectors carry get_; called against reads and snapshots (immutable per-boundary publications, §14.4).
- V93. Lifecycle and mutating actions are verbs, with ! when mutating.
- V94. Build primitives are plain verbs (§13.3).
- V95. A wrong-class name is a rename candidate on that ground alone.
- V96. Semantic axis: a name can be in the right class but pick the wrong noun.
- V97. **A declaration names the consequence it has**, not its content [D-146].
- V98. input_passthrough (§8.8, D-171) and claims/reads (§11.6, D-146) apply that axis; exports is its retired exemplar [D-170].
- V99. The *_connections family names content deliberately, for authoring transparency; a recorded choice, not class drift.
- V100. Which names the module exports is separate, open until the exported-name audit in pending.md runs [D-226].
