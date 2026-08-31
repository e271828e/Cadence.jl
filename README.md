# Cadence.jl

Cadence is a framework for simulating hierarchical models that mix continuous
dynamics, multi-rate periodic discrete dynamics and discrete events. It is
being built to replace `FlightCore` as the substrate for `FlightPhysics` and
`FlightApps` in Flight.jl, and it is not yet usable as a dependency: the
package exports nothing, and the implementation is a walking skeleton growing
one increment at a time behind a settled design.

The design is written down before it is built. `docs/design/spec.md` is
normative and defines the framework; `docs/design/decisions.md` records every
ruling and the alternatives it rejected. The code in `src/` implements that
document and feeds corrections back into it.

## What it simulates

A model is a tree of components over one hybrid formalism:

- **Continuous dynamics**, `ẋ = f(x, m, u, t)`, with algebraic outputs.
- **Multi-rate periodic discrete dynamics**, `s⁺ = g(s, u, t)` at declared
  rates, whose outputs are held zero-order between ticks.
- **Zero-crossing events**: a guard function and a handler, under two
  detection policies. A `Bool` guard is checked for edges at step boundaries
  and costs one evaluation per event per step. A sign-valued guard has its
  crossing instant located by root-finding, for the events where timing
  matters.
- **Manifold projection**: an optional `x ← project(x)` after each accepted
  step, for quaternion renormalization and anything else manifold-valued.
- **External inputs**, injected asynchronously by the runtime from devices,
  the network or a GUI.

Leaves are one tier or the other. Hybridness emerges at the assembly level,
where continuous vehicle parts meet discrete avionics parts.

## Authoring a component

A component is ordinary Julia. There is no macro DSL. Its structural facts are
declared by methods on a small set of framework generic functions, defined
beside the stage functions that compute with them:

```julia
import Cadence: AbstractComponent, init_x, input_types, output_types, h_x, h_xu, f

struct Oscillator <: AbstractComponent
    ω::Float64
    ζ::Float64
end

init_x(::Oscillator) = (q = SVector(0.0, 0.0),)
input_types(::Oscillator, ::Type{T}) where {T <: Real} = (u = T,)
output_types(::Oscillator, ::Type{T}) where {T <: Real} = (y = T, power = T)

h_x(::Oscillator, (; x)) = (y = x.q[1],)               # stage 1: state only
h_xu(::Oscillator, (; x, u)) = (power = u.u * x.q[2],) # stage 2: feeds through

f(c::Oscillator, (; x, u)) =
    (q = SVector(x.q[2], -c.ω^2 * x.q[1] - 2c.ζ * c.ω * x.q[2] + u.u),)
```

Three things in that listing carry weight.

The `import` line is authoring surface, not boilerplate. A component author
*extends* the framework's generics rather than calling them, and Julia admits
that only through an explicit per-name import. A bare `using` would leave
`f(::Oscillator, …)` defining a new unrelated function, silently, so the list
is written wherever a component is. Everything used further down — `Group`,
`Simulation`, `run!` — is imported the same way, the package exporting nothing
so far.

The declarations are the schema. `output_types` defines what the component
publishes; the build probes the stage functions with real values and checks
what they return against it. Types by declaration, values by execution,
conformance by comparison, never the reverse.

Outputs come in two stages. `h_x` sees state and time but no inputs, so
nothing consuming it acquires a dependence on this component's inputs. `h_xu`
sees inputs and feeds through. That distinction is what the next section is
about.

## Composition, and what the build makes of it

An assembly is children, connections and boundary faces. It has no dynamics of
its own:

```julia
loop(feedback_port) =
    Group((plant = Oscillator(2.0, 0.1), ctl = Gain(4.0), sum = Sum());
          wires = ("ctl/out" => "plant/u",
                   "sum/e"   => "ctl/e",
                   "plant/$feedback_port" => "sum/b"),
          inputs = "ref" => "sum/a",
          outputs = "plant/y" => "y")
```

Nothing here states an evaluation order. The build derives the schedule from
the declared feedthrough structure, and the two output stages are what make
that structure readable: `plant/y` is a stage-1 port, so routing it back into
the summing junction breaks the loop legally.

Route the feedback through the stage-2 port instead, and the model is refused:

```julia
julia> build(loop("power"))
ERROR: BuildError: AlgebraicCycle: algebraic loop through stage-2 ports:
plant → ctl → sum — break it with a stage-1 (`h_x`/`h_s`) port, which carries
no input dependence (§5.4/§5.5)
```

Refusals are like that throughout. A diagnostic is a value with a kind and a
payload, it names the parties involved, and where a check can collect rather
than fail on the first violation, it does.

## Running it

```julia
sim = Simulation(loop("y"); h = 1//1000)
init!(sim, fragment(inputs = (ref = 0.7,)))
run!(sim; t_end = 2.0)

port(sim, "plant", :y)      # a published port, by path and name
state(sim, "plant").q       # a component's continuous state
```

The framework owns the loop. `init!` takes an initial condition as a value
that resolves against the model's structure, and the run advances on a fixed
grid with events localized inside it.

## Design commitments

- **The schedule is derived, not authored.** Feedthrough is structural, so
  algebraic loops are a build error naming the cycle rather than a runtime
  surprise.
- **Zero-allocation stepping and type stability** are invariants the test
  suite asserts, not aspirations.
- **No shared mutable model.** The periphery writes by staging and reads by
  snapshot, so nothing outside the loop touches live state.
- **Deterministic replay is a guarantee.** RNG state lives in component
  discrete state and never in ambient globals, so the same seed gives a
  bit-identical trajectory. A recorded input trace re-drives the ordinary
  loop rather than a special one.
- **Failures are structured values.** One carrier exception, a closed set of
  diagnostic kinds, and compiler-style rendering.

What it deliberately excludes says as much. No DAEs, because projection covers
the actual need, which is state manifolds. No SDEs, because turbulence and
sensor noise are faithfully modeled as RNG-driven discrete processes, and that
choice is what buys deterministic replay. No unconditional per-step hook,
because every use of one decomposes into projection or a boundary-detected
event.

## Status

All design axes are settled, with a few items in §16 still open. The decision
log runs to 217 entries.

The prototype implements the formalism, the declaration layer, the build
pipeline, execution with multi-rate scheduling and event localization, the
runtime data plane with its trace and replay, error discipline, and the
stopped-sim services including trimming. It runs 1803 tests green. Not built
yet: the GUI write path, real-time pacing, linearization and mounting, and the
control plane's pause surface. `docs/design/implementation.md` keeps the full
list of what is absent and why.

The package exports nothing so far. Which names are public API is a
spec-driven question, still open.

## Repository layout

- `docs/design/` holds the design and the prototype's register. `spec.md` is
  normative, `decisions.md` is the log, `implementation.md` covers what `src/`
  and `test/` actually build, `companions/` holds worked explainers, and
  `tools/` holds the consistency checkers and the two style guides. Read the
  matching style guide before editing the spec or the log, and
  `implementation.md` before touching `src/`.
- `src/` is the `Cadence` package, `test/` its suite.
- `prototypes/` holds the frozen cell-store benchmark behind D-162 and a
  pre-design syntax sketch that no longer runs.

The repository was spun off from Flight.jl's `core-redesign-2` branch on
2026-08-29 and carries that branch's history.

## Commands

Run the test suite from the repository root:

    julia --project=. test/runtests.jl

Check the design documents' cross references:

    julia docs/design/tools/check_refs.jl

The other design tools sit beside it in `docs/design/tools/`.
