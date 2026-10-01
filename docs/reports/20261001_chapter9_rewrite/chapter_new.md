## 9. The build pipeline

The build consumes a root [component](#g-component) instance and produces the
runnable artifact. It consists of the resolved wires, the
[execution order](#g-execution-order), the anchor-relative rate triples and the
[root inputs](#g-root-input), plus the nominal activation's typed
[signal table](#g-signal-table) and flat state layout.
[§8][s8] states what is declared and what must hold. This chapter states *when*
each fact is checked, against what, and with which failure. The [§8.4][s8-4]
walkthroughs plus the error rules ([§6.1][s6-1]) are its acceptance tests.
Error-*reporting* policy is settled in [§13.1][s13-1], under which declarative
checking passes collect and user-code evaluation fails fast. [§9.1][s9-1]
covers the build's three steps, [§9.2][s9-2] the [`Build`](#g-build) and
[`Deployment`](#g-deployment) artifacts, [§9.3][s9-3] probing and input
synthesis, [§9.4][s9-4] [activations](#g-activation), [§9.5][s9-5] the
always-on conformance check, [§9.6][s9-6] stopped-sim services as activation
clients, and [§9.7][s9-7] the compiled executor.

### 9.1 The build's three steps

This section states the build's steps, what each consumes and produces, and what
each checks. Three ordering constraints are forced by settled decisions.
[Face](#g-face) derivation is bottom-up, because an [assembly](#g-assembly)'s
interface connections evaluate against child [contracts](#g-contract)
([§8.8][s8-8]). The unconnected-input obligation check and cross-level
two-producers detection are global. They are decidable only at the root, after
every assembly's wires and faces are in hand ([§6.1][s6-1]). And stage
membership is derived by probing the stage-1 functions ([§8.2][s8-2]), so
evaluation interleaves with graph construction at exactly one
[blessed](#g-blessed) spot. The pipeline is therefore inherently heterogeneous.

**The pipeline runs as the steps below**, each consuming one artifact and
producing the next, and each a barrier ([D-259][d-259]). A step that
produced any error throws before the next begins ([§13.1][s13-1]).

| step | consumes | produces | user code it runs |
|---|---|---|---|
| the structure step | the root instance | [`Structure`](#g-structure) | declaration bodies only |
| the nominal evaluation | `Structure` | [`Outputs`](#g-outputs), [`Events`](#g-events), the nominal `Float64` [activation](#g-activation) | every user function once, at `Float64` ([§9.3][s9-3]) |
| activation at `T` | `Structure`, `Outputs`, the nominal activation, a scalar `T` | `Activation{T}` | the continuous [tier](#g-tier)'s functions at `T` |
| deployment | the `Build`, the grid parameters | [`Deployment`](#g-deployment) with its [`Schedule`](#g-schedule) | none |
| materialization | the `Deployment`, a scalar `T` | `Simulation{T}` | none |

The first three are the build, and `build(world)` runs them. The
[`Build`](#g-build) bundles their products ([§9.2][s9-2]). The last two are
the `Deployment` constructor and the `Simulation` constructor, both in
[§9.2][s9-2].

#### The structure step

**The structure step is pure declaration reading** ([D-048][d-048]). No user
stage code executes in it ([D-259][d-259]). The `u_connections`,
`y_connections` and `input_passthrough` bodies are declaration code
([§8.8][s8-8]).

The step is a tree walk from the root instance, in this order:

1. [Components](#g-component) are collected by path.
2. Each component's [class](#g-class) (its primitive-vs-assembly status) is
   read off declaration shape ([§8.5][s8-5]).
3. Leaf contracts are collected: `u_types`, `y_types`, `init_*` values,
   `state_events`.
4. Face derivation runs bottom-up. It records at every level the input and
   output faces it declares and the chain each one routes through.
5. Global wiring resolution then runs, resolving wires to absolute leaf
   terminals.

Before a component's class is read, the walk runs the shadowing check
([§8.1][s8-1], [D-246][d-246]).

Resolution runs these checks:

- one-writer-per-input;
- the typo [did-you-mean](#g-did-you-mean) (the offending name plus the
  list-in-hand it should have matched) against the destination's input list;
- the two wiring type clauses ([§6.1][s6-1], [§8.2][s8-2]), stated below;
- the whole-tree (unconnected-input) obligation check;
- the store form ([§8.2][s8-2]);
- the closed leaf vocabulary ([§7.1][s7-1]).

The store form is that every `x_init`, `s_init` and `m_init` value is a
`NamedTuple`. **The store form is checked before the tier classifier
and the vocabulary checks read the value** ([D-247][d-247]). A primitive
failing it is read no further in this step. The closed leaf vocabulary is
checked on every `x_init`, because the walk in [§8.2][s8-2] rests on it.
`s_init` pins wholesale and answers to the isbits rule of [§7.3][s7-3] instead.
**The isbits rule is checked on `s_init` and `m_init` field by field**
([D-231][d-231]).

The bound check is the first type clause, and it applies at nominal faces.
**The producer's declaration at `Float64` must be `<:` the entry at
`Float64`** ([D-078][d-078]). Equality is the concrete degenerate case.
Abstract-at-root is detected here ([D-236][d-236]).

The walk-compatibility clause is the second, and it applies to continuous
consumers only. **The walk-compatibility clause is decided by retyping both
declarations at a marker scalar** and comparing per leaf at a concrete entry,
or on the whole declaration at an abstract one ([D-263][d-263],
[D-236][d-236]). Its diagnostic is `WalkingFaceAtFrozenEntry`. The clause
stays inside this step's charter because both sides are plain declarations
the walk retypes. Declarations are read, and no user stage code runs.

[Root inputs](#g-root-input) fall out here too, as the root component's
input faces ([D-208][d-208], [§8.2][s8-2]).

The step also checks the declaration-completeness rules ([§8.2][s8-2]):

- a store without its update;
- a leaf declaring no store;
- an event missing a [guard](#g-guard) or handler method;
- a leaf mixing tier families;
- a stateless leaf with no output contract.

**`sample_times` validation is the structure step's too** ([D-185][d-185]). It
has two parts. The first is per-entry validity against the constraints of
[§10.5][s10-5]. They require wrapper-typed values, `K ≥ 1`, `0 ≤ Φ < K`,
`T > 0`, `0 ≤ τ < T`, and keys naming discrete or scope children. Those
violations are collected with path attribution. The second is compilation into
`(anchor, m, c)` triples. A triple carries a discrete component's divisor and
[phase](#g-phase) in the [tick](#g-tick) units of its [anchor](#g-anchor), the
exact `(T, τ)` pair an `Absolute` entry establishes.

The compilation is a fold down the tree, one rule per case
([D-186][d-186]):

| the fold meets | the triple it produces |
|---|---|
| the root scope | `(A₀, 1, 0)`, anchor 0 being the base grid itself: `(T, τ) = (Δt_base, 0)` |
| `Relative(K, φ)` under a scope at `(a, mₛ, cₛ)` | `(a, K·mₛ, cₛ + φ·mₛ)` |
| `Absolute(q, τ)` under any scope | severs and re-seeds: a fresh anchor `Aₖ = (period(q), τ)`, its subtree continuing at `(Aₖ, 1, 0)` |

Anchor 0 is symbolic until deployment. The `Relative` case is the affine law
([§10.5][s10-5]) in anchor-tick units. The canonical residue (`c < m`) holds
within each anchor's subtree by the same induction.

Everything except binding `Δt_base`, which is deployment's, happens in the
structure step. [§9.2][s9-2] states why final divisors wait for that
binding.

**The structure step returns `Structure`** (the artifact holding everything the
instance alone fixes), and that is its whole product ([D-253][d-253]).
`Structure` carries the following:

- the component instances by path;
- the tier each one sits on;
- the resolved wires;
- the two-sided face table, with each face's routing chain;
- the root inputs;
- per component, its rate chain of `Relative`/`Absolute` links;
- for each assembly an explicit `sample_times` key names, the scope triple
  that key gives it.

Class and contracts are read off the instance on demand. Nothing in
`Structure` depends on a scalar type.

#### The nominal evaluation

**The nominal evaluation is a function of the `Structure`**, and it returns three
artifacts, `Outputs`, `Events` and the nominal `Float64` activation
([D-253][d-253], [D-259][d-259]). It is the single evaluation-feeds-structure
step.

`Outputs` (the artifact holding the port classification and the order over
it) carries per component the stage-1 and stage-2 output names. It also
carries the [execution order](#g-execution-order) over the components.
**The [feedthrough](#g-feedthrough) graph the order is computed over is not
carried** ([D-261][d-261]). It is derived from the `Structure`'s connections
and the producers' stage-2 names wherever it is shown.

`Events` (the artifact holding the event tables) carries per component the
event names, their detection policies and the bundle names.

The nominal evaluation does its work in this order:

- [Workspace](#g-workspace) (component-declared mutable scratch arriving as
  the `ws` bundle field) is allocated at the probing scalar, `Float64`
  ([§9.3][s9-3]).
- Stage-1 [probes](#g-probe) run at `Float64`, on
  `x_init`/`s_init`/`m_init` values. They are well-founded, because the
  no-feedthrough stage takes no inputs.
- [Ports](#g-port) are classified over `y_types` alone, into two classes,
  the stage-1 names and the stage-2 remainder ([§8.3][s8-3], [D-252][d-252]).
- The feedthrough graph is built from the wires carrying stage-2 ports, and a
  topological order over it follows. [§5.5][s5-5] cycle rejection applies.
- The event declarations are read last, after the stage probes, and they
  become `Events`. A consumer of the execution order therefore never carries
  the event tables ([D-253][d-253]).

`Outputs` and `Events` are structural. They are names only, `T`-independent,
and branch-protected by the branch-shape rule plus the always-on check
([§9.5][s9-5]).

The nominal evaluation fixes the structure and the `Float64` typing at
once ([D-253][d-253], [D-259][d-259]). The nominal
activation is its product beside `Outputs` and `Events`. It
is assembled from the same probe chain, never in a separate pass. That is why
no product of this step changes across activations.

#### Activation, parametric in `T`

Activation at a scalar `T` takes the `Structure`, the `Outputs` and the
nominal activation, and completes an `Activation{T}` ([D-253][d-253],
[D-259][d-259]). The step holds everything type-shaped. It retypes the
[cells](#g-cell) and the [walked](#g-walked) state type at `T` and lays out
the [buffers](#g-buffer), as [§9.4][s9-4] details. The probe chain runs in
topological order ([§9.3][s9-3]), and observed is compared against declared.

The nominal evaluation produces the `Float64` activation at build. Every other
activation re-runs *only this step* ([§9.4][s9-4]).

### 9.2 The `Build` and `Deployment` artifacts

The build's three steps ([§9.1][s9-1]) leave their products on a
[`Build`](#g-build). Deploying a build at grid parameters leaves a second
artifact, the [`Deployment`](#g-deployment) (the scalar-free artifact the grid
parameters fix). The `Deployment` carries the [`Schedule`](#g-schedule) (the
typed per-component `(D, Φ, Δt)` tick table). A `Simulation` then materializes
a `Deployment` at a scalar type. This section states what each artifact holds,
how a `Deployment` binds, how each artifact prints, how a `Deployment` explains
its grid, and where the warnings raised on the way live.

#### The `Build`

**`build(world) → Build` is a standalone entry point** ([D-049][d-049]). CI
checks a model by calling `build`, the acceptance tests target `build` errors
directly, and `attach!` validates [device](#g-device) [bindings](#g-binding)
against the `Build`. Build living only inside the `Simulation` constructor was
rejected.

**A `Build` is structure, outputs, events, the [activations](#g-activation)
and `warnings`** ([D-253][d-253]). The first three are the products of
the structure step and the nominal evaluation ([§9.1][s9-1]).

**Deploying and materializing are two steps**, with two sugar forms over them
([D-254][d-254]). The `Deployment` constructor (below) is the first step.
The `Simulation` constructor has three forms, the materialization step and the
two sugar forms:

```julia
Simulation(deployment, T)   # materializes a deployment at a scalar type
Simulation(build; kw...)    # composes the two steps
Simulation(world; kw...)    # calls build first
```

The artifact deployed is the very build that CI checked, that an acceptance
test targeted, and that a [face](#g-face)-route table was printed from, never
an assumed-equal reconstruction. Computed interface-connection bodies are
ordinary user code re-evaluated on every build, so equality between two builds
of the same world is an assumption the factorization removes.

The `Build` is immutable apart from its lazily filled activation dictionary,
and may back any number of `Deployment`s and `Simulation`s, concurrently
([D-135][d-135]). Insertion into that dictionary is torn-state-free.
[§9.4][s9-4] states the ownership rule, the keying and the guarantee.

The `Build` is the inspectable derived contract of the instantiation that
[§8.8][s8-8] gestures at. Its parts hold the wire list, face table,
[root inputs](#g-root-input) and [execution order](#g-execution-order) as
plain printable data. The first three sit on [`Structure`](#g-structure) (the
structure step's product, the components, wires, faces and tiers). The last
sits on [`Outputs`](#g-outputs) (the nominal evaluation's product, the port
classes and the execution order). "Printable" names the representation. Paths,
names and rationals are inspectable as fields, and any REPL prints them
without a method of their own. That is the diagnostic form, set against the
compiled form ([§9.7][s9-7]).

An [artifact](#g-artifact) holds declared facts, and a consumer compiles
what it needs from them once, at one home ([D-261][d-261]). The
activation's cell layout is that home for address facts. A compiled form
stored beside its declared one is a second home, with no enforcer but the
constructor that filled both.

**The face table on `Structure` is two-sided** ([D-207][d-207]). Beside each
level's output faces and their routes, it retains that level's *input* faces.
Each is resolved producer-ward to the one feed its consumers share, either a
root input or a producer inside the model. The record is total, because
one-level routing gives every signal a declared face at every boundary it
crosses ([§6.1][s6-1]). The input side is what a [fragment](#g-fragment)'s `u`
payload resolves against from any authoring level ([§14.2][s14-2],
[§14.3][s14-3]).

**`Structure`'s timing tables are anchor-relative**, and the `Deployment` binds
them ([D-186][d-186]). From the structure step the artifact gains two
printable tables:

- The [anchor](#g-anchor) table holds each anchor's exact `(T, τ)` rationals
  with the declaring scope's path and key.
- The [component](#g-component) table holds the `(anchor, m, c)` triples with
  their rate chain, the `Relative`/`Absolute` chain down the tree.

The base grid `A₀` takes an anchor-table row of its own, with a dash in the
scope and key columns, because no scope declares it. Its `(T, τ)` stays
symbolic there until `Δt_base` binds. For a fully relative model the only
anchor is `A₀`, and the triples *are* the final base-[tick](#g-tick) `(D, Φ)`
pairs. When anchors exist, final divisors cannot live here. They do not exist
until `Δt_base` binds, and the same `Build` already backs many `Deployment`s
with different grid parameters.

#### The `Deployment`

**A `Deployment` is scalar-free** ([D-254][d-254]). It carries everything the
grid parameters fix. Its constructor sits after the build's three steps,
and nothing in them depends on it. The constructor consumes the `Build` and
the grid parameters. It binds the grid parameters, the algorithm and the three
event parameters, runs harmonic-grid validation, and builds the `Schedule`. The
`Deployment` it returns holds the build, the grid parameters, the algorithm,
the three event parameters, the `Schedule`, the grid diagnostics below and its
own `warnings`. `Simulation` materializes it at a scalar type `T`. Two
`Deployment`s compare as values, which is what replay's header check reads
([§12.7][s12-7]).

**`Δt_base` has exactly one of three sources**, cross-validated
([D-186][d-186]):

- the explicit keyword, a `Rational`, `Period` or `Hz` value, from which
  `N_base` is derived as `Δt_base/h` and validated an integer ≥ 1;
- the `N_base·h` product when only `N_base` is given, with the
  default `N_base = 1`;
- derivation, permitted only when every discrete component is anchored, that
  is, with anchor 0 unpopulated.

Derivation is requested explicitly:

```julia
Δt_base = :derive
```

It is never entered by default, so the `N_base·h` path stays what silence
means.

**If any unanchored component exists, deployment must declare `Δt_base`**
([D-186][d-186]). The refusal is constructive, carrying the suggestion message
of the grid diagnostics below. Under the anchored-only restriction, `Δt_base`
is pure bookkeeping that no component's period depends on. An unanchored
component's period is `m·Δt_base`. Deriving with one present would let an
anchor edit anywhere in the tree silently rescale it, which is action at a
distance.

Admissibility is exact GCD arithmetic over the constraint pool:

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
content of the `Schedule`, which the constructor builds and the `Deployment`
carries.

**Deployment validation is collected like its declarative siblings**
([§13.1][s13-1], [D-229][d-229]). Violations are collected and reported as
`DeploymentInvalid` ([Appendix C][sC]), carrying parameter, value and the
violated constraint:

- a nonpositive `h`;
- an `N_base < 1`;
- a harmonic-grid violation;
- a non-dividing anchor period or offset;
- a declared `Δt_base` disagreeing with a declared `N_base`;
- an algorithm the [stepper seam](#g-seam) does not know;
- a nonpositive `localization_tol`;
- a `localization_budget` or a `firing_budget` that is not an integer ≥ 1.

Every check whose premise holds runs, and the constructor throws once.

The event parameters validate on their own terms only. They are
grid-independent, so they take no part in the harmonic-grid check
([§10.4][s10-4], [§10.6][s10-6]).

The `Schedule` lives on the `Deployment` ([D-254][d-254]). The constructor
builds it from the structure's triples and anchors. It is typed.
It has one row per discrete component, carrying `(D, Φ, Δt)` with the anchor
and rate-chain columns. It also has the rate-scope rows, each with its own
`(Dₛ, Φₛ)`. The per-component `(D, Φ, Δt)` the executor compiles over are
derived from the rows at `compile`, never stored beside them
([D-261][d-261]). The `Schedule` is the single source of truth for `Δt`
([§10.5][s10-5]). It is also the substrate of the grid diagnostics below, and
the table that answers "when does what run, and what coincides with what".

The model worked in [§10.5][s10-5] has three discrete components under two
scopes, and that section's code block gives their `sample_times`. The root holds
a flight-control scope `fcs` and a discrete GNSS component `gnss`, declared as
`fcs = Relative(1)` and `gnss = Absolute(Hz(50))`. Deploy
it at `Δt_base = 2 ms`. The `Absolute` entry seeds the anchor
`A₁ = (1//50, 0)`, and the rest of the tree stays on anchor 0. So the three
components carry these values through binding:

| | `inner` | `outer` | `gnss` |
|---|---|---|---|
| declaration | `Relative(1)` under `fcs` | `Relative(5, 2)` under `fcs` | `Absolute(Hz(50))` at the root |
| anchor | `A₀` | `A₀` | `A₁` |
| triple `(m, c)` | `(1, 0)` | `(5, 2)` | `(1, 0)` |
| bound `(D, Φ)` | `(1, 0)` | `(5, 2)` | `(10, 0)` |
| bound `Δt` | 2 ms | 10 ms | 20 ms |

`gnss` is the entry whose divisor could not exist before `Δt_base` bound. Its
divisor is `D = m·D₁`, with `D₁ = T₁/Δt_base = (1//50)/(1//500) = 10`.

#### Rendering

**Each artifact renders itself through `show`**, with no accessors
([D-257][d-257]):

- `show(::Structure)` prints the anchor table with the `A₀` row and the
  component table with the [rate-scope](#g-rate-scope) rows (an assembly's
  `sample_times` declaration against the enclosing scope). The structure step
  records each face's routing chain at every level, and `show(::Structure)`
  prints the root's routes, one line per chain ([§13.7][s13-7]).
- `show(::Outputs)` prints the execution order with each port's class.
- `show(::Events)` prints each component's event names with their policies.
- `show(::Schedule)` prints the rows and the hyperperiod chart.
- `show(::Build)` and `show(::Deployment)` print a summary and their parts.
  `show(::Build)`'s parts include the events, and a line of the feedthrough
  edges between the outputs table and the events table. The edges are derived
  from the structure's connections and the producers' stage-2 names.

A REPL user gets each table by evaluating the value.

The chart's pattern repeats with period `lcm(Dᵢ)` base ticks, and the gate
(`(tick − Φ) % D == 0`, [§9.7][s9-7]) is pure modulo arithmetic. So one
hyperperiod is the complete truth, not a sample. The chart guard is binary.
**The chart prints whole, as a tick chart over `k = 0 … lcm(Dᵢ) − 1`, when
`lcm(Dᵢ)` is at most 100 base ticks**
([D-257][d-257]). Otherwise `show` prints the hyperperiod's length and
"chart omitted".

#### Grid diagnostics

**The grid diagnostics live on the `Deployment`** and print from the pool,
exactly ([D-254][d-254]). The refusal path's suggestion message and the
derivation path's info line share one substrate. That substrate is the
coarsest admissible `Δt_base` with the admissible set `gcd(pool)/k`, and
per-entry attribution. Attribution has two forms:

- Leave-one-out refinement factors are the first form.
  `r_p = gcd(pool ∖ p)/gcd(pool)` is an integer ≥ 1 read as "how much coarser
  the grid would be without this entry". **Every `r_p > 1` is listed** rather
  than one culprit crowned ([D-187][d-187]). That is because joint
  responsibility is the honest answer.
- Prime attribution is the second form. Each prime power of `1/Δt_base` is
  traced to the pool entries whose denominators supply it. That pinpoints what
  an edit changed.

When an offset is a driver, the message adds the nearest non-refining
alternatives, the admissible offsets on the grid the rest of the pool
supports. That turns the diagnostic into a repair.

**Blame is computed against the actual pool** ([D-187][d-187]). A
simple-fraction-of-its-period test stays authoring guidance and never becomes
the engine's.

The derivation path is the one place refinement happens silently. It always
prints the derived value with its drivers, and it carries the one advisory,
`GridUtilization` ([Appendix C][sC]). The advisory reports `min_i Dᵢ`, the
base ticks between the fastest component's ticks, as "grid is N× finer than
the fastest declared work" with the drivers named. It is information rather
than scolding, since a scope deliberately declared finer than its fastest
member to buy stagger room ([§10.5][s10-5]) legitimately inflates the metric.

#### Warnings

**A step that completes carries its warnings on the artifact**, and the entry
point logs each one once at return ([D-250][d-250]). A step that throws
renders its warnings with the collection it throws. Logging is presentation
and never a home ([§13.2][s13-2]).

A warning raised inside a declaration body has no artifact in hand. The build
binds a scoped channel around its three steps, and the helper appends to it
without knowing the build. The same helper called standalone, outside any
build, logs directly. That is how `EmptyFaceSelection` ([§8.8][s8-8]) reaches
the `Build`'s list.

The `GridUtilization` advisory is a deployment warning, so it lives on the
`Deployment`'s list and the constructor logs it once at return ([D-250][d-250]).

**`warnings(x)` is defined on `Build` and `Deployment`**, and on `Simulation` as
the concatenation of its artifacts' lists ([D-250][d-250]). It reads the
list. Warnings raised while mutating state stay in that state's status record
([§11.8][s11-8]), never here.

### 9.3 Probing and input synthesis

The build calls each user function once, as a [probe](#g-probe), to catch
malformed code early. Each call needs argument values, and not every argument
has a producer. This section covers, in order, the probe-everything scope,
probe argument sourcing and its two checks, root-input synthesis, probe
scoping, and the totality that stage code owes in return.

**The nominal evaluation probes every user function once**, at the initial
state, with real values ([D-050][d-050]). The set is the
stages, `x_deriv`, `s_update`, [guards](#g-guard), handlers and
`x_projection`. The probe checks shape and type conformance and discards the
results. All are pure, and the cost is one evaluation each.

"Fails loudly at build time where possible" ([§8.1][s8-1]) decides this. A
malformed `x_deriv` return must not wait for the first integrator step. Probes
see only the initial state's branch, so the marginal coverage is earliness,
not completeness. The always-on check ([§9.5][s9-5]) remains the completeness
backstop.

Probe arguments are sourced as follows:

- `x`/`s`/`m` come from `init_*` declarations, which declare by value.
- The stage-1 hand-down, `y_x` on the continuous [tier](#g-tier) and `y_s` on
  the discrete, comes from the stage-1 probes' *returns*. That hand-down is
  every stage-1 [port](#g-port) there is ([§5.2][s5-2]).
- Wired inputs come from upstream products.

Real values are available because the stage-2 chain is probed in topological
order. So every consumer is probed against the same value it will receive at
run time.

The [bundle law](#g-bundle)'s two remaining fields ([§5.2][s5-2]) are `ws`, the
[workspace](#g-workspace), and `t`. `t` is a clock value, sourced below with
`Δt`. **`ws` comes from invoking the component's `ws_init` allocator** at the
probing scalar (`Float64` at build), before the nominal evaluation's probes
that need it ([D-115][d-115]). The allocator runs that early because it reads
only the instance and the scalar ([D-077][d-077]) and derives nothing from
layouts.

Two checks ride the same pass. The first is the return's shape. A stage
returning something other than a `NamedTuple` fails here. The second is the
dead-stage rule. **A stage returning bare `(;)` produces no ports at all, and
is `DeadStage`**, fail-fast ([D-194][d-194]).

Exactly one kind of terminal has no producer, the
[root inputs](#g-root-input). **The build
synthesizes their values via `probe_value(::Type)`** ([D-051][d-051]).
Framework methods cover three kinds of type:

- `Real`, with `zero(T)`;
- `Bool`, with `false`;
- enums, with their first instance.

The ultimate fallback is the zero-argument constructor `T()`. That is where
well-behaved constrained types already put their valid default. For the
rotation-quaternion type, `RQuat()` is the identity. The `@kwdef`
convention supplies such a default broadly.

`probe_value` is overridable. A type whose valid default is not reachable that
way declares its own method. That method is also the [seam](#g-seam) a
[walked](#g-walked) type uses to state a constrained default. No method is a
build error, in the didactic style. It names the [face](#g-face) and the type,
and asks for one of the two fixes. An example is "no `probe_value` for
`Ranged{Float64, -1, 1}` at face `pilot.elevator_axis` — define
`probe_value(::Type{Ranged{Float64, -1, 1}})` or a zero-argument
constructor".

Synthesis never meets an abstract type. Root inputs are concrete by the
tight-bound rule, and the root-input type is the consuming entry evaluated at
`Float64` ([§8.2][s8-2]). [Abstract entries](#g-abstract-entry) only occur on
component-fed inputs, which the probe sources from upstream products.

Physically silly values are acceptable by construction. The probe checks
types, and return types that depend on input *values* are type instabilities,
banned by the branch-shape rule ([§8.3][s8-3]). The [§4.3][s4-3] write-side
granularity rule keeps root inputs predominantly scalar, so the surface is
small.

**Probe values are strictly probe-scoped** ([D-051][d-051]). Everything the
probe writes is garbage once the build finishes. Probe values never double as
initial root-input values, because that would smuggle in the default semantics
that [D-051][d-051] rejects.

The same doctrine covers the clock. **`t` is probe-scoped `0.0`**
([D-115][d-115]). Deployment binds no clock and `t₀` post-dates even
deployment ([§14.5][s14-5]), so `t` is a fabricated value. `Δt` in seconds
does not exist until the `Deployment` constructor binds `Δt_base`, since
deployment post-dates the build. Discrete-tier probes therefore supply a
placeholder period (`1.0`) in the bundle. It is a fabricated, probe-scoped
value like `t` and like any synthesized input. The probe checks types, not
physics.

`Simulation` must not reach its first [boundary](#g-boundary) with
uninitialized root inputs. **Every complete-world application, namely
`init!`, trim setup and trim commit, carries the pre-write
`UninitializedInputs` check** ([§14.6][s14-6], [D-149][d-149]).

Silly values are acceptable *because* the author is obliged to accept them.
That obligation is the author's side of the bargain. **Stage code must be
total over type-valid inputs** ([D-142][d-142]). Every probed user function
(stages, `x_deriv`, `s_update`, guards, handlers, `x_projection`) evaluates
without throwing on any input satisfying its declared types.

The domain is type-validity, not the probe's particular synthesized values.
The branch-shape rule already bans value-dependent return types. So types are
the only domain the framework can speak of, and the probe is the enforcement
moment, not the reason.

There are two consequence sites, with the same throw at both. At build it is a
`UserCodeFraming`-wrapped build failure ([§13.1][s13-1]). Its diagnostic
points at code that is "correct" on every trajectory it has ever seen. At
runtime it is a `StepError` and the run ends `errored` ([§13.4][s13-4]).
Exceptions from model code are always abnormal ([§13.5][s13-5],
[D-060][d-060]).

Three habits of shipped landing-gear code have sanctioned spellings:

- A *plausibility* check meaning "stop the run" is a published `Bool` output
  face plus `stop_on` ([§13.5][s13-5], [D-060][d-060]). A landing-gear strut
  model that throws on a touchdown overload is one such check. The face and
  `stop_on` are machinery already there.
- A *self-consistency* assert, such as an author checking that their own
  contact algebra cancels a velocity component to a hard tolerance, is a
  regression test about that algebra. Its home is the test suite
  ([D-142][d-142]). It is also the most probe-fragile of the three,
  since a near-degenerate synthesized geometry can keep the cancellation
  algebraically exact while missing an absolute tolerance in floating point.
- A *defensive exhaustiveness* branch is the third habit. Examples are an
  `else error("unrecognized surface type")` over a closed enum of ground-surface
  kinds, or a friction-coefficient constructor asserting an ordering of its
  arguments (static ≥ dynamic) when that constructor runs per step inside a
  stage.

A defensive-exhaustiveness branch is not banned validation but mislocated
validation. Totality
over a closed enum means handling every instance, and an `else error` is an
admission that the function is partial. **Parameter validation belongs where
user-controlled data enters** ([D-142][d-142]). That place is the constructors
of parameter and instance values. They run before the build, where asserts are
perfectly legitimate. Parameter validation never belongs inside a stage, on
probe-fed data.

### 9.4 Activations: executable sets, laziness, caching

By default, the build types the model only at `Float64`. Linearization and
gradient trim need the same model at another scalar type, a `Dual`. An
[activation](#g-activation) (the build's typed products at a given scalar
type) supplies that typing. This section states what an activation re-runs,
which functions it probes, when it runs, and what the `Build` caches.

**Only the activation step re-runs for a new scalar** ([D-259][d-259]). An
activation at `T` re-runs it with a different scalar and redoes five things:

- Producer-fed [cells](#g-cell) are re-typed by *walking* the producing
  [component](#g-component)'s output declaration at `T` ([§8.2][s8-2]). A
  continuous producer's declaration follows the scalar at every unpinned leaf.
  A discrete producer's declaration is read once and pins.
- [Root-input](#g-root-input) cells are re-typed by *walking* the consuming
  `u_types` entry at `T`. [§8.2][s8-2] reads that entry permissively. An
  unpinned entry follows the activation, and a `Pinned` entry stays frozen.
- The state type derived from `x_init` is re-derived by the leaf walk
  ([§8.2][s8-2]). The table and the flat `x` [buffer](#g-buffer) are laid out
  again.
- [Workspace](#g-workspace) allocators are invoked again, a continuous
  component's at `T` and a discrete component's at `Float64`
  ([D-263][d-263]). The activation does not introduce them. Their first
  invocation precedes the nominal evaluation's [probes](#g-probe)
  ([§9.3][s9-3]). A
  [continuous component](#g-continuous-component)'s scratch carries the
  activation's scalar ([§7.3][s7-3]).
- The probe chain runs again.

No [execution order](#g-execution-order) and no name list changes across
activations ([D-253][d-253]). [`Structure`](#g-structure) is the structure
step's product, and [`Outputs`](#g-outputs) is the nominal evaluation's.
Neither depends on `T`, by construction.

**Each activation probes exactly the set of functions it can execute**
([D-052][d-052]). A `Dual` activation, as linearization and gradient trim use,
evaluates the model at a frozen instant.

- Discrete stages are gated off and hold `Float64` values. This is the
  frozen-constant semantics of [§8.2][s8-2].
- [Guards](#g-guard) and handlers never run, because event localization runs
  as `Float64` [sweeps](#g-sweep) by design ([§10.4][s10-4]).
- Only the continuous output stages (`y_state`/`y_direct`) and `x_deriv` ever
  see a `Dual`. So only they are probed at it.

Probing the discrete stages, `s_update` or the guards at `Dual` would check
code against a number type it cannot receive.

The rule has no special cases. The [§5.6][s5-6] tracer activation follows it
identically. "Tracer activation" names the *global* set-tracer
([D-012][d-012]). It is a whole-model run at the tracer scalar, an activation
like any other. The cycle classifier ([§5.6][s5-6]) is the other tracer
variant ([D-012][d-012]). It traces each member of a cycle locally and needs
no execution order. It runs in the nominal evaluation's failure path and is
not an activation at all.

**Non-nominal activations run at first request**, not at build
([D-052][d-052]). Their dominant cost is compiling the continuous chain a
second time, at `Dual`, and for interactive use, such as flying the model by
hand, that cost is pure waste.

Laziness has a price, and the spec states it openly. A successful `build` does
not certify that the model is linearizable. A [pinned](#g-walked) `Float64`
([§7.2][s7-2]) can appear in two places. It may hide in a constructor. Or it
may be declared `Pinned` at a leaf that really participates, which is the
misplaced pin of [§8.2][s8-2]. Either one lurks until the first `Dual`
activation. The probe then fails and names the offending constructor or leaf.

Instead, the repository's test suite makes linearizability an invariant, held
by policy rather than advice. **Every component gets a `Dual` activation built
in CI** ([D-280][d-280]). An opt-in exhaustive mode does it:

```julia
build(world; activations = (Float64, ProbeDual))
```

This call runs the exhaustive set. It catches both genericity violations and
misplaced pins at PR time, at the cost of one activation per component. **The
keyword is the whole entry point**, and no separate check function exists
([D-275][d-275]).

The same keyword is also recommended for the parallel-sweep idiom
([§11.1][s11-1]). Pre-materialize the activations the sweep will need. The
shared `Build` is then a fully immutable artifact, with no synchronization on
any path.

**[`ProbeDual`](#g-probedual) is the framework's public canonical probe
scalar** ([D-099][d-099]).

```julia
const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}
```

It exists because an activation is keyed by a *concrete* scalar type. The bare
`Dual` is a `UnionAll`. It cannot key an activation, be walked
to, or answer `zero(T)`. The width of `ProbeDual` is arbitrary. CI pins
genericity, not any particular Jacobian. So one canonical width suffices, even
though [§14.10][s14-10] chunks at whatever widths it needs.

**The activation cache lives on the `Build` and holds only immutable compiled
artifacts** ([D-135][d-135]). It lives there because an activation is a pure
function of the build and the concrete scalar type. The cache is one
activation dictionary, keyed by concrete scalar type. Each entry holds
layouts, compiled plans and a validated flag. An entry is immutable once
constructed, and so it is freely shareable. The nominal `Float64` entry is one
key in the activation dictionary like any other ([D-253][d-253]). **Whether an
activation is cached never changes a result** ([D-052][d-052]).

**Every buffer set has exactly one owner** ([D-282][d-282]).

- The `Simulation` owns its nominal activation's buffers. They are
  materialized from the cached layouts at construction. The loop's
  zero-allocation stepping runs on them.
- Every service invocation owns the scratch set it instantiates from those
  same layouts. [§14.8][s14-8] states this for `trim!`. It is the general rule,
  not one local to trim.

So buffers are never cached.

Julia itself caches compiled code, process-wide. The framework cache saves the
expensive part, namely probe re-runs, layout construction, and Julia's
compilation of the `Dual` chain. These savings amortize in loops that reuse an
activation. One such loop computes a gain schedule over a grid of flight
conditions, where hundreds of trim-then-linearize points pay those costs once.

The per-point allocation of a working store set does not amortize. It is
O(model size), and trivial against the solve it feeds. The zero-allocation
invariant ([§7.5][s7-5]) covers only the stepping loop, and the services were
always allocation-tolerant. Nothing numerical is ever cached.

`Dual{Tag,V,N}` carries the partial count. A different seeding width is
therefore a different scalar type. It gets a separate entry and a separate
Julia compile.

**Lazy materialization is torn-state-free** ([D-281][d-281]). Concurrent first
requests for the same activation must never expose partially populated cache
state. Torn state is excluded by contract, not by luck. The mechanism is
unspecified. A guard around insertion suffices, paid at service time and never
on the hot path. An activation is a pure function of build and scalar, so the
worst benign race is duplicated work.

### 9.5 The always-on conformance check

The [probe](#g-probe) validates each function *once*, on the initial state's
branch. The schema-authority bargain's second clause ("at first execution
otherwise", [§8.1][s8-1]) is discharged by leaving the probe's comparison
permanently in place.

#### The generated write

At the point where the [executor](#g-executor) (the compiled form of the
stage [execution order](#g-execution-order)) stores a stage return into the
table, it holds the complete expected return type at this
[activation](#g-activation). The expected type is the type of the
[cells](#g-cell) this stage writes, as the probe fixed them at this
activation. It is one concrete `NamedTuple` type per
([component](#g-component), stage), the stage's declared names at the types
their cells hold ([§8.2][s8-2]). **The write is generated over that type and
the return's type** ([D-235][d-235]). So the test is decided when the write's
method is specialized, and no per-field instruction reaches the conformant
path.

When the write's method is generated, the return's key set is compared with the
expected type's. At the same point, each returned field is held to its cell's
type under the relation below. A conformant return type generates the straight
stores and nothing else. A non-conformant one generates a throw of the failure
payload, raised the first time that branch executes.

How the stage's code is typed decides what the check costs it:

- For type-stable conformant code, the compiler proves the return type, one
  method is generated, and no check instruction exists to delete.
- For branch-divergent code, each return type the stage can produce gets its
  own method, the union split the code already pays. The check is absent from
  every conformant one. The divergent branch's method is the loud located
  error at its first execution.
- Type-unstable-but-conformant code pays the dynamic dispatch it already
  bought, and nothing on top.

#### Pairing by name

**The names are the pairing**, and field order carries no semantics
([D-151][d-151]). The expected type's order is an internal fact. It is derived
from `y_types`, stage-filtered, an order no single declaration shows the author.
The author never reproduces it. A return spelling the right names at the right
types conforms in any order. The following two are the same return, of a
shaft's power `P` and torque `M_shaft`.

```julia
(; P = M*ω, M_shaft = M)
(; M_shaft = M, P = M*ω)
```

This is the general rule at every `NamedTuple` [seam](#g-seam) between author
and framework. [§14.7][s14-7] states it for the trim problem's decisions and
residuals. It is also what downstream consumption already assumes. The scatter
writes each returned field into its own *named* cell ([§4.3][s4-3]).
Order-sensitivity in the check would therefore be incidental strictness rather
than protection.

Pairing by name costs nothing. The generated write reads each returned field by
name and stores it into its cell, so no permutation of the value exists at
runtime. The per-field reasoning happens on types at generation and emits no
per-field instruction, which is how the check's economics ([D-053][d-053]) hold.
The check's one baked type test is resolved by dispatch rather than executed
([D-235][d-235]). The canary ([§7.5][s7-5]) verifies empirically that the check
folds away, rather than by assertion.

What is an error is a key-set mismatch or a per-field type mismatch, reported
by the [payload](#g-payload) below. A permutation is not an error at all. That
is equally why the payload's diff never has to express one.

#### Exact match and embed-accept

At the nominal activation, the only one that ever runs in real time, **the
check is an exact type match**, with no convert-on-write ([D-053][d-053]). It
is decided at generation and absent from the conformant path ([D-235][d-235]).
The error can afford to be didactic, as in "field `M_shaft`: expected
`Float64`, got `Int64` — return `zero(x.ω)`, not `0`".

Under a non-nominal activation (the build's typed products at a given scalar
type), the two leaf kinds the declaration ([§8.2][s8-2]) distinguishes,
walking and pinned, are checked differently. An opaque leaf has a rule of its
own. **A walking leaf, one
the author left unpinned, accepts exactly two types**, the activation scalar or
`Float64` ([D-053][d-053]). The activation scalar is the fast path, the
straight store. The executor embeds a `Float64` as a zero-partial constant
(`convert` through the leaf). Struct-valued [ports](#g-port) use the standard
cross-eltype constructor, and a missing one fails loudly with both types
named.

**An opaque leaf ([§4.3][s4-3]) embeds nothing into a store**, and it is
accepted there by identity alone ([D-237][d-237]). At a wire the entry is a
bound, and a frozen opaque arrival is admitted as the producer's cell
([§6.1][s6-1], [D-264][d-264]).

Nothing else is accepted. **The check is decided on the type**, not leaf by
leaf ([D-238][d-238]). The arrival with its `Float64` positions lifted to
the scalar wherever the declaration has one must be the declaration itself.
So a field name, a non-numeric type parameter or an array's mutability that
differs is refused like any other mismatch.

A [pinned](#g-walked) leaf takes the nominal-style exact check at *every*
activation ([D-238][d-238], [D-263][d-263]). A pinned leaf is one the author
wrapped as `Pinned`, or an `Int`, `Bool` or enum leaf that never walks. It takes
that check because its declaration said the leaf never carries partials. An
observed `Dual` there is the misplaced-pin error, that being the one honest
cause. The didactic hint is attached, "if `F` participates in differentiation,
remove its `Pinned`".

The embedding is exact, not lenient. Promotion is airtight and there is no
lossy `Dual → Float64` cast. So a `Float64` observed at a walking leaf means no
`Dual` entered its computation. Its true derivative along every seeded
direction is zero, which is precisely what the embedded constant says. This
scopes the blanket convert-on-write rejection to the nominal check
([D-053][d-053]).

#### Deliberate stripping

The bug the convert-on-write rejection guards against, silently zeroed
partials, cannot arise from honest code. The reason is that accidental
`Float64`s from `Dual` operands are impossible (`MethodError` at the operation
site). The residual is
deliberate stripping (`ForwardDiff.value`), a stated intent to discard
partials, producing a silent zero in the Jacobian. That is the stop-gradient
idiom. It is occasionally legitimate, as with deliberately frozen couplings
and opaque non-Julia wrappers. Applied mid-expression it is equally invisible
to a strict exact-match rule, so the leniency costs nothing.

But stripping need not be invisible to the schema. **The pinned leaf is
the schema-visible freeze** ([D-263][d-263]). An author who means to strip
declares the leaf `Pinned{Float64}` and strips inside the stage. The check
above holds the freeze to its word at every activation. Stripping
mid-expression at a leaf left unpinned remains legal and remains unseen, as
the sharp tool it is.

#### Per-function predicates

**The check is uniform across all probed functions** ([D-053][d-053]). Each
function is checked against its own predicate.

- **`x_deriv` checks against `X`'s own shape** at the activation's `T`
  ([D-190][d-190]). A scalar leaf expects a `T`, and an `SArray` leaf the same
  `SArray` at `T` ([§7.1][s7-1]). Its predicate is "every field scatters into
  its field's block at `T`". That predicate is what makes derivative
  completeness structural rather than a matter of author discipline.
- `s_update` checks against its leaf's `s` shape.
- Handlers check against the [§5.2][s5-2] return law, key by key.
- [Guards](#g-guard) check against their probe-derived
  [predicate](#g-predicate) form (below).
- **`x_projection` checks against `X`'s own shape** at `T`, complete
  ([D-111][d-111]). It is complete because its result is written back to the
  [buffer](#g-buffer) wholesale at both of the positions in the execution order
  ([§5.3][s5-3]), and because a [projection](#g-projection) with a
  mode-dependent branch first executes its second branch at run time. That is
  the same predicate as a handler's `x` key.

#### Handler returns

**The returned NamedTuple's key set is checked first** ([D-090][d-090]). An
unknown key, or a key naming a store the component does not declare, is a
build error with [did-you-mean](#g-did-you-mean) against `{x, m}` narrowed to
the stores that exist. That is the [bundle law](#g-bundle)'s classification
running in the return direction.

Then, per present key, `x` must be complete against the state field set,
while `m` may be partial ([D-053][d-053], [D-090][d-090]). `x` must also
be conformant at `T` like any state value. `m` is checked against a
names-subset-with-matching-types predicate, still a type-level computation
that folds when inferred. An absent key is not an error and not a no-op to
diagnose. It is the handler saying it does not touch that store.

The completeness asymmetry is storage-shaped. `x` must be complete because it
lives in a flat buffer written back wholesale. `m` may be partial because `m`
lives in per-field stores where a partial merge is the natural write.

#### Guard forms

The guard check is form-aware rather than a flat `isa Bool`
([D-053][d-053]). The reason is that guards have two admissible forms
([§2.1][s2-1]). A `Bool`-form guard's probed return is `Bool`, and a
sign-form guard's is the nominal scalar. Guards run only at the nominal
activation ([D-052][d-052]), so no parametrized-leaf case arises here. Any
other probed return type is a build error naming both admissible forms.

There is nothing further to check. The probed form *is* the detection policy
([§10.4][s10-4], [D-179][d-179]), so no form/policy mismatch can be declared.

#### The failure payload

**The payload carries the component path, the function, the event name on a
handler's occurrence, and the field-level diff** (missing / unexpected /
per-field expected-vs-observed) ([D-053][d-053], [D-249][d-249]). Simulation
time is the carrier's, not the diagnostic's. At run time the failure travels
as a [species](#g-species) of `StepError` through the single catch site
([§13.4][s13-4], [D-059][d-059]). That site's frame holds the boundary time
and the replay index. A build-time occurrence has no time to carry
([D-249][d-249]).

**The source branch is deliberately absent from the payload**
([D-053][d-053]). A value does not say which branch produced it, and the diff
identifies it.

The always-on input [trace](#g-trace) makes every such failure reproducible
by [replay](#g-replay) ([D-053][d-053]). The error names the
[boundary](#g-boundary) to replay to (`to_boundary`, [§12.7][s12-7]). The
catch site adds the loop-level nonfinite-state check as the failure's
divergence sibling ([D-157][d-157]).

### 9.6 Stopped-sim services as activation clients

Trim and linearization are stopped-sim services, and each is a client of an
[activation](#g-activation) (the build's typed products at a given scalar type).
This section is only a sketch, kept here because it grounds the build's steps.
The services themselves are [§14][s14]. The bullets take trim, the generic
service loop and linearization in turn.

- Trim is a loop that writes a [condition](#g-condition), runs a
  [sweep](#g-sweep) and reads the result, on an activation. By default trim is
  gradient-based and runs on the `Dual` activation, with its decision
  variables seeded through the `T`-generic assignment (the user's function from
  decision variables to a condition) for exact residual Jacobians
  ([§14.7][s14-7]). The derivative-free fallback runs the same loop
  on the nominal `Float64` activation, with no new activation needed. The
  always-on checks ride along either way. Decision variables stay opaque to
  the framework, and only the assignment's *output* is framework vocabulary.
- The generic service loop handles vectorization, optimizer setup, bounds
  packing and the solved-condition write-back, [root inputs](#g-root-input)
  included ([§14.8][s14-8]). It takes the [trace header](#g-trace-header)
  after the write-back. A failed trim leaves the simulation's stores untouched
  ([D-070][d-070]).
- Linearization is a `Dual` activation plus seeded sweeps
  ([§14.10][s14-10]). Gather and scatter over the canonical layout replace the
  hand-written per-aircraft state-space mapping layer. That replacement
  discharges the layer's deletion ([§7.1][s7-1]). Root inputs are the input
  surface.
  Frozen discrete outputs are constants with zero partials, which is exactly
  "linearize with the discrete state held" ([§8.2][s8-2]).

### 9.7 The compiled executor

The [execution order](#g-execution-order) exists in two representations at two
lifecycle stages. On [`Outputs`](#g-outputs) (the nominal evaluation's product,
the port classes and the execution order) it is plain printable data
([§9.2][s9-2]), namely paths, stage names and order. That data is the authoring
and diagnostic form. The [executor](#g-executor) compiles from that order
([D-253][d-253]). This section covers the other form, the one the loop runs.

#### The execution form

At `Simulation` construction, and per [activation](#g-activation) (the
build's typed products at a given scalar type), that data is compiled into the
execution form. **The execution form is a concretely-typed tuple of entries**
over statically typed [cell](#g-cell) storage, traversed by a
compile-time-unrolled walk ([D-086][d-086]). This is a forced move, not a
preference. The zero-allocation invariant ([§7.5][s7-5]), the fold-away
conformance test ([§9.5][s9-5]) and the zero runtime graph logic
([§5.1][s5-1]) are reachable only under full specialization.

An entry carries what selects code in type parameters, namely
[component](#g-component) type and stage. It carries what is plain data in
fields, namely [tick](#g-tick) divisor and [phase](#g-phase), the `Δt` of the
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives), and layout offsets. Gating compiles to
`(tick − Φ) % D == 0` inside the specialized *[boundary](#g-boundary)* body,
and the interior bodies hold no discrete entries to test ([§10.5][s10-5]).

#### Cell storage

**Cells are stored per element type**, not per cell ([D-162][d-162]). The
[signal table](#g-signal-table) is one contiguous block per element type, the
construction pointed at signals rather than state ([§7.1][s7-1]). A cell
address is a build-time offset into it. The offset is carried in an entry
*field*, with the [port](#g-port) type as the address's own parameter.
Gathers reconstruct and scatters flatten through the same leaf walk, so the
closed vocabulary earns its keep twice. This is the entry rule above paying
off. Two instances of one component type then differ only in field values,
share an entry type, and compile to *one* body.
By contrast, a store enumerating every cell in its own type, addressed by
index in the type domain, compiles one body per instance. It also grows the
store type with the model. The choice was measured rather than argued
([D-162][d-162], `prototypes/cellstore_bench`).

#### Phase bodies, arities and seams

**[Phase bodies](#g-measurement-seam) are the outer decomposition**, and they
are semantically forced ([D-086][d-086]). The blocks are as follows.

- The [boundary sweep](#g-sweep)'s stage-1 block, both tiers' `y_state`
  entries alike, is order-free by definition, because the
  no-[feedthrough](#g-feedthrough) stage reads no `u`.
- The stage-2 block gates in the [due](#g-due) discrete stages, those whose
  components this boundary admits by their compiled `(D, Φ)` pair. It is the
  only topologically ordered one.
- The `x_deriv` block is `rhs`, the [RHS](#g-flow) body the stepper calls per
  stage evaluation. The `s_update` block is `ticks`. Both are order-free with
  disjoint writes.
- [Guards](#g-guard) and handlers are their own small callables inside the
  [§10.6][s10-6] iteration.

**Each sweep block compiles in two arities** off one entry list
([D-147][d-147]). The arities follow the interior/boundary split that
[§10.5][s10-5] fixes.

- The zero-arg `sweep_1()`/`sweep_2()` are the interior variants, over
  continuous entries only. That is what makes `@ballocated(sweep_2()) == 0` a
  well-defined measurement *of the interior path*, rather than of whichever
  tick phase the simulation happens to be sitting in.
- The `sweep_1(tick)`/`sweep_2(tick)` forms are the boundary variants. They
  gate their discrete entries by `(tick − Φ) % D` against the passed tick
  index, symmetric with `ticks(tick)`.

`rhs` takes no index. One gate serves all three tick-sensitive blocks,
because due-ness is per component, per boundary, never per stage. **At a
localized event time `t*` ([§10.4][s10-4]), the empty due set is arity
selection**, not an index trick ([D-147][d-147], [D-185][d-185]). The `t*`
iteration therefore runs the zero-arg arities, whose compiled bodies contain
no discrete entries ([§10.5][s10-5]).

**These bodies communicate only through the stores and the table**
([D-194][d-194]). No value crosses a [seam](#g-seam), whether between passes,
between the blocks of one pass, or between [chunks](#g-chunking). The seams
therefore cost nothing, and the executor's decomposition stays free. Fusing a
step's sweep with its `x_deriv` block, or an event round's sweep with its guards
and fired handlers ([§10.6][s10-6]), is an optimization it may take or decline.

Two options this structure opens for free are recorded, not committed.

- The first is deterministic parallel evaluation of the order-free blocks.
  They have disjoint writes and no floating-point reductions to reorder,
  because [§6.2][s6-2] made every sum an ordered junction entry.
- The second is finer recompilation granularity. Editing a discrete
  component invalidates the boundary body, not the RHS body. That is literal
  under the two-arity split, since discrete entries exist only in the
  boundary variants.

#### Views and construction

**[Views](#g-view) are spelled rebuild-per-call** ([D-086][d-086]). Every entry
constructs its bundle at its own position. There is no framework-maintained
hoisting and therefore no cache-invalidation obligation. Hoisting belongs to the
code generator. Common-subexpression elimination (CSE) merges repeated loads
exactly where no intervening store invalidates them. That is precisely
[§7.1][s7-1]'s buffer-unchanged-within-a-sweep rule. The sweep-varying bundle
fields (`u`, `y_x`/`y_s`) are per-call by topological necessity either way
([§7.1][s7-1]).

**Construction is type-opaque**, and only the executor
specializes ([D-086][d-086]). Entry tuples are built from untyped buffers
and splatted once. Generic tuple utilities (range indexing, long `ntuple`
closures, naive recursion) are inference traps at the entry list's length,
since a 400-entry heterogeneous tuple can send generic `getindex` inference
into combinatorial collapse. The compiled tuple's type therefore has exactly
one consumer, the unrolled walk.

#### Compile cost

[Chunking](#g-chunking) bounds the compile cost. Within a large block the tuple splits
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

The mitigation ladder, in order. Activations are lazy ([§9.4][s9-4]), so a
session that never linearizes never compiles `Dual`. Non-nominal activations
may compile at reduced optimizer level, because their sweeps run inside
service loops where microseconds are irrelevant, a one-line per-module
policy. And activations bake into package images via ordinary precompile
workloads. An aircraft package exercising build-plus-one-sweep per
activation turns TTFX from a session tax into a CI artifact.

#### The measurement seam

**The phase bodies are the [§7.5][s7-5] measurement seam**
([D-116][d-116]). The accessor
below returns the compiled bodies of the nominal activation as named
callables bound over the simulation's own buffers.

```julia
phase_bodies(sim)
```

It returns four blocks.

- `rhs`, the `x_deriv` block.
- `sweep_1`, in both arities.
- `sweep_2`, in both arities.
- `ticks`, which takes the tick index its entries gate on.

Returned with them are the per-event guards and handlers and the
per-component `x_projection` callables, keyed by the model's own roster.

**The four-body roster is fixed and total** ([D-156][d-156]). The accessor
returns all of it always, whatever the model happens to declare. A model with
no discrete components, no events or no continuous state at all still gets
every body. The empty ones are legal, compile to no-ops, and their
`@ballocated` assertion passes vacuously. That is the point, because
consumers then iterate the roster uniformly, with no existence checks and no
per-model branching in the measurement code.

The seam is diagnostic only ([§13.5][s13-5]), and it makes one promise.
**These are the bodies the loop runs**, not re-derivations ([D-116][d-116]).
That is what makes the measurement honest, and why each callable carries the
real in-loop argument types by construction. A hand-built standalone test
cannot reproduce those types. [D-116][d-116] records why per-component tests
cannot discharge the invariant.

**CI is warm-then-assert over the roster** ([D-116][d-116]). One call
compiles, then CI asserts the following.

```julia
@ballocated(body()) == 0
```

It asserts at per-body granularity, each sweep arity in its own right
([D-147][d-147]), with the interior call bare and the boundary call at a due
index. So a documented [§7.5][s7-5] tolerance loosens exactly one assertion.

**Publication is not a phase body** ([D-116][d-116]). That is the
[§7.5][s7-5] carve-out made structural. What the accessor exposes is exactly
what the invariant claims is zero. Invoking bodies in isolation mutates the
simulation's buffers outside any [frame](#g-frame) sequence (a tick entry
advances discrete state with no clock advance). It leaves them valid but
off-trajectory. A session that wants to continue meaningfully re-runs
`init!`.

