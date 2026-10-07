# Brief: increment 62, the limited integrator's second departure policy

One code stage and the increment 61 reviewer resumed over the delta, a
fixer if needed. The docs arc is landed: the companion
`docs/design/companions/limited_integrator_variants.md` records the defect,
the variants weighed and the decision, in commit bcbdd15, the tip at launch.
Line numbers below are its. Find passages in `implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **`LimitedIntegrator` ships two detection policies for its departures**,
  selected by a type parameter in `Step`'s shape: `LimitedIntegrator{V, L}`
  with `L::Bool`, and the keyword `localized = true` on the constructor
  (companion, section 6). Arrivals are localized in both: the arrival kink
  is first-order and the exact clamp depends on the hit handler's write.
- **The two forms differ in one method per leave guard.** Localized: the
  strict-gated sign form as shipped. Boundary-detected: the `Bool`
  predicate `m.saturation === :upper && u.in < 0` and its mirror, strict by
  construction, so the exact-zero corner needs no gate trick (companion,
  section 4). Everything else is shared: the struct, `x_init`, `m_init`, the
  derivative, the hit guards and handlers, `leave_handler`, `state_events`.
- **The policy is a type parameter** because the build reads it off the
  guard's probed return type (§10.4, D-179), exactly as for `Step`.
- **The accuracy price of the cheap form** is one offset of at most
  `a h² / 2` per departure, `a` the input's slope at its zero crossing
  (companion, section 5). The docstring states it.

## Out of scope

- The computed-clamp variants (companion, section 4). Not built.
- A policy parameter on `Relay`. Its departures are its arrivals.
- Any spec or log edit. The companion is the record.

## Reading, in order

- `docs/design/companions/limited_integrator_variants.md` whole.
- `docs/design/spec.md` §2.1, lines 229 to 273; §10.4, lines 5205 to 5268;
  §10.6, lines 5864 to 5970. Never read the spec whole.
- `docs/design/decisions.md` D-179.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the row `### src/blocks.jl`; "Authoring
  caveats", its first three bullets; "Naming"; "Running the suite". Never
  restate either in a commit or a comment.
- `src/blocks.jl`: `Step` whole, the model for a policy parameter and its
  two guard methods, then `LimitedIntegrator` whole.
- `test/test_blocks.jl`: `limited_model`, `zero_input_model`, `servo_loop`,
  the two limited-integrator testsets, the two step testsets that read the
  policy off `step_events(...).policies`, and the loops' allocation testset.

## The stage

### The shape

```julia
struct LimitedIntegrator{V <: Real, L} <: AbstractComponent
    x0::V
    lower::V
    upper::V
end
function LimitedIntegrator(; lower, upper, x0 = zero(lower), localized = true)
    x0, lower, upper = float.(promote(x0, lower, upper))
    LimitedIntegrator{typeof(x0), localized}(x0, lower, upper)
end

leave_upper_guard(c::LimitedIntegrator{V, true}, (; m, u)) where {V} =
    m.saturation === :upper && u.in < 0 ? -u.in : -one(u.in)
leave_lower_guard(c::LimitedIntegrator{V, true}, (; m, u)) where {V} =
    m.saturation === :lower && u.in > 0 ? u.in : -one(u.in)
leave_upper_guard(c::LimitedIntegrator{V, false}, (; m, u)) where {V} =
    m.saturation === :upper && u.in < 0
leave_lower_guard(c::LimitedIntegrator{V, false}, (; m, u)) where {V} =
    m.saturation === :lower && u.in > 0
```

Every other method stays on the unparametrized `LimitedIntegrator`. The
existing site comment on the strict gate stays with the localized methods.
The docstring gains a paragraph on `localized`, in `Step`'s register:
localized, the departure ends the step at the input's zero crossing;
boundary-detected, it fires at the end of the step in which `in` first
pointed back into the range, so `q` is held on the limit for the rest of
that step and carries an offset of at most `a h² / 2` from then on. It
points to the companion by file name for the reasoning.

### Tests

In `test/test_blocks.jl`, each red under the mutants the review runs.

