# Brief: increment 61, the library's second tranche

Two code stages, one cold review and a fixer if the review needs one. The
docs arc is landed: D-313 rewritten in place as three weighed admission
guidelines, with the demonstrating-model condition dropped, in the commit
"Replace D-313's admission rule with three weighed guidelines and drop the
demonstrating-model condition". The tip at launch is that commit, df08cb0, and line
numbers below are its. Find passages in `docs/design/implementation.md` by
heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **Five blocks join `Redstone.Blocks`** in `src/blocks.jl`: `Integrator{V}`,
  `FirstOrderLag{V}` and `Step{V, L}` over scalars and static vectors, and
  `LimitedIntegrator{V <: Real}` and `Relay{V <: Real}` over scalars. Each is
  an ordinary component written against the import list the file opens
  with (§13.7, D-313).
- **Why these five.** Judged against D-313's guidelines, each is
  domain-agnostic, and each shows one mechanism in a simple form: the
  continuous state that walks under `Dual` (`Integrator`, `FirstOrderLag`),
  §2.1's two detection policies in one block (`Step`), and a mode read by
  the derivative with sign-form events gated by the mode
  (`LimitedIntegrator`, `Relay`).
- **Instance data is plain.** Initial values, time constants, limits and
  thresholds are fields of the instance, the pinned-parameter class of
  §7.2. A `Float64` contract leaf walks under the activation (§7.2, D-263);
  the type parameter `V` exists so one block serves `Float64` and
  `SVector{N, Float64}` ports, never for differentiation.
- **Every block's output port is `out` and its input is `in`**, the
  inventory's convention. Every stateful block names its state `q`.
- **The policy of `Step` is a type parameter**, because D-179 reads the
  policy off the guard's probed return type, so the choice cannot be a
  field.
- **Every block has a keyword constructor with defaults**, the form the
  docstrings show and the tests use. The positional constructor stays, as
  the struct's default. A keyword with no default is required (`τ`,
  `t_step`, `lower`, `upper`), and where several fields share `V` the
  constructor promotes them, so `lower = -1, upper = 0.5` builds a
  `Float64` block instead of failing. With no arguments the defaults pin
  `Float64`, which §7.2 names as the `@kwdef` convention; the constructors
  are hand-written because `Step`'s policy is not a field and the others
  promote.
- **Two demonstrating loops** live in `test/test_blocks.jl` as test models,
  a servo loop and a bang-bang loop. They are the inspector's first
  examples later, so they are built from library blocks alone.
- **Boundary zero establishes every prior as not-holding** (§10.6), so a
  predicate already holding in the authored state fires at `t₀`
  (`test/test_events.jl` line 143). Each block's initial mode is therefore
  made consistent with its initial input by the framework. The docstrings
  say so; nothing checks or documents a trap that does not exist.

## Out of scope

- The vector forms of `LimitedIntegrator` and `Relay`, which need
  componentwise modes and masked reductions. Stage 2 lists them in the
  inventory as candidates.
- Every other candidate row of `docs/design/companions/library_inventory.md`.
- Argument validation on instance data (`τ > 0`, `lower < upper`). The
  docstrings state the domain.
- Exports. The module exports nothing until the audit (D-226); tests reach
  the blocks through `test/imports.jl`.
- Any spec or log edit. §13.7's "starting inventory" sentence describes the
  first tranche and stays; the inventory companion is where rows flip.

## Reading, in order

- `docs/design/spec.md` §13.7, lines 9713 to 9938, whole: the library and
  the rig. §2.1, lines 229 to 273: the two policies and edge semantics.
  §5.2, lines 678 to 825: the signature block (the names a guard, a
  handler and `x_deriv` receive, `t` always among them), the bundle law and
  the handler return law. §5.3, lines 867 to 903: `y_state` sees no `u`,
  which is why a `Relay` closes a loop. §7.2, lines 1625 to 1694: what
  walks and what pins. §7.3, lines 1706 to 1740: the mode store. §8.2,
  lines 2288 to 2351 and 2695 to 2708: state and mode declarations, and
  `state_events`. §10.4, lines 5205 to 5268: detection policy, the gate
  form `(gate) ? σ : -one(σ)`, and trial evaluations. §10.6, lines 5864 to
  5970: quiescence and the priors. Never read the spec whole.
