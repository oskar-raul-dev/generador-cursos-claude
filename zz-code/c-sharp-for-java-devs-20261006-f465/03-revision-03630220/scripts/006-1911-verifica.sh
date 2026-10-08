# rescatado de la sesión 03630220, 2026-09-13T19:11:04Z · Fix exercise check and list project progression
echo "=== 7bis. Ejercicios ==="
for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); if [ "$d" != "$n" ] || [ "$d" -lt 20 ] || [ "$d" -gt 25 ]; then echo "  ❌ $f decl=$d real=$n"; fi; done; echo "  ✅ declarado = real, y todo en 20-25"
echo
echo "=== 11. 'Proyecto que avanza' vs tabla de 0-ESTRUCTURA ==="
for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do printf "F%s  " ${f:0:2}; grep -m1 "^> Proyecto que avanza:" $f | sed -E 's/^> Proyecto que avanza: //' | cut -c1-70; done
