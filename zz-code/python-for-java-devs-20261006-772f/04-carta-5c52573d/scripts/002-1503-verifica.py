# rescatado de la sesión 5c52573d, 2026-10-05T15:03:16Z · Count exercises and multiline links
import re, pathlib, sys
sys.path.insert(0,'../../zz-instrucciones/herramientas')
import verificador_base as vb
slug = getattr(vb,'slug_github')
files = sorted(pathlib.Path('.').glob('[0-9]*.md'))
for f in files:
    t=f.read_text(encoding='utf-8')
    c={e:len(re.findall(r'^(?:\*\*|#+ |- |\d+\. )?\**'+e, t, re.M)) for e in '🟢🟡🟠🔴'}
    print(f.name[:40].ljust(40), c, sum(c.values()))
# multiline link texts pointing to anchors
for f in sorted(pathlib.Path('.').rglob('*.md')):
    t=f.read_text(encoding='utf-8')
    for m in re.finditer(r'\[([^\]]*\n[^\]]*)\]\(([^)]*)\)', t):
        print('MULTILINEA', f, repr(m.group(2)))
