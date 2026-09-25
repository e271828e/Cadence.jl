# A handle under the walk: static terrain, a moving deck, one consumer

*A companion explainer, not normative text. The ground truth is `spec.md`
[§4.4][s4-4] (field handles), [§6.1][s6-1] (the two wire clauses), [§8.2][s8-2] (the `Pinned`
marker and the handle shape rule), [§9.5][s9-5] (the embedding guarantee), [§13.7][s13-7]
(the `Freeze` block) and [§14.10][s14-10] (the local rule), with decisions [D-237][d-237],
[D-263][d-263], [D-264][d-264], [D-265][d-265] and [D-266][d-266]. If this document and the spec ever disagree,
the spec wins. It was written on 2026-09-25, when the two rulings on the
marker landed, to keep the worked example that grounded them.*

Everything here answers one question. A landing-gear component reads a
terrain handle and computes ground clearance. Trim and linearization run
`Dual` activations over the whole assembly. **What does the gear author
declare, what does each terrain author declare, and what happens when a
`Float64` grid meets a `Dual` pose inside a query?**

## 1. One consumer, two producers

The handle follows [§8.2][s8-2]'s shape rule. Its bulk sits behind a reference at
fixed `Float64`, and only the part that can depend on the activation carries
the scalar parameter:

```julia
struct DeckField{T}
    heave::T                 # pose: follows the activation scalar
    pitch::T
    grid::Matrix{Float64}    # geometry: frozen build-time data, never re-typed
end
```

The gear leaves its entry tolerant, because its math promotes and because
several producers should be able to stand behind one face ([§8.2][s8-2]):

```julia
input_types(::Gear)  = (terrain = DeckField{Float64},)    # tolerant: any arrival
output_types(::Gear) = (clearance = Float64,)
output_direct(g::Gear, (; x, u)) = (; clearance = x.p[3] - height(u.terrain, x.p))
```

**Static terrain pins.** Its handle is built from the instance's grid and a
datum loaded at build time. Nothing in it depends on state or on anything a
tap could seed. Declared unpinned, `DeckField{Float64}` would walk to
`DeckField{Dual}` and the stage would have to construct the handle at `T` on
every evaluation, wrapping numbers that never carry partials. The author says
what is true instead:

```julia
output_types(::StaticTerrain) = (terrain = Pinned{DeckField{Float64}},)
output_direct(c::StaticTerrain, _) = (; terrain = DeckField(c.datum, 0.0, c.grid))
```

**A moving deck walks.** Replace the ground with a ship deck whose heave and
pitch are continuous state of a sea-motion component. The pose parameters now
carry partials, and the gear's contact force differentiates through them.
Pinning here would silently zero the coupling between ship motion and
touchdown. The author leaves the output unpinned and builds the handle at
`T`, which is cheap because only the pose is `T`:

```julia
output_types(::SeaMotion) = (terrain = DeckField{Float64},)
output_state(c::SeaMotion, (; x)) = (; terrain = DeckField(x.heave, x.pitch, c.grid))
```

**Both wire into the same gear.** The walk clause ([§6.1][s6-1]) admits the moving
deck at the tolerant entry because a walking producer needs an unpinned
entry, and it admits the static terrain because a frozen arrival at a
tolerant entry is the producer's cell ([D-264][d-264]). A discrete terrain producer,
which pins wholesale with no marker at all, is admitted on the same terms.
Before [D-264][d-264] the second and third wires were refused, because the wire
relation borrowed the store's identity rule for opaque leaves.

## 2. What happens when the grid meets the pose

A bilinear lookup is the shape almost every terrain or table query takes:

```julia
function height(f::DeckField, p::SVector{3})
    x = p[1] * cos(f.pitch) - p[3] * sin(f.pitch)   # Dual arithmetic
    y = p[2]
    i, j = floor(Int, x), floor(Int, y)             # index: an Int, partials dropped
    a, b = x - i, y - j                             # weights: Dual, partials kept
    g = f.grid
    z = (1 - a) * (1 - b) * g[i, j]   + a * (1 - b) * g[i+1, j] +
        (1 - a) * b       * g[i, j+1] + a * b       * g[i+1, j+1]
    return z + f.heave
end
```

Under a `Dual` activation `f.pitch`, `f.heave` and every component of `p`
are `Dual`s of one type, because an activation has exactly one scalar type.
The query then meets three kinds of operation.

- **Dual with Dual.** The frame rotation on the first line. Ordinary
  forward-mode arithmetic.
