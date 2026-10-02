# Unit C phase 1 (blind assertion list from new.md)

V1. Two homes sit outside the continuous buffer; the buffer is the contiguous vector backing all continuous state. (glossary)
V2. The rules of the two homes are opposites.
V3. Discrete state and modes are state in the full sense.
V4. They are values whose fields are isbits or Symbols.
V5. The framework owns them.
V6. A checkpoint copies them wholesale.
V7. A workspace is mutable scratch, deliberately not state at all.
V8. A workspace is governed by contract rather than by checks.
V9. s and m stores are the framework-owned homes of those letters. (glossary store)
V10. [pointer] Section order: store rules, workspace rules, idioms.
V11. BOLD: Discrete state (a discrete leaf's s) and modes m live in typed stores, apart from the buffer holding x. [§7.1, D-013]
V12. The framework overwrites an s or m store when an update or handler returns a new value.
V13. s/m stores keep the same immutable-value discipline as the table's cells, in a separate home.
V14. §4.1 vocabulary never counts a store as a cell. [§4.1, D-302]
V15. s and m stores never touch the integrator buffer.
V16. No arithmetic is ever done on them.
V17. BOLD: Every field of an s or m store value is isbits or a Symbol. [D-231]
V18. Isbits = immutable value holding no references, transitively.
V19. Enums, integers, Bools, SArrays, nested isbits structs qualify.
V20. String, array, or struct holding either does not qualify.
V21. Symbol admitted as the idiomatic label.
V22. Symbol is interned, immutable, never freed; so it copies as a pointer to permanent data and serializes as its name.
V23. The table admits Symbol on the same grounds, as an opaque leaf. [§4.3]
V24. A struct nesting a Symbol does not qualify.
V25. The structure step checks every s_init and m_init field and reports violations as IllegalStoreField. [§9.1, App C, D-231]
V26. The rule rests on what state is: state is what changes between ticks (tick = instants a discrete component runs).
V27. Bulk data and labels do not change between ticks; their home is the component instance.
V28. BOLD: The frozen-reference latitude stays with signals. [§4.1, D-231]
V29. The latitude exists for field handles [§4.4]; no store needs it.
V30. Isbits makes the rest of the section literal: copying an s/m store copies bits.
V31. Therefore checkpoint and replay (ordinary loop re-driven from the trace) of the entire discrete side is "copy the store values".
V32. A stored value has one fixed layout per component.
V33. Double-buffered mutable state is a possible future extension only, deferred. [D-013]
V34. A workspace serves heavy algorithms such as an n≈20 Kalman filter.
V35. A workspace is component-declared mutable scratch, instantiated by the framework. [D-013]
V36. It arrives as the ws field of the bundle (NamedTuple of zero-copy views) in every bundle-receiving function of the declaring component. [§5.2]
V37. x_projection is positional and receives none. [D-074]
V38. A workspace is excluded from state semantics: not snapshotted, not replayed, never a condition target. [§14.1]
V39. It must carry no information between calls. [D-183]
V40. BOLD: The framework never inspects or mutates a workspace. [D-183]
V41. Workspace is an opaque, opt-in escape hatch from value semantics, used at author's own risk.
V42. Its rules are contract, not checks.
V43. At call entry, contents unspecified beyond structure the allocator established.
V44. A plan or factorization configured at allocation is valid from then on.
V45. Scratch is garbage until written this call; nothing a previous call left may be relied upon.
V46. No poisoning of scratch is attempted.
V47. BOLD: A workspace is declared by allocation. [D-077]
V48. The well-known method is the allocator (code example KF).
V49. BOLD: ws_init(::C, ::Type{T}) takes the activation scalar on both tiers (continuous and discrete). [D-263]
V50. It is the one declaration that does. [D-263]
V51. A discrete allocator receives Float64 at every activation, because the discrete tier never runs at another scalar. [§9.4]
V52. x_init, s_init, m_init and the contracts take the component alone on every tier.
V53. Nothing in the workspace contract is tier-specific.
V54. A continuous workspace simply joins the T-generic surface.
V55. Under a Dual activation the allocator is called at Dual; in-place math runs through Julia generic fallbacks; no BLAS.
V56. Activations probe and linearize; they don't run marathons.
V57. State and cells re-scalar through the walk [§7.2], so those declarations never need T.
V58. Scratch is allocated, not retyped; a factorization/plan/buffer sized by the scalar has no rebuild the framework could perform.
V59. So eltypes can come only from the allocator's own argument. [D-077, D-263]
V60. Allocator called once per activation (build's typed products at a given scalar type) and once per scratch-store set. [§14.8, D-077]
V61. Sizes come from the instance, eltypes from the activation.
V62. Nothing downstream derives from a workspace's type.
V63. Mistyped scratch detonates loudly at the Dual probe (build's single evaluation of a user function).
V64. The undef spelling is the recommended idiom and sole visible marker that contents are meaningless; it puts that fact in the declaration.
V65. That is the by-allocation convention this declaration lives in.
V66. Declaration is by allocation, never by initial value. [D-077]
V67. The init in ws_init means establish, as the device contract's init! does. [§11.6]
V68. It carries no claim that allocated contents are a value. [D-220]
V69. The continuous side runs many calls per boundary (published consistency point): RK stages, localization trial evaluations, event re-sweeps.
V70. That multiplicity makes the no-information-between-calls contract more essential there, not less.
V71. Blessed (explicitly sanctioned) idiom for zero-allocation ticks with immutable s: in-place math (mul!, cholesky!, BLAS) on the workspace. [D-013]
V72. At the end, snapshot into an isbits container and return it (KFState example).
V73. BOLD: in the blessed PRNG idiom, a generator object (Xoshiro) lives in the workspace; values that determine its next draw are state in s. [D-231]
V74. Generator is mutable, so scratch, allocated once.
V75. Values are immutable, so they are state.
V76. Keeping them in s is what makes replay deterministic. [§2.2]
V77. The tick loads them into generator at entry, snapshots back at exit, same shape as Kalman idiom. (code block)
V78. Rematerializing the generator each tick reads naturally and allocates.
V79. A sampler with an out-of-line tail lets the object escape. [D-231]
V80. Construction and storage of large SArrays are cheap and compile fine.
V81. StaticArrays "codegen catastrophe" lives in its operations (unrolled matmuls), never called on snapshots.
V82. Discipline: snapshot values are for storage, logging, element access only, never arithmetic.
V83. Optionally enforceable by op-forbidding ValueSnapshot{N,T} wrapper: NTuple with only getindex and iteration, structurally SArray minus methods.
V84. Practical ceiling: a few KB comfortable, tens of KB defensible; beyond that value semantics stop making sense.
