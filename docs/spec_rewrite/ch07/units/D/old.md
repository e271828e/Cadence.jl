### 7.4 The fused-evaluation lineage (prior art and how we got here)

The [§5.2][s5-2] interfaces are the end point of a four-step simplification arc. The arc
is recorded here because each step replaced a mechanism with something smaller.

1. **N output groups → exactly two** ([D-006][d-006]), at the price of an occasional
   [component](#g-component) split ([§5.4][s5-4]).
2. **Derivative binding → own-output access** ([D-015][d-015]). Passing the fresh [signal
   table](#g-signal-table) to `x_deriv`/`s_update` subsumes the
   declaration feature, and the "binding" becomes a one-line function body.
3. **Separate state arguments → the state decoder** ([D-016][d-016], [D-035][d-035]). Step 4 later
   reversed the second half of this step.
4. **Decoder-exclusive state access → stores-and-views arguments.** Step 3's
   second half was reversed ([D-035][d-035]). Once [§8.3][s8-3] made publication a deliberate
   interface act, the identity decode stood revealed as *transport*. It copied
   the [buffer](#g-buffer) into [cells](#g-cell) so that a buffer view could be replaced by a cell view.
   The fixed point is the argument rule ([§5.2][s5-2]), zero-copy views of the stores a
   function genuinely reads. What survives of step 3 is the uniform shapes, the
   fused economics, and the stage-1 decoder itself (today's `y_state`).
   That decoder is no longer the sole state gate. It is the no-[feedthrough](#g-feedthrough)
   stage.

For orientation, here is the prior art. Every causal framework meets the
shared-computation problem and resolves it per its architecture. **Simulink
diagrams** make integrators explicit blocks. Derivatives are ordinary wires into
`1/s`, and the computer/integrator split is their native idiom. **S-functions
and FMUs** use sanctioned *mutable caches*, DWork vectors and FMI's
lazy-evaluation caching, between their `mdlDerivatives`/`mdlOutputs`-style
callback pairs. **Modelica/MTK** write `der(x) = expr` natively with symbolic
CSE. The fused [sweep](#g-sweep) plus signal-consuming `x_deriv`/`s_update` is
the cache-free formulation that fits this design's purity rules. It is also what
FlightCore's fused `f_ode!` did economically, minus the checked ordering.

The **computer/integrator split** remains fully expressible without any
framework support. A stateless component computes derivatives as outputs, wired
into a trivial state-holding component. It is the idiom of choice when the
factoring earns reuse, for example one Newton–Euler solver shared across vehicle
variants, or swappable kinematic descriptors against a common integrator shape.
Against a split-form spelling of the same model (four components, thirteen
connections), the merged form has half the components and wiring. Everything
derivable from pose alone migrates to stage 1, shortening the stage-2 chain.

### 7.5 Allocation policy: a scoped invariant

The allocation policy is not dogma. Three reasons support it, and only one is
about speed. First, GC-pause jitter control for real-time. Second, throughput
for [unattended runs](#g-unattended-run) (runs with empty staging and no snapshot readers). Third,
**the canary**. An unexpected allocation is Julia's most reliable symptom of
type instability. A zero baseline therefore makes `@allocated == 0` a
CI-testable invariant, one that catches inference regressions at the offending
commit.

- **Continuous hot path.** This is per-stage evaluation, plus everything else
  that runs unconditionally per frame or [boundary](#g-boundary). Those unconditional items are
  [guards](#g-guard), evaluated every boundary whether they fire or not, and
  `x_projection` at both of its [§5.3][s5-3] positions in the [execution order](#g-execution-order). The
  budget is exactly zero, CI-enforced at the [§9.7][s9-7] phase-body [seam](#g-seam)
  (`phase_bodies`).
- **Periodic [ticks](#g-tick) and event handlers.** These execute episodically, a tick when
  due and a handler only on firing. Allocation here is zero by idiom. The idiom
  is the [workspace](#g-workspace) (component-declared mutable scratch arriving as the `ws`
  bundle field) and snapshot pattern, plus immutable-value returns. The rare
  exception has a documented tolerance, scoped per body by the seam's
  granularity so it never loosens the continuous assertions.
- **Logging** is amortized-zero. The [log](#g-log) retains the published
  snapshot objects themselves, by reference, one slot per retained boundary
  and no copy ([§11.2][s11-2]). `sizehint!` to the retention bound makes
  regrowth a non-event. The allocation claim is about the snapshot's
  *fields*, not about everything reachable from them. A model carrying [§4.4][s4-4] [field handles](#g-field-handle)
  (immutable query objects consumers evaluate at their own arguments, such as
  heightmap terrain or wind grids) has a snapshot type with reference fields.
  Those fields ride as references to build-time-frozen data, with no copy and no
  per-boundary garbage, which is what the allocation claim asserts. What the
  claim does not assert is that the snapshot is `isbits`. The per-boundary
  allocation cost is zero either way, and the summarize-or-skip rule ([§4.4][s4-4])
  governs what such a field contributes on export.
- **Event firings are not recorded.** The [log](#g-log) holds boundary snapshots and the
  [trace](#g-trace) holds staged inputs ([§11.2][s11-2], [§11.5][s11-5]). Neither carries a per-event record.
  Which events fired at which boundary is recovered by [replay](#g-replay) plus the published
  modes. The honest remedy ([§11.2][s11-2]) is to declare the mode field public and
  return it from `y_state` ([D-252][d-252]); a mode field so exposed is in
  every snapshot. An event-firing stream is a
  [guarded addition](#g-guarded-addition) (a capability the design admits but does not build).
- **Tools where garbage is unavoidable.** Arena allocation (Bumper.jl-style)
  serves scoped temporaries. A scheduled `GC.gc(false)` at frame boundaries
  moves collection out of the critical path. Julia has no per-object freeing, so
  these are the honest levers.

---

