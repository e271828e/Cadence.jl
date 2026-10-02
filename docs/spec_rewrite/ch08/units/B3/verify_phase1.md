# B3 verify, phase 1 (blind read of new.md)

V1. `y_types` declares the public port contract, by type.
V2. Like `u_types`, it is written at nominal `Float64`.
V3. Like `u_types`, it takes the component alone on both tiers.
V4. Like `u_types`, it is walked on the continuous tier.
V5. The input side is read permissively; this side is read literally.
V6. An entry states what the cell carries, not what it tolerates.
V7. Continuous producer spelling example: `y_types(::Engine) = (M_shaft = Float64, P = Float64, ω = Float64)`.
V8. Cell types at an activation are the declaration retyped at the activation's `T` by the leaf walk. [D-079, D-263]
V9. On a discrete producer the same spelling pins wholesale.
V10. That is the discrete exemption, enforced by tier. [§7.2]
V11. The leaf's tier decides which reading applies, never the contract's shape.
V12. The tier is declared by the leaf's store (above and below).
V13. Semantics are literal once the walk has run; the cell type is the retyped declaration, nothing inferred.
V14. Participation is therefore authored per leaf and legible on the page.
V15. `Float64`, alone or as a type parameter (`SVector{3, Float64}`, `RQuat{Float64}`, `MyStruct{Float64}`), means the leaf participates. [D-263]
V16. Its cell carries the activation scalar.
V17. Value parameters are structure, not number, and never take the activation scalar. [D-079]
V18. The bounds in `Ranged{Float64, -1, 1}` are not scalars to re-type.
V19. `Pinned{P}` means the leaf is deliberately pinned; the pin is schema-visible.
V20. The wrapper is stripped at nominal, so the cell is `P` at every activation.
V21. It is whole-leaf freezing, declared and conformance-checked.
V22. That delivers the recorded freeze door. [§14.10]
V23. Declare `Pinned{Float64}` and strip with `ForwardDiff.value` inside the stage. [D-286]
V24. The stop-gradient is then stated in the contract instead of buried mid-expression.
V25. The marker sits at the top of the entry and nowhere below it. [D-265]
V26. `Int`/`Bool`/enum leaves and reference-typed fields pin. [D-079]
V27. The grid of a bulk-data handle [§4.4] is frozen build-time data, never activation-dependent.
V28. The walk never reaches the grid, because references are fields and the walk substitutes type parameters alone.
V29. A handle carrying a scalar parameter walks like any type. [D-237, D-263]
V30. A handle built from build-time data is declared `Pinned`. [D-237, D-263]
V31. A mutable type's parameters pin by rule. [D-263]
V32. No stage can produce a `Vector{Dual}` inside a handle without copying the grid at every evaluation, so there is no choice for a marker to record.
V33. BOLD: A handle keeps its bulk at `Float64` and its activation-dependent part in the parameter. [D-263]
V34. The rule reads off the shape: references are fields, so a grid typed `Matrix{Float64}` stays frozen at every activation, and a pose typed `T` follows the scalar.
V35. `DeckField{T}` sketch: `heave::T`, `pitch::T` (pose follows scalar), `grid::Matrix{Float64}` (frozen, never re-typed).
V36. Inside a query nothing converts the grid; each grid-entry times `Dual`-weight product promotes on its own.
V37. The query result therefore carries the pose's partials and the interpolant's slope, while the grid is read as loaded.
V38. A `Matrix{T}` grid would give the same numbers at the cost of a copy per evaluation.
V39. That copy is the one the mutable-parameter rule refuses.
V40. The producer pins the handle when built from build-time data alone (static terrain).
V41. It leaves the handle walking when its parameters come from state (moving deck).
V42. A field that must never follow the scalar is typed concretely in its struct (`b::Float64` beside `a::T`), which freezes it for every user of the type.
V43. The marker pins a whole leaf; a pin on one parameter of one declaration is not offered. [D-265]
V44. The rule "every `Float64` position follows the scalar" reads the declaration as written, so a concretely typed field is frozen without appearing in the contract. [D-265]
V45. Companion `handle_walk_walkthrough.md` works a static terrain and a moving deck through one consumer.
V46. A custom struct is a first-class port type (e.g. `contact = GearContact{Float64}`) under the scoping §7.2 establishes. [§7.2]
V47. That scoping requires a struct parametric in its real-scalar leaves, with constructors inferring the scalar.
V48. A participating struct leaf is declared with `Float64` in its parameter position.
V49. The walk retypes it there, recursively for nested parameters. [D-263]
V50. A struct with a hardcoded `Float64` field offers no such position; the walk leaves it as written, a pinned leaf by shape.
V51. `Pinned{GearContact}` says so on the page.
V52. Any `Dual`-carrying construction then fails inside the stage with an `InexactError` naming the offending constructor.
V53. That is the CI invariant of §7.2, reached through the declaration layer with no extra machinery. [§7.2]
V54. The companion obligation is constructibility at `T`.
V55. BOLD: A declared type must be buildable at the activation scalar. [D-079]
V56. The `Dual` probe enforces it by construction.
V57. The probe builds real values, so a type whose constructor cannot accept them fails at the probe with its own name in the message.
V58. During a generic sweep, gated-off discrete producers hold their `Float64` values.
V59. Consumers gather mixed tuples, and promotion does the rest.
V60. That is semantically exact. [D-079]
V61. A frozen discrete output is a constant with zero partials.
V62. That is precisely what "linearize the continuous dynamics with the discrete state held" means.
V63. The frozen cell is not an AD limitation on the signal path; it is the true zero of an instantaneous dependence the hybrid semantics never had. (`frozen_discrete_walkthrough.md`)
V64. The embedding guarantee [§9.5] makes the mixing safe.
V65. The embedding guarantee is keyed on walking leaves. [D-238]
V66. A `Float64` observed at a walking leaf under a non-nominal activation implies no `Dual` entered its computation.
V67. Reason: promotion is airtight and there is no lossy cast.
V68. Its true derivative along every seeded direction is therefore zero, and embedding it as a zero-partial constant is exact.
V69. Piecewise branches returning literal constants (`flow > 0 ? f(x) : 0.0`) are legal as written, because zero partials are the derivative of a locally-constant branch. [D-194]
V70. Which invocation carries partials is chosen by seeding [§14.10], never by typing. [D-079]
V71. The declaration says which leaves can carry partials; the seed says which directions do.
V72. A leaf that really participates cannot be declared frozen by habit, because the habitual spelling, bare `Float64`, walks. [D-263]
V73. What remains is deliberate: writing `Pinned` at a leaf that really participates, or omitting it at one that does not.
V74. BOLD: The first bug lurks, but is never silent. [D-286]
V75. No lossy `Dual → Float64` cast exists, so the first `Dual` activation of that component fails.
V76. It fails at that activation's own lazy compile [§9.4], not at `build(world)`.
V77. The message carries the hint "if `F` participates in differentiation, remove its `Pinned`".
V78. Because an observed `Dual` at a pinned leaf has exactly one honest cause.
V79. The second bug fails at the same activation.
V80. It fails inside the stage where frozen internals meet a `Dual`, or at the identity comparison on an opaque leaf built from build-time data. [§9.5]
V81. Both lurks are contained by policy rather than machinery.
V82. The test suite builds a `Dual` activation of every component. [D-280]
V83. That is the exhaustive set that §9.4 defines. [§9.4]
V84. An activation is derived from the nominal one.
V85. It is cheap enough to make this policy unremarkable in CI.
V86. What the plain form buys in exchange is one convention: every declaration in the framework is read with the same walk rule. [D-263]
V87. A genuinely frozen leaf still says so on the page. [D-263]
V88. The stores are walked by the same rule, with no marker. [D-263]
V89. The type derived from `x_init` is walked; real leaves and `Real` type parameters follow the activation scalar.
V90. `m_init` and `s_init` pin wholesale, mirroring the discrete-producer rule.
V91. `Pinned` has no place in a store, because §7.1 admits no pinned state leaf for it to mark. [§7.1]
V92. Declared `Float64` initial values embed as zero-partial constants under non-nominal activations. [D-079]
V93. That is the rule for `Float64` condition leaves [§14.3] applied to the defaults those conditions overlay.
V94. Walking `x_init` presupposes the closed leaf vocabulary §7.1 fixes: scalars and `SArray`s at the common eltype. [§7.1, D-094]
V95. On the discrete tier, the stores answer to the isbits rule of §7.3, checked field by field. [§7.3, D-231]
V96. The structure step checks both vocabularies. [§9.1]
V97. It reports failures in the didactic style.
V98. Message: "`x_init` field `gear_count::Int` is not a continuous state — integers, `Bool`s and enums belong in `m_init`".
V99. Message: "`x_init` field `q_nb::RQuat` is not a state leaf — declare the `SVector{4}` backing and cast where rotation semantics are wanted (§7.1)".
V100. Message: "`x_init` field `pose::NamedTuple` is not a state leaf — a field is one scalar or `SArray`; split it into fields, structure comes from the component tree (§7.1)".
V101. Message: "`s_init` field `label::String` is not a store value — store fields are isbits or `Symbol`s; text and bulk data belong on the component instance (§7.3)".

Bold spans: V33, V55, V74 (three).
