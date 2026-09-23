# Cadence.jl

Cadence is a Julia framework for modeling and simulating hierarchical hybrid
systems. A model is a tree of components that exchange values through directed
ports, mixing continuous dynamics, multi-rate periodic discrete dynamics and
events. Its home domain is aircraft guidance, navigation and control, but the
formalism is domain-neutral.

## Status

Cadence is under active development and is not yet registered. Its API may
change without notice. The module exports nothing yet, so every name is
imported explicitly. Cadence requires Julia 1.12 or later.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/e271828e/Cadence.jl")
```

## Quick start

A continuous plant under a discrete PI controller running at 50 Hz:

```julia
using Cadence
import Cadence: AbstractComponent, init_x, init_s, input_types, output_types,
    output_state, output_direct, state_derivative, state_update,
    Group, Absolute, Hz, Simulation, init!, run!, fragment, port, state, build

struct Plant <: AbstractComponent
    ω::Float64
    ζ::Float64
end

init_x(::Plant) = (q = 0.0, v = 0.0)
input_types(::Plant, ::Type{T}) where {T <: Real} = (u = T,)
output_types(::Plant, ::Type{T}) where {T <: Real} = (y = T, power = T)

output_state(::Plant, (; x)) = (y = x.q,)                 # stage 1: state only
output_direct(::Plant, (; x, u)) = (power = u.u * x.v,)   # stage 2: reads inputs
state_derivative(p::Plant, (; x, u)) =
    (q = x.v, v = -p.ω^2 * x.q - 2p.ζ * p.ω * x.v + u.u)

struct PI <: AbstractComponent
    k_p::Float64
    k_i::Float64
end

init_s(::PI) = (integral = 0.0,)
input_types(::PI) = (ref = Float64, y = Float64)
output_types(::PI) = (u = Float64,)

output_direct(c::PI, (; s, u)) = (u = c.k_p * (u.ref - u.y) + s.integral,)
state_update(c::PI, (; s, u, Δt)) = (integral = s.integral + c.k_i * Δt * (u.ref - u.y),)

loop(feedback) = Group((plant = Plant(2.0, 0.3), ctl = PI(3.0, 2.0));
    wires = ("ctl/u" => "plant/u", "plant/$feedback" => "ctl/y"),
    inputs = "ref" => "ctl/ref",
    outputs = "plant/y" => "y",
    rates = (ctl = Absolute(Hz(50)),))

sim = Simulation(loop("y"); h = 1//1000)
init!(sim, fragment(inputs = (ref = 1.0,)))
run!(sim; t_end = 10.0)

port(sim, "plant", :y)    # 0.9654…
state(sim, "plant")       # (q = 0.9654…, v = 0.0120…)
```

The `import` list is part of authoring. A component extends the framework's
functions rather than calling them, and Julia allows that only for names
imported explicitly.

Each component has two output stages. `output_state` sees only the state, and
`output_direct` also sees the inputs. The build derives the execution order
from that split. Feeding back the plant's stage-2 `power` port instead of `y`
closes an algebraic loop, and the build refuses the model:

```
julia> build(loop("power"))
ERROR: DiagnosticError: 1 diagnostics
  AlgebraicCycle: algebraic loop among `plant`, `ctl`: plant/power → ctl/y, ctl/u → plant/u — real: a loop survives the trace (`ctl` structurally, the rest globally); break it with a state, a unit delay or a stage-1 (`output_state`) port (§5.5)
```

## Features

- Continuous dynamics on a fixed step, with events located by root-finding or
  checked at step boundaries.
- Multi-rate periodic discrete dynamics, held zero-order between ticks.
- An execution order derived from declared feedthrough. Algebraic loops are
  build errors that name the cycle.
- Zero-allocation stepping and type stability, both asserted by the test suite.
- A runtime data plane for devices, GUIs and scripts, with staged writes,
  snapshot reads and no shared mutable model.
- Bit-identical replay from a recorded input trace.
- Initialization and trim, with exact automatic-differentiation Jacobians.
- Structured diagnostics from a closed set of kinds, reported where the
  mistake was made.

Linearization, the GUI write path, real-time pacing and pausing are designed
but not yet built.

## Documentation

Cadence has no user manual yet. Its design is written down in full:

- `docs/design/spec.md` is the normative specification.
- `docs/design/decisions.md` records every design decision and the
  alternatives it rejected.
- `docs/design/companions/` holds worked explainers.
