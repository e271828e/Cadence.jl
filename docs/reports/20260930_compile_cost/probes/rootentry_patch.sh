#!/bin/sh
# The root-entry variants of the report's §3, applied on top of
# nospecialize_patch.sh in a scratch export of 82c23d5: run it from the
# export's root with one argument. Never run against the repository itself.
#   dyn    the root reaches `_walk!` through dynamic dispatch
#   infer  `@nospecializeinfer` on `flatten!` and `_walk!`, `flatten!`'s root unspecialized
#   top    infer, plus the same on `build`
set -e
case "$1" in
dyn)
  sed -i '' -e 's/_walk!(draft, "", root, Timing/_walk!(draft, "", Base.inferencebarrier(root), Timing/' src/assembly.jl ;;
infer|top)
  sed -i '' \
   -e 's/^function flatten!(draft::StructureDraft, root, diags::Vector{Diagnostic})$/Base.@nospecializeinfer function flatten!(draft::StructureDraft, @nospecialize(root), diags::Vector{Diagnostic})/' \
   -e 's/^function _walk!(draft::StructureDraft, path::String, @nospecialize(comp), scope::Timing,$/Base.@nospecializeinfer function _walk!(draft::StructureDraft, path::String, @nospecialize(comp), scope::Timing,/' src/assembly.jl
  [ "$1" = top ] && sed -i '' \
   -e 's/^function build(root::AbstractComponent; activations::Tuple = ())$/Base.@nospecializeinfer function build(@nospecialize(root::AbstractComponent); activations::Tuple = ())/' src/build.jl ;;
*) echo "usage: $0 dyn|infer|top" >&2; exit 1 ;;
esac
grep -c 'nospecializeinfer\|inferencebarrier' src/assembly.jl src/build.jl