- **Dual with Float64.** Each product `a * g[i, j]`. Julia's promotion rule
  for the pair, defined by ForwardDiff, yields a `Dual` whose partials are
  `g[i, j]` times the partials of `a`. The grid entry is read as a plain
  `Float64` and never stored as a `Dual`. This is the embedding [§9.5][s9-5]
  describes, happening inside the author's expression rather than at a
  store.
- **Dual to Int.** `floor(Int, x)` floors the value and discards the
  partials. That discard is correct. The index is piecewise constant in `x`,
  so its derivative is zero almost everywhere, and the slope survives in the
  fractional parts.

Run with two seed directions, ship heave and aircraft `x`, on a grid whose
slope along `i` is 0.1:

```
typeof(f.grid) after the query: Matrix{Float64}
typeof(h) = Dual{:act, Float64, 2}
∂h/∂heave = 1.0    ∂h/∂x = 0.1
```

The output is a `Dual`, the grid was never touched, and the partials are the
ones wanted. Sensitivity to the pose flows through the pose's `Dual` fields,
sensitivity to position flows through the weights, and the grid contributes
slope but no partials of its own, because nobody seeded it.

**Why the shape rule.** With `grid::Matrix{T}` the walk would produce
`DeckField{Dual}` with a `Matrix{Dual}` field, and the producer would build a
copy of the whole grid, every entry a zero-partial wrapper around the same
`Float64`, on every evaluation. The query would return identical numbers.
[D-263][d-263]'s rule that a mutable type's parameters pin keeps that copy off the
table, and the one-scalar-plus-reference shape gets the same derivatives for
free.

## 3. Three habits that break tolerance

A frozen handle at a tolerant entry asks nothing of the consumer that a
frozen `Float64` at a tolerant entry does not already ask. Three habits
break it, and each fails loudly at the `Dual` probe rather than silently.

**Tying the handle's parameter to another argument.** For numbers, Julia
promotes a `Float64` and a `Dual` in any expression. For a handle there is
no such machinery, so a tied signature fails whenever the handle is frozen
and the position is not:

```julia
# fails at the Dual probe with a MethodError when u.terrain is DeckField{Float64}
height(f::DeckField{T}, p::SVector{3,T}) where {T} = ...
# promotes: the form every tolerant scalar consumer already writes
height(f::DeckField, p::SVector{3}) = ...
```

**Writing into a `Float64` buffer.** A scratch array from `zeros(n)` inside
the stage, or a workspace allocated without the `T` that `init_workspace(c,
T)` hands over, cannot receive a `Dual`.

**Casting to `Float64`.** `Float64(x)` on a `Dual` has no method. The one
sanctioned way to drop partials is `ForwardDiff.value`, and [§8.2][s8-2] asks that
the intent be spelled as a `Pinned` leaf rather than buried mid-expression.

One consequence is specific to handles. A component that re-emits a frozen
handle under an unpinned handle output hits the store's identity rule at the
first `Dual` activation, because its declaration promises `DeckField{Dual}`
and it produced `DeckField{Float64}`. For a scalar the executor would embed
on the write. So a handle's pin propagates down its chain: every component
that forwards it pins that output too.

## 4. The legacy consumer, and the `Freeze` block

A third actor is a ground-reaction model wrapping a C library that takes
the terrain as a raw pointer. It cannot take partials, and it says so at the
leaf:

```julia
input_types(::LegacyGround) = (terrain = Pinned{DeckField{Float64}},)
```

Wire the moving deck into it and `WalkingFaceAtFrozenEntry` fires with the
right message and the right remedies. That is the direction the kind was
built for, and [D-264][d-264] leaves it exactly as it was.

The same consumer may still need to sit downstream of a walking producer,
for a scalar just as for a handle. A `Dual` can never become a `Float64`
without discarding its partials, and no lossy cast exists inside the
framework ([§9.5][s9-5]). The framework does not do the discard at the wire, on
purpose, because dropping partials is a modelling decision the design wants
on the page. The `Freeze` block ([§13.7][s13-7]) is that page:

```julia
child_connections(::Rig) = (
    "deck/terrain" => "freeze/in",
    "freeze/out"   => "legacy/terrain",     # legacy declares Pinned{DeckField{Float64}}
)
```

At nominal the strip is the identity. Under a `Dual` activation the block
drops the partials, and its output satisfies the pinned entry. What the wire
now declares is a zero coupling in every Jacobian along that path. If that
coupling matters to the Jacobian, no adapter fixes it, and section 5 is the
answer. A sampler is the other non-walking source, and it changes the model:
the value is held between ticks and arrives one sample late, which is right
for a flight computer reading a sensor and wrong for a continuous value the
consumer merely cannot differentiate through.

