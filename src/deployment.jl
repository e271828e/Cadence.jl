# Deployment binding (§9.1, §9.2, D-254): the artifact the grid parameters fix,
# standing between the `Build` and the `Simulation`. Everything here post-dates
# the build's three steps and precedes materialization: it exists per
# `Deployment`, not per `Build` and not per scalar type. Grid arithmetic is
# exact — GCD over `Rational{Int}` — and floats are refused at the door.
#
# The file sits after `build.jl` and `readers.jl` because the binding consumes the
# `Build`, and before `trace.jl` because `TraceHeader.deployment` is a typed field.
# The `AbstractStepper` check at the constructor and the `RK4` default resolve at
# call time, so `stepper.jl` may come later.

# Records and returns `nothing` on its two refusing arms; the call's list carries it.
_exact(name::Symbol, value::Rational{Int}, diags::Vector{Diagnostic}) = value
_exact(name::Symbol, value::Integer, diags::Vector{Diagnostic}) = Rational{Int}(value)
_exact(name::Symbol, value::Period, diags::Vector{Diagnostic}) = value.T
_exact(name::Symbol, value::AbstractFloat, diags::Vector{Diagnostic}) =
    (push!(diags, DeploymentInvalid(parameter = name, reason = :inexact, value = value));
     nothing)
_exact(name::Symbol, value, diags::Vector{Diagnostic}) =
    (push!(diags, DeploymentInvalid(parameter = name, reason = :not_a_quantity,
                                    value = typeof(value))); nothing)

_as_int(value::Rational) = denominator(value) == 1 ? Int(numerator(value)) : nothing

# --- the grid attribution (§9.2, D-187) -----------------------------------------

# Trial division: the integers factored here are grid denominators, lcms of a
# handful of declared ones, so no prime table is worth a dependency.
function _prime_powers(integer::Int)
    powers = Tuple{Int,Int}[]
    cofactor, divisor = integer, 2
    while divisor * divisor ≤ cofactor
        if cofactor % divisor == 0
            power = 0
            while cofactor % divisor == 0; cofactor ÷= divisor; power += 1 end
            push!(powers, (divisor, power))
        end
        divisor += 1
    end
    cofactor > 1 && push!(powers, (cofactor, 1))
    powers
end

"""
The grid attribution D-187 asks for (§9.2), a pure function of the structure's
anchors: the constraint pool — every anchor's period and every nonzero offset,
in anchor order, periods first — with each entry's leave-one-out refinement
factor `r_p = gcd(pool ∖ p)/gcd(pool)`, the prime attribution of `gcd(pool)`'s
denominator, and, for a driving offset, the nearest offsets the rest of the pool
already supports. One report per constructor call, computed ahead of the
`Δt_base` branch: the refusal path's suggestion, the derivation path's line and
the `Deployment` itself read the same substrate.
"""
function _grid_report(anchors::Vector{Anchor})
    entry_kinds, entry_values, anchor_indices = Symbol[], Rational{Int}[], Int[]
    for (k, anchor) in enumerate(anchors)
        push!(entry_kinds, :period); push!(entry_values, anchor.T); push!(anchor_indices, k)
    end
    for (k, anchor) in enumerate(anchors)
        anchor.τ == 0 && continue
        push!(entry_kinds, :offset); push!(entry_values, anchor.τ); push!(anchor_indices, k)
    end
    isempty(entry_values) &&
        return GridReport(GridEntry[], nothing,
                          Vector{@NamedTuple{prime::Int, power::Int, suppliers::Vector{Int}}}())
    admissible = reduce(gcd, entry_values)
    pool = GridEntry[]
    for i in eachindex(entry_values)
        # The empty reduction has no value, so a singleton pool gives factor 1 by
        # convention: with nothing else declared, nothing is refined.
        partial = length(entry_values) == 1 ? admissible :
            reduce(gcd, (entry_values[j] for j in eachindex(entry_values) if j != i))
        factor = _as_int(partial / admissible)
        factor === nothing && throw(InternalInvariant(
            "leave-one-out factor $(partial / admissible) is not an integer: " *
            "gcd(pool) divides every partial gcd"))
        alternatives = Rational{Int}[]
        if entry_kinds[i] === :offset && factor > 1
            # The grid the rest of the pool supports, and τ's neighbours on it. The
            # fold requires 0 ≤ τ < T (`assembly.jl`), so an upper neighbour reaching
            # the anchor's period is no offset; 0 stays, declaring none being a repair.
            τ, T = entry_values[i], anchors[anchor_indices[i]].T
            lower = floor(Int, τ / partial) * partial
            push!(alternatives, lower)
            lower + partial < T && push!(alternatives, lower + partial)
        end
        anchor = anchors[anchor_indices[i]]
        push!(pool, GridEntry(entry_kinds[i], entry_values[i], anchor.scope, anchor.key,
                              factor, alternatives))
    end
    primes = [(prime = prime, power = power,
               suppliers = [i for i in eachindex(entry_values)
                            if denominator(entry_values[i]) % prime^power == 0])
              for (prime, power) in _prime_powers(denominator(admissible))]
    GridReport(pool, admissible, primes)
