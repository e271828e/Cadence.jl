import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "checks"))
from norm import norm
O = norm(open(os.path.join(HERE, "old.md")).read())
N = norm(open(os.path.join(HERE, "new.md")).read())
B1 = "units/B1/old.md"; B4 = "units/B4/old.md"
C = []
def c(old, new, tag="F", cites=None, newcites=None, where="new", ruling=None):
    d = {"id": f"D-{len(C)+1:03d}", "old": old, "new": new, "where": where,
         "cites": cites or [], "tag": tag}
    if newcites is not None: d["newcites"] = newcites
    if ruling: d["ruling"] = ruling
    C.append(d)

c("### 8.5 Assembly declaration: type-based, class by declaration shape",
  "### 8.5 Assembly declaration: type-based, class by declaration shape", "X")
c("Rule. An assembly is a plain struct.", "An assembly is a plain struct (D-039).", "C", [], ["D-039"])
c("Fields whose type is `<: AbstractComponent` are its children, and all other fields are inert parameters.",
  "Its fields whose type is `<: AbstractComponent` are its children, and all its other fields are inert parameters.")
c("Field names are path segments.", "Field names are path segments.")
c("Substitutability and variants use ordinary parametric fields, exactly today's `Cessna172X{K, A}` shape.",
  "Substitutability and variants use ordinary parametric fields, exactly the shape of `Cessna172X{K, A}`, Flight.jl's Cessna 172 model.")
c("Alongside the struct come the well-known declarations: `inner_connections(::A)`, mandatory even when empty, plus `u_connections(::A)`, `y_connections(::A)` and `sample_times(::A)`.",
  "Alongside the struct come the well-known declarations. `inner_connections(::A)` is mandatory even when empty, and `u_connections(::A)`, `y_connections(::A)` and `sample_times(::A)` join it.")
c("One more is optional, `transparent_container(::A)`, default `nothing`.",
  "One more is optional, `transparent_container(::A)`, with default `nothing`.")
c("Naming a container field there drops that field's segment from its children's names, the rule the next subsection states.",
  "Naming a container field there drops that field's segment from its children's names, as \"Container children\" below states.")
# Class section (moved up)
c("#### Class by declaration shape", "#### Class by declaration shape", "X")
c("There is no `AbstractAssembly`, only one root `AbstractComponent` (D-039).",
  "There is no `AbstractAssembly`, only one root `AbstractComponent` (D-039).", "F", ["D-039"])
c("Why. The domain hierarchies (`AbstractAircraft`, the engine families) have to carry both classes.",
  "First, the domain hierarchies (`AbstractAircraft`, the engine families) have to carry both classes.")
c("A field declared `E <: AbstractEngine` must accept a primitive `PistonEngine` and a composite turbofan assembly alike.",
  "a field declared `E <: AbstractEngine` must accept a primitive `PistonEngine` and a composite turbofan assembly alike.")
c("And class is implementation detail behind the contract (§8.3).",
  "Second, class is implementation detail behind the contract (a component's declared interface, §8.3).", "F", ["§8.3"])
c("Class (a component's primitive-vs-assembly status) is declared instead by which well-known declarations a type defines.",
  "Class is declared instead by which well-known declarations a type defines.")
c("`inner_connections` is the marker, mandatory even when empty (the `LowPassFilter` precedent), and defining it makes an assembly.",
  "`inner_connections` is the marker, mandatory even when empty, and defining it makes an assembly (D-039).", "R", [], ["D-039"], ruling="R7")
c("Any leaf declaration makes a primitive: `x_init`/`s_init`/`m_init`, `ws_init`, `u_types`/`y_types`, `state_events`, or any stage, `x_deriv`, `s_update` or `x_projection` method.",
  "Any leaf declaration makes a primitive. The leaf declarations are `x_init`/`s_init`/`m_init`, `ws_init`, `u_types`/`y_types`, `state_events`, and any stage, `x_deriv`, `s_update` or `x_projection` method.")
c("The rule is total.", "The rule is total.")
c("A `<: AbstractComponent` type declaring neither family has no class to read.",
  "A `<: AbstractComponent` type declaring neither family has no class to read.")