## 5. Participating without `Dual`s: the local rule

The marker records that a leaf carries no partials. It does not record that
an implementation cannot take them. A component whose coupling matters to
the Jacobian, a C aerodynamic table whose slope the linearization must see,
keeps its entry tolerant and supplies its own local derivative inside the
stage ([§14.10][s14-10], [D-266][d-266]):

```julia
input_types(::Table)  = (u = Float64,)      # tolerant: this entry participates
output_types(::Table) = (y = Float64,)

output_direct(tb::Table, (; u)) = (; y = lookup(tb, u.u))

lookup(tb, u::Float64) = c_lookup(tb, u)                       # nominal: straight to the table

function lookup(tb, u::ForwardDiff.Dual{Tag}) where {Tag}       # Dual: the local rule
    u0 = ForwardDiff.value(u)
    y0 = c_lookup(tb, u0)
    h  = sqrt(eps(u0))                                          # or a step the table's grid suggests
    dy = (c_lookup(tb, u0 + h) - y0) / h
    return ForwardDiff.Dual{Tag}(y0, dy * ForwardDiff.partials(u))
end
```

The stripping happens mid-expression, which [§9.5][s9-5] leaves legal at an unpinned
leaf, and the partials are rebuilt by the chain rule, so the seeded pass sees
the component as an ordinary differentiable one. The derivative is
finite-difference in quality on this one component and exact everywhere
else. Where an analytic slope is available, it goes in the same place.

This is why linearization keeps one mechanism and no perturbation-based
fallback ([D-266][d-266]). Every stage is a pure map, so the local rule always
exists; it puts the cost on the opaque component alone rather than on every
model that contains it; and differencing one lookup at a step chosen with
knowledge of its grid is better conditioned than differencing the whole
nonlinear model at one global step.

## 6. The shape rule's limit

The per-parameter pin, `Mixed{Float64, Pinned{Float64}}`, is refused
([D-265][d-265]). A field that must not follow the scalar is typed concretely in its
struct instead:

```julia
struct Mixed{T}          # a walks, b is a count: pinned as Int leaves always are
    a::T
    b::Int
end

struct MixedRight{T}     # a walks, b is frozen for every user of the type
    a::T
    b::Float64
end
```

`MixedRight{Float64}` walks to `MixedRight{Dual}` with leaves `Dual` and
`Float64`, because the walk substitutes type parameters and never fields.
The struct's own constructor enforces the freeze on the producer side: a
stage that hands a `Dual` for `b` dies in `convert(Float64, ::Dual)`, which
has no method. What the concrete field cannot express is a freeze that
differs per declaration, the same struct with `b` walking in one component's
contract and pinned in another's. That is the recorded limit. In practice a
field that must not walk is frozen by nature, a count, a mode flag, a
calibration constant, a reference to build-time data, and the struct
definition is where a reader expects to learn it. A whole leaf that must
freeze in one component alone takes the marker, `Pinned{Mixed{Float64}}`.

One consequence for the reader's rule. "Every `Float64` position follows the
scalar" reads the declaration as written, the type expression
`MixedRight{Float64}`, not the fields in the struct body. A reader of the
contract cannot see that `b` is frozen without opening the struct. [D-263][d-263]
accepted that in exchange for one walk rule instead of two.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-237]: ../decisions.md#d-237--classify-a-non-isbits-immutable-port-type-as-one-opaque-leaf
[d-263]: ../decisions.md#d-263--one-arity-on-both-tiers-plain-contracts-the-pinned-marker-and-the-mandatory-store
[d-264]: ../decisions.md#d-264--admit-a-frozen-opaque-leaf-at-a-tolerant-entry
[d-265]: ../decisions.md#d-265--read-the-pinned-marker-at-the-top-of-an-entry-alone
[d-266]: ../decisions.md#d-266--two-doors-for-an-ad-opaque-implementation-the-local-rule-and-the-freeze-block
[s13-7]: ../spec.md#137-tooling-consequences-face-routes-and-the-component-library
[s14-10]: ../spec.md#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s4-4]: ../spec.md#44-function-valued-signals-environment-access
[s6-1]: ../spec.md#61-connections-and-hierarchy
[s8-2]: ../spec.md#82-the-declaration-inventory
[s9-5]: ../spec.md#95-the-always-on-conformance-check
