## 9. The build pipeline

The build consumes a root [component](#g-component) instance and produces the runnable
artifact: resolved wires, typed [signal table](#g-signal-table), [execution order](#g-execution-order),
absolute rate divisors, flat state layout, [root inputs](#g-root-input). [§8][s8] states what is
declared and what must hold. This chapter states *when* each fact is checked,
against what, and with which failure. The [§8.4][s8-4] walkthroughs plus the error
rules ([§6.1][s6-1]) are its acceptance tests. Error-*reporting* policy is settled in
[§13.1][s13-1]. Declarative checking passes collect, user-code evaluation fails fast,
and the build's steps are barriers, so the only partial results carried past
failures are violation lists from pure checks.

### 9.1 The build's three steps

Three ordering constraints are forced by settled decisions. [Face](#g-face) derivation
is **bottom-up**, because an [assembly](#g-assembly)'s interface connections evaluate
against child [contracts](#g-contract) ([§8.8][s8-8]). The unconnected-input obligation check
and cross-level two-producers detection are **global**, decidable only at the
root, after every assembly's wires and faces are in hand ([§6.1][s6-1]). And stage
membership is **derived by probing** the stage-1 functions ([§8.2][s8-2]), so
evaluation interleaves with graph construction at exactly one [blessed](#g-blessed) spot.
The pipeline is therefore inherently heterogeneous. It runs as the steps
below, each consuming one artifact and producing the next, and each a
barrier ([§13.1][s13-1]): a step that produced any error throws before the
next begins.

| step | consumes | produces | user code it runs |
|---|---|---|---|
| the structure step | the root instance | [`Structure`](#g-structure) | declaration bodies only |
| the nominal evaluation | `Structure` | [`Outputs`](#g-outputs), [`Events`](#g-events), the nominal `Float64` [activation](#g-activation) | the stage functions, guards and handlers, at `Float64` |
| activation at `T` | `Structure`, `Outputs`, the nominal activation, a scalar `T` | `Activation{T}` | the continuous tier's functions at `T` |
| deployment | the `Build`, the grid parameters | [`Deployment`](#g-deployment) with its [`Schedule`](#g-schedule) | none |
| materialization | the `Deployment`, a scalar `T` | `Simulation{T}` | none |

The first three are the build, and `build(world)` runs them; the
[`Build`](#g-build) bundles their products ([§9.2][s9-2]). The last two are
the `Deployment` constructor below and the `Simulation` constructor
([§9.2][s9-2]).

#### The structure step

The structure step is pure declaration reading. No user stage code executes in
it. The `u_connections`/`y_connections`/`input_passthrough` bodies are
declaration code ([§8.8][s8-8]).

The step is a tree walk from the root instance, in this order:

1. [Components](#g-component) are collected by path.
2. Each component's [class](#g-class) (its primitive-vs-assembly status) is read off
   declaration shape ([§8.5][s8-5]).
3. Leaf contracts are collected: `u_types`, `y_types`, `init_*`
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
- the store form ([§8.2][s8-2]): every `x_init`, `s_init` and `m_init` value is
  a `NamedTuple`. It is checked before the classifier and the vocabulary
  checks read the value, and a primitive failing it is read no further in
  this step;
- the closed leaf vocabulary ([§7.1][s7-1]), checked on every `x_init` because
  the walk in [§8.2][s8-2] rests on it. `s_init` pins wholesale and answers to the
  isbits rule of [§7.3][s7-3] instead, checked with `m_init` field by field.

[Root inputs](#g-root-input) fall out here too, as the root component's input faces
([§8.2][s8-2]).

**The bound check** is the first type clause, and it applies at nominal faces.
The producer's declaration at `Float64` must be `<:` the entry at `Float64`.
Equality is the concrete degenerate case. Abstract-at-root is detected here.

**The walk-compatibility clause** is the second, and it applies to continuous
consumers only. It is decided by retyping both declarations at a marker
scalar and comparing per leaf, and its diagnostic is
`WalkingFaceAtFrozenEntry`. It stays inside this step's charter because
both sides are plain declarations the walk retypes. Declarations are read, and
no user stage code runs.

The step also checks the declaration-completeness rules ([§8.2][s8-2]): a store
without its update, a leaf declaring no store, an event missing a [guard](#g-guard)
or handler method, a leaf mixing [tier](#g-tier) families, and a stateless leaf
with no output contract.

`sample_times` validation is the structure step's too, and it has two parts. The
first is per-entry validity against the constraints of [§10.5][s10-5]: wrapper-typed
values, `K ≥ 1`, `0 ≤ Φ < K`, `T > 0`, `0 ≤ τ < T`, and keys naming discrete or scope
children. Those violations are collected with path attribution. The second is
compilation into **`(anchor, m, c)` triples**. A triple carries a discrete component's
divisor and [phase](#g-phase) in the [tick](#g-tick) units of its [anchor](#g-anchor), the exact `(T, τ)` pair an
`Absolute` entry establishes.

The compilation is a fold down the tree, one rule per case:

| the fold meets | the triple it produces |
|---|---|
| the root scope | `(A₀, 1, 0)`, anchor 0 being the base grid itself: `(T, τ) = (Δt_base, 0)` |
| `Relative(K, φ)` under a scope at `(a, mₛ, cₛ)` | `(a, K·mₛ, cₛ + φ·mₛ)` |
| `Absolute(q, τ)` under any scope | **severs and re-seeds**: a fresh anchor `Aₖ = (period(q), τ)`, its subtree continuing at `(Aₖ, 1, 0)` |

Anchor 0 is symbolic until deployment. The `Relative` case is the affine law
([§10.5][s10-5]) in anchor-tick units. The canonical residue (`c < m`) holds
within each anchor's subtree by the same induction.

Everything except binding `Δt_base`, which is deployment's, happens in the
structure step. Final divisors for anchored entries genuinely cannot exist until
`Δt_base` binds.

**The structure step returns [`Structure`](#g-structure)** (the artifact holding
everything the instance alone fixes), and that is its whole product
([D-253][d-253]).
`Structure` carries the component instances by path, the [tier](#g-tier) each
one sits on, the resolved wires, the two-sided face table with each face's
routing chain, the [root inputs](#g-root-input), per component its rate chain
of `Relative`/`Absolute` links, and, for each assembly an explicit
`sample_times` key names, the scope triple that key gives it. Class and
contracts are read off the instance on demand. Nothing in it depends on a
scalar type.

#### The nominal evaluation

**The nominal evaluation is a function of the `Structure`**, and it returns three
artifacts, [`Outputs`](#g-outputs), [`Events`](#g-events) and the nominal `Float64` [activation](#g-activation) ([D-253][d-253], [D-259][d-259]).
It is the single evaluation-feeds-structure step. `Outputs` (the artifact holding
the port classification and the order over it) carries per component the stage-1
and stage-2 output names, and the [execution order](#g-execution-order) over the
components. The [feedthrough](#g-feedthrough) graph the order is computed over is
not carried. It is derived from the `Structure`'s connections and the producers'
stage-2 names wherever it is shown ([D-261][d-261]). `Events` (the artifact
holding the event tables) carries per component the event names, their detection
policies and the bundle names. It computes them in this order:

- [Workspace](#g-workspace) (component-declared mutable scratch arriving as the `ws` bundle
  field) is allocated at the probing scalar. That is sound this early because
  the allocator reads only the instance and the scalar ([D-077][d-077]), so there
  is no layout dependence.
- Stage-1 [probes](#g-probe) run at `Float64`, on `x_init`/`s_init`/`m_init` values.
  They are well-founded, because the no-[feedthrough](#g-feedthrough) stage takes no
  inputs.
- [Ports](#g-port) are classified over `y_types` alone, into two classes:
  the stage-1 names and the stage-2 remainder ([§8.3][s8-3], [D-252][d-252]).
- The feedthrough graph is built from the wires carrying stage-2 ports, and a
  topological order over it follows. [§5.5][s5-5] cycle rejection applies.
- The event declarations are read last, after the stage probes, and they
  become `Events`. A consumer of the execution order therefore never carries
  the event tables ([D-253][d-253]).

Both products are structural. They are names only, `T`-independent,
branch-protected by the branch-shape rule plus the always-on check ([§9.5][s9-5]).

**The nominal evaluation fixes the structure and the `Float64` typing at
once.** The nominal [activation](#g-activation) is its product beside
`Outputs` and `Events`, assembled from the same probe chain, never a
separate pass ([D-253][d-253], [D-259][d-259]). That is why no product of
this step changes across activations.

#### Activation, parametric in `T`

**Activation at a scalar `T` takes the `Structure`, the `Outputs` and the
nominal activation, and completes an `Activation{T}`** ([D-253][d-253],
[D-259][d-259]). The step holds everything type-shaped:

- The producers' output declarations are **retyped** at the activation's `T`
  to type the [cells](#g-cell). A continuous producer's declaration is walked at
  `T`, its `Pinned` leaves excepted, and a discrete producer's is read once and
  [pinned](#g-walked) ([§8.2][s8-2]).
- The `x_init`-derived state type is [walked](#g-walked) by the leaf-walk rule ([§8.2][s8-2]),
  and the `s_init`- and `m_init`-derived store types pin.
- The probe chain runs in topological order ([§9.3][s9-3]), and observed is
  compared against declared.
- The flat `x` [buffer](#g-buffer) and the table are laid out.

The nominal `Float64` activation runs at build. Other activations re-run *only
this step* ([§9.4][s9-4]).

#### The `Deployment` constructor

**The `Deployment` constructor sits after the build's three steps.** It consumes the
`Build` and the grid parameters, and it returns a [`Deployment`](#g-deployment),
the artifact that carries everything those parameters fix ([D-254][d-254]). It
binds the grid parameters, the algorithm, the three event parameters, runs
harmonic-grid validation, and builds the [schedule](#g-schedule). Nothing in
the build's three steps depends on it.

A `Deployment` is scalar-free. It holds the build, the grid parameters, the
algorithm, the three event parameters, the `Schedule`, the grid diagnostics
below and its own `warnings`. `Simulation` materializes it at a scalar type
`T` ([§9.2][s9-2]).
Two deployments compare as values, which is what replay's header check reads
([§12.7][s12-7]).

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
and key from the rate-chain column. The per-component triples are the
[schedule](#g-schedule), the `Schedule` the constructor builds and the
`Deployment` carries ([§9.2][s9-2]).

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

#### Where a build warning lives

**Rule.** A step that throws renders its warnings with the collection it
throws. A step that completes carries its warnings on the artifact, and the
entry point logs each one once at return ([D-250][d-250]). Logging is
presentation and never a home ([§13.2][s13-2]).

A warning raised inside a declaration body has no artifact in hand. The build
binds a scoped channel around its three steps, and the helper appends to it
without knowing the build. The same helper called standalone, outside any
build, logs directly. That is how `EmptyFaceSelection` ([§8.8][s8-8]) reaches
the `Build`'s list.

### 9.2 The `Build` artifact

`build(world) → Build` is a standalone entry point. **A `Build` is structure,
outputs, events, the [activations](#g-activation) and `warnings`** ([D-253][d-253]).
The first three are the products of [§9.1][s9-1]'s three steps. The activations are one
dictionary keyed by scalar type, the nominal `Float64` entry included, under
the lock that makes insertion torn-state-free ([§9.4][s9-4]).

**Deploying and materializing are two steps, with two sugar forms over them.**
The constructor of a [`Deployment`](#g-deployment) (the scalar-free artifact
the grid parameters fix) takes a `Build` and the grid parameters
([§9.1][s9-1]). `Simulation(deployment, T)` materializes a deployment at a scalar
type. `Simulation(build; kw...)` composes those two, and `Simulation(world;
kw...)` calls `build` first ([D-254][d-254]). The artifact deployed is the very
build that CI checked, that an acceptance test targeted, and that a
[face](#g-face)-route table was printed from, never an assumed-equal
reconstruction.

**Why.** Computed interface-connection bodies are ordinary user code
re-evaluated on every build, so equality between two builds of the same world
is an assumption the factorization removes.

**The `Build` is immutable and may back any number of deployments and
`Simulation`s, concurrently.** That is true by construction once buffers are
single-owner ([§9.4][s9-4]). Each `Simulation` materializes its own from the
shared layouts, so nothing writable is shared. The one mutable thing on the
artifact is the lazily populated activation dictionary, whose insertion
[§9.4][s9-4] makes torn-state-free. The `Build` is the inspectable derived
contract of the instantiation that [§8.8][s8-8] gestures at. Its parts hold the wire
list, face table, [root inputs](#g-root-input) and [execution order](#g-execution-order) as plain printable data. The
first three sit on [`Structure`](#g-structure) (the structure step's product, the components,
wires, faces and tiers). The last sits on [`Outputs`](#g-outputs) (the nominal evaluation's
product, the port classes and the execution order). "Printable" names the
representation. Paths, names and rationals are inspectable as fields
and printed by any REPL without a method of their own, the diagnostic form set
against the compiled form ([§9.7][s9-7]).

**The face table on `Structure` is two-sided.** Beside each level's output
faces and their routes it retains that level's *input* faces, each resolved
producer-ward
to the one feed its consumers share, either a root input or a producer inside
the model. The record is total, because one-level routing gives every signal
a declared face at every boundary it crosses ([§6.1][s6-1], [D-207][d-207]). The input
side is what a [fragment](#g-fragment)'s `u` payload resolves against from any
authoring level ([§14.2][s14-2], [§14.3][s14-3]). CI checks a model by calling `build`, the
acceptance tests target `build` errors directly, and `attach!` validates
[device](#g-device) [bindings](#g-binding) against it. Build living only inside the `Simulation`
constructor was rejected ([D-049][d-049]).

**`Structure`'s timing tables are anchor-relative, and the `Deployment` binds
them.** From the structure step the artifact gains two printable tables. The
**[anchor](#g-anchor) table** holds each anchor's exact `(T, τ)` rationals with the
declaring scope's path and key. The **[component](#g-component) table** holds the
`(anchor, m, c)` triples with their rate chain, the
`Relative`/`Absolute` chain down the tree. The base grid `A₀` takes an
anchor-table row of its own, with a dash in the scope and key columns,
because no scope declares it. Its `(T, τ)` stays symbolic there until
`Δt_base` binds. For a fully relative model the only anchor is `A₀` and the
triples *are* the final base-[tick](#g-tick) `(D, Φ)` pairs. When anchors exist, final
divisors cannot live here. They do not exist until `Δt_base` binds, and the
same `Build` already backs many deployments with different grid
parameters.

**The [`Schedule`](#g-schedule) (the typed per-component `(D, Φ, Δt)` tick
table) lives on the `Deployment`** ([D-254][d-254]). The `Deployment`
constructor ([§9.1][s9-1]) builds it from the structure's triples and anchors.
It is the typed schedule: one row per discrete component carrying
`(D, Φ, Δt)` with the anchor and rate-chain columns, the [rate-scope](#g-rate-scope)
rows (an assembly's `sample_times` declaration against the enclosing scope)
each with its own `(Dₛ, Φₛ)`. The per-component `(D, Φ, Δt)` the executor
compiles over are derived from the rows at `compile`, never stored beside
them ([D-261][d-261]). The schedule is the single source of truth for `Δt`
([§10.5][s10-5]), the substrate of the grid diagnostics below, and the table
that answers "when does what run, and what coincides with what".

**Rule.** An [artifact](#g-artifact) holds declared facts. A consumer
compiles what it needs from them once, at one home, and the activation's
cell layout is that home for address facts ([D-261][d-261]). A compiled form
stored beside its declared one is a second home, with no enforcer but the
constructor that filled both.

**Each artifact renders itself through `show`, with no accessors**
([D-257][d-257]). `show(::Structure)` prints the anchor table with the `A₀` row
and the component table with the rate-scope rows. `show(::Outputs)` prints the
execution order with each port's class. `show(::Schedule)` prints the rows and
the **hyperperiod chart**. `show(::Build)` and `show(::Deployment)` print a
summary and their parts. A REPL user gets each table by evaluating the value.
The structure step records each face's routing chain at every level.
`show(::Structure)` prints the root's routes, one line per chain, its hops
joined with `→` and ending at the terminal ([§13.7][s13-7]). An input face that
fans out prints one line per consumer.

The chart's pattern repeats with period `lcm(Dᵢ)` base ticks, and the gate is
pure modulo arithmetic, so one hyperperiod is the complete truth, not a sample.

**Rule.** The chart guard is binary. The chart prints whole, as a tick chart
over `k = 0 … lcm(Dᵢ) − 1`, when `lcm(Dᵢ)` is at most 100 base ticks.
Otherwise `show` prints the hyperperiod's length and "chart omitted"
([D-257][d-257]).

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

**The grid diagnostics live on the `Deployment` and print from the pool,
exactly** ([D-254][d-254]). The refusal path's
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
`GridUtilization` is a deployment warning, so it lives on the `Deployment`'s
list and the constructor logs it once at return ([D-250][d-250]).

**`warnings(x)` reads the list.** It is defined on `Build` and `Deployment`,
and on `Simulation` as the concatenation of its artifacts' lists ([D-250][d-250]).
Warnings raised while mutating state stay in that state's status record
([§11.8][s11-8]), never here.

### 9.3 Probing and input synthesis

**[Probe](#g-probe)-everything scope.** The nominal [activation](#g-activation) probes every user
function once, at the initial state, with real values. The set is the stages,
`x_deriv`, `s_update`, [guards](#g-guard), handlers and
`x_projection`. The probe checks shape and type conformance and discards
the results. All are pure, and the cost is one evaluation each. "Fails loudly
at build time where possible" ([§8.1][s8-1]) decides this. A malformed
`x_deriv` return must not wait for the first integrator step. Probes
see only the initial state's branch, so the marginal coverage is earliness,
not completeness. The always-on check ([§9.5][s9-5]) remains the completeness
backstop.

**Probe argument sourcing.** `x`/`s`/`m` come from `init_*` declarations,
which declare by value. The stage-1 hand-down, `y_x` and `y_s` on the
discrete [tier](#g-tier), comes from the stage-1 probes' *returns*, which is
every stage-1 [port](#g-port) there is ([§5.2][s5-2]). Wired inputs come from
upstream products. Real values
are available because the stage-2 chain is probed in topological order, so
every consumer is probed against the same value it will receive at run time.
Two checks ride the same pass. The first is the return's shape. A stage
returning something other than a `NamedTuple` fails here. The second is the
dead-stage rule. A stage returning bare `(;)` produces no ports at all, and
is `DeadStage`, fail-fast. The [bundle law](#g-bundle)'s two remaining fields ([§5.2][s5-2])
are sourced as follows. `t` is probe-scoped `0.0`. Deployment binds no clock
and `t₀` post-dates even deployment ([§14.5][s14-5]), so like `Δt` below it is a
fabricated, probe-scoped value. `ws` comes from invoking the component's
`ws_init` allocator at the probing scalar. That allocator reads only
the instance and the scalar ([D-077][d-077]) and derives nothing from layouts, so it
runs before the nominal evaluation's probes that need it. Exactly one kind of
terminal has no producer: **root inputs**. The build synthesizes their values
via `probe_value(::Type)`. Framework methods cover `Real` (`zero(T)`), `Bool`
(`false`) and enums (first instance), and the ultimate fallback is the
zero-argument constructor `T()`. That is where well-behaved constrained types
already put their valid default (`RQuat()` is the identity, and the `@kwdef`
convention supplies it broadly). `probe_value` is **overridable**. A type
whose valid default is not reachable that way declares its own method, which
is also the [seam](#g-seam) a [walked](#g-walked) type uses to state a constrained default. No
method is a build error, in the didactic style. It names the [face](#g-face) and the
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
à la `x_init`, NaN poison values, and init-service values.

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
type-valid inputs.** Every probed user function (stages, `x_deriv`,
`s_update`, guards, handlers, `x_projection`) evaluates without
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

An **[activation](#g-activation) at `T`** re-runs the activation step with a different scalar:

- producer-fed [cells](#g-cell) are re-typed by *walking* the producing [component](#g-component)'s
  output declaration at `T` ([§8.2][s8-2]). A continuous producer's declaration
  follows the scalar at every unpinned leaf, and a discrete producer's
  declaration pins;
- [root-input](#g-root-input) cells are re-typed by *walking* the consuming `u_types`
  entry at `T`, which [§8.2][s8-2] reads permissively. An unpinned entry follows
  the activation, and a `Pinned` entry stays frozen;
- the state type is re-derived by the walk over `x_init`'s, with table and
  state [buffers](#g-buffer) re-laid-out;
- [workspace](#g-workspace) allocators are re-invoked at `T`, not introduced. The first
  invocation precedes the nominal evaluation's [probes](#g-probe) ([§9.1][s9-1]/[§9.3][s9-3]), and a
  [continuous component](#g-continuous-component)'s scratch carries the activation's scalar ([§7.3][s7-3]);
- the probe chain is re-run.

[`Structure`](#g-structure), the structure step's product, and
[`Outputs`](#g-outputs), the nominal evaluation's, are `T`-independent by construction,
so no [execution order](#g-execution-order) and no name list changes across
activations
([D-253][d-253]).

**Each activation probes exactly the function set it can execute.** A `Dual`
activation (linearization, gradient trim) evaluates the model at a frozen
instant. Discrete stages are gated off holding `Float64` values (the [§8.2][s8-2]
frozen-constant semantics), and [guards](#g-guard) and handlers never run, because
event localization is `Float64` [sweeps](#g-sweep) by design ([§10.4][s10-4]). Only the
continuous output stages (`y_state`/`y_direct`) and
`x_deriv` ever see a `Dual`, so only they are probed. Probing the
discrete stages, `s_update`, or guards at `Dual` would check code against
a number type it cannot receive. It is one rule with no special cases, and the
[§5.6][s5-6] tracer activation follows it identically. "Tracer activation" names the
*global* set-tracer ([D-012][d-012]), a whole-model run at the tracer scalar, an activation
like any other. The cycle classifier ([§5.6][s5-6]) is the other variant ([D-012][d-012]). It is
the order-free per-member local trace, which runs in the nominal evaluation's
failure path and is not an activation at all.

**Lazy, with an opt-in exhaustive mode.** Non-nominal activations run at first
request, not at build. The dominant cost is compiling the continuous chain a
second time at `Dual`, pure waste for interactive fly-around use. The price is
stated openly. `build` succeeding does **not** certify the model
linearizable. A [pinned](#g-walked) `Float64` ([§7.2][s7-2]), whether hidden in a constructor
or declared `Pinned` at a leaf that really participates (the misplaced pin,
[§8.2][s8-2]), lurks until the first `Dual` activation
detonates it at the probe, naming the offending constructor or leaf. The
repository's test suite pins the invariant instead, as policy rather than
advice ([D-166][d-166]). **Every component gets a `Dual` activation built in CI.**
`build(world; activations = (Float64, ProbeDual))` runs the exhaustive set,
catching both genericity violations and misplaced pins at PR time, at the
cost of an activation per component. The keyword is the whole entry point,
and no separate check function exists ([D-275][d-275]). The same
keyword is also recommended for the parallel-sweep idiom ([§11.1][s11-1]).
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
function of the build and the concrete scalar type, so the activation
dictionary is the `Build`'s, and the nominal `Float64` entry is one key in it
like any other ([D-253][d-253]). Each entry holds layouts, compiled plans and a
validated flag keyed by that type, immutable once constructed and hence freely
shareable. **Buffers
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
At the point where the [executor](#g-executor) (the compiled form of the stage
execution order) stores a stage return into the table, it holds the complete
expected return type at this [activation](#g-activation). That type is the type of the
[cells](#g-cell) this stage writes, as the probe fixed them at this activation. It is one
concrete `NamedTuple` type per ([component](#g-component), stage), the stage's declared
names at the types their cells hold ([§8.2][s8-2]). The write is generated over
that type and the return's type, so the test is decided when the write's
method is specialized, and no per-field instruction reaches the conformant
path ([D-235][d-235]). When the write's method is
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
`Expected`'s order is an internal fact. It is derived from `y_types`,
stage-filtered, an order no single declaration shows the author. The author
never reproduces it. A return spelling the right names at the right types
conforms in any order.
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

**Exact match at nominal, embed-accept at walking leaves.** At the
nominal activation, the only one that ever runs in real time, the check is an
exact type match, with no convert-on-write, decided at generation and absent
from the conformant path ([D-053][d-053], [D-235][d-235]). The error can afford to be
didactic: "field `M_shaft`: expected `Float64`, got `Int64` — return
`zero(x.ω)`, not `0`". Under a non-nominal activation (the build's typed
products at a given scalar type) the two leaf kinds the declaration ([§8.2][s8-2])
distinguishes are checked differently. A **walking leaf**, one the author left
unpinned, accepts exactly two types, the activation scalar or
`Float64`. The activation scalar is the fast path, the straight store. A
`Float64` the executor **embeds** as a zero-partial constant (`convert`
through the leaf). Struct-valued [ports](#g-port) use the standard cross-eltype
constructor, and a missing one fails loudly with both types named. An opaque
leaf ([§4.3][s4-3], [D-237][d-237]) embeds nothing into a store. It is accepted there
by identity alone. At a wire the entry is a bound, and a frozen opaque
arrival is admitted as the producer's cell ([§6.1][s6-1], [D-264][d-264]).
Nothing else is accepted. The check is decided on the type, not leaf by leaf.
The arrival with its `Float64` positions lifted to the scalar wherever the
declaration has one must be the declaration itself, so a field name, a
non-numeric type parameter or an array's mutability that differs is refused
like any other mismatch ([D-238][d-238]). A **[pinned](#g-walked) leaf**, one the author
wrapped as `Pinned`, or an `Int`, `Bool` or enum leaf that never walks, takes
the nominal-style exact check at *every* activation, because its declaration
said the leaf never carries partials. An observed `Dual` there is the
misplaced-pin error, that being the one honest cause. The didactic hint is
attached: "if `F` participates in differentiation, remove its `Pinned`". The
embedding is exact, not lenient. Promotion is airtight and there is no lossy
`Dual → Float64` cast, so a `Float64` observed at a walking leaf means
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
is invisible to the schema. **The pinned leaf is the schema-visible freeze.**
An author who means to strip declares the leaf `Pinned{Float64}` and strips
inside the stage, and the check above holds the freeze to its word at every
activation. Stripping mid-expression at a leaf left unpinned remains legal and
remains unseen, as the sharp tool it is.

**Uniform across all probed functions.** `x_deriv` checks against
`X`'s own shape at the activation's `T` ([§7.1][s7-1]: a scalar leaf expects a
`T`, an `SArray` leaf the same `SArray` at `T`). Its predicate is "every field
scatters into its field's block at `T`", which is what makes derivative
completeness structural rather than a matter of author discipline. [Guards](#g-guard)
check against their probe-derived [predicate](#g-predicate) form (below), `s_update`
against its leaf's `s` shape, and handlers against the [§5.2][s5-2] return law,
key by key. `x_projection` checks against `X`'s own shape at `T`,
**complete**, since its result is written back to the [buffer](#g-buffer) wholesale at
both of the positions in the [execution order](#g-execution-order) ([§5.3][s5-3]) and a [projection](#g-projection) with a
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

**Failure payload.** The payload carries the component path, the function,
the event name on a handler's occurrence, and the field-level diff (missing /
unexpected / per-field expected-vs-observed). Simulation time is the
carrier's, not the diagnostic's. At run time the failure travels as a
[species](#g-species) of `StepError` through the single catch site ([§13.4][s13-4]), whose
frame holds the boundary time and the replay index, and a build-time
occurrence has no time to carry ([D-249][d-249]). Deliberately absent is the source
branch. A value does not say which branch produced it, and the diff identifies
it. The always-on input [trace](#g-trace) makes every such failure **reproducible by
[replay](#g-replay)**. The error
names the [boundary](#g-boundary) to replay to (`to_boundary`, [§12.7][s12-7]). The catch site adds
the loop-level nonfinite-state check as the failure's divergence sibling.
### 9.6 Stopped-sim services as activation clients

This section is sketched here because it grounds the build's steps. The services
themselves are [§14][s14]. The C172 trim problem (`c172.jl`: `TrimState`,
`TrimParameters`, `θ_constraint`, the `ẋ`-reading cost) transfers
near-verbatim:

- **Trim** is a loop that writes a condition, runs a [sweep](#g-sweep) and reads the
  result, on an [activation](#g-activation). By default that is the `Dual` activation, with
  decision variables seeded for exact residual Jacobians ([§14.7][s14-7]). The derivative-free fallback runs the
  same loop on the nominal `Float64` activation (the build's typed products at a
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
  solved-condition write-back including root inputs and the [trace header](#g-trace-header)
  taken after it) replaces today's per-aircraft NLopt plumbing. A failed
  trim leaves the simulation's stores untouched, an improvement over today's
  warn-but-assign `f_init!`.

### 9.7 The compiled executor

The [execution order](#g-execution-order) exists in two representations at two lifecycle stages. On
[`Outputs`](#g-outputs) (the nominal evaluation's product, the port classes and the execution order)
it is plain printable data ([§9.2][s9-2]), paths, stage names and order, which
is the authoring and diagnostic form. The executor compiles from that order
([D-253][d-253]). At `Simulation` construction, and
per [activation](#g-activation) (the build's typed products at a given scalar type), that data
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
forced.** The [boundary sweep](#g-sweep)'s stage-1 block, both tiers' `y_state`
entries alike, is order-free by definition, because the no-[feedthrough](#g-feedthrough)
stage reads no `u`. The stage-2 block gates in the [due](#g-due) discrete stages,
those whose components this boundary admits by their compiled `(D, Φ)` pair.
It is the only topologically ordered one. The `x_deriv` block (the
[RHS](#g-flow) body the stepper calls per stage evaluation) and the `s_update`
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
decomposition stays free. Fusing a step's sweep with its `x_deriv`
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
cross-entry fusion is lost, which a table-mediated signal flow barely had.
Chunk size is the implementation's *only* representation freedom (fully
fused and chunk-of-one are its endpoints), and it converts the compile cost
from superlinear in the largest body to linear in entry count.

Measured anchors, taken 2026-07 over synthetic ~15-op bodies on Apple
Silicon, with the last two rows extrapolated to a full aircraft model of
roughly 200–400 entries with larger bodies. Those two rows
assume the chunked mode, the one whose cost is linear in entry count:

| case | activation | compile time |
|---|---|---|
| 400-entry sweep, fused | `Float64` | ~0.8 s |
| 400-entry sweep, chunked | `Float64` | ~0.34 s |
| 400-entry sweep, chunked | 8-partial `Dual` | ~9 s |
| Aircraft-scale model, extrapolated | nominal | seconds |
| Aircraft-scale model, extrapolated | `Dual` | tens of seconds, before mitigation |

The fused curve is visibly superlinear. An 8-partial `Dual` activation
multiplies instruction count ~20×, and its chunked curve is linear,
instruction-bound rather than structure-bound. Re-measurement on a real
model of that scale is pending (`pending.md`).

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
Entry tuples are built from untyped buffers and splatted once. Generic
tuple utilities (range indexing, long `ntuple` closures, naive recursion) are
inference traps at the entry list's length, since a 400-entry heterogeneous
tuple can send generic `getindex` inference into combinatorial collapse. The
compiled tuple's type therefore has exactly one consumer, the unrolled walk.

**The phase bodies are the [§7.5][s7-5] [measurement seam](#g-measurement-seam).**
`phase_bodies(sim)` returns the compiled bodies of the nominal activation as
named callables bound over the simulation's own buffers. The four blocks:

- `rhs`, the `x_deriv` block.
- `sweep_1`, in both arities.
- `sweep_2`, in both arities.
- `ticks`, which takes the tick index its entries gate on.

Returned with them are the per-event guards and handlers and the
per-component `x_projection` callables, keyed by the model's own roster.

The four-body roster is fixed and total. The accessor returns all of it
always, whatever the model happens to declare. A model with no discrete
components, no events or no continuous state at all still gets every body.
The empty ones are legal, compile to no-ops, and their `@ballocated`
assertion passes vacuously. That is the point, because consumers then
iterate the roster uniformly, with no existence checks and no per-model
branching in the measurement code.

One promise, and it is diagnostic only ([§13.5][s13-5]). **These are the bodies
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
`@ballocated f_ode!`/`f_step!`/`f_periodic!` idiom and the seam the FlightCore
comparison in `migration_outline.md` measures through.

Publication is not a phase body. That is the carve-out ([§7.5][s7-5]) made
structural. What the accessor exposes is exactly what the invariant claims
is zero. Invoking bodies in isolation mutates the simulation's buffers
outside any [frame](#g-frame) sequence (a tick entry advances discrete state with no
clock advance), leaving them valid but off-trajectory. A session that wants
to continue meaningfully re-runs `init!`.
