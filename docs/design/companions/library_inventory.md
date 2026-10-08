# The standard component library: the admission guidelines and the inventory

*A companion record, not normative text. The ground truth is `spec.md`
[§13.7][s13-7] (the library and the rig), [§6.2][s6-2] (junctions), [§5.5][s5-5] (loop breaking)
and [§2.1][s2-1] (events), with decisions [D-311][d-311], [D-312][d-312] and [D-313][d-313]. If this
document and the spec ever disagree, the spec wins. It was written on
2026-10-06, when the first tranche was briefed, to keep the reasoning that
pruned Simulink's base library down to the blocks worth shipping and to
hold the candidates for later tranches.*

## 1. Why Simulink's granularity does not transfer

Simulink's base library is large because the diagram is its expression
language. There is no other way to write `2u + 3` than a Gain and a Bias,
so Gain, Bias, Abs, Sign, Product, Min/Max, the trigonometric functions,
the relational and logical operators and type conversion all exist as
blocks. In Redstone a leaf's stage body is Julia. The block for `2u + 3` is
one line of `y_direct`, and the same expression as a separate component
costs a build entry, a cell, a gather and a scatter, plus the
per-component compile cost [§9.7][s9-7] measures. Shipping those blocks would also
teach the diagram-granularity style the design rejects. [§13.7][s13-7]'s phrase is
"Simulink's library is a language, while this is a toolbox".

A second group disappears for structural reasons:

- Sinks (Scope, Display, To Workspace) are the snapshot table, the log and
  the inspector.
- Terminator is unnecessary, because only inputs must be wired.
- Stop Simulation is a stop face ([§13.5][s13-5]).
- Goto/From are forbidden by the hierarchy rules ([§6.1][s6-1]).
- Bus Creator and Bus Selector are a struct or a named tuple port.
- Zero-Order Hold and Rate Transition are what the tiers and
  `sample_times` already do ([§10.5][s10-5], [§8.7][s8-7]).
- Enabled and triggered subsystems are assemblies and modes.
- Lookup tables are generic mathematics for a utility package, called from
  a stage body.

## 2. The admission guidelines

A block joins the inventory by judgement against three guidelines
([§13.7][s13-7], [D-313][d-313]). None is a requirement. A candidate is
weighed against them, it need not satisfy all three, and a block that
plainly belongs is not argued into them.

- **Domain-agnostic and generally useful.** Aerodynamics, engines and
  sensors belong in packages built on the framework.
- **Didactic value**, as when a block shows one framework mechanism in a
  relatively simple form. The mechanisms worth showing:
  - *Modes and events.* A limited integrator is not a clamp. It is a mode
    (saturated or not) with events for hitting and leaving each limit, and
    a derivative that reads the mode. A relay with hysteresis is a mode plus
    a pair of sign-form guards.
  - *Tier semantics.* `UnitDelay` moves a signal onto the discrete tier,
    which [§5.5][s5-5] calls a modelling decision. A discrete integrator or
    filter is the same kind of object.
  - *Activation and pinning.* Every library block walks under `Dual` for
    linearization and trim. A hand-written lag filter that types its
    scratch as `Float64` works at nominal and fails the first `linearize`.
  - *Structure the declaration layer forces.* The junction exists because
    every input takes exactly one wire. Wires name whole ports, so feeding
    one component of an `SVector` port to a scalar consumer needs a block.
- **An implementation that is difficult to get right.** The lag filter
  typed at `Float64` is the standing example.

A gain fails the second and the third, and section 1 prices it, so it stays
out. A listed block is built whenever wanted, with no demonstrating model
required. How the limited integrator's exact-zero defect was found, which
implementation variants were weighed against it, and why the block ships two
detection policies for its departures is `limited_integrator_variants.md`.
How the PID's anti-windup design space was weighed, why the block carries
two independent ports and what it does not carry is `pid_anti_windup.md`.
Why the linear system is two blocks, how a transfer function is realized
and why it takes a steady-state input and no `x0` is `linear_blocks.md`.

## 3. The inventory

Status is one of *shipped*, *candidate* (listed, built when wanted), or
*example first* (built as an example model, promoted only if one form
proves standard). A block is generic over its port type `V`, in the
[D-263][d-263] spelling, unless its ports are fixed by what it is: the `Bool`
gates, the PID and the linear blocks, whose ports follow their matrix
shapes. The port names are `in`, `in1…inN` and `out`, and `out1…outN` where a
block splits one port into `N` alike.

### Structure

