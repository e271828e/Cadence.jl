# E2 verify, phase 1 (blind read of new.md)

## The leaves: integrate-and-difference
- V1. The IMU's leaves carry the idiom that answers integrate-and-dump. [§3.4]
- V2. In integrate-and-dump, the IMU's direct formulation integrates over each sample interval and zeroes its integrals at every sample. [§3.4, by position]
- V3. Algebra can eliminate that reset, with no approximation.
- V4. (bold) Every interval-relative integral becomes a cumulative one. [D-056]
- V5. The sampler differences against the previous sample, held in its `s`.
- V6. That is the textbook sampled-data latch.
- V7. The latch is the only new store, the memory the reset used to erase.
- V8. Raw increments (linear): Θ(t) = ∫_{t0}^t ω^c_ic dt and Υ(t) = ∫_{t0}^t f^c dt are never reset.
- V9. ϑ_c = Θ(t_k) − Θ(t_{k−1}); υ_c = Υ(t_k) − Υ(t_{k−1}).
- V10. Coning: cumulative attitude q(t) = q_{c0→c(t)} follows q̇ = ½ q ⊗ ω^c_ic from identity at t0.
- V11. Interval rotation Δq = q(t_{k−1})' ∘ q(t_k).
- V12. Δq is exact by right-invariance, because Δq satisfies the same ODE with the same body rate.
- V13. Sculling: ∫_{t_{k−1}}^{t_k} R^{c_{k−1}}_c f^c dt = q(t_{k−1})' (V(t_k) − V(t_{k−1})) with V̇ = q(t)(f^c).
- V14. Derivation step 1: re-anchor through fixed c0 frame, R^{c_{k−1}}_c = (R^{c0}_{c_{k−1}})ᵀ R^{c0}_c.
- V15. Re-anchoring lets the c_{k−1}-dependent factor, constant over the interval, exit the integral; what remains is the cumulative integrand.
- V16. Step 2: split its range at t_{k−1}, giving the difference of the running store (display equation).
- V17. In code, the sculling result is the sampler line `υ_c_sc = s.q'(u.V - s.V)`.
- V18. The factor leaving the integral is the anchor change between two inertially-fixed frames.
- V19. It is constant because t_{k−1} is in the past and latched.
- V20. The physical intra-interval rotation stays inside the integrand via q(t).
- V21. That rotation is what sculling corrections are about.
- V22. Every evaluation of the RHS (`x_deriv`, the continuous derivative function) applies the current cumulative attitude, RK stages included. [glossary g-flow]
- V23. The direct formulation applies its current `q_c_cc`, its coning attitude increment, in exactly the same way.

## The exactness condition
- V24. (bold) Interval-relative integrals factor into cumulative ones whenever the interval dependence enters through a left action by the interval-start value of a cumulatively-integrable quantity. [D-056]
- V25. That action is identity for linear integrals, right-invariance for attitude increments, constancy of the anchor change for sculling.
- V26. Two provisos apply.
- V27. (bold) The cumulative attitude must be integrated with the inertial rate. [D-056]
- V28. The anchor frame is then inertially fixed and the pulled factor rigorously constant.
- V29. Anchoring to a rotating reference breaks the factorization.
- V30. (bold) The equivalence survives discretization. [D-056]
- V31. Quaternion kinematics is linear in q; every RK stage composes on the right; left multiplication by the constant anchor commutes through.
- V32. So the formulations agree to machine precision, not merely in the continuous-time limit.
- V33. Never resetting has numerical consequences.
- V34. q stays unit under `x_projection`, better conditioned than the direct formulation's `normalization = false` plus reset.
- V35. Θ, Υ and V grow linearly, so differencing loses relative precision.
- V36. After an hour of flight that loss is of order 10^-11 m/s per sample against 10^4 m/s totals.
- V37. That is six-plus orders below any error model worth simulating.

## The leaves in code
- V38. `RQuat` is the domain wrapper an attitude `SVector{4}` is cast to where rotation semantics are wanted. [§7.1]
- V39. `Attitude.dt` gives the coning bullet's quaternion derivative.
- V40. `RVec` turns the interval rotation `Δq` into the vector the sample carries.
- V41. `IMUSample` is the sampler's output struct.
- V42. `FrameTransform` is one of the payload types §7.2 lists as walked. [§7.2]
- V43. Code block: IMUIntegrals (field t_bc::FrameTransform; x_init Θ,q,Υ,V; u_types q_eb, r_eb_e, ω_eb_b, a_ib_b, α_ib_b; y_types exposed state (§5.3) plus instantaneous truth ω_ic_c, f_c_c).
- V44. Code comment: the four integrals are state, so stage 1 returns them (§5.3); y_state returns Θ,q,Υ,V.
- V45. Code comment: y_direct is strapdown kinematics (lever arm, gravity, Earth rate) → (; ω_ic_c, f_c_c).
- V46. x_deriv casts x.q with RQuat(normalization=false) ("§7.1's explicit cast"); returns Θ=ω_ic_c, q=Attitude.dt, Υ=f_c_c, V=q(f_c_c).
- V47. x_projection normalizes q (SVector normalize).
- V48. IMUSampler: s_init identity/zeros; u_types "discrete tier: bound check only"; y_types sample=IMUSample "discrete tier: cells pin (frozen-exact)".
- V49. Sampler y_direct reads s, u, Δt; computes ϑ_c, υ_c, Δq = q_s' ∘ q_u ("interval rotation, exact"), υ_c_sc = q_s'(u.V − s.V) ("constant anchor change pulled out"); IMUSample with ω̄ = ϑ/Δt, f̄ = υ/Δt, ϑ_c_cc = RVec(Δq)[:].
- V50. s_update latches u (the latch).

