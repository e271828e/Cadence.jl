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
### 8.2 The declaration inventory

One continuous primitive, declared end to end:

```julia
struct Engine <: AbstractComponent
    ω_idle::Float64; ω_min::Float64; J::Float64      #parameters: plain struct fields
    ω_rated::Float64                                 #unread here; §14.2's shipped condition uses it
end

#state stores: declared by initial value — types derived, nothing to drift
x_init(::Engine) = (ω = 0.0,)
m_init(::Engine) = (phase = off,)                    # off | starting | running

#input contract: each entry states what may arrive; a Float64 leaf walks with the activation
u_types(::Engine) =
    (throttle = Float64, starter = Bool, fuel_available = Bool, M_load = Float64)

#output contract = the public interface (§8.3); Float64 walks, Pinned{Float64} would freeze a leaf
y_types(::Engine) = (M_shaft = Float64, P = Float64, ω = Float64)

#stage and update functions destructure their bundle by name (§5.2)
y_state(::Engine, (; x)) = (; ω = x.ω)          #exposing a state field is one line (§5.3)

function y_direct(eng::Engine, (; x, m, u))
    M_shaft = m.phase === running ? torque_law(eng, u.throttle, x.ω) : zero(x.ω)
    return (; M_shaft, P = M_shaft * x.ω)
end

x_deriv(eng::Engine, (; x, y, u)) = (ω = (y.M_shaft - u.M_load) / eng.J,)

#events: ordered and named — order matters (§5.3, §10.6); detection policy by the guard's return type (§2.1)
state_events(::Engine) = (
    start    = StateEvent(start_guard, start_handler),        # boundary-detected: Bool guard
    ignition = StateEvent(ignition_guard, ignition_handler),  # boundary-detected: Bool guard
    flameout = StateEvent(flameout_guard, flameout_handler))  # localized: sign-form guard
start_guard(::Engine, (; m, u)) =                        #manual trigger: an input (§12.5)
    m.phase === off && u.starter
start_handler(::Engine, _) = (; m = (; phase = starting))          #no `x` key: no reset
ignition_guard(eng::Engine, (; x, m, u)) =                #predicate form
    m.phase === starting && x.ω > eng.ω_idle && u.fuel_available
ignition_handler(::Engine, _) = (; m = (; phase = running))
flameout_guard(eng::Engine, (; x)) = eng.ω_min - x.ω      #continuous form: localizable
flameout_handler(::Engine, _) = (; m = (; phase = off))
```

The blocks below take that inventory declaration by declaration, and record
where each schema fact gets its authority.

#### State, modes, discrete state

