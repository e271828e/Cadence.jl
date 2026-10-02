#!/bin/zsh
# words per subheading block of spec.md lines 1901-3390
f=/Users/miguel/.julia/dev/Cadence.jl/docs/design/spec.md
starts=($(awk 'NR>=1901 && NR<=3390 && /^#{2,4} / {print NR}' $f) 3391)
for ((i=1; i<${#starts}; i++)); do
  a=${starts[i]}; b=$((starts[i+1]-1))
  printf "%d-%d\t%s\t%s\n" $a $b "$(sed -n ${a},${b}p $f | wc -w | tr -d ' ')" "$(sed -n ${a}p $f)"
done
