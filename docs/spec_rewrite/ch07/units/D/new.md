### 7.4 The fused-evaluation lineage (prior art and how we got here)

Overlap between derivatives and outputs is the norm in physical and control
models ([§5.3][s5-3]). The [§5.2][s5-2] interfaces are the end point of a
four-step simplification arc. The arc is recorded here because each step
replaced a mechanism with something smaller. The section gives the four steps,
then the prior art, then an idiom the design admits without framework support.

1. N output groups gave way to exactly two ([D-006][d-006]), at the price of an
   occasional [component](#g-component) split ([§5.4][s5-4]).
2. Derivative binding gave way to own-output access ([D-015][d-015]). Passing
   the fresh [signal table](#g-signal-table) to `x_deriv`/`s_update` subsumes
   the declaration feature, and the "binding" becomes a one-line function body.
3. Separate state arguments gave way to the state decoder ([D-016][d-016],
   [D-035][d-035]). Step 4 later reversed the second half of this step.
4. Decoder-exclusive state access gave way to stores-and-views arguments.
   Step 3's second half was reversed ([D-035][d-035]). Once contract
   visibility ([§8.3][s8-3], [D-034][d-034]) made a port's publicity a
   declaration, the identity decode stood revealed as *transport*. It copied
   the [buffer](#g-buffer) into [cells](#g-cell) so that a buffer view could be
   replaced by a cell view. The fixed point is the argument rule
   ([§5.2][s5-2]). A function receives zero-copy views of the stores it
   genuinely reads. What survives of step 3 is the uniform shapes, the fused
   economics, and the stage-1 decoder itself (now `y_state`). That decoder is
   no longer the sole state gate. It is the no-[feedthrough](#g-feedthrough)
   stage.

Every causal framework meets the shared-computation problem and resolves it
per its architecture. The prior art is given here for orientation. Simulink
diagrams make integrators explicit blocks. Derivatives are ordinary wires into
`1/s`, and the computer/integrator split is their native idiom. S-functions and
FMUs use sanctioned *mutable caches* between their
`mdlDerivatives`/`mdlOutputs`-style callback pairs. The caches are DWork
vectors and FMI's lazy-evaluation caching. Modelica/MTK (ModelingToolkit)
write `der(x) = expr` natively, with symbolic common-subexpression
elimination. The fused [sweep](#g-sweep) plus signal-consuming
`x_deriv`/`s_update` is the cache-free formulation that fits this design's
purity rules ([D-015][d-015]). It is also what FlightCore's fused `f_ode!`
(its in-place derivative function) did economically, minus the checked
ordering.

The computer/integrator split remains fully expressible without any framework
support ([D-015][d-015]). A stateless component computes derivatives as
outputs and is wired into a trivial state-holding component. It is the idiom
of choice when the factoring earns reuse. Two examples are one Newton–Euler
solver shared across vehicle variants, and swappable kinematic descriptors
against a common integrator shape. Against a split-form spelling of a
rigid-body kinematics and dynamics core (four components, thirteen
connections), the merged form has half the components and wiring
([D-015][d-015]). Everything derivable from pose alone migrates to stage 1,
shortening the stage-2 chain.

### 7.5 Allocation policy: a scoped invariant

The allocation policy is not dogma ([D-014][d-014]). Three reasons support it,
and only one is about speed. The first is GC-pause jitter control for
real-time. The second is throughput for [unattended runs](#g-unattended-run)
(runs with empty staging and no snapshot readers). The third is the canary. An
unexpected allocation is Julia's most reliable symptom of type instability. A
zero baseline therefore makes `@allocated == 0` a CI-testable invariant. That
invariant catches inference regressions at the offending commit. The section
states the invariant's scope, the policy's three tiers, what the
[log](#g-log) does not record, and the tools for garbage that cannot be
avoided.

The zero-allocation invariant is scoped to the stepping loop, and the
stopped-sim services were always allocation-tolerant ([D-135][d-135],
[§14.8][s14-8]). Publication is not a phase body ([D-288][d-288],
[§9.7][s9-7]), and its one snapshot allocation per
[boundary](#g-boundary) sits with logging on the framework side, outside what the
invariant claims is zero ([§11.2][s11-2]).

The policy has three tiers.

- The continuous hot path is per-stage evaluation, plus everything else that
  runs unconditionally per frame or boundary. Those
  unconditional items are [guards](#g-guard), evaluated every boundary whether
  they fire or not, and `x_projection` at both of its [§5.3][s5-3] positions in
  the [execution order](#g-execution-order). **The budget is exactly zero,
  CI-enforced** at the phase-body [seam](#g-seam) that `phase_bodies` exposes
  ([§9.7][s9-7], [D-014][d-014], [D-116][d-116]).
- Periodic [ticks](#g-tick) and event handlers execute episodically. A tick
  runs when due, and a handler only on firing. Their allocation is zero by
  idiom. The idiom is the [workspace](#g-workspace) (component-declared mutable
  scratch arriving as the `ws` bundle field) and snapshot pattern, plus
  immutable-value returns. The rare exception has a documented tolerance
  ([D-116][d-116]). The seam's granularity scopes the tolerance per body, so the
  tolerance never loosens the continuous assertions.
- Logging is amortized-zero. The log retains the published snapshot
  objects themselves, by reference ([§11.2][s11-2], [D-137][d-137]). It keeps
  one slot per retained boundary and makes no copy. `sizehint!` to the
  retention bound makes regrowth a non-event.

  The allocation claim is about the snapshot's *fields*, not about everything
  reachable from them. A model carrying [§4.4][s4-4]
  [field handles](#g-field-handle) (immutable query objects consumers evaluate
  at their own arguments, such as heightmap terrain or wind grids) has a
  snapshot type with reference fields. Those fields ride as references to
  build-time-frozen data, with no copy and no per-boundary garbage. That is
  what the allocation claim asserts. The claim does not assert that the
  snapshot is `isbits`. The per-boundary allocation cost is zero either way.
  The summarize-or-skip rule ([§4.4][s4-4]) governs what such a field
  contributes on export.

Event firings are not recorded. The log holds boundary snapshots and the
[trace](#g-trace) holds staged inputs ([§11.2][s11-2], [§11.5][s11-5]).
Neither carries a per-event record. [Replay](#g-replay) plus the published
modes recovers which events fired at which boundary. The honest remedy is to
declare the mode field public and return it from `y_state` ([§11.2][s11-2],
[D-252][d-252]). A mode field so exposed is in every snapshot. An event-firing
stream is a [guarded addition](#g-guarded-addition) (a capability the design
admits but does not build).

Two tools serve where garbage is unavoidable. Arena allocation
(Bumper.jl-style) serves scoped temporaries. A scheduled `GC.gc(false)` at
frame boundaries moves collection out of the critical path. Julia has no
per-object freeing, so these are the honest levers.

---
