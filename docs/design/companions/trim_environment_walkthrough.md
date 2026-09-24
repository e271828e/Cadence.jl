# Trim and the environment, from the ground up

*A companion explainer, not normative text. The ground truth is
`spec.md` [§4.4][s4-4] (field handles and the value-level constructor),
[§14.1][s14-1] (the pre-sweep doctrine), [§14.7][s14-7] and [§14.9][s14-9] (the trim problem and its
mounting), [§9.6][s9-6], and decision [D-139][d-139], which settled all of it on
2026-08-05 during the round-4 dry-run adjudication (commit `daf3298d`). This
document records the discussion that produced that row — the alternatives,
the arguments, and the two shapes that were kept as legitimate options rather
than decided between. Part II, added 2026-09-24 after decision [D-262][d-262]
landed the post-commit checks, takes the same problem up again from the
other end: what a check should check, and how the problem would be posed
from scratch. If this document and the spec ever disagree, the spec wins.*

Everything here answers one question: **the aircraft's trim assignment needs
to know the air density and the wind before anything has been evaluated —
where does it get them?** The question looks like plumbing. It is not: the
answer settles what a field handle is, what a "world" minimally has to
contain, and whether a trim problem is allowed to know anything about the
environment at all.

## The trigger: a condition that cannot be written

Today, `Model{<:Aircraft}`'s `f_ode!` and `f_init!` take the atmosphere and
terrain `Model`s as arguments, and `SimpleWorld` is the structural
acknowledgement of that: a container whose job is to hold the three of them
and thread the right pair into each aircraft call.

The C172's trim assignment is where this bites hardest
(`lib/FlightApps/src/c172/c172.jl:825-854`). `Kinematics.Initializer` — the
function that turns the seven trim decision variables plus the user's
`TrimParameters` into an initial kinematic state — takes
`atmosphere::Model{<:AbstractAtmosphere}` as its third argument, and uses it
twice:

```julia
atm_data = AtmosphericData(atmosphere, Ob)        # ρ at the trim location
TAS      = Atmosphere.EAS2TAS(EAS; ρ = atm_data.ρ)   # EAS → TAS needs ρ
...
v_ew_n   = atm_data.v                             # the wind vector
v_eb_n   = v_ew_n + v_wb_n                        # the wind triangle
```

Under the framework the initial condition is a *value* — a path-addressed
overlay applied before the first sweep exists ([§14.1][s14-1]) — and the condition
function is `d -> trim_condition(ac, params, d)` ([§14.7][s14-7]). It closes over the
aircraft component and a plain user `TrimParameters` record. It does not hold
the atmosphere, which in a full world is the aircraft's *sibling*, not its
child.

[§14.1][s14-1]'s pre-sweep doctrine, as originally written, admitted exactly two
escapes for a would-be init value that seems to depend on swept outputs: the
value is **caller-computable** (the doctrine's own example is trim's
`α_filt = α_a` — α is a decision variable, so the value is known one level
up, not computed below), or it is an **equilibrium constraint**, i.e. a job
for the trim service rather than for init. Neither covers ρ and `v_ew_n`.
They are not decision variables and not residuals; they are another
component's output, needed before any sweep has run.

The three workarounds that suggest themselves are each refused elsewhere in
the design. Duplicating the atmosphere's output-stage math inside aircraft
trim code is precisely the silent-drift class [§5.3][s5-3]'s whole stage discipline
exists to kill. Reading it through the problem's `reads` is circular — reads
are gathered *after* the sweep the condition precedes. And a pre-application
sweep is the "init as a third scheduled sweep" that [§14.2][s14-2] rejects by name.

That is dry-run finding #3, and it is where the discussion started.

## Fundamental dependence versus an incidental spelling

The productive move was to split the sentence "aircraft dynamics need the
atmosphere and terrain models" into two claims that had been travelling
together.

The **fundamental** claim is *field dependence*. The equations of motion are

> ẋ = f(x, u, t; A, S)

where A maps a position to an air state and S maps a ray to a surface
intersection. A and S are **boundary conditions of the dynamics**, evaluated
along the trajectory at points *the aircraft chooses* — the airflow stage
queries at the vehicle pose, each gear strut at its own contact point, the
ground-effect term at yet another. That is the whole reason [§4.4][s4-4] carries them
as query objects rather than as sampled data: nobody but the consumer knows
where to sample. And it is why baking a field into a component's parameters
is wrong in principle rather than merely inconvenient: parameters are frozen
at construction, so substitution dies (you cannot swap the atmosphere without
rebuilding the aircraft), and two aircraft in one world could legally fly
different atmospheres.

The **contingent** claim is that those fields arrive as *co-simulated
models*. That part is an artifact of FlightCore's vocabulary: the only way one
`Model` could share anything with another was to be handed the other `Model`
as an argument, so "the aircraft needs the air state at its own pose" got
spelled "the aircraft's update function takes the atmosphere `Model`". Once
you have that spelling you also inherit its consequences — a `SimpleWorld`
whose existence is a threading fixture, an `f_init!` at world level whose job
is to order two initializations, and a trim assignment that takes a `Model`
where it wants a function.

[§4.4][s4-4] separates the two. What a consumer consumes is a **handle**: an
immutable value with pure query functions on it (`ISAField(T_sl, p_sl,
wind)`; `airdata(field, pos, vel)`; `ray_intersect(field, p, u)`). A handle
is what the physics needs. A *producing component* is a separate question,
and it earns its place only when the field has something a value cannot
carry: dynamics (a wind field with its own state), tunable root inputs (sea-level
conditions a GUI or a script can move at runtime), or discrete behaviour
(gust triggering, a weather schedule). A frozen ISA atmosphere with no wind
has none of those, and the framework should not force a component on the user
who wants one.

