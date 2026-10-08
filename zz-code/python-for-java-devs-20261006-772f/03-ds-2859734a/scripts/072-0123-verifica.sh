# rescatado de la sesión 2859734a, 2026-09-14T01:23:17Z · Verify linting from both working directories
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== desde la raíz del curso ==="; uvx ruff@0.16.7 check src/ds0* 2>&1 | tail -3
echo "=== desde dentro de cada sección ==="
for d in src/ds0*/; do printf "  %-48s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "lint OK" || echo "LINT FALLA"); done