c("It is a build error naming both families rather than a silence that fails later and elsewhere.",
  "It is a build error naming both families, rather than a silence that fails later and elsewhere.")
c("That error sharpens into a did-you-mean when the type has component-typed fields (\"holds components but declares no `inner_connections`\").",
  "When the type has component-typed fields, that error sharpens into a did-you-mean (a name-shaped failure that carries the list-in-hand). Its message reads \"holds components but declares no `inner_connections`\".")
c("`inner_connections` plus any leaf declaration on one type is a build error as well.",
  "`inner_connections` plus any leaf declaration on one type is a build error as well.")
c("Assemblies have no state of their own, which is the no-atomic-assemblies rule at declaration time (§10.5).",
  "Assemblies have no state of their own, which is the no-atomic-assemblies rule at declaration time (§10.5).", "F", ["§10.5"])
c("They have no contract of their own either.", "They have no contract of their own either.")
c("An assembly's faces are derived from its children (§8.6).",
  "An assembly's faces (the names its ports wear on its boundary) are derived from its children (§8.6).", "F", ["§8.6"])
c("Reading which declarations exist is reading declarations. It is the same move as visibility-by-declaration-site (§8.3), not the banned inference-by-evaluation (§8.1).",
  "Reading which declarations exist is reading declarations. It is the same move as visibility-by-declaration-site (§8.3), not the banned inference-by-evaluation (§8.1).", "F", ["§8.3", "§8.1"])
# One arity (R5)
c("#### One arity on both tiers", "#### One arity on both tiers", "X")
c("Class fixes which declarations a type may define, and nothing about their shape.",
  "Class fixes which declarations a type may define, and nothing about their shape.", "R", ruling="R5")
c("Every declaration takes the component alone, on a leaf of either tier and on an assembly alike,",
  "Every declaration of a structural fact takes the component alone, on a leaf of either tier (continuous or discrete) and on an assembly alike.", "R", ruling="R7")
c("and the one exception, the allocator's scalar, is the same on both tiers (§7.3, D-263).",
  "The one exception, the allocator's scalar, is the same on both tiers (§7.3, D-263).", "F", ["§7.3", "D-263"])
c("A signature therefore never spells the tier.",
  "No arity carries a tier.", "R", where=B4, ruling="R5")
c("The tier is read from the store every leaf declares (§8.2),",
  "The tier is read from the store every leaf declares (§8.2).", "R", ["§8.2"], ruling="R5")
c("and the walk that retypes a continuous leaf's contracts is applied by the build, never requested by a `T` in the declaration.",
  "A by-type declaration walks by the same rule, and where a leaf must not follow the scalar the author says so at the leaf, with `Pinned`, which is why `u_types` and `y_types` take the component alone too.",
  "R", where=B1, ruling="R5")
c("There is consequently no signature-shape violation to name.",
  "No arity carries a tier. Every declaration takes the component alone, and `ws_init` takes the scalar on both tiers (D-263).",
  "R", where=B4, ruling="R5")
c("A declaration on the wrong tier is `DeclarationOnWrongTier` (Appendix C),",
  "A declaration on the wrong tier is `DeclarationOnWrongTier` (Appendix C).", "R", ["Appendix C"], ruling="R5")
c("and a marker meaningful on one tier alone, `Pinned` on a discrete leaf, is the same kind.",
  "It covers declaring both `x_deriv` and `s_update`, a `Pinned` entry on a discrete leaf,", "R", where=B4, ruling="R5")
# Containers
c("#### Container children", "#### Container children", "X")
c("Rule. A field whose type is a `Tuple` or `NamedTuple` with every element `<: AbstractComponent` contributes its elements as container children.",
  "A field whose type is a `Tuple` or `NamedTuple` with every element `<: AbstractComponent` contributes its elements as container children (D-085).", "C", [], ["D-085"])
c("They are path-named `\"field/1\"…\"field/N\"` (tuples) or `\"field/key\"` (NamedTuples), and declaration order governs layout.",
  "They are path-named `\"field/1\"…\"field/N\"` for a tuple and `\"field/key\"` for a NamedTuple, and declaration order governs layout.")
c("Containers are transparent grouping, not assemblies.",
  "Containers are transparent grouping, not assemblies (D-085).", "C", [], ["D-085"])