The last piece is the obligation that makes the split usable, and it is the
one thing the spec had to gain: a field-emitting component must expose the map
(component, input values) → handle as a **plain, pure, public function**,
with its own swept output stage a one-line call to it — never the reverse.
`atmospheric_field(atm; T_sl, p_sl, wind)` is the `SimpleAtmosphere`
successor's. This has to be a *shipped component's* obligation, not something
a consumer retrofits: the real component composes sub-models (`SimpleAtmosphere`
is an ISA hydrostatic layer plus an arbitrary wind model,
`atmosphere.jl:260-278`), and anybody else who reconstructs that composition
has re-created the drift class. For bulk-data components the obligation is
weaker but the same in kind — the query math must be *reachable* as a plain
function; building a handle outside a build may then cost a resource load,
which is acceptable because condition authoring is design-time code.

With that in hand, [§14.1][s14-1]'s first escape stretches to cover the case: the
condition constructs the sweep's exact handle from the same values its
`baseline` writes into the environment component's root inputs, and calls the same
query function the consuming component calls. One implementation of the field
math, evaluated one level up. No pre-sweep, no new mechanism.

## Two world shapes

The separation immediately produces two legitimate rig shapes, and a good
part of the discussion was spent establishing that neither dominates.

**(a) The `SimpleWorld` successor.** Atmosphere and terrain are ordinary
sibling components. Their handle-valued output ports are wired to the
aircraft's environment input faces, declared abstractly (`terrain =
AbstractTerrainField`) so any concrete field type below the bound may be
wired — today's `AbstractTerrain` polymorphism moved to the declaration
layer. The environment's tunables — sea-level temperature and pressure, the
wind vector, terrain elevation — are the *atmosphere component's* root inputs,
which is the vocabulary everything else already speaks: conditions write them,
`capture` reads them back, linearization can take them as inputs, and the
trace header records them. This is what `design_world(ac)` ships, and it is
the blessed default for design tasks.

**(b) Aircraft as root.** Leave the environment faces unconnected. Then, by
the ordinary rules, each becomes a root input — one whose *value* is a
handle. The `baseline` writes it like any other root input. Nothing new is
required: [§4.4][s4-4] handles are immutable values carried by ordinary ports, and a
root input holds a value.

Three things are worth stating about the pair.

It is legal *by construction*, not by dispensation. There is no rule that an
input face must be wired rather than exported to the root; [§14.9][s14-9]'s earlier
"the aircraft is never literally the root" was reporting a habit, not
enforcing an invariant, and it is now written as a default rather than a
doctrine.

(b) covers nothing (a) cannot. Wrap the constants in a component, wire it, and
you have (a) back. The gain is purely one of ceremony, and its real niche is
**component test rigs**: a strut, an airflow stage or an aero block tested on
its own against a frozen environment. "Leave the face unconnected and write a
handle literal into the root input" is the function-valued sibling of a constant
source — the same answer dry-run finding #7 reaches for its `Constant{V}`
when an aggregation has zero contributors, one step up the type ladder.

Multi-aircraft worlds argue for (a), and this is the sharpest reason it stays
the default. With one producer fanned out to every consumer, environmental
consistency is *structural*: two aircraft cannot disagree about the wind
because they read one port. With root-input-held handles, consistency is baseline
discipline — the user must write the same value into every aircraft's root input,
and nothing checks that they did.

## Two ways to pose the trim problem

The other axis of the discussion has nothing to do with rig shape. It is
about *where enforcement of the flight-condition targets lives*.

**Analytic elimination** is what `c172.jl` does today, and it is worth
spelling out precisely, because its elegance is exactly what creates the
environment dependence. It parametrizes the wind-relative velocity vector in
**aerodynamic spherical coordinates** (magnitude, α, β) and then pins two of
the three:

- `TAS = EAS2TAS(EAS; ρ)` pins the **magnitude** — the EAS target enters
  here, and this is the query that needs ρ;
- `get_velocity_vector(TAS, α_a, β_a)` builds the vector with **β at its
  target** — β is pinned by construction;
- **α is the name of the one remaining free coordinate**, which is why it
  appears in the decision vector at all.

Then `θ_constraint(; v_wb_b, γ_wb_n, φ_nb)` (`aircraftbase.jl:110-118`)
converts the flight-path-angle target into the pitch attitude θ in closed
form, and finally the wind converts the wind-relative velocity into the
earth-relative state the kinematics actually stores:
`v_eb_n = v_ew_n + v_wb_n`. Seven decision variables (α, φ, n_eng, throttle,
aileron, elevator, rudder) against seven residuals (v̇ three, ω̇ three, engine
speed one).

**Decision-space enlargement** is the alternative. Promote the eliminated
coordinates to decision variables and demote the targets to residuals. The
condition becomes a pure map from d — the earth-relative velocity `v_eb_n` as
three free Cartesian components, θ free, φ as before, ψ still an analytic
state write — and the targets are enforced as residuals on *swept* outputs:

```
EAS_swept − EAS_target,   β_swept − β_target,   γ_swept − γ_target
```

Ten decisions against ten residuals. The condition math touches nothing but
the decision vector: no ρ, no wind, no query of any kind.

Here is the same story as a ledger. Each row is one degree of freedom of the
initial condition; the last column names what pays for freeing it.

| DOF | elimination | enlargement | paid by |
|---|---|---|---|
| ψ (heading) | analytic state write from the target | analytic state write from the target | — (pinned in both) |
| φ (bank) | decision variable | decision variable | — (free in both) |
| θ (pitch) | closed form via `θ_constraint` from the γ target | free decision variable | γ residual |
| velocity magnitude | pinned: `EAS2TAS(EAS; ρ)` | absorbed into `v_eb_n` | EAS residual |
| β (sideslip) | pinned by construction of the velocity vector | absorbed into `v_eb_n` | β residual |
| α (incidence) | free — the remaining spherical coordinate | absorbed into `v_eb_n` | — (free in both) |

The corollary is the point of the whole table. **The environment queries live
exactly in the pinnings that elimination performs.** ρ appears in the
magnitude pinning and nowhere else. The wind appears in the chart change from
wind-relative to earth-relative velocity and nowhere else. (And `v_wb_b`, the
wind-relative velocity that `θ_constraint` consumes, is itself a product of
the first pinning.) Enlargement is environment-blind not by cleverness but
because it performs no pinnings: it names the state coordinates the state
actually stores, and lets the solver find the ones that hit the targets.

There is also a middle point on the spectrum, worth recording because it is
cheap. Free **only the magnitude** — keep the spherical chart, make TAS a
decision variable, add the EAS residual. That is 8×8, it removes the ρ
dependence entirely, and it keeps α and β as explicit decision variables so
their aerodynamic bounds stay expressible. The *wind* dependence, by
contrast, only goes away with the full switch to Cartesian `v_eb_n`, because
the wind is what relates the two frames.

## The four quadrants

The two axes are orthogonal: (elimination | enlargement) × ((a)
component-produced | (b) root-input-held). All four combinations are legal, and
here is one sketch of each. **These are illustrative** — the exact spellings
of root-input writes, face names and helper signatures are not all fixed by the
spec, and where a sketch guesses, it guesses in the direction of readability.
Said once, for all four.

**(a) + elimination** — the full world, environment produced by a sibling
component, handle rebuilt at value level for the condition math.

```julia
world = design_world(ac)                  #aircraft + atmosphere + terrain (§14.9)
sim   = Simulation(world; h = 0.02)

