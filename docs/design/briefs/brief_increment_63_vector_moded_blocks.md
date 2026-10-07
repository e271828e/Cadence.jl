# Brief: increment 63, the vector moded blocks, the `Int8` codes and the PID block

Three code stages, one cold review and a fixer if the review needs one. The
docs arc is landed: `pending.md`'s increment 63 bullet, the junction's
docstring on undeclared discontinuities (12eb8eb), and the companion
`docs/design/companions/pid_anti_windup.md` with the inventory's
`Controllers` rows (the commit "Promote the PID to a library block…"). The
tip at launch is the commit adding this brief; line numbers below are that
promotion commit's. Find passages in `docs/design/implementation.md` by
heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **The modes are signed `Int8` codes.** `LimitedIntegrator`'s `saturation`
  is `-1`, `0` or `+1` for lower, free and upper, so the code is the sign of
  the limit in force, and `Relay`'s `state` is `0` or `1` for off and on. The
  scalar blocks move from their `Symbol` labels to the same codes, so one
  encoding serves both shapes. This is a library choice, not a framework
  ruling, so it earns no log entry (user, 2026-10-07). D-231 still rules
  the store: `Symbol` is admitted as a bare label and nothing else, so a
  static vector of labels is refused, which is why the vector form needs the
  codes in the first place.
- **`LimitedIntegrator` publishes its code as a second output, `saturation`**,
  `Int8` or `SVector{N, Int8}`, from `y_state` beside `out`. It reads the mode
  alone, so it has no feedthrough. An integer leaf pins by itself (§7.2,
  D-079), so the type is declared plain, with no `Pinned` wrapper; a probe
  confirmed both spellings build under `(Float64, LinearizeDual)`, and the
  plain one is the honest one. The port is what the PID's `code` input
  reads.
- **The vector forms share the scalar struct.** The bound on `V` widens to
  `Union{Real, StaticArray{<:Tuple, <:Real}}` on both blocks, as `Integrator`
  spells it. The constructors are unchanged: `float.(promote(x0, lower,
  upper))` promotes static vectors as it promotes scalars (probed). Where a
  broadcast serves both shapes, one method serves both; where the shape
  differs, the methods dispatch on `V <: Real` and `V <: StaticArray`.
- **The vector events are per-component**, `4N` for the integrator and
  `2N` for the relay, generated from `N` by `ntuple` as closures capturing
  the component index, with names `hit_upper_1 … hit_upper_N`, then
  `hit_lower_i`, `leave_upper_i`, `leave_lower_i`, in the scalar order. Each
  guard reads its one component and each handler writes its one component
  through `setindex`. The scalar reasoning of
  `docs/design/companions/limited_integrator_variants.md` then transfers
  verbatim, which is why reductions were not chosen: a reduction hit guard
  holds forever once one component is clamped exactly on its limit, so a
  second arrival produces no edge, and masking it by the mode reintroduces
  the re-saturation the companion's section 1 explains. A probe of this
  shape builds nominal and under `Dual`, reports every policy, runs the
  trajectory below, and allocates nothing in the phase bodies or at a quiet
  boundary, at both policies.
- **`localized = true` stays the default** on every block carrying `L`
  (user, 2026-10-07): the accurate form by default, the cheap form the
  opt-in a paced deployment makes beside its base step.
- **The PID is a library block, `PID{Flag, Track}`**, promoted from the
  inventory's example-first row. The companion `pid_anti_windup.md` is the
  record and its section 7 the decision; this brief restates only what the
  keyboard needs. One law, `q̇ = Ki · gate(e) + (ref - u_raw) / Tt`, two
  independent `Bool` type parameters since each adds an input port: `Flag`
  adds `code::Int8` and makes `gate(e) = code == sign(e) ? 0 : e`; `Track`
  adds `v::Float64` as the correction's reference in place of the block's own
  clamped `u`, consulted only while the code is nonzero when both exist.
  `Ki` sits inside the integral, so `q` is the integral term in output units.
  The derivative acts on the measurement through a lag. Outputs `u`, clamped
  to the own limits, and `u_raw`. Defaults make the plain spelling a P
  controller: `Ki = Kd = 0`, `τd = 0.1`, `Tt = Inf`, infinite limits.