c("They have no contract, no `inner_connections`, no rate scope and no existence beyond the path segment.",
  "They have no contract, no `inner_connections`, no rate scope (an assembly's `sample_times` declaration) and no existence beyond the path segment.")
c("The elements are children of the parent, whose `inner_connections`/ `u_connections`/`y_connections`/`sample_times` address them by element name.",
  "The elements are children of the parent. The parent's `inner_connections`, `u_connections`, `y_connections` and `sample_times` address them by element name.")
c("Anything wanting its own wiring or faces declares itself an assembly.",
  "Anything wanting its own wiring or faces declares itself an assembly.")
c("The payoff is parametric composition.", "The payoff is parametric composition.")
c("`struct Formation{NT <: NamedTuple}; aircraft::NT; … end` holds any roster per instantiation, of any size, with any names and mixed aircraft types, and the declaration bodies generate wires by comprehension over the keys.",
  "`struct Formation{NT <: NamedTuple}; aircraft::NT; … end` holds any roster per instantiation, of any size, with any names and mixed aircraft types. Its declaration bodies generate wires by comprehension over the keys.")
c("That is the arity-via-computed-contracts pattern §6.2 uses for `SumJunction{W, N}`, here at structure scale.",
  "That is the arity-via-computed-contracts pattern §6.2 uses for `SumJunction{W, N}`, here at structure scale.", "F", ["§6.2"])
c("The swarm worlds (§14.9) consume it directly, and so does mounting, the relocation of a whole problem or tap set with `at``(\"aircraft/red\", problem)`.",
  "The swarm worlds (§14.9) consume it directly. So does mounting, the relocation of a whole problem or tap set with `at``(\"aircraft/red\", problem)`.", "F", ["§14.9"])
c("Rule. A component may declare at most one of its container fields name-transparent,",
  "A component may declare at most one of its container fields name-transparent (D-211). The declaration is", "C", [], ["D-211"])
c("by `transparent_container(::MyType) = :field`,", "`transparent_container(::MyType) = :field`")
c(":field`, default `nothing`.", "and its default is `nothing`.")
c("That field's elements are then contributed under their bare keys, `\"key\"` and `\"1\"` in place of `\"field/key\"` and `\"field/1\"`, everywhere a child name appears (D-211): wiring endpoints, `sample_times` keys, read paths, `at` prefixes, diagnostics.",
  "That field's elements are then contributed under their bare keys, `\"key\"` and `\"1\"` in place of `\"field/key\"` and `\"field/1\"`. The bare keys apply everywhere a child name appears, namely in wiring endpoints, `sample_times` keys, read paths, `at` prefixes and diagnostics (D-211).", "F", ["D-211"])
c("Naming is the only thing the declaration changes.", "Naming is the only thing the declaration changes.")
c("The elements are the parent's children exactly as before, laid out in declaration order, and the container keeps its transparency of contract, with no `inner_connections`, no faces and no rate scope.",
  "The elements are the parent's children exactly as before, laid out in declaration order. The container keeps its transparency of contract, with no `inner_connections`, no faces and no rate scope.")
c("The edges of the container form are fixed by rule:", "The edges of the container form are fixed by rule.", "X")
c("- A container mixing component and non-component elements is a build error in this section's did-you-mean family (the offending name plus the list-in-hand it should have matched).",
  "- A container mixing component and non-component elements is a build error in this section's did-you-mean family (D-085). The error carries the offending name plus the list-in-hand it should have matched.", "C", [], ["D-085"])
c("All-component elements are children, and zero-component elements are inert parameter data.",
  "All-component elements are children, and zero-component elements are inert parameter data.")
c("- Containers of containers are rejected in the first cut, because deeper grouping is what assemblies are for.",
  "- Containers of containers are rejected in the first cut, because deeper grouping is what assemblies are for (D-085).", "C", [], ["D-085"])
c("The element whose value is itself a component-bearing container is named, with its type (`ContainerNested`).",
  "The element whose value is itself a component-bearing container is named, with its type (`ContainerNested`).")
c("- Empty containers are legal and contribute zero children, so parametric code needs no special case.",
  "- Empty containers are legal and contribute zero children, so parametric code needs no special case (D-085).", "C", [], ["D-085"])
