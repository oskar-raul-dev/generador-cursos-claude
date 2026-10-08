# rescatado de la sesión 03630220, 2026-09-13T20:06:36Z · Complete closing checklist
echo "══════════ CIERRE ══════════"
b=0
printf "1  Referencias a otros cursos ......... "; grep -rqnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|curso de (Go|Python|Angular|React|Rust|Node)|otros cursos del|python-for-java|propuestas-cursos|_oskar" . --include="*.md" && { echo "❌"; b=1; } || echo "✅ cero"
printf "2  Enlaces relativos ................. "; n=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ]||n=1; done; done; for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ]||n=1; done; done; [ $n = 0 ] && echo "✅ todos resuelven" || { echo "❌"; b=1; }
printf "3  Cadena 00→24 y cabeceras .......... "; python3 -c "
import re,glob,io
bad=0
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)',s)
    if m.group(2).strip()!=('ninguna' if n==24 else '%02d'%(n+1)): bad=1
    if int(re.search(r'Fase (\d+) de 24',s).group(1))!=n: bad=1
print('✅ sin huecos' if not bad else '❌')"
printf "4  Plantilla de 10 secciones ......... "; n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f||n=1; done; done; [ $n = 0 ] && echo "✅ las 25, en orden" || { echo "❌"; b=1; }
printf "5  Ejercicios decl=real, banda 20-25 . "; n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); r=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); { [ "$d" = "$r" ]&&[ "$d" -ge 20 ]&&[ "$d" -le 25 ]; }||n=1; done; [ $n = 0 ] && echo "✅ las 25" || { echo "❌"; b=1; }
printf "6  Tags fase-NN / mini-NN ............ "; n=0; for i in $(seq -w 0 24); do f=$(ls ${i}-*.md|grep -vE 'convencion|historia'); { [ $(grep -c "git tag -a fase-$i" $f) = 1 ]&&[ $(grep -c "git tag -a mini-$i" $f) = 1 ]; }||n=1; done; [ $n = 0 ] && echo "✅ las 25" || { echo "❌"; b=1; }
printf "7  BENCHMARKS 24 entradas + F24 ...... "; python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
print('✅ F00-F23 + consolidación' if i==list(range(24)) and '## 🧮 F24' in s else '❌')"
printf "8  Servicios de nube prometidos ...... "; n=0; for k in "Durable Functions" "Azurite" "Blob Storage"; do grep -rq "$k" $(ls [0-9][0-9]-*.md|grep -vE 'historia') 2>/dev/null && n=1; done; [ $n = 0 ] && echo "✅ ninguno sin fase que lo cumpla" || { echo "❌"; b=1; }
echo; [ $b = 0 ] && echo "TODO EN VERDE" || echo "HAY FALLOS"