T_sl, p_sl, wind = 288.15, 101325.0, WindVector(-10.0, 0.0, 0.0)

#the baseline is the sole writer of the environment (§14.6, §14.9)
baseline = override(ready_for_taxi(ac),
                    condition("atmosphere.T_sl" => T_sl,
                              "atmosphere.p_sl" => p_sl,
                              "atmosphere.wind" => wind,
                              "terrain.elevation" => 0.0))

#the same handle the sweep will build, built one level up from the same
#values, by the component's own value-level constructor (§4.4)
atm = atmospheric_field(world.atmosphere; T_sl, p_sl, wind)

params = TrimParameters(; Ob, EAS = 50.0, γ = 0.0, β = 0.0, ψ = 0.0, atm)

cruise = TrimProblem(
    guess      = (α = 0.06, φ = 0.0, n_eng = 0.75, throttle = 0.6,
                  aileron = 0.0, elevator = -0.05, rudder = 0.0),
    lower      = (α = -0.09, φ = -0.5, n_eng = 0.4, throttle = 0.0, …),
    upper      = (α =  0.26, φ =  0.5, n_eng = 1.1, throttle = 1.0, …),
    condition  = d -> trim_condition(ac, params, d),   #queries params.atm
    reads      = reads(v̇ = get_deriv("vehicle/dynamics", :v_eb_b),
                       ω̇ = get_deriv("vehicle/dynamics", :ω_eb_b),
                       ω̇_eng = get_face("pwp.ω_dot")),
    residuals  = (r, d) -> (fx = r.v̇[1], fy = r.v̇[2], fz = r.v̇[3],
                            mx = r.ω̇[1], my = r.ω̇[2], mz = r.ω̇[3],
                            eng = r.ω̇_eng),
    tolerances = (fx = 1e-3, fy = 1e-3, fz = 1e-3,
                  mx = 1e-4, my = 1e-4, mz = 1e-4, eng = 1e-4))

trim!(sim, at("aircraft", cruise); baseline)
```

`T_sl`, `p_sl` and `wind` are written once and used twice — into the
baseline, and into the handle. That single-variable discipline is the whole
safety argument, and the next section is about what happens when it lapses.

**(b) + elimination** — aircraft as root, environment faces unconnected, the
handle *is* the root-input value.

```julia
sim = Simulation(ac; h = 0.02)  #the `atm`/`trn` faces are unconnected → root inputs

atm = ISAField(; T_sl = 288.15, p_sl = 101325.0, wind = WindVector(-10.0, 0.0, 0.0))
trn = HorizontalTerrainField(; elevation = 0.0)

#one variable, two uses: the root input the sweep reads, and the params the
#condition math queries. No value-level constructor needed — in this rig
#the handle is not produced by anything, it is written.
baseline = override(ready_for_taxi(ac), condition("atm" => atm, "trn" => trn))

params = TrimParameters(; Ob, EAS = 50.0, γ = 0.0, β = 0.0, ψ = 0.0, atm)

cruise = TrimProblem(
    guess      = (α = 0.06, φ = 0.0, n_eng = 0.75, throttle = 0.6,
                  aileron = 0.0, elevator = -0.05, rudder = 0.0),
    lower      = …, upper = …,
    condition  = d -> trim_condition(ac, params, d),   #ρ and wind from params.atm
    reads      = reads(v̇ = get_deriv("vehicle/dynamics", :v_eb_b),
                       ω̇ = get_deriv("vehicle/dynamics", :ω_eb_b),
                       ω̇_eng = get_face("pwp.ω_dot")),
    residuals  = (r, d) -> (fx = r.v̇[1], …, eng = r.ω̇_eng),
    tolerances = (fx = 1e-3, …, eng = 1e-4))

trim!(sim, cruise; baseline)          #mounted at the root: no `at` needed
```

Note that the *problem* is identical in both sketches — same `condition`,
same `reads`, same residuals. Only the rig and where `atm` comes from
changed. That is [§14.9][s14-9]'s relocatability doing its job, and it is the reason
the problem must never *write* the environment: a condition entry naming a
wired input fails resolution by name (correctly), so a problem that wrote
`"atm"` would apply only to rigs of shape (b).

**(a) + enlargement** — the full world, and a trim problem that has never
heard of the atmosphere.

```julia
world    = design_world(ac)
baseline = override(ready_for_taxi(ac),
                    condition("atmosphere.T_sl" => 288.15,
                              "atmosphere.p_sl" => 101325.0,
                              "atmosphere.wind" => WindVector(-10.0, 0.0, 0.0),
                              "terrain.elevation" => 0.0))

