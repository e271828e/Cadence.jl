# Brief: increment 63, the vector moded blocks, the `Int8` codes and the PID example

Two code stages, one cold review and a fixer if the review needs one. The
docs arc is landed: `pending.md`'s increment 63 bullet (commits 2f06908,
3b682e0 and 99438ec) and the junction's docstring on undeclared
discontinuities (12eb8eb). The tip at launch is the commit adding this brief;
line numbers below are 99438ec's. Find passages in
`docs/design/implementation.md` by heading.

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
  plain one is the honest one. The port serves anti-windup consumers: a
  controller integrates unless `code == sign(e)`, and several codes
  consolidate through the `Bool` gates.
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
- **The PID example ships in two forms with one controller law**:
  back-calculation against a tracking input `v`, `q̇ = e + (v - u_raw) / Tt`,
  derivative on the measurement through a lag, `d = (y - yf) / τd` with
  `ẏf = (y - yf) / τd`, and `u_raw = Kp e + Ki q - Kd d`. The assembly
  `pid_assembly` is library blocks in a `Group`; the leaf `PIDLeaf` is one
  component with states `q` and `yf`. Both are test material, the
  inventory's row stays *example first*, and the two are shown side by side.
- **The leaf cannot close the single loop, and that is the lesson.** With
  `v` wired from a clamp of the leaf's own `u`, the build refuses an
  `AlgebraicCycle` classified `:artificial`, with the dead hop
  `("controller", :v, :u)`: the leaf consumes `v` only in `x_deriv`, yet it
  has a stage-2 output, which is the stage-2 conservatism §5.4's last
  paragraph records. The assembly's integrator splits the stages by
  construction, which is §5.4's second remedy taken for free. The cascade
  feeds `v` from a lag's state, so both forms run there and agree to the
  digit (probed). The single loop runs the assembly, and a test asserts the
  leaf's refusal with its payload.
- **One root input fans out as `"y" => ("err/in2", "lag/in", "der/in1")`**
  (§8.6); a repeated key is a `FaceNameCollision`.
- **Reads into a nested assembly.** `state(sim, "controller/int")` and
  `port(sim, "controller", :u)` read a nested `Group`'s children and faces;
  a `get_state("c/int", …)` tap inside `linearize` does not reach past a
  generically held child (§13.3). The controller is therefore linearized as
  the root, with `r`, `y` and `v` as its root inputs.

## Out of scope

- A mode port on `Relay`. Nothing asks for it.
- Promoting the PID to a block, or any block beyond the two vector forms.
- Vector `Freeze`, and every other candidate row.
- Any spec or log edit. The one companion edit is the note in the
  bookkeeping below.

## Reading, in order

- `docs/design/pending.md`, the increment 63 bullet, lines 16 to 34.
- `docs/design/companions/limited_integrator_variants.md` whole, and
  `docs/design/companions/library_inventory.md` sections 2 and 3.
- `docs/design/spec.md` §2.1, lines 229 to 273; §5.3, lines 826 to 1037;
  §5.4, lines 1038 to 1107, above all its last paragraph; §7.2, lines 1625
  to 1694; §7.3, lines 1695 to 1843; §8.5, lines 2886 to 3087; §10.4, lines
  5182 to 5540; §10.6, lines 5877 to 6153; §13.7, lines 9726 to 9954. Never
  read the spec whole.
- `docs/design/decisions.md` D-179, D-231, D-312 and D-313.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/blocks.jl`,
  `### test/fixtures.jl` and `### test/imports.jl`; "Authoring caveats",
  its first three bullets; "Naming"; "Running the suite". Never restate
  either in a commit or a comment.
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
- `test/test_build.jl` lines 1750 to 1823: the `Dual` sweep and the pinned
  count of argument-taking fixtures, which stage 2 raises.
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

## Stage 2: the PID example

### The shape

The leaf, at top level in `test/fixtures.jl`, after grepping `PIDLeaf`
across `test/` (no hit at launch):

```julia
# The PID of §13.7's library example as one leaf, beside `pid_assembly` in
# test_blocks.jl: back-calculation against the tracking input `v`, the
# derivative on the measurement through a lag.
struct PIDLeaf <: AbstractComponent
    Kp::Float64
    Ki::Float64
    Kd::Float64
    τd::Float64     # the derivative filter's time constant
    Tt::Float64     # the tracking time; `Inf` switches the correction off
end
PIDLeaf(; Kp, Ki = 0.0, Kd = 0.0, τd = 0.1, Tt = Inf) = PIDLeaf(Kp, Ki, Kd, τd, Tt)
x_init(::PIDLeaf) = (q = 0.0, yf = 0.0)
u_types(::PIDLeaf) = (r = Float64, y = Float64, v = Float64)
y_types(::PIDLeaf) = (u = Float64,)
y_direct(c::PIDLeaf, (; x, u)) =
    (u = c.Kp * (u.r - u.y) + c.Ki * x.q - c.Kd * (u.y - x.yf) / c.τd,)
x_deriv(c::PIDLeaf, (; x, u, y)) =
    (q = (u.r - u.y) + (u.v - y.u) / c.Tt, yf = (u.y - x.yf) / c.τd)
```

