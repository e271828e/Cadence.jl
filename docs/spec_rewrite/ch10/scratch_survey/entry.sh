#!/bin/zsh
# usage: entry.sh 017 [more ids] -- prints entries with log line numbers
LOG=/Users/miguel/.julia/dev/Cadence.jl/docs/design/decisions.md
for id in "$@"; do
  awk -v id="### D-$id " 'index($0,id)==1{p=1} p && /^### D-[0-9]/ && index($0,id)!=1{p=0} p && /^## /{p=0} p{printf "%d\t%s\n", NR, $0}' $LOG
  echo "-----"
done
