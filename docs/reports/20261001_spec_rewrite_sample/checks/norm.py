import re
def render(t):
    t=re.sub(r'\[([^\]]+)\]\(#[^)]*\)',r'\1',t)
    t=re.sub(r'\[([^\]]+)\]\[[^\]]*\]',r'\1',t)
    t=re.sub(r'```julia\n(.*?)\n```',r'`\1`',t,flags=re.S)
    return t.replace('*','')
def norm(t): return re.sub(r'\s+',' ',render(t)).strip()
def units(t):
    out=[]
    for para in re.split(r'\n\s*\n',t):
        parts=re.split(r'\n(?=- )',para)
        out+= [norm(p) for p in parts if p.strip()]
    return out
