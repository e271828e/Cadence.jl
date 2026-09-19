# Deployment binding (§9.1, §9.2, D-254): the artifact the grid parameters fix,
# standing between the `Build` and the `Simulation`. Everything here post-dates
# the build's three steps and precedes materialization: it exists per
# `Deployment`, not per `Build` and not per scalar type. Grid arithmetic is
# exact — GCD over `Rational{Int}` — and floats are refused at the door.
#
# The file sits after `stepper.jl` because the constructor checks
# `algorithm <: AbstractStepper`, and before `sim.jl` because the materialization
# consumes what is built here.

# Records and returns `nothing` on its two refusing arms; the call's list carries it.
_exact(name::Symbol, v::Rational{Int}, diags::Vector{Diagnostic}) = v
_exact(name::Symbol, v::Integer, diags::Vector{Diagnostic}) = Rational{Int}(v)
_exact(name::Symbol, v::Period, diags::Vector{Diagnostic}) = v.T
_exact(name::Symbol, v::AbstractFloat, diags::Vector{Diagnostic}) =
    (push!(diags, DeploymentInvalid(parameter = name, reason = :inexact, value = v)); nothing)
_exact(name::Symbol, v, diags::Vector{Diagnostic}) =
    (push!(diags, DeploymentInvalid(parameter = name, reason = :not_a_quantity,
                                    value = typeof(v))); nothing)

_as_int(r::Rational) = denominator(r) == 1 ? Int(numerator(r)) : nothing

# --- the typed schedule (§9.2, §10.5, D-254) ------------------------------------

"""
One discrete component's row of the schedule (§9.2): its `(D, Φ, Δt)` with the
anchor it resolved against (0 is the base grid `A₀`) and its declaration
provenance, the `sample_times` links met on the way down.
"""
struct ScheduleRow
    path::String
    anchor::Int
    D::Int
    Φ::Int
    Δt::Float64
    provenance::Vector{RateLink}
end

# `provenance` is a vector, so the `===` fallback would make two rows of two
# builds of one model unequal. Value equality is what §12.7's header check
# needs, so both are spelled field-wise here (`hash` alongside, consistently).
Base.:(==)(a::ScheduleRow, b::ScheduleRow) =
    a.path == b.path && a.anchor == b.anchor && a.D == b.D && a.Φ == b.Φ &&
    a.Δt == b.Δt && a.provenance == b.provenance
Base.hash(r::ScheduleRow, h::UInt) =
    hash(r.provenance, hash(r.Δt, hash(r.Φ, hash(r.D, hash(r.anchor, hash(r.path, h))))))

"""
One rate scope's row (§9.2, §10.5): the assembly an explicit `sample_times` key
opened, resolved to its own `(Dₛ, Φₛ)` by the same multiply-add its members use.
"""
struct ScopeRow
    path::String
    key::Symbol
    anchor::Int
    D::Int
    Φ::Int
end

"""
The typed schedule (§9.2, §10.5, D-254): one row per discrete component in walk
order, the rate-scope rows, and the per-component `D`, `Φ` and `Δt` vectors the
executor compiles over, every tier included (a continuous component holds
`(1, 0, 0.0)`). The single source of truth for `Δt` (§10.5).
"""
struct Schedule
    rows::Vector{ScheduleRow}
    scopes::Vector{ScopeRow}
    D::Vector{Int}
    Φ::Vector{Int}
    Δt::Vector{Float64}
end

Base.:(==)(a::Schedule, b::Schedule) =
    a.rows == b.rows && a.scopes == b.scopes && a.D == b.D && a.Φ == b.Φ && a.Δt == b.Δt
Base.hash(s::Schedule, h::UInt) =
    hash(s.Δt, hash(s.Φ, hash(s.D, hash(s.scopes, hash(s.rows, h)))))

