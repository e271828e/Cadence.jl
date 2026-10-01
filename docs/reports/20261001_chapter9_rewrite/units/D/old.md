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