- **The trajectory at the cheap policy.** `limited_model` takes the policy as
  an argument. At `localized = false`, with the input stepping to `-1` at
  `1.05` off the `h = 1//10` grid, the departure fires at the boundary
  `1.1`, so `q == 0.5` and `:upper` at `t = 1.0`, `q == 0.5` and `:free` at
  `t = 1.1` (freed at the boundary, not yet moved), and `q ≈ -0.40` at
  `t = 2.0` within `1e-12` (the input is constant after its step, so no
  slope error applies), against `-0.45` at the localized policy. The
  arrival at `0.5` is still exact in both.
- **The policies product.** The build's events product reports
  `leave_upper` and `leave_lower` as `:localized` at the default and
  `:boundary` at `localized = false`, with `hit_upper` and `hit_lower`
  `:localized` in both. Read it as the step tests do.
- **The exact-zero corner in both policies.** The existing testset loops over
  both.
- **The offset bound.** A ramp-through-zero input: `Integrator(x0 = 1.05)`
  fed by `Constant(-1.0)`, so its output is `1.05 - t`, crossing zero at
  `t = 1.05`, off the `h = 1//10` grid at `θ = 0.5`, with slope `a = 1`.
  It feeds `LimitedIntegrator(lower = -2.0, upper = 0.4)` from `x0 = 0.0`,
  once per policy. The block's free trajectory is `1.05 t - t² / 2`, which
  reaches `0.4` at `t = 0.5`, so the arrival is exact and early in both.
  Localized, the departure lands at `1.05` and `q(3) = 0.4 - 1.95² / 2 =
  -1.50125`. Boundary-detected, the mode is held to `1.1` and
  `q(3) = 0.4 + ∫₁.₁³ (1.05 - τ) dτ = -1.5`. Assert at `t = 3.0` that the
  localized block reads `-1.50125` within the bracket width, and that the
  boundary-detected block reads `-1.5` within `1e-12` (constant input slope,
  RK4 exact on the quadratic), so their difference is `0.00125 =
  a h² (1 - θ)² / 2`, under the bound `a h² / 2 = 0.005` the docstring
  states. Confirm the numbers in a probe before writing the assertions.
- **The servo loop** runs once more at `localized = false` and settles to
  `1.0` at `t = 40` within `1e-3`; the mode samples are not re-asserted,
  since the departure moves by one step.
- **Allocation.** The loops' allocation testset covers the servo loop at both
  policies, including the quiet boundary.
- **The constructor.** `LimitedIntegrator(lower = -1, upper = 1, localized = false)
  isa LimitedIntegrator{Float64, false}`, and the integer-keyword testset's
  assertion still holds at the default.
- **The shadow check** gains the block at `localized = false`.

### Routing

`src/blocks.jl` is the `blocks` row; the change touches guards and their
policies, so run `blocks build events localization linearize` under the
flags of "Running the suite", in the foreground, 600 s per invocation.

### Bookkeeping, in the same commit

- `docs/design/implementation.md` `### src/blocks.jl`: the bullet names the
  two policies of `Step` and `LimitedIntegrator`; run the docs battery.
- `docs/design/companions/library_inventory.md`: the `LimitedIntegrator` row's
  mechanism cell adds "departures localized or boundary-detected, by `L`".
  Linkified spelling; run the battery, `linkify` a no-op on rerun.

## The review

The increment 61 reviewer, resumed with its context, over the one commit:

- Each guard method against the companion's section 4 and 6, and the
  policies the events product reports.
- Mutants on a scratch copy: the boundary-detected leave guards made
  non-strict (`<=`), which the exact-zero testset must catch at
  `localized = false`; the cheap trajectory test against the localized
  guards; the offset test against a departure that is localized.
- The companion's numbers against the tree: the offset bound, the exact
  trajectory, the trial counts if cheaply re-measured.
- "Naming" over the touched files, the docs battery, and the gate once on
  the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name; `git add -A` is forbidden.
Re-read a file before a scripted edit. Report: the commit hash, the files
touched, the routed subset's result with the assertion count, the probe's
numbers for the offset test, and every deviation from this brief with its
reason.
