# Brief: increment 69, the PID over vectors, scheduled parameters and setpoint weights, and the `Delay` line

One docs stage, three code stages, one cold review and a fixer if the
review needs one. Written at a682407 on 2026-10-08 and rebased at
0b4f9e5, increment 68's final commit, the same day: 68's fix touched none
of the files this brief anchors by line except in-place replacements
outside every cited range. Every line number below is from `git show
0b4f9e5:file`; the probes of "What is settled" ran at a682407, whose
`src/blocks.jl` and `test/test_blocks.jl` are identical at 0b4f9e5. Find
passages in `docs/design/implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

The user's rulings of 2026-10-08, all library content. None earns a log
entry: `decisions_style.md` rule 9 keeps implementation policy out of the
log, D-313 says a listed block is built whenever wanted, and nothing in the
spec names the PID's or the delay's shape (§13.7's starting inventory at
9862 to 9875 lists neither; the `PID` spellings at spec lines 716 and 3071
are illustrations and stay). The inventory and `pid_anti_windup.md` carry
the design, docs-commit-first, and the code conforms.

- **The PID goes over vectors by widening, not by a parallel type.** The
  library's convention is one struct with `V <: Union{Real,
  StaticArray{<:Tuple, <:Real}}` and the law in broadcast form
  (`LimitedIntegrator`, `Relay`, `DiscreteLimitedIntegrator`,
  `RateLimiter`, `Integrator`, `FirstOrderLag`); the only scalar-versus-
  vector forks in `src/blocks.jl` are `state_events` and the saturation
  code's port type. The PID has no events. `PID{V, Hold, Track, Fixed}` and
  `DiscretePID{V, Hold, Track, Fixed}` over `PIDBlock{V, Hold, Track, Fixed}`,
  `V` first as in `LimitedIntegrator{V, L}` and `Step{V, L}`. **Every
  parameter is a `V`**, the seven of today plus the two weights below:
  `Kp`, `Ki`, `Kd`, `τd`, `Tt`, `u_min`, `u_max`, `b`, `c`, the roster
  `const PID_PARAMETERS = (:Kp, :Ki, :Kd, :τd, :Tt, :u_min, :u_max, :b, :c)`.
  Over a vector every law is componentwise. The saturation port is
  `saturation_type(V)`, `Int8` over a `Real` and `similar_type(V, Int8)`
  over a static array, a two-arm helper shared with `LimitedIntegrator`
  (line 862) and `DiscreteLimitedIntegrator` (251), whose `y_types` pairs
  collapse to one method each. A scheduled parameter never enters
  `saturation_type`; the helper takes `V`.
- **The shape.** The keywords given as values broadcast to one `V` by the
  idiom `GaussianWhiteNoise` uses (319 to 325): `shape` is the sum of
  their `zero`s, each is `Float64.(value .+ shape)`, and `V =
  typeof(shape)`. `promote` is not an option, since `promote(1.0,
  SVector(1.0, 2.0))` throws. A scalar pairs with a vector, integer
  keywords qualify, and a vector PID with uniform gains spells at least one
  vector, `Kp = @SVector fill(2.0, 3)`, as the integrators take their shape
  from `s0`. A parameter given as `AsPort()` takes no part in the shape;
  when every value-carrying keyword is scheduled, `V` is `Float64`. Probed:
  `zero(SVector(1.0, 2.0)) .+ zero(0) .+ zero(0.5)` is an
  `SVector{2, Float64}` and `Float64.(0 .+ shape)` is its zero.
- **Scheduling is per parameter, carried by one type parameter.** Any of
  the nine may be a port instead of a field, spelled `Kp = AsPort()` in
  the constructor, where `struct AsPort end` is a marker type in
  `Redstone.Blocks`. The struct stores only the fixed ones:

  ```julia
  struct PID{V, Hold, Track, Fixed} <: PIDBlock{V, Hold, Track, Fixed}
      fixed::Fixed      # the parameters that are not ports, each a `V`, in roster order
  end
  ```

  `Fixed` is the NamedTuple type of the fixed parameters, in `PID_PARAMETERS`
  order, so every scheduled set is one type and no method dispatches on
  which. Nothing in the law depends on the set: a scheduled gain and a
  fixed gain enter the same expression. The values are fetched by one
  function,

  ```julia
  parameters(c::PIDBlock, u) = NamedTuple{PID_PARAMETERS}(merge(c.fixed, u))
  ```

  `merge` resolves at compile time from the two types and the selection
  lays the nine out in roster order whatever the stagger. Probed at
  a682407 with `Ki` and `u_min` scheduled and `u` listing them last: the
  merged keys read `(:Kp, :Kd, :τd, :Tt, :u_max, :b, :c, :r, :y, :u_min,
  :Ki)`, the selection reads the nine in roster order, and
  `Base.infer_return_type` gives the concrete nine-field NamedTuple. A
  parameter neither fixed nor a port fails inside the selection at the
  law's first specialization, which the constructor makes unreachable.
  Port and parameter names never collide, so merging `u` wholesale is
  safe. The port set is the four `Hold`/`Track` arms of today, renamed
  `signal_ports`, merged with one `V` port per scheduled name:

  ```julia
  signal_ports(::PIDBlock{V, false, false}) where {V} = (r = V, y = V)
  signal_ports(::PIDBlock{V, true, false})  where {V} = (r = V, y = V, saturation = saturation_type(V))
  signal_ports(::PIDBlock{V, false, true})  where {V} = (r = V, y = V, v = V)
  signal_ports(::PIDBlock{V, true, true})   where {V} = (r = V, y = V, saturation = saturation_type(V), v = V)
  function u_types(c::PIDBlock{V, Hold, Track, Fixed}) where {V, Hold, Track, Fixed}
      scheduled = filter(∉(fieldnames(Fixed)), PID_PARAMETERS)
      merge(signal_ports(c), NamedTuple{scheduled}(ntuple(_ -> V, length(scheduled))))
  end
  y_types(::PIDBlock{V}) where {V} = (u = V, u_raw = V)
  ```

  Probed: with `Ki` and `Kd` fixed the declaration reads `(r, y, Kp, τd,
  Tt, u_min, u_max, b, c)`, every entry `V`. `u_types` runs once at build
  and need not fold. `Hold` and `Track` stay as they are: they change the
  law, D-313's companion settled them, and the four arms stay readable.
- **A scheduled port is an ordinary input.** Every input of a PID makes a
  feedthrough edge, since `u` is a stage-2 output (the `PID` docstring's
  last paragraph, 1046 to 1054), so a schedule computed memorylessly from
  the block's own output closes an `AlgebraicCycle` exactly as a clamped
  `v` does, and one read from state is fine. A scheduled gain carries
  partials under a `Dual` activation, so a linearization sees the
  coupling through the schedule; a model that wants the gain frozen at its
  nominal routes the port through `Freeze`. Nothing new to rule on either.
- **The setpoint weights `b` and `c`**, Åström's two-degree-of-freedom
  form, defaults `b = 1.0` and `c = 0.0`, which is today's law. `b`
  weights the reference in the proportional term, `c` in the derivative
  term; the integral's error stays `e = r - y`. The filter state keeps its
  name and sign: `yf` filters the weighted measurement `w = y - c r`, so
  at `c = 0` every existing number holds. Continuous:

  ```
  w     = y - c r
  u_raw = Kp (b r - y) + q - Kd (w - yf) / τd
  u     = clamp(u_raw, u_min, u_max)
  q̇     = Ki · gate(e) + (ref - u_raw) / Tt
  ẏf    = (w - yf) / τd
  ```

  Discrete, with `Δt` the component's own period:

  ```
  deriv = (w - yf) / (τd + Δt)
  u_raw = Kp (b r - y) + q - Kd deriv
  q⁺    = q + Δt Ki · gate(e) + β (ref - u_raw),    β = 1 - exp(-Δt / Tt)
  yf⁺   = yf + Δt deriv
  ```

  Why the measurement by default: the derivative kick of a setpoint step
  through `Kd de/dt` is a spike of height `Kd Δr / τd`, an impulse at
  `τd = 0` on the discrete tier, which drives `u` into saturation where the
  anti-windup takes over; the loop gains set disturbance rejection and
  robustness, and the setpoint response is shaped separately by `b` and
  `c`, both multiplying `r` alone. `c = 1` recovers the derivative on the
  error for a model that wants it, say with a smooth generated reference.
- **The gate and the reference go componentwise.** Probed, scalar, vector
  and `Dual`:

  ```julia
  gated_error(::PIDBlock{V, false}, e, u) where {V} = e
  gated_error(::PIDBlock{V, true}, e, u) where {V} =
      ifelse.(u.saturation .!= 0 .&& u.saturation .== sign.(e), zero(e), e)
  correction_reference(::PIDBlock{V, Hold, false}, u, y) where {V, Hold} = y.u
  correction_reference(::PIDBlock{V, false, true}, u, y) where {V} = u.v
  correction_reference(::PIDBlock{V, true, true}, u, y) where {V} = ifelse.(u.saturation .== 0, y.u, u.v)
  ```

  The `.!= 0` keeps its reason (site comment at 1004 to 1007): a free
  channel at zero error never consults `sign` of a zero-valued `Dual`,
  and a broadcast `ifelse` selects without short-circuiting, so the
  property holds per channel. On scalars these are the expressions of
  today. The laws read `p = parameters(c, u)` and then `p.Kp` and so on,
  and every product with a parameter and every division by one is dotted:
  `SVector * SVector` is a shape error, not an elementwise product. Sums
  and differences of two `V` values stay undotted, as `FirstOrderLag`'s do.
  `x_init(::PID{V}) where {V} = (q = zero(V), yf = zero(V))`, and
  `s_init` likewise; `zero(SVector{3, Float64})` is the zero vector.
  `β = -expm1.(-Δt ./ p.Tt)`; probed over `SVector(1.0, Inf, 0.0)` it
  reads `(0.00995…, 0.0, 1.0)` at `Δt = 0.01`.
- **`Delay{V, K}`**, the discrete tier's `z⁻ᴷ`: `out` publishes `in` from
  `K` ticks ago, from stage 1, so the block has no feedthrough and breaks
  an algebraic loop as `UnitDelay` does; placed in a continuous loop it
  moves the signal onto the discrete tier with the same hold the
  `UnitDelay` docstring describes (141 to 150). `K` counts ticks of the
  component's own period (§10.5): a delay in seconds cannot be a keyword,
  since the block has no `Δt` until it runs, and the model picks `K` from
  the rate it declares. The store is a ring, not a shift register, so the
  work per tick and the compile cost are constant in `K` (a `K`-element
  tuple splat unrolls, D-289's concern):

  ```julia
  struct Delay{V <: Union{Real, StaticArray{<:Tuple, <:Real}}, K} <: AbstractComponent
      v0::V
  end
  function Delay(; K::Int, v0 = 0.0)
      K >= 1 || throw(ArgumentError("Delay takes `K >= 1`; `K = 1` is `UnitDelay`."))
      v0 = float(v0)
      Delay{typeof(v0), K}(v0)
  end
  s_init(c::Delay{V, K}) where {V, K} = (buf = SVector{K, V}(ntuple(_ -> c.v0, K)), k = 1)
  u_types(::Delay{V}) where {V} = (in = V,)
  y_types(::Delay{V}) where {V} = (out = V,)
  y_state(::Delay, (; s)) = (out = s.buf[s.k],)
  s_update(::Delay{V, K}, (; s, u)) where {V, K} =
      (buf = Base.setindex(s.buf, u.in, s.k), k = s.k == K ? 1 : s.k + 1)
  ```

  The slot under the cursor holds the value from `K` ticks ago; the update
  overwrites it with `in` and advances. `V` is `Float64` or a static
  array of it from `float(v0)`, as `DiscreteIntegrator` does, and an
  `SVector{K, V}` with `V` a static vector is isbits (probed:
  `SVector{4, SVector{3, Float64}}`, `Base.setindex` on it typed). One
  output: the inventory's word "tapped" goes, since a model that wants
  taps places delays in series, and a port carrying the whole line would
  be a second shape for nothing. `UnitDelay` keeps its name, its
  positional constructor and its D-312 standing; `Delay(K = 1, v0)` is
  the same block in the keyword spelling. The continuous transport delay
  stays not admitted (inventory line 126).
- **Verified before writing.** `Delay`, `AsPort`, `saturation_type`,
  `parameters`, `signal_ports`, `PID_PARAMETERS` and a field `fixed` bind
  nothing in `src/` or `test/` (`Base` exports no `parameters`). The
  Julia floor is 1.13 (`Project.toml` 16). `test/imports.jl` 77 to 81 is
  the `Redstone.Blocks` import line. `TickCounter` (`test/fixtures.jl`
  198) and `delay_model` (`test/test_blocks.jl` 24) drive the `UnitDelay`
  test at 507. The PID models are `test/test_blocks.jl` 252 to 349, all
  scalar: `pid_controller`, `pid_root_model`, `pid_clamp_loop`,
  `pid_assembly`, `pid_single_loop`, `pid_servo_loop`, `pid_cascade`,
  `discrete_hold_loop`, with `loop_samples` and `settling_time`. The
  PID testsets are 1272 to 1343 and 1457 to 1536; the constructor
  testset at 1537 asserts `PID(Kp = 1) isa PID{false, false}` and
  `fieldnames(PID)` all `Float64`; the loops' allocation testset at 1575
  and the shadowing sweep at 1599 list PID spellings; the discrete tier's
  allocation testset is 669. `vector_limited_model` (220) and the
  testset at 1156 are the vector-equivalence pattern.

## Out of scope

- Scheduling on any other block. The mechanism generalizes to
  `FirstOrderLag`'s `τ`, `RateLimiter`'s rates and the limited
  integrators' limits; a second block carrying it is the moment it
  becomes a convention, not this one.
- Folding `Hold` and `Track` into the port-set mechanism.
- Taps on `Delay`, a delay in seconds, or a continuous transport delay.
- Integrator authority limits, feedforward in the clamp, a general hold
  rule, the velocity form, internal clamping, and `yf` starting at the
  first measurement: `pid_anti_windup.md` section 6 keeps them.
- Any spec or log edit. A shape that needs one is a stop-and-report.

## Reading, in order

- `docs/design/pending.md` 10 to 16 and 144 to 146.
- `docs/design/decisions.md` D-313 (13093 to 13151), D-312 (13037 to
  13092), D-231 (8634), D-263 (10356), D-289 (12153).
- `docs/design/spec.md` §13.7's library part, 9862 to 10005; §5.4, 1042
  to 1111; §5.6, 1132 to 1219; §7.3, 1699 to 1847; §10.5's `Δt` rule, 5876
  to 5895; §4.3, 491 to 600. Never read the spec whole.
- `docs/design/companions/pid_anti_windup.md` whole (392 lines), the
  block's companion; `docs/design/companions/library_inventory.md` 39 to
  96 (the guidelines and the constructor convention), 135 to 146 (the
  discrete tier) and 154 to 166 (the controllers).
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/blocks.jl`, `### test/fixtures.jl`
  and `### test/imports.jl`; "Authoring caveats" whole, the mutant
  caveat last of all; "Naming"; "Running the suite". Never restate either
  in a commit or a comment.