c("- Abstract element types follow the same concreteness discipline as plain fields. They are directly concrete, or concrete through type-parameter bounds.",
  "- Abstract element types follow the same concreteness discipline as plain fields. They are directly concrete, or concrete through type-parameter bounds.")
c("That is the generic holding (a parent holding a child through a non-concrete field type) that §8.8 allows.",
  "That is the generic holding (a parent holding a child through a non-concrete field type) that §8.8 allows.", "F", ["§8.8"])
c("- A bare key from a name-transparent container colliding with any sibling child name is a build error naming both.",
  "- A bare key from a name-transparent container colliding with any sibling child name is a build error naming both (D-211).", "C", [], ["D-211"])
c("A bare key equal to the name of a sibling container field that contributes children is refused the same way.",
  "A bare key equal to the name of a sibling container field that contributes children is refused the same way (D-212).", "F", [], ["D-212"])
c("No child bears that name, but the key would shadow the container's `\"field/key\"` segment grammar (§6.1), leaving its elements unreachable behind a diagnostic that blames the wrong child.",
  "No child bears that name, but the key would shadow the container's `\"field/key\"` segment grammar (§6.1). Its elements would be unreachable behind a diagnostic that blames the wrong child.", "F", ["§6.1"])
c("An empty field reserves nothing, because it reaches no children and its value cannot be told from empty inert parameter data.",
  "An empty field reserves nothing (D-212), because it reaches no children and its value cannot be told from empty inert parameter data.", "F", [], ["D-212"])
c("The judgment is therefore per-instantiation, like every wiring judgment (D-212).",
  "The judgment is therefore per-instantiation, like every wiring judgment.", "F", ["D-212"], ["D-212"])
c("`transparent_container` must name a container field of the type, and declaring two transparent containers on one type is a declaration error.",
  "- `transparent_container` must name a container field of the type, and declaring two transparent containers on one type is a declaration error (D-211).", "C", [], ["D-211"])
c("The one ambiguity this leaves, a transparent element's bare key equal to its own field's name, joins the bare-key collision error above.",
  "The `sample_times` sugar of §8.7, where a container's bare field name keys one declaration for all its elements, leaves one ambiguity. A transparent element's bare key equal to its own field's name joins this collision error (D-215).",
  "C", [], ["§8.7", "D-215"])
# Builder (M4)
c("#### The builder is rejected",
  "The builder (`Assembly()` plus `add!`/`connect!`) is rejected (D-039).", "M")
c("The builder (`Assembly()` plus `add!`/`connect!`) is rejected (D-039).",
  "The builder (`Assembly()` plus `add!`/`connect!`) is rejected (D-039).", "M", ["D-039"])
c("Its one real advantage, programmatic generation, survives intact in the type-based form. A declaration is an ordinary function body, and loops and comprehensions build the returned tuple.",
  "Its one real advantage, programmatic generation, survives intact in the type-based form. A declaration is an ordinary function body, and loops and comprehensions build the returned tuple.", "M")
# Group
c("#### `Group`: the on-the-fly assembly", "#### `Group`: the on-the-fly assembly", "X")
c("The immutable version of \"grouping components by plain calls\" needs no builder.",
  "The immutable version of \"grouping components by plain calls\" needs no builder (`Assembly()` plus `add!`/`connect!`, rejected below).")
c("It is already expressible under this section's rules as a single library component (the starting inventory, §13.7).",
  "It is already expressible under this section's rules. `Group` expresses it as a single library component, part of the starting inventory (§13.7, D-184).", "C", ["§13.7"], ["§13.7", "D-184"])
c("A `NamedTuple` field's elements are its children by the container rule, name-transparent so they go by bare key (D-211),",
  "A `NamedTuple` field's elements are its children by the container rule, name-transparent so they go by bare key (D-211).", "F", ["D-211"])
c("and declarations are ordinary functions of the instance, free to read its fields:",
  "Its declarations are ordinary functions of the instance, free to read its fields.")
