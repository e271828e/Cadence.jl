# The linear blocks: `TransferFunction`, `StateSpace` and why they are two

*A companion record, not normative text. The ground truth is `spec.md`
[§13.7][s13-7] (the library), [§5.3][s5-3] and [§5.4][s5-4] (feedthrough and artificial loops),
[§7.2][s7-2] (numeric genericity) and [§14.10][s14-10] (linearization), with decisions
[D-226][d-226], [D-263][d-263] and [D-313][d-313]. If this document and the spec ever disagree, the
spec wins. It was written on 2026-10-07, when the inventory's one
`LinearSystem` row was split into two blocks, to keep the reasoning behind
the split, the realization a transfer function goes through, and the
initial-condition and naming rulings that came with it. Section 9, added the
same day, mirrors the pair onto the discrete tier and adds the two blocks
discretized per tick from a continuous system.*

The inventory listed one candidate, `LinearSystem` holding `A`, `B`, `C`
and `D` as static matrices, and said it "covers transfer functions and
state-space models". The second half is immediate. The first hides a
realization step, and working through it showed that everything the user
touches differs between the two spellings, while only the two equations are
shared. Section 1 states the two spellings, section 2 the realization,
section 3 how the direct term picks the stage, section 4 the ports and the
storage, section 5 the initial condition, section 6 the case for two
blocks, section 7 the names, and section 8 the decision with the probed
numbers.

## 1. Two spellings of one object

A finite-dimensional linear time-invariant system is written either as the
state-space model

```
q̇ = A q + B u        A: NX×NX   B: NX×NU
y  = C q + D u        C: NY×NX   D: NY×NU
```

or, for one input and one output, as the transfer function

```
G(s) = (b_n sⁿ + b_{n-1} sⁿ⁻¹ + … + b_0) / (sⁿ + a_{n-1} sⁿ⁻¹ + … + a_0)
```

with the denominator made monic. The transfer function describes only the
map from input to output. Any state-space model with that map is a
*realization* of it, and the realizations form a family: for every
invertible `T`, `(T A T⁻¹, T B, C T⁻¹, D)` has the same transfer function
as `(A, B, C, D)`. The state of one realization is `T` times the state of
another. A user who knows the transfer function alone therefore knows
nothing about what the state vector means, which is the fact section 5
turns on.

## 2. The realization

A transfer function is realizable when the numerator's degree is at most
the denominator's. Equal degrees mean the output depends on the input at
the same instant, and that part is split off first: `D = b_n`, and the
remaining numerator coefficients become `b̃_i = b_i - b_n a_i`. What is
left is strictly proper, and the *controllable canonical form* realizes it
mechanically. The states are a chain, each the derivative of the previous
one, and the denominator acts on the last derivative:

```
A = [ 0     1     0   …  0      ]      B = [0]      C = [b̃_0  b̃_1  …  b̃_{n-1}]
    [ 0     0     1   …  0      ]          [0]
    [ …                          ]          [⋮]      D = b_n
    [-a_0  -a_1  -a_2 … -a_{n-1}]          [1]
```

With coefficients given highest power first, as the control texts and the
analysis packages write them, the helper is a dozen lines:

```julia
function realize(num, den)                    # highest power first
    n = length(den) - 1
    num = (zeros(n + 1 - length(num))..., num...) ./ den[1]   # pad; make den monic
    den = den ./ den[1]
    d = num[1]                                # the direct term, zero when strictly proper
    b = num[2:end] .- d .* den[2:end]
    a = den[2:end]                            # a_{n-1} … a_0
    A = SMatrix{n, n}([zeros(n - 1) I(n - 1); -reverse(a)'])
    B = SMatrix{n, 1}([zeros(n - 1); 1])
    C = SMatrix{1, n}(reverse(b)')
    (; A, B, C, D = SMatrix{1, 1}(d))
end
```