- `docs/design/decisions.md` D-313, D-312, D-179, D-231 and D-290.
- `docs/design/companions/library_inventory.md`, sections 2 and 3.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/blocks.jl`,
  `### test/fixtures.jl` and `### test/imports.jl`; "Authoring caveats",
  above all its first three bullets; "Naming", which governs every name
  you add or touch; "Running the suite", the one home of test policy.
  Never restate either in a commit or a comment.
- `src/blocks.jl` whole: the import list, the shipped blocks and their
  docstrings, which set the register for the new ones.
- `test/test_blocks.jl` whole: the models at top level, the testsets, the
  allocation idiom and the shadow-check testset you extend.
- `test/fixtures.jl` 322 to 390 and 548 to 574: `Trigger`, `Follower`,
  `Sawtooth` and `Relaxer`, the fixtures whose shapes the new blocks
  follow (a mode-only leaf with events; a sign-form guard with an
  `x`-writing handler; a handler writing `x` and `m` together).
- `test/test_events.jl` 116 to 154 and 209 to 226: how a policy is read off
  the build's events product (`policies` is `(name = :boundary,)` or
  `(name = :localized,)`, `src/build.jl` line 672), and how a localized
  firing is asserted against a boundary recursion.
- `test/test_events.jl` 317 to 332: the quiet-boundary allocation gate.
- `test/test_linearize.jl` 1 to 120: how a linearization is requested and
  its matrices read.
- `src/localization.jl` 150 to 190: a trial evaluation sets the clock to
  the trial instant, so a sign-form guard on `t` localizes like any other.
- `src/build.jl` 1220 to 1230: the probe that classifies a guard's form.

## Stage 1: the plain blocks

### The shape

Three blocks, each with a docstring in the register of the shipped ones,
saying what the block computes, what it shows, and the domain of its
instance data. The bound on `V` is spelled inline as `Freeze` spells it;
no alias is introduced, since every new name is the audit's business.

```julia
struct Integrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    x0::V
end
Integrator(; x0 = 0.0) = Integrator(x0)
x_init(b::Integrator) = (q = b.x0,)
u_types(::Integrator{V}) where {V} = (in = V,)
y_types(::Integrator{V}) where {V} = (out = V,)
y_state(::Integrator, (; x)) = (out = x.q,)
x_deriv(::Integrator, (; u)) = (q = u.in,)

struct FirstOrderLag{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    x0::V
    τ::Float64        # the time constant, positive
end
FirstOrderLag(; τ, x0 = 0.0) = FirstOrderLag(x0, τ)
x_init(b::FirstOrderLag) = (q = b.x0,)
u_types(::FirstOrderLag{V}) where {V} = (in = V,)
y_types(::FirstOrderLag{V}) where {V} = (out = V,)
y_state(::FirstOrderLag, (; x)) = (out = x.q,)
x_deriv(b::FirstOrderLag, (; x, u)) = (q = (u.in - x.q) / b.τ,)

struct Step{V <: Union{Real, StaticArray{<:Tuple, <:Real}}, L} <: AbstractComponent
    before::V
    after::V
    t_step::Float64
end
function Step(; t_step, before = 0.0, after = 1.0, localized = true)
    before, after = promote(before, after)
    Step{typeof(before), localized}(before, after, t_step)
end
x_init(::Step) = (;)
m_init(::Step) = (fired = false,)
y_types(::Step{V}) where {V} = (out = V,)
y_state(b::Step, (; m)) = (out = m.fired ? b.after : b.before,)
step_guard(b::Step{V, true}, (; t)) where {V} = t - b.t_step     # sign form: localized
step_guard(b::Step{V, false}, (; t)) where {V} = t >= b.t_step   # Bool form: boundary-detected
step_handler(::Step, _) = (m = (fired = true,),)
state_events(::Step) = (fire = StateEvent(step_guard, step_handler),)
```

