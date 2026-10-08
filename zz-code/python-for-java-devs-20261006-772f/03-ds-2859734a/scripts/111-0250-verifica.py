# rescatado de la sesión 2859734a, 2026-09-14T02:50:22Z · Final verification of links, references and lint
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if any(x in root for x in ('pytest_cache','ruff_cache','__pycache__')): continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("\n".join(bad) or "  ninguno")
