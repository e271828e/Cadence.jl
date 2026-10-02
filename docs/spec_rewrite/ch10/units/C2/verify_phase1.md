# C2 verify, phase 1 (blind read of new.md)

## The two declaration forms
V1. A discrete component or sub-assembly is scheduled by a `sample_times` entry in its enclosing assembly. [§8.7]
V2. (bold) The entry declares one (period, phase) pair in one of two unit systems. [D-185]
V3. The wrapper type names the unit system. [D-185]
V4. The two forms declare one concept, a sample time, in different units.
V5. Table: `Relative(K, Φ = 0)`: unit system scope ticks; ticks every K-th tick of the enclosing scope starting from its Φ-th; constraints K ≥ 1, 0 ≤ Φ < K.
V6. Table: `Absolute(q, τ = 0)`: seconds; ticks at t = τ + k·T, T = period(q); constraints T > 0, 0 ≤ τ < T.
V7. K = 1 admits no stagger ("therefore", from the table constraints). [D-185]
V8. Two same-rate siblings are staggered one level down instead: declare the scope at twice their rate, give them Relative(2, 0) and Relative(2, 1).
V9. `q` is a quantity value, `Period(1//50)` or `Hz(50)`.
V10. The two spellings are a spelling choice, normalized to the rational period at construction.
V11. Every period and offset is an exact `Rational{Int}`.
V12. Reason for V11: grid derivation is GCD arithmetic and ill-defined over floats.
V13. A float argument throws the teaching error naming the exact spelling (`Period(1//50)`, or `Hz(1//2)` for 0.5 Hz).
V14. The wrappers are the whole vocabulary. [D-185]
V15. A bare integer or bare quantity is a declaration error.
V16. An unlisted discrete child defaults to `Relative(1)`.
V17. Consequence: the common case costs nothing, and a multiplied or anchored child always appears explicitly.
V18. Gloss: anchored child = one declared `Absolute`.
V19. (bold) Validation belongs to the structure step. [§9.1, §13.1, D-185]
V20. Gloss: the structure step is the build's declaration-reading step.
V21. The structure step collects validation errors with path attribution. [§9.1, §13.1, D-185]
V22. Validation covers K ≥ 1, 0 ≤ Φ < K, T > 0, 0 ≤ τ < T, and keys naming discrete or scope children.
V23. The constructors are plain data carriers with no checks of their own.

## Relative composition
V24. (bold) Multipliers compose multiplicatively and phases affinely down the tree. [D-019, D-185]
V25. Under a scope compiled to (D_s, Φ_s) in base ticks, child Relative(K, φ) compiles to D = K·D_s, Φ = Φ_s + φ·D_s. [D-019, D-185]
V26. Composition preserves the canonical residue 0 ≤ Φ < D.
V27. sample_time_proposal.md carries the one-line induction; gloss: it is the declaration design's worked companion.
V28. All scoping compiles away at build to one (D, Φ) pair per discrete component ("therefore").
V29. The boundary sweep gates on that pair with the `(tick − Φ) % D == 0` test "above".
V30. The lattice stays static.
V31. The interior sweep still holds no discrete entries to gate.
V32. Relative is the default form because in a layered control architecture the ratios are intrinsic to the design and travel with the assembly type.
V33. Example: inner loop at Relative(1), outer loops at Relative(5), whatever the deployment.
V34. One convention keeps K ≥ 1 livable: a scope's base rate is its fastest relative member, which gets K = 1. (plain, uncited)
V35. Two structural properties keep a relative entry on the scope grid and confine grid cost to the other form.
V36. (bold) A relative phase never refines the base grid, because it selects among scope ticks that already exist. [D-185]
V37. A relative phase cannot place a tick between scope ticks.
V38. Staggering off-grid means declaring the offset in seconds, or declaring the scope base finer than its fastest member so unused slots exist.

## Anchors
V39. (bold) An Absolute entry may appear in any scope's sample_times, not only the root's. [D-186]
V40. The (T, τ) pair it establishes is an anchor; the child hangs from it. [D-186]
V41. The child is severed from the enclosing scope's grid; no relation to the scope's ticks remains.
V42. Three corollaries follow. [D-186]
V43. K ≥ 1 reads "a child cannot tick faster than the scope it is relative to"; an anchored child may therefore tick faster than its scope.
V44. The fastest-member convention counts relative members only.
V45. Phase relationships between an anchored child and its relative siblings are deployment-emergent; coincidence depends on how grid derivation works out.
V46. The deployment's Schedule exists to answer that question. [§9.2]; gloss: Schedule is the per-component (D, Φ, Δt) table the Deployment carries.
V47. Relative children of an anchored subtree compose against the anchor exactly as against the root grid. [D-186]
V48. A nested anchor simply severs again (the fold). [§9.1]
V49. (bold) Absolute periods and nonzero offsets jointly constrain the base grid. [D-186]
V50. They join the deployment-time constraint pool. [§9.2]
V51. This is the subtle part, with a real cost: an offset of T/2 can cost a 2× finer grid, T/1000 a 1000× one.
V52. The cost is relational, incurred against everything else declared.
V53. That is why attribution is the engine's job. [§9.2]

