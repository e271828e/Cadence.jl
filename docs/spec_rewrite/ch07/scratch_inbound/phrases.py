import re
def norm(p): return re.sub(r'\s+',' ',open(p).read())
new=norm('chapter_new.md'); old=norm('chapter_old.md')
ph=["buffer-unchanged-within-a-sweep","the explicit cast","explicit, invariant-free cast","domain wrapper type","of a common eltype `T`","the CI invariant","CI invariant","the discrete exemption","stay `Float64`","promotion handles mixing","the canary","a documented tolerance","interned, immutable and never freed","governed by contract rather than by checks","no `::SomeType{Float64}` annotations","no `::SomeType{Float64}`","framework side","carve-out","stopped-sim","stepping loop","allocation-tolerant","topological necessity","layout image","not memory","one-line function body","integrator's buffers","mid-step table","zero(T)","walked payload","about 25","FrameTransform","@kwdef` defaults pin the no-argument case","IllegalStateLeaf","IllegalStoreField","IllegalPortType","no pinned","rebuild-per-call","rebuilt per call","No store ever mirrors","holds `x`","sizehint!","expected duration","model sweep","retention"]
for p in ph:
    print(f"{p!r}: new={new.lower().count(p.lower())} (exact {new.count(p)}) old={old.count(p)}")
