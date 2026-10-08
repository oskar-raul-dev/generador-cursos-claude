# rescatado de la sesión c9051874, 2026-09-13T20:13:42Z · Final verification sweep
import re,os,io,glob
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)\s]+\.md)\)', s):
        t=m.group(1).split('#')[0]
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(f),t))): bad.append(f"{f} -> {t}")
print('  ','\n'.join(sorted(set(bad))) or 'ninguno roto ✅')
