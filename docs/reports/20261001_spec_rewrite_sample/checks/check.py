"""Mechanical no-loss check of a §9.4 rewrite against the original.

Run from the report root:  python3 checks/check.py versions/v4_flat.md 4 [--bold]
The digit picks checks/inventoryN.py, the claim inventory for that version.
"""
import collections, importlib, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from norm import norm, units, render
new_path, n = sys.argv[1], sys.argv[2]
inv = importlib.import_module(f"inventory{n}"); C, ADDED = inv.C, inv.ADDED
old_raw = open(os.path.join(HERE, "..", "versions", "v0_spec.md")).read()
new_raw = open(new_path).read()
O, N, NU = norm(old_raw), norm(new_raw), units(new_raw)
bad = 0
# 1. Old spans exist and together cover every content word.
cov = [False] * len(O)
for cid, o, *_ in C:
    i = O.find(o)
    if i < 0: print("OLD SPAN MISSING", cid); bad += 1; continue
    for k in range(i, i + len(o)): cov[k] = True
STOP = set("a an the and or of to in at is are it its as by for on with be not no so".split())
gaps = [m.group() for m in re.finditer(r"[A-Za-z0-9_§'][A-Za-z0-9_§'\-]*", O)
        if not all(cov[m.start():m.end()]) and m.group().lower() not in STOP]
print("uncovered content words:", gaps or "none"); bad += bool(gaps)
# 2. New spans exist, and each claim's citations sit in the same paragraph or bullet.
cre = re.compile(r'§\d+(?:\.\d+)?|D-\d{3}')
for cid, o, n_, cites, tag, *rest in C:
    us = [u for u in NU if n_ in u]
    if not us: print("NEW SPAN MISSING", cid, repr(n_)); bad += 1; continue
    if set(cre.findall(o)) != set(cites): print("OLD CITES MISDECLARED", cid); bad += 1
    if not set(rest[0] if rest else cites) <= set(cre.findall(us[0])): print("CITE NOT IN UNIT", cid); bad += 1
for a in ADDED:
    if a not in N: print("ADDED MISSING", a); bad += 1
# 3. Multisets of code spans, citations and glossary links.
def code(t): return collections.Counter(re.findall(r'`([^`]+)`', render(t)))
def cites(t): return collections.Counter(cre.findall(norm(t)))
def gl(t): return collections.Counter(re.findall(r'\]\((#g-[^)]+)\)', t))
for name, f in [("code spans", code), ("citations", cites), ("glossary links", gl)]:
    a, b = f(old_raw), f(new_raw)
    print(f"{name}: lost {dict(a - b) or '{}'} gained {dict(b - a) or '{}'}")
# 4. With --bold, every bold span is followed by a D-citation.
if "--bold" in sys.argv:
    for m in re.finditer(r'\*\*(.+?)\*\*(?=(.{0,40}))', re.sub(r'\s+', ' ', new_raw)):
        c = re.findall(r'D-\d{3}', render(m.group(1) + m.group(2)))
        print(("ok  " if c else "BOLD WITHOUT D-CITE  ") + render(m.group(1))[:70], c); bad += not c
print("checks failed:", bad)
