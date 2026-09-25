# Case studies: grounding the design in Flight.jl

*A companion document, not normative text. The framework began as a
replacement for `FlightCore`, the simulation core of Flight.jl, and these case
studies read the design against code that existed there: `FlightPhysics`, its
physics library, and `FlightApps`, its applications. They are evidence rather
than rules. Where a measurement here and a rule in `spec.md` disagree, the
rule wins. The migration they feed is outlined in `migration_outline.md`.*

Section 1 is the `Vehicle` transliteration that validated the spec's [§5][s5].
Section 2 holds torture tests aimed at the [§5.2][s5-2] interfaces. Section 3
reads the full C172X demo as a load test on the periphery. The two case
studies that stand without Flight.jl live in the spec: the staging example of
[§11.4][s11-4] and the strapdown IMU of [§3.4][s3-4] and [§8.6][s8-6].

## 1. `Vehicle` today → this framework

This case study is the grounding exercise that validated [§5][s5]. Today's
`Vehicle.f_ode!` (`aircraftbase.jl:142-170`) is a hand-woven instance of the
machinery specified here:

| Today (convention) | This design (checked structure) |
|---|---|
| `kinematics.u .= dynamics.x` — velocity extracted directly from the state vector because `f_ode!(dynamics)` can't run yet | `dyn`'s stage-1 output, ordered first by construction; the artificial loop in `VehicleDynamics` dissolves ([D-035][d-035]) |
| Hand-ordered `f_ode!` body (kinematics → airdata → systems → route five `dynamics.u` assignments → dynamics last) | Build-time topological sort; wrong wiring = build error naming the cycle or dangling port |
| Velocity state duplicated in `dynamics.x` and `kinematics.u`, kept in sync by hand | One state, one owner; consumers wire to `dyn.vel` |
| `get_wr_b`/`get_mp_b`/`get_hr_b` generated tree-walk sums | Summing junctions at ownership boundaries, one explicit wire per contributor, exported totals ([§6.2][s6-2]) |
| `f_step!` quaternion renorm + engine-phase/stall-latch checks | `x_projection` hook + boundary-detected events with defined semantics |
| `Aircraft.f_ode!` runs avionics before the vehicle → continuous avionics reads one-stage-stale `vehicle.y` (implicit delay) | Avionics ordered inside the sweep, after the stage-1 outputs avionics consumes — no delay. Or avionics declared periodic, sampling post-step by stated semantics |
| `atmosphere`/`terrain` threaded as arguments through every signature | Field-handle signals through ordinary ports ([§4.4][s4-4]) |

Two of those rows carry detail a cell cannot hold. The artificial loop in
`VehicleDynamics` pairs a state-only velocity output with
feedthrough accelerations. The hand sync of the duplicated
velocity state reaches into initialization, where `f_init!` carries the line
`dynamics.x .= kinematics.u  #essential`.

The same exercise surfaced a migration cost. Today's monolithic `KinData`
splits in two, because its parts *genuinely* have different dependencies.

- `pose`, at stage 1: `q_eb`, `r_eb_e`, `ϕ_λ_h`, ...
- `kin_vel`, at stage 2: `v_eb_n`, `v_gnd`, `χ`, `γ`, ...

The recurring trade, stated once, is this. The framework asks authors to write
down structure they previously kept in their heads. It pays them back by never
letting that structure silently rot.

The genuine algebraic loop in the domain is α̇-dependent
aerodynamics. The current C172 model already breaks it with a filter state,
which is exactly the explicit break [§5.5][s5-5] prescribes. That precedent is
evidence that the reject-loops policy matches domain practice rather than
fighting it.

## 2. Torture tests for the §5.2 interfaces: `PistonEngine` and the FCS PID cascade

This case study is three exercises, each starting from code that exists today.
Two components were transliterated to validate the decoder
interfaces before adoption: `PistonEngine` on the continuous side, `PID` and
the C172X FCS on the discrete one. A third exercise takes the supervisor
sitting one level above those compensators. Each is read first as what today's
code does, then as what this design makes of it.

