# --- the artifacts' renderings (§9.2, §13.7, D-257) ----------------------------
# Each build-side and deployment artifact renders itself through `show`, with no
# accessor returning a table beside it. Two methods apiece: the compact form
# (one line, no newline — what a container or `repr` prints) and the REPL form
# under `MIME"text/plain"` (the tables). A REPL form is built as lines: no
# trailing newline, no line with trailing whitespace, tables aligned with `rpad`
# over `textwidth` and two spaces between columns, as `_grid_block` does, each
# block indented two spaces under its heading, and a nested artifact's lines two
# spaces further in. The grid block itself stays in `diagnostics.jl`, since the
# messages use it; the `Deployment` sets its lines under `grid:` here. The
# published `FrameworkStatus` renders here too, under the same conventions, with
# §11.8's `maxlog` cap its presentation policy.

const _SUBSCRIPTS = collect("₀₁₂₃₄₅₆₇₈₉")

# `A₀`, `A₁`, …: the anchor by its index, 0 the base grid.
_anchor_name(anchor::Int) = "A" * join(_SUBSCRIPTS[c - '0' + 1] for c in string(anchor))

# A count with its noun: `no anchors`, `1 anchor`, `4 components`.
_count(number::Int, noun::String) =
    number == 0 ? "no $(noun)s" : number == 1 ? "1 $noun" : "$number $(noun)s"

# The root's path in a table column; a primitive at the root is its own component.
_path_label(path::String) = isempty(path) ? "root" : path

# A rate entry as its fields spell it. Not the default `show`, whose
# qualification of the type name depends on the printing module.
_entry_label(entry::Relative) = "Relative($(entry.K), $(entry.φ))"
_entry_label(entry::Absolute) = "Absolute($(entry.T), $(entry.τ))"

# A `RateLink` chain, `key = entry` joined by ` → `; empty is a dash.
_rates_label(rates::Vector{RateLink}) =
    isempty(rates) ? "—" :
    join(("$(link.key) = $(_entry_label(link.entry))" for link in rates), " → ")

# A comma-separated list of names; empty is a dash.
_names_label(name_list) = isempty(name_list) ? "—" : join(name_list, ", ")

# One aligned table, header first, every line under `indent` and stripped on
# the right.
function _table(indent::String, header::Vector{String}, rows::Vector{Vector{String}})
    widths = [maximum(textwidth(line[j]) for line in (header, rows...)) for j in eachindex(header)]
    [rstrip(indent * join((rpad(cell, width) for (cell, width) in zip(line, widths)), "  "))
     for line in (header, rows...)]
end

# The lines two spaces further in, for a nested artifact or a rendered block.
_indented(lines::Vector{<:AbstractString}) = ["  " * line for line in lines]

# The warnings block every artifact that carries a list ends with: `none`, or one
# `logline` per warning, its own lines indented under the heading.
_warning_lines(warning_list::Vector{Diagnostic}) =
    isempty(warning_list) ? ["warnings: none"] :
    vcat(["warnings:"],
         (_indented(split(logline(warning), '\n')) for warning in warning_list)...)

# --- Structure --------------------------------------------------------------------

_structure_counts(structure::Structure) =
    join((_count(length(structure.components), "component"),
          _count(length(structure.anchors), "anchor"),
          _count(length(structure.scopes), "rate scope")), ", ")

Base.show(io::IO, structure::Structure) = print(io, "Structure(", _structure_counts(structure), ")")

# A root face's route: its bare name, then each hop as `path/name`, joined with
# ` → ` and ending at the terminal (§13.7).
_route_label(face::Symbol, route::Vector{Tuple{String,Symbol}}) =
    join([String(face); ["$path/$name" for (path, name) in route]], " → ")

# One side's block: one line per route of each root face in `faces`, derived from
# the wires (D-315), or no block when the side has no root face.
function _route_lines(heading::String, structure::Structure, faces::Vector{Symbol})
    lines = ["    " * _route_label(face, route)
             for face in faces for route in face_routes(structure, ("", face))]
    isempty(lines) ? String[] : vcat(["  " * heading], lines)
end