- `src/blocks.jl` 1 to 14; 121 to 175 (the leaf blocks, `UnitDelay` at
  141 to 158); 198 to 290 (the discrete tier); 291 to 354 (the noise
  source, the shape idiom at 319 to 325); 805 to 984 (the moded blocks,
  the `V` pattern, `similar_type` at 862); 985 to 1139 (the controller
  section, whole).
- `test/test_blocks.jl` 1 to 30, 252 to 349, 491 to 575, 669 to 697,
  1156 to 1200, 1272 to 1343, 1457 to 1600, 1599 to 1637; `test/imports.jl`
  77 to 81.

## Stage 0: the companion and the inventory

### The shape

One docs commit, written under `docs/design/tools/spec_style.md`'s
battery section (144 on) read first; no spec or log edit, so
`decisions_style.md` is not opened.

- **`docs/design/companions/pid_anti_windup.md`.** Section 4's "The
  grouping" paragraph (168 to 174) gains the weighted law: `b` in the
  proportional term, `c` in the derivative's weighted measurement `w = y -
  c r`, defaults `1` and `0`, the kick argument in two sentences, and that
  the integral's error is unweighted. Section 6 loses its "Setpoint
  weighting" (208 to 211) and "Gain scheduling" (224 to 226) bullets;
  the others stay. Section 9's "The law is shared, not the type" paragraph
  (367 to 372) names `PIDBlock{V, Hold, Track, Fixed}` and the eleven shared
  methods (four `signal_ports`, `u_types`, `y_types`, two `gated_error`,
  three `correction_reference`) plus `parameters`; its last paragraph
  (374 to 381) says `s_init` and `x_init` are `zero(V)`. A new section 10,
  "Vectors, scheduled parameters and the weights", in the companion's
  register, carrying: the widening-not-forking argument with the two forks
  the library has; `V` first and every parameter a `V`; the shape rule and
  the uniform-gains spelling; `AsPort()`, `fixed::Fixed`, `parameters` and
  the staggered-order fact; why no method dispatches on the scheduled
  set and why `Hold` and `Track` are not folded; a scheduled port as an
  ordinary feedthrough input, the cycle it can close and `Freeze` for a
  frozen linearization; the setpoint weights with the law in both tiers.
  About 60 lines; the code sketches of "What is settled" may be quoted.
- **`docs/design/companions/library_inventory.md`.** The constructor
  paragraph (86 to 96) gains two sentences: keywords that share `V`
  broadcast to one shape, a scalar pairing with a vector and the shape's
  type being `V`, so a uniform vector spells one vector keyword; and a
  keyword given as `AsPort()` is a port of the block and takes no part
  in the shape. The controllers table (158 to 160): `PID{V, Hold, Track,
  Fixed}` and `DiscretePID{V, Hold, Track, Fixed}` rows restated, componentwise
  over a static vector, every parameter a `V`, any parameter a port by
  `AsPort()`, the weights `b` and `c` with their defaults, the
  companion's section 10 cited; the "gain-scheduled `PID`" candidate row
  retires into them. The discrete tier table (145): `Delay{V, K}` becomes
  a shipped row, "the tier's `z⁻ᴷ` in a ring store, `K` ticks of the
  component's own period, one output, `K = 1` the `UnitDelay` in keyword
  spelling", citing §10.5.
- **`docs/design/pending.md`.** At the head of the first section (before
  "The inspector", line 16), the increment 69 bullet in working order,
  stating what the code owes the inventory and the companion: the vector
  `PID` and `DiscretePID` with `saturation_type` shared (stage 1), the
  scheduled parameters and the weights (stage 2), `Delay{V, K}` (stage 3).
  Stage 3 removes it, and removes `Delay{V, K}` from "The library's
  remaining candidates" (144 to 146), which keeps the rest of its text.

### The battery

`check_refs.jl`, `check_rows.jl`, `check_glossary.jl --strict`,
`check_bold.jl`, then `linkify.jl` and `check_refs.jl` again, all green.
Both companions are in `check_rows.jl`'s `FILES` and the inventory in
`check_refs.jl`'s `ROSTER`. A scripted edit reads and asserts every
file's matches before opening any for writing; `git diff --stat` before
committing.

### Bookkeeping

Nothing in `src/` or `test/`. The commit touches the two companions and
`pending.md`, and nothing else.

## Stage 1: the PID over vectors

### The shape

`saturation_type` in the moded-blocks section before `LimitedIntegrator`,
with a one-line site comment, and the two `y_types` pairs (251 and 862)
collapsed to one method each over it. In the controller section:
`PIDBlock{V, Hold, Track}` with `V` first, the four `u_types` arms and
`y_types` over `V` and `saturation_type(V)`, the gate and the reference
as settled, `PID{V, Hold, Track}` and `DiscretePID{V, Hold, Track}` with
their seven fields typed `V`, the constructors broadcasting by the shape
idiom, `x_init` and `s_init` from `zero(V)`, the laws dotted. The two
docstrings gain the sentence the other vector blocks carry (`V` is
`Float64` or a static array of `Float64`, componentwise), the shape rule
and the uniform-gains spelling. The stage-2 names (`Fixed`, `fixed`,
`parameters`, `signal_ports`, `b`, `c`) do not appear yet.

### Tests

- The testsets at 1272 and 1457: `isa PID{true, true}` becomes `PID{Float64,
  true, true}`, the two `PIDBlock{…}` assertions take `Float64` first;
  every number there holds unchanged. The constructor testset at 1537:
  `PID{Float64, false, false}`, `DiscretePID{Float64, false, false}`, and
  new arms `PID(Kp = SVector(1, 2)) isa PID{SVector{2, Float64}, false,
  false}` with `.Ki === SVector(0.0, 0.0)`, `DiscretePID(Kp = 1, u_max =
  SVector(1.0, 2.0)) isa DiscretePID{SVector{2, Float64}, false, false}`
  with `.Kp === SVector(1.0, 1.0)`, and `u_types(PID(Kp = SVector(1.0,
  2.0), hold = true)).saturation === SVector{2, Int8}`.
- A new testset after 1343, "the vector PID is two scalar PIDs side by
  side, in both tiers (§13.7, D-313)". Law level: a second gain set that
  separates every expression from `pid_controller`'s, `(Kp = 2.0, Ki =
  0.25, Kd = 0.1, τd = 0.2, Tt = 2.0, u_min = -0.5, u_max = 0.5)`; over
  the seven rows of the table at 1285, the 2-vector controller built from
  the two sets componentwise, with `x`, `u` and `y` the two scalar rows
  stacked (the second row's inputs `(r = 1.0, y = 2.0)` and, where
  present, the same code and `v = -0.3`), asserts `y_direct` and
  `x_deriv` equal to the two scalar blocks' results component by
  component, `atol = 1e-12`; the same over `DiscretePID` with `s_update`
  at `Δt = 0.01`. Loop level: a new model `vector_pid_loop()` beside
  `pid_single_loop`, a 2-vector `Step(t_step = 0.5, after = SVector(5.0,
  3.0))`, the vector controller and a vector `Integrator`, whose samples'
  first component equals `pid_single_loop(pid_controller(false, false))`'s
  samples to `1e-12` and whose second equals the second gain set's scalar
  loop on a reference of 3; and `build(…; activations = (Float64,
  LinearizeDual)) isa Build` on it.
- `vector_pid_loop()` joins the allocation testset at 1575, and a vector
  `PID` and `DiscretePID` with `hold = true, tracking = true` join the
  shadowing sweep at 1599.

### Routing

`blocks build`, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/blocks.jl`: the
  `DiscreteLimitedIntegrator` line and the `LimitedIntegrator` line name
  `saturation_type` where they name `saturation_code` and the `Int8`
  modes; the `PIDBlock` line reads `PIDBlock{V, Hold, Track}` over `Real`
  and static vectors. Constructs, not behaviour.