Three checks fix the mechanics. The lag `1/(τs + 1)` realizes to
`A = -1/τ`, `B = 1`, `C = 1/τ`, `D = 0`, which is `FirstOrderLag` with its
state scaled by `τ`. The lead-lag `(s + 2)/(s + 5)` realizes to `A = -5`,
`B = 1`, `C = -3`, `D = 1`, and `1 - 3/(s + 5)` expands back to the
original. The second-order `ω²/(s² + 2ζωs + ω²)` realizes to
`A = [0 1; -ω² -2ζω]`, `B = [0; 1]`, `C = [ω² 0]`, `D = 0`.

Companion forms are numerically poor at high order, because the
coefficients span many magnitudes. The library's transfer functions are
lags, lead-lags, washouts, second-order filters and notches, of order one to
four, where this is no issue. Balanced realizations are an analysis
package's job, not a block constructor's.

## 3. The direct term picks the stage

[§5.3][s5-3]'s rule is that an output computed as `h(x)` comes from `y_state` and
one computed as `h(x, u)` from `y_direct`, and that the stage's name is the
feedthrough declaration the loop checker reads. A strictly proper system,
`D = 0`, publishes `out` from stage 1 and breaks algebraic loops as the lag
does. A proper one, `D ≠ 0`, publishes from stage 2, participates in
feedthrough, and cannot close a loop on itself through a memoryless path.

Stage methods dispatch on the type, so the block cannot test `iszero(D)` at
run time. The feedthrough class is a type parameter, `FT`, and the
constructor sets it, from `iszero(D)` for the matrices and from the degree
comparison for a transfer function. The two arms are

```julia
y_state(c::LinearBlock{false}, (; x))     = (out = C q,)
y_direct(c::LinearBlock{true}, (; x, u))  = (out = C q + D u,)
```

on the abstract supertype section 6 introduces, and `x_deriv` is one method
over both. The lesson is testable. A scalar
block with `D = 0` wired into a unit-feedback loop through a difference
junction builds; the same loop with `D = 1` is refused as an
`AlgebraicCycle` classified `:real`, which the probe in section 8 confirmed.

## 4. Ports and storage

Wires name whole ports, so the input is one port and the output one port.
When `NU` and `NY` are both one the ports are scalars, otherwise they are
`SVector{NU}` and `SVector{NY}`, decided from the matrix shapes at
construction. The matrices are stored at full shape in every case, and the
bodies always do matrix products. The scalar case converts at the edges, a
scalar input lifted to an `SVector{1}` by `as_vector` and a one-element
result read out by `as_port`, with `port_type` naming the port for each
width, so there is one layout and the scalar block is not a second
implementation. The state is an `SVector` at every size for the same
reason, so a one-state block's `q` reads as a one-element vector and is
tapped as `"q[1]"` ([D-276][d-276]); a scalar state at `NX = 1` would be a second
layout with its own arms. Stage 1 of the increment found this when the
scalar linearization's tap `:q` was refused, and kept the one layout.

One trap was met and is recorded because it is silent. `SMatrix{N, N,
Float64}` is not a concrete type: a static matrix carries its length as a
fourth parameter, and a field declared without it is abstractly typed. The
first prototype was written that way, built, ran, linearized correctly, and
allocated about 1,100 bytes per step from boxing in the stage bodies, where
the lag allocates nothing beyond the framework's own. The fix is the
StaticArrays idiom, a length parameter per matrix field, after which the
block's steps match the lag's byte for byte at every shape probed (section
8). Plain `Matrix{Float64}` fields converted to static matrices inside the
bodies measured the same, at the cost of a heap field in instance data, and
were not chosen.

## 5. The initial condition

`StateSpace` takes `x0`, because the user wrote the coordinates and the
number means what they say. `TransferFunction` does not, because by
section 1 its state is an implementation detail: the same `x0` means one
output in the controllable form and another in the observable form, and
nothing to a user who knows only `G(s)`. The lag shows it at the smallest
scale, `FirstOrderLag(x0 = 1)` starting with output one and the realized
`1/(τs + 1)` with the same `x0` starting with output `1/τ`.