| Block | Status | Mechanism |
|---|---|---|
| `Junction{In, Out, N, F}`, with `SumJunction{V, N}`, `Or{N}`, `And{N}` | shipped | one wire per input; the consumer's consolidated input |
| `Group` | shipped | the on-the-fly assembly ([§8.5][s8-5], [D-184][d-184]) |
| `Pack{V, N}`, a junction alias at a named fold, and `Unpack{V, N}` between scalar ports and an `SVector{N, V}` port | shipped | wires name whole ports |
| `Switch{V}` selecting between two inputs on a `Bool` | shipped | the `Bool` a junction's one `In` cannot type; the jump lands where the selector flips, so the event is the selector's producer's |

### Sources

| Block | Status | Mechanism |
|---|---|---|
| `Constant{V}` | shipped | the pinned source; the zero-contributor wire and the rig stub |
| `Step{V, L}` with a guard on the bundle's `t` in either form | shipped | the jump is localized, or lands on a step boundary, by the guard's form ([D-179][d-179]) |
| `Source{V}(f)`, a user function of the nominal `t` | shipped | covers ramps and sines without a block each; pinned ([D-312][d-312]): `t` is the activation scalar, stripped before `f` |
| `GaussianWhiteNoise{V}`, a discrete Gaussian white noise process, seed as instance data | shipped | a counter-based draw: the sample is a pure function of the seed and a tick counter, the store's one field ([D-231][d-231]), so the stage draws and no generator or workspace is needed; `σ` per sample, or the two-sided density `Q` read against the bundle's `Δt` as `σ² = Q/Δt` |

### Continuous dynamics

| Block | Status | Mechanism |
|---|---|---|
| `Integrator{V}` | shipped | walks under `Dual` |
| `LimitedIntegrator{V, L}` over `Real` or a `StaticArray` | shipped | a mode the derivative reads, and four events, the leave pair gated by the mode and strictly inward input; departures localized or boundary-detected, by `L` ([D-179][d-179]); modes as `Int8` codes, `4N` per-component events over a vector; `saturation` published |
| `FirstOrderLag{V}`, time constant as instance data | shipped | the actuator model and [§5.5][s5-5]'s α-filter idiom |
| a continuous rate limiter | not admitted | `q̇ = clamp((in - q) / τ, -R, R)` is one line, its kinks are second-order and its offsets decay; the discrete form is the block |
| `StateSpace` holding `A`, `B`, `C`, `D` as static matrices, scalar or `SVector` ports by the matrix shapes | shipped | `D` picks the stage, so the feedthrough class is a type parameter; `x0` in the user's coordinates; `linear_blocks.md` |
| `TransferFunction` from coefficient tuples, one input and one output | shipped | realized to a `StateSpace` at construction, the stage arms shared through the abstract `LinearBlock{FT}`; the class from the numerator's degree; started at rest or at the steady state for `u0`, never from an `x0`; `linear_blocks.md` |
| a continuous transport delay | not admitted | a history buffer indexed by the step; `extensions.md` item 4 |

### Discontinuities

| Block | Status | Mechanism |
|---|---|---|
| `Relay{V}` (hysteresis) over `Real` or a `StaticArray` | shipped | the reference mode-switching leaf; modes as `Int8` codes, `2N` per-component events over a vector |
| Saturation, dead zone | not admitted | one-line clamps, unless localization doctrine wants a declared kink |

### Discrete tier

| Block | Status | Mechanism |
|---|---|---|
| `UnitDelay{V}` | shipped | the tier's native `z⁻¹` ([§10.6][s10-6]) |
| `DiscreteIntegrator{V}` | shipped | tier semantics; forward Euler, `out` the state from `s0`, so it breaks a loop as `UnitDelay` does; no gain and no limits, as `Integrator` has none |
| `RateLimiter{V}` | shipped | tier semantics; feedthrough, `out` following `in` within `rising Δt` up and `falling Δt` down per tick from `s0`; its `s_update` stores `y.out` |
| `DiscreteStateSpace` and `DiscreteTransferFunction`, the pair in `z` | shipped | the continuous pair mirrored over `DiscreteLinearBlock{FT}`, `s_update` for `x_deriv`; the period is the scope's and the block cannot check it; `linear_blocks.md`, section 9 |
| `DiscretizedStateSpace` and `DiscretizedTransferFunction`, from a continuous system | shipped | the zero-order hold taken per tick at the bundle's `Δt`, so the class and the initial condition are the continuous ones; `linear_blocks.md`, section 9 |
| `DiscreteLimitedIntegrator{V}` | shipped | tier semantics by contrast: the continuous block's mode and four events are one `clamp` in `s_update`, with no mode store and no localization; `LimitedIntegrator`'s interface, `lower`, `upper`, `s0` and the `Int8` `saturation` code, the code read off the state from stage 1 |
| `Delay{V, K}`, a tapped delay | candidate | only if a model asks |