end

# --- the typed schedule (§9.2, §10.5, D-254) ------------------------------------

"""
One discrete component's row of the schedule (§9.2): its `(D, Φ, Δt)` with the
anchor it resolved against (0 is the base grid `A₀`) and its `rates`, the
`sample_times` links met on the way down.
"""
struct ScheduleEntry
    path::String
    anchor::Int
    D::Int
    Φ::Int
    Δt::Float64
    rates::Vector{RateLink}
end

# `rates` is a vector, so the `===` fallback would make two rows of two
# builds of one model unequal. Value equality is what §12.7's header check
# needs, so both are spelled field-wise here (`hash` alongside, consistently).
Base.:(==)(a::ScheduleEntry, b::ScheduleEntry) =
    a.path == b.path && a.anchor == b.anchor && a.D == b.D && a.Φ == b.Φ &&
    a.Δt == b.Δt && a.rates == b.rates
Base.hash(entry::ScheduleEntry, seed::UInt) =
    hash(entry.rates, hash(entry.Δt, hash(entry.Φ, hash(entry.D,
        hash(entry.anchor, hash(entry.path, seed))))))

"""
One rate scope's row (§9.2, §10.5): the assembly an explicit `sample_times` key
opened, resolved to its own `(Dₛ, Φₛ)` by the same multiply-add its members use.
"""
struct ScopeEntry
    path::String
    key::Symbol
    anchor::Int
    D::Int
    Φ::Int
end

"""
The typed schedule (§9.2, §10.5, D-254): one row per discrete component in walk
order, and the rate-scope rows. The single source of truth for `Δt` (§10.5). The
per-component `(D, Φ, Δt)` the executor compiles over are derived from the rows
at `compile`, never stored beside them (D-261).
"""
struct Schedule
    rows::Vector{ScheduleEntry}
    scopes::Vector{ScopeEntry}
end

Base.:(==)(a::Schedule, b::Schedule) = a.rows == b.rows && a.scopes == b.scopes
Base.hash(schedule::Schedule, seed::UInt) = hash(schedule.scopes, hash(schedule.rows, seed))

# The per-component `(D, Φ, Δt)` the executor compiles over, derived from the
# rows by path at `compile` (§9.2, D-261); a component with no row is the
# continuous tier's `(1, 0, 0.0)`.
function _gates(schedule::Schedule, structure::Structure)
    row_by_path = Dict(row.path => row for row in schedule.rows)
    D_c, Φ_c, Δt_c = Int[], Int[], Float64[]
    for entry in structure.components
        row = get(row_by_path, entry.path, nothing)
        push!(D_c, row === nothing ? 1 : row.D)
        push!(Φ_c, row === nothing ? 0 : row.Φ)
        push!(Δt_c, row === nothing ? 0.0 : row.Δt)
    end
    D_c, Φ_c, Δt_c
end

