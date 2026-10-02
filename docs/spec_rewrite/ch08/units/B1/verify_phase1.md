# ch08 B1 verify, phase 1 (blind read of new.md)

Code example (lines 3-45)
- V1. §8.2 opens with one continuous primitive (`Engine`) declared end to end.
- V2. Parameters are plain struct fields.
- V3. `ω_rated` is unread in the example; §14.2's shipped condition uses it.
- V4. State stores are declared by initial value; types derived, nothing to drift.
- V5. Example `x_init(::Engine) = (ω = 0.0,)`, `m_init(::Engine) = (phase = off,)` with phases off | starting | running.
- V6. Input contract: each entry states what may arrive; a Float64 leaf walks with the activation.
- V7. Output contract = the public interface (§8.3).
- V8. In `y_types`, Float64 walks; `Pinned{Float64}` would freeze a leaf.
- V9. Stage and update functions destructure their bundle by name (§5.2).
- V10. Exposing a state field is one line (§5.3).
- V11. Events are ordered and named; order matters (§5.3, §10.6).
- V12. Detection policy is chosen by the guard's return type (§2.1): Bool guard is boundary-detected; sign-form (continuous) guard is localized/localizable.
- V13. A manual trigger is an input (§12.5).
- V14. A handler returning no `x` key means no reset.
- V15. Predicate form guard (`ignition_guard`) vs continuous form guard (`flameout_guard`).

Lead-in and criterion (47-73)
- V16. The blocks below take the inventory declaration by declaration and record where each schema fact gets its authority.
- V17. BOLD: Every declaration of a structural fact but the allocator takes the component alone [D-263].
- V18. The criterion is the convention each declaration lives in; stated once here; blocks below refer back.
- V19. By-value declaration states nominal physics; its types walk by rule (gloss: derivation of per-activation types from a declared nominal type).
- V20. §7.1 forces every state leaf to follow the scalar of the activation (gloss: build's typed products at a given scalar type).
- V21. Therefore nothing is left for a signature to record (causal "therefore").
- V22. Partials enter through per-invocation seeding, never through initialization [D-079].
- V23. By-type declaration walks by the same rule.
- V24. Where a leaf must not follow the scalar, the author says so at the leaf with `Pinned` (gloss: leaf wrapper `Pinned{P}`, yields `P` at every activation).
- V25. That is why `u_types` and `y_types` take the component alone too.
- V26. By-allocation declaration is the exception.
- V27. It builds values the framework may not rebuild, so the scalar can come from nowhere but its own argument.
- V28. `ws_init(c, T)` takes T on both tiers, continuous and discrete [D-077].
- V29. `ws_init` allocates the workspace (gloss: component-declared mutable scratch arriving as the `ws` bundle field); described below.
- V30. The criterion, not uniformity, is the rule.
- V31. A `T` in a signature means the framework could not have supplied it.

The stores (75-136)
- V32. BOLD: `x_init` (continuous), `s_init` (discrete), `m_init` declare by initial value [D-033].
- V33. The type is derived from the value.
- V34. BOLD: The value is a NamedTuple, one named field per leaf; no other form admitted [D-247].
- V35. A bare leaf (`x_init(::C) = 0.0`, `s_init(::C) = zeros(SVector{3})`) is refused.
- V36. Structure step reports it as `StoreNotNamedTuple`; message spells the wrap [§9.1, App C, D-247].
- V37. BOLD: Every leaf declares exactly one of `x_init` and `s_init`; a stateless leaf declares it empty [D-263].
- V38. Display: `x_init(::Gain) = (;)`, `s_init(::Sampler) = (;)`.
- V39. The store (gloss: model's memory, declared by initial value) is the tier marker.
- V40. Therefore mandatory even when empty, exactly as `inner_connections` is mandatory even when empty because it is the class marker [§8.5, D-263].
- V41. A primitive declaring neither store is `TierUnreadable`; its message spells the empty form.
- V42. An empty store owes no update law (nothing to integrate or advance).
- V43. An empty store puts no letter in the bundle [§5.2].
- V44. A continuous component's state may be empty [§3.1]; a stateless continuous leaf is a continuous leaf with zero state fields.
- V45. Spelling it out puts every leaf's tier on the page in one place, no tier by omission.
- V46. Closes a trap: a store lost to local scope or forgotten import [§8.1] fails loud as a leaf declaring no store, where an optional marker would have dropped silently.
- V47. Store names each leaf because every service reaches a leaf by field name.
- V48. A condition (gloss: path-addressed sparse overlay that sets a build's state) merges on the field name [§14.1].
- V49. Readers and the trace spell it [§14.4].
- V50. The name a one-state component is asked for is the name every service then uses.
- V51. Because the type is derived from the value, no second artifact to drift and no separate type declaration to check.
- V52. The workspace is the exception to that convention; declared by allocation as `ws_init(::C, ::Type{T})` on both tiers [D-077, D-263].
- V53. The method itself is the allocator.
- V54. Workspace earns the exception because it is not memory and none of the by-value arguments below cover it [§7.3].
- V55. `ws_init` alone declares by allocation.
- V56. Nothing downstream derives from the type of what `ws_init` returns.
- V57. This is the boundary of legitimate derivation: deriving from another declaration is sound; from evaluated user code is not.
- V58. Typed stores with synthesized initial values were rejected [D-073].
- V59. Declared values are the base layer of the condition substrate.
- V60. Overlays [§14.1] fall back to declared values leaf by leaf.
- V61. Compiled store writers bake `merge(defaults, overlay)`.
- V62. Therefore there must be an authored value under every leaf.
- V63. Asymmetry against `u_types`/`y_types` is one of kind, not style.
- V64. Contracts (gloss: a component's declared interfaces) describe table cells (gloss: signal table's typed entries, one per output port).
- V65. Cells recomputed from scratch every sweep (gloss: one pass through execution order), so contracts need only types.
- V66. `init_*` describe stores, the model's memory, which must have contents before the first sweep can run.

Cited: D-263 (x4), D-079, D-077 (x2), D-033, D-247 (x2), D-073; §§2.1, 3.1, 5.2, 5.3, 7.1, 7.3, 8.1, 8.3, 8.5, 9.1, 10.6, 12.5, 14.1, 14.2, 14.4, App C.
Observations to settle in phase 2: V54 "by-value arguments below" (none follow in this unit); V66 `init_*` spelling; gloss of `Pinned`, walk, activation, cell ("one per output port"), workspace.
