"""Rewrap a paragraph or list item to 80 columns, or scan for long and short lines.

    python3 wrap.py scan FILE            # lines over 80 rendered columns, and short lines
    python3 wrap.py wrap FILE SNIPPET    # rewrap the block holding the first line with SNIPPET
"""
import re, sys

LINK = re.compile(r'\[[^\]]+\](?:\([^)]*\)|\[[^\]]*\])|`[^`]+`')
ITEM = re.compile(r'^(\s*(?:- |\d+\. ))')


def rendered(s):
    s = re.sub(r'\[([^\]]+)\]\(#[^)]*\)', r'\1', s)
    s = re.sub(r'\[([^\]]+)\]\[[^\]]*\]', r'\1', s)
    return s.replace('*', '').replace('`', '')


def tokens(text):
    text = LINK.sub(lambda m: m.group().replace(' ', '\0'), text)
    return [t.replace('\0', ' ') for t in text.split()]


def fill(toks, first, cont):
    lines, cur = [], first
    for t in toks:
        if cur == first or cur.strip() == "":
            cur += t; continue
        cand = cur + " " + t
        if len(cand) <= 80 or (len(rendered(cand)) <= 78 and len(cand) <= 120):
            cur = cand
        else:
            lines.append(cur); cur = cont + t
    lines.append(cur)
    return lines


def block(lines, i):
    def boundary(l):
        return l.strip() == "" or l.startswith("```") or l.startswith("#") or l.startswith("|")
    s = i
    while s > 0 and not boundary(lines[s - 1]) and not ITEM.match(lines[s]):
        s -= 1
    e = i
    while e + 1 < len(lines) and not boundary(lines[e + 1]) and not ITEM.match(lines[e + 1]):
        e += 1
    return s, e


def main():
    cmd, path = sys.argv[1], sys.argv[2]
    lines = open(path).read().split("\n")
    if cmd == "scan":
        fence = False
        for n, l in enumerate(lines, 1):
            if l.startswith("```"): fence = not fence; continue
            if fence or l.startswith("|"): continue
            r = len(rendered(l))
            nxt = lines[n] if n < len(lines) else ""
            short = (r < 55 and nxt.strip() and not nxt.startswith(("```", "#", "|", "- "))
                     and not ITEM.match(nxt) and len(nxt.split()[0]) + r + 1 <= 80)
            if r > 80: print(f"{n}: LONG {r}: {l}")
            elif short: print(f"{n}: SHORT {r}: {l}")
        for n in range(1, len(lines)):
            if lines[n - 1].strip() == "" and lines[n].strip() == "" and n > 1:
                print(f"{n}: DOUBLE BLANK")
        return
    snip = sys.argv[3]
    i = next(k for k, l in enumerate(lines) if snip in l)
    s, e = block(lines, i)
    m = ITEM.match(lines[s])
    first = m.group(1) if m else ""
    cont = " " * len(first) if m else ""
    text = " ".join(l.strip() for l in lines[s:e + 1])
    if m: text = text[len(first.strip()):].strip()
    new = fill(tokens(text), first, cont)
    lines[s:e + 1] = new
    open(path, "w").write("\n".join(lines))
    print(f"rewrapped {s + 1}-{e + 1} into {len(new)} lines")
    for l in new: print("  ", len(rendered(l)), l)


main()
