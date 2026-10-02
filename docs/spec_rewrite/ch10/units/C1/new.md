### 10.5 Multi-rate tick scheduling

A model runs several clocks at once. The integrator advances on the continuous
step `h`. An inner control loop samples at one rate, an outer loop at another,
and a receiver at a third. Each of those must hold its outputs steady between
its own firings. For that to be well-defined, three things have to be fixed.
They are the time lattice every rate shares, the test that decides which
components run at a given [boundary](#g-boundary) (a published consistency
point), and the surface an author declares a rate on. This section fixes all
three, in that order.

#### The base grid and the gate

**Every discrete [component](#g-component)'s period is an integer multiple of a
base [tick](#g-tick) period `Δt_base`** ([D-019][d-019]). `Δt_base` is itself
an integer multiple of the continuous step, with `N_base` steps per base tick
($\Delta t_{\mathrm{base}} = N_{\mathrm{base}} \cdot h$, $N_{\mathrm{base}} \ge 1$).
That is the [harmonic grid](#g-harmonic-grid). Ticks therefore land on step
boundaries, which is the only place anything discrete ever happens.

[Frames](#g-frame) (iterations of the loop) are counted by the frame index
`k`. The frame top at `t = t₀ + k·h` is a base tick exactly when `k` is a
multiple of `N_base`. Its [tick index](#g-tick-index) is then
`tick = k ÷ N_base`. A frame top that is no base tick has no tick index, and
neither does a boundary at a localized event time `t*`
([§10.4][s10-4], [D-185][d-185], [D-288][d-288]).

However an author declares a rate, and however deeply the declaration is
nested, **the build compiles it to two integers per discrete component**
([D-185][d-185]). The divisor `D` is the component's period in base ticks. The
[phase](#g-phase) `Φ` is its offset in base ticks. The pair is kept in the
canonical residue `0 ≤ Φ < D`, so the component's ticks fall at base-tick
indices `Φ`, `Φ + D`, `Φ + 2D`, and so on.

**A component is [due](#g-due) at a boundary when `(tick − Φ) % D == 0`**,
where `tick` is the boundary's tick index ([D-185][d-185]). That subtraction
and remainder are the whole admission test. It costs one subtraction more than
a phase-free test would, over a lattice fixed at build time. The declaration
surface below says where a component's `(D, Φ)` comes from.

#### Zero-order hold and the two sweep variants

**A discrete component's `y_state`/`y_direct` run only at its own ticks**
([D-019][d-019]). Its [cells](#g-cell) (its entries in the
[signal table](#g-signal-table)) hold in between. This is zero-order hold
(ZOH), stated in [sweep](#g-sweep) terms. A sweep is one pass through the
[execution order](#g-execution-order). The reason for the hold is that
re-running a discrete component's stages at every boundary would un-sample a
sampled-data controller.

**Delivering that hold takes two statically distinct sweep variants, compiled
from one entry list** ([D-147][d-147]). Discreteness is a build-time fact, so
the split is static rather than a runtime test.

- The interior sweep walks continuous entries only ([D-147][d-147]). RK
  stage evaluations ([§10.3][s10-3]) and localization [guard](#g-guard) trial
  evaluations ([§10.4][s10-4]) run this variant. The ZOH therefore holds
  mid-step by construction. Discrete entries are not gated out at runtime.
  They are absent from the walk at compile time, so the hot path carries no
  gating test at all.
- **The boundary sweep walks the full list**, with discrete entries gated by
  `(tick − Φ) % D` against the boundary's tick index ([D-147][d-147]). It is
  the variant the [§10.6][s10-6] macro-sequence runs. It is not one fixed list
  either, because different boundaries run different subsets of the execution
  order.

**The split applies to both sweep blocks** ([D-147][d-147]). The discrete
[tier](#g-tier)'s `y_state` entries are absent from the interior stage-1 walk,
exactly as its `y_direct` entries are absent from the interior stage-2 walk.
The two sweep variants surface in the phase-body signatures: interior bodies
take no arguments, boundary bodies take the tick index ([§9.7][s9-7]).

#### Due sets

**The due set is computed once for the boundary and reused by every re-sweep
of its [quiescence](#g-quiescence) iteration** ([D-147][d-147]). Quiescence is
the fixed point where a round of handlers fires nothing ([§10.6][s10-6]). The
due set is a property of the boundary, not of the sweep call. That holds
because a due component is at its tick instant for the whole boundary, not for
one round of it.

Each kind of boundary has its own due set:

- At a tick frame top (every `N_base`-th frame top), the due set is every
  discrete component whose gate admits the tick index. These are the `(D, Φ)`
  pairs with `(tick − Φ) % D == 0`.
- At an off-tick frame top (a frame top with `N_base > 1` that is no base
  tick), the due set is empty. The tick counter has not advanced, so no
  component is at a tick instant.
- At a `t*` boundary, the due set is empty for the same reason. A modulo test
  against the unadvanced index would wrongly re-admit the previous tick's due
  set.
- At [boundary zero](#g-boundary-zero) (the initialization boundary, which
  runs the ordinary macro-sequence with an empty integrate), the due set is
  everything with `Φ = 0` ([D-185][d-185], [D-205][d-205]). At tick index 0 the gate reads
  `(0 − Φ) % D == 0`. Under the canonical residue `0 ≤ Φ < D` that holds if
  and only if `Φ = 0`. Nothing implements this rule. It falls out of the
  ordinary gate. Dueness at boundary zero governs the `s_update` calls alone.
  Output stages publish due or not ([D-205][d-205]), as [§14.5][s14-5]
  specifies.

An offset component's first tick is at `Φ·Δt_base`. Until then its cells hold
its boundary-zero publication. Its output stages still run at `t₀`, as above,
evaluated from the authored world ([D-205][d-205], [§14.5][s14-5]). The
[probe](#g-probe)'s synthesized values reach no published cell. The probe is the
build's single evaluation of a user function with real values ([§9.3][s9-3]). In
a phase-free model every `Φ` is 0, so at boundary zero everything is due and the
distinction is empty.

#### Simultaneous ticks

Several components can be due at one boundary, and settled machinery already
orders them. All due components run their output stages in topological order
within the sweep. All due `s_update` calls run after quiescence, in any order.
Each one reads the table and writes only its own `s` store. The intra-tick
ordering of a flight control system (FCS) cascade, where outer loops feed an
inner loop, is therefore a sweep property, not an update-order property.

#### Assemblies and rate scopes

**An [assembly](#g-assembly) is virtual for execution** ([D-019][d-019]). Its
children are scheduled individually, and the assembly itself never runs as a
unit. For declaration, a [rate scope](#g-rate-scope) is an assembly's
`sample_times` declaration against the enclosing scope. There are no atomic
assemblies, and no opt-in variant ([D-019][d-019]).

No coarsening is needed, because the signal table makes interleaving
semantically invisible. Consumers read cells whose freshness is guaranteed by
topological order rather than by contiguity.
