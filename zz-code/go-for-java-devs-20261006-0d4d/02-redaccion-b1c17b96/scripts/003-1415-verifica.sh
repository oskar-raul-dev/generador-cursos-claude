# rescatado de la sesión b1c17b96, 2026-09-12T14:15:43Z · Check mandatory sections present
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== SECCIONES OBLIGATORIAS ==="
printf "%-38s %-4s %-4s %-4s %-4s %-4s %-4s %-4s %-4s\n" ARCHIVO 🪞 🩻 🧨 ⚰️ 📖 ⚖️ 🏷️ 📌
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  a=$(grep -c '🪞' "$f"); b=$(grep -c '🩻' "$f"); c=$(grep -c '🧨 Rompe a propósito\|🧨 \*\*Rompe' "$f")
  d=$(grep -c '⚰️ Autopsia' "$f"); e=$(grep -c '📖 Diccionario' "$f"); g=$(grep -c '⚖️ Cuándo NO\|⚖️ El veredicto honesto' "$f")
  h=$(grep -c 'git tag -a fase-' "$f"); i=$(grep -c '📌 Bloque de autoría' "$f")
  printf "%-38s %-4s %-4s %-4s %-4s %-4s %-4s %-4s %-4s\n" "$f" "$a" "$b" "$c" "$d" "$e" "$g" "$h" "$i"
done
