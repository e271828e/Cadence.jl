#!/bin/sh
# Applies the report's §3 patch to a scratch export of 82c23d5: run it from
# the export's root. Round 1 is the first ten signatures, round 2 the next
# eleven. Never run against the repository itself.
set -e
sed -i '' \
 -e 's/^function _walk!(draft::StructureDraft, path::String, comp, scope::Timing,$/function _walk!(draft::StructureDraft, path::String, @nospecialize(comp), scope::Timing,/' \
 -e 's/^function _children(path::String, comp)$/function _children(path::String, @nospecialize(comp))/' \
 -e 's/^children(path::String, comp) = /children(path::String, @nospecialize(comp)) = /' \
 -e 's/^function classify(path::String, comp)$/function classify(path::String, @nospecialize(comp))/' \
 -e 's/^function _check_transparent(path::String, comp, transparent_field, diags::Vector{Diagnostic})$/function _check_transparent(path::String, @nospecialize(comp), transparent_field, diags::Vector{Diagnostic})/' \
 -e 's/^function leaf_declarations(comp)$/function leaf_declarations(@nospecialize(comp))/' \
 -e 's/^function declarations_found(comp)$/function declarations_found(@nospecialize(comp))/' \
 -e 's/^_is_container(v) = /_is_container(@nospecialize(v)) = /' \
 -e 's/^function _walked_faces(comp, side::Int, fn, face_of)$/function _walked_faces(@nospecialize(comp), side::Int, fn, face_of)/' \
 -e 's/^function resolve_source(draft, entry::String, base::String, assembly, path::AbstractString,$/function resolve_source(draft, entry::String, base::String, @nospecialize(assembly), path::AbstractString,/' \
 -e 's/^function resolve_dest(draft, entry::String, base::String, assembly, path::AbstractString,$/function resolve_dest(draft, entry::String, base::String, @nospecialize(assembly), path::AbstractString,/' \
 -e 's/^_fanout(draft, entry, base, comp, inner, diags) =$/_fanout(draft, entry, base, @nospecialize(comp), inner, diags) =/' src/assembly.jl
sed -i '' \
 -e 's/^function invoke_declaration(fn, comp, args...)$/function invoke_declaration(fn, @nospecialize(comp), args...)/' \
 -e 's/^function classify_tier(path::String, comp, diags::Vector{Diagnostic})$/function classify_tier(path::String, @nospecialize(comp), diags::Vector{Diagnostic})/' \
 -e 's/^function check_store_form(path::String, comp, diags::Vector{Diagnostic})$/function check_store_form(path::String, @nospecialize(comp), diags::Vector{Diagnostic})/' \
 -e 's/^function check_stores(path::String, comp, diags::Vector{Diagnostic})$/function check_stores(path::String, @nospecialize(comp), diags::Vector{Diagnostic})/' \
 -e 's/^function check_state_leaves(path::String, comp, diags::Vector{Diagnostic})$/function check_state_leaves(path::String, @nospecialize(comp), diags::Vector{Diagnostic})/' \
 -e 's/^function declarations(comp, tier::Tier, ::Type{T}) where {T}$/function declarations(@nospecialize(comp), tier::Tier, ::Type{T}) where {T}/' \
 -e 's/^_workspace(path::String, comp, tier::Tier, ::Type{T}) where {T} =$/_workspace(path::String, @nospecialize(comp), tier::Tier, ::Type{T}) where {T} =/' src/build.jl
sed -i '' \
 -e 's/^function foreign_declarations(comp)$/function foreign_declarations(@nospecialize(comp))/' \
 -e 's/^function declared_at(fn, comp, tier::Tier, ::Type{S} = Float64) where {S}$/function declared_at(fn, @nospecialize(comp), tier::Tier, ::Type{S} = Float64) where {S}/' src/declare.jl
grep -c nospecialize src/assembly.jl src/build.jl src/declare.jl