# The component table with its timing against the anchors, the rate-scope rows
# when any keyed scope exists, the anchor table with the `A₀` row always
# present: `Δt_base` symbolic in its `T` column and dashes where no scope
# declares it (§9.2), and the root faces' routes, derived through `face_routes`.
# The level rows and their wires are fields, printed by no method here.
function _lines(structure::Structure)
    lines = ["Structure: " * _structure_counts(structure) * "; root inputs: " *
             (isempty(structure.root_inputs) ? "none" : join(structure.root_inputs, ", ")),
             "  components:"]
    append!(lines, _table("    ", ["path", "tier", "anchor", "m", "c", "rates"],
                          [[_path_label(entry.path), tier_word(entry.tier),
                            _anchor_name(entry.timing.anchor), string(entry.timing.m),
                            string(entry.timing.c), _rates_label(entry.rates)]
                           for entry in structure.components]))
    if !isempty(structure.scopes)
        push!(lines, "  rate scopes:")
        append!(lines, _table("    ", ["path", "key", "anchor", "m", "c"],
                              [[_path_label(scope.path), string(scope.key),
                                _anchor_name(scope.timing.anchor), string(scope.timing.m),
                                string(scope.timing.c)]
                               for scope in structure.scopes]))
    end
    push!(lines, "  anchors:")
    append!(lines, _table("    ", ["anchor", "T", "τ", "scope", "key"],
                          vcat([[_anchor_name(0), "Δt_base", string(zero(Rational{Int})), "—", "—"]],
                               [[_anchor_name(k), string(anchor.T), string(anchor.τ),
                                 _path_label(anchor.scope), string(anchor.key)]
                                for (k, anchor) in enumerate(structure.anchors)])))
    root_level = first(structure.levels)
    append!(lines, _route_lines("input routes:", structure, _boundary_inputs(root_level)))
    append!(lines, _route_lines("output routes:", structure, _boundary_outputs(root_level)))
    lines
end

# --- Outputs ----------------------------------------------------------------------

Base.show(io::IO, outputs::Outputs) =
    print(io, "Outputs(", _count(length(outputs.order), "component"), ")")

# One row per position in the execution order: the component at it, by its
# path, with its stage-1 and stage-2 names.
function _lines(outputs::Outputs)
    rows = [[_path_label(outputs.components[ci].path),
             _names_label(outputs.components[ci].stage1),
             _names_label(outputs.components[ci].stage2)]
            for ci in outputs.order]
    vcat(["Outputs: execution order over " * _count(length(outputs.order), "component")],
         _table("  ", ["component", "stage 1", "stage 2"], rows))
end

# --- Events -----------------------------------------------------------------------

_events_counts(events::Events) =
    _count(sum(row -> length(row.policies), events.components; init = 0), "event") *
    " over " * _count(length(events.components), "component")

Base.show(io::IO, events::Events) = print(io, "Events(", _events_counts(events), ")")

# One row per component that declares an event: its path, `name => policy` in
# declaration order, and the event bundle's field names. No events is the
# heading alone.
function _lines(events::Events)
    rows = [[_path_label(row.path),
             join(("$name => $policy" for (name, policy) in pairs(row.policies)), ", "),
             isempty(row.bundle) ? "—" : "(" * join(row.bundle, ", ") * ")"]
            for row in events.components if !isempty(row.policies)]
    lines = ["Events: " * _events_counts(events)]
    isempty(rows) || append!(lines, _table("  ", ["component", "events", "bundle"], rows))
    lines
end

# --- Schedule ---------------------------------------------------------------------

# The hyperperiod: the pattern repeats with `lcm(Dᵢ)` base ticks, so one is the
# complete truth (§9.2).
_hyperperiod(schedule::Schedule) = lcm([row.D for row in schedule.rows])

function Base.show(io::IO, schedule::Schedule)
    isempty(schedule.rows) && return print(io, "Schedule(no rows)")
    print(io, "Schedule(", _count(length(schedule.rows), "row"), ", hyperperiod ",
          _hyperperiod(schedule), " base ticks)")
end