### Stop-gradient

| Block | Status | Mechanism |
|---|---|---|
| `Freeze{V}` over `Real` and `StaticArray` | shipped | the declared stop-gradient ([D-266][d-266]) |
| `Freeze` over a struct `V` | candidate | needs an allocation-free leafwise map ([D-312][d-312]) |

### Controllers

| Block | Status | Mechanism |
|---|---|---|
| `PID{Hold, Track}` | shipped | one law, `q̇ = Ki gate(e) + (ref - u_raw) / Tt`, with two independent ports: a saturation code that gates the integrator and a tracking reference; back-calculation against the own limits otherwise; `Ki` inside the integral; `pid_anti_windup.md` |
| `DiscretePID{Hold, Track}` | shipped | the positional law carried to the discrete tier, the ports, the gate and the reference rule shared through `PIDBlock{Hold, Track}`; forward Euler on the integral, backward Euler on the derivative filter so `τd = 0` is the backward difference, and the correction's step `1 - e^{-Δt/Tt}` so every `Tt` is stable and `Tt = 0` is instant; `pid_anti_windup.md`, section 9 |
| a gain-scheduled `PID`, gains as ports | candidate | the grouping admits a gain change bumplessly; built when a model asks |

The PID assembly of library blocks, the first variant as a `Group`, is an
example model in the tests, the inspector's example beside the block, not a
library row. A tracking leaf wired from a memoryless clamp of its own output
is refused as an artificial cycle ([§5.4][s5-4]), which is why the limits live inside
the block.

## 4. The order of work

The shipped rows are the first two tranches. The candidate rows follow in any
order, each when wanted. The example model `pending.md` queues under
"Outside the spec" is one source of further candidates: what it hand-writes
twice is a block to list. Packaging beyond the `Redstone.Blocks` submodule,
a workspace sub-package or a separate repository, is an after-release
question ([D-313][d-313]).
The blocks are unexported from `Redstone.Blocks` ([D-226][d-226]), so a model file
imports the names it uses, and a file that also loads ControlSystems
qualifies the two they share, `StateSpace` and `TransferFunction`.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-179]: ../decisions.md#d-179--derive-detection-policy-from-the-guards-return-type
[d-184]: ../decisions.md#d-184--fold-group-into-the-spec-as-an-ordinary-library-component
[d-226]: ../decisions.md#d-226--reach-the-public-surface-by-qualified-name-until-the-export-audit
[d-231]: ../decisions.md#d-231--require-isbits-store-values-checked-at-build
[d-263]: ../decisions.md#d-263--one-arity-on-both-tiers-plain-contracts-the-pinned-marker-and-the-mandatory-store
[d-266]: ../decisions.md#d-266--two-doors-for-an-ad-opaque-implementation-the-local-rule-and-the-freeze-block
[d-311]: ../decisions.md#d-311--fold-the-summing-junction-and-the-bool-gates-into-one-generic-junction
[d-312]: ../decisions.md#d-312--settle-the-leaf-blocks-constant-pins-unitdelay-holds-its-initial-value-freeze-strips-by-broadcast
[d-313]: ../decisions.md#d-313--admit-a-library-block-by-judgement-against-three-guidelines
[s10-5]: ../spec.md#105-multi-rate-tick-scheduling
[s10-6]: ../spec.md#106-event-iteration-at-boundaries-to-quiescence-budgeted
[s13-5]: ../spec.md#135-termination-is-a-state-not-an-exception
[s13-7]: ../spec.md#137-tooling-consequences-face-routes-and-the-component-library
[s2-1]: ../spec.md#21-events-two-detection-policies
[s5-4]: ../spec.md#54-artificial-loops-and-the-escape-hatch
[s5-5]: ../spec.md#55-algebraic-loop-policy-reject-at-build-time
[s6-1]: ../spec.md#61-connections-and-hierarchy
[s6-2]: ../spec.md#62-aggregation-explicit-summing-junctions
[s8-5]: ../spec.md#85-assembly-declaration-type-based-class-by-declaration-shape
[s8-7]: ../spec.md#87-rate-scopes
[s9-7]: ../spec.md#97-the-compiled-executor