- `test/imports.jl`: nothing new.

## Stage 2: the scheduled parameters and the setpoint weights

### The shape

In the controller section: `PID_PARAMETERS`, `AsPort`, `PIDBlock{V,
Hold, Track, Fixed}`, `signal_ports`, `u_types`, `parameters`, `fixed::Fixed` on
both structs, the constructors taking the nine keywords with `b = 1.0`
and `c = 0.0`, splitting on `=== AsPort()`, broadcasting the values by
the shape and building `Fixed` in roster order, and the laws as settled with
`w = y - c r`. A `AsPort()` docstring of four lines. Both PID
docstrings gain the weights in their law and their table, the scheduling
paragraph (the spelling, the port's type, no part in the shape, the
feedthrough edge and `Freeze`), and state that `yf` filters the weighted
measurement. The `DiscretePID` docstring's law and table follow.

Probe before asserting and report the numbers: for the weight row below,
print `y_direct` and `x_deriv` of the continuous block and `y_direct` and
`s_update` of the discrete one, and for the scheduled linearization the
`B` and `D` matrices.

### Tests

- The ports testset at 1272 gains: `u_types(PID(Kp = AsPort(), Ki =
  0.5)) == (r = Float64, y = Float64, Kp = Float64)`; with `hold = true,
  tracking = true` and `Ki` and `u_min` scheduled, the declaration reads
  `(r, y, saturation, v, Ki, u_min)` in that order; `fieldnames(typeof(PID(Kp
  = AsPort()).fixed))` lacks `:Kp` and holds the other eight in roster
  order; and `AsPort()` on a vector block, `PID(Kp = AsPort(), Ki =
  SVector(1.0, 2.0))`, declares `Kp = SVector{2, Float64}`.