# The rows, the rate-scope rows when any exist, and the hyperperiod chart: one
# row per schedule row, one character per base tick `k = 0 … hyperperiod−1`, `●`
# where `(k − Φ) % D == 0`, under a ruler carrying the tick index at every
# column divisible by 10. The guard is binary (D-257): at `hyperperiod > 100`
# the chart's place holds one line naming the length instead.
function _lines(schedule::Schedule)
    rows = schedule.rows
    heading = "Schedule: " * (isempty(rows) ? "no rows" : _count(length(rows), "row")) *
              (isempty(schedule.scopes) ? "" : ", " * _count(length(schedule.scopes), "rate scope")) *
              (isempty(rows) ? "" : ", hyperperiod $(_hyperperiod(schedule)) base ticks")
    lines = [heading]
    isempty(rows) ||
        append!(lines, _table("  ", ["path", "anchor", "D", "Φ", "Δt", "rates"],
                              [[_path_label(row.path), _anchor_name(row.anchor), string(row.D),
                                string(row.Φ), repr(row.Δt), _rates_label(row.rates)]
                               for row in rows]))
    if !isempty(schedule.scopes)
        push!(lines, "  rate scopes:")
        append!(lines, _table("    ", ["path", "key", "anchor", "D", "Φ"],
                              [[_path_label(scope.path), string(scope.key), _anchor_name(scope.anchor),
                                string(scope.D), string(scope.Φ)]
                               for scope in schedule.scopes]))
    end
    isempty(rows) && return lines
    hyperperiod = _hyperperiod(schedule)
    hyperperiod > 100 &&
        return push!(lines, "  hyperperiod: $hyperperiod base ticks, chart omitted")
    push!(lines, "  hyperperiod chart, $hyperperiod base ticks:")
    width = maximum(textwidth(_path_label(row.path)) for row in rows)
    ruler = ""
    for k in 0:10:hyperperiod-1
        ruler = rpad(ruler, k) * string(k)
    end
    push!(lines, " "^(4 + width + 2) * ruler)
    for row in rows
        push!(lines, "    " * rpad(_path_label(row.path), width) * "  " *
                     join(((k - row.Φ) % row.D == 0 ? '●' : '·') for k in 0:hyperperiod-1))
    end
    lines
end

# --- Build ------------------------------------------------------------------------

# The activation keys, read under the build's lock (§9.4): the nominal `Float64`
# first, the rest by name, since the dictionary has no order of its own.
_activations_label(build::Build) =
    lock(build.lock) do
        others = sort([string(T) for T in keys(build.activations) if T !== Float64])
        join(["Float64"; others], ", ")
    end

Base.show(io::IO, build::Build) =
    print(io, "Build(", _count(length(build.structure.components), "component"),
          ", activations: ", _activations_label(build), ")")

# The feedthrough edges the execution order was computed over (§5.3, D-261),
# derived rather than carried: a face of a component with a stage 2, fed by
# another component's stage-2 port. A root input and a stage-1 port add none.
function _feedthrough(structure::Structure, outputs::Outputs, decls::Vector{Decls})
    edges = String[]
    for ci in outputs.order
        isempty(outputs.components[ci].stage2) && continue
        consumer = structure.components[ci]
        for face in keys(decls[ci].ins)
            (producer, port_name) = terminal_producer(structure, (consumer.path, face))
            isempty(producer) && continue
            port_name in outputs.components[index_of(structure, producer)].stage2 || continue
            push!(edges, "$producer.$port_name → $(_path_label(consumer.path)).$face")
        end
    end
    edges
end

# The summary and the parts: the structure, the outputs, the feedthrough line
# the `Build` alone can derive, the events, then the warnings.
function _lines(build::Build)
    components = build.structure.components
    continuous = count(entry.tier === CONTINUOUS for entry in components)
    edges = _feedthrough(build.structure, build.outputs, activation(build, Float64).decls)
    vcat(["Build: " * _count(length(components), "component") *
          " ($continuous continuous, $(length(components) - continuous) discrete); activations: " *
          _activations_label(build) * "; " * _count(length(build.warnings), "warning")],
         _indented(_lines(build.structure)),
         _indented(_lines(build.outputs)),
         ["  feedthrough: " * (isempty(edges) ? "none" : join(edges, ", "))],
         _indented(_lines(build.events)),
         _indented(_warning_lines(build.warnings)))
end

# --- Deployment -------------------------------------------------------------------

_deployment_parameters(deployment::Deployment) =
    "h = $(repr(deployment.h)), N_base = $(deployment.N_base), Δt_base = $(repr(deployment.Δt_base)), " *
    string(nameof(deployment.algorithm))

Base.show(io::IO, deployment::Deployment) =
    print(io, "Deployment(", _deployment_parameters(deployment), ")")

