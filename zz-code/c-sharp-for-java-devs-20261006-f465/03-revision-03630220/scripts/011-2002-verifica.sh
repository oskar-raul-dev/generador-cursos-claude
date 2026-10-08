# rescatado de la sesión 03630220, 2026-09-13T20:02:58Z · Verification batch 2
echo "════ 4. PLANTILLA, EJERCICIOS, TAGS ════"
b=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do
 for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f || { echo "  ❌ $f falta §$k"; b=1; }; done
 d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. ")
 { [ "$d" = "$n" ] && [ "$d" -ge 20 ] && [ "$d" -le 25 ]; } || { echo "  ❌ $f ejercicios decl=$d real=$n"; b=1; }
 i=${f:0:2}; { [ $(grep -c "git tag -a fase-$i" $f) = 1 ] && [ $(grep -c "git tag -a mini-$i" $f) = 1 ]; } || { echo "  ❌ $f tags"; b=1; }
done; [ $b = 0 ] && echo "  ✅ 10 secciones en orden · ejercicios decl=real y en 20-25 · tags fase/mini · las 25"
echo
echo "════ 5. BENCHMARKS ════"
python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
idx=[int(m) for m in re.findall(r'^\| (\d{2}) \| ',s,re.M)][:25]
print('  ✅ 24 entradas F00-F23 + consolidación F24 · índice de 25 filas' if i==list(range(24)) and '## 🧮 F24' in s and idx==list(range(25)) else '  ❌ %s'%i)"
echo
echo "════ 6. CONTEOS ESCRITOS ════"
grep -rhoE "veinticinco (fases|mediciones|entradas|tablas|documentos|miniproyectos)|veinticuatro (fases|mediciones|entradas|tablas)" *.md | sort | uniq -c
echo
echo "════ 7. CIFRAS DEL DOMINIO ════"
grep -rhoE "[0-9][0-9.]*[0-9]? (procedimientos|formularios|títulos|equipos|empleados)" *.md | sort | uniq -c | sort -rn
grep -rhoE "(4[0-9] años|[Cc]uarenta y [a-z]+ años)" *.md | sort | uniq -c
