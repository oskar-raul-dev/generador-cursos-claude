import re,glob,collections
svcs=["pricing","inventory","catalog","replenish"]
kinds=["deployment","service","httproute"]
def norm(p,s):
    out=[]
    for l in open(p):
        if re.match(r'\s*#',l) or not l.strip(): continue
        l=re.sub(r'\s+#.*','',l.rstrip())
        out.append(l.replace(s,"SVC"))
    return out
tot=0; same=0
for k in kinds+["migrate"]:
    files={s:(f"deploy/manifests/{s}/{k}.yaml" if k!="migrate" else f"deploy/jobs/{s}-migrate.yaml") for s in svcs}
    texts={s:norm(f,s) for s,f in files.items()}
    base=collections.Counter(texts["pricing"])
    for s in svcs:
        t=texts[s]; tot+=len(t)
        c=collections.Counter(t); common=sum((c & base).values()) if s!="pricing" else len(t)
        same+=common
        print(f"{k:11} {s:10} {len(t):3} líneas, {common:3} iguales a pricing salvo el nombre")
print(f"total {tot} líneas sin comentarios; {same} iguales a las de pricing salvo el nombre ({same*100//tot} %)")
