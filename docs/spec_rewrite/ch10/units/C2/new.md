#### The two declaration forms

A discrete component or sub-assembly is scheduled by a `sample_times` entry in
its enclosing assembly ([§8.7][s8-7]). **The entry declares one (period,
phase) pair in one of two unit systems**, and the wrapper type names the unit
system ([D-185][d-185]). The two forms thus declare one concept, a sample
time, in different units.

| entry | unit system | tick instants | constraints |
|---|---|---|---|
| `Relative(K, Φ = 0)` | scope ticks | every `K`-th tick of the enclosing scope, starting from its `Φ`-th | `K ≥ 1`, `0 ≤ Φ < K` |
| `Absolute(q, τ = 0)` | seconds | `t = τ + k·T`, with `T = period(q)` | `T > 0`, `0 ≤ τ < T` |

`K = 1` therefore admits no stagger ([D-185][d-185]). Two same-rate siblings
are staggered one level down instead. Declare the scope at twice their rate,
then give them `Relative(2, 0)` and `Relative(2, 1)`.

`q` is a quantity value, `Period(1//50)` or `Hz(50)`. The two are a spelling
choice, normalized to the rational period at construction. Every period and
offset is an exact `Rational{Int}`, because grid derivation is GCD arithmetic
and ill-defined over floats. A float argument throws the teaching error naming
the exact spelling (`Period(1//50)`, or `Hz(1//2)` for 0.5 Hz).

The wrappers are the whole vocabulary ([D-185][d-185]). A bare integer or bare
quantity is a declaration error. An unlisted discrete child defaults to
`Relative(1)`. The common case therefore costs nothing, and a multiplied or
anchored child (one declared `Absolute`, below) always appears explicitly.

Validation belongs to the structure step (the build's declaration-reading
step), which collects it with path attribution ([§9.1][s9-1], [§13.1][s13-1],
[D-185][d-185]). It covers `K ≥ 1`, `0 ≤ Φ < K`, `T > 0`, `0 ≤ τ < T`, and
keys naming discrete or scope children. The constructors themselves are plain
data carriers, with no checks of their own.

#### Relative composition

**Multipliers compose multiplicatively and phases affinely down the tree**
([D-019][d-019], [D-185][d-185]). Under a scope compiled to divisor and phase
`(D_s, Φ_s)` in base ticks, a child declared `Relative(K, φ)` compiles to
`D = K·D_s` and `Φ = Φ_s + φ·D_s`.