- **The tracking variant wired from a memoryless clamp of its own output is
  refused**, `AlgebraicCycle` classified `:artificial` with the dead hop
  `("controller", :v, :u)`: §5.4's stage-2 conservatism, and the reason the
  limits live inside the block. A test asserts the refusal with its
  payload, as the lesson it is. The cascade and the servo loop feed `v` from
  a state-published port, so the variant runs there.
- **The simplified assembly stays a test model**, the first variant as a
  `Group` of library blocks, the inspector's example beside the block. Not a
  library row.
- **One root input fans out as `"y" => ("err/in2", "lag/in", "der/in1")`**
  (§8.6); a repeated key is a `FaceNameCollision`.
- **Reads into a nested assembly.** `state(sim, "controller/int")` and
  `port(sim, "controller", :u)` read a nested `Group`'s children and faces;
  a `get_state("c/int", …)` tap inside `linearize` does not reach past a
  generically held child (§13.3). The controller is therefore linearized as
  the root, with its ports as root inputs.
- **Every number in stages 2 and 3 was probed at 99438ec** against the
  shapes below, at `h = 1//100`, sampling every `0.1` by `step!`. The
  companion's section 7 tabulates them. Confirm each in a probe before
  writing an assertion, and report the probe's numbers.

## Out of scope

- A mode port on `Relay`. Nothing asks for it.
- The PID variants the companion's section 6 lists as not carried:
  setpoint weighting, authority limits, a feedforward input, a general hold
  port, gain scheduling, the velocity form, internal clamping.
- Vector `Freeze`, and every other candidate row.
- Any spec or log edit. The companion note on the recode is the one
  companion edit beyond what the docs arc landed.

## Reading, in order

- `docs/design/pending.md`, the increment 63 bullet, lines 16 to 35.
- `docs/design/companions/pid_anti_windup.md` whole, then
  `docs/design/companions/limited_integrator_variants.md` whole, and
  `docs/design/companions/library_inventory.md` sections 2 and 3.
- `docs/design/spec.md` §2.1, lines 229 to 273; §5.3, lines 826 to 1037;
  §5.4, lines 1038 to 1107, above all its last paragraph; §7.2, lines 1625
  to 1694; §7.3, lines 1695 to 1843; §8.5, lines 2886 to 3087; §10.4, lines
  5182 to 5540; §10.6, lines 5877 to 6153; §13.7, lines 9726 to 9954. Never
  read the spec whole.
- `docs/design/decisions.md` D-179, D-231, D-312 and D-313.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/blocks.jl` and
  `### test/imports.jl`; "Authoring caveats", its first three bullets;
  "Naming"; "Running the suite". Never restate either in a commit or a
  comment.
- `src/blocks.jl` whole. `Step`, `LimitedIntegrator` and `Relay` are the
  blocks touched; `Junction`'s docstring now says where a fold stops being
  enough.
- `src/build.jl` lines 166 to 175, the store check, and lines 1211 to 1235,
  how a guard's policy is read off its probed return type; `src/declare.jl`
  lines 202 to 215 and 359 to 371, `StateEvent` and the guard bundle, which
  comes from the component's declarations and not from the guard's
  signature, so a closure is a guard like any function.
- `test/test_blocks.jl` whole: the models at top level, the testsets you
  recode, the allocation idiom, the shadow-check testset and the policies
  read through `limited_events`.
- `test/fixtures.jl` line 57, `Motor`'s derivative reading its own outputs
  through `y`, which the PID's does.
- `test/utils.jl` lines 1 to 30: `single` and `fed`.

## Stage 1: the codes, the port and the vector forms

### The shape

`LimitedIntegrator`, with the constructor unchanged:

```julia
struct LimitedIntegrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}, L} <: AbstractComponent
    x0::V
    lower::V
    upper::V
end
x_init(c::LimitedIntegrator) = (q = c.x0,)
m_init(c::LimitedIntegrator) = (saturation = Int8.(zero(c.x0)),)      # -1 lower, 0 free, +1 upper
u_types(::LimitedIntegrator{V}) where {V} = (in = V,)
y_types(::LimitedIntegrator{V}) where {V <: Real} = (out = V, saturation = Int8)
y_types(::LimitedIntegrator{V}) where {V <: StaticArray} = (out = V, saturation = similar_type(V, Int8))
y_state(::LimitedIntegrator, (; x, m)) = (out = x.q, saturation = m.saturation)
x_deriv(::LimitedIntegrator, (; u, m)) = (q = ifelse.(m.saturation .== 0, u.in, zero(u.in)),)
```

