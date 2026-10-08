# rescatado de la sesión c9051874, 2026-09-13T19:56:18Z · List top-level sections of every phase
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    s=io.open(f,encoding='utf-8').read()
    h=[l for l in s.split('\n') if re.match(r'^##\s',l)]
    print(f"--- {f} ({len(h)} secciones)")
    for l in h: print("   ",l[:80])
