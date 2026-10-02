# Unit A, phase 1 (blind assertion list from new.md)

Chapter opening
- V1. The chapter fixes where data lives, on both tiers and outside them.
- V2. It fixes the homes the declared state occupies and how each home holds its values.
- V3. Continuous state is an immutable value over a flat buffer the framework owns.
- V4. The continuous path is generic over its scalar type.
- V5. Discrete state and modes live in stores.
- V6. Scratch lives in a workspace.
- V7. The allocation policy those choices make possible closes the chapter.
- V8. Section map: §7.1 continuous state, §7.2 numeric genericity, §7.3 discrete state/modes/workspace, §7.4 fused-evaluation lineage that led to §5.2's interfaces, §7.5 allocation policy.

§7.1 lead-in
- V9. A continuous component is the hybrid primitive, with continuous state, flow and events (glossary link).
- V10. Section roadmap (closed vocabulary, three things, buffer/views, why closed, shape of Ẋ, gains vs FlightCore's mutable-view pattern).

Vocabulary
- V11. Each continuous component declares its state by value (`x_init`). [§8.2, D-033]
- V12. The declaration is a NamedTuple. [D-247]
- V13. (bold) Leaves are drawn from a deliberately closed vocabulary: plain real scalars and SArrays of a common eltype `T`, nothing else. [D-094]
- V14. Ints, enums, Bools belong in modes.
- V15. Domain wrapper types are not state leaves.
- V16. RQuat is a rotation quaternion type with a `normalization` keyword; Ranged is a clamped scalar.
- V17. An attitude state is an SVector{4,T}, cast where rotation semantics are wanted.
- V18. The structure step refuses a field outside the vocabulary as IllegalStateLeaf. [§9.1]
- V19. Its messages are listed in §8.2. [§8.2]

Flatness
- V20. (bold) The declaration is flat. [D-094]
- V21. Each field is one leaf, never a NamedTuple of leaves.
- V22. The condition algebra and readers address a field as one leaf. [§14.3, §14.4]
- V23. Structure comes from the component tree, not from the value.

Three things
- V24. The framework computes a flat layout at build time with compile-time offsets into one contiguous Vector{T} the framework owns (the buffer).
- V25. It reconstructs the typed immutable state value for a component at each evaluation.
- V26. It passes that value to every function receiving state views, under §5.2's argument rule. [§5.2, D-035]
- V27. Reconstruction is field loads at known offsets, register-level, zero cost.
- V28. Derivative functions return an Ẋ-typed value, scatter-stored into the flat ẋ buffer.
- V29. A handler's `x` key and the projection (optional hook x_projection) carry a new X, written back.
- V30. Projection's write-back happens at the two positions in §5.3's execution order. [§5.3, D-111]

Buffer
- V31. (bold) The buffer is authoritative; typed values are ephemeral reconstructions. [D-010]
- V32. Nobody outside the framework ever holds a mutable reference to state.
- V33. "Ephemeral" is literal: an isbits view materializes in the caller's frame for exactly the duration of the call, no existence between calls.
- V34. Where it materializes (registers / spilled stack) is the compiler's business.
- V35. Re-materializing is the same loads.
- V36. It is value-identical because the value is immutable and the buffer is unchanged within a sweep (one pass through the execution order).
- V37. The buffer-unchanged-within-a-sweep rule is exactly the legality condition of the codegen's CSE, which hoists repeated reads of views rebuilt per call. [§9.7, D-288]

One home
- V38. The complementary rule is one home per datum (each datum has exactly one home), stated in §5.2. [§5.2, D-035]
- V39. No state cells in the signal table beyond the declared ports a component returns from y_state. [§5.3, D-252]
- V40. Those ports are interface, not transport.

Why closed
- V41. The vocabulary is closed because views must materialize without running anyone's invariants.
- V42. Scalars and SArrays have invariant-free constructors.
- V43. SVector's constructor stores its tuple; NamedTuple construction runs no user code; nothing normalizes or clamps.
- V44. Therefore building a view through ordinary public construction is bit-faithful automatically.
- V45. reconstruct(flatten(x)) == x holds identically, with no constructor bypass, no reinterpret, no reliance on custom struct layout mirroring the buffer.
- V46. Invariant-carrying leaves are excluded from the vocabulary. [D-094]

Cast
- V47. Domain semantics are an explicit, invariant-free cast at point of use.
- V48. It is the conversion f_ode! (FlightCore's in-place derivative function) performs on its raw views.
- V49. Invariants live in x_projection at boundaries and in writers ("where the design already put them").
- V50. Handlers build returned values through ordinary constructors.
- V51. The condition apply converts authored values through ordinary convert methods. [§14.3]
- V52. Constructors run on the write paths, never on views.

Shape of Ẋ
- V53. With the vocabulary closed, the shape of Ẋ takes one line to state.
- V54. Ẋ has exactly X's shape at the activation scalar (the scalar type T an activation is built at).
- V55. Scalar leaf's derivative is a T; SArray leaf's is the same SArray at T.
- V56. This is what the closed vocabulary buys.
- V57. An invariant-carrying leaf like a unit quaternion has a derivative off its own type, so Ẋ would need a separate derivation.
- V58. Here the attitude leaf is SVector{4,T}, and so is its rate.
- V59. The conformance predicate is structural: each field of x_deriv's return scatters into its field's block at T. [§9.5 states the check]
- V60. That makes derivative completeness a property of the layout rather than author discipline.
- V61. There is deliberately no derivative_type hook. [D-190]

Versus FlightCore
- V62. FlightCore's pattern was a flat Vector read through ComponentArrays views, mutable views into the flat vector.
- V63. Design buys five things against it.
- V64. No aliased mutable views where who writes what is convention.
- V65. Derivative completeness is structural: returned Ẋ has every field by construction; a forgotten ẋ entry is impossible rather than silently stale.
- V66. State fields arrive as declared scalars and SArrays, immutable; the domain wrapper is one explicit invariant-free cast (RQuat(x.q, normalization = false)).
- V67. That cast is the conversion the mutable-views pattern performed implicitly, now visible and chosen.
- V68. The flat vector still exists; integrator compatibility (OrdinaryDiffEq or custom), trim solvers, HDF5 logging, linearization get their arrays.
- V69. FlightCore's hand-written per-aircraft state-space mapping functions (get_x_ss/assign_x_ss!/get_u_ss/...) are deleted, replaced by the canonical layout. [D-072]