- The law testset at 1282 gains a second pass over its seven rows with
  `Kp` and `u_min` scheduled and their values moved into `u`, every
  assertion unchanged, and the discrete testset at 1457 likewise with
  `Ki` and `Tt` scheduled. Order matters: the scheduled values differ
  from any default, so `merge(u, c.fixed)` in place of `merge(c.fixed, u)`
  cannot pass.
- The weights, law level, in the testset at 1282: `pid_controller`'s
  gains with `b = 0.5, c = 1.0`, `x = (q = 0.3, yf = 0.1)`, `u = (r =
  3.0, y = 0.5)`, `y = (u = 1.0, u_raw = 6.5)`: `u_raw ≈ 6.5`, `u == 1.0`,
  `deriv.yf ≈ -26.0`, `deriv.q ≈ -4.25` (`1.25 + (1 - 6.5)`), each `atol =
  1e-12`; and `b = 1.0, c = 0.0` reproduces the first row exactly. The
  discrete counterpart in the testset at 1457, `Δt = 0.01`: `deriv =
  -2.6 / 0.11`, `u_raw ≈ 1.3 + 0.2 · 2.6 / 0.11`, `yf⁺ ≈ 0.1 - 0.026 /
  0.11`, `q⁺ = 0.3 + 0.0125 + β (1 - u_raw)`, the literals computed in the
  REPL and asserted as the testset's existing rows are.
