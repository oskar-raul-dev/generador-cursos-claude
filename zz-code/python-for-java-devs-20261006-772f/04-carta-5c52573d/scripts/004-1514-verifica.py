# rescatado de la sesión 5c52573d, 2026-10-05T15:14:05Z · Check exercise counts, rubrics, Spring Boot version
import re,glob
for f in sorted(glob.glob('[0-1][0-9]-*.md')):
    L=open(f,encoding='utf-8').read().splitlines()
    dec=None; num=0; dentro=False; rub=0; rojos=False; nrojos=0; desafios=0; sec=[]
    for l in L:
        if l.startswith('## '):
            sec.append(l)
            m=re.match(r'^## 🧪 8\. Ejercicios \((\d+)\)',l); dentro=bool(m)
            if m: dec=int(m.group(1))
            continue
        if not dentro: continue
        if re.match(r'^\*\*🔴',l) and 'Desaf' not in l: rojos=True
        if re.match(r'^\*\*(🔥|D\d)',l) or l.startswith('### '): rojos=False
        if re.match(r'^\d+\. ',l):
            num+=1
            if rojos: nrojos+=1
        if re.search(r'[Rr]úbrica|<details',l): rub+=1
        if re.match(r'^\*\*D\d',l): desafios+=1
    if dec is not None or 'historia' not in f and 'convencion' not in f:
        print(f"{f[:38]:38} dec={dec} num={num} rojos={nrojos} rubricas/details={rub} desafios={desafios} secciones={len(sec)}")
