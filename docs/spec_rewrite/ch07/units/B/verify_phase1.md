# Unit B, phase 1 (blind) assertion list

V1. The entire continuous evaluation path is generic over `T <: Real` [D-011]. (bold)
V2. The state buffer is generic over `T <: Real` [D-011].
V3. The buffer is the framework-owned flat vector backing continuous state (gloss).
V4. The pack/unpack machinery is generic over `T <: Real` [D-011].
V5. This one design property serves four consumers.
V6. Consumer 1: exact Jacobians for linearization, with ForwardDiff duals through the whole model.
V7. These exact Jacobians replace finite differences.
V8. Consumer 2: derivatives for trim solvers.
V9. Consumer 3: the feedthrough tracer [§5.6].
V10. The feedthrough tracer is the set-propagation instrument classifying a rejected cycle [§5.6] (gloss).
V11. Consumer 4: a trivially checkable CI invariant [D-280].
V12. One evaluation sweep with `T = Dual` fails loudly on any Float64-pinning [D-280].
V13. A sweep is one pass through the execution order (gloss).
V14. It fails with a `MethodError` or `InexactError` at the offending line [D-280].
V15. (Pointer) The section states three tiers, the per-leaf spelling, lookup tables and three author rules.
V16. Scoping (what needs genericity) has three tiers [D-011].
V17. Walked tier = payload and value types constructed during evaluation [D-011].
V18. `FrameTransform` is an example of a walked type.
V19. Parametrizing walked types is mechanical.
V20. Constructors infer `T`, so call sites don't change.
V21. `@kwdef` defaults pin the no-argument case to `Float64`.
V22. `@kwdef` is Julia's keyword-constructor macro (gloss).
V23. Pinned tier = parameters and definitions; they stay `Float64` [D-011].
V24. Pinned needs no migration, because promotion handles mixing.
V25. Exempt tier = the discrete side (compensators, avionics) [D-011].
V26. Reason: linearization and trim differentiate continuous dynamics only.
V27. For consumer 1, the discrete exemption is not a limitation but the exact answer [D-072].
V28. A frozen discrete cell is a constant with zero partials [D-072].
V29. A cell is a typed entry of the signal table (gloss).
V30. That is what "linearize the continuous dynamics with the discrete state held" means [D-072].
V31. `frozen_discrete_walkthrough.md` works the chain through in detail.
V32. The declaration layer keeps the scoping legible without putting it in the author's way.
V33. Every declaration but the allocator [§7.3] is written at nominal `Float64`.
V34. One walk retypes it per activation [§8.2].
V35. Activation = the build's typed products at a given scalar type (gloss).
V36. On the continuous tier a `Float64` leaf follows the activation scalar, in a contract and in the `x_init`-derived state type alike [D-263, D-295].
V37. A contract leaf wrapped in `Pinned{P}` is deliberately pinned [D-263].
V38. Participation is therefore authored per leaf, by absence or presence of the marker.
V39. The discrete side stays plain and pins wholesale [D-263, D-295].
V40. Nothing anywhere comes from inference through user code [D-032].
V41. Safety of the substitution rests on the embedding guarantee [§9.5].
V42. For lookups, table data is a pinned parameter [D-011].
V43. The query coordinate is walked traffic [D-011].
V44. Interpolations.jl is the interpolation package Flight.jl's lookup tables use.
V45. Interpolations.jl evaluates generically over the coordinate.
V46. `itp(x::Dual)` works through the `BSpline`/`scale`/`extrapolate` compositions in Flight.jl's tables.
V47. Two caveats apply.
V48. `Linear()` interpolants have kinked derivatives at knots.
V49. That is no regression against finite differences.
V50. Upgrade to `Cubic` where Jacobian quality near a lookup matters.
V51. A manual chain rule via `Interpolations.gradient` is the escape hatch for anything exotic [D-266].
V52. That manual chain rule is the pattern for wrapping non-Julia black boxes [D-266].
V53. Three rules are author-facing [D-011, D-235].
V54. Rule 1: no `::Float64` argument annotations in math; use `<:Real` or nothing.
V55. Rule 2: no `Float64`-pinned intermediates; write `zero(SVector{3,T})`.
V56. Rule 3: no `::SomeType{Float64}` return-type annotations on the continuous path.
V57. Such annotations force converts and hence `InexactError`.
