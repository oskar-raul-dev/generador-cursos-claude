# rescatado de la sesión c9051874, 2026-09-13T20:14:05Z · Final cross-check of benchmark IDs and state
import re,io,glob
ids=set(re.findall(r'^## (B-\d{2})', io.open('BENCHMARKS.md',encoding='utf-8').read(), re.M))
usados=set()
for f in glob.glob('*.md'):
    usados |= set(re.findall(r'B-\d{2}', io.open(f,encoding='utf-8').read()))
print("entradas:", len(ids), sorted(ids)[-6:])
print("citados y no existentes:", sorted(usados-ids) or "ninguno ✅")
