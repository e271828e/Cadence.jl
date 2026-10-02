import re,sys
def secs(path):
    out={}; cur='7'
    for line in open(path):
        m=re.match(r'### (7\.\d)',line)
        if m: cur=m.group(1)
        for d in re.findall(r'\[D-(\d+)\]',line):
            out.setdefault(cur,set()).add(int(d))
    return out
o=secs('chapter_old.md'); n=secs('chapter_new.md')
for s in sorted(set(o)|set(n)):
    print(s,'old',sorted(o.get(s,[])))
    print(s,'new',sorted(n.get(s,[])))