#no handle field anywhere in here: targets, not derived quantities
params = TrimParameters(; Ob, EAS = 50.0, γ = 0.0, β = 0.0, ψ = 0.0)

cruise = TrimProblem(
    guess      = (vN = 50.0, vE = 0.0, vD = 0.0, θ = 0.06, φ = 0.0,
                  n_eng = 0.75, throttle = 0.6,
                  aileron = 0.0, elevator = -0.05, rudder = 0.0),
    lower      = …, upper = …,
    condition  = d -> trim_condition(ac, params, d),   #pure: d → state overlay
    reads      = reads(v̇ = get_deriv("vehicle/dynamics", :v_eb_b),
                       ω̇ = get_deriv("vehicle/dynamics", :ω_eb_b),
                       ω̇_eng = get_face("pwp.ω_dot"),
                       EAS = get_face("airflow.EAS"),     #swept, not computed
                       β   = get_face("airflow.β"),
                       γ   = get_face("kinematics.γ_wb_n")),
    residuals  = (r, d) -> (fx = r.v̇[1], fy = r.v̇[2], fz = r.v̇[3],
                            mx = r.ω̇[1], my = r.ω̇[2], mz = r.ω̇[3],
                            eng = r.ω̇_eng,
                            eas = r.EAS - params.EAS,     #target as residual
                            beta = r.β - params.β,
                            gamma = r.γ - params.γ),
    tolerances = (fx = 1e-3, …, eas = 1e-2, beta = 1e-4, gamma = 1e-4))

trim!(sim, at("aircraft", cruise); baseline)
```

**(b) + enlargement** — the thin rig, and the one safe use a handle still has
under this formulation.

```julia
sim = Simulation(ac; h = 0.02)
atm = ISAField(; T_sl = 288.15, p_sl = 101325.0, wind = WindVector(-10.0, 0.0, 0.0))
baseline = override(ready_for_taxi(ac),
                    condition("atm" => atm, "trn" => HorizontalTerrainField()))

params = TrimParameters(; Ob, EAS = 50.0, γ = 0.0, β = 0.0, ψ = 0.0)   #no handle

#a good starting point is still worth having, and a rough elimination is the
#natural way to compute one. Using `atm` HERE is safe: the guess affects how
#many iterations the solver takes and nothing else. A stale ρ costs
#iterations; a stale ρ inside `trim_condition` would cost correctness.
v_guess = cartesian_velocity_guess(params, atm; α = 0.06, φ = 0.0)

cruise = TrimProblem(
    guess      = (vN = v_guess[1], vE = v_guess[2], vD = v_guess[3],
                  θ = 0.06, φ = 0.0, n_eng = 0.75, throttle = 0.6,
                  aileron = 0.0, elevator = -0.05, rudder = 0.0),
    lower      = …, upper = …,
    condition  = d -> trim_condition(ac, params, d),
    reads      = reads(v̇ = get_deriv("vehicle/dynamics", :v_eb_b),
                       ω̇ = get_deriv("vehicle/dynamics", :ω_eb_b),
                       ω̇_eng = get_face("pwp.ω_dot"),
                       EAS = get_face("airflow.EAS"),
                       β   = get_face("airflow.β"),
                       γ   = get_face("kinematics.γ_wb_n")),
    residuals  = (r, d) -> (fx = r.v̇[1], …, eng = r.ω̇_eng,
                            eas = r.EAS - params.EAS,
                            beta = r.β - params.β,
                            gamma = r.γ - params.γ),
    tolerances = (fx = 1e-3, …, eas = 1e-2, beta = 1e-4, gamma = 1e-4))

