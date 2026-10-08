# rescatado de la sesión aadc4f68, 2026-09-13T17:24:08Z · 
import re,glob,os
fases=sorted(f for f in glob.glob("[0-9][0-9]-*.md"))
print(f"Fases encontradas: {len(fases)}\n")
print(f"{'archivo':<42}{'secs':>5}{'ejerc':>7}{'mini':>6}{'med':>5}{'tag':>5}{'señal':>7}{'líneas':>8}")
print("-"*86)
faltan=[]
for f in fases:
    t=open(f,encoding='utf-8').read()
    secs=re.findall(r'^## [^\n]*?(\d+)\.\s', t, re.M)
    nums=[int(n) for n in secs]
    ok10 = sorted(set(n for n in nums if 1<=n<=10))==list(range(1,11))
    ej=len(re.findall(r'^\d+\. ', t, re.M))
    mini = '🧱' in t and 'Criterios de aceptación' in t
    med = '📏' in t and ('Hipótesis' in t or 'no produce' in t.lower() or 'consolida' in t.lower())
    tag = 'git tag -a fase-' in t
    senal = 'señal de que quedó bien' in t
    print(f"{f:<42}{'✅' if ok10 else '❌':>5}{ej:>7}{'✅' if mini else '❌':>6}{'✅' if med else '❌':>5}{'✅' if tag else '❌':>5}{'✅' if senal else '❌':>7}{len(t.splitlines()):>8}")
    if not(ok10 and mini and med and tag and senal): faltan.append(f)
print("\nIncompletas:", faltan or "ninguna")
