# The linear blocks: `TransferFunction`, `StateSpace` and why they are two

*A companion record, not normative text. The ground truth is `spec.md`
[§13.7][s13-7] (the library), [§5.3][s5-3] and [§5.4][s5-4] (feedthrough and artificial loops),
[§7.2][s7-2] (numeric genericity) and [§14.10][s14-10] (linearization), with decisions
[D-226][d-226], [D-263][d-263] and [D-313][d-313]. If this document and the spec ever disagree, the
spec wins. It was written on 2026-10-07, when the inventory's one
`LinearSystem` row was split into two blocks, to keep the reasoning behind
the split, the realization a transfer function goes through, and the
initial-condition and naming rulings that came with it.*

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
y_state(c::StateSpace{NX, NU, NY, false}, (; x))     = (out = C q,)
y_direct(c::StateSpace{NX, NU, NY, true}, (; x, u))  = (out = C q + D u,)
```

and `x_deriv` is one method over both. The lesson is testable. A scalar
block with `D = 0` wired into a unit-feedback loop through a difference
junction builds; the same loop with `D = 1` is refused as an
`AlgebraicCycle` classified `:real`, which the probe in section 8 confirmed.

## 4. Ports and storage

Wires name whole ports, so the input is one port and the output one port.
When `NU` and `NY` are both one the ports are scalars, otherwise they are
`SVector{NU}` and `SVector{NY}`, decided from the matrix shapes at
construction. The matrices are stored at full shape in every case, and the
bodies always do matrix products. The scalar case converts at the edges, a
scalar input lifted to an `SVector{1}` and a one-element result read out,
so there is one layout and the scalar block is not a second
implementation.

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
construction, and never surfaces `q0`.

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
shared type. The transfer function keeps its coefficients as instance data,
holds the realized `StateSpace` beside them, and forwards its stages:

```julia
x_deriv(c::TransferFunction, b) = x_deriv(c.realization, b)
y_state(c::TransferFunction{N, false}, b) where {N} = y_state(c.realization, b)
y_direct(c::TransferFunction{N, true}, b) where {N} = y_direct(c.realization, b)
```

This is delegation at the method level, not a `Group` around a leaf, so it
costs no cell, no gather and no scatter. The one cost is a concrete type to
compile per order and class, the same cost a `StateSpace` of that shape
pays.

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
| `TransferFunction(num = (1, 2), den = (1, 5))` | type `{1, true, …}`; linearizes to `A = -5`, `B = 1`, `C = -3`, `D = 1` |
| `TransferFunction(num = (4,), den = (1, 1.2, 4))` linearized, `C (sI - A)⁻¹ B + D` against `G(s)` at `s = 0, i, 2i, 1 + 3i` | agreement to `2.3e-16` or better |
| `TransferFunction(num = (1,), den = (0.5, 1), u0 = 3)` fed `3` | output `3.0` at start and after one second |
| `den = (1, 0)` with `u0 = 1` | refused at construction; with `u0 = 0` it builds |
| `num` longer than `den` | refused at construction |
| `step!` over `0.1 s` after warm-up, abstract `SMatrix{N, N, Float64}` fields | scalar 19,088 B, two-by-two 25,328 B |
| the same with length parameters, and with `Matrix` fields converted in the body | scalar 8,208 B, two-by-two 8,368 B, equal to the scalar and vector lags |

The discrete tier's filter row becomes `DiscreteTransferFunction`, the
same realization over `s_update` with `z` in place of `s`, once the helper
exists.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-226]: ../decisions.md#d-226--reach-the-public-surface-by-qualified-name-until-the-export-audit
[d-263]: ../decisions.md#d-263--one-arity-on-both-tiers-plain-contracts-the-pinned-marker-and-the-mandatory-store
[d-313]: ../decisions.md#d-313--admit-a-library-block-by-judgement-against-three-guidelines
[s13-7]: ../spec.md#137-tooling-consequences-face-routes-and-the-component-library
[s14-10]: ../spec.md#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s5-3]: ../spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
[s5-4]: ../spec.md#54-artificial-loops-and-the-escape-hatch
[s7-2]: ../spec.md#72-numeric-genericity-eltype
