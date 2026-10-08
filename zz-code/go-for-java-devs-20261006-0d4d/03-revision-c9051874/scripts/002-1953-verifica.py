# rescatado de la sesión c9051874, 2026-09-13T19:53:11Z · Audit relative markdown links across the course
import re,os,io,glob
root='.'
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)]+)\)', s):
        t=m.group(1).split('#')[0].strip()
        if not t or t.startswith(('http','mailto:','#')): continue
        d=os.path.normpath(os.path.join(os.path.dirname(f), t))
        if not os.path.exists(d):
            ln=s[:m.start()].count('\n')+1
            bad.append(f"{f}:{ln} -> {t}")
print('\n'.join(sorted(set(bad))) or 'sin enlaces rotos')
