# rescatado de la sesión 03630220, 2026-09-13T19:10:26Z · Verification batch 1
import re,glob,io
ok=True
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)', s)
    dep,hab=m.group(1).strip(),m.group(2).strip()
    exp_h = 'ninguna' if n==24 else f'{n+1:02d}'
    exp_d = 'ninguna' if n==0 else None
    if hab!=exp_h: print(f'  ❌ F{n:02d} Habilita={hab} esperado {exp_h}'); ok=False
    if n>0 and f'{n-1:02d}' not in dep: print(f'  ❌ F{n:02d} Depende={dep} no incluye {n-1:02d}'); ok=False
    fm=re.search(r'Fase (\d+) de 24', s)
    if int(fm.group(1))!=n: print(f'  ❌ F{n:02d} cabecera dice Fase {fm.group(1)}'); ok=False
print('  ✅ cadena 00→24 completa y cabeceras correctas' if ok else '')
