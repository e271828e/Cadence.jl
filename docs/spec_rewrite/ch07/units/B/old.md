### 7.2 Numeric genericity (eltype)

The state [buffer](#g-buffer), the pack/unpack machinery, and the entire **continuous
evaluation path** are generic over `T <: Real`. This one design property serves
four consumers.

1. Exact Jacobians for **linearization**, with ForwardDiff duals through the
   whole model, replacing finite differences.
2. Derivatives for **trim** solvers.
3. The **[feedthrough tracer](#g-feedthrough-tracer)** (the set-propagation instrument classifying a
   rejected cycle, [§5.6][s5-6]).
4. A trivially checkable **CI invariant**. One evaluation [sweep](#g-sweep) with `T = Dual`
   fails loudly (`MethodError`/`InexactError` at the offending line) on any
   Float64-pinning.

For consumer 1, the *discrete* side's exemption is not a limitation but the
exact answer. A frozen discrete [cell](#g-cell) is a constant with zero partials, which is
what "linearize the continuous dynamics with the discrete state held" means.
`frozen_discrete_walkthrough.md` works the chain through in detail.

The declaration layer keeps this scoping legible without putting it in the
author's way. Every declaration is written at nominal `Float64`, and one walk
retypes it per [activation](#g-activation) ([§8.2][s8-2]). On the continuous tier a `Float64`
leaf follows the activation scalar, in a contract and in the `x_init`-derived
state type alike, and a contract leaf wrapped as `Pinned{P}` is deliberately
[pinned](#g-walked). Participation is therefore authored per leaf, by the absence or
presence of the marker. The discrete side stays plain and pins wholesale.
Nothing anywhere comes from inference through user code. Safety of the
substitution rests on the embedding guarantee stated in [§9.5][s9-5].

Scoping, meaning what actually needs genericity, covers roughly half the type
inventory and has three tiers ([D-011][d-011]).

- **[Walked](#g-walked)**, the payload and value types constructed during evaluation (about
  25 structs). These are the quaternion/attitude family, `Wrench`,
  `FrameTransform`, `MassProperties`, `KinData`, `AirData`, geodesy value types,
  `TerrainData` and continuous output structs. `Quaternion` becomes
  `Quaternion{N,T} <: AbstractVector{T}`. By invariance, `Float64` instances
  still match every existing `AbstractVector{Float64}` method, so existing
  behavior is untouched. The parametrization is mechanical. Constructors infer
  `T`, so call sites don't change, and `@kwdef` defaults pin the no-argument
  case to `Float64`.
- **Pinned**, the parameters and definitions. They stay `Float64`, since
  promotion handles mixing, and need no migration.
- **[Exempt](#g-walked)**, the discrete side (compensators, avionics). Linearization and trim
  differentiate continuous dynamics only.

For lookups, **table data is a pinned parameter and the query coordinate is
walked traffic.** Interpolations.jl evaluates generically over the coordinate.
`itp(x::Dual)` works through the `BSpline`/`scale`/`extrapolate` compositions in
use. Two caveats apply. `Linear()` interpolants have kinked derivatives at
knots. That is no regression against finite differences, but upgrade to `Cubic`
where Jacobian quality near a lookup matters. A manual chain rule via
`Interpolations.gradient` is the escape hatch for anything exotic, and the
pattern for wrapping non-Julia black boxes.

**Rule.** Three rules are author-facing. First, no `::Float64` argument
annotations in math. Use `<:Real` or nothing, which the codebase already mostly
does. Second, no `Float64`-pinned intermediates. Write `zero(SVector{3,T})`.
Third, **no `::SomeType{Float64}` return-type annotations** on the continuous
path, because they force converts and hence `InexactError`. The `*` method in
`attitude.jl` is the live example pattern.

