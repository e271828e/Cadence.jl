### 8.5 Assembly declaration: type-based, class by declaration shape

**Rule.** An [assembly](#g-assembly) is a plain struct. Fields whose type is
`<: AbstractComponent` are its children, and all other fields are inert
parameters.

Field names are path segments. Substitutability and variants use ordinary
parametric fields, exactly today's `Cessna172X{K, A}` shape. Alongside the
struct come the well-known declarations: `inner_connections(::A)`, mandatory
even when empty, plus `u_connections(::A)`, `y_connections(::A)` and
`sample_times(::A)`. One more is optional, `transparent_container(::A)`,
default `nothing`. Naming a container field there drops that field's segment
from its children's names, the rule the next subsection states.

#### Container children

**Rule.** A field whose type is a `Tuple` or `NamedTuple` with *every* element
`<: AbstractComponent` contributes its elements as [container children](#g-container-children).

They are path-named `"field/1"…"field/N"` (tuples) or `"field/key"`
(NamedTuples), and declaration order governs layout. Containers are
**transparent grouping, not assemblies**. They have no [contract](#g-contract), no
`inner_connections`, no [rate scope](#g-rate-scope) and no existence beyond the path
segment. The elements are children *of the parent*, whose `inner_connections`/
`u_connections`/`y_connections`/`sample_times` address them by element
name. Anything wanting its own wiring or [faces](#g-face) declares itself an
assembly.

The payoff is parametric composition. `struct Formation{NT <: NamedTuple};
aircraft::NT; … end` holds any roster per instantiation, of any size, with any
names and mixed aircraft types, and the declaration bodies generate wires by
comprehension over the keys. That is the arity-via-computed-contracts pattern
[§6.2][s6-2] uses for `SumJunction{W, N}`, here at structure scale. The swarm worlds
([§14.9][s14-9]) consume it directly, and so does [mounting](#g-mounting), the relocation of
a whole problem or tap set with [`at`](#g-at)`("aircraft/red", problem)`.

**Rule.** A component may declare at most one of its container fields
**name-transparent**, by `transparent_container(::MyType) = :field`, default
`nothing`. That field's elements are then contributed under their bare keys,
`"key"` and `"1"` in place of `"field/key"` and `"field/1"`, everywhere a
child name appears ([D-211][d-211]): wiring endpoints, `sample_times` keys, read
paths, `at` prefixes, diagnostics.

Naming is the only thing the declaration changes. The elements are the parent's
children exactly as before, laid out in declaration order, and the container
keeps its transparency of contract, with no `inner_connections`, no faces and
no rate scope.

The edges of the container form are fixed by rule:

- A container mixing [component](#g-component) and non-component elements is a build
  error in this section's [did-you-mean](#g-did-you-mean) family (the offending name plus the
  list-in-hand it should have matched). All-component elements are children,
  and zero-component elements are inert parameter data.
- Containers of containers are rejected in the first cut, because deeper
  grouping is what assemblies are for. The element whose value is itself a
  component-bearing container is named, with its type (`ContainerNested`).
- Empty containers are legal and contribute zero children, so parametric code
  needs no special case.
- Abstract element types follow the same concreteness discipline as plain
  fields. They are directly concrete, or concrete through type-parameter
  bounds. That is the [generic holding](#g-generic-holding) (a parent holding a child through
  a non-concrete field type) that [§8.8][s8-8] allows.
- A bare key from a name-transparent container colliding with any sibling
  child name is a build error naming both. A bare key equal to the name of a
  sibling *container field* that contributes children is refused the same
  way. No child bears that name, but the key would shadow the container's
  `"field/key"` segment grammar ([§6.1][s6-1]), leaving its elements unreachable
  behind a diagnostic that blames the wrong child. An empty field reserves
  nothing, because it reaches no children and its value cannot be told from
  empty inert parameter data. The judgment is therefore per-instantiation,
  like every wiring judgment ([D-212][d-212]). `transparent_container` must name a
  container field of the type, and declaring two transparent containers on
  one type is a declaration error.

The one ambiguity this leaves, a
transparent element's bare key equal to its own field's name, joins the
bare-key collision error above.

#### The builder is rejected

The builder (`Assembly()` plus `add!`/`connect!`) is rejected ([D-039][d-039]).

Its one real advantage, programmatic generation, survives intact in the
type-based form. A declaration is an ordinary function body, and loops and
comprehensions build the returned tuple.

#### `Group`: the on-the-fly assembly

The *immutable* version of "grouping components by plain calls" needs no
builder. It is already expressible under this section's rules as a single
library component (the starting inventory, [§13.7][s13-7]). A `NamedTuple` field's
elements are its children by the container rule, name-transparent so they go
by bare key ([D-211][d-211]), and declarations are ordinary functions of the
*instance*, free to read its fields:

```julia
struct Group{C <: NamedTuple, W, I, O} <: AbstractComponent
    children::C      # component-typed elements → children by the container rule
    wires::W         # inert parameter data
    inputs::I
    outputs::O
end
inner_connections(g::Group)    = g.wires
u_connections(g::Group)        = g.inputs
y_connections(g::Group)        = g.outputs
transparent_container(::Group) = :children

Group(children; wires = (), inputs = (), outputs = ()) =
    Group(children, wires, inputs, outputs)

world = Group(
    (; plant = Plant(), ctrl = PID(kp = 2.0));
    wires = ("ctrl/u" => "plant/u", "plant/y" => "ctrl/y"),
)
```

One type, defined once, and every ad-hoc topology is a *value* of it. The type
parameters still carry the children's concrete types, so activation is
unchanged. So is the [executor](#g-executor), the compiled form of the stage execution order
([§9.7][s9-7]). Wiring validation, did-you-mean errors and the two-producer check all
run at build against the instance exactly as for a named assembly.

What is given up relative to a named type is exactly what named types are
*for*, namely dispatching domain code on `::Cessna172X` and a reusable
identity for the topology. The exploratory and programmatic composition
`Group` serves does not want it anyway.

The reach of the builder rejection is fixed by [D-184][d-184]. It targets mutable
recipes, not type-based *semantics*. `Group` is the library's anonymous
assembly form beside the named types, shipped the way Julia ships anonymous
functions alongside named ones. It serves the model assembler with a library
addition riding one opt-in declaration, `transparent_container` ([D-211][d-211]).
What that declaration buys is that a `Group`'s wiring and rate declarations
read exactly like a named assembly's, child and face, with no `children/`
boilerplate.

#### Class by declaration shape

**There is no `AbstractAssembly`, only one root `AbstractComponent`**
([D-039][d-039]).

**Why.** The domain hierarchies (`AbstractAircraft`, the engine families) have
to carry both classes. A field declared `E <: AbstractEngine` must accept a
primitive `PistonEngine` and a composite turbofan assembly alike. And class is
implementation detail behind the contract ([§8.3][s8-3]).

[Class](#g-class) (a component's primitive-vs-assembly status) is declared instead by
*which* well-known declarations a type defines. `inner_connections` is the
marker, mandatory even when empty (the `LowPassFilter` precedent), and
defining it makes an **assembly**. Any leaf declaration makes a **primitive**:
`x_init`/`s_init`/`m_init`, `ws_init`, `u_types`/`y_types`,
`state_events`, or any stage, `x_deriv`, `s_update` or
`x_projection` method.

The rule is total. A `<: AbstractComponent` type declaring neither family has
no class to read. It is a build error naming both families rather than a
silence that fails later and elsewhere. That error sharpens into a
did-you-mean when the type has component-typed fields ("holds components but
declares no `inner_connections`"). `inner_connections` plus any leaf
declaration on one type is a build error as well. Assemblies have no state of
their own, which is the no-atomic-assemblies rule at declaration time
([§10.5][s10-5]). They have no contract of their own either. An assembly's faces
are derived from its children ([§8.6][s8-6]).

Reading which declarations exist is reading declarations. It is the same move
as visibility-by-declaration-site ([§8.3][s8-3]), not the banned
inference-by-evaluation ([§8.1][s8-1]).

#### One arity on both tiers

Class fixes *which* declarations a type may define, and nothing about their
shape. Every declaration takes the component alone, on a leaf of either
[tier](#g-tier) and on an assembly alike, and the one exception, the allocator's
scalar, is the same on both tiers ([§7.3][s7-3], [D-263][d-263]). A signature
therefore never spells the tier. The tier is read from the store every leaf
declares ([§8.2][s8-2]), and the walk that retypes a continuous
leaf's contracts is applied by the build, never requested by a `T` in the
declaration. There is consequently no signature-shape violation to name. A
declaration on the wrong tier is `DeclarationOnWrongTier` ([Appendix C][sC]),
and a marker meaningful on one tier alone, `Pinned` on a discrete leaf, is the
same kind.
