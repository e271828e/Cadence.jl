# --- the artifacts' renderings (§9.2, §13.7, D-257) ----------------------------
# Each build-side and deployment artifact renders itself through `show`, with no
# accessor returning a table beside it. Two methods apiece: the compact form
# (one line, no newline — what a container or `repr` prints) and the REPL form
# under `MIME"text/plain"` (the tables). A REPL form is built as lines: no
# trailing newline, no line with trailing whitespace, tables aligned with `rpad`
# over `textwidth` and two spaces between columns, as `_grid_block` does, each
# block indented two spaces under its heading, and a nested artifact's lines two
# spaces further in. The grid block itself stays in `diagnostics.jl`, since the
# messages use it; the `Deployment` sets its lines under `grid:` here.

const _SUBSCRIPTS = collect("₀₁₂₃₄₅₆₇₈₉")

# `A₀`, `A₁`, …: the anchor by its index, 0 the base grid.
_anchor_name(anchor::Int) = "A" * join(_SUBSCRIPTS[c - '0' + 1] for c in string(anchor))

# A count with its noun: `no anchors`, `1 anchor`, `4 components`.
_count(n::Int, noun::String) = n == 0 ? "no $(noun)s" : n == 1 ? "1 $noun" : "$n $(noun)s"

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
_names_label(names) = isempty(names) ? "—" : join(names, ", ")

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
_warning_lines(warnings::Vector{Diagnostic}) =
    isempty(warnings) ? ["warnings: none"] :
    vcat(["warnings:"], (_indented(split(logline(warning), '\n')) for warning in warnings)...)

# --- Structure --------------------------------------------------------------------

_structure_counts(structure::Structure) =
    join((_count(length(structure.components), "component"),
          _count(length(structure.anchors), "anchor"),
          _count(length(structure.scopes), "rate scope")), ", ")

Base.show(io::IO, structure::Structure) = print(io, "Structure(", _structure_counts(structure), ")")

# The component table with its timing against the anchors, the rate-scope rows
# when any keyed scope exists, and the anchor table with the `A₀` row always
# present: `Δt_base` symbolic in its `T` column and dashes where no scope
# declares it (§9.2). Faces and wires are fields, printed by no method here.
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
    lines
end

# --- Dataflow ---------------------------------------------------------------------

Base.show(io::IO, dataflow::Dataflow) =
    print(io, "Dataflow(", _count(length(dataflow.order), "component"), ")")

# One row per position in the execution order: the component at it, its stage-1
# and stage-2 names, and the feedthrough edges into it, the stage-2 dependencies
# the order was computed over. `label(ci)` names a component: `#ci` standalone,
# the path where the `Build` renders it.
function _lines(dataflow::Dataflow, label)
    rows = [[string(position), label(ci), _names_label(dataflow.stage1[ci]),
             _names_label(dataflow.stage2[ci]),
             _names_label(("$face ← $(label(producer)).$port"
                           for (producer, port, face) in dataflow.edges[ci]))]
            for (position, ci) in enumerate(dataflow.order)]
    vcat(["Dataflow: execution order over " * _count(length(dataflow.order), "component")],
         _table("  ", ["position", "component", "stage 1", "stage 2", "feedthrough"], rows))
end
_lines(dataflow::Dataflow) = _lines(dataflow, ci -> "#$ci")

# --- Events -----------------------------------------------------------------------

_events_counts(events::Events) =
    _count(sum(length, events.policies; init = 0), "event") * " over " *
    _count(length(events.policies), "component")

Base.show(io::IO, events::Events) = print(io, "Events(", _events_counts(events), ")")

# One row per component that declares an event: `name => policy` in declaration
# order, and the event bundle's field names. No events is the heading alone.
function _lines(events::Events, label)
    rows = [[label(ci), join(("$name => $policy" for (name, policy) in pairs(policies)), ", "),
             isempty(events.bundles[ci]) ? "—" : "(" * join(events.bundles[ci], ", ") * ")"]
            for (ci, policies) in enumerate(events.policies) if !isempty(policies)]
    lines = ["Events: " * _events_counts(events)]
    isempty(rows) || append!(lines, _table("  ", ["component", "events", "bundle"], rows))
    lines
end
_lines(events::Events) = _lines(events, ci -> "#$ci")

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
# row per schedule row, one character per base tick `k = 0 … L−1`, `●` where
# `(k − Φ) % D == 0`, under a ruler carrying the tick index at every column
# divisible by 10. The guard is binary (D-257): at `L > 100` the chart's place
# holds one line naming the length instead.
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
    L = _hyperperiod(schedule)
    L > 100 && return push!(lines, "  hyperperiod: $L base ticks, chart omitted")
    push!(lines, "  hyperperiod chart, $L base ticks:")
    width = maximum(textwidth(_path_label(row.path)) for row in rows)
    ruler = ""
    for k in 0:10:L-1
        ruler = rpad(ruler, k) * string(k)
    end
    push!(lines, " "^(4 + width + 2) * ruler)
    for row in rows
        push!(lines, "    " * rpad(_path_label(row.path), width) * "  " *
                     join(((k - row.Φ) % row.D == 0 ? '●' : '·') for k in 0:L-1))
    end
    lines
end

# --- Build ------------------------------------------------------------------------

# The activation keys, read under the build's lock (§9.4): the nominal `Float64`
# first, the rest by name, since the dictionary has no order of its own.
_activations_label(built::Build) =
    lock(built.lock) do
        others = sort([string(T) for T in keys(built.activations) if T !== Float64])
        join(["Float64"; others], ", ")
    end

Base.show(io::IO, built::Build) =
    print(io, "Build(", _count(length(built.structure.components), "component"),
          ", activations: ", _activations_label(built), ")")

# The summary and the parts: the structure, then the dataflow and the events
# with paths as component labels, then the warnings.
function _lines(built::Build)
    components = built.structure.components
    continuous = count(entry.tier === CONTINUOUS for entry in components)
    label = ci -> _path_label(components[ci].path)
    vcat(["Build: " * _count(length(components), "component") *
          " ($continuous continuous, $(length(components) - continuous) discrete); activations: " *
          _activations_label(built) * "; " * _count(length(built.warnings), "warning")],
         _indented(_lines(built.structure)),
         _indented(_lines(built.dataflow, label)),
         _indented(_lines(built.events, label)),
         _indented(_warning_lines(built.warnings)))
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

# --- the REPL forms ---------------------------------------------------------------

for T in (Structure, Dataflow, Events, Schedule, Build, Deployment)
    @eval Base.show(io::IO, ::MIME"text/plain", x::$T) = join(io, _lines(x), "\n")
end
