## 5. Fixed-step RK4 on Flight.jl's aircraft model

This case study holds the Flight.jl evidence for the domain argument of
[§10.2][s10-2]. That argument claims that closed-loop ticks cap the step, that
a piecewise-smooth RHS starves high order, and that stiffness has a remedy
ladder. The items below take the three claims in turn.

- The periodic avionics of today's applications run at 50 Hz.
- RK4 at 50 Hz already puts integration error orders of magnitude below the
  model uncertainty of a coefficient-table aircraft model.
- The fastest continuous dynamics in Flight.jl's codebase sit inside RK4's
  stability region at `h = 0.02`. These are actuator poles near 31 rad/s,
  gear damper decay and friction compensators. The crosswind-landing demo,
  a Flight.jl demo of a landing in a crosswind, is the empirical proof. Shrinking `h` comes first on the
  ladder, since the RHS costs microseconds and 500 Hz real-time is
  unremarkable.
