# rescatado de la sesión b1c17b96, 2026-09-12T14:30:08Z · Validate challenges epoch discipline and totals
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== 5. Desafios: 3 por fase, sin duplicar titulos ==="
grep -h '^\*\*D[123] —' [01][0-9]-*.md | wc -l | xargs echo "total desafios:"
echo
echo "=== 6. Epoca: desafios del Bloque A sin deps externas ==="
for f in 0[0-7]-*.md; do [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  h=$(sed -n '/^### 🔴 Desafíos de cierre/,/^## 📚 9\./p' "$f" | grep -nE 'golang\.org/x|github\.com/|go\.uber' | grep -v '🕰️')
  [ -n "$h" ] && { echo "-- $f"; echo "$h"; }
done
echo "(revisar los que salgan)"
echo
echo "=== 7. Recuento final ==="
wc -l *.md | tail -1
echo "numerados: $(grep -h -E '^[0-9]+\. ' [01][0-9]-*.md | wc -l | tr -d ' ') (incluye listas fuera de §8)"
