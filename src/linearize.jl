# The linearization service (§14.10): the tap set the author declares, the
# seeded pass over it, and the value it comes back as.
#
# Everything the pass needs already exists. The addressing is the read side's:
# a resolved tap is a compiled read entry (readers.jl), and a `StateRead`'s
# `xbuf` offset or a `CellRead`'s cell address is a write site as much as a
# read site, so the seeds go where the reads come from (D-272). The world is
# trim's: D-213's two-half scratch set, a nominal half that holds the frozen
# discrete cells and a seeded half at the service's own `Dual` scalar
# (trim.jl). What this file adds is the tap resolution with its five refusals,
# the passes of `width` directions, and the split of values from partials.
# Nothing here writes the simulation: both executors are locals and die with
# the call, which is what makes linearization a pure query.

# --- the tap set (§14.10) ------------------------------------------------------

"""
    taps(; x = (;), u = (;), y = (;)) → Taps

§14.10's tap set: three labeled selector lists with closed membership, `x`
taking `get_state`, `u` `get_input`, `y` `get_output` and `get_face`. The
labels are the axes of the returned matrices. Membership is checked at
resolution, in the collecting form; here each list is checked to be a
NamedTuple of selectors, as `reads` checks its own (D-272).
"""
struct Taps{X<:Reads,U<:Reads,Y<:Reads}
    x::X
    u::U
    y::Y
end

taps(; x = (;), u = (;), y = (;)) = Taps(_tap_list(:x, x), _tap_list(:u, u), _tap_list(:y, y))

_tap_list(::Symbol, selectors::NamedTuple) = _reads(selectors)
_tap_list(list::Symbol, other) = throw(DiagnosticError(
    ReadSetMisuse(observed = typeof(other), reason = :not_a_tap_list, label = list)))

# --- the scalar, the width, the return (§14.10, D-272) --------------------------

"""
The service's own seeding tag (§9.4): what keeps a linearization activation
distinguishable from trim's (`TrimTag`), the probe's (`ProbeTag`) and a user's
own.
"""
struct LinearizeTag end

"The default number of seeded directions per pass (§14.10, D-272)."
const LINEARIZE_WIDTH = 8

"""The default width's scalar, pre-materializable: `build(m; activations = (Float64, LinearizeDual))` (§14.10, D-272)."""
const LinearizeDual = ForwardDiff.Dual{LinearizeTag,Float64,LINEARIZE_WIDTH}

"""
§14.10's returned object (D-272): the operating point and the four
Jacobians, the four vectors as NamedTuples under the tap labels, the
matrices row- and column-ordered by the label tuples. Every entry is exact
to round-off; nothing here is a finite difference.
"""
struct Linearization
    ẋ₀::NamedTuple
    x₀::NamedTuple
    u₀::NamedTuple
    y₀::NamedTuple
    A::Matrix{Float64}
    B::Matrix{Float64}
    C::Matrix{Float64}
    D::Matrix{Float64}
    x_labels::Tuple{Vararg{Symbol}}
    u_labels::Tuple{Vararg{Symbol}}
    y_labels::Tuple{Vararg{Symbol}}
end

# --- the service (§14.10) -------------------------------------------------------

