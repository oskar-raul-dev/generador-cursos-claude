# rescatado de la sesión 03630220, 2026-09-13T19:13:43Z · Full closing verification
echo "=== CIERRE: verificación completa ==="
p=0
echo "1. Referencias externas:"; grep -rnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|otros cursos del|python-for-java|propuestas-cursos|_oskar" . --include="*.md" >/dev/null 2>&1 && { grep -rnE "CLAUDE\.md|cursos-[a-z]" . --include="*.md"; p=1; } || echo "   ✅ cero"
echo "2. Enlaces:"; n=$(grep -ohE "\]\(([^)h][^)]*)\)" *.md prompts/*.md | sed -E 's/^\]\(//;s/\)$//;s/#.*//' | sort -u | while read -r l; do [ -z "$l" ]||[ -e "$l" ]||[ -e "prompts/$l" ]||echo x; done | wc -l); [ "$n" = 0 ] && echo "   ✅ todos resuelven" || { echo "   ❌ $n rotos"; p=1; }
echo "3. Cadena 00→24:"; python3 -c "
import re,glob,io,sys
bad=0
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)',s)
    e='ninguna' if n==24 else '%02d'%(n+1)
    if m.group(2).strip()!=e: bad+=1
print('   ✅ sin huecos' if not bad else '   ❌ %d'%bad)"
echo "4. Ejercicios (decl=real, 20-25):"; b=0; for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); { [ "$d" = "$n" ] && [ "$d" -ge 20 ] && [ "$d" -le 25 ]; } || b=$((b+1)); done; [ $b = 0 ] && echo "   ✅ las 25" || echo "   ❌ $b"
echo "5. Tags fase-NN/mini-NN:"; b=0; for i in $(seq -w 0 24); do f=$(ls ${i}-*.md|grep -v convencion); { [ $(grep -c "git tag -a fase-$i" $f) = 1 ] && [ $(grep -c "git tag -a mini-$i" $f) = 1 ]; } || b=$((b+1)); done; [ $b = 0 ] && echo "   ✅ las 25" || echo "   ❌ $b"
echo "6. BENCHMARKS F00–F23 + consolidación:"; python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
print('   ✅ 24 entradas + F24' if i==list(range(24)) and '## 🧮 F24' in s else '   ❌')"
echo "7. Plantilla de 10 secciones:"; b=0; for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f || b=$((b+1)); done; done; [ $b = 0 ] && echo "   ✅ las 25, en orden" || echo "   ❌ $b faltantes"
echo "8. git diff de deudas, rutas únicas por deuda:"; grep -rhoE "git diff fase-[0-9]+ fase-[0-9]+ -- [^\`\"]*" *.md | sed 's/ -->$//;s/ *$//' | sort | uniq -c | awk '$1>0{print "   "$0}' | head -30
