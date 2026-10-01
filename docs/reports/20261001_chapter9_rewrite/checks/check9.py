"""Mechanical no-loss check for one unit of the chapter 9 rewrite.

Run from the report root (docs/reports/20261001_chapter9_rewrite):

    python3 checks/check9.py show-old A1   # the unit's original, normalized
    python3 checks/check9.py show-new A1   # the rewrite, one paragraph per line
    python3 checks/check9.py check A1      # the checks

Normalized text collapses link markup to its visible text, drops * and **,
turns fenced code into `code`, and collapses whitespace. Every span in
units/<U>/inventory.json is written in that form.
"""
import collections, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                       # the report directory
REPO = os.path.abspath(os.path.join(ROOT, "..", "..", ".."))
sys.path.insert(0, HERE)
from norm import norm, units, render

STOP = set("a an the and or of to in at is are it its as by for on with be not no so".split())
WORD = re.compile(r"[A-Za-z0-9_§'][A-Za-z0-9_§'\-]*")
CITE = re.compile(r'§\d+(?:\.\d+)?|D-\d{3}|Appendix [A-D]')


def read(path):
    for base in (ROOT, REPO):
        p = os.path.join(base, path)
        if os.path.exists(p):
            return open(p).read()
    raise FileNotFoundError(path)


def uncovered(text, spans):
    cov = [False] * len(text)
    for s in spans:
        start = 0
        while (i := text.find(s, start)) >= 0:
            for k in range(i, i + len(s)): cov[k] = True
            start = i + 1
    return [m.group() for m in WORD.finditer(text)
            if not all(cov[m.start():m.end()]) and m.group().lower() not in STOP]


def check(u):
    old_raw = read(f"units/{u}/old.md"); new_raw = read(f"units/{u}/new.md")
    inv = json.load(open(os.path.join(ROOT, "units", u, "inventory.json")))
    C, ADDED = inv["claims"], inv.get("added", [])
    O, N, NU = norm(old_raw), norm(new_raw), units(new_raw)
    bad = 0
    # 1. Old spans exist, and together they cover every content word.
    for c in C:
        if c["old"] not in O: print("OLD SPAN NOT IN OLD TEXT", c["id"]); bad += 1
    gaps = uncovered(O, [c["old"] for c in C])
    print("old words no claim covers:", gaps or "none"); bad += bool(gaps)
    # 2. New spans exist where the claim says; citations sit with the claim.
    for c in C:
        where = c.get("where", "new")
        if where == "new":
            us = [x for x in NU if c["new"] in x]
            if not us: print("NEW SPAN MISSING", c["id"], repr(c["new"][:70])); bad += 1; continue
            want = set(c.get("newcites", c["cites"]))
            if not want <= set(CITE.findall(us[0])):
                print("CITATION NOT WITH ITS CLAIM", c["id"], sorted(want - set(CITE.findall(us[0])))); bad += 1
        else:
            try:
                if c["new"] not in norm(read(where)): print("SPAN MISSING AT", where, c["id"]); bad += 1
            except FileNotFoundError:
                print("NO SUCH FILE", where, c["id"]); bad += 1
        if set(CITE.findall(c["old"])) != set(c["cites"]):
            print("OLD CITATIONS MISDECLARED", c["id"]); bad += 1
    for a in ADDED:
        if a not in N: print("ADDED SPAN MISSING", repr(a[:70])); bad += 1
    # 3. Every word of the new text is accounted for by a claim or a declared addition.
    gaps = uncovered(N, [c["new"] for c in C if c.get("where", "new") == "new"] + ADDED)
    print("new words no claim or addition covers:", gaps or "none"); bad += bool(gaps)
    # 4. What moved: citations, code spans and glossary links, old against new.
    def code(t): return collections.Counter(re.findall(r'`([^`]+)`', render(t)))
    def cites(t): return collections.Counter(CITE.findall(norm(t)))
    def gl(t): return collections.Counter(re.findall(r'\]\((#g-[^)]+)\)', t))
    for name, f in [("citations", cites), ("code spans", code), ("glossary links", gl)]:
        a, b = f(old_raw), f(new_raw)
        print(f"{name}: only in old {dict(a - b) or '{}'} | only in new {dict(b - a) or '{}'}")
    # 5. Every bold span is a rule, and a D-citation follows it within its sentence.
    flat = re.sub(r'\s+', ' ', new_raw); n = 0
    for m in re.finditer(r'\*\*(.+?)\*\*', flat):
        n += 1
        rest = flat[m.end():]; end = re.search(r'\.(\s|$)', rest)
        if not re.findall(r'D-\d{3}', render(rest[: end.start() + 1] if end else rest)):
            print("BOLD WITHOUT D-CITATION:", render(m.group(1))[:70]); bad += 1
    print("bold spans:", n, "| headings:", re.findall(r'^#{2,4} .*', new_raw, re.M))
    print("checks failed:", bad)
    return bad


if __name__ == "__main__":
    cmd, u = sys.argv[1], sys.argv[2]
    if cmd == "show-old": print(norm(read(f"units/{u}/old.md")))
    elif cmd == "show-new": print("\n\n".join(units(read(f"units/{u}/new.md"))))
    else: sys.exit(1 if check(u) else 0)