What the user means is one of two things. Starting at rest is zero state,
and it is also the assumption the transfer function itself carries, since
the Laplace transform that defines it takes zero initial conditions. It is
the default. Starting in steady state for a constant input `u0` is the
other, and it is well defined in any coordinates because it comes from the
equations rather than from the state's meaning: `0 = A q0 + B u0` gives
`q0 = -A⁻¹ B u0`, and the output starts at `(D - C A⁻¹ B) u0 = G(0) u0`,
the DC gain times the input. The block takes `u0`, solves once at
construction, and offers no `x0` keyword; the solved state is visible only
inside the held realization, which the default `show` prints with the
coefficients.

The solve needs `A` invertible, meaning no pole at the origin. A static
`\` on a singular matrix does not throw: the probe got `-Inf` for the
integrator and `[-Inf, NaN]` for the double integrator. The refusal is
therefore explicit, and the exact test is the denominator's constant
coefficient being zero, which is what a pole at the origin is. An
integrator with `u0 = 0` is fine, since zero state is zero state.

An initial output `y0` was considered and rejected. For a first-order
system one output pins one state. For order `n` it fixes one linear
combination of `n` states and leaves `n - 1` free, so the constructor would
have to invent the rest. `u0` pins all `n` at once, and it is the case that
arises, a plant at an operating point when the controller is switched on.
The framework's trim is the general answer for a whole model; `u0` is the
same question for one linear leaf, in closed form.

## 6. Why two blocks

Listing what differs between the spellings, every item sits at the boundary
the user sees:

- **construction**, coefficients against matrices, with a realization step
  only one of them needs;
- **the initial condition**, `x0` in the user's coordinates against `u0`
  with the state hidden, which is not a scalar-against-vector split, since
  a scalar state-space system still takes `x0`;
- **the ports**, always scalar for a transfer function, scalar or `SVector`
  for state space;
- **the feedthrough class**, from the numerator's degree against
  `iszero(D)`;
- **what to show**, `num` and `den` for a transfer function, where the
  realized matrices are noise and a block holding only matrices has
  forgotten the coefficients it was built from.

One type carrying all of that has a constructor with two disjoint keyword
sets, an `x0` that is meaningful or a trap by which set was used, and a
`show` that cannot tell them apart. What the spellings share is the two
equations and section 3's arm selection, and that is shared without a
shared concrete type. The transfer function keeps its coefficients as
instance data and holds the realized `StateSpace` beside them. Both blocks
subtype one abstract `LinearBlock{FT}`, and each stage arm is defined once,
on the supertype, over an accessor that returns the matrices:

```julia
abstract type LinearBlock{FT} <: AbstractComponent end
realization(c::StateSpace) = c
realization(c::TransferFunction) = c.realization

