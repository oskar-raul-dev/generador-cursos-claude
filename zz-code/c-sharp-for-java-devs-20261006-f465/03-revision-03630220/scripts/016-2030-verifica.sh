# rescatado de la sesión 03630220, 2026-09-13T20:30:10Z · Standard verification battery
b=0
printf "1  Referencias a otros cursos ......... "; grep -rqnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|curso de (Go|Python|Angular|React|Rust|Node|Java)|otros cursos del|python-for-java|ruta-nosql|propuestas-cursos|_oskar" . --include="*.md" && { echo "❌"; grep -rnE "CLAUDE\.md|cursos-[a-z]|curso de (Go|Python|Angular|React|Rust|Node|Java)" . --include="*.md"; b=1; } || echo "✅ cero"
printf "2  Enlaces relativos ................. "; n=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ]||{ n=1; echo "❌ $f→$l"; }; done; done; for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ]||{ n=1; echo "❌ $f→$l"; }; done; done; [ $n = 0 ] && echo "✅" || b=1
printf "3  Cadena 00→24 + cabeceras .......... "; python3 -c "
import re,glob,io
bad=0
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    if re.search(r'> Depende de: (.+?) · Habilita: (.+)',s).group(2).strip()!=('ninguna' if n==24 else '%02d'%(n+1)): bad=1
    if int(re.search(r'Fase (\d+) de 24',s).group(1))!=n: bad=1
print('✅' if not bad else '❌')"
printf "4  10 secciones · ejercicios · tags ... "; n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f||n=1; done; d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); r=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); { [ "$d" = "$r" ]&&[ "$d" -ge 20 ]&&[ "$d" -le 25 ]; }||n=1; i=${f:0:2}; { [ $(grep -c "git tag -a fase-$i" $f) = 1 ]&&[ $(grep -c "git tag -a mini-$i" $f) = 1 ]; }||n=1; done; [ $n = 0 ] && echo "✅ las 25" || { echo "❌"; b=1; }
printf "5  BENCHMARKS ........................ "; python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
print('✅ 24 + consolidación' if i==list(range(24)) and '## 🧮 F24' in s else '❌')"
printf "6  src/ coincide con lo declarado .... "; find src/fases -mindepth 1 -maxdepth 2 -type d | sort | tr '\n' ' '; echo
[ $b = 0 ] && echo "── base en verde ──"
