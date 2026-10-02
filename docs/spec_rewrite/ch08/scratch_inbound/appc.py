import csv,re,sys
sys.path.insert(0,'scratch_inbound')
from sec import OLD,NEW
rows=list(csv.reader(open('inbound.tsv'),delimiter='\t'))[1:]
for i,r in enumerate(rows,1):
    f,l,c=r[0],int(r[1]),r[2]
    if f=='spec.md' and 11700<=l<=11995:
        kinds=re.findall(r'\*\*`(\w+)`\*\*',r[5])
        if not kinds:
            print(i,l,c,'NOKIND',r[5][:120]); continue
        k=kinds[0]
        o=k in OLD.get(c,''); n=k in NEW.get(c,'')
        where=[s for s in NEW if s!='§8all' and k in NEW[s]]
        print(i,l,c,k,'old' if o else '-', 'new' if n else '-', 'newsecs=',where)
