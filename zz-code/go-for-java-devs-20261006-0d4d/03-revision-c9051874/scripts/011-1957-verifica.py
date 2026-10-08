# rescatado de la sesión c9051874, 2026-09-13T19:57:50Z · Count debt markers per phase
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'conv' in f or 'hist' in f: continue
    s=io.open(f,encoding='utf-8').read()
    d=len(re.findall('💸',s))
    print(f"{f[:2]}: 💸={d}")
