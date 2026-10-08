# rescatado de la sesión c9051874, 2026-09-13T19:58:05Z · Collect open editorial decisions from authorship blocks
import re,io,glob
pat=re.compile(r'(Decisión (editorial )?(necesaria|pendiente)|Decidir(:| antes)|Hay que (añadir|decidir)|Recomiendo|Propuesta: B-|hay que |NO cerrada|sin resolver)',re.I)
for f in sorted(glob.glob('*.md')):
    s=io.open(f,encoding='utf-8').read()
    i=s.find('## 📌')
    if i<0: continue
    for j,l in enumerate(s[i:].split('\n')):
        if pat.search(l):
            print(f"{f}: {l.strip()[:150]}")
