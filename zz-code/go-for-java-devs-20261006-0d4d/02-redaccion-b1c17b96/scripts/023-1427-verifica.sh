# rescatado de la sesión b1c17b96, 2026-09-12T14:27:46Z · Verify challenge sections added and counts unchanged
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== Desafios de cierre presentes ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  n=$(grep -c '^\*\*D[123] —' "$f")
  ok=$(grep -c '^### 🔴 Desafíos de cierre' "$f")
  printf "%-38s seccion=%s desafios=%s\n" "$f" "$ok" "$n"
done
echo
echo "=== el conteo declarado de ejercicios NO cambio ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  d=$(grep -oE '^## 🧪 8\. Ejercicios \([0-9]+\)' "$f")
  n=$(awk '/^## 🧪 8\. Ejercicios/,/^## 📚 9\./' "$f" | grep -cE '^[0-9]+\. ')
  printf "%-38s %s numerados=%s\n" "$f" "$d" "$n"
done
