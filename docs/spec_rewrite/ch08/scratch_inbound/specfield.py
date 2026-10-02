import csv,re,sys
sys.path.insert(0,'scratch_inbound')
from sec import OLD,NEW
rows=list(csv.reader(open('inbound.tsv'),delimiter='\t'))[1:]
for i,r in enumerate(rows,1):
    f,l,c,e,fld=r[:5]
    if f=='decisions.md' and e:
        tag='['+e.lower()+']'
        o=tag in OLD.get(c,'') if c!='§8' else tag in OLD['§8all']
        n=tag in NEW.get(c,'') if c!='§8' else tag in NEW['§8all']
        others=[s for s in NEW if s not in('§8all','§8') and tag in NEW[s]]
        print(i,l,c,e,fld,'old' if o else '-','new' if n else '-','newsecs=',','.join(others))
