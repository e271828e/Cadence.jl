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