The assembly and the two loops, top-level functions in
`test/test_blocks.jl` beside the existing loops:

```julia
# The same PID as library blocks: the states are `int` and `lag`, and the
# integrator is what splits the stages (§5.4).
pid_assembly(; Kp, Ki, Kd, τd, Tt) = Group((
        err = Junction{Float64, Float64, 2}((r, y) -> r - y),
        lag = FirstOrderLag(; τ = τd),
        der = Junction{Float64, Float64, 2}((y, yf) -> (y - yf) / τd),
        int = Integrator(),
        raw = Junction{Float64, Float64, 3}((e, i, d) -> Kp * e + Ki * i - Kd * d),
        aw  = Junction{Float64, Float64, 3}((e, v, u_raw) -> e + (v - u_raw) / Tt));
      input_wires  = ("r" => "err/in1", "y" => ("err/in2", "lag/in", "der/in1"), "v" => "aw/in2"),
      local_wires  = ("lag/out" => "der/in2",
                      "err/out" => "raw/in1", "int/out" => "raw/in2", "der/out" => "raw/in3",
                      "err/out" => "aw/in1", "raw/out" => "aw/in3", "aw/out" => "int/in"),
      output_wires = ("raw/out" => "u",))

# A single loop: the controller drives an integrator plant through a clamp,
# and tracks the clamp's output.
pid_single_loop(controller) = Group((
        reference = Step(t_step = 0.5, after = 5.0),
        controller = controller,
        sat = Junction{Float64, Float64, 1}(v -> clamp(v, -1.0, 1.0)),
        plant = Integrator());
      local_wires = ("reference/out" => "controller/r", "plant/out" => "controller/y",
                     "sat/out" => "controller/v", "controller/u" => "sat/in1",
                     "sat/out" => "plant/in"),
      output_wires = ("plant/out" => "y",))

# A cascade: the controller sets the reference of a velocity servo, reads the
# position that integrates its velocity, and tracks the velocity itself.
pid_cascade(controller) = Group((
        reference = Step(t_step = 0.5, after = 5.0),
        controller = controller,
        error = Junction{Float64, Float64, 2}(-),
        inner = LimitedIntegrator(lower = -1.2, upper = 1.2),
        actuator = FirstOrderLag(τ = 0.1), velocity = FirstOrderLag(τ = 1.0),
        position = Integrator());
      local_wires = ("reference/out" => "controller/r", "position/out" => "controller/y",
                     "velocity/out" => "controller/v",
                     "controller/u" => "error/in1", "velocity/out" => "error/in2",
                     "error/out" => "inner/in", "inner/out" => "actuator/in",
                     "actuator/out" => "velocity/in", "velocity/out" => "position/in"),
      output_wires = ("position/out" => "y",))
```

Every number below was probed at 99438ec against this exact shape, at
`h = 1//100`, sampling every `0.1` by `step!`. Confirm each in a probe
before writing an assertion, and report the probe's numbers.

### Tests

New testsets in `test/test_blocks.jl`, after the servo loop's.

