import re,sys
def sections(path):
    secs={}; cur='§8'; buf=[]
    for line in open(path):
        m=re.match(r'^### (8\.\d)',line)
        if m:
            secs[cur]=''.join(buf); cur='§'+m.group(1); buf=[]
        buf.append(line)
    secs[cur]=''.join(buf)
    secs['§8all']=open(path).read()
    return secs
OLD=sections('chapter_old.md'); NEW=sections('chapter_new.md')
