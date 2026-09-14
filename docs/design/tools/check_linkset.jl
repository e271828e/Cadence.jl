#!/usr/bin/env julia
#
# Link-set stability checker for one `###` section of spec.md (rewrite plan).
#
# The rewrite touches a section's prose but must leave its link set alone: the
# same section citations, decision citations and glossary anchors it cited
# before, just possibly reworded around them. This tool snapshots that set
# before a section is rewritten and diffs against it afterwards, so a rewrite
# that quietly drops or adds a reference gets caught even though check_refs.jl
# and check_glossary.jl (which check resolution, not stability) still pass.
#
# A section's link set has three kinds of member, found by regex over its raw
# text (fenced code included — the set is meant to be exhaustive, and a
# citation inside a sketch is still a citation):
#
#   - section citations: reference-style labels `[sN-M]` (`[s11-4]`) and the
#     chapter-level form `[sN]` (`[s10]`), both in use in spec.md;
#   - decision citations: reference-style labels `[d-nnn]` (`[d-179]`);
#   - glossary anchors: `#g-…` link targets (`(#g-guard)`).
#
# Two modes:
#
#   save  <heading-prefix> <baseline-file>   write the current link set
#   check <heading-prefix> <baseline-file>   diff the current link set against it
#
# `<heading-prefix>` selects the section: the text a `###` heading line must
# start with (e.g. `### 10.4`). The section runs from that heading to the next
# `#`, `##` or `###` heading, exclusive. Lines inside fenced code blocks never
# end a section: a `# comment` line in a sketch is not a heading.
#
# `--file <path>` overrides the file scanned (default: spec.md next to this
# script) — e.g. to point at a pilot rewrite draft under docs/design/briefs/
# for the same section before it lands.
#
# Usage:  julia docs/design/tools/check_linkset.jl save  "### 10.4" baseline.txt
#         julia docs/design/tools/check_linkset.jl check "### 10.4" baseline.txt
#         julia docs/design/tools/check_linkset.jl check "### 10.4" baseline.txt --file docs/design/briefs/spec_rewrite_pilot.md
# Exits nonzero (check mode) if any of the three sets changed.

const DESIGN = normpath(joinpath(@__DIR__, ".."))
const DEFAULT_SPEC = joinpath(DESIGN, "spec.md")

const SLABEL = r"\[s\d+(?:-\d+)?\]"
const DLABEL = r"\[d-\d+\]"
const GANCHOR = r"#g-[a-z0-9-]+"

"The three link-set member kinds, in the order saved and printed."
const KINDS = (:section, :decision, :glossary)

"Sets of distinct citation/anchor strings in `text`, one per kind."
linksets(text) = (
    section = Set(m.match for m in eachmatch(SLABEL, text)),
    decision = Set(m.match for m in eachmatch(DLABEL, text)),
    glossary = Set(m.match for m in eachmatch(GANCHOR, text)),
)

"Text of the `###` section in `path` whose heading starts with `prefix`, up to
the next `#`, `##` or `###` heading (or EOF)."
function section_text(path, prefix)
    lines = readlines(path)
    starts = findall(l -> startswith(l, prefix), lines)
    isempty(starts) &&
        error("no heading in $path starts with $(repr(prefix))")
    length(starts) > 1 &&
        error("heading prefix $(repr(prefix)) is ambiguous in $path: matches lines $starts")
    start = starts[1]
    stop = length(lines) + 1
    fence = false
    for i in start+1:length(lines)
        startswith(lines[i], "```") && (fence = !fence; continue)
        fence && continue
        occursin(r"^#{1,3}\s", lines[i]) && (stop = i; break)
    end
    return join(lines[start:stop-1], "\n")
end

"Write `sets` (a `linksets` result) to `path`, one \"<kind> <member>\" line per
member, sorted within each kind for a stable, diffable file."
function save_baseline(path, sets)
    open(path, "w") do io
        for kind in KINDS
            for member in sort!(collect(getfield(sets, kind)))
                println(io, "$kind $member")
            end
        end
    end
end

"Read a baseline written by `save_baseline` back into a `linksets`-shaped
named tuple of sets."
function read_baseline(path)
    d = Dict(kind => Set{String}() for kind in KINDS)
    for line in eachline(path)
        isempty(line) && continue
        kind, member = split(line, ' '; limit=2)
        push!(d[Symbol(kind)], member)
    end
    return (; (kind => d[kind] for kind in KINDS)...)
end

"Parse ARGS into (mode, prefix, baseline, file), file `nothing` unless --file
was given."
function parse_args(args)
    args = collect(args)
    file = nothing
    i = findfirst(==("--file"), args)
    if i !== nothing
        i == length(args) && error("--file needs a path")
        file = args[i+1]
        deleteat!(args, i:i+1)
    end
    length(args) == 3 ||
        error("usage: check_linkset.jl <save|check> <heading-prefix> <baseline-file> [--file path]")
    mode, prefix, baseline = args
    mode in ("save", "check") ||
        error("mode must be 'save' or 'check', got $(repr(mode))")
    return mode, prefix, baseline, file
end

function main(args)
    mode, prefix, baseline, file = parse_args(args)
    path = file === nothing ? DEFAULT_SPEC : file
    isfile(path) || error("no such file: $path")
    sets = linksets(section_text(path, prefix))

    if mode == "save"
        save_baseline(baseline, sets)
        println("saved baseline for $(repr(prefix)) to $baseline (",
                join(("$(length(getfield(sets, k))) $k" for k in KINDS), ", "), ")")
        return 0
    end

    isfile(baseline) || error("no such baseline file: $baseline")
    base = read_baseline(baseline)
    ok = true
    for kind in KINDS
        cur, old = getfield(sets, kind), getfield(base, kind)
        missing = sort!(collect(setdiff(old, cur)))
        added = sort!(collect(setdiff(cur, old)))
        if isempty(missing) && isempty(added)
            println("  ", kind, ": unchanged (", length(cur), ")")
        else
            ok = false
            println("  ", kind, ": CHANGED")
            isempty(missing) || println("    missing: ", join(missing, ", "))
            isempty(added) || println("    added:   ", join(added, ", "))
        end
    end
    println(ok ? "OK — link set for $(repr(prefix)) unchanged." :
                 "FAIL — link set for $(repr(prefix)) changed.")
    return ok ? 0 : 1
end

exit(main(ARGS))
