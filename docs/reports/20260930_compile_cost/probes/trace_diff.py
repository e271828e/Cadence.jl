#!/usr/bin/env python3
"""Attribute the compile of one step: trace_diff.py before.txt after.txt [per_type]

Both files come from `julia --trace-compile=<file> --trace-compile-timing`;
`after` ran one more step than `before`. Prints the new roots grouped by
function, most expensive first, and the total, divided by `per_type` if given.
"""
import re, sys
def load(p):
    d = {}
    for line in open(p):
        m = re.match(r'#=\s*([\d.]+) ms =# (precompile\(.*)', line)
        if m: d[m.group(2)] = float(m.group(1))
    return d
def name(stmt):
    m = re.match(r'precompile\(Tuple\{typeof\(([^)]*)\)', stmt)
    if m: return m.group(1)
    m = re.match(r'precompile\(Tuple\{Type\{([^{},]*)', stmt)
    if m: return 'Type{' + m.group(1) + '}'
    m = re.match(r'precompile\(Tuple\{([A-Za-z_.!]+)', stmt)
    return m.group(1) if m else stmt[:50]
A, B = load(sys.argv[1]), load(sys.argv[2])
per = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
diff = {s: t for s, t in B.items() if s not in A}
tot = sum(diff.values()) / 1000
print(f'{len(diff)} new roots, {tot:.2f} s traced' + (f', {tot / per:.3f} s each' if per != 1 else ''))
by = {}
for s, t in diff.items():
    by.setdefault(name(s), [0, 0]); by[name(s)][0] += t; by[name(s)][1] += 1
for n, (t, c) in sorted(by.items(), key=lambda kv: -kv[1][0])[:20]:
    print(f'   {t / 1000:6.2f} s {c:4d}x  {n}')
