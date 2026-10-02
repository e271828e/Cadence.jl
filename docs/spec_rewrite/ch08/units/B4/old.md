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
