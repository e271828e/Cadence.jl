## 8. The declaration layer: components and assemblies

This chapter says how an author spells a [component](#g-component). It covers where the
structural facts live, what the build takes as authoritative, and what is
checked against what. The first four sections cover the component side.
[§8.1][s8-1] lays the foundations of the declaration layer, [§8.2][s8-2] lists the
declaration inventory, [§8.3][s8-3] says what a contract makes visible, and [§8.4][s8-4]
gives the five failure walkthroughs that ground error locality. The last four
cover the [assembly](#g-assembly) side. [§8.5][s8-5] covers assembly declaration, how a type's
class is read, container children and `Group`. [§8.6][s8-6] covers paths, wiring
and faces, works them through the strapdown IMU, and ends with the
boundary-sampling contract. [§8.7][s8-7] covers rate scopes, and [§8.8][s8-8] covers
computed connections and generic holding. The build pipeline is [§9][s9], and
the stopped-sim service spellings are [§14][s14]. The concrete syntax below is
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

The build [probes](#g-probe) user functions with real values (a single evaluation of
each, its result discarded), with no reliance on compiler inference, and
compares observed against declared. The same comparison then runs on every
subsequent evaluation for free, as a `NamedTuple`-type check that constant-folds
away when conformant.

Inference-by-evaluation as [schema authority](#g-schema-authority) (the source that defines
structure) is rejected on three counts, established by walkthrough
([§8.4][s8-4]) and litigated in [D-032][d-032]. Types come by declaration, values by
execution, and conformance by comparison.

#### Contracts are functions of the type

**A leaf's contract declarations must be determined by the component's
type**, its type parameters included, and never by its field *values*
([D-033][d-033]). Those declarations are `u_types`, `y_types` and
`state_events`, and the shapes of `x_init`/`s_init`/`m_init`.

The value-discarding signature `u_types(::Engine)` is the visible form of the
rule (`Engine` is the example component of [§8.2][s8-2]). The idiom for a
contract that genuinely varies is the type parameter, not the field, as in
`SumJunction{Wrench, 3}` ([§6.2][s6-2]) and `Or{N}` ([§13.7][s13-7]). Arity is spelled in
the type, at the price [§6.2][s6-2] states openly.

The reason is how executor entries are typed ([§9.7][s9-7]). A component's
[bundle](#g-bundle) is the `NamedTuple` of zero-copy views a component function
receives, and its key set *is* its contract's. An entry of the [executor](#g-executor),
the compiled form of the stage execution order, carries what selects code in
type parameters and what is plain data in fields. A key set derivable only from
field values would therefore have to go one of two ways. It could climb into the
type parameters anyway, multiplying specialization and changing the cost model
([§9.7][s9-7]) of [chunking](#g-chunking), the splitting of a large phase body into statically
typed chunks. Or it could sit in fields, dissolving the static typing that the
zero runtime graph logic ([§5.1][s5-1]), the allocation invariant ([§7.5][s7-5]) and the
fold-away conformance test ([§9.5][s9-5]) all rest on.

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
report a *modeling* diagnostic, `StoreWithoutUpdate` (a non-empty [store](#g-store)
without its update law, [§8.2][s8-2]). When the whole inventory was shadowed, it
would report `ClassUnreadable` (no declaration to read a [class](#g-class) from,
[§8.5][s8-5]). A one-line namespace mistake would be reported far from the line
that caused it. That is the inversion of [error locality](#g-error-locality) (the property
that a mistake fails at the site of the mistake) that [§8.4][s8-4] traces,
arriving through the namespace.

Two mitigations apply, both normative. The first is that the import list above
is authoring surface, stated wherever a component file is first shown
([D-117][d-117]). The second is a shadowing check. **The structural walk
runs the shadowing check on every component before its class is read**
([§9.1][s9-1], [D-246][d-246]).

The check looks for a binding of a declaration name (a name in the import list
above) in the component's parent module. If the module holds one distinct from
the framework's function, **the build throws `DeclarationShadowed` alone**
([D-246][d-246]). The diagnostic names the module, the foreign names and the
missing import. Its message reads "`MyEngine`'s module defines its own
`x_deriv`, distinct from `Cadence.x_deriv`; add `import Cadence: x_deriv`".

The check is a two-line `isdefined`/`!==` test on those names. Those names are
distinctive by design ([D-220][d-220]), so a foreign binding of one of them in a
component's module is evidence of the missing import, not a coincidence. The
check throws alone because nothing the module declares can be trusted. Every
declaration it holds may have gone to a foreign function, and a walk past it
would only report cascades of the one cause. It runs on every component rather
than only where an absence is noticed, because an optional declaration such as
`state_events` or `sample_times` has no absence to notice. Shadowed, it would
drop its feature silently.

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

1. Declarations are noun phrases naming what they return, prefixed by the bundle
   field they define where one exists ([D-267][d-267]). An [assembly](#g-assembly)'s boundary
   declarations take `u` and `y` too. There the letter names a side of the
   contract, which on a leaf is also a bundle field ([D-279][d-279]). The author
   defines them and the framework calls them. They include `inner_connections`,
   `u_connections`/`y_connections`, `state_events`, `u_types`, `ws_init`, the
   stage and update-law names ([D-220][d-220]), and `claims(b)` from the [binding](#g-binding)
   interface ([§11.6][s11-6]). A binding is the value passed at `attach!` that
   makes a device framework-legible.
2. Value selectors carry `get_`. They are called against `reads` and against
   [snapshots](#g-snapshot), the immutable per-boundary publications
   ([§14.4][s14-4]).
3. Lifecycle and mutating actions are verbs, with `!` when they mutate.
4. Build primitives are plain verbs ([§13.3][s13-3]).

A name in the wrong class is a rename candidate on that ground alone.

The convention also has a semantic axis. A name can sit in the right class and
still pick the wrong noun. A declaration names its *content*, never the
*consequence* the declaration has. `input_passthrough` ([§8.8][s8-8],
[D-171][d-171]) and the binding methods `claims`/`reads` ([§11.6][s11-6],
[D-146][d-146]) apply that axis, and `exports` is its retired exemplar
([D-170][d-170]). The `*_connections` family names content deliberately, for
authoring transparency. That is a recorded choice, not class drift.

Which names the module exports is a separate question. It stays open until
the exported-name audit in `pending.md` runs ([D-226][d-226]).

### 8.2 The declaration inventory

This section takes the declarations of a [component](#g-component) (the unit of
modeling, leaf or assembly) one by one, and records where each schema fact gets
its authority. One continuous primitive, declared end to end, shows them
together:

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

**Every declaration of a structural fact but the allocator takes the component
alone** ([D-263][d-263]). The criterion is the convention each declaration
lives in. It is stated once here, and the blocks below refer back to it.

- A *by-value* declaration states nominal physics, and its *types*
  [walk by rule](#g-leaf-walk) (the derivation of per-activation types from a
  declared nominal type). [§7.1][s7-1] forces every state leaf to follow the
  scalar of the [activation](#g-activation) (the build's typed products at a
  given scalar type). Nothing is therefore left for a signature to record.
  Partials enter through per-invocation seeding, never through initialization
  ([D-079][d-079]).
- A *by-type* declaration walks by the same rule. Where a leaf must not follow
  the scalar, the author says so at the leaf with `Pinned` (the leaf marker
  `Pinned{P}`, which yields `P` at every activation). That is why `u_types`
  and `y_types` take the component alone too.
- A *by-allocation* declaration is the exception. It builds values the framework
  may not rebuild, so the scalar can come from nowhere but its own argument.
  `ws_init(c, T)` takes it on both [tiers](#g-tier), the continuous and the
  discrete ([D-077][d-077]). `ws_init` allocates the [workspace](#g-workspace)
  (component-declared mutable scratch), which is described below. The workspace
  arrives as the `ws` [bundle](#g-bundle) field (the `NamedTuple` of views a
  component function receives).

The criterion, not uniformity, is the rule. A `T` in a signature means the
framework could not have supplied it.

#### The stores

**`x_init` on the continuous tier, `s_init` on the discrete, and `m_init`
declare by initial value** ([D-033][d-033]). The type is derived from the value.
**The value is a `NamedTuple`, one named field per leaf**, and no other form is
admitted ([D-247][d-247]). A bare leaf such as `x_init(::C) = 0.0` or
`s_init(::C) = zeros(SVector{3})` is refused. The structure step (the build's
first step, declaration reading only) reports it as `StoreNotNamedTuple`, and
the message spells the wrap ([§9.1][s9-1], [Appendix C][sC], [D-247][d-247]).

**Every leaf declares exactly one of `x_init` and `s_init`**, and a stateless
leaf declares it empty ([D-263][d-263]):

```julia
x_init(::Gain) = (;)
s_init(::Sampler) = (;)
```

The [store](#g-store) (the model's memory, declared by initial value) is the
tier marker. It is therefore mandatory even when empty, exactly as
`inner_connections` is mandatory even when empty because it is the class
marker ([§8.5][s8-5], [D-263][d-263]). A primitive declaring neither store is
`TierUnreadable`, and its message spells the empty form. An empty store owes no
update law, since it has nothing to integrate or advance. It puts no letter in
the bundle ([§5.2][s5-2]).

A continuous component's state may be empty ([§3.1][s3-1]), so a stateless
continuous leaf is honestly a continuous leaf with zero state fields. Spelling
that out puts every leaf's tier on the page in one place, stateful or not, with
no tier by omission. It also closes a trap. A store lost to a local scope or to
a forgotten import ([§8.1][s8-1]) fails loud as a leaf declaring no store,
where an optional marker would have dropped silently.

The store names each leaf because every service reaches a leaf by its field
name. A [condition](#g-condition), the path-addressed sparse overlay that sets a
build's state, merges on it ([§14.1][s14-1]). Readers and the trace spell it
([§14.4][s14-4]). The name a one-state component is asked for is the name
every service then uses.

Because the type is derived from the value, there is no second artifact to drift
and no separate type declaration to check. The workspace is the exception to
that convention. It is declared *by allocation*, as `ws_init(::C, ::Type{T})` on
both tiers ([D-077][d-077], [D-263][d-263]). The method itself is the allocator. A
workspace earns the exception because it is not memory and none of the by-value
arguments below cover it ([§7.3][s7-3]). `ws_init` alone declares by allocation,
and nothing downstream derives from the type of what it returns.

This is the boundary of legitimate derivation. Deriving from another
declaration is sound, and deriving from evaluated user code is not. Stores
declared by type, with synthesized initial values, were rejected
([D-073][d-073]).

The declared values are the base layer of the condition substrate. The
overlays ([§14.1][s14-1]) fall back to the declared values leaf by leaf, and
the compiled store writers bake `merge(defaults, overlay)`. There must
therefore be an authored value under every leaf.

The asymmetry against `u_types`/`y_types` is one of kind, not style.
[Contracts](#g-contract) (a component's declared interfaces) describe table [cells](#g-cell) (the
signal table's typed entries). There is one cell per output [port](#g-port) (one
declared input or output). Cells are recomputed from scratch every [sweep](#g-sweep)
(one pass through the execution order), so contracts need only types. `x_init`,
`s_init` and `m_init` describe stores, which must have contents before the first
sweep can run.

#### Input contracts: `u_types`

A `u_types` declaration is a bare `NamedTuple` of types, written at nominal
`Float64` and taking the component alone on both tiers ([D-263][d-263]). The one
piece of framework vocabulary it admits is the `Pinned{P}` marker (above). It
wraps the whole entry, and **a marker below the top of an entry is
`IllegalPortType`** ([D-265][d-265]).

On a continuous consumer the declaration is [walked](#g-walked), which means
that every `Float64` position follows the scalar and a `Pinned` leaf stays
`Float64`. On a discrete consumer it pins wholesale. A `Pinned` entry there
says nothing and is `DeclarationOnWrongTier` ([§8.5][s8-5], [D-263][d-263]).

**Entries are [face](#g-face) bounds, not cell types, and the reading is permissive**
([D-263][d-263], [D-078][d-078]). A face is the name a port wears on its component's
boundary. An entry states, per leaf, what the consumer *allows* to arrive there.
Entries come in three forms.

| entry | the leaf is | what may lawfully arrive |
|---|---|---|
| `Float64`, alone or as a type parameter (`SVector{3, Float64}`, `RQuat{Float64}`) | tolerant | the activation scalar or a frozen `Float64` |
| `Pinned{Float64}`, or `Pinned{P}` around any leaf type | demanding frozen | never partials |
| `Int`/`Bool`/enum leaves, abstract reference-typed entries | as it always was | what the declared bound admits |

`RQuat` is a domain wrapper type ([§7.1][s7-1]).

An unpinned entry is what a promoting consumer writes, and it is the
overwhelmingly common case. A walking producer, a frozen discrete producer and
a [root input](#g-root-input) (the root component's own input face, produced
by no component) are all admissible behind it. Substitution therefore stays
intact.

A `Pinned` entry is the FFI door. This input must never carry partials. A
component whose internals cannot propagate `Dual`s (an opaque wrapper, a C
table, a hand-rolled solver) declares it. Its AD-incompatibility then becomes
schema-visible instead of folklore. The failure moves from a `MethodError`
inside user math at the first `Dual` [probe](#g-probe) (the build's checking
evaluation of a user function) to a named wiring error at build
([§6.1][s6-1]). **`Pinned` records that a leaf carries no partials, not that
an implementation cannot take them** ([D-266][d-266]). An AD-opaque
implementation that must participate keeps its entry tolerant and supplies a
local derivative rule ([§14.10][s14-10]). A walking producer feeds a pinned
entry through the `Freeze` block ([§13.7][s13-7]).

`Int`/`Bool`/enum leaves and abstract reference-typed entries stand as they
always were, admitting what their declared bound admits. **[Abstract entries](#g-abstract-entry)
state structural substitutability** ([D-078][d-078]). Several concrete producer types are
admissible behind one stable face. The field handles ([§4.4][s4-4]) are the
demonstrated client, as in `terrain = AbstractTerrainField`. They carry no
scalar position, because they are references rather than numbers. They are still
never the tool for eltype genericity. That tool is exactly an unpinned entry, a
promoting consumer writing `SVector{3, Float64}` rather than an abstract bound.

Inputs are the component's *requirements*. Only against them are the
unconnected-input error ([§6.1][s6-1]), over-wiring detection and
[did-you-mean](#g-did-you-mean) typo messages definable at all. A
did-you-mean message is the offending name plus the list-in-hand it should
have matched. [D-033][d-033] records the rejected names-only contracts.

**Two clauses check a wire** ([§6.1][s6-1], [D-263][d-263],
[D-236][d-236]). The first is the nominal bound check, stated at nominal.
The producer's declaration at `Float64`, markers stripped, must be `<:` the
entry at `Float64` ([D-078][d-078]). It is one uniform rule. It degenerates
to exact equality for a concrete entry, because concrete types are final.

Beside it sits the tier-scoped walk-compatibility clause. For a *continuous*
consumer, a walking producer leaf (one the producer left unpinned) requires an
unpinned entry. A pinned producer leaf satisfies either, because frozen values
embed upward. An opaque leaf embeds nothing and is admitted at an unpinned entry
as the producer's cell ([D-264][d-264]). Both sides are plain declarations the
walk retypes. The clause is therefore decidable in the structure step by
retyping them at a marker scalar. No user stage code runs ([§9.1][s9-1]). A
violation is `WalkingFaceAtFrozenEntry`. [§6.1][s6-1] names the bound check's
kind too, and gives the remedies this violation's message carries.

**Discrete consumers take the bound check only** ([D-263][d-263]). That scope
is a correctness rule rather than tidiness. A discrete stage reads exclusively
at real [ticks](#g-tick) (the instants a discrete component runs) in the
nominal world. A `Dual`-carrying cell exists only inside activations discrete
stages never run in ([§9.4][s9-4]). Wires from a continuous producer to a
discrete consumer are therefore unconditionally legal. The unscoped variant is
rejected.

Because entries are bounds, nothing is ever "overwritten". Cell types are
single-sourced from the producer side per activation ([§9.4][s9-4],
[D-054][d-054]). A `Dual`-carrying cell behind an unpinned entry is the design
working, not a promise broken.

The code-level complement is the genericity obligation. It says that whatever
scalars the wiring delivers, the consumer's math promotes. It is still checked
by the `Dual` probe, never declared ([D-054][d-054]). **The obligation is scoped
to the unpinned entries** ([D-263][d-263]). A `Pinned` input imposes no such
obligation, which is its point. **Declarations record choices, and obligations
are checked** ([D-078][d-078]). The marker's absence records the tolerance
choice, and the probe checks the promotion.

The permissive reading is the operative one ([D-263][d-263]). It escapes two
other readings. The *predictive* reading has the entry saying what *will*
arrive. The *envelope* reading has it as a promise to promote. The log rejects
both ([D-054][d-054], [D-078][d-078]). The permissive reading predicts nothing,
and it is not constant, because pinned entries are rare but real. That is what
makes the marker carry information here.

#### Root inputs

Root inputs are the one place an entry types a cell. A root input is produced
by no component, so it has only the consumer declaration to take a type from.
The root-input type is the entry at `Float64`, markers stripped, and only a
*tight* bound determines one ([D-078][d-078]). A face surfacing as a root
input must therefore resolve to a concrete declaration, which
[staging cells](#g-staging-cell), the [trace header](#g-trace-header) and
`probe_value` all need. Staging cells hold each device's pending writes, and
the trace header is the trace's fixed preamble.

**Abstract-at-root is a build error** ([D-236][d-236]). The uniform root doctrine
below does not relax it ([D-208][d-208]). A leaf declaring an abstract entry
(`terrain = AbstractTerrainField`) still cannot be built bare. `AbstractAtRoot`
names the face and the remedy, which is to wire a concrete producer, or a stub
child in a test rig. The [component test rig](#g-component-test-rig) (a one-child wrapper
exporting its child's whole input face set, [§13.7][s13-7]) is the idiom for that
case. It satisfies the entry with a stub child *inside* the rig ([D-120][d-120]).

Under fan-out the root-input type is the unique concrete declaration among its
consumers, and abstract co-consumers are checked against it ([D-236][d-236]).
Two different concrete declarations remain an error, `RootInputTypeConflict`
([D-236][d-236]).

The root-input cells at an activation follow the root-input type by retyping
that same entry at the activation's `T`. **That retyping makes seedability
schema-visible** ([D-263][d-263]). An unpinned root input is a
lawful linearization `B`-matrix tap, and a `Pinned` root input is *declaredly*
unseedable ([§14.10][s14-10]).

**Fan-out combines tolerance by a meet, not by agreement** ([D-168][d-168]).
The root input pins at every activation if *any* consumer's entry pins. It
follows the scalar only when every consumer tolerates. Concretely, the
root-input cells at an activation are the root-input type with every leaf
following the scalar when every consumer's entry admits that type, and the
root-input type itself otherwise. A mixture of pins across leaves therefore
pins the whole root input ([D-236][d-236]).

Two consumers of one root input may agree at nominal and still differ in
tolerance. `SVector{3, Float64}` and `Pinned{SVector{3, Float64}}` are one
type at nominal. The root input *type* is therefore unambiguous while the
entries disagree about partials. That mixture is a legitimate model rather
than a mistake. A command consumed by a promoting aerodynamics leaf and by an
AD-opaque table is the FFI door in use.

The direction of the meet is forced by embedding. A pinned root-input cell
feeds an unpinned entry lawfully, because frozen values embed upward as
zero-partial constants ([§9.5][s9-5]). A `Dual`-carrying cell arriving at a
`Pinned` entry is precisely what that entry forbids. The meet is therefore the
only assignment satisfying every consumer at once. It mirrors the
walk-compatibility clause ([§6.1][s6-1]) on the producer side.

What the mixture costs is stated where it is paid. Such a root input is
unseedable. A tap selecting it is rejected naming the *pinning consumer*
rather than the face alone ([§14.10][s14-10], [D-168][d-168]).

**Any component may be the root of a build, and the model's root inputs are
the root's own input faces** ([D-208][d-208]). For an
[assembly](#g-assembly) (a component of pure composition) those are the faces
declared through `u_connections`, each traced through the face chain
([§6.1][s6-1], [§11.3][s11-3]) to the leaf entries consuming it. For a
primitive they are its `u_types` keys directly, because a leaf's faces are its
own port names ([§8.6][s8-6]). Each is then its own consuming entry. The type
derivation is one rule across both cases, the tight bound at the ultimate
consuming entry, above. At the root the two contract declarations share one
face namespace, so a key declared in both is a build error ([§8.6][s8-6],
[D-210][d-210]).

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
  `RQuat{Float64}`, `MyStruct{Float64}`), means the leaf participates ([D-263][d-263]).
  Its cell carries the activation scalar. Value parameters are structure rather
  than number, and they never take it ([D-079][d-079]). The bounds in
  `Ranged{Float64, -1, 1}` are not scalars to re-type. `Ranged` is a domain
  wrapper type too ([§7.1][s7-1]).
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
`contact = GearContact{Float64}`, under the scoping that [§7.2][s7-2] establishes. Here
`GearContact` is a landing-gear contact. That scoping requires a struct
parametric in its real-scalar leaves, with constructors inferring the scalar. A
participating struct leaf is declared with `Float64` in its parameter position,
`GearContact{Float64}`. The walk retypes it there, recursively for nested
parameters ([D-263][d-263]). A struct with a hardcoded `Float64` field offers no such
position. The walk therefore leaves it as written, a pinned leaf by shape, and
`Pinned{GearContact}` says so on the page. Any `Dual`-carrying construction then
fails inside the stage with an `InexactError` naming the offending constructor.
That is the CI invariant of [§7.2][s7-2], reached through the declaration layer with
no extra machinery.

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

The misplaced-pin account is stated openly here. A leaf that really participates
cannot be declared frozen by habit, because the habitual spelling, a bare
`Float64`, walks ([D-263][d-263]). What remains is deliberate, and it comes in two
bugs. The first is writing `Pinned` at a leaf that really participates. The
second is omitting it at one that really does not.

**The first bug lurks, but is never silent** ([D-286][d-286]). No lossy `Dual → Float64`
cast exists, so the first `Dual` activation of that component fails. It fails at
that activation's own lazy compile ([§9.4][s9-4]), not at `build(world)`. The message
carries the didactic hint ("if `F` participates in differentiation, remove its
`Pinned`"), because an observed `Dual` at a pinned leaf has exactly one honest
cause. A didactic diagnostic is one that states its fix ([§13.2][s13-2]). The second
bug fails at the same activation. It fails inside the stage where the frozen
internals meet a `Dual`, or at the identity comparison on an opaque leaf built
from build-time data ([§9.5][s9-5]).

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

#### Events: `state_events`

`state_events` declares an ordered, named collection of [guard](#g-guard)/handler pairs (a
guard is the declared function defining an event's predicate). A pair is spelled
`StateEvent(guard, handler)`, with no detection keyword. Detection policy is
declared by the guard's return type instead ([D-179][d-179]). A `Bool` guard makes the
event [boundary-detected](#g-boundary-detected), checked for edges at step boundaries only, with no
root-finding. A guard returning the nominal scalar makes it [localized](#g-localized), with
the crossing instant bracketed by root-finding over trial sweeps ([§10.4][s10-4]).

Order is semantics. It is the declaration order used by [§5.3][s5-3] and the
priority order, with re-decision, used by [§10.6][s10-6]. Nothing here is
inferrable.

#### Stage membership

**No port carries a stage tag, and stage membership is derived**
([D-033][d-033]). Which stage produces which port stays invisible in the
contract, preserving [§4.2][s4-2]. Moving a port between stages is
non-breaking for consumers.

The derivation has no chicken-and-egg. Stage-1 functions (`y_state`)
structurally receive no inputs, so the build probes them first and observes
their contract ports. It assigns the remainder to stage 2, builds the graph, and
probes the stage-2 chain in topological order with real upstream values. The
property that stage 1 takes no inputs is exactly what makes the derivation
well-founded.

A leaf's declarations do carry its tier ([D-195][d-195], [D-220][d-220]), and
that is a different fact. The tag refused here is the *stage* tag on a port,
which stays invisible either way.

#### Completeness

The build checks three rules in the structure step ([§9.1][s9-1]). They are
stated here because they are properties of the declarations, not of the
wiring.

A non-empty store needs its update. `x_init` with fields and no `x_deriv` method,
or `s_init` with fields and no `s_update` method, is a build error,
`StoreWithoutUpdate`. The first case is continuous state with no [flow](#g-flow) (the
continuous derivative function, `x_deriv`), the second a discrete store nothing
updates. The framework will not silently supply `ẋ = 0`, which is a model, not a
default. An unupdated discrete store is a parameter in disguise, and parameters
are plain struct fields. The didactic style says exactly that.

An empty store owes nothing (above). `m_init` carries no such obligation either.
Modes are written by handlers, and a component may legitimately declare modes no
event of its own transitions.

An event needs both halves. A `state_events` entry whose guard or handler has no
method for the component type is a build error, `EventHalfMissing`. Method
lookup catches it at declaration-reading time, rather than as a `MethodError` at
the first firing. An event that fires only in a corner of the envelope would
otherwise hide the omission indefinitely.

Tier is declared by the store, as "The stores" above states ([D-195][d-195], [D-263][d-263]). A
stateful leaf announces it in the update law as well, `x_deriv` beside `x_init`
and `s_update` beside `s_init`. The two output stages are one pair of names shared
by both tiers, so they announce nothing and cast no vote ([D-220][d-220]).

**The remaining tier-implying declarations must agree** ([D-112][d-112], [D-249][d-249]). `m_init`,
`state_events` and `x_projection` are continuous-only, because the event system is
continuous-side only ([§5.2][s5-2], [§3.2][s3-2], [§14.1][s14-1]) and projection's one manifold is the
continuous state's ([§2.2][s2-2]). A `Pinned` entry in a contract is continuous-only,
because the discrete tier pins wholesale and the marker there says nothing. No
arity carries a tier (above).

Disagreement is `DeclarationOnWrongTier` ([Appendix C][sC]). It is reported as the
offending declaration, with the tier the leaf's other declarations announce. It
covers declaring both `x_deriv` and `s_update`, a `Pinned` entry on a discrete leaf,
and the mixed-store cases that the split state letters (`x` for continuous
state, `s` for discrete, [D-195][d-195]) restore. Those are both stores on one leaf, an
`x_init` on a leaf whose update law is `s_update`, and an `s_init` on one whose
update law is `x_deriv`.

A stateless leaf is a leaf whose store is empty, and it declares its tier the
same way. `x_init(::C) = (;)` makes it continuous, the tier [§13.7][s13-7]
steers stateless leaves to. `s_init(::C) = (;)` makes it discrete, one that
runs at its ticks and holds its outputs between them.

`y_types` stays mandatory on a stateless leaf. A leaf with an empty store and no
output contract produces nothing and stores nothing, and it is refused as
`StatelessWithoutOutputs` ([Appendix C][sC], [D-263][d-263]). The stage bundles follow the tier
like any other leaf's, with no `x` or `s` field, because the bundle law puts a
store's letter in the bundle only when the store is non-empty ([§5.2][s5-2]). [§13.7][s13-7]
records why one stateless continuous leaf already serves consumers on both
tiers. A type declaring both the leaf and the assembly families of declarations,
or neither, meets the class errors of [§8.5][s8-5].

### 8.3 Visibility: the contract is the interface

This section decides which of a [component](#g-component)'s values are public. It states the
visibility rule, then the inspection path for an intermediate, then the
checks that hold stage returns and declarations to each other.

**Visibility is decided by *where the value goes*** ([D-034][d-034]):

- a field declared in `y_types` is public;
- a field returned in `y` (a stage's own published signals) and declared
  nowhere is a build error;
- a component with no `y_types(::C)` method has no outputs, and a stateless
  leaf without one is refused as `StatelessWithoutOutputs` ([§8.2][s8-2],
  [D-263][d-263]).

That is the same move as class-by-declaration-shape ([§8.5][s8-5]). [Ports](#g-port) in the
[contract](#g-contract) (a component's declared interface) are connectable, GUI-listed,
[snapshot](#g-snapshot)-carried and log-exported. A snapshot is the immutable per-boundary
publication. The table is public throughout, with every [cell](#g-cell) a declared port,
so nothing anywhere needs a presentation filter. Visibility is binary, with no
third class between the two. A value a later function reads travels as a
declared port like any other ([§5.2][s5-2]).

The inspection path for an intermediate is declaration ([D-194][d-194]). That follows
from the visibility rule above. One line in `y_types` makes it public, checked
and visible everywhere at once. FlightCore is the precedent. There an
intermediate could be inspected only by putting it in the model's output.
Publicity is never implicit. Even the minimal component writes
`y_types(::LowPassFilter) = (x = Float64,)`, one line, in exchange for "public"
always meaning someone wrote it down.

**A declared port must be produced by exactly one stage**, stage 1 or stage 2
([D-252][d-252]). Those two classes are the whole classification, and the
framework produces no port of its own. Stage membership is derived over
`y_types` alone ([§9.1][s9-1]). Declared-but-unproduced and
produced-by-two-stages are build errors. A declared port no stage produces is
`DeclaredNotProduced`, which names the port, the stage products and the store
fields. Its remedy is returning the name from `y_state` ([§5.3][s5-3]).

The return side is checked too. A *returned port field* declared nowhere is a
build error at [probe](#g-probe) (the build's single evaluation of a user function). The
error carries a [did-you-mean](#g-did-you-mean) (the offending name plus the list-in-hand it
should have matched) against `y_types`. That is the return-side analogue of [§8.4][s8-4]
walkthrough 1 ([D-034][d-034], [D-239][d-239]). Walkthrough 3 of [§8.4][s8-4], the forgotten branch
field, holds. A declared `P` missing from the taken branch's return fails at
probe. Missing from an *untaken* branch, it fails loudly at that branch's first
execution via the always-on check.

**Stage returns must have the same `NamedTuple` shape on every branch**, the
branch-shape rule ([D-034][d-034]). Julia's type-stability discipline already
demands that for performance. The framework merely makes it a stated rule
with a good error.

[Schema authority](#g-schema-authority) is total over the table ([D-032][d-032], [D-034][d-034]). Schema authority
means declarations define structure and evaluation only checks conformance.
Every *cell* traces to an authored declaration, and the always-on check's
expected type for `y` is fully declaration-derived. Return typos cannot silently
define new cells ([D-239][d-239]). Protection against silently dropped partials rests
on the embedding guarantee ([§9.5][s9-5]). Promotion is airtight, so an observed
`Float64` is a true constant. Probe-observed expected types remain rejected
([D-034][d-034], [D-194][d-194]).

This section's rules exclude several designs the log rejects
([D-016][d-016], [D-034][d-034], [D-055][d-055], [D-194][d-194]), among them
the `unlisted` flag ([§4.2][s4-2]) and its satellite-function representation.

### 8.4 Failure walkthroughs (the error-locality grounding)

The five mistakes below decided the choice between declaration and
inference-by-evaluation as the schema authority ([§8.1][s8-1]). They ground
[error locality](#g-error-locality) (the property that a mistake fails at the site of the mistake).
The list gives each with its failure site under this layer. Each was traced
under inference-by-evaluation too, and in every case the failure surfaced inside
*correct* code, later, or never. [D-032][d-032] carries the traces.

1. A typo'd wire (`:throtle`) is a build error at the connection, "no input
   `throtle`; did you mean `throttle`?"
2. A forgotten wire, such as `fuel_available` read only by a
   [guard](#g-guard) (the declared function defining an event's predicate),
   fails as the [§6.1][s6-1] unconnected-input error at build.
3. A forgotten branch field, such as `P` returned by one branch only, fails as a
   [probe](#g-probe) or first-execution error naming the declared [port](#g-port) (one declared input
   or output). A probe is the build's single evaluation of a user function.
4. A type mismatch, such as a `Float64` fraction wired into a `Bool` input,
   fails as a wiring-time error naming both endpoints and both
   [faces](#g-face) (the names ports wear on their component's boundary).
5. A typo'd return field, such as `P_shft = …` for a declared shaft power
   `P_shaft`, fails as a probe error with [did-you-mean](#g-did-you-mean) (the offending name plus
   the list-in-hand it should have matched) against `y_types`. That one error is
   the whole report. The probe chain stops at the port check ([§13.1][s13-1], [D-239][d-239]),
   and an unproduced-`P_shaft` error would only restate it from the other side,
   since renaming the field produces the port. A declared port no stage returns,
   on a component whose returns are all declared, is `DeclaredNotProduced`, with
   the stage-product and state-field lists in hand ([§8.3][s8-3]). Every returned
   field is a declared port, so this one error form is the whole case. An
   intermediate a later function reads is declared like any other output and
   typo'd like any other output ([§8.3][s8-3]).

### 8.5 Assembly declaration: type-based, class by declaration shape

This section states how an [assembly](#g-assembly) (a component of pure composition) is
declared, how a type's declarations mark it as an assembly or a primitive, what
arity those declarations take, how container fields contribute children, and how
`Group` assembles [components](#g-component) on the fly.

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
components but declares no `inner_connections`". `inner_connections` plus any leaf
declaration on one type is a build error as well.

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
  this section's did-you-mean family ([D-085][d-085]). All-component elements are
  children, and zero-component elements are inert parameter data.
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
- `transparent_container` must name a container field of the type, and
  declaring two transparent containers on one type is a declaration error
  ([D-211][d-211], [D-215][d-215]).

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

### 8.6 Paths, wiring and faces

An [assembly](#g-assembly) (a [component](#g-component) of pure composition, with no dynamics of its own)
wires its children and names its boundary with strings. A [face](#g-face) is the name a
[port](#g-port) (one declared input or output) wears on its component's boundary. This
section fixes the path form, the three wiring declarations and the direction
invariant they share, face names, [root inputs](#g-root-input) (the root component's own input
faces), and face uniqueness at the root. It then spells out a worked assembly,
the strapdown IMU, and its leaves. It closes with the boundary-sampling
contract.

**Paths are slash-separated strings**, relative to the assembly or model root they
are read from, with no leading slash ([D-040][d-040]). There is one canonical form.
Declarations, error messages, [device](#g-device)/[trace](#g-trace) addressing ([§11.3][s11-3]) and the HDF5 log
tree share it verbatim. A device is any attached participant outside the loop,
and the trace is the primary record of a session. [Container children](#g-container-children) (the
elements of a `Tuple` or `NamedTuple` field holding only components, [§8.5][s8-5]) add
index and key segments, `"aircraft/2"` and `"aircraft/red"` ([D-085][d-085]). These are
ordinary segments, resolved against the container field. A container declared
name-transparent ([§8.5][s8-5]) adds no segment of its own, and its elements go by
bare key ([D-211][d-211]). Instance navigation, tuples of symbols and dotted paths were
all rejected ([D-040][d-040]).

The three wiring declarations use only the short case of that form, one child
segment and one face name ([§6.1][s6-1], [D-207][d-207]). The read side
walks the full depth, as `"systems/ldg/left/trn"` does in a [snapshot](#g-snapshot) (the
immutable per-boundary publication) or the log tree. That read side is the
inspection side. It resolves a path with `resolve` under the instance walk
([§13.3][s13-3]). One fact behind the rejection of instance navigation is
relied on downstream. Symmetric immutable siblings are `===`-identical, so a
path is unrecoverable from an instance. That is why the helpers
([§8.8][s8-8]) name the child by path.

`inner_connections(::A)` is an ordered collection of `"src/face" => "dst/face"`
pairs. **Every pair runs strictly from a child face to a child face** ([D-170][d-170]). The
wiring rules apply ([§6.1][s6-1]). There is one wire per input, and every endpoint is
an immediate child and one of its faces, container key segments included.

**The assembly's boundary is declared by two further methods, one per
direction** ([D-170][d-170]). `u_connections(::A)` is an ordered collection of
pairs, face name => internal endpoint path. An input face routed to several
immediate children takes a tuple of paths instead, as in
`"trn" => ("left/trn_field", "right/trn_field", …)`. This is fan-out through
the boundary. **Every entry routes to at least one internal endpoint**
([D-210][d-210]). An empty tuple is a declaration error, because a face
feeding nothing declares nothing ([D-210][d-210]). `y_connections(::A)` runs the
other way, internal source path => face name (`"aircraft/pose" => "view_pose"`),
so that its pairs, like every other pair in the three declarations, read along
the flow.

**Direction is declared by the method**, not inferred ([D-170][d-170]). The reason is one
invariant that spans all three declarations. Every pair's arrow points the way
the signal flows. The left side is a producer or entry point, the right side is
a consumer, and every right side is fed exactly once. The resolved endpoints
only *cross-check* the direction. An entry whose endpoint resolves to a port of
the wrong direction is a build error. The error names the method, the entry and
the resolved port's actual direction. A mixed entry is not expressible, because
the single list that made that error class possible does not exist. Two entries
producing the same output face remain the ordinary two-producers error ([§6.1][s6-1]).

**Face *types and [tiers](#g-tier)* are derived from the internal endpoints** ([D-041][d-041]). A tier
is the continuous or discrete side of the hybrid formalism. This derivation is
the [blessed](#g-blessed) (explicitly sanctioned) derivation-from-declarations ([§8.2][s8-2]). The
derivation is forced, not merely convenient. An assembly is tier-neutral. It
exports continuous-sourced and discrete-sourced ports side by side. A face's
[cells](#g-cell) (entries of the signal table) follow the producer's own declaration
([§8.2][s8-2]). They are evaluated at the [activation](#g-activation) scalar on the continuous tier and
[pinned](#g-walked) on the discrete. Three alternative spellings are rejected ([D-041][d-041]).
Publicity is never implicit ([§8.3][s8-3]).

**Face names are arbitrary strings with two build-checked invariants**
([D-046][d-046]). The first is that a face name contains no `/`, which is
reserved for structural paths. The second is uniqueness across the union of
the two boundary declarations' face names ([D-170][d-170]). Every other naming
choice is author convention, not framework law. Separators and grouping
prefixes like `"pilot.throttle_axis"` are such choices. The
`input_passthrough` helper's defaults ([§8.8][s8-8]) document the house style
without legislating it.

The two-notation rule this rests on is directional. **It separates structure
from derived contract, not read from write** ([D-129][d-129]). Slash is
structure. It covers endpoint paths walking real children and ports, and the
inspection side's snapshot and log addressing. Face names are opaque
derived-contract tokens. The [periphery](#g-periphery) (everything outside the
loop that exchanges data with it) has a write side, made of input devices,
mappings, the trace and the GUI write path. That write side speaks face names
exclusively ([§11.3][s11-3]). The read side speaks them wherever it wants
meaning that outlives the build. It does so in integration bindings
(`get_face`, [§11.2][s11-2]) and service reads ([§14.4][s14-4]). The three
declarations return pairs of strings rather than NamedTuples
([D-046][d-046]).

Root inputs fall out with no vocabulary of their own. At every non-root level an
input face declared through `u_connections` is fed by the parent's wire. At the
root there is no parent. There the root component's input faces *are* the
[write surface](#g-write-surface), the set of faces a writer's batch entries may reach ([§11.3][s11-3]).
Which declaration supplies them follows the root's [class](#g-class) ([D-208][d-208]). Class is a
component's primitive-versus-assembly status. An assembly root supplies its
`u_connections` keys, and a primitive root its `u_types` keys ([§8.2][s8-2]). Nothing
downstream distinguishes the two. The whole-tree obligation model ([§6.1][s6-1])
states the complementary error rule. An assembly never declares its external
connections. Those live in the parent that instantiates it, exactly as a leaf's
do.

**At the root the uniqueness invariant follows the root's class**
([D-210][d-210]). A primitive root declares no boundary methods. Its face set
is therefore the union of its `u_types` and `y_types` keys. A key declared in
both is the same build error a duplicate face name is. The root is where those
two declarations first share an address space. A root input places a cell the
periphery writes ([§11.3][s11-3]), so a collision would put two cells at one
name. Below the root nothing collides, because a primitive's input faces alias
their producers' cells and place nothing. Non-root leaves are left alone.

#### A worked assembly: the strapdown IMU

The strapdown IMU of [§3.4][s3-4] is spelled here in full, as a
[worked](#g-worked) example (a full spelling of a mechanism against a concrete
case). It is a mixed-tier assembly. It exercises paths, faces and sample times
together:

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

Two spellings are worth reading closely. First, `input_passthrough` enumerates
the child's *input* faces and nothing else ([§8.8][s8-8]). That is why the
pass-through of the integrals' kinematic-truth inputs (`q_eb`, `r_eb_e`,
`ω_eb_b`, `a_ib_b`, `α_ib_b`) is a bare splat with nothing to say about
direction. Second, the measured-increment face sources `errors/sample_meas`,
the error model's *output* port. It does not source `errors/sample`, the
input the sampler already feeds. Listing `errors/sample` in `y_connections`
would fail the direction cross-check. Listing it in `u_connections` while it
is wired is the two-producers error of [§8.8][s8-8].

The example carries two more facts. The first is that the assembly is
tier-neutral. Every face's type and tier derive from its internal endpoint, and
a `sample_times` key on `integrals`, the continuous child, would be a build error
([§8.7][s8-7]). The second is that the two discrete children default to `Relative(1)`
anyway, so this `sample_times` declaration is declaratory. Their absolute rate
arrives from the enclosing scope at deployment ([§8.7][s8-7]). The latch-back wire
(below, under "The boundary-sampling contract"), where the integrals consume the
sampler's published latch, would join `inner_connections` as one more ordinary
pair.

#### The leaves: integrate-and-difference

The IMU's leaves carry the idiom that answers integrate-and-dump ([§3.4][s3-4]). In
integrate-and-dump, the IMU's direct formulation integrates over each sample
interval and zeroes its integrals at every sample. Algebra can eliminate that
reset, with no approximation. **Every interval-relative integral becomes a
*cumulative* one** ([D-056][d-056]). The sampler differences against the previous sample,
held in its `s`. That is the textbook sampled-data latch. It is the only new
[store](#g-store), the memory the reset used to erase.

- *Raw increments* (linear). The cumulative integrals
  $\Theta(t) = \int_{t_0}^{t} \omega^{c}_{ic} \, dt$ and
  $\Upsilon(t) = \int_{t_0}^{t} f^{c} \, dt$ are never reset. The increments
  are $\vartheta_c = \Theta(t_k) - \Theta(t_{k-1})$ and
  $\upsilon_c = \Upsilon(t_k) - \Upsilon(t_{k-1})$.
- *Coning*. The cumulative attitude $q(t) = q_{c_0 \to c(t)}$ follows
  $\dot{q} = \tfrac{1}{2} \, q \otimes \omega^{c}_{ic}$ from identity at
  $t_0$. The interval rotation is $\Delta q = q(t_{k-1})' \circ q(t_k)$. It is
  exact by right-invariance, because $\Delta q$ satisfies the same ODE with
  the same body rate.
- *Sculling*.
  $\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt = q(t_{k-1})' \, ( V(t_k) - V(t_{k-1}) )$
  with $\dot{V} = q(t)(f^{c})$. The derivation takes two steps. First,
  re-anchor the rotation through the fixed $c_0$ frame,
  $R^{c_{k-1}}_{c} = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} R^{c_0}_{c}$. The
  re-anchoring lets the $c_{k-1}$-dependent factor, constant over the
  interval, exit the integral. What remains is the cumulative integrand.
  Second, split its range at $t_{k-1}$. That gives the difference of the
  running store:

  $$\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt
  = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} \left( \int_{t_0}^{t_k} R^{c_0}_{c} f^{c} \, dt -
  \int_{t_0}^{t_{k-1}} R^{c_0}_{c} f^{c} \, dt \right)
  = q(t_{k-1})' \, \big( V(t_k) - V(t_{k-1}) \big)$$

In code, the sculling result is the sampler line `υ_c_sc = s.q'(u.V - s.V)`. The
factor leaving the integral is the *anchor change between two inertially-fixed
frames*. It is constant because $t_{k-1}$ is in the past and latched. The
physical intra-interval rotation stays inside the integrand via $q(t)$. That
rotation is what sculling corrections are *about*. Every evaluation of the [flow](#g-flow)
(`x_deriv`, the continuous derivative function) applies the current cumulative
attitude, RK stages included. The direct formulation applies its current
`q_c_cc`, its coning attitude increment, in exactly the same way.

#### The exactness condition

**Interval-relative integrals factor into cumulative ones whenever the
interval dependence enters through a left action by the interval-start value
of a cumulatively-integrable quantity** ([D-056][d-056]). That action is the
identity for linear integrals, right-invariance for attitude increments, and
constancy of the anchor change for sculling.

Two provisos apply. First, **the cumulative attitude must be integrated with
the *inertial* rate** ([D-056][d-056]). The anchor frame is then inertially
fixed and the pulled factor rigorously constant. Anchoring to a rotating
reference breaks the factorization. Second, **the equivalence survives
discretization** ([D-056][d-056]). Quaternion kinematics is linear in `q`,
every RK stage composes on the right, and left multiplication by the constant
anchor commutes through. So the formulations agree to machine precision, not
merely in the continuous-time limit.

Never resetting has numerical consequences. `q` stays unit under
`x_projection`, which is better conditioned than the direct formulation's
`normalization = false` plus reset. `Θ`, `Υ` and `V` grow linearly, so
differencing loses relative precision. After an hour of flight that loss is
of order $10^{-11}\ \mathrm{m/s}$ per sample against
$10^{4}\ \mathrm{m/s}$ totals. That is six-plus orders below any error model
worth simulating.

#### The leaves in code

A few names in the code below need an introduction. `RQuat` is the domain
wrapper an attitude `SVector{4}` is cast to where rotation semantics are wanted
([§7.1][s7-1]). `Attitude.dt` gives the coning bullet's quaternion derivative, and `RVec`
turns the interval rotation `Δq` into the vector the sample carries. `IMUSample`
is the type of the sampler's `sample` output. `FrameTransform` is one of the
payload types [§7.2][s7-2] lists as walked.

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
    q = RQuat(x.q, normalization = false)              # §7.1's explicit cast
    (Θ = y.ω_ic_c, q = SVector{4}(Attitude.dt(q, y.ω_ic_c)), Υ = y.f_c_c, V = q(y.f_c_c))
end
x_projection(imu::IMUIntegrals, x) = (; x..., q = normalize(x.q))   # SVector normalize

struct IMUSampler <: AbstractComponent end
s_init(::IMUSampler) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                        Υ = zeros(SVector{3}), V = zeros(SVector{3}))
u_types(::IMUSampler)  = (Θ = SVector{3,Float64}, q = SVector{4,Float64},  # discrete tier: bound check only
                         Υ = SVector{3,Float64}, V = SVector{3,Float64})
y_types(::IMUSampler) = (sample = IMUSample,)   # discrete tier: cells pin (frozen-exact)

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

The `IMU` assembly wires the four integral ports across. It holds the error
model as a discrete sibling consuming `sample`, and it leaves the sampler at
`K = 1` (its `sample_times` entry is `Relative(1)`) in its own scope. The
parent sets the IMU's rate ([§8.7][s8-7]). `Δt` arrives in the stage
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives) from its single source of truth, the deployment's `Schedule`
([§10.5][s10-5]). It is in the bundle for exactly this kind of discretized
law.

Initialization is consistent too. The sampler's `s` must equal the initial
integrals, or the `t₀` sample is wrong. That holds by default at
zeros/identity, and [boundary zero](#g-boundary-zero) discharges the rest.
Boundary zero is the initialization [boundary](#g-boundary) (a published
consistency point), run at `t₀`. There the sampler's
[due](#g-due) `s_update` (one scheduled to run at this boundary) latches
`s ← integrals(t₀)` for every subsequent sample ([D-067][d-067]). So only the
`t₀` sample itself depends on the authored `s`. That dependence is an
obligation on the author of the [condition](#g-condition) (the datum that
sets a build to a state) under trim ([§14.5][s14-5]).

#### Freshness at the sample

The sculling line is correct only because a due [tick](#g-tick) samples the
*completed* boundary. A tick is an instant at which a discrete component's
stages and update run. If `u.V` still held the previous boundary's decode,
it would equal `s.V` exactly, since that is the value `s_update` latched.
Sculling would then vanish without an error anywhere.

The guarantee is the boundary macro-sequence of [§10.6][s10-6], not a scheduling
accident. The sequence is integrate, [project](#g-projection), [sweep](#g-sweep) (one pass through the
execution order). Projection is the `x_projection` hook, run after integration.
The due sampler's stages are gated *into* that sweep ([§10.5][s10-5]). The integrals
arrive at stage-1 position, returned by `y_state` ([§5.3][s5-3]). They arrive before any
stage-2 function runs, regardless of topological placement.

The rest of the timeline closes consistently. The sampler's `y_direct`
decodes `s`, the `t_{k-1}` latch, *before* `s_update` runs. That is the
`z⁻¹` semantics, the one-sample delay of sampled-data control. After event
[quiescence](#g-quiescence) (the point where an event round fires
nothing), `s_update` latches the `t_k` values for the next tick.
Same-boundary events re-run the gated stages in their re-sweeps. So
`s_update` and external readers see the settled boundary.

#### The boundary-sampling contract

The clean implementation leans on the author *knowing* that "sampling at `t_k`"
means post-integration, post-projection, stage-1-fresh state. **That knowledge
must be part of the framework's taught contract**, not internal lore ([D-056][d-056]).
The semantics of [§10.5][s10-5] and [§10.6][s10-6] must be stated in component-author
documentation ([Appendix A][sA]), with this IMU as the worked example.

The failure mode of not knowing it is instructive. An author who distrusts the
sweep order adds a defensive one-tick delay or re-derives the integrals in the
sampler. Either one silently degrades the model.

**When the coupling is genuinely two-way, the latch becomes a wire back**
([D-056][d-056]). The IMU's coupling is one-directional, from integrals to
sampler. Suppose the flow itself needed the interval-relative value, say for
integrator saturation within the sampling interval. Then the sampler publishes
the sample-instant values from its *[feedthrough](#g-feedthrough)* stage (the
stage with an instantaneous input-to-output dependence). The continuous
`x_deriv` computes `x − u.latch`.

The feedthrough stage is the right one because `y_direct` reads `u`. The
latch port therefore carries the current tick's values, held by zero-order
hold (ZOH) until the next. A `y_state`-published latch would be one period
stale. Both cross-wires consume the other side's ports, and the feedthrough
graph stays acyclic. The integrals' stage 1 feeds the sampler's `y_direct`,
and the sampler's `y_direct` feeds the integrals' `x_deriv` edge
([§5.4][s5-4]). The "reset" becomes a visible tier-crossing feedback loop.
That is what it always was, physically.

### 8.7 Rate scopes

An [assembly](#g-assembly) (a component of pure composition) schedules its children through
one declaration, `sample_times`, its [rate scope](#g-rate-scope). This section gives its spelling
and its keys, then what it never holds and why it belongs to the type.

The declaration maps each child name to a `Relative` or `Absolute` entry, as
in this one.

```julia
sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))
```

These are the two forms that [§10.5][s10-5] defines ([D-185][d-185]). Relative entries compose
affinely down the tree, absolute entries anchor, and all are compiled to one
`(D, Φ)` pair per discrete [component](#g-component) (the unit of modeling, leaf or assembly).
[§10.5][s10-5] also holds the wrappers' definitions and their validation. The
declaration is optional, and so is any given key ([D-042][d-042]). Since an unlisted
discrete child defaults to `Relative(1)` ([§10.5][s10-5]), only multiplied, phased or
anchored children need appear.

**Keys are immediate child names only** ([D-042][d-042]). A deep key would
edit another type's design from outside, and the composition rule guarantees
an author never needs to.

Container elements ([§8.5][s8-5]) are immediate children, so `"aircraft/red"` is a legal
key, and `sample_times` needs no rule change for them ([D-085][d-085]). The bare field
name is sugar that applies one uniform declaration across all elements. The
sugar keys on the *field*, not on a path segment, so a name-transparent
container keeps it unchanged. `(children = Relative(2),)` is the uniform
spelling for a `Group`.

A `sample_times` key on a continuous child is a build error
([D-042][d-042]). It is the declaration-time side of a run-time fact. A
continuous [bundle](#g-bundle) (the `NamedTuple` of views a component function
receives) carries no `Δt` ([§10.5][s10-5]).

`Δt_base`, `h` and `N_base` appear in no declaration. They are deployment
decisions fixed at deployment ([D-254][d-254]). [§9.2][s9-2] gives the three
sources for `Δt_base`.

The declaration belongs to the assembly type, not to the child instance
([D-042][d-042]). The reason is that a sample time is a design ratio or a
modeled instrument's intrinsic rate ([§10.5][s10-5]), never a per-instance
value. An instance wrapper in the style of FlightCore's `Subsampled` is
rejected ([D-042][d-042]).

### 8.8 Computed connections and generic holding

`u_connections` and `y_connections` are ordinary functions evaluated at build
against the concrete instance. They may therefore *compute* entries from child
[contracts](#g-contract) (each child's declared interface). That is derivation from
declarations, which [§8.2][s8-2] blesses. The section covers the passthrough helpers,
the single authored feed list and [generic holding](#g-generic-holding) (a parent holding a child
through a non-concrete field type), in that order.

#### The passthrough helpers

The framework helper `input_passthrough` is sketched below. The sketch ends with
a `World` [assembly](#g-assembly), a [component](#g-component) of pure composition. It passes up the input
[faces](#g-face) (the names [ports](#g-port) wear on component boundaries) of its `aircraft` and
`atmosphere` children.

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
problem ([§8.6][s8-6]) makes a path unrecoverable from an instance. A face
name containing dots is a legal final path segment on the internal-endpoint
side ([D-046][d-046]). That holds precisely because slash is the only structural
separator.

Computed entries mix freely with hand-written ones in either declaration.
`resolve` and `input_faces` are build-pipeline primitives needed anyway, and
`input_passthrough` is a thin composition. That is what keeps the helper sugar
rather than machinery. There is no `rename` hook, because the boundary
declarations are ordinary code ([D-046][d-046]). An author renames by mapping over the
pairs. Normative signatures for both primitives are in [§13.3][s13-3].

Every error stays first-class.

- An `except` face the assembly then fails to wire is an ordinary
  unconnected input.
- A face both wired and passed through is a two-producers error
  ([D-145][d-145]).
- `except` or `only` naming a nonexistent face errors with the child's face
  list in hand.
- A `prefix = ""` collision is caught by the build's uniqueness check like
  any hand-written duplicate.

**The selectors are exclusive** ([D-251][d-251]). A call takes `except`,
`only` or `select`, one of the three and no more. `select` is a predicate
over the child's face names, and the helper keeps the names it accepts. More
than one selector given is `UnknownFaceSelection` with reason
`:multiple_selectors`, "more than one selector given", its payload naming the
selectors given.

**A call that gives a selector and keeps nothing raises
`EmptyFaceSelection`**, a warning on the `Build`'s list ([§9.2][s9-2],
[D-251][d-251]). A bare call over a faceless child is silent, because passing
nothing through is what it asked for. The payload names the helper, the child
path, the selector given with its names, and the child's face list.

The warning exists because an empty selection is almost always a typo the
unknown-names check cannot see. An `only` may name faces that exist while a
`select` matches none, or an `except` may list every face. It warns rather
than errors because a level may legitimately pass nothing through under one
configuration of a generic child.

`select` exists for feed lists, the idiom of "One authored feed list" below.
There the feed list already computes the `except` tuple. A closure over the same
list says the same thing without building the tuple.

The effective face list is plain printable data, the inspectable derived
contract of this instantiation. What computation does *not* do is auto-bubble
([D-043][d-043]). The author wrote down "every input face of this child that
I don't feed, I expose under this prefix", explicit at the type level and
evaluated at build.

The helpers come in pairs, because the name carries the direction
([D-171][d-171]). `input_passthrough` reads `input_faces(child)`, and the
selector filters *face names* within that set. The helper exists for the
pass-through case, where an assembly hands a child's unfed requirements up
one level. **`output_passthrough` is its sibling** ([D-209][d-209]). It is
splatted into `y_connections`, reads `output_faces(child)`, and has the same
`prefix`/`sep` surface, the same three exclusive selectors and the same
declaration-time error set. In the block below, `Systems` is an assembly
whose children include `aero` and `ldg`.

```julia
y_connections(sys::Systems) = (
    output_passthrough(sys, "ldg"; only = ("damaged",))...,   # "ldg.damaged"
    "aero/wrench" => "wrench",
)
```

`output_passthrough`'s consumer is one-level routing ([§6.1][s6-1], [D-209][d-209]). Every
level re-exports the outputs it surfaces, so the output side needs the
computed spelling the input side already has.

Both helpers take `child_path` naming an immediate child, container key
segments included ([D-207][d-207]). The default `prefix` folds the path's
slash into `sep`, so `"gear/1"` labels its faces `"gear.1.…"` and the default
stays a legal face name for every blessed `child_path`. An explicit `prefix`
is used verbatim. A deeper path meets `resolve`'s one-level rejection like any
other wiring endpoint ([§13.3][s13-3], [D-207][d-207]).

There are two helpers rather than one keyword ([D-171][d-171]). The boundary
declarations split by direction into `u_connections` and `y_connections`, and
after that split a single call cannot emit entries into two different
declarations.

#### One authored feed list

The `World` example's two-entry `except` understates the real shape. Every
level of a realistic tree is a generic [seam](#g-seam) (a narrow, named
interface kept deliberately thin). An assembly that feeds some of a child's
input faces while passing the rest up must name the fed ones in `except`. At
the scale of Flight.jl's C172X demo, that is four seams and roughly ten names
at the innermost one. Each `except` tuple restates the wire list sitting in
the same assembly's `inner_connections`. That is structure kept in two
artifacts ([D-039][d-039]), the shape this design refuses elsewhere.

**Removing the duplication needs no vocabulary** ([D-145][d-145]). Declaration
bodies are ordinary code ([§8.5][s8-5]), so the author writes the feed list
*once* and both declarations compute their share of it. In the block below,
`Systems` also holds an actuator child `act` whose output faces feed `aero`
and `ldg`.

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

Adding an actuator channel is then one edit ([D-145][d-145]). The new pair
simultaneously creates the wire and removes the face from the input face
surface. The two declarations cannot drift, because neither holds the shared
names. Both are projections of the authored list, so the drift class is
removed rather than detected.

Every misspelling stays loud. A mistyped destination is an unknown-face error
with the child's face list in hand, whether the wire or the `except` entry
meets it first.

One asymmetry is stated openly. A pair *omitted* from the list is not an error
but a structural change. The face leaves the `except` set and joins the input
face surface, ultimately a [root input](#g-root-input) (the root component's own input face)
for [conditions](#g-condition), the data that set a build's state, to cover ([§14.6][s14-6]). What the
idiom preserves, and the helper below surrenders, is that the feed statement
exists to be reviewed. An omission is legible in one authored artifact, not
defined away as the complement of the wire list.

The line not to cross is deriving `except` from `inner_connections` itself.
A helper spelled `except = fed(sys, "aero")`, reading the assembly's own wire
list, would cross it. That is auto-bubbling under another name
([D-043][d-043], [D-145][d-145]). **The single source must be authored data,
never inferred structure** ([D-145][d-145]).

#### Generic holding

**Generic holding is an imposed derived contract** ([D-043][d-043]). A parent holding a
child generically constrains it exactly through the faces its wires and
interface connections reference. Build a `World` whose concrete aircraft lacks a
referenced face, and the error names the `World` entry. That is build-time
structural typing with no new vocabulary. A formal required-faces declaration on
domain abstract types remains possible sugar ([D-251][d-251]).

Scalar faces make partial scripting compose ([D-207][d-207]). A guidance
[scenario component](#g-scenario-component) (the home of a sim-time script) wires `mode_req` and `EAS_ref`,
the equivalent-airspeed reference. The remaining faces stay exported for GUI or
defaults. That is impossible with a bundled face, under the write-side rule of
[§4.3][s4-3].

---

