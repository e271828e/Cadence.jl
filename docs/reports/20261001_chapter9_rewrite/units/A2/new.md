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