`similar_type` joins the `using StaticArrays:` line; `setindex` is
`Base.setindex`, which StaticArrays extends, so it needs no import. The
scalar events keep their named guards and handlers, recoded:
`hit_upper_handler` writes `Int8(1)`, `hit_lower_handler` `Int8(-1)`,
`leave_handler` `Int8(0)`, and the leave guards gate on `m.saturation == 1`
and `== -1`. Their site comments stay. The scalar `state_events` method
dispatches on `V <: Real`. The vector method generates its roster:

```julia
function state_events(::LimitedIntegrator{V, L}) where {V <: StaticArray, L}
    N = length(V)
    hit_upper = ntuple(N) do i
        StateEvent((c, (; x)) -> x.q[i] - c.upper[i],
                   (c, (; x, m)) -> (x = (q = setindex(x.q, c.upper[i], i),),
                                     m = (saturation = setindex(m.saturation, Int8(1), i),)))
    end
    hit_lower = ntuple(N) do i
        StateEvent((c, (; x)) -> c.lower[i] - x.q[i],
                   (c, (; x, m)) -> (x = (q = setindex(x.q, c.lower[i], i),),
                                     m = (saturation = setindex(m.saturation, Int8(-1), i),)))
    end
    leave_upper = ntuple(N) do i
        guard = L ? ((c, (; m, u)) -> m.saturation[i] == 1 && u.in[i] < 0 ? -u.in[i] : -one(u.in[i])) :
                    ((c, (; m, u)) -> m.saturation[i] == 1 && u.in[i] < 0)
        StateEvent(guard, (c, (; m)) -> (m = (saturation = setindex(m.saturation, Int8(0), i),),))
    end
    leave_lower = ntuple(N) do i
        guard = L ? ((c, (; m, u)) -> m.saturation[i] == -1 && u.in[i] > 0 ? u.in[i] : -one(u.in[i])) :
                    ((c, (; m, u)) -> m.saturation[i] == -1 && u.in[i] > 0)
        StateEvent(guard, (c, (; m)) -> (m = (saturation = setindex(m.saturation, Int8(0), i),),))
    end
    names = (ntuple(i -> Symbol(:hit_upper_, i), N)..., ntuple(i -> Symbol(:hit_lower_, i), N)...,
             ntuple(i -> Symbol(:leave_upper_, i), N)..., ntuple(i -> Symbol(:leave_lower_, i), N)...)
    NamedTuple{names}((hit_upper..., hit_lower..., leave_upper..., leave_lower...))
end
```