"""
Deployment binding (§9.1): `Δt_base` from one of three cross-validated sources —
the explicit keyword, the `N_base·h` product (default `N_base = 1`), or GCD derivation
over the constraint pool, requested as `Δt_base = :derive` and permitted only
with every discrete component anchored. Resolution is one exact division pair
per anchor and one multiply-add per component. Returns the bound grid: `h`,
`N_base`, `Δt_base` and the `Schedule` (§9.2's typed artifact).

The pass records into the call's list and returns `nothing` when a premise
fails; the caller owns the one throw per `Deployment` call (§9.1, D-229). `h`,
`N_base` and `Δt_base` are three independent premises, each checked and recorded on
its own; the harmonic resolution and the anchor loop read all three, so they
run only when all three are sound (D-229).
"""
function bind_schedule(b::Build, h, N_base, Δt_base, diags::Vector{Diagnostic})
    k0 = length(diags)
    h === nothing && push!(diags, DeploymentInvalid(parameter = :h, reason = :missing))
    h_r = h === nothing ? nothing : _exact(:h, h, diags)
    if h_r !== nothing && !(h_r > 0)
        push!(diags, DeploymentInvalid(parameter = :h, reason = :range, value = h_r))
        h_r = nothing
    end
    n_ok = N_base === nothing || (N_base isa Integer && N_base ≥ 1)
    n_ok || push!(diags, DeploymentInvalid(parameter = :N_base, reason = :range, value = N_base))

    anchors, prov, triples = b.structure.anchors, b.structure.aprov, b.structure.triples
    # The constraint pool: every anchor's period and every nonzero offset (§9.1).
    pool = vcat([Tk for (Tk, _) in anchors], [τk for (_, τk) in anchors if τk != 0])

    # The Δt_base branch is its own premise: derivation reads the tiers and the
    # anchors, the explicit keyword reads only itself, and only the default path
    # reads `h` and `N_base` — which is why it alone is skipped when either is unsound.
    Δt_r = nothing
    if Δt_base === :derive
        unanchored = [b.structure.paths[ci] for ci in eachindex(b.structure.tiers)
                      if b.structure.tiers[ci] === DISCRETE && triples[ci][1] == 0]
        if !isempty(unanchored)
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :unanchored,
                                           paths = unanchored))
        elseif isempty(pool)
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :no_constraint))
        else
            Δt_r = reduce(gcd, pool)                 # the coarsest admissible value
        end
    elseif Δt_base !== nothing
        Δt_r = _exact(:Δt_base, Δt_base, diags)
    elseif h_r !== nothing && n_ok
        Δt_r = something(N_base, 1) * h_r                 # the default path (§15.4)
    end

    # The harmonic checks and the anchor loop read `h`, `N_base` and `Δt_base` together,
    # so they run only on a sound value of each (D-229).
    (length(diags) == k0 && h_r !== nothing && Δt_r !== nothing) || return nothing

    n_i = _as_int(Δt_r / h_r)
    if n_i === nothing || n_i < 1
        push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :not_harmonic,
                                       value = Δt_r, related = h_r))
        return nothing
    end
    if !(N_base === nothing || N_base == n_i)
        push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :disagrees_with_n,
                                       value = Δt_r, related = N_base, quotient = n_i))
        return nothing
    end

    # Per anchor, one exact division pair; anchor 0 is the base grid itself. The
    # loop collects into the call's list (§13.1): every anchor the chosen base
    # grid cannot express is named, so the coarsest admissible value is chosen
    # against the whole list.
    adm = isempty(pool) ? nothing : reduce(gcd, pool)
    Dk, Φk = [1], [0]
    for (k, (Tk, τk)) in enumerate(anchors)
        D = _as_int(Tk / Δt_r)
        D === nothing &&
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :anchor_period,
                                          value = Tk, related = Δt_r, provenance = prov[k],
                                          admissible = adm))
        Φ = _as_int(τk / Δt_r)
        Φ === nothing &&
            push!(diags, DeploymentInvalid(parameter = :Δt_base, reason = :anchor_offset,
                                          value = τk, related = Δt_r, provenance = prov[k],
                                          admissible = adm))
        push!(Dk, something(D, 1)); push!(Φk, something(Φ, 0))
    end
    length(diags) == k0 || return nothing

    # Per component, one multiply-add; the canonical residue 0 ≤ Φ < D survives
    # composition (§10.5), which is what the gate's truncated rem relies on. The
    # rate scopes resolve by the same law, off the triple the fold left them.
    Δtb = Float64(Δt_r)
    D_c, Φ_c, Δt_c = Int[], Int[], Float64[]
    rows = ScheduleRow[]
    for ci in eachindex(b.structure.tiers)
        (a, m, c) = triples[ci]
        if b.structure.tiers[ci] === DISCRETE
            D, Φ = m * Dk[a + 1], Φk[a + 1] + c * Dk[a + 1]
            push!(D_c, D); push!(Φ_c, Φ); push!(Δt_c, D * Δtb)
            # the provenance vector itself: the structure is immutable, so no copy
            push!(rows, ScheduleRow(b.structure.paths[ci], a, D, Φ, D * Δtb,
                                    b.structure.provenance[ci]))
        else
            push!(D_c, 1); push!(Φ_c, 0); push!(Δt_c, 0.0)
        end
    end
    scopes = [ScopeRow(sc.path, sc.key, sc.triple[1],
                       sc.triple[2] * Dk[sc.triple[1] + 1],
                       Φk[sc.triple[1] + 1] + sc.triple[3] * Dk[sc.triple[1] + 1])
              for sc in b.structure.scopes]
    (h = Float64(h_r), N_base = n_i, Δt_base = Δtb,
     schedule = Schedule(rows, scopes, D_c, Φ_c, Δt_c))
