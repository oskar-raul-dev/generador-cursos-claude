# rescatado de la sesión c9051874, 2026-09-13T19:56:10Z · Count exercises per phase inside the exercises section
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    s=io.open(f,encoding='utf-8').read()
    lines=s.split('\n')
    # find section 8 heading (Ejercicios) and section 9 (Referencias)
    st=en=None
    for i,l in enumerate(lines):
        if re.match(r'^##\s', l):
            if st is None and 'jercicio' in l: st=i
            elif st is not None and en is None and re.match(r'^##\s', l): en=i
    body='\n'.join(lines[st:en]) if st is not None else ''
    ex=re.findall(r'^(\d+)\.\s', body, re.M)
    d=re.findall(r'\*\*D[123]\b', body)
    print(f"{f:42s} sec8={'sí' if st else 'NO'}  ejercicios={len(ex)} max={max(map(int,ex)) if ex else 0}  D={len(set(d))}")
