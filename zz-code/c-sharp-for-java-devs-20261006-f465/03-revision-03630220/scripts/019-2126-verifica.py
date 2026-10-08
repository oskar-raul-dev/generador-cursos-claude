# rescatado de la sesión 03630220, 2026-09-13T21:26:31Z · Style, pendientes and references audit
import re,io,glob
est=io.open('0-ESTRUCTURA-CURSO.md',encoding='utf-8').read()
tabla={}
for m in re.finditer(r'^\| (\d{2}) ⭐? \| [^|]+\| (nuevo|heredado|mixto 🧬|—) \|',est,re.M):
    tabla[int(m.group(1))]=m.group(2)
bad=[]
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Estilo de esta fase: \*\*(.+?)\*\*',s)
    d=m.group(1).replace('mixto 🧬','mixto 🧬')
    t=tabla.get(n)
    if t and t.split()[0] not in d: bad.append((n,d,t))
print('  ✅ coinciden' if not bad else '  ❌ %s'%bad)