`m_init` and `x_deriv` join the import list; `StateEvent` too. The guard
and handler names follow "Naming". Read the input as `u.in`, never by
destructuring `(; in)`, which shadows `Base.in` in the body. `Step`'s docstring states the two
policies in §2.1's words: the localized form ends the step at the crossing
and the jump lands there; the boundary-detected form fires at the end of
the step in which `t ≥ t_step` was first observed, so the jump lands on the
first boundary at or after `t_step`, never inside a step. It also says why
the choice is a type parameter (D-179).

### Tests

New testsets in `test/test_blocks.jl`, models at top level beside the
existing ones. Each test goes red under the mutants the review runs.

- **The integrator.** `Integrator(x0 = 1.0)` fed by `Constant(2.0)` at
  `h = 1//100`: after `step!(sim; t_plus = 0.5)`, `state(sim, "i").q ≈ 2.0`
  within `1e-12`, and `port(sim, "i", :out)` equals it. The vector form,
  `Integrator(x0 = SVector(0.0, 1.0))` fed by `Constant(SVector(1.0, -1.0))`,
  gives `SVector(0.5, 0.5)`. Linearized through a root input (wrap the
  block in a `Group` with `input_wires = ("u" => "i/in",)`), `A` is `0` and
  `B` is `1`.
- **The lag.** `FirstOrderLag(τ = 0.5)` fed by `Constant(1.0)` at
  `h = 1//100`: at `t = 1`, `q ≈ 1 - exp(-2)` with `rtol = 1e-7`. The vector
  form matches componentwise. Linearized, `A` is `-2` and `B` is `2`.
- **The step, both policies.** `Step(t_step = 0.25)` feeding
  `Integrator()` at `h = 1//10`. Localized: after `t_plus = 0.3`, the
  integrator's `q` is `0.05` within the localization tolerance (read
  `localization_tol`'s default off the deployment constants, §10.4, and
  set `atol` from it), and the build's events product reports
  `(fire = :localized,)`. Boundary-detected (`localized = false`): `q == 0`
  at `t = 0.3`, `q ≈ 0.1` at `t = 0.4`, and the product reports
  `(fire = :boundary,)`. Before `t_step` both forms publish `before`. A
  `Step` whose `t_step` is at or before `t₀` publishes `after` right after
  `init!`, the boundary-zero rule. The vector form,
  `Step(t_step = 0.25, before = SVector(0.0, 0.0), after = SVector(1.0, -1.0))`,
  builds and switches. Mixed keywords promote: `Step(t_step = 0.25, after = 2)`
  is a `Step{Float64, true}`.
- **Allocation.** The step-into-integrator model's phase bodies allocate
  nothing, by the existing idiom in this file, and its boundary with the
  event quiet does not allocate, by the `test_events.jl` 317 idiom.
- **The shadow check.** The three blocks join the existing testset's list.

No new `AbstractComponent` fixture is expected. If one proves necessary,
it lives at top level in `test/fixtures.jl`, grepped across `test/` first,
and `build` joins the routed subset.

### Routing

`src/blocks.jl` is the `blocks` row: `blocks build`. Name a generous set:
run `blocks build events linearize` under the flags of "Running the
suite", in the foreground.

### Bookkeeping, in the same commit

- `test/imports.jl`: `Integrator`, `FirstOrderLag` and `Step` join the
  `import Redstone.Blocks:` line.
- `docs/design/implementation.md` `### src/blocks.jl`: a bullet naming the
  three blocks with their entry (D-313), and §2.1 and §10.4 join the Spec
  line. Run the docs battery after editing it; each tool's header says how,
  and `--strict` is a separate argument to `check_glossary.jl`.

## Stage 2: the moded blocks and the loops

### The shape

