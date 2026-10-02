## 10. Time and execution

### 10.1 Loop ownership: the framework owns the simulation loop

The simulation loop consists of six activities: the [§5.3][s5-3]
[boundary](#g-boundary) sequence, [tick](#g-tick) dispatch, event handling,
logging, input staging, and [pacing](#g-pacing) (waits inserted between
completed frames, never altering the boundary sequence).

**Rule.** All six are **framework code, unconditionally**. The framework
writes the loop itself. It does not assemble the loop out of callbacks
registered with a third-party solver.

**Why.** The step-boundary contract is the central invariant of this design.
Only a loop the framework owns can enforce that contract by construction
rather than by convention. Choreographing the same sequence as an ordered
`CallbackSet` inside a foreign event loop is rejected on exactly that ground
([D-017][d-017]).

`OrdinaryDiffEq` is therefore **dropped as a dependency** of the new core
([D-017][d-017]).

### 10.2 The stepper seam

Loop ownership stops at one operation: *advance the continuous state from `t`
by `h`*. The framework delegates that operation across a narrow internal
interface, the **[stepper seam](#g-seam)**. The seam exists so that the
integration method can be replaced without the loop changing.

#### What the seam requires of a backend

The seam contract has three clauses.

- **Advance by arbitrary `h`.** The loop needs this anyway. It lands on
  [tick](#g-tick) [boundaries](#g-boundary), and it resumes from a
  [localized](#g-localized) event time (the crossing instant bracketed by
  root-finding over trial sweeps).
- **Dense output on demand over the last completed step.** Only event
  localization needs it ([§10.4][s10-4]), so the backend constructs it lazily.
- **One-step methods only.** Event handlers reset state discontinuously, and a
  one-step method restarts from a new state for free. Multistep methods are
  excluded ([D-017][d-017]).

#### Models with no continuous state

A model with no continuous state at all is legal. Nothing in [§8.2][s8-2]
requires an `x` block of any component. Such a model still has to be run.

**The seam is never entered empty.** The framework short-circuits this case
rather than pushing it down the seam. With an empty `x`, the integrate step
degenerates to advancing `t` to the next boundary, and the stepper is not
called. No backend ever faces `N = 0`, and no backend contract has to say what
it would do there.

The ownership rule of [§10.1][s10-1] pays off structurally here. Under a
foreign solver loop, an empty state pays a dummy-`[0.0]` tax ([D-017][d-017]).
Here that tax is gone at the root. Not only the [buffer](#g-buffer)
disappears, but also the step over it. Everything else about such a model is
ordinary. The boundary machinery of [sweeps](#g-sweep), events and ticks runs
unchanged.

#### The first-cut backends

The first cut ships **in-house fixed-step RK4 and Heun** over the flat state
buffer. Together they are about a hundred lines. They are trivially
zero-allocation, so they can be audited against the CI invariant of
[§7.5][s7-5], and they are trivially `T`-generic. Genericity is not even
required of the stepper, because linearization and the tracer drive the
*sweep*, never the integrator.

Of the two, **`RK4` is the default**. The `algorithm` keyword selects the
backend by type on the [`Deployment`](#g-deployment) (the scalar-free artifact
the grid parameters fix), and materialization at `Simulation` construction
binds the stepper against the state buffer, on the
executor ([Appendix B][sB], [§9.2][s9-2], [D-227][d-227]). The step `h` has no default and is
**required** of the caller. A domain rate is not a framework default.

An `OrdinaryDiffEq`-backed stepper can exist later as a package extension, if
an offline study genuinely demands adaptive or stiff methods. Per the
guarded-additions rule it is not built until then.

#### Why fixed-step low-order suffices

The domain argument is recorded here because it is decisive for the whole
axis.

1. **The closed-loop tick cap.** Every application beyond bare propagation
   runs periodic avionics (50 Hz today), whose commands are zero-order-held
   signals. Integrating past a tick with stale commands is wrong, so the
   integrator must land on every tick boundary regardless of method. Adaptive
   and high-order methods pay off exactly when steps can stretch, and the
   execution model forbids the stretch by construction.
2. **A piecewise-smooth [RHS](#g-flow) starves high order.** Linearly
   interpolated lookup tables (C¹-kinked at every knot), clamps, friction
   blends and mode branches deny high-order error estimators and
   implicit-solver Newton iterations the smoothness they assume. RK4 at 50 Hz
   already puts integration error orders of magnitude below the model
   uncertainty of a coefficient-table aircraft model.
3. **Stiffness has a remedy ladder.** The fastest continuous dynamics in the
   current codebase sit inside RK4's stability region at `h = 0.02`. These are
   actuator poles near 31 rad/s, gear damper decay and friction compensators.
   The crosswind-landing demo is the empirical proof. If a future model
   exceeds that region, the ladder runs in order. First shrink `h`, since the
   RHS costs microseconds and 500 Hz real-time is unremarkable. Then subcycle
   the stepper against the tick grid. Only then reach for an implicit method
   through the adapter. If that day comes, the eltype genericity of
   [§7.2][s7-2] supplies exact ForwardDiff Jacobians through the sweep for
   free.

### 10.3 Signal-table consistency is a boundary property

During a step, the RK stages evaluate the [interior sweep](#g-sweep)
([§10.5][s10-5]) at internal stage states. While they do, the
[signal table](#g-signal-table) is transiently **integrator scratch**. The
[boundary sweep](#g-sweep) in the [§5.3][s5-3] sequence restores consistency
at each accepted [boundary](#g-boundary).

**Rule.** External readers (GUI, logging, network output) observe the signal
table only at step boundaries. Mid-step contents carry no meaning. This rule
binds the [periphery](#g-periphery) ([§11][s11]).


Two terms recur throughout, and they mean different things.

- A **[frame](#g-frame)** is one grid step `[tₙ, tₙ₊₁]`. It is the unit of scheduling. Three
  things are keyed to it: the input [drain](#g-drain) (the frame-top swap that publishes
  staged device writes into the root inputs, [§11.4][s11-4]), pacer deadlines ([§10.7][s10-7]) and
  [tick](#g-tick) eligibility ([§10.5][s10-5]).
- A **[boundary](#g-boundary)** is a published consistency point. The [§10.6][s10-6] macro-sequence
  completes there and a [snapshot](#g-snapshot) goes out.

Every grid point is a boundary, but not every boundary is a grid point. The
localized event time `t*` is a boundary, and so is [boundary zero](#g-boundary-zero) (the
initialization boundary at `t₀`, [§14.5][s14-5]). Neither is a frame top.

[§10.3][s10-3] extends naturally. External readers observe the table only
after the boundary sequence completes.