- The weights, linearization, a row in the testset at 1305: `pid_root_model`
  over `pid_controller(false, false)` rebuilt with `b = 0.5, c = 1.0`
  gives `A = [0 0; 0 -10]`, `B = [0.5 -0.5; -10 10]`, `C = [1 2]`, `D =
  [2.5 -3]`, the `B[2, 1]` and `D[1, 1]` entries being the two the weights
  touch (`-c/τd` and `Kp b + Kd c/τd`).
- A new testset after 1343, "a scheduled parameter is a port: it carries
  partials, freezes through `Freeze`, and closes a cycle from the own
  output (§13.7, §5.4, §14.10)". Model `scheduled_pid_root(controller)`
  beside `pid_root_model`, every scheduled name a root input. With `Kp`
  scheduled and the operating point `r = 1.0, y = 0.25, Kp = 1.0`
  (`u_raw = 0.25`, inside the limits), `linearize` over inputs `(r, y,
  Kp)` reads `D[1, 3] ≈ 0.75` (`b r - y`) and a zero third column in `B`;
  the same model with `Freeze{Float64}()` between the root input and the
  port reads `D[1, 3] == 0`. A second model wiring `Kp` from
  `Junction{Float64, Float64, 1}(abs)` over the controller's own `u` is
  refused as `AlgebraicCycle` with the testset at 1333's assertions. A
  loop: `pid_single_loop` over a controller with `Kp = AsPort()` and a
  `Constant(1.0)` child wired into `controller/Kp` reproduces
  `pid_single_loop(pid_controller(false, false))`'s samples to `1e-12`
  (a model `scheduled_pid_loop()` beside the others).
