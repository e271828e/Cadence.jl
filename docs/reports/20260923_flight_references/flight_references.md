# Flight.jl references in Cadence.jl — inventory (2026-09-23)

Sweep of the whole repo for references to Flight.jl, `FlightCore`, `FlightPhysics`,
`FlightApps`, and code that lives there (`f_ode!`, `KinData`, `PistonEngine`,
`Vehicle`, the C172X and Xv1 demos, `aircraftbase.jl`, `iodevices.jl`,
`navsensors.jl`, ...). Grouped by the kind of treatment each group would need.

## 1. Identity and framing (few passages, highest visibility)

These tell the reader what Cadence *is*. They must be rewritten, not trimmed.

- `README.md:5-6` — "built to replace `FlightCore` as the substrate for `FlightPhysics` and `FlightApps` in Flight.jl".
- `README.md:183-184` — spun off from Flight.jl's `core-redesign-2` branch, carries its history.
- `docs/design/spec.md:1` — title: "A Modeling & Simulation Framework for Flight.jl".
- `spec.md` §1 (148-175) — purpose, the three ground rules. "Capability grounding" defines requirements as what FlightPhysics/FlightApps *do*; "no interface compatibility" is about them; "guarded additions" are weighed against "the fundamental strengths of Flight.jl".
- `spec.md:12495` glossary entry *guarded addition* — repeats "Flight.jl's fundamental strengths".
- `spec.md` Part V intro (9641-9655) and §16 opening (10312) — "the migration of FlightPhysics and FlightApps".
- `docs/design/extensions.md` §1 (19-20) and §1.5 "The bias, named" (174-190) — the gap survey is framed as "how far did the FlightCore rewrite land from a general engine". §1.5 is *about* the inheritance, so it can't just be scrubbed.
- `docs/design/decisions.md:19-22` — says the design's full history lives in the git history of `framework_design.md` (a Flight.jl-era file).
- `docs/design/tools/decisions_style.md:68-70` — style ruling: FlightCore is "the predecessor in-house framework", contrast with it is lineage and goes in Rationale.

## 2. Design rules that depend on the migration

Not mere mentions. These are rules whose justification is "the consumers need it".

- `spec.md` §13.7 (8247, 8316) — "The library grows by migration demand only" and "the library is a migration-phase deliverable". `Group` is the stated exception ("admitted by persona").
- `spec.md` §16 "Migration" (10316-10440) — a 16-row outline for FlightPhysics/FlightApps: `KinData` splits, `Ranged`/`RQuat` conversions, `AbstractSteering`, `Strut`, the C172 AD audit, the exported aircraft surface. Some rows are framework work in disguise: the export audit, the executor compile-cost re-measurement, the comparison criteria.
- `spec.md` §16 "Log and trace persistence" (10519) — deferred "to migration, where the consumers exist".
- `spec.md` §16 export surface (10430) — names clash "with FlightPhysics domain code".
- `docs/design/pending.md:18, 45` — §13.7 library deferred as "the spec's own migration deliverables" (M-B22).
- Scattered "deferred to migration" / "when migration shows demand" lines in `spec.md` (1287, 1291, 3855, 6361, 10056) and `decisions.md` (D-140, D-141 and D-143 among them).

## 3. Rationale by contrast with FlightCore (the bulk)

Arguments of the form "FlightCore did X and it went wrong, so we do Y".
The lesson usually stands without the name, restated as a general pitfall.
A standalone reader can't check the FlightCore evidence either way.

**spec.md**, by section (count of hits):

| Section | Hits | Example |
|---|---|---|
| §5.3 "Why derivatives may read outputs" | 2 | FlightCore's fused `f_ode!` |
| §6.2 aggregation idiom | 2 | FlightCore's tree walk |
| §7.4 fused-evaluation lineage | 2 | "what FlightCore's fused `f_ode!` did" |
| §8.3, §8.7 | 2 | intermediates precedent, `Subsampled` |
| §9.7 compiled executor | 5 | allocation comparison vs FlightCore |
| §10.7 pacing | 1 | "`margin = ∞`, FlightCore's behavior" |
| §11.1, §11.6, §11.7 | 7 | lock choreography, dead slider, poke-any-`u` |
| §12.2, §12.4 tail, §12.5 | 7 | `nthreads` error, `SimulationTermination`, `io_start` |
| §13, §13.5 | 3 | "two lessons FlightCore paid for" |
| §14.7, §14.8 trim | 9 | FlightCore formulation "survives verbatim", hand-scaled threshold |

