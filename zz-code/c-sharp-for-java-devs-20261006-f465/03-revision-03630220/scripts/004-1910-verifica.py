# rescatado de la sesión 03630220, 2026-09-13T19:10:38Z · Verification batch 2
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
ids=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·', s, re.M)]
print('  ✅ F00–F23 sin huecos ni duplicados' if ids==list(range(24)) else f'  ❌ {ids}')
idx=re.findall(r'^\| (\d{2}) \| ', s, re.M)
print('  ✅ índice con 25 filas, una por fase' if [int(i) for i in idx]==list(range(25)) else f'  ❌ índice: {idx}')