- **The two forms linearize alike.** With `Kp = 1.0, Ki = 0.5, Kd = 0.2,
  τd = 0.1, Tt = 1.0`, the assembly as the root, and the leaf as
  `Group((; c = leaf); input_wires = ("r" => "c/r", "y" => "c/y", "v" =>
  "c/v"), output_wires = ("c/u" => "u",))`: both build under `(Float64,
  LinearizeDual)`; after `init!` at `r = y = v = 0`, `linearize` with
  `x = (q, yf)` (the assembly's `get_state("int", :q)` and
  `get_state("lag", :q)`, the leaf's `get_state("c", :q)` and `:yf`),
  `u = (r, y, v)` by `get_input` and `y = (u = get_face(:u),)` gives, for
  both, within `1e-12`: `A = [-0.5 -2.0; 0.0 -10.0]`, `B = [0.0 2.0 1.0; 0.0
  10.0 0.0]`, `C = [0.5 2.0]`, `D = [1.0 -3.0 0.0]`. Read them off the
  equations in the comment: `∂q̇/∂q = -Ki/Tt`, `∂q̇/∂yf = Kd/(τd Tt)`,
  `∂u/∂y = -Kp - Kd/τd`, `∂u/∂v = 0`.
- **The single loop winds up without the correction and not with it.**
  `pid_single_loop(pid_assembly(; Kp = 1.0, Ki = 0.5, Kd = 0.2, τd = 0.1,
  Tt))` to `t = 40`. The peak of `plant/out` over the samples is `8.184` at
  `Tt = Inf` and `5.675` at `Tt = 1.0`: assert `> 8.0` and `< 6.0`. Both
  settle: `plant/out ≈ 5.0` within `1e-4` at `t = 40`. The peak of
  `state(sim, "controller/int").q` over the samples is larger at `Tt = Inf`
  than at `Tt = 1.0`, the windup itself, read through the nested path.
- **The leaf in the single loop is refused, and the assembly is not.**
  `failure(() -> build(pid_single_loop(PIDLeaf(Kp = 1.0, Ki = 0.5, Kd = 0.2,
  Tt = 1.0))))` is a `DiagnosticError` whose one diagnostic is an
  `AlgebraicCycle` with `classification === :artificial`, `dead ==
  [("controller", :v, :u)]` and `wires == ["controller/u" => "sat/in1",
  "sat/out" => "controller/v"]`; `build(pid_single_loop(pid_assembly(…)))
  isa Build`. The testset's name cites §5.4 and says what the test shows:
  the leaf consumes `v` in `x_deriv` alone and has a stage-2 output, so
  the wire is a feedthrough edge; the assembly's integrator splits the
  stages.
- **The cascade runs both forms and they agree.** `pid_cascade(controller)`
  with `Kp = 0.5, Ki = 0.1, Kd = 0.0, τd = 0.1` to `t = 60`. For the
  assembly, the peak of `position/out` is `8.330` at `Tt = Inf` and `7.755`
  at `Tt = 2.0`: assert the `Tt = 2.0` peak is below the `Tt = Inf` peak by
  more than `0.5`; `position/out ≈ 5.0` within `5e-3` at `t = 60` for both.
  The leaf at `Tt = 2.0` matches the assembly at `Tt = 2.0` sample by
  sample within `1e-9`; the probe read identical digits.
- **Allocation.** The single loop with the assembly at `Tt = 1.0` and the
  cascade with each form at `Tt = 2.0` join the loops' allocation testset.
  The folds capture `Float64` gains, so they are isbits; if a closure
  allocates, report rather than hoist the gains into a struct.
- **The `Dual` sweep.** `PIDLeaf` takes arguments, so `test/test_build.jl`
  line 1822's pinned count of argument-taking fixtures rises from `61` to
  `62`; update the number and the comment's date.

### Routing

`test/fixtures.jl` gains an `AbstractComponent` fixture and the test
touches wiring, feedthrough tracing and linearization: run
`blocks build events linearize` under the flags of "Running the suite", in
the foreground.

### Bookkeeping, in the same commit

- `docs/design/implementation.md` `### test/fixtures.jl`: a bullet naming
  `PIDLeaf`, the leaf half of §13.7's PID example, whose assembly half is
  `pid_assembly` in `test_blocks.jl`.
- `docs/design/companions/library_inventory.md`: the PID row's mechanism
  cell adds that both forms are built in the tests, and that the leaf's
  tracking input closes an artificial cycle in a single loop (§5.4) where
  the assembly's integrator splits the stages. Status stays *example
  first*. Battery.
- `docs/design/pending.md`: the increment 63 sub-bullet is deleted; the
  tranche bullet then opens with increment 64. Battery.

## The cold review

One fresh Opus reviewer over the two code commits: open-mind stance, probe
scripts under `/tmp`, "empty is acceptable". Dimensions:

- **Each block against its sketch here**, the event order and names, the
  codes' sign convention, the `saturation` port's type and stage, and the
  policies the events product reports for the vector form.
- **The submodule's imports.** `src/blocks.jl` reaches the parent through
  its import list alone; `similar_type` is the one StaticArrays name added.
- **Mutants on a scratch copy**, each named test going red: the vector hit
  handler clamping every component (the `0.45` sample); a vector leave
  guard reading `u.in[1]` for every `i` (the exact-zero component); the
  `saturation` port published as a constant `0`; the vector relay's
  `ifelse` arms swapped; the leaf's `x_deriv` dropping the `v` term (the
  cascade agreement and the `A` matrix); the assembly's `aw` fold dropping
  `Tt` (the single-loop peaks); `PIDLeaf`'s `v` moved into `y_direct` (the
  refusal test's payload). A surviving mutant is a missing test.
- **The numbers.** Re-probe the vector trajectory, the four matrices, the
  peaks and the settling values, and the companion's claims the recode
  touches.
- **`Dual`.** Every new model builds under `(Float64, LinearizeDual)`, and
  the linearizations assert the matrices, so a `Float64` pin anywhere on
  the continuous path is a red test.
- **The example as an example.** Both forms read as a user would write
  them; the refusal test reads as the lesson it is; the nested reads use
  the spellings "What is settled" names.
- **The register, the inventory and the companion note.**
  `implementation.md`'s rows name constructs; behaviour is in docstrings.
- "Naming" over every touched file, the docs battery, and the gate once on
  the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new fixture name across
`test/` before defining it. Fixtures live at top level. Report: the commit
hash, the files touched, the routed subset's result with the assertion
count, the probe's numbers for every asserted value, and every deviation
from this brief with its reason.
