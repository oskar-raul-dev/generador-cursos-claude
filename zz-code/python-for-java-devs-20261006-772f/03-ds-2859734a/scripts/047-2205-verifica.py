# rescatado de la sesión 2859734a, 2026-09-13T22:05:46Z · Final verification of the whole ds track
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("\n".join(bad) or "sin links rotos")
