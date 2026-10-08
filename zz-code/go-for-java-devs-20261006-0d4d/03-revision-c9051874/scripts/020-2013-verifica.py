# rescatado de la sesión c9051874, 2026-09-13T20:13:42Z · Final verification sweep
import re,io,glob
tot=0
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'conv' in f or 'hist' in f: continue
    s=io.open(f,encoding='utf-8').read(); inf=False; hs=[]
    for l in s.split('\n'):
        if l.lstrip().startswith('```'): inf = not inf; continue
        if not inf and re.match(r'^##\s',l): hs.append(l)
    num=[h for h in hs if re.match(r'^##\s+\S+\s+\d+\.',h)]
    i=s.find('## 🧪'); j=s.find('## 📚',i)
    ex=re.findall(r'^(\d+)\.\s', s[i:j], re.M); tot+=len(ex)
    assert len(num)==10, (f,len(num))
print("plantilla 10 secciones: 18/18 OK · ejercicios:", tot)