### `PistonEngine`: the continuous side

The current engine (piston.jl:310-449) carries a mode enum with three flow
regimes, four table lookups, two embedded continuous PI compensators, boolean
transitions and an argument-threaded `fuel_available`. The points below place
each of those features under the decoder interfaces.

- The compensator paths (`idle`, `frc`) are pure functions of the engine's own
  state `ω`. Their complete PI laws, outputs and state derivatives alike,
  therefore evaluate in `y_state`. The alternative factoring, with the
  compensators as child components of an engine assembly, also
  orders cleanly from the core's stage-1 ports.
- `y_direct` runs the lookup chain and the mode branch once.
  `x_derivative` is a three-field copy (`ω̇`, `ẋ_idle`, `ẋ_frc`). Under
  the orthodox split, `f(x, u, t)` would reproduce essentially the whole
  `f_ode!` body, four lookups and the mode branch, at each of the four RK
  stages per step ([D-015][d-015]).
- `f_step!`'s transitions become boundary-detected
  events with mixed predicate/threshold guards
  ([§2.1][s2-1]).
- `fuel_available` becomes an ordinary port. It is state-derived at the fuel
  system, hence a stage-1 port, so it closes no loop.
- Forced publications: none. Everything `x_derivative` reads was already
  in `PistonEngineY`.

### `PID` and the C172X FCS: the discrete side

`PID` (control.jl:431-471) and the C172X FCS around it represent the discrete
side.

- The current update entangles outputs and next state by construction. The
  spelling is `y_i = s_i`: this tick's integral-path output *is*
  the updated integrator state.
- Under [§5.3][s5-3] the law runs once in `y_direct`, publishing paths,
  saturation and the updated states. `s_update` is a three-field copy.
- Under the orthodox split, `g(s, u, t)` would reproduce the entire law per
  compensator per tick ([D-015][d-015]).

**The exercise discovered a latent delay.** The FCS chains anti-windup: outer
compensators take `sat_ext` from the inner LQR's `sat_out`
(c172x_ctl.jl:332,345,...). Wired naively, that chain is a *genuine*
tick-domain algebraic loop, and the build correctly
rejects it:

```
outer.output → inner.input → inner.sat_out → outer.sat_ext →
outer.int_halted → outer.y_i → outer.output
```

Today's code escapes the loop only through hand-managed call order. The outer
loops read the LQR's `sat_out` *before* the LQR updates, so they silently
consume the **previous tick's** value. That is a unit delay that exists
nowhere in the code, only in statement ordering.

Under this design the fix is one visible wire. Connect `outer.sat_ext` to the
inner compensator's stage-1 port for the previous saturation, `sat_out_0`.
That port is an `s` field declared in the LQR's output contract
and returned from its `y_state`, so it sits at stage-1 position
([§5.3][s5-3]). The delay becomes an
explicit property of the wiring. The loop and its fix do not depend on the
formalism. The framework's contribution is that it refuses to let the
ambiguity through. Stage 1's contribution is that the delayed value is already
on a port.

Both components passed without blockers, and neither needed a port beyond
current practice. That result is the empirical basis for the claim in
[§5.3][s5-3] that derivative/output overlap is the domain norm and that the
decoder matches the codebase's grain.

### The supervisor slice: scheduled gains and bumpless engage

One level above the compensators, today's `c172x_ctl.jl` runs on two idioms
that the stores-and-views rules deliberately remove.
The first is per-tick gain scheduling by mutation. `assign!` writes `Ref`-cell
parameters from EAS/altitude lookups on every 50 Hz tick, LQR matrix sets
included. The second is mode-transition resets. `f_init!` plus a
bumpless-transfer latch run hand-ordered *before* the same tick's
`f_periodic!`. Both survive as ordinary signal flow.