trim!(sim, cruise; baseline)
```

## The two-path anatomy, and the mismatch walk

Under **elimination** the handle influences the residuals along two distinct
paths, and this is the structural fact that matters:

- **Path 1 (the world's).** `baseline` → environment root inputs → the sweep builds
  the handle → the airflow stage queries it at the vehicle pose → aerodynamic
  forces → ẋ → the residuals the solver reads.
- **Path 2 (the condition's).** `params.atm` → the condition math →
  a manufactured kinematic state written into the overlay.

Under **enlargement** path 2 does not exist. That asymmetry is the only thing
either axis of the 2×2 decides about doctrine, and it is worth seeing what it
costs when the two paths disagree.

Take a concrete mismatch. The baseline writes ISA sea-level conditions and a
10-knot headwind: `v_ew_n = −10 x̂` for an aircraft heading along `+x̂`. The
`params` handle, through a copy-paste or an edit that touched one line of a
script and not the other, carries **zero wind**. The target is EAS 50 knots
on heading `+x̂`.

Path 2 computes `TAS_param = EAS2TAS(50; ρ_param) ≈ 50`, builds a
wind-relative velocity of ≈50 knots along `+x̂`, and adds the wind it
believes in — zero — to get `v_eb_n ≈ 50 x̂`. So the *ground* speed of every
candidate the solver ever proposes is ≈50 knots. The decision variables steer
direction and attitude (α rotates the velocity vector in the body frame, φ
banks it, the controls trim it); **none of them touches the magnitude**,
because the magnitude was pinned by the EAS target and `ρ_param`.

Path 1 then measures what that state actually means in the world's
atmosphere: `v_wb = v_eb_n − v_ew_n = 50 x̂ − (−10 x̂) = 60 x̂`. The airflow
stage sees 60 knots, the aero tables are evaluated at 60 knots, the forces
are 60-knot forces.

And the solver **converges**. The residuals only demand that the derivatives
vanish; they say nothing about which operating point they vanish at. What you
get is a *true equilibrium* — genuinely trimmed, genuinely flyable — at EAS ≈
60, reported as "trimmed at 50". Nothing is inconsistent inside either path.
The falsehood lives entirely in the **bridge between them**: path 2's *claim*
about which wind-relative condition its overlay represents was computed
against a different atmosphere than the one path 1 measures.

Two things follow.

First, the consistency argument is a **script discipline**, and it is a
one-variable one: the same `atm` (or the same `T_sl`/`p_sl`/`wind` triple)
feeds the baseline and the params, as both elimination sketches above show.
That is thin protection compared to a structural guarantee, which is why the
second point matters.

Second, the whole class is caught by a **cheap post-commit read-back**: after
the commit, evaluate the sweep once and compare the achieved EAS, γ and β
against the requested targets. It costs one evaluation the service has
already paid for, needs no new mechanism, and it catches every variant of
this failure — mismatched wind, mismatched sea-level conditions, a params
record left over from a different flight condition. It is the trim
problem's `checks`, evaluated once at the committed state and reported
beside the committed-state residuals ([§14.7][s14-7], [§14.8][s14-8], [D-262][d-262]).

The corresponding statement for enlargement is the reason it is called
robust-by-construction: a handle there can at most inform the **initial
guess**, and a good `v_eb_n` guess is naturally computed by doing a rough
elimination in the script. But the guess is *solution-irrelevant*. A stale ρ
in a guess costs iterations. A stale ρ inside elimination's condition math
costs correctness, silently. Under enlargement, a wind mismatch does not lie —
it *moves a residual*, and the solver moves the state until the residual is
zero again.

## Trade-offs, and the verdict

**Elimination's case.** It is small — seven variables against seven
residuals, proven over years of use. It is well-conditioned: the eliminated
relations are exact, so the solver never has to discover analytically known
facts numerically. And its **bounds are natural**, which is the argument that
carried the most weight. The aerodynamic validity envelope of a table-driven
aero model is a *box* in (TAS, α, β): the C172's `α_a ∈ [−5°, 15°]` keeps
every table lookup in-domain and away from the stall model's pathologies.
Nothing about that envelope is a box in Cartesian `v_eb_n`. A box there is
either too loose — iterates wander into table extrapolation, which in
practice is the dominant source of failed trims, far more than dimension
count ever is — or it is tight enough to clip the feasible set for some
combination of heading and wind.

**Enlargement's case.** It is universal: it works for any aircraft, any
target set, any environment, with no closed-form work by the aircraft author.
It is single-path, so the mismatch class above cannot arise. And it is
honest under perturbation — change the wind and the trim moves rather than
lying. What it pays is exactly what elimination banks: guess and bounds
ergonomics, plus a longer residual vector of mixed units (accelerations,
angular accelerations, a speed, two angles). The mixed units are a
non-problem in practice — [§14.7][s14-7]'s per-residual physical tolerances are
per-equation numbers already, and [§9.6][s9-6] keeps per-residual scalings
aircraft-side where they belong. And with the `Dual` activation seeding exact
Jacobians ([§14.7][s14-7], [§14.8][s14-8]), a 10×10 nonlinear least-squares problem is
unremarkable: the extra three columns are three more seeded directions
through the same sweep.

**The verdict.** Elimination is the practical **default** — the migration
preserves today's 7×7 formulation verbatim as user math, which is what [§14.7][s14-7]
already promises. Enlargement is the **doctrinal reference and the fallback**:
it is what [§14.1][s14-1] now points at when closed-form enforcement is unwanted or
impossible, it is the answer for an aircraft whose author has no analytic
elimination to offer, and it is the shape to reach for when a trim is
misbehaving and the two-path structure is under suspicion. The choice is
per-problem and entirely user-level — the framework sees a `TrimProblem`
either way — and it is orthogonal to the (a)/(b) rig choice, which is why the
four sketches above are four and not two.

## The shape that was rejected

One alternative deserves recording because it is the first thing anyone
proposes: widen the condition seam to `condition(d, baseline)`, so the
condition math can read the handle straight out of the baseline it will be
applied over. It would genuinely single-source the handle — in rig shape (b),
where the handle *is* a baseline root-input value, the params field disappears
entirely.

It fails on two counts.

It is **rig-only**. In a full world of shape (a), the environment face is
*wired*, so the handle is not in the baseline at all — the baseline carries
the atmosphere's `T_sl`/`p_sl`/`wind` root inputs, not the handle those root inputs will
eventually produce. Serving the condition a handle there would mean
pre-sweeping the environment subtree, which is [§14.2][s14-2]'s rejected "init as a
third scheduled sweep" under a new name, and it would additionally require
the services to reason about which subtrees are state-independent and
therefore safe to pre-sweep — graph reasoning they deliberately do not do.

And it **reintroduces a hidden input one level up**. [§14.1][s14-1]'s overlay-base
decision — the base is always the declared defaults, never the stopped sim's
current stores — exists precisely to keep a condition's meaning independent
of history. A `condition(d, baseline)` seam makes every problem's meaning
depend on the baseline it happens to be applied against: the same
`TrimProblem` value, applied over two baselines, is two different problems.
That also breaks the pure condition algebra that lets [§14.9][s14-9]'s `at`-lifting be
five lines, because `p.condition` is no longer a function of `d` alone.

It is recorded as rejected in [D-139][d-139], alongside the pre-application sweep,
mandating enlargement as the sole route, reading the environment through
`reads`, and duplicating the atmosphere's output stage in aircraft trim code.
Worth stating once, to forestall the reading: none of this reopens [D-008][d-008]'s
rejected resource injection. There is no registry and no invisible
composition here — just a plain function call on values the caller already
holds.

## What landed in the spec

For the record, commit `daf3298d`, decision [D-139][d-139]:

- **[§4.4][s4-4]** gains the value-level constructor as a shipped component's
  obligation, with the taught-contract entry in [Appendix A][sA] and the glossary
  entry in [Appendix D][sD].
- **[§14.1][s14-1]**'s caller-computable escape is extended to cover environment
  queries, and the environment-free fallback (enlargement) is recorded as
  already covered by the second escape. The detailed elimination-vs-enlargement
  material stayed out of the spec deliberately — it is this document, and then
  `pending.md`.
- **[§14.7][s14-7]** and **[§14.9][s14-9]** state the portability rule: handles ride in the user
  parameter record, and a problem *receives* the environment and never writes
  it — which is what keeps one problem artifact valid across a full world and
  a thin rig.
- **[§14.9][s14-9]**'s "the aircraft is never literally the root" is softened from
  doctrine to default, admitting the unconnected environment face as the
  test-rig idiom while keeping `design_world(ac)` as the shipped rig for
  design tasks.
- **[§9.6][s9-6]**'s claim that `Kinematics.Initializer` "survives untouched,
  aircraft-side" is corrected: it survives aircraft-side with its
  `atmosphere::Model` argument respelled as a field handle.

Landed later: the post-commit read-back, as the trim problem's `checks`
([D-262][d-262]).


---

## Part II: the checks, and the problem posed from scratch

Part I ended with a deferral: the post-commit read-back was recorded as a
report-level nicety and left for `pending.md`. It has since landed as the
trim problem's `checks` ([§14.7][s14-7], [§14.8][s14-8], [D-262][d-262]).
Building it raised two questions Part I did not answer. How does an author
decide what a check should check? And, with the checks in hand, which
posing of the problem would one choose without a migration to preserve?
This part answers both, and along the way records a posing Part I's
spectrum did not contain.

### The checks, as the spec has them

A `TrimProblem` carries a second, optional equation set beside its residuals:
`checks`, a function of the gathered reads and the decisions returning a
NamedTuple of named equations, and `check_tolerances`, same-named with that
return. The service never solves the checks. After the commit it gathers
them once, from the boundary-zero sweep the committed-state residuals already
gather from, and reports them as `committed_checks`. A check outside its
tolerance raises `TrimCommitChecks`, a logged warning that rides the report.
Both fields default to empty. Setup observes the return's shape at the guess
evaluation, exactly as it observes the residuals', so a malformed check is
refused before any solve.

**Checks never affect the outcome of the solve.** They are not in the
residual vector and the solver never sees them. A correctly posed problem
passes every one of its checks without having done anything to earn it, and
a failed check changes nothing about the committed state; it is a warning
on the report. Checks are an insurance policy. They cost one gather from a
sweep the service has already run, and they pay out only when a belief the
problem holds about the world turns out to be wrong. An author can be
generous with them: a redundant check is free, and a missing one is the one
that would have caught the mismatch.

The reason the mechanism is user-supplied equations rather than a
service-side read-back of EAS, γ and β is that the service has no idea what
the targets are. Under elimination they live inside the condition closure,
as numbers the framework never sees. The problem has to state the requested
point in a form the service can evaluate, and the committed state is the
one place where a world measurement and a request meet on the same line.
The alternative of folding the targets into the residuals was rejected: it
makes the square problem overdetermined, and under a mismatch the
least-squares backend compromises between the equilibrium rows and the
target rows, so the answer is neither trimmed nor on target ([D-262][d-262]).

For the elimination problem of Part I, the check is the read-back Part I
asked for, spelled as one line:

```julia
    reads            = reads(…, EAS = get_face("airflow.EAS"), γ = get_face("kinematics.γ")),
    checks           = (r, d) -> (EAS = r.EAS - params.EAS, γ = r.γ - params.γ),
    check_tolerances = (EAS = 0.1, γ = 1e-3))
