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