# The parameters, the build in its compact form (a reader wanting it evaluates
# `deployment.build`), the schedule, the grid block's lines under `grid:` — `no
# constraint` where no anchor declares one — and the warnings. The block's
# lines carry their own indent under the line they are appended to.
function _lines(deployment::Deployment)
    block = _grid_block(deployment.grid)
    grid = isempty(block) ? ["grid: no constraint"] : vcat(["grid:"], split(block, '\n')[2:end])
    vcat(["Deployment: " * _deployment_parameters(deployment) *
          "; firing_budget = $(deployment.firing_budget), " *
          "localization_tol = $(repr(deployment.localization_tol)), " *
          "localization_budget = $(deployment.localization_budget)",
          "  build: " * sprint(show, deployment.build)],
         _indented(_lines(deployment.schedule)),
         _indented(grid),
         _indented(_warning_lines(deployment.warnings)))
end

# --- FrameworkStatus (§11.8) ------------------------------------------------------

"""
§11.8's presentation policy, the `maxlog` successor: a writer × kind prints
its occurrences in full up to this many cumulative ones, then as a count
alone. Presentation, never channel policy: the channel's own bound is
`DIAG_RING`, and the counts accumulate regardless.
"""
const STATUS_MAXLOG = 25

_pace_label(p::Float64) = isinf(p) ? "unpaced" : "pace = $p"

# The writer count, the cumulative occurrences over every writer's totals, the pace.
_status_counts(status::FrameworkStatus) =
    join((_count(length(status.writers), "writer"),
          _count(sum(record -> _total(record.totals), status.writers; init = 0), "occurrence"),
          _pace_label(status.pacer.pace)), ", ")

Base.show(io::IO, status::FrameworkStatus) =
    print(io, "FrameworkStatus(", _status_counts(status), ")")

# One kind's group under its writer: the count-only line, then the retained
# occurrences within the cap, then this boundary's suppressed count. The cap
# needs no state across snapshots: the occurrences before this boundary are the
# total less this boundary's retained and suppressed ones, so a reader sampling
# every snapshot sees each of the first `STATUS_MAXLOG` exactly once.
function _kind_lines(record::WriterStatus, kind_type::Type)
    field = _kind(kind_type)
    total = getfield(record.totals, field)
    total == 0 && return String[]
    retained = [occurrence for occurrence in record.recent if occurrence isa kind_type]
    suppressed_count = getfield(record.suppressed, field)
    earlier = total - length(retained) - suppressed_count
    lines = ["$(nameof(kind_type)): $(_count(total, "occurrence"))"]
    for (i, occurrence) in enumerate(retained)
        earlier + i ≤ STATUS_MAXLOG && append!(lines, _indented(split(logline(occurrence), '\n')))
    end
    suppressed_count > 0 && push!(lines, "  $suppressed_count suppressed this boundary")
    lines
end

# One writer's block: its name, the task state and the raw heartbeat where the
# record carries them, then a group per kind with a nonzero total in `KINDS`'s
# order. No staleness verdict: read after the run, every heartbeat is stale
# against the wall clock, and `stale(record)` stays the GUI's question.
function _writer_lines(record::WriterStatus)
    facts = String[]
    record.task_state === nothing || push!(facts, string(record.task_state))
    record.heartbeat === nothing || push!(facts, "heartbeat $(record.heartbeat)")
    _total(record.totals) == 0 && push!(facts, "no occurrences")
    heading = isempty(facts) ? record.who * ":" : record.who * ": " * join(facts, ", ")
    vcat([heading],
         _indented(mapreduce(kind_type -> _kind_lines(record, kind_type), vcat, KINDS;
                             init = String[])))
end

_pacer_line(pacer::PacerStatus) =
    "pacer: " * join((_pace_label(pacer.pace), "debt $(pacer.debt) s",
                      "peak $(pacer.peak_debt) s", _count(pacer.overruns, "overrun"),
                      _count(pacer.reanchors, "reanchor"), "$(pacer.forgiven) s forgiven",
                      _count(pacer.waits, "wait"), "$(pacer.waited) s waited"), ", ")

# The writers in the status's order, the pacer's line last (§11.8, §10.7).
_lines(status::FrameworkStatus) =
    vcat(["FrameworkStatus: " * _status_counts(status)],
         _indented(mapreduce(_writer_lines, vcat, status.writers; init = String[])),
         ["  " * _pacer_line(status.pacer)])

# --- the REPL forms ---------------------------------------------------------------

for Artifact in (Structure, Outputs, Events, Schedule, Build, Deployment, FrameworkStatus)
    @eval Base.show(io::IO, ::MIME"text/plain", artifact::$Artifact) =
        join(io, _lines(artifact), "\n")
end
