### 8.5 Assembly declaration: type-based, class by declaration shape

This section states how an [assembly](#g-assembly) (a [component](#g-component) of pure composition) is
declared, how a type's declarations mark it as an assembly or a primitive, what
arity those declarations take, how container fields contribute children, and how
`Group` assembles components on the fly.

**An assembly is a plain struct** ([D-039][d-039]). Its fields whose type is
`<: AbstractComponent` are its children, and all its other fields are inert
parameters.

Field names are path segments. Substitutability and variants use ordinary
parametric fields, exactly the shape of `Cessna172X{K, A}`, Flight.jl's Cessna
172 model. Alongside the struct come the well-known declarations.
`inner_connections(::A)` is mandatory even when empty, and
`u_connections(::A)`, `y_connections(::A)` and `sample_times(::A)` join it.
One more is optional, `transparent_container(::A)`, with default `nothing`.
Naming a container field there drops that field's segment from its children's
names, as "Container children" below states.

#### Class by declaration shape

**There is no `AbstractAssembly`, only one root `AbstractComponent`** ([D-039][d-039]). Two
reasons rule out a supertype for [class](#g-class) (a component's primitive-vs-assembly
status). First, the domain hierarchies have to carry both classes. In an
aircraft library, for example, these are `AbstractAircraft` and the engine
families. A field declared `E <: AbstractEngine` must accept a primitive
`PistonEngine` and a composite turbofan assembly alike. Second, class is
implementation detail behind the [contract](#g-contract) (a component's declared interface,
[§8.3][s8-3]).

Class is declared instead by *which* well-known declarations a type defines.
**`inner_connections` is the marker**, mandatory even when empty, and defining
it makes an assembly ([D-039][d-039]). Any leaf declaration makes a primitive.
The leaf declarations are `x_init`/`s_init`/`m_init`, `ws_init`,
`u_types`/`y_types`, `state_events`, and any stage, `x_deriv`, `s_update` or
`x_projection` method.

The rule is total. A `<: AbstractComponent` type declaring neither family has no
class to read. It is a build error, `ClassUnreadable`, naming both families,
rather than a silence that fails later and elsewhere. When the type has
component-typed fields, that error sharpens into a [did-you-mean](#g-did-you-mean) (the offending
name plus the list-in-hand it should have matched). Its message reads "holds
components but declares no `inner_connections`". `inner_connections` plus any
leaf declaration on one type is a build error as well, `ClassMixed`.

Assemblies have no state of their own, which is the no-atomic-assemblies rule
at declaration time ([§10.5][s10-5]). They have no contract of their own
either. An assembly's [faces](#g-face) (the names its ports wear on its
boundary) are derived from its children ([§8.6][s8-6]).

Reading which declarations exist is reading declarations. It is the same move
as visibility-by-declaration-site ([§8.3][s8-3]), not the banned
inference-by-evaluation ([§8.1][s8-1]).

#### One arity on both tiers

