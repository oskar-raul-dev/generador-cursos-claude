# rescatado de la sesión b1c17b96, 2026-09-12T14:16:25Z · Verify proposed benchmark IDs only in authorship blocks
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== ¿Dónde aparecen B-25..B-31? (deben estar SOLO en bloques 📌 de autoría) ==="
for f in [01][0-9]-*.md; do
  line=$(grep -nE '\bB-(2[5-9]|3[01])\b' "$f" | cut -d: -f1)
  [ -z "$line" ] && continue
  autoria=$(grep -n '📌 Bloque de autoría' "$f" | cut -d: -f1)
  for l in $line; do
    if [ "$l" -lt "${autoria:-999999}" ]; then echo "⚠️  $f:$l está ANTES del bloque de autoría"; else echo "✅ $f:$l en autoría"; fi
  done
done
