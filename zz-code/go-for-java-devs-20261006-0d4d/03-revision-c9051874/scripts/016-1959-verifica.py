# rescatado de la sesión c9051874, 2026-09-13T19:59:09Z · Verify required recurring blocks in every phase
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'conv' in f or 'hist' in f: continue
    s=io.open(f,encoding='utf-8').read()
    i=s.find('## ⚖️ 10.')
    sec=s[i:]
    m={'📖 diccionario':'📖' in sec,'🏷️ tag':'🏷️' in sec or 'git tag' in sec,
       '🪞 instinto':'🪞' in s,'🩻 igual':'🩻' in s,'⚰️ autopsia':'⚰️' in s,
       '🧨 rompe':'🧨' in s,'⚖️ cuándo NO':'Cuándo NO usar' in sec or 'cuándo NO usar' in sec}
    falta=[k for k,v in m.items() if not v]
    print(f"{f[:2]}: {'OK' if not falta else 'FALTA '+', '.join(falta)}")
