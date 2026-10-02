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