end

# --- the artifact (§9.1, §9.2, D-254) -------------------------------------------

"""
    Deployment(build::Build; h, N_base = nothing, Δt_base = nothing, algorithm = RK4,
               firing_budget = 4, localization_tol = 1e-6, localization_budget = 8)

The artifact the grid parameters fix (§9.1, §9.2, D-254): the build plus the
grid parameters, the algorithm and the three event parameters, scalar-free,
carrying the `Schedule` the constructor built and its own `warnings`.
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
    warnings::Vector{Diagnostic}  # the warnings the constructor raised (§9.1, D-250)
end

function Deployment(b::Build; h = nothing, N_base = nothing, Δt_base = nothing,
                    algorithm = RK4, firing_budget = 4, localization_tol = 1e-6,
                    localization_budget = 8)
    # The event parameters and the algorithm validate on their own terms, ahead
    # of the grid; all of it lands in one list and one throw (§9.1, D-229).
    diags = Diagnostic[]
    algorithm isa Type && algorithm <: AbstractStepper ||
        push!(diags, DeploymentInvalid(parameter = :algorithm, reason = :range, value = algorithm))
    firing_budget isa Integer && firing_budget ≥ 1 ||
        push!(diags, DeploymentInvalid(parameter = :firing_budget, reason = :range, value = firing_budget))
    localization_tol isa Real && localization_tol > 0 ||
        push!(diags, DeploymentInvalid(parameter = :localization_tol, reason = :range, value = localization_tol))
    localization_budget isa Integer && localization_budget ≥ 1 ||
        push!(diags, DeploymentInvalid(parameter = :localization_budget, reason = :range, value = localization_budget))
    bound = bind_schedule(b, h, N_base, Δt_base, diags)
    isempty(diags) || throw(DiagnosticError(diags))    # one throw per call (§9.1, D-229)
    Deployment(b, bound.h, bound.N_base, bound.Δt_base, algorithm, Int(firing_budget),
               Float64(localization_tol), Int(localization_budget), bound.schedule,
               Diagnostic[])
end

# §12.7's header check is the consumer, and a what-if replay re-drives a
# recording against a *modified model of the same structure*, so **the build is
# not compared**: comparing it would refuse what the spec admits. `warnings` is
# not compared either — it is a function of the rest.
Base.:(==)(a::Deployment, b::Deployment) =
    a.h == b.h && a.N_base == b.N_base && a.Δt_base == b.Δt_base &&
    a.algorithm === b.algorithm && a.firing_budget == b.firing_budget &&
    a.localization_tol == b.localization_tol &&
    a.localization_budget == b.localization_budget && a.schedule == b.schedule
Base.hash(d::Deployment, h::UInt) =
    hash(d.schedule, hash(d.localization_budget, hash(d.localization_tol,
        hash(d.firing_budget, hash(d.algorithm, hash(d.Δt_base,
            hash(d.N_base, hash(d.h, h))))))))

"""
    warnings(d::Deployment) → Vector{Diagnostic}

The warnings the `Deployment` constructor raised (§9.2, D-250). The constructor
produces an artifact, so its warnings live on it; the log line each one got at
return is presentation, never the home.
"""
warnings(d::Deployment) = d.warnings