```

Walk the mismatch of Part I through it. The solve converges at 60 knots in
the world's air, reported as 50. The check reads the world's EAS at the
committed state, 60, subtracts the request, 50, and reports 10 against a
tolerance of 0.1. The equilibrium is real, the point is wrong, and the
report says so.

The same script could have read the atmosphere itself back instead, or as
well, and that would have named the cause rather than the symptom. Which
quantities a check should read is one question, asked while writing
`trim_condition`; the section on choosing checks below states it.

### Enlargement in the spherical chart

Part I placed two enlargement shapes on the spectrum: the full Cartesian
switch, which frees the earth-relative velocity components, and the 8×8
middle point, which frees the magnitude alone. There is a third, and it is
the one that keeps elimination's strongest asset.

Keep the aerodynamic spherical coordinates as decisions, free all three, and
enforce the targets as residuals:

```
d = (TAS, α, β, θ, φ, n_eng, throttle, aileron, elevator, rudder)      # 10
r = (fx, fy, fz, mx, my, mz, eng, eas, beta, gamma)                    # 10
```

Against Part I's ledger, every row reads as under Cartesian enlargement,
except that the velocity's three degrees of freedom are named by the chart
the aero tables use rather than by the frame the kinematics stores:

| DOF | elimination | spherical enlargement | paid by |
|---|---|---|---|
| ψ (heading) | analytic state write | analytic state write | — |
| φ (bank) | decision variable | decision variable | — |
| θ (pitch) | closed form from the γ target | decision variable | γ residual |
| velocity magnitude | pinned: `EAS2TAS(EAS; ρ)` | decision variable `TAS` | EAS residual |
| β (sideslip) | pinned by construction | decision variable `β` | β residual |
| α (incidence) | decision variable | decision variable `α` | — |

The condition builds the wind-relative velocity from the first three
decisions, rotates it with the attitude, adds the wind, and writes the
earth-relative state. No density query, because no EAS conversion happens
in the condition; `TAS` is a decision and EAS is measured by the sweep. No
`θ_constraint`, because θ is free and γ is a residual. The bounds sit on
`TAS`, `α` and `β` directly, which is the envelope box Part I's verdict
weighed most heavily.

The wind still enters the condition, for the chart change and nothing else.
What matters is what a mismatch does to it now. Suppose the params record
says zero wind and the world has a ten-knot headwind. The sweep measures ten
knots more airspeed than the condition assumed, the `eas` residual is off by
ten knots, and the solver lowers the `TAS` decision until the world's EAS
reads fifty. The solution is at the requested point, in the world's air. What
is wrong is the label: the decision named `TAS` holds forty, and the bound on
it was applied to that mislabeled value. The lie has shrunk from a wrong
answer to a slightly misplaced envelope box. And it is detectable exactly,
which the next section is about.

What elimination still buys over this shape is small. Seven unknowns against
ten, and the θ constraint solved in closed form rather than discovered
numerically. With exact Jacobians from the seeded sweep and a least-squares
backend, neither is measurable. What it costs is Part I's whole mismatch
class, the closed-form work every aircraft author has to reproduce, and
rigidity: level flight at an EAS, a climb at a rate, a turn at a bank angle
and a trim at fixed throttle with the airspeed free are four eliminations
under the first posing and four residual lines under this one.

### The script, with one source for the wind

The spherical enlargement needs one environment fact in the condition, the
wind. The script should state it once and derive both uses from that one
statement, rather than writing two literals that have to agree. Illustrative
spellings, as in Part I:

```julia
world = design_world(ac)
sim   = Simulation(world; h = 0.02)

