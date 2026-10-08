# rescatado de la sesión 03630220, 2026-09-13T20:02:45Z · Verification batch 1
echo "════ 1. REFERENCIAS A OTROS CURSOS / REPO ════"
grep -rnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|otros cursos del|cursos de (Angular|legacy|Python|React|Go)|python-for-java|ruta-nosql|docker-container|propuestas-cursos|_oskar|del repositorio|repositorio tiene" . --include="*.md" \
 | grep -viE "SDK del repositorio|archivo del repositorio|raíz del repositorio|árbol del repositorio|subárbol del repositorio|Fuera del repositorio|fuera del repositorio" || echo "  ✅ cero"
echo
echo "════ 2. ENLACES ════"
b=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f" | sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ] || { echo "  ❌ $f → $l"; b=1; }; done; done
for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f" | sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ] || { echo "  ❌ $f → $l"; b=1; }; done; done
[ $b = 0 ] && echo "  ✅ todos resuelven"
echo
echo "════ 3. ESTRUCTURA ════"
echo "  archivos publicados: $(ls *.md | wc -l | tr -d ' ') · fases: $(ls [0-9][0-9]-*.md | grep -vE 'convencion|historia' | wc -l | tr -d ' ')"
python3 -c "
import re,glob,io
bad=[]
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)',s)
    e='ninguna' if n==24 else '%02d'%(n+1)
    if m.group(2).strip()!=e: bad.append((n,m.group(2)))
    if int(re.search(r'Fase (\d+) de 24',s).group(1))!=n: bad.append((n,'cabecera'))
print('  ✅ cadena 00→24 sin huecos, cabeceras correctas' if not bad else '  ❌ %s'%bad)"
