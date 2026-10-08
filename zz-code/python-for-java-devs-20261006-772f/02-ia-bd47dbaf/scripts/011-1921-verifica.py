# rescatado de la sesión bd47dbaf, 2026-09-13T19:21:05Z · Check all internal markdown links resolve
import pathlib, re
base = pathlib.Path('.')
rotos = []
for md in sorted(base.rglob('*.md')):
    if '__pycache__' in str(md): continue
    for m in re.finditer(r'\[([^\]]{1,80})\]\(([^)]+)\)', md.read_text(encoding='utf-8')):
        target = m.group(2).split('#')[0]
        if target.startswith(('http', 'mailto:')) or not target: continue
        resolved = (md.parent / target).resolve()
        if not resolved.exists():
            rotos.append(f"{md}  →  {target}")
print(f"{len(rotos)} enlaces rotos")
for r in rotos: print(" ", r)