"""
Deployment binding (§9.1): `Δt_base` from one of three cross-validated sources —
the explicit keyword, the `N_base·h` product (default `N_base = 1`), or GCD derivation
over the constraint pool, requested as `Δt_base = :derive` and permitted only
with every discrete component anchored. Resolution is one exact division pair
per anchor and one multiply-add per component. Returns the bound grid: `h`,
`N_base`, `Δt_base`, the `Schedule` (§9.2's typed artifact), the grid
attribution and whether the derivation path produced the value.

The pass records into the call's list and returns `nothing` when a premise
fails; the caller owns the one throw per `Deployment` call (§9.1, D-229). `h`,
`N_base` and `Δt_base` are three independent premises, each checked and recorded on
its own; the harmonic resolution and the anchor loop read all three, so they
run only when all three are sound (D-229).
"""
function bind_schedule(build::Build, h, N_base, Δt_base, diags::Vector{Diagnostic})
    count_on_entry = length(diags)
    h === nothing && push!(diags, DeploymentInvalid(parameter = :h, reason = :missing))
    h_r = h === nothing ? nothing : _exact(:h, h, diags)
    if h_r !== nothing && !(h_r > 0)
        push!(diags, DeploymentInvalid(parameter = :h, reason = :range, value = h_r))
        h_r = nothing
    end
    N_base_sound = N_base === nothing || (N_base isa Integer && N_base ≥ 1)
    N_base_sound || push!(diags, DeploymentInvalid(parameter = :N_base, reason = :range,
                                                   value = N_base))

    structure = build.structure
    anchors = structure.anchors
    # The attribution over the constraint pool — every anchor's period and every
    # nonzero offset (§9.1) — computed once, ahead of the branch, and handed to
    # every refusal that names the grid as well as to the artifact (§9.2, D-187).
    grid = _grid_report(anchors)

    # The Δt_base branch is its own premise: derivation reads the tiers and the
    # anchors, the explicit keyword reads only itself, and only the default path
    # reads `h` and `N_base` — which is why it alone is skipped when either is unsound.
    Δt_r, derived = nothing, false
    if Δt_base === :derive
        unanchored = [entry.path for entry in structure.components
                      if entry.tier === DISCRETE && entry.timing.anchor == 0]
        if !isempty(unanchored)
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :unanchored,
                                           paths = unanchored, grid = grid))
        elseif grid.admissible === nothing
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :no_constraint))
        else
            Δt_r, derived = grid.admissible, true    # the coarsest admissible value
        end
    elseif Δt_base !== nothing
        Δt_r = _exact(:Δt_base, Δt_base, diags)
    elseif h_r !== nothing && N_base_sound
        Δt_r = something(N_base, 1) * h_r                 # the default path (§9.1)
    end

    # The harmonic checks and the anchor loop read `h`, `N_base` and `Δt_base` together,
    # so they run only on a sound value of each (D-229).
    (length(diags) == count_on_entry && h_r !== nothing && Δt_r !== nothing) ||
        return nothing

    N_base_resolved = _as_int(Δt_r / h_r)
    if N_base_resolved === nothing || N_base_resolved < 1
        push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :not_harmonic,
                                       value = Δt_r, related = h_r))
        return nothing
    end
    if !(N_base === nothing || N_base == N_base_resolved)
        push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :disagrees_with_n,
                                       value = Δt_r, related = N_base,
                                       quotient = N_base_resolved))
        return nothing
    end

    # Per anchor, one exact division pair; anchor 0 is the base grid itself. The
    # loop collects into the call's list (§13.1): every anchor the chosen base
    # grid cannot express is named, so the coarsest admissible value is chosen
    # against the whole list.
    Dk, Φk = [1], [0]
    for anchor in anchors
        D = _as_int(anchor.T / Δt_r)
        D === nothing &&
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :anchor_period,
                                          value = anchor.T, related = Δt_r,
                                          scope = anchor.scope, key = anchor.key, grid = grid))
        Φ = _as_int(anchor.τ / Δt_r)
        Φ === nothing &&
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :anchor_offset,
                                          value = anchor.τ, related = Δt_r,
                                          scope = anchor.scope, key = anchor.key, grid = grid))
        push!(Dk, something(D, 1)); push!(Φk, something(Φ, 0))
    end
    length(diags) == count_on_entry || return nothing

    # Per component, one multiply-add; the canonical residue 0 ≤ Φ < D survives
    # composition (§10.5), which is what the gate's truncated rem relies on. The
    # rate scopes resolve by the same law, off the timing the fold left them.
    Δtb = Float64(Δt_r)
    timing_gates(timing::Timing) = (timing.m * Dk[timing.anchor + 1],
                                    Φk[timing.anchor + 1] +
                                    timing.c * Dk[timing.anchor + 1])
    rows = ScheduleEntry[]
    for entry in structure.components
        entry.tier === DISCRETE || continue
        D, Φ = timing_gates(entry.timing)
        # the rates vector itself: the structure is immutable, so no copy
        push!(rows, ScheduleEntry(entry.path, entry.timing.anchor, D, Φ, D * Δtb, entry.rates))
    end
    scopes = [ScopeEntry(scope.path, scope.key, scope.timing.anchor,
                         timing_gates(scope.timing)...)
              for scope in structure.scopes]
    (h = Float64(h_r), N_base = N_base_resolved, Δt_base = Δtb,
     schedule = Schedule(rows, scopes), grid = grid, derived = derived)
