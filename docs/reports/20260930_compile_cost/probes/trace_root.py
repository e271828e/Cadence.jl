#!/usr/bin/env python3
"""Compile roots of a roottrace.jl trace, from the first naming the 64-loop
type on, at or above a threshold in ms: trace_root.py <trace> [threshold]."""
import re, sys
lines = open(sys.argv[1]).read().splitlines()
floor = float(sys.argv[2]) if len(sys.argv) > 2 else 40.0
start = next(k for k, l in enumerate(lines)
             if ':m64' in l and 'Group{C, W' not in l and 'many' not in l)
total = 0.0
for l in lines[start:]:
    m = re.match(r'#=\s*([\d.]+)\s*ms\s*=#\s*precompile\(Tuple\{(.*)', l)
    if not m or 'temp_cleanup' in l or 'profile_listener' in l:
        continue
    t = float(m.group(1)); total += t
    if t >= floor:
        s = re.sub(r'Redstone\.|Base\.|typeof\(|\)', '', m.group(2))
        s = re.sub(r'NamedTuple\{\(:m1, :m2.*', '<the 64-loop children>', s)
        print(f"{t:8.0f} ms  {s[:110]}")
print(f"total from the first 64-loop root on: {total/1000:.2f} s")
