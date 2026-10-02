## 8. The declaration layer: components and assemblies

This chapter says how an author spells a [component](#g-component). It covers where the
structural facts live, what the build takes as authoritative, and what is
checked against what. [§8.1][s8-1]–[§8.4][s8-4] cover the component side, and [§8.5][s8-5]–[§8.8][s8-8]
the [assembly](#g-assembly) side. The build pipeline is [§9][s9], and the stopped-sim service
spellings are [§14][s14]. The concrete syntax below is near-final in shape but
still illustrative in spelling.

### 8.1 Position: a declarative trait layer in plain Julia, no macros

A component is authored in ordinary Julia. Its [stage functions](#g-stage-function)
(`y_state` and `y_direct`, the two output stages every component
provides on either [tier](#g-tier)) are ordinary multiple-dispatch methods, on the
`GUI.draw!` precedent. Its structural facts are declared through a small set of
well-known functions returning plain values, defined alongside those methods.
Four questions about that layer are settled here. What does it rule out, and
what does it still admit (macros)? How do an author's methods reach the
framework's generic functions, and how can they silently fail to (the
namespace)? Which of declaration and evaluation is authoritative (the schema)?
And what may a component's contract depend on (the type)?

#### Plain Julia, not a macro DSL

**Rule.** There is no macro DSL.

**Why.** The debugging, tooling and comprehension criterion ([§1][s1])
decides it ([D-032][d-032]).

Redundancy between declarations and function bodies is accepted deliberately,
under one non-negotiable condition. **Every inconsistency fails loudly**, at
build time where possible and at first execution otherwise.

A macro can only ever *lower to* a layer like this one. A convenience macro
therefore remains addable a posteriori as pure sugar, on the `@kwdef`
precedent, and never becomes essential.

The door stays open for the declaration layer specifically. A macro generating
the well-known declarations is admissible sugar *on top of* the plain-Julia
forms. It is never a replacement for them and never required to author a
[component](#g-component) ([D-166][d-166]). The obvious candidate is the `where {T <: Real}`
ceremony of a continuous `y_types` ([§8.2][s8-2]). Every rule in this part is
stated over the generated methods, so a macro that lowers to them adds
convenience and no semantics.

#### The namespace: declarations are extended, not called

**Rule.** The framework's extensible functions are extended, not called.
Authoring a component means adding methods to framework-owned generic
functions.

Julia admits that only through an explicit per-name `import`, or through a
qualified `Cadence.x_deriv(…) = …` definition. The latter is the
`Base.show` idiom that the exported-name audit in `pending.md` records for the
extension-only periphery surface. A component module therefore opens with

```julia
import Cadence: x_init, s_init, m_init, ws_init, u_types,
    y_types, state_events, y_state, y_direct, x_deriv,
    s_update, x_projection, inner_connections, u_connections,
    y_connections, sample_times, transparent_container
```

**The explicit list is needed because `using Cadence` alone is a silent trap.**
After a bare `using`, `x_deriv(eng::Engine, …) = …` defines a new,
unrelated `MyModule.x_deriv`, with no error and no warning. The
declarations are deliberately unexported ([D-117][d-117]). A bare `using` therefore
brings no name into scope for the definition to clash with, so there is nothing
for the language to detect. Left alone, the build would see a component with
no `x_deriv` method and report a *modeling* diagnostic,
`StoreWithoutUpdate`, or `ClassUnreadable` when the whole inventory was
shadowed. A one-line namespace mistake would be reported far from the line
that caused it. That is the [§8.4][s8-4] inversion of [error locality](#g-error-locality) (the
property that a mistake fails at the site of the mistake), arriving through the
namespace.

Two mitigations, both normative. The first is that the import list above is
authoring surface, stated wherever a component file is first shown. The second
is a **shadowing check** in the structural walk ([§9.1][s9-1]), run on every
component before its class is read ([D-246][d-246]). If the component's parent
module holds a binding of a family name distinct from the framework's
function, the build throws `DeclarationShadowed`, alone, naming the module,
the foreign names and the missing import: "`MyEngine`'s module defines its
own `x_deriv`, distinct from `Cadence.x_deriv`; add
`import Cadence: x_deriv`". The check is a two-line `isdefined`/`!==`
test on the family's names. Those names are distinctive by design
([D-220][d-220]), so a foreign binding of one of them in a component's module
is evidence of the missing import, not a coincidence. The check throws alone
because nothing the module declares can be trusted. Every declaration it
holds may have gone to a foreign function, and a walk past it would only
report cascades of the one cause. It runs on every component rather than
only where an absence is noticed, because an optional declaration such as
`state_events` or `sample_times` has no absence to notice. Shadowed, it would
drop its feature silently.

A convenience macro expanding to the import list remains addable a posteriori
as sugar, per this section's macro doctrine. A re-export submodule is not an
alternative, because per-name `import` is the only *unqualified* extension
mechanism the language provides ([D-117][d-117]).

**The same trap has a local-scope sibling** ([D-164][d-164]). Written inside a `let`, a
function body or a `@testset`, `y_state(::MyComp, (; x)) = …` does not add
a method to the global `y_state`. It binds a *new local function* of that
name. Calls within the block resolve to it and look correct. The generic
function the build dispatches on never learns of the component, which
therefore reads as one declaring nothing at all.

```julia
@testset "mycomp" begin
    y_state(::MyComp, (; x)) = …   #a NEW local one, not a method of
    …                                   #Cadence.y_state; calls here
end                                     #resolve to it, and look correct
#outside: Cadence.y_state still has no MyComp method
```

The shadowing check above cannot reach this case. There is no parent-module
binding to compare, because the shadow is a local binding that disappears with
its block. So the mitigation sits at the other end. **A component that declares
nothing and defines no stage is rejected at build time**, because an inert
component is unwritable on purpose. That check costs a line, and it catches the
misspelled-declaration family with it.

Test code is the realistic victim, with a fixture component defined inside its
own `@testset`. The authoring rule is one line. Declarations live at module top
level.

The net holds under a *partially* shadowed component too, because `y_types`
is still a declaration. A component whose [ports](#g-port) are declared but whose
stage went to a local binding reads as "declared but not produced" ([§8.3][s8-3])
rather than as a component with nothing to say.

#### Names: four classes by role

**Rule.** Every name on the framework's surface belongs to one of four
classes, and its class fixes its grammatical shape ([D-144][d-144]).

1. **Declarations** are noun phrases naming what they return, prefixed by
   the bundle field they define where one exists ([D-267][d-267]). An assembly's
   boundary declarations take `u` and `y` too. There the letter names a side
   of the contract, which on a leaf is also a bundle field ([D-279][d-279]). The
   author defines them and the framework calls them: `inner_connections`,
   `u_connections`/`y_connections`, `state_events`, `u_types`, `ws_init`,
   the stage and update-law names ([D-220][d-220]), and `claims(b)`
   from the [binding](#g-binding) interface ([§11.6][s11-6]).
2. **Value selectors** carry `get_`. They are called against `reads` and
   against [snapshots](#g-snapshot) ([§14.4][s14-4]).
3. **Lifecycle and mutating actions** are verbs, with `!` when they mutate.
4. **Build primitives** are plain verbs ([§13.3][s13-3]).

A name in the wrong class is a rename candidate on that ground alone.

**The convention also has a semantic axis.** A name can sit in the right
class and still pick the wrong noun. A declaration names its *content*, never
the *consequence* the declaration has. `input_passthrough` ([§8.8][s8-8], [D-171][d-171]) and
the binding methods `claims`/`reads` ([§11.6][s11-6], [D-146][d-146]) apply that axis, and
`exports` is its retired exemplar ([D-170][d-170]). The `*_connections` family names
content deliberately, for authoring transparency. That is a recorded choice,
not class drift.

Which names the module exports is a separate question. It stays open until
the exported-name audit in `pending.md` runs ([D-226][d-226]).

#### Declarations are the schema authority

**Rule.** Declarations *define* the model's structure. Evaluation *checks*
conformance against them, never the reverse.

The build [probes](#g-probe) user functions with real values, with no reliance on
compiler inference, and compares observed against declared. The same comparison
then runs on every subsequent evaluation for free, as a `NamedTuple`-type check
that constant-folds away when conformant.

Inference-by-evaluation as schema authority is rejected on three counts,
established by walkthrough ([§8.4][s8-4]) and litigated in [D-032][d-032]. Types come by
declaration, values by execution, and conformance by comparison.

#### Contracts are functions of the type, not of the instance

**Rule.** A leaf's [contract](#g-contract) declarations (`u_types`, `y_types`,
`state_events`, and the shapes of `x_init`/`s_init`/`m_init`) must be
determined by the component's **type**, its type parameters included, and never
by its field *values*.

The value-discarding signature `u_types(::Engine)` is the visible form of
the rule. The idiom for a contract that genuinely varies is the type
parameter, not the field, as in `SumJunction{Wrench, 3}` ([§6.2][s6-2]) and `Or{N}`
([§13.7][s13-7]). Arity is spelled in the type, at the price [§6.2][s6-2] states openly.

**Why.** The entry typing decides it ([§9.7][s9-7]). A component's [bundle](#g-bundle) is the
`NamedTuple` of zero-copy views a component function receives, and its key set
*is* its contract's. An entry of the [executor](#g-executor), the compiled form of the stage
execution order, carries what selects code in type parameters and what is plain
data in fields. A key set derivable only from field values would therefore have
to go one of two ways. It could climb into the type parameters anyway,
multiplying specialization and changing the cost model ([§9.7][s9-7]) of [chunking](#g-chunking),
the splitting of a large phase body into statically typed chunks. Or it could
sit in fields, dissolving the static typing that the zero runtime graph logic
([§5.1][s5-1]), the allocation invariant ([§7.5][s7-5]) and the fold-away conformance test
([§9.5][s9-5]) all rest on.

The build reads each declaration once, against the concrete instance, so a
value-dependent contract does not announce itself. This is a rule authors keep,
not a check the build can run.

**`ws_init` is the one exception**, and explicitly so. It is the
by-allocation convention ([D-077][d-077]), an allocator the framework *calls* rather
than a schema it *walks*. It legitimately takes sizes from the instance
(`ws_init(c::KF, ::Type{T})` reads `c.n`, [§7.3][s7-3]), because no entry type
is derived from it.
