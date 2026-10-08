# rescatado de la sesión aadc4f68, 2026-09-13T17:24:41Z · 
import re,glob
print(f"{'archivo':<42}{'🪞':>3}{'🩻':>3}{'📖':>3}{'⚰️':>3}{'⚖️':>3}{'🧬':>3}{'💸':>4}{'Proyecto':>9}{'apend':>6}")
print("-"*80)
avisos=[]
for f in sorted(glob.glob("[0-2][0-9]-*.md")):
    if 'convencion' in f: continue
    t=open(f,encoding='utf-8').read()
    head=t[:600]
    row=dict(
      mirror='🪞' in t, xray='🩻' in t, dict_='📖' in t, autop='⚰️' in t,
      verd='⚖️' in t, gen='🧬' in t, debt=t.count('💸'),
      proj='Proyecto que avanza' in head or 'Proyecto:' in head,
      apend=len(re.findall(r'apéndice', t, re.I)))
    print(f"{f:<42}{'✅' if row['mirror'] else '—':>3}{'✅' if row['xray'] else '—':>3}"
          f"{'✅' if row['dict_'] else '—':>3}{'✅' if row['autop'] else '—':>3}"
          f"{'✅' if row['verd'] else '—':>3}{'✅' if row['gen'] else '—':>3}"
          f"{row['debt']:>4}{'✅' if row['proj'] else '❌':>9}{row['apend']:>6}")
    if not row['mirror'] or not row['xray'] or not row['dict_'] or not row['proj']:
        avisos.append(f)
print("\nSin 🪞/🩻/📖 o sin proyecto declarado:", avisos or "ninguno")
