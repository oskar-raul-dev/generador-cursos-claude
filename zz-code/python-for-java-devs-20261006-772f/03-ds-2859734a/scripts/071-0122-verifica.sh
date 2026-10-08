# rescatado de la sesión 2859734a, 2026-09-14T01:22:42Z · Verify state text and lint the whole track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "⏳ **El track" prompts/prompts-de-tracks-ia-ds.md | head -2
sed -n '/El track `ds` va por `ds06`/,+8p' prompts/prompts-de-tracks-ia-ds.md
rm -rf src/ds0*/data src/ds0*/salida src/ds0*/cuadernos src/ds0*/resultado.json src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint + pruebas de todo el track ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo src/ds05-visualizacion src/ds06-notebooks-y-reproducibilidad src/ds07-scikit-learn; do
  printf "  %-48s" "$(basename $d)"
  (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && printf "lint OK · " || printf "LINT FALLA · ")
done; echo