# One record, the single source. The baseline is derived from it; the
# condition closes over one of its fields. No second wind literal exists.
env = (T_sl = 288.15, p_sl = 101325.0, wind = WindVector(-10.0, 0.0, 0.0),
       elevation = 0.0)

environment(env) = condition("atmosphere.T_sl" => env.T_sl,
                             "atmosphere.p_sl" => env.p_sl,
                             "atmosphere.wind" => env.wind,
                             "terrain.elevation" => env.elevation)

baseline = override(ready_for_taxi(ac), environment(env))
targets  = (EAS = 50.0, β = 0.0, γ = 0.0)
params   = (; Ob, ψ = 0.0, wind = env.wind)          # no handle, no density

function trim_condition(ac, params, d)
    q_nb   = attitude(params.ψ, d.θ, d.φ)
    v_wb_b = velocity_vector(d.TAS, d.α, d.β)        # wind-relative, body axes
    v_eb_n = params.wind + q_nb * v_wb_b             # the one environment use
    combine(at("vehicle/kinematics",
               fragment(x = (q_nb = q_nb, v_eb_n = v_eb_n, r_eb = params.Ob))),
            at("pwp/engine", fragment(x = (ω = d.n_eng,))),
            fragment(inputs = (throttle = d.throttle, aileron = d.aileron,
                               elevator = d.elevator, rudder = d.rudder)))
end

cruise = TrimProblem(
    guess      = spherical_guess(targets, env; α = 0.06),   # a rough elimination, guess only
    lower      = (TAS = 30.0, α = -0.09, β = -0.2, θ = -0.5, φ = -0.5, …),
    upper      = (TAS = 80.0, α =  0.26, β =  0.2, θ =  0.5, φ =  0.5, …),
    condition  = d -> trim_condition(ac, params, d),
    reads      = reads(v̇ = get_deriv("vehicle/dynamics", :v_eb_b),
                       ω̇ = get_deriv("vehicle/dynamics", :ω_eb_b),
                       ω̇_eng = get_face("pwp.ω_dot"),
                       EAS = get_face("airflow.EAS"), TAS = get_face("airflow.TAS"),
                       α = get_face("airflow.α"), β = get_face("airflow.β"),
                       γ = get_face("kinematics.γ"),
                       wind = get_face("atmosphere.wind")),
    residuals  = (r, d) -> (fx = r.v̇[1], fy = r.v̇[2], fz = r.v̇[3],
                            mx = r.ω̇[1], my = r.ω̇[2], mz = r.ω̇[3], eng = r.ω̇_eng,
                            eas = r.EAS - targets.EAS, beta = r.β - targets.β,
                            gamma = r.γ - targets.γ),
    tolerances = (fx = 1e-3, fy = 1e-3, fz = 1e-3, mx = 1e-4, my = 1e-4, mz = 1e-4,
                  eng = 1e-4, eas = 1e-2, beta = 1e-4, gamma = 1e-4),
    checks           = (r, d) -> (wind = norm(r.wind - params.wind),      # the cause
                                  TAS = r.TAS - d.TAS, α = r.α - d.α,     # its consequence
                                  β = r.β - d.β),
    check_tolerances = (wind = 1e-6, TAS = 1e-3, α = 1e-5, β = 1e-5))

