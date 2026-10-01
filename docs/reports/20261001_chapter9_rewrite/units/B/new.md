### 9.3 Probing and input synthesis

The build calls each user function once, as a [probe](#g-probe), to catch
malformed code early. Each call needs argument values, and not every argument
has a producer. This section covers, in order, the probe-everything scope,
probe argument sourcing and its two checks, root-input synthesis, probe
scoping, and the totality that stage code owes in return.

**The nominal evaluation probes every user function once**, at the initial
state, with real values ([D-050][d-050]). The set is the
stages, `x_deriv`, `s_update`, [guards](#g-guard), handlers and
`x_projection`. The probe checks shape and type conformance and discards the
results. All are pure, and the cost is one evaluation each.

"Fails loudly at build time where possible" ([§8.1][s8-1]) decides this. A
malformed `x_deriv` return must not wait for the first integrator step. Probes
see only the initial state's branch, so the marginal coverage is earliness,
not completeness. The always-on check ([§9.5][s9-5]) remains the completeness
backstop.

Probe arguments are sourced as follows:

- `x`/`s`/`m` come from `init_*` declarations, which declare by value.
- The stage-1 hand-down, `y_x` on the continuous [tier](#g-tier) and `y_s` on
  the discrete, comes from the stage-1 probes' *returns*. That hand-down is
  every stage-1 [port](#g-port) there is ([§5.2][s5-2]).
- Wired inputs come from upstream products.

Real values are available because the stage-2 chain is probed in topological
order. So every consumer is probed against the same value it will receive at
run time.

The [bundle law](#g-bundle)'s two remaining fields ([§5.2][s5-2]) are `ws`, the
[workspace](#g-workspace), and `t`. `t` is a clock value, sourced below with
`Δt`. **`ws` comes from invoking the component's `ws_init` allocator** at the
probing scalar (`Float64` at build), before the nominal evaluation's probes
that need it ([D-115][d-115]). The allocator runs that early because it reads
only the instance and the scalar ([D-077][d-077]) and derives nothing from
layouts.

Two checks ride the same pass. The first is the return's shape. A stage
returning something other than a `NamedTuple` fails here. The second is the
dead-stage rule. **A stage returning bare `(;)` produces no ports at all, and
is `DeadStage`**, fail-fast ([D-194][d-194]).

Exactly one kind of terminal has no producer, the
[root inputs](#g-root-input). **The build
synthesizes their values via `probe_value(::Type)`** ([D-051][d-051]).
Framework methods cover three kinds of type:

- `Real`, with `zero(T)`;
- `Bool`, with `false`;
- enums, with their first instance.

The ultimate fallback is the zero-argument constructor `T()`. That is where
well-behaved constrained types already put their valid default. For the
rotation-quaternion type, `RQuat()` is the identity. The `@kwdef`
convention supplies such a default broadly.

`probe_value` is overridable. A type whose valid default is not reachable that
way declares its own method. That method is also the [seam](#g-seam) a
[walked](#g-walked) type uses to state a constrained default. No method is a
build error, in the didactic style. It names the [face](#g-face) and the type,
and asks for one of the two fixes. An example is "no `probe_value` for
`Ranged{Float64, -1, 1}` at face `pilot.elevator_axis` — define
`probe_value(::Type{Ranged{Float64, -1, 1}})` or a zero-argument
constructor".

Synthesis never meets an abstract type. Root inputs are concrete by the
tight-bound rule, and the root-input type is the consuming entry evaluated at
`Float64` ([§8.2][s8-2]). [Abstract entries](#g-abstract-entry) only occur on
component-fed inputs, which the probe sources from upstream products.

Physically silly values are acceptable by construction. The probe checks
types, and return types that depend on input *values* are type instabilities,
banned by the branch-shape rule ([§8.3][s8-3]). The [§4.3][s4-3] write-side
granularity rule keeps root inputs predominantly scalar, so the surface is
small.

**Probe values are strictly probe-scoped** ([D-051][d-051]). Everything the
probe writes is garbage once the build finishes. Probe values never double as
initial root-input values, because that would smuggle in the default semantics
that [D-051][d-051] rejects.

The same doctrine covers the clock. **`t` is probe-scoped `0.0`**
([D-115][d-115]). Deployment binds no clock and `t₀` post-dates even
deployment ([§14.5][s14-5]), so `t` is a fabricated value. `Δt` in seconds
does not exist until the `Deployment` constructor binds `Δt_base`, since
deployment post-dates the build. Discrete-tier probes therefore supply a
placeholder period (`1.0`) in the bundle. It is a fabricated, probe-scoped
value like `t` and like any synthesized input. The probe checks types, not
physics.

`Simulation` must not reach its first [boundary](#g-boundary) with
uninitialized root inputs. **Every complete-world application, namely
`init!`, trim setup and trim commit, carries the pre-write
`UninitializedInputs` check** ([§14.6][s14-6], [D-149][d-149]).

Silly values are acceptable *because* the author is obliged to accept them.
That obligation is the author's side of the bargain. **Stage code must be
total over type-valid inputs** ([D-142][d-142]). Every probed user function
(stages, `x_deriv`, `s_update`, guards, handlers, `x_projection`) evaluates
without throwing on any input satisfying its declared types.

The domain is type-validity, not the probe's particular synthesized values.
The branch-shape rule already bans value-dependent return types. So types are
the only domain the framework can speak of, and the probe is the enforcement
moment, not the reason.

There are two consequence sites, with the same throw at both. At build it is a
`UserCodeFraming`-wrapped build failure ([§13.1][s13-1]). Its diagnostic
points at code that is "correct" on every trajectory it has ever seen. At
runtime it is a `StepError` and the run ends `errored` ([§13.4][s13-4]).
Exceptions from model code are always abnormal ([§13.5][s13-5],
[D-060][d-060]).

Three habits of shipped landing-gear code have sanctioned spellings:

- A *plausibility* check meaning "stop the run" is a published `Bool` output
  face plus `stop_on` ([§13.5][s13-5], [D-060][d-060]). A landing-gear strut
  model that throws on a touchdown overload is one such check. The face and
  `stop_on` are machinery already there.
- A *self-consistency* assert, such as an author checking that their own
  contact algebra cancels a velocity component to a hard tolerance, is a
  regression test about that algebra. Its home is the test suite
  ([D-142][d-142]). It is also the most probe-fragile of the three,
  since a near-degenerate synthesized geometry can keep the cancellation
  algebraically exact while missing an absolute tolerance in floating point.
- A *defensive exhaustiveness* branch is the third habit. Examples are an
  `else error("unrecognized surface type")` over a closed enum of ground-surface
  kinds, or a friction-coefficient constructor asserting an ordering of its
  arguments (static ≥ dynamic) when that constructor runs per step inside a
  stage.

A defensive-exhaustiveness branch is not banned validation but mislocated
validation. Totality
over a closed enum means handling every instance, and an `else error` is an
admission that the function is partial. **Parameter validation belongs where
user-controlled data enters** ([D-142][d-142]). That place is the constructors
of parameter and instance values. They run before the build, where asserts are
perfectly legitimate. Parameter validation never belongs inside a stage, on
probe-fed data.