## When an anchor belongs in a library type
V54. Absolute-first declaration as the default form is rejected. [D-019, D-186]
V55. What mid-tree anchors legitimize is narrower; the doctrinal line falls here.
V56. (bold) An absolute declaration inside a library type is legitimate when the rate is a fact about the modeled system, not a preference about the simulation. [D-186]
V57. Examples: GPS receiver at 1 Hz, a bus schedule, an ADC (analog-to-digital converter) pipeline's fixed conversion offset are as intrinsic as the wiring.
V58. Forcing them to the root breaks encapsulation, since the root would have to know instrument internals to re-declare them.
V59. "Run the controller at 400 Hz in this study" remains a deployment choice; the existing idiom (multiplier as constructor parameter) remains its answer.
V60. Absolute pinning from outside a subtree's contract stays rejected as action at a distance; gloss: contract = its declared interface.
V61. The framework cannot police the distinction; it is authoring doctrine, recorded here.
V62. (bold) Anchoring leaves the never-cache-Δt argument below fully intact. [D-186]
V63. Pinning happens in the enclosing assembly's sample_times, the same site where the multiplier lives.
V64. The component type therefore stays rate-agnostic and still consumes its bundle's Δt.
V65. Gloss: bundle = the NamedTuple of zero-copy views a component function receives.

## A worked example
V66. Example: three discrete components under two scopes, deployment binding Δt_base = 2 ms. [§9.2]
V67. Root holds fcs, a flight control system (FCS) scope, and gnss, a satellite-navigation (GNSS) component.
V68. Code block: Vehicle root (1,0); fcs Relative(1) → (1,0); gnss Absolute(Hz(50)) → (10,0) anchored at T = 20 ms; FCS children inner Relative(1) → (1,0), outer Relative(5,2) → (5,2).
V69. Those pairs are what the boundary gate reads at run time.
V70. One hyperperiod is lcm(Dᵢ) = 10 base ticks.
V71. Because the gate is pure modulo arithmetic, one hyperperiod is the complete truth rather than a sample. [§9.2]
V72. Chart of ticks 0..9 for inner, outer, gnss.
V73. outer due where (k − 2) % 5 == 0, gnss where k % 10 == 0.
V74. If outer reads a gnss cell, ZOH makes the read two base ticks old at k = 2, seven at k = 7.

## Coincidence and stagger
V75. Coincidence and stagger are modeling choices with observable consequences.
V76. Coincident ticks give fresh same-instant reads via topological order; the idealized synchronous-sampling picture.
V77. A phase stagger makes those reads pipelined and deterministically aged; the structural expression of an acquisition pipeline's latency, with no delay blocks.
V78. The two-tick and seven-tick reads above are the deterministic aging of a stagger.
V79. A stagger is also a load-shaping tool under real-time pacing; gloss: pacing = waits inserted between completed frames, never altering the boundary sequence.
V80. Staggered stacks never share a frame, so worst-case frame cost is a max rather than a sum. [§10.7]
V81. Both patterns are worked in sample_time_proposal.md, with how silently an offset edit rewires a coincidence structure.
V82. The Schedule and its hyperperiod chart are how a user audits which pattern a model has. [§9.2]

## Δt in the bundle
V83. Δt has a single source of truth, the deployment's Schedule. [D-187, D-254]
V84. (bold) Each discrete component's effective period arrives read-only as the Δt field of every discrete-tier bundle. [§5.2, D-019]
V85. The field arrives in y_state, y_direct and s_update alike.
V86. It is absent from continuous bundles, so touching it on the wrong tier is a missing-field error rather than a rule.
V87. The field must be readable in the stages, not just s_update.
V88. The discretized laws that consume Δt run in y_direct, which computes each law once and publishes it. [§5.3, D-015]
V89. Examples: a PID's backward-difference coefficients, a LeadLag's Tustin transform.
V90. s_update is a copy.
V91. The value must arrive through the call; the bundle field is where it arrives.
V92. A comp.Δt virtual property is impossible here, not merely inconvenient. [D-019]
V93. (bold) An author must never store Δt or a Δt-derived coefficient as a component parameter. [D-019]
V94. Recomputing derived coefficients per tick is a few arithmetic ops; a cached copy is a second thing for gain-scheduling machinery to chase.
V95. Relative declaration structurally enforces that rule for the period itself.
V96. Under scoped multipliers an author cannot know their absolute rate; it does not exist until composition.
V97. Phases change none of this.
V98. (bold) The bundle's Δt is still D·Δt_base. [D-185]
V99. An offset shifts firing instants and never the period, so discretized laws are unaffected by staggering.

Bold count: V2, V19, V24, V36, V39, V49, V56, V62, V84, V93, V98 (11). D-185 headlines: V2, V19, V24 (shared with D-019), V36, V98 = 5. D-186: V39, V49, V56, V62 = 4.
