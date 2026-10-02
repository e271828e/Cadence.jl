#!/bin/zsh
# Assemble a chapter's rewrite from its units into chapter_new.md, and its
# original, lines RANGE of spec.md at commit BASE, into chapter_old.md.
# Reads <chapter dir>/chapter.sh.
# Usage: checks/assemble.sh <chapter dir>
C=${1:A}; REPO=${0:A:h:h:h:h}
source $C/chapter.sh
for u in $UNITS; do cat $C/units/$u/new.md; echo; done > $C/chapter_new.md
git -C $REPO show $BASE:docs/design/spec.md | sed -n ${RANGE}p > $C/chapter_old.md