*Scheduled gains are inputs.* A scheduler component owns the lookup tables as
inert parameters, reads the scheduling variables as inputs, and publishes one
gain bundle per compensator. Compensators consume gains as `u`. What mutation
hid, ports expose. Gain trajectories become observable in log,
trace and replay, where the `Ref` writes were
invisible to all three. The feedthrough graph carries the
dependency. Linearization holds unseeded gain inputs constant with no special
casing ([§14.10][s14-10]). One-shot design-time gains, such as `robot2d`'s
controller synthesis at init, are construction-time parameters or stopped-sim
service outputs. They are not a runtime write path.

*Resets are same-tick inputs, consumed in the output stage.* The supervisor
publishes `engage` and the latch value from its own feedthrough stage. The
compensator sits topologically after the supervisor and honors them **this
tick**:

```julia
y_direct(c::PI, (; s, u)) = (; u_cmd = u.engage ? u.u_latch : c.k_p*u.e + s.s_i)
s_update(c::PI, (; s, u, Δt)) = (; s_i = u.engage ? u.u_latch - c.k_p*u.e
                                                      : s.s_i + c.k_i*Δt*u.e)
```

Honoring the reset only in `s_update` is legal, and it means something
else. The state still lands correctly at the next tick. But the *output at the
engagement tick* was already published from the stale state during the
sweep, and under ZOH the plant integrates a full step under that
stale command. That one-tick-late command is exactly the bump that bumpless
transfer exists to remove. No diagnostic can catch the bump, because both
spellings are meaningful designs.

The update stage cannot rescue its own boundary, because
republishing from `s⁺` is rejected ([D-067][d-067]). The output stage is
therefore the *only* same-tick path. Today's hand-ordering, `f_init!` before
`f_periodic!` in one call, is that same-tick reset contract enforced by hand.
[Appendix A][sA] carries it as the same-tick reset entry, and the
bumpless-engage answer ([§11.7][s11-7]) presupposes exactly this spelling.
Engage semantics live in the FCS.

One relative lives outside the FCS. The landing gear's level-triggered
cross-component reset (`!wow` re-initializing the friction regulator every
step) becomes an edge-triggered event owned by the regulator. That is a
semantic tightening, recorded in the migration mapping (`migration_outline.md`). There the
respelling is not a stylistic one. The continuous tier admits no
input spelling at all, because only handlers write `x` ([§3.1][s3-1]). The
event is therefore necessity rather than taste, and the reimplemented
`PIVector`'s optional reset face (`migration_outline.md`) is sugar over exactly
that event. [Appendix A][sA] carries the continuous-reset contract too.

## 3. The interactive C172X demo: the periphery under load

This case study is the full-fidelity successor to [§11.4][s11-4], run against
the real deployment. `generic_simulation()` (`FlightApps/demos/c172_demos.jl`)
builds `SimpleWorld(Cessna172Xv1, SimpleAtmosphere, HorizontalTerrain)` and
adds a GUI, joysticks, an XPlane12 output device, ground/trim
init, a paced run and post-run plots. The method treats FlightCore's
mechanisms as reference *behavior*, not as requirements. The question is
whether the new machinery expresses the experience (move stick, plane banks),
never how to reproduce `assign_input!`. The interactive surface is *not* one
thing. Pilot commands cluster under a prefix, and environment knobs stay with
their components' panels. The complete interactive surface follows, with each
item's home.

- **Streamed commands** (`throttle_axis`, `elevator/aileron/rudder_axis`).
  Today joystick mappings write these after shaping, *and* GUI sliders write
  the same fields. Every dual-writer field in the demo is this pattern, a
  stream shadowed by a mirror, where simultaneous live writing is a bug. This
  finding adjudicated root-input exclusivity
  ([§11.3][s11-3]). Claim/disable covers every case found, and
  none needs two concurrent writers.