The method's own parameter is unnamed so that `c` has one meaning in the
body. A site comment says why the events are per component and not
reductions, in two sentences from "What is settled". The docstring gains
the vector form (componentwise limits and codes, `N` copies of the scalar
block's events), the `saturation` port and what it serves, and the sign
convention of the codes; its policy paragraph is unchanged.

`Relay`, with the constructor unchanged:

```julia
struct Relay{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    lower::V; upper::V; off::V; on::V      # the four comments stay
end
m_init(c::Relay) = (state = Int8.(zero(c.lower)),)        # 0 off, 1 on
y_state(c::Relay, (; m)) = (out = ifelse.(m.state .== 1, c.on, c.off),)
```

The scalar guards gate on `m.state == 0` and `== 1`; the handlers write
`Int8(1)` and `Int8(0)`. The vector `state_events` generates `switch_on_1 …
switch_on_N` then `switch_off_i`, each guard the scalar's gated sign form on
component `i`, each handler a `setindex` of its code. The docstring gains
the vector form and the codes.

### Tests

In `test/test_blocks.jl`, each red under the mutants the review runs.

- **The recode.** Every `Symbol` assertion on `saturation` and `state`
  reads the code instead: twelve lines, in the limited-integrator testsets,
  the exact-zero testset's tuple, the relay testset and the servo loop.
  `y_types(LimitedIntegrator(lower = -1.0, upper = 0.5)) == (out = Float64,
  saturation = Int8)`, and in the first limited-integrator testset
  `port(sim, "li", :saturation) === modes(sim, "li").saturation` at each
  sampled instant.
- **The vector limited integrator.** A top-level
  `vector_limited_model(localized)`: `Step(t_step = 1.05, before =
  SVector(1.0, 2.0), after = SVector(-1.0, 0.0))` into
  `LimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(0.5, 0.8),
  localized = localized)`, at `h = 1//10`, for both policies, since the
  step's jump carries its own boundary. Component 2 hits `0.8` at `t = 0.4`,
  component 1 hits `0.5` at `0.5`; after `1.05` component 1 leaves and
  reaches `-1` at `2.55`, while component 2's input is exactly zero, so it
  stays saturated, the corner of the companion's section 2 in vector form.
  At `t = 0.45`: `q == SVector(0.45, 0.8)` within `1e-12` on the free
  component and exactly on the clamped one, `saturation ==
  SVector{2, Int8}(0, 1)`, and the port equals the mode. At `0.7`:
  `q == SVector(0.5, 0.8)`, codes `(1, 1)`. At `2.0`: `q ≈ SVector(-0.45,
  0.8)` within the bracket width, codes `(0, 1)`. At `3.0`: `q ==
  SVector(-1.0, 0.8)`, codes `(-1, 1)`. The `0.45` sample is what separates a
  handler that clamps its one component from one that clamps all; the zero
  input on component 2 is what separates a leave guard reading `u.in[i]`
  from one reading `u.in[1]`.
- **The policies product** of `vector_limited_model` names the eight events
  in the order above, every one `:localized` at the default, and the four
  leave events `:boundary` at `localized = false`.
- **The mode-dependent Jacobian, componentwise.** A rig
  `fed(LimitedIntegrator(lower = SVector(-1.0, -1.0), upper = SVector(0.5,
  0.8)), "in")` at `h = 1//10`, `init!` with `in = SVector(1.0, 0.0)`,
  stepped to `0.7`: component 1 saturated, component 2 free. Linearized
  through `taps(x = (q = get_state("c", :q),), u = (in = get_input(:in),))`,
  `B` is `diagm([0.0, 1.0])` within `1e-12`. Confirm in a probe that a
  vector tap yields the 2×2 matrix; if the tap is scalar-only, report and
  drop this bullet rather than work around it.
- **Builds and constructors.** `vector_limited_model(true)` builds under
  `(Float64, LinearizeDual)`. `LimitedIntegrator(lower = SVector(-1, -1),
  upper = SVector(1, 1))` isa `LimitedIntegrator{SVector{2, Float64}, true}`,
  in the integer-keyword testset.
- **The vector relay.** A top-level `vector_relay_model()`:
  `Step(t_step = 1.0, before = SVector(1.0, 0.5), after = SVector(-1.0, -0.5))`
  into `Integrator(x0 = SVector(0.0, 0.0))` into `Relay(lower = SVector(0.2,
  0.2), upper = SVector(0.8, 0.8))`, at `h = 1//10`. Component 1 is the
  scalar relay test; component 2 climbs to `0.5` and never reaches `0.8`.
  At `t = 0.5`: `out == SVector(0.0, 0.0)`, `state == SVector{2, Int8}(0, 0)`;
  at `0.9`: `(1.0, 0.0)`, `(1, 0)`; at `1.5`: the same; at `1.9`: `(0.0,
  0.0)`, `(0, 0)`. A relay fed `Constant(SVector(1.0, 0.5))` reads `(1, 0)`
  right after `init!`. `y_types` of a vector relay is `(out = Pinned{SVector{2,
  Float64}},)`.
- **Allocation.** `vector_limited_model` at both policies and
  `vector_relay_model` join the loops' allocation testset: phase bodies and
  a quiet boundary allocate nothing.
- **The shadow check** gains a vector `LimitedIntegrator` at each policy and
  a vector `Relay`.

### Routing

`src/blocks.jl` is the `blocks` row; the change touches guards, policies
and a new output port, so run `blocks build events localization linearize`
under the flags of "Running the suite", in the foreground, 600 s per
invocation.

### Bookkeeping, in the same commit

- `docs/design/implementation.md` `### src/blocks.jl`: the D-313 bullet says
  `LimitedIntegrator` and `Relay` are over `Real` and static vectors with
  `Int8` modes, the vector events generated per component, and that
  `LimitedIntegrator` publishes `saturation`. Constructs, not behaviour.
- `docs/design/companions/library_inventory.md`: the two vector-form rows
  fold into their scalar rows, which read `LimitedIntegrator{V, L}` and
  `Relay{V}` over `Real` or a `StaticArray`, *shipped*, their mechanism
  cells adding "modes as `Int8` codes, `4N` (`2N`) per-component events over
  a vector" and, for the integrator, "`saturation` published". Linkified
  spelling; run the battery, `linkify` a no-op on rerun.
- `docs/design/companions/limited_integrator_variants.md`, end of section
  6, one sentence: on 2026-10-07 the modes were recoded from `Symbol` labels
  to the signed `Int8` codes `-1`, `0`, `+1`, so the vector form could share
  them under D-231's rule, and the sketches above keep the labels.

## Stage 2: the PID block

### The shape

In `src/blocks.jl`, a new section `# --- the controller (§13.7, §5.4,
D-313)` after the moded blocks:

```julia
struct PID{Flag, Track} <: AbstractComponent
    Kp::Float64
    Ki::Float64
    Kd::Float64
    τd::Float64       # the derivative filter's time constant, positive
    Tt::Float64       # the tracking time; `Inf` switches the correction off
    u_min::Float64    # the own limits; infinite by default
    u_max::Float64
end
PID(; Kp, Ki = 0.0, Kd = 0.0, τd = 0.1, Tt = Inf, u_min = -Inf, u_max = Inf,
      flag = false, tracking = false) =
    PID{flag, tracking}(Kp, Ki, Kd, τd, Tt, u_min, u_max)

x_init(::PID) = (q = 0.0, yf = 0.0)
u_types(::PID{false, false}) = (r = Float64, y = Float64)
u_types(::PID{true, false})  = (r = Float64, y = Float64, code = Int8)
u_types(::PID{false, true})  = (r = Float64, y = Float64, v = Float64)
u_types(::PID{true, true})   = (r = Float64, y = Float64, code = Int8, v = Float64)
y_types(::PID) = (u = Float64, u_raw = Float64)
function y_direct(c::PID, (; x, u))
    u_raw = c.Kp * (u.r - u.y) + x.q - c.Kd * (u.y - x.yf) / c.τd
    (u = clamp(u_raw, c.u_min, c.u_max), u_raw = u_raw)
end
gated_error(::PID{false}, e, u) = e
gated_error(::PID{true}, e, u) = u.code == sign(e) ? zero(e) : e
correction_reference(::PID{Flag, false}, u, y) where {Flag} = y.u
correction_reference(::PID{false, true}, u, y) = u.v
correction_reference(::PID{true, true}, u, y) = u.code == 0 ? y.u : u.v
x_deriv(c::PID, (; x, u, y)) =
    (q  = c.Ki * gated_error(c, u.r - u.y, u) + (correction_reference(c, u, y) - y.u_raw) / c.Tt,
     yf = (u.y - x.yf) / c.τd)
```

`y_direct` joins the import list. The keyword spellings are `flag` and
`tracking`; the type parameters `Flag` and `Track`. The docstring, in the
register of the shipped blocks: the law in one line, the four-cell table of
the companion's section 4, the ports each parameter adds, the fallback rule
when both exist, the grouping (`q` is the integral term in output units,
so a change in `Ki` alters only future accumulation), the derivative on the
measurement, the defaults that make the plain spelling a P controller, the
refusal a tracking input wired from a memoryless clamp of the own output
meets and why (§5.4), and the pointer to `pid_anti_windup.md` by file name
for the reasoning. Two site comments: on `gated_error`, why the gate tests
the sign and not `code != 0` (integration resumes when the error reverses
while the path still reports saturation); on `correction_reference`, why
`v` is consulted only while the code is nonzero.

### Tests

New testsets in `test/test_blocks.jl`, after the relay's and before the
loops'.

- **Ports and constructors.** `u_types` of the four spellings is the four
  tuples above, and `y_types(PID(Kp = 1.0)) == (u = Float64, u_raw =
  Float64)`. `PID(Kp = 1) isa PID{false, false}` with `Float64` fields, in
  the integer-keyword testset; `PID(Kp = 1.0, flag = true, tracking = true)
  isa PID{true, true}`.
- **The law, by direct call.** With `c = PID(Kp = 1.0, Ki = 0.5, Kd = 0.2,
  τd = 0.1, Tt = 1.0, u_min = -1.0, u_max = 1.0)` in each spelling,
  `x = (q = 0.3, yf = 0.1)` and `r = 3.0`, `y = 0.5`: `y_direct` gives
  `u_raw == 2.0` (`2.5 + 0.3 - 0.8`) and `u == 1.0`. Then `x_deriv` at that
  `x`, `u` and `y = (u = 1.0, u_raw = 2.0)`, with `yf' == 4.0` throughout:
  plain, `q̇ == 0.25` (`1.25 - 1`); flag, `q̇ == -1.0` at `code = 1`
  (the gate holds), `0.25` at `code = -1` and at `code = 0`; tracking,
  `q̇ == -0.05` at `v = 0.7` (`1.25 - 1.3`); both, `q̇ == -1.3` at `code = 1,
  v = 0.7` and `0.25` at `code = 0, v = 0.7`, the fallback to `u`. These
  equalities are exact in binary arithmetic; if one is not, assert within
  `1e-12`.
- **The four linearizations.** Each spelling as the root of a `Group` with
  its ports as root inputs and `u`, `u_raw` as faces, at the gains above,
  `init!` with every real input `0.0` and `code = Int8(0)`; `linearize` with
  `x = (q, yf)`, the real inputs and `y = (u = get_face(:u),)`. Plain and
  flag: `A = [0.0 0.0; 0.0 -10.0]`, `B = [0.5 -0.5; 0.0 10.0]`, `C = [1.0
  2.0]`, `D = [1.0 -3.0]`. Tracking: `A = [-1.0 -2.0; 0.0 -10.0]`, `B = [-0.5
  2.5 1.0; 0.0 10.0 0.0]`, `C = [1.0 2.0]`, `D = [1.0 -3.0 0.0]`. Both: the
  plain matrices with a zero column for `v`. All within `1e-12`, and every
  spelling builds under `(Float64, LinearizeDual)`.
- **The refusal.** `failure(() -> build(model))` where `model` wires
  `PID(Kp = 1.0, Ki = 0.5, Kd = 0.2, Tt = 1.0, tracking = true)` as
  `controller` with `controller/u` into a `Junction{Float64, Float64, 1}(v ->
  clamp(v, -1.0, 1.0))` named `sat`, `sat/out` into `controller/v` and into
  an `Integrator` plant, the plant into `controller/y`, a `Step` into
  `controller/r`: a `DiagnosticError` whose one diagnostic is an
  `AlgebraicCycle` with `classification === :artificial`, `dead ==
  [("controller", :v, :u)]` and `wires == ["controller/u" => "sat/in1",
  "sat/out" => "controller/v"]`. The testset's name cites §5.4.
- **The shadow check** gains the four spellings.

### Routing

`blocks build events linearize` under the flags of "Running the suite", in
the foreground.

### Bookkeeping, in the same commit

- `test/imports.jl`: `PID` joins the `import Redstone.Blocks:` line.
- `docs/design/implementation.md` `### src/blocks.jl`: a bullet naming
  `PID{Flag, Track}` with `gated_error` and `correction_reference`, and §5.4
  joins the Spec line. Battery.

## Stage 3: the loops and the example assembly

### The shape

Top-level functions in `test/test_blocks.jl` beside the existing loops. The
assembly is the first variant as a `Group`, the inspector's example:

```julia
# The PID's first variant as library blocks, the inspector's example beside
# the block: the integrator is what splits the stages (§5.4).
pid_assembly(; Kp, Ki, Kd, τd, Tt, u_min, u_max) = Group((
        err = Junction{Float64, Float64, 2}((r, y) -> r - y),
        lag = FirstOrderLag(; τ = τd),
        der = Junction{Float64, Float64, 2}((y, yf) -> (y - yf) / τd),
        int = Integrator(),
        raw = Junction{Float64, Float64, 3}((e, q, d) -> Kp * e + q - Kd * d),
        sat = Junction{Float64, Float64, 1}(v -> clamp(v, u_min, u_max)),
        aw  = Junction{Float64, Float64, 3}((e, u, u_raw) -> Ki * e + (u - u_raw) / Tt));
      input_wires  = ("r" => "err/in1", "y" => ("err/in2", "lag/in", "der/in1")),
      local_wires  = ("lag/out" => "der/in2",
                      "err/out" => "raw/in1", "int/out" => "raw/in2", "der/out" => "raw/in3",
                      "raw/out" => "sat/in1",
                      "err/out" => "aw/in1", "sat/out" => "aw/in2", "raw/out" => "aw/in3",
                      "aw/out" => "int/in"),
      output_wires = ("sat/out" => "u", "raw/out" => "u_raw"))

# A single loop on the own limits: the controller drives an integrator plant.
pid_single_loop(controller) = Group((
        reference = Step(t_step = 0.5, after = 5.0), controller = controller, plant = Integrator());
      local_wires = ("reference/out" => "controller/r", "plant/out" => "controller/y",
                     "controller/u" => "plant/in"),
      output_wires = ("plant/out" => "y",))

# A servo loop: a first-order position servo limited at ±1 between the
# controller and the plant, whose position the controller tracks.
pid_servo_loop(controller) = Group((
        reference = Step(t_step = 0.5, after = 5.0), controller = controller,
        servo_error = Junction{Float64, Float64, 2}(-),
        servo = LimitedIntegrator(lower = -1.0, upper = 1.0), plant = Integrator());
      local_wires = ("reference/out" => "controller/r", "plant/out" => "controller/y",
                     "controller/u" => "servo_error/in1", "servo/out" => "servo_error/in2",
                     "servo_error/out" => "servo/in", "servo/out" => "controller/v",
                     "servo/out" => "plant/in"),
      output_wires = ("plant/out" => "y",))

# A cascade: the controller sets a velocity servo's reference and reads the
# position that integrates the velocity; `code` wires the inner block's
# saturation into the controller, `tracking` the velocity into `v`.
function pid_cascade(controller; code = false, tracking = false)
    wires = Pair{String, String}[
        "reference/out" => "controller/r", "position/out" => "controller/y",
        "controller/u" => "error/in1", "velocity/out" => "error/in2",
        "error/out" => "inner/in", "inner/out" => "actuator/in",
        "actuator/out" => "velocity/in", "velocity/out" => "position/in"]
    code && push!(wires, "inner/saturation" => "controller/code")
    tracking && push!(wires, "velocity/out" => "controller/v")
    Group((reference = Step(t_step = 0.5, after = 5.0), controller = controller,
           error = Junction{Float64, Float64, 2}(-), inner = LimitedIntegrator(lower = -1.2, upper = 1.2),
           actuator = FirstOrderLag(τ = 0.1), velocity = FirstOrderLag(τ = 1.0), position = Integrator());
          local_wires = Tuple(wires), output_wires = ("position/out" => "y",))
end
```

A sampling helper at top level, if the testsets want one, follows "Naming".

### Tests

The gains are `Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1` in the single and
servo loops and `Kp = 0.5, Ki = 0.1` in the cascades; `h = 1//100`; the
peak is of the loop's output over samples every `0.1`; "settles" means
within the stated tolerance of `5.0` at the end.

- **The single loop on the own limits.** `PID(…, u_min = -1.0, u_max =
  1.0, Tt)` to `t = 40`: the peak is `8.184` at `Tt = Inf` and `5.327` at
  `Tt = 1.0`, assert `> 8.0` and `< 5.5`; both settle within `1e-4`; the
  peak of `abs(state(sim, "controller").q)` is `6.25` against `0.665`,
  assert the ordering, the windup itself.
- **The assembly is the block.** `pid_single_loop(pid_assembly(…))` at
  `Tt = 1.0` and the same limits matches `pid_single_loop(PID(…))` sample
  by sample within `1e-9` on `plant/out`, and the two linearize alike as
  roots (the assembly's `x` taps are `get_state("int", :q)` and
  `get_state("lag", :q)`), to the plain matrices of stage 2 within `1e-12`.
  Confirm the `1e-9` in a probe; the two compute one law in a different
  association order.
- **The servo loop, tracking a stateful actuator.** `PID(…, tracking =
  true, Tt)` to `t = 40`: the peak is `8.707` at `Tt = Inf` and `5.958` at
  `Tt = 1.0`, assert `> 8.5` and `< 6.5`; both settle within `1e-2`. The
  loop builds, which is the positive half of stage 2's refusal: `v` from the
  servo's state closes no cycle.
- **The cascade, six ways, to `t = 60`.** Plain `PID(…)`: peak `8.33`.
  `flag = true` with `code = true`: `6.103`. `tracking = true` with
  `tracking = true` in the loop: `6.135` at `Tt = 2.0`, `7.273` at `Tt =
  0.5`. Both parameters with both wires: `5.202` at `Tt = 2.0`, `5.088` at
  `Tt = 0.5`. Assert: the flag's peak is below the plain peak by more than
  `2.0`; the gated-tracking peaks are below the flag's; shortening `Tt`
  raises the ungated-tracking peak by more than `1.0` and lowers the
  gated one; every run settles within `3e-2`. The testset's name says what
  this measures, the companion's section 3: ungated tracking couples the
  loops, and the gate removes the coupling.
- **Allocation.** The single loop with the block and with the assembly, the
  servo loop, and the cascade with both parameters join the loops'
  allocation testset. The folds capture `Float64` gains, so they are
  isbits; if a closure allocates, report rather than hoist the gains.

### Routing

`blocks build events linearize`, as stage 2. No new `AbstractComponent`
type is declared: `pid_assembly` returns a `Group`.

### Bookkeeping, in the same commit

- `docs/design/companions/library_inventory.md`: the `PID{Flag, Track}` row
  flips to *shipped*, its mechanism cell kept; the gain-scheduled row stays
  a candidate; the paragraph under the table stands. Battery.
- `docs/design/pending.md`: the increment 63 sub-bullet is deleted; the
  tranche bullet then opens with increment 64. Battery.

## The cold review

One fresh Opus reviewer over the three code commits: open-mind stance,
probe scripts under `/tmp`, "empty is acceptable". Dimensions:

- **Each block against its sketch here and the companions**, the event
  order and names, the codes' sign convention, the `saturation` port's type
  and stage, the policies the events product reports for the vector form,
  and the PID's law against the companion's section 4 table, cell by cell.
- **The submodule's imports.** `src/blocks.jl` reaches the parent through
  its import list alone; `similar_type` is the one StaticArrays name added.
- **Mutants on a scratch copy**, each named test going red: the vector hit
  handler clamping every component (the `0.45` sample); a vector leave
  guard reading `u.in[1]` for every `i` (the exact-zero component); the
  `saturation` port published as a constant `0`; the vector relay's
  `ifelse` arms swapped; the PID's gate written `code != 0` (the direct
  call at `code = -1`); the fallback dropped so `v` is read at `code = 0`
  (the direct call at `code = 0, v = 0.7`); `Ki` moved outside the
  integral (the `B` matrix); the clamp dropped from `y_direct` (the direct
  call's `u`); the assembly's `aw` fold dropping `Tt` (the single-loop
  agreement). A surviving mutant is a missing test.
- **The numbers.** Re-probe the vector trajectory, the four matrices, the
  direct-call values, the peaks and the settling values against the
  companion's section 7 table, and the companion's claims the recode
  touches.
- **`Dual`.** Every new model builds under `(Float64, LinearizeDual)`, and
  the linearizations assert the matrices, so a `Float64` pin anywhere on
  the continuous path is a red test. The gate compares an `Int8` with
  `sign` of a `Dual` under the activation; the build proves it compiles.
- **The example as an example.** The assembly and the loops read as a user
  would write them; the refusal test reads as the lesson it is; the nested
  reads use the spellings "What is settled" names.
- **The register, the inventory and the companions.**
  `implementation.md`'s rows name constructs; behaviour is in docstrings;
  the PID's docstring and `pid_anti_windup.md` agree.
- "Naming" over every touched file, the docs battery, and the gate once on
  the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new name across `test/`
before defining it. Models and helpers live at top level. Report: the
commit hash, the files touched, the routed subset's result with the
assertion count, the probe's numbers for every asserted value, and every
deviation from this brief with its reason.
