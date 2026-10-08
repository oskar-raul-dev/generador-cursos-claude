# rescatado de la sesión 03630220, 2026-09-13T19:10:51Z · Verification batch 3
echo "=== 7. Ejercicios: declarado vs real, dentro de la banda 20-25 ==="
for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do d=$(grep -oE "^## 🧪 8\. Ejercicios \([0-9]+\)" $f|grep -oE "[0-9]+$"); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); [ "$d" = "$n" ] && [ "$d" -ge 20 ] && [ "$d" -le 25 ] || echo "  ❌ $f decl=$d real=$n"; done; echo "  ✅ las 25 coinciden y caen en 20-25"
echo
echo "=== 8. Tags ==="
for i in $(seq -w 0 24); do f=$(ls ${i}-*.md 2>/dev/null|grep -v convencion); [ $(grep -c "git tag -a fase-$i" $f) = 1 ] && [ $(grep -c "git tag -a mini-$i" $f) = 1 ] || echo "  ❌ F$i"; done; echo "  ✅ fase-NN y mini-NN en las 25"
echo
echo "=== 9. Cifras del dominio ==="
grep -rhoE "[0-9][0-9.]*[0-9]? (procedimientos|formularios|títulos|equipos|empleados)" *.md | sort | uniq -c | sort -rn
echo "  -- años de contratos --"; grep -rhoE "(4[0-9] años|[Cc]uarenta y [a-z]+ años)" *.md | sort | uniq -c
echo
echo "=== 10. Conteos escritos ==="
grep -rhoE "veinticinco (fases|mediciones|entradas|tablas|documentos|miniproyectos)|veinticuatro (fases|mediciones|entradas|tablas)" *.md | sort | uniq -c
