### 7.2 Numeric genericity (eltype)

**The entire continuous evaluation path is generic over `T <: Real`**, and so are
the state [buffer](#g-buffer) (the framework-owned contiguous vector backing all continuous
state) and the pack/unpack machinery ([D-011][d-011]). This one design property serves
four consumers.

1. Exact Jacobians for linearization, with ForwardDiff duals through the
   whole model, replacing finite differences.
2. Derivatives for trim solvers.
3. The [feedthrough tracer](#g-feedthrough-tracer) (the set-propagation
   instrument classifying a rejected cycle, [§5.6][s5-6]).
4. A trivially checkable CI invariant ([D-280][d-280]). One evaluation
   [sweep](#g-sweep) (one pass through the execution order) with `T = Dual`
   fails loudly on any Float64-pinning. It fails with a `MethodError` or an
   `InexactError` at the offending line.

The rest of the section states the three classes that scope this genericity, how
the declaration layer spells them per leaf, how lookup tables fit them, and
three rules for authors.

Scoping, meaning what actually needs genericity, has three classes ([D-011][d-011]).

- *[Walked](#g-walked)*, the payload and value types constructed during
  evaluation. One example is `FrameTransform`, a FlightPhysics payload type.
  The walked types' parametrization is mechanical. Constructors infer `T`, so
  call sites don't change, and `@kwdef` defaults pin the no-argument case to
  `Float64`. `@kwdef` is Julia's keyword-constructor macro.
- *Pinned*, the parameters and definitions. They stay `Float64`, since
  promotion handles mixing.
- *Exempt*, the discrete side (compensators, avionics). Linearization and trim
  differentiate continuous dynamics only.

For consumer 1, the *discrete* side's exemption is not a limitation but the
exact answer ([D-072][d-072]). A frozen discrete [cell](#g-cell) (a typed
entry of the signal table) is a constant with zero partials. That is what
"linearize the continuous dynamics with the discrete state held" means.
`frozen_discrete_walkthrough.md` works the chain through in detail.

The declaration layer keeps this scoping legible without putting it in the
author's way. Every declaration but the allocator ([§7.3][s7-3]) is written at nominal
`Float64`. One walk retypes it per [activation](#g-activation) (the build's typed products at a
given scalar type), as [§8.2][s8-2] states. On the continuous [tier](#g-tier) (the continuous or
discrete side) a `Float64` leaf follows the activation scalar, in a contract and
in the `x_init`-derived state type alike ([D-263][d-263], [D-295][d-295]). A contract leaf wrapped
in the leaf marker `Pinned{P}` is deliberately pinned ([D-263][d-263]). Participation is
therefore authored per leaf, by the absence or presence of the marker. The
discrete side stays plain and pins wholesale ([D-263][d-263], [D-295][d-295]). Nothing anywhere
comes from inference through user code ([D-032][d-032], [D-079][d-079]). Safety of the
substitution rests on the embedding guarantee stated in [§9.5][s9-5].

For lookups, table data is a pinned parameter and the query coordinate is
walked traffic ([D-011][d-011]). Interpolations.jl, the interpolation package
Flight.jl's lookup tables use, evaluates generically over the coordinate. A
call `itp(x::Dual)` works through the `BSpline`/`scale`/`extrapolate`
compositions in Flight.jl's tables. Two caveats apply. `Linear()` interpolants
have kinked derivatives at knots. That is no regression against finite
differences, but upgrade to `Cubic` where Jacobian quality near a lookup
matters. A manual chain rule via `Interpolations.gradient` is the escape hatch
for anything exotic, and the pattern for wrapping non-Julia black boxes
([D-266][d-266]).

Three rules are author-facing ([D-011][d-011], [D-235][d-235]).

1. No `::Float64` argument annotations in math. Use `<:Real` or nothing.
2. No `Float64`-pinned intermediates. Write `zero(SVector{3,T})`.
3. No `::SomeType{Float64}` return-type annotations on the continuous path,
   because they force converts and hence `InexactError`.
