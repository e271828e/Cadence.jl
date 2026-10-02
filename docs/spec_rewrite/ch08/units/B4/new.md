#### Events: `state_events`

`state_events` declares an ordered, named collection of
[guard](#g-guard)/handler pairs (each guard the declared predicate of its
event). A pair is spelled `StateEvent(guard, handler)`, with no detection
keyword. Detection policy is declared by the guard's return type instead
([D-179][d-179]). A `Bool` guard makes the event
[boundary-detected](#g-boundary-detected), checked for edges at step
boundaries only, with no root-finding. A guard returning the nominal scalar
makes it [localized](#g-localized), with the crossing instant bracketed by
root-finding over trial sweeps ([§10.4][s10-4]).

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
their contract ports. It assigns the remainder to stage 2, builds the graph,
and probes the stage-2 chain in topological order with real upstream values.
The "decoder takes no inputs" property is exactly what makes the derivation
well-founded.

A leaf's declarations do carry its tier ([D-195][d-195], [D-220][d-220]), and
that is a different fact. The tag refused here is the *stage* tag on a port,
which stays invisible either way.

#### Completeness

The build checks three rules in the structure step ([§9.1][s9-1]). They are
stated here because they are properties of the declarations, not of the
wiring.

A non-empty store needs its update. `x_init` with fields and no `x_deriv`
method, or `s_init` with fields and no `s_update` method, is a build error.
The first case is continuous state with no [flow](#g-flow) (the continuous
derivative function, `x_deriv`), the second a discrete store nothing updates.
The framework will not silently supply `ẋ = 0`, which is a model, not a
default. An unupdated discrete store is a parameter in disguise, and
parameters are plain struct fields. The didactic style says exactly that.

An empty store is a stateless leaf's tier marker (above) and owes nothing.
`m_init` carries no such obligation either. Modes are written by handlers, and
a component may legitimately declare modes no event of its own transitions.

An event needs both halves. A `state_events` entry whose guard or handler has
no method for the component type is a build error. Method lookup catches it
at declaration-reading time, rather than as a `MethodError` at the first
firing. An event that fires only in a corner of the envelope would otherwise
hide the omission indefinitely.

Tier is declared by the store. Every leaf declares `x_init` or `s_init`, and
the two are disjoint, so every leaf announces its tier in one place
([D-195][d-195], [D-263][d-263]). A stateful leaf announces it in the update
law as well, `x_deriv` beside `x_init` and `s_update` beside `s_init`. The
two output stages are one pair of names shared by both tiers, so they
announce nothing and cast no vote ([D-220][d-220]).

**The remaining tier-implying declarations must agree** ([D-112][d-112],
[D-249][d-249]). `m_init`, `state_events` and `x_projection` are
continuous-only, because the event system is continuous-side only
([§5.2][s5-2], [§3.2][s3-2], [§14.1][s14-1]) and projection's one manifold is
the continuous state's ([§2.2][s2-2]). A `Pinned` entry in a contract is
continuous-only, because the discrete tier pins wholesale and the marker
there says nothing. No arity carries a tier. Every declaration takes the
component alone, and `ws_init` takes the scalar on both tiers
([D-263][d-263]).

Disagreement is `DeclarationOnWrongTier` ([Appendix C][sC]). It is reported
as the offending declaration, with the tier the leaf's other declarations
announce. It covers declaring both `x_deriv` and `s_update`, a `Pinned` entry
on a discrete leaf, and the mixed-store cases the split state letters restore.
Those are both stores on one leaf, an `x_init` on a leaf whose update law is
`s_update`, and an `s_init` on one whose update law is `x_deriv`.

A stateless leaf is a leaf whose store is empty, and it declares its tier the
same way. `x_init(::C) = (;)` makes it continuous, the tier [§13.7][s13-7]
steers stateless leaves to. `s_init(::C) = (;)` makes it discrete, one that
runs at its ticks and holds its outputs between them. A primitive declaring
neither store is `TierUnreadable` ([Appendix C][sC]).

`y_types` stays mandatory on a stateless leaf. A leaf with an empty store and
no output contract produces nothing and stores nothing, and it is refused as
`StatelessWithoutOutputs` ([Appendix C][sC], [D-263][d-263]). The stage
bundles follow the tier like any other leaf's, with no `x` or `s` field,
because the bundle law puts a store's letter in the bundle only when the
store is non-empty ([§5.2][s5-2]). [§13.7][s13-7] records why one stateless
continuous leaf already serves consumers on both tiers. Members of both
families, or of neither, are the [§8.5][s8-5] class errors.


### 8.3 Visibility: the contract is the interface

This section decides which of a component's values are public. It states the
visibility rule, then the inspection path for an intermediate, then the
checks that hold every stage's returns to the declared set.

**Visibility is decided by *where the value goes*** ([D-034][d-034]):

- a field declared in `y_types` is public;
- a field returned in `y` (a stage's own published signals) and declared
  nowhere is a build error;
- a component with no `y_types(::C)` method has no outputs, and a stateless
  leaf without one is refused as `StatelessWithoutOutputs` ([§8.2][s8-2],
  [D-263][d-263]).

That is the same move as class-by-declaration-shape ([§8.5][s8-5]).
[Ports](#g-port) in the [contract](#g-contract) (a component's declared
interface) are connectable,
GUI-listed, [snapshot](#g-snapshot)-carried and log-exported. A snapshot is
the immutable per-boundary publication. The table is public throughout, with
every [cell](#g-cell) a declared port, so nothing anywhere needs a
presentation filter. Visibility is binary, with no third class between the
two. A value a later function reads travels as a declared port like any other
([§5.2][s5-2]).

**The inspection path for an intermediate is declaration** ([D-194][d-194]).
That follows from the visibility rule above. One line in `y_types` makes it public,
checked and visible everywhere at once. FlightCore is the precedent, where an
intermediate was inspected by putting it in the `Model` output and no other
way. Publicity is never implicit. Even the minimal
[component](#g-component) writes `y_types(::LowPassFilter) = (x = Float64,)`,
one line, in exchange for "public" always meaning someone wrote it down.

**A declared port must be produced by exactly one stage**, stage 1 or stage 2
([D-252][d-252]). Those two classes are the whole classification, and the
framework produces no port of its own. Stage membership is derived over
`y_types` alone ([§9.1][s9-1]). Declared-but-unproduced and
produced-by-two-stages are build errors. A declared port no stage produces is
`DeclaredNotProduced`, which names the port, the stage products and the store
fields. Its remedy is returning the name from `y_state` ([§5.3][s5-3]).

The return side is checked too. A *returned port field* declared nowhere is a
build error at [probe](#g-probe) (the build's single evaluation of a user
function). The error carries a [did-you-mean](#g-did-you-mean) (the offending
name plus the list-in-hand it should have matched) against `y_types`. That is
the return-side analogue of [§8.4][s8-4] walkthrough 1 ([D-034][d-034],
[D-239][d-239]). The forgotten-branch walkthrough holds. A declared `P`
missing from the taken branch's return fails at probe. Missing from an
*untaken* branch, it fails loudly at that branch's first execution via the
always-on check.

**Stage returns must have the same `NamedTuple` shape on every branch**, the
branch-shape rule ([D-034][d-034]). Julia's type-stability discipline already
demands that for performance. The framework merely makes it a stated rule
with a good error.

**[Schema authority](#g-schema-authority) is total over the table**
([D-034][d-034]). Schema authority means declarations define structure and
evaluation only checks conformance. Every *cell* traces to an authored
declaration, and the always-on check's expected type for `y` is fully
declaration-derived. Return typos cannot silently define new cells
([D-239][d-239]). Protection against silently dropped partials rests on the
embedding guarantee ([§9.5][s9-5]). Promotion is airtight, so an observed
`Float64` is a true constant. Probe-observed expected types remain rejected
([D-034][d-034], [D-194][d-194]).

This section's rules exclude several designs the log rejects
([D-016][d-016], [D-034][d-034], [D-055][d-055], [D-194][d-194]), among them
the `unlisted` flag ([§4.2][s4-2]) and its satellite-function representation.

### 8.4 Failure walkthroughs (the error-locality grounding)

The five mistakes below decided declaration-vs-inference. The list gives
each with its failure site under this layer. Each was traced under inference-by-evaluation
too, and in every case the failure surfaced inside *correct* code, later, or
never. [D-032][d-032] carries the traces.

1. A typo'd wire (`:throtle`) is a build error at the connection, "no input
   `throtle`; did you mean `throttle`?"
2. A forgotten wire is `fuel_available`, read only by a [guard](#g-guard)
   (the declared function defining an event's predicate). It fails as the
   [§6.1][s6-1] unconnected-input error at build.
3. A forgotten branch field is `P`, returned by one branch only. It fails as a
   [probe](#g-probe) or first-execution error naming the declared
   [port](#g-port).
4. A type mismatch is a `Float64` fraction wired into a `Bool` input. It fails
   as a wiring-time error naming both endpoints and both [faces](#g-face) (the
   names ports wear on their component's boundary).
5. A typo'd return field is `P_shft = …` for a declared `P_shaft`. It fails as
   a probe error with [did-you-mean](#g-did-you-mean) (the offending name plus
   the list-in-hand it should have matched) against `y_types`. That one error
   is the whole report. The probe chain stops at the port check
   ([§13.1][s13-1], [D-239][d-239]), and an unproduced-`P_shaft` error would
   only restate it from the other side, since renaming the field produces the
   port. A declared port no stage returns, on a component whose returns are
   all declared, is the completeness pass's error, with the stage-product and
   state-field lists in hand ([§8.3][s8-3]). Every returned field is a
   declared port, so this one error form is the whole case. An intermediate a
   later function reads is declared like any other output and typo'd like any
   other output ([§8.3][s8-3]).
