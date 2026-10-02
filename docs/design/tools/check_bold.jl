#!/usr/bin/env julia
#
# Bold-ruling checker for the chapters of spec.md the readability rewrite has
# reached (`tools/spec_style.md`, "Marking rulings"). Over each chapter in
# `REWRITTEN` it errors on:
#
#   - an old **Rule.**, **Why.** or **Example.** label;
#   - a bold span with no D-citation after it in the rest of its sentence.
#
# A sentence ends at a period followed by a space or the end of its paragraph,
# bullet or table row. Fenced code is skipped. The check cannot see whether a
# bold span is a ruling, or the right one; the rewrite's verifiers judge that.
# It prints each chapter's bold weight in words as an advisory.
#
# A chapter joins `REWRITTEN` when its rewrite lands (docs/spec_rewrite/).
#
# Usage:  julia docs/design/tools/check_bold.jl

const SPEC = normpath(joinpath(@__DIR__, "..", "spec.md"))

const REWRITTEN = [7, 8, 9, 10]

const LABEL = r"\*\*(Rule|Why|Example)\.\*\*"
const BOLD = r"\*\*(.+?)\*\*"
const DCITE = r"D-\d{3}"

"Visible text of a markdown fragment: link markup collapsed, emphasis dropped."
render(s) = replace(s, r"\[([^\]]+)\]\[[^\]]*\]" => s"\1",
                    r"\[([^\]]+)\]\([^)]*\)" => s"\1", "*" => "")

"The chapter's lines outside code fences, with their line numbers."
function chapter(lines, n)
    i = findfirst(startswith("## $n. "), lines)
    i === nothing && error("chapter $n heading not found")
    out = Tuple{Int,String}[]
    fenced = false
    for k in i+1:length(lines)
        l = lines[k]
        startswith(l, "```") && (fenced = !fenced; continue)
        fenced && continue
        (startswith(l, "# ") || occursin(r"^## (\d+\.|Appendix)", l)) && break
        push!(out, (k, l))
    end
    return out
end

"Split into paragraphs, bullets and table rows, each with its first line number."
function units(chlines)
    out = Tuple{Int,String}[]
    cur, start = String[], 0
    flush() = (isempty(cur) || push!(out, (start, join(cur, " "))); empty!(cur))
    for (k, l) in chlines
        if isempty(strip(l)) || startswith(l, "#")
            flush()
        elseif startswith(l, "|") || occursin(r"^\s*(-|\d+\.) ", l)
            flush(); push!(cur, l); start = k
            startswith(l, "|") && flush()
        else
            isempty(cur) && (start = k)
            push!(cur, l)
        end
    end
    flush()
    return out
end

function main()
    lines = readlines(SPEC)
    bad = 0
    for n in REWRITTEN
        spans = words = 0
        for (k, u) in units(chapter(lines, n))
            for m in eachmatch(LABEL, u)
                println("spec.md:$k: old label $(m.match) in rewritten chapter $n")
                bad += 1
            end
            for m in eachmatch(BOLD, u)
                spans += 1
                words += length(split(render(m[1])))
                rest = u[m.offset+ncodeunits(m.match):end]
                e = findfirst(r"\.(\s|$)", rest)
                sentence = e === nothing ? rest : rest[1:first(e)]
                if !occursin(DCITE, sentence)
                    println("spec.md:$k: bold without a D-citation in its sentence: ",
                            first(render(m[1]), 70))
                    bad += 1
                end
            end
        end
        println("chapter $n: $spans bold spans, $words bold words")
    end
    if bad == 0
        println("OK — every bold span in a rewritten chapter carries its D-citation.")
    else
        println("$bad problem(s).")
        exit(1)
    end
end

main()
