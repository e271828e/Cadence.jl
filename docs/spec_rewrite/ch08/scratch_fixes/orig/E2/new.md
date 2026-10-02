#### The leaves: integrate-and-difference

The IMU's leaves carry the idiom that answers integrate-and-dump
([§3.4][s3-4]). In integrate-and-dump, the IMU's direct formulation integrates
over each sample interval and zeroes its integrals at every sample. Algebra
can eliminate that reset, with no approximation. **Every interval-relative
integral becomes a *cumulative* one** ([D-056][d-056]). The sampler
differences against the previous sample, held in its `s`. That is the
textbook sampled-data latch. It is the only new store, the memory the reset
used to erase.

- *Raw increments* (linear). The cumulative integrals
  $\Theta(t) = \int_{t_0}^{t} \omega^{c}_{ic} \, dt$ and
  $\Upsilon(t) = \int_{t_0}^{t} f^{c} \, dt$ are never reset. The increments
  are $\vartheta_c = \Theta(t_k) - \Theta(t_{k-1})$ and
  $\upsilon_c = \Upsilon(t_k) - \Upsilon(t_{k-1})$.
- *Coning*. The cumulative attitude $q(t) = q_{c_0 \to c(t)}$ follows
  $\dot{q} = \tfrac{1}{2} \, q \otimes \omega^{c}_{ic}$ from identity at
  $t_0$. The interval rotation is $\Delta q = q(t_{k-1})' \circ q(t_k)$. It is
  exact by right-invariance, because $\Delta q$ satisfies the same ODE with
  the same body rate.
- *Sculling*.
  $\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt = q(t_{k-1})' \, ( V(t_k) - V(t_{k-1}) )$
  with $\dot{V} = q(t)(f^{c})$. The derivation takes two steps. First,
  re-anchor the rotation through the fixed $c_0$ frame,
  $R^{c_{k-1}}_{c} = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} R^{c_0}_{c}$. The
  re-anchoring lets the $c_{k-1}$-dependent factor, constant over the
  interval, exit the integral. What remains is the cumulative integrand.
  Second, split its range at $t_{k-1}$. That gives the difference of the
  running store:

  $$\int_{t_{k-1}}^{t_k} R^{c_{k-1}}_{c} f^{c} \, dt
  = (R^{c_0}_{c_{k-1}})^{\mathsf{T}} \left( \int_{t_0}^{t_k} R^{c_0}_{c} f^{c} \, dt -
  \int_{t_0}^{t_{k-1}} R^{c_0}_{c} f^{c} \, dt \right)
  = q(t_{k-1})' \, \big( V(t_k) - V(t_{k-1}) \big)$$

In code, the sculling result is the sampler line `υ_c_sc = s.q'(u.V - s.V)`.
The factor leaving the integral is the *anchor change between two
inertially-fixed frames*. It is constant because $t_{k-1}$ is in the past and
latched. The physical intra-interval rotation stays inside the integrand via
$q(t)$. That rotation is what sculling corrections are *about*. Every
evaluation of the [RHS](#g-flow) (`x_deriv`, the continuous derivative
function) applies the current cumulative attitude, RK stages included. The
direct formulation applies its current `q_c_cc`, its coning attitude
increment, in exactly the same way.

#### The exactness condition

**Interval-relative integrals factor into cumulative ones whenever the
interval dependence enters through a left action by the interval-start value
of a cumulatively-integrable quantity** ([D-056][d-056]). That action is the
identity for linear integrals, right-invariance for attitude increments, and
constancy of the anchor change for sculling.

Two provisos apply. First, **the cumulative attitude must be integrated with
the *inertial* rate** ([D-056][d-056]). The anchor frame is then inertially
fixed and the pulled factor rigorously constant. Anchoring to a rotating
reference breaks the factorization. Second, **the equivalence survives
discretization** ([D-056][d-056]). Quaternion kinematics is linear in `q`,
every RK stage composes on the right, and left multiplication by the constant
anchor commutes through. So the formulations agree to machine precision, not
merely in the continuous-time limit.

Never resetting has numerical consequences. `q` stays unit under
`x_projection`, which is better conditioned than the direct formulation's
`normalization = false` plus reset. `Θ`, `Υ` and `V` grow linearly, so
differencing loses relative precision. After an hour of flight that loss is
of order $10^{-11}\ \mathrm{m/s}$ per sample against
$10^{4}\ \mathrm{m/s}$ totals. That is six-plus orders below any error model
worth simulating.

#### The leaves in code

A few names in the code below need an introduction. `RQuat` is the domain
wrapper an attitude `SVector{4}` is cast to where rotation semantics are wanted
([§7.1][s7-1]). `Attitude.dt` gives the coning bullet's quaternion
derivative, and `RVec` turns the interval rotation `Δq` into the vector the
sample carries. `IMUSample` is the type of the sampler's `sample` output. `FrameTransform`
is one of the payload types [§7.2][s7-2] lists as walked.

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
    q = RQuat(x.q, normalization = false)              # §7.1's explicit cast
    (Θ = y.ω_ic_c, q = SVector{4}(Attitude.dt(q, y.ω_ic_c)), Υ = y.f_c_c, V = q(y.f_c_c))