"""
    linearize(sim, tap_set::Taps; about = nothing, t0 = nothing, width = LINEARIZE_WIDTH)
        → Linearization

§14.10's linearization, a pure query on scratch buffers:

1. The operating point is `checkpoint(sim)` by default, legal in `initialized`
   and `stopped` and refused mid-frame, and it carries its own clock;
   `about = <condition>` with `t0` beside it places it anywhere else, legal
   wherever `init!` is (§14). `t0` is admitted only beside `about`, never
   silently ignored (Appendix B).
2. The tap set resolves in §13.1's collecting form: closed membership per list,
   one scalar per tap, no discrete store in `x` (D-197), no unseedable root
   input in `u` (D-167, D-168), no two seeds at one site (D-272). Every
   violation is one `TapResolution` in one `DiagnosticError`.
3. The nominal half: a `Float64` scratch executor. By default the checkpoint
   restored, whose held cells are the frozen tier's (D-274); under `about`, the
   condition applied and checked total over the root inputs (§14.6), then one
   establishment round (D-213).
4. The seeded half, at `Dual{LinearizeTag,Float64,width}`: a scratch executor,
   the operating point written as zero-partial constants, the frozen discrete
   cells copied from the nominal half (D-213).
5. The seeds: one direction per `x` tap and per `u` tap, `x` first, each
   written at its resolved site, the state's `xbuf` slot or the root input's
   cell (D-272).
6. The passes: the directions in groups of `width`, one evaluation per group.
   Value parts give `ẋ₀` and `y₀`, partials give `A` and `B` read at `ẋ`, `C`
   and `D` read at `y`.
7. Nothing on the simulation is written: both executors die with the call,
   with no commit and no boundary zero.

The default width's scalar is `LinearizeDual`, so a build that lists it in
`activations` linearizes any tap set with no compile at the keyboard (§9.7).
The width changes the grouping, never the answer.
"""
function linearize(sim::Simulation{Float64}, tap_set::Taps; about = nothing,
                   t0 = nothing, width::Int = LINEARIZE_WIDTH)
    width ≥ 1 || throw(DiagnosticError(ArgumentInvalid(
        call = :linearize, argument = :width, reason = :nonpositive_width, value = width)))
    about === nothing && t0 !== nothing && throw(DiagnosticError(ArgumentInvalid(
        call = :linearize, argument = :t0, reason = :t0_without_about)))

    # §14's two rows: the default form inherits `checkpoint`'s precondition, the
    # explicit one `init!`'s legality. Both before any resolution. The gate names
    # `linearize` for both forms, so `checkpoint` is left the mid-frame refusal.
    status = lifecycle(sim)
    legal = about === nothing ? [:initialized, :stopped] : collect(STOPPED_SIM_LEGAL)
    status in legal ||
        throw(DiagnosticError(ServiceLifecycle(op = :linearize, status = status, legal = legal)))
    cp = about === nothing ? checkpoint(sim) : nothing
    build = sim.deployment.build
    T = ForwardDiff.Dual{LinearizeTag,Float64,width}
    (x_entries, u_entries, y_entries) = _resolve_taps(tap_set, build, T)

    # --- the nominal half (D-213) ------------------------------------------------
    nominal_exec = _scratch(sim, Float64)
    if about === nothing
        _restore_state!(nominal_exec, cp)            # the held cells are the frozen tier's (D-274)
    else
        t = Float64(something(t0, 0.0))
        _set_clock!(nominal_exec, t, t)
        plan = resolve_condition(about, build, Float64)
        assert_total(plan, build.structure, :linearize)   # (§14.6): before any evaluation
        apply!(nominal_exec, plan)
        _round!(nominal_exec, ESTABLISH)             # every discrete output stage, due or not
    end

    # --- the seeded half ---------------------------------------------------------
    act = activation(build, T)
    seeded_exec = _scratch(sim, T, act)
    if about === nothing
        copyto!(seeded_exec.xbuf, cp.x)              # zero partials throughout
        _restore_stores!(seeded_exec, cp)
        # each root input converted to its seeded cell's type, as an authored
        # value is at resolution (conditions.jl)
        for face in build.structure.root_inputs
            addr = act.layout.addr[("", face)]
            scatter_cell!(seeded_exec.store, addr, convert(_port_type(addr),
                gather_cell(nominal_exec.store, nominal_exec.act.layout.addr[("", face)])))
        end
        _set_clock!(seeded_exec, cp.t, cp.t₀)
    else
        _set_clock!(seeded_exec, t, t)
        apply!(seeded_exec, resolve_condition(about, build, T))
    end
    _establish_frozen!(seeded_exec, act, nominal_exec, build)

    # --- the passes --------------------------------------------------------------
    n_x, n_u, n_y = length(x_entries), length(u_entries), length(y_entries)
    N = n_x + n_u
    sites = Any[first.(x_entries); u_entries]
    site_values = Float64[_site_value(seeded_exec, site) for site in sites]
    ẋ₀, y₀ = Vector{Any}(undef, n_x), Vector{Any}(undef, n_y)
    A, B = zeros(n_x, n_x), zeros(n_x, n_u)
    C, D = zeros(n_y, n_x), zeros(n_y, n_u)
    for group in (N == 0 ? (1:0,) : Iterators.partition(1:N, width))
        for (k, site) in enumerate(sites)
            pos = k in group ? k - first(group) + 1 : 0
            _seed_site!(seeded_exec, site, _seed(T, site_values[k], pos))
        end
        evaluate!(seeded_exec)
        for (i, (_, entry)) in enumerate(x_entries)
            ẋ₀[i] = _readback!(A, B, i, _read(entry, seeded_exec), group, n_x)
        end
        for (i, entry) in enumerate(y_entries)
            y₀[i] = _readback!(C, D, i, _read(entry, seeded_exec), group, n_x)
        end
    end

    x_labels, u_labels, y_labels =
        keys(tap_set.x.selectors), keys(tap_set.u.selectors), keys(tap_set.y.selectors)
    Linearization(NamedTuple{x_labels}(Tuple(ẋ₀)),
                  NamedTuple{x_labels}(Tuple(site_values[1:n_x])),
                  NamedTuple{u_labels}(Tuple(site_values[n_x+1:N])),
                  NamedTuple{y_labels}(Tuple(y₀)),
                  A, B, C, D, x_labels, u_labels, y_labels)
