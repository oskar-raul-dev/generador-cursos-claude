# rescatado de la sesión c9051874, 2026-09-13T19:56:35Z · Re-audit section template ignoring fenced blocks
import re,io,glob
tpl=['Propósito','Qué queda listo','Qué NO entra','Concepto mínimo','CLI de la fase','Construcción guiada','Autopsia','Ejercicios','Referencias','Veredicto']
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    s=io.open(f,encoding='utf-8').read(); infence=False; hs=[]
    for l in s.split('\n'):
        if l.lstrip().startswith('```'): infence = not infence; continue
        if not infence and re.match(r'^##\s',l): hs.append(l)
    num=[h for h in hs if re.match(r'^##\s+\S+\s+\d+\.',h)]
    ok = len(num)==10 and all(t.lower() in num[i].lower() for i,t in enumerate(tpl))
    print(f"{f:42s} secciones={len(hs)} numeradas={len(num)} plantilla={'OK' if ok else 'REVISAR'}")
    if not ok:
        for h in hs: print("      ",h[:70])