end
x_projection(imu::IMUIntegrals, x) = (; x..., q = normalize(x.q))   # SVector normalize

struct IMUSampler <: AbstractComponent end
s_init(::IMUSampler) = (Θ = zeros(SVector{3}), q = SVector{4}(1.0, 0, 0, 0),
                        Υ = zeros(SVector{3}), V = zeros(SVector{3}))
u_types(::IMUSampler)  = (Θ = SVector{3,Float64}, q = SVector{4,Float64},  # discrete tier: bound check only
                         Υ = SVector{3,Float64}, V = SVector{3,Float64})
y_types(::IMUSampler) = (sample = IMUSample,)   # discrete tier: cells pin (frozen-exact)

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

The `IMU` assembly wires the four integral ports across. It holds the error
model as a discrete sibling consuming `sample`, and it leaves the sampler at
`K = 1` (its `sample_times` entry is `Relative(1)`) in its own scope. The
parent sets the IMU's rate ([§8.7][s8-7]). `Δt` arrives in the stage
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives) from its single source of truth, the deployment's `Schedule`
([§10.5][s10-5]). It is in the bundle for exactly this kind of discretized
law.

Initialization is consistent too. The sampler's `s` must equal the initial
integrals, or the `t₀` sample is wrong. That holds by default at
zeros/identity, and [boundary zero](#g-boundary-zero) discharges the rest.
Boundary zero is the initialization [boundary](#g-boundary) (a published
consistency point), run at `t₀`. There the sampler's
[due](#g-due) `s_update` (one scheduled to run at this boundary) latches
`s ← integrals(t₀)` for every subsequent sample ([D-067][d-067]). So only the
`t₀` sample itself depends on the authored `s`. That dependence is an
obligation on the author of the [condition](#g-condition) (the datum that
sets a build to a state) under trim ([§14.5][s14-5]).

#### Freshness at the sample

The sculling line is correct only because a due [tick](#g-tick) samples the
*completed* boundary. A tick is an instant at which a discrete component's
stages and update run. If `u.V` still held the previous boundary's decode,
it would equal `s.V` exactly, since that is the value `s_update` latched.
Sculling would then vanish without an error anywhere.

The guarantee is the boundary macro-sequence of [§10.6][s10-6], not a
scheduling accident. The sequence is integrate,
[project](#g-projection), [sweep](#g-sweep) (one pass through the execution
order). Projection is the `x_projection` hook, run after integration. The due
sampler's stages are gated *into* that sweep ([§10.5][s10-5]). The integrals
arrive at stage-1 position, returned by `y_state` ([§5.3][s5-3]). They arrive before
any stage-2 function runs, regardless of topological placement.

The rest of the timeline closes consistently. The sampler's `y_direct`
decodes `s`, the `t_{k-1}` latch, *before* `s_update` runs. That is the
`z⁻¹` semantics, the one-sample delay of sampled-data control. After event
[quiescence](#g-quiescence) (the point where an event round fires
nothing), `s_update` latches the `t_k` values for the next tick.
Same-boundary events re-run the gated stages in their re-sweeps. So
`s_update` and external readers see the settled boundary.

#### The boundary-sampling contract

The clean implementation leans on the author *knowing* that "sampling at
`t_k`" means post-integration, post-projection,
stage-1-fresh state. **That knowledge must be part of the framework's taught
contract**, not internal lore ([D-056][d-056]). The semantics of
[§10.5][s10-5] and [§10.6][s10-6] must be stated in component-author
documentation ([Appendix A][sA]), with this IMU as the worked example.

The failure mode of not knowing it is instructive. An author who distrusts the
sweep order adds a defensive one-tick delay or re-derives the integrals in the
sampler. Either one silently degrades the model.

**When the coupling is genuinely two-way, the latch becomes a wire back**
([D-056][d-056]). The IMU's coupling is one-directional, from integrals to
sampler. Suppose the flow itself needed the interval-relative value, say for
integrator saturation within the sampling interval. Then the sampler publishes
the sample-instant values from its *[feedthrough](#g-feedthrough)* stage (the
stage with an instantaneous input-to-output dependence). The continuous
`x_deriv` computes `x − u.latch`.

The feedthrough stage is the right one because `y_direct` reads `u`. The
latch port therefore carries the current tick's values, held by zero-order
hold (ZOH) until the next. A `y_state`-published latch would be one period
stale. Both cross-wires consume the other side's ports, and the feedthrough
graph stays acyclic. The integrals' stage 1 feeds the sampler's `y_direct`,
and the sampler's `y_direct` feeds the integrals' `x_deriv` edge
([§5.4][s5-4]). The "reset" becomes a visible tier-crossing feedback loop.
That is what it always was, physically.