Class fixes *which* declarations a type may define, and nothing about their
shape. Every declaration of a structural fact takes the component alone, on a
leaf of either [tier](#g-tier) (continuous or discrete) and on an assembly
alike. The one exception, the allocator's scalar, is the same on both tiers
([§7.3][s7-3], [D-263][d-263]). The tier is read from the store every leaf
declares ([§8.2][s8-2]). That section states the arity rule and tier agreement
in full. A declaration on the wrong tier is `DeclarationOnWrongTier`
([Appendix C][sC]).

#### Container children

**A field whose type is a `Tuple` or `NamedTuple` with *every* element
`<: AbstractComponent` contributes its elements as [container children](#g-container-children)** ([D-085][d-085]).
They are path-named `"field/1"…"field/N"` for a tuple and `"field/key"` for a
NamedTuple, and declaration order governs layout.

**Containers are transparent grouping, not assemblies** ([D-085][d-085]). They
have no contract, no `inner_connections`, no [rate scope](#g-rate-scope) (an
assembly's `sample_times` declaration) and no existence beyond the path
segment. The elements are children *of the parent*. The parent's
`inner_connections`, `u_connections`, `y_connections` and `sample_times`
address them by element name. Anything wanting its own wiring or faces
declares itself an assembly.

The payoff is parametric composition. `struct Formation{NT <: NamedTuple};
aircraft::NT; … end` holds any roster per instantiation, of any size, with any
names and mixed aircraft types. Its declaration bodies generate wires by
comprehension over the keys. That is the arity-via-computed-contracts pattern
[§6.2][s6-2] uses for `SumJunction{W, N}`, here at structure scale. The swarm
worlds ([§14.9][s14-9]) consume it directly. So does [mounting](#g-mounting), the relocation of a
whole problem or tap set with [`at`](#g-at)`("aircraft/red", problem)`.

**A component may declare at most one of its container fields
name-transparent** ([D-211][d-211]). The declaration is

```julia
transparent_container(::MyType) = :field
```

That field's elements are then contributed under their bare keys, `"key"` and
`"1"` in place of `"field/key"` and `"field/1"`. The bare keys apply everywhere a
child name appears, namely in wiring endpoints, `sample_times` keys, read paths,
`at` prefixes and diagnostics ([D-211][d-211]).

Naming is the only thing the declaration changes. The elements are the
parent's children exactly as before, laid out in declaration order. The
container keeps its transparency of contract, with no `inner_connections`, no
faces and no rate scope.

The edges of the container form are fixed by rule.

- A container mixing component and non-component elements is a build error in
  this section's did-you-mean family ([D-085][d-085]). The error is `ContainerMixed`.
  All-component elements are children, and zero-component elements are inert
  parameter data.
- Containers of containers are rejected in the first cut, because deeper
  grouping is what assemblies are for ([D-085][d-085]). The element whose
  value is itself a component-bearing container is named, with its type
  (`ContainerNested`).
- Empty containers are legal and contribute zero children, so parametric code
  needs no special case ([D-085][d-085]).
- Abstract element types follow the same concreteness discipline as plain
  fields. They are directly concrete, or concrete through type-parameter
  bounds. That is the [generic holding](#g-generic-holding) (a parent holding
  a child through a non-concrete field type) that [§8.8][s8-8] allows.
- **A bare key from a name-transparent container colliding with any sibling
  child name is a build error naming both** ([D-211][d-211]). The error is
  `ChildNameCollision`. The `sample_times` sugar of [§8.7][s8-7], where a container's bare
  field name keys one declaration for all its elements, leaves only one
  ambiguity. A transparent element's bare key equal to its own field's name
  joins this collision error ([D-215][d-215]).
- **A bare key equal to the name of a sibling *container field* that
  contributes children is refused the same way** ([D-212][d-212]). No child
  bears that name, but the key would shadow the container's `"field/key"`
  segment grammar ([§6.1][s6-1]). Its elements would be unreachable behind a
  diagnostic that blames the wrong child. **An empty field reserves nothing**
  ([D-212][d-212]), because it reaches no children and its value cannot be
  told from empty inert parameter data. The judgment is therefore
  per-instantiation, like every wiring judgment.
- `transparent_container` must name a container field of the type, and a name
  that matches none is `TransparentContainerUnknown` ([D-211][d-211]). Declaring two
  transparent containers on one type is a declaration error ([D-211][d-211], [D-215][d-215]).

#### `Group`: the on-the-fly assembly

The *immutable* version of grouping components by plain calls needs no builder
(`Assembly()` plus `add!`/`connect!`, rejected below). It is already expressible
under this section's rules. **`Group` expresses it as a single library component**,
part of the starting inventory ([§13.7][s13-7], [D-184][d-184]). A `NamedTuple` field's elements
are its children by the container rule, name-transparent so they go by bare key
([D-211][d-211]). Its declarations are ordinary functions of the *instance*, free to read
its fields.

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

`Group` is one type, defined once, and every ad-hoc topology is a *value* of it.
The type parameters still carry the children's concrete types, so activation is
unchanged. So is the [executor](#g-executor), the compiled form of the stage execution order
([§9.7][s9-7]). Wiring validation, did-you-mean errors and the two-producers error all
run at build against the instance exactly as for a named assembly.

What is given up relative to a named type is exactly what named types are
*for*. That is dispatching domain code on `::Cessna172X`, and a reusable
identity for the topology. The exploratory and programmatic composition
`Group` serves does not want it anyway.

**The builder (`Assembly()` plus `add!`/`connect!`) is rejected**
([D-039][d-039]). Its one real advantage, programmatic generation, survives
intact in the type-based form. A declaration is an ordinary function body, and
loops and comprehensions build the returned tuple.

The reach of the builder rejection is fixed by [D-184][d-184]. It targets
mutable recipes, not type-based *semantics*. `Group` is the library's
anonymous assembly form beside the named types, shipped the way Julia ships
anonymous functions alongside named ones. It serves the model assembler (the
persona for whom topology is data rather than a named type, [§13.7][s13-7])
with a library addition that rests on one opt-in declaration,
`transparent_container` ([D-211][d-211]). With that declaration, a `Group`'s
wiring and rate declarations read exactly like a named assembly's, child and
face, with no `children/` boilerplate.