x_deriv(c::LinearBlock, (; x, u))        = (s = realization(c); (q = s.A * x.q + s.B * u,))
y_state(c::LinearBlock{false}, (; x))    = (out = realization(c).C * x.q,)
y_direct(c::LinearBlock{true}, (; x, u)) = (s = realization(c); (out = s.C * x.q + s.D * u,))
```

Nothing is forwarded and no `Group` wraps a leaf, so the transfer function
costs no cell, no gather and no scatter. The one cost is a concrete type to
compile per order and class, the same cost a `StateSpace` of that shape
pays.

The first draft forwarded instead, `y_state(c::TransferFunction{N, false},
b) = y_state(c.realization, b)` and its twin, and the user asked what the
obvious generic spelling, `y_state(c::TransferFunction, b) =
y_state(c.sys, b)` for both stages, would do. The build detects a stage by
`hasmethod` on the component's type and never looks inside, so a method's
existence is the declaration: the generic pair declares both stages for
every transfer function. A probe followed the three steps an author would
take from there. The generic pair builds nothing, since the arm the inner
block lacks surfaces as a `UserCodeFraming` around a `MethodError`. The
natural repair, an inner `y_direct` for every class with `D` taken as zero,
is refused as `ProducedByTwoStages` on `out` ([§8.3][s8-3]). The next repair,
dropping `y_state` so `y_direct` is the only producer, builds and silently
makes a strictly proper block a feedthrough block, which only the loop test
of section 3 catches. The supertype removes the forwarding, and with it the
place where the generic spelling could be written. With it the probe found
`has_stage(y_direct, ·)` false on a strictly proper transfer function and
`has_stage(y_state, ·)` false on a proper one, the loop pair of section 3
holding for the transfer functions, and the lag match, the `Dual` build and
the allocation figures of section 8 unchanged.

Against [D-313][d-313]'s guidelines, `TransferFunction` stands alone. It is
domain-agnostic and the most used object in classical control. It is
didactic in a way the matrix block is not, a feedthrough class derived from
a property of the user's input, and the clearest small example of why the
stage name is the loop checker's evidence. And it is difficult to get
right, with the direct-term split, the monic normalization, the `x0` trap
and section 4's storage trap as the standing examples. `StateSpace` keeps
the general row for the state-space and multi-input case.

## 7. The names

`LinearSystem` named the mathematical object both blocks are. Once they
are two, the pair `TransferFunction`/`LinearSystem` reads as a kind beside
the general thing, and `TransferFunction`/`StateSpace` as two spellings of
one thing, which is the truth. They are also the names the field uses:
MATLAB's `tf` and `ss`, ControlSystems.jl's and python-control's
`TransferFunction` and `StateSpace`.

ControlSystemsBase.jl exports both names, and a user who linearizes a
model and analyses it there loads both packages. The collision is real,
both names collide and not one, and it was judged not to cost a rename.
`Redstone.Blocks` exports nothing ([D-226][d-226]), so every block reaches a file
either qualified, `Blocks.StateSpace`, or by an explicit import, the one
place the choice is visible. Julia resolves an explicit import against a
`using` in the explicit import's favour, in every order and without a
warning; this was checked on Julia 1.13.1 with two modules defining one
name, one exporting it, the explicit import winning before the `using`,
after it, and after the exported name had already been used. The failure
mode is a user who wrote the import line and forgot which one they meant,
and the block's keyword constructor makes that loud, since the positional
`StateSpace(A, B, C, D)` of the analysis packages does not match it. If the
shared name ever bothers in practice, the fix is a bridge, a constructor
from the analysis type behind a package extension, not a rename; it is not
listed.

## 8. The decision, and the numbers

Two blocks, `StateSpace` and `TransferFunction`, in one increment, the
companion's sections 2 to 7 the contract. Prototypes of both were built
against the tree at 0571605 and probed at `h = 1//100`:

| probe | result |
|---|---|
| two-state, two-input, two-output `StateSpace` linearized at `t = 0.3` | `A`, `B`, `C`, `D` recovered to `≈` |
| the same, built under `(Float64, LinearizeDual)` | builds |
| scalar `StateSpace`, `D = 0`, in a unit-feedback loop through a difference junction | builds |
| the same loop with `D = 1` | `AlgebraicCycle`, classification `:real` |
| `TransferFunction(num = (1,), den = (0.5, 1))` beside `FirstOrderLag(τ = 0.5)`, both from a unit constant, at `t = 1` | outputs equal to the last bit, `0.8646647163964265`; the realized state `0.4323…`, half the lag's |
| the strictly proper transfer function in the unit-feedback loop; the lead-lag in the same loop | builds; `AlgebraicCycle`, classification `:real` |
| generic two-stage forwarding; an inner `y_direct` for every class; `y_direct` as the only producer of a `D = 0` block | `UserCodeFraming`; `ProducedByTwoStages` on `out`; builds, and the loop is refused |
| `TransferFunction(num = (1, 2), den = (1, 5))` | type `{1, true, …}`; linearizes to `A = -5`, `B = 1`, `C = -3`, `D = 1` |
| `TransferFunction(num = (4,), den = (1, 1.2, 4))` linearized, `C (sI - A)⁻¹ B + D` against `G(s)` at `s = 0, i, 2i, 1 + 3i` | agreement to `2.3e-16` or better |
| `TransferFunction(num = (1,), den = (0.5, 1), u0 = 3)` fed `3` | output `3.0` at start and after one second |
| `den = (1, 0)` with `u0 = 1` | refused at construction; with `u0 = 0` it builds |
| `num` longer than `den` | refused at construction |
| `step!` over `0.1 s` after warm-up, abstract `SMatrix{N, N, Float64}` fields | scalar 19,088 B, two-by-two 25,328 B |
| the same with length parameters, and with `Matrix` fields converted in the body | scalar 8,208 B, two-by-two 8,368 B, equal to the scalar and vector lags |
| `step!` over `0.1 s`, the transfer functions through `LinearBlock{FT}` | lag form and lead-lag 8,208 B, equal to the scalar lag |

