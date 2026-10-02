#### The IMU's leaves: integrate-and-difference

The leaves carry the idiom that answers integrate-and-dump ([§3.4][s3-4]).
Algebra can eliminate the reset, with no approximation. Every interval-relative
integral becomes a *cumulative* one. The sampler differences against the
previous sample, held in its `s`. That is the textbook sampled-data latch, and
it is the only new store, the memory the reset used to erase.

- *Raw increments* (linear): $\Theta(t) = \int_{t_0}^{t} \omega^{c}_{ic} \, dt$,
  $\Upsilon(t) = \int_{t_0}^{t} f^{c} \, dt$, never reset;
  $\vartheta_c = \Theta(t_k) - \Theta(t_{k-1})$,
  $\upsilon_c = \Upsilon(t_k) - \Upsilon(t_{k-1})$.
- *Coning*: cumulative $q(t) = q_{c_0 \to c(t)}$ with
  $\dot{q} = \tfrac{1}{2} \, q \otimes \omega^{c}_{ic}$ from
  identity at $t_0$. The interval rotation is $\Delta q = q(t_{k-1})' \circ q(t_k)$, exact by
  right-invariance ($\Delta q$ satisfies the same ODE with the same body rate).
- *Sculling*:
  $\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt = q(t_{k-1})' \, ( V(t_k) - V(t_{k-1}) )$
  with $\dot{V} = q(t)(f^{c})$. The derivation takes two steps. First,
  re-anchor the rotation through the fixed $c_0$ frame,
  $R^{c_{k-1}}_{c} = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} R^{c_0}_{c}$, so that
  the $c_{k-1}$-dependent factor, constant over the interval, exits the
  integral. What remains is the cumulative integrand. Second, split its range
  at $t_{k-1}$, which gives the difference of the running store:

  $$\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt
  = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} \left( \int_{t_0}^{t_k} R^{c_0}_{c} f^{c} \, dt -
  \int_{t_0}^{t_{k-1}} R^{c_0}_{c} f^{c} \, dt \right)
  = q(t_{k-1})' \, \big( V(t_k) - V(t_{k-1}) \big)$$

  In code, this is the sampler line `υ_c_sc = s.q'(u.V - s.V)`. The factor
  leaving the integral is the **anchor change between two inertially-fixed
  frames**. It is constant because $t_{k-1}$ is in the past and latched. The
  physical intra-interval rotation, the thing sculling corrections are
  *about*, stays inside the integrand via $q(t)$. Every [RHS](#g-flow)
  evaluation, RK stages included, applies the current cumulative attitude,
  exactly as the direct formulation applies its current `q_c_cc`.

#### Exactness condition, stated once

Interval-relative integrals factor into cumulative ones whenever the interval
dependence enters through a *left action by the interval-start value of a
cumulatively-integrable quantity*. That action is the identity for linear
integrals, right-invariance for attitude increments, and constancy of the
anchor change for sculling. Two provisos apply. First, the cumulative attitude
must be integrated with the **inertial** rate, so that the anchor frame is
inertially fixed and the pulled factor rigorously constant. Anchoring to a
rotating reference breaks the factorization. Second, the equivalence survives
discretization. Quaternion kinematics is linear in `q`, every RK stage
composes on the right, and left multiplication by the constant anchor commutes
through, so the formulations agree to machine precision, not merely in the
continuous-time limit. Never resetting has numerical consequences. `q` stays
unit under `x_projection`, which is better conditioned than the direct formulation's
`normalization = false` plus reset. `Θ`, `Υ` and `V` grow linearly, so
differencing loses relative precision. After an hour of flight that loss is of
order $10^{-11}\ \mathrm{m/s}$ per sample against $10^{4}\ \mathrm{m/s}$
totals, six-plus orders below any error model worth simulating.

```julia
struct IMUIntegrals <: AbstractComponent
    t_bc::FrameTransform
end
x_init(::IMUIntegrals) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                          Υ = zeros(SVector{3}), V = zeros(SVector{3}))
u_types(::IMUIntegrals) =
    (q_eb = RQuat{Float64}, r_eb_e = SVector{3,Float64}, ω_eb_b = SVector{3,Float64},
     a_ib_b = SVector{3,Float64}, α_ib_b = SVector{3,Float64})
y_types(::IMUIntegrals) =
    (Θ = SVector{3,Float64}, q = SVector{4,Float64},            # exposed state (§5.3)
     Υ = SVector{3,Float64}, V = SVector{3,Float64},
     ω_ic_c = SVector{3,Float64}, f_c_c = SVector{3,Float64})   # instantaneous truth

# the four integrals are state, so stage 1 returns them (§5.3)
y_state(::IMUIntegrals, (; x)) = (; x.Θ, x.q, x.Υ, x.V)

# y_direct: strapdown kinematics (lever arm, gravity, Earth rate) → (; ω_ic_c, f_c_c)
function x_deriv(imu::IMUIntegrals, (; x, y))
    q = RQuat(x.q, normalization = false)              # [§7.1][s7-1]'s explicit cast
    (Θ = y.ω_ic_c, q = SVector{4}(Attitude.dt(q, y.ω_ic_c)), Υ = y.f_c_c, V = q(y.f_c_c))
end
x_projection(imu::IMUIntegrals, x) = (; x..., q = normalize(x.q))   # SVector normalize

struct IMUSampler <: AbstractComponent end
s_init(::IMUSampler) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                        Υ = zeros(SVector{3}), V = zeros(SVector{3}))
u_types(::IMUSampler)  = (Θ = SVector{3,Float64}, q = SVector{4,Float64},  # discrete class: plain
                         Υ = SVector{3,Float64}, V = SVector{3,Float64})       # form, bound check only
y_types(::IMUSampler) = (sample = IMUSample,)   # discrete class: cells pin (frozen-exact)

function y_direct(smp::IMUSampler, (; s, u, Δt))
    q_s = RQuat(s.q, normalization = false);  q_u = RQuat(u.q, normalization = false)
    ϑ_c = u.Θ - s.Θ;  υ_c = u.Υ - s.Υ
    Δq  = q_s' ∘ q_u                                   # interval rotation, exact
    υ_c_sc = q_s'(u.V - s.V)                           # constant anchor change pulled out
    (; sample = IMUSample(; ω̄_ic_c = ϑ_c / Δt, f̄_c_c = υ_c / Δt,
                            ϑ_c, ϑ_c_cc = RVec(Δq)[:], υ_c, υ_c_sc))
end
s_update(smp::IMUSampler, (; u)) = (Θ = u.Θ, q = u.q, Υ = u.Υ, V = u.V)   # the latch
```

The `IMU` [assembly](#g-assembly) wires the four integral [ports](#g-port)
across, holds the error model as a discrete sibling consuming `sample`, and
leaves the sampler at `K = 1` in its own scope. The parent sets the IMU's rate
([§8.7][s8-7]). `Δt` in the stage [bundle](#g-bundle) (the NamedTuple of
zero-copy views a component function receives) is the [§10.5][s10-5] single
source of truth, put there for exactly this kind of discretized law.
Initialization consistency also holds. The sampler's `s` must equal the
initial integrals, or the `t₀` sample is wrong. That holds by default at
zeros/identity, and [boundary zero](#g-boundary-zero) discharges the rest. Its
[due](#g-due) `s_update` latches `s ← integrals(t₀)` for every subsequent
sample, so only the `t₀` sample itself depends on the authored `s`. That
dependence is a [condition](#g-condition)-authoring obligation under trim
([§14.5][s14-5]).

#### Why `u.V` is fresh: the line that would silently zero

The sculling line is correct only because a due [tick](#g-tick) samples the
*completed* [boundary](#g-boundary). If `u.V` still held the previous
boundary's decode, it would equal `s.V` exactly, since that is the value
`s_update` latched, and sculling would vanish without an error anywhere.
The guarantee is the [§10.6][s10-6] macro-sequence, not a scheduling accident.
The sequence is integrate, project, [sweep](#g-sweep), with the due sampler's
stages gated *into* that sweep ([§10.5][s10-5]) and the integrals arriving at
stage-1 position, returned by `y_state` ([§5.3][s5-3]). They arrive before
any stage-2 function runs, regardless of topological placement. The rest of
the timeline closes consistently. The sampler's `y_direct` decodes `s`,
the `t_{k-1}` latch, *before* `s_update` runs, which is the `z⁻¹`
semantics. After event [quiescence](#g-quiescence), `s_update` latches the
`t_k` values for the next tick. Same-boundary events re-run the gated stages
in their re-sweeps, so `s_update` and external readers see the settled
boundary.

#### Sampling at `t_k` is a taught contract

The clean implementation leans on the author *knowing* that "sampling at `t_k`" means
post-integration, post-[projection](#g-projection), stage-1-fresh state. That
knowledge must be part of the framework's taught contract, not internal lore,
with the [§10.5][s10-5] and [§10.6][s10-6] semantics stated in
[component](#g-component)-author documentation ([Appendix A][sA]) and this IMU
as the [worked](#g-worked) example. The failure mode
of not knowing it is instructive. An author who distrusts the
[sweep](#g-sweep) order adds a defensive one-[tick](#g-tick) delay or
re-derives the integrals in the sampler, silently degrading the model.

**When the coupling is genuinely two-way, the latch becomes a wire back.** The
IMU's coupling is one-directional, from integrals to sampler. Suppose the
[flow](#g-flow) itself needed the interval-relative value, say for integrator
saturation within the sampling interval. Then the sampler publishes the
sample-instant values from its *[feedthrough](#g-feedthrough)* stage, and the
continuous `x_deriv` computes `x − u.latch`. The feedthrough stage is
the right one because `y_direct` reads `u`, so the latch [port](#g-port)
carries the current tick's values, ZOH until the next. An
`y_state`-published latch would be one period stale. Both cross-wires
consume the other side's ports, and the [feedthrough](#g-feedthrough) graph stays acyclic.
The integrals' stage 1 feeds the sampler's `y_direct`, and the sampler's
`y_direct` feeds the integrals' `x_deriv` edge ([§5.4][s5-4]).
The "reset" becomes a visible [tier](#g-tier)-crossing feedback loop, which is
what it always was, physically.

