### 9.3 Probing and input synthesis

**[Probe](#g-probe)-everything scope.** The nominal [activation](#g-activation) probes every user
function once, at the initial state, with real values. The set is the stages,
`x_deriv`, `s_update`, [guards](#g-guard), handlers and
`x_projection`. The probe checks shape and type conformance and discards
the results. All are pure, and the cost is one evaluation each. "Fails loudly
at build time where possible" ([§8.1][s8-1]) decides this. A malformed
`x_deriv` return must not wait for the first integrator step. Probes
see only the initial state's branch, so the marginal coverage is earliness,
not completeness. The always-on check ([§9.5][s9-5]) remains the completeness
backstop.

**Probe argument sourcing.** `x`/`s`/`m` come from `init_*` declarations,
which declare by value. The stage-1 hand-down, `y_x` and `y_s` on the
discrete [tier](#g-tier), comes from the stage-1 probes' *returns*, which is
every stage-1 [port](#g-port) there is ([§5.2][s5-2]). Wired inputs come from
upstream products. Real values
are available because the stage-2 chain is probed in topological order, so
every consumer is probed against the same value it will receive at run time.
Two checks ride the same pass. The first is the return's shape. A stage
returning something other than a `NamedTuple` fails here. The second is the
dead-stage rule. A stage returning bare `(;)` produces no ports at all, and
is `DeadStage`, fail-fast. The [bundle law](#g-bundle)'s two remaining fields ([§5.2][s5-2])
are sourced as follows. `t` is probe-scoped `0.0`. Deployment binds no clock
and `t₀` post-dates even deployment ([§14.5][s14-5]), so like `Δt` below it is a
fabricated, probe-scoped value. `ws` comes from invoking the component's
`ws_init` allocator at the probing scalar. That allocator reads only
the instance and the scalar ([D-077][d-077]) and derives nothing from layouts, so it
runs before the nominal evaluation's probes that need it. Exactly one kind of
terminal has no producer: **root inputs**. The build synthesizes their values
via `probe_value(::Type)`. Framework methods cover `Real` (`zero(T)`), `Bool`
(`false`) and enums (first instance), and the ultimate fallback is the
zero-argument constructor `T()`. That is where well-behaved constrained types
already put their valid default (`RQuat()` is the identity, and the `@kwdef`
convention supplies it broadly). `probe_value` is **overridable**. A type
whose valid default is not reachable that way declares its own method, which
is also the [seam](#g-seam) a [walked](#g-walked) type uses to state a constrained default. No
method is a build error, in the didactic style. It names the [face](#g-face) and the
type, and asks for one of the two fixes ("no `probe_value` for
`Ranged{Float64, -1, 1}` at face `pilot.elevator_axis` — define
`probe_value(::Type{Ranged{Float64, -1, 1}})` or a zero-argument
constructor"). Synthesis never meets an abstract type. Root inputs are
concrete by the tight-bound rule ([§8.2][s8-2]; the root-input type is the
consuming entry evaluated at `Float64`), and [abstract entries](#g-abstract-entry) only occur
on component-fed inputs, which the probe sources from upstream products.
Physically silly values are acceptable by construction. The probe checks
types, and return types that depend on input *values* are type
instabilities, banned by the branch-shape rule. The [§4.3][s4-3] write-side
granularity rule keeps root inputs predominantly scalar, so the surface is
small. Three alternatives were rejected ([D-051][d-051]): inputs declared by value
à la `x_init`, NaN poison values, and init-service values.

**Probe values are strictly probe-scoped.** Everything the probe writes is
garbage once the build finishes. Probe values never double as initial
root-input values, because that would smuggle in the default semantics
rejected above. The same doctrine covers the clock. `Δt` in seconds does not
exist until `Simulation` binds `Δt_base`, since deployment post-dates the
build, so discrete-[tier](#g-tier) probes supply a placeholder period (`1.0`) in the
bundle. It is a fabricated, probe-scoped value like any synthesized input.
The probe checks types, not physics. `Simulation` must not reach its
first [boundary](#g-boundary) with uninitialized root inputs. Enforcement is the pre-write
`UninitializedInputs` check carried by every complete-world application,
namely `init!`, trim setup and trim commit ([§14.6][s14-6]).

**The author's side of that bargain.** Silly values are acceptable *because*
the author is obliged to accept them. **Stage code must be total over
type-valid inputs.** Every probed user function (stages, `x_deriv`,
`s_update`, guards, handlers, `x_projection`) evaluates without
throwing on any input satisfying its declared types. The domain is
type-validity, not the probe's particular synthesized values. The
branch-shape rule already bans value-dependent return types, so types are the
only domain the framework can speak of, and the probe is the enforcement
moment, not the reason ([D-142][d-142]). There are two consequence sites, with the
same throw at both. At build it is a `UserCodeFraming`-wrapped build failure
([§13.1][s13-1]) whose diagnostic points at code that is "correct" on every
trajectory it has ever seen. At runtime it is a `StepError` and the run ends
`errored` ([§13.4][s13-4]). Exceptions from model code are always abnormal
([§13.5][s13-5]). Three habits of shipped code have sanctioned spellings. A
*plausibility* check meaning "stop the run", such as a strut throwing on a
touchdown overload, is a published `Bool` output face plus `stop_on`
([§13.5][s13-5]), machinery already there. A *self-consistency* assert, such as an
author checking that their own contact algebra cancels a velocity component
to a hard tolerance, is a regression test about that algebra, and its home is
the test suite. It is also the most probe-fragile of the three, since a
near-degenerate synthesized geometry can keep the cancellation algebraically
exact while missing an absolute tolerance in floating point. And there is the
*defensive exhaustiveness* branch, an `else error("unrecognized surface
type")` over a closed enum, or a coefficient constructor asserting an ordering
of its arguments when that constructor runs per step inside a stage. Such a
branch is not banned validation but **mislocated** validation. Totality over
a closed enum means handling every instance, and an `else error` is an
admission that the function is partial. Parameter validation belongs where
user-controlled data enters, in the constructors of parameter and instance
values, which run before the build, where asserts are perfectly legitimate.
It never belongs inside a stage, on probe-fed data.