## 9. The discrete tier

Every item section 6 listed as differing between the two spellings is about
the user's boundary, not the tier, so the discrete tier gets the same pair,
and a second pair beside it for a continuous system discretized at run time.
The four share one abstract `DiscreteLinearBlock{FT}`. Two accessors serve
it: `held(c)` returns the stored system, whose shapes and `x0` do not depend
on the period, and `realization(c, Δt)` returns the discrete update matrices.
The declarations and the output arms read `held(c)`, and only the update
discretizes, because the hold of section 9.2 leaves `C` and `D` untouched.

```julia
abstract type DiscreteLinearBlock{FT} <: AbstractComponent end

s_init(c::DiscreteLinearBlock)  = (q = held(c).x0,)
u_types(c::DiscreteLinearBlock) = (in = port_type(size(held(c).B, 2)),)
y_types(c::DiscreteLinearBlock) = (out = port_type(size(held(c).C, 1)),)
function s_update(c::DiscreteLinearBlock, (; s, u, Δt))
    (; A, B) = realization(c, Δt)
    (q = A * s.q + B * as_vector(u.in),)
end
y_state(c::DiscreteLinearBlock{false}, (; s)) = (out = as_port(held(c).C * s.q),)
function y_direct(c::DiscreteLinearBlock{true}, (; s, u))
    (; C, D) = held(c)
    (out = as_port(C * s.q + D * as_vector(u.in)),)
end
```

One supertype cannot span both tiers: every leaf declares exactly one of
`x_init` and `s_init`, and the store is the tier marker ([D-263][d-263]), so two
parallel trees is the honest shape. A leaf holding another component
instance as a field has `TransferFunction` as its precedent, and the
structure step reads tiers from declarations, never from fields.

### 9.1 The pair in `z`

`DiscreteStateSpace` holds `A`, `B`, `C`, `D` and `x0` as the continuous
block does, with `FT` from `iszero(D)`, and is its own `held` and
`realization`. `DiscreteTransferFunction` takes its coefficients highest
power of `z` first, the convention of MATLAB's `tf(num, den, Ts)` and of
the continuous block, and holds the `DiscreteStateSpace` that `realize`
produces unchanged, since the companion form does not know whether its
variable is `s` or `z`. The DSP convention, `filter(b, a)` in powers of
`z⁻¹`, agrees only when the degrees are equal, and the docstring says so.

Both carry a period they cannot see. Their matrices presuppose the sample
time they were designed at, `Δt` binds at deployment, and the instance is
built before that, so neither the constructor nor the structure step can
compare the two. A `Ts` field checked at the first tick was rejected as a
run-time refusal of a deployment fact, and a declared period would need a
hook that `sample_times` deliberately denies instances ([D-042][d-042]). The
docstring states the dependence, and section 9.2 is the mitigation.

The steady state for `u0` is `(I - A) q0 = B u0`, so `out` starts at
`G(1) u0`. The pole with no steady state is now at `z = 1`, whose exact test
is the denominator summing to zero, and unlike the continuous test on the
constant coefficient this one is floating. A designed denominator such as
`(1, -0.7, -0.3)` sums to about `-5.6e-17`, so an exact test lets the solve
through and yields a huge state. The refusal takes a tolerance.

### 9.2 The pair discretized per tick

`DiscretizedStateSpace` holds a continuous `StateSpace` and discretizes it
in `realization(c, Δt)` by the zero-order hold, which is exact when the
input is held over each period:

```
A_d = e^{A Δt}        B_d = (∫₀^Δt e^{Aτ} dτ) B        C_d = C        D_d = D
```