report = trim!(sim, at("aircraft", cruise); baseline)
```

Two things make this safer than Part I's elimination script, even though
the wind is still stated once and used twice.

The first is `environment(env)`. Part I's redundancy was two literals that
had to agree. Here there is one literal, and the baseline entry is computed
from it. A copy-paste cannot desynchronize a value that exists once. It is
the same move [D-139][d-139] makes with the value-level constructor, applied one level
up, and it is the strongest discipline a script can have short of the
framework doing it, which Part I's rejected shape explains it cannot.

The second is the check set, and why it has four lines is the subject of
the next section.

### What a check should check

Every check in this part came from one question, asked while writing
`trim_condition`, of each quantity the model needs and the condition
touches: **where does the model get this from?** Does the condition being
written supply it, directly or indirectly, or does the model have its own,
independent source for it? The three answers sort every quantity, and only
the third calls for a check.

**The condition writes it directly.** The engine speed, θ, φ and the
controls, under every posing. The condition takes a decision and stores it
verbatim, and the model has no other source, so nothing can disagree. A
check here compares a number with itself and is always zero. (The first
draft of the increment's tests made exactly this mistake, with a check on
θ that passed at every point because the condition writes θ from the
decision.)

**The condition writes it indirectly.** The heading, through the attitude
quaternion. The velocity, through the chart change. The model derives the
quantity from what the condition wrote, so again nothing can disagree,
unless the derivation itself consumed something from the third class. The
heading did not: the quaternion is built from three angles the condition
owns. The velocity did: the chart change added the wind.

**The model has its own, independent source for it.** The wind, published
by the atmosphere component. The density, derived from the sea-level
conditions the baseline wrote. When the condition uses one of these, it is
using a copy of something the world owns, and the copy is a belief. Every
such input is a check candidate, and the check is the simplest possible
one: read the world's value back and compare it with the copy. These are
the primary checks, and they name the cause.

Two corollaries finish the rule. A quantity the condition wrote indirectly
earns a check of its own when its derivation consumed a third-class input,
because that is where a wrong belief surfaces as a wrong state. Such a
check compares the world's measurement with what the decisions describe,
and it catches anything that breaks the derivation, a bug in the
condition's own math included, whatever the cause. It is a consequence
check, and since checks are free the script carries both forms. And a
quantity the solver enforces as a residual needs no check at all; the
residual is the guarantee, and the report already carries the achieved
value beside its tolerance.

Applied to each posing, cause first:

- **Elimination.** The condition uses the density and the wind, both owned
  by the world. Read them back. The airspeed, β and θ were written
  indirectly through them, and the world measures EAS, β and γ, so the
  targets read back are the consequence checks.
- **Spherical enlargement with wind.** The condition uses the wind. Read
  it back. The velocity was written indirectly through it, and the world
  measures true airspeed, α and β from that velocity and its own wind, so
  swept minus decision on those three is the consequence check. They agree
  exactly when the winds agree.
- **Still air**, below. The condition uses nothing the world owns. What it
  holds instead is an assumption, that the wind is zero, and the check
  reads the world's wind to test it.

### Still air: the redundancy becomes a precondition

Fix the wind at zero and the chart change is `v_eb_n = q_nb * v_wb_b`. The
condition then touches no environment fact at all. There is no `params.wind`
to go stale because there is none, and the `environment(env)` discipline has
nothing left to protect. What remains is not a duplicated value but an
assumption: the problem is valid over baselines whose wind is zero. An
assumption about the world is exactly what a check expresses:

```julia
    reads            = reads(…, wind = get_face("atmosphere.wind")),
    checks           = (r, d) -> (still_air = norm(r.wind),),   # the problem assumes no wind
    check_tolerances = (still_air = 1e-6,))
```

Apply the problem over a windy baseline and the solve still converges to the
requested EAS in the world's air, because enlargement enforces the targets
on swept values. The decision labels are off by the wind, the `still_air`
check fails, and the report says why. Nothing lies and nothing is
duplicated.

The price is a restriction on what can be posed, and it is worth being
exact about it. A steady uniform wind does not change the aerodynamic
equilibrium: the attitude, controls, airspeed, α and β that trim the
aircraft in still air trim it in any steady wind. What changes is the
earth-relative side, the ground speed, the ground track and the
earth-relative flight path angle. So a still-air problem serves every task
that is about the aircraft, which is most of them: linearization, stability
derivatives, control design, envelope sweeps. It cannot pose a task about
the aircraft relative to the ground in wind, such as an approach at a given
earth-relative descent angle in a crosswind. For those the wind belongs in
the chart change, and the windy script above is the shape.

### The from-scratch verdict

Part I's verdict stands for what it was about. A migration that preserves
FlightCore's 7×7 formulation verbatim as user math is the right first move,
and elimination remains a legitimate posing with the checks as its backstop.

For an aircraft posed fresh in Cadence, this part reverses the default.
Pose the trim as enlargement in the spherical chart, and ship it as two
problems rather than one with a switch: a still-air problem with no
environment dependence anywhere and a one-line precondition check, and a
windy problem whose one dependence is stated once, derived into the
baseline, and detected by the checks when the discipline lapses. The
closed-form knowledge an aircraft author has is not wasted under either. It
moves from defining the solution to seeding it, as the rough elimination
that computes the guess, where a stale atmosphere costs iterations and
nothing else.

The framework is agnostic throughout. It sees a `TrimProblem` either way,
and nothing in the spec prefers one posing. What this part adds is a rule
for the checks and a posing that keeps elimination's bounds without its
two-path structure, so that the choice, which stays the author's, is made
with the whole spectrum in view.

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-008]: ../decisions.md#d-008--function-valued-environment-signals-with-the-handle-pattern
[d-139]: ../decisions.md#d-139--give-environment-field-handles-a-value-level-constructor-to-prevent-drift
[d-262]: ../decisions.md#d-262--post-commit-checks-on-the-trim-problem
[s14-1]: ../spec.md#141-conditions-are-path-addressed-overlays-on-the-declared-defaults
[s14-2]: ../spec.md#142-fragment-composition-locality-without-schema
[s14-7]: ../spec.md#147-the-trim-problem-namedtuple-decisions-declared-reads-named-residuals
[s14-8]: ../spec.md#148-the-trim-service-solver-seam-scratch-stores-commit-and-report
[s14-9]: ../spec.md#149-mounting-problems-as-relocatable-values
[s4-4]: ../spec.md#44-function-valued-signals-environment-access
[s5-3]: ../spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
[s9-6]: ../spec.md#96-stopped-sim-services-as-activation-clients
[sA]: ../spec.md#appendix-a-taught-contracts-the-author-facing-index
[sD]: ../spec.md#appendix-d-glossary