```julia
struct LimitedIntegrator{V <: Real} <: AbstractComponent
    x0::V
    lower::V
    upper::V
end
LimitedIntegrator(; lower, upper, x0 = zero(lower)) =
    LimitedIntegrator(promote(x0, lower, upper)...)
x_init(b::LimitedIntegrator) = (q = b.x0,)
m_init(::LimitedIntegrator) = (sat = :free,)        # :free, :upper or :lower
u_types(::LimitedIntegrator{V}) where {V} = (in = V,)
y_types(::LimitedIntegrator{V}) where {V} = (out = V,)
y_state(::LimitedIntegrator, (; x)) = (out = x.q,)
x_deriv(::LimitedIntegrator, (; u, m)) = (q = m.sat === :free ? u.in : zero(u.in),)
```

Four events, declared in this order: `hit_upper`, `hit_lower`,
`leave_upper`, `leave_lower`. The hit guards are ungated sign forms,
`x.q - b.upper` and `b.lower - x.q`; their handlers write the state to the
limit exactly and the mode to `:upper` or `:lower`, both keys in one return.
The leave guards are gated by the mode in §10.4's form,
`m.sat === :upper ? -u.in : -one(u.in)` and
`m.sat === :lower ? u.in : -one(u.in)`; their handlers set `:free`. The hit
guards are not gated on purpose: gated by `:free`, a hit guard would read
`0` the instant a leave handler frees the mode, present a fresh edge, and
re-saturate. Say so in a site comment. The docstring states that `x0`
outside the limits is clamped at boundary zero, by the same rule that
fires a holding predicate at `t₀`.

```julia
struct Relay{V <: Real} <: AbstractComponent
    lower::V      # switch off when `in` falls to it
    upper::V      # switch on when `in` rises to it
    off::V        # `out` while off
    on::V         # `out` while on
end
Relay(; lower, upper, off = zero(lower), on = one(lower)) =
    Relay(promote(lower, upper, off, on)...)
x_init(::Relay) = (;)
m_init(::Relay) = (state = :off,)
u_types(::Relay{V}) where {V} = (in = V,)
y_types(::Relay{V}) where {V} = (out = V,)
y_state(b::Relay, (; m)) = (out = m.state === :on ? b.on : b.off,)
```

Two events, `switch_on` then `switch_off`, both gated sign forms:
`m.state === :off ? u.in - b.upper : -one(u.in)` and
`m.state === :on ? b.lower - u.in : -one(u.in)`. The docstring says the
relay starts off, that an input already at or above `upper` at `t₀` turns
it on at boundary zero, and that an input between the thresholds at `t₀`
leaves it off, which is the hysteresis itself. It also says that `out` is a
stage-1 port, so a relay in a feedback loop is not an algebraic loop
(§5.3), the reference mode-switching leaf of the inventory.

### The two loops

Top-level functions in `test/test_blocks.jl` returning a `Group`, built
from library blocks alone.

- **The servo loop.** `Step(t_step = 0.5)` as the reference into `in1` of
  `Junction{Float64, Float64, 2}(-)`; the plant output into `in2`; the
  error into `LimitedIntegrator(lower = -2.0, upper = 2.0)`; its output
  through `FirstOrderLag(τ = 0.1)`, the actuator, into `FirstOrderLag(τ = 1.0)`,
  the plant, whose `out` is the loop's output face. The loop is stable
  (characteristic polynomial `0.1 s³ + 1.1 s² + s + 1`, Routh holds).
- **The bang-bang loop.** `Integrator()` fed by
  `Relay(lower = 0.2, upper = 0.8, off = 1.0, on = -1.0)`, which reads the
  integrator's `out`.

### Tests

- **The limited integrator.** `LimitedIntegrator(lower = -1.0, upper = 0.5)`
  fed by `Step(t_step = 1.05, before = 1.0, after = -1.0)` at `h = 1//10`. At `t = 0.7`: `q == 0.5` exactly
  and `modes(sim, "li").sat === :upper`. At `t = 2.0`: `q ≈ -0.45` and
  `:free`. At `t = 3.0`: `q == -1.0` exactly and `:lower`. The exact
  equalities are the test of the handler's state write. Linearized through
  a root input at a free state, `B` is `1`; linearized at the saturated
  state reached above, `B` is `0`, the mode-dependent Jacobian. A
  `LimitedIntegrator(x0 = 2.0, lower = -1.0, upper = 0.5)` reads `q == 0.5`
  and `:upper` right after `init!`. `LimitedIntegrator(lower = -1, upper = 0.5)`
  is a `LimitedIntegrator{Float64}` with `x0 == 0.0`, the promotion.
