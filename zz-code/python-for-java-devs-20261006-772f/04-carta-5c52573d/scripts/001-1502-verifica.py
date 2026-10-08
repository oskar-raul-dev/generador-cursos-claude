# rescatado de la sesión 5c52573d, 2026-10-05T15:02:32Z · List every text/untagged code block in course
import re, pathlib
for md in sorted(pathlib.Path('.').rglob('*.md')):
    L = md.read_text(encoding='utf-8').splitlines(); i=0
    while i < len(L):
        m = re.match(r'^\s*(```+)(\S*)', L[i])
        if m:
            j=i+1
            while j<len(L) and not L[j].strip().startswith(m.group(1)): j+=1
            if m.group(2) in ('','text','txt'):
                print(f"{md}:{i+1} [{m.group(2) or '-'}] {len(L[i+1:j])}l | {L[i+1][:70] if i+1<j else ''}")
            i=j+1
        else: i+=1
