# Migrating FlightPhysics and FlightApps

*A companion outline, not normative text. It records how the `FlightPhysics`
and `FlightApps` packages of Flight.jl move onto this framework, and it is an
outline rather than a specification. The ground truth is `spec.md`, and the
case studies of `flight_case_studies.md` are the outline's evidence. If this document and the
spec ever disagree, the spec wins.*

The table carries one row per item: the item, the disposition recorded for it,
the section owning the machinery it touches, and the governing decision entry.
A dash means the outline names the item and records nothing further. Items
whose disposition exceeds a cell are expanded below the table.

| item | disposition | section | decision |
|---|---|---|---|
| The walked-leaf parametrization pass | the `Ranged` rewrite targets the walk rule wherever `Ranged` survives, at ports and parameters | [§8.2][s8-2] | — |
| The `KinData`-style output splits | — | — | — |
| The contributor survey feeding the aggregation chains | mechanical to extract from today's trait implementations | [§6.2][s6-2] | — |
| Comparison criteria against FlightCore's demonstrated strengths | three strengths to compare against: zero-alloc stepping, flexibility, interactive operation | [§9.7][s9-7] | — |
| The component library's starting inventory | — | [§13.7][s13-7] | — |
| The conventional exported aircraft surface for generic periphery consumers | pose and velocity faces with wrapper types, the periphery-facing half of the `KinData` successor | [§11.2][s11-2] | — |
| The supervisor seam | three respellings — gain ports and schedulers, mode-transition latches, the gear's reset — the last of which lands on the *library* side | [§5.3][s5-3] | [D-089][d-089], [D-139][d-139] and [D-141][d-141] |
| The steering contract re-factoring | `AbstractSteering` moves from "give me the angle" to `(engaged, ψ_cmd)` | [§5.4][s5-4] | — |
| Splitting `Strut` | the residual remedy, recorded and not taken | — | — |
| The state-declaration conversion to the closed vocabulary | each `RQuat` state field becomes its `SVector{4}` backing, each `Ranged` state field a plain scalar | [§7.1][s7-1] | — |
| *Residual*: the `q_sf` home | aircraft design, so it belongs on this list | — | — |
| *Residual*: the engage-boundary write-order check | verify the FCS latch and the GUI input sync-write commute on one boundary — believed order-free, both deriving from the same measurements | — | — |
| *Residual*: the C172 AD audit for trim | Interpolations tables (prefer cubic knots), saturation rank-deficiency (LM-tolerated, reported), the gear identically zero airborne | [§14.8][s14-8] | [D-070][d-070] |

**The parametrization pass.** `Ranged` survives at ports and
parameters, and there the rewrite targets the walk rule ([§8.2][s8-2]). The
rewrite is constructor discipline that admits the walked scalar and leaves the
value parameters alone, plus a `probe_value` method. State fields are not
among those survival sites. The state-declaration conversion below turns each
`Ranged` state field into a plain scalar.

**Comparison criteria.** FlightCore's demonstrated strengths are three:
zero-alloc stepping, flexibility, interactive operation. Zero-alloc stepping
is measured through the `phase_bodies` seam ([§9.7][s9-7]),
apples-to-apples with today's `@ballocated f_ode!` suites.

**The conventional exported aircraft surface.** Generic
periphery consumers read the integration
side ([§11.2][s11-2]). That surface exports pose and velocity faces with wrapper types
(`VelocityData`, with field meaning defined at the type). It is the
periphery-facing half of the `KinData` successor.

**The supervisor seam.** The supervisor sitting above the compensators
(section 2 of `flight_case_studies.md`) contributes three respellings. Compensator gains become input
ports fed by scheduler components (about 7 for the C172X). Every
mode-transition latch is respelled as a same-tick reset. The gear's
level-triggered reset becomes an edge event, and that last one lands on the
*library* side.

On the library side, the reimplemented `PIVector` gains a **flag-gated reset
face**. `PIVector(; reset = true)` adds a `Bool` input face plus the event.
The default omits both. Declarations are ordinary functions of the instance
([§8.5][s8-5]), which is what makes this the honest version of Simulink's
checkbox. One fixed policy governs the face: a rising edge resets to the
declared `x_init` values. The implementation is internal, an ordinary
guard/handler event. It is the continuous-reset contract in its
worked instance ([Appendix A][sA]).