**Rule.** `x_init` on the continuous [tier](#g-tier), `s_init` on the discrete, and
`m_init`, declare *by initial value*. The type is derived from the value. The
value is a `NamedTuple`, one named field per leaf, and no other form is
admitted. A bare leaf such as `x_init(::C) = 0.0` or
`s_init(::C) = zeros(SVector{3})` is refused. The structure step reports it as
`StoreNotNamedTuple`, and the message spells the wrap ([§9.1][s9-1],
[Appendix C][sC], [D-247][d-247]).

**Rule.** Every leaf declares exactly one of `x_init` and `s_init`, and a
stateless leaf declares it empty, `x_init(::Gain) = (;)` or
`s_init(::Sampler) = (;)`. The store is the tier marker, so it is mandatory
even when empty, exactly as `inner_connections` is mandatory even when empty
because it is the class marker ([§8.5][s8-5], [D-263][d-263]). A primitive
declaring neither store is `TierUnreadable`, and its message spells the empty
form. An empty store owes no update law, since it has nothing to integrate or
advance, and it puts no letter in the bundle ([§5.2][s5-2]).

**Why.** A continuous component's state may be empty ([§3.1][s3-1]), so a
stateless continuous leaf is honestly a continuous leaf with zero state fields.
Spelling that out puts every leaf's tier on the page in one place, stateful or
not, with no tier by omission. It also closes a trap. A store lost to a local
scope or to a forgotten import ([§8.1][s8-1]) fails loud as a leaf declaring no
store, where an optional marker would have dropped silently.

**Why.** Every service reaches a leaf by its field name. The condition overlay
merges on it ([§14.1][s14-1]), readers and the trace spell it ([§14.4][s14-4]),
and a one-field store publishes its field as the port of that name
([§5.3][s5-3]). The name a one-state component is asked for is the name every
service then uses.

There is consequently no second artifact to drift and no separate type
declaration to check. The [workspace](#g-workspace) (component-declared mutable scratch
arriving as the `ws` bundle field) is the exception to that convention. It is
declared *by allocation*, as `ws_init(::C, ::Type{T})` on both tiers,
and the method itself is the allocator. A workspace earns the exception because it is not memory and
none of the by-value arguments below cover it ([§7.3][s7-3]). `ws_init`
alone declares by allocation, and nothing downstream derives from the type of
what it returns.

This is the boundary of legitimate derivation. Deriving from another
declaration is sound, and deriving from evaluated user code is not. Declaring
types here too, `u_types`-style, with `probe_value` ([§9.3][s9-3]) synthesizing
the initial values, was rejected ([D-073][d-073]).

**Why.** The declared values are the base layer of the [condition](#g-condition) substrate
(a condition is the path-addressed sparse overlay that sets a build's state).
The overlays ([§14.1][s14-1]) fall back to them leaf by leaf, and the compiled store
writers bake `merge(defaults, overlay)`, so there must be an authored value
under every leaf.

The asymmetry against `u_types`/`y_types` is one of kind, not style.
[Contracts](#g-contract) describe table [cells](#g-cell), which are recomputed from scratch every
[sweep](#g-sweep), and so need only types. `init_*` describe [stores](#g-store), the model's
memory, which must have contents before the first sweep can run.

**Every declaration but the allocator takes the component alone**, and the
criterion is the declaration convention it lives in ([D-263][d-263]). It is stated
once here, and the blocks below refer back to it. A *by-value* declaration
states nominal physics, and its *types* [walk by rule](#g-leaf-walk) (the derivation of
per-activation types from a declared nominal type). [§7.1][s7-1] forces every state
leaf to follow the [activation](#g-activation) scalar (the build's typed products at a
given scalar type), so nothing is left for a signature to record. Partials enter
through per-invocation seeding, never through initialization. A *by-type*
declaration walks by the same rule, and where a leaf must not follow the scalar
the author says so at the leaf, with `Pinned`, which is why `u_types` and
`y_types` take the component alone too. A *by-allocation* declaration is
the exception. It builds values the framework may not rebuild, so the scalar
can come from nowhere but its own argument, and `ws_init(c, T)` takes it
on both tiers ([D-077][d-077]). The criterion, not uniformity, is the rule. A `T` in
a signature means the framework could not have supplied it.

#### `u_types(::C)`

An `u_types` declaration is a bare `NamedTuple` of types, written at
nominal `Float64` and taking the component alone on both [tiers](#g-tier). The one
piece of framework vocabulary it admits is the `Pinned{P}` marker, which
wraps a leaf type to say that the leaf never follows the activation scalar.
It wraps the whole entry, and a marker below the top of an entry is
`IllegalPortType` ([D-265][d-265]). On a continuous consumer the declaration is [walked](#g-walked): every `Float64`
position follows the scalar, and a `Pinned` leaf stays `Float64`. On a
discrete consumer it pins wholesale, and a `Pinned` entry there says nothing
and is `DeclarationOnWrongTier` ([§8.5][s8-5]).

Entries are **[face](#g-face) bounds, not [cell](#g-cell) types**, and the reading is
**permissive** ([D-167][d-167]). An entry states, per leaf, what the consumer *allows*
to arrive there. Entries come in three forms:

| entry | the leaf is | what may lawfully arrive |
|---|---|---|
| `Float64`, alone or as a type parameter (`SVector{3, Float64}`, `RQuat{Float64}`) | **tolerant** | the [activation](#g-activation) scalar or a frozen `Float64` |
| `Pinned{Float64}`, or `Pinned{P}` around any leaf type | **demanding frozen** | never partials |
| `Int`/`Bool`/enum leaves, abstract reference-typed entries | as it always was | what the declared bound admits |

An unpinned entry is what a promoting consumer writes, and it is the
overwhelmingly common case. A walking producer, a frozen discrete producer and
a [root input](#g-root-input) are all admissible behind it, so substitution stays intact.

A `Pinned` entry is the **FFI door**. This input must never carry partials. A
[component](#g-component) whose internals cannot propagate `Dual`s (an opaque wrapper, a C
table, a hand-rolled solver) declares it, and its AD-incompatibility becomes
schema-visible instead of folklore. The failure then moves from a
`MethodError` inside user math at the first `Dual` [probe](#g-probe) to a named wiring
error at build ([§6.1][s6-1]).

`Int`/`Bool`/enum leaves and abstract reference-typed entries stand as they
always were. [Abstract entries](#g-abstract-entry) state **structural substitutability**, several
concrete producer types admissible behind one stable face. The field handles
([§4.4][s4-4]) are the demonstrated client, as in `terrain = AbstractTerrainField`.
They carry no scalar position, because they are references rather than
numbers. They are still never the tool for eltype genericity. That is exactly
what an unpinned entry is, a promoting consumer writing `SVector{3, Float64}`
rather than an abstract bound.

Names-only [contracts](#g-contract) were rejected ([D-033][d-033]). Inputs are the component's
*requirements*. Only against them are the unconnected-input error ([§6.1][s6-1]),
over-wiring detection and [did-you-mean](#g-did-you-mean) typo messages definable at all. A
did-you-mean message is the offending name plus the list-in-hand it should
have matched.

**Two clauses check a wire** ([§6.1][s6-1]). The **nominal bound check** is stated at
nominal. The producer's declaration at `Float64`, markers stripped, must be `<:`
the entry at `Float64`. It is one uniform rule, and it degenerates to exact
equality for a concrete entry, because concrete types are final. Beside it sits
the **tier-scoped walk-compatibility clause**. For a *continuous* consumer, a
walking producer leaf (one the producer left unpinned) requires an unpinned
entry, while a [pinned](#g-walked) producer leaf satisfies either, because frozen values
embed upward. An opaque leaf embeds nothing and is admitted at an unpinned
entry as the producer's cell ([D-264][d-264]). Both sides are plain declarations the walk retypes, so the clause
is decidable in the structure step (the build's first step, declaration reading
only) by retyping them at a marker scalar. No user stage code runs ([§9.1][s9-1]),
and a violation is `WalkingFaceAtFrozenEntry`.

**Discrete consumers take the bound check only**, and that scope is
a correctness rule rather than tidiness.

**Why.** A discrete stage reads exclusively at real [ticks](#g-tick) in the nominal
world, and a `Dual`-carrying cell exists only inside activations discrete
stages never run in ([§9.4][s9-4]). Wires from a continuous producer to a discrete
consumer are therefore unconditionally legal. The unscoped variant is rejected
in [D-167][d-167].

Because entries are bounds, nothing is ever "overwritten". Cell types are
single-sourced from the producer side per activation ([§9.4][s9-4]), and a
`Dual`-carrying cell behind an unpinned entry is the design working, not a
promise broken. The code-level complement is the **genericity obligation**, which
says that whatever scalars the wiring delivers, the consumer's math promotes. The
obligation is still checked by the `Dual` probe, never declared, and it is
**scoped to the unpinned entries**. A `Pinned` input imposes no such
obligation, which is its point. So **declarations record choices, and
obligations are checked**. The marker's absence records the tolerance choice,
and the probe checks the promotion.

**The permissive reading is the operative one, and the two readings it escapes
are rejected** ([D-033][d-033], [D-054][d-054], [D-167][d-167], [D-263][d-263]). The *predictive* reading has the
entry saying what *will* arrive. The *envelope* reading has it as a promise to
promote. The permissive reading predicts nothing, and it is not constant,
because pinned entries are rare but real. That is what makes the marker carry
information here.

**Root inputs are the one place an entry types a cell.** A root input is
produced by no component, so it has only the consumer declaration to take a
type from. The **root-input type** is the entry at `Float64`, markers stripped,
and only a *tight* bound determines one. A face surfacing as a root input must
therefore resolve to a concrete declaration, which [staging cells](#g-staging-cell), the
[trace header](#g-trace-header) and `probe_value` all need. Abstract-at-root is a build error, and
`AbstractAtRoot` names the face and the remedy, which is to wire a concrete
producer, or a stub child in a test rig ([§13.7][s13-7]). Under fan-out the
root-input type is the unique concrete declaration among its consumers, and
abstract co-consumers are checked against it. Two different concrete
declarations remain an error. The **root-input cells** at an activation follow
the root-input type by retyping that same entry at the activation's `T`.
This makes **seedability schema-visible**. An unpinned root input is a lawful
linearization `B`-matrix tap, and a `Pinned` root input is *declaredly*
unseedable ([§14.10][s14-10]).

**Fan-out combines tolerance by a meet, not by agreement** ([D-168][d-168]). The root
input pins at every activation if *any* consumer's entry pins, and follows the
scalar only when every consumer tolerates. Concretely, the root-input cells at
an activation are the root-input type with every leaf following the scalar
when every consumer's entry admits that type, and the root-input type itself
otherwise. A mixture of pins across leaves therefore pins the whole root input
([D-236][d-236]). Two consumers of one root input may agree at nominal and still
differ in tolerance. `SVector{3, Float64}` and `Pinned{SVector{3, Float64}}`
are one type at nominal, so the root input *type* is unambiguous while the
entries disagree about partials. That mixture is a legitimate model rather
than a mistake. A command consumed by a promoting aerodynamics leaf and by an
AD-opaque table is the FFI door in use.

**Why.** The direction of the meet is forced by embedding. A pinned root-input
cell feeds an unpinned entry lawfully, because frozen values embed upward as
zero-partial constants ([§9.5][s9-5]). A `Dual`-carrying cell arriving at a
`Pinned` entry is precisely what that entry forbids. The meet is therefore
the only assignment satisfying every consumer at once. It mirrors the
walk-compatibility clause ([§6.1][s6-1]) on the producer side.

What the mixture costs is stated where it is paid. Such a root input is
unseedable, and a tap selecting it is rejected naming the *pinning consumer*
rather than the face alone ([§14.10][s14-10]).

#### `y_types(::C)`

`y_types` declares the public [port](#g-port) [contract](#g-contract), and declares it **by
type**. It is the same species as `u_types`, written at nominal `Float64`,
taking the component alone on both [tiers](#g-tier), and [walked](#g-walked) on the continuous
one. Where the input side is read permissively, though, this one is read
**literally**. An entry states what the [cell](#g-cell) *carries*, not what it tolerates.

On a **continuous producer** the declaration is spelled
`y_types(::Engine) = (M_shaft = Float64, P = Float64, ω = Float64)`, and
the cell types at an activation are that declaration retyped at the
activation's `T` by the leaf walk ([D-079][d-079], [D-263][d-263]). On a **discrete producer** the same spelling
pins wholesale, which is the discrete exemption ([§7.2][s7-2]) enforced by tier.
Which reading applies is decided by the leaf's tier, declared by its store
(above and below), never by the contract's shape.

Semantics are **literal** once the walk has run. The cell type is the retyped
declaration, with nothing inferred. Participation is therefore authored **per
leaf** and legible on the page:
- **`Float64`, alone or as a type parameter** (`SVector{3, Float64}`,
  `RQuat{Float64}`, `MyStruct{Float64}`) means the leaf **participates**. Its
  cell carries the activation scalar. Value parameters are structure rather
  than number and never take it (`Ranged{Float64, -1, 1}`; the bounds are not
  scalars to re-type).
- **`Pinned{P}`** means the leaf is **deliberately [pinned](#g-walked)**, and the pin is
  schema-visible. The wrapper is stripped at nominal, so the cell is `P` at
  every activation. It is whole-leaf freezing, declared and
  conformance-checked. That is the recorded freeze door ([§14.10][s14-10]) delivered.
  Declare `Pinned{Float64}` and strip with `ForwardDiff.value` inside the
  stage, so the stop-gradient is stated in the contract instead of buried
  mid-expression. The marker sits at the top of the entry and nowhere below
  it ([D-265][d-265]).
- **`Int`/`Bool`/enum leaves and reference-typed fields** pin as they always
  did. A [§4.4][s4-4] bulk-data handle's grid is frozen build-time data, never
  activation-dependent, and the walk never reaches it, because references are
  fields and the walk substitutes type parameters alone. A handle carrying a
  scalar *parameter* walks like any type, and one built from build-time data
  is declared `Pinned` ([D-237][d-237]).
- **A mutable type's parameters** pin by rule. No stage can produce a
  `Vector{Dual}` inside a handle without copying the grid at every evaluation,
  so there is no choice for a marker to record.

**A handle keeps its bulk at `Float64` and its activation-dependent part in
the parameter.** The rule reads off the shape. References are fields, so a
grid typed `Matrix{Float64}` stays frozen at every activation, and a pose
typed `T` follows the scalar:

```julia
struct DeckField{T}
    heave::T                 # pose: follows the activation scalar
    pitch::T
    grid::Matrix{Float64}    # geometry: frozen build-time data, never re-typed
end
```

Inside a query nothing converts the grid. Each product of a grid entry and a
`Dual` weight promotes on its own, so the query's result carries the pose's
partials and the interpolant's slope while the grid is read as it was loaded.
A `Matrix{T}` grid would give the same numbers at the cost of a copy per
evaluation, which is the copy the mutable-parameter rule above refuses. The
producer pins the handle when it is built from build-time data alone, a
static terrain, and leaves it walking when its parameters come from state, a
moving deck. A field that must never follow the scalar is typed concretely in
its struct, `b::Float64` beside `a::T`, which freezes it for every user of
the type; the marker pins a whole leaf, and a pin on one parameter of one
declaration is not offered ([D-265][d-265]). The rule "every `Float64` position
follows the scalar" reads the declaration as written, so a concretely typed
field is frozen without appearing in the contract.
`handle_walk_walkthrough.md` works a static terrain and a moving deck
through one consumer.

The companion obligation is **constructibility at `T`**. A declared type must
be buildable at the activation scalar. The `Dual` [probe](#g-probe) enforces it by
construction. It builds real values, so a type whose constructor cannot accept
them detonates at the probe with its own name in the message.

During a generic [sweep](#g-sweep), gated-off discrete producers hold their `Float64`
values, consumers gather mixed tuples, and promotion does the rest. That is
semantically exact. A frozen discrete output is a constant with zero partials,
which is precisely what "linearize the continuous dynamics with the discrete
state held" means. The frozen cell is not an AD limitation on the signal path.
It is the true zero of an instantaneous dependence the hybrid semantics never
had (`frozen_discrete_walkthrough.md`). What makes the mixing safe is the
**embedding guarantee** ([§9.5][s9-5]), keyed on **walking leaves** ([D-033][d-033]).

**Why.** A `Float64` observed at a walking leaf under a non-nominal
activation implies no `Dual` entered its computation, because promotion is
airtight and there is no lossy cast. Its true derivative along every seeded
direction is therefore zero, and embedding it as a zero-partial constant is
exact.

Piecewise branches returning literal constants (`flow > 0 ? f(x) : 0.0`) are
legal as written, because zero partials are the derivative of a
locally-constant branch. Which *invocation* carries partials is still chosen
by seeding ([§14.10][s14-10]), never by typing. The declaration says which leaves
*can* carry them, and the seed says which directions do.

**The misplaced-pin account, stated openly.** A leaf that really participates
cannot be declared frozen by habit, because the habitual spelling, a bare
`Float64`, walks. What remains is deliberate. An author writes `Pinned` at a
leaf that really participates, or omits it at one that really does not.

The first bug **lurks, but is never silent**. No lossy `Dual → Float64` cast
exists, so the first `Dual` activation of that [component](#g-component) fails. It fails at
that activation's own lazy compile ([§9.4][s9-4]), not at `build(world)`. The
message carries the didactic hint ("if `F` participates in differentiation,
remove its `Pinned`"), because an observed `Dual` at a pinned leaf has exactly
one honest cause. The second fails at the same activation, inside the stage
where the frozen internals meet a `Dual`, or at the identity comparison on an
opaque leaf built from build-time data ([§9.5][s9-5]).

Both lurks are contained by policy rather than machinery. **The test suite builds
a `Dual` activation of every component**, which is the exhaustive set [§9.4][s9-4]
defines. An activation is derived from the nominal one, cheap enough to make
this unremarkable in CI. What the plain form buys in exchange is **one
convention**. Every declaration in the framework is read with the same walk
rule, and a genuinely frozen leaf still says so on the page.

**The stores are walked by the same rule, with no marker.** The type derived
from `x_init` is walked. Real leaves and `Real` type parameters follow the
activation scalar. `m_init` and `s_init` pin wholesale, mirroring the
discrete-producer rule. `Pinned` has no place in a store, because [§7.1][s7-1]
admits no pinned state leaf for it to mark. Declared `Float64` initial values
embed as zero-partial constants under non-nominal activations. That is the rule for `Float64` condition leaves
([§14.3][s14-3]) applied to the defaults those conditions overlay.

Walking `x_init` presupposes the closed leaf vocabulary [§7.1][s7-1] fixes, scalars
and `SArray`s at the common eltype. On the discrete tier, the stores answer to
the isbits rule of [§7.3][s7-3], checked field by field. The structure step checks both
vocabularies ([§9.1][s9-1]) and reports a failure in the didactic style:
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

#### `state_events(::C)`

`state_events` declares an ordered, named collection of [guard](#g-guard)/handler pairs,
spelled `StateEvent(guard, handler)` with no detection keyword. Detection
policy is declared by the guard's return type instead. A `Bool` guard makes
the event [boundary-detected](#g-boundary-detected), checked for edges at step boundaries only,
with no root-finding. A guard returning the nominal scalar makes it
[localized](#g-localized), with the crossing instant bracketed by root-finding over trial
sweeps ([§10.4][s10-4]). Order is semantics. It is the declaration order used by
[§5.3][s5-3] and the priority order, with re-decision, used by [§10.6][s10-6]. Nothing
here is inferrable.

#### No stage tags anywhere

Which stage produces which [port](#g-port) stays invisible in the [contract](#g-contract),
preserving [§4.2][s4-2]. Moving a port between stages is non-breaking for
consumers. Membership is *derived* instead, with no chicken-and-egg. Stage-1
functions (`y_state`) structurally receive no inputs, so the build
[probes](#g-probe) them first, observes their contract ports, assigns the remainder to
stage 2, builds the graph, and probes the stage-2 chain in topological order
with real upstream values. The "decoder takes no inputs" property is exactly
what makes the derivation well-founded. A leaf's declarations do carry its
[tier](#g-tier) ([D-195][d-195], [D-220][d-220]), and that is a different fact. The tag this
subsection refuses is the *stage* tag on a port, which stays invisible either
way.

#### Custom structs as port types

A custom struct is a first-class port type, as in `contact = GearContact{Float64}`,
under the scoping [§7.2][s7-2] establishes. That scoping requires a struct
parametric in its real-scalar leaves, with constructors inferring the scalar
and no [pinned](#g-walked) fields on the continuous path. A participating struct leaf
is declared with `Float64` in its parameter position, `GearContact{Float64}`,
and the walk retypes it there, recursively for nested parameters. A struct with
a hardcoded `Float64` field offers no such position, so the walk leaves it as
written, a pinned leaf by shape, and `Pinned{GearContact}` says so on the page.
Any `Dual`-carrying construction then detonates inside the stage with an
`InexactError` naming the offending constructor. That is the [§7.2][s7-2] CI
invariant reached through the declaration layer with no extra machinery.

#### Completeness of the declaration set

Four rules the build checks in the structure step ([§9.1][s9-1]), stated here because
they are properties of the declarations, not of the wiring.

**A non-empty store needs its update.** `x_init` with fields and no
`x_deriv` method, or `s_init` with fields and no `s_update`
method, is a build error. An empty store is a stateless leaf's tier marker
(above) and owes nothing. The first is
continuous state with no [flow](#g-flow), the second a discrete store nothing updates.
The framework will not silently supply `ẋ = 0`, which is a model, not a
default. An unupdated discrete store is a parameter in disguise, and
parameters are plain struct fields. The didactic style says exactly that.
`m_init` carries no such obligation. Modes are written by handlers, and a
[component](#g-component) may legitimately declare modes no event of its own transitions.

**An event needs both halves.** A `state_events` entry whose [guard](#g-guard) or handler
has no method for the component type is a build error, caught by method
lookup at declaration-reading time rather than as a `MethodError` at the first
firing. An event that fires only in a corner of the envelope would otherwise
hide the omission indefinitely.

**[Tier](#g-tier) is declared by the store.** Every leaf declares `x_init` or
`s_init`, the two are disjoint, and so every leaf announces its tier in one
place ([D-195][d-195], [D-263][d-263]). A stateful leaf announces it in the update law as
well, `x_deriv` beside `x_init` and `s_update` beside `s_init`.
The two output stages are one pair of names shared by both tiers, so they
announce nothing and cast no vote ([D-220][d-220]). The remaining tier-implying
declarations must agree. `m_init`, `state_events` and `x_projection` are
continuous-only, because the event system is continuous-side only ([§5.2][s5-2],
[§3.2][s3-2], [§14.1][s14-1]) and projection's one manifold is the continuous state's
([§2.2][s2-2]). A `Pinned` entry in a contract is continuous-only, because the
discrete tier pins wholesale and the marker there says nothing. No arity
carries a tier. Every declaration takes the component alone, and
`ws_init` takes the scalar on both tiers ([D-263][d-263]). Disagreement is
`DeclarationOnWrongTier` ([Appendix C][sC]), reported as the offending declaration
with the tier the leaf's other declarations announce. It covers declaring both
`x_deriv` and `s_update`, a `Pinned` entry on a discrete leaf, and
the mixed-store cases the split state letters restore, namely both stores on
one leaf, an `x_init` on a leaf whose update law is `s_update` and an
`s_init` on one whose update law is `x_deriv`.

A **stateless** leaf is a leaf whose store is empty, and it declares its tier
the same way. `x_init(::C) = (;)` makes it continuous, the tier [§13.7][s13-7]
steers stateless leaves to, and `s_init(::C) = (;)` makes it discrete, one
that runs at its [ticks](#g-tick) and holds its outputs between them. A primitive
declaring neither store is `TierUnreadable` ([Appendix C][sC]). `y_types`
stays mandatory on a stateless leaf. A leaf with an empty store and no output
[contract](#g-contract) produces nothing and stores nothing, and it is refused as
`StatelessWithoutOutputs` ([Appendix C][sC]). The stage bundles follow the tier
like any other leaf's, with no `x` or `s` field, because the bundle law puts a
store's letter in the bundle only when the store is non-empty ([§5.2][s5-2]).
[§13.7][s13-7] records why one stateless continuous leaf already serves consumers
on both tiers. Members of both families, or of neither, are the [§8.5][s8-5]
class errors.

**Any component may be the root of a build, and the model's [root inputs](#g-root-input) are
the root's own input [faces](#g-face)** ([D-208][d-208]). For an [assembly](#g-assembly) those are the
faces declared through `u_connections`, each traced through the face
chain ([§6.1][s6-1], [§11.3][s11-3]) to the leaf entries consuming it. For a primitive they
are its `u_types` keys directly, because a leaf's faces are its own [port](#g-port)
names ([§8.6][s8-6]). Each is then its own consuming entry. The type derivation is
one rule across both cases, the tight bound at the ultimate consuming entry,
above. At the root the two contract declarations share one face namespace, so
a key declared in both is a build error ([§8.6][s8-6]).

Abstract-at-root is what the uniform doctrine does not relax. A leaf declaring
an [abstract entry](#g-abstract-entry) (`terrain = AbstractTerrainField`) still cannot be built
bare, because a root input must resolve to a concrete declaration. The
[component test rig](#g-component-test-rig) ([§13.7][s13-7]) is the idiom for that case. It satisfies the
entry with a stub child *inside* the rig.
### 8.3 Visibility: the contract is the interface

**Rule.** Visibility is decided by *where the value goes*:

- a field declared in `y_types` is public;
- a field returned in `y` (a stage's own published signals) and declared
  nowhere is a build error;
- a component with no `y_types()` method has no outputs.

That is the same move as class-by-declaration-shape. [Ports](#g-port) in the
[contract](#g-contract) are connectable, GUI-listed, [snapshot](#g-snapshot)-carried and log-exported.
The table is public throughout, with every [cell](#g-cell) a declared port, so
nothing anywhere needs a presentation filter.
Visibility is binary, with no third class between the two. A value a later
function reads travels as a declared port like any other ([§5.2][s5-2]).

The inspection path for an intermediate is therefore **declaration**. One line
in `y_types` makes it public, checked and visible everywhere at once
([D-194][d-194]). FlightCore is the precedent, where an intermediate was inspected by
putting it in the `Model` output and no other way. Publicity is never
implicit. Even the minimal [component](#g-component) writes
`y_types(::LowPassFilter) = (x = Float64,)`, one line, in exchange for
"public" always meaning someone wrote it down.

- **Conformance.** A declared port must be produced by exactly one stage,
  stage 1 or stage 2 ([D-252][d-252]). Those two classes are the whole
  classification, and the framework produces no port of its own. Stage
  membership is derived over `y_types` alone ([§9.1][s9-1]).
  Declared-but-unproduced and produced-by-two-stages are build errors. A
  declared port no stage produces is `DeclaredNotProduced`, which names the
  port, the stage products and the store fields; the remedy is returning the
  name from `y_state` ([§5.3][s5-3]). A *returned port field*
  declared nowhere is a build error at [probe](#g-probe), with [did-you-mean](#g-did-you-mean) (the
  offending name plus the list-in-hand it should have matched) against
  `y_types`. That is the return-side analogue of [§8.4][s8-4] walkthrough 1
  ([D-034][d-034], [D-055][d-055]). The forgotten-branch walkthrough holds. A declared `P`
  missing from the taken branch's return fails at probe. Missing from an
  *untaken* branch, it fails loudly at that branch's first execution via the
  always-on check.
- **Branch-shape rule.** Stage returns must have the same `NamedTuple` shape
  on every branch. Julia's type-stability discipline already demands that for
  performance. The framework merely makes it a stated rule with a good error.
- **[Schema authority](#g-schema-authority) is total over the table** (declarations define
  structure; evaluation only checks conformance). Every *cell* traces to an
  authored declaration, the always-on check's expected type for `y` is fully
  declaration-derived, and return typos cannot silently define new cells.
  Protection against silently dropped partials rests on the embedding
  guarantee ([§9.5][s9-5]). Promotion is airtight, so an observed `Float64` is a
  true constant. Probe-observed expected types remain rejected ([D-034][d-034],
  [D-055][d-055], [D-194][d-194]).
- **What this rules out** ([D-016][d-016], [D-034][d-034], [D-055][d-055], [D-194][d-194]). The `unlisted`
  flag ([§4.2][s4-2]) and its satellite-function representation; identity
  publication by default ([§7.4][s7-4] step 4); **probe-observed private cells**;
  the `Private(T)` fallback; and the opt-in variant with a
  `Float64`-under-`Dual` diagnostic.

### 8.4 Failure walkthroughs (the error-locality grounding)

The five mistakes that decided declaration-vs-inference, with their failure
sites under this layer. Each was traced under inference-by-evaluation too, and
in every case the failure surfaced inside *correct* code, later, or never.
[D-032][d-032] carries the traces.

1. **Typo'd wire** (`:throtle`). A build error at the connection, "no input
   `throtle`; did you mean `throttle`?"
2. **Forgotten wire** (`fuel_available`, read only by a [guard](#g-guard)). The [§6.1][s6-1]
   unconnected-input error at build.
3. **Forgotten branch field** (`P` returned by one branch only). A [probe](#g-probe) or
   first-execution error naming the declared [port](#g-port).
4. **Type mismatch** (a `Float64` fraction wired into a `Bool` input). A
   wiring-time error naming both endpoints and both [faces](#g-face).
5. **Typo'd return field** (`P_shft = …` for a declared `P_shaft`). A probe
   error with [did-you-mean](#g-did-you-mean) (the offending name plus the list-in-hand it
   should have matched) against `y_types`. That one error is the whole
   report. The probe chain stops at the port check ([§13.1][s13-1], [D-239][d-239]), and
   an unproduced-`P_shaft` error would only restate it from the other side,
   since renaming the field produces the port. A declared port no stage
   returns, on a component whose returns are all declared, is the
   completeness pass's error, with the stage-product and state-field lists in
   hand ([§8.3][s8-3]). Every returned field is a declared port, so this one
   error form is the whole case. An intermediate a later function reads is
   declared like any other output and typo'd like any other output ([§8.3][s8-3]).
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

`sample_times` needs no rule change. Element names are immediate child names,
hence legal keys, and the bare field name is sugar for a uniform declaration
across all elements. The sugar keys on the *field*, not on a path segment, so
a name-transparent container keeps it unchanged. `(children = Relative(2),)`
is the uniform spelling for a `Group`. The one ambiguity this leaves, a
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
### 8.6 Paths, wiring and faces

**Paths are slash-separated strings**, relative to the [assembly](#g-assembly) or model root
they are read from, with no leading slash. There is one canonical form, shared
verbatim by declarations, error messages, [device](#g-device)/[trace](#g-trace) addressing
([§11.3][s11-3]) and the HDF5 log tree. [Container children](#g-container-children) ([§8.5][s8-5]) add index and
key segments, `"aircraft/2"` and `"aircraft/red"`, which are ordinary segments
resolved against the container field. A container declared name-transparent
([§8.5][s8-5]) adds no segment of its own, and its elements go by bare key. Instance
navigation, tuples of symbols and dotted paths were all rejected ([D-040][d-040]). A
path-tracking proxy remains addable sugar. The three wiring declarations use
only the short case of that form, one child segment and one [face](#g-face) name
([§6.1][s6-1]). The read side walks the full depth (`"systems/ldg/left/trn"` in a
[snapshot](#g-snapshot) or the log tree). That read side is the inspection side and
`resolve` as the inspection primitive ([§13.3][s13-3]). One fact from that
adjudication is relied on downstream. Symmetric immutable siblings are
`===`-identical, so a path is unrecoverable from an instance. That is why the
helpers ([§8.8][s8-8]) name the child by path.

**`inner_connections(::A)`** is an ordered collection of `"src/face" => "dst/face"`
pairs, strictly from a child face to a child face. The rules ([§6.1][s6-1]) apply:
one wire per input, and every endpoint an immediate child and one of its
[faces](#g-face), container key segments included. The assembly's **boundary** is
declared by two further methods, one per direction. **`u_connections(::A)`**
is an ordered collection of pairs, face name => internal endpoint path, or a
tuple of paths for an input face routed to several immediate children
(fan-out through the boundary), as in
`"trn" => ("left/trn_field", "right/trn_field", …)`. Every entry routes to
**at least one** internal endpoint. An empty tuple is a declaration error,
because a face feeding nothing declares nothing ([D-210][d-210]).
**`y_connections(::A)`** runs the other way, internal source path => face
name (`"aircraft/pose" => "view_pose"`), so that its pairs, like every other
pair in the three declarations, read along the flow.

**Face names are arbitrary strings with two build-checked invariants.** The
first is that a face name contains no `/` (reserved for structural paths). The
second is uniqueness across the union of the two boundary declarations' face
names. Every other naming choice (separators, grouping prefixes like
`"pilot.throttle_axis"`) is author convention, not framework law. The
`input_passthrough` helper's defaults ([§8.8][s8-8]) document the house style
without legislating it.

**At the root the uniqueness invariant follows the root's [class](#g-class)**
([D-210][d-210]). A primitive root declares no boundary methods, so its face set is
the union of its `u_types` and `y_types` keys, and a key declared in
both is the same build error a duplicate face name is. The root is where those
two declarations first share an address space. A [root input](#g-root-input) places a [cell](#g-cell)
the [periphery](#g-periphery) writes ([§11.3][s11-3]), so a collision would put two cells at one
name. Below the root nothing collides, because a primitive's input faces alias
their producers' cells and place nothing. Non-root leaves are left alone.

The two-notation rule this rests on is directional. It separates structure
from derived contract, not read from write. **Slash is structure**: endpoint
paths walking real children and ports, and the inspection side's
[snapshot](#g-snapshot) and log addressing. **Face names are opaque derived-contract
tokens.** The [periphery](#g-periphery)'s write side (input devices, mappings, the trace,
the GUI write path) speaks face names exclusively ([§11.3][s11-3]). The read side
speaks them wherever it wants meaning that outlives the build, in integration
bindings (`get_face`, [§11.2][s11-2]) and service reads ([§14.4][s14-4]). The
three declarations return pairs of strings rather than NamedTuples ([D-046][d-046]).

One invariant spans all three declarations. Every pair's arrow points the way
the signal flows, with the left side a producer or entry point and the right
side a consumer, and every right side is fed exactly once. **Direction is
therefore declared by the method**, not inferred. The resolved endpoints only
*cross-check* it, and an entry whose endpoint resolves to a port of the wrong
direction is a build error naming the method, the entry and the resolved
port's actual direction. A mixed entry is not expressible, because the single
list that made that error class possible does not exist. Two entries producing
the same output face remain the ordinary two-producers error. Face *types and
[tiers](#g-tier)* are derived from the internal endpoints, which is the [blessed](#g-blessed)
derivation-from-declarations ([§8.2][s8-2]). The derivation is forced, not merely
convenient ([D-041][d-041]). An assembly is tier-neutral, exporting
continuous-sourced and discrete-sourced ports side by side, and a face's
[cells](#g-cell) follow the producer's own declaration ([§8.5][s8-5]), evaluated at the
[activation](#g-activation) scalar on the continuous tier and [pinned](#g-walked) on the discrete. Three
alternative spellings are rejected ([D-041][d-041], [D-170][d-170]): routing values under the
leaf names `u_types`/`y_types`, leaf-style *typed* faces with face
wires inside `inner_connections`, and routing-as-wires with derived types and
no face list. Publicity is never implicit ([§8.3][s8-3]).

**[Root inputs](#g-root-input) fall out with no vocabulary.** At every non-root level an input
face declared through `u_connections` is fed by the parent's wire. At the
root there is no parent, and the root component's input faces *are* the
[write surface](#g-write-surface), the set of faces a writer's batch entries may reach ([§11.3][s11-3]).
Which declaration supplies them follows the root's [class](#g-class),
`u_connections` keys for an assembly and `u_types` keys for a
primitive ([§8.2][s8-2]), and nothing downstream distinguishes the two. The
whole-tree obligation model ([§6.1][s6-1]) states the complementary error rule. An
assembly never declares its external connections. Those live in the parent
that instantiates it, exactly as a leaf's do.

**A [worked](#g-worked) assembly.** The strapdown IMU of [§3.4][s3-4], spelled in full. It is a
mixed-tier assembly exercising paths, faces and sample times together:

```julia
struct IMU <: AbstractComponent
    integrals::IMUIntegrals    # continuous — cumulative Θ, q, Υ, V
    sampler::IMUSampler        # discrete — integrate-and-difference latches
    errors::IMUErrorModel      # discrete — scale/bias/noise on the sample
end

inner_connections(::IMU) = (
    "integrals/Θ" => "sampler/Θ", "integrals/q" => "sampler/q",
    "integrals/Υ" => "sampler/Υ", "integrals/V" => "sampler/V",
    "sampler/sample" => "errors/sample",
)

u_connections(imu::IMU) = (
    input_passthrough(imu, "integrals")...,       # kinematic-truth inputs pass through
)

y_connections(::IMU) = (
    "sampler/sample"     => "sample",             # ideal increments
    "errors/sample_meas" => "sample_meas",        # measured increments (the error
                                                  # model's output port)
)

sample_times(::IMU) = (sampler = Relative(1), errors = Relative(1))
```

Two spellings are worth reading closely. `input_passthrough` enumerates the
child's **input** faces and nothing else ([§8.8][s8-8]), which is why the
pass-through of the integrals' kinematic-truth inputs (`q_eb`, `r_eb_e`,
`ω_eb_b`, `a_ib_b`, `α_ib_b`) is a bare splat with nothing to say
about direction. And the measured-increment face sources `errors/sample_meas`,
the error model's *output* port, not the `errors/sample` input the sampler
already feeds. Listing `errors/sample` in `y_connections` would fail the
direction cross-check, and listing it in `u_connections` while it is wired
is the two-producers error of [§8.8][s8-8].

Three facts the example carries. The assembly is tier-neutral. Every face's
type and tier derive from its internal endpoint, and a `sample_times` key on
`integrals`, the continuous child, would be a [§8.7][s8-7] build error. The two
discrete children default to `Relative(1)` anyway, so this `sample_times`
declaration is declaratory, and their absolute rate arrives from the enclosing
scope at deployment ([§8.7][s8-7]). And the latch-back wire (below), where the
integrals consume the sampler's published latch, joins `inner_connections` as
one more ordinary pair.

#### The IMU's leaves: integrate-and-difference

The leaves carry the idiom that answers integrate-and-dump ([§3.4][s3-4]).
Algebra can eliminate the reset, with no approximation. Every interval-relative
integral becomes a *cumulative* one. The sampler differences against the
previous sample, held in its `s`. That is the textbook sampled-data latch, and
it is the only new store, the memory the reset used to erase.

- *Raw increments* (linear): $\Theta(t) = \int_{t_0}^{t} \omega^{c}_{ic} \, dt$,
  $\Upsilon(t) = \int_{t_0}^{t} f^{c} \, dt$, never reset;
  $\vartheta_c = \Theta(t_k) - \Theta(t_{k-1})$,
  $\upsilon_c = \Upsilon(t_k) - \Upsilon(t_{k-1})$.
- *Coning*: cumulative $q(t) = q_{c_0 \to c(t)}$ with
  $\dot{q} = \tfrac{1}{2} \, q \otimes \omega^{c}_{ic}$ from
  identity at $t_0$. The interval rotation is $\Delta q = q(t_{k-1})' \circ q(t_k)$, exact by
  right-invariance ($\Delta q$ satisfies the same ODE with the same body rate).
- *Sculling*:
  $\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt = q(t_{k-1})' \, ( V(t_k) - V(t_{k-1}) )$
  with $\dot{V} = q(t)(f^{c})$. The derivation takes two steps. First,
  re-anchor the rotation through the fixed $c_0$ frame,
  $R^{c_{k-1}}_{c} = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} R^{c_0}_{c}$, so that
  the $c_{k-1}$-dependent factor, constant over the interval, exits the
  integral. What remains is the cumulative integrand. Second, split its range
  at $t_{k-1}$, which gives the difference of the running store:

  $$\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt
  = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} \left( \int_{t_0}^{t_k} R^{c_0}_{c} f^{c} \, dt -
  \int_{t_0}^{t_{k-1}} R^{c_0}_{c} f^{c} \, dt \right)
  = q(t_{k-1})' \, \big( V(t_k) - V(t_{k-1}) \big)$$

  In code, this is the sampler line `υ_c_sc = s.q'(u.V - s.V)`. The factor
  leaving the integral is the **anchor change between two inertially-fixed
  frames**. It is constant because $t_{k-1}$ is in the past and latched. The
  physical intra-interval rotation, the thing sculling corrections are
  *about*, stays inside the integrand via $q(t)$. Every [RHS](#g-flow)
  evaluation, RK stages included, applies the current cumulative attitude,
  exactly as the direct formulation applies its current `q_c_cc`.

#### Exactness condition, stated once

Interval-relative integrals factor into cumulative ones whenever the interval
dependence enters through a *left action by the interval-start value of a
cumulatively-integrable quantity*. That action is the identity for linear
integrals, right-invariance for attitude increments, and constancy of the
anchor change for sculling. Two provisos apply. First, the cumulative attitude
must be integrated with the **inertial** rate, so that the anchor frame is
inertially fixed and the pulled factor rigorously constant. Anchoring to a
rotating reference breaks the factorization. Second, the equivalence survives
discretization. Quaternion kinematics is linear in `q`, every RK stage
composes on the right, and left multiplication by the constant anchor commutes
through, so the formulations agree to machine precision, not merely in the
continuous-time limit. Never resetting has numerical consequences. `q` stays
unit under `x_projection`, which is better conditioned than the direct formulation's
`normalization = false` plus reset. `Θ`, `Υ` and `V` grow linearly, so
differencing loses relative precision. After an hour of flight that loss is of
order $10^{-11}\ \mathrm{m/s}$ per sample against $10^{4}\ \mathrm{m/s}$
totals, six-plus orders below any error model worth simulating.

```julia
struct IMUIntegrals <: AbstractComponent
    t_bc::FrameTransform
end
x_init(::IMUIntegrals) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                          Υ = zeros(SVector{3}), V = zeros(SVector{3}))
u_types(::IMUIntegrals) =
    (q_eb = RQuat{Float64}, r_eb_e = SVector{3,Float64}, ω_eb_b = SVector{3,Float64},
     a_ib_b = SVector{3,Float64}, α_ib_b = SVector{3,Float64})
y_types(::IMUIntegrals) =
    (Θ = SVector{3,Float64}, q = SVector{4,Float64},            # exposed state (§5.3)
     Υ = SVector{3,Float64}, V = SVector{3,Float64},
     ω_ic_c = SVector{3,Float64}, f_c_c = SVector{3,Float64})   # instantaneous truth

# the four integrals are state, so stage 1 returns them (§5.3)
y_state(::IMUIntegrals, (; x)) = (; x.Θ, x.q, x.Υ, x.V)

# y_direct: strapdown kinematics (lever arm, gravity, Earth rate) → (; ω_ic_c, f_c_c)
function x_deriv(imu::IMUIntegrals, (; x, y))
    q = RQuat(x.q, normalization = false)              # [§7.1][s7-1]'s explicit cast
    (Θ = y.ω_ic_c, q = SVector{4}(Attitude.dt(q, y.ω_ic_c)), Υ = y.f_c_c, V = q(y.f_c_c))
end
x_projection(imu::IMUIntegrals, x) = (; x..., q = normalize(x.q))   # SVector normalize

struct IMUSampler <: AbstractComponent end
s_init(::IMUSampler) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                        Υ = zeros(SVector{3}), V = zeros(SVector{3}))
u_types(::IMUSampler)  = (Θ = SVector{3,Float64}, q = SVector{4,Float64},  # discrete class: plain
                         Υ = SVector{3,Float64}, V = SVector{3,Float64})       # form, bound check only
y_types(::IMUSampler) = (sample = IMUSample,)   # discrete class: cells pin (frozen-exact)

function y_direct(smp::IMUSampler, (; s, u, Δt))
    q_s = RQuat(s.q, normalization = false);  q_u = RQuat(u.q, normalization = false)
    ϑ_c = u.Θ - s.Θ;  υ_c = u.Υ - s.Υ
    Δq  = q_s' ∘ q_u                                   # interval rotation, exact
    υ_c_sc = q_s'(u.V - s.V)                           # constant anchor change pulled out
    (; sample = IMUSample(; ω̄_ic_c = ϑ_c / Δt, f̄_c_c = υ_c / Δt,
                            ϑ_c, ϑ_c_cc = RVec(Δq)[:], υ_c, υ_c_sc))
end
s_update(smp::IMUSampler, (; u)) = (Θ = u.Θ, q = u.q, Υ = u.Υ, V = u.V)   # the latch
```

The `IMU` [assembly](#g-assembly) wires the four integral [ports](#g-port)
across, holds the error model as a discrete sibling consuming `sample`, and
leaves the sampler at `K = 1` in its own scope. The parent sets the IMU's rate
([§8.7][s8-7]). `Δt` in the stage [bundle](#g-bundle) (the NamedTuple of
zero-copy views a component function receives) is the [§10.5][s10-5] single
source of truth, put there for exactly this kind of discretized law.
Initialization consistency also holds. The sampler's `s` must equal the
initial integrals, or the `t₀` sample is wrong. That holds by default at
zeros/identity, and [boundary zero](#g-boundary-zero) discharges the rest. Its
[due](#g-due) `s_update` latches `s ← integrals(t₀)` for every subsequent
sample, so only the `t₀` sample itself depends on the authored `s`. That
dependence is a [condition](#g-condition)-authoring obligation under trim
([§14.5][s14-5]).

#### Why `u.V` is fresh: the line that would silently zero

The sculling line is correct only because a due [tick](#g-tick) samples the
*completed* [boundary](#g-boundary). If `u.V` still held the previous
boundary's decode, it would equal `s.V` exactly, since that is the value
`s_update` latched, and sculling would vanish without an error anywhere.
The guarantee is the [§10.6][s10-6] macro-sequence, not a scheduling accident.
The sequence is integrate, project, [sweep](#g-sweep), with the due sampler's
stages gated *into* that sweep ([§10.5][s10-5]) and the integrals arriving at
stage-1 position, returned by `y_state` ([§5.3][s5-3]). They arrive before
any stage-2 function runs, regardless of topological placement. The rest of
the timeline closes consistently. The sampler's `y_direct` decodes `s`,
the `t_{k-1}` latch, *before* `s_update` runs, which is the `z⁻¹`
semantics. After event [quiescence](#g-quiescence), `s_update` latches the
`t_k` values for the next tick. Same-boundary events re-run the gated stages
in their re-sweeps, so `s_update` and external readers see the settled
boundary.

#### Sampling at `t_k` is a taught contract

The clean implementation leans on the author *knowing* that "sampling at `t_k`" means
post-integration, post-[projection](#g-projection), stage-1-fresh state. That
knowledge must be part of the framework's taught contract, not internal lore,
with the [§10.5][s10-5] and [§10.6][s10-6] semantics stated in
[component](#g-component)-author documentation ([Appendix A][sA]) and this IMU
as the [worked](#g-worked) example. The failure mode
of not knowing it is instructive. An author who distrusts the
[sweep](#g-sweep) order adds a defensive one-[tick](#g-tick) delay or
re-derives the integrals in the sampler, silently degrading the model.

**When the coupling is genuinely two-way, the latch becomes a wire back.** The
IMU's coupling is one-directional, from integrals to sampler. Suppose the
[flow](#g-flow) itself needed the interval-relative value, say for integrator
saturation within the sampling interval. Then the sampler publishes the
sample-instant values from its *[feedthrough](#g-feedthrough)* stage, and the
continuous `x_deriv` computes `x − u.latch`. The feedthrough stage is
the right one because `y_direct` reads `u`, so the latch [port](#g-port)
carries the current tick's values, ZOH until the next. An
`y_state`-published latch would be one period stale. Both cross-wires
consume the other side's ports, and the [feedthrough](#g-feedthrough) graph stays acyclic.
The integrals' stage 1 feeds the sampler's `y_direct`, and the sampler's
`y_direct` feeds the integrals' `x_deriv` edge ([§5.4][s5-4]).
The "reset" becomes a visible [tier](#g-tier)-crossing feedback loop, which is
what it always was, physically.

### 8.7 Rate scopes

The declaration is `sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))`,
mapping each child name to a `Relative` or `Absolute` entry. These are the two
forms of [§10.5][s10-5]. Relative entries compose affinely down the tree,
absolute entries anchor, and all are compiled to one `(D, Φ)` pair per
discrete [component](#g-component). The wrappers are the whole value vocabulary, so a
bare integer or bare quantity is a declaration error. The declaration is
optional, and so is any given key. An unlisted discrete child defaults to
`Relative(1)`, so only multiplied, phased or anchored children need appear.
Keys are **immediate child names only**. A deep key would edit another type's
design from outside, and the composition rule guarantees you never need to.
Container elements ([§8.5][s8-5]) are immediate children, so `"aircraft/red"` is a
legal key, and the bare field name applies one declaration to every element.
A `sample_times` key on a continuous child is a build error (the
Δt-on-continuous error at declaration time, [§10.5][s10-5]). `Δt_base`, `h` and
`N_base` appear in no declaration. They are deployment decisions fixed at
deployment (the three sources for `Δt_base`, [§9.2][s9-2]). The
declaration belongs to the [assembly](#g-assembly) type, not to the child instance,
because a sample time is a design ratio or a modeled instrument's intrinsic
rate ([§10.5][s10-5]), never a per-instance value. The FlightCore-`Subsampled`-style
instance wrapper is rejected in [D-042][d-042].

### 8.8 Computed connections and generic holding

`u_connections` and `y_connections` are ordinary functions evaluated
at build against the concrete instance, so they may *compute* entries from
child [contracts](#g-contract). That is derivation from declarations, which [§8.2][s8-2]
blesses. The framework helper, sketched:

```julia
# the two shapes of `declaration_error` used below:
declaration_error(path::AbstractString, why::Symbol)      # e.g. :multiple_selectors
declaration_error(path::AbstractString, unknown, legal)   # did-you-mean against the legal set

function input_passthrough(assembly, child_path::AbstractString;
                     sep::AbstractString = ".",
                     prefix::AbstractString =               # "" → no prefixing
                         replace(child_path, "/" => sep),
                     except::Tuple = (), only::Tuple = (),  # one selector per call
                     select = nothing)                      # predicate over face names

    child = resolve(assembly, child_path)      # getfield walk along "/" segments
    names = input_faces(child)            # the leaf's u_types keys,
                                          # entries of u_connections(c) for an assembly
    given = !isempty(except) + !isempty(only) + (select !== nothing)
    given ≤ 1 ||
        declaration_error(child_path, :multiple_selectors)  # exclusivity enforced, not documented
    unknown = setdiff((except..., only...), names)
    isempty(unknown) || declaration_error(child_path, unknown, names)  # list in hand
    wanted = !isempty(only)     ? only :
             select !== nothing ? filter(select, names) :
                                  setdiff(names, except)
    # `given == 1` with an empty `wanted` is EmptyFaceSelection, a build warning
    # through §9.2's channel; a bare call over a faceless child is silent
    label(n) = isempty(prefix) ? n : string(prefix, sep, n)
    return Tuple(label(n) => string(child_path, "/", n) for n in wanted)
end

u_connections(w::World) = (
    input_passthrough(w, "aircraft"; except = ("atm", "trn"))...,   # "aircraft.pilot.throttle_axis"
    input_passthrough(w, "atmosphere"; prefix = "env", sep = "_")..., # "env_wind_N"
)

y_connections(w::World) = (
    "aircraft/pose" => "view_pose",
)
```

The child is named by path and never passed as an instance, because the `===`
problem ([§8.6][s8-6]) makes a path unrecoverable from an instance. A [face](#g-face) name
containing dots is a legal final path segment on the internal-endpoint side,
precisely because slash is the only structural separator. Computed entries
mix freely with hand-written ones in either declaration. `resolve` and
`input_faces` are build-pipeline primitives needed anyway, and
`input_passthrough` is a thin composition. That is what keeps the helper
sugar rather than machinery. There is no `rename` hook, because the boundary
declarations are ordinary code (map over the pairs). Normative signatures for
both primitives are in [§13.3][s13-3]. Every error stays first-class. An `except`
face the [assembly](#g-assembly) then fails to wire is an ordinary unconnected input. A
face both wired and passed through is a two-producers error. `except` or `only`
naming a nonexistent face errors with the child's face list in hand. A
`prefix = ""` collision is caught by the build's uniqueness check like any
hand-written duplicate.

**Rule.** The selectors are exclusive. A call takes `except`, `only` or
`select`, one of the three and no more ([D-251][d-251]). `select` is a predicate
over the child's face names, and the helper keeps the names it accepts. More
than one selector given is `UnknownFaceSelection` with reason
`:multiple_selectors`, "more than one selector given", its payload naming the
selectors given.

**Rule.** A call that gives a selector and keeps nothing raises
`EmptyFaceSelection`, a warning on the `Build`'s list ([§9.2][s9-2],
[D-251][d-251]). A bare call over a faceless child is silent, because passing
nothing through is what it asked for. The payload names the helper, the child
path, the selector given with its names, and the child's face list.

**Why.** An empty selection is almost always a typo the unknown-names check
cannot see. An `only` may name faces that exist while a `select` matches none,
or an `except` may list every face. It warns rather than errors because a level
may legitimately pass nothing through under one configuration of a generic
child.

**Why `select` exists.** At C172X scale the feed list below already computes
the `except` tuple. A closure over the same list says the same thing without
building the tuple.

The effective face list is plain printable data, the
inspectable derived contract of this instantiation. What computation does
*not* do is auto-bubble. The author wrote down "every input face of this child
that I don't feed, I expose under this prefix", explicit at the type level and
evaluated at build.

**The name carries the direction, so the helpers come in pairs.**
`input_passthrough` reads `input_faces(child)`, and the selector filters
*face names* within that set. The helper exists for the pass-through case,
where an assembly hands a child's unfed requirements up one level.
**`output_passthrough` is its sibling** ([D-209][d-209]). It is splatted into
`y_connections`, reads `output_faces(child)`, and has the same
`prefix`/`sep` surface, the same three exclusive selectors and the same
declaration-time error set.

```julia
y_connections(sys::Systems) = (
    output_passthrough(sys, "ldg"; only = ("damaged",))...,   # "ldg.damaged"
    "aero/wrench" => "wrench",
)
```

Its consumer is one-level routing ([§6.1][s6-1]). Every level re-exports the
outputs it surfaces, so the output side needs the computed spelling the input
side already has. Both helpers take `child_path` naming an **immediate**
child, container key segments included. The default `prefix` folds the path's
slash into `sep`, so `"gear/1"` labels its faces `"gear.1.…"` and the default
stays a legal face name for every blessed `child_path`. An explicit `prefix`
is used verbatim. A deeper path meets `resolve`'s one-level rejection like any
other wiring endpoint ([§13.3][s13-3]). There are two helpers rather than one
keyword, because after the boundary split a single call cannot emit entries
into two different declarations.

**One authored list, two declarations.** The `World` example's two-entry
`except` understates the real shape. Every level of a realistic tree is a
generic [seam](#g-seam), and an assembly that feeds some of a child's input faces while
passing the rest up must name the fed ones in `except`. At C172X scale that is
four seams and roughly ten names at the innermost one, restating in each
`except` tuple the wire list sitting in the same assembly's
`inner_connections`. That is "structure kept in two artifacts" ([§8.1][s8-1];
[D-039][d-039]), the shape this design refuses elsewhere. It needs no vocabulary.
Declaration bodies are ordinary code ([§8.5][s8-5]), so the author writes the feed
list *once* and both declarations compute their share of it.

```julia
# one authored artifact: actuator output face => destination child input face
const ACT_FEEDS = (
    "e"          => "aero/e",
    "a"          => "aero/a",
    "r"          => "aero/r",
    "brake_left" => "ldg/left.brake",
    …                                            # ~10 entries for the C172X
)

# the face names of `child` the feed list targets
fed_faces(feeds, child) = Tuple(chopprefix(dst, child * "/")
                                for (_, dst) in feeds
                                if startswith(dst, child * "/"))

inner_connections(::Systems) = (
    (("act/" * src) => dst for (src, dst) in ACT_FEEDS)...,
    "aero/wrench" => "wr_sum/in1",               # non-feed wires unchanged
    …
)

u_connections(sys::Systems) = (
    input_passthrough(sys, "aero"; except = fed_faces(ACT_FEEDS, "aero"))...,
    input_passthrough(sys, "ldg";  except = fed_faces(ACT_FEEDS, "ldg"))...,
    …
)
```

Adding an actuator channel is then one edit. The new pair simultaneously
creates the wire and removes the face from the input face surface. The two
declarations cannot drift, because neither holds the shared names. Both are
projections of the authored list, so the drift class is removed rather than
detected. Every misspelling stays loud. A mistyped destination is an
unknown-face error with the child's face list in hand, whether the wire or
the `except` entry meets it first. One asymmetry is stated openly. A pair
*omitted* from the list is not an error but a structural change. The face
leaves the `except` set and joins the input face surface, ultimately a
[root input](#g-root-input) for conditions to cover ([§14.6][s14-6]). What the idiom preserves, and
the helper below surrenders, is that the feed statement exists to be
reviewed. An omission is legible in one authored artifact, not defined away
as the complement of the wire list.

**The line not to cross** is deriving `except` from `inner_connections` itself,
for instance a helper spelled `except = fed(sys, "aero")` that reads the
assembly's own wire list. That is auto-bubbling under another name ([D-043][d-043],
[D-145][d-145]). The single source must be **authored data, never inferred
structure**.

**[Generic holding](#g-generic-holding) is an imposed derived contract.** A parent holding a child
generically constrains it exactly through the faces its wires and interface
connections reference. Build a `World` whose concrete aircraft lacks a
referenced face, and the error names the `World` entry. That is build-time
structural typing with no new vocabulary (a formal required-faces declaration
on domain abstract types remains possible sugar). Scalar faces make partial
scripting compose. A guidance [scenario component](#g-scenario-component) wires `mode_req` and
`EAS_ref` while the remaining faces stay exported for GUI or defaults, which
is impossible with a bundled face ([§4.3][s4-3] write-side rule).

---

