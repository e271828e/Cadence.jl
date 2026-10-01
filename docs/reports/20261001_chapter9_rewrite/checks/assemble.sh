#!/bin/zsh
# Assemble the rewritten chapter from its units, and the original beside it.
R=${0:A:h:h}; D=${R:h:h}/design
V4=$R/units/S94/new.md
for f in units/A1/new.md units/A2/new.md units/B/new.md $V4 units/C/new.md units/D/new.md units/E/new.md; do
  [[ $f = /* ]] && cat $f || cat $R/$f; echo
done > $R/chapter_new.md
sed -n 3391,4337p $D/spec.md > $R/chapter_old.md
