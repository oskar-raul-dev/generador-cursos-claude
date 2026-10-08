# rescatado de la sesión b1c17b96, 2026-09-12T14:15:30Z · Verify exercise counts vs declared
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== EJERCICIOS: declarado vs numerado vs rangos ==="
printf "%-38s %-10s %-8s %s\n" ARCHIVO DECLARADO NUMERADO RANGOS
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  decl=$(grep -oE '^## 🧪 8\. Ejercicios \(([0-9]+)\)' "$f" | grep -oE '[0-9]+\)' | tr -d ')')
  # contar items numerados entre la sección 8 y la 9
  n=$(awk '/^## 🧪 8\. Ejercicios/,/^## 📚 9\./' "$f" | grep -cE '^[0-9]+\. ')
  rangos=$(awk '/^## 🧪 8\. Ejercicios/,/^## 📚 9\./' "$f" | grep -oE '\*\*(🟢|🟡|🟠|🔴) [^(]+\(([0-9]+–[0-9]+)\)' | grep -oE '\([0-9]+–[0-9]+\)' | tr '\n' ' ')
  printf "%-38s %-10s %-8s %s\n" "$f" "$decl" "$n" "$rangos"
done
