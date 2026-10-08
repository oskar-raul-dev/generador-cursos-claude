# rescatado de la sesión b1c17b96, 2026-09-12T14:17:21Z · Verify hours and phase numbering coherence
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== CABECERA DE CADA FASE: horas y 'Fase N de 17' ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  printf "%-38s " "$f"; sed -n '3p' "$f"
done
echo
echo "=== ¿La tabla de 0-ESTRUCTURA coincide en horas? ==="
grep -oE '\| [0-9]+ \| [0-9]+ \|' 0-ESTRUCTURA-CURSO.md | head -20
echo
echo "=== suma de horas declaradas en las cabeceras ==="
grep -h '^> Go para desarrolladores' [01][0-9]-*.md | grep -oE '\*\*[0-9]+ horas?\*\*' | grep -oE '[0-9]+' | paste -sd+ | bc
