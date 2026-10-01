# Unit D (§9.6) — phase 1 blind assertion list

## new.md
- V1. Trim and linearization are stopped-sim services.
- V2. Each is a client of an activation.
- V3. An activation is the build's typed products at a given scalar type (gloss).
- V4. This section is sketched here because it grounds the build's steps. (pointer/rationale)
- V5. The services themselves are specified in §14. [§14]
- V6. Trim is a loop that writes a condition, runs a sweep and reads the result, on an activation.
- V7. By default trim is gradient-based. [§14.7]
- V8. By default trim runs on the `Dual` activation. [§14.7]
- V9. Trim's decision variables are seeded through the `T`-generic assignment math. [§14.7]
- V10. That seeding gives exact residual Jacobians. [§14.7]
- V11. The derivative-free fallback runs the same loop on the nominal `Float64` activation.
- V12. The fallback needs no new activation.
- V13. The always-on checks ride along either way (gradient-based and derivative-free).
- V14. Decision variables stay opaque to the framework.
- V15. Only the assignment's output is framework vocabulary.
- V16. The generic service loop handles vectorization. [§14.8]
- V17. It handles optimizer setup. [§14.8]
- V18. It handles bounds packing. [§14.8]
- V19. It handles the solved-condition write-back, root inputs included. [§14.8]
- V20. It takes the trace header after the write-back.
- V21. A failed trim leaves the simulation's stores untouched. [D-070]
- V22. Linearization is a `Dual` activation plus seeded sweeps. [§14.10]
- V23. Gather and scatter over the canonical layout replace the hand-written `get_x_ss`/`assign_x_ss!` layer.
- V24. That replacement discharges the layer's deletion. [§7.1]
- V25. Root inputs are linearization's input surface.
- V26. Frozen discrete outputs are constants with zero partials. [§8.2]
- V27. That is exactly "linearize with the discrete state held". [§8.2]

## companion_addition.md (case study 4)
- C1. §9.6 sketches the stopped-sim services; §14 specifies them. [§9.6, §14]
- C2. The C172 trim problem (`c172.jl`: `TrimState`, `TrimParameters`, `θ_constraint`, the `ẋ`-reading cost) transfers near-verbatim.
- C3. `assign!` inverts from in-place mutation plus self-invoked `f_ode!` to a pure function. [§14.7]
- C4. That function returns a condition value (state by path, modes, root inputs by face). [§14.7]
- C5. The service writes and evaluates that condition value. [§14.7]
- C6. Domain math survives aircraft-side: pitch constraint, `Kinematics.Initializer`, per-residual scalings, equilibrium-subset choice.
- C7. With one respelling, the initializer's.
- C8. The initializer's `atmosphere::Model` argument becomes a field handle. [§4.4, D-139]
- C9. The handle is built at value level by the atmosphere's value-level constructor. [§14.1, §14.9]
- C10. Or the handle is held directly as a rig root-input value. [§14.1, §14.9]
- C11. The generic service loop replaces today's per-aircraft NLopt plumbing. [§14.8]
- C12. A failed trim leaves the simulation's stores untouched.
- C13. That is an improvement over today's warn-but-assign `f_init!`.
