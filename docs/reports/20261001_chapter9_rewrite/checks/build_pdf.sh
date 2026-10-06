#!/bin/zsh
# Render the old and the rewritten chapter 9 with design.pdf's settings into
# chapter9.pdf (untracked). Links inside the excerpt keep their look but go nowhere.
R=${0:A:h:h}; D=${R:h:h}/design
$R/checks/assemble.sh
pb() { printf '\n```{=typst}\n#pagebreak()\n```\n\n'; }
{
echo '# Chapter 9: the spec as of 2026-10-01'; echo; cat $R/chapter_old.md; pb
echo '# Chapter 9: rewritten'; echo; cat $R/chapter_new.md; pb
echo '# Companion section moved out of §9.6'; echo; cat $R/units/D/companion_addition.md; echo
rg '^\[[a-zA-Z0-9-]+\]: ' $D/spec.md
# D-entries the spec never cited before have no definition there yet; linkify.jl
# adds them on landing, so define every one the excerpt uses and the spec lacks.
for d in $(rg -o '\]\[d-[0-9]{3}\]' -N $R/chapter_new.md $R/units/D/companion_addition.md | rg -o 'd-[0-9]{3}' | sort -u); do
  rg -q "^\[$d\]:" $D/spec.md || echo "[$d]: decisions.md#$d"
done
} > $R/chapter9.md
cd $D/pdf && pandoc -d pdf.yaml -f gfm+tex_math_dollars+raw_attribute -L $R/checks/deadlinks.lua \
  --pdf-engine-opt=--input=theme=gallery/themes/redstone.tmTheme $R/chapter9.md -o $R/chapter9.pdf
rm $R/chapter9.md
