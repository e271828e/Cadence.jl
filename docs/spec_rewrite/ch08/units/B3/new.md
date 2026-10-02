#### Output contracts: `y_types`

`y_types` declares the public port contract, and it declares it by type.
Like `u_types`, it is written at nominal `Float64`, takes the component alone
on both tiers, and is walked on the continuous tier. The input side is read
permissively, but this side is read literally. An entry states what the cell
*carries*, not what it tolerates.

On a continuous producer the declaration is spelled as follows.

```julia
y_types(::Engine) = (M_shaft = Float64, P = Float64, ω = Float64)
```

The cell types at an activation are that declaration retyped at the
activation's `T` by the leaf walk ([D-079][d-079], [D-263][d-263]). On a
discrete producer the same spelling pins wholesale. That is the discrete
exemption ([§7.2][s7-2]), enforced by tier. The leaf's tier decides which
reading applies, never the contract's shape. The tier is declared by the
leaf's store (above and below).

Semantics are literal once the walk has run. The cell type is the retyped
declaration, with nothing inferred. Participation is therefore authored per
leaf and legible on the page. The leaf forms read as follows.

- `Float64`, alone or as a type parameter (`SVector{3, Float64}`,
  `RQuat{Float64}`, `MyStruct{Float64}`), means the leaf participates
  ([D-263][d-263]). Its cell carries the activation scalar. Value parameters
  are structure rather than number, and they never take it ([D-079][d-079]).
  The bounds in `Ranged{Float64, -1, 1}` are not scalars to re-type. `RQuat`
  and `Ranged` are domain wrapper types ([§7.1][s7-1]).
- `Pinned{P}` means the leaf is deliberately pinned, and the pin is
  schema-visible. The wrapper is stripped at nominal, so the cell is `P` at
  every activation. It is whole-leaf freezing, declared and
  conformance-checked. That delivers the recorded freeze door
  ([§14.10][s14-10]). Declare `Pinned{Float64}` and strip with
  `ForwardDiff.value` inside the stage ([D-286][d-286]). The stop-gradient is
  then stated in the contract instead of buried mid-expression. The marker
  sits at the top of the entry and nowhere below it ([D-265][d-265]).
- `Int`/`Bool`/enum leaves and reference-typed fields pin ([D-079][d-079]).
  The grid of a bulk-data handle ([§4.4][s4-4]) is frozen build-time data,
  never activation-dependent. The walk never reaches it, because references
  are fields and the walk substitutes type parameters alone. A handle
  carrying a scalar *parameter* walks like any type, and one built from
  build-time data is declared `Pinned` ([D-237][d-237], [D-263][d-263]).
- A mutable type's parameters pin by rule ([D-263][d-263]). No stage can
  produce a `Vector{Dual}` inside a handle without copying the grid at every
  evaluation, so there is no choice for a marker to record.

**A handle keeps its bulk at `Float64` and its activation-dependent part in
the parameter** ([D-263][d-263]). The rule reads off the shape. References are
fields, so a grid typed `Matrix{Float64}` stays frozen at every activation,
and a pose typed `T` follows the scalar. The `DeckField` sketch has both.

```julia
struct DeckField{T}
    heave::T                 # pose: follows the activation scalar
    pitch::T
    grid::Matrix{Float64}    # geometry: frozen build-time data, never re-typed
end
```

Inside a query nothing converts the grid. Each product of a grid entry and a
`Dual` weight promotes on its own. The query's result therefore carries the
pose's partials and the interpolant's slope, while the grid is read as it was
loaded. A `Matrix{T}` grid would give the same numbers at the cost of a copy
per evaluation. That is the copy the mutable-parameter rule above refuses.

The producer pins the handle when it is built from build-time data alone, as
for a static terrain. It leaves the handle walking when its parameters come
from state, as for a moving ship deck, whose heave and pitch are continuous
state. A field that must never follow the scalar is typed concretely in its
struct, `b::Float64` beside `a::T`, which freezes it for every user of the
type. The marker pins a whole leaf, and a pin on one parameter of one
declaration is not offered ([D-265][d-265]). The rule "every `Float64`
position follows the scalar" reads the declaration as written, so a
concretely typed field is frozen without appearing in the contract
([D-265][d-265]). The walkthrough `handle_walk_walkthrough.md` works a static
terrain and a moving deck through one consumer.

A custom struct is a first-class port type, as in
`contact = GearContact{Float64}`, under the scoping that [§7.2][s7-2]
establishes. Here `GearContact` is a landing-gear contact. That scoping
requires a struct parametric in its real-scalar leaves, with constructors
inferring the scalar. A participating struct leaf is declared with `Float64`
in its parameter position, `GearContact{Float64}`. The walk retypes it there,
recursively for nested parameters ([D-263][d-263]). A struct with a
hardcoded `Float64` field offers no such position. The walk therefore leaves
it as written, a pinned leaf by shape, and `Pinned{GearContact}` says so on
the page. Any `Dual`-carrying construction then fails inside the stage with
an `InexactError` naming the offending constructor. That is the CI invariant
of [§7.2][s7-2], reached through the declaration layer with no extra
machinery.