The two are read off one static exponential of the augmented matrix
`[A B; 0 0] Δt`, whose top row is `[A_d B_d]`. The output equation is
algebraic and merely sampled, so the class is `iszero(D)` as for the
continuous block, and `x0` in the user's coordinates is exact.
`DiscretizedTransferFunction` takes its coefficients in `s`, realizes them
as the continuous block does and holds the `DiscretizedStateSpace`, so the
pattern is the continuous one with one more layer.

Per tick is the only clean place for the discretization. The instance
predates the period. The workspace allocator receives no `Δt` and the
workspace may carry nothing between calls. The store could hold the
matrices as isbits fields, but then a value that is not state is logged
every tick and multiplied every tick, against [§7.3][s7-3]'s rule that no
arithmetic is done on a store. The body is where the design put `Δt`, and
the IMU sampler of [§8.7][s8-7] divides by it every tick for the same reason.
The cost is small: on Julia 1.13.1 a static `exp` allocates nothing at
every size probed, about 41 ns at 4×4 and 125 ns at 5×5, against the
hundreds of bytes a tick's publication already allocates. The exponential
is defined for every matrix and period, so the probe's placeholder `Δt`
([§9.3][s9-3]) raises no singularity.

The initial conditions do not depend on the period. `I - A_d` is
`A⁻¹`-commuting times `e^{AΔt} - I`, so the discrete steady state for `u0`
is the continuous one, `q0 = -A⁻¹ B u0`, `out` starts at `G(0) u0`, and the
refusal is the continuous one, a zero constant coefficient, with no
tolerance question. The solve runs once at construction from the
continuous matrices.

Tustin was weighed for the transfer function and rejected. The trapezoidal
rule's update reads the input at `k + 1`, and the change of variable that
removes it moves half a period of input into the output equation, so a
strictly proper system gains a direct term for every period and every
Tustin block is `FT = true`. The lag shows it: the hold gives
`(1 - a)/(z - a)` with `a = e^{-Δt/τ}`, strictly proper, and Tustin gives
`(Δt/(2τ + Δt)) (z + 1)/(z - (2τ - Δt)/(2τ + Δt))`, of equal degrees. A lag
that broke a loop as a continuous block would be refused as an algebraic
cycle once discretized, which is the wrong surprise for a block whose
purpose is to stand in for its continuous original. The price is frequency
response: the hold matches the step response at the samples, while Tustin
preserves the response up to warping, which a controller designer may
want. The docstring states the caveat. A Tustin design is still available
by discretizing externally and using `DiscreteTransferFunction`, at the
price of section 9.1's period dependence. Should the method ever be wanted
on the block, it becomes a type parameter on the accessor's arm, with `FT`
set from the method as well as from `D`.

Four blocks and not two because a controller designed in `z`, or exported
by a `c2d` elsewhere, arrives with no continuous original. The `Discrete`
and `Discretized` prefixes match `DiscreteIntegrator`, and ControlSystemsBase
spells its discrete case as a time-evolution parameter on the two names
section 7 discussed, so none of the four new names collides.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-042]: ../decisions.md#d-042--rates-declaration-on-immediate-children-only
[d-226]: ../decisions.md#d-226--reach-the-public-surface-by-qualified-name-until-the-export-audit
[d-263]: ../decisions.md#d-263--one-arity-on-both-tiers-plain-contracts-the-pinned-marker-and-the-mandatory-store
[d-276]: ../decisions.md#d-276--address-a-leaf-inside-a-port-value-by-a-dotted-leaf-address
[d-313]: ../decisions.md#d-313--admit-a-library-block-by-judgement-against-three-guidelines
[s13-7]: ../spec.md#137-tooling-consequences-face-routes-and-the-component-library
[s14-10]: ../spec.md#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s5-3]: ../spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
[s5-4]: ../spec.md#54-artificial-loops-and-the-escape-hatch
[s7-2]: ../spec.md#72-numeric-genericity-eltype
[s7-3]: ../spec.md#73-discrete-state-modes-and-workspace
[s8-3]: ../spec.md#83-visibility-the-contract-is-the-interface
[s8-7]: ../spec.md#87-rate-scopes
[s9-3]: ../spec.md#93-probing-and-input-synthesis