- **Edge-driven increments** (trim offsets ±5e-3 per hat release, flaps ±⅓
  per button release). Today these are `+=` deltas executed *inside the
  mappings*, accumulating in model `u`. That is the levels-never-deltas
  violation, live in the codebase. Under this design, devices stage monotonic
  press counters, and the accumulator state lives in the model as avionics
  discrete state.
- **The shaping stack.** The exp curves and deadzones are defined in the
  aircraft variant module and duplicated *verbatim* across the T16000M and
  Gladiator mappings, which is the duplication smell. The
  `q_ref = q_sf · axis` fan-out sits beside them. The stack decomposes into
  device conditioning (device truth), feel curves (deployment preference) and
  command semantics (FCS design). The face contract
  splits it along those lines: conditioning upstream as mapping data,
  semantics in-model ([§11.4][s11-4]).
- **Mode engage** (`mode_req` plus setpoint capture from current
  measurements). The GUI handler does `u.EAS_ref = EAS`, read from
  `vehicle.y`. This is the one place where the GUI composes writes from model
  state. It is resolved under *Frame anatomies* below.
- **Vehicle-direct and environment tunables** (engine start/stop/mixture,
  payload masses, terrain surface enum, sea-level T/p, wind NED). These are
  ordinary component inputs exported to root faces. The GUI
  writes them under its greedy claim (the unclaimed
  complement, computed by the framework instead of returned) via
  [§11.7][s11-7]. No machinery is needed.
- **The Xv1 actuator sliders.** These are FlightCore's dead sliders.
  [§11.7][s11-7] resolves them as read-only. No action.
- **Outbound** (XPlane12: control-surface angles, nose-wheel steering, prop
  speed/phase, pose, `t`). This is a snapshot-consuming device,
  a pure `map_output` on the device task ([§11.2][s11-2]). No friction found.
- **Init/trim, pause/pace, post-run plots.** These are stopped-sim services
  ([§14][s14]), the control plane ([§12.1][s12-1]) and log/trace
  ([§11.2][s11-2], [§11.5][s11-5]).

### Architectures examined here and rejected

This cast forced the [§11][s11] and [§12][s12] periphery
decisions. The exercise examined three architectures: devices as
components (a `T16000M` component wrapping SDL), a root-level
`PilotInterface` cockpit component, and bundled command faces
(`pilot_inputs` as one struct port). [D-045][d-045] litigates all
three. What each leaves behind is the design's own answer.

- The *knowledge* half of a device model, its semantics, is expressible as an
  ordinary in-model component wherever wanted. Only the
  wall-clock pump stays outside.
- The cockpit component's claimed jobs are covered where they belong. Struct
  assembly happens in-model, downstream of scalar faces. Curves are mapping
  data. Widget arbitration is [§11.7][s11-7] plus exclusivity. The stateful
  residue (accumulators, capture-on-engage) lives in the avionics.
- The routing convenience a command bundle bought in FlightCore's
  argument-threading world is provided by the namespace prefix and
  `input_passthrough` ([§8.8][s8-8]). The struct reappears legitimately
  downstream, assembled in-model by a single producer.

### Surface walkthrough

The demo, line by line:

- `SimpleWorld(Cessna172Xv1(), SimpleAtmosphere(), HorizontalTerrain(h_LOWS15))`
  is pure value construction, with no `Model` wrapper (its jobs move into the
  build). `HorizontalTerrain`'s elevation is a plain field (a parameter) and
  its surface type an input port. The parameter/port split that
  FlightCore kept implicit in its `U()`-vs-field convention is now the
  declaration itself. The aircraft's `input_connections` block carries the
  `pilot.*` face group in one place, hands it one level down to
  avionics and systems, and re-routes it at each level below ([§6.1][s6-1]).
  Today's mapping writes flaps/brakes directly into `act`, bypassing avionics.
  That bypass becomes a declared route.