end

# A non-nominal deployment is refused rather than served: the seeded scalar is
# the service's own `Dual` over `Float64`, and the operating point is a nominal
# world's.
linearize(sim::Simulation, ::Taps; kw...) = throw(DiagnosticError(
    ArgumentInvalid(call = :linearize, reason = :non_nominal, value = string(typeof(sim)))))

linearize(::Simulation, other; kw...) = throw(DiagnosticError(
    ArgumentInvalid(call = :linearize, argument = :taps, reason = :not_a_tap_set,
                    value = string(typeof(other)))))

# --- the pieces the service is built out of --------------------------------------

# The scratch clock at the operating point: `t` in the executor's scalar, the
# origin a `Float64` as everywhere (§12.6).
function _set_clock!(exec::Executor{T}, t::Float64, t₀::Float64) where {T}
    exec.clock.t = T(t)
    exec.clock.t₀ = t₀
    nothing
end

# What each list admits (§14.10, D-272).
_tap_kind(::Val{:x}) = GetState
_tap_kind(::Val{:u}) = GetInput
_tap_kind(::Val{:y}) = Union{GetOutput,GetFace}

"""
    _resolve_taps(tap_set, build, T) → (x_entries, u_entries, y_entries)

Resolve the three lists in §13.1's collecting form, one `DiagnosticError` with
every violation. The checks run at the nominal activation, so every payload
carries nominal types; the entries returned are the seeded activation's. An `x`
entry is its `xbuf` site paired with the `DerivRead` its row is read through,
a `u` entry the root input's `CellRead`, a `y` entry its cell's. A second `x`
or `u` tap at a site already seeded is refused naming the earlier label, since
its seed would overwrite the first; `y` taps are reads and may repeat.

Each list is mounted (§14.9, D-277). The kind check reads the selector as
authored and runs before the rebase, and everything after it reads the rebased
selector: a `get_face` in the `y` list is admitted, and seeded, as the
`get_output` of its producer. A mount chain that fails is reported once, for
every list that carries it.
"""
function _resolve_taps(tap_set::Taps, build::Build, ::Type{T}) where {T}
    nominal_act, act = activation(build, Float64), activation(build, T)
    diags = Diagnostic[]
    seeded_by = Dict{Any,Symbol}()       # seed site => the label that seeds it
    failed_prefixes = Set{Tuple{Vararg{String}}}()
    entries = map((:x, :u, :y)) do list
        resolved = Any[]
        read_set = getfield(tap_set, list)
        read_set.prefixes in failed_prefixes && return resolved
        mount_point = _mount(read_set, build, diags)
        mount_point === nothing && (push!(failed_prefixes, read_set.prefixes); return resolved)
        for (label, authored) in pairs(read_set.selectors)
            if !(authored isa _tap_kind(Val(list)))
                push!(diags, _reader_violation(label, authored, first(mount_point), :tap_kind;
                                               list = list))
                continue
            end
            read = _rebase(authored, label, mount_point..., build, diags)
            read === nothing && continue
            nominal_entry = _resolve_selector(read.selector, read, build, nominal_act, diags)
            nominal_entry === nothing && continue
            entry = _seeded_tap(Val(list), nominal_entry, read.selector, read, build, act, diags)
            entry === nothing && continue
            site = _site_key(Val(list), entry)
            if site !== nothing && haskey(seeded_by, site)
                push!(diags, _reader_violation(read, :duplicate_site;
                                               duplicate_of = seeded_by[site]))
                continue
            end
            site === nothing || (seeded_by[site] = read.label)
            push!(resolved, entry)
        end
        resolved
    end
    isempty(diags) || throw(DiagnosticError(diags))
    entries