Composition preserves the canonical residue `0 ≤ Φ < D`.
`sample_time_proposal.md` (the declaration design's worked companion) carries
the one-line induction. All scoping therefore compiles away at build to one
`(D, Φ)` pair per discrete component. The boundary sweep gates on that pair
with the `(tick − Φ) % D == 0` test above. The lattice stays static, and the
interior sweep still holds no discrete entries to gate.

Relative is the default form because, in a layered control architecture, the
*ratios* are intrinsic to the design and travel with the assembly type. The
inner loop runs at `Relative(1)` and the outer loops at `Relative(5)`,
whatever the deployment. One convention keeps `K ≥ 1` livable. A scope's base
rate is its fastest relative member, and that member gets `K = 1`.

Two structural properties keep a relative entry on the scope grid and confine
grid cost to the other form. **A relative phase never refines the base grid**,
because it selects among scope ticks that already exist ([D-185][d-185]). It
also cannot place a tick *between* scope ticks. Staggering off-grid means
declaring the offset in seconds, or declaring the scope base finer than its
fastest member so that unused slots exist.

#### Anchors

**An `Absolute` entry may appear in any scope's `sample_times`, not only the
root's** ([D-186][d-186]). The `(T, τ)` pair it establishes is an
[anchor](#g-anchor), and the child hangs from that anchor. The child is
severed from the enclosing scope's grid, and no relation to the scope's ticks
remains.

Three corollaries follow ([D-186][d-186]):

- `K ≥ 1` reads "a child cannot tick faster than the scope it is *relative*
  to". An anchored child may therefore tick faster than its scope.
- The fastest-member convention counts relative members only.
- Phase relationships between an anchored child and its relative siblings are
  deployment-emergent. Whether their ticks ever coincide depends on how the
  grid derivation works out. The deployment's [`Schedule`](#g-schedule) (the
  per-component `(D, Φ, Δt)` table the `Deployment` carries) exists to answer
  that question ([§9.2][s9-2]).

Relative children *of* an anchored subtree compose against the anchor exactly
as against the root grid ([D-186][d-186], [D-283][d-283]). A nested anchor simply severs again
(the fold, [§9.1][s9-1]).

**Absolute periods and nonzero offsets jointly constrain the base grid**
([D-186][d-186], [D-283][d-283]). They join the deployment-time constraint pool
([§9.2][s9-2]). This is the subtle part, and it has a real cost. An offset of
`T/2` can cost a 2× finer grid, and `T/1000` a 1000× one. The cost is
relational, incurred against everything else declared. That is why
attribution is the engine's job ([§9.2][s9-2]).

#### When an anchor belongs in a library type

Absolute-first declaration as the default form is rejected ([D-019][d-019],
[D-186][d-186]). What mid-tree anchors legitimize is narrower, and the
doctrinal line falls here. **An absolute declaration inside a library type is
legitimate when the rate is a fact about the modeled system, not a preference
about the simulation** ([D-186][d-186]).

A GPS receiver emitting at 1 Hz, a data bus's transmission schedule and an ADC
(analog-to-digital converter) pipeline's fixed conversion offset are as
intrinsic to the assembly as its wiring. Forcing them to the root breaks
encapsulation, since the root would have to know instrument internals to
re-declare them.

"Run the controller at 400 Hz in this study" remains a deployment choice, and
the existing idiom remains its answer. The assembly exposes its multiplier as
a constructor parameter. Absolute pinning *from outside* a subtree's
[contract](#g-contract) (its declared interface) stays rejected as action at a
distance.

The framework cannot police the distinction. It is authoring doctrine,
recorded here.

**Anchoring leaves the never-cache-`Δt` argument below fully intact**
([D-186][d-186]). The pinning happens in the enclosing assembly's
`sample_times`, the same site where the multiplier lives. The component type
itself therefore stays rate-agnostic. It still consumes the `Δt` of its
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives).

#### A worked example

This example follows one declaration to its compiled pairs and one
hyperperiod. Three discrete components sit under two scopes, at a deployment
that binds `Δt_base = 2 ms` ([§9.2][s9-2]). The root scope holds `fcs`, a
flight control system (FCS) scope, and `gnss`, a satellite-navigation (GNSS)
component.

```julia
# Root scope: (D_s, Φ_s) = (1, 0).
sample_times(::Vehicle) = (fcs  = Relative(1),        # → (D, Φ) = (1, 0)
                           gnss = Absolute(Hz(50)))   # → (10, 0), anchored at T = 20 ms

# fcs is the enclosing scope of its own children, at (D_s, Φ_s) = (1, 0).
sample_times(::FCS) = (inner = Relative(1),           # → (1, 0)
                       outer = Relative(5, 2))        # → (5, 2), D = 5·1, Φ = 0 + 2·1
```

Those pairs are what the boundary gate reads at run time. One hyperperiod is
`lcm(Dᵢ) = 10` base ticks. Because the gate is pure modulo arithmetic, that
one hyperperiod is the complete truth rather than a sample ([§9.2][s9-2]):

```
base tick k:  0  1  2  3  4  5  6  7  8  9 | 0  1  …
inner         •  •  •  •  •  •  •  •  •  • | •  •       (D, Φ) = (1, 0)
outer               •              •       |            (5, 2)
gnss          •                            | •          (10, 0)
```

`outer` is due where `(k − 2) % 5 == 0`, `gnss` where `k % 10 == 0`. Should
`outer` read a `gnss` cell, the ZOH makes that read two base ticks old at
`k = 2` and seven at `k = 7`.

#### Coincidence and stagger

Coincidence and stagger are modeling choices with observable consequences.
Coincident ticks give a consumer fresh same-instant reads via topological
order. That is the idealized synchronous-sampling picture. A phase stagger
makes the same reads pipelined and deterministically aged instead. That is the
structural expression of an acquisition pipeline's latency, obtained with no
delay blocks. The two-tick and seven-tick reads in the example above are the
deterministic aging of a stagger, in that model's numbers.

A stagger is also a load-shaping tool under real-time [pacing](#g-pacing)
(waits inserted between completed frames, never altering the boundary
sequence). Staggered stacks never share a [frame](#g-frame), so worst-case
frame cost is a `max` rather than a sum ([§10.7][s10-7]).

Both patterns are worked in `sample_time_proposal.md`, together with how
silently an offset edit rewires a coincidence structure. The `Schedule` and
its hyperperiod chart ([§9.2][s9-2]) are how a user audits which pattern a
model actually has.

#### `Δt` in the bundle

`Δt` has a single source of truth, the deployment's `Schedule`
([D-187][d-187], [D-254][d-254]). **Each discrete component's effective period
arrives read-only as the `Δt` field of every discrete-tier bundle**
([§5.2][s5-2], [D-019][d-019]). The field arrives in `y_state`, `y_direct` and
`s_update` alike. It is absent from continuous bundles, so touching it on the
wrong tier is a missing-field error rather than a rule.

The field must be readable in the *stages*, not just in `s_update`. The
discretized laws that actually consume `Δt` run in `y_direct`, which computes
each law once and publishes it ([§5.3][s5-3], [D-015][d-015]). A PID
controller's backward-difference coefficients and a lead-lag compensator's
Tustin transform are the examples. `s_update` is a copy.

The value must arrive through the call, and the bundle field is where it
arrives. A `comp.Δt` virtual property is impossible here, not merely
inconvenient ([D-019][d-019]).

An author must never store `Δt`, or any `Δt`-derived coefficient, as a
component parameter ([D-019][d-019]). Recomputing derived coefficients per
tick is a few arithmetic ops. A cached copy is a second thing for
gain-scheduling machinery to chase.

Relative declaration structurally enforces that author rule for the period
itself. Under scoped multipliers a component author *cannot* know their
absolute rate. It does not exist until composition.

Phases change none of this. **The bundle's `Δt` is still `D·Δt_base`**
([D-185][d-185]). An offset shifts firing instants and never the period, so
the discretized laws are unaffected by staggering.