- `Simulation(world; algorithm = RK4, h = 0.02, N_base = 1)`.
  `N_base` binds `Δt_base = N_base·h` ([§10.5][s10-5]). Its default of 1 puts
  a base tick on every step. The entire build pipeline runs here:
  class resolution, path validation, face derivation (computed
  interface connections expanded, printable), the two-producers and
  unconnected checks, topological sort, probe passes, rate
  compilation, flat layout and the root input table.
- `init!(sim, ready_for_taxi(ac); t0 = 0.0)` runs the stopped-sim services
  ([§14][s14]). Trim is its own service, `trim!(sim, problem; baseline, …)`,
  and its commit runs the same boundary. The services write `(x, s, m)`,
  **establish every root input's initial value**, and capture the
  trace header. Root-input initialization *decisively*
  belongs here and not in declarations, because the trim service writes
  root-input values it *solved for* (throttle, elevator), not declaration
  constants.
- `attach!(sim, XPlane12Control(…), binding)` attaches an output
  device. It claims nothing, consumes
  snapshots via [§12.3][s12-3], and runs a pure `map_output` on
  its task. Its binding names snapshot paths, **validated at
  attach against the actual contract**. An aircraft substitution
  that breaks the binding therefore fails at attach, not with silent garbage
  UDP. That is a new, cheap [§11.2][s11-2] obligation.
- `attach!(sim, joystick, T16000MBinding())`. The binding is a declarative
  table from axis or button to face name plus conditioning parameters
  (`stick_y = (face = "aircraft.pilot.elevator_axis", expo = 1.0, deadzone =
  0.05)`, `button_3 = (face = "aircraft.pilot.flaps_up_count", as = :count)`).
  At attach, faces resolve against the root contract (a typo gets a
  did-you-mean) and `attach!` registers the claim set, so
  a second joystick on the same faces errors here. The Gladiator variant is
  the same table with different keys and zero shaping code. The duplication
  smell is structurally gone.
- `run!(sim; gui = true, pace = 1, t_end = 1000)` makes a
  greedy claim over every unclaimed face and settles
  liveness with zero configuration, both at run start against the
  frozen roster ([§11.3][s11-3]). Axis
  mirrors are read-only (claimed, source shown). The mode, setpoint,
  mixture, payload and environment widgets are live. Actuator sliders are
  read-only (component-fed). The `gui` flag's attachment lasts
  exactly this run ([§12.6][s12-6]).
  Unplugging the joystick makes its task exit. The mirrors stay read-only with
  the death in their source label ("claimed by `T16000M` — task dead"), and the
  axes hold their last-drained values. Those two behaviors are the accepted
  orphan anomaly ([§11.3][s11-3]). Recovery happens between runs: stop,
  `detach!`, then `init!` for a fresh trajectory, or `replay!` to the end
  followed by `run!` to continue the interrupted one ([§12.7][s12-7]).
  After the run, `TimeSeries` reads the retained snapshots, and the
  trace can re-drive a fresh `Simulation(world)` bit-identically.
  That replay is also the state-trajectory inspector, which is
  [D-038][d-038] paying its way.

### Frame anatomies

One frame each:

- *Stick motion.* The device task polls, and the conditioning
  helper applies the binding parameters. A complete batch
  overwrites the cell, so inter-frame polls coalesce, which
  is ZOH-correct. The drain applies the batch and
  traces it, and the avionics tick reads the
  root input fresh. The worst-case stick-to-physics latency
  is the poll interval plus one frame, now by stated semantics.
- *Flaps click.* The button peeks the counter `k`
  (own-pending-else-snapshot) and stages level `k+1` on
  activation. The drain applies it. The avionics compares the root-input
  counter to its `s` counter, moves the detent, and stores. Multiple clicks in
  one window count through the own-pending-first peek, and repeated staging is
  idempotent ([§11.7][s11-7]).
