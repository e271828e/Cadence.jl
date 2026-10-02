## 8. The declaration layer: components and assemblies

This chapter says how an author spells a [component](#g-component). It covers
where the structural facts live, what the build takes as authoritative, and
what is checked against what. [§8.1][s8-1]–[§8.4][s8-4] cover the component
side, and [§8.5][s8-5]–[§8.8][s8-8] the [assembly](#g-assembly) side. On the
component side, [§8.1][s8-1] lays the foundations of the declaration layer,
[§8.2][s8-2] lists the declaration inventory, [§8.3][s8-3] says what a
contract makes visible, and [§8.4][s8-4] gives the five failure walkthroughs
that ground error locality. On the assembly side, [§8.5][s8-5] covers assembly
declaration and how a type's class is read, [§8.6][s8-6] covers paths, wiring
and faces, [§8.7][s8-7] covers rate scopes, and [§8.8][s8-8] covers computed
connections and generic holding. The build pipeline is [§9][s9], and the
stopped-sim service spellings are [§14][s14]. The concrete syntax below is
near-final in shape but still illustrative in spelling.

### 8.1 Position: a declarative trait layer in plain Julia, no macros

A [component](#g-component) is authored in ordinary Julia. Its
[stage functions](#g-stage-function) are ordinary multiple-dispatch methods.
They are `y_state` and `y_direct`, the two output stages every component
provides on either [tier](#g-tier) (the continuous or discrete side of the
hybrid formalism). The methods follow the `GUI.draw!` precedent, the
per-component panel extensions in FlightCore's style ([§11.7][s11-7]). A
component's structural facts are declared through a small set of well-known
functions returning plain values, defined alongside those methods.

Five questions about that layer are settled here, one per subsection. What
does it rule out, and what does it still admit (macros)? Which of declaration
and evaluation is authoritative (the schema)? What may a component's
[contract](#g-contract) (its declared interface) depend on (the type)? How do
an author's methods reach the framework's generic functions, and how can they
silently fail to (the namespace)? And what grammatical shape does each name
on the framework's surface take (names)?

#### Plain Julia, not a macro DSL

**There is no macro DSL** ([D-032][d-032]). The debugging, tooling and
comprehension criterion ([§1][s1]) decides it.

Redundancy between declarations and function bodies is accepted deliberately,
under one non-negotiable condition. Every inconsistency fails loudly, at
build time where possible and at first execution otherwise ([D-032][d-032]).

**A convenience macro remains addable a posteriori** as pure sugar, on the
`@kwdef` precedent, and never becomes essential ([D-032][d-032]). The reason
is that a macro can only ever *lower to* a layer like this one.

The door stays open for the declaration layer specifically. A macro generating
the well-known declarations is admissible sugar *on top of* the plain-Julia
forms. It is never a replacement for them and never required to author a
component ([D-032][d-032]). Every rule in this part is stated over the
generated methods, so a macro that lowers to them adds convenience and no
semantics.

#### Declarations are the schema authority

**Declarations *define* the model's structure** ([D-032][d-032]). Evaluation
*checks* conformance against them, never the reverse.

The build [probes](#g-probe) user functions with real values, with no reliance
on compiler inference, and compares observed against declared. The same
comparison then runs on every subsequent evaluation for free, as a
`NamedTuple`-type check that constant-folds away when conformant.

Inference-by-evaluation as schema authority is rejected on three counts,
established by walkthrough ([§8.4][s8-4]) and litigated in [D-032][d-032].
Types come by declaration, values by execution, and conformance by comparison.

#### Contracts are functions of the type

**A leaf's contract declarations must be determined by the component's
type**, its type parameters included, and never by its field *values*
([D-033][d-033]). Those declarations are `u_types`, `y_types` and
`state_events`, and the shapes of `x_init`/`s_init`/`m_init`.

The value-discarding signature `u_types(::Engine)` is the visible form of the
rule. The idiom for a contract that genuinely varies is the type parameter,
not the field, as in `SumJunction{Wrench, 3}` ([§6.2][s6-2]) and `Or{N}`
([§13.7][s13-7]). Arity is spelled in the type, at the price [§6.2][s6-2]
states openly.

The entry typing decides it ([§9.7][s9-7]). A component's
[bundle](#g-bundle) is the `NamedTuple` of zero-copy views a component
function receives, and its key set *is* its contract's. An entry of the
[executor](#g-executor), the compiled form of the stage execution order,
carries what selects code in type parameters and what is plain data in fields.
A key set derivable only from field values would therefore have to go one of
two ways. It could climb into the type parameters anyway, multiplying
specialization and changing the cost model ([§9.7][s9-7]) of
[chunking](#g-chunking), the splitting of a large phase body into statically
typed chunks. Or it could sit in fields, dissolving the static typing that
the zero runtime graph logic ([§5.1][s5-1]), the allocation invariant
([§7.5][s7-5]) and the fold-away conformance test ([§9.5][s9-5]) all rest on.

The build reads each declaration once, against the concrete instance, so a
value-dependent contract does not announce itself. This is a rule authors keep,
not a check the build can run.

`ws_init` is the one exception, and explicitly so ([D-033][d-033]). It is the
by-allocation convention ([D-077][d-077]), an allocator the framework *calls*
rather than a schema it *walks*. It legitimately takes sizes from the instance
(`ws_init(c::KF, ::Type{T})` reads `c.n`, [§7.3][s7-3]), because no entry type
is derived from it.

#### The namespace

**The framework's extensible functions are extended, not called**
([D-117][d-117]). Authoring a component means adding methods to
framework-owned generic functions.

Julia admits that only through an explicit per-name `import`, or through a
qualified `Cadence.x_deriv(…) = …` definition. The latter is the `Base.show`
idiom that the exported-name audit in `pending.md` records for the
extension-only periphery surface. A component module therefore opens with

```julia
import Cadence: x_init, s_init, m_init, ws_init, u_types,
    y_types, state_events, y_state, y_direct, x_deriv,
    s_update, x_projection, inner_connections, u_connections,
    y_connections, sample_times, transparent_container
```

The explicit list is needed because `using Cadence` alone is a silent trap.
After a bare `using`, `x_deriv(eng::Engine, …) = …` defines a new, unrelated
`MyModule.x_deriv`, with no error and no warning. The declarations are
deliberately unexported ([D-117][d-117]). A bare `using` therefore brings no
name into scope for the definition to clash with, so there is nothing for the
language to detect.

Left alone, the build would see a component with no `x_deriv` method. It would
report a *modeling* diagnostic, `StoreWithoutUpdate` (a non-empty store
without its update law, [§8.2][s8-2]). When the whole inventory was shadowed,
it would report `ClassUnreadable` (no declaration to read a class from,
[§8.5][s8-5]). A one-line namespace mistake would be reported far from the
line that caused it. That is the inversion of
[error locality](#g-error-locality) (the property that a mistake fails at the
site of the mistake) that [§8.4][s8-4] traces, arriving through the namespace.

Two mitigations apply, both normative. The first is that the import list above
is authoring surface, stated wherever a component file is first shown
([D-117][d-117]). The second is a shadowing check. **The structural walk
runs the shadowing check on every component before its class is read**
([§9.1][s9-1], [D-246][d-246]).

The check looks for a binding of a family name (a name in the import list
above) in the component's parent module. If the module holds one distinct from
the framework's function, **the build throws `DeclarationShadowed` alone**
([D-246][d-246]). The diagnostic names the module, the foreign names and the
missing import. Its message reads "`MyEngine`'s module defines its own
`x_deriv`, distinct from `Cadence.x_deriv`; add `import Cadence: x_deriv`".

The check is a two-line `isdefined`/`!==` test on the family's names. Those
names are distinctive by design ([D-220][d-220]), so a foreign binding of one
of them in a component's module is evidence of the missing import, not a
coincidence. The check throws alone because nothing the module declares can be
trusted. Every declaration it holds may have gone to a foreign function, and a
walk past it would only report cascades of the one cause. It runs on every
component rather than only where an absence is noticed, because an optional
declaration such as `state_events` or `sample_times` has no absence to notice.
Shadowed, it would drop its feature silently.

A convenience macro expanding to the import list remains addable a posteriori
as sugar, per this section's macro doctrine. A re-export submodule is not an
alternative ([D-117][d-117]).

The same trap has a local-scope sibling ([D-164][d-164]). Written inside a
`let`, a function body or a `@testset`, `y_state(::MyComp, (; x)) = …` does
not add a method to the global `y_state`. It binds a *new local function* of
that name. Calls within the block resolve to it and look correct. The generic
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
its block. The mitigation therefore sits at the other end. **A component that
declares nothing and defines no stage is rejected at build time**
([D-164][d-164]), because an inert component is unwritable on purpose. The
refusal is `ClassUnreadable` ([§8.5][s8-5]). That check costs a line, and it catches
the misspelled-declaration family with it.

Test code is the realistic victim, with a fixture component defined inside its
own `@testset`. The authoring rule is one line. **Declarations live at module
top level** ([D-164][d-164]).

The net also holds when only a stage is shadowed, because `y_types` is still a
declaration. A component whose [ports](#g-port) (its declared, addressable
names) are declared but whose stage went to a local binding reads as "declared
but not produced" ([§8.3][s8-3]). It does not read as a component with nothing
to say. An optional declaration shadowed in a local scope, such as
`state_events` or `ws_init`, drops its feature silently ([D-178][d-178]).

#### Names

**Every name on the framework's surface belongs to one of four classes**, and
its class fixes its grammatical shape ([D-144][d-144]).

1. Declarations are noun phrases naming what they return, prefixed by the
   bundle field they define where one exists ([D-267][d-267]). An assembly's
   boundary declarations take `u` and `y` too. There the letter names a side
   of the contract, which on a leaf is also a bundle field ([D-279][d-279]).
   The author defines them and the framework calls them. They include
   `inner_connections`, `u_connections`/`y_connections`, `state_events`,
   `u_types`, `ws_init`, the stage and update-law names ([D-220][d-220]), and
   `claims(b)` from the [binding](#g-binding) interface ([§11.6][s11-6]). A
   binding is the value passed at `attach!` that makes a device
   framework-legible.
2. Value selectors carry `get_`. They are called against `reads` and against
   [snapshots](#g-snapshot), the immutable per-boundary publications
   ([§14.4][s14-4]).
3. Lifecycle and mutating actions are verbs, with `!` when they mutate.
4. Build primitives are plain verbs ([§13.3][s13-3]).

A name in the wrong class is a rename candidate on that ground alone.

The convention also has a semantic axis. A name can sit in the right class and
still pick the wrong noun. **A declaration names the *consequence* it has**, not
its *content* ([D-146][d-146]). `input_passthrough` ([§8.8][s8-8],
[D-171][d-171]) and the binding methods `claims`/`reads` ([§11.6][s11-6],
[D-146][d-146]) apply that axis, and `exports` is its retired exemplar
([D-170][d-170]). The `*_connections` family names content deliberately, for
authoring transparency. That is a recorded choice, not class drift.

Which names the module exports is a separate question. It stays open until
the exported-name audit in `pending.md` runs ([D-226][d-226]).