Falling-edge consumers wire a NOT gate (the Bool gates, [§13.7][s13-7]).
Level-pinning and reset-to-an-external-value, which is tracking, are different
blocks rather than options on this one ([D-141][d-141]).

The gear then wires `strut.wow → frc.reset`. That is the **touchdown** edge,
with the not-holding → holding semantics ([§2.1][s2-1]),
and it gives fresh regulator state per contact episode. The liftoff edge
(`!wow`) was rejected ([D-141][d-141]). The
boundary-detected policy (checked for edges at step
boundaries only, no root-finding) suffices, because the regulator's input
ramps from zero at touchdown, so localization buys nothing. A sim initialized
on ground fires the reset at boundary zero (the
initialization boundary: the ordinary macro-sequence with an empty integrate).
It fires harmlessly there. Declared inits are zero, and
boundary-zero priors are not-holding
([§14.5][s14-5]).

The engine's two `PIVector` instances, `PistonEngine`'s `idle` and `frc`,
migrate **unchanged, flag off**. They are verified reset-free in today's code,
where the saturation bounds and `int_halted` already handle windup across
unused phases. Their `f_init!` gain writes become construction-time
parameters, as `Contact`'s do ([D-089][d-089]). The PI *law* is shared as
plain pure functions called by the block's stages, which is the
laws-as-plain-functions pattern ([D-139][d-139]). `sat_ext` poses the same
always-on-vs-flag-gated face question, to be decided at reimplementation time
on the same axis.

**The steering contract re-factoring.** This is the middle rung
([§5.4][s5-4]), worked on the shipped instance. `AbstractSteering` moves from
"give me the angle" to `(engaged, ψ_cmd)`, with the castoring fallback
`ψ_sw = engaged ? ψ_cmd : ψ_v` computed inside `Strut`. That move deletes the
strut → steering → strut artificial loop that stage-2 conservatism would
otherwise manufacture. The `VehicleDynamics` instance standing beside it
(section 1 of `flight_case_studies.md`) needs no such move. It dissolves under the two-stage split
alone.

**Splitting `Strut`.** The residual remedy is to split `Strut`, with its
shared geometry crossing the new boundary as one `StrutGeometry` bundle port.
It is recorded and not taken. The call is an aircraft-library one, about a
component's own contract, so it is recorded here rather than in framework
vocabulary.

**The state-declaration conversion.** State declarations move to the closed
vocabulary ([§7.1][s7-1]). Each `RQuat` state field becomes its `SVector{4}`
backing, with the explicit `normalization = false` cast at its use sites. The
4-wide rate is already what today's `Attitude.dt` delivers. Each `Ranged`
state field becomes a plain scalar, with its clamp respelled as dynamics or
projection, never as construction.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-070]: ../decisions.md#d-070--trim-service-in-house-dense-lm-behind-a-swappable-backend
[d-089]: ../decisions.md#d-089--route-supervisor-gains-and-resets-through-ordinary-ports
[d-139]: ../decisions.md#d-139--give-environment-field-handles-a-value-level-constructor-to-prevent-drift
[d-141]: ../decisions.md#d-141--continuous-state-resets-are-events-owned-by-the-reimplemented-pivector
[s11-2]: ../spec.md#112-outbound-snapshot-publication
[s13-7]: ../spec.md#137-tooling-consequences-face-routes-and-the-component-library
[s14-5]: ../spec.md#145-boundary-zero-an-ordinary-boundary-with-authored-incoming-transitions
[s14-8]: ../spec.md#148-the-trim-service-solver-seam-scratch-stores-commit-and-report
[s2-1]: ../spec.md#21-events-two-detection-policies
[s5-3]: ../spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
[s5-4]: ../spec.md#54-artificial-loops-and-the-escape-hatch
[s6-2]: ../spec.md#62-aggregation-explicit-summing-junctions
[s7-1]: ../spec.md#71-continuous-state-structured-immutable-flat-backing
[s8-2]: ../spec.md#82-the-declaration-inventory
[s8-5]: ../spec.md#85-assembly-declaration-type-based-class-by-declaration-shape
[s9-7]: ../spec.md#97-the-compiled-executor
[sA]: ../spec.md#appendix-a-taught-contracts-the-author-facing-index
