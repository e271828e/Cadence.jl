### 8.2 The declaration inventory

This section takes the declarations of a [component](#g-component) (the unit of
modeling, leaf or assembly) one by one, and records where each schema fact gets
its authority. One continuous primitive, declared end to end, shows them
together:

```julia
struct Engine <: AbstractComponent
    ω_idle::Float64; ω_min::Float64; J::Float64      #parameters: plain struct fields
    ω_rated::Float64                                 #unread here; §14.2's shipped condition uses it
end

#state stores: declared by initial value — types derived, nothing to drift
x_init(::Engine) = (ω = 0.0,)
m_init(::Engine) = (phase = off,)                    # off | starting | running

#input contract: each entry states what may arrive; a Float64 leaf walks with the activation
u_types(::Engine) =
    (throttle = Float64, starter = Bool, fuel_available = Bool, M_load = Float64)

#output contract = the public interface (§8.3); Float64 walks, Pinned{Float64} would freeze a leaf
y_types(::Engine) = (M_shaft = Float64, P = Float64, ω = Float64)

#stage and update functions destructure their bundle by name (§5.2)
y_state(::Engine, (; x)) = (; ω = x.ω)          #exposing a state field is one line (§5.3)

function y_direct(eng::Engine, (; x, m, u))
    M_shaft = m.phase === running ? torque_law(eng, u.throttle, x.ω) : zero(x.ω)
    return (; M_shaft, P = M_shaft * x.ω)
end

x_deriv(eng::Engine, (; x, y, u)) = (ω = (y.M_shaft - u.M_load) / eng.J,)

#events: ordered and named — order matters (§5.3, §10.6); detection policy by the guard's return type (§2.1)
state_events(::Engine) = (
    start    = StateEvent(start_guard, start_handler),        # boundary-detected: Bool guard
    ignition = StateEvent(ignition_guard, ignition_handler),  # boundary-detected: Bool guard
    flameout = StateEvent(flameout_guard, flameout_handler))  # localized: sign-form guard
start_guard(::Engine, (; m, u)) =                        #manual trigger: an input (§12.5)
    m.phase === off && u.starter
start_handler(::Engine, _) = (; m = (; phase = starting))          #no `x` key: no reset
ignition_guard(eng::Engine, (; x, m, u)) =                #predicate form
    m.phase === starting && x.ω > eng.ω_idle && u.fuel_available
ignition_handler(::Engine, _) = (; m = (; phase = running))
flameout_guard(eng::Engine, (; x)) = eng.ω_min - x.ω      #continuous form: localizable
flameout_handler(::Engine, _) = (; m = (; phase = off))
```

**Every declaration of a structural fact but the allocator takes the component
alone** ([D-263][d-263]). The criterion is the convention each declaration
lives in. It is stated once here, and the blocks below refer back to it.

- A *by-value* declaration states nominal physics, and its *types*
  [walk by rule](#g-leaf-walk) (the derivation of per-activation types from a
  declared nominal type). [§7.1][s7-1] forces every state leaf to follow the
  scalar of the [activation](#g-activation) (the build's typed products at a
  given scalar type). Nothing is therefore left for a signature to record.
  Partials enter through per-invocation seeding, never through initialization
  ([D-079][d-079]).
- A *by-type* declaration walks by the same rule. Where a leaf must not follow
  the scalar, the author says so at the leaf with `Pinned` (the leaf marker
  `Pinned{P}`, which yields `P` at every activation). That is why `u_types`
  and `y_types` take the component alone too.
- A *by-allocation* declaration is the exception. It builds values the framework
  may not rebuild, so the scalar can come from nowhere but its own argument.
  `ws_init(c, T)` takes it on both [tiers](#g-tier), the continuous and the
  discrete ([D-077][d-077]). `ws_init` allocates the [workspace](#g-workspace)
  (component-declared mutable scratch), which is described below. The workspace
  arrives as the `ws` [bundle](#g-bundle) field (the `NamedTuple` of views a
  component function receives).

The criterion, not uniformity, is the rule. A `T` in a signature means the
framework could not have supplied it.

#### The stores

**`x_init` on the continuous tier, `s_init` on the discrete, and `m_init`
declare by initial value** ([D-033][d-033]). The type is derived from the value.
**The value is a `NamedTuple`, one named field per leaf**, and no other form is
admitted ([D-247][d-247]). A bare leaf such as `x_init(::C) = 0.0` or
`s_init(::C) = zeros(SVector{3})` is refused. The structure step (the build's
first step, declaration reading only) reports it as `StoreNotNamedTuple`, and
the message spells the wrap ([§9.1][s9-1], [Appendix C][sC], [D-247][d-247]).

The [store](#g-store) (the model's memory, declared by initial value) names each leaf
because every service reaches a leaf by its field name. A [condition](#g-condition), the
path-addressed sparse overlay that sets a build's state, merges on it ([§14.1][s14-1]).
Readers and the trace spell it ([§14.4][s14-4]). The name a one-state component is asked
for is the name every service then uses.

**Every leaf declares exactly one of `x_init` and `s_init`**, and a stateless
leaf declares it empty ([D-263][d-263]):

```julia
x_init(::Gain) = (;)
s_init(::Sampler) = (;)
```

The store is the tier marker. It is therefore mandatory even when empty, exactly
as `inner_connections` is mandatory even when empty because it is the class
marker ([§8.5][s8-5], [D-263][d-263]). A primitive declaring neither store is `TierUnreadable`,
and its message spells the empty form. An empty store owes no update law, since
it has nothing to integrate or advance. It puts no letter in the bundle ([§5.2][s5-2]).

A continuous component's state may be empty ([§3.1][s3-1]), so a stateless
continuous leaf is honestly a continuous leaf with zero state fields. Spelling
that out puts every leaf's tier on the page in one place, stateful or not, with
no tier by omission. It also closes a trap. A store lost to a local scope or to
a forgotten import ([§8.1][s8-1]) fails loud as a leaf declaring no store,
where an optional marker would have dropped silently.

Because the type is derived from the value, there is no second artifact to drift
and no separate type declaration to check. The workspace is the exception to
that convention. It is declared *by allocation*, as `ws_init(::C, ::Type{T})` on
both tiers ([D-077][d-077], [D-263][d-263]). The method itself is the allocator. A
workspace earns the exception because it is not memory and none of the by-value
arguments below cover it ([§7.3][s7-3]). `ws_init` alone declares by allocation,
and nothing downstream derives from the type of what it returns.

This is the boundary of legitimate derivation. Deriving from another
declaration is sound, and deriving from evaluated user code is not. Stores
declared by type, with synthesized initial values, were rejected
([D-073][d-073]).

The declared values are the base layer of the condition substrate. The
overlays ([§14.1][s14-1]) fall back to the declared values leaf by leaf, and
the compiled store writers bake `merge(defaults, overlay)`. There must
therefore be an authored value under every leaf.

The asymmetry against `u_types`/`y_types` is one of kind, not style.
[Contracts](#g-contract) (a component's declared interfaces) describe table [cells](#g-cell) (the
signal table's typed entries). There is one cell per output [port](#g-port) (one
declared input or output). Cells are recomputed from scratch every [sweep](#g-sweep)
(one pass through the execution order), so contracts need only types. `x_init`,
`s_init` and `m_init` describe stores, which must have contents before the first
sweep can run.