end

# --- the artifact (§9.1, §9.2, D-254) -------------------------------------------

"""
    Deployment(build::Build; h, N_base = nothing, Δt_base = nothing, algorithm = RK4,
               firing_budget = 4, localization_tol = 1e-6, localization_budget = 8)

The artifact the grid parameters fix (§9.1, §9.2, D-254): the build plus the
grid parameters, the algorithm and the three event parameters, scalar-free,
carrying the `Schedule` the constructor built, the grid attribution of §9.2 and
its own `warnings`.
`Simulation` materializes it at a scalar type, and one deployment backs many
(§9.2). Two deployments compare as values, which is what replay's header check
reads (§12.7).

`Δt_base` has exactly one of three cross-validated sources (§9.1): explicit (a
`Rational` or `Period`/`Hz` value), the `N_base·h` product (the default path),
or GCD derivation over the anchors' constraint pool, requested as
`Δt_base = :derive` and permitted only with every discrete component anchored.
`h` is required — a domain rate is not a framework default.

`algorithm` selects the integration backend across the stepper seam (§10.2): a
stepper type — `RK4`, the default, or `Heun` — selected here and materialized
against the flat buffer at `Simulation` construction (D-227). The algorithm is
trajectory-determining and grid-independent, exactly like the keywords below;
nothing outside the backend's own struct knows which one ran.

`firing_budget` is §10.6's: how many times each declared event may fire at one
boundary, an integer ≥ 1 defaulting to 4 — a legitimate re-enable is one or two
firings deep, a toggling FSM pair chatters without bound, and 4 separates them
without ever binding on a healthy model.

`localization_tol` and `localization_budget` are §10.4's: the relative bracket
width at which root-finding stops (positive, defaulting to 1e-6 — the event
time can only ever be as accurate as the `O(h⁴)` interpolant, so anything
tighter buys nothing while every trial evaluation costs a full sweep), and how
many localizations one frame admits (an integer ≥ 1 defaulting to 8 — a
legitimate multi-event frame needs three or four, chattering needs tens). All
three are trajectory-determining and grid-independent: they stand beside `h`
and `N_base`, validated here with their siblings, and enter none of the grid
arithmetic.
"""
struct Deployment
    build::Build
    h::Float64                    # the continuous step (§10.2)
    N_base::Int                   # steps per base tick: Δt_base = N_base·h (§10.5)
    Δt_base::Float64
    algorithm::Type               # <: AbstractStepper, materialized at Simulation construction (D-227)
    firing_budget::Int            # per-event firings per boundary (§10.6)
    localization_tol::Float64     # relative bracket-width stop (§10.4)
    localization_budget::Int      # t* boundaries permitted per frame (§10.4)
    schedule::Schedule            # the bound per-component tick table (§9.2)
    grid::GridReport              # the attribution over the constraint pool (§9.2, D-187)
    warnings::Vector{Diagnostic}  # the warnings the constructor raised (§9.1, D-250)