**decisions.md**: 44 of 261 entries carry at least one hit. Heaviest are
D-141 (6), D-140 (4), D-143 (4), D-069, D-093, D-105 and D-132 (3 each).
Most sit in **Rationale** or **Rejected** items ("*Always-hot widgets:* FlightCore's
dead slider", "*Framework-owned hook loop (FlightCore's shape)*"). Full list in
the appendix.

**Companions**: `inbound_periphery_walkthrough.md:15`, `trim_environment_walkthrough.md:90`.

## 4. Grounding in Flight.jl code (case studies and surveys)

Evidence drawn from real consumer code, often with `file.jl:line` citations
into a repo the reader doesn't have.

- `spec.md` §15 (9659-10300) — all four case studies: `Vehicle` today (`aircraftbase.jl:142-170`), `PistonEngine` and the C172X FCS PID cascade, the interactive C172X/Xv1 demo (`FlightApps/demos/c172_demos.jl`), the strapdown IMU from `navsensors.jl`. This is Part V's whole content.
- `spec.md` §12.5 (6996) — "What the consumers demonstrably mutate mid-run is surveyed here".
- `spec.md` §7.1 (1337, 5 hits) — `RQuat`/`Ranged` state fields.
- `decisions.md` D-132 cites `iodevices.jl:36`; D-141 cites line ranges (`:330-346`).
- `trim_environment_walkthrough.md:28` — `lib/FlightApps/src/c172/c172.jl:825-854`.
- The phrase "today's ..." (36 times in `spec.md`, 21 in `decisions.md`) often means "in Flight.jl today". Not every instance does.

## 5. Aerospace domain flavor (not Flight.jl references)

Aircraft examples, "flight condition", gravity as `g`. These don't name
Flight.jl and make sense to a newcomer. Likely keep; listed so the choice is
deliberate.

- `src/trim.jl:1, 22` — "the aircraft author ships".
- `src/trim.jl:354`, `src/conditions.jl:493` — "a terrible flight condition" (the same aphorism also in `spec.md:8893` and five times in `decisions.md`).
- `docs/design/tools/gloss_table.md:180, 186` — *baseline* and *`design_world`* glossed in aircraft terms.
- ~50 "aircraft" mentions in `spec.md`, 28 in `trim_environment_walkthrough.md`.

## 6. Prototypes

- `prototypes/sketch_decoder.jl` — pre-design sketch: `Cessna172X{K, A}`, airframe mass, "the migration's" (36, 218, 259).
- `prototypes/cellstore_bench/README.md:76` — "C172X-scale model" as a benchmark size.

## 7. Historical records (frozen)

These record what happened, and rewriting them would falsify them.
The choice is to keep them as history or leave them out of the release.

- `docs/reports/` — 4 report directories. 9 files mention Flight.
- `docs/design/briefs/` — 45 briefs. 14 mention Flight.
- `docs/design/design.pdf` — built from the spec. It inherits whatever the spec says and needs a rebuild after any change.
- Git history — 762 commits, starting in Flight.jl's `core-redesign-2` branch. The first ones talk about the Vehicle sketch and PistonEngine.

## Clean

`src/` and `test/` carry no Flight.jl names. "Consumer" there is the framework's
own producer/consumer term. `Project.toml`, `implementation.md` and `inspector/`
are clean.

## Appendix: raw hits in live files

Pattern covers the Flight.jl names, its subpackages, legacy code names (`f_ode!`, `KinData`, `PistonEngine`, ...), the C172/Xv1 demos, and aerospace wording in `src/`. Historical records under `docs/reports/` and `docs/design/briefs/` are excluded.

```
README.md:5:being built to replace `FlightCore` as the substrate for `FlightPhysics` and
README.md:6:`FlightApps` in Flight.jl, and it is not yet usable as a dependency: the
README.md:183:The repository was spun off from Flight.jl's `core-redesign-2` branch on
docs/design/decisions.md:305:- *`f_step!`:* step-size-dependent semantics.
docs/design/decisions.md:586:  usage. The substrate rejection's evidence dossier, from FlightCore's own
docs/design/decisions.md:647:  the signal table; FlightCore's whole-tree atomicity was a call-tree artifact.
docs/design/decisions.md:679:  semantics, the [§2.2][s2-2] `f_step!` footgun class, made common by [§3.1][s3-1] externalized
docs/design/decisions.md:695:pure sleep, ∞ = pure busy-wait = FlightCore).
docs/design/decisions.md:819:- *Always-hot widgets:* FlightCore's dead slider — visually live, silently
docs/design/decisions.md:861:  no correct placement under asynchronous waiters; cf. FlightCore's `io_start`
docs/design/decisions.md:921:- *Retaining `user_callback!`:* the periphery's `f_step!` — unrecorded
docs/design/decisions.md:1095:- *FlightCore tree walks:* silent omission — the zero-edit convenience *is* the
docs/design/decisions.md:1207:- *Instance wrappers (`Subsampled`-style):* wraps the field type, pollutes
docs/design/decisions.md:1256:- *FlightCore-style concurrent multi-device writing of one input:* a bug
docs/design/decisions.md:1650:always abnormal; no `SimulationTermination` exception type.
docs/design/decisions.md:1875:  fabricated zero is a fine probe input and a terrible flight condition.
docs/design/decisions.md:1914:  diagnostics discarded — FlightCore's rational choice only because Jacobians
docs/design/decisions.md:1915:  through mutating `f_ode!` were unreachable.
docs/design/decisions.md:1939:- The C172 audit is Interpolations tables (prefer cubic knots), saturation
docs/design/decisions.md:1967:- The world-level `f_init!` wrapper dissolves into the `baseline` condition:
docs/design/decisions.md:2039:- *Split-form sketch files and separate `navsensors.jl`/`imu.md` notes:*
docs/design/decisions.md:2047:  (a fabricated zero is a fine probe input and a terrible flight condition —
docs/design/decisions.md:2596:acquisition per run — FlightCore's create-a-new-socket-each-`init!` in
docs/design/decisions.md:2619:- *`Event` start gate "as today":* [§12.3][s12-3]'s rejected primitive — the `io_start`
docs/design/decisions.md:2626:- *Always-spawned loop task FlightCore-style:* uniform topology whose only
docs/design/decisions.md:2646:semantics are explicit casts at the point of use (`RQuat(x.q, normalization =
docs/design/decisions.md:2647:false)` — today's `f_ode!`-over-raw-views pattern made immutable); invariants
docs/design/decisions.md:2905:- *Framework-owned hook loop (FlightCore's shape):* its eight hooks were never
docs/design/decisions.md:2994:**Rationale.** Classification is the author's, as FlightCore's
docs/design/decisions.md:2995:`InputMappingError` docstring already assigned it; `report(handle, …)` is
docs/design/decisions.md:3001:- *A marked exception type (`InputMappingError` successor):* vestigial under
docs/design/decisions.md:3035:join-a-running-session find a customer. Supporting fact: FlightCore has no
docs/design/decisions.md:3362:off-trajectory (re-`init!` to continue); [§16][s16]'s FlightCore allocation comparison
docs/design/decisions.md:3436:three-equation C172 cruise problem was added to [§14.7][s14-7].
docs/design/decisions.md:3650:outline. Grounding: the C172's engine-speed equilibrium
docs/design/decisions.md:3903:FlightCore's `interrupt!` (iodevices.jl:36, its one override closing UDPInput's
docs/design/decisions.md:3905:[§12.4][s12-4](3)'s `unblock!`, not of this path; FlightCore has no
docs/design/decisions.md:3918:  called `stop` anyway — the FlightCore name would also import an unrelated
docs/design/decisions.md:4251:  C172X scale and 50 Hz in the configuration [Appendix B][sB] calls the honest
docs/design/decisions.md:4406:  aircraft author has — the aero validity envelope is a box in (TAS, α, β) and
docs/design/decisions.md:4429:[§15.1][s15-1]'s `VehicleDynamics` instance is the canonical dissolution. (ii)
docs/design/decisions.md:4441:the strut's business, not the steering law's; re-factoring `AbstractSteering`
docs/design/decisions.md:4460:`VehicleDynamics`, with the split and its bundle port noted as the residual
docs/design/decisions.md:4461:remedy not taken; the `AbstractSteering` contract change is an
docs/design/decisions.md:4519:initialized on ground. `PistonEngine`'s two `PIVector` instances (`idle`,
docs/design/decisions.md:4520:`frc`) are verified reset-free in today's code (`piston.jl:295-449`: `f_ode!`
docs/design/decisions.md:4521:runs both in every engine state, `f_step!` does mode transitions only,
docs/design/decisions.md:4522:`f_init!` sets gains; windup across unused phases is already handled by the
docs/design/decisions.md:4524:their `f_init!` gain writes becoming construction-time parameters ([D-089][d-089]). The
docs/design/decisions.md:4659:(`aircraftbase.jl:27-35`) contributes zero to both external wrench and internal
docs/design/decisions.md:4660:angular momentum while `VehicleDynamics` requires both inputs unconditionally,
docs/design/decisions.md:4667:wrench ≡ 0" out loud — instead of FlightCore's silent identity methods, whose
docs/design/decisions.md:4684:- *A configuration-aware `VehicleDynamics` branching on whether contributors
docs/design/decisions.md:4786:as though the duplication stays small, when at C172X scale it is four
docs/design/decisions.md:4912:  correct one, so a C172X at `h = 0.02, n = 1` under a 50 Hz FCS simply flies a
docs/design/decisions.md:4935:authored `RQuat` of `Dual`s → the `SVector{4}` state leaf at `Dual`), partials
docs/design/decisions.md:5018:  fabricated zero is a fine probe input and a terrible flight condition.
docs/design/decisions.md:5050:place of FlightCore's hand-scaled absolute threshold, and a well-scaled valley
docs/design/decisions.md:5067:  [§14.7][s14-7] itself criticizes FlightCore for, and the finding's divergence follows
docs/design/decisions.md:5446:evaluator, a hand-rolled per-component check, today's FlightCore path in [§16][s16]'s
docs/design/decisions.md:5456:chunk sizes, and [§16][s16]'s FlightCore value comparison is a tolerance comparison by
docs/design/decisions.md:5556:*promote to output* (FlightCore precedent: intermediates were only ever
docs/design/decisions.md:6753:customer: the FlightCore lineage record is that intermediates were only ever
docs/design/decisions.md:6823:being legacy FlightCore's own discrete state field (`Model.s`), which [§12.5][s12-5]'s
docs/design/decisions.md:7182:a terrible flight condition — and [§10.5][s10-5]'s content defense ("what a tick at
docs/design/decisions.md:7511:  input and a terrible flight condition.
docs/design/decisions.md:8138:`fragment`, `at` and `combine` share a namespace with FlightPhysics domain
docs/design/decisions.md:9243:rather than "both". A predicate earns its place at C172X scale, where the
docs/design/briefs/brief_increment_23.md:4:> below are the old layout: the worktree `~/.julia/dev/Flight.jl-core-redesign-2`
docs/design/briefs/brief_increment_23.md:10:Worktree `~/.julia/dev/Flight.jl-core-redesign-2`, branch `core-redesign-2`,
docs/design/briefs/draft_step1b_entries.md:96:rather than "both". A predicate earns its place at C172X scale, where the
docs/design/briefs/spec_rewrite_pilot.md:39:Most transitions in FlightPhysics mix input predicates with state thresholds, so this case matters in practice. The piston engine's `starting → running` fir
docs/design/briefs/spec_rewrite_pilot.md:188:**Why iterate.** Under a single pass, a cascade of N logically simultaneous transitions (supervisor FSM → subordinate FSM → …) takes N steps to complete, a
docs/design/briefs/brief_increment_21.md:4:> below are the old layout: the worktree `~/.julia/dev/Flight.jl-core-redesign-2`
docs/design/briefs/brief_increment_21.md:11:`/Users/miguel/.julia/dev/Flight.jl-core-redesign-2/prototypes/kernel` (a git
docs/design/briefs/brief_increment_21.md:12:worktree, branch `core-redesign-2`; never `cd` elsewhere — `cd` is aliased to
prototypes/cellstore_bench/README.md:76:  C172X-scale model both land in single-digit seconds, which makes §9.7's
prototypes/sketch_decoder.jl:52:    q_eb   = RQuat{Float64},
prototypes/sketch_decoder.jl:129:init_x(::WA) = (q_wb = RQuat(), q_ew = RQuat(), h_e = HEllip())
prototypes/sketch_decoder.jl:137:    q_wb = RQuat{Float64}, q_ew = RQuat{Float64}, q_nw = RQuat{Float64},
prototypes/sketch_decoder.jl:138:    q_nb = RQuat{Float64}, q_eb = RQuat{Float64}, e_nb = REuler{Float64},
prototypes/sketch_decoder.jl:259:#A parametric child field (sys::S, today's Cessna172X{K, A} shape) is the
docs/design/companions/trim_environment_walkthrough.md:22:Today, `Model{<:Aircraft}`'s `f_ode!` and `f_init!` take the atmosphere and
docs/design/companions/trim_environment_walkthrough.md:27:The C172's trim assignment is where this bites hardest
docs/design/companions/trim_environment_walkthrough.md:28:(`lib/FlightApps/src/c172/c172.jl:825-854`). `Kinematics.Initializer` — the
docs/design/companions/trim_environment_walkthrough.md:90:models*. That part is an artifact of FlightCore's vocabulary: the only way one
docs/design/companions/trim_environment_walkthrough.md:95:whose existence is a threading fixture, an `f_init!` at world level whose job
docs/design/companions/trim_environment_walkthrough.md:194:Then `θ_constraint(; v_wb_b, γ_wb_n, φ_nb)` (`aircraftbase.jl:110-118`)
docs/design/companions/trim_environment_walkthrough.md:464:record left over from a different flight condition. It is not in the spec's
docs/design/companions/trim_environment_walkthrough.md:485:aero model is a *box* in (TAS, α, β): the C172's `α_a ∈ [−5°, 15°]` keeps
docs/design/companions/trim_environment_walkthrough.md:494:target set, any environment, with no closed-form work by the aircraft author.
src/conditions.jl:493:fabricated zero is a fine probe input and a terrible flight condition.
docs/design/companions/inbound_periphery_walkthrough.md:15:feed values into a simulation that owns its data exclusively?** FlightCore's
docs/design/pdf/gallery/sample.jl:3:    (pose = KinPose{T}, q_eb = RQuat{T})
docs/design/pdf/gallery/sample.jl:14:    q::RQuat{T}
src/trim.jl:1:# The trim service (§14.7, §14.8): the problem value the aircraft author ships,
src/trim.jl:22:What the aircraft author ships: what the solver may vary, what those decisions
src/trim.jl:354:a fine probe input and a terrible flight condition (§14.6's barrier, reaching
docs/design/extensions.md:19:The framework began as a rewrite of `FlightCore`, and its early decisions were shaped
docs/design/extensions.md:20:by what porting `FlightPhysics` and `FlightApps` would need. The question this section
docs/design/extensions.md:174:Re-examination showed the two decisions most suspected of `FlightCore` inheritance
docs/design/extensions.md:176:explicitly identifies `Subsampled`'s parent-relative multipliers as a call-tree
docs/design/extensions.md:179:assemblies (a departure from FlightCore's execution-through-composition, coinciding
docs/design/extensions.md:182:Where the `FlightPhysics`/`FlightApps` assumption genuinely biased the design is the
docs/design/tools/decisions_style.md:68:  not divergence — it stays where it is. Ruled 2026-08-14: FlightCore, the
docs/design/spec.md:1:# A Modeling & Simulation Framework for Flight.jl — Specification
docs/design/spec.md:104:    - [15.2 Torture tests for the §5.2 interfaces: `PistonEngine` and the FCS PID cascade](#152-torture-tests-for-the-52-interfaces-pistonengine-and-the-fcs-pid-cascade)
docs/design/spec.md:106:    - [15.4 The interactive C172X demo: the periphery under load](#154-the-interactive-c172x-demo-the-periphery-under-load)
docs/design/spec.md:148:`FlightCore` as the substrate for `FlightPhysics` and `FlightApps`. It is the
docs/design/spec.md:150:present tense. The new framework must match or surpass `FlightCore` in
docs/design/spec.md:158:  what `FlightPhysics` and `FlightApps` demonstrably *do* in their code, unit
docs/design/spec.md:159:  tests and demos. Every `FlightCore` call site in the consumers is read as
docs/design/spec.md:164:  `FlightPhysics` and `FlightApps` is expected and accepted.
docs/design/spec.md:167:  fundamental strengths of Flight.jl. Those strengths are zero-allocation
docs/design/spec.md:257:- **No unconditional per-step hook**, so no `f_step!` equivalent. Every current
docs/design/spec.md:457:`KinData` mistake ([§15.1][s15-1]). Pose is stage 1 and velocity-derived quantities are
docs/design/spec.md:468:    (pose = KinPose{T}, q_eb = RQuat{T})
docs/design/spec.md:868:FlightPhysics/FlightApps ([§15.2][s15-2]). Derivative/output overlap is the *norm* in
docs/design/spec.md:871:split expensive here ([D-015][d-015]). FlightCore's fused `f_ode!` already embodied the
docs/design/spec.md:888:it, and it is the rung that absorbs most of the class. The `VehicleDynamics`
docs/design/spec.md:962:domain and in the current C172 model. The unit delay carries a caveat. It
docs/design/spec.md:1089:assembly speaking only of its own children. `Cessna172` hands its `trn` input to
docs/design/spec.md:1094:input_connections(::Cessna172) = ("trn" => "systems/trn", …)
docs/design/spec.md:1273:Each recursion step of FlightCore's tree walk becomes one visible junction at
docs/design/spec.md:1274:the level that owns the contributors. For the C172 that is about four junctions
docs/design/spec.md:1298:external wrench and to internal angular momentum, while `VehicleDynamics`
docs/design/spec.md:1337:modes. Domain wrapper types (`RQuat`, `Ranged`) are not state leaves. An
docs/design/spec.md:1396:`f_ode!` code performs on its raw views. Invariants live where the design
docs/design/spec.md:1411:  domain wrapper, where wanted, is one explicit invariant-free cast (`RQuat(x.q,
docs/design/spec.md:1456:  `FrameTransform`, `MassProperties`, `KinData`, `AirData`, geodesy value types,
docs/design/spec.md:1654:FlightCore's fused `f_ode!` did economically, minus the checked ordering.
docs/design/spec.md:2029:| `T`, alone or as a type parameter (`SVector{3, T}`, `RQuat{T}`) | **tolerant** | the [activation](#g-activation) scalar or a frozen `Float64` |
docs/design/spec.md:2158:- **`T`, alone or as a type parameter** (`SVector{3, T}`, `RQuat{T}`,
docs/design/spec.md:2235:- "`init_x` field `q_nb::RQuat` is not a state leaf — declare the `SVector{4}`
docs/design/spec.md:2368:([D-194][d-194]). FlightCore is the precedent, where an intermediate was inspected by
docs/design/spec.md:2439:parametric fields, exactly today's `Cessna172X{K, A}` shape. Alongside the
docs/design/spec.md:2560:*for*, namely dispatching domain code on `::Cessna172X` and a reusable
docs/design/spec.md:2580:primitive `PistonEngine` and a composite turbofan assembly alike. And class is
docs/design/spec.md:2787:rate ([§10.5][s10-5]), never a per-instance value. The FlightCore-`Subsampled`-style
docs/design/spec.md:2871:**Why `select` exists.** At C172X scale the feed list below already computes
docs/design/spec.md:2911:passing the rest up must name the fed ones in `except`. At C172X scale that is
docs/design/spec.md:2926:    …                                            # ~10 entries for the C172X
docs/design/spec.md:3432:already put their valid default (`RQuat()` is the identity, and the `@kwdef`
docs/design/spec.md:3727:themselves are [§14][s14]. The C172 trim problem (`c172.jl`: `TrimState`,
docs/design/spec.md:3738:  from in-place mutation plus self-invoked `f_ode!` to a pure function
docs/design/spec.md:3758:  warn-but-assign `f_init!`.
docs/design/spec.md:3840:Silicon, with the last two rows extrapolated to a C172X-scale model of
docs/design/spec.md:3849:| C172X-scale model, extrapolated | nominal | seconds |
docs/design/spec.md:3850:| C172X-scale model, extrapolated | `Dual` | tens of seconds, before mitigation |
docs/design/spec.md:3912:`@ballocated f_ode!`/`f_step!`/`f_periodic!` idiom and the seam the [§16][s16]
docs/design/spec.md:3913:FlightCore comparison measures through.
docs/design/spec.md:4132:Most transitions in FlightPhysics mix input predicates with state thresholds, so
docs/design/spec.md:4799:when killing `f_step!`. Cascades are not a corner case either. Externalized FSM
docs/design/spec.md:5002:- **`margin = ∞`, pure busy-wait.** FlightCore's behavior, with maximum frame
docs/design/spec.md:5046:of them wants the data the loop is stepping. FlightCore's answer is one big
docs/design/spec.md:5137:  section.** FlightCore's pathologies are all "arbitrary code under a shared
docs/design/spec.md:5254:the session lasts. At C172X scale and 50 Hz that is gigabytes per hour, and
docs/design/spec.md:5761:Aircraft-semantic derivation must *not* ride along. The C172X
docs/design/spec.md:5894:FlightCore's input/output/GUI trichotomy is lock choreography, not modeling.
docs/design/spec.md:6007:function loop(dev::UDPInput, handle)             # source-driven, data-dependent
docs/design/spec.md:6254:FlightCore's `InputMappingError` docstring assigned it the same way. What
docs/design/spec.md:6269:Panels remain per-[component](#g-component) extensions in FlightCore's style,
docs/design/spec.md:6286:This retires FlightCore's dead-slider convention and replaces it with checked
docs/design/spec.md:6288:command in this configuration.** The dead slider is the `Cessna172Xv1`
docs/design/spec.md:6322:unpokeable.** FlightCore's poke-any-`u` workflow does not survive
docs/design/spec.md:6456:count-only display ("`MalformedDatum` from `UDPInput#3`: 1 482
docs/design/spec.md:6597:The freeze FlightCore's `nthreads` error prevented cannot reproduce here, for
docs/design/spec.md:6737:   catches that raise and treats it as shutdown. This demotes FlightCore's
docs/design/spec.md:6771:   FlightCore's `SimulationTermination` catch path was the precedent, though
docs/design/spec.md:6849:`init!`, since resource acquisition is per-run. FlightCore's
docs/design/spec.md:6996:What the consumers demonstrably mutate mid-run is surveyed here. FlightCore's
docs/design/spec.md:7036:[periphery](#g-periphery)'s `f_step!`, and cheap composition leaves it
docs/design/spec.md:7507:Two lessons FlightCore paid for ground it. The first is the compact-backtrace
docs/design/spec.md:7509:unreadable. The second is the `SimulationTermination` machinery, which
docs/design/spec.md:7728:  `InputMappingError`.
docs/design/spec.md:7999:FlightCore's `SimulationTermination` idiom (model code throws, and the loop
docs/design/spec.md:8474:declare `initialize(::C, spec)`, today's `f_init!` reborn declaratively, and
docs/design/spec.md:8488:condition(eng::PistonEngine; n_eng) =
docs/design/spec.md:8495:condition(sys::C172XSystems; n_eng, α_a, β_a) = combine(
docs/design/spec.md:8617:An authored `RQuat` of `Dual`s becomes the `SVector{4}` state leaf at `Dual`,
docs/design/spec.md:8621:authored `RQuat` value becomes the `SVector{4}` state leaf it initializes.
docs/design/spec.md:8761:sweep dominates, exactly as `f_ode!` does today. `apply!` ends at established
docs/design/spec.md:8893:probe input and a terrible flight condition. A silently zeroed `mixture` kills
docs/design/spec.md:8919:The aircraft author ships one value. It says what the solver may vary, what
docs/design/spec.md:8936:[Worked](#g-worked), the C172 cruise case reduces to its three-equation core.
docs/design/spec.md:9003:- **The FlightCore formulation's core is correct and survives verbatim as user
docs/design/spec.md:9007:- **What changes is the numerics.** Trim is a square root-find. FlightCore's
docs/design/spec.md:9010:  the mutating `f_ode!` chain and the assignment math were out of reach
docs/design/spec.md:9040:  `state_update`, which was structurally impossible under FlightCore's
docs/design/spec.md:9144:That objective is dimensionless where FlightCore's threshold was hand-scaled
docs/design/spec.md:9346:C172 migration audit (one afternoon):
docs/design/spec.md:9413:**The world wrapper dissolves.** Today's `f_init!(::Model{<:SimpleWorld})`
docs/design/spec.md:9643:[§5.2][s5-2] interfaces and at the [§11][s11] staging shapes, the full C172X
docs/design/spec.md:9646:settled, the migration of FlightPhysics and FlightApps among them.
docs/design/spec.md:9659:`Vehicle.f_ode!` (`aircraftbase.jl:142-170`) is a hand-woven instance of the
docs/design/spec.md:9664:| `kinematics.u .= dynamics.x` — velocity extracted directly from the state vector because `f_ode!(dynamics)` can't run yet | `dyn`'s stage-1 output, ordered first by construc
docs/design/spec.md:9665:| Hand-ordered `f_ode!` body (kinematics → airdata → systems → route five `dynamics.u` assignments → dynamics last) | Build-time topological sort; wrong wiring = build error n
docs/design/spec.md:9668:| `f_step!` quaternion renorm + engine-phase/stall-latch checks | `state_projection` hook + [boundary-detected](#g-boundary-detected) events with defined semantics |
docs/design/spec.md:9669:| `Aircraft.f_ode!` runs avionics before the vehicle → continuous avionics reads one-stage-stale `vehicle.y` (implicit delay) | Avionics ordered inside the [sweep](#g-sweep), 
docs/design/spec.md:9673:`VehicleDynamics` pairs a state-only velocity output with
docs/design/spec.md:9675:velocity state reaches into initialization, where `f_init!` carries the line
docs/design/spec.md:9678:The same exercise surfaced a migration cost. Today's monolithic `KinData`
docs/design/spec.md:9689:aerodynamics. The current C172 model already breaks it with a filter state,
docs/design/spec.md:9694:### 15.2 Torture tests for the §5.2 interfaces: `PistonEngine` and the FCS PID cascade
docs/design/spec.md:9698:interfaces before adoption: `PistonEngine` on the continuous side, `PID` and
docs/design/spec.md:9699:the C172X FCS on the discrete one. A third exercise takes the supervisor
docs/design/spec.md:9703:#### `PistonEngine`: the continuous side
docs/design/spec.md:9718:  `f_ode!` body, four lookups and the mode branch, at each of the four RK
docs/design/spec.md:9720:- `f_step!`'s transitions become [boundary-detected](#g-boundary-detected)
docs/design/spec.md:9726:  in `PistonEngineY`.
docs/design/spec.md:9728:#### `PID` and the C172X FCS: the discrete side
docs/design/spec.md:9730:`PID` (control.jl:431-471) and the C172X FCS around it represent the discrete
docs/design/spec.md:9778:included. The second is mode-transition resets. `f_init!` plus a
docs/design/spec.md:9814:therefore the *only* same-tick path. Today's hand-ordering, `f_init!` before
docs/design/spec.md:9890:  component. That embedded-filter case is the `Cessna172Xv0` → `Xv1` throttle
docs/design/spec.md:9893:### 15.4 The interactive C172X demo: the periphery under load
docs/design/spec.md:9896:the real deployment. `generic_simulation()` (`FlightApps/demos/c172_demos.jl`)
docs/design/spec.md:9897:builds `SimpleWorld(Cessna172Xv1, SimpleAtmosphere, HorizontalTerrain)` and
docs/design/spec.md:9899:init, a paced run and post-run plots. The method treats FlightCore's
docs/design/spec.md:9938:- **The Xv1 actuator sliders.** These are FlightCore's dead sliders.
docs/design/spec.md:9963:- The routing convenience a command bundle bought in FlightCore's
docs/design/spec.md:9972:- `SimpleWorld(Cessna172Xv1(), SimpleAtmosphere(), HorizontalTerrain(h_LOWS15))`
docs/design/spec.md:9976:  FlightCore kept implicit in its `U()`-vs-field convention is now the
docs/design/spec.md:10110:The source is a pre-design FlightCore sketch, `navsensors.jl`, whose operative
docs/design/spec.md:10195:    (q_eb = RQuat{T}, r_eb_e = SVector{3,T},
docs/design/spec.md:10205:# output_direct: the sketch's f_ode! math verbatim (lever arm, gravity, Earth rate) → (; ω_ic_c, f_c_c)
docs/design/spec.md:10207:    q = RQuat(x.q, normalization = false)              # [§7.1][s7-1]'s explicit cast
docs/design/spec.md:10220:    q_s = RQuat(s.q, normalization = false);  q_u = RQuat(u.q, normalization = false)
docs/design/spec.md:10312:Three axes are still to be settled: the migration of FlightPhysics and
docs/design/spec.md:10313:FlightApps, the GUI panel authoring API, and log and [trace](#g-trace)
docs/design/spec.md:10318:What follows is an outline for FlightPhysics/FlightApps, not a specification.
docs/design/spec.md:10327:| The `KinData`-style output splits | — | — | — |
docs/design/spec.md:10329:| Comparison criteria against FlightCore's demonstrated strengths | three strengths to compare against: zero-alloc stepping, flexibility, interactive operation | [§9.7][s9-7]
docs/design/spec.md:10331:| The conventional exported aircraft surface for generic periphery consumers | pose and velocity faces with wrapper types, the periphery-facing half of the `KinData` successo
docs/design/spec.md:10333:| The steering contract re-factoring | `AbstractSteering` moves from "give me the angle" to `(engaged, ψ_cmd)` | [§5.4][s5-4] | — |
docs/design/spec.md:10335:| The state-declaration conversion to the closed vocabulary | each `RQuat` state field becomes its `SVector{4}` backing, each `Ranged` state field a plain scalar | [§7.1][s7-
docs/design/spec.md:10341:| *Residual*: the C172 AD audit for trim | Interpolations tables (prefer cubic knots), saturation rank-deficiency (LM-tolerated, reported), the gear identically zero airborne
docs/design/spec.md:10350:**Comparison criteria.** FlightCore's demonstrated strengths are three:
docs/design/spec.md:10353:apples-to-apples with today's `@ballocated f_ode!` suites.
docs/design/spec.md:10359:periphery-facing half of the `KinData` successor.
docs/design/spec.md:10363:ports fed by scheduler components (about 7 for the C172X). Every
docs/design/spec.md:10394:The engine's two `PIVector` instances, `PistonEngine`'s `idle` and `frc`,
docs/design/spec.md:10397:unused phases. Their `f_init!` gain writes become construction-time
docs/design/spec.md:10405:([§5.4][s5-4]), worked on the shipped instance. `AbstractSteering` moves from
docs/design/spec.md:10409:otherwise manufacture. The `VehicleDynamics` instance standing beside it
docs/design/spec.md:10420:vocabulary ([§7.1][s7-1]). Each `RQuat` state field becomes its `SVector{4}`
docs/design/spec.md:10430:([§14.2][s14-2]) are generic names that share a namespace with FlightPhysics
docs/design/spec.md:12495:weighed against Flight.jl's fundamental strengths and recorded with its
docs/design/spec.md:12521:against a proposed mechanism to validate it before adoption: `PistonEngine`
docs/design/spec.md:12529:assembly of [§8.6][s8-6], the worked C172 cruise problem of [§14.7][s14-7],
```
