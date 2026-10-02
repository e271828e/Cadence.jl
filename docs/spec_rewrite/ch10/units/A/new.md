## 10. Time and execution

This chapter states how the loop runs a model through time. It takes the
execution order ([§5.3][s5-3]) and the compiled executor ([§9.7][s9-7]) as
given. [§10.1][s10-1] covers loop ownership and the loop's two units;
[§10.2][s10-2] the stepper seam; [§10.3][s10-3] signal-table consistency;
[§10.4][s10-4] localization mechanics; [§10.5][s10-5] multi-rate tick
scheduling; [§10.6][s10-6] event iteration at boundaries; and [§10.7][s10-7]
real-time pacing.

### 10.1 Loop ownership: the framework owns the simulation loop

This section defines the simulation loop's two units, lists its six activities
and states who writes the loop. The two units recur throughout the chapter,
and they mean different things.

- A [frame](#g-frame) is one grid step `[tₙ, tₙ₊₁]`. It is the unit of
  scheduling. Three things are keyed to it, namely the input
  [drain](#g-drain) (the frame-top swap that publishes staged device writes
  into the root inputs, [§11.4][s11-4]), pacer deadlines ([§10.7][s10-7]) and
  [tick](#g-tick) eligibility ([§10.5][s10-5]).
- A [boundary](#g-boundary) is a published consistency point. The boundary
  sequence ([§5.3][s5-3]) completes there, in the final form [§10.6][s10-6]
  calls the macro-sequence, and a [snapshot](#g-snapshot) (the immutable
  per-boundary publication) goes out.

Every grid point is a boundary, but not every boundary is a grid point.
`t*` is an event's crossing instant inside a step, bracketed by root-finding
([§10.4][s10-4]). **The [localized](#g-localized) event time `t*` is a
boundary but not a frame top** ([D-081][d-081]).
[Boundary zero](#g-boundary-zero) (the initialization boundary at `t₀`,
[§14.5][s14-5]) is a boundary and not a frame top either.

The loop consists of six activities. They are the boundary sequence
([§5.3][s5-3]), tick dispatch, event handling, logging, input staging, and
[pacing](#g-pacing) (waits inserted between completed frames, never altering
the boundary sequence).

**All six are framework code, unconditionally** ([D-017][d-017]). The framework
writes the loop itself. It does not assemble the loop out of callbacks
registered with a third-party solver. The reason is the step-boundary contract
(at every boundary the [§10.6][s10-6] macro-sequence completes before a snapshot
goes out). It is the central invariant of this design. Only a loop the framework
owns can enforce that contract by construction rather than by convention.
[D-017][d-017] records the rejected foreign-loop alternative.

**`OrdinaryDiffEq` is dropped as a dependency** of the new core
([D-017][d-017]).

### 10.2 The stepper seam

Loop ownership stops at one operation. That operation advances the continuous
state from `t` by `h`. **The framework delegates that operation across a
narrow internal interface**, the [stepper seam](#g-seam) ([D-017][d-017]).
The seam exists so that the integration method can be replaced without the
loop changing.

#### What the seam requires of a backend

The seam contract has four clauses.

- The backend advances by arbitrary `h`. The loop needs this anyway. It lands
  on [tick](#g-tick) [boundaries](#g-boundary), and it resumes from a
  [localized](#g-localized) event time (the crossing instant bracketed by
  root-finding over trial evaluations).
- The backend provides dense output on demand over the last completed step.
  Only event localization needs it ([§10.4][s10-4]), so the backend
  constructs it lazily.
- The backend uses one-step methods only. Event handlers reset state
  discontinuously, and a one-step method restarts from a new state for free.
  Multistep methods are excluded ([D-017][d-017]).
- The seam carries what a backend needs across a frame top through a
  checkpoint hook, empty for a single-step method. A
  [checkpoint](#g-checkpoint) is the executor's state at a frame top
  ([§12.6][s12-6], [D-274][d-274]).

#### Models with no continuous state

A model with no continuous state at all is legal ([D-156][d-156]). Nothing in
[§8.2][s8-2] requires an `x` block of any component. Such a model still has
to be run.

**The seam is never entered empty** ([D-156][d-156]). The framework
short-circuits this case rather than pushing it down the seam. With an empty
`x`, the integrate step degenerates to advancing `t` to the next boundary,
and the stepper is not called. No backend ever faces `N = 0`, and no backend
contract has to say what it would do there.

The loop-ownership rule ([§10.1][s10-1]) pays off structurally here. Under a
foreign solver loop, an empty state pays a dummy-`[0.0]` tax
([D-017][d-017]). Here that tax is gone at the root. Both the
[buffer](#g-buffer) (the contiguous vector backing all continuous state) and
the step over it disappear. Everything else about such a model is ordinary.
The boundary machinery of [sweeps](#g-sweep), events and ticks runs
unchanged.

#### The first-cut backends

**The first cut ships in-house fixed-step RK4 and Heun** over the flat state
buffer ([D-017][d-017]). Together they are about a hundred lines. They are
trivially zero-allocation, so they can be audited against the CI invariant
([§7.5][s7-5]). They are also trivially `T`-generic. Genericity is not even
required of the stepper, because linearization and the
[feedthrough tracer](#g-feedthrough-tracer) (the instrument that classifies a
rejected cycle as real or artificial, [§5.6][s5-6]) drive the *sweep*, never the
integrator.

**`RK4` is the default** of the two ([D-227][d-227]). The `algorithm` keyword
selects the backend by type on the [`Deployment`](#g-deployment) (the
scalar-free artifact the grid parameters fix). Materialization at
`Simulation` construction binds the stepper against the state buffer, on the
executor ([Appendix B][sB], [§9.2][s9-2], [D-227][d-227]). The step `h` has
no default and is required of the caller. A domain rate is not a framework
default.

An `OrdinaryDiffEq`-backed stepper can exist later as a package extension, if
an offline study genuinely demands adaptive or stiff methods
([D-017][d-017]). It is a [guarded addition](#g-guarded-addition) (a
capability the design admits but does not build), so it is not built until
then.

#### The case for fixed-step low order

The domain argument is recorded here because it is decisive for the choice
of integration method. It makes three claims.

1. Closed-loop ticks cap the step. Every application beyond bare propagation
   runs periodic avionics (onboard flight systems), whose commands are
   zero-order-held signals. Integrating past a tick with stale commands is
   wrong, so the integrator must land on every tick boundary regardless of
   method. Adaptive and high-order methods pay off exactly when steps can
   stretch, and the execution model forbids the stretch by construction.
2. A piecewise-smooth [RHS](#g-flow) (the continuous derivative function)
   starves high order. Linearly interpolated lookup tables (C¹-kinked at
   every knot), clamps, friction blends and mode branches deny high-order
   error estimators and implicit-solver Newton iterations the smoothness they
   assume.
3. Stiffness has a remedy ladder. If a future model exceeds RK4's stability
   region at the deployed `h`, the ladder runs in order. First shrink `h`. Then
   subcycle the stepper against the tick grid. Only then reach for an implicit
   method through the `OrdinaryDiffEq` extension above. If that day comes,
   eltype genericity ([§7.2][s7-2]) supplies exact ForwardDiff Jacobians through
   the sweep for free.

The Flight.jl evidence behind these claims lives in section 5 of
`companions/flight_case_studies.md`.

### 10.3 Signal-table consistency is a boundary property

During a step, the RK stages evaluate the [interior sweep](#g-sweep) (the
sweep variant over continuous entries only, [§10.5][s10-5]) at internal stage
states ([D-147][d-147]). While they do, the [signal table](#g-signal-table)
is transiently integrator scratch. The [boundary sweep](#g-sweep) in the
[§5.3][s5-3] sequence restores consistency at each accepted
[boundary](#g-boundary).

**External readers observe the signal table only at step boundaries**
([D-023][d-023]). These readers are the GUI, logging and network output.
Mid-step contents carry no meaning. This rule binds the
[periphery](#g-periphery) (everything outside the loop that exchanges data with
it, [§11][s11]). The rule extends naturally to the boundary sequence
([§10.6][s10-6]). External readers observe the table only after the boundary
sequence completes.