- **The relay.** `Integrator()` fed by
  `Step(t_step = 1.0, before = 1.0, after = -1.0)`, its `out` into
  `Relay(lower = 0.2, upper = 0.8)`, at `h = 1//10`: `out` is `0.0` at
  `t = 0.5`, `1.0` at `0.9`, `1.0` at `1.5` (inside the band, still on) and
  `0.0` at `1.9`, with `modes(sim, "r").state` agreeing at each. A relay
  whose input is `Constant(1.0)` is on right after `init!`.
- **The bang-bang loop** builds, with no `AlgebraicLoop` diagnostic, and at
  `t = 5.0` the integrator's `q` lies in `[0.2, 0.8]` widened by the
  localization tolerance.
- **The servo loop** builds; at `t = 40.0` the plant output is `1.0` within
  `1e-3`, and the limited integrator's `q` never leaves `[-2, 2]` at the
  sampled instants `t = 1, 2, 5, 10, 40`.
- **Allocation.** Both loops' phase bodies allocate nothing, and a quiet
  boundary of each does not allocate.
- **The shadow check.** `LimitedIntegrator` and `Relay` join the list.

### Routing

As stage 1: `blocks build events linearize`.

### Bookkeeping, in the same commit

- `test/imports.jl`: `LimitedIntegrator` and `Relay` join the line.
- `docs/design/implementation.md` `### src/blocks.jl`: the stage 1 bullet
  grows to the five blocks.
- `docs/design/companions/library_inventory.md`: the rows `Step{V}`,
  `Integrator{V}`, `LimitedIntegrator{V}`, `FirstOrderLag{V}` and
  `Relay{V}` flip to *shipped*, their Mechanism cells kept; the
  `LimitedIntegrator` and `Relay` rows say `V <: Real`; one new *candidate*
  row under "Continuous dynamics" and one under "Discontinuities" for
  their vector forms, mechanism "componentwise modes, four events over
  reductions masked by the mode". The status sentence at the head of
  section 3 loses its parenthesis on the first tranche. Run the docs
  battery.
- `docs/design/pending.md` needs nothing: its bullet already says
  "whatever of the inventory is unbuilt at release".

## The cold review

One fresh Opus reviewer over the two code commits: open-mind stance, probe
scripts under `/tmp`, "empty is acceptable". Dimensions:

- **Each block against its sketch here and against D-313's guidelines.**
  Port names, the state name `q`, the bound on `V`, the event order, the
  gating of each guard, the policies the events product reports.
- **The submodule's imports.** `src/blocks.jl` reaches the parent through
  its import list alone: no qualified `Redstone.` access, no `_`-prefixed
  parent name.
- **The constructors.** Each keyword form against this brief: the
  required keywords, the defaults, the promotion, and that every docstring
  shows the keyword form.
- **A mutant per block**, each on a scratch copy, each named test going
  red: `Integrator`'s derivative reading `x.q`; the lag's `τ` dropped;
  `Step{V, false}`'s guard made sign-form; the limited integrator's hit
  handler dropping its `x` write, and its hit guards gated by `:free`; the
  relay's `switch_off` guard ungated with `lower` and `upper` swapped in
  the test. A surviving mutant is a missing test.
- **Dual.** Every block builds under `(Float64, LinearizeDual)`; the
  linearizations assert the matrices, so a `Float64` pin anywhere on the
  continuous path is a red test, not a sweep count.
- **The loops as examples.** Both read as a user would write them, from
  library blocks alone; the servo loop's limits are hit or not, reported
  either way.
- **The register and the inventory.** `implementation.md`'s row names
  constructs; behaviour is in docstrings. The inventory rows flipped, the
  two vector-form candidates present.
- "Naming" over every touched file.
- The docs battery, and the gate once on the real tree.

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
count, and every deviation from this brief with its reason.