end

function Deployment(build::Build; h = nothing, N_base = nothing, Δt_base = nothing,
                    algorithm = RK4, firing_budget = 4, localization_tol = 1e-6,
                    localization_budget = 8)
    # The event parameters and the algorithm validate on their own terms, ahead
    # of the grid; all of it lands in one list and one throw (§9.1, D-229).
    diags, raised = Diagnostic[], Diagnostic[]
    algorithm isa Type && algorithm <: AbstractStepper ||
        push!(diags, DeploymentInvalid(parameter = :algorithm, reason = :range, value = algorithm))
    firing_budget isa Integer && firing_budget ≥ 1 ||
        push!(diags, DeploymentInvalid(parameter = :firing_budget, reason = :range, value = firing_budget))
    localization_tol isa Real && localization_tol > 0 ||
        push!(diags, DeploymentInvalid(parameter = :localization_tol, reason = :range, value = localization_tol))
    localization_budget isa Integer && localization_budget ≥ 1 ||
        push!(diags, DeploymentInvalid(parameter = :localization_budget, reason = :range, value = localization_budget))
    bound = bind_schedule(build, h, N_base, Δt_base, diags)
    # One throw per call (§9.1, D-229), carrying the warnings raised so far: the
    # artifact that would have held them never returns (D-250).
    isempty(diags) || throw(DiagnosticError(diags, raised))
    # Derivation is the one place refinement happens silently (§9.2, D-187), so it
    # always prints the derived value over the grid block, both attribution forms;
    # a pool where nothing refines says so on the first line. The line is
    # presentation, never a home (§9.1, D-250).
    if bound.derived
        grid = bound.grid
        @info "Δt_base derived as $(grid.admissible) s" *
              (all(e.factor == 1 for e in grid.pool) ? ", no entry refines another" : "") *
              " (§9.2)" * _grid_block(grid)
        # The advisory rides the same path, when the grid is finer than the fastest
        # declared work. `utilization == 1` is no information. No user body runs
        # inside this constructor, so the warning goes straight onto its own list,
        # not through `_warn!`'s channel.
        rows = bound.schedule.rows
        utilization = isempty(rows) ? 1 : minimum(row.D for row in rows)
        utilization > 1 && push!(raised,
            GridUtilization(Δt_base = grid.admissible, utilization = utilization,
                            fastest =
                                rows[findfirst(row -> row.D == utilization, rows)].path,
                            grid = grid))
    end
    deployment = Deployment(build, bound.h, bound.N_base, bound.Δt_base, algorithm,
                            Int(firing_budget), Float64(localization_tol),
                            Int(localization_budget), bound.schedule, bound.grid, raised)
    # The completed constructor carries the record, and logs each warning once at
    # return through the standard backend (Appendix C's `logged`), as `build` does.
    for warning in raised
        @warn logline(warning)
    end
    deployment
end

# §12.7's header check is the consumer, and a what-if replay re-drives a
# recording against a *modified model of the same structure*, so **the build is
# not compared**: comparing it would refuse what the spec admits. `grid` and
# `warnings` are not compared either — both are functions of the rest.
Base.:(==)(a::Deployment, b::Deployment) =
    a.h == b.h && a.N_base == b.N_base && a.Δt_base == b.Δt_base &&
    a.algorithm === b.algorithm && a.firing_budget == b.firing_budget &&
    a.localization_tol == b.localization_tol &&
    a.localization_budget == b.localization_budget && a.schedule == b.schedule
Base.hash(deployment::Deployment, seed::UInt) =
    hash(deployment.schedule, hash(deployment.localization_budget,
        hash(deployment.localization_tol, hash(deployment.firing_budget,
            hash(deployment.algorithm, hash(deployment.Δt_base,
                hash(deployment.N_base, hash(deployment.h, seed))))))))

"""
    warnings(deployment::Deployment) → Vector{Diagnostic}

The warnings the `Deployment` constructor raised (§9.2, D-250). The constructor
produces an artifact, so its warnings live on it; the log line each one got at
return is presentation, never the home.
"""
warnings(deployment::Deployment) = deployment.warnings