- The constructor testset at 1537: the two `fieldnames` arms become
  `all(v -> v isa Float64, values(PID(Kp = 1).fixed))` and the discrete
  twin; new arms `PID(Kp = 1, Ki = AsPort()) isa PID{Float64, false,
  false, <:NamedTuple}`, `PID(Kp = AsPort(), Ki = AsPort(), Kd =
  AsPort(), τd = AsPort(), Tt = AsPort(), u_min = AsPort(),
  u_max = AsPort(), b = AsPort(), c = AsPort()) isa PID{Float64}`
  with `fixed === (;)`, and `PID(Kp = SVector(1.0, 2.0), Ki = AsPort())`
  declaring `Ki = SVector{2, Float64}`.
- `scheduled_pid_loop()` joins the allocation testset at 1575; `PID(Kp =
  AsPort(), b = 0.5, c = 1.0)` and a `DiscretePID` with two scheduled
  parameters join the shadowing sweep at 1599.

### Routing

`blocks build`, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/blocks.jl`: the `PIDBlock`
  line reads `PIDBlock{V, Hold, Track, Fixed}`, carrying `signal_ports`,
  `u_types`, `parameters`, `gated_error` and `correction_reference`, with
  `AsPort` and the roster `PID_PARAMETERS`.
- `test/imports.jl`: `AsPort` on the `Redstone.Blocks` line.

## Stage 3: the delay line

### The shape

`Delay{V, K}` as settled, in the discrete tier section (198) before
`DiscreteIntegrator`, its docstring saying what `K` counts, that the store
is a ring whose cursor slot is the value from `K` ticks ago, that `K = 1`
is `UnitDelay` in keyword spelling, that the block breaks a loop from
stage 1, and the tier-move sentence `UnitDelay`'s docstring carries.

### Tests

- A new testset after 519, "the delay line publishes its input `K` ticks
  late, `v0` before, from a ring (§7.3, §13.7, D-313)": `delay_model`
  generalized to take the block (`delay_model(UnitDelay(v0))` keeps the
  testset at 507 as it is); with `Delay(K = 3, v0 = -1)` and the counter
  at `h = 1//100`, `out` reads `-1` at ticks 0, 1 and 2 and `k - 3` from
  tick 3 to tick 8, past one full turn of the ring; `Delay(K = 1, v0 = -1)`
  reads exactly what `UnitDelay(-1)` reads over the same ticks; a 2-vector
  `Delay(K = 2, v0 = SVector(0.0, 0.0))` under `fed_by(Constant(SVector(1.0,
  -2.0)), …)` reads `v0` for two ticks and the constant from the third;
  `Delay(K = 2, v0 = [1.0])` is refused as `IllegalStoreField` as at 517;
  `Delay(K = 0)` throws `ArgumentError`; and a loop closed through a
  `Delay` and a `Junction` builds (the pattern of the discrete integrator's
  loop at 520 to 546).
