# rescatado de la sesión c9051874, 2026-09-13T19:53:36Z · Final verification of references and links
import re,os,io,glob
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)\s]+\.md)\)', s):
        t=m.group(1).split('#')[0]
        d=os.path.normpath(os.path.join(os.path.dirname(f), t))
        if not os.path.exists(d):
            bad.append(f"{f}:{s[:m.start()].count(chr(10))+1} -> {t}")
print('\n'.join(sorted(set(bad))) or 'ninguno')