## After the code
- V51. The `IMU` assembly wires the four integral ports across.
- V52. It holds the error model as a discrete sibling consuming `sample`.
- V53. It leaves the sampler at K = 1 (sample_times entry Relative(1)) in its own scope.
- V54. The parent sets the IMU's rate. [§8.7]
- V55. `Δt` in the stage bundle (NamedTuple of zero-copy views a component function receives) is the single source of truth. [§10.5] [glossary g-bundle]
- V56. Δt is there for exactly this kind of discretized law.
- V57. Initialization is consistent too.
- V58. The sampler's `s` must equal the initial integrals, or the t₀ sample is wrong.
- V59. That holds by default at zeros/identity.
- V60. Boundary zero discharges the rest.
- V61. Boundary zero is the initialization boundary (a published consistency point), run at t₀. [glossary]
- V62. There the sampler's due s_update (one scheduled to run at this boundary) latches s ← integrals(t₀) for every subsequent sample. [D-067]
- V63. So only the t₀ sample itself depends on the authored s.
- V64. That dependence is an obligation on the author of the condition (the datum that sets a build to a state) under trim. [§14.5]

## Freshness at the sample
- V65. The sculling line is correct only because a due tick samples the completed boundary.
- V66. A tick is an instant at which a discrete component's stages and update run.
- V67. If u.V still held the previous boundary's decode, it would equal s.V exactly, since that is the value s_update latched.
- V68. Sculling would then vanish without an error anywhere.
- V69. The guarantee is the boundary macro-sequence of §10.6, not a scheduling accident. [§10.6]
- V70. The sequence is integrate, project, sweep (one pass through the execution order).
- V71. The due sampler's stages are gated into that sweep. [§10.5]
- V72. The integrals arrive at stage-1 position, returned by y_state. [§5.3]
- V73. They arrive before any stage-2 function runs, regardless of topological placement.
- V74. The sampler's y_direct decodes s, the t_{k−1} latch, before s_update runs.
- V75. That is the z⁻¹ semantics, the one-sample delay of sampled-data control.
- V76. After event quiescence (point where a round of handlers fires nothing), s_update latches the t_k values for the next tick.
- V77. Same-boundary events re-run the gated stages in their re-sweeps.
- V78. So s_update and external readers see the settled boundary.

## The boundary-sampling contract
- V79. The clean implementation leans on the author knowing that "sampling at t_k" means post-integration, post-projection, stage-1-fresh state.
- V80. Projection is the x_projection hook, run after integration.
- V81. (bold) That knowledge must be part of the framework's taught contract, not internal lore. [D-056]
- V82. The semantics of §10.5 and §10.6 must be stated in component-author documentation, with this IMU as worked example. [Appendix A]
- V83. An author who distrusts the sweep order adds a defensive one-tick delay or re-derives integrals in the sampler.
- V84. Either one silently degrades the model.
- V85. (bold) When the coupling is genuinely two-way, the latch becomes a wire back. [D-056]
- V86. The IMU's coupling is one-directional, integrals to sampler.
- V87. If the flow needed the interval-relative value (e.g. integrator saturation within the interval), the sampler publishes sample-instant values from its feedthrough stage (instantaneous input-to-output dependence).
- V88. The continuous x_deriv computes x − u.latch.
- V89. The feedthrough stage is right because y_direct reads u.
- V90. The latch port therefore carries the current tick's values, held by ZOH until the next.
- V91. A y_state-published latch would be one period stale.
- V92. Both cross-wires consume the other side's ports, and the feedthrough graph stays acyclic.
- V93. Integrals' stage 1 feeds sampler's y_direct; sampler's y_direct feeds integrals' x_deriv edge. [§5.4]
- V94. The "reset" becomes a visible tier-crossing feedback loop.
- V95. That is what it always was, physically.

Citations attached: §3.4, D-056 (x7, V4 V24 V27 V30 V81 V85 + none else), §7.1 (x2: prose and code comment), §7.2, §5.3 (x3: two code comments, V72), §8.7, §10.5 (x3), §14.5, D-067, §10.6 (x2), Appendix A, §5.4; glossary anchors g-flow, g-bundle, g-boundary-zero, g-boundary, g-due, g-condition, g-tick, g-sweep, g-quiescence, g-projection, g-feedthrough.