- `Delay(K = 2, v0 = 1) isa Delay{Float64, 2}` in the constructor testset
  at 1537; `fed_by(Constant(1.0), Delay(K = 50, v0 = 0.0))` in the
  discrete tier's allocation testset at 669, `K = 50` so a shift-register
  regression would show; `Delay(K = 3, v0 = 0.0)` and the vector one in
  the shadowing sweep at 1599.

### Routing

`blocks build`, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`, `### src/blocks.jl`: `Delay` on the
  discrete tier line.
- `docs/design/pending.md`: the increment 69 bullet is removed, and
  `Delay{V, K}` leaves the "remaining candidates" bullet; run the battery.
- `test/imports.jl`: `Delay` on the `Redstone.Blocks` line.

## The cold review

One fresh Opus reviewer over the three code commits, the docs commit read
for what they owe: open-mind stance, probe scripts in the scratchpad,
"empty is acceptable". Dimensions:

- **The companion against the tree.** Section 10's every sentence holds
  of the code: the shape rule, the roster order, the port set, the
  feedthrough edge, the weights' law in both tiers. The two inventory rows
  name the type parameters the code has.
- **Equivalence.** On a scratch copy, a 3-vector `PID` and `DiscretePID`
  with three distinct gain sets, hold and tracking on, random inputs and
  codes over 200 draws: every output and every store update equals the
  three scalar blocks' to `1e-12`. The same with two parameters scheduled
  per draw, the scheduled set chosen at random from the nine.
- **Mutants on a scratch copy**, each named test going red: a `*` for a
  `.*` in `y_direct`; the gate's `.&&` as `.||`; `merge(u, c.fixed)`;
  `b` applied inside the integral's error; `c` with its sign flipped;
  `yf` filtering `y` with `c` dropped from the filter alone; `zero(V)`
  replaced by `0.0` in `x_init`; the scalar arm of `saturation_type`
  returning `V`; the ring publishing the slot after the cursor; the cursor
  never wrapping; `K = 0` admitted. A surviving mutant is a missing test.
- **Allocation.** The vector loop, the scheduled loop and the `K = 50`
  delay allocate nothing past 1000 frames, and `K = 200` compiles in the
  same order of time as `K = 2` (report both).
- **The register and the docstrings.** Rows name constructs; the three
  docstrings and `AsPort`'s say what the companion says and no more;
  the spelling that settles `V` is stated in the inventory's constructor
  paragraph and in both PID docstrings.
- "Naming" over every touched file, the docs battery, and the gate once
  on the real tree, on the Julia floor `Project.toml` declares.

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
