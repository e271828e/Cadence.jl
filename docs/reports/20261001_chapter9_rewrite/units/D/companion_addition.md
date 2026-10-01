## 4. C172 trim today → the stopped-sim services

This case study reads today's C172 trim against the stopped-sim services that
[§9.6][s9-6] sketches and [§14][s14] specifies. The C172 trim problem
(`c172.jl`: `TrimState`, `TrimParameters`, `θ_constraint`, the `ẋ`-reading
cost) transfers near-verbatim. The items below take the assignment, the domain
math, the service loop and the failure behavior in turn.

- `assign!` inverts from in-place mutation plus self-invoked `f_ode!` to a pure
  function. That function returns a condition value (state by path, modes,
  root inputs by face), which the service writes and evaluates
  ([§14.7][s14-7]).
- Domain math survives aircraft-side, with one respelling. That math is the
  pitch constraint, `Kinematics.Initializer`, the per-residual scalings and the
  equilibrium-subset choice. The respelling is the initializer's. Its
  `atmosphere::Model` argument becomes a field handle ([§4.4][s4-4],
  [D-139][d-139]). The handle is built at value level by the atmosphere's
  value-level constructor, or held directly as a rig root-input value
  ([§14.1][s14-1], [§14.9][s14-9]).
- The generic service loop replaces today's per-aircraft NLopt plumbing
  ([§14.8][s14-8]).
- A failed trim leaves the simulation's stores untouched. That is an
  improvement over today's warn-but-assign `f_init!`.
