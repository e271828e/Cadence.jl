"""Check a bold-only edit: python3 checks/boldcheck.py <U>

With every ** removed, units/<U>/new.md must equal units/<U>/new_pretrim.md.
Every bold span must be followed, within the rest of its sentence, by a
D-citation. Prints each bold span with its length in words.
"""
import re, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
u = sys.argv[1]
new = open(f"{ROOT}/units/{u}/new.md").read()
pre = open(f"{ROOT}/units/{u}/new_pretrim.md").read()
bad = 0
if new.replace("**", "") != pre.replace("**", ""):
    print("TEXT CHANGED beyond bold markers"); bad += 1
flat = re.sub(r"\s+", " ", new)
words = 0
for m in re.finditer(r"\*\*(.+?)\*\*", flat):
    rest = flat[m.end():]
    end = re.search(r"\.(\s|$)", rest)
    sentence_rest = rest[: end.start() + 1] if end else rest
    vis = re.sub(r"\]\[[^\]]*\]|\]\([^)]*\)|\[", "", m.group(1))
    n = len(vis.split()); words += n
    ok = re.search(r"D-\d{3}", sentence_rest)
    print(("ok " if ok else "NO D-CITATION IN SENTENCE ") + f"[{n}w] " + vis[:80])
    bad += not ok
print("bold words:", words, "| checks failed:", bad)