- *Mode engage.* The GUI stages `mode_req`, plus optionally peek-captured
  setpoint root inputs. **Bumpless-engage semantics live in the FCS already.**
  The current `ControlLaws` latches each controller's reference from the
  present command vector on mode transitions. So the capture fork dissolved.
  Semantic capture is aircraft design. That arrangement is the status quo, and
  it is uniform across writers, so a script engages sanely by staging one
  value. The GUI peek-batch ([§11.7][s11-7]) therefore survives as
  display and input-sync sugar only. One residual check remains for migration:
  the order-sensitivity of the latch against a sync-write on the same
  boundary. None is believed to exist, because both derive from
  the same measurements.
- *Wind slider.* A sparse CAS merge, the uncontested-`τ` case
  ([§11.4][s11-4]), live in the real cast.
- *Pause/un-pause.* The control plane handles it. GUI
  edits hold in its cell, and peek displays them. The joystick cell coalesces,
  bounded. The un-pause drain applies both, since the root inputs are disjoint
  and exclusivity makes the contested question unaskable. The pacer
  re-anchors.
- *Window close.* [§12.4][s12-4] applies verbatim: complete the boundary,
  final snapshot, sticky stopped, wake waits, unblock hooks, named-timeout
  joins.

Two items remain open and feed the migration outline
(`migration_outline.md`). The first is the `q_sf` home, a
thin mapping entry against an avionics-internal derivation, which is aircraft
design rather than framework design. The second is the mode-engage entry's
write-order check.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-015]: ../decisions.md#d-015--fused-evaluation-of-derivatives-and-outputs
[d-035]: ../decisions.md#d-035--stores-and-views-components-read-zero-copy-view-bundles
[d-038]: ../decisions.md#d-038--snapshot-and-log-derived-trajectory-primary-trace-header
[d-045]: ../decisions.md#d-045--periphery-input-semantics-derived-liveness-conditioning-mappings-edge-logic
[d-067]: ../decisions.md#d-067--boundary-zero-runs-the-macro-sequence-with-an-empty-integrate
[s10-5]: ../spec.md#105-multi-rate-tick-scheduling
[s11]: ../spec.md#11-runtime-periphery-the-data-plane
[s11-2]: ../spec.md#112-outbound-snapshot-publication
[s11-3]: ../spec.md#113-inbound-root-inputs-claims-and-the-frozen-roster
[s11-4]: ../spec.md#114-inbound-per-device-staging-representation-and-the-drain
[s11-5]: ../spec.md#115-inbound-the-input-trace
[s11-7]: ../spec.md#117-the-gui-write-path-port-resolution-peek-staging-contract
[s12]: ../spec.md#12-runtime-periphery-lifecycle-and-orchestration
[s12-1]: ../spec.md#121-control-plane
[s12-3]: ../spec.md#123-the-next-snapshot-wait
[s12-4]: ../spec.md#124-shutdown-protocol
[s12-6]: ../spec.md#126-run-lifecycle-and-partial-advance
[s12-7]: ../spec.md#127-replay-the-trace-re-drives-the-ordinary-loop
[s14]: ../spec.md#14-stopped-sim-services
[s14-10]: ../spec.md#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s2-1]: ../spec.md#21-events-two-detection-policies
[s3-1]: ../spec.md#31-continuous-component-the-hybrid-primitive
[s3-4]: ../spec.md#34-why-two-leaf-classes-not-one-hybrid-primitive
[s4-4]: ../spec.md#44-function-valued-signals-environment-access
[s5]: ../spec.md#5-evaluation-order-and-feedthrough
[s5-2]: ../spec.md#52-two-stage-outputs-signatures-bundles-and-the-hand-off-laws
[s5-3]: ../spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
[s5-5]: ../spec.md#55-algebraic-loop-policy-reject-at-build-time
[s6-1]: ../spec.md#61-connections-and-hierarchy
[s6-2]: ../spec.md#62-aggregation-explicit-summing-junctions
[s8-6]: ../spec.md#86-paths-wiring-and-faces
[s8-8]: ../spec.md#88-computed-connections-and-generic-holding
[sA]: ../spec.md#appendix-a-taught-contracts-the-author-facing-index