c("struct Group{C <: NamedTuple, W, I, O} <: AbstractComponent children::C # component-typed elements → children by the container rule wires::W # inert parameter data inputs::I outputs::O end inner_connections(g::Group) = g.wires u_connections(g::Group) = g.inputs y_connections(g::Group) = g.outputs transparent_container(::Group) = :children",
  "struct Group{C <: NamedTuple, W, I, O} <: AbstractComponent children::C # component-typed elements → children by the container rule wires::W # inert parameter data inputs::I outputs::O end inner_connections(g::Group) = g.wires u_connections(g::Group) = g.inputs y_connections(g::Group) = g.outputs transparent_container(::Group) = :children",
  "R", ruling="R1")
c("Group(children; wires = (), inputs = (), outputs = ()) = Group(children, wires, inputs, outputs)",
  "Group(children; wires = (), inputs = (), outputs = ()) = Group(children, wires, inputs, outputs)", "R", ruling="R1")
c("world = Group( (; plant = Plant(), ctrl = PID(kp = 2.0)); wires = (\"ctrl/u\" => \"plant/u\", \"plant/y\" => \"ctrl/y\"), )",
  "world = Group( (; plant = Plant(), ctrl = PID(kp = 2.0)); wires = (\"ctrl/u\" => \"plant/u\", \"plant/y\" => \"ctrl/y\"), )", "R", ruling="R1")
c("One type, defined once, and every ad-hoc topology is a value of it.",
  "`Group` is one type, defined once, and every ad-hoc topology is a value of it.")
c("The type parameters still carry the children's concrete types, so activation is unchanged.",
  "The type parameters still carry the children's concrete types, so activation is unchanged.")
c("So is the executor, the compiled form of the stage execution order (§9.7).",
  "So is the executor, the compiled form of the stage execution order (§9.7).", "F", ["§9.7"])
c("Wiring validation, did-you-mean errors and the two-producer check all run at build against the instance exactly as for a named assembly.",
  "Wiring validation, did-you-mean errors and the two-producer check all run at build against the instance exactly as for a named assembly.")
c("What is given up relative to a named type is exactly what named types are for, namely dispatching domain code on `::Cessna172X` and a reusable identity for the topology.",
  "What is given up relative to a named type is exactly what named types are for. That is dispatching domain code on `::Cessna172X`, and a reusable identity for the topology.")
c("The exploratory and programmatic composition `Group` serves does not want it anyway.",
  "The exploratory and programmatic composition `Group` serves does not want it anyway.")
c("The reach of the builder rejection is fixed by D-184.", "The reach of the builder rejection is fixed by D-184.", "F", ["D-184"])
c("It targets mutable recipes, not type-based semantics.", "It targets mutable recipes, not type-based semantics.")
c("`Group` is the library's anonymous assembly form beside the named types, shipped the way Julia ships anonymous functions alongside named ones.",
  "`Group` is the library's anonymous assembly form beside the named types, shipped the way Julia ships anonymous functions alongside named ones.")
c("It serves the model assembler with a library addition riding one opt-in declaration, `transparent_container` (D-211).",
  "It serves the model assembler (the persona for whom topology is data rather than a named type, §13.7) with a library addition that rests on one opt-in declaration, `transparent_container` (D-211).", "F", ["D-211"], ["D-211", "§13.7"])
c("What that declaration buys is that a `Group`'s wiring and rate declarations read exactly like a named assembly's, child and face, with no `children/` boilerplate.",
  "With that declaration, a `Group`'s wiring and rate declarations read exactly like a named assembly's, child and face, with no `children/` boilerplate.")

added = [
 "This section states how an assembly is declared, how a type's declarations mark it as an assembly or a primitive, how container fields contribute children, and how `Group` assembles components on the fly.",
 "Two reasons rule out a supertype for class (a component's primitive-vs-assembly status).",
 "In an aircraft library, for example,",
 "That section states the arity rule and tier agreement in full.",
]
for x in C:
    if x["old"] not in O: print("OLD MISSING", x["id"], x["old"][:60])
    if x["where"] == "new" and x["new"] not in N: print("NEW MISSING", x["id"], x["new"][:60])
for a in added:
    if a not in N: print("ADDED MISSING", a[:60])
json.dump({"claims": C, "added": added}, open(os.path.join(HERE, "inventory.json"), "w"), indent=1, ensure_ascii=False)
print(len(C), "claims")
