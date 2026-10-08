# rescatado de la sesión b1c17b96, 2026-09-12T14:16:13Z · Check file links and benchmark ID coherence
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== ENLACES A ARCHIVOS: ¿existen? ==="
grep -ohE '\]\(([0-9A-Za-z._/-]+\.md)\)' *.md | grep -oE '\(.*\)' | tr -d '()' | sort -u | while read -r p; do
  [ -e "$p" ] || echo "❌ ROTO: $p"
done
echo "(sin salida = todos existen)"
echo
echo "=== IDs de benchmark citados en las fases vs definidos en BENCHMARKS.md ==="
cited=$(grep -ohE '\bB-[0-9]{2}\b' [01][0-9]-*.md | sort -u)
defined=$(grep -oE '^## B-[0-9]{2}' BENCHMARKS.md | grep -oE 'B-[0-9]{2}' | sort -u)
echo "citados:   $(echo $cited | tr '\n' ' ')"
echo "definidos: $(echo $defined | tr '\n' ' ')"
echo "--- citados y NO definidos:"; comm -23 <(echo "$cited") <(echo "$defined")
echo "--- definidos y NO citados:"; comm -13 <(echo "$cited") <(echo "$defined")
