#!/bin/zsh
# Render a chapter's original and its rewrite with design.pdf's settings into
# <chapter dir>/chapter.pdf (untracked), followed by each EXTRA file.
# Links inside the excerpt keep their look but go nowhere.
# Usage: checks/build_pdf.sh <chapter dir>
H=${0:A:h}; C=${1:A}; D=${H:h:h}/design
source $C/chapter.sh
$H/assemble.sh $C
extra=(${EXTRA/#/$C/})
pb() { printf '\n```{=typst}\n#pagebreak()\n```\n\n'; }
{
echo "# Chapter $NUM: the spec at $BASE"; echo; cat $C/chapter_old.md; pb
echo "# Chapter $NUM: rewritten"; echo; cat $C/chapter_new.md
for f in $extra; do pb; echo "# Moved out of the chapter: ${f:t}"; echo; cat $f; echo; done
rg '^\[[a-zA-Z0-9-]+\]: ' $D/spec.md
# D-entries the spec never cited before have no definition there yet; linkify.jl
# adds them on landing, so define every one the excerpt uses and the spec lacks.
for d in $(rg -o '\]\[d-[0-9]{3}\]' -N $C/chapter_new.md $extra | rg -o 'd-[0-9]{3}' | sort -u); do
  rg -q "^\[$d\]:" $D/spec.md || echo "[$d]: decisions.md#$d"
done
} > $C/chapter.md
cd $D/pdf && pandoc -d pdf.yaml -f gfm+tex_math_dollars+raw_attribute -L $H/deadlinks.lua \
  --pdf-engine-opt=--input=theme=gallery/themes/cadence.tmTheme $C/chapter.md -o $C/chapter.pdf
rm $C/chapter.md
