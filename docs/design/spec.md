# A Modeling & Simulation Framework for Flight.jl — Specification

---

## Contents

- [Part I — Foundations](#part-i--foundations)
  - [1. Purpose and method](#1-purpose-and-method)
  - [2. Formalism](#2-formalism)
    - [2.1 Events: two detection policies](#21-events-two-detection-policies)
    - [2.2 Exclusions (deliberate)](#22-exclusions-deliberate)
  - [3. Component taxonomy](#3-component-taxonomy)
    - [3.1 Continuous component (the hybrid primitive)](#31-continuous-component-the-hybrid-primitive)
    - [3.2 Periodic discrete component](#32-periodic-discrete-component)
    - [3.3 Assembly](#33-assembly)
  - [4. Ports and signals](#4-ports-and-signals)
    - [4.1 Immutable value semantics](#41-immutable-value-semantics)
    - [4.2 Consumers see ports, not stages](#42-consumers-see-ports-not-stages)
    - [4.3 Table mechanics and port granularity](#43-table-mechanics-and-port-granularity)
    - [4.4 Function-valued signals: environment access](#44-function-valued-signals-environment-access)
  - [5. Evaluation order and feedthrough](#5-evaluation-order-and-feedthrough)
    - [5.1 The scheduling problem](#51-the-scheduling-problem)
    - [5.2 Two-stage outputs: signatures, bundles and the hand-off laws](#52-two-stage-outputs-signatures-bundles-and-the-hand-off-laws)
    - [5.3 Structural feedthrough: stage roles, schedule and step boundaries](#53-structural-feedthrough-stage-roles-schedule-and-step-boundaries)
    - [5.4 Artificial loops and the escape hatch](#54-artificial-loops-and-the-escape-hatch)
    - [5.5 Algebraic loop policy: reject at build time](#55-algebraic-loop-policy-reject-at-build-time)
    - [5.6 Diagnostics: feedthrough tracing](#56-diagnostics-feedthrough-tracing)
  - [6. Composition: connections, aggregation and hierarchy](#6-composition-connections-aggregation-and-hierarchy)
    - [6.1 Connections and hierarchy](#61-connections-and-hierarchy)
    - [6.2 Aggregation: explicit summing junctions](#62-aggregation-explicit-summing-junctions)
  - [7. State and data representation](#7-state-and-data-representation)
    - [7.1 Continuous state: structured immutable, flat backing](#71-continuous-state-structured-immutable-flat-backing)
    - [7.2 Numeric genericity (eltype)](#72-numeric-genericity-eltype)
    - [7.3 Discrete state, modes, and workspace](#73-discrete-state-modes-and-workspace)
    - [7.4 The fused-evaluation lineage (prior art and how we got here)](#74-the-fused-evaluation-lineage-prior-art-and-how-we-got-here)
    - [7.5 Allocation policy: a scoped invariant](#75-allocation-policy-a-scoped-invariant)
- [Part II — Authoring and build](#part-ii--authoring-and-build)
  - [8. The declaration layer: components and assemblies](#8-the-declaration-layer-components-and-assemblies)
    - [8.1 Position: a declarative trait layer in plain Julia, no macros](#81-position-a-declarative-trait-layer-in-plain-julia-no-macros)
    - [8.2 The declaration inventory](#82-the-declaration-inventory)
    - [8.3 Visibility: the contract is the interface](#83-visibility-the-contract-is-the-interface)
    - [8.4 Failure walkthroughs (the error-locality grounding)](#84-failure-walkthroughs-the-error-locality-grounding)
    - [8.5 Assembly declaration: type-based, class by declaration shape](#85-assembly-declaration-type-based-class-by-declaration-shape)
    - [8.6 Paths, wiring and faces](#86-paths-wiring-and-faces)
    - [8.7 Rate scopes](#87-rate-scopes)
    - [8.8 Computed connections and generic holding](#88-computed-connections-and-generic-holding)
  - [9. The build pipeline](#9-the-build-pipeline)
    - [9.1 Three strata](#91-three-strata)
    - [9.2 The `Build` artifact](#92-the-build-artifact)
    - [9.3 Probing and input synthesis](#93-probing-and-input-synthesis)
    - [9.4 Activations: executable sets, laziness, caching](#94-activations-executable-sets-laziness-caching)
    - [9.5 The always-on conformance check](#95-the-always-on-conformance-check)
    - [9.6 Stopped-sim services as Stratum-C clients](#96-stopped-sim-services-as-stratum-c-clients)
    - [9.7 The compiled executor](#97-the-compiled-executor)
- [Part III — Execution](#part-iii--execution)
  - [10. Time and execution](#10-time-and-execution)
    - [10.1 Loop ownership: the framework owns the simulation loop](#101-loop-ownership-the-framework-owns-the-simulation-loop)
    - [10.2 The stepper seam](#102-the-stepper-seam)
    - [10.3 Signal-table consistency is a boundary property](#103-signal-table-consistency-is-a-boundary-property)
    - [10.4 Localization mechanics](#104-localization-mechanics)
    - [10.5 Multi-rate tick scheduling](#105-multi-rate-tick-scheduling)
    - [10.6 Event iteration at boundaries: to quiescence, budgeted](#106-event-iteration-at-boundaries-to-quiescence-budgeted)
    - [10.7 Real-time pacing](#107-real-time-pacing)
  - [11. Runtime periphery: the data plane](#11-runtime-periphery-the-data-plane)
    - [11.1 No shared mutable model: staged writes, snapshot reads](#111-no-shared-mutable-model-staged-writes-snapshot-reads)
    - [11.2 Outbound: snapshot publication](#112-outbound-snapshot-publication)
    - [11.3 Inbound: root inputs, claims and the frozen roster](#113-inbound-root-inputs-claims-and-the-frozen-roster)
    - [11.4 Inbound: per-device staging, representation and the drain](#114-inbound-per-device-staging-representation-and-the-drain)
    - [11.5 Inbound: the input trace](#115-inbound-the-input-trace)
    - [11.6 Devices: one authoring contract, no taxonomy](#116-devices-one-authoring-contract-no-taxonomy)
    - [11.7 The GUI write path: port resolution, peek, staging contract](#117-the-gui-write-path-port-resolution-peek-staging-contract)
    - [11.8 Diagnostics and liveness: the per-writer cell](#118-diagnostics-and-liveness-the-per-writer-cell)
  - [12. Runtime periphery: lifecycle and orchestration](#12-runtime-periphery-lifecycle-and-orchestration)
    - [12.1 Control plane](#121-control-plane)
    - [12.2 Loop scheduling: wait primitive, yields, thread budget](#122-loop-scheduling-wait-primitive-yields-thread-budget)
    - [12.3 The next-snapshot wait](#123-the-next-snapshot-wait)
    - [12.4 Shutdown protocol](#124-shutdown-protocol)
    - [12.5 Scripts and the mid-run mutation doctrine](#125-scripts-and-the-mid-run-mutation-doctrine)
    - [12.6 Run lifecycle and partial advance](#126-run-lifecycle-and-partial-advance)
    - [12.7 Replay: the trace re-drives the ordinary loop](#127-replay-the-trace-re-drives-the-ordinary-loop)
- [Part IV — Failure and services](#part-iv--failure-and-services)
  - [13. Error discipline](#13-error-discipline)
    - [13.1 Reporting policy: collect the checks, fail the evaluations fast](#131-reporting-policy-collect-the-checks-fail-the-evaluations-fast)
    - [13.2 Diagnostics: structured values, one carrier exception](#132-diagnostics-structured-values-one-carrier-exception)
    - [13.3 Build primitives: `resolve` and the face-list accessors](#133-build-primitives-resolve-and-the-face-list-accessors)
    - [13.4 Runtime failures: one catch site, an execution cursor](#134-runtime-failures-one-catch-site-an-execution-cursor)
    - [13.5 Termination is a state, not an exception](#135-termination-is-a-state-not-an-exception)
    - [13.6 Abnormal shutdown: one tail, two entries](#136-abnormal-shutdown-one-tail-two-entries)
    - [13.7 Tooling consequences: provenance and the component library](#137-tooling-consequences-provenance-and-the-component-library)
  - [14. Stopped-sim services](#14-stopped-sim-services)
    - [14.1 Conditions are path-addressed overlays on the declared defaults](#141-conditions-are-path-addressed-overlays-on-the-declared-defaults)
    - [14.2 Fragment composition: locality without schema](#142-fragment-composition-locality-without-schema)
    - [14.3 Resolution: flatten, validate, compile once](#143-resolution-flatten-validate-compile-once)
    - [14.4 Two application registers over one plan](#144-two-application-registers-over-one-plan)
    - [14.5 Boundary zero: an ordinary boundary with authored incoming transitions](#145-boundary-zero-an-ordinary-boundary-with-authored-incoming-transitions)
    - [14.6 Root-input totality: the missing-value error and the `override` combinator](#146-root-input-totality-the-missing-value-error-and-the-override-combinator)
    - [14.7 The trim problem: NamedTuple decisions, declared reads, named residuals](#147-the-trim-problem-namedtuple-decisions-declared-reads-named-residuals)
    - [14.8 The trim service: solver seam, scratch stores, commit and report](#148-the-trim-service-solver-seam-scratch-stores-commit-and-report)
    - [14.9 Mounting: problems as relocatable values](#149-mounting-problems-as-relocatable-values)
    - [14.10 Linearization: tap selectors, one seeded pass, a pure query](#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query)
- [Part V — Grounding](#part-v--grounding)
  - [15. Case studies](#15-case-studies)
    - [15.1 `Vehicle` today → this framework](#151-vehicle-today--this-framework)
    - [15.2 Torture tests for the §5.2 interfaces: `PistonEngine` and the FCS PID cascade](#152-torture-tests-for-the-52-interfaces-pistonengine-and-the-fcs-pid-cascade)
    - [15.3 Torture test for the §11 staging shapes: filter, joystick and GUI](#153-torture-test-for-the-11-staging-shapes-filter-joystick-and-gui)
    - [15.4 The interactive C172X demo: the periphery under load](#154-the-interactive-c172x-demo-the-periphery-under-load)
    - [15.5 The strapdown IMU: integrate-and-dump across the tier boundary](#155-the-strapdown-imu-integrate-and-dump-across-the-tier-boundary)
  - [16. Open axes](#16-open-axes)
- [Appendices](#appendices)
  - [Appendix A. Taught contracts: the author-facing index](#appendix-a-taught-contracts-the-author-facing-index)
  - [Appendix B. API synopsis: the entry points](#appendix-b-api-synopsis-the-entry-points)
  - [Appendix C. The diagnostic kind set](#appendix-c-the-diagnostic-kind-set)
  - [Appendix D. Glossary](#appendix-d-glossary)
    - [D.1 Component model and declaration layer](#d1-component-model-and-declaration-layer)
    - [D.2 Signals and data homes](#d2-signals-and-data-homes)
    - [D.3 Evaluation and scheduling](#d3-evaluation-and-scheduling)
    - [D.4 Time and events](#d4-time-and-events)
    - [D.5 Build pipeline](#d5-build-pipeline)
    - [D.6 Runtime periphery](#d6-runtime-periphery)
    - [D.7 Recording and replay](#d7-recording-and-replay)
    - [D.8 Stopped-sim services and the condition algebra](#d8-stopped-sim-services-and-the-condition-algebra)
    - [D.9 Error discipline and diagnostics](#d9-error-discipline-and-diagnostics)
    - [D.10 Meta-vocabulary](#d10-meta-vocabulary)

---

# Part I — Foundations

Part I fixes what the framework *is*, before any of it is spelled in code. [§1][s1]
states the purpose and the ground rules the rest of the document answers to. [§2][s2]
gives the formalism. It fixes the class of systems in scope, the two
event-detection policies, and the exclusions taken deliberately. [§3][s3] and [§4][s4]
introduce the two objects every later part manipulates. [§3][s3] gives the component
taxonomy, with two leaf classes and the assembly that composes them. [§4][s4] gives
the port, the addressable unit through which components exchange immutable
values. [§5][s5] is the load-bearing chapter. It fixes two output stages per
component, what each stage may see, and how those signatures alone yield a
static evaluation schedule. [§6][s6] lifts composition from a single component to a
hierarchy of them. [§7][s7] fixes where data lives, on both tiers and outside them.

Part I assumes nothing from later parts. It cites them for spellings only. [§8][s8]
shows how an author writes a declaration, [§9][s9] fixes when each declared fact is
checked, and [§10][s10] fixes what runs at a step boundary.

## 1. Purpose and method

This document specifies a modeling and simulation framework intended to replace
`FlightCore` as the substrate for `FlightPhysics` and `FlightApps`. It is the
[normative statement](#g-normative) of the design, and it states what the framework *is*, in the
present tense. The new framework must match or surpass `FlightCore` in
functionality, performance and flexibility. It must also be more rigorous and
explicit, so that model authors face a shorter learning curve and fewer latent
footguns.

The design adopts three ground rules.

- **Capability grounding, not interface grounding.** Requirements derive from
  what `FlightPhysics` and `FlightApps` demonstrably *do* in their code, unit
  tests and demos. Every `FlightCore` call site in the consumers is read as
  evidence of a capability the substrate must provide, never as a prescription
  for how it should be spelled.
- **No interface compatibility.** The new framework need not be
  source-compatible with the current consumers. A non-trivial migration of
  `FlightPhysics` and `FlightApps` is expected and accepted.
- **[Guarded additions](#g-guarded-addition).** Wherever the design admits functionality beyond what
  the consumers demonstrate, that functionality must be weighed against the
  fundamental strengths of Flight.jl. Those strengths are zero-allocation
  stepping, type stability, real-time interactive operation, live introspection
  through the GUI, and compositional flexibility.

All design axes are settled. They are the formalism, the [component](#g-component) taxonomy, the
signal and scheduling model, time and execution, the runtime [periphery](#g-periphery), the
declaration layer, the build pipeline, error discipline and the stopped-sim
services. Only the [§16][s16] items remain open. Those are the migration outline, the
GUI panel authoring API and the log/[trace](#g-trace) persistence deferral.

Decision rationale lives in `decisions.md`, including the alternatives
considered and the reasons they were rejected. This document cites it throughout
as linked `D-nnn` entries, one entry per settled decision. Entry numbers are
stable and never reused, so a citation here always names the same entry there.

---

## 2. Formalism

The framework simulates **[hybrid causal systems](#g-hybrid-causal-system)**. Such a system has five parts.

- **Continuous dynamics.** $\dot{x} = f(x, m, u, t)$ with algebraic outputs.
- **Multi-rate periodic discrete dynamics.** $s^{+} = g(s, u, t)$ at declared
  rates, with outputs held zero-order between [ticks](#g-tick).
- **Zero-crossing events.** [Guard](#g-guard) functions with handlers, under two detection
  policies, stated below.
- **Post-step manifold [projection](#g-projection).** An optional per-[component](#g-component) hook `x ←
  state_projection(x)`, applied after each accepted step. It covers quaternion
  renormalization, DCM orthonormalization and any other manifold-valued state.
  It is the cheap end of the projection-methods family from geometric
  integration.
- **External inputs.** The runtime injects them asynchronously, from pilot
  controls or the network, under the staging rules of [§11][s11].

### 2.1 Events: two detection policies

Both policies share one declaration, a [guard](#g-guard) function plus a handler. Only
detection differs.

- **[Boundary-detected](#g-boundary-detected) (cheap).** The framework checks each guard for a
  not-holding → [holding](#g-edge-semantics) edge against its [prior](#g-prior) ([§10.6][s10-6]) at step [boundaries](#g-boundary) only.
  There is no root-finding and no step rejection. The handler fires at the end
  of the step in which the edge was observed. The cost is one guard evaluation
  per event per step. This policy is fully compatible with fixed-step real-time
  execution.
- **[Localized](#g-localized) (precise).** The framework finds the crossing instant by
  root-finding. This policy serves events where timing precision genuinely
  matters. [§10.4][s10-4] gives the mechanics.

Detection policy never depends on real-time [pacing](#g-pacing) ([§10.7][s10-7]).

**Time events and state events.** The discrete [tier](#g-tier)'s [ticks](#g-tick), declared by
`sample_times`, are [time events](#g-time-event). Their instants are known in advance and
scheduled ([§10.5][s10-5]). Everything declared through `StateEvent(guard, handler)` is a
[state event](#g-state-event). Its instant is unknown and must be detected, by boundary check or
by localization. That is why the declaration is named `state_events` ([§8.2][s8-2]). The
criterion is detection versus scheduling, not which fields a guard reads. A
guard over an input is still a state event.

This arrangement gives step-boundary logic *well-defined semantics*. The
crossing defines the transition. Detection resolution is an execution-policy
detail.

A guard defines a **[predicate](#g-predicate)**. It does so in one of two forms, either a
`Bool`-valued form or the sign of a continuous function under the normative
convention **positive = predicate holds**. Writing the guard's sign value `σ`,
holding means `σ ≥ 0`.

An event fires when its predicate transitions from not-holding to holding. This
is [edge semantics](#g-edge-semantics), and it is uniform across both forms. [§10.6][s10-6] states the prior
bookkeeping. The opposite crossing direction is declared as a second event with
the negated guard. Stall entry and exit are one such pair.

Which form an author declares is not a free choice. **The guard's return type is
the declared policy.** A `Bool` return declares boundary-detected, and the sign
form declares localized ([D-179][d-179]). [§10.4][s10-4] states the rule, the exactness result
that motivates the `Bool` form, and the gate idiom for localizing mixed
predicates.

### 2.2 Exclusions (deliberate)

- **No DAEs / algebraic constraints.** The actual need is state manifolds, and
  [projection](#g-projection) covers it ([D-001][d-001]).
- **No SDEs / stochastic integrators.** Noise processes such as Dryden/von
  Kármán turbulence and sensor noise are modeled as ordinary RNG-driven discrete
  processes, that is, shaping filters. That modeling is faithful to how they are
  specified, and it is cheap. One consequence is elevated to a framework
  guarantee, **deterministic [replay](#g-replay)**. RNG state lives in [component](#g-component) discrete
  state (`s`), never in ambient globals, so the same seed gives a bit-identical
  trajectory.
- **No unconditional per-step hook**, so no `f_step!` equivalent. Every current
  use decomposes into one of two mechanisms. Projection covers quaternion
  renormalization. [Boundary-detected](#g-boundary-detected) events (checked for edges at step
  boundaries only, no root-finding) cover engine phase transitions and the stall
  hysteresis latch. For one class the mapping tightens semantics.
  Level-triggered cross-component resets become edge-triggered events. The gear
  friction regulator under `!wow` is one such reset ([§15.2][s15-2], [§16][s16], [D-001][d-001]).

---

## 3. Component taxonomy

There are three classes. Two of them are leaves with crisp, closed semantics,
and one is pure composition.

### 3.1 Continuous component (the hybrid primitive)

A continuous component is a classical hybrid automaton. It has these facets.

- **Continuous state** `x`, an isbits struct of real scalars ([§7][s7]).
- **Mode variables** `m`. These are piecewise-constant values (enums, integers,
  flags) that parametrize the [flow](#g-flow) and change *only* through event handlers.
- **Flow** $\dot{x} = f(x, m, u, t)$.
- **Two output stages** ([§5.2][s5-2]).
- **Events**, each a [guard](#g-guard) plus a handler. A handler may update `m` and may
  reset the component's own `x`. Both guard and handler read the fresh [boundary](#g-boundary)
  [signal table](#g-signal-table) ([§5.3][s5-3]).
- An optional **[projection](#g-projection)**.

Any facet may be empty. In particular, a [component](#g-component) with *no* continuous state,
only modes, events and mode-valued outputs, is an FSM. A single primitive
therefore supports both factorings of mode logic.

- **Internal modes** suit tightly coupled cases, such as stall hysteresis inside
  the aero component. They preserve cohesion and enable reset maps.
- An **external FSM component** feeding modes through a [port](#g-port) gives maximal
  purity, independent testability and swappable supervision logic.

**Rule of meaning.** A supervisor *commanding* a mode change is an ordinary
**input**. A component *detecting* its own transition is an **event**. The two
mechanisms carry two meanings and do not overlap.

### 3.2 Periodic discrete component

A periodic discrete component has these facets.

- **Discrete state** `s`, any isbits value ([§7][s7]).
- **Update** $s^{+} = g(s, u, t)$ at a declared rate.
- **Two output stages**, with [feedthrough](#g-feedthrough) applying at update instants. A
  proportional path is direct feedthrough. A state-only output is not.

Each [tier](#g-tier) carries its own state letter. `x` is the argument of the [flow](#g-flow) map
under `f`, and `s` is the argument of the jump map under `g`. The two are
different objects. `x` has a derivative and lives in the flat [buffer](#g-buffer). `s` has
none and is latched in a [store](#g-store) between [ticks](#g-tick). So they are spelled differently
([D-195][d-195]). Nothing is lost by the split, because a leaf is strictly one tier
([D-056][d-056]) and no [component](#g-component) ever reads another's state. A discrete component's `s`
influences continuous dynamics only **through signals**. Those outputs are held
zero-order between ticks.

**`m` is continuous-only.** A discrete component has no mode store. Its FSM
enums, flags and counters are ordinary `s` fields.

**Why.** `m` exists on the continuous side because modes must change *between*
flow evaluations, which is what handlers do. On the discrete side `g` already
runs at the only instants at which anything may change. A second store would
duplicate the discrete tier's own state semantics under another name.

### 3.3 Assembly

An assembly is pure composition. It holds submodels, child connections and
boundary [faces](#g-face). **It has no dynamics of its own.** Hybridness emerges at the
[assembly](#g-assembly) level. An aircraft is continuous vehicle parts plus discrete avionics
parts. The two-leaf split was upheld against the integrate-and-dump challenge
([§15.5][s15-5], [D-056][d-056]). Assemblies are flattened away for scheduling. They are retained
as the navigation and introspection hierarchy (GUI, logging, paths) and as
declaration-level [rate scopes](#g-rate-scope) ([§10.5][s10-5]).

---

## 4. Ports and signals

### 4.1 Immutable value semantics

[Ports](#g-port) exchange **immutable values**, typically isbits structs (floats,
`SVector`s, enums, nested immutables). The framework owns a **[signal table](#g-signal-table)**,
with one concretely typed **[cell](#g-cell)** per output port in the flattened model. A
producer's output [stage function](#g-stage-function) (`output_state`/`output_direct`, the two output
stages every component provides, on either [tier](#g-tier)) returns a named tuple of fresh
values. The framework writes each of those values into its cell, and consumers
read cells.

**Vocabulary.** These names are binding throughout this document.

- A bare *cell* is the table entry, and only that.
- A *store* is one of the discrete-state and mode registers ([§7.3][s7-3]). Stores are
  not cells.
- A *[staging cell](#g-staging-cell)* is a distinct compound term. It is the per-[device](#g-device) inbound
  register of [§11.4][s11-4]. Unlike a table cell it is mutated frame by frame, and it
  sits outside the table's publish-once discipline.
- A *[root input](#g-root-input)* is a source cell fed by the [periphery](#g-periphery) rather than by a producer
  ([§11.3][s11-3]).

Stated precisely, the signal requirement is **immutability plus frozen
references**. Signals may reference bulk data ([§4.4][s4-4]) provided that data is
read-only for the duration of the run. `isbits` is the common case, not the
rule.

This requirement has four consequences.

- There is no aliasing, ever. Nothing can be mutated under a consumer's feet.
- Concurrent reads from the GUI and logging threads are safe by construction.
- Isbits payloads allocate nothing, because named tuples of isbits are isbits.
- Each cell has a definite freshness, tied to its producer's position in the
  [schedule](#g-schedule) ([D-004][d-004]).

### 4.2 Consumers see ports, not stages

The [port](#g-port) is the addressable unit. A [component](#g-component)'s outputs appear to consumers, the
GUI and logs as one flat namespace (`dyn.vel`, `dyn.f_c_c`), which can be
materialized lazily as a view. Which output stage computes which port is a
scheduling annotation, invisible outside the component. Moving an output between
stages is non-breaking *for consumers*. No wire, log or panel sees it. The
scheduler does see it, because the [feedthrough](#g-feedthrough) graph and stage membership change
([§9.1][s9-1]).

**Visibility.** Which ports exist at all is a declaration-layer decision. The
output [contract](#g-contract) *is* the public interface. There are no private intermediates. A
value a later function needs is a declared port like any other, and a stage
result outside the contract is a build error ([§5.2][s5-2], [§8.3][s8-3]). A presentational
*unlisted* flag, skipped in logs and GUI but still connectable, is closed
([D-016][d-016]).

### 4.3 Table mechanics and port granularity

[§4.2][s4-2] fixed the [port](#g-port) as the addressable unit. Four questions remain. What is a
port on a [component](#g-component)'s boundary? How do values travel into cells and out of them?
What may a port hold? And how much should a single port carry? The last question
has two answers, one owed to the parties that read a port and one to the parties
that write it.

#### Ports and faces

A component's **ports** are its signal endpoints, one [cell](#g-cell) and one producer
each. Its **[faces](#g-face)** are the names those ports wear on the component's boundary.
For a leaf the two coincide. For an [assembly](#g-assembly) every face aliases an interior port
through its boundary declarations ([§8.6][s8-6]) and never creates an endpoint. The
distinction is kind-blind. Wiring and the [periphery](#g-periphery) address a child's faces
without knowing whether it is primitive or composite.

**Rule.** The port is the atomic unit of the entire periphery. It is one cell,
one [root input](#g-root-input), one staged write, one [device](#g-device) [claim](#g-claim) ([§11.3][s11-3]), one [trace](#g-trace) address
and one GUI liveness verdict ([§11.7][s11-7]).

#### Scatter and gather

**Scatter/gather is the whole protocol.** A [stage function](#g-stage-function)
(`output_state`/`output_direct`, on either [tier](#g-tier)) returns a named tuple. The
framework scatters each field into that port's concretely typed cell. Every
reader gathers views from cells. The readers are the next stage,
`state_derivative`/`state_update`, [guards](#g-guard), wired consumers and [snapshot](#g-snapshot) capture.

**The aggregate `y` is a merge semantically and virtual physically.**
Semantically, a component's `y` is the merge of its stage products, `merge(y_x,
y_xu)` on the continuous [tier](#g-tier) and `merge(y_s, y_su)` on the discrete. It carries
declared ports only. Physically no such object exists. `y` is reconstructed per
call from cells, as register-level field loads at zero cost for isbits, and is
never stored as an object.

Name collisions across a component's stages are a build error.

#### What a port may hold

**Stage returns are named tuples of port values, period.** A custom struct is a
first-class port *value*. It is one field of the returned tuple, one declared
port, one cell (`pose = KinPose{T}`). Nested fields get no cells of their own.
GUI and logs drill into them lazily (the view clause, [§4.2][s4-2]). Bare-struct returns
are rejected ([D-036][d-036]).

A port value's leaves are what the leaf walk reaches through `Real`s, static
arrays and isbits structs. The walk stops at an immutable type that is not
isbits and treats it as one opaque leaf (a leaf the table stores whole,
references included). That leaf is the [field handle](#g-field-handle) ([§4.4][s4-4]). A mutable type
anywhere in a port value is refused, and so is a handle-typed face surfacing as
a root input (`IllegalPortType`, [D-237][d-237]).

#### Granularity, read side

**Rule.** Wiring is port-granular. There are no sub-field connections. A
consumer that wants less than a bundle asks the producer for a loose port, or
takes the bundle and destructures. A field-projection connector is a [guarded
addition](#g-guarded-addition) (a capability the design admits but does not
build). Its shape is obvious, and it is not built.

**Granularity guideline.** Authors should bundle what *shares a stage* *and is
consumed together*. The first criterion is trivially enforced, because each port
has exactly one producing function. Bundling across dependency footprints is the
`KinData` mistake ([§15.1][s15-1]). Pose is stage 1 and velocity-derived quantities are
stage 2, so that bundle must split. Fan-out is free, so publishing both a bundle
and a hot loose field (`pose` *and* `q_eb`) is legitimate. It costs one extra
isbits cell.

**Example.** The sketch below shows the bundle, the loose hot field and a face
aliasing an interior port, in declaration form.

```julia
#a continuous leaf: one bundle port and the hot field published loose — two cells
output_types(::Kinematics, ::Type{T}) where {T <: Real} =
    (pose = KinPose{T}, q_eb = RQuat{T})

#the enclosing assembly: each face aliases an interior port, creating no endpoint
output_connections(::Vehicle) = ("kin/pose" => "pose", "kin/q_eb" => "q_eb")
```

#### Granularity, write side

**Write-side rule.** **Bundle what is written together** ([§15.4][s15-4]).

**Rule.** Data written by different external writers, or at different cadences,
must not share a port.

Pilot commands are the case in point. They are scalar faces under a namespace
prefix. The convenient bundle is assembled *downstream*, inside the graph, by an
ordinary component. That is legal by the read-side guideline, since the bundle
has a single producer and is consumed together.

The guideline and the rule compose into one principle. A port's granularity is
set by the finest-grained party owning either end, producers on the read side
and external writers on the write side. Field-addressed staging (a lens into
struct slots) stays a recorded guarded addition, unbuilt.

### 4.4 Function-valued signals: environment access

Atmosphere and terrain are **query-shaped**. Consumers evaluate them at
arguments of their own choosing, such as each gear strut at its own contact
point, or airflow at the vehicle pose. Ordinary [ports](#g-port) therefore carry them as
**immutable query objects**, called [field handles](#g-field-handle).

- An environment [component](#g-component) emits a field value (`ISAField(T_sl, p_sl, wind)`,
  `TerrainField(…)`), and consumers receive it through ordinary input ports.
  Inside their own [stage functions](#g-stage-function) (`output_state`/`output_direct`) they call
  query functions on it, such as `airdata(field, pos, vel)` and
  `ray_intersect(field, p, u)`.
- **Parametric models are isbits** (ISA, uniform wind, horizontal terrain).
  **Bulk-data models use the handle pattern.** The handle is an immutable struct
  combining isbits parameters with references to bulk data (heightmaps, wind
  grids, the geoid undulation grid) loaded at build time and frozen. Handles are
  rebuilt per evaluation without allocation, as immutable structs holding
  existing references. They are never `Ref`s, whose mutable cell allocates.
- **No mutable caches inside field objects**, such as memoizing interpolators or
  lazy loaders. Concurrent consumers and the GUI thread would race on them.
  Caches belong in the consumer's state, or the interpolant is restructured to
  be pure.
- Loggers treat field-handle signals specially. They skip or summarize them.

**The [value-level constructor](#g-value-level-constructor).** Every field-emitting component must expose the
map (component, input values) → handle as a plain, pure, public function. For
the `SimpleAtmosphere` successor that function is `atmospheric_field(atm; T_sl,
p_sl, wind)`. The field-emitting component's swept output stage must be a
**one-line call to that function**, never the other way round. The other way
round puts the query math in the output stage, where only a [sweep](#g-sweep) can reach it.

The reason is script-side. The condition math ([§14.1][s14-1]) must be able to construct,
outside any sweep, bit-for-bit the same handle the sweep would produce from the
same [root input](#g-root-input) values. One implementation serves two call sites, so there is no
drift. The drift avoided here is the silent-drift class that [§5.3][s5-3] exists to
kill. This is a *shipped component's obligation*, not something a consumer can
retrofit. The real component composes sub-models, and anyone else reconstructing
the map has re-created the drift class.

For bulk-data components the obligation is only that the query math be reachable
as a plain function. They own their resource loading, so building a handle
outside a build may cost a load. That cost is acceptable, because condition
authoring is design-time code.

**Example.** The sketch below shows the map as a plain function, and the stage
that does nothing but call it.

```julia
#the map: plain, pure, public — callable outside any sweep
atmospheric_field(atm; T_sl, p_sl, wind) = ISAField(…)

#the swept output stage: one line, nothing but the call
output_direct(atm, args) = (; … = atmospheric_field(atm; T_sl = …, p_sl = …, wind = …))
```

Pre-sampling is an **idiom built on top**, used where natural, not a separate
mechanism. In it, a component consumes the field and a pose and emits plain
data, as `Airflow` emits `AirData` for the whole vehicle. Resource injection
(declare-and-resolve service registries) is closed for the first cut ([D-008][d-008]).

The field-handle mechanism replaces threading `atmosphere`/`terrain` as
arguments through every update signature. It dovetails with the terrain
ray-query direction of the landing-gear redesign. Substitutability behind a
stable [face](#g-face) is declared with an abstract input entry, `terrain =
AbstractTerrainField`, which is structural substitutability ([§8.2][s8-2]). The consumer
wires to any concrete field type below the bound. That preserves today's
`AbstractTerrain` polymorphism at the declaration layer.

---

## 5. Evaluation order and feedthrough

### 5.1 The scheduling problem

At every evaluation instant, all signals must be computed consistently. Every
consumer reads values already produced at that instant. The build constructs the
directed graph of wiring edges and intra-[component](#g-component) [feedthrough](#g-feedthrough) relations. If the
graph is acyclic, a topological sort yields a **static evaluation [schedule](#g-schedule)**,
computed once at build time. The hot loop runs a flat list of `(component,
stage)` entries, with no runtime graph logic.

### 5.2 Two-stage outputs: signatures, bundles and the hand-off laws

Every [component](#g-component) provides exactly **two output stages**. [Feedthrough](#g-feedthrough) is declared
**structurally, by function signature**. There are no dependency annotations
anywhere in the design.

```julia
# continuous component — maximal legal view set of each bundle in comments
y_x  = output_state(comp, args)       # x, m, t [, ws] — no-feedthrough stage
y_xu = output_direct(comp, args)      # x, m, u, y_x, t [, ws]
ẋ    = state_derivative(comp, args)   # x, m, y, u, t [, ws]

# discrete component — the same two stage names over its own state letter
y_s  = output_state(comp, args)       # s, t, Δt [, ws]
y_su = output_direct(comp, args)      # s, u, y_s, t, Δt [, ws]
s⁺   = state_update(comp, args)       # s, y, u, t, Δt [, ws]

# every output stage returns its port NamedTuple — the return law below

# event system (continuous side only) — same fresh table, same state views:
σ        = guard(comp, args)        # x, m, y, u, t [, ws] — Bool or scalar sign value (§2.1)
(; x, m) = handler(comp, args)      # x, m, y, u, t [, ws] — keys by the return law below (§9.5)
x⁺ = state_projection(comp, x)      # manifold projection; positional (below)
```

The laws that govern that surface follow. They fix how a function receives its
arguments, which names it receives, what an output stage returns, and what a
handler returns.

#### The hand-off: one component, one bundle

**Rule.** Every function receives exactly two arguments, the component and one
NamedTuple [bundle](#g-bundle) of zero-copy views. From that bundle the author **destructures
by name** only what the body reads, as in `state_derivative(c::LowPassFilter, (;
x, u)) = …` and `output_direct(c::PID, (; s, u, Δt)) = …`.

**Why.** The [executor](#g-executor) (the compiled execution form of the schedule) issues one
fixed call shape, `fn(comp, args)`. Language semantics ignore unread fields.
Argument order cannot be confused, because there is no order.

Positional, `kwarg_decl`-reflected and slurping-keyword spellings are all closed
([D-074][d-074]). `state_projection` alone stays positional. It takes one store in and
returns the same store out, so there is nothing to select.

#### The bundle law: which names a component receives

**Rule.** Under the [bundle law](#g-bundle), a name appears in a component's bundle **iff the
corresponding store or fact exists for that component**.

| bundle field | present iff |
|---|---|
| `x` | the component declares `init_x` (continuous [tier](#g-tier)) |
| `s` | the component declares `init_s` (discrete tier) |
| `m` | the component declares `init_m` |
| `ws` | the component declares `init_workspace` |
| `u` | the [function family](#g-function-family) (which bundle fields a given function may legally receive) may see inputs **and** the component declares `input_types` |
| `y` | the component produces any table [cell](#g-cell) at all (`output_types` ∪ auto-published) |
| `y_x` / `y_s` | stage-1 [ports](#g-port) exist, under the tier's own spelling |
| `t` | always |
| `Δt` | the component is on the discrete tier |

**The stage-1 hand-down carries the stage-1 *return*, auto-published names
excluded.** An [auto-published port](#g-auto-published-port) is the framework copying a state or mode
field into a cell at stage-1 position ([§5.3][s5-3]), and stage 2 already holds `x`/`m`
(continuous) or `s` (discrete) directly. [§9.3][s9-3] already sources the rule. `y_x`,
or `y_s` on the discrete tier, comes from the stage-1 [probe](#g-probe)'s return. So a
component whose only stage-1 ports are auto-published has no `y_x`/`y_s` in its
stage-2 bundle at all ([D-169][d-169]).

Undeclared stores are *absent*, never `nothing`-filled. Destructuring a field
that does not exist for the component fails at the probe, inside the [§13.2][s13-2]
framing diagnostic. The diagnostic carries [did-you-mean](#g-did-you-mean) (the offending name plus
the list-in-hand it should have matched) against the legal field set. An example
is "`state_derivative` of `Foo` destructures `m`, but `Foo` declares no
`init_m`". One law covers tier facts, stage legality and declarations alike.

The mechanism is structured, not textual. Destructuring an absent field throws a
`FieldError` carrying the type and the field name as data (Julia ≥ 1.12). The
probe catches it *matched against the bundle's own NamedTuple type* and
synthesizes the framing diagnostic from the legal set. It classifies the field
as an undeclared store, a wrong-tier fact, or a name illegal for this function
family. No message text is scraped, and the bundle stays a bare NamedTuple
([D-074][d-074]). A getproperty-wrapper spelling is the recorded fallback, should
type-matched interception prove insufficient.

The wrong-tier class covers the state letters too ([D-195][d-195]). `x` and `m` are
continuous-only, and `s` and `Δt` are discrete-only, so destructuring any of the
four on the wrong tier lands in that bucket.

The per-function name sets are **closed**, one set per function per [tier](#g-tier). The
update laws carry their tier in the name, so `state_derivative` and
`state_update` have one set each. The two output stages are shared machinery
over both tiers ([D-220][d-220]), so `output_state` and `output_direct` have one set per
tier. On the continuous tier the sets are `x, m, t [, ws]` and `x, m, u, y_x, t
[, ws]`. On the discrete tier they are `s, t, Δt [, ws]` and `s, u, y_s, t, Δt
[, ws]`. Adding a name to any of them is a decision-log entry, not a
convenience. The comments in the signature block above state each function's
maximal legal set at each tier. A given component's bundle narrows that set to
declared reality, and the destructuring narrows it further to actual reads. That
three-level funnel (stage name at its tier ⊇ bundle ⊇ reads) is worth teaching
once, because a stateless component legitimately writes `output_direct` while
owning neither `x` nor `m`.

#### The stage return law

**Rule.** An output stage returns its port NamedTuple, `y`, and nothing else.

`y` scatters into the component's declared cells as always, and every value a
later function needs is one of those cells ([§8.3][s8-3]). Stages are discovered by
method existence, and stage membership is a partition of the declared ports.

An empty `y = (;)` is a `DeadStage` build error at the probe ([§9.3][s9-3]). A stage
returning nothing at all computes nothing any consumer can read. That is the
inert-component check in the stage register ([§8.1][s8-1]).

#### The handler return law

**Rule.** A handler returns a NamedTuple carrying the stores it writes. A key is
present **iff** the corresponding store exists on the component **and** the
handler updates it.

That is the bundle law's *iff* shape, now governing the return side. A pure FSM
(modes and events, no `x`) returns `(; m = (; phase = running))`. An `x`-only
reset map returns `(; x = (; x..., ω = 0.0))`. A handler touching both returns
both. Padding forms such as `((;), m⁺)` and `(x⁺, (;))` do not exist ([D-090][d-090], on
the argument-side ground of [D-074][d-074]).

The semantics per key are these. When `x` is present, the value is complete
against the state field set. When `m` is present, the names-subset predicate
applies. An unknown key gets did-you-mean against `{x, m}`. This is the same
`FieldError`-shaped machinery [§13.2][s13-2] builds for bundles, now running in both
directions ([§9.5][s9-5]).

#### What the views are

The views themselves are unchanged in meaning.

- Own state. On the continuous tier `x` comes from the flat [buffer](#g-buffer) and `m` from
  the mode [stores](#g-store). On the discrete tier `s` comes from its store.
- Own published signals. `y` is gathered from the component's own table cells
  (the declared ports, [§8.2][s8-2]).
- Inputs. `u` is gathered from foreign cells through the wiring's name binding.
- The clock. `t`, and `Δt` ([§10.5][s10-5]).
- Scratch. `ws` ([§7.3][s7-3]).

The [signal table](#g-signal-table) holds only *produced* signals, never transported ones. Each
datum has exactly one home. The buffer holds `x`, the stores hold `s` and `m`,
and the table holds signals. No store mirrors another. Every bundle field earns
its place as a view genuinely readable, and no minimization of the set survives
without introducing a copy ([D-035][d-035]).

### 5.3 Structural feedthrough: stage roles, schedule and step boundaries

[§5.2][s5-2] fixes the two-stage surface and the laws that govern it. What remains is
the reading. A stage's role has two halves, what its name asserts and what it
may see. The rest of the section orders the stages into a schedule, then puts
that schedule inside a step [boundary](#g-boundary).

#### Stage roles: the names

**Mathematical symbols and API names are two vocabularies, deliberately.** This
document's formulas keep the symbols of the traditions they come from. `f` is
the continuous [flow](#g-flow) and `g` the discrete update, the hybrid-systems flow/jump
pair (Goebel–Sanfelice–Teel). `h` is the control/estimation convention that the
output map is `y = h(x, u)`, as in every navigation filter's measurement
function. The API spells the same objects as words, so that a name bound in an
author's own module is unambiguous evidence of a forgotten import ([D-220][d-220]). The
correspondence is one to one.

| symbol | declaration |
|---|---|
| `f`, the flow | `state_derivative` |
| `g`, the jump | `state_update` |
| `y = h(x)` | `output_state` |
| `y = h(x, u)` | `output_direct` |

**Rule.** A stage's **name** states the **dependence class**, not the argument
list. `output_state` is the `y = h(x)` case and `output_direct` the `y = h(x,
u)` case. So "no `direct` in the name" *is* the no-[feedthrough](#g-feedthrough) property, visible
at every definition site.

The names are deliberately non-exhaustive. Modes fold under the state. `m` is
state, and the name states the [feedthrough](#g-feedthrough) split rather than an argument
inventory ([D-075][d-075]). Ambient facts (`t`, `Δt`) and scratch (`ws`) ride unnamed.

The update law carries the [tier](#g-tier) in its name, `state_derivative` versus
`state_update`. The two output stages do not. One pair of names serves both
tiers, over each tier's own state letter ([D-220][d-220]). A stateful leaf's declarations
must agree on one tier throughout ([§8.2][s8-2]). A leaf mixing the update laws, or
declaring a store of one tier and the update law of the other, is a build error,
not a reading.

#### Stage roles: what each stage may see

**`output_state` is the no-feedthrough stage**, defined entirely by what it
cannot see. Its [bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives) carries no `u`, so "no feedthrough" cannot be violated by
construction. That structural guarantee is what stage-1 [ports](#g-port) contribute to the
[schedule](#g-schedule). They break would-be loops.

Stage 1 exists when the [component](#g-component) has state-derived ports, including any
state-derived intermediate a later function reads ([§5.2][s5-2]). Otherwise it is simply
absent. A stage that would produce none is the `DeadStage` error. An empty stage
is unwritable on purpose.

**Rule.** A declared output that matches a state or mode field by name and type,
and that no stage produces, is auto-published by the framework from the state
stores at stage-1 position ([§8.3][s8-3]). The match is against the declared stores,
`init_x` plus `init_m` on the continuous tier and `init_s` on the discrete. The
publication position is stage 1 on either tier. Publication is driven by the
public [contract](#g-contract) ([D-016][d-016]).

**`output_direct` receives all wired inputs plus the stage-1 hand-down.** The
hand-down is the component's own stage-1 ports, auto-published names excluded
([D-169][d-169]). A shared intermediate is therefore computed once and read, not
re-derived. Stage 1 declares it as a port, and stage 2 finds it in `y_x`, or
`y_s` on the discrete tier. Stage 2 receives the [state views](#g-view) too.
Conservatively, every stage-2 output is presumed dependent on every wired input.

**`state_derivative` and `state_update` run after the sweep**, when the full
[signal table](#g-signal-table) is complete and fresh, the component's own stage-2 ports included.
The fused idiom stands. Compute each law once, in a stage. Publish it. Let
`state_derivative`/`state_update` copy from `y`.

**Why.** The interfaces *reward* single-source-of-truth rather than making
duplication unwritable. Nothing ever needs computing twice ([D-015][d-015], [D-035][d-035]).

All output stages must be pure, with no side effects. State types make mutation
impossible anyway ([§7][s7]).

#### The schedule

**Rule.** The schedule runs all stage-1 functions in any order, then stage 2 in
topological order, then all `state_derivative` calls against the now-consistent
signal table.

The systemic consequence is that *evaluating the [RHS](#g-flow) means running the sweep*.
There is no incremental `state_derivative`-only re-evaluation. Nothing is lost
by that, because implicit solvers, linearization and trim already work this way.
They seed `x` and run the composite. [§10.3][s10-3] and [§10.4][s10-4] restate that consequence as
a property of the execution model. RHS evaluations and guard trial evaluations
alike run the *interior* sweep, the continuous-only variant of [§10.5][s10-5]. Discrete
entries are absent from it by construction, so discrete [cells](#g-cell) hold across the
step.

#### Step boundaries

**[Guards](#g-guard) and handlers read the same fresh world.** At a step boundary the order
is *integrate → project → [boundary sweep](#g-sweep) → guards*. So by guard and handler time
`y` is a fresh decode of exactly the state being transformed, and the state
views are that state itself. Handlers construct their `x`/`m` returns from raw
state naturally. A reset map is `(; x = (; x..., ω = 0.0))`, with no reassembly
from published fields.

**`state_projection` runs between a state write and its decode.** That is after
integration, and after any handler `x`-reset. Those are the only positions in
the schedule where no fresh `y` of the new state can exist yet.
`state_projection` is not *unique* in receiving raw state, since every function
gets state views. It is unique in that schedule position.

**The boundary sequence.** At each boundary the framework integrates, projects,
runs the boundary sweep, evaluates **all guards once** against that sweep, and
fires the eligible events. Each firing is `handler → state_projection`. The
sweep → guards → handlers phase then iterates to [quiescence](#g-quiescence) (the fixed point
where a round of handlers fires nothing), so newly enabled guards fire within
the *same* boundary.

> integrate → project → **[ sweep → guards → handlers ]** iterated to quiescence

The signal table is written **only by sweeps**, so a transition reaches the
table at the next round's re-sweep ([§10.6][s10-6]). The round that detects quiescence
leaves the table post-transition-consistent for whatever else the boundary does,
such as discrete [ticks](#g-tick) and logging.

**Rule.** Hence the [epoch rule](#g-input-epoch). A handler executes against exactly the world its
guard fired on. Own `y`, foreign `u` and own `x`/`m` alike come from the firing
round's sweep, so `y = h(x)` holds at every handler entry.

[§10.6][s10-6] settles the iteration itself, how far it runs and how often each event may
fire under the [firing budget](#g-firing-budget) (the per-boundary cap on how often each event
fires). Two of its rules matter here. Within a round each component fires at
most one event, and declaration order picks among that component's
simultaneously eligible events. Same-component sequential composition happens
*across* rounds. Each later event is re-decided against the post-transition
sweep rather than fired on a stale premise.

#### Why derivatives may read outputs

**Departure from the orthodox formalism, stated openly.** The textbook form is
$\dot{x} = f(x, u)$, $y = g(x, u)$. This design's `f` receives the orthodox
arguments *plus* the published table, $\dot{x} = f(x, m, y, u, t)$. The
composite map $x \mapsto \dot{x}$ is mathematically identical, so linearization,
trim and AD are untouched. The heterodox element is only that derivatives may
read outputs.

The teaching line is this. *"stage 1 publishes what you know from state alone;
stage 2 adds what needs inputs; your dynamics read your own published results
instead of recomputing them."*

**Why.** The decision was grounded in a component-by-component survey of
FlightPhysics/FlightApps ([§15.2][s15-2]). Derivative/output overlap is the *norm* in
this domain. Newton–Euler, kinematics, the piston engine, gear friction and
every discrete compensator all show it. That overlap is what makes the orthodox
split expensive here ([D-015][d-015]). FlightCore's fused `f_ode!` already embodied the
same economics. This design keeps them while adding checked scheduling.

**Shared expensive computations** are thereby solved uniformly. Compute once in
stage 2, publish, and let `state_derivative`/`state_update` consume the ports.
External consumers read the same ports, as an accelerometer model reads `f_c_c`.
The **computer/integrator split** remains fully expressible without framework
support. [§7.4][s7-4] carries the full statement, including when the factoring earns its
keep. Purity rules forbid the classic resolution by mutable caching, by design.

### 5.4 Artificial loops and the escape hatch

A [component](#g-component) that bundles a no-[feedthrough](#g-feedthrough) output with a feedthrough output in
one atomic evaluation unit can be **[port](#g-port)-level acyclic yet unschedulable**.
Simulink calls this an "artificial algebraic loop". The canonical instance in
this domain is rigid-body dynamics. Velocity out is pure state, and acceleration
out is feedthrough from total force. The [two-stage split](#g-stage-function) resolves it, and it is
the rung that absorbs most of the class. The `VehicleDynamics` instance ([§15.1][s15-1])
is velocity state-only with accelerations feedthrough, and it simply dissolves
under the split.

What survives the split is the case where a single component's stage-2 outputs
cross-couple through a neighbor. That case is port-level acyclic and stage-level
cyclic. The tracer ([§5.6][s5-6]) labels it **artificial**. Two remedies apply, in this
order.

- **Re-factor the [contract](#g-contract).** Before moving any code, re-examine the cycle's
  wires. An input the neighbor consumes *only in a fallback branch* is the
  archetypal false dependency. The neighbor is computing, on the component's
  behalf, a fallback whose semantics belong on the component's own side of the
  boundary. Move the branch to its natural owner and the wire disappears.

  The canonical instance is the landing gear's strut/steering pair. The steering
  model consumes the contact-point velocity azimuth `ψ_v` only in its
  disengaged, castoring branch. Castoring, however, is free-swiveling wheel
  physics. It is the strut's business, not the steering law's.

  ```
  # before
  strut ──ψ_v──▶ steering        # ψ_v consumed only by the castoring branch
  steering ─────▶ strut          # the pair of wires is the cycle

  # after
  steering ──(engaged, ψ_cmd)──▶ strut
  strut:  ψ_sw = engaged ? ψ_cmd : ψ_v    # nothing flows back
  ```

  Re-factoring the steering contract to emit `(engaged, ψ_cmd)`, and computing
  `ψ_sw = engaged ? ψ_cmd : ψ_v` inside the strut, deletes the backward wire
  outright. The factoring survives substitution, which is the test that it
  records structure rather than dodging the diagnostic. A stateful steering
  actuator produces `ψ_cmd` from its own state and still needs nothing from the
  strut ([§16][s16] records the migration).
- **Split the component.** This is the residual remedy, taken when both halves
  genuinely belong to the component and the split documents real structure. Its
  cost is stated where it bites. Visibility ([§8.3][s8-3]) is binary, so every
  intermediate shared across the new boundary becomes `output_types`, which is
  public, connectable and substitution-relevant. The mitigating idiom is the
  granularity guideline ([§4.3][s4-3]), which the split case satisfies trivially, with
  one producing stage and one consumer. The idiom spells out as **one
  struct-valued bundle port**, a `StrutGeometry`-shaped value, not N loose
  ports. The bundle type is then contract. That is a real cost, but a bounded
  and honest one. No visibility register is added for the orphaned
  intermediates. [D-034][d-034] and [D-055][d-055] (`unlisted`, `Private(T)`) stay closed.

The build diagnostic offers both exits explicitly. It reads "cycle through
`systems/aero` is artificial at port level — split the component, or narrow the
neighbor's contract". The offending stage-2 function is carried as a separate
[payload](#g-payload) field rather than dotted onto the path ([§8.6][s8-6], [§13.2][s13-2]).

The split is rare, and the ladder is what earns that word rather than asserting
it. The two-stage split dissolves the common shapes, and the contract
re-factoring absorbs the false wires. What is left for the split is cycles whose
halves really are one component's own work.

One consequence of stage-2 conservatism is worth recording. An input consumed
only by `state_derivative`, never by `output_direct`, still creates a scheduling
edge if the component has stage-2 outputs. In practice such components are
integrator-shaped and have no stage-2 outputs. The remedy, if ever needed, is
the same ladder.

### 5.5 Algebraic loop policy: reject at build time

A genuine cycle in the instantaneous dependency graph is a **build error**. The
diagnostic names the full path in the canonical slash form of [§8.6][s8-6], as in
`aero/F → dyn/a → aero/α̇ → aero/F`.

The user breaks the cycle explicitly, by one of three routes. They can insert
dynamics (the α-filter idiom), insert an explicit unit delay (`UnitDelay`,
[§13.7][s13-7]), or restructure. The α-filter idiom is already standard practice in the
domain and in the current C172 model. The unit delay carries a caveat. It
changes the model's [tier](#g-tier) structure. The broken signal becomes discrete, sampled
at [`Δt_base`](#g-dt_base) (the base tick period, an integer multiple `N_base·h`). That is a
modeling decision, not a transparent wire. Implicit delays and per-step
numerical loop solving are both closed ([D-005][d-005]).

Implicit *algebraic balances* inside a [component](#g-component), such as a turbomachinery
operating point, remain the component author's business. They are local, owned
and bounded. Rejecting framework-level loops does not forbid such models.

### 5.6 Diagnostics: feedthrough tracing

Tracing is **diagnostic only, never load-bearing**. Scheduling correctness comes
exclusively from the structural two-stage split. Tracing improves error messages
and verification. The scheduler triggers it when it finds a cycle, to classify
that cycle. A genuine cycle gets "insert a state", and an artificial one gets
the remedy ladder ([§5.4][s5-4]).

**Detection and naming.** A cycle surfaces as a topological-sort stall in
[Stratum](#g-stratum) B (one of the build's three phases: structure, schedule, activation).
The stalled subgraph is decomposed into **strongly connected components**. Each
nontrivial SCC names one cyclic cluster exactly, and each cluster becomes one
diagnostic. The diagnostic presents the cluster's members and the wires among
them as one readable loop in the canonical slash form ([§8.6][s8-6], `aero/F → dyn/a →
aero/α̇ → aero/F`). Neither the raw stall residue nor a single back edge names
the cluster correctly ([D-012][d-012]).

**Classification is [schedule](#g-schedule)-free.** It runs inside Stratum B's failure path,
where no schedule exists. None is needed, because each SCC member is evaluated
*once, in isolation*, at the [probe](#g-probe) point. That evaluation reads state views from
`init_*`, out-of-cycle [cells](#g-cell) from the acyclic prefix's probe values, and
in-cycle cells synthesized through `probe_value` ([§9.3][s9-3]) under tracer tags. The
tracer's product is a per-member dependence set rather than a value, so no
ordering has to be valid for the labels to come out right.

The loop is **real** iff every hop of the structural cycle survives in the
traced per-member maps. It is **artificial** ([§5.4][s5-4]) iff some hop dies, at the
component whose stage-2 function does not in fact route that input to that
output. No Stratum C machinery is touched. There is no [activation](#g-activation) (a re-run of
Stratum C at a given scalar type), no layouts and no table. This is the *local*
variant ([D-012][d-012]), the schedule-free per-member trace at the probe point, which is
what the cycle classifier uses. The "tracer activation" ([§9.4][s9-4]) names the other
variant ([D-012][d-012]), the global set-tracer run as an ordinary Stratum-C activation.
The two must not be conflated.

**Caveats, carried in the diagnostic rather than assumed away.** The trace
speaks for the branch taken at the probe state (the diagnostic-only doctrine,
[D-012][d-012]). Discrete members trace *structurally*, because the discrete [tier](#g-tier)'s
plain, wholesale-pinning declarations admit no tracer scalar. Structural tracing
is sound as a may-depend answer but never sharp, so the remedy hint is offered
only for continuous members. The hint itself is to split this component, *or* to
narrow the neighbor's [contract](#g-contract) when the dead hop's input is consumed only in a
fallback branch (the ladder, [§5.4][s5-4]). If a member's evaluation itself throws, the
diagnostic ships with the member list alone. Classification is a bonus on the
cycle error, never its precondition.

There are two modes, and they degrade gracefully.

- **Global (value-blind) set-tracer.** A `Real` subtype carries a set of input
  indices, unioned by every operation. It has **may-depend semantics**, a sound
  over-approximation. A saturated `clamp` still reports, and $u^2$ at $u = 0$
  still reports. It is exact, in one evaluation. It requires the traced stage-2
  code to be free of branches and lookups on *input-tainted* values.
- **Local (primal-carrying) set-tracer at sampled states.** This is the fallback
  whenever the global tracer hits an undecidable branch, such as piecewise
  friction, stall blending or any gridded lookup at an input-tainted coordinate.
  It reports the dependence pattern of the taken paths, sampled across
  randomized states. Its only misses are untaken branches ([D-012][d-012]).

**Boundaries.** Only *inputs* are seeded, so branching on state, modes,
parameters or time never interferes. Stage-2 functions also receive state views,
but neither those nor the stage-1 hand-down are ever seeded. Stage-1 functions
are never traced, since there is nothing to seed. Derivatives, [guards](#g-guard), handlers
and [projections](#g-projection) are outside tracing's jurisdiction entirely. A known tracer
blind spot is documented. Value-severing operations pass dependence through a
bare `Int` index, as a nearest-neighbor lookup does. Linear and cubic
interpolation are immune, because dependence flows through the fractional
weights.

Both modes ride the same `T <: Real` genericity as `Dual`. Dual-cleanliness in
CI effectively guarantees traceability.

---

## 6. Composition: connections, aggregation and hierarchy

[Components](#g-component) become a system through wiring. Connections route signals across the
[assembly](#g-assembly) hierarchy, and ordinary junction components sit wherever several
signals must combine into one. [§6.1][s6-1] gives the connection and hierarchy rules.
[§6.2][s6-2] gives the aggregation idiom they force.

### 6.1 Connections and hierarchy

A wire names its two endpoints by path, and those paths run down the hierarchy
of children. How far a path may reach decides whether a parent addresses a
grandchild's [port](#g-port) directly or every intermediate level must re-export it. That
question comes first here. Then come what type-checks a wire once both endpoints
resolve, how many connections each side may take, and what becomes of the ports
left unconnected.

#### How far a path may reach

**Rule.** Every connection endpoint names an **immediate child and one of its
[faces](#g-face)** ([D-207][d-207]). The rule covers all three wiring declarations ([§8.6][s8-6]). A
`child_connections` pair wires one child's face to another's. An
`input_connections` entry routes a face to an immediate child's face. An
`output_connections` entry sources a face from an immediate child's face.
[Container children](#g-container-children) ([§8.5][s8-5]) keep their key segment, so `"aircraft/2/face"` is one
level and not two. A container declared name-transparent ([§8.5][s8-5]) is the
exception. Its elements go by bare key, so `"ctl/face"` reads exactly as a plain
child's endpoint does, the same one level.

Routing across several levels is therefore declared level by level, with each
assembly speaking only of its own children. `Cessna172` hands its `trn` input to
`systems`, `Systems` hands it to `ldg`, and `Ldg` fans it out to its three legs.
The fan-out is declared at the level where the paths diverge.

```julia
input_connections(::Cessna172) = ("trn" => "systems/trn", …)
input_connections(::Systems)   = ("trn" => "ldg/trn", …)
input_connections(::Ldg)       = ("trn" => ("left/trn_field", "right/trn_field",
                                            "nose/trn_field"), …)
```

**Why.** [Faces](#g-face) become the only currency crossing an assembly boundary, so
substitutability holds at *every* boundary rather than only at generic ones.
This is the contract-is-the-interface principle of [§8.3][s8-3] with its one leak
closed. The second consequence is that the face graph is **total**. Every signal
crossing a boundary bears a declared face there, at every level it crosses.
Totality is what the condition algebra addresses against. An `at` prefix
stopping at a child's face has a name to resolve through ([§14.2][s14-2]).

The ceremony this costs is the re-export entry per level. It is the ceremony the
design already pays almost everywhere, because every level of a realistic tree
is a generic [seam](#g-seam), where one-level routing was mandatory in any case ([§8.8][s8-8]).
Where the entries multiply, they are computed rather than typed, through
`input_passthrough`/`output_passthrough` over a single authored feed list
([§8.8][s8-8]). Parallel routes threading many boundaries are the signal to gather them
into a component of their own.

Enforcement lives in the path-resolution primitive itself (`resolve`, [§13.3][s13-3]),
which walks declared field types alongside instances. Paths are validated at
build time, and renames break loudly.

#### Type-checking a wire

**Rule.** Two clauses type-check a wire ([§8.2][s8-2]).

**The nominal bound check** is stated over declaration evaluations. The
producer's declaration at `Float64` must be `<:` the consumer's entry at
`Float64`. It is one uniform rule, and it degenerates to exact equality for a
concrete entry. A violation is `WireTypeMismatch`.

Beside it, and **for a continuous consumer only**, stands the
**walk-compatibility clause**. A walking producer leaf, one the producer
declared `T`, requires a `T` entry. A [pinned](#g-walked) producer leaf satisfies either
entry, because frozen values embed upward under any [activation](#g-activation) (a re-run of
Stratum C at a given scalar type).

Both sides are declaration functions of `T`, so the clause is decided in [Stratum](#g-stratum)
A (one of the build's three phases: structure, schedule, activation) by
evaluating them at a marker scalar. That is declaration reading, and no user
stage code runs ([§9.1][s9-1]). A violation is `WalkingFaceAtFrozenEntry`, naming both
endpoints, the leaf and both declared leaf types. The message carries both
remedies. Declare the entry `T` if the consumer promotes, or feed it from a
non-walking source if the freeze is genuine.

For an abstract entry, whose leaves cannot be enumerated, the clause is decided
on the whole declaration. The producer's declaration at the marker, or the same
with every pinned leaf lifted to the marker, must be `<:` the entry at the
marker ([D-236][d-236]).

**The [tier](#g-tier) scope is load-bearing, not tidiness.** A discrete consumer takes the
bound check alone, because its stages read exclusively at real [ticks](#g-tick) in the
[nominal](#g-nominal) world (the `Float64` activation, and a declaration's `Float64` face). A
`Dual`-carrying [cell](#g-cell) exists only inside activations the discrete tier never runs
in ([§9.4][s9-4]). A continuous producer feeding a discrete consumer is therefore
unconditionally legal ([D-167][d-167]).

The same clause also gives the two [contract](#g-contract) sides their **failure asymmetry**.
The input-side forgotten `T`, the habitual `Float64` written at an entry whose
consumer really promotes, fails at the *first nominal build*, at the wire, with
both endpoints named. It fails there because an input has a build-time
counterparty. The output side has none, so its forgotten `T` lurks until the
first `Dual` activation. It lurks loudly, never silently ([§8.2][s8-2]).

#### Fan-out and fan-in

Fan-out is free. One producer may feed many consumers. The converse is strict.

**Rule.** Every input port takes **exactly one** connection, with no exceptions.
Aggregation is done by junctions ([§6.2][s6-2]).

The rule spans levels. A child input fed by a sibling wire at its own level
*and* handed up through its parent's `input_connections` is a two-producers
build error. Routing a face upward cannot silently double-feed.

#### Unconnected ports

There is no auto-bubbling of unconnected inputs ([D-043][d-043]). Unconnected output
ports are legal, silently, with no build-time warning ([D-084][d-084]). Unconnected input
ports are a build error, with no silent defaults.

**The check is a whole-tree property, not a per-declaration one.** Within a
single assembly declaration an unfed child input is simply *awaiting a claim
from above*, either a sibling wire or an `input_connections` entry handing the
obligation up one level ([§8.6][s8-6]). The error fires at the root build for any input
whose obligation chain never terminates. The one legitimate terminus fed by no
[component](#g-component) is the root component's own input face, a root input ([§11.3][s11-3]).

### 6.2 Aggregation: explicit summing junctions

Several physical quantities are totals over many contributors. Total wrench,
total mass properties and total internal angular momentum are the examples, and
today they are the work of the generated `get_wr_b`/`get_mp_b`/`get_hr_b` tree
walks.

**Rule.** N-to-1 physical aggregation is expressed by **ordinary junction
[components](#g-component) and explicit wires**.

There is no framework aggregation mechanism. There are no multi-connection
[ports](#g-port), no declared fold ops and no identity-element opt-outs. Every input port
takes exactly one connection, everywhere.

```julia
struct SumJunction{W, N} end        #type constructor, arity; library-provided

input_types(::SumJunction{W, N}, ::Type{T}) where {W, N, T <: Real} =
    NamedTuple{ntuple(i -> Symbol(:in, i), N)}(ntuple(_ -> W{T}, N))
output_types(::SumJunction{W, N}, ::Type{T}) where {W, N, T <: Real} = (; Σ = W{T})
output_direct(::SumJunction, (; u)) = (; Σ = +(u...))
```

The parameter is the *unparametrized* type constructor, as in
`SumJunction{Wrench, 3}`. UnionAlls are legal type parameters, so both [contracts](#g-contract)
derive their entries from it by applying it to the scalar of the [activation](#g-activation) (a
re-run of Stratum C at a given scalar type).

The junction is a continuous leaf, so its `input_types` entries are the tolerant
`W{T}` a promoting consumer writes. Walking, frozen and [root-input](#g-root-input) contributors
are all admissible behind them. `output_types` re-types the output [cell](#g-cell) per
activation ([§8.2][s8-2]). This is the same arity-via-computed-contracts pattern [§13.7][s13-7]
commits to for `Or{N}`.

Wired at an ownership boundary, the junction is ordinary structure.
`wr_sum::SumJunction{Wrench, 3}` is a field of `Systems` like any other child
([§8.5][s8-5]).

```julia
child_connections(::Systems) = (
    "aero/wrench" => "wr_sum/in1",
    "pwp/wrench"  => "wr_sum/in2",
    "ldg/wrench"  => "wr_sum/in3",
    "wr_sum/Σ"    => "dynamics/wr_ext",
)
```

#### What the explicit form buys

- **Every mistake is loud** under the declaration layer. A forgotten contributor
  is an unconnected-input error naming `in4`. A double-wired slot violates
  single-connection. A stale arity surfaces as one or the other. The bookkeeping
  is ceremony, never silence.
- **The aggregate is a first-class signal.** `wr_sum.Σ` is an ordinary port. It
  is loggable, GUI-visible, and fanned out to a second consumer (a loads
  monitor) for one wire.
- **Aggregation logic is arbitrary stage-2 code**, such as mass-properties
  composition with its transport terms, or weighted blends. It is not restricted
  to a declared commutative-associative binary op.
- **Fold order is author-visible.** It is the positional order of the junction's
  inputs. Reassigning contributors to different slots changes summation order,
  hence bits, because float addition is not associative. The ordering is
  deterministic per configuration and under author control, which is strictly
  more explicit than a framework-canonical order ([D-037][d-037]).
- For the handful of real sites, a **named site-specific junction** documents
  the contributor set better than generated slots, at the price of hard-coding
  it into a type. An example is `input_types(::VehicleWrenchSum, ::Type{T})
  where {T <: Real} = (aero = …, ldg = …, pwp = …)`. The generic positional form
  remains the tool for configuration-variable sites. Both are plain components,
  and the framework is not involved.

#### The hierarchical aggregation idiom

This is what replaces the tree walk. Only physical contributors publish these
ports. A strut publishes `wr_b`, and avionics publishes nothing.

Each [assembly](#g-assembly) that *owns* contributors aggregates them with an internal junction
and **exports the total**. The junction is a component inside the assembly, and
the assembly exports its `Σ` port ([§3.3][s3-3]).

**Why.** The [§6.1][s6-1] connection rules force this shape. A child is opaque to wiring
at every boundary, so every assembly that owns contributors must export its
aggregate.

**Example.** `Ldg` sums its three struts and exports `wr_b`. The systems
assembly sums `aero + ldg + pwp`. The vehicle wires the systems totals into
Newton–Euler.

Each recursion step of FlightCore's tree walk becomes one visible junction at
the level that owns the contributors. For the C172 that is about four junctions
and fifteen wires, written once. They read as a manifest of what weighs, what
pushes and what spins.

Frame responsibility is unchanged. Contributors publish in the common body
frame, applying their own mounting transforms at source.

Do **not** bundle the three quantities into one contribution struct.
Contributors are ragged. Aero has wrench but no mass, fuel the reverse, and only
`pwp` has angular momentum. A bundle forces zero-filled identity noise through
every port, which is the "silently sum nothing" hazard in a new coat ([D-037][d-037]).

A `sum_ports!`-style helper (instantiate + wire + export in one call) is
guarded-addition sugar, added when migration shows the pattern repeated.

The junctions themselves, [summing junctions](#g-summing-junction) and Bool gates, are the seed of the
standard component library committed in [§13.7][s13-7]. They are ordinary components with
no framework privileges, and the inventory grows strictly by migration demand.

#### The zero-contributor end of the same spectrum

Ragged contributors bottom out at none. Some configuration has a consumer whose
required aggregate input has *no* physical contributors at all. The
bare-propagation `Vehicle{NoVehicleSystems}` is one. It has zero contributors to
external wrench and to internal angular momentum, while `VehicleDynamics`
requires both unconditionally.

There is no junction to write and no producer to wire. [§6.1][s6-1] bans unconnected
inputs and silent defaults, and the identity element a zero-arity junction would
need is deliberately absent ([D-037][d-037]).

**Rule.** The spelling is a library `Constant` source ([§13.7][s13-7]) wired straight to
the consumer's input, as in `Constant(Wrench())` → `dynamics/wr_ext`.

**Why.** The zero total becomes declared structure. The configuration states
"external wrench ≡ 0" as a visible wire and an observable port, rather than as
an identity method the framework supplies behind the author's back.

This is not the banned default ([§6.1][s6-1]) in component clothing but its opposite.
That default is silent and consumer-declared. This one is loud and
assembly-declared, with the author writing the child and the wire, both
inspectable.

#### The cost, recorded

Adding a contributor from another subtree edits the assembly levels between its
producer and the junction ([§6.1][s6-1]) instead of zero. In exchange, explicit wiring
buys per-contributor values and intermediate totals as observable ports, with
every silence inverted into a warning or error ([D-007][d-007], [D-037][d-037]).

Consumer-declared folds with multi-connection legality are closed ([D-007][d-007] and
[D-037][d-037]).

---

## 7. State and data representation

### 7.1 Continuous state: structured immutable, flat backing

Each [continuous component](#g-continuous-component) declares its state by value (`init_x`, [§8.2][s8-2]). The
declaration is a NamedTuple whose leaves are drawn from a **deliberately closed
vocabulary, plain real scalars and `SArray`s (static vectors and matrices) of a
common eltype `T`**, and nothing else. `Int`s, enums and `Bool`s belong in
modes. Domain wrapper types (`RQuat`, `Ranged`) are not state leaves. An
attitude state is an `SVector{4,T}`, cast where rotation semantics are wanted,
as described below. The declaration is flat. Each field is one leaf, never a
`NamedTuple` of leaves. The condition register and the readers address a field
as one leaf ([§14.3][s14-3], [§14.4][s14-4]), and structure comes from the component tree, not
from the value ([D-094][d-094]). The framework does three things with the declaration.

- It computes a **flat layout** at build time, with compile-time offsets over
  one contiguous `Vector{T}` [buffer](#g-buffer) it owns.
- It **reconstructs** the typed immutable state value for a [component](#g-component) at each
  evaluation and passes it to every function receiving state views, under the
  argument rule of [§5.2][s5-2]. The reconstruction is field loads at known offsets,
  register-level, at zero cost.
- It receives immutable results back. Derivative functions return an `Ẋ`-typed
  value, which is scatter-stored into the flat `ẋ` buffer. Event handlers and
  [projection](#g-projection) return a new `X`, which is written back, with projection at the two
  [schedule](#g-schedule) positions of [§5.3][s5-3].

**What `Ẋ` is.** With the leaf vocabulary closed, the answer takes one line. `Ẋ`
has exactly `X`'s shape at the [activation](#g-activation) scalar. A scalar leaf's derivative is
a `T`, and an `SArray` leaf's is the same `SArray` at `T`. This is the
vocabulary rule paying rent. An invariant-carrying leaf like a unit quaternion
has a derivative off its own type, and `Ẋ` would need a separate derivation.
Here the attitude leaf is an `SVector{4,T}` and so is its rate. The conformance
predicate is structural. *Each field of `state_derivative`'s return scatters
into its field's block at `T`* ([§9.5][s9-5] states the check). That makes derivative
completeness a property of the layout rather than of author discipline. There is
deliberately **no `derivative_type` hook** ([D-190][d-190]).

**The buffer is authoritative, and typed values are ephemeral reconstructions.**
Nobody outside the framework ever holds a mutable reference to state.
"Ephemeral" is literal. An isbits view materializes in the caller's frame for
exactly the duration of the call, and has no existence between calls. Where it
materializes, in registers or on the spilled stack, is the compiler's business.
Re-materializing is the same loads, and it is value-identical because the value
is immutable and the buffer is unchanged within a [sweep](#g-sweep).

Whether repeated reads within a sweep re-materialize or reuse the loads is
codegen freedom, in the literal sense that the freedom is the code generator's.
The [executor](#g-executor) (the compiled execution form of the schedule) is spelled
rebuild-per-call, and hoisting a repeated read is the code generator's CSE. The
legality condition of that CSE is exactly the buffer-unchanged-within-a-sweep
rule ([§9.7][s9-7]).

The complementary rule is **[one home per datum](#g-one-home-per-datum)** ([§5.2][s5-2]). The buffer holds `x`,
the stores hold `s` and `m`, and the table holds produced signals. No store ever
mirrors another. In particular there are no state [cells](#g-cell) in the table beyond
[contract](#g-contract)-driven [auto-published ports](#g-auto-published-port) (published by the framework from the state
or mode store), which are interface, not transport.

**The vocabulary is closed because views must materialize without running
anyone's invariants.** Scalars and `SArray`s have invariant-free constructors.
`SVector`'s stores its tuple, `NamedTuple` construction runs no user code, and
nothing normalizes or clamps. Building a view through ordinary public
construction is therefore bit-faithful automatically. `reconstruct(flatten(x))
== x` holds identically, with no constructor bypass, no `reinterpret`, and no
reliance on a custom struct's memory layout mirroring the buffer's.
Invariant-carrying leaves are closed ([D-094][d-094]). Domain semantics are instead an
**explicit, invariant-free cast at the point of use**, the conversion today's
`f_ode!` code performs on its raw views. Invariants live where the design
already put them, in `state_projection` at [boundaries](#g-boundary) and in writers. Handlers
build their returned values through ordinary constructors, and the condition
apply converts authored values through ordinary `convert` methods ([§14.3][s14-3]).
Constructors run on the write paths, never on views.

Against today's flat-`Vector` + `ComponentArrays`-views pattern, this buys five
things.

- There are no aliased mutable views, where who writes what is a matter of
  convention.
- Derivative completeness is **structural**. The returned `Ẋ` has every field by
  construction, so a forgotten `ẋ` entry is impossible rather than silently
  stale.
- State fields arrive as the declared scalars and `SArray`s, immutable. The
  domain wrapper, where wanted, is one explicit invariant-free cast (`RQuat(x.q,
  normalization = false)`). That is the conversion the mutable-views pattern
  performed implicitly, now visible and chosen.
- The flat vector still exists. Integrator compatibility (OrdinaryDiffEq or
  custom), trim solvers, HDF5 logging and linearization all get their arrays.
- The hand-written per-aircraft state-space mapping layer
  (`get_x_ss`/`assign_x_ss!`/`get_u_ss`/...) is deleted, replaced by the
  framework's canonical layout.

### 7.2 Numeric genericity (eltype)

The state [buffer](#g-buffer), the pack/unpack machinery, and the entire **continuous
evaluation path** are generic over `T <: Real`. This one design property serves
four consumers.

1. Exact Jacobians for **linearization**, with ForwardDiff duals through the
   whole model, replacing finite differences.
2. Derivatives for **trim** solvers.
3. The **[feedthrough tracer](#g-feedthrough-tracer)** (the set-propagation instrument classifying a
   rejected cycle, [§5.6][s5-6]).
4. A trivially checkable **CI invariant**. One evaluation [sweep](#g-sweep) with `T = Dual`
   fails loudly (`MethodError`/`InexactError` at the offending line) on any
   Float64-pinning.

For consumer 1, the *discrete* side's exemption is not a limitation but the
exact answer. A frozen discrete [cell](#g-cell) is a constant with zero partials, which is
what "linearize the continuous dynamics with the discrete state held" means.
`frozen_discrete_walkthrough.md` works the chain through in detail.

The declaration layer keeps this scoping legible without putting it in the
author's way. A continuous producer's output declaration is a function of the
[activation](#g-activation) scalar ([§8.2][s8-2]), and cell types per activation are that declaration
*evaluated* at the scalar. Participation is authored per leaf. A leaf declared
`T` follows the activation, and a leaf declared with a concrete type is
deliberately [pinned](#g-walked). The state type is still derived. The framework walks the
`init_x`-derived type, with real leaves and `Real` type parameters following the
scalar. The discrete side stays plain and pins wholesale. Nothing anywhere comes
from inference through user code. Safety of the substitution rests on the
embedding guarantee stated in [§9.5][s9-5].

Scoping, meaning what actually needs genericity, covers roughly half the type
inventory and has three tiers ([D-011][d-011]).

- **[Walked](#g-walked)**, the payload and value types constructed during evaluation (about
  25 structs). These are the quaternion/attitude family, `Wrench`,
  `FrameTransform`, `MassProperties`, `KinData`, `AirData`, geodesy value types,
  `TerrainData` and continuous output structs. `Quaternion` becomes
  `Quaternion{N,T} <: AbstractVector{T}`. By invariance, `Float64` instances
  still match every existing `AbstractVector{Float64}` method, so existing
  behavior is untouched. The parametrization is mechanical. Constructors infer
  `T`, so call sites don't change, and `@kwdef` defaults pin the no-argument
  case to `Float64`.
- **Pinned**, the parameters and definitions. They stay `Float64`, since
  promotion handles mixing, and need no migration.
- **[Exempt](#g-walked)**, the discrete side (compensators, avionics). Linearization and trim
  differentiate continuous dynamics only.

For lookups, **table data is a pinned parameter and the query coordinate is
walked traffic.** Interpolations.jl evaluates generically over the coordinate.
`itp(x::Dual)` works through the `BSpline`/`scale`/`extrapolate` compositions in
use. Two caveats apply. `Linear()` interpolants have kinked derivatives at
knots. That is no regression against finite differences, but upgrade to `Cubic`
where Jacobian quality near a lookup matters. A manual chain rule via
`Interpolations.gradient` is the escape hatch for anything exotic, and the
pattern for wrapping non-Julia black boxes.

**Rule.** Three rules are author-facing. First, no `::Float64` argument
annotations in math. Use `<:Real` or nothing, which the codebase already mostly
does. Second, no `Float64`-pinned intermediates. Write `zero(SVector{3,T})`.
Third, **no `::SomeType{Float64}` return-type annotations** on the continuous
path, because they force converts and hence `InexactError`. The `*` method in
`attitude.jl` is the live example pattern.

### 7.3 Discrete state, modes, and workspace

Two homes sit outside the continuous [buffer](#g-buffer), and the rules they obey are
opposites. Discrete state and modes are state in the full sense. They are isbits
values that the framework owns and that a checkpoint copies wholesale. A
[workspace](#g-workspace) is mutable scratch, deliberately not state at all, governed by
contract rather than by checks.

#### Stores: discrete state and modes

**Rule.** Discrete state, a discrete leaf's `s`, and the modes `m` live in
**typed stores**. The framework overwrites a store when an update or a handler
returns a new value.

A store keeps the same immutable-value discipline as the table's [cells](#g-cell), in a
separate home. The vocabulary of [§4.1][s4-1] reserves the word *store* for these
registers and never counts them as cells. Stores never touch the integrator
buffer, and no arithmetic is ever done on them.

**Rule.** Every field of a store value is **isbits or a `Symbol`**. Isbits is an
immutable value that holds no references, transitively. Enums, integers,
`Bool`s, `SArray`s and nested isbits structs all qualify. A `Symbol` is admitted
as the idiomatic label. It is interned, immutable and never freed, so it copies
as a pointer to permanent data and serializes as its name. A `String`, an array,
or a struct holding either does not qualify, and neither does a struct nesting a
`Symbol`. Stratum A checks every `init_s` and `init_m` field and reports a
violation as `IllegalStoreField` ([§9.1][s9-1], [Appendix C][sC], [D-231][d-231]).

**Why.** State is what changes between [ticks](#g-tick). Bulk data and labels do not, and
their home is the component instance. The frozen-reference latitude signals
enjoy ([§4.1][s4-1]) exists for field handles ([§4.4][s4-4]), and no store needs it. Isbits is
what makes the rest of this section literal. Copying a store copies bits, so
checkpoint and [replay](#g-replay) of the entire discrete side is "copy the store values",
and a stored value has one fixed layout per component.

#### Workspace

A workspace serves heavy algorithms, such as an n≈20 Kalman filter.

**Rule.** A workspace is [component](#g-component)-declared mutable scratch, instantiated by the
framework. It arrives as the `ws` field of the [bundle](#g-bundle) (the NamedTuple of
zero-copy views a component function receives) in every bundle-receiving
function of the declaring component ([§5.2][s5-2]). `state_projection` is positional and
receives none.

**Rule.** A workspace is **excluded from state semantics**. It is not
snapshotted, not replayed and never a condition target ([§14.1][s14-1]). It must carry no
information between calls.

The framework **never inspects or mutates a workspace**. The workspace is an
opaque, opt-in escape hatch from value semantics, used at the author's own risk,
and its rules are contract, not checks. At call entry, contents are unspecified
beyond the structure the allocator itself established. A plan or factorization
configured at allocation is valid from then on. Scratch is garbage until written
this call, and nothing a previous call left behind may be relied upon. No
poisoning of scratch is attempted ([D-183][d-183]).

**Declared by allocation.** The well-known method *is* the allocator.

```julia
init_workspace(c::KF, ::Type{T}) where {T} =
    (P = Matrix{T}(undef, c.n, c.n), x̂ = Vector{T}(undef, c.n))
```

**Rule.** `init_workspace` follows the [tier](#g-tier) split of the port contracts. It is
`(::C, ::Type{T})` on the continuous tier and plain `(::C)` on the discrete.
`init_x`, `init_s` and `init_m` take the component alone on every tier.

**Why.** State re-scalars through reconstruction ([§7.2][s7-2]), so `init_x` never needs
`T`. Scratch is part of the `T`-generic surface itself, and its eltypes can come
from nowhere else. A one-argument `init_workspace` on a continuous leaf is
therefore an ordinary tier disagreement ([§8.2][s8-2]).

The allocator is called once per [activation](#g-activation) (a re-run of Stratum C at a given
scalar type) and once per scratch-store set ([§14.8][s14-8]). Sizes come from the
instance, and eltypes from the activation. Nothing downstream derives from a
workspace's type, and mistyped scratch detonates loudly at the `Dual` [probe](#g-probe).

The `undef` spelling is the recommended idiom and the sole visible marker that
contents are meaningless. It puts that fact in the declaration, which is the
register this store actually lives in. Declaration is by allocation, never by
initial value ([D-077][d-077]). The `init_` prefix means *establish*, as the device
contract's `init!` does ([§11.6][s11-6]), and carries no claim that the allocated
contents are a value ([D-220][d-220]).

**Available on both tiers.** Nothing in the workspace contract is tier-specific,
and a continuous workspace simply joins the `T`-generic surface. Under a `Dual`
activation the allocator is called at `Dual`, and the in-place math runs through
Julia's generic fallbacks. No BLAS is involved. Activations probe and linearize,
they don't run marathons.

The continuous side runs many calls per [boundary](#g-boundary), for RK stages, localization
trial evaluations and event re-[sweeps](#g-sweep). That multiplicity makes the
no-information-between-calls contract *more* load-bearing there, not less.

**The [blessed](#g-blessed) idiom for zero-allocation [ticks](#g-tick) with immutable `s`.** Do the
in-place math (`mul!`, `cholesky!`, BLAS) on the workspace. At the end, snapshot
into an isbits container and return it, as in `s = KFState(SVector{20}(ws.x̂),
SMatrix{20,20}(ws.P))`.

**The blessed idiom for a PRNG in a discrete leaf.** A generator object such as
`Xoshiro` is mutable, so it is scratch and lives in the workspace, allocated
once. The values that determine its next draw are immutable, so they are state
and live in `s`, which is what makes replay deterministic ([§2.2][s2-2]). The tick loads
them into the generator at entry and snapshots them back at exit, in the same
shape as the Kalman idiom above.

```julia
init_s(::Noise)         = (rng = (0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667),)
init_workspace(::Noise) = (rng = Xoshiro(0, 0, 0, 0),)

function state_update(c::Noise, b)
    r = b.ws.rng
    r.s0, r.s1, r.s2, r.s3 = b.s.rng        # load the words at entry
    z = randn(r)
    (rng = (r.s0, r.s1, r.s2, r.s3),)       # snapshot them back
end
```

Rematerializing the generator from its values each tick reads naturally and
allocates. A sampler with an out-of-line tail lets the object escape ([D-231][d-231]).

Construction and storage of large `SArray`s are cheap and compile fine. The
StaticArrays "codegen catastrophe" lives in its *operations*, the unrolled
matmuls, which are never called on snapshots.

The discipline is that snapshot values are for storage, logging and element
access only, never arithmetic. It is optionally enforceable by an op-forbidding
`ValueSnapshot{N,T}` wrapper, an `NTuple` with only `getindex` and iteration,
structurally what `SArray` is minus the methods. The practical ceiling is a few
KB comfortable and tens of KB defensible. Beyond that, value semantics stop
making sense.

#### Double-buffered mutable state (deferred)

Double-buffered mutable state is a possible future extension only, deferred
([D-013][d-013]).

### 7.4 The fused-evaluation lineage (prior art and how we got here)

The [§5.2][s5-2] interfaces are the end point of a four-step simplification arc. The arc
is recorded here because each step replaced a mechanism with something smaller.

1. **N output groups → exactly two** ([D-006][d-006]), at the price of an occasional
   [component](#g-component) split ([§5.4][s5-4]).
2. **Derivative binding → own-output access** ([D-015][d-015]). Passing the fresh [signal
   table](#g-signal-table) to `state_derivative`/`state_update` subsumes the
   declaration feature, and the "binding" becomes a one-line function body.
3. **Separate state arguments → the state decoder** ([D-016][d-016], [D-035][d-035]). Step 4 later
   reversed the second half of this step.
4. **Decoder-exclusive state access → stores-and-views arguments.** Step 3's
   second half was reversed ([D-035][d-035]). Once [§8.3][s8-3] made publication a deliberate
   interface act, the identity decode stood revealed as *transport*. It copied
   the [buffer](#g-buffer) into [cells](#g-cell) so that a buffer view could be replaced by a cell view.
   The fixed point is the argument rule ([§5.2][s5-2]), zero-copy views of the stores a
   function genuinely reads. What survives of step 3 is the uniform shapes, the
   fused economics, and the stage-1 decoder itself (today's `output_state`).
   That decoder is no longer the sole state gate. It is the no-[feedthrough](#g-feedthrough)
   stage.

For orientation, here is the prior art. Every causal framework meets the
shared-computation problem and resolves it per its architecture. **Simulink
diagrams** make integrators explicit blocks. Derivatives are ordinary wires into
`1/s`, and the computer/integrator split is their native idiom. **S-functions
and FMUs** use sanctioned *mutable caches*, DWork vectors and FMI's
lazy-evaluation caching, between their `mdlDerivatives`/`mdlOutputs`-style
callback pairs. **Modelica/MTK** write `der(x) = expr` natively with symbolic
CSE. The fused [sweep](#g-sweep) plus signal-consuming `state_derivative`/`state_update` is
the cache-free formulation that fits this design's purity rules. It is also what
FlightCore's fused `f_ode!` did economically, minus the checked scheduling.

The **computer/integrator split** remains fully expressible without any
framework support. A stateless component computes derivatives as outputs, wired
into a trivial state-holding component. It is the idiom of choice when the
factoring earns reuse, for example one Newton–Euler solver shared across vehicle
variants, or swappable kinematic descriptors against a common integrator shape.
Against a split-form spelling of the same model (four components, thirteen
connections), the merged form has half the components and wiring. Everything
derivable from pose alone migrates to stage 1, shortening the stage-2 chain.

### 7.5 Allocation policy: a scoped invariant

The allocation policy is not dogma. Three reasons support it, and only one is
about speed. First, GC-pause jitter control for real-time. Second, throughput
for [unattended runs](#g-unattended-run) (runs with empty staging and no snapshot readers). Third,
**the canary**. An unexpected allocation is Julia's most reliable symptom of
type instability. A zero baseline therefore makes `@allocated == 0` a
CI-testable invariant, one that catches inference regressions at the offending
commit.

- **Continuous hot path.** This is per-stage evaluation, plus everything else
  that runs unconditionally per frame or [boundary](#g-boundary). Those unconditional items are
  [guards](#g-guard), evaluated every boundary whether they fire or not, and
  `state_projection` at both of its [§5.3][s5-3] [schedule](#g-schedule) positions. The budget is
  exactly zero, CI-enforced at the [§9.7][s9-7] phase-body [seam](#g-seam) (`phase_bodies`).
- **Periodic [ticks](#g-tick) and event handlers.** These execute episodically, a tick when
  due and a handler only on firing. Allocation here is zero by idiom. The idiom
  is the [workspace](#g-workspace) (component-declared mutable scratch arriving as the `ws`
  bundle field) and snapshot pattern, plus immutable-value returns. The rare
  exception has a documented tolerance, scoped per body by the seam's
  granularity so it never loosens the continuous assertions.
- **Logging** is amortized-zero. Snapshots are records stored *inline* in a
  `Vector`, and `sizehint!` for the expected duration makes regrowth a
  non-event. The inline-storage claim is about the snapshot record's *fields*,
  not about everything reachable from them. A model carrying [§4.4][s4-4] [field handles](#g-field-handle)
  (immutable query objects consumers evaluate at their own arguments, such as
  heightmap terrain or wind grids) has a snapshot type with reference fields.
  Those fields ride as references to build-time-frozen data, with no copy and no
  per-boundary garbage, which is what the allocation claim asserts. What the
  claim does not assert is that the snapshot is `isbits`. The per-boundary
  allocation cost is zero either way, and the summarize-or-skip rule ([§4.4][s4-4])
  governs what such a field contributes on export.
- **Event firings are not recorded.** The [log](#g-log) holds boundary snapshots and the
  [trace](#g-trace) holds staged inputs ([§11.2][s11-2], [§11.5][s11-5]). Neither carries a per-event record.
  Which events fired at which boundary is recovered by [replay](#g-replay) plus the published
  modes. The honest remedy ([§11.2][s11-2]) is to declare the mode field public, and a
  mode field so declared is in every snapshot. An event-firing stream is a
  [guarded addition](#g-guarded-addition) (a capability the design admits but does not build).
- **Tools where garbage is unavoidable.** Arena allocation (Bumper.jl-style)
  serves scoped temporaries. A scheduled `GC.gc(false)` at frame boundaries
  moves collection out of the critical path. Julia has no per-object freeing, so
  these are the honest levers.

---

# Part II — Authoring and build

Part II covers everything that happens before a simulation runs: an author
declares a model, and the build turns that declaration into an executable
artifact. [§8][s8] is the declaration layer. It fixes the closed inventory of
well-known functions a component defines, the visibility each declaration
carries, and the shapes an assembly adds on top: children, paths, faces, rate
scopes and computed connections. [§9][s9] is the build pipeline that consumes them.
It fixes the three ordering strata, the `Build` artifact they produce, the probe
that runs every user function once against real values, activations at other
scalar types, the conformance check the probe leaves permanently in place, and
the compiled executor the loop will dispatch through.

Part II assumes Part I throughout. The taxonomy of [§3][s3] decides what may be
declared, the contracts of [§4][s4] are what a declaration fixes, and the two-stage
split of [§5.2][s5-2] is what makes feedthrough structural rather than annotated. [§7][s7]
fixes the homes the declared state occupies. Nothing here runs: the executor
built in [§9.7][s9-7] is not dispatched until [§10][s10].

## 8. The declaration layer: components and assemblies

This chapter says how an author spells a [component](#g-component). It covers where the
structural facts live, what the build takes as authoritative, and what is
checked against what. [§8.1][s8-1]–[§8.4][s8-4] cover the component side, and [§8.5][s8-5]–[§8.8][s8-8]
the [assembly](#g-assembly) side. The build pipeline is [§9][s9], and the stopped-sim service
spellings are [§14][s14]. The concrete syntax below is near-final in shape but
still illustrative in spelling.

### 8.1 Position: a declarative trait layer in plain Julia, no macros

A component is authored in ordinary Julia. Its [stage functions](#g-stage-function)
(`output_state` and `output_direct`, the two output stages every component
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

**Why.** The charter's debugging, tooling and comprehension workflows ([§1][s1])
decide it ([D-032][d-032]).

Redundancy between declarations and function bodies is accepted deliberately,
under one non-negotiable condition. **Every inconsistency fails loudly**, at
build time where possible and at first execution otherwise.

A macro can only ever *lower to* a layer like this one. A convenience macro
therefore remains addable a posteriori as pure sugar, on the `@kwdef`
precedent, and never becomes load-bearing.

The door stays open for the declaration layer specifically. A macro generating
the well-known declarations is admissible sugar *on top of* the plain-Julia
forms. It is never a replacement for them and never required to author a
[component](#g-component) ([D-166][d-166]). The obvious candidate is the `where {T <: Real}`
ceremony of a continuous `output_types` ([§8.2][s8-2]). Every rule in this part is
stated over the generated methods, so a macro that lowers to them adds
convenience and no semantics.

#### The namespace: declarations are extended, not called

**Rule.** The framework's extensible functions are extended, not called.
Authoring a component means adding methods to framework-owned generic
functions.

Julia admits that only through an explicit per-name `import`, or through a
qualified `Flight.state_derivative(…) = …` definition. The latter is the
`Base.show` idiom that [§16][s16] records for the extension-only periphery
surface. A component module therefore opens with

```julia
import Flight: init_x, init_s, init_m, init_workspace, input_types,
    output_types, state_events, output_state, output_direct, state_derivative,
    state_update, state_projection, child_connections, input_connections,
    output_connections, sample_times, transparent_container
```

**The explicit list is needed because `using Flight` alone is a silent trap.**
After a bare `using`, `state_derivative(eng::Engine, …) = …` defines a new,
unrelated `MyModule.state_derivative`, with no error and no warning. The
declarations are deliberately unexported ([D-117][d-117]). A bare `using` therefore
brings no name into scope for the definition to clash with, so there is nothing
for the language to detect. The build then sees a component with no
`state_derivative` method and reports a *modeling* diagnostic,
`StoreWithoutUpdate`, or `ClassUnreadable` when the whole inventory was
shadowed. A one-line namespace mistake is thereby reported far from the line
that caused it. That is the [§8.4][s8-4] inversion of [error locality](#g-error-locality) (the
property that a mistake fails at the site of the mistake), arriving through the
namespace.

Two mitigations, both normative. The first is that the import list above is
authoring surface, stated wherever a component file is first shown. The second
is that the two diagnostics run a **shadowing check**. If the component's parent
module defines a same-named function distinct from the framework's, the message
says so and names the missing import: "`MyEngine`'s module defines its own
`state_derivative`, distinct from `Flight.state_derivative` — add
`import Flight: state_derivative`". The check is a two-line `isdefined`/`!==`
test on names the build already looks up. The family's names are distinctive
by design ([D-220][d-220]), so a foreign binding of one of them in a component's
module is evidence of the missing import, not a coincidence.

A convenience macro expanding to the import list remains addable a posteriori
as sugar, per this section's macro doctrine. A re-export submodule is not an
alternative, because per-name `import` is the only *unqualified* extension
register the language provides ([D-117][d-117]).

**The same trap has a local-scope sibling** ([D-164][d-164]). Written inside a `let`, a
function body or a `@testset`, `output_state(::MyComp, (; x)) = …` does not add
a method to the global `output_state`. It binds a *new local function* of that
name. Calls within the block resolve to it and look correct. The generic
function the build dispatches on never learns of the component, which
therefore reads as one declaring nothing at all.

```julia
@testset "mycomp" begin
    output_state(::MyComp, (; x)) = …   #a NEW local one, not a method of
    …                                   #Flight.output_state; calls here
end                                     #resolve to it, and look correct
#outside: Flight.output_state still has no MyComp method
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

The net holds under a *partially* shadowed component too, because `output_types`
is still a declaration. A component whose [ports](#g-port) are declared but whose
stage went to a local binding reads as "declared but not produced" ([§8.3][s8-3]),
with the shadowing note attached, rather than as a component with nothing to
say.

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

**Rule.** A leaf's [contract](#g-contract) declarations (`input_types`, `output_types`,
`state_events`, and the shapes of `init_x`/`init_s`/`init_m`) must be
determined by the component's **type**, its type parameters included, and never
by its field *values*.

The value-discarding signature `input_types(::Engine, ::Type{T})` is the visible
form of the rule. The idiom for a contract that genuinely varies is the type
parameter, not the field, as in `SumJunction{Wrench, 3}` ([§6.2][s6-2]) and `Or{N}`
([§13.7][s13-7]). Arity is spelled in the type, at the price [§6.2][s6-2] states openly.

**Why.** The entry typing decides it ([§9.7][s9-7]). A component's [bundle](#g-bundle) is the
`NamedTuple` of zero-copy views a component function receives, and its key set
*is* its contract's. An entry of the [executor](#g-executor), the compiled execution form
of the schedule, carries what selects code in type parameters and what is plain
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

**`init_workspace` is the one exception**, and explicitly so. It is the
by-allocation [register](#g-register) ([D-077][d-077]), an allocator the framework *calls* rather
than a schema it *walks*. It legitimately takes sizes from the instance
(`init_workspace(c::KF, ::Type{T})` reads `c.n`, [§7.3][s7-3]), because no entry type
is derived from it.
### 8.2 The declaration inventory

One continuous primitive, declared end to end:

```julia
struct Engine <: AbstractComponent
    ω_idle::Float64; ω_min::Float64; J::Float64      #parameters: plain struct fields
    ω_rated::Float64                                 #unread here; §14.2's shipped condition uses it
end

#state stores: declared by initial value — types derived, nothing to drift
init_x(::Engine) = (ω = 0.0,)
init_m(::Engine) = (phase = off,)                    # off | starting | running

#input contract: continuous tier ⇒ the T-form; each entry states what may arrive
input_types(::Engine, ::Type{T}) where {T <: Real} =
    (throttle = T, starter = Bool, fuel_available = Bool, M_load = T)

#output contract = the public interface (§8.3); continuous tier ⇒ the T-form, participation per leaf
output_types(::Engine, ::Type{T}) where {T <: Real} = (M_shaft = T, P = T, ω = T)
#ω names a state field no stage produces → auto-published at stage 1 (§5.3)

#stage and update functions destructure their bundle by name (§5.2)
function output_direct(eng::Engine, (; x, m, u))
    M_shaft = m.phase === running ? torque_law(eng, u.throttle, x.ω) : zero(x.ω)
    return (; M_shaft, P = M_shaft * x.ω)
end

state_derivative(eng::Engine, (; x, y, u)) = (ω = (y.M_shaft - u.M_load) / eng.J,)

#events: ordered and named — order is load-bearing (§5.3, §10.6); detection policy by the guard's return type (§2.1)
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

**Rule.** `init_x` on the continuous [tier](#g-tier), `init_s` on the discrete, and
`init_m`, declare *by initial value*. The type is derived from the value.

There is consequently no second artifact to drift and no separate type
declaration to check. The [workspace](#g-workspace) (component-declared mutable scratch
arriving as the `ws` bundle field) is the exception to that [register](#g-register). It is
declared *by allocation*, as `init_workspace(::C, ::Type{T})` on the continuous
tier and `init_workspace(::C)` on the discrete one, and the method itself is
the allocator. A workspace earns the exception because it is not memory and
none of the by-value arguments below cover it ([§7.3][s7-3]). `init_workspace`
alone declares by allocation, and nothing downstream derives from the type of
what it returns.

This is the boundary of legitimate derivation. Deriving from another
declaration is sound, and deriving from evaluated user code is not. Declaring
types here too, `input_types`-style, with `probe_value` ([§9.3][s9-3]) synthesizing
the initial values, was rejected ([D-073][d-073]).

**Why.** The declared values are the base layer of the [condition](#g-condition) substrate
(a condition is the path-addressed sparse overlay that sets a build's state).
The overlays ([§14.1][s14-1]) fall back to them leaf by leaf, and the compiled store
writers bake `merge(defaults, overlay)`, so there must be an authored value
under every leaf.

The asymmetry against `input_types`/`output_types` is one of kind, not style.
[Contracts](#g-contract) describe table [cells](#g-cell), which are recomputed from scratch every
[sweep](#g-sweep), and so need only types. `init_*` describe [stores](#g-store), the model's
memory, which must have contents before the first sweep can run.

**These declarations stay one-argument**, and the criterion is the register
they live in ([D-166][d-166]). It is stated once here, and the blocks below refer
back to it. A *by-value* declaration states nominal physics, and its *types*
[walk by rule](#g-leaf-walk) (the derivation of per-activation types from a declared nominal
type). [§7.1][s7-1] forces every state leaf to follow the [activation](#g-activation) scalar (a
re-run of Stratum C at a given scalar type), so a `T` in the signature would
record no choice its author could make. Partials enter through per-invocation
seeding, never through initialization. A *by-type* declaration is a function
of the activation scalar, which is why `input_types` and `output_types` both
take it on the continuous tier. A *by-allocation* declaration takes the scalar
too, and `init_workspace(c, T)` is the standing precedent ([D-077][d-077]). The
criterion, not uniformity, is the rule. A `T` in a signature means a choice was
made there.

#### `input_types(::C, ::Type{T})` on the continuous tier, `input_types(::C)` on the discrete

An `input_types` declaration is a bare `NamedTuple` of types, with zero
framework vocabulary and no wrapper types. On **continuous consumers the
two-argument form is mandated**, and on **discrete consumers the plain one**.
That is the same [tier](#g-tier) mandate `output_types` carries. The [class](#g-class) (a
component's primitive-vs-assembly status) is read off declaration shape, and
the class fixes the form the declaration must take ([§8.5][s8-5]). Either violation
is `TierSignatureMismatch`.

Entries are **[face](#g-face) bounds, not [cell](#g-cell) types**, and the reading is
**permissive** ([D-167][d-167]). An entry states, per leaf, what the consumer *allows*
to arrive there. Entries come in three forms:

| entry | the leaf is | what may lawfully arrive |
|---|---|---|
| `T`, alone or as a type parameter (`SVector{3, T}`, `RQuat{T}`) | **tolerant** | the [activation](#g-activation) scalar or a frozen `Float64` |
| `Float64` | **demanding frozen** | never partials |
| `Int`/`Bool`/enum leaves, abstract reference-typed entries | as it always was | what the declared bound admits |

A `T` entry is what a promoting consumer writes, and it is the overwhelmingly
common case. A walking producer, a frozen discrete producer and a [root input](#g-root-input)
are all admissible behind it, so substitution stays intact.

A `Float64` entry is the **FFI door**. This input must never carry partials. A
[component](#g-component) whose internals cannot propagate `Dual`s (an opaque wrapper, a C
table, a hand-rolled solver) declares it, and its AD-incompatibility becomes
schema-visible instead of folklore. The failure then moves from a
`MethodError` inside user math at the first `Dual` [probe](#g-probe) to a named wiring
error at build ([§6.1][s6-1]).

`Int`/`Bool`/enum leaves and abstract reference-typed entries stand as they
always were. [Abstract entries](#g-abstract-entry) state **structural substitutability**, several
concrete producer types admissible behind one stable face. The field handles
([§4.4][s4-4]) are the demonstrated client, as in `terrain = AbstractTerrainField`.
They are spelled without `T`, because they are references rather than
numbers. They are still never the tool for eltype genericity. That is exactly
what a `T` entry is, a promoting consumer writing `SVector{3, T}` rather than
an abstract bound.

Names-only [contracts](#g-contract) were rejected ([D-033][d-033]). Inputs are the component's
*requirements*. Only against them are the unconnected-input error ([§6.1][s6-1]),
over-wiring detection and [did-you-mean](#g-did-you-mean) typo messages definable at all. A
did-you-mean message is the offending name plus the list-in-hand it should
have matched.

**Two clauses check a wire** ([§6.1][s6-1]). The **nominal bound check** is stated
over evaluations. The producer's declaration at `Float64` must be `<:` the
entry at `Float64`. It is one uniform rule, and it degenerates to exact
equality for a concrete entry, because concrete types are final. Beside it
sits the **tier-scoped walk-compatibility clause**. For a *continuous*
consumer, a walking producer leaf (one the producer declared `T`) requires a
`T` entry, while a [pinned](#g-walked) producer leaf satisfies either, because frozen
values embed upward. Both sides are declaration functions of `T`, so the
clause is decidable in [Stratum](#g-stratum) A (one of the build's three phases:
structure, schedule, activation) by evaluating them at a marker scalar. No
user stage code runs ([§9.1][s9-1]), and a violation is `WalkingFaceAtFrozenEntry`.

**Discrete consumers take the bound check only**, and that scope is
load-bearing rather than tidy.

**Why.** A discrete stage reads exclusively at real [ticks](#g-tick) in the nominal
world, and a `Dual`-carrying cell exists only inside activations discrete
stages never run in ([§9.4][s9-4]). Wires from a continuous producer to a discrete
consumer are therefore unconditionally legal. The unscoped variant is rejected
in [D-167][d-167].

Because entries are bounds, nothing is ever "overwritten". Cell types are
single-sourced from the producer side per activation ([§9.1][s9-1]), and a
`Dual`-carrying cell behind a `T` entry is the design working, not a promise
broken. The code-level complement is the **genericity obligation**, which says
that whatever scalars the wiring delivers, the consumer's math promotes. The
obligation is still checked by the `Dual` probe, never declared, and it is
**scoped to the `T`-entries**. A `Float64`-entry input imposes no such
obligation, which is its point. So **declarations record choices, and
obligations are checked**. The `T` entry records the tolerance choice, and the
probe checks the promotion.

**The permissive reading is the operative one, and the two readings it escapes
are rejected** ([D-033][d-033], [D-054][d-054], [D-167][d-167]). The *predictive* reading has the
entry saying what *will* arrive. The *envelope* reading has it as a promise to
promote. The permissive reading predicts nothing, and it is not constant,
because pinned entries are rare but real. That is what makes the `T` carry
information here.

**Root inputs are the one place an entry types a cell.** A root input is
produced by no component, so it has only the consumer declaration to take a
type from. The **root-input type** is the entry evaluated at `Float64`, and
only a *tight* bound determines one. A face surfacing as a root input must
therefore resolve to a concrete declaration, which [staging cells](#g-staging-cell), the
[trace header](#g-trace-header) and `probe_value` all need. Abstract-at-root is a build error, and
`AbstractAtRoot` names the face and the remedy, which is to wire a concrete
producer, or a stub child in a test rig ([§13.7][s13-7]). Under fan-out the
root-input type is the unique concrete declaration among its consumers, and
abstract co-consumers are checked against it. Two different concrete
declarations remain an error. The **root-input cells** at an activation follow
the root-input type by evaluating that same entry at the activation's `T`.
This makes **seedability schema-visible**. A `T`-entry root input is a lawful
linearization `B`-matrix tap, and a `Float64`-entry root input is *declaredly*
unseedable ([§14.10][s14-10]).

**Fan-out combines tolerance by a meet, not by agreement** ([D-168][d-168]). The root
input pins at every activation if *any* consumer's entry pins, and follows the
scalar only when every consumer tolerates. Concretely, the root-input cells at
an activation are the root-input type with every leaf following the scalar
when every consumer's entry admits that type, and the root-input type itself
otherwise. A mixture of pins across leaves therefore pins the whole root input
([D-236][d-236]). Two consumers of one root input may agree at nominal and still
differ in tolerance. `SVector{3, T}` and `SVector{3, Float64}` both evaluate to
`SVector{3, Float64}`, so the root input *type* is unambiguous while the
entries disagree about partials. That mixture is a legitimate model rather
than a mistake. A command consumed by a promoting aerodynamics leaf and by an
AD-opaque table is the FFI door in use.

**Why.** The direction of the meet is forced by embedding. A pinned root-input
cell feeds a `T` entry lawfully, because frozen values embed upward as
zero-partial constants ([§9.5][s9-5]). A `Dual`-carrying cell arriving at a
`Float64` entry is precisely what that entry forbids. The meet is therefore
the only assignment satisfying every consumer at once. It mirrors the
walk-compatibility clause ([§6.1][s6-1]) on the producer side.

What the mixture costs is stated where it is paid. Such a root input is
unseedable, and a tap selecting it is rejected naming the *pinning consumer*
rather than the face alone ([§14.10][s14-10]).

#### `output_types(::C, ::Type{T})` on the continuous tier, `output_types(::C)` on the discrete

`output_types` declares the public [port](#g-port) [contract](#g-contract), and declares it **by
type**. It is the same species as `input_types`, carrying the [activation](#g-activation)
scalar in its signature on the same terms. Where the input side is read
permissively, though, this one is read **literally**. An entry states what the
[cell](#g-cell) *carries*, not what it tolerates.

On **continuous producers the two-argument form is mandated**, spelled
`output_types(::Engine, ::Type{T}) where {T <: Real} = (M_shaft = T, P = T, ω = T)`.
On **discrete producers the plain form is mandated**, and it *is* the
wholesale pinning of the discrete exemption ([§7.2][s7-2]), spelled in the signature
as well as enforced by [tier](#g-tier). Class is read off declaration shape ([§8.5][s8-5]),
the class fixes the form the declaration must take, and
`TierSignatureMismatch` names a producer whose form and tier disagree in
either direction.

Semantics are **literal**. The cell types at an activation are the declaration
*evaluated* at that activation's `T`, with nothing [walked](#g-walked) and nothing
inferred. Participation is therefore authored **per leaf** and legible on the
page:
- **`T`, alone or as a type parameter** (`SVector{3, T}`, `RQuat{T}`,
  `MyStruct{T}`) means the leaf **participates**. Its cell carries the
  activation scalar. Value parameters are structure rather than number and
  never take it (`Ranged{T, -1, 1}`; the bounds are not scalars to re-type).
- **`Float64`** means the leaf is **deliberately [pinned](#g-walked)**, and the pin is
  schema-visible. It is whole-leaf freezing, declared and
  conformance-checked. That is the recorded freeze door ([§14.10][s14-10]) delivered.
  Declare `Float64` and strip with `ForwardDiff.value` inside the stage, so
  the stop-gradient is stated in the contract instead of buried
  mid-expression.
- **`Int`/`Bool`/enum leaves and reference-typed fields** pin as they always
  did. A [§4.4][s4-4] bulk-data handle's grid is frozen build-time data, never
  activation-dependent.

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
**embedding guarantee** ([§9.5][s9-5]), keyed on **declared-`T` leaves** ([D-033][d-033]).

**Why.** A `Float64` observed at a declared-`T` leaf under a non-nominal
activation implies no `Dual` entered its computation, because promotion is
airtight and there is no lossy cast. Its true derivative along every seeded
direction is therefore zero, and embedding it as a zero-partial constant is
exact.

Piecewise branches returning literal constants (`flow > 0 ? f(x) : 0.0`) are
legal as written, because zero partials are the derivative of a
locally-constant branch. Which *invocation* carries partials is still chosen
by seeding ([§14.10][s14-10]), never by typing. The declaration says which leaves
*can* carry them, and the seed says which directions do.

**The forgotten-`T` account, stated openly.** The whole-signature variant, a
continuous producer declared as though it were discrete, is unwritable by
construction. The tier mandate catches it in [Stratum](#g-stratum) A, before any user
code runs. What remains is per-leaf. An author writes `Float64` at a leaf that
really participates.

That bug **lurks, but is never silent**. No lossy `Dual → Float64` cast exists,
so the first `Dual` activation of that [component](#g-component) fails. It fails at that
activation's own lazy Stratum-C compile ([§9.4][s9-4]), not at `build(world)`. The
message carries the didactic hint ("if `F` participates in differentiation,
declare it `T`"), because an observed `Dual` at a declared-pinned leaf has
exactly one honest cause.

The lurk is contained by policy rather than machinery. **The test suite builds
a `Dual` activation of every component**, which is the exhaustive set [§9.4][s9-4]
defines. An activation is a Stratum-C re-run, cheap enough to make this
unremarkable in CI. What the form buys in exchange is **reader honesty**.
Participation is read off the declaration instead of reconstructed from a
framework rule carried in the reader's head, and a genuinely frozen leaf can
say so.

**The stores are walked, and only the output side is evaluated.** The type
derived from `init_x` is walked. Real leaves and `Real` type parameters follow
the activation scalar. `init_m` and `init_s` pin wholesale, mirroring the
discrete-producer rule. The asymmetry is the register criterion stated above
under the by-value declarations, not an inconsistency. `init_*` declare *by
value*, and [§7.1][s7-1] admits no pinned state leaf for a `T` to record a choice
about. Declared `Float64` initial values embed as zero-partial constants under
non-nominal activations. That is the rule for `Float64` condition leaves
([§14.3][s14-3]) applied to the defaults those conditions overlay.

Walking `init_x` presupposes the closed leaf vocabulary [§7.1][s7-1] fixes, scalars
and `SArray`s at the common eltype. On the discrete tier, the stores answer to
the isbits rule of [§7.3][s7-3], checked field by field. Stratum A checks both
vocabularies ([§9.1][s9-1]) and reports a failure in the didactic register:
- "`init_x` field `gear_count::Int` is not a continuous state — integers,
  `Bool`s and enums belong in `init_m`";
- "`init_x` field `q_nb::RQuat` is not a state leaf — declare the `SVector{4}`
  backing and cast where rotation semantics are wanted ([§7.1][s7-1])";
- "`init_x` field `pose::NamedTuple` is not a state leaf — a field is one
  scalar or `SArray`; split it into fields, structure comes from the component
  tree ([§7.1][s7-1])";
- "`init_s` field `label::String` is not a store value — store fields are
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
functions (`output_state`) structurally receive no inputs, so the build
[probes](#g-probe) them first, observes their contract ports, assigns the remainder to
stage 2, builds the graph, and probes the stage-2 chain in topological order
with real upstream values. The "decoder takes no inputs" property is exactly
what makes the derivation well-founded. A leaf's declarations do carry its
[tier](#g-tier) ([D-195][d-195], [D-220][d-220]), and that is a different fact. The tag this
subsection refuses is the *stage* tag on a port, which stays invisible either
way.

#### Custom structs as port types

A custom struct is a first-class port type, as in `contact = GearContact{T}`,
under the scoping [§7.2][s7-2] establishes. That scoping requires a struct
parametric in its real-scalar leaves, with constructors inferring the scalar
and no [pinned](#g-walked) fields on the continuous path. A participating struct leaf
is declared with the scalar in its parameter position, `GearContact{T}`,
recursively for nested parameters. A struct with a hardcoded `Float64` field offers no such position,
so it can only be declared bare, a pinned leaf, honestly spelled. Any
`Dual`-carrying construction then detonates inside the stage with an
`InexactError` naming the offending constructor. That is the [§7.2][s7-2] CI
invariant reached through the declaration layer with no extra machinery.

#### Completeness of the declaration set

Four rules the build checks in [Stratum](#g-stratum) A ([§9.1][s9-1]), stated here because
they are properties of the declarations, not of the wiring.

**A store needs its update.** `init_x` with no `state_derivative` method, or
`init_s` with no `state_update` method, is a build error. The first is
continuous state with no [flow](#g-flow), the second a discrete store nothing updates.
The framework will not silently supply `ẋ = 0`, which is a model, not a
default. An unupdated discrete store is a parameter in disguise, and
parameters are plain struct fields. The didactic register says exactly that.
`init_m` carries no such obligation. Modes are written by handlers, and a
[component](#g-component) may legitimately declare modes no event of its own transitions.

**An event needs both halves.** A `state_events` entry whose [guard](#g-guard) or handler
has no method for the component type is a build error, caught by method
lookup at declaration-reading time rather than as a `MethodError` at the first
firing. An event that fires only in a corner of the envelope would otherwise
hide the omission indefinitely.

**[Tier](#g-tier) is declared by the store and the update law.** For a **stateful**
leaf, `init_x` and `state_derivative` mark continuous, and `init_s` and
`state_update` mark discrete. Those two pairs are disjoint, so such a leaf
announces its tier in the store and in the update law alike ([D-195][d-195]). The
two output stages are one pair of names shared by both tiers, so they announce
nothing and cast no vote ([D-220][d-220]). The remaining tier-implying declarations
must agree. `init_m`, `state_events` and `state_projection` are
continuous-only, because the event system is continuous-side only ([§5.2][s5-2],
[§3.2][s3-2], [§14.1][s14-1]) and projection's one manifold is the continuous state's
([§2.2][s2-2]). `init_workspace`'s arity splits the tiers (`(::C, ::Type{T})` versus
`(::C)`), and so do the arities of `output_types` and `input_types`
([D-166][d-166]–[D-167][d-167]). Disagreement is `DeclarationOnWrongTier` ([Appendix C][sC]),
reported as the offending declaration with the tier the leaf's other
declarations announce. It covers declaring both `state_derivative` and
`state_update`, a `state_update` beside a two-argument `output_types`, and the
mixed-store cases the split state letters restore, namely an `init_x` on a
leaf whose update law is `state_update` and an `init_s` on one whose update
law is `state_derivative`.

A **stateless** leaf declares no store and no update law, so its tier is
decided by its [contract](#g-contract) arities. `output_types` is mandatory and hence always
the decider, with `input_types` agreeing where declared. The arity is no mere
marker. It *is* the tier's semantics ([D-166][d-166]–[D-167][d-167]). The two-argument forms
declare [cells](#g-cell) and tolerances at the [activation](#g-activation) scalar, walking with it,
where the plain forms declare the [pinned](#g-walked) discrete world. Its stage bundles
follow that decision like any other leaf's. `output_direct` reads the
continuous tier's bundle under the two-argument forms and the discrete tier's
under the plain ones. [§13.7][s13-7] records why one stateless continuous leaf
already serves consumers on both tiers. Members of both families, or of
neither, are the [§8.5][s8-5] class errors.

**Any component may be the root of a build, and the model's [root inputs](#g-root-input) are
the root's own input [faces](#g-face)** ([D-208][d-208]). For an [assembly](#g-assembly) those are the
faces declared through `input_connections`, each traced through the face
chain ([§6.1][s6-1], [§11.3][s11-3]) to the leaf entries consuming it. For a primitive they
are its `input_types` keys directly, because a leaf's faces are its own [port](#g-port)
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

- a field declared in `output_types` is public;
- a field returned in `y` (a stage's own published signals) and declared
  nowhere is a build error;
- a component with no `output_types()` method has no outputs.

That is the same move as class-by-declaration-shape. [Ports](#g-port) in the
[contract](#g-contract) are connectable, GUI-listed, [snapshot](#g-snapshot)-carried and log-exported.
The table is public throughout, with every [cell](#g-cell) a declared port or an
auto-published one, so nothing anywhere needs a presentation filter.
Visibility is binary, with no third register between the two. A value a later
function reads travels as a declared port like any other ([§5.2][s5-2]).

The inspection path for an intermediate is therefore **declaration**. One line
in `output_types` makes it public, checked and visible everywhere at once
([D-194][d-194]). FlightCore is the precedent, where an intermediate was inspected by
putting it in the `Model` output and no other way. Publicity is never
implicit. Even the minimal [component](#g-component) writes
`output_types(::LowPassFilter, ::Type{T}) where {T <: Real} = (x = T,)`, one
line, in exchange for "public" always meaning someone wrote it down.

- **Conformance.** A declared port must be produced, by exactly one stage or
  by **auto-publication**. Auto-publication covers declared names matching
  state or mode fields that no stage produces ([§5.3][s5-3]). Stage membership is
  derived over `output_types` alone ([§9.1][s9-1]). Declared-but-unproduced and
  produced-by-two-stages are build errors. A declared port matching neither a
  stage product nor a state field errors with both lists in hand: "not
  produced by any stage and not a state field". A *returned port field*
  declared nowhere is a build error at [probe](#g-probe), with [did-you-mean](#g-did-you-mean) (the
  offending name plus the list-in-hand it should have matched) against
  `output_types`. That is the return-side analogue of [§8.4][s8-4] walkthrough 1
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
   should have matched) against `output_types`. That one error is the whole
   report. The probe chain stops at the port check ([§13.1][s13-1], [D-239][d-239]), and
   an unproduced-`P_shaft` error would only restate it from the other side,
   since renaming the field produces the port. A declared port no stage
   returns, on a component whose returns are all declared, is the
   completeness pass's error, with the stage-product and state-field lists in
   hand ([§8.3][s8-3]). Every returned field is a declared port, so this one
   register is the whole case. An intermediate a later function reads is
   declared like any other output and typo'd like any other output ([§8.3][s8-3]).
### 8.5 Assembly declaration: type-based, class by declaration shape

**Rule.** An [assembly](#g-assembly) is a plain struct. Fields whose type is
`<: AbstractComponent` are its children, and all other fields are inert
parameters.

Field names are path segments. Substitutability and variants use ordinary
parametric fields, exactly today's `Cessna172X{K, A}` shape. Alongside the
struct come the well-known declarations: `child_connections(::A)`, mandatory
even when empty, plus `input_connections(::A)`, `output_connections(::A)` and
`sample_times(::A)`. One more is optional, `transparent_container(::A)`,
default `nothing`. Naming a container field there drops that field's segment
from its children's names, the rule the next subsection states.

#### Container children

**Rule.** A field whose type is a `Tuple` or `NamedTuple` with *every* element
`<: AbstractComponent` contributes its elements as [container children](#g-container-children).

They are path-named `"field/1"…"field/N"` (tuples) or `"field/key"`
(NamedTuples), and declaration order governs layout. Containers are
**transparent grouping, not assemblies**. They have no [contract](#g-contract), no
`child_connections`, no [rate scope](#g-rate-scope) and no existence beyond the path
segment. The elements are children *of the parent*, whose `child_connections`/
`input_connections`/`output_connections`/`sample_times` address them by element
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
keeps its transparency of contract, with no `child_connections`, no faces and
no rate scope.

The edges of the container form are fixed by rule:

- A container mixing [component](#g-component) and non-component elements is a build
  error in this section's [did-you-mean](#g-did-you-mean) family (the offending name plus the
  list-in-hand it should have matched). All-component elements are children,
  and zero-component elements are inert parameter data.
- Containers of containers are rejected in the first cut, because deeper
  grouping is what assemblies are for.
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
child_connections(g::Group)    = g.wires
input_connections(g::Group)    = g.inputs
output_connections(g::Group)   = g.outputs
transparent_container(::Group) = :children

Group(children; wires = (), inputs = (), outputs = ()) =
    Group(children, wires, inputs, outputs)

world = Group(
    (; plant = Plant(), ctrl = PID(kp = 2.0));
    wires = ("ctrl/u" => "plant/u", "plant/y" => "ctrl/y"),
)
```

One type, defined once, and every ad-hoc topology is a *value* of it. The type
parameters still carry the children's concrete types, so [Stratum](#g-stratum) C
specialization is unchanged (the strata are the build's three phases:
structure, schedule, activation). So is the [executor](#g-executor), the compiled
execution form of the schedule ([§9.7][s9-7]). Wiring validation, did-you-mean
errors and the two-producer check all run at build against the instance
exactly as for a named assembly.

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
*which* well-known declarations a type defines. `child_connections` is the
marker, mandatory even when empty (the `LowPassFilter` precedent), and
defining it makes an **assembly**. Any leaf declaration makes a **primitive**:
`init_x`/`init_s`/`init_m`, `init_workspace`, `input_types`/`output_types`,
`state_events`, or any stage, `state_derivative`, `state_update` or
`state_projection` method.

The rule is total. A `<: AbstractComponent` type declaring neither family has
no class to read. It is a build error naming both families rather than a
silence that fails later and elsewhere. That error sharpens into a
did-you-mean when the type has component-typed fields ("holds components but
declares no `child_connections`"). `child_connections` plus any leaf
declaration on one type is a build error as well. Assemblies have no state of
their own, which is the no-atomic-assemblies rule at declaration time
([§10.5][s10-5]). They have no contract of their own either. An assembly's faces
are derived from its children ([§8.6][s8-6]).

Reading which declarations exist is reading declarations. It is the same move
as visibility-by-declaration-site ([§8.3][s8-3]), not the banned
inference-by-evaluation ([§8.1][s8-1]).

#### Contract signature shape follows the class

Class also **mandates the shape of the contract signatures** rather than merely
being read from them ([D-166][d-166], [D-167][d-167]). **Both** contract declarations follow
the [tier](#g-tier). On a continuous leaf, `input_types` and `output_types` must take
the two-argument form `input_types(::C, ::Type{T}) where {T <: Real}` and
`output_types(::C, ::Type{T}) where {T <: Real}`. On a discrete leaf, both
must take the plain one-argument form.

Any of three violations is `TierSignatureMismatch` ([Appendix C][sC]): a
continuous declaration missing the `T`-form, a discrete declaration carrying
one, or a `T`-form bounded narrower than `Real`. The diagnostic reports the
component path, the declaration at fault, the tier its other declarations
announce, and the form found versus the form mandated. The check is Stratum A
and collected. Declaration shape is read, and nothing is evaluated.

The tier fact is therefore spelled in the signature *and* fixed by the class,
and the two are kept in agreement by a check rather than by convention. That
is what makes the whole-signature forgotten-`T` bug (the worst case, [D-079][d-079])
unwritable.
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
[snapshot](#g-snapshot) or the log tree). That read side is the inspection [register](#g-register) and
`resolve` as a provenance primitive ([§13.3][s13-3]). One fact from that
adjudication is load-bearing downstream. Symmetric immutable siblings are
`===`-identical, so a path is unrecoverable from an instance. That is why the
helpers ([§8.8][s8-8]) name the child by path.

**`child_connections(::A)`** is an ordered collection of `"src/face" => "dst/face"`
pairs, strictly from a child face to a child face. The rules ([§6.1][s6-1]) apply:
one wire per input, and every endpoint an immediate child and one of its
[faces](#g-face), container key segments included. The assembly's **boundary** is
declared by two further methods, one per direction. **`input_connections(::A)`**
is an ordered collection of pairs, face name => internal endpoint path, or a
tuple of paths for an input face routed to several immediate children
(fan-out through the boundary), as in
`"trn" => ("left/trn_field", "right/trn_field", …)`. Every entry routes to
**at least one** internal endpoint. An empty tuple is a declaration error,
because a face feeding nothing declares nothing ([D-210][d-210]).
**`output_connections(::A)`** runs the other way, internal source path => face
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
the union of its `input_types` and `output_types` keys, and a key declared in
both is the same build error a duplicate face name is. The root is where those
two declarations first share an address space. A [root input](#g-root-input) places a [cell](#g-cell)
the [periphery](#g-periphery) writes ([§11.3][s11-3]), so a collision would put two cells at one
name. Below the root nothing collides, because a primitive's input faces alias
their producers' cells and place nothing. Non-root leaves are left alone.

The two-notation rule this rests on is directional. It separates structure
from derived contract, not read from write. **Slash is structure**: endpoint
paths walking real children and ports, and the inspection [register](#g-register)'s
[snapshot](#g-snapshot) and log addressing. **Face names are opaque derived-contract
tokens.** The [periphery](#g-periphery)'s write side (input devices, mappings, the trace,
the GUI write path) speaks face names exclusively ([§11.3][s11-3]). The read side
speaks them wherever it wants meaning that outlives the build, in integration
bindings (`get_face`, [§11.2][s11-2]) and load-bearing service reads ([§14.4][s14-4]). The
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
leaf names `input_types`/`output_types`, leaf-style *typed* faces with face
wires inside `child_connections`, and routing-as-wires with derived types and
no face list. Publicity is never implicit ([§8.3][s8-3]).

**[Root inputs](#g-root-input) fall out with no vocabulary.** At every non-root level an input
face declared through `input_connections` is fed by the parent's wire. At the
root there is no parent, and the root component's input faces *are* the
[write surface](#g-write-surface), the set of faces a writer's batch entries may reach ([§11.3][s11-3]).
Which declaration supplies them follows the root's [class](#g-class),
`input_connections` keys for an assembly and `input_types` keys for a
primitive ([§8.2][s8-2]), and nothing downstream distinguishes the two. The
whole-tree obligation model ([§6.1][s6-1]) states the complementary error rule. An
assembly never declares its external connections. Those live in the parent
that instantiates it, exactly as a leaf's do.

**A [worked](#g-worked) assembly.** The IMU ([§15.5][s15-5]), spelled in full. It is a
mixed-tier assembly exercising paths, faces and sample times together:

```julia
struct IMU <: AbstractComponent
    integrals::IMUIntegrals    # continuous — cumulative Θ, q, Υ, V
    sampler::IMUSampler        # discrete — integrate-and-difference latches
    errors::IMUErrorModel      # discrete — scale/bias/noise on the sample
end

child_connections(::IMU) = (
    "integrals/Θ" => "sampler/Θ", "integrals/q" => "sampler/q",
    "integrals/Υ" => "sampler/Υ", "integrals/V" => "sampler/V",
    "sampler/sample" => "errors/sample",
)

input_connections(imu::IMU) = (
    input_passthrough(imu, "integrals")...,       # kinematic-truth inputs pass through
)

output_connections(::IMU) = (
    "sampler/sample"     => "sample",             # ideal increments
    "errors/sample_meas" => "sample_meas",        # measured increments (the error
                                                  # model's output port)
)

sample_times(::IMU) = (sampler = Relative(1), errors = Relative(1))
```

Two spellings are worth reading closely. `input_passthrough` enumerates the
child's **input** faces and nothing else ([§8.8][s8-8]), which is why the
pass-through of the integrals' kinematic-truth inputs (`q_eb`, `r_eb_e`,
`ω_eb_b`, `a_ib_b`, `α_ib_b`, [§15.5][s15-5]) is a bare splat with nothing to say
about direction. And the measured-increment face sources `errors/sample_meas`,
the error model's *output* port, not the `errors/sample` input the sampler
already feeds. Listing `errors/sample` in `output_connections` would fail the
direction cross-check, and listing it in `input_connections` while it is wired
is the two-producers error of [§8.8][s8-8].

Three facts the example carries. The assembly is tier-neutral. Every face's
type and tier derive from its internal endpoint, and a `sample_times` key on
`integrals`, the continuous child, would be a [§8.7][s8-7] build error. The two
discrete children default to `Relative(1)` anyway, so this `sample_times`
declaration is declaratory, and their absolute rate arrives from the enclosing
scope at deployment ([§8.7][s8-7]). And the latch-back wire ([§15.5][s15-5]), where the
integrals consume the sampler's published latch, joins `child_connections` as
one more ordinary pair.
### 8.7 Rate scopes

The declaration is `sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))`,
mapping each child name to a `Relative` or `Absolute` entry. These are the two
registers of [§10.5][s10-5]. Relative entries compose affinely down the tree,
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
`Simulation` construction (the three sources for `Δt_base`, [§9.1][s9-1]). The
declaration belongs to the [assembly](#g-assembly) type, not to the child instance,
because a sample time is a design ratio or a modeled instrument's intrinsic
rate ([§10.5][s10-5]), never a per-instance value. The FlightCore-`Subsampled`-style
instance wrapper is rejected in [D-042][d-042].

### 8.8 Computed connections and generic holding

`input_connections` and `output_connections` are ordinary functions evaluated
at build against the concrete instance, so they may *compute* entries from
child [contracts](#g-contract). That is derivation from declarations, which [§8.2][s8-2]
blesses. The framework helper, sketched:

```julia
# the two shapes of `declaration_error` used below:
declaration_error(path::AbstractString, why::Symbol)      # e.g. :both_given
declaration_error(path::AbstractString, unknown, legal)   # did-you-mean against the legal set

function input_passthrough(asm, child_path::AbstractString;
                     sep::AbstractString = ".",
                     prefix::AbstractString =               # "" → no prefixing
                         replace(child_path, "/" => sep),
                     except::Tuple = (), only::Tuple = ())  # mutually exclusive

    child = resolve(asm, child_path)      # getfield walk along "/" segments
    names = input_faces(child)            # the leaf's input_types keys,
                                          # entries of input_connections(c) for an assembly
    isempty(except) || isempty(only) ||
        declaration_error(child_path, :both_given)  # exclusivity enforced, not documented
    unknown = setdiff((except..., only...), names)
    isempty(unknown) || declaration_error(child_path, unknown, names)  # list in hand
    wanted = isempty(only) ? setdiff(names, except) : only
    label(n) = isempty(prefix) ? n : string(prefix, sep, n)
    return Tuple(label(n) => string(child_path, "/", n) for n in wanted)
end

input_connections(w::World) = (
    input_passthrough(w, "aircraft"; except = ("atm", "trn"))...,   # "aircraft.pilot.throttle_axis"
    input_passthrough(w, "atmosphere"; prefix = "env", sep = "_")..., # "env_wind_N"
)

output_connections(w::World) = (
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
face both wired and passed through is a two-producers error. `except`/`only`
naming a nonexistent face errors with the child's face list in hand. A
`prefix = ""` collision is caught by the build's uniqueness check like any
hand-written duplicate. The effective face list is plain printable data, the
inspectable derived contract of this instantiation. What computation does
*not* do is auto-bubble. The author wrote down "every input face of this child
that I don't feed, I expose under this prefix", explicit at the type level and
evaluated at build.

**The name carries the direction, so the helpers come in pairs.**
`input_passthrough` reads `input_faces(child)`, and `except`/`only` filter
*face names* within that set. The helper exists for the pass-through case,
where an assembly hands a child's unfed requirements up one level.
**`output_passthrough` is its sibling** ([D-209][d-209]). It is splatted into
`output_connections`, reads `output_faces(child)`, and has the same
`prefix`/`sep`/`except`/`only` surface and the same declaration-time error
set.

```julia
output_connections(sys::Systems) = (
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
`child_connections`. That is "structure kept in two artifacts" ([§8.1][s8-1];
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

child_connections(::Systems) = (
    (("act/" * src) => dst for (src, dst) in ACT_FEEDS)...,
    "aero/wrench" => "wr_sum/in1",               # non-feed wires unchanged
    …
)

input_connections(sys::Systems) = (
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

**The line not to cross** is deriving `except` from `child_connections` itself,
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

## 9. The build pipeline

The build consumes a root [component](#g-component) instance and produces the runnable
artifact: resolved wires, typed [signal table](#g-signal-table), evaluation [schedule](#g-schedule),
absolute rate divisors, flat state layout, [root inputs](#g-root-input). [§8][s8] states what is
declared and what must hold. This chapter states *when* each fact is checked,
against what, and with which failure. The [§8.4][s8-4] walkthroughs plus the error
rules ([§6.1][s6-1]) are its acceptance tests. Error-*reporting* policy is settled in
[§13.1][s13-1]. Declarative checking passes collect, user-code evaluation fails fast,
and strata are barriers, so the only partial results carried past failures
are violation lists from pure checks.

### 9.1 Three strata

Three ordering constraints are forced by settled decisions. [Face](#g-face) derivation
is **bottom-up**, because an [assembly](#g-assembly)'s interface connections evaluate
against child [contracts](#g-contract) ([§8.8][s8-8]). The unconnected-input obligation check
and cross-level two-producers detection are **global**, decidable only at the
root, after every assembly's wires and faces are in hand ([§6.1][s6-1]). And stage
membership is **derived by probing** the stage-1 functions ([§8.2][s8-2]), so
evaluation interleaves with graph construction at exactly one [blessed](#g-blessed) spot.
The pipeline is therefore inherently heterogeneous, and it is organized as
three [strata](#g-stratum).

#### Stratum A: structure

Stratum A is pure declaration reading. No user stage code executes in it. The
`input_connections`/`output_connections`/`input_passthrough` bodies are
declaration code ([§8.8][s8-8]).

The stratum is a tree walk from the root instance, in this order:

1. [Components](#g-component) are collected by path.
2. Each component's [class](#g-class) (its primitive-vs-assembly status) is read off
   declaration shape ([§8.5][s8-5]).
3. Leaf contracts are collected: `input_types`, `output_types`, `init_*`
   values, `state_events`.
4. Face derivation runs bottom-up, recording at every level the input and
   output [faces](#g-face) it declares and the chain each one routes through.
5. Global wiring resolution then runs, resolving wires to absolute leaf
   terminals.

Resolution runs these checks:

- one-writer-per-input;
- the typo [did-you-mean](#g-did-you-mean) (the offending name plus the list-in-hand it
  should have matched) against the destination's input list;
- the two wiring type clauses ([§6.1][s6-1], [§8.2][s8-2]), stated below;
- the whole-tree obligation check;
- the closed leaf vocabulary ([§7.1][s7-1]), checked on every `init_x` because
  the walk in [§8.2][s8-2] rests on it. `init_s` pins wholesale and answers to the
  isbits rule of [§7.3][s7-3] instead, checked with `init_m` field by field.

[Root inputs](#g-root-input) fall out here too, as the root component's input faces
([§8.2][s8-2]).

**The bound check** is the first type clause, and it applies at nominal faces.
The producer's declaration at `Float64` must be `<:` the entry at `Float64`.
Equality is the concrete degenerate case. Abstract-at-root is detected here.

**The walk-compatibility clause** is the second, and it applies to continuous
consumers only. It is decided by evaluating both declarations at a marker
scalar and comparing per leaf, and its diagnostic is
`WalkingFaceAtFrozenEntry`. It stays inside this stratum's charter because
both sides are declaration functions of `T`. Declarations are evaluated, and
no user stage code runs.

Stratum A also checks the declaration-completeness rules ([§8.2][s8-2]): a store
without its update, an event missing a [guard](#g-guard) or handler method, a leaf
mixing [tier](#g-tier) families, and a contract signature whose form contradicts the
leaf's tier ([§8.5][s8-5]).

`sample_times` validation is Stratum A's too, and it has two parts. The first
is per-entry validity against the constraints of [§10.5][s10-5]: wrapper-typed
values, `K ≥ 1`, `0 ≤ Φ < K`, `T > 0`, `0 ≤ τ < T`, and keys naming discrete or
scope children. Those violations are collected with path attribution. The
second is compilation into **`(anchor, m, c)` triples**. A triple carries a
discrete component's divisor and [phase](#g-phase) in the [tick](#g-tick) units of its
[anchor](#g-anchor), the exact `(T, τ)` pair an `Absolute` entry establishes.

The compilation is a fold down the tree, one rule per case:

| the fold meets | the triple it produces |
|---|---|
| the root scope | `(A₀, 1, 0)`, anchor 0 being the base grid itself: `(T, τ) = (Δt_base, 0)` |
| `Relative(K, φ)` under a scope at `(a, mₛ, cₛ)` | `(a, K·mₛ, cₛ + φ·mₛ)` |
| `Absolute(q, τ)` under any scope | **severs and re-seeds**: a fresh anchor `Aₖ = (period(q), τ)`, its subtree continuing at `(Aₖ, 1, 0)` |

Anchor 0 is symbolic until deployment. The `Relative` case is the affine law
([§10.5][s10-5]) in anchor-tick units. The canonical residue (`c < m`) holds
within each anchor's subtree by the same induction.

Everything except binding `Δt_base`, which is deployment's, happens in
Stratum A. Final divisors for anchored entries genuinely cannot exist until
`Δt_base` binds.

#### Stratum B: schedule

Stratum B is the single evaluation-feeds-structure step. It computes the
[schedule](#g-schedule):

- [Workspace](#g-workspace) (component-declared mutable scratch arriving as the `ws` bundle
  field) is allocated at the probing scalar. That is sound this early because
  the allocator reads only the instance and the scalar ([D-077][d-077]), so there
  is no layout dependence.
- Stage-1 [probes](#g-probe) run at `Float64`, on `init_x`/`init_s`/`init_m` values.
  They are well-founded, because the no-[feedthrough](#g-feedthrough) stage takes no
  inputs.
- [Ports](#g-port) are classified over `output_types` alone: stage-1, auto-published,
  and the stage-2 remainder ([§8.3][s8-3]).
- The feedthrough graph is built from the wires carrying stage-2 ports, and a
  topological order over it follows. [§5.5][s5-5] cycle rejection applies.

The output is structural. It is names only, `T`-independent,
branch-protected by the branch-shape rule plus the always-on check ([§9.5][s9-5]).

#### Stratum C: activation, parametric in `T`

An [activation](#g-activation) is a re-run of Stratum C at a given scalar type. The
stratum holds everything type-shaped:

- The producers' output declarations are **evaluated** at the activation's `T`
  to type the [cells](#g-cell). That is the literal semantics ([§8.2][s8-2]). A
  continuous producer's two-argument declaration is called at `T`, and a
  discrete producer's plain one is read once and [pinned](#g-walked).
- The `init_x`-derived state type is [walked](#g-walked) by the leaf-walk rule ([§8.2][s8-2]),
  and the `init_s`- and `init_m`-derived store types pin.
- The probe chain runs in topological order ([§9.3][s9-3]), and observed is
  compared against declared.
- The flat `x` [buffer](#g-buffer) and the table are laid out.

The nominal `Float64` activation runs at build. Other activations re-run *only
this stratum* ([§9.4][s9-4]).

#### Deployment binding

Deployment binding sits after all three strata, at `Simulation` construction.
It binds `Δt_base`, `h`, `N_base`, `t_end`, the algorithm, `localization_tol`,
`localization_budget` and `firing_budget`, runs harmonic-grid validation, and
instantiates the tick schedule. Nothing in A–C depends on it.

`Δt_base` has exactly one of three sources, cross-validated:

- the explicit keyword, a `Rational`, `Period` or `Hz` value, from which
  `N_base` is derived as `Δt_base/h` and validated an integer ≥ 1;
- the `N_base·h` product when only `N_base` is given, today's rule, with the
  default `N_base = 1`;
- **derivation**, requested explicitly as `Δt_base = :derive`. It is never
  entered by default, so the `N_base·h` path stays what silence means, and it
  is permitted only when every discrete component is anchored, that is, with
  anchor 0 unpopulated.

**Why.** Under that restriction `Δt_base` is pure bookkeeping that no
component's period depends on. An unanchored component's period is
`m·Δt_base`, and deriving with one present would let an anchor edit anywhere
in the tree silently rescale it, which is action at a distance.

**Rule.** If any unanchored component exists, deployment must declare
`Δt_base`. The refusal is constructive, carrying the suggestion message
([§9.2][s9-2]).

Admissibility is exact GCD arithmetic over the **constraint pool**:

| quantity | value |
|---|---|
| the constraint pool | every anchor's period and every nonzero anchor offset `τ` |
| an admissible `Δt_base` | one dividing every pool entry, equivalently one dividing `gcd(pool)` |
| the admissible set | `gcd(pool)/k`, for integer `k ≥ 1` |
| the derived `Δt_base` | `gcd(pool)` itself, the coarsest admissible value |
| per anchor `k` | `Dₖ = Tₖ/Δt_base`, `Φₖ = τₖ/Δt_base` |
| per component | `D = m·Dₖ`, `Φ = Φₖ + c·Dₖ`, `Δt = D·Δt_base` |

Resolution is therefore one division pair per anchor and one multiply-add per
component. `Dₖ` and `Φₖ` must both come out exact integers. Otherwise the
result is a `DeploymentInvalid`, naming the anchor with its declaring scope
and key from the provenance column. The per-component triples are the
[bound schedule](#g-bound-schedule), the printable artifact deployment binding produces
([§9.2][s9-2]).

Deployment validation is collected like its declarative siblings ([§13.1][s13-1]).
Violations are collected and reported as `DeploymentInvalid` ([Appendix C][sC]),
carrying parameter, value and the violated constraint:

- a nonpositive `h`;
- an `N_base < 1`;
- a harmonic-grid violation;
- a non-dividing anchor period or offset;
- a declared `Δt_base` disagreeing with a declared `N_base`;
- an algorithm the [stepper seam](#g-seam) does not know;
- a nonpositive `localization_tol`;
- a `localization_budget` or a `firing_budget` that is not an integer ≥ 1.

The event parameters validate on their own terms only. They are
grid-independent, so they take no part in the harmonic-grid check ([§10.4][s10-4],
[§10.6][s10-6]).
### 9.2 The `Build` artifact

`build(world) → Build` is a standalone entry point. `Simulation(world; …)`
(the spelling, [§15.4][s15-4]) is the convenience that calls it and adds
deployment binding, [buffers](#g-buffer) and the stopped-sim services.

The constructor is two entry points, not one. `Simulation(build::Build; …)`
accepts the artifact directly, and `Simulation(world; …)` is *defined as*
`Simulation(build(world); …)`. The artifact deployed is the very build that CI
checked, that an acceptance test targeted, and that a [face](#g-face)-provenance
table was printed from, never an assumed-equal reconstruction.

**Why.** Computed interface-connection bodies are ordinary user code
re-evaluated on every build, so equality between two builds of the same world
is an assumption the factorization removes.

Deployment binding still happens only at `Simulation` construction, whichever
entry point runs.

**The `Build` is immutable and may back any number of `Simulation`s,
concurrently.** That is true by construction once buffers are single-owner
([§9.4][s9-4]). Each `Simulation` materializes its own from the shared layouts, so
nothing writable is shared. The one mutable thing on the artifact is the
lazily populated [activation](#g-activation) cache, whose insertion [§9.4][s9-4] makes
torn-state-free. The `Build` is the inspectable derived contract of the
instantiation that [§8.8][s8-8] gestures at. It holds the wire list, face table,
[schedule](#g-schedule) and [root inputs](#g-root-input) as plain printable data. "Printable" names the
representation. Paths, names and rationals are inspectable as fields and
printed by any REPL without a method of their own, the diagnostic form set
against the compiled form ([§9.7][s9-7]). The renderings the artifact owes are the named
ones: the anchor and component tables and the hyperperiod chart below, and
the face-provenance printer ([§13.7][s13-7]).

**The face table is two-sided.** Beside each level's output faces and their
provenance it retains that level's *input* faces, each resolved producer-ward
to the one feed its consumers share, either a root input or a producer inside
the model. The record is total, because one-level routing gives every signal
a declared face at every boundary it crosses ([§6.1][s6-1], [D-207][d-207]). The input
side is what a [fragment](#g-fragment)'s `inputs` payload resolves against from any
authoring level ([§14.2][s14-2], [§14.3][s14-3]). CI checks a model by calling `build`, the
acceptance tests target `build` errors directly, and `attach!` validates
[device](#g-device) [bindings](#g-binding) against it. Build living only inside the `Simulation`
constructor was rejected ([D-049][d-049]).

**The schedule the `Build` carries is anchor-relative, and the `Simulation`
binds it.** From [Stratum](#g-stratum) A the artifact gains two printable tables. The
**[anchor](#g-anchor) table** holds each anchor's exact `(T, τ)` rationals with the
declaring scope's path and key. The **[component](#g-component) table** holds the
`(anchor, m, c)` triples with their declaration provenance, the
`Relative`/`Absolute` chain down the tree. The base grid `A₀` takes an
anchor-table row of its own, with a dash in the scope and key columns,
because no scope declares it. Its `(T, τ)` stays symbolic there until
`Δt_base` binds. For a fully relative model the only anchor is `A₀` and the
triples *are* the final base-[tick](#g-tick) `(D, Φ)` pairs. When anchors exist, final
divisors cannot live here. They do not exist until `Δt_base` binds, and the
same `Build` already backs many `Simulation`s with different deployment
parameters. Binding ([§9.1][s9-1]) produces the **[bound schedule](#g-bound-schedule)**, a named
printable artifact on the `Simulation`. It lists, per discrete component,
`(D, Φ, Δt)` with the anchor and provenance columns carried through. It is
the single source of truth for `Δt` ([§10.5][s10-5]), the substrate of the grid
diagnostics below, and the table that answers "when does what run, and what
coincides with what". [Rate scopes](#g-rate-scope) (an assembly's `sample_times` declaration
against the enclosing scope) appear in it beside the discrete components,
each with its own `(Dₛ, Φₛ)`. The bound schedule's `show`-form is the
**hyperperiod chart**. The pattern repeats with period `lcm(Dᵢ)` base ticks,
and the gate is pure modulo arithmetic, so one hyperperiod is the complete
truth, not a sample. The chart renders it as a tick chart over
`k = 0 … lcm(Dᵢ) − 1`, with a guard for absurd hyperperiods.

**Example.** The model worked in [§10.5][s10-5] has three discrete components
under two scopes. `sample_times` declares `fcs = Relative(1)` and
`gnss = Absolute(Hz(50))` at the root, and `inner = Relative(1)` and
`outer = Relative(5, 2)` under `fcs`. Deploy it at `Δt_base = 2 ms`. The
`Absolute` entry seeds the anchor `A₁ = (1//50, 0)` and the rest of the tree
stays on anchor 0, so the three components carry these values through binding:

| | `inner` | `outer` | `gnss` |
|---|---|---|---|
| declaration | `Relative(1)` under `fcs` | `Relative(5, 2)` under `fcs` | `Absolute(Hz(50))` at the root |
| anchor | `A₀` | `A₀` | `A₁` |
| triple `(m, c)` | `(1, 0)` | `(5, 2)` | `(1, 0)` |
| bound `(D, Φ)` | `(1, 0)` | `(5, 2)` | `(10, 0)` |
| bound `Δt` | 2 ms | 10 ms | 20 ms |

`gnss` is the entry whose divisor could not exist before `Δt_base` bound. Its
divisor is `D = m·D₁`, with `D₁ = T₁/Δt_base = (1//50)/(1//500) = 10`.

**Grid diagnostics print from the pool, exactly.** The refusal path's
suggestion message and the derivation path's info line share one substrate:
the coarsest admissible `Δt_base` with the admissible set `gcd(pool)/k`, and
per-entry attribution. Attribution has two forms.

**Leave-one-out refinement factors** are the first form.
`r_p = gcd(pool ∖ p)/gcd(pool)` is an integer ≥ 1 read as "how much coarser
the grid would be without this entry". Every `r_p > 1` is listed rather than
one culprit crowned, because joint responsibility is the honest answer.

**Prime attribution** is the second form. Each prime power of `1/Δt_base` is
traced to the pool entries whose denominators supply it. That pinpoints what
an edit changed.

When an offset is a driver, the message adds the nearest non-refining
alternatives, the admissible offsets on the grid the rest of the pool
supports. That turns the diagnostic into a repair.

Blame is computed against the actual pool. A simple-fraction-of-its-period
test stays authoring guidance and never becomes the engine's ([D-187][d-187]).

The derivation path is the one place refinement happens silently. It always
prints the derived value with its drivers, and it carries the one advisory,
`GridUtilization` ([Appendix C][sC]). The advisory reports `min_i Dᵢ`, the base
ticks between the fastest component's ticks, as "grid is N× finer than the
fastest declared work" with the drivers named. It is information rather than
scolding, since a scope deliberately declared finer than its fastest member to
buy stagger room ([§10.5][s10-5]) legitimately inflates the metric.
### 9.3 Probing and input synthesis

**[Probe](#g-probe)-everything scope.** The nominal [activation](#g-activation) probes every user
function once, at the initial state, with real values. The set is the stages,
`state_derivative`, `state_update`, [guards](#g-guard), handlers and
`state_projection`. The probe checks shape and type conformance and discards
the results. All are pure, and the cost is one evaluation each. "Fails loudly
at build time where possible" ([§8.1][s8-1]) decides this. A malformed
`state_derivative` return must not wait for the first integrator step. Probes
see only the initial state's branch, so the marginal coverage is earliness,
not completeness. The always-on check ([§9.5][s9-5]) remains the completeness
backstop.

**Probe argument sourcing.** `x`/`s`/`m` come from `init_*` declarations,
which declare by value. The stage-1 hand-down, `y_x` and `y_s` on the
discrete [tier](#g-tier), comes from the stage-1 probes' *returns*. An auto-published
name is a framework write, never a probe product, so it is absent from the
hand-down ([§5.2][s5-2]). Wired inputs come from upstream products. Real values
are available because the stage-2 chain is probed in topological order, so
every consumer is probed against the same value it will receive at run time.
Two checks ride the same pass. The first is the return's shape. A stage
returning something other than a `NamedTuple` fails here. The second is the
dead-stage rule. A stage returning bare `(;)` produces no [ports](#g-port) at all, and
is `DeadStage`, fail-fast. The [bundle law](#g-bundle)'s two remaining fields ([§5.2][s5-2])
are sourced as follows. `t` is probe-scoped `0.0`. Deployment binds no clock
and `t₀` post-dates even deployment ([§14.5][s14-5]), so like `Δt` below it is a
fabricated, probe-scoped value. `ws` comes from invoking the component's
`init_workspace` allocator at the probing scalar. That allocator reads only
the instance and the scalar ([D-077][d-077]) and derives nothing from layouts, so it
runs before the [Stratum](#g-stratum) B probes that need it. Exactly one kind of
terminal has no producer: **root inputs**. The build synthesizes their values
via `probe_value(::Type)`. Framework methods cover `Real` (`zero(T)`), `Bool`
(`false`) and enums (first instance), and the ultimate fallback is the
zero-argument constructor `T()`. That is where well-behaved constrained types
already put their valid default (`RQuat()` is the identity, and the `@kwdef`
convention supplies it broadly). `probe_value` is **overridable**. A type
whose valid default is not reachable that way declares its own method, which
is also the [seam](#g-seam) a [walked](#g-walked) type uses to state a constrained default. No
method is a build error, in the didactic register. It names the [face](#g-face) and the
type, and asks for one of the two fixes ("no `probe_value` for
`Ranged{Float64, -1, 1}` at face `pilot.elevator_axis` — define
`probe_value(::Type{Ranged{Float64, -1, 1}})` or a zero-argument
constructor"). Synthesis never meets an abstract type. Root inputs are
concrete by the tight-bound rule ([§8.2][s8-2]; the root-input type is the
consuming entry evaluated at `Float64`), and [abstract entries](#g-abstract-entry) only occur
on component-fed inputs, which the probe sources from upstream products.
Physically silly values are acceptable by construction. The probe checks
types, and return types that depend on input *values* are type
instabilities, banned by the branch-shape rule. The [§4.3][s4-3] write-side
granularity rule keeps root inputs predominantly scalar, so the surface is
small. Three alternatives were rejected ([D-051][d-051]): inputs declared by value
à la `init_x`, NaN poison values, and init-service values.

**Probe values are strictly probe-scoped.** Everything the probe writes is
garbage once the build finishes. Probe values never double as initial
root-input values, because that would smuggle in the default semantics
rejected above. The same doctrine covers the clock. `Δt` in seconds does not
exist until `Simulation` binds `Δt_base`, since deployment post-dates the
build, so discrete-[tier](#g-tier) probes supply a placeholder period (`1.0`) in the
bundle. It is a fabricated, probe-scoped value like any synthesized input.
The probe checks types, not physics. `Simulation` must not reach its
first [boundary](#g-boundary) with uninitialized root inputs. Enforcement is the pre-write
`UninitializedInputs` check carried by every complete-world application,
namely `init!`, trim setup and trim commit ([§14.6][s14-6]).

**The author's side of that bargain.** Silly values are acceptable *because*
the author is obliged to accept them. **Stage code must be total over
type-valid inputs.** Every probed user function (stages, `state_derivative`,
`state_update`, guards, handlers, `state_projection`) evaluates without
throwing on any input satisfying its declared types. The domain is
type-validity, not the probe's particular synthesized values. The
branch-shape rule already bans value-dependent return types, so types are the
only domain the framework can speak of, and the probe is the enforcement
moment, not the reason ([D-142][d-142]). There are two consequence sites, with the
same throw at both. At build it is a `UserCodeFraming`-wrapped build failure
([§13.1][s13-1]) whose diagnostic points at code that is "correct" on every
trajectory it has ever seen. At runtime it is a `StepError` and the run ends
`errored` ([§13.4][s13-4]). Exceptions from model code are always abnormal
([§13.5][s13-5]). Three habits of shipped code have sanctioned spellings. A
*plausibility* check meaning "stop the run", such as a strut throwing on a
touchdown overload, is a published `Bool` output face plus `stop_on`
([§13.5][s13-5]), machinery already there. A *self-consistency* assert, such as an
author checking that their own contact algebra cancels a velocity component
to a hard tolerance, is a regression test about that algebra, and its home is
the test suite. It is also the most probe-fragile of the three, since a
near-degenerate synthesized geometry can keep the cancellation algebraically
exact while missing an absolute tolerance in floating point. And there is the
*defensive exhaustiveness* branch, an `else error("unrecognized surface
type")` over a closed enum, or a coefficient constructor asserting an ordering
of its arguments when that constructor runs per step inside a stage. Such a
branch is not banned validation but **mislocated** validation. Totality over
a closed enum means handling every instance, and an `else error` is an
admission that the function is partial. Parameter validation belongs where
user-controlled data enters, in the constructors of parameter and instance
values, which run before the build, where asserts are perfectly legitimate.
It never belongs inside a stage, on probe-fed data.
### 9.4 Activations: executable sets, laziness, caching

An **[activation](#g-activation) at `T`** re-runs [Stratum](#g-stratum) C with a different scalar:

- producer-fed [cells](#g-cell) are re-typed by *evaluating* the producing [component](#g-component)'s
  output declaration at `T` ([§8.2][s8-2]). A continuous producer's two-argument
  declaration is called at the scalar, and a discrete producer's plain
  declaration pins;
- [root-input](#g-root-input) cells are re-typed by *evaluating* the consuming `input_types`
  entry at `T`, which [§8.2][s8-2] reads permissively. A `T` entry follows the
  activation, and a `Float64` entry stays frozen;
- the state type is re-derived by the walk over `init_x`'s, with table and
  state [buffers](#g-buffer) re-laid-out;
- [workspace](#g-workspace) allocators are re-invoked at `T`, not introduced. The first
  invocation precedes the Stratum B [probes](#g-probe) ([§9.1][s9-1]/[§9.3][s9-3]), and a
  [continuous component](#g-continuous-component)'s scratch carries the activation's scalar ([§7.3][s7-3]);
- the probe chain is re-run.

Structure and [schedule](#g-schedule) are `T`-independent by construction.

**Each activation probes exactly the function set it can execute.** A `Dual`
activation (linearization, gradient trim) evaluates the model at a frozen
instant. Discrete stages are gated off holding `Float64` values (the [§8.2][s8-2]
frozen-constant semantics), and [guards](#g-guard) and handlers never run, because
event localization is `Float64` [sweeps](#g-sweep) by design ([§10.4][s10-4]). Only the
continuous output stages (`output_state`/`output_direct`) and
`state_derivative` ever see a `Dual`, so only they are probed. Probing the
discrete stages, `state_update`, or guards at `Dual` would check code against
a number type it cannot receive. It is one rule with no special cases, and
the [§5.6][s5-6] tracer activation follows it identically. "Tracer activation"
names the *global* set-tracer ([D-012][d-012]), a whole-model run at the tracer
scalar, an activation like any other. The cycle classifier ([§5.6][s5-6]) is the
other variant ([D-012][d-012]). It is the schedule-free per-member local trace,
which runs in Stratum B's failure path and is not an activation at all.

**Lazy, with an opt-in exhaustive mode.** Non-nominal activations run at first
request, not at build. The dominant cost is compiling the continuous chain a
second time at `Dual`, pure waste for interactive fly-around use. The price is
stated openly. `build` succeeding does **not** certify the model
linearizable. A [pinned](#g-walked) `Float64` ([§7.2][s7-2]), whether hidden in a constructor
or written into an output declaration at a leaf that really participates (the
per-leaf forgotten-`T`, [§8.2][s8-2]), lurks until the first `Dual` activation
detonates it at the probe, naming the offending constructor or leaf. The
repository's test suite pins the invariant instead, as policy rather than
advice ([D-166][d-166]). **Every component gets a `Dual` activation built in CI.**
`build(world; activations = (Float64, ProbeDual))` (or a `check` entry) runs
the exhaustive set, catching both genericity violations and forgotten-`T`
leaves at PR time, at the cost of a Stratum-C re-run per component. The same
keyword is the recommended idiom for the parallel-sweep register ([§11.1][s11-1]).
Pre-materialize the activations the sweep will need, and the shared `Build`
is a fully immutable artifact, with no synchronization on any path.
[`ProbeDual`](#g-probedual) is the framework's public canonical probe scalar,
`const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}`. It exists because
an activation is keyed by a *concrete* scalar type, and the bare `Dual`
`UnionAll` cannot key one, be [walked](#g-walked) to, or answer `zero(T)`. Its width is
arbitrary. What CI pins is genericity, not any particular Jacobian, so one
canonical width suffices even though [§14.10][s14-10] chunks at whatever widths it
needs.

**Caching is implementation detail, not semantics.** An activation is a pure
function of the build and the concrete scalar type, so the cache is the
`Build`'s. It holds layouts, compiled plans and a validated flag keyed by
that type, immutable once constructed and hence freely shareable. **Buffers
are never cached**, because every buffer set has exactly one owner. The
`Simulation` owns its nominal activation's buffers, materialized from the
cached layouts at construction, which is what the loop's zero-allocation
stepping runs on. Every service invocation owns the scratch set it
instantiates from those same layouts. [§14.8][s14-8] states this for `trim!`, and
it is the general rule, not a trim-local one. Compiled code is cached by
Julia itself, process-wide. What the framework cache saves is the expensive
part, namely probe re-runs, layout construction, and Julia's compilation of
the `Dual` chain. That is what actually amortizes in activation-reusing
loops, such as the envelope-grid gain-schedule case, where hundreds of
trim-then-linearize points pay those costs once. What does not amortize is
the per-point allocation of a working store set, which is O(model size) and
trivial against the solve it feeds. The zero-allocation invariant ([§7.5][s7-5])
is scoped to the stepping loop, and the services were always
allocation-tolerant. Nothing numerical is ever cached. Note that
`Dual{Tag,V,N}` carries the partial count, so a different seeding width is a
different scalar type, hence a separate entry and a separate Julia compile.
**Lazy materialization is torn-state-free**, normatively. Concurrent first
requests for the same activation must never expose partially populated cache
state. The mechanism is unspecified, and a guard around insertion suffices,
paid at service time and never on the hot path. Since an activation is a
pure function of build and scalar, the worst benign race is duplicated work.
Torn state is excluded by contract, not by luck.
### 9.5 The always-on conformance check

The [probe](#g-probe) validates each function *once*, on the initial state's branch.
The schema-authority bargain's second clause ("at first execution otherwise",
[§8.1][s8-1]) is discharged by leaving the probe's comparison permanently in place.
At the point where the [executor](#g-executor) (the compiled execution form of the
schedule) stores a stage return into the table, it holds the complete
expected return type at this [activation](#g-activation). That type is the type of the
[cells](#g-cell) this stage writes, as the probe fixed them at this activation. It is one
concrete `NamedTuple` type per ([component](#g-component), stage), the stage's declared
names at the types their cells hold ([§8.2][s8-2]). The write is generated over
that type and the return's type, so the test is decided when the write's
method is specialized, and no per-field instruction reaches the conformant
path ([D-235][d-235]). Auto-published names belong to no stage's expected type,
because the framework writes those [cells](#g-cell) itself. When the write's method is
generated, the return's key set is compared with the expected type's, and
each returned field is held to its cell's type under the relation below. A
conformant return type generates the straight stores and nothing else. A
non-conformant one generates a throw of the failure payload, raised the first
time that branch executes. For type-stable conformant code, the compiler
proves the return type, one method is generated, and no check instruction
exists to delete. For branch-divergent code, each return type the stage can
produce gets its own method, the union split the code already pays, and the
check is absent from every conformant one. The divergent branch's method is
the loud located error at its first execution. Type-unstable-but-conformant
code pays the dynamic dispatch it already bought, and nothing on top.

**The names are the pairing, and field order carries no semantics.**
`Expected`'s order is an internal fact. It is derived from `output_types`,
stage-filtered, with auto-published names removed, an order no single
declaration shows the author. The author never reproduces it. A return
spelling the right names at the right types conforms in any order.
`(; P = M*ω, M_shaft = M)` and `(; M_shaft = M, P = M*ω)` are the same
return. This is the general rule at every `NamedTuple` [seam](#g-seam) between author
and framework ([§14.7][s14-7] states it for the trim problem's decisions and
residuals). It is also what downstream consumption already assumes. The
scatter writes each returned field into its own *named* cell ([§4.3][s4-3]).
Order-sensitivity in the check would therefore be incidental strictness
rather than protection. Pairing by name costs nothing. The generated write
reads each returned field by name and stores it into its cell, so no
permutation of the value exists at runtime. The per-field reasoning happens
on types at generation and emits no per-field instruction, which is how the
economics ([D-053][d-053]) hold. Its one baked type test is resolved by dispatch
rather than executed ([D-235][d-235]). The canary ([§7.5][s7-5]) verifies the fold
empirically rather than by assertion. What is an error is a key-set mismatch
or a per-field type mismatch, reported by the [payload](#g-payload) below. A permutation
is not an error at all, which is equally why that diff never has to express
one.

**Exact match at nominal, embed-accept at declared-`T` leaves.** At the
nominal activation, the only one that ever runs in real time, the check is an
exact type match, with no convert-on-write, decided at generation and absent
from the conformant path ([D-053][d-053], [D-235][d-235]). The error can afford to be
didactic: "field `M_shaft`: expected `Float64`, got `Int64` — return
`zero(x.ω)`, not `0`". Under a non-nominal activation (a re-run of Stratum C
at a given scalar type) the two leaf kinds the declaration ([§8.2][s8-2])
distinguishes are checked differently. A **declared-`T` leaf**, where the
author wrote `T`, accepts exactly two types, the activation scalar or
`Float64`. The activation scalar is the fast path, the straight store. A
`Float64` the executor **embeds** as a zero-partial constant (`convert`
through the leaf). Struct-valued [ports](#g-port) use the standard cross-eltype
constructor, and a missing one fails loudly with both types named. An opaque
leaf ([§4.3][s4-3], [D-237][d-237]) embeds nothing. It is accepted by identity alone.
Nothing else is accepted. The check is decided on the type, not leaf by leaf.
The arrival with its `Float64` positions lifted to the scalar wherever the
declaration has one must be the declaration itself, so a field name, a
non-numeric type parameter or an array's mutability that differs is refused
like any other mismatch ([D-238][d-238]). A **declared-[pinned](#g-walked) leaf**, where the
author wrote a concrete type, `Float64` at the head of the list, takes the
nominal-style exact check at *every* activation, because its declaration said
the leaf never carries partials. An observed `Dual` there is the per-leaf
forgotten-`T` error, that being the one honest cause. The didactic hint is
attached: "if `F` participates in differentiation, declare it `T`". The
embedding is exact, not lenient. Promotion is airtight and there is no lossy
`Dual → Float64` cast, so a `Float64` observed at a declared-`T` leaf means
no `Dual` entered its computation. Its true derivative along every seeded
direction is zero, which is precisely what the embedded constant says. This
scopes the blanket convert-on-write rejection to the nominal check ([D-053][d-053]).
The bug that rejection guards against, silently zeroed partials, cannot arise
from honest code, because accidental `Float64`s from `Dual` operands are
impossible (`MethodError` at the operation site). The residual is
**deliberate stripping** (`ForwardDiff.value`), a stated intent to discard
partials, producing a silent zero in the Jacobian. That is the stop-gradient
idiom, occasionally legitimate, as with deliberately frozen couplings and
opaque non-Julia wrappers. Applied mid-expression it is equally invisible to a
strict exact-match rule, so the leniency costs nothing. What it need not be
is invisible to the schema. **The declared-pinned leaf is the schema-visible
freeze.** An author who means to strip declares the leaf `Float64` and strips
inside the stage, and the check above holds the freeze to its word at every
activation. Stripping mid-expression at a leaf still declared `T` remains
legal and remains unseen, as the sharp tool it is.

**Uniform across all probed functions.** `state_derivative` checks against
`X`'s own shape at the activation's `T` ([§7.1][s7-1]: a scalar leaf expects a
`T`, an `SArray` leaf the same `SArray` at `T`). Its predicate is "every field
scatters into its field's block at `T`", which is what makes derivative
completeness structural rather than a matter of author discipline. [Guards](#g-guard)
check against their probe-derived [predicate](#g-predicate) form (below), `state_update`
against its leaf's `s` shape, and handlers against the [§5.2][s5-2] return law,
key by key. `state_projection` checks against `X`'s own shape at `T`,
**complete**, since its result is written back to the [buffer](#g-buffer) wholesale at
both of the [schedule](#g-schedule) positions ([§5.3][s5-3]) and a [projection](#g-projection) with a
mode-dependent branch first executes its second branch at run time. That is
the same predicate as a handler's `x` key.

**Handler returns, key by key.** The returned NamedTuple's key set is checked
first. An unknown key, or a key naming a store the component does not
declare, is a build error with [did-you-mean](#g-did-you-mean) against `{x, m}` narrowed to
the stores that exist. That is the [bundle law](#g-bundle)'s classification running in
the return direction. Then, per present key, `x` must be **complete** against
the state field set (and conformant at `T` like any state value), while `m`
may be **partial**, checked against a names-subset-with-matching-types
predicate, still a type-level computation that folds when inferred. An
absent key is not an error and not a no-op to diagnose. It is the handler
saying it does not touch that store. The completeness asymmetry is
storage-shaped. `x` must be complete because it lives in a flat buffer
written back wholesale, while `m` may be partial because `m` lives in
per-field stores where a partial merge is the natural write.

**Guards have two admissible forms** ([§2.1][s2-1]), so their check is form-aware
rather than a flat `isa Bool`. A `Bool`-form guard's probed return is `Bool`,
and a sign-form guard's is the nominal scalar. Guards run only at the nominal
activation ([D-052][d-052]), so no parametrized-leaf case arises here. Any other
probed return type is a build error naming both admissible forms. There is
nothing further to check. The probed form *is* the detection policy ([§10.4][s10-4],
[D-179][d-179]), so no form/policy mismatch can be declared.

**Failure payload.** The payload carries the component path, function,
field-level diff (missing / unexpected / per-field expected-vs-observed) and
simulation time. Deliberately absent is the source branch. Values carry no
provenance, and the diff identifies it. The always-on input [trace](#g-trace) makes
every such failure **reproducible by [replay](#g-replay)**. The error names the [boundary](#g-boundary)
to replay to (`to_boundary`, [§12.7][s12-7]). At run time the failure travels as a
[species](#g-species) of `StepError` through the single catch site ([§13.4][s13-4]), which adds
the loop-level nonfinite-state check as its divergence sibling.
### 9.6 Stopped-sim services as Stratum-C clients

This section is sketched here because it grounds the strata. The services
themselves are [§14][s14]. The C172 trim problem (`c172.jl`: `TrimState`,
`TrimParameters`, `θ_constraint`, the `ẋ`-reading cost) transfers
near-verbatim:

- **Trim** is a loop that writes a condition, runs a [sweep](#g-sweep) and reads the
  result, on an [activation](#g-activation). By default that is the `Dual` activation, with
  decision variables seeded for exact residual Jacobians ([§14.7][s14-7]). The derivative-free fallback runs the
  same loop on the nominal `Float64` activation (a re-run of Stratum C at a
  given scalar type) with no new activation needed, and the always-on checks
  ride along either way. Decision variables stay opaque to the framework, and
  only the assignment's *output* is framework vocabulary. `assign!` inverts
  from in-place mutation plus self-invoked `f_ode!` to a pure function
  returning a [condition](#g-condition) value (state by path, modes, [root inputs](#g-root-input) by [face](#g-face))
  that the service writes and evaluates. Domain math survives aircraft-side,
  namely the pitch constraint, `Kinematics.Initializer`, per-residual
  scalings and the equilibrium-subset choice, with one respelling. The
  initializer's `atmosphere::Model` argument becomes a [field handle](#g-field-handle)
  ([§4.4][s4-4]), built at value level by the atmosphere's
  [value-level constructor](#g-value-level-constructor) or held directly as a rig root-input value
  ([§14.1][s14-1], [§14.9][s14-9]).
- **Linearization** is a `Dual` activation plus seeded sweeps. Gather and
  scatter over the canonical layout replace the hand-written
  `get_x_ss`/`assign_x_ss!` layer (the deletion discharged, [§7.1][s7-1]). Root
  inputs are the input surface. Frozen discrete outputs are constants with
  zero partials, which is exactly "linearize with the discrete state held"
  ([§8.2][s8-2]). Gradient-based trim, with decision variables seeded through the
  `T`-generic assignment math, is the default ([§14.7][s14-7]).
- The generic service loop (vectorization, optimizer setup, bounds packing,
  solved-condition write-back including root inputs and the [trace header](#g-trace-header)'s
  root-input capture) replaces today's per-aircraft NLopt plumbing. A failed
  trim leaves the simulation's stores untouched, an improvement over today's
  warn-but-assign `f_init!`.

### 9.7 The compiled executor

The [schedule](#g-schedule) exists in two representations at two lifecycle stages. In the
`Build` it is plain printable data ([§9.2][s9-2]), paths, stage names and order,
which is the authoring and diagnostic form. At `Simulation` construction, and
per [activation](#g-activation) (a re-run of Stratum C at a given scalar type), that data
is compiled into the execution form: **a concretely-typed tuple of entries
over statically typed [cell](#g-cell) storage, traversed by a compile-time-unrolled
walk**. This is a forced move, not a preference. The zero-allocation
invariant ([§7.5][s7-5]), the fold-away conformance test ([§9.5][s9-5]) and the zero
runtime graph logic ([§5.1][s5-1]) are reachable only under full specialization
([D-086][d-086]). An entry carries what selects code in type parameters, namely
[component](#g-component) type and stage. It carries what is plain data in fields, namely
[tick](#g-tick) divisor and [phase](#g-phase), the [bundle](#g-bundle)'s `Δt`, and layout offsets. Gating
compiles to `(tick − Φ) % D == 0` inside the specialized *[boundary](#g-boundary)* body,
and the interior bodies hold no discrete entries to test ([§10.5][s10-5]).

**Cells are stored per element type, not per cell.** The [signal table](#g-signal-table) is one
contiguous block per element type, the construction pointed at signals
rather than state ([§7.1][s7-1]). A cell address is a build-time offset into it,
carried in an entry *field* with the [port](#g-port) type as the address's own
parameter. Gathers reconstruct and scatters flatten through the same leaf
walk, so the closed vocabulary earns its keep twice. This is the entry rule
above paying rent. Two instances of one component type then differ only in
field values, share an entry type, and compile to **one** body. A store
enumerating every cell in its own type, addressed by index in the type
domain, compiles one body per instance and grows the store type with the
model. The choice was measured rather than argued ([D-162][d-162],
`prototypes/cellstore_bench`).

**[Phase bodies](#g-measurement-seam) are the outer decomposition, and they are semantically
forced.** The [boundary sweep](#g-sweep)'s stage-1 block, both tiers' `output_state`
entries alike, is order-free by definition, because the no-[feedthrough](#g-feedthrough)
stage reads no `u`. The stage-2 block gates in the [due](#g-due) discrete stages,
those whose components this boundary admits by their compiled `(D, Φ)` pair.
It is the only topologically ordered one. The `state_derivative` block (the
[RHS](#g-flow) body the stepper calls per stage evaluation) and the `state_update`
block are order-free with disjoint writes. [Guards](#g-guard) and handlers are their
own small callables inside the [§10.6][s10-6] iteration.

**Each sweep block compiles in two arities off one entry list**, along the
interior/boundary split that [§10.5][s10-5] fixes. The zero-arg
`sweep_1()`/`sweep_2()` are the interior variants, over continuous entries
only. That is what makes `@ballocated(sweep_2()) == 0` a well-defined
measurement *of the interior path*, rather than of whichever tick phase the
simulation happens to be sitting in. The `sweep_1(tick)`/`sweep_2(tick)`
forms are the boundary variants, gating their discrete entries by
`(tick − Φ) % D` against the passed tick index, symmetric with `ticks(tick)`.
`rhs` takes no index ([D-147][d-147]). One gate serves all three tick-sensitive
blocks, because due-ness is per component, per boundary, never per stage.
`t*`'s empty due set is **arity selection, not an index trick** ([D-147][d-147],
[D-185][d-185]), so the `t*` iteration runs the zero-arg arities, whose compiled
bodies contain no discrete entries ([§10.5][s10-5]).

These bodies communicate only through the stores and the table. No value
crosses a [seam](#g-seam), whether between passes, between the blocks of one pass, or
between chunks. The seams therefore cost nothing, and the executor's
decomposition stays free. Fusing a step's sweep with its `state_derivative`
block, or an event round's sweep with its guards and fired handlers
([§10.6][s10-6]), is an optimization it may take or decline ([D-194][d-194]). Two doors
this structure opens for free are recorded, not committed. The first is
deterministic parallel evaluation of the order-free blocks, which have
disjoint writes and no floating-point reductions to reorder, because [§6.2][s6-2]
made every sum an ordered junction entry. The second is finer recompilation
granularity. Editing a discrete component invalidates the boundary body, not
the RHS body, which is literal under the two-arity split, since discrete
entries exist only in the boundary variants.

**[Chunking](#g-chunking) bounds the compile cost.** Within a large block the tuple splits
into chunks behind non-inlined but statically-typed function barriers.
Inside a chunk everything the design relies on survives: static dispatch,
inlining, view SROA, check folding, zero allocation. At the seams only
cross-entry fusion is lost, which a table-mediated dataflow barely had.
Chunk size is the implementation's *only* representation freedom (fully
fused and chunk-of-one are its endpoints), and it converts the compile cost
from superlinear in the largest body to linear in entry count.

Measured anchors, taken 2026-07 over synthetic ~15-op bodies on Apple
Silicon, with the last two rows extrapolated to a C172X-scale model of
roughly 200–400 entries with larger bodies ([§15.4][s15-4]). Those two rows
assume the chunked mode, the one whose cost is linear in entry count:

| case | activation | compile time |
|---|---|---|
| 400-entry sweep, fused | `Float64` | ~0.8 s |
| 400-entry sweep, chunked | `Float64` | ~0.34 s |
| 400-entry sweep, chunked | 8-partial `Dual` | ~9 s |
| C172X-scale model, extrapolated | nominal | seconds |
| C172X-scale model, extrapolated | `Dual` | tens of seconds, before mitigation |

The fused curve is visibly superlinear. An 8-partial `Dual` activation
multiplies instruction count ~20×, and its chunked curve is linear,
instruction-bound rather than structure-bound. Re-measurement on the real
vehicle skeleton is a [§16][s16] migration item.

**The mitigation ladder**, in order. Activations are lazy ([§9.4][s9-4]), so a
session that never linearizes never compiles `Dual`. Non-nominal activations
may compile at reduced optimizer level, because their sweeps run inside
service loops where microseconds are irrelevant, a one-line per-module
policy. And activations bake into package images via ordinary precompile
workloads. An aircraft package exercising build-plus-one-sweep per
activation turns TTFX from a session tax into a CI artifact.

**[Views](#g-view) are spelled rebuild-per-call.** Every entry constructs its bundle
(the NamedTuple of zero-copy views a component function receives) at its own
position. There is no framework-maintained hoisting and therefore no
cache-invalidation obligation. Hoisting belongs to the code generator. CSE
merges repeated loads exactly where no intervening store invalidates them,
which is precisely the staleness rule, and the sweep-varying bundle fields
(`u`, `y_x`/`y_s`) are per-call by topological necessity either way ([§7.1][s7-1]).

**Construction is type-opaque, and only the [executor](#g-executor) specializes.**
Schedule tuples are built from untyped buffers and splatted once. Generic
tuple utilities (range indexing, long `ntuple` closures, naive recursion) are
inference traps at schedule length, since a 400-entry heterogeneous tuple
can send generic `getindex` inference into combinatorial collapse. The
compiled tuple's type therefore has exactly one consumer, the unrolled walk.

**The phase bodies are the [§7.5][s7-5] [measurement seam](#g-measurement-seam).**
`phase_bodies(sim)` returns the compiled bodies of the nominal activation as
named callables bound over the simulation's own buffers. The four blocks:

- `rhs`, the `state_derivative` block.
- `sweep_1`, in both arities.
- `sweep_2`, in both arities.
- `ticks`, which takes the tick index its entries gate on.

Returned with them are the per-event guards and handlers and the
per-component `state_projection` callables, keyed by the model's own roster.

The four-body roster is fixed and total. The accessor returns all of it
always, whatever the model happens to declare. A model with no discrete
components, no events or no continuous state at all still gets every body.
The empty ones are legal, compile to no-ops, and their `@ballocated`
assertion passes vacuously. That is the point, because consumers then
iterate the roster uniformly, with no existence checks and no per-model
branching in the measurement code.

One promise, in the diagnostic register ([§13.5][s13-5]). **These are the bodies
the loop runs**, not re-derivations. That is what makes the measurement
honest, and why each callable carries the real in-loop argument types by
construction. Those types are the thing a hand-built standalone test cannot
reproduce, and [D-116][d-116] records why per-component tests cannot discharge the
invariant.

CI is warm-then-assert over the roster. One call compiles, then
`@ballocated(body()) == 0`. It asserts at per-body granularity, each sweep
arity in its own right, with the interior call bare and the boundary call at
a due index. So a documented [§7.5][s7-5] tolerance loosens exactly one assertion.
This is the successor of the migration suite's
`@ballocated f_ode!`/`f_step!`/`f_periodic!` idiom and the seam the [§16][s16]
FlightCore comparison measures through.

Publication is not a phase body. That is the carve-out ([§7.5][s7-5]) made
structural. What the accessor exposes is exactly what the invariant claims
is zero. Invoking bodies in isolation mutates the simulation's buffers
outside any [frame](#g-frame) sequence (a tick entry advances discrete state with no
clock advance), leaving them valid but off-trajectory. A session that wants
to continue meaningfully re-runs `init!`.

---

# Part III — Execution

Part III specifies the running simulation. [§10][s10] owns time. It fixes
the loop the framework writes rather than delegates, the stepper seam across
which integration is delegated, the localization machinery that finds
crossing instants inside a step, the multi-rate tick lattice, the event
iteration at each boundary, and real-time pacing. [§11][s11] is the data
plane between the loop and everything outside it. Outbound it fixes snapshot
publication. Inbound it fixes root inputs, per-device staging and the drain.
Alongside both it fixes the device authoring contract and the input trace
that makes a session replayable. [§12][s12] is the orchestration around
them: the control plane, the wait primitives and thread budget, the shutdown
protocol, the five run states, and replay.

Part III assumes the schedule rather than deriving it. The boundary sequence it
dispatches is fixed in [§5.3][s5-3], the executor it dispatches through is built in
[§9.7][s9-7], and the root inputs the periphery writes into are the root
component's input [faces](#g-face) ([§8.6][s8-6]). What Part III adds is timing, concurrency and
orchestration around machinery the earlier parts already settled.

## 10. Time and execution

### 10.1 Loop ownership: the framework owns the simulation loop

The simulation loop consists of six activities: the [§5.3][s5-3]
[boundary](#g-boundary) sequence, [tick](#g-tick) dispatch, event handling,
logging, input staging, and [pacing](#g-pacing) (waits inserted between
completed frames, never altering the boundary sequence).

**Rule.** All six are **framework code, unconditionally**. The framework
writes the loop itself. It does not assemble the loop out of callbacks
registered with a third-party solver.

**Why.** The step-boundary contract is the central invariant of this design.
Only a loop the framework owns can enforce that contract by construction
rather than by convention. Choreographing the same sequence as an ordered
`CallbackSet` inside a foreign event loop is rejected on exactly that ground
([D-017][d-017]).

`OrdinaryDiffEq` is therefore **dropped as a dependency** of the new core
([D-017][d-017]).

### 10.2 The stepper seam

Loop ownership stops at one operation: *advance the continuous state from `t`
by `h`*. The framework delegates that operation across a narrow internal
interface, the **[stepper seam](#g-seam)**. The seam exists so that the
integration method can be replaced without the loop changing.

#### What the seam requires of a backend

The seam contract has three clauses.

- **Advance by arbitrary `h`.** The loop needs this anyway. It lands on
  [tick](#g-tick) [boundaries](#g-boundary), and it resumes from a
  [localized](#g-localized) event time (the crossing instant bracketed by
  root-finding over trial sweeps).
- **Dense output on demand over the last completed step.** Only event
  localization needs it ([§10.4][s10-4]), so the backend constructs it lazily.
- **One-step methods only.** Event handlers reset state discontinuously, and a
  one-step method restarts from a new state for free. Multistep methods are
  excluded ([D-017][d-017]).

#### Models with no continuous state

A model with no continuous state at all is legal. Nothing in [§8.2][s8-2]
requires an `x` block of any component. Such a model still has to be run.

**The seam is never entered empty.** The framework short-circuits this case
rather than pushing it down the seam. With an empty `x`, the integrate step
degenerates to advancing `t` to the next boundary, and the stepper is not
called. No backend ever faces `N = 0`, and no backend contract has to say what
it would do there.

The ownership rule of [§10.1][s10-1] pays off structurally here. Under a
foreign solver loop, an empty state pays a dummy-`[0.0]` tax ([D-017][d-017]).
Here that tax is gone at the root. Not only the [buffer](#g-buffer)
disappears, but also the step over it. Everything else about such a model is
ordinary. The boundary machinery of [sweeps](#g-sweep), events and ticks runs
unchanged.

#### The first-cut backends

The first cut ships **in-house fixed-step RK4 and Heun** over the flat state
buffer. Together they are about a hundred lines. They are trivially
zero-allocation, so they can be audited against the CI invariant of
[§7.5][s7-5], and they are trivially `T`-generic. Genericity is not even
required of the stepper, because linearization and the tracer drive the
*sweep*, never the integrator.

Of the two, **`RK4` is the default**. The `algorithm` keyword selects the
backend by type, and deployment binding materializes it against the state
buffer ([Appendix B][sB], [D-227][d-227]). The step `h` has no default and is
**required** of the caller. A domain rate is not a framework default.

An `OrdinaryDiffEq`-backed stepper can exist later as a package extension, if
an offline study genuinely demands adaptive or stiff methods. Per the
guarded-additions rule it is not built until then.

#### Why fixed-step low-order suffices

The domain argument is recorded here because it is load-bearing for the whole
axis.

1. **The closed-loop tick cap.** Every application beyond bare propagation
   runs periodic avionics (50 Hz today), whose commands are zero-order-held
   signals. Integrating past a tick with stale commands is wrong, so the
   integrator must land on every tick boundary regardless of method. Adaptive
   and high-order methods pay off exactly when steps can stretch, and the
   execution model forbids the stretch by construction.
2. **A piecewise-smooth [RHS](#g-flow) starves high order.** Linearly
   interpolated lookup tables (C¹-kinked at every knot), clamps, friction
   blends and mode branches deny high-order error estimators and
   implicit-solver Newton iterations the smoothness they assume. RK4 at 50 Hz
   already puts integration error orders of magnitude below the model
   uncertainty of a coefficient-table aircraft model.
3. **Stiffness has a remedy ladder.** The fastest continuous dynamics in the
   current codebase sit inside RK4's stability region at `h = 0.02`. These are
   actuator poles near 31 rad/s, gear damper decay and friction compensators.
   The crosswind-landing demo is the empirical proof. If a future model
   exceeds that region, the ladder runs in order. First shrink `h`, since the
   RHS costs microseconds and 500 Hz real-time is unremarkable. Then subcycle
   the stepper against the tick grid. Only then reach for an implicit method
   through the adapter. If that day comes, the eltype genericity of
   [§7.2][s7-2] supplies exact ForwardDiff Jacobians through the sweep for
   free.

### 10.3 Signal-table consistency is a boundary property

During a step, the RK stages evaluate the [interior sweep](#g-sweep)
([§10.5][s10-5]) at internal stage states. While they do, the
[signal table](#g-signal-table) is transiently **integrator scratch**. The
[boundary sweep](#g-sweep) in the [§5.3][s5-3] sequence restores consistency
at each accepted [boundary](#g-boundary).

**Rule.** External readers (GUI, logging, network output) observe the signal
table only at step boundaries. Mid-step contents carry no meaning. This rule
binds the [periphery](#g-periphery) ([§11][s11]).

### 10.4 Localization mechanics

A [guard](#g-guard)'s [predicate](#g-predicate) can cross inside an integration step, strictly between two
grid points. The framework can handle such a crossing in two ways. It can notice
the crossing at the end of the step, at grid resolution. Or it can find the
crossing instant and publish it. This section fixes which guards get which
treatment, and describes the machinery behind the second.

Two terms recur throughout, and they mean different things.

- A **[frame](#g-frame)** is one grid step `[tₙ, tₙ₊₁]`. It is the unit of scheduling. Three
  things are keyed to it: the input [drain](#g-drain) (the frame-top swap that publishes
  staged device writes into the root inputs, [§11.4][s11-4]), pacer deadlines ([§10.7][s10-7]) and
  [tick](#g-tick) eligibility ([§10.5][s10-5]).
- A **[boundary](#g-boundary)** is a published consistency point. The [§10.6][s10-6] macro-sequence
  completes there and a [snapshot](#g-snapshot) goes out.

Every grid point is a boundary, but not every boundary is a grid point. The
localized event time `t*` is a boundary, and so is [boundary zero](#g-boundary-zero) (the
initialization boundary at `t₀`, [§14.5][s14-5]). Neither is a frame top.

A frame in which one event localizes runs through these steps, with boundaries
in bold:

> **tₙ** → integrate → arrival sweep at tₙ₊₁ → trigger → θ = 0 trial evaluation → bracket
> → root-find → **t\*** → remainder step → **tₙ₊₁**

This chain lists the order of operations. It is not a walk along the time axis.
The arrival sweep at tₙ₊₁ raises the trigger, and integration then resumes from
`t*`, which lies before tₙ₊₁.

#### Which guards localize: the form is the policy

**Rule.** The guard's return type declares its detection policy. No flag is
involved.

- A guard returning `Bool` is **[boundary-detected](#g-boundary-detected)**. The framework checks it for
  edges at step boundaries only and never root-finds it.
- A guard returning the nominal scalar, the continuous sign form, is
  **[localized](#g-localized)**. The framework brackets the crossing instant by root-finding
  over trial sweeps.

The build reads the policy off the [probe](#g-probe) it already runs ([§9.3][s9-3], nominal
[activation](#g-activation)). `StateEvent(guard, handler)` therefore carries no detection keyword
([D-179][d-179]).

**Why.** Localization brackets a root, and only the sign form offers one.
Because the form is the policy, the illegal pairing cannot be written at all. It
needs no diagnostic.

**A localized guard becomes boundary-detected with a one-line rewrite, at no
semantic cost.** Return the predicate `σ ≥ 0` instead of `σ`. That cast is the
definition of the predicate ([§2.1][s2-1]). The predicate and its edges stay the same.
Only the resolution at which they are observed changes.

#### Boundary detection is exact for guards over `u` and `m` alone

**Rule.** For a guard that reads only `u` and `m`, boundary detection is exact.

**Why.** Such a predicate is constant within each frame. `u` changes only at the
frame-top drain ([§11.4][s11-4]), and `m` changes only through handlers, at boundaries.
The predicate cannot cross mid-step, so there is no interior instant for a
root-finder to find. Here the boundary is not a resolution limit. It is the
crossing itself, and localization would have nothing to do.

#### Mixed predicates: the gate idiom

Most transitions in FlightPhysics mix input predicates with state thresholds, so
this case matters in practice. The piston engine's `starting → running` fires on
`ω > ω_idle && fuel_available`.

**Rule.** When such a transition should localize, write it in the gate form
`(gate) ? σ : -one(σ)`. The `Bool` factors go in the branch condition and the
continuous factor in the value.

**Why.** The idiom is sound rather than a way around the policy check. Trial
evaluations vary only θ. `u` and `m` stay fixed through a localization, so the
gates are constant over the bracket. Restricted to the bracket, σ is the
continuous atom, and it can be bracketed as such.

#### The trigger

**Rule.** A localized event triggers when its predicate was not-[holding](#g-edge-semantics) at tₙ's
[quiescence](#g-quiescence) (the fixed point where a round of handlers fires nothing) and is
holding at tₙ₊₁. The tₙ sample is the event's **[prior](#g-prior)**, the predicate sample
stored at the previous boundary ([§10.6][s10-6]).

This is the directional edge of [§2.1][s2-1], not a bare sign change. A holding →
not-holding transition neither fires nor localizes.

**The trigger check runs against the arrival [sweep](#g-sweep) at tₙ₊₁.** That is the sweep
that closes the integration step. So the check runs before the due-gated
[boundary sweep](#g-sweep) refreshes any discrete [cell](#g-cell). The rule that trial evaluations run
the interior sweep (below) already forces this order, because trial evaluations
must see the values the frame actually held. Stating it here fixes the
sequencing up front. Every `t*` firing precedes tₙ₊₁'s whole boundary sequence.

#### The localization loop

The sketch below shows one localized event within one frame. Every step is
normed afterwards.

```julia
# θ = (t − tₙ)/h, and every σ(θ) is a trial evaluation: write the state, run
# the interior sweep, evaluate the guard.
σ₁ = σ(1)                              # already computed by the arrival sweep
(prior not-holding && σ₁ holding) || return    # no trigger, nothing to localize

σ₀ = σ(0)                              # the θ = 0 validation: x̂(0) = xₙ, no interpolant
σ₀ holding && return                   # epoch-caused edge: fall through to tₙ₊₁

build x̂ from (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁)      # one sweep for ẋₙ₊₁, paid only here
lo, hi = 0, 1                          # the not-holding / holding bracket, in θ
while hi - lo > localization_tol       # relative: bracket width (hi − lo)·h vs. tol·h
    θ = next bracketed guess in (lo, hi)       # ITP, Brent or bisection
    σ(θ) holding ? (hi = θ) : (lo = θ)
end
t* = tₙ + hi·h                         # the holding endpoint of the final bracket
```

**The θ = 0 validation.** On trigger, the first act is a trial evaluation at the
left end. Write xₙ into the state [buffer](#g-buffer), run one [interior sweep](#g-sweep), and evaluate
the guard to get σ₀. Nothing new is kept, since the stepper already retains xₙ
for the [interpolant](#g-interpolant) (the cubic Hermite continuous extension over the last
completed step). This trial evaluation needs no interpolant, because x̂(0) = xₙ
identically. So it runs before any interpolant cost is paid.

The evaluation serves two purposes. σ₀ is the left bracket value that
value-based root-finders need. σ₁ = σ(tₙ₊₁) is retained from the arrival
evaluation, but σ₀ had no source until now. And σ₀ tells the edge's cause apart.

That discrimination needs one term. An **[input epoch](#g-input-epoch)** is a maximal span of
constant `u`, delimited by frame-top drains ([§11.4][s11-4]). Within an epoch a guard can
change only through the trajectory. At a seam between epochs it can jump without
crossing anything.

**Why the discriminator is conclusive.** `u` is the only thing that can differ
between the prior's evaluation context and this trial evaluation. `m` changes
only via handlers at boundaries, and priors are sampled at quiescence, after the
handlers. Discrete cells hold their values under ZOH, and the interior sweep
excludes discrete entries ([§10.5][s10-5]). `t = tₙ` exactly, by the indexed-grid rule
below. Sweeps are deterministic. So under the honest [priors](#g-prior) of [§10.6][s10-6], the
frame-top drain is the only possible source of disagreement.

- σ₀ **not-holding** means a **trajectory-caused** edge, a genuine in-frame
  crossing. Pay the sweep for ẋₙ₊₁, build the interpolant and root-find on the
  bracket $(t_n, \sigma_0)$/$(t_{n+1}, \sigma_1)$.
- σ₀ **holding** means an **epoch-caused** edge. The drain flipped the guard at
  the frame top. σ holds at both ends, so there is no in-frame crossing to find.

**An epoch-caused edge is discarded, not degraded.** The localization is
abandoned and the event fires inside tₙ₊₁'s ordinary iteration. Mechanically,
not localizing is the action. The frame falls through, and the boundary
iteration detects and fires the event like any boundary-detected event. This
path costs one interior sweep. It never pays for ẋₙ₊₁ or an interpolant, and it
consumes no `localization_budget`. It also warns nothing. Input timing is a
frame fact, by the same doctrine that forbids draining at `t*` below, and
boundary detection is exact for a `u`-caused edge (above; [D-179][d-179]). Boundary
firing is therefore the correct semantics, not a degradation. This is the
left-end mirror of the `t* = tₙ₊₁` degeneracy below.

**The interpolant is built lazily.** It is the cubic Hermite continuous
extension $\hat{x}(\theta)$, $\theta = (t - t_n)/h \in [0, 1]$, built from
$(x_n, \dot{x}_n, x_{n+1}, \dot{x}_{n+1})$. $\dot{x}_n$ is the step's first
stage. $\dot{x}_{n+1}$ costs one sweep, paid only on a validated trigger. The θ
= 0 trial evaluation comes first, so an epoch-caused edge never pays for it.
Uniform accuracy is $O(h^4)$, one order below the discrete solution, which is
the standard pairing. The event time can never be more accurate than the
interpolant, so nothing more expensive is worth running trials against.

**Trial evaluations run the interior sweep.** Guards read `y`. Evaluating a
guard at an interpolated state therefore means writing $\hat{x}(\theta)$ into
the state buffer and running the interior sweep. The [RHS](#g-flow) already lives under
this rule ([§10.5][s10-5]), since a trial evaluation is a mid-step evaluation. Discrete
cells therefore hold their [tick](#g-tick) values through localization, and a guard reading
a sampled output sees what the controller is holding. Each trial evaluation
costs one interior sweep.

**Root-finding is bracketed and derivative-free.** ITP or Brent are the intended
methods, and bisection is an acceptable fallback. The observed
not-holding/holding bracket is an unconditional convergence certificate. Newton
and AD localization are rejected ([D-018][d-018]).

**Convergence is a relative bracket width.** Localization stops once the bracket
is narrower than `localization_tol · h`. `localization_tol` is a `Simulation`
deployment keyword defaulting to `1e-6`. The tolerance is relative because an
absolute tolerance in `t` is not scale-free ([D-133][d-133]). The default is `1e-6`
because the event time can never be more accurate than the interpolant, which is
`O(h⁴)` as stated above. At practical `h`, anything tighter buys nothing, while
every trial evaluation costs a full sweep. Under ITP the bill is a handful of
trial evaluations, and around 20 in bisection's worst case.

**Post-event.** The boundary sequence runs at `t*` (below). The interpolant is
then invalidated, because the handlers have made it wrong for `t > t*`.
Integration resumes from `t*` with the [remainder step](#g-remainder-step) targeting tₙ₊₁, and the
guards are re-checked on the remainder. The re-check runs under the per-frame
[localization budget](#g-chattering), with a chattering diagnostic.

**Multiple events localizing in one step fire at the earliest `t*`.** Ties fire
at that boundary inside the event iteration, one eligible event per component
per round in declaration order ([§10.6][s10-6]). Later crossings re-localize on the
remainder.

**Both policies share one blind spot.** An even number of crossings within one
step returns the predicate to not-holding at the boundary, so no edge is
observed. Neither policy can detect this. The mitigation is a smaller step size,
not more machinery.

#### Endpoint policy and grid integrity

**Rule.** The root-finder returns the holding endpoint of its final bracket.
That is the smallest trial point where the predicate holds.

**Consequence.** `t* = tₙ` is structurally impossible. It never needs clamping
away.

**Why.** The argument rests on what was measured, not on what the prior reports.
Root-finding starts only after the θ = 0 validation has measured σ₀ not-holding
under the frame's own `u`. The bracket's left end is therefore not-holding by
the same kind of evidence as its right end, and the returned point is strictly
later than the published, immutable tₙ. In the worst rounding case it is
`nextfloat(tₙ)`. This holds unconditionally. It needs no appeal to the prior and
leaves no residual epoch hole, because the case where the prior and the frame's
`u` disagree is exactly the epoch-caused edge, and that case never reaches the
root-finder.

The guard also observably holds at `t*`. Handlers therefore fire in states where
their own predicate holds, and the post-fire prior records an actual observation
rather than an assumption.

**`t* = tₙ₊₁` exactly is legitimate.** It is a crossing at the grid point, where
σ(tₙ₊₁) = 0 both triggers detection and is the root. It degenerates to the grid
boundary. The localization result is discarded and the event fires inside tₙ₊₁'s
ordinary iteration. That outcome is bitwise identical to the boundary-detected
one, with one boundary, one snapshot and no zero-length remainder.

**Grid times are indexed, never accumulated.** A near-degenerate `t*` leaves a
tiny remainder step. Numerically that is harmless, since increments scale with
`h′`. The real hazard is bookkeeping, and this rule removes it. `tₖ = t₀ + k·h`
is computed from the frame index, just as tick gating is already counter-modulo
([§10.5][s10-5]). The remainder step targets the grid point, with `h′` derived at use.
`t*` is a float inside a frame, never an anchor from which anything else is
computed.

#### What a `t*` boundary does, and does not, do

At `t*` the full [§10.6][s10-6] event phase runs. The sweep → guards → handlers cycle
iterates to quiescence, with firing-budget accounting scoped to this boundary.
The budget is fresh again at tₙ₊₁, and again at a second `t*` on the remainder.
The settled state is then published. That means a snapshot, the [§12.3][s12-3]
boundary-counter increment and the [`stop_on`](#g-stop_on) check ([§13.5][s13-5]). A crash localized at
`t*` ends the run from that snapshot.

**Two things do not happen at `t*`.** Ticks are never due there. `t*` is off the
[harmonic grid](#g-harmonic-grid) (every discrete period an integer multiple of `Δt_base`) by
construction, and discrete cells ZOH-hold through the sweep. Staged inputs are
not drained either, for two reasons. Input timing is a frame fact, and replay
determinism must not depend on localization arithmetic.

**The `t*` publication is not separately paced.** The pacer paces frame
deadlines. A `t*` snapshot publishes when computed, mid-frame. Where that lands
in wall-clock time is below what pacing resolves. The [§10.7][s10-7] invariant is about
trajectories, and those are identical either way.

Replay pointers and error messages index boundaries by the frame-entry boundary
index ([§13.4][s13-4]) together with the recorded `t`. Snapshots carry the trajectory's
published-boundary ordinal ([§12.3][s12-3]). The trace stays frame-indexed, since `t*`
boundaries consume no inputs.

#### Projection's reach is the boundary, not the trial evaluation

**Rule.** Guard trial evaluations run against the raw interpolated state.
Authority rests with the `t*` boundary. [Projection](#g-projection) runs there, and the [§10.6][s10-6]
iteration's edge checks read the projected state.

**Why.** RK-stage RHS evaluations already run under the same rule, since they
are equally off-manifold. Sweeps must therefore tolerate near-manifold states,
and they already do. Per-trial projection is rejected ([D-018][d-018]).

If projection moves the state back across a guard, the event does not fire and
the run has published one extra boundary. That is harmless. Like any other
localization outcome, it is deterministic and pace-independent ([D-080][d-080]).

#### Budget exhaustion degrades; it does not throw

**Rule.** `localization_budget` is an integer count of localizations permitted
within one frame. It defaults to **8**. It is the second deployment keyword this
section fixes.

**Why 8.** A legitimate multi-event frame needs three or four localizations.
Three landing-gear struts touching down inside one step is the reference case.
[Chattering](#g-chattering) needs tens. A budget of 8 bounds the pathology without ever binding
on a healthy model.

**When a frame spends its budget**, localization stops for the rest of that
frame. The remainder step completes, and any further crossings fire in the next
boundary's ordinary iteration, at boundary granularity for that frame. A
`ChatteringBudget` warning ([Appendix C][sC]) names the chattering event and the
localization count.

The degradation depends on the trajectory alone, never on wall clock. The
pace-independence guarantee ([D-080][d-080]) therefore stands, and the run replays
identically. A `StepError` here would misclassify an expected modeling outcome
as broken machinery, which the [§14.8][s14-8] doctrine forbids.

**The same doctrine governs [§10.6][s10-6].** Neither the boundary iteration nor
cross-frame re-localization has a structural bound, so each takes a budget. The
boundary iteration takes `firing_budget`, and re-localization takes
`localization_budget`. Both degrade loudly rather than erroring, under a warning
that names the offending event. They differ only in what exhaustion sheds.
Localization sheds root-finding precision and preserves every firing at boundary
granularity. The firing budget sheds firings, which is exactly what bounds the
iteration.

#### Both constants are deployment, not implementation

`localization_tol` and `localization_budget` are `Simulation` keywords. They
stand beside `h`, `N_base` and the algorithm ([§9.1][s9-1], [Appendix B][sB]). They are
validated with their siblings, as a positive tolerance and an integer budget ≥
1, and failures are collected into `DeploymentInvalid` ([Appendix C][sC]). The
`firing_budget` ([§10.6][s10-6]) stands beside them in every one of these lists. It gets
the same validation, the same `DeploymentInvalid`, the same trace header and the
same replay comparison. Both are grid-independent, so neither enters the
harmonic-grid check ([§10.5][s10-5]).

**Because they determine the trajectory, both are recorded.** They ride the
[trace header](#g-trace-header)'s deployment block and join the set that [replay](#g-replay) compares up front,
exactly as `h` and the algorithm do ([§11.5][s11-5], [§12.7][s12-7]).

**Why.** Without this, the replays-identically promise above is empty. A run
that does not record what its localizer was told to do cannot be re-driven
through the same localization outcomes.

### 10.5 Multi-rate tick scheduling

A model runs several clocks at once. The integrator advances on the continuous
step `h`. An inner control loop samples at one rate, an outer loop at another,
and a receiver at a third. Each of those must hold its outputs steady between
its own firings. Three things have to be fixed for that to be well-defined: the
time lattice every rate shares, the test that decides which components run at
a given [boundary](#g-boundary), and the surface an author declares a rate on.
This section fixes all three, in that order.

#### The base grid, and the pair every rate compiles to

**Rule.** Every discrete [component](#g-component)'s period is an integer
multiple of a base [tick](#g-tick) period `Δt_base`. `Δt_base` is itself an
integer multiple of the continuous step, with `N_base` steps per base tick
($\Delta t_{\mathrm{base}} = N_{\mathrm{base}} \cdot h$, $N_{\mathrm{base}} \ge 1$).
That is the **[harmonic grid](#g-harmonic-grid)**. Ticks therefore land on step
boundaries, which is the only place anything discrete ever happens
([D-019][d-019]).

**Two indices.** Frames are counted by the **frame index** `k`. The frame top
at `t = k·h` is a base tick exactly when `k` is a multiple of `N_base`. Its
**[tick index](#g-tick-index)** is then `tick = k ÷ N_base`. A frame top that
is no base tick has no tick index, and neither does a `t*` boundary.

**One pair per component.** However an author declares a rate, and however
deeply the declaration is nested, the build compiles it to two integers per
discrete component. The divisor `D` is the component's period in base ticks.
The [phase](#g-phase) `Φ` is its offset in base ticks. The pair is kept in the
canonical residue `0 ≤ Φ < D`, so the component's ticks fall at base-tick
indices `Φ`, `Φ + D`, `Φ + 2D`, and so on.

**The gate.** A component is **[due](#g-due)** at a boundary when
`(tick − Φ) % D == 0`, where `tick` is the boundary's tick index. That
subtraction and remainder are the whole admission test. It costs one
subtraction more than a phase-free test would, over a lattice fixed at build
time. The declaration surface below says where a component's `(D, Φ)` comes
from.

#### Discrete stages run only at their own ticks

**Rule.** A discrete component's `output_state`/`output_direct` run only at
its own ticks. Its [cells](#g-cell) hold in between. This is zero-order hold
(ZOH), stated in [sweep](#g-sweep) terms.

**Why.** Re-running a discrete component's stages at every boundary would
un-sample a sampled-data controller ([D-019][d-019]).

Delivering that hold takes **two statically distinct sweep variants, compiled
from one entry list**. Discreteness is a build-time fact, so the split is
static rather than a runtime test ([D-147][d-147]).

- The **[interior sweep](#g-sweep)** walks *continuous entries only*. RK stage
  evaluations ([§10.3][s10-3]) and localization [guard](#g-guard) trial
  evaluations ([§10.4][s10-4]) run this variant. The ZOH therefore holds
  mid-step **by construction**. Discrete entries are not gated out at runtime.
  They are absent from the walk at compile time, so the hot path carries no
  gating test at all.
- The **[boundary sweep](#g-sweep)** walks the full list, with discrete
  entries gated by `(tick − Φ) % D` against the boundary's tick index. It is
  the variant the [§10.6][s10-6] macro-sequence runs. It is not one fixed list
  either, because different boundaries run different subsets of the
  [schedule](#g-schedule).

The split applies to **both sweep blocks**. The discrete [tier](#g-tier)'s
`output_state` entries are absent from the interior stage-1 walk, exactly as
its `output_direct` entries are absent from the interior stage-2 walk. The two
sweep variants surface in the phase-body signatures: interior bodies take no
arguments, boundary bodies take the tick index ([§9.7][s9-7]).

#### The due set is a property of the boundary

**Rule.** The due set is computed once for the boundary and reused by every
re-sweep of its [quiescence](#g-quiescence) iteration (the fixed point where a
round of handlers fires nothing, [§10.6][s10-6]). It is a property of the
boundary, not of the sweep call.

**Why.** A due component is at its tick instant for the whole boundary, not
for one round of it.

Each kind of boundary has its own due set:

- At a **tick frame top** (every `N_base`-th frame top), the due set is every
  discrete component whose gate admits the tick index. These are the `(D, Φ)`
  pairs with `(tick − Φ) % D == 0`.
- At an **off-tick frame top** (a frame top with `N_base > 1` that is no base
  tick), the due set is **empty**. The tick counter has not advanced, so no
  component is at a tick instant.
- At a **`t*` boundary**, the due set is **empty** for the same reason. A
  modulo test against the unadvanced index would wrongly re-admit the previous
  tick's due set.
- At **[boundary zero](#g-boundary-zero)** (the initialization boundary: the
  ordinary macro-sequence with an empty integrate), the due set is
  **everything with `Φ = 0`**. At tick index 0 the gate reads
  `(0 − Φ) % D == 0`. Under the canonical residue `0 ≤ Φ < D` that holds if
  and only if `Φ = 0`. Nothing implements this rule. It falls out of the
  ordinary gate. Dueness at boundary zero governs the `state_update` calls
  alone. Output stages publish due or not ([D-205][d-205]), as [§14.5][s14-5]
  specifies.

An offset component's first tick is at `Φ·Δt_base`. Until then its cells hold
its boundary-zero publication. Its output stages run at `t₀` due or not,
evaluated from the authored world ([D-205][d-205], [§14.5][s14-5]). The
probe's synthesized values ([§9.3][s9-3]) reach no published cell. The "tick
at `t₀⁻`" story they once told held only in the build's own world, because the
probe runs before any condition exists. In a phase-free model every `Φ` is 0,
so at boundary zero everything is due and the distinction is empty.

#### Simultaneous ticks are already well-defined

Several components can be due at one boundary, and settled machinery already
orders them. All due components run their output stages in topological order
within the sweep. All due `state_update` calls run after the sweep, in any
order. Each one reads the table and writes only its own `s` store. The FCS
cascade's intra-tick ordering is therefore a sweep property, not an
update-order property.

#### Coincidence and stagger are modeling choices with observable consequences

Coincident ticks give a consumer fresh same-instant reads via topological
order. That is the idealized synchronous-sampling picture. A phase stagger
makes the same reads pipelined and deterministically aged instead. That is the
structural expression of an acquisition pipeline's latency, obtained with no
delay blocks.

A stagger is also a load-shaping tool under real-time [pacing](#g-pacing)
(waits inserted between completed frames, never altering the boundary
sequence). Staggered stacks never share a [frame](#g-frame), so worst-case
frame cost is a `max` rather than a sum ([§10.7][s10-7]).

Both patterns are worked in `sample_time_proposal.md`, together with how
silently an offset edit rewires a coincidence structure. The
[bound schedule](#g-bound-schedule) (the printable per-component `(D, Φ, Δt)`
artifact deployment binding produces) and its hyperperiod chart
([§9.2][s9-2]) are how a user audits which pattern a model actually has.

#### Assemblies: virtual for execution, rate scopes for declaration

An assembly is virtual for execution. Its children are scheduled individually,
and the assembly itself never runs as a unit. For declaration, a
[rate scope](#g-rate-scope) is an assembly's `sample_times` declaration
against the enclosing scope. There are no atomic [assemblies](#g-assembly),
and no opt-in variant ([D-019][d-019]).

**Why no coarsening is needed.** The [signal table](#g-signal-table) makes
interleaving semantically invisible. Consumers read cells whose freshness is
guaranteed by topological order rather than by contiguity.

#### Declaring a sample time: two registers, one concept

**Rule.** A discrete component or sub-assembly is scheduled by a
`sample_times` entry in its enclosing assembly ([§8.7][s8-7]). The entry
declares one (period, phase) pair in one of two unit systems, and the wrapper
type names the unit system.

| entry | unit system | tick instants | constraints |
|---|---|---|---|
| `Relative(K, Φ = 0)` | scope ticks | every `K`-th tick of the enclosing scope, starting from its `Φ`-th | `K ≥ 1`, `0 ≤ Φ < K` |
| `Absolute(q, τ = 0)` | seconds | `t = τ + k·T`, with `T = period(q)` | `T > 0`, `0 ≤ τ < T` |

`K = 1` therefore admits no stagger. Two same-rate siblings are staggered one
level down instead. Declare the scope at twice their rate, then give them
`Relative(2, 0)` and `Relative(2, 1)`.

`q` is a quantity value, `Period(1//50)` or `Hz(50)`. The two are a spelling
choice, normalized to the rational period at construction. Every period and
offset is an exact `Rational{Int}`, because grid derivation is GCD arithmetic
and ill-defined over floats. A float argument throws the teaching error naming
the exact spelling (`Period(1//50)`, or `Hz(1//2)` for 0.5 Hz).

The wrappers are the whole vocabulary. A bare integer or bare quantity is a
declaration error. An unlisted discrete child defaults to `Relative(1)`, so
the common case costs nothing and a multiplied or anchored child always
appears explicitly.

**Validation belongs to [Stratum](#g-stratum) A**, the build's
declaration-validation stratum, and is collected with path attribution
([§9.1][s9-1], [§13.1][s13-1]). It covers `K ≥ 1`, `0 ≤ Φ < K`, `T > 0`,
`0 ≤ τ < T`, and keys naming discrete or scope children. The constructors
themselves are plain data carriers, with no checks of their own
([D-185][d-185]).

#### The relative register composes affinely and stays on the scope grid

**Rule.** Multipliers compose multiplicatively and phases affinely down the
tree. Under a scope compiled to divisor and phase `(D_s, Φ_s)` in base ticks, a
child declared `Relative(K, φ)` compiles to `D = K·D_s` and `Φ = Φ_s + φ·D_s`.

Composition preserves the canonical residue `0 ≤ Φ < D`.
`sample_time_proposal.md` carries the one-line induction. All scoping
therefore compiles away at build to **one `(D, Φ)` pair per discrete
component**, and the boundary sweep gates on that pair with the
`(tick − Φ) % D == 0` test above. The lattice stays static, and the interior
sweep still holds no discrete entries to gate.

**Why relative is the default register.** In a layered control architecture
the *ratios* are intrinsic to the design and travel with the assembly type.
The inner loop runs at `Relative(1)` and the outer loops at `Relative(5)`,
whatever the deployment. The convention that keeps `K ≥ 1` livable is this:
**a scope's base rate is its fastest relative member**, and that member gets
`K = 1`.

**Two structural properties confine grid cost to the other register.** A
relative phase selects among scope ticks that already exist, so it never
refines the base grid. And it cannot place a tick *between* scope ticks.
Staggering off-grid means declaring the offset in seconds, or declaring the
scope base finer than its fastest member so that unused slots exist.

#### An `Absolute` entry detaches its child from the scope's grid

**Rule.** An `Absolute` entry may appear in any scope's `sample_times`, not
only the root's. The `(T, τ)` pair it establishes is an **[anchor](#g-anchor)**,
and the child hangs from that anchor. The child is severed from the enclosing
scope's grid, and no relation to the scope's ticks remains.

Three corollaries follow:

- `K ≥ 1` reads "a child cannot tick faster than the scope it is *relative*
  to". An anchored child may therefore tick faster than its scope.
- The fastest-member convention counts relative members only.
- Phase relationships between an anchored child and its relative siblings are
  **deployment-emergent**. Whether their ticks ever coincide depends on how
  the grid derivation works out. That is the question the printable bound
  schedule ([§9.2][s9-2]) exists to answer.

Relative children *of* an anchored subtree compose against the anchor exactly
as against the root grid. A nested anchor simply severs again (the fold,
[§9.1][s9-1]).

**Absolute periods and nonzero offsets jointly constrain the base grid.** They
join the deployment-time constraint pool ([§9.1][s9-1]). This is the subtlety
with teeth. An offset of `T/2` can cost a 2× finer grid, and `T/1000` a 1000×
one. The cost is relational, incurred against everything else declared. That
is why attribution is the engine's job ([§9.2][s9-2]).

#### A declaration, its compiled pairs, and one hyperperiod

Three discrete components sit under two scopes, at a deployment that binds
`Δt_base = 2 ms` ([§9.1][s9-1]):

```julia
# Root scope: (D_s, Φ_s) = (1, 0).
sample_times(::Vehicle) = (fcs  = Relative(1),        # → (D, Φ) = (1, 0)
                           gnss = Absolute(Hz(50)))   # → (10, 0), anchored at T = 20 ms

# fcs is the enclosing scope of its own children, at (D_s, Φ_s) = (1, 0).
sample_times(::FCS) = (inner = Relative(1),           # → (1, 0)
                       outer = Relative(5, 2))        # → (5, 2), D = 5·1, Φ = 0 + 2·1
```

Those pairs are what the boundary gate reads at run time. One hyperperiod is
`lcm(Dᵢ) = 10` base ticks. Because the gate is pure modulo arithmetic, that
one hyperperiod is the complete truth rather than a sample ([§9.2][s9-2]):

```
base tick k:  0  1  2  3  4  5  6  7  8  9 | 0  1  …
inner         •  •  •  •  •  •  •  •  •  • | •  •       (D, Φ) = (1, 0)
outer               •              •       |            (5, 2)
gnss          •                            | •          (10, 0)
```

`outer` is due where `(k − 2) % 5 == 0`, `gnss` where `k % 10 == 0`. Should
`outer` read a `gnss` cell, the ZOH makes that read two base ticks old at
`k = 2` and seven at `k = 7`. That is the deterministic aging of a stagger, in
this model's numbers.

#### Where the doctrinal line falls on mid-tree anchors

Absolute-first declaration as the default register is rejected
([D-019][d-019], [D-186][d-186]). What mid-tree anchors legitimize is
narrower.

**Rule.** An absolute declaration inside a library type is legitimate when the
rate is **a fact about the modeled system, not a preference about the
simulation**.

A GPS receiver emitting at 1 Hz, a bus schedule and an ADC pipeline's fixed
conversion offset are as intrinsic to the assembly as its wiring. Forcing them
to the root breaks encapsulation, since the root would have to know instrument
internals to re-declare them.

"Run the controller at 400 Hz in this study" remains a deployment choice, and
the existing idiom remains its answer. The assembly exposes its multiplier as
a constructor parameter. Absolute pinning *from outside* a subtree's
[contract](#g-contract) stays rejected as action at a distance.

The framework cannot police the distinction. It is authoring doctrine,
recorded here.

**Anchoring leaves the never-cache-`Δt` argument below fully intact.** The
pinning happens in the enclosing assembly's `sample_times`, the same site
where the multiplier lives. The component type itself therefore stays
rate-agnostic, and still consumes the `Δt` of its [bundle](#g-bundle) (the
NamedTuple of zero-copy views a component function receives).

#### `Δt` has a single source of truth: the compiled schedule

**Rule.** Each discrete component's effective period arrives read-only as the
`Δt` field of every discrete-tier bundle ([§5.2][s5-2]), in `output_state`,
`output_direct` and `state_update` alike. The field is absent from continuous
bundles, so touching it on the wrong tier is a missing-field error rather than
a rule.

**It must be readable in the *stages*, not just in `state_update`.** Per
[§15.2][s15-2], the discretized laws that actually consume `Δt` run in
`output_direct`. A PID's backward-difference coefficients and a LeadLag's
Tustin transform are the examples. `state_update` is a copy.

The value must arrive through the call, and the bundle field is where it
arrives. A `comp.Δt` virtual property is impossible here, not merely
inconvenient ([D-019][d-019]).

**Author rule: never store `Δt`, or any `Δt`-derived coefficient, as a
component parameter.** Recomputing derived coefficients per tick is a few
arithmetic ops. A cached copy is a second thing for gain-scheduling machinery
to chase.

**Relative declaration structurally enforces that rule for the period
itself.** Under scoped multipliers a component author *cannot* know their
absolute rate. It does not exist until composition.

**Phases change none of this.** The bundle's `Δt` is still `D·Δt_base`. An
offset shifts firing instants and never the period, so the discretized laws
([§15.2][s15-2]) are unaffected by staggering.

### 10.6 Event iteration at boundaries: to quiescence, budgeted

[§5.3][s5-3] leaves two questions open. How far does the event phase run at a [boundary](#g-boundary),
and how often may each event fire while it does? This section answers both. The
phase iterates. One round re-runs the [boundary sweep](#g-sweep), evaluates all [guards](#g-guard)
against it, and fires the eligible events, at most one per [component](#g-component). Each
firing is `handler → state_projection`. Rounds continue to [quiescence](#g-quiescence), the fixed
point where a round of handlers fires nothing.

**Rule.** An event fires in an iteration round if and only if three conditions
hold. Its [predicate](#g-predicate) is observed holding in that round. The sample observed
before it was not-holding. And the event's firing count for this boundary is
below `firing_budget`. That is the whole definition of "newly fired". The
predicate is the one [§2.1][s2-1] defines, either the `Bool` form true or `σ ≥ 0`.
`firing_budget` is a `Simulation` deployment keyword, an integer ≥ 1 defaulting
to **4**. It caps how many times each declared event may fire at one boundary.

Three registers per event decide the rule, all named normatively.

- The **[prior](#g-prior)** is the previous boundary's quiescent sample. The boundary's
  first round tests against it.
- The **last-observed sample** is initialized from the prior when the boundary
  opens and overwritten by every round's evaluation. Every later round tests
  against it. There is one exception. An event that was eligible but blocked
  (below) keeps its sample, because blocking defers its edge rather than
  consuming it.
- The **firing count** for the boundary is incremented at each firing and reset
  when the boundary ends.

Eligibility inside a boundary is therefore an [edge](#g-edge-semantics) like any other. It is a
not-holding → holding transition, never a bare sign change. What differs is the
reference sample. The edge is read against the last-observed sample, not against
the prior the boundary entered with. Two consequences follow. Sticky predicates
need no special case. An event that fires and keeps holding presents no further
not-holding → holding edge, so it fires once, at the boundary where it first
held. And a predicate that is genuinely falsified and re-enabled inside the
boundary, because another handler's cascade reverted its effect, fires again at
this boundary against a fresh sweep ([D-181][d-181]).

One boundary's iteration, sketched:

```julia
# entering the boundary, per event:  last ← prior,  count ← 0
while the previous round fired something   # the first round always runs
    boundary sweep                         # whole gated schedule, due set fixed for the boundary
    per event:      eligible ← last not-holding && now holding && count < firing_budget
    per component:  firing ← its first eligible event, in declaration order
    per event:      last ← now, unless eligible and not firing   # a blocked edge stays unconsumed
    fire the firing events                 # handler → state_projection, count += 1
end                                        # the exit condition is quiescence
per event:  prior ← last                   # the settled boundary's honest sample
```

**The prior is updated at each boundary's quiescence, from the final
post-iteration samples.** The update is unconditional. Every prior is therefore
an honest observation of a settled boundary. That is what makes the θ = 0
discriminator ([§10.4][s10-4]) conclusive. The [frame-top drain](#g-drain) is the only possible
source of disagreement between the prior and the left-end trial evaluation.

All three registers are detection bookkeeping, not model memory. They are
correctly absent from every state store. They are not captured, not traced, and
reconstructed deterministically. Beyond the prior, the cost is one `Bool` and
one small counter per event.

**[Boundary zero](#g-boundary-zero) sets every prior to not-holding.** A predicate already holding
in the authored state therefore fires at `t₀`. That behavior ([§14.5][s14-5]) is derived
rather than asserted. A warm restart resets all three registers from scratch,
because `init!` re-runs boundary zero ([§14.5][s14-5]). Predicates holding in the newly
applied state fire again at the new `t₀`.

**Why iterate.** Under a single pass, a cascade of N logically simultaneous
transitions (supervisor FSM → subordinate FSM → …) takes N steps to complete, at
latency N·h. Model semantics would then depend on the integrator's step size,
and `h` is an execution parameter. This is the same class of footgun [§2.2][s2-2] cited
when killing `f_step!`. Cascades are not a corner case either. Externalized FSM
components are blessed ([§3.1][s3-1]), which makes cross-component cascades the expected
idiom. Established practice agrees. Hybrid automata take sequences of
instantaneous transitions at one time point, Modelica iterates events to
quiescence, and Stateflow runs charts to completion within a [tick](#g-tick).

Boundary-detection timing remains h-dependent, but that is a different quantity.
It is the resolution at which a physical crossing is noticed. The cascade delay
would have been structure the framework inserts between transitions the model
declares simultaneous.

**Why a full re-sweep per round.** A transition reaches the [signal table](#g-signal-table) only
through a sweep. A handler writes its component's state stores and nothing else.
So neither the transitioning component's own [ports](#g-port) nor the downstream stage-2
chains that read them have moved. A round therefore re-runs the whole gated
[schedule](#g-schedule). The cost is noise. Sweeps take microseconds, and rounds beyond the
first require an actual cascade.

**Within a round, the signal table has a single writer, and it is the sweep.** A
handler writes nothing to the table. It returns transitions, the framework
latches them into the component's state stores, and `state_projection`
normalizes them. Auto-publication is a sweep act like any other stage-1 write
([§9.5][s9-5]). Nothing moves the table mid-round.

This gives the [epoch rule](#g-input-epoch), which is the core of this section. **A handler
executes against exactly the world its guard fired on.** Its own `y`, foreign
`u` and its own `x`/`m` all come from the firing round's sweep, so `y = h(x)`
holds at every handler entry. No [bundle](#g-bundle) (the NamedTuple of zero-copy views a
component function receives) ever straddles two epochs. Serialization is what
delivers this. A component's state stores are written only by its own handlers,
and it fires at most one event per round, so no same-round writer precedes any
handler's entry.

**A component's other eligible events are blocked, not lost.** Each is
re-decided in the next round, against the post-transition sweep. Declaration
order is therefore a priority with re-decision, not a simultaneity. An event
whose premise the earlier transition falsified simply does not fire. Under a
within-round sequence it would have fired on the stale premise. Blocking is
visible in the registers ([D-191][d-191]). An eligible-but-blocked event is the one case
whose last-observed sample is not overwritten, so the edge it presented stands
unconsumed. A guard that keeps holding therefore fires in the next round on that
same edge. One that the transition falsified records not-holding as usual, and
any later re-rise is a fresh edge. The prior stays honest at no cost. The
quiescent round fires nothing, hence blocks nothing, so every sample takes its
final update before the prior is written.

**Across components, handler order within a round is semantically
unobservable.** The reason is stronger than serialization. There is no
delivering mechanism at all. Nothing writes the table mid-round, so there is
nothing for order to observe. Execution order is fixed all the same, as [executor](#g-executor)
component order and then declaration order within a component. That keeps the
[§13.4][s13-4] cursor and the diagnostics stream deterministic. No trajectory depends on
it. The natural single-pass executor is therefore exactly correct. It builds
each handler's bundle at dispatch, from the live table. It needs no
pre-materialization, no staging pass, no carrier and no shadow table, and it
allocates nothing.

**The trade, stated openly, is that a handler cannot opt into seeing a
same-round foreign transition.** Same-instant sequential coupling across
components is a cascade, one round per link, deterministic. Coupling tighter
than that belongs inside one component, where declaration order gives exact
sequencing across rounds. This is the position of the synchronous languages. A
micro-step sees the pre-state, and effects appear at the next micro-step.
Serializing same-component firings costs one extra intra-boundary sweep per
event so serialized, which is microseconds on the rare boundary that fires at
all. [D-154][d-154] records the rejected shapes. They are the per-event re-decode with a
frozen round-start `u` ([D-016][d-016], [D-100][d-100], [D-152][d-152]), live-table reads under the
canonical execution order, a table copy per firing round ([D-100][d-100]), and handlers
stripped of their own `y`.

**Why a per-event budget.** A re-enabled event fires at its true boundary,
against a fresh sweep. The deferral design and the per-round cap are both
rejected ([D-020][d-020], [D-181][d-181]). Priors stay honest as a consequence. Every prior is a
sample actually taken, never a value recorded to make a rule work out.

Termination is then budget-bounded rather than structural. For `E` declared
events, a boundary admits at most `firing_budget · E` firings, hence a bounded
number of rounds, deterministically and independently of pace. A livelock, such
as two FSMs toggling each other, does not resolve silently. Each toggler spends
its budget and warns (below), and the run proceeds and replays identically. This
is degradation, not an error, per the doctrine of [§10.4][s10-4]. The warning names the
actual chatterer, while every other event's iteration continues untouched.

This trade is also stated openly. Because termination is budget-bounded rather
than structural, the arbitrary-K objection lives on in `firing_budget`. What
that buys is the absence of deferral machinery. There is no manufactured prior,
no re-arm flag, no `EventDeferred` warning, no one-step artifact, and no
collapse of several intra-boundary re-arms into a single later firing.

**Budget exhaustion degrades; it does not throw.** When an event has fired
`firing_budget` times at a boundary, its further edges there are lost for the
rest of that boundary. The eligibility test skips it while every other event
iterates normally. A lost edge emits a `FiringBudget` warning ([§13.2][s13-2], [Appendix
C][sC]), at most once per event per boundary. An event that fires its budget out
and then quiesces lost nothing and warns nothing. The warning carries the
component path, the event name, the boundary time and the exhausted budget
beside the boundary's firing count.

The default of **4** is chosen the way [§10.4][s10-4] chooses 8. A legitimate re-enable
is one or two firings deep. A toggling FSM pair chatters without bound. A budget
of 4 separates the two without ever binding on a healthy model. Like every other
degradation here, it depends on the trajectory alone, so the run replays
identically.

**Ticks stay outside the iteration, after quiescence.** The two possible
couplings resolve asymmetrically.

- *Events → ticks: machinery already in place handles this.* Due discrete
  components' output stages (`output_state`/`output_direct`) are gated into the
  boundary sweep against a due set fixed for the whole iteration ([§10.5][s10-5]). Every
  iteration round therefore refreshes them for free, against the same `s` and
  post-transition inputs. Their `state_update` has not run yet. At quiescence,
  their published outputs reflect the settled boundary instant, which is exactly
  what "sampling at t" should mean for a logically instantaneous cascade.
  Earlier rounds' tentative values are internal scratch, like RK stage
  evaluations. [§10.3][s10-3] extends naturally. External readers observe the table only
  after the boundary sequence completes.
- *Ticks → events: structurally impossible.* A tick's output stages contribute
  nothing guards have not already seen, since they run inside the sweep, from
  current `s`. Its `state_update` writes `s⁺` after the sweep, and `s⁺` is first
  decoded at the owner's next tick. So `s⁺` is invisible to every reader within
  the boundary. This is the standard one-sample `z⁻¹` delay of sampled-data
  control, enforced here by construction. Nothing that happens after quiescence
  can flip a guard, so there is no combined event/tick fixed point to iterate.

The boundary macro-sequence, in its final form. Boundary zero, the
initialization boundary, is the same sequence with an empty integrate ([§14.5][s14-5]).

> integrate → project → **[sweep → guards → handlers]** iterated to quiescence
> (under the [firing budget](#g-firing-budget)) → all due `state_update` calls → logging / I/O staging.

The sequence decides the mixed case, where a [continuous component](#g-continuous-component)'s handler and
its discrete observers' ticks land on one boundary. Take an engine's `starting →
running` transition under a 50 Hz FCS. The transition fires in the iteration
segment. The re-sweep re-runs the FCS's stages against `running`-mode ports, and
its `state_update` then runs from post-transition values.

### 10.7 Real-time pacing

**[Pacing](#g-pacing) is outside the semantics.** That is the section's
invariant. The pacer inserts waits between completed [frames](#g-frame). It
never reorders, skips or alters the [boundary](#g-boundary) sequence. A paced
and an unpaced run with identical input [traces](#g-trace) produce
bit-identical trajectories, so deterministic [replay](#g-replay)
([§2.2][s2-2]) extends over pace. Interactive runs differ only because their
*inputs* differ. Detection policy is inside the semantics. Event localization
runs identically paced or unpaced, and its [sweep](#g-sweep) cost is absorbed
as debt like any other expensive frame ([§10.4][s10-4]). Degrading to boundary
detection under pacing was rejected ([D-080][d-080]).

**The wall-clock map is piecewise affine, re-anchored at every knee.** The map
is $\tau(t) = \tau_{\mathrm{anchor}} + (t - t_{\mathrm{anchor}})/p$, with the
anchor pair as its reference point. A live pace change re-establishes the
anchor at the current `(t, τ)`, so the new slope applies only forward
([D-021][d-021]). Un-pause re-anchors for the same reason. Debt is cleared at
re-anchor. A deliberate user action is a natural sync point, and the counters
record what was forgiven.

**Deadline law: an absolute schedule with bounded [debt](#g-pacing)**
([D-021][d-021]). Frame deadlines come from the map. A frame that exceeds its
wall budget `h/p` leaves debt, and subsequent frames repay it by running short
or without waiting. The long-run rate is therefore exact, and ms-scale hiccups
from GC or the scheduler are invisible. Debt beyond a threshold of **five
frames' worth of budget, `5·h/p`**, is forgiven by re-anchor plus a warning,
so long stalls (a debugger, laptop sleep) do not trigger catch-up bursts. Five
frames' worth sits comfortably above the ms-scale hiccups that debt exists to
absorb silently, and far below the seconds-to-minutes stalls that forgiveness
exists for. Neither case lands near the threshold.

**`p = ∞` is pacer-off, not a limit value** ([D-021][d-021]). Unpaced mode is
the explicit *absence* of deadlines. There are no waits, no debt and no
warnings. By the invariant, it is the same execution with the waits deleted.

**The wait mechanism is a hybrid sleep-then-spin with one knob.** Non-realtime
OSes guarantee only a lower bound on sleep. The thread becomes runnable no
earlier than requested, and the wake-up is best-effort, subject to timer
granularity, scheduler load and macOS timer coalescing, with no hard upper
bound. Measured on the dev machine, idle, against 2 ms requests (2026-07),
Julia `sleep` overshoots by about 1.4 ms median, and `Libc.systemsleep` by
about 0.5 ms. Behind the `sleep` figure are libuv's millisecond-granularity
timers. Sub-ms requests are accepted and rounded up. Spikes under load are
unbounded. The pacer therefore sleeps toward `deadline − margin` and spins the
remainder:

```julia
remaining = deadline - margin - τ()
remaining > 0 && sleep(remaining)   # coarse phase: cheap, lower-bound-only (runs at most once)
while τ() < deadline end            # spin phase: µs-precise, CPU cost bounded by margin
```

`margin` is a single constant calibrated to cover the primitive's granularity
*plus* typical overshoot. There is no second threshold. The resolution floor
is absorbed into the calibration, and a margin below the primitive's
granularity defeats the spin phase's purpose. **Its default is 2 ms**, the
value the measurements above imply. It covers libuv's millisecond timer
granularity and `sleep`'s median overshoot of about 1.4 ms, while anything
larger merely spends more core in the spin phase. The knob spans the whole
design space:

- **`margin = 0`, pure sleep.** Cheapest in CPU. Frame spacing is bursty, but
  the absolute schedule still delivers the exact *average* rate through debt
  repayment. The spin phase buys regularity, never rate correctness.
- **`margin = 2 ms`, the hybrid default.** Sleeps about 90% of a 20 ms budget
  and lands within µs of the deadline at a few percent of one core.
- **`margin = ∞`, pure busy-wait.** FlightCore's behavior, with maximum frame
  regularity at one pinned core. The "best attempt at real time" mode is the
  knob's endpoint, not a separate mechanism.

When the frame budget is at or below the margin (for example `h = 0.01` at
`p = 5`, a 2 ms budget), the hybrid degenerates to pure spin per frame by
construction. Rare wake-ups past the deadline are overruns, absorbed as debt.
Which primitive the coarse phase uses, task-yielding `sleep` or
thread-blocking `Libc.systemsleep`, is settled in [§12.2][s12-2]. The coarse
phase uses task-yielding `sleep`, with `margin` absorbing its overshoot.

**Diagnostics.** Overrun count, current and peak debt, forgiven-debt events
and wait statistics are published as [framework status](#g-framework-status)
(the frozen diagnostics value each snapshot carries beside the table) for GUI
and logs. Today's `SimControl` fields are the precedent.

**Forward pointers.** The wait interval is the natural staging slot for
externally injected inputs, applied at the next boundary. The staging rules
belong to [§11][s11] and [§12][s12], as does the concurrency model generally,
which [§10.3][s10-3] constrains but does not decide.

---

## 11. Runtime periphery: the data plane

This chapter covers GUI, input [devices](#g-device), network I/O and logging, and how
data crosses between them and the [§10][s10] loop:

- the architecture that replaces the shared mutable model ([§11.1][s11-1]);
- outbound [snapshot](#g-snapshot) publication ([§11.2][s11-2]);
- the inbound path:
  - [root inputs](#g-root-input), [claims](#g-claim) and the [frozen roster](#g-roster) ([§11.3][s11-3]);
  - per-device staging and the [drain](#g-drain) ([§11.4][s11-4]);
  - the input [trace](#g-trace) ([§11.5][s11-5]);
- the device authoring contract ([§11.6][s11-6]);
- the GUI write path ([§11.7][s11-7]);
- the third cross-task channel, runtime diagnostics and liveness ([§11.8][s11-8]).

The machinery that drives the loop itself follows in [§12][s12].

### 11.1 No shared mutable model: staged writes, snapshot reads

Everything in the [periphery](#g-periphery) (GUI, input [devices](#g-device),
network I/O, logging) runs on tasks the loop does not control, and every one
of them wants the data the loop is stepping. FlightCore's answer is one big
lock. `SimControl` and the live `Model` are guarded by `io_lock`, with one
task per attached interface reading or mutating the model under it (sim.jl).
That lock does enforce the [boundary](#g-boundary)-visibility rule
([§10.3][s10-3]), because it is only ever free between steps. Transplanting
it here was nevertheless rejected, on three structural costs ([D-022][d-022]).
One of the three is load-bearing for everything below. Under a lock, input
timing is scheduler-determined and unrecorded. There is then no defined input
[trace](#g-trace), and bit-identical [replay](#g-replay) ([§10.7][s10-7]) is
unachievable *in principle* for interactive runs.

The replacement has five planes. Its unit of account is the [frame](#g-frame)
(one iteration of the loop: [drain](#g-drain), integrate, boundary sequence,
publication), the grid step [§10.4][s10-4] names. A frame is what `step!`
counts, and it is the ordinal that keys the trace. "Per frame" means this
throughout the document. The kinematic *reference frames* of the aircraft
domain are a different word, and they always appear compounded: the b frame,
the ECEF frame.

1. **Staging (inbound).** Devices submit pending input writes at any
   wall-clock moment, never touching live [root inputs](#g-root-input)
   ([§11.4][s11-4]).
2. **The drain.** Exactly one point in each frame, at its top, where the loop
   takes the staged batches and applies them to the root inputs. It never
   happens at a `t*` boundary ([§10.4][s10-4]). Between drains the loop owns
   its data exclusively, and no lock is held during stepping, ever.
3. **Publication (outbound).** At the end of each boundary sequence the loop
   publishes an immutable [snapshot](#g-snapshot). Readers observe it without
   coordinating with the loop ([§11.2][s11-2]).
4. **Control.** Pause, pace and stop live on a separate few-word atomic
   surface ([§12.1][s12-1]).
5. **Task topology.** One loop, one task per rostered device except the
   calling-task device, all run-scoped.

The fifth plane carries the most machinery, and the rest of this section
spells it out.

**Device tasks are run-scoped.** `run!` spawns one task per other
[roster](#g-roster) entry after device `init!`, and [§12.4][s12-4] joins them
all at every stop ([§12.6][s12-6]). `attach!` never spawns. It registers, in
a stopped-sim state only ([§11.3][s11-3]), and the task appears at the next
`run!`.

**The calling-task device is pinned, and the loop is the movable piece.**
Calling-task affinity is a device trait, `needs_calling_task`, default
`false` ([§11.6][s11-6]). At most one device per roster holds it (the
admission checks, [§11.3][s11-3]). The shipped GUI declares it, because CImGui
ties rendering to the calling (main) task. With such a device rostered, the
loop moves to a spawned task for the duration of the run, and the
[calling task](#g-calling-task) (the task that invoked `run!`) runs that
device's loop body. It runs the body inline, inside the same [§11.6][s11-6]
wrapper that brackets any spawned device's loop body. With no such device
rostered, the loop runs on the calling task.

| | no calling-task device | calling-task device rostered |
|---|---|---|
| the calling task runs | the loop | that device's loop body, inline |
| spawned tasks | one per rostered device | the loop, plus one per other rostered device |

The loop-on-the-calling-task case is the unattended register. It is what the
synchronous rethrow ([§13.4][s13-4]) presupposes. It is also what lets
parallel unattended sweeps thread `run!` inline with no nested task fan-out.
One immutable [`Build`](#g-build) is shared across the workers
([§9.2][s9-2]), and each `Simulation` owns its own [buffers](#g-buffer).
Pre-materializing the sweep's [activations](#g-activation), its per-eltype
[executable sets](#g-executable-set) via `build(world; activations = …)`
([§9.4][s9-4]), then leaves no worker synchronizing on anything. Either way
`run!` blocks its caller until the run ends. What varies is what the calling
task spends the run doing.

**Topology is derived after initialization**, from the
[frozen roster](#g-roster) plus the outcomes of device `init!`, and never from
`run!`'s keywords. [§12.4][s12-4] carries the rule and the case that motivates
it. A calling-task holder whose `init!` failed returns the loop to the calling
task.

**Spawn-inside-`run!` is the start gate.** A task exists only once the run it
serves exists. Any first-boundary synchronization a device needs is the
counter-plus-condition predicate wait ([§12.3][s12-3]), never a `Base.Event`
latch ([D-093][d-093]).

Two rules bind the implementation:

- **Every handoff is one atomic reference operation.** Both shared structures
  reduce their mutable surface to single words, release/acquire `@atomic`
  fields. The GC is the reclamation mechanism, since an object a reader still
  holds is reachable and therefore never recycled. That dissolves the
  reclamation problem (hazard pointers, epochs, RCU grace periods) which makes
  these patterns hard in non-GC languages. Deep immutability of the exchanged
  objects is what makes this sound.
- **No user code, no unbounded work, ever, inside a framework critical
  section.** FlightCore's pathologies are all "arbitrary code under a shared
  lock". Here mappings run on device tasks, rendering runs against snapshots,
  and the loop's frame contains framework and model code only. A stalled
  device produces stale snapshots and late staging. It cannot stall the loop.
  Two exposures are residual and pre-existing, GC pauses and OS scheduling,
  and the pacer's debt absorption is the mitigation for both.

One consequence is recorded here because it collapses an API axis.
Interactive and unattended simulation stop being different execution modes.
An [unattended run](#g-unattended-run) is the same loop with empty staging and
no snapshot readers. A replayed interactive session is the same loop with
staging fed from a recording ([§11.5][s11-5], [§12.7][s12-7]).

### 11.2 Outbound: snapshot publication

Every consumer of model state (GUI panels, output [devices](#g-device), the
log) needs a picture of the model that holds still while it is read, and none
of them should have to make the loop wait to get one. Publication is the
answer. One immutable value is published per [boundary](#g-boundary), handed
out through a single atomic reference. Three things follow from it, in that
order: how a [snapshot](#g-snapshot) is built and published, how the log
retains published snapshots under a bound, and how an output device addresses
what it reads.

#### The snapshot and its publication

**Rule.** The loop builds each snapshot in private memory, then publishes it
with a single release-store to an [`@atomic latest`](#g-latest) reference. A
snapshot carries the boundary-consistent [signal table](#g-signal-table), `t`
and the framework status. Readers acquire-load that reference and then work
with an immutable, coherent world for as long as they like. The
[calling task](#g-calling-task) (the task that invoked `run!`) reads the same
value through `latest(sim)`, the inspection register ([§12.6][s12-6]).

The exchange is wait-free in both directions. A wedged reader cannot delay
publication by a nanosecond, and the loop cannot tear a reader's view.
Publication happens only after the boundary sequence completes
([§10.3][s10-3] as extended by [§10.6][s10-6]).

**Binding rule: nothing reachable from a published snapshot is ever written
again.** The table's immutable values ([§4.1][s4-1], [§7][s7]) make the
compiler enforce most of it. **Why.** The soundness of lock-free reading rests
on this rule.

**The [framework status](#g-framework-status) is a concrete frozen value, not
a window onto live bookkeeping.** It carries the pacer diagnostics
([§10.7][s10-7]), plus the per-writer diagnostic batches, the suppressed and
cumulative counters and the liveness timestamps the loop takes at frame top
([§11.8][s11-8]). **Why.** The binding rule forces that shape. A status
referencing an accumulator its writers are still filling would be a snapshot
whose contents change after publication.

**The captured table is the whole table.** It holds the declared
[ports](#g-port) and the auto-published fields, every one of them public
([§8.3][s8-3]). No presentation layer has anything to filter. Private
intermediates are not in it, because they were never [cells](#g-cell) at all
([§5.2][s5-2]). The inspection path for one is **promotion to a declared
output**. Add a line in `output_types`, and the value appears in the
snapshot, the log, the GUI and the wiring alike. Its visibility is then an
authored fact like every other.

**The captured table also includes the [root inputs](#g-root-input)**
([§15.4][s15-4]). Root inputs are source cells of the table, not state stores,
so they ride along. That is load-bearing, not incidental. The [§11.7][s11-7]
[peek](#g-peek) (showing a widget's own pending write, else the snapshot
value) falls back to the snapshot, and that fallback is what an idle live
widget displays. Read-only mirrors of claimed root inputs, such as the axis
sliders under joystick [claim](#g-claim), show the applied root-input value
from the snapshot. Root input values in the log are derived data,
recomputable from the [trace](#g-trace). That is consistent, because
snapshots are derived wholesale.

**The snapshot deliberately does *not* carry the state stores (`x`, `s`,
`m`).** There are two reasons. The state trajectory is *derived* data,
recomputable from the [trace header](#g-trace-header) plus the batches
([§11.5][s11-5]) by bit-identical [replay](#g-replay). And per-boundary
capture would systematically record derived data, the same asymmetry the
trace-default decision ([D-029][d-029]) refuses in the other direction.

"What was the private state at t = 37.2?" is answered by replaying to 37.2
and inspecting the live stores. A state field wanted in logs or GUI has the
honest remedy of being declared public, at a cost of one auto-published cell
per [sweep](#g-sweep). Post-run continuation reads the live stores directly.
Periodic full-state checkpoints, which would allow warm restart without replay
from zero, are a [guarded addition](#g-guarded-addition) shaped as an opt-in
log policy. A dev-mode flag auto-publishing all state fields is a possible
future diagnostic.

#### The log: retained snapshots under a bound

**Logging dissolves into publication.** The log is a vector of retained
snapshot references. They are the same objects, with zero extra copies. The
per-step `deepcopy` detour of the `SavingCallback` disappears. The cost is one
snapshot allocation per boundary, on the framework side of the [§7.5][s7-5]
scope, which already carved out logging. Logged snapshots are not garbage at
all, and unlogged ones die young. Preallocated snapshot buffers are rejected
([D-023][d-023]).

**Retention: the trace's kill switch, plus [decimation](#g-decimation).** The
log takes the same plain on/off switch the trace has ([§11.5][s11-5]), and
additionally a keep-every-kth retention policy, `log_every`
([Appendix B][sB]). **Why decimation is admissible here and not there.** The
derived/primary split ([D-038][d-038]) decides it. The log is recomputable
from the trace by replay, so a thinned log costs resolution in a *view*,
never in a record. Thinning the trace would destroy the only primary account
of a session ([D-029][d-029]). Decimation is a retention policy only. Every
boundary still runs, is still published to live readers, and still enters the
trace.

Decimation slows the log's growth. It does not stop it. The default
configuration is `log = true, log_every = 1` alongside `t_end = Inf`, the
honest interactive default ([Appendix B][sB]), and it grows for as long as
the session lasts. At C172X scale and 50 Hz that is gigabytes per hour, and
it ends in an out-of-memory nobody was warned about.

**Rule.** The log takes a retention bound beside its switch and its stride:
`log_max`, the maximum number of retained snapshot references, default
**65536** (2¹⁶), with `Inf` the explicit opt-out.

**The bound is a count, not a memory budget.** Snapshots are immutable object
graphs with internal sharing ([§4.1][s4-1]), and a
[field handle](#g-field-handle) (an immutable query object consumers evaluate
at their own arguments, [§4.4][s4-4]) rides as a reference to
build-time-frozen data ([§7.5][s7-5]). Byte accounting over them is therefore
fuzzy and platform-dependent. A count is exact, and it converts to memory
through one number the user can measure once, `Base.summarysize` of a single
snapshot.

**The default is finite unconditionally**, not a modal rule keyed on `t_end`.
A finite run shorter than the bound never notices the bound, and one number
is easier to hold than two regimes. At 50 Hz and full density, 2¹⁶ boundaries
is about 22 minutes before anything is dropped at all.

**When the log fills, the retention stride doubles, so coverage stays
global.** A rolling window, with the recent past at full density and the
start of the session forgotten, was rejected ([D-137][d-137]). Instead the log
**re-decimates progressively**. After *k* generations the effective stride is
`log_every · 2^k`. The whole run stays plottable, and what coarsens is
density, never extent.

**Why.** That is the division of labor ([D-038][d-038]) carried through. The
log's chief consumer is the post-run plot of a session *as a whole*, and
nobody plots hours at 50 Hz. Full density over any *segment* of interest is
what replay from the trace recovers ([§11.5][s11-5], [§12.7][s12-7]).

**The guarantees are normative, not the mechanism.** There are three. The
bound is respected continuously, and the retained count never exceeds
`log_max`. Coverage is global at the effective stride. The endpoints below
are kept.

The mechanism sketch is non-binding. The thinning is **amortized**. When the
log fills, the stride doubles immediately, and each subsequent retained
append also releases one predecessor of the previous generation. A cursor
over the odd indices does this in O(1) amortized, with physical compaction
once per generation. A generation's thinning therefore completes exactly when
its refill does.

> fill at stride `log_every` → **full** → stride doubles → thin one predecessor
> per retained append, while refilling → **full** at stride `log_every · 2` → ⋯
> → generation *k* at `log_every · 2^k`

Amortizing rather than halving in one shot is a responsiveness choice
([D-137][d-137]). The amortized form drops exactly one old snapshot per
retained append, the same steady trickle a rolling window would produce, so
keeping coverage global costs nothing extra in GC pressure. The loop's own
work is pointer bookkeeping, microseconds either way and on the framework
side of the scope ([§7.5][s7-5]). Publication stays wait-free and readers
never block. A reader holding a released snapshot simply keeps it alive.

**The endpoints are retained unconditionally.** The boundary-zero snapshot
([§14.5][s14-5]) and the terminal snapshot ([§12.4][s12-4], [§13.5][s13-5])
survive any `log_every` and any `log_max`, and they do not count against the
bound. They are two extra references. The terminal snapshot's status carries
the run's final cumulative diagnostic counters ([§11.8][s11-8]). A run's two
endpoints and its diagnostic account, complete to the final frame top
([D-201][d-201]), therefore always outlive whatever retention did to the
middle.

Two compositions are worth stating once. The `totals` monotonicity across
logged snapshots ([§11.8][s11-8]) is untouched. Re-decimation, like
decimation, loses *which* boundary within a stretch an occurrence fell on,
never *how many*. And `log_max` is a **view policy, not a
trajectory-determining one**. Like `log` and `log_every` it stays out of the
trace header's deployment block, and replay neither records nor compares it
([§11.5][s11-5], [§12.7][s12-7]). Sizing follows. The `sizehint!` for the
expected duration ([§7.5][s7-5]) is now naturally capped by `log_max`, which
is also what defines the hint when `t_end = Inf`.

#### Output-device bindings

**Output-device bindings are snapshot bindings.** An output device
(telemetry, the XPlane visualizer, disk streaming) consumes snapshots via
[§12.3][s12-3]. It addresses what it reads with the
[selectors](#g-selector) (the closed family of deferred reads resolving
against a source, [§14.4][s14-4]), which reach any cell, since the diagnostic
register admits deep paths. A binding is resolved at attach against the
`Build` with [did-you-mean](#g-did-you-mean) (the offending name plus the
list-in-hand it should have matched), and compiled to one gather, the output
half of the binding interface ([§11.6][s11-6]). `map_output` therefore
receives a labeled NamedTuple, keyed by the names `reads` declared
([§11.6][s11-6]), instead of performing its own path lookups. That discharges
the obligation stated in [§15.4][s15-4]. A substitution that breaks a binding
fails at attach, not with silent garbage UDP.

This is **diagnostic observation** ([§13.5][s13-5]). It is human-facing, with
no effect on run semantics. It is the same register as the log retaining the
full table and the GUI's deep-reading panels. Every cell is reachable, because
the table is public throughout ([§8.3][s8-3]), and an intermediate a device
wants to stream is one promoted to a declared output.

**A binding chooses its register.** A deep path is the *inspection* register.
It makes zero promises, gives free access, and is right for looking at *this*
build. An exported output [face](#g-face), spelled `get_face(name)`
([§14.4][s14-4]), is the *integration* register. It is named, curated and
meaning-stable under substitution, and right for consumers that outlive the
build they were configured against. What makes a face meaning-stable is
writer-independent semantics ([§15.4][s15-4]).

**Why the choice matters.** Attach validation converts *structural* drift to
loud errors in both registers. Only faces protect against *semantic* drift,
where a substituted aircraft publishes the same path at the same type with a
different meaning, such as a CG velocity under a name read as body-origin
velocity. Nothing else can, because meaning is not in the schema.

Semantically generic consumers should therefore bind faces. A visualizer
needs pose, and every aircraft has one. Aircraft families should export the
conventional surface such consumers need, a library/migration deliverable
([§16][s16]). Wrapper types make face semantics structurally checkable, as in
`VelocityData` with its `v_eb_b` defined *at the type* as body-origin
velocity. A bare vector does not wire, and wrapping the wrong quantity is a
deliberate lie, not a drift.

### 11.3 Inbound: root inputs, claims and the frozen roster

**The [write surface](#g-write-surface) (the set of faces a writer's batch
entries may reach) is [root inputs](#g-root-input).** A root input *is* the
root [component](#g-component)'s own input [face](#g-face), an assembly's
`input_connections` key or a primitive's `input_types` key ([§8.2][s8-2],
[§8.6][s8-6]). It is routed inward to consumers and produced by no component.
At every non-root level an input face is fed by the parent's wire, and at the
root there is no parent. No dedicated vocabulary is needed.

A root input is usefully read as the output face of the one producer the
build never sees: the [periphery](#g-periphery) and the services. On that
reading, root-input exclusivity (below) is that producer's one-writer right,
and the totality ([§14.6][s14-6]) is its completeness obligation.

Root inputs are sources to the build-time scheduler, constants within a
frame, and the *only* thing the periphery may write. The GUI reaches them
through the resolution ([§11.7][s11-7]), and control commands are not writes
([§12.1][s12-1]). [Devices](#g-device), mappings, the [trace](#g-trace) and
the GUI write path address root inputs by **face name** ([§8.6][s8-6]).
Structural slash paths never cross the periphery's *write* boundary. The
write side speaks the root [contract](#g-contract)'s names only. The read
side chooses per binding. It uses slash paths in the inspection register, and
face names in the integration register and in load-bearing service reads
([§11.2][s11-2]/[§13.5][s13-5]/[§14.4][s14-4]).

**Root-input exclusivity: one writer per root input at any time**
([§15.4][s15-4]). A device [claims](#g-claim) its root inputs at attach, and
claiming an already-claimed root input is an attach-time error. Detaching
releases the claims. A released root input's GUI widgets are live again from
the next run ([§11.7][s11-7]). Exclusivity replaces any cross-device conflict
*policy*, such as attachment-order precedence at [drain](#g-drain)
([D-044][d-044]). Per-device [cells](#g-staging-cell), the CAS merge and the
atomicswap drain all stay. They serve atomicity and
[coalescing](#g-coalescing), not arbitration.

**A claim is what a device *may* write, not what it will.** Data-dependent
write-sets are ordinary. A UDP/JSON peer writes whichever subset of faces the
incoming message names, and `map_input` is arbitrary user code the framework
never inspects. Such a device therefore claims the **binding's enumerated
allowed set**, the faces the binding table lists, whether or not any given
batch touches them. The claim is registered at attach exactly as a joystick's
is. A broad claim costs liveness. Every enumerated face is claimed for the
device's whole attachment, so the derived-liveness rule ([§11.7][s11-7])
renders the device's GUI widget read-only even on faces the peer never
writes. Narrow the binding to narrow the claim. The enumeration *is* the
interface.

**Every writer has a write surface, and the periphery enforces it.** A batch
entry reaches a root input **iff the named face is inside the writer's
surface**. Anything else is discarded with a runtime warning
([§13.2][s13-2]). Because surfaces are static per run (the
[roster](#g-roster) freeze, below), enforcement runs entirely at *staging*,
the earliest site, on the writer's own task. The drain performs no checks at
all. **Every device's surface is its claim set**, and a claim set has two
*sources*:

- **Returned.** The binding enumerates the faces. It declares
  `is_input(b) = true`, `claims(b)` ([§11.6][s11-6]) is called once at
  attach, and what it names is staked. Such a claim is static for the
  attachment and exclusively its own, since claims are disjoint by
  construction. It is binding-bounded even where no one else is involved. A
  mapping that has drifted onto an unenumerated face is a diagnosable anomaly
  (`OutOfClaimEntry`), never a silent write, claimed or not.
- **Computed.** The binding declares `is_greedy(b) = true` ([§11.6][s11-6])
  and the framework computes the claim at attach: all root-input faces minus
  the union of the rostered claims, the unclaimed complement at that instant.
  This is the shipped GUI's claim ([§11.7][s11-7]), everything unclaimed,
  without configuration. It is disjoint from every incumbent claim by
  construction, so exclusivity validates trivially and nothing downstream can
  tell the two sources apart.

One claim mechanism, two claim sources. The source is exhausted at the attach
point. Past it, validation, roster-entry storage, shape compilation
([§11.4][s11-4]), the drain, the trace and detach-releases-claims treat a
computed claim exactly as a returned one. The GUI is therefore not an
exception but an ordinary enumerated writer whose enumeration the framework
performed. Attaching the greedy claimant last is the idiom. Its computed
claim is taken at the attach point and never recomputed, so attachment order
is load-bearing by design. Opportunistic writing by autonomous devices does
not exist. A device that wants a face enumerates it, and greediness is an
explicit declaration, never a default. Cross-writer races on one root input
therefore cannot arise structurally, because every claim is exclusive,
whatever its source. That is what keeps drain order a diagnostic fact (below)
and lets a drained GUI value simply stay ([§11.7][s11-7]).

**One framework-owned remainder: the
[harness register](#g-harness-register).** Beside the roster sits a
**task-free entry point**, `stage!(sim, "face" => value, …)`, the harness/REPL
write path ([§12.6][s12-6]). It stages a batch from the
[calling task](#g-calling-task) itself (the task that invoked `run!`). Its
always-present cell is drained, traced and surface-checked exactly as any
device's. The register's surface is the one thing in the design that is
*derived* rather than claimed. It is the unclaimed complement, the faces no
rostered device speaks for. That surface is recomputed at every stopped-sim
roster change, and is therefore as fixed within a run as any claim set. A
`stage!` write to a claimed face is rejected at staging
(`ClaimedFaceEntry`, naming the incumbent). A rostered greedy claimant
empties that surface outright. The greedy claim is itself a rostered claim,
so the complement it leaves is empty and every `stage!` in such a session is
rejected that way ([D-192][d-192]). There is one seam, a batch staged while
stopped whose face a subsequent `attach!` claims, and the attach itself
renormalizes it away (below). The [harness cell](#g-harness-cell) (the
always-present staging cell of the harness register) drains **last**, by
convention. With every surface disjoint the order is unobservable, so the
rule exists to make the trace read the same way every time, not to arbitrate
anything.

**Root-input initial values are owned by the init/trim services**
([§15.4][s15-4]). Input declarations are bare types ([§8.2][s8-2]) and carry
no defaults, yet a root input unfed by any device must hold a defined value
from the first frame. Today's `U()` constructors provide these
(`mixture = 0.5`). Export-entry defaults were rejected ([D-047][d-047]).
`init!` establishes every root input, and the
[trace header](#g-trace-header) captures the result. Totality is enforced
pre-write at every complete-world application: `init!`, trim setup, trim
commit ([§14.6][s14-6]).

**The roster is frozen per run: attach and detach are stopped-sim
operations.** `attach!`/`detach!` are legal in the `built`, `initialized`
and `stopped` states ([§12.6][s12-6]) and an error while `running`. That
error is `ServiceLifecycle` ([Appendix C][sC]), the same kind that gates the
[§14][s14] services. The list is exhaustive. An `errored` simulation refuses
both with the same kind. A roster change configures the next run, and an
errored simulation has none ([§13.6][s13-6], [D-232][d-232]). The prohibition
includes pause. Pause is a control-plane state *inside* a run
([§12.1][s12-1]), and a surface that could move while paused would move
mid-run. The roster (entries, claims, attachment order) is therefore a plain
immutable value the loop reads once at `run!`. The partition of the root face
set into per-writer surfaces plus the harness remainder is a static,
inspectable fact of the run. It is printable before the run starts and valid
until it ends (the provenance register, [§13.7][s13-7]). No republication
machinery exists. There is no atomic roster reference, no per-frame
acquire-load, no next-frame attachment granularity and no sequence numbers.
Attachment order is the roster's own order. The trace still tags entries
with a stable device id, never a roster index, because ids read across runs,
where the roster does change. Attach validation, claim registration and the
staging-shape compilation (below) all run at the attach point, which makes
`attach!`/`detach!` stopped-sim configuration operations beside `init!` and
trim ([§14][s14]). While a simulation runs, its configuration (build, roster,
claims, surfaces) is immutable. The doctrine ([§12.5][s12-5]) extends to its
final form. The running periphery stages writes and issues control commands,
*and nothing else changes*.

**Device identity, ids and roster admission.** Identity is the device
instance. The same object (`===`) may occupy at most one roster entry. Two
instances of the same type, two joysticks say, are two devices. The stable
device id the trace, heartbeat and diagnostics speak is assigned at
`attach!`, monotonic per `Simulation` and never reused. It lives exactly as
long as the entry: across runs (roster persistence, [§12.6][s12-6]), until
`detach!`.

Admission is a three-part check at the attach point, in order:

```
# each line: the condition that rejects the attach → the diagnostic it raises
identity   this instance is already rostered
               → AlreadyAttached      (names the entry and its binding)
affinity   this device declares needs_calling_task, and a rostered
           device already declares it
               → CallerTaskConflict   (names both devices)
claims     face exclusivity: this device's claim set meets a rostered claim
               → ClaimConflict        (names two distinct devices)
```

An already-rostered instance is rejected rather than silently absorbed,
because rebinding has an explicit spelling: `detach!` then `attach!`, both
legal at any stopped-sim point. Either a silent no-op or a silent rebind
would discard a binding the caller handed over. The affinity check admits at
most one rostered device declaring `needs_calling_task`, because the topology
([§11.1][s11-1]) makes the calling task a single-slot resource. Running the
claims check after the identity check is what makes `ClaimConflict` always
name two *distinct* devices, never a device colliding with its own earlier
attachment.

**Device death does not detach.** A mid-run crash, voluntary exit or unplug
([§11.6][s11-6], [§12.4][s12-4]) ends the device's *task*. The cell stops
filling, the [§12.2][s12-2] heartbeat shows the death by name, and the roster
entry, claims included, persists to the end of the run. The
[orphaned claims](#g-orphaned-claims) are the accepted cost of
[the freeze](#g-the-freeze). The device's root inputs hold their
last-drained values and no other writer inherits them. The read-only widgets
([§11.7][s11-7]) render the orphan visibly ("claimed by `T16000M` — task
dead"), never mysteriously. Recovery is between runs: stop, `detach!`, and
either `init!` (fresh trajectory) or `replay!`-to-end then `run!`
(continuation from the interrupted boundary, [§12.7][s12-7]). The death is an
anomaly, not a surface event.

One deliberate asymmetry is on record as a
**[guarded addition](#g-guarded-addition)** (a capability the design admits
but does not build). A pure reader claims nothing. Examples are a binding
declaring `is_output` alone ([§11.6][s11-6]), a visualizer or a telemetry
tap. Attaching one mid-run would therefore move no writer's surface. A
dynamic reader list would touch only [§12.3][s12-3] wakeups, the heartbeat
and the shutdown join, never the drain, and it is cleanly severable from the
freeze should the join-a-running-session workflow find a customer. The
[§12.2][s12-2] thread-budget warning runs once per `run!`, against the frozen
population.

### 11.4 Inbound: per-device staging, representation and the drain

A device produces writes on its own task, whenever its hardware or its peer
hands it a datum. The loop consumes them at frame top. Between those two
rates something has to hold each device's pending writes and hand the loop a
value it can apply. That something is the staging cell. This section fixes
the policy under which a device writes into its cell, the shape the cell
holds, and the [drain](#g-drain) (the frame-top swap that publishes staged
device writes into the root inputs) that empties it.

**Rule.** Staging keeps one atomic [cell](#g-staging-cell) per attached
[device](#g-device) under one [coalescing](#g-coalescing) policy: CAS merge,
newest wins per [face](#g-face). Each cell has a single writer, its own device
task, and holds that device's latest pending [batch](#g-batch) of
[root input](#g-root-input) writes. Staging merges the incoming batch into the
pending one. Untouched faces survive, and re-staged faces take the newest
level. That is the per-face ZOH. The CAS can fail only because a drain
intercepted the old batch, so the retry is bounded. The failure case is
precisely correct as well. Intercepted writes are already applied, and must
not be re-staged.

**Why.** Merge is the *only* policy because it is always correct. A
**complete** writer covers every face in every batch it stages. A joystick
delivering its full write-set every poll is the type case. For such a writer
merge and overwrite are provably the same operation, which makes overwrite a
degenerate fast path rather than a second semantics. A **sparse** writer
stages only what was touched. The GUI and a JSON peer are sparse writers, and
under overwrite they lose writes silently instead. [§15.3][s15-3] works that
hazard through: a pending `flaps` edit clobbered by an unrelated `gear`
message, undrained and undiagnosable. A user-facing overwrite opt-in
(`complete(binding)`) is closed ([D-104][d-104]).

**Rule.** The staged representation is fixed per attachment, compiled at
attach. An enumerated writer's [claim](#g-claim) set and root-input types are
both known at attach, since `claims(binding)` ([§11.6][s11-6]) is read
against the root [contract](#g-contract). So the framework fixes the cell's
content type there. It is a pair of positional tuples over the claim set: a
values tuple, concretely typed `Tuple{T₁, …, Tₙ}`, and a parallel `Bool`
touched-mask. A set mask position means *staged this time*. A clear one
means *not touched*, never "reset". Untouched positions carry placeholder
values and are never read. The mask guards every consumer, so no placeholder
ever reaches the model. The batch is therefore isbits with one concrete
layout per writer. The levels doctrine is untouched, and root inputs only
ever receive masked positions. The face-name → position schema lives in the
[roster](#g-roster) entry.

In sketch form:

```julia
# claim set enumerated f₁ … fₙ; Tᵢ = declared type of the root input behind fᵢ

# attach fixes the cell's content type — values and mask, both concrete:
values :: Tuple{T₁, …, Tₙ};  mask :: NTuple{n, Bool}

# stage!, on the device task: the shim turns the author's face ⇒ value pairs
# into `incoming` — name → position, convert to Tᵢ, set the mask

# staging merges into the pending batch, newest wins per face:
merged.values[i] = incoming.mask[i] ? incoming.values[i] : pending.values[i]
merged.mask[i]   = incoming.mask[i] | pending.mask[i]

# the drain scatters, unmasked positions skipped:
batch.mask[i] && (the root input at position i receives batch.values[i])
```

**Why.** One concrete layout is what makes the frame-top drain compilable.
The alternative carrier, `Union{Nothing, Tᵢ}` per face with the marker riding
in the value, has no such layout. Tuple types are covariant, so each
combination of touched faces is its own concrete type, and applying a batch
would specialize at frame top on which faces it touched ([D-202][d-202]). The
mask buys the layout back at the price of dead placeholders. Those are filled
from the declaration's [probe](#g-probe) values, which are constructible for
every declared type and unreachable behind the mask guard.

The consequences are each mechanical. The merge is positional and
mask-driven (the sketch above), so it compiles straight-line, leans on no
small-tuple heuristic, and does not degrade with surface width
([D-202][d-202]). The drain applies each cell through an attach-compiled
**scatter**: position → root-input cell, statically typed, masked-off
positions skipped. That scatter is the exact mirror of the compiled output
gather ([§11.2][s11-2]).

Authors never build the shape by hand. `map_input` returns face ⇒ value pairs
for whatever the datum touched, and `stage!` normalizes those pairs through
an attach-compiled shim. The shim does three things. It maps name to
position, converts to the root input's declared type, and sets the mask. It
thereby confines the residual name-shaped dynamism to one framework-owned
conversion on the device task, at the boundary where wire-shaped data becomes
system-shaped data. Author-built total tuples are rejected as a padding form,
the same disease [D-074][d-074] and the handler return law refuse
([D-104][d-104]).

**A greedy entry needs no special treatment here.** Its claim was computed at
the attach point, and by the time shapes are compiled it is an ordinary claim
set ([§11.3][s11-3]). The GUI's cell is compiled exactly as a joystick's.

**The [harness cell](#g-harness-cell) (the always-present staging cell of the
harness register) gets the same treatment.** Under the roster freeze its
derived surface, the unclaimed complement, is as static as any claim set, so
it too is compiled to a positional shape. That shape is recompiled at each
`attach!`/`detach!`, both stopped-sim points, and it carries the same shim,
merge and scatter. Being always present, the harness cell gets the
compilation unasked. It is also the one cell whose shape the framework
derives rather than receives.

One representation, one mechanism. The name-keyed dynamic path the mutable
surface used to force does not exist, and no face name is ever resolved
inside the loop's frame.

The recompilation has one seam. A pending harness batch staged *before* a
stopped-sim `attach!` may hold the old shape, or may name a face the new
claim covers. The attach renormalizes that batch. It is reshaped, and
newly-claimed faces are discarded with `ClaimedFaceEntry`. So the run always
starts with cells matching the run's schemas.

**Rule.** Diagnostic sites follow the compilation, all of them to staging.
Face-name validity, surface membership and value convertibility are all
static facts of the run. Every check therefore runs in `stage!`'s
normalization, on the writer's own task. A device's out-of-claim face has no
position in the schema and is rejected with `OutOfClaimEntry`. Staging is an
earlier, better-attributed site than the drain for that rejection, and the
kind and [payload](#g-payload) are the same either way. The GUI is included,
its claim being an ordinary one. A **harness** write to a claimed face is
rejected the same way, with `ClaimedFaceEntry` naming the incumbent device.
And a value that cannot convert to its root input's declared type is
discarded with `EntryTypeMismatch` ([Appendix C][sC]), at the same spot.

Nothing remains at the drain. With surfaces frozen for the run, there is no
fact only the drain can know, and the drain is pure application.

**Doctrine: staged values are levels, never deltas** (`press_count = 17`,
never `presses += 1`). Levels are idempotent and survive coalescing. Button
edges ride as monotonic counters.

**Rule.** At frame top the drain takes each device's cell with one
`atomicswap(cell, nothing)`. The swap is an indivisible take, so there is no
lost-write window. Each taken cell is then applied through its compiled
scatter, **in attachment order**. Attachment order is retained as a
deterministic application order. Under root-input exclusivity, cross-device
writes to one root input cannot arise, so the order matters only for
diagnostics.

Which *frame* a write lands in remains wall-clock reality. What the drain
guarantees is that the frame's outcome is a pure function of the drained
batches.

Because the roster is a fixed value at `run!`, the drain is fully compilable.
The cells and their scatters form a heterogeneous but *known* tuple the frame
function can specialize on, which means zero dynamic dispatch at frame top.
That is the same per-configuration compile trade the [executor](#g-executor)
([§9.7][s9-7]) already makes, now incurred only at stopped-sim attach points.
The specialization is an implementation freedom
[the freeze](#g-the-freeze) creates, not an obligation. Iterating a roster
array costs a handful of dispatches per frame and remains acceptable.

Two shapes were rejected, both torture-tested in [§15.3][s15-3]: per-input
atomic cells, and a shared lock-free [batch](#g-batch) stack ([D-024][d-024]).

**Mappings run on the device task.** Today's
`assign_input!(mdl, mapping, data)` becomes the pure
`map_input(data, mapping) → batch`. User-extensible code thereby never
executes inside the loop's frame, and the trace consists of root-input-level
batches.

**Mappings are binding data, not shaping code** ([§15.4][s15-4]). A mapping
is a declarative table: axis/button → root input, plus per-axis conditioning
parameters (deadzone, expo strength). The shipped `TableBinding` applies
those parameters in its generic `map_input`, on the device task. That is the
shared pure helper, with an owner ([§11.6][s11-6]).

The boundary is set by the face contract: **a face's meaning is
writer-independent**. Faces therefore carry *post-conditioning* semantics. A
GUI slider or a script writes the same command a curved stick delivers, and
running a mouse drag through a deadzone would be absurd. This GUI-parity test
is what places conditioning upstream.

Aircraft-semantic derivation must *not* ride along. The C172X
`q_ref = q_sf · axis` fan-out is the case in point. It is FCS design and
lives in-model, in the avionics. Alternatively it is accepted as a small
per-aircraft×device mapping entry, an aircraft-design fork ([§15.4][s15-4]).

The trace records post-conditioning levels. Those are exactly what the model
consumed, so [replay](#g-replay) is exact. Raw-stick provenance, re-running a
session through *different* curves, is the known, accepted loss. Edge logic
follows the levels doctrine. Devices stage monotonic press counters.
Accumulators (trim offsets, flap detents) are model state, not mapping state
([§15.4][s15-4]).

### 11.5 Inbound: the input trace

**The input [trace](#g-trace)** is the sequence of drained,
[device](#g-device)-tagged batches per frame. It extends the determinism
([§10.7][s10-7]) end-to-end. Replaying a recorded interactive session
reproduces the trajectory bit-identically, with staging fed from the
recording and no devices or mappings present.

**One record format: every batch is retained sparse.** At the
[drain](#g-drain) (the frame-top swap that publishes staged device writes
into the root inputs) each drained [cell](#g-staging-cell) is scanned. Its
masked (touched) entries are recorded as (position ⇒ value) pairs, against
the writer's [face](#g-face)-name → position schema in the header (below).
That is an O(surface-width) scan and one small allocation per drained batch.

**Why.** The rule is uniform because a [claim](#g-claim)'s *width* is a fact
about one binding, not about a class of writers. A
[greedy claim](#g-greedy-claim) is enumerated and as wide as the root
[contract](#g-contract) ([§11.3][s11-3]), so keying retention by claim source
is rejected ([D-176][d-176]). Every consumer then handles one format instead
of two. There is one record format at the trace's edge, no per-entry format
flag, one decoder in the [what-if register](#g-what-if-register) (replay with
edited inputs), in disk serialization and in human inspection, and one
inverse conversion in [replay](#g-replay). That work is paid once, up front,
off the loop ([§12.7][s12-7]). The conversion site is the drain and not the
staging shim, because the drained tuple is the *coalesced* truth. A shim-side
sparse log would need its own merge.

**The costs are recorded rather than argued away.** On the wide writers the
conversion is what keeps the trace honest. A tuple as wide as the unclaimed
surface carrying one edit would otherwise make trace size track surface
width rather than information. At hundreds of faces, render-rate dragging
would inflate the trace past the two-orders-below-the-log budget that
justifies trace-on-by-default ([D-029][d-029]). On the dense
[component](#g-component) the conversion costs **about 2×**, a position
beside every value where the positional tuple carried the value alone. That
changes no order of magnitude, and it leaves the budget ([D-029][d-029])
standing for every writer at once. The allocation is in-class with what the
retention carve-out ([§7.5][s7-5]) already admits. Per [boundary](#g-boundary)
it is smaller than the log's [snapshot](#g-snapshot), the carve-out's standing
occupant and the one qualified exception to retains-what-was-already-allocated.
And the decision is **reversible as pure implementation**. The conversion is
lossless in both directions, so verbatim retention could return as a
per-entry storage optimization if a marathon-session measurement ever asks
for it. Such a return would leave the record semantics, the header and the
replay path exactly as they are.

**The [trace header](#g-trace-header) captures the full initial state**
`(x, s, m)` **plus the initial [root-input](#g-root-input) values** at
`init!`. The capture happens **after `apply!` and the root-input writes,
before the boundary-zero sequence runs** ([§14.5][s14-5]). Both halves of
that placement are load-bearing:

- The header holds the *resolved* stores and root inputs as values, never
  the sparse authored overlay. Replay must survive edits to declared
  defaults, the primary-data doctrine ([D-038][d-038]).
- The header never holds the post-transition result, since
  [boundary zero](#g-boundary-zero) is re-executed under replay
  ([§12.7][s12-7]). A post-sequence capture would re-fire authored-condition
  events on top of already-latched state.

An unfed `mixture = 0.5` never appears in any batch, so replay is broken
without the root inputs. The init/trim services own root-input
initialization ([§14.6][s14-6]), and the header capture extends naturally.
The header carries two further things:

- **Each writer's face-name → position schema.** Positional records are
  meaningless without it, and replay does not reconstruct claims
  ([§12.7][s12-7]). The schema list only grows ([D-217][d-217]). The header
  outlives a run, and a roster change between advances ([§12.6][s12-6])
  recompiles the harness writer, so the same face moves position. Every
  capture and every roster change appends the current writer set, earlier
  records keep their index, and a record resolves only through its own
  schema entry.
- **The run's deployment block.** It holds `t₀`, `Δt_base`, `h`, `N_base`,
  the algorithm identifier, `localization_tol`, `localization_budget`
  ([§10.4][s10-4]), `firing_budget` ([§10.6][s10-6]) and the `t_end`/`stop_on`
  pair bound at construction, captured at the same instant as the stores. A
  `run!` override post-dates the capture ([§13.5][s13-5]). The header records
  what `init!` knows ([D-217][d-217]).

The trajectory depends on the deployment block exactly as it depends on the
stores. The deployment binding ([§9.1][s9-1]) sits outside the `Build`, and
`t₀` post-dates even deployment ([§14.5][s14-5]). A header without them could
therefore not back the bit-identity claim ([§12.7][s12-7]). This block is
also what the artifact's **run metadata** names ([§13.5][s13-5],
[Appendix B][sB]). The header capture is the one full-state capture in a
normal run, and the other half of what "given the initial state and the
trace, the log is recomputable" requires. Header plus batches are the
*primary* record. Everything else, the state trajectory included, is derived
([§11.2][s11-2]). The trace also carries its length, the number of drains
since the capture ([D-217][d-217]). A recording whose last frames drained
nothing still ran them, and every advance in `:replay` is capped at that
count ([§12.7][s12-7], [D-218][d-218]).

**Trace recording is on by default.** The trace is cleared at `init!` and
retrievable after the run, and a plain kill switch covers
memory-constrained marathon sessions. The asymmetry that decides the default
is that the trace is *primary* data and the log *derived*. Given the initial
state and the trace, the log is recomputable, which is what bit-identical
replay means. An untraced interactive session, by contrast, is
unreproducible, permanently. The cost supports the default. The trace
retains one small sparse record per drained batch (above), at drain-rate ×
device-count. That is tens of MB per hour worst case, two orders of magnitude
below the snapshot log. There is no sampling and no rolling window
([D-029][d-029]).

### 11.6 Devices: one authoring contract, no taxonomy

FlightCore's input/output/GUI trichotomy is lock choreography, not modeling.
With no lock, the protocol the taxonomy encoded has no referent
([D-025][d-025]).

#### Every attached device receives the same handle

The handle carries the two primitive capabilities, read and stage, plus
control access (observe running, request shutdown). Read returns the latest
[snapshot](#g-snapshot), optionally waiting for the next
[boundary](#g-boundary) ([§12.3][s12-3]).

**[`should_abort`](#g-should_abort) is an `attach!` keyword**, defaulting to
`false`. It is per-attachment, never a device property. The same joystick is
advisory in one deployment and load-bearing in another. With it clear, a
device's departure is reported and the run continues without it. With it
set, that departure also requests a sim stop ([§12.4][s12-4]). A departure
is the loop body returning, a crash, or a failed `init!`. The shipped GUI
attaches with `should_abort = true`, since closing the window is the
interactive session's natural end, and `gui = true`'s run-scoped attachment
states that value ([§12.6][s12-6], [Appendix B][sB]).

Input-only and output-only devices are degenerate uses, not framework
classes. A bidirectional network peer is *one* device with one socket and
one lifecycle, not two framework devices sharing state. The GUI is an
ordinary device, the paradigm one, and it uses every capability. It has
exactly two genuine peculiarities, neither taxonomic: main-thread affinity
(a launch concern) and read-modify-write widgets ([§11.7][s11-7]).

#### The authoring contract: four functions, one optional, one trait

A [device](#g-device) is a user type subtyping the framework's neutral root:
`MyDevice <: AbstractDevice`. That is one mandatory word, and it costs
nothing, because the [periphery](#g-periphery) has no competing hierarchy to
inherit from. What it buys is `attach!`'s dispatch gate below. The framework
asks for

```julia
init!(dev)          # per-run resource acquisition — calling task, before spawn (§12.4)
loop(dev, handle)   # the task body: owns its own wait structure
shutdown!(dev)      # per-run resource release — guaranteed on every exit path
unblock!(dev)       # optional hook, default no-op: make a blocked loop return (§12.4)
needs_calling_task(dev)   # optional trait, default false: run the loop body on the
                          # calling task (§11.1's topology; the shipped GUI's CImGui
                          # constraint). At most one holder per roster (§11.3).
```

The framework owns everything around them. The wrapper is the shutdown
protocol ([§12.4][s12-4]) made structural:

```julia
init!(dev)                                   # its own bracket, pre-spawn (§12.4): a throw
                                             # here is shutdown! + DeviceCrash by name
task = Threads.@spawn try
    loop(dev, handle)
catch e
    report!(handle, DeviceCrash(e))          # §12.4(6): sim continues, device absent
finally
    shutdown!(dev)                           # any exit path: OS resources released
    mark_dead!(...)                          # heartbeat only — claims stay, §11.3
end
```

A `needs_calling_task` device runs the identical wrapper *inline* on the
[calling task](#g-calling-task). The invocation site, not the authoring
contract, is its only difference (the topology, [§11.1][s11-1]; the join
exclusion, [§12.4][s12-4]).

**`shutdown!` must tolerate a partially initialized device.** The release
guarantee holds on the one path *outside* this wrapper too. The
initialization step ([§12.4][s12-4]) brackets each `init!`, and a device that
threw half-way through acquisition goes straight back to `shutdown!`, so
nothing it did manage to open is leaked. The obligation that follows is
"close only what is open". That is the same defensiveness `shutdown!`
already owes the crash path, where a loop body may die at any point in its
own life. `init!` is correspondingly *not* asked to clean up after itself.
The bracket does once, for every device, what would otherwise be duplicated
in each and enforced in none.

The wrapper makes one discrimination. **An `InterruptException` is never a
`DeviceCrash`.** Under the spawned-loop topology the calling task is the one
running a device loop body inline, the GUI's ([§11.1][s11-1]). An operator
Ctrl-C therefore raises *there*, inside user code that did nothing wrong. The
wrapper forwards the control-plane stop and lets the body leave through the
ordinary `running(handle)` predicate ([§12.4][s12-4](4)). There is no crash
report for what is not a crash, and no `should_abort` consultation, since a
stop is already requested.

#### The author owns the loop body; the framework owns the bracket

One device contract means author-owned loop bodies. A framework-owned hook
loop would have to ask each device what it waits on, which is the rejected
taxonomy resurrected as a trait ([D-102][d-102]). Under the author-owned
body, every wait structure is ordinary user code composed from handle
primitives:

```julia
function loop(dev::T16000M, handle)              # timer-driven, full write-set
    while running(handle)
        sleep(dev.Δt_poll)
        stage!(handle, map_input(poll_axes(dev), binding(handle)))
    end
end

function loop(dev::UDPInput, handle)             # source-driven, data-dependent
    while running(handle)
        datum = recv(dev.socket)                 # blocks; unblock! closes the socket
        is_eot(datum) && return                  # voluntary exit
        try
            stage!(handle, map_input(datum, binding(handle)))
        catch e
            is_datum_error(dev, e) || rethrow()  # a bug → wrapper → DeviceCrash
            report!(handle, MalformedDatum(e))   # garbage → visible, bounded, alive
        end
    end
end

function loop(dev::Telemetry, handle)            # boundary-driven output
    while running(handle)
        snap = wait_next_snapshot(handle)        # §12.3; returns on stop
        send(dev.socket, map_output(gather(handle, snap), binding(handle)))
    end
end
```

A bidirectional peer composes both halves itself, with an inner reader task
inside its own domain, rather than forcing a select engine into the
framework. Two idioms are author obligations the framework can only teach
and diagnose, never force ([Appendix A][sA]): loop on `running(handle)`, and
make blocking calls interruptible (`unblock!`, or timeouts). A forgotten
predicate check surfaces as `DeviceJoinTimeout` with the device's name. A
stall surfaces as a stale heartbeat ([§12.2][s12-2]). Liveness timestamps
ride *inside* the handle primitives, which store them in the device's own
[diagnostic cell](#g-diagnostic-cell) ([§11.8][s11-8]), so the framework
observes activity without owning the loop.

**`should_close` dissolves.** A window ✕ or peer EOT is the loop body
returning. The wrapper's exit path releases the device's OS resources, marks
it dead for the heartbeat and consults `should_abort`. [Claims](#g-claim) and
the [roster](#g-roster) entry persist to run end (the freeze,
[§11.3][s11-3]). [§12.4][s12-4](6) is literally "the task body returned."
The GUI implements the same authoring contract. The framework calls its
`loop` inline on the [calling task](#g-calling-task) instead of spawning
(the pinning, [§11.1][s11-1]).

#### The binding: framework-legible by enumeration, opaque in its mappings

A binding is a value subtyping `AbstractBinding`, the second mandatory root.
Its type declares which sides it has and enumerates what each side touches.
The legible half is explicit methods returning data, called once at attach
on the [calling task](#g-calling-task) (the task that invoked `run!`). The
opaque half is called per datum on the [device](#g-device) task by the
author's own loop:

```julia
struct T16000MBinding <: AbstractBinding    # the roots are mandatory: attach! dispatches
    table::NamedTuple                       # on ::AbstractDevice, ::AbstractBinding
end

is_input(::T16000MBinding)  = true     # sides are *declared*, never inferred; the root
is_output(::T16000MBinding) = false    # carries the false defaults, so silence = absent
is_greedy(::T16000MBinding) = false    # the claim source within the input side (§11.3)

claims(b::T16000MBinding)   = ...      # input side:  the enumerated face set → the claim
map_input(datum, b)                    #              datum → face ⇒ value pairs — user code
reads(b)                               # output side: labeled §14.4 selectors → one compiled gather
map_output(nt, b)                      #              the gather's NamedTuple → wire datum
```

The root carries `is_greedy(::AbstractBinding) = false` beside the two side
defaults, so silence is not greediness. The computed claim source is
declared or absent.

The framework needs no [contract](#g-contract) on the datum's shape. The
datum travels only between `loop` and `map_input`, written by the same
author, and the framework's structural knowledge comes entirely from the
declared traits and the enumeration methods. Everything enumerable validates
at attach. Everything opaque is bounded at its runtime enforcement point.
`map_input` is bounded by the staging checks ([§11.4][s11-4]). `map_output`
receives exactly the compiled gather's NamedTuple, and what it puts on the
wire is the peer's business. `map_input`/`map_output` are, precisely,
**conventions of the author-owned loop idiom**. The framework never calls
them, so they are taught ([Appendix A][sA]) and never checked. A binding
whose loop calls something else by another name is simply a binding with a
different private helper.

**Rule.** `reads(b)` returns a labeled NamedTuple of [selectors](#g-selector)
(the closed family of deferred reads, [§14.4][s14-4]), for example
`(; alt = get_output(…), pose = get_face(…))`. The labels are the binding's
own naming, carried through compilation in declaration order, so the
NamedTuple `map_output` receives is keyed by exactly the names `reads`
declared. One returned value thereby fixes names, order and reads together,
under the same attach-time validation as `claims` ([D-199][d-199]).

**Sides are declared, and the obligations they create are enforced both
ways.** `claims` and `reads` have **error-throwing fallbacks on the root**,
so a declared side whose method was never written fails loudly at the attach
point rather than degrading into silence. The attach runs a
**bidirectional conformance check** over the pair (trait, method):

- `is_input && !is_greedy` ⇒ `claims(b)` is called once and its
  [faces](#g-face) staked. The fallback firing here means "you declared an
  input side and wrote no enumeration".
- `is_input && is_greedy` ⇒ the [claim](#g-claim) is computed
  ([§11.3][s11-3]), and a `claims` method defined for this binding is an
  error. The two sources are alternatives, not layers.
- `is_output` ⇒ `reads(b)` is called and the gather compiled.
- Neither side declared ⇒ attach-time error naming both traits. A binding
  that touches nothing is a configuration mistake, not a degenerate.
- `is_greedy` without `is_input` ⇒ error. Greediness is a *source* within a
  side, and a source without its side is meaningless.
- A **specific** method of `claims` or `reads` defined for the binding type
  while its trait reads false ⇒ error, the converse direction of the same
  fact. A method written and never reached is exactly the drift the check
  exists to catch. Detecting it is one `which` against the fallback method.
  That is the reflection class ([§8.1][s8-1]), where the shadowing check is
  an `isdefined`/`!==` pair. The `which` detection runs once at a stopped-sim
  service point, not inside any frame.

Every violation in that list reports `BindingContractMismatch`
([Appendix C][sC]). The report names the binding type, the trait, the method
at fault and the direction (declared-but-missing, or defined-but-undeclared).

**This is what closes the shadowing hole.** Under the rejected alternative,
detection by method presence ([D-177][d-177]), a bidirectional binding whose
`claims` was written without extending the framework's generic presented as
output-only and degraded *silently*. That omission is the
`using`-without-`import` trap ([§8.1][s8-1]), one level down. With the side
declared, the absent method has something to contradict.

Greediness stays orthogonal to `reads`. A greedy front end may also drive a
compiled output gather. That combination is legal and currently
uninstantiated. Its plausible customer is a narrow-wire interactive surface,
a motorized control board whose detents must be driven back out. The binding
stays an `attach!` argument, never a device field. The same `T16000M` binds
differently per aircraft, and narrowing the binding narrows the claim
([§11.3][s11-3]).

**Why the [periphery](#g-periphery) gets roots where
[components](#g-component) have one.** [§8.5][s8-5] refuses a class supertype
for two reasons, and neither reaches here. First, a component's
single-inheritance slot is *already spoken for* by the domain hierarchies
(`AbstractAircraft`, engine families), while a device's and a binding's are
vacant. Nothing else wants them. Second, a component's class is
implementation detail behind its contract ([§8.3][s8-3]), while a binding's
**sidedness is its public contract**, the one thing every consumer of it
must know.

Rejected, correspondingly ([D-177][d-177]): an abstract binding-type
*taxonomy* encoding the sides, optional roots left unenforced, and a declared
`sides(b)` trait returning the side set. The last of the three is **answered
rather than repeated** by the design above, since redundancy *with a
cross-check* is drift detection. That is what the bidirectional check turns
the traits into. The same fact is stated twice, in two registers, with the
framework paid to compare them.

**`is_greedy` is a claim source, not a device class.** What the declaration
buys is one computation at the attach point. After it the binding holds an
ordinary claim set, and every mechanism downstream is blind to where the set
came from: exclusivity and storage ([§11.3][s11-3]); shape, shim, merge,
scatter and [drain](#g-drain) ([§11.4][s11-4]); [trace](#g-trace)
([§11.5][s11-5]); detach's release. There is no derived surface shared among
the writers that elected it, and no device class hanging off the marker. The
standing rejection is untouched. Opportunistic writing to unclaimed faces
"for any device" stays dead ([D-044][d-044]). Autonomous devices still
enumerate, and a maximal surface is what exactly one line of a binding asks
for, in the open, checked like any other claim.

**A second greedy attach stakes the empty remainder.** The complement is
computed against the [roster](#g-roster) as it stands. A greedy binding
attached after another has already swallowed everything therefore gets the
empty claim. That claim is legal, being the honest may-write-nothing
degenerate below, and it is useless, which is worth saying out loud. The
attach succeeds and reports `EmptyGreedyClaim` ([Appendix C][sC], a service
warning naming the device and its binding). That is the one honest reading
of "you asked for what is left and nothing was left".

**Several interactive front ends may be rostered at once.** A web console
can claim the autopilot faces beside a local GUI claiming the stick faces.
With explicit claims they are simply two enumerated devices, partitioning
the surface rather than sharing it. The one thing still limited to a single
holder is `needs_calling_task` (the affinity check, [§11.3][s11-3]), which is
a property of the task topology, not of interactivity.

**The shipped GUI binding is a greedy one.** It declares `is_input` and
`is_greedy`, stakes the computed claim (everything unclaimed at the moment
it attaches), and defines no `claims` of its own. It declares no `reads`
either, because its read path is the handle's primitive read. VSync-paced,
it reads `latest` afresh each render ([§12.3][s12-3]), with an ad-hoc,
render-time read set over the whole [snapshot](#g-snapshot). That is the
inspection register's shape ([§11.2][s11-2]). The compiled output gather
therefore has nothing to do for it. The same GUI device type is equally
attachable under a binding that returns explicit claims. Greediness is the
binding's declaration, not the device's nature. Every other interactive
front end anyone might want (a web console, a remote panel) has both
spellings available. It can attach with the greedy binding where the GUI
would have been, or with explicit claims beside other front ends.

**The empty enumeration is not a back door.** `is_input(b) = true` with
`claims(b) = ()` stays an honest degenerate, a device that may write nothing.
Its writes are still binding-bounded, so drift onto any face is
`OutOfClaimEntry`. There is no privileged class for it to promote into
either. `claims` bodies are ordinary code (the idiom, [§8.5][s8-5];
comprehensions included), and an enumeration that came back empty by
accident stays inert, exactly as written. The maximal surface is reachable
only through the explicit `is_greedy(b) = true` declaration. The most
privileged claim is the hardest to acquire by accident, and a declared trait
is deliberate authorship. For the same reason, `claims` never returns
`nothing` or a sentinel to mean "compute it for me". The enumeration
contract has one meaning and the trait carries the other. A dual-meaning
return would be exactly the ambiguity the declaration vocabulary is built to
refuse.

#### One shipped binding type; conditioning has an owner

`TableBinding` is *data-driven*. The framework writes its `map_input` once,
and a table value (axis/button entry → [face](#g-face), deadzone/expo
parameters) is constructed per [device](#g-device) × aircraft pairing, where
configurations are made:

```julia
TableBinding(stick_y  = (face = "elevator", deadzone = 0.05, expo = 0.6),
             throttle = (face = "throttle",),
             trigger  = (face = "brake_count",))       # levels doctrine: a counter
```

Its generic `map_input` *is* the shared pure conditioning helper
([§11.4][s11-4]), and its owner. The entry tuple rides in the type, so the
mapping specializes per table with no dynamic dispatch. A *code-driven*
binding looks identical to the framework. A JSON telecommand peer whose
`claims` returns the vocabulary and whose `map_input` parses bytes is one.
One purity note is taught in [Appendix A][sA]. Cross-datum state, such as
press counters and edge detection, lives in the device struct, maintained by
the loop, and arrives *inside* the datum. `map_input` stays pure.

#### Bad datum versus bug: two classes, two fates

A datum that cannot be mapped for environmental reasons (a truncated
datagram, malformed JSON, an out-of-range field) is a
[bad datum](#g-bad-datum), tolerated *in the loop body*. The body catches
it, stages nothing, calls `report!(handle, MalformedDatum(cause))` and
continues. That tolerance is bounded by the [device](#g-device)'s own
[diagnostic cell](#g-diagnostic-cell) (the ring and suppressed counts,
[§11.8][s11-8]; the stream, [§13.2][s13-2]), and what it records is visible
next to a live heartbeat. Any other exception propagates, and the wrapper
turns it into `DeviceCrash` ([§12.4][s12-4]).

The classification is the author's, because only they know their parser.
FlightCore's `InputMappingError` docstring assigned it the same way. What
changes under the author-owned loop is that no framework per-iteration catch
site exists, so the framework's contribution is the diagnostic channel, not
the catch. A marked exception type is not provided ([D-105][d-105]).
`report!(handle, …)` writes device-attributed runtime warnings into that
device's diagnostic [cell](#g-diagnostic-cell), the single-writer entry point
into the runtime warning stream ([§13.2][s13-2], [§11.8][s11-8]), and
nothing more. It is not a general user-diagnostics channel. Tolerating
everything hides bugs as "device attached, nothing happens". Tolerating
nothing kills a live telemetry link on its first truncated datagram, and
since tasks are per-run artifacts ([D-093][d-093]), kills it for the rest of
the run.

### 11.7 The GUI write path: port resolution, peek, staging contract

Panels remain per-[component](#g-component) extensions in FlightCore's style,
such as `GUI.draw!(ctx, ::LowPassFilter)`, discovered by walking the
[assembly](#g-assembly). Widgets, however, name **the component's own
[ports](#g-port)**, never [root inputs](#g-root-input). The build-time wiring
answers one question statically and exactly: *is this port transitively
driven by a root input, and which one?* Every input port has exactly one
source ([§6.1][s6-1]), so the resolution is total:

- **Root-driven, within the GUI's claim: a live widget.** It
  [peeks](#g-peek) and stages the resolved root input through the GUI's own
  [staging cell](#g-staging-cell).
- **Component-driven, or root-driven under another device's claim: a
  read-only rendering.** It displays the driven value from the
  [snapshot](#g-snapshot), visually distinct, with the source as provenance
  ("driven by `avionics/throttle_cmd`", the canonical slash form of
  [§8.6][s8-6]).

This retires FlightCore's dead-slider convention and replaces it with checked
structure: **a widget is live exactly when the underlying input is yours to
command in this configuration.** The dead slider is the `Cessna172Xv1`
throttle. The engine panel's slider is visually live and the avionics
silently overwrite it every cycle, so who commands what lives in the user's
head. User-commandability is a wiring decision made where configurations are
made. Command-plus-manual-override is a mux component with a root-wired
select. That is explicit structure, not two writers racing (the same race as
the drag phase, [§15.3][s15-3], ruled out the same way). This places one
obligation on the GUI. Read-only rendering is first-class, not an error
state, because the author of `input_slider!` cannot know at authoring time
whether it will be live.

**Liveness is a [derived property](#g-derived-liveness), and resolution is
transitive.** A widget is live iff two things hold. Its port's feed chain
terminates in a root input, *and* that root input lies **inside the GUI's
own [claim](#g-claim)** in the run's frozen surface partition (root-input
exclusivity, [§11.3][s11-3]). The feed chain is walked through wires and
interface connections across *all* levels, not just the local assembly. The
claim may have been computed from the unclaimed complement under
`is_greedy`, or enumerated [face](#g-face) by face by a partial-claims
binding ([§11.6][s11-6]). Either way, "live" reads as "inside the surface I
declared for".

Under the [roster](#g-roster) freeze, liveness is a static fact of the run.
It is baked once, with the port resolution, when the run starts, and never
consulted against mutable claim state at render. There is no per-port
"GUI-controlled" marking anywhere. The export chain is the marking, written
by the one author entitled to write it. A component's ports become
GUI-commandable exactly when the assemblies above surface them. The switch
between "driven by its own panel" and "driven by an external provider" is
therefore automatic. At build time it follows the wiring archetype, where a
scripted `World` wires a [scenario component](#g-scenario-component) into the
same faces the interactive `World` exports to root. At run start it follows
roster claim state. Nominally-connected ports with a GUI *override* channel
are rejected ([D-045][d-045]). The honest cost stands. **Unexported ports are
unpokeable.** FlightCore's poke-any-`u` workflow does not survive
[contract](#g-contract) visibility ([§8.3][s8-3]), deliberately.

**Peek rule.** A widget displays its **own pending write if any, else the
snapshot value**. It peeks its own [cell](#g-staging-cell) only. Another
[device](#g-device)'s pending write is invisible by design. Its applied value
arrives via the snapshot one frame later, and cross-device peek is rejected
([D-026][d-026]). While paused, staged edits display indefinitely and apply
at the un-pause [drain](#g-drain) (the frame-top swap that publishes staged
device writes into the root inputs). Fan-out is consistent for free. Widgets
on ports resolving to the same root input peek the same pending value.

**Staging contract: widgets stage on interaction events only.** Value
widgets (sliders, drags) stage the new absolute level on edit. Edge widgets
(buttons) stage on activation, as a level computed from the peek. A flaps
button peeks the current counter `k` and stages `k+1`. The levels doctrine
makes this safe by construction. Repeated staging of the same level within a
drain window is idempotent, so there is no repeat-increment hazard.
Multi-click within one window counts correctly through the
own-pending-first peek (`k` → stage `k+1`; second click peeks pending `k+1`
→ stages `k+2`). Held buttons do not re-stage. After the drain applies and
the snapshot catches up, re-staging from the peek would auto-repeat at frame
rate. The activation edge is the intent.

The alternative, active widgets staging on *every* render pass, is rejected
([D-026][d-026]). Under root-input exclusivity ([§11.3][s11-3]) it has no
motivation. As a side benefit, staging traffic (and trace noise) drops from
render-rate-while-grabbed to actual edits.

No claim-transition policy exists, because no claim transition can occur
mid-run (the freeze, [§11.3][s11-3]). The one liveness-adjacent display rule
is the orphan case. A read-only widget whose claiming device's task has died
renders the fact in its provenance ("claimed by `T16000M` — task dead"), the
heartbeat surfaced in place ([§12.2][s12-2]). What it displays beside that
fact is the ordinary snapshot value, the orphaned root input's last drained
level. An orphan widget is a read-only rendering like any other, never a
blanked one. An orphaned root input is therefore visible where the user is
looking, not only in the status panel.

The panel-authoring calling convention is deferred to migration
([§16][s16]), where it is co-designed against the GUI library. It covers what
the drawing context carries, how widgets name their component's ports, and
how an assembly's panel composes its children's. Its constraints are fixed
here. Panels name their own ports by face-name string. Resolution to root
inputs and the liveness verdict are baked at run start, never performed at
render. Liveness and peek arrive through the framework-supplied context,
never by reaching into the loop. And assembly panels compose children by
path.

### 11.8 Diagnostics and liveness: the per-writer cell

The chapter's two data channels are specified down to their memory ordering.
The runtime warning stream ([§13.2][s13-2]) and the liveness heartbeat
([§12.2][s12-2]) are a third, and they cross the same task boundaries. They
are written at staging by whichever task stages (`OutOfClaimEntry`,
`ClaimedFaceEntry` and `EntryTypeMismatch`, [§11.4][s11-4], on a
[device](#g-device) task or through the harness register, [D-200][d-200]).
They are written by the device tasks (`MalformedDatum` from the author's loop
body via `report!(handle, …)`, [§11.6][s11-6]), and by the loop itself
(`ChatteringBudget`, `FiringBudget`, `DebtReanchor`). They are read by the
loop, which folds them into the published
[framework status](#g-framework-status) ([§11.2][s11-2]) and hence into every
[snapshot](#g-snapshot). An unspecified structure with those writers is
exactly the arbitrary shared mutable state the two rules ([§11.1][s11-1])
exist to eliminate, so it gets the mechanism [§11.4][s11-4] already
established, not one of its own.

**One [diagnostic cell](#g-diagnostic-cell) per writer: one per rostered
device, one for the harness register, one for the loop itself
([D-200][d-200]).** A device's [cell](#g-diagnostic-cell) and the loop's have
a single writer, the same ownership argument as the
[staging cells](#g-staging-cell). There is no locking, no arbitration and no
new primitive. The harness register's cell is written from whichever task
stages, exactly as its staging cell is, and the same CAS append arbitrates.
It carries no heartbeat, and its status record no `task_state`, because it
has no task of its own to be alive or dead. The cell holds a **bounded
accumulation** and one atomic liveness timestamp. The accumulation is a
small ring of diagnostic values, capacity **16**, plus a per-kind count of
what the ring could not hold.

**That bound *is* the rate limit.** When a writer emits past the ring's
capacity within one frame, the entry is not stored and its kind's suppressed
count increments. The drop policy retains the earliest in the frame, and the
excess becomes counts. The first occurrences are the ones with diagnostic
content, and the hundredth is noise the count already reports. Rate-limiting
"wherever its source can repeat" ([§13.2][s13-2]) is therefore not a policy
layered over the stream but a structural property of the channel that
carries it. A [chattering](#g-chattering) model or a peer flooding malformed
datagrams costs at most sixteen retained values and one integer increment
per kind per frame, whatever its source does. No writer can starve another,
because the cells are disjoint.

**This [drain](#g-drain) is the same drain [§11.4][s11-4] specifies.** One
`atomicswap` per cell at frame top, at the same point and under the same
indivisible-take argument as the staging drain. What the loop swaps *in* is
a shared **empty sentinel**, so a quiet frame swaps the sentinel in and gets
the sentinel back. That allocates nothing, and it leaves no load-only code
path that goes untested on healthy runs. The take is also what makes
publication sound. The batch is exclusively the loop's before it is ever
reachable from a snapshot, so the binding rule ([§11.2][s11-2]), that nothing
reachable from a published snapshot is ever written again, holds by
construction. The live accumulator is never reachable from a published
value.

**The heartbeat rides in the same cell**, as an atomic timestamp field. The
device task stores it on every loop pass from inside the handle primitives
([§11.6][s11-6]: the framework observes activity without owning the loop
body), and the loop acquire-loads it at publication, when it assembles the
status ([D-240][d-240]). There is no separate liveness channel and no second
registry. A device that is alive is a device whose cell carries a recent
timestamp, and the 2 s staleness threshold ([§12.2][s12-2]) is read against
this field. The heartbeat is not a diagnostic kind. It is a field, always
present, never enumerated in [Appendix C][sC].

**The published framework status is a concrete frozen value.** Per writer it
carries four things. `recent` is the ring this boundary drained, at most
sixteen entries. `suppressed` is the per-kind counts the ring refused this
boundary. `totals` is the cumulative per-writer × per-kind counts since the
run began, owned privately by the loop and *copied* into each status. And
`heartbeat` rides beside the `task_state` the loop reads off its own device
`Task` handle at publication ([§12.2][s12-2]). Beside the per-writer records
ride the pacer diagnostics ([§10.7][s10-7]). Delta plus total is what makes
the status legible at any reading cadence. A GUI panel refreshing at 60 Hz
sees each occurrence once in `recent`, while a consumer that samples
occasionally still reads a complete account from `totals`. Nothing is lost
by not looking. The record's `who` is the only attribution a value has, so a
renderer presents each value under its record's writer ([D-228][d-228]).

**Presentation is where `maxlog` lives.** A status renderer prints a given
writer × kind up to **25** cumulative occurrences and then switches to
count-only display ("`MalformedDatum` from `UDPInput#3`: 1 482
occurrences"). That threshold is presentation policy, not channel policy.
Counts keep accumulating regardless, nothing recorded depends on it, and the
choice belongs to whoever renders. The channel's own bound, above, is the
one that is normative.

**The terminal snapshot carries the run's final cumulative counters**
([§12.4][s12-4], [§13.5][s13-5]). An [unattended run](#g-unattended-run) (a
run with empty staging and no snapshot readers) that nobody watched
therefore still answers "what went wrong, and how often" from the value its
own shutdown published. Final means final at the last frame top
([D-201][d-201]). The account closes with the drain that preceded the
terminal publication. What lands after it can reach no snapshot. Examples
are a report from a device's exit path and the tail's own
`DeviceJoinTimeout` ([§12.4][s12-4]). So the loop takes each cell once more
at the run's end, keeping the next run's account clean. That last take is
folded into the [termination record](#g-termination-record) as the tail
residue, per writer the final ring and its suppressed counts
([§13.5][s13-5]), and presented through the standard logging backend. It is
loud *and* recorded, and still never published ([D-201][d-201],
[D-203][d-203]).

**Allocation.** On a quiet frame **nothing allocated scales with diagnostic
activity**. The sentinel swap allocates nothing, and the per-writer status
costs one small vector of records per publication beside the per-boundary
snapshot allocation [§11.2][s11-2] already accepts. That is the same
GC-over-reuse trade, a roster-sized vector rather than a snapshot type per
roster size ([D-241][d-241]). The per-kind counters are a **fixed-shape
isbits record, never a `Dict`**. The closed kind set ([Appendix C][sC])
licenses that, because it makes the counter layout a type rather than a
lookup. On a noisy frame the diagnostic values are allocated at emission, on
the writer's own task. A drained non-empty ring is frozen into the snapshot
and can never be written again, so the writer allocates a fresh ring lazily
at its next emission. That cost, too, lands on the writer's task, and it is
the same GC-over-reuse trade [§11.2][s11-2] makes when it rejects
preallocated snapshot buffers. The rate limit is therefore an allocation
bound as well. One ring of sixteen entries per writer per boundary is the
worst case, and everything past it is an integer increment. The
zero-allocation invariant ([§7.5][s7-5]), scoped to the model
[sweep](#g-sweep), is untouched. The cells sit on the framework side of that
scope with publication and logging.

One composition with the log is worth stating once. Because the log retains
snapshot references ([§11.2][s11-2]), `totals` is monotone across logged
snapshots. So `log_every` [decimation](#g-decimation) (the log's
keep-every-kth retention policy) loses *which* boundary within a skipped
stretch an occurrence fell on, never *how many* occurrences there were.

Rejected: a shared queue under a lock, a status referencing the live
accumulator, ring reuse by double-buffering, and unbounded accumulation
([D-136][d-136]).

---

## 12. Runtime periphery: lifecycle and orchestration

Where [§11][s11] fixes how data crosses the loop boundary, this chapter covers the
machinery that drives the loop itself: the [control plane](#g-control-plane) and the scheduling
primitives, the shutdown protocol, and the run lifecycle from `init!` through
[replay](#g-replay).

### 12.1 Control plane

Pause, un-pause, pace changes, `margin` changes and stop are a few scalar
fields on a separate atomic surface. The loop consults them at frame top and
inside its wait and pause states. `margin` ([§10.7][s10-7]) rides here for
the same reason `pace` does. It tunes the wait, never the arithmetic, so
retuning the coarse/spin split mid-run is safe by construction. The stop's
issuers are the operator's channels (GUI button, [device](#g-device) handle,
calling code) and, in an interactive session, Ctrl-C. An
[operator interrupt](#g-operator-interrupt) is caught at one of the loop's
unmask points and sets exactly this stop, with no separate entry point
involved ([§12.4][s12-4]).

**The stop word carries its issuer.** Each issuing site writes its identity
(the device's name, `:code`, or `:interrupt`) by compare-and-swap from empty,
and the first writer wins. The loop's frame-top read consults the word for
non-empty, so the recorded issuer is the request that actually initiated the
tail. It lands in the [termination record](#g-termination-record)'s
`ControlRequestedStop` ([§13.5][s13-5], [D-203][d-203]).

**Control is not staging, structurally.** Staged writes apply at
[drains](#g-drain), and a paused loop drains nothing, so un-pause via staging
would deadlock by construction. Riding outside the drain/[trace](#g-trace)
path is safe for determinism precisely because [§10.7][s10-7] put
[pacing](#g-pacing) outside the semantics. Control changes *when* frames
execute, never what they compute, and stop merely truncates the trajectory.
While paused the loop blocks on a condition (notified on un-pause and stop),
not a spin.

### 12.2 Loop scheduling: wait primitive, yields, thread budget

[§10.7][s10-7] fixed the shape of the pacer's wait, hybrid sleep-then-spin,
but left the coarse phase's primitive open. That choice is a scheduling
decision rather than an arithmetic one. It settles what else can run while a
frame waits. It is made here, together with the two questions that trail it:
whether a frame is guaranteed to yield at all, and how many threads a session
needs.

**Rule.** The coarse phase uses task-yielding `sleep`. There is no
`systemsleep` variant ([D-027][d-027]).

**Why.** What the choice buys is the wait slot. `sleep` releases the loop's
thread, which makes the pacer's wait the natural scheduling window for
co-resident [device](#g-device) tasks. The design already spends that slot
twice, as the staging slot ([§10.7][s10-7]) and as the [drain](#g-drain)
source ([§11.4][s11-4]).

A `systemsleep` variant for dedicated-thread hard-RT deployments is a
[guarded addition](#g-guarded-addition) (a capability the design admits but
does not build).

**Rule.** With devices attached, every frame yields at least once.

**Why.** The rule is semantically free. [Pacing](#g-pacing), and hence
yielding, is outside the semantics ([§10.7][s10-7]).

The yield is implicit in the coarse-phase `sleep` whenever that phase runs.
An explicit `yield()` covers the frames where it does not run: unpaced runs,
and pure-spin frames with budget ≤ margin. The spin phase itself never
yields. Yielding there would trade its µs precision for scheduler noise.

The consequence is a bound on thread occupancy. The loop holds a thread for
at most one frame before the scheduler can run anyone else. Julia's
cooperative-scheduler freeze requires a thread monopolist, a never-yielding
task that holds its thread forever, and that precondition is structurally
absent from framework tasks.

**Rule.** The thread budget is a documented sizing rule and a startup
warning, not a hard error ([D-027][d-027]).

The freeze FlightCore's `nthreads` error prevented cannot reproduce here, for
three reasons. The loop yields every frame. Nothing couples a stall to anyone
else, the GUI least of all. It waits on nothing, ever. It uses a
[snapshot](#g-snapshot) acquire-load, its own
[staging cell](#g-staging-cell) and atomic control. And the GUI runs on the
*calling* task, so it cannot fail to be scheduled. Under any starvation,
then, the window keeps rendering and the stop button keeps working.
Undersized sessions degrade to laggy inputs and stale snapshots, which are
visible, recoverable states.

`run!` warns when `Threads.nthreads()` is tight for the attached population,
naming the `julia -t` remedy. That is one check per run, against the frozen
[roster](#g-roster) ([§11.3][s11-3]). The sizing guidance behind it is one
thread for the loop, the main thread for the GUI, and headroom for
compute-heavy or blocking-ccall devices. libuv-backed I/O yields. Raw
blocking ccalls pin their thread for the duration. There is no pinning and
there are no sticky tasks.

**Liveness heartbeat.** Since starvation is survivable, it must be
diagnosable. The record is the published
[framework status](#g-framework-status), the frozen diagnostics value each
snapshot carries beside the table. It includes per-device liveness (the
liveness timestamp and the device's `task_state`) next to the pacer
diagnostics. The mechanism is the per-writer [cell](#g-diagnostic-cell),
specified in full by [§11.8][s11-8], plus the device `Task` handles the loop
already owns, and nothing besides. The cell carries the single liveness
timestamp. The loop reads `task_state` off those handles where it publishes
([D-193][d-193]). A starved, blocked or crashed device task shows in the GUI
as a stale heartbeat with a name on it, not as mysteriously frozen physics.

**Stale means a liveness timestamp more than 2 s behind wall clock.** The
threshold is deliberately loose, because the heartbeat is advisory. It is a
liveness display and a provenance record, never a kill trigger, never a
detach. It must also tolerate a device legitimately parked in a blocking
read between rare data.

### 12.3 The next-snapshot wait

Rate-matched output [devices](#g-device) (telemetry, disk streaming) act once
per [boundary](#g-boundary). What they need from the framework is a way to
learn that a boundary has happened without polling for it.

**Rule.** Two artifacts provide it: a monotonic
**[boundary counter](#g-boundary-counter)**, the loop's own, plus one
`Threads.Condition`.

The counter counts *published boundaries*, that is grid, `t*` and
[boundary zero](#g-boundary-zero) ([§10.4][s10-4]), not frames. Consecutive
wakes are therefore not necessarily `h` apart.

The loop's publication is `lock; counter += 1; notify; unlock`, nanoseconds
of framework-only code. Waiters never block it. One parked in `wait` has
released the lock as part of parking.

The device side is `wait_next_snapshot(handle)`, which blocks until
`counter > last_seen && running` under the canonical predicate-loop idiom.
That idiom handles waiters at different paces, frames skipped while
transmitting, and shutdown, all with no per-frame reset. Shutdown works
because [§12.4][s12-4] wakes all waiters and each predicate then routes its
owner out.

A `Base.Event` latch is the wrong primitive here ([D-028][d-028]).
Conditions carry no facts, only "look again". The facts that matter, the
counter and `running`, live in state each waiter tests privately.

**Two indices, and where each lives.** The [snapshot](#g-snapshot) carries
the trajectory's *published-boundary ordinal* with `t`. Boundary zero is 0,
and every publication after it, grid or `t*`, counts one. Any holder of a
snapshot therefore indexes it without consulting the loop, whether the log
or a post-run inspector. A new trajectory restarts the ordinal at zero, with
everything else `init!` resets. The boundary counter is a different number.
It is the loop's monotone count of every publication it has ever made, never
reset across trajectories, and its absolute value is nowhere normative. It
exists for the wait predicate alone, and it is never reset because a
waiter's `last_seen` must never run ahead of it ([D-230][d-230]). An error's
[replay](#g-replay) pointer is a third index, the frame-entry boundary index
of [§13.4][s13-4], a frame count that names no `t*` boundary.

**Rule.** The order of the two publications is normative. The release-store
of `latest` ([§11.2][s11-2]) happens **before** the counter increment under
the lock.

```julia
# the loop, at every published boundary
@atomic latest = snap    # 1. release-store: the snapshot becomes reachable (§11.2)
lock(cond) do            # 2. only then the counter, under the lock
    counter += 1
    notify(cond)         #    parked waiters wake and re-test their predicate
end
```

`counter > last_seen` therefore implies that `latest` holds at least that
boundary, and a waiter can never wake onto a stale snapshot. The converse,
observing a *newer* snapshot than the increment that woke you, is expected
and correct. Newest wins.

**Semantics: newest-wins, no queues.** A slow consumer skips frames and
always receives the current world. This mirrors the inbound side.
[Coalescing](#g-coalescing) to the newest batch (in) and to the newest
snapshot (out) are the same ZOH decision. No backpressure exists in either
direction, and the loop never waits on anyone. Per-consumer every-boundary
queues are rejected ([D-028][d-028]).

The GUI does not use the wait. Being VSync-paced, it reads `latest` at each
render.

### 12.4 Shutdown protocol

A run ends when its time is up, when someone stops it, or when the model
itself says so. Whatever the cause, the same work has to happen. The loop
has to stop on a [boundary](#g-boundary) rather than mid-frame, every device
task has to be woken out of whatever it was blocked on, and every resource
acquired for the run has to be released before `run!` returns. This section
specifies that sequence, which it calls the tail throughout. It also
specifies the two things that bracket the tail. One is the pre-spawn
initialization at the top of a run, which is a step of this same protocol.
The other is the operator interrupt, which enters the tail rather than
bypassing it.

#### The tail: the ordered sequence every stop takes

**Rule.** Steps (1) through (5) below run in that order on every stop,
whatever initiated it. Steps (6) and (7) specify what happens when a device
task or the loop itself ends first.

1. **Initiation.** Three events start a shutdown: `t_end` is reached, a
   control-plane stop is issued, or a `stop_on` [face](#g-face) reads `true`
   in the just-published [snapshot](#g-snapshot). The stop's issuers are the
   GUI, a [device](#g-device) handle, code, or an
   [operator interrupt](#g-operator-interrupt) (Ctrl-C, treated below). The
   third event is model-detected termination ([§13.5][s13-5]). The loop
   always completes the current boundary sequence and never stops mid-frame.
   It then publishes the final snapshot. Only then does it set the sticky
   stopped status.
2. **Wake all framework waits.** The waits are the next-snapshot wait and
   the pause. Each waiter observes the stopped status and unwinds. A stop
   issued while paused therefore works.
3. **Unblock device-specific blocking calls.** The hook is
   `unblock!(device)`, default no-op. A network input's override closes its
   own socket, which raises in the blocked task. The framework wrapper
   catches that raise and treats it as shutdown. This demotes FlightCore's
   EOT convention from load-bearing shutdown mechanism to an optional
   wire-protocol courtesy between remote peers.
4. **Loop bodies exit.** The exit is the author's own
   `while running(handle)` loop, the authoring contract of [§11.6][s11-6].
   That authoring contract teaches two obligations: the predicate check and
   interruptible blocking. Steps (2) and (3) are what make every blocking
   point interruptible. The wrapper's `finally shutdown!(device)` is
   guaranteed on every exit path.
5. **Join under the `join_timeout` cap.** The cap is a `Simulation`
   deployment keyword, a positive real in seconds of wall clock, defaulting
   to 5 ([Appendix B][sB]). A device task exceeding it is reported *by name*,
   through the [§12.2][s12-2] heartbeat. It is then abandoned with a
   `DeviceJoinTimeout` diagnostic ([Appendix C][sC]) rather than left to hang
   `run!`. The diagnostic is written to the loop's own cell, collected by the
   run's-end sweep into the [termination record](#g-termination-record) and
   presented through the logging backend, with the terminal snapshot
   preceding the join ([D-201][d-201], [D-203][d-203]).
6. **Device-initiated paths.** A device exits voluntarily when its loop body
   returns, at a window ✕ or a peer EOT. No `should_close` hook exists
   ([§11.6][s11-6]). With `should_abort` set, the wrapper's exit path also
   requests a sim stop. Otherwise the sim continues with the device's *task*
   absent. Its [cell](#g-staging-cell) stops filling, and the loop is
   structurally indifferent. Its [roster](#g-roster) entry and its
   [claims](#g-claim) persist to run end, because [§11.3][s11-3] freezes the
   roster for the run and death is not detach. The orphaned
   [root inputs](#g-root-input) hold their last-drained values, visibly
   ([§11.7][s11-7]). A crashing device task is caught by the framework
   wrapper and follows the same path, logged with the device's name
   (`DeviceCrash`, [Appendix C][sC]).
7. **Loop-side failure.** A failure on the loop's own side runs steps (1)
   through (5) from the catch path, specified in [§13.6][s13-6]. The failed
   boundary is discarded and the previous snapshot is promoted to final.
   FlightCore's `SimulationTermination` catch path was the precedent, though
   the exception-based termination idiom itself has no place here
   ([§13.5][s13-5]). Devices therefore unwind cleanly regardless of who died.

The ordered part, in one line:

> **(1)** stop observed → current boundary completed → final snapshot published
> → sticky `stopped` set → **(2)** framework waits woken → **(3)** `unblock!`
> per device → **(4)** loop bodies return, each through its wrapper's
> `finally shutdown!` → **(5)** join under the `join_timeout` cap → `run!`
> returns

**Why the final snapshot goes out before the status is set.** Publishing
first guarantees that output devices can flush the true final state. The
status in that terminal snapshot carries the run's cumulative diagnostic
counters ([§11.8][s11-8]), the warning account of a run nobody watched,
complete up to that snapshot's own frame top. What the tail itself produces
comes later by construction. It is folded into the termination record and
presented through the logging backend, never published ([D-201][d-201],
[D-203][d-203]).

**Rule.** That terminal snapshot is retained in the log unconditionally,
under any `log_every` and any `log_max` ([§11.2][s11-2]).

**`t_end` lands on the grid.** The run ends at the first grid boundary whose
time reaches or exceeds `t_end`. Whole frames only, never a shortened final
step, which grid integrity forbids ([§10.4][s10-4]; `tₖ = t₀ + k·h`, indexed
and never accumulated). The final boundary may therefore overshoot `t_end`
by up to `h`. The termination record carries the actual final `t`
([§13.5][s13-5]). This is the `t_plus` spelling ([§12.6][s12-6]) applied to
the run's own clock. The run takes whole frames until the boundary time
first covers the duration.

**The two termination sources differ in kind.** `t_end` is a grid fact,
checked against boundary times on the grid. `stop_on` is checked at *every*
published boundary, `t*` included ([§13.5][s13-5]).

**Why the default is five seconds.** It is generous for GUI window teardown
and socket closes. It is short enough that an abandoned join reads as a
diagnosed timeout rather than a hang.

**The cap is deployment, not implementation.** That is the disposition
[§10.4][s10-4] gives its own two constants, extended here to an operational
one ([D-198][d-198]). Deployment contexts legitimately differ in patience. An
unattended sweep wants to fail fast, a test battery exercising the
abandonment path faster still, while a device with slow teardown may warrant
more. The cap is not trajectory-determining, because the trajectory has
ended at the final snapshot before any join begins. So, like `log_max`
([§11.2][s11-2]), it stays out of the trace header's deployment block, and
replay neither records nor compares it ([§11.5][s11-5], [§12.7][s12-7]).

**The calling-task device sits outside the join.** The
[calling task](#g-calling-task) is the task that invoked `run!`. The device
it hosts is the GUI, which has no spawned task ([§11.1][s11-1]). That
device's loop body is the calling task's own occupation of `run!`. It exits
by the same `running(handle)` predicate as any device loop, and `run!`
returns after the joins. One honest asymmetry follows. The abandonment path
of (5) cannot cover it, because nothing can abandon the task `run!` stands
on. A calling-task device that blocks past shutdown therefore hangs `run!`.
The trait's one authoring obligation is a loop body that never blocks
between `running` checks. The shipped GUI's render loop polls once per frame
and never blocks.

**What survives the tail.** After (5) the task set is empty, device tasks
being per-run artifacts ([§11.1][s11-1]), and `shutdown!` has released each
device's OS resources. What survives a stop is the roster entry: binding,
claims, stable device id ([§11.3][s11-3]). Never a task, never a live
resource. That holds for a device whose task died mid-run too, its entry
being indistinguishable at this point from any other's. `stopped` is where
`detach!` removes an entry and releases its claims.

**One roster change belongs to this tail.** A GUI attached by `run!`'s
`gui = true` is detached here, releasing its computed claim (the run-scoped
flag, [§12.6][s12-6]). It is the only roster mutation the protocol itself
performs. It sits in the tail precisely so that (7)'s failure path takes it
too, an everything-claim staked for one run never surviving into the next.

**The next run re-acquires everything.** The next `run!` re-runs device
`init!`, since resource acquisition is per-run. FlightCore's
create-a-new-socket-each-`init!` in network.jl is the precedent. It also
spawns fresh tasks against the [§12.3][s12-3] counter, which is never
re-armed. Each task reads its `last_seen` off the counter at spawn. While
stopped there are no device tasks at all, so voluntary exit and the
[§12.2][s12-2] liveness heartbeat are run-scoped observables. A device
unplugged while stopped surfaces as the next run's `init!` failure, disposed
of by the initialization bracket below.

#### Initialization: the pre-spawn bracket

**Initialization is a step of this protocol, taken at the top of a run.**

**Rule.** Before any task is spawned, the loop calls `init!` once per roster
entry, in attachment order, on the calling task. Each call sits in its own
bracket.

```julia
for entry in roster                       # attachment order, calling task
    try
        init!(entry.device)
    catch e
        shutdown!(entry.device)           # release, unconditionally (§11.6)
        report!(entry, DeviceCrash(e))    # pre-spawn: the entry is the address, no handle yet
        mark_dead!(entry)                 # from boundary zero; no task is spawned
        entry.should_abort && stop!(control)
    end
end
```

**Why the bracket.** It is what makes "guaranteed on every exit path"
([§11.6][s11-6]) true of the path outside that wrapper. A device that throws
half-way through acquisition is handed back to `shutdown!` right there, so
its partially acquired OS resources are released rather than leaked. That is
exactly why `shutdown!` owes tolerance of a partially initialized device, a
rule [§11.6][s11-6] teaches.

**The report is the ordinary `DeviceCrash`, not a kind of its own**
([Appendix C][sC]). Its [payload](#g-payload) already carries everything an
init-time failure has to say: the device id, the cause exception, and
whether `should_abort` was set. The name is honest. A device that cannot
acquire its resources has crashed before it lived.

**Rule.** The report is written through the ordinary
`report!(address, diagnostic)` entry point, addressed by the roster entry
rather than by a handle.

There is no device task to hold a handle before the spawn. The address
supplies the device identity either way, which is why no call passes a
device id ([§11.8][s11-8]).

**Rule.** No task is spawned for a failed device, so it is dead from
[boundary zero](#g-boundary-zero) (the initialization boundary: the ordinary
macro-sequence with an empty integrate).

That needs no machinery. Its [diagnostic cell](#g-diagnostic-cell) (the
single-writer cell each writer owns for diagnostics and heartbeat) never
receives a heartbeat timestamp. The cell therefore reads stale against the
[§12.2][s12-2] threshold from the first frame ([§11.8][s11-8]).

**Rule.** The claims of a failed device persist to run end.

This is the death-is-not-detach disposition ([§11.3][s11-3]), applied one
step earlier than (6)'s. The roster is frozen for the run, and the orphaned
root inputs hold their initial values, well-defined by
[root-input totality](#g-root-input-totality) ([§14.6][s14-6]; every root
input must hold a value). An orphan of (6) holds a last drained batch
instead.

**The run's disposition splits on `should_abort`, uniformly with (6).** With
the flag clear, which is the default ([§11.6][s11-6]), the remaining entries
initialize, the run starts, and the sim runs with that device absent from
frame zero. That is (6)'s "the sim continues with the device's *task*
absent", shifted to `t₀`.

With the flag set, the failure requests a control-plane stop, and that stop
is simply *already pending* when the run reaches boundary zero. This
protocol already has that path. The boundary-zero check ([§13.5][s13-5])
ends a run at `t₀` with that snapshot final, integrating nothing. No new
exit protocol is needed, therefore. The remaining entries still initialize,
every rostered device getting its `init!`/`shutdown!` pair uniformly. The
run publishes boundary zero. It ends `stopped` at `t₀` through this same
tail, with the termination record naming the source ([§13.5][s13-5]). What
the operator is left with is an ordinary stopped simulation: a terminal
snapshot, with the failure named in its diagnostic account. It is fully
serviceable by [§14][s14] and resumable by the next `run!` ([§12.6][s12-6])
once the device is plugged back in.

**Topology is derived after initialization**, not from the roster alone
([§11.1][s11-1]). A `needs_calling_task` holder whose `init!` failed returns
the loop to the calling task, which would otherwise be pinned waiting to run
the loop body of a device that does not exist. The shipped GUI attaches with
`should_abort = true`, so in practice that run ends at `t₀` anyway. The rule
is stated generally because it costs nothing.

#### The operator interrupt

**The operator interrupt is a stop, not a failure.** Ctrl-C in an
interactive session is a control-plane stop command issued by hand. The run
completes the current boundary, publishes the final snapshot, takes this
tail like any other stop, and ends `stopped`. The result is
boundary-consistent. It is fully serviceable by the [§14][s14] stopped-sim
services and resumable by the next `run!` ([§12.6][s12-6]).

The interrupt is the escape from a run nothing else can end. Such a run is
deviceless, with no finite `t_end` and no `stop_on` faces. The unpaced case
is the configuration the `UnboundedRun` warning names ([Appendix C][sC]).
The interrupt needs no entry point of its own. The stop already rides on the
[control plane](#g-control-plane), the separate atomic surface carrying
pause, pace and stop ([§12.1][s12-1]). The exceptions-are-abnormal doctrine
([§13][s13]) is untouched. That doctrine is about *model* code, while this
is the one exception whose meaning the framework knows.

**Rule.** Masking across the boundary is normative, not an implementation
hint.

**Why.** An `InterruptException` is delivered asynchronously. An interrupt
landing mid-[sweep](#g-sweep) would therefore destroy the boundary this
protocol is built on completing, and would leave half-written stores
([§13.6][s13-6]). That forces a choice between `stopped` with dirty stores
and a terminal `errored`. The `stopped`-with-consistent-stores guarantee is
exactly what the masking buys.

The loop masks delivery across the boundary macro-sequence, using Julia's
`disable_sigint`, a sigatomic counter increment that is negligible per
frame. It takes the deferred raise at the unmask points: the frame top,
where it already consults the control plane ([§12.1][s12-1]), and inside its
wait and pause blocks. All of those points are boundary-consistent. Caught
at one of them, the interrupt sets the control-plane stop and enters this
tail. The catch site ([§13.4][s13-4]) therefore never sees it.

**A second interrupt during the tail** collapses the remaining joins
immediately. That is (5)'s abandonment path taken at once, with devices
still reported by name (`DeviceJoinTimeout`). The run still ends `stopped`.
Escalation shortens the tail, never reclassifies the run. Nor can a second
interrupt repair (5)'s honest asymmetry, since nothing can abandon the task
`run!` stands on.

**Interactive-session scope, stated plainly.** Outside the REPL, Julia's
default (`exit_on_sigint(true)`) kills the process on SIGINT before any of
this machinery runs. The framework flips nothing process-global.
[Unattended runs](#g-unattended-run), those with empty staging and no
snapshot readers, rely on `t_end` and `stop_on`, as they already must.

### 12.5 Scripts and the mid-run mutation doctrine

What the consumers demonstrably mutate mid-run is surveyed here. FlightCore's
`user_callback!` has exactly two archetypes. The first is the timetable
script (c172_demos.jl:290: `elevator_offset` as a function of `t`). The
second is the synthetic pilot (c172_demos.jl:423, 525: a phase FSM reading
`y` and writing mode requests, references, flaps, wind). Both write only `u`
fields. No demo, test or GUI path pokes `x`/`s` mid-run, and `init!`/trim
appear only between construction and `run!` (c172_demos.jl:303).

**Sim-time scripts are model behavior, so they become
[scenario components](#g-scenario-component)** (ordinary periodic discrete
components holding a sim-time script). Both archetypes are clocked by *sim
time*, `t`, the trajectory. Mapping them to [devices](#g-device) is rejected
([D-031][d-031]). The clock is the criterion.

**Rule.** A sim-time script becomes a source or supervisor
[component](#g-component); a wall-clock interaction becomes a device.

A script mapped to a component is periodic discrete, with `K = 1` for
today's `dt = 0.02` callbacks. It executes synchronously in the loop,
deterministic paced or unpaced. It is replayed by recomputation, with no
[trace](#g-trace). A device, by contrast, is traced and replayed from the
trace.

**The component mapping is strictly richer than the callback it replaces.**

- The `Ref(:init)` phase closure becomes honest `s`, visible in
  [snapshots](#g-snapshot), logs and plots.
- Inputs arrive same-[boundary](#g-boundary) fresh by topological order. The
  callback ran post-step, one boundary staler.
- The pure timetable script is a one-liner reading the clock out of its
  [bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
  receives). That one-liner is
  `output_direct(c, (; t)) = (; offset = profile(t))`, exact at its own
  [ticks](#g-tick), with no latching.
- In a scenario configuration the script drives the avionics' input
  [ports](#g-port). [§11.7][s11-7] therefore renders the corresponding GUI
  widgets read-only with provenance. Today's demo-vs-GUI dead-slider fight is
  resolved by the port-resolution rule.

**`user_callback!` is eliminated** ([D-031][d-031]). It is the
[periphery](#g-periphery)'s `f_step!`, and cheap composition leaves it
without justification. Its call sites migrate to scenario components, not
devices.

**Manual event triggering needs no mechanism.** It takes a
[root input](#g-root-input) plus a [boundary-detected](#g-boundary-detected)
[guard](#g-guard) reading that root input (an edge check at step boundaries
only, with no root-finding). That is already expressible in settled
machinery. The levels doctrine applies: latched commands or counters. The
demos' engine start/stop buttons are `u`-writes today.

**Mid-run re-initialization is not built, because it is not demonstrated.**
Initialization and trim are stopped-sim workflows (first-class services,
[§14][s14]). No concurrency perimeter exists there. There is no loop and no
devices, just plain single-task code. The guarded-addition shape is on
record should demand appear. It would be a traced, boundary-executed
intervention command applied through project → [sweep](#g-sweep) → publish,
so that no consumer ever observes un-decoded state.

**The doctrine, final form.** While a simulation runs, the periphery stages
root-input writes and issues control commands. Structurally, it does nothing
else. Anything that wants to poke the model mid-run is one of three things.
It is an *input* in disguise, so wire a root input and a guard. It is *model
behavior* in disguise, so add a scenario component. Or it is a *wall-clock
interaction*, so attach a device. Graceful termination follows the same
shape ([§13.5][s13-5]): a declared stop [face](#g-face) in the model, plus
`stop_on` policy at deployment. Never a callback, and never a thrown
exception.

### 12.6 Run lifecycle and partial advance

A `Simulation` moves through five states: **built**, **initialized**,
**running**, and terminally **stopped** or **errored** ([§13.4][s13-4]).
**Built** means stores allocated and [boundary zero](#g-boundary-zero) not
completed. It is the cold state, and the state a throw inside boundary zero
returns the simulation to ([§13.4][s13-4]). **Initialized** means `init!`
has completed boundary zero, the initialization boundary run as the ordinary
macro-sequence with an empty integrate ([§14.5][s14-5]).

Beside the state, a simulation carries an **[input mode](#g-input-mode)**,
`:live` or `:replay`, read as `mode(sim)`. The mode names where the next
frame's [drain](#g-drain) takes its batches from, the staging cells or an
attached recording ([§12.7][s12-7]). State and mode are orthogonal. The
state says whether the simulation may advance, and the mode says what it
will advance on.

**Rule.** `init!` is mandatory.

`run!` or `step!` on a simulation whose [boundary](#g-boundary) zero has not
completed is an error in the kind set ([§13.2][s13-2]) naming `init!`. That
is distinct from `UninitializedInputs`, which fires *inside* `init!`
([§14.6][s14-6]). `replay!` is the one alternative entry. It runs boundary
zero from a [trace header](#g-trace-header) ([§12.7][s12-7]). A throw inside
boundary zero, under either entry, leaves the simulation `built`
([§13.4][s13-4]), so the next `run!` or `step!` meets the same refusal.

**Where the loop runs.** The loop runs on the [calling task](#g-calling-task),
the task that invoked `run!`, unless a calling-task [device](#g-device) is
rostered. That device is the GUI, and the topology is derived from the
[roster](#g-roster) ([§11.1][s11-1]). Deviceless, `run!` is fully
synchronous. That is the unattended register. An
[unattended run](#g-unattended-run) is the same loop with empty staging
([§11.1][s11-1]). It is also what the synchronous rethrow presupposes
([§13.4][s13-4]).

**Partial advance.** `step!(sim; frames = 1)` advances whole frames
synchronously through the ordinary frame sequence ([drain](#g-drain),
integrate, boundaries, publication) and returns. A stepped simulation is
bit-identical to the same frames under `run!`. `step!(sim; t_plus = 10.0)`
is the duration spelling, mutually exclusive with `frames`. It advances
whole frames until the boundary time first covers the duration, which is
the migration suite's advance-by-duration idiom.

Partial advance is the test-harness register: advance, assert, advance. It
is equally the REPL register: fly a while, inspect, continue. Neither is a
script, so the scenario-[component](#g-component) doctrine does not absorb
them ([§12.5][s12-5]).

**A stepping session is deviceless by construction.** Device tasks are
per-`run!` artifacts ([§11.1][s11-1]), and a device loop's
`while running(handle)` is false outside a run. Between `step!` calls the
simulation is in a stopped-sim state, `initialized` (below), so `attach!` is
legal there and does what it always does. It registers ([§11.3][s11-3]), and
the task appears at the next `run!`.

**The [frame-top drain](#g-drain) still runs**, so `step!` frames stay
bit-identical to `run!` frames. What it drains is the **harness
[cell](#g-harness-cell)**. The harness write path is
`stage!(sim, "face" => value, …)` ([§11.3][s11-3]), with the calling task as
writer. Staged batches are ordinary batches. They are traced, so
[replay](#g-replay) and bit-identity hold. They are applied at the next
frame top. They are surface-checked like any writer's ([§11.3][s11-3]).

The read half is `latest(sim)`. It hands back the same immutable
[snapshot](#g-snapshot) value a device handle acquires ([§11.2][s11-2]),
navigated directly for assertions. Advance-assert-advance is `stage!` →
`step!` → `latest`. Both entry points work under `run!` too. The
[harness cell](#g-harness-cell), the always-present staging cell of the
harness register, is not step-scoped. An inspection accessor leaves the
rejection of closure-based termination ([§13.5][s13-5]) untouched.

**Status, termination and the `run!` [seam](#g-seam).** Between `step!`
calls a simulation reports **initialized**. No loop task exists, so
`running` would lie. Nothing is terminal, so `stopped` would lie too. The
state reads "boundary-consistent and ready to advance", not "sitting at
boundary zero". `run!` may therefore follow `step!`, continuing from the
current boundary, and so may another `step!`.

Termination policy is honored throughout, as bit-identity requires. `t_end`
reached, or a `stop_on` [face](#g-face) [holding](#g-edge-semantics) at
frame 3 of `step!(sim; frames = 10)`, ends the run there through the
ordinary [§12.4][s12-4] tail and leaves the simulation `stopped`. `step!`
therefore returns the number of frames **actually advanced**. That is the
requested count in the ordinary case, and fewer when the run terminated
inside the call. That return is how a harness detects the truncation without
inspecting the clock.

**Re-running: `stopped → init! → run!` is the supported cycle.** `init!`
re-runs boundary zero from its condition. The warm restart is `capture` →
tweak → `init!` ([§14.1][s14-1]). `init!` clears the [trace](#g-trace), the
log, the [termination record](#g-termination-record) ([§13.5][s13-5]), *and*
any batches still in [staging cells](#g-staging-cell). The
[recorders](#g-recorders) restart with the run they record, and no stale
batch survives to clobber the boundary zero it predates. `init!` also
returns the input mode to `:live`, and a fresh `replay!` sets the mode
exactly as it sets the trajectory. `live!` is the third door, and the only
one that moves the mode alone. It takes a replaying simulation live where it
stands ([§12.7][s12-7]). A terminal state makes the mode moot. Nothing
advances until one of those three doors is taken ([D-218][d-218],
[D-219][d-219]).

**Device attachments persist across re-initialization**, because attachment
is orthogonal to the run lifecycle ([§11.3][s11-3]). Persistence means
*roster* persistence. Binding, [claims](#g-claim) and device id survive.
Tasks and OS resources do not (the per-run topology, [§11.1][s11-1]; the
teardown, [§12.4][s12-4]). Each `run!` re-initializes every rostered device
and spawns its task. `attach!` while stopped only registers, and the task
appears at the next `run!`.

**Task topology follows the roster each time** ([§11.1][s11-1]). A GUI
attached *by hand* is still rostered, so the next `run!` renders it again,
with the loop on a spawned task, whether or not `gui = true` is repeated.

**The `gui = true` flag itself is run-scoped.** At run entry it attaches the
standard GUI device under the greedy binding, with `should_abort = true`,
iff no GUI is rostered ([Appendix B][sB]). The run's shutdown tail detaches
it again ([§12.4][s12-4]). So the roster a flagged run leaves behind is the
roster it found, and a window on every run means the flag on every run. A
*persistent* GUI session is spelled by hand: `attach!` while stopped,
`detach!` when done. Against a hand-attached GUI the flag does nothing and
detaches nothing, having attached nothing.

**What the scoping buys is the absence of a trap.** The flag's GUI claims
everything unclaimed at attach (the computed source, [§11.3][s11-3]), and a
claim of that shape must not outlive the run that asked for it. A joystick
attached between two runs would otherwise meet a `ClaimConflict` against an
everything-claim staked by a convenience argument nobody remembers passing.

**The accepted cost is a fresh device id per run for that GUI.** Ids exist
to be read *across* roster changes, and each run's trace header carries its
own schemas ([§11.5][s11-5]). Nothing that reads a completed run is
therefore affected.

**Run policy is re-bindable per cycle.** `t_end` and `stop_on` are
`Simulation` defaults that `run!` may override for the run it starts
([§13.5][s13-5]). A second run, or a `step!` register between two runs, can
therefore stop on a different clock or a different face set without a
rebuild.

**`errored` is terminal** ([D-059][d-059]). Reproduction is trace replay
([§12.7][s12-7]), not resurrection.

### 12.7 Replay: the trace re-drives the ordinary loop

The entry point the [§11.5][s11-5] [trace](#g-trace) exists for:

```julia
trc  = trace(sim)                     # the recorded session: header + per-frame batches
sim2 = Simulation(world)              # the same build
replay!(sim2, trc)                    # header-init, then re-drive every recorded frame
replay!(sim2, trc; to_boundary = k)   # partial: the §13.4 replay-pointer register
replay!(sim2, trc; to_time = 100.0)   # partial: the same halt addressed by time
```

`replay!` is **the ordinary loop with exactly two substitutions**, not a
second loop. That is what keeps every property proved of the loop true of
[replay](#g-replay):

- **[Boundary zero](#g-boundary-zero) from the header.** Boundary zero is
  the initialization boundary, the ordinary macro-sequence with an empty
  integrate. `replay!` stands in the `init!` position of the lifecycle
  ([§12.6][s12-6]). It applies the header's resolved stores and
  [root input](#g-root-input) values directly. There is no condition
  resolution, and the totality ([§14.6][s14-6]) holds by capture. It then
  executes the ordinary [boundary](#g-boundary)-zero sequence
  ([§14.5][s14-5]). Authored-condition events re-fire identically. The
  header predates the sequence (the capture placement, [§11.5][s11-5]), so
  nothing is applied twice and nothing is skipped.
- **The [drain](#g-drain) reads the trace.** Each frame top applies the
  recording's batches for that **[frame ordinal](#g-frame-ordinal)**, the
  frame index a batch replays at. It does not swap the [roster](#g-roster)'s
  [staging cells](#g-staging-cell), where a device's pending write batch
  waits between drains. Ordinal keying is exact because the frame sequence
  is itself deterministic under replay (`t*` boundaries derive from state,
  [§10.4][s10-4]). Frame *k* of the replay *is* frame *k* of the recording.
  Recorded batches apply **verbatim, with no surface re-check**. The
  write-surface rule ([§11.3][s11-3]) ran at recording time, and
  [claims](#g-claim) are a live-roster fact of the recorded session that
  replay does not reconstruct.

**Rule.** A simulation is in one of two [input modes](#g-input-mode),
`:live` or `:replay`, and the mode decides which source that one drain
branch reads: the [staging cells](#g-staging-cell) under `:live`, the
attached recording under `:replay`. `replay!` attaches the recording and
enters `:replay`. `step!` and `run!` consume it from there, frame by frame,
exactly as the bullet above describes. There is still one loop and one drain
([D-218][d-218]).

**Why.** A mode that outlives the call makes a partial replay a resumable
position rather than the end of an operation. Whatever advances the
simulation next reads the same register and finds the same records. That is
what lets the reproduction workflow of [§13.4][s13-4] run through the
ordinary entry points, with no replay-only spelling of `step!`. That
workflow halts at the frame top the error names, then `step!`s the failing
frame on its recorded inputs.

Everything else is the loop as already specified:

- **Termination and partial replay.** In `:replay` the recording is the
  bound. Every advance's frame budget is capped at the recording's last
  frame, and `to_boundary = k` caps it earlier. That keyword is the consumer
  of the replay pointer ([§13.4][s13-4]). `to_time` is the same cap
  addressed by time, the next bullet. The `to_boundary` spelling is defined
  as running **through the frame whose execution published boundary `k`**,
  so replay always halts at a frame top. For a grid boundary the halt is
  exactly at `k`, the frame that publishes one ending at it. The frame-entry
  pointer ([§13.4][s13-4]) lands the same way. A [localized](#g-localized)
  `t*` boundary inside the frame (the crossing instant bracketed by
  root-finding over trial sweeps) is reproduced but not stoppable-at.
  [§10.4][s10-4] separates the two indices. The trace stays frame-indexed,
  and boundaries are the reporting index. Replay may also end earlier still
  under the ordinary policies, since `t_end` and `stop_on` overrides bind
  for this replay exactly as at `run!` ([§12.6][s12-6]). A termination the
  recorded session hit through `stop_on` reproduces itself anyway,
  deterministically.
- **`to_time` addresses the same halt by time.** The keyword is mutually
  exclusive with `to_boundary`, and it halts at the **last frame top at or
  before** the time given: `k = ⌊(to_time − t₀)/h⌋` against the header's
  `t₀`. A time falling between two frame tops floors onto the earlier one.

  The rounding is the deliberate opposite of `t_end`'s, which ends a run at
  the first grid boundary reaching or exceeding it ([§12.4][s12-4]). `t_end`
  bounds a run, and `to_time` positions an inspection. The point of halting
  is to stand *before* the anomaly, so a halt that stepped past it would
  defeat the call ([D-219][d-219]).

  Validation is the other keywords'. The value must be real, finite and at
  least `t₀`, and it must name a time the recording covers. The checks run
  before the replay writes anything, boundary zero included.
- **The halt flips the mode only at the recording's end.** A frame budget
  that runs out halts the loop at a frame top, leaving the simulation
  `initialized` ([§12.6][s12-6]). The mode becomes `:live` exactly when that
  halt lands at the recording's last frame, with the records exhausted. It
  stays `:replay` otherwise, and the next `step!` or `run!` goes on
  consuming the recording. So no advance ever flips mid-run. A `run!` whose
  `t_end` lies past the recording halts at the last recorded frame, now
  `:live`, and the *next* call is the live continuation ([D-218][d-218]).
- **`live!` is the mode's one manual door.** The flip above is automatic,
  and it happens only at the recording's end. `live!(sim)` performs it by
  hand. It sets the mode to `:live` and detaches the recording's remainder,
  touching nothing else. The trajectory stands where the replay left it, and
  so does the trace register with the header it inherited. The next `run!`
  or `step!` is therefore the live continuation from the replayed boundary,
  and its drains append to the re-recorded prefix. `live!` is a stopped-sim
  operation, legal only on an `initialized` simulation in `:replay`.
  `:running` and `:errored` refuse under the ordinary lifecycle gates
  ([§12.6][s12-6]), and a simulation already `:live` refuses too. The call
  would have nothing to do, and a loud refusal beats a silent no-op
  ([D-219][d-219]).

  That door is what makes the rewrite workflow real. An interactive session
  is interrupted at t = 110, and the last ten seconds are to be flown again:

  ```julia
  trc  = trace(sim)                     # the interrupted session, out to t = 110
  sim2 = Simulation(world)
  replay!(sim2, trc; to_time = 100.0)   # halt at the last frame top at or before 100
  latest(sim2)                          # inspect the boundary landed on
  live!(sim2)                           # drop the remainder; the mode is :live
  run!(sim2; t_end = 130.0)             # live from t = 100, re-recording onward
  ```

  The trace `sim2` leaves behind is a complete recording of *itself*: the
  replayed prefix out to t = 100, then the frames flown live after it.
- **Replay ends `initialized`, never `stopped`.** That state is
  boundary-consistent and ready to advance, the same state `step!` leaves
  ([§12.6][s12-6]). This is what makes three promised workflows real.
  State-trajectory inspection asks "what was the private state at
  t = 37.2?", and answers it by replaying there and reading the live stores
  ([§11.2][s11-2]). Error reproduction replays to `k − 1`, then `step!`s the
  failing frame under instrumentation ([§13.4][s13-4]). Continuation is
  `run!` after `replay!`, a live session from the replayed boundary. After a
  full replay that is the next call, the records exhausted at the halt.
  After a partial one the remainder of the recording is consumed first,
  across as many `step!` and `run!` calls as the caller makes, and the
  session goes live at the recording's end. Or `live!` drops that
  remainder, and the continuation starts at the halt.
- **Replay re-records.** The trace register runs normally. The new trace
  inherits the old header and accumulates the re-drained batches, a
  bit-identical prefix. A replayed-then-continued session therefore leaves
  behind a complete, valid trace of *itself*, with no special stitching.
- **[Pacing](#g-pacing) and the [control plane](#g-control-plane) are
  unchanged** ([§10.7][s10-7], [§12.1][s12-1]). Pacing (waits inserted
  between completed frames, never altering the boundary sequence) sits
  outside the semantics, so paused, slow-motion or real-time replay is free.
  Paced replay with an attached visualizer *is* session playback. Stop
  truncates, as anywhere.
- **[Devices](#g-device) are readers.** Rostered devices init and spawn
  normally ([§11.1][s11-1]) and consume [snapshots](#g-snapshot)
  ([§11.2][s11-2], [§12.3][s12-3]). That is the visualizer case. But no live
  staging [cell](#g-staging-cell) is drained while the simulation is in
  `:replay`. A batch found staged is discarded with a rate-limited warning
  (`ReplayDiscardedStaging`, [Appendix C][sC]). Mixing live writes into a
  replay would destroy the property replay exists to provide. A session that
  wants live input is a continuation (`run!` after replay), not a replay.
- **Validation is loud and up front.** Before the first frame, the header is
  validated against the `Build` (store layout, root input
  [faces](#g-face)), the trace's batch entries against the root input-face
  list, and each batch's frame ordinal against the recording's length
  ([D-217][d-217]). Each writer's face-name → position schema
  ([§11.5][s11-5]) is **validated** in the same pass. A recorded schema that
  disagrees with the target model's own root-input faces is a replay error.
  The checks are attach-style, and a failure reports
  [did-you-mean](#g-did-you-mean): the offending name plus the list-in-hand
  it should have matched. The kinds are `ReplayHeaderMismatch`,
  `ReplaySchemaMismatch` and `ReplayUnknownFace` ([Appendix C][sC]).

  The same pass pays the trace-record conversion in reverse. Every writer's
  sparse records ([§11.5][s11-5]) are normalized to positional batches
  against the header's schemas, once, off the loop. Replay has the whole
  trace in hand before frame 1. The replay drain therefore applies compiled
  scatters exactly as the live drain does, and no face name is resolved per
  frame under replay either.

  *Structural* mismatch is an error. *Parametric* difference is not.
  Replaying against the same structure with changed parameters is the
  **[what-if register](#g-what-if-register)**, the deterministic re-driving
  of the recorded inputs through a modified model. Bit-identity is promised
  only against the identical build. The what-if register promises
  determinism, never reproduction.

  The header's deployment block ([§11.5][s11-5]) validates in the same pass,
  on the *structural* side of that line. The seven trajectory-determining
  parameters are `Δt_base`, `h`, `N_base`, the algorithm,
  `localization_tol`, `localization_budget` ([§10.4][s10-4]) and
  `firing_budget` ([§10.6][s10-6]). All seven are compared against the
  target `Simulation`'s own deployment binding. Mismatch is
  `ReplayHeaderMismatch` with a deployment-parameter discriminator, never a
  what-if. A deployment change moves the times at which the frame-ordinal
  batches apply. That is different inputs, not a modified model. The event
  trio (the localization pair and `firing_budget`) is compared for exactly
  the same reason the grid parameters are. It moves the trajectory, so a
  run that differs in it is not re-driving the recorded one.

  `t₀` is *applied*, not compared. Replay stands in the `init!` position and
  owns the anchor, so `replay!` takes no `t0` argument. The header's
  `t_end`/`stop_on` pair is a recorded fact of the recorded session, never a
  constraint on this one. Overrides bind as stated above.

The dispositions, by header content:

| header content | disposition |
|---|---|
| store layout, root-input faces | compared against the `Build` |
| the deployment block's seven trajectory-determining parameters: `Δt_base`, `h`, `N_base`, the algorithm, `localization_tol`, `localization_budget`, `firing_budget` | compared against the target `Simulation`'s own deployment binding |
| each writer's face-name → position schema | validated against the target model's root-input faces: disagreement is a replay error |
| resolved stores, root-input values | applied directly at boundary zero |
| `t₀` | applied; `replay!` takes no `t0` argument |
| `t_end`, `stop_on` | neither compared nor applied: a recorded fact of the recorded session |

Rejected shapes, for the record ([D-101][d-101]): a `run!(sim; replay = trc)`
flag, a synthetic playback device staging the recorded batches, and replay
ending `stopped`. The mode register clarifies that decision's second
substitution rather than replacing it, and carries its own rejected shapes
([D-218][d-218]).

---

# Part IV — Failure and services

Part IV covers what happens when things go wrong, and what a stopped simulation
can be asked to do. [§13][s13] is the error discipline. It fixes which failures
are collected and which fail fast, and the diagnostic value both produce. It
fixes the single runtime catch site and the execution cursor that locates a
failure inside a frame. And it explains why graceful termination is model state
rather than an exception. [§14][s14] is the stopped-sim services.
[§14.1][s14-1]–[§14.6][s14-6] build the condition (a path-addressed overlay on
the declared defaults) and apply it through boundary zero. Applying a condition
is the initialization service. [§14.7][s14-7]–[§14.10][s14-10] build trim and
linearization on that same foundation.

Part IV assumes both earlier parts. [§9.1][s9-1] already fixed when each check
runs, so [§13][s13] fixes only how a failure is reported once it happens.
[§8.6][s8-6] supplies the paths a condition addresses. [§9.4][s9-4] supplies the
activations trim and linearization run on. [§10.6][s10-6] supplies the
macro-sequence that boundary zero re-runs with an empty integrate.

## 13. Error discipline

[§8.4][s8-4] fixed what must be caught and where. [§9][s9] fixed when each fact
is checked. This section fixes how failures are *reported*. It covers the
reporting policy, the diagnostic representation, the runtime failure story, and
the seam between "the model reached a terminal state" and "the run should end".
Two lessons FlightCore paid for ground it. The first is the compact-backtrace
discipline, needed because parameterized model types make rendered output
unreadable. The second is the `SimulationTermination` machinery, which
[§13.5][s13-5] replaces.

### 13.1 Reporting policy: collect the checks, fail the evaluations fast

The build's failure sites split into two populations. That split settles the
choice between fail-fast and compiler-style reporting. Each population takes
the policy that fits it.

- **Declarative checks over collected structure collect.** These are the
  checks for unconnected inputs, two producers, wire typos and type mismatches,
  [face](#g-face)-name uniqueness, `output_types`/state-field consistency and
  `sample_times` validation. Each is a pass over a list. The whole-tree
  obligation check literally computes *the set of* inputs whose obligation
  chain never terminates. Reporting every violation is the natural output of
  such a pass, and truncating to the first would be extra work. These failures
  also cluster in practice. A freshly written [assembly](#g-assembly) has five
  unwired inputs, and a renamed [port](#g-port) breaks three wires. Each of
  these passes returns its full violation list.
- **User-code evaluation fails fast.** User code runs in three places. The
  first is the interface-connection bodies in [Stratum](#g-stratum) A (one of
  the build's three phases: structure, schedule, activation). The other two
  are the stage-1 [probes](#g-probe) in B and the probe chain in C. When user
  code throws,
  there is no meaningful rest of the collection to report. A failed
  `input_connections` leaves the parent's face derivation undefined. A failed
  stage-2 probe starves every downstream probe of its wired inputs, because
  [probe values](#g-probe-value) flow topologically ([§9.3][s9-3]). The first
  user-code exception aborts the phase ([D-057][d-057]).

Strata are barriers. A stratum that produced any error-severity diagnostic, of
either kind, throws before the next stratum begins. Probing against unresolved
wiring would be meaningless.

**Rule.** Collection reaches the stratum barrier, under a dependency rule. A
declarative pass runs when the results it reads are clean. It records every
violation it finds and returns a total result. Every pass that ran merges into
the barrier's one throw ([D-229][d-229]).

Whether a pass can run past a failure follows from what it reads. Stratum A's
walk yields two results, the component list and the wiring. A wire that fails
to resolve is recorded and claims nothing, so the obligation check reports its
input as unfed. Tier and event checking read only the component list, so they
run and merge. A structural failure leaves the subtree behind it unknown. An
unreadable or mixed class or a malformed container is such a failure. No pass
can read past it, so it throws alone. In Stratum C the probe chain consumes
each check's subject as it goes. A check that reads a failed probe does not
run, so the chain's fail-fast follows from the same rule. Outside the strata
the unit is the call. Deployment validation ([§9.1][s9-1]) runs every check
whose premise holds and throws once. The only partial results ever carried past
a failure are violation lists and a claim table with the failed wires absent.
None of the three strata therefore needs machinery for carrying partial
internal results across a failure. That machinery was the cost that kept this
decision open, and it never materializes.

**There is no cascade suppression within a stratum.** This is a deliberate
simplification ([D-057][d-057]). A wire typo'd as `:throtle` produces two
errors. One is a [did-you-mean](#g-did-you-mean) error (the offending name plus
the list-in-hand it should have matched). The other is an unconnected-input
error for the intended `throttle`. Both are reported. They render adjacently,
because diagnostics sort by path, and the pairing explains itself.

### 13.2 Diagnostics: structured values, one carrier exception

Both reporting policies move the same thing. What a collecting pass returns and
what a fail-fast site produces is in either case a *diagnostic*. The shape of
that value decides what an acceptance test can assert and what a user reads.

**Rule.** A diagnostic is a plain value from a small closed set of
[kinds](#g-kind) ([D-058][d-058]). **[Appendix C][sC]** enumerates that set
normatively. For each kind it records the kind name, the [payload](#g-payload)
fields, the owning section, the severity, where the kind is raised and under
which policy. That index is the artifact the [§8.4][s8-4] acceptance tests and
the error-message work are written against. Each kind carries its own
structured payload. The payload holds endpoint paths, [face](#g-face) names,
expected and observed types, and the *list-in-hand* a
[did-you-mean](#g-did-you-mean) needs (the offending name plus the list it
should have matched). A kind *is* a Julia type. Severity is a property of the
kind, not of the occurrence. It is `error` or `warning`, and it says whether an
occurrence ever throws. It is read as `severity(d)` and never stored per
occurrence. The severity field of [Appendix C][sC] is derived from it. Where an
occurrence surfaces (build, service or runtime) and how it is reported
(collected, fail-fast, logged or rate-limited) are the *raised* and *policy*
fields of [Appendix C][sC]. Those two fields describe the occurrence, not the
kind. `BundleFieldError`, for example, is raised at the probe and as a
`StepError` [species](#g-species) thereafter.

Checking passes return diagnostics. The [stratum](#g-stratum) barrier (a
stratum is one of the build's three phases: structure, schedule, activation)
throws a single `DiagnosticError` wrapping the collection. A fail-fast site
throws the same carrier holding one diagnostic. **The carrier's type parameter
spells the policy.** It is the diagnostic's kind for a fail-fast throw and
`Vector{Diagnostic}` for a collected one. A test therefore asserts policy and
kind at once with `@test_throws DiagnosticError{Kind}` ([D-222][d-222]). The
runtime carrier follows the same rule. `StepError{C}` carries the type of its
`cause`, so a species is `StepError{Kind}` ([§13.4][s13-4], [D-225][d-225]).
`showerror` renders a collection compiler-style, grouped by kind and sorted by
path. It renders a single diagnostic as its own line.

```julia
# a diagnostic value: its kind is its identity, its payload is plain data
abstract type Diagnostic end
struct WireTypeMismatch <: Diagnostic   # one kind of the closed Appendix C set
    …                                   # payload fields per Appendix C: paths and
                                        # names as Strings, port types as types
end

# the carrier: one exception, its parameter the policy — a kind for a
# fail-fast throw, the collection type for a barrier's batch
struct DiagnosticError{P <: Union{Diagnostic, Vector{Diagnostic}}} <: Exception
    carried::P
end
```

A user-code exception is wrapped in a framing diagnostic, with the original
exception as `cause`. The frame carries the [component](#g-component) path, the
function that threw, and the [probe](#g-probe) context including the
synthesized inputs. The didactic frame therefore renders first and the raw
throw second.

One class of exception is recognized rather than merely framed. A `FieldError`
carries its type and field as data. The framework matches them against the
[bundle](#g-bundle)'s own NamedTuple type (the NamedTuple of zero-copy views a
component function receives). The result is the bundle-law did-you-mean
([§5.2][s5-2]). It carries the legal field set and classifies the miss as an
undeclared store, a wrong [tier](#g-tier), or a field illegal for this
function. Nothing is recovered by reading message text.

The [§8.4][s8-4] walkthroughs, run as acceptance tests, target diagnostics.
Tests match on kind plus payload fields, never on message text. Messages are
therefore pure presentation.

Two rendering rules are doctrine, not style.

- **Strings, never instances.** Diagnostics carry paths and names as strings,
  never component instances and never model types. This is the
  `compact_backtrace` lesson. Expected and observed *[port](#g-port)* types are
  the one payload exception, and they are small. Examples are a `Float64`
  against a `Bool`, and a NamedTuple field diff.
- **The didactic [register](#g-register) is policy.** Every diagnostic states
  the fix or the lists-in-hand, not just the violation. Examples are "return
  `zero(x.ω)`, not `0`" and "no input `throtle`; did you mean `throttle`?", or
  the child's face list shown alongside the unknown `except` entry.

**There are two [warning streams](#g-warning-streams), scoped separately.** The
*build* diagnostic stream is the one the build kinds ([Appendix C][sC]) ride.
Warnings there carry warning severity, render with the collection, and never
trigger the throw. That stream's warning set is **currently empty**. Its sole
candidate, the unconnected-output warning, was rejected ([§6.1][s6-1],
[D-084][d-084]). An empty, trusted stream is better than a noisy one. A
warnings-as-errors CI switch could be added, but is not built.

The *runtime* status/log stream is a different channel, and it is not empty. It
is per-occurrence. The per-writer [diagnostic cells](#g-diagnostic-cell) (the
single-writer cell each writer owns for diagnostics and heartbeat) carry it
([§11.8][s11-8]). The rate limit lives in the cells, as a structural bound
rather than a policy layered over the stream. The bound is a bounded ring plus
per-kind suppressed counts, drained at frame top. So "rate-limited wherever its
source can repeat" holds of every kind below without any kind arranging it. The
stream surfaces through the published [framework status](#g-framework-status)
([§11.2][s11-2]). The [§10.7][s10-7] pacer diagnostics and the [§12.2][s12-2]
liveness heartbeats ride in the same [cells](#g-diagnostic-cell) and surface
beside it. The stream is never collected, since there is no collection to
join. Nothing in the argument of [D-084][d-084] applies to it. That decision is
about what the *build* warns on.

A *service* warning (`TrimCommitEvents` and `TrimCommitResiduals`,
[Appendix C][sC]) belongs to neither stream. It is a synchronous per-call
annotation. A stopped-sim service call emits it once at return, beside the
value it returns, with its payload duplicated as plain report fields. There is
no carrier cell, no collection and no rate limit to arrange. The committed
runtime warnings, in one place, are these.

- **[Chattering](#g-chattering), or localization-budget exhaustion**
  ([§10.4][s10-4]). A [localized](#g-localized) event's bracketing budget runs
  out at a [boundary](#g-boundary).
- **Firing-budget exhaustion** ([§10.6][s10-6]). An event has spent its
  `firing_budget` at a boundary, and its further edges there are dropped.
- **Forgiven-debt re-anchor** ([§10.7][s10-7]). The pacer abandons its
  accumulated debt and re-anchors its schedule.
- **The write-surface and entry violations** ([§11.3][s11-3]), all raised at
  staging. The [drain](#g-drain) checks nothing. `OutOfClaimEntry` is an
  enumerated surface's binding drift, a name with no position in the
  attach-compiled schema. `ClaimedFaceEntry` is a harness write to a face
  claimed in the run's frozen partition, and it names the incumbent. The
  stopped-sim attach also fires it when it renormalizes a pending
  [batch](#g-batch). `EntryTypeMismatch` is a value unconvertible to its
  [root input](#g-root-input)'s declared type, rejected at staging for every
  writer.
- **A tolerated [device](#g-device)-side datum failure** ([§11.6][s11-6],
  [§13.4][s13-4]). `MalformedDatum` is emitted by the author's loop via
  `report!(handle, …)` into the device's own cell ([§11.8][s11-8]). It succeeds
  `InputMappingError`.
- **Staging discarded during [replay](#g-replay)** ([§12.7][s12-7]).
  `ReplayDiscardedStaging` reports a live batch found staged while the
  [trace](#g-trace) feeds the drain.
- **Thread-budget tightness** ([§12.2][s12-2]). Raised once per `run!`, against
  the frozen [roster](#g-roster).
- **Device join timeout** ([§12.4][s12-4]). A device task exceeds the shutdown
  join timeout and is abandoned by name rather than hanging `run!`. It arises
  after the terminal snapshot. It is therefore collected into the
  [termination record](#g-termination-record) and presented through the
  logging backend, never carried into a status ([D-201][d-201],
  [D-203][d-203]).
- **Device crash** ([§12.4][s12-4], [§13.4][s13-4]). The framework wrapper
  catches a device task's failure, and the sim continues with the device
  absent.
- **Unbounded run** ([Appendix B][sB]). At run start there is no finite
  `t_end`, no `stop_on` faces, and `pace = Inf`.

### 13.3 Build primitives: `resolve` and the face-list accessors

The `input_passthrough` sketch ([§8.8][s8-8]) calls two of the primitives below
without defining them. All three are normative in the forms given here.

- `resolve(asm, path::String) → AbstractComponent` is the getfield walk along
  `/`-segments.
- `input_faces(c)` / `output_faces(c) → Vector{String}` return the stringified
  keys of a leaf's `input_types` / `output_types` (the key set is
  `T`-independent). For an [assembly](#g-assembly) they return the entries of
  `input_connections(c)` / `output_connections(c)`. Declaration order is
  preserved, which gives deterministic printouts and stable diagnostics.
- `resolve_terminal(asm, path) → (component, name)` splits off a terminal
  path's final segment and resolves the prefix through `resolve`. The split is
  unambiguous because [face](#g-face) names may contain dots but never slashes
  ([§8.6][s8-6]).

**The walk enforces two duties, and they belong to different clients.** The
first is the one-level rule ([§6.1][s6-1]). A connection endpoint resolves to
an immediate child and one of its [faces](#g-face). A wiring path reaching
further is a build error, whatever the declared field types along it. The
second is the generic-holding rule, which governs the deep paths the read side
still writes. The walk follows *declared field types* alongside instances. A
segment that traverses **past** a generically-held field (one whose declared
type is non-concrete) is a diagnostic, even though the concrete instance in
hand would resolve it. Resolving *to* a generic child is [port](#g-port)-level
access and legal. An unknown segment errors with the sibling field list in
hand.

**The duty is [register](#g-register)-scoped.** The line between load-bearing
and diagnostic clients ([D-083][d-083]) carries into resolution. Client policy
rides on one primitive. The two application registers over one plan
([§14.4][s14-4]) use the same arrangement.

| register | who resolves under it | what the walk enforces |
|---|---|---|
| **structural** | wiring resolution, in [Stratum](#g-stratum) A (one of the build's three phases: structure, schedule, activation) | the one-level rule: an immediate child and one of its faces |
| **load-bearing** | [condition](#g-condition) entries (the path-addressed sparse overlay that sets a build's state), trim `reads`, [taps](#g-taps) ([§14.3][s14-3], [§14.7][s14-7], [§14.10][s14-10]) | strict, evaluated **at the authoring or mount level** |
| **diagnostic** | [device](#g-device) read [bindings](#g-binding), GUI panels, [snapshot](#g-snapshot) and log inspection ([§11.2][s11-2], [§11.7][s11-7]) | the instance walk |

Each register's treatment has its own warrant. The structural register is the
one the law ([§6.1][s6-1]) lives in, so it applies that law verbatim. Under
one-level routing the generic-holding question never arises there, because an
endpoint stops before any field it could traverse past. The load-bearing
register evaluates at the authoring or mount level for two reasons. First, the
locality law is an authoring-level law, and absolute paths are a compiled
derivative ([§14.2][s14-2]). Second, the mount itself checks a mount prefix,
where the problem's authored names resolve through the export chain from the
mount point ([§14.9][s14-9]). So this register checks the authored path below
that prefix. The diagnostic register walks instances instead. A generic
[seam](#g-seam) is not an error for a client that never claimed
substitutability. "What is in *this* build" is the inspection register's
defining question. Drift still stays loud. An unknown path is an attach-time
`ReadBindingUnresolved` with a [did-you-mean](#g-did-you-mean) (the offending
name plus the list-in-hand it should have matched).

**The scoping is one principle, not three concessions.** What varies across the
registers is not how far a client is trusted. It is what a violation costs, and
where the cost lands. A diagnostic client claims no substitutability. It
addresses one build's instances, and a broken binding fails at attach, at its
own site, harming only the observer. A wiring entry is carried by the declaring
*type* and compiled into every instantiation. That is why its endpoints stop at
the boundary. A wire reaching past one would fail at substitution time, at a
different site, for whoever exercised the substitution the field advertised.
That is the non-local failure class the error discipline exists to eliminate
([§8.4][s8-4]). The rule is strict exactly where a promise depends on it, and
relaxed exactly where none is made ([D-083][d-083], [D-130][d-130]).
Strictness forbids nothing outright in the load-bearing register. Declaring the
field's concrete type restores the deep read legally, with the hard-coding
visible in the declaration itself. For wiring there is no deep route left to
restore, because the face chain is the route ([§6.1][s6-1]).

Which register a client resolves under is internal framework fact, never
user-facing API. The two `apply!` registers ([§14.4][s14-4]) have the same
status.

`resolve_terminal` is first-class because five clients share it across the
three registers. Wiring resolution is structural. Condition addressing
([§14.3][s14-3]) and tap resolution ([§14.10][s14-10]) are load-bearing.
Device-binding validation ([§11.2][s11-2]) and snapshot inspection are
diagnostic. The result is one splitter and one did-you-mean site.

### 13.4 Runtime failures: one catch site, an execution cursor

**Where caught.** The loop wraps each execution of the [boundary](#g-boundary)
macro-sequence (integrate → project → event iteration → [ticks](#g-tick) →
publication) in a single `try`. It never wraps per stage or per
[component](#g-component) ([D-059][d-059]). Framing information does not need
to be *caught* into existence. The [executor](#g-executor) (the compiled
execution form of the [schedule](#g-schedule)) maintains an
**[execution cursor](#g-execution-cursor)**, a plain mutable field in the loop
state recording where in the compiled schedule execution is. The cursor
records three facts. The first is the component path, as a schedule index. The
second is which function is running: `output_state`, `output_direct`,
`state_derivative`, `state_update`, a [guard](#g-guard), a handler, or
`state_projection`. The third is the boundary phase: integration stage *k*,
event round *r*, a localization evaluation at trial time, or tick. Maintaining
the cursor costs one cheap store per dispatch on a single-tasked executor, with
no allocation and no exception frames. It covers every user-code surface
uniformly, including the forgettable ones. Those are the [RHS](#g-flow)
evaluations at interior RK stage points, the guard evaluations at ITP/Brent
trial points, and the environment closures.

```julia
# the cursor: one mutable field of the loop state, overwritten per dispatch
mutable struct ExecutionCursor
    …    # what it records, per the prose above: component path (schedule
         # index), which function, and the boundary phase
end
```

**How handled.** The catch site wraps the original exception in `StepError`,
the runtime counterpart of the `DiagnosticError` carrier. A `StepError` carries
four things: the cursor's frame, the boundary time, the **frame-entry boundary
index**, and the original exception as `cause`. The frame-entry boundary index
is the [replay](#g-replay) pointer. It names the frame-top boundary at which
the failing frame began. That frame top is a grid boundary or
[boundary zero](#g-boundary-zero) (the initialization boundary: the ordinary
macro-sequence with an empty integrate), and it is always a legal replay halt
([§12.7][s12-7]). A `StepError` is rendered with compact frames per the
doctrine ([§13.2][s13-2]).

Conformance failure ([§9.5][s9-5]) needs no separate path. At the table-write
point it throws as every fail-fast site does, a `DiagnosticError` holding the
one diagnostic, and it arrives at the same catch site. **The species rule.**
The catch site unwraps a single-diagnostic `DiagnosticError` thrown inside the
guarded sequence, and the `StepError`'s `cause` is that diagnostic. A
[species](#g-species) of `StepError` is one whose `cause` is a diagnostic. The
conformance failure's species carries the field-diff [payload](#g-payload).
The rule keeps the catch site the only `StepError` constructor. A `StepError`
arriving at the catch site is therefore an invariant failure, while a runtime
check stays a plain thrower of its kind ([D-221][d-221]). A collected carrier
has no single kind and rides as `cause` unchanged. No runtime check throws
one.

**The cause's type is the carrier's parameter.** `StepError{C}` takes the type
of its `cause`, bounded to a diagnostic or an exception. A species is therefore
`StepError{Kind}`, and a raw throw is `StepError{ArgumentError}` and the like.
`isa StepError` matches both ([D-225][d-225]). A test asserts a species as
`@test_throws StepError{ConformanceFailure}`, the runtime spelling of the build
carrier's idiom ([§13.2][s13-2]). A collected carrier riding as `cause` is an
exception and falls under that arm. A bare value thrown deliberately by model
code is neither, and the constructor refuses it unframed. The framework does
not handle that throw ([D-225][d-225]).

```julia
# the runtime carrier: its parameter the cause's type — a diagnostic's kind
# for a species, the exception model code threw otherwise
struct StepError{C <: Union{Diagnostic, Exception}} <: Exception
    frame          # the cursor's frame at the catch
    t::Float64     # the boundary time
    boundary::Int  # the frame-entry boundary index: the replay pointer
    cause::C
end
```

Reproducibility holds by construction. Staged inputs are drained and recorded
to the [trace](#g-trace) at the frame top, *before* the boundary executes. So
the failing boundary's inputs are already in the trace when it fails. The error
names the frame-entry boundary `k` to replay to.
`replay!(sim2, trc; to_boundary = k)` halts exactly at that frame top. It halts
in `:replay`, the input mode that keeps the recording attached, so the failing
frame's record is still ahead of the simulation ([§12.7][s12-7]). `step!` then
applies that record and re-executes the failing frame under instrumentation,
[localized](#g-localized) boundaries included.

```julia
replay!(sim2, trc; to_boundary = k)   # halt at the frame top; still :replay
step!(sim2; frames = 1)               # re-execute the failing frame, instrumented
```

**Boundary zero is caught too, under the service's disposition.** Boundary zero
runs inside `init!` and `replay!`, which are stopped-sim services, not inside
the loop. Its macro-sequence executes the same user-code surfaces the loop's
does, with the cursor maintained through them, so the service hosts the same
catch. A throw inside boundary zero arrives as a `StepError` from the one
constructor. Its frame comes from the cursor, its time is `t₀`, and the species
rule applies. An `InterruptException` inside boundary zero is not model code
failing, and it has no stop path to take in a service. The host therefore moves
the lifecycle to `built` and lets it propagate raw. The pointer is `0`, and at
zero the recipe degenerates. Boundary zero is frame one's entry boundary too. A
pointer of `0` therefore names either boundary zero itself or frame one as the
failing frame, and `replay!(sim2, trc)` reproduces both. It re-runs boundary
zero from the captured header and, where that completes, frame one from the
record. The rendered recipe therefore names the bare replay at zero and the
halt-then-`step!` form elsewhere. The header is captured before boundary zero
runs ([§14.5][s14-5]), so the trace already holds the reproduction. What
differs is the disposition. Nothing was published and no run was open, so there
is no tail to take and no snapshot to promote. The simulation returns to
`built`. `run!` and `step!` refuse it and name `init!` ([§12.6][s12-6]), while
`init!` and `replay!` remain legal. The remedy for a condition that fails at
`t₀` is a corrected condition, and `init!` re-establishes every store before it
applies one ([§14.1][s14-1]). No [termination record](#g-termination-record)
is written. The stores may hold the half-transitioned `t₀` state until the next
`init!` resets them. They are retained for inspection, as an errored
simulation's are ([§13.6][s13-6]). `trim!`'s commit is an `init!`
([§14.8][s14-8]) and inherits the rule ([D-223][d-223]).

**The one exception never wrapped.** An `InterruptException` is not model code
failing. It is the operator's stop command ([§12.4][s12-4]). So the catch site
discriminates it and routes it to the stop path. The run takes the ordinary
graceful tail and ends `stopped`, never `errored` under a `StepError`. With the
boundary masking in force ([§12.4][s12-4]) the branch is unreachable in
practice. The interrupt is deferred to a frame-top or wait unmask point, and
never raises inside the guarded sequence. The branch is kept defensively,
because the cost of being wrong about that is a terminally errored session in
place of a clean stop.

**Disposition.** The `Simulation` ends in a terminal status, `stopped` or
`errored`, with the exception retrievable. A synchronous
[unattended run](#g-unattended-run) (a run with empty staging and no snapshot
readers) rethrows after the shutdown tail completes, so CI fails honestly. An
interactive session logs the rendered error and surfaces the status through
the control plane and GUI.

**The nonfinite check.** Divergence is not termination. Dynamics that blow up
(ground penetration, an unstable gain) produce NaNs that defeat guards. NaN
comparisons are false, so no declared condition will catch them. A loop-level
`isfinite` [sweep](#g-sweep) over `x` at boundaries fails fast as a `StepError`
species, naming the offending component's state block and the boundary. It
catches diverging models generally, not just post-terminal ones.

*Placement is the whole value.* The sweep is the boundary's **first act**. It
runs immediately after integrate returns, before `state_projection` and before
the boundary sweep. Run there, `NonfiniteState` names the component whose own
block diverged. Run later, the NaN has already propagated. It reaches an
innocent downstream component through the ordinary signal path and surfaces as
that component's lookup-table `DomainError`, or as an `InexactError` in its
conversion. That is the error-locality inversion ([§8.4][s8-4]), designed out
of the build tier and quietly reintroduced at runtime. One `isfinite` pass over
a flat [buffer](#g-buffer) is cheap enough that placement, not cost, decides.

*Scope: `ẋ` does not participate* ([D-157][d-157]). A nonfinite derivative
contaminates its own state block's step result within that very step. The `x`
check at the next boundary is therefore the same detection with identical
component attribution. And `ẋ` buffers are integrator scratch. They are
written per stage, meaningful only inside a step, and not boundary-consistent
in the sense the check is stated over.

**Domain separation.** [Device](#g-device)-side user code fails in the device's
own domain, because loop bodies and mappings run on the device task
([§11.4][s11-4], [§11.6][s11-6]). It fails in two classes. A genuine bug takes
the per-device crash path (liveness heartbeat, `DeviceCrash`) while the sim
keeps running. An unmappable datum is not a failure at all. The loop body
tolerates and reports it (`MalformedDatum`, [§11.6][s11-6]). The two failure
domains never mix. That is exactly what the no-shared-mutable-model decision
bought.

### 13.5 Termination is a state, not an exception

FlightCore's `SimulationTermination` idiom (model code throws, and the loop
catches and logs it as informational) has **no counterpart here**
([D-060][d-060]). The discipline is that **exceptions from model code are
always abnormal**. Graceful termination is model *state*, and it reaches the
loop through declared machinery.

- **Detection** is ordinary [guard](#g-guard)/handler/mode machinery. If the
  stop should be localized, declare the [predicate](#g-predicate) as a
  sign-form event. Such an event is [localized](#g-localized) (the crossing
  instant bracketed by root-finding over trial sweeps). Touchdown overload is
  precisely a zero-crossing. The boundary is localized to the crossing, the
  handler sets `m.crashed`, and the [snapshot](#g-snapshot) at the crossing
  instant carries the touchdown state.
- **Publication** is an ordinary `Bool` output [face](#g-face), exported to
  the root. The condition is gathered at its owning boundary in one visible
  block. `Ldg` ORs its three legs through a junction (the ownership idiom,
  [§6.2][s6-2]; the library, [§13.7][s13-7]) and exports one `damaged` face.
  Each [assembly](#g-assembly) above it re-exports that single face. That
  takes one `output_connections` entry per level ([§6.1][s6-1]), or
  `output_passthrough` where a level re-exports a child's surface wholesale
  ([§8.8][s8-8]). That hop is the substitutability [contract](#g-contract)
  doing its job, not plumbing (the imposed derived contract, [§8.8][s8-8]).
- **Policy** binds at deployment. `Simulation(world; …, stop_on = (…))` names
  root-exported `Bool` output faces. They are OR-combined, validated against
  the `Build`, and recorded in the [run metadata](#g-run-metadata), which is
  the [trace header](#g-trace-header)'s deployment block ([§11.5][s11-5]).
  After *every* published boundary the loop reads the named faces in the
  snapshot it just published. Grid boundaries, `t*` ([§10.4][s10-4]) and
  [boundary zero](#g-boundary-zero) ([§14.5][s14-5]) all count. The first
  `true` initiates [§12.4][s12-4] shutdown with *this* snapshot as the final
  one. The terminal snapshot is the terminal state. There is no roll-back, and
  nothing [§12.4][s12-4] does not already do. That terminal snapshot's status
  carries the run's final cumulative diagnostic counters ([§11.8][s11-8]).
  `run!` therefore checks the boundary-zero snapshot before the first step. An
  authored [condition](#g-condition) (the path-addressed sparse overlay that
  sets a build's state) that is already terminal ends the run at `t₀` with
  that snapshot final, integrating nothing. The default is no stop faces and a
  run to `t_end`. `stop_on` is `t_end`'s model-declared sibling at the same
  declaration site.

**Both are `run!`-time overridable, with the constructor value as the
default.** `Simulation(world; t_end, stop_on)` sets the defaults for the
simulation. `run!(sim; t_end = …, stop_on = …)` binds them for **that run
only**. The `run!` argument wins where given, and the constructor's value
stands where it is not. Nothing about the `Simulation` is mutated, so the next
`run!` without arguments gets the constructor's policy again. The run metadata
records the constructor's pair. A run's effective bound is reported by its
termination record when it fires ([D-217][d-217]). `stop_on` face validation
against the `Build` runs at **both** binding sites, identically. An unknown or
non-`Bool` face fails at `run!` exactly as it fails at construction.

```julia
sim = Simulation(world; h = 0.02, t_end = 60, stop_on = (…))  # the Simulation's defaults

init!(sim, cond); run!(sim)                # t_end = 60, stop_on as constructed
init!(sim, cond); run!(sim; t_end = 10)    # this run only: t_end = 10, stop_on as constructed
init!(sim, cond); run!(sim; stop_on = ())  # this run only: no stop faces, t_end still 60
init!(sim, cond); run!(sim)                # the constructor's pair again: nothing was mutated
```

This is not the root-declared stop policy rejected below. The `run!` argument
moves binding one notch *later* along the same axis, more deployment-flavored
rather than less ([D-060][d-060] and [D-091][d-091]). The
`stopped → init! → run!` cycle and the `step!` register ([§12.6][s12-6]) are
precisely where one `Simulation` wants different stopping policies on
different runs. The honest cost is two homes for one fact. The precedence rule
above settles it.

**The termination record names the source, as a typed value.** Where run
metadata carries the effective *policy*, the run's
[termination record](#g-termination-record) carries its *outcome*. The record
holds three fields: the final boundary time, the source, and the tail residue.
The tail residue is the post-account diagnostics the run's-end sweep folds in
([§11.8][s11-8]). The time is always present, because boundary zero precedes
every record and a throw inside boundary zero writes none ([§12.6][s12-6],
[D-233][d-233]). The source follows the diagnostic convention, so its kind is
its identity and its payload is plain data ([§13.2][s13-2]). It has four
kinds.

- `EndTimeReached` means `t_end`'s frame completed. It has no payload. The
  record's own `t` is the fact, and the configured bound lives in the run
  metadata.
- `ModelRequestedStop` means a named `stop_on` face read `true`. The payload
  is the holding face.
- `ControlRequestedStop` means a control-plane stop. The payload is its issuer
  ([§12.1][s12-1]): the requesting device, `:code`, or `:interrupt`.
- `LoopError` means the abnormal entry of [§13.6][s13-6]. The payload is the
  propagated cause. The record covers the `errored` terminal state exactly as
  it covers `stopped`.

A `stopped` simulation therefore answers "why did it stop?" without its
consumer reconstructing the answer from the clock. It answers "how did the
stop go?" from the same value. The
[operator interrupt](#g-operator-interrupt) is a tag on an ordinary stop, not
a [kind](#g-kind) of its own, because nothing failed. [Appendix C][sC] gains
nothing from it.

**Rule.** The sources are consulted in a fixed order. The loop checks a pending
control stop at frame top, then `t_end`, then the stop faces at each
publication. When two sources hold at one boundary, the recorded source is the
first in that order ([D-203][d-203]).

The taught contract is this. **Stop faces are sampled at completed boundaries;
declare a sign-form event if you need the stop localized.** Both stop-flag
shapes work without framework latching. A handler-set `m` flag is sticky by
nature. A transient stage-2 Bool is caught because the loop reacts to the
first `true`. Compound stop logic composes in-model, as a monitor
[component](#g-component) reading the relevant signals and outputting one
Bool. That is the same move [§12.5][s12-5] made for scripts.

Post-terminal dynamics are the model's job, and that is a feature. Today
`robot2d` *throws* when it falls, because it has no other way to say "my
dynamics are no longer meaningful". Here it declares the fall as an event,
switches to a frozen mode, and exports `fallen`. The frozen mode is a
mode-dependent `state_derivative`, machinery the model already has. Wired, the
sim ends at the fall. Unwired, it integrates a frozen robot, which is
well-defined, unlike an uncaught throw. The discipline forces models to have
well-defined terminal states, which is better modeling.

The rejected mechanisms are litigated in [D-060][d-060]. They are predicate
closures (`stop_when = snap -> …`), root-type-declared stop policy,
[blessed](#g-blessed) terminal types and `terminal` event flags, a
[control-plane](#g-control-plane) capability for [components](#g-component),
and observation-by-path (`stop_on` naming a deep path into any public output).
A root-declared *default*, overridable at the constructor, is the one variant
on record for reopening, should the constructor argument prove chronically
forgotten ([§16][s16]).

The observation-by-path line leaves doctrine behind it. **Diagnostic
observation** is human-facing, has no effect on run semantics, and
legitimately sees every public [cell](#g-cell). The log retaining the full
table, GUI panels rendering a component's [ports](#g-port), and
[replay](#g-replay) inspection are all diagnostic observation. **Load-bearing
observation** is a read that changes what the run *does*, and it must speak
the [contract](#g-contract). `stop_on` is the one read that changes what the
run does, which is why it alone names root-exported faces. Output devices are
the other half of the same doctrine. Their reads are diagnostic snapshot-path
bindings ([§11.2][s11-2], [§15.4][s15-4]).

The wall-clock channel (GUI stop button, device handle, code) is orthogonal
and untouched. That is the [control plane](#g-control-plane)'s operator path.
The sim-time, model-detected channel specified here meets it at
[§12.4][s12-4] and nowhere else.

### 13.6 Abnormal shutdown: one tail, two entries

**The [boundary](#g-boundary) is all-or-nothing outside the sim task.** That is
why a `StepError` cannot break [§12.4][s12-4]. [Sweeps](#g-sweep) write into
table blocks. Integration intermediates live in framework-owned integrator
buffers, never in a [component](#g-component)'s [workspace](#g-workspace) as
[§7.3][s7-3] defines it. The only externally visible act is
[snapshot](#g-snapshot) publication at the very end of the sequence. A
boundary that throws has published nothing. The last *published* snapshot is a
complete, consistent boundary by construction, and it is still the newest
thing any [device](#g-device), logger or waiter has seen.

The abnormal path therefore **discards the failed boundary, promotes the
previous snapshot to final, and rejoins the ordinary tail.** The protocol
becomes one tail with two entry points. Graceful entry follows a *completed*
final boundary, and abnormal entry follows a *discarded* one. Everything
downstream of "final snapshot" runs identically: sticky stopped, waiters woken
through the boundary-counter plus `Condition` path, `unblock!`/close hooks,
and named joins with timeout. Those waiters observe stopped rather than a new
boundary, so no device task hangs.

```
  graceful entry                      abnormal entry
  final boundary completes            failed boundary discarded
  final snapshot published            previous snapshot promoted to final
             |                                   |
             +-----------------+-----------------+
                               |
                       "final snapshot"
                               |
       sticky stopped → waiters woken → unblock!/close hooks
                     → named joins with timeout
```

This fills the seat [§12.4][s12-4] reserved for it. A loop-side failure runs
the same protocol from the catch path. The
[termination record](#g-termination-record) covers this entry too. Its source
is `LoopError`, and the payload is the propagated cause ([§13.5][s13-5],
[D-203][d-203]).

Tail hygiene follows from the hooks being user code too. Each is individually
caught and logged. Shutdown therefore runs to completion even if a device's
hook misbehaves. The join timeout already bounds a hook that hangs rather than
throws.

What is lost is quarantined. The state [stores](#g-store) may hold
mid-boundary values (a half-written `m`, integration intermediates). They are
retained on the errored `Simulation` for post-mortem inspection, but an
errored sim is terminally stopped, not resumable. The reproduction tool is
[trace](#g-trace) [replay](#g-replay), not resurrection. The stopped-sim
services enforce that non-resumability by refusing an errored simulation
outright (`ServiceLifecycle`, [§14][s14]). The roster operations refuse it
with them ([§11.3][s11-3], [D-232][d-232]). Inspection is reading, but
`attach!` configures a run that cannot follow. The published record (snapshot
chain, log, trace) ends at the last consistent boundary. Nothing downstream of
the sim ever sees half a boundary.

### 13.7 Tooling consequences: provenance and the component library

Termination chains are the second structural customer of computed interface
connections, after generic-holding [contracts](#g-contract). Computed
connections are therefore prominent in this section. Two commitments follow, a
library and an idiom.

**The passthrough helper pair grows deliberately.** Predicate-based selection
is a natural extension. It would add an `endswith`-style filter alongside
`except`/`only`, on `input_passthrough` and `output_passthrough` alike
([D-209][d-209]). It stays explicit at the declaration site, evaluated at
build, and printable. That is the [blessed](#g-blessed) side of the
auto-bubbling line, where the author writes down the *rule* and the build
evaluates it into inspectable data.

**The `Build` printer owes [face](#g-face) provenance.** For every root face,
that means the resolved chain down to the producing terminal (`"crashed" →
aircraft/monitor/out ← systems/ldg/{left,right,nose}/damaged`). Once faces are
computed rather than hand-listed, "what does this face actually reach" is a
question the artifact must answer, not the reader. The same rendering serves
the wiring diagnostics, which already carry endpoint paths.

#### The standard component library

**A standard [component](#g-component) library makes good on the junction
promise ([§6.2][s6-2]).** That promise rests on explicit junctions being
*cheap*. A junction hand-written per arity per type is not cheap.

The starting inventory comes strictly from demonstrated need. It holds wrench
and scalar summing junctions, the Bool gates the termination chains use,
`UnitDelay`, and `Constant{V}`. `UnitDelay` is the spelling the second
loop-breaking remedy ([§5.5][s5-5]) needs. `Constant{V}` is the source block.
The library grows by migration demand only. Simulink's library is a language,
while this is a toolbox.

One member is admitted by persona rather than migration demand. `Group` is the
on-the-fly [assembly](#g-assembly), and its declaration-layer treatment lives
in [§8.5][s8-5] ([D-184][d-184]). `Group` serves the model assembler, for whom
topology is data rather than a named type. It needs no rule the declaration
layer does not already have.

The doctrine is that **library blocks are ordinary components**, with no
framework privileges and no special vocabulary. Ordinary status is what keeps
[schema authority](#g-schema-authority) total (declarations define structure;
evaluation only checks conformance). That same status makes the library a
permanent ergonomics [torture test](#g-torture-test). If a three-input OR gate
is painful to write under the declaration rules, the rules are wrong.

Arity comes from a type parameter. `Or{N}` builds `(in1 = Bool, …, inN = Bool)`
programmatically. That is a derivation [§8.2][s8-2] blesses, and an early
validation that the contract functions support parametric components.

[Tier](#g-tier)-transparency falls out of settled semantics. A stateless
continuous `output_direct` recomputes every [sweep](#g-sweep). Fed ZOH-held
discrete signals, its output therefore changes only at [ticks](#g-tick). No
tier-neutral class is needed.

`UnitDelay{V}` is a **discrete** leaf at `K = 1`. It is the tier's native
`z⁻¹` ([§10.6][s10-6]) and the shape `sat_out_0` hand-writes in
[§15.2][s15-2]. It needs no framework support.

```julia
# UnitDelay{V} — a discrete leaf at K = 1; port face names elided
init_s(::UnitDelay{V}) where {V} = (v = zero(V),)
output_state(::UnitDelay, (; s)) = (; … = s.v)   # publishes the stored value
state_update(::UnitDelay, (; u)) = (; v = …)     # stores the incoming one, from u
```

`UnitDelay`'s tier semantics are the point, and they must be stated wherever
the remedy is recommended. Inserting a `UnitDelay` into a *continuous* loop
moves that signal onto the discrete tier and inserts a `Δt_base`-scale ZOH
into the model's mathematics. That is a modeling decision, because the delayed
signal is genuinely sampled rather than a transparent wire. The diagnostic
([§5.5][s5-5]) therefore says so rather than offering the remedy as free.

`Constant{V}` is the **source block**. It has no inputs, no state, and a
stage-1 body returning the value the instance holds.

```julia
# Constant{V} — a stateless continuous leaf; its value is instance data
output_types(::Constant{V}, ::Type{T}) where {V, T <: Real} = (out = V,)
output_state(c::Constant, _) = (; out = …)   # the value the instance holds
```

`Constant` is a stateless continuous leaf, so the tier-transparency argument
above already covers discrete consumers. No discrete variant is needed. The
declaration takes the [activation](#g-activation) scalar (a re-run of Stratum
C at a given scalar type) and ignores it. That is the point. The block's
output *is* its stored value, so the leaf is **deliberately
[pinned](#g-walked)** at that value's own type. A `Constant{Float64}` declares
a `Float64` port and means it. The embedding ([§8.2][s8-2]) turns it into the
zero-partial constant it already was under any `Dual` activation. The honest
pin is spelled rather than inferred.

Two demonstrated needs admit `Constant` under the inventory's demonstrated-need
charter. The zero-contributor configurations ([§6.2][s6-2]) are one. There, a
required aggregate input has no physical contributor, and the zero total must
be spelled as a wire. The rig stub below is the other. The block's value is
instance data, like junction arity, not an overridable default. A
configuration wanting an externally settable source uses a
[root input](#g-root-input) ([§11.3][s11-3]). That keeps the block from
drifting into a back-door input default. The library is a migration-phase
deliverable.

#### The component test rig

**The [component test rig](#g-component-test-rig) is the library's companion
idiom.** Exercising a leaf alone needs no rig of its own. Any component may be
the root of a build, and its input [faces](#g-face) then become the model's
root inputs ([§8.2][s8-2], [D-208][d-208]). Ordinary conditions and
[devices](#g-device) feed them, and every output is observable in the
[snapshot](#g-snapshot) table. The rig is a one-child assembly whose
`input_connections` surface the child's entire input face set, as
`input_passthrough(rig, "child")` verbatim ([§8.8][s8-8]). What it buys is a
place to wire something *beside* the component under test.

The demonstrated need is the root-input rule ([§8.2][s8-2]). An *abstract*
input entry (`terrain = AbstractTerrainField`, [§4.4][s4-4]) cannot surface as
a root input, because abstract-at-root is a build error. The rig therefore
satisfies that entry *inside* the rig. A concrete stub child (a
`SampleTerrainField` provider) is wired to the face, and the concrete
remainder is exposed via
`input_passthrough(rig, "strut"; except = ("terrain",))`.

```julia
struct StrutRig <: AbstractComponent    # the rig: component under test + stub
    strut::Strut
    stub::Constant{SampleTerrainField}  # the test handle, held as instance data
end

child_connections(::StrutRig) = ("stub/out" => "strut/terrain",)
input_connections(rig::StrutRig) =
    (input_passthrough(rig, "strut"; except = ("terrain",))...,)
```

That stub child is typically just a `Constant` holding the test handle, which
makes it the source block's first shipped instance. Bespoke stubs remain
ordinary components wherever the double must compute something.

The rig adds zero new machinery, because wiring and `except` already exist. It
is the substitutability contract doing its job. An
[abstract entry](#g-abstract-entry) (an `input_types` entry admitting any
concrete producer face) declares that a substitute must be chosen. The rig
chooses its test double explicitly, as ordinary inspectable code. That is
precisely the isolation the rig exists to provide.

The rig is [`design_world`](#g-design_world)'s little sibling
([§14.9][s14-9]). Where `design_world(ac)` mounts an aircraft in a minimal
world for trim and linearization, the rig mounts one component behind a root
contract for unit tests and open-loop probing. The machinery is deliberately
ordinary end to end, with no framework support. That makes the rig, like the
library blocks, a standing ergonomics test of the declaration rules.

---

## 14. Stopped-sim services

[§9.6][s9-6] previewed the services as [Stratum](#g-stratum)-C clients. They
are initialization, trim, linearization and [capture](#g-capture) (reading the
current stores and root inputs back as a condition). Everything they share
reduces to one artifact, the **[condition](#g-condition) value**. A condition
is the datum that says "set this build to this state."
[§14.1][s14-1]–[§14.4][s14-4] settle its representation, composition and
application. [§14.5][s14-5]–[§14.6][s14-6] cover the [boundary](#g-boundary)-zero
sequence and [root-input totality](#g-root-input-totality) (the requirement
that an application establishing a complete world cover every root input).
[§14.7][s14-7]–[§14.9][s14-9] cover the trim service in full.
[§14.10][s14-10] covers linearization and `capture`.

**Lifecycle preconditions.** Every service requires a non-running simulation.
While a run exists the loop owns the [stores](#g-store) between
[drains](#g-drain) (the frame-top swap that publishes staged device writes into
the root inputs), and a service reading or writing them would race it. Pause
is no exception, by the doctrine that freezes the [roster](#g-roster). Pause is
a control-plane state *inside* a run, so a prohibition that holds mid-run holds
while paused ([§11.3][s11-3], [§12.1][s12-1]).

Within the stopped-sim states, legality follows each service's inputs.

| service | `built` | `initialized` | `stopped` | its inputs |
|---|---|---|---|---|
| `capture` | error | legal | legal | committed, boundary-consistent stores |
| `init!` | legal | legal | legal | authored conditions |
| `trim!` | legal | legal | legal | authored conditions; the scratch world is [`override`](#g-override)`(baseline, condition(guess))` ([§14.8][s14-8]), never the sim's stores |
| `linearize`, operating point defaulted to `capture(sim)` | error | legal | legal | inherits `capture`'s precondition |
| `linearize`, explicit `about` ([§14.10][s14-10]) | legal | legal | legal | inherits `init!`'s legality — legal wherever `init!` is |

**`errored` is terminal for all four** ([D-059][d-059], [D-108][d-108]).
Post-mortem inspection of an errored sim's stores, log and [trace](#g-trace)
stays available as a diagnostic read. It may not become a condition value.

A violation is `ServiceLifecycle` ([Appendix C][sC]). Its payload is the
operation, the current status and the legal statuses. It is the same kind
`attach!`/`detach!` raise while `running` ([§11.3][s11-3]), so there is one
[register](#g-register) for "this operation is illegal in the current
lifecycle state." `MissingInit` is distinct, and names a missing prior step.

### 14.1 Conditions are path-addressed overlays on the declared defaults

A [condition](#g-condition) may specify state fields (`x` on the continuous
[tier](#g-tier), `s` on the discrete) and modes (`m`,
[continuous components](#g-continuous-component) only, [§3.2][s3-2]). All
three are addressed by a [§8.6][s8-6] slash path plus a field name. It may
also specify [root inputs](#g-root-input), addressed by [face](#g-face). It
never specifies outputs, which are derived data. It never specifies
[workspace](#g-workspace) (component-declared mutable scratch arriving as the
`ws` bundle field). Entries are validated in the [§13.1][s13-1] collecting
[register](#g-register). The full list is checked, violations are collected,
and one `DiagnosticError` is thrown.

**The overlay base is always the declared defaults.** Every [store](#g-store)
has a declared initial value (declaration-by-initial-value, [§8.2][s8-2]), so
conditions are naturally sparse. Applying one means "fresh run from the
`init_*` defaults, with these overrides" ([D-063][d-063]). Warm restart needs
no second semantics. A `capture` service reads the current stores **and root
inputs** back *as a condition value*, so the cycle is capture, tweak, apply.
Root input coverage is what makes the captured condition total, and hence
re-applicable under [§14.6][s14-6]. That gather is the one the
[trace header](#g-trace-header) already needs. It is one mechanism with two
uses.

**Doctrine.** Addressing conditions by path does not reopen the
observation-by-path rejection ([§13.5][s13-5]). That rejection was about
*runtime* coupling, where a root-authored predicate reaches through generic
[seams](#g-seam) the root does not own and breaks on substitution. A condition
is a *design-time statement about a concrete build*. It is authored in the
same register as `child_connections`, which also speaks paths, about children
its author owns. The composition law ([§14.2][s14-2]) makes the parallel
exact.

**Pre-[sweep](#g-sweep) doctrine.** Condition writes precede the first sweep by
definition. A would-be init value that depends on swept outputs is therefore
either analytically known to the caller or an equilibrium constraint. The
first case is trim's `α_filt = α_a`. There α is a *decision variable*, so the
value is known above, not computable below. The second case is a job for the
trim service, not for init.

"Caller-computable" reaches past closed-form knowledge to **environment
queries**. A condition needing one constructs the same handle the sweep will
produce, and then calls the same query function the consuming component calls.
There are two routes to that handle. One is the
[value-level constructor](#g-value-level-constructor) (the plain public
function building a field handle from the component and input values,
[§4.4][s4-4]), applied to the same values the [`baseline`](#g-baseline) writes
into the environment [component](#g-component)'s root inputs. The other
applies in a rig where the handle itself is a root-input value. There the
condition simply holds the value the `baseline` wrote. Either way there is one
implementation of the field math, evaluated one level up, with no pre-sweep
and no new mechanism. Where closed-form enforcement of a target is not wanted
at all, the second escape already covers the case. Promote the eliminated
state coordinates to decision variables and enforce the targets as residuals
on swept outputs. That route needs no environment access at condition time
whatsoever.

### 14.2 Fragment composition: locality without schema

Init knowledge is [component](#g-component)-local. The engine knows
`n_eng → ω = n_eng·ω_rated`, and nothing above it should have to. Making that
locality a schema entry was rejected ([D-064][d-064]). That spelling would
declare `initialize(::C, spec)`, today's `f_init!` reborn declaratively, and
add an [assembly](#g-assembly)-level rule routing sub-specs to children.

What preserves the locality is an idiom, not schema. It is the
**[fragment](#g-fragment) function**, an ordinary function shipped beside the
component and dispatched on the component.

```julia
condition(eng::PistonEngine; n_eng) =
    fragment(x = (ω = n_eng * eng.ω_rated,), m = (phase = Phase.running,))
```

Fragments are composed by *pull* from the structure's owner.

```julia
condition(sys::C172XSystems; n_eng, α_a, β_a) = combine(
    at("pwp/engine", condition(sys.pwp.engine; n_eng)),
    at("aero",       fragment(x = (α_filt = α_a, β_filt = β_a))))
```

Dispatch selects variant-specific methods, so the c172s/c172x actuation split
costs no upstream edits. The three combinators are constructors of an
**inert, lazy tree**. No path arithmetic happens at composition.

```julia
struct Fragment{X,S,M,L}  x::X; s::S; m::M; inputs::L  end  #self-vocabulary payloads; no paths
struct Scoped{N}  prefix::String; node::N  end             #at(prefix, node): stores, never applies
struct Combined{T<:Tuple}  nodes::T  end                   #combine(ns...): collects; order = diagnostics only
```

Every node is isbits except the prefix strings, and a prefix is a reference to
the author's own literal. So **rebuilding the tree per trim iteration
allocates nothing**. There is no path arithmetic, no validation and no copy of
the payloads. The zero-alloc property of today's `assign!` loop holds of the
construction and of the [register](#g-register) that *applies* the tree
([§14.4][s14-4]) alike. An evaluation's cost is therefore the sweep it feeds.

`fragment`'s payloads speak only about the component at the authoring point.
Addressing children is exclusively `at`'s job, so there is one way to say
everything. An `inputs` payload names faces *of the authoring level's
[contract](#g-contract)*. Resolution walks the export chain to the root input
and errors if the face never surfaces. That walk always has a name to follow.
One-level routing gives every level a declared face for every signal crossing
its boundary, so the chain a sub-assembly's face routes through is in the
`Build` ([§6.1][s6-1], [§9.2][s9-2]). An internally-wired input has no root
input behind it, and writing it would be meaningless because the first sweep
overwrites it. Unexported stays unpokeable for init exactly as it does for the
GUI ([§11.7][s11-7], [§15.4][s15-4]).

**The locality law** here is the one [§6.1][s6-1] states for connections, now
in its third instance. The three instances are child connections, computed
interface connections and conditions. Each level speaks its own fields, its
declared children's names, and its own faces. Delegation runs by dispatch at
every genericity [seam](#g-seam). An `at` prefix may stop at *any* child's
faces, owned or generically held, because the face graph is total
([D-207][d-207]). A deep `at` path into structure stays legitimate exactly
where a deep [condition](#g-condition) path is, within an owned concrete
subtree ([§13.3][s13-3]). Absolute paths exist only in the flattened entry
list, a *compiled derivative* of the composition, as cell offsets are of
`child_connections`. Substituting a component invalidates precisely the
fragments its owner shipped, nothing else. The enforcement status carries over
from [§6.1][s6-1] as well. The law is convention. Ownership is a fact about
who maintains the code, and the build cannot see it, so the law is available
and idiomatic rather than machine-checked. `fragment`/`at`/`combine` are
[§13.7][s13-7] standard-library material, ordinary artifacts with no
privileges.

A [combine](#g-combine) collision is two entries on one leaf. Collisions are
errors at resolution, and the error reports *both* provenance chains. The
message names the layering combinator: "`combine` is collision-intolerant by
design — use `override(base, patch)` to layer." Last-writer-wins was rejected
([D-065][d-065]). That rejection is also why the combinator is not
`Base.merge`, and is no longer named after it ([D-204][d-204]). `Base.merge`
is last-wins on NamedTuples, the exact semantics rejected here, and its own
name should not promise them. Because `combine` is its own function, a bare
NamedTuple blended into a node cannot fall through to any last-wins method.
The blend is still closed explicitly. A `combine(::Fragment, ::NamedTuple)`,
or any other blend of a condition node with a bare NamedTuple, is an **error
method**. Its message is directive: wrap the NamedTuple in `fragment(…)` (or
`at(prefix, fragment(…))`) and combine nodes with nodes. The rejection carries
a [kind](#g-kind) like every other. It is `ConditionNodeMisuse`
([Appendix C][sC]), carrying the offending argument's type and the node kinds
in hand. It is raised at composition time, before any resolution pass or
provenance chain exists. That is why it is its own kind and not a
`ConditionResolution` sub-kind ([§14.3][s14-3]). The explicit, *ordered*
layering spelling, `override`, belongs with the use case
[root-input totality](#g-root-input-totality) produces ([§14.6][s14-6]).

### 14.3 Resolution: flatten, validate, compile once

Resolution takes the root node plus a `Build`. Flattening is the only place
path strings are ever concatenated. It is a trivial recursion with a path
accumulator, and it also records each entry's **tree position**, its
`getfield`/`getindex` step tuple.

The collecting pass then checks each flat entry:

- the path resolves, with [did-you-mean](#g-did-you-mean) (the offending name
  plus the list-in-hand it should have matched) over children;
- the field is declared in the target's `init_x`/`init_s`/`init_m`;
- the value type is convertible to the declared leaf type;
- input [faces](#g-face) reach [root inputs](#g-root-input);
- no `(path, store, field)` is duplicated.

The `Build` supplies two lookup families. **Schema** is the evaluated
declarations, and it is the authority. It answers whether you may write this
field, and at what leaf type. **Layout** is the destination. It holds the `x`
backing ranges, the store indices for `s` and for `m`, and the root-input
indices from the [activation](#g-activation) (a re-run of Stratum C at a given
scalar type). Layout also carries the face chains from [Stratum](#g-stratum) A
(one of the build's three phases: structure, schedule, activation).

A valid list compiles to a plan. Per leaf, the plan holds a `Getter{P}`
[lens](#g-lens) (the compiled navigation step of a condition entry), a
destination offset, and a converter. The lens is the position tuple lifted to a
type parameter, so navigation of the fixed tree type is type-stable.

**Rule.** The converter is baked now, selected per leaf from that leaf's type
in the resolved shape.

**Why.** Leaf types are shape facts, carried by the tree type along with the
full nesting and every field name ([§14.4][s14-4]). Selection therefore
consults no runtime fact and stays a resolution-time bake.

There are two cases.

| leaf in the resolved shape | converter baked |
|---|---|
| already at the activation's scalar type — decision-descended | the type's ordinary `convert`/constructor methods *at that eltype* |
| a plain `Float64` leaf against a non-nominal activation's scratch — a held constant | the `Float64 → Dual` zero-partial embedding |

**A leaf already at the activation's scalar type** is decision-descended.
Under a `Dual`-seeded evaluation of a type-stable `trim_condition(d)`, every
decision-dependent leaf is `Dual`-typed in the shape ([§14.7][s14-7]). Such a
leaf takes the type's ordinary `convert`/constructor methods *at that eltype*.
An authored `RQuat` of `Dual`s becomes the `SVector{4}` state leaf at `Dual`,
with the partials flowing through untouched. That untouched flow of partials
is what makes the seeded decisions reach the [sweep](#g-sweep) at all. At the
nominal activation the same rule is the ordinary `Float64` conversion. An
authored `RQuat` value becomes the `SVector{4}` state leaf it initializes.

**A plain `Float64` leaf against a non-nominal activation's scratch** is a held
constant, and it takes the `Float64 → Dual` zero-partial embedding. That
embedding is semantically exact in that case, and in no other. "Held at the
operating point" *is* zero partials. Zero partials are the whole of a
linearization operating-point [condition](#g-condition), which is authored
decision-free ([§14.10][s14-10]).

The selection is a one-time boundary decision, and it leaves the nominal
exact-match doctrine for table [cells](#g-cell) ([§9.5][s9-5]) untouched.
Converters run here and in `capture`'s gather ([§14.10][s14-10]), which are
the write paths. They never run on state [views](#g-view) ([§7.1][s7-1]).

Overlay partiality for the `s` and `m` stores is baked the same way. The
writer holds `merge(init_m_defaults, overlay)`, with the base resolved at
compile time (the overlay-base rule, [§14.1][s14-1]).

### 14.4 Two application registers over one plan

**The paradigm-change tax feared at execution does not materialize.** All
string work, validation and addressing are functions of the *shape* of the
[condition](#g-condition) (the path-addressed sparse overlay that sets a
build's state). Every hot path holds the shape fixed while varying values.
Execution is therefore resolve-once/execute-many, with two
[registers](#g-register) over one plan.

- **Specialized `apply!`** serves the services that iterate, namely trim's
  per-evaluation write and linearization's seeding. It unrolls stores through
  the baked lenses and converters. Those are the same machine operations as
  today's in-place writes: zero-alloc, no strings, no dispatch. The
  per-iteration shape check is the mechanism of [§9.5][s9-5] transferred. The
  tree type is proven by dispatch, and it carries the full nesting, every
  field name and leaf type. A `===` sweep over the prefix strings closes the
  remainder. `===` on strings compares content, so a prefix computed at run
  time pairs with the compiled one exactly as a literal does, at the cost of
  one short comparison per `at` node. Shape drift (a tree of another type, or
  a prefix that differs at a position) is `ConditionShapeDrift`
  ([Appendix C][sC]), a structured error rather than silent corruption. The
  cost is Julia codegen of ~10–50 ms *once per condition shape*. That cost is
  noise against the model's own first-sweep warmup (seconds), and against the
  10³–10⁴ optimizer evaluations the codegen amortizes over.
- **The dynamic walk** serves one-shot init. It executes the same validated
  entry list by runtime dispatch per write. That takes microseconds in total,
  with allocation permitted, since the stopped-sim path was never under the
  zero-alloc regime ([§7.5][s7-5]). It needs no per-shape codegen. Fifty
  structurally different scripted conditions cost fifty walks, not fifty
  compiles.

**Rule.** Which register a service uses is internal, never user-facing API.

A compiled plan or reader carries the [activation](#g-activation) it was
compiled at and applies only to a store set of that activation. That pairing
is a framework invariant the services uphold, not a user-facing check. Neither
plans nor readers are user values.

#### The read-selector family

**The read-[selector](#g-selector) family is closed.** Its members are
`get_state(path, field[, i])`, `get_deriv(path, field[, i])`,
`get_output(path, field[, i])`, `get_input(face)` and `get_face(name)`. They
form one address space for every reader of the model.

The names carry a deliberate `get_` prefix. A selector is a *deferred read*, a
value describing the read the compiled gather will perform. The prefix names
that action, and it keeps five short common nouns out of the namespace user
declarations share with domain code.

There is no selector for a value a [component](#g-component) computes without
declaring it, and there cannot be one, because only [cells](#g-cell) are
addressable ([§5.2][s5-2]). So a reader that wants one is asking the producing
component to declare it an output ([§8.3][s8-3]). `get_face` addresses a
root-exported output [face](#g-face), which is the *integration* register
([§11.2][s11-2]).

**Rule.** A selector resolves against a source, before any client policy
applies.

The table selectors (`get_output`, `get_input`, `get_face`) resolve against a
*table source*. A table source is a [boundary](#g-boundary)
[snapshot](#g-snapshot), or the scratch tables a service evaluation
instantiates ([§14.8][s14-8]). The store selectors (`get_state`, `get_deriv`)
resolve only against live stores. The table/store axis separates table-borne
values from store-borne ones, not snapshots from services.

Only stopped-sim service evaluations, `capture`, and post-run inspection of
the live stores (the [replay](#g-replay)-to-inspect, [§11.2][s11-2]) ever hold
live stores. The snapshot deliberately carries no state stores
([§11.2][s11-2]), and `ẋ` [buffers](#g-buffer) are integrator scratch, not
boundary-consistent objects outside a service evaluation. A snapshot-bound
reader naming a store selector is therefore a resolution error at attach
(`ReadBindingUnresolved`), raised in the didactic register. The honest remedy
([§11.2][s11-2]) is to declare the field public and read the
[auto-published port](#g-auto-published-port) (published by the framework
from the state or mode store).

Client policy rides on top. It is the registers of [D-083][d-083] restated as
a resolver property.

- **Load-bearing services speak the [contract](#g-contract).** Trim's `reads`
  and linearization's [taps](#g-taps) (the three selector lists declaring
  what linearization seeds and reports) name
  `get_state`/`get_deriv`/`get_output`/`get_input`/`get_face`. They do so
  within the scopes the locality law ([§6.1][s6-1]) and
  [fragment](#g-fragment) scoping ([§14.2][s14-2]) own. `get_face` is the
  set's [seam](#g-seam)-crossing member. It resolves through export chains
  exactly as [mounting](#g-mounting) (relocating a whole problem or tap set
  with `at(prefix, …)`) resolves [root input](#g-root-input) faces
  ([§14.9][s14-9]), so the read side mirrors the write side. An equilibrium
  equation reaching behind a generically-held child therefore binds the
  curated face register instead of a path the locality law forbids. A service
  evaluation needing an undeclared intermediate has one remedy, and it is the
  same at every register. The component exports it ([§14.7][s14-7]).
- **Diagnostic readers admit the whole family, within the source rule.**
  Output-[device](#g-device) bindings, GUI panels and log inspection take deep
  paths and `get_face` names alike. The store selectors reach only the
  diagnostic clients that actually hold stores (`capture`, post-run
  inspection). A snapshot-bound reader is barred from them by source, not by
  client.
- **`stop_on` is not a family client.** It names root-exported `Bool` output
  faces, period ([§13.5][s13-5], [D-060][d-060]). Termination is run policy
  against the root contract, and no path selector reaches `stop_on`.

The five selectors, their sources, and their clients:

| selector | resolves against | load-bearing services | diagnostic readers |
|---|---|---|---|
| `get_state(path, field[, i])` | live stores | named in the contract | only clients that hold stores |
| `get_deriv(path, field[, i])` | live stores | named in the contract | only clients that hold stores |
| `get_output(path, field[, i])` | a table source | named in the contract | admitted |
| `get_input(face)` | a table source | named in the contract | admitted |
| `get_face(name)` | a table source | named in the contract | admitted |

**Compiled readers are the gather twin** over this family and the layout
tables. Trim's cost read (`ẋ` and output fields), linearization's Jacobian
gather, and `capture`'s full-store readback are one primitive run in reverse.
It is one machinery, in both directions, in the `Build`'s client kit.

The per-iteration ledger for trim has four terms. They are the user fragment
math (the domain computations unchanged from today, plus the tree's few boxes,
[§14.2][s14-2]), the leaf stores, the folded shape check, and the sweep. The
sweep dominates, exactly as `f_ode!` does today. `apply!` ends at established
stores. Making the model *coherent* is the job of
[boundary zero](#g-boundary-zero) (the initialization boundary: the ordinary
macro-sequence with an empty integrate), [§14.5][s14-5].

### 14.5 Boundary zero: an ordinary boundary with authored incoming transitions

`apply!` establishes the stores at `t₀`. The [trace header](#g-trace-header)
captures those stores, together with the [root input](#g-root-input) values,
*before anything below runs* (the capture placement, [§11.5][s11-5]). A
post-sequence capture would hand [replay](#g-replay) already-transitioned
state. The init service then completes the [§10.6][s10-6] macro-sequence with
an empty integrate. The sequence is project → [[sweep](#g-sweep) →
[guards](#g-guard) → handlers]\* → [due](#g-due) `state_update` calls → first
[snapshot](#g-snapshot). The parity with an ordinary boundary is exact, not
approximate. The pieces follow one by one.

- **Project runs.** Authored `x` can sit off-manifold. A hand-assembled
  quaternion may be ulps off unit norm, or a [condition](#g-condition) (the
  path-addressed sparse overlay that sets a build's state) may write part of a
  constrained block against fresh defaults. [Projection](#g-projection) after
  condition writes holds the same position it holds after any other `x`
  mutation. And it costs nothing when the state is already clean.
- **The sweep runs, and every discrete output stage publishes, due or not
  ([D-205][d-205]).** `t₀` is a grid point of every phase-free divisor, so the
  `Φ = 0` components are due in full. An offset [component](#g-component)
  ([§10.5][s10-5]) is *not* due, because its first [tick](#g-tick) is at
  `Φ·Δt_base`. Its output stages run at boundary zero all the same, publishing
  from the authored `s` and the `t₀` table in the ordinary sorted walk. That
  evaluation is establishment, not a scheduled sample. The schedule owns every
  instant after `t₀`, and the first sample the component's `state_update`
  consumes remains its `Φ·Δt_base` tick's. What the rule buys is a `t₀`
  [snapshot](#g-snapshot) carrying the authored world fully evaluated. No
  published [cell](#g-cell) holds the [probe](#g-probe)'s synthesized values.
  That is the [§14.6][s14-6] barrier extended from the
  [root inputs](#g-root-input) to the whole table.
- **Events run.** A condition can land a guard [predicate](#g-predicate) in
  [holding](#g-edge-semantics) territory (firing on not-holding → holding
  transitions, never bare sign changes). An authored stall flag, or a strut
  authored into contact, does exactly that. The event then fires visibly at
  `t₀` rather than one step later. The [prior](#g-prior) rule grounds that
  timing ([§10.6][s10-6]). [Boundary zero](#g-boundary-zero) establishes every
  guard prior (the event's stored predicate sample from the previous boundary)
  as not-holding. Suppressing those firings was rejected ([D-067][d-067]), on
  the [stage-on-interaction](#g-stage-on-interaction) lesson of
  [§11.7][s11-7] (widgets stage on edit or activation, never per render pass).
  Insurance that masks invariant violations is anti-diagnostic
  ([D-026][d-026]). The header records the *resolved pre-sequence* stores and
  root inputs ([§11.5][s11-5]). Replay therefore re-executes
  [boundary](#g-boundary) zero from the same starting point, and whatever
  fires at `t₀` fires again identically ([§12.7][s12-7]). The firings are
  recomputed, never recorded. A `stop_on` [face](#g-face) already `true` is a
  different category. Nothing *fires*. The face simply reads `true` in the
  published `t₀` snapshot and the loop reacts ([§13.5][s13-5]).
- **Due `state_update` calls run.** This follows from an interval-alignment
  fact that is easy to mis-picture. It is hereby a taught contract, sibling to
  the boundary-sampling line ([§15.5][s15-5]). **A boundary's `state_update`
  is the *outgoing* transition.** At tick `t_k` it consumes the completed
  boundary's samples and produces `s_{k+1}`, the value the next tick reads.
  The transition that carried `s` *into* `t_k` ran at `t_{k-1}`. Boundary
  zero is missing its incoming transitions on *both* tiers, and authorship
  replaces both.

  | [tier](#g-tier) | `t₋₁` | `t₀` (boundary zero) | `t₁` |
  |---|---|---|---|
  | discrete | the `state_update` that would have produced a discrete leaf's `s(0)` never ran; the condition authored `s(0)` | `state_update` consumes the `t₀` samples and produces `s(1)` | the gated stages read `s(1)` |
  | continuous | the integration over `[t_{-1}, t_0]` that would have produced a continuous leaf's `x(0)` never ran; the condition authored `x(0)` | the authored `x(0)` is the initial condition of the outgoing integrate, $t_0 \to t_0 + h$ | |

  The outgoing work all runs, and `t₀`'s `state_update` has its only
  opportunity. `s(1)` must sit in the store before `t₁`'s gated stages read
  it. An accumulator $s_{k+1} = s_k + \Delta t \, e_k$ authored with $s_0 = 0$
  under nonzero $e(t_0)$ would otherwise first integrate $e(t_1)$, putting the
  whole sampled-data lattice one period late ([D-067][d-067]). The authored
  `s(0)` needs no protection, because it is published in the `t₀` snapshot
  regardless. The continuous-tier analogue of `state_update`-at-`t₀` is not
  the empty incoming integrate but that first *outgoing* one. Both authored
  values are the published initial conditions of their outgoing transitions.
- **`t₀` is an init-service argument** (default `0.0`), never a condition
  entry, because time is not a store of any component. The
  [harmonic grid](#g-harmonic-grid) (every discrete period an integer multiple
  of `Δt_base`) anchors at whatever `t₀` boundary zero runs at. Both
  init-service entry points carry the argument, with the same default. They
  are `init!(sim, condition; t0)` and `trim!`'s commit
  (`trim!(sim, problem; baseline, t0, backend)`, [§14.8][s14-8]). Conditions
  are time-free. `capture` returns condition and time separately for
  resume-at-time, and the returned `t` is passed back as `t0`.
- **Trim is untouched by all of this.** Optimizer iterations are raw
  write → sweep → read cycles on the activation, with no boundaries, no events
  and no `state_update`. Only the committed solution executes boundary zero.
- **A guard firing at commit is a wanted failure signal.** Today's
  hand-written trim asserts (`!stall`, no weight-on-wheels, `ω > ω_idle`)
  become the model's own event logic, surfaced through the ordinary machinery
  instead of `@assert`. A handler that fires at commit moves the committed
  stores off the solved point. Saying nothing would be warn-but-assign
  relocated. The channel that says it is the trim report ([§14.8][s14-8]).
- **A commit-fired handler is not the only mover, and the second one is
  unconditional.** Boundary zero's *first* act is `state_projection`, so the
  committed `x` is `state_projection(x*)`, not the solver's `x*`. An attitude
  quaternion renormalized by a few ulps is the canonical case. That move is
  legitimate, wanted, and usually invisible in the residuals. But the point
  the stores sit at is no longer the point the verdict was read at. Both
  movers take the same remedy, specified with the report in [§14.8][s14-8].

### 14.6 Root-input totality: the missing-value error and the `override` combinator

[Root inputs](#g-root-input) are the one initialized datum without declared
defaults. That is the bare-types decision ([§11.3][s11-3]), upheld here
([D-068][d-068]). So a root input's only source before
[boundary zero](#g-boundary-zero) (the initialization boundary: the ordinary
macro-sequence with an empty integrate) is the condition. Three consequences
follow.

**Totality is a precondition of starting, checked by the service.** A
condition value is legitimately partial. [Fragments](#g-fragment) compose,
trim iterations write subsets, and capture-then-tweak patches leaves. So
"every root input covered" is not a property of conditions. It is a property
of *every application that establishes a complete world over virgin stores*.
That principle, not an enumeration, names the sites. They are `init!`, trim's
setup application to freshly allocated scratch stores, and trim's commit
through [boundary](#g-boundary) zero ([§14.8][s14-8]). That is one class, one
mechanism and one kind. Each compares the resolved plan's root-input coverage
against the `Build`'s `input_faces` before writing anything. A shortfall is
one collected, declaration-ordered diagnostic (`UninitializedInputs`, a
[§13.2][s13-2] kind) naming every uncovered face. Coverage is a *plan-level
fact*, because both operands are resolution-time data. The check is therefore
one comparison, and it runs before any evaluation, not merely before any
write. Pre-write means all-or-nothing. A rejected init leaves the sim exactly
as it was, the same posture as failed trim.

**The [probe](#g-probe-value)-value barrier is structural.** The `probe_value`
synthesis ([§9.3][s9-3]; zero/false/first-enum/`T()`) exists so build-time
probes can exercise code with fabricated inputs. A fabricated zero is a fine
probe input and a terrible flight condition. A silently zeroed `mixture` kills
the engine and sends the user debugging aerodynamics. The services path simply
contains no call to it. A root input gets a condition value or the application
errors, with no third branch. [Replay](#g-replay) likewise never synthesizes.
The [trace header](#g-trace-header) records every root-input value, and with
totality enforced its root-input capture is complete by construction (the
requirement discharged, [§11.3][s11-3]).

**[Baselines](#g-baseline) are aircraft-shipped [condition](#g-condition)
functions, layered by `override`.** Nobody hand-writes ~20 root-input values
per script. Today `SystemsInitializer`'s `@kwdef` defaults carry that load.
Their successor is ordinary user math in one authoritative home, such as
`ready_for_taxi(ac)` or `cold_and_dark(ac)`, returning full-coverage
conditions. But "baseline plus tweaks" collides with the duplicate-leaf error
([§14.2][s14-2]) by design. The collision *is* the intent. Hence the fourth
node kind, **`override(base, patch)`**. It is ordered and asymmetric, where
`combine` is symmetric and collision-intolerant. At resolution a leaf present
in both takes the patch's value, with provenance recording both sources
("patch overrode base's `throttle`"). Collisions *within* one layer remain
errors. Variadic layering (`override(campaign, aircraft, todays_case)`)
composes. Trim uses it on day one. The committed condition is
`override(baseline, solution)`, the solver's handful of values over full
coverage ([D-068][d-068]).

### 14.7 The trim problem: NamedTuple decisions, declared reads, named residuals

The aircraft author ships one value. It says what the solver may vary, what
those decisions make of the model, what to read back after each evaluation,
and which equations the readings must satisfy.

**Rule.** The field set is normative. The lift ([§14.9][s14-9]) is
field-by-field, so this list is closed.

- `guess`, `lower` and `upper` are same-named all-`Float64` NamedTuples.
- `condition` is the condition-valued function over decisions.
- `reads` is the declared read set.
- `residuals` is the residual function.
- `tolerances` is an all-`Float64` NamedTuple, same-named as the residual
  function's return.

`tolerances` is carried *in the problem* because a relocated problem must carry
its own convergence test. `at` passes it through untouched.

[Worked](#g-worked), the C172 cruise case reduces to its three-equation core.
The real problem is the same shape with the full 7-variable search, and the
θ-constraint elimination survives inside `trim_condition`.

```julia
cruise = TrimProblem(
    guess      = (throttle = 0.6, elevator = -0.05, α = 0.06),
    lower      = (throttle = 0.0, elevator = -1.0,  α = -0.1),
    upper      = (throttle = 1.0, elevator =  1.0,  α =  0.3),
    condition  = d -> trim_condition(ac, params, d),    #params closed over (§14.2)
    reads      = reads(v̇_b = get_deriv("vehicle/dynamics", :v_eb_b),
                       ω̇_b = get_deriv("vehicle/dynamics", :ω_eb_b)),
    residuals  = (r, d) -> (axial_force  = r.v̇_b[1],
                            normal_force = r.v̇_b[3],
                            pitch_moment = r.ω̇_b[2]),
    tolerances = (axial_force = 1e-3, normal_force = 1e-3, pitch_moment = 1e-4))
```

The rest of the section takes what the author ships one piece at a time,
against today's `c172.jl`.

- **Decision variables, initial guess and box bounds are plain, same-*named*,
  all-`Float64` NamedTuples.** The `AbstractTrimState{N}`/`FieldVector`
  supertype dies. Its only job was vectorization, and vectorization is the
  service's. The service packs and unpacks by field order, and that order is
  the `guess` NamedTuple's own. [§9.5][s9-5] states the rule this
  [seam](#g-seam) runs on: **the names are the pairing, order carries no
  semantics**. `lower` and `upper` are checked at setup for key-set equality
  with `guess` and for `Float64` fields. They are then canonicalized to
  `guess`'s field order by the same type-level reorder
  (`NamedTuple{keys(guess)}(lower)`). A permuted bound spelling is therefore
  a non-event, rather than `α`'s bound silently applied to `throttle`. A
  key-set or field-type mismatch is `TrimProblemInvalid`. Guess, bounds and
  the returned solution share one spelling, and
  `Base.merge(guess, (throttle = 0.3,))` is free warm-start tweaking. An
  author who wants a documented `@kwdef` struct keeps it privately and
  converts.
- **`TrimParameters` stays a plain user struct** the framework never sees. The
  assignment is the pure `trim_condition(ac, params, d)` fragment-tree
  function ([§14.2][s14-2]), applied per iteration by the compiled plan
  ([§14.4][s14-4]).
- **The read side is declared, then compiled.** The spelling is
  `reads(name = get_state(path, field) | get_deriv(path, field) |
  get_output(path, field) | get_input([face](#g-face)) | get_face(name),
  ...)`, the load-bearing set ([§14.4][s14-4]). `get_state` and `get_deriv`
  address a declared state field and its derivative (validated against
  `init_x`/`init_s`). `get_output` addresses a declared output
  [port](#g-port) (validated against `output_types`). `get_input` and
  `get_face` address a root input and an output face (validated against the
  root face lists). The path [selectors](#g-selector) (the closed family of
  deferred reads resolving against a source) reach only through the locality
  scopes ([§6.1][s6-1]). An equilibrium equation crossing a generic seam
  reads a face. A value a [component](#g-component) computes without
  declaring it is not addressable at all ([§5.2][s5-2], [§14.4][s14-4]). A
  trim evaluation needing one is a signal that the component should export
  it. A derivative wanted across a [contract](#g-contract) boundary takes the
  same remedy. Publish it as an ordinary output port computed in
  `output_direct` (the one-line binding of [§7.4][s7-4] step 2, made
  contract). That leaves `get_deriv` scoped to owned concrete subtrees. The
  compiled reader (the gather twin, [§14.4][s14-4]) fills a stack-only
  NamedTuple per evaluation.
- **The user supplies a residual *system*, not a scalar cost.** It is authored
  as a NamedTuple of named equations and packed to the solver's vector by
  field order. The order here is `tolerances`' field order, the declared side
  again, and the residual return is canonicalized to it. The decisions rule
  holds symmetrically on both ends of the seam. Names pair, and order never
  does.
- **The FlightCore formulation's core is correct and survives verbatim as user
  math.** That core is analytic elimination: `θ_constraint` substituting the
  pitch constraint, filter and actuator equilibria imposed by construction, and
  the minimal 7-variable search.
- **What changes is the numerics.** Trim is a square root-find. FlightCore's
  derivative-free scalar minimization over $\|r\|^2$ against a hand-scaled
  absolute `stopval` was the rational choice only because Jacobians through
  the mutating `f_ode!` chain and the assignment math were out of reach
  ([D-069][d-069]).
- **Nonlinear least squares with exact AD Jacobians is the default.** The
  `Dual` [activation](#g-activation) seeds the decision variables through the
  `T`-generic assignment, [sweep](#g-sweep) and `state_derivative`. The seeds
  survive the condition write boundary because [§14.3][s14-3] selects the
  baked converter per leaf from the shape. A decision-descended leaf is
  `Dual`-typed there and takes the structural conversion, while the
  zero-partial embedding stays on the held `Float64` leaves. The *default* is
  nonlinear least squares on $r(d)$ with exact AD Jacobians, in the
  trust-region/Levenberg–Marquardt register ([§9.6][s9-6]). Convergence is
  quadratic (~5–15 evaluations), the tolerances are per-residual and
  physical, and failure reports name the unbalanced equations with
  magnitudes. The convergence verdict itself is service-owned and
  backend-independent ([§14.8][s14-8]).
- **Non-squareness degrades gracefully.** Redundant actuation becomes weighted
  or minimum-norm least squares. Infeasible demands converge to a nonzero
  residual identifying the impossible balance. At the solution,
  $\partial r / \partial d$ is free flight-physics data (control
  effectiveness) that cross-checks linearization.
- **The derivative-free scalar path survives as the fallback.** The service
  squares *and normalizes* the residuals against the tolerances, minimizing
  $\sum (r_i/\mathit{tol}_i)^2$ at `stopval = 1` ([§14.8][s14-8]). That
  normalization is where the hand-scaled absolute threshold is repaired. It
  leaves today's algorithm as the degenerate case.
- **Two problems are [recorded, not built](#g-recorded-not-built)** (a
  worked-out extension deliberately left unimplemented, its seams named). They
  are closed-loop sampled-data trim and on-ground static equilibrium, each
  simply another problem value over the same service. Closed-loop trim appends
  $g(s) - s = 0$ residuals via a nondestructive scratch evaluation of
  `state_update`, which was structurally impossible under FlightCore's
  mutating `f_disc!`. On-ground static equilibrium solves strut compressions
  and attitude against gear forces.

The residual signature:

```julia
residuals(reads::NamedTuple, d::NamedTuple) → NamedTuple
```

**Rule.** What the solver varies is passed. What is fixed per problem is
closed over.

The gathered reads and the decision NamedTuple arrive as arguments. `d` is the
one value that *cannot* be closed over. `TrimParameters` stays behind the
closure, exactly as `condition` already holds it, and the framework never sees
it. Being user-shaped, that record is also where any environment handles the
condition math needs conventionally ride (the
[value-level constructor](#g-value-level-constructor), [§4.4][s4-4]; the
pre-sweep doctrine, [§14.1][s14-1]). The problem *receives* the environment,
and never writes it ([§14.9][s14-9]).

The returned NamedTuple's names are the equation names the report and the
failure messages use. The service packs residuals and tolerances by field
order. `tolerances`' order is canonical for the r-side, and each residual
return is reordered to it (`NamedTuple{keys(tolerances)}(r)`) before packing.
An equation list spelled in a different order inside the lambda therefore
pairs correctly and costs nothing. Names and types are checked at setup,
because the guess evaluation the service performs anyway observes the
residual key set. A `tolerances` key-set mismatch, or any field-type
disagreement on either side of the seam, is `TrimProblemInvalid`
([Appendix C][sC]), with the offending field and the names or types in hand.
Order is never a mismatch.

### 14.8 The trim service: solver seam, scratch stores, commit and report

A `TrimProblem` is an inert value until a service runs it. `trim!` is that
service. It drives a solver it holds behind one method, works on scratch
stores of its own, commits a converged solution the way `init!` would, and
returns a report.

#### The backend seam

The signature is
`trim!(sim, problem; baseline, t0 = 0.0, backend = LevenbergMarquardt())`. The
default backend is an in-house dense Levenberg–Marquardt. For decision
dimensions ~10 with exact Jacobians, the core is ~100 lines: a damping loop, a
small linear solve, a convergence test. That is the [§10.2][s10-2] stepper
precedent exactly, a tiny needed core against a heavy dependency. The
per-residual physical tolerances sharpen the case ([§14.7][s14-7]). They are a
convergence test no external package spells natively. That is precisely why
the *service*, not the backend, applies it.

The backend contract is a **pinned signature**, value-passed, with one
required method per backend. That one method is the [seam](#g-seam).

```julia
solve(backend, eval!, d0, lower, upper, tol) -> (; d, status, nevals, niters)
```

`eval!(r, J, d)` is in-place and always fills `r`, the residual vector packed
in `tolerances`' field order. It fills `J` **iff `J !== nothing`**. The
Jacobian is requested by argument, so a Jacobian-free backend simply always
passes `nothing`, and there is still exactly one evaluation method to
implement.

`d0`, `lower` and `upper` are packed `Vector{Float64}` in `guess`'s field
order, with `±Inf` meaning unbounded. The declared side is canonical on both
ends, and the service has canonicalized before packing ([§14.7][s14-7]). A
backend that ignores bounds therefore ignores two vectors, not a missing
argument.

`tol` is a `Vector{Float64}` in `tolerances`' field order. It is data the
backend *may* stop on, under the service's per-register translation below, and
it is decisive of nothing.

The return holds `d`, the solution, `status::Symbol` from a deliberately
**open** set, and the diagnostic counts `nevals` and `niters`. The status is
recorded verbatim in the report because the verdict is the service's
([D-158][d-158]). The name `solve` is subject to the [§16][s16] naming audit
like every other API spelling. The backend sees vectors and never names, so
the solution it returns unpacks by the same order it was given.

#### The convergence verdict is the service's, uniformly

`converged` means `all(abs.(rᵢ) .≤ tolᵢ)`. That is the per-residual box test
([§14.7][s14-7]) in its own physical units, evaluated **by the service at the
backend's returned point**. It is one residual evaluation, noise against the
solve that produced it. That verdict, and nothing else, gates the commit and
fills `TrimReport.converged`. The backend's returned `status` is recorded in
the report as diagnostic data, and it is authoritative over nothing.

#### The tolerance translation, per register

The tolerance translation is the service's too, per register. In the
least-squares register the tolerances *are* the stopping criterion. They feed
the per-residual test directly, so LM's damping loop tests exactly what the
service will re-test.

The derivative-free scalar fallback is `NLoptBackend(:LN_BOBYQA)` in a package
extension. It passes `nothing` for the Jacobian, keeps today's algorithm one
keyword away, and leaves the framework core carrying zero optimizer
dependencies. For that fallback the service squares *and normalizes*. The
objective minimized is $\sum_i (r_i/\mathit{tol}_i)^2$ with `stopval = 1`.
That objective is dimensionless where FlightCore's threshold was hand-scaled
and absolute ([§14.7][s14-7]). It is a well-scaled valley where a raw
$\|r\|^2$ sums forces against moments.

The two criteria cannot disagree in the dangerous direction:

$$\sum_i (r_i/\mathit{tol}_i)^2 \le 1
\quad\Longrightarrow\quad (r_i/\mathit{tol}_i)^2 \le 1 \;\text{ for every } i$$

so the `stopval` sphere is *inscribed* in the tolerance box, and a fallback
stopping at `stopval` necessarily passes the service's box test. The converse
disagreement, a backend stopping early and reporting an optimistic status, is
caught by the re-check, which remains the single authority. What is *not*
claimed is point identity. Different backends may land on different
solutions, which is an algorithmic difference and a legitimate one. What is
eliminated is per-backend meanings of `converged`.

#### Box bounds and saturated decisions

Box bounds are honored by step projection. A decision variable saturated *at
the solution* is flagged in the report: "converged with `elevator` at its upper
bound". That is the classic CG-limit diagnostic, today inferable only from
mysterious residuals.

#### Scratch stores, stated without type luck

Every `trim!` invocation instantiates a fresh working store set. It holds the
`x` backing, the `s` and `m` stores, the [root input](#g-root-input) and
[signal tables](#g-signal-table), and the derivative [buffer](#g-buffer). The
set is built from the [activation](#g-activation)'s *layout* (a re-run of
Stratum C at a given scalar type). The layout is the reusable compiled
artifact. The buffers are per-invocation and die with the call (stopped-sim
allocation, [§7.5][s7-5]).

The `Dual` backend's buffers being un-aliasable by type is defense in depth,
not the mechanism. A `Float64` backend (NLopt) gets equally fresh buffers. The
invariant is backend-independent. **The simulation's authoritative stores have
exactly one writer, the commit through [boundary zero](#g-boundary-zero)** (the
initialization boundary: the ordinary macro-sequence with an empty integrate).

Setup applies `override(baseline, condition(guess))` to the scratch set once,
and that application's full coverage is *checked here*. The check is the
comparison of the resolved plan against the `Build`'s `input_faces`
([§14.6][s14-6]), one plan-level comparison before the first evaluation.
[Sweeps](#g-sweep) therefore see a complete world. Raw instantiation is sound
exactly because of that check, since every root input is written before any
read. An incomplete `baseline` is one declaration-ordered
`UninitializedInputs` at setup rather than a whole solve against undefined
[cells](#g-cell).

**The frozen cells are established, not probe-seeded.** At the seeded
activation the discrete [tier](#g-tier) is frozen ([§9.4][s9-4]). Its stages
never run there, so nothing at that activation can derive a discrete output
cell from the authored `s`. Setup therefore instantiates the
[scratch](#g-scratch) set in two halves. A [nominal](#g-nominal) set takes the
composite first, by the dynamic walk ([§14.4][s14-4]), and runs one
establishment round. That round is boundary zero's sweep with every discrete
output stage admitted, due or not ([D-205][d-205]), with no
[projection](#g-projection), no [guards](#g-guard) and no `state_update`. The
seeded set is then written by the specialized register, and its frozen cells
are copied from the nominal set as zero-partial constants (the embedding of
[§14.3][s14-3]). Every cell the iterations read is thus derived from the
authored world. A frozen cell holds what the authored discrete state
publishes, which makes "held at the operating point" literal. No scratch cell
holds the [probe](#g-probe)'s synthesized values. That is the [§14.6][s14-6]
barrier reaching the scratch world, as [D-205][d-205] made it reach the
published one. The iterations are untouched. They are raw write → sweep → read
cycles at the seeded activation, over the continuous chain and
`state_derivative` alone ([§14.5][s14-5]). The zero-decision problem (below)
is the nominal half alone, and its one evaluation is that establishment round
([D-213][d-213]).

The commit applies the same composite over the same `baseline`
(`override(baseline, condition(d*))`, [§14.9][s14-9]), so its coverage is
setup's. Commit's totality check is therefore structurally unfailable through
the trim path, and it stands as the shared `init!`-[boundary](#g-boundary)
defense. A converged solve is always committable. `TrimReport` therefore
carries no committed flag, and the no-throw doctrine needs no exception.

Iterations rewrite the composite's write-set via the compiled plan. The
write-set is `override(baseline, condition(d))`, the same tree setup resolved,
so a store both layers touch merges exactly as it did at setup. An LM
evaluation is one Dual-seeded sweep yielding `r` (value parts) and `J`
(partials) together. No convergence means no commit. Non-convergence is the
service's box test failing at the returned point, whatever status the backend
attached to it. No commit means the sim is bit-for-bit untouched, including
"never initialized". Today's warn-but-assign is structurally impossible.

The same structure covers an interrupt. Ctrl-C during a long solve unwinds an
ordinary Julia call operating on per-invocation scratch stores. No commit has
happened, and the simulation is bit-for-bit untouched, exactly as a
non-converged solve leaves it. The services need no counterpart to the loop's
boundary masking ([§12.4][s12-4]).

#### The commit, in full

The committed solution is applied as an `init!` in every respect. It is
`override(baseline, solution)` through boundary zero, with the pre-write
[root-input totality](#g-root-input-totality) check ([§14.6][s14-6]), the
sequence ([§14.5][s14-5]) and [guards](#g-guard) at commit.

The `t0` argument that anchors the grid, and its default, are the same for
both init-service entry points ([§14.5][s14-5]). The
[recorders](#g-recorders) are cleared exactly as [§12.6][s12-6] states for
`init!`. Those are the [trace](#g-trace), the log, and any
[batches](#g-batch) still in [staging cells](#g-staging-cell) (where a
device's pending write batch waits between drains).

A fresh recording starting at its own anchor is the unattended register's
natural shape. Fly-then-retrim keeps continuity explicitly. The resumed
spelling is `trim!(sim, problem; baseline = c, t0 = t)`, with `(condition, t)`
coming from a `capture` ([§14.1][s14-1]).

#### The report, not an exception

`trim!` returns a structured `TrimReport`:

```julia
# what trim! returns: a value to read, never an exception to catch
struct TrimReport
    converged   # the service's box test at the backend's returned point
    …           # the remaining fields, enumerated below; this section
                # does not name them
end
```

Field by field:

- The `converged` flag is the service's own box test at the returned point,
  never a backend's opinion.
- The solution NamedTuple is guess-shaped, hence warm-startable.
- The **solved-point residuals** come with their tolerances. They are the very
  numbers the verdict is read off, gathered at the backend's returned point.
- The **committed-state residuals** are the same residuals re-gathered from
  the boundary-zero world after the commit.
- The backend's returned status comes with its iteration and evaluation
  counts. These are diagnostic throughout, informative about *how* the solve
  went and decisive about nothing.
- The saturated-bounds list.
- The commit's fired events, as component paths and event names. The list is
  empty when boundary zero ran quiet ([§14.5][s14-5]).

The committed-state residuals are nearly free. That boundary's sweep has
already run, so the residuals' declared reads need only gather from it. There
is no offset caveat to carry. Every output stage publishes at boundary zero
([D-205][d-205], [§14.5][s14-5]), so a residual reading an offset
[component](#g-component)'s [port](#g-port) reads a commit-refreshed cell like
any other. Those committed-state residuals are the numbers describing the
state the simulation is actually *in*, which is the point a
`capture`-defaulted `linearize` reads. A non-empty fired-event set also raises
`TrimCommitEvents` ([Appendix C][sC]). The committed stores then sit at the
post-handler point, not the reported solution, and a `capture`-defaulted
`linearize` ([§14.10][s14-10]) reads that point.

The two residual sets are what make the moved point auditable. A converged
solve whose *committed-state* residuals violate the box test raises
`TrimCommitResiduals` ([Appendix C][sC]), naming the offending residuals with
their committed values and tolerances. The move, whether `state_projection` or
a commit-fired handler ([§14.5][s14-5]), is surfaced rather than left silent.
The verdict itself is not re-litigated. It gated the commit, at the solved
point, and the numbers ([D-150][d-150]) stand as reported.

Non-convergence never throws. It is an expected *outcome*, per the
exceptions-are-broken-machinery line ([§13][s13]). In an envelope sweep,
hitting the infeasible edge is information. A malformed problem is a different
case. It is a `DiagnosticError`-class failure at setup, `TrimProblemInvalid`
([Appendix C][sC]). The malformed cases are a guess/bounds key-set or
field-type disagreement, an unknown `reads` [selector](#g-selector), and a
`tolerances`/residual key-set mismatch observed at the setup guess evaluation.
The error carries the offending field with the names or types in hand,
collected, mirroring linearization's `TapResolution`. A permuted spelling is
none of these ([§14.7][s14-7]).

A throw inside the commit's boundary zero is a third case, and neither of
those. It is model code failing. It propagates out of `trim!` as the commit's
`StepError`. The simulation is left `built` ([§13.4][s13-4], [D-223][d-223]),
and no report is returned for that solve ([D-224][d-224]).

An *empty* problem is none of them either.
[`TrimProblem`](#g-trimproblem)`(guess = (;), …)` is legal, not
`TrimProblemInvalid`. With zero decision variables the solver is bypassed
outright. There is nothing to pack, no seeded activation and no backend call.
The service simply evaluates the residuals once at the
[baseline](#g-baseline). The ordinary box test decides `converged`, and the
commit runs as usual. The degenerate problem is the "is this operating point
an equilibrium?" probe. It evaluates this condition's equations and reports,
which is useful in its own right and free.

#### The AD obligation, scoped

The default formulation requires `Dual` genericity of exactly the continuous
output-stage chains and `state_derivative`, plus the user's assignment and
residual math. The discrete [tier](#g-tier)'s stages and `state_update`, and
the event system's guards and handlers, never see a `Dual`. They are frozen
constants with zero partials, semantically exact ([§8.2][s8-2]).

This is *not a new obligation*. It is the same activation linearization is
defined on. AD-readiness is also a build-checked property. The Dual probe
detonates [pinned](#g-walked) intermediates with a culprit-naming
`InexactError`, and `build(world; activations)` puts it in CI. The robustness
comes from enforcement, not hope.

C172 migration audit (one afternoon):

- `Interpolations.jl` tables (propeller coefficient maps, engine maps) must
  accept generic scalars. They do. But prefer cubic knots over linear where
  partials matter, since linear knots make Jacobian entries
  piecewise-constant.
- In-model saturations (actuator limits, idle/FRC clamps) zero Jacobian columns
  when active. LM damping tolerates the rank deficiency, and the report names
  the saturated variable ([D-070][d-070]). Cruise trim leaves those
  saturations inactive.
- The landing gear is never evaluated off-zero airborne.
- `norm`-at-zero guards are already in place (e5efb3a).

The fallback is per problem, through one `backend =` keyword.

### 14.9 Mounting: problems as relocatable values

**What a `TrimProblem` is.** It is not a condition but an **implicitly
specified condition**. `condition` is a condition-*valued function* over the
decision space. `reads`/`residuals` are the equations that pin the free
variables down. `guess`/`bounds` say where to search. Solving makes the
implicit condition explicit. The commit is then literally an init,
`override(baseline, condition(d*))` through [boundary zero](#g-boundary-zero)
(the initialization boundary: the ordinary macro-sequence with an empty
integrate). The services unify as clients of one condition algebra. `init!`
applies an explicit condition, `capture` produces one, and `trim!` searches a
family for the member satisfying its equations.

**`at` lifts to problems in five lines.** Every field of a problem is either
condition-producing (path-relative) or path-free. The rule that residual math
sees only the gathered NamedTuple ([§14.7][s14-7]) pays off here.

```julia
at(prefix::String, p::TrimProblem) = TrimProblem(
    guess      = p.guess,                      #path-free: pass through
    lower      = p.lower,
    upper      = p.upper,
    condition  = d -> at(prefix, p.condition(d)),  #post-compose: wrap each returned tree
    reads      = at(prefix, p.reads),              #inert selector data: same Scoped node
    residuals  = p.residuals,                      #path-free: pass through
    tolerances = p.tolerances)
```

Resolution then needs nothing new. The flattening accumulator of
[§14.3][s14-3] enters the `Scoped` wrapper and prefixes every entry
(`"vehicle/dynamics"` → `"wing/vehicle/dynamics"`).
[Root input](#g-root-input) entries authored in the aircraft's [face](#g-face)
vocabulary resolve through the export chain *from the mount point* (`throttle`
at `"wing"` → root input `"wing.throttle"`). An unexported face fails
resolution by name, and correctly so. An internally wired input (a
[scenario component](#g-scenario-component) driving the wingman's throttle) is
untrimmable from outside, and the build says so. The service compiles the
scoped condition and reads, and runs the identical loop. It never knows where
its paths are mounted.

**A problem never authors the environment.** The environment is the world's
and the `baseline`'s business. In a full world it is a sibling
[component](#g-component)'s root inputs, and in a thin rig it is a
handle-valued root input. The problem *receives* its handles through the user
parameter record ([§14.7][s14-7]), and only queries them.

**Why.** The reason is the resolution rule just stated. A condition entry
naming a wired input fails by name, correctly. A problem writing an
environment face would therefore be applicable only to those rigs where that
face happens to be unconnected. The relocatability this section exists to
guarantee would be lost.

**The world wrapper dissolves.** Today's `f_init!(::Model{<:SimpleWorld})`
(initialize environment, then call the aircraft's trim) has no successor
method. The environment, the other aircraft and all root inputs are covered by
the `baseline` condition ([§14.6][s14-6]), applied once at setup. The commit
is `override(baseline, at(mount, condition(d*)))`. Method nesting became value
layering.

**"Aircraft as root" is a thin world.** By default the aircraft is not
literally the root. Its environment inputs ([§4.4][s4-4] function-valued
signals) are wired from provider components. Design tasks therefore use a
shipped rig, `design_world(ac)` = aircraft +
`SimpleAtmosphere(wind = NoWind())` + `HorizontalTerrain`. That rig is today's
ad-hoc models inside `linearize` promoted to a named artifact. There is one
register. The "root" case is the shallowest world, and the trim problem mounts
at `"aircraft"` like anywhere else. Leaving an environment face *unconnected*
is legal by construction, though. The face becomes an ordinary root input
holding the handle **value**, written by the `baseline` like any other root
input. That is the test-rig register. It is the function-valued sibling of a
[constant source](#g-constant-source) (a library component publishing a value
its instance holds), with zero ceremony for a frozen environment. For design
tasks the shipped rig stays `design_world(ac)`. That keeps the environment's
tunables in the root-input vocabulary that conditions, `capture`,
linearization's input surface and the [trace header](#g-trace-header) already
speak.

**Swarm doctrine.** The service solves *one problem at a time*. Sequential
independent trims (trim lead, commit, trim wing against the committed world)
cover weak or one-way coupling. A joint trim is user-side value composition.
Concatenate decision NamedTuples under prefixed names, combine the scoped
condition trees, and stack the residuals. If joint trims become routine, a
`product(p₁ => "lead", p₂ => "wing")` helper belongs in the [§13.7][s13-7]
library. That helper is [recorded, not built](#g-recorded-not-built) (a
worked-out extension deliberately left unimplemented, its seams named).

### 14.10 Linearization: tap selectors, one seeded pass, a pure query

**The tap declaration.** Today's per-aircraft
`XStateSpace`/`UStateSpace`/`YStateSpace` structs, plus the
`get_*_ss`/`assign_*_ss!` shuttle methods, run to ~150 lines of bookkeeping
per variant. All of it becomes three [selector](#g-selector) lists (the closed
family of deferred reads resolving against a source). Three members of the
read-selector family supply them: `get_state`, `get_input` and `get_output`
([§14.4][s14-4]). The lists carry the optional [component](#g-component)
index, so a vector leaf yields *named scalars*. The NamedTuple key is the
label control design slices by.

```julia
x = (p = get_state("vehicle/dynamics", :ω_eb_b, 1),
     θ = get_state("vehicle/kinematics", :θ_nb), …)
u = (throttle_cmd = get_input("throttle"), …)
y = (EAS = get_output("vehicle/airflow", :EAS), …)
```

The three lists are validated at resolution, with
[did-you-mean](#g-did-you-mean) errors (the offending name plus the
list-in-hand it should have matched). The `x` list is validated against the
continuous tier's `init_x` stores, the `u` list against [faces](#g-face), and
the `y` list against `output_types`. An `x` entry naming a discrete store is
rejected at resolution with the entry and its tier in hand. That is the
no-silent-zeros rule again ([D-167][d-167], [D-197][d-197]). The frozen tier's
only possible partials are zeros, and the rejection's next-move guidance
points at the recorded step-map extension below. The lists compile to offsets
once, and relocate whole via `at(prefix, taps)`. The shuttle layer's successor
is that compiled writer/reader pair, and the promised `get_x_ss` deletion
([§7.1][s7-1]) is discharged.

**The evaluation.** Each invocation instantiates its own scratch store set, the
trim service's mechanism verbatim ([§14.8][s14-8]), and applies the
operating-point condition. It then runs **one** Dual evaluation, seeded with
one direction per `x`-tap and per `u`-tap entry (chunked internally). Value
parts give `ẋ₀` and `y₀`. Partials give `A` and `B` against the `x`- and
`u`-seeds, and `C` and `D` against the same seeds read at `y`. All four come
out simultaneously, exact to machine precision.

```
  x-taps ─┐                                         ┌─ value parts → ẋ₀, y₀
          ├─ seed directions → one Dual evaluation ─┤
  u-taps ─┘          (chunked internally)           └─ partials    → A, B, C, D
```

That single pass replaces four `FiniteDiff` jacobians, their step-size
heuristics and ~4n perturbed evaluations.

**What the pass seeds, and what it holds frozen.** Unseeded states sit
constant at the operating point, and so do unseeded
[root inputs](#g-root-input). The condition apply embeds their `Float64`
values as zero-partial constants. A root-input [cell](#g-cell) follows the
[activation](#g-activation) scalar (a re-run of Stratum C at a given scalar
type) by *evaluating* its consuming `input_types` entry at that scalar
([§8.2][s8-2]). The discrete [tier](#g-tier) is frozen with zero partials,
which is precisely "linearize with the discrete state held" ([§8.2][s8-2]).
Differentiation participation is a per-invocation *seeding* fact for every
root input the schema leaves seedable, one register for `x` and root inputs
alike. One declared exception is visible in the schema. A root input whose
entry is declared `Float64` is **declaredly unseedable**, and its cell is
frozen at every activation. Selecting it as a `B`-matrix tap is therefore
rejected at tap resolution with the offending entry in hand, rather than
silently yielding a zero column ([D-167][d-167]). Under fan-out the rejection
names the **pinning consumer**, not the face alone. A root input is unseedable
whenever any one of its consumers demands frozen, which is the fan-out meet
([§8.2][s8-2]; [D-168][d-168]). The author's next move is to promote that leaf
to a tolerant entry, or to route the tap around it. Either move depends on
knowing which leaf froze the root input. Seeded and frozen, side by side:

| leaf | in the one pass | what fixes it |
|---|---|---|
| a state leaf named by an `x` tap | seeded, one direction | per-invocation seeding |
| any other state leaf | sits constant at the operating point | per-invocation seeding |
| a root input named by a `u` tap | seeded, one direction | per-invocation seeding |
| any other seedable root input | constant, its `Float64` value embedded as a zero-partial constant | per-invocation seeding |
| a root input whose entry is declared `Float64` | frozen at every activation, and rejected as a `B`-matrix tap | the schema: a declaration |
| any discrete-tier leaf | frozen, zero partials | the tier |

**A pure query, and the shape of `capture`.** Linearization is the first
service with no commit and no [boundary zero](#g-boundary-zero) (the
initialization boundary: the ordinary macro-sequence with an empty integrate).
It works on scratch buffers only, and nothing it computes becomes
authoritative. Today's restore-the-trim dance, the re-`assign!` after
`FiniteDiff` dirtied the model, has no successor. The default operating point
is the sim's current committed state, taken through
`capture(sim) → (condition, t)`. That gather covers stores *and root inputs*
in full. Root-input totality ([§14.6][s14-6]) makes root-input coverage
mandatory for capture → apply. After a `trim!` commit, `linearize(sim, taps)`
is about the trim point with nothing re-specified. An `about = <condition>`
keyword linearizes anywhere else without touching the sim.

**The returned object and `LinearizedSS`.** `linearize` returns labeled data,
`(ẋ₀, x₀, u₀, y₀, A, B, C, D)`, carrying the label sets of the
[taps](#g-taps) (the three selector lists declaring what linearization seeds
and reports). On that data, `subsystem`/`delete_vars` survive as pure
label-indexed matrix slicing, with no model involvement. The `c172x_ctl` LQR
pipeline consumes it with cosmetic changes. `LinearizedSS` the *component*
survives separately, as an ordinary
[continuous component](#g-continuous-component) in the migrated library. Its
`init_x` is the state vector, its faces are labeled, and the affine update
lives in `output_direct`/`state_derivative`. It has no privileges, and its
schema is everyone else's.

**Recorded guidance.** Linearization taps should select minimal-coordinate
mechanizations. Perturbing Euler-angle states is meaningful where seeding
quaternion components steps off the unit-norm manifold. This is why today's
code linearizes the `{NED}` variant. `design_world(ac)` rigs that variant,
promoting implicit practice to stated rule. The coordinate choice belongs to
the tap author, not the framework.

**The sampled-data Dual activation is
[recorded, not built](#g-recorded-not-built)** (a worked-out extension
deliberately left unimplemented, its seams named). The frozen-exact doctrine is
consumer-scoped, not a capability wall. Today's services differentiate the
continuous dynamics with the discrete state held. For that, a frozen discrete
output (a ZOH constant with zero partials) is the exact answer. The type
system enforces it ([§8.2][s8-2]). This is stated once, because the question
recurs. **The frozen discrete cell is not an AD limitation on the signal path.
It is the true zero of an instantaneous dependence that the hybrid semantics
never had.** The dataflow through a discrete component is temporal, not
instantaneous, and AD follows actual dataflow.
`frozen_discrete_walkthrough.md` works the three-component chain through.

Differentiating "through" the discrete side means differentiating a
*different object*. That object is the sampled-data step map
$\Phi : ((x_k, s_k), \mathrm{inputs}) \to (x_{k+1}, s_{k+1})$, taken over the
model's *whole* state, both letters at once. One evaluation of $\Phi$
integrates one period, then runs the [due](#g-due) [ticks](#g-tick). The
extension is additive along existing [seams](#g-seam).

- **[Walked](#g-walked)-leaf parametrization** of the discrete tier's
  real-scalar state leaves. Counters and enums stay [pinned](#g-walked), like
  `m`.
- **Opt-in participation** on discrete components, with frozen-exact staying
  the default. A participating component opts in through an explicit trait,
  and that trait **brings the two-argument `T`-form of `output_types` with
  it**. It flips the leaf's mandated declaration shape from the plain form to
  the continuous one ([§8.2][s8-2], [§8.5][s8-5]). Participation therefore
  stays authored per leaf on that tier too. The hinge is recorded here so the
  two forms stay compatible, which gives graceful migration with no flag day.
- **One new activation** ([§9.4][s9-4]): "continuous chain + `state_derivative`
  + the discrete tier's output stages + `state_update`".
- **Forward sensitivities** through the in-house RK steppers, for free. That
  is a payoff of owning the loop ([§10.1][s10-1]).
- **A distinct `s`-tap register** beside the `x` list, labeling the step map's
  state blocks $\partial(x^+, s^+)/\partial(x, s)$ ([D-197][d-197]). The `x`
  list keeps its continuous meaning unchanged.

The honest boundary is that $\Phi$ is differentiable only where the event
pattern is locally constant. Exactness across a firing needs saltation
corrections. The scope is therefore event-quiescent operating points, which
trim points already are, because [guards](#g-guard) at commit see to that
([§14.5][s14-5]). The scope comes with a loud diagnostic if an event fires
inside a differentiated step. Two consumers wait. The first is the closed-loop
trim door ([§14.7][s14-7]), whose $g(s) - s = 0$ residuals currently imply the
derivative-free fallback, since a frozen `state_update` has no Jacobian
columns. The second is exact discrete-time linearization of the full loop,
which is digital design on the exact discretized plant instead of continuous
linearization plus Tustin.

**Declarative non-participation: what the schema states, and what stays
recorded.** **Both halves of this door have a spelling.** The output half is
[D-166][d-166]. A continuous producer's declaration is per-leaf, so "this
[port](#g-port) is frozen under differentiation" has a spelling. Declare the
leaf `Float64`, and strip with `ForwardDiff.value` inside the stage
([§8.2][s8-2], [§9.5][s9-5]). An opaque wrapper (an FMU, a C aerodynamic
table) and a deliberately severed coupling can therefore both say so in the
schema, instead of showing up in Jacobians as unexplained zero rows. The
conformance check holds them to it at every activation.

The input half is [D-167][d-167]. A consumer's entries are per-leaf too, so a
`Float64` entry declares "never hand me partials". That is the AD-incompatible
component's own statement, enforced at the wire ([§6.1][s6-1]). At a root
input, such an entry *is* the forbid-seeding marker itself. That marker
carries semantics rather than mere protection, because it types the
root-input cell at every activation. An unseeded root input is therefore a
*choice*, where a `Float64`-entry root input is a *declaration*. Tap
resolution rejects the latter with the offending entry in hand instead of
returning a silent zero column.

What stays recorded is only the remaining **tooling** over that visibility.
One piece is pinned-face validation by the tap declaration, where selecting a
declared-frozen output is a warning. The other is a
[feedthrough](#g-feedthrough)-graph lint, where a frozen output fed by
participating inputs names the severed coupling. Both are additive when a
consumer shows up, with no flag day. Until then the declared pins and the
visible zero rows suffice.

---

# Part V — Grounding

Part V grounds the design and marks what it leaves open. [§15][s15] is five case
studies, each starting from code that exists today: the `Vehicle`
transliteration that validated [§5][s5], torture tests aimed at the [§5.2][s5-2] interfaces
and at the [§11][s11] staging shapes, the full C172X demo read as a load test on the
periphery, and the strapdown IMU challenge to the [§3][s3] class split. [§16][s16] records
the three axes still to be settled, the migration of FlightPhysics and
FlightApps among them.

Part V assumes the whole specification and norms none of it. The case studies
are evidence rather than rules, so where a measurement here and a rule earlier
disagree, the rule wins. They keep their worked comparisons at full resolution,
which is the one place the rationale-belongs-in-the-decision-log rule is
relaxed.

## 15. Case studies

### 15.1 `Vehicle` today → this framework

This case study is the grounding exercise that validated [§5][s5]. Current
`Vehicle.f_ode!` (`aircraftbase.jl:142-170`) is a hand-woven instance of the machinery
specified here:

| Today (convention) | This design (checked structure) |
|---|---|
| `kinematics.u .= dynamics.x` — velocity extracted directly from the state vector because `f_ode!(dynamics)` can't run yet | `dyn`'s stage-1 output, scheduled first by construction; the artificial loop in `VehicleDynamics` dissolves ([D-035][d-035]) |
| Hand-ordered `f_ode!` body (kinematics → airdata → systems → route five `dynamics.u` assignments → dynamics last) | Build-time topological sort; wrong wiring = build error naming the cycle or dangling [port](#g-port) |
| Velocity state duplicated in `dynamics.x` and `kinematics.u`, kept in sync by hand | One state, one owner; consumers wire to `dyn.vel` |
| `get_wr_b`/`get_mp_b`/`get_hr_b` generated tree-walk sums | [Summing junctions](#g-summing-junction) at ownership boundaries, one explicit wire per contributor, exported totals ([§6.2][s6-2]) |
| `f_step!` quaternion renorm + engine-phase/stall-latch checks | `state_projection` hook + [boundary-detected](#g-boundary-detected) events with defined semantics |
| `Aircraft.f_ode!` runs avionics before the vehicle → continuous avionics reads one-stage-stale `vehicle.y` (implicit delay) | Avionics scheduled inside the [sweep](#g-sweep), after the stage-1 outputs avionics consumes — no delay. Or avionics declared periodic, sampling post-step by stated semantics |
| `atmosphere`/`terrain` threaded as arguments through every signature | Field-handle signals through ordinary ports ([§4.4][s4-4]) |

Two of those entries carry detail a cell cannot hold. The artificial loop in
`VehicleDynamics` is the pairing of a state-only velocity output with
[feedthrough](#g-feedthrough) accelerations. The hand sync of the duplicated velocity
state reaches into initialization, where `f_init!` carries the line
`dynamics.x .= kinematics.u  #essential`.

The same exercise surfaced a migration cost: today's monolithic `KinData` splits in
two, because its parts genuinely have different dependencies.

- `pose` — stage 1: `q_eb`, `r_eb_e`, `ϕ_λ_h`, ...
- `kin_vel` — stage 2: `v_eb_n`, `v_gnd`, `χ`, `γ`, ...

The recurring trade, stated once: the framework asks authors to write down structure
previously kept in their heads, and pays them back by never letting that structure
silently rot.

The genuine [algebraic loop](#g-algebraic-loop) in the domain — α̇-dependent
aerodynamics — is already broken in the current C172 model by a filter state, exactly
the explicit break [§5.5][s5-5] prescribes. That precedent is evidence that the
reject-loops policy matches domain practice rather than fighting it.

### 15.2 Torture tests for the §5.2 interfaces: `PistonEngine` and the FCS PID cascade

Three exercises, each starting from code that exists today. Two [components](#g-component) were
transliterated to validate the decoder interfaces before adoption: `PistonEngine`
on the continuous side, `PID` and the C172X FCS on the discrete one. A third
exercise takes the supervisor sitting one level above those compensators. Each
is read first as what today's code does, then as what this design makes of it.

#### `PistonEngine`: the continuous side

The current engine (piston.jl:310-449) carries a mode enum with three flow
regimes, four table lookups, two embedded continuous PI compensators, boolean
transitions and an argument-threaded `fuel_available`. The points below place
each of those features under the decoder interfaces.

- The compensator paths (`idle`, `frc`) are pure functions of the engine's own
  state `ω`. Their complete PI laws — outputs *and* state derivatives —
  therefore evaluate in `output_state`. (The alternative factoring, compensators as
  child components of an engine [assembly](#g-assembly), also [schedules](#g-schedule) cleanly from the
  core's stage-1 [ports](#g-port).)
- `output_direct` runs the lookup chain and the mode branch once.
  `state_derivative` is a three-field
  copy (`ω̇`, `ẋ_idle`, `ẋ_frc`). Under the orthodox split, `f(x, u, t)` would reproduce
  essentially the whole `f_ode!` body — four lookups and the mode branch — ×4
  RK stages per step ([D-015][d-015]).
- `f_step!`'s transitions become [boundary-detected](#g-boundary-detected) events with mixed [predicate](#g-predicate)/threshold [guards](#g-guard)
  ([§2.1][s2-1]).
- `fuel_available` becomes an ordinary port. It is state-derived at the fuel
  system, hence a stage-1 port — no loop.
- Forced publications: none — everything `state_derivative` reads was already in `PistonEngineY`.

#### `PID` and the C172X FCS: the discrete side

`PID` (control.jl:431-471) and the C172X FCS around it are the discrete side's
representative.

- The current update entangles outputs and next state by construction. The
  spelling is `y_i = s_i`: this [tick](#g-tick)'s integral-path output *is* the updated
  integrator state.
- Under [§5.3][s5-3] the law runs once in `output_direct`, publishing paths, saturation and the
  updated states; `state_update` is a three-field copy.
- Under the orthodox split, `g(s, u, t)` would reproduce the entire law per
  compensator per tick ([D-015][d-015]).

**Discovered latent delay.** The FCS chains anti-windup: outer compensators
take `sat_ext` from the inner LQR's `sat_out` (c172x_ctl.jl:332,345,...). Wired
naively, that chain is a *genuine* tick-domain [algebraic loop](#g-algebraic-loop), and the build
correctly rejects it:

```
outer.output → inner.input → inner.sat_out → outer.sat_ext →
outer.int_halted → outer.y_i → outer.output
```

Today's code escapes the loop only through hand-managed call order: the outer
loops read the LQR's `sat_out` *before* the LQR updates, silently consuming
the **previous tick's** value. That is a unit delay existing nowhere in the
code, only in statement ordering.

Under this design the fix is one visible wire: connect `outer.sat_ext` to the
inner compensator's stage-1 port for the previous saturation, `sat_out_0`.
That port is an `s` field declared in the LQR's output [contract](#g-contract), hence
auto-published at stage-1 position ([§8.3][s8-3]). The delay becomes an explicit
property of the wiring. The loop and its fix are formalism-independent: the
framework's contribution is refusing to let the ambiguity through, and stage
1's contribution is having the delayed value already on a port.

Both components passed without blockers, with zero publications forced beyond
current practice. That result is the empirical basis for the claim ([§5.3][s5-3]) that
derivative/output overlap is the domain norm and that the decoder matches the
codebase's grain.

#### The supervisor slice: scheduled gains and bumpless engage

One level above the compensators, today's `c172x_ctl.jl` runs on two idioms
the [stores](#g-store)-and-[views](#g-view) rules deliberately remove. The first is per-tick gain
scheduling by mutation: `assign!` writes `Ref`-cell parameters from
EAS/altitude lookups every 50 Hz tick, LQR matrix sets included. The second is
mode-transition resets: `f_init!` plus a bumpless-transfer latch, hand-ordered
*before* the same tick's `f_periodic!`. Both survive as dataflow.

*Scheduled gains are inputs.* A scheduler component owns the lookup tables as
inert parameters, reads the scheduling variables as inputs, and publishes one
gain bundle per compensator; compensators consume gains as `u`. What mutation
hid, ports expose. Gain trajectories become observable in log, [trace](#g-trace) and
[replay](#g-replay); the `Ref` writes were invisible to all three. The [feedthrough](#g-feedthrough)
graph carries the dependency. Linearization holds unseeded gain inputs
constant with zero special-casing ([§14.10][s14-10]). One-shot design-time gains
(`robot2d`'s controller synthesis at init) are construction-time parameters or
stopped-sim service outputs — not a runtime write path.

*Resets are same-tick inputs, consumed in the output stage.* The supervisor
publishes `engage` and the latch value from its own feedthrough stage; the
compensator, topologically after the supervisor, honors them **this tick**:

```julia
output_direct(c::PI, (; s, u)) = (; u_cmd = u.engage ? u.u_latch : c.k_p*u.e + s.s_i)
state_update(c::PI, (; s, u, Δt)) = (; s_i = u.engage ? u.u_latch - c.k_p*u.e
                                                      : s.s_i + c.k_i*Δt*u.e)
```

Honoring the reset only in `state_update` is legal, and it means something else. The
state still lands correctly at the next tick. But the *output at the
engagement tick* was already published from the stale state during the [sweep](#g-sweep),
and under ZOH the plant integrates a full step under that stale command. That
one-tick-late command is exactly the bump that bumpless transfer exists to
remove. No diagnostic can catch the bump: both spellings are meaningful
designs.

The update stage cannot rescue its own [boundary](#g-boundary) — republish-from-`s⁺` is
rejected ([D-067][d-067]) — so the output stage is the *only* same-tick path. Today's
hand-ordering (`f_init!` before `f_periodic!` in one call) is that same-tick
reset contract enforced manually. [Appendix A][sA] carries it as the same-tick reset
entry, and the bumpless-engage answer ([§11.7][s11-7]) presupposes exactly this
spelling — engage semantics live in the FCS.

One relative lives outside the FCS. The landing gear's level-triggered
cross-component reset (`!wow` re-initializing the friction regulator every
step) becomes an edge-triggered event owned by the regulator, a semantic
tightening recorded in the migration mapping ([§16][s16]). There the respelling is
not a stylistic one: the continuous [tier](#g-tier) admits no input spelling at all,
because only handlers write `x` ([§3.1][s3-1]). The event is therefore necessity
rather than taste, and the reimplemented `PIVector`'s optional reset [face](#g-face)
([§16][s16]) is sugar over exactly that event. [Appendix A][sA] carries the
continuous-reset contract too.

### 15.3 Torture test for the §11 staging shapes: filter, joystick and GUI

This case study is the exercise that selected per-[device](#g-device) [cells](#g-staging-cell)
([§11.4][s11-4]) and produced the [§11.7][s11-7] staging contracts. Setup: a
first-order filter with root inputs `u_cmd` and `τ`; a fictitious 100 Hz
single-axis joystick streaming a slow ramp onto `u_cmd` (complete writer); a 60
Hz GUI with sliders for both [root inputs](#g-root-input) (sparse writer); 50 Hz
[boundaries](#g-boundary); pace 1. The interference on `u_cmd` is the point.

Three candidate staging shapes were on the table: **per-input cells**, a shared
**[batch](#g-batch) stack**, and **per-device cells**. The user-level listing
came out identical across all three — ergonomics cannot discriminate between
them; behavior under a concrete interleaving did.

**Root-input exclusivity rules out the very contest the setup builds.** Under
root-input exclusivity ([§11.3][s11-3]) the contested-`u_cmd` scenario cannot arise — a
second writer on `u_cmd` is an attach-time error. What the test settles is
therefore the cell *shapes*: atomicity, [coalescing](#g-coalescing), pause
behavior and the peek rule. Its conflict-precedence comparison and the
active-widget stage-every-pass contract ([§11.7][s11-7]) describe a contested-input
world the design does not have. The findings below are read under that scope.

- **Drag against the stream** — the user grabs the `u_cmd` slider while the
  joystick streams. Under per-input cells and the batch stack, each
  [frame](#g-frame)'s conflict resolves by last-store/last-push wall-clock order
  ([D-024][d-024]). With 16.7 ms renders against 10 ms polls, the applied input
  alternates between drag value and ramp on the cadence beat, the filter visibly
  wobbles, and the pattern differs run to run. The [trace](#g-trace) replays any
  given run exactly; the behavior is still a timing artifact. Under per-device
  cells the GUI stages in every drag frame: ≥ one render per 20 ms frame, plus
  the active-widget stage-every-pass contract. The GUI therefore wins every
  [drain](#g-drain) (the
  frame-top swap that publishes staged device writes into the root inputs) by
  attachment order. That win is a clean, deterministic override for exactly the
  grab duration. Same user code, qualitatively different physics.
- **Edits while paused.** Under per-input cells, the user's `u_cmd` edit is
  overwritten by the still-polling joystick ~10 ms later ([D-024][d-024]); the knob
  visibly snaps back and the edit never applies. Under the batch stack, the edit
  is buried under newer pushes, and the pending chain grows at the polling rate
  — ~10³ nodes per 10 s pause — with every [peek](#g-peek) walking that chain
  ([D-024][d-024]). Under per-device cells, the `u_cmd` edit holds in the GUI's own cell
  across the pause, the knob keeping the edit by the [§11.7][s11-7] peek rule. That
  edit merges with the `τ` edit — the sparse-accumulation case — and applies at
  the un-pause drain, for one deterministic frame before the joystick reclaims
  the root input. That one-frame application is the honest semantics of one-shot
  editing a streamed input. The uncontested `τ` edit works under all three
  shapes.
- **Corrections the exercise forced.** The sparse-writer lost-write hazard is
  specific to one-cell-per-device layouts: per-input cells cannot lose
  independent-input writes; the CAS merge is per-device cells' antidote, not a
  general need. And the batch stack's conflict order is temporal, not an
  attachment-order policy ([D-024][d-024]).
- **Discoveries.** Two: the active-widget contract, and the
  [port](#g-port)-resolution answer to panel reuse ([§11.7][s11-7]) — prompted by
  asking how the filter's panel survives the filter becoming an embedded
  [component](#g-component) with `u_cmd` driven by another component. That
  embedded-filter case is the `Cessna172Xv0` → `Xv1` throttle situation.

### 15.4 The interactive C172X demo: the periphery under load

The full-fidelity successor to [§15.3][s15-3], against the real deployment:
`generic_simulation()` (`FlightApps/demos/c172_demos.jl`) —
`SimpleWorld(Cessna172Xv1, SimpleAtmosphere, HorizontalTerrain)`, GUI, joysticks,
an XPlane12 output [device](#g-device), ground/trim init, paced run, post-run plots. Method:
FlightCore's mechanisms are reference *behavior*, not requirements — the question
is whether the new machinery expresses the experience (move stick, plane banks),
never how to reproduce `assign_input!`. The interactive surface is *not* one
thing: pilot commands cluster under a prefix; environment knobs stay with their
components' panels. Inventory of the complete interactive surface, with each
item's home:

- **Streamed commands** (`throttle_axis`, `elevator/aileron/rudder_axis`): today
  written by joystick mappings after shaping *and* by GUI sliders on the same
  fields. Every dual-writer field in the demo is this pattern — a stream shadowed
  by a mirror, where simultaneous live writing is a bug. This adjudicated [root-input](#g-root-input)
  exclusivity ([§11.3][s11-3]): [claim](#g-claim)/disable covers every case found; none needs two
  concurrent writers.
- **Edge-driven increments** (trim offsets ±5e-3 per hat release, flaps ±⅓ per
  button release): today `+=` deltas executed *inside the mappings*, accumulating
  in model `u` — the levels-never-deltas violation, live in the codebase.
  Becomes: devices stage monotonic press counters; accumulator state lives in the
  model (avionics discrete state).
- **The shaping stack**: exp curves and deadzones (defined in the aircraft
  variant module, duplicated *verbatim* across the T16000M and Gladiator
  mappings — the duplication smell), plus the `q_ref = q_sf · axis` fan-out. It
  decomposes into device conditioning (device truth), feel curves (deployment
  preference) and command semantics (FCS design); the [face](#g-face) [contract](#g-contract) splits it —
  conditioning upstream as mapping data, semantics in-model ([§11.4][s11-4]).
- **Mode engage** (`mode_req` + setpoint capture from current measurements — the
  GUI handler does `u.EAS_ref = EAS` read from `vehicle.y`): the one place the
  GUI composes writes from model state. Resolved under *Frame anatomies* below.
- **Vehicle-direct and environment tunables** (engine start/stop/mixture, payload
  masses, terrain surface enum, sea-level T/p, wind NED): ordinary [component](#g-component)
  inputs exported to root faces; the GUI writes them under its [greedy claim](#g-greedy-claim)
  (the unclaimed complement, computed by the framework instead of returned) via
  [§11.7][s11-7]; no machinery.
- **The Xv1 actuator sliders**: FlightCore's dead sliders; resolved read-only by
  [§11.7][s11-7]. No action.
- **Outbound** (XPlane12: control-surface angles, nose-wheel steering, prop
  speed/phase, pose, `t`): a [snapshot](#g-snapshot)-consuming device, pure `map_output` on the
  device task ([§11.2][s11-2]). No friction found.
- **Init/trim, pause/pace, post-run plots**: stopped-sim services ([§14][s14]), control
  plane ([§12.1][s12-1]), log/[trace](#g-trace) ([§11.2][s11-2], [§11.5][s11-5]).

#### Architectures examined here and rejected

The [§11][s11], [§12][s12] [periphery](#g-periphery) decisions were
forced by this cast: [devices](#g-device) as [components](#g-component) (a `T16000M`
component wrapping SDL), a root-level `PilotInterface` cockpit component, and
bundled command [faces](#g-face) (`pilot_inputs` as one struct [port](#g-port)) —
all three litigated in [D-045][d-045]. What each leaves behind is the design's own
answer:

- the *knowledge* half of a device model — its semantics — is expressible as an
  ordinary in-model [component](#g-component) wherever wanted; only the wall-clock
  pump stays outside;
- the cockpit component's claimed jobs are covered where they belong: struct
  assembly in-model downstream of scalar faces, curves as mapping
  data, widget arbitration by [§11.7][s11-7] plus exclusivity, and the stateful
  residue (accumulators, capture-on-engage) in the avionics;
- the routing convenience a command bundle bought in FlightCore's
  argument-threading world is provided by the namespace prefix and
  `input_passthrough` ([§8.8][s8-8]), with the struct reappearing legitimately
  downstream, assembled in-model by a single producer.

#### Surface walkthrough

The demo line by line:

- `SimpleWorld(Cessna172Xv1(), SimpleAtmosphere(), HorizontalTerrain(h_LOWS15))` —
  pure value construction; no `Model` wrapper (its jobs move into the build).
  `HorizontalTerrain`'s elevation is a plain field (parameter), its surface type
  an input [port](#g-port): the parameter/port split FlightCore kept implicit in
  `U()`-vs-field convention is now the declaration itself. The aircraft's
  `input_connections` block carries the `pilot.*` [face](#g-face) group in one place,
  handed one level down to avionics and systems and re-routed at each level below
  ([§6.1][s6-1]) — today's mapping writes flaps/brakes directly
  into `act`, bypassing avionics; that bypass becomes a declared route.
- `Simulation(world; algorithm = RK4, h = 0.02, N_base = 1, t_end = 1000)` — `N_base`
  binds `Δt_base = N_base·h` ([§10.5][s10-5]; default 1: base [tick](#g-tick) every step). The entire
  build pipeline runs here: [class](#g-class) resolution, path validation, face derivation
  (computed interface connections expanded, printable), two-producers/unconnected checks,
  topological sort, [probe](#g-probe) passes, rate compilation, flat layout, [root input](#g-root-input) table.
- `init!(sim, ready_for_taxi(ac); t0 = 0.0)` — stopped-sim services ([§14][s14];
  trim is its own service, `trim!(sim, problem; baseline, …)`, whose commit
  runs the same boundary): they write `(x, s, m)`, **establish every
  root input's initial value**, and capture the [trace header](#g-trace-header). Root-input initialization
  decisively belongs here, not in declarations: the trim service writes root-input
  values it *solved for* (throttle, elevator) — not declaration constants.
- `attach!(sim, XPlane12Control(…), binding)` — output [device](#g-device): [claims](#g-claim) nothing,
  consumes [snapshots](#g-snapshot) via [§12.3][s12-3], pure `map_output` on its task. Its [binding](#g-binding) names
  snapshot paths, **validated at attach against the actual [contract](#g-contract)** — an
  aircraft substitution that breaks the binding fails at attach, not with silent
  garbage UDP (a new, cheap [§11.2][s11-2] obligation).
- `attach!(sim, joystick, T16000MBinding())` — the binding is a declarative
  table: axis/button → face name + conditioning params
  (`stick_y = (face = "aircraft.pilot.elevator_axis", expo = 1.0, deadzone =
  0.05)`, `button_3 = (face = "aircraft.pilot.flaps_up_count", as = :count)`).
  At attach: faces resolved against the root contract (typo → [did-you-mean](#g-did-you-mean)),
  claim set registered (second joystick on the same faces errors here). The
  Gladiator variant is the same table with different keys, zero shaping code —
  the duplication smell structurally gone.
- `run!(sim; gui = true, pace = 1)` — a [greedy claim](#g-greedy-claim) over every
  unclaimed face and liveness with zero configuration, both settled at run start
  against the [frozen roster](#g-roster) ([§11.3][s11-3]): axis mirrors read-only
  (claimed, with provenance), mode/setpoint/mixture/payload/environment widgets
  live, actuator sliders read-only ([component](#g-component)-fed). The `gui`
  flag's attachment lasts exactly this run ([§12.6][s12-6]).
  Unplug the joystick → its task exits. The mirrors stay read-only with the
  death in their provenance ("claimed by `T16000M` — task dead"), and the axes
  hold their last-drained values; those two behaviors are the accepted orphan
  anomaly ([§11.3][s11-3]). Recovery is between runs: stop, `detach!`, then
  `init!` for a fresh trajectory, or `replay!`-to-end + `run!` to continue the
  interrupted one ([§12.7][s12-7]).
  Post-run: `TimeSeries` over retained snapshots; the [trace](#g-trace) can
  re-drive a fresh `Simulation(world)` bit-identically. That replay is also the
  state-trajectory inspector ([D-038][d-038] paying its way).

#### Frame anatomies

One [frame](#g-frame) each:

- *Stick motion*: [device](#g-device) task polls, conditioning helper applies binding params,
  complete [batch](#g-batch) overwrites the [cell](#g-staging-cell) (inter-frame polls coalesce, ZOH-correct);
  [drain](#g-drain) applies + [traces](#g-trace); avionics [tick](#g-tick) reads the [root input](#g-root-input) fresh; worst-case
  stick-to-physics latency = poll interval + frame, now by stated semantics.
- *Flaps click*: button [peeks](#g-peek) counter `k` (own-pending-else-[snapshot](#g-snapshot)), stages
  level `k+1` on activation; drain applies; avionics compares the root-input counter to its
  `s` counter, moves the detent, stores. Multi-click in one window counts via
  own-pending-first peek; repeated staging idempotent ([§11.7][s11-7]).
- *Mode engage*: the GUI stages `mode_req`, plus optionally peek-captured
  setpoint root inputs. **Bumpless-engage semantics live in the FCS already**: the
  current `ControlLaws` latches each controller's reference from the present
  command vector on mode transitions. So the capture fork dissolved: semantic
  capture is aircraft design. That arrangement is the status quo, and it is uniform across
  writers — a script engages sanely staging one value.
  The GUI [peek](#g-peek)-batch ([§11.7][s11-7]) therefore
  survives as display/input-sync sugar only. Residual check for migration:
  order-sensitivity of latch vs. sync-write on the same [boundary](#g-boundary)
  (believed none — both derive from the same measurements).
- *Wind slider*: sparse CAS-merge, the uncontested-`τ` case ([§15.3][s15-3]), live in the
  real cast.
- *Pause/un-pause*: [control plane](#g-control-plane); GUI edits hold in its cell (peek displays),
  joystick cell coalesces bounded; un-pause drain applies both (disjoint root inputs —
  exclusivity makes the contested question unaskable), pacer re-anchors.
- *Window close*: [§12.4][s12-4] verbatim — complete boundary, final snapshot, sticky
  stopped, wake waits, unblock hooks, named-timeout joins.

Remaining open (feeding [§16][s16]): the `q_sf` home (thin mapping entry vs.
avionics-internal derivation — aircraft design, not framework design), and the
mode-engage entry's write-order check.

### 15.5 The strapdown IMU: integrate-and-dump across the tier boundary

The strongest challenge mounted against the [§3][s3] class split, and its resolution.
The general question first: why two leaf classes at all — why not one all-in-one
primitive carrying continuous state, modes *and* discrete state, with `state_derivative`, events *and* `state_update`, purely
continuous or discrete [components](#g-component) falling out by whichever facets an author
declares? ([Class](#g-class) is already read off declaration shape, [§8.5][s8-5] — the question is
whether the two declaration sets should be exclusive.)

#### Why the merge buys nothing

The split is between *time bases*, not state
classes — the continuous primitive is already hybrid (`m`, [guards](#g-guard),
handlers, [§3.1][s3-1]); what separates the classes is [sweep](#g-sweep)-driven
versus [tick](#g-tick)-driven execution. And the settled rules force a merged
[component](#g-component)'s two halves to communicate exactly as two siblings
do: [one home per datum](#g-one-home-per-datum) ([§5.2][s5-2]), `state_derivative` sees only
the continuous state and `state_update` only the discrete one, and `s⁺` is decoded only at
the owner's next tick (`state_update` runs last). That deferred decode is what makes
ticks→events structurally impossible and what terminates the
[boundary](#g-boundary) iteration ([§10.6][s10-6]). Cross-[tier](#g-tier)
influence inside the merged class still routes through published table
[cells](#g-cell). The all-in-one component is therefore an
[assembly](#g-assembly) of two primitives in a trench coat, buying no
expressiveness and incurring costs of its own that [D-056][d-056] enumerates. One of
those costs is not bookkeeping. The sampling [seam](#g-seam) — ZOH and the
`z⁻¹` delay — is the most bug-prone boundary in a flight-control stack. A
monolith swallows it; the split keeps it a visible wire.

#### The counterexample

The source is a pre-design FlightCore sketch, `navsensors.jl`, whose operative
content and companion derivation note are recorded here in full. In that sketch
a strapdown IMU integrates raw increments continuously — `ẋ.ϑ_c = ω_ic_c`,
`ẋ.υ_c = f_c_c`, the coning attitude increment `q_c_cc` and the sculling integral
`ẋ.υ_c_sc = q_c_cc(f_c_c)` — and `f_disc!`, at the IMU's own `Δt`, reads the
integrals, publishes the sample, and **zeroes them**. In interval terms, the
sketch's piecewise quantities are integrals over $[t_{k-1}, t_k]$ with their
weights re-anchored at each reset: `ϑ_c` $= \int_{t_{k-1}}^{t_k} \omega^{c}_{ic} \, dt$
and `υ_c` $= \int_{t_{k-1}}^{t_k} f^{c} \, dt$ from zero,
`q_c_cc` $= q_{c_{k-1} \to c(t)}$ from identity, and
`υ_c_sc` $= \int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt$ with the rotation
anchored at the interval
start — exactly the forms the differencing bullets below recover from the
cumulative stores, term by term. The reset is periodic, not
condition-triggered, so events are the wrong [tier](#g-tier); and the reset is a
discrete-tier write into continuous state, exactly the operation this design
forbids (`state_update` writes only its own `s`; handlers are the sole resetters of
continuous state, and they are [guard](#g-guard)-driven).
Integrate-and-dump falls squarely into the crack between the classes:
tightly-coupled continuous and periodic dynamics in one physical instrument.

#### The idiom: integrate-and-difference

The reset is eliminable by algebra, not
approximation. Every interval-relative integral becomes a *cumulative* one; the
sampler differences against the previous sample, held in its `s` — the textbook
sampled-data latch, and the only new store (the memory the reset used to erase):

- *Raw increments* (linear): $\Theta(t) = \int_{t_0}^{t} \omega^{c}_{ic} \, dt$,
  $\Upsilon(t) = \int_{t_0}^{t} f^{c} \, dt$, never reset;
  $\vartheta_c = \Theta(t_k) - \Theta(t_{k-1})$,
  $\upsilon_c = \Upsilon(t_k) - \Upsilon(t_{k-1})$.
- *Coning*: cumulative $q(t) = q_{c_0 \to c(t)}$ with
  $\dot{q} = \tfrac{1}{2} \, q \otimes \omega^{c}_{ic}$ from
  identity at $t_0$; the interval rotation is $\Delta q = q(t_{k-1})' \circ q(t_k)$, exact by
  right-invariance ($\Delta q$ satisfies the same ODE with the same body rate).
- *Sculling*:
  $\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt = q(t_{k-1})' \, ( V(t_k) - V(t_{k-1}) )$
  with $\dot{V} = q(t)(f^{c})$. The derivation, in two steps: re-anchor the rotation through the fixed $c_0$ frame,
  $R^{c_{k-1}}_{c} = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} R^{c_0}_{c}$, so the $c_{k-1}$-dependent
  factor — constant over the interval — exits the integral; what remains is the
  cumulative integrand, and splitting its range at $t_{k-1}$ gives the
  difference of the running store:

  $$\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt
  = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} \left( \int_{t_0}^{t_k} R^{c_0}_{c} f^{c} \, dt -
  \int_{t_0}^{t_{k-1}} R^{c_0}_{c} f^{c} \, dt \right)
  = q(t_{k-1})' \, \big( V(t_k) - V(t_{k-1}) \big)$$

  — in code, the sampler line
  `υ_c_sc = s.q'(u.V - s.V)`. The factor leaving the integral is the **anchor
  change between two inertially-fixed frames** — constant because $t_{k-1}$ is
  in the past and latched. The physical intra-interval rotation, the thing
  sculling corrections are *about*, stays inside the integrand via $q(t)$: every
  [RHS](#g-flow) evaluation, RK stages included, applies the current cumulative attitude,
  exactly as the sketch applies the current `q_c_cc`.

#### Exactness condition, stated once

Interval-relative integrals factor into
cumulative ones whenever the interval-dependence enters through a *left action by
the interval-start value of a cumulatively-integrable quantity* — the identity
action for linear integrals, right-invariance for attitude increments, constancy
of the anchor change for sculling. Two provisos: the cumulative attitude must be
integrated with the **inertial** rate, so the anchor frame is inertially fixed and
the pulled factor rigorously constant (anchoring to a rotating reference breaks
the factorization); and the equivalence survives discretization — quaternion
kinematics is linear in `q`, every RK stage composes on the right, and left
multiplication by the constant anchor commutes through, so the formulations agree
to machine precision, not merely in the continuous-time limit. Numerics of never
resetting: `q` stays unit under `state_projection` (better conditioned than the sketch's
`normalization = false` + reset); `Θ`/`Υ`/`V` grow linearly, so differencing
loses relative precision — after an hour of flight, order $10^{-11}\ \mathrm{m/s}$ per sample
against $10^{4}\ \mathrm{m/s}$ totals, six-plus orders below any error model worth simulating.

```julia
struct IMUIntegrals <: AbstractComponent
    t_bc::FrameTransform
end
init_x(::IMUIntegrals) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                          Υ = zeros(SVector{3}), V = zeros(SVector{3}))
input_types(::IMUIntegrals, ::Type{T}) where {T <: Real} =
    (q_eb = RQuat{T}, r_eb_e = SVector{3,T},
     ω_eb_b = SVector{3,T}, a_ib_b = SVector{3,T}, α_ib_b = SVector{3,T})
output_types(::IMUIntegrals, ::Type{T}) where {T <: Real} =
    (Θ = SVector{3,T}, q = SVector{4,T},                        # auto-published state
     Υ = SVector{3,T}, V = SVector{3,T},
     ω_ic_c = SVector{3,T}, f_c_c = SVector{3,T})               # instantaneous truth

# output_direct: the sketch's f_ode! math verbatim (lever arm, gravity, Earth rate) → (; ω_ic_c, f_c_c)
function state_derivative(imu::IMUIntegrals, (; x, y))
    q = RQuat(x.q, normalization = false)              # [§7.1][s7-1]'s explicit cast
    (Θ = y.ω_ic_c, q = SVector{4}(Attitude.dt(q, y.ω_ic_c)), Υ = y.f_c_c, V = q(y.f_c_c))
end
state_projection(imu::IMUIntegrals, x) = (; x..., q = normalize(x.q))   # SVector normalize

struct IMUSampler <: AbstractComponent end
init_s(::IMUSampler) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                        Υ = zeros(SVector{3}), V = zeros(SVector{3}))
input_types(::IMUSampler)  = (Θ = SVector{3,Float64}, q = SVector{4,Float64},  # discrete class: plain
                         Υ = SVector{3,Float64}, V = SVector{3,Float64})       # form, bound check only
output_types(::IMUSampler) = (sample = IMUSample,)   # discrete class: cells pin (frozen-exact)

function output_direct(smp::IMUSampler, (; s, u, Δt))
    q_s = RQuat(s.q, normalization = false);  q_u = RQuat(u.q, normalization = false)
    ϑ_c = u.Θ - s.Θ;  υ_c = u.Υ - s.Υ
    Δq  = q_s' ∘ q_u                                   # interval rotation, exact
    υ_c_sc = q_s'(u.V - s.V)                           # constant anchor change pulled out
    (; sample = IMUSample(; ω̄_ic_c = ϑ_c / Δt, f̄_c_c = υ_c / Δt,
                            ϑ_c, ϑ_c_cc = RVec(Δq)[:], υ_c, υ_c_sc))
end
state_update(smp::IMUSampler, (; u)) = (Θ = u.Θ, q = u.q, Υ = u.Υ, V = u.V)   # the latch
```

The `IMU` [assembly](#g-assembly) wires the four integral [ports](#g-port) across, holds the error model as
a discrete sibling consuming `sample`, and leaves the sampler at `K = 1` in its
own scope — the parent sets the IMU's rate ([§8.7][s8-7]). `Δt` in the stage [bundle](#g-bundle)
(the NamedTuple of zero-copy views a component function receives) is the [§10.5][s10-5]
single source of truth, put there for exactly this kind of discretized law.
(Initialization consistency — the sampler's `s` must equal the initial
integrals or the `t₀` sample is wrong — holds by default at zeros/identity, and
[boundary zero](#g-boundary-zero) discharges the rest: its [due](#g-due) `state_update` latches `s ← integrals(t₀)` for
every subsequent sample, so only the `t₀` sample itself depends on the authored
`s` — a [condition](#g-condition)-authoring obligation under trim, [§14.5][s14-5].)

#### Why `u.V` is fresh — the line that would silently zero

The sculling line is
correct only because a due [tick](#g-tick) samples the *completed* [boundary](#g-boundary): if `u.V` still
held the previous boundary's decode it would equal `s.V` exactly (that is the
value `state_update` latched), and sculling would vanish without an error anywhere. The
guarantee is the [§10.6][s10-6] macro-sequence, not a scheduling accident: integrate →
project → [sweep](#g-sweep), with the due sampler's stages gated *into* that sweep ([§10.5][s10-5]) and
the integrals arriving at stage-1 position (auto-published state, [§5.3][s5-3]) — before
any stage-2 function runs, regardless of topological placement. The rest of the
timeline closes consistently: the sampler's `output_direct` decodes `s` (the `t_{k-1}` latch)
*before* `state_update` runs — the `z⁻¹` semantics — and after event [quiescence](#g-quiescence)
`state_update` latches
the `t_k` values for the next tick; same-boundary events re-run the gated stages
in their re-sweeps, so `state_update` and external readers see the settled boundary.

#### Author-knowledge note

User observation, recorded as a documentation
obligation: the clean implementation leans on the author *knowing* that "sampling
at `t_k`" means post-integration, post-[projection](#g-projection), stage-1-fresh state. That
knowledge must be part of the framework's taught contract — [§10.5][s10-5]/[§10.6][s10-6] semantics
stated in [component](#g-component)-author documentation with this IMU as the [worked](#g-worked) example — not
internal lore. The failure mode of not knowing it is instructive: an author who
distrusts the [sweep](#g-sweep) order adds a defensive one-[tick](#g-tick) delay or re-derives the
integrals in the sampler, silently degrading the model.

**When the coupling is genuinely two-way: the latch-back wire.** The IMU's
coupling is one-directional (integrals → sampler). If the [flow](#g-flow) itself needed the
interval-relative value — integrator saturation within the sampling interval,
say — the latch becomes a wire back: the sampler publishes the sample-instant
values from its *[feedthrough](#g-feedthrough)* stage (`output_direct` reads `u`, so the latch [port](#g-port) carries
the current tick's values, ZOH until the next; an `output_state`-published latch would be
one period stale), and the continuous `state_derivative` computes `x − u.latch`. Both cross-wires
consume the other side's ports and the [schedule](#g-schedule) stays acyclic (integrals stage 1 →
sampler `output_direct`; sampler `output_direct` → the integrals'
`state_derivative`-edge, [§5.4][s5-4]). The "reset"
becomes a visible [tier](#g-tier)-crossing feedback loop — which is what it always was,
physically.

**Verdict.** The strongest counterexample landed on the two-class taxonomy with
*less* code than the fused original — same thirteen integral scalars, same math,
minus the reset block — and three structural gains. The sampling [seam](#g-seam) became a
wire. The sketch's incidental violations became visible structure: the
`CircularBuffer` mutated inside the component struct (constants) moves to the
consumer's `s` or falls out of the log; the parent-called `f_disc!(errors)`
becomes a discrete sibling, making the truth/corrupted sample pair separately
loggable. And linearization got sane: under a `Dual` [activation](#g-activation) the discrete tier
is held ([§8.2][s8-2]), and "integrators that never reset" *is* the cumulative
formulation — the framework's rules pushed the model into the only form its own
linearization semantics could coherently handle. Residual escape hatch, recorded
unbuilt: if interval-relative dynamics ever neither factor algebraically nor
tolerate the latch-back wire, the [guarded addition](#g-guarded-addition) is a **tick-triggered handler**
on [continuous components](#g-continuous-component) (periodic events). Nothing surveyed needs it ([D-056][d-056]).

---

## 16. Open axes

Three axes are still to be settled: the migration of FlightPhysics and
FlightApps, the GUI panel authoring API, and log and [trace](#g-trace)
persistence.

#### Migration

What follows is an outline for FlightPhysics/FlightApps, not a specification.
The table carries one row per item: the item, the disposition recorded for it,
the section owning the machinery it touches, and the governing decision entry. A
dash means the outline names the item and records nothing further. Items whose
disposition exceeds a cell are expanded below the table.

| item | disposition | section | decision |
|---|---|---|---|
| The [walked](#g-walked)-leaf parametrization pass | the `Ranged` rewrite targets the walk rule wherever `Ranged` survives, at ports and parameters | [§8.2][s8-2] | — |
| The `KinData`-style output splits | — | — | — |
| The contributor survey feeding the aggregation chains | mechanical to extract from today's trait implementations | [§6.2][s6-2] | — |
| Comparison criteria against FlightCore's demonstrated strengths | three strengths to compare against: zero-alloc stepping, flexibility, interactive operation | [§9.7][s9-7] | — |
| The [component](#g-component) library's starting inventory | — | [§13.7][s13-7] | — |
| The conventional exported aircraft surface for generic periphery consumers | pose and velocity faces with wrapper types, the periphery-facing half of the `KinData` successor | [§11.2][s11-2] | — |
| The supervisor seam | three respellings — gain ports and schedulers, mode-transition latches, the gear's reset — the last of which lands on the *library* side | [§15.2][s15-2] | [D-089][d-089], [D-139][d-139] and [D-141][d-141] |
| The steering contract re-factoring | `AbstractSteering` moves from "give me the angle" to `(engaged, ψ_cmd)` | [§5.4][s5-4] | — |
| Splitting `Strut` | the residual remedy, recorded and not taken | — | — |
| The state-declaration conversion to the closed vocabulary | each `RQuat` state field becomes its `SVector{4}` backing, each `Ranged` state field a plain scalar | [§7.1][s7-1] | — |
| The exported-name surface | decided deliberately rather than by accident, by a full-surface audit under the four-register naming convention | [§14.2][s14-2] | [D-144][d-144] |
| The [executor](#g-executor) compile-cost re-measurement | runs on the real vehicle skeleton, early — before the executor's shape hardens | [§9.7][s9-7] | — |
| *Residual*: the `q_sf` home | aircraft design, so it belongs on this list | [§15.4][s15-4] | — |
| *Residual*: a root-declared overridable `stop_on` default | reopen only if the constructor argument proves chronically forgotten | [§13.5][s13-5] | — |
| *Residual*: the engage-boundary write-order check | verify the FCS latch and the GUI input sync-write commute on one boundary — believed order-free, both deriving from the same measurements | [§15.4][s15-4] | — |
| *Residual*: the C172 AD audit for trim | Interpolations tables (prefer cubic knots), saturation rank-deficiency (LM-tolerated, reported), the gear identically zero airborne | [§14.8][s14-8] | [D-070][d-070] |

**The parametrization pass.** `Ranged` survives at [ports](#g-port) and
parameters, and there the rewrite targets the walk rule ([§8.2][s8-2]):
constructor discipline admitting the walked scalar with the value parameters
left alone, plus a `probe_value` method. State fields are not among those
survival sites; the state-declaration conversion below turns each `Ranged`
state field into a plain scalar.

**Comparison criteria.** FlightCore's demonstrated strengths are three:
zero-alloc stepping, flexibility, interactive operation. Zero-alloc stepping is
measured through the `phase_bodies` [seam](#g-seam) ([§9.7][s9-7]),
apples-to-apples with today's `@ballocated f_ode!` suites.

**The conventional exported aircraft surface.** Generic
[periphery](#g-periphery) consumers read the integration
[register](#g-register) ([§11.2][s11-2]). What that surface exports is pose and
velocity [faces](#g-face) with wrapper types — `VelocityData`, field meaning
defined at the type — the periphery-facing half of the `KinData` successor.

**The supervisor seam.** The supervisor sitting above the compensators
([§15.2][s15-2]) contributes three respellings. Compensator gains become input
ports fed by scheduler components (~7 for the C172X). Every mode-transition
latch is respelled as a same-[tick](#g-tick) reset. The gear's level-triggered
reset becomes an edge event — and that last one lands on the *library* side.

On the library side, the reimplemented `PIVector` gains a **flag-gated reset
face**. `PIVector(; reset = true)` adds a `Bool` input face plus the event; the
default omits both. Declarations are ordinary functions of the instance
([§8.5][s8-5]), which is what makes this the honest version of Simulink's
checkbox. One fixed policy governs the face: a rising edge resets to the
declared `init_x` values. The implementation is internal — an ordinary
[guard](#g-guard)/handler event, the continuous-reset contract in
its [worked](#g-worked) instance ([Appendix A][sA]).

Falling-edge consumers wire a NOT gate (the Bool gates, [§13.7][s13-7]).
Level-pinning and reset-to-an-external-value, which is tracking, are different
blocks rather than options on this one ([D-141][d-141]).

The gear then wires `strut.wow → frc.reset`. That is the **touchdown** edge —
the not-[holding](#g-edge-semantics) → holding semantics ([§2.1][s2-1]) — and it
gives fresh regulator state per contact episode. The liftoff edge (`!wow`) was
rejected ([D-141][d-141]). [Boundary-detected](#g-boundary-detected) policy (checked
for edges at step boundaries only, no root-finding) suffices, because the
regulator's input ramps from zero at touchdown, so localization buys nothing. A
sim initialized on ground fires the reset at [boundary zero](#g-boundary-zero)
(the initialization boundary: the ordinary macro-sequence with an empty
integrate). It fires harmlessly there: declared inits are zero, and
[boundary](#g-boundary)-zero [priors](#g-prior) are not-holding
([§14.5][s14-5]).

The engine's two `PIVector` instances — `PistonEngine`'s `idle` and `frc` —
migrate **unchanged, flag off**. They are verified reset-free in today's code,
where windup across unused phases is already handled by the saturation bounds
and `int_halted`. Their `f_init!` gain writes become construction-time
parameters, as `Contact`'s do ([D-089][d-089]). The PI *law* is shared as plain pure
functions called by the block's stages, the laws-as-plain-functions pattern
([D-139][d-139]). `sat_ext` poses the same always-on-vs-flag-gated face question, to
be decided at reimplementation time on the same axis.

**The steering contract re-factoring.** This is the middle rung
([§5.4][s5-4]), worked on the shipped instance. `AbstractSteering` moves from
"give me the angle" to `(engaged, ψ_cmd)`, with the castoring fallback
`ψ_sw = engaged ? ψ_cmd : ψ_v` computed inside `Strut`. That move deletes the
strut → steering → strut artificial loop that stage-2 conservatism would
otherwise manufacture. The `VehicleDynamics` instance standing beside it
([§15.1][s15-1]) needs no such move: it dissolves under the two-stage split
alone.

**Splitting `Strut`.** The residual remedy is to split `Strut`, its shared
geometry crossing the new boundary as one `StrutGeometry` bundle
port. It is recorded and not taken. The call is an aircraft-library one — a
component's own contract — recorded here rather than in framework vocabulary.

**The state-declaration conversion.** State declarations move to the closed
vocabulary ([§7.1][s7-1]). Each `RQuat` state field becomes its `SVector{4}`
backing, with the explicit `normalization = false` cast at its use sites; the
4-wide rate is already what today's `Attitude.dt` delivers. Each `Ranged` state
field becomes a plain scalar, its clamp respelled as dynamics or
[projection](#g-projection), never as construction.

**The exported-name surface.** This surface is to be decided deliberately
rather than by accident. Until the audit below runs, the module exports
nothing, and a public name is reached by qualified name or per-name `import`
([D-226][d-226]). `condition`, `fragment`, `at`, `capture` and
`combine` ([§14.2][s14-2]) are generic names sharing a namespace with
FlightPhysics domain code. The `Base.merge` piracy surface the combinator once
presented is retired with its rename ([D-204][d-204]); the mixed-argument methods stay
error methods. For the readers, the `get_` prefix of the [selector](#g-selector) family
already settles the question ([§14.4][s14-4]). Whether the [condition](#g-condition) algebra ships
behind a submodule is the packaging question.

The audit is a full-surface sweep (per user, 2026-08-01). Every API
method name is either specific enough to export, or gets renamed, or is left
unexported — and for extension-only surface, *unexported* is the preferred
disposition. Extension-only surface has three parts:

- the declaration and stage family of the import list ([§8.1][s8-1]), the
  larger half of the question: it sits on every component file's first line and
  is settled there;
- the [binding](#g-binding) interface `claims`/`reads` ([§11.6][s11-6]) and the
  side traits `is_input`/`is_output`/`is_greedy`, with `map_input`/`map_output`
  outside the question as loop-idiom conventions the framework never calls;
- the [device](#g-device) contract
  `init!`/`loop`/`shutdown!`/`unblock!`/`needs_calling_task`, which authors
  extend by `import` or qualified name, `Base.show`-style, rather than call
  every day.

The audit's criterion is the **four-register naming convention** ([D-144][d-144]):

1. **Declarations**, which the author defines and the framework calls, are noun
   phrases or `init_*`/`_types`: `child_connections`,
   `input_connections`/`output_connections`, `state_events`, `input_types`,
   `init_workspace`, the stage and update-law names ([D-220][d-220]), and
   `claims(b)` from the binding interface ([§11.6][s11-6]).
2. **Value selectors**, called against `reads` and [snapshots](#g-snapshot),
   carry `get_` ([§14.4][s14-4]).
3. **Lifecycle and mutating actions** are verbs, with `!` when they mutate.
4. **Build primitives** ([§13.3][s13-3]) are plain verbs.

A name in the wrong register is a rename candidate on that ground alone.

The convention also has a **semantic axis**: right register, wrong noun.
`input_passthrough` ([§8.8][s8-8], [D-171][d-171]) and the binding methods
`claims`/`reads` ([§11.6][s11-6], [D-146][d-146]) are what settle it — bare-noun
declarations name the *consequence* a declaration has rather than its
*content*. `exports` is that axis's retired exemplar ([D-170][d-170]). The
`*_connections` family names content deliberately, for authoring transparency;
that is a recorded choice, not register drift.

Four items are flagged for the sweep and deliberately not settled here:

- `input_faces`/`output_faces` — noun accessors punning on the `_types`
  declarations, mitigated by being framework-facing.
- `loop` — the device contract ([§11.6][s11-6]): a mutating task body spelled as
  a bare noun among its verb-`!` siblings `init!`/`shutdown!`/`unblock!`. With
  `run!` taken and the "loop body" prose entrenched, it needs the audit's
  whole-surface view.
- The bare-noun accessor family `trace(sim)`, `latest(sim)`, `binding(handle)`,
  `phase_bodies(sim)` — value selectors outside register (2)'s `get_` rule.
  `trace` is the sharpest of them: the constructor kill-switch `trace = false`
  and the post-run accessor `trace(sim)` are one name in two senses, the
  overload pattern [D-122][d-122] and [D-144][d-144] retire.
- Whether register (1) needs an explicit exemption for predicate traits
  (`is_greedy`, `needs_calling_task`).

All five are boundary cases the convention in [D-144][d-144] does not settle, and they
are not defects of its list.

#### GUI panel authoring API

The semantics are settled ([§11.7][s11-7]): derived liveness, first-class
read-only rendering, own-pending-else-snapshot [peek](#g-peek),
[stage-on-interaction](#g-stage-on-interaction), orphan display. What is
deferred to migration is the calling convention — context contents, port
naming, child composition. That convention is to be co-designed against the GUI
library under the four constraints ([§11.7][s11-7]).

#### Log and trace persistence

The in-memory artifacts are settled; nothing on-disk is. Three facts stand on
the in-memory side:

- the log is the retained boundary snapshots ([§11.2][s11-2]);
- the input trace is always on and device-tagged, carrying its header of
  initial [stores](#g-store) and [root input](#g-root-input) values ([§11.5][s11-5],
  [§14.5][s14-5], [§14.6][s14-6]);
- the primary/derived rule holds: the log is recomputable from the trace, never
  the reverse.

The on-disk questions are deferred to migration, where the consumers exist to
ground the choices:

- the HDF5 export scope — the whole snapshot log, or selected subtrees;
- field-handle summarization over retained snapshots, the successor to the
  `getproperty` navigation of `TimeSeries`, which is today's post-processing
  entry point;
- the trace file format, which doubles as the reproducibility carrier: the
  [replay](#g-replay) pointers ([§13.4][s13-4]) name positions in it.

---

# Appendices

The appendices are reference matter, not a sixth part. [Appendix A][sA] indexes the
semantic contracts an author must know and no check can enforce; [Appendix B][sB] is
the API synopsis. Neither is a second home: each entry is normative only where
its owning section settles it. [Appendix C][sC] is the exception — its diagnostic
kind set is made normative here, and acceptance tests match on it. [Appendix D][sD]
is the glossary, non-normative, with the owning section winning wherever the
two diverge.

## Appendix A. Taught contracts: the author-facing index

The build pipeline enforces structure — declarations, wiring, types,
conformance. A residue of *semantic* facts is unenforceable by any check.
Knowing them is what makes component and periphery code come out right.
Not knowing them produces defensive delays, duplicated math or mistimed
samples with no diagnostic firing anywhere; the author-knowledge note
([§15.5][s15-5]) is the archetype.
This appendix is an **index, not a second home**: one recall line per
contract, with the normative statement staying in the owning section. That is
one home per datum, applied to the document itself.

For component authors:

- **The stage funnel** ([§5.2][s5-2]). Stage name at its tier ⊇ bundle ⊇
  destructured reads: the stage name fixes the maximal legal view set at the
  component's tier, the component's
  declarations narrow it to the bundle, and the signature's destructuring
  narrows the bundle to actual reads — so "no `direct` in the name" *is* the
  no-feedthrough property. The teaching line: stage 1 publishes what you
  know from state alone; stage 2 adds what needs inputs; your dynamics
  read your own published results instead of recomputing them.
- **One home per datum** ([§5.2][s5-2], [§4.3][s4-3]). The signal table holds *produced*
  signals only, never transported ones: buffer for `x`, stores for
  `s` and for `m`, table for signals — no store mirrors another.
- **The value-level constructor** ([§4.4][s4-4]). A field-emitting component ships
  the map (component, input values) → handle as a plain public function,
  and its output stage merely calls it: the condition math ([§14.1][s14-1]) must
  be able to produce the sweep's exact handle outside any sweep, and only the
  component's author can write that function without re-creating the
  drift class.
- **Boundary sampling** ([§10.5][s10-5]/[§10.6][s10-6]; worked example [§15.5][s15-5]). "Sampling at
  `t_k`" means post-integration, post-projection, stage-1-fresh state: a
  due tick's gated stages run inside the boundary sweep and sample the
  *completed* boundary. Distrusting that guarantee — a defensive one-tick
  delay, a re-derivation inside the sampler — silently degrades the model.
- **Interval alignment** ([§14.5][s14-5]). A boundary's `state_update` is the
  *outgoing* transition: at tick `t_k` it consumes the completed boundary's samples
  and produces `s_{k+1}` — the value the component's *next* tick decodes
  (the sampled-data `z⁻¹` delay, by construction). Hence `state_update` runs at
  boundary zero: that run is the `t₀` sample's only chance.
- **Same-tick reset consumption** ([§15.2][s15-2]) — *discrete tier*. A commanded reset
  of a discrete component's `s` is an input. For same-tick output semantics
  the *output stage* consumes that input — overriding the state-derived path —
  and `state_update` stores the matching `s⁺`. A reset honored only in
  `state_update` reaches the
  outputs one tick late: the plant integrates a full step under the stale
  command. Both spellings are legal; they mean different things. The
  continuous tier has no such choice — next entry.
- **A continuous component's state reset is an event** ([§3.1][s3-1], [§10.6][s10-6], [§15.2][s15-2]).
  Only handlers write `x`, so even a *commanded* reset — the condition
  arriving as an ordinary `Bool` input, weight-on-wheels being the shipped
  instance — is spelled as an event whose guard reads that input; the
  discrete tier's input spelling does not transfer. The reason is semantic,
  not stylistic: only the discrete tier's update stage is already a jump map,
  so a reset there is just another value for `s⁺`, whereas a continuous state
  jump must be solver-visible, applied *between* integration segments — the
  flow/jump split every hybrid tool converges on (Simulink applies its reset
  ports through zero-crossing events plus a solver restart; Modelica's
  `reinit` is syntactically legal only inside a `when`). And there is no
  stale-output hazard to manage: [§10.6][s10-6] re-sweeps outputs to quiescence after
  handlers, so a continuous edge-reset is same-boundary by construction.
- **Guard predicates, edges and priors** ([§2.1][s2-1], [§10.6][s10-6]). A guard defines
  a predicate — a `Bool` form, or a sign value `σ` with
  positive = holding — and the form chosen *is* the detection policy: `Bool`
  boundary-detected, sign localized. Events fire on not-holding → holding *edges* against per-event
  priors (the previous boundary's quiescent sample): a predicate that
  keeps holding fires once, at the boundary where it first held. Boundary
  zero sets every prior to not-holding, so a predicate already holding in
  the authored state fires at `t₀`. The opposite crossing direction is a
  second event with the negated guard.
- **Handler-phase visibility** ([§5.3][s5-3], [§10.6][s10-6]). A handler executes
  against exactly the world its guard fired on: own `y`, foreign `u` and own
  `x`/`m` are all the firing round's sweep, and a component fires at most one
  event per round — later own events are re-decided against the next round's
  sweep, one round per causal link, within and across components alike. The
  signal table is written only by sweeps.
- **Stage totality** ([§9.3][s9-3]; [§13.4][s13-4], [§13.5][s13-5]). Stage code is total over
  type-valid inputs: the probe evaluates every user function against values
  chosen for their types alone, and a value-level throw is a build failure
  there and a `StepError` at runtime. Physical plausibility is a published
  `Bool` and `stop_on`; self-consistency asserts belong in tests; parameter
  validation belongs at instance construction, not inside a stage.
- **Stop-face sampling** ([§13.5][s13-5]). Stop faces are read in completed-boundary
  snapshots; declare a sign-form (localized) event if the stop needs localizing.

For periphery authors and consumers:

- **Levels, never deltas** ([§11.4][s11-4]). Staged input values are levels
  (`press_count = 17`, never `presses += 1`) — idempotent under
  coalescing; button edges ride as monotonic counters. Cross-datum state
  (press counters, edge detection) lives in the device struct, maintained
  by the loop, arriving *inside* the datum — `map_input` is pure ([§11.6][s11-6]).
- **The device loop idioms** ([§11.6][s11-6], [§12.4][s12-4]). Loop on `running(handle)`;
  make every blocking call interruptible (an `unblock!` override, or
  timeouts); voluntary exit is returning. Three canonical shapes:
  timer-poll (sleep, poll, stage), source-driven (block on your socket;
  `unblock!` closes it), boundary-driven (`wait_next_snapshot`, gather,
  send). A forgotten predicate check surfaces as `DeviceJoinTimeout` with
  your device's name; a stall as a stale heartbeat.
- **`shutdown!` closes only what is open** ([§11.6][s11-6], [§12.4][s12-4]). The framework
  runs `shutdown!` on every exit path, your own `init!`'s failure included:
  a throw half-way through acquisition hands the half-built device straight
  back to you, so guard each release (`isopen`, a `nothing` handle) rather than
  assuming initialization completed. The converse is a burden you do *not*
  carry: `init!` owes no cleanup of its own.
- **Binding traits are declarations, mappings are your own idiom** ([§11.6][s11-6]).
  Keep `is_input`/`is_output`/`is_greedy` trivial — a literal, or a flag read
  off a field fixed at the constructor call — because the framework calls them
  once, at attach, and cross-checks each against the enumeration method it
  implies. `map_input`/`map_output` are the other kind of thing: conventions of
  the loop idiom, called only by your own `loop`, never by the framework — the
  names are worth keeping for readers, and nothing enforces them.
- **Bad datum vs. bug** ([§11.6][s11-6], [§13.4][s13-4]). Catch what your parser can throw,
  `report!(handle, MalformedDatum(cause))`, stage nothing, continue; let
  everything else propagate — the wrapper makes it `DeviceCrash`.
  Tolerating everything hides bugs as "device attached, nothing happens";
  tolerating nothing kills a live link on its first truncated datagram.
- **Derived liveness** ([§11.7][s11-7]). A widget is live iff its port's feed chain
  terminates in a root input inside the GUI's own claim in the run's frozen
  partition; there is no per-port marking, and unexported ports are
  unpokeable.
- **The two observation registers** ([§11.2][s11-2], [§13.5][s13-5]). A deep snapshot path is
  the *inspection* register: it sees everything and promises nothing
  across builds. An exported output face is the *integration* register:
  curated, writer-independent meaning — the only shield against silent
  semantic drift. Bind faces in anything meant to outlive the current
  build. The store selectors (`get_state`/`get_deriv`) belong to neither:
  they read live stores, never snapshots (the source rule, [§14.4][s14-4]).

---

## Appendix B. API synopsis: the entry points

The user-facing surface on one page — same rule as [Appendix A][sA]: an index, not a
second home, with each signature normative only where its owning section settles
it. Every name here is public by being here, reached by qualified name or by
per-name `import`; the module exports nothing until [§16][s16]'s audit fixes the
exported-name list ([D-226][d-226]). The author-side declaration surface first, then
the operator surface by lifecycle:

**Authoring** — what a component or assembly defines ([§8.2][s8-2], [§8.5][s8-5]–[§8.7][s8-7]):

- Continuous leaf: `init_x`/`init_m` (by value), `init_workspace(::C, ::Type{T})`
  (by allocation), `input_types(::C, ::Type{T})` and
  `output_types(::C, ::Type{T})` (by type),
  `state_events` — stages `output_state`, `output_direct`, `state_derivative`,
  guard/handler pairs
  (`StateEvent(guard, handler)`; detection policy comes from the guard's return
  type, [§10.4][s10-4]), `state_projection`.
- Discrete leaf: `init_s`, `init_workspace(::C)`,
  `input_types`/`output_types` — stages `output_state`, `output_direct`,
  `state_update`.
- Assembly: `child_connections` (mandatory — the class marker),
  `input_connections`, `output_connections`, `sample_times`,
  `transparent_container` (optional, default `nothing`).
- Shipped conditions: `condition(::C; kw)` fragment functions ([§14.2][s14-2]).

Bundle contents by function family (the maximal legal sets, [§5.2][s5-2] — signatures
destructure less at will):

| function | tier | bundle fields |
|---|---|---|
| `output_state` | continuous | `x, m, t [, ws]` |
| `output_direct` | continuous | `x, m, u, y_x, t [, ws]` |
| `state_derivative` | continuous | `x, m, y, u, t [, ws]` |
| `output_state` | discrete | `s, t, Δt [, ws]` |
| `output_direct` | discrete | `s, u, y_s, t, Δt [, ws]` |
| `state_update` | discrete | `s, y, u, t, Δt [, ws]` |
| guard / handler | continuous | `x, m, y, u, t [, ws]` |
| `state_projection` | continuous | positional `(comp, x)` — no bundle |

Table footnotes, from the bundle law ([§5.2][s5-2]) — the sets above are maximal, and
each field is present only if it exists for the component: `u` iff the function
family may see inputs **and** the component declares `input_types`; `y` iff the
component produces any table cell (`output_types` ∪
auto-published); `x`/`s`/`m`/`ws` iff declared; `y_x`/`y_s` iff the stage-1
*return* is non-empty (auto-published names excluded — [§5.2][s5-2], [D-169][d-169]);
`Δt` on the discrete tier only. Returns: a stage returns a NamedTuple of
port values ([§4.3][s4-3], [§5.2][s5-2]); `state_derivative` returns the layout image of `X` ([§7.1][s7-1]); a **handler
returns `(; x, m)` with each key present iff that store exists and the handler
updates it** (the return law, [§5.2][s5-2] — no padding, `x` complete, `m` partial).

**Build.**

- `build(world) → Build` — standalone; the inspectable derived-contract artifact:
  wire list, face table with provenance, schedule, root inputs ([§9.2][s9-2]).
  `build(world; activations = (Float64, ProbeDual))` additionally pins
  activation invariants for CI (`ProbeDual` the public canonical concrete
  probe scalar, [§9.4][s9-4]), and pre-materializes activations so a parallel
  sweep shares a fully immutable `Build` ([§11.1][s11-1], [§9.4][s9-4]).
- `resolve(asm, path) → AbstractComponent` — the getfield walk along `/`
  segments, enforcing the one-level rule for wiring ([§6.1][s6-1]) and the
  generic-holding rule for deep reads, at the primitive ([§13.3][s13-3]).
- `input_faces(c)` / `output_faces(c) → Vector{String}` — declaration-ordered
  face names ([§13.3][s13-3]).
- `input_passthrough(asm, path; prefix, sep, except, only)` /
  `output_passthrough(asm, path; prefix, sep, except, only)` — the
  declaration-site helpers for computed interface connections; `path` names an
  immediate child ([§8.8][s8-8]).

**Deployment.**

- `Simulation(world; algorithm = RK4, h, N_base = 1, Δt_base = nothing,
  t_end = Inf,
  stop_on = (), localization_tol = 1e-6, localization_budget = 8,
  firing_budget = 4, join_timeout = 5.0,
  trace = true, log = true, log_every = 1, log_max = 65536)` —
  wraps the build (`Simulation(world; …) = Simulation(build(world); …)`;
  the `Build` overload takes the same deployment keywords and deploys an
  inspected artifact directly, [§9.2][s9-2]).

  | keyword | default | meaning | owning section |
  |---|---|---|---|
  | `algorithm` | `RK4` | the stepper, selected by type and materialized against the state buffer at binding ([D-227][d-227]) | [§10.2][s10-2] |
  | `h` | — | required: a domain rate is not a framework default | [§10.2][s10-2] |
  | `N_base` | `1` | steps per base tick: absent the `Δt_base` keyword, the `N_base·h` product is the base tick period (the default path); given it, `N_base` is instead derived and validated an integer ≥ 1 | [§9.1][s9-1] |
  | `Δt_base` | `nothing` | the base tick period as a `Rational`, `Period` or `Hz` value, or `:derive` to request GCD derivation (all-anchored models only); one of three binding sources | [§9.1][s9-1] |
  | `t_end` | `Inf` | the run's end time — a **default**, overridable per run at `run!` | [§13.5][s13-5], [§12.6][s12-6] |
  | `stop_on` | `()` | root-exported `Bool` output faces, OR-combined — a **default**, overridable per run at `run!` | [§13.5][s13-5], [§12.6][s12-6] |
  | `localization_tol` | `1e-6` | the root-finder's relative bracket-width convergence test (`localization_tol · h`) | [§10.4][s10-4] |
  | `localization_budget` | `8` | the per-frame localization allowance | [§10.4][s10-4] |
  | `firing_budget` | `4` | the per-event, per-boundary firing allowance of the event iteration, an integer ≥ 1 | [§10.6][s10-6] |
  | `join_timeout` | `5.0` | the shutdown tail's join cap, in seconds of wall clock | [§12.4][s12-4] |
  | `trace` | `true` | the input trace's plain kill switch | [§11.5][s11-5] |
  | `log` | `true` | the snapshot log's plain kill switch | [§11.2][s11-2] |
  | `log_every` | `1` | the log's keep-every-kth decimation | [§11.2][s11-2] |
  | `log_max` | `65536` | the maximum number of retained snapshots, finite by default with `Inf` the opt-out | [§11.2][s11-2] |

  `Δt_base` binds from exactly one of three sources ([§9.1][s9-1]): the
  `Δt_base` keyword — a `Rational`, `Period` or `Hz` value, `N_base` then derived
  and validated an integer ≥ 1 — the `N_base·h` product when the keyword is absent
  (the default path), or, in a fully anchored model omitting both, derivation
  from the constraint pool at the coarsest admissible value, printed with its
  drivers ([§9.2][s9-2]).

  `t_end = Inf` is the honest interactive default — open-ended in time but
  bounded in memory, `log_max` being what keeps such a session from growing
  without limit ([§11.2][s11-2]). A run with no finite `t_end`, no `stop_on`
  faces and `pace = Inf` warns at start, an unbounded unattended run being
  almost always an oversight. A run ends at the first grid boundary reaching
  or exceeding `t_end`, whole frames only ([§12.4][s12-4]). The `stop_on` faces
  are recorded in run metadata — the trace header's deployment block
  ([§11.5][s11-5], [§13.5][s13-5]; walkthrough [§15.4][s15-4]).

  An event that exhausts `firing_budget` at a boundary loses its further edges
  there, under a `FiringBudget` warning ([§10.6][s10-6]). `localization_tol`,
  `localization_budget` and `firing_budget` are all three
  trajectory-determining like their siblings, hence validated with them
  (`DeploymentInvalid`) and recorded in the deployment block, where replay
  compares them ([§11.5][s11-5], [§12.7][s12-7]). `join_timeout`, the shutdown
  tail's join cap, is the one operational keyword: it moves no trajectory, so
  it stays outside the deployment block, and replay neither records nor
  compares it ([§12.4][s12-4]).

  Recording: `log_every` is admissible on the derived artifact only, never on
  the trace ([§11.2][s11-2], [§11.5][s11-5], [D-029][d-029]). When the log fills, the
  retention stride doubles, so the whole run stays covered at coarsening
  density, the boundary-zero and terminal snapshots being retained
  unconditionally and outside the bound ([§11.2][s11-2]). All four recording
  keywords — `trace`, `log`, `log_every` and `log_max` — are view policies, not
  trajectory-determining: none enters the deployment block, and replay neither
  records nor compares them.
- `attach!(sim, dev::AbstractDevice, binding::AbstractBinding; should_abort = false)`
  — the roots are mandatory and the signature is the gate.

  | argument | default | meaning | owning section |
  |---|---|---|---|
  | `dev::AbstractDevice` | — | the device instance; the root type is mandatory | [§11.6][s11-6] |
  | `binding::AbstractBinding` | — | the binding value; the root type is mandatory | [§11.6][s11-6] |
  | `should_abort` | `false` | the per-attachment failure policy: set, the device's departure also requests a sim stop; clear, the run continues with the device absent and its claims held to run end | [§11.6][s11-6], [§12.4][s12-4] |

  A departure is the loop body returning, a crash, or a failed `init!`.

  **Sides are declared** by the binding's Bool traits, and each declared side
  carries its own methods:

  | trait / method | default | meaning | owning section |
  |---|---|---|---|
  | `is_input(b)` | `false` on `AbstractBinding` | declares the input side | [§11.6][s11-6] |
  | `is_output(b)` | `false` on `AbstractBinding` | declares the output side | [§11.6][s11-6] |
  | `is_greedy(b)` | `false` on `AbstractBinding` | `true` switches the claim's *source* | [§11.3][s11-3], [§11.6][s11-6] |
  | `claims(b)` / `map_input(datum, b)` | — | the input side: the enumerated face set *is* the claim — what the device may write, not what it will | [§11.4][s11-4] |
  | `reads(b)` / `map_output(nt, b)` | — | the output side | [§14.4][s14-4], [§11.2][s11-2] |

  The conformance check runs at attach, pairing each trait against its method: error fallbacks
  for a declared side whose `claims`/`reads` was never written,
  `which`-against-the-fallback for a method defined under a false trait, both
  `BindingContractMismatch` ([§11.6][s11-6]). A claim is registered with
  exclusivity enforced, and the staged shape and normalization shim are
  compiled ([§11.4][s11-4]); the `reads` selectors are validated and compiled to
  one gather ([§14.4][s14-4], [§11.2][s11-2]). Under `is_greedy(b) = true` the
  framework computes the unclaimed complement at attach instead of calling
  `claims`, everything downstream being identical, an empty remainder legal and
  reported (`EmptyGreedyClaim`), and `is_greedy` without `is_input` an error
  ([§11.3][s11-3], [§11.6][s11-6]). `TableBinding` is the shipped data-driven
  binding, the standard GUI binding the shipped greedy one ([§11.6][s11-6]).

  `attach!` is a stopped-sim operation — legal in `built`, `initialized` and
  `stopped`, an error while `running` and on an `errored` simulation
  (`ServiceLifecycle`; the roster freeze, [§11.3][s11-3], and the terminal
  state, [§13.6][s13-6]). Admission checks identity (`AlreadyAttached` — one roster
  entry per instance, rebinding = `detach!` + `attach!`), calling-task affinity
  (`CallerTaskConflict` — at most one holder) and claims (`ClaimConflict`),
  [§11.3][s11-3]. It registers only: the task appears at the next `run!`.
- `detach!(sim, device)` — removes the roster entry and releases the
  device's claims; stopped-sim only, like `attach!`. A loop body's
  voluntary exit or crash mid-run does *not* detach: the task dies, the
  claims persist to run end ([§11.3][s11-3], [§11.6][s11-6], [§12.4][s12-4]).
- The device contract — `MyDevice <: AbstractDevice` plus `init!(dev)` /
  `loop(dev, handle)` /
  `shutdown!(dev)` / optional `unblock!(dev)` / optional trait
  `needs_calling_task(dev) = false`, a trait the task topology admits at most
  one of per roster and whose device runs its loop body inline on the calling
  task ([§11.1][s11-1]). Around those functions: per-run `init!`
  on the calling task — bracketed, so a throw there is `shutdown!` plus
  `DeviceCrash` by name and the device is dead from boundary zero
  ([§12.4][s12-4]) — the author-owned task body inside the framework's
  try/catch/finally wrapper, voluntary exit = return ([§11.6][s11-6], [§12.4][s12-4]).
- The device handle — one type, capabilities not taxonomy: `running`,
  `latest`, `wait_next_snapshot` ([§12.3][s12-3]), `stage!`, `binding`, `gather`,
  `report!` ([§11.6][s11-6]).

**Condition algebra** ([§14.1][s14-1]–[§14.6][s14-6]).

- `fragment(; x, s, m, inputs)` — self-vocabulary payloads at the authoring
  level; `inputs` names faces of that level's contract.
- `at(prefix, node)` — scoping; stores, never applies. Also lifts whole
  `TrimProblem`s and linearization tap sets ([§14.9][s14-9], [§14.10][s14-10]).
- `combine(nodes...)` — symmetric collection; duplicate leaves error with dual
  provenance; blending a node with a bare NamedTuple is a directive error
  method ([§14.2][s14-2]).
- `override(base, patches...)` — ordered layering; patch wins, provenance
  keeps both ([§14.6][s14-6]).
- `condition(comp; kw)` — the shipped fragment-function idiom; aircraft
  baselines (`ready_for_taxi(ac)`, `cold_and_dark(ac)`) are its
  full-coverage instances.

**Stopped-sim services** ([§14][s14]).

- `init!(sim, condition; t0 = 0.0)` — root-input totality checked pre-write
  ([§14.6][s14-6]), then boundary zero: project → sweep → events → due
  `state_update` calls →
  header + first snapshot ([§14.5][s14-5]).
- `trim!(sim, problem; baseline, t0 = 0.0, backend) → TrimReport` —
  nonlinear least squares on the packed residuals with exact Dual
  Jacobians, against the problem's own `tolerances`
  (`residuals(reads, d) → NamedTuple`, packed in `tolerances`' field order as
  decisions pack in `guess`'s — names pair, order is the declared side's,
  within the problem [§14.7][s14-7] closes at seven fields); setup and commit
  both carry the root-input-totality
  check ([§14.6][s14-6]); commit = `init!` with `override(baseline, solution)` —
  boundary zero anchored at `t0`, recordings cleared ([§12.6][s12-6]); resume-at-
  time = `capture`'s returned `t` as `t0`; `converged` = the service's
  per-residual box test at the backend's returned point, backend-independent
  and the commit's gate, with the backend's status and counts recorded
  diagnostically; the backend seam a pinned one-method signature,
  `solve(backend, eval!, d0, lower, upper, tol) → (; d, status, nevals, niters)`
  — in-place `eval!(r, J, d)` filling `J` only when it is not `nothing`,
  packed vectors in the declared orders, `status` an open `Symbol` recorded
  verbatim; non-convergence reports, never
  throws ([§14.7][s14-7], [§14.8][s14-8]).
- `capture(sim) → (condition, t)` — full-store gather including root inputs;
  warm restart = capture → tweak → apply ([§14.1][s14-1], [§14.10][s14-10]).
- `linearize(sim, taps) → labeled (ẋ₀, x₀, u₀, y₀, A, B, C, D)` — pure query, one
  seeded Dual pass on scratch; operating point defaults to `capture(sim)`;
  taps = `get_state`/`get_input`/`get_output` selector lists with control-design
  labels ([§14.10][s14-10]).

**Running.**

- `run!(sim; gui = false, pace = 1, margin = 0.002, t_end = <ctor value>,
  stop_on = <ctor value>)` — `run!` blocks until the run ends; deviceless it is
  fully synchronous on the calling task; `init!` required first
  ([§12.6][s12-6]). Paced and unpaced runs are bit-identical ([§10.7][s10-7]).

  | keyword | default | meaning | owning section |
  |---|---|---|---|
  | `gui` | `false` | **run-scoped attachment**: at run entry it attaches the standard GUI device under the standard greedy binding, with `should_abort = true`, **iff no GUI is already rostered** | [§12.4][s12-4], [§11.6][s11-6], [§11.7][s11-7] |
  | `pace` | `1` | the run's pacing rate | [§10.7][s10-7] |
  | `margin` | `0.002` | the single pacing knob, in seconds | [§10.7][s10-7] |
  | `t_end` | the constructor's value | overrides that default **for this run only** | [§13.5][s13-5] |
  | `stop_on` | the constructor's value | overrides that default **for this run only**, validated against the `Build` here exactly as at construction | [§13.5][s13-5] |

  The GUI is an ordinary rostered device rendered on the calling task
  ([§11.6][s11-6], [§11.7][s11-7]). Because the flag attaches only if no GUI is
  already rostered, a hand-attached GUI makes it a no-op rather than an
  admission error; and because the run's shutdown tail detaches that GUI again
  ([§12.4][s12-4]), the error path included, nothing the flag
  did survives the run; a persistent GUI session is spelled `attach!`/`detach!`
  by hand. Placement follows the roster, not the flag: a rostered GUI moves the
  loop to a spawned task for as long as it is rostered ([§11.1][s11-1],
  [§12.6][s12-6]); sugar never activates by default.

  `margin` defaults to 2 ms, the sleep primitive's granularity plus its
  measured overshoot, with `0` / 2 ms / `∞` spanning the design space
  ([§10.7][s10-7]). The constructor's `t_end`/`stop_on` pair is recorded in
  the run metadata; the override is reported by the termination record when
  it fires ([§13.5][s13-5]).
- `step!(sim; frames = 1) → frames_advanced` — synchronous partial advance
  through the ordinary frame sequence, bit-identical to the same frames under
  `run!`; `t_plus = <duration>` is the mutually-exclusive duration spelling
  (whole frames until the boundary time covers that duration); returns the
  frames *actually* advanced, fewer than requested when
  `t_end` or a `stop_on` face ended the run inside the call. Between calls the
  simulation reports `initialized`; `run!` may follow and continues from the
  current boundary; a stepping session is deviceless — write via `stage!`,
  read via `latest` ([§12.6][s12-6]).
- `stage!(sim, "face" => value, …)` — task-free staging from the calling
  task into the harness register ([§11.3][s11-3]; surface = the
  currently-unclaimed faces): traced, drained last at the next frame top,
  surface-checked exactly
  as the GUI's writes (the harness cell, [§12.6][s12-6]; legal under `run!` and
  `step!` alike).
- `latest(sim) → snapshot` — the current published snapshot, the same
  immutable value device handles read ([§11.2][s11-2]); the assertion/inspection
  accessor of the harness and REPL registers ([§12.6][s12-6]).
- `phase_bodies(sim) → named callables` — the compiled phase bodies of the
  nominal activation, bound over the simulation's own buffers: the four
  blocks (`rhs`, `sweep_1`, `sweep_2`, `ticks` — the sweeps in both
  arities, zero-arg interior and tick-indexed boundary; `ticks` takes the tick
  index) plus per-event guards/handlers and per-component `state_projection`, keyed
  by the model's roster. The [§7.5][s7-5] allocation seam: warm, then
  `@ballocated(body()) == 0` per body; diagnostic register, the one promise
  being identity with what the loop runs; isolated invocation leaves buffers
  valid but off-trajectory — re-run `init!` to continue ([§9.7][s9-7]).
- Control plane — pause/un-pause, pace and `margin` changes, stop on a
  separate atomic surface, never staged ([§12.1][s12-1]; pacing sits outside the
  semantics, so pace and `margin` are both safe to change live).
- Termination — model state via `stop_on` faces read at every published
  boundary ([§13.5][s13-5]); shutdown completes a boundary, publishes the final
  snapshot, then joins ([§12.4][s12-4]).
- Post-run — the log is retained snapshots; `trace(sim) → trc` retrieves the
  always-on input trace, and `replay!(sim2, trc; to_boundary = k)` re-drives
  a fresh `Simulation(world)` bit-identically through the ordinary loop
  (boundary zero from the trace header, drain fed by frame ordinal), ending
  `initialized`; `to_time = t` is the mutually-exclusive time spelling of the
  halt, floored to the last frame top at or before `t` — inspect via
  `latest`/live stores, advance via `step!`, continue via `run!`; the
  state-trajectory inspector and the `StepError`
  reproduction tool ([§11.2][s11-2], [§11.5][s11-5], [§12.7][s12-7]; on-disk persistence deferred,
  [§16][s16]).
- `mode(sim) → :live | :replay` — the input mode, read beside the lifecycle
  state: where the next frame's drain takes its batches from, the staging cells
  or a recording `replay!` attached ([§12.6][s12-6], [§12.7][s12-7]).
- `live!(sim)` — detaches the remainder of an attached recording and sets the
  mode to `:live`, touching neither trajectory nor trace register, so the next
  `run!` or `step!` continues live from the replayed boundary and re-records
  onto the replayed prefix; stopped-sim only, legal on an `initialized`
  simulation in `:replay`, and an already live one refuses
  ([§12.6][s12-6], [§12.7][s12-7]).

---

## Appendix C. The diagnostic kind set

The kinds below are the closed set [D-058][d-058] commits to, made normative. **Tests
match on kind plus payload fields, never on message text** ([§13.2][s13-2]). So
the entries below — not any message — are the acceptance-test contract. Adding a
kind is a decision-log entry. Every entry's payload is *in addition to* what
[§13.2][s13-2] requires of all diagnostics: paths and names as strings, never
instances; the list-in-hand wherever a did-you-mean renders; the didactic
register (state the fix). Owning sections stay the normative home of each rule;
this appendix is an index of the values, in the manner of Appendices A and B.

Each entry names the kind, then its owning sections in parentheses, then
severity · raised · policy, then the payload. Three fields place each kind.
**Severity** is a property of the kind, read as `severity(d)` ([§13.2][s13-2]),
and takes one of two values:

- **error** — an occurrence throws, alone or within a collection; a stratum
  that produced one throws before the next begins ([§13.1][s13-1]);
- **warning** — an occurrence never throws and joins no throw; it renders
  with a collection, is logged beside a returned value, or rides the runtime
  stream, according to where and how it is raised.

**Raised** and **policy** describe the occurrence, not the kind — where it
surfaces, and how it is reported. A kind raised at two stages lists both
(`BundleFieldError`: at the probe, and as a `StepError` [species](#g-species) thereafter);
the placement notes stay in the raised field beside the stage they qualify.
The stages are the ones [§13][s13] fixes:

- **build** — during one of the three strata ([§9.1][s9-1]), whether in a declarative
  pass or while *user code* runs (an interface-connection body, a probe);
- **service** — in a stopped-sim service, or in `attach!`/`Simulation`/`run!`
  validating against the `Build`;
- **runtime** — during a boundary.

The policies:

- **collected** — gathered with its siblings and thrown as one carrier: a
  declarative pass's violations as the `DiagnosticError` of the stratum barrier,
  every pass that ran under [§13.1][s13-1]'s dependency rule merging into the one
  throw ([D-229][d-229]); a service's wherever the owning section says so (the register,
  [§14.1][s14-1]; the pre-write check, [§14.6][s14-6]);
- **fail-fast** — the first occurrence throws on its own, nothing else being
  gathered: at build the first user-code failure aborts the phase ([§13.1][s13-1]); at
  a service call the first violation is the throw; at runtime it reaches the
  single catch site ([§13.4][s13-4]) as a species of `StepError`;
- **logged** — a warning from a stopped-sim service call that *completed*:
  emitted at the call site through the standard logging backend, beside the
  returned value, part of no collection; no rate limit — each kind fires at
  most once per call, and its payload is drawn from the report the call
  returns ([§14.5][s14-5], [§14.8][s14-8]);
- **rate-limited** — the per-occurrence runtime warning stream of [§13.2][s13-2],
  carried by the per-writer diagnostic cells ([§11.8][s11-8]) and bounded by them:
  every kind reported this way is bounded per writer per boundary (a ring of
  sixteen retained values, the excess becoming per-kind suppressed counts).
  The per-entry qualifiers record where that bound is load-bearing — a source
  that can repeat within a frame — and where the source itself fires once.
  A kind carried this way names its subjects in the payload, never its
  writer: the cell attributes the writer, and the status record's `who` and
  the tail residue carry that attribution ([D-228][d-228]). `DeviceJoinTimeout`'s
  device id is a subject, the abandoned device, written by the loop.

The build warning set — warning-severity kinds raised at build, rendering
with the collection and never triggering its throw — is currently empty
([D-084][d-084]).

**Declaration and wiring** (Stratum A):

- **`UnknownPort`** ([§6.1][s6-1], [§8.4][s8-4] w1) — error · build · collected. The
  wire end (`source`/`destination`, or `connection` for an interface-connection entry's
  internal side, [D-210][d-210]), that end's path, the unknown port name, that end's
  port list (did-you-mean).
- **`UnconnectedInput`** ([§6.1][s6-1], [§8.4][s8-4] w2) — error · build · collected.
  Leaf path, input name, declared entry type, the obligation chain's last level.
- **`TwoProducers`** ([§6.1][s6-1], [§8.8][s8-8]) — error · build · collected.
  Destination terminal, both producer terminals with provenance (sibling wire /
  interface connection entry).
- **`WireTypeMismatch`** ([§6.1][s6-1], [§8.2][s8-2], [§8.4][s8-4] w4) — error · build ·
  collected. Both endpoint paths, both face names, declared entry type, producer face
  type.
- **`WalkingFaceAtFrozenEntry`** ([§6.1][s6-1], [§8.2][s8-2]) — error · build ·
  collected. Consumer path and entry name, producer path and face name, the offending
  leaf, both declared leaf types; both remedies in the message ("declare the entry `T`
  if the consumer promotes; feed it from a non-walking source if the freeze is
  genuine").
- **`PathResolution`** ([§6.1][s6-1], [§13.3][s13-3]) — error · build · collected. Path,
  offending segment, sibling field list; for a wiring endpoint reaching past the
  immediate child, the level it stopped at; for a read-side traversal past a
  generically-held field, that field's declared type.
- **`AbstractAtRoot`** ([§8.2][s8-2]) — error · build · collected. Face name, consuming
  leaf path, the abstract entry; remedy hint (wire a concrete producer — in a rig, a
  stub child, [§13.7][s13-7]).
- **`RootInputTypeConflict`** ([§8.2][s8-2]) — error · build · collected. Face name, the
  consuming paths, their conflicting concrete declarations at nominal (a tolerance
  difference is not a conflict — the meet, [§8.2][s8-2]).
- **`IllegalStateLeaf`** ([§7.1][s7-1], [§8.2][s8-2]) — error · build · collected.
  Component path, `init_x` field name, leaf type, the closed vocabulary (scalar /
  `SArray` at the common eltype).
- **`StoreWithoutUpdate`** ([§8.2][s8-2]) — error · build · collected. Component path,
  the `init_x` or `init_s` store, the missing update (no `state_derivative` for the one,
  no `state_update` for the other); shadowing note when the parent module defines its
  own `state_derivative`/`state_update` ([§8.1][s8-1]).
- **`EventHalfMissing`** ([§8.2][s8-2]) — error · build · collected. Component path,
  event name, reason (guard half missing / handler half missing / the entry is not a
  `StateEvent`), the function that has no method or the entry's type.
- **`ClassUnreadable`** ([§8.5][s8-5]) — error · build · fail-fast. Component path,
  type, declarations found, both family lists; did-you-mean when the type holds
  component-typed fields; shadowing note when the parent module defines same-named
  declaration functions ([§8.1][s8-1]).
- **`ClassMixed`** ([§8.5][s8-5]) — error · build · fail-fast. Component path, the
  `child_connections` declaration and the offending leaf declarations.
- **`ContainerMixed`** ([§8.5][s8-5]) — error · build · fail-fast. Container field path,
  offending element keys/indices, their types.
- **`DeclarationOnWrongTier`** ([§5.2][s5-2], [§8.2][s8-2], [§8.5][s8-5]) — error ·
  build · collected. Component path, the offending declaration
  (`state_derivative`/`state_update`, a store from the wrong family — `init_x` against
  `init_s`, [D-195][d-195] — `state_events`, `init_m`, `state_projection`, or an
  `init_workspace`/`output_types` arity), the tier the leaf's other declarations
  announce.
- **`TierSignatureMismatch`** ([§6.1][s6-1], [§8.2][s8-2], [§8.5][s8-5]) — error · build
  · collected. Component path, the declaration at fault (`input_types` or
  `output_types`), the leaf's tier, the signature form found versus the form mandated
  (two-argument `(::C, ::Type{T})` on the continuous tier, plain `(::C)` on the
  discrete); stateful leaves only — on a stateless leaf `output_types`' arity *is* the
  tier ([§8.2][s8-2]), so there is nothing to mismatch; a two-argument form whose `T` is
  bounded narrower than `Real` is the same violation on any continuous leaf, decided by
  method lookup at the marker scalar ([§6.1][s6-1]), the bound found versus the mandated
  `T <: Real`.
- **`FaceNameIllegal`** ([§8.6][s8-6]) — error · build · collected. Assembly path, face
  name, the violated invariant (contains `/`).
- **`FaceNameCollision`** ([§8.6][s8-6]) — error · build · collected. Assembly path,
  face name, both entries' provenance (hand-written / computed).
- **`FaceDirectionConflict`** ([§8.6][s8-6]) — error · build · collected. Assembly path,
  the declaring method, the offending entry, the resolved port's actual direction.
- **`UnknownFaceSelection`** ([§8.8][s8-8]) — error · build · fail-fast. Child path,
  reason (unknown names / both `except` and `only` given), the offending names, the
  child's face list.
- **`RatesViolation`** ([§10.5][s10-5], [§8.7][s8-7]) — error · build · collected.
  Assembly path, offending key, reason (deep key / unknown child / `K` on a continuous
  child).
- **`MissingProbeValue`** ([§9.3][s9-3]) — error · build · collected. Face name, type.
- **`ChildNameCollision`** ([§8.5][s8-5]) — error · build · fail-fast. Assembly path,
  the colliding child name, reason (a bare container key against the `sample_times`
  sugar, [D-211][d-211] / against a sibling field, [D-212][d-212] / two children with
  one name), both provenances.
- **`TransparentContainerUnknown`** ([§8.5][s8-5], [D-211][d-211]) — error · build ·
  fail-fast. Assembly path, the field `transparent_container` names, the type's
  container fields (the list-in-hand).
- **`TierUnreadable`** ([§5.2][s5-2], [§8.2][s8-2], [§8.5][s8-5]) — error · build ·
  collected. Component path, type, the declarations found — no `output_types`, no state
  — and the tier-announcing family list; the tier twin of `ClassUnreadable`.
- **`IllegalPortType`** ([§7.1][s7-1], [§8.2][s8-2]) — error · build · collected.
  Component path, the declaration at fault (`input_types`/`output_types`, or a root
  input), port name, the offending type — one with no numeric leaves, a mutable one, or
  a handle at a root input; the leaf vocabulary ([§7.1][s7-1]).
- **`IllegalStoreField`** ([§7.3][s7-3], [§8.2][s8-2], [§9.1][s9-1]) — error · build ·
  collected. Component path, the store at fault (`init_s`/`init_m`), field name, the
  offending type — one neither isbits nor `Symbol`; the fix (text and bulk data belong
  on the component instance).

**Schedule and contract conformance** (Strata B and C):

- **`AlgebraicCycle`** ([§5.5][s5-5], [§5.6][s5-6]) — error · build · collected. The
  SCC's member terminals in slash form, the wires among them, optional classification
  (`real`/`artificial`) with the member whose hop died.
- **`ProducedByTwoStages`** ([§4.3][s4-3], [§8.3][s8-3]) — error · build · fail-fast —
  with the probe chain ([D-229][d-229]). Component path, port name, both stage names.
- **`DeclaredNotProduced`** ([§8.3][s8-3]) — error · build · collected, by the
  completeness pass over the complete products, which runs only once every port
  check has passed ([D-239][d-239]). Component path, declared name, the
  stage-product list and the state-field list.
- **`UndeclaredReturnField`** ([§8.3][s8-3], [§8.4][s8-4] w5) — error · build ·
  fail-fast, alone: it stops the probe chain before the completeness pass
  ([D-239][d-239]). Component path, stage, returned field name, candidates
  (`output_types`).
- **`DeadStage`** ([§5.2][s5-2], [§9.3][s9-3]) — error · build, at probe · fail-fast.
  Component path, stage — a stage method returning bare `(;)`, producing no ports.
- **`ConformanceFailure`** ([§9.5][s9-5]) — error · build, at probe; runtime thereafter
  · fail-fast — a `StepError` species at runtime. Component path, function, field-level
  diff (missing / unexpected / per-field expected-vs-observed — order-insensitive,
  fields pairing by name), simulation time.
- **`GuardForm`** ([§9.5][s9-5]) — error · build · fail-fast. Component path, event
  name, observed probe return type, both admissible forms.
- **`BundleFieldError`** ([§5.2][s5-2], [§13.2][s13-2]) — error · build, at probe;
  runtime thereafter · fail-fast — a `StepError` species at runtime. Component path,
  function family, requested field, the legal field set, classification (undeclared
  store / wrong-tier fact / illegal for this function family).
- **`HandlerReturnKey`** ([§5.2][s5-2], [§9.5][s9-5]) — error · build · fail-fast.
  Component path, event name, offending key, the legal set `{x, m}` narrowed to the
  stores that exist.
- **`UserCodeFraming`** ([§13.2][s13-2]) — error · build · fail-fast. Component path,
  which function, the probe context including synthesized inputs; the original exception
  as `cause`.

**Deployment, periphery and services:**

- **`MissingInit`** ([§12.6][s12-6]) — error · service · fail-fast. The simulation's
  status, the entry point called (`run!`/`step!`).
- **`ServiceLifecycle`** ([§11.3][s11-3], [§14][s14]) — error · service · fail-fast. The
  operation (`attach!`/`detach!`/`init!`/`trim!`/`capture`/`linearize`), the current
  status, the legal statuses.
- **`StopFaceInvalid`** ([§13.5][s13-5]) — error · service · collected, over the given
  faces. Face name, reason (unknown / not root-exported / not `Bool`), the root
  output-face list; the binding site (constructor or `run!`).
- **`DeploymentInvalid`** ([§9.1][s9-1]) — error · service · collected. The deployment
  parameter (`h`, `N_base`, `Δt_base`, algorithm, `localization_tol`,
  `localization_budget`, `firing_budget`, `join_timeout`, `log`, `log_every`, `log_max`,
  `t_end` ([§13.5][s13-5]), the harmonic-grid relation, a non-dividing anchor period or
  offset — the anchor named with its declaring scope and key), the value in hand, the
  violated constraint.
- **`AttachUnknownFace`** ([§11.3][s11-3]) — error · service · fail-fast. The device (by
  type — its roster id is assigned only at admission), binding entry, face name, the
  root input-face list.
- **`AlreadyAttached`** ([§11.3][s11-3]) — error · service · fail-fast. The device id of
  the existing roster entry, its binding.
- **`CallerTaskConflict`** ([§11.1][s11-1], [§11.3][s11-3]) — error · service ·
  fail-fast. Both device ids — the rostered `needs_calling_task` holder and the
  candidate.
- **`ClaimConflict`** ([§11.3][s11-3]) — error · service · collected, over the device's
  claim set. Face name, claiming device id, incumbent device id.
- **`EmptyGreedyClaim`** ([§11.3][s11-3], [§11.6][s11-6]) — warning · service · logged.
  The greedy device's id and its binding — the computed complement was empty, every
  root-input face being claimed already.
- **`BindingContractMismatch`** ([§11.6][s11-6]) — error · service · fail-fast. The
  binding type, the trait and the method at fault, and the direction: a declared side
  whose enumeration method is missing (`is_input`/`is_output` true, the root's error
  fallback reached), or a `claims`/`reads` method defined under a false trait (detected
  by `which` against the fallback); `is_greedy` without `is_input`, `claims` defined on
  a greedy binding, and a binding declaring neither side, report here too.
- **`DeviceContractMismatch`** ([§11.6][s11-6]) — error · service · fail-fast. The
  device type, and what the contract lacks: the `loop` method, or the output side
  `gather` needs from a binding that declares none — the device twin of
  `BindingContractMismatch`.
- **`ReadBindingUnresolved`** ([§11.2][s11-2], [§14.4][s14-4]) — error · service ·
  fail-fast. The device (by type — its roster id is assigned only at admission), the
  selector, path and field, candidates; a `reason` distinguishing an unresolved path
  from a store selector in a snapshot binding (the source rule, [§14.4][s14-4]).
- **`ConditionResolution`** ([§14.2][s14-2], [§14.3][s14-3]) — error · service ·
  collected. Entry path, store and field (or the root-input face the entry addresses),
  offending value type and declared leaf type, the leaf's tier and role where the
  refusal is tier-bound, the producer where a face is fed, candidates where a list is in
  hand, provenance chain; sub-kinds: unknown path, undeclared field, unconvertible
  value, unexported root-input face.
- **`DuplicateConditionLeaf`** ([§14.2][s14-2]) — error · service · collected. The leaf
  `(path, store, field)`, both provenance chains, the `override` advice.
- **`ConditionNodeMisuse`** ([§14.2][s14-2]) — error · service · fail-fast. The
  offending argument's type, the node kinds in hand.
- **`UninitializedInputs`** ([§14.6][s14-6]) — error · service, pre-write · collected.
  Every uncovered root face, in declaration order.
- **`TapResolution`** ([§14.10][s14-10]) — error · service · collected. Tap set
  (`x`/`u`/`y`), selector kind, path, field, optional index, candidates; for a
  declaredly-unseedable root input, the pinning consumer's path and its `input_types`
  entry.
- **`TrimProblemInvalid`** ([§14.7][s14-7], [§14.8][s14-8]) — error · service ·
  collected. The offending `TrimProblem` field, the names or types in hand (a key-set or
  field-type mismatch; never a field-order difference).
- **`TrimCommitEvents`** ([§14.8][s14-8]) — warning · service · logged. The events fired
  at boundary zero: component paths and event names; the same list rides the
  `TrimReport`.
- **`TrimCommitResiduals`** ([§14.8][s14-8]) — warning · service · logged. The offending
  residual names with committed-state values and tolerances — a converged solve whose
  committed-state residuals violate the box test.
- **`ConditionShapeDrift`** ([§14.4][s14-4]) — error · service · fail-fast. The compiled
  tree type and the observed one; for a prefix mismatch, the node position and both
  strings; the remedy — a condition function returns one shape for every decision.
- **`GridUtilization`** ([§9.1][s9-1], [§9.2][s9-2]) — warning · service, at deployment
  binding (derivation path only) · logged. The derived `Δt_base`, its driver entries
  with provenance and refinement factors, and `min_i Dᵢ` — the grid rendered as "N×
  finer than the fastest declared work".
- **`ReplayHeaderMismatch`** ([§11.5][s11-5], [§12.7][s12-7]) — error · service ·
  collected. The mismatch, discriminated: a store or root input (component path, store,
  expected vs. found layout/type) or a deployment parameter
  (`Δt_base`/`h`/`N_base`/algorithm/`localization_tol`/`localization_budget`/`firing_budget`,
  recorded vs. bound value) or a frame ordinal outside the recording's length (the
  writer, the ordinal, the legal range); the build's and the trace's provenance.
- **`ReplaySchemaMismatch`** ([§11.5][s11-5], [§12.7][s12-7]) — error · service ·
  collected. The trace's device tag, its recorded face-name → position schema, the
  disagreeing face names, the target's root input-face list.
- **`ReplayUnknownFace`** ([§12.7][s12-7]) — error · service · collected. Face name, or
  the bare position where the writer's schema has no name for it; frame ordinal, the
  trace's device tag, the root input-face list.
- **`ArgumentInvalid`** ([§8.7][s8-7], [§11.6][s11-6], [§12.6][s12-6], [§14.7][s14-7]) —
  error · service; build, in a `sample_times` declaration · fail-fast; collected over a
  `TableBinding`'s entry table. The call (`step!`, `trim!`, `TableBinding`, a period
  constructor), the argument, the value in hand, the violated constraint — the twin of
  `DeploymentInvalid` for arguments that are not deployment parameters.
- **`ReadSetMisuse`** ([§14.4][s14-4]) — error · service · fail-fast. The offending
  argument's type, the selector kinds in hand — the read register's twin of
  `ConditionNodeMisuse`.
- **`NotAttached`** ([§11.3][s11-3]) — error · service · fail-fast. The device id or
  handle offered to `detach!`, the roster's device ids.

**Runtime:**

- **`StepError`** ([§13.4][s13-4]) — error · runtime · fail-fast. The carrier: cursor
  frame (component path, function, boundary phase — RK stage, event round, localization
  trial evaluation, tick), boundary time, frame-entry boundary index (replay pointer),
  the `cause` — a species' diagnostic or the original exception, its type the parameter.
- **`NonfiniteState`** ([§13.4][s13-4]) — error · runtime · fail-fast. Component path,
  the offending state block, boundary time and index.
- **`ChatteringBudget`** ([§10.4][s10-4]) — warning · runtime · rate-limited. Component
  path, event name, boundary time, the exhausted `localization_budget` and the frame's
  localization count.
- **`FiringBudget`** ([§10.6][s10-6]) — warning · runtime · rate-limited. Component
  path, event name, boundary time, the exhausted `firing_budget` and the boundary's
  firing count.
- **`DebtReanchor`** ([§10.7][s10-7]) — warning · runtime · rate-limited. Forgiven debt,
  the new schedule anchor, boundary time.
- **`ClaimedFaceEntry`** ([§11.3][s11-3], [§11.4][s11-4]) — warning · runtime ·
  rate-limited. Face name, the incumbent (claiming) device id, the discarded value; the
  site (staging, or a stopped-sim attach's renormalization). Harness-register only — a
  device's out-of-surface entry is `OutOfClaimEntry`.
- **`OutOfClaimEntry`** ([§11.3][s11-3]) — warning · runtime · rate-limited. Face name,
  the discarded value, the device's claim set; the incumbent's device id when the face
  is claimed elsewhere.
- **`ThreadBudget`** ([§12.2][s12-2]) — warning · runtime, at `run!` · rate-limited.
  Thread count, device-task count.
- **`DeviceJoinTimeout`** ([§12.4][s12-4]) — warning · runtime, at the shutdown tail —
  written to the loop's cell, collected by the run's-end sweep into the termination
  record and presented through the logging backend, past the terminal snapshot
  ([D-201][d-201], [D-203][d-203]) · rate-limited. Device id, the join timeout, boundary
  time and index at shutdown.
- **`DeviceCrash`** ([§12.4][s12-4], [§11.6][s11-6], [§13.4][s13-4]) — warning · runtime
  · rate-limited. The original exception as `cause`, whether `should_abort` was set;
  also the init-time failure, reported pre-spawn from the initialization bracket after
  its `shutdown!`.
- **`ReplayDiscardedStaging`** ([§12.7][s12-7]) — warning · runtime · rate-limited;
  repeating source ([§11.8][s11-8]). The discarded batch's face names, frame ordinal.
- **`MalformedDatum`** ([§11.6][s11-6], [§13.4][s13-4]) — warning · runtime ·
  rate-limited; repeating source ([§11.8][s11-8]). The cause exception; emitted by the
  author's loop body via `report!(handle, …)`.
- **`EntryTypeMismatch`** ([§11.4][s11-4]) — warning · runtime · rate-limited. Face
  name, the offending value's type, the root input's declared type, the discarded value.
- **`UnboundedRun`** ([Appendix B][sB], [§13.5][s13-5]) — warning · runtime, at run
  start · rate-limited. The effective `t_end`, `stop_on` set and `pace`; the remedy
  names both, and — interactively — the operator interrupt as the sanctioned escape from
  the configuration warned about ([§12.4][s12-4]).

---

## Appendix D. Glossary

*Non-normative. Each entry compresses the meaning its owning section fixes
and cites that section; where an entry and its owning section diverge, **the
owning section wins** — the same precedence rule the companion walkthrough
explainers carry. The glossary's job is to route a reader to the normative
text and to make drift visible, never to be a second source of truth. Entries
are grouped by subject and alphabetical within each group; a term appears
once, in the group that owns it, with a "not to be confused with" clause
wherever a neighboring term is genuinely close.*

### D.1 Component model and declaration layer

<a id="g-abstract-entry"></a>**abstract entry** — an `input_types` entry whose declared type is abstract,
stating **structural substitutability**: any concrete producer face below the
bound wires to it (the field handles, [§4.4][s4-4], are the demonstrated client). Never
needed for eltype genericity, and illegal where the face surfaces as a
root input (`AbstractAtRoot`) ([§8.2][s8-2]).

<a id="g-assembly"></a>**assembly** — pure composition: component-typed fields as children, plus
`child_connections` (mandatory, the class marker), `input_connections`,
`output_connections`, `sample_times` and the optional
`transparent_container`, with no
dynamics of its own; flattened away for scheduling, retained as the
navigation hierarchy and as declaration-level rate scopes ([§3.3][s3-3], [§8.5][s8-5]).

<a id="g-auto-published-port"></a>**auto-published port** — a declared output that matches a state or mode field
by name and type and that no stage produces: the framework publishes it from
the store at stage-1 position on either tier; the match is against `init_x`
plus `init_m` on the continuous tier, `init_s` on the discrete. Contract-driven — [D-016][d-016]
rejected blanket identity publication of state — a framework write, never a
probe product, and excluded from the stage-1 hand-down `y_x`/`y_s` ([§5.3][s5-3], [§8.3][s8-3],
[§5.2][s5-2], [D-169][d-169]).

<a id="g-class"></a>**class** — a component's primitive-vs-assembly status, read off *which*
well-known declarations its type defines: `child_connections` ⇒ assembly, any leaf
declaration ⇒ primitive, neither ⇒ `ClassUnreadable` ([§8.5][s8-5]). Not to be
confused with *tier* (continuous vs. discrete, [§D.4][sD-4]) — though class
*mandates* the contract shape that spells the tier ([§8.5][s8-5]) — or with a
diagnostic *kind* ([§D.9][sD-9]). "Class" in the continuous-vs-discrete sense
("class split", "two leaf classes", [§15.5][s15-5]) is ordinary English, a
distinct usage, never linked here.

<a id="g-component"></a>**component** — the unit of modeling: a leaf (continuous or periodic discrete
primitive) or an assembly of components; "primitive" and "leaf" are used
interchangeably for the non-assembly classes ([§3][s3]).

<a id="g-container-children"></a>**container children** — a `Tuple`/`NamedTuple` field whose elements are all
components, contributing them as children path-named `"field/1"` or
`"field/key"` — or by bare key, `"1"` or `"key"`, where the field is declared
name-transparent via `transparent_container`. Transparent grouping, not an
assembly: no contract, no `child_connections`, no rate scope ([§8.5][s8-5]).

<a id="g-continuous-component"></a>**continuous component** — the hybrid primitive: continuous state `x`, modes
`m`, flow `state_derivative`, two output stages, events (guards + handlers) and optional
`state_projection`; any facet may be empty, so a state-free instance is an FSM ([§3.1][s3-1]).

<a id="g-contract"></a>**contract** — a component's declared interface: `input_types` (its
requirements, read permissively — what each entry *allows* to arrive) and
`output_types` (its public ports, read literally — what each cell *carries*).
Both take the two-argument `T`-form on the continuous tier and the plain form on
the discrete one. Declared in
`output_types` = public, returned in `y` and declared nowhere = build error
([§8.2][s8-2], [§8.3][s8-3]). Not to be
confused with the other contracts this spec names — the device authoring
contract ([§11.6][s11-6]), the stepper seam's backend contract ([§10.2][s10-2]), the
staging contract ([§11.7][s11-7]), the step-boundary contract ([§10.6][s10-6]) and the
*derived contract* ([§D.1][sD-1] above) — each a distinct sense, linked never or
at its own anchor.

<a id="g-declaration-inventory"></a>**declaration inventory** — the closed set of well-known functions a component
or assembly defines — `init_x`/`init_s`/`init_m`, `init_workspace`,
`input_types`/`output_types`, `state_events`, the stages,
`state_derivative`/`state_update`/
`state_projection`, and `child_connections`/`input_connections`/`output_connections`/`sample_times`/`transparent_container` — each declared in a stated
register of authority: by value, by type, by allocation ([§8.2][s8-2]).

<a id="g-derived-contract"></a>**derived contract** — the checkable surface an assembly or the
`Build` derives from its children's declarations and its own wiring instead of
declaring itself: an assembly's effective face list, the `Build`'s wire list,
face table, schedule and root inputs. Plain printable data — paths, names and
rationals, inspectable as fields, no rendering implied beyond the ones [§9.2][s9-2]
names — and on a generic holding the constraint the referencing wires and interface connections impose on
whatever concrete child is plugged in ([§8.6][s8-6], [§8.8][s8-8], [§9.2][s9-2]).

<a id="g-function-family"></a>**function family** — which bundle fields a given function may legally
receive: `output_state`/`output_direct`/`state_derivative`/`state_update`/guard/handler/`state_projection`
(one closed set per name per tier, the shared output stages taking one set on
each, [§5.2][s5-2], [D-220][d-220]), with the
comment block ([§5.2][s5-2]) stating each family's maximal legal set and
`BundleFieldError` classifying a read as illegal for the family ([§5.2][s5-2]).
Not a diagnostic *kind* ([§D.9][sD-9]).

<a id="g-generic-holding"></a>**generic holding** — a parent holding a child through a non-concrete field
type; the child is opaque below its faces, and the wires and interface connections
referencing those faces *are* the imposed derived contract, checked per instantiation
([§8.8][s8-8], [§6.1][s6-1]).

<a id="g-hybrid-causal-system"></a>**hybrid causal system** — what the framework simulates: continuous flow with
algebraic outputs, multi-rate periodic discrete dynamics, zero-crossing
events, post-step manifold projection, and externally injected inputs ([§2][s2]).

<a id="g-the-letters"></a>**the letters** — the mathematical symbols the spec's formulas keep, against the
words the API spells them as ([D-220][d-220]): `f` the continuous flow
(`state_derivative`), `g` the discrete update (`state_update`), `y = h(x)` and
`y = h(x, u)` the two output stages (`output_state` and `output_direct`). The
bundle letters are API in their own right: `x` the continuous
state and `m` the continuous-only mode store, `s` the discrete state ([D-195][d-195]),
`u` wired inputs, `y` own published signals, `ws` the
workspace. Bare `h` means the integration step size only ([§10][s10]);
bare `z` means only the shift operator `z⁻¹` — retired as a state letter by
[D-173][d-173] and never reclaimed, the discrete state having its own.

<a id="g-periodic-discrete-component"></a>**periodic discrete component** — a leaf with state `s`, update `state_update`
at a declared rate, and two output stages whose cells hold zero-order between
ticks; it has no `m` store, and its `s` reaches others only through signals
([§3.2][s3-2]).

<a id="g-rate-scope"></a>**rate scope** — an assembly's `sample_times` declaration: immediate child
name ⇒ `Relative` or `Absolute` declaration against the enclosing scope,
relative entries composing affinely down the tree, absolute entries
anchoring; all compiled to one `(D, Φ)` pair per discrete component
([§8.7][s8-7], [§10.5][s10-5]).

<a id="g-schema-authority"></a>**schema authority** — the principle that declarations *define* structure and
evaluation only *checks* conformance against them, never the reverse; types by
declaration, values by execution, conformance by comparison ([§8.1][s8-1]).

<a id="g-stage-function"></a>**stage function / two-stage outputs** — every component provides exactly two
output stages, `output_state` (no `u` in the bundle, hence structurally no
feedthrough) and `output_direct`; one pair of names over both tiers, each
name's legal bundle set being tier-dependent ([D-220][d-220]). Feedthrough is
thereby declared by signature, with no dependency annotations anywhere
([§5.2][s5-2]).

<a id="g-workspace"></a>**workspace** — component-declared mutable scratch, declared *by allocation*
(`init_workspace(::C, ::Type{T})` continuous, `init_workspace(::C)` discrete), arriving
as the `ws` bundle field; excluded from state semantics, never a condition
target, and never inspected or mutated by the framework — contents at call
entry are unspecified ([§7.3][s7-3]).

### D.2 Signals and data homes

<a id="g-buffer"></a>**buffer** — the framework-owned contiguous `Vector{T}` backing all continuous
state, laid out at build time; authoritative, with typed state values as
ephemeral reconstructions of it ([§7.1][s7-1]). The integration intermediates ([§13.6][s13-6]) live
in framework-owned integrator buffers, never in a component's workspace.

<a id="g-bundle"></a>**bundle** — the single `NamedTuple` of zero-copy views a component function
receives beside the component itself. Under the bundle law a name is present
**iff** the corresponding store or fact exists for that component; undeclared
stores are absent, never `nothing`-filled ([§5.2][s5-2]).

<a id="g-cell"></a>**cell** — one concretely-typed entry of the signal table, one per output port
of the flattened model, written by its producing
stage and read by every gatherer ([§4.1][s4-1]). Every cell is public, private
intermediates never being cells ([§8.3][s8-3]). Bare "cell" is only this — see
*staging cell* ([§D.6][sD-6]) and *store*.

<a id="g-constant-source"></a>**constant source** — an ordinary library component with no inputs and no
state, publishing a value its instance holds (`Constant{V}`); the spelling for
an aggregate input with zero contributors and for the rig stub feeding an
abstract face. Its value is instance data, never a default ([§13.7][s13-7], [§6.2][s6-2]).

<a id="g-entry"></a>**entry** — never used bare: the spec's compounds are table entry (a cell),
input entry ([§8.2][s8-2]), executor entry ([§9.7][s9-7]), roster entry ([§11.3][s11-3]), batch entry
([§11.3][s11-3]) and condition entry ([§14.3][s14-3]), each a different thing.

<a id="g-face"></a>**face** — the name a port wears on its component's boundary: for a leaf the
port's own name, for an assembly a name declared in `input_connections` or
`output_connections`, aliasing an interior port. An opaque token with
two build-checked invariants (no `/`, unique within the assembly), its type
derived from its internal endpoint and its direction declared by the method
that names it. The periphery's write side
speaks face names only; the read side speaks them wherever it wants contract
rather than structure ([§8.6][s8-6], [§11.2][s11-2], [§14.4][s14-4]).

<a id="g-feedthrough"></a>**feedthrough** — an instantaneous input→output dependence. **Structural
feedthrough** is this design's version: fixed by which stage produces a port
rather than annotated, with every stage-2 output conservatively presumed
dependent on every wired input ([§5.3][s5-3]).

<a id="g-field-handle"></a>**field handle / function-valued signal** — an immutable query object carried
on an ordinary port (`ISAField`, `TerrainField`) that consumers evaluate at
arguments of their own choosing; bulk data rides as build-time-frozen
references, never as mutable caches ([§4.4][s4-4]).

<a id="g-immutable-value-semantics"></a>**immutable value semantics** — the signal rule, stated precisely as
immutability *plus frozen references* (`isbits` is the common case, not the
rule): no aliasing, safe concurrent reads, and a definite per-cell freshness
tied to the producer's schedule position ([§4.1][s4-1]).

<a id="g-one-home-per-datum"></a>**one home per datum** — buffer for `x`, stores for `s` and for `m`, table for
produced signals; no store mirrors another, and the table never holds
transported data ([§5.2][s5-2], [§7.1][s7-1]).

<a id="g-port"></a>**port** — the addressable unit of the model: one declared name, one cell, one
root input, one staged write, one device claim, one trace address, one GUI
liveness verdict. Wiring is port-granular, and which stage computes a port is
invisible outside the component ([§4.2][s4-2], [§4.3][s4-3]).

<a id="g-root-input"></a>**root input** — the root component's own input face —
an assembly's `input_connections` key, a primitive's `input_types` key —
produced by no component, constant within a frame, and the only thing the
periphery may write ([§11.3][s11-3], [§8.2][s8-2], [§8.6][s8-6]).

<a id="g-scratch"></a>**scratch** — mutable working storage whose contents are never authoritative: no
boundary-consistent fact of the simulation is read from it. Three kinds: a
component's workspace (`ws`, [§7.3][s7-3]); the integrator's buffers and the mid-step
table ([§7.5][s7-5], [§10.4][s10-4]); and the store set a service invocation instantiates from
the activation's layout and discards with the call ([§9.2][s9-2], [§14.8][s14-8]). Not to be
confused with the simulation's own buffer set, which has the same shape and is
the authoritative one — scratch names the role, not the type.

<a id="g-signal-table"></a>**signal table** — the framework-owned collection of cells holding every
produced signal of the flattened model; consumers gather views from it, and
its consistency is a boundary property, transiently integrator scratch within
a step ([§4.1][s4-1], [§10.3][s10-3]).

<a id="g-staging-cell"></a>**staging cell** — the per-device atomic holding place where a device's pending
write batch waits between drains; mutated frame by frame, hence outside the
table's publish-once discipline ([§11.4][s11-4]). Not a table cell ([§4.1][s4-1]).

<a id="g-store"></a>**store** — the typed home of `m` and of a discrete leaf's `s`: isbits or `Symbol` field by field, overwritten by the framework when a
handler or update returns a new value, never arithmetic-touched, snapshot-free
to copy. Never called a cell — root inputs, by contrast, *are* source cells of
the table ([§7.3][s7-3], [§4.1][s4-1], [§11.2][s11-2]).

<a id="g-summing-junction"></a>**summing junction** — an ordinary library component performing N-to-1
aggregation through explicit wires (`SumJunction{W, N}` or a named
site-specific variant); there is no framework aggregation mechanism, and fold
order is the junction's positional input order ([§6.2][s6-2]).

<a id="g-value-level-constructor"></a>**value-level constructor** — the plain public function (component, input
values) → field handle that every field-emitting component is obliged to
provide, its own swept output stage being a one-line call to it; the device by
which [§14.1][s14-1] condition math queries the environment before any sweep exists
([§4.4][s4-4]).

<a id="g-view"></a>**view** — a zero-copy reconstruction of a store handed to a function through
its bundle; it materializes in the caller's frame for the duration of the call
and is value-identical on re-materialization within a sweep ([§7.1][s7-1], [§5.2][s5-2]).

### D.3 Evaluation and scheduling

<a id="g-algebraic-loop"></a>**algebraic loop** — a genuine cycle in the instantaneous dependency graph: a
build error naming the path in canonical slash form, broken by the author with
inserted dynamics, an explicit `UnitDelay` or restructuring ([§5.5][s5-5]). Not to be
confused with an **artificial loop**, port-level acyclic but stage-level
cyclic, whose remedy is a ladder — the two-stage split, contract re-factoring,
and as residual a component split ([§5.4][s5-4]).

<a id="g-flow"></a>**flow / RHS** — `state_derivative`, the continuous derivative function, `f` in
the spec's formulas ([D-220][d-220]). Evaluating the RHS
means running the whole sweep, since `state_derivative` reads the fresh table: there is no
incremental `state_derivative`-only re-evaluation ([§3.1][s3-1], [§5.3][s5-3]).

<a id="g-frame"></a>**frame** — one iteration of the loop — drain, integrate, boundary sequence,
publication — the unit `step!` counts and the trace's ordinal key ([§11.1][s11-1]).
Distinct from a *boundary* ([§D.4][sD-4]), and from the kinematic reference frames of
the aircraft domain, which always appear compounded ("the b frame").

<a id="g-projection"></a>**projection** — the optional per-component hook `x ← state_projection(x)`, run in the
only two schedule positions between a state write and its decode (after
integration, after a handler's `x`-reset); the cheap end of geometric
integration's projection methods ([§2][s2], [§5.3][s5-3]).

<a id="g-schedule"></a>**schedule** — the static evaluation order computed once at build time from
wiring edges plus intra-component feedthrough: all stage-1 functions in any
order, stage 2 in topological order, then `state_derivative`. The hot loop runs a flat list of
`(component, stage)` entries, with zero runtime graph logic ([§5.1][s5-1]).

<a id="g-sweep"></a>**sweep** — one execution of that schedule against the current state, in one of
two statically distinct variants compiled from the same entry list: the
**interior sweep** walks continuous entries only — what RK stage evaluations and
localization guard trial evaluations run, so discrete cells hold ZOH mid-step by
construction — and the **boundary sweep** walks the full list, with the
boundary's due discrete entries gated in by counter modulo. Mid-step sweeps are
integrator scratch; the boundary sweep restores table consistency, and the event
phase re-runs whole boundary sweeps, against that boundary's fixed due set,
until quiescence ([§5.3][s5-3], [§10.3][s10-3], [§10.5][s10-5], [§10.6][s10-6]).

### D.4 Time and events

<a id="g-anchor"></a>**anchor** — the exact `(T, τ)` pair an `Absolute` entry establishes: period
and offset in rational seconds, severing its subtree from the enclosing
scope's grid; anchor 0 is the base grid itself. Anchors join the deployment
constraint pool; relative declarations below one compose against it exactly
as against the root grid ([§10.5][s10-5], [§9.1][s9-1]).

<a id="g-bound-schedule"></a>**bound schedule** — the named printable artifact on the `Simulation`
produced by deployment binding: per discrete component, `(D, Φ, Δt)` with
anchor and provenance columns — the single source of truth for `Δt` and the
substrate of the grid diagnostics and the hyperperiod chart ([§9.2][s9-2], [§10.5][s10-5]).

<a id="g-boundary"></a>**boundary** — a published consistency point: where the [§10.6][s10-6] macro-sequence
completes and a snapshot goes out. Every grid point is a boundary, but `t*`
and boundary zero are boundaries that are not frame tops ([§10.4][s10-4]). *Boundary
zero* ([§14.5][s14-5], [§D.8][sD-8]) is a hyponym — it is an ordinary boundary whose incoming
transitions are authored rather than computed. "Boundary" in the structural
sense — a component's boundary, its boundary declarations, the interface
connections crossing it ([§8.6][s8-6]) — is ordinary English, a distinct
usage, never linked here.

<a id="g-boundary-detected"></a>**boundary-detected** — the detection policy a `Bool`-returning guard declares:
guards are checked for
not-holding → holding edges against their priors at step boundaries only, with
no root-finding and no step rejection, the handler firing at the end of the
step in which the edge was observed. Exact, not approximate, for guards over
`u`/`m` alone — those predicates are piecewise frame-constant ([§10.4][s10-4]).

<a id="g-chattering"></a>**chattering / localization budget** — the bounded per-frame localization
allowance, `localization_budget`, a `Simulation` deployment keyword defaulting
to 8; exhaustion *degrades* rather than throws — localization stops for the
rest of the frame and further crossings fire at the next boundary, under a
`ChatteringBudget` warning naming the event ([§10.4][s10-4]).

<a id="g-dt_base"></a>**`Δt_base`** — the base tick period, an integer multiple `N_base·h` of the
continuous step, bound at `Simulation` construction from one of three
sources: explicit keyword, `N_base·h`, or — fully anchored models only —
derivation from the constraint pool; every discrete component's period is an
integer multiple of it ([§10.5][s10-5], [§9.1][s9-1]).

<a id="g-due"></a>**due** — a discrete component is due at a boundary when its compiled `(D, Φ)`
pair admits that boundary's tick index (`(tick − Φ) % D == 0`); due components'
output stages are gated into the *boundary* sweep (never the interior one) and
their `state_update` calls run after quiescence. The due set is a property of the
boundary, fixed for its whole event iteration: the components whose gate
admits the tick index at a tick frame top, empty at an off-tick frame top and
at `t*`, the `Φ = 0` set at boundary zero ([§10.5][s10-5], [§10.6][s10-6]).

<a id="g-edge-semantics"></a>**edge semantics / holding** — an event fires on a not-holding → holding
transition of its predicate, never on a bare sign change; the opposite
crossing direction is declared as a second event with the negated guard ([§2.1][s2-1],
[§10.6][s10-6]).

<a id="g-firing-budget"></a>**firing budget** — the rule bounding the boundary event iteration: each
declared event fires at most `firing_budget` times per boundary (a
`Simulation` deployment keyword, an integer ≥ 1 defaulting to 4), eligibility
being a not-holding → holding edge on the event's last-observed sample. An
event re-enabled within the boundary therefore fires *at* that boundary;
exhaustion drops its further edges there under a `FiringBudget` warning
([§10.6][s10-6]).

<a id="g-guard"></a>**guard** — the declared function defining an event's predicate, evaluated
against the fresh boundary table and paired with a handler in an ordered,
named `state_events` collection; its detection policy is declared by its return
type — `Bool` boundary-detected, the nominal scalar localized ([§10.4][s10-4],
[§8.2][s8-2]).

<a id="g-harmonic-grid"></a>**harmonic grid** — the rule that every discrete period is an integer multiple
of `Δt_base` — and every anchor period and offset an integer multiple
likewise — itself an integer multiple of `h`, so ticks land only on step
boundaries; grid times are indexed from the frame count, never accumulated
([§10.5][s10-5], [§10.4][s10-4]).

<a id="g-input-epoch"></a>**input epoch** — a maximal span of constant `u`, delimited by the frame-top
drains ([§11.4][s11-4]). Within an epoch a guard changes only through the
trajectory; at a seam it can jump without crossing. Hence the **θ = 0
validation**: the first act of a triggered localization is a trial evaluation at `xₙ`
under the frame's own `u`, whose `σ₀` both supplies the left bracket value and
tells a *trajectory-caused* edge (root-find) from an *epoch-caused* one (no
in-frame crossing exists — discard the localization and let the event fire in
the boundary's ordinary iteration, no budget, no warning) ([§10.4][s10-4]).

<a id="g-interpolant"></a>**interpolant** — the lazily built cubic Hermite continuous extension over the
last completed step, from which localization trial evaluations read the states they sweep;
built only after the θ = 0 validation confirms an in-frame crossing, and
invalidated at `t*`, where the handlers have made it a lie ([§10.4][s10-4]).

<a id="g-localized"></a>**localized** — the detection policy a sign-form guard declares: the crossing
instant is
bracketed by derivative-free root-finding over trial sweeps of interpolated
states, to a bracket narrower than `localization_tol · h` (a deployment
keyword, default `1e-6`). Only the sign form can declare it — the `Bool` form
offers no root to bracket — and it runs
identically paced or unpaced ([§10.7][s10-7], [§10.4][s10-4]).

<a id="g-pacing"></a>**pacing / pacer debt** — the pacer inserts waits between completed frames and
never alters the boundary sequence; a frame exceeding its wall budget leaves
**debt** that later frames repay, with excess forgiven by re-anchor plus
warning ([§10.7][s10-7]).

<a id="g-phase"></a>**phase (`Φ`)** — a schedule's offset against its grid: in scope ticks for
`Relative(K, Φ)`, in rational seconds for `Absolute(q, τ)`, compiled to base
ticks with `0 ≤ Φ < D` by construction; the boundary gate is
`(tick − Φ) % D == 0`, and a phase shifts firing instants, never the period
([§10.5][s10-5]).

<a id="g-predicate"></a>**predicate** — what a guard defines: a `Bool`-valued form, or the sign of a
continuous function with positive = holding (writing the sign value `σ`,
holding = `σ ≥ 0`) ([§2.1][s2-1]). Not to be confused with the *condition*
([§14][s14]), the value that sets a build's state ([§D.8][sD-8]). The device
loop's running check ([§11.6][s11-6], [§12.3][s12-3]) and structural conformance
predicates ([§9.5][s9-5]) are distinct usages, never linked here.

<a id="g-prior"></a>**prior** — the per-event stored sample of its predicate at the previous
boundary's quiescence, always an honest observation and never a manufactured
one; held in loop state and never in a state store; "newly fired"
is defined against it for the boundary's first round (later rounds test the
last-observed sample), and boundary zero establishes every prior as
not-holding ([§10.6][s10-6]).

<a id="g-quiescence"></a>**quiescence** — the fixed point of the boundary event phase: rounds of
[sweep → guards → handlers] iterate until a round fires nothing, after which
the priors are updated and due `state_update` calls run ([§10.6][s10-6]).

<a id="g-remainder-step"></a>**remainder step** — the integration from `t*` to the original grid target
after a localized event, with `h′` derived at use; guards are re-checked on it
under the localization budget ([§10.4][s10-4]).

<a id="g-state-event"></a>**state event** — an event whose instant is unknown in advance and must be
detected, declared as a `StateEvent(guard, handler)` pair under `state_events`;
the criterion is detection versus scheduling, not which fields the guard reads,
so a guard over an input is a state event too. Detected either
boundary-detected or localized ([§2.1][s2-1], [§8.2][s8-2]).

<a id="g-t"></a>**`t*`** — the localized event time: the holding endpoint of the root-finder's
final bracket, structurally strictly later than `tₙ`. A full boundary runs
there, but no ticks are due and no staged inputs are drained ([§10.4][s10-4]).

<a id="g-tick"></a>**tick** — an instant at which a discrete component's stages and update run,
gated by counter modulo against the harmonic grid inside the boundary sweep;
different boundaries therefore run different subsets of the schedule ([§10.5][s10-5]).

<a id="g-tick-index"></a>**tick index** — the count of base ticks, `tick = k ÷ N_base` at the
frame top of frame `k` when `k` is a multiple of `N_base`; the index the boundary
gate reads. An off-tick frame top and a `t*` boundary have none ([§10.5][s10-5]).

<a id="g-tier"></a>**tier** — the continuous or discrete side of the hybrid formalism, read off a
leaf's declaration shape (`DeclarationOnWrongTier` names a violation) ([§8.2][s8-2],
[§8.5][s8-5]). Bare "tier" means only this: the genericity classes are *walked /
pinned / exempt* ([§D.5][sD-5]) and the detection policies *boundary-detected /
localized*.

<a id="g-time-event"></a>**time event** — an event whose instant is known in advance and scheduled: the
discrete tier's ticks, declared by `sample_times` and gated by the harmonic
grid. The counterpart of a *state event*, which must instead be detected
([§2.1][s2-1], [§10.5][s10-5]).

### D.5 Build pipeline

<a id="g-activation"></a>**activation** — a re-run of Stratum C at a given scalar type `T`: cells
re-typed (producer-fed ones by evaluating the producer's output declaration at
`T`, root inputs by evaluating the consuming `input_types` entry at `T`, the
state type by the leaf walk), buffers re-laid-out,
workspace allocators re-invoked, probe chain re-run. Structure and schedule are `T`-independent;
non-nominal activations are lazy, with an opt-in exhaustive set for CI ([§9.4][s9-4]).

<a id="g-always-on-conformance-check"></a>**always-on conformance check** — the probe's comparison left permanently in
place: the key-set and per-field comparison of a stage return against the
type of the cells it writes, decided when the table write's method is
generated over the two types (the names pair; order carries no semantics).
A conformant return type generates the straight stores and no check
instruction ([§9.5][s9-5], [D-235][d-235]).

<a id="g-build"></a>**`Build`** — the artifact `build(world)` produces: wire list, face table with
provenance, schedule and root inputs as plain printable data — the inspectable
contract of the instantiation, and what `attach!`, `stop_on`, replay and
condition resolution all validate against ([§9.2][s9-2]).

<a id="g-chunking"></a>**chunking** — splitting a large phase body's entry tuple into statically
typed chunks behind non-inlined function barriers; the implementation's only
representation freedom, converting compile cost from superlinear in body size
to linear in entry count ([§9.7][s9-7]).

<a id="g-executable-set"></a>**executable set** — the function set an activation can actually run, hence
exactly what it probes: a `Dual` activation sees only the continuous output
stages and `state_derivative` — never the discrete stages, `state_update`, guards or handlers ([§9.4][s9-4]).

<a id="g-executor"></a>**executor** — the compiled execution form of the schedule: a concretely-typed
tuple of entries over statically typed cell storage, traversed by a
compile-time-unrolled walk, with code-selecting facts in type parameters and
plain data in fields ([§9.7][s9-7]).

<a id="g-leaf-walk"></a>**leaf walk** — the framework's derivation of per-activation types from a
declared nominal type: real leaves and `Real` type parameters follow the
activation scalar, everything else pins. It applies on the **state** side alone
(the type derived from `init_x`; `init_m` and `init_s` pin wholesale). **Cells are not
walked**: an output cell comes from evaluating the producer's `output_types` at
the activation scalar ([D-166][d-166]) and a root-input cell from evaluating the
consuming `input_types` entry at it ([D-167][d-167]), participation and tolerance
authored per leaf in both ([§8.2][s8-2]; applied in Stratum C,
[§9.1][s9-1]).

<a id="g-lens"></a>**lens (`Getter`)** — the compiled navigation step of a condition entry: its
tree position tuple lifted to a type parameter, giving type-stable access to
the authored value at apply time ([§14.3][s14-3]).

<a id="g-measurement-seam"></a>**measurement seam / phase bodies** — `phase_bodies(sim)` returns the compiled
bodies of the nominal activation bound over the simulation's own buffers
(`rhs`, `sweep_1`, `sweep_2` — the sweeps in both arities, zero-arg interior
and tick-indexed boundary — `ticks`, plus per-event guards and handlers
and per-component `state_projection`). Its one promise is identity with what the loop
runs, which is what makes the allocation assertions ([§7.5][s7-5]) honest ([§9.7][s9-7]).

<a id="g-nominal"></a>**nominal** — the `Float64` activation, and of a declaration its `Float64`
face (for a continuous producer's output declaration, its evaluation at
`Float64`); the only activation that runs in real time, and the one where the
conformance check demands exact type match ([§8.2][s8-2], [§9.4][s9-4], [§9.5][s9-5]).

<a id="g-probe"></a>**probe** — the build's single evaluation of a user function with real values,
checking shape and type conformance and discarding the result. Every user
function is probed once, at the initial state; probes see only that state's
branch ([§9.3][s9-3]).

<a id="g-probe-value"></a>**probe value / input synthesis** — the fabricated values a build-time probe
runs on. `probe_value(::Type)` synthesizes them at the one kind of terminal
with no producer, root inputs (`zero(T)`/`false`/first enum/`T()`,
overridable); from there they flow the probe chain as the probed stages' own
returns ([§13.1][s13-1]). Strictly probe-scoped: never an initial root-input value,
which [§14.6][s14-6] makes a structural barrier ([§9.3][s9-3]).

<a id="g-probedual"></a>**`ProbeDual`** — the framework's public canonical concrete probe scalar
(`ForwardDiff.Dual{ProbeTag, Float64, 1}`), which keys the CI activation
pinning walked-leaf genericity; its width is arbitrary, since what CI pins is
genericity, not a particular Jacobian ([§9.4][s9-4]).

<a id="g-schema-vs-layout"></a>**schema vs. layout** — the two lookup families the `Build` supplies to
condition resolution: *schema* is the evaluated declarations (may you write
this field, at what leaf type — the authority), *layout* is where it
physically lives (buffer ranges, store and root-input indices) ([§14.3][s14-3]).

<a id="g-stratum"></a>**stratum** — one of the build's three phases: A structure (pure declaration
reading), B schedule (the single evaluation-feeds-structure step), C
activation (everything type-shaped). Strata are barriers — a stratum that
produced any error-severity diagnostic throws before the next begins ([§9.1][s9-1],
[§13.1][s13-1]).

<a id="g-walked"></a>**walked / pinned / exempt** — the eltype-genericity classes: walked
payload/value types follow the activation scalar, pinned parameters and
definitions stay `Float64`, and the discrete side is exempt. Enforced by the
leaf walk on the state side and stated per leaf in a continuous leaf's contract
declarations on the cell side — `output_types` for what a producer's cells
carry, `input_types` for what a consumer's entries tolerate ([§7.2][s7-2], [§8.2][s8-2]).

### D.6 Runtime periphery

<a id="g-bad-datum"></a>**bad datum** — a datum unmappable for environmental reasons (truncated
datagram, malformed JSON, out-of-range field): tolerated *in the loop body* —
catch, stage nothing, `report!(handle, MalformedDatum(cause))`, continue —
while any other exception propagates and becomes `DeviceCrash`. The
classification is the device author's ([§11.6][s11-6]).

<a id="g-batch"></a>**batch** — a device's staged set of face ⇒ value writes, coalesced in its
staging cell and applied whole at the next drain ([§11.4][s11-4]). The word means only
this; error reporting *collects* ([§D.9][sD-9]).

<a id="g-binding"></a>**binding** — the value passed at `attach!` that makes a device
framework-legible: a subtype of `AbstractBinding` declaring its sides by the
Bool traits `is_input`/`is_output` (false by default on the root), with
`is_greedy` switching the input side's claim source from returned to computed
(the unclaimed complement, in place of `claims`). `claims` and `reads` carry
error fallbacks on the root, and attach cross-checks each trait against its
method in both directions (`BindingContractMismatch`); `map_input`/`map_output`
are loop-idiom conventions the framework never calls. Every input-side binding
stakes a claim; `TableBinding` is the shipped
data-driven one ([§11.6][s11-6], [§11.4][s11-4]).

<a id="g-boundary-counter"></a>**boundary counter** — the loop's monotonic count of *published boundaries*,
the fact the wait predicate tests, never reset across trajectories;
incremented after the `latest` release-store, so a waking waiter can never see
a stale snapshot ([§12.3][s12-3]). Distinct from the per-trajectory ordinal a
snapshot carries.

<a id="g-calling-task"></a>**calling task** — the task that invoked `run!`. It runs the loop itself (the
unattended register) unless a `needs_calling_task` device is rostered, in
which case it runs that device's loop body inline and the loop moves to a
spawned task ([§11.1][s11-1]).

<a id="g-claim"></a>**claim** — the set of faces a device *may* write, registered at attach —
either returned by its binding's `claims` or computed as the unclaimed
complement under `is_greedy` — and released at detach; claiming an
already-claimed face is an attach-time error (`ClaimConflict`), and a broad
claim costs GUI liveness ([§11.3][s11-3]).

<a id="g-coalescing"></a>**coalescing** — the CAS merge keeping one pending batch per device:
untouched faces survive, re-staged faces take the newest level (the per-face
ZOH). Its outbound mirror is newest-wins snapshot delivery ([§11.4][s11-4], [§12.3][s12-3]).

<a id="g-control-plane"></a>**control plane** — the separate few-word atomic surface carrying pause,
un-pause, pace, `margin` and stop, consulted at frame top and inside the
loop's wait and pause states; structurally not staging, since a paused loop
drains nothing ([§12.1][s12-1]).

<a id="g-derived-liveness"></a>**derived liveness** — the rule that a GUI widget is live iff its port's feed
chain terminates in a root input inside the GUI's own claim in the run's frozen
surface partition; baked once at run start, with no per-port "GUI-controlled"
marking anywhere ([§11.7][s11-7]).

<a id="g-device"></a>**device** — any attached participant in the periphery: a subtype of
`AbstractDevice` under one authoring
contract (`init!`/`loop`/`shutdown!`, optional `unblock!` and
`needs_calling_task`) and one handle; input-only and output-only are
degenerate uses, and the GUI is an ordinary device ([§11.6][s11-6]).

<a id="g-diagnostic-cell"></a>**diagnostic cell** — the per-writer cell each rostered device, the harness
register and the loop itself own for runtime diagnostics and liveness: a bounded ring (capacity 16)
of diagnostic values plus per-kind suppressed counts — the bound being the
rate limit itself — and an atomic heartbeat timestamp, taken by the loop with
`atomicswap` at the frame-top drain and frozen into the published status
([§11.8][s11-8]).

<a id="g-drain"></a>**drain** — the single point at the top of each frame where the loop takes
each staging cell by `atomicswap` and applies it through the attach-compiled
scatter, in attachment order; never at a `t*` boundary, and under the roster
freeze it performs no checks at all ([§11.1][s11-1], [§11.4][s11-4]). The diagnostic
cells are taken at the same point ([§11.8][s11-8]).

<a id="g-framework-status"></a>**framework status** — the concrete frozen value each snapshot carries beside
the signal table: the pacer diagnostics ([§10.7][s10-7]) plus, per writer, this
boundary's drained diagnostics (`recent`), the counts the ring refused
(`suppressed`), the loop's cumulative per-writer × per-kind counters copied in
(`totals`) and the liveness timestamp ([§11.8][s11-8], [§11.2][s11-2]).

<a id="g-greedy-claim"></a>**greedy claim** — the claim a binding declaring `is_greedy` receives: the
unclaimed complement computed by the framework at attach instead of returned
by `claims`, ordinary in every respect afterwards; an empty remainder is legal
and reported (`EmptyGreedyClaim`), and the shipped GUI binding is the shipped
instance ([§11.3][s11-3], [§11.6][s11-6]).

<a id="g-harness-cell"></a>**harness cell** — the always-present staging cell of the harness register,
written by `stage!(sim, "face" => value, …)` from the calling task itself:
ordinary batches, traced and surface-checked, drained last by convention
([§12.6][s12-6], [§11.3][s11-3]).

<a id="g-harness-register"></a>**harness register** — the framework-owned write path of the calling task —
`stage!(sim, …)` and its cell — and the design's sole *derived* surface: the
unclaimed complement, the faces no rostered device claims, recomputed at every
stopped-sim roster change; a write to a claimed face is `ClaimedFaceEntry`
([§11.3][s11-3], [§12.6][s12-6]).

<a id="g-latest"></a>**`latest`** — the `@atomic` reference a published snapshot is release-stored
into and readers acquire-load; `latest(sim)` hands the calling task the same
immutable value a device handle gets ([§11.2][s11-2]).

<a id="g-next-snapshot-wait"></a>**next-snapshot wait** — `wait_next_snapshot(handle)`: the boundary counter
plus one `Threads.Condition` under the canonical predicate loop
(`counter > last_seen && running`), newest-wins, no queues, no per-frame reset
([§12.3][s12-3]).

<a id="g-operator-interrupt"></a>**operator interrupt** — Ctrl-C in an interactive session, read as a
control-plane stop rather than a failure: delivery is masked across the boundary
macro-sequence (`disable_sigint`) and raised at a frame-top or wait unmask
point, so the run takes the ordinary graceful tail and ends `stopped`. A second
one collapses the device joins; outside the REPL, SIGINT still kills the process
([§12.4][s12-4], [§12.1][s12-1]).

<a id="g-orphaned-claims"></a>**orphaned claims** — the claims of a device whose task died mid-run. Death is
not detach: the roster entry and claims persist to run end, the root inputs hold
their last-drained values, and the GUI renders the fact in the widget's
provenance; recovery is between runs ([§11.3][s11-3]).

<a id="g-peek"></a>**peek** — the GUI display rule: a widget shows its own pending write if any,
else the snapshot value. Own-cell only, which is what makes multi-click
counting and paused editing correct ([§11.7][s11-7]).

<a id="g-periphery"></a>**periphery** — everything outside the loop that exchanges data with it — GUI,
input devices, network I/O, logging — together with the concurrency model
binding them: staged writes inbound, snapshot reads outbound, control on its
own surface ([§11][s11], [§12][s12]).

<a id="g-roster"></a>**roster** — the list of attached device entries (binding, claims, stable
device id, attachment order): a plain immutable value the loop reads once at
`run!`, since `attach!`/`detach!` are stopped-sim operations ([§11.3][s11-3]).

<a id="g-scenario-component"></a>**scenario component** — the home of a sim-time script under the mid-run
mutation doctrine: an ordinary periodic discrete component executed
synchronously in the loop, deterministic paced or unpaced and replayed by
recomputation. The clock is the criterion — wall-clock interactions are
devices ([§12.5][s12-5]).

<a id="g-selector"></a>**selector (read-selector family)** — the closed set of deferred reads
`get_state`/`get_deriv`/`get_output`/`get_input`/`get_face`, each
resolving against a source (table sources — a boundary snapshot or a service
evaluation's scratch tables — vs. live stores) before any client policy
applies ([§14.4][s14-4]).

<a id="g-should_abort"></a>**`should_abort`** — the per-attachment failure policy, an `attach!` keyword
defaulting to `false`: set, a device's departure — loop body returning, crash,
or a failed `init!` — also requests a control-plane stop; clear, the run
continues with the device absent and its claims held to run end. An attachment
fact, never a device property, the same device being advisory in one deployment
and load-bearing in another; the shipped GUI attaches with `true` ([§11.6][s11-6],
[§12.4][s12-4]).

<a id="g-snapshot"></a>**snapshot** — the immutable per-boundary publication: boundary-consistent
signal table (root inputs included), `t`, boundary index and
framework status. It deliberately carries no state stores — the state
trajectory is derived data ([§11.2][s11-2]).

<a id="g-stage-on-interaction"></a>**stage-on-interaction** — the GUI staging contract: value widgets stage the
new level on edit, edge widgets on activation as a level computed from the
peek; held buttons do not re-stage, and no widget stages per render pass
([§11.7][s11-7]).

<a id="g-unattended-run"></a>**unattended run** — a run with empty staging and no snapshot readers: the
same loop, fully synchronous on the calling task, rethrowing after the
shutdown tail so CI fails honestly ([§11.1][s11-1], [§13.4][s13-4]).

<a id="g-write-surface"></a>**write surface** — the set of faces a writer's batch entries may reach: a
device's claim set, whether returned by `claims` or computed under
`is_greedy` ([§11.6][s11-6]), and for the harness register the derived
unclaimed complement. Static per run and enforced entirely at
staging — `OutOfClaimEntry` for a device, `ClaimedFaceEntry` for the harness
([§11.3][s11-3]).

### D.7 Recording and replay

<a id="g-decimation"></a>**decimation** — the log's keep-every-kth retention policy (`log_every`),
admissible on the log alone because it is derived data; every boundary still
runs, publishes to live readers and enters the trace. Bounded by `log_max`, the
maximum number of retained snapshot references (default finite, `Inf` the
opt-out): when the log fills, the effective stride doubles — *progressive
re-decimation*, so coverage stays global at `log_every · 2^k` instead of
collapsing to a rolling window — with the boundary-zero and terminal snapshots
retained unconditionally and outside the bound. A view policy throughout, never
trajectory-determining ([§11.2][s11-2]).

<a id="g-frame-ordinal"></a>**frame ordinal** — the trace's key: replay applies the recording's batches
for frame *k* at frame *k*, exact because the frame sequence is itself
deterministic under replay ([§12.7][s12-7], [§11.1][s11-1]).

<a id="g-input-mode"></a>**input mode** — the `Simulation` register naming where the
[drain](#g-drain) takes its batches from: `:live` from the staging cells,
`:replay` from a recording `replay!` attached. A replaying advance is bounded
by the recording, and the mode returns to `:live` when the recording's last
frame is consumed, or when `live!` drops the remainder by hand
([§12.6][s12-6], [§12.7][s12-7]).

<a id="g-log"></a>**log** — the retained sequence of published snapshots (the same objects, no
copies), with a plain kill switch and `log_every` decimation; derived data,
recomputable from the trace by replay ([§11.2][s11-2]).

<a id="g-recorders"></a>**recorders** — the trace and the log jointly, cleared together at `init!` and
at a trim commit so they restart with the run they record ([§12.6][s12-6], [§14.8][s14-8]).

<a id="g-replay"></a>**replay** — the ordinary loop with exactly two substitutions: boundary zero
from the trace header, and a drain reading the trace by frame ordinal. It
re-records, ends `initialized`, and validates the header — stores, root-input
faces and deployment block — up front, applying the header's `t₀`
([§12.7][s12-7]).

<a id="g-run-metadata"></a>**run metadata** — the trace header's deployment block: `t₀`, `Δt_base`,
`h`, `N_base`, the algorithm identifier, `localization_tol`, `localization_budget`,
`firing_budget` and the
`t_end`/`stop_on` pair bound at
construction ([§11.5][s11-5], [§13.5][s13-5]).

<a id="g-trace"></a>**trace** — the primary record of a session: the sequence of drained,
device-tagged batches per frame, plus its header. On by default, because the
log is recomputable from the trace and never the reverse ([§11.5][s11-5]).

<a id="g-trace-header"></a>**trace header** — the trace's preamble: the resolved initial state
`(x, s, m)`, the initial root-input values, each writer's face-name →
position schema, and the deployment block — captured after `apply!` and the
root-input writes, before the boundary-zero sequence runs ([§11.5][s11-5], [§14.5][s14-5]).

<a id="g-trace-record"></a>**trace record** — the retained form of a drained batch, uniform for every
writer: (position ⇒ value) pairs for the masked (touched) entries, converted at
the drain against the header's schema, so trace size tracks information
rather than surface width and consumers meet one format and one replay path
([§11.5][s11-5], [D-176][d-176]).

<a id="g-what-if-register"></a>**what-if register** — replaying a trace against the same structure with
changed parameters: deterministic re-driving of the recorded inputs through a
modified model, promising determinism but never bit-identical reproduction
([§12.7][s12-7]).

### D.8 Stopped-sim services and the condition algebra

<a id="g-at"></a>**`at` / `Scoped`** — the scoping combinator: `at(prefix, node)` stores a
prefix beside a condition node and applies nothing, path concatenation
happening once at resolution. It also lifts whole `TrimProblem`s and
linearization tap sets ([§14.2][s14-2], [§14.9][s14-9]).

<a id="g-baseline"></a>**baseline** — an aircraft-shipped, full-coverage condition function
(`ready_for_taxi(ac)`, `cold_and_dark(ac)`) layered under tweaks by
`override`, and the `baseline` keyword `init!`/`trim!` take ([§14.6][s14-6]). Not to be
confused with an event *prior* ([§D.4][sD-4]).

<a id="g-boundary-zero"></a>**boundary zero** — the initialization boundary: the ordinary macro-sequence
with an empty integrate — project → [sweep → guards → handlers]\* → due
`state_update` calls → header and first snapshot — run at `t₀` once `apply!` has
established the stores ([§14.5][s14-5]).

<a id="g-capture"></a>**capture** — the service reading the current committed stores *and*
root inputs back as a condition value, returning `(condition, t)`; the gather twin
of `apply!`, and what makes warm restart need no second semantics ([§14.1][s14-1],
[§14.10][s14-10]).

<a id="g-combine"></a>**combine** — the symmetric, collision-intolerant combinator over condition
nodes: a duplicate leaf is an error naming both provenance chains, and blending
a node with a bare `NamedTuple` is a directive error method ([§14.2][s14-2]).

<a id="g-component-test-rig"></a>**component test rig** — a one-child assembly exporting the child's entire
input face set; the idiom for exercising a leaf that needs something wired
beside it, an abstract entry being satisfied *inside* the rig by a concrete
**stub child** wired to that face ([§13.7][s13-7]).

<a id="g-condition"></a>**condition** — the datum that says "set this build to this state": a
path-addressed sparse overlay on the declared defaults, covering `x`, `s` and
`m` fields plus root inputs by face — never outputs, never workspace ([§14.1][s14-1]).
[§14][s14] owns the word; a guard defines a *predicate* ([§D.4][sD-4]).

<a id="g-design_world"></a>**`design_world`** — the shipped thin world (aircraft +
`SimpleAtmosphere(wind = NoWind())` + `HorizontalTerrain`) that mounts an
aircraft for trim and linearization; "aircraft as root" is the shallowest
world, not a special case ([§14.9][s14-9]).

<a id="g-fragment"></a>**fragment** — the leaf node of the condition algebra: `fragment(; x, s, m,
inputs)` payloads speaking only about the component at the authoring point
(**self-vocabulary**), with addressing left entirely to `at` ([§14.2][s14-2]).

<a id="g-fragment-tree"></a>**fragment tree** — the inert, lazy composition of `Fragment`/`Scoped`/
`Combined`/override nodes; isbits but for the prefix strings, which are
references to the author's literals, so rebuilding it per trim iteration
allocates nothing and does no path work ([§14.2][s14-2]).

<a id="g-mounting"></a>**mounting** — relocating a whole problem or tap set with `at(prefix, …)`:
every field is either condition-producing (path-relative, post-composed) or
path-free, so the service never knows where its paths sit ([§14.9][s14-9]).

<a id="g-override"></a>**override** — the ordered, asymmetric layering combinator: on a shared leaf
the patch wins and provenance keeps both sources, while collisions *within* a
layer remain errors; variadic ([§14.6][s14-6]).

<a id="g-root-input-totality"></a>**root-input totality** — the pre-write requirement that an application establishing
a complete world over virgin stores — `init!`, trim setup, trim commit —
cover every root input. Conditions themselves are legitimately partial; a
shortfall is `UninitializedInputs`, collected and declaration-ordered, leaving
the simulation untouched ([§14.6][s14-6]).

<a id="g-service-lifecycle"></a>**service lifecycle** — the `Simulation` states `built` / `initialized` /
`running` / `stopped` / `errored` ([§12.6][s12-6]) and each service's legality against
them; a violation is `ServiceLifecycle`, and `errored` is terminal for all
four services ([§14][s14]).

<a id="g-taps"></a>**taps** — the three selector lists (`x`, `u`, `y`) declaring what
linearization seeds and reports, with an optional component index so a vector
leaf yields named scalars; validated at resolution (`TapResolution`) and
relocatable via `at` ([§14.10][s14-10]).

<a id="g-trimproblem"></a>**`TrimProblem`** — the closed seven-field value
`guess`/`lower`/`upper`/`condition`/`reads`/`residuals`/`tolerances`: an
*implicitly specified* condition, solved as a square root-find over named
residuals and committed as an `init!` of `override(baseline, solution)`
([§14.7][s14-7], [§14.8][s14-8]).

### D.9 Error discipline and diagnostics

<a id="g-carrier-exception"></a>**carrier exception** — the single exception diagnostics travel in when thrown:
`DiagnosticError`, holding one diagnostic at a fail-fast site or the collection
at a stratum barrier, its type parameter telling which; and `StepError` at the
runtime catch site, which takes a single diagnostic over as its `cause` and
carries the cause's type as its parameter. Diagnostics themselves are plain
values ([§13.2][s13-2], [§13.4][s13-4]).

<a id="g-collect-the-checks-fail-the-evaluations-fast"></a>**collect the checks, fail the evaluations fast** — the reporting policy:
declarative passes over collected structure return their full violation list,
while the first user-code exception aborts the phase; strata are barriers, and
the site column spells the collecting case "build (collected)" ([§13.1][s13-1],
[Appendix C][sC]).

<a id="g-did-you-mean"></a>**did-you-mean** — the required shape of any name-shaped failure: the
offending name plus the list-in-hand it should have matched, carried as
payload rather than baked into message text ([§13.2][s13-2]).

<a id="g-error-locality"></a>**error locality** — the property the declaration layer buys: a mistake fails
at the site of the mistake, not later and inside correct code. The five
walkthroughs ([§8.4][s8-4]) are its grounding cases and the acceptance tests
([§8.4][s8-4]).

<a id="g-execution-cursor"></a>**execution cursor** — the plain mutable field recording where in the compiled
schedule execution is (component path, function, boundary phase); one cheap
store per dispatch, so a runtime failure gets its frame without exception
frames in the hot path ([§13.4][s13-4]).

<a id="g-feedthrough-tracer"></a>**feedthrough tracer** — the set-propagation instrument (global value-blind,
or local primal-carrying at sampled states) used to classify a rejected cycle
as real or artificial; diagnostic only, never an input to scheduling ([§5.6][s5-6]).

<a id="g-kind"></a>**kind** — a diagnostic's identity in the closed set enumerated normatively in
[Appendix C][sC], with payload fields, owning section, severity, where it is raised
and under which policy; tests match on kind plus payload, never on message text
([§13.2][s13-2]). Not a component *class*
([§D.1][sD-1]) or a *function family* ([§D.1][sD-1]).

<a id="g-payload"></a>**payload** — the structured data a diagnostic carries beside its kind: paths
and names as strings (never instances or model types), expected/observed port
types, the list-in-hand ([§13.2][s13-2], [Appendix C][sC]); severity is the kind's,
not the payload's.

<a id="g-species"></a>**species** — a `StepError` whose `cause` is a diagnostic, `StepError{Kind}` by
type: what the catch site makes of a single-diagnostic `DiagnosticError` thrown
inside the frame, under the species rule ([§13.4][s13-4], [D-225][d-225]).

<a id="g-stop_on"></a>**`stop_on` / termination is a state** — graceful termination is model state,
never an exception: detection is ordinary event machinery, publication an
ordinary root-exported `Bool` output face, and `stop_on` the deployment policy
naming the faces the loop reads after every published boundary ([§13.5][s13-5]).

<a id="g-termination-record"></a>**termination record** — the stopped-sim
value naming how the run ended: final boundary time, a typed source with its
payload, and the tail residue ([§13.5][s13-5]).

<a id="g-warning-streams"></a>**warning streams** — two, scoped separately: the *build* stream, whose
warning set is deliberately empty, and the *runtime* stream — per-occurrence,
carried by the per-writer diagnostic cells that structurally rate-limit it
([§11.8][s11-8]), surfaced through published
framework status, with its committed inventory listed in [§13.2][s13-2].

### D.10 Meta-vocabulary

<a id="g-blessed"></a>**blessed** — the spec's marker for a practice it explicitly sanctions where a
neighboring one is forbidden: derivation from other declarations ([§8.2][s8-2]), the
one spot where evaluation feeds structure ([§9.1][s9-1]), the workspace-plus-snapshot
idiom for zero-allocation ticks ([§7.3][s7-3]).

<a id="g-row"></a>**decision entry / `D-nnn`** — a numbered entry of `decisions.md`,
cited throughout as a linked `D-nnn` reference: one settled decision with the
alternatives weighed against it. Entry numbers are stable and never reused,
and each entry states its *current* position, a superseded one marked
`superseded → D-nnn` in its Status line rather than rewritten ([§1][s1]).

<a id="g-the-freeze"></a>**the freeze** — the roster freeze: `attach!`/`detach!` are stopped-sim
operations, so the roster, its claims and the run's partition of the root face
set into write surfaces are static, inspectable facts of each run ([§11.3][s11-3],
[D-106][d-106]).

<a id="g-guarded-addition"></a>**guarded addition** — a capability the design admits but does not build,
weighed against Flight.jl's fundamental strengths and recorded with its shape
so adoption stays additive ([§1][s1]; e.g. field-addressed staging,
[§4.3][s4-3]; mid-run reader attach, [§11.3][s11-3]).

<a id="g-normative"></a>**normative / index, not a second home** — the spec is the normative statement
of the design, and its appendices are indices: each recall line's normative
statement stays in the owning section ([Appendix A][sA], and the same rule for
Appendices B, C and D). The design directory's walkthrough explainers are
non-normative companions by their own preambles.

<a id="g-recorded-not-built"></a>**recorded, not built** — the disposition of a worked-out extension
deliberately left unimplemented, with its seams named so adoption is additive
(the closed-loop trim, [§14.7][s14-7]; the sampled-data `Dual` activation and
declarative non-participation, [§14.10][s14-10]).

<a id="g-register"></a>**register** — the spec's word for a mode or idiom in which something is done,
always compounded: the didactic register ([§13.2][s13-2]), the inspection and
integration registers ([§11.2][s11-2]), the by-allocation register ([§8.2][s8-2]), the
harness, unattended and what-if registers ([§12.6][s12-6], [§12.7][s12-7]). Reserved for this
sense — the recording artifacts are the *recorders* ([§D.7][sD-7]).

<a id="g-seam"></a>**seam** — a narrow, named interface kept deliberately thin so what sits
behind it can be replaced or measured: the stepper seam ([§10.2][s10-2]), the backend
seam ([§14.8][s14-8]), the measurement seam ([§9.7][s9-7]), the phase-body seams of the
compiled executor ([§9.7][s9-7]).

<a id="g-torture-test"></a>**torture test** — an existing, maximally awkward artifact transliterated
against a proposed mechanism to validate it before adoption: `PistonEngine`
and the FCS cascade against [§5.2][s5-2] ([§15.2][s15-2]), filter/joystick/GUI against the
[§11][s11] staging shapes ([§15.3][s15-3]), the strapdown IMU against the leaf split ([§15.5][s15-5]); the
standard component library is the standing ergonomics one ([§13.7][s13-7]).

<a id="g-worked"></a>**worked (example)** — a full spelling of a mechanism against a real artifact,
carried in the spec rather than left to the reader: the worked assembly of
[§8.6][s8-6], the worked C172 cruise problem of [§14.7][s14-7], and the IMU
([§15.5][s15-5]) as the boundary-sampling example [Appendix A][sA] points at.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-001]: decisions.md#d-001--hybrid-causal-formalism-with-two-tier-events-and-projection
[d-004]: decisions.md#d-004--immutable-value-signals-in-a-typed-signal-table
[d-005]: decisions.md#d-005--reject-algebraic-loops-at-build
[d-006]: decisions.md#d-006--two-stage-structural-feedthrough-via-h_xh_xu
[d-007]: decisions.md#d-007--aggregation-mechanism
[d-008]: decisions.md#d-008--function-valued-environment-signals-with-the-handle-pattern
[d-011]: decisions.md#d-011--eltype-genericity-on-the-continuous-path
[d-012]: decisions.md#d-012--set-propagation-tracers-and-scc-based-cycle-diagnostics
[d-013]: decisions.md#d-013--immutable-discrete-state-via-cells-workspace-and-snapshot
[d-015]: decisions.md#d-015--fused-evaluation-of-derivatives-and-outputs
[d-016]: decisions.md#d-016--uniform-component-interfaces-via-h_x-and-per-event-re-decode
[d-017]: decisions.md#d-017--framework-owned-simulation-loop-with-a-stepper-seam
[d-018]: decisions.md#d-018--tier-2-event-localization-via-dense-output-and-bracketed-root-finding
[d-019]: decisions.md#d-019--harmonic-tick-grid-with-virtual-assemblies-and-rate-scopes
[d-020]: decisions.md#d-020--boundary-event-phase-iterates-to-quiescence
[d-021]: decisions.md#d-021--pacer-piecewise-affine-wall-clock-mapping-with-bounded-debt
[d-022]: decisions.md#d-022--periphery-architecture-no-shared-mutable-model
[d-023]: decisions.md#d-023--snapshot-publication-via-atomic-acquire-release
[d-024]: decisions.md#d-024--inbound-staging-per-device-atomic-batch-cells
[d-025]: decisions.md#d-025--one-uniform-device-kind
[d-026]: decisions.md#d-026--gui-write-path-panels-name-their-own-ports
[d-027]: decisions.md#d-027--pacer-coarse-phase-uses-task-yielding-sleep
[d-028]: decisions.md#d-028--next-snapshot-wait-via-monotonic-counter-and-condition-variable
[d-029]: decisions.md#d-029--input-trace-on-by-default
[d-031]: decisions.md#d-031--mid-run-mutation-doctrine-staging-and-control-commands-only
[d-032]: decisions.md#d-032--component-declaration-trait-layer-with-probe-checked-schema-authority
[d-033]: decisions.md#d-033--declaration-inventory-by-value-by-type-by-allocation-registers
[d-034]: decisions.md#d-034--contract-visibility-declared-fields-are-public
[d-035]: decisions.md#d-035--stores-and-views-components-read-zero-copy-view-bundles
[d-036]: decisions.md#d-036--table-mechanics-stage-returns-are-namedtuples-of-port-values
[d-037]: decisions.md#d-037--aggregation-by-explicit-summing-junctions
[d-038]: decisions.md#d-038--snapshot-and-log-derived-trajectory-primary-trace-header
[d-039]: decisions.md#d-039--assembly-declaration-is-type-based
[d-040]: decisions.md#d-040--slash-string-paths-as-the-canonical-path-form
[d-041]: decisions.md#d-041--dedicated-exports-for-assembly-faces
[d-042]: decisions.md#d-042--rates-declaration-on-immediate-children-only
[d-043]: decisions.md#d-043--computed-exports-via-ordinary-code-and-faces
[d-044]: decisions.md#d-044--slot-exclusivity-and-the-write-surface-rule
[d-045]: decisions.md#d-045--periphery-input-semantics-derived-liveness-conditioning-mappings-edge-logic
[d-046]: decisions.md#d-046--face-names-are-opaque-string-tokens-slash-is-reserved-for-structure
[d-047]: decisions.md#d-047--stage-widgets-on-interaction-events-not-every-pass
[d-049]: decisions.md#d-049--standalone-buildworld-artifact-wrapped-by-simulation
[d-051]: decisions.md#d-051--synthesize-probe-inputs-via-a-probe_valuetype-fallback-chain
[d-052]: decisions.md#d-052--scope-dual-probing-to-each-activations-executable-set
[d-053]: decisions.md#d-053--bake-one-always-on-conformance-check-at-every-table-write
[d-054]: decisions.md#d-054--producers-determine-activation-types-consumers-stay-generic
[d-055]: decisions.md#d-055--require-strict-local_types-declaration-for-cross-stage-cells
[d-056]: decisions.md#d-056--uphold-the-two-kind-taxonomy-against-the-integrate-and-dump-challenge
[d-057]: decisions.md#d-057--batch-declarative-check-violations-abort-on-first-user-code-exception
[d-058]: decisions.md#d-058--diagnostics-as-structured-values-under-one-builderror-carrier
[d-059]: decisions.md#d-059--catch-runtime-failures-at-one-boundary-site-into-steperror
[d-060]: decisions.md#d-060--graceful-termination-is-model-state-never-an-exception
[d-063]: decisions.md#d-063--conditions-are-path-addressed-sparse-overlays-on-init_-defaults
[d-064]: decisions.md#d-064--compose-per-component-init-by-pull-via-fragment-functions
[d-065]: decisions.md#d-065--fragments-form-a-lazy-inert-tree-resolved-against-the-build
[d-067]: decisions.md#d-067--boundary-zero-runs-the-macro-sequence-with-an-empty-integrate
[d-068]: decisions.md#d-068--enforce-slot-totality-at-the-initcommit-service-boundary
[d-069]: decisions.md#d-069--trim-problem-spelling-namedtuples-residual-vector-exact-ad-jacobians
[d-070]: decisions.md#d-070--trim-service-in-house-dense-lm-behind-a-swappable-backend
[d-073]: decisions.md#d-073--companion-sketches-carry-the-settled-condition-algebra-design
[d-074]: decisions.md#d-074--hand-off-component-function-arguments-as-one-named-bundle
[d-075]: decisions.md#d-075--name-flowupdateoutput-stages-by-letter-and-dependence-class
[d-077]: decisions.md#d-077--allocate-workspace-via-a-per-activation-workspace-method
[d-079]: decisions.md#d-079--type-declarations-concretely-resolved-by-an-activation-leaf-walk
[d-080]: decisions.md#d-080--keep-tier-2-event-detection-pace-independent
[d-083]: decisions.md#d-083--bind-output-device-reads-to-snapshot-paths-not-just-faces
[d-084]: decisions.md#d-084--drop-the-unconnected-output-warning
[d-086]: decisions.md#d-086--compile-the-executors-schedule-into-unrolled-statically-typed-entries
[d-089]: decisions.md#d-089--route-supervisor-gains-and-resets-through-ordinary-ports
[d-090]: decisions.md#d-090--return-handler-updates-as-bundle-law-namedtuples
[d-091]: decisions.md#d-091--override-t_endstop_on-per-run-at-run
[d-093]: decisions.md#d-093--spawn-device-tasks-per-run-not-per-attach
[d-094]: decisions.md#d-094--close-the-state-leaf-vocabulary-to-plain-scalars-and-sarrays
[d-100]: decisions.md#d-100--freeze-u-at-round-start-for-within-round-event-visibility
[d-101]: decisions.md#d-101--implement-replay-as-the-ordinary-loop-with-two-substitutions
[d-102]: decisions.md#d-102--author-owned-device-loop-inside-a-framework-owned-bracket
[d-104]: decisions.md#d-104--coalesce-staged-writes-by-cas-merge-with-per-attachment-positional-shape
[d-105]: decisions.md#d-105--split-device-side-bad-datum-handling-into-tolerated-garbage-and-propagated-crashes
[d-106]: decisions.md#d-106--freeze-the-device-roster-for-the-duration-of-a-run
[d-108]: decisions.md#d-108--gate-stopped-sim-services-by-input-derived-lifecycle-preconditions
[d-116]: decisions.md#d-116--expose-phase_bodiessim-as-the-zero-allocation-invariants-measurement-seam
[d-117]: decisions.md#d-117--extend-declarations-and-stages-via-explicit-per-name-import
[d-122]: decisions.md#d-122--resolve-de-polysemy-by-giving-each-overloaded-term-one-owner
[d-130]: decisions.md#d-130--scope-resolves-generic-boundary-duty-by-register-structuralload-bearingdiagnostic
[d-133]: decisions.md#d-133--split-spec-invoked-numeric-constants-into-deployment-parameters-vs-owning-section-defaults
[d-136]: decisions.md#d-136--unify-diagnostics-and-liveness-heartbeat-into-one-per-writer-diagnostic-cell
[d-137]: decisions.md#d-137--bound-snapshot-log-retention-by-count-with-amortized-doubling-stride
[d-139]: decisions.md#d-139--give-environment-field-handles-a-value-level-constructor-to-prevent-drift
[d-141]: decisions.md#d-141--continuous-state-resets-are-events-owned-by-the-reimplemented-pivector
[d-142]: decisions.md#d-142--stage-code-must-be-total-over-type-valid-inputs
[d-144]: decisions.md#d-144--rename-the-computed-exports-helper-faces-to-passthrough
[d-145]: decisions.md#d-145--deduplicate-pass-through-except-lists-with-a-shared-feed-list-idiom
[d-146]: decisions.md#d-146--rename-facesselectors-to-claimsreads-on-the-binding-interface
[d-147]: decisions.md#d-147--split-the-sweep-into-static-interior-and-boundary-variants
[d-150]: decisions.md#d-150--make-the-service-the-sole-authority-on-convergence
[d-152]: decisions.md#d-152--join-auto-publication-to-the-per-event-re-decode-at-stage-1
[d-154]: decisions.md#d-154--remove-per-event-re-decode-serialize-same-component-events
[d-157]: decisions.md#d-157--check-for-nonfinite-x-immediately-after-integrate
[d-158]: decisions.md#d-158--pin-the-backend-seam-to-one-required-solve-signature
[d-162]: decisions.md#d-162--adopt-per-eltype-homogeneous-cell-stores-over-per-instance
[d-164]: decisions.md#d-164--reject-components-that-declare-nothing-and-define-no-stage
[d-166]: decisions.md#d-166--mandate-typet-output-signatures-on-continuous-producers
[d-167]: decisions.md#d-167--mandate-typet-input-signatures-under-the-permissive-reading
[d-168]: decisions.md#d-168--root-slot-fan-out-tolerance-combines-by-meet-not-agreement
[d-169]: decisions.md#d-169--y_xy_z-carry-stage-1-ports-only-auto-published-excluded
[d-170]: decisions.md#d-170--split-assembly-connections-into-childinputoutput-declarations
[d-171]: decisions.md#d-171--rename-passthrough-to-input_passthrough
[d-173]: decisions.md#d-173--fuse-the-discrete-state-letter-z-into-x
[d-176]: decisions.md#d-176--unify-trace-retention-on-one-sparse-record-format
[d-177]: decisions.md#d-177--re-found-the-periphery-on-mandatory-roots-plus-declared-traits
[d-179]: decisions.md#d-179--derive-detection-policy-from-the-guards-return-type
[d-181]: decisions.md#d-181--replace-once-per-boundary-firing-with-budgeted-re-firing
[d-183]: decisions.md#d-183--retire-workspace-poisoning
[d-184]: decisions.md#d-184--fold-group-into-the-spec-as-an-ordinary-library-component
[d-185]: decisions.md#d-185--adopt-the-phased-two-register-sample-time-declaration
[d-186]: decisions.md#d-186--legalize-absolute-declarations-in-any-scope-via-anchors
[d-187]: decisions.md#d-187--make-the-bound-schedule-a-named-artifact-with-exact-grid-diagnostics
[d-190]: decisions.md#d-190--reject-a-separate-derivative_type-declaration
[d-191]: decisions.md#d-191--defer-not-consume-the-edge-on-a-blocked-event
[d-192]: decisions.md#d-192--let-the-greedy-claim-empty-the-harness-remainder
[d-193]: decisions.md#d-193--keep-per-writer-liveness-on-one-timestamp-plus-task-state
[d-194]: decisions.md#d-194--retire-the-w-channel-intermediates-are-declared-ports
[d-195]: decisions.md#d-195--give-the-discrete-state-its-own-letter-s
[d-197]: decisions.md#d-197--reject-discrete-stores-in-linearizations-x-tap-list
[d-198]: decisions.md#d-198--promote-the-shutdown-join-timeout-to-a-deployment-keyword
[d-199]: decisions.md#d-199--the-reads-enumeration-returns-a-labeled-namedtuple-of-selectors
[d-200]: decisions.md#d-200--the-harness-register-is-a-diagnostic-writer-with-its-own-cell
[d-201]: decisions.md#d-201--the-terminal-account-closes-at-the-final-frame-top
[d-202]: decisions.md#d-202--stage-batches-as-values-plus-touched-mask-never-union-tuples
[d-203]: decisions.md#d-203--the-termination-record-carries-typed-sources-and-the-tail-residue
[d-204]: decisions.md#d-204--rename-the-condition-algebras-symmetric-combinator-to-combine
[d-205]: decisions.md#d-205--boundary-zero-publishes-every-discrete-output-stage-due-or-not
[d-207]: decisions.md#d-207--route-every-connection-one-level-faces-are-the-only-cross-boundary-currency
[d-208]: decisions.md#d-208--root-inputs-are-the-root-components-input-faces-whatever-its-class
[d-209]: decisions.md#d-209--build-output_passthrough
[d-210]: decisions.md#d-210--tighten-the-input-boundary-class-uniform-face-uniqueness-and-no-empty-routing
[d-211]: decisions.md#d-211--let-a-component-declare-one-container-name-transparent
[d-212]: decisions.md#d-212--refuse-the-transparent-bare-key-that-shadows-a-sibling-container-field
[d-213]: decisions.md#d-213--establish-a-services-frozen-cells-from-the-authored-discrete-state
[d-217]: decisions.md#d-217--conform-the-trace-and-replay-sections-to-the-prototypes-record
[d-218]: decisions.md#d-218--make-the-replaylive-distinction-an-explicit-input-mode
[d-219]: decisions.md#d-219--add-a-time-addressed-replay-halt-and-a-manual-door-to-live
[d-220]: decisions.md#d-220--rename-the-authoring-family-to-words-stage-update-projection-event-and-workspace-declarations
[d-221]: decisions.md#d-221--unwrap-a-single-diagnostic-carrier-at-the-runtime-catch-site-into-a-steperror-species
[d-222]: decisions.md#d-222--replace-builderror-with-the-policy-parametric-diagnosticerror-carrier
[d-223]: decisions.md#d-223--host-the-runtime-catch-in-boundary-zero-under-the-services-disposition
[d-224]: decisions.md#d-224--let-a-throw-inside-a-trim-commit-propagate-as-the-commits-steperror
[d-225]: decisions.md#d-225--parametrize-steperror-on-its-causes-type
[d-226]: decisions.md#d-226--reach-the-public-surface-by-qualified-name-until-16s-export-audit
[d-227]: decisions.md#d-227--select-the-stepper-by-type-under-the-algorithm-keyword
[d-228]: decisions.md#d-228--attribute-runtime-diagnostics-by-cell-never-by-payload
[d-229]: decisions.md#d-229--collect-to-the-stratum-barrier-under-a-dependency-rule
[d-230]: decisions.md#d-230--stamp-the-snapshot-with-the-trajectorys-boundary-ordinal-not-the-wait-counter
[d-231]: decisions.md#d-231--require-isbits-store-values-checked-at-build
[d-232]: decisions.md#d-232--refuse-the-roster-operations-on-an-errored-simulation
[d-233]: decisions.md#d-233--retire-the-termination-records-absent-time-arm
[d-235]: decisions.md#d-235--realize-the-always-on-check-at-the-generated-write-against-the-cell-type
[d-236]: decisions.md#d-236--type-check-a-wire-by-one-relation-with-embedding-in-stratum-a
[d-237]: decisions.md#d-237--classify-a-non-isbits-immutable-port-type-as-one-opaque-leaf
[d-238]: decisions.md#d-238--decide-embed-accept-on-the-type-lift-the-arrival-compare-exactly
[d-239]: decisions.md#d-239--report-a-typod-return-field-alone-without-the-unproduced-port
[d-240]: decisions.md#d-240--read-the-heartbeat-at-publication-beside-the-task-state
[d-241]: decisions.md#d-241--keep-the-status-a-vector-of-records-one-small-allocation-per-publication
[s1]: #1-purpose-and-method
[s10]: #10-time-and-execution
[s10-1]: #101-loop-ownership-the-framework-owns-the-simulation-loop
[s10-2]: #102-the-stepper-seam
[s10-3]: #103-signal-table-consistency-is-a-boundary-property
[s10-4]: #104-localization-mechanics
[s10-5]: #105-multi-rate-tick-scheduling
[s10-6]: #106-event-iteration-at-boundaries-to-quiescence-budgeted
[s10-7]: #107-real-time-pacing
[s11]: #11-runtime-periphery-the-data-plane
[s11-1]: #111-no-shared-mutable-model-staged-writes-snapshot-reads
[s11-2]: #112-outbound-snapshot-publication
[s11-3]: #113-inbound-root-inputs-claims-and-the-frozen-roster
[s11-4]: #114-inbound-per-device-staging-representation-and-the-drain
[s11-5]: #115-inbound-the-input-trace
[s11-6]: #116-devices-one-authoring-contract-no-taxonomy
[s11-7]: #117-the-gui-write-path-port-resolution-peek-staging-contract
[s11-8]: #118-diagnostics-and-liveness-the-per-writer-cell
[s12]: #12-runtime-periphery-lifecycle-and-orchestration
[s12-1]: #121-control-plane
[s12-2]: #122-loop-scheduling-wait-primitive-yields-thread-budget
[s12-3]: #123-the-next-snapshot-wait
[s12-4]: #124-shutdown-protocol
[s12-5]: #125-scripts-and-the-mid-run-mutation-doctrine
[s12-6]: #126-run-lifecycle-and-partial-advance
[s12-7]: #127-replay-the-trace-re-drives-the-ordinary-loop
[s13]: #13-error-discipline
[s13-1]: #131-reporting-policy-collect-the-checks-fail-the-evaluations-fast
[s13-2]: #132-diagnostics-structured-values-one-carrier-exception
[s13-3]: #133-build-primitives-resolve-and-the-face-list-accessors
[s13-4]: #134-runtime-failures-one-catch-site-an-execution-cursor
[s13-5]: #135-termination-is-a-state-not-an-exception
[s13-6]: #136-abnormal-shutdown-one-tail-two-entries
[s13-7]: #137-tooling-consequences-provenance-and-the-component-library
[s14]: #14-stopped-sim-services
[s14-1]: #141-conditions-are-path-addressed-overlays-on-the-declared-defaults
[s14-10]: #1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s14-2]: #142-fragment-composition-locality-without-schema
[s14-3]: #143-resolution-flatten-validate-compile-once
[s14-4]: #144-two-application-registers-over-one-plan
[s14-5]: #145-boundary-zero-an-ordinary-boundary-with-authored-incoming-transitions
[s14-6]: #146-root-input-totality-the-missing-value-error-and-the-override-combinator
[s14-7]: #147-the-trim-problem-namedtuple-decisions-declared-reads-named-residuals
[s14-8]: #148-the-trim-service-solver-seam-scratch-stores-commit-and-report
[s14-9]: #149-mounting-problems-as-relocatable-values
[s15]: #15-case-studies
[s15-1]: #151-vehicle-today--this-framework
[s15-2]: #152-torture-tests-for-the-52-interfaces-pistonengine-and-the-fcs-pid-cascade
[s15-3]: #153-torture-test-for-the-11-staging-shapes-filter-joystick-and-gui
[s15-4]: #154-the-interactive-c172x-demo-the-periphery-under-load
[s15-5]: #155-the-strapdown-imu-integrate-and-dump-across-the-tier-boundary
[s16]: #16-open-axes
[s2]: #2-formalism
[s2-1]: #21-events-two-detection-policies
[s2-2]: #22-exclusions-deliberate
[s3]: #3-component-taxonomy
[s3-1]: #31-continuous-component-the-hybrid-primitive
[s3-2]: #32-periodic-discrete-component
[s3-3]: #33-assembly
[s4]: #4-ports-and-signals
[s4-1]: #41-immutable-value-semantics
[s4-2]: #42-consumers-see-ports-not-stages
[s4-3]: #43-table-mechanics-and-port-granularity
[s4-4]: #44-function-valued-signals-environment-access
[s5]: #5-evaluation-order-and-feedthrough
[s5-1]: #51-the-scheduling-problem
[s5-2]: #52-two-stage-outputs-signatures-bundles-and-the-hand-off-laws
[s5-3]: #53-structural-feedthrough-stage-roles-schedule-and-step-boundaries
[s5-4]: #54-artificial-loops-and-the-escape-hatch
[s5-5]: #55-algebraic-loop-policy-reject-at-build-time
[s5-6]: #56-diagnostics-feedthrough-tracing
[s6]: #6-composition-connections-aggregation-and-hierarchy
[s6-1]: #61-connections-and-hierarchy
[s6-2]: #62-aggregation-explicit-summing-junctions
[s7]: #7-state-and-data-representation
[s7-1]: #71-continuous-state-structured-immutable-flat-backing
[s7-2]: #72-numeric-genericity-eltype
[s7-3]: #73-discrete-state-modes-and-workspace
[s7-4]: #74-the-fused-evaluation-lineage-prior-art-and-how-we-got-here
[s7-5]: #75-allocation-policy-a-scoped-invariant
[s8]: #8-the-declaration-layer-components-and-assemblies
[s8-1]: #81-position-a-declarative-trait-layer-in-plain-julia-no-macros
[s8-2]: #82-the-declaration-inventory
[s8-3]: #83-visibility-the-contract-is-the-interface
[s8-4]: #84-failure-walkthroughs-the-error-locality-grounding
[s8-5]: #85-assembly-declaration-type-based-class-by-declaration-shape
[s8-6]: #86-paths-wiring-and-faces
[s8-7]: #87-rate-scopes
[s8-8]: #88-computed-connections-and-generic-holding
[s9]: #9-the-build-pipeline
[s9-1]: #91-three-strata
[s9-2]: #92-the-build-artifact
[s9-3]: #93-probing-and-input-synthesis
[s9-4]: #94-activations-executable-sets-laziness-caching
[s9-5]: #95-the-always-on-conformance-check
[s9-6]: #96-stopped-sim-services-as-stratum-c-clients
[s9-7]: #97-the-compiled-executor
[sA]: #appendix-a-taught-contracts-the-author-facing-index
[sB]: #appendix-b-api-synopsis-the-entry-points
[sC]: #appendix-c-the-diagnostic-kind-set
[sD]: #appendix-d-glossary
[sD-1]: #d1-component-model-and-declaration-layer
[sD-4]: #d4-time-and-events
[sD-5]: #d5-build-pipeline
[sD-6]: #d6-runtime-periphery
[sD-7]: #d7-recording-and-replay
[sD-8]: #d8-stopped-sim-services-and-the-condition-algebra
[sD-9]: #d9-error-discipline-and-diagnostics