The companion obligation is constructibility at `T`. **A declared type must
be buildable at the activation scalar** ([D-079][d-079]). The `Dual` probe
enforces it by construction. The probe builds real values, so a type whose
constructor cannot accept them fails at the probe with its own name in the
message.

During a generic sweep, gated-off discrete producers hold their `Float64`
values. Consumers gather mixed tuples, and promotion does the rest. That is
semantically exact ([D-079][d-079]). A frozen discrete output is a constant
with zero partials. That is precisely what "linearize the continuous dynamics
with the discrete state held" means. The frozen cell is not an AD limitation
on the signal path. It is the true zero of an instantaneous dependence the
hybrid semantics never had (`frozen_discrete_walkthrough.md`).

The embedding guarantee ([§9.5][s9-5]) makes the mixing safe. It is keyed on
walking leaves ([D-238][d-238]). A `Float64` observed at a walking leaf under
a non-nominal activation implies that no `Dual` entered its computation. The
reason is that promotion is airtight and there is no lossy cast. Its true
derivative along every seeded direction is therefore zero, and embedding it
as a zero-partial constant is exact.

Piecewise branches returning literal constants (`flow > 0 ? f(x) : 0.0`) are
legal as written, because zero partials are the derivative of a
locally-constant branch ([D-194][d-194]). Which *invocation* carries
partials is still chosen by seeding ([§14.10][s14-10]), never by typing
([D-079][d-079]). The declaration says which leaves *can* carry them, and the
seed says which directions do.

The misplaced-pin account is stated openly here. A leaf that really
participates cannot be declared frozen by habit, because the habitual
spelling, a bare `Float64`, walks ([D-263][d-263]). What remains is
deliberate. An author writes `Pinned` at a leaf that really participates, or
omits it at one that really does not.

**The first bug lurks, but is never silent** ([D-286][d-286]). No lossy
`Dual → Float64` cast exists, so the first `Dual` activation of that
component fails. It fails at that activation's own lazy compile
([§9.4][s9-4]), not at `build(world)`. The message carries the didactic hint
("if `F` participates in differentiation, remove its `Pinned`"), because an
observed `Dual` at a pinned leaf has exactly one honest cause. The second bug
fails at the same activation. It fails inside the stage where the frozen
internals meet a `Dual`, or at the identity comparison on an opaque leaf
built from build-time data ([§9.5][s9-5]).

Both lurks are contained by policy rather than machinery. The test suite
builds a `Dual` activation of every component ([D-280][d-280]). That is the
exhaustive set that [§9.4][s9-4] defines. An activation is derived from the
nominal one, and it is cheap enough to make this policy unremarkable in CI.
What the plain form buys in exchange is one convention. Every declaration in
the framework is read with the same walk rule, and a genuinely frozen leaf
still says so on the page ([D-263][d-263]).

The stores are walked by the same rule, with no marker ([D-263][d-263]). The
type derived from `x_init` is walked. Real leaves and `Real` type parameters
follow the activation scalar. `m_init` and `s_init` pin wholesale, mirroring
the discrete-producer rule. `Pinned` has no place in a store, because
[§7.1][s7-1] admits no pinned state leaf for it to mark. Declared `Float64`
initial values embed as zero-partial constants under non-nominal activations
([D-079][d-079]). That is the rule for `Float64` condition leaves
([§14.3][s14-3]) applied to the defaults those conditions overlay.

Walking `x_init` presupposes the closed leaf vocabulary that [§7.1][s7-1]
fixes, scalars and `SArray`s at the common eltype ([D-094][d-094]). On the
discrete tier, the stores answer to the isbits rule of [§7.3][s7-3], checked
field by field ([D-231][d-231]). The structure step checks both vocabularies
([§9.1][s9-1]). It reports a failure in the didactic style, as these messages
show.

- "`x_init` field `gear_count::Int` is not a continuous state — integers,
  `Bool`s and enums belong in `m_init`";
- "`x_init` field `q_nb::RQuat` is not a state leaf — declare the `SVector{4}`
  backing and cast where rotation semantics are wanted ([§7.1][s7-1])";
- "`x_init` field `pose::NamedTuple` is not a state leaf — a field is one
  scalar or `SArray`; split it into fields, structure comes from the component
  tree ([§7.1][s7-1])";
- "`s_init` field `label::String` is not a store value — store fields are
  isbits or `Symbol`s; text and bulk data belong on the component instance
  ([§7.3][s7-3])".
