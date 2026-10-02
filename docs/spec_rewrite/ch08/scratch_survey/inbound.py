import re, glob, os
ROOT = "/Users/miguel/.julia/dev/Cadence.jl/docs/design"
files = ["spec.md", "decisions.md", "extensions.md", "implementation.md", "pending.md"] + \
        sorted(os.path.relpath(p, ROOT) for p in glob.glob(ROOT + "/companions/*.md"))
PAT = re.compile(r"§8(?:\.[0-9]+)?(?![0-9])")
ANCH = re.compile(r"#8[0-9]-[a-z0-9-]+")
FIELD = re.compile(r"^\*\*(Status|Position|Spec|Rationale|Rejected|Divergence)\.\*\*")
SEC = {"#81":"§8.1","#82":"§8.2","#83":"§8.3","#84":"§8.4","#85":"§8.5","#86":"§8.6","#87":"§8.7","#88":"§8.8"}

def para_bounds(lines, i):
    def is_start(l):
        s = l.lstrip()
        return s.startswith(("- ", "* ", "|", "#", "```", ">")) or re.match(r"^\d+\. ", s)
    a = i
    while a > 0 and lines[a-1].strip() and not is_start(lines[a]):
        a -= 1
    b = i
    while b + 1 < len(lines) and lines[b+1].strip() and not is_start(lines[b+1]):
        b += 1
    return a, b

def sentence(lines, i, col):
    a, b = para_bounds(lines, i)
    text, off = "", 0
    for j in range(a, b + 1):
        if j == i: off = len(text) + col
        text += lines[j].strip() + " "
    # sentence boundaries: ". " followed by capital/backtick/bracket, outside obvious abbreviations
    starts = [0] + [m.end() for m in re.finditer(r"(?<!e\.g)(?<!i\.e)(?<!vs)\.\s+(?=[A-Z`*\[(])", text)]
    s = max(x for x in starts if x <= off)
    ends = [m.end() for m in re.finditer(r"\.\s+(?=[A-Z`*\[(])|\.\s*$", text) if m.end() > off]
    e = min(ends) if ends else len(text)
    return re.sub(r"\s+", " ", text[s:e]).strip().replace("\t", " ")

rows = []
for f in files:
    lines = open(os.path.join(ROOT, f)).read().split("\n")
    entry, field = "", ""
    for i, l in enumerate(lines):
        n = i + 1
        if f == "decisions.md":
            m = re.match(r"^### (D-\d{3})", l)
            if m: entry, field = m.group(1), "heading"
            m2 = FIELD.match(l)
            if m2: field = m2.group(1)
            if l.startswith("Annotation"): field = "Annotation"
        if re.match(r"^\[s[0-9A-D]", l):   # link definitions
            continue
        if f == "spec.md" and (1901 <= n <= 3390 or 40 <= n <= 116 and l.lstrip().startswith("- [")):
            continue
        for m in list(PAT.finditer(l)) + list(ANCH.finditer(l)):
            cited = m.group(0)
            if cited.startswith("#"):
                cited = SEC.get(cited[:3], cited)
            e, fl = "", ""
            if f == "decisions.md":
                if n < 323:
                    mm = re.search(r"\[(D-\d{3})\]", l); e, fl = (mm.group(1) if mm else ""), "index"
                else:
                    e, fl = entry, field
            rows.append((f, n, cited, e, fl, sentence(lines, i, m.start())))
with open("/Users/miguel/.julia/dev/Cadence.jl/docs/spec_rewrite/ch08/inbound.tsv", "w") as out:
    out.write("file\tline\tcited\tentry\tfield\tsentence\n")
    for r in rows:
        out.write("\t".join(str(x) for x in r) + "\n")
print(len(rows))
