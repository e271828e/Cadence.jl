#!/bin/zsh
# Render every version with design.pdf's settings into samples.pdf at the report root.
R=${0:A:h:h}; D=${R:h:h}/design
pb() { printf '\n```{=typst}\n#pagebreak()\n```\n\n'; }
v() { echo "## $1"; echo; cat $R/versions/$2; pb; }
{
echo '# §9.4 rendering samples'; echo
v 'Version 0: the spec as of 2026-10-01' v0_spec.md
v 'Version 1: Rule/Why/Example labels' v1_labels.md
v 'Version 2: bold marks rules, no labels' v2_bold.md
v 'Version 3: bold rules with their D-entries' v3_cited.md
v 'Version 4: bold rules, no subheadings' v4_flat.md
v 'Version 5: written from the claim list alone' v5_from_claims.md
echo '## Draft log entries for versions 3 to 5'; echo; cat $R/versions/draft_entries.md; echo
rg '^\[[a-z0-9-]+\]: ' $D/spec.md
printf '[d-280]: decisions.md#d-280\n[d-281]: decisions.md#d-281\n[d-282]: decisions.md#d-282\n'
} > $R/samples.md
cd $D/pdf && pandoc -d pdf.yaml -f gfm+tex_math_dollars+raw_attribute -L $R/checks/deadlinks.lua \
  --pdf-engine-opt=--input=theme=gallery/themes/redstone.tmTheme $R/samples.md -o $R/samples.pdf
rm $R/samples.md