end

# A seed site's identity (D-272): an `x` entry's `xbuf` slot, a `u` entry's cell
# and the linear place its index step names, 0 for the whole cell, so `[3]` and
# `[1,2]` on one matrix are one site. A `y` entry is a read, not a seed, and has none.
_site_key(::Val{:x}, entry::Tuple{Int,DerivRead}) = first(entry)
_site_key(::Val{:u}, entry::CellRead{A,C}) where {A,C} =
    (entry.addr, isempty(C) ? 0 : _linear_index(_port_type(entry.addr), only(C)))
_site_key(::Val{:y}, ::CellRead) = nothing

# The type a resolved chain lands on under `P`.
_resolved_type(::Type{P}, chain::Tuple) where {P} = last(resolve_leaf(P, chain))

# A seed is a `Float64` direction written into a whole cell or one `SArray`
# component, so a seeded tap reaches its scalar through one index step at most
# and never a `.name` step: there is no lens into a struct's slots (D-036,
# D-276). A non-`Real` leaf is the vector tap, checked before the leaf's type
# so that an unindexed `SVector` reads as one.
function _check_seedable(read::MountedRead, ::Type{P}, chain::Tuple, leaf_type::Type,
                         diags::Vector{Diagnostic}) where {P}
    offending = findfirst(k -> chain[k] isa Symbol || k > 1, eachindex(chain))
    offending === nothing ||
        return (push!(diags, _reader_violation(read, :unseedable; declared = P,
                                               step = _step_string(chain[offending]))); false)
    leaf_type <: Real ||
        return (push!(diags, _reader_violation(read, :vector_tap; declared = leaf_type)); false)
    leaf_type === Float64 ||
        return (push!(diags, _reader_violation(read, :unseedable; declared = leaf_type)); false)
    true
end

# The linear position of an index step in an `SArray` of type `P`: `[k]` is
# itself, `[k,l]` its column-major place (§14.4).
_linear_index(::Type{P}, index::Tuple{Vararg{Int}}) where {P} = LinearIndices(size(P))[index...]

# The `x` list: a discrete store is refused with its tier in hand (D-197).
_seeded_tap(::Val{:x}, ::StoreRead, ::GetState, read::MountedRead, ::Build, ::Activation,
            diags::Vector{Diagnostic}) =
    (push!(diags, _reader_violation(read, :discrete_state)); nothing)

# The `x` list's continuous leaf: the offset is `T`-independent (§9.2), so the
# seeded entries are the nominal one retyped. The seed site is the leaf's slot
# in `xbuf`, the field's offset plus the index step's linear position.
function _seeded_tap(::Val{:x}, entry::StateRead{P,C}, ::GetState, read::MountedRead,
                     ::Build, ::Activation{T}, diags::Vector{Diagnostic}) where {P,C,T}
    _check_seedable(read, P, C, _resolved_type(P, C), diags) || return nothing
    linear = isempty(C) ? 1 : _linear_index(P, only(C))
    (entry.offset + linear, DerivRead{retype(T, P),C}(entry.offset))
end

