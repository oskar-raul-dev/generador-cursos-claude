# rescatado de la sesión aadc4f68, 2026-09-13T17:24:24Z · 
import re,glob
print(f"{'archivo':<42}{'declarados':>11}{'reales':>8}{'🟢🟡🟠🔴':>10}{'🔥':>4}")
print("-"*76)
malos=[]
for f in sorted(glob.glob("[0-2][0-9]-*.md")):
    t=open(f,encoding='utf-8').read()
    m=re.search(r'^## 🧪 8\. Ejercicios \((\d+)\)', t, re.M)
    if not m: continue
    decl=int(m.group(1))
    start=m.end()
    nxt=re.search(r'^## 📚 9\.', t[start:], re.M)
    sec=t[start:start+nxt.start()]
    nums=[int(n) for n in re.findall(r'^(\d+)\. ', sec, re.M)]
    reales=len(nums)
    niveles=len(re.findall(r'^\*\*🟢|^\*\*🟡|^\*\*🟠|^\*\*🔴', sec, re.M))
    fuego=len(re.findall(r'^- ', sec[sec.find('🔥'):], re.M)) if '🔥' in sec else 0
    consec = nums==list(range(1,reales+1))
    flag='' if (decl==reales and consec and niveles==4) else '  ← revisar'
    print(f"{f:<42}{decl:>11}{reales:>8}{niveles:>10}{fuego:>4}{flag}")
    if flag: malos.append((f,decl,reales,consec,niveles))
print("\nProblemas:", malos or "ninguno")
