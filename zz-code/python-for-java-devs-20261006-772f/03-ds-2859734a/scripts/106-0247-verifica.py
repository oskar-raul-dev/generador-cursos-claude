# rescatado de la sesión 2859734a, 2026-09-14T02:47:04Z · Count reflexes per block and find stale count claims
import re
lines=open('INSTINTOS.md',encoding='utf-8').read().splitlines()
block=None; counts={}
for l in lines:
    if l.startswith('## '): block=l.strip()
    if re.match(r'^### \d+\.', l) or (block and 'método' in block and l.startswith('### ')):
        counts[block]=counts.get(block,0)+1
for k,v in counts.items(): print(f"  {v:>2}  {k}")