# The `u` list: the root input's cell follows the seeded scalar only when every
# consumer tolerates it, D-168's meet. A consumer whose entry refuses the walked
# type is a pinning consumer, named with its tier and its declared entry: a
# continuous one pins by declaration (D-167), a discrete one by tier (§8.2). The
# face is the root input the mount step landed on, so the meet is right at a
# mount (D-277).
function _seeded_tap(::Val{:u}, entry::CellRead{A,C}, ::GetInput, read::MountedRead,
                     build::Build, act::Activation{T}, diags::Vector{Diagnostic}) where {A,C,T}
    structure = build.structure
    face = read.head
    P = _port_type(entry.addr)
    _check_seedable(read, P, C, _resolved_type(P, C), diags) || return nothing
    root_type = structure.root_types[findfirst(==(face), structure.root_inputs)]
    walked_type = retype(T, root_type)
    pinning = Tuple{String,Symbol,Any}[
        (consumer.path, Symbol(tier_word(consumer.tier)),
         invoke_declaration(u_types, consumer.instance)[consumer_face])
        for (ci, consumer) in enumerate(structure.components)
        for (consumer_face, producer) in consumer.conns
        if producer === ("", face) &&
           !_accepts_wire(act.decls[ci].ins[consumer_face], walked_type, T)]
    addr = act.layout.addr[("", face)]
    # The seeded cell's type is the meet's own witness.
    isempty(pinning) == (_port_type(addr) === walked_type) || throw(InternalInvariant(
        "root input `$face`: the meet names $(length(pinning)) pinning consumer(s) and the " *
        "seeded cell is $(_port_type(addr)), against the walked $walked_type"))
    isempty(pinning) ||
        return (push!(diags, _reader_violation(read, :unseedable; declared = root_type,
                                               pinning = pinning));
                nothing)
    CellRead{typeof(addr),C}(addr)
end

# The `y` list: any `Real` leaf is readable, `Float64` or not, since a row is a
# read and not a seed. A `get_face` arrives rebased to its producer's port.
function _seeded_tap(::Val{:y}, entry::CellRead{A,C}, selector::GetOutput, read::MountedRead,
                     ::Build, act::Activation, diags::Vector{Diagnostic}) where {A,C}
    leaf_type = _resolved_type(_port_type(entry.addr), C)
    leaf_type <: Real ||
        return (push!(diags, _reader_violation(read, :vector_tap; declared = leaf_type));
                nothing)
    addr = act.layout.addr[(selector.path, read.head)]
    CellRead{typeof(addr),C}(addr)
end

# The value at a seed site before any seed is written.
_site_value(exec::Executor, site::Int) = ForwardDiff.value(exec.xbuf[site])
_site_value(exec::Executor, site::CellRead) = ForwardDiff.value(_read(site, exec))

# One seed: the site's value with the unit partial in slot `pos`, or all-zero
# partials when `pos` is zero and the site is outside the pass's group.
_seed(::Type{ForwardDiff.Dual{TG,Float64,W}}, site_value::Float64, pos::Int) where {TG,W} =
    ForwardDiff.Dual{TG}(site_value, ntuple(j -> Float64(j == pos), Val(W))...)

_seed_site!(exec::Executor, site::Int, seed) = (exec.xbuf[site] = seed; nothing)
_seed_site!(exec::Executor, site::CellRead{A,()}, seed) where {A} =
    scatter_cell!(exec.store, site.addr, seed)
# A one-step index chain, the only other a seeded tap resolves to: one component.
function _seed_site!(exec::Executor, site::CellRead{A,C}, seed) where {A,C}
    cell = gather_cell(exec.store, site.addr)
    scatter_cell!(exec.store, site.addr,
                  Base.setindex(cell, seed, _linear_index(typeof(cell), only(C))))
end

# One row of a matrix pair out of one read: the group's partials into the `x`
# matrix's or the `u` matrix's column, the value returned. A frozen `Float64`
# read carries no partials, and its row is zero.
function _readback!(state_matrix::Matrix{Float64}, input_matrix::Matrix{Float64}, i::Int,
                    reading, group, n_x::Int)
    for (pos, k) in enumerate(group)
        partial = reading isa ForwardDiff.Dual ? ForwardDiff.partials(reading, pos) : 0.0
        k ≤ n_x ? (state_matrix[i, k] = partial) : (input_matrix[i, k - n_x] = partial)
    end
    ForwardDiff.value(reading)
end
